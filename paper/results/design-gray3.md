# Results: a designed dictionary with three Gray-coded 8-cycles

2026-10-18, after the census and the null models (`ablation-scan.md`). Tool
`paper/experiments/design-dict.mjs`; the dictionary, its census, funnel and
invasion table in `paper/data/design/ca-gray3c.{txt,md,json}` and
`ca-gray3c-invasion.md`; lattice runs by `species-run.mjs` in
`paper/data/design/runs/` (tables in `log-c-*.txt`, `log-c2-*.txt`, frames as
PNG: species = hue, phase = lightness, off-cycle = dark). The dictionary is
installed as `ca-gray3c` in the page's manifest (not built).

## 1. The construction

The decoder reads a 16-byte cell as a bit stream: 6 skipped bits, a 12-bit
header h, then insert-and-copy commands. A cell whose first 46 bits say "no
literals, copy 10 bytes from the dictionary at distance d, copy 6 more at the
same distance" outputs the 16 dictionary bytes at h − d and reads nothing
else. With d = 16 and h chosen so that the six command bytes are printable
(`b0 b1 b2 ? 0 @`, h bits 1 and 9 clear), the output is a pointer into the
dictionary and the remaining 82 bits of the cell are free.

A species is a block of eight 16-byte slots at H0 − 16 + 16 g, g the 3-bit
reflected Gray code (0 1 3 2 6 7 5 4). The slot of index g(k − 1) holds the
state S_k = head(H0 + 16 g(k)) + tail, so S_k decodes exactly to S_{k+1}, and
consecutive states differ in **one header bit** (the Gray bit, in byte 1)
plus, optionally, **one tail byte** (`tailgray=1`, byte 6 + j flips between
X and X xor 4 when Gray bit j flips). Verified bit-exactly with the reference
decoder for all 24 states.

Species A, B, C have H0 = 128, 2304, 3328 (header bytes `0`, `2`, `3`) and
tails of `1`, `2`, `3`. The rest of the dictionary is **constant**: the
header range [0, 1365) filled with `1`, [1365, 2730) with `2`, the rest with
`3`. A constant region makes every misaligned reading the same cell, all-X,
whose decoding is fixed by the bits of X; for X = `1`, `2`, `3` that decoding
begins with 9, 13 and 13 bytes copied from positions the design controls
(1211..1219, 2235..2247, 3263..3275), and a **landing pad** holding state 0
of the species is written there. So all-X → state 0 in one step. This is the
mechanism the swarm's dictionaries found by search (F is 90 % `(`): a tiny
alphabet makes the funnel steep. (`mode=words`, a 16-byte filler word with
ten hill-climbed bytes, gave 99.5 % convergence but a 26-turn transient and
did not take hold on the lattice: 58 % off-cycle after 1,000 turns at median
p = 1; kept in `ca-gray3.*` as the control.)

## 2. The decoder with ca-gray3c, against F

| | F (`ca-swarm-f`) | ca-gray3c |
|---|---|---|
| attractors (10,000 random cells) | one 3-cycle, 100 % | three 8-cycles, 42.9 / 30.3 / 26.8 %, **no stray cycle** |
| transient mean / p90 / max | 9.6 / 15 / 35 | **5.1 / 8 / 17** |
| on a cycle after 4 and 8 steps from random | 5.4 %, 50.1 % | **48.2 %, 93.4 %** |
| one bit flipped in a cycle state: return mean / p90 / max | 3.2 / 7 / 15 | **1.5 / 3 / 10**, same species 94.4 % |
| consecutive cycle states, Hamming | 45, 29, 64 | **2, 2, 2, …** |
| planes constant along the cycle | 59 | 122 (46 read) |
| cycle states | three words in rotation | `0 0?0@1111111111` → `0$0?0@5111111111` → `0,0?0@5511111111` → … |

Region bounds 1220 / 2550 balance the basins at 34.4 / 33.0 / 32.7 %
(`bounds=`); the runs below use the default 1365 / 2730.

**Invasion table** (`invasion.mjs`): a cell of species X crossed with a cell
of species Y at rate q per bit and iterated to a cycle. At q = ½: A × B → A
49.5 %, B 48.9 %; B × C → 50 / 50; **A × C → A 43 %, C 26 %, B 31 %**. The
third outcome is the header byte: `0` and `3` mixed bitwise give `1` or `2`,
which point into B's or A's region, so the A–C interface breeds B. Against a
uniformly random cell A stays 64 %, B 36 %, C 39 %. No species dominates
another at the single-cell level; C's dominance on the lattice (below) is
collective.

## 3. The lattice (256², swap p = ½, seed 1, bulk margin 32)

| median p | hashing | after 1,000 turns |
|---|---|---|
| 0.3, 0.4 | both | granular: 83 to 93 % of cells off-cycle, the rest C; d1 0.15 |
| 0.5 | quenched | granular, 90 % off-cycle |
| 0.5 | annealed | **one species (C) with phase domains**: all cells on-cycle, coherence 0.24, 172 phase domains, coarsening slowly (116 at 3,000 turns, coherence 0.46, wall share 0.11 → 0.08); seed 2 the same |
| 0.7 | quenched | one species (C), **476 pinned phase domains**, wall share 0.18, frozen |
| 0.7 | annealed | one species, 13 phase domains, coherence 0.96 |
| 1 | quenched | **three species coexist, pinned**: A 15 %, B 21 %, C 60 %, 55 domains, phase coherence 0.4 to 0.8 within species, frozen from turn ≈ 100 |
| 1 | annealed | **species coarsening**: C 61 → 73 → 84 % at 100 / 1,000 / 3,000 turns, 8 domains left; A islands shrink inside B rims (the A–C interface breeds B) |
| page frame (gradients) | quenched | granular sky, C below with B/A fringes at the low-swap edges, 579 domains |

d1 = 0.016 in every ordered state: exactly the two bits per turn of the Gray
walk (2/128). The off-cycle share at median p ≤ 0.5 quenched says the
transition of `ablation-scan.md` is still there: the oscillators need the
median to synchronise before the swaps (rate ½) scramble the 46 read bits.
With F the ordered side was a single phase; here it is a Potts-like mosaic
of eight phases (q = 8 clock) that coarsens when annealed and pins when
quenched, and at p = 1 a three-species mosaic with a slow invasion.

## 4. What this says

1. **The attractor structure of the decoder can be written down, not
   searched.** Twenty-four 16-byte cells and three constant regions give
   exactly the census one asks for: three attractors, Gray-coded, no strays,
   a funnel twice as steep as the best searched dictionary.
2. **Steepness comes from a tiny alphabet, not from the attractor.** The same
   24 states with a hill-climbed filler (99.5 % convergence, 26-turn
   transient) do nothing on the lattice; with constant regions (5-turn
   transient, 93 % on-cycle in 8 steps) the lattice orders at median p ≥ 0.5
   annealed. The lattice selects on the transient, as the cycle nulls said.
3. **Gray coding gives a clock model.** Neighbouring phases differ in two
   bits, the median of three consecutive phases is the middle one, and the
   ordered state is a mosaic of phase domains with d1 fixed at 2/128, instead
   of F's single synchronised phase.
4. **Species interactions are set by the header bytes.** Pairwise crossings
   are symmetric, so there is no designed dominance yet; the lattice picks C,
   and A and C cannot touch (their mixture is B). Cyclic dominance is a
   matter of choosing H0 so that the bitwise mixtures of two headers point
   into the third's region in a rotating pattern, and of the all-X reading
   length (44 bits for `3`, 60 for `2`, 72 for `1`), which is the likely
   source of C's advantage and is testable by changing the letters.

## 5. Next

- Test the read-length hypothesis: species letters with equal all-X reading
  lengths (or permuted), same geometry; if C's dominance follows the letter,
  it is a design knob.
- Design cyclic dominance: choose three H0 whose pairwise bit mixtures land
  in the third species' region in a cycle (A × B → C, B × C → A, C × A → B)
  and look for spiral waves at median p = 1 annealed.
- Longer cycles (16 or 32 states, Gray over bits 4..8) for a finer clock;
  and a species whose cycle states share fewer planes, to move the
  granular-to-ordered transition.
- The quenched phase mosaic at median p = 0.7 is a pinned q = 8 clock
  model; measure the pinned length against system size as for MS−.

## 6. Four, five and six species (added the same evening)

`design-dict.mjs species=N` generalises the construction: letters whose
all-X cell starts with six or more dictionary bytes from distinct positions
are `0 ! 1 " 2 # 3` (all-X reads 88, 84, 72, 74, 60, 56, 44 bits), the
blocks go to the printable header spots {128, 256, 384} + {0, 1024, 2048,
3072} clear of the landing pads, and the region bounds are hill-climbed for
equal basins (limited by the block positions). The three-species dictionary
is reproduced byte for byte. Dictionaries `ca-gray4c` (letters `0123`),
`ca-gray5c` (`0"123`), `ca-gray6c` (`0!"123`), all in the page manifest.

| | 4 species | 5 species | 6 species |
|---|---|---|---|
| census shares | 22 / 32 / 22 / 25 % | 24 / 13 / 12 / 15 / 35 %, stray 1.3 % | 21 / 11 / 14 / 13 / 10 / 33 % |
| transient mean / p90 | 5.2 / 8 | 5.2 / 8 | 5.4 / 9 |
| on a cycle after 8 steps | 91.4 % | 90.3 % | 89.8 % |
| bit flip: return mean, same species | 1.5, 93.5 % | 1.5, 91.6 % (12 lost) | 1.5, 90.6 % |
| lattice, median 1 quenched, 1,000 turns | all four pinned: 9 / 38 / 10 / 43 %, 93 domains | `0` 8 %, `2` 47 %, `3` 45 %; `"` and `1` gone by turn 100 | `3` 78 %, the rest 0 to 10 % |
| median 1 annealed | `1` 46 %, `3` 54 % | `2` 55 %, `3` 45 % | `3` alone by turn 1,000 |
| median 0.6 annealed | `1` 25 %, `3` 75 %, 52 phase domains | `2` 78 %, `3` 22 % | `3` alone, 66 phase domains |
| page frame | four species under the granular sky, 48 % off-cycle | `0`, `2`, `3` below, `"` and `1` traces | `3` with traces of the others |

(Species named by their letter; A..F in the tables of `runs/log-g*.txt`,
frames `ca-gray{4,5,6}c-*.png`: species = hue, phase = lightness.)

The letter `3` wins in every design that contains it, `2` is second, and the
letters with long all-X readings (`"` 74 bits, `1` 72, `!` 84) lose first:
the ranking of the species on the lattice follows the length of the all-X
reading, as conjectured in section 4. The pairwise invasion tables stay
symmetric (50 / 50, or 25 / 25 with the rest to a third species whose
header is the bitwise mixture) except in the six-species dictionary, where
`3` beats `!` 72 / 28 and `0` 36 / 13 at q = ½. The four-species quenched
mosaic (all four pinned, 93 domains) and the five-species frame are the
richest pictures; with six species the strong letter takes over.

So the knob for coexistence is the reading length of the constant letters,
and for a balanced many-species picture the letters should have equal
reading lengths. The seven qualifying letters do not offer that; the next
step is to search the printable bytes for letters with equal, short
readings, or to pad the regions with a two-byte pattern whose misaligned
readings are controlled in the same way.

## 7. Seven to thirty-two species: where the construction stops (2026-10-19)

The request was 7, 8, 9, … up to 32 species, "perhaps with a longer
dictionary". The tool was generalised (`design-dict.mjs species=N`,
`V=`, `len=`): filler patterns of one, two or three bytes whose rotations
land, chosen together with the blocks by a randomised packing search so that
no landing pad falls inside a block or on another pad; at 13 header bits
(window V = 8122, the page's maximum) the head's second copy takes an
explicit distance (the ring form puts 0x80 in byte 5) and tail byte 6 must be
0 mod 8. The three-species dictionary is still reproduced byte for byte.

**A longer dictionary does not help.** The decoder can only reach positions
below the window range V (plus 64 bytes of wrap), so bytes beyond V are dead;
what limits the design is the header window and what printable ASCII allows
inside it:

- Blocks need head byte 1 printable, which puts every block and every landing
  pad in the same quarter of the header range (h mod 1024 in [128, 508]):
  1,520 bytes at V = 4096, 3,040 at V = 8122. With 128 bytes per block and
  pads in between, at most 12 blocks fit at 4096 and about 24 at 8122 (four
  or eight more with control characters in byte 1).
- Fully landing patterns are few and their pads cluster: 45 single or
  two-byte patterns at V = 4096 with at most **11** mutually compatible, 59
  at V = 8122 with at most **8**. The larger window has fewer, not more,
  qualifying patterns, because the extra header bit shifts the command bits.
- Beyond that the search has to take patterns with a rotation that does not
  land, whose cells are junk that forms stray cycles.

| species | window | readings (bits) | on a cycle after 8 steps | stray | transient mean | lattice, median 1 quenched: species alive (> 1 %) |
|---|---|---|---|---|---|---|
| 3 to 6 | 4096 | 44 to 88, all landing | 90 to 93 % | 0 to 1.3 % | 5.1 to 5.4 | all (3, 4), 3 of 5, 1 to 2 of 6 |
| 7 | 4096 | 72 to 106, all landing | 80 % | 5.8 % | 6.0 | 1 |
| 8 | 4096 | 54 to 74, 4 partial | 27 % | 5.6 % | 12.5 | **0: never orders** (100 % off-cycle) |
| 9 | 4096 | 44 to 72, 4 partial | 72 % | 0 | 7.0 | 3 |
| 10 | 4096 | 44 to 72, 5 partial | 75 % | 0 | 7.9 | 3 |
| 11 | 4096 | 42 to 56, 8 partial | 53 % | 0.1 % | 11.3 | 2 |
| 12 | 4096 | 42 to 56, 9 partial | 52 % | 6.6 % | 9.3 | 2 |
| 14 | 8122 | 54 to 70, 11 partial | 8 % | **87 %** | 9.3 | 0: never orders |
| 16 | 8122 | 43 to 82, 11 partial | 24 % | 22 % | 15.6 | 4 |
| 18 | 8122 | 43 to 82, 13 partial | 25 % | 0 | 23.2 | 4 |
| 20 | 8122 | 43 to 82, 15 partial | 24 % | 54 % | 9.2 | 4 |
| 24 | 8122 | 54 to 96, 21 partial | 23 % | 0.4 % | 23.9 | 2 |
| 28, 32 | 8122 | — | — | — | — | no block packing exists |

(Lattice: 256², swap ½, 1,000 turns, seed 1; `runs/log-g*.txt`. Annealed
at median 1 one species is left in every case except 16, 18 and 20 with two
to four. The page frame keeps 46 to 66 % of the cells off-cycle with two or
three species below the sky.)

The lattice is harsher than the census. Even where the decoder has nine or
ten clean attractors and a funnel at F's level, the collective selection by
reading length leaves one to three species after 1,000 turns at median 1,
and the dictionaries whose random cells mostly end in stray cycles (8 and
14) never order at all: the junk cycles are what the swaps keep producing.
Six species is the most that coexist in a quenched mosaic; three or four is
where every species keeps a visible share.

What would be needed for 32 coexisting species: equal reading lengths (the
collective selection removes the slower ones regardless of basin size), a
funnel for each species as steep as a single constant byte's, and header
room for 32 blocks. The first two need a different landing mechanism than
one pad per constant pattern, for example a two-step pad chain steering the
orbit of a non-landing rotation; the third needs either bytes outside ASCII
(the page decodes dictionaries as UTF-8) or a 14-bit window, which breaks the
printable head encoding. Shorter cycles (4 states, 64-byte blocks) would
free header room but not funnels. All thirteen dictionaries (7 to 24) are in
the page manifest; the eight-species and larger ones at window 8122 need the
Dictionary window range set to 8122 (`cread=8122` in the settings line).

## 8. Long dictionaries: 7 to 32 species at a 16-bit window (2026-10-19)

The author's suggestion was right in substance: what the many-species
designs lacked was addressable room, and the way to get it is a longer
dictionary **together with a wider window range**. With V = 60000 the
header has 16 bits, the dictionary is 61,440 bytes (the module's static
region allows 65,024, so 256 kB would need a new memory layout), and every
byte below 60000 is reachable. The head form is searched at 14 or more
header bits (here: distance 17, uppercase transform on the first copy,
explicit second distance; 54 bits, so tail byte 6 must match the head's
last six bits); the page's window-range box now accepts up to 65535
(`cread=60000` in the settings line). The module agrees with the reference
decoder on 49,152 cells at V = 60000 (0 mismatches).

At this window 1,035 one-, two- and three-byte patterns land in every
rotation (902 pairs, 906 triples qualify at all) with 54 block spots, so the
packing search finds fully landing patterns for every species up to 32:

| species | on a cycle after 8 steps | stray | transient mean / p90 | lattice, median 1 quenched: alive (> 1 %), top shares | annealed |
|---|---|---|---|---|---|
| 7 | 90 % | 0.3 % | 5.3 / 8 | 2: 52 / 44 % | 2 |
| 8 | 90 % | 0.2 % | 5.4 / 8 | 2: 84 / 13 % | 1 |
| 9 | 85 % | 0.2 % | 6.0 / 10 | 2: 64 / 32 % | 2 |
| 10 | 92 % | 0.03 % | 5.3 / 8 | 2: 53 / 44 % | 2 |
| 11 | 89 % | 0.01 % | 5.6 / 9 | 2: 96 / 3 % | 1 |
| 12 | 76 % | 7.9 % | 6.3 / 10 | **0: never orders** | 0 |
| 14 | 80 % | 5.6 % | 6.1 / 10 | 0: never orders | 0 |
| 16 | 73 % | 9.8 % | 6.8 / 11 | 0: never orders | 0 |
| 18 | 84 % | 0.3 % | 6.1 / 10 | 1 | 1 |
| 20 | 85 % | 0.01 % | 6.1 / 10 | 1: 99 % | 1 |
| 21 | 85 % | 0.05 % | 6.0 / 10 | 3: 85 / 13 / 1 % | 2 |
| 22 | 84 % | 0.02 % | 6.1 / 10 | 3: 76 / 14 / 9 %, 50 domains | 2 |
| 23 | 86 % | 0.2 % | 6.0 / 10 | 3: 64 / 20 / 15 %, 61 domains | 2 |
| 24 | 81 % | 0.1 % | 6.8 / 12 | **7: 49 / 28 / 9 %**, 69 domains | 4 |
| 25 | 81 % | 0.2 % | 6.6 / 11 | 5: 54 / 30 / 6 %, 66 domains | 4 |
| 26 | 80 % | 0.01 % | 6.4 / 11 | **4: 45 / 34 / 15 %**, 92 domains | 4: 41 / 32 / 22 %, 65 domains |
| 27 | 79 % | 0.1 % | 6.7 / 11 | 1: 99 % | 1 |
| 28 | 87 % | 0.1 % | 5.7 / 9 | 2: 70 / 30 % | 2 |
| 29 | 82 % | 0.01 % | 6.4 / 11 | 2: 84 / 15 % | 1 |
| 30 | 81 % | 0.02 % | 6.4 / 10 | 3: 53 / 41 / 4 % | 2 |
| 31 | 85 % | 0.01 % | 6.0 / 10 | 2: 97 / 3 % | 1 |
| 32 | 83 % | 0.01 % | 6.4 / 10 | 1: 98 % | 1 |

(Census 10,000 random cells; lattice 256², swap ½, 1,000 turns, seed 1,
`runs/log-g*.txt`; the page frame keeps 40 to 68 % of the cells off-cycle
with one to four species below the sky.)

So the construction now scales: thirty-two 8-cycles with Gray steps, no
stray cycle worth the name, and a funnel at F's level or better (F: 50 %
after 8 steps, transient 9.6). What does not scale is coexistence on the
lattice. Two regularities:

- **Stray cycles are fatal.** The three dictionaries whose random cells end
  in stray cycles 6 to 10 % of the time (12, 14, 16 species) never order at
  all: the swaps keep producing the junk that feeds those cycles, and the
  designed species never get a foothold. Below 0.5 % stray the lattice
  orders every time. The design rule is therefore: no stray cycles, before
  anything else; the packing search should score the census, not only the
  pads.
- **The lattice keeps one to three species whatever the count,** with
  exceptions that depend on the particular pattern set rather than on the
  count: 24 species keep seven in a 69-domain mosaic at median 1 quenched,
  26 keep four even when annealed (41 / 32 / 22 %, 65 domains, the only
  design whose annealed run does not collapse to one or two), 25 keep five;
  27, 29 and 31 are down to one. Which species win is set by the reading lengths (48 to 101
  bits here) and by the collective funnel, not by the basin shares of the
  census, which are spread over all species in every design.

For many coexisting species the next lever is therefore not the dictionary's
length but the selection: equal reading lengths for all patterns (the
packing search can be told to use one reading length only, 48 bits here,
of which there are 369 patterns), a census-scored search that rejects any
stray cycle, and the quenched hashing, which pins the mosaic before the
collective selection finishes.

## 9. Other cycle lengths: 5 to 12 (2026-10-19)

`design-dict.mjs cycles=` takes one length per species, 3 to 16. A cycle is
a closed walk on the header cube found by depth-first search: bits 4..6 for
lengths up to 8, with header bit 10 as a fourth Gray bit for 9 to 16 (bit 7
would push byte 1 out of the printable range, so a long-cycle species has
two 128-byte blocks 1,024 apart). Even lengths walk in one-bit steps; an
odd length takes exactly one two-bit step. The tail's parity byte (byte 6,
or byte 7 when the 16-bit head fixes byte 6) flips on every one-bit step
and stays on the two-bit step, so **every step is two bits** for every
length. The 8-cycle designs are reproduced byte for byte (`cycles=8` is the
old reflected Gray code with the old tail scheme).

| dictionary | window | species (cycle length, pattern) | on a cycle after 8 steps | stray | transient |
|---|---|---|---|---|---|
| `ca-cyc567` | 4096 | 5 `1`, 6 `2`, 7 `3` | 94 % | 0 | 5.1 / 8 |
| `ca-cyc5to12` | 60000 | 5 `??3`, 6 `;7`, 7 `37`, 8 `3?`, 9 `?7`, 10 `3;`, 11 `7`, 12 `;?` (all readings 48 bits) | 86 % | 0.35 % | 5.9 / 10 |

Lattice (256², swap ½, 1,000 turns, seed 1):

| dictionary | median 1 quenched | median 1 annealed | median 0.6 annealed | page frame |
|---|---|---|---|---|
| `ca-cyc567` | all three: 12 / 19 / 67 % (5-, 6-, 7-cycle), 27 domains, 246 phase domains | 6- and 7-cycle, 15 / 85 % | 7-cycle alone, 83 phase domains | 7-cycle below the sky with traces of the others |
| `ca-cyc5to12` | the 12-cycle alone, 252 phase domains | the 12-cycle alone, 49 | the 12-cycle alone, 167 | the 12-cycle alone below the sky |

Two observations. With the letters `1 2 3` the 7-cycle on `3` wins as the
8-cycle on `3` did (section 6), so the reading length still rules there.
In the eight-species dictionary every pattern has the same reading (48
bits) and the **longest cycle wins everywhere**, at every median strength,
with the 11-cycle not even second; a longer cycle has more phases and so
more states that a disturbed neighbour can be pulled onto, which is the
same advantage a steeper funnel gives. One seed and one design; the test
is a set of equal-reading patterns with the lengths permuted over them.
Both dictionaries are in the page manifest; the mixed one needs the window
range 60000.
