# Round 2, second panel: the emeritus professor

2026-10-22. Read all six other round-1 notes. Three small checks of my own before taking sides (read-only, nothing
new written outside data/review2/): `passes` in every experiment script (closure, droplets, heredity, infodyn and
entropy-curves run one settling pass; frame-mechanism and replicators run three; the harness default is three); the
droplet tracks for Brotli 12's fixed point in the 3-cycle sea (final fixed-point share 0.0 % at every partial-settling
point with mixing, the sea melting to 1–16 %, no refill in 400 turns); and `kmax=64` in all three replicators-v2 shell
scripts. The physicist, the mathematician and the computation reviewer are right on all three.

## 1. Where I now agree or disagree, by note and finding

**The settling-pass mismatch (physics §2.2; information finding 5).** Agree, and I rank it the panel's first
correction. Every uniform-parameter experiment behind mechanism.md §2–3 and §5 (closure, droplets, whole-lattice
survival, mutant patches) ran one majority pass; the frame maps of §4 and every replicator run ran three. The
sentence "closed types nucleate in the melt and fill it" therefore joins two experiments on different media, and the
one-pass droplet tracks show what that hides: at one pass the closed droplet dies and nothing refills the melt. The
heredity patches, infodyn and entropy-curves carry the same unstated choice. My round-1 finding 5 ("explained in kind")
assumed the settings matched; it did not check, and I withdraw the word "confirm" from it.

**Nucleation, seeds from the start, and t₅₀ (physics §2.3, mathematics findings 8–9, computation finding 2).** Agree
with all three, and they improve on my round-1 finding 1. I wrote "no faster than 1.6× for a fourfold side"; the
computation reviewer's table (times to 25 % and 40 % equal to within 5 % at 128², 256² and 512²; 50 % on the plateau)
and the physicist's share curves show the right statement is "size-independent establishment within the decoder's
transient, then logarithmic creep", with t₅₀ an artefact of where the plateau sits. "Nucleation" needs a barrier and a
critical radius, and none was measured; the droplet tracks say the fixed-point seeds on the frame are not born in the
melt. Where I part from the physicist slightly: whether the seeds are "the random start's own basin cells" (mathematics
8) or "the three-pass medium enlarging the basin" (physics §2.6, 18 % by turn 20 against an isolated basin of 0.26 %)
is open, and the two are not exclusive. The mathematician's two runs (basin cells removed at t = 0; a droplet planted
in a pre-melted sea) and the physicist's lattice-basin measurement decide it between them for 2–3 CPU-hours. Until
then: "melts the open type; the closed type's domains, present from the start, grow into the melt".

**The selection rule is conditional (ALife §2.3; optimization finding 6).** Agree. Swarm F, with no closed competitor
at a detectable share, re-forms its open 3-cycle in phase on the frame (62–66 % at turn 2,000 in 50 of 50 seeds), so
the rule is "where a closed type exists at detectable share it wins the mixed region; otherwise the open type
re-crystallises". The frame map for Swarm F is the missing control and costs an hour.

**The Declaration (computation finding 5).** Agree. The detector was raised to 64 and the one dictionary that needed
more (periods 154 and 182) was run at 64 in all three shells; its "no takeover" rows are not a measurement, and
RESPONSE.md row 4 is wrong for the only case it was for.

**The closure statistic (all six; mathematics 7, information 13–14, optimization 3–5).** Agree that r = 0.79 must go,
as I also said. Three additions I adopt: the optimizer's sensitivity (at eight steps the 11-cycle is 100 % closed and
dies, so the (r, steps) choice must be stated and shown); his basin-against-survival r = −0.57, which is the hypothesis's
own quantity failing and the better figure; and the information theorist's reframing of the index as a return-time
against the disturbance rate, which is the same experiment as my p*(type, median) and the physicist's item 3. One
experiment, three names; run it once. The optimizer's finding 5 (closure is silent among closed types, so it does not
pick the design winner) is the open design question, and should be stated as such rather than hidden under "closure
explains the winner".

**Heredity as the second paper's thesis (ALife §5.1, information findings 20–21 and 25, mathematics finding 10).** Agree;
it is what I called "von Neumann's tape, measured". I adopt the mathematician's sharpest form as the panel's
definition: *the heritable information of a replicator is log₂ the size of the fixed-point family it belongs to, the
bytes the map copies without reading*; Keimli's families have 0–3 such bytes, BFF's 48–54, the imp none. That one
definition joins the self-read-literal families of the census to the BFF neutral set, and it is a census, not a
programme. Two refinements from the ALife reviewer I accept: the BFF heredity figures are conditional on R being in the
first slot (about half per encounter), and the "new attractor (heritable)" column is conversion, so Keimli's heritable
count is 0 of 2,944.

**Where I disagree with the ALife reviewer: the BFF census in the first paper (ALife §5.2).** Partly conceded. In
round 3 of the first panel I said the BFF census should be a separate paper with an outside co-author, because the
author is measuring his own earlier result. The reviewer's §4.3 changes my mind on one point: the census does not
deflate BFF, it *refutes* "listed, not born" for BFF's origin (a 2^−100 target is built by the walk, whatever the
walker), and that is a result that protects the author from the advocacy reading rather than inviting it. So: the
heredity contrast (one table, Keimli's repaired mutants against BFF's inherited ones, with the co-authorship declared
beside it) goes into the first paper's closing section; the origin question, the emergence rate, the imp and the
processor dose–response remain the second paper, with the outside co-author.

**Information dynamics (information findings 16–19).** Agree that "rest" bounds nothing and that the decomposition is
representation-dependent, and this softens my round-1 finding 9: the processors' "stillness" is their low H(next), and
the null is a null of this decomposition, not a proof that computation is absent. My conclusion stands on the other
leg: no measurement in the project shows "computation" doing anything, and the identity control (rest 0.11 under the
medium alone) shows the decoder's residual is the decoder's. Drop the word from the thesis.

**Other agreements, in one line each.** Mathematics 3 (the prefix is 48 bits, 30 command bits, 80-bit tail) and 2
(the look-and-say formula in Lemma 3's remark is inverted); information 4 (the look-and-say stopping time is one digit
longer: 72 / 87 / 99 bits) and 6 (the "110 bits lost" sentence reads a collision figure as Shannon; the Shannon loss
is bracketed, not measured); mathematics 4's mutual-closure corollary (species whose H₀ form a Gray code over the
upper header bits are mutually closed), which answers the editors' interface question constructively for one line of
text and one check; physics §1.2 (quenched (0.2, ½) is coarsening at z ≈ 0.26, not frozen; finite-size.md point 1 is
overstated) and §1.3 (z ≈ 0.36 ± 0.03 is already on disk in series.csv); optimization 10 (gray3c never reaches 90 %
under uniform settings and has two leaders, which is a better fact than the sentence that hides it); computation 1a
(the harness version behind the mechanism data is unrecoverable, which the three-pass rerun cures) and 6 (the CPU
numbers read from overwritten logs have no file behind them); ALife 7.6 (the decoder copies nothing, it writes
dictionary bytes); the optimizer's §1 that the search tools still carry the broken generator and seed-11 scoring.

## 2. What I revise in my own round 1

- Finding 1 and 5: as above. The mechanism is explained for melting (now 4 of 4 open types, with Swarm F added by three
  reviewers independently) and not for filling; the latter has no uniform-parameter experiment at the frame's settling.
- Finding 6: keep p*, but it is one experiment with the physicist's item 3 and the information theorist's return-time
  curve; name it once.
- Finding 9: "the thesis died" becomes "the thesis has no positive measurement and the one decomposition tried returned
  a null that is representation-dependent"; the recommendation (drop "computation") is unchanged.
- Finding 10 and the verdict: the heredity contrast goes into the first paper; the rest of the processor arm stays out.
- The thesis statement, revised: *A dictionary decoder as a cellular-automaton rule has an exactly countable attractor
  set (68,964,123 fixed points in 15,693 families, one 3-cycle with 99.995 % of the basin) whose structure is carried by
  the dictionary's words and not by any random map with its one-step law; attractors can be built into it and proved
  closed; in a medium of exchange and majority a type holds a region if its own states' bit exchanges return to the
  type, so fixed points and designed cycles displace large-basin open cycles where mixing is strong and settling
  partial, and the open cycle re-forms where no closed type is present; and the surviving types have no heredity of
  variants, which separates them from the replicators of BFF by exactly the bytes a copier does not read.*
- Venue: unchanged, Artificial Life first, Complex Systems or JCA second. Not a physics venue: with the (0.2, ½) point
  reclassified as slow coarsening and the full system's lengths non-monotone in t, the medium's physics is a
  majority-vote model's, and the author should print no MSR length and no exponent in the first paper.

## 3. The panel's three most important corrections, ranked

1. **The settling-pass mismatch.** Closure, droplets, whole-lattice survival, heredity patches, infodyn and entropy-curves
   at one pass; the frame and every replicator run at three. Every mechanism table must be regenerated at three passes
   (with seed as a parameter and n ≥ 3), and every results table must state passes. Until then the mechanism's uniform
   half and its frame half are not about the same automaton. (Physics §2.2, information 5; confirmed by me.)
2. **"Nucleation", "1.35–1.6×" and t₅₀.** Retire all three. Report share curves and times to 25 % and 40 %
   (size-independent), define "melt" once, and decide where the closed type's seeds come from with the mathematician's
   two runs and the physicist's lattice-basin grid. (Physics §2.3, mathematics 8–9, computation 2.)
3. **r = 0.79 and the one-pass closure table.** Replace by the 2 × 2 count with the Swarm F row and the two 95 %
   exceptions, the (r, steps) sensitivity line, basin-against-survival r = −0.57, and the whole-turn return-time curve
   with its threshold p*(type, median). (All seven notes.)

Close behind: the Declaration at kmax = 64 (computation 5); the 48-bit prefix and the inverted look-and-say formula
(mathematics 2–3, information 4); the unwritten drafts and the stale README, which every reviewer listed and which I
treat as work, not correction, in the plan below.

## 4. Draft consolidated verdict

The experiments of 2026-10-21 answered the first panel. The map spine is exact where it can be and honest where it
cannot: the fixed-point count, the random-map nulls, the shuffles, Lemma 3 and the Gray closure proposition were each
reproduced by two or more reviewers from the data or by rerun. The retractions are complete in the results folder.
The processor arm produced two clean results (every evolved BFF replicator is a fixed point of the pair map that absorbs
any partner; the imp is a fixed point that a rare basin and a strong medium pick) and one contrast that is now the
project's sharpest (BFF inherits 80–85 % of single-byte mutations, Keimli 0 of 2,944). The thesis of the drafts,
entropy reduction against computation, found no measurement in its favour and should be replaced by heredity as
copying of unread bytes, von Neumann's distinction with numbers.

The mechanism behind the central lattice result is half established. Melting of open types under mixing with partial
settling is shown for four generic cycles, with a proof for why closed ones do not melt. Filling of the melt by the
closed type is shown only on the frame at three settling passes, while every uniform-parameter experiment ran one
pass and shows no filling; the seeds' origin is undecided; "nucleation" and the size ratio are unsupported; and the
correlation is a 2 × 2 table. These are days of work, not weeks.

Nothing written for the paper reflects any of it. All nine false sentences stand in every draft; results/README.md
still asserts "no fixed points" and "hash pinning"; the co-authorship of the 2024 study is declared nowhere. The
first paper is a map paper for Artificial Life (Complex Systems or JCA as fall-backs), with the heredity contrast as
its closing section. The second paper is the origin and heredity of replicators in BFF, Core War and a constructed
replicase, with an outside co-author.

## 5. Ordered work plan, deduplicated across the seven notes

Costs from the stamped run times; "who" names the notes that demand the item. Paper 1 is A–E; F–G are paper 2.

| # | item | days | CPU-h | who |
|---|---|---|---|---|
| A1 | Mechanism rerun at three passes: closure, droplets (seed as parameter, 3 seeds), whole-lattice survival, mutant patches; every type with basin > 1 % in Brotli 1, 9, 12, 13, Swarm F, gray3c/20c/32c, cyc5to12, Declaration; predictions written before the runs | 1 | 35 | physics 1, computation Q6, optimization a, ALife 2, information 5 |
| A2 | Seed origin: random start with basin cells replaced (20 seeds, 256², frame); fixed-point droplet in a pre-melted sea; lattice basin after one three-pass turn on an 8 × 8 (swap, median) grid | 0.3 | 3 | mathematics 8, physics 4 |
| A3 | Radius series R ∈ {1…32}, Brotli 12 and 13, three settings, 5 seeds | 0.2 | 3 | physics 2 |
| A4 | Whole-turn closure as a return-time curve against the disturbance rate (k = 1, 2, 4, 8; swap × median grid), generic cycles plus the 12-cycle; the threshold p*(type, median); Hamming-span column; index sensitivity table and basin-against-survival figure from the existing JSON | 0.5 | 2 | physics 3, information 4, mathematics 6, optimization b–c, professor 6 |
| A5 | Frame maps for Swarm F and gray3c, 256², 3 seeds; competition matrix and transitivity from the droplet JSON | 0.2 | 1 | optimization c, e; ALife 2.3 |
| A6 | Exact fixed points of Brotli 12, 13 and every Gray design; 2-cycle class search for Brotli 12 and 13; the mutual-closure corollary checked on gray3c and gray20c | 0.2 | 1 | professor 12, mathematics 4 |
| A7 | Declaration at kmax = 200, 4 settings × 10 seeds, 128² and 256²; first appearance at 32² and 64² | 0.3 | 7 | computation 5, Q6 |
| B1 | DEFINITION.md: 48 / 30 / 80 bits; "mutation off" in the corollary; the look-and-say formula and the one-digit stopping time; "any bitwise function" and "pure domain"; cross-type closure marked empirical; the mutual-closure corollary; the Shannon bracket H₂ ≤ H ≤ 87.5 per dictionary | 0.5 | 1 | mathematics 1–4, information 4, 6, 9, 12; professor 7 |
| B2 | Results text: mechanism.md generated from the data (38 / 95, the 11-cycle sentence, the heritable column, passes stated, 2 × 2 in place of r); replicators-v2.md (share curves and t₂₅/t₄₀ in place of 1.35–1.6×, the gray3c sentence, log-derived CPU numbers dropped, the Declaration row marked unmeasured); finite-size.md point 1 reworded, z ≈ 0.36 from series.csv added; decoder-map.md l.38; look-and-say N = 131,044; entropy-manipulators' "110 bits"; infodyn "residual" and the identity control row; the replicase log₂ definition stated | 1 | 0 | all |
| B3 | Index and pipeline: results/README.md rewritten as an index; superseded banners on ablation-main/-scan/-structure, replicators.md, replicators-table.md, design-gray3 ("no stray cycle", "clock model"); the two replicator figures regenerated from v2 or deleted; one `make tables` script; provenance in entropy-curves output and lead files; harness `altOrder` default rotate; the four dictionaries normalised; band.js and docs/lattice.md headers; lemma test in CI; the search tools' generator and seed-11 scoring retired with one honest paragraph | 1 | 0 | computation 1, 6, 8–9; optimization f; physics 3.1 |
| C | Entropy calibration with a non-flat known map; pair counts near the resolution | 0.5 | 1 | information 3, 8 |
| D | Design-winner rules multi-seed (gray4–6c, cyc567, cyc5to12, the 24/26-species designs, one permuted-length design), uniform (½, 1), 5 seeds | 0.3 | 4 | optimization d (optional for paper 1) |
| E | The writing: abstract, introduction, methods, results on both claims tables; the nine sentences out; "no copy instruction, no fitness function, no heredity of variants" on the first page; the co-authorship; vocabulary (melt defined; attractor types, domain competition; no nucleation, front or coarsening); citations (zenil2015 fixed, lempel1976, levin1974, Hopfield 1982, Eigen 1971, Wilke 2001, Vasas–Szathmáry–Santos 2010, Kaneko); the heredity contrast table as the closing section | 3–4 | 0 | all |
| F | Paper 2, CPU: single-cell dose at 5 seeds (8); infodyn at k = 4, five seeds, identity control, one cell-level variant (3); 6502 and Redcode single-cell reruns with the fixed script, 256² (10); Redcode pairs at 256² (2); the 6502 pair leader decoded and tested as a fixed point (0); imp mutant census on pairs (4); random-tape self-copier count in BFF (2); 20 BFF soups at the paper's setting to 16,000 epochs (40); stage-resolved erasure H(Y\|Z) (10); the family-size census of the imp and the 6502 type (1) | 5 | 80 | computation Q6, ALife 6.3–6.6, information 5–7, mathematics 10, optimization 8 |
| G | Paper 2, people: an outside co-author from the BFF community; the origin section written from ALife §4.3 | – | 0 | professor, ALife, editors |
| H | Only for a physics paper: turn-salted MS− at 1024² × 3 × 4,000 turns and 2048² × 8,000 (z: ⅓ or ½); the phase-field observable for MSR and the ablation-v2 points rerun; salt-by-position at 10 seeds | 1.5 | 26 | physics 5–6, 1.5 |

Paper 1: A1–A7, B1–B3, C and E, about eight working days and 55 CPU-hours (two hours on 28 cores), of which four days
are writing and one is text corrections. A1–A4 come first because they decide whether the paper's central sentence
stands; they can run tonight. Paper 2: F and G, one to two further weeks and 80 CPU-hours. H only if the author
decides to write the medium's physics, which the panel advises against.
