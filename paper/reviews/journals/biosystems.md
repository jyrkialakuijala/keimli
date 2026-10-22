# BioSystems: handling editor's report on Keimli

2026-10-21. Read for this report: BRIEF.md, the internal panel's `reviews/team/SYNTHESIS.md`, `INTRODUCTION.md`,
`RESULTS_REPLICATORS.md`, `results/replicators.md`, `results/entropy-manipulators.md`.

**What I could and could not check on the web.** I confirmed the aims and scope on Elsevier's journal page
(shop.elsevier.com/journals/biosystems/0303-2647). The journal publishes "theoretical, computational, and experimental
articles that link biology" and "research on self-organizing information systems". It does **not** publish "purely
medical, computational, or ecological research" unless the work is clearly linked to the basic, conceptual aspects of
biological organization. Besides research papers, the editors encourage hypothesis papers and perspectives papers.
Wikipedia names Abir Igamberdiev as editor and lists special issues on biological computation (2022) and biological
thermodynamics (2024).

I could **not** retrieve the Guide for Authors, because ScienceDirect returned 403. That leaves the following
unconfirmed: word and figure limits (a 2018 special-issue call said there was no length limit), the abstract limit,
the Highlights format, the review model, the APC and turnaround times. The open-access charge is an aggregator
estimate of about US$2,700, and the journal is hybrid. Check all of these on the Guide before formatting.

## 1. Fit and desk decision

The fit is real but conditional. BioSystems has published on artificial chemistries, autocatalytic sets, (M,R)-systems,
biological computation and thermodynamics since Conrad's and Pattee's time. A model that asks where self-maintaining
structures come from, and what "replication" means when nothing copies, belongs here. But the scope sentence
excluding "purely computational research" is the one I would be applying. The current drafts are written for ALife
and compression readers: a decoder, 25 CPUs, Brotli dictionaries, a gradient frame. The biology appears only as the
word "replicator", and the drafts then argue that the word does not apply.

**Desk decision on the current drafts: return without review, inviting resubmission.** I have four reasons:
- No assembled manuscript exists, only pencil sections.
- Several central sentences are ones the internal panel has shown to be false: "no fixed points", "computes nothing",
  "no late first appearance" from 1/(N·b), and takeover "1.5× slower at 256²".
- Every lattice number comes from a pipeline with known defects: the fixed swap order, censored medians, the period-12
  detector and no provenance.
- The link to biological organization (heredity, selection, self-maintenance) is asserted rather than measured.

A resubmission built on the panel's "map paper", framed around heredity, would go out to review.

## 2. What readers and reviewers will care about; what triggers rejection here

They will care about:
- **What replicates, and what is inherited.** The strongest material for this journal is the measured observation
  that a mutant is never copied, only repaired or dissolved. In Maynard Smith and Szathmáry's terms this is *limited
  heredity*: the number of heritable types is bounded by the attractor count, and the drafts can count it. That is a
  biological statement, and it should be the spine of the paper.
- **Selection without a copying instruction.** "The medium, not the basin, picks the winner" is a selection result. A
  fixed-point domain is a fixed point of the lattice map, and fixed-point domains survive noise that melts cycle
  domains. Readers will want this stated as a fitness (persistence and robustness), with a competition matrix, and
  connected to Eigen's error threshold and to holistic or compositional replicators (Kauffman; Segrè–Lancet GARD,
  which is also limited-heredity).
- **Self-maintenance against dissipation.** The entropy budget, with erasure accounting for the decoder's structure,
  connects to autopoiesis and to biological thermodynamics. It must be phrased as coarse-grained, deterministic
  entropy loss, not as a "pump".

Rejection triggers specific to this journal:
- the paper reads as a compression or CA engineering paper with biology vocabulary attached;
- any claim about computational life in general (Tierra, Avida, BFF) made without data on those systems;
- unaddressed overlap with the author's own 2024 study, or a missing declaration of that co-authorship;
- inflated wording that the panel already flagged (a "species" with no inheritance, an "invasion" that is domain
  coarsening).

## 3. The paper I would want

**Working title:** *Self-maintenance without copying: designed attractors, limited heredity and selection by the
medium in a decompressive cellular automaton.*

**Angle of the abstract (5 sentences):**
1. Replicators in computational life are, as dynamical objects, periodic points of a rewriting map, and the question
   of their origin splits into which attractors exist and how a population reaches them.
2. We build a lattice whose local rule is a dictionary decoder, so that the attractors can be censused exactly and
   even prescribed by constructing Gray-coded cycles.
3. In this system every self-maintaining type is present within the decoder's transient; what takes time is takeover.
4. The winner is chosen by the exchange-and-majority medium, by robustness rather than by basin size, while variants
   are repaired or dissolved and never inherited, which is limited heredity in Maynard Smith and Szathmáry's sense.
5. Calibrated whole-cell entropy shows that the structure is accounted for by erasure, which gives a null model
   against which claims of open-ended heredity in program-based systems can be tested.

**Lead claims (only ones the evidence supports once rerun):**
1. Census of the decoder map: image, fixed points (at least 48 for F, by exact search), cycles and basins; collision
   entropy 16.5 bits and min-entropy 8.3 bits after one step, against the hash null.
2. Attractors can be prescribed: 3–32 Gray-coded 8-cycles, constructed by exhaustive enumeration and verified by an
   exact census, with the stray fixed point reported.
3. Selection by the medium: fixed points beat a basin 300 times larger under strong local settling, and the
   large-basin cycle wins under uniform settling. Show this as a competition matrix with a transitivity test and
   droplet (critical-nucleus) experiments.
4. Heredity is limited: the fate of single-bit and multi-bit mutants of each attractor, and the heritable information
   per type (log₂ of the number of distinct maintained types), against lattice size.
5. Entropy calibration: collision entropy is exact on rules with known loss (rule 90: 2 bits a turn), block entropy is
   blind, and the decoder loses about 110 bits in one step.

**Drop or move to supplementary material:**
- Drop: the 25-CPU gallery; the "computation vs entropy" dichotomy, which belongs in the second paper; correlation
  lengths, the t^⅓ exponent and transition order; the q = 8 clock model; the swarm-search dictionary ranking; the
  Declaration cycles.
- Supplementary: look-and-say; the Z80 entropy line, unless the processor dose–response is done; swap-order
  anisotropy; the gradient frame. The frame stays as a figure and as the interactive tool, not as evidence.

**Article type and length:** a Research paper, roughly 7,000–9,000 words, 8 figures and 3 tables, with an SI. Do not
submit it as a hypothesis or perspective paper, since the strength is the measured census.

**Key figures:**
1. A lattice snapshot with an attractor-type overlay.
2. The basin census and the cycle-length distribution against the hash null.
3. The Gray-code construction diagram and its verified 8-cycles.
4. First appearance against takeover time, censoring-aware, from 32² to 512².
5. The competition matrix and droplet growth or shrinkage against radius.
6. Mutant fate: repaired, dissolved or new type, against Hamming distance.
7. Collision-entropy decay for rule 60, rule 90, the decoder and the null.
8. A schematic of "attractor + medium = apparent replication".

## 4. Required work, ranked

**Must:**
1. **Pipeline hygiene** (panel item 2; 1 day): provenance in every output, the rotating order by default, the
   single-thread snapshot bug fixed with a parity test, the broken generator retired.
2. **Rerun the replicator Monte Carlo** (1–2 days + ~60 CPU-h) with censoring-aware statistics (Kaplan–Meier style,
   bootstrap CIs) and an unbounded period detector, from 32² to 512². Reword the first-appearance claim to "within
   the transient", and delete the takeover-scaling claim unless the rerun supports it.
3. **The heredity experiment** (1 day + ~10 CPU-h): inject mutants of each attractor at varying Hamming distance into
   domains under each medium. Report the fraction repaired, dissolved and converted to another type, and whether any
   variant is ever copied. This is the measurement that makes the paper BioSystems material.
4. **Competition matrix and droplets** (1–2 days + ~30 CPU-h), run annealed and quenched, with a transitivity test.
   This settles the panel's disagreement about robustness against nucleation.
5. **Rewrite on the panel's claims table** (2–3 days), with biological framing and literature:
   - von Neumann; Langton 1984;
   - Maynard Smith–Szathmáry 1995; Szathmáry 2000 on limited and unlimited heredity;
   - Eigen 1971; Kauffman 1986/1993; Segrè–Ben-Eli–Lancet 2000; Fontana–Buss 1994;
   - Maturana–Varela; Wilke 2001; Lenski 2003; Kaneko; Wuensche–Lesser.
   Declare the 2024 co-authorship and state what is new relative to Knierim et al. 2026.
6. **Typicality of the dictionaries** (overnight): 30 byte and 30 word shuffles of F and Brotli 13, so that the census
   is not a property of one hand-picked table.

**Nice (each strengthens the paper; the first would raise the score by one or two):**
- A minimal BFF attractor census: the fraction of BFF self-replicators that are fixed points or short cycles of the
  pairwise map, and whether BFF variants are inherited (1–2 weeks). This is the only route to saying anything
  general about computational life here, and an outside co-author would help.
- One processor (Z80) attractor census and dose–response over instruction budgets from 1 to 256 (3 days + ~40 CPU-h).
- A short analytic treatment of why a uniform fixed-point domain is a lattice fixed point while a cycle domain needs
  phase agreement.

## 5. Reviewers I would invite

- **A heredity and origins theorist** (e.g. Eörs Szathmáry or someone from the Parmenides / GARD tradition, such as
  Doron Lancet). Will attack: is "limited heredity" earned when there is no variation that is inherited at all? Is
  this heredity or just multistability? They will demand the mutant-fate data.
- **A specialist in autocatalytic sets and evolving CAs** (e.g. Wim Hordijk). Will attack: novelty against
  Kauffman/Wuensche basin censuses and Crutchfield–Mitchell, and whether "the medium selects" is just majority-rule
  coarsening with a known answer.
- **A program-based ALife researcher** (Tierra/Avida/Stringmol lineage, e.g. Susan Stepney's group, or Takashi
  Ikegami). Will attack: any implication that BFF or Tierra replicators "are just attractors" without their data;
  the absence of open-endedness tests.
- **A statistical physicist of lattice models.** Will attack: deterministic freezing against coarsening, the
  censoring, finite-size effects, and the quenched-hash artefacts.

Exclude Agüera y Arcas and the other 2024 co-authors, and Knierim et al., as conflicted or competing.

## 6. Presentation and formatting

- **Elsevier standard items** (confirm on the Guide): Highlights (3–5 bullets, typically ≤ 85 characters each), an
  optional graphical abstract, keywords, a CRediT statement, a declaration of competing interests, a data
  availability statement, and the disclosure of generative-AI use in manuscript preparation that Elsevier's policy
  requires.
- **Code and data:** a tagged release archived on Zenodo with a DOI, including the wasm build, its hash, the
  experiment scripts and one-command reproduction of every figure. Archive raw run files with provenance blocks, or
  give the seeds and scripts that regenerate them if they are too large.
- **The browser artifact** is welcome as supplementary material: a pinned, archived snapshot (Zenodo, plus Software
  Heritage), not just a live URL. It must not carry evidence, and every number in the paper must come from the
  headless harness. Short videos of takeover, droplets and mutant repair belong in the SI.
- **Open access** is optional (hybrid, APC unconfirmed). A preprint on arXiv or bioRxiv is acceptable under Elsevier's
  policy.
- **Readability for this journal:** move the Brotli bitstream detail, the dictionary construction algorithm and the
  25-machine list to Methods or the SI. The main text should be readable by a theoretical biologist.

## 7. Score and timeline

**Publishability after the required work: 7/10.** It would be 8/10 with the BFF census. The risks are a reviewer
judging it "purely computational" and the heredity result reading as negative. Turn the negative into the point: a
calibrated null model of limited heredity.

**Timeline:**
- Required work: 3–4 weeks of author time plus about 100 CPU-hours.
- First decision: probably 2–4 months (typical for the journal; not confirmed).
- One major revision: realistic.
- Acceptance: about 6–9 months after submission.
