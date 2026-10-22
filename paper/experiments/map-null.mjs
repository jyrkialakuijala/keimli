// The random-mapping null for the decoder map (the map spine, deliverable 2). From N uniformly random cells, iterate the
// map and measure, after k = 1, 2, 4, ..., 256 applications: the number of distinct states, the collision entropy H2
// (unbiased: -log2 sum c(c-1) / (N(N-1))), the plug-in min-entropy H_inf = -log2(max c / N); the share of samples already
// on a cycle; and, at the end, the cycles reached, their periods and the largest basin share. The same for:
//   - uniform random maps on n points (Flajolet-Odlyzko): the exact functional graph is built for n <= 2^24, so cycles,
//     tails and basins are exact for that graph; n = 2^(H2 + 1) is the random map matched in one-step H2 to the decoder,
//     n = 2^20 and 2^24 for scale; three graph seeds each;
//   - the P-random map: each state maps to an independent draw from the decoder's own one-step output law P (estimated
//     from an independent N-sample: the outputs seen at least twice as atoms with weight c/N, the singleton mass spread
//     uniformly over 2^93 states, where a draw never repeats). Matched to the decoder in the whole one-step image law
//     (H2 and H_inf), not just its entropy; three seeds;
//   - hash:93 (the lattice null of ablation.mjs: keep the first 93 bits, a fixed hash of them for the rest), matched in
//     Shannon H(f(U)); it is idempotent (g(g(x)) = g(x)), so every sample is on a fixed point after one step.
// and the Flajolet-Odlyzko expectations at n = 2^128 (and 2^93) where they are meaningful.
// Usage: node paper/experiments/map-null.mjs [N=1000000] [T=300] [dict=ca-swarm-f]
// Output: paper/data/map/null-<dict>.json and paper/results tables in paper/data/map/null-<dict>.md
import fs from 'node:fs';
import { loadDict } from './dict-variants.mjs';
import { fastF, rng, entropies, hex } from './map-lib.mjs';
import { provenance, provLine } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const [N = 1e6, T = 300, ID = 'ca-swarm-f'] = process.argv.slice(2).map((a, i) => i === 2 ? a : Number(a));
const KS = [1, 2, 4, 8, 16, 32, 64, 128, 256].filter(k => k <= T);
const prov = provenance(import.meta.url, { N, T, dict: ID });
const outDir = dir + '/paper/data/map'; fs.mkdirSync(outDir, { recursive: true });
const log = (...a) => console.error(...a);

// ---------------------------------------------------------------- 16-byte state maps (the decoder, hash:93)
function runBytes(name, f, seed) {
  const t0 = Date.now(), r = rng(seed), X = new Uint8Array(16 * N), tmp = new Uint8Array(16);
  r.fill(X, 0, 16 * N);
  const X0 = Uint8Array.from(X), at = {};
  for (let t = 1; t <= T; t++) {
    for (let i = 0; i < N; i++) { f(X, 16 * i, tmp, 0); X.set(tmp, 16 * i); }
    if (KS.includes(t)) { const m = new Map(); for (let i = 0; i < N; i++) { const k = Buffer.from(X.buffer, 16 * i, 16).toString('latin1'); m.set(k, (m.get(k) || 0) + 1); } at[t] = entropies(m.values(), N); }
  }
  // cycles from the states after T steps
  const cyc = new Map(), cycleOf = new Array(N), onCycle = new Set(); let unsettled = 0;
  const memo = new Map();   // state -> cycle id for states found on cycles
  const y = new Uint8Array(16), st = new Uint8Array(16);
  for (let i = 0; i < N; i++) {
    const k0 = Buffer.from(X.buffer, 16 * i, 16).toString('latin1');
    if (memo.has(k0)) { cycleOf[i] = memo.get(k0); continue; }
    st.set(X.subarray(16 * i, 16 * i + 16)); y.set(st); let per = 0; const states = [k0];
    for (let t = 1; t <= 4096; t++) { f(y, 0, tmp, 0); y.set(tmp); let eq = true; for (let q = 0; q < 16; q++) if (y[q] !== st[q]) { eq = false; break; } if (eq) { per = t; break; } states.push(Buffer.from(y).toString('latin1')); }
    if (!per) { unsettled++; cycleOf[i] = null; continue; }
    states.length = per; const id = states.reduce((a, b) => a < b ? a : b);
    cyc.set(id, { period: per, basin: 0 }); for (const s of states) { memo.set(s, id); onCycle.add(s); }
    cycleOf[i] = id;
  }
  for (const id of cycleOf) if (id !== null) cyc.get(id).basin++;
  // tails: first t with the state on a cycle (second pass from the start states)
  const tails = new Int32Array(N).fill(-1); X.set(X0);
  for (let i = 0; i < N; i++) {
    y.set(X.subarray(16 * i, 16 * i + 16));
    for (let t = 0; t <= T; t++) { if (onCycle.has(Buffer.from(y).toString('latin1'))) { tails[i] = t; break; } f(y, 0, tmp, 0); y.set(tmp); }
  }
  return summarize(name, at, cyc, tails, unsettled, { seconds: (Date.now() - t0) / 1000, cycleStates: [...cyc.entries()].sort((a, b) => b[1].basin - a[1].basin).slice(0, 50).map(([k, v]) => ({ x: hex(Buffer.from(k, 'latin1')), ...v })) });
}
function summarize(name, at, cyc, tails, unsettled, extra = {}) {
  const basins = [...cyc.values()].sort((a, b) => b.basin - a.basin), settled = N - unsettled;
  const periodsByCycle = {}, periodsBySample = {};
  for (const c of basins) { periodsByCycle[c.period] = (periodsByCycle[c.period] || 0) + 1; periodsBySample[c.period] = (periodsBySample[c.period] || 0) + c.basin / N; }
  const onCycleAt = {}; for (const k of [0, ...KS]) { let c = 0; for (let i = 0; i < N; i++) if (tails[i] >= 0 && tails[i] <= k) c++; onCycleAt[k] = c / N; }
  const tl = Array.from(tails).filter(t => t >= 0).sort((a, b) => a - b);
  const res = { name, N, T, at, cycles: cyc.size, unsettled, periodsByCycle, periodsBySample, largestBasin: basins.length ? basins[0].basin / N : 0, top5Basins: basins.slice(0, 5).map(c => c.basin / N),
    onCycleAt, tailMean: tl.reduce((s, v) => s + v, 0) / (tl.length || 1), tailMedian: tl[tl.length >> 1] ?? null, tailP99: tl[Math.floor(0.99 * tl.length)] ?? null, tailMax: tl[tl.length - 1] ?? null, ...extra };
  log(`${name}: H2 ${KS.map(k => `k${k} ${fmt(at[k].H2)}`).join(' ')} | cycles ${cyc.size}, largest basin ${(100 * res.largestBasin).toFixed(1)} %, on cycle at 16: ${(100 * onCycleAt[16] || 0).toFixed(1)} %, unsettled ${unsettled}`);
  return res;
}
const fmt = v => v === Infinity ? '>' + (2 * Math.log2(N) - 1).toFixed(0) : v.toFixed(2);

// ---------------------------------------------------------------- number-state maps (random maps)
// a functional graph given as next[] (Int32Array; -1 means "leave to a fresh tail state"); samples start from start(i)
function analyzeGraph(next) {
  // cycles, cycle id per node, and tail length (distance to the cycle) per node; nodes whose path leaves (-1) get -1
  const n = next.length, state = new Uint8Array(n), cid = new Int32Array(n).fill(-2), tail = new Int32Array(n).fill(-1), period = [];
  const stack = new Int32Array(n);
  for (let s = 0; s < n; s++) {
    if (state[s]) continue;
    let sp = 0, x = s;
    while (x >= 0 && state[x] === 0) { state[x] = 1; stack[sp++] = x; x = next[x]; }
    let c = -1, t = -1;
    if (x >= 0 && state[x] === 1) {   // a new cycle: the stack from x on
      let j = sp - 1; while (stack[j] !== x) j--;
      c = period.length; period.push(sp - j);
      for (let q = j; q < sp; q++) { cid[stack[q]] = c; tail[stack[q]] = 0; state[stack[q]] = 2; }
      sp = j; t = 0;
    } else if (x >= 0) { c = cid[x]; t = tail[x]; }
    while (sp > 0) { const y = stack[--sp]; state[y] = 2; cid[y] = c; tail[y] = c >= 0 ? ++t : -1; if (c < 0) t = -1; }
  }
  return { cid, tail, period };
}
function runGraph(name, n, next, sampleNext, seed) {
  // states: a node index >= 0, or a negative id for a tail state of the P-map (never repeats; its successor is a fresh
  // draw). The uniform map starts from a uniform node (k = 0); the P-map starts from a draw of P, which is f(U) (k = 1).
  const t0 = Date.now(), r = rng(seed), rand = () => r.next() / 4294967296;
  const g = analyzeGraph(next);
  let tailId = -1; const fix = v => v === -1 ? tailId-- : v;
  const step = x => { if (x >= 0 && next[x] >= 0) return next[x]; return fix(sampleNext(rand)); };
  const X = new Float64Array(N), tails = new Int32Array(N).fill(-1), at = {}, start = sampleNext ? 1 : 0;
  for (let i = 0; i < N; i++) X[i] = sampleNext ? fix(sampleNext(rand)) : Math.floor(rand() * n);
  for (let t = start; t <= T; t++) {
    if (t > start) for (let i = 0; i < N; i++) X[i] = step(X[i]);
    for (let i = 0; i < N; i++) if (tails[i] < 0 && X[i] >= 0 && g.tail[X[i]] === 0) tails[i] = t;
    if (KS.includes(t)) { const m = new Map(); for (let i = 0; i < N; i++) m.set(X[i], (m.get(X[i]) || 0) + 1); at[t] = entropies(m.values(), N); }
  }
  // eventual cycles: a sample whose state at T is a node with a path to a cycle has a known cycle (and tail, if beyond T)
  const cyc = new Map(); let unsettled = 0, lateTails = 0;
  for (let i = 0; i < N; i++) {
    const x = X[i];
    if (x >= 0 && g.cid[x] >= 0) { const c = g.cid[x]; if (!cyc.has(c)) cyc.set(c, { period: g.period[c], basin: 0 }); cyc.get(c).basin++; if (tails[i] < 0) { tails[i] = T + g.tail[x]; lateTails++; } }
    else unsettled++;
  }
  const whole = { graphCycles: g.period.length, graphCyclicNodes: g.period.reduce((s, p) => s + p, 0), graphLongestCycle: g.period.reduce((m, p) => Math.max(m, p), 0), samplesReachingCycleAfterT: lateTails };
  return summarize(name, at, cyc, tails, unsettled, { n, seconds: (Date.now() - t0) / 1000, ...whole });
}
// splitmix-like 32-bit hashes for the random maps
const h32 = (x, s) => { let h = Math.imul((x ^ s) >>> 0, 0x9E3779B1) ^ (x >>> 16) ^ Math.imul(s, 0x85EBCA77); h = Math.imul(h ^ (h >>> 15), 0x2C1B3C6D); h = Math.imul(h ^ (h >>> 12), 0x297A2D39); return (h ^ (h >>> 15)) >>> 0; };
function uniformGraph(n, seed) { const next = new Int32Array(n); for (let i = 0; i < n; i++) next[i] = Math.floor((h32(i, seed) * 4294967296 + h32(i, seed ^ 0x5bd1e995)) / 18446744073709551616 * n); return next; }

// ---------------------------------------------------------------- run
const dictInfo = loadDict(ID), dict = dictInfo.bytes;
const f = fastF(dict, { skip: 6, V: 4096, coff: 0 });
const results = { provenance: prov, N, T, KS, dict: ID };
log('decoder ...');
results.decoder = runBytes(`decoder ${ID}`, f, 1);
const H2dec = results.decoder.at[1].H2;

// hash:93 as in ablation.mjs: keep the first K bits, a fixed hash of them for the rest (splitmix64 over the kept words)
{
  const K = 93, M64 = (1n << 64n) - 1n;
  const mix64 = z => { z = (z + 0x9E3779B97F4A7C15n) & M64; z = ((z ^ (z >> 30n)) * 0xBF58476D1CE4E5B9n) & M64; z = ((z ^ (z >> 27n)) * 0x94D049BB133111EBn) & M64; return z ^ (z >> 31n); };
  const g = (src, so, dst, d0) => {
    const b = Buffer.from(src.subarray(so, so + 16)); let lo = b.readBigUInt64LE(0), hi = b.readBigUInt64LE(8);
    hi &= (1n << BigInt(K - 64)) - 1n;   // kept: 64 + 29 bits
    let s = mix64(lo ^ mix64(hi)); const kept = hi;
    let out = kept | ((s << BigInt(K - 64)) & M64);
    const o = Buffer.alloc(16); o.writeBigUInt64LE(lo, 0); o.writeBigUInt64LE(out, 8); dst.set(o, d0);
  };
  const Nsave = N; log('hash:93 ...');
  // a short run suffices (it is idempotent): 10^5 samples, 4 steps
  const r = rng(3), a = new Uint8Array(16), b = new Uint8Array(16), c = new Uint8Array(16); let idem = 0, fixedAfter1 = 0; const m1 = new Map();
  for (let i = 0; i < 100000; i++) { r.fill(a, 0, 16); g(a, 0, b, 0); g(b, 0, c, 0); if (Buffer.compare(Buffer.from(b), Buffer.from(c)) === 0) idem++; const k = hex(b); m1.set(k, (m1.get(k) || 0) + 1); }
  results.hash93 = { name: 'hash:93 (keep 93 bits, hash the rest)', samples: 100000, idempotentShare: idem / 100000, onFixedPointAfter1: idem / 100000, distinctAfter1: m1.size,
    note: 'g(g(x)) = g(x) for every x: every image point is a fixed point, 2^93 attractors, all of period 1, every basin of size 2^35; matched in H(f(U)) but not in attractor structure' };
  log(`hash:93: idempotent on ${idem} of 100000`);
}

// uniform random maps
results.uniform = [];
const nMatched = Math.round(2 ** (H2dec + 1));
for (const [label, n] of [['matched H2: n = 2^(H2+1)', nMatched], ['n = 2^20', 2 ** 20], ['n = 2^24', 2 ** 24]]) for (const s of [1, 2, 3]) {
  log(`uniform ${label} seed ${s} ...`);
  const res = runGraph(`uniform random map, ${label} (${n}), seed ${s}`, n, uniformGraph(n, 0x1234567 * s), null, 100 + s);
  res.label = label; res.seed = s; results.uniform.push(res);
}

// the P-random map: atoms from an independent decoder sample (seed 2)
{
  log('P-map: building the one-step law ...');
  const r = rng(2), a = new Uint8Array(16), b = new Uint8Array(16), m = new Map();
  for (let i = 0; i < N; i++) { r.fill(a, 0, 16); f(a, 0, b, 0); const k = Buffer.from(b).toString('latin1'); m.set(k, (m.get(k) || 0) + 1); }
  const atoms = [...m.values()].filter(c => c >= 2).sort((x, y) => y - x), A = atoms.length;
  const cum = new Float64Array(A); let s = 0; for (let i = 0; i < A; i++) { s += atoms[i] / N; cum[i] = s; }
  const tailMass = 1 - s;
  const draw = u => { if (u >= s) return -1; let lo = 0, hi = A - 1; while (lo < hi) { const mid = (lo + hi) >> 1; if (cum[mid] > u) hi = mid; else lo = mid + 1; } return lo; };
  let pc = 0; for (const c of atoms) pc += (c / N) ** 2;
  results.pLaw = { atoms: A, atomMass: s, tailMass, H2: -Math.log2(pc), Hinf: -Math.log2(atoms[0] / N), note: 'atoms = outputs seen at least twice in an independent 10^6 sample (seed 2), weight c/N; the rest is a never-repeating tail' };
  results.pmap = [];
  for (const sd of [1, 2, 3]) { log(`P-map seed ${sd} ...`); const res = runPmap(`P-random map (decoder's one-step law), seed ${sd}`, A, draw, sd); res.seed = sd; results.pmap.push(res); }
}

// The P-random map, exactly as a deterministic map: every state x has one successor, an independent draw from P keyed by
// x. A draw from P is an atom (repeats possible) or a tail state (never drawn twice). So from atom a the orbit runs
// through a chain of len[a] - 1 tail states (each seen only on this chain) to the next atom next[a]; the chains are
// part of the map's functional graph. Trajectories can merge only at atoms, so the map is the functional graph on the
// atoms with edge lengths len[a]: its cycles are the map's cycles (period = sum of len over the cycle; the chain states
// between cycle atoms are cyclic too). A uniform start x0 goes to x1 = a fresh draw from P (k = 1); if that is a tail
// state, a fresh chain leads to the first atom.
function runPmap(name, A, draw, sd) {
  const t0 = Date.now(), r = rng(300 + sd), rand = () => r.next() / 4294967296;
  const U = (a, j) => (h32(a, 0x9e3779b1 * sd + j) * 4294967296 + h32(a ^ 0x5bd1e995, 0x7f4a7c15 * sd + 3 * j + 1)) / 18446744073709551616;
  const next = new Int32Array(A), len = new Int32Array(A);
  for (let a = 0; a < A; a++) { let L = 1, b; for (;;) { b = draw(U(a, L)); if (b >= 0) break; L++; } next[a] = b; len[a] = L; }
  const g = analyzeGraph(next);
  // steps from atom a to the first cycle atom; cycle period in steps
  const order = Array.from({ length: A }, (_, a) => a).sort((x, y) => g.tail[x] - g.tail[y]), stepTail = new Float64Array(A);
  for (const a of order) stepTail[a] = g.tail[a] === 0 ? 0 : len[a] + stepTail[next[a]];
  const perSteps = new Array(g.period.length).fill(0); for (let a = 0; a < A; a++) if (g.tail[a] === 0) perSteps[g.cid[a]] += len[a];
  // samples: arrival time at the first atom
  const atom0 = new Int32Array(N), arrive = new Float64Array(N);
  for (let i = 0; i < N; i++) { let t = 1, b = draw(rand()); while (b < 0) { t++; b = draw(rand()); } atom0[i] = b; arrive[i] = t; }
  // states at the checkpoints: (atom, offset in its chain) or a unique state on the initial chain
  const at = {}, cur = Int32Array.from(atom0), ct = Float64Array.from(arrive);
  for (const k of KS) {
    const m = new Map(); let uniq = 0;
    for (let i = 0; i < N; i++) {
      if (ct[i] > k) { uniq++; continue; }
      while (ct[i] + len[cur[i]] <= k) { ct[i] += len[cur[i]]; cur[i] = next[cur[i]]; }
      const key = cur[i] * 1048576 + (k - ct[i]); m.set(key, (m.get(key) || 0) + 1);
    }
    const counts = [...m.values()]; for (let q = 0; q < uniq; q++) counts.push(1);
    at[k] = entropies(counts, N);
  }
  const cyc = new Map(), tails = new Int32Array(N);
  for (let i = 0; i < N; i++) { const a = atom0[i], c = g.cid[a]; tails[i] = Math.min(2 ** 31 - 1, arrive[i] + stepTail[a]); if (!cyc.has(c)) cyc.set(c, { period: perSteps[c], basin: 0 }); cyc.get(c).basin++; }
  const res = summarize(name, at, cyc, tails, 0, { atoms: A, seconds: (Date.now() - t0) / 1000, graphCycles: g.period.length, cyclePeriodsSteps: perSteps, meanChainLength: len.reduce((s, v) => s + v, 0) / A });
  res.note = 'cycles and tails are exact for this realisation of the map (the atom graph is finite); "unsettled at T" is 0 by construction: tails beyond T are known exactly';
  return res;
}

// Flajolet-Odlyzko expectations for a uniform random map on n points
function fo(n) {
  const tau = [0]; for (let k = 1; k <= 256; k++) tau.push(Math.exp(-1 + tau[k - 1]));
  return { log2n: Math.log2(n), expectedCycles: 0.5 * Math.log(n), expectedCyclicNodes: Math.sqrt(Math.PI * n / 2), expectedRho: Math.sqrt(Math.PI * n / 2), expectedTail: Math.sqrt(Math.PI * n / 8), expectedCycleLength: Math.sqrt(Math.PI * n / 8),
    expectedFixedPoints: 1, expectedTwoCycles: 0.5, largestComponentShare: 0.7578, largestTreeShare: 0.4834,
    imageFractionAfterK: Object.fromEntries(KS.map(k => [k, 1 - tau[k]])),
    log2ImageAfterK: Object.fromEntries(KS.map(k => [k, Math.log2(n) + Math.log2(1 - tau[k])])),
    H2AfterK_approx: Object.fromEntries(KS.map(k => [k, Math.log2(n) - Math.log2(k + 1)])),
    pOnCycleWithinK_approx: Object.fromEntries(KS.map(k => [k, Math.min(1, (k * k / 2) / n)])) };
}
results.fo128 = fo(2 ** 128); results.fo93 = fo(2 ** 93); results.foMatched = fo(nMatched);
fs.writeFileSync(`${outDir}/null-${ID}.json`, JSON.stringify(results));

// ---------------------------------------------------------------- the tables
const md = [provLine(prov), '', `# The decoder map against random-mapping nulls (${ID})`, '',
  `N = ${N} samples, T = ${T} steps. H2 = -log2 of the unbiased collision probability among the N samples (">" = no collision: above the resolution 2 log2 N - 1), H_inf = -log2(max share).`, '',
  '## H2 / H_inf / distinct after k steps', '', `| map | ${KS.map(k => 'k=' + k).join(' | ')} |`, `|---|${KS.map(() => '---').join('|')}|`];
const rowsOf = res => [`| ${res.name} H2 | ${KS.map(k => fmt(res.at[k].H2)).join(' | ')} |`, `| ${res.name} H_inf | ${KS.map(k => res.at[k].Hinf.toFixed(2)).join(' | ')} |`, `| ${res.name} distinct | ${KS.map(k => res.at[k].distinct).join(' | ')} |`];
md.push(...rowsOf(results.decoder));
for (const r of results.pmap.slice(0, 1)) md.push(...rowsOf(r));
for (const r of results.uniform.filter(u => u.seed === 1)) md.push(...rowsOf(r));
md.push(`| FO n = 2^128, H2 ≈ 128 - log2(k+1) | ${KS.map(k => results.fo128.H2AfterK_approx[k].toFixed(1)).join(' | ')} |`);
md.push('', '## Cycles', '', '| map | cycles reached | unsettled at T | largest basin | top 5 basins | on a cycle at k = 1 / 4 / 16 / 64 / 256 | tail mean / p99 / max | periods (cycles: count) | periods (share of samples) |', '|---|---|---|---|---|---|---|---|---|');
const pct = v => (100 * v).toFixed(v < 0.01 ? 3 : 1) + ' %';
for (const r of [results.decoder, ...results.pmap, ...results.uniform]) md.push(`| ${r.name} | ${r.cycles} | ${r.unsettled} | ${pct(r.largestBasin)} | ${r.top5Basins.map(v => (100 * v).toFixed(1)).join(', ')} | ${[1, 4, 16, 64, 256].filter(k => k <= T).map(k => pct(r.onCycleAt[k])).join(' / ')} | ${r.tailMean.toFixed(1)} / ${r.tailP99} / ${r.tailMax} | ${Object.entries(r.periodsByCycle).map(([p, c]) => `${p}: ${c}`).join(', ')} | ${Object.entries(r.periodsBySample).map(([p, c]) => `${p}: ${(100 * c).toFixed(1)}`).join(', ')} |`);
md.push('', `hash:93: idempotent on ${(100 * results.hash93.idempotentShare).toFixed(1)} % of 10^5 samples: every sample is on a fixed point after one step; 2^93 attractors.`);
md.push('', `P-law: ${results.pLaw.atoms} atoms carrying ${(100 * results.pLaw.atomMass).toFixed(1)} % of the mass, H2 ${results.pLaw.H2.toFixed(2)}, H_inf ${results.pLaw.Hinf.toFixed(2)}.`);
md.push('', `Flajolet–Odlyzko at n = 2^128: ${results.fo128.expectedCycles.toFixed(1)} cycles expected, ${Math.log2(results.fo128.expectedCyclicNodes).toFixed(1)} log2 cyclic nodes, expected rho length 2^${Math.log2(results.fo128.expectedRho).toFixed(1)}, largest component 75.8 %, 1 fixed point and 1/2 two-cycle expected. At the matched n = ${nMatched}: ${results.foMatched.expectedCycles.toFixed(1)} cycles, rho ${results.foMatched.expectedRho.toFixed(0)} steps, cycle length ${results.foMatched.expectedCycleLength.toFixed(0)}.`);
fs.writeFileSync(`${outDir}/null-${ID}.md`, md.join('\n') + '\n');
console.log(md.join('\n'));
