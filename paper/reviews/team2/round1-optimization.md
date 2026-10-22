# Round 1 (second panel): optimization and search

Reviewer: optimization specialist, continuing ../team/round1–3-optimization.md. Read in the brief's order: both
syntheses, RESPONSE.md, results/README.md and the twelve new results, DEFINITION.md, the unrewritten drafts, and the
scripts closure.mjs, closure-vs-survival.mjs, droplets.mjs, replicators-summary2.mjs, map-shuffles output, and the three
search tools. redesign.md and paper/data/redesign/ ignored as instructed.

## 0. What I checked myself

1. **r = 0.79** (mechanism.md §2, closure-vs-survival.md l.20). Recomputed from the raw JSON in data/closure/ and
   data/droplets/ with my own code: Pearson 0.791, Spearman 0.995. Reproduced. What the number means is finding 4.
2. **The closure values for Brotli 12** (38 % for the 3-cycle, 100 % for the fixed point at r = 0.25, one step).
   Reran `closure.mjs dict=ca-brotli-12 samples=4000` (5 s) into data/review2/closure/: 38 % / 100 %, and 64 % against
   65 % at eight steps. Reproduced.
3. **Kaplan–Meier medians** (replicators-table-v2.md). From the per-seed rows of the four aggregate JSON files, with my
   own KM code: Brotli 12 on the frame, 128², 731 (20 of 20 reach 50 %; raw times 235–1,336); 256², 920 with 19 of 20;
   Brotli 13 128², 373; Swarm F 128², 34. All four reproduced exactly.
4. **A prediction the table omits.** Swarm F's 3-cycle (self-closure 34 %, closure-ca-swarm-f.md) has no droplet run, so
   it is not among the 15 types. I ran the whole-lattice random-phase protocol of droplets.mjs for it inline (128², swap
   0.1, 400 turns, two phase seeds): share on the cycle 0.0 / 0.0 / 0.0–0.1 / 99.7–99.8 % at median 0 / 0.25 / 0.5 / 1.
   The index's prediction holds for the default dictionary. Brotli 12's 3-cycle with a different phase seed:
   0.7 / 1.0 / 0.7 / 100 %, against the table's 1 / 1 / 1 / 99. The whole-lattice numbers are not phase-seed artefacts.
5. **The sensitivity of the index to its own definition** (finding 4), from the same JSON: eight-step closure, the
   r = 0.05 and 0.5 variants, and the majority closure.

Taken on trust: the exact fixed-point count (68,964,123) and its wasm verification, the BFF reproduction of cubff's log,
the dose-response and infodyn tables, and every number under 1024².

## 1. Q1: my earlier concerns, judged on the evidence

| my round-3 item | status | evidence |
|---|---|---|
| Shuffle distribution for F (30 byte, 30 word) | settled at the map level | map-spine.md §4: F ranks 1 of 31 on H2 at k = 1, 4, 16, 64 against byte shuffles; typical against word shuffles (5 of 30 reach F's own 3-cycle). The lattice-level typicality was not run; the map-level answer makes it unnecessary for the map paper. |
| Multi-seed, rotating-order re-evaluation of named dictionaries | partly | replicators-v2: 3 searched + 4 designed dictionaries, 20 seeds, both settings, winners and takeover with intervals. Not done: the design-gray3 §6–9 tables (26 designs, the stray-cycle rule, the reading-length rule) and the search-score re-evaluation. |
| Retire the broken generator; state the seed-11 winner's curse; "selected by eye" | not at all | tools/ca-search.mjs l.17 and ca-lattice-search.mjs l.20 still run the LCG in doubles (period 10,466); ca-swarm.mjs l.83 and ca-lattice-search.mjs l.84 still score on `seed: 11` alone; no output of the searches carries provenance. Nothing in RESPONSE.md mentions the searches. These are text and two-line fixes, so this is cheap to settle. |
| "No head fits" (design-vote) reworded to "no single-word, single-distance, literal-free head" | not at all | design-vote.md l.63–65 unchanged. |
| Pairwise transitivity of "who wins" | partly, untabulated | droplets.mjs runs every ordered pair of three types per dictionary, so the data exist in data/droplets/*.json; nobody has reduced them to a competition matrix or a transitivity test. |
| The professor's cycle-projection null | not done | still the right null for whether the 128-bit content matters to what the search rewarded; still not needed for the map paper. |
| MAP-Elites | not done | agreed with the professor: not needed now. |
| Provenance in outputs | settled for the new scripts | every new output read carries the stamp; the old searches do not. |

## 2. Q2: the central result and the closure index

**Finding 1 (the index is correct as a filter, and the data say so cleanly).** All ten types with C(A, A) ≥ 99 % hold a
random-phase domain at every setting; the three types with C < 40 % lose it at every partial setting (closure-vs-survival.md).
My own run of Swarm F (check 4) adds an eleventh prediction, made before I ran it, that came out right: the default
dictionary's one attractor melts at median ≤ 0.5. For the lattice, Lemma 1 plus the §4 proposition explain why the
closed ones hold; the melting of the open ones is measured, not derived.

**Finding 2 (DEFINITION.md §4 is correct).** The pointer lemma, the existence theorem and the closure proposition are
sound as stated: a bitwise combination of two or three designed states keeps the 28 command bits and lands on some
header H₀ + 16γ, γ a value of the bijection g, so f sends it to the next designed state; the tail, including the parity
byte, is never read. Two things the section rightly does not claim and the mechanism text sometimes forgets: closure
against *other* types is not proved (cross-closure C(#1, #0) for Brotli 12's fixed point against its 3-cycle is 0 % at
one step, closure-ca-brotli-12.md l.19), and the basins are not controlled by the construction.

**Finding 3 (basin against survival is the number to report).** From the same 15 types: basin against mean random-phase
survival, Pearson −0.57, Spearman −0.43. That is "the medium, not the basin, picks the winner" in one figure, and it is
stronger than r = 0.79 because it is the hypothesis's own quantity failing.

**Finding 4 (r = 0.79 is a 2 × 2 table dressed as a correlation, and the dressing is fragile).**
- Ten of the 15 points sit at (100 %, 100 %) and three at (≤ 39 %, ≤ 1 %); the correlation is the distance between two
  clusters. Spearman 0.995 says the same. Report the counts (10 of 10, 0 of 3) and drop r.
- Five of the 15 are fixed points, for which "random phases" and "coherent" are the same configuration (one state). They
  are closed by definition and cannot discriminate. Five more are Gray cycles, closed by theorem. The empirical content
  is the five generic cycles: Pearson 0.60 on five points, and the two at 95 % go opposite ways.
- The definition's parameters matter. With closure at eight steps instead of one (same JSON), Pearson falls to 0.73, and
  the 5-to-12 design's 11-cycle is 100 % closed yet dies (survival 0.6 %): a counterexample under a choice the text does
  not motivate. At r = 0.5, 0.80; majority closure at one step, 0.70; at eight steps, 0.54. The 99 % threshold in
  closure-vs-survival.mjs l.26 is placed so that the two 95 % types fall on the "open" side. State the (r, steps) choice
  as a choice and show the sensitivity in one line.
- mechanism.md §2 l.56 says the two 5-to-12 generic cycles "survive mixing alone but die under partial settling". The
  5-cycle does (100 / 0 / 0); the 11-cycle dies at median 0 too (1 / 1 / 1 / 100, closure-vs-survival.md l.11). The
  sentence is wrong for one of its two subjects.
- The types were selected by basin plus the largest fixed point (droplets.mjs l.32, "the type the frame favours"). That
  is fine, but it is why a third of the sample is trivially closed, and the paper should say so.

**Finding 5 (what the index cannot do, which is where the design question lives).** Among closed types it is silent,
and the lattice still picks one. Under uniform settings one Gray 8-cycle with a 4.8 % basin takes 98 % of the 20-species
design by turn 90 (replicators-table-v2.md, gray20c), the 1.4 % one takes 98 % of the 32-species design, and the
three-species design's winner is the cycle with the *smallest* basin (26.8 %), with two distinct leaders over 20 seeds.
All have C = 100 %. So closure explains why fixed points and designs beat open cycles; it does not explain the winner
among designs, which is the thing a designer of lively dictionaries needs. The author's candidate, the reading length of
the filler, is still single-seed (design-gray3.md §6 l.150–160, §9 l.340–348: "one seed and one design").

**Finding 6 (the mechanism on the frame is a picture, not a measured rate).** "The fixed point nucleates in the melt and
fills it" (mechanism.md §4) rests on the Brotli 12 and 13 frame maps (3 + 1 seeds). Under f alone the fixed point's
basin is 0.26 %, so entry into it in the melt is created by the medium; the rate is not measured. And the frame map was
run for no dictionary without a closed competitor: Swarm F's open 3-cycle holds 62–66 % of the frame at turn 2,000 in
50 of 50 seeds (replicators-table-v2.md), the same share Brotli 12's fixed point takes (54–57 %). Given check 4, F's
melt must stay a melt. A frame map for F (one run of frame-mechanism.mjs, three seeds) would show what fills a melt when
nothing closed is available, and it is the missing control for §4.

**Verdict on Q2.** Explained for the dichotomy closed/open, with a proof for the designed side and 11 of 11 correct
predictions. Not yet a quantity: the correlation should go, the sensitivity should be shown, and the test that would make
it settled is a pre-stated prediction on dictionaries the index was not built on (Brotli 1, 9; Swarm A–E, G; cyc567;
gray4–6c; the Declaration's long cycles), run after the predictions are written down. closure.mjs is 5–15 s per
dictionary and the whole-lattice runs about 12 s each at 128², so the whole set is one to two CPU-hours.

## 3. Q3: the retractions

**Finding 7.** In the results folder the five retractions are complete and the superseding files say what they
supersede (ablation-v2.md, finite-size.md, replicators-v2.md l.9–11, map-spine.md §5, DEFINITION.md l.101–103). What still
rests on retracted numbers:
- results/README.md is stale as an index: l.21 still summarises replicators.md with "takeover at front speed"; l.47–48
  "no fixed points"; l.41–46 the t^⅓ and pinning language; l.73 "q = 8 clock model". It needs a date and a rewrite,
  or the superseded rows marked.
- design-gray3.md l.47 "no stray cycle" (contradicted by the exact search's stray fixed point).
- The drafts, as the brief says, are untouched: RESULTS_REPLICATORS.md l.26 "no fixed point", l.83–86 the 1/(N·b)
  argument, l.88–89 "the pace of a front, about 1.5 times longer than at 128²"; INTRODUCTION.md l.50, 56, 111–117,
  125; INTRODUCTION_MOTIVATION.md l.70, 76–77, 87, 164; MOTIVATION.md l.70, 121; METHODS.md l.74 (the correlation length
  as an observable). RELATED_WORK.md l.235 states the 93.5-bit bound correctly as an entropy.
- The harness budget: fixed, and every earlier run asked for 256. But dose-response.md l.13 says Brainfuck ignores the
  budget, so its dose row is not a dose and should be dropped from the figure.
- From my own side, nothing in the new results rests on the search scores, which is as it should be. The scores
  themselves remain fixed-order, seed-11 numbers (round 2, b1); they must not reappear in a table.

## 4. Q4: the processor arm

**Finding 8.** As an experimental design, the four pieces are of unequal strength.
- replicase-ablation.md is a proper factorial with 5 seeds, negative controls (inert trait: exactly 0) and contrasts
  of 1.00 against 0.00. It is a result about a constructed family and says so (l.314–329).
- bff-census.md is exact for what it tests (12 of 12 evolved replicators send (R|X) to a fixed point in one step for
  256 of 256 partners; 80–85 % of soup-drawn mutants breed true, 100 % of non-instruction changes). The emergence rate is
  rightly not claimed from 8 soups.
- dose-response.md is seed 1 at 128² for the single-cell table, with 5 seeds only for Redcode pairs (leading share
  12 / 45 / 77 % at 16 / 64 / 256 instructions) and the imp's KM median 144 on 5 seeds. The 6502's 36 % at 16
  instructions is "not robust" by the author's own words (l.99–100).
- infodyn.md is seed 1, k = 3, plug-in.

Together they make this a result: *the replicators that appear in BFF, in Redcode on this lattice, and in a constructed
replicase family are fixed points of their interaction map, and the one ingredient that separates heritable from
repaired is verbatim copying of unread bits.* The generalisation "replicators of computational life" is still a
programme: one of six processors produced a replicator here, and BFF is one soup. The minimum to call the narrow
statement finished is the single-cell dose table on 5 seeds (dose.mjs is a few minutes per row) and the pair-mode
takeover for Redcode at 256² to rule out the 128² absorbing-state artefact that finite-size.md found for the decoder.

## 5. Q5: thesis and venue

**Finding 9.** The thesis has sharpened, not changed. The first panel said "the medium, not the basin, chooses";
the project now says *a type holds a region iff its own states' bit exchanges stay on the type, closure can be
designed, and fixed points and designed cycles are closed while generic cycles are not.* That is a design rule, which
makes it an Artificial Life paper (designable self-maintenance in a medium) rather than a physics one; Complex Systems
remains the fallback. The second paper's claim has data now (finding 8) and belongs to PNAS or Artificial Life as
before. My own earlier framing, "the map paper", stands, with the closure dichotomy as its spine and the census as its
method.

## 6. Q6: minimum remaining work, my part

| # | experiment | seeds, sizes | cost |
|---|---|---|---|
| a | Closure-table extension to every type with basin > 1 % in every named dictionary (Brotli 1, 9, 12, 13; Swarm A–G; gray3c/4c/5c/6c/20c/32c; cyc567; cyc5to12; Declaration), predictions written down first; whole-lattice random-phase runs only, 3 phase seeds | 128², 400 turns, 4 settings | closure.mjs 5–15 s each, runs 12 s each: 1–2 CPU-h |
| b | Index sensitivity table: r ∈ {0.05, 0.25, 0.5}, steps ∈ {1, 8}, majority closure, all from the existing JSON | — | no CPU |
| c | Frame map for Swarm F and gray3c (what fills the melt without, and with, closed competitors); nucleation rate of the fixed point per melt cell per turn from turn-50–200 snapshots | 256², 2,000 turns, 3 seeds each | 6 runs, about 1 CPU-h |
| d | Reading-length and longest-cycle rules: gray4c, gray5c, gray6c, cyc567, cyc5to12, the 24- and 26-species designs, plus one equal-reading design with the cycle lengths permuted (the author's own proposed test, design-gray3.md l.346) | 256², 1,000 turns, uniform (½, 1), 5 seeds | about 40 runs, 3–5 CPU-h |
| e | Competition matrix and transitivity from the existing droplet JSON (every ordered pair × settings) | — | no CPU, one script |
| f | Search provenance: retire the double LCG (two lines), one paragraph stating seed-11 selection, fixed order, "chosen by eye", and that score gaps are within seed noise | — | half a day |
| g | Replace r = 0.79 by the 2 × 2 count and the basin's negative correlation; fix mechanism.md l.56 and README.md; generate the mechanism table from the data rather than typing it (39 % and 94 % in the text against 38 % and 95 % in the data) | — | text |

Two to three days and about 10 CPU-hours, in addition to the physics and statistics items the others will list.

## 7. Q7: anything wrong

**Finding 10.** replicators-v2.md l.49–50: "The Gray designs' leaders reach 90 % by turns 86–95." True for gray20c
and gray32c (86–90). False for gray3c: under uniform settings its leader never reaches 90 % (> 1,999 in both sizes),
holds 67–69 % at the end, and there are two distinct leaders over 20 seeds (replicators-table-v2.md l.30–31). The
three-species design coexists under uniform settings as well as on the frame; that is a better fact for the paper than
the sentence that hides it.

**Finding 11.** mechanism.md l.56 (the 11-cycle "survives mixing alone": it does not), l.35 and l.41–42 (39 %, 94 %
against the data's 38 %, 95 %), README.md l.23 ("9 of 9 closed types" against mechanism.md's 10 of 10). Small, but three
hand-copied numbers in one table argue for generating it.

**Finding 12.** map-spine.md §4: F's rank "4 of 31" for H2 at k = 16 among word shuffles. At two decimals only
wordshuffle16 (1.74) is below F's 1.80, with wordshuffle8 and 18 equal; so the rank is 2 (two tied) unless the comparison
used more digits. Immaterial to the conclusion; state the tie rule.

**Finding 13.** The two older search tools still carry the defective generator and the single evaluation seed (§1),
and design-vote.md still says "no head fits" where it means "no head of the single-word form". None of this touches the
new results; all of it will be found by any referee who opens tools/.

**Finding 14 (what a search for lively dictionaries should optimise, in the light of the new results).** Closure at
100 % gives frozen stand-offs on the frame (no Gray design reaches 50 % in 2,000 turns; replicators-v2.md item 3) and a
single winner under uniform settings (finding 5); closure below 40 % gives melting. "Lively" lies in between and is
not a self-closure property at all: it is the off-diagonal, C(A, B) ≠ C(B, A), asymmetric invasion without melting,
and, for cyclic dominance, A × B → C. The droplet data already contain those off-diagonal numbers (closure-ca-cyc5to12.md:
#0 × #1 46 % closed at one step, 73 % at eight, with 25 % landing on #1). The right objective for a census-scored
packing search is therefore a target *matrix* of cross-closures with a steep funnel and no stray attractor as
constraints, not a maximal self-closure, and the lattice evaluation must be multi-seed under uniform settings, with the
frame kept as the picture. That is a one-paragraph change to the plan in results/README.md "Next experiments 0".
