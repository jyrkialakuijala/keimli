# Round 3: statistical physics and design (claims and recommendations)

Experiment names (E0–E7) are those of `round2-physics.md` §c.

## 1. Claims table

| # | claim (where) | verdict |
|---|---|---|
| 1 | The bitwise pair freezes under quenched hashing and coarsens when annealed (INTRODUCTION l.111–115, ablation-main §2) | KEEP-REWORDED: "Under a time-invariant rule (salt 0, or salt by position) mixing plus a deterministic median freezes at ξ ≈ 3–6 cells; re-salting by turn makes it coarsen." The salt-by-position part rests on 2 seeds; E1 at 10 seeds before print. |
| 2 | "Pinning by a weak quenched disorder" [sicilia2008] | DROP. Real spatial disorder (salt 2) changes nothing (C(8) 0.331 vs 0.327). Say "blocked states of a zero-temperature deterministic vote" [vichniac1984; Spirin–Krapivsky–Redner 2001]. |
| 3 | Coarsening "as about t^⅓", Kawasaki-like (ablation-main §2, INTRODUCTION_MOTIVATION l.149) | NEEDS-EXPERIMENT E2. Until then: "coarsens, local exponent drifting from 0.37 to 0.24 over one decade". |
| 4 | Three-stage finite domain length (ξ ≈ 40 quenched, one domain annealed) is hash pinning (ablation-main §3) | NEEDS-EXPERIMENT E0. The connected bound is ≤ 9.5 vs ≤ 24; the direction may survive, the numbers do not. |
| 5 | Sharp granular-to-ordered transition, median 0.3–0.5; "no critical regime" (ablation-scan §1) | KEEP-REWORDED: "below median p ≈ 0.3 the phase field is uncorrelated and about 95 % of cells are in transients; above it, phase order develops". Sharpness, order and location: E3. DROP "no critical regime" (it was measured with the biased ξ). |
| 6 | The decoder's transient and its cycle geometry decide ordering (`cycle3f`/`cycle3` nulls) | KEEP; the distinct-cell and C(1) evidence does not need ξ. Add the relaxation-time null (README item 2): this is the paper's physics result. |
| 7 | "The frame is the sweep" (INTRODUCTION l.98–99) | DROP. Reword: "the frame illustrates the diagram; adjacent regimes interact through fronts". |
| 8 | Fixed order anisotropic, rotation isotropic (swap-order.md) | KEEP: an x/y comparison in one snapshot shares ⟨m²⟩, so the bias cancels. DROP "gave the most ordered lattice" as a reason (chosen on outcome), or report it as such. |
| 9 | Gray designs give a q = 8 clock / Potts-like mosaic (design-gray3 §3–4) | DROP. Reword: "three Ising-like fields on the 3-cube, driven round a Gray Hamiltonian cycle". A clock needs a Johnson code (E5). |
| 10 | Species coexistence, wetting layer, "reading length decides" (design-gray3) | NEEDS-EXPERIMENT: ≥ 5 seeds, rotating order, a reading-length column (optimisation reviewer). |
| 11 | No late first appearance: 1/(N·b) (RESULTS_REPLICATORS, replicators.md) | DROP as derived. Reword: "in these runs every winning type held ≥ 1 % of cells within about 100 turns". E7 with lattice-verified cycles. |
| 12 | "Lateness is takeover at front speed"; "1.5× at 256²"; t₅₀ ∝ b^−½ | DROP all three. Reword: "fast establishment (≤ 100 turns) then slow, size-independent growth, about +0.04 of the lattice per doubling of t". |
| 13 | The medium, not the basin, chooses the winner | KEEP-REWORDED: add the mathematician's exact reason (a uniform fixed-point domain is a fixed point of the global map; a k-cycle domain carries phase walls). Quantify with wall velocity and robustness (E6b). |
| 14 | Swaps carry phase information that the vote alone cannot (life-vote.md) | KEEP provisionally. C(8) ≈ 0.5 as "uncorrelated" must be rechecked with E0. |
| 15 | METHODS: "exchanged with probability p", "replaced with probability p", "randomness quenched in its configuration" | KEEP-REWORDED: "p sets the fraction of local contexts that act; the rule is deterministic, period 4 in time under the rotating order, with pseudo-random decisions; 'annealed' re-salts by turn and is also deterministic". |
| 16 | Correlation length as observable (METHODS l.74–76) | KEEP-REWORDED: "the connected correlation of the phase field (or mutual information between neighbour labels), sampled at equal phase". |
| 17 | Entropy pump, nothing replicates or is selected, refuting a hypothesis in programs is new, no fixed points | DROP (information, ALife, professor, mathematics). I concur. |

## 2. Remaining disagreements

**ALife (nucleation and "survival of the flattest").** We agree that it is not a front. I do not accept nucleation as the rate-limiting step *under the frame*. Brotli 12's fixed point holds 16–25 % of cells by turn 100 in all ten runs, so it is not waiting for a rare supercritical nucleus. The ALife patch runs are uniform-parameter, single-seed and on idealised residents; there a barrier is plausible and I accept s* > 1 for uniform strong settling. My reading of the frame data is: establishment where the fixed point is robust (the noisy rows), then wall creep. That is their robustness mechanism, which I endorse, plus the mathematician's no-internal-wall theorem. I would not use "survival of the flattest". Wilke et al. describe mutation–selection balance among heritable genotypes, and the ALife reviewer's own test shows no heritable variation. Use "selection on robustness between types". Multi-nucleus (Avrami) growth is also size-free; E6a's cluster counts separate the two.

**Professor (the Brotli 12 flip as gradient percolation).** Partly. A front pinned at the gradient explains *where* the boundary sits, not *which* type wins. The robustness reservoir in the noisy rows does.

**Computation ("the order flaw matters little").** Agreed for winners. But the "fixed" data cannot be used for any ξ, anisotropy or exponent claim.

## 3. Top five recommendations

1. **Rebuild the observable (E0).** Connected per-plane G(r), a Z₃ phase field, mutual information (information reviewer), range to L/4, equal-phase sampling; then rerun the reference points. About 2 h of code plus 10 CPU-h. Every length claim depends on it.
2. **Rerun and relabel the salt controls (E1).** Salt modes 0–3 plus five fixed-salt rule replicas, and the wording "deterministic freezing". About 9 CPU-h.
3. **Rerun under the page's rule, with provenance and censoring-aware statistics** (computation's items 1–3). 10 seeds, bootstrap CIs, "never" counted as > T. About 3 h on 28 cores.
4. **Locate the synchronisation transition (E3) together with the relaxation-time null.** Periodic boundaries; sizes 128–512; median 0.25–0.5; both starts; Binder cumulant. About 190 CPU-h (a 256/512-only version, about 70). This is the physics paper's result.
5. **The takeover mechanism (E6a and E6b with the ALife s*, v, ρ).** About 50 CPU-h. It turns "the medium chooses" into a measured selection rule.

E2 (the exponent, about 50 CPU-h) only if the exponent stays in the paper.

## 4. Verdict

Yes, one paper. "An attractor census of a dictionary decoder, and the phase ordering of a lattice of identical discrete oscillators under exchange noise and majority settling." Its results:
- the census, with designed attractors;
- deterministic freezing against re-salted coarsening of the bitwise control;
- a granular-to-synchronised transition whose position is set by the decoder's relaxation time and cycle geometry, shown by the nulls.

Venues: Physical Review E or Chaos; Physica D if the census leads. The replicator deflation belongs in the discussion, or in a separate ALife paper after the BFF census.

Minimum work: recommendations 1–4 plus the rewording in §1. That is about 100–200 CPU-h and two weeks. As it stands, no length or exponent in the drafts is publishable. The census and the null-model logic are.
