# Round 2 (second panel): optimization and search

Read: the six other round-1 notes. One new run of my own (§0), inline, nothing written outside this folder.

## 0. A new check forced by the physicist's finding: the droplet table at three settling passes

Physics §2.2 and §7.1: `droplets.mjs` and `closure.mjs` run one settling pass, the frame and replicator scripts three.
My round-1 check 4 (Swarm F's 3-cycle melts in random phases at median ≤ 0.5) copied droplets.mjs and so was at one
pass too. I reran the whole-lattice and droplet protocol at `passes: 3` (128², swap 0.1, 400 turns, phase seed 1,
n = 1 per cell, eight runs, 77 s). Shares in % at turns 20 / 100 / 200 / 400:

| run | median | result |
|---|---|---|
| F 3-cycle, random phases, whole lattice | 0.25 | 0.1 / 0 / 0 / 0 (melts, as at one pass) |
| same | 0.5 | 99.1 / 98.7 / 96.7 / **95.6** (held; at one pass 0.2 / 0.1 / 0.0) |
| same | 1 | 99.3 / 99.8 / 99.8 / 99.9 |
| Brotli 12 3-cycle, random phases, whole lattice | 0.25 | 1.3 / 0.6 / 0.5 / 0.6 (melts) |
| same | 0.5 | 84.6 / 96.8 / 93.7 / **83.8** (held; the table says 1) |
| Brotli 12 fixed-point disc R = 16 in coherent 3-cycle sea | 0.25 | disc 2.5 / 0 / 0 / 0; sea 91 / 75 / 42 / 0.6 (both die; the melt is not filled in 400 turns) |
| same | 0.5 | disc 4.2 / 6.6 / 10.6 / **24.0**; sea 94 / 91 / 87 / 72 (the disc grows into an intact sea) |
| same, random-phase sea | 0.5 | disc 5.0 / 8.4 / 14.4 / **29.8**; sea 80 / 89 / 82 / 66 |
| Brotli 12 3-cycle disc in fixed-point sea | 0.5 | disc 3.1 / 0.2 / 0 / 0 (erased by turn 200) |

Three consequences.
1. **The physicist is right that the mechanism has no uniform-parameter experiment at the frame's settling, and at
   three passes the mechanism at (0.1, 0.5) is a different one.** The open cycle does *not* melt there; the fixed
   point's disc grows from 5 % to 24–30 % in 400 turns through an interface with an intact sea (radius about 16 → 35
   cells, roughly 0.05 cells a turn), and the reverse disc is erased. That is asymmetric domain competition at an
   interface, not "melt, then nucleate in the melt". At (0.1, 0.25) both die and nothing fills the melt in 400 turns,
   as the mathematician's finding 8 says of the one-pass tracks. The frame contains both regimes: melting where mixing
   is strong, invasion where it is weak. mechanism.md §3–4 must be rewritten after physics item 1 is run; the sentence
   "closed types nucleate in the melt and fill it" should not survive it.
2. **The closure dichotomy survives, the threshold moves.** Open types still melt at median 0.25 and closed ones hold
   everywhere; what three passes change is where in (swap, median) the open types stop melting. That is exactly the
   per-type threshold p*(type, median) that the professor (finding 6), the physicist (item 3), the mathematician
   (finding 7) and the information theorist (findings 13–14) all ask for, and it must be measured at three passes.
3. **The single-cell cross-closure does not predict the interface winner.** In closure-ca-brotli-12.md, crossover
   children of fixed point × cycle land on the cycle (35 % at eight steps) and never on the fixed point (1 %), yet on
   the lattice the fixed point wins the interface. The majority passes over a uniform fixed-point neighbourhood are what
   carry it. So the physicist's item 4 (the lattice basin under one three-pass turn) is the right replacement for any
   cross-closure index, and my round-1 finding 14 (a target matrix of single-cell cross-closures as the search objective)
   needs that correction: the objective must be measured with the medium on.

## 1. Agreement and disagreement, by file and finding

**Physics §2.2 (one pass against three).** Agree, and §0 shows it changes the stated mechanism, not only its
numbers. Agree with §2.3 and computation finding 2 that t₅₀ sits on the plateau and the "1.35–1.6×" is an asymptote
artefact; my round-1 check 3 verified the arithmetic of the medians, not the meaning of the statistic, and I withdraw
my implicit acceptance of the size claim. Agree with §7.2 that quenched (0.2, ½) is slow coarsening, on the series data
the physicist read. Disagree mildly with §2.3's "write seeded growth from the melt": at (0.1, 0.5) and three passes
there is no melt to grow from (§0), so the wording should wait for the rerun. Physics item 1 (droplets at three
passes, 3 seeds) is the single most important run on the list and I put it first in §3.

**Mathematics finding 4 (mutual-closure corollary).** Agree, and it is the design lever I was looking for in round-1
finding 14: a set of species whose H₀ form a Gray code over the header bits above bit 6 is mutually closed, so no
interface can melt; a set whose H₀ differ in three or more header bits makes strangers at 57 %. That makes
cross-closure a *designed* quantity with two settings, and the author's three-species design already has both (B–C
adjacent, A not). The corollary should be stated with the 48-bit prefix of finding 3. The consequence for
"lively" dictionaries: fully mutual closure gives frozen stand-offs (replicators-table-v2: no Gray design reaches 50 %
on the frame in 2,000 turns), so the knob is partial mutual closure, chosen per pair by header adjacency. That is a
one-line addition to the design tool and a better plan than the census-scored packing search in README "Next
experiments 0".

**Mathematics finding 8 ("the seeds come from the start") against physics §2.6 ("the medium enlarges the basin").**
Both are consistent with §0, and they are not rivals: the fixed-point share of 18 % at turn 20 on the frame is far
above the 0.26 % the start supplies, so the three-pass medium makes entries (physics); the one-pass melt makes none in
400 turns (mathematics). The two cheap experiments (the mathematician's (i), the start with the basin cells removed,
and the physicist's item 4, the share of transient cells landing on the fixed point after one three-pass turn) decide
how much of each. Both belong on the list; neither is mine.

**Computation finding 5 (the Declaration at kmax = 64).** Agree. The Declaration is also the "text" control of the
search-score table and of the census ("texts give long cycles and many attractors"), so until it is run at kmax ≥ 200
the sentence "the Declaration produces no takeover in any setting" and any text-against-dictionary contrast on the
lattice are unmeasured. Computation finding 6 and ALife 1.8 (6502 and Redcode rows from overwritten logs): agree,
delete or rerun.

**Professor finding 6 (p\* per type as the quantity).** Agree, with the three-pass condition of §0 added, and with
the professor's link to the replicase error threshold at swap ≈ 0.01 (replicase-ablation.md §3): the same experiment on
the constructed type puts the two papers on one axis. The information theorist's return-time framing (finding 13) is
the same quantity read in time rather than in rate; one table serves both. Professor finding 7's exact enumeration of
Brotli 12, 13 and the designs: agree, it also delivers the strays of every design, which my round-1 item 8 asked for.

**ALife 2.3 (Swarm F's frame re-crystallises in phase).** Partly agree. The table shows F's 3-cycle holding 62–66 % of
the frame; whether the remaining third is in-phase cycle or melt is not in any file, and §0 shows that at three passes
F's cycle holds at median 0.5 without re-crystallising from anything. The frame map for F (round-1 item c; ALife item
2) decides it. ALife 4.3 (BFF's replicators are built, 2^−100): agree with the arithmetic and the conclusion that they
are not "listed" in the initial sample. As the optimisation reviewer I add one caution: the walk's difficulty is set by
the landscape's accessibility (partial copiers, the 2^405-member neutral set), not by the uniform-sampling probability
of the target, so "built by selection" against "found by neutral drift" (Knierim et al. 2026) is not decided by that
number and the paper should not pretend it is.

**ALife 1.1** (the "new attractor (heritable)" column is conversion): agree. **Information finding 14** (Hamming span of a
type's states as the trivial predictor: 0, 1–2, 29–64 bits): agree, it should be the first column of the table.
**Information finding 16–17** (the infodyn "rest" is a residual, representation-dependent): agree; outside my role.
**Computation finding 1a** (the harness version behind the mechanism data is unrecoverable): my rerun of closure.mjs and
the ALife reviewer's reproduce the stored tables line for line, so the function was the same; the hash should still be
pinned by committing the scripts.

## 2. What the others make me revise in my own round-1 note

1. **Check 4 and finding 1** were at one settling pass. Corrected in §0: the dichotomy holds at three passes, the
   melting boundary moves (F and Brotli 12's cycles hold at median 0.5), and the droplet mechanism at (0.1, 0.5) is
   invasion of an intact sea, not melting.
2. **Finding 6** ("F's melt must stay a melt"): withdrawn as stated; at three passes there is no melt at median 0.5.
   The frame map for F is still the right experiment.
3. **Finding 14** (optimise a matrix of single-cell cross-closures): revised. Single-cell cross-closure mispredicts the
   interface winner (§0.3). The search objective must be the lattice quantity: the melting threshold p\*(type) and the
   interface velocity between pairs, measured with the medium on at three passes, on 32² patches. The design knob
   stays the mathematician's header adjacency.
4. **Check 3**: I confirmed the KM medians arithmetically and did not question the statistic; the physicist and the
   computation reviewer are right that t₅₀ at the plateau is not a takeover time. Share curves, or time to 25 % and
   40 %, replace it.
5. **Item (e)** of my work list (competition matrix and transitivity from the droplet JSON): downgraded. The droplet
   data are one pass and n = 1, so nothing should be tabulated from them until physics item 1 replaces them.
6. My round-1 §4 took the single-cell dose table as seed 1 only; the ALife reviewer's reading of the replicase
   summary (two definitions of log₂ up/down, 11.47 against 7.48, from two script versions) is a provenance defect of
   the kind I asked the searches to avoid, and it belongs on the pipeline list with the others.

## 3. The panel's three most important corrections, ranked

1. **The settling-pass mismatch** (physics §2.2; §0 here). The closure and droplet experiments behind mechanism.md
   §2–3 were run at one third of the settling of the frame and replicator runs they explain, and at three passes the
   mechanism at the test point is invasion, not melting. Everything in mechanism.md §3–4 and the paper's "statement
   for the paper" waits on physics item 1.
2. **The statistics that stand in for mechanisms**: r = 0.79 (all seven: a 2 × 2 table of mostly theorems), t₅₀ on
   the plateau (physics, computation), "nucleation" without a radius series or a rate (physics, mathematics, ALife).
   Replace with the 2 × 2 count plus the per-type melting threshold p\*(type, median) at three passes, the share
   curves, and the two cheap seeding experiments (mathematics (i), physics item 4).
3. **Rows presented as measurements that are not**: the Declaration at kmax = 64 (computation 5), the 6502 and Redcode
   single-cell shares from overwritten logs (computation 6, ALife 1.8, professor), the Brainfuck dose rows (all), the
   replicase summary with two definitions (ALife §8). These are cheap to rerun or delete and expensive to be caught on.

The drafts and results/README.md are the largest *writing* risk (professor §1, everyone), but they are not a correction
to the research.

## 4. Consolidated minimum work for my role, deduplicated

Already demanded by others and not repeated here: droplets and whole-lattice survival at three passes, 6 dictionaries,
3 seeds (physics 1); the radius series (physics 2); p\*(type, median) for the generic cycles (physics 3, professor 3,
information 4; add Swarm F's cycle and the 5-to-12 12-cycle, and run it at three passes); the lattice basin after one
three-pass turn (physics 4); the start-without-basin-cells test (mathematics 8(i)); exact fixed points of Brotli 12, 13
and the designs (professor 2); Swarm F, Brotli 1, 9 and Gray 32 added to the closure table (ALife 2, computation);
the Hamming-span column and the 2 × 2 table in place of r (information 4); the Declaration at kmax = 200 (computation);
share curves in place of t₅₀ (physics 8, computation); `make tables` and the provenance gaps (computation).

What remains mine:

| # | item | seeds, sizes | cost | why nobody else has it |
|---|---|---|---|---|
| 1 | **Prediction-first extension of the closure test** to the dictionaries nobody has run: Swarm A–E and G, cyc567, gray4c/5c/6c, the Declaration's two long cycles (after the kmax fix). Predictions from closure written to a file before the runs; three passes; folded into physics item 1's batch | 128², 400 turns, 3 phase seeds, 4 settings | about 1 CPU-h on top of physics 1 | the index has only been tested on the dictionaries it was devised on |
| 2 | **The reading-length and longest-cycle rules at seeds** (design-gray3.md §6 l.150–160, §9 l.340–348): gray4c, gray5c, gray6c, cyc567, cyc5to12, the 24- and 26-species designs, plus one equal-reading design with the cycle lengths permuted (the author's own proposed test, l.346) | 256², 1,000 turns, uniform (½, 1), three passes, 5 seeds | about 40 runs, 3–5 CPU-h | the only candidate rule for the winner among closed types, where closure is silent (round-1 finding 5) |
| 3 | **Frame map for Swarm F and gray3c** (frame-mechanism.mjs): what the frame does with an open type and no closed competitor, and with three mutually closed ones | 256², 2,000 turns, 3 seeds | 6 runs, about 1 CPU-h | ALife 2.3 and my §0 disagree on what fills F's frame; the data do not exist |
| 4 | **Search provenance paragraph**: retire the double-precision LCG in ca-search.mjs l.17 and ca-lattice-search.mjs l.20; state that every searched dictionary was scored at seed 11, fixed order, under the gradient frame, that F was chosen by eye and ranks in the bottom half by the search's own score on held-out seeds, and that score gaps are within seed noise | — | half a day, no CPU | no other reviewer reads the search tools |
| 5 | **Design rule for liveliness, one paragraph in README "Next experiments 0"**: partial mutual closure by header adjacency (mathematics finding 4) as the knob; p\*(type) and interface velocity, measured with the medium on at three passes, as the objective; the frame as the picture only | — | text | replaces the census-scored packing search, which optimises the wrong quantity |

About two days and 5–7 CPU-hours beyond what the others list. Item 1 is the one that would make the closure result
a prediction rather than a description; item 2 is the one that would give the paper a second design rule.
