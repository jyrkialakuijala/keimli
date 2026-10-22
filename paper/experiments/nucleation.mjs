// Nucleation tests (results/nucleation.md). The leading fixed point X of a dictionary against its leading cycle Y, at
// the page's three settling passes, uniform (swap p, median m). Three modes, one job per (dict, p, m, seed):
//   radius       discs of X of every radius in the list, in a sea of Y with a disorder fraction q (q = 0: in phase;
//                q = 1: every cell a random phase); the share of X is tracked, so each disc grows or dies -> R*.
//   spontaneous  a sea of Y with disorder q and no disc; the first appearance of X, the number and size of its
//                4-connected clusters over time, and its share -> where and how often X starts on its own.
//   q            a disc of radius r in seas of each disorder q in the list -> R* against the sea's order.
// Usage: node paper/experiments/nucleation.mjs dict=ca-brotli-12 mode=radius p=0.1 m=0.5 seed=1 [n=128] [turns=1000]
//        [radii=1,2,3,4,5,6,7,8,10,12,16] [q=0] [qs=0,0.1,0.25,0.5,1] [r=16] [cread=4096] [types=3] [every=20]
//        [out=paper/data/nucleation]
import fs from 'node:fs';
import { makeSim } from '../../tools/ca-harness.mjs';
import { loadDict, asText } from './dict-variants.mjs';
import { provenance } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const dictId = opt.dict || 'ca-brotli-12', mode = opt.mode || 'radius', cread = Number(opt.cread ?? 4096), n = Number(opt.n ?? 128);
const T = Number(opt.turns ?? (mode === 'spontaneous' ? 2000 : 1000)), NT = Number(opt.types ?? 3), seed = Number(opt.seed ?? 1), every = Number(opt.every ?? (mode === 'spontaneous' ? 10 : 20));
const p = Number(opt.p ?? 0.1), m = Number(opt.m ?? 0.5), q0 = Number(opt.q ?? 0), R0 = Number(opt.r ?? 16);
const radii = (opt.radii || '1,2,3,4,5,6,7,8,10,12,16').split(',').map(Number), qs = (opt.qs || '0,0.1,0.25,0.5,1').split(',').map(Number);
const outDir = opt.out || dir + '/paper/data/nucleation'; fs.mkdirSync(outDir, { recursive: true });
const tag = `${dictId}-${mode}-p${p}-m${m}-q${q0}${mode === 'q' ? '-r' + R0 : ''}-n${n}-t${T}-seed${seed}`;
if (fs.existsSync(`${outDir}/${tag}.json`)) { console.error('exists', tag); process.exit(0); }
const designPath = `${dir}/paper/data/design/${dictId}.txt`;
const text = fs.existsSync(designPath) ? fs.readFileSync(designPath, 'latin1') : asText(loadDict(dictId).bytes);
const N = n * n, key = (g, i) => Buffer.from(g.subarray(16 * i, 16 * i + 16)).toString('latin1');
const common = { W: n, H: n, changer: 36, maxlen: 3, skip: 6, cread, coff: 0, passes: 3, nbr: 1, altOrder: 'rotate', pairMode: 0, saltMode: 0 };
// the types, as droplets.mjs chooses them
const simB = await makeSim({ ...common, W: 128, H: 128, swap: [0, 0], smooth: [0, 0], mixOn: false, settleOn: false }); simB.setDict(text); simB.reset(99);
for (let t = 0; t < 300; t++) simB.step();
const KMAX = 64, hist = []; for (let t = 0; t <= 2 * KMAX; t++) { hist.push(simB.grid().slice()); simB.step(); }
const types = new Map();
for (let i = 0; i < 16384; i++) { const k0 = key(hist[0], i); let per = 0; for (let k = 1; k <= KMAX; k++) if (key(hist[k], i) === k0) { per = k; break; }
  if (!per) continue; const st = []; for (let k = 0; k < per; k++) st.push(key(hist[k], i)); const c = st.reduce((a, b) => (b < a ? b : a)); const e = types.get(c) || { states: st, count: 0 }; e.count++; types.set(c, e); }
const list = [...types.values()].sort((a, b) => b.count - a.count), fixed = list.find(e => e.states.length === 1);
let chosen = list.slice(0, NT); if (fixed && !chosen.includes(fixed)) chosen = [...chosen.slice(0, NT - 1), fixed];
chosen = chosen.map((e, j) => ({ id: j, period: e.states.length, basin: e.count / 16384, states: e.states }));
const X = chosen.filter(c => c.period === 1).sort((a, b) => b.basin - a.basin)[0], Y = chosen.filter(c => c.period > 1).sort((a, b) => b.basin - a.basin)[0];
if (!X || !Y) { console.error(`${dictId}: needs a fixed point and a cycle among the chosen types`); process.exit(1); }
const onX = new Set(X.states), onY = new Set(Y.states);
console.error(`${tag}: X #${X.id} fixed point basin ${(100 * X.basin).toFixed(2)} %, Y #${Y.id} ${Y.period}-cycle basin ${(100 * Y.basin).toFixed(2)} %`);
// the runs
let rs = seed * 2654435761 >>> 0 || 1; const rnd = () => (rs = (Math.imul(rs, 1664525) + 1013904223) >>> 0) / 4294967296;
const cx = n / 2 + Math.floor((rnd() - 0.5) * n / 4), cy = n / 2 + Math.floor((rnd() - 0.5) * n / 4);
const sim = await makeSim({ ...common, swap: [p, p], smooth: [m, m], mixOn: p > 0, settleOn: m > 0 }); sim.setDict(text);
const put = (g, i, s) => { for (let b = 0; b < 16; b++) g[16 * i + b] = s.charCodeAt(b); };
const inDisc = (i, r) => { const x = i % n, y = (i / n) | 0; return (x - cx) ** 2 + (y - cy) ** 2 < r * r; };
function plant(g, r, q) {   // disc of X (radius r, 0 for none) in a sea of Y; a fraction q of the sea's cells in a random phase, the rest in phase 0
  for (let i = 0; i < N; i++) { if (r && inDisc(i, r)) put(g, i, X.states[0]); else put(g, i, rnd() < q ? Y.states[Math.floor(rnd() * Y.period)] : Y.states[0]); }
}
const mask = new Uint8Array(N), seen = new Uint8Array(N), stack = new Int32Array(N);
function clusters(g) {   // 4-connected clusters of cells on X: count, largest, and the share of X and Y
  let x = 0, y = 0; for (let i = 0; i < N; i++) { const k = key(g, i); mask[i] = onX.has(k) ? 1 : 0; x += mask[i]; if (onY.has(k)) y++; }
  seen.fill(0); let count = 0, largest = 0;
  for (let i = 0; i < N; i++) { if (!mask[i] || seen[i]) continue; count++; let sp = 0, size = 0; stack[sp++] = i; seen[i] = 1;
    while (sp) { const j = stack[--sp]; size++; const jx = j % n, jy = (j / n) | 0;
      for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) { const kx = jx + dx, ky = jy + dy; if (kx < 0 || ky < 0 || kx >= n || ky >= n) continue; const k = ky * n + kx; if (mask[k] && !seen[k]) { seen[k] = 1; stack[sp++] = k; } } }
    if (size > largest) largest = size; }
  return { x: x / N, y: y / N, clusters: count, largest };
}
function follow(withClusters) {
  const track = []; let first = null, first01 = null;
  const rec = t => { const c = withClusters ? clusters(sim.grid()) : (() => { let x = 0, y = 0; const g = sim.grid(); for (let i = 0; i < N; i++) { const k = key(g, i); if (onX.has(k)) x++; else if (onY.has(k)) y++; } return { x: x / N, y: y / N }; })();
    if (first === null && c.x > 0) first = t; if (first01 === null && c.x >= 0.001) first01 = t; track.push([t, c.x, c.y, c.clusters ?? null, c.largest ?? null]); };
  rec(0); for (let t = 1; t <= T; t++) { sim.step(); if (t % every === 0) rec(t); }
  const last = track[track.length - 1];
  return { x0: track[0][1], xT: last[1], yT: last[2], first, first01, track };
}
const runs = [];
if (mode === 'radius') for (const r of radii) { sim.reset(seed); plant(sim.grid(), r, q0); runs.push({ r, q: q0, ...follow(false) }); console.error(`  R ${r}: ${(100 * runs[runs.length - 1].xT).toFixed(0)} %`); }
if (mode === 'spontaneous') { sim.reset(seed); plant(sim.grid(), 0, q0); runs.push({ r: 0, q: q0, ...follow(true) }); const r = runs[0]; console.error(`  first X at turn ${r.first}, 0.1 % at ${r.first01}, end ${(100 * r.xT).toFixed(0)} %`); }
if (mode === 'q') for (const q of qs) { sim.reset(seed); plant(sim.grid(), R0, q); runs.push({ r: R0, q, ...follow(false) }); console.error(`  q ${q}: ${(100 * runs[runs.length - 1].xT).toFixed(0)} %`); }
fs.writeFileSync(`${outDir}/${tag}.json`, JSON.stringify({ provenance: provenance(import.meta.url, { dictId, mode, cread, n, T, NT, seed, p, m, q0, radii, qs, R0, every }), dict: dictId, mode, n, T, p, m, seed, centre: [cx, cy], X: { id: X.id, basin: X.basin }, Y: { id: Y.id, period: Y.period, basin: Y.basin }, runs }));
console.error('written', tag);
