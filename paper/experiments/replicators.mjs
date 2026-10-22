// A Monte Carlo on replicators: when do cycles of the rewriting map first appear on the lattice, and how fast do they take
// over? No knowledge of the dictionary's cycles is used: a cell is on a k-cycle (k <= KMAX) when its content has repeated
// with period k over the last 2k turns, and the cycle's identity is the canonical rotation of its k state hashes, so the
// same cycle is the same species wherever and whenever it is found. For every species the script records the turn of
// first appearance, the turns at which it holds 1, 10, 50 and 90 % of the cells, its peak and its final share; and, for
// the waiting-time comparison, the basin of each species under the decoder alone (random cells decoded in isolation,
// mixing and settling off: the share on the species after 200 turns). A k-cycle is visible from turn 2k - 1 on.
// Usage: node paper/experiments/replicators.mjs dict=ca-swarm-f [cread=4096] [n=256] [turns=2000] [seeds=5] [pm=0.5] [ps=1]
//        [page=1] [pair=0] [mixsync=0] [nbr=1] [passes=3] [kmax=64] [order=rotate] [changer=36] [steps=256] [salt=0] [out=paper/data/replicators-v2]
// changer selects the rewriting rule (36 the Brotli-like decoder on dict; a CPU kind runs steps instructions a cell and
// ignores the dictionary); salt=1 salts the hashes by the turn (annealed) instead of the quenched default.
import fs from 'node:fs';
import { makeSim } from '../../tools/ca-harness.mjs';
import { loadDict, asText } from './dict-variants.mjs';
import { provenance, provLine } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const dictId = opt.dict || 'ca-swarm-f', cread = Number(opt.cread ?? 4096), n = Number(opt.n ?? 256), turns = Number(opt.turns ?? 2000), seeds = Number(opt.seeds ?? 5);
const pm = Number(opt.pm ?? 0.5), ps = Number(opt.ps ?? 1), page = Number(opt.page ?? 0) === 1, pair = Number(opt.pair ?? 0), mixSync = Number(opt.mixsync ?? 0) === 1;
const nbr = Number(opt.nbr ?? 1), passes = Number(opt.passes ?? 3), KMAX = Number(opt.kmax ?? 64), outDir = opt.out || dir + '/paper/data/replicators-v2';
const order = opt.order || 'rotate';   // the swap order scheme (Band.SCHEMES): the page's default 'rotate'; 'fixed' reproduces the first batches
const changer = Number(opt.changer ?? 36), steps = Number(opt.steps ?? 0), salt = Number(opt.salt ?? 0);   // changer: the page's kind (36 the Brotli-like decoder, 6..30, 43, 44, 47 the CPUs); salt: 0 quenched, 1 by turn
const designPath = `${dir}/paper/data/design/${dictId}.txt`;
const text = fs.existsSync(designPath) ? fs.readFileSync(designPath, 'latin1') : asText(loadDict(dictId).bytes);
const tag = `${changer === 36 ? dictId : 'cpu' + changer}-${page ? 'page' : `pm${pm}-ps${ps}`}-n${n}-t${turns}${pair ? '-pair' + pair : ''}${mixSync ? '-sync' : ''}${salt ? '-salt' + salt : ''}${steps ? '-steps' + steps : ''}`;
const common = { W: n, H: n, changer, maxlen: 3, skip: 6, cread, coff: 0, saltMode: salt, pairMode: pair, passes, nbr, steps, altOrder: order };
const simL = await makeSim({ ...common, mixSync, swap: page ? [0, 1] : [pm, pm], smooth: page ? [0, 1] : [ps, ps], mixOn: true, settleOn: true });
const simB = await makeSim({ ...common, mixSync: false, swap: [0, 0], smooth: [0, 0], mixOn: false, settleOn: false });
const h32 = (g, i) => { let h = 2166136261; for (let k = 0; k < 16; k++) { h ^= g[16 * i + k]; h = Math.imul(h, 16777619) >>> 0; } return h; };
const mixHash = (a, b) => { let h = (a ^ Math.imul(b, 0x9E3779B1)) >>> 0; h ^= h >>> 15; h = Math.imul(h, 0x85EBCA6B) >>> 0; h ^= h >>> 13; return h >>> 0; };
const RING = 2 * KMAX + 1;
const at = (ring, i, t) => ring[i * RING + ((t % RING) + RING) % RING];
// a k-cycle can be seen once 2k turns are in the history: at turn t the periods up to (t + 1) / 2 are tested, so a
// 3-cycle is detectable from turn 5 and the longest, KMAX, from turn 2 KMAX - 1
function periodOf(ring, i, t) {   // the smallest k whose last k states repeat the k before them: find a recent repeat of the current state, then confirm the whole period
  const kmax = Math.min(KMAX, (t + 1) >> 1), base = i * RING, cur = ring[base + (t % RING)];
  for (let k = 1; k <= kmax; k++) {
    if (ring[base + ((t - k) % RING + RING) % RING] !== cur) continue;
    let ok = true; for (let j = 1; j < k; j++) if (at(ring, i, t - j) !== at(ring, i, t - j - k)) { ok = false; break; }
    if (ok) return k;
  }
  return 0;
}
function speciesOf(ring, i, t, k) {   // the rotation starting at the smallest hash, folded with the period into one id
  let best = -1, bi = 0; for (let j = 0; j < k; j++) { const v = at(ring, i, t - j); if (best < 0 || v < best) { best = v; bi = j; } }
  let id = k; for (let j = 0; j < k; j++) id = mixHash(id, at(ring, i, t - bi - j)); return id;
}
function run(sim, seed, T) {
  sim.setDict(text); sim.reset(seed);
  const N = sim.N, ring = new Uint32Array(N * RING), species = new Map(), lead = []; let onCycle = 0;
  for (let t = 0; t < T; t++) {
    sim.step(); const g = sim.grid(); const counts = new Map(); onCycle = 0;
    for (let i = 0; i < N; i++) {
      ring[i * RING + (t % RING)] = h32(g, i);
      if (t < 1) continue;
      const p = periodOf(ring, i, t); if (!p) continue; onCycle++;
      const id = speciesOf(ring, i, t, p); const c = counts.get(id); if (c) c.n++; else counts.set(id, { n: 1, k: p });
    }
    let leadShare = 0, leadId = 0;
    for (const [id, c] of counts) {
      const share = c.n / N; if (share > leadShare) { leadShare = share; leadId = id; }
      let s = species.get(id); if (!s) { s = { id, k: c.k, first: t, marks: {}, max: 0, final: 0 }; species.set(id, s); }
      for (const m of [1, 10, 50, 90]) if (share >= m / 100 && s.marks[m] === undefined) s.marks[m] = t;
      if (share > s.max) s.max = share; s.final = share;
    }
    for (const s of species.values()) if (!counts.has(s.id)) s.final = 0;
    if (t % 10 === 0 || t === T - 1) { const top = {}; for (const [id, c] of counts) if (c.n / N >= 0.01) top[id.toString(16)] = Math.round(1e4 * c.n / N) / 1e4; lead.push([t, leadShare, leadId.toString(16), top]); }   // every tenth turn: the leader and every species at 1 % or more
  }
  return { species: [...species.values()].sort((a, b) => a.first - b.first), onCycle: onCycle / N, lead };
}
fs.mkdirSync(outDir, { recursive: true });
// skip a configuration another process has finished or claimed (lets two batches share one job list)
if (opt.skipdone !== '0') { const done = `${outDir}/${tag}.json`, lock = `${outDir}/${tag}.lock`;
  if (fs.existsSync(done) || fs.existsSync(lock)) { console.error(`${tag}: done or claimed, skipped`); process.exit(0); }
  fs.writeFileSync(lock, String(process.pid)); process.on('exit', () => { try { fs.unlinkSync(lock); } catch {} }); }
// the basins: the decoder alone from random cells
const basinRun = run(simB, 99, Math.min(turns, 200)), basins = new Map(basinRun.species.map(s => [s.id, { k: s.k, share: s.final }]));
console.error(`${tag}: decoder alone after ${Math.min(turns, 200)} turns, ${(100 * basinRun.onCycle).toFixed(1)} % of cells on a cycle, ${basins.size} species: ${[...basins.values()].filter(b => b.share >= 0.001).sort((a, b) => b.share - a.share).map(b => `${b.k}-cycle ${(100 * b.share).toFixed(2)} %`).join(', ')}`);
const rows = []; let minorTotal = 0;
for (let seed = 1; seed <= seeds; seed++) {
  const r = run(simL, seed, turns);
  minorTotal = (minorTotal || 0) + r.species.filter(s => s.max < 0.001).length;   // species that never held 0.1 % are counted, not listed (a CPU run sees millions)
  for (const s of r.species) { if (s.max < 0.001) continue; const b = basins.get(s.id); rows.push({ seed, id: s.id.toString(16), k: s.k, first: s.first, t1: s.marks[1] ?? null, t10: s.marks[10] ?? null, t50: s.marks[50] ?? null, t90: s.marks[90] ?? null, max: s.max, final: s.final, basin: b ? b.share : 0 }); }
  const lf = r.lead[r.lead.length - 1], leader = r.species.find(s => s.id.toString(16) === lf[2]);
  console.error(`seed ${seed}: ${r.species.length} species seen, ${(100 * r.onCycle).toFixed(1)} % of cells on a cycle at the end, leader (${leader ? leader.k : '-'}-cycle) ${(100 * lf[1]).toFixed(1)} %, first seen at turn ${leader ? leader.first : '-'}, 50 % at ${leader?.marks[50] ?? '-'}, 90 % at ${leader?.marks[90] ?? '-'}`);
  fs.writeFileSync(`${outDir}/${tag}-seed${seed}-lead.json`, JSON.stringify(r.lead));
}
fs.writeFileSync(`${outDir}/${tag}.json`, JSON.stringify({ provenance: provenance(import.meta.url, { dictId, cread, n, turns, seeds, pm, ps, page, pair, mixSync, nbr, passes, KMAX, changer, steps, salt, order }), order, kmax: KMAX, tag, dict: changer === 36 ? dictId : 'cpu' + changer, changer, steps, salt, n, turns, seeds, pm, ps, page, pair, mixSync, basins: [...basins.entries()].filter(([, b]) => b.share >= 0.0001).map(([id, b]) => ({ id: id.toString(16), ...b })), minorSpecies: minorTotal, rows }, null, 1));
const major = rows.filter(r => r.t1 !== null);
console.log(provLine(provenance(import.meta.url)));
console.log(`| ${tag} | seed | species | k | basin | first | 1 % | 10 % | 50 % | 90 % | peak | final |`);
console.log('|---|---|---|---|---|---|---|---|---|---|---|---|');
for (const r of major) console.log(`| | ${r.seed} | ${r.id} | ${r.k} | ${(100 * r.basin).toFixed(2)} % | ${r.first} | ${r.t1} | ${r.t10 ?? '-'} | ${r.t50 ?? '-'} | ${r.t90 ?? '-'} | ${(100 * r.max).toFixed(0)} % | ${(100 * r.final).toFixed(0)} % |`);
console.log(`minor species (never 1 %): ${rows.length - major.length}`);
