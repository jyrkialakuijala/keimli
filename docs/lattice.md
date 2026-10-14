# The lattice

Source: `src/lattice/lattice.wat` (the kernels) and `src/lattice/band.js`
(the turn, the swap-order cycle, the band pipeline for worker threads).
Tests: `test/mix.test.mjs` (mixing rule, smoothing, jam checks) and
`test/band.test.mjs` (bands reproduce the full grid bit for bit).

Every pixel is a 128-bit string stored as two little-endian 64-bit words.
The grid is a plane with edges, not a torus.

## A turn

1. **Snapshot.** The whole grid is copied to a scratch buffer. Every swap
   decision of the turn is read from this copy (`mix_from`, the `snap`
   argument of `mix_zone`), so which pair exchanges which bit is settled
   from the pre-turn state, and the exchanges are then applied to the live
   map in phase order. An exchange whose two bits are already equal when it
   is applied, because an earlier phase moved one of them, is a no-op and is
   not counted.
2. **Four swap phases**, one per neighbour direction and parity, in this
   turn's order (below).
3. **Bit-plane median filtering passes** (entropy decrease), 0 to 5 per turn (default 3).
4. **The local changer** rewrites every pixel's 16 bytes with its output
   (see [changers.md](changers.md)). It can be switched off, in which case
   it only feeds the views.

The view is refreshed once per turn.

## Entropy increase through gene swapping

A swap phase pairs every pixel with one neighbour: left–right (LR) or
up–down (UD), at an even (0) or odd (1) offset. Pairs never cross a row end
or the last row, so the last pixel of a row and the last row sit out the
odd-offset phases.

For each pair the two strings are compared position by position. Where the
bits differ, the 32 bits neighbouring that position (16 below, 16 above,
wrapping around the 128-bit ring, the position itself excluded) are hashed
separately for each pixel with a splitmix64 finaliser and the two 64-bit
hashes are added with overflow, so the decision is independent of pixel
order. The first position whose sum is below the threshold has that single
bit exchanged. Swaps conserve the total number of set bits. Because
identical contexts hash identically, a uniform boundary is all-or-nothing;
the optional turn-number salt (distinct for every phase and pass) breaks the
tie.

The swap probability is a per-column table: a linear gradient from the
left-edge value to the right-edge value, each 0 to 1 (defaults 0 and 1),
sampled at pixel centres (column x gets (x + 0.5) / W of the way) so the
first column is not frozen at exactly 0; a pair uses its first pixel's
column. `Band.gradient` builds the table, shared with the tests. The kernel
walks only the bit positions where the two pixels differ (`$pair`), uses a
branchless 128-bit rotate for the context (`$ctx`), and skips hashing
entirely at p = 0 and p = 1.

## The swap-order cycle

The four phases LR0, UD0, LR1, UD1 run once each per turn, so every pixel
exchanges once with each neighbour. Their order changes every turn.
Left–right and up–down always alternate, which leaves 8 of the 24
permutations (LR or UD first, and the order within each pair); turn t uses
order t mod 8 (`Band.order`), so over any 8 turns every order has been used
once and no fixed order can shape the long run.

The cycle through the 8 is arranged so that consecutive orders differ as
much as possible. Measuring the difference of two orders as the total
distance the four phases move between them (at most 8), no cycle through
the 8 keeps every step at 8; the cycle used, found by exhaustive search,
has 6 steps of 8 and 2 of 6, the optimum. Each phase goes first twice per
cycle and no two consecutive turns share a first or a last phase. The page
shows the current order next to the turn counter.

| turn mod 8 | order |
|---|---|
| 0 | LR0 UD0 LR1 UD1 |
| 1 | UD0 LR1 UD1 LR0 |
| 2 | LR0 UD1 LR1 UD0 |
| 3 | LR1 UD0 LR0 UD1 |
| 4 | UD1 LR0 UD0 LR1 |
| 5 | LR1 UD1 LR0 UD0 |
| 6 | UD0 LR0 UD1 LR1 |
| 7 | UD1 LR1 UD0 LR0 |

## Entropy decrease through bit-plane median filtering

A pass works on each of the 128 bit planes separately and is computed
synchronously into a scratch buffer. For every pixel and bit position where
the bit disagrees with the majority of its neighbourhood, the pixel's 32-bit
context of that position is hashed; if the hash is below the smoothing
threshold, the bit takes the majority value. At p = 1 every disagreeing bit
is replaced each pass.

The neighbourhood is selectable: the pixel and its four 4-connected
neighbours (5 votes, majority at 3), the 3 × 3 block (9 votes, 5) or the
5 × 5 block (25 votes, 13). Coordinates are clamped to the grid, so at an
edge the missing neighbours count as the nearest pixel. The kernel counts
votes bit-sliced (`$majority`) and visits only the bits that disagree with
the majority (`$smooth_px`).

The smoothing probability is a per-row table: a linear gradient from the
top-edge value to the bottom-edge value (defaults 0 and 1), sampled at
pixel centres like the swap table.

## Grid utilities

`bits` counts the set bits of the grid, `randomize` fills memory with
xorshift32 words for the random starts.

## Threads: the band pipeline

The page can run the lattice in a pool of Web Workers, one per horizontal
band of rows, each with its own wasm instance. A band keeps D halo rows
above and below (`Band.depthFor`: 2 plus one row per smoothing pass for the
cross and 3 × 3 neighbourhoods, two per pass for 5 × 5, rounded up to even)
and receives them once per turn from its neighbours' edge rows. It then
runs the whole turn locally with the zone kernels `mix_zone` and
`smooth_zone`, shrinking its valid zone by a row on a side whenever an
up-down phase pairs across the zone edge or a smoothing pass reads across
it. Pairs on band boundaries are computed redundantly by both neighbours,
which is deterministic, so a turn costs a single message round trip. Each
band snapshots its whole buffer, halos included, at the start of the turn.

`band.js` holds this bookkeeping and `test/band.test.mjs` checks that the
pipeline reproduces the full-grid functions bit for bit, counts included,
for several band counts, pass counts, neighbourhoods and changers.

Changing the thread count, the pass count or the neighbourhood rebuilds the
worker pool but carries the lattice over bit for bit: the old engine's cells
are read out, the new one is seeded with them, and the turn counter keeps
running; only a new grid size starts over. Shared-memory wasm threads are
not used because they need cross-origin isolation, which `file://` pages do
not have.

## Exports

`mix`, `mix_from`, `mix_zone`, `smooth`, `smooth_zone`, `bits`,
`randomize`, and `memory`.
