# Scientific Reports: handling editor's report on Keimli

Editorial Board Member (complex systems), 2026-10-21.

## 1. Fit and desk decision

**Fit.** *Scientific Reports* accepts work from any area of the natural sciences and judges it only on technical soundness. Its stated criterion is that the methods, analysis and interpretation must be "appropriate, properly conducted … and fully supported by the data". It does not judge novelty or importance. A careful paper on the decoder as a lattice rule, covering its attractor census, the designed attractors and which attractor the medium selects, fits the journal's discrete dynamics and complex systems subject areas well.

**Desk decision on the current drafts: reject without review, with explicit encouragement to resubmit.** Our standard is that conclusions must follow from the data, so a draft whose claims are contradicted by its own data cannot go out. These drafts state the following:
- "No fixed points." Swarm F has at least 48 verified fixed points, and a fixed point wins under the frame.
- "Never reads its own output." The decoder copies from its own output, and those copies are 18 % of output bytes.
- "Nothing replicates, nothing is selected."
- "The frame is the sweep." Frame runs and uniform runs pick different winners.
- Takeover times taken from medians that silently drop censored seeds.
- "Hash pinning by quenched disorder." The salt controls refute it.

There are also known code defects (the single-thread snapshot corruption, the fixed swap order, the broken generator) and no provenance. A reviewer would find these quickly. The problem is preparation, not fit.

## 2. What readers and reviewers will care about; what triggers rejection here

Our readers are generalists. They will want the exact map, the estimator behind each number, and evidence that the numbers survive more seeds and larger lattices.

**Rejection triggers specific to us:**
- **Overclaiming relative to data.** This is the main cause of rejection. Here it means the computation-versus-entropy thesis, any "first" or "new" claim, and the Ising or clock mappings unless they are derived.
- **Statistics.**
  - Every quantity needs n, seeds, and intervals (bootstrap, or Kaplan–Meier for times to threshold, since times are censored).
  - Exponents and correlation lengths need the bias-corrected connected correlation. The panel showed ξ falls from 39.8 to at most 9.5 cells once it is corrected.
  - Comparisons need a stated test or effect size.
  - A single seed (seed 11 for the searched dictionaries) is fatal for any ranking.
- **Reproducibility.**
  - Every figure must be regenerable from a deposited script and data with a commit and WASM hash.
  - A result produced only by an interactive page is not acceptable.
  - The 1-thread versus 4-thread parity failure must be fixed and tested before any number is reported.
- **Null models.** Every positive finding needs one: the matched random map (hash:93), 30 byte and 30 word shuffles, the cycle-projection null.

## 3. The paper I would want

**Working title** (one sentence, under 20 words, no puns, as our rules require): *A data decompressor iterated as a cellular-automaton rule has few, designable attractors, and the medium selects which one wins.*

**Abstract (5 sentences).**
1. We study a two-dimensional lattice whose local update rule is an LZ77-style decompressor: each 128-bit cell is decoded against a shared dictionary and replaced by its output, between stages of neighbour bit exchange and majority smoothing.
2. Calibrated against elementary rules of exactly known information loss, collision entropy shows the decoder removes about 110 of 128 bits in one step, while block entropy is blind to such losses.
3. The decoder's attractors are few and can be counted: one dominant short cycle plus enumerated fixed points for a reference dictionary, changed predictably by shuffling the dictionary.
4. They can also be designed: constructed dictionaries give 3–32 prescribed Gray-coded 8-cycles.
5. On the lattice, every major attractor type is present from the earliest detectable turn, and which one takes over is set by the smoothing medium, not by basin size, because a uniform fixed-point domain is a fixed point of the whole lattice map while a cycle domain survives only in phase.

**Claims to lead with** (all supported once the reruns are done):
1. The census of the map: collision entropy 16.5 bits and min-entropy 8.3 bits after one step for F; the attractor set; the effect of shuffles. Present the 93.5-bit figure only as an upper bound at turn 1.
2. Constructing attractors by inverse design (Gray cycles; "constructed by exhaustive enumeration under an exact census check").
3. The medium, not the basin, selects the winner, with the domain-level mechanism and a droplet or critical-nucleus test.
4. Methodological: collision entropy against block entropy, calibrated on rules 60 and 90.
5. Optionally, as a negative result: the two-stage medium freezes deterministically on its own, and the decoder adds oscillation, not arrest.

**Drop or move to Supplementary Information:**
- **Drop:** the computation-versus-entropy dichotomy (that is the second paper); the 25-CPU gallery; the Z80 comparison, except one sentence of outlook; "between computational and arithmetic life"; the frame as an evaluation tool; t^⅓ and ξ unless redone; the Ising or q = 8 framing.
- **Move to SI:** the decoder specification in full, look-and-say, the pair and vote modes, and the dictionary search history.

**Type and length.** Article, about 4,000 words of main text (limit 4,500 excluding Methods), a Methods section of about 1,500 words, 6–7 display items, and 50–60 references. RELATED_WORK.md has 248 bib entries; cut them hard.

**Key figures:**
1. Schematic of the three stages, with one gradient frame as a visual.
2. Entropy decay under iteration: collision entropy and min-entropy for rule 90, the decoder, the hash null and shuffles.
3. The attractor census as a basin and transient histogram across dictionaries and shuffles.
4. Designed dictionaries: the Gray-cycle state graph and its census check.
5. Takeover curves as Kaplan–Meier style plots with confidence bands, frame against uniform.
6. A droplet experiment: fixed-point against cycle domains under noise.
7. A table of dictionaries, attractors and winners, with n and intervals.

## 4. Required work before submission

**Must (ranked):**
1. **Rewrite every draft on the panel's claims table.** Declare the co-authorship of Agüera y Arcas et al. 2024 and Brotli co-design (as competing or non-financial interests, plus employer if relevant). Fix the citations: Lempel–Ziv 1976, Levin 1974 and the zenil2015 misuse. *2–3 days.*
2. **Pipeline hygiene.**
   - A provenance block in every output.
   - The rotating swap order as the default.
   - One turn engine, with a 1-against-4-thread parity self-test, which fixes the snapshot corruption.
   - The broken generator retired.
   - The docs corrected.
   *1 day.*
3. **Map results done properly.**
   - Exact enumeration in C of F's fixed points and 2-cycles, or bounds with confidence intervals.
   - Entropy decay against the hash:93 null.
   - 30 byte and 30 word shuffles for F and for Brotli 13.
   *2 days plus an overnight run.*
4. **Replicator and lattice reruns on the fixed pipeline.**
   - At least 20 seeds and three sizes (128², 256², 512²).
   - Censoring-aware takeover statistics with bootstrap intervals.
   - An unbounded period detector.
   - The droplet and critical-nucleus experiment that settles the panel's disagreement over robustness against nucleation.
   *2 days plus about 60 CPU-hours.*
5. **Re-evaluate each dictionary any claim rests on**, using several seeds and both uniform and frame settings. *About 12 CPU-hours.*
6. **Deposit the code, data and an archived page snapshot with a DOI** (Zenodo), plus scripts that regenerate each figure. *1 day.*

**Nice:**
- Corrected correlation lengths and the transition's finite-size scaling (E0/E1). This strengthens the paper but is not needed if those claims are dropped.
- A competition matrix with a transitivity test.
- An outside co-author from statistical physics or ALife. This would help credibility with reviewers, since the paper currently has a single author.

## 5. Reviewers I would invite

1. **Discrete dynamics or CA theorist** (Wuensche or Kauffman-style basin censuses, non-uniform CA). Will attack whether the global map is correctly defined (period 4, non-uniform in space, a 2 × 2 block CA), whether the enumeration is complete, sampling bias in the census, and prior basin-census work being under-cited.
2. **Statistical physicist** (coarsening, freezing, voter and majority models). Will attack the correlation estimators, finite-size effects, the word "transition" without scaling, determinism presented as quenched disorder, seed counts, and censoring.
3. **Information or compression theorist.** Will attack the entropy estimators and their resolution limit (about 33 bits), the bound stated in the wrong direction, the use of LZ as a proxy for Kolmogorov complexity, and the coding-theorem framing.
4. **ALife scientist** (an optional fourth, or a substitute). Will attack the words "replicator" and "species", the relation to BFF and Knierim et al. 2026, Langton's trivial self-reproduction, and whether "the medium selects" is a fitness under another name.

## 6. Presentation and formatting requirements

These were verified on nature.com/srep, October 2026.
- **Limits:**
  - Main text at most 4,500 words, excluding Abstract, Methods, references and legends; about 11 typeset pages.
  - Abstract at most 200 words, unstructured, with no references.
  - Title at most 20 words, as one accurate sentence with no puns. "Keimli" belongs in the text, not the title.
  - At most 8 display items; tables at most one page each.
  - Figure legends at most 350 words each.
  - About 60 references (a soft limit), in Nature style. No footnotes.
- **Structure:** Introduction, Results (with subheadings), Discussion (without subheadings), Methods.
- **Data Availability statement:** mandatory, placed before the references, with DOIs or accession identifiers.
- **Code availability statement:** required for custom code. The journal may publish the code as SI or ask for a maintained, version-controlled repository. Pin a release tag and a Zenodo DOI, and keep the raw lattice data in the deposit, not in the Git repository.
- **The browser artifact:** cannot be embedded. Cite it as a URL plus an archived, versioned snapshot in the code deposit. Supply SI videos of the frame. State that every reported number comes from the headless harness, not from the page.
- **SI:** one combined PDF (title and authors on page 1), with videos as separate files.
- **LLM use:** must be documented in Methods. This is relevant if AI agents helped with drafting, analysis or the internal review.
- **APC:** not confirmed. The official fees page did not render for me (404 via curl). Third-party figures are USD 2,590 for 2025 (UZH repository) and an undated USD 2,390 / EUR 2,090 / GBP 1,890. Check the "Open Access Fees and Funding" page before submitting. The article is published CC BY, and waivers exist.
- **Timeline:** the journal aims for a first decision within 45 days.

## 7. Score, timeline, reputation

**Publishability after the must-do work: 7/10.** The remaining risks are a reviewer insisting on finite-size physics, and drift back toward the grand thesis.

**Timeline:**
- About 3–4 weeks of work.
- First decision in about 6–10 weeks. The 45-day target often slips when reviewers for niche topics are hard to find.
- One major revision, which we aim to keep to a single round.
- Acceptance about 5–7 months after submission.

**Reputation trade-offs:**
- *Scientific Reports* is a high-volume megajournal with an impact factor of 4.9 (2025) and a soundness-only bar. Acceptance is realistic, and publication is fast, open, indexed and citable.
- In ALife and complex systems, a paper here carries less signal than one in *Artificial Life*, *Physical Review E* or *Chaos*, where the relevant readers are.
- My advice: if the physics (E0/E1, finite-size scaling) gets done, go to PRE or Chaos. If the goal is a clean, citable record of the census and the designed attractors, and then moving on to the second paper on computation, *Scientific Reports* is a reasonable and honest home. The reputational cost is moderate, not damaging.

Sources: nature.com/srep submission guidelines, editorial policies, editorial process and About pages (fetched 2026-10-21); APC figures from zora.uzh.ch and researcher.life (not official).
