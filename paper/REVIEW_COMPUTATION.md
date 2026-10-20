# Review of the computational approach

2026-10-20. A read of `docs/lattice.md`, `docs/changers.md`,
`src/lattice/lattice.wat`, `src/lattice/band.js`, `src/changers/decode.wat`,
`src/changers/codec.js`, the page's two engines and the two test suites,
with the checks run while reading. Findings first, in order of weight.

## 1. Two defects found and fixed

**The pair-write mask defaulted to "write nothing".** The parameter block's
new entry at offset 116 (which cells of a pair take the decoded joint cell)
was initialised to 0 by `Codec.install`. The band pipeline and the page
always set it, so the page looked right, but every direct caller of
`change` (both test suites, the design tools that call the module without
the band layer) rewrote no cell in any pair mode: 13 failures in
`test/mix.test.mjs` and 6 in `test/band.test.mjs`. The default is now 3
(both cells) and both suites pass.

**The single-thread engine is a second implementation of the turn.** The
page's in-page engine (Threads = 1) does not call `Band.runTurn`; it has
its own copy of the turn loop. Today that copy missed the synchronous
mixing rule (fixed earlier) and the pair-write mask (fixed now): with one
thread the "rewrite to A / B cell" boxes had no effect while on workers
they did. The band test cannot see this, because it compares the band
pipeline with the module's whole-grid functions, not with the page's
engine; the page self-test only checks that turns advance. Recommendation:
make the in-page engine one band (`y0 = 0, rows = H`) driven by
`Band.runTurn`, so there is one turn implementation, or add a parity check
to the self-test that runs the same seed on 1 and 4 threads and compares
cells. Until then every new turn-level option must be added in both
places.

`test/band.test.mjs` now also covers the vote partner (modes 9 and 10) and
the synchronous mixing, all bit-identical across bands.

## 2. The rule is a composition, and its order matters

A turn is snapshot, four swap phases applied in sequence to the live map
(decisions from the snapshot, exchanges only where the live bits still
differ), then the median passes, then the rewrite. The sequential
application makes the result depend on the phase order: with the fixed
order UD0 LR0 UD1 LR1 the lateral exchanges act last before the settling
and the correlation length came out 1.37 times longer along y than along x
(`results/swap-order.md`). The rotating order equalises this to within 4 %
and gives the most ordered lattice. For the article the rule should be
stated as this composition, with the 4-turn period of the rotating order,
not as "a crossover with each neighbour".

The synchronous alternative (`mix_sync_zone`) removes the order dependence
and is isotropic to the third decimal, but it is a copy rule, not an
exchange, and it orders much less (`results/life-vote.md`). The swaps'
pairwise convergence is doing real work; that is a result, not a flaw.

## 3. The randomness is quenched in the configuration

Every swap and median decision is a hash of the 32-bit context(s) at the
position, with salt 0 by default. The lattice is therefore a deterministic
cellular automaton on 128-bit cells, and "p" is the fraction of context
pairs whose hash falls under the threshold, not a probability drawn each
time. Two consequences the text should state plainly: identical contexts
decide identically, so a boundary between two uniform regions is
all-or-nothing position by position; and in an ordered field the realised
rate is a property of the few contexts that occur there. I measured the
second on Swarm F at p = ½ after 300 turns: 2.4 differing bits per
horizontal pair and 1.50 bits exchanged per cell-turn under the quenched
hash, against 1.2 and 0.82 annealed (salt by turn). The realised rate per
differing bit is about the nominal one in both, so the quenched hash does
not freeze the ordered state; but the two salts give different fields, and
the article's claims should say which one they are about (the pre-registered
runs are quenched).

## 4. The median

The settling is a synchronous per-plane majority, computed from the
previous state into a scratch buffer and copied back: the Life-style step
the author asked for is this kernel with the 4-connected neighbourhood at
one pass (`results/life-vote.md`). Coordinates are clamped, so an edge
pixel votes for itself in place of each missing neighbour: edges are more
persistent than the interior, and a corner with the cross has three votes
of its own out of five and never changes under the median. A synchronous
majority with 5 votes turns a checkerboard plane into a period-2 blinker on
an infinite lattice; on the bounded grid I checked (16 × 16, p = 1) the
clamped corners break it and the plane dies in three passes, so this is
not a live artifact, but the bottom rows (p = 1 by default) are a
deterministic synchronous rule and the article should say so.

## 5. The rewrite, and where the coupling is

In single-cell mode the decoder output is a function of the cell alone:
all spatial coupling is in the mixing and the settling, and the decoder is
a pure map applied in place. Its input is read as a ring (the bit position
wraps at 128, up to the 1024-bit cap), so late commands re-read the
header's bits. Positions are not equally consequential: the header bits
(after the skip) select the window and matter most, the first commands
next, and the tail least; the mixing is uniform over positions. The
designed dictionaries exploit exactly this (one header bit and one tail
parity byte per step). It is a modelling choice worth one sentence: the
genome has a fixed reading frame, unlike a biological one, which is why
"skip bits" exists as a control.

The pair modes make the two cells one 256-bit unit for the rewrite while
the mixing treats them as two cells; the within-pair swap at rate ½
scrambles any joining whose two halves differ, which is why the interleaved
designs are decoder-valid but lattice-dead and the concatenated ones with
identical halves order. The A/B write boxes and the vote partner are the
two ways round this now in the page; neither is in the article's runs.

The vote partner (pair modes 8 + m) reads a snapshot taken before any cell
is rewritten and writes only the cell, so it is synchronous and isotropic.
The tie at two set neighbours goes to the cell's own bit (the author named
only the other counts); with "2 → 1" the vote would be biased to 1 on a
random plane (11/16). Verified bit for bit against a JavaScript reference
in all five joinings and both roles.

## 6. The band pipeline

The halo accounting is sound: each up-down phase or leftover-column pass
consumes one halo row per side, each median pass R rows, the depth is kept
even for the brick parity, and the vote partner now has two spare rows
(`depthFor` is 4 + n + (n & 1)). Pairs across band edges are computed by
both neighbours, deterministically. The band test checks bit-identity and
the counts for 16 configurations. The cost of the larger depth is two more
halo rows per band, negligible, and small grids admit fewer bands
(`Band.split` needs rows ≥ D).

## 7. Smaller points

- A left-right pair uses its left pixel's column threshold: the mixing
  gradient is shifted by half a pixel for the right pixel. Negligible.
- `mix_sync_px` walks all 128 positions and loads four neighbours each,
  so it costs two to three times a swap phase; an early-out on the OR of
  the four xors would remove most of that. It also adds the salt twice
  (once inside the pair key, once on the fresh hash); harmless.
- Thresholds carry 32 bits of the probability; p = 0 and 1 are exact and
  skip the hashing.
- The LZ decoder's `peek` for single cells wraps at 128 bits while the
  32-byte joint cell uses `peekm`; both are covered by the reference tests.
- The page's `#selftest` checks liveness only. Running
  `node test/mix.test.mjs` and `node test/band.test.mjs` before a push is
  what catches the kind of defect found today; the push procedure should
  include them.
