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
for (const [W, H, K, passes, changer, nbr = 0, pair = 0, sync = 0] of [[64, 48, 4, 1, 0, 0, 9], [64, 48, 3, 1, 36, 0, 10, 1], [64, 48, 4, 3, 0, 1, 0, 1], [64, 48, 4, 3, 0], [64, 48, 8, 1, 6], [40, 24, 3, 0, 1], [64, 48, 7, 5, 0], [64, 48, 5, 3, 0, 1], [64, 64, 3, 2, 0, 5], [64, 48, 4, 1, 6, 3], [64, 48, 4, 3, 0, 2], [64, 64, 6, 5, 3, 2], [64, 48, 4, 1, 6, 0, 2], [64, 48, 3, 1, 0, 0, 1], [64, 48, 4, 1, 0, 0, 3], [64, 48, 5, 1, 6, 0, 4], [64, 48, 4, 1, 6, 0, 5]]) {
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
    const salts = Array.from({ length: 4 + passes }, (_, k) => BigInt(turn * 64 + k + 1)), order = Band.order(turn), posalt = turn === 1;   // turn 1 salts by position too
    full.ex.salt_by_position(posalt ? 1 : 0);
    // full grid
    new BigUint64Array(full.ex.memory.buffer, L.THR, W).set(thrSwap); new BigUint64Array(full.ex.memory.buffer, L.THRY, H).set(thrSmooth);
    let fm = 0, fs2 = 0, k = 0;
    fm8.copyWithin(GRID2, GRID, GRID + 16 * N);
    if (sync) fm += full.ex.mix_sync_zone(W, GRID2, GRID, L.THR, 0, H, 0, H, 0, H, salts[k++]);   // the synchronous isotropic mixing
    else for (const ph of order) fm += full.ex.mix_from(W, H, GRID, GRID2, ph, Band.edgeParity(ph, turn & 1), L.THR, salts[k++]);
    for (let p = 0; p < passes; p++) { fs2 += full.ex.smooth(W, H, GRID, GRID2, L.THRY, salts[k++], nbr); fm8.copyWithin(GRID, GRID2, GRID2 + 16 * N); }
    full.io.setPair(pair, turn & 1, W, 0, H, GRID2);
    if (pair & 8) fm8.copyWithin(GRID2, GRID, GRID + 16 * N);   // the vote partner reads the state before any pixel is rewritten
    const fr = changer ? full.ex.change(N, GRID, L.PRM) : 0;
    const mut = { lam: BigInt(Math.round(0.05 * 2 ** 32)), salt: BigInt(turn * 64 + 63) };   // mutation: 0.05 flips a cell, after the changer
    const fmu = full.ex.mutate(N, GRID, 0, mut.lam, mut.salt);
    // bands: one message each, halos from the neighbours' edges at the end of the previous turn
    let bm = 0, bs = 0, br = 0, bmu = 0;
    const results = bands.map((b, i) => Band.runTurn(b.st, { haloTop: i > 0 ? bands[i - 1].bottom : null, haloBottom: i + 1 < bands.length ? bands[i + 1].top : null, order, alt: turn & 1, mixSync: !!sync, passes, nbr, thrSwap, thrSmooth, salts, posalt, changer: !!changer, pair: { mode: pair, flip: turn & 1 }, mut }));
    results.forEach((r, i) => { bm += r.moved; bs += r.smoothed; br += r.rewritten; bmu += r.mutated; Object.assign(bands[i], Band.edges(bands[i].st)); });
    if (fm !== bm || fs2 !== bs || fr !== br || fmu !== bmu) counts = false;
    const assembled = new Uint8Array(16 * N);
    for (const b of bands) assembled.set(b.m8.subarray(b.st.GRID + D * S, b.st.GRID + (D + b.st.rows) * S), b.st.y0 * S);
    for (let i = 0; i < 16 * N; i++) if (assembled[i] !== fm8[GRID + i]) { same = false; break; }
  }
  check(`${W}x${H}, ${bands.length} bands (depth ${D}), ${passes} passes, neighbourhood ${nbr}, changer ${changer}${pair ? ', pairs mode ' + pair : ''}${sync ? ', synchronous mixing' : ''}: grid bit-identical over 3 turns`, same);
  check(`${W}x${H}, ${bands.length} bands: moved / smoothed / rewritten counts match the full grid (mutations too)`, counts);
}
// Links on bands: the per-round protocol of Band.linkBand (UD0, LR0 on own rows; the row above comes in, UD1 with the
// top-edge pair, the row goes back; the bottom row returns; LR1), run synchronously here in band order, must give the
// same grid, the same states and the same pixel-write count as the whole-grid `links` call, over a whole turn's worth
// of rounds and across a reset.
for (const [W, H, K, kind, rounds, mode = 1] of [[32, 24, 3, 6, 40], [32, 32, 4, 7, 24], [24, 16, 2, 15, 20], [32, 24, 5, 19, 12], [32, 24, 4, 6, 24, 2], [32, 24, 3, 8, 24, 5], [32, 24, 4, 12, 24, 3], [32, 24, 3, 7, 24, 4], [32, 24, 3, 0, 24, 1], [32, 24, 4, 0, 24, 5]]) {
  const N = W * H, S = 16 * W, D = 2;
  const full = await mk(); full.io.setChanger(kind); full.io.setPair(mode, 0);
  const fm8 = new Uint8Array(full.ex.memory.buffer), GRID = L.GRID, ST = GRID + 16 * N + 1024;
  full.ex.randomize(4 * N, GRID, 1234 + K);
  const ref = fm8.slice(GRID, GRID + 16 * N);
  const bands = [];
  for (const b of Band.split(H, K, D)) {
    const inst = await mk(); inst.io.setChanger(kind); inst.io.setPair(mode, 0);
    const m8 = new Uint8Array(inst.ex.memory.buffer), G = GRID, LINKS = G + (b.rows + 2 * D) * S + 1024;
    const need = LINKS + 512 * b.rows * W; if (need > m8.length) inst.ex.memory.grow(Math.ceil((need - m8.length) / 65536));
    new Uint8Array(inst.ex.memory.buffer).set(ref.subarray(b.y0 * S, (b.y0 + b.rows) * S), G + D * S);
    const st = { wasm: inst.ex, W, H, y0: b.y0, rows: b.rows, D, GRID: G, PRM: L.PRM };
    inst.ex.links_reset(LINKS, 4 * b.rows * W, kind);
    bands.push({ st, lb: Band.linkBand(st, LINKS), LINKS, ex: inst.ex });
  }
  let fw = 0; full.ex.links_reset(ST, 4 * N, kind);
  const round = r => {   // the band protocol with the round's phase lists, forward on even rounds and reversed on odd ones
    const ph = Band.linkPhases(r);
    for (const b of bands) b.lb.early(ph.early);
    for (let k = 0; k < bands.length; k++) { const back = bands[k].lb.middle(k > 0 ? bands[k - 1].lb.bottomRow() : null); if (k > 0) bands[k - 1].lb.setBottom(back); }
    for (const b of bands) b.lb.late(ph.late);
  };
  for (let r = 0; r < rounds; r++) { for (const ph of Band.linkPhases(r).all) fw += full.ex.links(W, H, GRID, L.PRM, ph, ST); round(r); }
  const same = () => { const a = new Uint8Array(16 * N); for (const b of bands) a.set(new Uint8Array(b.ex.memory.buffer).subarray(b.st.GRID + D * S, b.st.GRID + (D + b.st.rows) * S), b.st.y0 * S); for (let i = 0; i < 16 * N; i++) if (a[i] !== fm8[GRID + i]) return false; return true; };
  const bw = bands.reduce((c, b) => c + b.lb.changed, 0);
  check(`links on ${bands.length} bands, ${W}x${H}, kind ${kind}, joining ${mode}: grid bit-identical to the whole-grid run after ${rounds} rounds (${fw} pixel writes)`, same() && fw === bw && fw > 0);
  // the states agree too: compare the forward state of the up-down pair across each band edge, which the lower band owns
  let states = true;
  for (let k = 1; k < bands.length; k++) {
    const b = bands[k], y = b.st.y0 - 1, m = new Uint8Array(b.ex.memory.buffer);
    for (let x = 0; x < W && states; x++) {
      const mine = m.subarray(b.LINKS + 256 * b.st.rows * W + 256 * x, b.LINKS + 256 * b.st.rows * W + 256 * x + 256);   // local vertical row index 0 = row y0 - 1
      const theirs = fm8.subarray(ST + 256 * (W * H + y * W + x), ST + 256 * (W * H + y * W + x) + 256);
      for (let i = 0; i < 256; i++) if (mine[i] !== theirs[i]) { states = false; break; }
    }
  }
  check(`links on ${bands.length} bands: the machines of the edge pairs carry the same registers as in the whole-grid run`, states);
  // a reset then the same number of rounds again lands on the same grid both ways
  full.ex.links_reset(ST, 4 * N, kind); for (const b of bands) b.ex.links_reset(b.LINKS, 4 * b.st.rows * W, kind);
  for (let r = 0; r < rounds; r++) { for (const ph of Band.linkPhases(r).all) full.ex.links(W, H, GRID, L.PRM, ph, ST); round(r); }
  check(`links on ${bands.length} bands: still identical after a reset and ${rounds} more rounds`, same());
}
// The swap order: fixed, UD0 LR0 UD1 LR1, the same for every turn.
{
  check('order(t) is UD0 LR0 UD1 LR1 for every turn', Band.orderName(0) === 'UD0 LR0 UD1 LR1' && [0, 1, 7, 8, 21].every(t => Band.order(t).join('') === '1032'));
  check('the order is a permutation of the four phases with LR and UD alternating', [...Band.ORDER].sort().join('') === '0123' && Band.ORDER.every((ph, i) => i === 0 || (ph & 1) !== (Band.ORDER[i - 1] & 1)));
}
// Render post-processing in bands: a band's own rows, processed with POST_HALO neighbour rows on each side, must equal
// shape: the gradient's position shaped by a power, symmetric about the centre, linear at 1
{ const g1 = Band.gradient(0, 1, 8), gl = Band.gradient(0, 1, 8, v => v, 1), g3 = Band.gradient(0, 1, 512, v => v, 0.3);
  const mid = Band.toThreshold(0.5), sym = Array.from(g3, (v, i) => v + g3[511 - i]).every(s => s >= 2n * mid - (1n << 33n) && s <= 2n * mid + (1n << 33n));
  check('gradient power 1 is the linear gradient; 0.3 is symmetric about the centre, monotone, and steep there (column 256 of 512 is near 0.5 + 0.2)', Array.from(g1).every((v, i) => v === gl[i]) && sym && Array.from(g3).every((v, i) => i === 0 || v >= g3[i - 1]) && Math.abs(Band.shape(256.5 / 512, 0.3) - 0.5 - 0.5 * (1 / 512) ** 0.3) < 1e-9 && Band.shape(0.75, 1) === 0.75 && Band.shape(0.25, 0.3) === 1 - Band.shape(0.75, 0.3)); }
// mixRate: the page's swap parameter -> exchange rate, identity at both ends, maximal at 1/2
check('mixRate: 0 and 1 give 0, 1/2 gives 1/2, 1/4 gives 3/8', Band.mixRate(0) === 0 && Band.mixRate(1) === 0 && Band.mixRate(0.5) === 0.5 && Band.mixRate(0.25) === 0.375 && Band.gradient(1, 1, 4, Band.mixRate).every(t => t === 0n));
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
    const f = frame(t), p = { stages: 2, sp: 1, k0: t === 0 ? 65536 : 20000, k4: t === 0 ? 65536 : 12000, k8: t === 0 ? 65536 : 6000, k0s: t === 0 ? 65536 : 10000, k4s: t === 0 ? 65536 : 6000, k8s: t === 0 ? 65536 : 3000, ts: 0.25, reset: t === 0 };
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
  check(`render post-processing in ${bands.length} bands with ${Band.POST_HALO} halo rows equals the whole frame over 12 frames (two stages, the slow stage, tiers, temporal and spatial sharpening)`, same);
  check('the flat-neighbourhood counts of the bands add up to the whole frame', counts);
  // two halo rows would not be enough: the band result then differs from the whole frame somewhere
  let sameWith2 = true;
  for (let t = 0; t < 12 && sameWith2; t++) {
    const f = frame(t), p = { stages: 2, sp: 1, k0: t === 0 ? 65536 : 20000, k4: t === 0 ? 65536 : 12000, k8: t === 0 ? 65536 : 6000, reset: t === 0 };
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
  let salt = 1n; for (let t = 0; t < 40; t++) for (const ph of Band.order(t)) ex.mix(W, H, L.GRID, ph, Band.edgeParity(ph, t & 1), L.THR, salt++);
  const col = new Array(W).fill(0);
  for (let i = 0; i < N; i++) for (let k = 0; k < 16; k++) if (before[16 * i + k] !== m8[L.GRID + 16 * i + k]) col[i % W]++;
  check(`column 0 swaps under the default gradient (${col[0]} changed bytes in 40 turns, column 1: ${col[1]}, column 63: ${col[63]})`, col[0] > 0 && col[0] < col[1]);
}
console.log(fails ? fails + ' failures' : 'all passed'); process.exit(fails ? 1 : 0);
