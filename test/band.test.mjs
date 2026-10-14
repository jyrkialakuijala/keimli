// The band pipeline used by the worker pool (one wasm instance per horizontal band, deep halos
// exchanged once per turn, see src/lattice/band.js) must reproduce the full-grid turn bit for bit.
// Run: node test/band.test.mjs [project dir]
import fs from 'node:fs';
import vm from 'node:vm';
const dir = process.argv[2] || new URL('..', import.meta.url).pathname.replace(/\/$/, '');
const Codec = vm.runInThisContext(fs.readFileSync(dir + '/src/changers/codec.js', 'utf8') + '; Codec');
const Band = vm.runInThisContext(fs.readFileSync(dir + '/src/lattice/band.js', 'utf8') + '; Band');
const text = fs.readFileSync(dir + '/src/changers/declaration.txt', 'utf8').trim();
const bytes = fs.readFileSync(dir + '/build/keimli.wasm');
const mk = async () => { const ex = (await WebAssembly.instantiate(bytes)).instance.exports; const io = Codec.install(ex.memory, Codec.build(text, 4)); return { ex, io }; };
let fails = 0; const check = (n, ok) => { console.log((ok ? 'ok  ' : 'FAIL') + ' ' + n); if (!ok) fails++; };
const L = Codec.LAYOUT;
for (const [W, H, K, passes, changer, nbr = 0, pair = 0] of [[64, 48, 4, 3, 0], [64, 48, 8, 1, 6], [40, 24, 3, 0, 1], [64, 48, 7, 5, 0], [64, 48, 5, 3, 0, 1], [64, 48, 4, 3, 0, 2], [64, 64, 6, 5, 3, 2], [64, 48, 4, 1, 6, 0, 2], [64, 48, 3, 1, 0, 0, 1]]) {
  const N = W * H, S = 16 * W, D = Band.depthFor(passes, nbr);
  const full = await mk(); full.io.setChanger(changer);
  const fm8 = new Uint8Array(full.ex.memory.buffer), GRID = L.GRID, GRID2 = GRID + 16 * N + 64;
  full.ex.randomize(4 * N, GRID, 77 + K);
  if (changer) for (let i = GRID; i < GRID + 16 * N; i++) fm8[i] &= 7;
  const ref = fm8.slice(GRID, GRID + 16 * N);
  const bands = [];
  for (const b of Band.split(H, K, D)) {
    const inst = await mk(); inst.io.setChanger(changer);
    const Lrows = b.rows + 2 * D, G = GRID, G2 = G + Lrows * S + 64;
    const m8 = new Uint8Array(inst.ex.memory.buffer);
    m8.set(ref.subarray(b.y0 * S, (b.y0 + b.rows) * S), G + D * S);
    const st = { wasm: inst.ex, W, H, y0: b.y0, rows: b.rows, D, GRID: G, GRID2: G2, PRM: L.PRM, THR: L.THR, THRY: L.THRY };
    bands.push({ st, m8, ...Band.edges(st) });
  }
  const thrSwap = new BigUint64Array(W), thrSmooth = new BigUint64Array(H);
  for (let x = 0; x < W; x++) thrSwap[x] = BigInt(Math.round(2 ** 32 * x / (W - 1))) << 32n;          // 0 .. almost 1 across x
  thrSwap[W - 1] = (1n << 64n) - 1n;
  for (let y = 0; y < H; y++) thrSmooth[y] = (1n << 64n) / BigInt(2 + y);                             // 1/2 down the rows
  let same = true, counts = true;
  for (let turn = 0; turn < 3 && same; turn++) {
    const salts = Array.from({ length: 4 + passes }, (_, k) => BigInt(turn * 64 + k + 1)), order = Band.order(turn * 7);   // a different order each turn
    // full grid
    new BigUint64Array(full.ex.memory.buffer, L.THR, W).set(thrSwap); new BigUint64Array(full.ex.memory.buffer, L.THRY, H).set(thrSmooth);
    let fm = 0, fs2 = 0, k = 0;
    fm8.copyWithin(GRID2, GRID, GRID + 16 * N);
    for (const ph of order) fm += full.ex.mix_from(W, H, GRID, GRID2, ph, L.THR, salts[k++]);
    for (let p = 0; p < passes; p++) { fs2 += full.ex.smooth(W, H, GRID, GRID2, L.THRY, salts[k++], nbr); fm8.copyWithin(GRID, GRID2, GRID2 + 16 * N); }
    full.io.setPair(pair, turn & 1);
    const fr = changer ? full.ex.change(N, GRID, L.PRM) : 0;
    // bands: one message each, halos from the neighbours' edges at the end of the previous turn
    let bm = 0, bs = 0, br = 0;
    const results = bands.map((b, i) => Band.runTurn(b.st, { haloTop: i > 0 ? bands[i - 1].bottom : null, haloBottom: i + 1 < bands.length ? bands[i + 1].top : null, order, passes, nbr, thrSwap, thrSmooth, salts, changer: !!changer, pair: { mode: pair, flip: turn & 1 } }));
    results.forEach((r, i) => { bm += r.moved; bs += r.smoothed; br += r.rewritten; Object.assign(bands[i], Band.edges(bands[i].st)); });
    if (fm !== bm || fs2 !== bs || fr !== br) counts = false;
    const assembled = new Uint8Array(16 * N);
    for (const b of bands) assembled.set(b.m8.subarray(b.st.GRID + D * S, b.st.GRID + (D + b.st.rows) * S), b.st.y0 * S);
    for (let i = 0; i < 16 * N; i++) if (assembled[i] !== fm8[GRID + i]) { same = false; break; }
  }
  check(`${W}x${H}, ${bands.length} bands (depth ${D}), ${passes} passes, neighbourhood ${nbr}, changer ${changer}${pair ? ', pairs mode ' + pair : ''}: grid bit-identical over 3 turns`, same);
  check(`${W}x${H}, ${bands.length} bands: moved / smoothed / rewritten counts match the full grid`, counts);
}
// The 8 swap orders: the permutations of the four phases in which LR (even ids) and UD (odd ids) alternate, cycling with the turn counter.
{
  const keys = new Set(Band.PERMS.map(p => p.join('')));
  check('8 distinct swap orders, each a permutation of the four phases with LR and UD alternating', Band.PERMS.length === 8 && keys.size === 8 && Band.PERMS.every(p => [...p].sort().join('') === '0123' && p.every((ph, i) => i === 0 || (ph & 1) !== (p[i - 1] & 1))));
  check('order(t) cycles with period 8, starting from LR0 UD0 LR1 UD1', Band.orderName(0) === 'LR0 UD0 LR1 UD1' && Band.order(1).join('') === '1230' && Band.order(7).join('') === '3210' && Band.order(8) === Band.order(0) && Band.order(21) === Band.order(5));
  check('every phase takes each position in the order equally often (twice each)', [0, 1, 2, 3].every(ph => [0, 1, 2, 3].every(pos => Band.PERMS.filter(p => p[pos] === ph).length === 2)));
  const dists = Band.PERMS.map((p, i) => Band.orderDistance(p, Band.PERMS[(i + 1) % 8]));
  check(`consecutive orders differ by at least 6 of the possible 8 position moves, 6 steps by 8 (total ${dists.reduce((a, b) => a + b, 0)} of the optimum 60)`, Math.min(...dists) === 6 && dists.filter(d => d === 8).length === 6 && dists.reduce((a, b) => a + b, 0) === 60);
  check('no two consecutive turns share a first or a last phase', Band.PERMS.every((p, i) => { const q = Band.PERMS[(i + 1) % 8]; return p[0] !== q[0] && p[3] !== q[3]; }));
}
// Render post-processing in bands: a band's own rows, processed with POST_HALO neighbour rows on each side, must equal
// the whole-frame computation bit for bit over a sequence of frames (two stages, the flat tiers, sharpening).
{
  const { ex } = await mk(), W = 24, H = 40, n = W * H, m8 = new Uint8Array(ex.memory.buffer);
  const FULL = L.GRID, bandBase = k => FULL + Band.POST_BYTES * n * (k + 1);
  const bands = Band.split(H, 4, 2);
  // frames: noise around a flat block whose inner edge creeps right, so every tier and the halo cases occur
  const frame = t => { const f = new Uint8Array(4 * n); let s = 12345 + t;
    for (let i = 0; i < n; i++) { const x = i % W, y = (i / W) | 0; s = (s * 1664525 + 1013904223) >>> 0;
      const flat = y >= 8 && y < 32 && x >= 4 && x < 20, v = flat ? (x < 10 + (t >> 1) ? 40 : 200) : s >>> 24;
      f.set([v, flat ? 90 : (s >>> 16) & 255, flat ? 150 : (s >>> 8) & 255, 255], 4 * i); }
    return f; };
  let same = true, counts = true;
  for (let t = 0; t < 12 && same; t++) {
    const f = frame(t), p = { stages: 2, sharp: true, k0: t === 0 ? 65536 : 20000, k4: t === 0 ? 65536 : 12000, k8: t === 0 ? 65536 : 6000 };
    m8.set(f, FULL); const flatFull = Band.postFrame(ex, FULL, W, H, p, 0, H);
    let n4 = 0, n8 = 0;
    bands.forEach((b, k) => {
      const hT = k > 0 ? Band.POST_HALO : 0, hB = k + 1 < bands.length ? Band.POST_HALO : 0, base = bandBase(k);
      m8.set(f.subarray(4 * W * (b.y0 - hT), 4 * W * (b.y0 + b.rows + hB)), base);
      const fl = Band.postFrame(ex, base, W, hT + b.rows + hB, p, hT, hT + b.rows); n4 += fl.n4; n8 += fl.n8;
      for (let i = 0; i < 4 * W * b.rows; i++) if (m8[base + 4 * W * hT + i] !== m8[FULL + 4 * W * b.y0 + i]) { same = false; break; }
    });
    if (n4 !== flatFull.n4 || n8 !== flatFull.n8) counts = false;
  }
  check(`render post-processing in ${bands.length} bands with ${Band.POST_HALO} halo rows equals the whole frame over 12 frames (two stages, tiers, sharpening)`, same);
  check('the flat-neighbourhood counts of the bands add up to the whole frame', counts);
  // two halo rows would not be enough: the band result then differs from the whole frame somewhere
  let sameWith2 = true;
  for (let t = 0; t < 12 && sameWith2; t++) {
    const f = frame(t), p = { stages: 2, sharp: true, k0: t === 0 ? 65536 : 20000, k4: t === 0 ? 65536 : 12000, k8: t === 0 ? 65536 : 6000 };
    m8.set(f, FULL); Band.postFrame(ex, FULL, W, H, p, 0, H);
    bands.forEach((b, k) => {
      const hT = k > 0 ? 2 : 0, hB = k + 1 < bands.length ? 2 : 0, base = bandBase(k);
      m8.set(f.subarray(4 * W * (b.y0 - hT), 4 * W * (b.y0 + b.rows + hB)), base);
      Band.postFrame(ex, base, W, hT + b.rows + hB, p, hT, hT + b.rows);
      for (let i = 0; i < 4 * W * b.rows; i++) if (m8[base + 4 * W * hT + i] !== m8[FULL + 4 * W * b.y0 + i]) { sameWith2 = false; break; }
    });
  }
  console.log(`   (with only 2 halo rows the bands ${sameWith2 ? 'still matched on these frames' : 'differ from the whole frame, as expected'})`);
}
// Gradients are sampled at pixel centres: no column or row is frozen at exactly 0, and the table is symmetric.
{
  const g = Band.gradient(0, 1, 64), full = (1n << 64n) - 1n;
  check('gradient 0 -> 1 over 64 columns: first column above 0, last below 1, symmetric, increasing',
    g[0] > 0n && g[63] < full && g[0] === (1n << 64n) - g[63] && g.every((v, i) => i === 0 || v > g[i - 1]) && g[0] === Band.toThreshold(0.5 / 64));
  check('gradient edge values are exact at 0 and 1 when both ends agree', Band.gradient(0, 0, 8).every(v => v === 0n) && Band.gradient(1, 1, 8).every(v => v === full));
  // with the default gradient the first column must still take part in swaps
  const { ex } = await mk(), W = 64, H = 32, N = W * H, m8 = new Uint8Array(ex.memory.buffer);
  ex.randomize(4 * N, L.GRID, 77);
  new BigUint64Array(ex.memory.buffer, L.THR, W).set(g);
  const before = m8.slice(L.GRID, L.GRID + 16 * N);
  let salt = 1n; for (let t = 0; t < 40; t++) for (const ph of Band.order(t)) ex.mix(W, H, L.GRID, ph, L.THR, salt++);
  const col = new Array(W).fill(0);
  for (let i = 0; i < N; i++) for (let k = 0; k < 16; k++) if (before[16 * i + k] !== m8[L.GRID + 16 * i + k]) col[i % W]++;
  check(`column 0 swaps under the default gradient (${col[0]} changed bytes in 40 turns, column 1: ${col[1]}, column 63: ${col[63]})`, col[0] > 0 && col[0] < col[1]);
}
console.log(fails ? fails + ' failures' : 'all passed'); process.exit(fails ? 1 : 0);
