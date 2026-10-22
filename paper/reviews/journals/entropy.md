# Entropy (MDPI): handling editor's report on Keimli

2026-10-21. Read: BRIEF.md, reviews/team/SYNTHESIS.md, INTRODUCTION.md, RESULTS_REPLICATORS.md,
results/decoder-map.md, results/entropy-manipulators.md, the results index. Journal facts checked on the web
(mdpi.com pages returned 403 to direct fetches, so these come from search snippets of MDPI pages and DOAJ listings):
- **Fees and metrics.** APC CHF 2,600 (MDPI special-issue page; DOAJ via Melbourne, July 2026). Impact factor 2.1 for
  2025, 5-year 2.3, JCR Q2 in Physics, Multidisciplinary. Median first decision about 21 days (H1 2026), all self-reported.
- **Sections.** Information Theory, Probability and Statistics; Complexity; Entropy and Biology; Non-equilibrium
  Phenomena; Multidisciplinary Applications; Entropy Reviews; and others.
- **Special issues.** The Kolmogorov-complexity issues (one dedicated to Vitányi) closed in January and March 2026.
  "Shannon Information and Kolmogorov Complexity" showed no deadline.
- **Not confirmed:** an open special issue on cellular automata or artificial life; the exact current APC from the
  journal's own page; the current wording of the instructions for authors.

## 1. Fit and desk decision

The fit is good, better than the author may think. Several of Entropy's core interests meet in this project:
- many-to-one maps measured by their information loss, which goes back to Wolfram 1983's entropy view of CAs;
- collision and min-entropy as tractable measures;
- LZ complexity as a stand-in for Kolmogorov complexity, in the coding-theorem line of Levin 1974;
- simplicity bias, in the Dingle and Zenil line;
- ordering of a lattice through local information loss.

The journal regularly publishes algorithmic-information, CA-entropy and information-dynamics papers (Zenil, Lizier,
Prokopenko). The right home is the **Complexity** section, or Information Theory if the paper is framed around the map.

**Desk decision on the current drafts: invite resubmission.** I would not send them out as they stand. Three reasons:
- **The framing claims refuted things.** The introduction says rule systems carry "no computation at all", that the
  decoder has "no loop" and "no fixed points", and that it gives "2^93.5 image" bounds. The internal panel has already
  shown each of these is wrong; any CA reviewer will find them in the first page and stop reading charitably.
- **The headline thesis has no evidence yet.** "Separating computation from entropy reduction" is a research programme.
  The processor arm is one Z80 run.
- **Known code and data defects sit under the lattice numbers.** These are the unconnected correlation function,
  censored medians, missing provenance and the swap-order mismatch.

I am not desk-rejecting. The parts the panel calls the "map paper" are clean, novel and squarely Entropy material:
- the decoder-map census;
- the calibrated entropy measures (rule 90 losing exactly 2 bits per turn, H₂ tracking it exactly, block entropy blind);
- the roughly 110-bit first-step loss;
- the constructed Gray-coded attractors.

## 2. What readers and reviewers here care about; what triggers rejection

**What they care about:**
- **Measures defined precisely and validated.** Each estimator needs its estimation range stated: H₂ is resolvable only
  up to 2 log₂N − 1 ≈ 33 bits. Report bias and confidence intervals, and calibrate on systems with known answers.
  results/entropy-manipulators.md is exactly the right instinct; it should become a central section.
- **Correct use of information-theoretic language.** Separate Shannon, Rényi and algorithmic entropy. State bounds in
  the right direction: entropy bounds the image size from *below*. Say "coarse-grained entropy" for deterministic runs.
  No thermodynamic claims (Landauer, "entropy pump") without an actual thermodynamic quantity.
- **Placement against algorithmic information dynamics.** That means the coding theorem, BDM/CTM (Zenil), simplicity
  bias (Dingle, Camargo and Louis 2018) and local information dynamics in CAs (Lizier, Prokopenko, Zomaya 2008/2012).
  Entropy reviewers come from exactly these groups. Leave them out and you get a major revision at best.

**What triggers rejection here specifically:**
- **Over-interpretation.** Life-like or biological language ("species", "invasion", "nothing is selected") with no
  quantitative support, or ALife grand-narrative framing.
- **Numbers from defective code.** A reviewer who reruns the browser artifact and gets different numbers will sink it.
- **"Software description" papers** with no information-theoretic result.

State the contribution in the first paragraph.

## 3. The paper I would want

**Working title:** *Decompression as a Cellular-Automaton Rule: Information Loss, Attractor Census and Designed
Attractors of an LZ77 Decoder Lattice*

**Abstract angle, five sentences:**
1. We study a lattice whose local rule decodes each 128-bit cell as an LZ77-plus-static-dictionary stream, a
   many-to-one map whose information loss can be measured exactly.
2. Calibrated on elementary rules of known loss, the collision entropy is exact where it can resolve, and Wolfram-style
   block entropy is blind to non-local erasure.
3. One decoding step takes 128 bits to about 17 bits of collision entropy (8.3 bits min-entropy), more than 100 bits
   beyond the random-mapping null. Iteration reaches dictionary-specific attractors within about 16 turns.
4. Because the dictionary supplies only byte values, attractors can be prescribed: we construct dictionaries with 3 to
   32 Gray-coded 8-cycles by exhaustive enumeration and verify them by exact census.
5. On the lattice, the mixing and settling medium, not basin size, decides which attractor takes over, and fixed-point
   domains outlast cycle domains under noise.

**Claims to lead with** (supported now or after section 4's must-items):
1. The decoder map's entropy profile: upper bound H(f(U)) ≤ 93.5 bits; measured H₂ 16.5 and H∞ 8.3 bits for F;
   decay under iteration, set against the hash:93 null and against shuffled dictionaries.
2. Measurement methodology: whole-cell Rényi entropies are calibrated by rules 60, 90 and 150; local block entropy
   fails on information loss that spans the whole ring. This short, citable result is the most "Entropy" thing here.
3. Inverse construction of attractors (the Gray-coded cycles), with an exact census check.
4. The medium selects the winner. A uniform fixed-point domain is a fixed point of the whole lattice map; a cycle
   domain survives only in phase. This needs the competition matrix from the panel's item 6.
5. Optional, short: look-and-say truncated to 128 bits loses about half its information per step, read fraction
   2(1−1/b), predicted and measured.

**Drop or move to supplementary:**
- **Drop** the computation-against-entropy dichotomy (keep one paragraph of outlook) and the Z80 line, except as one
  table row labelled "preliminary".
- **Drop** Core War, Tierra and BFF as motivation beyond a paragraph, and all coarsening exponents and correlation
  lengths unless E0 is redone.
- **Drop** the "frame is the sweep" and the "hash pinning" language.
- **Move to supplementary** the 25-CPU catalogue, the dictionary-search history, the swap-order anisotropy and the
  pre-registration with the H1 retraction. Keep that one; Entropy readers will respect it.

**Format.** Article type "Article", in the Complexity section. MDPI sets no hard length limit; aim for about 8,000
words, 8–9 figures and 4 tables.

**Key figures:**
1. Schematic of the cell, the decoder and the three stages.
2. Calibration: H₂, distinct cells and block-8 against turn for rules 60, 90, 150 and 170.
3. H₂ and H∞ decay under iteration for decoder dictionaries, shuffles, the hash:93 null and look-and-say.
4. Attractor census: cycle lengths and basin fractions per dictionary.
5. A Gray-design state graph (3-cube metric).
6. Lattice snapshots under uniform settings for a fixed-point winner and a cycle winner.
7. The competition matrix and takeover curves with bootstrap bands.

## 4. Required work before submission

**Must**, in order:
1. **Rewrite on the panel's claims table** (2–3 days). Delete each refuted sentence. Cite Lempel–Ziv 1976 and Levin
   1974, and fix the zenil2015 citation. Add Lizier et al. on local information dynamics and the Dingle/Louis simplicity
   bias, and declare the 2024 co-authorship.
2. **Pipeline hygiene** (1 day): a provenance block in every output, the rotating order as the default, the page's
   single-thread snapshot bug fixed with a parity self-test, the broken generator retired.
3. **Map-level spine** (2 days plus overnight runs):
   - exact enumeration of fixed points and 2-cycles for F;
   - H₂ and H∞ decay with bootstrap confidence intervals over several sampling seeds;
   - 30 byte shuffles and 30 word shuffles each of F and Brotli 13;
   - the hash:93 random-map null run through the same iteration.
4. **Estimator section** (1 day). State the resolution limit of H₂, its estimator variance and the
   birthday-paradox basis. Add an LZ76 density estimate beside H₂ so the "LZ as a Kolmogorov stand-in" claim is used,
   not only asserted.
5. **Lattice section on the fixed pipeline** (2 days plus about 60 CPU-hours): a competition matrix with a transitivity
   test, censoring-aware statistics, and unbounded period detection. If time is short, cut the lattice to claim 4 alone.

**Nice:**
- the connected correlation and phase mutual information as a time series (Lizier-style active information storage
  per cell would delight this readership; about 2 days);
- the H₂ decay of the processor under an instruction budget of 1–256, as a teaser figure only (1 day);
- finite-size scaling (save it for PRE or Chaos).

Total for the must-items: about 2 weeks and about 80 CPU-hours.

## 5. Reviewers I would invite

Exclude co-authors of Agüera y Arcas et al. 2024. I would invite three of the five below.
- **Algorithmic information dynamics or coding theorem** (e.g. Hector Zenil, or Kamaludin Dingle/Ard Louis). Will
  attack: does the paper use LZ as a Kolmogorov proxy correctly; is the coding-theorem analogy (decoder ↔ universal
  prior) stated rigorously or only by analogy; why not BDM.
- **Information dynamics in CAs** (e.g. Joseph Lizier or Mikhail Prokopenko). Will attack: block entropy dismissed too
  quickly, since it measures something else; no local (pointwise) measures; estimator bias of H₂ at small N.
- **Discrete dynamics and basins of attraction** (e.g. Andrew Wuensche, or a Kauffman-network theorist). Will attack:
  is the census exhaustive or sampled; the claim of "no stray cycle"; the cost of the Gray construction; whether the
  global map is a CA at all (period 4 in time, uniform only on 2×2 blocks).
- **Statistical physics of coarsening** (e.g. a Kaneko-school coupled-map-lattice person). Will attack: freezing
  versus coarsening, the correlation length, finite-size effects, and the claim that the medium decides.
- **Artificial life** (e.g. Christoph Adami or Tim Taylor). Will attack: the word "replicator",
  heredity, and the missing BFF comparison. Invite them only if the life framing stays; otherwise skip them.

## 6. Presentation and formatting requirements

- **Template.** MDPI LaTeX or Word; single-paragraph abstract of about 200 words; keywords.
- **Back matter.** The required sections are Author Contributions (CRediT), Funding, Data Availability Statement,
  Conflicts of Interest and, where needed, Institutional Review Board statements (not needed here).
- **Conflict of interest.** Google employment and the Brotli authorship must be declared, as must the 2024 co-authorship.
- **Data and code.** Entropy expects a public repository with a DOI.
  - Archive the exact commit of the code, the wasm hash and the experiment scripts on Zenodo.
  - Archive the summary JSONs, not the raw multi-GB runs.
  - Every number should be reproducible by one command.
- **The browser artifact.** Cite it as software (Zenodo DOI plus URL) and describe it in Methods. Reviewers cannot be
  required to use it, so the paper must stand without it. A "reproduce Figure N" button or URL parameters would help.
- **Supplementary material.** Unlimited, as PDF or zip; put the CPU catalogue, the dictionary searches and the
  pre-registration there.
- **Preprints.** Posting to arXiv first is allowed and advisable.
- **Open access and APC.** The licence is CC BY. The APC is about CHF 2,600 (unconfirmed on the journal's own page).
  Check whether the author's institution has an MDPI agreement; invited special-issue papers sometimes get discounts.

## 7. Score, timeline, reputation

**Publishability after the must-work: 8/10.**

**Timeline.** About 2–3 weeks of preparation. After submission, first decision in about 3–4 weeks; one round of major
revision is likely, with MDPI's 10-day revision clock negotiable to 30 days; publication about 2–3 months from
submission.

**Reputation trade-off, stated honestly:**
- **For it.**
  - Entropy is the most respected MDPI title in this area, indexed in Web of Science and Scopus, and has a real
    algorithmic-information community.
  - It is fast and open access, and its audience is exactly the one that will reuse the calibration result.
- **Against it.**
  - Impact factor about 2, and MDPI's volume-driven model carries a stigma among some physicists and ALife people.
  - Review depth varies; a strong paper can get a thin review, which buys speed but not credibility.
- **For this author.** The decoder-map paper reaches its natural audience here. The bigger thesis, what computation
  adds once entropy reduction is accounted for, deserves a more prestigious outlet once it has evidence: Artificial
  Life, PRE, or PNAS with co-authors.

**My suggestion:** publish the map paper here (or in Complex Systems), on arXiv first, and keep the dichotomy paper for
a higher-profile venue.
