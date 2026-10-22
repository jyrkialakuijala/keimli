# Second panel review of Keimli: synthesis

2026-10-22. The same seven roles as the first panel (../team/SYNTHESIS.md, 2026-10-21), reviewing the project after
the experiments of 2026-10-21 that answered the first panel and the twelve journal editors (../journals/RESPONSE.md).
Two rounds; each reviewer kept their own context from the first panel and read the others' round-1 notes before
round 2. The notes are `round1-*.md` and `round2-*.md` in this folder (about 42,000 words); BRIEF.md is the brief.
Where a number is quoted, the note that produced it is named. Every reviewer checked at least three numbers against
the data or by rerunning; what they checked is listed in §6.

## 1. The verdict

The experiments answered the first panel. The map spine is exact where it can be and honest where it cannot. Two or
more reviewers independently reproduced the fixed-point count (68,964,123 in 15,693 families; computation on 16
threads, mathematics, professor), the random-map nulls and the collision law (mathematics: every Flajolet–Odlyzko
constant checks), the Kaplan–Meier medians from the per-seed rows (731 / 920 / 992 and 373 / 505 / 584; five
reviewers), the r = 0.79 (all seven), Lemma 3 and the Gray closure proposition (mathematics, information, physics).
The retractions are complete inside results/. The processor arm produced two clean results and one contrast that is
now the project's sharpest: BFF inherits 80–85 % of single-byte mutations, Keimli 0 of 2,944.

But the mechanism behind the central lattice sentence, "the medium, not the basin, picks the winner", has to be
rewritten, because the panel found that the experiments behind it ran on two different media (§2). When three
reviewers reran the uniform-parameter experiments at the page's settling, the story changed in kind: there is no melt
and no nucleation; closed types are created by the medium inside coherent domains of the open cycle and invade them
by a moving wall. The result survives; its explanation does not, and the words "melt", "nucleate" and the size ratio
must go.

Nothing written for the paper reflects any of it. All nine retracted sentences stand in every draft; results/README.md
still asserts "no fixed points" and "hash pinning"; six results files and two figures carry the old numbers; the
co-authorship of the 2024 Computational Life study is declared nowhere.

The first paper is a map paper for *Artificial Life* (Complex Systems or the Journal of Cellular Automata as
fall-backs), with the heredity contrast as its closing section. The second paper is the origin and heredity of
replicators in BFF, Core War and a constructed replicase, with an outside co-author. The panel's estimate for the
first: about eight working days and 55 CPU-hours, of which four days are writing. The thesis "entropy reduction
against computation" found no measurement in its favour and should be replaced (§4).

## 2. The finding of the panel: the settling-pass mismatch

The physicist found it (round1-physics §2.2) and the information theorist and computation reviewer extended it: the
scripts closure.mjs, droplets.mjs, heredity.mjs, infodyn.mjs, entropy-curves.mjs, dose.mjs and replicase.mjs run **one**
settling (majority) pass; frame-mechanism.mjs, replicators.mjs and ablation.mjs run the page's **three**. No results
file states the pass count. So mechanism.md's §2–3 (closure, droplets, whole-lattice survival) and §5 (mutant patches)
and the frame maps of §4 are about different automata, and the sentence "closed types nucleate in the melt and fill
it" joins the two.

What the one-pass droplet tracks actually show (physics, mathematics, professor, each from the data): at every
partial-settling point with mixing the closed fixed point's own droplet dies (gone by turn 40–200) and nothing refills
the melt in 400 turns.

Three reviewers then reran the protocol at three passes in round 2 (Brotli 12, 128², optimization at swap 0.1 and
mathematics and computation at several settings), and agree:
- the open 3-cycle does **not** melt at median ½: a random-phase sea re-coheres to 84–100 % (one pass: 0–1 %);
- the fixed point is **created inside pure cycle domains** with no fixed-point cell present: 10–37 % by turn 400 at
  (½, ½) (computation);
- its droplets **invade the coherent sea** by a moving wall: 5 → 24–30 % at swap 0.1, 5 → 71–97 % at swap ½, while
  the reverse droplet (cycle in a fixed-point sea) is erased (mathematics, optimization, computation).

And the seed-origin question the mathematician raised in round 1 ("seeds come from the start") was settled in the same
round by the computation reviewer: removing every isolated-basin cell at turn 0 (verified none remain) leaves the frame
result unchanged (52–60 % against 53–58 %, first seen at turn 10, three seeds). **The medium makes the seeds.** The
mathematician withdrew the hypothesis on reading this.

So the mechanism at the page's settings is: *mixing with partial settling creates the closed type inside the open
cycle's domains; the closed type's walls advance into the cycle, the cycle's walls do not advance into it.* Melting of
the open type is real but only at one pass (and for four generic cycles, Swarm F added independently by three
reviewers). Closure (Lemma 1, the §4 proposition) still explains why the closed type holds; it does not explain why its
wall advances, which is the open question for A1 below.

## 3. The other corrections, ranked by the panel

1. **"Nucleation", "1.35–1.6× for a fourfold side", and t₅₀.** Retire all three (physics §2.3, computation 2,
   mathematics 9, professor). The fixed point's share curve on the frame is identical at 128², 256² and 512² (18 % at
   turn 20, 29 % at 50, 37–39 % at 200); the times to 25 % and 40 % agree within 5 % across sizes; only the 50 % mark,
   sitting on the 53–57 % plateau, moves. Brotli 13 shows a real but small late lag at 512² (physics round 2), so
   "size-independent establishment within the decoder's transient, then logarithmic creep" is the statement. No
   critical radius was measured, so "nucleation" is unjustified; say seeded growth or invasion.
2. **r = 0.79 is a 2 × 2 table.** Ten of the fifteen types are closed by theorem (four fixed points by Lemma 1, five
   Gray cycles by the proposition) and sit at (100 %, 100 %); over the five generic cycles r is 0.57–0.61, and the two
   95 % types die. Report the counts (closed 10 of 10 hold, open 4 of 4 melt at one pass, with the Swarm F row), the
   (r, steps) sensitivity (at eight steps the 11-cycle is 100 % closed and dies: optimization), and the basin-against-
   survival correlation −0.57, which is the thesis's own quantity (optimization; the physicist notes it has the same
   degeneracy). Replace the one-step index with a per-turn return rate against the disturbance rate and its
   threshold p*(type, median) at three passes: the professor's p*, the physicist's item 3, the information theorist's
   return time and the mathematician's whole-turn closure are one experiment, named four ways.
3. **Rows presented as measurements that are not.** The Declaration: kmax = 64 in all three v2 shells while its cycles
   have periods 154 and 182, so "no takeover" is a detector limit and RESPONSE.md row 4 is wrong for the one case it
   was for (computation). The 6502 and Redcode single-cell shares: read from partly overwritten logs, no JSON written,
   three seeds not five (ALife, computation). Brainfuck ignores the budget. The replicase log₂ up/down figure (7.48
   against 11.47) is two definitions across script versions on the same data (ALife).
4. **The drafts and the index.** Every reviewer: the nine false sentences (no fixed points, 1/(N·b), 2^93.5, front
   speed 716 / 1,093, t^⅓ hash pinning, ξ ≈ 60, "nothing replicates, nothing is selected") stand in INTRODUCTION,
   INTRODUCTION_MOTIVATION, RESULTS_REPLICATORS and RELATED_WORK §2; results/README.md, decoder-map.md l.38,
   design-gray3.md, docs/lattice.md and band.js still carry them; the two replicator figures predate v2.
5. **Errors in the results text.** replicators-v2.md says the Gray designs' leaders reach 90 % by turns 86–95; gray3c
   never does (67–69 %, two leaders) (optimization). mechanism.md l.56 says the 11-cycle survives mixing alone; it dies
   at median 0 (optimization, ALife). The "new attractor (heritable)" column in mechanism.md §5 is conversion, not
   heredity; Keimli's heritable count is 0 of 2,944 (ALife). Hand-copied 39 / 94 against 38 / 95 in the data. N is
   131,044 (362²), not 131,072, in two files (information). finite-size.md's "size-independent frozen length" holds at
   (½, 1) (ξ 12.4 → 12.6, z = 0.00) but not at (0.2, ½), where ξ grows as t^0.26 at 512² to turn 2,000; the coarsening
   exponent the author lists as "not done" is on disk in series.csv, z ≈ 0.36 ± 0.03 (physics).
6. **DEFINITION.md.** Lemmas 1–3 and the §4 proposition are correct, and the proposition is stronger than stated: it
   covers any bitwise combination of any number of same-type states, so settling at any radius (mathematics, verified on
   120,000 crossovers and 60,000 majorities). Errors: the Gray pointer lemma's prefix is 48 bits / 30 command bits /
   80-bit tail, not 46 / 28 / 82; Lemma 3's look-and-say remark has its formula inverted (128 / (2(1 − 1/b))), and the
   stopping time is one digit longer than the table because the rule reads the digit that ends the last run: 72.3 /
   87.1 / 98.9 bits, not 68.3 / 85.1 / 97.9 (information, confirmed by mathematics and computation). Cross-type closure
   is not covered and must be labelled empirical, except the new corollary: species whose H₀ differ in one header bit
   are mutually closed (gray3c B × C 10,000 of 10,000; A × B 57 % strangers), so a Gray code over the header bits would
   make every interface unmeltable (mathematics). New exact result: ca-gray3c has exactly 2,544 fixed points (240
   isolated strays, 9 families), including the first panel's stray.
7. **Entropy and information dynamics.** Collision entropy is "exact" only where H = H₂; "the decoder loses about 110
   bits in its first step" reads a collision figure as a Shannon loss, which is bracketed [40.5, 111.4] with the header
   correction, not measured. Infodyn's "rest" is neither an upper nor a lower bound (direction stated wrongly), its
   "non-local" part is mostly within-cell cross-bit dependence, and the decomposition is representation-dependent: it
   is not a measure of computation. The missing medium-alone control was run (identity rewrite: rest 0.04 at median 1,
   0.11 at median ½), so the decoder's 0.77–0.99 residual is the decoder's (information).
8. **Pipeline.** The harness hash on all mechanism data matches no commit (cured by the three-pass rerun); entropy-curves
   output and lead files lack provenance stamps; the harness still defaults to the fixed swap order; the search tools
   still carry the broken LCG and the seed-11 single evaluation; the page has two engines and no parity test; the
   Brotli 13 trailing newline is immaterial (same five attractors, basins within 0.05 %) (computation, optimization).

## 4. The thesis and the venue

Unchanged venue: *Artificial Life* first. The thesis, in the professor's revised words, amended by the three-pass
finding:

*A dictionary decoder as a cellular-automaton rule has an exactly countable attractor set (68,964,123 fixed points in
15,693 families, one 3-cycle with 99.995 % of the basin) whose structure is carried by the dictionary's words and not
by any random map with its one-step law; attractors can be built into it and proved closed; in a medium of exchange
and majority, a type holds a region if its own states' bit exchanges return to the type, and the medium creates the
closed types inside the open cycle's domains and advances their walls, so fixed points and designed cycles displace
large-basin open cycles where mixing is strong and settling partial, while the open cycle re-forms where no closed
type is present; and the surviving types have no heredity of variants, which separates them from the replicators of
BFF by exactly the bytes a copier does not read.*

The processor arm's thesis is heredity, not computation. The panel adopts the mathematician's definition: *the
heritable information of a replicator is log₂ the size of the fixed-point family it belongs to, the bytes the map
copies without reading* (BFF 48–54 such bytes, Keimli's families 0–3, the imp none), with the ALife reviewer's two
refinements: it is capacity, and heredity needs a transmission step (BFF has one, half per encounter because R must be
in the first slot; Keimli's families do not). The BFF census refutes "listed, not born" for BFF's own origin (a target
of order 2^−100 is reached by the walk), and the paper must say so (ALife; conceded by the professor). The word
"computation" leaves the thesis: no measurement in the project shows it doing anything, and the one decomposition
tried returned a representation-dependent null (information, professor).

Where the panel disagrees with itself: the mathematician holds that mutual closure of Gray types is a theorem under
the one-header-bit condition, against three reviewers who call cross-closure empirical; both are right about different
pairs. The physicist disputes the optimizer's −0.57 as degenerate like r. The ALife reviewer wants the heredity
contrast in paper 1; the professor conceded the table, not the origin section.

## 5. The work plan

The professor's deduplicated plan (round2-professor.md §5) stands, with A2 partly done in round 2 (the basin-cells-
removed test and the three-pass droplets exist for Brotli 12 at 128², n = 1–3; data/review2/). Paper 1, about eight
working days and 55 CPU-hours:

- **A1, first and decisive (1 day, 35 CPU-h):** the mechanism block at three passes with seed as a parameter (n ≥ 3):
  closure, droplets, whole-lattice survival, mutant patches, for every type with basin > 1 % in Brotli 1, 9, 12, 13,
  Swarm F, gray3c / 20c / 32c, cyc5to12 and the Declaration; predictions written before the runs; the physicist's full
  specification is in round2-physics.md §4 (12 settings, 5 seeds, 128², 2,000 turns, pre-melted sea and
  start-replacement arms).
- **A2–A7 (1.2 days, 17 CPU-h):** seed origin at 20 seeds and the lattice-basin grid; the radius series; the return-
  rate curve and p*; frame maps for Swarm F and gray3c; exact fixed points of Brotli 12, 13 and every Gray design; the
  Declaration at kmax = 200.
- **B1–B3 (2.5 days):** DEFINITION.md corrections; every results file regenerated from data with passes stated;
  README as an index with superseded banners; the figures regenerated; provenance everywhere; the harness default;
  the search tools' generator retired with one honest paragraph.
- **C, D (0.8 days, 5 CPU-h):** entropy calibration on a non-flat known map; the design-winner rules at 5 seeds.
- **E (3–4 days):** the writing, on both claims tables, with the nine sentences out, the co-authorship declared, the
  vocabulary fixed (melt defined; attractor types and domain competition; no nucleation, front or coarsening), the
  citations added (Hopfield 1982, Eigen 1971, Wilke 2001, Vasas–Szathmáry–Santos 2010, Kaneko, Lempel–Ziv 1976, Levin
  1974, the Zenil fix), and the heredity contrast table as the closing section.

Paper 2 (F, G): about 80 CPU-hours and one to two weeks (single-cell dose at 5 seeds, infodyn at k = 4 with the
identity control, the 6502 and Redcode reruns on the fixed script, the imp mutant census, the random-tape self-copier
count, 20 BFF soups, the family-size census), plus an outside co-author from the BFF community. H (the medium's
physics at 1024²–2048²) only for a physics paper, which the panel advises against.

## 6. What was checked, by whom

- **Computation:** the exact count on 16 threads; a Brotli 12 frame run byte-identical to the stored lead curve;
  the replicator and closure tables regenerated; the finite-size summary including 1024²; two Z80 dose rows; the
  three-pass mechanism rerun and the basin-cells-removed test (round 2); the one-digit count.
- **Optimization:** r from the raw JSON; Brotli 12 closure 38 / 100 % by a fresh 4,000-sample run; four KM medians;
  Swarm F's 3-cycle under the droplet protocol (melts at one pass, holds at median 1); the three-pass rerun (round 2).
- **Mathematics:** Lemma 1 test and the Lemma 2 radius in lattice.wat; the full census; H₂ decay at k = 1 / 4 / 16 /
  64; the Flajolet–Odlyzko constants; the proposition on 180,000 samples; the gray3c exact census; the three-pass
  droplets (round 2).
- **ALife:** r; the five KM medians; the closure rerun; Brotli 12 heredity counts; the BFF self-test and cubff
  validation to the byte; the Fig. 4 census (87.0 / 0.4 / 0.0 / 12.6, 48 neutral); the imp t₅₀ median 144.
- **Professor:** r and its restrictions (0.74 on non-Gray, 0.61 on generic); the exact search on four headers; rule 90
  and Swarm F entropy curves; the table regenerated byte-identically; the pass counts and kmax in every script.
- **Physics:** an MS− quenched run reproduced bit for bit (ξ 11.6 against 11.65); r, Spearman 0.995; the KM medians;
  the share curves by size; ξ(t) and local exponents from series.csv; the lemma test.
- **Information:** rule 90 calibration against exact loss; r with and without the borderline types; the decoder's first
  step on 2 × 10⁵ cells (93.49 bits, H₂ 16.56); the look-and-say digit count; every infodyn row, plus the identity
  control it lacked.

## 7. Against the first panel

The first panel said: a publishable map paper exists; the drafts describe a different, unproven one; the processor arm
is a programme. The second says: the map paper is now built and checked; its mechanism needs one more day of
experiments at the right settings and a rewrite of its vocabulary; the processor arm has become a result about
heredity, not about computation, and the paper should say so; and the drafts have not moved. The minimum work has
fallen from one to three weeks to about eight days for paper 1, with most of it writing.
