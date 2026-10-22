// The closure index: a candidate mechanism for which attractor types hold domains under mixing. For types A and B of
// the decoder (as in droplets.mjs) and a crossover rate r, take a random state a of A and b of B (random phases), make
// the crossover child (each differing bit taken from b with probability r: what one mixing exchange does), apply the
// local map f once, and ask whether the child lands on a state of A or B (closed), or elsewhere (open). C(A, A) with
// random phases measures whether a type's own domain survives phase disorder; C(A, B) whether the interface between
// two types stays inside the two (invasion, stand-off) or makes strangers (melting). Single-cell computation, no lattice.
// Usage: node paper/experiments/closure.mjs dict=ca-brotli-12 [cread=4096] [types=3] [samples=20000] [out=paper/data/closure]
import fs from 'node:fs';
import { makeSim } from '../../tools/ca-harness.mjs';
import { loadDict, asText } from './dict-variants.mjs';
import { provenance, provLine } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const dictId = opt.dict || 'ca-brotli-12', cread = Number(opt.cread ?? 4096), NT = Number(opt.types ?? 3), S = Number(opt.samples ?? 20000), outDir = opt.out || dir + '/paper/data/closure';
fs.mkdirSync(outDir, { recursive: true });
const designPath = `${dir}/paper/data/design/${dictId}.txt`;
const text = fs.existsSync(designPath) ? fs.readFileSync(designPath, 'latin1') : asText(loadDict(dictId).bytes);
const common = { changer: 36, maxlen: 3, skip: 6, cread, coff: 0, passes: 1, nbr: 1, pairMode: 0, swap: [0, 0], smooth: [0, 0], mixOn: false, settleOn: false };
const key = (g, i) => Buffer.from(g.subarray(16 * i, 16 * i + 16)).toString('latin1');
// types, exactly as droplets.mjs chooses them
const simB = await makeSim({ ...common, W: 128, H: 128 }); simB.setDict(text); simB.reset(99);
for (let t = 0; t < 300; t++) simB.step();
const KMAX = 64, hist = []; for (let t = 0; t <= KMAX; t++) { hist.push(simB.grid().slice()); simB.step(); }
const types = new Map();
for (let i = 0; i < 16384; i++) { const k0 = key(hist[0], i); let p = 0; for (let k = 1; k <= KMAX; k++) if (key(hist[k], i) === k0) { p = k; break; }
  if (!p) continue; const st = []; for (let k = 0; k < p; k++) st.push(key(hist[k], i)); const c = st.reduce((a, b) => (b < a ? b : a)); const e = types.get(c) || { states: st, count: 0 }; e.count++; types.set(c, e); }
let list = [...types.values()].sort((a, b) => b.count - a.count);
const fixed = list.find(e => e.states.length === 1); let chosen = list.slice(0, NT); if (fixed && !chosen.includes(fixed)) chosen = [...chosen.slice(0, NT - 1), fixed];
chosen = chosen.map((e, j) => ({ id: j, period: e.states.length, basin: e.count / 16384, states: e.states }));
const owner = new Map(); chosen.forEach(c => c.states.forEach(s => owner.set(s, c.id)));
// children through f, in batches on a lattice with mixing and settling off
const side = Math.ceil(Math.sqrt(S)), simF = await makeSim({ ...common, W: side, H: side }); simF.setDict(text);
let rs = 7; const rnd = () => (rs = (Math.imul(rs, 1664525) + 1013904223) >>> 0) / 4294967296;
function closure(A, B, r, steps = 1) {
  const g = simF.grid();
  for (let i = 0; i < side * side; i++) { const a = A.states[Math.floor(rnd() * A.states.length)], b = B.states[Math.floor(rnd() * B.states.length)];
    for (let k = 0; k < 16; k++) { const x = a.charCodeAt(k), y = b.charCodeAt(k); let m = 0; for (let j = 0; j < 8; j++) if (rnd() < r) m |= 1 << j; g[16 * i + k] = (x & ~m) | (y & m); } }
  for (let s = 0; s < steps; s++) simF.step();
  const h = simF.grid(); let inA = 0, inB = 0; for (let i = 0; i < side * side; i++) { const o = owner.get(key(h, i)); if (o === A.id) inA++; else if (o === B.id) inB++; }
  const n = side * side; return { inA: inA / n, inB: inB / n, closed: (inA + inB) / n };
}
// the majority closure: the settling stage's bitwise majority over neighbours in different phases is a 3-parent
// crossover; M(A) = the share of maj(a1, a2, a3) (three random states of A, random phases) that land on A after f
function majClosure(A, steps = 1) {
  const g = simF.grid(), pick = () => A.states[Math.floor(rnd() * A.states.length)];
  for (let i = 0; i < side * side; i++) { const a = pick(), b = pick(), c = pick(); for (let k = 0; k < 16; k++) { const x = a.charCodeAt(k), y = b.charCodeAt(k), z = c.charCodeAt(k); g[16 * i + k] = (x & y) | (x & z) | (y & z); } }
  for (let s = 0; s < steps; s++) simF.step();
  const h = simF.grid(); let inA = 0; for (let i = 0; i < side * side; i++) if (owner.get(key(h, i)) === A.id) inA++; return inA / (side * side);
}
const maj = chosen.map(A => ({ A: A.id, maj1: majClosure(A, 1), maj8: majClosure(A, 8) }));
const R = [0.05, 0.25, 0.5], rows = [];
for (const A of chosen) for (const B of chosen) for (const r of R) for (const steps of [1, 8]) rows.push({ A: A.id, B: B.id, r, steps, ...closure(A, B, r, steps) });
const prov = provenance(import.meta.url, { dictId, cread, NT, S });
fs.writeFileSync(`${outDir}/closure-${dictId}.json`, JSON.stringify({ provenance: prov, dict: dictId, types: chosen.map(({ states, ...c }) => c), rows, maj }));
const md = [provLine(prov), `# Closure: ${dictId}`, '', 'Types: ' + chosen.map(c => `#${c.id} ${c.period === 1 ? 'fixed point' : c.period + '-cycle'} (basin ${(100 * c.basin).toFixed(2)} %)`).join(', '), '',
  'A random state of A crossed with a random state of B (each differing bit from B with probability r), then f applied 1 or 8 times: the share landing on A, on B, and on either (closed).', '',
  '| A × B | r | after 1 step: on A / on B / closed | after 8 steps: on A / on B / closed |', '|---|---|---|---|'];
for (const A of chosen) for (const B of chosen) for (const r of R) { const a = rows.find(x => x.A === A.id && x.B === B.id && x.r === r && x.steps === 1), b = rows.find(x => x.A === A.id && x.B === B.id && x.r === r && x.steps === 8);
  const f = x => `${(100 * x.inA).toFixed(0)} / ${(100 * x.inB).toFixed(0)} / **${(100 * x.closed).toFixed(0)} %**`; md.push(`| #${A.id} × #${B.id} | ${r} | ${f(a)} | ${f(b)} |`); }
md.push('', '| type | majority closure: maj of three random-phase states, then f once / 8 times |', '|---|---|', ...maj.map(m => `| #${m.A} | ${(100 * m.maj1).toFixed(0)} % / ${(100 * m.maj8).toFixed(0)} % |`));
fs.writeFileSync(`${outDir}/closure-${dictId}.md`, md.join('\n') + '\n'); console.error('written', `${outDir}/closure-${dictId}.md`);
