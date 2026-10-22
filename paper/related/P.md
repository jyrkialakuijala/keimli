# Thread P — prior art and novelty (2026-10-21)

Searches run this session: Semantic Scholar citation graph (BFF arXiv 2406.19108: 26 citing records; Kaspar–Schuster
1987 DOI 10.1103/PhysRevA.36.842: 513 citing records; Ryan–Collins–O'Neill 1998 DOI 10.1007/BFb0055930: 844 citing
records; O'Neill–Ryan 2001 returned nothing, rate-limited), all titles grepped for automat/cellular/lattice/decod/
decompress/compress/replic/iterat/artificial life. OpenAlex keyword search (15 phrases incl. "LZ77 cellular automaton",
"decompression cellular automaton", "quine cellular automaton", "iterated decompression", "self-decoding", "decompressor
dynamical system", "Lempel-Ziv dynamical system fixed point", "string rewriting dictionary cellular automaton",
"lattice virtual machines artificial life", "decompression quine", "spatially varying parameter cellular automaton").
arXiv abstract search ("cellular automaton decompression": 0 hits; "cellular automata Lempel-Ziv": 4 hits, all
measurement; "cellular automata compression rule decoder": 0; "quine cellular": 0; "self-replicators programs soup": 3).
Google Scholar was reachable but throttled (a few queries only; its citation count for BFF was unusable).
General web searches for the remaining phrases.

**Bottom line: no work found that uses a decompressor/decoder as the iterated local update rule of a lattice.**
The nearest things are (a) decompression quines — fixed points of a real LZ77 decoder, built by hand, never iterated
on a lattice; (b) Conway's look-and-say — iterating a run-length *coder* on one string and censusing what survives;
(c) neural CA used as an image decoder — the CA is the decompressor, the converse of Keimli; (d) the BFF/Z80 spatial
soups, where the local rule is an interpreter, not a decoder.

## 1. Fixed points of decompressors (closest to "replicators = fixed points of the decoder")

**cox2010** — Russ Cox, "Zip Files All The Way Down", research!rsc blog, 18 March 2010.
Builds a gzip/zip file that decompresses to itself, first in a toy Lempel–Ziv language with only "literal" and
"repeat" opcodes, then in real DEFLATE; output lags input by one instruction until a final repeat catches up.
"The recursion is in the representation of the program rather than its execution." Relation: a Keimli fixed point is
exactly an LZ77 quine of the cell's decoder (with a static dictionary and a 128-bit budget). Keimli's census finds
these automatically and on a lattice; Cox hand-builds one. Gives vocabulary ("decompression quine") and the earliest
clean construction. Not a novelty threat: one file, no iteration across space, no census.
Suggested: "Fixed points of an LZ77 decoder are decompression quines, which Cox constructed by hand for DEFLATE
[cox2010]; in Keimli they are found by census and compete on a lattice." Verified: https://research.swtch.com/zip

**canet2017** — M. Canet, A. Kumar, C. Lauradoux, M.-A. Rakotomanga, R. Safavi-Naini, "Decompression Quines and
Anti-Viruses", Proc. 7th ACM CODASPY 2017, pp. 23–34, doi:10.1145/3029806.3029818.
Analyses all known decompression quines (files that decompress to themselves), their structure, and proposes a
detector based on structural differences between quines and ordinary compressed files. Relation: the only peer-reviewed
analysis of decoder fixed points found; security framing. Supports the claim that decoder fixed points are known
objects; Keimli's contribution is iterating the decoder as a dynamics and censusing all attractors including cycles.
Suggested: "Decompression quines have been catalogued as a security nuisance [canet2017]." Verified: OpenAlex DOI record.

**vanmello2024** — R. Van Mello, P. Audenaert, "A Generator for Recursive Zip Files", Applied Sciences 14(21), 9797,
2024, doi:10.3390/app14219797.
Generalises Cox's construction; also builds *looped* zip files (A contains B which contains A) — i.e. a 2-cycle of
extraction. Relation: the decompressor analogue of Keimli's short cycles, again hand-built and single-file.
Suggested: "...and extended to two-cycles of extraction [vanmello2024]." Verified: OpenAlex DOI record + abstract.

**conway1987** — J. H. Conway, "The Weird and Wonderful Chemistry of Audioactive Decay", in T. M. Cover, B. Gopinath
(eds.), Open Problems in Communication and Computation, Springer, 1987, pp. 173–188, doi:10.1007/978-1-4612-4808-8_53.
Iterates the look-and-say map (a run-length encoder) on digit strings; proves every string eventually splits into
compounds of 92 "elements" (Cosmological Theorem), with "22" the only fixed point. Relation: the most important
conceptual precedent — iterating a *coding* map on strings and producing a census of persistent, recombining parts in
chemical vocabulary. Differences: an encoder (expanding, length grows ~1.3^n) not a fixed-width decoder; one string,
no lattice, no mixing. The paper should cite it as the ancestor of "iterate a codec and count what survives".
Suggested: "Iterating a coder on strings is old: Conway's audioactive decay iterates run-length encoding and finds
92 persistent elements [conway1987]; Keimli iterates a decoder of fixed width on every cell of a lattice."
Verified: OpenAlex DOI record (title, pages, year).

**williams2011** — L. R. Williams, "Artificial cells as reified quines", Artificial Life XII (MIT Press),
doi:10.7551/978-0-262-29714-1-ch130 (pages not checked).
Self-replicating artificial cells in a spatial computing medium understood as quines made physical. Relation:
vocabulary linking quines and spatial self-replication; not a decoder. Verified: OpenAlex DOI record (title/author only).

## 2. A cellular automaton as decoder (converse direction)

**falcao2025** — A. M. C. Falcao, I. A. X. Santos, F. R. Cordeiro, "Unraveling Neural Cellular Automata for Lightweight
Image Compression", Anais Estendidos SIBGRAPI 2025, pp. 55–60, doi:10.5753/sibgrapi.est.2025.38272.
Trains neural CAs whose iterated local rule reconstructs an image; the compressed file is the NCA; compared against
JPEG/WebP. Relation: closest "CA + decoder" construction found, but the converse: here the CA *is* the decompressor
of one image, while in Keimli a decompressor *is* the CA rule and nothing is being compressed. Together with Haukeli
2012 / Macura 2006 (already in references.bib) this completes the "compression by automata" family.
Suggested: "Neural cellular automata have been trained as image decoders [falcao2025]; we use a decoder as the
automaton." Verified: SBC/SOL publisher page.

## 3. Lempel–Ziv as a measure of automata (Kaspar–Schuster lineage) — no threat

Forward citations of Kaspar–Schuster 1987 (513 scanned) are almost entirely physiological/EEG/time-series uses of LZ
complexity; none runs a codec inside a rule. Relevant ones:

**estevezrams2015** — E. Estevez-Rams, R. Lora-Serrano, C. A. J. Nunes, B. Aragón-Fernández, "Lempel-Ziv complexity
analysis of one dimensional cellular automata", Chaos 25(12), 123106, 2015, doi:10.1063/1.4936876 (arXiv 1511.08657).
LZ-based entropy density and information distance across ECA evolution. Measurement only.
Suggested: "LZ complexity remains a standard lens on automata [kaspar1987, estevezrams2015]." Verified: OpenAlex.

**zenil2010** — H. Zenil, "Compression-based investigation of the dynamical properties of cellular automata and other
systems", arXiv:0910.4042 (published Complex Systems 19(1), 2010 — journal pages not checked).
Classifies CA by compressibility of evolutions and a compression-based "phase transition" coefficient. Measurement.
Verified: OpenAlex arXiv record.

**lathrop1996** — J. I. Lathrop, "Compression Depth and the Behavior of Cellular Automata", Iowa State University
(tech report/repository), 1996. Defines LZ-based compression depth and relates it to CA behaviour. Measurement.
Verified: OpenAlex record (venue details missing).

Also note (no new key): the original Computational Life paper (agueraYarcas2024) itself uses a Brotli-based
"high-order entropy" as its order parameter — compression as measurement inside the lineage Keimli comes from.

## 4. Census vocabulary for many-to-one maps

**flajolet1990** — P. Flajolet, A. M. Odlyzko, "Random Mapping Statistics", Advances in Cryptology — EUROCRYPT '89,
LNCS 434, Springer, 1990, pp. 329–354, doi:10.1007/3-540-46885-4_34.
Expected number of components, cyclic points, tail and rho lengths of a uniformly random map on n points (e.g.
√(πn/2) cyclic nodes). Relation: the null model for Keimli's attractor census — compare the decoder's measured
fixed points/cycles/basins to a random map of the same image size (2^93.5 effective). A method, not a threat.
Suggested: "Against a random map of the same image size, whose cycle statistics are known [flajolet1990], the decoder
has ..." Verified: OpenAlex DOI record (pages; OpenAlex lists 2007 for the online edition; print 1990).

**dingle2018** — K. Dingle, C. Q. Camargo, A. A. Louis, "Input–output maps are strongly biased towards simple
outputs", Nature Communications 9, 761, 2018, doi:10.1038/s41467-018-03101-6.
Many-to-one maps (RNA folding, ODEs, finance models) hit low-complexity outputs exponentially more often, with the bound
P(x) ≲ 2^{-aK̃(x)-b} using LZ-type complexity. Relation: directly predicts that Keimli's decoder maps most inputs onto
compressible outputs; gives the "simplicity bias" vocabulary for the 93.5-bit image result and a testable law for
attractor frequency vs. LZ complexity. Strongly supports the thesis framing.
Suggested: "Like other input–output maps [dingle2018], the decoder is simplicity-biased: ..." Verified: OpenAlex DOI.

**dingle2024** — K. Dingle, M. Alaskandarani, B. Hamzi, A. A. Louis, "Exploring Simplicity Bias in 1D Dynamical
Systems", Entropy 26(5), 426, 2024, doi:10.3390/e26050426; and **hamzi2024** — B. Hamzi, K. Dingle, "Simplicity bias,
algorithmic probability, and the random logistic map", Physica D 463, 134160, 2024, doi:10.1016/j.physd.2024.134160.
Extend simplicity bias to iterated maps (logistic etc.) — symbolic trajectories are biased to low LZ complexity.
Both cite Kaspar–Schuster. Relation: the dynamical-systems version of the above; closest literature for "iterated
map + LZ complexity of what it produces". Verified: OpenAlex DOI records.

## 5. Program lattices: Computational Life and its 2024–2026 follow-ups

Precise description of BFF's 2D variant (from arXiv 2406.19108v2, §2.2 "Spatial simulations"): 32,400 BFF tapes on a
240×135 grid; each epoch programs are visited in random order, each picks a neighbour uniformly within Chebyshev
distance 2 (5×5 window); if neither is taken both are marked; the concatenation PN is executed and split back,
overwriting both; non-executing programs are still mutated. Replicators arise and spread as waves (takeover ∝ side
length vs. log n well-mixed), and variants coexist. Forth has a 2D soup figure; the Z80 experiment is a 2D grid of
16-byte programs, a random adjacent pair concatenated in random order, 256 Z80 steps, addresses mod 32. Relation to
Keimli: Keimli's CPU mode is this design generalised to 25 ISAs plus mixing/settling; its decoder mode replaces the
interpreter by a decoder. Already cited as agueraYarcas2024.

**knierim2026** — C. Knierim, L. Versari, R. Obryk, B. Agüera y Arcas, R. A. Saurous, "BFF: Simple explanations for
complex phenomena", arXiv:2607.01483, 2026.
Using newer self-replicator detectors, finds replicators are found at least as easily by plain mutation random walks
as by pairwise interaction; capping ancestry-tree depth/width stops takeover, not emergence. Relation: strongly
supports Keimli's thesis that much of the "emergence" is a property of the local map's fixed points rather than of
interaction/selection; same group. Suggested: "Replicators in BFF are reachable by random walks alone [knierim2026],
consistent with reading them as attractors of the local map." Verified: arXiv abstract page.

**cicala2026** — F. Cicala, E. Niklasson, E. Randazzo, S. Boukortt, A. Basti, M. Etcheverry, R. A. Saurous, B. Laurie,
J. Manyika, B. Agüera y Arcas, B. Richards, "Coevolution of self-replication and function in a digital primordial
soup", arXiv:2607.09211, 2026. 32-byte Z80 programs; task success (polynomial evaluation) raises interaction rate;
replication and function coevolve; metabolic cost selects conditional execution. Relation: adds selection, which
Keimli deliberately lacks. Verified: arXiv.

**jha2026** — K. Jha, F. Cicala, B. Agüera y Arcas, B. A. Richards, N. Jaques, M. Kleiman-Weiner, E. Niklasson,
"Tapes Together Strong: The Co-evolution of Computation and Cooperation", arXiv:2609.10817, 2026. Z80 soups with
energy budgets ("autopoietic game theory"); cooperation among replicators under scarcity. Relation: Z80 lineage,
selection via energy; contrast case. Verified: arXiv.

**kumar2026** — A. Kumar, R. Bahlous-Boldi, P. Sharma, P. Isola, S. Risi, Y. Tang, D. Ha, "Digital Red Queen:
Adversarial Program Evolution in Core War with LLMs", arXiv:2601.03335, 2026. LLM as mutation operator evolving
Redcode warriors in rounds against all predecessors; convergent generalist strategies. Classic 1D core, not spatial.
Relation: the current Core War reference; Keimli emulates Redcode per cell with no selection. Verified: arXiv.

**kumar2024** — A. Kumar, C. Lu, L. Kirsch, Y. Tang, K. O. Stanley, P. Isola, D. Ha, "Automating the Search for
Artificial Life with Foundation Models" (ASAL), arXiv:2412.17799, 2024. Vision-language models score target,
open-ended and diverse simulations across Lenia, Life, NCA, etc. Relation: the automated alternative to Keimli's
swarm/dictionary search (an "interestingness" search over rule space). Verified: arXiv.

**myers2026** — T. D. Myers, S. J. Song, A. Bartko et al., "Prediction and Entropy of Evolving Sequences: A
Transformer-Based Estimator of Functional Information", ALIFE 2026 proceedings, doi:10.1162/isal.a.974. Masked-LM
pseudo-perplexity separates conserved opcode positions in 64-byte BFF replicators. Relation: a learned-compression
measure on BFF; parallels Keimli's use of decoder structure to read which bits matter ("82 unread bits").
Verified: OpenAlex DOI (author list truncated).

**stepney2025** — S. Stepney, "Towards origins of virtual artificial life: an overview", Phil. Trans. R. Soc. B
380(1936), 20240298, 2025, doi:10.1098/rstb.2024.0298. Review of definitions/detection/origination of virtual life.
Relation: the survey a referee will expect; useful for positioning "trivial replication" (fixed points) against
definitions of life. Verified: OpenAlex DOI.

**cotler2025** — J. Cotler, C. Hongler, B. Hudcová, "Self-replication and Computational Universality",
arXiv:2510.08342, 2025. A Turing-universal CA that cannot sustain non-trivial self-replication; translation cost
between dynamics and symbols is part of universality. Relation: supports separating "computation" from "replication"
— Keimli's decoder has neither universality nor non-trivial replication but shows replicator-like domains.
Verified: arXiv.

**kauffman2025** — S. A. Kauffman, A. Roli, "Is the emergence of life and of agency expected?", Phil. Trans. R. Soc. B
380(1936), 20240283, 2025, doi:10.1098/rstb.2024.0283. Cites BFF; theory of spontaneous emergence. Context only.
Verified: OpenAlex DOI.

**norton2026** — C. C. Norton, "Universal Construction and Exact Self-Reproduction in Ternary McCulloch-Pitts
Networks", arXiv:2610.12251, 2026. Fixed threshold network that stores and runs networks; exact von Neumann
self-reproduction; SUBLEQ computer. Relation: a "fixed rule hosts stored programs" construction; non-trivial
replication contrast. Verified: arXiv.

Other BFF citers seen (context only, not recommended): Vimal, Mathis, Weimer, Forrest 2025 "Prebiotic Functional
Programs: Endogenous Selection in an Artificial Chemistry" (IEEE ALIFE Symposium; lambda-calculus AlChemy);
Pigozzi & Levin 2026 arXiv:2607.28250 (causal organisation before replicators); Darlow 2026 ALIFE "Digital
Ecosystems: Interactive Multi-Agent NCA" (doi:10.1162/isal.a.982); Abramsky et al. 2026 R. Soc. Open Sci. "Open
questions about time and self-reference in living systems"; Ashford et al. GECCO 2026 "Symbiogenesis: from Barricelli's
Legacy to Collective Intelligence" (doi:10.1145/3795101.3814707); Tensen et al. 2026 Microcosmos (GPU ALife).
None of them is spatial-decoder-like.

## 6. Spatially varying rules / parameter sweep in one frame

**sipper1997** — M. Sipper, "Evolution of Parallel Cellular Machines: The Cellular Programming Approach", LNCS 1194,
Springer, 1997, doi:10.1007/3-540-62613-1. Non-uniform CA: each cell its own rule, rules coevolved locally (density,
synchronisation tasks); evolved grids become quasi-uniform. Relation: precedent for position-dependent rules; Keimli's
rule is uniform in form but its mixing/settling strength varies by position by design, not evolution.
Suggested: "Position-dependent rules are non-uniform automata in Sipper's sense [sipper1997]; ours vary along a
designed gradient rather than by evolution." Verified: OpenAlex DOI.

**pearson1993** — J. E. Pearson, "Complex Patterns in a Simple System", Science 261(5118), 189–192, 1993,
doi:10.1126/science.261.5118.189. The Gray–Scott (F,k) phase map with pattern classes. Note: Pearson's map and
Munafo's xmorphia (mrob.com, 1996–2024) are mosaics of *separate fixed-parameter runs* — Munafo: "Each grid square
leads to a different page" — not one simulation with varying parameters. The single-frame spatial sweep appears in
Karl Sims' Reaction-Diffusion Tutorial ("Style Map: the feed and kill rates can vary across the grid", karlsims.com/
rd.html) and in teaching exercises (G. Turk, Georgia Tech, "k should vary across the x direction"). Relation:
Keimli's "gradients = parameter sweep in space" has this folk precedent in reaction–diffusion; cite Pearson for the
map and Sims as a web reference, and do not claim the in-frame sweep as new. Verified: OpenAlex DOI (Pearson);
web pages fetched (Munafo, Sims via search snippet).

## 7. Grammatical Evolution forward citations — no threat

844 citing titles of Ryan–Collins–O'Neill 1998 scanned; only CA-related: Abu Dalhoum & Abdel Latif 2004 (Dialnet)
"Genetic evolution and equivalence of some complex systems: fractals, cellular automata and lindenmayer systems" —
uses GE to *evolve* CA/L-system descriptions, the decoder is applied once per individual; plus GE+cellular-encoding
for neural nets (2008). Nothing iterates the GE mapping as a dynamics. The O'Neill–Ryan 2001 citation list could not
be retrieved (rate limit).

## Most important for the paper
1. conway1987 — iterating a codec on strings and censusing survivors is 1987 prior art in spirit; cite it and state the differences (decoder, fixed width, lattice).
2. cox2010 / canet2017 / vanmello2024 — Keimli's fixed points and 2-cycles are decompression quines / looped archives; use that name.
3. knierim2026 — BFF replicators found by random walks alone; supports "replicators are attractors of the local map".
4. dingle2018 (+ dingle2024, hamzi2024) — simplicity bias of many-to-one maps; the theory behind the 93.5-bit image and attractor frequencies.
5. flajolet1990 — random-mapping null model for the attractor census.

## Threats to novelty
- No direct threat found: no publication uses an LZ77/Brotli-like (or any) decompressor as the iterated per-cell rule of a lattice.
- Partial: decompression quines (cox2010, canet2017, vanmello2024) mean "fixed points of a DEFLATE decoder exist and can be built" is not new; Keimli must claim the dynamics/census/lattice, not the existence of decoder fixed points.
- Partial: Conway's audioactive decay already iterates a coding map and gives a "chemistry" of persistent elements; the thesis framing ("a codec iterated is analysable where a CPU is not") should acknowledge it.
- Partial: neural-CA image codecs (falcao2025, and growing-NCA generally) join CA and decoding, in the reverse direction.
- Spatial parameter sweeps in one frame are folk practice in reaction–diffusion (Sims' style map); do not claim them as new.
- The CPU-per-cell mode is a direct generalisation of BFF/Z80 2D soups (agueraYarcas2024) — novelty there is breadth (25 ISAs) and the mixing/settling stages, not the idea.

## Could not verify
- Google Scholar forward citations (throttled; reported "cited by 1" for BFF, clearly wrong).
- O'Neill & Ryan 2001 forward citations (Semantic Scholar rate limit).
- Pages for williams2011; journal pages for zenil2010 (Complex Systems 19(1)); venue of lathrop1996.
- Full author list for myers2026 beyond first three.
- Erling Ellingsen's earlier zip quine (mentioned in vanmello2024; no primary source found).
- Whether any 2026 ALIFE paper runs a spatial decoder lattice (proceedings not searchable in full text).
