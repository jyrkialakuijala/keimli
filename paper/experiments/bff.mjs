// BFF (Agüera y Arcas et al. 2024, "Computational Life", arXiv 2406.19108, §2) and a census of its replicators.
// The interpreter and the soup follow the reference code the paper names (github.com/paradigms-of-intelligence/cubff,
// --lang bff_noheads, files bff.inc.h and common_language.h) exactly: 64-byte tapes, two concatenated into 128 bytes,
// instruction pointer, head0 and head1 all starting at 0, heads taken mod 128, 2^13 = 8192 steps (every byte read counts,
// no-ops included), unmatched bracket = halt, background mutation per byte of the 128-byte pair before execution with
// probability round(p * 2^30) / 2^30 (default p = 1/4096 = 0.024 %), a fresh random permutation each epoch paired
// consecutively, and cubff's SplitMix64 random numbers, so a run with a given seed is the run cubff makes (checked by
// `validate`: cubff's own regression log testdata/bff_noheads.txt, 2^17 tapes, seed 10248).
// Usage:
//   node paper/experiments/bff.mjs selftest
//   node paper/experiments/bff.mjs validate                      # reproduce cubff testdata/bff_noheads.txt
//   node paper/experiments/bff.mjs soup seed=1 n=131072 mut=0.000244140625 epochs=16384 after=2048 every=16 [thr=1.0]
//   node paper/experiments/bff.mjs census in=paper/data/bff/soup-....json [top=4] [nx=256] [nmut=...]
import fs from 'node:fs';
import zlib from 'node:zlib';
import { provenance, provLine } from './provenance.mjs';

const T = 64, T2 = 128, STEPS = 8192;
// ---------------------------------------------------------------- the interpreter (cubff bff.inc.h, noheads)
const OP = new Uint8Array(256).fill(11);   // 11 = no-op
const OPS = { '[': 0, ']': 1, '+': 2, '-': 3, '.': 4, ',': 5, '<': 6, '>': 7, '{': 8, '}': 9 };
for (const [c, k] of Object.entries(OPS)) OP[c.charCodeAt(0)] = k;
OP[0] = 10;
export const isInsn = b => OP[b] < 10;
// Runs the 128-byte tape in place. Returns the number of non-no-op instructions (cubff's "ops"). If `trace` is a
// Uint8Array(128), marks the positions at which an instruction was executed.
export function run(tape, steps = STEPS, trace = null) {
  let pc = 0, h0 = 0, h1 = 0, nskip = 0, i = 0;
  for (; i < steps; i++) {
    h0 &= 127; h1 &= 127;
    const k = OP[tape[pc]];
    if (trace && k < 10) trace[pc] = 1;
    switch (k) {
      case 6: h0--; break;
      case 7: h0++; break;
      case 8: h1--; break;
      case 9: h1++; break;
      case 2: tape[h0] = (tape[h0] + 1) & 255; break;
      case 3: tape[h0] = (tape[h0] - 1) & 255; break;
      case 4: tape[h1] = tape[h0]; break;
      case 5: tape[h0] = tape[h1]; break;
      case 0:
        if (tape[h0] === 0) {
          let d = 1; pc++;
          for (; pc < T2 && d > 0; pc++) { const o = OP[tape[pc]]; if (o === 1) d--; else if (o === 0) d++; }
          pc--;
          if (d !== 0) pc = T2;
        }
        break;
      case 1:
        if (tape[h0] !== 0) {
          let d = 1; pc--;
          for (; pc >= 0 && d > 0; pc--) { const o = OP[tape[pc]]; if (o === 1) d++; else if (o === 0) d--; }
          pc++;
          if (d !== 0) pc = -1;
        }
        break;
      default: nskip++;
    }
    if (pc < 0) { i++; break; }
    pc++;
    if (pc >= T2) { i++; break; }
  }
  return i - nskip;
}
// ---------------------------------------------------------------- SplitMix64 on (hi, lo) uint32 halves
let RH = 0, RL = 0;   // result registers
function mulc(h, l, ch, cl) {   // (h,l) * (ch,cl) mod 2^64 -> RH, RL
  const a0 = l & 0xffff, a1 = l >>> 16, b0 = cl & 0xffff, b1 = cl >>> 16;
  const p00 = a0 * b0, p01 = a0 * b1, p10 = a1 * b0, p11 = a1 * b1;
  const mid = (p00 >>> 16) + (p01 & 0xffff) + (p10 & 0xffff);
  const carry = p11 + Math.floor(p01 / 65536) + Math.floor(p10 / 65536) + Math.floor(mid / 65536);
  RH = (carry + Math.imul(h, cl) + Math.imul(l, ch)) >>> 0;
  RL = Math.imul(l, cl) >>> 0;
}
export function sm64(h, l) {   // SplitMix64(z) -> RH, RL
  let lo = l + 0x7f4a7c15, hi = h + 0x9e3779b9;
  if (lo > 0xffffffff) { lo -= 0x100000000; hi++; }
  hi >>>= 0; lo >>>= 0;
  let nl = (lo >>> 30 | hi << 2) >>> 0, nh = hi >>> 30; mulc(hi ^ nh, lo ^ nl, 0xbf58476d, 0x1ce4e5b9); hi = RH; lo = RL;
  nl = (lo >>> 27 | hi << 5) >>> 0; nh = hi >>> 27; mulc(hi ^ nh, lo ^ nl, 0x94d049bb, 0x133111eb); hi = RH; lo = RL;
  nl = (lo >>> 31 | hi << 1) >>> 0; nh = hi >>> 31; RH = (hi ^ nh) >>> 0; RL = (lo ^ nl) >>> 0;
}
const M64 = (1n << 64n) - 1n;
const toBig = (h, l) => (BigInt(h) << 32n) | BigInt(l);
const smBig = x => { x &= M64; sm64(Number(x >> 32n), Number(x & 0xffffffffn)); return toBig(RH, RL); };
function smRef(x) {   // reference SplitMix64 in BigInt, for the self-test
  let z = (x + 0x9e3779b97f4a7c15n) & M64;
  z = ((z ^ (z >> 30n)) * 0xbf58476d1ce4e5b9n) & M64;
  z = ((z ^ (z >> 27n)) * 0x94d049bb133111ebn) & M64;
  return z ^ (z >> 31n);
}
// ---------------------------------------------------------------- the soup (cubff common_language.h)
export function makeSoup(n, seed0, mut) {
  const S = BigInt(seed0);
  const seedF = x => smBig(smBig(S) ^ smBig(BigInt(x)));       // cubff's seed(x)
  const soup = new Uint8Array(n * T), s = new Uint32Array(n), tape = new Uint8Array(T2);
  const mprob = Math.round(mut * 2 ** 30);
  { const base = (BigInt(T * n) * seedF(0n)) & M64;            // InitPrograms(seed(0))
    for (let idx = 0; idx < n; idx++) for (let i = 0; i < T; i++) { const v = smBig(base + BigInt(T * idx + i)); soup[idx * T + i] = Number(v & 255n); } }
  let epoch = 0;
  const st = { soup, n, ops: 0, runs: 0 };
  st.step = () => {
    for (let i = 0; i < n; i++) s[i] = i;
    const seedHL = smBig(S);
    for (let i = n; i-- > 0;) {                                  // do_shuffle: j = SplitMix64(seed(epoch*len+i)) % (i+1)
      const x = epoch * n + i;
      sm64(Math.floor(x / 4294967296) >>> 0, x >>> 0); let h = RH, l = RL;
      h ^= Number(seedHL >> 32n); l ^= Number(seedHL & 0xffffffffn);
      sm64(h >>> 0, l >>> 0); sm64(RH, RL);
      const m = i + 1, j = ((RH % m) * (4294967296 % m) + (RL % m)) % m;
      const t = s[i]; s[i] = s[j]; s[j] = t;
    }
    const es = seedF(BigInt(epoch)), base = (BigInt(n) * es) & M64;
    for (let p = 0; 2 * p < n; p++) {
      const a = s[2 * p] * T, b = s[2 * p + 1] * T;
      tape.set(soup.subarray(a, a + T), 0); tape.set(soup.subarray(b, b + T), T);
      if (mprob > 0) {
        const r = ((base + BigInt(p)) * 128n) & M64, rh = Number(r >> 32n), rl = Number(r & 0xffffffffn);
        for (let i = 0; i < T2; i++) {
          sm64(rh, (rl | i) >>> 0);
          if ((((RL >>> 8) | (RH << 24)) & 0x3fffffff) < mprob) tape[i] = RL & 255;
        }
      }
      st.ops += run(tape); st.runs++;
      soup.set(tape.subarray(0, T), a); soup.set(tape.subarray(T, T2), b);
    }
    epoch++; st.epoch = epoch;
  };
  st.epoch = 0;
  return st;
}
// soup statistics: brotli q2 (cubff's measure), byte entropy H0, higher-order entropy, tape-level H2, distinct tapes
export function stats(soup, n) {
  const br = zlib.brotliCompressSync(soup, { params: { [zlib.constants.BROTLI_PARAM_QUALITY]: 2, [zlib.constants.BROTLI_PARAM_LGWIN]: 24, [zlib.constants.BROTLI_PARAM_SIZE_HINT]: soup.length } }).length;
  const cnt = new Float64Array(256); for (let i = 0; i < soup.length; i++) cnt[soup[i]]++;
  let h0 = 0; for (const c of cnt) if (c) { const f = c / soup.length; h0 -= f * Math.log2(f); }
  const bpb = br * 8 / soup.length;
  const m = new Map(); const buf = Buffer.from(soup.buffer, soup.byteOffset, soup.length);
  for (let i = 0; i < n; i++) { const k = buf.toString('latin1', i * T, i * T + T); m.set(k, (m.get(k) || 0) + 1); }
  let p2 = 0, top = 0, topk = null; for (const [k, c] of m) { p2 += c * (c - 1); if (c > top) { top = c; topk = k; } }
  const H2 = p2 > 0 ? -Math.log2(p2 / (n * (n - 1))) : null;
  let insn = 0; for (let b = 0; b < 256; b++) if (b && OP[b] < 10) insn += cnt[b];
  return { brotli: br, bpb: +bpb.toFixed(6), h0: +h0.toFixed(6), higher: +(h0 - bpb).toFixed(6), H2: H2 === null ? null : +H2.toFixed(3), distinct: m.size, topShare: +(top / n).toFixed(5), zeroFrac: +(cnt[0] / soup.length).toFixed(5), insnFrac: +(insn / soup.length).toFixed(5), _map: m, _top: topk };
}
export const hex = a => Buffer.from(a).toString('hex');
export const fromHex = h => new Uint8Array(Buffer.from(h, 'hex'));
export function show(a) {   // printable: instructions as themselves, 0 as '0', other bytes as '·'
  let s = ''; for (const b of a) s += b === 0 ? '0' : OP[b] < 10 ? String.fromCharCode(b) : '·'; return s;
}
// ---------------------------------------------------------------- self-test
function selftest() {
  let fails = 0; const ok = (c, msg) => { if (!c) { fails++; console.log('FAIL', msg); } else console.log('ok  ', msg); };
  const P = (s, pad = T2) => { const a = new Uint8Array(pad); for (let i = 0; i < s.length; i++) a[i] = s[i] === '0' ? 0 : s.charCodeAt(i); return a; };
  // SplitMix64 vs BigInt reference
  let good = true; for (const x of [0n, 1n, 12345n, 0xffffffffffffffffn, 0x123456789abcdefn, 1n << 63n]) if (smBig(x) !== smRef(x)) good = false;
  for (let k = 0; k < 2000; k++) { const x = smRef(BigInt(k) * 977n); if (smBig(x) !== smRef(x)) good = false; }
  ok(good, 'SplitMix64 (32-bit halves) equals the BigInt reference on 2006 inputs');
  // 1. '+' increments tape[head0]=tape[0], which is the '+' itself (43 -> 44 = ','); then pc=1 reads 0 (no-op) ...
  { const t = P('+'); const ops = run(t); ok(t[0] === 44 && ops === 1, `"+" increments itself to "," (ops ${ops})`); }
  // 2. '>' moves head0 to 1, '.' copies tape[1]='.' (46) to tape[head1=0]: tape[0] becomes '.'; then pc=2 is 0 (no-op)
  { const t = P('>.'); run(t); ok(t[0] === 46 && t[1] === 46, '">." copies tape[1] onto tape[0]'); }
  // 3. head moves wrap mod 128: '<' from 0 to 127, '-' decrements tape[127] 0 -> 255
  { const t = P('<-'); run(t); ok(t[127] === 255 && t[0] === 60, '"<-" wraps head0 to 127 and decrements it to 255'); }
  // 4. '{' wraps head1 to 127; ',' copies tape[head1=127] (0) to tape[head0=0]: tape[0] becomes 0
  { const t = P('{,'); run(t); ok(t[0] === 0 && t[1] === 44, '"{," copies tape[127] to tape[0]'); }
  // 5. unmatched ']' with tape[head0] != 0 halts: '+' never runs
  { const t = P(']+'); const ops = run(t); ok(t[1] === 43 && t[0] === 93 && ops === 1, 'unmatched "]" halts'); }
  // 6. '[' with tape[head0]=='[' (nonzero) enters; no matching ']' is needed if not jumping -> runs on
  { const t = P('[>+'); run(t); ok(t[1] === 63, '"[" with a nonzero head byte does not jump ("[>+": tape[1] ">" -> "?")'); }
  // 7. '<' puts head0 on 127 (a zero); '[' then jumps forward, finds no ']' and halts: '+' never runs
  { const t = P('<[+'); const ops = run(t); ok(t[2] === 43 && t[127] === 0 && ops === 2, '"[" on a zero with no "]" halts'); }
  // 8. a loop: tape[127] = 3; '<[-]' runs '<', '[', then 3 x ('-', ']'); the jump back resumes after the '[' (8 ops)
  { const t = P('<[-]'); t[127] = 3; const ops = run(t); ok(t[127] === 0 && ops === 8, `"<[-]" clears a 3 in 3 rounds (ops ${ops})`); }
  // 9. nested brackets are matched: '<[[]]+' jumps from the outer '[' past the outer ']' and runs '+' on tape[127]
  { const t = P('<[[]]+'); const ops = run(t); ok(t[127] === 1 && ops === 3, 'forward jump over a nested "[[]]" lands after the outer "]"'); }
  // 10. step limit: an infinite loop '[]' on a nonzero byte stops after 8192 reads
  { const t = P('[]'); const ops = run(t); ok(ops === 8192, `"[]" on a nonzero head byte runs exactly 8192 steps (ops ${ops})`); }
  // 11. the paper's Fig. 4 replicator, "[[{.>]-]" ... "]-]>.{[[", with its middle filled by a non-zero non-instruction
  //     byte (0x20): '{' takes head1 to 127, the loop "{.>" copies forward-read bytes backwards until head0 meets a zero
  //     (the 0 at the start of the partner... none here) and the palindrome makes the reversed copy equal to itself.
  //     Hand-traced: g(R|X) = (R|R) for any X. (With the middle as zeros, the "-" turns every zero into 255 first.)
  { const R = new Uint8Array(T).fill(0x20); const L = '[[{.>]-]', E = ']-]>.{[['; for (let i = 0; i < 8; i++) { R[i] = L.charCodeAt(i); R[56 + i] = E.charCodeAt(i); }
    let all = true; for (let k = 0; k < 20; k++) { const t = new Uint8Array(T2); t.set(R, 0); for (let i = T; i < T2; i++) t[i] = (k * 37 + i * 101) & 255; run(t); for (let i = 0; i < T; i++) if (t[i] !== R[i] || t[T + i] !== R[i]) all = false; }
    ok(all, 'the Fig. 4 palindrome (middle 0x20) maps (R|X) to (R|R) for 20 partners X');
  }
  console.log(fails ? `${fails} FAILED` : 'all ok'); process.exit(fails ? 1 : 0);
}
// ---------------------------------------------------------------- validate against cubff's regression log
function validate() {
  const want = `1,8388776,131072,-0.000190
65,8286015,131072,0.097342
129,8216575,131072,0.162708
193,8161711,131072,0.213831
257,8114689,131072,0.256865`.split('\n');
  const n = 131072, sp = makeSoup(n, 10248, 1 / 4096); const got = [];
  const t0 = Date.now();
  for (let e = 0; e <= 256; e++) {
    sp.step();
    if (e % 64 === 0) { const s = stats(sp.soup, n); const line = `${e + 1},${s.brotli},${n},${s.higher.toFixed(6)}`; got.push(line); console.log(line, '| cubff:', want[got.length - 1], `| ${((Date.now() - t0) / 1000).toFixed(0)} s, ops/run ${(sp.ops / sp.runs).toFixed(1)}`); }
  }
  const res = { provenance: provenance(import.meta.url, { n, seed: 10248, mut: 1 / 4096 }), cubff: want, ours: got, equal: got.map((g, i) => g === want[i]) };
  fs.mkdirSync(dir + '/paper/data/bff', { recursive: true });
  fs.writeFileSync(dir + '/paper/data/bff/validate.json', JSON.stringify(res, null, 1));
}
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const opt = Object.fromEntries(process.argv.slice(3).map(a => { const i = a.indexOf('='); return [a.slice(0, i), a.slice(i + 1)]; }));
// ---------------------------------------------------------------- soup runs
function soupRun() {
  const seed = Number(opt.seed ?? 1), n = Number(opt.n ?? 131072), mut = Number(opt.mut ?? 1 / 4096), E = Number(opt.epochs ?? 16384);
  const after = Number(opt.after ?? 2048), every = Number(opt.every ?? 16), thr = Number(opt.thr ?? 1.0);
  const tag = opt.tag || `soup-n${n}-m${mut}-s${seed}`, out = opt.out || dir + '/paper/data/bff';
  const scratch = opt.scratch || null;
  fs.mkdirSync(out, { recursive: true });
  const sp = makeSoup(n, seed, mut), curve = []; let emerged = null, stop = E;
  const t0 = Date.now();
  const snapTop = s => [...s._map.entries()].sort((a, b) => b[1] - a[1]).slice(0, 64).map(([k, c]) => ({ hex: Buffer.from(k, 'latin1').toString('hex'), show: show(Buffer.from(k, 'latin1')), count: c }));
  const dump = (final) => {
    const s = stats(sp.soup, n);
    const res = { provenance: provenance(import.meta.url, { seed, n, mut, epochs: E, after, every, thr }), seed, n, mut, epochsRun: sp.epoch, emergedEpoch: emerged, threshold: `higher-order entropy > ${thr} bits/byte (first logged epoch)`, final, curve, top: snapTop(s) };
    fs.writeFileSync(`${out}/${tag}.json`, JSON.stringify(res));
    if (scratch) fs.writeFileSync(`${scratch}/${tag}.bin`, sp.soup);
  };
  for (let e = 0; e < stop; e++) {
    sp.step();
    if (e % every === 0 || e === stop - 1) {
      const s = stats(sp.soup, n); delete s._map; delete s._top;
      const row = { epoch: e + 1, ...s, opsPerRun: +(sp.ops / Math.max(1, sp.runs)).toFixed(1), sec: Math.round((Date.now() - t0) / 1000) };
      sp.ops = 0; sp.runs = 0; curve.push(row);
      if (emerged === null && s.higher > thr) { emerged = e + 1; stop = Math.min(E, e + 1 + after); }
      if (e % (every * 64) === 0 || emerged === e + 1) console.log(JSON.stringify(row));
      if (e % (every * 256) === 0) dump(false);
    }
  }
  dump(true);
  console.log(`${tag}: emerged ${emerged}, epochs ${sp.epoch}, ${Math.round((Date.now() - t0) / 1000)} s`);
}
// ---------------------------------------------------------------- the census
// g(A|B) = split(run(A|B)), no mutation.
const g = (A, B, tr) => { const t = new Uint8Array(T2); t.set(A, 0); t.set(B, T); run(t, STEPS, tr); return [t.slice(0, T), t.slice(T)]; };
const eq = (a, b) => { for (let i = 0; i < a.length; i++) if (a[i] !== b[i]) return false; return true; };
const ham = (a, b) => { let d = 0; for (let i = 0; i < a.length; i++) if (a[i] !== b[i]) d++; return d; };
function rng32(seed) { let x = seed >>> 0 || 1; return () => { x ^= x << 13; x >>>= 0; x ^= x >>> 17; x ^= x << 5; x >>>= 0; return x; }; }
const randTape = r => { const a = new Uint8Array(T); for (let i = 0; i < T; i++) a[i] = r() & 255; return a; };
const key = a => Buffer.from(a).toString('latin1');
function orbit(A, B, kmax = 64) {   // iterate the pair map on one pair; return {pre, period} of the first repeat
  const seen = new Map(); let a = A, b = B;
  for (let k = 0; k <= kmax; k++) { const kk = key(a) + key(b); if (seen.has(kk)) return { pre: seen.get(kk), period: k - seen.get(kk), a, b }; seen.set(kk, k); [a, b] = g(a, b); }
  return { pre: null, period: null, a, b };
}
// Offspring line: R in slot `slot` (0 or 1) with a fresh random partner; the offspring is the partner slot after the run;
// it then plays the parent with a fresh partner, for `gens` generations (as cubff's CheckSelfRep, 1 + 4 generations).
function lineage(R, slot, r, gens = 5) {
  let p = R;
  for (let k = 0; k < gens; k++) { const X = randTape(r); const [a, b] = slot === 0 ? g(p, X) : g(X, p); p = slot === 0 ? b : a; }
  return p;
}
function censusOne(R, r, nx, label) {
  const Rv = R.slice().reverse(), isRR = (a, b) => (eq(a, R) || eq(a, Rv)) && (eq(b, R) || eq(b, Rv));
  const res = { label, hex: hex(R), show: show(R), insnBytes: R.reduce((s, b) => s + (b && OP[b] < 10 ? 1 : 0), 0), zeroBytes: R.reduce((s, b) => s + (b === 0 ? 1 : 0), 0) };
  const [a0, b0] = g(R, R); const oRR = orbit(R, R); res.RR = { fixed: eq(a0, R) && eq(b0, R), pre: oRR.pre, period: oRR.period, cycleIsRorMirror: oRR.period !== null && isRR(oRR.a, oRR.b), hamOut: [ham(a0, R), ham(b0, R)] };
  { const ob = orbit(R, R.slice().reverse()); res.RRv = { pre: ob.pre, period: ob.period, cycleIsRorMirror: ob.period !== null && isRR(ob.a, ob.b) }; }
  // one interaction with a random partner, both orders
  const trace = new Uint8Array(T2);
  res.palindrome = eq(R, Rv); res.hamMirror = ham(R, Rv);
  const one = { RX: { parentKept: 0, childIsR: 0, childIsMirror: 0, childNear2: 0, both: 0 }, XR: { parentKept: 0, childIsR: 0, childIsMirror: 0, childNear2: 0, both: 0 } };
  const basin = { RX: { toRR: 0, toOtherFixed: 0, cycles: 0, none: 0, steps: [] }, XR: { toRR: 0, toOtherFixed: 0, cycles: 0, none: 0, steps: [] } };
  const lin = { RX: 0, XR: 0 };
  for (let k = 0; k < nx; k++) {
    const X = randTape(r);
    for (const ord of ['RX', 'XR']) {
      const [a, b] = ord === 'RX' ? g(R, X, trace) : g(X, R);
      const par = ord === 'RX' ? a : b, ch = ord === 'RX' ? b : a, o = one[ord];
      if (eq(par, R)) o.parentKept++; if (eq(ch, R)) o.childIsR++; else if (eq(ch, Rv)) o.childIsMirror++; if (Math.min(ham(ch, R), ham(ch, Rv)) <= 2) o.childNear2++; if (eq(par, R) && eq(ch, R)) o.both++;
      const ob = ord === 'RX' ? orbit(R, X) : orbit(X, R), B = basin[ord];
      if (ob.period === null) B.none++; else if (isRR(ob.a, ob.b) && ob.period <= 2) { B.toRR++; B.steps.push(ob.pre); } else if (ob.period <= 2) B.toOtherFixed++; else B.cycles++;
      { const o = lineage(R, ord === 'RX' ? 0 : 1, r), o2 = lineage(R, ord === 'RX' ? 0 : 1, r, 6); if ((eq(o, R) || eq(o, Rv)) && (eq(o2, R) || eq(o2, Rv))) lin[ord]++; }
    }
  }
  for (const ord of ['RX', 'XR']) { const B = basin[ord]; B.medianSteps = B.steps.sort((x, y) => x - y)[B.steps.length >> 1] ?? null; delete B.steps; }
  res.one = one; res.basin = basin; res.lineage5 = lin; res.nx = nx;
  res.executed = Array.from(trace.slice(0, T)).map((v, i) => v);
  return res;
}
// heredity: every position x a set of substitutions. A mutant M is placed in a slot with a fresh random partner, its
// offspring (the partner slot after the run) with a fresh partner, and so on for 8 generations (the offspring line).
// A line is settled if its last tapes repeat with period 1 or 2 (period 2: a reversing copier writes the mirror image).
// Classes, by the majority of nlin lines in the better of the two slots: reverts (settles on R, the mutation is lost),
// heritable (settles on M itself or its mirror image: the one-byte change is passed on exactly),
// variant (settles on another tape: a heritable change that also altered other bytes), dies (no settled line).
const GENS = 8;
function lineSeq(M, slot, r) {
  const seq = []; let p = M;
  for (let k = 0; k < GENS; k++) { const X = randTape(r); const [a, b] = slot === 0 ? g(p, X) : g(X, p); p = slot === 0 ? b : a; seq.push(p); }
  return seq;
}
function classifyLine(seq, R, M) {
  const L = seq.length, a = seq[L - 1], b = seq[L - 2], c = seq[L - 3];
  if (!(eq(a, b) || eq(a, c))) return 'dies';
  const Rv = R.slice().reverse();
  if (eq(a, R) || eq(b, R) || eq(a, Rv) || eq(b, Rv)) return 'reverts';
  if (!M) return 'variant';
  const Mv = M.slice().reverse();
  return eq(a, M) || eq(a, Mv) || eq(b, M) || eq(b, Mv) ? 'heritable' : 'variant';
}
function heredity(R, r, nlin, label) {
  const subs = [0, ...Object.keys(OPS).map(c => c.charCodeAt(0))]; for (let k = 0; k < 5; k++) { let v; do { v = r() & 255; } while (OP[v] < 11 || subs.includes(v)); subs.push(v); }
  const trace = new Uint8Array(T2); for (let k = 0; k < 64; k++) g(R, randTape(r), trace);
  const self = { 0: 0, 1: 0 }; for (const slot of [0, 1]) for (let k = 0; k < nlin; k++) if (classifyLine(lineSeq(R, slot, r), R) === 'reverts') self[slot]++;
  const rows = [];
  for (let pos = 0; pos < T; pos++) for (const v of subs) {
    if (v === R[pos]) continue;
    const M = R.slice(); M[pos] = v;
    let best = null;
    for (const slot of [0, 1]) {
      const c = { slot, heritable: 0, reverts: 0, variant: 0, dies: 0 };
      for (let k = 0; k < nlin; k++) c[classifyLine(lineSeq(M, slot, r), R, M)]++;
      if (!best || c.dies < best.dies) best = c;
    }
    let klass = 'dies'; for (const k of ['heritable', 'reverts', 'variant']) if (best[k] > nlin / 2) klass = k;
    const ob = orbit(M, M, 16);
    rows.push({ pos, from: R[pos], to: v, fromKind: R[pos] === 0 ? 'zero' : OP[R[pos]] < 10 ? 'insn' : 'data', toKind: v === 0 ? 'zero' : OP[v] < 10 ? 'insn' : 'data', executed: trace[pos] === 1, klass, MM: { pre: ob.pre, period: ob.period }, counts: best });
  }
  const sum = f => { const c = { n: 0, heritable: 0, reverts: 0, variant: 0, dies: 0, MMcycle: 0 }; for (const x of rows) if (f(x)) { c.n++; c[x.klass]++; if (x.MM.period !== null && x.MM.period <= 2 && x.MM.pre <= 2) c.MMcycle++; } return c; };
  // the soup's mutation draws a uniform byte: weight each tested substitution by the share of the 256 values its kind has
  // (11 instruction-or-zero values tested one by one; the 245 others represented by 5 random ones)
  const w = x => x.toKind === 'data' ? (245 / 256) / subs.filter(v => OP[v] === 11 && v !== R[x.pos]).length : (1 / 256);
  const weighted = {}; let wt = 0; for (const x of rows) { wt += w(x); weighted[x.klass] = (weighted[x.klass] || 0) + w(x); }
  for (const k of Object.keys(weighted)) weighted[k] /= wt;
  // neutral positions: every tested non-instruction substitution there breeds true; the tapes that differ from R only
  // at these positions, by non-instruction values, are then (by this sample) all replicators: about 245^k of them
  let neutral = 0, neutralCode = 0; const npos = []; for (let pos = 0; pos < T; pos++) { const rs = rows.filter(x => x.pos === pos && x.toKind === 'data'); if (rs.length && rs.every(x => x.klass === 'heritable')) { if (OP[R[pos]] === 11) { neutral++; npos.push(pos); } else neutralCode++; } }
  // direct test of the independence assumption: redraw ALL neutral positions at once (random non-instruction, non-zero
  // values) and check that the new tape breeds true in its better slot (majority of nlin lines)
  let multiOk = 0; const NM = 64;
  for (let k = 0; k < NM; k++) { const M = R.slice(); for (const pos of npos) { let v; do { v = r() & 255; } while (OP[v] !== 11); M[pos] = v; }
    let best = 0; for (const slot of [0, 1]) { let h = 0; for (let q = 0; q < nlin; q++) if (classifyLine(lineSeq(M, slot, r), R, M) === 'heritable') h++; best = Math.max(best, h); }
    if (best > nlin / 2) multiOk++; }
  return { label, hex: hex(R), show: show(R), nlin, gens: GENS, subs, selfLines: self, weighted, neutralPositions: neutral, neutralCodePositions: neutralCode, multiNeutral: { tested: NM, breedTrue: multiOk }, log2NeutralSet: +(neutral * Math.log2(245)).toFixed(0), summary: { all: sum(() => true), executed: sum(x => x.executed), notExecuted: sum(x => !x.executed), fromInsn: sum(x => x.fromKind === 'insn'), fromNonInsn: sum(x => x.fromKind !== 'insn'), executedInsn: sum(x => x.executed && x.fromKind === 'insn'), notExecNonInsn: sum(x => !x.executed && x.fromKind !== 'insn'), notExecInsn: sum(x => !x.executed && x.fromKind === 'insn'), toInsn: sum(x => x.toKind === 'insn'), toNonInsn: sum(x => x.toKind !== 'insn'), nonInsnToData: sum(x => x.fromKind !== 'insn' && x.toKind === 'data'), nonInsnToZero: sum(x => x.fromKind !== 'insn' && x.toKind === 'zero'), nonInsnToInsn: sum(x => x.fromKind !== 'insn' && x.toKind === 'insn'), insnToData: sum(x => x.fromKind === 'insn' && x.toKind === 'data') }, executedPositions: Array.from(trace.slice(0, T)), rows };
}
function census() {
  const files = (opt.in || '').split(',').filter(Boolean), top = Number(opt.top ?? 3), nx = Number(opt.nx ?? 256), nlin = Number(opt.nlin ?? 16);
  const r = rng32(Number(opt.rseed ?? 7));
  const reps = [];
  for (const f of files) {
    const d = JSON.parse(fs.readFileSync(f, 'utf8'));
    d.top.slice(0, top).forEach((t, i) => reps.push({ src: f.replace(dir + '/', ''), seed: d.seed, rank: i + 1, count: t.count, share: t.count / d.n, R: fromHex(t.hex) }));
  }
  if (opt.hex) for (const h of opt.hex.split(',')) reps.push({ src: 'given', rank: 0, R: fromHex(h) });
  const out = [];
  const bins = opt.bins || null;
  for (const rep of reps) {
    if (bins && rep.src !== 'given') { const bf = `${bins}/${rep.src.split('/').pop().replace(/\.json$/, '.bin')}`;
      if (fs.existsSync(bf)) { const soup = fs.readFileSync(bf), n = soup.length / T, Rv = rep.R.slice().reverse(), hist = new Array(T + 1).fill(0);
        for (let i = 0; i < n; i++) { let d1 = 0, d2 = 0; for (let j = 0; j < T; j++) { const b = soup[i * T + j]; if (b !== rep.R[j]) d1++; if (b !== Rv[j]) d2++; } hist[Math.min(d1, d2)]++; }
        const cum = d => hist.slice(0, d + 1).reduce((a, b) => a + b, 0) / n; rep.family = { n, within0: cum(0), within2: cum(2), within4: cum(4), within8: cum(8), within16: cum(16), within32: cum(32), hist }; } }
    const lab = `${rep.src}#${rep.rank}`;
    const c = censusOne(rep.R, r, nx, lab), h = opt.noher ? null : heredity(rep.R, r, nlin, lab);
    out.push({ ...rep, R: undefined, census: c, heredity: h });
    console.log(lab, show(rep.R), JSON.stringify({ RR: c.RR, one: c.one, basin: c.basin, lin: c.lineage5, her: h && h.summary.all }));
  }
  // the share of self-copiers in each final soup: a sampled tape T is one if g(T|X) leaves T and writes T or its mirror
  // into the partner for 3 of 3 random partners X (T first), or likewise with T second
  const soupStats = [];
  if (bins) for (const f of files) { const bf = `${bins}/${f.split('/').pop().replace(/\.json$/, '.bin')}`; if (!fs.existsSync(bf)) continue;
    const soup = fs.readFileSync(bf), n = soup.length / T, S = Math.min(n, 4096); let first = 0, second = 0, either = 0;
    for (let k = 0; k < S; k++) { const i = Math.floor((r() / 4294967296) * n), Tp = new Uint8Array(soup.subarray(i * T, i * T + T)), Tv = Tp.slice().reverse(); let a1 = true, a2 = true;
      for (let q = 0; q < 3; q++) { const X = randTape(r); let [a, b] = g(Tp, X); if (!eq(a, Tp) || !(eq(b, Tp) || eq(b, Tv))) a1 = false; [a, b] = g(X, Tp); if (!eq(b, Tp) || !(eq(a, Tp) || eq(a, Tv))) a2 = false; }
      if (a1) first++; if (a2) second++; if (a1 || a2) either++; }
    soupStats.push({ src: f.replace(dir + '/', ''), sampled: S, selfCopierFirst: first / S, selfCopierSecond: second / S, selfCopierEither: either / S }); }
  const res = { provenance: provenance(import.meta.url, { files, top, nx, nlin }), soupStats, reps: out };
  fs.writeFileSync(opt.out || dir + '/paper/data/bff/census.json', JSON.stringify(res));
}
// ---------------------------------------------------------------- report: Markdown tables from the JSON files
function report() {
  const pct = (a, b) => b ? (100 * a / b).toFixed(1) : '–';
  const L = [];
  const soups = (opt.soups || '').split(',').filter(Boolean).map(f => JSON.parse(fs.readFileSync(f, 'utf8')));
  L.push('### Soup runs', '', '| seed | tapes | mutation / byte | emerged (epoch) | epochs run | top tape share | distinct tapes | H₂ (bits) | higher-order entropy | ops / run |', '|---|---|---|---|---|---|---|---|---|---|');
  for (const d of soups) { const e = d.curve[d.curve.length - 1]; L.push(`| ${d.seed} | ${d.n} | ${(d.mut * 100).toFixed(4)} % | ${d.emergedEpoch ?? 'none'} | ${d.epochsRun} | ${(100 * e.topShare).toFixed(3)} % | ${e.distinct} | ${e.H2 ?? '>' + (2 * Math.log2(d.n) - 1).toFixed(0)} | ${e.higher.toFixed(3)} | ${e.opsPerRun} |`); }
  for (const d of soups) {
    if (!d.emergedEpoch) continue;
    L.push('', `### Entropy around the transition, seed ${d.seed} (${d.n} tapes, emergence at epoch ${d.emergedEpoch})`, '', '| epoch | rel. | brotli bits/byte | byte entropy H₀ | higher-order | tape H₂ (bits) | distinct tapes | top share | zero bytes | ops / run |', '|---|---|---|---|---|---|---|---|---|---|');
    const want = [1, -4096, -1024, -256, -64, -16, 0, 16, 64, 256, 1024, 1e9]; const used = new Set();
    for (const w of want) {
      const target = w === 1 ? 1 : w === 1e9 ? d.curve[d.curve.length - 1].epoch : d.emergedEpoch + w;
      let best = null; for (const r of d.curve) if (!best || Math.abs(r.epoch - target) < Math.abs(best.epoch - target)) best = r;
      if (used.has(best.epoch) || Math.abs(best.epoch - target) > 64) continue; used.add(best.epoch);
      L.push(`| ${best.epoch} | ${best.epoch - d.emergedEpoch >= 0 ? '+' : ''}${best.epoch - d.emergedEpoch} | ${best.bpb.toFixed(3)} | ${best.h0.toFixed(3)} | ${best.higher.toFixed(3)} | ${best.H2 ?? '>' + (2 * Math.log2(d.n) - 1).toFixed(0)} | ${best.distinct} | ${(100 * best.topShare).toFixed(2)} % | ${(100 * best.zeroFrac).toFixed(1)} % | ${best.opsPerRun} |`);
    }
  }
  if (opt.census) {
    const c = JSON.parse(fs.readFileSync(opt.census, 'utf8'));
    L.push('', '### Self-copiers in the final soups (4096 sampled tapes; T is one if g(T|X) keeps T and writes T or its mirror into X, for 3 of 3 random X)', '', '| soup | T first | T second | either |', '|---|---|---|---|');
    for (const x of c.soupStats || []) L.push(`| ${x.src.split('/').pop()} | ${pct(x.selfCopierFirst * x.sampled, x.sampled)} % | ${pct(x.selfCopierSecond * x.sampled, x.sampled)} % | ${pct(x.selfCopierEither * x.sampled, x.sampled)} % |`);
    L.push('', '### Families: the share of soup tapes within Hamming distance d of R or its mirror', '', '| id | d = 0 | ≤ 2 | ≤ 8 | ≤ 16 | ≤ 32 |', '|---|---|---|---|---|---|');
    c.reps.forEach((r, i) => { if (r.family) L.push(`| R${i + 1} | ${(100 * r.family.within0).toFixed(2)} % | ${(100 * r.family.within2).toFixed(2)} % | ${(100 * r.family.within8).toFixed(2)} % | ${(100 * r.family.within16).toFixed(2)} % | ${(100 * r.family.within32).toFixed(2)} % |`); });
    L.push('', '### Dominant tapes', '', '| id | source | share | tape (instructions as themselves, 0 as 0, other bytes ·) | instr. bytes | positions where an instruction ran | distance to its mirror |', '|---|---|---|---|---|---|---|');
    c.reps.forEach((r, i) => L.push(`| R${i + 1} | seed ${r.seed ?? '–'} #${r.rank} | ${r.share ? (100 * r.share).toFixed(3) + ' % (' + r.count + ' tapes)' : "the paper's Fig. 4 (middle 0x20)"} | \`${r.census.show}\` | ${r.census.insnBytes} | ${r.census.executed.reduce((a, b) => a + b, 0)} | ${r.census.hamMirror} |`));
    L.push('', '### The pair map g(A|B) = split(run(A|B)) at each replicator R', '', `| id | (R\\|R) | (R\\|mirror R) | g(R\\|X): R kept | g(R\\|X): copy = R / mirror of R | g(X\\|R): R kept | g(X\\|R): copy = R / mirror | iterate g on (R\\|X): reaches a fixed point or 2-cycle of R and its mirror | on (X\\|R) | offspring line after 5 and 6 generations is R or its mirror (R first / second) |`, '|---|---|---|---|---|---|---|---|---|---|');
    c.reps.forEach((r, i) => { const x = r.census, n = x.nx; const rv = x.RRv.pre === 0 && x.RRv.period === 1 ? 'fixed point' : `pre-period ${x.RRv.pre}, period ${x.RRv.period}`; const rr = x.RR.fixed ? 'fixed point' : x.RR.period ? `(R\\|R) → (${x.RR.hamOut[0] ? 'R′' : 'R'}\\|${x.RR.hamOut[1] ? (x.palindrome ? 'R′' : 'mirror R') : 'R'}): pre-period ${x.RR.pre}, then period ${x.RR.period}` : 'no cycle ≤ 64';
      L.push(`| R${i + 1} | ${rr} | ${rv} | ${pct(x.one.RX.parentKept, n)} % | ${pct(x.one.RX.childIsR, n)} % / ${pct(x.one.RX.childIsMirror, n)} % | ${pct(x.one.XR.parentKept, n)} % | ${pct(x.one.XR.childIsR, n)} % / ${pct(x.one.XR.childIsMirror, n)} % | ${pct(x.basin.RX.toRR, n)} % (median ${x.basin.RX.medianSteps ?? '–'} steps) | ${pct(x.basin.XR.toRR, n)} % | ${pct(x.lineage5.RX, n)} % / ${pct(x.lineage5.XR, n)} % |`); });
    L.push('', '### Heredity, compact (percent of mutants; soup-weighted = a uniform random byte, as the soup\'s mutation draws)', '', '| id | soup-weighted: heritable / variant / reverts / dies | tape byte → other non-instr. value: heritable | tape byte → 0: heritable / variant / dies | tape byte → instr.: heritable / dies | code byte (any change): heritable / dies | neutral tape positions | all neutral bytes redrawn at once: breed true |', '|---|---|---|---|---|---|---|---|');
    c.reps.forEach((r, i) => { const h = r.heredity; if (!h) return; const W = h.weighted, S = h.summary, f = x => (100 * (x || 0)).toFixed(1), q = (a, n) => pct(a, n);
      L.push(`| R${i + 1} | ${f(W.heritable)} / ${f(W.variant)} / ${f(W.reverts)} / ${f(W.dies)} | ${q(S.nonInsnToData.heritable, S.nonInsnToData.n)} (n ${S.nonInsnToData.n}) | ${q(S.nonInsnToZero.heritable, S.nonInsnToZero.n)} / ${q(S.nonInsnToZero.variant, S.nonInsnToZero.n)} / ${q(S.nonInsnToZero.dies, S.nonInsnToZero.n)} | ${q(S.nonInsnToInsn.heritable, S.nonInsnToInsn.n)} / ${q(S.nonInsnToInsn.dies, S.nonInsnToInsn.n)} | ${q(S.fromInsn.heritable, S.fromInsn.n)} / ${q(S.fromInsn.dies, S.fromInsn.n)} (n ${S.fromInsn.n}) | ${h.neutralPositions} of ${64 - r.census.insnBytes - r.census.zeroBytes} | ${h.multiNeutral.breedTrue} / ${h.multiNeutral.tested} |`); });
    L.push('', '### Heredity: single-byte mutants', '', '| id | mutants | n | heritable (M or its mirror breeds true) | variant (another settled line) | reverts to R | dies (no settled line) |', '|---|---|---|---|---|---|---|');
    const names = { all: 'all tested (11 instr./0 + 5 other values per position)', fromInsn: 'code: the byte is an instruction', insnToData: 'code byte → a non-instruction value', fromNonInsn: 'tape: the byte is not an instruction', nonInsnToData: 'tape byte → another non-instruction value', nonInsnToZero: 'tape byte → 0', nonInsnToInsn: 'tape byte → an instruction', executed: '(positions where an instruction ran)', notExecuted: '(positions where none ran)' };
    c.reps.forEach((r, i) => { if (!r.heredity) return; const W = r.heredity.weighted; L.push(`| R${i + 1} | neutral tape positions (non-instruction bytes where all tested non-instruction values breed true): ${r.heredity.neutralPositions} of ${64 - r.census.insnBytes - r.census.zeroBytes}; also ${r.heredity.neutralCodePositions} code positions tolerate any tested non-instruction value; 245^${r.heredity.neutralPositions} ≈ 2^${r.heredity.log2NeutralSet} tapes; of ${r.heredity.multiNeutral.tested} tapes with all of them redrawn at once, ${r.heredity.multiNeutral.breedTrue} breed true | | | | | |`); L.push(`| R${i + 1} | **uniform random byte (soup-weighted)** | – | ${(100 * (W.heritable || 0)).toFixed(1)} % | ${(100 * (W.variant || 0)).toFixed(1)} % | ${(100 * (W.reverts || 0)).toFixed(1)} % | ${(100 * (W.dies || 0)).toFixed(1)} % |`); for (const [k, nm] of Object.entries(names)) { const s = r.heredity.summary[k]; if (!s.n) continue; L.push(`| R${i + 1} | ${nm} | ${s.n} | ${pct(s.heritable, s.n)} % | ${pct(s.variant, s.n)} % | ${pct(s.reverts, s.n)} % | ${pct(s.dies, s.n)} % |`); } });
  }
  console.log(L.join('\n'));
}
const cmd = process.argv[2];
if (cmd === 'report') report();
else if (cmd === 'selftest') selftest();
else if (cmd === 'validate') validate();
else if (cmd === 'soup') soupRun();
else if (cmd === 'census') census();
else if (cmd === 'bench') { const n = Number(opt.n ?? 16384), sp = makeSoup(n, 1, 1 / 4096); const t0 = Date.now(); for (let e = 0; e < Number(opt.e ?? 20); e++) sp.step(); console.log(`${(Date.now() - t0) / Number(opt.e ?? 20)} ms/epoch, ops/run ${(sp.ops / sp.runs).toFixed(1)}`); }
else if (cmd !== undefined) console.log('unknown command');
export { provLine };
