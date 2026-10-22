# Thread E — Information, complexity, entropy and computation

All DOIs below were resolved against the Crossref API in this session unless the entry says otherwise. BibTeX in E.bib.

## E0. Existing entries in references.bib: verification and fixes

- **ziv1977** — verified (doi 10.1109/TIT.1977.1055714, 23(3):337–343). Fix: add DOI. Use it for the *decoder* (literal + copy), not for the LZ complexity measure. Kaspar–Schuster implement lempel1976.
- **rfc7932** — verified (doi 10.17487/RFC7932). Add DOI.
- **alakuijala2019** — verified. Crossref lists the authors in the bib's order (Vandevenne last), 37(1):1–30, online Dec 2018 / issue Jan 2019. "Article 4" comes from ACM's citation format; Crossref does not show it.
- **kaspar1987** — verified, 842–848, doi 10.1103/PhysRevA.36.842.
- **zenil2015** — verified (PeerJ CS 1:e23, doi 10.7717/peerj-cs.23, arXiv 1212.6745). **What it argues.** It proposes the *coding theorem method* in 2D: estimate K(x) ≈ −log₂ P(x), where P(x) is the frequency with which small 2D Turing machines output x. It then shows that CTM agrees with lossless compression only "where both methods overlap in their range of applicability", that is, on objects large enough to compress. The authors' line across the series is that compressors are unreliable K estimators for small objects, and that LZ-type compression captures statistical regularity (entropy rate) rather than algorithmic structure. INTRODUCTION.md l.71 and MOTIVATION.md l.58 cite it for "LZ is a good-enough proxy for K", which reverses its point. **Fix:** cite zenil2015 / soler2014 for the *decoder side*: random programs fed to a machine sample its algorithmic probability. Cite zenil2018 / zenil2020 for the claim that LZ measures entropy rate rather than K. Cite lempel1976 + kaspar1987 + the EEG/DNA papers (E3) for "LZ is what science uses in practice".
- **cilibrasi2005** — verified, add doi 10.1109/TIT.2005.844059.
- **chaitin2012** — verified as a book (Pantheon 2012, ISBN 9780375423147). It is a popular metabiology book and does not support a technical claim about LZ proxies. Drop it from that sentence, or keep it only as a pointer to "evolution as random walk in software space".
- **walker2013** — verified, add issue 79 and DOI 10.1098/rsif.2012.0869.
- **li2008** — verified (Springer, Texts in CS, doi 10.1007/978-0-387-49820-1). A 4th edition (2019) also exists.
- **sharma2023** — verified, Nature 622(7982):321–328, doi 10.1038/s41586-023-06600-9. Contested. See abrahao2024 / ozelim2026 below: the assembly index reduces to dictionary/LZ compression. That critique is *useful* to Keimli (see E2).

## E1. Algorithmic information: the foundations the motivation needs

**lempel1976** — Lempel & Ziv, "On the complexity of finite sequences", IEEE Trans. IT 22(1):75–81, 1976.
Defines production complexity, the number of phrases in an exhaustive history. It is a *parsing* measure of an observed string, and normalised it tends to the entropy rate. This is the measure that Kaspar–Schuster and all the EEG/DNA work use, not LZ77.
Relation: the correct citation for "complexity is measured in practice by LZ". Suggested: "Real-world complexity is measured by the Lempel–Ziv production complexity of an observed string [lempel1976, kaspar1987], which is computable in linear time, and not by Kolmogorov complexity, which is not." doi 10.1109/TIT.1976.1055501.

**ziv1978** — Ziv & Lempel, "Compression of individual sequences via variable-rate coding", IEEE Trans. IT 24(5):530–536, 1978.
LZ78: the compression ratio reaches the finite-state compressibility (the entropy rate for stationary ergodic sources). This gives the formal sense in which LZ is an *entropy-rate* estimator, not a K estimator. Suggested: "LZ parsing converges to the entropy rate [ziv1978], which bounds K from above only up to the source's statistics." doi 10.1109/TIT.1978.1055934.

**levin1974** — Levin, "Laws of information conservation (nongrowth) and aspects of the foundation of probability theory", Probl. Inf. Transm. 10(3):206–210, 1974 (Russian: Probl. Peredachi Inf. 10(3):30–35).
The standard source for the coding theorem K(x) = −log m(x) + O(1) and for information non-growth under computable maps; Chaitin 1975 has it independently. Non-growth is the formal version of the panel's data-processing point: a deterministic decoder cannot create algorithmic information. Suggested: "Fed random bits, a machine outputs x with its algorithmic probability, and for a universal machine −log of that probability equals K(x) up to a constant [levin1974, chaitin1975]." Verified on Math-Net.Ru (ppi1039); no DOI. This is the coding-theorem paper. Levin 1973, "Universal sequential search problems", is universal search, which the paper does not need.

**zvonkin1970** — Zvonkin & Levin, Russ. Math. Surveys 25(6):83–124, 1970. The a priori (universal semi-)measure; the survey reference. doi 10.1070/RM1970v025n06ABEH001269.

**kolmogorov1965 / solomonoff1964 / chaitin1966 / chaitin1975** — the three founding definitions of algorithmic complexity and the prefix-free version. One sentence: "Kolmogorov complexity [solomonoff1964, kolmogorov1965, chaitin1966] is uncomputable." Kolmogorov 1965 is partly verified: the Russian original is pp. 3–11 per Math-Net.Ru; the English 1–7 pagination was not seen; the 1968 IJCM reprint has doi 10.1080/00207166808803030. The others have Crossref DOIs (10.1016/S0019-9958(64)90223-2; 10.1145/321356.321363; 10.1145/321892.321894).

## E2. The decoder side: CTM, simplicity bias, and critiques of LZ as a K proxy

**soler2014** — Soler-Toscano, Zenil, Delahaye, Gauvrit, PLoS ONE 9(5):e96223, 2014.
Runs all small Turing machines and takes the output frequency distribution D(n), then estimates K(s) = −log₂ D(s) for short strings. This is the coding theorem method. **Method:** Keimli's census of the decoder's image under uniformly random 128-bit inputs is the same construction with a fixed, non-universal decoder in place of the TM enumeration. Suggested: "Our census of the decoder's image under uniform random input is the coding-theorem construction [levin1974, soler2014] with a fixed, sub-universal reference machine." doi 10.1371/journal.pone.0096223.

**zenil2019** (arXiv 1711.01711) — Zenil, Badillo, Hernández-Orozco, Hernández-Quiroz, "Coding-theorem like behaviour and emergence of the universal distribution from resource-bounded algorithmic probability", IJPEDS 34(2):161–180 (online 2018).
Computes output distributions of machines below Turing universality (finite automata, PDAs, LBAs). They show coding-theorem-like simplicity bias, and the rank agreement with the universal distribution grows with computational power. **Most directly relevant formal frame:** an LZ77+dictionary decoder of fixed depth is such a resource-bounded machine. This supports the reviewer's rewording, "the decoder fed random bits samples a resource-bounded algorithmic probability". doi 10.1080/17445760.2018.1448932.

**dingle2018** — Dingle, Camargo, Louis, "Input–output maps are strongly biased towards simple outputs", Nat. Commun. 9:761, 2018.
For computable, many-to-one, non-universal input→output maps they derive P(x) ≤ 2^(−aK̃(x)−b). Here K̃ is estimated by LZ complexity. They test it on RNA folding, ODEs, finance models and others. **Method + vocabulary:** gives a falsifiable test of Keimli's decoder map: plot −log₂ P(output) against LZ complexity of output, and an upper-bound line should appear. It also reconciles the two halves of the motivation. LZ (parse side) estimates the complexity of the outputs, and the decoder (generate side) supplies the probabilities. Suggested: "Like other many-to-one input–output maps [dingle2018], the decoder concentrates probability on outputs of low LZ complexity; the fixed points that win are among the simplest outputs." doi 10.1038/s41467-018-03101-6.

**johnston2022** — Johnston et al., PNAS 119(11):e2113883119, 2022. Simplicity bias in genotype→phenotype maps (protein complexes, RNA, gene networks) makes symmetric, simple phenotypes far more likely to arise under evolution. Relation: an analogue of "which attractor wins". Keimli finds the medium, not basin size, decides, which **contrasts** with the simplicity-bias prediction that the largest preimage wins. That contrast is citable. doi 10.1073/pnas.2113883119.

**zenil2018** — Zenil et al., "A decomposition method for global evaluation of Shannon entropy and local estimations of algorithmic complexity" (BDM), Entropy 20(8):605, 2018. In the authors' words, popular lossless compressors capture "statistical regularities", and BDM itself "performs like Shannon entropy when it loses accuracy". Cite for: "LZ-family compressors estimate entropy rate, not algorithmic complexity [ziv1978, zenil2018]." doi 10.3390/e20080605.

**zenil2020** — Zenil, "A review of methods for estimating algorithmic complexity: options, challenges, and new directions", Entropy 22(6):612, 2020. The survey of LZ vs CTM/BDM. Use as the single critique-of-LZ citation. Verified at title level only; I did not read the abstract. doi 10.3390/e22060612.

**zenil2010** — Zenil, "Compression-based investigation of the dynamical properties of cellular automata and other systems", Complex Systems 19(1):1–28, 2010. Classifies CA by the compressibility of their space-time evolutions and by its sensitivity to initial conditions (a compression-based phase-transition coefficient). **Method precedent:** compression-based observables of CA dynamics. In this thread Keimli turns that around: the compressor is the local rule rather than the observable. doi 10.25088/ComplexSystems.19.1.1.

**abrahao2024; uthamacumaran2024; ozelim2026** — Abrahão et al., PLOS Complex Systems 1(1):e0000014 (2024); Uthamacumaran et al., npj Syst. Biol. Appl. 10:82 (2024); Ozelim et al., npj Complexity (July 2026).
They argue that the assembly index of Assembly Theory (sharma2023) is an LZ/dictionary-compression quantity, bounded by Shannon entropy rate. They say it explains selection no better than a compressor does. The 2026 title is "Assembly theory collapses to dictionary compression". **Relation:** a live 2023–2026 debate on whether dictionary compression measures *selection/evolution* or only *statistics*. Keimli's dictionary decoder is the generative dual of the assembly index, so the paper can place itself here. A dictionary-based process yields structured, library-shaped outputs without selection doing the work, which bears on what assembly-type measures can detect. Suggested: "Whether dictionary-compression quantities track selection or only statistics is disputed [sharma2023, abrahao2024, ozelim2026]; a decompressive automaton produces dictionary structure with no selection beyond its fixed points." DOIs: 10.1371/journal.pcsy.0000014; 10.1038/s41540-024-00403-y; 10.1038/s44260-026-00088-w (ozelim2026 volume/article number not yet in Crossref).

## E3. LZ complexity as the working proxy in the sciences (supports the analogy)

**casali2013** — Casali et al., "A theoretically based index of consciousness independent of sensory processing and behavior", Sci. Transl. Med. 5(198):198ra105, 2013.
The Perturbational Complexity Index is the normalised LZ complexity of the binarised TMS-evoked cortical response. It separates wake, sleep, anaesthesia and disorders of consciousness. This is the headline example of LZ standing in for "complexity" in a high-stakes science. Verified: Crossref has the volume, issue and date. The article number 198ra105 and the last three authors are from memory. doi 10.1126/scitranslmed.3006294.

**schartner2015** — Schartner et al., PLOS ONE 10(8):e0133532, 2015. LZ complexity of spontaneous multichannel EEG drops under propofol. doi 10.1371/journal.pone.0133532.

**schartner2017** — Schartner et al., Sci. Rep. 7:46421, 2017. LZ "signal diversity" of MEG rises under ketamine, LSD and psilocybin. doi 10.1038/srep46421.

**aboy2006** — Aboy et al., IEEE TBME 53(11):2282–2288, 2006. On what LZ complexity actually measures in biomedical signals (frequency content, binarisation, noise), a caution paper. Useful for "LZ density is a proxy with known biases". doi 10.1109/TBME.2006.883696.

**gusev1999** — Gusev, Nemytikova, Chuzhanova, Bioinformatics 15(12):994–999, 1999. LZ-type complexity profiles of DNA sequences. The DNA example for the motivation. doi 10.1093/bioinformatics/15.12.994.

**estevezrams2015** — Estevez-Rams et al., "Lempel-Ziv complexity analysis of one dimensional cellular automata", Chaos 25(12):123106, 2015.
Uses LZ76 factor counts as an entropy-density estimate of ECA configurations, and an LZ-based normalised information distance between consecutive configurations as "information transfer". They group rules by these quantities and argue the analysis suits a CA's *computational processing capabilities*. **Method:** the exact observable the panel asks for (LZ density on lattice configurations), with a CA precedent. doi 10.1063/1.4936876.

**estevezrams2019** — Estevez-Rams et al., Chaos 29(4):043105, 2019. LZ-based entropy density and information-distance measures of computational capability near the edge of chaos in 1D systems. Title-level verified. doi 10.1063/1.5062364.

## E4. Thermodynamics of computation: what "entropy reduction" means

**landauer1961** — IBM J. Res. Dev. 5(3):183–191. Logically irreversible operations (erasure, many-to-one maps) must dissipate ≥ kT ln 2 per bit. **Vocabulary:** Keimli's decoder is a many-to-one map, so each application is logically irreversible, and the bits it erases are exactly H(input) − H(output). Suggested: "The rewrite is logically irreversible in Landauer's sense [landauer1961]: it maps 2^128 inputs onto at most 2^93.5 outputs, and the difference is the information it erases." doi 10.1147/rd.53.0183.

**bennett1973** — IBM J. Res. Dev. 17(6):525–532. Any computation can be made logically reversible, so irreversibility is not essential to computation. **Key for the thesis:** entropy reduction (erasure) and computation are separable *in principle*. A running program in Core War/BFF does both, and Keimli keeps only the erasing part. doi 10.1147/rd.176.0525.

**bennett1982** — "The thermodynamics of computation—a review", IJTP 21(12):905–940. The standard review: computation costs nothing intrinsically, and only erasure costs. Cite with bennett1973 for "the entropy a program removes from its memory is a separate quantity from the computation it performs". doi 10.1007/BF02084158.

**fredkin1982** — Fredkin & Toffoli, "Conservative logic", IJTP 21(3–4):219–253. Reversible, conservative universal logic (billiard-ball model). It is the reversible counterpart: universal computation with zero entropy reduction. Together with Keimli (entropy reduction with no universal computation), it gives two points on either side of the dichotomy. doi 10.1007/BF01857727.

**bennett1988** — "Logical depth and physical complexity", in Herken (ed.), The Universal Turing Machine: A Half-Century Survey, OUP, pp. 227–257. Depth is the run time of near-shortest programs. Random and trivially ordered strings are both shallow, while organised objects are deep. **Vocabulary, with a caveat** (round3-information): depth is a property of a *string*, not of a local map. Use it as context only: "the configurations a decoder can reach in one bounded pass are shallow by construction; deep objects require long computation [bennett1988]". Partly verified: Crossref shows the 1990 OUP printing, pp. 227–258. doi 10.1093/oso/9780198537748.003.0008.

**zurek1989** — "Algorithmic randomness and physical entropy", PRA 40(8):4731–4751. Physical entropy = Shannon entropy of the observer's ignorance + algorithmic complexity of the record. Gives the formal bridge between "entropy of the lattice ensemble" and "K of the configuration", which the paper's "entropy budget" needs. doi 10.1103/PhysRevA.40.4731.

**wolpert2019** — "The stochastic thermodynamics of computation", J. Phys. A 52(19):193001. A modern review: the thermodynamic cost of a map depends on how it reduces the entropy of the input distribution (and on the prior). This is the current reference for "a many-to-one map lowers the entropy of its input distribution, and that has a cost". doi 10.1088/1751-8121/ab0850.

## E5. Information dynamics and complexity measures: separating storage/transfer/modification from mere ordering

**lizier2008** — Lizier, Prokopenko, Zomaya, "Local information transfer as a spatiotemporal filter for complex systems", PRE 77:026110. Local transfer entropy on ECAs lights up gliders and leaves domains dark. doi 10.1103/PhysRevE.77.026110.

**lizier2010** — "Information modification and particle collisions in distributed computation", Chaos 20:037109. Local separable information: negative values mark glider collisions, which are *modification*, the non-trivial part of distributed computation. doi 10.1063/1.3486801.

**lizier2012** — "Local measures of information storage in complex distributed computation", Inf. Sci. 208:39–54. Local active information storage: domains and blinkers store information. doi 10.1016/j.ins.2012.04.016.
**What these let the paper say:** they give an operational decomposition of distributed computation into *storage*, *transfer* and *modification*. Entropy reduction alone yields storage: frozen fixed-point domains and phase-locked cycle domains. Transfer and modification need moving, colliding structures. The paper can claim, and *measure*, that Keimli's dynamics is almost entirely storage, with transfer only at moving domain walls and essentially no modification. That is a quantitative form of "entropy reduction without the finesse of computation". The same measures on a BFF/Core War soup would quantify the other source. Suggested: "In Lizier et al.'s decomposition of distributed computation [lizier2008, lizier2010, lizier2012], a decompressive automaton supplies storage but little transfer and no modification."

**crutchfield1989** — Crutchfield & Young, "Inferring statistical complexity", PRL 63(2):105–108. Statistical complexity is the entropy of causal states, and it vanishes for both perfectly ordered and fully random processes. It is a complexity measure that does *not* rise with entropy reduction alone, so a frozen Keimli domain scores low. crutchfield1993 and shalizi2006 are already in the bib. doi 10.1103/PhysRevLett.63.105.

**grassberger1986** — "Toward a quantitative theory of self-generated complexity", IJTP 25(9):907–938. Effective measure complexity (excess entropy): the information needed to predict optimally. It is a lower bound for statistical complexity and is likewise zero for crystals and noise. doi 10.1007/BF00668821.

**gellmann1996** — Gell-Mann & Lloyd, "Information measures, effective complexity, and total information", Complexity 2(1):44–52. Effective complexity is the K of the regularities, separated from the random part. It offers vocabulary for "the dictionary is the regularity". doi 10.1002/(SICI)1099-0526(199609/10)2:1<44::AID-CPLX10>3.0.CO;2-X.

**wolfram1983** — "Statistical mechanics of cellular automata", RMP 55(3):601–644. Irreversible CA lower the entropy of the configuration ensemble from random initial states ("self-organisation"); spatial and temporal entropies are defined there. It is the **classic precedent** for "entropy reduction by an irreversible local map produces structure", the half of the dichotomy Keimli isolates. Cite for the fine-grained/coarse-grained distinction: fine-grained ensemble entropy can only fall under a deterministic CA, while measured (block/coarse-grained) entropies are what change visibly. doi 10.1103/RevModPhys.55.601.

**renyi1961** — Rényi, "On measures of entropy and information", Proc. 4th Berkeley Symp. 1:547–561. The source of the order-α family: H₂ = collision entropy (−log Σp²) and H_∞ = min-entropy (−log max p). The panel asks for these as observables in place of zeroth-order byte entropy. Suggested: "We report the collision entropy H₂ and the min-entropy H_∞ [renyi1961] of the cell distribution, which unlike Shannon entropy are estimated reliably from collision counts." Partly verified (pages agree across three web sources).

**flajolet1990** — Flajolet & Odlyzko, "Random mapping statistics", EUROCRYPT '89, LNCS 434, pp. 329–354. Exact asymptotics for random maps on N points: the image has size (1−1/e)N, the k-th iterate's image shrinks by a known recursion, and they give tail lengths, cycle lengths and the number of cyclic points (~√(πN/2)). **Method:** the analytic null for the paper's "hash:93 random-map null". Under iteration, collision-entropy decay and the count of cyclic points/fixed points can be compared with these formulas instead of only with a simulated hash. doi 10.1007/3-540-46885-4_34 (LNCS volume/year from memory).

## E6. Entropy/compression and activity measures in ALife and open-endedness

**bedau1992** — Bedau & Packard, "Measurement of evolutionary activity, teleology, and life", Artificial Life II, Addison-Wesley, pp. 431–461. Evolutionary activity counts how long components persist, against a shadow (neutral) model. **Relation:** a persistence-based test that separates adaptive persistence from persistence caused by the dynamics. For Keimli, fixed points persist for purely dynamical reasons, which is exactly what the shadow model is designed to discount. Partly verified (authors' PDF; no DOI).

**adams2017** — Adams, Zenil, Davies, Walker, Sci. Rep. 7:997, 2017. Defines unbounded evolution as non-repetition within the Poincaré recurrence time, and innovation as trajectories not seen in isolated systems. Tested on CA whose rules vary in time; state-dependent rule changes do best. **Relation:** a formal criterion that a fixed-rule, deterministic, finite Keimli lattice fails by construction, since it freezes or cycles. That is consistent with Keimli as the "no open-endedness" control. doi 10.1038/s41598-017-00810-8.

**hernandezorozco2018** — Hernández-Orozco, Hernández-Quiroz, Zenil, Artificial Life 24(1):56–70, 2018. They argue that open-ended evolution with unbounded growth of complexity needs undecidability or irreducibility. **Supports the thesis:** a decidable, O(n), fixed-depth rule cannot be open-ended in their sense. The rich phenomena of BFF/Core War that Keimli lacks are those that need computation. doi 10.1162/artl_a_00254.

Already in the bib and relevant: cisneros2019 (compression-based interestingness in CA), schmidhuber2009 (compression progress), wuensche1999 (input-entropy classification of CA).

## Most important for the paper (ranked)
1. **zenil2019 + soler2014 + levin1974**: the correct frame for the decoder. Random bits through a sub-universal decoder sample a resource-bounded algorithmic probability (coding theorem side). This replaces the mis-cited "LZ is good enough [zenil2015]".
2. **dingle2018**: a ready-made, falsifiable test of the decoder map (output probability against LZ complexity of the output). It joins the parse side (LZ) and the decode side (probability) in one plot.
3. **lizier2008/2010/2012**: a measurable storage/transfer/modification decomposition that turns "entropy reduction vs computation" into numbers.
4. **landauer1961 + bennett1973/1982 + fredkin1982 + wolfram1983**: erasure (many-to-one) and computation are separable. Reversible computing is the opposite corner, and irreversible CA self-organise by entropy reduction alone.
5. **lempel1976 + casali2013/schartner2015 + estevezrams2015 + renyi1961 + flajolet1990**: the practical-proxy analogy with the right citation, and the observables (LZ density, H₂, H_∞) plus an analytic random-map null.

## Threats to novelty
- **Coding theorem method / resource-bounded algorithmic probability** (soler2014, zenil2019): they already study the output distribution of simple machines fed all inputs, including sub-universal ones. Keimli's map-level census (image size, fixed points) is methodologically the same as CTM with a specific decoder. The novelty is *putting that decoder in a lattice as the CA rule* and studying the spatial dynamics. Say so explicitly.
- **Simplicity bias in input–output maps** (dingle2018, johnston2022): the statement that "a many-to-one decoder concentrates mass on simple outputs" is not new. Keimli's finding that the medium, not basin size, selects the winner is the contrast.
- **Assembly-theory critiques** (abrahao2024, ozelim2026) already equate a dictionary-compression quantity with "selection". These are papers about *measures*, not about a decoder used as dynamics, so there is no direct threat. Expect reviewers from that debate.
- **Wolfram 1983 / Estevez-Rams 2015 / Zenil 2010**: entropy decrease and LZ/compression observables in CA are old. Keimli's contribution is the rule (a decompressor), not the observables.
- I found no paper that uses an LZ77/dictionary *decoder* as the local rule of a CA, or that explicitly frames ALife phenomena as "entropy reduction vs computation" with a decompressive control. hernandezorozco2018 and adams2017 come closest in spirit (open-endedness needs irreducibility / state-dependent rules).

## Could not verify (or only partly)
- levin1974 English page range 206–210 vs 206–211 (Math-Net.Ru gives 206–210); no DOI.
- kolmogorov1965 English pagination 1–7 (Russian original 3–11 confirmed).
- casali2013 article number 198ra105 and authors 9–11 (not shown in the truncated Crossref output).
- bennett1988 first-edition year/pages (Crossref shows the 1990 printing, 227–258).
- flajolet1990 LNCS volume 434 / year 1990 (DOI and pages confirmed).
- ozelim2026 volume/article number (published July 2026, not yet in Crossref).
- zenil2020 and estevezrams2019: verified at title/record level only; abstracts not read.
- bedau1992 and renyi1961: no DOI; verified from secondary records only.
