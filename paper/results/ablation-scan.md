# Results: the median-probability scan and the cycle null models

2026-10-18. Batches `paper/experiments/ablation-scan.sh` (330 runs) and
`ablation-cycle.sh` (100 runs), tables in `paper/data/ablation/summary-final.md`.
Swap p = 0.5 (rate ½), 256 × 256, 1,000 turns, seeds 1 to 5, means with the
10th to 90th percentile band. The scan was added after the main batch
(declared in `PLAN_AMENDMENTS.md` section 5), with the prediction that the
gradient frame's "granular sky" and "domains below" are two phases along the
median axis with a transition between p = 0.02 and 0.3 where ξ is finite and
larger than 4 cells.

## 1. Two phases of the three-stage lattice along the median probability

| median p | hashing | d1 | ξx | C(1) | byte H | distinct cells |
|---|---|---|---|---|---|---|
| 0.02 | quenched | 0.331 | 0.5 | 0.35 | 4.65 | 97 % |
| 0.05 | quenched | 0.328 | 0.5 | 0.36 | 4.59 | 97 % |
| 0.1 | quenched | 0.322 | 0.5 | 0.38 | 4.44 | 96 % |
| 0.2 | quenched | 0.311 | 0.5 | 0.44 | 4.07 | 93 % |
| 0.3 | quenched | 0.308 | 1.13 [1.07, 1.19] | 0.51 | 3.65 | 87 % |
| 0.3 | annealed | 0.382 | 57.6 [49.6, 64] | 0.92 | 2.14 | 13.5 % |
| 0.5 | quenched | 0.316 | 64 | 0.99 | 1.87 | 1.7 % |
| 1 | quenched | 0.357 | 39.8 [19.5, 64] | 0.96 | 1.47 | 0.27 % |
| 1 | annealed | 0.409 | 62.5 | 0.98 | 1.53 | 0.28 % |

Below median p ≈ 0.3 the lattice is **granular**: no spatial correlation at
all (ξ = 0.5, C(1) ≈ 0.35, the value two independent oscillator phases give),
and 93 to 97 % of the cells distinct. That last number is the mechanism:
with the swaps exchanging bits at rate ½ with neighbours in other phases,
and the decoder needing about ten turns to pull a disturbed cell back onto
its cycle (`decoder-cycles.md`: transient mean 9.6, 90th percentile 15), the
cells are almost all in transients at any time; the field is a soup of
relaxing cells, and the median is too weak to synchronise phases. Above
p ≈ 0.3 (annealed) or between 0.3 and 0.5 (quenched) the lattice is
**ordered**: one phase across the bulk, with the only exception the pinned
multi-domain state at p = 1 under quenched hashing (`ablation-main.md`). The
transition is sharp on this grid of points and sits in a different place for
the two hashings. The prediction of a regime with finite, un-pinned ξ larger
than 4 cells was **not met at any of the five points**: ξ jumps from about 1
to the measurement cap. If a critical regime exists it is narrower than the
0.1 spacing of the scan (locating it needs points between 0.3 and 0.5, and
system-size scaling at the transition).

The two-stage control (MS−) at the same points coarsens slowly and never
freezes: ξ 19.6 to 23.1 quenched, 24.3 to 27.9 annealed, d1 0.04 to 0.11
quenched; the quenched pinning of the main batch is specific to the
deterministic median at p = 1.

## 2. The null models along the scan

| map | median p 0.02 to 0.2 (quenched) | p 0.3 | p 0.5 | p 1 |
|---|---|---|---|---|
| decoder | ξ 0.5, d1 0.31–0.33, 93–97 % distinct | ξ 1.1 | ξ 64, one phase | ξ 40 [19, 64] pinned |
| `hash:93` | ξ 11–13 and growing, d1 0.16–0.22 | ξ 12.8 | ξ 13.3 | frozen, ξ 3.7 |
| `hashdict:93` | ξ 24–28 and growing, d1 0.08–0.13 | ξ 24.0 | ξ 24.7 | frozen, ξ 6.8 |
| `cycle3` (three random states) | ξ 0.5, d1 0.33, 3 states | — | ξ 0.5 | ξ 64, d1 0.53 |
| `cycle3f` (the decoder's three states) | ξ 64, d1 0.24–0.27, 3 states | — | ξ 64 | ξ 64, d1 0.50 |

- The two **hash maps** are idempotent and so never oscillate; with them the
  lattice coarsens like the two-stage control with a hashed alphabet
  (`hashdict:93`, with the dictionary's byte histogram, coarsens about twice
  as far as `hash:93` with uniform bytes, since its planes are mostly
  constant). They are not matched to the decoder in any regime and are
  dropped as nulls for this system.
- **`cycle3f`**, the decoder's own three states with instantaneous collapse
  onto the cycle, orders completely at every median probability down to
  0.05, where the decoder itself is granular. **`cycle3`**, three random
  states with the same rule, stays granular up to p = 0.5 and orders only at
  p = 1. So the pre-registered rule for the cycle nulls gives: the attractor
  alone does not reproduce the lattice (`cycle3f` fails at p ≤ 0.3), and
  neither does the alphabet-free version. Two properties of the decoder
  matter and pull in opposite directions: **its gradual contraction** (the
  ten-turn transient, which keeps the field granular under strong mixing and
  weak median, where the instant-collapse null orders) and **the geometry of
  its cycle states**. The three states of F's cycle are
  `AAAAAPPAPPP(((((`, `((\x10\x14((PPPPPPAAAA` and `(((((((((((AAAAA` (three
  dictionary words in rotating arrangement), 45, 29 and 64 bits apart, with
  59 of the 128 bit planes identical in all three; the random states of
  `cycle3` are about 64 bits apart with no shared planes. On the 59 shared
  planes nothing the swaps or the median do can disturb an on-cycle cell, so
  a cycle with close, plane-sharing states is far easier to synchronise than
  a random one, and that is what the dictionary search found.

## 3. What the scan does to the plan

- Claim 2 of the plan ("every frame is a two-parameter phase diagram") is
  true in the plain sense that the gradient frame crosses a sharp transition
  between a granular and an ordered phase along the median axis; the
  transition's position depends on the hashing, and nothing in the scan
  shows a critical regime with its own finite length. The interesting
  pictures live at the front, which the gradient frame renders as a line
  across the lattice; a homogeneous system sits on one side or the other.
- The physics paper's measurable content is now: (i) the attractor census
  of the decoder as the dictionary-dependent quantity; (ii) the hash-pinned
  freezing of the quenched majority dynamics against t^⅓ coarsening when
  annealed; (iii) the granular-to-ordered transition of a lattice of
  relaxing 3-cycle oscillators under crossover noise, with the relaxation
  time (the decoder's transient) as the parameter that the instant-collapse
  null lacks. (iii) is the only one of the three that is about the decoder
  as a lattice rule, and it needs the transition located (median p between
  0.3 and 0.5, three system sizes) before it can be stated with a number.
