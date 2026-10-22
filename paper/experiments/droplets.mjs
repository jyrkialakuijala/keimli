// Droplet competition: why does the medium, not the basin, pick the winner? A disc of attractor type X (a fixed point or
// a cycle of the decoder) is planted in a sea of type Y, under uniform mixing (swap slider p) and settling (median m), and
// the share of X is followed. Every ordered pair of the dictionary's main types, both phase modes (every cell of a cycle
// domain in the same phase, or each cell in a random phase), a grid of (p, m), and a noise sweep (random bit flips per
// cell per turn). Attractor types come from the decoder alone on random cells (the basins of replicators.mjs); a cell
// belongs to a type when its 16 bytes are one of the type's states.
// Usage: node paper/experiments/droplets.mjs dict=ca-brotli-12 [cread=4096] [n=128] [turns=400] [r=16] [types=3] [out=paper/data/droplets]
import fs from 'node:fs';
import { makeSim } from '../../tools/ca-harness.mjs';
import { loadDict, asText } from './dict-variants.mjs';
import { provenance, provLine } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const dictId = opt.dict || 'ca-brotli-12', cread = Number(opt.cread ?? 4096), n = Number(opt.n ?? 128), T = Number(opt.turns ?? 400), R = Number(opt.r ?? 16), NT = Number(opt.types ?? 3);
const outDir = opt.out || dir + '/paper/data/droplets'; fs.mkdirSync(outDir, { recursive: true });
const designPath = `${dir}/paper/data/design/${dictId}.txt`;
const text = fs.existsSync(designPath) ? fs.readFileSync(designPath, 'latin1') : asText(loadDict(dictId).bytes);
const N = n * n, key = (g, i) => Buffer.from(g.subarray(16 * i, 16 * i + 16)).toString('latin1');
const common = { W: n, H: n, changer: 36, maxlen: 3, skip: 6, cread, coff: 0, passes: 1, nbr: 1, altOrder: 'rotate', pairMode: 0 };
// ---- 1. the attractor types and their basins: the decoder alone from random cells
const simB = await makeSim({ ...common, swap: [0, 0], smooth: [0, 0], mixOn: false, settleOn: false });
simB.setDict(text); simB.reset(99);
for (let t = 0; t < 300; t++) simB.step();
const KMAX = 64, hist = []; for (let t = 0; t <= 2 * KMAX; t++) { hist.push(simB.grid().slice()); simB.step(); }
const types = new Map();   // canonical key -> { states: [keys in order], count }
for (let i = 0; i < N; i++) {
  const k0 = key(hist[0], i); let p = 0; for (let k = 1; k <= KMAX; k++) if (key(hist[k], i) === k0) { p = k; break; }
  if (!p) continue; const st = []; for (let k = 0; k < p; k++) st.push(key(hist[k], i));
  const c = st.reduce((a, b) => (b < a ? b : a)); const e = types.get(c) || { states: st, count: 0 }; e.count++; types.set(c, e);
}
let list = [...types.values()].sort((a, b) => b.count - a.count);
const fixed = list.find(e => e.states.length === 1);   // always include the largest fixed point, the type the frame favours
let chosen = list.slice(0, NT); if (fixed && !chosen.includes(fixed)) chosen = [...chosen.slice(0, NT - 1), fixed];
chosen = chosen.map((e, j) => ({ id: j, period: e.states.length, basin: e.count / N, states: e.states }));
const owner = new Map(); chosen.forEach(c => c.states.forEach(s => owner.set(s, c.id)));
console.error(`${dictId}: ${types.size} attractor types from ${N} random cells; chosen: ${chosen.map(c => `#${c.id} period ${c.period} basin ${(100 * c.basin).toFixed(2)} %`).join(', ')}`);
// ---- 2. droplet runs
let rs = 1; const rnd = () => (rs = (Math.imul(rs, 1664525) + 1013904223) >>> 0) / 4294967296;
const sims = new Map();
async function simFor(p, m) { const k = `${p}/${m}`; if (!sims.has(k)) { const s = await makeSim({ ...common, swap: [p, p], smooth: [m, m], mixOn: p > 0, settleOn: m > 0 }); s.setDict(text); sims.set(k, s); } return sims.get(k); }
function plant(g, X, Y, phase) {   // phase: 'coherent' every cell in state 0 of its cycle; 'random' a random state each
  const cx = n / 2, cy = n / 2;
  for (let i = 0; i < N; i++) { const x = i % n, y = (i / n) | 0, inX = (x - cx) ** 2 + (y - cy) ** 2 < R * R, c = inX ? X : Y;
    const s = phase === 'coherent' ? c.states[0] : c.states[Math.floor(rnd() * c.states.length)];
    for (let b = 0; b < 16; b++) g[16 * i + b] = s.charCodeAt(b); }
}
function shares(g) { const c = new Array(chosen.length).fill(0); let other = 0; for (let i = 0; i < N; i++) { const o = owner.get(key(g, i)); if (o === undefined) other++; else c[o]++; } return { types: c.map(v => v / N), other: other / N }; }
function noise(g, lam) { if (!lam) return; const flips = Math.round(lam * N); for (let f = 0; f < flips; f++) { const i = Math.floor(rnd() * N), b = Math.floor(rnd() * 128); g[16 * i + (b >> 3)] ^= 1 << (b & 7); } }
async function run(X, Y, p, m, phase, lam) {
  const sim = await simFor(p, m); sim.reset(1); plant(sim.grid(), X, Y, phase); const s0 = shares(sim.grid()), track = [[0, s0.types[X.id], s0.types[Y.id], s0.other]];
  for (let t = 1; t <= T; t++) { sim.step(); noise(sim.grid(), lam); if (t % 20 === 0) { const s = shares(sim.grid()); track.push([t, s.types[X.id], s.types[Y.id], s.other]); } }
  const last = track[track.length - 1];
  return { X: X.id, Y: Y.id, p, m, phase, lam, x0: s0.types[X.id], xT: last[1], yT: last[2], otherT: last[3], track };
}
const P = [0, 0.1, 0.25, 0.5], M = [0, 0.25, 0.5, 1], runs = [];
for (const X of chosen) for (const Y of chosen) { if (X === Y) continue;
  for (const phase of ['coherent', 'random']) for (const p of P) for (const m of M) runs.push(await run(X, Y, p, m, phase, 0));
  for (const lam of [0.01, 0.05, 0.2, 1]) for (const m of [0, 0.5, 1]) runs.push(await run(X, Y, 0.1, m, 'coherent', lam));
  console.error(`  pair #${X.id} in #${Y.id} done`);
}
// whole-lattice domains without a droplet: does a cycle domain survive in random phases? (X = Y)
for (const Y of chosen) for (const phase of ['coherent', 'random']) for (const m of M) {
  const sim = await simFor(0.1, m); sim.reset(1); plant(sim.grid(), Y, Y, phase);
  for (let t = 1; t <= T; t++) sim.step();
  runs.push({ X: Y.id, Y: Y.id, p: 0.1, m, phase, lam: 0, x0: 1, xT: shares(sim.grid()).types[Y.id], whole: true });
}
const prov = provenance(import.meta.url, { dictId, cread, n, T, R, NT });
fs.writeFileSync(`${outDir}/droplets-${dictId}-n${n}-t${T}.json`, JSON.stringify({ provenance: prov, dict: dictId, n, T, R, types: chosen.map(c => ({ id: c.id, period: c.period, basin: c.basin })), runs }));
// ---- 3. tables
const sym = r => { const g = r.xT / r.x0; return r.xT > 0.9 ? 'X takes all' : g > 2 ? `grows ×${g.toFixed(1)}` : g < 0.05 ? 'vanishes' : g < 0.5 ? `shrinks ×${g.toFixed(2)}` : `holds ×${g.toFixed(2)}`; };
const out = [provLine(prov), `# Droplets: ${dictId}, ${n}², ${T} turns, disc radius ${R}`, '', 'Types: ' + chosen.map(c => `#${c.id} ${c.period === 1 ? 'fixed point' : c.period + '-cycle'}, basin ${(100 * c.basin).toFixed(2)} %`).join('; '), ''];
for (const phase of ['coherent', 'random']) for (const X of chosen) for (const Y of chosen) { if (X === Y) continue;
  out.push(`## #${X.id} (period ${X.period}) planted in #${Y.id} (period ${Y.period}), ${phase} phases: X share at turn ${T} / at turn 0`, '', '| swap p \\ median m | ' + M.join(' | ') + ' |', '|---|' + M.map(() => '---').join('|') + '|');
  for (const p of P) out.push(`| ${p} | ` + M.map(m => sym(runs.find(r => !r.whole && r.X === X.id && r.Y === Y.id && r.p === p && r.m === m && r.phase === phase && r.lam === 0))).join(' | ') + ' |');
  out.push(''); }
out.push('## Noise (swap 0.1, coherent): X share at the end / at the start', '', '| pair | flips per cell per turn | m = 0 | m = 0.5 | m = 1 |', '|---|---|---|---|---|');
for (const X of chosen) for (const Y of chosen) { if (X === Y) continue; for (const lam of [0.01, 0.05, 0.2, 1]) out.push(`| #${X.id} in #${Y.id} | ${lam} | ` + [0, 0.5, 1].map(m => sym(runs.find(r => !r.whole && r.X === X.id && r.Y === Y.id && r.p === 0.1 && r.m === m && r.lam === lam))).join(' | ') + ' |'); }
out.push('', '## Whole-lattice domains (swap 0.1): share of the type after ' + T + ' turns', '', '| type | phases | ' + M.map(m => 'm = ' + m).join(' | ') + ' |', '|---|---|' + M.map(() => '---').join('|') + '|');
for (const Y of chosen) for (const phase of ['coherent', 'random']) out.push(`| #${Y.id} (period ${Y.period}) | ${phase} | ` + M.map(m => (100 * runs.find(r => r.whole && r.Y === Y.id && r.phase === phase && r.m === m).xT).toFixed(0) + ' %').join(' | ') + ' |');
fs.writeFileSync(`${outDir}/droplets-${dictId}-n${n}-t${T}.md`, out.join('\n') + '\n');
console.error('written', `${outDir}/droplets-${dictId}-n${n}-t${T}.md`);
