// The matched droplet block (second panel, A1): droplets.mjs rerun at the page's settling (three majority passes) with
// the seed as a parameter. One job = one dictionary at one (swap p, median m) and one seed; the batch droplets3.sh runs
// the grid. Modes: 'pairs' (every ordered pair of the chosen types, a disc of X of radius r in a sea of Y, coherent and
// random phases), 'whole' (the whole lattice one type, coherent and random phases: does the domain survive?),
// 'premelt' (the open type run alone in random phases for 100 turns first, then the closed type's disc planted in
// whatever is left), 'radius' (the closed type's disc in the open type at several radii). The hashing stays quenched
// (salt 0) as on the page; the seed sets the phases and the disc's centre.
// Usage: node paper/experiments/droplets3.mjs dict=ca-brotli-12 p=0.1 m=0.5 seed=1 [cread=4096] [n=128] [turns=2000]
//        [passes=3] [r=16] [types=3] [modes=pairs,whole,premelt] [radii=1,2,4,8,16,32] [every=20] [out=paper/data/droplets3]
import fs from 'node:fs';
import { makeSim } from '../../tools/ca-harness.mjs';
import { loadDict, asText } from './dict-variants.mjs';
import { provenance } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const dictId = opt.dict || 'ca-brotli-12', cread = Number(opt.cread ?? 4096), n = Number(opt.n ?? 128), T = Number(opt.turns ?? 2000);
const R = Number(opt.r ?? 16), NT = Number(opt.types ?? 3), passes = Number(opt.passes ?? 3), seed = Number(opt.seed ?? 1), every = Number(opt.every ?? 20);
const p = Number(opt.p ?? 0.1), m = Number(opt.m ?? 0.5), modes = (opt.modes || 'pairs,whole,premelt').split(',');
const radii = (opt.radii || '1,2,4,8,16,32').split(',').map(Number), PRE = Number(opt.premelt ?? 100);
const outDir = opt.out || dir + '/paper/data/droplets3'; fs.mkdirSync(outDir, { recursive: true });
const tag = `${dictId}-p${p}-m${m}-pass${passes}-n${n}-t${T}-seed${seed}${modes.includes('radius') ? '-radius' : ''}`;
if (fs.existsSync(`${outDir}/${tag}.json`)) { console.error('exists', tag); process.exit(0); }
const designPath = `${dir}/paper/data/design/${dictId}.txt`;
const text = fs.existsSync(designPath) ? fs.readFileSync(designPath, 'latin1') : asText(loadDict(dictId).bytes);
const N = n * n, key = (g, i) => Buffer.from(g.subarray(16 * i, 16 * i + 16)).toString('latin1');
const common = { W: n, H: n, changer: 36, maxlen: 3, skip: 6, cread, coff: 0, passes, nbr: 1, altOrder: 'rotate', pairMode: 0, saltMode: 0 };
// ---- 1. the attractor types and their basins, exactly as droplets.mjs chooses them (seed 99, the decoder alone)
const simB = await makeSim({ ...common, swap: [0, 0], smooth: [0, 0], mixOn: false, settleOn: false });
simB.setDict(text); simB.reset(99);
for (let t = 0; t < 300; t++) simB.step();
const KMAX = 64, hist = []; for (let t = 0; t <= 2 * KMAX; t++) { hist.push(simB.grid().slice()); simB.step(); }
const types = new Map();
for (let i = 0; i < N; i++) {
  const k0 = key(hist[0], i); let per = 0; for (let k = 1; k <= KMAX; k++) if (key(hist[k], i) === k0) { per = k; break; }
  if (!per) continue; const st = []; for (let k = 0; k < per; k++) st.push(key(hist[k], i));
  const c = st.reduce((a, b) => (b < a ? b : a)); const e = types.get(c) || { states: st, count: 0 }; e.count++; types.set(c, e);
}
const list = [...types.values()].sort((a, b) => b.count - a.count);
const fixed = list.find(e => e.states.length === 1);
let chosen = list.slice(0, NT); if (fixed && !chosen.includes(fixed)) chosen = [...chosen.slice(0, NT - 1), fixed];
chosen = chosen.map((e, j) => ({ id: j, period: e.states.length, basin: e.count / N, states: e.states }));
const owner = new Map(); chosen.forEach(c => c.states.forEach(s => owner.set(s, c.id)));
console.error(`${tag}: ${types.size} types; chosen ${chosen.map(c => `#${c.id} period ${c.period} basin ${(100 * c.basin).toFixed(2)} %`).join(', ')}`);
// ---- 2. the runs
let rs = seed * 2654435761 >>> 0 || 1; const rnd = () => (rs = (Math.imul(rs, 1664525) + 1013904223) >>> 0) / 4294967296;
const cx = n / 2 + Math.floor((rnd() - 0.5) * n / 2), cy = n / 2 + Math.floor((rnd() - 0.5) * n / 2);   // the disc's centre moves with the seed
const sim = await makeSim({ ...common, swap: [p, p], smooth: [m, m], mixOn: p > 0, settleOn: m > 0 }); sim.setDict(text);
const state = (c, phase) => phase === 'coherent' ? c.states[0] : c.states[Math.floor(rnd() * c.states.length)];
const put = (g, i, s) => { for (let b = 0; b < 16; b++) g[16 * i + b] = s.charCodeAt(b); };
const inDisc = (i, r) => { const x = i % n, y = (i / n) | 0, dx = Math.min(Math.abs(x - cx), n - Math.abs(x - cx)), dy = Math.min(Math.abs(y - cy), n - Math.abs(y - cy)); return dx * dx + dy * dy < r * r; };
function plant(g, X, Y, phase, r) { for (let i = 0; i < N; i++) put(g, i, state(inDisc(i, r) ? X : Y, phase)); }
function shares(g) { const c = new Array(chosen.length).fill(0); let other = 0; for (let i = 0; i < N; i++) { const o = owner.get(key(g, i)); if (o === undefined) other++; else c[o]++; } return { types: c.map(v => v / N), other: other / N }; }
function follow(X, Y, from) {   // run T turns from the planted grid, sampling the shares
  const s0 = shares(sim.grid()), track = [[from, s0.types[X.id], s0.types[Y.id], s0.other]];
  for (let t = 1; t <= T; t++) { sim.step(); if (t % every === 0) { const s = shares(sim.grid()); track.push([from + t, s.types[X.id], s.types[Y.id], s.other]); } }
  const last = track[track.length - 1];
  return { x0: s0.types[X.id], xT: last[1], yT: last[2], otherT: last[3], track };
}
const runs = [];
if (modes.includes('pairs')) for (const X of chosen) for (const Y of chosen) { if (X === Y) continue;
  for (const phase of ['coherent', 'random']) { sim.reset(seed); plant(sim.grid(), X, Y, phase, R); runs.push({ mode: 'pair', X: X.id, Y: Y.id, r: R, phase, ...follow(X, Y, 0) }); }
  console.error(`  pair #${X.id} in #${Y.id}`); }
if (modes.includes('whole')) for (const Y of chosen) for (const phase of ['coherent', 'random']) {
  sim.reset(seed); plant(sim.grid(), Y, Y, phase, 0); runs.push({ mode: 'whole', X: Y.id, Y: Y.id, r: 0, phase, ...follow(Y, Y, 0) }); }
if (modes.includes('premelt')) for (const X of chosen.filter(c => c.period === 1)) for (const Y of chosen.filter(c => c.period > 1)) {
  sim.reset(seed); plant(sim.grid(), Y, Y, 'random', 0); for (let t = 0; t < PRE; t++) sim.step();   // the sea alone first
  const g = sim.grid(), pre = shares(g); for (let i = 0; i < N; i++) if (inDisc(i, R)) put(g, i, X.states[0]);
  runs.push({ mode: 'premelt', X: X.id, Y: Y.id, r: R, phase: 'coherent', seaBefore: pre.types[Y.id], ...follow(X, Y, PRE) }); }
if (modes.includes('radius')) for (const X of chosen.filter(c => c.period === 1)) for (const Y of chosen.filter(c => c.period > 1)) for (const r of radii) for (const phase of ['coherent', 'random']) {
  sim.reset(seed); plant(sim.grid(), X, Y, phase, r); runs.push({ mode: 'radius', X: X.id, Y: Y.id, r, phase, ...follow(X, Y, 0) }); }
const prov = provenance(import.meta.url, { dictId, cread, n, T, R, NT, passes, seed, p, m, modes, radii, PRE, every });
fs.writeFileSync(`${outDir}/${tag}.json`, JSON.stringify({ provenance: prov, dict: dictId, n, T, R, passes, p, m, seed, centre: [cx, cy], types: chosen.map(c => ({ id: c.id, period: c.period, basin: c.basin })), runs }));
console.error('written', tag);
