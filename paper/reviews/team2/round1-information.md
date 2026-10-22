# Round 1 (second panel): information theory

Reviewer: information theorist. Continuity with my first-panel notes (../team/round1-, round2-, round3-information.md):
there I asked for (a) collision and min-entropy beside the Shannon bound, (b) a random-map null matched in the one-step
law, (c) an entropy decay curve H₂(f^k), (d) calibrated observables in place of the pooled byte histogram, (e) a stage test
of the "entropy pump", (f) the parse-versus-decode citations, and (g) heritable information as a channel capacity. (a), (b),
(c) and most of (d) and (f) are now done; (e) and (g) are not in the pipeline. Details below.

## 0. What I checked myself

Everything else in this note is read from the results files and taken on trust unless marked. Outputs of my runs are in
`paper/data/review2/` (git-ignored); scratch scripts in my session scratchpad, not in the repository.

1. **Rule-90 calibration** (`results/entropy-manipulators.md`). From `data/entropy/entropy-curves-n362-t64.json`: H₂ = 23.95,
   16.00, 8.00, 0 at turns 52, 56, 60, 64 against the exact 24, 16, 8, 0; 256 distinct cells at turn 60. My rerun at 64²
   (`node paper/experiments/entropy-curves.mjs n=64 turns=64 out=paper/data/review2`, under a minute): 23.0 (at that run's
   23-bit resolution), 16.12, 7.995, 0, and the same Swarm F curve (15.5 → 3.5 → 1.8 → 1.6), look-and-say (3.6 → 1.5 → 1.2
   base 10; 4.8 → 0.4 base 16) and Z80 (12.5) within the resolution. **Confirmed.** One number is wrong in the text: the run
   has n = 362, so N = 131,044 cells, not 131,072 (the JSON says 131044; the "distinct cells" column in both
   entropy-manipulators.md and look-and-say.md says "of 131,072").
2. **r = 0.79** (`results/closure-vs-survival.md`). Recomputed from the 15 rows of the table: r = 0.790. Dropping the two
   borderline 95 % types (5-to-12 #0 and #1) gives r = 0.98. See finding 7.
3. **The decoder's first step** (`results/decoder-map.md`, `map-spine.md`). 2 × 10⁵ uniform cells through `decode36.mjs`
   with `ca-swarm-f` (4,400 bytes): E[min(c, 128)] = 93.49, 4.9 % past 128 bits, H₂ = 16.56, H∞ = 8.30, most probable
   output `28…28` (sixteen `(`) at 0.32 %. Against 93.5, 5.0 %, 16.50, 8.27, 0.32 %. **Confirmed.**
4. **Look-and-say bits read** (`results/look-and-say.md`). My own run-length script reproduces 68.27 (base 16), 85.10
   (base 4) and 97.92 (base 2) bits exactly, as the count of digits inside the runs that are described. But the reference
   rule (`test/mix.test.mjs` `lasRef`: `while (i + r < n && d[i + r] === d[i]) r++`) also reads the digit that ends the last
   run, and the output depends on it. The stopping time is one digit longer: **72.27, 87.11 and 98.92 bits.** The table's
   column is "digits consumed", not "digits the output depends on", and the bound in Lemma 3 needs the latter. The
   closed-form 128/(2(1 − 1/b)) is likewise the run count only. Small, but it is exactly the point Lemma 3 turns on.
5. **Information dynamics** (`results/infodyn.md`). Every row reproduced from `data/infodyn/*.json` (T0 = 20, window 40
   for the median-1 rows; T0 = 200, window 100 for the median-0.5 rows). The table has no control for the medium alone,
   so I ran one: `infodyn.mjs changer=3` (kind 3 = "do nothing", `decode.wat` l.110), same settings, into
   `paper/data/review2/`: **rest 0.036 at median 1 and 0.111 at median 0.5** (storage 0.96 and 0.87, H(next) = 1.00). The
   medium by itself does not produce the decoder's rest of 0.77–0.99, which is what the table needs to show and does
   not. Both scripts (`infodyn.mjs`, `entropy-curves.mjs`) run **one settling pass** (`passes: 1`) where DEFINITION.md
   §2 gives the default as three; neither results file says so.

## 1. The entropy measures and their calibration (editors' concern 12)

6. **Collision entropy is "exact" only where it equals Shannon entropy.** The four calibration rules are linear maps on
   GF(2)¹²⁸ whose images are subspaces; the output distribution is flat, so H = H₂ = H∞ and the calibration cannot tell
   the three apart. The decoder's output is the opposite of flat (H∞ = 8.3, H₂ = 16.5, H ≤ 87.5 after the header
   correction of my round 2; the plug-in Shannon estimate saturates near log₂ N). Three sentences now read a
   collision figure as a Shannon loss and must change:
   - entropy-manipulators.md: "the decoder's first step takes 128 bits to 17 to 20" and the proposed draft sentence "the
     decoder loses about 110 bits in its first step" (128 − H₂). The Shannon loss lies between 40.5 and 111 bits; nobody
     has measured it.
   - DEFINITION.md Lemma 3, remark: "the measured values are far smaller: collision entropy 16.5 bits, min-entropy 8.3"
     is true but compares different functionals with the bound; say that H itself is unmeasured and bracketed.
   - decoder-map.md l.38 still says "the image of f has at most 2^93.5 elements in entropy terms" and calls hash:93 the
     matched null; both were withdrawn (DEFINITION.md, map-spine.md §3) but this file was not amended.

   What would make the calibration complete: one rule with a known *non-flat* image law (for instance, truncate the cell
   to a length chosen by its own leading bits), for which H, H₂ and H∞ are all computable and differ. Half a day.
7. **Block entropy blind, collision entropy blind the other way.** The rule-90 demonstration (block-8 stays at 1.000
   until the lattice is all zero) is correct and worth keeping. The dose-response table shows the converse: Z80 and rule
   90 at the same whole-cell H₂ (11.2 against 11.3 bits) with block-8 0.23 against 0.92. That pair of numbers is the
   most useful information-theoretic fact in the processor arm (finding 12), and the write-up should present the two
   measures as complementary, not as one trustworthy and one not.
8. **Resolution and error bars.** H₂ from the number of equal pairs is unbiased, but near the resolution (2 log₂ N − 1)
   it rests on a handful of collisions: "29.7 bits" at N = 131,044 is about ten pairs, a Poisson error of ±0.5 bits.
   The tables should give the pair count or an interval for every value above about 28 bits, and the dose tables at 128²
   (resolution 27) for everything above 22.

## 2. Lemma 3 and the look-and-say worked example

9. **Lemma 3 is correct.** τ = min(c, 128) is a stopping time of the bit sequence read in the decoder's order (reading
   starts at bit 6 and wraps to bits 0–5, so "distinct bits read" is exactly min(c, 128)); the stopped prefixes form a
   complete prefix-free code; under fair bits each prefix p has probability 2^−|p|, so H(U₁…U_τ) = Σ 2^−|p| |p| = E[τ].
   This is the argument of my round 1 and it is now stated properly. Two remarks: the loss bound it gives, 128 − 93.5 =
   34.5 bits, is a lower bound on the loss; my round-2 header-redundancy correction (E[12 − H(out | rest)] = 5.5 bits)
   tightens it to H(f(U)) ≤ 87.5, and should be cited next to it, since it is free.
10. **Look-and-say.** As a worked example it is the cleanest thing in the processor arm: lossless and growing unbounded,
    many-to-one only through the cut, and the loss computed from a stopping time by the same lemma. Finding 4 corrects
    the table by one digit per base. The entropy-curve numbers (3.7/1.6/1.2 bits; 9–10 distinct cells) I reproduced at
    64². The "LZ compressors see the density fall to zero" paragraph is right but says less than it could: term n is a
    deterministic function of n, so its information is O(log n) bits and the per-digit density is O(log n / n); Deflate's
    0.09 and Brotli's 0.015 bits a digit at term 55 are just how close each gets. That is the parse-versus-decode point of
    my round 2, and the drafts still cite zenil2015 for the opposite of what it argues (INTRODUCTION.md l.71,
    INTRODUCTION_MOTIVATION.md l.98, MOTIVATION.md l.58); lempel1976 and levin1974 are now in references.bib (l.700, 708),
    unused in any draft.

## 3. The map spine (team action 4)

11. **The random-mapping null is done the way I asked, and the finding stands.** The P-random map matched in the whole
    one-step law (atoms with their weights, a never-repeating tail) is the right null for a heavy-headed map, and it
    settles the question of my round 2: with the same H₂ = 16.5 and H∞ = 8.3, a random map loses about one bit of H₂ per
    doubling of k (16.4 → 15.4 → 14.5 → 13.5), the decoder four to five (16.5 → 12.6 → 7.5 → 3.5). My round-2 decay
    numbers (16.4, 12.6, 9.5, 7.5, 6.2 at k = 1–5, log₂ 3 by k = 30) agree with map-null's. The information-theoretic
    statement is: f restricted to its own image contracts far more than f on uniform input; the attractor structure is a
    property of the iterates, not of the one-step law. I checked the Flajolet–Odlyzko line (H₂ ≈ 128 − log₂(k + 1)): the
    collision probability counts the U = U′ term, so a random map's H₂(f(U)) is log₂ n − 1, and the map-null table's
    n = 2^(H₂+1) matches it. Correct. The exact fixed-point count (68,964,123 in 15,693 families, verified on the wasm)
    I take on trust; its structure (self-read literals, 110 of 4,096 windows) is consistent with the grammar.
    Against the byte shuffles F is extreme and against the word shuffles typical: the shuffle comparison is not at matched
    one-step entropy (byte shuffles start at H₂ = 21.9), which is fine for a dictionary-property claim but should be said.

## 4. The closure index and the proof (question 2)

12. **The proposition in DEFINITION.md §4 is correct.** States of a designed type agree on the 46-bit prefix except header
    bits 4–6; any bitwise combination of them (exchange or majority, any number of parents) has that prefix with some
    3-bit pattern γ in bits 4–6; g is a bijection on {0, …, 7}, so γ = g(k) for some k and the pointer lemma gives
    f(c) = S_{k+1}. The pointer lemma needs the two copy commands to fill the output before the tail is read, and the
    windows to be disjoint; both are stated. The proof covers *same-type* parents only, which is what self-closure means;
    it says nothing about an interface with another type, and the droplet runs show closed types still invade one
    another. The wording "a designed type's domain cannot be melted by the medium, whatever the phases of its cells" is
    right for a pure domain and should say "pure".
13. **The closure index measures a rate, not a property, for the generic types.** Swarm F's 3-cycle has a basin of 100 %,
    so *every* crossover child returns to it; the index at one step (52/34/33 % at r = 0.05/0.25/0.5) is the share that
    returns in one turn, and at eight steps it is 91/78/76 % (`data/closure/closure-ca-swarm-f.md`). What decides
    survival is then the return time of a disturbed cell against the time between disturbances, which is set by the swap
    rate (four phases a turn at 2p(1 − p) per differing bit) and by settling, which is a three-or-nine-parent crossover
    every turn. That reframing explains the two borderline types (95 % at one step, dead under partial settling, alive
    under mixing alone) that the one-step index leaves open (mechanism.md §2, last bullet). The data to show it are
    already computed (closure at 1 and 8 steps, three rates); add k = 2 and 4 and plot survival against the return-time
    distribution. Half a day.
14. **r = 0.79 is a dichotomy wearing a correlation.** The 15 points are ten at (100 %, 100 %), three at (≤ 39 %, ≤ 1 %)
    and two at (95 %, ~1 %). Pearson's r on that is not informative: without the two borderline points it is 0.98, and
    the honest statistic is the 2 × 2 table (10 of 10 closed types survive, 0 of 3 open ones; Fisher's exact probability
    of that split by chance is 1/286). The information the correlation hides is in the two borderline points, which are
    the test of the mechanism (finding 13). The predictor that would make the result trivial and exact is the Hamming
    span of a type's states: 0 for a fixed point, 1–2 bits for a Gray cycle (closed by the proposition), 29–64 bits for
    the generic cycles. Report it in the table.
15. **Is the central result explained?** Yes at the level of mechanism: Lemmas 1–2 (exact), closure predicts domain
    survival (finding 14), and the frame maps show melt-then-nucleate. Not yet at the level of a rate: nothing predicts
    *where* on the frame the band of 100 % fixed point begins and ends, which a return-time-against-disturbance model
    would. I agree with the response table's "done" for the mechanism and would mark the quantitative version "open".

## 5. Information dynamics (editors' concern 18, response row 18)

16. **"Rest" is not a bound on anything.** `infodyn.mjs` computes rest = H(next) − A − T̄ − T_S, with T̄ the apparent
    transfer entropy averaged over the four neighbours and T_S the joint transfer from the two ring-adjacent bits. Apparent
    single-source terms overlap (redundancy) or fall short (synergy) of the joint conditional information, so subtracting
    several of them gives neither an upper nor a lower bound on H(next | past, all local sources). The md's sentence "an
    upper bound on what no single local source explains" has the direction wrong: subtracting more than one source makes
    it a *lower* bound on H(next | past, best single source). Call it what it is, the residual after storage and the
    pairwise transfers, and drop the claim that it bounds Lizier's modification; modification is defined through the
    local separable information and its sign, which is not computed.
17. **"Non-local" is the wrong word; the residual is mostly within the cell.** The system is deterministic, so
    H(next | the 3 × 3 neighbourhood at t, t mod 4) = 0; everything in the residual is explained by sources the
    decomposition did not condition on, and for the decoder that is the other 125 bits of the same cell, which it reads
    every turn. The per-bit choice of variable is what makes a whole-cell rewrite look "unexplained" and a processor that
    writes two bytes look "still". With the cell as the variable, the decoder alone is perfectly stored (a deterministic
    map of its own state). The decomposition is representation-dependent, and the md should say which representation it
    is making its claim in and why that one.
18. **The processors' stillness tracks their low H(next).** Z80, Subleq and Redcode have 0.1–0.3 bits of next-bit entropy
    at these settings (biased, locally ordered memories, block-8 0.21–0.23 in dose-response.md), so there is little to
    explain and storage explains it. The 6502 at 16 instructions, the one setting with a leading type, has H(next) 0.86
    and residual 0.68, like the decoder. So "processors do less non-local processing per turn than the decoder" is a
    statement about how much their memories change, which the dose-response already said better. My identity control
    (finding 5) does strengthen one point: the residual of 0.77–0.99 under partial settling is not the medium's hashing
    (0.11 under the same medium with no rewrite). Add that row.
19. **Smaller things.** k = 3 history under a rule of period 4 in time (DEFINITION.md §2) cannot represent the medium's
    own periodicity; use k = 4. One seed, 32 of 128 bit positions, one settling pass: state all three. The plug-in
    estimates themselves are fine (binary variables, 10⁷–10⁸ samples).
20. **Is "computation versus entropy reduction" now a measurable distinction?** Partly, and not through this
    decomposition. What is measurable, and measured:
    - one-step loss against iterated contraction (finding 11): the decoder's structure is in the iterates;
    - whole-cell against local entropy (finding 7): erasers collapse the cell, processors order it locally while keeping it;
    - heredity as the capacity of unread bits (finding 21).

    None of these measures "computation". What they measure is *erasure with repair* against *verbatim copying of bits
    the rule does not read*. That is the distinction the three experiments converge on, and it is a sharper thesis than
    the one in the drafts, because it can fail: a rule that reads every bit it copies cannot inherit a mutation.

## 6. The processor arm (question 4)

21. **Heredity is now a number, and it is the result.** BFF: 80–85 % of soup-weighted single-byte mutants breed true,
    0 % revert, 100 % of non-instruction-to-non-instruction changes inherited, all 48–54 neutral positions redrawn at once
    still breed true (64/64) in 12 of 12 replicators, so each sits on a neutral set of about 245^51 ≈ 2^405 fixed points
    (bff-census.md §4). Keimli: 384/384 one-bit mutants of F repaired, 0–1.6 % inherited across eight types
    (mechanism.md §5, replicase-ablation.md §6). The constructed replicase: tape heredity 1.00 with verbatim copying,
    0.00 with derived or template copying, in every seed (replicase-ablation.md §1). In my round-3 terms, the capacity of
    the parent → offspring channel is about 400 bits for a BFF tape and at most log₂(number of attractor types), a few
    bits, for a Keimli type. Three independent lines, one answer. **Result.**
22. **"Replicators are fixed points and short cycles" is true and nearly empty.** That (R | mirror R) is a fixed point of
    the pair map follows from R overwriting its partner with a copy; any copier that absorbs its partner makes the pair a
    fixed point. The content is in the asymmetry (R copies only from the first slot, 0 of 256 from the second) and in the
    neutral set. The Redcode imp on joined pairs (6 % → 85 % with the budget, five seeds) is the one processor replicator
    in Keimli's own medium and is Core War's trivial self-copier; it supports the fixed-point statement, and a census of
    its mutants (does an imp inherit a changed operand?) is the missing cheap experiment that would tie it to finding 21.
23. **What is still a programme.** The emergence rate (8 soups, no rate claimed, correctly); seed 1 only for the
    single-cell dose-response and the information dynamics; the 6502's 16-instruction leader undecoded; and no measure
    that distinguishes "computation" from "copying". The response table's "done" for rows 13 and 18 is "done at one
    seed, with a decomposition that needs renaming".

## 7. Retractions (question 3)

24. Complete in DEFINITION.md, map-spine.md, ablation-v2.md and replicators-v2.md. Incomplete elsewhere:
    - results/decoder-map.md l.38: "the image of f has at most 2^93.5 elements"; "the matched null … is hash:93".
    - results/README.md: the index still describes replicators.md ("takeover at front speed"), ablation-main.md
      (ξ = 64) and the "no fixed points" line under H4 without a superseded mark.
    - results/entropy-manipulators.md: the new "about 110 bits" sentence (finding 6) would introduce a fresh error.
    - results/look-and-say.md: the bound one digit short (finding 4), N = 131,072.
    - Every draft: INTRODUCTION.md l.50–56 (reads every bit once, never reads its own output, no loop, less than 94 bits,
      no fixed points), l.125 (pump); INTRODUCTION_MOTIVATION.md l.70, 76–77, 164; MOTIVATION.md l.38, 50–58, 70;
      RESULTS_REPLICATORS.md l.26 (no fixed point), l.81 (never late), l.87–89 (front, 1.5 times). The brief says the
      drafts are unrewritten; I list the lines so nothing is missed.

## 8. Thesis and venue (question 5)

25. The first paper's thesis has not changed since the first panel and is now supported: a decompressor as a CA rule,
    with a first-step loss bounded by a stopping time, iterated contraction far beyond any map with its one-step law, an
    exact fixed-point census, designed closed cycles, and selection of attractor types by closure under the medium. From
    my side the venue is Artificial Life or Complex Systems; Entropy would take the information spectrum as the lead
    (findings 9, 11, 7) and is the fastest. The second paper's thesis *has* changed, for the better: not "computation
    against entropy reduction" but "repair against inheritance: heredity needs bits the copier does not read". That is
    BioSystems or Artificial Life, and it does not need the word "computation" at all.

## 9. Minimum remaining work from this role (question 6)

| # | item | days | CPU-h |
|---|---|---|---|
| 1 | Text: findings 6, 9, 10, 16, 17, 24 (the information sentences, the leftovers, the citations) | 1 | 0 |
| 2 | The Shannon bracket: H₂ = 16.6 ≤ H(f(U)) ≤ 87.5 with the header correction, per dictionary (`decode36`, 10⁶ cells) | 0.5 | < 1 |
| 3 | Calibration with a non-flat known map (finding 6), rerun of entropy-curves at n = 362 with pair counts (finding 8) | 0.5 | 1 |
| 4 | Closure as a return-time distribution against the disturbance rate, k = 1, 2, 4, 8, three rates, 15 types; the Hamming span column; the 2 × 2 table in place of r (findings 13–14) | 0.5 | 1 |
| 5 | Information dynamics: identity control, k = 4, passes stated, five seeds, "residual" wording; one cell-level variant (type labels) to show the representation dependence (findings 16–19) | 1 | 2 |
| 6 | Imp mutant census on joined pairs (finding 22), 128², five seeds | 0.5 | 3 |
| 7 | The stage-resolved erasure H(Y\|Z) per cell per turn in the pipeline (my round-2 scratch result, still not in a results file) | 1 | 10 |

About four days and under twenty CPU-hours. Items 1–4 are needed for the first paper; 5–7 for the second.

## 10. Verdict on the seven questions, in one line each

1. Settled: the first-step bound (Lemma 3), the random-map null and shuffles, the calibration on flat rules, heredity.
   Partly: the entropy observables (no LZ density, no phase mutual information, no stage test), the information dynamics.
   Not: the Shannon entropy of f(U) itself, the pump sentence in any draft.
2. Explained as mechanism, not yet as a rate; closure is the right idea but should be a return time; r = 0.79 should be
   a 2 × 2 table; the proof is correct.
3. Complete in the new files, with the four leftovers of finding 24 and every draft line listed there.
4. Heredity is a result; "fixed points and short cycles" is true by construction of a copier; the rest is a programme at
   one seed.
5. First paper unchanged and supported; second paper's thesis improved to repair-against-inheritance.
6. Four days, under twenty CPU-hours, table above.
7. Wrong: the look-and-say bound by one digit (72/87/99, not 68/85/98); N = 131,044; "110 bits lost" (a collision
   figure read as Shannon); the "upper bound" direction and "non-local" in infodyn.md; decoder-map.md l.38 unretracted;
   one settling pass unstated in two scripts.
