# Related work map and prior-art search log

2026-10-19. The plan (section 3) asked for a bibliography with a `verified`
flag per entry and a one-page map before any writing. `references.bib`
holds 68 entries: 16 verified against a publisher, repository or arXiv
record, 19 partly (the fields still to check are in each entry's `note`),
33 written from memory and flagged `verified = {no}`. The checks were
web searches of 2026-10-19; the sources are listed at the end. No PDF has
been read yet: the five-line summaries the plan asks for (what they did,
measured, claimed, how it relates, exact citation) are still to write.

## 1. The prior-art question: has a codec been used as a lattice rule?

Searched under: cellular automaton with an LZ77 / Lempel–Ziv decompressor
or decoder as update rule; dictionary coding or compression with
artificial life, self-decoding and quine automata; lossless compression as
a dynamical system decompressing every cell every step; interestingness
measures for automata; majority-vote coarsening with quenched disorder.

**Nothing found that uses a decoder as the update rule of a lattice.** The
nearest neighbours, all different in kind:

- Compression *by* automata: Haukeli 2012 (run a 2D automaton backwards so
  a smaller earlier configuration plus a step count stands for the data),
  Macura 2006 (data as rule plus initial condition), Albury (a CA mask
  XOR-ed before a standard compressor), and two US patents of the same
  family. The automaton is the compressor; the data is not the automaton.
- Compression as a *measure* of automata: Kaspar and Schuster 1987
  (Lempel–Ziv complexity of space-time patterns), Cisneros et al. 2019
  (compression-based and learned complexity for evolving structures),
  Ahmed's Bangor thesis (PPM code-length series), the Springer 2019
  elementary-CA clustering paper, Liao 2021 (networks detecting interesting
  rules). These measure patterns from outside; they do not run a codec
  inside the rule.
- Decoding a genome through a table with wrap-around: Grammatical
  Evolution (Ryan, Collins, O'Neill 1998; O'Neill and Ryan 2001). This is
  the closest construction (a bit string read as codons modulo a grammar),
  but it is a genotype-to-phenotype map used once per individual in an
  evolutionary search, not an iterated local rule, and nothing is spatial.
- Programs as matter: Core War, Tierra, Avida, Amoeba, Squirm3, the
  Movable Feast Machine, Computational Life (Agüera y Arcas et al. 2024).
  Each has replication and selection; Keimli has neither, which the paper
  must say on the first page.

So claim 1 ("a decompressor as the rewriting stage of a lattice") stands
as far as the first search goes. Two further searches are owed before
submission: forward citations of Kaspar–Schuster 1987 and of Grammatical
Evolution in Google Scholar and Semantic Scholar, and the keyword set
"self-decoding", "LZ77 cellular automaton", "quine cellular automaton"
in those two engines rather than the general web.

## 2. What each thread gives the paper

| thread | what we take from it | the paper's sentence |
|---|---|---|
| A. edge of chaos, classification | λ and Z as knobs through rule space; input-entropy variance and local statistical complexity (Shalizi et al. 2006) as objective regime detectors; the Mitchell–Hraber–Crutchfield critique as the warning against reading a phase diagram into a parameter sweep | our dictionary is the knob; our block-regime count is a Wuensche-style classifier and should be replaced by Shalizi's filter before any "phase diagram" is claimed |
| B. voting automata, coarsening | Vichniac's voting rules; Oliveira's majority-vote model (Ising class); Bray's phase-ordering review for the t^⅓ law; Sicilia et al. 2008 for weak-disorder pinning; Toom and Gács for noise-resisting majority; the GKL density task | the per-plane median is a majority rule; the annealed two-stage control coarsens as Allen–Cahn; the quenched hashing is a weak disorder that pins (H1 retracted, results/ablation-main.md) |
| C. program substrates | Core War (we emulate Redcode), Tierra, Avida, Amoeba, Squirm3, Movable Feast Machine, Computational Life | the systems a referee will name; the difference is no replication and no selection |
| D. continuous automata, interestingness | Lenia and Flow-Lenia; IMGEP (Reinke et al. 2020) as the method our swarm search approximates by hand; novelty search, MAP-Elites, quality diversity; Schmidhuber's compression progress | the dictionary searches are a quality-diversity search over rule strings and must be positioned as one; "compression progress" fits a system whose rule is a compressor |
| E. compression, algorithmic information | LZ77, the Brotli RFC and paper; Kaspar–Schuster; the coding theorem method (Zenil et al.); compression distance (Cilibrasi–Vitányi); Chaitin, Walker–Davies | what decoding does to information: a fixed many-to-one map onto the decodable strings; H(f(U)) ≤ 93.5 bits (results/decoder-map.md) is the measured version |
| F. decoding genomes | Grammatical Evolution; RNA neutral networks; Wagner on robustness; indirect encodings | the vocabulary for the attractor census and the Gray-coded designs: neutrality (the 82 unread bits), robustness (return after one flipped bit), the many-to-one map |
| G. recombination on lattices | Syswerda; Spears–De Jong parameterised uniform crossover (our 2p(1−p)); cellular GAs | the mixing stage is a cellular GA without fitness |
| H. colour | Glasbey et al. 2007 for the palette; Tukey's median | one paragraph in methods |

## 3. What is still to do

1. Check the 33 unverified entries and the open fields of the 19 partly
   verified ones against the publisher or arXiv records (an afternoon).
2. Pull the PDFs of the twelve papers the text will lean on (Langton 1990,
   Mitchell et al. 1993, Shalizi et al. 2006, Vichniac 1984, Bray 1994,
   Sicilia et al. 2008, Reinke et al. 2020, Kaspar–Schuster 1987, Ryan et
   al. 1998, Spears–De Jong 1991, Agüera y Arcas et al. 2024, Alakuijala
   et al. 2019) and write the five lines for each.
3. The two forward-citation searches of section 1.
4. Decide whether Shalizi's local statistical complexity replaces the
   block-regime classifier before the phase-diagram figure is drawn.

## Sources of the checks (2026-10-19)

arXiv records: adap-org/9303003 (Mitchell et al. 1993), nlin/0508001
(Shalizi et al.), math/0003117 (Gács), cond-mat/9501089 (Bray),
1908.06663 (Reinke et al.), 1812.05433 (Chan), 2212.07906 (Flow-Lenia),
2406.19108 (Computational Life), 0812.4360 (Schmidhuber), 1911.01086
(Cisneros), 0711.3848 (Sicilia et al.). Publisher and repository records:
Physical Review A 36, 842 (Kaspar–Schuster, APS); Physical Review Letters
53, 311 (Domany–Kinzel); Journal of Statistical Physics 66, 273
(Oliveira, DOI 10.1007/BF01060069); Physica D 69, 279 (Crutchfield–Hanson,
UC Davis CMG page); Physica D 10, 96 (Vichniac, Computer History Museum
scan); Complexity 4(3) 47 (Wuensche, Sussex page); Complex Systems 28(3)
251 (Chan, journal page); Artificial Life 7(3) 225 (Dittrich et al.), 8(4)
341 (Hutton, DBLP), 15(1) 105 (Sayama); Color Research & Application
32(4) 304 (Glasbey et al., Strathclyde repository, DOI 10.1002/col.20327);
ACM TOIS 37(1), DOI 10.1145/3231935 (Brotli); LNCS 1391, 83 (Ryan et al.,
GP bibliography, DOI 10.1007/BFb0055930); USENIX HotOS XIII (Ackley and
Cannon); UC Berkeley EECS-2021-150 (Liao). Secondary only: Langton 1990
pages 12–37 (one database), Spears–De Jong 1991 (R package and Springer
reference lists), Pargellis 2001 (Bell Labs listing), Mitchell et al. 1996
(UC Davis listing).
