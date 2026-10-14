// Band execution shared by the worker pool and the band test.
// A band owns rows [y0, y0 + rows) of the grid and keeps D halo rows above and below
// in its buffer (local row r is global row y0 - D + r). One message carries a whole
// turn: the halos are the neighbours' edge rows as they were at the end of the last
// turn, and every step that would read or pair with a row outside the valid zone
// shrinks the zone by one row on that side. Pairs across band boundaries are computed
// redundantly by both neighbours, which is deterministic, so no exchange is needed
// within a turn. The depth is chosen so the interior rows always stay valid.
const Band = (() => {
  // wasm phase ids: 0 LR even, 1 UD even, 2 LR odd, 3 UD odd. A turn runs each of the four
  // swap phases once, always alternating left-right and up-down, which leaves 8 of the 24
  // orders (LR or UD first, and the order within each pair); turn t uses order t mod 8, so
  // over 8 turns every order has been used once. The cycle is arranged so consecutive orders
  // differ as much as possible: the difference of two orders is the sum over the phases of how
  // far each phase's position moves (at most 8). No cycle through the 8 keeps every step at 8;
  // this one (found by search) has 6 steps of 8 and 2 of 6, the optimum. Each phase goes first
  // twice per cycle, and no two consecutive turns share a first or a last phase.
  // Names as shown in the page: LR0 UD0 LR1 UD1.
  const PHASE_NAMES = ['LR0', 'UD0', 'LR1', 'UD1'];
  const PERMS = ['0123', '1230', '0321', '2103', '3012', '2301', '1032', '3210'].map(s => [...s].map(Number));
  const orderDistance = (a, b) => [0, 1, 2, 3].reduce((s, ph) => s + Math.abs(a.indexOf(ph) - b.indexOf(ph)), 0);
  const order = turn => PERMS[((turn % 8) + 8) % 8];
  const orderName = turn => order(turn).map(p => PHASE_NAMES[p]).join(' ');
  // The two up-down phases cost at most two rows per side (given even band starts and an
  // even depth), each smoothing pass R rows per side, R = radius(nbr): 1 for the 4- and
  // 8-connected neighbourhoods, 2 for 5x5. Kept even so the parity argument holds.
  const radius = nbr => nbr === 2 ? 2 : 1;
  const depthFor = (passes, nbr = 0) => { const n = radius(nbr) * passes; return 2 + n + (n & 1); };
  // st = { wasm, W, H, y0, rows, D, GRID, GRID2, PRM, THR, THRY }
  // msg = { haloTop, haloBottom (Uint8Array of D rows or null at the grid edge), order (the turn's four phase ids), passes,
  //         thrSwap (BigUint64Array W), thrSmooth (BigUint64Array H), salts (BigInt per step), changer (bool), pair ({ mode, flip }),
  //         nbr (smoothing neighbourhood 0 cross / 1 3x3 / 2 5x5) }
  function runTurn(st, msg) {
    const { wasm, W, H, y0, rows, D, GRID, GRID2 } = st, S = 16 * W, y1 = y0 + rows, gy0 = y0 - D;
    const m8 = new Uint8Array(wasm.memory.buffer);
    if (msg.haloTop) m8.set(msg.haloTop.subarray(msg.haloTop.length - D * S), GRID);           // the D rows nearest the band
    if (msg.haloBottom) m8.set(msg.haloBottom.subarray(0, D * S), GRID + (D + rows) * S);
    new BigUint64Array(wasm.memory.buffer, st.THR, W).set(msg.thrSwap);
    new BigUint64Array(wasm.memory.buffer, st.THRY, H).set(msg.thrSmooth);
    const topArt = y0 > 0, botArt = y1 < H;                 // artificial boundaries (a real grid edge needs no halo)
    let vt = topArt ? D : 0, vb = botArt ? D : 0;           // valid halo rows above / below the interior
    const useTop = () => { if (vt === 0) throw new Error('band halo exhausted above'); vt--; };
    const useBot = () => { if (vb === 0) throw new Error('band halo exhausted below'); vb--; };
    let moved = 0, smoothed = 0, k = 0;
    m8.copyWithin(GRID2, GRID, GRID + (rows + 2 * D) * S);   // snapshot: every swap decision of the turn is read from the map before the first phase
    for (const ph of msg.order) {
      moved += wasm.mix_zone(W, GRID, GRID2, ph, st.THR, gy0, H, D - vt, D + rows + vb, D, D + rows, msg.salts[k++]);   // count only the band's own rows
      if (ph & 1) {   // up-down: a zone-edge row whose partner lies outside the zone is no longer valid
        const off = ph >> 1;
        if (topArt) { const g = y0 - vt; if (((g - 1) & 1) === off) useTop(); }
        if (botArt) { const gb = y1 + vb - 1; if ((gb & 1) === off) useBot(); }
      }
    }
    const nbr = msg.nbr | 0, R = radius(nbr);
    for (let p = 0; p < msg.passes; p++) {
      const a = D - vt, b = D + rows + vb;
      smoothed += wasm.smooth_zone(W, GRID, GRID2, st.THRY, gy0, H, a, b, D, D + rows, msg.salts[k++], nbr);
      m8.copyWithin(GRID + a * S, GRID2 + a * S, GRID2 + b * S);
      for (let i = 0; i < R; i++) { if (topArt) useTop(); if (botArt) useBot(); }
    }
    if (msg.pair) new Int32Array(wasm.memory.buffer, st.PRM + 104, 2).set([msg.pair.mode | 0, msg.pair.flip ? 1 : 0]);   // pairs: mode and this turn's flip
    const rewritten = msg.changer ? wasm.change(rows * W, GRID + D * S, st.PRM) : 0;
    return { moved, smoothed, rewritten };
  }
  // the band's first and last E interior rows, E = max(D, POST_HALO): the neighbours' halos for the next turn
  // (D rows) and for rendering (POST_HALO rows)
  function edges(st) {
    const S = 16 * st.W, m8 = new Uint8Array(st.wasm.memory.buffer), base = st.GRID + st.D * S, E = Math.min(st.rows, Math.max(st.D, POST_HALO));
    return { top: m8.slice(base, base + E * S), bottom: m8.slice(base + (st.rows - E) * S, base + st.rows * S) };
  }
  // ---- render post-processing, shared by the page (single-thread engine) and the band workers ----
  // A frame of w x h RGBA pixels at base is followed by two sets of 16.16 accumulators (12 bytes a pixel) and a
  // 4-byte scratch copy: POST_BYTES per pixel in all. p = { stages (0..2), sharp, k0, k4, k8 } comes from the page,
  // which decides the per-frame constants; rows [cy0, cy1) are the ones counted as flat. A band processes its own
  // rows plus POST_HALO neighbour rows on each side: the first stage's flatness test reads one row beyond a pixel,
  // the second stage's reads the first stage's output one row beyond, and the sharpening reads the second stage's
  // output one row beyond, so three correct neighbour rows make a band's own rows identical to a whole-frame run.
  const POST_HALO = 3, POST_BYTES = 32;
  function postFrame(wasm, base, w, h, p, cy0 = 0, cy1 = h) {
    const n = w * h, acc1 = base + 4 * n, acc2 = acc1 + 12 * n, scratch = acc2 + 12 * n;
    let flat = null;
    if (p.stages) {
      const r = wasm.blend(w, h, base, acc1, p.k0, p.k4, p.k8, cy0, cy1);
      if (p.stages > 1) wasm.blend(w, h, base, acc2, p.k0, p.k4, p.k8, cy0, cy1);   // the second stage reads the first stage's output
      flat = { n4: Number(r >> 32n), n8: Number(r & 0xffffffffn) };
    }
    if (p.sharp) { new Uint8Array(wasm.memory.buffer).copyWithin(scratch, base, base + 4 * n); wasm.sharpen(w, h, scratch, base); }
    return flat;
  }
  // split H rows into K bands of even heights, each at least D rows, starting at even rows
  function split(H, K, D) {
    K = Math.max(1, Math.min(K, Math.floor(H / Math.max(D, 2))));
    const pairs = H / 2, base = Math.floor(pairs / K); let extra = pairs - base * K, y = 0;
    const bands = [];
    for (let k = 0; k < K; k++) { const rows = 2 * (base + (extra-- > 0 ? 1 : 0)); bands.push({ y0: y, rows }); y += rows; }
    return bands;
  }
  // Probability p as a 64-bit threshold (p * 2^64); 0 and 1 are exact so the kernels can skip hashing.
  const toThreshold = p => p <= 0 ? 0n : p >= 1 ? (1n << 64n) - 1n : BigInt(Math.round(p * 2 ** 32)) << 32n;
  // Linear gradient of n thresholds from probability a at one edge of the image to b at the other,
  // sampled at pixel centres: entry i is a + (b - a) * (i + 0.5) / n, so no pixel sits at exactly a or b
  // and the first and last columns (or rows) are not frozen when an edge value is 0.
  const gradient = (a, b, n) => { const tab = new BigUint64Array(n); for (let i = 0; i < n; i++) tab[i] = toThreshold(a + (b - a) * (i + 0.5) / n); return tab; };
  return { PHASE_NAMES, PERMS, order, orderName, orderDistance, radius, depthFor, runTurn, edges, split, toThreshold, gradient, POST_HALO, POST_BYTES, postFrame };
})();
