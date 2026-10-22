# PNAS: handling-editor assessment of Keimli

Member editor, Physical Sciences (Applied Mathematics; secondary Computer Sciences). 2026-10-21. I read BRIEF.md,
the panel's SYNTHESIS.md, INTRODUCTION.md, RESULTS_REPLICATORS.md, results/README.md, results/replicators.md,
results/entropy-manipulators.md and the Nature editor's note.

**PNAS rules (secondary sources only).** pnas.org returned 403, so these come from the Overleaf templates, an archived
scope page and a third-party guide dated 2026-10-08; confirm them on the Author Center.
- Research Report: 6 pages preferred, 12 at most (about 4,000 words, 4 display items, about 50 references).
- Abstract at most 250 words; Significance Statement at most 120 words, written for a scientist outside the field.
- Criterion: "exceptional importance", intelligible to a broad readership.
- Direct Submission, suggesting board and NAS members as editors; data deposited; open-access fee about $3k delayed,
  $6k immediate.

From memory, not confirmed: the policy covers code as well as data, and arXiv preprints are allowed. The Contributed
track needs an NAS member as a genuine author.

## 1. Fit and desk decision

**Fit.** PNAS publishes complex-systems and artificial-life work when it answers a question that people outside the
field already ask. Examples are the origin of self-replication, the role of computation in evolution, and simplicity
bias in genotype–phenotype maps. Keimli could become such a paper. The drafts do not yet make that case:
- They introduce a new object, a decoder used as a lattice rule, with a browser artifact and a census of attractors.
- They then argue a thesis, separating what computation adds from what entropy reduction alone does, which so far has
  one arm: the decoder arm.
- The processor arm is one Z80 setting at 256 instructions.
- There is no census of the BFF replicators that the thesis is meant to explain.

**Desk decision on the current drafts: desk reject, with an encouragement to resubmit** if rebuilt as below.
- **Breadth.** A census of one novel map is specialist work, for *Artificial Life* or *Phys. Rev. E*.
- **Retracted claims.** The panel has already withdrawn many draft claims ("no fixed points", with 48 known; "no
  computation in Life-like rules"; "never reads its own output"; "the frame is the sweep"). Reviewers would too.
- **Defects.** The lattice numbers rest on the fixed swap order, censored medians, a period-12 detector, an unconnected
  correlation measure and no provenance.

## 2. What readers and reviewers will care about; what triggers rejection here

**What they will care about.**
- **One sentence a biologist or physicist will repeat.** For example: "the replicators that emerge in random program
  soups are attractors of the interpretation map, and which one wins is set by the medium, not by the basin." That is
  of broad interest because it bears on Agüera y Arcas et al. 2024, which was widely read, and on origin-of-life
  arguments about how "surprising" spontaneous replication is.
- **A quantitative, falsifiable separation.** A dose–response curve that shows where computation starts to matter.
- **Calibrated measurement.** The rule-90 calibration of collision entropy is the kind of care that convinces.

**What would trigger rejection at PNAS specifically.**
1. Novelty of an object without a finding (the Nature editor's point, and correct).
2. The thesis is asserted from the decoder side only. Without the BFF census, an ALife reviewer will say the paper
   "deflates" replicators in a system it never studied.
3. Overclaiming that reviewers can refute from textbooks, such as computation in Life or rule 110, or Lenski 2003 as
   prior refutation.
4. Physics language (transition, t^⅓ exponent, correlation length) without finite-size scaling. One statistical
   physicist will sink the paper on this alone.
5. A self-citation conflict that is not declared. Declare the co-authorship of the 2024 study, and do not suggest its
   co-authors as editors or reviewers.
6. A paper that can be read only through the browser page. PNAS readers read the PDF.

## 3. The paper I would want

**Working title:** *Self-replicators as attractors: separating erasure from computation in artificial life.*
Alternative: *How much of artificial life is information loss?*

**Draft significance statement (113 words).** Self-copying programs arise spontaneously in random soups of simple
programs, which is often read as evidence that computation readily creates life-like organisation. We separate two
ingredients that such soups mix: the information a running program erases from its memory, and the computation it
performs. We build a lattice whose local rule is a decompressor: it erases information but cannot loop. Its
"replicators" are attractors of the rewriting map, so they can be counted, prescribed in advance and calibrated against
rules of exactly known information loss. Varying a processor's instruction budget from one step to hundreds, and
counting the attractors of the program soup itself, shows which phenomena of artificial life need computation and
which follow from erasure alone.

**Angle of the abstract.** Pose the question: is computation necessary for the phenomena of artificial life? Introduce
the erasure-only control, a decoder of bounded work per bit. Present the calibrated entropy measure. Then give three
results:
- attractor census and design;
- the medium selects the winner;
- the processor dose–response together with the BFF attractor census.

**Claims to lead with** (supported now, or supportable after the work in section 4):
1. **Calibrated entropy.** Whole-cell collision entropy measures a rule's information loss exactly (rule 90: 2 bits per
   turn), while Wolfram-style block entropy is blind to it. The decoder loses about 110 bits in its first step.
   (Supported now.)
2. **Census and design.** The decoder map's attractors can be enumerated, and they can be prescribed by construction:
   Gray-coded cycles, 3 to 32 species, built rather than searched, with an exact census check. (Supported once the
   exact fixed-point and 2-cycle enumeration in C is done.)
3. **The medium picks the winner.** On the lattice, the medium (mixing and settling), not the basin size, selects the
   winning attractor. Fixed-point domains are fixed points of the whole lattice map and survive noise that melts cycle
   domains. (Supportable after the clean rerun and the droplet/competition-matrix experiments.)
4. **Processor dose–response (the headline).** For processors run for 1 to 256 instructions, entropy loss, attractor
   counts and lattice phenomena are measured against the budget. This shows whether, and at what budget, processors
   leave the decoder's erasure curve. (Requires new work.)
5. **BFF as attractors.** The BFF self-replicators appear in an attractor census of the pairwise map, and their
   frequency scales as erasure alone predicts, or does not. (Requires new work; a negative result is publishable too.)

**What to drop.**
- The 25-processor gallery as content; keep it as an SI table.
- The gradient frame as evidence; keep it as Fig. 1's illustration and the artifact.
- "Between computational and arithmetic life."
- Look-and-say beyond one SI paragraph.
- All coarsening exponents, transition and correlation-length claims, the Ising/clock mapping and "hash pinning".
  These belong in a separate Phys. Rev. E paper.
- Swarm-search dictionaries as results.
- Every item in SYNTHESIS §2 "Drop".

**Article type and length.** Research Report, about 6 pages: about 4,000 words, 4 figures and about 50 references. A
rich SI appendix.

**Key figures.**
1. **The system.** The cell as a program, the decoder with its dictionary, the three stages, and one lattice snapshot.
2. **The calibration.** Collision entropy over time for rules 90, 60 and 150, the decoder, and Z80s at several budgets,
   on one axis.
3. **Census and design.** Basin and cycle spectra for natural, shuffled and designed dictionaries, and a Gray-cycle
   schematic.
4. **Dose–response and BFF.** Entropy loss, attractor count and replicator frequency against instruction budget, with
   the BFF census overlaid. Inset: the medium-selects-winner competition matrix.

## 4. Required work before submission

**Yes: the broad-significance version is the "computation vs entropy reduction" paper, not the map paper.** The map
paper is a good *Artificial Life* or *PRE* paper and should probably go there first, citable as the foundation. PNAS
needs the second arm.

**Must.**

| # | work | effort |
|---|---|---|
| M1 | Processor dose–response: Z80 plus two other ISAs (e.g. RISC-V, BFF-like) at budgets 1, 2, 4 … 256. Measure collision entropy, distinct cells, an attractor census of each map and the lattice outcome. Matched-erasure nulls: a random many-to-one map of equal H₂ (the Nature editor's "single biggest gap"). | 1–2 weeks, ~100 CPU-h |
| M2 | BFF census: an attractor census of the pairwise BFF map; replicator frequency against 1/(tapes × interactions); inheritance of mutations. Compare with Knierim et al. 2026. Ideally with an outside co-author from the BFF community. | 1–2 weeks |
| M3 | Pipeline hygiene and provenance (SYNTHESIS items 2–3): rotating order as default, a one-engine parity test, uncensored statistics with bootstrap intervals, unbounded period detection, a provenance block in every output. | 2 days + ~10 CPU-h |
| M4 | Exact enumeration of fixed points and 2-cycles for F, and 30 byte and 30 word shuffles of F and Brotli 13 as typicality nulls. | 2 days + overnight |
| M5 | Rerun the replicator section: droplets and critical nucleus, a competition matrix with a transitivity test, annealed as well as quenched runs, several seeds. | 2 days + 50–60 CPU-h |
| M6 | Rewrite on the claims table; add the missing literature (von Neumann, Langton 1984, Kauffman, Kaneko, Wuensche–Lesser, Wilke 2001, Lempel–Ziv 1976, Levin 1974, Bennett, Landauer, Dingle 2018, Schaper–Louis). Declare the conflict of interest. | 3 days |

**Nice.**
- Information-dynamics measures (transfer entropy, active storage) on decoder against processor. (3 days)
- One analytic result: a bound on the decoder's first-step collision entropy from dictionary statistics, or the
  fixed-point lattice-map lemma stated and proved. A theorem lifts a PNAS applied-mathematics paper considerably.
  (1 week)
- A MAP-Elites search: skip it.

## 5. Reviewers I would invite, and what each will attack

- **Lead author of the BFF or Knierim et al. line** (or a co-author not conflicted with the author, if possible). Will
  attack whether the decoder results transfer at all to BFF, where replication is copying via instructions.
- **Chris Adami or Charles Ofria** (Avida). Will attack "replicators are just attractors" as ignoring heredity and
  open-ended evolution. Will demand a heritable-variation measure.
- **Ard Louis or Kamaludin Dingle** (simplicity bias, arrival of the frequent). Will ask whether the census merely
  restates simplicity bias in a new map, and will check the use of Levin's coding theorem.
- **A statistical physicist of CAs and coarsening** (e.g. Sidney Redner or Paul Krapivsky). Will attack any phase or
  exponent language and the deterministic hashing presented as noise.
- **An information theorist** (e.g. Joseph Lizier or James Crutchfield). Will attack the entropy estimators, the
  resolution ceiling of H₂ (about 33 bits at 2¹⁷ cells), and the conflation of coarse-grained with thermodynamic
  entropy.

**Suggested editors.** Board and NAS members in applied mathematics or complex systems (e.g. Simon Levin); verify
current membership.

## 6. Presentation and formatting

- **Data.** Deposit raw run data in Zenodo with a DOI. Do not deposit only GitHub. Cite the datasets in the references.
  Exclude multi-GB intermediates but keep every table's source.
- **Code.** Archive a tagged release on Zenodo: the wasm, the JS reference decoder, experiments/*.mjs and the commit
  hash. Every number must be reproducible by one documented command.
- **Browser artifact.** State the URL in Methods and the significance-adjacent text. Also archive a frozen build with
  the release, because the live page will change. Reviewers must be able to verify everything without it.
- **SI appendix.** One PDF with S-numbered items: the decoder specification, the dictionaries (as data files), the
  25-processor table, the pre-registration and H1 retraction (reviewers will value it), the design enumeration and the
  robustness runs. Add one movie of the lattice.
- **Limits.** About 4,000 words main text, 250-word abstract, 120-word significance statement, about 4 figures and
  about 50 references. The 248-entry bibliography must shrink drastically; the rest goes into the SI.
- **Other.** Immediate open access (about $6k). Post an arXiv preprint (cs.NE or nlin.CG).
- **Prose.** Cut the essayistic "two traditions" opening: one paragraph to reach the question.

## 7. Score and timeline

**Publishability at PNAS after the required work: 6/10.** It rises to 7–8 if M1 and M2 give a clean, surprising
answer, for instance that the BFF replicators' frequency follows the erasure-only prediction, or that a sharp
instruction budget marks where computation starts to matter. The current drafts score 2/10.

**Timeline.**
- Must-work: 5–7 weeks of author time and about 250 CPU-h.
- The map paper submitted elsewhere in parallel: about 3 weeks.
- PNAS review: about 1–2 months to first decision, with one revision likely.
- Realistic acceptance: mid to late 2027.
