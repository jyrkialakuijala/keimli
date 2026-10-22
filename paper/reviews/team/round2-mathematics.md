# Round 2 — mathematics: methodology

Scripts and outputs are in my scratchpad (`decay.mjs`, `top.mjs`, `fp.mjs`, `funnel.mjs`, `ff.mjs`, `hdfs.mjs`, `knuth.mjs`). Each one imports `paper/experiments/decode36.mjs` and `dict-variants.mjs` read-only. Every run took under 2 minutes, and nothing was written to the repository except this file.

## (a) Responses to the other panelists

**Professor: the iterated, coupled decoder is itself a CA that may compute.** I agree, and I would put it more strongly. Any map on a finite set is "fixed-depth". So is a Z80 run for a fixed number of instructions: as the ALife reviewer asked, both arms are finite maps on 2^128 per turn. The decoder/processor contrast therefore cannot be "computes vs does not compute" at the level of one turn, and nothing measured here bears on whether the lattice is universal. The difference has to be stated as a *measured* property of the one-turn map. Section (b)1 offers one: how far iteration contracts entropy relative to a random-map null. That is a quantity the processor arm can be measured on too. "Cannot compute" must go. "One turn is an explicitly given, bounded-time map whose iterates collapse far faster than a random map's" can stay.

**Information theorist: the 93.5-bit bound.** I agree it is an upper bound valid at turn 1 only, and their prefix-code proof matches mine. I measured what they bounded. With 2^18 uniform cells and the unbiased collision estimator, **H₂(f(U)) = 16.5 bits for F**. It was 16.8 at 2^15 samples, so it is stable. Their "≲ 25.3" was loose by 9 bits. One atom sets the value: the output "((((((((((((((((" has probability 0.324 %, so H_∞ = 8.3 bits. Values for the other dictionaries: Declaration 28.8 bits, Brotli 13 22.1, F byte-shuffled 21.4, ca-gray3c 14.6 (its three atoms "1…1", "2…2", "3…3" each at about 0.35 %). The matched null `hash:93` has H₂ ≈ 92. For the dynamics, the Shannon bound is the wrong headline. The Rényi entropies and the atoms are what predict the census.

**ALife: the takeover rule amounts to selection.** I agree with the substance and add a structural point. Selection by a scalar fitness requires the pairwise "who wins" relation to be transitive. design-gray3.md's invasion table already has A × C → B 31 %, so a third type wins a contact between two others. The pairwise test for a total order is cheap, and if it fails, the takeover is frequency-dependent dynamics with no fitness ranking. Either result is publishable. "No selection" is wrong in any case. "No fitness function and no copy operation" is right.

I also have a theorem-level reason why fixed points win under strong settling (replicators.md, Brotli 12/13 under the frame). A spatially uniform domain of a fixed point x is a fixed point of the *global* map: exchanges between equal cells and votes among equal cells are no-ops, and f(x) = x. A domain of a k-cycle is invariant only when it is phase-coherent, and a random start produces up to k phase domains separated by walls on which mixing and voting act. Fixed-point species are thus the only species with no internal walls. This is exact and should replace "the majority filter propagates what makes neighbours agree".

**Computation reviewer.** The fixed-order finding invalidates the takeover times. It does not affect the map-level results below, which involve no lattice. Their point 3, that the wrong basin was used, is strengthened by (b)3.

**Physicist: clock versus Potts.** Their suspicion is confirmed exactly. For ca-gray3c the Hamming distances from state 0 along the cycle are **0 2 4 2 4 6 4 2**, which is 2·d_Q₃(g(0), g(k)): the cycle is a Gray 8-cycle embedded in the 3-cube. Distance is not monotone in cyclic phase distance (k = 3 is closer than k = 2, and k = 5 is the farthest), so there is no Z₈ clock symmetry. Drop "clock model".

## (b) Deep dive

**1. Entropy decay under iteration.** Uniform U, 2^18 cells, plug-in H and collision H₂ (in bits) of f^k(U):

| k | F: H / H₂ | F shuffled: H / H₂ | Brotli 13: H / H₂ | Declaration: H / H₂ | gray3c: H / H₂ |
|---|---|---|---|---|---|
| 1 | 17.95 / 16.5 | 17.99 / 21.4 | 17.99 / 22.1 | 18.00 / 28.8 | 17.87 / 14.6 |
| 4 | 13.96 / 7.5 | 16.85 / 12.4 | 15.76 / 10.3 | 17.54 / 15.8 | 7.26 / 4.5 |
| 8 | 6.65 / 3.5 | 12.47 / 7.7 | 10.43 / 7.0 | 16.16 / 13.1 | 4.46 / 4.0 |
| 16 | 2.32 / 1.8 | 7.19 / 5.1 | 6.89 / 5.7 | 14.08 / 11.5 | 4.14 / 3.9 |
| 32 | 1.59 / 1.59 | 5.18 / 4.6 | 4.91 / 4.3 | 12.05 / 10.5 | 4.14 / 3.9 |

The plug-in H is capped at log₂ N = 18. The null is the random mapping on n points. By Flajolet–Odlyzko, the k-th iterate's image has size ≈ 2n/k, so a random map loses only about log₂(k/2) bits after k steps: 4 bits at k = 32, not 90. In a 2^18 sample from 2^128 it would show no coincidence at all before k ≈ 2^64. F reaches log₂ 3 (the 3-cycle) by k ≈ 32. This decay curve, not 93.5 bits, is the quantitative form of "the decoder is tame". The same curve can be measured on the processors.

**2. Fixed points: they exist.** In the sampling search (fp.mjs; 2^18 starts, 80 iterations, verified with decode36), F has at least 4 fixed points and 2 two-cycles (5 and 7 of the 2^18 cells, basins about 2·10⁻⁵). One example is `((\x03K\x03K\x03K\x03K\x1aX\x03K\x1aX`. ca-gray3c, for which design-gray3.md claims "no stray cycle", has a stray fixed point `UUUU@@@@@@@@@@@@` (1 in 2^18 starts).

I also ran an exact search (hdfs.mjs). It treats f(x) = x as a constraint problem: a depth-first search over the bits as the decoder reads them, where each output byte must equal the input byte it overwrites. All solutions were re-verified. With the 12 header bits fixed, each subtree has 4–37 M nodes. Exhaustive results: header 3232 has **44 fixed points**, header 1 has 4, and headers 64, 777, 1999, 2560, 3001 and 4000 have none. So F has **at least 48 fixed points**, exactly verified, clustered in a few windows. A Knuth estimate puts the whole tree at about 2·10⁹ nodes. Full enumeration across the 4,096 headers is about 1–4·10¹¹ node visits: an overnight job in C, after which "F has exactly N fixed points" would be a theorem. The 10⁴-start census misses them because their random basins are below 10⁻⁴. Under the lattice they are not negligible a priori (see 3 and the wall argument above).

**3. Robustness of the funnels.** These are exhaustive over every state of every cycle.

| | 1-bit flips | 2-bit flips (all pairs) | 3-bit flips (random) |
|---|---|---|---|
| gray3c, same species | 94.4 % | 89.6 % | 85.6 % |
| gray3c, return mean / p90 / max | 1.54 / 3 / 10 | 1.99 / 4 / 13 | 2.37 / 5 / 17 |
| gray3c, lands off any cycle | 0 | 0 | 0 |

The 1-bit row reproduces design-gray3.md exactly. The funnel degrades gracefully: about 5 % per extra flipped bit switches species, which is a measurable "mutation matrix" between species. For F, all 24,768 one- and two-bit flips of the 3-cycle return to it except 2, which land on a 2-cycle. **The perturbation basin is not the uniform basin.** States near an attractor (what mixing produces) reach different attractors with different weights than random cells do. The waiting time 1/(Nb) of replicators.md should use the perturbation kernel, not b.

**4. The global map, precisely.** X = A^Λ with A = {0,1}^128 and Λ = [0,W)×[0,H), edges clamped. One turn is
F_t = R ∘ S_θ^m ∘ M_{π(t mod 4), t mod 2},
where:
- M is the four brick-partition exchange phases, with decisions read from the pre-turn snapshot (radius 2).
- S is m synchronous per-plane majority passes, each with radius r, accepted by a hash of the cell's own 32-bit context against the row threshold.
- R is the cellwise f.

Under salt 0 the rule depends on t only through the phase order and edge parity, so the system has **period 4**, and G = F₃F₂F₁F₀ is autonomous. With gradients, G is a *non-uniform* CA. With uniform thresholds and away from edges, G commutes with translations by 2Z × 2Z only, because brick pairings are Margolus partitions. It is therefore a uniform CA on 2×2 blocks (alphabet A⁴) with radius ≤ 4(2 + m·r) in cells.

Two consequences:
- f is not injective, so it is not surjective. Hence G is not surjective, and Gardens of Eden exist trivially (any cell outside Im f). On the infinite lattice G is not pre-injective (Moore–Myhill).
- Every orbit on the finite grid is eventually periodic.

The mixing decision also ignores the bit index (computation reviewer, point 6). S and M therefore commute with rotating every cell's bit ring, while R does not.

## (c) Statements

**Safe (each stated precisely):**
1. For uniform U, V = 4096 and skip 6: H(f(U)) ≤ E[min(τ,128)] = 93.5 bits. Every x has at least 2^(128 − min(c(x),128)) preimages.
2. Measured on 2^18 samples: H₂(f(U)) ≈ 16.5 bits and H_∞ ≈ 8.3 bits for F.
3. H(f^k(U)) reaches log₂ 3 by k ≈ 32 for F, whereas a random map loses about log₂(k/2) bits.
4. Designed dictionaries: S_k ↦ S_{k+1} exactly, with Hamming geometry 2·d_Q₃. The funnel figures are in (b)3.
5. The global map as in (b)4: deterministic, period 4, non-uniform, non-surjective. It is a uniform CA on 2×2 blocks only under uniform parameters.
6. A uniform fixed-point domain is a fixed point of the global map. A k-cycle domain is invariant only if phase-coherent.

**Drop or rephrase:**
- "no fixed points" (F has at least 48);
- "no stray cycle" (gray3c);
- "reads every bit once, never reads its own output, no loop";
- "fixed-depth … enumerated and inverted";
- "image ≤ 2^93.5";
- "cannot compute";
- "clock model";
- "no selection";
- basins under uniform random input used as lattice probabilities.
