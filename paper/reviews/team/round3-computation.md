# Round 3: scientific computation, claims and recommendations

No new experiments. The facts used below come from rounds 1–2 (mine and the panel's).

## 1. Claims table

| claim (where) | verdict | wording or experiment |
|---|---|---|
| "Every number comes from a script run on the same module the page uses" (METHODS) | KEEP-REWORDED | "…on the module built from commit X (wasm SHA-256 Y), with the settings recorded in each output". The harness is not the page today: it defaults to the fixed swap order, and the page's single-thread engine is a separate implementation with a vote-snapshot defect. |
| The band pipeline is bit-identical to the single-threaded module (METHODS) | KEEP | band.test passes. It does not cover the page's own engine; add a 1-vs-4-thread parity self-test. |
| A deterministic cellular automaton whose randomness is quenched in its configuration (METHODS) | KEEP-REWORDED | Use mathematics' version: "deterministic, period 4 in time (swap order, edge parity), non-uniform under gradients, uniform on 2×2 blocks under uniform parameters, clamped edges". Say that the median's acceptance hashes only the cell's own context, so at p < 1 it is a content-dependent mask, not a rate. |
| H1 retracted; freezing is "hash pinning by quenched disorder" (results/README, INTRODUCTION:114) | KEEP-REWORDED | "Freezing of the time-invariant deterministic rule". Physics' salt-2 runs show that disorder changes nothing and time-variation unfreezes. |
| Correlation lengths, "one domain across the bulk", the granular→ordered transition (ablation-main, ablation-scan) | NEEDS-EXPERIMENT | Physics E0 with connected G(r) or phase mutual information, run uncapped. The current ξ measures whether the magnetisation plateau lies above ½. |
| Annealed coarsening as t^⅓ | NEEDS-EXPERIMENT | E2. The local slope drifts from 0.37 to 0.24, so the exponent is not stable. |
| The decoder as a map: 93.5-bit bound, census, H₂ (decoder-map, ablation-main §1) | KEEP-REWORDED | It is an upper bound at turn 1. Add H₂ = 16.5 bits and the H₂(fᵏ) decay to log₂3 by k ≈ 30. Drop "no fixed points": F has ≥ 48. |
| "No late first appearance; present from the start below notice; 1/(N·b)" (RESULTS_REPLICATORS, replicators.md) | KEEP-REWORDED + NEEDS-EXPERIMENT | "At 128² and above, every attractor that ever reaches 1 % appears within its transient (≤ 15 turns). The lattice creates basin entries: at 32² a fixed point absent from the isolated census appears by turn 20–58." Restrict to periods ≤ kmax; texts are unmeasured. Experiment: E7 with lattice-verified f-cycles. |
| "Takeover at front speed, 1.5× longer at 256²; time ∝ basin^−½" | DROP | The 716 was a censored median (true 1,336 at 128² against 1,093 at 256²). The curves do not depend on size (physics b5), and the basin fit spans four different dictionaries. Replace with the full share curves and E6a/E6b. |
| "The medium, not the basin, chooses the winner" | KEEP | It is robust to swap order (my rerun) and to seeds. Add mathematics' wall argument and ALife's robustness mechanism as the explanation. |
| "Nothing replicates, nothing is selected" | DROP | Use ALife's §c paragraph: trivial replication, limited heredity, no fitness function and no copy instruction. |
| "Rule systems compute nothing"; "decoder has no loop, never reads its output" | DROP | Use the professor's and information's wording: a single-pass, bounded-work map. |
| "Entropy pump" | DROP | Use information's source/sink sentence, with coarse-grained entropy stated explicitly. |
| "The frame is the sweep" | NEEDS-EXPERIMENT | E4. Optimization and Brotli 12 already contradict it, so keep the frame as an illustration only. |
| Designed dictionaries: prescribed Gray 8-cycles, funnel figures | KEEP-REWORDED | Exact and verified. Drop "no stray cycle" (gray3c has a stray fixed point) and "clock model". |
| "Swarm/searched dictionaries have many regimes" | KEEP-REWORDED | "…under the gradient frame". Optimization's b1 shows that the score collapses under uniform parameters. |

## 2. Remaining disagreements

- **Physics and information, "annealed injects zero entropy".** This is formally true, but it is true of every pseudo-random Monte Carlo simulation. It should not drive the experimental design: a "true-RNG flag" is unnecessary. What matters operationally is whether the decision depends on the turn and the position. Fine-grained entropy should be dropped from the text entirely, and the paper should say which coarse-graining it uses.
- **Professor ("nothing in RESULTS_REPLICATORS is confirmatory given the fixed order") and mathematics ("the order invalidates takeover times").** My fixed/rotate rerun leaves the winners, final shares and first appearances unchanged, and moves times within the seed scatter. What invalidates the takeover numbers is the statistics: censoring and a t₅₀ taken at the plateau. Fixing the order is needed for the anisotropy and ξ claims and for honesty, but it is not what breaks this section.
- **ALife ("first appearance can be genuinely late through nucleation").** That is plausible in principle, but it was not observed in the published setting. Under the frame, Brotli 12's fixed point appears by turns 7–12 at 128²–256² and holds 3–10 % by turn 50 (physics). ALife's implants were idealised, uniform-settling residents. The nucleation picture belongs in the text as a hypothesis for small N and uniform strong settling, where my 32² data are consistent with it.

## 3. Top five recommendations

1. **Pipeline hygiene before any rerun (about one day).** This means:
   - a provenance block in every output (commit plus dirty flag, wasm, script and dictionary SHAs, swap order, salt mode, kmax), with summaries that refuse mixed versions;
   - rotate as the harness default;
   - one turn engine in the page (`Band.runTurn` with one band), plus a parity self-test, which also fixes the vote-snapshot corruption;
   - docs/lattice.md and the band.js header corrected.
2. **Observables fixed once, in the harness (about one day).** Connected G(r) or phase mutual information, run to L/4 with no cap; uncensored survival-style summaries; bootstrap CIs; full share curves in place of t₅₀; per-stage snapshots; lattice-verified f-cycles in the detector, with unbounded period detection by hash table. Then recompute or rerun E0 (about 10 CPU-hours).
3. **Rerun the replicator section on the fixed pipeline (a few CPU-hours).** The size series 32²–512² for first appearance against the lattice's own b_eff, ten seeds, uniform and frame. Add droplet experiments for wall velocity (E6b).
4. **Consolidate the map-level results, which are cheap and exact (1–2 days).** The H₂(fᵏ) decay against the random-map null, the exhaustive fixed-point enumeration of F (an overnight job in C), H₂ and H_∞ per dictionary, and the designed attractors with the funnel matrix. This is the part that cannot be refuted and is the author's own.
5. **The comparison that justifies the title (several days).** Run the census and the H₂(fᵏ) decay on the CPUs over instruction budgets k = 1…256 (the professor's dose–response), plus the BFF random-tape census against 1/(N·interactions). Without it, the "computational life" claims stay hypotheses.

## 4. Verdict

Yes, there is a publishable paper, though not the one framed now:

> **"Decoders as cellular-automaton rules: attractor census, designed attractors, and trivial replication in an oscillator medium."**

- **Content.** The census and the decay of H₂(fᵏ); designed Gray attractors; deterministic freezing against time-salted coarsening (connected measures); the medium choosing the winner (wall and robustness), with first appearance inside the transient.
- **Venue.** *Artificial Life* (MIT Press), or a full paper at ALIFE 2027 with the page as a reproducible supplementary artifact (archived build, DOI, settings line per figure). *Physica D* or *Complex Systems* would suit if the physics experiments E0–E4 are done properly.
- **Minimum work.** Recommendations 1–4 (about a week, mostly not CPU-bound), plus rewriting the dropped and reworded sentences above.
- **What the larger claim needs.** "The decoder separates computation from entropy reduction" needs recommendation 5. Until it exists, that claim belongs in the discussion as a programme, not in the abstract.
