# Round 1 (second panel): statistical physics and statistics

2026-10-22. Continuity: my first-panel notes asked for E0 (connected correlations), E1 (salt controls), E2 (the
coarsening exponent from several sizes), E3 (the transition), E6 (takeover mechanism: front, nucleation or creep,
with droplets) and censoring-aware statistics. E0, E1 and the statistics are done; E6 was attempted; E2 was run but
not analysed; E3 was not run and is now rightly demoted to "crossover" in DEFINITION.md §5.

## 0. What I checked myself

All read-only on `paper/data/`, plus one 14-second run and two scripts in `paper/data/review2/` (`r079.mjs`,
`km.mjs`).

1. **The MS− frozen length, by rerun.** `ablation.mjs cond=MS- pm=0.5 ps=1 salt=0 seed=1 n=128 turns=2000` reproduces
   the stored run `ablation-sizes/MS--decoder-pm0.5-ps1-salt0-n128-...-seed1` bit for bit (d1 = 9.7995 × 10⁻⁴ and all
   twelve connected C(r) values identical: 0.894 at r = 1, 0.502 at 8, 0.313 at 12). Log-interpolating the C(1)/e
   crossing by hand gives ξ_c = 11.6 against the reported 11.65. The pipeline is deterministic and reproducible.
2. **r = 0.79.** Recomputed from the 15 rows of `closure-vs-survival.md`: Pearson 0.790, Spearman 0.995. Without the
   two 5-to-12 generic cycles, r = 0.98. The 2 × 2 table is perfectly separated: 10 closed types survive, 5 open ones
   die, no exception (§2 below on what that is worth).
3. **The Kaplan–Meier medians.** From the per-seed `t50` in `replicators-v2/ca-brotli-12-page-*.json`: 731 (128²,
   20 of 20 events), 920 (256², 19 events, one censored at 1999 with a final share of 50 %), 992 (512², 10 events).
   All three agree with `replicators-table-v2.md`. The within-size spread is 235–1,336 at 128², a factor of six.
4. **The share curves behind those medians** (`*-lead.json`, mean over seeds, fixed-point share in %):

   | size | t 20 | 50 | 100 | 200 | 400 | 800 | 1,200 | 1,600 | 1,999 |
   |---|---|---|---|---|---|---|---|---|---|
   | 128² | 17.9 | 28.5 | 30.9 | 38.6 | 45.1 | 51.0 | 54.3 | 56.1 | 57.0 |
   | 256² | 18.1 | 29.2 | 31.0 | 36.8 | 43.8 | 48.6 | 51.3 | 53.3 | 54.4 |
   | 512² | 18.1 | 28.7 | 30.1 | 37.2 | 44.1 | 48.5 | 50.5 | 52.0 | 53.1 |

5. **ξ(t) from `ablation-sizes/series.csv`** (geometric mean of x and y, mean of 3 seeds), with local exponents
   z = d ln ξ / d ln t over 100–200, 200–400, 400–800, 800–1,600:

   | condition | 128² | 256² | 512² | z at 512² |
   |---|---|---|---|---|
   | MS− quenched (½, 1) | 10.6 → 11.7 → 11.7 (t 100, 400, 2,000) | 11.0 → 12.3 → 12.4 | 11.2 → 12.5 → 12.5 | 0.13, 0.03, 0.00, 0.00 |
   | MS− quenched (0.2, ½) | 11.5 → 16.3 → 22.0 | 12.0 → 18.0 → 26.4 | 12.1 → 18.5 → 27.8 | 0.32, 0.29, 0.26, 0.26 |
   | MS− turn-salted (½, 1) | 13.0 → 19.6 → 25.9 | 13.8 → 22.8 → 36.8 | 14.1 → 24.1 → 42.1 | 0.38, 0.38, 0.36, 0.34 |
   | MS− turn-salted (0.2, ½) | 12.9 → 20.0 → 27.3 | 13.5 → 23.0 → 37.4 | 13.7 → 24.3 → 44.6 | 0.42, 0.41, 0.40, 0.36 |

6. **The droplet time tracks** (`droplets-ca-brotli-12-n128-t400.json`, field `track`), fixed point #1 (radius 16,
   5 % of the lattice) in the 3-cycle sea, coherent phases: at swap 0.1 and median 0 / 0.25 / 0.5 the fixed point is
   at 0 % by turn 80 / 160 / 200 and the sea ends 99 / 99 / 84 % "other"; at swap 0.5 the same by turn 40–120. In
   random phases it is gone by turn 40 at every partial-settling point. At median 1 it holds at 5–6 % and does not
   grow (5.0 → 5.0 % coherent, 5 → 6 % random over 400 turns).
7. `test/lemma.test.mjs` passes (1 test, 0.2 s).

Taken on trust: the exact fixed-point count and its wasm verification, the BFF reproduction of cubff's log, the
heredity percentages, the dose-response and infodyn tables, and the entropy calibration.

## 1. Which concerns are settled (question 1)

1. **Connected correlations, settled.** `ablation.mjs` lines 105–113 subtract each plane's squared mean over the
   bulk region; the summary uses a C(1)/e crossing. The raw ξ ≈ 60 of the first batch is gone (`ablation-v2.md`).
   What remains unsettled is the observable for the full system: with the decoder, nearly every cell is on the
   3-cycle (distinct cells 0.001–0.05 of N at turn 2,000, `series.csv`), so the bit-plane correlation is a proxy for
   the Z₃ phase field, and its ξ(t) is non-monotone (512² quenched (0.2, ½): 31 → 53 → 48 → 51 over turns 400–2,000;
   256² turn-salted (½, 1): 38 at 1,600, 27 at 2,000). No MSR length should be quoted as a number until the phase
   field itself is correlated. This is my first-panel recommendation 1, half done.
2. **Deterministic freezing, settled at one point, wrong at the other.** At (½, 1) the quenched medium arrests:
   z = 0.00 from turn 400 on, d1 constant at 1.0 × 10⁻³, ξ_c 9.8 / 11.7 / 12.4 / 12.5 / 12.6 (64²–1024²). That is a
   clean, size-converged intrinsic length and supports the "blocked states of a deterministic vote" wording. At
   (0.2, ½), `finite-size.md` claims the same ("26.5 → 27.9, converged"), but the series shows ξ still growing as
   t^0.26 at 512² at turn 2,000, with d1 = 1.3 × 10⁻², ten times the frozen value. The agreement between 256² and 512²
   is agreement between two un-converged runs of equal length. Quenched (0.2, ½) is slow coarsening, not freezing.
3. **The coarsening exponent (E2), run but not read.** The author lists "the time dependence ξ(t)" as not done, yet
   `series.csv` holds it. At 512² the turn-salted medium gives z = 0.34–0.38 at (½, 1) and 0.36–0.42 at (0.2, ½),
   steady over 1.2 decades, with the 256² slope bending down after turn 800 as finite size bites. My first-panel
   objection (slope drifting 0.37 → 0.24 at 256²) is explained as finite size. So t^⅓ is not refuted; z ≈ 0.36 ± 0.03
   from one size is what can be said, and ⅓ against ½ is not yet decided (one 2048² seed over 4,000 turns, or 1024² at
   3 seeds, would decide it; the 1024² runs exist for the final turn only). Partly settled.
4. **Censoring, settled.** Kaplan–Meier over seeds with bootstrap intervals, no seed dropped (`replicators-summary2.mjs`,
   checked). The remaining problem is not censoring but the statistic: see §2.3.
5. **Salt controls (E1).** Not rerun. The "quenched disorder" wording is gone from the results but the sicilia2008
   citation and the sentence stand in `INTRODUCTION.md` line 115 and `INTRODUCTION_MOTIVATION.md` line 151. My two-seed
   salt-by-position result from the first panel is still the only evidence that position salting freezes like salt 0;
   it needs 10 seeds before it is printed.
6. **The transition (E3).** Not run, and DEFINITION.md §5 now says "crossover unless finite-size scaling shows
   otherwise". That is the right discipline. `INTRODUCTION_MOTIVATION.md` line 136 still says "a sharp transition".
7. **The takeover mechanism (E6).** Attempted, with one defect that undoes the comparison (§2.2) and one statistic
   that misleads (§2.3).

## 2. The central result (question 2)

1. **What is proved, and what the proof covers.** Lemma 1 and its corollary are correct and the test passes.
   Lemma 2's range (mixing partner at distance 1, since decisions are read from the snapshot) is right. Lemma 3 is
   the standard identity H(U₁…U_τ) = E[τ] for a bounded stopping time on fair bits. The closure proposition of §4 is
   correct: every bitwise combination of same-type states keeps the common 43 prefix bits, header bits 4–6 become some
   pattern, the Gray map is a bijection on 3 bits, so the pointer lemma applies and f returns a type state. It also
   covers nine-cell majorities and sequential exchanges across the four phases, since each bit of the result still
   comes from some state of the type. It does not cover combinations of two different Gray types (the C(A, B) = 100 %
   of `closure-ca-gray3c.md` is empirical) and says nothing about stray attractors; §4 says so.
2. **The droplet and frame experiments are not at the same settling.** `droplets.mjs` line 20 and `closure.mjs` set
   `passes: 1`; `frame-mechanism.mjs` line 17 and `replicators.mjs` use `passes: 3`, the page's default
   (DEFINITION.md §2, `ca-harness.mjs` line 16). `mechanism.md` states the swap order and the hashing but not the
   passes. So §2–3 of mechanism.md (closure, droplets, whole-lattice survival, hence the r = 0.79 table) are at one
   third of the settling of §4 (the frame). The tracks in §0.6 show what that costs: at one pass, the closed fixed
   point's droplet is destroyed by the melting cycle sea at every partial-settling point, in both phase modes, and
   the lattice ends 84–99 % transients; at the same (swap, median) on the three-pass frame the fixed point ends at
   100 %. The sentence "closed types nucleate in the melt and fill it" therefore has no uniform-parameter experiment
   behind it. Either the droplets are rerun at three passes, or the frame at one, before the mechanism is stated.
   Note also that each droplet cell is one realisation (`let rs = 1`, line 38): n = 1 throughout the droplet tables.
3. **"Nucleation" is not established, and t₅₀ is still the wrong statistic.** The share curves (§0.4) are the same
   at 128², 256² and 512² to within 3 points up to turn 400, and differ afterwards only in the asymptote (57, 54,
   53 %). The fixed point holds 18 % of the frame at turn 20 and 29 % at turn 50; after turn 200 it gains 5–6 points
   per doubling of time at every size, logarithmic creep. The reported "1.35× for a fourfold side" is the asymptote
   crossing 50 %, exactly the plateau artefact I described in the first panel, and the bootstrap intervals
   [560, 912] and [688, 1445] overlap. Brotli 13's 1.57× (intervals disjoint) is also an asymptote effect (67 → 63 %).
   The honest statement is: establishment of the fixed point across the mixing rows within the decoder's transient,
   size-free, then logarithmic wall creep; t₁₀ = 59–61 at all sizes is the one time statistic that means something.
   "Nucleation" requires a barrier, hence a critical radius; no radius series was run (R = 16 only), and at one pass
   even R = 16 dies. Until a radius series shows a critical R, write "seeded growth from the melt", not nucleation.
   "Slow coarsening" after takeover is likewise unmeasured (no domain-size series of the fixed-point regions).
4. **Is the closure index the right quantity?** It is a correct sufficient condition, by the proposition, and the
   data say nothing beyond that. Of the 15 types, 4 are fixed points (closed by Lemma 1) and 5 are designed cycles
   (closed by the proposition): their survival is the theorem, not a test of the index. The 6 generic cycles are the
   test, and among them closure does not grade survival: the two at 95 % die as surely as the ones at 6–11 %. So the
   index is binary in practice, "exactly 1 or not", and the 95 % types show that a 5 % leak per turn is enough to
   dissolve a domain in 400 turns at one pass. What would make it a quantity: a survival threshold in the mixing
   rate p*(type) for the five generic cycles, compared with 1 − C. Also, the index is measured at crossover rate
   r = 0.25 while the survival runs are at swap 0.1 (exchange rate 0.18): say so.
5. **Is r = 0.79 enough?** It is the wrong summary. The scatter is ten points at (1, 1) and five near (x, 0); Pearson
   measures the gap, and the two 95 % points drag it from 0.98 to 0.79. Report the 2 × 2 table (10/0/0/5, perfect
   separation) and say that four of the ten are trivial and five are designed. Fisher's exact p on 15 non-independent
   rows would be theatre; leave it out.
6. **Is the result explained?** Half. Why open cycles dissolve under mixing with partial settling: yes, by closure
   plus the droplet tracks. Why the closed fixed point then fills the melt on the frame, when at one pass its own
   droplet dies: no. The candidate explanation is the one I gave in the first panel: the medium with three passes
   maps transient cells into the fixed point's basin far more often than the isolated basin (0.26 %) suggests, since
   18 % of the frame is fixed point by turn 20. That is a lattice basin measurement, not a nucleation story, and it
   can be done directly: the share of transient cells that land on the fixed point after one three-pass turn, as a
   function of (swap, median).
7. **Vocabulary.** "Melt" is acceptable as a defined term for "a domain dissolves into transients", provided it is
   defined once and not read as a phase transition at a temperature. "Nucleation", "coarsening" (post-takeover) and
   "front" should go. "Absorbing state" for the uniform in-phase 3-cycle at 64²–128² is right by Lemma 1 (strictly an
   absorbing periodic orbit); "larger ones avoid it" is not shown: at 256² (0.2, ½) quenched, ξ drops from 32 to 13
   and distinct cells to 0.05 of N by turn 2,000, which looks like the approach to the same orbit, later.
   "Freezing" is right at (½, 1) only.

## 3. Retractions (question 3)

1. **Correlation length.** Retracted in `ablation-v2.md` and `RESPONSE.md`, but `results/README.md` still lists
   `ablation-main.md`, `ablation-structure.md`, `ablation-scan.md`, `design-gray3.md`, `swap-order.md` and
   `life-vote.md` as measured results with the raw ξ (39.8, "one domain", the 128/256/512 "scaling check", the
   "sharp transition between p = 0.3 and 0.5", ξy/ξx 1.37), and the hypotheses section still reads "coarsens as about
   t^⅓ ... hash pinning". Only `replicators.md` carries a superseded notice. Everything in those six files that is a
   length rests on the retracted observable; the swap-order anisotropy ratio survives (bias cancels in an x/y
   comparison, as I said before) but its magnitude should be recomputed connected.
2. **Front speed.** Retracted, replaced by "nucleation, 1.35×", which is wrong for the reasons in §2.3. The figures
   `replicators-takeover.png` and `replicators-basin-vs-takeover.png` (03:24 on 10-21) predate the v2 rerun, were made
   by `replicators-plot.py` from the censored batch, and encode the basin^−½ relation that is withdrawn. Not
   regenerated.
3. **Image bound.** Complete in DEFINITION.md; `INTRODUCTION_MOTIVATION.md` line 76 already says entropy, which is
   right. "No fixed points" still stands in `INTRODUCTION.md` line 56, `INTRODUCTION_MOTIVATION.md` line 77 and
   `RESULTS_REPLICATORS.md` line 26, against 68,964,123.
4. **Harness budget.** Fixed; earlier runs asked for 256 and got it. Fine.
5. **Other things resting on retracted numbers.** `RELATED_WORK.md` line 232 cites Bray for "the t^⅓ law" and
   Sicilia for "weak-disorder pinning" as if both were the paper's results; `RESULTS_REPLICATORS.md` lines 83–93 carry
   1/(N·b), the front, and "1.5 times longer at 128²" in full; `MOTIVATION.md` line 121 and `INTRODUCTION.md` line 99
   carry "the frame is the sweep". None of the drafts has been touched, as the brief says; the point is that the
   results README has not either.

## 4. The processor arm (question 4)

1. **What is a result.** BFF: 12 evolved replicators, each a fixed point of the pair map in one step for 256 of 256
   partners, and 100 % inheritance of changes to unread bytes (n = 240–270 per replicator). Redcode: the imp, a
   fixed point, takes 77 ± 12 % of the lattice at 256 instructions over 5 seeds, KM median 144 [114, 195] on the
   frame. The constructed replicase: heredity 1.00 against 0.00 by copy mode over 5 seeds, with the required negative
   control (trait inert gives log₂ up/down exactly 0). These three are results.
2. **What is a programme.** The claim is about "the replicators of computational life". The evidence covers one
   language of the 2024 study (BFF, 4 emergences in 8 soups, no rate), one Core War rule, and a rule built to the
   hypothesis. The single-cell dose-response and infodyn are seed 1 only; the 6502's 2-cycle at 16 instructions is one
   setting and non-monotone in the budget. "Heredity needs verbatim copying of unread tape" is shown necessary in the
   constructed rule and present in BFF; sufficiency in an evolved system is one data point. The "error threshold" in
   `replicase-ablation.md` §3 is a lethal-noise threshold at swap ≈ 0.01; Eigen's threshold is a relation between
   per-bit fidelity, genome length and selective advantage, and the table gives only the first and last at fixed
   length. Call it a noise threshold unless the length is varied.
3. **The inversion.** `infodyn.md` finds processors do less non-local processing per turn than the decoder. That is
   the opposite of the first drafts' dichotomy, and the second paper has to begin from it, not around it.
4. **Verdict.** A result for two systems plus a construction; a programme as a general claim. One more evolved
   language from the 2024 study (Forth or Z80 soups) with the same census, and 20 BFF soups for an emergence rate,
   would make it a result. That is CPU, not new ideas.

## 5. Thesis and venue (question 5)

The thesis has not changed since the first panel; the evidence under it has. It is now: a decoder as a CA rule has
an exact census (68,964,123 fixed points with basins ≤ 2 × 10⁻⁶ and one 3-cycle taking 99.995 %), its attractors can
be designed and their closure proved, and on the lattice a closed type beats a large-basin open one because mixing
dissolves open types (the proposition plus the droplet tracks). The medium's own physics is deterministic arrest at
(½, 1) against annealed coarsening with z ≈ 0.36. The computation-against-erasure dichotomy is the second paper and
currently points the other way. Venue for the first paper: Artificial Life or Complex Systems, as the editors said.
Physical Review E would need §6 items 3 and 5 and a phase-field observable; the ξ(t) analysis above is a start the
author already has on disk.

## 6. Minimum remaining work (question 6)

Costs from measured speeds: MS− 2.3 × 10⁶ cell-turns/s per core (14 s for 128² × 2,000), the decoder about
2.5 × 10⁵.

| # | experiment | runs | CPU-h | days | decides |
|---|---|---|---|---|---|
| 1 | Droplets and whole-lattice survival at three passes, 6 dictionaries, 3 seeds each cell (`droplets.mjs passes=3`, seed as a parameter) | ≈ 5,000 × 128² × 400 | 35 | 0.5 | whether the mechanism holds at the frame's settling |
| 2 | Radius series R ∈ {1, 2, 4, 8, 16, 32}, fixed point in 3-cycle and the reverse, Brotli 12 and 13, (0.1, ½), (0.5, ½), (0.1, 1), 5 seeds, 3 passes | 360 × 128² × 400 | 3 | 0.2 | critical radius or none: "nucleation" or "seeded growth" |
| 3 | Survival threshold p* for the 5 generic cycles: swap {0.01, 0.02, 0.05, 0.1, 0.2} × median {0.25, 0.5}, random phases, 3 seeds, 3 passes | 150 × 128² × 400 | 1 | 0.1 | makes the closure index quantitative |
| 4 | Lattice basin of the fixed point: share of transient cells landing on it after one three-pass turn, 8 × 8 (swap, median) grid, 5 seeds | 320 × 128² × 50 | 0.5 | 0.2 | the missing half of the explanation (§2.6) |
| 5 | Turn-salted MS− at 1024² × 3 seeds × 4,000 turns and 2048² × 1 × 8,000, both points; local slopes and collapse | 8 | 12 | 0.2 | z: ⅓ or ½ |
| 6 | Phase-field observable for MSR (cycle-phase label per cell, connected Z₃ correlation, equal-phase sampling), then rerun the ablation-v2 reference points | 170 × 256² × 1,000 | 12 | 1 | any MSR length claim |
| 7 | Seeds for the processor arm: dose single cells and infodyn at 3 seeds; 20 BFF soups at the paper's setting | | 40 | 1 | §4 |
| 8 | No CPU: share curves in place of t₅₀, the two replicator figures regenerated from v2, a superseded flag on the six results files, drafts rewritten on the claims tables | | 0 | 3 | |

About 100 CPU-h (four hours on 28 cores) and six working days, of which three are writing. Items 1–4 come first;
they decide whether the paper's central sentence stands.

## 7. Anything wrong (question 7)

1. `droplets.mjs` and `closure.mjs` at one settling pass against three in the frame and replicator scripts (§2.2).
   This is the finding that matters.
2. `finite-size.md` point 1: the (0.2, ½) quenched medium is coarsening at z ≈ 0.26, not frozen (§1.2).
3. `replicators-v2.md` point 2: "1.35–1.6×, nucleation not a front" is the asymptote crossing 50 %; the curves are
   size-free (§2.3).
4. `mechanism.md` §2: r = 0.79 reports a gap, not a gradation (§2.5); §3's "68 %" for the fixed-point sea at
   (0.1, ½) is a snapshot of a sea melting at 3 points per 40 turns, not an asymptote; the droplet tables are n = 1.
5. `finite-size.md` point 3: "larger lattices avoid" the absorbing orbit is not shown; 256² looks to be heading
   there (§2.7).
6. `results/README.md` still presents the retracted lengths, the t^⅓ and "hash pinning" as the project's state (§3.1).
7. Minor: `mechanism.md` quotes Brotli 12's 3-cycle closure as 39 %, the table says 38 %.
