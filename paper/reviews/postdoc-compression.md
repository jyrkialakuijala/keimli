# Review of the plan: the decoder as a map, entropy, neutrality

## 1. The decoder as a map f on 128-bit strings (Q4, H4)

H4 is right for the codebook (kind 45), which has no literals, and wrong for the reference decoder. Kind 36 inserts 8-bit literals, so the image is not confined to the dictionary's alphabet. Under uniform input a command emits about 2.1 literal and 4.75 copied bytes, so roughly 30 percent of output bytes are copied verbatim from the input and the image of f is of order 2^90, not thousands. "Thousands" describes the attractor set under iteration, which the off/off/on ablation and tools/ca-search.mjs probe; distinguish the image of f, the image of f^k and the cycles inside it.

Two statements are exact. First, the decoder reads a prefix of the cell and stops; the consumed prefixes form a complete prefix code, so under uniform input H(f(U)) ≤ E[min(c, 128)], c the bits consumed, and every x has at least 2^(128−c(x)) preimages. The counter exists (prm + 48); I estimate E[c] near 80 bits for the reference setting. Second, the output is determined by a skeleton (insert lengths, copy lengths, distances, transforms), the literal bytes and the window. Skeletons filling 16 bytes are countable by dynamic programming over the grammar with state (output position, ring, window), giving |image| ≤ Σ over skeletons of 256^(literals). For the codebook this is closed form: given the window the output is a product of independent bigram draws, so H(output | window) is eight times the entropy of a bigram at a uniform code position (F has 164 distinct bigrams in 4,400 bytes).

Distinct-output counts from 10^6 samples are only lower bounds once the image exceeds about 10^12; report Chao1 beside them and prefer quantities with error bars: the output byte-marginal entropy, the source decomposition of output bytes (literal, self-copy, dictionary copy) and the consumed-bits histogram, each against the dictionary's distinct byte count (F: 54 values, 1.93 bits per byte, 64 percent parentheses) and the header range V in {1, 8, 128, 4096}. The pair variant is a two-turn map g1 ∘ g0 since the roles alternate; state cycle lengths for that map.

Two corrections for the section 1 table: "longest copy 3" is the kind-0 slider, kind 36 copies 2 to 13 bytes (verify); and the stream never runs out, it wraps and re-reads the cell, header included, under a 1,024-bit cap.

## 2. Entropy accounting (claim 2, H5)

The page measures only the Shannon entropy of the lattice byte histogram (zeroth order), plus d1, d2, a zip ratio and the distinct-cell share. Claim 2 concerns the entropy of the configuration distribution, unmeasurable directly but with a clean theory: uniform crossover is a random permutation of bits, a doubly stochastic kernel that cannot lower it, while the median and the decoder are deterministic maps that cannot raise it. H5 as written has no conservation law behind it: a median flip is not a bit of entropy lost. What balances exactly is any state functional at stationarity, ΔS_mix + ΔS_median + ΔS_decode = 0 per turn on average. So snapshot after each stage and report the stage increments, per gradient band, of byte-histogram entropy, 2×2 and 4×4 block entropy of the dominant byte, LZ76 complexity (Kaspar–Schuster) of a Hilbert scan, and a named compressor's ratio: that is figure 4.

## 3. Dictionary as genome (H2, H7, thread F)

In grammatical evolution the genome is the codon string and neutrality comes from codon mod n and unread tail codons. Keimli has tail neutrality in the cell, not the dictionary: bits past the consumed prefix are neutral for f but carried by the swaps, unlike in GE. The dictionary's neutrality is positional: the window end lies in 0..4095 and kind 36 reaches back at most 64 bytes by explicit distance plus about 3 per command by ring adjustment, so bytes roughly 4096 to 4300 are unreachable by any cell. That exactly neutral region is a free null for the H2 sensitivity map: mutations there must give bit-identical runs. For H7, exact invariance is not to be expected under any listed operator: literals are not transformed, the case transforms act only on ASCII letters (near-inert on F, active on texts), and the bit-plane median commutes with XOR by a constant but not with add mod 95 or multiplication. Predict the ordering (XOR first, affine mod 95 last) and test it. Convincing neutrality experiments: the single-byte neutral fraction by position; neutral walks after Huynen, Stadler and Fontana with an acceptance test calibrated on seed-only replicates; Wagner's count of distinct phenotypes in the one-mutant neighbourhood.

## 4. Literature (threads E, F)

Cite Lempel and Ziv 1976 (complexity of finite sequences, IEEE Trans. IT) separately from Ziv and Lempel 1977; Kaspar and Schuster 1987 (Phys. Rev. A 36, 842) is the implementation. Zenil 2010 in Complex Systems classified CA by the compressed size of their evolutions (verify title, volume): the closest prior method. Cilibrasi and Vitányi 2005 (IEEE Trans. IT) works on ensembles of frames, never on 16-byte cells. Schmidhuber 2009, "Driven by compression progress" (verify venue). RFC 7932 for the distance ring and word transforms (verify sections). GE: Ryan, Collins and O'Neill 1998; O'Neill and Ryan 2001 (IEEE TEC). Neutral networks: Schuster, Fontana, Stadler and Hofacker 1994; Huynen, Stadler and Fontana 1996; Wagner 2008.

## 5. Recommendations

1. Rewrite H4 around H(f(U)), the attractor census under iteration and the consumed-bits bound; keep "thousands" for the codebook only.
2. Log E[min(c, 128)] and the output source decomposition for every dictionary in the manifest.
3. Implement the skeleton DP for kind 36 and the bigram entropy for kind 45 as an appendix result, checked against sampling and one exact enumeration (kind 0, V = 1).
4. Snapshot after each stage and report per-stage increments of the four proxies per gradient band; drop the Hamming "balance" from H5.
5. Make LZ76 complexity on a Hilbert scan the primary lattice measure; name the compressor behind "zip".
6. Verify the unreachable dictionary region from the code and use it as the null of the H2 map.
7. Pre-register the H7 invariance ordering; report literal and letter fractions as covariates.
8. Give every sampled statistic a seed-replicate error bar; "within noise" needs a calibrated test.

## 6. First experiment

Consumed bits and source decomposition over 10^6 uniform cells for the eight gallery dictionaries and their shuffled controls at V = 1, 8, 128 and 4096: a day's work on an existing counter that yields the H(f(U)) bounds, the literal fraction behind H7 and the V dependence H4 asserts, before any lattice run.
