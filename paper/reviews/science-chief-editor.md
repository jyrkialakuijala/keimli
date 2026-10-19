# Assessment of the Keimli research plan

Editor-in-chief, Science, on paper/RESEARCH_PLAN.md (commit 3241330).

## 1. What the plan is actually claiming

Stripped of "self-decoding" and "the genome is a text", section 0's claim 1
says this: a lattice of 128-bit sites is driven by a stochastic bit-plane
majority vote (a voting CA), a bit-conserving uniform crossover with
neighbours (a noise source), and a deterministic per-site map applied to each
cell in isolation. That map happens to be an LZ/Brotli-style decoder
parametrised by a few kilobytes of bytes. The claim is that a many-to-one
per-site map arrests the coarsening the voting rule would otherwise produce,
and that the map's parameter string shapes the patterns. Claim 2 is its bookkeeping. Claim 3 is that a score the authors wrote
disagrees with the authors' eye. Structurally this is a coupled map lattice
with a discrete map and a voting coupling.

## 2. Significance

Who outside artificial life would care? Statistical physicists, if H1 yields
a law: a saturation length set by a measurable property of the map that
holds across decoders and that a random map of matched image size does not
reproduce. Evolutionary-computation people, for the degeneracy in H4. Nobody
else: the plan disclaims replication, selection and open-endedness (sections
3C and 10), so the biological hook that has put ALife in general journals
(Lenski et al. 2003) is absent by design. For Science to care, one of three things would have to
be true: (a) decoding-as-rule produces a phenomenon that voting CAs, coupled
map lattices and Lenia-type systems demonstrably do not, shown against those
controls; (b) the dictionary-to-pattern map yields a general statement about
robustness and evolvability of compressed genotypes that transfers to real
genotype-phenotype maps; or (c) the search finds something open-ended. None
is in the plan. The right home is Artificial Life (MIT Press) or the ALIFE
conference, as section 7 itself concludes; Physica D or Chaos if H1 becomes
a scaling result.

## 3. Rigour audit, H1 to H7

H1. Falsifiable in principle, under-controlled in practice. First, the
reference system runs both parameters as spatial gradients (section 1), so no
condition in the ablation matrix (section 4) has uniform p; an exponent read
off strips of a gradient is contaminated by neighbours at other p and by the
grid-dependent gradient resolution.
Second, t^1/2 is Allen–Cahn for a non-conserved order parameter; the
crossover conserves set bits (docs/lattice.md), and zero-temperature majority
dynamics on a square lattice often freezes into stripe states (Spirin,
Krapivsky and Redner 2001; verify), so the control may never coarsen cleanly.
Third and decisive: "a scale set by the dictionary" has no control for the
alternative that any many-to-one per-site map of comparable image size
arrests coarsening. Without a random-map control the decompressor is not
shown to matter, only a contractive local map, which coupled-map-lattice
work established long ago (Kaneko, Physica D 1989; verify).

H2. Falsifiable, but the response variable is the hand-made regime
classifier that section 4 admits is inadequate. Until the objective measure
exists, H2 measures the classifier's sensitivity, not the dynamics'.

H3. Circular as written. The searched dictionaries were selected by
maximising regime count; reporting that they out-score texts on regime count
restates the selection. The shuffled controls test whether byte order matters, a different
question. A fair test needs an
independent measure never used in the search, or a matched search over texts
(splice and recase real texts under the same budget and objective). Length
and alphabet are also confounded: texts run 88 to 8,123 bytes, the searched
ones 4,400.

H4. Measurable, but say how image size is estimated from 10^6 samples
(collision counting, not a distinct count). And the hypothesis is near-true
by construction: the output is a
concatenation of dictionary copies under a 12-bit window header, so the image
is bounded by substrings of a 4,400-byte string. State the combinatorial
bound first; the interesting number is the gap.

H5. Not a hypothesis. At a stationary state the per-stage changes balance by
definition, and "moves predictably with p" is unfalsifiable without a
written prediction. Derive one or demote H5 to a figure.

H6. Six to ten viewers cannot support "no, not monotonically"; a null at that
n is noise. The human who picked the default (section 0) is an author;
viewers must be independent and blind.

H7. The real hypothesis is hidden. XOR and bit rotation commute with the
per-plane median and the bitwise crossover; adding a constant mod 95 does
not. Copying is value-blind, so invariance under the non-symmetric
transforms would show that the decoder, not the bitwise stages, sets the
structure. Phrase H7 as that contrast.

## 4. Changes required before the work starts

1. Add uniform-parameter runs: a grid of fixed (p_mix, p_settle) values, 10
   seeds each, for every quantitative claim. Gradient frames stay as
   illustrations.
2. Add a random per-site map control with matched image size and matched d1
   contribution, plus a mutation-only control at the matched rate. Claim 1
   stands or falls on this.
3. Resolve the topology: section 1 says torus; docs/lattice.md says plane
   with edges.
4. Fix an independent measure (local statistical complexity after Shalizi et
   al. 2006, or a clustering frozen before the experiments) and commit in
   writing that H2, H3 and H7 are scored by it.
5. Redesign H3 as a matched-search comparison, or drop "different in kind".
6. Rewrite H5 with a prediction, or demote it.
7. Rewrite H7 as the symmetry test above, with noise from seed variance.
8. Add coupled map lattices and zero-temperature freezing to section 3; the
   section 10 answer to "lookup table" is a quibble.
9. Pre-register in paper/ before week 2: seeds, measures, the decision rule
   for each H, and what would make the authors retract each claim.
10. Run the human pilot with independent, blinded viewers, or label it
    anecdote.

## 5. Decision letter

The plan describes careful, reproducible work on an original substrate, but
as designed it tests whether a contractive per-site map arrests voting-rule
coarsening, a question without broad scientific interest, and its central
comparisons are not yet controlled against the obvious alternatives.
We would not consider the resulting manuscript for Science; we encourage
submission to Artificial Life, or to Physica D if H1 becomes a quantitative
scaling result that survives the random-map control.
