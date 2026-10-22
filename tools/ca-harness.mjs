// Headless Keimli: a full-grid band run with the page's defaults except where overridden; returns per-turn metrics.
import fs from 'node:fs';
import vm from 'node:vm';
import zlib from 'node:zlib';
const dir = new URL('..', import.meta.url).pathname.replace(/\/$/, '');
export const Codec = vm.runInThisContext(fs.readFileSync(dir + '/src/changers/codec.js', 'utf8') + '; Codec');
export const Band = vm.runInThisContext(fs.readFileSync(dir + '/src/lattice/band.js', 'utf8') + '; Band');
const wasmBytes = fs.readFileSync(dir + '/build/keimli.wasm');
const L = Codec.LAYOUT;
// saltMode: 0 content only (the default); bit 0 salts the swap and smoothing hashes by the turn, bit 1 by the cell's
// coordinates; experimental controls that break the rule's invariance in time or space
// swap / smooth: the slider values at the two edges of the page's gradients ([0, 1] on the page: left to right for the swap
// slider p, whose exchange rate is 2p(1-p); top to bottom for the median probability); equal values give a uniform
// parameter. mixOn / settleOn / rewriteOn switch the three stages for the ablations. rewrite: an optional JS function
// (grid Uint8Array, N) that replaces the wasm changer, for null-model rewriting rules; it returns the bits it changed.
export async function makeSim({ W = 128, H = 128, passes = 3, nbr = 1, changer = 39, pairMode = 1, maxlen = 3, skip = 0, cread = 127, coff = 0, gpow = 0.2, saltMode = 0,
                                swap = [0, 1], smooth = [0, 1], mixOn = true, settleOn = true, rewriteOn = true, rewrite = null, altOrder = false, pairWrite = false, mixSync = false, steps = 0 } = {}) {
  if (!settleOn) passes = 0;
  const { instance } = await WebAssembly.instantiate(wasmBytes);
  const wasm = instance.exports, N = W * H, S = 16 * W, D = Band.depthFor(passes, nbr);
  const GRID = L.GRID, GRID2 = GRID + (H + 2 * D) * S + 64, need = GRID2 + (H + 2 * D) * S + 65536;
  if (need > wasm.memory.buffer.byteLength) wasm.memory.grow(Math.ceil((need - wasm.memory.buffer.byteLength) / 65536));
  const st = { wasm, W, H, y0: 0, rows: H, D, GRID, GRID2, PRM: L.PRM, THR: L.THR, THRY: L.THRY };
  if (steps) new Int32Array(wasm.memory.buffer, L.PRM + 92, 1)[0] = steps;   // instructions a pixel for the CPU changers (256 by default)
  const thrSwap = mixOn ? Band.gradient(swap[0], swap[1], W, Band.mixRate, gpow) : new BigUint64Array(W), thrSmooth = settleOn ? Band.gradient(smooth[0], smooth[1], H) : new BigUint64Array(H);
  let io = null, turn = 0;
  const m8 = () => new Uint8Array(wasm.memory.buffer);
  const base = GRID + D * S;
  function setDict(text) {
    io = Codec.install(wasm.memory, Codec.build(text, maxlen), undefined, 3, need);   // a dictionary too long for the static region goes past the lattice
    io.setChanger(changer); io.setSkipBits(skip); io.setCursorRead(cread); io.setCursorOffset(coff);
    if (steps) new Int32Array(wasm.memory.buffer, L.PRM + 92, 1)[0] = steps;   // after the install, which resets the parameter block (before 2026-10-21 the budget set below was overwritten here and every run used 256)
  }
  function reset(seed) { wasm.randomize(4 * N, base, seed); turn = 0; }
  function step() {
    const r = Band.runTurn(st, { haloTop: null, haloBottom: null, order: Band.order(turn, altOrder), alt: turn & 1, mixSync, passes, nbr, thrSwap, thrSmooth,
      salts: Array.from({ length: 4 + passes }, (_, k) => saltMode & 1 ? BigInt.asUintN(64, BigInt(turn + 1) * 0x9E3779B97F4A7C15n + BigInt(k + 1) * 0xD1B54A32D192ED03n) : 0n),
      posalt: !!(saltMode & 2), changer: rewriteOn && !rewrite, pair: { mode: pairMode, flip: turn & 1, write: pairWrite === false ? 3 : pairWrite === true ? 1 : pairWrite }, mut: null });   // pairWrite: a mask (bit 0 the leading cell, bit 1 the other), true = the leading cell only
    if (rewriteOn && rewrite) r.rewritten = rewrite(grid(), N);
    turn++; return r;
  }
  const grid = () => m8().subarray(base, base + 16 * N);
  return { W, H, N, setDict, reset, step, grid, get turn() { return turn; }, params: { passes, nbr, changer, pairMode, maxlen, skip, cread, coff, gpow, saltMode, swap, smooth, mixOn, settleOn, rewriteOn, altOrder } };
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
  const seen = new Set(); for (let i = 0; i < N; i++) seen.add(Buffer.from(g.subarray(16 * i, 16 * i + 16)).toString('latin1'));   // distinct pixel contents
  // regimes: every 8 x 8 block classified by its change since the previous frame (4 levels), its neighbour difference
  // (4 levels) and its byte entropy (3 levels); the effective number of classes present (exp of the class entropy) says
  // how many different kinds of behaviour the picture holds at once
  let regimes = null;
  if (prev && prev[0]) {
    const cls = new Map(); const B = 8, nbx = Math.floor(W / B), nby = Math.floor(H / B), blocks = [];
    for (let by = 0; by < nby; by++) for (let bx = 0; bx < nbx; bx++) {
      let ch = 0, nd = 0, np = 0; const bc = new Float64Array(256);
      for (let y = by * B; y < by * B + B; y++) for (let x = bx * B; x < bx * B + B; x++) {
        const a = 16 * (y * W + x);
        for (let k = 0; k < 16; k++) { ch += POP[g[a + k] ^ prev[0][a + k]]; bc[g[a + k]]++; if (x + 1 < bx * B + B) { nd += POP[g[a + k] ^ g[a + 16 + k]]; } }
        if (x + 1 < bx * B + B) np++;
      }
      const a = ch / (B * B * 128), s = np ? nd / (np * 128) : 0; let e = 0; for (let v = 0; v < 256; v++) if (bc[v]) { const p = bc[v] / (B * B * 16); e -= p * Math.log2(p); }
      const la = a < 0.01 ? 0 : a < 0.08 ? 1 : a < 0.25 ? 2 : 3, ls = s < 0.04 ? 0 : s < 0.12 ? 1 : s < 0.3 ? 2 : 3, le = e < 1.5 ? 0 : e < 3.5 ? 1 : 2;
      const key = la * 12 + ls * 3 + le; cls.set(key, (cls.get(key) || 0) + 1); blocks.push(key);
    }
    const total = nbx * nby; let Hc = 0; for (const v of cls.values()) { const p = v / total; Hc -= p * Math.log(p); }
    regimes = { classes: cls.size, effective: Math.exp(Hc), blocks };
  }
  return { ent, spatial, d1: d1 / (128 * N), d2: d2 / (128 * N), zip: z, distinct: seen.size / N, regimes };
}
export function evaluate(sim, text, { turns = 200, seed = 1, every = 10, keepFrom = turns - 3 } = {}) {   // frames are kept from turn keepFrom on, so samples after it have their previous frames
  sim.setDict(text); sim.reset(seed);
  const hist = [null, null], rows = [];
  for (let t = 0; t < turns; t++) {
    const r = sim.step();
    if (t % every === every - 1 || t >= turns - 3) {
      const m = metrics(sim, hist); rows.push({ t: t + 1, act: r.rewritten / sim.N, moved: r.moved / (128 * sim.N), ...m });
    }
    if (t >= keepFrom) { hist[1] = hist[0]; hist[0] = sim.grid().slice(); }
  }
  return rows;
}
