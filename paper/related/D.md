# Thread D — discovery methods, continuous/neural automata, rule-space exploration

Verification sources used in this session: Crossref API records (DOI, venue, volume, pages, author order),
arXiv abstract pages / arXiv API, NeurIPS proceedings page, O'Reilly page, Google Research page,
mrob.com (Munafo), complex-systems.com. "Verified" below means one of these was seen in this session.

## D1. Corrections to existing entries in references.bib

- **chan2019** — OK as is (Complex Systems 28(3):251–286, DOI 10.25088/ComplexSystems.28.3.251, arXiv 1812.05433). Not re-fetched; existing record left as verified.
- **chan2020** — FIX: now verified. Chan, B. W.-C., "Lenia and Expanded Universe", ALIFE 2020 (The 2020 Conference on Artificial Life), MIT Press, pp. 221–229, DOI 10.1162/isal_a_00297, arXiv 2005.03742 (Crossref + arXiv).
- **mordvintsev2020** — FIX: verified; add volume 5, number 2 (Distill, 11 Feb 2020), DOI 10.23915/distill.00023 (Crossref).
- **reinke2020** — OK (ICLR 2020, arXiv 1908.06663), existing record.
- **plantec2023** — FIX: it is a conference paper, not an article. ALIFE 2023 proceedings, DOI 10.1162/isal_a_00651, author order Plantec, Hamon, Etcheverry, Oudeyer, Moulin-Frier, Chan. The *journal* version is a separate paper with a different title and author order → new key **plantec2025** (Artificial Life 31(2):228–248, DOI 10.1162/artl_a_00471, order Plantec, Hamon, Etcheverry, Chan, Oudeyer, Moulin-Frier).
- **lehman2011** — FIX: verified; add DOI 10.1162/evco_a_00025 (Evolutionary Computation 19(2):189–223).
- **mouret2015** — verified: arXiv 1504.04909, submitted 20 Apr 2015, comment "Early draft", no journal ref. Keep as @misc.
- **pugh2016** — FIX: verified; add DOI 10.3389/frobt.2016.00040 (Frontiers in Robotics and AI 3; article 40).
- **schmidhuber2009** — FIX: verified as book chapter, Anticipatory Behavior in Adaptive Learning Systems (LNCS), pp. 48–76, Springer 2009, DOI 10.1007/978-3-642-02565-5_4. The LNAI volume number 5499 was not shown in the record I saw — keep it marked "to confirm".
- **sayama2009** — add DOI 10.1162/artl.2009.15.1.15107 (Artificial Life 15(1):105–114).
- **stanley2017** — FIX: verified; O'Reilly Radar, 19 December 2017, authors Stanley, Lehman, Soros, URL https://www.oreilly.com/radar/open-endedness-the-last-grand-challenge-youve-never-heard-of/ . Should be @misc (not peer reviewed).

Corrected versions of these entries are included in D.bib under the same keys; replace the old ones.

## D2. Lenia and its follow-ups (continuous CA)

**chan2020** — Chan, B. W.-C. (2020). Lenia and expanded universe. *ALIFE 2020*, pp. 221–229. MIT Press.
Extends Lenia to multiple kernels and channels and higher dimensions; finds individuality, self-replication, emission and growth by ingestion among patterns found by hand and by semi-automated search.
Relation: the ALife reference for "a gallery of named organisms found by a person exploring a rule space"; Keimli's swarm-search-plus-eye-selection is the same practice. Lenia's self-replication is morphological, not template-based; useful contrast with Keimli's trivial (fixed-point) replication.
Cite: "Like Lenia's gallery of organisms [chan2019, chan2020], Keimli's named dictionaries were found by a search followed by inspection."
Verified: https://doi.org/10.1162/isal_a_00297 ; arXiv 2005.03742.

**chan2023** — Chan, B. W.-C. (2023). Towards large-scale simulations of open-ended evolution in continuous cellular automata. *GECCO '23 Companion*, pp. 127–130. ACM. DOI 10.1145/3583133.3590670; arXiv 2304.05639.
Proposes extending Lenia with spatially localised, heritable rule parameters so that different regions carry different rules and selection can occur — a large-scale OEE design programme.
Relation: closest Lenia work to "parameters vary in space". In Chan's design the parameter field is a genome that moves with the matter; in Keimli the gradient is a fixed experimental sweep. Worth one sentence to prevent the referee conflating the two.
Cite: "Spatially varying parameters have been proposed as heritable traits in continuous CA [chan2023, plantec2025]; our gradients are fixed and serve only as a sweep."
Verified: Crossref + arXiv.

**plantec2023 / plantec2025** — Plantec, E. et al. (2023). Flow-Lenia: towards open-ended evolution in cellular automata through mass conservation and parameter localization. *ALIFE 2023*. DOI 10.1162/isal_a_00651. Journal version: Plantec, E., Hamon, G., Etcheverry, M., Chan, B. W.-C., Oudeyer, P.-Y., Moulin-Frier, C. (2025). Flow-Lenia: emergent evolutionary dynamics in mass conservative continuous cellular automata. *Artificial Life* 31(2):228–248. DOI 10.1162/artl_a_00471.
Mass-conserving Lenia whose update parameters are carried by the matter (parameter localisation), so several "species" with different rules coexist and compete in one simulation.
Relation: Flow-Lenia shows that putting different parameters in different places makes *interaction between parameter regimes* part of the dynamics — exactly why Keimli's frame and uniform runs pick different winners. Keimli's settling is not mass-conserving; bit-mixing is (it trades bits), a point of contact.
Cite: "As in Flow-Lenia, where localised parameters let rule regimes meet and compete [plantec2025], a frame with spatial gradients is a coupled system, not a set of independent uniform runs."
Verified: Crossref both DOIs.

**mordvintsev2022particle** — Mordvintsev, A., Niklasson, E., Randazzo, E. (2022, 23 Dec). Particle Lenia and the energy-based formulation. Google Research, self-organising-systems blog.
Lenia rewritten for particles moving down an energy gradient; simple local energy gives rich motile and multi-part creatures.
Relation: marginal; shows the "Lenia family" breadth. Optional citation.
Verified: https://google-research.github.io/self-organising-systems/particle-lenia/ (title, authors, date).

**hudcova2026** — Hudcová, B., Dušek, F., Tuccio, M., Hongler, C. (2026). Visualizing the structure of Lenia parameter space. arXiv 2601.01932.
Automatic classification of Lenia systems into four dynamical classes, interactive map of parameter space; soliton families found in regions not previously thought to hold them.
Relation: the current state of "parameter maps" for continuous CA. Their map is assembled from independent uniform runs; Keimli's frame is one coupled run. Good foil for the frame ≠ sweep point.
Cite: "Parameter maps of continuous CA are built from independent runs [hudcova2026]; ours is a single coupled run, which we show can differ."
Verified: arXiv abstract page.

## D3. Automated discovery (IMGEP, diversity search, foundation models)

**reinke2020** — (existing) IMGEP on Lenia: goal-exploration with learned goal spaces finds more diverse patterns than random search.
Relation: the method the swarm search approximates by hand (RELATED_WORK.md, row D). Keep.

**etcheverry2020** — Etcheverry, M., Moulin-Frier, C., Oudeyer, P.-Y. (2020). Hierarchically organized latent modules for exploratory search in morphogenetic systems. *NeurIPS 33* (oral). arXiv 2007.01195.
Argues "interesting" diversity is observer-dependent ("meta-diversity"); a monolithic behaviour embedding biases discovery; a hierarchy of learned representations lets a user steer search with little feedback. Applied to Lenia.
Relation: gives vocabulary for an honest admission — Keimli's hand-made score plus "by eye" selection is a single, observer-defined behaviour descriptor; Etcheverry et al. show such a descriptor biases what is found. Supports the panel's demand to re-evaluate dictionaries under several conditions.
Cite: "Discoveries made with one hand-designed descriptor are biased by it [etcheverry2020]; we therefore re-evaluate every named dictionary under uniform parameters, several seeds and both swap orders."
Verified: NeurIPS proceedings page https://proceedings.neurips.cc/paper/2020/hash/33a5435d4f945aa6154b31a73bab3b73-Abstract.html ; arXiv.

**hamon2025** — Hamon, G., Etcheverry, M., Chan, B. W.-C., Moulin-Frier, C., Oudeyer, P.-Y. (2025). Discovering sensorimotor agency in cellular automata using diversity search. *Science Advances* 11(44): eadp0834. DOI 10.1126/sciadv.adp0834; arXiv 2402.10236 (2024).
Diversity search plus gradient descent in Lenia finds localised, moving "agents" that maintain integrity under obstacles — sensorimotor agency emerges from local rules found by search.
Relation: the strongest recent example of search finding qualitatively rich behaviour in a CA. Keimli's search finds fixed points and short cycles; contrasting the two supports the thesis that rich behaviour needs more than a many-to-one map (a continuous, differentiable rule here; computation in Core War/BFF).
Cite: "Diversity search in Lenia finds agent-like entities [hamon2025]; the same kind of search over decoder dictionaries finds only fixed points and short cycles."
Verified: Crossref (note: published 2025, not 2024).

**kumar2025** — Kumar, A., Lu, C., Kirsch, L., Tang, Y., Stanley, K. O., Isola, P., Ha, D. (2025). Automating the search for artificial life with foundation models. *Artificial Life* 31(3):368–396. DOI 10.1162/artl.a.8; arXiv 2412.17799.
ASAL: vision-language foundation-model embeddings score simulations for (1) a target phenomenon, (2) open-ended temporal novelty, (3) illumination of diverse simulations; applied to Boids, Particle Life, Game of Life, Lenia, NCA; finds Life-like CA "open-ended like Conway's Life".
Relation: makes Keimli's hand-made score look dated; a referee may ask "why not ASAL?". Answer: Keimli's rule is analysable, so for the designed dictionaries the attractors are enumerated rather than searched. Also an obvious future-work hook (ASAL's illumination over dictionaries).
Cite: "Search over ALife rule spaces is now automated with foundation-model scores [kumar2025]; Keimli's searches used a hand-made score, but its decoder rule also allows what such searches cannot: building the attractors by construction."
Verified: Crossref; arXiv.

**faldor2024** — Faldor, M., Cully, A. (2024). Toward artificial open-ended evolution within Lenia using quality-diversity. *ALIFE 2024*. DOI 10.1162/isal_a_00827; arXiv 2406.04235.
Leniabreeder: MAP-Elites and AURORA (unsupervised QD) over Lenia parameters; claims a diverse, growing repertoire of self-organising patterns.
Relation: the direct "QD over a CA rule space" precedent; Keimli's swarm search is a single-objective search with diversity enforced only by the swarm, not QD. Say so.
Cite: "Unlike quality-diversity searches over Lenia [faldor2024], our swarm search optimised one scalar score."
Verified: Crossref; arXiv.

**grillotti2022** — Grillotti, L., Cully, A. (2022). Unsupervised behavior discovery with quality-diversity optimization. *IEEE TEVC* 26(6):1539–1552. DOI 10.1109/TEVC.2022.3159855.
AURORA: QD with learned behaviour descriptors. Optional, supporting faldor2024.
Verified: Crossref.

## D4. Quality-diversity, novelty, interactive evolution

**mouret2015, pugh2016, lehman2011, stanley2017** — (existing; corrected) MAP-Elites; QD survey; novelty search; open-endedness essay. Relation unchanged: the swarm search must be positioned against QD (it is not one). Suggested citation: "The swarm search is an objective search with a hand-made score; quality-diversity methods [mouret2015, pugh2016] and novelty search [lehman2011] would illuminate the dictionary space instead of optimising it."

**sims1991** — Sims, K. (1991). Artificial evolution for computer graphics. *Computer Graphics (SIGGRAPH '91)* 25(4):319–328. DOI 10.1145/127719.122752.
Interactive evolution where a human selects images by eye (including reaction-diffusion textures).
Relation: the honest precedent for "selected by a hand-made score ... and by eye". Gives vocabulary: Keimli's dictionary selection is partly interactive evolution.
Verified: Crossref.

**secretan2011** — Secretan, J., Beato, N., D'Ambrosio, D. B., Rodriguez, A., Campbell, A., Folsom-Kovarik, J. T., Stanley, K. O. (2011). Picbreeder: a case study in collaborative evolutionary exploration of design space. *Evolutionary Computation* 19(3):373–403. DOI 10.1162/EVCO_a_00030.
Relation: optional; human-selection as open-ended search; aligns with the author's stated taste-driven choice of default dictionary ("a different picture beats a higher score").
Verified: Crossref.

**sayama2009, schmidhuber2009** — (existing; corrected) Swarm Chemistry (interactive evolution of particle swarms); compression-progress as interestingness. Unchanged relation.

## D5. Rule-space search for interesting discrete CA

**packard1985** — Packard, N. H., Wolfram, S. (1985). Two-dimensional cellular automata. *J. Stat. Phys.* 38(5–6):901–946. DOI 10.1007/BF01010423.
First systematic survey of 2D totalistic/outer-totalistic rule spaces, classifying behaviours; growth shapes, entropies.
Relation: the base reference for "surveying a 2D rule space by simulation". Keimli's dictionaries are a rule space too, but one indexed by a byte string.
Verified: Crossref.

**eppstein2002** — Eppstein, D. (2002). Searching for spaceships. In *More Games of No Chance*, MSRI Publications 42, pp. 433–453. arXiv cs/0004003.
Algorithms (graph/state-space search) for finding spaceships in Life-like rules — search for patterns within a fixed rule.
Relation: Keimli's census of fixed points and cycles of the decoder is the same task (find all small periodic patterns of a rule) made trivial because the local map is per-cell. Good contrast: in Life the search is hard because patterns are spatially extended; in Keimli's REWRITE the cycle census is per-cell.
Cite: "Finding periodic patterns of a Life-like rule is a hard search [eppstein2002]; for a per-cell decoder, the fixed points and cycles of the local map can be enumerated."
Verified: arXiv cs/0004003 (journal-ref lists MSRI 42, pp. 433–453).

**eppstein2010** — Eppstein, D. (2010). Growth and decay in Life-like cellular automata. In Adamatzky (ed.), *Game of Life Cellular Automata*, Springer, pp. 71–97. DOI 10.1007/978-1-84996-217-9_6.
Classifies Life-like (B/S) rules by whether patterns can grow and decay; argues rules allowing both are the interesting ones.
Relation: a principled, analytic pre-filter for interesting rules — a counterpart to Keimli's hand-made score.
Verified: Crossref.

**sapin2004** — Sapin, E., Bailleux, O., Chabrier, J.-J., Collet, P. (2004). A new universal cellular automaton discovered by evolutionary algorithms. *GECCO 2004*, LNCS 3102, pp. 175–187. DOI 10.1007/978-3-540-24854-5_16.
Evolutionary search over 2D rules for glider/glider-gun support; finds rule "R" claimed universal.
Relation: precedent for evolutionary search with a hand-made fitness over CA rules for a target phenomenon. Keimli's swarm search fits this lineage.
Verified: Crossref.

**sapin2007** — Sapin, E., Bailleux, O., Chabrier, J.-J. (2007). Research of complexity in cellular automata through evolutionary algorithms. *Complex Systems* 17(3):231–. DOI 10.25088/ComplexSystems.17.3.231.
Fitness detecting glider birth in a random soup.
Relation: same; the "soup + fitness" setup mirrors Keimli's random initial lattice + score. End page not seen.
Verified: complex-systems.com abstract page.

**cisneros2020** — Cisneros, H., Sivic, J., Mikolov, T. (2020). Visualizing computation in large-scale cellular automata. *ALIFE 2020*, pp. 239–247. DOI 10.1162/isal_a_00277; arXiv 2104.01008.
Coarse-graining and visualisation of large CA to spot emergent computation; companion to cisneros2019 (already in bib) on compression-based interestingness.
Relation: method for measuring/visualising emergent structure at scale; useful next to the gradient frame as a visualisation tool.
Verified: arXiv (journal-ref and DOI listed).

**davis2022** — not added (Davis & Bongard 2022, GECCO companion, arXiv 2204.07541, evolving continuous Life-like CA for halting unpredictability) — seen only as a search snippet; listed in "could not verify".

## D6. Neural cellular automata, and isotropy

**mordvintsev2020** — (existing; corrected) Growing NCA, Distill 5(2).
Relation: NCA learn the local rule by gradient descent to a target pattern; Keimli's dictionaries are designed by enumeration. Both "design" a CA rule; Keimli's design is exact and analysable (attractors by construction), NCA's is approximate and opaque.

**randazzo2020** — Randazzo, E., Mordvintsev, A., Niklasson, E., Levin, M., Greydanus, S. (2020). Self-classifying MNIST digits. *Distill* 5(8). DOI 10.23915/distill.00027.002.
Cells reach global consensus (digit label) by local messaging; consensus domains and their stability.
Relation: consensus by local agreement — vocabulary for Keimli's phase agreement in cycle domains (cycles need phase consensus; fixed points do not).
Verified: Crossref.

**niklasson2021** — Niklasson, E., Mordvintsev, A., Randazzo, E., Levin, M. (2021). Self-organising textures. *Distill* 6(2). DOI 10.23915/distill.00027.003.
NCA trained to produce textures; robust, dynamic textures emerge.
Relation: the Keimli lattice produces textures rather than shapes; this is the NCA reference for "texture as the attractor of a local rule".
Verified: Crossref.

**palm2022** — Palm, R. B., González-Duque, M., Sudhakaran, S., Risi, S. (2022). Variational neural cellular automata. *ICLR 2022*. arXiv 2201.12360.
NCA as a generative model; produces a distribution of stable attractors that recover from damage.
Relation: "attractors that repair after damage" = Keimli's robustness/return-after-flip measurement; vocabulary.
Verified: arXiv; ICLR 2022 venue confirmed via iclr.cc / mlanthology listing in search results (partly).

**mordvintsev2022iso** — Mordvintsev, A., Randazzo, E., Fouts, C. (2022). Growing isotropic neural cellular automata. *ALIFE 2022*. DOI 10.1162/isal_a_00552; arXiv 2205.01681.
Standard NCA perceive with fixed-orientation (Sobel) filters, so rules are anisotropic; IsoNCA uses rotation-invariant perception; symmetry is broken with structured seeds or by asynchronous updates.
Relation: directly relevant to Keimli's isotropy work — the down-right streaks removed by alternating link-round direction, and the synchronous isotropic 4-neighbour mixing rule. Gives a citation that grid update order/orientation is a known source of anisotropy, and that asynchronous updates are a symmetry breaker (cf. Keimli's rotating swap order).
Cite: "Grid automata inherit orientation from their update scheme, as noted for neural CA [mordvintsev2022iso]; we remove it by alternating link-round direction and a synchronous isotropic mixing rule."
Verified: Crossref; arXiv.

**randazzo2023** — Randazzo, E., Mordvintsev, A., Fouts, C. (2023). Growing steerable neural cellular automata. *ALIFE 2023*. DOI 10.1162/isal_a_00564. Optional follow-up (cells with their own orientation).
Verified: Crossref (title/authors/DOI only).

## D7. Parameter sweeps in space, heterogeneous media, and why the frame is not the sweep

**pearson1993** — Pearson, J. E. (1993). Complex patterns in a simple system. *Science* 261(5118):189–192. DOI 10.1126/science.261.5118.189.
Gray–Scott model; a (F, k) phase diagram of pattern classes from systematic simulation.
Relation: the classic parameter-plane picture of pattern classes. Verified: Crossref.

**munafo_xmorphia** — Munafo, R. P. (1996–2024). Reaction-diffusion by the Gray–Scott model: Pearson's parametrization (xmorphia), and PDE4 user instructions. https://mrob.com/pub/comp/xmorphia/
PDE4's parameter-space view runs ONE simulation in which "F varies from 0.0 at the bottom edge to 0.09 at the top edge, and k varies from 0.03 at the left edge to 0.075 at the right edge"; a 0 argument instead simulates "uniform values of both parameters". Munafo also extends Pearson's classes and notes Pearson's single initial condition missed pattern types.
Relation: THE direct precedent for Keimli's gradient frame (a parameter sweep in space, in one image) — must be cited; claiming the gradient frame as new would be a novelty error. Munafo's own uniform option is the same control the panel asked for.
Cite: "Showing a parameter sweep as spatial gradients in one simulation follows Munafo's Gray–Scott parameter map [munafo_xmorphia]; as there, each point of the frame is coupled to its neighbours, and we check frame findings against uniform runs."
Verified: mrob.com PDE4-user-instructions.txt and xmorphia index page (fetched this session).

**dziarmaga1999** — Dziarmaga, J., Laguna, P., Zurek, W. H. (1999). Symmetry breaking with a slant: topological defects after an inhomogeneous quench. *PRL* 82(24):4749–4752. DOI 10.1103/PhysRevLett.82.4749.
When the control parameter crosses the transition at different places at different times (a front), the broken-symmetry phase spreads from the region that ordered first, and far fewer defects form than in a homogeneous quench.
Relation: the physics reason the frame and uniform runs pick different winners: in a gradient the phase chosen where ordering is fastest invades neighbouring regions, so the outcome at a pixel is not that of a uniform run at that pixel's parameters. Directly addresses the panel's "the frame is the sweep is false".
Cite: "Inhomogeneous control parameters change which ordered state is reached and how many defects remain [dziarmaga1999, zurek2008]; a gradient frame is therefore a different experiment from a set of uniform runs."
Verified: Crossref.

**zurek2008** — Zurek, W. H., Dorner, U. (2008). Phase transition in space: how far does a symmetry bend before it breaks? *Phil. Trans. R. Soc. A* 366(1877):2953–2972. DOI 10.1098/rsta.2008.0069.
Phase transitions driven by a spatial gradient of the control parameter: the broken symmetry is selected by the front; defect formation is suppressed below a critical front speed / gradient.
Relation: same as above; the spatial (static-gradient) case is the one closest to Keimli's frame.
Verified: Crossref.

**keener1987** — Keener, J. P. (1987). Propagation and its failure in coupled systems of discrete excitable cells. *SIAM J. Appl. Math.* 47(3):556–572. DOI 10.1137/0147038.
In discrete (lattice) media, fronts stop (pin) below a coupling threshold even when the continuum model propagates.
Relation: explains why Keimli domains can freeze ("deterministic freezing") and why domain walls stall where mixing (coupling) is weak — mixing probability plays the role of coupling strength; pinning threshold ↔ the place in the frame where a domain stops advancing.
Cite: "Interfaces in discrete media pin when coupling is weak [keener1987, erneux1993]; in the frame, the mixing gradient sets where a domain boundary stops."
Verified: Crossref.

**erneux1993** — Erneux, T., Nicolis, G. (1993). Propagating waves in discrete bistable reaction-diffusion systems. *Physica D* 67(1–3):237–244. DOI 10.1016/0167-2789(93)90208-I.
Propagation failure of bistable fronts on lattices below a critical coupling. Relation: as keener1987 for the bistable (two-attractor competition) case, closest to fixed-point-vs-cycle competition. Verified: Crossref.

**lober2012** — Löber, J., Bär, M., Engel, H. (2012). Front propagation in one-dimensional spatially periodic bistable media. *PRE* 86(6):066210. DOI 10.1103/PhysRevE.86.066210; arXiv 1203.4710.
Average front velocity and propagation failure as functions of the period and amplitude of spatial heterogeneity.
Relation: quantitative example that spatial heterogeneity of a parameter alone changes which state invades — supports the frame ≠ sweep finding. Verified: Crossref.

**sipper1997** — Sipper, M. (1997). *Evolution of Parallel Cellular Machines: The Cellular Programming Approach*. LNCS 1194 (volume number to confirm), Springer. DOI 10.1007/3-540-62613-1.
Non-uniform CA: each cell has its own rule, co-evolved locally ("cellular programming"); non-uniform CA can solve tasks (density, synchronisation) better than uniform ones.
Relation: heterogeneous *rules*; Keimli has one rule (decoder) and heterogeneous *medium* (mixing/settling strength). Cite to distinguish.
Verified: Crossref (book DOI, title, year); volume number not shown.

**medernach2013** — Medernach, D., Kowaliw, T., Ryan, C., Doursat, R. (2013). Long-term evolutionary dynamics in heterogeneous cellular automata. *GECCO '13*, pp. 231–238. DOI 10.1145/2463372.2463395.
HetCA: per-cell GP-like transition functions with genetic transfer between neighbours, age, decay; long-term phenotypic dynamics without stagnation over 10^6 steps. (Follow-up: Medernach et al. 2016, ALIFE 2016 pp. 216–223, DOI 10.7551/978-0-262-33936-0-ch041.)
Relation: important near neighbour — "genetic transfer between neighbouring cells" is close to Keimli's bit-mixing; HetCA has selection-like dynamics and per-cell rules, Keimli has neither. Good to cite as the contrast case.
Cite: "Heterogeneous CA with gene transfer between neighbours [medernach2013] show long-term dynamics; Keimli's mixing also transfers bits between neighbours, but every cell is rewritten by the same decoder."
Verified: Crossref; abstract via UL Pure / GP bibliography snippets (partly).

**shrestha2024** — Shrestha, A., Reimers, F., Jain, S., Baldini, P., Braccini, M., Roli, A., Nichele, S. (2024). Emergent dynamics in heterogeneous life-like cellular automata. arXiv 2406.13383.
Life-like rules mutate locally (an evolutionary inner loop) with cell ageing; parameter settings found giving long-term phenotypic dynamics.
Relation: as medernach2013; recent. Verified: arXiv abstract page.

## Most important for the paper (ranked)
1. munafo_xmorphia — direct precedent for the gradient frame (one simulation, parameters varying linearly across the grid, uniform-run option); must cite.
2. dziarmaga1999 / zurek2008 — physics explaining why a spatial parameter gradient selects different ordered states than uniform runs (answers the panel's "frame is the sweep" error).
3. kumar2025 (ASAL) + faldor2024 + etcheverry2020 — state of the art in automated/QD discovery; position the swarm search honestly as single-score search with eye selection, and the designed dictionaries as construction (not possible in Lenia/NCA).
4. mordvintsev2022iso — anisotropy from update scheme in grid automata; supports the isotropic mixing / alternating-direction design.
5. keener1987 / erneux1993 — propagation failure/pinning on lattices: vocabulary for deterministic freezing and stalled domain walls in weak-mixing regions.

## Threats to novelty
- No work in this thread uses a decoder/decompressor as a CA rule; nothing close to the thesis (entropy reduction vs computation).
- The gradient frame is NOT novel: Munafo's PDE4 parameter map (Gray–Scott) does exactly this; Flow-Lenia and Chan 2023 put parameters in space as well (heritable). Present the frame as a known visualisation applied to a new system.
- Searching a rule space with a hand-made score for interesting patterns is long established (Packard–Wolfram 1985, Sapin et al. 2004/2007, Mitchell et al.); automated QD/foundation-model search (Faldor–Cully 2024, ASAL 2025, Hamon et al. 2025) is ahead of it. Do not claim the search as a contribution; the designed (enumerated, Gray-coded) dictionaries are the defensible novelty here.
- Neighbour bit-transfer in a heterogeneous CA (Medernach et al. 2013 HetCA "genetic transfer") resembles the mixing stage; distinguish (no per-cell rules, no selection).

## Could not verify
- Schmidhuber 2009 LNAI volume number (5499) — chapter DOI and pages verified, volume not seen.
- Sipper 1997 LNCS volume number (1194) — book DOI verified, volume not seen.
- Sapin et al. 2007 Complex Systems end page.
- Palm et al. 2022 — ICLR 2022 venue only from search-result listings (iclr.cc, mlanthology), not opened.
- "Hintze — Evolving CA": no matching paper found; possibly a mis-remembered author. Nearby: Davis & Bongard 2022 (arXiv 2204.07541, GECCO companion) — seen only as a search snippet.
- "Medernach et al. 2016 Evolutionary search for self-reproducing structures": not found under that title; the 2016 Medernach paper is "Evolution of heterogeneous cellular automata in fluctuating environments" (ALIFE 2016, pp. 216–223, DOI 10.7551/978-0-262-33936-0-ch041; Crossref seen).
- "Cisneros/Mikolov Benchmarking ... interestingness": no such paper found; Cisneros et al. 2020 (visualising computation) substituted; cisneros2019 is already in the bib.
- "Kaleidoscope" spatially varying sweep: not found.
- Lenia parameter maps in Chan 2019 (built from separate runs) — not re-checked in this session.
