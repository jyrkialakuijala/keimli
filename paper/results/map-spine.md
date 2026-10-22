<!-- provenance: written from paper/data/map/ (exact-ca-swarm-f-K1.json: paper/experiments/map-exact.mjs (9515d4f3d97a0e2d) ca-swarm-f 1 2 | commit 48f9653+dirty | wasm 90ec8c30bca92b5b | 2026-10-21T13:20:15.534Z; the other files carry their own provenance fields) -->

# Results: the map spine (exact periodic points, the random-mapping null, the shuffle distribution)

2026-10-21. The three analyses the journal and team syntheses asked for, all on
the single-cell decoder map f (kind 36) at the reference setting: dictionary
`ca-swarm-f` (4,400 bytes, the file as shipped), header range V = 4096
(12 header bits), 6 skipped bits, offset 0. Scripts:
`paper/experiments/map-exact.mjs`, `map-null.mjs`, `map-shuffles.mjs`
(`map-shuffles-exact.sh` runs the exact search on the shuffles),
helpers in `map-lib.mjs`. Data: `paper/data/map/` (JSON with a `provenance`
field; the Markdown tables `null-ca-swarm-f.md` and `shuffles-ca-swarm-f.md`).
The fast JavaScript decoder used for iteration (`map-lib.mjs` `fastF`) agrees
with `decode36.mjs` on 200,000 random cells and with the WebAssembly module on
100,000 (0 mismatches).

## 1. Fixed points: exact

**Method.** A depth-first search over the bitstream. The decoder reads the
cell's bits in its own order (bits 6, 7, …, 127, then wrapping round to 0, 1,
…); every bit starts unknown and the search branches on a bit's value when the
decoder first reads it. Every output byte the decoder writes is, for a fixed
point, the cell's own byte at that position, so each write is checked against
the bits already known there and fixes the rest; a contradiction prunes the
branch. Literal bits are written as they are read. Re-read bits (after the
wrap) take their known value. The 12 header bits split the tree into 4,096
independent subtrees (worker threads). A leaf is reached when 16 bytes have
been produced; then every bit of the cell is known and f(x) = x holds by
construction. Distinct leaves differ in a branched bit, so leaves and fixed
points correspond one to one. The 1,024-bit read cap is unreachable (each pass
of the command loop writes at least 2 bytes and reads at most 4 + 56 + 5 + 1 +
6 + 2 bits) and the engine asserts it. The search is complete without any
bound: nothing was capped.

**Validation.** It reproduces the round-2 mathematician's partial counts
exactly (header 3232: 44, header 1: 4, headers 64 and 777: 0). Every leaf was
re-checked in the workers with the fast reference (0 failures); the 64,163
stored points were re-checked with `decode36` and with the wasm; and
`--verifyall` re-expanded every family (below) over all values of its free
bytes through the **WebAssembly module: all 68,964,123 are fixed points, 0
failures, and the expanded total equals the search's count**
(`exact-ca-swarm-f-K1-verifyall.json`). Sampling cross-check (10⁶ random
cells, 300 + up to 600 iterations, `exact-ca-swarm-f-sample1000000.json`): the
3 distinct fixed points reached are all in the exact list.

**Result (exact).** Swarm F has **exactly 68,964,123 fixed points** at the
reference setting (1.46 · 10¹⁰ search nodes, 48 s on 16 threads without
per-leaf checks). They lie in only **110 of the 4,096 dictionary windows**.
The large number is a single mechanism, the *self-read literal*: when the read
cursor sits exactly on the byte the decoder is about to write as a literal
(read position = 8 × output position), the literal reads the very bits it
writes and any value of that byte is consistent. Blanking such bytes groups
the fixed points into **15,693 families**:

| free (self-read) bytes | families | fixed points |
|---|---|---|
| 0 (isolated fixed points) | 15,643 | 15,643 |
| 1 | 18 | 4,608 |
| 2 | 28 | 1,835,008 |
| 3 | 4 | 67,108,864 |
| total | 15,693 | 68,964,123 |

The four 3-free-byte families are all in window 69; the 28 2-free-byte families
sit in 28 windows, 26 of them ≡ 5 (mod 32) from 5 to 997, plus 897 and 2311
(65,536 points each); the 1-free-byte ones are in windows 1285 and 1927. A
family is a fact of the grammar, not an attractor: each of its members is a
separate fixed point with its own basin. The three fixed points that sampling
reached (`3c3c0243…`, `282881c2…`, `282880c2…`) are all isolated (no
self-read byte), with 1–2 hits per 10⁶ starts (largest basin seen 2 · 10⁻⁶).
Every fixed point found has a basin below 10⁻⁵ under uniform starts; none is
among the attractors that matter on the lattice under uniform settling.

## 2. Two-cycles: complete only within a stated class

**What is infeasible.** The same search on the pair (x, y) with f(x) = y,
f(y) = x (two resumable decoders, each writing the other's cell) is complete
in principle but too large: Knuth random-probe estimates give 10¹³–10¹⁴ nodes
per header of x (≈ 10¹⁷ in all; the plain fixed-point search is ≈ 4 · 10⁶
per header), and runs capped at 2–3 · 10⁹ nodes per header, or per pair of
headers (x's and y's), never finished. The reason: decoder 1's writes into x
only overtake decoder 0's reads after about six output bytes, so about 30
bits of x are read unconstrained. A symmetric scheme (branching on whichever
decoder has read less) did not help. **The full set of 2-cycles of F is not
known.**

**What is exact.** A class defined by agreement: *all 2-cycles {x, f(x)} in
which x and f(x) agree on bytes 2 to 9* (tie mask 0x3fc; bytes 0, 1 and 10–15
may differ; this covers the header bits only partly, so x and y may use
different windows). Tying makes the search as tractable as the fixed-point
search (4.6 · 10¹⁰ nodes, 10 min on 8 threads; the two headers capped at 10⁹
nodes, 1285 and 1927, were rerun uncapped and contain none). **Exactly 49
two-cycles (98 points) lie in that class**, in 23 windows of x; all 98 points
were verified with decode36 and the wasm. x and f(x) differ in 1 to 7 bytes
(14 cycles differ in one byte), 2 to 31 bits. Wider classes (agreement on
bytes 2–5 or 2–7) exceed 3 · 10⁸ nodes in most of the test headers and were
not run.

**Sampling cross-check.** 10⁶ random cells reach 8 distinct 2-cycles
(45 samples). The 6 of them that lie in the class are all in the exact list.
The other 2 (`5050c1c1…` ↔ `2828180a…`, two pairs; x and f(x) differ in 13
and 15 bytes) lie outside it, so the class misses 2-cycles that sampling finds.
They have basins of 2–5 · 10⁻⁶.

What may be claimed: "F has at least 51 two-cycles: 49 found exactly within
the class of cycles whose two points agree on bytes 2–9, plus 2 outside it
found by sampling. All 2-cycles reached from 10⁶ random cells have basins
≤ 4 · 10⁻⁵." The total number of 2-cycles is not claimed.

## 3. The random-mapping null

`map-null.mjs`, N = 10⁶ uniformly random starts, T = 300 steps (table
`paper/data/map/null-ca-swarm-f.md`). H2 = −log₂ of the unbiased collision
probability among the N states; H∞ = −log₂(largest share).

| map | H2 k=1 | k=2 | k=4 | k=8 | k=16 | k=32 | k=64 | k=256 |
|---|---|---|---|---|---|---|---|---|
| decoder, Swarm F | 16.50 | 12.62 | 7.50 | 3.50 | 1.80 | 1.59 | 1.58 | 1.58 |
| P-random map (F's one-step law), seed 1 | 16.44 | 15.44 | 14.47 | 13.51 | 12.58 | 11.67 | 10.75 | 8.68 |
| uniform random map, n = 2^(H2+1) = 185,734, seed 1 | 16.50 | 15.91 | 15.17 | 14.30 | 13.38 | 12.45 | 11.54 | 9.77 |
| uniform random map, n = 2^24 | 22.93 | 22.33 | 21.57 | 20.71 | 19.79 | 18.84 | 17.86 | 15.88 |
| Flajolet–Odlyzko, n = 2^128 (≈ 128 − log₂(k+1)) | 127.0 | 126.4 | 125.7 | 124.8 | 123.9 | 123.0 | 122.0 | 120.0 |

| map | cycles reached | largest basin | on a cycle by k = 4 / 16 / 64 | tail mean / p99 / max | periods (share of samples) |
|---|---|---|---|---|---|
| decoder, Swarm F | 11 | 99.995 % | 5.2 % / 92.8 % / 100 % | 9.6 / 26 / 41 | 3: 99.995 %; 1, 2, 4: 3, 5, 2 cycles, ≤ 4 · 10⁻⁵ each |
| P-random map, seeds 1 / 2 / 3 | 4 / 2 / 5 | 98.2 / 99.2 / 98.3 % | 1.3 / 5.2 / 19.6 % (seed 1) | 263 / 351 / 281 (means) | 163, 169, 120 (the dominant cycles) |
| uniform, n = 185,734, seeds 1 / 2 / 3 | 9 / 9 / 8 | 49.6 / 70.3 / 85.4 % | 2.5 / 8.7 / 26.6 % (seed 1) | 169 / 206 / 278 (means) | 304, 303, 234 (dominant) |
| uniform, n = 2^20, seeds 1–3 | 5 / 11 / 8 | 38.7 / 89.3 / 78.5 % | ≈ 1 / 4 / 14 % | 335 / 363 / 471 | 668, 1957, 626 |
| uniform, n = 2^24, seeds 1–3 | 7 / 7 / 6 | 99.9 / 48.1 / 89.8 % | < 0.5 % by 16 | 3,101 / 1,888 / 4,333 | 883, 2306, 1305 |

The nulls:

- **Flajolet–Odlyzko at n = 2^128** (exact asymptotics): ½ ln n = 44.4 cycles
  expected, about 2^64.3 cyclic points, expected rho length 2^64.3, largest
  component 75.8 % of the space, 1 fixed point and ½ two-cycle expected;
  image after k steps a fraction 1 − τ_k ≈ 2/k (τ₀ = 0, τ_{k+1} = e^{τ_k − 1});
  H2(f^k(U)) ≈ 128 − log₂(k+1). A uniform random map on the cell space loses
  1 bit at the first step and log₂(k+1) bits by step k; 10⁶ samples would
  see no collision at all.
- **hash:93** (the lattice null of `ablation.mjs`, matched in Shannon H(f(U)) =
  93 bits): keep 93 bits and hash them into the rest. It is idempotent,
  g(g(x)) = g(x) for every x (checked on 10⁵ samples, 100 %): every image point
  is a fixed point, so it has 2^93 attractors, all fixed points, each with a
  basin of 2^35 cells. It matches the decoder's one-step entropy and is the
  opposite of the decoder in attractor structure. It cannot serve as an
  iteration null.
- **Uniform random map matched in H2** (n = 2^(H2+1) = 185,734 points, exact
  functional graph, three seeds): the one-step H2 is the decoder's 16.50 by
  construction; under iteration it loses about 1 bit per doubling of k, as
  Flajolet–Odlyzko predict.
- **P-random map, matched in the whole one-step law** (each state maps to an
  independent draw from the decoder's own output distribution, estimated from
  an independent 10⁶ sample: the 3,087 outputs seen twice or more, carrying
  1.5 % of the mass, as atoms with weight c/N, the remaining 98.5 % as a
  never-repeating tail; H2 16.47, H∞ 8.25 against the decoder's 16.50 / 8.27).
  Implemented as an exact deterministic map: an atom's successor chain runs
  through fresh tail states (mean chain length 67) to the next atom, so
  cycles, tails and basins are exact for each realisation (three seeds).

**Finding.** With the same one-step contraction (H2 16.5, H∞ 8.3), a random
map loses about one bit of H2 per doubling of the number of steps. After 16
steps it keeps H2 ≈ 12.6–13.4 bits, its trajectories need 170–350 steps on
average to reach a cycle, and its dominant cycles have periods 120–304. The
decoder drops to H2 = 1.80 by k = 16 (four to five bits per doubling) and
puts 92.8 % of samples on its cycles by k = 16 (100 % by k = 64; mean tail
9.6, maximum 41). One 3-cycle takes 99.995 % of the samples. The decoder's
attractor structure, few short cycles with one huge basin, is **not** what a
random map with the same one-step contraction gives. The difference is in the
iterates: f restricted to its own image contracts far more than f on uniform
inputs. A random map draws fresh independent outputs at every step.
(Caveat: the P-law's atoms are the outputs seen at least twice in 10⁶ samples.
A larger sample would add rarer atoms; that changes the tail mass, not the
heavy atoms that set H2.)

## 4. The shuffle distribution

`map-shuffles.mjs`: the original and 30 byte shuffles and 30 word shuffles
(`dict-variants.mjs`, seeds 1–30). Census from 10⁵ random cells (the same cells
for every dictionary), 200 steps and then a return within 200 more steps. The
exact fixed-point counts come from `map-exact.mjs` on each variant
(`map-shuffles-exact.sh`). Per-dictionary rows are in
`paper/data/map/shuffles-ca-swarm-f.md`. Rank 1 = the smallest value among the
original and its 30 controls.

| statistic | F | byte shuffles: median [min, max] | F's rank of 31 | word shuffles: median [min, max] | F's rank of 31 |
|---|---|---|---|---|---|
| attractors reached (10⁵ starts) | 5 | 5 [1, 11] | 15 (4 tied) | 3 [1, 6] | 26 (4 tied) |
| largest basin | 0.99993 | 0.948 [0.479, 1.000] | 26 | 1.000 [0.535, 1.000] | 21 |
| H2, k = 1 | 16.65 | 21.87 [20.88, 22.17] | 1 | 17.07 [16.59, 17.35] | 2 |
| H2, k = 4 | 7.49 | 12.67 [12.29, 13.70] | 1 | 8.44 [7.54, 9.57] | 1 |
| H2, k = 16 | 1.80 | 5.40 [2.82, 7.12] | 1 | 2.33 [1.74, 5.12] | 4 |
| H2, k = 64 | 1.58 | 3.61 [1.58, 5.43] | 1 | 1.59 [1.58, 4.43] | 14 |
| H∞, k = 1 | 8.34 | 10.94 [10.44, 11.12] | 1 | 8.55 [8.31, 8.70] | 2 |
| mean period (by sample) | 3.00 | 8.76 [3.00, 48.0] | 2 | 3.00 [3.00, 38.4] | 6 |
| fixed points (exact) | 68,964,123 | 2,108,922 [1,125,950, ≥ 500,534,803] | 24 | 68,958,221 [1,252,897, 136,462,035] | 17 |
| fixed-point families | 15,693 | 8,765 [8,090, 13,676] | 31 | 13,590 [7,477, 16,924] | 29 |
| isolated fixed points | 15,643 | 8,725 [8,063, 9,491] | 31 | 13,162 [4,976, 15,393] | 31 |

Completeness of the exact counts: shuffles 1–6 ran with a per-header cap of
10⁹ nodes, all later ones with 2 · 10⁸ (F's largest header needs 1.6 · 10⁸).
Seven variants hit the cap in one header each: byte shuffles 6, 16, 22 and
word shuffles 13, 24, 25, 26. Their counts are lower bounds, so the minima,
maxima and ranks involving them are bounds too. In particular, F's rank 31 for
isolated fixed points among the word shuffles is certain against the 26
complete ones only; the 4 capped ones show at least 4,976–12,340.

Reading.

- **Against byte shuffles (F's byte histogram, order destroyed), F is extreme
  on every contraction statistic.** It has the lowest H2 at every k and the
  lowest H∞ of all 31, the most isolated fixed points and the most families.
  The byte shuffles contract less (H2 21.9 bits after one step against 16.7)
  and reach longer cycles (median mean period 8.8, up to 48). The byte
  statistics alone do not produce F's attractor structure.
- **Against word shuffles (F's words, their order destroyed), F is typical
  in attractor structure and only mildly extreme in contraction.** The word
  shuffles also collapse onto one dominant short cycle (median largest basin
  1.000, median mean period 3). In 5 of 30 the dominant attractor is F's own
  3-cycle `28281014282850505050505041414141` (`((\x10\x14((PPPPPPAAAA`). F
  ranks 1–4 in H2 for k ≤ 16, but by k = 64 most word shuffles have reached
  the same log₂ 3 floor (rank 14). The structure that matters is carried by
  the words, as the decoder-map second-order result already suggested; the
  word order adds a little contraction at small k.
- **The raw fixed-point count is not a dictionary property worth ranking.**
  Totals jump in steps of about 2^24 (≈ 1.3, 2, 69 or 136 million) according
  to how many 3-free-byte self-read families a variant happens to have. The
  free-byte mechanism belongs to the command grammar and the window position,
  not to the content. Isolated fixed points and families are the meaningful
  counts. F has more of them than every byte shuffle (8,063–9,491) and every
  complete word shuffle (7,457–15,393).

What may be claimed: "Swarm F's contraction under iteration, and its single
dominant 3-cycle, are not explained by its byte histogram: F contracts more
than all 30 byte shuffles at every step count measured. They are largely
explained by its words: word shuffles reach the same structure, often the
same attractor, and F is at most mildly extreme among them." The search
(Swarm F was selected for a lattice score) found a dictionary whose words do
the work.

## 5. What the paper may claim

- **Exact:** F has exactly 68,964,123 fixed points at the reference setting,
  in 15,693 families by self-read literal bytes (15,643 isolated fixed points
  plus 50 families with 1–3 free bytes), in 110 of the 4,096 windows; every
  one of them was verified with the WebAssembly module. "No fixed points" is
  false; "few fixed points" is false; "no fixed point with a measurable
  basin" is supported by sampling (largest basin seen 2 · 10⁻⁶, 10⁶ starts)
  but is not exact.
- **Exact within a class:** 49 two-cycles whose two points agree on bytes 2–9.
  **Lower bound:** F has at least 51 two-cycles. The total is not known; the
  full search is estimated at about 10¹⁷ nodes.
- **Sampled, against exact nulls:** the decoder's iterated contraction (H2
  16.5 → 1.8 bits in 16 steps; 99.995 % of starts on one 3-cycle, mean tail
  9.6) far exceeds that of random maps matched in the one-step collision
  entropy, and in the whole one-step law (H2 ≈ 12.6–13.4 at k = 16; tails
  170–350; cycles of period 120–304). hash:93, the lattice null matched in
  H(f(U)), is idempotent and has 2^93 fixed-point attractors. So "any map
  with the decoder's contraction" is not a valid description of its
  attractors. The structure is in the iterates.
- **Shuffles:** F contracts more than all 30 byte shuffles (rank 1 of 31 on H2 at k = 1, 4, 16 and 64 and on H∞); among its 30 word shuffles its attractor structure is typical (one dominant short cycle, often the same 3-cycle) and its contraction ranks 1–4 for k ≤ 16, 14 at k = 64.
- Not claimed: anything about periods ≥ 3 beyond sampling, about other
  settings (V, skip) or dictionaries, or about the lattice.

Reproduce: `node paper/experiments/map-exact.mjs ca-swarm-f 1 16`;
`node paper/experiments/map-exact.mjs ca-swarm-f 1 --verifyall`;
`node paper/experiments/map-exact.mjs ca-swarm-f 2 8 raw 1 all tie=1020 sym=0 nodecap=1000000000`
(then the capped headers with `… 1285,1927 … nodecap=0`);
`node paper/experiments/map-exact.mjs ca-swarm-f 1 --sample=1000000`;
`node paper/experiments/map-null.mjs 1000000 300`;
`node paper/experiments/map-shuffles.mjs 100000 4`; `sh paper/experiments/map-shuffles-exact.sh ca-swarm-f 7`;
`node paper/experiments/map-shuffles.mjs --table`.
