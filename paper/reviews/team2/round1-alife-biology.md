# Round 1, second panel: artificial-life and biology reviewer

2026-10-22. Continuity with my first-panel notes (../team/round1-, round2-, round3-alife-biology.md): there I asked for
(a) the vocabulary of trivial replication and limited heredity, (b) a heredity test (are mutants copied, repaired or
dissolved), (c) a competition mechanism that explains the frame's winners, (d) the BFF census, and (e) the
conflict-of-interest declaration. This note judges what the 2026-10-21 experiments did to each, and answers the
brief's seven questions in order. Section 8 lists what I reran or recomputed myself.

## 1. Which concerns are settled, which partly, which not (question 1)

1. **Heredity in Keimli: settled, and in my favour.** `results/mechanism.md` §5 and `data/heredity/*.md` test every
   one-bit mutant of every state of every main type under the map alone, and 3 × 3 mutant patches on the lattice.
   Repaired 73–100 %, converted to another existing type 0–27 %, mutant itself on a cycle 0 % for every type (the
   column "the mutant is itself on a cycle" in the data tables, which is the right heredity measure). I checked the
   Brotli 12 numbers against `data/heredity/heredity-ca-brotli-12.json`: 384/384 repaired for the 3-cycle, 106/128
   repaired and 22/128 converted for the fixed point (82.8 / 17.2 %). This is limited heredity, quantified: what I
   asked for in round 2. One mislabel: the column "a new attractor (heritable)" in mechanism.md §5 is not heritable.
   A mutant that lands on a *different* attractor from itself has not passed its mutation on; it has been converted
   to a rare type. The 1.6 % for the 20-Gray fixed point is conversion, not heredity. The heritable count is the
   "mutant is itself on a cycle" column, which is 0 everywhere. The paper should say "0 of 2,944 mutants heritable".
2. **The competition mechanism: largely settled** (`results/mechanism.md`, `closure-vs-survival.md`, `droplets-table.md`,
   `DEFINITION.md` §3–4). Lemmas 1–2 say the medium acts only at boundaries, so a fixed-point domain is a fixed point
   of the whole lattice map; the closure index says which cycle domains survive their own phase disorder. This is a
   mechanism, and it replaces my round-2 guess ("survival of the flattest", robustness to noise) with something
   sharper: the open cycle is not out-competed, it is *melted by exchange between its own phases*, and the closed
   type crystallises in the melt. I accept this over my own version. Section 2 below says what the evidence does and
   does not carry.
3. **The vocabulary: not done.** Every draft still carries the sentences I flagged. `INTRODUCTION.md` 135–136:
   "nothing replicates, a cell is rewritten and never copied, and nothing is selected, no score is kept";
   `INTRODUCTION_MOTIVATION.md` 233: "No replication, no selection, no fitness: on the first page, before a referee
   says it"; `RESULTS_REPLICATORS.md` throughout: species, invasion, "a rule for which wins". The response table
   (`reviews/journals/RESPONSE.md`, "Still not addressed") admits the drafts were not rewritten. `RELATED_WORK.md` 41
   and 78–81 already adopt "trivial replication" and "limited heredity [maynardsmith1995]", so the author agrees; the
   introduction just has not caught up. Status: agreed, not written.
4. **Conflict of interest: not done.** `RELATED_WORK.md` 75–76 says "The author co-wrote agueraYarcas2024; say so in a
   footnote". No draft says it. With the BFF census now in the paper this is more necessary, not less: the paper now
   re-analyses the author's own earlier replicators.
5. **The BFF census: done as a census of evolved replicators, not as the census I asked for.** My round-2 item (iii)
   was the frequency of replicators among *random* tapes against 1/(tapes × interactions), to decide whether BFF's
   replicators are "listed" (present in the initial sample, as Keimli's are) or "built" (reached by a walk). What was
   done (`results/bff-census.md`) is a census of twelve evolved replicators plus the paper's Fig. 4 tape: their
   pair-map orbits and their mutants' heredity. That answers a different and also useful question (section 4). The
   origin question is left open, and the write-up says so ("no emergence rate claimed"). But the data already contain
   the answer in rough form, and it cuts against the deflation; see section 4, finding 3.
6. **The processor arm: done at the level of one seed and one size**, with the budget bug fixed. See section 4.
7. **"The medium picks the winner" with intervals: settled.** `results/replicators-v2.md` and `replicators-table-v2.md`:
   Brotli 12's fixed point (0.26–0.34 % basin) takes half the frame in 49 of 50 seeds over three sizes; Brotli 13's
   (2.8 %) in 50 of 50; under uniform settings the 93–100 % cycles win in 13–82 turns. I recomputed the Kaplan–Meier
   medians from the seed rows (section 8): they reproduce.
8. **The processor replicator Monte Carlo at 5 seeds (RESPONSE row 5, "Z80, 6502 and Redcode at 5 seeds: done")
   is not done as described.** `replicators-v2.md` says the 6502 and Redcode result files "exceeded JavaScript's string
   limit and were not written", their numbers were read from run logs, and "the other seeds' log lines were
   overwritten when the two batches shared the job list". Only `cpu6` (Z80) appears in `replicators-table-v2.md`. The
   single-cell processor rows are therefore 3 seeds from logs, without provenance, for two of the three processors.
   The status column says done; the evidence says partly, and needs a rerun with the fixed script.

## 2. Is the central result now explained (question 2)

1. **The proof.** DEFINITION.md Lemma 1 is correct and trivial (mixing acts only on differing bits; the majority of equal
   bits is that bit; clamped edges repeat an equal cell). Lemma 2 follows. The §4 pointer lemma, the 8-cycle theorem and
   the closure proposition are correct as stated, given one thing I took on trust: that the 46-bit prefix with header
   bits 4–6 varying is the only place the designed states differ *in the bits the decoder reads before it stops*. The
   proposition's proof uses that a crossover of two designed states has a header H₀ + 16γ for some γ in 0–7, hence is
   P(h_k)·τ for some k, hence maps to S_{k+1}. That holds because the states agree on every prefix bit except header
   bits 4–6, and a crossover of the header bits 4–6 is still a 3-bit pattern. Fine. The theorem gives existence and
   closure only; stray attractors (the mathematician's stray fixed point for the 3-species design) stay empirical, and
   the text says so. `test/lemma.test.mjs` checks Lemma 1 on the module (48 × 40 cells, 12 turns, both mixing rules,
   both salts); I read it, I did not run it.
2. **Is the closure index the right quantity?** It is the right *kind* of quantity: a property of the type's own state
   set under the medium's operators, computable without a lattice run. But the correlation r = 0.79 over 15 types
   carries less than it looks. I recomputed it from `closure-vs-survival.md` (section 8) and it is exactly 0.79. Ten
   of the fifteen types are closed *by proof* (six fixed points, four designed Gray cycles: C = 100 %, survival 100 %),
   so for them the index predicts nothing the lemmas did not already say. The predictive content lies in the five
   generic cycles: Brotli 12's 3-cycle (C = 38 %, survival 1 %), Brotli 13's 9- and 18-cycles (11 %, 6 %: 0 %), and the
   two 5-to-12 cycles (95 %, 95 %: 33 % and 1 %). Three clear hits, two borderline misses that the write-up honestly
   calls open ("the one-operator index leaves them open"). That is n = 5, not n = 15. I added a sixth: Swarm F's
   3-cycle, the default dictionary, which has a closure file (`data/closure/closure-ca-swarm-f.md`: 34 % at r = 0.25)
   but no droplet run and is absent from the survival table. I ran it (section 8): a random-phase domain of it dies at
   median 0, 0.25 and 0.5 (0 % after 400 turns) and holds at median 1 (100 %). A fourth hit, and it should be in the
   table, since every page figure uses this dictionary.
3. **Where the mechanism statement needs a qualifier.** "Mixing melts the open types; closed types nucleate in the melt
   and fill it" (mechanism.md §4) is true where a closed type is present at a share above about 1/N. For Swarm F there
   is none (68,964,123 fixed points, every basin below 10⁻⁵, `map-spine.md`), and the frame does *not* stay melted: the
   3-cycle takes 50 % of the frame at turn 33–34 and holds 62–66 % at turn 2,000 in all 50 seeds
   (`replicators-table-v2.md`). So the melt of an open type re-crystallises in phase when nothing closed is there to
   take it. The statement for the paper is: "where a closed type exists at detectable share, it wins the mixed region;
   otherwise the open type re-forms in phase". That is a conditional selection rule, which is what I asked for in
   round 2, and it is better than the unconditional one.
4. **Does it explain the frame maps?** Yes, qualitatively, and across seeds. I checked the turn-2000 grids for Brotli 12
   seeds 2 and 3 and Brotli 13 seed 1 (`data/frame-mechanism/*.md`): rows 3–4, columns 1–6 are 100 % fixed point in all
   four maps, the edges and the full-settling row vary. What is not explained quantitatively is the takeover time, and
   the write-up's "nucleation throughout the melt followed by slow coarsening" (replicators-v2.md item 2) is a
   description of the curve's weak size dependence (1.35–1.6× for 4× side), not a measured nucleation rate. No
   droplet-growth velocity or critical radius has been measured; the droplets table reports only holds / shrinks /
   vanishes at 400 turns. My round-3 request for v, s* and a transitivity test stands, but it is no longer needed for
   the first paper: the closure mechanism plus Lemma 1 is enough to say *why*, and the KM medians say *when*.
5. **In my field's terms.** The result is now: a type's persistence under the medium depends on a property of its own
   state set (closure), not on its basin (the map's "arrival of the frequent", Schaper and Louis 2014, which
   RELATED_WORK.md 44 already names as the contrast). That is selection on robustness of the *type*, with no fitness
   function, no lineage and no heritable variation. The right citations are Wilke et al. 2001 for the robustness idea
   and Vasas, Szathmáry and Santos 2010 for why such types cannot evolve.

## 3. Retractions (question 3)

1. **Complete in the results folder, incomplete in the drafts and the index.** The retracted items (correlation length,
   front speed, image bound, "no fixed points", the harness budget) are withdrawn in `replicators-v2.md`,
   `ablation-v2.md`, `DEFINITION.md` Lemma 3 remarks, `map-spine.md` and `dose-response.md`. They survive verbatim in:
   - `INTRODUCTION.md` 50–57: "never reads its own output", "no fixed points"; 155: "invasion with a rule for which
     species wins"; contribution (iv): "the identification of hash pinning".
   - `INTRODUCTION_MOTIVATION.md` 70–77: "never reads its own output", "no fixed points"; 145–150: the t^⅓ law and
     "pinning by the hash, a weak quenched disorder in the sense of [sicilia2008]", which the physicist retracted
     (salting by position freezes exactly like no salt; it is deterministic freezing) and which `finite-size.md`
     now reports as a size-independent frozen length (12.4 → 12.6 cells).
   - `RESULTS_REPLICATORS.md` 26: "there is no fixed point"; 81–85: the 1/(N·b) waiting time and "never late";
     86–90: "at the pace of a front, half of a 256² lattice after a thousand turns ... about 1.5 times longer than at
     128²", the censored-median number (716 / 1,093) now replaced by KM medians 731 / 920 / 992.
   - `results/README.md`: the H4 line "no fixed points" and the `replicators.md` row "lateness is takeover at front
     speed" are still in the index table, next to the v2 row that supersedes them. The index should mark the old row
     superseded.
2. **Anything else resting on the retracted numbers?** The "every major type appears at once" claim
   (replicators-v2.md item 4) no longer rests on 1/(N·b); it is now a direct observation (median first sighting turn
   5–25; I saw first-seen turns of 4–16 in the seed rows). It is fine as an observation. The *inference* I objected
   to in round 2, that first appearance can never be late because basins exceed 1/N, is gone from the results and
   should go from the draft. What remains true and worth saying: the leading fixed point is detected at turn 6–16 in
   every seed at every size, and then takes 370–1,000 turns to reach half; the lag is the medium's.
3. **The harness budget.** The fix (`tools/ca-harness.mjs` line 32) means every earlier processor run used 256
   instructions. `entropy-manipulators.md` rows 65–66 are labelled "Z80, 256 instructions" and are unaffected. I found
   no earlier result that quotes a budget other than 256, so nothing else needs retracting; the dose-response is the
   first experiment to vary it.

## 4. The processor arm (question 4)

1. **Redcode's imp: a clean, honest result.** On joined pairs the leading type is Core War's imp, `MOV $0, $1` and its
   relatives, a memory full of one self-copying instruction; it is a fixed point of the cell map and takes 60–92 % of
   the lattice at 256 instructions across five seeds (`dose-response.md`). I checked the frame takeover from
   `data/candidate/redcode-pair-page1.md`: t50 = 114, 115, 195, 183, 144 for seeds 1–5, median 144, basin 0.59 %. The
   imp is the one case in the processor arm where "the replicator is a fixed point of the map, and a rare one that
   the medium picks" is shown rather than argued. It is also the most trivial replicator in the literature (Dewdney
   1984 calls it that), so the ALife reader will say: of course the imp is a fixed point. True; the point to make is
   that the imp's heredity is as limited as the decoder's (one instruction, nothing unread), and the paper does not
   yet test that. It should: mutate an imp-filled cell and see whether anything but the imp is copied.
2. **The BFF census answers my heredity question, and the answer is the paper's best contrast.** Every evolved
   replicator R sends (R|X) to (R|mirror R) in one step for 256/256 partners; 80–85 % of soup-drawn single-byte
   mutants breed true, 0 % revert, and every non-instruction byte is neutral (48–54 per tape, 64/64 joint redraws
   breed true). I reproduced the Fig. 4 tape's census from scratch with a quarter of the sampling (section 8) and
   got the same 87.0 / 0.4 / 0.0 / 12.6 and 48 neutral positions. So: Keimli's types repair their mutants; BFF's
   copy theirs. That is exactly the limited-against-unlimited heredity line of Maynard Smith and Szathmáry, measured
   in both systems. One caveat the write-up should state next to the numbers: the mutant is placed "in the better of
   the two slots". In the soup the slot is random and R copies only from the first slot (0/256 from the second), so
   per encounter the heredity is roughly half the quoted figure. It is the same conditioning for R itself (selfLines:
   16/16 in slot 0, 0/16 in slot 1), so the comparison is fair, but the absolute numbers are conditional.
3. **The census does not carry the "listed, not born" deflation over to BFF; it refutes it.** The neutral-set estimate
   says each evolved replicator sits on about 245^51 ≈ 2^405 fixed points of g. Even with a few hundred such families,
   a uniformly random 64-byte tape is a self-copier with probability of order 2^405 × 10² / 2^512 ≈ 2^−100. A soup of
   2^17 tapes over 12,000 epochs samples at most 10^9 ≈ 2^30 tapes by any route. So BFF's replicators are not present
   in the initial population at a share above 1/N, as Keimli's are; they are reached. Knierim et al. 2026 (cited in
   RELATED_WORK.md 42) say the route is a mutation random walk and needs no interaction; fine, but a walk that finds a
   2^−100 target is constructing it, whatever the walker is. `results/bff-census.md` §2 ("no rate is claimed") and §7
   leave this unsaid. The paper must say it, because it is the one place where the thesis of RESULTS_REPLICATORS.md,
   "they are not born; they are listed", meets the author's own earlier system and loses. The honest statement:
   Keimli's attractors are listed; BFF's are built, and once built they sit on a neutral manifold that the copy loop
   carries. The deflation applies to *spread and competition* (the medium picks, the basin does not), not to
   *origin* (the walk builds) or *evolution* (heredity of unread bytes). That was my round-3 Paper B verdict; the data
   now say it with numbers.
4. **The replicase ablation is a useful control, not a result about emergence.** Heredity 1.00 for verbatim against
   0.00 for template and derived is true by construction; the rows confirm the implementation, no more. The content is
   in the other switches: no spread without self-reference and protection (0/5), no spontaneous origin unless the
   background makes novelty (rule 90 yes, decoder never, identity never), and an error threshold at swap ≈ 0.01, an
   order of magnitude below the page's own settings (½), so no constructed replicator survives any default frame. The
   last point is the one I would keep in the paper: Keimli's medium is far above the Eigen threshold for anything that
   copies a tape; only attractor types that need no copying can live in it. That is a sharp reason why the two kinds
   of replicator cannot coexist on the same page, and it explains the empty processor arm (no leader at any budget
   for the Z80, Subleq, RISC-V, Brainfuck) better than "processors compute".
5. **Dose-response and infodyn: one seed, one size, and a conclusion that cuts the other way.** `infodyn.md` finds that
   the processors' bits sit still (storage explains 0.1–0.3 bits of 0.1–0.3) and the decoder rewrites everything.
   `dose-response.md` finds local order without takeover. Both are seed 1 at 128², and `finite-size.md` warns that
   128² with the decoder can fall into an absorbing state. Neither shows computation; infodyn.md says so ("whatever
   is distinctive about computation does not show as ongoing per-bit activity here"). As evidence for the second
   paper's claim they are honest negatives.
6. **Verdict on question 4.** "Replicators of computational life are fixed points and short cycles" is now a *result* for
   three systems (Keimli's types, the imp, BFF's loops), with the needed qualifier that a BFF replicator is a fixed
   point *family* of about 2^405 members. "Heredity needs verbatim copying of unread tape" is a result in BFF (100 %
   inheritance of non-instruction bytes, 0 % in Keimli) and a construction in the replicase rule. What is still a
   programme: the origin claim (section 4.3), any statement about "computation" (infodyn is negative), and every
   processor number at more than one seed.

## 5. The thesis and the venue (question 5)

1. **It has changed, and the results folder knows it; the drafts do not.** The first panel's thesis was "a decoder
   separates entropy reduction from computation". After the experiments the defensible thesis is narrower and better:
   *a rewriting map with no copy instruction, in a medium of exchange and majority, has self-maintaining attractor
   types whose competition is decided by closure under the medium's operators, not by basin size; those types have no
   heredity of variation, and the one thing that separates them from the replicators of computational life is the
   verbatim copying of unread tape, measured in BFF.* That is the Artificial Life or BioSystems paper the editors
   scored 7–8, and it needs no claim about computation.
2. **Venue.** *Artificial Life* first, as the journals' synthesis recommends, with the BFF comparison as the closing
   section rather than a second paper: the census is done, it is small, and it is the part an ALife referee will read
   first. The "what computation adds" paper should wait; its two positive results (the imp, BFF heredity) now fit in
   the first paper, and its negative ones (infodyn, dose-response single cells) do not make a paper.
3. **The sentence that must go.** "Nothing replicates, nothing is selected" (INTRODUCTION.md 135). After mechanism.md
   §5 and the BFF census the author has *measured* replication (the medium copies type identity: 100 % of in-phase
   domains hold, Lemma 1), measured selection (closed types displace open ones in 99/100 seeds) and measured the
   absence of heredity. The honest first-page sentence is "no copy instruction, no fitness function, no heredity of
   variants", and each clause now has a number.

## 6. Minimum remaining work (question 6)

For the first paper only, in order. Where I give CPU-hours I scale from the stamped run times in the results.

1. **Rewrite** the introduction, motivation and the replicator section on the claims table of the first panel plus
   sections 2–4 above; declare the co-authorship; fix the README index. 2–3 days, no CPU.
2. **Add Swarm F to the closure–survival table** (my run: 1 minute; `droplets.mjs dict=ca-swarm-f types=1`), and the
   six closure values for its 3-cycle (already in `data/closure/closure-ca-swarm-f.md`). Then state the correlation as
   "16 types, of which 10 closed by proof; of the 6 generic cycles, 4 predicted, 2 borderline". Half a day.
3. **The processor single-cell Monte Carlo redone with the fixed script**: 6502 and Redcode, 5 seeds, 256², 2,000
   turns, both settings, result files written (the 0.1 % cut-off is already in the script). About 60 runs; from the
   v2 timing, roughly 10 CPU-hours.
4. **The imp's heredity**: `heredity.mjs`-style mutants of an imp-filled cell under changer 47 on pairs, map alone and
   3 × 3 patches, seeds 1–5. One day, under 5 CPU-hours. This closes the "limited heredity" comparison across all
   three systems.
5. **A random-tape self-copier count for BFF**: the `soupStats` test of `bff.mjs` on 10⁶–10⁷ uniformly random tapes
   (zero expected) and on the pre-transition soup at epoch −256 (zero expected), to print the number next to the
   2^−100 estimate. Hours of one core.
6. **Seeds 2–3 for `dose.mjs` on pairs at 16, 64 and 256 instructions**, so that the 6502's 61–69 % at 16 instructions
   has an interval. About 20 CPU-hours.
7. **Lemma test in CI**: `node test/lemma.test.mjs` in `test/smoke.sh`. Minutes.

Total: about 5 working days and 40 CPU-hours, then the physics items the other reviewers will list. Nothing here needs
512² or 1024².

## 7. Anything wrong (question 7)

1. mechanism.md §2 table: Brotli 12's 3-cycle closure "39 %" is 37.9 % in `data/closure/closure-ca-brotli-12.json`
   (0.3789); `closure-vs-survival.md` says 38 %. Trivial, but the two tables should agree.
2. mechanism.md §5: the column heading "a new attractor (heritable)" is wrong, as in section 1.1 above. The data
   tables have the right column ("the mutant is itself on a cycle": 0 everywhere).
3. RESPONSE.md row 5 marks the processor replicator Monte Carlo done; the result files for two of three processors
   were never written and the seed coverage is 3 from overwritten logs (section 1.8).
4. `bff.mjs validate` writes to a hard-coded path (`paper/data/bff/validate.json`, line 204) and ignores `out=`. My
   validation run therefore rewrote that git-ignored file; its content is deterministic and the five logged lines
   matched cubff's to the byte before and after, so nothing changed, but the script should honour `out=`, and I
   report the overwrite here.
5. bff-census.md §4: the "soup-weighted" heredity is conditional on R being first (section 4.2); the unconditional
   per-encounter figure is about half. Not wrong, but the paper must not quote 80–85 % as "the heredity of a BFF
   replicator" without the condition.
6. bff-census.md §6 and replicase-ablation.md "Plain statements" 1 say the decoder "reads, and so erases, what it
   copies". It also erases what it does *not* read (about half of all point mutations are gone in one step,
   replicase-ablation.md §6, because the decoder never reads those bits). The sentence should say the decoder copies
   nothing: it writes dictionary bytes.
7. replicators-v2.md item 4, "every major type appears at once", is a statement about types that *ever held 0.1 %*.
   It cannot see a late type by construction. Fine as written, but it must not be turned back into "no late first
   appearance" in the draft.

## 8. What I checked myself and what I took on trust

Checked (outputs under `paper/data/review2/`):
- **r = 0.79**: recomputed from the 15 rows of `closure-vs-survival.md` (self-closure against the mean of the
  median-0 / 0.25 / 0.5 survival columns): 0.79 exactly.
- **Kaplan–Meier medians**: recomputed from the seed rows of `data/replicators-v2/ca-brotli-1{2,3}-page-n{128,256,512}-
  t2000.json` with my own KM and bootstrap: 731, 920, 992, 373, 584, as in the table; 20/19/10 and 20/10 seeds reach
  50 %; the leader is the k = 1 type with basin 0.26–0.34 % and 2.8–2.9 % in every seed. My bootstrap interval for
  128² is [560, 878] against the table's [560, 912]; a different random stream.
- **The closure index**: reran `closure.mjs dict=ca-brotli-12` (9 s); the 27-row table is identical to
  `data/closure/closure-ca-brotli-12.md` line for line.
- **Heredity, Brotli 12**: 384/384, 106/128, 105/128 repaired in the JSON, matching the 100 / 82.8 / 82.0 % quoted.
- **BFF**: `bff.mjs selftest` passes (12 checks); `validate` reproduces cubff's five regression lines (epochs 1–257)
  to the byte, 110 s; a fresh census of the Fig. 4 tape with nx = 64, nlin = 8 gives soup-weighted 87.0 / 0.4 / 0.0 /
  12.6 %, 48 neutral positions, 64/64 joint redraws, (R|X) → (R|R) for 64/64 partners, matching R13 in
  `bff-census.md`. The R1–R12 weighted figures I read from `data/bff/census.json` (82.0, 82.0, 84.4, 79.8, 83.0,
  80.0, 84.2, 84.2, 81.2, 84.3, 84.5, 84.5 % heritable), matching the table.
- **Replicase**: rows `verbatim-s1-t1-r90-off-mu0.001` (heredity 1.00 ± 0.00, log₂ up/down 11.47 ± 1.01 in the
  summary table against 7.48 ± 1.00 in the write-up's core table; Δtrait 4.34 ± 0.15) and `template-s1-t1-r90-off-
  mu0.001` (heredity 0.00) in `data/replicase/summary-table.md`. The log₂ figure differs between the summary table
  (11.47) and replicase-ablation.md §1 (7.48), and I traced it: `replicase.mjs` line 273 now computes
  log₂((Σup + 1)/(Σdown + 1)) over the 16 + 16 mutants' descendant totals, while the write-up's definition is per
  mutant. With Σdown = 0, 2^11.47 ≈ 2,836 descendants is 177 per mutant and log₂ 178 = 7.48; the mu = 0 row gives
  2^13.99/16 → log₂ 1,019 = 10.0, the write-up's 10.0. Same data, two definitions from the two script versions
  (d4f4aca1 and 27131eef). The write-up should quote one and say which; the sign and the zero control are not in
  doubt.
- **Frame maps**: rows 3–4, columns 1–6 are 100 % fixed point in all four turn-2000 grids (Brotli 12 seeds 1–3,
  Brotli 13 seed 1).
- **The imp**: t50 per seed from `data/candidate/redcode-pair-page1.md`, median 144, basin 0.59 %.
- **New**: Swarm F's random-phase 3-cycle domain, `droplets.mjs dict=ca-swarm-f types=1` (65 s): 0 / 0 / 0 / 100 %
  at median 0 / 0.25 / 0.5 / 1, swap 0.1; coherent 100 % everywhere.

Taken on trust: the exact fixed-point count 68,964,123 and its wasm verification; the infodyn and dose-response
numbers (seed 1); the 1,150 replicase runs beyond the rows above; the BFF soup runs themselves (1–2 hours each);
Lemma 1's module test (read, not run); every draft citation.
