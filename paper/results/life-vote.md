# A synchronous neighbour vote instead of the swap phases

2026-10-20. The author proposed replacing the four swap phases by one
synchronous rule on the 4-connected neighbourhood of every bit plane: three
or four neighbours set makes the bit 1, none or one makes it 0, two leaves
it, computed once a turn and written only to the local pixel, as in
Conway's game of life.

**That rule is the lattice's existing 4-connected median.** The settling
stage's "4-connected (5 votes)" neighbourhood takes the majority of the
four neighbours and the centre; with five votes the centre decides exactly
the 2–2 split, so the outcome is the proposed rule bit for bit. Every
median pass reads the previous state and writes only the local pixel
(`smooth_zone` goes from one buffer to another), so one pass a turn at
p = 1 is the synchronous Life-style step. What is new is running it
without the swaps. The page has it as the preset "Life-like: one
synchronous 4-neighbour vote a turn, no swaps" (Mixing off, 4-connected,
1 pass, median p = 1 everywhere).

Measured with `ablation.mjs cond=-SR nbr=0 passes=1` (256², 400 turns,
quenched, seeds 1 to 3, `paper/data/design/life/`):

| stages | dictionary | median p | C(1) | C(8) x / y | ξx / ξy | d1 | distinct cells |
|---|---|---|---|---|---|---|---|
| vote + decoder | F | 1 | 0.846 | 0.497 / 0.499 | 7.7 / 11.7 | 0.377 | 0.01 % |
| vote + decoder | F | 0.5 | 0.848 | 0.513 / 0.517 | 64 / 64 | 0.383 | 0.01 % |
| vote + decoder | 20 Gray 8-cycles | 1 | 0.884 | 0.732 / 0.729 | 64 / 64 | 0.019 | 0.84 % |
| vote + decoder | 20 Gray 8-cycles | 0.5 | 0.877 | 0.698 / 0.699 | 64 / 64 | 0.023 | 1.74 % |
| swaps (rotating) + vote + decoder | F | 1 | 0.990 | 0.973 / 0.970 | 64 / 64 | 0.354 | 1.57 % |

Three things follow. The synchronous vote is isotropic as it should be:
C(8) along x and y agree to 0.004 in every row, against the 0.055 gap of
the fixed swap order (`swap-order.md`). But the vote alone does not
synchronise F: every cell sits on the 3-cycle (d1 0.38, a handful of
distinct cells), yet the phases stay uncorrelated beyond about eight cells
(C(8) ≈ ½, the value two independent phases give), so the field is a
phase-random oscillator mosaic; with the swaps the same system is one
phase across the bulk (C(8) 0.97). The designed twenty-cycle dictionary
does order under the vote alone (C(8) 0.73, 1 % distinct cells), because
its states share many planes and a plane-wise majority can pull a cell onto
a neighbour's phase. So the swaps are not only a source of noise: for F
they are what carries phase information between cells, which the median
cannot do when the cycle states differ in most planes. A Life-like rule
is a cleaner model to write about, and the designed dictionaries are the
ones it works with.
