# Thread K: classical dynamics of lattices and maps

Checked 2026-10-21 against Crossref (api.crossref.org), Open Library, Math-Net.ru and publisher records. Each entry says what
was checked. Keys do not clash with references.bib. Entries already in references.bib are corrected in section K7.

## K1. Self-reproduction, universality and the Garden of Eden

**vonneumann1966**: J. von Neumann, *Theory of Self-Reproducing Automata*, ed. A. W. Burks, University of Illinois Press, 1966.
Builds a 29-state 2-D cellular automaton with a universal constructor that copies itself, including its own description.
This is non-trivial self-reproduction: copying runs through a description that is both interpreted and copied. Keimli's
"replicators" are the opposite extreme. Gives vocabulary, does not threaten novelty.
Cite as: "Self-reproduction in cellular automata begins with von Neumann's universal constructor [vonneumann1966], in which
a description is both interpreted and copied; nothing of that kind happens in Keimli."
Verified: Open Library (Univ. Illinois Press 1966, 388 pp.); Math. Comp. review doi:10.2307/2005041.

**langton1984**: C. G. Langton, "Self-reproduction in cellular automata", *Physica D* 10(1–2):135–144, 1984. doi:10.1016/0167-2789(84)90256-2.
Presents the 8-state "Langton loop", which copies itself without universal construction. It argues that self-reproduction
should require the structure to direct its own copying, not be copied passively by the rule. Under that test, a crystal
or a fixed point of the local rule is "trivial" replication. This is the vocabulary the panel wants: Keimli's fixed points and
short cycles are trivial replicators in this sense. That supports a careful framing and removes any overclaim.
Cite as: "In Langton's terms [langton1984] the spreading fixed points and short cycles of the decoder are trivial
replication: the rule does the copying and the pattern only carries the state."
Verified: Crossref.

**moore1962**: E. F. Moore, "Machine models of self-reproduction", *Proc. Symp. Appl. Math.* 14:17–33, AMS, 1962. doi:10.1090/psapm/014/9961.
**myhill1963**: J. Myhill, "The converse of Moore's Garden-of-Eden theorem", *Proc. AMS* 14(4):685–686, 1963. doi:10.1090/S0002-9939-1963-0155764-9.
Together these give the Garden-of-Eden theorem: a CA has configurations with no predecessor (Gardens of Eden) exactly when
it is not injective on finite configurations. Keimli's rewrite is a many-to-one map, so most 128-bit states are
unreachable Gardens of Eden of the local map, and the global map loses information at every step. This is the formal side of the
"entropy reduction" thesis. Gives method and vocabulary.
Cite as: "Because the decoder is many-to-one, the global map is not surjective and, by the Garden-of-Eden theorem
[moore1962; myhill1963], has configurations with no predecessor; each step shrinks the set of reachable states."
Verified: Crossref/AMS for both.

**hedlund1969**: G. A. Hedlund, "Endomorphisms and automorphisms of the shift dynamical system", *Math. Systems Theory* 3(4):320–375, 1969. doi:10.1007/BF01691062.
Characterises CAs as the continuous shift-commuting maps (Curtis–Hedlund–Lyndon). It also proves that surjective CAs are
"balanced": every finite block has the same number of preimages. Keimli's local map is very far from balanced, and its
skewed preimage counts (basin sizes) can be measured directly. Gives a formal anchor.
Cite as: "A surjective CA must be balanced, with every block having equally many preimages [hedlund1969]; the
decoder's preimage counts are extremely skewed, which is exactly the information loss we measure."
Verified: Crossref.

**kari2005**: J. Kari, "Theory of cellular automata: a survey", *Theor. Comput. Sci.* 334:3–33, 2005. doi:10.1016/j.tcs.2004.11.021.
A modern survey of reversibility, surjectivity, Garden of Eden, undecidability and the basic notions of
CA dynamics. A single citation for those definitions, so the paper does not have to cite every original result.
Cite as: "For surjectivity, injectivity and the Garden-of-Eden theorem see the survey [kari2005]."
Verified: Crossref.

**gardner1970**: M. Gardner, "Mathematical Games: the fantastic combinations of John Conway's new solitaire game 'life'", *Scientific American* 223(4):120–123, 1970. doi:10.1038/scientificamerican1070-120.
Introduced the Game of Life to the public. Cite it only as the origin of Life (historical).
Verified: Crossref (registered title is "Mathematical Games").

**berlekamp1982**: E. R. Berlekamp, J. H. Conway, R. K. Guy, *Winning Ways for Your Mathematical Plays*, vol. 2, Academic Press, 1982.
Contains the sketch that Life is computation-universal (gliders as signals, eaters, guns). Contrast: universality in Life
comes from engineered configurations, not from the rule's typical behaviour. Keimli's thesis says that rich behaviour in
ALife substrates comes from "the finesse of computation", and this book is the classic case of computation built
on top of a simple rule.
Cite as: "Universality can live in a CA's rare configurations rather than in its typical dynamics, as in Life
[berlekamp1982] and Rule 110 [cook2004]."
Verified partly: publisher, year and volumes confirmed; chapter number not confirmed.

**cook2004**: M. Cook, "Universality in elementary cellular automata", *Complex Systems* 15(1):1–40, 2004. doi:10.25088/ComplexSystems.15.1.1.
Proves that Rule 110 is universal using cyclic tag systems built from gliders. This is the standard reference for "even a minimal
local rule can be universal". Keimli should acknowledge that "linear-time decoder" does not mean "computationally
weak" for the global system, because universality can emerge through the lattice coupling. This is a caveat on the thesis.
Cite as in berlekamp1982, and also: "Bounding the local map's work does not bound the global system's computational power
[cook2004]."
Verified: Crossref.

## K2. Global dynamics, entropy decrease and attractor basins of many-to-one maps

**wolfram1983**: S. Wolfram, "Statistical mechanics of cellular automata", *Rev. Mod. Phys.* 55(3):601–644, 1983. doi:10.1103/RevModPhys.55.601.
Studies the elementary CAs as irreversible dynamical systems. Because the maps are many-to-one, the set of reachable
configurations shrinks and the spatial (set) entropy decreases with time, so self-organisation is the result of
irreversibility. This is the closest classical statement of Keimli's "entropy reduction" source of structure. It supports the thesis
and must be cited prominently. It also limits the thesis's novelty: the claim that information loss alone makes
structure is Wolfram's. Keimli's contribution is to isolate it in a substrate whose local map is a decoder and to compare it
with real program substrates.
Cite as: "That irreversible, many-to-one rules organise themselves by shrinking the set of reachable configurations, so
that entropy decreases, goes back to Wolfram [wolfram1983]; Keimli puts this mechanism, and only this one, into a
program-like substrate."
Verified: Crossref.

**wolfram1984** (existing key; verify): "Universality and complexity in cellular automata", *Physica D* 10(1–2):1–35, 1984. doi:10.1016/0167-2789(84)90245-8.
The four-class scheme. The existing pages 1–35 are correct; add the DOI and set verified = yes. Verified: Crossref.

**wolfram1984b**: S. Wolfram, "Computation theory of cellular automata", *Commun. Math. Phys.* 96(1):15–57, 1984. doi:10.1007/BF01217347.
Shows that the sets reachable after t steps are regular languages whose complexity grows with t, quantifying the
"attractor" of an irreversible CA. Gives a method: Keimli's census of reachable 128-bit states after k rewrites is
a finite, per-cell version of this.
Cite as: "The census of states reachable after k rewrites is a cell-level analogue of Wolfram's description of the
shrinking reachable sets [wolfram1984b]." Verified: Crossref.

**kauffman1969**: S. A. Kauffman, "Metabolic stability and epigenesis in randomly constructed genetic nets", *J. Theor. Biol.* 22(3):437–467, 1969. doi:10.1016/0022-5193(69)90015-0.
In random Boolean networks (N nodes, K inputs) the many-to-one global map has few, short attractor cycles that are stable
under perturbation. Kauffman identifies these with cell types. This is the classic case of "a random many-to-one map has few
attractors, and they matter". Keimli's census of fixed points, cycles and basin sizes of a random-looking decoder is the
same kind of analysis on a 128-bit map. Gives method and vocabulary (attractor, basin, cycle length).
Cite as: "Counting the fixed points, cycles and basins of the rewrite follows Kauffman's analysis of random
Boolean networks [kauffman1969; kauffman1993], here applied to a local map that is then coupled in space."
Verified: Crossref.

**kauffman1993**: S. A. Kauffman, *The Origins of Order*, Oxford University Press, 1993. doi:10.1093/oso/9780195079517.001.0001.
The book-length treatment of RBN attractors, basin structure, frozen components and order "for free". The "frozen core" is
a vocabulary match for Keimli's frozen domains. Verified: Crossref/OUP.

**rispoli2026** (recent): G. Rispoli, "Replication of Kauffman (1969)…", *ALIFE 2026 Proceedings*, MIT Press. doi:10.1162/isal.a.960.
Reproduces Kauffman's cycle statistics with a verified simulator. Shows that underspecified model choices (constant
functions, step budgets) change the reported cycle lengths. Gives a method lesson for Keimli: report the step budget and
cycle-detection limits of its own attractor census.
Cite as: "Attractor censuses are sensitive to unreported choices such as step budgets [rispoli2026]; ours are listed in
Methods." Verified: Crossref (abstract read).

**wuensche1992**: A. Wuensche, M. Lesser, *The Global Dynamics of Cellular Automata: An Atlas of Basin of Attraction Fields of One-Dimensional Cellular Automata*, SFI Reference Vol. I, Addison-Wesley, 1992.
Computes and draws full basin-of-attraction fields (state-transition graphs) of 1-D CAs on small rings. Gives a reverse
algorithm that counts preimages and finds Garden-of-Eden states, and measures convergence and in-degree. This is the
direct methodological ancestor of Keimli's basin census. The difference is that Keimli takes the basins of the *local* 128-bit map,
not of the global lattice map, and then studies how coupling selects among them. (wuensche1999 is already in the bib.)
Cite as: "Like the basin-of-attraction atlases of Wuensche and Lesser [wuensche1992], we enumerate preimages and
Garden-of-Eden states, but of the per-cell rewrite rather than of the whole lattice."
Verified partly: Open Library (Addison-Wesley 1992, ISBN 0201557401); SIAM Review doi:10.1137/1035161.

## K3. Coupled map lattices: the closest structural class

**kaneko1984**: K. Kaneko, "Period-doubling of kink-antikink patterns, quasiperiodicity in antiferro-like structures and spatial intermittency in coupled logistic lattice", *Prog. Theor. Phys.* 72(3):480–486, 1984. doi:10.1143/PTP.72.480.
The founding CML paper: a local nonlinear map (logistic) on each site, followed by diffusive coupling to neighbours. Structurally
Keimli is a discrete CML: rewriting is the local map, and mixing and settling are the coupling. Kaneko's sweep of the
nonlinearity and coupling strength is the parameter plane that Keimli's spatial gradients sample in one frame.
This must be cited as the structural class. It does not threaten novelty: CMLs have continuous states and smooth maps, and none
uses a decoder.
Cite as: "Structurally Keimli is a coupled map lattice [kaneko1984; kaneko1992] with a discrete state: a local map
(the decoder) applied to every cell, alternating with nearest-neighbour coupling (mixing and settling)."
Verified: Crossref.

**kaneko1985**: K. Kaneko, "Spatiotemporal intermittency in coupled map lattices", *Prog. Theor. Phys.* 74(5):1033–1044, 1985. doi:10.1143/PTP.74.1033.
Laminar domains interrupted by turbulent bursts that spread like directed percolation. Gives vocabulary for Keimli regimes
where frozen domains coexist with churning regions.
Cite as: "Regions where frozen domains are interrupted by bursts of change resemble spatiotemporal intermittency in
CMLs [kaneko1985; chate1987]." Verified: Crossref.

**kaneko1989**: K. Kaneko, "Pattern dynamics in spatiotemporal chaos", *Physica D* 34(1–2):1–41, 1989. doi:10.1016/0167-2789(89)90227-3.
The main phase diagram of the diffusively coupled logistic lattice: frozen random patterns, pattern selection, defect
turbulence, spatiotemporal intermittency, fully developed chaos. "Frozen random pattern" (domains of different
attractors frozen in place, with sizes fixed by the initial condition and coupling) is the best existing name for
Keimli's "deterministic freezing". "Pattern selection" (coupling picks which domain sizes survive) parallels Keimli's
finding that the medium, not basin size, decides which attractor wins.
Cite as: "Keimli's frozen mosaics of different attractors are the discrete counterpart of Kaneko's frozen random
patterns, and the medium's choice of winner parallels pattern selection in CMLs [kaneko1989]."
Verified: Crossref.

**kaneko1992**: K. Kaneko, "Overview of coupled map lattices", *Chaos* 2(3):279–282, 1992. doi:10.1063/1.165869.
A short review introducing the CML focus issue. The best single citation for the class.
Verified: Crossref.

**kaneko2001**: K. Kaneko, I. Tsuda, *Complex Systems: Chaos and Beyond*, Springer, 2001. doi:10.1007/978-3-642-56861-9.
A book treatment (chapter 3, "CMLs: constructive approach", pp. 57–106). It frames the CML as a "constructive" modelling
approach that chains simple procedures (local map, then coupling), which is Keimli's design philosophy.
Cite as: "Keimli is built in the constructive style of coupled map lattices [kaneko2001]: separate, simple procedures applied in
turn." Verified: Crossref.

**bunimovich1988**: L. A. Bunimovich, Ya. G. Sinai, "Spacetime chaos in coupled map lattices", *Nonlinearity* 1(4):491–516, 1988. doi:10.1088/0951-7715/1/4/001.
A rigorous result for weakly coupled expanding maps: a unique space-time-mixing invariant (SRB) measure, which means
spacetime chaos with no ordering. It marks the opposite pole to Keimli. The decoder is contracting and many-to-one, not
expanding, so ordering and freezing are expected rather than mixing chaos.
Cite as: "Unlike the weakly coupled expanding maps of Bunimovich and Sinai [bunimovich1988], whose spacetime
statistics mix, the decoder contracts state space, so the coupled system orders and freezes."
Verified: Crossref.

**chate1987**: H. Chaté, P. Manneville, "Transition to turbulence via spatio-temporal intermittency", *PRL* 58(2):112–115, 1987. doi:10.1103/PhysRevLett.58.112.
Spatiotemporal intermittency in a CML with absorbing laminar states, linking it to directed percolation. Gives vocabulary,
and an optional test: is Keimli's frozen-to-churning boundary a directed-percolation-like transition? Verified: Crossref.

## K4. Spatial competition among cycling states

**greenberg1978**: J. M. Greenberg, S. P. Hastings, "Spatial patterns for discrete models of diffusion in excitable media", *SIAM J. Appl. Math.* 34(3):515–523, 1978. doi:10.1137/0134040.
A discrete excitable medium (rest → excited → refractory → rest). Persistent spiral patterns need topological
defects. Relevant to Keimli's cycles: a cycle domain needs phase agreement, and phase defects either annihilate or
organise spirals.
Cite as: "Domains of a cycle need neighbours to agree on phase; as in discrete excitable media
[greenberg1978; fisch1991], phase defects either annihilate or organise rotating spirals." Verified: Crossref.

**fisch1991**: R. Fisch, J. Gravner, D. Griffeath, "Cyclic cellular automata in two dimensions", in *Spatial Stochastic Processes*, Birkhäuser, 1991, 171–185. doi:10.1007/978-1-4612-0451-0_8.
**fisch1991b**: same authors, "Threshold-range scaling of excitable cellular automata", *Statistics and Computing* 1(1):23–39, 1991. doi:10.1007/BF01890834.
In the cyclic CA each of k colours advances when a neighbour has the next colour. Phases run from debris and
fixation to droplets, spiral "demons" and turbulence, depending on k, the range and the threshold. This is the canonical
spatial dynamics of cyclically ordered states. Keimli's Gray-coded designed cycles are cyclically ordered states with a
designed successor, so this is the right comparison for cycle-domain behaviour, including the observation that cycles melt under noise
where fixed points do not. Gives vocabulary (fixation vs. spirals); partly anticipates the cycle findings.
Cite as: "Designed cycles turn the lattice into a cyclic medium with k states, whose fixation and spiral phases are well
charted [fisch1991; fisch1991b]." Verified: Crossref (both).

**frachebourg1996**: L. Frachebourg, P. L. Krapivsky, E. Ben-Naim, "Spatial organization in cyclic Lotka–Volterra systems", *PRE* 54(6):6186–6200, 1996. doi:10.1103/PhysRevE.54.6186.
Lattice cyclic competition with 3 or more species: coarsening for 3 species in 1D, fixation for many species. Gives vocabulary for
Keimli runs with 3–32 designed species. Verified: Crossref.

**reichenbach2007**: T. Reichenbach, M. Mobilia, E. Frey, "Mobility promotes and jeopardizes biodiversity in rock–paper–scissors games", *Nature* 448:1046–1049, 2007. doi:10.1038/nature06095.
In a lattice rock–paper–scissors game, mobility (exchange of neighbours) below a critical value lets spirals keep all three
species. Above it, one species takes over. Keimli's mixing probability is a mobility parameter that varies across the
image, so Keimli could show a mobility threshold for cycle survival in one frame. Gives a testable prediction and a method.
Cite as: "Mixing in Keimli acts like mobility in lattice rock–paper–scissors games, where coexistence of cycling species is lost above a
critical mobility [reichenbach2007]; a mixing gradient shows that threshold across one image."
Verified: Crossref.

**szolnoki2014**: A. Szolnoki, M. Mobilia, L.-L. Jiang, B. Szczesny, A. M. Rucklidge, M. Perc, "Cyclic dominance in evolutionary games: a review", *J. R. Soc. Interface* 11:20140735, 2014. doi:10.1098/rsif.2014.0735.
A survey of cyclic dominance on lattices and the one citation for that field. Verified: Crossref.

**pearson1993**: J. E. Pearson, "Complex patterns in a simple system", *Science* 261(5118):189–192, 1993. doi:10.1126/science.261.5118.189.
Maps the Gray–Scott reaction–diffusion model over its two parameters (feed and kill) and labels regions by pattern type. This is the
model for presenting Keimli's gradient frames as a parameter map. A spatial sweep in one image also echoes the
reaction–diffusion "parameter map" figures that came later.
Cite as: "Reading a gradient frame as a phase diagram follows Pearson's parameter map of the Gray–Scott system
[pearson1993], except that here the sweep is laid out in space within a single run." Verified: Crossref.

## K5. Partitioning (block) cellular automata

**margolus1984**: N. Margolus, "Physics-like models of computation", *Physica D* 10(1–2):81–95, 1984. doi:10.1016/0167-2789(84)90252-5.
Introduces the 2×2 block (Margolus) neighbourhood: the lattice is partitioned into blocks, the partition alternates between two offsets, and a block rule acts
on each block. Keimli's swap phases on 2×2 blocks with alternating offsets are exactly a partitioning CA, and
Margolus partitioning is the standard way to make bit-exchange (mixing) rules that conserve bits. Gives method and vocabulary;
cite in Methods.
Cite as: "The mixing step is a partitioning cellular automaton on the Margolus neighbourhood [margolus1984; toffoli1987]: 2×2
blocks with alternating offsets, inside which bits are exchanged and conserved." Verified: Crossref.

**toffoli1987**: T. Toffoli, N. Margolus, *Cellular Automata Machines: A New Environment for Modeling*, MIT Press, 1987. doi:10.7551/mitpress/1763.001.0001.
The textbook account (chapter "The Margolus neighborhood", pp. 123–142) of partitioning CAs, lattice-gas diffusion and
reversible block rules. Keimli's mixing is a probabilistic block permutation of this kind. Verified: Crossref/MIT Press.

**sipper1997**: M. Sipper, *Evolution of Parallel Cellular Machines*, LNCS 1194, Springer, 1997. doi:10.1007/3-540-62613-1.
Non-uniform CAs, where different cells have different rules evolved by "cellular programming". Keimli's position-dependent
mixing and settling strength is a non-uniform CA with a designed (gradient) rule field rather than an evolved one.
Cite as: "Rules that vary over the lattice make Keimli a non-uniform cellular automaton [sipper1997], with the rule field set by a
gradient rather than evolved." Verified partly: Crossref (LNCS volume number from memory).

## K6. Zero-temperature coarsening, freezing and the voter model

**spirin2001a**: V. Spirin, P. L. Krapivsky, S. Redner, "Fate of zero-temperature Ising ferromagnets", *PRE* 63:036118, 2001. doi:10.1103/PhysRevE.63.036118.
**spirin2001**: same authors, "Freezing in Ising ferromagnets", *PRE* 65:016119, 2001 (vol. 65 is dated 2002). doi:10.1103/PhysRevE.65.016119.
Under zero-temperature Glauber dynamics a 2D Ising system reaches the ground state only with probability
about 2/3. Otherwise it freezes into stripe states, and in 3D it gets stuck in "blinking" states. This is the reference for the panel's
"deterministic freezing". Keimli's settling step is a zero-temperature majority dynamics, so frozen stripes and domains
are expected, not anomalous.
Cite as: "Freezing into stripes and other non-ground states is generic in zero-temperature majority dynamics
[spirin2001a; spirin2001]; Keimli's settling step inherits it." Verified: Crossref (both).

**derrida1996**: B. Derrida, P. M. C. de Oliveira, D. Stauffer, "Stable spins in the zero temperature spinodal decomposition of 2D Potts models", *Physica A* 224:604–612, 1996. doi:10.1016/0378-4371(95)00345-2.
With many Potts states, zero-temperature dynamics leaves a finite fraction of spins frozen forever, because of
T-junctions and pinning. This applies directly to Keimli with many species (3–32 designs): more species means more
pinning and earlier freezing.
Cite as: "With many species, zero-temperature Potts dynamics pins a finite fraction of the lattice
[derrida1996; olejarz2013]." Verified: Crossref.

**olejarz2013**: J. Olejarz, P. L. Krapivsky, S. Redner, "Zero-temperature coarsening in the 2d Potts model", *J. Stat. Mech.* P06018, 2013. doi:10.1088/1742-5468/2013/06/P06018.
A modern study of final states (frozen, blinking, ground) for q-state Potts. Verified: Crossref.

**denholm2021** (recent): J. Denholm, "High-degeneracy Potts coarsening", *PRE* 103:012119, 2021. doi:10.1103/PhysRevE.103.012119.
Coarsening when the number of states q is large. Relevant to Keimli's large-alphabet regime. The content summary is from memory;
check before citing. Verified: Crossref (metadata only).

**holley1975**: R. A. Holley, T. M. Liggett, "Ergodic theorems for weakly interacting infinite systems and the voter model", *Ann. Probab.* 3(4):643–663, 1975. doi:10.1214/aop/1176996306.
**liggett1985**: T. M. Liggett, *Interacting Particle Systems*, Springer Grundlehren, 1985. doi:10.1007/978-1-4613-8542-4.
The voter model: a site copies a random neighbour. It coarsens in d ≤ 2 without surface tension, and consensus is reached in d ≤ 2.
Keimli's mixing step (copying or trading bits with a random neighbour) is voter-like, and its settling step is
majority-like (with surface tension). The two kinds of coarsening differ, and Keimli mixes them.
Cite as: "Mixing copies state from random neighbours as in the voter model [holley1975; liggett1985], while settling is
a majority rule with surface tension; the two coarsen differently [dornic2001]." Verified: Crossref (Liggett's volume
number 276 is from memory).

**dornic2001**: I. Dornic, H. Chaté, J. Chave, H. Hinrichsen, "Critical coarsening without surface tension: the universality class of the voter model", *PRL* 87:045701, 2001. doi:10.1103/PhysRevLett.87.045701.
Separates voter-class coarsening (interfacial noise, no surface tension) from Ising-like coarsening. Gives a diagnostic: measure
whether Keimli's domain walls are sharp (curvature-driven) or diffuse (voter-like) as the settling strength varies. Verified:
Crossref.

**krapivsky2010**: P. L. Krapivsky, S. Redner, E. Ben-Naim, *A Kinetic View of Statistical Physics*, CUP, 2010. doi:10.1017/CBO9780511780516.
Textbook covering voter, Glauber, Potts and cyclic-competition kinetics. One reference for the background. Verified: Crossref.

## K7. Corrections to existing references.bib entries

- **wolfram1984**: correct as written (Physica D 10:1–35). Add number = {1--2}, doi = {10.1016/0167-2789(84)90245-8}, verified = yes (Crossref).
- **gacs1978**: change to @article, journal = Problemy Peredachi Informatsii **14(3):92–96** (not 92–98). English translation is
  *Problems of Information Transmission* 14(3):223–226 (1978). Math-Net.ru lists it as "P. Gach" (ppi1551), received
  08.09.1977. Some later papers cite it as "One-dimensional homogeneous media dissolving finite islands". Verified: Math-Net.ru record (seen via search
  index), mathnet.ru/eng/ppi1551.
- **toom1980**: the book is confirmed: *Multicomponent Random Systems*, Marcel Dekker, 1980, ISBN 0824768310, 606 pp. (Open
  Library, which lists Dobrushin and Griffeath as names; the editors are usually given as Dobrushin & Sinai, Advances in
  Probability and Related Topics 6). Toom's chapter title and pp. 549–575 were **not** found in any record. Keep verified = partly.
- **gacs2001**: fields match the arXiv id given; not re-fetched. **vichniac1984**: already verified; no change.

## Most important for the paper

1. **wolfram1983**: entropy decrease from irreversible, many-to-one rules. This is the classical form of the "entropy reduction" source; it must be cited and the thesis positioned against it.
2. **kaneko1984 / kaneko1989 / kaneko1992**: Keimli *is* a discrete coupled map lattice. "Frozen random patterns" and "pattern selection" are the existing names for deterministic freezing and for the medium choosing the winner.
3. **langton1984** (with vonneumann1966): the trivial vs. non-trivial replication vocabulary. The paper should say plainly that Keimli's replicators are trivial.
4. **kauffman1969 / wuensche1992**: methods ancestry for the census of attractors, basins and Gardens of Eden of a many-to-one map. Add **moore1962/myhill1963/hedlund1969** for the formal statement.
5. **margolus1984 / toffoli1987** for the mixing step, plus **spirin2001 / derrida1996 / reichenbach2007 / fisch1991** as the expected behaviour of the settling and cycle domains (freezing, pinning, mobility threshold, spirals).

## Threats to novelty

- **Wolfram 1983** already argues that irreversibility (many-to-one maps) alone produces self-organisation by shrinking the reachable set.
  The thesis's first half ("entropy reduction a running program does to its memory") must be presented as an application and
  isolation of that mechanism in program-like substrates, not as a new mechanism.
- **CMLs (Kaneko)** already have "local map + neighbour coupling" with frozen random patterns, pattern selection and
  phase diagrams over coupling strength. Keimli's novelty is the *discrete, decoder* local map (designed basins and cycles, a
  checkable census) and the in-image parameter gradient, not the architecture.
- **Wuensche & Lesser / Kauffman** already take basin and attractor censuses of many-to-one maps. Keimli's novelty is doing it for a
  compression decoder and designing the cycles (Gray-coded dictionary) in advance.
- **Cyclic CA / rock–paper–scissors**: the behaviour of designed cycle domains (spirals, fixation, melting under mixing) is largely
  predicted by Fisch–Gravner–Griffeath and Reichenbach et al. Present these results as confirmation, not discovery.
- **Freezing**: zero-temperature majority/Potts dynamics freezes generically (Spirin et al., Derrida et al.), so "deterministic freezing" is
  expected given the settling step.
- **Rule 110 / Life universality** is a caveat, not a threat: a linear-time local map does not make the global system
  computationally weak.
- No work found in this thread uses a decoder or decompressor as a CA or CML local rule.

## Could not verify

- Toom 1980 chapter title and pages 549–575 (book confirmed, chapter not).
- Winning Ways: chapter number/title of the Life chapter ("What is Life?", ch. 25 of vol. 2): not confirmed.
- Wuensche & Lesser 1992: exact subtitle and series line (authors, publisher, year, ISBN confirmed).
- Sipper 1997: LNCS volume number 1194. Liggett 1985: Grundlehren volume 276 (both from memory).
- Kaneko 1984 and 1989 subtitles beyond what Crossref shows. Denholm 2021 content (metadata only).
- arXiv ids for spirin2001, dornic2001 and reichenbach2007 were not looked up; DOIs were used instead.
