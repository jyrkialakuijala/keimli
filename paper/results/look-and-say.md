# Look-and-say on a 128-bit cell: an iterated coder whose entropy loss comes from the cut

2026-10-21. Transform kinds 50–64 (base = kind − 48; docs/changers.md). Scripts: the BigInt reference and probes in
`test/mix.test.mjs` (every base against the reference on 600 cells and on joined pairs); the attractor census, the
first-step bound and the unbounded comparison were run as one-off scripts during the session, and their numbers are
quoted here. The H₂ curves are from `experiments/entropy-curves.mjs` (results/entropy-manipulators.md).

## The two versions

**Unbounded** (Conway 1987).
- The sequence 1, 11, 21, 1211, … is the iteration of a run-length encoder.
- The map is one-to-one: a string has at most one parent.
- It grows by Conway's constant, about 1.3036 a step, and decomposes into his 92 "elements".
- From "1", the digit frequencies settle at 0.495, 0.320 and 0.184 for 1, 2 and 3. So the zeroth-order entropy stays
  at 1.478 bits a digit.
- General-purpose compressors see the information density fall towards zero:

  | term | digits | Deflate (bits a digit) | Brotli q11 (bits a digit) |
  |---|---|---|---|
  | 30 | 4,462 | 0.645 | 0.588 |
  | 40 | 63,138 | 0.153 | 0.124 |
  | 50 | 894,810 | 0.096 | 0.026 |
  | 55 | 3,369,156 | 0.092 | 0.015 |

- The content of term n is fixed (n and the start); only its length grows. Each element always decays into the same
  compound, and LZ-type compressors exploit that repeating structure while the per-digit entropy does not see it.

**Truncated to the cell**, as in Keimli.
- The cell's 128 bits are read as a number in base b. One look-and-say step is applied, and the result is cut to the
  cell's digit count, padded with zeros, and wrapped modulo 2¹²⁸.
- The map becomes many-to-one, and all its loss comes from the cut.

## The first step keeps at most the bits it reads

Each run of a random digit string costs at least two digits to describe, while it averages b/(b − 1) digits. So the
description is about 2(1 − 1/b) times longer than what it describes, and the step reads only the first 1/(2(1 − 1/b))
of the cell. The output is a function of the digits read, and that count is a stopping time. So by the argument of
DEFINITION.md, Lemma 3, H(f(U)) ≤ E[bits read]. The values below are from 2 × 10⁵ random cells per base:

| base | digits | E[bits read] (95 % CI) | prediction 128 / (2(1 − 1/b)) |
|---|---|---|---|
| 2 | 128 | 97.92 ± 0.03 | (run lengths in binary: not applicable) |
| 3 | 81 | 91.49 ± 0.03 | 96.0 |
| 4 | 64 | 85.10 ± 0.03 | 85.3 |
| 8 | 43 | 74.83 ± 0.02 | 73.1 |
| 10 | 39 | 73.02 ± 0.02 | 71.1 |
| 16 | 32 | 68.27 ± 0.02 | 68.3 |

- The bound is exact in form for bases 2, 4 and 16, where the digits are i.i.d. uniform.
- For the other bases the cell's top digit is restricted, so "bits read" is digits read × log₂ b scaled to the cell,
  an approximation.
- Base 3 falls below the prediction because runs of three or more need two-digit counts.

## Then the collapse

Collision entropy of a cell from random starts, the rewrite alone. These figures come from 20,000 cells (resolution
14.3 bits) and from the 131,072-cell entropy-curves run (resolution 33 bits):

| base | turn 1 | turn 8 | turn 16 | turn 64 | distinct cells at turn 64 (of 131,072) |
|---|---|---|---|---|---|
| 10 | > 33 | 3.7 | 1.6 | 1.2 | 10 |
| 16 | > 33 | 4.8 | 0.4 | 0.4 | 9 |

- Of 300 random cells per base, none ended on a fixed point, and almost all ended on a 3-cycle within about 12 turns.
- In bases 4, 7, 8, 10 and 12–16 the dominant cycle is the same digit string, a prefix of Conway's own
  1113122113121113222123211211131211121311121321…. On the digits 1–3 with runs shorter than the base, the rule does
  not depend on the base.
- Bases 2 and 3 have cycles of their own.
- In bases 5, 6, 9 and 11 the wrap makes the cycle; base 11's is a 2-cycle.
- On the lattice, decimal look-and-say shows Conway's 3-cycle with islands of the others. Binary shows a fine
  mottle. Hexadecimal locks the strongly settled rows into one cycle.

## What it gives the paper

1. **The cleanest instance of entropy reduction without computation.** One rule, two versions. Unbounded, nothing is
   lost and the strings grow without end. Cut to 128 bits, the entropy falls from 128 to at most 68–98 bits in one
   step and to about a bit within a dozen. Every self-maintaining type, the 3-cycles, is produced by the cut.
2. **The proxy argument in a worked example.** On the unbounded sequence the zeroth-order entropy stays constant,
   while LZ-type compression follows the true information density towards zero.
