# Artificial Life (MIT Press / ISAL): handling editor's report on Keimli

2026-10-21. Read: BRIEF.md, reviews/team/SYNTHESIS.md, INTRODUCTION.md, RESULTS_REPLICATORS.md,
RELATED_WORK.md §0, results/entropy-manipulators.md, results/decoder-map.md (parts).

**Journal facts, checked on the web.** I found the MIT Press submission-guidelines page through
search, but direct.mit.edu returned 403 to a direct fetch, so these come from the indexed copy of that page.
- *Artificial Life* is the official journal of ISAL, published by MIT Press since 1993.
- **Editors:** Alan Dorin and Susan Stepney (they wrote the vol. 30 editorial in 2024).
- **Article types:**
  - Article: original research, typically 6,000–12,000 words.
  - Review: usually solicited, >12,000 words.
  - Letter: <2,000 words.
  - Meeting Report: <2,000 words.
- **Submission:** a PDF through ScholarOne ManuscriptCentral, with 5–6 keywords. LaTeX or Word for accepted papers,
  and an Overleaf template exists.
- **Open access:** an optional paid OA route has existed since 2013.

**Not confirmed:** the current APC, any mandatory data/code-availability statement, figure limits, whether review is
single- or double-blind, and whether the editorship is unchanged in 2026. Check these on the live page before submission.

## 1. Fit and desk decision

The fit is good. A lattice whose local rule is an interpreter of the cells' own content falls squarely within
the journal's core. The paper's natural ancestors and competitors were published here or at ALIFE:
- Tierra and Avida;
- AlChemy;
- Langton's work on replication and the edge of chaos;
- the 2024 Computational Life study.

What the journal can use is a substrate between "programs as matter" and "rules as physics" whose map can be
**read**: censused, inverted and designed. Our readers do not have that, and it would be cited.

**Desk decision: I would not send these drafts out. I would invite resubmission** of a narrowed paper. The reasons are
these.
- The introduction rests on statements that the author's own panel has refuted, and an ALife referee would catch each
  of them within a page:
  - "no fixed points" (at least 48 exist);
  - "nothing replicates, nothing is selected";
  - "no computation at all" in Life-like rules;
  - "a hypothesis refuted in a system of programs is new";
  - the local entropy pump;
  - hash pinning by quenched disorder.
- The central thesis, separating what entropy reduction does from what computation does, is announced but not tested.
  There is no processor dose–response and no BFF census.
- Several numbers carry known pipeline defects:
  - censored medians;
  - the fixed swap order;
  - unconnected correlations;
  - no provenance.
- The author co-wrote the 2024 study and does not disclose it.

None of this is fatal. Sending the drafts out now would burn three reviewers on problems we already know about.

## 2. What our readers and reviewers will care about, and what triggers rejection here

**What they will care about:**
- **The meaning of "replicator" and "species".** This community has argued about trivial versus non-trivial
  replication, limited versus unlimited heredity, and open-endedness for 40 years. Fixed points of a map, called
  replicators without Langton 1984, will be read as overclaiming. Called "trivial self-maintenance, with repair, no
  heritable variation" and measured, they become an interesting deflation.
- **Whether the system says anything about life-like phenomena,** not only about its own dynamics. A paper about a
  decoder's attractors and nothing more belongs in *Complex Systems*. Ours must close the loop back to Computational
  Life, Tierra and Avida.
- **Reproducibility of a software artefact.** ALife readers will open the browser page. The panel found that its
  default single-thread engine corrupts the vote snapshot. A referee who finds that will distrust everything else.
- **Novelty against the closest work:**
  - Kaneko's coupled map lattices;
  - Wuensche–Lesser basin censuses;
  - Schaper–Louis "arrival of the frequent";
  - Dingle's simplicity bias;
  - Knierim et al. 2026.

**What triggers rejection here specifically:**
1. Thesis-level claims about "what computation adds" with no computation arm.
2. Vocabulary from biology (species, invasion, selection-free evolution) that does not match the mechanism.
3. A "system description plus pretty pictures" paper. A gallery of 25 CPUs and a gradient frame read as a demo, not a
   result.
4. Missing the replication literature.

## 3. The paper I would want

**Working title:** *Decompressive Cellular Automata: Designed Attractors and a Medium That Chooses Its Self-Maintaining
Types*

**Angle of the abstract (5 sentences):**
1. We introduce a lattice whose local rule decodes each cell's 128 bits as an LZ77-plus-dictionary stream, so that every
   cell is a program run every turn by an interpreter whose map can be sampled, enumerated and inverted.
2. A census of the map shows that one decoding step leaves a collision entropy of 16.5 bits and a min-entropy of 8.3,
   and that cells fall within tens of turns onto a small set of fixed points and short cycles.
3. Calibration against elementary rules of exactly known information loss shows that whole-cell collision entropy is
   exact where block entropy is blind, and that the decoder erases ~110 bits in one step where a Z80 running 256
   instructions erases almost none.
4. Inverting the census, we construct dictionaries with prescribed Gray-coded cycles, 3–32 attractor types, by
   exhaustive enumeration.
5. On the lattice every major type is present from its first detectable turn, but which one takes over is set by the
   mixing and settling medium rather than by basin size, the opposite of "arrival of the frequent", because uniform
   fixed-point domains are lattice fixed points while cycle domains survive only in phase.

**Claims to lead with (supported now or after the must-fix reruns):**
- (i) The attractor census and the entropy decay of the decoder map, with the hash:93 random-map null and 30 dictionary
  shuffles.
- (ii) Attractors constructed by design (the Gray-coded dictionaries), with the census check and the stray fixed point
  reported.
- (iii) The entropy calibration: rules 90 and 60 against the decoder and the Z80. Present it as a method and a single
  observation, not as the thesis.
- (iv) The medium, not the basin, picks the winner, with the phase argument and a competition matrix.
- (v) Self-maintaining types are trivial replicators with repair and no heritable variation: Langton's sense, measured.

**Drop, or move to supplementary material or a second paper:**
- **Drop:** the "two sources" dichotomy as a result; it becomes one paragraph of motivation plus future work.
- **Supplementary:** the 25-processor gallery, keeping one CPU (Z80) as a contrast row.
- **Supplementary or a separate *Complex Systems* or PRE paper:**
  - look-and-say;
  - the elementary-rule ring kinds beyond the calibration;
  - correlation lengths, the coarsening exponent and transition order.
- **Recast:** the gradient frame as an exploratory tool and Figure 1, never as evidence.
- **Drop entirely:**
  - hash pinning;
  - the q = 8 clock model;
  - "first in a system of programs";
  - "O(n) vs O(c^n)".

**Article type and length:** an Article of about 9,000 words, with ≤8 main figures and a supplement.

**Key figures:**
1. The system: cell, three stages, decoder bit layout, and one gradient frame.
2. The census: a basin/cycle diagram for F and a shuffle distribution.
3. Collision entropy against turn for rules 90, 60 and 150, the decoder, a Gray design and the Z80.
4. The Gray construction: a 3-cube state graph and a census table.
5. Takeover curves under two media, with bootstrap bands and uncensored statistics.
6. The competition matrix and droplet survival (fixed point against cycle).
7. A heritability test: mutants repaired versus dissolved.

## 4. Required work before submission

**Must (ranked):**
1. **Rewrite the introduction, abstract and results on the panel's claims table.** Add the literature: Langton 1984,
   von Neumann, Kaneko, Wuensche–Lesser, Schaper–Louis, Dingle, Knierim 2026, Maynard Smith–Szathmáry, Lempel–Ziv 1976.
   Fix the zenil2015 inversion and add the conflict-of-interest/co-authorship footnote. *2–3 days.*
2. **Pipeline hygiene.**
   - Provenance (commit, wasm hash, dictionary checksum, swap order) in every output.
   - Rotating swap order as the default.
   - Fix the page's single-thread snapshot bug and add a 1-against-4-thread parity self-test.
   - Retire the broken random generator.
   - Bring the docs up to date.

   *1 day.*
3. **Map-level spine.**
   - Exact enumeration of fixed points and 2-cycles.
   - Collision-entropy decay against a random-map null.
   - 30 byte and 30 word shuffles of F and Brotli 13.

   *2 days + overnight.*
4. **Replicator section rerun on the fixed pipeline.** Censoring-aware statistics with bootstrap intervals and unbounded
   period detection. Add first appearance against lattice size, droplet/critical-nucleus runs, a competition matrix with
   a transitivity test, and a heritable-bits measure. *2 days + ~60 CPU-h.*
5. **Re-evaluate the named dictionaries** under several seeds, uniform parameters and the frame. *~12 CPU-h.*
6. **Archive the release:** a Zenodo DOI for code and data, plus a frozen page version referenced in the paper.
   *½ day.*

**Nice:**
- A minimal BFF comparison: replicator frequency in BFF against Keimli's types under the same entropy measures. It would
  turn claim (v) from a deflation into a test of the 2024 paper, and is the single addition most likely to raise the
  score. *~1 week.*
- A Z80 instruction-budget dose–response (1–256), only as a teaser figure. *3 days + ~30 CPU-h.*
- An outside co-author from origin-of-life or replication theory.

## 5. Reviewers I would invite

- **An ALife replication and open-endedness theorist** (the Sayama, Taylor or Packard tradition; someone from the
  evoloop or Avida community). They will attack:
  - "replicator" and "species";
  - limited heredity;
  - whether any of this informs Computational Life.
- **A discrete-dynamics/CA mathematician** (the Wuensche, Kari or Gravner tradition). They will attack:
  - the census method, with step budgets and sampling bias;
  - the claim that "the global map is a CA" (period 4, 2 × 2 blocks);
  - novelty against Kaneko and the basin-of-attraction field.
- **A statistical physicist of coarsening and freezing.** They will attack:
  - deterministic freezing against quenched disorder;
  - the correlation measures;
  - the frame against uniform runs;
  - finite-size effects.
- **An algorithmic-information/simplicity-bias researcher** (the Louis or Dingle group, or Zenil). They will attack:
  - the coding-theorem framing;
  - the medium-against-basin contrast with "arrival of the frequent";
  - the LZ-as-Kolmogorov motivation.

**Conflicts to avoid:** Agüera y Arcas, the Knierim et al. authors, and the other co-authors of Computational Life.

## 6. Presentation and formatting

- **Length and format:** an Article of 6,000–12,000 words, submitted as a PDF through ManuscriptCentral with 5–6
  keywords; the MIT Press LaTeX template is preferred for a paper this mathematical.
- **Code and data:** I could not confirm a mandatory statement. I would require one anyway:
  - a public repository and an archived DOI;
  - raw data excluded from the repository but deposited;
  - a script per figure with provenance.
- **The browser artifact:** cite a frozen, versioned URL (a tagged GitHub Pages build plus a DOI snapshot) with a
  "reproduce Figure k" link per figure. The paper must stand without it; reviewers may not run it.
- **Supplementary material:** the dictionaries, the full census tables, the CPU gallery, the pre-registration and its
  amendments. Keep the pre-registration and the H1 retraction; our readers value them.
- **Open access:** optional and paid; recommended for visibility. I could not confirm the APC.
- **Language:** cut the biological metaphor; define "type", "domain" and "takeover" operationally.

## 7. Score and timeline

**Publishability after the required work: 7/10.** With the minimal BFF comparison: 8/10.

**Timeline:**
- 3–4 weeks of the author's work to submission;
- first decision ~3 months after submission;
- one major revision is likely, mostly on replication vocabulary and novelty against Kaneko and Schaper–Louis;
- acceptance plausibly 7–9 months from submission, and print a quarter later.

Sources: [MIT Press submission guidelines](https://direct.mit.edu/artl/pages/submission-guidelines) (via search index;
fetch blocked), [Overleaf template](https://www.overleaf.com/latex/templates/artificial-life-journal-submission-template/zhhhjdgvhryt),
[ISAL OA option 2013](https://alife.org/2013/05/09/new-open-access-option-for-artificial-life-journal-authors/),
[Wikipedia: Artificial Life (journal)](https://en.wikipedia.org/wiki/Artificial_Life_(journal)),
[Stepney bibliography, vol. 30 editorial](https://www-users.york.ac.uk/~ss44/bib/ss/nonstd/artl24.htm).
