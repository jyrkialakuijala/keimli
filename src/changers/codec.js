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
  const CURSOR_OFFSET = 50;   // bytes added to the LZ start cursor by default
  const pixelRate = (rSym, hb) => 8 * OUT_BYTES / (hb + 8 * OUT_BYTES / rSym);  // command-level rate -> whole-pixel rate

  // Fixed memory map (bytes). The grid starts after the static region.
  const LAYOUT = { PRM: 0, COS: 512, LIT: 1024, DEC: 1024 + (4 << LIT_BITS), LUT: 31744, THR: 32768, THRY: 49152, VP8: 65536, TEXT: 131072, GRID: 196608 };
  // TEXT: the dictionary (UTF-8 bytes, up to about 64 KB), then the decoder's output buffer and flags; GRID: the lattice
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
    const bytes = new TextEncoder().encode(text);   // the dictionary as UTF-8 bytes
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
    for (let v = 0; v < 256; v++) { const wgt = weights[v]; if (!wgt) continue; const e = lut[v]; r += wgt * (e & 255); g += wgt * ((e >> 8) & 255); b += wgt * ((e >> 16) & 255); n += wgt; }
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
    if (FLAGS + 256 > LAYOUT.GRID) throw new Error('dictionary too long for the static region');
    m8.set(built.bytes, LAYOUT.TEXT);
    decoderTables(memory, built.bytes);
    const headerBits = built.headerBits ?? cursorBits(textLen), offsetUnit = Math.ceil(textLen / 2 ** headerBits);
    put(LAYOUT.PRM, [OUT, OUT_BYTES, LAYOUT.LIT, 0, 0, 0, 0, 0, textLen, FLAGS, 0, offsetUnit, 0, 0, LAYOUT.LUT, meanRaw, meanDec, gain, 0, 0, 0, 0, 0, 256, headerBits, CURSOR_OFFSET, 0, 0, FLAGS + 128, 3, 0, 0, 0, 0]);   // ..., pairBuf, pairWrite (3: both cells), gridW, gridY0, gridH, snap   // ..., pairMode, pairFlip, pairBuf
    const cosTab = new Float64Array(memory.buffer, LAYOUT.COS, 33);   // cos(pi m / 64), m = 0..32, for the DCT processors (16 and 32 points, the rest by symmetry)
    for (let m = 0; m <= 32; m++) cosTab[m] = Math.cos(Math.PI * m / 64);
    const io = { OUT, FLAGS, textLen, OUT_BYTES, offsetUnit, headerBits, cursorOffset: CURSOR_OFFSET, skipBits: 0, cursorRead: 0, meanRaw, meanDec, gain, lastOffset: () => new Int32Array(memory.buffer, LAYOUT.PRM, 13)[12],
             // cursor header width: 2^bits start positions, ceil(textLen / 2^bits) bytes apart
             setHeaderBits: bits => { const a = new Int32Array(memory.buffer, LAYOUT.PRM, 25); io.headerBits = bits; io.offsetUnit = Math.ceil(textLen / 2 ** bits); a[11] = io.offsetUnit; a[24] = bits; },
             setCursorOffset: n => { io.cursorOffset = n; new Int32Array(memory.buffer, LAYOUT.PRM, 26)[25] = n; },
             // cursor read range V: the header is ceil(log2 V) bits and its value wraps round once when it is V or more (V = textLen: every byte a start position; V = 1: no header)
             setCursorRead: V => { const a = new Int32Array(memory.buffer, LAYOUT.PRM, 25); io.cursorRead = V; io.headerBits = rangeBits(V); io.offsetUnit = 1; a[11] = 1; a[13] = V; a[24] = io.headerBits; },
             // bits of the pixel skipped before the LZ header, 0..16
             setSkipBits: n => { io.skipBits = n; new Int32Array(memory.buffer, LAYOUT.PRM, 11)[10] = n; },
             // pairs: mode 0 single cells, 1 concatenated, 2 bit-interleaved, 3 xor then add, 4 add then subtract, 5 byte-interleaved; flip swaps the roles of the two cells (alternate it per turn)
             setPair: (mode, flip, w, gy0, h, snap) => { const a = new Int32Array(memory.buffer, LAYOUT.PRM, 34); a[26] = mode | 0; a[27] = flip ? 1 : 0; if (w !== undefined) { a[30] = w | 0; a[31] = gy0 | 0; a[32] = h | 0; a[33] = snap | 0; } },   // the geometry and the snapshot: for the vote partner (pair modes 8 + m)
             setChanger: m => { new Int32Array(memory.buffer, LAYOUT.PRM, 19)[18] = m; },
             setSteps: n => { new Int32Array(memory.buffer, LAYOUT.PRM, 24)[23] = n; },
             frameSums: () => { const a = new Int32Array(memory.buffer, LAYOUT.PRM, 23); return { r: a[19], g: a[20], b: a[21], n: a[22] }; },
             setMean: (mode, packed) => { new Int32Array(memory.buffer, LAYOUT.PRM, 17)[mode === 4 ? 15 : 16] = packed; } };
    return io;
  }

  // Byte-colour LUT, 8 bits per channel packed as R | G << 8 | B << 16. The 256 colours come from
  // tools/palette.py: 257 points spread through the RGB cube by maximising the sum over colours of
  // sqrt(sqrt(distance to the nearest other colour)), with the eight corners pinned, so the closest
  // pairs are pushed apart first and the smallest gap ends near the sphere-packing limit (44.5 of
  // 255); white is one of the pinned points but is kept out of the table, so no byte is white and
  // every byte shows against a white page. Which byte value gets which colour is optimised against the
  // dictionaries: for each one, the byte values making up at least 0.2 % of its text form a working set,
  // and simulated annealing over swaps maximises the frequency-weighted sum of sqrt(sqrt(distance to the
  // nearest colour of another byte in the set)), summed over all dictionaries, so the Latin letters of the
  // Declaration and the UTF-8 bytes of the Chinese, Armenian, Cyrillic, Arabic ... texts each get a broad mix.
  const BYTE_PALETTE = new Uint32Array([
    0xbc6759, 0xff9eb0, 0x524b00, 0xac0079, 0xff5736, 0xcfdcff, 0xbf392c, 0xd3ffa7,
    0x4500d3, 0x92292c, 0x0000ff, 0x71007f, 0xa6bdff, 0x9f8c56, 0xd6d84c, 0xd4ff2a,
    0xafd470, 0xa9cfa2, 0x5affb9, 0x7dcd80, 0xd9ff6e, 0x55aad2, 0x94ff2c, 0x93d64c,
    0x9150a8, 0x9200ff, 0xd0aaa1, 0xcf847e, 0xa7a781, 0xa6dbd9, 0x30002b, 0xdc7baf,
    0xffff00, 0xffb14c, 0xbf2dd4, 0x516d2d, 0x420085, 0x81bad9, 0xffc9cf, 0x0077d5,
    0x7f822c, 0xb2ff52, 0x552e7b, 0xd36b2d, 0x00d775, 0x004286, 0x49b850, 0xd978ff,
    0x0045d4, 0x2dffa8, 0x8c277b, 0x52292a, 0xceffdb, 0xaa86a9, 0xd78c00, 0xbe56ae,
    0xdb5489, 0xff815c, 0x00a8d2, 0x2b90d2, 0x230061, 0x0000ce, 0x00312f, 0x2545ab,
    0xa90036, 0x2847ff, 0xff79d4, 0x7933ff, 0xb38f2a, 0x2b887b, 0x002fff, 0x819d00,
    0x4929ff, 0x279b50, 0xd30022, 0x007281, 0x0091ff, 0x557481, 0x77517f, 0xa97900,
    0x740027, 0x7977a7, 0x2525d7, 0x2f00ff, 0x5595a7, 0xa5ffb9, 0x2b77ff, 0xd05600,
    0x797159, 0x8e2bd0, 0xa82bff, 0xaf2456, 0x702a52, 0x002262, 0x302f53, 0x92d200,
    0xa2602c, 0x000000, 0x00c3ff, 0x57ffff, 0x000089, 0xff00ff, 0x55c9a6, 0x00ffc0,
    0xff0076, 0xff778e, 0x7c927e, 0x80ffdb, 0x008300, 0xff0000, 0xffc6ff, 0xffff8e,
    0x8987d4, 0x5559ff, 0xff6e00, 0x00ff00, 0x7e6300, 0x880057, 0x80ff64, 0x742ba5,
    0x335ad4, 0x2e75a8, 0x809fff, 0xab28a5, 0x81ff98, 0xdb55d7, 0xb3d627, 0xd4904d,
    0x0060ff, 0xa7ffff, 0xadff85, 0xffffc4, 0x83aaaa, 0x4bd675, 0xffcf9f, 0x27da51,
    0x2aa8a2, 0x67da51, 0x00b851, 0x2a8528, 0x005fac, 0x00a47e, 0x500000, 0x28b872,
    0x578200, 0x2f547d, 0x00d7d5, 0x2edbff, 0x2a6a51, 0x7bff00, 0x5cc500, 0x005258,
    0x91b02b, 0x6100ff, 0x53a97c, 0x540053, 0x2c2800, 0x545257, 0x5554a9, 0x2c4c29,
    0x2fffda, 0x008fa9, 0x008555, 0x27b82b, 0x00ffff, 0xb3ae00, 0x48d82b, 0x00682b,
    0x00ba00, 0x63ff2e, 0x2ad500, 0x2b6900, 0x27ff2c, 0x4aff56, 0x0026ad, 0x00d92b,
    0x00ff51, 0x00ff8f, 0x30a200, 0x54ff88, 0x29d794, 0x46ff00, 0x2ca9ff, 0x79ac55,
    0x00003d, 0x528a55, 0x27ff74, 0x2600ad, 0x004800, 0x59dbd8, 0x59a427, 0x009d2b,
    0xff8c29, 0x7fdcff, 0x577ad0, 0x7800d3, 0x59beff, 0x76d427, 0xa00000, 0xaa00d0,
    0xd5d78b, 0x7455d2, 0x944b56, 0xd8b128, 0xd1d2c1, 0xafaccc, 0xff003c, 0xff94ff,
    0xff2bd6, 0xff3a00, 0xd64255, 0xff53b2, 0xffd86d, 0xd30056, 0xff55ff, 0xff2958,
    0xec2b2c, 0xc500ff, 0x7fdbb7, 0xdc2eae, 0xa23f00, 0xd6d500, 0xb758ff, 0x5a2ed3,
    0xdd00d2, 0xdc2fff, 0x4425aa, 0xff00ac, 0xffff49, 0xcd2200, 0x8568ff, 0xffb000,
    0xb3b44c, 0xb3ff00, 0x9100a5, 0xff556a, 0xd2aaff, 0x568aff, 0xab8aff, 0xffd528,
    0x744e2d, 0xbf7ed5, 0x5f00ab, 0xff308d, 0x00c7a7, 0xb0457e, 0x2dc9ca, 0xd2227c,
    0xffa77f, 0x9e7080, 0x752600, 0xd4b36e, 0xca00a2, 0xdfa2d3, 0x252585, 0xa258d4]);
  function byteLut() { return new Uint32Array(BYTE_PALETTE); }

  return { MIN_MATCH, MAX_MATCH_LIMIT, SKIP_BITS, LIT_BITS, OUT_BYTES, cursorBits, rangeBits, CURSOR_OFFSET, pixelRate, LAYOUT,
           huffmanLengths, canonicalTable, build, install, reverseBits, byteLut, BYTE_PALETTE, lutMean, vp8Model, morseTable, decoderTables, MORSE, ZIGZAG4, JPEG_Q4 };
})();
