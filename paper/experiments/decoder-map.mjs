// The decoder as a map on 128-bit strings (research plan Q4 / H4, and the compression reviewer's "first experiment").
// A bit-exact JavaScript reference of the Brotli-like decoder (kind 36, src/changers/codecs.wat), checked against the
// WebAssembly module on random cells, then statistics over N uniformly random cells for a dictionary and a header range V:
//   consumed bits c (mean, histogram, share past 128 = the stream wrapped and re-read the cell, share at the 1,024 cap),
//   E[min(c, 128)] (an upper bound on H(f(U)) in bits: the decoder reads a prefix and stops, so every output has at least
//   2^(128 - c) preimages), the source of every output byte (literal from the cell, copy from the output, copy from the
//   dictionary, or kept because the output ran short), the output byte-marginal entropy per position, the fraction of
//   fixed points f(x) = x, the number of distinct outputs with the Chao1 lower-bound estimate, and the dictionary
//   positions ever read (the reachable region; the rest is exactly neutral for the decoder).
// Usage: node paper/experiments/decoder-map.mjs <dict id | path> [V=4096] [N=1000000] [skip=6] [coff=0] [variant=raw|shuffle|wordshuffle|reverse] [seed=1]
//   --verify runs the wasm comparison only. Output: one JSON line on stdout (and a human summary on stderr).
import fs from 'node:fs';
import vm from 'node:vm';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const Codec = vm.runInThisContext(fs.readFileSync(dir + '/src/changers/codec.js', 'utf8') + '; Codec');
const args = process.argv.slice(2).filter(a => !a.startsWith('--')), flags = new Set(process.argv.slice(2).filter(a => a.startsWith('--')));
const [ID = 'ca-swarm-f', V = 4096, N = 1e6, SKIP = 6, COFF = 0, VARIANT = 'raw', SEED = 1] = args.map((a, i) => i === 0 || i === 5 ? a : Number(a));

import { loadDict, variantOf } from './dict-variants.mjs';
import { decode36 } from './decode36.mjs';
let rs = (SEED * 2654435761 + 12345) >>> 0 || 1;
const rnd32 = () => { rs ^= rs << 13; rs >>>= 0; rs ^= rs >>> 17; rs ^= rs << 5; rs >>>= 0; return rs; };   // xorshift32 for the random cells

// ---- the wasm for comparison
async function wasmDecoder(dictBytes, { skip, V, coff }) {
  const { instance } = await WebAssembly.instantiate(fs.readFileSync(dir + '/build/keimli.wasm'));
  const wasm = instance.exports, L = Codec.LAYOUT;
  const io = Codec.install(wasm.memory, Codec.build(Buffer.from(dictBytes).toString('latin1'), 3));   // latin1 keeps every byte as one byte
  if (io.textLen !== dictBytes.length) throw new Error('dictionary length mismatch through install');
  io.setChanger(36); io.setSkipBits(skip); io.setCursorRead(V); io.setCursorOffset(coff);
  const m8 = new Uint8Array(wasm.memory.buffer), GRID = L.GRID;
  return cell => { m8.set(cell, GRID); const r = wasm.decode_pixel(GRID, 0, L.PRM); return { out: m8.slice(io.OUT, io.OUT + 16), consumed: r >> 8, window: io.lastOffset() }; };
}
const randomCell = () => { const c = new Uint8Array(16); for (let i = 0; i < 16; i += 4) { const v = rnd32(); c[i] = v & 255; c[i + 1] = (v >> 8) & 255; c[i + 2] = (v >> 16) & 255; c[i + 3] = v >>> 24; } return c; };

const dictInfo = loadDict(ID);
const dict = variantOf(dictInfo.bytes, VARIANT, SEED);
if (flags.has('--verify')) {
  let bad = 0; const n = 200000;
  for (const v of [1, 8, 128, 4096]) for (const skip of [0, 6]) {
    const w = await wasmDecoder(dict, { skip, V: v, coff: COFF });
    for (let i = 0; i < n; i++) {
      const cell = randomCell(), a = decode36(cell, dict, { skip, V: v, coff: COFF }), b = w(cell);
      if (a.consumed !== b.consumed || a.window !== b.window || a.out.some((x, k) => x !== b.out[k])) { bad++; if (bad < 4) console.error('mismatch', { v, skip, cell: Buffer.from(cell).toString('hex'), js: Buffer.from(a.out).toString('hex'), wasm: Buffer.from(b.out).toString('hex'), jc: a.consumed, wc: b.consumed, jw: a.window, ww: b.window }); }
    }
    console.error(`V ${v} skip ${skip}: ${n} cells, ${bad} mismatches`);
  }
  process.exit(bad ? 1 : 0);
}

// ---- statistics
const t0 = Date.now();
const hist = new Float64Array(65), srcCount = [0, 0, 0, 0], posEnt = Array.from({ length: 16 }, () => new Float64Array(256)), byteCount = new Float64Array(256);
const reads = new Float64Array(dict.length), seen = new Map(), bigram = new Float64Array(65536), dictBigram = new Float64Array(65536);
for (let i = 0; i + 1 < dict.length; i++) dictBigram[dict[i] << 8 | dict[i + 1]]++;
let sumC = 0, sumMinC = 0, past128 = 0, capped = 0, fixed = 0, sumCmds = 0, sumLit = 0, inputBytesKept = 0, winCount = new Float64Array(Math.max(V, 1));
for (let i = 0; i < N; i++) {
  const cell = randomCell(), r = decode36(cell, dict, { skip: SKIP, V, coff: COFF });
  sumC += r.consumed; sumMinC += Math.min(r.consumed, 128); hist[Math.min(64, r.consumed >> 4)]++;
  if (r.consumed > 128) past128++; if (r.consumed >= 1024) capped++;
  sumCmds += r.cmds;
  let same = true;
  for (let k = 0; k < 16; k++) { srcCount[r.src[k]]++; posEnt[k][r.out[k]]++; byteCount[r.out[k]]++; if (r.out[k] !== cell[k]) same = false; if (k) bigram[r.out[k - 1] << 8 | r.out[k]]++; }
  if (same) fixed++;
  for (const p of r.dictPos) reads[p]++;
  winCount[r.window]++;
  const key = Buffer.from(r.out).toString('latin1'); seen.set(key, (seen.get(key) || 0) + 1);
}
const H = cnt => { let s = 0, e = 0; for (const c of cnt) s += c; for (const c of cnt) if (c) { const p = c / s; e -= p * Math.log2(p); } return e; };
let f1 = 0, f2 = 0; for (const c of seen.values()) { if (c === 1) f1++; else if (c === 2) f2++; }
const distinct = seen.size, chao1 = distinct + (f2 ? f1 * f1 / (2 * f2) : f1 * (f1 - 1) / 2);
const reachable = reads.reduce((s, c) => s + (c > 0 ? 1 : 0), 0);
let firstUnread = -1, lastUnread = -1; for (let p = 0; p < dict.length; p++) if (!reads[p]) { if (firstUnread < 0) firstUnread = p; lastUnread = p; }
const dictHist = new Float64Array(256); for (const b of dict) dictHist[b]++;
// conditional entropy H(next byte | byte) = H(bigram) - H(byte), for the output and for the dictionary itself
const condH = (bg, h) => H(bg) - H(h);
const bgFirst = new Float64Array(256); for (let i = 0; i < 65536; i++) bgFirst[i >> 8] += bigram[i];
const dbgFirst = new Float64Array(256); for (let i = 0; i < 65536; i++) dbgFirst[i >> 8] += dictBigram[i];
const res = {
  dict: ID, variant: VARIANT, file: dictInfo.file, bytes: dict.length, pageBytes: dictInfo.pageBytes, V, skip: SKIP, coff: COFF, N, seed: SEED,
  dictDistinctBytes: dictHist.reduce((s, c) => s + (c > 0 ? 1 : 0), 0), dictByteEntropy: H(dictHist),
  consumedMean: sumC / N, minConsumedMean: sumMinC / N, past128: past128 / N, capped: capped / N, consumedHist16: Array.from(hist),
  cmdsMean: sumCmds / N,
  src: { literal: srcCount[0] / (16 * N), selfCopy: srcCount[1] / (16 * N), dictCopy: srcCount[2] / (16 * N), kept: srcCount[3] / (16 * N) },
  outByteEntropy: H(byteCount), outCondEntropy: condH(bigram, bgFirst), dictCondEntropy: condH(dictBigram, dbgFirst), posEntropy: posEnt.map(H), fixedPoints: fixed / N,
  distinct, f1, f2, chao1, log2Chao1: Math.log2(chao1),
  reachable, reachableFrac: reachable / dict.length, unreadRange: firstUnread < 0 ? null : [firstUnread, lastUnread], readsPerPos: Array.from(reads),
  windowsUsed: winCount.reduce((s, c) => s + (c > 0 ? 1 : 0), 0), seconds: (Date.now() - t0) / 1000,
};
console.error(`${ID}/${VARIANT} V ${V}: ${dict.length} B (page ${dictInfo.pageBytes}), ${res.dictDistinctBytes} distinct bytes, H ${res.dictByteEntropy.toFixed(2)} | consumed ${res.consumedMean.toFixed(1)} bits, E[min(c,128)] ${res.minConsumedMean.toFixed(1)}, past 128: ${(100 * res.past128).toFixed(1)} %, capped ${(100 * res.capped).toFixed(2)} % | ` +
  `src lit ${(100 * res.src.literal).toFixed(1)} self ${(100 * res.src.selfCopy).toFixed(1)} dict ${(100 * res.src.dictCopy).toFixed(1)} kept ${(100 * res.src.kept).toFixed(1)} % | out byte H ${res.outByteEntropy.toFixed(2)} cond H ${res.outCondEntropy.toFixed(2)} (dict cond H ${res.dictCondEntropy.toFixed(2)}) | fixed ${(100 * res.fixedPoints).toFixed(3)} % | distinct ${distinct} of ${N}, Chao1 2^${res.log2Chao1.toFixed(1)} | reachable ${reachable}/${dict.length} unread [${res.unreadRange}] | ${res.seconds.toFixed(0)} s`);
console.log(JSON.stringify(res));
