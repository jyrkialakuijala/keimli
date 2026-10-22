# Round 1, second panel: the emeritus professor of complex systems

2026-10-22. Read in the brief's order: both syntheses, RESPONSE.md, results/README.md and the twelve new result notes,
DEFINITION.md, the six drafts, RELATED_WORK.md with references.bib, and the scripts behind the numbers I checked.
My earlier notes (../team/round1–3-professor.md) are the baseline; where I have changed my mind I say so.

## What I checked myself (outputs in paper/data/review2/)

| number | where claimed | what I did | result |
|---|---|---|---|
| r = 0.79 over 15 types | mechanism.md §2, closure-vs-survival.md | reran `closure-vs-survival.mjs 0.25` on the data | 0.79 reproduced; on the 9 non-Gray types r = 0.74, on the 5 generic cycles 0.61 (see finding 6) |
| 44 / 4 / 0 / 0 fixed points in headers 3232 / 1 / 64 / 777 | map-spine.md §1 | reran `map-exact.mjs ca-swarm-f 1 4 raw 1 3232,1,64,777` (1 s) | 44 / 4 / 0 / 0; all 48 verified with decode36 and the wasm |
| 15,643 + 4,608 + 1,835,008 + 67,108,864 = 68,964,123 | map-spine.md §1 | arithmetic, and 18·2⁸, 28·2¹⁶, 4·2²⁴ | consistent |
| rule 90: H₂ = 8.00 and 256 distinct cells at turn 60; Swarm F H₂ = 1.80 at k = 16, 1.58 at 64 | entropy-manipulators.md | reran `entropy-curves.mjs n=64 turns=64` (4,096 cells) | 8.00 / 256 / 1.80 / 1.58 reproduced; turn 56 gives 16.12 against the exact 16 (sampling at this N) |
| Brotli 13 frame 128²: KM median 373 [351, 406], 20 of 20 | replicators-v2.md | regenerated the whole table with `replicators-summary2.mjs` (identical, plus one new CPU row); own plain median from the 20 seed files, 10-turn grid | 380 (range 260–610), leader 4a9527eb in every seed; Brotli 12: 770 at 128², 920 at 256², 1050 at 512² against 731 / 920 / 992 |
| MS− quenched 256² ξ_c = 12.41 | finite-size.md | read data/ablation-sizes/summary-final.md | 12.408 [12.315, 12.536] |
| Z80 block entropy 0.98 → 0.23 over budgets 1–256 | dose-response.md | read dose-table.md | 0.98, 0.95, 0.89, 0.79, 0.60, 0.41, 0.29, 0.24, 0.23 |
| 248 entries, 218 verified, 30 partly, every cited key resolves | RELATED_WORK.md §0 | grep of references.bib and of the 138 keys cited in drafts and results | 248; 219 yes, 29 partly; all 138 keys resolve |

Taken on trust: the BFF reimplementation (the regression-log match is reported, not rerun), the 1,150-run replicase
grid, and every 2026 preprint in the bibliography (I cannot read them).

## 1. Which concerns are settled (the evidence, not the status column)

**Settled.**
- Provenance, rotating order, period detector, censoring-aware medians, the page's snapshot bug, the harness budget.
  The regenerated table is byte-identical, which is what provenance is for.
- "No fixed points": overturned exactly. 68,964,123, verified one by one on the module, with the self-read-literal
  mechanism as the explanation. This is now the paper's best single sentence.
- The random-mapping null: Flajolet–Odlyzko, a uniform map matched in H₂ and a map matched in the whole one-step
  law, three seeds each, against the decoder's 92.8 % on cycles by k = 16. The contraction of the iterates is not
  that of a random map. Settled.
- The image-size bound, withdrawn and replaced by Lemma 3 (correct; it is the prefix-code identity for a stopping
  time).
- The first batch's correlation lengths: plane bias, now shown (ablation-v2.md).
- The front-speed takeover claim: withdrawn, and the replacement is honest about Brotli 13 (373 → 584, intervals
  disjoint).
- Entropy calibration on rules 60/90/150/170; the block entropy is shown blind. Settled, and useful.
- A formal definition with Lemmas 1–2 checked on the module.

**Partly.**
- The mechanism of "the medium, not the basin": explained in kind (finding 5), not in degree (finding 6).
- The takeover-against-size claim for Brotli 12: 731 [560, 912] → 992 [688, 1445] does not establish growth at all;
  it excludes the fourfold scaling of a front and nothing more. Say "no faster than 1.6× for a fourfold side", not
  "grows 1.35×".
- Heredity: quantified for the decoder (repaired 73–100 %, inherited 0–1.6 %) on every one-bit mutant, which is a
  complete experiment for the map; the lattice part is 12 trials per setting on 64², which finite-size.md says can
  collapse with the decoder.
- Finite-size: the medium alone is converged (12.41 → 12.61 → 12.59 at 1024²); the full system is not, and
  ablation-v2's "10–46 cells" must therefore not be printed as a property of the system.
- The dose–response and the information dynamics: seed 1, 128², k = 3 plug-in. Enough to kill a hypothesis
  (finding 9), not enough to print as a table of properties.
- The 6502 and Redcode single-cell numbers in replicators-v2.md are "read from the run logs" after the result files
  failed to write and log lines were overwritten. That is exactly the provenance failure item 1 was meant to end.
  Rerun or delete.

**Not at all.**
- The drafts. Every one of the nine false sentences is still in them. I grepped: "no fixed points" at
  INTRODUCTION.md l.56, INTRODUCTION_MOTIVATION.md l.77, RESULTS_REPLICATORS.md l.26; "never reads its own output"
  at INTRODUCTION.md l.50; "there is no computation" at l.28; "the frame is the sweep" in all three motivation
  drafts; "quenched disorder [sicilia2008]" at INTRODUCTION.md l.115; "entropy pump" at l.125; "to our knowledge,
  new" at l.118; "at the pace of a front" at RESULTS_REPLICATORS.md l.87. RESPONSE.md says so; I say it is the
  largest remaining risk, because the author now has a results folder that contradicts his introduction.
- results/README.md, the index everything points to, is dated 2026-10-18 and still asserts "no fixed points" (H4) and
  "hash pinning" (H1, decision 3). The new rows were appended under it. It must be rewritten, not appended to.
- The co-authorship of agueraYarcas2024 is declared nowhere in the drafts.
- The t^⅓ exponent and the "sharp transition" of ablation-scan.md were never re-examined; DEFINITION.md §5 quietly
  demotes the transition to a crossover, which is right, but no result note says so.

## 2. The central result: is it explained?

**5. Explained in kind.** The structure is now: Lemma 1 (a uniform domain is untouched by the medium), so a fixed-point
domain is an absorbing set of the lattice map and a cycle domain is one only in phase; mixing between unequal phases
leaves a generic cycle (self-closure 6–39 % for the three open types) and the melt is then transients; closed types
nucleate in the melt and fill it (the frame table in mechanism.md §4: a band of 100 % fixed point where mixing is
strong and settling partial, the cycle surviving only at the edges and in the full-settling row). That is a
mechanism, it predicts the designed cycles' robustness, and the frame maps confirm it on three seeds and two
dictionaries. It replaces "fixed points are favoured by strong settling", which was wrong (the fixed point loses the
full-settling row).

**6. Not explained in degree, and the correlation is the wrong statistic.** Ten of the fifteen points are the same
point (closure 100 %, survival 100 %), and seven of those ten are closed for reasons that are theorems (one-state
types; the Proposition in DEFINITION.md §4). The index's non-trivial predictive content is tested on five generic
cycles, where I get r = 0.61, and the two cycles at 95 % closure die under any partial settling. So what the data
support is a threshold ("closure ≥ 99 % sufficed in 10 of 10, ≤ 39 % was fatal in 3 of 3, 95 % was not enough in
2 of 2"), not a correlation. Print the 2 × 2 table and the two exceptions; drop "r = 0.79".

The right quantity is the author's own borderline remark made into a definition: the probability that one whole turn
(exchange, then k majority passes, then f) returns a random-phase configuration of the type to the type, measured on
a small patch, as a function of the swap rate. Each open type then has a melting threshold p*(type, median) above
which it loses, and closed types have none. That is one map-level Monte Carlo per type, minutes of CPU, and it would
put the borderline pair on the same axis as the three open ones. It would also connect to the replicase ablation,
whose "error threshold at swap ≈ 0.01" is the same quantity for a constructed type, and to Eigen 1971, which is the
right citation for both.

**7. Is the proof in DEFINITION.md §4 correct?** Yes, as far as it goes. The pointer lemma holds because the two copy
commands fill 16 bytes before any tail bit is read; the theorem follows; and the Proposition is right because every
bitwise combination of states that agree outside header bits 4–6 is P(h_k)·τ for some k, and g is a bijection on
three bits, so f sends it to S_{k+1} whatever the tail. Three caveats the text should carry: (i) the proof covers
any bitwise combination, not only "a crossover or a majority of three", so say so and drop the "three"; (ii) it covers
self-closure only; the measured cross-closure of two Gray types (mechanism.md §3, "C = 100 %") is not a consequence,
since a crossover of two types can select a filler window, and should be labelled empirical; (iii) "self-closure is
5–67 %" for generic cycles in §4 does not match the 6–52 % of mechanism.md §2. Lemma 3 is correct. Lemma 2's range
k·r + 1 is right for the sequential mixing as defined. One more exact fact is within reach and missing: the
fixed-point search runs in seconds per dictionary, so the strays of every Gray design, and the fixed points of
Brotli 12 and 13, the two dictionaries whose fixed points actually win on the frame, can be enumerated exactly. The
one dictionary enumerated, Swarm F, is the one whose fixed points never matter on the lattice.

## 3. The retractions

**8.** Complete in the results folder, incomplete in the project. The five listed in RESPONSE.md are made; four more
that the first panel required are made in substance but not listed as retractions: the entropy pump (infodyn.md
measures the opposite), quenched disorder (finite-size.md says "deterministic freezing"), "rules compute nothing"
(DEFINITION.md §5) and the novelty of refutation-in-programs. Nothing in the new results rests on a retracted number.
Three things outside them do: RESULTS_REPLICATORS.md (the 1/(Nb) argument, the front, "no fixed point"), the old
part of RELATED_WORK.md (§2 row B: "the quenched hashing is a weak disorder that pins"), and results/README.md. The
"about 110 bits lost in the first step" sentence proposed in entropy-manipulators.md mixes orders: 128 − 16.6 is a
collision-entropy loss, while Lemma 3 bounds the Shannon entropy above by 93.5; since H ≥ H₂, the Shannon loss is
somewhere in [34.5, 111.5] bits, and the sentence must say which entropy it means.

## 4. The processor arm: result or programme?

**9. One half is a result, the other half has died, and the death is the finding.** The result: every evolved BFF
replicator sends (R|X) to the fixed point (R|mirror R) for 256 of 256 partners, from the first slot only; Redcode's
imp, the type that takes over joined pairs, is a fixed point; and the heredity contrast is stark and measured on
every single-byte mutant (BFF 80–85 % inherited, 0 % reverting; Keimli 0–1.6 % inherited, 73–100 % repaired).
The constructed-rule ablation closes the loop: tape heredity is 1.00 with verbatim copying of unread bits and 0.00
without, with the right negative controls (inert trait gives exactly 0). So "replicators of computational life are
fixed points and short cycles of the interaction map; heredity needs verbatim copying of unread tape" is a result,
on a narrow base (one BFF variant, four emerged soups, one constructed family, five seeds).

What died is the thesis the drafts were written for. The information dynamics say the processors' memories sit
still (a bit's past explains nearly all of its 0.1–0.3 bits) while the decoder rewrites the whole cell; the
dose–response finds no leading type for four of six processors at any budget; what makes BFF different is not
"computation" in any measured sense but a loop that copies bytes it does not interpret. That is von Neumann's
distinction between the constructor and the tape (1966), which Langton (1984) made the criterion for non-trivial
replication, and which I asked for in my round 2. The author has reached it from the data, and should say so in
those words: the second paper is "von Neumann's tape, measured in three substrates", not "what computation adds". The
"two sources" framing, bounded against unbounded work, entropy against computation, should go; the measurements
refused it.

**10. What the processor arm still lacks before it is a paper:** more than seed 1 for the rows quoted; the lost
6502/Redcode single-cell files; an emergence rate for BFF (eight soups cannot stand beside the paper's 40 %); and,
unchanged from round 3, an author outside the 2024 team, because this paper measures the author's own earlier
result against a toy built to deflate it.

## 5. The thesis now, and the venue

**11.** The first paper has become what the first panel said it was, and it is firmer than I expected in one day:
a dictionary decoder as a CA rule, with (a) an exact census whose largest fact, 69 million fixed points as a
grammar artefact of self-read literals with no measurable basin, is new and verifiable; (b) the contraction of the
iterates against three random-map nulls and 60 shuffles, which shows the words carry the attractor structure;
(c) attractors built by construction with a closure proposition; (d) selection by closure under the medium, with
Lemma 1 as the exact core. The physics has been demoted to its right place: the medium alone is a majority-vote
model with deterministic freezing and annealed coarsening, now size-checked, and the full system's lengths are not
converged. Venue unchanged from my round 3: Artificial Life first (readers who own the phenomena), Complex Systems or
the Journal of Cellular Automata second (the exact census and the Proposition are their kind of thing). Not
Physica D, not PRE: the author should stop spending on the physics of a voting model that is not his. A title that
claims exactly what is shown: "A dictionary decoder as a cellular-automaton rule: exact fixed points, constructed
cycles, and selection by closure in a mixing medium".

The second paper's thesis has changed, as in finding 9: from separating entropy reduction from computation to
measuring heredity as the copying of uninterpreted bits, in a decoder, a constructed replicase and BFF. That is an
old idea with new numbers, which is a respectable paper for Artificial Life or BioSystems; it is not a PNAS paper,
and it should not try to be.

## 6. Minimum remaining work

**12.** For the first paper, about six working days and 10 CPU-hours:
1. Rewrite abstract, introduction, methods and the replicator subsection on the claims table; rewrite
   results/README.md as an index of the new notes; declare the co-authorship. 3–4 days, no CPU.
2. Exact fixed points of Brotli 12, Brotli 13, ca-gray3c, ca-gray20c, ca-cyc5to12 (`map-exact.mjs … 1 16`, about a
   minute each) and the 2-cycle class search for Brotli 12 and 13 (10 min each). Under 1 CPU-hour. This replaces
   "the panel's exact search found a stray fixed point" with a count.
3. The whole-turn closure and the melting threshold p* for all 15 types plus Swarm F's 3-cycle, swap rates
   0.01–0.5 at median 0, 0.25, 0.5, 1, on a 32² in-phase and random-phase patch, 10 seeds. About 1 CPU-hour.
4. Droplets as in mechanism.md §3 for Brotli 13 and the 5-to-12 design, not only Brotli 12: 256², 400 turns, three
   settings, both orientations, 3 seeds, about 54 runs, 4 CPU-hours.
5. The frame mechanism at 512², the figures' size, Brotli 12 and 13, 3 seeds, 2,000 turns: 6 runs, 3 CPU-hours.
6. The replicator table's three sizes exist; print the Brotli 12 size dependence as a bound (finding 1).

For the second paper, one to two further weeks and about 70 CPU-hours: seeds 2–5 at 256² for the dose–response rows
quoted (Z80, Redcode pairs, 6502 at 16) and the information dynamics (about 20 CPU-hours); the 6502 and Redcode
single-cell runs regenerated with the fixed script (10); twenty BFF soups at the paper's setting to 16,000 epochs
(40, one core each); and a co-author.

## 7. Anything wrong

**13. Small errors found.** mechanism.md §2 prints Brotli 12's closure as 39 % and the 5-to-12 11-cycle's as 94 %;
the data file says 38 % and 95 % (the numbers in the text were typed, not generated). DEFINITION.md §4 "5–67 %"
against mechanism.md's 6–52 %. RELATED_WORK.md §0 says 218 verified and 30 partly; the file has 219 and 29.
dose-response.md's Brainfuck row is not a dose–response, since Brainfuck ignores the budget; say so in the table,
not only in the setup. replicators-v2.md §"processors on single cells" quotes numbers without files (finding 1).
mechanism.md §4 prints the frame table for seed 1 and describes seeds 2–3 in prose; print all three.

**14. A reading to resist.** The 68,964,123 figure invites the sentence "the decoder has many fixed points". The
honest sentence is in map-spine.md §5 and should be the one printed: 15,643 isolated fixed points plus 50 families,
none with a basin above 2·10⁻⁶ in 10⁶ starts, so "no fixed point that matters under uniform starts" is still true of
Swarm F while being false of Brotli 12 and 13 on the frame. The paper must not let the big number do rhetorical work.

## 8. The related-work chapter and the claims table (RELATED_WORK.md §0)

**15. Honest, with three corrections.**
- "No Lenia, neural-CA or evolved-rule work builds its attractors by construction" is true of those literatures and
  misleading as a novelty claim: prescribing the attractors of a map by construction is Hopfield 1982, and
  Wuensche–Lesser's reverse algorithm is already in the table. hopfield1982 is absent from references.bib. Word the
  claim as "within automata used as artificial-life substrates", and cite Hopfield as the general precedent.
- The table lacks the row the second paper now needs: "heredity requires copying of uninterpreted information:
  von Neumann 1966, Langton 1984, Maynard Smith–Szathmáry 1995 (limited against unlimited heredity), Eigen 1971
  (the error threshold); Keimli measures it in three substrates". All five keys are in the bibliography.
- "The medium, not the basin, picks the winner" as the contrast to Schaper–Louis is right; add Wilke et al. 2001
  (survival of the flattest) beside it as the population-genetic form of robustness beating abundance, and
  Kaneko's coupled map lattices for "the coupling picks the pattern", which §0.1 already cites in another row.
- Paragraph 7 of the chapter plan (entropy, erasure and computation, Bennett's depth, Lizier's modification) was
  written for the thesis that finding 9 retired. Cut it to Lizier as the method that returned the null.
- The 2026-10-19 map below §0 should be marked superseded or removed; its row B still asserts the quenched-disorder
  reading.
- The zenil2015 misuse is listed as a correction in §0.3 and is still in all three drafts (INTRODUCTION.md l.71).
- What is still new after the searches, as §0.1 states it, I accept: a decoder as the iterated local rule, its exact
  census, constructed attractors in such a rule, and closure as the selector under one medium. The open items in
  §0.5 (forward citations throttled, no PDF read in full) are stated, and should stay stated in the submitted
  version's acknowledgement of limits.

## 9. Verdict

The experiments of 2026-10-21 did what the first panel asked, mostly well, in one day. The map spine is exact where
it can be and honest where it cannot; the mechanism is a lemma plus a measured melting; the processor arm returned a
null that is worth more than the hypothesis it killed. What has not happened is the writing, and the writing is now
the whole risk: a results folder that says one thing under an introduction that says nine others. Priorities, in
order: the rewrite; the exact census of the dictionaries that win; the melting threshold in place of r = 0.79; then
submit the first paper. Leave the processor arm until it has seeds and a co-author.
