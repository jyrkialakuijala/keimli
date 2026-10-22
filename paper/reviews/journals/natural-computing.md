# Natural Computing (Springer): handling editor's report on Keimli

2026-10-21.

**What I checked on the web, and what I could not.** Confirmed: the journal is Springer's *Natural Computing* (ISSN 1567-7818 /
1572-9796). Its scope is "computing in nature and computing inspired by nature", covering theory, experiments and applications,
and it makes a special effort to get surveys and tutorials. The editors-in-chief are Jarkko Kari and Ion Petre (Turku).
Publishing is hybrid, with Open Choice open access. Springer Nature's research-data policy applies and a Data Availability
Statement is required. The 2025 impact factor is 1.9. Its recent CA papers are mostly formal or from ACRI collections. **Not confirmed:** the
full submission-guidelines page redirects to a Springer login, so I could not verify the article types, any word or page
limit, the abstract length, the review model (single- or double-blind), the APC, or the time to first decision. What I say about them below is my estimate; check the live page.

## 1. Fit and desk decision

The fit is real but partial. Our CA readership, starting with an editor-in-chief who works on CA dynamics, will find the
central object new and interesting: a lattice whose local rule is a decompressor, a fixed-depth map
{0,1}^128 → {0,1}^128 that can be sampled, enumerated and inverted. Two things in the project are exactly what this journal
publishes: the **attractor census of that map**, and the **inverse construction of dictionaries with prescribed Gray-coded
cycles**. The ALife thesis, that decoding separates entropy reduction from computation, is outside our core. As the panel
found, it is also mostly not yet a result. **Desk decision on the current drafts: desk reject, with an explicit invitation to
submit a re-scoped paper.** The reasons:
- The introduction claims things a CA referee will refute in the first paragraph: "no computation at all" in Life-like
  rules, "never reads its own output" (18.2 % of the output bytes are self-copies), and "no fixed points" (there are at least
  48).
- The global map is never defined formally. It is non-uniform in space (the gradients), period 4 in time, and hashed by
  position. That makes it a CA only on 2 × 2 blocks and only under uniform parameters, and the draft does not say so.
- The paper has no theorem anywhere, although several of its statements are provable.
- The internal panel lists open code defects: the snapshot corruption, the fixed swap order, censored medians, no
  provenance.

I would not send this out to referees. Re-scoped, it is a plausible "send out".

## 2. What our readers and reviewers care about; what triggers rejection here

**What they care about:**
- precise definitions of the local rule, the global map and the configuration space;
- what is proved and what is only measured;
- links to the classical CA questions: surjectivity and Garden-of-Eden configurations, limit sets, nilpotency, periodic
  orbits, and basins in the sense of Wuensche–Lesser;
- the inverse problem (designing rules with given dynamics);
- reproducibility of the simulations.

**What triggers rejection at this journal specifically:**
1. A simulation narrative with grand interpretation and no formal content.
2. Calling a stochastic, spatially non-uniform, hash-salted system a "cellular automaton" without qualification.
3. Known results presented as new. The rule-90 nilpotency on the 128-ring is Martin–Odlyzko–Wolfram 1984, and it is fine
   as a calibration only if it is labelled as one.
4. Thin related work on CA basins, coupled map lattices (Kaneko), simplicity bias and algorithmic-probability CAs
   (Zenil, Dingle).
5. ALife vocabulary ("species", "invasion", "replicators") on objects that are fixed points and short cycles.

## 3. The paper I would want

**Working title:** *Decompression as a cellular-automaton rule: attractor census and the design of prescribed cycles*

**Abstract angle (5 sentences):**
1. We study cellular automata whose local rule is an LZ77-style decoder with a static dictionary, acting on 128-bit cells.
2. The decoder's command skeleton is independent of the dictionary, which bounds the one-step output entropy by 93.5 bits.
   The measured collision and min-entropy are 16.5 and 8.3 bits for a searched dictionary.
3. We give an exact census of the map's fixed points, short cycles and basins, and show that the dictionary's byte order,
   not its alphabet, sets the attractors.
4. We prove a construction of dictionaries whose decoder has prescribed Gray-coded 8-cycles (3 to 32 of them), and verify
   the cycle sets exhaustively.
5. On the lattice, under deterministic mixing and majority settling, the medium and not the basin size decides which
   attractor's domains win, because a uniform fixed-point domain is a fixed point of the global map while a cycle domain
   needs phase agreement.

**Claims to lead with** (the evidence supports these):
1. The skeleton independence, and the entropy bound stated as a turn-1 upper bound, with the collision and min-entropy
   beside it.
2. The exact attractor census, together with the shuffle controls on the dictionary (byte order sets the cycle).
3. The constructive theorem for Gray-coded cycles: the landing-pad and constant-filler mechanism, with the conditions under
   which no stray cycles appear. The three-species design does have a stray fixed point, and the theorem must say so.
4. A domain-survival proposition (fixed-point domains are invariant, cycle domains need phase coherence), and the
   Monte Carlo result that the medium picks the winner.
5. The entropy-measure calibration as a short methods result: collision entropy exact on rules of known loss, block
   entropy blind. Optional.

**Drop or move to supplementary material:**
- the computation-against-entropy thesis, the 25 CPUs and the Z80 comparison (these are the second paper);
- look-and-say;
- the gradient frame as evidence (keep it as the interactive tool and one figure);
- the correlation lengths, the t^⅓ exponent and any phase-transition claims, until the physics experiments E0 to E3 are
  done;
- the swap-order anisotropy (supplementary material);
- the searched-dictionary history (supplementary material).

**Article type and length:** a regular original research article, about 25–30 pages in the Springer single-column
template (roughly 9–11k words), 8–10 figures, with proofs in the main text and the extended tables in the supplementary
material. Natural Computing accepts long papers, but a referee will not read a 50-page one.

**Key figures:**
1. The cell bit layout and the decoder command structure.
2. The basin and transient distributions for F, the texts and the shuffles.
3. A diagram of the Gray-cycle construction: the slots, the landing pad, the funnel.
4. The convergence funnel, designed against searched dictionaries.
5. Lattice snapshots: hue for the species, lightness for the phase.
6. Winner against the medium parameters (the "medium picks the winner" phase diagram).
7. The entropy-calibration curves.

## 4. Required work before submission

**Must** (ranked):
1. **Formal definitions and a rescoped writing pass** (3–4 days). Define the local map D_dict, the mixing M, the settling S
   and the global map. State exactly when the system is a CA: deterministic and uniform, with 2 × 2 blocks and period 4.
   Turn the panel's "drop" list into deletions. Disclose the co-authorship of Agüera y Arcas et al. 2024.
2. **Pipeline hygiene** (panel item 2, about 1 day):
   - provenance in every output;
   - the rotating swap order as the default;
   - the single-thread snapshot bug fixed, with a parity self-test against 4 threads;
   - the broken random generator retired.
   Every number in the paper must come from the fixed pipeline.
3. **Exact map-level results** (panel item 4, 1–2 days plus an overnight run). Enumerate F's fixed points and 2-cycles
   exhaustively in C, or state precisely what part of the space was searched. Compare the collision-entropy decay under
   iteration with the size-matched random-map null. Add 30 byte shuffles and 30 word shuffles of F and Brotli 13, so that
   F's typicality is tested.
4. **Proofs** (3–5 days). Prove the cycle construction theorem with explicit hypotheses: window size, printability, the
   header bits that must be clear. Give the stray-cycle condition, with the exhaustive check as corroboration. Prove the
   domain-invariance proposition. Prove or properly cite the bound on the skeleton entropy.
5. **Re-run the replicator lattice results** (panel item 6, reduced; 1–2 days plus about 40 CPU-hours):
   - the rotating order, with censoring-aware statistics and bootstrap intervals;
   - an unbounded period detector;
   - droplet and critical-nucleus experiments, enough to support the claim that the medium picks the winner;
   - a competition matrix with a transitivity check.
6. **Related work for a CA audience** (1–2 days): Wuensche–Lesser; Kauffman; Kaneko; Martin–Odlyzko–Wolfram; Hedlund
   and Garden-of-Eden results; Toffoli–Margolus; Fatès on stochastic CA; Zenil and Dingle on simplicity bias; Lempel–Ziv
   1976 and Levin 1974. Fix the zenil2015 citation, which is currently cited for the opposite of what it argues.

**Nice:**
- Surjectivity, or an explicit Garden-of-Eden count, for the 1D or block-CA restriction of a small instance (a 32-bit cell
  version could be fully enumerated).
- A scaled-down instance (16- or 32-bit cells) with complete state-transition graphs, which this audience would love.

## 5. Reviewers I would invite

- **A CA dynamics theorist** (the circle of Kari, Formenti or Guillon; e.g. Enrico Formenti or Pierre Guillon) will
  attack whether this is a CA at all (non-uniformity, hashing, time period), the absence of theorems, and loose
  terminology.
- **Andrew Wuensche** (basins of attraction, DDLab) will attack the census methodology: sampling against exhaustive
  enumeration, the Garden-of-Eden fraction, and comparison with random-map basin statistics.
- **Hector Zenil or Kamaludin Dingle** (algorithmic probability, simplicity bias) will attack the LZ-as-Kolmogorov framing
  and the citation of the coding theorem, and ask whether the output distribution follows a simplicity-bias law. The
  last point is a free extra result if it holds.
- **Nazim Fatès** (stochastic and asynchronous CA) will attack the claim that the "annealed" runs are deterministic, the
  role of the hash salt, and the statistics.

**Exclude** the co-authors of the 2024 Computational Life paper as conflicted.

## 6. Presentation and formatting

- **Data and code availability.** A Data Availability Statement is mandatory (confirmed). Archive the code, the WASM build,
  the dictionaries and the run JSONs on Zenodo with a DOI pinned to the paper's commit. GitHub alone is not acceptable as
  the archive.
- **Reproducibility.** Each table should name its script, commit, WASM hash, dictionary checksum and swap order (the
  panel's provenance block). A one-command script should regenerate every figure.
- **The browser artifact.** Cite it as software (with a DOI) and describe it in a short "interactive companion" paragraph,
  with a fixed-version URL. It is not a substitute for the methods: the paper must be complete without it. A short
  screen-recording or GIF can go in the supplementary material.
- **Format.** The Springer Nature LaTeX template (sn-jnl) is usual. Use one numbering system for definitions, theorems and
  proofs. Write the figure captions so they stand alone. Use vector figures, colour-blind-safe.
- **Open access.** Optional (hybrid); the APC was not confirmed.
- **Declarations.** Competing interests, including the co-authorship of the 2024 paper and the author's employer.
- **Limits.** No word or figure limit could be confirmed; aim at the length in §3.

## 7. Score and timeline

**Publishability after the required work: 6/10.** The census and the designed-cycle construction are a genuine, citable
contribution to the design of CA rules. The score rises to 7 if the construction theorem is proved cleanly and a small
instance is analysed exhaustively. It falls to 4 if the paper keeps its ALife thesis in front.

**Timeline:**
- about 3 weeks of work before submission;
- first decision 3–5 months (my estimate, not verified);
- one major revision likely;
- acceptance around 9–12 months from submission, and online-first publication shortly after.

A faster route is a short version at ACRI or AUTOMATA, followed by an invited extended paper in the journal's conference
collection.
