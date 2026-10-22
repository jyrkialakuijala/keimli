// Local information dynamics (Lizier, Prokopenko and Zomaya 2008, 2012) on the lattice, per bit: each (cell, bit) is a
// binary time series. Active information storage A = I(x_{t+1}; x_t^{(k)}) (how much a bit's own past k values predict
// its next), and transfer entropy T = I(y_t; x_{t+1} | x_t^{(k)}) from the same bit of each of the four neighbours y
// (averaged over the four), apparent (one source at a time). The rest of the next bit's entropy, H(x_{t+1}) - A - T,
// is an upper-bound proxy for what neither storage nor single-source transfer explains, which includes the
// "modification" a computation does and the hashing of the medium. Plug-in estimates over all cells and a sample of
// 32 bit positions, over a window of turns after a transient; k = 3. Uniform settings swap 1/2 and median 1, 128².
// Usage: node paper/experiments/infodyn.mjs changer=36 [dict=ca-swarm-f] [steps=256] [pair=0] [turns=300] [window=200]
import fs from 'node:fs';
import { makeSim } from '../../tools/ca-harness.mjs';
import { loadDict, asText } from './dict-variants.mjs';
import { provenance } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(2).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
const changer = Number(opt.changer ?? 36), dictId = opt.dict || (changer === 36 ? 'ca-swarm-f' : 'declaration'), steps = Number(opt.steps ?? 0), pair = Number(opt.pair ?? 0);
const T0 = Number(opt.turns ?? 300), WIN = Number(opt.window ?? 200), n = Number(opt.n ?? 128), K = 3, pm = Number(opt.pm ?? 0.5), ps = Number(opt.ps ?? 1);
const outDir = opt.out || dir + '/paper/data/infodyn'; fs.mkdirSync(outDir, { recursive: true });
const decl = fs.readFileSync(dir + '/src/changers/declaration.txt', 'latin1');
const text = dictId === 'declaration' ? decl : (fs.existsSync(`${dir}/paper/data/design/${dictId}.txt`) ? fs.readFileSync(`${dir}/paper/data/design/${dictId}.txt`, 'latin1') : asText(loadDict(dictId).bytes));
const sim = await makeSim({ W: n, H: n, changer, maxlen: 3, skip: 6, cread: Number(opt.cread ?? 4096), coff: 0, passes: 1, nbr: 1, pairMode: pair, altOrder: 'rotate', steps, swap: [pm, pm], smooth: [ps, ps], mixOn: pm > 0, settleOn: ps > 0 });
sim.setDict(text); sim.reset(1);
const N = n * n, BITS = Array.from({ length: 32 }, (_, j) => (j * 4 + 1) % 128);   // a spread sample of bit positions
for (let t = 0; t < T0; t++) sim.step();
// record the sampled bits over the window: hist[t][i * 32 + b]
const hist = [], side = [];   // side[t][i * 32 + b]: the two ring-adjacent bits q - 1 and q + 1 of the same cell, packed
const bit = (g, i, q) => (g[16 * i + ((q & 127) >> 3)] >> (q & 7)) & 1;
for (let t = 0; t < WIN + K + 1; t++) { const g = sim.grid(), h = new Uint8Array(N * 32), s = new Uint8Array(N * 32); for (let i = 0; i < N; i++) for (let b = 0; b < 32; b++) { const q = BITS[b]; h[i * 32 + b] = bit(g, i, q); s[i * 32 + b] = (bit(g, i, q + 127) << 1) | bit(g, i, q + 1); } hist.push(h); side.push(s); sim.step(); }
// counts: past (k bits) x next, and past x source x next
const cA = new Float64Array(1 << (K + 1)), cT = new Float64Array(1 << (K + 2)), cS = new Float64Array(1 << (K + 3));   // cS: past x (two adjacent bits) x next
const nb = i => { const x = i % n, y = (i / n) | 0; return [x > 0 ? i - 1 : -1, x < n - 1 ? i + 1 : -1, y > 0 ? i - n : -1, y < n - 1 ? i + n : -1]; };
for (let t = K - 1; t < WIN + K; t++) for (let i = 0; i < N; i++) { const ns = nb(i); for (let b = 0; b < 32; b++) {
  let past = 0; for (let j = 0; j < K; j++) past = (past << 1) | hist[t - j][i * 32 + b];
  const next = hist[t + 1][i * 32 + b]; cA[(past << 1) | next]++;
  for (const m of ns) if (m >= 0) cT[(((past << 1) | hist[t][m * 32 + b]) << 1) | next]++;
  cS[(((past << 2) | side[t][i * 32 + b]) << 1) | next]++;
} }
const H = c => { const s = c.reduce((a, b) => a + b, 0); let h = 0; for (const v of c) if (v) h -= (v / s) * Math.log2(v / s); return h; };
const marg = (c, keep) => { const m = new Map(); c.forEach((v, idx) => { const k = keep(idx); m.set(k, (m.get(k) || 0) + v); }); return [...m.values()]; };
// A = H(next) + H(past) - H(past, next); T = H(past, src) + H(past, next) - H(past) - H(past, src, next)
const Hnext = H(marg(cA, x => x & 1)), Hpast = H(marg(cA, x => x >> 1)), HpastNext = H(Array.from(cA));
const A = Hnext + Hpast - HpastNext;
const TpastSrc = H(marg(cT, x => x >> 1)), TpastNext = H(marg(cT, x => ((x >> 2) << 1) | (x & 1))), Tpast = H(marg(cT, x => x >> 2)), Tall = H(Array.from(cT));
const TE = TpastSrc + TpastNext - Tpast - Tall;
// within the cell: I(next; the two adjacent bits | past)
const SpastSrc = H(marg(cS, x => x >> 1)), SpastNext = H(marg(cS, x => ((x >> 3) << 1) | (x & 1))), Spast = H(marg(cS, x => x >> 3)), Sall = H(Array.from(cS));
const TS = SpastSrc + SpastNext - Spast - Sall;
const res = { provenance: provenance(import.meta.url, opt), changer, dict: dictId, steps, pair, pm, ps, n, T0, WIN, K, Hnext, A, TE, TS, rest: Hnext - A - TE - TS };
fs.writeFileSync(`${outDir}/infodyn-kind${changer}-${dictId}${steps ? '-s' + steps : ''}${pair ? '-pair' + pair : ''}-pm${pm}-ps${ps}.json`, JSON.stringify(res));
console.log(`kind ${changer} ${dictId}${steps ? ' steps ' + steps : ''}${pair ? ' pair' : ''} pm ${pm} ps ${ps}: H(next) ${Hnext.toFixed(3)} | storage A ${A.toFixed(3)} | from a neighbouring cell ${TE.toFixed(3)} | from the adjacent bits ${TS.toFixed(3)} | rest ${res.rest.toFixed(3)} bits`);
