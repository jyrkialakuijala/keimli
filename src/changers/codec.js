// Code-table builder for the bit-swap lattice decoder.
// Plain script (no modules) so it can be inlined into the page and loaded by tests.
// The decoder has no literals and no distances: a pixel's bits are a 10-bit start
// cursor into a static dictionary followed by copy commands, each a prefix-coded
// length (2..maxMatch bytes) and a 3-bit skip. This builds the length code, reports
// the expected decompression rate on random input, and writes everything into wasm memory.
const Codec = (() => {
  const MIN_MATCH = 2, MAX_MATCH_LIMIT = 16, SKIP_BITS = 3;
  const LIT_BITS = 12;                       // lookup table width for the length code
  const OUT_BYTES = 16;                      // decoded output is always 128 bits
  const cursorBits = textLen => Math.max(1, Math.ceil(Math.log2(textLen)));   // start-cursor header width: ceil(log2 of the dictionary size), every byte a start position
  const CURSOR_OFFSET = 600;   // bytes added to the LZ start cursor (the dictionary's opening is a dull start)
  const pixelRate = (rSym, hb) => 8 * OUT_BYTES / (hb + 8 * OUT_BYTES / rSym);  // command-level rate -> whole-pixel rate

  // Fixed memory map (bytes). The grid starts after the static region.
  const LAYOUT = { PRM: 0, COS: 512, LIT: 1024, TEXT: 1024 + (4 << LIT_BITS) + 4096, LUT: 31744, THR: 32768, THRY: 49152, GRID: 65536 };
  // LUT: 256 x i32 byte colours; THR: per-column swap thresholds (i64, up to 2048 columns); THRY: per-row smoothing thresholds (i64, up to 2048 rows)

  // Huffman code lengths limited to `limit` bits; the result is always a complete code.
  function huffmanLengths(freq, limit) {
    const n = freq.length, lengths = new Array(n).fill(0);
    const syms = []; for (let i = 0; i < n; i++) if (freq[i] > 0) syms.push(i);
    if (syms.length === 0) return lengths;
    if (syms.length === 1) { lengths[syms[0]] = 1; return lengths; }
    const leaves = syms.map(i => ({ f: freq[i], sym: i })).sort((a, b) => a.f - b.f || a.sym - b.sym);
    const inner = []; let li = 0, ii = 0;
    const pop = () => (ii >= inner.length || (li < leaves.length && leaves[li].f <= inner[ii].f)) ? leaves[li++] : inner[ii++];
    while ((leaves.length - li) + (inner.length - ii) > 1) { const a = pop(), b = pop(); inner.push({ f: a.f + b.f, kids: [a, b] }); }
    const stack = [[pop(), 0]];
    while (stack.length) { const [nd, d] = stack.pop(); if (nd.kids) stack.push([nd.kids[0], d + 1], [nd.kids[1], d + 1]); else lengths[nd.sym] = Math.max(1, d); }
    for (const s of syms) if (lengths[s] > limit) lengths[s] = limit;
    const unit = l => 2 ** (limit - l), T = 2 ** limit;
    let K = 0; for (const s of syms) K += unit(lengths[s]);
    const asc = syms.slice().sort((a, b) => freq[a] - freq[b] || a - b);
    while (K > T) {
      let moved = false;
      for (const s of asc) { if (lengths[s] < limit) { K -= unit(lengths[s]) / 2; lengths[s]++; moved = true; if (K <= T) break; } }
      if (!moved) break;
    }
    const desc = asc.slice().reverse();
    let changed = true;
    while (K < T && changed) {
      changed = false;
      for (const s of desc) { if (lengths[s] > 1 && unit(lengths[s]) <= T - K) { K += unit(lengths[s]); lengths[s]--; changed = true; } }
    }
    return lengths;
  }

  const reverseBits = (c, l) => { let r = 0; for (let i = 0; i < l; i++) { r = (r << 1) | (c & 1); c >>= 1; } return r; };

  // Canonical code -> direct lookup table for an LSB-first bit reader. entry = sym << 8 | len.
  function canonicalTable(lengths, maxBits) {
    const blCount = new Array(maxBits + 1).fill(0);
    for (const l of lengths) if (l) blCount[l]++;
    const next = new Array(maxBits + 1).fill(0);
    let code = 0;
    for (let b = 1; b <= maxBits; b++) { code = (code + blCount[b - 1]) << 1; next[b] = code; }
    const table = new Uint32Array(1 << maxBits);
    for (let sym = 0; sym < lengths.length; sym++) {
      const l = lengths[sym]; if (!l) continue;
      const r = reverseBits(next[l]++, l);
      for (let k = r; k < table.length; k += 1 << l) table[k] = (sym << 8) | l;
    }
    return table;
  }

  // Build the length code for copies of MIN_MATCH..maxMatch bytes. Lengths are weighted
  // equally, so the canonical code gives the shorter copies the shorter codes.
  function build(text, maxMatch, headerBits) {
    maxMatch = Math.max(MIN_MATCH, Math.min(MAX_MATCH_LIMIT, maxMatch | 0));
    const bytes = Uint8Array.from(text, ch => { const c = ch.charCodeAt(0); return c < 128 ? c : 63; });
    headerBits ??= cursorBits(bytes.length);
    const n = maxMatch - MIN_MATCH + 1;
    const lenLengths = n === 1 ? [0] : huffmanLengths(new Array(n).fill(1), LIT_BITS);   // one length needs no code bits
    let inBits = 0, outBits = 0, meanCode = 0;
    for (let s = 0; s < n; s++) { const p = 2 ** -lenLengths[s]; inBits += p * (lenLengths[s] + SKIP_BITS); outBits += p * 8 * (s + MIN_MATCH); meanCode += p * lenLengths[s]; }
    return { bytes, maxMatch, headerBits, lenLengths, symbolRate: outBits / inBits, rate: pixelRate(outBits / inBits, headerBits),
             meanCommandBits: inBits, meanCodeBits: meanCode, meanCopyBytes: outBits / 8,
             expectedConsumed: headerBits + 8 * OUT_BYTES / (outBits / inBits) };
  }

  // Mean LUT colour (packed 8-bit channels) under a byte distribution given as 256 weights.
  function lutMean(lut, weights) {
    let r = 0, g = 0, b = 0, n = 0;
    for (let v = 0; v < 256; v++) { const wgt = weights[v]; if (!wgt) continue; const e = lut[v]; r += wgt * (e & 15) * 17; g += wgt * ((e >> 8) & 15) * 17; b += wgt * ((e >> 16) & 15) * 17; n += wgt; }
    return Math.round(r / n) | (Math.round(g / n) << 8) | (Math.round(b / n) << 16);
  }

  // Write the table, the dictionary, the byte LUT and the parameter block into wasm memory.
  // `gain` stretches the LUT-average views around the palette mean (1 = plain average).
  function install(memory, built, lut = byteLut(built.bytes), gain = 3) {
    const m8 = new Uint8Array(memory.buffer), m32 = new Int32Array(memory.buffer);
    const put = (off, arr) => { for (let i = 0; i < arr.length; i++) m32[(off >> 2) + i] = arr[i]; };
    put(LAYOUT.LIT, canonicalTable(built.lenLengths, LIT_BITS));
    put(LAYOUT.LUT, lut);
    const freq = new Float64Array(256); for (const b of built.bytes) freq[b]++;
    const meanRaw = lutMean(lut, new Float64Array(256).fill(1)), meanDec = lutMean(lut, freq);
    const textLen = built.bytes.length, OUT = LAYOUT.TEXT + textLen, FLAGS = OUT + 256;
    if (FLAGS + 256 > LAYOUT.LUT) throw new Error('dictionary too long for the static region');
    m8.set(built.bytes, LAYOUT.TEXT);
    const headerBits = built.headerBits ?? cursorBits(textLen), offsetUnit = Math.ceil(textLen / 2 ** headerBits);
    put(LAYOUT.PRM, [OUT, OUT_BYTES, LAYOUT.LIT, 0, 0, 0, 0, 0, textLen, FLAGS, 0, offsetUnit, 0, 0, LAYOUT.LUT, meanRaw, meanDec, gain, 0, 0, 0, 0, 0, 256, headerBits, CURSOR_OFFSET, 0, 0, FLAGS + 128]);   // ..., pairMode, pairFlip, pairBuf
    const cosTab = new Float64Array(memory.buffer, LAYOUT.COS, 33);   // cos(pi m / 64), m = 0..32, for the DCT processors (16 and 32 points, the rest by symmetry)
    for (let m = 0; m <= 32; m++) cosTab[m] = Math.cos(Math.PI * m / 64);
    const io = { OUT, FLAGS, textLen, OUT_BYTES, offsetUnit, headerBits, cursorOffset: CURSOR_OFFSET, meanRaw, meanDec, gain, lastOffset: () => new Int32Array(memory.buffer, LAYOUT.PRM, 13)[12],
             // cursor header width: 2^bits start positions, ceil(textLen / 2^bits) bytes apart
             setHeaderBits: bits => { const a = new Int32Array(memory.buffer, LAYOUT.PRM, 25); io.headerBits = bits; io.offsetUnit = Math.ceil(textLen / 2 ** bits); a[11] = io.offsetUnit; a[24] = bits; },
             setCursorOffset: n => { io.cursorOffset = n; new Int32Array(memory.buffer, LAYOUT.PRM, 26)[25] = n; },
             // pairs: mode 0 single cells, 1 concatenated, 2 bit-interleaved, 3 xor then add, 4 add then subtract, 5 byte-interleaved; flip swaps the roles of the two cells (alternate it per turn)
             setPair: (mode, flip) => { const a = new Int32Array(memory.buffer, LAYOUT.PRM, 28); a[26] = mode | 0; a[27] = flip ? 1 : 0; },
             setChanger: m => { new Int32Array(memory.buffer, LAYOUT.PRM, 19)[18] = m; },
             setSteps: n => { new Int32Array(memory.buffer, LAYOUT.PRM, 24)[23] = n; },
             frameSums: () => { const a = new Int32Array(memory.buffer, LAYOUT.PRM, 23); return { r: a[19], g: a[20], b: a[21], n: a[22] }; },
             setMean: (mode, packed) => { new Int32Array(memory.buffer, LAYOUT.PRM, 17)[mode === 4 ? 15 : 16] = packed; } };
    return io;
  }

  // Byte-colour LUT, 4 bits per channel packed as R | G << 8 | B << 16 so 16 entries can be
  // summed without carries. Designed around the dictionary's alphabet: a-z take the whole hue
  // circle in order at full saturation, A-Z are pastel versions of the same hue as their lowercase
  // letter, digits and punctuation are light neutral tones, space is white and newline light grey.
  // Byte values 0-7, the Brainfuck commands, get eight vivid hues of their own. Every other byte
  // value is coloured by its Z80 opcode class (x = bits 7-6, y = bits 5-3, z = bits 2-0): teal for
  // the x=0 loads/inc/dec/rotates/jumps, blue for LD r,r', red-to-orange for the ALU block, violet
  // for control flow and stack, pale lilac for the CB/DD/ED/FD prefixes; all kept darker than letters.
  function byteLut(dictBytes) {
    const hsl = (h, s, l) => { const f = n => { const k = (n + h / 30) % 12, a = s * Math.min(l, 1 - l); return l - a * Math.max(-1, Math.min(k - 3, 9 - k, 1)); }; return [f(0), f(8), f(4)]; };
    const pack = rgb => rgb.map(v => Math.max(0, Math.min(15, Math.round(v * 15)))).reduce((acc, q, k) => acc | (q << (8 * k)), 0);
    const inDict = new Uint8Array(256); if (dictBytes) for (const b of dictBytes) inDict[b] = 1;
    const lut = new Uint32Array(256);
    let punct = 0;
    for (let v = 0; v < 256; v++) {
      let rgb;
      if (v < 8) rgb = hsl(v * 45 + 10, 0.9, 0.55);                                        // 0-7: the eight Brainfuck commands, eight hues
      else if (v >= 97 && v <= 122) rgb = hsl((v - 97) * 360 / 26, 0.9, 0.5);            // a-z: the full hue circle
      else if (v >= 65 && v <= 90) rgb = hsl((v - 65) * 360 / 26, 0.85, 0.74);           // A-Z: pastel of the same hue
      else if (v === 32) rgb = [0.95, 0.95, 0.95];                                        // space
      else if (v === 10 || v === 13) rgb = [0.8, 0.8, 0.84];                              // newline
      else if (v >= 48 && v <= 57) rgb = hsl(200 + (v - 48) * 16, 0.25, 0.68);           // digits: cool light neutrals
      else if (inDict[v]) rgb = hsl(30 + 37 * punct++, 0.18, 0.5 + 0.04 * (punct % 4));  // punctuation: warm mid neutrals
      else {                                                                                // everything else: coloured by Z80 opcode class
        const x = v >> 6, y = (v >> 3) & 7, z = v & 7;
        if (v === 0xCB || v === 0xDD || v === 0xED || v === 0xFD) rgb = [0.92, 0.84, 0.95];   // prefixes: pale lilac
        else if (x === 0) rgb = hsl(165 + z * 7, 0.55, 0.30 + 0.04 * y);                    // loads, inc/dec, rotates, jumps: teal
        else if (x === 1) rgb = hsl(215 + z * 4, 0.45, 0.34 + 0.04 * y);                    // LD r,r': blue
        else if (x === 2) rgb = hsl(y * 7, 0.75, 0.32 + 0.04 * z);                           // ALU: ADD..CP across red to orange
        else rgb = hsl(275 + z * 8, 0.55, 0.30 + 0.04 * y);                                  // control flow, stack, I/O: violet
      }
      lut[v] = pack(rgb);
    }
    return lut;
  }

  // Mean LUT colour (packed 8-bit channels) under a byte distribution given as 256 weights.
  return { MIN_MATCH, MAX_MATCH_LIMIT, SKIP_BITS, LIT_BITS, OUT_BYTES, cursorBits, CURSOR_OFFSET, pixelRate, LAYOUT,
           huffmanLengths, canonicalTable, build, install, reverseBits, byteLut, lutMean };
})();
