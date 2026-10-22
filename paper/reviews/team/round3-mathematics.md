# Round 3 — mathematics: claims, disagreements, recommendations

## 1. Claims table

| # | claim (source) | verdict | wording or experiment |
|---|---|---|---|
| 1 | decoder "reads every bit once, never reads its own output, no loop" (INTRO l.50–52) | DROP | "a single-pass, bounded-work dictionary decoder: at most 1,024 bit reads, copies from its own output with lookback ≤ 64 bytes" |
| 2 | "fixed-depth map … sampled, enumerated and inverted" (INTRO l.53–54) | KEEP-REWORDED | "a fixed, explicitly given map that can be sampled forward; its preimages can be constructed by search over the stream grammar (the designs), and its fixed points enumerated as a constraint problem" |
| 3 | "O(n) against O(c^n)" (MOTIVATION) | DROP | use INTRODUCTION_MOTIVATION l.217, or the professor's bounded-work wording |
| 4 | output < 94 bits (INTRO; decoder-map §1) | KEEP-REWORDED | "for uniform input, H(f(U)) ≤ E[min(τ,128)] = 93.5 bits (about 87.5 once header redundancy is estimated, per the information theorist); H₂ ≈ 16.5 and H_∞ ≈ 8.3 bits for F. This holds at the first turn only." |
| 5 | "image has at most 2^93.5 elements" (decoder-map §1a) | DROP | the inequality runs the other way: \|Im f\| ≥ 2^H |
| 6 | codebook "exact H(f(U)) 27–49 bits" (§6) | KEEP-REWORDED | "log₂\|Im f\| = 27–49 bits" |
| 7 | "no fixed points" (INTRO l.55; RESULTS_REPLICATORS) | DROP | F has ≥ 48 exactly verified fixed points and ≥ 2 two-cycles, all with basins < 10⁻⁴ |
| 8 | "small set of short cycles … within a few tens of turns" | KEEP-REWORDED | "for the searched dictionaries one attractor holds ≥ 77 % of 10⁴ sampled cells; texts have cycles of up to 303 turns and transients of up to 670" |
| 9 | iterated contraction | KEEP (new) | "H₂(f^k(U)) reaches log₂ 3 by k ≈ 30 for F, whereas a random map loses about log₂(k/2) bits" |
| 10 | "byte order sets the cycle" (ablation-structure §1) | NEEDS-EXPERIMENT | census of 30 byte shuffles and 30 word shuffles; F is a search winner |
| 11 | Gray-coded cycles, two bits apart, 3–32 species | KEEP | exact; add the Hamming metric 2·d_Q₃ |
| 12 | "no stray cycle" (design-gray3 §2) | KEEP-REWORDED | "no stray attractor with basin ≥ 10⁻⁴; a stray fixed point exists" |
| 13 | "clock model of as many species" | DROP | 3-cube geometry, not Z₈ |
| 14 | "deterministic cellular automaton" (METHODS) | KEEP-REWORDED | "deterministic, period 4 in time, non-uniform in space, on a bounded grid; under uniform parameters a uniform CA on 2×2 blocks" |
| 15 | "pinning by weak quenched disorder" (INTRO l.112–114) | DROP | "freezing of a time-invariant deterministic rule"; the salt-by-position runs settle this |
| 16 | "entropy pump", "mixing raises entropy" | DROP | the information theorist's source/sink paragraph, with coarse-grained entropy named |
| 17 | "the frame is the sweep" | NEEDS-EXPERIMENT | physics E4; currently contradicted by Brotli 12 |
| 18 | "replicators are fixed points and short cycles" | KEEP-REWORDED | "a configuration that reproduces itself exactly in place is a periodic point of the rewriting map. The converse is false. What Keimli shows is trivial replication with limited heredity." |
| 19 | "not born; listed" | KEEP-REWORDED | "the attractors of f are listable. The lattice also makes periodic cells that are not f-cycles (computation reviewer)." |
| 20 | "no late first appearance", 1/(Nb) | DROP the mechanism; NEEDS-EXPERIMENT | first appearance against N (32²–512²) with verified f-cycles and supercritical nuclei |
| 21 | front takeover, "1.5×", "basin^-½" | DROP | the censored median reverses the sign; the curves are size-free creep |
| 22 | fixed points win under strong settling | KEEP-REWORDED | "a uniform fixed-point domain is a fixed point of the global map, while a k-cycle domain is invariant only if phase-coherent"; robustness and wall mobility need physics E6b |
| 23 | "nothing replicates, nothing is selected" | DROP | "no copy instruction, no fitness function; the dictionaries were selected" |
| 24 | decoder versus processor separates computation | NEEDS-EXPERIMENT | dose–response in the instruction budget k; BFF census |
| 25 | never-read bytes 4,095–4,335 | KEEP | exact |
| 26 | order acts only as a 0.25-bit second-order effect | KEEP-REWORDED | add H₂: 16.5 bits for F against 21.4 shuffled |
| 27 | "refuting a hypothesis in programs is new" | DROP | Avida has done this for 25 years |
| 28 | design-vote "no head fits" | KEEP-REWORDED | "no head of the single-word, single-distance form" |

## 2. Remaining disagreements

- **Professor ("Wolfram's equivalence conjecture says to expect universality").** That is not evidence. Universality concerns specially prepared configurations, and nothing measured bears on it either way. I would write "open" and nothing more. His own frame check (boundaries identical from turn 400 to 1,000) and the decay curve show that *typical* orbits of F collapse onto small periodic orbits. That is the honest content.
- **Professor ("the frame shows where the front sits", gradient percolation).** The physicist's size series (b5) shows no front at all: the curves at 128² and 256² coincide. I side with the data.
- **Physicist ("Ashkin–Teller-like").** I agree on the cube metric, but the model is driven. Every domain advances along the Hamiltonian cycle each turn, and for a fixed phase offset j the distance d(g(k), g(k+j)) depends on k: offset 3 is 1 cube step at k = 0 and 3 steps at k = 1. Wall couplings therefore oscillate with period 8. No equilibrium model applies directly.
- **Information (87.5-bit bound).** The argument is sound, because the parse does not depend on the header. The 5.5 bits are a 4,000-cell sample mean, so the result is an estimate, not a bound, until a confidence interval is given.
- **ALife ("heritable bits ≤ log₂ of the number of attractors").** Add log₂ k for the phase, which domains inherit. That is still at most about 8 bits, so their conclusion stands.

## 3. Top five recommendations, ranked

1. **Rewrite the sentences in the table** (items 1, 3, 5, 7, 13, 15, 16, 21, 23 and 27 first). Cost: 1–2 days of writing. No new data is needed, and it removes every outright false statement.
2. **Make the map-level results exact.**
   - Port the fixed-point constraint search to C and run it over all 4,096 headers for F and ca-gray3c, and for period 2 by the same method on f∘f.
   - Report H, H₂, H_∞ and the decay of H₂(f^k(U)) for every dictionary and for the `hash:93` null, with confidence intervals.
   - Cost: 1–2 days of code plus an overnight run. It yields theorems ("F has exactly N fixed points") and replaces the 93.5-bit headline.
3. **Replace uniform basins with the medium's kernels.**
   - The perturbation matrix: the 1-, 2- and 3-bit flip outcomes per attractor, as in my round 2.
   - First appearance against N with verified f-cycles.
   - A transitivity test of the pairwise winner relation (s\*, v).
   - Cost: about 1 day plus a few CPU-hours, using the rotating order and provenance fields.
4. **Shuffle distributions**: 30 byte shuffles and 30 word shuffles of F and of Brotli 13, each with census, H₂ and decay curve, to show whether the search winner is typical. Cost: about 1 CPU-hour.
5. **The processor arm as a dose–response experiment**: the decay curve, the fixed-point and cycle census and takeover against the instruction budget k = 1…256, plus the BFF random-tape census. Cost: 1–2 weeks. Only this supports the title thesis.

## 4. Verdict

There is a publishable paper now, but not the one drafted. Its title would be roughly: *A dictionary-decoder cellular automaton: attractor census, designed attractors, and trivial replication in a deterministic medium.* Its content:

- the map-level results, made exact (recommendation 2);
- the Gray construction;
- the global-map definition;
- the replicator deflation, correctly named as trivial replication with limited heredity, with takeover reported as medium-chosen creep;
- the lattice length claims dropped or recomputed with connected correlations.

Venues: *Artificial Life* (MIT Press) or a full ALIFE 2027 paper; *Complex Systems* would suit the map-level half alone.

Minimum work: recommendations 1–3 plus the physicist's E0 if any ξ is kept. That is about two weeks.

The thesis that the decoder "separates computation from entropy reduction" needs recommendation 5 and belongs in a second paper.
