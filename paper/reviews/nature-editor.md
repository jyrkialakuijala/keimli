# Editorial assessment of the Keimli research plan

Senior editor, physical sciences. Assessment of the plan dated 2026-10-18, not of a manuscript.

## 1. What the plan proposes

The authors run a 1024 × 1024 lattice of 128-bit cells through three stages per turn: a hash-driven uniform crossover with neighbours (rate 2p(1−p), p a horizontal gradient), a per-bit-plane 3 × 3 median (strength a vertical gradient), and a rewrite in which each cell's bits are read as a Brotli-like compressed stream against a few-kilobyte dictionary and replaced by what they decode to. Section 0 elects one headline claim, that a decompressor used as the local rule gives sustained, spatially organised dynamics and that the rule is therefore indexed by a text; a mechanism claim, that the three stages balance entropy and every frame is a two-parameter phase diagram; and a discussion claim, that automated interestingness scores and human preference diverge. Seven hypotheses (H1 to H7), an ablation matrix, dictionary controls and nine figures follow. Section 7 names *Artificial Life* as the first-choice venue.

## 2. Verdict and realistic venue

As planned this is not a Nature paper, nor a Nature Physics paper. The core novelty (section 0, claim 1) is novelty of object: nobody has used a decompressor as a cellular-automaton rule. Nature publishes findings, not objects: what does a reader in a neighbouring field now know that they did not? Claim 2 as written is a design principle, not a measurement, and claim 3 is a pilot with six to ten viewers.

The one thread that could lift the work is H1, coarsening arrest: a local many-to-one map that pins domain growth at a scale set by the dictionary. If that scale can be predicted from a property of the decoder rather than merely measured, and the arrest is shown to be specific to decoding rather than generic to any contracting map, the result becomes a statement about pattern selection by codes and could be argued at Nature Communications. Without that prediction the ceiling is Scientific Reports, and the authors' own choice of *Artificial Life* is the better home for the paper the plan actually describes. Nature Computational Science would need a method others adopt; the harness is good practice, not a method.

## 3. The single biggest gap

There is no null model for the rewrite stage. Every hypothesis compares the decoder with its absence or with shuffled dictionaries; none compares it with a different many-to-one map of matched image size and contraction, for example a random hash truncated to k outputs, or a lookup table with the same fixed-point fraction. Until that control exists, the sceptical reading in section 10 ("a noisy majority-vote CA with a lookup table") is not answered, only denied. The plan's reply, that H1 and H4 separate the two, is circular: H4 measures the image, not that only a decoder's image does this.

## 4. Specific points

1. Section 1's table says "torus"; `docs/lattice.md` says a plane with edges and a bespoke edge-pairing rule. Read the table off the code first; boundaries matter for coarsening exponents and confound H1.
2. H1 expects Allen–Cahn t^1/2 growth. Per bit plane the swap stage conserves set bits (Kawasaki-like) while the median does not; the ablation (mixing on, settling on, rewriting off) is 128 independent noisy majority-vote models with mixed conserved and non-conserved dynamics. Derive the expected exponent, do not assume it. Check Spirin, Krapivsky and Redner (PRE 2001, zero-temperature Ising freezing into stripes; verify title), which the settle-only ablation may reproduce.
3. The noise is not annealed. Swap and median decisions hash the 32-bit context with salt 0, so identical contexts always decide identically and a flat boundary moves all-or-nothing. Any comparison to stochastic CA (thread B) needs a control salted by turn number.
4. The frame-as-phase-diagram (claim 2, Figure 2) is an illustration, not a measurement: regions at different p are spatially coupled and gradient power 0.2 makes the axis nonlinear. Produce the phase diagram (H5) from uniform-p runs; keep the gradient frame as Figure 1b.
5. H4 says the image is "thousands, not 2^128". The Brotli-like decoder has 8-bit literals, so this is not obvious; report the number and its scaling with dictionary length, and compute it analytically for the codebook decoder. This is the quantity the null model above must match.
6. To the dictionary controls (section 4) add a word-level shuffle, so that "alphabet", "words" and "position" are separated rather than only "alphabet" versus "everything else".
7. Prior art to settle before writing: Kauffman's random Boolean networks and Wuensche's basin-of-attraction programme (H4 is an attractor census); Zenil's compression-based classification of CA (Complex Systems 2010, verify); Agüera y Arcas et al. 2024 and Lenia and neural CA as planned. "To my knowledge" (section 0) cannot survive into a manuscript.
8. Cut H6 from the main claims. A six-to-ten-viewer pilot is anecdote under any Nature-family policy, and a human ranking task needs an ethics statement. One paragraph in the discussion at most.
9. The overclaiming risk is in the vocabulary: "genome", "self-decoding", "alive" in one title candidate, and the README's "artificial life". The plan's own rule, use "pattern formation", is right; apply it to the title and the repository's first line.
10. Searches ran at 64 and 128 cells, pictures were judged at 512 and 1024 (section 4). Do the scaling check before the figures.

## 5. Questions for the authors

1. Given a dictionary you have not yet run, can you predict its saturated domain length or regime count from properties of the decoder map (image size, contraction, fixed-point fraction)? If yes, that is the paper; if no, what would it take?
2. Does a random many-to-one map with the same image size as the reference decoder arrest coarsening at the same scale? If it does, what is left of claim 1?
3. Do you already have a number for the shuffled-dictionary control under the reference setting? Section 4 says the structure claim falls if it matches; I would want to know before the writing starts.
