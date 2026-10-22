# The replicator Monte Carlo on the corrected pipeline

2026-10-21. `experiments/replicators-v2.sh`, `-v2b.sh` and `-v2c.sh` (`replicators.mjs`). Setup:
- **Pipeline:** the rotating swap order, a period detector to 64 with the full period confirmed, provenance in every
  output.
- **Seeds and length:** 20 seeds (10 at 512², 5 for the CPUs), 2,000 turns.
- **Summary:** `replicators-summary2.mjs` gives `replicators-table-v2.md`. A seed whose leader never reached a share is
  censored at the last turn, not dropped. Medians are Kaplan–Meier over seeds, with 95 % bootstrap intervals.
- **Raw data:** `../data/replicators-v2/`.
- **What it supersedes:** `replicators.md` and `replicators-table.md`, which used the fixed swap order, censored
  medians and a period-12/16 detector. Those numbers should not be quoted.

## The headline cases

| rule | setting | n | seeds | leader (basin under the map alone) | 10 % | 50 %: KM median [95 % CI] | seeds reaching 50 % |
|---|---|---|---|---|---|---|---|
| Brotli 12 | page frame | 128 | 20 | fixed point (0.26 %) | 59 | 731 [560, 912] | 20 |
| Brotli 12 | page frame | 256 | 20 | fixed point (0.34 %) | 61 | 920 [697, 1108] | 19 |
| Brotli 12 | page frame | 512 | 10 | fixed point (0.32 %) | 59 | 992 [688, 1445] | 10 |
| Brotli 12 | swap ½, median 1 | 256 | 20 | 3-cycle (99.6 %) | 8 | 22 [22, 24] | 20 |
| Brotli 13 | page frame | 128 | 20 | fixed point (2.8 %) | 102 | 373 [351, 406] | 20 |
| Brotli 13 | page frame | 256 | 20 | fixed point (2.8 %) | 98 | 505 [472, 526] | 20 |
| Brotli 13 | page frame | 512 | 10 | fixed point (2.9 %) | 100 | 584 [544, 606] | 10 |
| Brotli 13 | swap ½, median 1 | 256 | 20 | 9-cycle (92.9 %) | 47 | 82 [81, 83] | 20 |
| Swarm F | page frame | 128 / 256 / 512 | 20 / 20 / 10 | 3-cycle (100 %) | 11 | 34 / 33 / 34 | all |
| Swarm F | swap ½, median 1 | 256 | 20 | 3-cycle (100 %) | 8 | 13 [12, 13] | 20 |
| 5-to-12 cycles | swap ½, median 1 | 256 | 20 | 12-cycle (18.6 %) | 28 | 40 [40, 40] | 20 |
| 32 Gray 8-cycles | page frame | 256 | 20 | one 8-cycle (1.4 %) | 39 | 233 [226, 243] | 20 |
| 32 Gray 8-cycles | swap ½, median 1 | 256 | 20 | one 8-cycle (1.4 %) | 30 | 44 [43, 44] | 20 |
| 20 Gray 8-cycles | swap ½, median 1 | 256 | 20 | one 8-cycle (4.8 %) | 24 | 36 [36, 37] | 20 |
| 20 Gray 8-cycles, 3 Gray 8-cycles, 5-to-12 | page frame | 256 | 20 | (coexistence) | 24–35 | > 1999 | 0 |
| Declaration | both | 128, 256 | 20 | (no takeover) | > 1999 | > 1999 | 0 |
| Z80, 256 instructions | swap ½, median 1 | 256 | 5 | (no takeover) | > 1999 | > 1999 | 0 |

## What holds, now with intervals

1. **The medium, not the basin, picks the winner.**
   - On the frame, Brotli 12's fixed point (0.3 % basin) takes half the lattice in 49 of 50 seeds over three sizes.
   - Brotli 13's fixed point (2.8 %) does so in all 50 seeds, against cycles with 99.6 % and 92.9 % basins.
   - Under uniform settings the large-basin cycles win, within about 20–80 turns.
   - In the 5-to-12 design under uniform settings, the 12-cycle (19 % basin) takes 100 % of the lattice, not the
     5-cycle with the larger basin (28 %).
   - The mechanism is in results/mechanism.md: closure, melting, nucleation.
2. **Takeover on the frame grows slowly with size, not like a front.** From 128² to 512², a fourfold side, the median
   time to half grows 1.35 times for Brotli 12 (731 → 992) and 1.57 times for Brotli 13 (373 → 584). A single front
   crossing the lattice would scale with the side. This is nucleation throughout the melt followed by slow coarsening.
   The first batch's statement, "1.5 times slower at 256² than at 128², as a front", is withdrawn: its medians were
   censored.
3. **Designed attractors win fast under uniform settings and coexist under the frame.** The Gray designs' leaders reach
   90 % by turns 86–95. On the frame no Gray design and no 5-to-12 run reaches 50 %, except the 32-cycle design (turn
   233). Closed types do not melt one another, so the frame's mosaic stays.
4. **Every major type appears at once.** The median first sighting is turn 5–25 for every rule: within the decoder's
   transient, at the earliest turn its period can be seen.
5. **The Declaration and the Z80** produce no takeover in any setting.

## The processors on single cells (256 instructions, 256², 5 seeds)

The 6502 and Redcode runs see millions of short-lived types, 0.76–2.2 million types per seed. Their result files
exceeded JavaScript's string limit and were not written, so these numbers are read from the run logs. The script now
lists only types that ever held 0.1 % and counts the rest.

- **No takeover.** At turn 2,000 the leading type, always a fixed point, holds:

  | processor | leading type's share | seeds |
  |---|---|---|
  | 6502 | 0.1–0.5 % | 3 per setting, from the logs |
  | Redcode | 2.6–7.3 % | 3 per setting, from the logs |
  | Z80 | 1.5–1.9 % on the frame; no leader under uniform settings | 5, from the result files |

  The other seeds' log lines were overwritten when the two batches shared the job list.
- **Joined pairs are different.** Redcode's imp takes over there (`dose-response.md`), and the 6502 leads with 61–69 %
  at 16 instructions.
