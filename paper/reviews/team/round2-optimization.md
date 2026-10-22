# Round 2: optimization and search methodology

The scripts and raw outputs are in my scratchpad (`rescore.mjs`, `seedcheck.mjs`, `r-*.tsv`), not in paper/data. My harness reproduces Swarm F's logged score (14.34 at seed 11) exactly. Setup for all runs: 128², 200 turns, the swarm's modes score without the novelty factor, about 7 s per evaluation on the loaded machine.

## (a) Responses to the panel

- **Computation, altOrder (confirmed by the coordinator).** The same default also affects all three search tools: `makeSim` defaults to `altOrder=false`, and no search tool passes it. So every searched dictionary was optimised under the fixed order. I measured how much this matters for the search score: re-scoring under `rotate` changes it by under about 15 % and keeps the ranking (F 14.4/12.5, A 26.1/22.8, E 38.2/30.7, Brotli 1 6.6/6.9, seeds 1/2). This weakens the concern for the dictionary-menu claims. It says nothing about the replicator winners, which still need the rerun.
- **Computation, provenance.** Agreed, and it is worse for the searches. ca-swarm.mjs l.380 reseeds every run from every earlier `build/ca-swarm-best-*.json`, and no parent or operator is logged. The lineage of F cannot be reconstructed, and the "six swarm results" are one tree.
- **Mathematics #7 (shuffles of a selected object).** Agreed, and this is the optimisation point exactly. F is the top of a search, so its 3-cycle is subject to a winner's curse; comparing it with one sample per shuffle tells us nothing about how typical it is. My one byte-shuffle of F scores 5.4–7.5 against F's 12.5–14.5, so the score does see byte order. A distribution needs about 30 shuffles.
- **Mathematics, "enumerated".** The same over-reach appears in design-vote; see (b2).
- **ALife #1 (selection exists).** Agreed. design-gray3's rule "the longest reading wins" is a fitness function measured after the fact. My (b3) adds that the census does not predict which types coexist, so the medium, not the map, does the selecting.
- **Professor**, "the author found out what his own search did". Yes, and (b1) sharpens it: the search found dictionaries whose diversity exists only across the gradient frame.
- **Physics #5 ("the frame is the sweep" is false).** My data are direct evidence; see (b1). **Physics #7:** `rotate` was chosen on the outcome measure. That is the same move as picking F by eye from search output. Both are legitimate, but both are selection on the result and must be reported as such.
- **Information #2.** The search guards use the same pooled byte entropy. In every case I printed, the entropy window (1.5–7.2 bits) was 1, so it never constrained the search. The binding guards are `structure` (mean neighbour Hamming) and `compress` (zip ratio).

## (b) Deep dive

### b1. Held-out seeds, uniform parameters against the frame, rotating order

Held-out seeds 1–3, gradient frame, fixed order (score):

| dictionary | seed 11 (search) | seeds 1 / 2 / 3 (or 1–5) |
|---|---|---|
| Swarm E | — | 30.9 / 29.5 / 34.2 |
| Swarm A | 31.1 | 40.1 33.8 23.7 23.1 25.8 |
| Swarm C | — | 27.5 / 22.1 / 25.6 |
| Swarm G | **31.3** | 27.5 22.6 22.5 24.8 24.9 |
| Brotli 9 | — | 23.7 / 22.2 / 23.3 |
| Swarm D | — | 22.5 / 20.1 / 18.7 |
| Brotli 13 | 19.7 | 18.2 15.8 20.1 17.3 23.1 |
| Brotli 12 | — | 14.5 / 15.9 / 16.1 |
| **Swarm F (default)** | 14.3 | 12.6 14.4 14.5 13.0 14.5 |
| F byte-shuffled | — | 7.5 / 6.7 / 5.4 |
| Brotli 1 | — | 6.4 / 6.3 / 6.0 |
| Declaration (text) | — | 0.88 / 0.84 / 0.84 |

- The score separates searched dictionaries from texts and from a shuffle, which supports Q3 in the frame.
- Within-dictionary spread (SD 1–7) is comparable to the gaps between neighbours in the table. Only a coarse three-tier ranking is reliable.
- Swarm G's seed-11 score is 28 % above its held-out mean: a winner's curse.
- F, the human choice, ranks in the bottom half of the searched set. That is consistent with the cut H6 and shows the default was chosen by eye, not by the score.

**Uniform parameters destroy the score.** At swap ½, median ½ everywhere (seeds 1, 2):

- Every swarm dictionary scores 0.00 (E 0.11). The `structure` and `compress` guards fail, and the raw modes fall to 1.5–6.9.
- Brotli 1, the lowest in the frame, becomes the highest (10.3, 11.2). Brotli 13 scores 3.6 and 8.4.

At swap 0.2, median 1, every dictionary except the text fails a guard again. The raw modes there are E 17, Brotli 9 16, A 9, F 7, Brotli 1 1.0. So part of the regime diversity is intrinsic, but the gated objective that selected the menu can only be satisfied by averaging over the frame. The guards are computed on frame-wide means, so a picture that is noise at the top and frozen at the bottom passes "structure 0.05–0.42" on average.

**Conclusion.** The searched dictionaries are optimal for "frame + dictionary", not for the rule. Any sentence that the search found rules with "many regimes" must say "under the gradient frame". This is also the strongest evidence yet for Physics #5.

### b2. Is design-vote's "no head fits" exhaustive?

It is exhaustive only inside a template. `parse()` (design-vote.mjs l.38–54) accepts:

- no literals (l.42);
- all copies at one distance, with 32 ≤ d ≤ 64 (6-bit explicit distance; l.46 and l.52);
- one transform for all copies (l.48);
- exactly 32 bytes in total;
- all within the first four enumerated cell bytes, 80 joint bits (`NTAIL=4`, l.57).

The nibble and 2-bit joinings get 0 parses under these rules. The result note (design-vote.md: "no copy command survives that constraint at any header width tried") reads as a property of the decoder. It is a property of the single-word, single-distance head. Untested alternatives:

- heads with literals;
- mixed distances that assemble the next state from several dictionary pieces;
- longer heads (`NTAIL` 5–6).

Each of these is a small enumeration (`NTAIL=5` multiplies 16.8 M tails by about 64). Either run them or reword the note to "no head of the single-word form".

### b3. Do census features predict lattice outcomes?

From the 26 long-window designs (design-gray3 §8; each a single seed, 256², 1,000 turns):

- **Stray share predicts ordering perfectly.** All 4 dictionaries with ≥ 5.6 % stray never order; all 22 with ≤ 0.3 % order.
- **Among the 22 that order, census features do not predict coexistence.** Spearman ρ between species alive and on-cycle-by-8 is −0.08, transient mean 0.10, species count 0.14, stray 0.14.

So the census is a good feasibility filter but not an objective for coexistence. The claimed predictor, reading length, is not tabulated per dictionary, so it cannot be checked; it needs a table and multiple seeds. One seed per row makes "7 alive at 24 species" an anecdote.

### b4. A MAP-Elites redesign for the dictionary paper

- **Stage 1 (map level, cheap).** Run MAP-Elites over dictionaries with census descriptors as the behaviour space: number of attractors with basin > 1 %, dominant period (bins 1, 2, 3–4, 5–8, 9–32, > 32), and stray share (log bins).
  - Feasibility: stray share < 0.5 % (from b3).
  - Fitness: the funnel, on-cycle within 8 steps.
  - Seed the archive with texts, the searched dictionaries and the designed ones, and use the swarm's operators unchanged.
  - Census of 2,000 cells: about 0.1 s per evaluation, so 10⁵ evaluations take a few CPU-hours.
- **Stage 2 (lattice).** Re-evaluate every elite on 5 held-out seeds at 3–4 uniform parameter points. Use descriptors unrelated to the stage-1 objective, as the ALife postdoc asked: connected correlation length (Physics #1), the number of surviving types, and LZ76 of the frame (Information).
  - Report coverage and QD-score with bootstrap CIs.
  - Present the frame only as a visualisation, never as the evaluation.
- This turns "which dictionary properties make which lattice phenomena" into a regression across an archive rather than anecdotes about named dictionaries.

## (c) Methodology fixes

| fix | cost | claims that depend on it |
|---|---|---|
| Fix or retire the double-precision LCG in ca-search and ca-lattice-search (period 10,466; all seeds share one cycle); say the seeds were not independent | minutes, plus one sentence | any statement about search reliability or repeated runs (Codebook 1–9, Brotli 1–15) |
| Re-score the whole menu on 5+ held-out seeds, both orders, frame and 3 uniform points; report mean ± CI and the raw modes alongside the gated score | ~40 dictionaries × 5 seeds × 5 settings ≈ 1,000 evaluations ≈ 2 CPU-h | Q3 "searched dictionaries differ in kind", every "many regimes" caption, the menu ordering |
| Reword "found by search for many regimes" to "selected under the gradient frame; diversity vanishes or reorders under uniform parameters" | text | Introduction l.98–104, the draft's search section, Claim 2 |
| Shuffle distribution: 30 byte-shuffles and 30 word-shuffles of F with census and score | ~1 CPU-h | "byte order sets the cycle" as a statement about typicality |
| Widen design-vote's enumeration (literals, mixed distances, `NTAIL` 5–6), or reword "no head fits" | CPU-hours, or one line | design-vote.md impossibility claims for the nibble and 2-bit joinings |
| Multi-seed (≥ 5) lattice runs for the design-gray3 §7–8 tables, plus a per-dictionary reading-length column | 26 × 5 runs at 256², about 1 batch | "reading length decides the winner", "six species coexist", "stray cycles are fatal" (likely to survive) |
| Log parent, operator, seed, commit and dictionary SHA for every accepted child; stop silent reseeding from earlier runs, or record it | small code change | the provenance of F and of every named dictionary |
| MAP-Elites census-then-lattice study | 1–2 days of CPU | only the dictionary paper; not needed for the physics paper |
