// Headless Keimli: a full-grid band run with the page's defaults except where overridden; returns per-turn metrics.
import fs from 'node:fs';
import vm from 'node:vm';
import zlib from 'node:zlib';
const dir = new URL('..', import.meta.url).pathname.replace(/\/$/, '');
export const Codec = vm.runInThisContext(fs.readFileSync(dir + '/src/changers/codec.js', 'utf8') + '; Codec');
export const Band = vm.runInThisContext(fs.readFileSync(dir + '/src/lattice/band.js', 'utf8') + '; Band');
const wasmBytes = fs.readFileSync(dir + '/build/keimli.wasm');
const L = Codec.LAYOUT;
export async function makeSim({ W = 128, H = 128, passes = 3, nbr = 1, changer = 39, pairMode = 1, maxlen = 3, skip = 0, cread = 127, coff = 0, gpow = 0.07 } = {}) {
  const { instance } = await WebAssembly.instantiate(wasmBytes);
  const wasm = instance.exports, N = W * H, S = 16 * W, D = Band.depthFor(passes, nbr);
  const GRID = L.GRID, GRID2 = GRID + (H + 2 * D) * S + 64, need = GRID2 + (H + 2 * D) * S + 65536;
  if (need > wasm.memory.buffer.byteLength) wasm.memory.grow(Math.ceil((need - wasm.memory.buffer.byteLength) / 65536));
  const st = { wasm, W, H, y0: 0, rows: H, D, GRID, GRID2, PRM: L.PRM, THR: L.THR, THRY: L.THRY };
  const thrSwap = Band.gradient(0, 1, W, Band.mixRate, gpow), thrSmooth = Band.gradient(0, 1, H);
  let io = null, turn = 0;
  const m8 = () => new Uint8Array(wasm.memory.buffer);
  const base = GRID + D * S;
  function setDict(text) {
    io = Codec.install(wasm.memory, Codec.build(text, maxlen));
    io.setChanger(changer); io.setSkipBits(skip); io.setCursorRead(cread); io.setCursorOffset(coff);
  }
  function reset(seed) { wasm.randomize(4 * N, base, seed); turn = 0; }
  function step() {
    const r = Band.runTurn(st, { haloTop: null, haloBottom: null, order: Band.order(turn), alt: turn & 1, passes, nbr, thrSwap, thrSmooth,
      salts: Array.from({ length: 4 + passes }, () => 0n), changer: true, pair: { mode: pairMode, flip: turn & 1 }, mut: null });
    turn++; return r;
  }
  const grid = () => m8().subarray(base, base + 16 * N);
  return { W, H, N, setDict, reset, step, grid, get turn() { return turn; } };
}
const POP = new Uint8Array(256); for (let i = 0; i < 256; i++) POP[i] = (i & 1) + POP[i >> 1];
export function metrics(sim, prev) {
  const g = sim.grid(), { W, H, N } = sim;
  // byte entropy
  const cnt = new Float64Array(256); for (let i = 0; i < g.length; i++) cnt[g[i]]++;
  let ent = 0; for (let v = 0; v < 256; v++) if (cnt[v]) { const p = cnt[v] / g.length; ent -= p * Math.log2(p); }
  // spatial: mean Hamming between horizontal and vertical neighbours, per 128 bits
  let hs = 0, vs = 0;
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const a = 16 * (y * W + x);
    if (x + 1 < W) for (let k = 0; k < 16; k++) hs += POP[g[a + k] ^ g[a + 16 + k]];
    if (y + 1 < H) for (let k = 0; k < 16; k++) vs += POP[g[a + k] ^ g[a + 16 * W + k]];
  }
  const spatial = (hs / ((W - 1) * H) + vs / (W * (H - 1))) / 2 / 128;
  // temporal: Hamming to the previous frame and the one before
  let d1 = 0, d2 = 0;
  if (prev && prev[0]) for (let i = 0; i < g.length; i++) d1 += POP[g[i] ^ prev[0][i]];
  if (prev && prev[1]) for (let i = 0; i < g.length; i++) d2 += POP[g[i] ^ prev[1][i]];
  const z = zlib.deflateSync(Buffer.from(g), { level: 6 }).length / g.length;
  return { ent, spatial, d1: d1 / (128 * N), d2: d2 / (128 * N), zip: z };
}
export function evaluate(sim, text, { turns = 200, seed = 1, every = 10 } = {}) {
  sim.setDict(text); sim.reset(seed);
  const hist = [null, null], rows = [];
  for (let t = 0; t < turns; t++) {
    const r = sim.step();
    if (t % every === every - 1 || t >= turns - 3) {
      const m = metrics(sim, hist); rows.push({ t: t + 1, act: r.rewritten / sim.N, moved: r.moved / (128 * sim.N), ...m });
    }
    if (t >= turns - 3) { hist[1] = hist[0]; hist[0] = sim.grid().slice(); }
  }
  return rows;
}
