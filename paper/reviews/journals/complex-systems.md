# Editor's report: *Complex Systems* (Complex Systems Publications, Champaign IL)

2026-10-21. Handling editor's view of the Keimli project, from the brief, the drafts (INTRODUCTION, METHODS, MOTIVATION,
RESULTS_REPLICATORS, the assembled draft), `results/*.md` (esp. decoder-map, replicators, design-gray3,
entropy-manipulators), the panel's SYNTHESIS.md and RELATED_WORK.md.

**Journal facts checked on the web today** ([about](https://www.complex-systems.com/about/),
[contribute](https://www.complex-systems.com/contribute/), [current issue](https://www.complex-systems.com/current/)):
scope "science, mathematics and engineering of systems with simple components but complex overall behavior", explicitly
listing cellular automata and discrete dynamical systems, algorithmic complexity and information theory, rewriting
systems, symbolic dynamics; founding editor Stephen Wolfram, managing editor Hector Zenil; quarterly (current issue
vol. 35 no. 2, 2026: number-conserving CAs, maximal-length CAs, ECA reservoir computing, link prediction); Platinum
open access, CC BY, no fees, 25 reprints; electronic submission by web form or e-mail; LaTeX (`ComplexSystems.sty`)
and Wolfram Mathematica templates plus a sample paper; authors must suggest referees with contact details;
"results and presentation accessible to a wide readership". **Not confirmed:** article types, word/page or figure
limits, review model (single/double blind), data/code policy, supplementary-material rules, typical turnaround. The site
states none of these. Published papers are typically 15–30 journal pages; I treat that as the working norm, not a rule.

## 1. Fit and desk decision

Fit is very good, arguably better than any other journal on the panel's list. A lattice whose local rule is a fixed,
linear-time rewriting system (an LZ77/Brotli-style decoder), studied by exact enumeration of the local map's attractors,
by entropy loss under iteration, and by the domain dynamics it induces, is squarely "CA and discrete dynamical systems"
plus "algorithmic complexity" and "rewriting systems". Wolfram 1983 is the paper's natural ancestor, and the
calibration on rules 60/90/150 on the 128-bit ring is the kind of exact result this readership enjoys. **Desk decision
on the current drafts: invite resubmission (not sent out).** The drafts still assert things the project's own data
refute: RESULTS_REPLICATORS says "there is no fixed point" (≥ 48 verified fixed points exist, and one wins under the
frame), INTRODUCTION says the decoder "never reads its own output" (18.2 % of output bytes are self-copies) and that
Life-like rules do "no computation at all" (Life and rule 110 are universal; a referee here will stop reading at that
sentence). Lattice numbers rest on scripts with the fixed swap order, censored medians, an unconnected correlation
function and no provenance. And the abstract sells a thesis ("separate entropy reduction from computation") that the
evidence does not yet test. None of this is fatal; all of it would be fatal with referees.

## 2. What readers and reviewers here care about; rejection triggers

They care about: (a) a precisely defined rule (state space, update order, period-4 time dependence, the 2 × 2 block
uniformity), stated so it can be reimplemented from the paper alone; (b) exact or enumerative results over
simulation lore: the attractor census, the Gray-code inverse construction, the rule-90 nilpotence calibration;
(c) pictures: space-time and lattice images that show the phenomenon at a glance; (d) correct placement in the CA
literature (Wolfram classes, NKS, Wuensche–Lesser basin fields, Kaneko CMLs, Toffoli–Margolus block CAs,
Greenberg–Hastings/cyclic CAs, Fisch–Gravner–Griffeath); (e) algorithmic-information claims done correctly.

Triggers specific to this journal:
- **Misstating Wolfram.** "Block entropy is blind" must be framed as what it is: local spatial block entropies do not
  see ring-wide linear constraints of additive rules (Martin–Odlyzko–Wolfram 1984 explains why). Phrased as "Wolfram's
  measure fails", it will be read as a cheap shot and refereed accordingly.
- **Misusing algorithmic information theory.** The managing editor and much of the board work on the coding theorem
  method and BDM. Citing zenil2015 for "LZ is a good-enough proxy for K" (it argues the opposite) is the single most
  avoidable rejection risk in the manuscript. "LZ complexity as a tractable stand-in for Kolmogorov complexity" needs
  Lempel–Ziv 1976, Levin 1974 and the coding-theorem literature, with the limits stated.
- **Universal-sounding claims without proof** ("O(n) against O(c^n)", "image at most 2^93.5").
- **Grand ALife framing** with no ALife result: our referees are CA people and will treat the dichotomy as rhetoric.

## 3. The paper I would want

**Working title:** *Decompression as a cellular-automaton rule: attractor census, designed cycles and domain
competition on a lattice of LZ77 decoders.*

**Abstract angle (5 sentences).** (1) We study a lattice CA whose local rule rewrites each 128-bit cell by decoding it
as an LZ77-type stream against a fixed dictionary, coupled to neighbours by bit exchange and majority settling. (2) The
rewriting map is linear-time and many-to-one; its output carries at most 93.5 bits at one step, and measured collision
and min-entropies of 16.5 and 8.3 bits, calibrated against elementary rules of exactly known loss. (3) Its attractors
(fixed points and short cycles) can be enumerated, depend on the order of the dictionary's bytes, and can be prescribed:
we construct dictionaries with 3 to 32 Gray-coded 8-cycles and no other attractors. (4) On the lattice these become
competing domain types; which wins is set by the coupling medium, not by basin size: fixed-point domains under strong
settling, the large-basin cycle under uniform settling, explained by phase coherence of cycle domains. (5) The system
runs interactively in a browser, with parameter gradients across one image.

**Lead claims (supported or nearly so):**
1. Exact characterisation of the local map: the output-entropy bound (as an upper bound at turn 1 only), H₂/H∞ after
   one step, entropy decay under iteration against a size-matched random-map null, and the whole-cell vs. block
   entropy calibration on rules 60/90/150.
2. The attractor census (≥ 48 fixed points by exact search, the dominant short cycles, shuffle dependence; stated
   for F and Brotli 13 with 30 shuffles each).
3. Inverse design: Gray-coded cycles built by exhaustive enumeration and packing, verified by census, with the
   stray-attractor exceptions reported honestly.
4. Medium, not basin, selects the winning attractor type; the fixed-point/cycle phase-coherence argument as the
   mechanism, with the droplet/noise competition matrix.
5. Deterministic freezing (salt-by-position freezes like no salt, salt-by-turn unfreezes) and the Gray designs as three
   coupled Ising fields — only if E0/E1 are redone; otherwise move to an outlook paragraph.

**Drop or move to supplement:** the computation-vs-entropy dichotomy (one paragraph of outlook, flagged as the next
paper); the 25-CPU gallery and Z80 row (supplement at most; one sentence); "replicators/species/invasion" vocabulary
(say periodic points, attractor types, domain competition; one paragraph linking to Langton 1984 trivial replication
and to Agüera y Arcas et al. 2024, with the co-authorship declared); the t^⅓ exponent and all correlation lengths until
recomputed; the q = 8 clock model; "hash pinning by quenched disorder"; the gradient frame as evidence (it is a figure
and the tool, not an evaluation); look-and-say to a short supplementary note unless it earns a figure.

**Article type and length:** regular research article; target 20–25 journal pages (~8,000–9,000 words), 8–10 figures,
3–4 tables, ~60–80 references (not 248). Supplement: full census tables, dictionaries, run manifests.

**Key figures:** (1) the rule schematically: one cell decoded, the three stages, update order; (2) entropy vs. iteration
for decoder, rules 60/90/150 and random-map null (H₂, distinct cells, block-8); (3) basin/attractor diagram of F
(Wuensche-style) and of a designed 3-cycle dictionary; (4) Gray-cycle construction and its 3-cube metric; (5) lattice
snapshots: fixed-point vs. cycle domains under two media; (6) competition matrix / droplet growth vs. noise; (7) the
gradient frame as a phase-diagram picture with the caveat; (8) freezing with/without salt by turn.

## 4. Required work, ranked

**Must**
1. Rewrite abstract/introduction/results on the panel's claims table; remove every refuted statement; fix the
   zenil2015 and LZ77-for-LZ76 citations; add NKS (wolfram2002, chs. 3, 10 on substitution systems and data compression),
   Martin–Odlyzko–Wolfram, Wuensche–Lesser, Kaneko, Toffoli–Margolus, Langton 1984, Levin 1974. ~3 days.
2. Pipeline hygiene: provenance block in every output, rotating order as harness default, fixed single-thread snapshot
   bug with a 1-vs-4-thread parity test, retire the broken RNG. ~1 day.
3. Exact map-level results in C: enumerate F's fixed points and 2-cycles exhaustively within a stated structural class
   (or state precisely what "exact search" covers); entropy decay vs. random-map null; 30 byte + 30 word shuffles. ~2 days
   + overnight.
4. Redo the lattice claim that leads (claim 4) on the fixed pipeline: several seeds, uniform parameters and frame,
   censoring-aware statistics with bootstrap CIs, unbounded period detection, droplet/noise competition matrix with a
   transitivity check. ~2 days + 50 CPU-h.
5. A formal definition section: global map, time period 4, 2 × 2 block uniformity, exactly which bits are hashed. ~1 day.

**Nice**
6. Connected correlations up to L/4 and E1 salt controls, to keep claim 5 (~20 CPU-h).
7. Finite-size scaling of the median-axis transition (70+ CPU-h) — better saved for a PRE companion.
8. A Mathematica or Python reference implementation of the local rule (~200 lines) in the supplement; this journal's
   readers will run it.

Total must-work: about two weeks, under 100 CPU-hours.

## 5. Reviewers I would invite

- **Basin-of-attraction / discrete-dynamics specialist (e.g. Andrew Wuensche):** will attack the census methodology
  (sampling vs. exhaustive), the claim of "no other attractors" for designs, and the absence of basin-field pictures.
- **Mathematical CA theorist (e.g. Janko Gravner, Klaus Sutner, or Jarkko Kari's group):** precise definition of the
  global map, whether it is a CA at all under hashing and gradients, period-4 time dependence, the freezing argument.
- **Algorithmic information person (coding theorem/BDM school, e.g. Narsis Kiani or Fernando Soler-Toscano; the
  managing editor recuses from refereeing but will read):** LZ-vs-K framing, the entropy bounds, whether "decoder =
  coding theorem side" is stated correctly.
- **Statistical physicist of coarsening/CMLs:** correlation measures, freezing vs. coarsening, Ising-field reading,
  censored statistics.
- **Optionally an ALife reviewer (Avida/BFF-literate, not from the Agüera y Arcas / Google Zurich circle):** the
  replicator deflation and the overreach toward computational life.
Exclude as conflicted: co-authors of arXiv 2406.19108 and of knierim2026 (Versari, Obryk, Agüera y Arcas, Saurous,
Knierim), and Brotli/JPEG XL collaborators.

## 6. Presentation and formatting

- Prepare in the journal's LaTeX class (`ComplexSystems.sty`) or the Mathematica template; follow the sample paper's
  style. Suggest 4–5 referees with addresses (required at submission).
- Data/code: the journal states no policy (unconfirmed), but I will require a code and data availability statement
  with an archived, versioned release (Zenodo DOI) of the wasm source, experiment scripts, dictionaries and run
  manifests; a GitHub URL alone is not archival. Exclude raw bulk data; give scripts that regenerate it and checksums.
- The browser artifact: cite it as interactive companion, pinned to the archived commit; the paper must be complete
  without it. Every figure must be reproducible from a script, not a page screenshot.
- Supplement: no stated mechanism found; plan a single PDF appendix plus the archived repository.
- Open access is automatic (Platinum, CC BY, no fee); check figure licensing for anything not your own.
- No confirmed word/figure limits; aim for the norms above. Write for a wide readership: define LZ77 and Brotli
  terms in a box; no project jargon (Swarm F, ca-gray3c) without a table mapping names to definitions.

## 7. Score and timeline

**Publishability after the required work: 7/10.** The census, the inverse construction and the medium-picks-winner
result are novel and in scope; risk lies in the AIT framing and the lattice statistics. Timeline: ~2–3 weeks to
submission; Complex Systems review is not fast (turnaround unconfirmed; plan for 3–6 months to first decision, one
round of minor/major revision, publication in the following quarterly issue — realistically mid-to-late 2027).
