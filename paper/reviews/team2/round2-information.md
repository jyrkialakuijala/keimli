# Round 2 (second panel): information theory

Read: the other six round-1 notes in this folder. Numbered items refer to those notes by role and finding number, and to
my own round 1 (`round1-information.md`) as "mine, finding n".

## 1. Agreements and disagreements, by file and number

1. **Mathematics, finding 2 and check 9 (the look-and-say formula).** Agree that DEFINITION.md l.105–106 prints the
   expression inverted (128 · 2(1 − 1/b) gives 240 bits at b = 16) and that 128 / (2(1 − 1/b)) is what look-and-say.md
   uses. I missed the inversion in round 1 and should have caught it; it is one fix. But "matches the measurement to
   0.01 bit" is agreement between two counts of the same thing, not between the bound and the stopping time. Both the
   formula and the table count the digits *inside* the described runs. The reference rule (`test/mix.test.mjs`,
   `lasRef`) reads one digit past the last described run to know its length, and the output depends on that digit, so
   τ is one digit longer (mine, check 4): 72.27, 87.11 and 98.92 bits at b = 16, 4, 2. The corrected remark for
   DEFINITION.md is "about 128 / (2(1 − 1/b)) + log₂ b bits", and the table's column should be renamed "digits inside
   the described runs" or recomputed. Small in bits, exact in kind: it is the stopping-time clause of Lemma 3.
2. **Mathematics, finding 10 (heritable bits = log₂ of the fixed-point family).** Agree, and I would make it the one
   definition the second paper uses, with three qualifications. (a) It is an upper bound on heritable information:
   the capacity of the parent → offspring channel is log₂ |family| only if every member breeds true under the actual
   pair map and the medium does not erase; BFF's 64/64 joint redraws (bff-census.md §4) support the first for BFF, and
   the replicase ablation's heredity 0.80 at swap 0.01 (replicase-ablation.md §3) shows the second can cut it. (b) The
   ALife reviewer's conditioning (4.2) applies: R copies only from the first slot, so per encounter the realised
   heredity is about half; the capacity is unchanged, the rate is halved. (c) For Keimli the families with 1–3 free
   bytes (map-spine.md §1) have basins below 10⁻⁵ and never appear on the lattice; the types that do appear are
   isolated, so the honest Keimli figure is 0 bits, which the ALife reviewer's relabelling (1.1: "0 of 2,944 mutants
   heritable") confirms. The mathematician's finding 6, that a Keimli family is bytes "read at the moment they are
   written", is the right bridge: in both systems heritable bits are exactly the bits copied without being used.
3. **Physics §2.2 and §7.1 (one settling pass in droplets and closure, three in the frame and replicators).** Agree,
   and it is wider than the mechanism set: `infodyn.mjs` and `entropy-curves.mjs` also run `passes: 1` (mine, finding
   5). So the lattice rows of entropy-manipulators.md ("swap ½, median 1": Z80 block-8 0.24 and H₂ 13.7; the decoder's
   0.5 bits and 2,766 distinct cells at turn 64; rule 90 held near 30 bits) and every row of infodyn.md are at one
   third of the page's settling, unlabelled. The rule-alone rows and the calibration are unaffected. This is the panel's
   most important correction (section 3).
4. **Professor, finding 9 ("the two-sources framing should go"; cut the entropy-versus-computation paragraph).**
   Agree; my finding 20 reached the same place from the measurements: nothing in dose-response or infodyn measures
   computation, and the distinction the three experiments converge on is erasure-with-repair against verbatim copying
   of unread bits, which is von Neumann's tape. One thing I would keep from the entropy side, as description and not
   as dichotomy: the split between whole-cell and local entropy (Z80 and rule 90 at 11.2 against 11.3 bits of H₂ with
   block-8 0.23 against 0.92; mine, finding 7), because it is the one matched-measure fact that separates processors
   from erasers without the word "computation". Also agree with the professor's finding 8 on "110 bits": his bracket
   [34.5, 111.5] uses the 93.5 bound; with the header correction it is [40.5, 111.4].
5. **Professor, finding 14 (resist "many fixed points").** Agree. The information-theoretic version: 68,964,123 fixed
   points carry at most log₂ of that, 26 bits, against a space of 128, and their total basin in 10⁶ starts is a few
   in 10⁶; the number is a grammar fact, not an attractor fact.
6. **ALife 4.3 ("BFF's replicators are built, not listed").** Agree with the arithmetic: 2^405 members per family,
   a few hundred families, against 2^512 tapes gives order 2^−100 for a uniform tape, and the soup samples about 2^30.
   The neutral-set size extrapolates from five tested values per position to 245, but the 64/64 joint redraws make the
   order of magnitude safe. This is a correction to RESULTS_REPLICATORS.md's "listed, not born" that none of us made in
   the first panel, and it belongs in the second paper's first paragraph.
7. **ALife 7.6 ("the decoder copies nothing; it writes dictionary bytes").** Half agree. 18.2 % of output bytes are
   copies of the decoder's own output and 36.9 % literals read from the cell (decoder-map.md §1), so it does copy. The
   sentence that is true and carries the point: "every output byte of the decoder is a function of bits it read; it
   copies no bit unread". That is the property heredity needs and the decoder lacks, and it is also why its mutants in
   unread bits vanish in one step (replicase-ablation.md §6).
8. **Optimization, finding 4 (the index at eight steps: the 11-cycle is 100 % closed and dies).** Agree, and it is the
   cleanest evidence for my finding 13: closure at k steps is a return-time statistic, and a type whose children return
   in eight turns is disturbed again every turn. The quantity is the return-time distribution against the disturbance
   interval, which the professor (finding 6) and the physicist (§2.4, p* thresholds) state as the whole-turn closure
   and the melting threshold. Three formulations of one experiment; I withdraw mine in favour of theirs, which is
   closer to what `closure.mjs` can run.
9. **Optimization, finding 3 (basin against survival, r = −0.57).** Agree that it is the hypothesis's own quantity
   failing and should be the figure. Same caveat as for r = 0.79: five informative points.
10. **Computation, finding 1c (no provenance in `entropy-curves.mjs` output).** Agree; the file I reran also has none.
    Computation Q4 ("verbatim 1.00 against 0.00 is close to a tautology"): agree for the constructed rule; the content
    is on the two ends that were not built to the hypothesis, Keimli's 384/384 repaired and BFF's 100 % for bytes no
    one designed to be unread.
11. **Mathematics, finding 5.** Agree with the log₂(k + 1) law and the "by construction" idempotence of hash:93; I
    verified the collision-probability argument independently (mine, finding 11). Finding 3 (48-bit prefix) I take on
    trust; it does not touch Lemma 3.
12. **Physics §2.6 (the lattice basin of the fixed point under a three-pass turn).** Agree, and it is the same
    measurement as the "entropy throughput" of my first-panel round 2: the one-turn image law of medium-plus-decoder
    against the decoder alone (entropy-curves already shows the medium holding 2,766 distinct cells at turn 64 where the
    decoder alone holds 7). One script serves both.

## 2. What I revise in my own round 1

13. **Finding 14, Fisher's p.** The physicist is right that 15 non-independent rows, ten of them at (1, 1) by proof,
    do not support a test; I withdraw the 1/286 and keep the counts. With the sixth type three reviewers added
    (Swarm F's 3-cycle: 0 / 0 / 0 / 100 %), the count is 10 of 10 closed types hold, 4 of 4 open types melt, 0 of 2 at
    95 % hold.
14. **Finding 15 (the mechanism "explained as mechanism").** I accepted the frame maps as showing melt-then-nucleate.
    The mathematician's droplet tracks (finding 8: no fixed point forms from the melt in 400 turns at one pass) and
    the physicist's settling mismatch (§2.2) mean the melting half is shown and the filling half is not. I move the
    mechanism to "melting explained; the winner's growth unexplained until the three-pass droplets and the radius
    series are run".
15. **Findings 5 and 19 (one pass).** Extended as in item 3: the lattice rows of entropy-manipulators.md are affected
    too, not only infodyn.md.
16. **Finding 21 (heredity as a capacity).** Adopt log₂ |family| with the qualifications of item 2; Keimli's figure
    becomes 0 bits (the "new attractor" column is conversion, ALife 1.1), BFF's about 400, the imp's to be measured
    (ALife item 4 and my item 6 are the same experiment).
17. **Finding 4.** Add the inverted formula in DEFINITION.md (item 1).
18. **Finding 22.** The ALife reviewer's point that the imp's heredity is untested, and the mathematician's that its
    family has no free bytes, together make the imp the test case for the capacity definition: predicted 0 bits.

## 3. The panel's three most important corrections, ranked

1. **The settling-pass mismatch** (physics §2.2; mathematics finding 8; mine, item 3). The closure–survival table, the
   droplets, the whole-lattice domains, all of infodyn.md and the lattice rows of entropy-manipulators.md are at one
   pass; the frame maps, the replicator Monte Carlo and the page are at three. "Closed types nucleate in the melt and
   fill it" has no uniform-parameter experiment behind it at the frame's settling, and the processor-arm lattice numbers
   are not at the page's setting. Rerun at three passes or label every table.
2. **The second paper's thesis** (professor 9; mathematics 10; ALife 4.3 and 5.1; mine, finding 20). The data refuse
   "computation against entropy reduction" and "listed, not born" for BFF, and give instead: replicators are fixed
   points of their interaction map; heritable information is the bits copied unread, about 400 for a BFF tape, 0 for
   a Keimli type; BFF's are reached by a walk, Keimli's are present at the start. Six reviewers converge on this; the
   drafts say the opposite.
3. **Two statistics that mislead, and the retractions that did not propagate** (all seven notes). r = 0.79 is a 2 × 2
   count with five informative rows; "1.35–1.6× for a fourfold side" is the 50 % mark on a plateau (computation 2,
   physics §2.3); and results/README.md, decoder-map.md l.38 and every draft still carry the withdrawn claims. The
   information-side errors of my round 1 (the one-digit undercount, "110 bits", the infodyn "upper bound" and
   "non-local", N = 131,044) go in the same pass.

## 4. Consolidated minimum work for this role, deduplicated

Already demanded by others and not repeated here: Swarm F in the closure table (ALife 2, optimization a, computation);
whole-turn closure and melting thresholds p* (professor 3, physics 3, optimization a); droplets and domains at three
passes (physics 1); seeds for dose and infodyn (professor, physics 7, ALife 6); the imp's mutant census (ALife 4);
exact fixed points of Brotli 12 and 13 (professor 2); provenance in entropy-curves and the lead files (computation 1);
the BFF random-tape count (ALife 5); the README, docs and drafts (everyone).

What remains mine:

| # | item | days | CPU-h |
|---|---|---|---|
| 1 | Text: the Shannon bracket H₂ ≤ H(f(U)) ≤ 87.5 per dictionary in place of "110 bits"; decoder-map.md l.38; one fix for the look-and-say bound (inverted formula and the lookahead digit, with the mathematician); N = 131,044; infodyn renamed "residual after storage and pairwise transfers", direction corrected, "within-cell" for "non-local"; pair counts beside every H₂ within 5 bits of the resolution | 1 | 0 |
| 2 | Rerun the lattice rows of entropy-curves and all of infodyn at three passes, with a provenance field, the identity control (already run, 2 min) and k = 4; the rule-alone rows stand | 0.5 | 2 |
| 3 | One calibration map with a known non-flat image law, so H, H₂ and H∞ are checked where they differ | 0.5 | < 1 |
| 4 | Heritable capacity as one definition (log₂ of the breed-true family under the actual interaction map) computed for BFF from the existing census, for Keimli's lattice types (0), and for the imp from the ALife reviewer's mutant run | 0.5 | 0 |
| 5 | The one-turn image law of medium-plus-decoder against the decoder alone (H₂, top atoms, share of transients landing on each attractor), which is the physicist's item 4 and my throughput measurement in one script, at three passes over the (swap, median) grid | 0.5 | 1 |

About three days and under five CPU-hours; items 1–3 for the first paper, 4–5 for the second. My round-1 item 7 (the
stage-resolved erasure H(Y|Z)) is absorbed into item 5; the cell-level infodyn variant is dropped as not needed by
either paper once the "computation" framing goes.
