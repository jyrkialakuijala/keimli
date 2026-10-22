# Round 3: information theory, claims and recommendations

## 1. Claims table

| # | claim (where) | verdict | wording or experiment |
|---|---|---|---|
| 1 | Rule systems "compute nothing" (INTRO l.27–29) | DROP | Use the professor's version: one-pass, bounded-work maps against maps with unbounded work per step |
| 2 | Decoder "reads every bit once, never reads its own output, no loop" (INTRO l.50–53) | KEEP-REWORDED | "Each turn is one bounded pass over the cell, at most 1,024 bit reads, with lookback into its own 16-byte output; its output carries no more entropy than the bits it reads." |
| 3 | O(n) against O(c^n) (MOTIVATION) | KEEP-REWORDED | Work per turn is bounded by a constant times the cell size. Drop "fixed-depth … enumerated and inverted". |
| 4 | Output "carries less than 94 bits" (INTRO l.55–56) | KEEP-REWORDED | "For uniform input, H(f(U)) ≤ 93.5 bits (≤ 87.5 after the header's redundancy). The distribution is heavy-headed: H₂ = 16.5 bits and H_∞ = 8.3 bits for F, with one output at 0.32 %." State that this holds at turn 1 only. |
| 5 | "No fixed points" (INTRO l.56) | DROP | F has at least 48, verified exactly (mathematician) |
| 6 | Short cycles within tens of turns | KEEP-REWORDED | True for the searched dictionaries only; the texts have cycles of 55–303 turns and transients up to 670 |
| 7 | Byte order sets the cycle (ablation-structure §1) | NEEDS-EXPERIMENT | 30 byte-shuffles and 30 word-shuffles, with census and H₂ |
| 8 | Order acts only at second order, 0.25 bit (decoder-map §2) | KEEP-REWORDED | Order shows weakly in the conditional entropy, strongly in the head: H₂ 16.5 for F against 21.4 shuffled; header redundancy 5.5 against 2.7 bits |
| 9 | `hash:93` is the matched null | KEEP-REWORDED | It is matched in the Shannon bound only (H₂ ≈ 92 against 16.5). Present it as a null for image size, not for the decoder's concentration. |
| 10 | "LZ rather than Kolmogorov" (MOTIVATION, INTRO l.66–73) | KEEP-REWORDED | My round-2 paragraph: parse against decode, with lempel1976, levin1974 and zenil2015 cited for what they say |
| 11 | "Information-centric; entropy is the natural observable" | NEEDS-EXPERIMENT | E0 redone with LZ density, connected mutual information and stage snapshots (rec. 2) |
| 12 | Mixing raises entropy, the median lowers it; "entropy budget" (INTRO l.80–96) | KEEP-REWORDED | Name the coarse-grained entropy (per-cell, block or LZ density). Every hashing mode is deterministic, so the fine-grained entropy only falls. Otherwise say "activity budget". |
| 13 | "Local entropy pump … raising it around" (INTRO l.121–125) | DROP | Replace with the entropy-sink sentence from round 2. The stage test shows every neighbourhood quantity falling at the rewrite. |
| 14 | "The frame is the sweep" | NEEDS-EXPERIMENT | Physics E4; the current evidence (optimiser b1, Brotli 12 winner) is against it |
| 15 | Pinning "by quenched disorder" (INTRO l.114) | KEEP-REWORDED | "Freezing of a time-invariant deterministic rule" (physicist's salt test) |
| 16 | H1 retracted; the decoder contributes the oscillation and the transient | KEEP | The `cycle3f` failure supports it |
| 17 | ξ values, t^⅓, the sharp transition | NEEDS-EXPERIMENT | Physics E0, E2, E3 with connected measures |
| 18 | Replicators are fixed points or short cycles (RESULTS_REPLICATORS) | KEEP-REWORDED | "Trivial replication with limited heredity: a type transmits at most log₂(number of attractors) bits, 1.6–5 bits, and variants are erased." |
| 19 | First appearance at 1/(Nb); "never late" | DROP the mechanism, NEEDS-EXPERIMENT | First appearance is set by the medium and by a nucleus (computation table, ALife), not by the uniform basin |
| 20 | Takeover is a front, 1.5× slower at 256² | DROP | Censored median, size-free creep (physics b5) |
| 21 | Nothing replicates, nothing is selected | DROP | "No copy instruction, no fitness function; the dictionaries were selected" |
| 22 | Whatever the decoder reproduces is not computation | KEEP-REWORDED, NEEDS-EXPERIMENT | A hypothesis tested by dose–response over the CPU instruction budget k, plus the BFF census |
| 23 | Refuting a hypothesis in programs is new | DROP | |
| 24 | Bulk byte entropy 1.5–1.9 bits | KEEP as description | It is a zeroth-order marginal, not lattice entropy |

## 2. Remaining disagreements

- **Professor, "Bennett logical depth" as the dichotomy.** Logical depth is a property of a *string*: the running time of its near-shortest programs. It is not a property of a local map. The fitting quantity is the work bound per step, the k in the dose–response, or time-bounded complexity. Cite Bennett 1988 as context only.
- **Professor, "the swaps are Fredkin–Toffoli conservative logic, reversible by design".** They conserve bit counts. Global reversibility of a hashed exchange phase is not established: a decision context may be altered by a concurrent swap. My argument does not need it, since deterministic maps cannot raise fine-grained entropy either way. The sentence should not appear unproven.
- **Mathematician, "Rényi entropies predict the census".** It is plausible, but untested. gray3c has the lowest H₂ and the most attractors, so H₂ cannot be the predictor on its own. The decay curve H₂(f^k) is the better candidate.
- **ALife, heritable bits.** I agree, and I sharpen it: define them as the capacity of the parent-type → offspring-type channel under the medium. That is bounded by log₂ of the number of types, and it is measurable identically for BFF.

## 3. Top five recommendations

1. **Rewrite the information sentences** (rows 1–5, 10, 12, 13, 21) with the wordings above. *Text only, about one day.*
2. **Replace the observables**:
   - Brotli or LZMA bits per cell on the raster scan, with a cell-shuffled control;
   - connected mutual information I(r) on cycle-phase labels;
   - pre/post-rewrite snapshots through the JS rewrite hook, reporting H(Y|Z) as erasure;
   - provenance fields in every output.

   Rerun E0 with these. *Half a day of code, about 10 CPU-hours.*
3. **An information spectrum of the decoder per dictionary**:
   - the header-corrected Shannon bound, H₂, H_∞ and the top atoms;
   - the decay of H₂(f^k(U)) against the random-map null (log₂(k/2));
   - 30 shuffles of each kind;
   - the exact fixed-point count (mathematician's overnight C job).

   *One day of code and overnight compute.*
4. **Entropy throughput as a regime observable.** Measure it across uniform points, frame strips and nulls (`cycle3f`, `hash:93`, and a null matched in H₂), and then over the CPU instruction budget k. The prediction that can fail: if throughput against regime does not depend on k, the phenomena are bounded-work phenomena. *Two days of code, about 20–40 CPU-hours.*
5. **Heritable-information comparison with BFF**, run jointly with the ALife reviewer. *About one week.* It is the experiment that decides the "two sources" claim.

## 4. Verdict

There is a publishable paper now, but not the one drafted. Its title would be "A decompressor as a cellular-automaton rule: information spectrum, attractor census and designed attractors". Its contents:
- the decoder as a map: the bound, H₂ and H_∞, entropy decay against the random-map null, exact fixed points and the shuffle distribution;
- the Gray-coded inverse construction;
- one honest lattice section: oscillator medium, freezing of the deterministic rule, the `cycle3f` null, and entropy throughput between source and sink.

**Venue:** Complex Systems or Physica D; Entropy if the information spectrum leads. **Minimum work:** recommendations 1–3, the physicist's E0 and E1, and the computation reviewer's provenance and rotating-order fixes. That is two to three weeks, most of it already scripted. The "two sources of opportunity" paper on replicators and computational life needs recommendations 4–5 and the BFF census. It is a second paper, for Artificial Life or ALIFE, and it should declare the author's co-authorship of the 2024 paper.
