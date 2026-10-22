# Chaos (AIP): handling editor's report on Keimli

2026-10-21. I read the BRIEF, the internal panel's SYNTHESIS.md, INTRODUCTION.md, RESULTS_REPLICATORS.md and these results notes: decoder-map, entropy-manipulators, design-gray3, replicators, ablation-main and swap-order. I wrote this from the journal's point of view.

**Journal facts I checked (21 Oct 2026).** These come from the Chaos *Editorial Policies* and *About* pages on pubs.aip.org:
- **Scope.** Nonlinear dynamics and complex systems, written so researchers in many fields can read it. Analytical, computational and experimental work are all in scope.
- **Article types.** Regular Articles have **no length limit**. Fast Track is capped at **5,750 words**, counting figures, tables and equations; the abstract at **250 words**. There are also Perspectives, Reviews, Focus Issues and "public-access software" announcements.
- **Lead Paragraph.** A bold one is **mandatory**, written for non-specialists, and the editors edit it. The page gives **no** length limit for it.
- **Review criteria.** Correctness, originality, novelty, interest and accessibility. "Highly technical work in certain subareas may be rejected in favor of a specialized journal."
- **Open access.** Chaos is hybrid. Open access is through Author Select at about **US$3,500–3,800**. I could not confirm the current Chaos-specific price.

**What I could not confirm on the web:**
- the exact wording of AIP's data-availability rule (I believe AIP journals require a Data Availability Statement);
- the supplementary-material size and format limits;
- the figure limits for Regular Articles.

## 1. Fit and desk decision

The project fits Chaos, but only as one specific paper. That paper is a coupled lattice of identical nonlinear local maps, each a decoder taking 2¹²⁸ states to 2¹²⁸ states. It should report:
- **the map:** a census of its attractors, and its entropy decay measured against the random-mapping null;
- **the inverse problem:** how to construct a map whose attractors are prescribed;
- **the lattice:** the spatiotemporal phenomena that follow, namely deterministic freezing, coarsening when the hashing is annealed, and domain competition decided by the medium rather than by the basin.

That is a Kaneko coupled-map-lattice and Wuensche basin-of-attraction paper with a new local map. Chaos readers recognise that genre at once.

The drafts describe a different paper: an ALife thesis that a decoder separates "entropy reduction" from "computation". That thesis is not demonstrated (the panel agrees). Several claims in the drafts are false:
- "no fixed points" (an exact search found at least 48);
- "never reads its own output" (18.2 % of output bytes are copies from the output);
- "hash pinning by quenched disorder" (refuted by the salt controls);
- "the frame is the sweep";
- the takeover times, which come from censored medians.

The lattice statistics we would care about most rest on a correlation measure that does not subtract each bit plane's bias. Corrected, ξ falls from 39.8 to at most 9.5 cells and the t^⅓ exponent drifts. Two of the panel's defects also touch the numbers: the scripts ran the fixed swap order, and no output has provenance.

**Desk decision on the current drafts: desk reject, with an explicit invitation to resubmit the map-and-lattice paper.** I would not send this out. The referees would spend their reports on errors the author has already found himself, and the conceptual framing would draw an "out of scope, try an ALife venue" response. The underlying material, re-scoped, is a credible Chaos Regular Article.

## 2. What readers and reviewers will care about, and what triggers rejection here

Chaos readers will look for:
- **A well-defined dynamical system.** State the global map exactly: it is deterministic, has period 4 in time, is spatially non-uniform under the gradients, and is a uniform CA only on 2 × 2 blocks under uniform parameters. Use parameters a reader can reproduce.
- **Quantities that mean something in nonlinear science.** Attractor statistics, transient lengths and contraction (H₂, min-entropy) against a null. Connected correlation functions, growth exponents with error bars, and a phase diagram in (swap p, median p) with the order of any transition.
- **Connection to the established literature.** Wolfram 1983–84 on entropy and attractors; Martin–Odlyzko–Wolfram on additive rules; Kaneko on CMLs and frozen random patterns; Kauffman, Wuensche and Lesser on basin fields; Bray on coarsening; Vichniac on voting rules; Toffoli and Margolus on block CAs; Derrida and Flyvbjerg, and Harris, on random-map statistics.

**What would get it rejected at Chaos specifically:**
1. **Unsupported physics language.** "Phase transition", "Ising", "t^⅓ coarsening" or "pinning" without finite-size scaling, connected correlations and seed statistics.
2. **Framing.** If the paper reads as an ALife or compression manifesto, it goes to "a specialised journal".
3. **No mechanism.** Phenomenology from one interactive gradient image, with no explanation of why the medium picks the winner.
4. **Non-reproducibility.** Results that depend on the swap-order scheme, a broken random generator, or a single seed.
5. **Inaccessibility.** Brotli internals in the main text where a dynamical description would do.

## 3. The paper I would want

**Working title:** *A decompressor as a local map: attractor census, designed attractors and domain competition in a coupled lattice of decoders*

**Abstract angle (5 sentences):**
1. We study a coupled lattice whose local map is an LZ77-type decoder with a static dictionary, acting on 128-bit cells, coupled by stochastic bit exchange and majority smoothing.
2. The local map contracts sharply. One step takes uniform cells to a collision entropy of about 17 bits, against roughly 127 for a random map, and calibrated against additive rules of known loss, whole-cell entropies track information loss exactly while block entropies are blind.
3. Its attractors can be counted exactly and also prescribed: an inverse construction yields dictionaries with 3–32 Gray-coded 8-cycles whose consecutive states differ by two bits.
4. On the lattice, the coupling alone freezes under time-invariant deterministic updating and coarsens when the hashing is annealed. The decoder adds cycling and fast repair.
5. Which attractor takes over is set by the coupling, not the basin size: fixed-point domains, being fixed points of the global map, survive smoothing that melts unsynchronised cycle domains.

**Claims to lead with** (supported now, or after the "must" work):
1. **Contraction and calibration.** Measured on the corrected pipeline: H₂ at turn 1 of 16.5 bits and min-entropy of 8.3 bits for F; the 93.5-bit value only as an upper bound; the hash:93 null. Calibration on rules 60 and 90, and Wolfram block entropy shown to be blind to the loss.
2. **The attractor census:** at least 48 fixed points, cycles, basins and transients, together with the shuffle controls. The census includes the first-order versus second-order result: the dictionary's order shows only in about 0.25 bits per output byte.
3. **Inverse design of attractors** by exhaustive enumeration and packing, with the stray fixed point reported honestly.
4. **Deterministic freezing against annealed coarsening,** with the exponents recomputed (E0, E1).
5. **"The medium picks the winner."** Back it with the droplet and competition-matrix experiments and the mechanism: a uniform fixed-point domain is a fixed point of the lattice map, and cycle domains need phase coherence.

**Drop or move to supplementary material:**
- **Drop:** the computation-versus-entropy dichotomy (keep one sentence in the outlook); "local entropy pump"; "nothing replicates or is selected"; the "replicator" vocabulary (use "self-maintaining attractor types" and "domain competition"); "a refuted hypothesis is new".
- **Out of the main text:**
  - the 25-CPU gallery (at most one Z80 row in the entropy table, explicitly preliminary);
  - look-and-say (its own short note, or the supplement);
  - the searched-dictionary history.
- **Supplementary material:** the swap-order anisotropy study; the Brotli bitstream details; the full dictionary tables.
- **The gradient frame** becomes a visualisation figure, not evidence.

**Article type and length:** a Regular Article of about 7,000–9,000 words with 8–10 figures. Fast Track is not appropriate, because the work is not yet at the "high-impact, novel" bar and needs room for methods.

**Key figures:**
1. A schematic of the three stages and of the decoder as a map.
2. H₂ and distinct cells against turn for rule 90, rule 60, the decoder, the hash:93 null and the Z80.
3. The census: basin sizes, transient distributions, shuffled versus raw.
4. The Gray construction: the state graph and the 3-cube metric.
5. The phase diagram in (swap p, median p) from uniform runs, with the gradient frame as an inset.
6. Connected C(r) and ξ(t) for quenched versus annealed hashing, with fitted exponents and confidence intervals.
7. Droplet growth and shrinkage, wall velocity, and the competition matrix.
8. Takeover curves with a censoring-aware analysis (Kaplan–Meier), at several system sizes.

## 4. Required work before submission

**Must**, in order:
1. **Rewrite the paper on the panel's claims table** with the re-scope above. Add the CML, basin and coarsening literature and fix the misused citations (zenil2015; LZ76 versus LZ77). Disclose the co-authorship of the 2024 study. *2–3 days.*
2. **Pipeline hygiene.** A provenance block in every output; the rotating order as the harness default; the page's vote-snapshot corruption fixed and a parity test added; the broken random generator retired; every reported run redone. *1 day + ~15 CPU-h.*
3. **Correct the observables.** Connected, bias-subtracted correlations out to L/4; censoring-aware statistics with bootstrap confidence intervals; an unbounded period detector. *1 day + ~10 CPU-h.*
4. **Map-level spine.** An exact C enumeration of fixed points and 2-cycles; H₂ decay under iteration against the hash:93 null; 30 byte shuffles and 30 word shuffles of F and Brotli 13. *2 days + overnight.*
5. **Freezing and coarsening on the corrected measure (E0, E1).** Salt controls and replicas; at least 10 seeds; 3–4 system sizes. *~20–30 CPU-h.*
6. **Competition experiments.** Droplets, critical nucleus, wall speed, noise robustness, and an N × N competition matrix with a transitivity test. *2 days + ~60 CPU-h.*

**Nice:**
- E3, the order–disorder transition with periodic boundaries and finite-size scaling (~100–190 CPU-h). This would change "interesting model" into "Chaos physics paper" and I strongly encourage it.
- Lyapunov or damage-spreading (Hamming distance) curves across the phase diagram. These are cheap, very Chaos, and connect directly to Derrida–Pomeau and Kaneko.
- An analytic mean-field estimate for the fixed-point versus cycle competition.

## 5. Reviewers I would invite

1. **Coupled map lattices / spatiotemporal chaos** (Kaneko's school, or a CML dynamicist). Will attack: novelty relative to CMLs with discrete local maps, and the absence of damage spreading or Lyapunov analysis.
2. **CA theory and basins of attraction** (Wuensche-style, or symbolic dynamics such as Kari or Formenti). Will attack: whether the global map is properly defined; the census methodology (sampling versus exhaustive); and whether "designed attractors" is more than a lookup table.
3. **Statistical physics of coarsening and domain competition** (Bray or Krapivsky–Redner tradition; voter and majority models). Will attack: the exponents, the corrected ξ, finite size, the pinning-versus-freezing story, and the Ising mapping of the Gray designs.
4. **Algorithmic information / simplicity bias** (Louis or Dingle group, or Zenil). Will attack: the LZ-as-Kolmogorov-proxy motivation, the entropy estimators' resolution (H₂ saturates at 33 bits), and the random-map nulls.
5. *(Optional)* **Artificial life** (Adami or Ofria school). Only if the replicator language survives. Will attack: replication without heredity, and the missing BFF comparison.

## 6. Presentation and formatting

- **Lead paragraph.** Bold, before Section I, about 120–200 words, with no jargon (no "Brotli", "Gray code" or "collision entropy" without a gloss). It should explain why a decompressor is an interesting nonlinear map and what the reader learns about attractor selection in coupled systems.
- **Template.** AIP REVTeX 4.2 (the lead paragraph goes in a `quotation` environment) or the Word template. Abstract ≤ 250 words.
- **Data and code.** A Data Availability Statement (AIP standard; I could not verify the exact wording). Deposit code, dictionaries, the bit-exact JS reference decoder, the WASM build hash and the raw run JSON (Zenodo DOI at a tagged commit). Every figure must regenerate from one script. Provenance blocks are a precondition.
- **The browser artifact.** Cite it as software (URL plus archived snapshot) and describe it in the Methods as an exploration tool. Referees must be able to reproduce every number **without** the page, from the headless harness. A short video of the gradient frame can go in the Supplementary Material.
- **Supplementary Material.** Hosted by AIP: decoder specification, dictionary listings, swap-order study, extra seeds and sizes.
- **Open access.** Optional via Author Select (about $3.5–3.8k, unverified for Chaos). Post an arXiv preprint (nlin.CG plus cond-mat.stat-mech).
- **Language.** Strip the manifesto tone. Number the equations, and define the global map F: (Σ¹²⁸)^{L²} → itself formally in Section II.

## 7. Score and timeline

**Publishability at Chaos after the required work: 6/10.** It rises to 7–8 with E3 (finite-size scaling) and damage spreading.

**Timeline:**
- Must work: 2–3 weeks plus about 150 CPU-h.
- Review: first decision in 2–3 months, typically major revision.
- Revision: about 1 month.
- Acceptance: realistically 5–7 months from submission.

The main risk is a referee from category 1 or 3 judging that the physics content is too thin relative to existing CML and voter-model work. E3 and the competition mechanism are the insurance against that.

Sources: [Chaos Editorial Policies](https://pubs.aip.org/aip/cha/pages/policies), [Chaos About](https://pubs.aip.org/aip/cha/pages/About), [AIP Open Access options](https://publishing.aip.org/resources/researchers/open-science/open-access/), [AIP Author Instructions](https://publishing.aip.org/resources/researchers/author-instructions/), [CIRAD listing](https://ou-publier.cirad.fr/en/node/5469).
