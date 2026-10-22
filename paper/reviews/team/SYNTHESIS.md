# Panel review of Keimli: synthesis

2026-10-21. Seven reviewers, three rounds, each reviewer keeping their own
context across rounds and reading all the others' notes between rounds.
The panel: a scientific-computation specialist, an optimization
specialist, a mathematician (discrete dynamics, CA theory), an
artificial-life scientist from the life sciences, an emeritus professor
of complex systems, a statistical physicist (also responsible for
statistics), and an information theorist. Their notes are in this
folder as `round1-*.md`, `round2-*.md` and `round3-*.md`; this file
condenses them. Where a number is quoted, the note that produced it is
named.

## 1. The verdict

All seven reviewers find a publishable paper here. None of them thinks it
is the paper the current drafts describe.

**The paper that exists now** is about the decoder as a cellular-automaton
rule:
- the attractor census of the rewriting map;
- the entropy decay under iteration;
- attractors prescribed by design (the Gray-coded cycles);
- the design rules that say when the lattice orders;
- an honest account of the lattice as deterministic freezing against
  coarsening, with the medium choosing which attractor wins.

The suggested venues are the *Artificial Life* journal, a full ALIFE paper
or *Complex Systems*, or *Physical Review E*, *Chaos* or *Physica D* if the
physics is done properly. The estimates of the minimum work range from one
to three weeks and from 50 to 200 CPU-hours.

**The paper the drafts describe**, that a decoder separates what
computation adds from what any entropy-reducing program does, is a second
paper. It is a programme, not yet a result. It needs the processor arm
done as a dose–response experiment and a census of the self-replicators of
the 2024 Computational Life study, which the author co-wrote. Without that
census, the ALife reviewer says, editors in that field would return it.
The professor suggests it be written with an outside co-author for that
reason.

The professor's word to the author, which the others echo: the census and
the designed attractors are yours, the grand dichotomy is not, and much of
it is not true. Claim the small thing exactly and it will be cited in ten
years.

## 2. Claims: what the panel would keep, reword, test or drop

Unanimous or near-unanimous across the round-3 claims tables.

**Drop.**
- "Rule systems compute nothing", or "no computation at all" in Life-like
  rules. Life is universal (Berlekamp–Conway–Guy 1982), so is rule 110
  (Cook 2004), and Langton 1990 is about where computation emerges in rule
  space.
- "The decoder never reads its own output, has no loop." It copies from
  its own output, which accounts for 18.2 % of output bytes, and 5 % of
  cells reread bits through the wrap (mathematics).
- "No fixed points." Swarm F has at least 48 verified fixed points, found
  by an exact search, and a fixed point wins under the frame (mathematics).
- "O(n) against O(c^n)" as stated.
- The "local entropy pump". The rewrite lowers the cell's entropy, its
  mutual information with its neighbours and the conditional entropy,
  all at once; nothing rises around the cell (information, measured).
- "Hash pinning by quenched disorder". Salting by position freezes exactly
  like no salt, and only salting by turn unfreezes it, so this is the
  freezing of a time-invariant deterministic rule (physics, measured).
- "The frame is the sweep". The frame and the uniform runs pick different
  winners (physics), and every searched dictionary scores about zero under
  uniform parameters, with the ranking inverted (optimization, measured).
- The q = 8 clock model. The Gray states have the metric of a 3-cube, so
  the designs are three coupled Ising fields (physics and mathematics).
- "No late first appearance" argued from the 1/(N·b) waiting time, and
  takeover "at front speed, 1.5 times slower at 256², proportional to
  basin^−½". The 716 was a median that silently dropped seeds which never
  reached 50 %; counted properly the takeover is faster at 256²
  (computation). The curves are the same at both sizes and creep
  logarithmically (physics).
- "Nothing replicates, nothing is selected." The rule that decides the
  winner is a fitness, and the medium copies states (ALife).
- "A hypothesis refuted in a system of programs is new." Lenski et al.
  2003 and Wilke et al. 2001 did this (professor).
- "Image at most 2^93.5". Entropy bounds the size of the image from below,
  not from above (mathematics).
- "No stray cycle" for the three-species design: it has a stray fixed
  point (mathematics).

**Keep, reworded.**
- **The output-entropy bound.** H(f(U)) ≤ 93.5 bits as an upper bound at
  turn 1 only, with the much smaller real figures beside it: the
  collision entropy is 16.5 bits and the min-entropy 8.3 bits for F
  (mathematics, information).
- **The global map, stated precisely.** It is deterministic, has period 4
  in time, and is non-uniform in space because of the gradients. Under
  uniform parameters it is a uniform CA only on 2 × 2 blocks
  (mathematics).
- **Replicators.** A self-maintaining type is a periodic point of the
  rewriting map, which is trivial replication in von Neumann's and
  Langton's sense (Langton 1984), with limited heredity: a mutant is never
  copied, only repaired or dissolved (ALife, measured). Better words for
  "species" and "invasion" are attractor types and domain competition.
- **The strongest lattice result: the medium, not the basin, picks the
  winner.** A uniform fixed-point domain is a fixed point of the whole
  lattice map, while a cycle domain survives only if all its cells share a
  phase (mathematics). Fixed-point domains survive noise that melts cycle
  domains (ALife).
- **The LZ motivation.** Cite Lempel–Ziv 1976, not LZ77, and Levin 1974.
  The decoder side corresponds to the coding theorem, not to LZ parsing;
  zenil2015 is currently cited for the opposite of what it argues
  (information, professor).
- **The entropy budget**, stated as coarse-grained entropy. Every run in
  the code is deterministic, the "annealed" ones included (information,
  physics).
- **"Built, not searched".** Say constructed by exhaustive enumeration and
  packing under an exact census check. Say the searched dictionaries were
  "selected by a hand-made score on the gradient frame, and by eye"
  (optimization).
- **"No late first appearance".** Say instead: within the decoder's
  transient at 128² and larger, with the lattice itself creating entries
  into basins (computation).

**Keep.**
- The pre-registration and the honest retraction of H1.
- The attractor census.
- The Gray-code inverse construction of attractors.
- The cycle null models.
- The swap-order anisotropy, which survives because the magnetisation bias
  cancels in an x/y comparison (physics).

**Needs an experiment before anything is said.**
- Every correlation length, the t^⅓ exponent, and the sharpness and order
  of the transition. The correlation never subtracts each bit plane's
  bias; corrected, the reference length drops from 39.8 to at most 9.5
  cells, and the local slope of the exponent drifts from 0.37 to 0.24
  (physics).
- The species and coexistence claims, and whether the "who wins" relation
  is a consistent ranking (ALife, mathematics, optimization).
- The design-table rules on several seeds (optimization).
- F's typicality against 30 shuffles (mathematics, optimization).

## 3. Defects found in the code and data

1. **The page's single-thread engine corrupts the vote snapshot.** The
   influence measurement writes five integers over cell 0 and part of
   cell 1 of the snapshot in the vote-partner modes. One thread is the
   page's default; the worker path is unaffected (computation).
2. **The replicator and species scripts ran the fixed swap order**, not
   the page's rotating one, and the harness defaults to it. The rerun
   changed no winner or share, but every correlation and anisotropy
   number from those scripts is affected (computation; confirmed).
3. **The correlation measure is unconnected** (`ablation.mjs` lines
   91–103) and is capped at 64 cells (physics, computation).
4. **The summary statistics are censored.** Seeds that never reach a
   threshold are dropped before the median is taken (computation).
5. **The period-12 cycle detector cannot see the Declaration's cycles**,
   of periods 154 and 182 (computation).
6. **Two older searches have a broken random generator** (period 10,466),
   so their "different seeds" replayed one sequence. Every candidate was
   scored on seed 11 only, which gives a winner's curse of about 28 % for
   Swarm G (optimization).
7. **No output carries provenance**: commit, wasm hash, script, swap
   order or dictionary checksum. The 20,000-turn files were made by an
   older detector and are mixed into the summary table (computation).
8. **The design-vote result "no head fits" is not exhaustive.** It is
   true only inside the searched template (optimization).
9. **Documentation is out of date**: `docs/lattice.md` and the `band.js`
   header still describe the fixed swap order (mathematics, computation).

## 4. The action list, in the order the panel converged on

| # | action | cost | unblocks |
|---|---|---|---|
| 1 | Rewrite the introduction, abstract and results drafts on the claims table above. Declare the co-authorship of the 2024 study. Add the missing literature: von Neumann; Langton 1984; Kauffman; Kaneko; Greenberg–Hastings; Fisch–Gravner–Griffeath; Toffoli–Margolus; Wuensche–Lesser 1992; Maynard Smith–Szathmáry; Wilke 2001; Price 1970; Lempel–Ziv 1976; Levin 1974; Bennett; Landauer. Fix the citation errors. | 2 days, no CPU | everything |
| 2 | Pipeline hygiene: a provenance block in every output; the rotating order as the harness default; one turn engine in the page with a 1-against-4-thread parity self-test (which also fixes defect 1); the docs fixed; the broken generator retired. | 1 day | all reruns |
| 3 | Observables: connected and phase correlations up to L/4 at equal phase; collision entropy, min-entropy, LZ density and phase mutual information in place of the zeroth-order byte entropy; censoring-aware statistics with bootstrap intervals; unbounded period detection. | 1 day + ~10 CPU-h | every lattice number |
| 4 | Map-level results: exact enumeration of F's fixed points and 2-cycles in C; collision-entropy decay under iteration against the hash:93 random-map null; 30 byte and 30 word shuffles of F and Brotli 13. | 1–2 days + overnight | the paper's spine |
| 5 | The physicist's E0 (recompute every ξ) and E1 (salt controls and rule replicas, with the wording "deterministic freezing"). | ~20 CPU-h | the physics section |
| 6 | Replicator section on the fixed pipeline: first appearance against size from 32² to 512² with verified cycles; droplets, critical nucleus, wall speed and robustness to noise as a competition matrix, with a transitivity test; the heritable-bits measure. | 1–2 days + 50–60 CPU-h | the replicator claims |
| 7 | Re-evaluate every named dictionary a claim rests on: several seeds, rotating order, uniform parameters as well as the frame. | ~12 CPU-h | the dictionary claims |
| 8 | Optional, for the physics paper: E3, the transition with periodic boundaries and finite-size scaling; E2, coarsening over more decades. | 70–190 CPU-h | Phys. Rev. E or Chaos |
| 9 | For the second paper: the processor arm as a dose–response over instruction budgets from 1 to 256; the BFF census (replicator frequency against 1/(tapes × interactions), inheritance of mutations, the 2026 follow-up). | 1–2 weeks, ~100 CPU-h | "what computation adds" |

## 5. Where the panel still disagrees

- **How the fixed point wins under the frame.** The ALife reviewer says by
  robustness, needing a critical nucleus, so lasting first appearance can
  be late. The physicist answers that under the frame the fixed point
  already holds 16–25 % of the cells by turn 100 in all ten runs, so
  nucleation is not the rate-limiting step there. It may be under strong
  uniform settling. The droplet experiments in item 6 decide it, run
  annealed as well, since the walls are pinned under quenched hashing.
- **The professor's cycle-projection null.** The physicist and the
  information theorist say the existing null already answers it. The
  optimizer says it does not, because the fitted table has an off-cycle
  state the null lacks.
- **The dichotomy.** The professor would restate it as bounded against
  unbounded work per step, in Bennett's sense of logical depth. The
  information theorist objects that logical depth is a property of a
  string, not of a local map. The mathematician proposes the entropy
  decay under iteration, measured for decoder and processors alike, as
  the operational replacement.
- **True randomness.** The physicist and the information theorist point
  out that annealed runs are deterministic too. The computation
  specialist answers that this is true of every pseudo-random simulation
  and should not drive the design; what matters is whether decisions
  depend on turn and position.
- **A MAP-Elites search.** The optimizer proposes it, with the census as
  the objective. The professor thinks design has beaten search and the
  apparatus is not worth building now.
- **What will matter in ten years.** The professor names the census, the
  designed attractors, and the replicator deflation once the BFF census is
  done. The gradient frame survives as the interactive tool and a figure,
  not as an evaluation; the 25-processor gallery and the framing "between
  computational and arithmetic life" do not.

## 6. What this means for the running batches

The wider replicator batch now running used the fixed swap order, the
censored summary statistics and the period-12 detector, and has no
provenance. Its winners and shares are usable as a qualitative survey.
Its takeover times and anything about the Declaration are not, until it
is rerun after items 2 and 3. The same applies to the 20,000-turn runs,
which also use the older detector.
