# Second panel review of Keimli: the brief

2026-10-22. The same seven roles as the first panel (../team/), reviewing the research after the experiments of
2026-10-21 that answered the first panel's and the twelve journal editors' concerns. Each reviewer writes
`round1-<role>.md` here, then reads the others' round-1 notes and writes `round2-<role>.md`. SYNTHESIS.md condenses them.

## What to read, in this order

1. ../team/SYNTHESIS.md and ../journals/SYNTHESIS.md: the earlier verdicts.
2. ../journals/RESPONSE.md: each concern, the experiment that answered it, and its status; what the experiments
   change; what is still not addressed.
3. ../../results/README.md, then the new results: mechanism.md, closure-vs-survival.md, replicators-v2.md,
   map-spine.md, dose-response.md, infodyn.md, bff-census.md, replicase-ablation.md, ablation-v2.md, finite-size.md,
   entropy-manipulators.md, look-and-say.md. Figures in ../../figures/.
4. ../../DEFINITION.md: the formal automaton, three lemmas, the Gray construction and the closure proposition.
5. The drafts, which predate the experiments and have NOT been rewritten: ../../MOTIVATION.md,
   INTRODUCTION_MOTIVATION.md, INTRODUCTION.md, METHODS.md, RESULTS_REPLICATORS.md, RELATED_WORK.md (with references.bib).
6. The code where a claim depends on it: ../../experiments/*.mjs, ../../../tools/ca-harness.mjs,
   ../../../src/changers/decode.wat and simple.wat, ../../../test/. You may run scripts (node, headless) to check a
   number; keep runs short (minutes), write any output to ../../data/review2/ (git-ignored), never kill processes by
   pattern, and do not edit anything outside this folder.

Ignore ../../results/redesign.md and anything under paper/data/redesign/: a separate agent is writing it right now.

## The questions

1. Which of the first panel's and editors' concerns are now settled, which are only partly, and which not at all?
   Judge the evidence, not the response table's status column.
2. Is the central result, "the medium, not the basin, picks the winner", now explained? Is the closure index the
   right quantity, is the correlation (r = 0.79 over 15 types) enough, and is the proof in DEFINITION.md §4 correct?
3. The retractions (correlation length, front speed, image bound, "no fixed points", the harness budget): are they
   complete? Does anything else in the results or drafts rest on the retracted numbers?
4. The processor arm: do the dose-response, information dynamics, BFF census and replicase ablation together make the
   second paper's claim (replicators of computational life are fixed points and short cycles; heredity needs verbatim
   copying of unread tape) a result rather than a programme?
5. What is the thesis now, and which venue? Has it changed since the first panel?
6. The minimum remaining work, in days and CPU-hours, to a submittable manuscript. Be concrete: name the
   experiment, the seeds, the sizes.
7. Anything wrong. Check at least three numbers from the results against the data or by rerunning something small,
   and say which.

## How to write

Plain prose, numbered findings, each tied to a file and a number. Say what you checked yourself and what you took on
trust. Disagree with the response table where the evidence warrants it. No praise without a reason.
