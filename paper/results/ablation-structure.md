# Results: dictionary structure at the lattice level, and the scaling check

2026-10-18. Batch `paper/experiments/ablation-extra.sh` (62 runs), tables in
`paper/data/ablation/summary-final.md`; the attractor census of the controls
by `DICTS=... node paper/experiments/decoder-cycles.mjs 5000` in
`paper/data/decoder-map/cycles-ca_swarm_f_*.md`. Reference condition: all
three stages, swap p = 0.5, median p = 1, quenched hashing, 256 × 256, 1,000
turns, ten seeds; means with the 10th to 90th percentile band.

## 1. F against its shuffles (the pre-registered Q3 test)

| dictionary | decoder attractors (5,000 cells) | d1 at 1,000 | ξx at 1,000 | byte H | distinct cells |
|---|---|---|---|---|---|
| F raw | one 3-cycle, transient 9 | 0.357 [0.347, 0.371] | 39.8 [19.5, 64] | 1.47 | 0.27 % |
| F word-shuffled | one 3-cycle, transient 10 | 0.416 [0.414, 0.417] | 64 [64, 64] | 1.37 | 0.15 % |
| F reversed | 3-cycle (98 %) and an 8-cycle | 0.318 [0.302, 0.338] | 64 [64, 64] (ξy 59.5 [49, 64]) | 1.31 | 0.07 % |
| F byte-shuffled 1 | one 29-cycle, transient 22 | 0.445 [0.445, 0.448] | 64 [64, 64] | 2.55 | 0.10 % |
| F byte-shuffled 2 | a 23-cycle (99.7 %), a 5- and a 10-cycle | 0.454 [0.433, 0.472] | 54.3 [40, 64] | 3.12 | 2.2 % |
| F byte-shuffled 3 | a 10-cycle (58 %), a 38-cycle (28 %), a 19-cycle (14 %) | 0.531 [0.530, 0.531] | 64 [64, 64] | 1.67 | 0.03 % |

Under the pre-registered rule the structure claim is **not** retracted: every
control's d1 lies outside the raw dictionary's seed band, and so does the
byte entropy. But the reason is now plain and it is not the one the plan had
in mind. The decoder's attractor is a property of the dictionary's byte order:
shuffling the bytes turns F's single 3-cycle into a 29-cycle, a 23-cycle or
three competing cycles of 10, 19 and 38 turns, and the lattice's d1, which is
the Hamming distance per step along the cycle, follows. The first-order
statistics of the decoder as a map (`results/decoder-map.md`) were blind to
this; the attractor census is not. Shuffling the words keeps the 3-cycle (the
cycle's states are built from the dictionary's words, so the words, not their
order, fix the period) but changes its states and so d1. Reversal keeps the
3-cycle for 98 % of cells and adds an 8-cycle.

On ξ the test is not decisive: the raw dictionary's seed band spans 19.5 to
64 and five of six controls sit at the 64 cap (one phase domain across the
bulk), so the raw F is the only one of the six whose phase field stays
pinned in several domains; with the band this wide, the comparison needs
either more seeds or the measurement at equal cycle phase and beyond 64
cells (section 3 of `ablation-main.md`). The claim the paper can make from
this batch is the exact one: **the dictionary's byte order sets the
decoder's cycle, and the lattice inherits the cycle.** Whether it also sets
the pinned domain length is open.

## 2. Scaling check (three seeds, swap p = 0.5, median p = 1, quenched)

| condition | 128 (margin 16) | 256 (margin 32) | 512 (margin 64) |
|---|---|---|---|
| MS− ξx at 1,000 | 5.59 [5.58, 5.61] | 5.60 [5.57, 5.64] | 5.62 [5.60, 5.64] |
| MS− d1 at 1,000 | 2.5 × 10⁻⁵ | 2.6 × 10⁻⁵ | 2.5 × 10⁻⁵ |
| MSR ξx at 1,000 | 22.3 [19.4, 25.0] | 39.8 [19.5, 64] (ten seeds) | 32.1 [24.7, 39.0] |
| MSR ξy at 1,000 | 18.6 [17.3, 19.7] | 41.9 [21.8, 64] | 41.2 [29.0, 57.4] |
| MSR d1 at 1,000 | 0.370 | 0.357 | 0.359 |

The pinned length of the two-stage system (MS−) is independent of the
system size to 1 %: it is an intrinsic length of the quenched majority
dynamics at this exchange rate. The three-stage phase-domain length is not
yet measured well enough to say: at 128 cells the bulk is 96 cells wide and
ξ is cut off by the system; 256 and 512 agree within 20 % on the mean with
overlapping bands. The per-plan rule (move the figures to 512 if ξ changes
by more than 20 % between 256 and 512) is not triggered, but the bands say
the 256 × 256 measurement of ξ for MSR needs more seeds or a longer
correlation range before any number is printed.
