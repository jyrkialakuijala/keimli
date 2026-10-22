# Physica D: Nonlinear Phenomena: the handling editor's report on Keimli

2026-10-21. I read BRIEF.md, the panel's SYNTHESIS.md, INTRODUCTION.md, RESULTS_REPLICATORS.md,
results/README.md, results/replicators.md, results/entropy-manipulators.md and the RELATED_WORK.md
map. The 10-page draft PDF was not read line by line.

**What I could and could not verify on the web.** Elsevier's journal page gives the scope as
"research and review articles reporting on theoretical and experimental work, techniques and
ideas that advance the understanding of nonlinear phenomena". It names pattern formation and
collective phenomena, integrable and Hamiltonian systems, data-driven dynamical systems and
complex networks, and it encourages emerging application domains. The same page confirms that
articles become free to read 48 months after publication. ScienceDirect returned 403 for the Guide
for Authors and the aims-and-scope page, so the following are **not confirmed**: article types
beyond research and review articles, any length limit, the APC, and whether highlights, a graphical
abstract or a data statement are mandatory. A third party (LetPub) gives a first review time of
3–8 weeks. A special issue, "New Horizons at the Intersections of Machine Learning, Dynamical
Systems and Algorithmic Information Theory", had Hamzi, Dingle, Hutter, Li and Schmah as guest
editors. Its deadline was given as 2026-02-28 by an aggregator and has probably passed. Those
editors are still the natural readers of this work.

## 1. Fit and desk decision

Physica D has been a home for cellular automata since the 1984 Los Alamos proceedings (Physica D
10: Wolfram, Vichniac). It also published Crutchfield–Hanson's computational mechanics of CAs and
much of the work on coupled map lattices. A lattice whose local map is a decompressor is a
discrete coupled map lattice with an unusual, analysable local map. That is squarely in scope
**if** it is presented as nonlinear dynamics: the map's attractors and entropy loss, how the
attractors are constructed, and the spatial dynamics of domains, freezing and fronts. It is not in
scope as an artificial-life manifesto or a software gallery.

**Desk decision on the current drafts: return without review, with an invitation to resubmit.**
The reasons:
- The drafts lead with a thesis ("computation versus entropy reduction") that the data do not yet
  test.
- They contain statements that are false as written: "no fixed points" (at least 48 exist), "no
  computation at all" in Life-like rules, and "never reads its own output".
- Every spatial number depends on a correlation measure the internal panel found to be
  unconnected and capped. A Physica D referee would find this within an hour, and the paper would
  be rejected rather than revised.
- The core is good, and it is unusual: an exactly analysable, structured many-to-one local map,
  attractors designed by inverse construction, and a clean lattice-level selection result.

## 2. What our readers will care about, and what triggers rejection

**Readers care about:**
- statements about the map that are exact or provable (image size, entropy loss, periodic points,
  a lemma about the lattice);
- reduced descriptions: the Gray designs as three coupled Ising fields, and front motion
  controlled by reading length;
- clean physics: freezing against coarsening, the exponents with error bars, finite-size
  behaviour and the role of quenched hashing;
- placement against Kaneko, Kauffman/Wuensche, Wolfram 1983, and freezing in majority dynamics
  (Spirin–Krapivsky–Redner, Olejarz).

**Triggers specific to this journal:**
- (a) "Phase transition", "critical" or "t^⅓" stated without finite-size analysis, periodic
  boundaries and uncertainty.
- (b) A phenomenological zoo (25 CPUs, many dictionaries, presets) with no unifying analysis.
- (c) Biological vocabulary ("species", "replicators", "invasion") doing argumentative work.
- (d) Results that depend on implementation accidents: swap order, hashing, the broken RNG.
- (e) An interactive page offered in place of reproducible numerical methods.
- (f) Reading a phase diagram into the gradient frame. This is the Mitchell–Hraber–Crutchfield
  critique, and it was published in our pages' neighbourhood.

## 3. The paper I would want

**Working title:** *A decompressor as a local map: attractor census, designed cycles and
deterministic freezing in a coupled map lattice*

**The abstract's angle, in five sentences:**
1. We study a lattice of 128-bit cells whose local map is an LZ77-type decoder against a fixed
   dictionary, coupled by bit exchange and majority smoothing.
2. The decoder is a structured many-to-one map: after one step the collision entropy is 16.5 bits
   and the min-entropy 8.3 bits, far below a random map of the same image size. Its periodic
   points can be enumerated.
3. Inverting the construction, we build dictionaries with prescribed Gray-coded cycles, 3 to 32
   of them, verified exactly by census.
4. On the lattice, Gray designs reduce to three coupled Ising fields. Domains freeze under a
   time-invariant rule and coarsen only when the rule's hashing varies in time. The coupling
   medium, not the basin size, decides which attractor fills the lattice: fixed-point domains are
   fixed points of the lattice map, while cycle domains need phase coherence.
5. Calibrating against elementary rules of exactly known loss shows that whole-cell collision
   entropy tracks information loss exactly while local block entropies are blind to it.

**Claims to lead with (only those the evidence supports or that a week of work will secure):**
1. The decoder map's census: entropy after one step, periodic points (exhaustive fixed points and
   2-cycles), transients, and the comparison with a random-mapping (Flajolet–Odlyzko) null and
   with 30 byte or word shuffles.
2. Inverse construction of attractors (Gray 8-cycles, 3–32 of them), with exact verification and
   the stray-cycle and reading-length rules stated as tested conditions.
3. A lemma with its numerical confirmation. A uniform fixed-point domain is a fixed point of the
   lattice map; a cycle domain survives only if it is phase-coherent. Hence the medium selects:
   fixed points win under strong settling, the large-basin cycle under uniform settling. This is
   the contrast with Schaper–Louis's "arrival of the frequent".
4. Deterministic freezing against coarsening: salting by position equals no salt, and salting by
   turn unfreezes. Use the connected correlation length and give exponents only with error bars.
5. A methods result: collision entropy is exact on rule 90 and block entropy is blind (a short
   section or an appendix).

**Drop or move to the supplement:**
- The computation-versus-entropy thesis (one paragraph of outlook at most).
- The Z80 and processor comparison, and the 25-CPU gallery.
- Look-and-say: supplement, or a separate note.
- The "replicator" framing: one paragraph in the discussion citing Langton 1984, as trivial
  replication.
- The swarm-searched dictionaries except F, and the gradient frame as evidence. It stays as one
  illustrative figure.
- The pair and vote modes, and the page presets.

**Article type and length:** a regular research article. I found no confirmed limit; aim for
about 9,000 words and 25–30 typeset pages, with 8–10 figures and a supplement.

**Key figures:**
1. The system schematic (cell, three stages, coupling).
2. The decoder map: the entropy-decay curve against the random-map null and the shuffles, and the
   basin/cycle census.
3. The construction: the dictionary layout giving a Gray 8-cycle, and the census of designed
   dictionaries.
4. Lattice snapshots, uniform parameters, frozen against annealed.
5. The connected correlation length against time, quenched against annealed, with fits and
   intervals, at three sizes.
6. The selection diagram: winner against settling strength and mixing probability, with the
   lemma's prediction overlaid.
7. Front speed against the reading-length difference.
8. The calibration figure (rule 90 against block entropy).
9. The gradient frame, as an illustration only.

## 4. Required work before submission

**Must:**
1. **Pipeline hygiene** (panel item 2): provenance in every output, the rotating swap order as
   the harness default, the page's snapshot corruption fixed, the broken generator retired.
   *1 day.*
2. **Recompute every spatial observable** (panel items 3 and 5): connected, bias-subtracted phase
   correlations to L/4; censoring-aware statistics with bootstrap intervals; unbounded period
   detection; the salt controls (E0, E1). *2 days, ~30 CPU-h.*
3. **The map-level spine** (panel item 4): exhaustive fixed points and 2-cycles of F in C; the
   entropy decay against the hash null; 30 byte and 30 word shuffles of F and Brotli 13.
   *1–2 days plus overnight.*
4. **An analysis section.** Prove the lattice fixed-point and phase-coherence lemma. Derive the
   Ising reduction from the 3-cube metric. Give at least a pair-approximation or front-velocity
   argument for the reading-length rule. Without this, Physica D referees will call the paper
   numerical phenomenology. *3–5 days, no CPU.*
5. **The selection result on several seeds**, under uniform parameters as well as the frame, with
   a transitivity check of the competition matrix (panel items 6 and 7). *2 days, ~60 CPU-h.*
6. **The rewrite**, on the panel's claims table: drop the false statements; add Kaneko,
   Bunimovich–Sinai, Wuensche–Lesser, Kauffman, Spirin–Krapivsky–Redner, Lempel–Ziv 1976 and
   Levin 1974; declare the co-authorship of the 2024 study. *3 days.*

**Nice:**
- Periodic boundaries with finite-size scaling across the median-axis transition (E3), only if
  the word "transition" stays. *70–190 CPU-h.*
- Coarsening over more decades (E2).
- Droplet and critical-nucleus experiments, to settle the panel's disagreement about how the
  fixed point wins.

Total for the musts: about 3 weeks and about 100 CPU-hours.

## 5. Reviewers I would invite

- **A coupled-map-lattice specialist** (e.g. K. Kaneko or L. Bunimovich, or someone from their
  schools). They will ask whether this is anything more than a CML with an exotic local map, and
  what the decoder gives that a random many-to-one map with matched statistics does not. Answer
  them with the null models and the shuffles.
- **A discrete-dynamics or CA mathematician** (J. Kari, or A. Wuensche for basin-of-attraction
  work). They will attack the precision of the definitions: global map, period 4, 2 × 2 block
  uniformity, the exhaustiveness of the censuses, and the claimed image bounds.
- **A statistical physicist of ordering kinetics** (S. Redner, P. Krapivsky or J. Olejarz). They
  will attack the correlation lengths, the exponents, freezing against pinning and the lack of
  finite-size control.
- **An algorithmic-information / simplicity-bias reviewer** (K. Dingle or B. Hamzi). They will
  test whether the LZ/Kolmogorov motivation is stated correctly (the coding theorem, not LZ
  parsing; the zenil2015 citation), and whether "the medium beats the basin" really contradicts
  arrival-of-the-frequent results.
- **Excluded for conflict:** co-authors of Agüera y Arcas et al. 2024.

## 6. Presentation and formatting

- **Format:** Elsevier `elsarticle` LaTeX. Highlights and a graphical abstract are standard
  Elsevier items; whether Physica D requires them is unconfirmed, so prepare both.
- **Data and code:** expect a data-availability statement (Elsevier research-data policy). Deposit
  the code, the wasm build, the dictionaries and the analysis scripts in an archived release with a
  DOI (Zenodo), not only GitHub. Every figure should be regenerable by one script, with the
  provenance block. Exclude raw data the paper does not use.
- **The browser artifact:** cite it as a supplementary interactive demonstration with a pinned
  version URL. Referees must be able to reproduce every number without it. Do not let the page be
  the only route to any result, especially while the single-thread path is known to have been
  defective.
- **Supplementary material:** the dictionary listings, the full census tables, the gradient-frame
  movies, and look-and-say and the processors if kept.
- **Open access:** the journal is hybrid. Choose gold OA (APC unconfirmed; check it) or the
  subscription route with the arXiv preprint. Papers are free to read after 48 months.
- **Limits:** no word or figure limits were confirmed. Keep to roughly 10 figures; Physica D
  readers tolerate length but not padding.

## 7. Score and timeline

**Publishability after the required work: 6/10.**
- Novel local map, exact census, constructive design and a clean selection result: in scope and
  of interest.
- The risk is a referee judging it "a CML zoo without theory". Item 4 decides between a 5 and a 7.

**Timeline:**
- about 3–4 weeks of work;
- a first decision 2–3 months after submission (third-party figures suggest 3–8 weeks to first
  reports, plus editor time);
- one major revision likely;
- acceptance plausible 6–9 months from submission.
