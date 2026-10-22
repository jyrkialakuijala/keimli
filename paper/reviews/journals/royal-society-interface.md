# Journal of the Royal Society Interface — handling editor's report on Keimli

2026-10-21.

**Journal facts.** The journal's own pages returned HTTP 403, so I could not read the current guidelines.
- *Confirmed from secondary sources:*
  - the scope is the physical/mathematical-sciences interface with the life sciences, and biological relevance is required;
  - research articles run 2,500–8,000 words including references, strictly enforced (a 2022 copy);
  - fully open access in 2026 under Subscribe to Open, with no APC; 2027 may revert to hybrid.
- *Not confirmed:* the current article types beyond Research article and Review, figure limits, the exact review criteria, and the
  code-deposition wording. From Royal Society policy as I remember it: a mandatory data accessibility statement, DOI repositories, and
  the ESM on Figshare.

## 1. Fit and desk decision

Interface publishes mathematics and physics *about living systems*. As drafted, Keimli is a paper about compression, cellular automata and
artificial life in which biology appears only as metaphor ("species", "replicators", "invasion"). The lattice-of-decoders idea is new
(nobody has used a decoder as an iterated local rule). There is also one result that does reach biology: **the medium, not the basin size,
decides which attractor wins**, which speaks directly to "arrival of the frequent" (Schaper & Louis 2014), simplicity bias in
genotype–phenotype maps (Dingle et al. 2018), and "survival of the flattest" (Wilke et al. 2001). That result is buried under a
computation-versus-entropy thesis that the author's own panel says is not yet supported and partly false ("no fixed points",
"never reads its own output", "Life computes nothing"). The pipeline defects (fixed swap order, censored medians, period-12 detector,
no provenance, a biased correlation length) touch exactly the replicator numbers an Interface paper would lead with.

**Desk decision on the current drafts: desk reject, with an explicit invitation to resubmit** as a different and narrower paper. Reasons:
- no stated biological question;
- abstract-level claims contradicted by the author's own data;
- the key lattice statistics come from a pipeline known to be defective;
- the length and bibliography (248 entries) are far beyond an 8,000-word cap that includes the references.

## 2. What readers and reviewers will care about, and what triggers rejection here

**What they will care about:**
- **The biological question.** Origins-of-life and evolutionary-dynamics readers will ask what this teaches about how self-maintaining
  entities arise and spread in a prebiotic or digital population.
- **Contact with genotype–phenotype map theory.** The decoder is a many-to-one, highly biased map (collision entropy 16.5 bits after one
  step). That is precisely the GP-map setting. Reviewers will want the frequency of attractors plotted against their complexity
  (Dingle's plot), and the lattice result placed against arrival of the frequent.
- **Honest replication semantics.** "Replicator" must mean a periodic point of the local map, maintained by the medium: trivial
  replication in Langton's sense, with no heredity of mutants. Overclaiming Darwinian evolution here will sink the paper.
- **Statistics.** Seeds, bootstrap intervals, and censoring-aware takeover times.

**What triggers rejection at this journal:**
- "This is computer science / CA physics with no life-science content" — the commonest Interface desk reject.
- Claims of evolution or selection without inheritance of variation.
- Results that depend on one engine with known bugs.
- Not engaging the BFF/Computational Life literature the author co-wrote. The conflict must be declared, and Knierim et al. 2026
  (replicators found without interaction) must be discussed, because it makes the same deflationary argument.

## 3. The paper I would want

**Working title:** *The medium, not the basin, selects: attractor competition in a lattice of decompressing cells*

**Abstract angle (5 sentences):**
1. Self-replicators emerge spontaneously in populations of random programs, but it is unclear which of their properties need
   computation and which follow from any many-to-one rewriting.
2. We study a lattice whose cells are rewritten by a bounded, linear-time decompressor, a strongly biased genotype-to-genotype map whose
   periodic points can be enumerated and even prescribed by construction.
3. Self-maintaining types are fixed points and short cycles of this map; they are present from the first detectable turn, and what
   takes time is their takeover.
4. Which type takes over is set by the mixing and smoothing of the medium, not by basin size: fixed points survive noise that
   desynchronises cycle domains, so a type with a 0.3 % basin can beat one with 99 %.
5. Arrival of the frequent is therefore not sufficient in a spatial population, and the system provides an analysable null model for
   claims about digital replicators.

**Claims to lead with (supported, after reruns):**
1. **The census.** The decoder map's one-step output entropy is bounded by 93.5 bits; the real collision entropy is 16.5 bits and
   min-entropy 8.3 bits; at least 48 exact fixed points; all random cells reach a few short cycles. State it against the random-map
   null and 30 dictionary shuffles.
2. **Attractors can be prescribed.** Gray-coded 8-cycles, 3 to 32 types, are constructed by exhaustive enumeration and verified by
   census, which gives a controllable "species pool".
3. **Presence from the start, lateness is takeover.** This needs the rerun with censoring-aware statistics and unbounded period
   detection.
4. **The medium, not the basin, picks the winner,** with the mechanism: a uniform fixed-point domain is a lattice fixed point, while a
   cycle domain needs phase coherence. Back it with the droplet/critical-nucleus experiments and a competition matrix.
5. **Optional: the calibration.** Collision entropy tracks the exactly known loss of rule 90; block entropy is blind. The decoder loses
   about 110 bits in one step; a Z80 hardly loses any. Include it only as one methods paragraph plus an ESM figure.

**Drop, or move to the ESM:**
- the computation-vs-entropy dichotomy (a second paper);
- the 25-CPU gallery, Redcode and look-and-say;
- coarsening exponents, correlation lengths and the Ising-field mapping (these belong in a physics journal);
- "the frame is the sweep" (keep the gradient frame as Figure 1 and the interactive tool only);
- the searched-dictionary history and the pre-registration story (one sentence; the documents go in the ESM).

**Article type and length:** Research article, about 6,500 words of text plus 60–80 references, under 8,000 in total. 5–6 main figures.

**Key figures:**
1. The system: the three stages, the gradient frame snapshot, and a decoded cell.
2. The map census: the attractor spectrum, the basin distribution against output complexity (Dingle-style), and the shuffle nulls.
3. Designed Gray cycles: the construction and the verified census.
4. Takeover curves with confidence bands, for uniform parameters and the frame, with first presence marked.
5. The phase diagram of the winner in the (mixing, settling) plane, with basin size annotated, plus the droplet survival curves.
6. Optional: the entropy calibration.

## 4. Required work before submission

**Must (ranked):**
1. **Pipeline hygiene** — the panel's items 2–3:
   - provenance in every output;
   - the rotating swap order as default;
   - single-engine parity with the snapshot bug fixed;
   - censoring-aware statistics with bootstrap intervals;
   - unbounded period detection.

   Effort: about 2 days plus 10 CPU-h.
2. **Rerun the replicator Monte Carlo** at 128², 256² and 512², with at least 10 seeds, under uniform parameters across a grid of
   (mixing, settling) and under the frame. Report winner probabilities, not single winners. Effort: 2 days plus about 60 CPU-h.
3. **Mechanism of "medium picks winner".** Droplets of each type in a sea of another; critical nucleus; wall velocity against noise;
   a competition matrix with a transitivity test. Effort: 2 days plus about 40 CPU-h. *This is the paper's biological claim; without it
   I would not send it out.*
4. **GP-map framing analyses:** attractor frequency against LZ complexity (simplicity-bias plot); F against 30 byte and word shuffles;
   exact enumeration of fixed points and 2-cycles. Effort: 1–2 days plus an overnight run.
5. **Rewrite** to the panel's claims table:
   - declare the co-authorship of Agüera y Arcas et al. 2024;
   - discuss Knierim et al. 2026, Schaper–Louis, Wilke 2001, Langton 1984, Kauffman and Kaneko;
   - cut the bibliography to about 70 entries.

   Effort: 3 days.

**Nice:**
- A heredity measure: the fraction of perturbed cells that return to their own type rather than to their neighbour's. This would make
  the "no inheritance" statement quantitative. About 1 day.
- A BFF census on the same axes, as a bridge to the second paper. About 1 week; worth about +1 on the score.
- An outside co-author from evolutionary dynamics or GP maps.

## 5. Reviewers I would invite

- **A GP-map / simplicity-bias specialist** (the Ard Louis or Kamaludin Dingle group, or Sebastian Ahnert). They will attack whether
  "medium beats basin" is really in tension with arrival of the frequent, which concerns the *phenotype* frequency at introduction, and
  will demand the complexity–frequency plot.
- **An evolutionary-dynamics theorist** (Claus Wilke, or someone working on survival of the flattest and quasispecies). They will say
  "robustness wins under noise" is survival of the flattest, and will ask what is new.
- **A digital-life / origins researcher** (the Avida lineage, Chris Adami or Charles Ofria; or Ricard Solé or Hiroki Sayama). They will
  attack the word "replicator" and the absence of heredity and of any BFF comparison, and will check the conflict of interest with
  Agüera y Arcas et al. 2024. Avoid Google co-authors of that paper and of Knierim et al. 2026.
- **A statistical physicist on spatial competition and coarsening** (Kaneko's CML school, or a domain-growth specialist). They will
  attack the deterministic freezing, the finite-size effects, the frame against uniform parameters, and the statistics.

## 6. Presentation and formatting requirements

- **Data accessibility statement (mandatory).**
  - Deposit the code (wasm sources, experiment scripts, dictionaries with checksums) and the summarised run data in Zenodo or Dryad
    with a DOI, pinned to a tagged commit.
- **The browser artifact.**
  - Cite it as a versioned archived build, with the GitHub Pages URL as a convenience only.
  - Add a "reproduce Figure N" preset in the page.
  - Short videos of the frame can go in the ESM.
- **ESM** (hosted on Figshare): the methods detail of the decoder grammar, the dictionary construction, the calibration, the
  pre-registration and amendments, and the 25-changer gallery.
- **Open access.** No APC in 2026 under Subscribe to Open; confirm the 2027 status at acceptance.
- **Format.** About 8,000 words including references (strict). Figures must be readable in greyscale; the maroon/blue palettes need
  colour-blind checking.
- **Writing.** Use plain terms: "attractor types", not "species", unless defined. The conflict with Agüera y Arcas et al. 2024 goes
  in the competing-interests statement.

## 7. Score and timeline

**Publishability at Interface after the required work: 5/10.** It rises to 6–7 if the BFF bridge or a GP-map co-author makes the
biological contribution unmistakable. The risk is scope: even a clean paper may be read as a CA paper, and *Artificial Life*,
*Physical Review E* or *Chaos* are safer homes for the physics.

**Timeline:**
- about 3–4 weeks of work plus about 120 CPU-h to resubmission;
- first decision about 6–8 weeks after submission;
- one major revision is likely (2–3 months);
- acceptance about 5–7 months from submission.

Sources consulted on the journal:
- Royal Society S2O news, 2025: https://royalsociety.org/news/2025/08/subscribe-to-open/
- Subscribe to Open for authors: https://www.royalsociety.org/journals/authors/subscribe-to-open-for-authors/
- Secondary guideline copies (Editage; eshukan.com, 2022 snapshot)
