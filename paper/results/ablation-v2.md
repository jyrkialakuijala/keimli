# The ablation rerun: connected correlations, the rotating order

2026-10-21. Runner and settings:
- `experiments/ablation-v2.sh` (`ablation.mjs`), 170 runs on 256²: bulk margin 32, 1,000 turns, seeds 1–5,
  dictionary Swarm F (V = 4096).
- The stage conditions at the six (swap, median) points of the first batch, quenched and turn-salted hashing.
- The page's rotating swap order; provenance in every output.
- Summary: `ablation-summary.mjs dir=paper/data/ablation-v2`, giving `../data/ablation-v2/summary-final.md`.

**What changed.** The first batch (`ablation-main.md`) defined ξ as the r where the raw C(r) = 1 − 2 P(bits differ)
crosses ½. C(r) is ⟨s_a s_b⟩ for spins s = ±1 per bit plane and includes the square of each plane's mean spin. The
lattice's bit planes are strongly biased (plane |m| = 0.5–0.99), so the raw C(r) stays above ½ at every distance.
- **Connected correlation:** C_c(r) = C(r) − m², averaged over the 8 planes of a byte group, then over groups.
- **Connected length:** ξ_c is the r where C_c(r) falls below C_c(1)/e, log-interpolated.

| condition | swap (rate) | median | hashing | raw ξx (cells) | connected ξx, mean [10th, 90th] | connected C(1) | plane \|m\| |
|---|---|---|---|---|---|---|---|
| MSR (full) | 0.5 (0.5) | 1 | quenched | 61 | 17 [13, 20] | 0.35 | 0.74 |
| MSR | 0.5 (0.5) | 1 | turn | 63 | 38 [24, 59] | 0.32 | 0.74 |
| MSR | 0.5 (0.5) | 0.5 | quenched | 64 | 46 [21, 62] | 0.13 | 0.91 |
| MSR | 0.2 (0.32) | 1 | quenched | 64 | 16 [11, 24] | 0.13 | 0.92 |
| MSR | 0.05 (0.095) | 1 | quenched | 64 | 11 [7, 14] | 0.22 | 0.85 |
| MSR | 0.05 (0.095) | 1 | turn | 59 | 19 [14, 25] | 0.43 | 0.63 |
| MS− (no decoder) | 0.5 (0.5) | 1 | quenched | 9 | 12.4 [12.3, 12.5] | 0.93 | 0.09 |
| MS− | 0.5 (0.5) | 1 | turn | 25 | 30.4 [30.0, 30.8] | 0.89 | 0.24 |
| MS− | 0.05 (0.095) | 1 | quenched | 3 | 4.7 [4.7, 4.7] | 0.84 | 0.03 |
| MS− | 0.05 (0.095) | 1 | turn | 12 | 16.0 [15.8, 16.1] | 0.93 | 0.12 |
| M−R (no settling) | 0.5 (0.5) | 1 | both | 0.5 | 0 | 0.004 | 0.53 |
| −SR (no mixing) | — | 1 | both | 18 | 4.0 [4.0, 4.1] | 0.40 | 0.58 |

The full table, with every (swap, median) point, is in `summary-final.md`.

1. **The raw lengths of the first batch were an artefact of plane bias.** With the decoder, raw ξ sits at the 57–64-cell
   edge of the measurement range everywhere. The connected correlation at distance 1 is only 0.13–0.43.
2. **The connected length of the full system is 10–46 cells,** with wide seed bands. The quenched runs at full settling
   are the shortest and tightest (11–17 cells).
   - The panel's estimate, "at most 10 cells", is right for the strongly settled, weakly mixed corner, not across the
     board.
   - The long, weak tails (C_c(1) of 0.13 at median 0.5) mean the decoder lattice is many weakly correlated, strongly
     biased planes, not large domains.
3. **Without the decoder (MS−) there are real domains.**
   - Connected C(1) is 0.84–0.93, and the lengths are tight across seeds: 5–35 cells.
   - Turn salting roughly doubles to triples them: 12 → 30 and 5 → 16 cells. This is what annealed coarsening does,
     against the deterministic freezing of the quenched rule (team synthesis).
4. **No settling, no correlation (M−R). No mixing, short correlation (−SR, 4 cells).**

**For the draft.**
- Replace every quoted ξ from the first batch with the connected length.
- Say that the decoder's lattice is biased planes with weak correlated fluctuations, and that the domain physics
  (coarsening, freezing) belongs to the mixing-and-settling medium without the decoder.
- The finite-size series (`ablation-sizes.sh`, running) tests whether these lengths depend on the lattice size.
