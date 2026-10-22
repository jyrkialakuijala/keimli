# The processor dose-response: erasure against computation, at matched measures

2026-10-21. `experiments/dose.mjs`; figure `../figures/dose-response.png` (`dose-plot.py`); the full table is `dose-table.md` (regenerate with `dose-summary.mjs`); raw data
`../data/dose/`. Setup:
- **Processors.** Six (Brainfuck, Z80, 6502, Subleq, RISC-V, Redcode), each at instruction budgets of 1 to 256 per cell
  per turn, every cell its own 16-byte memory.
- **References.** The decoder (Swarm F, Brotli 12), look-and-say in base 10, and rule 90.
- **Run.** 128² cells, seed 1, the rotating swap order.
- **Measures.** As in `entropy-manipulators.md`: whole-cell collision entropy H₂, resolvable to about 27 bits here;
  distinct cells; attractor types; the 8-bit block entropy.
- **A fix this experiment found.** The harness overwrote the instruction budget when it installed the dictionary. Before
  this fix every harness run used 256 instructions whatever was asked; runs that asked for 256, including every
  earlier result, are unaffected. Brainfuck ignores the budget and stops at a fixed 1,024 steps.

## What separates the rules

| rule | map: H₂ after 16 turns | map: attractor types of 16,384 cells | lattice: H₂ | lattice: distinct cells | lattice: leading type | lattice: block-8 entropy |
|---|---|---|---|---|---|---|
| decoder, Swarm F | 1.8 | 1 | 0.1 | 56 | 100 % | 0.42 |
| decoder, Brotli 12 | 3.3 | 3 | 1.0 | 133 | 57 % | 0.68 |
| look-and-say, base 10 | 1.5 | 4 | 0.0 | 1 | 100 % | 0.73 |
| rule 90 (2 bits a turn) | > 27 | 1 (all zero by turn 64) | 11.3 | 15,916 | 2 % | 0.92 |
| Z80, 256 instructions | 12.4 | 15,456 | 11.2 | 4,965 | 0 % | 0.23 |
| 6502, 256 | 7.1 | 11,512 | 10.6 | 4,436 | 1 % | 0.51 |
| Subleq, 256 | > 27 | 15,247 | 11.4 | 5,303 | 0 % | 0.21 |
| RISC-V, 256 | > 27 | 15,599 | 13.0 | 9,947 | 0 % | 0.62 |
| Redcode, 256 | 17.4 | 14,195 | 7.4 | 10,002 | 7 % | 0.82 |

1. **The decoder and look-and-say collapse the cell.** One to four attractor types take every random cell, and on the
   lattice one type holds 57–100 % of the cells. This is the whole-cell erasure measured in `entropy-manipulators.md`.
2. **Processors keep the cell.** Nearly every random cell ends on an attractor of its own (9,400–16,384 types, mostly
   fixed points where the program has stopped writing). The map's collision entropy stays high (7–27+ bits). On the
   lattice no type leads.
3. **Processors order the lattice locally without collapsing it.** As the budget grows, the 8-bit block entropy on the
   lattice falls steadily: Z80 from 0.98 at one instruction to 0.23 at 256, Subleq 0.99 to 0.21. Meanwhile thousands
   of distinct cells remain. At 256 instructions the Z80 and rule 90 have the same whole-cell entropy (11.2 and 11.3
   bits) but very different local order (0.23 against 0.92). So the two entropy measures separate for processors and
   coincide for the decoder.
   - This is the measurable form of the thesis's two sources: the decoder's structure is whole-cell erasure; the
     processor's is local ordering of memory, with most of the cell's information kept.
4. **The dose-response is monotone in the local order and not in the attractors.**
   - Block entropy falls with the budget for every processor.
   - The map's attractor structure saturates by 8–16 instructions.
   - One non-monotone exception: the 6502 at 16 instructions, where a 2-cycle type takes 36 % of the lattice (H₂ 3.6
     bits, 341 distinct cells). That type is not the map's largest basin (13 %, a 3-cycle), and it is gone at 8 and at
     32 instructions. It is the one processor setting in which a type takes over the lattice, a candidate replicator
     for the second paper, and it needs a census of its own.

## What it does and does not show

- **Shown.** At matched whole-cell entropy, processors and the decoder build different structure: local order with
  most information kept, against whole-cell collapse onto a handful of types. The decoder's dominant types are
  accounted for by its erasure. The processors' structure is not, and needs a different explanation.
- **Not shown.**
  - That the difference is "computation" in any stronger sense; the next measure would be Lizier's information
    modification.
  - Anything about joined programs from this table alone; see the next section.
  - Seeds other than 1; sizes other than 128².

## Joined programs: two cells share one 32-byte memory (pair = 1, the BFF-like setting)

Leading type's share of the lattice at turn 400 (swap ½, median 1), against the instruction budget:

| rule | 8 | 16 | 32 | 64 | 128 | 256 |
|---|---|---|---|---|---|---|
| Redcode | 0 % | 6 % | 23 % | 30 % | 58 % | 85 % |
| 6502 | 2 % | 61 % | 16 % | 37 % | 13 % | 1 % |
| Z80, RISC-V, Subleq, Brainfuck | ≤ 1 % | ≤ 1 % | ≤ 1 % | ≤ 1 % | ≤ 1 % | ≤ 1 % |

- **Redcode's leader is the imp.** The leading states fill the cell with one repeated instruction:
  - `MOV $0, <1`: 86 % at 256 instructions;
  - `MOV $0, $1`, Core War's classic imp: the leader at 64 instructions, 30 %;
  - `MOV $0, @1`.

  Each copies itself to the next address. A memory full of imps is unchanged by running it, so it is a fixed point of
  the cell map.
- **Takeover rises with the budget, in every seed.** More instructions a turn copy faster. Leading share at turn 400 over
  five seeds (seed 1 in the table above):

  | instructions | seeds 1–5 | mean |
  |---|---|---|
  | 16 | 6, 17, 14, 12, 11 % | 12 % |
  | 64 | 30, 55, 26, 72, 41 % | 45 % |
  | 256 | 85, 73, 60, 92, 76 % | 77 % |
- **Takeover times** (`replicators.mjs`, 128², 1,000 turns, 5 seeds, `../data/candidate/`). The imp's fixed point,
  with a basin of 0.6 % under the map alone, reaches half the lattice:
  - on the page frame in 5 of 5 seeds, Kaplan–Meier median turn 144 (95 % interval 114–195);
  - under uniform settings in 3 of 5 seeds, median 678.

  As with the decoder's rare fixed points, the medium, not the basin, picks it, and the frame picks it fastest.
- **What it shows.** The one processor that produces a dominant replicator on this lattice produces Core War's trivial
  self-copier, and the type that takes over is a fixed point. This supports, in the processor arm itself, the paper's
  claim that the replicators of computational life are fixed points and short cycles of the local map.
- **The 6502 on pairs.**
  - At 16 instructions one type takes 61, 69 and 63 % of the lattice in seeds 1–3: a 16-byte state, `00 34 09 00 34 28
    00 34 08 00 08 00 08 00 02 00` in seed 1, not yet decoded.
  - At 32 instructions the leader falls to 16–34 %, and at 64 to 33–42 %. So the response to the budget is not monotone.
  - On single cells, the 6502's 16-instruction leader is a 2-cycle. Across five seeds at turn 1,000 it holds only 8–12 %
    under uniform settings (3 passes) and 2–4 % on the frame (`../data/candidate/`). The single-cell 36 % in the first
    table (1 pass, seed 1) is not robust.
- **No other processor produces a leading type**, single or joined, at any budget tested.
- **The decoder on joined pairs** loses its single dominant type: 12 attractor types, the leader at 3 %, H₂ 7.8 bits.
  Joining two cells doubles the input the decoder reads from and breaks its collapse.
