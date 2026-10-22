# Thread C: computational artificial life and replication

The question for each work is how it **supports (S)** or **limits (L)** the claim that the "replicators" seen in
program substrates may be fixed points or short cycles of a local map rather than products of computation.

## C0. Corrections to existing references.bib entries (see C.bib, Part 1, for replacements)
- **dewdney1984**: correct; now verified, DOI 10.1038/scientificamerican0584-14 added (250(5) 14–22).
- **ray1991**: pages 371–408 and editors confirmed on Ray's own publication list. No DOI. SFI series volume given as X or XI in different sources; the book was printed in 1992. Now `partly`.
- **adami1994**: title has quotation marks around "Avida". arXiv adap-org/9405003 added. Pages 377–381 come only from secondary citations, so `partly`.
- **lenski2003**: correct; issue 6936 and DOI 10.1038/nature01568 added. Now `yes`.
- **pargellis2001**: volume and pages are right (7(1) 63–75); DOI added. Now `yes`. The 2017 follow-up in the note is real: greenbaum2017.
- **koza1994**: pages 225–262 confirmed by the GP Bibliography; SFI volume XVII. Changed to @incollection, `partly` (there is no DOI).
- **fontana1994**: this is "Arrival of the fittest" (Bull. Math. Biol. 56(1) 1–64), which is correct. DOI added. The PNAS "tape played twice" paper is a different work, now added as **fontana1994b**.
- **dittrich2001**, **hutton2002**: correct; DOIs added. hutton2002 *is* the Squirm3 paper.
- **ackley2011**: correct; confirmed on the USENIX HotOS XIII page. There are no page numbers.
- **agueraYarcas2024**: the eight-author list and its order are now confirmed on arXiv, so it is `yes`. v1 27 Jun 2024, v2 2 Aug 2024, no journal reference. The 2026 follow-up named in the note (2607.01483) exists: knierim2026.

## C1. Program substrates: the classic systems
**dewdney1984** — Dewdney, Sci. Am. 250(5):14–22, 1984.
Introduced Core War (Redcode). The one-instruction "Imp" (`MOV 0,1`) copies itself one cell ahead forever.
Relation: **S**, strongly. The canonical first replicator in the canonical substrate is a one-instruction fixed point of a shift (a travelling wave), with no loop and no test. Keimli emulates Redcode, so this is a direct anchor.
Cite: "Core War's oldest replicator, the Imp, is a single instruction that copies itself one cell ahead, a fixed point up to translation [dewdney1984]."
Verified: Crossref DOI 10.1038/scientificamerican0584-14.

**rasmussen1990** — Rasmussen, Knudsen, Feldberg, Hindsholm, "The coreworld…", Physica D 42:111–134, 1990.
A Redcode-like "computational chemistry" started from random code, with no seeded ancestor. Cooperative structures emerged, among them MOV-based self-copiers and parasitic chains.
Relation: **S**. This is the first "replicators from random code" result, and it is in Core War. The structures it reports are mostly short MOV loops and spreads; it predates BFF by 34 years. It gives Keimli the vocabulary of a "computational chemistry".
Cite: "Random Redcode already yields self-copying and cooperative structures [rasmussen1990]."
Verified: Crossref.

**ray1991** — Tierra. Seeded with an 80-instruction hand-written ancestor; parasites, hyper-parasites and size shrinkage evolved.
Relation: **L** for "replicators are trivial". Tierra's replicators run a genuine copy loop that has to find its own boundaries. **S** for Keimli's framing, though, because Tierra *seeds* replication and never shows it emerging. Cite it as the paradigm in which replication is given and selection is studied.
Verified: author's site tomray.me/pubs (no DOI).

**adami1994**, **ofria2004** — Avida (2D Tierra variant; Ofria & Wilke, Artif. Life 10(2):191–229, 2004).
Avida is the standard platform: replication by an ancestor's copy loop, plus tasks that are rewarded.
Relation: neutral to **L**. Replication is engineered. Its value to Keimli is as the "computation" end of the spectrum: logic tasks (EQU) need real computation.
Verified: ofria2004 via Crossref; adami1994 via arXiv adap-org/9405003.

**lenski2003** — Nature 423:139–144.
Complex functions (EQU) evolve through cumulative intermediate steps.
Relation: **L**. This is the clearest case of rich phenomena produced by computation in program substrates, which Keimli by construction cannot show. It belongs on the "finesse of computation" side of the thesis.
Cite: "Where selection rewards computation, as in Avida, complex functions arise stepwise [lenski2003]; a decoder has no such ladder."
Verified: Crossref.

**wilke2001** — "Survival of the flattest", Nature 412:331–333.
At high mutation rates, a lower-fitness but mutationally robust (flat) quasispecies outcompetes a fitter, narrow one.
Relation: **S** by analogy, and useful. It is the program-substrate precedent for Keimli's finding that the winning attractor is set by the medium's noise rather than by basin size, and that fixed-point domains survive noise that melts cycle domains. Robustness beats raw replication rate.
Cite: "As in survival of the flattest [wilke2001], which attractor wins depends on the noise of the medium, not on how fast or how often it is reached."
Verified: Crossref.

**koza1994** — Artificial Life III 225–262.
Self-replicating Lisp-like programs emerge from random program sets, using template-matching side effects.
Relation: **S**. An early "emergence from random code" claim in which the replicators are short template-copy idioms.
Verified: GP Bibliography record (no DOI).

**pargellis2001**, **greenbaum2017** — the Amoeba world (Artif. Life 7(1):63–75; Greenbaum & Pargellis, Artif. Life 23(3):318–342, 2017).
Self-replicators arise spontaneously from random instruction sequences in a Tierra-like CPU world. The 2017 paper describes a "self-organizing prebiotic" phase that comes before them.
Relation: **S**. This is the closest pre-BFF analogue of spontaneous emergence. The emergent replicators are short and simple, and the prebiotic phase looks like a medium settling, not like computation.
Verified: Crossref for both.

**nitash2017** — C G, LaBar, Hintze, Adami, "Origin of life in a digital microcosm", Phil. Trans. R. Soc. A 375:20160350, 2017.
Generated the **exhaustive set of minimal-genome Avida self-replicators**, analysed the network of that fitness landscape, and competed the replicators in a soup. Which ancestor wins is non-uniform: winners cluster in a small region of replicator space.
Relation: **S**, and it gives Keimli a method. It is the nearest precedent for Keimli's *census* of fixed points and cycles. Like Keimli, it finds the winner is not set by simple abundance. The difference is that Avida needs a fully enumerated copy machine, while Keimli's census is of a linear-time map.
Cite: "Exhaustive enumeration of minimal replicators has been done in Avida [nitash2017]; for a decoder the census covers every fixed point and cycle, not just one genome length."
Verified: Crossref and the Europe PMC abstract.

**labar2016** — LaBar, Hintze, Adami, Artif. Life 22(4):483–498.
Emergent (randomly assembled) Avida replicators fall into two functional classes with an evolvability trade-off.
Relation: **S/L**. Replicator classes differ in what they can become. Keimli's analogue is the difference between fixed points and cycles. Use it as vocabulary.
Verified: Crossref.

**adami2017** — Adami & LaBar, "From entropy to information: biased typewriters…", in *From Matter to Life*, CUP, 130–154.
The probability that a self-replicator arises by chance rises enormously when the monomer distribution is biased.
Relation: **S**. Biased sampling, not computation, makes replicators likely. knierim2026 cites it, and it matches their finding that BFF-biased random strings beat the soup.
Verified: Crossref.

**hutton2002** — Squirm3 (Artif. Life 8(4):341–356).
Template replication of atom strings in a 2D artificial chemistry, via hand-designed reactions.
Relation: **S** by contrast. In Squirm3, replication is a property of the reaction rules (template copying), not of a program. It is a precedent for a "replicator" being a property of the local rule.
Verified: Crossref.

**ackley2011** — the Movable Feast Machine and "robust-first" computing.
Relation: neutral. It is a spatial, indefinitely scalable substrate in which local rules are robust to noise, which is close to Keimli's lattice ethos. Cite it alongside the spatial BFF variants.
Verified: USENIX.

**ierymenko2005** — Nanopond (software, about 2005).
A tiny Tierra-like virtual-machine pond with a 4-bit instruction set. Popular, but unpublished.
Relation: weak **S** (short self-copy loops dominate). Cite only as software if at all.
Verified: partly (AUR package listing only).

## C2. Emergence of replicators in program soups (BFF lineage, 2024–2026)
**agueraYarcas2024** — Computational Life, arXiv:2406.19108 (8 authors). Precise details, verified from the arXiv HTML v2:
- **BFF soup.** 2^17 tapes of 64 bytes, random pairs concatenated, run for at most 2^13 steps, then split. Default mutation rate 0.024%.
- **BFF emergence.** About 40% of runs show a state transition within 16k epochs, roughly the same without mutation. In short 128-epoch random runs, 3 of 1000 transitioned; seeding raised this to 22%.
- **High-order entropy.** Shannon entropy minus normalised Kolmogorov complexity, the latter approximated by brotli -q2.
- **Zero-poisoning.** A zero-poisoning phase follows the first replicator.
- **2D variant.** A 240×135 grid with interaction radius 2; replicators spread at a speed proportional to the grid side.
- **Long-tape variants.** On a 64 KiB tape with no head offset, *trivial non-looping replicators* take over. Looping replicators need an offset greater than about 8.
- **Forth.** A *one-byte* replicator exists, and almost all runs transition within 1k epochs.
- **SUBLEQ and RSUBLEQ4.** Hand-written replicators exist (60 and 25 bytes), but none emerge from random starts.
- **Z80.** A 2D grid of 16-byte programs: stack-push replicators come first, then LDIR/LDDR copiers.
- **8080.** Long-tape replicators are two-byte repeats (e.g. `01 c5`) and never loop.

Relation: **S**, strongly, from the paper itself. The first replicators in Forth, 8080 and long-tape BFF are one- or two-byte trivial copies, which are fixed points of the interaction map up to shift. **L** for BFF in the soup, where the dominant replicators are looping copy programs. Keimli should present itself as isolating the trivial-replicator regime that this paper already observed.
Cite: "Even in the computational-life experiments, the first replicators are often one or two bytes long and do not loop [agueraYarcas2024]."
Verified: arXiv abstract and HTML.

**knierim2026** — Knierim, Versari, Obryk, Agüera y Arcas, Saurous, "BFF: simple explanations for complex phenomena", arXiv:2607.01483.
- **Random walks beat the soup.** Pure mutation random walks with no interaction find BFF self-replicators *as fast or faster* than the soup:
  - soup: about 5×10^6 programs tested;
  - uniform random strings: 2.9×10^7;
  - strings drawn from BFF-written bytes: 1.7×10^6;
  - strings drawn from operator-biased byte distributions: 4.5×10^5 to 9.4×10^4.
- **The detector is a fixed-point test.** The program is placed in noise, run through chained iterations, and must reappear (score ≥ 48 of 64). Odd-length chains catch self-inverting (period-2) replicators.
- **Ancestry caps.** Capping ancestry depth or width stops takeover, not emergence.

Relation: **S**, the strongest support in the literature. Interaction, and therefore computation between programs, is not what produces replicators: biased sampling of a byte distribution is enough. The field's own detector operationalises "replicator" as an approximate fixed point or 2-cycle of the run-in-noise map, which is exactly Keimli's definition. It does not mention decoders or compression as the map.
Cite: "Replicators in BFF are found faster by biased random sampling than by soup interaction, and are detected as fixed points of running a program in noise [knierim2026]."
Verified: arXiv API and HTML v1.

**cicala2026** — Cicala et al., "Coevolution of self-replication and function in a digital primordial soup", arXiv:2607.09211.
Random 32-byte Z80 programs. A polynomial-evaluation task raises interaction probability, and self-replication and task-solving coevolve. Metabolic (runtime) costs select for conditional execution.
Relation: **L**, but it clarifies the thesis. Once tasks are coupled in, the computational side matters: real computation appears only where it is rewarded. That is consistent with Keimli's two-source split.
Verified: arXiv abstract.

**jha2026** — Jha et al., "Tapes together strong: the co-evolution of computation and cooperation", arXiv:2609.10817.
"Autopoietic game theory" on Z80 soups. Energy-limited execution makes stealing self-limiting, and cooperative replicators emerge.
Relation: **L/neutral**. Rich ecology comes from coupling compute to energy. Shows the 2026 direction of the BFF group.
Verified: arXiv abstract.

**sarkar2020** — Sarkar, "The computational inevitability of life…", arXiv:2010.09646 (v2, Jan 2026).
Argues from algorithmic information theory that, under resource bounds, quines are *stable fixed points* of nested algorithmic probability and act as attractors in program space.
Relation: **S** at the theory level, and a partial **novelty threat** to the framing "replicators are fixed points". It is abstract, not peer-reviewed and makes no lattice census, but Keimli should cite it as a related theoretical claim.
Verified: arXiv.

**randazzo2021** — Randazzo, Versari, Mordvintsev, "Recursively fertile self-replicating neural agents", ALIFE 2021.
Neural networks that output their own weights (neural quines) and remain fertile over generations.
Relation: **S**. The same group frames replication as a weight fixed point (a quine) and shows that fertility needs more than the fixed point.
Verified: Crossref DOI 10.1162/isal_a_00367.

## C3. Core War and machine-code evolution
**corno2004**, **corno2005**, **sanchez2006** — µGP evolution of Core War warriors (CEC 2004, 133–138; IEEE TEC 9(6):695–706; CIG 2006, 272–278).
The first machine-written warriors to reach King of the Hill on all four main Tiny Hills. The nano-core work rediscovered the champion's structure and found a self-modifying strategy.
Relation: **L/neutral**. These use explicit fitness (battles). Strong warriors are often bombers and imps or paper-style replicators, i.e. short copy loops. A method precedent for Keimli's Redcode changer.
Verified: Crossref; the TEC abstract on iris.polito.it.

**kumar2026** — Digital Red Queen, arXiv:2601.03335 (MIT and Sakana AI).
An LLM evolves Redcode warriors by self-play against all previous winners. Generality rises, cross-run diversity falls, and strategies include bombing, self-replication and multithreading.
Relation: neutral. A 2026 sign that Core War is current again. Its replicators are designed by an LLM, not emergent.
Verified: arXiv API and project page.

**nordin1994**, **schulte2013** — evolution acting directly on real machine code (Nordin's CGPS; Schulte et al. on binary and assembly repair, ASPLOS 2013, 317–328).
Relation: neutral. These show real x86/ARM code is evolvable under fitness. Neither concerns spontaneous replication. Cite only if the paper discusses emulated real CPUs as substrates.
Verified: Crossref (nordin1994 page numbers missing).

## C4. Definitions and theory of replication and heredity
**langton1984** — Physica D 10:135–144.
The self-reproducing loop. Langton separates trivial self-reproduction (a crystal, or a pattern copied by the physics) from reproduction in which the information is actively used, both interpreted and copied.
Relation: **S**. This is the definition the paper rests on. It is missing from references.bib.
Verified: Crossref.

**sipper1998** — Artif. Life 4(3):237–257.
Fifty-year survey of self-replication (von Neumann, Langton loops, programs, hardware), including the trivial vs non-trivial distinction.
Relation: **S**, as a vocabulary source.
Verified: Crossref.

**adams2009** — Adams & Lipson, Entropy 11(2):295–325.
A universal framework that gives self-replication a graded *measure*, in place of a yes/no definition, based on how much the replicator versus the environment contributes.
Relation: **S**, and it gives a method. Keimli's replicators would score near zero "self" contribution, because the decoder (the environment) does the copying. Usable as a quantitative way to say "trivial".
Verified: Crossref.

**freitas2004** — *Kinematic Self-Replicating Machines*, Landes Bioscience.
A taxonomy of replicator design dimensions, among them how much of the copying is done by the environment versus the replicator.
Relation: **S**, as vocabulary.
Verified: CiNii record.

**eigen1971**, **eigen1979** — the error threshold, quasispecies and the hypercycle.
Heredity needs copying fidelity above a threshold set by sequence length. The hypercycle couples replicators in a cycle.
Relation: **S/L**. Keimli's domains persist below a noise threshold and melt above it (cycles first), which is an error-threshold-like phenomenon without copying. The hypercycle is a separate, named notion of "cycle"; avoid confusing it with Keimli's map cycles.
Verified: Crossref.

**price1970** — the Price equation, Nature 227:520–521.
Relation: neutral and formal. Selection is a covariance between trait and fitness, and heredity is the parent-offspring regression. It gives a clean test: Keimli has "fitness" (domain growth) but heredity only in the sense of a fixed point. Use it if the paper defines what is missing.
Verified: Crossref.

**maynardsmith1995** — *The Major Transitions in Evolution*.
Distinguishes limited heredity (few possible states) from unlimited heredity.
Relation: **S**, strongly. Keimli's attractors give **limited heredity**: a small census of fixed points and cycles. That is exactly Maynard Smith and Szathmáry's category for pre-genetic replicators, and it gives the paper vocabulary.
Cite: "Fixed points of the local map provide only limited heredity in the sense of [maynardsmith1995]."
Verified: partly (OUP 1997 reissue DOI).

**fontana1994**, **fontana1994b** — AlChemy (lambda-calculus chemistry; Bull. Math. Biol. 56(1):1–64; PNAS 91(2):757–761).
In AlChemy, the first organisations are copying "level 0" self-replicators. When copying is disabled, self-maintaining organisations appear and are conserved across replays.
Relation: **S**. Self-copiers dominate unless copying is forbidden, and the identity and copy functions are the trivial attractors of a functional map. This is the conceptual ancestor of "replicators as fixed points of the interaction operator". BFF calls its soup a variant of Fontana's Turing gas.
Verified: Crossref for both.

**hordijk2004** — RAF autocatalytic sets (J. Theor. Biol. 227(4):451–461).
Relation: neutral, as vocabulary. Collective self-maintenance in which no single member replicates. Contrast it with Keimli's single-cell fixed points, and with cycles that are collective in phase rather than in chemistry.
Verified: Crossref.

## C5. Open-endedness framing
**taylor2016** — Artif. Life 22(3):408–423 (25 authors). **packard2019** — Artif. Life 25(2):93–103.
Both define open-ended evolution (OEE) and its hallmarks, and both note that most systems plateau.
Relation: **S**. Keimli's deterministic freezing and finite census of attractors are a clean, analysable *non*-open-ended case. Cite these to say so explicitly.
Verified: Crossref for both.

## C6. Cellular-automaton and neural-CA replication (recent)
**sayama2025** — "25 years after evoloops", Artif. Life 31(1):81–95.
Review of evolving self-reproducing CA patterns.
Relation: **S**, as context. CA replication research mostly designs non-trivial replicators. Keimli sits at the trivial end, with a census.
Verified: Crossref and arXiv.

**plantec2025** — Flow-Lenia, Artif. Life 31(2):228–248.
Mass conservation plus parameters stored locally in the field give multi-species evolutionary dynamics.
Relation: neutral. A close cousin of "the parameters are in the field": Keimli varies parameters in space, but by the experimenter, not by heredity.
Verified: Crossref.

**sinapayen2023** — ALIFE 2023.
Self-replicating neural-CA patterns acquire inheritable mutations without being trained for them.
Relation: neutral to **L**.
Verified: Crossref and arXiv.

**jain2026** — arXiv:2609.19902.
Neural-network agents clone into neighbours. There is a phenotype-versus-genotype diversity trade-off.
Relation: neutral, and peripheral.
Verified: arXiv.

**kumar2025** — ASAL, Artif. Life 31(3):368–396.
Foundation models (CLIP) search Lenia, Boids, Life-like CAs and others for target, open-ended and diverse behaviour.
Relation: gives a method. A plausible future tool for searching Keimli's dictionary and parameter space, and a referee may ask about it.
Verified: Crossref DOI 10.1162/artl.a.8.

---
## Most important for the paper
1. **knierim2026**: replicators are found faster by biased random sampling than by soup interaction, and the BFF detector is itself a fixed-point/2-cycle test. This is the strongest support for "replicators ≠ products of computation".
2. **agueraYarcas2024**: its own data shows trivial one- or two-byte non-looping replicators in Forth, 8080 and long-tape BFF. Cite those precise details.
3. **langton1984** with **adams2009**: the trivial vs non-trivial definition, plus a graded measure of how much the environment does the copying. Add langton1984 to the bib.
4. **maynardsmith1995** with **wilke2001**: limited heredity, and robustness (flatness) beating fitness under noise, are the right vocabulary for Keimli's fixed-point-vs-cycle and medium-decides findings.
5. **nitash2017**: an exhaustive census of minimal Avida replicators, in which winners are not set by abundance. This is the closest methodological precedent for Keimli's census.

## Threats to novelty
- **sarkar2020 (v2, 2026)** states in AIT terms that self-replicating programs are fixed points and attractors of resource-bounded program dynamics. It is theory only, with no CA, no decoder and no census, but the phrase "replicators as fixed points" is no longer new. Cite it and differentiate.
- **knierim2026** already argues that BFF replicators have "simple explanations" and uses a fixed-point detector. Keimli's novelty is the decompressive map, the full census and design of attractors, and the spatial medium results, not the deflationary claim itself.
- **fontana1994/fontana1994b** (AlChemy): self-copy (identity-like) functions as the default attractors of an interaction operator. That is conceptually close, and should be acknowledged as the ancestor of the framing.
- **nitash2017**: exhaustive census of replicators already done for Avida (one genome length, not a full map census).
- I found nothing that uses an LZ77 or Brotli decoder (or any decompressor) as a CA or soup rewrite rule. The searches covered the arXiv API and web searches on BFF follow-ups, NCA replication, Core War evolution and quine emergence. The arXiv API was rate-limited partway through, so some planned queries (e.g. "quine emergence", "Core War evolution" on arXiv) were not completed.

## Could not verify
- Mordvintsev/Randazzo work on BFF after 2024, other than knierim2026 and cicala2026 (Randazzo is a co-author of cicala2026). No separate paper found.
- A dedicated "thermodynamics of BFF replicators" or "what counts as a replicator" paper (2025–2026): none found.
- "Tierra on x86" and "evolving x86 self-replicators": no peer-reviewed source found. Nanopond exists only as software (ierymenko2005, partly).
- Page numbers for nordin1994 and adami1994 are not confirmed against the printed volumes. ray1991's SFI volume number (X or XI) is ambiguous.
- maynardsmith1995 first-edition publisher was checked only indirectly. wilke2001's second-author given name and adami2017's editors are from memory.
- No "Adams & Lipson self-replication measure" journal paper beyond adams2009 (Entropy 2009); the 2003 ECAL version (LNCS, doi 10.1007/978-3-540-39432-7_1) exists but was not added.
