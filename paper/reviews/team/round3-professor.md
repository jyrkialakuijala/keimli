# Round 3: the emeritus professor, claims and recommendations

Read all six round-2 notes. No new experiments.

## 1. Claims table

| claim (where) | verdict |
|---|---|
| A lattice whose local rule is a decompressor is new (Intro, contribution i) | KEEP-REWORDED: "As far as our search goes, a dictionary decoder has not been used as the local rule of a cellular automaton." Add Wuensche–Lesser 1992 as the precedent for designing attractors of a local map. |
| Two traditions; rule systems "compute nothing" (abstract, Intro, MOTIVATION) | DROP. Life is universal (Berlekamp–Conway–Guy 1982), so is rule 110 (Cook 2004), and Langton 1990 is about computation emerging in rules. Replace with the bounded-work contrast below. |
| Decoder "reads every bit once, never reads its output, no loop", "cannot compute" | KEEP-REWORDED: "One turn of a cell is a single-pass decoder of bounded work, at most 1,024 bit reads, that copies from a library and from its own output. Its output entropy cannot exceed that of the bits it reads. Whether the iterated lattice computes is not addressed." |
| O(n) against O(c^n); "fixed-depth, enumerated, inverted" | DROP as stated. Replace with the measured contraction: H₂(f^k(U)) reaches log₂3 by k ≈ 30 for F, against about log₂(k/2) bits lost for a random map (mathematics, information). |
| H(f(U)) ≤ 93.5 bits | KEEP-REWORDED: an upper bound at turn 1 (87.5 with header redundancy). Lead instead with H₂ ≈ 16.5 and H_∞ ≈ 8.3 bits. |
| "No fixed points" | DROP. F has at least 48, verified exactly. NEEDS-EXPERIMENT for the exact count: the overnight enumeration. |
| "LZ rather than Kolmogorov" | KEEP-REWORDED as the information theorist's paragraph: a parser is to Lempel–Ziv 1976 what a decoder fed random bits is to Levin 1974. Drop zenil2015 as support for "LZ is good enough". |
| Entropy pump; mixing supplies entropy (Intro, MOTIVATION) | DROP "pump". KEEP-REWORDED: "decoder as sink, the medium as a coarse-grained source; throughput is H(Y \| Z)". Both hashing modes are deterministic. |
| "Pinning by weak quenched disorder" (Intro, Sicilia) | DROP. "Freezing of a time-invariant deterministic rule" (Vichniac 1984). Salt by position changes nothing (physics E1). |
| "The frame is the sweep" (Intro) | KEEP-REWORDED: "The frame is a picture of the diagram, not its measurement" (Sapoval et al. 1985). Search scores vanish under uniform parameters (optimization). |
| Ablation retracts H1; "refuting a hypothesis in programs is new" | KEEP the retraction. DROP the novelty sentence (Lenski 2003, Wilke 2001). |
| Census: one short cycle for searched dictionaries, long cycles for texts, dependence on byte order | KEEP, with the 1–2 % fixed points and the shuffle distribution (30 shuffles) added. |
| Designed Gray 8-cycles, 3 to 32 species | KEEP. Drop "clock" and "Potts" (it is the 3-cube, Ashkin–Teller-like), and drop "no stray cycle". NEEDS-EXPERIMENT: multi-seed runs for "reading length decides". |
| "Replicators are fixed points and short cycles"; "nothing replicates, nothing is selected" | KEEP-REWORDED with the ALife reviewer's paragraph: trivial replication in von Neumann's and Langton's sense, limited heredity, no fitness function and no copy instruction. Declare the agueraYarcas2024 co-authorship beside it. |
| "Never late: first appearance at 1/(Nb)" | DROP the mechanism (the lattice basin is 30–100× the isolated one, and supercritical nuclei are needed). NEEDS-EXPERIMENT: E7 first appearance against N, and nucleus size s*. |
| "Takeover at front speed, ×1.5 with size" | DROP. A censored median reversed in sign; the share curves are size-free creep. |
| The medium chooses the winner | KEEP-REWORDED: "Uniform fixed-point domains have no internal walls" (mathematics), plus robustness ("survival of the flattest"). NEEDS-EXPERIMENT: droplets E6b and robustness ρ. |
| What remains needs computation; the processor arm (Section 6) | NEEDS-EXPERIMENT: the dose–response over instruction budget k, and the BFF census. Until then, one sentence in the outlook. |

## 2. Remaining disagreements

- **Physics and information on my cycle-projection null.** They say `cycle3f` already refutes it. It refutes the *three-state* reduction with instant collapse. My null keeps an off-cycle label and fits the table from data. The information theorist's own figures (H(cell) = 1.19 bits, about 2 % off-cycle) make a small-state reduction with a transient-depth label plausible. Whether the 128 bits matter beyond (phase, depth) is still untested. I concede the three-state version and nothing more.
- **Spirals.** I accept the physicist's correction that the Gray designs are cube-coded, so they are neither clock nor Potts models. That retires my "clock" home for them.
- **ALife, on putting the BFF census in this paper.** I disagree. The author is a co-author of the work under critique. A paper that measures his own earlier result against a toy built to deflate it will be read as advocacy. The replicator section should claim only what Keimli shows, and the BFF census should be a separate paper, preferably with a co-author outside the 2024 team.
- **Optimization, on MAP-Elites.** I disagree on priority. Design has already beaten search here. Report the searches as provenance, in one paragraph, with the broken LCG admitted, and spend nothing on a QD apparatus.
- **Physics, on scope.** The 345 CPU-hours buy a Physica D paper about a voting model with a decoder attached. That is honest work, but it is not this author's contribution. E0 and E1 are needed; E2 and E3 are optional.

## 3. Top five recommendations

1. **Rewrite the Introduction and abstract against the table above.** Remove the nine false sentences, name the old things by their old names, and declare the co-authorship. Cost: two days of writing, no CPU.
2. **Make the decoder-as-a-map section the paper's spine.** That means the census, H₂ and H_∞, the decay of H(f^k(U)) against a random-map null, the exact fixed-point enumeration, the shuffle distribution and the designed attractors with their funnel matrix. Cost: about one CPU-night plus 2 CPU-hours.
3. **Fix the measurement pipeline before any lattice number is reprinted.** Provenance fields, the rotating order, connected correlations or mutual information on phase labels, the censoring-aware medians, and one turn engine on the page. Then run E0 and E1. Cost: one to two days of code and about 20 CPU-hours.
4. **Recast the replicator section as trivial replication with limited heredity.** Test it with the variant-propagation test (10 seeds, several dictionaries), the droplet and robustness measurements, and first appearance against N. Cost: about 60 CPU-hours.
5. **Cut the processor arm to one dose–response figure, or defer it.** Twenty-five machines as a gallery invite the "Tierra demo" reading without its substance. Cost: negative.

## 4. Verdict

There is a paper here, and it is smaller and better than the drafts. It is "A dictionary decoder as a cellular automaton rule: attractor census, designed attractors, and trivial replication in a voting medium". Its venues are *Artificial Life* (MIT Press), *Complex Systems*, or a full paper at the ALIFE conference. The minimum work is recommendations 1 to 3, plus the variant test from 4. Physica D only if the physicist's E2 and E3 are done and the paper becomes about the medium.

A word to the author. You have done what most of us at Santa Fe did not: you pre-registered, you retracted, and you let the census tell you what your search had really found. The census is yours, and so are the designed attractors. The grand dichotomy is not yours, and much of it is not true. Langton, Wolfram and von Neumann have already said what can be said there. Claim the small thing exactly and it will still be cited in ten years. Claim the big thing and the first referee who was there will stop reading at the abstract.
