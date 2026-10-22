# Round 1: the emeritus professor of complex systems

Read: README, docs/lattice.md (parts), paper/INTRODUCTION.md, MOTIVATION.md,
METHODS.md, RESULTS_REPLICATORS.md, RELATED_WORK.md, PLAN_AMENDMENTS.md (§§1–3),
references.bib (keys), results/README.md, ablation-main.md, replicators.md,
design-gray3.md, reviews/retired-professor.md and postdoc-alife.md, and the
first page of draft/keimli-draft.pdf.

## 1. The project in my words

A cellular automaton with 2^128 states per cell. The local map is an
LZ/Brotli-style decoder parametrised by a few kilobytes of text; around it
sit a conserved bit-exchange (a lattice gas on 128 planes) and a per-plane
majority vote, all deterministic via a salt-0 hash. The decoder alone is a
finite self-map whose attractors (here mostly one short cycle) can be
censused and even designed. The lattice is then a medium of coupled discrete
oscillators, and the author reads "replicators" as attractors plus spread.

## 2. Strengths

- Honesty of method. A pre-registered hypothesis (H1) was retracted in
  writing when the annealed control showed hash pinning; that is rarer than
  it should be, and I would have been proud of it at Santa Fe in 1990.
- The `hash:K` null with matched image entropy, the byte/word shuffles, and a
  bit-exact JS reference of the decoder. This is the kind of control
  Mitchell, Hraber and Crutchfield (1993) begged the λ crowd for.
- The attractor census (ablation-main.md table) is clean and genuinely
  illuminating: the swarm search "selected dictionaries whose decoder is a
  short global oscillator". The author found out what his own search did.
  Good.
- Designed Gray-coded cycles: an inverse problem solved by construction,
  not search. Small, exact, verifiable.
- The replicator Monte Carlo argument (first appearance at 1/(Nb), lateness
  is takeover at front speed) is a crisp, falsifiable deflation. It is the
  most citable thing here.

## 3. Concerns, ranked

1. **The founding dichotomy is historically wrong.** The abstract says rule
   systems "are tractable but compute nothing"; the Introduction says Life-like
   rules have "no computation at all". Life is universal (Berlekamp, Conway,
   Guy 1982); so is rule 110 (Cook 2004; Wolfram's conjecture from the 1980s).
   Langton's whole 1990 paper is about *where computation emerges* in rule
   space. The two traditions were never apart: Artificial Life I (1987) had
   Langton's loops beside Rasmussen's Coreworld (1990, I think). The framing
   must become: one-step maps of bounded depth versus one-step general
   programs. The iterated, coupled decoder lattice is itself a CA and nobody
   has shown it is *not* universal. "The decoder cannot compute" is a claim
   about one turn, not about the dynamics. This is the claim a Wolfram-school
   referee will dismantle first.
2. **"Replicators are fixed points and short cycles" rediscovers old
   ground and ignores the old distinction.** Von Neumann (1966, Burks ed.)
   and Langton (1984, Physica D 10) insisted on separating trivial
   replication (crystal growth, a state that spreads) from replication
   directed by a description. What the paper shows is precisely trivial
   replication; that is fine and useful, but say it in those words. Kauffman's
   attractors-as-cell-types (1969) and Fontana and Buss's organisations (1994,
   in the bib) are the direct ancestors of "listed, not born".
3. **The spatial phenomena have names already.** A lattice of 3-phase
   oscillators with neighbour coupling is a cyclic / excitable medium:
   Greenberg and Hastings (1978), Fisch, Gravner and Griffeath's cyclic CA
   (around 1991), Kaneko's coupled map lattices (1980s; phase
   synchronisation, domain fronts, "spatiotemporal intermittency"). Invasion
   with a winner rule and wetting layers are Potts/voter-model material
   (Bramson and Griffeath). None of Kaneko, Griffeath, Greenberg–Hastings,
   Kauffman, von Neumann, Langton 1984, Toffoli–Margolus is in references.bib.
   The even/odd swap phases are a Margolus partitioning (Toffoli and Margolus,
   *Cellular Automata Machines*, 1987); the swaps are a lattice gas (HPP,
   1973).
4. **The 128-bit, 2^128-state cell hides how ordinary the dynamics may be.**
   If F collapses every cell onto one 3-cycle within 35 turns, the lattice is
   effectively a 3-state cyclic automaton plus noise. The decisive null is a
   reduction: replace the decoder by its cycle projection and see what is lost.
5. **Novelty sentences that are not true.** "That a hypothesis could be put
   and refuted in a system of programs is, to our knowledge, new" (Intro):
   Avida has tested hypotheses for twenty-five years (Lenski et al. 2003;
   Wilke et al. 2001, survival of the flattest). Strike it.
6. **LZ76 versus LZ77.** Kaspar–Schuster used the Lempel–Ziv 1976
   complexity, not the 1977 algorithm; the bib has only ziv1977. Small, but
   it is the analogy the whole motivation rests on.
7. **Scope creep.** Twenty-five CPUs, ten decoders, seventeen texts. Ray's
   Tierra demo worked because it was one thing. The processor arm is
   promised but mostly "to show".

## 4. Questions for the other panelists

- Compression: is the decoder really loop-free once overlapping copies
  (distance < length) and the wrap-around input are allowed? Does
  "fixed-depth function" hold exactly?
- Physics: is "hash pinning" genuinely quenched disorder in the Sicilia et al.
  sense, or simply Vichniac's deterministic freezing of a zero-temperature
  vote, which needed no disorder at all?
- ALife: would Agüera y Arcas et al. accept that their replicators are
  attractors-plus-spread? Their soups have a copy instruction; is the
  analogy fair?
- Statistics: does the period ≤ 12 detector bias the "no late appearance"
  result against long-cycle species?
- Anyone: has a coupled-decoder lattice ever been tested for universality, or
  even for a glider?

## 5. For the methodology round

- Check every "no computation"/"cannot compute" sentence and propose the
  correct, defensible version of the dichotomy.
- Read the replicator argument against Langton's 1984 criterion and the
  von Neumann distinction; draft the paragraph that places it.
- Examine whether F's lattice reduces to a 3-state cyclic CA with majority
  noise (design the cycle-projection null; look at existing runs for spirals
  or Greenberg–Hastings waves).
- Audit references.bib against the missing classics above; mark which I am
  sure of and which I am citing from memory.
- Ask what will survive in ten years: my present guess is the census and
  the replicator deflation, not the gradient frame or the CPUs.
