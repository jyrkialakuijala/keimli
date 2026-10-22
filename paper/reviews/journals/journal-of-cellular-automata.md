# Journal of Cellular Automata: handling editor's report on Keimli

2026-10-21. Read: BRIEF, SYNTHESIS, the drafts and the main results notes.

**Journal facts, checked on the web today** (oldcitypublishing.com, JCA home page and "Notes for Contributors"):
- **Scope and type.** Scope: CA "studied theoretically or used as computational models". The examples it names include
  self-reproduction and structure formation. Article types are full papers, short communications, reviews and
  tutorials. The EiC is Andrew Adamatzky.
- **Format.** 6 × 9 in, 80 pages per issue. The abstract is 100–150 words, with 6–12 keywords and a short title of at
  most 35 characters. A nomenclature section is required.
- **References and figures.** References are numbered in MR style with all authors listed (no "et al."). Figures are
  EPS, TIFF or JPEG at 300 or 600+ dpi, with free colour plates when the colour is integral.
- **Charges and rights.** There are no page charges, and copyright passes to the publisher.
- **Indexing.** SCIE and Scopus, with a JIF of 0.3.

**What I could not confirm:** any length limit (a 10-page limit dates from 2007), a data, code or supplementary
policy, the open-access terms, review times, and the issue frequency (sources say six or four issues a year).

## 1. Fit and desk decision

The fit is good, better than at most ALife venues for the paper that exists. The paper takes a new local rule (a
dictionary decoder on a 2^128-state cell) and studies it the JCA way:
- an attractor and basin census of the local map;
- inverse design of the attractors;
- entropy loss calibrated against elementary rules with exactly known algebra;
- domain competition on a spatially non-uniform lattice.

This is the lineage of Wolfram 1983, Wuensche–Lesser and Kaneko, and "self-reproduction" and "structure formation" are
in our scope statement. **Desk decision on the current drafts: invite resubmission. I would not send them out.**
- They are pencil drafts with "to show" placeholders.
- They argue a thesis (that a decoder separates computation from entropy reduction) which the author's own panel has
  shown is not yet a result.
- They contain statements that any CA referee would reject on sight: that rule systems "compute nothing" (Life and
  rule 110 are universal), "no fixed points" (≥48 are known), "no loop" (18.2 % of output bytes are copied from the
  output) and an image "at most 2^93.5".
- Several lattice numbers come from a pipeline with known defects: the fixed swap order, censored medians, an
  unconnected correlation and the period-12 detector.

Sent out now, they would be rejected.

## 2. What our readers and reviewers care about; rejection triggers

Readers here are CA theorists and modellers. They will care about four things:
1. **A formal definition of the automaton.** This covers the state set, the neighbourhood and the global map. The map
   is period-4 in time and non-uniform in space; under uniform parameters it is uniform only on 2 × 2 blocks. The
   reader must be told whether the automaton is probabilistic or deterministic (hashed pseudo-randomness, so
   "deterministic freezing"). Today METHODS.md defers to the browser page. For us the page is a supplement, never the
   definition.
2. **Exact and statistical results kept apart.** That means exact enumeration where it is possible (fixed points,
   2-cycles, the Gray designs, verified bit-exactly), sampled censuses with their sampling error, and lattice
   statistics with seeds and intervals.
3. **Connection to established CA theory.** This covers Garden-of-Eden states and in-degree, basin fields
   (Wuensche/DDLab), coupled map lattices, majority and voter dynamics, coarsening, and Greenberg–Hastings-type cyclic
   competition.
4. **Reproducibility of every number**, from an archived code version.

**Triggers for rejection at JCA specifically:**
- false claims about CA computation;
- ALife rhetoric ("species", "invasion", "replicators evolve") with no precise dynamical statement under it;
- results that exist only in a web page;
- physics vocabulary (exponents, transitions, correlation lengths) without connected correlations and finite-size
  checks;
- a tour of 25 emulated processors that reads as a software description.

## 3. The paper I would want

**Working title:** *Decoders as cellular-automaton rules: attractor census, entropy loss and designed attractors of a
decompressive automaton.* Short title: "Decompressive automata" (24 characters).

**Abstract angle (5 sentences):**
1. We define a cellular automaton whose local rule decodes each 128-bit cell as an LZ77-plus-dictionary stream, framed
   by a bit-exchange and majority medium.
2. The one-step map is strongly contracting: the command skeleton is independent of the dictionary, and the output
   carries at most 93.5 bits of Shannon entropy, 16.5 bits of collision entropy and 8.3 bits of min-entropy.
3. Calibration against elementary rules with exactly known loss (rule 90 on a 128-ring loses 2 bits a turn) shows
   that whole-cell collision entropy tracks information loss exactly while block entropies are blind to it.
4. The attractors can be prescribed: dictionaries constructed by enumeration give 3 to 32 Gray-coded 8-cycles with
   verified basins and transients.
5. On the lattice, the medium rather than basin size selects which attractor's domains win, because a uniform
   fixed-point domain is a fixed point of the global map while a cycle domain survives only when it is
   phase-synchronised.

**Claims to lead with (all supported, or supported after the reruns in §4):**
1. **The one-step contraction and entropy census.** Report Shannon (upper bound), collision and min-entropy, the
   dictionary-independent skeleton, the ≥48 fixed points from exact search, and the shuffle controls.
2. **The calibration result.** Collision entropy versus block entropy on rules 60, 90, 150 and 170 with their
   nilpotency over GF(2). The decoder loses about 110 bits in step one. This is a methodological contribution JCA
   readers will reuse.
3. **Inverse design of attractors.** The Gray-code construction, the landing pads, and the exact census, with the
   stray fixed point of the three-species design reported.
4. **Domain competition.** The medium picks the winner, with the mechanism proved for uniform domains and measured as
   a competition matrix with seeds and intervals. The fixed swap order's anisotropy, and its removal, can go in as a
   short methodological note.
5. *(Optional)* **Truncated look-and-say as a contrast rule.** The read fraction 2(1 − 1/b) is predicted and
   measured, and the dynamics collapse onto the prefix of Conway's 3-cycle.

**Drop or move:**
- **Drop:** the computation-versus-entropy dichotomy (keep one paragraph of outlook); the Z80 comparison (one point is
  not a dose–response; it belongs to the second paper); "frame is the sweep"; the "entropy pump"; the q = 8 clock;
  all correlation-length exponents unless E0 has been redone.
- **Supplement:** the 25-processor gallery, the swarm searches, the dictionary zoo and the anisotropy scheme table.
- **Replicator framing:** use one section, "periodic points as trivial self-reproduction (Langton 1984)", in neutral
  words: attractor types and domain competition.

**Article type and length:** a full-length original paper of about 7,000–9,000 words, which is about 30–35 journal
pages at 6 × 9. That is close to half an issue, so stay at the lower end. Use 8–10 figures and 4–5 tables.

**Key figures:**
1. A schematic of a turn: mix, settle, decode, with the bit layout of a cell.
2. Entropy against turn for the calibration rules and the decoders (H₂ alongside block-8).
3. The basin and transient distributions for Swarm F against the hash:93 random-map null.
4. The Gray-cycle construction diagram with its verified census.
5. Lattice snapshots of the three-species design (a colour plate, which is free because the colour is integral).
6. The competition matrix and the takeover-share curves with intervals.
7. One gradient frame, labelled as an exploratory parameter map, not as evidence.

## 4. Required work before submission

**Must (in order):**
1. **Rewrite on the panel's claims table (SYNTHESIS §2) as a single CA paper** (3 days). This includes:
   - a formal definition section with the global map, its time period and its spatial non-uniformity;
   - declaring the co-authorship of the 2024 study;
   - fixing the citations (Lempel–Ziv 1976 rather than LZ77 for complexity; zenil2015 is cited the wrong way round).
2. **Pipeline hygiene** (1 day), following panel items 2–3:
   - a provenance block (commit, wasm hash, dictionary checksum) in every output;
   - the rotating order as the default;
   - the single-thread snapshot bug fixed, with a 1-against-4-thread parity test;
   - censoring-aware statistics with bootstrap intervals;
   - unbounded period detection.
3. **Map-level spine** (2 days plus an overnight run): exact enumeration of F's fixed points and 2-cycles in C, or an
   exact statement of what the search covers; the collision-entropy decay against the hash:93 null; 30 byte and 30
   word shuffles of F to place F in its distribution.
4. **Rerun the lattice claims on the fixed pipeline** (2 days plus about 60 CPU-hours):
   - droplets and critical nucleus;
   - the competition matrix with a transitivity test;
   - several seeds under both uniform parameters and the frame.

   Only what survives goes in.
5. **An archived artifact** (half a day): a Zenodo DOI for the code, the wasm, the scripts and the summarised data,
   with a README mapping each table and figure to a command.
6. **Formatting to the Notes** (1 day). Cut the 248-entry bib to the roughly 60–80 references actually cited, in
   numbered MR style with all authors listed. Add the 100–150-word abstract, the keywords, the nomenclature section and
   the figures at 300/600 dpi.

**Nice:**
- the in-degree and Garden-of-Eden density of the local map, estimated for example by preimage counting on reduced
  cells (V = 1, short cells), in Wuensche's terms;
- finite-size scaling with periodic boundaries (E3, 70–190 CPU-hours), which would let the physics claims stand;

## 5. Reviewers I would invite

- **A basin-field and discrete-dynamics specialist (Andrew Wuensche).** He will attack the sampled census against an
  exact one, the absent in-degree and Garden-of-Eden statistics, and the claim that the map is "analysable" when 2^128
  is far out of exhaustive reach.
- **A CA complexity and classification researcher (Genaro J. Martínez, or a Wolfram-class specialist).** He will
  attack the novelty against non-uniform and second-order CA, the "computes nothing" framing, and whether the decoder
  rule simply belongs to class 1/2 behaviour.
- **An algorithmic-information researcher (Hector Zenil, or someone from the coding-theorem and simplicity-bias line
  such as Dingle or Louis).** They will attack the LZ-as-Kolmogorov proxy argument, the misreading of zenil2015, and
  the case for collision entropy over block entropy.
- **A statistical physicist working on coarsening and voter/majority models (for example Janko Gravner).** He will
  attack deterministic freezing against coarsening, the bias-uncorrected correlations, the seeds and the edges instead
  of a torus.
- **Exclusions.** No 2024 co-authors and no Google colleagues.

## 6. Presentation and formatting

- **Data and code.** JCA states no policy (unconfirmed), but I would require a code and data availability statement
  with a DOI. The raw run data stays in the archive, not the paper.
- **The browser artifact.** Cite it as supplementary material with an archived snapshot. Every number must be
  reproducible from Node scripts without the page.
- **Open access.** Copyright transfers to OCP. Post the arXiv preprint before submission, and ask the EiC about the OA
  form's terms and fee.
- **Limits.** No word or figure limit is published; respect the ~30-page practical ceiling. Keep colour to the figures
  where it carries information (species and phase hue), because colour goes to plates at the back.

## 7. Score and timeline

**Publishability at JCA after the "must" items: 7/10.** The census, the calibration and the inverse design are solid
and new for this readership. The risk lies in the lattice section if the reruns weaken it. In that case cut the
lattice to a qualitative section and the score stays at about 6.

**Timeline:**
- about 3 weeks of author work plus about 80 CPU-hours;
- first decision about 3–4 months after submission (review times are not published; this is my estimate for a small
  journal with volunteer referees);
- one round of major revision;
- acceptance about 6–8 months after submission, and print a few months later.

The 0.3 impact factor means modest visibility. The preprint and the page will carry the readers.
