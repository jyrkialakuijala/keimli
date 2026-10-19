# The lattice

Source: `src/lattice/lattice.wat` (the kernels) and `src/lattice/band.js`
(the turn, the swap order, the band pipeline for worker threads).
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
   it only feeds the views. With a CPU changer on cell pairs this step is
   instead rounds of four phases of persistent per-link CPUs, one
   instruction each.
5. **Mutation** flips a random share of all bits (below).

The view is refreshed once per turn.

## Entropy increase through gene swapping

Each of the three stages has an on/off box in its section header. Swapping
off sends the kernel a table of zero thresholds, so no pair exchanges a bit
and nothing is hashed; median filtering off does the same for the
smoothing passes, which then copy every pixel unchanged; the local changer
off skips the rewrite (the views still decode with the selected decoder).

A swap phase pairs every pixel with one neighbour: left–right (LR) or
up–down (UD), at an even (0) or odd (1) offset. Pairs never cross a row end
or the last row, so the last pixel of a row and the last row sit out the
odd-offset phases.

For each pair the two strings are compared position by position. Where the
bits differ, the 32 bits neighbouring that position (16 below, 16 above,
wrapping around the 128-bit ring, the position itself excluded) are taken
from each pixel, the two contexts are packed without regard to order, the
smaller in the low word and the larger in the high, an injective key of the
unordered pair, and hashed once with a splitmix64 finaliser, so the
decision is independent of pixel order and costs one hash per position. Every position whose sum is below the threshold is exchanged on its
own, so a pair undergoes a uniform crossover at the rate the threshold
encodes. The page maps the slider value p to the rate 2 p (1 − p)
(`Band.mixRate`): exchanging every differing bit would only make the two
pixels change places, so p = 1 is the identity like p = 0, and p = 0.5 is
the maximal mixing, half of the differing bits crossing over. The kernel
itself takes the rate directly: a threshold of 2^64 − 1 exchanges every
differing bit. Swaps conserve the total number of set bits. Because identical contexts
hash identically, a uniform boundary is all-or-nothing position by
position.
By default the page passes salt 0 to the swap and smoothing kernels, so
the hashes see the neighbouring bits only: the rule is the same at every
place and every turn, which is what makes the lattice a cellular automaton,
and its randomness is quenched in the configuration rather than drawn
afresh. The **Hash salt** control under Mixing's More settings offers three
experimental alternatives for comparison: *by turn* adds the turn number to
every decision (annealed noise: the same bits decide differently from turn
to turn), *by position* adds the cell's coordinates (the same bits decide
differently from place to place; `salt_by_position` in `lattice.wat`), and
*both*. Each breaks one of the rule's invariances and changes the pictures;
they exist so that the quenched hashing can be told apart from the stages
themselves in an experiment, not as settings to run. The harness takes the
same choice as `saltMode`.

The swap parameter is a per-column table: a gradient of p from the
left-edge value to the right-edge value, each 0 to 1 (defaults 0 and 1),
mapped to the rate 2 p (1 − p) column by column, sampled at pixel centres
(column x is at t = (x + 0.5) / W of the way) so the first column is not
frozen at exactly 0; a pair uses its first pixel's column. The position is
shaped by the "Gradient power" slider: t is taken to u = 2t − 1 in
[−1, 1], |u| raised to the power and the sign put back (`Band.shape`), so
below 1 (0.2 by default; the slider runs 0 to 1) the gradient is steep at
the centre and flat towards the edges, more of the lattice sitting near the
edge values; 1 is linear and 0 two flat halves. `Band.gradient` builds the table, shared with the tests; the
smoothing gradient along y stays linear. The kernel
walks only the bit positions where the two pixels differ (`$pair`), uses a
branchless 128-bit rotate for the context (`$ctx`), and skips hashing
entirely at p = 0 and p = 1.

## Mutation

The last step of a turn flips bits at random (`mutate`). The control is a
percentage of all bits per turn, 0 by default (mutation off); at 0.001 %,
with 128 bits a cell, it is an expected 0.00128 flips per cell, about 335 flipped bits a turn on
a 512 × 512 grid, one every 50 turns in a given cell. The kernel takes the
expected flips per cell λ in 32.32 fixed point and gives every cell
floor(λ) flips plus one more with probability frac(λ), each at a bit
position drawn from the hash of the turn's salt and the cell's global
index, so a band of rows in a worker produces exactly the flips the whole
grid would. Two flips on the same bit cancel. Mutation is salted by the
turn number, or the same bits would flip every turn. The statistics panel counts the flips.

## The swap order

The four phases run once each per turn, always in the same order:
UD0, LR0, UD1, LR1 (`Band.order`), so every pixel exchanges once with each
neighbour and left–right and up–down alternate.

A phase pairs the pixels of a row or column as bricks, (0, 1), (2, 3), …
at offset 0 and (1, 2), (3, 4), … at offset 1, and on a plane with edges
that leaves pixels out: the left column in LR1 and, when the width is even,
the right column as well, and likewise the top and bottom rows in UD1 (for
odd sizes it is LR0 and UD0 that leave the far edge out). Those pixels pair
along their edge instead, up and down in a left–right phase and left and
right in an up–down phase, as bricks with an offset of their own that
alternates with the turn parity (the `alt` argument of `mix_zone`,
`Band.edgeParity`). Every pixel then takes part in four exchanges a turn;
a corner, which has only two neighbours, takes part in three, because the
two directions use opposite offsets so that the corner's extra exchange
comes once a turn rather than twice every other turn. In the band pipeline
an edge column's vertical pairs consume halo rows exactly like an up-down
phase, and the fixed order keeps that to two rows per side. An earlier version cycled
through the 8 LR/UD-alternating orders with the turn counter, chosen so that
consecutive orders differed as much as possible. The order matters for the
small structures: with the fixed order the specks that live in the frozen
floor mostly stand still and blink, while the cycle made them wander (about
four times as many moving specks, moving on most turns). The page shows the
order in the statistics panel.

## Entropy decrease through median filtering

A pass works on each of the 128 bit planes separately and is computed
synchronously into a scratch buffer. For every pixel and bit position where
the bit disagrees with the majority of its neighbourhood, the pixel's 32-bit
context of that position is hashed; if the hash is below the smoothing
threshold, the bit takes the majority value. At p = 1 every disagreeing bit
is replaced each pass.

The neighbourhood is selectable: the pixel and its four 4-connected
neighbours (5 votes, majority at 3), the 3 × 3 block (9 votes, 5; the
default) or the 5 × 5, 7 × 7, 9 × 9 or 11 × 11 block (25, 49, 81 or 121
votes, a majority at 13, 25, 41 or 61; the kernel counts the votes in a
7-bit bit-sliced counter and compares it with the majority from the top bit
down). Coordinates are clamped to the grid, so at an
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
cross and 3 × 3 neighbourhoods, r per pass for the (2r + 1) × (2r + 1) blocks, rounded up to even)
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

Rendering is threaded the same way. Each band renders its own rows and
runs the render buffer and the sharpening on them (see
[rendering.md](rendering.md)): the main thread sends three neighbour rows
from each side with the render message, taken from the edge rows the bands
return after every turn, because the first blend stage's flatness test
reads one row beyond a pixel, the second stage's reads the first stage's
output one row beyond, and the sharpening reads the second stage's output
one row beyond. `test/band.test.mjs` checks that a band's rows come out
bit-identical to a whole-frame run over a sequence of frames.

Changing the thread count, the pass count or the neighbourhood rebuilds the
worker pool but carries the lattice over bit for bit: the old engine's cells
are read out, the new one is seeded with them, and the turn counter keeps
running; only a new grid size starts over. Shared-memory wasm threads are
not used because they need cross-origin isolation, which `file://` pages do
not have.

## Exports

`mix`, `mix_from`, `mix_zone`, `smooth`, `smooth_zone`, `mutate`, `bits`,
`hist`, `randomize`, and `memory`.
