# Richness against dictionary size: one construction from 2^8 to 2^24 bytes

2026-10-22. Scripts: `experiments/design-scale.mjs` (the generator; batch `design-scale.sh`), `scale-map.mjs` (the map
alone), `scale-run.mjs` (the lattice; batch `scale.sh`), `scale-summary.mjs` (the tables below, regenerated from the
data), `scale-plot.py` and `scale-functions-plot.py` (the figures). Figures `../figures/dictionary-size.png`, `../figures/dictionary-size-snapshots.png` and `../figures/dictionary-size-functions.png` (twelve quantities against the size).
Raw data `../data/design/ca-size-*.json` and `../data/scale/` (git-ignored, provenance in every file). The dictionaries
are `src/changers/dict/ca-size-08.txt` .. `ca-size-24.txt`; the four of 2^12, 2^16, 2^20 and 2^24 bytes are page presets
("Designed at 2^N bytes", Decompressive group), the sizes of 128 KB and more fetched by the page when selected.
Those eight files (2^17 .. 2^24, 32 MB in all) are not tracked in git: the generator is deterministic (a re-run gives
byte-identical dictionaries), so `design-scale.sh` or `design-scale.mjs sizes=17-24` rebuilds them locally and the
Pages workflow rebuilds them on every push.

## 1. Question

The decoder addresses its dictionary with a header of ceil(log2 V) bits that selects a window position; copies reach at
most about 64 bytes behind it. A dictionary is therefore a set of 64-byte neighbourhoods, one per position, and its
size scales the number of distinct words linearly, at the price of header bits (24 of the cell's 128 at 2^24). Does a
bigger dictionary buy a richer lattice: more types, more entropy of the type shares, more domains, more movement?

## 2. Method

**The module.** Dictionaries up to 2^24 bytes now work everywhere. `Codec.install` keeps a text that fits the 64 KB
static region exactly where it was (every old result reproduces bit for bit: `test/mix.test.mjs`, `band`, `activity`,
`lemma` unchanged); a longer text is placed past the lattice, the output and flag buffers after it, and the memory
grows; every decoder reads the dictionary as out − textLen from the parameter block, so nothing else moved. The
codebook decoders' code × length product was widened to 64 bits (it overflowed at 2^24). `test/bigdict.test.mjs`
checks the wasm decoder against the reference `decode36.mjs` on 20,000 random cells at 1 MB and 16 MB (24 header bits
and 12), after a relocation, and the codebook against a BigInt reference. The page's window-range box goes to 2^24;
manifest entries with a `url` are not inlined but fetched when selected (GitHub Pages serves `src/`; from `file://`
the page says so and keeps its dictionary); the self-test pages stay clean. The harness installs big dictionaries past
its lattice.

**One construction for every size** (`design-scale.mjs`, the header comment has the full schedule). V = the size,
header bits = log2 size. A designed cell is design-dict.mjs's quine head (byte 0's skipped bits, the header h = 16u,
two or three copy commands summing to 16 bytes at one distance) and a tail; it decodes to the 16 dictionary bytes at
h − d, its slot, and reads nothing else, so among designed cells the decoder is a table over codes. Code bits 0–2 are
the Gray bits, code bits 6–7 the group bits; a spot is 8 codes (128 bytes), a group the 2-cube of 4 spots over the
group bits. Three kinds of type, verified state by state on `decode36`:

- **Gray 8-cycles**, closed (DEFINITION.md §4), in groups of four whose blocks differ in one header bit, so the four
  are mutually closed (the corollary): any crossover child of two of them lands in the group.
- **Phase-chasing 3-cycles** (the mechanism of ca-live-phases): a whole group; the three states at the codes 00000,
  00111, 11011 of the group's 5-cube (3, 3 and 4 bits apart), the other 29 codes routed by expected parentage with the
  lead rule, so each phase invades the one behind it.
- **Fixed points** with differing reading lengths: a spot whose eight slots hold the one state.

The funnel is design-dict.mjs's: each type has a filler pattern of period 1–4 (98 safe bytes; the control bytes to
period 5, because at 15 and 23 header bits the "no literals" code falls on bits 5 and 6 of a byte, which only a control
byte has both clear) tiled over a region, and the positions a cell made of that pattern copies its head from (its
landing pad) hold the head of the type's state 0. Only patterns all of whose rotations land are used (a rotation
without a landing bred stray fixed points of filler bytes with 42 % of the cells in a trial); each rotation has its own
pad and may serve a different type, so a pattern of period L feeds up to L types; the pads in use are
position-disjoint; a rotation whose commands carry a lowercase transform is given only to a type whose head holds no
letter at that byte, and letter-free spots are taken first.

**The schedule.** With U the groups whose 32 heads the text pipeline carries (no byte above 0x7e, no NUL, newline,
return or lowercase), the block budget is B = floor(U/2) groups, so blocks cover at most a quarter of the dictionary:
max(1, round(B/5)) Gray groups (4 types each), B minus that many chasing types, min(6, max(1, floor(B/4))) fixed
points on spots outside the groups; below 12 header bits (no group bits) half the safe spots, Gray cycles and one
fixed point. The pad supply then caps the count: when fewer slots exist than types scheduled, chasing types are dropped
first, then whole Gray groups. Regions are shares of the header range proportional to the types a pattern serves.

**Parallelism.** The pattern enumeration (98^4 patterns × 4 rotations × 2 reference decodes), the verification and the
census run on `node:worker_threads`, split by first byte, type index and cell range with a seed per chunk and the
results merged in order, so a re-run gives byte-identical dictionaries; the 17 sizes run as separate processes
(`design-scale.sh`: 6 at a time × 4 threads, then the manifest merge).

**Measures.** Map alone (`scale-map.mjs`): 16,384 random cells through `decode36` until an attractor repeats (Brent);
the attractors realised and their basins, the designed types reached, the strays, the transient length, and the
closure index C(A, A) of the 20 largest realised types (two random states of A in random phases, each differing bit
from the second with probability r, f once, the share landing on A; `closure.mjs`'s definition). Lattice
(`scale-run.mjs`): 256², 2,000 turns, three settling passes, the rotating order, quenched hashing, decoder 36, skip 6,
window range V, 3 seeds, in the page's frame (swap 0–1 left to right at the page's shaping, median 0–1 top to bottom)
and uniform (swap 0.25, median 0.5). Every 50 turns, every cell labelled by the designed type whose state it is on
(else a transient): the types alive (share ≥ 0.1 %), the Shannon entropy of the type shares (over the cells on a type),
the transient share, the domains (4-connected components of same-type cells), the block change (8 × 8 blocks whose most
common label differs from 200 turns earlier); at the end the border matrix (4-neighbour pairs by ordered label pair,
in the run files). PNG snapshots in the page's colouring at turns 200, 1,000 and 2,000. 2^24 also once at 512².

<!-- provenance: paper/experiments/scale-summary.mjs (04ef5e53f34569dd)  | commit 3dc3e4a+dirty | wasm ca7db341fb2dd98b | 2026-10-22T18:20:29.470Z -->

## 3. Results (the tables are `../data/scale/summary.md`, written by `scale-summary.mjs` from the data files)

### 3.1 The schedule and the construction per size

| log2 size | bytes | safe spots (letter-free) | groups | distinct pads | scheduled Gray / chasing / fixed | built Gray / chasing / fixed | types | head bits | seconds (workers) |
|---|---|---|---|---|---|---|---|---|---|
| 8 | 256 | 1 (1) | 0 | 16667 | 1 / 0 / 0 | 1 / 0 / 0 | **1** | 41 | 175.3 (4) |
| 9 | 512 | 2 (1) | 0 | 9437 | 1 / 0 / 0 | 1 / 0 / 0 | **1** | 42 | 151.1 (4) |
| 10 | 1,024 | 2 (1) | 0 | 422 | 1 / 0 / 0 | 1 / 0 / 0 | **1** | 41 | 122.6 (4) |
| 11 | 2,048 | 4 (2) | 2 | 651 | 2 / 0 / 1 | 2 / 0 / 1 | **3** | 44 | 107.6 (4) |
| 12 | 4,096 | 8 (4) | 2 | 485 | 4 / 0 / 1 | 4 / 0 / 1 | **5** | 44 | 38.9 (3) |
| 13 | 8,192 | 16 (8) | 4 | 384 | 4 / 1 / 1 | 4 / 1 / 1 | **6** | 44 | 120.6 (4) |
| 14 | 16,384 | 32 (1) | 8 | 333 | 4 / 3 / 1 | 4 / 3 / 1 | **8** | 45 | 97 (4) |
| 15 | 32,768 | 58 (29) | 10 | 25 | 4 / 4 / 1 | 4 / 4 / 1 | **9** | 49 | 114.9 (4) |
| 16 | 65,536 | 122 (61) | 26 | 22931 | 12 / 10 / 3 | 12 / 10 / 3 | **25** | 49 | 133 (4) |
| 17 | 131,072 | 196 (72) | 42 | 7447 | 16 / 17 / 5 | 16 / 17 / 5 | **38** | 50 | 109.6 (4) |
| 18 | 262,144 | 196 (72) | 42 | 452 | 16 / 17 / 5 | 16 / 17 / 5 | **38** | 49 | 100.8 (4) |
| 19 | 524,288 | 392 (144) | 84 | 295 | 32 / 34 / 6 | 32 / 32 / 6 | **70** | 52 | 85.5 (4) |
| 20 | 1,048,576 | 784 (288) | 168 | 231 | 68 / 67 / 6 | 40 / 17 / 6 | **63** | 52 | 81 (4) |
| 21 | 2,097,152 | 1568 (576) | 336 | 163 | 136 / 134 / 6 | 20 / 30 / 6 | **56** | 52 | 90.2 (4) |
| 22 | 4,194,304 | 2548 (936) | 546 | 76 | 220 / 218 / 6 | 4 / 28 / 6 | **38** | 64 | 86.4 (4) |
| 23 | 8,388,608 | 5684 (2088) | 1218 | 14 | 488 / 487 / 6 | 0 / 4 / 6 | **10** | 57 | 87.6 (4) |
| 24 | 16,777,216 | 11956 (4392) | 2562 | 13971 | 1024 / 1025 / 6 | 1024 / 1025 / 6 | **2055** | 57 | 67.6 (4) |

### 3.2 The map alone (16,384 random cells per size)

| log2 size | types designed | attractors realised | designed reached | stray attractors (share of cells) | transient mean (p90) | designed types with an empty basin | C(A,A) at r = 0.25, min over the 20 largest | C(A,A) of the strays |
|---|---|---|---|---|---|---|---|---|
| 8 | 1 | 7 | 1 | 6 (28.8 %) | 6.0 (10) | 0 | 36.8 % | 36.8 %, 52.0 %, 100.0 %, 100.0 %, 48.7 %, 100.0 % |
| 9 | 1 | 4 | 1 | 3 (21.4 %) | 5.3 (9) | 0 | 53.6 % | 100.0 %, 53.6 %, 100.0 % |
| 10 | 1 | 1 | 1 | 0 (0.0 %) | 5.8 (9) | 0 | 100.0 % | – |
| 11 | 3 | 15 | 3 | 12 (15.9 %) | 7.3 (14) | 0 | 14.4 % | 100.0 %, 25.2 %, 27.4 %, 39.5 %, 100.0 %, 26.6 %, 25.2 %, 100.0 %, 49.2 %, 14.4 %, 26.3 %, 25.9 % |
| 12 | 5 | 15 | 5 | 10 (2.6 %) | 5.8 (10) | 0 | 17.8 % | 18.4 %, 100.0 %, 36.7 %, 18.1 %, 35.6 %, 17.8 %, 100.0 %, 100.0 %, 100.0 %, 38.1 % |
| 13 | 6 | 6 | 6 | 0 (0.0 %) | 10.5 (20) | 0 | 100.0 % | – |
| 14 | 8 | 11 | 8 | 3 (0.0 %) | 15.7 (38) | 0 | 100.0 % | 100.0 %, 100.0 %, 100.0 % |
| 15 | 9 | 15 | 9 | 6 (0.9 %) | 9.6 (20) | 0 | 35.6 % | 100.0 %, 100.0 %, 100.0 %, 100.0 %, 100.0 %, 35.6 % |
| 16 | 25 | 30 | 25 | 5 (2.1 %) | 6.0 (10) | 0 | 100.0 % | – |
| 17 | 38 | 39 | 38 | 1 (1.9 %) | 6.1 (10) | 0 | 100.0 % | 100.0 % |
| 18 | 38 | 39 | 38 | 1 (0.3 %) | 5.8 (10) | 0 | 100.0 % | – |
| 19 | 70 | 72 | 70 | 2 (0.0 %) | 5.8 (9) | 0 | 100.0 % | – |
| 20 | 63 | 64 | 63 | 1 (0.5 %) | 6.6 (11) | 0 | 100.0 % | – |
| 21 | 56 | 59 | 56 | 3 (4.6 %) | 8.0 (15) | 0 | 36.4 % | 36.4 % |
| 22 | 38 | 47 | 38 | 9 (11.5 %) | 11.4 (21) | 0 | 20.5 % | 34.4 %, 100.0 %, 20.5 % |
| 23 | 10 | 15 | 10 | 5 (3.1 %) | 8.0 (15) | 0 | 26.6 % | 26.6 %, 100.0 %, 71.1 %, 100.0 %, 100.0 % |
| 24 | 2055 | 1896 | 1892 | 4 (0.1 %) | 6.1 (10) | 163 | 100.0 % | – |

### 3.3 The lattice, 256², 2,000 turns, 3 seeds (mean, and the range over seeds where the seeds differ)

| log2 size | designed | frame: alive at 2,000 | frame: Gray / chasing / fixed alive | frame: entropy (bits) | frame: transients | frame: domains | frame: block change | uniform: alive | uniform: entropy | uniform: transients | uniform: domains | uniform: block change |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 8 | 1 | 1 | 1 / 0 / 0 | 0 | 70.9 % | 175 (165–192) | 0.03 (0.02–0.03) | 0 | 0 | 100.0 % | 0 | 0 |
| 9 | 1 | 1 | 1 / 0 / 0 | 0 | 85.4 % | 96.33 (86–107) | 0.00 (0–0.00) | 0 | 0 | 100.0 % | 0 | 0 |
| 10 | 1 | 1 | 1 / 0 / 0 | 0 | 49.3 % | 171 (157–181) | 0.02 (0.02–0.02) | 1 | 0 | 95.6 % | 366 (332–398) | 0.01 (0.00–0.01) |
| 11 | 3 | 3 | 2 / 0 / 1 | 0.58 (0.44–0.70) | 89.7 % | 221 (214–234) | 0.00 (0–0.00) | 0 | 0 | 100.0 % | 0 | 0 |
| 12 | 5 | 5 | 4 / 0 / 1 | 1.85 (1.79–1.94) | 64.8 % | 940 (916–971) | 0.02 (0.02–0.03) | 4.67 (4–5) | 1.21 (1.20–1.22) | 93.4 % | 1372 (1333–1419) | 0.00 (0–0.00) |
| 13 | 6 | 5 | 4 / 1 / 0 | 0.92 (0.66–1.12) | 49.9 % | 226 (217–234) | 0.01 (0.00–0.01) | 0 | 0.66 (0.36–0.82) | 100.0 % | 15.67 (11–19) | 0 |
| 14 | 8 | 6.33 (5–7) | 3.33 / 3 / 0 | 1.61 (1.55–1.66) | 51.1 % | 475 (448–491) | 0.01 (0.01–0.02) | 1 | 1.09 (0.99–1.23) | 99.5 % | 156 (142–166) | 0 |
| 15 | 9 | 4.67 (4–5) | 2.67 / 1 / 1 | 1.34 (1.17–1.69) | 57.5 % | 329 (307–344) | 0.01 (0.00–0.01) | 1 | 0.33 (0.31–0.35) | 99.1 % | 176 (150–194) | 0 |
| 16 | 25 | 15.33 (14–16) | 6.33 / 7 / 2 | 2.66 (2.44–2.81) | 45.4 % | 2158 (2079–2245) | 0.03 (0.03–0.03) | 9 | 2.85 (2.81–2.89) | 90.6 % | 2766 (2677–2897) | 0.00 (0–0.00) |
| 17 | 38 | 16 | 6.33 / 7 / 2.67 | 2.40 (2.14–2.84) | 53.2 % | 1218 (1177–1249) | 0.02 (0.01–0.03) | 2.67 (2–3) | 4.06 (3.99–4.17) | 98.9 % | 524 (456–621) | 0 |
| 18 | 38 | 12.33 (11–13) | 7 / 4.33 / 1 | 2.61 (2.52–2.69) | 52.6 % | 1273 (1206–1321) | 0.02 (0.01–0.03) | 4 | 2.62 (2.60–2.65) | 97.5 % | 694 (624–742) | 0 |
| 19 | 70 | 16.67 (16–17) | 7 / 7.67 / 2 | 2.91 (2.71–3.16) | 59.9 % | 790 (758–837) | 0.01 (0.01–0.01) | 1 | 2.61 (2.48–2.84) | 99.2 % | 260 (234–296) | 0 |
| 20 | 63 | 13.33 (12–14) | 11.33 / 1 / 1 | 2.95 (2.71–3.09) | 68.7 % | 580 (547–631) | 0.01 (0.01–0.01) | 0 | 2.97 (2.73–3.35) | 99.9 % | 46.67 (43–51) | 0 |
| 21 | 56 | 4.67 (4–5) | 0 / 4.33 / 0.33 | 1.03 (0.96–1.11) | 58.9 % | 362 (310–406) | 0.00 (0.00–0.00) | 0 | 2.90 (2.55–3.21) | 99.9 % | 27.33 (24–33) | 0 |
| 22 | 38 | 1.33 (1–2) | 0.33 / 0 / 1 | 0.31 (0.18–0.40) | 84.8 % | 170 (151–198) | 0.01 (0.00–0.03) | 1 | 0.01 (0–0.03) | 99.5 % | 98 (87–109) | 0 |
| 23 | 10 | 3.67 (3–4) | 0 / 1 / 2.67 | 0.30 (0.27–0.32) | 73.3 % | 391 (389–393) | 0.02 (0.02–0.02) | 2 | 0.91 (0.89–0.93) | 98.7 % | 278 (251–328) | 0 |
| 24 | 2055 | 36.33 (36–37) | 22 / 14.33 / 0 | 4.90 (4.86–4.95) | 42.8 % | 2227 (2124–2344) | 0.03 (0.02–0.04) | 0 | 7.80 (7.72–7.95) | 99.0 % | 607 (567–672) | 0 |

2^24 at 512², frame, seed 1: alive 36, entropy 4.86, transients 41.9 %, domains 8354, block change 0.026 (604 s).

Generation time per size (one process, 4 worker threads, six sizes running at once on 24 cores): 39–175 s, almost all
of it the pattern enumeration (98^4 period-4 patterns through the reference decoder twice); the build, the verification
and the census take 0.1–3 s even at 2^24 (2,055 types, 16 MB). The 17 sizes took about 7 minutes of wall clock in all (one batch of 5 min 22 s, and five sizes rerun after a fix in 1½ min).
Alone with 24 threads, 2^24 takes 53 s. A re-run gives byte-identical dictionaries (checked at 2^12 with 3 against 4
threads).

## 4. What the figures show (`../figures/dictionary-size.png`, `../figures/dictionary-size-snapshots.png`)

- **Types designed** grow with the size as the schedule allows: 1 at 2^8–2^10, 3–9 at 2^11–2^15, 25–38 at 2^16–2^18,
  56–70 at 2^19–2^21, then down to 38 and 10 at 2^22 and 2^23, and 2,055 at 2^24. The dip is the construction's, not
  the size's (section 6).
- **The map alone reaches every designed type** at every size up to 2^23 (basins 0.5–30 %); at 2^24 16,384 random
  cells reach 1,892 of the 2,055 (163 have an empty basin in the census; a basin there is about 0.05 %). The transient
  to a designed state is 5–8 steps (p90 9–15) except at 2^13–2^15 (10–16 steps, p90 20–40). The closure index C(A, A)
  of every designed type is 100 % at r = 0.25 (the Gray and fixed types by DEFINITION.md §4; the chasing cubes route
  every child to a phase): the strays are the open ones (14–54 %), with a few closed stray fixed points.
- **On the frame** the types alive at turn 2,000 (share ≥ 0.1 % of the whole lattice) rise from 1 at 2^8–2^10 to 5 at
  2^12, 12–17 at 2^16–2^20, 1–5 at 2^21–2^23, and 36 at 2^24. The entropy of the type shares follows: 0
  bits to 2^10, 1.9 at 2^12, 2.4–3.0 from 2^16 to 2^20, 0.3–1.0 at 2^21–2^23, 4.9 at 2^24 (the maximum, log₂ of the
  types designed, is 11 there). The 512² run of 2^24 has the same 36 alive and 4.86 bits: the count is not a lattice-size
  effect. Of the 2,055 types at 2^24, 22 Gray and 14 chasing are alive, no fixed point; the largest share is a chasing
  type with 9.7 %, and 85 % of the borders are type–type (15 % against transients), against 51 % at 2^16.
- **Domains** at 2,000 are 100–2,200 on the frame (the frame's lower half is a mottle of closed domains; the upper
  half, at weak settling, is transients: 43–90 % of the cells on the whole frame are transients at every size).
- **Nothing moves.** The block change at turn 2,000 is 0.00–0.03 in every run and every setting: by turn 1,000 every
  lattice is a standing mottle. The chasing types do not keep their spirals turning here as ca-live-phases does at
  512² alone; with closed Gray neighbours and fixed points around them they lock within a few hundred turns (the
  snapshot sheet: the 2^16 lattice is the same at 1,000 and 2,000 but for one invading fixed point's domain).
- **Uniform (swap 0.25, median 0.5) holds nothing from a random start.** Transients are 90–100 % at every size at
  turn 2,000; the types alive are 0–9 (9 at 2^16, 4.7 at 2^12) with shares of a few per cent, and the block change is 0.
  At that mixing a random cell never completes the 5–16 steps of the funnel before an exchange breaks the pattern it is
  on: the mechanism results that hold domains at (0.25, 0.5) started from planted in-phase domains; here nothing is
  planted, and no domain forms. The frame's lower rows (median 0.6–1) are where its types form.

## 5. How richness scales with size, and where it saturates

Under this construction, measured on the page's frame at 256² for 2,000 turns: the types alive at turn 2,000 grow
from 1 to about 16 between 2^8 and 2^16 (about one doubling of alive types per two doublings of the dictionary from
2^11 on), stay at 12–17 through 2^20 while the types designed grow from 25 to 70, and reach 36 at 2^24 where 2,055 are
designed. The entropy of the type shares is 2.4–3.0 bits from 2^16 to 2^20 and 4.9 bits at 2^24. So a 256-fold larger
dictionary (2^16 to 2^24) with 80 times the types buys 2.3 times the types alive and two more bits of entropy; the
number of domains does not grow (2,158 at 2^16, 2,227 at 2^24, both the mottle of the frame's settled half); and no
size moves. Richness saturates at about 16 types alive from 2^16 on, where the frame's settled half has room for a
dozen domains of a few hundred cells each, and the one further gain, at 2^24, comes with 2,055 types whose basins are
each 0.05 % of the random cells, so that the lattice's 65,536 cells sample a different few dozen each run (36–37
alive over three seeds, 4.86–4.95 bits). What a bigger dictionary buys is more types to choose from and a flatter
share distribution among the winners, not movement and not more domains; the medium, not the dictionary, sets the
number of domains the frame holds, as the mechanism results found for the winners (mechanism-v2.md §9).

## 6. Caveats

- **The construction, not the size, caps the types from 2^19 to 2^23.** The funnel needs, per type, a landing pad
  with distinct dictionary positions, from a filler pattern all of whose rotations land; the pads in use must not
  overlap. Patterns of period 1–4 over the 98 safe bytes give 13,971–22,931 distinct pads at 2^16 and 2^24 but only
  14–295 at 2^15 and 2^19–2^23, and at 15 and 23 header bits only control-byte patterns land at all (the "no
  literals" code falls on bits 5 and 6 of a byte). So 2^23 has 10 types where 981 were scheduled, 2^22 38 of 444,
  and the curve's dip from 2^20 to 2^23 says nothing about size. 2^24 is where the schedule is met in full and shows
  what the size allows. A pad supply that scales with the size (longer patterns, or a second funnel stage) would be
  needed to make the type count monotone.
- **Printable heads.** Only an eighth to a quarter of the spots have heads the text pipeline carries (byte 1 of the
  head must avoid the letters when a pattern's commands lowercase that byte; control bytes are allowed in heads).
  2^17 and 2^18 therefore have the same 38 types (196 safe spots each). The dictionaries hold control bytes in the
  filler and in some heads; they are "texts" only in the sense that the page carries them.
- **Strays.** One type with half the dictionary as its block leaves 21–29 % of random cells on open stray cycles
  (2^8, 2^9); 2^11 has 16 % and 2^22 11.5 % (two open stray cycles among the control-byte filler). Elsewhere the
  strays hold under 5 %.
- **The lattice measures.** Alive = share ≥ 0.1 % of the whole lattice, the unsettled top rows included; the entropy
  is over the cells on a type (so a lattice with 1 % of its cells on types can show 7.8 bits, as the uniform runs at
  2^24 do); block change compares the most common label 200 turns apart, so a cycle in place counts as unchanged;
  three seeds, 2,000 turns, 256² (and one 512²). No bootstrap intervals: the ranges over seeds are printed.
- **The page at 16 MB.** The fetched dictionaries work over http (headless Chrome reached ready with a clean console
  at 2^20 and 2^24 with four workers); each worker holds its own 16 MB copy and rebuilds the code tables over it, a
  few hundred milliseconds on a desktop; not tried on a phone. Over file:// the page says the dictionary could not be
  loaded and keeps the one it had.
- **Not tested here.** Other settling strengths; the salted hashes; dictionaries searched rather than built at these
  sizes; whether the chasing types move on their own at 2^24 (one chasing type alone per dictionary would be the
  control).

