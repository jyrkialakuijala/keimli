# Results: the ablation matrix with uniform parameters (Q1 / H1), main batch

2026-10-18. Runner `paper/experiments/ablation.mjs`, batch `ablation-all.sh`
(700 runs: 256 × 256 bounded plane, bulk margin 32, 1,000 turns, seeds 1 to
10, dictionary `ca-swarm-f`, header range 4096, 6 skipped bits), tables by
`ablation-summary.mjs` in `paper/data/ablation/summary-final.md`,
`series.csv`, `curves.csv`. The protocol and decision rules are in
`paper/PLAN_AMENDMENTS.md` section 3. Statistics below are means over ten
seeds with the 10th to 90th percentile band in brackets; ξ is the length at
which the mean Hamming correlation C(r) over the 16 byte groups crosses ½,
capped at the 64-cell measurement range; d1 is the fraction of bulk bits
changed in one turn. Conditions are written M (mixing), S (settling), R
(rewriting), with − for a stage switched off.

## 1. The decoder alone is a 3-cycle oscillator (−−R)

With both bitwise stages off, every cell iterates the decoder on its own. By
turn 50 the bulk holds 4 distinct cell contents out of 36,864 cells (byte
entropy 1.76 bits) and d1 stays at 0.358 for the rest of the run, with C(r)
flat at 0.52 for every r. The attractor census of the decoder map
(`paper/experiments/decoder-cycles.mjs`, `paper/data/decoder-map/cycles.md`,
10,000 random cells each) says why:

| dictionary | attractors reached | cycle lengths (cells) | largest basin | transient mean / p90 / max |
|---|---|---|---|---|
| Swarm F (reference) | 1 | 3 (10,000) | 100 % | 9.6 / 15 / 35 |
| Swarm A | 3 | 1 (23), 6 (9,483), 8 (494) | 94.8 % | 7.4 / 14 / 30 |
| Swarm D | 4 | 1 (76), 3 (9,392), 12 (532) | 93.9 % | 18.0 / 40 / 71 |
| Brotli 13 | 4 | 1 (295), 9 (9,324), 18 (381) | 93.2 % | 24.5 / 46 / 75 |
| Brotli 9 | 2 | 1 (5), 14 (9,995) | 100 % | 13.8 / 25 / 56 |
| Brotli 1 | 6 | 2 (7,751), 3 (1), 4 (900), 15 (1,348) | 77.5 % | 25.7 / 50 / 92 |
| Declaration | 7 | 3, 6, 9, 22, 67, 154 (1,687), 182 (8,077) | 80.8 % | 89.4 / 198 / 431 |
| Don Quijote | 4 | 2, 4, 55 (6,280), 64 (3,718) | 62.8 % | 82.4 / 145 / 273 |
| Kalevala 1 | 55 | 3 to 303; 303 (6,468), 77 (2,762) | 64.7 % | 209 / 418 / 670 |

**Every random 128-bit cell decoded against F ends on the same 3-cycle within
35 turns.** The searched dictionaries all have one dominant short cycle (3 to
14 turns) with a basin above 77 %, and transients of 10 to 25 turns; the texts
have long cycles (55 to 303 turns), several attractors and transients of 80
to 200 turns. So the dictionary search, scoring "modes over space and time",
selected dictionaries whose decoder is a short global oscillator. This was
not known before today and it reorganises the mechanism: with the reference
dictionary, the lattice is a medium of 3-phase oscillators, and what the
mixing and the median act on is the phase field. The d1 of 0.36 is the
Hamming distance between consecutive states of the cycle, 128 × 0.36 ≈ 46
bits, and it is present with no spatial interaction at all.

Consequence for claim 1: "sustained dynamics" is not a lattice phenomenon
and cannot be claimed as one. The lattice phenomenon, if any, is the spatial
organisation of the phases.

## 2. Freezing, coarsening and hash pinning without the decoder (MS−, −S−, M−−)

| condition | p swap (rate) | p median | hashing | d1 at 1,000 | ξx at 100 / 400 / 1,000 |
|---|---|---|---|---|---|
| MS− | 0.5 (0.50) | 1 | quenched | 2.6 × 10⁻⁵ | 5.60 / 5.60 / 5.60 |
| MS− | 0.5 (0.50) | 1 | annealed | 5.4 × 10⁻⁴ | 9.39 / 15.5 / 19.9 |
| MS− | 0.2 (0.32) | 1 | quenched | 8.7 × 10⁻⁶ | 4.69 / 4.69 / 4.69 |
| MS− | 0.2 (0.32) | 1 | annealed | 5.1 × 10⁻⁴ | 8.56 / 13.9 / 18.3 |
| MS− | 0.05 (0.095) | 1 | quenched | 2 × 10⁻⁸ | 3.15 / 3.15 / 3.15 |
| MS− | 0.05 (0.095) | 1 | annealed | 4.0 × 10⁻⁴ | 6.50 / 10.5 / 14.7 |
| MS− | 0.5 (0.50) | 0.5 | quenched | 0.023 | 9.39 / 15.1 / 19.8 |
| MS− | 0.5 (0.50) | 0.5 | annealed | 1.9 × 10⁻³ | 10.8 / 19.2 / 26.8 |
| −S− | — | 1 | either | 2.7 × 10⁻⁵ | 2.28 frozen from turn 10 |
| −S− | — | 0.5 | quenched | 0 | 1.60 frozen |
| M−− | 0.5 (0.50) | — | either | 0.474 | 0.5 (C(1) ≈ 0, noise) |

The seed bands on these numbers are narrow (ξ within ±2 % at turn 1,000).

- **The median alone freezes at once** (ξ ≈ 2.3 cells by turn 10, Vichniac's
  blocked states), with or without annealing; at p = ½ under quenched hashing
  it freezes completely (d1 = 0), because a hashed decision with salt 0 is a
  deterministic rule of the neighbourhood.
- **Mixing plus the deterministic median under quenched hashing freezes** by
  turn 100 at ξ of 3 to 6 cells, the length growing with the exchange rate.
  **The same system under annealed hashing never freezes**: ξ grows as about
  t^0.33 (9.4 → 19.9 between turns 100 and 1,000 at rate ½, exponents 0.33,
  0.33 and 0.35 at the three rates) and d1 decays as about t^−0.6. This is
  the pinning the retired professor predicted: quenched randomness in the
  swap decisions pins the interfaces of the majority dynamics. At median
  p = ½ the quenched system coarsens too (ξ 9.4 → 19.8, d1 0.023), so the
  pinning needs the deterministic median together with the quenched swaps.
- The growth exponent of ⅓ rather than Allen–Cahn's ½ is consistent with the
  conserved (Kawasaki-like) character of the swaps per bit plane, as the
  editors anticipated; it is read off one decade at one system size and is
  a band, not a value, until the scaling check (queued) is in.

## 3. All three stages (MSR): phase domains pinned by the hash, or none

| p swap (rate) | p median | hashing | d1 at 1,000 | ξx at 1,000 | distinct cells | byte H | plane |m| |
|---|---|---|---|---|---|---|---|
| 0.5 (0.50) | 1 | quenched | 0.357 [0.347, 0.371] | 39.8 [19.5, 64] | 0.27 % | 1.47 | 0.54 |
| 0.5 (0.50) | 1 | annealed | 0.409 [0.375, 0.459] | 62.5 [62.5, 64] | 0.28 % | 1.53 | 0.68 |
| 0.2 (0.32) | 1 | quenched | 0.362 [0.348, 0.376] | 28.9 [17.0, 37.5] | 0.75 % | 1.56 | 0.53 |
| 0.2 (0.32) | 1 | annealed | 0.416 [0.367, 0.446] | 63.8 [63.8, 64] | 0.23 % | 1.54 | 0.69 |
| 0.05 (0.095) | 1 | quenched | 0.365 [0.357, 0.370] | 17.3 [11.7, 24.8] | 0.93 % | 1.64 | 0.53 |
| 0.05 (0.095) | 1 | annealed | 0.406 [0.368, 0.436] | 60.9 [56.8, 64] | 0.23 % | 1.55 | 0.67 |
| 0.5 (0.50) | 0.5 | quenched | 0.316 [0.252, 0.352] | 64 | 1.7 % | 1.87 | 0.89 |
| 0.2 (0.32) | 0.5 | quenched | 0.299 [0.263, 0.339] | 64 | 2.9 % | 1.76 | 0.77 |
| 0.05 (0.095) | 0.5 | quenched | 0.319 [0.279, 0.343] | 63.4 | 3.3 % | 1.63 | 0.68 |

In every three-stage run the bulk is within a few per cent of a single cell
content per phase (distinct cells below 3.3 %, byte entropy 1.5 to 1.9 bits),
and d1 is the oscillator's 0.3 to 0.4. The spatial structure is in the
phase field:

- With the deterministic median and **quenched** hashing, ξ is finite and
  stationary: at rate ½ it is 39.9 at turn 400 and 39.8 at turn 1,000 (the
  samples compared are 600 turns apart at the same cycle phase, since 400 ≡
  1,000 mod 3), 28.3 → 28.9 at rate 0.32, 17.2 → 17.3 at rate 0.095. The
  phase domains are arrested, their size growing with the mixing rate, and the
  seed bands are wide (ξ from 12 to 64 across seeds at rate ½).
- With **annealed** hashing the same system goes to a single phase: ξ runs to
  the measurement limit (52.9 at turn 400, 62.5 at 1,000 at rate ½; 60.6 →
  60.9 at rate 0.095) and the bulk is one domain.
- At median p = ½ both hashings give one domain (ξ at the cap) by turn 50.

**Decision under the pre-registered rules.** The quenched and annealed MSR
runs disagree on ξ beyond the seed bands at rates 0.32 and 0.095 (28.9
[17, 37.5] against 63.8 [63.8, 64]; 17.3 [11.7, 24.8] against 60.9 [56.8,
64]), so **the arrest of domain growth in the reference system is hash
pinning, not an effect of the decoder**, and the "scale set by the
dictionary" half of H1 is retracted at these parameters. What the decoder
adds is the oscillation and the collapse of the cell alphabet onto its
3-cycle; the median and the quenched swaps then do to the phase field what
they do to any bit field, freeze it. The queued median-probability scan
(0.02 to 0.3) will say whether a regime with finite, un-pinned structure
exists, which the gradient frames suggest near the top of the picture.

A measurement note: because the whole bulk cycles with period 3, C(r) and ξ
depend on the phase at which the frame is sampled (at rate ½ the samples at
turns 200, 600 and 800, all ≡ 2 mod 3, give ξ = 64 while 400 and 1,000 give
40). Comparisons must be made at equal phase, or on three consecutive turns.

## 4. The hash null models do not reproduce the decoder, for a reason

`hash:93` and `hash:64` (keep the first K bits, hash them into the rest;
image 2^K) are idempotent: a cell that has been rewritten once is a fixed
point of the map. They therefore have no oscillation and the lattice with
them behaves as MS− with a hashed alphabet: at median p = 1 they freeze
(d1 3.6 × 10⁻⁴, ξ 3.7 quenched; coarsening ξ 12.6 and growing when
annealed), at p = ½ they coarsen slowly (ξ 13 at turn 1,000, d1 0.12), and
`hash:64` leaves the 64 hashed planes spatially uncorrelated (C(1) ≈ 0.47).
The right null for the reference system is not "a map of matched image
size" but **a map with the decoder's attractor structure**, a single short
cycle reached by every cell, with and without the dictionary's alphabet and
with and without the decoder's gradual (10-turn) contraction. Two such nulls
(`cycle3`, three random states; `cycle3f`, the decoder's own three states)
are implemented in the runner and queued after the scan.

## 5. Mixing plus decoder (M−R) and settling plus decoder (−SR)

Without the median the oscillator phases stay spatially random (M−R: ξ = 0.5,
C(1) = 0.35, 97 % distinct cells, d1 0.33, independent of the hashing): the
swaps exchange bits between cells in different phases and the decoder pulls
each back onto the cycle, so the field is a phase noise. Without the mixing
(−SR) the median alone organises the phases into domains with the widest
seed variation of the batch (ξ 20 [8.7, 26.8] at p = 1, identical under both
hashings since a p = 1 median does not hash); the median does the ordering,
the mixing only sets the pinned length.

## 6. What this does to the plan

- H1 is restated: the control (MS−) does not coarsen as t^½ and go quiet; it
  freezes under the page's quenched hashing and coarsens as about t^⅓ when
  annealed. The reference system does not arrest coarsening by the decoder;
  it is pinned by the hashing. The decoder's contribution is to make every
  cell an oscillator with a dictionary-determined period and basin structure.
- The single most important new measurement for the paper is the attractor
  census of the decoder per dictionary (section 1), which is exact,
  dictionary-specific and cheap; the "regimes" of the gallery should be
  re-read as oscillator media with different periods and basins, and the
  dictionary search as having selected for one short global cycle.
- The page's default should be reconsidered for the paper: the quenched
  hashing makes the lattice a deterministic CA, as the docs say, but it also
  makes the pictures hash-pinned; the article should show both hashings.
- Pending: the median-probability scan, the dictionary-structure test (F
  against its shuffles at the lattice level), the scaling check and the
  cycle null models, all queued in `paper/data/ablation/`.
