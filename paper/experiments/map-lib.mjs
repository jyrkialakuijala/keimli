// Shared helpers for the map-spine experiments (map-exact, map-null, map-shuffles): an allocation-free version of the
// kind-36 decoder (bit-identical to decode36.mjs, checked by checkFast against decode36 and by wasmDecoder against the
// WebAssembly module), a seeded random-cell source, and the entropy estimators used on samples of states.
import fs from 'node:fs';
import vm from 'node:vm';
import { decode36, rangeBits } from './decode36.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');

// ---- f as a fast function on 16-byte cells: f(src, so, dst, do) writes the 16 output bytes of the cell at src[so..so+16)
// to dst[do..do+16). Same decoder as decode36 (skip, V, coff), without the bookkeeping.
export function fastF(dict, { skip = 6, V = 4096, coff = 0 } = {}, trace = null) {   // trace: optional Int16Array(16), per output byte the stream bit (mod 128) a literal was read from, else -1
  const tl = dict.length, HB = rangeBits(V), out = new Uint8Array(16);
  let cell, so, cbp, cused;
  const bits = n => { let v = 0; for (let i = 0; i < n; i++) { const b = cbp & 127; cbp++; cused++; v |= ((cell[so + (b >> 3)] >> (b & 7)) & 1) << i; } return v; };
  return function f(src, s0, dst, d0) {
    cell = src; so = s0; cbp = skip; cused = 0; if (trace) trace.fill(-1);
    let h = bits(HB); if (V && h >= V) h -= V;
    const dwin = (h + coff) % tl;
    let opos = 0, r0 = 4, r1 = 11, r2 = 15, r3 = 16;
    while (cused < 1024 && opos < 16) {
      let c = bits(2), n = c;
      if (c === 2) n = 2 + bits(1); else if (c === 3) n = 4 + bits(2);
      while (n && cused < 1024 && opos < 16) { if (trace) trace[opos] = cbp & 127; out[opos++] = bits(8); n--; }
      if (cused >= 1024 || opos >= 16) break;
      c = bits(2); let len = c + 2;
      if (c === 2) len = 4 + bits(1); else if (c === 3) len = 6 + bits(3);
      let push = 1, d;
      if (bits(1) === 0) {
        const sc = bits(4);
        if (sc < 4) { d = sc === 0 ? r0 : sc === 1 ? r1 : sc === 2 ? r2 : r3; if (sc === 0) push = 0; }
        else { let k = ((sc - 4) >> 1) + 1; if (sc >= 10) k -= 3; d = sc < 10 ? r0 : r1; d = (sc & 1) === 0 ? d - k : d + k; }
      } else d = 1 + bits(6);
      if (d < 1) d = 1;
      let tf = 0; if (d > opos) tf = bits(2);
      if (push) { r3 = r2; r2 = r1; r1 = r0; r0 = d; }
      let first = true;
      while (len && opos < 16) {
        let v;
        if (d <= opos) v = out[opos - d];
        else { let k = (d - opos) % tl; k = dwin - k + tl; if (k >= tl) k -= tl; v = dict[k]; }
        if (tf === 2 || (tf === 1 && first)) { if (v >= 97 && v < 123) v -= 32; }
        else if (tf === 3) { if (v >= 65 && v < 91) v += 32; }
        out[opos++] = v; first = false; len--;
      }
    }
    for (let i = 0; i < 16; i++) dst[d0 + i] = i < opos ? out[i] : src[so + i];
  };
}

// ---- seeded xorshift32 random cells
export function rng(seed) {
  let rs = (seed * 2654435761 + 12345) >>> 0 || 1;
  const next = () => { rs ^= rs << 13; rs >>>= 0; rs ^= rs >>> 17; rs ^= rs << 5; rs >>>= 0; return rs; };
  return { next, fill(buf, off, n) { for (let i = 0; i < n; i += 4) { const v = next(); buf[off + i] = v & 255; buf[off + i + 1] = (v >> 8) & 255; buf[off + i + 2] = (v >> 16) & 255; buf[off + i + 3] = v >>> 24; } } };
}

// ---- the WebAssembly decoder (as in decoder-map.mjs)
export async function wasmDecoder(dictBytes, { skip = 6, V = 4096, coff = 0 } = {}) {
  const Codec = vm.runInThisContext(fs.readFileSync(dir + '/src/changers/codec.js', 'utf8') + '; Codec');
  const { instance } = await WebAssembly.instantiate(fs.readFileSync(dir + '/build/keimli.wasm'));
  const wasm = instance.exports, L = Codec.LAYOUT;
  const io = Codec.install(wasm.memory, Codec.build(Buffer.from(dictBytes).toString('latin1'), 3));
  if (io.textLen !== dictBytes.length) throw new Error('dictionary length mismatch through install');
  io.setChanger(36); io.setSkipBits(skip); io.setCursorRead(V); io.setCursorOffset(coff);
  const m8 = new Uint8Array(wasm.memory.buffer), GRID = L.GRID;
  return cell => { m8.set(cell, GRID); wasm.decode_pixel(GRID, 0, L.PRM); return m8.slice(io.OUT, io.OUT + 16); };
}

// fastF against decode36 on n random cells; returns the number of mismatches
export function checkFast(dict, opts, n = 100000, seed = 99) {
  const f = fastF(dict, opts), r = rng(seed), c = new Uint8Array(16), o = new Uint8Array(16); let bad = 0;
  for (let i = 0; i < n; i++) { r.fill(c, 0, 16); f(c, 0, o, 0); const ref = decode36(c, dict, opts).out; for (let k = 0; k < 16; k++) if (o[k] !== ref[k]) { bad++; break; } }
  return bad;
}

export const hex = (b, o = 0) => Buffer.from(b.subarray ? b.subarray(o, o + 16) : b).toString('hex');

// ---- estimators on a multiset of states given as counts
// H2: -log2 of the unbiased collision probability sum c(c-1) / (N(N-1)) (Infinity when no collision is seen);
// Hinf: -log2(max c / N) (the plug-in min-entropy); H: plug-in Shannon entropy (a lower bound when the support is undersampled).
export function entropies(counts, N) {
  let coll = 0, max = 0, H = 0, distinct = 0, f1 = 0, f2 = 0;
  for (const c of counts) { distinct++; coll += c * (c - 1); if (c > max) max = c; const p = c / N; H -= p * Math.log2(p); if (c === 1) f1++; else if (c === 2) f2++; }
  const pc = coll / (N * (N - 1));
  return { distinct, H2: pc > 0 ? -Math.log2(pc) : Infinity, collisions: coll / 2, Hinf: -Math.log2(max / N), maxCount: max, Hplugin: H, f1, f2 };
}
// counts of 16-byte states in a flat Uint8Array of n states
export function countStates(buf, n) {
  const m = new Map();
  for (let i = 0; i < n; i++) { const k = Buffer.from(buf.buffer, buf.byteOffset + 16 * i, 16).toString('latin1'); m.set(k, (m.get(k) || 0) + 1); }
  return m;
}
