# The automaton, defined

*Draft for the methods section and an appendix. It answers the editors' request (Journal of Cellular Automata, Natural
Computing, Physical Review E) for a formal definition of the global map, and states the three exact facts the results
lean on. Implementation: `src/lattice/lattice.wat`, `src/lattice/band.js`, `src/changers/decode.wat`; the
prose specification is `docs/lattice.md` and `docs/changers.md`.*

## 1. Space, states, configurations

- The lattice is Λ = {0, …, W−1} × {0, …, H−1}, a plane with edges (not a torus).
- A cell's state is s ∈ Σ = {0,1}¹²⁸. Write s[j] for bit j, with j ∈ ℤ/128 taken as a ring.
- A configuration is c : Λ → Σ.
- The context of bit j of state s is κ(s, j) ∈ {0,1}³²: the 16 bits below j and the 16 above it on the ring,
  excluding j itself.
- h : {0,1}⁶⁴ → {0,1}⁶⁴ is the splitmix64 finaliser. A decision with threshold θ ∈ [0, 2⁶⁴] fires when h(key ⊕ salt)
  < θ.
- The salt is 0 by default ("quenched"). The variants salt by the turn number ("annealed") or by the position.

## 2. One turn: F_t = Mut ∘ R ∘ Sᵏ ∘ M_t

**Mixing M_t.**
- Snapshot. Let c⁰ be the configuration at the start of the turn.
- Pairings. The four phases φ ∈ {LR0, UD0, LR1, UD1} each partition Λ into disjoint neighbour pairs: bricks
  (0,1), (2,3), … at offset 0 and (1,2), (3,4), … at offset 1. Cells left out at an edge pair along the edge, with
  an offset that alternates with the parity of t.
- Order. The phases run in the order π(t mod 4) given by the "rotate" scheme. Successive turns take the pattern
  turned by 90°, which exchanges LR with UD and the two brick offsets.
- Decision. For a pair (a, b) of phase φ and a bit position j with c⁰_a[j] ≠ c⁰_b[j], the key is the unordered pair
  {κ(c⁰_a, j), κ(c⁰_b, j)}, packed smaller-first into 64 bits. The bit is exchanged when its hash is below
  θ_M(x_a) = 2⁶⁴ · 2p(x_a)(1 − p(x_a)). Here p(x) is the swap parameter of the first cell's column.
- Application. Decisions are read from c⁰ and applied to the live configuration in phase order. An exchange whose
  two bits are equal when it is applied is the identity. Exchanges conserve the number of 1s in each bit plane.
- Variant. "Isotropic" mixing (`mix_sync`) is synchronous instead: each differing bit takes the value of the
  neighbour with the lowest symmetric pair key, decided by a fresh hash against the threshold.

**Settling S**, k passes (default 3), each synchronous.
- Majority. For every cell x and bit j, let v = maj{ c_y[j] : y ∈ N(x) }. N(x) is the 3 × 3 block by default (or the
  4-neighbour cross, or the (2r+1)² block), with coordinates clamped at the edges.
- Update. If c_x[j] ≠ v and h(κ(c_x, j) ⊕ salt) < θ_S(row of x), then c'_x[j] = v. Otherwise c'_x[j] = c_x[j].

**Rewriting R.**
- Single cells: c'_x = f(c_x) for the local map f : Σ → Σ. This is the decoder (kind 36, against a dictionary) or
  any other changer.
- Pair modes: two cells, or a cell and its 4-neighbour vote taken from the start-of-rewrite snapshot, are joined,
  mapped and split, and a write mask selects which cells take the result.

**Mutation.** Mut flips bits at positions hashed from the turn and the cell index. It is 0 by default and off in
every experiment below unless stated.

**Determinism and symmetry.**
- With mutation off, F_t is a deterministic function of c and t. The turn-salted "annealed" variant is deterministic
  too: its randomness is a fixed hash of the turn.
- F_t depends on t only through t mod 4: the rotate order has period 4 and the edge parity period 2.
- With uniform parameters and away from the edges, F_t commutes with translations by 2ℤ²: the brick partitions are
  invariant under them. So, under uniform parameters, the lattice is a cellular automaton on 2 × 2 blocks with a
  period-4 rule in time. With the gradients of the page frame it is a non-uniform automaton.

## 3. Three exact facts

**Lemma 1 (uniform configurations).** Let c be uniform, c_x = s for every x. Then, for every parameter table, every
salt and every neighbourhood, M_t(c) = c and S(c) = c, so F_t(c) is the uniform configuration f(s).

*Proof.*
- Mixing acts only on positions where the two cells of a pair differ, and in a uniform configuration there are none.
- The majority of identical bits is that bit, also at the edges, where clamping repeats a cell that is already
  equal. ∎

**Corollary.** If f(s) = s, the uniform configuration s is a fixed point of every F_t. If s₀ → s₁ → … → s_{k−1} → s₀
is a k-cycle of f, the uniform configurations s₀, …, s_{k−1} form a periodic orbit of the lattice map. This holds
whatever the mixing and settling parameters.

**Lemma 2 (domain interiors).** Let D ⊂ Λ be a region where c is uniform, c_x = s, and let D° be the cells of D whose
whole interaction range lies in D. That range is the mixing partner of every phase and the settling neighbourhood of
every pass, so at most k·r + 1 cells for k passes of radius r. Then F_t(c)_x = f(s) for x ∈ D°. Only the cells
within that range of the domain's boundary feel the medium.

*Proof.* As for Lemma 1, applied to the cells whose every input is s. ∎

**Consequence for cycles (the phase-coherence mechanism).**
- For a fixed point, every domain of s is coherent: all its cells hold the same state.
- For a k-cycle (k ≥ 2), a domain whose cells sit at different phases s_i ≠ s_{i'} has no uniform region, so every
  cell is a boundary cell. Mixing then exchanges bits between unequal states, which generally leaves the cycle;
  settling can restore a common phase only where a majority already shares one.
- So a cycle type can hold a domain against the medium only if its cells share a phase, while a fixed-point type
  always can.
- This is the mechanism proposed for "the medium, not the basin, picks the winner". `experiments/droplets.mjs` and
  `experiments/heredity.mjs` test it: in-phase against random-phase domains, droplets of each type in each other,
  and mutant patches.

**Lemma 3 (the first-step entropy bound).** Let U be uniform on Σ, and let τ ≤ 128 be the number of distinct cell bits
the decoder reads before its output is complete. τ is a stopping time of the bit sequence; the wrap-around rereads
bits it already has. Then H(f(U)) ≤ H(U₁, …, U_τ) = E[τ].

*Proof.*
- f(U) is a function of the bits read, so H(f(U)) ≤ H(U₁ … U_τ).
- For i.i.d. fair bits and a stopping time τ, H(U₁ … U_τ) = E[τ] H(U₁) = E[τ]. This is Wald's identity applied to
  the entropy chain rule. ∎

**Remarks.**
- At the reference setting E[min(c, 128)] = 93.5 bits (results/decoder-map.md), so H(f(U)) ≤ 93.5 bits after one
  step.
- This bounds the entropy, not the size of the image. The earlier statement "the image has at most 2^93.5 elements"
  is wrong and is withdrawn.
- The measured values are far smaller: collision entropy 16.5 bits, min-entropy 8.3 bits.
- The same argument gives look-and-say's bound, about 128 · 2(1 − 1/b) bits read in base b (results/look-and-say,
  to write). For the elementary rules the loss is exact: 0, 1 and 2 bits a turn for rules 150, 60 and 90
  (results/entropy-manipulators.md).

## 4. The Gray construction, and why designed cycles are closed

Setting: the reference decoder (kind 36), 6 skipped bits, a 12-bit cursor header h (V = 4096), the construction of
results/design-gray3.md.

**Pointer lemma.**
- Let P(h) be the 46-bit prefix: the 6 skipped bits (arbitrary), the header h, then the commands "no literals, copy 10
  bytes at distance 16, copy 6 more at the same distance". Its 28 command bits are fixed, and h is chosen so that the six command
  bytes are printable.
- Then f(P(h) · τ) = D[w(h), w(h) + 16) for every tail τ ∈ {0,1}⁸², where w(h) is the window start that h selects
  (the dictionary bytes at h − 16 in the reference setting).

*Proof.* The decoder reads the skip bits, the header and the two copy commands. That fills the 16 output bytes, so it
stops and never reads τ. Both copies reach past the empty output into the dictionary at the window that h selects. ∎

**Theorem (existence of a designed k-cycle).**
- Construction. Let H₀ be a multiple of 128, g the 3-bit reflected Gray code, and h_k = H₀ + 16·g(k) for k = 0, …, 7,
  so that the h_k differ only in header bits 4–6. Let S_k = P(h_k) · τ_k with chosen tails, and write the 16 bytes of
  S_{k+1 mod 8} into the dictionary window w(h_k).
- Claim. If those windows are disjoint and lie inside the dictionary, then f(S_k) = S_{k+1 mod 8} for every k: an
  exact 8-cycle.
- Distance. Consecutive states differ in one header bit, or two bits with the optional tail Gray byte.

*Proof.* The pointer lemma, applied to each S_k. ∎

The construction is checked bit-exactly with the reference decoder for all 24 states of the three-type design
(design-gray3.md).

**What the theorem does not give.**
- That the designed cycles are the only attractors. The basins and the absence of stray attractors come from the
  filler regions and are empirical: the census found none for 10⁴ random cells, while the panel's exact search found a
  stray fixed point.
- The sizes of the basins.

**Proposition (closure of a designed type).** Let a and b be states of the same Gray type, in any phases, and let c be
any bitwise combination of them: a crossover, or a bitwise majority of three states. Then f(c) is a state of the type.

*Proof.*
- The states of a type agree on every bit of the 46-bit prefix except header bits 4–6.
- So c begins with the skip bits of some state (arbitrary anyway), the common command bits, and a header H₀ + 16·γ
  with γ ∈ {0, …, 7}. Header bits 4–6 of c are some 3-bit pattern, and every pattern is a value of g, which is a
  bijection.
- So c = P(h_k) · τ for some k and some tail τ, and by the pointer lemma f(c) = S_{k+1}. ∎

**Consequence.**
- The self-closure index of every designed Gray cycle is exactly 1, both under mixing exchanges and under settling
  majorities. The measured values are 100 % in results/mechanism.md §2.
- So a designed type's domain cannot be melted by the medium, whatever the phases of its cells.
- A generic cycle of a searched dictionary has no such structure: its states differ in 29–64 bits, and its
  self-closure is 5–67 %.
- That is the analytic reason the designs hold their domains, and the reason a fixed point beats a large-basin open
  cycle under mixing.

## 5. What is not claimed

- No transition in the thermodynamic sense; the parameter dependence is described as a crossover unless finite-size
  scaling shows otherwise.
- No universality class.
- No statement about the image size of f beyond the entropy bound and the census.
- No computation: the decoder is not claimed to be computationally weak globally. The lattice it drives may well be
  able to compute; Life and rule 110 are universal.
