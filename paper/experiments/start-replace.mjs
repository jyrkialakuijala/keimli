// Where do the closed type's seeds come from (second panel, A2)? The page frame is run from a random start twice: as it
// is, and with every cell whose decoder-alone attractor is a fixed point replaced by a copy of a random cell whose
// attractor is the leading cycle, so the start contains no fixed-point-basin cell. The share of fixed-point cells
// (cells with f(c) = c, any fixed point) is followed. If the frame still makes them, the medium creates the entries.
// Usage: node paper/experiments/start-replace.mjs dict=ca-brotli-12 [cread=4096] [n=256] [turns=2000] [seeds=1-20] [passes=3]
//        [pm=0.5 ps=1 | page=1] [every=20] [out=paper/data/start-replace]
import fs from 'node:fs';
import { makeSim } from '../../tools/ca-harness.mjs';
import { loadDict, asText } from './dict-variants.mjs';
import { provenance } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const dictId = opt.dict || 'ca-brotli-12', cread = Number(opt.cread ?? 4096), n = Number(opt.n ?? 256), T = Number(opt.turns ?? 2000);
const passes = Number(opt.passes ?? 3), every = Number(opt.every ?? 20), page = Number(opt.page ?? 1) === 1, pm = Number(opt.pm ?? 0.5), ps = Number(opt.ps ?? 1);
const [s0, s1] = (opt.seeds || '1-20').split('-').map(Number); const seeds = []; for (let s = s0; s <= (s1 ?? s0); s++) seeds.push(s);
const outDir = opt.out || dir + '/paper/data/start-replace'; fs.mkdirSync(outDir, { recursive: true });
const designPath = `${dir}/paper/data/design/${dictId}.txt`;
const text = fs.existsSync(designPath) ? fs.readFileSync(designPath, 'latin1') : asText(loadDict(dictId).bytes);
const N = n * n, key = (g, i) => Buffer.from(g.subarray(16 * i, 16 * i + 16)).toString('latin1');
const common = { W: n, H: n, changer: 36, maxlen: 3, skip: 6, cread, coff: 0, passes, nbr: 1, altOrder: 'rotate', pairMode: 0, saltMode: 0 };
const simB = await makeSim({ ...common, swap: [0, 0], smooth: [0, 0], mixOn: false, settleOn: false }); simB.setDict(text);
const simL = await makeSim({ ...common, swap: page ? [0, 1] : [pm, pm], smooth: page ? [0, 1] : [ps, ps], mixOn: true, settleOn: true }); simL.setDict(text);
const KMAX = 64;
function classify(start) {   // each start cell's attractor under f alone: period (0 = none found within KMAX after 300 turns) and canonical key
  simB.grid().set(start); for (let t = 0; t < 300; t++) simB.step();
  const hist = []; for (let t = 0; t <= KMAX; t++) { hist.push(simB.grid().slice()); simB.step(); }
  const per = new Int32Array(N), canon = new Array(N);
  for (let i = 0; i < N; i++) { const k0 = key(hist[0], i); let c = k0; for (let k = 1; k <= KMAX; k++) { const kk = key(hist[k], i); if (kk < c) c = kk; if (kk === k0) { per[i] = k; break; } } canon[i] = per[i] ? c : null; }
  return { per, canon };
}
function fixedShare(g) {   // cells that f maps to themselves
  simB.grid().set(g); simB.step(); const h = simB.grid(); let c = 0;
  for (let i = 0; i < N; i++) { let same = true; for (let b = 0; b < 16; b++) if (g[16 * i + b] !== h[16 * i + b]) { same = false; break; } if (same) c++; }
  return c / N;
}
const results = [];
for (const seed of seeds) {
  simL.reset(seed); const start = simL.grid().slice();
  const { per, canon } = classify(start);
  const count = new Map(); for (let i = 0; i < N; i++) if (per[i]) count.set(canon[i], (count.get(canon[i]) || 0) + 1);
  const lead = [...count.entries()].filter(([c]) => per[canon.indexOf(c)] > 1).sort((a, b) => b[1] - a[1])[0]?.[0];   // the leading cycle
  const fpCells = [], cycleCells = []; for (let i = 0; i < N; i++) { if (per[i] === 1) fpCells.push(i); else if (canon[i] === lead) cycleCells.push(i); }
  let rs = seed; const rnd = () => (rs = (Math.imul(rs, 1664525) + 1013904223) >>> 0) / 4294967296;
  for (const arm of ['control', 'replaced']) {
    simL.reset(seed); const g = simL.grid();
    if (arm === 'replaced') for (const i of fpCells) { const j = cycleCells[Math.floor(rnd() * cycleCells.length)]; for (let b = 0; b < 16; b++) g[16 * i + b] = start[16 * j + b]; }
    const after = arm === 'replaced' ? classify(g.slice()).per.filter(v => v === 1).length : fpCells.length;
    const track = [[0, fixedShare(g)]]; let firstSeen = null;
    for (let t = 1; t <= T; t++) { simL.step(); if (t % every === 0) { const f = fixedShare(simL.grid()); track.push([t, f]); if (firstSeen === null && f > 0.001) firstSeen = t; } }
    results.push({ seed, arm, fpCellsAtStart: fpCells.length, fpCellsAfterReplacement: after, cycleCells: cycleCells.length, firstSeen, finalFixedShare: track[track.length - 1][1], track });
    console.error(`seed ${seed} ${arm}: fixed-point cells at start ${fpCells.length} -> ${after}; first seen ${firstSeen}; final ${(100 * track[track.length - 1][1]).toFixed(1)} %`);
  }
}
const tag = `${dictId}-${page ? 'page' : `pm${pm}-ps${ps}`}-n${n}-t${T}-pass${passes}-seeds${s0}-${s1 ?? s0}`;
fs.writeFileSync(`${outDir}/${tag}.json`, JSON.stringify({ provenance: provenance(import.meta.url, { dictId, cread, n, T, passes, page, pm, ps, seeds, every }), dict: dictId, n, T, passes, page, results }));
console.error('written', tag);
