# Results: the decoder as a map (Q4 / H4)

2026-10-18. Scripts: `paper/experiments/decoder-map.mjs` (a bit-exact
JavaScript reference of the Brotli-like decoder, kind 36, checked against the
WebAssembly module on 1.6 million random cells at V ∈ {1, 8, 128, 4096} and
skip ∈ {0, 6} with zero mismatches), `decoder-map-all.sh` (the battery),
`decoder-map-summary.mjs` (the tables). Data: `paper/data/decoder-map/`
(one JSON per run, `summary.csv`, `summary.md`). Each run decodes 10⁶
uniformly random 128-bit cells with 6 skipped bits and offset 0. Dictionaries:
the Declaration, Don Quijote and Kalevala as texts; Brotli search 1, 9, 13 and
Swarm search A, D, F as searched dictionaries; every one of them shuffled by
byte, shuffled by word and reversed at V = 4096; three sampling seeds for F raw
and F shuffled.

## 1. The command skeleton does not depend on the dictionary

For every dictionary and every control the following agree to the printed
precision, because the insert lengths, literal count, copy lengths and
distances are read from the cell's bits and the dictionary only supplies the
copied byte values:

| header range V | header bits | bits consumed | E[min(c, 128)] | cells reading past 128 bits | cells at the 1,024-bit cap | commands per cell |
|---|---|---|---|---|---|---|
| 1 | 0 | 81.7 | 81.7 | 0.4 % | 0 | 4.68 |
| 8 | 3 | 84.8 | 84.7 | 1.0 % | 0 | 4.68 |
| 128 | 7 | 88.7 | 88.6 | 2.2 % | 0 | 4.68 |
| 4096 | 12 | 93.8 | 93.5 | 5.0 % | 0 | 4.68 |

Output byte sources at every V: 36.9 % literals read from the cell, 18.2 %
copied from the output already written, 44.9 % copied from the dictionary,
0.00 % kept from the input (the output always fills: 16 bytes take about 82
bits of commands, and the stream wraps round the cell when they run out). The
compression reviewer's estimate from the grammar (about 30 % literal, E[c]
near 80) was close.

Consequences. (a) **E[min(c, 128)] = 93.5 bits bounds H(f(U)) at the reference
setting**: on average an output has at least 2^34 preimages, and the image of
f has at most 2^93.5 elements in entropy terms. The plan's H4 ("thousands, not
2^128") was wrong for this decoder, as the compression review predicted;
"thousands" can only describe the attractor set under iteration, which the
−−R ablation row measures. (b) Against the random-mapping null (Harris: image
fraction 1 − 1/e, H ≈ 127.2 bits) the decoder is a far stronger contraction,
by at least 34 bits. (c) The matched null for the lattice experiments is a
random map with H(f(U)) = 93 bits, which is what `hash:93` implements.

## 2. The dictionary acts through the output alphabet and its second-order structure

| dictionary | bytes | distinct bytes | dictionary byte H | dictionary H(next \| byte) | output byte H | output H(next \| byte) | distinct outputs of 10⁶ | log₂ Chao1 |
|---|---|---|---|---|---|---|---|---|
| Declaration | 8,123 | 61 | 4.37 | 3.27 | 7.07 | 6.43 | 999,678 | 32.9 |
| Don Quijote | 2,336 | 52 | 4.34 | — | 7.07 | — | 999,682 | 32.8 |
| Kalevala 1 | 2,486 | 40 | 4.36 | — | 7.12 | — | 999,665 | 33.0 |
| Brotli 1 | 4,400 | 9 | 2.24 | — | 6.26 | — | 999,255 | 30.8 |
| Brotli 9 | 4,400 | 52 | 2.32 | — | 6.17 | — | 997,446 | 29.7 |
| Brotli 13 | 4,400 | 59 | 2.91 | 1.81 | 6.37 | 5.62 | 997,773 | 29.9 |
| Swarm A | 4,400 | 53 | 1.84 | — | 5.74 | — | 988,387 | 28.2 |
| Swarm D | 4,400 | 80 | 2.88 | — | 6.29 | — | 997,230 | 29.7 |
| Swarm F | 4,400 | 54 | 1.93 | 1.14 | 5.70 | 5.05 | 988,284 | 28.1 |

(The dashes are in `summary.md`; the three shown are the ones discussed.) The
input is 8 bits per byte. A text dictionary leaves 7.1 bits per output byte;
the searched dictionaries leave 5.7 to 6.4, F the least. Since 55 % of output
bytes are literals or self-copies with the input's full 8 bits, the whole drop
sits in the 45 % dictionary-copied bytes: for F those carry about 1.9 bits
each, the dictionary's own byte entropy. Byte 0 of the output has the highest
entropy (7.2 to 7.7 bits, since the first command is usually an insert) and
byte 7 the lowest (5.24 for F), rising again towards byte 15.

**The controls.** Shuffling the dictionary's bytes leaves every first-order
statistic unchanged (F: output byte entropy 5.70 raw, 5.68 shuffled; sources,
consumed bits and per-position entropies identical to the second decimal), so
at first order the alphabet alone matters, exactly the outcome the plan feared
for Q3. The order of the dictionary shows only at second order: the output's
conditional entropy H(next byte | byte) is 5.05 bits for F raw, 5.30 for F
shuffled (three shuffles: 5.30, 5.31, 5.30), 5.07 for the word shuffle and
5.08 for the reversal; the dictionary's own conditional entropy goes 1.14 →
1.87 → 1.14 → 1.14 under the same operations. So the byte-level structure
that survives shuffling of words is the structure the decoder transmits, about
0.25 bits per output byte for F and 0.27 for the Declaration (6.43 → 6.70).
Whether the lattice responds to that quarter bit is the pre-registered
lattice-level test in `paper/PLAN_AMENDMENTS.md` section 3 (F raw against its
shuffles under MSR, queued as `ablation-extra.sh`).

**Fixed points.** None in 10⁶ cells for any dictionary (f(x) = x has
probability below 10⁻⁶ under uniform x). The number of distinct outputs is a
lower bound only: 988,284 distinct of 10⁶ for F (Chao1 ≥ 2^28) and 999,678 for
the Declaration (≥ 2^33); the true image is far larger (section 1).

## 3. Which bytes of the dictionary are ever read

A back-reference reaches at most 64 bytes behind the window end, so the
decoder reads V + 63 dictionary bytes: 65 at V = 1, 72 at V = 8, 191 at
V = 128 and 4,159 at V = 4096. For a 4,400-byte dictionary at the reference
setting, **bytes 4,095 to 4,335 are never read**, by any cell, under any input:
241 bytes that are exactly neutral and the free null for the positional
sensitivity map of H2 (a mutation there must give a bit-identical run). Bytes
4,336 to 4,399 are read through the wrap from small windows. Of the 8,123-byte
Declaration, bytes 4,095 to 8,058 are never read: the page's Declaration
pictures use only its first half and last 64 bytes. Dictionaries shorter than
4,096 bytes (Don Quijote, Kalevala) are read in full because the header wraps
modulo the length.

## 4. A reproducibility finding

The build (`tools/build.py --dicts`) strips trailing newlines from each
dictionary file and appends one. Four shipped dictionaries do not end in a
newline (`ca-brotli-1`, `ca-brotli-9`, `ca-brotli-13`, `ca-swarm-d`), so the
page decodes against 4,401 bytes where the harness, the swarm and the lattice
searches used 4,400. The extra byte lies in the wrap region read from small
windows and changes the modulus of every window position. The reference
dictionary F and Swarm A end in a newline and agree. Decision for the author:
append the newline to the four files (the harness then matches the page, and
the search scores in the manifest notes become one byte stale) or make the
build stop normalising. Every caption will carry the dictionary file's SHA-256.

## 5. What this changes in the plan

- H4 is restated around H(f(U)) ≤ 93.5 bits, the dictionary-independent
  skeleton and the attractor census under iteration; "thousands" is kept for
  the codebook decoder only, where the exact count is still to be computed.
- The lattice-level null is `hash:93`, matched in H(f(U)); and since the
  decoder's distinctive feature at first order is its output alphabet,
  `hashdict:93` (the same map with the dictionary's byte histogram) is the
  second null.
- The structure question (Q3) is decided at the lattice, not here: the decoder
  passes dictionary order only as a 0.25-bit-per-byte second-order effect.

## 6. The codebook decoder: exact image against sampling

Script `paper/experiments/codebook-image.mjs`, table
`paper/data/decoder-map/codebook-image.md`. For a dictionary shorter than
1,024 bytes every 10-bit code reaches every byte from every window, so the set
B of bigrams a code can produce is the dictionary's set of cyclic bigrams
whatever the window, and the image of a single cell is exactly B⁸. Across the
nine codebook dictionaries |B| runs from 30 to 157, so the exact image is
2^39 to 2^58 and the exact H(f(U)) is 27 to 49 bits, against 87 bits consumed.
Sampling 10⁶ cells sees 2^23 to 2^39 (Chao1): the distinct count undershoots
the true image by 10 to 25 bits, which is the retired professor's point that
sampling counts the heavy part of the image. For the codebook as for the
Brotli-like decoder, "thousands" can only describe the attractors under
iteration, never the image of one application; no fixed point in 10⁶ cells
for any of the nine.
