// The whole-turn melting threshold p*(type, median) (second panel, A4): a small lattice filled with one attractor type
// in random phases, run under uniform mixing and settling at the page's three passes for a number of turns, the share of
// cells still on the type sampled at turns 1, 2, 4, 8, ... This is the closure index with the medium switched on: the
// return rate against the disturbance rate, and the threshold above which the type dissolves.
// Usage: node paper/experiments/pstar.mjs dict=ca-brotli-12 [cread=4096] [n=32] [turns=200] [types=3] [passes=3] [seeds=10]
//        [swaps=0.01,0.02,0.05,0.1,0.2,0.5] [medians=0,0.25,0.5,1] [out=paper/data/pstar]
import fs from 'node:fs';
import { makeSim } from '../../tools/ca-harness.mjs';
import { loadDict, asText } from './dict-variants.mjs';
import { provenance, provLine } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const dictId = opt.dict || 'ca-brotli-12', cread = Number(opt.cread ?? 4096), n = Number(opt.n ?? 32), T = Number(opt.turns ?? 200), NT = Number(opt.types ?? 3);
const passes = Number(opt.passes ?? 3), S = Number(opt.seeds ?? 10), outDir = opt.out || dir + '/paper/data/pstar'; fs.mkdirSync(outDir, { recursive: true });
const P = (opt.swaps || '0.01,0.02,0.05,0.1,0.2,0.5').split(',').map(Number), M = (opt.medians || '0,0.25,0.5,1').split(',').map(Number);
const designPath = `${dir}/paper/data/design/${dictId}.txt`;
const text = fs.existsSync(designPath) ? fs.readFileSync(designPath, 'latin1') : asText(loadDict(dictId).bytes);
const key = (g, i) => Buffer.from(g.subarray(16 * i, 16 * i + 16)).toString('latin1');
const common = { changer: 36, maxlen: 3, skip: 6, cread, coff: 0, passes, nbr: 1, altOrder: 'rotate', pairMode: 0, saltMode: 0 };
// types as droplets.mjs chooses them: 128² random cells, the decoder alone, seed 99
const simB = await makeSim({ ...common, W: 128, H: 128, swap: [0, 0], smooth: [0, 0], mixOn: false, settleOn: false }); simB.setDict(text); simB.reset(99);
for (let t = 0; t < 300; t++) simB.step();
const KMAX = 64, hist = []; for (let t = 0; t <= KMAX; t++) { hist.push(simB.grid().slice()); simB.step(); }
const types = new Map();
for (let i = 0; i < 16384; i++) { const k0 = key(hist[0], i); let per = 0; for (let k = 1; k <= KMAX; k++) if (key(hist[k], i) === k0) { per = k; break; }
  if (!per) continue; const st = []; for (let k = 0; k < per; k++) st.push(key(hist[k], i)); const c = st.reduce((a, b) => (b < a ? b : a)); const e = types.get(c) || { states: st, count: 0 }; e.count++; types.set(c, e); }
const list = [...types.values()].sort((a, b) => b.count - a.count); const fixed = list.find(e => e.states.length === 1);
let chosen = list.slice(0, NT); if (fixed && !chosen.includes(fixed)) chosen = [...chosen.slice(0, NT - 1), fixed];
chosen = chosen.map((e, j) => ({ id: j, period: e.states.length, basin: e.count / 16384, states: e.states, set: new Set(e.states) }));
console.error(`${dictId}: chosen ${chosen.map(c => `#${c.id} period ${c.period} basin ${(100 * c.basin).toFixed(2)} %`).join(', ')}`);
const N = n * n, samples = [1, 2, 4, 8, 16, 32, 64, 128, T].filter(t => t <= T), runs = [];
for (const p of P) for (const m of M) {
  const sim = await makeSim({ ...common, W: n, H: n, swap: [p, p], smooth: [m, m], mixOn: p > 0, settleOn: m > 0 }); sim.setDict(text);
  for (const c of chosen) for (let seed = 1; seed <= S; seed++) {
    let rs = seed; const rnd = () => (rs = (Math.imul(rs, 1664525) + 1013904223) >>> 0) / 4294967296;
    sim.reset(seed); const g = sim.grid(); for (let i = 0; i < N; i++) { const s = c.states[Math.floor(rnd() * c.states.length)]; for (let b = 0; b < 16; b++) g[16 * i + b] = s.charCodeAt(b); }
    const share = []; for (let t = 1; t <= T; t++) { sim.step(); if (samples.includes(t)) { let k = 0; const h = sim.grid(); for (let i = 0; i < N; i++) if (c.set.has(key(h, i))) k++; share.push([t, k / N]); } }
    runs.push({ type: c.id, p, m, seed, share });
  }
  console.error(`  p ${p} m ${m}`);
}
const prov = provenance(import.meta.url, { dictId, cread, n, T, NT, passes, S, P, M });
fs.writeFileSync(`${outDir}/pstar-${dictId}-n${n}-pass${passes}.json`, JSON.stringify({ provenance: prov, dict: dictId, n, T, passes, seeds: S, samples, types: chosen.map(c => ({ id: c.id, period: c.period, basin: c.basin })), runs }));
// table: mean share at turn T (and at turn 8) over seeds, per type and setting
const mean = a => a.reduce((x, y) => x + y, 0) / a.length;
const md = [provLine(prov), `# Melting threshold: ${dictId}, ${n}², ${T} turns, ${passes} passes, ${S} seeds; share of the type at turn ${T} (at turn 8 in brackets)`, ''];
for (const c of chosen) { md.push(`## #${c.id}: ${c.period === 1 ? 'fixed point' : c.period + '-cycle'}, basin ${(100 * c.basin).toFixed(2)} %`, '', '| swap \\ median | ' + M.join(' | ') + ' |', '|---|' + M.map(() => '---').join('|') + '|');
  for (const p of P) md.push(`| ${p} | ` + M.map(m => { const r = runs.filter(x => x.type === c.id && x.p === p && x.m === m); const at = t => mean(r.map(x => x.share.find(s => s[0] === t)[1])); return `${(100 * at(T)).toFixed(0)} % (${(100 * at(8)).toFixed(0)})`; }).join(' | ') + ' |'); md.push(''); }
fs.writeFileSync(`${outDir}/pstar-${dictId}-n${n}-pass${passes}.md`, md.join('\n') + '\n');
console.error('written', `${outDir}/pstar-${dictId}-n${n}-pass${passes}.md`);
