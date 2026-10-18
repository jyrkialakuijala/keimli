// How much does each byte processor actually change? For every changer, rewrite a random
// 64x64 grid once and again, and report the share of pixels and bytes that changed each time.
// A processor that changes fewer than 5% of random pixels is classified as effectively
// "do nothing"; the test asserts the current classification so any drift is noticed.
// Run: node test/activity.test.mjs [project dir]
import fs from 'node:fs';
import vm from 'node:vm';
const dir = process.argv[2] || new URL('..', import.meta.url).pathname.replace(/\/$/, '');
const Codec = vm.runInThisContext(fs.readFileSync(dir + '/src/changers/codec.js', 'utf8') + '; Codec');
const text = fs.readFileSync(dir + '/src/changers/declaration.txt', 'utf8').trim();
const { instance } = await WebAssembly.instantiate(fs.readFileSync(dir + '/build/keimli.wasm'));
const { memory, change, randomize } = instance.exports;
const io = Codec.install(memory, Codec.build(text, 4));
const L = Codec.LAYOUT, W = 64, H = 64, N = W * H, GRID = L.GRID;
if (GRID + 16 * N > memory.buffer.byteLength) memory.grow(4);
const m8 = new Uint8Array(memory.buffer);
const names = { 0: 'LZ decompressor', 1: 'Brainfuck (empty tape, not offered)', 2: 'Brainfuck (tape = pixel)', 3: 'do nothing', 4: 'invert', 5: 'reverse',
  6: 'Z80', 7: '6502', 8: '8080', 9: 'Subleq', 10: 'CHIP-8', 11: '4004', 12: 'SM83', 13: '8051', 14: '6809', 15: 'RISC-V', 16: 'extremes (+-23/11/13)', 17: 'DCT', 18: 'inverse DCT', 19: 'PDP-8', 20: 'PDP-11', 21: '68000', 22: 'UNIVAC 1101', 23: 'VAX-11/780', 24: 'CDC 6600', 25: '68020', 26: '8086', 27: '80286', 28: '80386', 29: 'i860', 30: 'PIC1640',
  31: 'prefix code', 32: 'Morse', 33: 'Deflate fixed', 34: 'LZ4', 35: 'Snappy', 36: 'Brotli-like', 37: 'PNG filters', 38: 'JPEG 4x4', 39: 'VP8 boolean', 40: 'Rice residuals', 41: 'sort bytes', 42: 'primes first', 43: 'Alpha 21064', 44: 'PA-RISC', 45: 'codebook', 46: 'bit codebook', 47: 'Redcode' };
const THRESHOLD = 0.05, idle = [], rows = [];
for (let k = 0; k <= 47; k++) {
  io.setChanger(k);
  randomize(4 * N, GRID, 1234 + k);
  if (k === 1 || k === 2) for (let i = GRID; i < GRID + 16 * N; i++) m8[i] &= 7;   // Brainfuck wants command bytes
  const before = m8.slice(GRID, GRID + 16 * N);
  const px1 = change(N, GRID, 0);
  const mid = m8.slice(GRID, GRID + 16 * N);
  let bytes1 = 0; for (let i = 0; i < 16 * N; i++) if (before[i] !== mid[i]) bytes1++;
  const px2 = change(N, GRID, 0);
  const after = m8.slice(GRID, GRID + 16 * N);
  let bytes2 = 0; for (let i = 0; i < 16 * N; i++) if (mid[i] !== after[i]) bytes2++;
  const share = px1 / N;
  if (share < THRESHOLD) idle.push(names[k]);
  rows.push(`${names[k].padEnd(26)} pixels ${(100 * share).toFixed(1).padStart(5)}%  bytes ${(100 * bytes1 / (16 * N)).toFixed(1).padStart(5)}%   second pass: pixels ${(100 * px2 / N).toFixed(1).padStart(5)}%  bytes ${(100 * bytes2 / (16 * N)).toFixed(1).padStart(5)}%${share < THRESHOLD ? '   <- effectively do nothing' : ''}`);
}
console.log('activity on random 64x64 grids (first rewrite, then a second rewrite of the result):');
for (const r of rows) console.log('   ' + r);
const expectedIdle = ['do nothing'];
const ok = idle.length === expectedIdle.length && expectedIdle.every(n => idle.includes(n));
console.log((ok ? 'ok   ' : 'FAIL ') + `processors below ${100 * THRESHOLD}% of pixels: ${idle.join(', ') || 'none'} (expected: ${expectedIdle.join(', ')})`);
process.exit(ok ? 0 : 1);
