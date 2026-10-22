# Related work map and prior-art search log

## 0. The searches of 2026-10-21 and the chapter they give

Six searches, one per thread, each checking every citation against a
publisher, Crossref, arXiv, DBLP or library record. Annotated notes, one
file per thread, five lines a work with a suggested citing sentence:
`related/K.md` (classical dynamics of lattices and maps), `related/C.md`
(computational artificial life and replication), `related/E.md`
(information, complexity, entropy and computation), `related/D.md`
(discovery methods, continuous and neural automata, spatial parameter
maps), `related/P.md` (prior art and forward citations), `related/V.md`
(verification of the old entries; genotype–phenotype maps, simplicity
bias, cellular evolutionary algorithms). `references.bib` went from 68
entries (16 verified, 19 partly, 33 not) to 248 (218 verified, 30 partly
with the open field named in `note`, none unchecked). Every key cited in
the drafts resolves. The 2026 preprints the searches turned up after the
author's last reading (Knierim et al., Cicala et al., Jha et al., Kumar et
al. 2026, Jain et al., Norton, Hudcová et al.) were re-checked by
identifier against the arXiv API.

### 0.1 What the paper may claim, and what it may not

**Still new after the searches.** Nobody has used a decoder or decompressor
as the iterated local rule of a lattice. The forward citations of
Kaspar–Schuster 1987 (513 papers) and of Grammatical Evolution 1998 (844)
were scanned, as were arXiv and OpenAlex keyword searches. Also new: a
census of that rule's fixed points, cycles and basins; attractors
*constructed* into it by enumeration (the Gray-coded dictionaries: no
Lenia, neural-CA or evolved-rule work builds its attractors by
construction); and the finding that, under one decoder, the medium (mixing
and settling) and not the basin picks the winner.

**Not new: cite, and present Keimli as an instance or a test.**

| idea in the drafts | who had it | how to say it |
|---|---|---|
| a many-to-one rule organises the lattice by losing entropy | Wolfram 1983 [wolfram1983]; Landauer, Bennett [landauer1961, bennett1973, bennett1982] | Keimli isolates that mechanism in a program-like substrate; it does not discover it |
| local map on every cell plus neighbour coupling; frozen patterns; the coupling picks the pattern | Kaneko's coupled map lattices [kaneko1984, kaneko1989, kaneko1992], Bunimovich–Sinai [bunimovich1988] | Keimli is a discrete coupled map lattice whose local map is a decoder; "deterministic freezing" is Kaneko's frozen random pattern and the zero-temperature freezing of majority dynamics [spirin2001, derrida1996, olejarz2013] |
| census of the attractors and basins of a many-to-one map | Kauffman [kauffman1969, kauffman1993], Wuensche–Lesser [wuensche1992]; Garden of Eden theory [moore1962, myhill1963, hedlund1969, kari2005]; random mappings [flajolet1990] | the method is theirs; the map is ours; Flajolet–Odlyzko is the null model, and step budgets must be reported [rispoli2026] |
| replicators are fixed points or short cycles | Langton's trivial replication [langton1984, vonneumann1966]; quines as fixed points [sarkar2020]; AlChemy's copy functions as default attractors [fontana1994, fontana1994b] | say "trivial replication" and cite; Keimli's contribution is the census and the construction |
| BFF replicators need no computation to appear | Knierim, Versari, Obryk, Agüera y Arcas 2026 [knierim2026]: mutation random walks with no interaction find them as fast as the soup, biased sampling up to 25× faster; their detector is a fixed-point or 2-cycle test | the closest and newest support; Keimli is the same argument with a substrate whose map can be read |
| decoder fixed points exist | decompression quines and looping archives [cox2010, canet2017, vanmello2024]; iterated codec with a census of survivors: Conway's audioactive decay [conway1987] | claim the dynamics and the lattice, not the existence |
| a many-to-one map favours simple, repetitive outputs; the big basin wins | simplicity bias [dingle2018, dingle2020, johnston2022, dingle2024, hamzi2024]; arrival of the frequent [schaper2014]; coding-theorem method [soler2014, zenil2019] | Keimli's "the medium, not the basin, picks the winner" is the contrast to Schaper–Louis, and the most citable lattice result |
| cycle domains compete, spiral, fix or melt under mixing | cyclic CA [fisch1991, fisch1991b], excitable media [greenberg1978], rock–paper–scissors with mobility [reichenbach2007, frachebourg1996, szolnoki2014] | confirmation, not discovery; Reichenbach's mobility threshold is a prediction to test against the mixing gradient |
| a parameter sweep laid out across one frame | Munafo's PDE4 runs one Gray–Scott simulation with F and k varying across the grid [munafo2024]; Pearson's map [pearson1993]; Sims' style map [sims2013] | not new; the new part is the measurement that the frame and the uniform runs pick different winners, which physics predicts: an ordered state chosen at a front spreads into neighbouring regions [dziarmaga1999, zurek2008], and walls pin on weakly coupled or uneven lattices [keener1987, erneux1993, lober2012] |
| neighbours trading bits on 2 × 2 blocks | partitioning (Margolus) automata [margolus1984, toffoli1987]; non-uniform CA [sipper1997]; per-cell rules with transfer between neighbours [medernach2013] | one sentence in methods |
| a processor on every cell of a grid | Computational Life's 2D variants [agueraYarcas2024]: 240 × 135 grid, partner within Chebyshev distance 2, run concatenated; Z80 with 16-byte cells and 256 steps | Keimli's processor arm generalises it to 25 instruction sets with the mixing and settling stages |

**Close in spirit, to be differentiated in one sentence each:**
- Neural cellular automata used as image codecs [falcao2025] put the
  decoder in the reverse role: the CA decodes, rather than the decoder
  being the CA.
- The biomorphs study [martin2024] finds that bias in arrival beats
  selection, but in a designed decoder with no lattice.
- The Avida replicator census [nitash2017] finds winners not set by
  abundance, but for one genome length.
- Fortuna et al.'s genotype–phenotype census of Avida [fortuna2017] treats
  an interpreter as a genotype–phenotype map.
- Expect reviewers from the assembly-theory debate
  [sharma2023, abrahao2024, ozelim2026], since the last of these equates
  the assembly index with dictionary compression.

### 0.2 The chapter, paragraph by paragraph

1. **Programs as matter.** Core War and its evolution [dewdney1984,
   corno2004, kumar2026], Coreworld [rasmussen1990], Tierra [ray1991],
   Avida [adami1994, ofria2004, lenski2003, wilke2001], AlChemy
   [fontana1994, fontana1994b], Amoeba [pargellis2001], Squirm3
   [hutton2002], the Movable Feast Machine [ackley2011], and Computational
   Life with its 2026 follow-ups [agueraYarcas2024, knierim2026,
   cicala2026, jha2026]. The two follow-ups on Z80 soups only get rich
   behaviour once tasks or energy are coupled in, which fits the
   two-source thesis. The author co-wrote agueraYarcas2024; say so in a
   footnote.
2. **What counts as replication.** von Neumann, Langton's trivial versus
   non-trivial [vonneumann1966, langton1984], Sipper's survey [sipper1998],
   the graded measure [adams2009], limited and unlimited heredity
   [maynardsmith1995], Eigen's error threshold [eigen1971], evoloops 25
   years on [sayama2025], self-replicating neural CA [jain2026]. This is
   where Keimli's replicators are named trivial, with limited heredity.
3. **Rules on lattices, and what they compute.** Wolfram's classes and
   statistical mechanics [wolfram1983, wolfram1984], universality of Life
   and rule 110 [berlekamp1982, cook2004], the edge of chaos and its
   critique [langton1990, packard1988, mitchell1993], computational
   mechanics and coherent structures [crutchfield1993, shalizi2006].
   Necessary because the drafts' "rules compute nothing" is false.
4. **Maps, attractors and coupling.** Kauffman, Wuensche–Lesser, Garden of
   Eden, random mappings; Kaneko's coupled map lattices; partitioning
   automata. This is where Keimli is placed structurally.
5. **Ordering, freezing and domain competition.** Voting rules and
   majority models [vichniac1984, oliveira1992, toom1980, gacs2001],
   voter model [holley1975, liggett1985, dornic2001], coarsening
   [bray1994, krapivsky2010], freezing [spirin2001, derrida1996], cyclic
   and rock–paper–scissors domains [fisch1991, reichenbach2007], pinning
   by spatial heterogeneity [keener1987, dziarmaga1999]. The settling
   stage and the medium results sit here.
6. **Compression, algorithmic information and the practical proxy.**
   Kolmogorov, Solomonoff, Chaitin, Levin [kolmogorov1965,
   solomonoff1964, chaitin1966, levin1974]; Lempel–Ziv complexity
   [lempel1976] as the measure science actually uses [kaspar1987,
   casali2013, schartner2015, estevezrams2015]; the coding-theorem method
   and simplicity bias [soler2014, zenil2019, dingle2018]; LZ77 and Brotli
   [ziv1977, rfc7932, alakuijala2019]. The thesis analogy (LZ for
   Kolmogorov, decoder for CPU) goes here with the right citations.
7. **Entropy, erasure and computation.** Landauer, Bennett on
   reversibility and logical depth, Fredkin–Toffoli conservative logic
   [fredkin1982], Zurek [zurek1989], Wolpert's review [wolpert2019];
   Lizier's information dynamics [lizier2008, lizier2010, lizier2012],
   which splits computation into storage, transfer and modification. The
   two sources of the thesis become measurable here.
8. **Searching and designing rule spaces.** Rule-space surveys
   [packard1985, eppstein2010, sapin2004]; Lenia and its search methods
   [chan2019, chan2020, chan2023, plantec2025, reinke2020, etcheverry2020,
   hamon2025, faldor2024, kumar2025, hudcova2026]; quality-diversity
   search [lehman2011, mouret2015, pugh2016]; neural CA and isotropy
   [mordvintsev2020, mordvintsev2022iso]. Present the swarm search
   honestly as a single score plus selection by eye; the constructed
   dictionaries are what this literature lacks.
9. **Decoders as genotype–phenotype maps.** Grammatical Evolution
   [ryan1998, oneill2001], neutral networks [schuster1994, huynen1996,
   fontana1998, manrubia2021], robustness [wagner2005], genotype–phenotype
   bias [ahnert2017, greenbury2016]. This supplies the vocabulary for the
   unread bits and the transition graph between attractors.
10. **Prior art on codecs and automata.** Compression by automata
    [haukeli2012, macura2006, albury2019], compression as a measure of
    automata [kaspar1987, zenil2010, cisneros2019], decompression quines
    [cox2010, canet2017], audioactive decay [conway1987], neural CA
    codecs [falcao2025]. Close the chapter with the one-sentence novelty
    statement.

### 0.3 Corrections the drafts need (citations only)

- `INTRODUCTION.md` l.71, `MOTIVATION.md` l.58 and
  `INTRODUCTION_MOTIVATION.md` l.98 cite [zenil2015, chaitin2012] for "LZ
  is a good-enough proxy". zenil2015 argues the opposite: compressors are
  unreliable on short strings, so use the coding-theorem method. Replace
  with [lempel1976, kaspar1987, casali2013] for the practice, and
  [levin1974, soler2014, zenil2019] for the decoder side. chaitin2012 is
  a popular book; drop it from that sentence.
- Cite Lempel–Ziv 1976 for LZ complexity, not LZ77.
- Fixed in the bibliography: albury2018 is albury2019 (three authors,
  FLAIRS-32); Haukeli's first name is Martin; Macura 2006 does report a
  result (94.8 % average ratio); cisneros2019 is a peer-reviewed IEEE SSCI
  paper; plantec2023 is the ALIFE paper, and the journal version is
  plantec2025; gacs1978 is pages 92–96.

### 0.4 Measurements the literature hands us

Each is a day or less and would turn a claim of the thesis into a number:
- Dingle's plot: output probability against the output's LZ complexity,
  for the decoder fed random cells.
- Lizier's storage, transfer and modification for the decoder lattice
  against a processor lattice at the same mixing and settling.
- Image size and cyclic points of the decoder against Flajolet–Odlyzko's
  random-mapping values.
- Reichenbach's mobility threshold for the designed cycle domains, read
  off the mixing gradient.
- Collision entropy, min-entropy and LZ density [renyi1961,
  estevezrams2015] as the lattice observables, as the panel asked.

### 0.5 Still open

- Google Scholar forward citations; the searches were throttled and used
  OpenAlex and Semantic Scholar instead.
- The forward citations of O'Neill–Ryan 2001; Semantic Scholar was rate-limited.
- The full text of ALIFE 2026, for any spatial decoder lattice.
- Thirty bibliography entries still have one field open; each names it in
  `note`.
- No PDF has yet been read in full for the five-line summaries. The notes
  in `related/` are from abstracts, records and, for agueraYarcas2024 and
  knierim2026, the arXiv HTML.

---

The map below is the first search, of 2026-10-19.

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
