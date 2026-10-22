# Round 2: scientific computation, methodology

2026-10-21. All runs below were made in my scratchpad with a copy of `replicators.mjs` that adds a swap-order option (`altOrder`). None took longer than three minutes. Nothing was written to `paper/data`.

## (a) Responses to the panel

**Physics: the correlation is not connected. Confirmed in code.** `ablation.mjs:91–103` computes `1 − 2⟨popcount(a⊕b)⟩/8` with no mean subtracted, and `corrPlanes` does the same per plane. Since `bulkStats` already computes `planeMag`, the connected version costs nothing: subtract ⟨m_j²⟩ per plane. I agree this is a precondition for every ξ claim (the correlation length, the t^⅓ coarsening, the transition, the pinned lengths).

**Physics: salt by position was never run. Confirmed.** `ls paper/data/ablation | grep -c salt2` gives 0, against 500 runs with salt1. The "annealed" mode adds one scalar per turn after the hash (`lattice.wat:47–50`, `$decide` = salt + mix64(key)), so identical contexts still decide alike across the whole lattice within a turn. I add a mechanism detail. The median's decision hashes only the cell's **own** 32-bit context at that bit (`lattice.wat:288–303`), not the neighbours, the bit index or the pass. All three passes get salt 0 under quenched hashing (`ca-harness.mjs:36`). So for a cell of given content, the set of bits that *may* be outvoted is a fixed function of that content. At median p < 1, "p" is therefore a content-dependent mask, not a rate, and repeating a pass on an unchanged cell can only act where the majority itself changed. That is pinning by construction, and it supports physics's "deterministic freezing, not disorder". The swap decision has the same property along the ring: `$ctx` excludes bit i and the index is not hashed, so the rule is invariant under rotating both cells together.

**Physics and mathematics: takeover is not a front, and the "1.5×" figure is an artefact. My check makes this stronger.** `replicators-summary.mjs:7` takes the median after *dropping seeds that never reached the mark* (`filter(v => v !== null)`), and picks the upper middle element. For Brotli 12, page frame, 128², the per-seed turns to 50 % are 298, 1336, never, never, 716, so the published "716" is the median of the three seeds that got there. Counting "never" as more than 2,000, the median is 1,336, against 1,093 at 256². **The size effect reverses sign.** Brotli 13 is uncensored and gives 354 → 585 (×1.65), not the ×2 a front predicts. Brotli 12's seed scatter alone is ×4.5 at 128². Physics's point that "50 %" sits at the saturation tail of a 53 % final share applies on top of this.

**Professor: does the detector's limit of period 12 bias the result? Yes, decisively, for the texts.** The short batch ran with `kmax=12`, and the Declaration's attractors have periods 154 and 182 (`ablation-main.md` §1). Every Declaration row in `replicators-table.md` reads "0 %, 0 species". The claim "no late first appearance" is therefore *unmeasurable* for exactly the dictionaries closest to code-like text. replicators.md l.86 half-admits this, but RESULTS_REPLICATORS states the claim without the restriction.

**Mathematics (concern 6) and ALife: the basin is not the lattice basin. I have the experiment.** Brotli 12, page frame, rotating order, 5 seeds, first turn at which the fixed point is seen:

| n | isolated basin | 1/(Nb) | first seen (5 seeds) |
|---|---|---|---|
| 32 | 0 cells of 1,024 | ∞ | 20, 23, 24, 34, 58 |
| 64 | 0.32 % | 0.08 | 12, 17, 21, 24, 31 |
| 128 | 0.26 % | 0.02 | 7, 8, 11, 12, 15 |
| 256 | 0.34 % | 0.004 | 7, 8, 10, 11, 12 |

At 32² the decoder alone finds **no** cell in the fixed point's basin, yet the lattice produces the fixed point by turn 20 to 58. The medium *creates* basin entries; it does not just sample them. At large N the first appearance saturates at about the transient length (7 to 12 turns), not at 1/(Nb) < 1. The conclusion "present from the start" survives at 128² and above, but the stated mechanism is wrong. The detector also certifies lattice-periodic cells, not f-cycles: the species with basin 0.00 % in the table (Brotli 1, cyc5to12, Brotli 12 uniform) are cycles made by the lattice. Those, not the listed attractors, are the candidates for genuine late appearances, and the text should say so.

**Optimization: the broken LCG and the single scoring seed.** I did not re-verify these. The doubles argument is right: 1103515245 × 2³¹ > 2⁵³. One correction to the citation: the harness's `altOrder` default is at `ca-harness.mjs:17`, not l.433.

**Mathematics: docs contradict the default. Confirmed and extended.** `docs/lattice.md:105` and the header comment of `band.js` (l.10–12) both say "always the same order UD0 LR0 UD1 LR1".

**Information: Rényi-2 bound.** The arithmetic checks: ≥ 11,716 colliding pairs / C(10⁶, 2) gives H₂ ≤ 25.3 bits. I agree it should be reported.

## (b) Deep dive

**1. Is fixed-versus-rotate order material for the replicator claims?** I ran 128², 2,000 turns, seeds 1 to 3, `kmax=12`, both orders. **Reproducibility first:** my fixed-order rerun matched the stored `ca-brotli-12-page-n128-t2000.json`, `ca-brotli-13-…` and `ca-swarm-f-pm0.5-ps1-…` seed for seed, to the turn (t50 = 298, 1336, never; 312, 316, 392; 13, 13, 12). The present wasm and harness reproduce the short batch exactly. Good.

| dictionary, setting | fixed: winner, final, t50 | rotate: winner, final, t50 |
|---|---|---|
| Brotli 12, frame | fixed point, 46–58 %, 298 / 1336 / never | fixed point, 52–58 %, 719 / 878 / 1336 |
| Brotli 13, frame | fixed point, 59–63 %, 312–392 | fixed point, 65 %, 304–477 |
| Swarm F, uniform | 3-cycle, 98–99 %, t90 31–38 | 3-cycle, 99.5 %, t90 35–52 |
| Gray 20, frame | 8-cycle, 39–41 % | 8-cycle, 39–40 % |

The winners, final shares and first appearances are unchanged. Times move within the seed scatter. So the order flaw matters little for the qualitative replicator claims. It still matters for any anisotropy or ξ claim (swap-order.md: C(8) 0.680 against 0.735). It must still be fixed for honesty: "page frame" should mean the page.

**2. Provenance.** The stored JSON can be regenerated (item 1), but only because I knew which options to add. The 20,000-turn files came from an earlier script version: every species is first seen at turn 32, and there are no `changer/steps/salt` fields. Yet their t50 values equal the short runs' (1546, 1093, 1112). The dynamics are stable and the detector changed between versions. `replicators-summary.mjs` mixes both versions into one table without a turns column.

**3. Second turn engine: a concrete parity defect.** In the page's single-thread engine (`lattice.html:868–889`), the vote partner's snapshot is copied to `GRID2` (cell 0 upward). Then `wasm.influence(N, GRID, PRM, GRID2, …)` runs whenever `N ≤ 65536` and a pair mode is set. It always stores five i32 at `scr = GRID2` (`decode.wat:470–472`), even in vote mode, where it computes nothing. This zeroes snapshot cell 0 and the first 4 bytes of cell 1. `change()` then reads the corrupted snapshot for the votes of cells (1,0), (0,1), (0,0), (2,0) and (1,1). In the band pipeline, `influence` runs *before* the snapshot copy (`band.js:93–95`), so there is no clash. With Threads = 1 (the default), vote modes on grids up to 256², the page differs from the workers in the top-left corner, and the difference can spread. It touches no paper data, because the harness never sets `influence`. It is exactly the class of bug that REVIEW_COMPUTATION §1 predicted from two implementations.

**4. Detector integrity.** The FNV-1a hash is 32-bit per cell state. A false period-1 detection needs one collision between consecutive states: about 2⁻³² per cell-turn, so about 0.03 events in a 256² × 2,000 run. Negligible. Species IDs are 32-bit as well; collisions among about 2,000 species per run are around 10⁻³. The ring indexing in `periodOf` is correct for k ≤ (t+1)/2.

## (c) Methodology fixes

| # | fix | cost | claims depending on it |
|---|---|---|---|
| 1 | Record a provenance block in every output: git commit plus dirty flag, wasm SHA-256, script SHA, dictionary SHA, swap order, salt mode, kmax, turns. Make the summary refuse mixed versions | 1 h | every table; the t20000 rows |
| 2 | Pass `altOrder:'rotate'` in `replicators.mjs` and `species-run.mjs`, and make it the harness default, or make "frame" mean the page's settings line | 15 min plus rerun (short batch ≈ 3 h on 28 cores) | "page frame" rows; anisotropy; every ξ |
| 3 | Fix the censored median: treat "never" as more than T, report n reached/n and bootstrap CIs, use ≥ 10 seeds | 30 min plus rerun | takeover-vs-size, takeover-vs-basin, the "1.5×" figure (currently wrong in sign) |
| 4 | Measure first appearance against N at 32–512, plus the turn-by-turn input distribution to f on the lattice | 1 h, minutes of CPU | "never late", the 1/(Nb) mechanism |
| 5 | Raise kmax (or use cycle detection by hash table, unbounded) for the texts, or restrict the claim to short-period species | 1 h | Declaration and text rows; the generality of "no late appearance" |
| 6 | Use connected correlations and a phase-field correlation; uncap ξ (fit, or r up to L/4) | 2 h plus re-analysis of saved series (no snapshots are saved: rerun) | H1, t^⅓, the transition, pinning |
| 7 | Run salt-by-position and per-pass salts as distinct controls; name quenched as "deterministic", not "disorder" | 30 min plus batch | the pinning interpretation |
| 8 | One turn engine: make the page call `Band.runTurn` with one band; add a 1-vs-4-thread cell-parity self-test covering the vote, pair-write, sync and posalt modes | half a day | the page as the primary artifact; the vote presets |
| 9 | Fix docs/lattice.md and the band.js header on the swap order; tag results by order | 15 min | METHODS consistency |
| 10 | Archive the build (wasm hash, DOI) with the settings line per figure | 1 h | the reproducibility claim in METHODS |
