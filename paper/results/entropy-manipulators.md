# Known entropy manipulators: calibrating the entropy measures

2026-10-21. `experiments/entropy-curves.mjs n=362 turns=64` (131,072 cells,
seed 1, quenched hashing, rotating swap order). Raw data
`../data/entropy/entropy-curves-n362-t64.json`.

**The question.** Which measurements of a cell's entropy can be trusted?
**The method.** Before reading them for the decoder, run them on rewriting
rules whose information loss is known exactly. These are the elementary
rules on the cell's 128 bits taken as a ring (kinds 256 + rule):
- rules 150 and 170 are bijections;
- rule 60 loses exactly 1 bit a turn;
- rule 90 loses exactly 2 bits a turn, and every cell is zero at turn 64.

The ring has 2⁷ bits, and over GF(2) x¹²⁸ − 1 = (x + 1)¹²⁸, so
multiplying by 1 + x⁻¹ (rule 60) or by x⁻¹(1 + x)² (rule 90) is nilpotent
[wolfram1983; Martin, Odlyzko and Wolfram 1984].

**The measures**, per turn, over all cells:
- **Collision entropy** of one cell, H₂ = −log₂ P(two cells equal), from
  the number of equal pairs. It is resolvable up to 2 log₂ N − 1 ≈ 33
  bits; above that it is reported as "> 33".
- **The number of distinct cells.**
- **The 8-bit block entropy per bit**, from windows of the ring pooled
  over cells and positions. This is the local measure of Wolfram 1983.

## Calibration: rule 90, the rewrite alone

| turn | exact entropy (bits) | measured H₂ | distinct cells | block-8 (bits/bit) |
|---|---|---|---|---|
| 40 | 48 | > 33 | 131,044 | 1.000 |
| 48 | 32 | > 33 | 131,044 | 1.000 |
| 52 | 24 | 23.95 | 130,516 | 1.000 |
| 56 | 16 | 16.00 | 56,674 | 1.000 |
| 60 | 8 | 8.00 | 256 | 1.000 |
| 64 | 0 | 0.00 | 1 | 0.000 |

- **Collision entropy is exact wherever it can resolve.** At turn 60 there
  are exactly 2⁸ distinct cells.
- **The block entropy is blind.** It reads a full bit per bit until the
  turn the lattice is all zero. Rule 90 removes information through
  constraints that span the whole ring, its image being a subspace of
  dimension 128 − 2t, and every 8-bit window stays uniform. A local
  measure therefore says nothing about how much a rule has destroyed. For
  the paper: Wolfram's block entropies measure local order, not
  information loss, and the whole-cell measures are the ones to report.
- **Rules 150, 170 and 60** stay above the resolution throughout, as they
  should: 60 loses only 64 of its 128 bits in 64 turns.

## The same measures on the other rewriting rules

H₂ in bits (> 33: above the resolution) and the distinct cells at turn 64:

| rule | setting | t1 | t8 | t16 | t64 | distinct at t64 | block-8 at t64 |
|---|---|---|---|---|---|---|---|
| rule 90 | the rewrite alone | > 33 | > 33 | > 33 | 0.0 | 1 | 0.000 |
| rule 90 | swap ½, median 1 | > 33 | > 33 | 33.0 | 29.7 | 131,034 | 1.000 |
| rule 150 | swap ½, median 1 | > 33 | > 33 | > 33 | > 33 | 131,044 | 1.000 |
| rule 170 | swap ½, median 1 | > 33 | 26.6 | 24.3 | 20.7 | 126,438 | 1.000 |
| look-and-say, base 10 | the rewrite alone | > 33 | 3.7 | 1.6 | 1.2 | 10 | 0.920 |
| look-and-say, base 16 | the rewrite alone | > 33 | 4.8 | 0.4 | 0.4 | 9 | 0.613 |
| decoder, Swarm F | the rewrite alone | 16.6 | 3.5 | 1.8 | 1.6 | 7 | 0.478 |
| decoder, Swarm F | swap ½, median 1 | 16.8 | 4.3 | 1.3 | 0.5 | 2,766 | 0.479 |
| decoder, 20 Gray 8-cycles | the rewrite alone | 19.7 | 6.0 | 5.9 | 5.8 | 162 | 0.850 |
| Z80, 256 instructions | the rewrite alone | 12.9 | 12.5 | 12.5 | 12.5 | 121,647 | 0.928 |
| Z80, 256 instructions | swap ½, median 1 | 12.9 | 19.2 | 16.9 | 13.7 | 40,651 | 0.239 |

**Decoder and look-and-say.** Both destroy information far faster than
the known manipulators:
- **The decoder's first step** takes 128 bits to 17 to 20 (collision
  entropy).
- **Look-and-say's first step** stays above 33 bits. As estimated from
  the part of the cell it reads, it keeps about 70.
- **Within 16 turns** both are within a few bits of their attractors:
  - Swarm F's 1.6 bits is the phase of its 3-cycle (log₂ 3 = 1.58).
  - The Gray design's 162 distinct cells are its 20 cycles of 8 states
    (160) and two strays.

**Mixing and settling.** They hold rule 90 near 30 bits. They put back
what the rule removes, so the lattice's entropy is a balance and not a
decay. Under rule 170 settling alone orders the lattice slowly, to 21
bits by turn 64. Rule 150, which spreads every bit across the ring, keeps
the settling from ordering anything that this measure can see.

**The processor.** The Z80 is different in kind. Alone it leaves 121,647
of 131,072 cells distinct, so most programs destroy little information,
and the collision entropy of 12.5 bits comes from one heavily shared
state. Under mixing and settling the cells become locally ordered (block
entropy 0.24) while staying more varied than under the decoder. A
processor, then, is not simply a stronger eraser. For the thesis: the
decoder's structure is accounted for by its erasure, which is fast,
large and measured exactly like the known rules'. The processor's is
not, and needs the further measures the panel listed (information
dynamics, dose–response over instruction budgets).

## For the draft

- Report whole-cell entropies (collision entropy, distinct cells) and
  calibrate them on rules 90, 60 and 150. Do not use block entropies as
  evidence of information loss.
- The sentence: "a many-to-one rule organises a lattice by losing
  information [wolfram1983]; the decoder does so at about 110 bits in its
  first step, rule 90 at exactly 2 bits a turn, and a Z80 running 256
  instructions hardly at all."
