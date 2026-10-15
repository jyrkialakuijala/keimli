// snap2.mjs <turns> <offset>...: after T turns write snap_<off>.png (8-frame average of the LUT view) and
// act_<off>.png (how many of the last 16 turns changed each pixel: black 0 .. white 16), both 256x256 (2x).
import fs from 'node:fs'; import vm from 'node:vm';
import { png } from './png.mjs';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const Codec = vm.runInThisContext(fs.readFileSync(dir + '/src/changers/codec.js', 'utf8') + '; Codec');
const Band = vm.runInThisContext(fs.readFileSync(dir + '/src/lattice/band.js', 'utf8') + '; Band');
const text = fs.readFileSync(dir + '/src/changers/declaration.txt', 'utf8').trim();
const bytes = fs.readFileSync(dir + '/build/keimli.wasm');
const [T, ...offs] = process.argv.slice(2).map(Number);
const W = 128, H = 128, N = W * H;
const up2 = (src, ch) => { const o = new Uint8Array(4 * 4 * N); for (let y = 0; y < 2 * H; y++) for (let x = 0; x < 2 * W; x++) { const s = 4 * ((y >> 1) * W + (x >> 1)), d = 4 * (y * 2 * W + x); o[d] = src[s]; o[d + 1] = src[s + 1]; o[d + 2] = src[s + 2]; o[d + 3] = 255; } return o; };
for (const off of offs) {
  const { instance } = await WebAssembly.instantiate(bytes);
  const { memory, mix_from, smooth, change, randomize, render } = instance.exports;
  const built = Codec.build(text, 3), io = Codec.install(memory, built, Codec.byteLut(built.bytes));
  const L = Codec.LAYOUT, GRID = L.GRID, GRID2 = GRID + 16 * N + 64, PIX = GRID2 + 16 * N + 64, PAL = PIX + 4 * N + 64;
  if (PAL + 600 > memory.buffer.byteLength) memory.grow(Math.ceil((PAL + 600 - memory.buffer.byteLength) / 65536));
  const m8 = new Uint8Array(memory.buffer);
  new BigUint64Array(memory.buffer, L.THR, W).set(Band.gradient(0, 1, W));
  new BigUint64Array(memory.buffer, L.THRY, H).set(Band.gradient(0, 1, H));
  io.setCursorOffset(off); io.setChanger(0);
  randomize(4 * N, GRID, 4242);
  const acc = new Float64Array(4 * N), cnt = new Uint8Array(N); let frames = 0, before = null;
  for (let t = 1; t <= T; t++) {
    if (t > T - 16) before = m8.slice(GRID, GRID + 16 * N);
    m8.copyWithin(GRID2, GRID, GRID + 16 * N);
    for (const ph of Band.order(t)) mix_from(W, H, GRID, GRID2, ph, Band.edgeParity(ph, t & 1), L.THR, 0n);
    for (let i = 0; i < 3; i++) { smooth(W, H, GRID, GRID2, L.THRY, 0n, 1); m8.copyWithin(GRID, GRID2, GRID2 + 16 * N); }
    change(N, GRID, L.PRM);
    if (t > T - 16) for (let i = 0; i < N; i++) { for (let k = 0; k < 16; k++) if (before[16 * i + k] !== m8[GRID + 16 * i + k]) { cnt[i]++; break; } }
    if (t > T - 8) { render(N, GRID, PIX, PAL, 4, L.PRM); const s = io.frameSums(); if (s.n) io.setMean(4, Math.round(s.r / s.n) | (Math.round(s.g / s.n) << 8) | (Math.round(s.b / s.n) << 16)); for (let i = 0; i < 4 * N; i++) acc[i] += m8[PIX + i]; frames++; }
  }
  const rgba = new Uint8Array(4 * N); for (let i = 0; i < 4 * N; i++) rgba[i] = Math.round(acc[i] / frames);
  fs.writeFileSync(`snap_${off}.png`, png(2 * W, 2 * H, up2(rgba)));
  const am = new Uint8Array(4 * N); for (let i = 0; i < N; i++) { const v = Math.round(cnt[i] * 255 / 16); am[4 * i] = v; am[4 * i + 1] = v; am[4 * i + 2] = v; }
  fs.writeFileSync(`act_${off}.png`, png(2 * W, 2 * H, up2(am)));
}
