# Physical Review E — handling editor's report on Keimli

**Journal facts checked on the web (journals.aps.org/pre/about, /pre/authors):** scope is statistical physics, nonlinear
dynamics and chaos, networks and complex systems, biological physics, soft matter, fluids, plasma, computational
physics; criteria: an "authoritative and substantive addition" of interest to the journal's general readers. Regular
Articles have no length limit; Letters are limited to 4,500 words, get priority handling and need a cover-letter
justification of the format. Every article needs a Data Availability Statement. Supplemental Material must not be
essential: the paper must be convincing without it. Hybrid OA under CC BY 4.0; the 2026 APC of US$2,910 comes from a search
summary of the APS price list, which **I did not open directly**. **Not confirmed:** whether APS has a separate code
policy (none on the author page), any figure-count limit (none stated), and the full text of the Data Availability Policy.

## 1. Fit and desk decision

The fit is real but narrow. PRE publishes cellular automata, coupled map lattices, coarsening, domain competition and
information-theoretic measures of dynamics. A lattice whose local rule is a many-to-one map with a few hundred
measurable, designable attractors is squarely in scope (Kaneko-type CML, Kauffman/Wuensche basin censuses, Ising-like
ordering). Artificial life, Core War, "what computation adds" and the 25-processor gallery are not, and our referees
will read them as advocacy. **Decision on the current drafts: desk reject, with an invitation to resubmit a different
paper.** The drafts are framed as an ALife thesis. The introduction says rule systems compute "nothing at all", which
our CA referees will refute in one line (Life, rule 110). Other draft claims ("no fixed points", hash pinning, the
q = 8 clock model, t^⅓ coarsening, the correlation lengths) are contradicted by the author's own panel. The numbers
also come from a pipeline the panel found defective: censored medians, a biased and capped correlation function, the
fixed swap order, no provenance. Nothing in the physics section can go to a referee yet. The map-level results can.

## 2. What our readers and referees will care about, and what triggers rejection here

They will care about:
- **A well-defined model.** The global map must be written down exactly, with its symmetries (period 4 in time;
  translation-invariant only on 2 × 2 blocks under uniform parameters), and with the stochastic and quenched elements
  stated. A browser page is not a definition.
- **Controlled observables.** Connected correlation functions with each bit plane's bias subtracted; collision
  entropy and min-entropy calibrated on rules of known loss (the rule 90 calibration is exactly what we like).
- **Finite-size and time scaling** for any statement about ordering, freezing or a transition, with error bars and
  several system sizes under periodic boundaries.
- **Mapping to known universality.** If the Gray designs are three coupled Ising fields, show it. Measure the
  magnetisations and their couplings, and compare the ordering with Glauber/majority-vote coarsening.
  Kinetics alone, without that comparison, will not do.

What gets a paper rejected at PRE specifically:
- (i) "Interesting simulations, no physics": phenomenology with no scaling and no mechanism.
- (ii) Any exponent or "sharp transition" from one size and a few decades of time. The present t^⅓ drifting from
  0.37 to 0.24 is exactly this.
- (iii) Overclaiming novelty against the CA, CML and random-map literature.
- (iv) A gradient-frame "phase diagram". A spatially varying parameter is not a phase diagram, and the panel showed
  that the frame and the uniform runs pick different winners.

## 3. The paper I would want

**Working title:** *Designable attractors and deterministic freezing in a lattice of decompressing cells*

**Abstract, five sentences:**
1. We study a two-dimensional lattice whose local rule decodes each 128-bit cell as an LZ77-type stream against a
   fixed dictionary, coupled to neighbours by bit exchange and per-plane majority.
2. The local map is strongly many-to-one: calibrated on elementary rules of exactly known loss, collision entropy shows
   ~110 of 128 bits lost in one step and convergence to a handful of cycles within ~35 steps.
3. The dictionary determines the attractor set, and we construct dictionaries with prescribed Gray-coded cycles
   (3–32), verified by exact census.
4. On the lattice the designed cycles act as three coupled Ising fields. A time-invariant deterministic rule freezes,
   and turn-dependent salting restores coarsening.
5. Which attractor takes the lattice is set by the coupling, not by basin size: fixed-point domains are fixed points of
   the global map and survive noise that melts cycle domains, which must share a phase.

**Claims to lead with (supported, or nearly so):**
1. The entropy contraction of the local map, measured with calibrated whole-cell entropies (H₂ 16.5, H_min 8.3 bits
   after one step for F). The 93.5-bit figure is an upper bound at turn 1 only. Block entropy is shown blind.
2. The attractor census, and the inverse construction of prescribed cycles, with exact enumeration of fixed points and
   2-cycles and the shuffle nulls (byte order sets the cycle).
3. Deterministic freezing as the default and coarsening when the hash depends on the turn. The salt controls are
   already done: position salt freezes like no salt. Use that wording, not "pinning by disorder".
4. Medium-selected domain competition: the fixed-point versus cycle-domain mechanism, with a competition matrix and a
   transitivity test.
5. Optionally, the swap-order anisotropy and its cure, as a short methods point (it survives because the bias cancels).

**Drop or move to SM:**
- Drop: the computation-versus-entropy dichotomy, Core War/Tierra/BFF framing beyond one paragraph, the Z80 result
  (a dose–response belongs in the second paper), look-and-say, the 25-CPU gallery and the "replicator" vocabulary
  (use "periodic points / attractor types").
- SM: the 1,192-run ablation tables, dictionary search procedures, codebook and vote-partner variants, the decoder
  specification and the bit-exact JS reference.

**Article type and length:** Regular Article, ~7,000–9,000 words, 8–10 figures. Not a Letter. Nothing here is the
"particular importance" result a Letter cover justification needs, and the model needs space to be defined.

**Key figures:**
1. Model schematic: the three stages and the 2 × 2 block structure.
2. Entropy decay H₂(t) and H_min(t) for the decoder against rules 60 and 90 and the hash:93 random-map null.
3. Attractor census: basin sizes and transients for F, its shuffles and the texts.
4. A designed dictionary's cycle graph on the 3-cube.
5. Lattice snapshots: frozen versus salted-by-turn.
6. Connected C(r,t) and domain length L(t) on log axes for three or more sizes, with a scaling collapse.
7. The three Ising magnetisations and their cross-correlations.
8. Competition matrix and front velocity against settling strength.

## 4. Required work before submission

**Must (ranked):**
1. **Pipeline hygiene** (panel item 2): provenance in every output, the rotating order as the default, one engine
   with a parity self-test, the broken RNG retired. *1 day.*
2. **Rewrite on the claims table.** Precise definition of the global map. Cite Wolfram 1983, Martin–Odlyzko–Wolfram,
   Kaneko, Kauffman, Wuensche–Lesser, Harris, Bray 1994, Toffoli–Margolus, Fisch–Gravner–Griffeath and
   Greenberg–Hastings. Declare the 2024 co-authorship. *2–3 days.*
3. **Observables redone** (panel item 3): connected and phase correlations to L/4, censoring-aware statistics with
   bootstrap intervals, an unbounded period detector. Recompute every ξ (E0). *1 day + ~20 CPU-h.*
4. **Scaling (E2/E3)**: periodic boundaries; L = 64–1024; at least 3 decades in t for the salted-by-turn coarsening;
   the exponent fitted with drift shown, compared with z = 2 (non-conserved) and with majority-vote/Glauber controls
   run in the same code. If the median-axis transition is claimed, add finite-size scaling of the order parameter and
   its susceptibility, or call it a crossover. *3–5 days + 70–190 CPU-h.* Without this item, PRE referees will
   reject.
5. **Exact map-level results** (panel item 4): exhaustive fixed points and 2-cycles in C; shuffle ensembles of 30.
   *1–2 days + overnight.*
6. **The Ising mapping made quantitative**: the three magnetisations, the effective couplings, and whether the
   ordering transition sits in the 2D Ising class. *2–3 days.*
7. **Competition matrix** with droplets, critical nucleus and wall speed against noise, run with and without turn salt
   (panel item 6). This settles the panel's disagreement over nucleation versus robustness. *2 days + 50 CPU-h.*

**Nice:**
- An analytic mean-field or pair-approximation for front velocity between a fixed-point and a cycle domain.
- Re-evaluating the named dictionaries on several seeds (needed only for any claim that rests on F specifically).

## 5. Referees I would invite

- **CA / discrete dynamics** (e.g. A. Wuensche or someone of the Gravner/Griffeath school). Will attack: novelty
  against basin-of-attraction fields and random-map theory, the precise statement of the global map, the "no
  computation" sentences, and the exactness of the census.
- **Coarsening / nonequilibrium statistical physics** (e.g. someone from the Bray/Cugliandolo/Krapivsky line or a
  majority-vote model expert such as M. J. de Oliveira). Will attack: exponents from short runs, uncorrected
  correlations, freezing versus pinning, the missing size scaling, and the absence of a known-model control in the
  same code.
- **Information theory of dynamical systems** (Crutchfield/Shalizi school, or someone working on Lempel–Ziv entropy
  estimation). Will attack: the entropy estimators (resolution of H₂ at 2 log₂ N), the claim that collision entropy
  measures "loss", and the coarse-grained versus fine-grained entropy of a deterministic system.

## 6. Presentation and formatting

- **Data Availability Statement is mandatory.** Deposit the generating scripts, the exact wasm build and dictionaries,
  and the summary JSON in a DOI-bearing archive (Zenodo) tagged to a commit. Every number in the paper should trace
  to a provenance block. Raw multi-GB runs can be regenerated; say so.
- **Code:** APS lists no code policy on the author page, but referees will expect a command-line harness that
  reproduces every figure without a browser. The browser page is welcome as an SM link and an interactive
  illustration. It cannot be the method, and the paper must define the model completely in its own text (equations
  and pseudocode in an appendix, the decoder grammar in SM).
- **SM** must not be essential. The definition of the decoder belongs in an appendix, not SM.
- Use REVTeX 4.2 and BibTeX. The current markdown-to-PDF draft is not submittable. Figures should be vector, with
  colour free online. Print colour is charged, so print in greyscale.
- **Open access** is optional (hybrid, CC BY; APC as stated above, unverified). arXiv posting is fine, and an arXiv
  version is expected.
- State the 2024 co-authorship and affiliation in the competing-interests field.

## 7. Score and timeline

**6/10** for publishability at PRE after the "must" work. The map census, the designed attractors and the
freezing/salting result are a solid PRE Regular Article if the scaling is done carefully. The score is capped because
the physics is not yet novel in universality terms. Coupled Ising fields that coarsen are expected, so the paper lives
on the model's novelty and the design result. It rises to 7 if the Ising mapping is quantitative and the
competition mechanism is derived, not just observed.

**Timeline:**
- 3–5 weeks of work plus ~150–300 CPU-h before submission.
- Then about a week to the desk decision, about 2 months to the first reports, and one or two rounds.
- Acceptance realistically 5–7 months after submission (the journal's median is 126 days).

Sources: [PRE about](https://journals.aps.org/pre/about), [PRE publishing guidelines](https://journals.aps.org/pre/authors),
[APS APCs](https://journals.aps.org/authors/apcs) (not opened directly; figure via search summary).
