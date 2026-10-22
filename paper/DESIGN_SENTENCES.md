# Experiments designed to the ten sentences

2026-10-22. For each sentence of SKETCH.md (pass 20) that the data carry thinly: the experiment, its prediction written
before the run, the measure, the decision rule, and the cost. Numbered E3–E10 by sentence. Predictions are the
pre-registration; the write-up says whether each held. Settings unless stated: three settling passes, the rotating
order, quenched hashing, 128², 5 seeds, shares as means with bootstrap intervals.

## Sentence 3–4: the census and the shuffles are for Swarm F; the selection result is for Brotli 12

**E3a. Exact census of Brotli 12 and 13** (`map-exact.mjs`, minutes each).
- Prediction: fixed points in self-read-literal families with 0–3 free bytes; Brotli 12's winning fixed point #1
  (basin 0.26 %) is one such family; the 3-cycle's basin matches the 99.72 % of random cells.
- Decision: if any family has more than 3 free bytes, sentence 9's "zero for every type of the decoder" is wrong
  and the heredity axis has a Keimli point before A9. Either way, the census and the selection result then share a
  dictionary.

**E4a. Word- and byte-shuffle nulls on Brotli 12 and 13** (`map-shuffles.mjs`, 5 shuffles each, 10 minutes).
- Prediction: word shuffles keep the number of types, the leading basin and the H₂ decay curve within the seed
  spread; byte shuffles do not.
- Decision: the sentence stands for the dictionary the paper's lattice results use; if word shuffles change the
  attractor set here, sentence 4 is restricted to Swarm F.

## Sentence 5: "closed is what holds"

**E5a. Prediction-first extension to untested dictionaries** (closure first, then the lattice; about 1 CPU-h).
- Dictionaries: Brotli 1, 2, 9, 14, 15; swarm A–E; cyc567; gray4c–6c; the five ca-live designs.
- Step 1: `closure.mjs` on each; every type with basin > 1 % is labelled closed (C(A, A) ≥ 0.99) or open, and the
  prediction "holds / dissolves at (0.25, 0.5) in random phases" is written to a file before step 2.
- Step 2: whole-lattice random-phase runs (`droplets3.mjs modes=whole`), 2,000 turns.
- Decision: the 2 × 2 count grows from 16 rows to about 50. Any closed type that dissolves, or any open type that
  holds at (0.25, 0.5), is reported as a counter-example and sentence 5 is weakened to a tendency.

## Sentence 6: the three regimes rest on three settling values

**E6a. The settling scan** (about 2 CPU-h).
- m ∈ {0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1} × p ∈ {0.1, 0.25, 0.5}; Brotli 12 and 13; two configurations:
  the random-phase cycle alone (dissolution) and the fixed-point disc R = 16 in an in-phase sea (invasion);
  2,000 turns.
- Measures: the cycle's share at the end; the disc's share at the end and the wall speed from the radius track.
- Prediction: a dissolution boundary m_d between 0.25 and 0.5 below which the disordered cycle dissolves; an
  arrest boundary m_f above which the disc neither grows nor dies (Brotli 12: between 0.5 and 0.75; Brotli 13:
  between 0.75 and 1); the selection window is m_d < m < m_f, and the wall speed falls to zero at m_f.
- Output: a (p, m) map with the three regions, the paper's regime figure; the frame's vertical axis read against it.

**E6b. Robustness of the 99-of-100 result** (`replicators.mjs`, about 2 CPU-h).
- Brotli 12 and 13 on the frame, 128², 2,000 turns, 10 seeds each, (i) turn-salted hashing (`salt=1`), (ii) the
  isotropic mixing rule (`mixsync=1`).
- Prediction: the fixed point reaches half the lattice in at least 9 of 10 seeds in both variants; the Kaplan–Meier
  median within a factor of 2 of the quenched one (731 for Brotli 12, 373 for Brotli 13).
- Decision: if either variant fails, the result is reported as specific to quenched hashing or to the swap rule.

**E6c. The frame's regimes by row** (from existing frame maps plus 5 new seeds; 0.5 CPU-h).
- The fixed point's share at turn 2,000 as a function of the row (the settling strength), averaged over columns in
  the mixing range 0.1–0.5, for Brotli 12 and 13.
- Prediction: zero in the top rows (dissolved), near one in the middle band, near the start value in the bottom rows
  (frozen), with the boundaries at the m_d and m_f of E6a.

## Sentence 7: closure decides who holds, not who advances

**E7a. The wall-velocity matrix** (new script `wall.mjs`; 1–2 CPU-h).
- A flat wall: the left half of a 256 × 64 lattice type X, the right half type Y, both in phase (and a variant with
  Y in random phases); settings (0.1, 0.5), (0.25, 0.5), (0.5, 0.5); 2,000 turns; every ordered pair of the chosen
  types of Brotli 12, 13, gray3c, cyc5to12, and for Swarm F its 3-cycle against its ten largest exact fixed points
  (from `map-exact`); 5 seeds.
- Measure: the wall position x(t) = X's share × width; the velocity v (cells per turn) from the slope between turns
  200 and 1,000 with its interval; the wall's roughness (the standard deviation of the wall's column over rows).
- Prediction: v(#1, 3-cycle) = +0.06 to +0.12 for Brotli 12 as measured on discs; v(#2, 3-cycle) < 0; v between
  gray3c's types within ±0.01 of zero; v antisymmetric under swapping X and Y to within the interval.
- Decision: the matrix is reported whatever it shows; the sentence "closure decides who holds, not who advances"
  gets its table.

**E7b. Predictors of v** (single-cell and strip computations; 0.5 CPU-h).
- For each ordered pair: (i) the cross-closure C(X, Y) and C(Y, X) from `closure.mjs`; (ii) the local wall
  advantage a(X, Y): a 1 × 64 strip, half X half Y, one turn at (p, m) with three passes, repeated over 10,000
  phase draws, the mean displacement of the wall in cells; (iii) the mean reading length of X's and Y's states.
- Prediction: a(X, Y) predicts the sign of v in at least 90 % of pairs and correlates with v (Spearman ≥ 0.8);
  C(X, Y) alone does not (the second panel's finding); reading length does not.
- Decision: if a(X, Y) predicts, the paper has a local predictor of who advances and the open question closes
  partway; if nothing predicts, the sentence stays and the matrix is the result.

**E7c. The nucleation rate over the settings and the wall speed at 256²** (`nucleation.mjs`; about 2 CPU-h).
- Spontaneous mode, q = 1, p ∈ {0.05, 0.1, 0.25, 0.5} × m ∈ {0.375, 0.5, 0.625}, 128², 10 seeds, Brotli 12 and 13:
  the rate per cell and turn from the cluster count at the first 0.1 %.
- Radius mode, R = 16, (0.1, 0.5) and (0.5, 0.5), 256², 3 seeds: the wall speed.
- Prediction: the rate rises with p and falls toward zero as m approaches m_f; v at 256² equals v at 128² within
  10 %.

**E7d. The nucleation rate against the cycle's period** (`nucleation.mjs`; about 1 CPU-h).
- The 9-cycle nucleated the fixed point 20–40 times faster than the 3-cycle. Seas of cyc5to12's 5- and 11-cycles
  and Brotli 13's 18-cycle, each against its dictionary's fixed point, spontaneous mode at (0.1, 0.5) and
  (0.25, 0.5), 128², 10 seeds.
- Prediction: the rate increases with the period, because a longer cycle in random phases is less uniform under
  majority and makes more transients.

## Sentence 8: the decoder's types inherit nothing

**E8a. Variants of every kind, for every type, in both metrics** (`heredity.mjs` extended; about 1 CPU-h).
- Single-bit and single-byte variants (BFF's figure is single-byte; Keimli's 2,944 is single-bit, so the two are
  not yet comparable): all 128 bit variants and all 16 × 255 byte variants of every state of every chosen type of
  Brotli 12, 13, Swarm F (the 3-cycle and its ten largest exact fixed points), gray3c and cyc5to12; the map alone
  and 3 × 3 patches on the lattice at three passes.
- Prediction: 0 inherited under the map alone (every variant repaired or converted to an existing type); on the
  lattice every patch erased at m ≥ 0.5.
- Decision: sentence 8 then quotes the single-byte number beside BFF's.

**E8b. Free-byte alleles of a natural family on the lattice** (the medium as a channel; about 1 CPU-h).
- Swarm F's fixed points come in families whose members differ only in bytes the decoder never reads (0–3 bytes).
  A member keeps its unread bytes under f (memory); mixing can carry a free byte into a neighbour of the same family,
  where it is kept too (transmission); settling votes it out unless the neighbourhood agrees. So a family with b
  free bytes has up to 8b bits of lattice-level capacity, carried by the medium rather than the map.
- Setup: the three largest 3-free-byte families from `map-exact`; a 128² domain of one member; a 3 × 3 and an 8 × 8
  patch of a second member (a free-byte allele); (p, m) ∈ {0.1, 0.25, 0.5} × {0.25, 0.5, 0.75, 1}; 1,000 turns;
  10 seeds. Measure the allele's share over time and whether it is removed, held, or spreads.
- Prediction: removed at m ≥ 0.5 for the 3 × 3 patch; the 8 × 8 patch holds as a domain at m = 1 (majority inside
  it agrees) and spreads slowly at (0.5, 0.5) if at all; new alleles appear at the wall by recombination of the
  free bytes.
- Decision: sentence 9 reads "zero for the types that win; up to 24 bits of medium-carried capacity for the largest
  families, which [holds / is removed] on the lattice". This is also the natural control for A9 (E10c ii): the
  designed type adds a copy operation to a channel the medium already provides a little of.

## Sentence 9: one measurement of heritable information for every system

**E9a. `copier.mjs`: the copier test and the family on the pair map** (map evaluations only; 0.5 CPU-h).
- For each candidate state R: 1,000 random partners X; R is a copier if g(R, X) = (R, R) in at least 99 % (the slot
  condition for BFF reported separately: R first, R second). For each byte position: all 256 values; a byte is free
  if every value gives a copier; a byte with some free values contributes log₂ of their count. h(R) = the sum.
- Candidates: the 12 evolved BFF replicators and the paper's Fig. 4 tape; the imp and its two operand variants and
  every single Redcode instruction repeated; the constructed replicase variants of `replicase.mjs`; the chosen types
  of Brotli 12, 13, Swarm F and gray3c in pair mode 1 (each state as R); A9's type when built.
- Prediction: BFF 48–54 free bytes (384–432 bits), with partly free bytes adding a few; the imp 0 free bytes and
  h ≈ log₂ 3 across the family of self-copying single instructions; the decoder's types not copiers at all (the
  partner is not overwritten with R); the replicase variants exactly 8 × the tape they copy verbatim.
- Decision: the table is Figure 1's heredity axis; the earlier 80–85 % (encounter-based) is reported beside the
  family-based h and the two are reconciled in one paragraph.

## Sentence 10: the dictionary that sets both (A9)

**E10a. The decoder check** (reading `decode36.mjs` and `decode.wat`; ten minutes).
- Question: can a backward reference copy from the bytes already output in this cell (the output buffer as the
  window), with distance 16 and length 16 in pair mode 1 (32-byte joint cell)?
- Decision: if yes, E10b as designed. If the window is the dictionary only, add a decoder kind, the Brotli-like
  decoder with the output window (one field in `decode.wat`, mirrored in `decode36.mjs` and tested bit-exact), and
  say in the paper that the rule was given one copy operation.

**E10b. The design** (`design-copier.mjs`, half a day).
- The state: a prefix P that copies the dictionary word W = P (a quine by construction, as the Gray designs are),
  then an insert of k literal bytes (the tail T, k = 10), then a command C that copies 16 bytes from distance 16.
  The dictionary holds W and the bytes of C where P can reach them. Landing pads and filler as in `design-dict.mjs`
  so random cells reach the type.
- Verification on the reference decoder: g(P + T + C, X) = (P + T + C, P + T + C) for 10,000 random X and 1,000
  random T; the prefix bytes are not free, the tail bytes are.
- Prediction: a copier with h = 8k = 80 bits; closed (the prefix is a fixed point of the single-cell map on its own
  bytes; the tail is passed through).

**E10c. The measurements** (about 4 CPU-h).
- Under g: `copier.mjs` on it (E9a): tail 100 % inherited, prefix 0 %, h = 80.
- On the lattice, pair mode 1, both write boxes, three passes: (i) the frame and the (p, m) grid of E6a, with the
  tail alleles coloured; (ii) inheritance against m: plant one allele in a 3 × 3 patch inside a domain of another
  allele; inherited if the patch's allele is present after 200 turns (prediction: removed by settling at m ≥ 0.5
  when alone, kept when the patch is a domain of 8 × 8 or more, so heredity on the lattice is at the domain level
  and the error threshold is in m); (iii) drift: start with every cell a random tail, count distinct tails and the
  mean allele-domain size over 2,000 turns at 128² (prediction: coarsening of neutral alleles, the number of
  distinct tails falling as a power of time); (iv) recombination: tails of two neighbouring alleles cross over
  under mixing, so new tails appear at walls at a rate proportional to p (prediction: the number of distinct tails
  at the end has a floor set by p).
- Competition (`droplets3.mjs` with a dictionary holding both A9's type and a crystal type): does heredity cost
  holding? Prediction: A9's type is closed and holds; against the crystal the wall velocity is whatever E7a's
  predictor says.

**E10d. The page** (half a day): the dictionary and a preset in pair mode; the view coloured by tail allele; the
inspector's copier and free-byte readout for the clicked cell.

## Order and cost

Tonight's batch, cheap and parallel (about 12 CPU-h, 30 minutes on 28 cores): E3a, E4a, E5a, E6a, E6b, E6c, E7a,
E7c, E7d, E8a. Then E7b and E9a (map computations, half a day of scripting). Then E10a–d (two days). After that the
sketch's last sentence loses its "[to show]" or says what was found instead.
