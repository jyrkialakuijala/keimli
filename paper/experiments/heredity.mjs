// Heredity of the decoder's attractor types: what becomes of a mutant? (1) the map alone: every one-bit mutant of every
// state of each main type is iterated on its own (a lattice with mixing and settling off, one mutant per cell) and
// classified after 300 turns: repaired (back on its parent type), converted (on another known type), a new attractor
// (a type of its own: the only way a mutation can be inherited here), or still transient. Whether the mutant itself
// lies on a cycle (it would then copy itself, i.e. be heritable) is tested directly. (2) The lattice: a 3 x 3 patch of
// one mutant planted in a domain of its parent type (all cells in phase), under uniform mixing p and settling m; after
// 200 turns, the cells not of the parent type: 0 = erased, a few = persists, more than 9 = spread.
// Usage: node paper/experiments/heredity.mjs dict=ca-brotli-12 [cread=4096] [types=3] [out=paper/data/heredity]
import fs from 'node:fs';
import { makeSim } from '../../tools/ca-harness.mjs';
import { loadDict, asText } from './dict-variants.mjs';
import { provenance, provLine } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const dictId = opt.dict || 'ca-brotli-12', cread = Number(opt.cread ?? 4096), NT = Number(opt.types ?? 3), outDir = opt.out || dir + '/paper/data/heredity';
fs.mkdirSync(outDir, { recursive: true });
const designPath = `${dir}/paper/data/design/${dictId}.txt`;
const text = fs.existsSync(designPath) ? fs.readFileSync(designPath, 'latin1') : asText(loadDict(dictId).bytes);
const common = { changer: 36, maxlen: 3, skip: 6, cread, coff: 0, passes: 1, nbr: 1, altOrder: 'rotate', pairMode: 0 };
const key = (g, i) => Buffer.from(g.subarray(16 * i, 16 * i + 16)).toString('latin1');
const KMAX = 64;
async function census(n, seed, T0, cells) {   // iterate f alone on n*n cells (random, or the given keys), then each cell's cycle
  const sim = await makeSim({ ...common, W: n, H: n, swap: [0, 0], smooth: [0, 0], mixOn: false, settleOn: false }); sim.setDict(text); sim.reset(seed);
  const N = n * n; if (cells) { const g = sim.grid(); cells.forEach((s, i) => { for (let b = 0; b < 16; b++) g[16 * i + b] = s.charCodeAt(b); }); }
  for (let t = 0; t < T0; t++) sim.step();
  const hist = []; for (let t = 0; t <= KMAX; t++) { hist.push(sim.grid().slice()); sim.step(); }
  return Array.from({ length: cells ? cells.length : N }, (_, i) => { const k0 = key(hist[0], i); for (let k = 1; k <= KMAX; k++) if (key(hist[k], i) === k0) { const st = []; for (let j = 0; j < k; j++) st.push(key(hist[j], i)); return st; } return null; });
}
const canon = st => st.reduce((a, b) => (b < a ? b : a));
// the main types
const base = await census(128, 99, 300, null), types = new Map();
for (const st of base) if (st) { const c = canon(st); const e = types.get(c) || { states: st, count: 0 }; e.count++; types.set(c, e); }
let list = [...types.values()].sort((a, b) => b.count - a.count);
const fixed = list.find(e => e.states.length === 1); let chosen = list.slice(0, NT); if (fixed && !chosen.includes(fixed)) chosen = [...chosen.slice(0, NT - 1), fixed];
chosen = chosen.map((e, j) => ({ id: j, period: e.states.length, basin: e.count / 16384, states: e.states, canon: canon(e.states) }));
const known = new Map(chosen.map(c => [c.canon, c.id])); for (const e of list) if (!known.has(canon(e.states))) known.set(canon(e.states), 'other');
// (1) the map alone: all one-bit mutants
const mutants = [], meta = [];
for (const c of chosen) c.states.forEach((s, si) => { for (let b = 0; b < 128; b++) { const a = Buffer.from(s, 'latin1'); a[b >> 3] ^= 1 << (b & 7); mutants.push(a.toString('latin1')); meta.push({ type: c.id, state: si, bit: b }); } });
const side = Math.ceil(Math.sqrt(mutants.length));
const fate = await census(side, 1, 300, mutants);
const selfCycle = await census(side, 1, 0, mutants);   // T0 = 0: is the mutant itself on a cycle of length <= 64?
const map = chosen.map(c => ({ type: c.id, period: c.period, basin: c.basin, n: 0, repaired: 0, converted: 0, newAttractor: 0, transient: 0, mutantIsAttractor: 0 }));
meta.forEach((m, i) => { const r = map[m.type]; r.n++; const st = fate[i];
  if (!st) r.transient++; else { const k = known.get(canon(st)); if (k === m.type) r.repaired++; else if (k !== undefined) r.converted++; else r.newAttractor++; }
  if (selfCycle[i] && selfCycle[i][0] === mutants[i]) r.mutantIsAttractor++; });
// (2) the lattice: a 3 x 3 patch of a mutant in a domain of its parent, in phase
const n = 64, N = n * n, P = [0, 0.1, 0.25, 0.5], M = [0, 0.25, 0.5, 1], lat = [];
let rs = 3; const rnd = () => (rs = (Math.imul(rs, 1664525) + 1013904223) >>> 0) / 4294967296;
const owners = new Map(); chosen.forEach(c => c.states.forEach(s => owners.set(s, c.id)));
for (const p of P) for (const m of M) {
  const sim = await makeSim({ ...common, W: n, H: n, swap: [p, p], smooth: [m, m], mixOn: p > 0, settleOn: m > 0 }); sim.setDict(text);
  for (const c of chosen) { const out = { erased: 0, persists: 0, spread: 0, domainLost: 0, trials: 0 };
    for (let trial = 0; trial < 12; trial++) {
      sim.reset(1); const g = sim.grid(), s = c.states[0], b = Math.floor(rnd() * 128), mu = Buffer.from(s, 'latin1'); mu[b >> 3] ^= 1 << (b & 7);
      for (let i = 0; i < N; i++) { const x = i % n, y = (i / n) | 0, inP = Math.abs(x - n / 2) <= 1 && Math.abs(y - n / 2) <= 1, src = inP ? mu : Buffer.from(s, 'latin1'); for (let k = 0; k < 16; k++) g[16 * i + k] = src[k]; }
      for (let t = 0; t < 200; t++) sim.step();
      let off = 0; for (let i = 0; i < N; i++) if (owners.get(key(sim.grid(), i)) !== c.id) off++;
      out.trials++; if (off === 0) out.erased++; else if (off <= 9) out.persists++; else if (off < N / 2) out.spread++; else out.domainLost++;
    }
    lat.push({ type: c.id, p, m, ...out }); }
}
const prov = provenance(import.meta.url, { dictId, cread, NT });
fs.writeFileSync(`${outDir}/heredity-${dictId}.json`, JSON.stringify({ provenance: prov, dict: dictId, types: chosen.map(({ states, canon, ...c }) => c), map, lattice: lat }));
const pc = (a, b) => (100 * a / b).toFixed(1) + ' %';
const md = [provLine(prov), `# Heredity: ${dictId}`, '', '## The map alone: every one-bit mutant of every state of each type, after 300 turns', '',
  '| type | period | basin | mutants | repaired | converted to another type | new attractor | still transient | the mutant is itself on a cycle |', '|---|---|---|---|---|---|---|---|---|',
  ...map.map(r => `| #${r.type} | ${r.period} | ${(100 * r.basin).toFixed(2)} % | ${r.n} | ${pc(r.repaired, r.n)} | ${pc(r.converted, r.n)} | ${pc(r.newAttractor, r.n)} | ${pc(r.transient, r.n)} | ${pc(r.mutantIsAttractor, r.n)} |`),
  '', '## The lattice: a 3 x 3 patch of a one-bit mutant in an in-phase domain of its parent, 64², 200 turns, 12 trials each', '', 'erased / persists (≤ 9 cells off the parent type) / spread (> 9) / domain lost (more than half the cells off)', '',
  '| type | swap p \\ median m | ' + M.join(' | ') + ' |', '|---|---|' + M.map(() => '---').join('|') + '|'];
for (const c of chosen) for (const p of P) md.push(`| #${c.id} (period ${c.period}) | ${p} | ` + M.map(m => { const r = lat.find(x => x.type === c.id && x.p === p && x.m === m); return `${r.erased}/${r.persists}/${r.spread}/${r.domainLost}`; }).join(' | ') + ' |');
fs.writeFileSync(`${outDir}/heredity-${dictId}.md`, md.join('\n') + '\n');
console.error('written', `${outDir}/heredity-${dictId}.md`);
