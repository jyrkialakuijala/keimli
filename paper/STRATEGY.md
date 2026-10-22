# Keimli: what nine days taught us, and the strategy for the next weeks

2026-10-22, written after the second panel. This condenses the project's record (git history, paper/RESEARCH_PLAN.md,
PLAN_AMENDMENTS.md, the three reviews, results/) into what we know, what we learned about how we work, and what to do
next. PLAN_PANEL2.md is the itemised work list; this is the reasoning above it.

## 1. What the project is

Keimli is a 512 × 512 lattice of 128-bit cells in a browser page over a hand-written WebAssembly module. Each turn
neighbours trade bits (mixing), bit planes are smoothed by majority (settling), and every cell is rewritten by a
changer: a Brotli-like decoder reading the cell as a compressed stream against a dictionary, one of 25 emulated CPUs,
or an arithmetic transform (look-and-say, Wolfram's elementary rules, sorts, the DCT). The mixing and settling
strengths run as gradients across the frame, so one picture is a two-parameter phase diagram. The dictionary is the
rule's genome: a few kilobytes of text, searchable, spliceable, designable.

The page is the primary artifact. The article grew out of it on 2026-10-18 and now has a research plan, amendments,
a formal definition with proofs, 248 references, 30 results files, three reviews (five referees, a seven-person panel
twice, twelve journal editors) and five pencil drafts that predate everything the reviews found.

## 2. The record, condensed

- **Oct 14–17, the platform.** Lattice, Life, the band engine, five then twenty-five CPUs, ten decoders, pairs and
  joinings, link machines, the byte palette, the entropy trace. Breadth first; nothing measured.
- **Oct 18, dictionaries by search.** Brotli searches 1–15, the swarm (Swarm F became the default by eye, not by
  score), presets, the shareable settings line. The research plan: the claim is the decoder as a rule, not the CPUs.
- **Oct 19–20, dictionaries by construction.** Gray-coded cycles built into the dictionary (3 to 32 types),
  pair-mode designs, the vote designs, the Life-like options. Twenty Gray 8-cycles became the default; it froze.
- **Oct 21, the reviews and the eight-hour session.** The panel and the editors said: a map paper exists, the drafts
  describe a different one, the thesis (computation against entropy) has no measurement. Twenty-one concerns were
  answered in four and a half hours: closure, droplets, the exact census, the dose-response, BFF, the replicase
  ablation, the corrected statistics. Two code bugs found (the harness budget, the one-thread vote snapshot).
- **Oct 22, the second panel and the redesign.** The panel found the mechanism experiments had run on a different
  medium from the frame (one settling pass against three) and reran them: no melt, invasion instead. The redesign
  found that "land and sea" freezes by Lemma 1 and that one chasing 3-cycle stays alive. Swarm F is the default again.

Pace: about 30 commits, 42,000 words of review, 30 results files, 190 MB of review reruns, in nine days. Most of the
science happened in the last three.

## 3. What we know (the science, in the order a reader needs it)

1. **The decoder as a rule has an exactly countable attractor set.** Swarm F: 68,964,123 fixed points in 15,693
   families (mostly self-read literals), one 3-cycle with 99.995 % of the basin, at least 51 two-cycles. Reproduced by
   three reviewers. ca-gray3c: 2,544 fixed points. Brotli 12 and 13 and the Gray designs: not yet enumerated (A6).
2. **The structure is in the words.** A random map with the decoder's one-step contraction does not end in its
   attractors; a byte-shuffled dictionary does not; a word-shuffled one does.
3. **Attractors can be built in and proved closed.** The Gray construction (DEFINITION.md §4): any bitwise
   combination of same-type states returns to the type in one step. Type whose headers differ in one bit are
   mutually closed. Strays above about 6 % of the basin spoil a design.
4. **Uniform domains are untouched by the medium (Lemma 1); interiors evolve by f alone (Lemma 2).** This is why
   designed cycles freeze into a static mottle and why "open sea that keeps melting" cannot be built.
5. **The medium, not the basin, picks the winner.** Rare fixed points (basins 0.3–2.8 %) take the frame in 99 of 100
   seeds against cycles with 93–100 % basins; establishment is size-independent (times to 25 % and 40 % equal at 128²
   to 512²) with a logarithmic creep after. Removing every fixed-point-basin cell from the start changes nothing: the
   medium creates them.
6. **How: at the page's settling, dissolution where the open type is disordered, invasion where it is ordered.**
   With partial settling and mixing, open types in random phases dissolve and in-phase domains hold (Lemma 1); the
   leading closed type fills the first and advances its wall into the second. This is nucleation by the definition
   in TERMS.md and results/nucleation.md: a critical radius of 5–8 cells against an ordered sea with a constant wall
   speed of 0.06–0.13 cells a turn, and spontaneous starts as rare clusters in a disordered sea at 10⁻⁶–10⁻⁴ per
   cell and turn, never inside an in-phase domain. The seeds are made by the medium (start replacement, n =
   20: no difference). Weak settling dissolves everything, strong settling freezes everything. Closure decides who
   holds (every open type dissolves at partial settling; every closed type holds) but not who wins a wall: Brotli
   12's second fixed point holds and loses. (results/mechanism-v2.md, n = 5 throughout.)
7. **Heredity is the sharp contrast, not computation.** Keimli's types repair mutants: 0 of 2,944 one-bit mutants are
   inherited. BFF's replicators inherit 80–85 % of single-byte mutations, because the copy loop copies bytes it never
   reads; the constructed replicase ablation finds exactly that ingredient necessary. Heritable information = log₂ of
   the fixed-point family size = bytes copied verbatim, whatever else is done with them (BFF 48–54, Keimli 0–3, the imp 0).
8. **Processors against the decoder.** Processors keep most of a cell's information and order the lattice locally;
   the decoder collapses the cell onto a handful of states. Redcode's imp, a fixed point with a 0.6 % basin, takes
   over joined pairs with the instruction budget (12 → 77 %). The information-dynamics decomposition returned a
   representation-dependent null: no measurement in the project shows "computation" doing anything.
9. **The medium alone.** Quenched hashing freezes the medium at a size-independent 12.6 cells at (½, 1); at (0.2, ½)
   it still coarsens (z ≈ 0.26); turn-salting coarsens at z ≈ 0.36. The full system's lengths are not size-converged.
   The panel advises printing no MSR length and writing no physics paper.
10. **Entropy measures.** Collision entropy is exact against rules of known loss and is the right whole-cell measure;
    block entropy is blind to rule 90's loss; the stopping-time bound H(f(U)) ≤ E[bits read] holds (93.5 bits for the
    decoder, 72–99 for look-and-say by base). "Bits lost" figures are collision figures, not Shannon losses.

11. **A fixed point and a replicator differ by whether the copy depends on the original** (DEFINITION.md §6, added
    2026-10-22). A copier is a state that, joined with almost any partner, leaves itself and a copy; its heritable
    information is log₂ the size of the family of variants that still copy, the bytes the map carries without
    reading. Above zero it is a replicator; at zero it is a crystal (the imp; the decoder's types on the lattice).
    No instruction set or universality is needed: one copy operation the state can invoke on itself suffices
    (Langton's criterion); rule 90's copying of everything is the trivial end where nothing can be selected.

Retracted along the way, each by a later measurement: the H1 arrest claim; "no fixed points"; the 2^93.5 image bound;
ξ ≈ 60 (plane bias); "takeover moves as a front" and its 716 / 1,093 speeds; the t^⅓ hash-pinning story; "closed
types nucleate in the melt"; the 1.35–1.6× size ratio; "the 6502 single-cell leader takes 36 %" (seed 1, one pass).

## 4. What we learned about how we work

The failures repeat, so they are worth naming once.

- **A parameter not printed on the table is a parameter that will differ between tables.** Settling passes (1 against
  3), the swap order (fixed against rotating), the instruction budget (always 256), the period detector (64 against
  154). Each cost a result. Rule: every results table states passes, order, budget, seeds, size, turns and the kmax
  of any detector, generated from the data file, never typed.
- **Hand-copied numbers drift.** 39 / 94 against 38 / 95; 7.48 against 11.47 as two definitions; "90 % by turn 86–95"
  for a design that never reaches 70 %. Rule: tables are regenerated by a script from JSON with a provenance stamp,
  or they do not exist. One `make tables` entry point (B3).
- **A statistic can hide a table.** r = 0.79 over 15 points was 10 theorem points and 5 generic ones; t₅₀ sat on a
  plateau; "1.35×" was where the plateau crossed one half. Rule: print the counts and the curves; print a correlation
  only over the points that could have failed.
- **Results outrun drafts.** Every draft still carries every retracted sentence. Rule: drafts are written on the
  claims table (RELATED_WORK.md §0) and the results index, and each claim in a draft names its results file; a
  retraction edits the drafts the same day.
- **The eye and the score disagree, and the eye wins the default.** Swarm F scored 14 against the swarm's 47; the
  twenty Gray cycles scored well and froze; the user keeps choosing the picture. Rule: liveliness is scored by block
  change over the picture region, and the final choice is by eye; the score only shortlists.
- **Construction beats search for understanding; search beats construction for pictures.** The Gray construction
  gave the proofs and the closure mechanism; the swarm found the chasing-phase mechanism that the construction then
  explained. Keep both; use construction to explain what search finds.
- **Self-review by role-played panels works when each reviewer must check numbers.** Both panels found code bugs and
  a design-level error that the author (and the assistant) had not, because each reviewer reran something. Rule:
  every review round requires three checked numbers per reviewer and names them.
- **Experiments outrun the pipeline.** The harness, the page's two engines, the search tools' broken generator and
  the review reruns at "whatever the script defaults to" are one codebase with four versions of the turn. Rule: one
  turn implementation (Band.runTurn) for the page, the harness and the experiments; a parity test; the harness
  defaults equal the page's defaults.
- **Breadth was cheap and is now a cost.** Twenty-five CPUs, fifteen decoders, forty dictionaries, eleven pair modes.
  The paper uses one decoder, four dictionaries and two CPUs. Rule: no new changer, mode or dictionary until paper 1
  is submitted, unless it is a one-line preset the user wants to see.
- **Time boxes work.** The eight-hour session finished in four and a half; the redesign in two; the panels in under an
  hour each. The reruns the second panel asked for are a day. Keep budgeting in hours and finishing early.

## 5. The thesis now, in one sentence each

**Paper 1 (the map paper, Artificial Life; Complex Systems or JCA as fall-backs).** A dictionary decoder as a
cellular-automaton rule has an exactly countable attractor set carried by the dictionary's words; attractors can be
built in and proved closed; in a medium of exchange and majority a type holds a region if its own bit exchanges return
to the type, and the medium creates the closed types and advances their walls, so rare fixed points and designed
cycles displace large-basin open cycles; and the surviving types are crystals, not copiers: they have no heredity of variants, which separates them from the
replicators of BFF by exactly the bytes a copier carries verbatim; a decoder type with one self-copy command
and a free tail crosses that line with no processor at all.

**Paper 2 (origin and heredity of replicators in BFF, Core War and a constructed replicase; an outside co-author).**
The replicators of computational life are fixed points of their interaction maps; what makes them heritable is
verbatim copying of the tape; BFF's are built by the walk, not listed in the start.

**Not claimed:** anything about computation as such; a coarsening exponent or a correlation length for the full
system; emergence rates; anything measured at one seed or one settling pass.

## 6. Strategy for the next three weeks

**Order of work.** Finish the mechanism (A1–A4, running; A5–A8 after), build the heritable type (A9, so the paper's
contrast is shown inside one system), then the corrections (B1–B3), then write paper 1 on OUTLINE.md (E), then paper
2's experiments (F). Writing waits for A1 and A9; B can overlap with A.

**Decision rules.**
1. No number enters a draft without a results file and a data file behind it; the results file names its script,
   commit, wasm hash, passes, order, seeds, size and turns.
2. Every claim in the drafts is one row of the claims table with a status: shown, to show, retracted.
3. An experiment is run with its prediction written first (PLAN_AMENDMENTS.md style); the write-up says whether the
   prediction held.
4. A retraction is propagated to every draft, the results index and the docs the same day it is made.
5. The page changes only to fix a bug, to serve a figure, or to add a preset the user asks for; the default
   dictionary is the user's choice by eye.
6. Commits only on "push to github"; the private demo on "update the demo"; raw data never in git.
7. Reviews before submission: one more panel round on the finished manuscript, each reviewer with three checked
   numbers; then the editors' pass.

**Timeline.** Days 1–2: A1–A8 and the mechanism write-up (results/mechanism-v2.md replaces mechanism.md). Days 3–4:
B1–B3, C, D; the results index rewritten. Days 5–8: paper 1 written on the claims table, figures regenerated from v2
data, the heredity contrast as the closing section, the co-authorship declared. Day 9: the panel on the manuscript.
Days 10–12: corrections and submission to Artificial Life. Weeks 3–4: F1–F10 for paper 2 while finding the co-author.

**What to say no to.** A physics paper; 1024² for the full system; more CPUs, decoders or pair modes; more dictionary
searches; the information-dynamics programme beyond the identity control; Kolmogorov or "computation" measures;
anything that needs a new memory layout in the module.

**Risks.** (a) A1 contradicts the three reviewers' n = 1–3 reruns: then the mechanism section states the conditional
rule and the paper is a census paper with a smaller lattice section; it still stands. (b) The Declaration at kmax = 200
shows takeover: then the "text dictionaries" row changes and the selection rule is retested there. (c) The drafts
resist rewriting because their motivation (MOTIVATION.md) is the dropped thesis: write the new introduction from
SYNTHESIS.md §4 and keep MOTIVATION.md as the discussion's history, not its frame. (d) Priority and credit around
BFF: the co-authorship is declared on the first page; the origin result is phrased as a refutation of our own
deflation, which protects it.

## 7. Open decisions for the author

- Whether the heredity contrast (one table) closes paper 1, as the panel now recommends, or waits for paper 2.
- Who the outside co-author for paper 2 is.
- Whether the old replicator batch (replicators-more.sh, stopped since 2026-10-21, pre-fix pipeline) is killed; its
  results are superseded by replicators-v2.
- Whether the four dictionary files without a trailing newline are normalised (immaterial for attractors; B3).
- Whether "Three phases chasing" joins Swarm F as a featured preset in the paper's figure of designed dictionaries.
