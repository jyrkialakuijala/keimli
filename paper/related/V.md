# Thread V: verification (A, B, F, G, H, P) and new works for F (genotype–phenotype maps) and G (cellular EAs)

Checked on 2026-10-21. Corrected entries are in V.bib under the same keys, except albury2018, which becomes **albury2019**.
Sources: Crossref (`api.crossref.org/works/<doi>`), PubMed, zbMATH Open, OpenAlex, arXiv, and the authors' or
repositories' own pages. DBLP and Semantic Scholar were bot-walled or rate-limited in this session, which matters only for
the ICGA papers.

## Part 1. Verification of existing entries (26 entries in scope)

Scope: every no/partly entry outside threads C, D and E.
**Before:** 15 no, 11 partly. **After:** 22 yes, 4 partly, 0 no.

| key | before → after | what changed | source |
|---|---|---|---|
| wolfram1984 | no → yes | issue 1–2 and DOI 10.1016/0167-2789(84)90245-8 added | https://doi.org/10.1016/0167-2789(84)90245-8 |
| wolfram2002 | no → yes | address Champaign, IL added | zbMATH Open (xiv+1197 p.) |
| langton1990 | partly → yes | pages 12–37 confirmed; issue 1–3 and DOI 10.1016/0167-2789(90)90064-V added | Crossref |
| packard1988 | no → yes | pp. 293–301 confirmed against the proceedings table of contents; volume DOI 10.1142/0534 added | zbMATH Open record of the proceedings (full TOC); Crossref |
| wuensche1999 | partly → yes | subtitle confirmed word for word; DOI added | Crossref |
| toom1980 | no → yes | series *Advances in Probability and Related Topics* vol. 6 and New York added; pages 549–575 confirmed (some citing papers give 576) | zbMATH Open |
| bray1994 | partly → yes | end page 459 confirmed; DOI 10.1080/00018739400101505 added; 2002 reprint DOI added | Crossref |
| **gacs1978** | no → yes | **pages 92–96, not 92–98**; issue 3 added; now @article (was @incollection) | zbMATH Open Zbl 0393.68060 |
| mitchell1996 | partly → yes | publisher Russian Academy of Sciences added; no page range cited (1–14 unconfirmed) | https://csc.ucdavis.edu/~evca/Papers/evca-review.html |
| oneill2001 | partly → yes | volume 5(4) 349–358 confirmed; DOI 10.1109/4235.942529 | Crossref |
| schuster1994 | no → yes | issue 1344 and DOI 10.1098/rspb.1994.0040 added; journal name expanded | Crossref + PubMed 7517565 (authors) |
| wagner2005 | no → yes | address and ISBN 0-691-12240-7 added; e-book DOI noted | Crossref (De Gruyter e-book; BioEssays review 10.1002/bies.20460) |
| wagner2008 | no → yes | issue 1630, DOI 10.1098/rspb.2007.1137 | Crossref |
| stanley2003 | no → yes | DOI 10.1162/106454603322221487 | Crossref |
| gruau1994 | no → yes | DOI 10.1177/105971239400300202 | Crossref |
| syswerda1989 | no → yes | editor Schaffer added; pages 2–9 confirmed | Semantic Scholar record with DBLP key conf/icga/Syswerda89 |
| spears1991 | partly → partly | author order Spears, De Jong confirmed; pages 230–236 still come only from citing papers | DTIC/Crossref 10.21236/ADA293985 (NRL report version, 1995); Springer reference list |
| whitley1993 | no → partly | forename L. Darrell; editor Forrest. A **one-page** item on p. 658 (an abstract) | ACM DL citation 657598 (search snippet only: page returned 403) |
| alba2002 | no → yes | DOI 10.1109/TEVC.2002.800880 | Crossref |
| alba2008 | no → yes | series ORCS vol. 42, New York, DOI 10.1007/978-0-387-77610-1 | Crossref; zbMATH Open |
| tukey1977 | no → yes | **was @incollection with no booktitle; now @book**, Reading, MA | zbMATH Open |
| **haukeli2012** | partly → partly | **author's forename is Martin, not Vegard**; handle 10852/34901 added | DUO metadata (via search); US 11934354 B2 non-patent citations |
| **macura2006** | partly → yes | abstract page read: the old note "no results reported" is **wrong**. It reports 94.80 % average compression ratio over all 26-bit sequences (XOR of elementary-CA outputs) | https://www.wolframscience.com/conference/2006/presentations/macura.html |
| **albury2018 → albury2019** | partly → yes | **three authors (Albury, Wales, Wu), FLAIRS-32, 2019, pp. 104–107**; was single author and 2018 | OpenAlex W2946950578; US 11934354 B2 citations |
| cisneros2019 | partly → yes | **it is an IEEE SSCI 2019 paper, pp. 230–237**, DOI 10.1109/SSCI44817.2019.9002840; was @misc arXiv | arXiv abs page; Crossref |
| sicilia2008 | partly → yes | EPL 82(1) 10001, DOI 10.1209/0295-5075/82/10001 | Crossref |

## Part 2. New works

### F1. Neutral networks and the RNA genotype–phenotype map: the vocabulary for many-to-one decoders

**schuster1994** — Schuster, Fontana, Stadler, Hofacker, "From sequences to shapes and back: a case study in RNA secondary
structures", Proc. R. Soc. B 255(1344):279–284, 1994. doi:10.1098/rspb.1994.0040.
They census the RNA sequence-to-fold map. A few common shapes take up most of sequence space; the sequences that fold to
one shape form extended neutral networks that percolate the space; every common shape lies within a short distance of
any random sequence ("shape space covering"). Keimli's decoder is the same kind of object: a fixed many-to-one map from
128-bit genotypes to byte outputs, so the same census (frequency of each output, neutral sets, robustness) applies.
*Cite:* "Like the RNA folding map [schuster1994], the decoder is many-to-one, and its census of outputs and of the inputs
that produce each one is the first thing to measure." Verified: Crossref, PubMed.

**huynen1996** — Huynen, Stadler, Fontana, "Smoothness within ruggedness: the role of neutrality in adaptation", PNAS
93(1):397–401, 1996. doi:10.1073/pnas.93.1.397.
Populations drift along neutral networks and then make punctuated jumps to new shapes. This is vocabulary for the
neutral drift Keimli cells undergo while mixing changes bits the decoder ignores. Verified: Crossref.

**fontana1998** — Fontana & Schuster, "Continuity in evolution: on the nature of transitions", Science
280(5368):1451–1455, 1998. doi:10.1126/science.280.5368.1451.
The paper defines accessibility (nearness) between phenotypes through the genotype–phenotype map, not through phenotype
similarity. The resulting topology is not symmetric, and evolutionary transitions are continuous or discontinuous with
respect to it. Use it for the transition graph between Keimli's attractors under single-bit mixing.
*Cite:* "Which output is reachable from which under bit mixing is a property of the map, not of output similarity
[fontana1998]." Verified: Crossref.

### F2. Bias in genotype–phenotype maps, simplicity bias and the coding theorem (most relevant to Keimli)

**dingle2018** — Dingle, Camargo & Louis, "Input–output maps are strongly biased towards simple outputs", Nature
Communications 9:761, 2018. doi:10.1038/s41467-018-03101-6.
For computable many-to-one maps that meet a few conditions (simple map, large input space, non-linear), the probability
of an output is bounded above by 2^(−a·K̃(x)−b), where K̃ is a compression-based (Lempel–Ziv) complexity estimate. They
show this for RNA, ODE systems, a financial model and others: a practical form of the coding theorem. **This is the
closest theory to Keimli's decoder.** A random 128-bit cell fed to an LZ77-plus-dictionary decoder is exactly such a map,
and the decoder's output frequencies can be tested directly against the bound. The test is cheap because the decoder runs
in linear time and its census is tractable. It also supports the paper's "LZ complexity rather than Kolmogorov
complexity" analogy.
*Cite:* "The decoder is an input–output map of the kind Dingle et al. showed to be exponentially biased toward outputs of
low compressed complexity [dingle2018]; Keimli's census gives a case where the map is itself a decompressor." Verified: Crossref.

**dingle2020** — Dingle, Valle Pérez & Louis, "Generic predictions of output probability based on complexities of inputs
and outputs", Scientific Reports 10:4415, 2020. doi:10.1038/s41598-020-61135-7.
This extends the bound to cases where the inputs are not uniformly random, which is the situation of Keimli cells after
mixing and settling. Verified: Crossref.

**schaper2014** — Schaper & Louis, "The arrival of the frequent: how bias in genotype–phenotype maps can steer
populations to local optima", PLoS ONE 9(2):e86635, 2014. doi:10.1371/journal.pone.0086635.
Phenotypes with large neutral sets appear so much more often that they can win against fitter rare phenotypes. **It
tensions with a Keimli finding:** in Keimli, which attractor wins depends on the medium, not on basin size. State it as a
contrast: in Keimli the spatial medium (phase agreement, settling) overrides the "arrival of the frequent".
Verified: Crossref.

**johnston2022** — Johnston, Dingle, Greenbury, Camargo, Doye, Ahnert & Louis, "Symmetry and simplicity spontaneously
emerge from the algorithmic nature of evolution", PNAS 119(11):e2113883119, 2022. doi:10.1073/pnas.2113883119.
Simplicity bias in the GP map explains why protein complexes and RNA are symmetric, without any selection for symmetry.
The Keimli parallel: the repetitive, symmetric cell contents (fixed points and short cycles) can be explained by the
decoder's bias before invoking any "replication". *Cite:* "Simple, repetitive outputs are favoured by the map
itself [johnston2022, dingle2018]; that a decompressor's fixed points are repetitive needs no selective explanation."
Verified: Crossref.

**dingle2015** — Dingle, Schaper & Louis, "The structure of the genotype–phenotype map strongly constrains the evolution
of non-coding RNA", Interface Focus 5(6):20150053, 2015. doi:10.1098/rsfs.2015.0053. They show that natural RNA
structure frequencies follow the GP map's bias. Optional. Verified: Crossref.

**martin2024** — Martin, Camargo & Louis, "Bias in the arrival of variation can dominate over natural selection in
Richard Dawkins's biomorphs", PLoS Comput. Biol. 20(3):e1011893, 2024. doi:10.1371/journal.pcbi.1011893.
This applies the same bias analysis to a hand-designed, developmental "artificial-life" decoder (Dawkins's biomorphs).
It is close in spirit to Keimli: a designed decoder whose bias shapes what evolves. Verified: Crossref.

**dingle2024** — Dingle, Alaskandarani, Hamzi & Louis, "Exploring simplicity bias in 1D dynamical systems", Entropy
26(5):426, 2024. doi:10.3390/e26050426. **hamzi2024** — Hamzi & Dingle, "Simplicity bias, algorithmic probability, and
the random logistic map", Physica D 463:134160, 2024. doi:10.1016/j.physd.2024.134160.
Simplicity bias measured in iterated maps, which is the setting of an iterated local rule. Both are recent and
directly comparable. Verified: Crossref.

### F3. Structure of GP maps (robustness, evolvability, navigability) and reviews

**ahnert2017** — Ahnert, "Structural properties of genotype–phenotype maps", J. R. Soc. Interface 14(132):20170275, 2017.
doi:10.1098/rsif.2017.0275. A review of the shared properties of GP maps: redundancy, phenotype bias, robustness that
grows with the log of phenotype frequency, evolvability, and component correlations. **It gives the checklist for
Keimli's decoder census.** Verified: Crossref.

**greenbury2016** — Greenbury, Schaper, Ahnert & Louis, PLoS Comput. Biol. 12(3):e1004773, 2016.
doi:10.1371/journal.pcbi.1004773. Correlations in the genotype raise robustness well above the random-map expectation.
Verified: Crossref.

**greenbury2022** — Greenbury, Louis & Ahnert, "The structure of genotype–phenotype maps makes fitness landscapes
navigable", Nature Ecology & Evolution 6(11):1742–1752, 2022. doi:10.1038/s41559-022-01867-z. Verified: Crossref.

**mohanty2023** — Mohanty et al., "Maximum mutational robustness in genotype–phenotype maps follows a self-similar
blancmange-like curve", J. R. Soc. Interface 20(204):20230169, 2023. doi:10.1098/rsif.2023.0169.
This bounds robustness for a given phenotype frequency. Keimli's fixed-point "species" could be placed against the
bound. Verified: Crossref.

**manrubia2021** — Manrubia, Cuesta, Aguirre, Ahnert, Altenberg, … Weiß (18 authors), "From genotypes to organisms:
state-of-the-art and perspectives of a cornerstone in evolutionary dynamics", Physics of Life Reviews 38:55–106, 2021.
doi:10.1016/j.plrev.2021.03.004. The standard recent review: cite it once as the entry point to the field.
Verified: Crossref.

**fortuna2017** — Fortuna, Zaman, Ofria & Wagner, "The genotype-phenotype map of an evolving digital organism", PLoS
Comput. Biol. 13(2):e1005414, 2017. doi:10.1371/journal.pcbi.1005414.
They census Avida's GP map exhaustively: genotype networks, robustness, evolvability. **It bridges thread C (program
substrates) and thread F.** It is the precedent for treating a program substrate's interpreter as a GP map and
censusing it, which is what Keimli does for a decoder, cheaply and exhaustively. Verified: Crossref.

### G. Cellular (spatially structured) evolutionary algorithms

**sarma1996** — Sarma & De Jong, "An analysis of the effects of neighborhood size and shape on local selection
algorithms", PPSN IV, LNCS, pp. 236–244, 1996. doi:10.1007/3-540-61723-X_988.
Takeover time depends on the ratio of neighbourhood radius to grid radius, the standard measure of selection pressure on a
lattice. This is useful vocabulary for Keimli's domain growth. Verified: Crossref (LNCS volume inferred).

**giacobini2005** — Giacobini, Tomassini, Tettamanzi & Alba, "Selection intensity in cellular evolutionary algorithms for
regular lattices", IEEE TEVC 9(5):489–505, 2005. doi:10.1109/TEVC.2005.850298.
They give takeover-time models on 1D and 2D lattices, including logistic and polynomial growth of the best class. This is
a quantitative comparison point for how fast one Keimli attractor's domain takes the grid. Verified: Crossref.

**tomassini2005** — Tomassini, *Spatially Structured Evolutionary Algorithms*, Springer Natural Computing Series, 2005.
doi:10.1007/3-540-29938-6. A monograph covering cellular EAs, synchronous and asynchronous update, and takeover.
Keimli's rotating swap order and the synchronous variant correspond to its update-policy discussion.
Verified: Crossref + zbMATH (subtitle from memory).

**alba2008** (existing, now verified) — the cellular GA book. **alba2002** (existing, now verified) — the parallel-EA
review.

**gong2015** — Gong et al., "Distributed evolutionary algorithms and their models: a survey of the state-of-the-art",
Applied Soft Computing 34:286–300, 2015. doi:10.1016/j.asoc.2015.04.061. A more recent survey that places cellular
models among distributed EAs. Verified: Crossref.

**fernandes2020** — Fernandes, Fachada, Laredo, Merelo & Rosa, "Population sizing of cellular evolutionary algorithms",
Swarm and Evolutionary Computation 58:100721, 2020. doi:10.1016/j.swevo.2020.100721. Recent cEA work on grid size.
Verified: Crossref.

Relation to Keimli: in cellular EAs, the lattice exists to slow takeover by selection. Keimli has no fitness and no
selection, and its "recombination" is bit mixing between neighbours (parameterised uniform crossover, spears1991, at a
rate that varies by position). Cite this group for vocabulary (takeover, selection pressure, update order), not as
precedent for the dynamics.

## Most important for the paper
1. **dingle2018**: simplicity bias in many-to-one input–output maps, with an LZ-complexity form of the coding theorem.
   Keimli's decoder is such a map. Test the output census against the bound and frame the LZ-versus-Kolmogorov thesis with it.
2. **schaper2014**: "arrival of the frequent". Keimli's finding that the medium decides the winner, not basin size, is
   best stated as a contrast to it.
3. **johnston2022**: simplicity and symmetry produced by the map's bias alone. It supports describing fixed points and
   short cycles as trivial, map-driven structures.
4. **fortuna2017**: a GP-map census of Avida, the precedent for censusing a program substrate's interpreter as a GP map.
5. **schuster1994 + fontana1998 + manrubia2021**: neutral networks, shape-space covering and accessibility-based
   topology, plus the current review: the standard vocabulary for the decoder census and the attractor-transition graph.

## Threats to novelty
- No work found uses a decompressor (LZ77/dictionary decoder) as a CA rule or as a GP map on a lattice.
- dingle2018 / dingle2020 / dingle2024 already establish, in general, that LZ-simple outputs dominate many-to-one maps,
  including iterated 1D maps. Keimli must not claim the bias toward repetitive outputs as a new finding. The new parts
  are the spatial coupling, the designed cycles and the medium-dependence of the winner.
- martin2024 shows "bias in arrival beats selection" in a designed artificial-life decoder (biomorphs). It is close in
  spirit, but has no lattice and no iteration on the outputs.
- Corrections that change what the paper may claim from prior art: macura2006 *does* report a compression result;
  albury2019 has three authors and the year 2019; cisneros2019 is a peer-reviewed IEEE SSCI paper.

## Could not verify (fully)
- spears1991: pages 230–236 and the editors come only from citing papers (the ICGA-4 table of contents was not readable;
  DBLP was bot-walled).
- whitley1993: only an ACM DL search snippet (p. 658, one page, which suggests an abstract). Consider dropping it or
  citing Gordon, Mathias & Whitley, SAC 1994, 237–241 (not verified here).
- haukeli2012: forename Martin confirmed by two sources, but the awarding institution is ambiguous (DUO/University of Oslo
  versus "Oslo University College" in a patent).
- gacs1978: the English translation (Problems of Information Transmission 14(3) 223–226) comes only from secondary sources.
- tomassini2005: the subtitle "Artificial Evolution in Space and Time" is from memory. sarma1996: LNCS 1141 is inferred.
- wagner2005: the series "Princeton Studies in Complexity" is from memory.
