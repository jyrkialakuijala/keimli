// Big dictionaries (past the 64 KB static region, up to 2^24 bytes): the wasm Brotli-like decoder against the JavaScript
// reference decode36.mjs on random cells, with the dictionary placed past a lattice region and relocated once, and the
// codebook decoders at a 16 MB text (their code x length product needs 64 bits). Run: node test/bigdict.test.mjs
import fs from 'node:fs';
import vm from 'node:vm';
const dir = process.argv[2] || new URL('..', import.meta.url).pathname.replace(/\/$/, '');
const Codec = vm.runInThisContext(fs.readFileSync(dir + '/src/changers/codec.js', 'utf8') + '; Codec');
const { decode36 } = await import(dir + '/paper/experiments/decode36.mjs');
const bytes = fs.readFileSync(dir + '/build/keimli.wasm');
let fails = 0; const check = (n, ok) => { console.log((ok ? 'ok  ' : 'FAIL') + ' ' + n); if (!ok) fails++; };
let rs = 0x1234567; const r32 = () => { rs ^= rs << 13; rs >>>= 0; rs ^= rs >>> 17; rs ^= rs << 5; rs >>>= 0; return rs; };
const randomCell = () => { const c = new Uint8Array(16); for (let i = 0; i < 16; i += 4) { const v = r32(); c[i] = v & 255; c[i + 1] = (v >> 8) & 255; c[i + 2] = (v >> 16) & 255; c[i + 3] = v >>> 24; } return c; };
const randomText = n => { const d = new Uint8Array(n); for (let i = 0; i < n; i++) d[i] = 0x20 + (r32() % 95); return d; };   // printable bytes, one byte each through Codec.build
const L = Codec.LAYOUT;
for (const size of [1 << 20, 1 << 24]) {
  const dict = randomText(size), text = Buffer.from(dict).toString('latin1');
  const { instance } = await WebAssembly.instantiate(bytes); const wasm = instance.exports;
  const GRID = L.GRID, lattice = GRID + 16 * 256 * 256 + 65536;   // a 256 x 256 lattice region the dictionary must not touch
  const io = Codec.install(wasm.memory, Codec.build(text, 3), undefined, 3, lattice);
  check(`${size >> 20} MB: installed past the lattice region (text at ${io.TEXT}, big ${io.big}, memory ${(wasm.memory.buffer.byteLength >> 20)} MB)`, io.big && io.TEXT === lattice && io.textLen === size);
  io.setChanger(36); io.setSkipBits(6); io.setCursorRead(size); io.setCursorOffset(0);
  const run = (cell, V) => { const m8 = new Uint8Array(wasm.memory.buffer); m8.set(cell, GRID); const r = wasm.decode_pixel(GRID, 0, L.PRM); return { out: m8.slice(io.OUT, io.OUT + 16), consumed: r >> 8, window: io.lastOffset() }; };
  for (const V of [size, 4096]) {
    io.setCursorRead(V); let bad = 0; const n = 20000;
    for (let i = 0; i < n; i++) { const c = randomCell(), a = decode36(c, dict, { skip: 6, V, coff: 0 }), b = run(c, V); if (a.consumed !== b.consumed || a.window !== b.window || a.out.some((x, k) => x !== b.out[k])) bad++; }
    check(`${size >> 20} MB, V = ${V} (${Codec.rangeBits(V)} header bits): ${n} random cells decode alike in wasm and decode36`, bad === 0);
  }
  // relocate once (as the page's resize does) and decode again
  const moved = io.relocate(lattice + size + 1024 * 1024); io.setCursorRead(size);
  let bad = 0; for (let i = 0; i < 5000; i++) { const c = randomCell(), a = decode36(c, dict, { skip: 6, V: size, coff: 0 }), b = run(c, size); if (a.consumed !== b.consumed || a.out.some((x, k) => x !== b.out[k])) bad++; }
  check(`${size >> 20} MB: after relocate to ${moved} the decoder still agrees (5000 cells)`, bad === 0 && io.TEXT === moved && new Int32Array(wasm.memory.buffer, L.PRM, 1)[0] === moved + size);
  // the codebook decoders read (window + code L / 1024) mod L: the product needs 64 bits at 16 MB
  if (size === 1 << 24) {
    const m8 = new Uint8Array(wasm.memory.buffer);
    io.setChanger(45); io.setSkipBits(0); io.setCursorRead(256); io.setCursorOffset(0);
    let ok = true;
    for (let i = 0; i < 2000 && ok; i++) {
      const c = randomCell(); m8.set(c, GRID); wasm.decode_pixel(GRID, 0, L.PRM); const out = m8.slice(io.OUT, io.OUT + 16);
      // reference: fold the second half into bytes 0, 1; 8 header bits MSB-first (V = 256) choose the window; then 10-bit codes MSB-first
      const f = c.slice(); let f0 = 0, f1 = 0; for (let k = 8; k < 16; k += 2) { f0 ^= c[k]; f1 ^= c[k + 1]; } f[0] ^= f0; f[1] ^= f1;
      let bp = 0; const bit = () => { const b = bp & 127; bp++; return (f[b >> 3] >> (7 - (b & 7))) & 1; }, bits = n => { let v = 0; for (let k = 0; k < n; k++) v = (v << 1) | bit(); return v; };
      const h = bits(8), win = h % size; const ref = new Uint8Array(16); let op = 0;
      while (op < 16 && bp < 1024) { const code = bits(10); const pos = Number((BigInt(win) + ((BigInt(code) * BigInt(size)) >> 10n)) % BigInt(size)); ref[op++] = dict[pos]; if (op < 16) ref[op++] = dict[(pos + 1) % size]; }
      for (let k = 0; k < 16; k++) if (out[k] !== ref[k]) ok = false;
    }
    check('16 MB: the codebook (kind 45) reads code x length in 64 bits (2000 cells against a BigInt reference)', ok);
  }
}
// small dictionaries stay where they were
{
  const { instance } = await WebAssembly.instantiate(bytes); const wasm = instance.exports;
  const io = Codec.install(wasm.memory, Codec.build(fs.readFileSync(dir + '/src/changers/declaration.txt', 'utf8').trim(), 4), undefined, 3, 1 << 20);
  check(`a small dictionary ignores textBase and stays at ${L.TEXT} (text ${io.TEXT}, big ${io.big}, relocate is a no-op ${io.relocate(1 << 20)})`, !io.big && io.TEXT === L.TEXT && io.relocate(1 << 20) === L.TEXT && wasm.memory.buffer.byteLength === 64 * 65536);
}
console.log(fails ? `${fails} FAILED` : 'all passed'); process.exit(fails ? 1 : 0);
