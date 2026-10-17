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
  const rangeBits = V => V <= 1 ? 0 : Math.ceil(Math.log2(V));                 // header width for a cursor read range V (V = 1: no header bits)
  const CURSOR_OFFSET = 610;   // bytes added to the LZ start cursor (the dictionary's opening is a dull start)
  const pixelRate = (rSym, hb) => 8 * OUT_BYTES / (hb + 8 * OUT_BYTES / rSym);  // command-level rate -> whole-pixel rate

  // Fixed memory map (bytes). The grid starts after the static region.
  const LAYOUT = { PRM: 0, COS: 512, LIT: 1024, DEC: 1024 + (4 << LIT_BITS), TEXT: 1024 + (4 << LIT_BITS) + 4096, LUT: 31744, THR: 32768, THRY: 49152, VP8: 65536, GRID: 131072 };
  // LUT: 256 x i32 byte colours; THR: per-column swap thresholds (i64, up to 2048 columns); THRY: per-row smoothing thresholds (i64, up to 2048 rows)
  // DEC: the decoders' tables (codecs.wat); VP8: the order-1 model for the boolean decoder, 256 contexts x 256 tree nodes

  // ---- tables for the decoders (changers 31..40), see src/changers/codecs.wat ----
  const MORSE = { a: '.-', b: '-...', c: '-.-.', d: '-..', e: '.', f: '..-.', g: '--.', h: '....', i: '..', j: '.---', k: '-.-', l: '.-..', m: '--', n: '-.', o: '---', p: '.--.', q: '--.-', r: '.-.', s: '...', t: '-', u: '..-', v: '...-', w: '.--', x: '-..-', y: '-.--', z: '--..',
    0: '-----', 1: '.----', 2: '..---', 3: '...--', 4: '....-', 5: '.....', 6: '-....', 7: '--...', 8: '---..', 9: '----.',
    '.': '.-.-.-', ',': '--..--', '?': '..--..', "'": '.----.', '!': '-.-.--', '/': '-..-.', '(': '-.--.', ')': '-.--.-', '&': '.-...', ':': '---...', ';': '-.-.-.', '=': '-...-', '+': '.-.-.', '-': '-....-', '_': '..--.-', '"': '.-..-.', '@': '.--.-.' };
  const JPEG_DC_BITS = [0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0], JPEG_DC_VAL = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];   // Annex K.3, luminance DC
  const JPEG_AC_BITS = [0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 0x7d];   // K.5, luminance AC
  const JPEG_AC_VAL = [0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12, 0x21, 0x31, 0x41, 0x06, 0x13, 0x51, 0x61, 0x07, 0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xa1, 0x08, 0x23, 0x42, 0xb1, 0xc1, 0x15, 0x52, 0xd1, 0xf0,
    0x24, 0x33, 0x62, 0x72, 0x82, 0x09, 0x0a, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a,
    0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8a,
    0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6,
    0xc7, 0xc8, 0xc9, 0xca, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa];
  const JPEG_Q4 = [16, 11, 10, 16, 12, 12, 14, 19, 14, 13, 16, 24, 14, 17, 22, 29];   // the top-left 4x4 of the K.1 luminance quantiser, raster order
  const ZIGZAG4 = [0, 1, 4, 8, 5, 2, 3, 6, 9, 12, 13, 10, 7, 11, 14, 15];             // zigzag position -> raster index in a 4x4 block
  const DEFLATE_LEN_BASE = [3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258];
  const DEFLATE_LEN_EXTRA = [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0];
  const DEFLATE_DIST_BASE = [1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577];
  const DEFLATE_DIST_EXTRA = [0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13];
  // The Morse table by path: 1 followed by the elements, dot 0 and dash 1, indexes the letter; unknown patterns read '?'.
  function morseTable() {
    const t = new Uint8Array(128).fill(63);
    for (const [ch, code] of Object.entries(MORSE)) if (code.length <= 6) t[parseInt('1' + code.replace(/\./g, '0').replace(/-/g, '1'), 2)] = ch.charCodeAt(0);
    return t;
  }
  // The boolean decoder's model: for each context (the previous byte) and each node of the binary tree over the next
  // byte, the probability (1..255 out of 256) that the next bit is 0, from the dictionary's bigram counts smoothed
  // towards its byte frequencies (16 pseudo-counts) so that every byte stays decodable in every context.
  function vp8Model(bytes) {
    const n = new Float64Array(256), big = new Float64Array(65536);
    for (let i = 0; i < bytes.length; i++) { n[bytes[i]]++; if (i) big[(bytes[i - 1] << 8) | bytes[i]]++; }
    const total = bytes.length, p0 = Array.from(n, c => (c + 0.5) / (total + 128));
    const model = new Uint8Array(65536), w = new Float64Array(257);
    for (let ctx = 0; ctx < 256; ctx++) {
      w[0] = 0;
      for (let s = 0; s < 256; s++) w[s + 1] = w[s] + big[(ctx << 8) | s] + 16 * p0[s];   // prefix sums of the weights
      for (let d = 0; d < 8; d++) for (let pre = 0; pre < (1 << d); pre++) {
        const lo = pre << (8 - d), mid = lo + (1 << (7 - d)), hi = lo + (1 << (8 - d));
        const p = Math.round(256 * (w[mid] - w[lo]) / (w[hi] - w[lo]));
        model[(ctx << 8) | (1 << d) | pre] = Math.max(1, Math.min(255, p));
      }
    }
    return model;
  }
  function decoderTables(memory, bytes) {
    const m8 = new Uint8Array(memory.buffer), D = LAYOUT.DEC;
    m8.fill(0, D, D + 4096);
    new Int16Array(memory.buffer, D, 29).set(DEFLATE_LEN_BASE); m8.set(DEFLATE_LEN_EXTRA, D + 64);
    new Int32Array(memory.buffer, D + 96, 30).set(DEFLATE_DIST_BASE); m8.set(DEFLATE_DIST_EXTRA, D + 224);
    m8.set(morseTable(), D + 256);
    m8.set(JPEG_DC_BITS, D + 384); m8.set(JPEG_DC_VAL, D + 400); m8.set(JPEG_AC_BITS, D + 416); m8.set(JPEG_AC_VAL, D + 432);
    m8.set(ZIGZAG4.map(z => JPEG_Q4[z]), D + 608); m8.set(ZIGZAG4, D + 624);
    m8.set(vp8Model(bytes), LAYOUT.VP8);
  }

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
    decoderTables(memory, built.bytes);
    const headerBits = built.headerBits ?? cursorBits(textLen), offsetUnit = Math.ceil(textLen / 2 ** headerBits);
    put(LAYOUT.PRM, [OUT, OUT_BYTES, LAYOUT.LIT, 0, 0, 0, 0, 0, textLen, FLAGS, 0, offsetUnit, 0, 0, LAYOUT.LUT, meanRaw, meanDec, gain, 0, 0, 0, 0, 0, 256, headerBits, CURSOR_OFFSET, 0, 0, FLAGS + 128]);   // ..., pairMode, pairFlip, pairBuf
    const cosTab = new Float64Array(memory.buffer, LAYOUT.COS, 33);   // cos(pi m / 64), m = 0..32, for the DCT processors (16 and 32 points, the rest by symmetry)
    for (let m = 0; m <= 32; m++) cosTab[m] = Math.cos(Math.PI * m / 64);
    const io = { OUT, FLAGS, textLen, OUT_BYTES, offsetUnit, headerBits, cursorOffset: CURSOR_OFFSET, skipBits: 0, cursorRead: 0, meanRaw, meanDec, gain, lastOffset: () => new Int32Array(memory.buffer, LAYOUT.PRM, 13)[12],
             // cursor header width: 2^bits start positions, ceil(textLen / 2^bits) bytes apart
             setHeaderBits: bits => { const a = new Int32Array(memory.buffer, LAYOUT.PRM, 25); io.headerBits = bits; io.offsetUnit = Math.ceil(textLen / 2 ** bits); a[11] = io.offsetUnit; a[24] = bits; },
             setCursorOffset: n => { io.cursorOffset = n; new Int32Array(memory.buffer, LAYOUT.PRM, 26)[25] = n; },
             // cursor read range V: the header is ceil(log2 V) bits and its value is taken mod V (V = textLen: every byte a start position; V = 1: no header)
             setCursorRead: V => { const a = new Int32Array(memory.buffer, LAYOUT.PRM, 25); io.cursorRead = V; io.headerBits = rangeBits(V); io.offsetUnit = 1; a[11] = 1; a[13] = V; a[24] = io.headerBits; },
             // bits of the pixel skipped before the LZ header, 0..16
             setSkipBits: n => { io.skipBits = n; new Int32Array(memory.buffer, LAYOUT.PRM, 11)[10] = n; },
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
  return { MIN_MATCH, MAX_MATCH_LIMIT, SKIP_BITS, LIT_BITS, OUT_BYTES, cursorBits, rangeBits, CURSOR_OFFSET, pixelRate, LAYOUT,
           huffmanLengths, canonicalTable, build, install, reverseBits, byteLut, lutMean, vp8Model, morseTable, decoderTables, MORSE, ZIGZAG4, JPEG_Q4 };
})();
