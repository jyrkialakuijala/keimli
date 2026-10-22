# Information dynamics per bit: storage, transfer and the rest

2026-10-21. `experiments/infodyn.mjs` (raw data `../data/infodyn/`). Each (cell, bit) is a binary time series on 128²
under uniform swap ½, seed 1, rotating order, and its next value is decomposed with plug-in estimators over all cells
and 32 sampled bit positions (history k = 3). This follows Lizier, Prokopenko and Zomaya [lizier2008, lizier2012]:
- **storage** A = I(x_{t+1}; x_t^{(3)});
- **transfer from a neighbouring cell:** the apparent transfer entropy from the same bit of each 4-neighbour,
  averaged over the four;
- **transfer from the adjacent bits:** from bits q − 1 and q + 1 of the same cell, jointly;
- **the rest:** H(x_{t+1}) minus the three. It is an upper bound on what no single local source explains, which
  includes the synergistic, non-local rewriting of a decoder or a program.

The rest is not Lizier's information modification, which needs a separable-information estimate. It bounds it from above.

| rule | setting | H(next) | storage | from a neighbouring cell | from the adjacent bits | rest |
|---|---|---|---|---|---|---|
| decoder, Swarm F | median 1, turns 20–60 | 0.742 | 0.623 | 0.013 | 0.014 | 0.092 |
| decoder, Swarm F | median 0.5, turns 200–300 | 0.847 | 0.047 | 0.007 | 0.021 | 0.772 |
| decoder, Brotli 12 | median 1, turns 20–60 | 0.993 | 0.433 | 0.031 | 0.031 | 0.498 |
| decoder, Brotli 12 | median 0.5, turns 200–300 | 0.999 | 0.008 | 0.003 | 0.001 | 0.988 |
| look-and-say, base 10 | median 1, turns 20–60 | 0.999 | 0.913 | 0.018 | 0.002 | 0.066 |
| look-and-say, base 10 | median 0.5, turns 200–300 | 1.000 | 0.002 | 0.001 | 0.001 | 0.997 |
| rule 90 | median 1, turns 20–60 | 1.000 | 0.000 | 0.000 | 0.352 | 0.648 |
| rule 90 | median 0.5, turns 200–300 | 1.000 | 0.000 | 0.000 | 0.003 | 0.997 |
| Z80, 256 | median 1, turns 20–60 | 0.345 | 0.335 | 0.001 | 0.000 | 0.009 |
| Z80, 256 | median 0.5, turns 200–300 | 0.118 | 0.104 | 0.001 | 0.000 | 0.013 |
| Z80, 256, pairs | median 0.5, turns 200–300 | 0.105 | 0.089 | 0.001 | 0.000 | 0.014 |
| Subleq, 256 | median 0.5, turns 200–300 | 0.146 | 0.122 | 0.002 | 0.000 | 0.022 |
| Redcode, 256, pairs | median 1, turns 20–60 | 0.842 | 0.684 | 0.012 | 0.001 | 0.145 |
| Redcode, 256, pairs | median 0.5, turns 200–300 | 0.297 | 0.279 | 0.002 | 0.003 | 0.013 |
| 6502, 16 | median 0.5, turns 200–300 | 0.863 | 0.156 | 0.022 | 0.007 | 0.679 |

1. **Processors' memories mostly sit still.**
   - For the Z80, Subleq and Redcode, a bit's next value has 0.1–0.3 bits of entropy, and its own past explains nearly
     all of it.
   - Most programs in a 16-byte memory halt, or loop without writing, within a few turns.
   - What they leave is local order (dose-response.md), not ongoing processing.
2. **The decoder and look-and-say rewrite everything every turn.**
   - Where they are kept active (median 0.5), 77–100 % of each bit's next value comes from neither its past nor any
     single local source: it is the non-local rewrite of the whole cell.
   - Where they sit on their cycles (median 1), storage takes over: a k-cycle is perfectly stored.
3. **Rule 90** shows the within-cell transfer that it is (0.35 bits at median 1), blurred by the medium. Under strong
   mixing it is mostly unexplained, because the mixing scrambles the adjacent bits between turns.
4. **The 6502 at 16 instructions** is the one processor that keeps its memory active (H(next) 0.86, rest 0.68), like
   the decoder. That fits its being the one processor setting with a leading type on single cells (dose-response.md).

**For the thesis.** By these per-bit measures, the processors in this lattice do less non-local processing per turn
than the decoder, not more. Their programs fall still. Whatever is distinctive about computation does not show as
ongoing per-bit activity here. If it shows at all, it is as the local order processors leave behind (block entropy)
and as Redcode's imp takeover on pairs.

**Caveats.**
- Plug-in estimates with k = 3 and single-bit sources.
- Larger k, multi-bit sources and the separable information of Lizier 2010 would sharpen the rest into modification.
- Seed 1 only.
