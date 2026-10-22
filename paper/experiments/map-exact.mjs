// Exact enumeration of the periodic points of period 1 and 2 of the single-cell decoder map f (kind 36) for one
// dictionary: every x with f(x) = x, and every x with f(f(x)) = x and f(x) != x.
//
// Method (a constraint search over the bitstream, complete by construction). For period K we look for cells c_0..c_{K-1}
// with f(c_i) = c_{i+1 mod K}. Decoder i reads the bits of c_i in the decoder's order (skip bits, the header, then the
// commands, wrapping round the cell at bit 128) and writes the 16 bytes of c_{i+1}. Every bit of every c_i starts
// unknown. The search runs the K decoders as resumable bit-level state machines. Decoders 1..K-1 only ever read bits
// that some decoder has written, and run as far as their input is known; decoder 0 reads bits of c_0 and, when a bit is
// unknown, the search branches on its value (0 and 1). Every byte a decoder writes is checked against the bits already
// known in the target cell and fixes them; a contradiction prunes the branch. Literal bits are written to the target
// as they are read. Re-reading a bit after the wrap reads the known value. A leaf is reached when all K decoders have
// produced 16 bytes: then every bit of c_0 is known (c_0 is written in full by decoder K-1), and since writes were
// checked, f(c_i) = c_{i+1} holds for all i. Two leaves differ in a branched bit of c_0, so leaves and solutions are in
// one-to-one correspondence: the count is exact. The 1,024-bit read cap of the decoder is never reached (each pass of the
// command loop writes at least 2 bytes and reads at most 4 + 7·8 + 5 + 1 + 6 + 2 bits, so 16 bytes cost < 1,024 bits);
// the engine asserts it. The 12 header bits are split into 4,096 independent subtrees, run on worker threads.
// Every solution is re-verified with the JavaScript reference (decode36) and with the WebAssembly module.
//
// Usage: node paper/experiments/map-exact.mjs [dict=ca-swarm-f] [K=1] [workers=16] [variant=raw] [seed=1] [headers=all|a-b|list]
//   options as key=value: V=4096 skip=6 coff=0 out=<json path> nodecap=<per-header node cap, 0 = none>
//   --sample=N  the sampling cross-check: iterate f from N random cells (seed 12345) for 300 steps, collect every fixed
//               point and 2-cycle reached, and check each is in the exact list (K=1 and K=2 runs must both exist in out dir)
import fs from 'node:fs';
import os from 'node:os';
import { Worker, isMainThread, parentPort, workerData } from 'node:worker_threads';
import { decode36, rangeBits } from './decode36.mjs';
import { loadDict, variantOf } from './dict-variants.mjs';
import { wasmDecoder, hex, fastF } from './map-lib.mjs';
import { provenance, provLine } from './provenance.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');

// ---------------------------------------------------------------- the engine
const HDR = 0, INS0 = 1, INSX = 2, LIT = 3, CLEN0 = 4, CLENX = 5, DFLAG = 6, SC = 7, DIST = 8, TF = 9, DONE = 10;
const DS = 20;   // decoder state words: phase cbp cused opos acc nb need dwin r0 r1 r2 r3 n len base litbit d push
const PH = 0, CBP = 1, CUSED = 2, OPOS = 3, ACC = 4, NB = 5, NEED = 6, DWIN = 7, R0 = 8, R1 = 9, R2 = 10, R3 = 11, NN = 12, LEN = 13, BASE = 14, LITB = 15, DD = 16, PUSH = 17;
export function makeEngine(dict, { K = 1, skip = 6, V = 4096, coff = 0, sym = K > 1, tie = 0 } = {}) {   // tie (K = 2): a 16-bit mask of byte positions where c_0 and c_1 are required to agree
  const tl = dict.length, HB = rangeBits(V), SZ = 8 * K + DS * K, MAXD = 300;
  const pool = new Int32Array(SZ * MAXD);
  let prof = null, nodes = 0, nodeCap = 0, capped = false, onLeaf = null, probe = false, est = 0, rs = 1;
  const rnd = () => { rs ^= rs << 13; rs >>>= 0; rs ^= rs >>> 17; rs ^= rs << 5; rs >>>= 0; return rs & 1; }; const leafX = new Uint8Array(16);
  const dB = i => 8 * K + DS * i;
  // cell j: value words at 8j..8j+3, mask words at 8j+4..8j+7
  const known = (S, o, j, b) => (S[o + 8 * j + 4 + (b >> 5)] >>> (b & 31)) & 1;
  const val = (S, o, j, b) => (S[o + 8 * j + (b >> 5)] >>> (b & 31)) & 1;
  function setBit1(S, o, j, b, v) {   // 0 on contradiction
    const w = o + 8 * j + (b >> 5), m = 1 << (b & 31);
    if (S[w + 4] & m) return ((S[w] & m) !== 0) === (v === 1) ? 1 : 0;
    S[w + 4] |= m; if (v) S[w] |= m; return 1;
  }
  function setByte1(S, o, j, p, v) {
    const w = o + 8 * j + (p >> 2), sh = (p & 3) << 3, m = 255 << sh, vv = v << sh, km = S[w + 4] & m;
    if ((S[w] & km) !== (vv & km)) return 0;
    S[w] = (S[w] & ~m) | vv; S[w + 4] |= m; return 1;
  }
  const setBit = tie ? (S, o, j, b, v) => setBit1(S, o, j, b, v) && (!((tie >> (b >> 3)) & 1) || setBit1(S, o, 1 - j, b, v)) : setBit1;
  const setByte = tie ? (S, o, j, p, v) => setByte1(S, o, j, p, v) && (!((tie >> p) & 1) || setByte1(S, o, 1 - j, p, v)) : setByte1;
  const getByte = (S, o, j, p) => (S[o + 8 * j + (p >> 2)] >>> ((p & 3) << 3)) & 255;
  function startCmd(S, b) { S[b + PH] = INS0; S[b + NEED] = 2; }
  function afterDist(S, o, b, i) {
    let d = S[b + DD]; if (d < 1) d = 1; S[b + DD] = d;
    if (d > S[b + OPOS]) { S[b + PH] = TF; S[b + NEED] = 2; return 1; }
    return doCopy(S, o, b, i, 0);
  }
  function doCopy(S, o, b, i, tf) {
    const d = S[b + DD], t = (i + 1) % K;
    if (S[b + PUSH]) { S[b + R3] = S[b + R2]; S[b + R2] = S[b + R1]; S[b + R1] = S[b + R0]; S[b + R0] = d; }
    let len = S[b + LEN], opos = S[b + OPOS], first = true; const dwin = S[b + DWIN];
    while (len && opos < 16) {
      let v;
      if (d <= opos) v = getByte(S, o, t, opos - d);
      else { let k = (d - opos) % tl; k = dwin - k + tl; if (k >= tl) k -= tl; v = dict[k]; }
      if (tf === 2 || (tf === 1 && first)) { if (v >= 97 && v < 123) v -= 32; }
      else if (tf === 3) { if (v >= 65 && v < 91) v += 32; }
      if (!setByte(S, o, t, opos, v)) return 0;
      opos++; len--; first = false;
    }
    S[b + OPOS] = opos;
    if (opos >= 16) S[b + PH] = DONE; else startCmd(S, b);
    return 1;
  }
  // feed one bit to decoder i (the bit at its cursor, already known); 0 on contradiction
  function feed(S, o, i, bit) {
    const b = o + dB(i);
    S[b + CBP]++; if (++S[b + CUSED] >= 1024) throw new Error('read cap reached');
    if (S[b + PH] === LIT) {
      const t = (i + 1) % K, opos = S[b + OPOS], lb = S[b + LITB];
      if (!setBit(S, o, t, 8 * opos + lb, bit)) return 0;
      if (lb < 7) { S[b + LITB] = lb + 1; return 1; }
      S[b + LITB] = 0; S[b + OPOS] = opos + 1; S[b + NN]--;
      if (opos + 1 >= 16) { S[b + PH] = DONE; return 1; }
      if (S[b + NN] === 0) { S[b + PH] = CLEN0; S[b + NEED] = 2; }
      return 1;
    }
    const nb = S[b + NB]; S[b + ACC] |= bit << nb; S[b + NB] = nb + 1;
    if (nb + 1 < S[b + NEED]) return 1;
    const v = S[b + ACC]; S[b + ACC] = 0; S[b + NB] = 0;
    switch (S[b + PH]) {
      case HDR: { let h = v; if (V && h >= V) h -= V; S[b + DWIN] = (h + coff) % tl; startCmd(S, b); return 1; }
      case INS0:
        if (v < 2) { S[b + NN] = v; break; }
        S[b + PH] = INSX; S[b + NEED] = v === 2 ? 1 : 2; S[b + BASE] = v === 2 ? 2 : 4; return 1;
      case INSX: S[b + NN] = S[b + BASE] + v; break;
      case CLEN0:
        if (v < 2) { S[b + LEN] = v + 2; S[b + PH] = DFLAG; S[b + NEED] = 1; return 1; }
        S[b + PH] = CLENX; S[b + NEED] = v === 2 ? 1 : 3; S[b + BASE] = v === 2 ? 4 : 6; return 1;
      case CLENX: S[b + LEN] = S[b + BASE] + v; S[b + PH] = DFLAG; S[b + NEED] = 1; return 1;
      case DFLAG: if (v === 0) { S[b + PH] = SC; S[b + NEED] = 4; } else { S[b + PH] = DIST; S[b + NEED] = 6; } return 1;
      case SC: {
        const sc = v; let d, push = 1;
        if (sc < 4) { d = S[b + R0 + sc]; if (sc === 0) push = 0; }
        else { let k = ((sc - 4) >> 1) + 1; if (sc >= 10) k -= 3; d = sc < 10 ? S[b + R0] : S[b + R1]; d = (sc & 1) === 0 ? d - k : d + k; }
        S[b + DD] = d; S[b + PUSH] = push; return afterDist(S, o, b, i);
      }
      case DIST: S[b + DD] = 1 + v; S[b + PUSH] = 1; return afterDist(S, o, b, i);
      case TF: return doCopy(S, o, b, i, v);
    }
    // after the insert length (INS0 with v < 2, INSX)
    if (S[b + NN] > 0) { S[b + PH] = LIT; S[b + LITB] = 0; } else { S[b + PH] = CLEN0; S[b + NEED] = 2; }
    return 1;
  }
  function init(o, skipBits) {
    pool.fill(0, o, o + SZ);
    for (let i = 0; i < K; i++) {
      const b = o + dB(i);
      pool[b + CBP] = skipBits; pool[b + R0] = 4; pool[b + R1] = 11; pool[b + R2] = 15; pool[b + R3] = 16;
      if (HB) { pool[b + PH] = HDR; pool[b + NEED] = HB; }
      else { pool[b + DWIN] = coff % tl; startCmd(pool, b); }
    }
  }
  function search(depth) {
    const S = pool, o = depth * SZ;
    nodes++;
    if (nodeCap && nodes > nodeCap) { capped = true; return; }
    for (;;) {
      // decoders 1..K-1: run while their next bit is known
      let allDone = true;
      for (let i = 1; i < K; i++) {
        const b = o + dB(i);
        while (S[b + PH] !== DONE) {
          const p = S[b + CBP] & 127;
          if (!known(S, o, i, p)) break;
          if (!feed(S, o, i, val(S, o, i, p))) return;
        }
        if (S[b + PH] !== DONE) allDone = false;
      }
      const b0 = o + dB(0);
      if (S[b0 + PH] === DONE) {
        if (allDone) {   // a solution: c_0 is fully known
          for (let w = 0; w < 4; w++) if (S[o + 4 + w] !== -1) throw new Error('leaf with unknown bits');
          for (let p = 0; p < 16; p++) leafX[p] = getByte(S, o, 0, p);
          onLeaf(leafX); return;
        }
        // decoder 0 done; c_1 is then fully known, so the others cannot stay blocked unless waiting on a later cell
        let blocked = true;
        for (let i = 1; i < K; i++) { const b = o + dB(i); if (S[b + PH] !== DONE && known(S, o, i, S[b + CBP] & 127)) blocked = false; }
        if (blocked) throw new Error('deadlock');
        continue;
      }
      const p = S[b0 + CBP] & 127;
      if (known(S, o, 0, p)) { if (!feed(S, o, 0, val(S, o, 0, p))) return; continue; }
      // branch on the unknown bit p of c_0
      if (depth + 1 >= MAXD) throw new Error('depth');
      const o2 = o + SZ;
      for (let v = 0; v < 2; v++) {
        if (probe) { est += 2 ** (depth + 1); v = rnd(); S.copyWithin(o2, o, o + SZ); setBit(S, o2, 0, p, v); search(depth + 1); break; }
        S.copyWithin(o2, o, o + SZ);
        setBit(S, o2, 0, p, v);
        search(depth + 1);
      }
      return;
    }
  }
  // the symmetric search (K >= 2): every decoder runs while its next bit is known; then the search branches on the
  // unknown next bit of the decoder that has read the fewest bits (the bits of every c_i are free variables, each
  // checked when another decoder writes it), so each decoder's writes run ahead of the other's reads and prune early.
  // Complete for the same reason as the plain search: every branch covers both values of one bit.
  function searchSym(depth) {
    const S = pool, o = depth * SZ;
    nodes++;
    if (nodeCap && nodes > nodeCap) { capped = true; return; }
    for (;;) {
      let progressed = false;
      for (let i = 0; i < K; i++) {
        const b = o + dB(i);
        while (S[b + PH] !== DONE) {
          const p = S[b + CBP] & 127;
          if (!known(S, o, i, p)) break;
          if (!feed(S, o, i, val(S, o, i, p))) return;
          progressed = true;
        }
      }
      if (progressed) continue;
      let bi = -1, bu = 1 << 30;
      for (let i = 0; i < K; i++) { const b = o + dB(i); if (S[b + PH] !== DONE && S[b + CUSED] < bu) { bu = S[b + CUSED]; bi = i; } }
      if (bi < 0) {
        for (let j = 0; j < K; j++) for (let w = 0; w < 4; w++) if (S[o + 8 * j + 4 + w] !== -1) throw new Error('leaf with unknown bits');
        for (let p = 0; p < 16; p++) leafX[p] = getByte(S, o, 0, p);
        onLeaf(leafX); return;
      }
      const p = S[o + dB(bi) + CBP] & 127;
      if (prof) prof[S[o + dB(0) + OPOS] * 17 + S[o + dB(1) + OPOS]]++;
      if (depth + 1 >= MAXD) throw new Error('depth');
      const o2 = o + SZ;
      for (let v = 0; v < 2; v++) {
        if (probe) { est += 2 ** (depth + 1); v = rnd(); S.copyWithin(o2, o, o + SZ); setBit(S, o2, bi, p, v); searchSym(depth + 1); break; }
        S.copyWithin(o2, o, o + SZ);
        setBit(S, o2, bi, p, v);
        searchSym(depth + 1);
      }
      return;
    }
  }
  // run the subtree with header value h (decoder 0's header bits preset); returns the solutions and the node count
  function runHeader(h, cap, leaf, h1 = -1, presetFn = null) {   // h1 >= 0 also presets the header bits of c_1 (K >= 2)
    nodes = 0; nodeCap = cap; capped = false; onLeaf = leaf;
    init(0, skip);
    for (let k = 0; k < HB; k++) setBit(pool, 0, 0, (skip + k) & 127, (h >> k) & 1);
    if (h1 >= 0) for (let k = 0; k < HB; k++) setBit(pool, 0, 1, (skip + k) & 127, (h1 >> k) & 1);
    if (presetFn) presetFn((j, b, v) => setBit(pool, 0, j, b, v));
    if (sym) searchSym(0); else search(0);
    return { nodes, capped };
  }
  // Knuth's estimator of the subtree size under header h: the mean over n random root-to-leaf probes of sum 2^depth
  function estimate(h, n, seed = 1) {
    probe = true; rs = seed >>> 0 || 1; let tot = 0; const vals = [];
    for (let k = 0; k < n; k++) { est = 1; nodes = 0; nodeCap = 0; onLeaf = () => {}; init(0, skip); for (let q = 0; q < HB; q++) setBit(pool, 0, 0, (skip + q) & 127, (h >> q) & 1); if (sym) searchSym(0); else search(0); tot += est; vals.push(est); }
    probe = false; return { mean: tot / n, vals };
  }
  return { runHeader, estimate, HB, setProfile: a => { prof = a; } };
}

// ---------------------------------------------------------------- worker
if (!isMainThread) {
  const { dictBytes, opts, cap, maxStore } = workerData;
  const dict = Uint8Array.from(dictBytes), eng = makeEngine(dict, opts), trace = new Int16Array(16);
  const f = fastF(dict, opts), ft = fastF(dict, opts, trace), y = new Uint8Array(16), z = new Uint8Array(16);
  parentPort.on('message', h => {
    if (h === null) { process.exit(0); }
    const t0 = Date.now(); let count = 0, minimal = 0, bad = 0; const stored = [], fam = new Map(), freeHist = new Array(17).fill(0);
    const r = eng.runHeader(h, cap, x => {
      count++;
      // verify with the fast reference: f^K(x) = x; minimal when f(x) != x
      y.set(x); for (let i = 0; i < opts.K; i++) { f(y, 0, z, 0); y.set(z); }
      let ok = true; for (let k = 0; k < 16; k++) if (y[k] !== x[k]) ok = false;
      if (!ok) bad++;
      f(x, 0, z, 0); let isMin = opts.K === 1; if (!isMin) for (let k = 0; k < 16; k++) if (z[k] !== x[k]) isMin = true;
      if (!isMin) return;
      minimal++;
      if (stored.length < maxStore) stored.push(hex(x));
      if (opts.K === 1) {   // family: the solution with its self-read literal bytes (read from the bits they write) blanked
        ft(x, 0, z, 0); const key = Uint8Array.from(x); let free = 0, mask = 0;
        for (let k = 0; k < 16; k++) if (trace[k] === 8 * k) { key[k] = 0; free++; mask |= 1 << k; }
        freeHist[free]++;
        const kk = hex(key) + ':' + mask.toString(16).padStart(4, '0');
        fam.set(kk, (fam.get(kk) || 0) + 1);
      }
    });
    parentPort.postMessage({ h, nodes: r.nodes, capped: r.capped, count, minimal, bad, ms: Date.now() - t0, solutions: stored, families: [...fam.entries()].slice(0, 20000), nfamilies: fam.size, freeHist });
  });
}

// ---------------------------------------------------------------- main
async function main() {
  const argv = process.argv.slice(2), pos = argv.filter(a => !a.includes('=') && !a.startsWith('--')), kv = Object.fromEntries(argv.filter(a => a.includes('=') && !a.startsWith('--')).map(a => a.split('=')));
  const flags = Object.fromEntries(argv.filter(a => a.startsWith('--')).map(a => { const [k, v] = a.slice(2).split('='); return [k, v ?? true]; }));
  const [ID = 'ca-swarm-f', K = '1', W = '16', VARIANT = 'raw', SEED = '1', HDRS = 'all'] = pos;
  const opts = { K: Number(K), skip: Number(kv.skip ?? 6), V: Number(kv.V ?? 4096), coff: Number(kv.coff ?? 0), sym: kv.sym ? kv.sym === '1' : Number(K) > 1, tie: Number(kv.tie ?? 0) };
  const dict = variantOf(loadDict(ID).bytes, VARIANT, Number(SEED));
  const name = VARIANT === 'raw' ? ID : `${ID}-${VARIANT}${SEED}`;
  const outDir = dir + '/paper/data/map'; fs.mkdirSync(outDir, { recursive: true });
  if (flags.sample) return sampleCheck(dict, name, opts, Number(flags.sample), outDir);
  if (flags.verifyall) return verifyAll(dict, name, opts, outDir);
  const HBn = rangeBits(opts.V), all = 1 << HBn;
  let headers = [];
  if (HDRS === 'all') headers = Array.from({ length: all }, (_, i) => i);
  else if (HDRS.includes('-')) { const [a, b] = HDRS.split('-').map(Number); for (let h = a; h <= b; h++) headers.push(h); }
  else if (HDRS.startsWith('rand')) { const n = Number(HDRS.slice(4)); let s = 7; const seen = new Set(); while (seen.size < n) { s = (s * 1103515245 + 12345) >>> 0; seen.add((s >>> 8) % all); } headers = [...seen].sort((a, b) => a - b); }
  else headers = HDRS.split(',').map(Number);
  const cap = Number(kv.nodecap ?? 0);
  const prov = provenance(import.meta.url, { dict: name, ...opts, headers: HDRS, cap });
  const t0 = Date.now();
  const results = new Array(headers.length);
  await new Promise((resolve, reject) => {
    let next = 0, done = 0; const nw = Math.min(Number(W), headers.length);
    for (let w = 0; w < nw; w++) {
      const wk = new Worker(new URL(import.meta.url), { workerData: { dictBytes: Array.from(dict), opts, cap, maxStore: Number(kv.store ?? 2000) } });
      const give = () => { if (next < headers.length) { wk.postMessage(headers[next++]); } else wk.postMessage(null); };
      wk.on('message', m => {
        results[headers.indexOf(m.h)] = m; done++;
        if (done % 256 === 0 || done === headers.length) console.error(`${name} K=${opts.K}: ${done}/${headers.length} headers, ${((Date.now() - t0) / 1000).toFixed(0)} s`);
        if (done === headers.length) resolve();
        give();
      });
      wk.on('error', reject);
      give();
    }
  });
  const secs = (Date.now() - t0) / 1000;
  // every leaf was verified in the workers with the fast JavaScript reference; the stored ones are verified again here
  // with decode36 and with the WebAssembly module
  const w = await wasmDecoder(dict, opts);
  const f = x => decode36(x, dict, opts).out;
  let verified = 0; const points = [];
  for (const r of results) for (const x of r.solutions) {
    const xb = Uint8Array.from(Buffer.from(x, 'hex'));
    let y = xb, ok = true; const orbit = [x];
    for (let i = 0; i < opts.K; i++) { const a = f(y), b = w(y); if (hex(a) !== hex(b)) ok = false; y = a; if (i < opts.K - 1) orbit.push(hex(y)); }
    if (hex(y) !== x || (opts.K > 1 && orbit[1] === x)) ok = false;
    if (ok) verified++;
    points.push({ header: r.h, x, latin1: Buffer.from(xb).toString('latin1'), ok, orbit });
  }
  const sum = k => results.reduce((s, r) => s + r[k], 0);
  const nodes = sum('nodes'), leaves = sum('count'), minimal = sum('minimal'), bad = sum('bad'), cappedH = results.filter(r => r.capped).map(r => r.h);
  const freeHist = new Array(17).fill(0); for (const r of results) r.freeHist.forEach((c, i) => freeHist[i] += c);
  const families = opts.K === 1 ? sum('nfamilies') : null;
  const famList = []; if (opts.K === 1) for (const r of results) for (const [k, c] of r.families) famList.push({ header: r.h, key: k, size: c });
  const perHeader = results.map(r => [r.h, r.nodes, r.minimal, r.ms, r.nfamilies]);
  const res = {
    provenance: prov, dict: name, file: loadDict(ID).file, bytes: dict.length, ...opts, headersSearched: headers.length, headersTotal: all,
    complete: headers.length === all && cappedH.length === 0, cappedHeaders: cappedH, nodes, seconds: secs,
    leaves, leavesFailingFastCheck: bad, solutions: minimal, cycles: minimal / opts.K, families, freeBytesHist: freeHist,
    headersWithSolutions: results.filter(r => r.minimal > 0).length,
    storedSolutions: points.length, storedVerifiedDecode36AndWasm: verified,
    note: (opts.K === 1 ? 'solutions = fixed points; a family is a fixed point with its self-read literal bytes (literals read from the very bits they write, any value works) blanked'
      : 'solutions = points of least period 2 (f(f(x)) = x, f(x) != x); cycles = solutions / 2') + (opts.tie ? `; restricted to x, f(x) equal on the bytes of tie mask ${opts.tie.toString(16)} (bit k = byte k): complete for that class only` : ''),
    perHeaderColumns: ['header', 'nodes', 'solutions', 'ms', 'families'], perHeader, families: famList.length <= 200000 ? famList : famList.slice(0, 200000), familyCount: families, points,
  };
  const out = kv.out || `${outDir}/exact-${name}-K${opts.K}${opts.tie ? '-tie' + opts.tie.toString(16) : ''}${HDRS === 'all' ? '' : '-h' + HDRS.replace(/[^0-9a-z]+/g, '_')}.json`;
  fs.writeFileSync(out, JSON.stringify(res));
  const summary = { dict: name, K: opts.K, headers: headers.length, complete: res.complete, nodes, seconds: secs, leaves, bad, solutions: minimal, cycles: minimal / opts.K, families, freeHist, stored: points.length, verified, out };
  console.error(JSON.stringify(summary));
  console.log(JSON.stringify(summary));
}

// every fixed point through the WebAssembly module: each family (a fixed point with its self-read literal bytes blanked)
// is expanded over all values of its free bytes; the expanded count must equal the search's count
async function verifyAll(dict, name, opts, outDir) {
  const p = `${outDir}/exact-${name}-K1.json`, e = JSON.parse(fs.readFileSync(p, 'utf8'));
  if (e.families.length !== e.familyCount) throw new Error('family list truncated');
  const w = await wasmDecoder(dict, opts), t0 = Date.now();
  let total = 0, bad = 0;
  for (const fam of e.families) {
    const [kh, mh] = fam.key.split(':'), base = Uint8Array.from(Buffer.from(kh, 'hex')), mask = parseInt(mh, 16), free = [];
    for (let k = 0; k < 16; k++) if ((mask >> k) & 1) free.push(k);
    const n = 256 ** free.length, x = Uint8Array.from(base); let ok = 0;
    for (let v = 0; v < n; v++) {
      let q = v; for (const k of free) { x[k] = q & 255; q = Math.floor(q / 256); }
      const y = w(x); let eq = true; for (let k = 0; k < 16; k++) if (y[k] !== x[k]) { eq = false; break; }
      if (eq) ok++; else bad++;
    }
    if (ok !== fam.size) console.error('family size mismatch', fam.key, ok, fam.size);
    total += ok;
  }
  const res = { provenance: provenance(import.meta.url, { dict: name, ...opts, verifyall: true }), dict: name, families: e.families.length, expandedFixedPointsVerifiedByWasm: total, failures: bad, searchCount: e.solutions, agree: total === e.solutions && bad === 0, seconds: (Date.now() - t0) / 1000 };
  fs.writeFileSync(`${outDir}/exact-${name}-K1-verifyall.json`, JSON.stringify(res));
  console.log(JSON.stringify(res));
}

// the sampling cross-check: iterate f from N random cells and check every fixed point and 2-cycle reached against the exact lists
async function sampleCheck(dict, name, opts, N, outDir) {
  const { fastF, rng } = await import('./map-lib.mjs');
  const f = fastF(dict, opts), r = rng(12345), x = new Uint8Array(16), y = new Uint8Array(16);
  const load = k => { const p = `${outDir}/exact-${name}-K${k}.json`; return fs.existsSync(p) ? JSON.parse(fs.readFileSync(p, 'utf8')) : null; };
  const e1 = load(1), e2files = fs.readdirSync(outDir).filter(f => f.startsWith(`exact-${name}-K2`) && f.endsWith('.json')), e2s = e2files.map(f => JSON.parse(fs.readFileSync(`${outDir}/${f}`, 'utf8')));
  const e2 = e2s.length ? { points: e2s.flatMap(e => e.points.map(p => ({ ...p, minimal: true }))), tie: e2s.map(e => e.tie) } : null;
  const fp = new Set(e1 ? e1.families.map(p => p.key) : []), c2 = new Set(e2 ? e2.points.filter(p => p.minimal).map(p => p.x) : []);
  const seenFp = new Map(), seen2 = new Map(), periods = new Map(); let unsettled = 0;
  const T = 300, STEPS = 600, hist = [];
  for (let i = 0; i < N; i++) {
    r.fill(x, 0, 16);
    for (let t = 0; t < T; t++) { f(x, 0, y, 0); x.set(y); }
    // period of the state after T steps (Brent-free: walk up to STEPS more and look for a return)
    const st = Uint8Array.from(x); let per = 0;
    for (let t = 1; t <= STEPS; t++) { f(x, 0, y, 0); x.set(y); let eq = true; for (let k = 0; k < 16; k++) if (x[k] !== st[k]) { eq = false; break; } if (eq) { per = t; break; } }
    const start = hex(x);
    if (!per) { unsettled++; continue; }
    periods.set(per, (periods.get(per) || 0) + 1);
    if (per === 1) seenFp.set(start, (seenFp.get(start) || 0) + 1);
    if (per === 2) { f(x, 0, y, 0); const a = start, b = hex(y); seen2.set(a, (seen2.get(a) || 0) + 1); seen2.set(b, seen2.get(b) || 0); }
  }
  const trace = new Int16Array(16), ft = fastF(dict, opts, trace), famKey = h => { const xb = Uint8Array.from(Buffer.from(h, 'hex')), z = new Uint8Array(16); ft(xb, 0, z, 0); let mask = 0; for (let k = 0; k < 16; k++) if (trace[k] === 8 * k) { xb[k] = 0; mask |= 1 << k; } return hex(xb) + ':' + mask.toString(16).padStart(4, '0'); };
  const missFp = [...seenFp.keys()].filter(k => !fp.has(famKey(k))), miss2 = [...seen2.keys()].filter(k => !c2.has(k));
  const res = { provenance: provenance(import.meta.url, { dict: name, ...opts, N, T, STEPS }), dict: name, N, T, STEPS, unsettled, periods: Object.fromEntries([...periods].sort((a, b) => a[0] - b[0])),
    fixedPointsReached: Object.fromEntries(seenFp), twoCyclePointsReached: Object.fromEntries(seen2), exactFixedFamilies: fp.size, exactFixed: e1 ? e1.solutions : null, exactFamiliesComplete: e1 ? e1.families.length === e1.familyCount : null, exactTwoCyclePoints: c2.size,
    fixedMissingFromExact: missFp, twoCycleMissingFromExact: miss2, exactListsPresent: { K1: !!e1, K2: !!e2 } };
  fs.writeFileSync(`${outDir}/exact-${name}-sample${N}.json`, JSON.stringify(res));
  console.log(JSON.stringify({ ...res, provenance: undefined, fixedPointsReached: seenFp.size, twoCyclePointsReached: seen2.size }));
}

if (isMainThread && process.argv[1] === new URL(import.meta.url).pathname) main().catch(e => { console.error(e); process.exit(1); });
