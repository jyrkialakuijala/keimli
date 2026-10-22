# Finite-size series: freezing, coarsening, and an absorbing state at small sizes

2026-10-21. `experiments/ablation-sizes.sh` (`ablation.mjs`): 96 runs.
- **Conditions:** MSR (the full system, decoder Swarm F) and MS− (mixing and settling only).
- **Parameter points:** (swap ½, median 1) and (swap 0.2, median ½); quenched and turn-salted hashing.
- **Sizes:** 64², 128², 256² and 512², bulk margin n/8; seeds 1–3; 2,000 turns.
- **Observables:** connected correlations (results/ablation-v2.md); the rotating swap order; provenance in every output.
- **Summary:** `ablation-summary.mjs dir=paper/data/ablation-sizes`.

Connected length ξ_c (cells, mean and 10th–90th percentile over seeds) at turn 2,000:

| condition | swap, median | hashing | 64² | 128² | 256² | 512² |
|---|---|---|---|---|---|---|
| MS− | ½, 1 | quenched | 9.78 [9.77, 9.80] | 11.65 [11.56, 11.77] | 12.41 [12.32, 12.54] | 12.61 [12.59, 12.62] |
| MS− | ½, 1 | turn | 15.3 [14.2, 16.4] | 25.7 [25.5, 25.9] | 37.1 [36.4, 37.6] | 42.4 [41.8, 42.8] |
| MS− | 0.2, ½ | quenched | 13.7 [13.5, 13.8] | 21.6 [21.5, 21.7] | 26.5 [26.4, 26.6] | 27.9 [27.8, 28.0] |
| MS− | 0.2, ½ | turn | 18.7 [15.1, 23.3] | 27.4 [25.4, 29.6] | 37.0 [36.0, 38.3] | 44.6 [44.4, 44.8] |
| MSR | ½, 1 | quenched | 11.9 [7.5, 17.4] | 33.9 [19.6, 45.5] | 21.9 [13.8, 32.8] | 30.9 [20.7, 43.3] |
| MSR | ½, 1 | turn | 32.0 | 17.4 [14.8, 19.6] | 30.8 [5.7, 56.9] | 31.0 [5.8, 57.0] |
| MSR | 0.2, ½ | quenched | uniform (\|m\| = 1) | uniform | 12.2 [2.8, 21.0] | 52.6 [41.9, 62.3] |
| MSR | 0.2, ½ | turn | uniform | uniform | 15.6 [3.1, 28.2] | 56.8 [48.9, 63.3] |

1. **The quenched medium freezes at a size-independent length.**
   - Without the decoder and with quenched hashing, ξ_c converges with size: 12.41 → 12.61 cells from 256² to 512²
     at (½, 1), and 26.5 → 27.9 at (0.2, ½), with seed spreads below 0.2 cells.
   - This is the finite-size signature of the deterministic freezing the panel identified. The rule is time-invariant,
     so the configuration stops changing (d1 ≈ 10⁻³) at an intrinsic length.
2. **The turn-salted medium coarsens until the lattice stops it.** With the hash salted by the turn, ξ_c keeps growing
   with size, 15 → 26 → 37 → 42 cells, and has not converged at 512² within 2,000 turns. That is coarsening limited
   by the finite size and the run length, the annealed counterpart.
3. **With the decoder, small lattices fall into an absorbing state.**
   - At (0.2, ½), every 64² and 128² run ends uniform: plane |m| = 1 and every cell the same state, an absorbing state
     of the lattice map by Lemma 1.
   - At 256² and 512² none does within 2,000 turns.
   - At (½, 1) no size collapses, and ξ_c shows no clear trend with size, with wide seed bands of 6–57 cells.
4. **For the paper.**
   - Results with the decoder at 128² or below can be dominated by a finite-size collapse.
   - The full system's correlation length is not size-converged and must be reported as a range with its seed spread,
     not as a number.
   - The freezing and coarsening claims belong to the medium (MS−), where they are now size-checked.

**1024² (one seed, the medium alone).**
- Quenched: ξ_c = 12.59 at (½, 1) and 28.47 at (0.2, ½), against 12.61 and 27.9 at 512². Converged.
- Turn-salted: 44.65 and 45.51, against 42.4 and 44.6. Still creeping up.

**Not done.** longer runs for the annealed series, and the time dependence ξ(t) at each size; the per-turn data
is in `series.csv` of the same directory.
