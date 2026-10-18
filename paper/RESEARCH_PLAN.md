# Research plan: an article on Keimli, a self-decoding cellular automaton

Written 2026-10-18 against commit 3241330 of the repository. This is the plan a
senior author writes before a line of the article exists: what the claim is,
what the object is, what must be read, what must be measured, and what the
referee will say. It is meant to be argued with and then followed.

## 0. The one decision to make first

An article lives or dies on a single claim that a reader can repeat in one
sentence. Everything in the repository is interesting to us; only some of it
is a result. The candidate claims, in the order I would rank them:

1. **A lattice whose update rule is a decompressor produces sustained,
   spatially organised dynamics, and the "genome" of such a rule is a text.**
   Each cell holds 128 bits; each turn the bits are read as a compressed
   stream and the cell is replaced by what they decode to. The dictionary the
   decoder copies from is a few kilobytes of bytes, so the whole rule space is
   indexed by strings, and strings can be searched, spliced, recased and
   transformed. This is the novel object. Nobody, to my knowledge, has used a
   general-purpose decompressor (LZ77, Brotli-like) as the local rule of a
   cellular automaton and studied what dictionaries do to the dynamics.
2. **Three stages with opposite effects on entropy balance into persistent
   structure.** Neighbour crossover (uniform crossover at rate 2p(1−p)) raises
   entropy; a per-bit-plane median over the 8-neighbourhood lowers it; the
   decoder lowers it in a different way, collapsing arbitrary bit strings onto
   the decoder's image. Because the page runs the mixing strength as a
   left-to-right gradient and the settling strength as a top-to-bottom
   gradient, **every frame is a two-parameter phase diagram**: granular at the
   top, domains at the bottom, the interesting fronts in between. This should be
   stated as a design principle and exploited in the figures.
3. **Automated "interestingness" scores and human preference diverge in a
   measurable way, and whole-alphabet transforms of a dictionary move its
   structure to new pictures.** Our own experience in the dictionary searches:
   the modes score climbed from 21 to 47 on one lineage that the eye reads as
   one picture, while the picture a human picked as the default scored 14.
   This is a smaller result but an honest and publishable one, and it connects
   to the quality-diversity and intrinsic-motivation literatures.

Claim 1 is the paper. Claim 2 is its mechanism section. Claim 3 is its
discussion, or a short second paper. I would not lead with the CPU link
machines, Redcode, Brainfuck or the sorts: they are the breadth of the
platform, worth a paragraph and a table, but each would need its own study to
support any claim. Decide this before gathering anything.

Working title candidates:

- *Self-decoding cellular automata: a lattice whose rule is a decompressor*
- *Text as rule: cellular automata driven by dictionary decompression*
- *Decompressive cellular automata and the dictionaries that keep them alive*

Terminology to fix now and never vary: **cell** (128 bits), **turn** (one
update of the whole lattice), **stage** (mixing, settling, rewriting),
**dictionary** (the byte string the decoder copies from), **self-decoding**
(the cell is both the compressed message and the output). Use "pattern
formation" and "sustained dynamics", not "life", in every claim sentence.

## 1. The object, pinned down

The article must describe exactly one configuration as the reference system
and treat everything else as variations. From the current defaults:

| Element | Reference setting | Source of truth |
| --- | --- | --- |
| Lattice | 1024 × 1024 cells, torus, one turn per frame | `src/lattice/` |
| Cell | 128 bits, rendered as the mean palette colour of its 16 bytes | `src/render/render.wat`, `src/changers/codec.js` |
| Mixing | 4 swap phases per turn, uniform crossover with each neighbour at rate 2p(1−p), p a left-to-right gradient 0 → 1, gradient power 0.2 | `docs/lattice.md` |
| Settling | 3 passes of a per-bit-plane median over the 8-neighbourhood (9 votes), p a top-to-bottom gradient 0 → 1 | `docs/lattice.md` |
| Rewriting | Brotli-like insert-and-copy decoder, 6 skipped bits, 12-bit header selecting a dictionary window, offset 0, longest copy 3, each cell on its own | `src/changers/codecs.wat`, `docs/changers.md` |
| Dictionary | Swarm search F, 4,400 bytes | `src/changers/dict/ca-swarm-f.txt` |
| Start | uniformly random bits | page |
| Mutation | 0 | page |

Every number in that table has to be read off the code once more before the
methods section is written; the plan is not the source. The methods section
also needs the decoder specified to the bit: command format, the ring of last
distances, the dictionary window selection, the word transforms, what happens
when the stream runs out, and how the 16 output bytes are written back. The
inspector already prints all of this for one cell; the text should be derived
from the same code paths and checked against the inspector on three cells.

What the platform additionally contains, for one table and no claims: 25
emulated CPUs as rewriting rules (including Redcode, Alpha, PA-RISC), Brainfuck,
ten decoders (LZ, Brotli-like, VP8 boolean decoder, codebooks), sorts and
transforms, cell pairs with four interleavings, link machines that run code
across neighbouring cells, and the 256-colour maximin palette tuned to the
dictionaries. Each is one sentence and a pointer to the repository.

## 2. Research questions and the hypotheses that answer them

Phrase every question so that an experiment can say no.

**Q1. Does the decoder stage, and not the median alone, produce the sustained
structure?**
H1: with mixing and settling on and rewriting off, the lattice coarsens into
ever larger domains (Ising-like, domain length growing roughly as t^1/2) and
goes quiet; with rewriting on, the domain size saturates at a scale set by the
dictionary and the fraction of bits changing per turn stays bounded away from
zero. Measure: domain-length distribution and the change fraction d1 against
turn, for the three single-stage and three two-stage ablations.

**Q2. How much of the dictionary matters, and which part?**
H2: the first few hundred bytes decide the settled phase (the splices of
Brotli 1 into Brotli 9 showed bytes 137 to 549 doing the work; the default
window ends at 1,285). Measure: splice families, and a positional sensitivity
map (mutate a 32-byte block, score the change in the regime histogram).

**Q3. Are searched dictionaries different in kind from texts?**
H3: real texts (the Declaration, Han, Arabic, Hangul samples in the manifest)
give one or two regimes; searched dictionaries give many, and they do it with
small alphabets, long runs and a few "words" that the decoder's copy codes can
reach. Measure: regime count and byte entropy for every dictionary in the
manifest under the reference setting, with shuffled-byte and
histogram-matched random controls for each.

**Q4. What does the decoder do as a map on bit strings?**
H4: the decoder is strongly many-to-one; the number of distinct 128-bit
outputs reachable from random inputs is small (thousands, not 2^128) and
depends on the dictionary's distinct byte count and the header width.
Measure: image size by sampling, fixed-point fraction, cycle census with the
existing attractor tools (`tools/ca-search.mjs`), for codebook and Brotli-like
decoders. This is where the entropy accounting of claim 2 becomes numbers.

**Q5. How is the entropy budget split per turn?**
H5: at the steady state, bits moved by mixing, bits changed by the median and
bits changed by rewriting balance, and the balance point moves predictably
with p. The page already reports all three; log them along the two gradients
and plot the phase diagram that each frame implicitly is.

**Q6. Do the automatic scores track human preference?**
H6: no, not monotonically. The modes score (effective number of block regimes
over space and time) rewards fine churn the eye merges into texture. Measure:
rank the six swarm results and the fifteen Brotli results by each score; ask
a handful of viewers to rank the same images; report rank correlations. Keep
this modest: a few viewers is a pilot, not a user study.

**Q7. Do whole-alphabet transforms preserve structure while changing the
picture?**
H7: a bijection on the printable alphabet (add a constant mod 95, multiply by
a unit, XOR a bit, rotate) keeps the regime count within noise and moves the
colours and the copy codes; the parentheses dictionary F is the existence
proof. Measure: transform each of ten dictionaries by each operator, compare
regime histograms before and after.

Anything not on this list is not in the article.

## 3. The prior science to gather

The reading has to be done before the introduction, because the introduction
is where the referee checks whether we know the field. Organise it by thread.
For each paper: pull the PDF, write five lines (what they did, what they
measured, what they claimed, how it relates, exact citation), and flag any
detail below that was quoted from memory and must be verified against the
paper itself before it is cited.

**A. Cellular automata as pattern generators and the "edge of chaos".**
Wolfram's 1984 classification (Physica D) and the 2002 book; Langton 1990
"Computation at the edge of chaos" (the λ parameter); Packard 1988; the
critique by Mitchell, Hraber and Crutchfield 1993; Wuensche's Z parameter and
input-entropy variance as a classifier (Complexity 1999). Why: our dictionary
is a continuous-ish knob through rule space like λ, and our regime counts are
Wuensche-style classifiers. Also Crutchfield and Hanson's computational
mechanics of CA (Physica D 1993) and Shalizi et al. 2006 (PRL, local
statistical complexity, "automatic filters for coherent structure"): the
right way to define our "regimes per block" objectively, instead of the
hand-made class list in the harness.

**B. Stochastic and voting automata, coarsening, fault tolerance.**
Vichniac 1984 (voting rules, the annealing rule); Toom 1980 and Gács 2001 on
majority rules that resist noise; Domany and Kinzel 1984 probabilistic CA;
Oliveira 1992 majority-vote model; Glauber Ising dynamics and Allen–Cahn
curvature-driven coarsening (Bray's 1994 review of phase-ordering kinetics).
Why: the per-bit-plane median is a voting rule, and H1 is a coarsening claim.
The density-classification task (Gács, Kurdyumov, Levin 1978; Mitchell,
Crutchfield, Das 1996) is the classic study of majority-like rules.

**C. Artificial life substrates where programs are the matter.**
Dewdney's Core War (Scientific American 1984, and the ICWS-88 standard; we
emulate Redcode); Ray's Tierra 1991; Adami and Brown's Avida 1994, Lenski et
al. 2003 (Nature); Pargellis 2001 (amoeba, replicators from random soup);
Koza 1994 on spontaneous self-replicators; Fontana and Buss 1994 (lambda
chemistry); Dittrich, Ziegler, Banzhaf 2001 review of artificial chemistries;
Hutton's Squirm3; Ackley's Movable Feast Machine (robust spatial computing);
Agüera y Arcas et al. 2024, "Computational Life" (self-replicating programs
emerging in Brainfuck soups; verify the arXiv number before citing). Why:
these are the systems a referee will name, and our Brainfuck and CPU rules
sit right next to them. The difference to state plainly: Keimli has no
replication and no selection; it is pattern formation, and this must be said
in the first page.

**D. Continuous and learned automata, and the search for interestingness.**
Chan 2019 Lenia and 2020 expanded universe; Mordvintsev et al. 2020 growing
neural CA (Distill); Reinke, Etcheverry, Oudeyer 2020 (ICLR, intrinsically
motivated discovery of diverse patterns in Lenia; IMGEP); Hamon et al. Flow
Lenia; Lehman and Stanley 2011 novelty search; Mouret and Clune 2015
MAP-Elites and the quality-diversity line (Pugh et al. 2016); Schmidhuber
2009 "compression progress" as the formal theory of interestingness (fits
our subject uncannily: the system is literally a compressor); Stanley,
Lehman and Soros on open-endedness; Sayama's swarm chemistry. Why: Q6 and Q7
and the whole dictionary-search methodology (annealing, swarm, splices,
crossovers) are a quality-diversity search over rule strings, and must be
positioned as such.

**E. Compression, algorithmic information and life.**
Ziv and Lempel 1977; the Brotli RFC 7932 (Alakuijala and Szabadka 2016) and
the Brotli paper (ACM TOIS 2019); Kaspar and Schuster 1987 (Lempel–Ziv
complexity as a measure of spatiotemporal patterns); Zenil and Delahaye on
the algorithmic complexity of CA and the coding-theorem method; Cilibrasi and
Vitányi 2005 (compression-based distance; a candidate similarity metric
between our dictionaries' outputs); Chaitin 2012 *Proving Darwin*
(metabiology: organisms as programs); Walker and Davies 2013 on algorithmic
origins of life; Li and Vitányi for the background. Why: the paper's identity
is "the rule is a decoder", and this thread lets us say what decoding does to
information precisely: it is a fixed many-to-one map whose image is the set of
decodable strings. Mention assembly theory (Sharma et al. 2023) only if a
measure of object complexity is needed, and note the controversy.

**F. Genotype-to-phenotype maps that decode bit strings.**
Grammatical Evolution (Ryan, Collins, O'Neill 1998; O'Neill and Ryan 2001):
a bit string read as codons, modulo a grammar, with wrap-around. This is the
closest existing use of "decode a genome through a table with wrap-around",
and the degeneracy and neutrality results there (and Schuster, Fontana et al.
1994 on RNA neutral networks; Wagner 2005/2008 on robustness and
evolvability) are the vocabulary for H4. Also indirect encodings (Stanley and
Miikkulainen 2003 taxonomy; Gruau's cellular encoding; L-systems) as a
contrast: ours decodes in place, every turn.

**G. Recombination on lattices.**
Syswerda 1989 uniform crossover; Spears and De Jong 1991 (parameterised
uniform crossover, which is exactly our 2p(1−p) rate once you count both
directions); cellular genetic algorithms (Whitley 1993; Alba and Tomassini
2002; Alba and Dorronsoro's book) where individuals sit on a grid and mate
with neighbours; the voter model and spatial coalescence. Why: the mixing
stage is a cellular GA with no fitness, and reviewers from evolutionary
computation will ask why.

**H. Colour and display.**
Glasbey et al. 2007 (colour displays for categorical images, maximin palettes)
for the 256-byte palette; Tukey's median filter origin; basic references for
temporal averaging. One paragraph in methods, no claims.

Search plan: start from the references above by citation chasing in Google
Scholar and Semantic Scholar (forward citations of Langton 1990, Reinke 2020,
Agüera y Arcas 2024 and Shalizi 2006 are the four most productive seeds);
then keyword searches: "decompression" OR "decoder" with "cellular automaton";
"LZ77 cellular automaton"; "dictionary coding artificial life"; "self-decoding";
"quine cellular automaton"; "compression artificial life"; "interestingness
measure cellular automata"; "majority vote coarsening cellular automaton
noise". Record every hit that uses a codec as a dynamical rule, even
tangentially; if there is prior art on claim 1, we must find it ourselves
rather than hear it from the referee. Budget: three full days of reading, a
shared bibliography file (`paper/references.bib`) with a `verified = yes/no`
field, and a one-page "related work map" before any writing.

## 4. Experiments, measurements, controls

Everything runs headless with the existing harness (`tools/ca-harness.mjs`)
and the page's own counters; nothing in the article should depend on a
screenshot alone. Fixed protocol: 10 seeds per condition, grid 256 × 256 for
statistics and 1024 × 1024 for figures, 1,000 turns with samples every 10,
report mean and the 10th–90th percentile band, and state the seed list. The
settings line (`keimli1 ...`) for every figure goes in its caption, so any
reader can reproduce the frame in the browser.

Measurements to implement or keep:

- d1 (fraction of bits changing per turn), d2 (two-turn), bits moved, bits
  median-changed, bits rewritten: the entropy budget, per turn, per gradient
  band (16 vertical and 16 horizontal strips).
- Byte entropy, zip ratio, distinct cell contents.
- Domain statistics: label connected regions of equal dominant byte;
  distribution of sizes; mean domain length against turn (H1).
- Regimes: replace the hand-made block classifier with Shalizi-style local
  statistical complexity or at least a clustering of block feature vectors,
  then report the effective number of clusters; keep the current classifier
  as a secondary measure, since the search results were obtained with it.
- Decoder map statistics (H4): sample 10^6 random cells per dictionary, count
  distinct outputs, fixed points, 2- and 3-cycles; the pair variant too.
- Positional sensitivity map of the dictionary (H2).
- Transform invariance (H7).
- Human ranking pilot (H6): six to ten viewers, twenty images, the same
  settings, forced ranking; Kendall τ against each score. Say in the text that
  this is a pilot.

Ablation matrix (each with the reference dictionary, 10 seeds):

| mixing | settling | rewriting | expected |
| --- | --- | --- | --- |
| on | off | off | noise, no structure |
| off | on | off | coarsening to a few domains, then frozen |
| off | off | on | each cell falls onto a decoder attractor independently, no spatial order |
| on | on | off | Ising-like coarsening under noise (H1 control) |
| on | off | on | ? (the experiment that may surprise) |
| off | on | on | domains with decoder-set texture, frozen or breathing |
| on | on | on | reference |

Dictionary controls for every searched dictionary: the same bytes shuffled;
random bytes with the same histogram; a real text of the same length; the
dictionary reversed. If the shuffled control gives the same regime count, the
"structure of the dictionary" claim falls and the article must say the
alphabet alone matters.

Scaling checks: 128, 256, 512, 1024 grids; do measures converge per cell? The
searches were done at 64 and 128 and the pictures judged at 512 and 1024,
which is a weakness to close rather than hide.

## 5. Figures (decide them before writing)

1. The system in one picture: a cell, its 128 bits, the three stages, the
   decoder reading the bits and writing 16 bytes back, the dictionary. One
   schematic, drawn, not a screenshot.
2. The reference run: four frames at turns 10, 100, 400, 1,000 at 1024², with
   the two gradients annotated on the axes, so the reader sees the phase
   diagram.
3. Ablations: the seven conditions at turn 400, same seed, small multiples.
4. Entropy budget against p for each gradient; d1 against turn for the
   ablations (H1, H5).
5. Domain-length growth: settle-only versus reference, log–log (H1).
6. Dictionaries: a gallery of eight (two texts, Brotli 1, 9, 13, Swarm A, D,
   F) with regime counts, and the shuffled controls beside them (H3).
7. Positional sensitivity of a dictionary (H2) as a bar along the byte axis.
8. Decoder map statistics across dictionaries (H4).
9. Score versus human rank scatter (H6), and the F transform family (H7).
10. Platform table (CPUs, decoders, pairs, links) as a table, not a figure.

## 6. Article outline

Target 8,000 words plus appendix, or 6 pages if a conference format forces it.

1. Introduction (700 words): the question (what happens when a lattice's rule
   is a decompressor), the three claims, what we do not claim.
2. Related work (900): threads A to G, compressed, each paragraph ending in
   the difference to this work.
3. The system (1,500): cell, stages, decoder to the bit, dictionary, display;
   the pinned table; implementation note (WebAssembly, band workers, browser).
4. Measures (600): the entropy budget, regimes, domains, decoder statistics.
5. Results (2,500): Q1 to Q5 in order, each with its figure and its numbers.
6. Searching dictionaries (900): the methods (annealing, splices, crossover,
   swarm with word copying, recasing, bit flips and alphabet transforms), the
   score, what was found, and Q6/Q7.
7. Discussion (700): decoding as a many-to-one map that arrests coarsening;
   text as rule; the gap between score and eye; limits (no replication, no
   selection, qualitative regimes, small human pilot).
8. Reproducibility (200): the repository, the settings lines, the harness,
   the seeds.
Appendix: decoder format tables, the dictionary texts, the CPU table, the
palette construction.

## 7. Venue

First choice: *Artificial Life* (MIT Press) as a full article; the platform
breadth and the dictionary-search methodology fit there. Alternatives: the
ALIFE conference (shorter, faster, good for a first airing of claim 1);
*Complex Systems* (would welcome the CA framing); *Physica D* or *Chaos* if
the coarsening-arrest result (H1) becomes quantitative enough to lead;
*Entropy* for the entropy-budget framing. Post to arXiv (nlin.CG, with cs.NE
cross-list) at submission. Pick after the H1 and H4 numbers are in: if the
coarsening arrest is clean, lean physics; if the dictionary findings
dominate, lean ALife.

## 8. Reproducibility and the artifact

The repository is the artifact. Before submission: tag a release; freeze the
reference settings line in the README; add `paper/` with the figure scripts
(`paper/figures/*.mjs` driving the harness), the seed lists, the raw CSVs,
and the bibliography; make the headless harness runnable with one command
that regenerates every number in the paper; archive the release on Zenodo for
a DOI. The settings line is a feature reviewers will like: every figure is a
URL.

## 9. Timeline

- Week 1: decide the claim (section 0); reading, threads A to G; the related
  work map; pin the system table against the code.
- Week 2: implement the missing measures (domains, decoder map, objective
  regimes); run the ablation matrix and the dictionary controls; first look at
  H1 and H4.
- Week 3: the remaining experiments; the human pilot; all figures in draft.
- Week 4: write sections 3 to 5; week 5: sections 1, 2, 6, 7; week 6: internal
  review, rewrite, reproducibility package, submit.

The swarm search runs throughout on a spare machine and anything it finds
goes into the gallery, not into the claims.

## 10. What the referee will say, and the answer to have ready

- "This is not life; there is no replication or selection." Agreed, and said
  on page one; the claim is about pattern formation under a decoder rule.
- "The regimes are hand-labelled." Hence the objective measure in section 4
  and the report of both.
- "The dictionaries were found by searching for a score you invented." Hence
  the shuffled and histogram-matched controls, and Q6 admitting the score's
  limits.
- "Why these particular decoders?" Because they are the family the authors
  know to the bit, and the paper studies one reference decoder fully, with
  the others as a table.
- "The human study is anecdotal." It is a pilot and is named as one; the
  quantitative claims do not rest on it.
- "Isn't this just a noisy majority-vote CA with a lookup table?" The decoder
  is not a lookup table on the neighbourhood; it is a map on the cell's own
  128 bits with a 4,400-byte parameter, and H1 and H4 are the experiments that
  separate it from the majority rule.
- "Prior art." Only the reading in section 3 answers this; do it first.

## 11. Rules for the writing

Claims match evidence: a sentence with "shows" needs a figure; "suggests" is
for everything else. Define each term once and never vary it. One reference
setting; every deviation stated. Numbers in tables, not prose. Put the
settings line in every caption. Say what did not work: the first lattice
scores pinned at their floor; the codebook decoder needing small alphabets to
contract; the swarm converging on whitespace. Those are results too.
