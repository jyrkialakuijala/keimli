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
  // swap phases once, always in the same order: UD0 LR0 UD1 LR1. (An earlier version cycled
  // through the 8 LR/UD-alternating orders with the turn counter. With the fixed order the
  // specks in the frozen floor mostly stand still and blink; the cycle made them wander.)
  // Names as shown in the page.
  const PHASE_NAMES = ['LR0', 'UD0', 'LR1', 'UD1'];
  const ORDER = [1, 0, 3, 2];
  const order = () => ORDER;
  const orderName = () => ORDER.map(p => PHASE_NAMES[p]).join(' ');
  // The brick pattern of a phase leaves an edge column (left-right phases) or an edge row (up-down
  // phases) without partners; those pixels pair along their edge instead (up and down in a left-right
  // phase, left and right in an up-down phase) with a brick offset of their own, so that every pixel
  // takes part in four exchanges a turn. The offset alternates with the turn parity alt, and the two
  // directions use opposite offsets, so a corner (two neighbours only) gets three exchanges every turn
  // rather than four and two in alternation. leftover(n, off) says whether the pattern with offset off
  // over n pixels leaves an end pixel out.
  const edgeParity = (ph, alt) => (ph & 1) ? (alt ^ 1) : alt;
  const leftover = (n, off) => off === 1 || ((n - 1 - off) & 1) === 0;
  // The swap phases cost at most two rows per side (given even band starts and an even depth):
  // an up-down phase, or a left-right phase whose leftover columns pair up and down, invalidates a
  // zone-edge row whose partner lies outside, and with the fixed order that happens at most twice.
  // Each smoothing pass costs R rows per side, R = radius(nbr): 1 for the 4- and 8-connected
  // neighbourhoods, r for the (2r+1)x(2r+1) blocks (nbr 2..5). Kept even so the parity argument holds.
  const radius = nbr => nbr >= 2 ? nbr : 1;   // nbr 0 and 1: the cross and the 3x3; nbr r >= 2: the (2r+1)x(2r+1) square
  const depthFor = (passes, nbr = 0) => { const n = radius(nbr) * passes; return 2 + n + (n & 1); };
  // st = { wasm, W, H, y0, rows, D, GRID, GRID2, PRM, THR, THRY }
  // msg = { haloTop, haloBottom (Uint8Array of D rows or null at the grid edge), order (the turn's four phase ids), alt (the turn parity, for the edge pairs), passes,
  //         thrSwap (BigUint64Array W), thrSmooth (BigUint64Array H), salts (BigInt per step), changer (bool), pair ({ mode, flip }),
  //         nbr (smoothing neighbourhood 0 cross / 1 3x3 / r = 2..5 the (2r+1)x(2r+1) block), mut ({ lam, salt }: expected flips per pixel as 32.32
  //         fixed-point BigInt, and this turn's salt; absent or lam 0 for no mutation), influence (a BigInt salt: measure the segment influence of pairs with it; absent or 0n: do not) }
  // runTurn = runHead (the swap phases and the smoothing passes) + runTail (the changer and the mutation); the worker
  // runs the link rounds in between when links are on, see linkBand.
  function runTurn(st, msg) { return Object.assign(runHead(st, msg), runTail(st, msg)); }
  function runHead(st, msg) {
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
    if (msg.pair) new Int32Array(wasm.memory.buffer, st.PRM + 104, 2).set([msg.pair.mode | 0, msg.pair.flip ? 1 : 0]);   // pairs: the joining and this turn's flip, for the link rounds and the changer
    let moved = 0, smoothed = 0, k = 0;
    m8.copyWithin(GRID2, GRID, GRID + (rows + 2 * D) * S);   // snapshot: every swap decision of the turn is read from the map before the first phase
    for (const ph of msg.order) {
      const ea = edgeParity(ph, msg.alt | 0);
      moved += wasm.mix_zone(W, GRID, GRID2, ph, ea, st.THR, gy0, H, D - vt, D + rows + vb, D, D + rows, msg.salts[k++]);   // count only the band's own rows
      // vertical pairs (an up-down phase, or the leftover columns of a left-right phase): a zone-edge row whose
      // partner lies outside the zone is no longer valid
      const off = (ph & 1) ? ph >> 1 : leftover(W, ph >> 1) ? ea : -1;
      if (off >= 0) {
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
    return { moved, smoothed };
  }
  // the changer (unless the link rounds took its place: then linkWrites is their pixel-write count) and the mutation
  function runTail(st, msg, linkWrites = 0) {
    const { wasm, W, y0, rows, D, GRID } = st, S = 16 * W;
    // segment influence (msg.influence): before the changer rewrites the pairs, how much each half decides the other's new content
    let infl = null;
    if (msg.influence && msg.pair && msg.pair.mode && msg.changer && !msg.links) { wasm.influence(rows * W, GRID + D * S, st.PRM, st.GRID2, BigInt(msg.influence)); infl = Array.from(new Int32Array(wasm.memory.buffer, st.GRID2, 5)); }
    const rewritten = msg.links ? linkWrites : msg.changer ? wasm.change(rows * W, GRID + D * S, st.PRM) : 0;
    const mutated = msg.mut && msg.mut.lam ? wasm.mutate(rows * W, GRID + D * S, y0 * W, msg.mut.lam, msg.mut.salt) : 0;   // own rows, global pixel indices
    return { rewritten, mutated, infl };
  }
  // ---- links: the persistent per-link CPUs in a band (docs/changers.md). Within a phase the pairs are disjoint and
  // every machine touches only its own two pixels, so a phase splits over bands exactly; only the up-down pairs across
  // a band edge need care. A band owns the left-right pairs of its rows and the up-down pairs whose first row is
  // y0 - 1 .. y1 - 2: the pair across its top edge is its own (its first row is odd, so it belongs to UD1), the one
  // across its bottom edge is the next band's. A round is early(phases) on the own rows; then middle(above): the
  // current row y0 - 1 from the band above goes into halo row D - 1, UD1 runs, and the changed row is handed back
  // (the band above puts it in place with setBottom); then late(phases). The band below needs this band's bottom row
  // after early() (bottomRow()) and returns it before late(). Even rounds run UD0 LR0 | UD1 | LR1 and odd rounds the
  // reverse, LR1 | UD1 | LR0 UD0 (linkPhases): with one fixed order information travels two cells down and right in a
  // round but one cell up and left, and the lattice grows streaks along the down-right diagonal; alternating the
  // direction makes the two-round light cone symmetric. states: 2 rows W pairs x 256 bytes, the left-right
  // pairs first, then the up-down pairs from local row D - 1.
  function linkStateBytes(st) { return 512 * st.rows * st.W; }
  // the phase order of link round r: the swap order forward on even rounds, reversed on odd ones (UD1 stays the
  // middle phase, the only one that crosses band edges); as early/late lists and as the flat order
  const linkPhases = r => r & 1 ? { early: [2], late: [0, 1], all: [2, 3, 0, 1] } : { early: [1, 0], late: [2], all: [1, 0, 3, 2] };
  function linkBand(st, states) {
    const { wasm, W, rows, D, GRID, PRM } = st, S = 16 * W, gy0 = st.y0 - D, top = st.y0 > 0;
    const hst = states, vst = states + 256 * rows * W;
    const m8 = () => new Uint8Array(wasm.memory.buffer);
    const run = (ph, a, b) => wasm.links_zone(W, GRID, gy0, PRM, ph, hst, D, vst, D - 1, a, b);
    let changed = 0;
    return {
      early(phases = [1, 0]) { for (const ph of phases) changed += run(ph, D, D + rows); },
      bottomRow() { return m8().slice(GRID + (D + rows - 1) * S, GRID + (D + rows) * S); },
      middle(above) {
        if (top) m8().set(above, GRID + (D - 1) * S);
        changed += run(3, top ? D - 1 : D, D + rows);
        return top ? m8().slice(GRID + (D - 1) * S, GRID + D * S) : null;
      },
      setBottom(row) { m8().set(row, GRID + (D + rows - 1) * S); },
      late(phases = [2]) { for (const ph of phases) changed += run(ph, D, D + rows); },
      get changed() { return changed; },
    };
  }
  // the band's first and last E interior rows, E = max(D, POST_HALO): the neighbours' halos for the next turn
  // (D rows) and for rendering (POST_HALO rows)
  function edges(st) {
    const S = 16 * st.W, m8 = new Uint8Array(st.wasm.memory.buffer), base = st.GRID + st.D * S, E = Math.min(st.rows, Math.max(st.D, POST_HALO));
    return { top: m8.slice(base, base + E * S), bottom: m8.slice(base + (st.rows - E) * S, base + st.rows * S) };
  }
  // ---- render post-processing, shared by the page (single-thread engine) and the band workers ----
  // A frame of w x h RGBA pixels at base is followed by three sets of accumulators (one v128 a pixel: the channels
  // as f32 lanes), a 4-byte scratch copy and the nine last raw colours of the pixel (36 bytes, for the cycle
  // detection of periods 2 to 8): POST_BYTES per pixel in all. p = { stages (0..2), sp, k0, k4, k8,
  // ts, k0s, k4s, k8s, turn, dt, cph } comes from the page, which decides the per-frame constants; rows [cy0, cy1) are the ones
  // counted as flat. With a temporal sharpening ts other than 0 a slow stage blends the last averaging stage's output
  // (the frame itself when there is none) at its own constants k0s, k4s, k8s (twice the half-time) and the frame is
  // composed from the last and the slow accumulators as (1 + ts) last - ts slow. Nothing runs when both are off.
  // A band processes its own rows plus POST_HALO neighbour rows on each side: each stage's flatness test reads one
  // row beyond a pixel of the previous stage's output and the spatial sharpening one more, so four correct
  // neighbour rows make a band's own rows identical to a whole-frame run.
  const POST_HALO = 4, POST_BYTES = 92;
  function postFrame(wasm, base, w, h, p, cy0 = 0, cy1 = h) {
    const n = w * h, acc1 = base + 4 * n, acc2 = acc1 + 16 * n, acc3 = acc2 + 16 * n, scratch = acc3 + 16 * n, hist = scratch + 4 * n;
    let flat = null;
    if (p.stages || p.ts) {
      // a pixel cycling with a period of 2 to 8 shows its cycle's mean mixed with cph/256 of the phase its column selects (x mod k at
      // frame turn) before the averaging sees it. p.dt is the number of turns since the last frame: 1 pushes the raw frame into the
      // history, 0 (a redraw of the same turn) reuses the history as it is, more than 1 clears it first
      const dt = p.dt ?? 1, clear = p.reset || dt > 1;
      wasm.cycle(w, h, base, hist, clear ? 1 : 0, p.turn | 0, p.cph ?? 31, dt === 0 && !clear ? 0 : 1);   // a cleared history always takes the frame first
      // with no averaging stage the first accumulator takes an exact copy of the frame (k = 65536), so the sharpening works against the raw frame
      const r = p.stages ? wasm.blend(w, h, base, acc1, p.k0, p.k4, p.k8, cy0, cy1) : wasm.blend(w, h, base, acc1, 65536, 65536, 65536, cy0, cy1);
      if (p.stages > 1) wasm.blend(w, h, base, acc2, p.k0, p.k4, p.k8, cy0, cy1);   // the second stage reads the first stage's output
      if (p.ts) {   // the slow stage reads the last stage's output; the frame = (1 + ts) last - ts slow
        wasm.blend(w, h, base, acc3, p.k0s ?? p.k0, p.k4s ?? p.k4, p.k8s ?? p.k8, cy0, cy1);
        wasm.unsharp(n, base, p.stages > 1 ? acc2 : acc1, acc3, -p.ts);
      }
      flat = { n4: Number(r >> 32n), n8: Number(r & 0xffffffffn) };
    }
    if (p.sp) { new Uint8Array(wasm.memory.buffer).copyWithin(scratch, base, base + 4 * n); wasm.sharpen(w, h, scratch, base, Math.round(p.sp * 256)); }   // spatial sharpening by p.sp (1 = the classic 2 x pixel - mean)
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
  // Gradient of n thresholds from probability a at one edge of the image to b at the other, sampled at pixel
  // centres: entry i is at t = (i + 0.5) / n of the way, so no pixel sits at exactly a or b and the first and last
  // columns (or rows) are not frozen when an edge value is 0. The position can be shaped by a power: t is taken
  // to u = 2t - 1 in [-1, 1], |u| is raised to pow and the sign put back, so pow < 1 makes the gradient steep at the
  // centre and flat towards the edges (more of the lattice near the edge values), pow > 1 the opposite, pow = 1 linear.
  const shape = (t, pow) => { const u = 2 * t - 1; return (Math.sign(u) * Math.abs(u) ** pow + 1) / 2; };
  const gradient = (a, b, n, f = v => v, pow = 1) => { const tab = new BigUint64Array(n); for (let i = 0; i < n; i++) tab[i] = toThreshold(f(a + (b - a) * shape((i + 0.5) / n, pow))); return tab; };
  // The swap slider p -> the per-position exchange rate 2 p (1 - p): p = 0 and p = 1 are the identity (exchanging every
  // differing bit only swaps the two pixels' places), p = 1/2 the maximal mixing, half of the differing bits crossing over.
  const mixRate = p => 2 * p * (1 - p);
  return { PHASE_NAMES, ORDER, order, orderName, edgeParity, leftover, radius, depthFor, runTurn, runHead, runTail, linkBand, linkStateBytes, linkPhases, edges, split, toThreshold, gradient, shape, mixRate, POST_HALO, POST_BYTES, postFrame };
})();
