// A bit-exact JavaScript reference of the Brotli-like decoder (kind 36, src/changers/codecs.wat) on one 16-byte cell, or on
// the 32-byte joint cell of a pair (width 32: the bits wrap at 256 and 32 bytes are produced);
// checked against the WebAssembly module by decoder-map.mjs --verify. No side effects: safe to import.
// ---- the reference decoder. Returns { out, src (0 literal, 1 copy from the output, 2 copy from the dictionary, 3 kept),
// consumed, cmds, dictPos (the dictionary positions read, in order), window }
export const rangeBits = V => V <= 1 ? 0 : Math.ceil(Math.log2(V));
export function decode36(cell, dict, { skip = 6, V = 4096, coff = 0, width = 16 } = {}) {
  let cbp = skip, cused = 0; const WM = 8 * width - 1;
  const bitL = () => { const b = cbp & WM; cbp++; cused++; return (cell[b >> 3] >> (b & 7)) & 1; };
  const bitsL = n => { let v = 0; for (let i = 0; i < n; i++) v |= bitL() << i; return v; };
  let h = bitsL(rangeBits(V)); if (V && h >= V) h -= V;
  const tl = dict.length, dwin = (h + coff) % tl;
  const out = new Uint8Array(width), src = new Uint8Array(width).fill(3), dictPos = [];
  let opos = 0, cmds = 0;
  const full = () => opos >= width, stop = () => cused >= 1024 || full();
  const put = (v, s) => { if (full()) return; out[opos] = v; src[opos] = s; opos++; };
  const oref = d => {
    if (d <= opos) return [out[opos - d], 1];
    let k = (d - opos) % tl; k = dwin - k + tl; if (k >= tl) k -= tl; dictPos.push(k); return [dict[k], 2];
  };
  const xf = (v, tf, first) => {
    if (tf === 2 || (tf === 1 && first)) { if (v >= 97 && v < 123) return v - 32; }
    if (tf === 3) { if (v >= 65 && v < 91) return v + 32; }
    return v;
  };
  let r0 = 4, r1 = 11, r2 = 15, r3 = 16;
  while (!stop()) {
    let c = bitsL(2), n = c;
    if (c === 2) n = 2 + bitsL(1); else if (c === 3) n = 4 + bitsL(2);
    if (n) cmds++;
    while (n && !stop()) { put(bitsL(8), 0); n--; }
    if (stop()) break;
    c = bitsL(2); let len = c + 2;
    if (c === 2) len = 4 + bitsL(1); else if (c === 3) len = 6 + bitsL(3);
    let push = 1, d;
    if (bitsL(1) === 0) {
      const sc = bitsL(4);
      if (sc < 4) { d = [r0, r1, r2, r3][sc]; if (sc === 0) push = 0; }
      else { let k = ((sc - 4) >> 1) + 1; if (sc >= 10) k -= 3; d = sc < 10 ? r0 : r1; d = (sc & 1) === 0 ? d - k : d + k; }
    } else d = 1 + bitsL(6);
    if (d < 1) d = 1;
    let tf = 0; if (d > opos) tf = bitsL(2);
    if (push) { r3 = r2; r2 = r1; r1 = r0; r0 = d; }
    cmds++;
    let first = true;
    while (len && !full()) { const [v, s] = oref(d); put(xf(v, tf, first), s); first = false; len--; }
  }
  for (let i = opos; i < width; i++) out[i] = cell[i];   // what was not produced stays
  return { out, src, consumed: cused, cmds, dictPos, window: dwin };
}


// ---- the pair modes (decode.wat join/split): two 16-byte cells a and b become one 32-byte joint cell; flip swaps the roles.
// mode 1 concatenates; 2 interleaves bit by bit (a on the even bits); 3 nibble by nibble (a in the low nibbles); 4 two bits at a time; 5 byte by byte.
export function joinPair(a, b, mode, flip) {
  if (flip) [a, b] = [b, a];
  const j = new Uint8Array(32);
  if (mode === 1) { j.set(a, 0); j.set(b, 16); }
  else if (mode === 2) { for (let k = 0; k < 128; k++) { const ab = (a[k >> 3] >> (k & 7)) & 1, bb = (b[k >> 3] >> (k & 7)) & 1; const p = 2 * k; j[p >> 3] |= ab << (p & 7); j[(p + 1) >> 3] |= bb << ((p + 1) & 7); } }
  else if (mode === 3) { for (let m = 0; m < 32; m++) { const na = (a[m >> 1] >> ((m & 1) << 2)) & 15, nb = (b[m >> 1] >> ((m & 1) << 2)) & 15; j[m] = na | (nb << 4); } }
  else if (mode === 4) { for (let k = 0; k < 64; k++) { const pa = (a[k >> 2] >> ((k & 3) << 1)) & 3, pb = (b[k >> 2] >> ((k & 3) << 1)) & 3; const p = 4 * k; j[p >> 3] |= (pa | (pb << 2)) << (p & 7); } }   // 2-bit groups: a's at the even group positions, b's at the odd
  else if (mode === 5) { for (let m = 0; m < 16; m++) { j[2 * m] = a[m]; j[2 * m + 1] = b[m]; } }
  else throw new Error('pair mode ' + mode);
  return j;
}
export function splitPair(j, mode, flip) {
  const a = new Uint8Array(16), b = new Uint8Array(16);
  if (mode === 1) { a.set(j.subarray(0, 16)); b.set(j.subarray(16, 32)); }
  else if (mode === 2) { for (let k = 0; k < 128; k++) { const p = 2 * k; a[k >> 3] |= ((j[p >> 3] >> (p & 7)) & 1) << (k & 7); b[k >> 3] |= ((j[(p + 1) >> 3] >> ((p + 1) & 7)) & 1) << (k & 7); } }
  else if (mode === 3) { for (let m = 0; m < 32; m++) { a[m >> 1] |= (j[m] & 15) << ((m & 1) << 2); b[m >> 1] |= (j[m] >> 4) << ((m & 1) << 2); } }
  else if (mode === 4) { for (let k = 0; k < 64; k++) { const p = 4 * k, g = (j[p >> 3] >> (p & 7)) & 15; a[k >> 2] |= (g & 3) << ((k & 3) << 1); b[k >> 2] |= (g >> 2) << ((k & 3) << 1); } }
  else if (mode === 5) { for (let m = 0; m < 16; m++) { a[m] = j[2 * m]; b[m] = j[2 * m + 1]; } }
  else throw new Error('pair mode ' + mode);
  return flip ? [b, a] : [a, b];
}
