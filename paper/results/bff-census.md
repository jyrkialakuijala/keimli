# The BFF census: fixed points of the pair map, and heredity

2026-10-21. The editors' "BFF census" (PNAS, BioSystems): are the replicators that emerge in BFF [agueraYarcas2024]
fixed points or short cycles of the interaction map, as Keimli's replicators are of its local map, and are their
mutations inherited, unlike Keimli's, whose mutants are repaired (`mechanism.md` §5)? Script
`../experiments/bff.mjs` (interpreter, soup, census, report, self-test); raw data `../data/bff/` (git-ignored JSON).

<!-- provenance: paper/experiments/bff.mjs (d1fe4dc5d7e83f40) census in=paper/data/bff/soup-n131072-m0.000244140625-s2.json,paper/data/bff/soup-n131072-m0.0009765625-s3.json,paper/data/bff/soup-n131072-m0.0009765625-s4.json,paper/data/bff/soup-n32768-m0.0009765625-s6.json top=3 hex=5b5b7b2e3e5d2d5d2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020205d2d5d3e2e7b5b5b nx=256 nlin=16 bins=/tmp/claude-1000/-home-jyrki-life/1528f620-29d4-4b78-a5f7-6d337385d757/scratchpad/soups out=paper/data/bff/census.json | commit 48f9653+dirty | wasm 90ec8c30bca92b5b | 2026-10-21T15:24:07.756Z -->
<!-- provenance: paper/experiments/bff.mjs (d1fe4dc5d7e83f40) validate | commit 48f9653+dirty | wasm 90ec8c30bca92b5b | 2026-10-21T15:25:42.861Z -->
<!-- provenance: paper/experiments/bff.mjs (1f8e56473c3a1dba) soup seed=2 n=131072 mut=0.000244140625 epochs=12000 after=768 every=16 scratch=/tmp/claude-1000/-home-jyrki-life/1528f620-29d4-4b78-a5f7-6d337385d757/scratchpad/soups | commit 48f9653+dirty | wasm 90ec8c30bca92b5b | 2026-10-21T15:15:53.621Z -->

## Summary

- **The implementation is cubff's.** The paper names `--lang bff_noheads` of its reference code as "the BFF variant
  from Section 2". `bff.mjs` reproduces that code's own regression log (`testdata/bff_noheads.txt`: 2^17 tapes,
  seed 10248, 257 epochs) to the byte: all 5 logged Brotli sizes and high-order entropies are equal (§1).
- **Replicators emerged in 4 of 8 soups** (§2): 1 of 2 at the paper's setting (2^17 tapes, 0.024 % mutation) within
  12,000 epochs (at epoch 11,585), 2 of 2 at 2^17 tapes with 4× the mutation (epochs 4,833 and 7,633), 1 of 4 at 2^15
  tapes with 4× the mutation (epoch 4,849; three runs of 30,000–48,000 epochs saw none).
- **Every evolved replicator is a fixed point of the pair map after one step, and absorbs its partner** (§3). For all
  12 dominant tapes R and 256 random partners X, g(R|X) = (R | mirror R) in 256 of 256 cases: R is left intact and its
  byte-reversed image overwrites the partner, whatever the partner was. (R|mirror R) is a fixed point of g, (R|R)
  reaches it in one step, and the line R → mirror R → R is a 2-cycle of offspring. With R second, R is never copied
  and survives in only 16–23 % of encounters. Two families of copy loops, "[{ . > ]" (seeds 3, 4, and the paper's
  Fig. 4) and "[ < , } ]" (seeds 2, 6).
- **Unlike Keimli's, BFF's mutations are inherited** (§4). Of single-byte mutants drawn as the soup draws them (a
  uniform random byte), 80–85 % breed true (the mutant, or its mirror, copies itself exactly for 8 generations), 0.0 %
  revert to R, 15–18 % stop copying. Every tested change of a non-instruction byte to another non-instruction value is
  inherited (100 % in all 12 replicators, n = 240–270 each); all 48–54 such positions of each replicator can be redrawn
  at once and the tape still breeds true (64 of 64 trials each). Keimli's attractor types repair 73–100 % of their
  one-bit mutants and pass on almost none (0 for 7 of 8 types, 1.6 % for one).
- **The entropy view** (§5). Takeover drops Brotli's estimate from 7.4–7.8 to 1.3–3.2 bits a byte, and the tapes'
  collision entropy from ≥ 29–33 bits (the resolution limit) to 13–18 bits, but 28–88 % of the tapes stay distinct:
  the soup is a cloud of neutral variants of a few copiers, not a collapse onto a few states as under the decoder
  (128 → 17–20 bits in one step; 7 distinct cells after 64 turns).

## 1. Setup and validation

**Semantics** (cubff `bff.inc.h` without `BFF_HEADS`, `common_language.h`): 64-byte tapes; two concatenated into 128
bytes; the instruction pointer, head0 and head1 all start at 0; heads are taken mod 128; `< >` move head0, `{ }`
head1, `- +` change the byte at head0, `.` copies head0's byte to head1, `,` head1's to head0; `[` jumps past its
matching `]` if the byte at head0 is 0, `]` back to its matching `[` if it is not; an unmatched bracket halts; at most
2^13 = 8,192 bytes are read (no-ops count); the 128 bytes are split back. The soup: a fresh random permutation each
epoch, paired consecutively (first, second); before each run each of the 128 bytes is replaced by a uniform random byte
with probability round(p·2^30)/2^30 (p = 1/4096 = 0.024 % by default); cubff's SplitMix64 streams for initialisation,
shuffle and mutation, so a seed gives cubff's run. Measures every 16 epochs: Brotli quality 2, window 24 (cubff's),
byte entropy H₀, high-order entropy H₀ − Brotli bits a byte (the paper's), and per tape: collision entropy H₂, distinct
tapes, the most common tape's share.

**Self-test** (`node paper/experiments/bff.mjs selftest`, 12 checks, all pass): SplitMix64 on 32-bit halves against a
BigInt reference; hand-traced programs for each instruction, head wrap-around, unmatched `]` and `[`, a counted loop
(`<[-]` on 3: 8 ops), a forward jump over nested brackets, the 8,192-step limit (`[]`: exactly 8,192 ops), and the
paper's Fig. 4 replicator `[[{.>]-] … ]-]>.{[[` with its middle as 0x20 mapping (R|X) to (R|R) for 20 partners.

**Validation against cubff's regression log** (`node paper/experiments/bff.mjs validate`, `../data/bff/validate.json`):

| epoch | cubff testdata/bff_noheads.txt | bff.mjs |
|---|---|---|
| 1 | `1,8388776,131072,-0.000190` | `1,8388776,131072,-0.000190` (equal) |
| 65 | `65,8286015,131072,0.097342` | `65,8286015,131072,0.097342` (equal) |
| 129 | `129,8216575,131072,0.162708` | `129,8216575,131072,0.162708` (equal) |
| 193 | `193,8161711,131072,0.213831` | `193,8161711,131072,0.213831` (equal) |
| 257 | `257,8114689,131072,0.256865` | `257,8114689,131072,0.256865` (equal) |

## 2. Soup runs and emergence

Emergence is the first logged epoch (every 16) at which the high-order entropy exceeds 1 bit a byte; it is about 0.1
(0.09–0.13) in the thousand epochs before (§5). Runs stop 768 (2^17) or 1,536 (2^15) epochs after it, or at the epoch cap.

| seed | tapes | mutation / byte | emerged (epoch) | epochs run | top tape share | distinct tapes | H₂ (bits) | higher-order entropy | ops / run |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 131072 | 0.0244 % | none | 12000 | 0.003 % | 131067 | 30 | 0.127 | 245.1 |
| 2 | 131072 | 0.0244 % | 11585 | 12000 | 0.141 % | 37063 | 13.096 | 3.994 | 1264.5 |
| 3 | 131072 | 0.0977 % | 4833 | 5601 | 0.017 % | 114704 | 17.683 | 4.152 | 1844.4 |
| 4 | 131072 | 0.0977 % | 7633 | 8401 | 0.021 % | 110742 | 16.937 | 3.801 | 409.2 |
| 5 | 32768 | 0.0977 % | none | 48000 | 0.006 % | 32767 | 29 | 0.076 | 105.2 |
| 6 | 32768 | 0.0977 % | 4849 | 6385 | 0.073 % | 20868 | 13.736 | 5.603 | 2034.2 |
| 7 | 32768 | 0.0977 % | none | 40000 | 0.003 % | 32768 | >29 | 0.100 | 100.9 |
| 8 | 32768 | 0.0977 % | none | 30000 | 0.009 % | 32764 | 26.678 | 0.096 | 113.5 |

- At the paper's setting, 1 of 2 runs emerged within 12,000 epochs; the paper reports about 40 % within 16,000
  [agueraYarcas2024, Fig. 5]. Two runs say nothing about that rate; they only show the setting works here.
- Small soups at the higher rate emerged in 1 of 4 runs over 30,000–48,000 epochs, i.e. 7,500–12,000 epochs' worth of
  interactions of a 2^17 soup; the large soups at the same rate emerged in 2 of 2 within 7,633 epochs. No rate is
  claimed from these counts.
- Seed 2 was stopped 415 epochs after emergence by the cap, seed 3 after 768, seed 4 after 768, seed 6 after 1,536;
  the soups are at different stages of takeover (self-copiers 16–85 % of the soup, §3).

## 3. The pair map at the replicators

g(A|B) = split(run(A|B)), with no mutation. For each of the three most common tapes of each emerged soup (R1–R12;
R1/R2, R7/R8 and R11/R12 are each other's mirror images), and the paper's Fig. 4 replicator (R13, middle bytes 0x20
since the figure prints them blank): 256 random partners X in both orders; the orbit of the pair under g (up to 64
steps); the offspring line (R with a fresh random partner, then its offspring with a fresh one, 5 and 6 generations).

Dominant tapes (instructions as themselves, 0 as `0`, other bytes `·`):

| id | source | share | tape (instructions as themselves, 0 as 0, other bytes ·) | instr. bytes | positions where an instruction ran | distance to its mirror |
|---|---|---|---|---|---|---|
| R1 | seed 2 #1 | 0.141 % (185 tapes) | `······[····<··,··}·········]·········.·}<]·········}··,··<·····[` | 13 | 5 | 64 |
| R2 | seed 2 #2 | 0.141 % (185 tapes) | `[·····<··,··}·········]<}·.·········]·········}··,··<····[······` | 13 | 5 | 64 |
| R3 | seed 2 #3 | 0.106 % (139 tapes) | `·····[·······<··,··}·········]]·········}··,··<·······[·········` | 10 | 5 | 54 |
| R4 | seed 3 #1 | 0.017 % (22 tapes) | `}·················{[{···.···>···········]····>···.···{[········,` | 12 | 7 | 64 |
| R5 | seed 3 #2 | 0.016 % (21 tapes) | `,·····[{···.···>···········]······>···.···{[··.·················` | 11 | 6 | 64 |
| R6 | seed 3 #3 | 0.016 % (21 tapes) | `··[{···.···>···········]····>···.···{[···+·········,··.···,·,·,-` | 16 | 5 | 64 |
| R7 | seed 4 #1 | 0.021 % (27 tapes) | `,··[{·····.····>···············]]················>·.······{[··.·` | 12 | 6 | 60 |
| R8 | seed 4 #2 | 0.021 % (27 tapes) | `·.··[{······.·>················]]···············>····.·····{[··,` | 12 | 6 | 60 |
| R9 | seed 4 #3 | 0.019 % (25 tapes) | `··[{······.·>···············]]···············>·.······{[···-··.+` | 13 | 5 | 64 |
| R10 | seed 6 #1 | 0.073 % (24 tapes) | `·····[·[··············<·,·}···]··}·,·<··················[·······` | 10 | 6 | 62 |
| R11 | seed 6 #2 | 0.073 % (24 tapes) | `···············[···[····<·,·}···]··}·,·<···············[········` | 10 | 6 | 58 |
| R12 | seed 6 #3 | 0.073 % (24 tapes) | `········[···············<·,·}··]···}·,·<····[···[···············` | 10 | 5 | 58 |
| R13 | seed – #0 | the paper's Fig. 4 (middle 0x20) | `[[{.>]-]················································]-]>.{[[` | 16 | 6 | 0 |

| id | (R\|R) | (R\|mirror R) | g(R\|X): R kept | g(R\|X): copy = R / mirror of R | g(X\|R): R kept | g(X\|R): copy = R / mirror | iterate g on (R\|X): reaches a fixed point or 2-cycle of R and its mirror | on (X\|R) | offspring line after 5 and 6 generations is R or its mirror (R first / second) |
|---|---|---|---|---|---|---|---|---|---|
| R1 | (R\|R) → (R\|mirror R): pre-period 1, then period 1 | fixed point | 100.0 % | 0.0 % / 100.0 % | 23.4 % | 0.0 % / 0.0 % | 100.0 % (median 1 steps) | 0.0 % | 100.0 % / 0.0 % |
| R2 | (R\|R) → (R\|mirror R): pre-period 1, then period 1 | fixed point | 100.0 % | 0.0 % / 100.0 % | 18.8 % | 0.0 % / 0.0 % | 100.0 % (median 1 steps) | 0.0 % | 100.0 % / 0.0 % |
| R3 | (R\|R) → (R\|mirror R): pre-period 1, then period 1 | fixed point | 100.0 % | 0.0 % / 100.0 % | 20.3 % | 0.0 % / 0.0 % | 100.0 % (median 1 steps) | 0.0 % | 100.0 % / 0.0 % |
| R4 | (R\|R) → (R\|mirror R): pre-period 1, then period 1 | fixed point | 100.0 % | 0.0 % / 100.0 % | 20.3 % | 0.0 % / 0.0 % | 100.0 % (median 1 steps) | 0.0 % | 100.0 % / 0.0 % |
| R5 | (R\|R) → (R\|mirror R): pre-period 1, then period 1 | fixed point | 100.0 % | 0.0 % / 100.0 % | 19.1 % | 0.0 % / 0.0 % | 100.0 % (median 1 steps) | 0.0 % | 100.0 % / 0.0 % |
| R6 | (R\|R) → (R\|mirror R): pre-period 1, then period 1 | fixed point | 100.0 % | 0.0 % / 100.0 % | 19.5 % | 0.0 % / 0.0 % | 100.0 % (median 1 steps) | 0.0 % | 100.0 % / 0.0 % |
| R7 | (R\|R) → (R\|mirror R): pre-period 1, then period 1 | fixed point | 100.0 % | 0.0 % / 100.0 % | 20.3 % | 0.0 % / 0.0 % | 100.0 % (median 1 steps) | 0.0 % | 100.0 % / 0.0 % |
| R8 | (R\|R) → (R\|mirror R): pre-period 1, then period 1 | fixed point | 100.0 % | 0.0 % / 100.0 % | 18.4 % | 0.0 % / 0.0 % | 100.0 % (median 1 steps) | 0.0 % | 100.0 % / 0.0 % |
| R9 | (R\|R) → (R\|mirror R): pre-period 1, then period 1 | fixed point | 100.0 % | 0.0 % / 100.0 % | 18.8 % | 0.0 % / 0.0 % | 100.0 % (median 1 steps) | 0.0 % | 100.0 % / 0.0 % |
| R10 | (R\|R) → (R\|mirror R): pre-period 1, then period 1 | fixed point | 100.0 % | 0.0 % / 100.0 % | 20.3 % | 0.0 % / 0.0 % | 100.0 % (median 1 steps) | 0.0 % | 100.0 % / 0.0 % |
| R11 | (R\|R) → (R\|mirror R): pre-period 1, then period 1 | fixed point | 100.0 % | 0.0 % / 100.0 % | 20.7 % | 0.0 % / 0.0 % | 100.0 % (median 1 steps) | 0.0 % | 100.0 % / 0.0 % |
| R12 | (R\|R) → (R\|mirror R): pre-period 1, then period 1 | fixed point | 100.0 % | 0.0 % / 100.0 % | 19.9 % | 0.0 % / 0.0 % | 100.0 % (median 1 steps) | 0.0 % | 100.0 % / 0.0 % |
| R13 | fixed point | fixed point | 100.0 % | 100.0 % / 0.0 % | 15.6 % | 0.0 % / 0.0 % | 100.0 % (median 1 steps) | 0.0 % | 100.0 % / 0.0 % |

- **Fixed point.** In all twelve, g(R|X) = (R|mirror R) for 256 of 256 partners, so g maps every tested pair (R|X)
  onto one point in one step, and that point, (R|mirror R), is fixed: g(R|mirror R) = (R|mirror R). (R|R) is not
  itself fixed (the copy is reversed) but reaches the fixed point in one step. The Fig. 4 palindrome equals its mirror,
  so for it (R|R) is the fixed point. The offspring line alternates R, mirror R, R, …: a 2-cycle at the level of
  tapes, a fixed point at the level of the pair.
- **Only from the first slot.** With R second, the partner's bytes run first; R is never copied (0 of 256) and is left
  intact in 16–23 %. Since pairs are ordered at random, R acts as a replicator in half of its encounters.
- **The whole basin is reached in one step.** Iterating g on (R|X) reaches the fixed point in 1 step for 256 of 256
  partners; on (X|R) never.
- **In the soup.** Sampling 4,096 tapes of each final soup and testing each against 3 random partners:

  | soup | T first | T second | either |
  |---|---|---|---|
  | soup-n131072-m0.000244140625-s2.json | 84.8 % | 0.0 % | 84.8 % |
  | soup-n131072-m0.0009765625-s3.json | 16.1 % | 0.0 % | 16.1 % |
  | soup-n131072-m0.0009765625-s4.json | 27.4 % | 0.0 % | 27.4 % |
  | soup-n32768-m0.0009765625-s6.json | 55.9 % | 0.0 % | 55.9 % |

  The most common tape is rare (0.017–0.141 % of the soup): the copiers are many variants of a few loops. By Hamming
  distance the families look small (below), because variants also differ in where the loop sits on the tape; the
  self-copier share above is the better measure.

| id | d = 0 | ≤ 2 | ≤ 8 | ≤ 16 | ≤ 32 |
|---|---|---|---|---|---|
| R1 | 0.28 % | 0.98 % | 1.66 % | 1.66 % | 2.14 % |
| R2 | 0.28 % | 0.98 % | 1.66 % | 1.66 % | 2.14 % |
| R3 | 0.21 % | 0.43 % | 0.58 % | 21.10 % | 28.22 % |
| R4 | 0.03 % | 0.07 % | 0.14 % | 0.14 % | 0.15 % |
| R5 | 0.03 % | 0.05 % | 0.06 % | 0.07 % | 0.07 % |
| R6 | 0.03 % | 0.05 % | 0.08 % | 0.23 % | 0.33 % |
| R7 | 0.04 % | 0.07 % | 0.11 % | 0.13 % | 0.25 % |
| R8 | 0.04 % | 0.07 % | 0.11 % | 0.13 % | 0.25 % |
| R9 | 0.04 % | 0.13 % | 0.21 % | 0.22 % | 0.36 % |
| R10 | 0.15 % | 0.18 % | 0.29 % | 0.32 % | 1.04 % |
| R11 | 0.15 % | 0.23 % | 0.29 % | 0.79 % | 3.06 % |
| R12 | 0.15 % | 0.23 % | 0.29 % | 0.79 % | 3.06 % |

## 4. Heredity

Every single-byte mutant M of each R: all 64 positions × (0, the 10 instructions, 5 random non-instruction values),
minus the unchanged value, about 1,010 mutants per R. M is put in the better of the two slots with a fresh random
partner; its offspring (the partner slot) with a fresh partner; 8 generations, 16 such lines per mutant. A line
*breeds true* if it ends in M or mirror M repeating with period 1 or 2; *reverts* if it ends in R or mirror R;
*variant* if it settles on another tape; *dies* if it does not settle. A mutant is classed by the majority of its 16
lines. "Soup-weighted" weights the 11 instruction-or-zero values by 1/256 each and the 5 others by 245/256 shared,
which is the distribution of the soup's mutations. "Neutral tape positions": non-instruction bytes of R at which all
5 tested non-instruction values breed true; the last column redraws all of them at once (random non-instruction,
non-zero values), 64 times.

| id | soup-weighted: heritable / variant / reverts / dies | tape byte → other non-instr. value: heritable | tape byte → 0: heritable / variant / dies | tape byte → instr.: heritable / dies | code byte (any change): heritable / dies | neutral tape positions | all neutral bytes redrawn at once: breed true |
|---|---|---|---|---|---|---|---|
| R1 | 82.0 / 0.1 / 0.0 / 17.9 | 100.0 (n 255) | 0.0 / 0.0 / 100.0 | 32.4 / 65.1 | 21.5 / 78.5 (n 195) | 51 of 51 | 64 / 64 |
| R2 | 82.0 / 0.1 / 0.0 / 17.9 | 100.0 (n 255) | 0.0 / 2.0 / 98.0 | 32.4 / 65.1 | 21.5 / 78.5 (n 195) | 51 of 51 | 64 / 64 |
| R3 | 84.4 / 0.2 / 0.0 / 15.4 | 100.0 (n 270) | 0.0 / 29.6 / 70.4 | 17.4 / 79.6 | 6.7 / 93.3 (n 150) | 54 of 54 | 64 / 64 |
| R4 | 79.8 / 1.8 / 0.0 / 18.4 | 100.0 (n 258) | 0.0 / 13.5 / 86.5 | 14.2 / 77.5 | 3.9 / 89.4 (n 180) | 52 of 52 | 64 / 64 |
| R5 | 83.0 / 0.3 / 0.0 / 16.7 | 100.0 (n 264) | 0.0 / 37.7 / 62.3 | 20.2 / 75.5 | 8.5 / 88.5 (n 165) | 53 of 53 | 64 / 64 |
| R6 | 80.0 / 1.9 / 0.0 / 18.1 | 100.0 (n 240) | 0.0 / 37.5 / 62.5 | 20.0 / 74.6 | 14.6 / 75.0 (n 240) | 48 of 48 | 64 / 64 |
| R7 | 84.2 / 0.2 / 0.0 / 15.6 | 100.0 (n 259) | 0.0 / 11.5 / 88.5 | 12.9 / 84.2 | 13.3 / 82.8 (n 180) | 52 of 52 | 64 / 64 |
| R8 | 84.2 / 0.1 / 0.0 / 15.6 | 100.0 (n 258) | 0.0 / 1.9 / 98.1 | 12.9 / 84.2 | 13.3 / 82.8 (n 180) | 52 of 52 | 64 / 64 |
| R9 | 81.2 / 1.6 / 0.0 / 17.1 | 100.0 (n 255) | 0.0 / 7.8 / 92.2 | 13.1 / 84.7 | 8.7 / 83.1 (n 195) | 51 of 51 | 64 / 64 |
| R10 | 84.3 / 0.3 / 0.0 / 15.4 | 100.0 (n 270) | 0.0 / 46.3 / 53.7 | 15.6 / 81.5 | 8.0 / 92.0 (n 150) | 54 of 54 | 64 / 64 |
| R11 | 84.5 / 0.3 / 0.0 / 15.2 | 100.0 (n 268) | 0.0 / 38.9 / 59.3 | 20.7 / 73.1 | 8.0 / 91.3 (n 150) | 54 of 54 | 64 / 64 |
| R12 | 84.5 / 0.3 / 0.0 / 15.2 | 100.0 (n 269) | 0.0 / 38.9 / 59.3 | 20.7 / 73.1 | 8.0 / 90.0 (n 150) | 54 of 54 | 64 / 64 |
| R13 | 87.0 / 0.4 / 0.0 / 12.6 | 100.0 (n 240) | 0.0 / 100.0 / 0.0 | 100.0 / 0.0 | 33.3 / 60.4 (n 240) | 48 of 48 | 64 / 64 |

- **Heredity is the rule.** 80–85 % of the soup's single-byte mutations of an evolved replicator breed true; none
  reverts (0.0 % soup-weighted; at most 2.2 % of any tested class). Keimli's mutant table (`mechanism.md` §5)
  is the opposite: repaired 73–100 %, converted to another existing type 0–27 %, inherited 0 except 1.6 % for one
  fixed point of one design.
- **Code and tape.** A non-instruction byte changed to another non-instruction value is a no-op either way and is copied
  verbatim: 100 % inherited. A zero breaks the copy (the loops stop at a 0 under head0): 0 % inherited, 54–100 %
  die (R1–R12). A new instruction in the tape is executed in the next generation (the pointer passes over the whole tape): 13–32 %
  still breed true, 65–85 % die. Changing an instruction of the loop itself: 4–22 % breed true, 75–93 % die.
- **A neutral manifold, not an isolated point.** For every R, every non-instruction position is neutral, and redrawing
  all 48–54 of them at once still gives a replicator in 64 of 64 trials: each evolved R is one point of a set of about
  245^51 ≈ 2^405 replicators (2^381–2^429 across R1–R12; this extrapolates from the tested values), each a fixed point
  of g in the same sense as R.

The full breakdown (by original byte kind, by substitution kind, and by whether an instruction ran at the position):

| id | mutants | n | heritable (M or its mirror breeds true) | variant (another settled line) | reverts to R | dies (no settled line) |
|---|---|---|---|---|---|---|
| R1 | neutral tape positions (non-instruction bytes where all tested non-instruction values breed true): 51 of 51; also 3 code positions tolerate any tested non-instruction value; 245^51 ≈ 2^405 tapes; of 64 tapes with all of them redrawn at once, 64 breed true | | | | | |
| R1 | **uniform random byte (soup-weighted)** | – | 82.0 % | 0.1 % | 0.0 % | 17.9 % |
| R1 | all tested (11 instr./0 + 5 other values per position) | 1011 | 45.7 % | 1.3 % | 0.0 % | 53.0 % |
| R1 | code: the byte is an instruction | 195 | 21.5 % | 0.0 % | 0.0 % | 78.5 % |
| R1 | code byte → a non-instruction value | 65 | 23.1 % | 0.0 % | 0.0 % | 76.9 % |
| R1 | tape: the byte is not an instruction | 816 | 51.5 % | 1.6 % | 0.0 % | 46.9 % |
| R1 | tape byte → another non-instruction value | 255 | 100.0 % | 0.0 % | 0.0 % | 0.0 % |
| R1 | tape byte → 0 | 51 | 0.0 % | 0.0 % | 0.0 % | 100.0 % |
| R1 | tape byte → an instruction | 510 | 32.4 % | 2.5 % | 0.0 % | 65.1 % |
| R1 | (positions where an instruction ran) | 75 | 0.0 % | 0.0 % | 0.0 % | 100.0 % |
| R1 | (positions where none ran) | 936 | 49.4 % | 1.4 % | 0.0 % | 49.3 % |
| R2 | neutral tape positions (non-instruction bytes where all tested non-instruction values breed true): 51 of 51; also 3 code positions tolerate any tested non-instruction value; 245^51 ≈ 2^405 tapes; of 64 tapes with all of them redrawn at once, 64 breed true | | | | | |
| R2 | **uniform random byte (soup-weighted)** | – | 82.0 % | 0.1 % | 0.0 % | 17.9 % |
| R2 | all tested (11 instr./0 + 5 other values per position) | 1011 | 45.7 % | 1.4 % | 0.0 % | 52.9 % |
| R2 | code: the byte is an instruction | 195 | 21.5 % | 0.0 % | 0.0 % | 78.5 % |
| R2 | code byte → a non-instruction value | 65 | 23.1 % | 0.0 % | 0.0 % | 76.9 % |
| R2 | tape: the byte is not an instruction | 816 | 51.5 % | 1.7 % | 0.0 % | 46.8 % |
| R2 | tape byte → another non-instruction value | 255 | 100.0 % | 0.0 % | 0.0 % | 0.0 % |
| R2 | tape byte → 0 | 51 | 0.0 % | 2.0 % | 0.0 % | 98.0 % |
| R2 | tape byte → an instruction | 510 | 32.4 % | 2.5 % | 0.0 % | 65.1 % |
| R2 | (positions where an instruction ran) | 75 | 0.0 % | 0.0 % | 0.0 % | 100.0 % |
| R2 | (positions where none ran) | 936 | 49.4 % | 1.5 % | 0.0 % | 49.1 % |
| R3 | neutral tape positions (non-instruction bytes where all tested non-instruction values breed true): 54 of 54; also 2 code positions tolerate any tested non-instruction value; 245^54 ≈ 2^429 tapes; of 64 tapes with all of them redrawn at once, 64 breed true | | | | | |
| R3 | **uniform random byte (soup-weighted)** | – | 84.4 % | 0.2 % | 0.0 % | 15.4 % |
| R3 | all tested (11 instr./0 + 5 other values per position) | 1014 | 36.9 % | 3.2 % | 0.0 % | 60.0 % |
| R3 | code: the byte is an instruction | 150 | 6.7 % | 0.0 % | 0.0 % | 93.3 % |
| R3 | code byte → a non-instruction value | 50 | 20.0 % | 0.0 % | 0.0 % | 80.0 % |
| R3 | tape: the byte is not an instruction | 864 | 42.1 % | 3.7 % | 0.0 % | 54.2 % |
| R3 | tape byte → another non-instruction value | 270 | 100.0 % | 0.0 % | 0.0 % | 0.0 % |
| R3 | tape byte → 0 | 54 | 0.0 % | 29.6 % | 0.0 % | 70.4 % |
| R3 | tape byte → an instruction | 540 | 17.4 % | 3.0 % | 0.0 % | 79.6 % |
| R3 | (positions where an instruction ran) | 75 | 6.7 % | 0.0 % | 0.0 % | 93.3 % |
| R3 | (positions where none ran) | 939 | 39.3 % | 3.4 % | 0.0 % | 57.3 % |
| R4 | neutral tape positions (non-instruction bytes where all tested non-instruction values breed true): 52 of 52; also 1 code positions tolerate any tested non-instruction value; 245^52 ≈ 2^413 tapes; of 64 tapes with all of them redrawn at once, 64 breed true | | | | | |
| R4 | **uniform random byte (soup-weighted)** | – | 79.8 % | 1.8 % | 0.0 % | 18.4 % |
| R4 | all tested (11 instr./0 + 5 other values per position) | 1010 | 33.6 % | 5.9 % | 0.2 % | 60.3 % |
| R4 | code: the byte is an instruction | 180 | 3.9 % | 5.6 % | 1.1 % | 89.4 % |
| R4 | code byte → a non-instruction value | 60 | 8.3 % | 8.3 % | 0.0 % | 83.3 % |
| R4 | tape: the byte is not an instruction | 830 | 40.0 % | 6.0 % | 0.0 % | 54.0 % |
| R4 | tape byte → another non-instruction value | 258 | 100.0 % | 0.0 % | 0.0 % | 0.0 % |
| R4 | tape byte → 0 | 52 | 0.0 % | 13.5 % | 0.0 % | 86.5 % |
| R4 | tape byte → an instruction | 520 | 14.2 % | 8.3 % | 0.0 % | 77.5 % |
| R4 | (positions where an instruction ran) | 105 | 0.0 % | 6.7 % | 0.0 % | 93.3 % |
| R4 | (positions where none ran) | 905 | 37.5 % | 5.9 % | 0.2 % | 56.5 % |
| R5 | neutral tape positions (non-instruction bytes where all tested non-instruction values breed true): 53 of 53; also 2 code positions tolerate any tested non-instruction value; 245^53 ≈ 2^421 tapes; of 64 tapes with all of them redrawn at once, 64 breed true | | | | | |
| R5 | **uniform random byte (soup-weighted)** | – | 83.0 % | 0.3 % | 0.0 % | 16.7 % |
| R5 | all tested (11 instr./0 + 5 other values per position) | 1012 | 38.0 % | 4.5 % | 0.2 % | 57.2 % |
| R5 | code: the byte is an instruction | 165 | 8.5 % | 1.8 % | 1.2 % | 88.5 % |
| R5 | code byte → a non-instruction value | 55 | 18.2 % | 0.0 % | 0.0 % | 81.8 % |
| R5 | tape: the byte is not an instruction | 847 | 43.8 % | 5.1 % | 0.0 % | 51.1 % |
| R5 | tape byte → another non-instruction value | 264 | 100.0 % | 0.0 % | 0.0 % | 0.0 % |
| R5 | tape byte → 0 | 53 | 0.0 % | 37.7 % | 0.0 % | 62.3 % |
| R5 | tape byte → an instruction | 530 | 20.2 % | 4.3 % | 0.0 % | 75.5 % |
| R5 | (positions where an instruction ran) | 90 | 7.8 % | 2.2 % | 2.2 % | 87.8 % |
| R5 | (positions where none ran) | 922 | 41.0 % | 4.8 % | 0.0 % | 54.2 % |
| R6 | neutral tape positions (non-instruction bytes where all tested non-instruction values breed true): 48 of 48; also 5 code positions tolerate any tested non-instruction value; 245^48 ≈ 2^381 tapes; of 64 tapes with all of them redrawn at once, 64 breed true | | | | | |
| R6 | **uniform random byte (soup-weighted)** | – | 80.0 % | 1.9 % | 0.0 % | 18.1 % |
| R6 | all tested (11 instr./0 + 5 other values per position) | 1008 | 36.8 % | 6.6 % | 0.2 % | 56.3 % |
| R6 | code: the byte is an instruction | 240 | 14.6 % | 9.6 % | 0.8 % | 75.0 % |
| R6 | code byte → a non-instruction value | 80 | 31.3 % | 6.3 % | 0.0 % | 62.5 % |
| R6 | tape: the byte is not an instruction | 768 | 43.8 % | 5.7 % | 0.0 % | 50.5 % |
| R6 | tape byte → another non-instruction value | 240 | 100.0 % | 0.0 % | 0.0 % | 0.0 % |
| R6 | tape byte → 0 | 48 | 0.0 % | 37.5 % | 0.0 % | 62.5 % |
| R6 | tape byte → an instruction | 480 | 20.0 % | 5.4 % | 0.0 % | 74.6 % |
| R6 | (positions where an instruction ran) | 75 | 0.0 % | 0.0 % | 0.0 % | 100.0 % |
| R6 | (positions where none ran) | 933 | 39.8 % | 7.2 % | 0.2 % | 52.8 % |
| R7 | neutral tape positions (non-instruction bytes where all tested non-instruction values breed true): 52 of 52; also 4 code positions tolerate any tested non-instruction value; 245^52 ≈ 2^413 tapes; of 64 tapes with all of them redrawn at once, 64 breed true | | | | | |
| R7 | **uniform random byte (soup-weighted)** | – | 84.2 % | 0.2 % | 0.0 % | 15.6 % |
| R7 | all tested (11 instr./0 + 5 other values per position) | 1011 | 34.6 % | 2.6 % | 0.2 % | 62.6 % |
| R7 | code: the byte is an instruction | 180 | 13.3 % | 2.8 % | 1.1 % | 82.8 % |
| R7 | code byte → a non-instruction value | 60 | 33.3 % | 0.0 % | 0.0 % | 66.7 % |
| R7 | tape: the byte is not an instruction | 831 | 39.2 % | 2.5 % | 0.0 % | 58.2 % |
| R7 | tape byte → another non-instruction value | 259 | 100.0 % | 0.0 % | 0.0 % | 0.0 % |
| R7 | tape byte → 0 | 52 | 0.0 % | 11.5 % | 0.0 % | 88.5 % |
| R7 | tape byte → an instruction | 520 | 12.9 % | 2.9 % | 0.0 % | 84.2 % |
| R7 | (positions where an instruction ran) | 90 | 13.3 % | 2.2 % | 2.2 % | 82.2 % |
| R7 | (positions where none ran) | 921 | 36.7 % | 2.6 % | 0.0 % | 60.7 % |
| R8 | neutral tape positions (non-instruction bytes where all tested non-instruction values breed true): 52 of 52; also 4 code positions tolerate any tested non-instruction value; 245^52 ≈ 2^413 tapes; of 64 tapes with all of them redrawn at once, 64 breed true | | | | | |
| R8 | **uniform random byte (soup-weighted)** | – | 84.2 % | 0.1 % | 0.0 % | 15.6 % |
| R8 | all tested (11 instr./0 + 5 other values per position) | 1010 | 34.6 % | 2.1 % | 0.2 % | 63.2 % |
| R8 | code: the byte is an instruction | 180 | 13.3 % | 2.8 % | 1.1 % | 82.8 % |
| R8 | code byte → a non-instruction value | 60 | 33.3 % | 0.0 % | 0.0 % | 66.7 % |
| R8 | tape: the byte is not an instruction | 830 | 39.2 % | 1.9 % | 0.0 % | 58.9 % |
| R8 | tape byte → another non-instruction value | 258 | 100.0 % | 0.0 % | 0.0 % | 0.0 % |
| R8 | tape byte → 0 | 52 | 0.0 % | 1.9 % | 0.0 % | 98.1 % |
| R8 | tape byte → an instruction | 520 | 12.9 % | 2.9 % | 0.0 % | 84.2 % |
| R8 | (positions where an instruction ran) | 90 | 13.3 % | 2.2 % | 0.0 % | 84.4 % |
| R8 | (positions where none ran) | 920 | 36.6 % | 2.1 % | 0.2 % | 61.1 % |
| R9 | neutral tape positions (non-instruction bytes where all tested non-instruction values breed true): 51 of 51; also 3 code positions tolerate any tested non-instruction value; 245^51 ≈ 2^405 tapes; of 64 tapes with all of them redrawn at once, 64 breed true | | | | | |
| R9 | **uniform random byte (soup-weighted)** | – | 81.2 % | 1.6 % | 0.0 % | 17.1 % |
| R9 | all tested (11 instr./0 + 5 other values per position) | 1011 | 33.5 % | 2.8 % | 0.3 % | 63.4 % |
| R9 | code: the byte is an instruction | 195 | 8.7 % | 6.7 % | 1.5 % | 83.1 % |
| R9 | code byte → a non-instruction value | 65 | 23.1 % | 7.7 % | 0.0 % | 69.2 % |
| R9 | tape: the byte is not an instruction | 816 | 39.5 % | 1.8 % | 0.0 % | 58.7 % |
| R9 | tape byte → another non-instruction value | 255 | 100.0 % | 0.0 % | 0.0 % | 0.0 % |
| R9 | tape byte → 0 | 51 | 0.0 % | 7.8 % | 0.0 % | 92.2 % |
| R9 | tape byte → an instruction | 510 | 13.1 % | 2.2 % | 0.0 % | 84.7 % |
| R9 | (positions where an instruction ran) | 75 | 6.7 % | 0.0 % | 0.0 % | 93.3 % |
| R9 | (positions where none ran) | 936 | 35.7 % | 3.0 % | 0.3 % | 61.0 % |
| R10 | neutral tape positions (non-instruction bytes where all tested non-instruction values breed true): 54 of 54; also 2 code positions tolerate any tested non-instruction value; 245^54 ≈ 2^429 tapes; of 64 tapes with all of them redrawn at once, 64 breed true | | | | | |
| R10 | **uniform random byte (soup-weighted)** | – | 84.3 % | 0.3 % | 0.0 % | 15.4 % |
| R10 | all tested (11 instr./0 + 5 other values per position) | 1014 | 36.1 % | 4.0 % | 0.0 % | 59.9 % |
| R10 | code: the byte is an instruction | 150 | 8.0 % | 0.0 % | 0.0 % | 92.0 % |
| R10 | code byte → a non-instruction value | 50 | 20.0 % | 0.0 % | 0.0 % | 80.0 % |
| R10 | tape: the byte is not an instruction | 864 | 41.0 % | 4.7 % | 0.0 % | 54.3 % |
| R10 | tape byte → another non-instruction value | 270 | 100.0 % | 0.0 % | 0.0 % | 0.0 % |
| R10 | tape byte → 0 | 54 | 0.0 % | 46.3 % | 0.0 % | 53.7 % |
| R10 | tape byte → an instruction | 540 | 15.6 % | 3.0 % | 0.0 % | 81.5 % |
| R10 | (positions where an instruction ran) | 90 | 13.3 % | 0.0 % | 0.0 % | 86.7 % |
| R10 | (positions where none ran) | 924 | 38.3 % | 4.4 % | 0.0 % | 57.3 % |
| R11 | neutral tape positions (non-instruction bytes where all tested non-instruction values breed true): 54 of 54; also 2 code positions tolerate any tested non-instruction value; 245^54 ≈ 2^429 tapes; of 64 tapes with all of them redrawn at once, 64 breed true | | | | | |
| R11 | **uniform random byte (soup-weighted)** | – | 84.5 % | 0.3 % | 0.0 % | 15.2 % |
| R11 | all tested (11 instr./0 + 5 other values per position) | 1012 | 38.7 % | 5.4 % | 0.1 % | 55.7 % |
| R11 | code: the byte is an instruction | 150 | 8.0 % | 0.7 % | 0.0 % | 91.3 % |
| R11 | code byte → a non-instruction value | 50 | 20.0 % | 0.0 % | 0.0 % | 80.0 % |
| R11 | tape: the byte is not an instruction | 862 | 44.1 % | 6.3 % | 0.1 % | 49.5 % |
| R11 | tape byte → another non-instruction value | 268 | 100.0 % | 0.0 % | 0.0 % | 0.0 % |
| R11 | tape byte → 0 | 54 | 0.0 % | 38.9 % | 1.9 % | 59.3 % |
| R11 | tape byte → an instruction | 540 | 20.7 % | 6.1 % | 0.0 % | 73.1 % |
| R11 | (positions where an instruction ran) | 90 | 13.3 % | 1.1 % | 0.0 % | 85.6 % |
| R11 | (positions where none ran) | 922 | 41.2 % | 5.9 % | 0.1 % | 52.8 % |
| R12 | neutral tape positions (non-instruction bytes where all tested non-instruction values breed true): 54 of 54; also 2 code positions tolerate any tested non-instruction value; 245^54 ≈ 2^429 tapes; of 64 tapes with all of them redrawn at once, 64 breed true | | | | | |
| R12 | **uniform random byte (soup-weighted)** | – | 84.5 % | 0.3 % | 0.0 % | 15.2 % |
| R12 | all tested (11 instr./0 + 5 other values per position) | 1013 | 38.8 % | 5.6 % | 0.1 % | 55.5 % |
| R12 | code: the byte is an instruction | 150 | 8.0 % | 2.0 % | 0.0 % | 90.0 % |
| R12 | code byte → a non-instruction value | 50 | 20.0 % | 0.0 % | 0.0 % | 80.0 % |
| R12 | tape: the byte is not an instruction | 863 | 44.1 % | 6.3 % | 0.1 % | 49.5 % |
| R12 | tape byte → another non-instruction value | 269 | 100.0 % | 0.0 % | 0.0 % | 0.0 % |
| R12 | tape byte → 0 | 54 | 0.0 % | 38.9 % | 1.9 % | 59.3 % |
| R12 | tape byte → an instruction | 540 | 20.7 % | 6.1 % | 0.0 % | 73.1 % |
| R12 | (positions where an instruction ran) | 75 | 0.0 % | 0.0 % | 0.0 % | 100.0 % |
| R12 | (positions where none ran) | 938 | 41.9 % | 6.1 % | 0.1 % | 51.9 % |
| R13 | neutral tape positions (non-instruction bytes where all tested non-instruction values breed true): 48 of 48; also 8 code positions tolerate any tested non-instruction value; 245^48 ≈ 2^381 tapes; of 64 tapes with all of them redrawn at once, 64 breed true | | | | | |
| R13 | **uniform random byte (soup-weighted)** | – | 87.0 % | 0.4 % | 0.0 % | 12.6 % |
| R13 | all tested (11 instr./0 + 5 other values per position) | 1008 | 79.4 % | 6.1 % | 0.2 % | 14.4 % |
| R13 | code: the byte is an instruction | 240 | 33.3 % | 5.4 % | 0.8 % | 60.4 % |
| R13 | code byte → a non-instruction value | 80 | 50.0 % | 0.0 % | 0.0 % | 50.0 % |
| R13 | tape: the byte is not an instruction | 768 | 93.8 % | 6.3 % | 0.0 % | 0.0 % |
| R13 | tape byte → another non-instruction value | 240 | 100.0 % | 0.0 % | 0.0 % | 0.0 % |
| R13 | tape byte → 0 | 48 | 0.0 % | 100.0 % | 0.0 % | 0.0 % |
| R13 | tape byte → an instruction | 480 | 100.0 % | 0.0 % | 0.0 % | 0.0 % |
| R13 | (positions where an instruction ran) | 90 | 13.3 % | 4.4 % | 1.1 % | 81.1 % |
| R13 | (positions where none ran) | 918 | 85.8 % | 6.2 % | 0.1 % | 7.8 % |

## 5. The entropy view

The soup around the transition, per emerged run. H₂ is resolvable to 2 log₂ N − 1 bits (33 at 2^17, 29 at 2^15);
"> x" means no two tapes were equal.

#### Entropy around the transition, seed 2 (131072 tapes, emergence at epoch 11585)

| epoch | rel. | brotli bits/byte | byte entropy H₀ | higher-order | tape H₂ (bits) | distinct tapes | top share | zero bytes | ops / run |
|---|---|---|---|---|---|---|---|---|---|
| 1 | -11584 | 8.000 | 8.000 | -0.000 | 33 | 131071 | 0.00 % | 0.4 % | 65.1 |
| 7489 | -4096 | 7.446 | 7.543 | 0.097 | >33 | 131072 | 0.00 % | 0.4 % | 239.7 |
| 10561 | -1024 | 7.407 | 7.531 | 0.124 | 32 | 131070 | 0.00 % | 0.3 % | 237.4 |
| 11329 | -256 | 7.408 | 7.529 | 0.120 | 33 | 131071 | 0.00 % | 0.4 % | 239 |
| 11521 | -64 | 7.401 | 7.527 | 0.126 | 33 | 131071 | 0.00 % | 0.4 % | 240.9 |
| 11569 | -16 | 7.005 | 7.485 | 0.481 | 25.791 | 130977 | 0.01 % | 1.1 % | 240.6 |
| 11585 | +0 | 4.737 | 6.460 | 1.723 | 26.206 | 131000 | 0.01 % | 6.9 % | 285.3 |
| 11601 | +16 | 4.416 | 5.950 | 1.534 | 28.476 | 131059 | 0.01 % | 10.3 % | 439.1 |
| 11649 | +64 | 5.021 | 5.932 | 0.911 | 27.574 | 131058 | 0.01 % | 12.0 % | 578.7 |
| 11841 | +256 | 1.232 | 5.103 | 3.870 | 12.728 | 43837 | 0.46 % | 2.9 % | 1202.8 |
| 12000 | +415 | 1.267 | 5.261 | 3.994 | 13.096 | 37063 | 0.14 % | 4.2 % | 1264.5 |

#### Entropy around the transition, seed 3 (131072 tapes, emergence at epoch 4833)

| epoch | rel. | brotli bits/byte | byte entropy H₀ | higher-order | tape H₂ (bits) | distinct tapes | top share | zero bytes | ops / run |
|---|---|---|---|---|---|---|---|---|---|
| 1 | -4832 | 8.000 | 8.000 | -0.000 | 33 | 131071 | 0.00 % | 0.4 % | 63.2 |
| 737 | -4096 | 7.604 | 7.966 | 0.362 | 31 | 131069 | 0.00 % | 0.4 % | 93.6 |
| 3809 | -1024 | 7.805 | 7.905 | 0.100 | 29.83 | 131066 | 0.00 % | 0.4 % | 111.1 |
| 4577 | -256 | 7.807 | 7.908 | 0.101 | 30.678 | 131068 | 0.00 % | 0.4 % | 111.1 |
| 4769 | -64 | 7.641 | 7.904 | 0.263 | 27.328 | 131037 | 0.01 % | 0.4 % | 121.9 |
| 4817 | -16 | 6.741 | 7.727 | 0.986 | 24.43 | 130887 | 0.01 % | 0.2 % | 174.5 |
| 4833 | +0 | 6.263 | 7.578 | 1.316 | 24.678 | 130887 | 0.01 % | 0.2 % | 192.5 |
| 4849 | +16 | 5.812 | 7.398 | 1.586 | 24.719 | 130830 | 0.01 % | 0.1 % | 209.4 |
| 4897 | +64 | 4.733 | 6.879 | 2.147 | 23.724 | 130670 | 0.01 % | 0.1 % | 239.1 |
| 5089 | +256 | 4.458 | 6.759 | 2.301 | 22.482 | 130472 | 0.01 % | 0.0 % | 195.1 |
| 5601 | +768 | 2.818 | 6.970 | 4.152 | 17.683 | 114704 | 0.02 % | 0.0 % | 1844.4 |

#### Entropy around the transition, seed 4 (131072 tapes, emergence at epoch 7633)

| epoch | rel. | brotli bits/byte | byte entropy H₀ | higher-order | tape H₂ (bits) | distinct tapes | top share | zero bytes | ops / run |
|---|---|---|---|---|---|---|---|---|---|
| 1 | -7632 | 8.000 | 8.000 | -0.000 | >33 | 131072 | 0.00 % | 0.4 % | 63.3 |
| 3537 | -4096 | 7.801 | 7.901 | 0.100 | 29 | 131059 | 0.00 % | 0.4 % | 117.3 |
| 6609 | -1024 | 7.808 | 7.902 | 0.093 | 29.415 | 131063 | 0.00 % | 0.4 % | 111.6 |
| 7377 | -256 | 7.801 | 7.900 | 0.099 | 29.541 | 131063 | 0.00 % | 0.5 % | 115.1 |
| 7569 | -64 | 7.787 | 7.900 | 0.113 | 23.83 | 130982 | 0.02 % | 0.4 % | 115.8 |
| 7617 | -16 | 7.346 | 7.850 | 0.504 | 19.16 | 129214 | 0.08 % | 0.4 % | 133.7 |
| 7633 | +0 | 6.667 | 7.684 | 1.017 | 18.633 | 127609 | 0.08 % | 0.3 % | 153.3 |
| 7649 | +16 | 5.721 | 7.359 | 1.638 | 18.291 | 125733 | 0.05 % | 0.2 % | 171.4 |
| 7697 | +64 | 3.767 | 6.275 | 2.508 | 18.355 | 123592 | 0.02 % | 0.1 % | 189.9 |
| 7889 | +256 | 2.928 | 6.244 | 3.315 | 17.119 | 113237 | 0.02 % | 0.0 % | 338.7 |
| 8401 | +768 | 3.216 | 7.017 | 3.801 | 16.937 | 110742 | 0.02 % | 0.0 % | 409.2 |

#### Entropy around the transition, seed 6 (32768 tapes, emergence at epoch 4849)

| epoch | rel. | brotli bits/byte | byte entropy H₀ | higher-order | tape H₂ (bits) | distinct tapes | top share | zero bytes | ops / run |
|---|---|---|---|---|---|---|---|---|---|
| 1 | -4848 | 8.000 | 8.000 | -0.000 | >29 | 32768 | 0.00 % | 0.4 % | 59.9 |
| 753 | -4096 | 7.852 | 7.971 | 0.120 | 29 | 32767 | 0.01 % | 0.4 % | 87.3 |
| 3825 | -1024 | 7.809 | 7.899 | 0.089 | 29 | 32767 | 0.01 % | 0.4 % | 117.2 |
| 4593 | -256 | 7.805 | 7.898 | 0.092 | 29 | 32767 | 0.01 % | 0.4 % | 127.2 |
| 4785 | -64 | 7.769 | 7.898 | 0.129 | 22 | 32726 | 0.03 % | 0.4 % | 125.7 |
| 4833 | -16 | 7.105 | 7.794 | 0.689 | 16.854 | 31939 | 0.08 % | 0.3 % | 226 |
| 4849 | +0 | 5.840 | 7.454 | 1.614 | 15.677 | 31028 | 0.13 % | 0.2 % | 292.1 |
| 4865 | +16 | 4.364 | 6.858 | 2.495 | 15.345 | 30406 | 0.13 % | 0.1 % | 296.8 |
| 4913 | +64 | 2.479 | 5.820 | 3.341 | 15.945 | 30186 | 0.07 % | 0.0 % | 207 |
| 5105 | +256 | 2.738 | 6.178 | 3.440 | 16.478 | 31271 | 0.08 % | 0.0 % | 146.2 |
| 5873 | +1024 | 1.570 | 6.906 | 5.336 | 13.7 | 19823 | 0.07 % | 7.2 % | 1346.6 |
| 6385 | +1536 | 1.567 | 7.170 | 5.603 | 13.736 | 20868 | 0.07 % | 1.1 % | 2034.2 |

- **Before:** about 0.1 bits a byte of high-order entropy, H₂ at the resolution limit, every tape distinct.
- **At the transition** the Brotli estimate falls by 4.6–6.2 bits a byte within 400–1,500 epochs, as in the paper's
  Fig. 1, and the high-order entropy rises to 3.8–5.6. The tape-level collision entropy falls to 13–18 bits.
- **But the soup does not collapse onto a few states.** 28 % (seed 2, 2^17), 64 % (seed 6, 2^15) and 84–88 % (seeds 3
  and 4) of the tapes are still distinct at the end, and the most common tape holds at most 0.46 % of the soup. Compare
  the decoder (`entropy-manipulators.md`): one step takes a 128-bit cell to 17–20 bits of collision entropy, and 64
  turns leave 7 distinct cells (Swarm F). Takeover by a copier lowers the entropy per byte, because many tapes share a
  loop and the copied bytes; it does not erase the tape bytes the loop does not read, because it copies them. The
  decoder erases what it does not read.
- Seed 6 shows the paper's second phase: 1,024 epochs after emergence the zero-byte share jumps to 7 % and the
  operations per run from 150–300 to 1,300–2,000 (the "zero-poisoning" and a new family, [agueraYarcas2024, Fig. 1–2]);
  seed 2 shows a zero-byte rise to 12 % at +64 epochs.

## 6. Comparison: in what sense both are fixed points, and where they differ

Both kinds of replicator are fixed points of an iterated map, and in both the map, not a separate copying mechanism,
does the work. Keimli's are fixed points or short cycles of the local map f on one 128-bit cell (Langton's trivial
replication: a neighbour that adopts the state is "a copy"). A BFF replicator R is a fixed point of the pair map g on
128 bytes, and a strong one: g sends every tested pair (R|X) with R first (256 of 256) to the same fixed point (R|mirror R) in one step,
erasing the partner's 512 bits. Measured this way, BFF's emergence is the appearance of a tape whose pair-map orbit
is constant in its partner, the kind of property Knierim et al. 2026 [knierim2026] detect with their fixed-point or 2-cycle test
(as summarised in `../RELATED_WORK.md`; their detector was not reimplemented here).

They differ in what the fixed point is a fixed point *of*. Keimli's fixed points are isolated attractors of f: their
one-bit mutants lie in their basins and are mapped back (repaired) or into another existing attractor; the map forgets
the mutation. BFF's replicator is a loop that copies the tape without reading most of it, so each fixed point sits on
a neutral manifold of about 2^400 others: changing a byte the loop does not interpret yields another fixed point of
g, and the change is passed on exactly (100 % of non-instruction substitutions, 80–85 % of all random ones, 0 %
reverting). This is the difference between an attractor and a template: Keimli's map erases the information outside
its fixed points, BFF's copying loop carries the information it does not read. It is also why a BFF soup after
takeover still holds tens of thousands of distinct tapes while the decoder's lattice holds a handful of states. In
Keimli, heredity appears only with constructed rules that copy an unread tape verbatim (`replicase-ablation.md`:
unread verbatim tape is necessary and sufficient, 1.00 vs 0.00), which is what the evolved BFF loops do.

## 7. Deviations and limits

- **Fewer and shorter runs than the paper.** 8 soups instead of 1,000; the 2^17 runs at the paper's mutation rate were
  capped at 12,000 epochs (16,000 in the paper); four runs used 4× the mutation rate (0.098 %) and four used 2^15 tapes,
  to raise the chance of emergence on about 6 cores in 4 hours (paper Fig. 6: a higher rate speeds emergence). The
  replicators of the faster runs belong to the same two loop families as the default run's.
- **The soup is cubff's, the census is not.** The census uses g without mutation, random partners from a separate
  xorshift stream (seed 7), 256 partners per replicator and 16 lines of 8 generations per mutant. "Breeds true" is a
  finite test; a mutant that changes after more than 8 generations would be misclassed.
- **The mutant set is not exhaustive.** 16 of 255 values per position; the soup-weighted figures assume the 5 random
  non-instruction values represent all 245 (they agreed exactly: 100 % at every position of every R).
- **The 2^400 neutral set is an extrapolation** from 5 values per position and 64 joint redraws per replicator.
- **The census tests the three most common tapes per soup**, which are rare (≤ 0.14 %); the self-copier sample covers
  the soup. The family table by Hamming distance understates families whose members are shifted.
- **Raw soups are not kept.** The final soups (8 MB at 2^17) were written outside the repository; the self-copier and
  family numbers need them. They are reproducible: the runs are deterministic (`soup seed=… n=… mut=… epochs=… after=…`).
- **Provenance.** The soup JSONs' `scriptSha` is the script at the time each file was written; the census and report
  code was edited while the soups ran, the interpreter and soup code were not.
- **Emergence criterion.** High-order entropy > 1 bit a byte; the paper reads the transition from the same quantity's
  jump and from tracer tokens (not implemented).

## Reproduce

```
node paper/experiments/bff.mjs selftest
node paper/experiments/bff.mjs validate
node paper/experiments/bff.mjs soup seed=2 n=131072 mut=0.000244140625 epochs=12000 after=768 every=16 scratch=<dir>
node paper/experiments/bff.mjs soup seed=3 n=131072 mut=0.0009765625 epochs=12000 after=768 every=16 scratch=<dir>
node paper/experiments/bff.mjs soup seed=4 n=131072 mut=0.0009765625 epochs=12000 after=768 every=16 scratch=<dir>
node paper/experiments/bff.mjs soup seed=6 n=32768 mut=0.0009765625 epochs=48000 after=1536 every=16 scratch=<dir>
   (no emergence: seed=1 as seed 2; seed=5,7,8 as seed 6 with epochs=48000, 40000, 30000)
node paper/experiments/bff.mjs census in=<the four emerged soup JSONs> top=3 hex=<Fig. 4 tape> nx=256 nlin=16 bins=<dir> out=paper/data/bff/census.json
node paper/experiments/bff.mjs report census=paper/data/bff/census.json soups=<the eight soup JSONs>
```

Node v22.22.1; the soups took 0.6–1.0 s an epoch at 2^17 (pre-transition) on one core of a loaded machine, 1.2–2.0
hours per run.
