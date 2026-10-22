# Brief for the journal editors (read first)

Project: **Keimli** (author Jyrki Alakuijala, single author so far; co-designer of Brotli; co-author of Agüera y Arcas et al.
2024 "Computational Life", arXiv 2406.19108). Everything is in /home/jyrki/life (READ ONLY for you, except your own output file).

## What it is
A 2D lattice of 128-bit cells, rewritten every turn by three stages:
1. mixing: neighbours trade bits, probability varying across the image;
2. settling: per-bit-plane majority smoothing, strength varying across the image;
3. rewriting: each cell's bits are decoded once as a Brotli-like (LZ77 + static dictionary) stream and the decoded
   bytes replace the cell; alternatives are 25 emulated CPUs (Z80, 6502, VAX, RISC-V, Redcode...), other decoders,
   arithmetic transforms (look-and-say in bases 2–16, elementary CA rules on the cell's bit ring).
The gradient frame shows a parameter sweep in one image. It runs in the browser (WebAssembly); the page is the artifact.

## The thesis (author's framing)
Computational artificial life (Core War, Tierra, Avida, BFF) mixes two sources of rich phenomena: the entropy reduction a
running program does to its memory, and the finesse of computation itself. A decompressive automaton has the first and
not the second, is linear-time and analysable (LZ complexity as a tractable stand-in for Kolmogorov complexity), and so
helps separate which phenomena come from which.

## Results so far (see paper/results/*.md, paper/RESULTS_REPLICATORS.md)
- Census of the decoder map: image, fixed points, cycles, basins; collision entropy 16.5 bits and min-entropy 8.3 bits
  after one step for the default dictionary; at least 48 fixed points found by exact search.
- Dictionaries **constructed** by enumeration to have prescribed Gray-coded cycles (3–32 "species").
- "Replicators" are fixed points / short cycles of the local map (trivial replication in Langton 1984's sense).
- Replicator Monte Carlo: every major species is present from its first detectable turn; what is late is takeover; the
  **medium (mixing/settling), not the basin size, picks the winner** (fixed points win under strong settling, the
  large-basin cycle under uniform settling).
- Deterministic freezing; the Gray designs behave like three coupled Ising fields.
- New today (results/entropy-manipulators.md): calibration with elementary rules of exactly known loss (rule 90 on a
  128-bit ring loses exactly 2 bits/turn); collision entropy tracks it exactly, Wolfram-style block entropy is blind;
  the decoder loses ~110 bits in one step; a Z80 running 256 instructions hardly loses any → the decoder's structure is
  accounted for by erasure, the processor's is not.
- Look-and-say truncated to 128 bits: loses ~half the information per step (read fraction 2(1−1/b) predicted and
  measured), collapses onto Conway's 3-cycle prefix in ~12 turns; unbounded look-and-say is lossless while LZ-type
  compressors see its information density go to zero.

## Known weaknesses (paper/reviews/team/SYNTHESIS.md — a 7-person internal panel; read it)
Many draft claims must be dropped or reworded; code/data defects (fixed swap order in older scripts, censored medians,
period detector limits, no provenance, biased correlation length); the "computation vs entropy" thesis needs a second
paper (CPU dose–response over instruction budgets, BFF census). Panel verdict: a narrower "map paper" is publishable now.

## Related work and novelty (paper/RELATED_WORK.md §0, paper/related/*.md)
Nobody has used a decoder as the iterated local rule of a lattice. But: Wolfram 1983 (entropy loss organises CAs),
Kaneko coupled map lattices (architecture, frozen patterns), Kauffman/Wuensche (basin censuses), Dingle 2018 simplicity
bias, Schaper–Louis 2014 arrival of the frequent, decompression quines, Munafo's one-simulation parameter gradient,
Knierim et al. 2026 (BFF replicators found by random walks without interaction).

## Files
Drafts: paper/INTRODUCTION.md, METHODS.md, RESULTS_REPLICATORS.md, MOTIVATION.md; assembled PDF
paper/draft/keimli-draft.pdf (HTML beside it); figures paper/figures/; results index paper/results/README.md;
docs/ (lattice.md, changers.md) describe the system; references.bib (248 entries).
