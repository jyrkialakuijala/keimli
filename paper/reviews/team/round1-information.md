# Round 1: information theory and algorithmic information

Reviewer: information theorist (Shannon, Kolmogorov/LZ, CTM, Landauer/Bennett).

## 1. The project in my words

A 512² (formerly 256²) lattice of 128-bit cells. Each turn a hashed uniform crossover between neighbours, a per-bit-plane majority vote, then a total map f: {0,1}^128 → {0,1}^128 given by a Brotli-like decoder reading the cell as a command stream against a fixed dictionary. f is many-to-one, fixed-cost, loop-free. The claim is that f captures the "entropy reduction of running a program" without "computation", so whatever Core War-like phenomena it shows come from the first. The entropy budget (crossover in, vote out) is varied across the image as a built-in parameter sweep.

## 2. Strengths

- **The 93.5-bit bound is correct, and the argument is clean.** In `decode36.mjs` the stopping rule depends only on the bits read so far, so the read prefixes (capped at 128 distinct bits by the wrap) form a complete prefix code. Under uniform input, H(prefix) = E[min(c,128)] exactly, and H(f(U)) ≤ 93.5 (`results/decoder-map.md` §1). The same argument gives every x at least 2^(128−c(x)) preimages. Checking "0.00 % kept" was the right thing to do: if any output bytes were kept from the input, the bound would fail.
- **The controls are honest.** Shuffles separate the first-order and second-order effects of the dictionary (5.05 vs 5.30 bits conditional). PLAN_AMENDMENTS l.88–90 already concedes that mixing is a bijection and "raises no configuration entropy", and H5 was renamed "activity".
- **The attractor census (`ablation-main.md` §1) is the right object.** It is exact, it depends on the dictionary, and it measures the iterated map, which the H(f(U)) bound says nothing about.

## 3. Concerns, ranked

1. **The "local entropy pump" sentence contradicts the project's own amendment.** INTRODUCTION.md l.121–125 (draft PDF l.90–92) says the decoder "lowers the entropy of its own memory while, in a mixing medium, raising it around". The rewrite writes only its own cell, so it cannot raise entropy anywhere else. By data processing, a deterministic f cannot raise ensemble entropy. Under the default **quenched** hashing (METHODS l.60–66) the whole lattice is a deterministic CA, so the fine-grained entropy of the configuration over initial conditions is **non-increasing every turn, at every stage**. "Mixing raises entropy" and "entropy supply along one axis" (INTRODUCTION l.85, 95) are therefore true only of coarse-grained or marginal entropies, and the text never says which one it means. Only annealed salts inject entropy. No observable in `ablation.mjs` measures entropy "around" a cell.
2. **The lattice "entropy" is a zeroth-order pooled byte histogram** (`ablation.mjs` l.121: one histogram over all 16 byte positions in the bulk). It cannot tell a uniform field from a mosaic of domains that share the same byte alphabet. The earlier compression review (§2, recs 4–5) asked for block entropies and LZ76 on a Hilbert scan, plus snapshots after each stage. I grep'd `paper/experiments` and `tools`: none of these are implemented. Every entropy claim about the lattice therefore rests on an observable that cannot carry it.
3. **The output distribution is heavily skewed, and Shannon H hides this.** From the reported counts, 988,284 distinct outputs in 10⁶ samples for F implies at least 11,716 colliding pairs. That puts the collision (Rényi-2) entropy at **H₂ ≲ 25.3 bits**, against H ≤ 93.5. For the Declaration it is ≲ 30.5. A few outputs (long dictionary copies, short skeletons) carry a lot of probability mass, which is exactly the algorithmic-probability shape. Report H₂, H_∞ and the most probable outputs alongside H. Chao1 (2^28) is useless on a distribution this skewed. RELATED_WORK l.60 calls the bound "the measured version" of H(f(U)). It is an upper bound, not a measurement, and its tightness is unknown: equivalent distance codes, literal versus copy of the same byte, and case transforms all create collisions.
4. **"LZ rather than Kolmogorov" is the wrong analogy, and one citation points the other way.** LZ complexity is an *encoder-side* measure, the parse of a given string. It approximates entropy rate asymptotically, not the K of a 128-bit string. Keimli runs a *decoder* on random bits. That is Levin's coding theorem with a non-universal reference machine: P_f(y) = Σ 2^−|p| over the read prefixes p that decode to y, which is the construction behind Zenil's CTM. zenil2015 (references.bib l.164) argues that compression *fails* on short strings and proposes CTM instead, so citing it for "LZ is good enough" gets it backwards. chaitin2012 is an unverified popular book. The accurate sentence is: "the decoder fed random bits samples a resource-bounded algorithmic probability". That is a stronger claim and a more defensible one.
5. **The thermodynamic language is unaccounted for.** Landauer cost is logical irreversibility. On the attractor the decoder is a *permutation* of the cycle states (F: a 3-cycle) and erases nothing. Erasure happens only during transients, when the decoder absorbs the bits that mixing knocked off the cycle. The "pump" would then be a measurable rate: the bits of perturbation absorbed per turn, at most H(input | on-cycle). In the quenched regime this tends to zero once the system freezes. In the annealed regime it is set by the injected noise. Without this accounting, "pump" is a metaphor.
6. **The 93.5 bits applies only at turn 1.** After that, cells are far from uniform (byte H 1.5 bits, <3 % distinct). The bound should not appear in the introduction as a property of the dynamics (INTRODUCTION l.55–56).

## 4. Questions for the panel

- Statistical physicist: is a coarse-grained entropy plus an explicitly annealed noise source the right formal frame for the "entropy budget"? Would you accept "activity budget" throughout?
- ALife reviewer: do Core War and Tierra papers make any entropy claim that the decoder is meant to reproduce, or is "entropy reduction of running a program" new to this paper? If it is new, it needs a definition.
- Theory of computation: is "the decoder has no computation" consistent with my reading (a CTM machine of bounded depth)? Is iterating f (a cell's output is its next input) a loop by another name?
- Experimentalist: can stage-wise snapshots be added to `ablation.mjs` cheaply without disturbing the running batches?

## 5. What I will examine in the methodology round

- Exact or sharper bounds on H(f(U)): enumerate the skeletons for small V, and get a lower bound from the collision structure. Is 93.5 tight to within a few bits?
- A definition of the "pump" that can fail: conditional entropy of a cell given its 8-neighbourhood, and mutual information between neighbours, measured per stage, under quenched vs annealed hashing.
- LZ76 or Kaspar–Schuster complexity, and entropy density from block entropies, on frames from the gradient runs. Do the named "regimes" separate on these and not on byte H?
- Whether the output distribution under the decoder follows a coding-theorem shape (log P against the length of the shortest generating prefix). If it does, it would replace the LZ analogy with a measured result.
- The draft's wording, checked line by line against these definitions.

*What would change my mind on 1 and 5:* a stage-resolved measurement in which a neighbourhood entropy (conditional, block or LZ76) rises around rewritten cells while the per-cell entropy falls, under annealed noise and against the `cycle3` null.
