# Round 3: optimization reviewer, claims and recommendations

## 1. Claims table

| # | claim (where) | verdict | wording or experiment |
|---|---|---|---|
| 1 | Dictionaries "found" by search; the frame lets a rule set be judged "after a few adjustments, rather than after a search" (INTRODUCTION l.101–105, MOTIVATION l.123) | KEEP-REWORDED | "The searched dictionaries were selected by a hand-made score computed on the gradient frame, and the default by eye. Under uniform parameters their score falls to zero and the ranking reorders." (my round 2, b1) |
| 2 | "The frame is the sweep" (INTRODUCTION l.98–99) | DROP | Replace with E4 (physics): frame strips against uniform runs. My data and Brotli 12's flipping winner already contradict it. |
| 3 | "Nothing is selected, no score is kept" (INTRODUCTION l.133–137) | KEEP-REWORDED | "The lattice has no fitness function and no copy instruction. The dictionaries were selected, and the medium selects among types." (ALife, mathematics) |
| 4 | Each searched dictionary gives one dominant short cycle (RESULTS_REPLICATORS l.26) | KEEP | Add: "the search score did not ask for this; it is a by-product of its activity window". |
| 5 | Q3: searched dictionaries differ in kind from texts | KEEP-REWORDED | True under the frame on held-out seeds (searched 6–34, the Declaration about 0.85, one shuffle of F 5–8). Must say "under the gradient frame"; the uniform-point comparison needs ≥ 5 seeds. |
| 6 | The byte order sets the cycle (ablation-structure §1) | KEEP for F; NEEDS-EXPERIMENT for typicality | 30 byte- and 30 word-shuffles, census plus score. F is a selected object, so one shuffle per condition says nothing about how typical it is. |
| 7 | Attractors "built, not searched", "listed, prescribed" (RESULTS_REPLICATORS l.35, draft §1) | KEEP-REWORDED | "Constructed by exhaustive enumeration and randomised packing under an exact census check". The Gray construction itself is exact (mathematics). |
| 8 | ca-gray3c has "no stray cycle" | KEEP-REWORDED | "No stray cycle with basin above 10⁻⁴". Mathematics found a stray fixed point. |
| 9 | "Stray cycles are fatal; below 0.5 % stray the lattice always orders" (design-gray3 §8) | NEEDS-EXPERIMENT | 26 designs × 5 seeds, rotating order. Likely to survive: 22 of 22 and 4 of 4 at one seed. |
| 10 | "Reading length decides the winner; the longest cycle wins; funnel steepness is what the lattice selects on" | NEEDS-EXPERIMENT | A per-design reading-length column, multiple seeds, and the pairwise transitivity test (mathematics: A × C → B already breaks a total order). The census funnel does not predict coexistence (ρ = −0.08). |
| 11 | Nibble and 2-bit joinings: "no head fits" (design-vote.md) | KEEP-REWORDED | "No head of the single-word, single-distance, literal-free form fits". |
| 12 | design-vote and design-gray3 lattice tables | NEEDS-EXPERIMENT | They are single-seed and fixed-order. Rerun with 5 seeds and the rotating order. |
| 13 | Replicators "present from the start; lateness is takeover at front speed"; 1/(Nb) | KEEP-REWORDED | "At 128² and above, attractor types appear within the transient (7–12 turns) and their share then creeps up logarithmically. The medium, not the isolated basin, sets both." (computation, physics, ALife) |
| 14 | ×1.5 from 128² to 256²; takeover time ∝ basin^−½ | DROP | The censored median reverses the sign; four dictionaries do not make a law. |
| 15 | q = 8 clock model / Potts-like | DROP | The states lie on a 3-cube (mathematics, physics). |
| 16 | Hash pinning "by weak quenched disorder" [sicilia2008] | KEEP-REWORDED | "Freezing of the time-invariant deterministic rule". Salt by position changes nothing (physics). |
| 17 | t^⅓ coarsening | NEEDS-EXPERIMENT | E2 (physics). |
| 18 | "Cannot loop, refer to itself or compute"; "local entropy pump" | KEEP-REWORDED; DROP | Use the information theorist's bounded-work-decoder and entropy-sink sentences. |
| 19 | Score and eye diverge (former H6) | KEEP as one sentence | "The default (F) ranks in the bottom half of the searched set by the search's own score on held-out seeds." No user study is needed. |

## 2. Remaining disagreements

- **Physics, "cycle3f already refutes the professor's reduction."** I disagree. `cycle3f` tests one reduction, instant collapse onto the cycle. The professor's fitted table has an off-cycle label ⊥ and learns transient behaviour from data, so it is a different null and is not refuted. It is also the right null for the optimiser's question of whether the 128-bit content matters to what the search rewarded. Run it.
- **Professor, "the swarm found short global oscillators because the objective rewarded them."** I partly disagree. The score's `change` window (0.005–0.35) and the guards reward moderate activity *averaged over the frame*. Nothing in the objective asks for one global cycle, and the shuffled F, with a 29-cycle, also passes the guards. The single cycle is more likely a by-product of selecting for a steep funnel through `structure`, which is an untested hypothesis. Settling it means scoring dictionaries matched for cycle count but differing in funnel steepness.
- **Professor, "the gradient frame will not matter."** I agree as evaluation, not as a tool. As an interactive search environment it is what let the author find F and the designs quickly. Keep it as the instrument and the figure, never as a measurement.
- **Computation, order flaw "matters little."** I agree for the qualitative results and for the search score (under 15 %). It still must not be mixed with rotating-order data in one table.

## 3. Top five recommendations, ranked

1. **Demote search to provenance; promote design and the census.** Rewrite the search sections as "human-in-the-loop selection under the frame". Report the broken generator (period 10,466, so the seeds were not independent) and the seed-11 winner's curse. Cost: one day of text, plus minutes to fix the generator.
2. **Multi-seed, rotating-order, uniform-point re-evaluation** of every named dictionary that a claim rests on: the menu score, the design-gray3 and design-vote tables, and the stray-cycle rule. Cost: about 2 CPU-hours for the score, one batch (about 10 CPU-hours) for the design tables.
3. **Make the design objective explicit and validated.** Use the census (stray share under 0.5 % as a constraint, funnel as quality) to pick candidates. Then test what decides the lattice outcome: reading length, pairwise transitivity, and droplet velocity and robustness (ALife's s\*, v, ρ; physics E6b). Cost: 1–2 days of code, about 10 CPU-hours.
4. **Typicality controls for selected objects**: 30 shuffles of F, and the exact fixed-point enumeration (mathematics, overnight in C). Cost: about 1 CPU-hour plus one night.
5. **Provenance and lineage logging** in every search and run output, with no silent reseeding. Cost: half a day.

The MAP-Elites study is for a later dictionary paper, not this one.

## 4. Verdict

Yes, there is a publishable paper. It is not the "between computational and arithmetic life" paper; it is the map paper.

**Content.** A CA whose local rule is a dictionary decoder, analysed through the attractor census and the entropy-decay curve (mathematics: log₂ 3 by k ≈ 32, against log₂(k/2) for a random map). Attractors prescribed by construction, with the exact Gray-cube geometry, design rules for whether the lattice orders, and an honest account of the medium as frozen mosaics of coupled oscillators.

**Venue.** The *Artificial Life* journal or an ALIFE full paper; Complex Systems is a fallback.

**Minimum work.**
- Strike the false sentences, items 2, 3, 8, 14, 15, 16 and 18 of the table.
- Physics E0, connected correlations.
- Recommendations 1, 2 and 4.

That is about a week of work and under 50 CPU-hours. The replicator deflation becomes a second paper and needs the BFF census (ALife) to be decisive. Without it, the deflation is the author's hypothesis about his own earlier work.
