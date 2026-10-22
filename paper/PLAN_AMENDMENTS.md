# Amendments to the research plan after review, and the pre-registration

Written 2026-10-18 against the working tree after commit ef227cc, after the five
reviews in `paper/reviews/`. This file changes the plan; it does not replace
it. Where the two disagree, this file wins. Section 3 is the pre-registration
the Science review asked for: seeds, measures, the decision rule for each
hypothesis and what would make us retract each claim. Section 4 says what had
already been observed when this was written, so that nobody can mistake it for
a prediction.

## 1. Corrections to the plan's description of the system

Read off the code (`src/lattice/lattice.wat`, `src/lattice/band.js`,
`src/changers/codecs.wat`, `src/page/lattice.html`), not from memory.

1. **Topology.** The lattice is a bounded plane, not a torus. The median
   clamps coordinates at the edges (a missing neighbour counts as the cell
   itself), and the swap phases pair the leftover edge column or row along the
   edge. The plan's table is wrong. Every quantitative measurement is taken in
   the bulk (a margin of n/8 cells excluded on each side) until a periodic mode
   exists; adding one to the module is on the list, not done.
2. **Noise is quenched.** Every swap and median decision is the hash of the
   two 32-bit contexts with salt 0, so identical neighbourhoods decide
   identically at every place and time. The page and the harness now offer an
   annealed control (salt by turn, `saltMode` 1) and a position control
   (`saltMode` 2); they are experimental controls, not settings.
3. **The mixing gradient folds.** The slider p maps to the exchange rate
   2p(1−p), so p = 0 and p = 1 are both the identity and the frame's x axis
   runs 0 → ½ → 0 in rate; with gradient power 0.2 the strong mixing lives in a
   narrow central column. Uniform-parameter runs are specified by p, and the
   rate is reported beside it.
4. **The decoder.** Kind 36 copies 2 to 13 bytes (2-bit code: 2, 3, 4 + 1
   bit, 6 + 3 bits); "longest copy 3" in the plan's table is the kind-0
   slider and does not apply. The stream never runs out: the bit reader wraps
   at the end of the cell and re-reads it, header included, until the 16
   output bytes are full or 1,024 bits have been read. At the reference
   setting 5.0 % of random cells read past 128 bits and none reach the cap.
   The 12 header bits (V = 4096) count toward the bits consumed.
5. **Reachable dictionary.** A back-reference reaches at most 64 bytes behind
   the window end (explicit distance 1 + 6 bits; the ring never exceeds it in
   practice), so with window ends 0..V−1 the decoder reads V + 63 bytes of the
   dictionary: 65 at V = 1, 72 at V = 8, 191 at V = 128, 4,159 of 4,400 at
   V = 4096. Bytes 4,095 to 4,335 of a 4,400-byte dictionary are never read
   and are exactly neutral; of the 8,123-byte Declaration, bytes 4,095 to
   8,058 are never read.
6. **Page versus file.** The build strips trailing newlines from a dictionary
   file and adds one back, so a file that does not end in a newline is one
   byte longer on the page than in the harness and in the searches that
   produced it. This affects `ca-brotli-1`, `ca-brotli-9`, `ca-brotli-13` and
   `ca-swarm-d` (4,401 bytes on the page, 4,400 in the harness); the reference
   dictionary F and Swarm A agree. The extra byte is reachable (it lies in the
   wrap region read from small windows). Decision needed from the author:
   which version is canonical; the paper will cite the file's SHA-256 beside
   its id in every caption.
7. **Default grid.** The page opens at 1024 × 1024 (512 on eight cores or
   fewer); `docs/changers.md` says 128 × 128 and is out of date.

## 2. Changes to the design

- **Uniform parameters for every number.** All quantitative runs use a
  uniform swap p and a uniform median p over the grid. The gradient frame
  remains Figure 1b and Figure 2, as a picture of the diagram and never as its
  source. Harness: `makeSim({ swap: [p, p], smooth: [q, q] })`.
- **The order parameter.** Byte-labelled domains are dropped. The primary
  spatial measure is the Hamming correlation C(r) = 1 − 2⟨d_H(x, x+r)⟩/128
  along x and along y separately, per byte group of eight bit planes at every
  sample and per bit plane at turns 10, 100, 400 and 1,000. The correlation
  length ξ is the r at which the mean C(r) over the 16 byte groups crosses ½,
  interpolated linearly in log r between the measured distances
  1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 64. The activity is d1 (bits changed
  per turn per bit) in the bulk. The hand-made regime classifier stays only as
  a secondary measure in the dictionary paper.
- **Null model for the rewrite stage** (the editors' single biggest gap): the
  map `hash:K` keeps the first K bits of the cell and replaces the other
  128 − K by a fixed hash of them. It is a random many-to-one map with image
  size exactly 2^K and H(f(U)) = K bits. K = 93 matches the decoder's
  consumed-bits bound (section 4); K = 64 is a stronger contraction.
- **Dictionary controls:** the same bytes shuffled (three shuffles), the words
  shuffled with the whitespace left in place (the editors' addition, separating
  word identity from word order), and the bytes reversed.
- **Two papers, not one and a half** (the retired professor's section 6). The
  physics paper is H1, H4, H5 on one decoder and one dictionary with the
  controls above. The dictionary paper is Q2, Q3, Q6, Q7 and the gallery; its
  search methodology is to be reframed as quality–diversity with a hand-made
  behaviour characterisation, and the ALife postdoc's recommendations 1 to 11
  apply to it. The rest of this file is about the physics paper.
- **H5 is demoted** to a figure of the activity budget (bits moved, bits
  median-changed, bits rewritten per turn against p), named activity and not
  entropy; mixing is a bijection on each pair and raises no configuration
  entropy.
- **H6 is cut** from the claims. One paragraph in the dictionary paper's
  discussion at most; if any human judgement is reported it comes from
  independent, blinded viewers choosing pairwise between short clips.
- **H7 becomes a symmetry test** in the dictionary paper: XOR and bit
  rotation commute with the bitwise stages, add and multiply mod 95 do not;
  the prediction is that invariance of the lattice statistics is best under
  XOR and worst under the affine transforms.

## 3. Pre-registration for the physics paper

**Protocol.** Grid 256 × 256, bounded plane, bulk margin 32 cells, 1,000
turns, seeds 1 to 10 (the module's xorshift32 seed; `reset(seed)`), the
reference dictionary `ca-swarm-f` (4,400 bytes, the file as shipped), the
Brotli-like decoder with 6 skipped bits, header range V = 4096, offset 0,
cells on their own, 3 median passes over the 3 × 3 block. Parameter points:
swap p ∈ {0.5, 0.2, 0.05} (rates 0.5, 0.32, 0.095) and median p ∈ {1, 0.5}.
Conditions: the seven rows of the plan's ablation matrix, each at every
parameter point of the stages it uses, with quenched (salt 0) and annealed
(salt by turn) hashing; and the `hash:93` and `hash:64` null models in place
of the decoder for the full three-stage row. Samples at every turn to 10,
every 5 turns to 100, every 20 turns to 1,000. Statistics are the mean and
the 10th to 90th percentile band over the ten seeds. Runner:
`paper/experiments/ablation.mjs`; batch: `paper/experiments/ablation-all.sh`;
data: `paper/data/ablation/`.

**H1, coarsening and its arrest.** Prediction: with rewriting off (MS−) at
median p = 1 the bulk freezes, d1 < 10⁻³ by turn 1,000, and ξ stops growing
(ξ at 1,000 within 10 % of ξ at 400); with rewriting on (MSR) at the same
parameters d1 stays above 0.01 at turn 1,000 in every seed (10th percentile),
and ξ at turn 1,000 differs from the MS− value by more than the two seed
bands. Decision rules:

- If MSR's d1 at turn 1,000 falls below 0.01 at every parameter point, the
  "sustained dynamics" half of claim 1 is retracted for this dictionary.
- If `hash:93` reproduces MSR's d1 and ξ within the seed bands at every
  parameter point, "decoder-specific" is retracted and the claim becomes
  "any many-to-one per-site map of this contraction"; if `hash:64` does so as
  well, the claim becomes "any strongly contracting per-site map".
- If the annealed MS− runs do not freeze where the quenched ones do (ξ still
  growing at turn 1,000, d1 above 10⁻³), the freezing is hash pinning and the
  paper says so; the arrest in MSR counts as decoder-driven only if the
  quenched and annealed MSR runs agree on d1 and ξ within the seed bands.
- Anisotropy: ξ along x and along y are reported separately; a claim about ξ
  is made only if the two agree within 20 %, otherwise the anisotropy is the
  result reported.

**H4, the decoder as a map.** Measured before this document (section 4);
registered here are the comparisons still to be made: the codebook decoder's
image computed exactly from the bigram count and compared with its sampled
Chao1; the attractor census of the decoder iterated alone (the −−R row:
distinct cells and d1 against turn, the fraction of cells on a fixed point or
a 2-cycle by turn 1,000); and the random-mapping null (image fraction
1 − 1/e, H(f(U)) ≈ 128 − 0.83 bits) against the measured H(f(U)) ≤ 93.5 bits.

**Dictionary structure at the lattice level (the plan's Q3, physics part).**
MSR at the reference parameters (p = 0.5, median 1) with F raw, F shuffled
(three shuffles), F word-shuffled and F reversed, ten seeds each. Decision:
if ξ, d1 and the bulk byte entropy at turn 1,000 of every control lie within
the raw dictionary's seed band, the claim that the dictionary's structure (not
only its alphabet) shapes the dynamics is retracted for this dictionary and
the article says that the alphabet alone matters. Reversal is the weakest
control (copies run forward in both) and is reported but does not decide.

**Scaling.** The reference and MS− conditions at 128, 256 and 512 cells with
the same margin fraction, three seeds: if ξ at turn 1,000 changes by more than
20 % between 256 and 512, the 256 results are reported as size-dependent and
the figures move to 512.

## 4. What had been observed when this was written

- The decoder-map battery (`paper/data/decoder-map/`): for every dictionary
  and header range the consumed bits (81.7 at V = 1, 93.8 at V = 4096) and the
  output-byte sources (36.9 % literal, 18.2 % copied from the output, 44.9 %
  copied from the dictionary) are identical to the first decimal, because the
  command skeleton depends only on the bits; E[min(c, 128)] = 93.5 bits bounds
  H(f(U)); no fixed point in 10⁶ cells for any dictionary; the output byte
  entropy is 7.1 bits for texts and 5.7 to 6.4 bits for searched dictionaries;
  the shuffled dictionaries match the raw ones on every first-order statistic.
- Six runs of the ablation batch had been printed to the log (MS− at three
  parameter points, seed 1) when the decision rules above were written: the
  quenched MS− runs at median p = 1 had d1 < 10⁻⁴ and C(32) ≈ 0 at turn 1,000.
  No MSR, null-model or annealed run had been seen.
- The second-order decoder statistic (the conditional entropy of the next
  output byte given the previous one) was added after the first battery, when
  the first-order statistics had turned out blind to byte order. It sees the
  order: for F the output's conditional entropy is 5.05 bits raw, 5.30
  shuffled, 5.07 word-shuffled, 5.08 reversed.

## 5. Additions after the first seed of the main batch (post hoc, declared)

Seen before these were added: the 51 seed-1 runs of the main batch that had
finished (MSR with the decoder at all six parameter points, quenched and
annealed; hash93 and hash64 at most points). What they showed: with uniform
parameters and median p of 1 or 0.5 the three-stage lattice is nearly uniform
in the bulk (fewer than 1 % distinct cells, byte entropy 1.3 to 2.0 bits,
ξ at or beyond the 64-cell measurement range) while 26 to 45 % of its bits
change every turn, so the bulk is a spatially uniform, temporally cycling
field; the hash null models at the same points give spatially uncorrelated
bits on the hashed planes (C(1) ≈ 0.45 to 0.7, ξ ≤ 4 at median p = 1) and
freeze (d1 < 10⁻³) where the decoder churns.

Added in response, without looking further:

- **A scan along the median probability** at swap p = 0.5: median p ∈ {0.3,
  0.2, 0.1, 0.05, 0.02} for MSR, MS− and the two nulls, quenched and annealed,
  seeds 1 to 5 (`paper/experiments/ablation-scan.sh`). Prediction: the
  gradient frame's "granular sky" and "domains below" are two phases along
  this axis, with a transition at a median p between 0.02 and 0.3 where ξ is
  finite and larger than 4 cells and d1 is between 10⁻³ and 0.2; the decision
  rules of H1 are applied at that point rather than at median p = 1.
- **A second null, `hashdict:93`:** the hash map whose replaced bytes are
  drawn from the dictionary's own bytes (its exact byte histogram) instead of
  uniform bits, so the null has the decoder's alphabet but no copy structure.
  The H1 specificity rule applies to it as to `hash:93`: if `hashdict:93`
  matches MSR within the seed bands, the result is "any contracting map onto
  this alphabet", and the dictionary's copy structure is not shown to matter.
- **The cycle null models `cycle3` and `cycle3f`** (added after the main
  batch, see `results/ablation-main.md` section 4): a map with one global
  3-cycle and nothing else, with random states or with the reference
  decoder's own three states. Rule: if `cycle3f` reproduces MSR's ξ and d1
  within the seed bands across the median scan, the lattice phenomenon is
  explained by the attractor alone and the decoder's gradual contraction and
  alphabet do not matter; if `cycle3` does too, neither does the alphabet.
- **The attractor census** (`decoder-cycles.mjs`) was run after the main
  batch showed −−R collapsing to four cell contents; it was not planned and
  its results (one 3-cycle for F) are a finding, not a confirmed prediction.
- **A designed dictionary** (`design-dict.mjs`, `type-run.mjs`,
  `invasion.mjs`, results in `results/design-gray3.md`) was built after the
  census, on the author's request, to test the conclusion that the attractor
  structure and the funnel's steepness are what the lattice responds to. It
  is an existence proof and an exploratory look (one seed per parameter
  point, two at median p = 0.5 annealed), not a pre-registered test; any
  claim from it needs the seed bands and the system-size check of section 3.
- **The swap order** (2026-10-20). The four swap phases of a turn ran in the
  fixed order UD0 LR0 UD1 LR1 in every run recorded here, so the left–right
  exchanges always acted last before the settling and the rewriting; the
  author observed more lateral than vertical propagation on the page. The
  page now turns the phase pattern by 90° each turn (four variations; a
  selector under Mixing's More settings offers the fixed, mirrored,
  palindromic and random orders too). The harness keeps the fixed order
  unless `altOrder` names a scheme (`ablation.mjs altorder=rotate`), so the data above stand as recorded; the
  lattice runs the article prints must be repeated with the alternating
  order, or the article must state the fixed one. The anisotropy itself is
  measured in `results/swap-order.md`.

## 2026-10-20, later: the Life-like options

Three additions on the author's request, all in the page and the module, none
yet used in the article's runs. (1) Mixing rule "Synchronous": each differing
bit taken from a hashed 4-connected neighbour, written to the local pixel only
(`mix_sync_zone`); isotropic, orders much less than the swaps
(`results/life-vote.md`). (2) Rewriting writes to the A cell and the B cell of
a pair separately (`writeA`, `writeB`). (3) Cells entries "Self and its
4-neighbour vote": the pair partner is a cell built from the four neighbours'
bit-plane vote (three or four set gives 1, none or one gives 0, two keeps the
own bit), taken from a snapshot before any cell is rewritten, joined by any of
the five pair modes (values 8 + m), only the cell itself written back. Checked
against a JavaScript reference in every mode and both roles. The halo depth of
a band grew by two rows for the vote's reads (`depthFor`).

## 2026-10-21: the motivation

The author set the article's motivation (`MOTIVATION.md`): computational
life (Core War, Tierra, Avida) gives the richer phenomena but is a general
computation and hard to analyse; arithmetic life (Life, cellular automata)
is tractable but poorer; the decompressive automaton sits between, keeps
the "running a program" part that a decoder is, in linear time per cell
instead of the exponential cost of deciding a program, and is
information-centric, as the practice of measuring real-life complexity by
Lempel-Ziv rather than Kolmogorov complexity already is. The purpose: to
separate the phenomena of computational life that come from computation
proper from those that come from running any program that pumps entropy
out of its cell into its surroundings. The introduction and the discussion
should be rewritten around this; the CPU changers are the comparison arm.

The opening is drafted in `INTRODUCTION_MOTIVATION.md` (2026-10-21): the two lines of artificial life and the gap, the decompressor as the rule, the managed and position-varied entropy budget, what the model is for, the claims stated so that they can fail, and the sentences to be careful with. Every claim is marked shown or to show against the results notes.

A first pencil draft of the introduction is `INTRODUCTION.md` (2026-10-21), built from `INTRODUCTION_MOTIVATION.md`; section numbers refer to the outline in `RESEARCH_PLAN.md` section 6 and will move with it.

A short methods draft is `METHODS.md` (2026-10-21): the page and its module are the primary artifact, the text names what each stage does and where the exact definitions live.

A results subsection is drafted in `RESULTS_REPLICATORS.md` (2026-10-21): the replicators of computational life are fixed points and short cycles of the rewriting map; here they are listed by census and prescribed by design, and their spread is the medium's work; two corollaries for the processor arm (the processors' attractor census; what a processor adds is run-dependence and hidden state, not replication).
