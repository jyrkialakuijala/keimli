// lattice5.mjs <turns> <offset>...: dancers in the stone. Page defaults with the 3x3 median neighbourhood.
// Stone = pixels periodic in place with period <= 16 (p = 1 frozen), judged on state hashes. A defect is a
// non-stone pixel with at least 3 stone pixels among its 4 neighbours (an active speck inside the flat area).
// Over the last 300 turns: stone share, defects per turn (and per 1000 stone pixels), the share of defects that
// are still a defect somewhere in their 3x3 block next turn (alive), the share of those that moved (dance), the
// mean 8-connected cluster size of defects, and the stone's x/y eighths.
import fs from 'node:fs'; import vm from 'node:vm';
const dir = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
const Codec = vm.runInThisContext(fs.readFileSync(dir + '/src/changers/codec.js', 'utf8') + '; Codec');
const Band = vm.runInThisContext(fs.readFileSync(dir + '/src/lattice/band.js', 'utf8') + '; Band');
const text = fs.readFileSync(dir + '/src/changers/declaration.txt', 'utf8').trim();
const bytes = fs.readFileSync(dir + '/build/keimli.wasm');
const [T, ...offs] = process.argv.slice(2).map(Number);
const W = 128, H = 128, N = W * H, R = 40, LAST = 300;
for (const off of offs) {
  const { instance } = await WebAssembly.instantiate(bytes);
  const { memory, mix_from, smooth, change, randomize } = instance.exports;
  const io = Codec.install(memory, Codec.build(text, 3));
  const L = Codec.LAYOUT, GRID = L.GRID, GRID2 = GRID + 16 * N + 64;
  if (GRID2 + 16 * N > memory.buffer.byteLength) memory.grow(Math.ceil((GRID2 + 16 * N - memory.buffer.byteLength) / 65536));
  const m8 = new Uint8Array(memory.buffer), m32 = new Uint32Array(memory.buffer);
  new BigUint64Array(memory.buffer, L.THR, W).set(Band.gradient(0, 1, W));
  new BigUint64Array(memory.buffer, L.THRY, H).set(Band.gradient(0, 1, H));
  io.setCursorOffset(off); io.setChanger(0);
  randomize(4 * N, GRID, 4242);
  const hist = new Uint32Array(R * N);
  let stoneSum = 0, frozenSum = 0, defSum = 0, alive = 0, moved = 0, defPrev = null, clusterSum = 0, clusterN = 0, n = 0;
  const sx = new Float64Array(8), sy = new Float64Array(8);
  for (let t = 1; t <= T; t++) {
    m8.copyWithin(GRID2, GRID, GRID + 16 * N);
    for (const ph of Band.order(t)) mix_from(W, H, GRID, GRID2, ph, Band.edgeParity(ph, t & 1), L.THR, 0n);
    for (let i = 0; i < 3; i++) { smooth(W, H, GRID, GRID2, L.THRY, 0n, 1); m8.copyWithin(GRID, GRID2, GRID2 + 16 * N); }
    change(N, GRID, L.PRM);
    const row = hist.subarray((t % R) * N, (t % R + 1) * N), g = GRID >> 2;
    for (let i = 0; i < N; i++) { let h = 2166136261; for (let k = 0; k < 4; k++) { h ^= m32[g + 4 * i + k]; h = Math.imul(h, 16777619); } row[i] = h >>> 0; }
    if (t <= T - LAST) continue;
    const at = k => hist.subarray(((t - k) % R + R) % R * N);
    const h0 = at(0), stone = new Uint8Array(N); let ns = 0, nf = 0;
    for (let i = 0; i < N; i++) for (let q = 1; q <= 16; q++) if (at(q)[i] === h0[i] && at(2 * q)[i] === h0[i]) { stone[i] = 1; ns++; if (q === 1) nf++; break; }
    stoneSum += ns; frozenSum += nf;
    const def = new Uint8Array(N); let nd = 0;
    for (let i = 0; i < N; i++) { if (stone[i]) continue; const x = i % W, y = (i / W) | 0; let c = 0;
      if (x > 0 && stone[i - 1]) c++; if (x < W - 1 && stone[i + 1]) c++; if (y > 0 && stone[i - W]) c++; if (y < H - 1 && stone[i + W]) c++;
      if (c >= 3) { def[i] = 1; nd++; } }
    defSum += nd;
    if (defPrev) { for (let i = 0; i < N; i++) { if (!defPrev[i]) continue; const x = i % W, y = (i / W) | 0; let here = def[i], near = 0;
      for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) { if (!dx && !dy) continue; const xx = x + dx, yy = y + dy; if (xx >= 0 && yy >= 0 && xx < W && yy < H && def[yy * W + xx]) near = 1; }
      if (here || near) alive++; if (!here && near) moved++; } }
    defPrev = def;
    // cluster sizes (8-connected) of defects
    const seen = new Uint8Array(N); let comps = 0, members = 0;
    for (let i = 0; i < N; i++) { if (!def[i] || seen[i]) continue; comps++; const stack = [i]; seen[i] = 1;
      while (stack.length) { const j = stack.pop(); members++; const x = j % W, y = (j / W) | 0;
        for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) { const xx = x + dx, yy = y + dy; if (xx < 0 || yy < 0 || xx >= W || yy >= H) continue; const k = yy * W + xx; if (def[k] && !seen[k]) { seen[k] = 1; stack.push(k); } } } }
    if (comps) { clusterSum += members / comps; clusterN++; }
    n++;
    if (t === T) for (let i = 0; i < N; i++) if (stone[i]) { sx[(i % W) >> 4]++; sy[(i / W / 16) | 0]++; }
  }
  const stone = stoneSum / n, defects = defSum / n, prevDefs = defSum - (defPrev ? 0 : 0);
  console.log(JSON.stringify({ off, stone: +(stone / N).toFixed(3), frozen: +(frozenSum / n / N).toFixed(3), defects: +defects.toFixed(1), perK: stone ? +(1000 * defects / stone).toFixed(2) : 0,
    alive: defSum ? +(alive / defSum).toFixed(2) : 0, dance: defSum ? +(moved / defSum).toFixed(2) : 0, cluster: clusterN ? +(clusterSum / clusterN).toFixed(2) : 0,
    sx: Array.from(sx, v => +(v / (N / 8)).toFixed(2)), sy: Array.from(sy, v => +(v / (N / 8)).toFixed(2)) }));
}
