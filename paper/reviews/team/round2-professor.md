# Round 2: the emeritus professor, methodology

Read all six round-1 notes. Small checks of my own on the frames in
`paper/data/design/runs` (Python, read-only; numbers below).

## (a) Responding to the panel

Where the table below names old work, I agree with the panelist who raised
the point. Additions only:

- **Mathematics** (no loop, no fixed points, "fixed-depth"): every finite CA
  rule is a lookup table (Wolfram 1983); depth claims need a family in n.
- **Information**: the swaps are Fredkin–Toffoli conservative logic (1982),
  reversible by design. Lempel–Ziv 1976, the measure Kaspar–Schuster used,
  is missing from the bibliography.
- **ALife**: agreed in full. Declare the agueraYarcas2024 co-authorship first.
- **Physics**: my frame check below supports "frozen, not disordered".
  Brotli 12's winner flipping between frame and uniform runs is the
  gradient-percolation effect: the frame shows where the front sits.
- **Optimization**: the swarm found short global oscillators because the
  objective and gradient rewarded them. Packard (1988) and
  Mitchell–Hraber–Crutchfield (1993) again. Swarm G's seed-11 score is the
  same lesson.
- **Computation**: given the fixed swap order, nothing in
  RESULTS_REPLICATORS is confirmatory yet. My frames carry the same caveat.

**The false sentences, and what already settles each:**

| sentence | settled by |
|---|---|
| rule systems "compute nothing" | Berlekamp–Conway–Guy 1982; Cook 2004; Langton 1990 |
| decoder "never reads its output, no loop" | Ziv–Lempel 1977 |
| "no fixed points" | Harris 1960; the census itself |
| "nothing replicates, nothing is selected" | von Neumann 1966; Langton 1984; Price 1970 |
| "entropy pump", "mixing raises entropy" (deterministic) | Landauer 1961; Bennett 1982; Fredkin–Toffoli 1982 |
| "pinning by quenched disorder" | Vichniac 1984 |
| "the frame is the sweep" | Sapoval–Rosso–Gouyet 1985 |
| "refuting a hypothesis in programs is new" | Lenski et al. 2003; Wilke et al. 2001 |
| zenil2015 cited for "LZ is good enough" | Zenil et al. argue the opposite |

## (b) Methodology

**1. A defensible dichotomy.** Both arms are finite maps on 2^128 states per
step, and both lattices are CAs. Whether the decoder lattice is universal is
open, and Wolfram's equivalence conjecture says to expect it. So the
difference is one of *degree of work per step*, not computation against none.
Proposed text: "The decoder is a one-pass, bounded-work map. Each turn costs
at most a constant times the cell size, with bounded lookback into its own
output. A processor given k instructions can spend work that is not bounded
by the cell size. We compare local maps of bounded and unbounded per-step
depth, in Bennett's (1988) sense of logical depth. Whether the iterated
lattice computes is not settled here." This turns the processor arm into
a dose–response experiment. Run each CPU at instruction budgets k = 1, 4,
16, 64, 256 and plot every phenomenon (census, takeover time, phase order)
against k. The decoder is a reference point near k ≈ n. If nothing changes
with k, the phenomena are bounded-depth phenomena. That is the paper's
intended claim, stated so that it can fail.

**2. Replicators against Langton 1984.** Langton kept von Neumann's
requirement that the configuration's own information *directs* its copying,
read once as instructions and copied once as data. He did that to exclude
copying done by the transition rule. The classic example of the excluded
kind is Fredkin's parity rule, in which every pattern replicates. Keimli's
copying is done by exchange plus majority plus the funnel, so it is
precisely the trivial replication Langton excluded. That is not a weakness.
It is the claim, correctly named: *the population phenomenology credited to
replicators (spread, invasion, coexistence, late takeover) can be produced by
trivial replication, with limited heredity, in a slow medium.* BFF
replicators carry a copy loop, which makes them non-trivial with unlimited
heredity. The 1/(Nb) argument therefore transfers only if their basins under
the pair map are ≥ 1/N. That census is the decisive experiment. Without
it, the section is a hypothesis about Agüera y Arcas et al., written by one
of its authors.

**3. The cycle-projection null, ready to run.** The existing `cycle3f`
collapses onto the cycle instantly and so removes the transient. My null asks
a different question: is the lattice a small-state CA in disguise?
- Runs: F, rotating order, 256², bulk margin 32. Points: (swap ½, median 1)
  and (swap ½, median 0.3), quenched and annealed, 10 seeds, 1,000 turns.
- Labels: at every turn t ≥ 50, φ(x) ∈ {0, 1, 2, ⊥} is the index of the F-cycle
  state the cell equals, or ⊥ if it equals none.
- Fit: the empirical table P(φ_{t+1} | φ_t, counts of each label among the
  8 neighbours). That is at most 4 × 165 rows, pooled over seeds 1–5. Repeat
  with the 24 cells of the 5×5 block, since three median passes reach
  further than one cell.
- Report: H(φ_{t+1} | row) in bits per cell for both radii, and the
  ⊥-fraction.
- Simulate: run the fitted table (stochastic and argmax) from the turn-50
  labels of seeds 6–10. Compare the phase correlation length (connected, as
  the physicist asks), the domain-size distribution, the ⊥-fraction and
  boundary persistence, each with a bootstrap CI.
- Decision: if H < 0.1 bit and all four statistics agree within the CIs, the
  lattice is a 4-state totalistic CA with a 2^128-state front end. The paper
  then says so, and cites cyclic CA and clock models as its home. If H >
  0.3 bit, or the simulation fails, the 128-bit content matters, and that is
  the novelty to lead with. For the Gray designs, use (species, phase)
  labels, with neighbour counts by phase difference.

**4. Greenberg–Hastings or spirals?** None. In `ca-gray20c` and `ca-cyc5to12`
at t = 1000 the frames are irregular phase-locked mosaics. Each domain
advances its phase in place, and no wave fronts or vortices are visible. I
measured the share of domain-boundary pixels that recur between frames:

| run | boundary fraction t400 → t1000 | same boundary pixels, 999→1000 | same, 400→1000 |
|---|---|---|---|
| cyc5to12, median 1, salt 0 | 0.072 → 0.072 | 0.98 | **1.00** |
| gray20c, median 1, salt 0 | 0.089 (t998–1000) | 0.94 | – |
| gray20c, median 1, salt 1 | 0.049 → 0.039 | 0.95 | 0.29 |
| cyc5to12, median 1, salt 1 | 0.035 → 0.023 | 0.96 | 0.25 |

The quenched mosaic is frozen outright: the boundaries are identical at
turns 400 and 1,000. The annealed one coarsens. This is what you would
expect: Greenberg–Hastings and the cyclic CA of Fisch, Gravner and Griffeath
(1990–91) are *excitable*, so a cell advances only when a neighbour leads it,
and that is what makes spirals. Here every cell oscillates on its own, so the
right home is lattices of identical discrete oscillators: Kaneko's coupled map
lattices, Kuramoto (1984), clock and Potts models. Caveats: one seed, the
fixed swap order, and a colour map that may hide 3-phase vortices. The
physicist should count vortices on the phase field itself.

**5. References to add** (~ = page/volume from memory, verify).
Universality: Berlekamp–Conway–Guy 1982; Cook 2004; Wolfram 1983 RMP.
Replication: von Neumann 1966 (Burks); Langton 1984 Physica D ~; Rasmussen
et al. 1990 Coreworld ~; Price 1970; Maynard Smith–Szathmáry 1995; Wilke et
al. 2001. Maps and attractors: Kauffman 1969 ~ and 1993; Derrida–Pomeau 1986
~; Harris 1960 ~; Wuensche–Lesser 1992 (basins and preimages, the precedent
for designed attractors). Oscillator media: Kaneko 1985 ~ and the 1993 CML
volume; Kuramoto 1984; Greenberg–Hastings 1978 ~; Fisch–Gravner–Griffeath
c. 1991 ~. Physics of the stages: Toffoli–Margolus 1987 (the even/odd
phases are a Margolus partition); Fredkin–Toffoli 1982; HPP 1973 ~;
Sapoval–Rosso–Gouyet 1985 ~; Spirin–Krapivsky–Redner 2001 ~. Information:
Lempel–Ziv 1976; Levin 1974 ~; Bennett 1988 (logical depth); Landauer 1961;
Bennett 1982.

## (c) Verdict

What will matter in ten years:
- the attractor census as the way to read any rewriting rule;
- designed attractors, an inverse problem solved by construction (cite
  Wuensche);
- if the BFF census is done, the deflation of "late, elaborate replicators"
  into trivial replication with limited heredity, plus slow takeover.

That last one would be a useful corrective to my own generation's
enthusiasms, and to the author's.

What will not matter: the gradient frame as a phase diagram, the
"between computational and arithmetic life" framing, the entropy pump, and
twenty-five CPUs shown as a gallery rather than run as a dose–response
experiment.

The paper must stop claiming that rules compute nothing; that the decoder has
no loop and never reads its output; that it has no fixed points; that nothing
replicates or is selected; that mixing pumps entropy in a deterministic
system; that the frame is the sweep; that hash freezing is quenched disorder;
and that refuting a hypothesis in a program system is new. It should claim
less, name the old things by their old names, and keep the census. The census
is the part that is the author's own.
