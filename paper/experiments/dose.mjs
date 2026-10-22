// The processor dose-response: how a CPU changer's information loss, attractor structure and lattice order depend on
// its instruction budget (steps per cell per turn), set beside the decoder and look-and-say at the same measures.
// (1) The map alone on 128² random cells: collision entropy H2 of a cell after 1 and 16 turns (equal-pair count;
// resolvable to about 27 bits), distinct cells, the share of cells on a cycle of length <= 64 after 300 turns, the
// number of attractor types and the largest basin. (2) The lattice, uniform swap 0.5 and median 1, 128², 400 turns:
// H2, distinct cells, the leading cycle type's share, the 8-bit block entropy per bit. Seed 1, quenched hashing.
// Usage: node paper/experiments/dose.mjs changer=6 [budgets=1,2,4,8,16,32,64,128,256] [out=paper/data/dose]
import fs from 'node:fs';
import { makeSim } from '../../tools/ca-harness.mjs';
import { loadDict, asText } from './dict-variants.mjs';
import { provenance, provLine } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const changer = Number(opt.changer ?? 6), budgets = (opt.budgets || '1,2,4,8,16,32,64,128,256').split(',').map(Number);
const pair = Number(opt.pair ?? 0), seed = Number(opt.seed ?? 1);   // 1: cells joined with a neighbour, concatenated (the BFF-like setting: two programs share one 32-byte tape)
const dictId = opt.dict || 'declaration', cread = Number(opt.cread ?? 4096), outDir = opt.out || dir + '/paper/data/dose'; fs.mkdirSync(outDir, { recursive: true });
const decl = fs.readFileSync(dir + '/src/changers/declaration.txt', 'latin1');
const text = dictId === 'declaration' ? decl : (fs.existsSync(`${dir}/paper/data/design/${dictId}.txt`) ? fs.readFileSync(`${dir}/paper/data/design/${dictId}.txt`, 'latin1') : asText(loadDict(dictId).bytes));
const n = 128, N = n * n, key = (g, i) => Buffer.from(g.subarray(16 * i, 16 * i + 16)).toString('latin1');
function h2(g) { const c = new Map(); for (let i = 0; i < N; i++) { const k = key(g, i); c.set(k, (c.get(k) || 0) + 1); } let p = 0; for (const v of c.values()) p += v * (v - 1) / 2; return { h2: p ? -Math.log2(p / (N * (N - 1) / 2)) : null, distinct: c.size }; }
function block8(g) { const b = new Float64Array(256); let tot = 0; for (let i = 0; i < N; i++) { const c = g.subarray(16 * i, 16 * i + 16); for (let s = 0; s < 128; s += 2) { let v = 0; for (let k = 0; k < 8; k++) { const q = (s + k) & 127; v = (v << 1) | ((c[q >> 3] >> (7 - (q & 7))) & 1); } b[v]++; tot++; } } let h = 0; for (const c of b) if (c) h -= (c / tot) * Math.log2(c / tot); return h / 8; }
function census(hist) {   // hist[0..64]: each cell's cycle (period <= 64) -> canonical type
  const types = new Map(); let on = 0;
  for (let i = 0; i < N; i++) { const k0 = key(hist[0], i); let p = 0; for (let k = 1; k <= 64; k++) if (key(hist[k], i) === k0) { p = k; break; } if (!p) continue; on++;
    let c = k0; for (let k = 1; k < p; k++) { const s = key(hist[k], i); if (s < c) c = s; } const e = types.get(c) || { p, count: 0 }; e.count++; types.set(c, e); }
  const list = [...types.entries()].sort((a, b) => b[1].count - a[1].count);
  return { onCycle: on / N, types: types.size, largest: list.length ? list[0][1].count / N : 0, largestPeriod: list.length ? list[0][1].p : 0, largestKey: list.length ? list[0][0] : null, owner: types };
}
const rows = [];
for (const steps of (changer === 36 || changer >= 50 ? [0] : budgets)) {
  const common = { W: n, H: n, changer, maxlen: 3, skip: 6, cread, coff: 0, passes: 1, nbr: 1, pairMode: pair, altOrder: 'rotate', steps };
  const t0 = Date.now();
  const a = await makeSim({ ...common, swap: [0, 0], smooth: [0, 0], mixOn: false, settleOn: false }); a.setDict(text); a.reset(seed);
  a.step(); const one = h2(a.grid()); for (let t = 1; t < 16; t++) a.step(); const sixteen = h2(a.grid());
  for (let t = 16; t < 300; t++) a.step(); const hist = []; for (let t = 0; t <= 64; t++) { hist.push(a.grid().slice()); a.step(); } const cen = census(hist);
  const b = await makeSim({ ...common, swap: [0.5, 0.5], smooth: [1, 1] }); b.setDict(text); b.reset(seed);
  for (let t = 0; t < 400; t++) b.step(); const g = b.grid(), lat = h2(g);
  const lh = []; for (let t = 0; t <= 64; t++) { lh.push(b.grid().slice()); b.step(); } const lc = census(lh);
  const row = { changer, steps, map: { h2_1: one.h2, distinct_1: one.distinct, h2_16: sixteen.h2, distinct_16: sixteen.distinct, onCycle: cen.onCycle, types: cen.types, largest: cen.largest, largestPeriod: cen.largestPeriod },
    lattice: { h2: lat.h2, distinct: lat.distinct, onCycle: lc.onCycle, types: lc.types, leader: lc.largest, leaderPeriod: lc.largestPeriod, block8: block8(g) }, seconds: (Date.now() - t0) / 1000 };
  rows.push(row); const f = v => v === null ? '>27' : v.toFixed(1);
  console.error(`kind ${changer}${pair ? ' pair ' + pair : ''} steps ${steps}: map H2 ${f(one.h2)} -> ${f(sixteen.h2)}, on cycles ${(100 * cen.onCycle).toFixed(0)} %, ${cen.types} types, largest ${(100 * cen.largest).toFixed(0)} % (period ${cen.largestPeriod}) | lattice H2 ${f(lat.h2)}, distinct ${lat.distinct}, on cycles ${(100 * lc.onCycle).toFixed(0)} %, leader ${(100 * lc.largest).toFixed(0)} %, block8 ${row.lattice.block8.toFixed(3)} | ${row.seconds.toFixed(0)} s`);
}
const prov = provenance(import.meta.url, { changer, budgets, dictId, cread, pair, seed });
fs.writeFileSync(`${outDir}/dose-kind${changer}${dictId !== 'declaration' ? '-' + dictId : ''}${pair ? '-pair' + pair : ''}${seed !== 1 ? '-seed' + seed : ''}.json`, JSON.stringify({ provenance: prov, changer, dict: dictId, pair, seed, rows }));
