# Eleven designs per size: is the shipped dictionary typical?

2026-10-23. Scripts: `experiments/design-scale.mjs` with `seed=2..11` (batch `scale-seeds.sh`), `scale-map.mjs` and
`scale-run.mjs` with `design=K`, `scale-seeds-summary.mjs` (the tables below), `scale-seeds-plot.py`. Figure
`../figures/dictionary-size-seeds.png`. Raw data `../data/design-seeds/` (the 190 dictionaries of seeds 2–11,
about 1.5 GB, and their design files) and `../data/scale-seeds/` (git-ignored, provenance in every file). Seed 1 is the
construction of `dictionary-size.md` (`src/changers/dict/ca-size-NN.txt`, byte-identical before and after this change:
checked by sha256 for 2^8 .. 2^24).

## 1. Question

`dictionary-size.md` measured one design per size. The construction has choices the seed did not reach: the head
form, the share of Gray groups in the block budget, the period cap of the filler patterns, the order in which patterns
are offered to the types. Eleven designs per size, each with its own choices, give the median and the spread of the
richness measures against size, and say whether the shipped seed-1 dictionaries are typical of the construction.

## 2. Method

**Sizes 2^25 and 2^26** were added first (seed 1): the module's cap went from 2^24 to 2^26 (`Codec.install`), the page's
window-range and offset boxes to 2^26, the render's cursor-colour index to 64-bit arithmetic, `test/bigdict.test.mjs`
to 64 MB (5,000 random cells at 26 header bits, the codebook against a BigInt reference); 2^26 is a preset, 2^25 is in
the dictionary list. Both are served locally only (not in the Pages workflow; see §5).

**The approach, varied by the seed** (seed 1 unchanged; `design-scale.mjs` header and the `approach` field of every
design JSON): the head form is drawn among the viable forms within 60 % of the best score (seed 1 takes the best); the
Gray groups are round(f · B/5) with f drawn from {0.5, 0.75, 1, 1.5, 2} (seed 1: f = 1), the rest of the budget B
chasing; the pattern period cap is drawn from {3, 4, 4} (seed 1: 4); the patterns are offered shortest reading first,
longest first, or in a seeded shuffle (seed 1: shortest). The seed also shuffles the spots and groups and the
placement trials, as before. The pattern enumeration depends only on the header bits, the head bytes and the period
cap, so it is cached per size (`../data/design/patterns/`) and shared by the seeds; the jobs run seed-major, twelve at
a time with two threads each.

**Measures** as in `dictionary-size.md`: the map census (16,384 random cells, Brent) and one frame lattice run per
design (256², 2,000 turns, three settling passes, the rotating order, quenched hashing, decoder 36, skip 6, window
range V), the lattice seed equal to the design seed; types alive (share ≥ 0.1 %), entropy of the type shares over the
cells on a type, transient share, domains, block change at turn 2,000. The uniform setting holds nothing from a random
start at any size (`dictionary-size.md` §4) and was not run. Per size the tables give the median and the interquartile
range over the 11 designs and the seed-1 value beside them.

<!-- provenance: paper/experiments/scale-seeds-summary.mjs (6d89bbe334523eba)  | commit 1a2a747+dirty | wasm 70b2e1c5d518b905 | 2026-10-23T00:25:46.322Z -->

## 3. Results (the tables are `../data/scale-seeds/summary.md`, written by `scale-seeds-summary.mjs` from the data files)

Each cell: median [interquartile range] over the 11 designs · the seed-1 (shipped) value.

### 3.1 Designed types, the map alone, and generation time

| log2 size | designs | types designed | reached by the map | stray share | placement + verification + census s (the pattern enumeration is cached) | seed 1 cold, s |
|---|---|---|---|---|---|---|
| 8 | 11 | 1 [1–1] · 1 | 1 [1–1] · 1 | 28.8 % [9.2 %–36.8 %] · 28.8 % | 1 [1–1] · 1 | 175 |
| 9 | 11 | 1 [1–1] · 1 | 1 [1–1] · 1 | 7.7 % [0.0 %–21.7 %] · 21.4 % | 1 [1–1] · 0 | 151 |
| 10 | 11 | 1 [1–1] · 1 | 1 [1–1] · 1 | 1.3 % [0.1 %–12.8 %] · 0.0 % | 1 [1–1] · 1 | 123 |
| 11 | 11 | 3 [3–3] · 3 | 3 [3–3] · 3 | 1.0 % [0.2 %–8.5 %] · 15.9 % | 1 [1–1] · 1 | 108 |
| 12 | 11 | 5 [5–5] · 5 | 5 [5–5] · 5 | 0.1 % [0.0 %–2.0 %] · 2.6 % | 1 [1–1] · 1 | 111 |
| 13 | 11 | 6 [6–6] · 6 | 6 [6–6] · 6 | 8.2 % [5.2 %–10.1 %] · 0.0 % | 1 [1–1] · 1 | 121 |
| 14 | 11 | 8 [8–8] · 8 | 8 [8–8] · 8 | 2.2 % [0.4 %–5.9 %] · 0.0 % | 1 [1–1] · 1 | 97 |
| 15 | 11 | 1 [1–5] · 9 | 1 [1–5] · 9 | 0.9 % [0.3 %–3.2 %] · 0.9 % | 1 [1–1] · 1 | 115 |
| 16 | 11 | 25 [22–28] · 25 | 25 [22–28] · 25 | 0.9 % [0.1 %–1.8 %] · 2.1 % | 1 [1–1] · 1 | 133 |
| 17 | 11 | 38 [37–46] · 38 | 38 [37–46] · 38 | 0.2 % [0.0 %–0.8 %] · 1.9 % | 1 [1–1] · 1 | 110 |
| 18 | 11 | 23 [16–35] · 38 | 23 [16–35] · 38 | 0.3 % [0.0 %–1.0 %] · 0.3 % | 1 [1–1] · 1 | 101 |
| 19 | 11 | 46 [43–62] · 70 | 46 [43–62] · 70 | 0.1 % [0.0 %–0.6 %] · 0.0 % | 1 [1–1] · 1 | 86 |
| 20 | 11 | 24 [21–30] · 63 | 24 [21–30] · 63 | 0.3 % [0.0 %–1.3 %] · 0.5 % | 1 [1–2] · 1 | 81 |
| 21 | 11 | 38 [34–48] · 56 | 38 [34–48] · 56 | 1.8 % [0.2 %–2.5 %] · 4.6 % | 2 [1–2] · 1 | 90 |
| 22 | 11 | 34 [30–38] · 38 | 34 [30–38] · 38 | 1.8 % [0.4 %–4.9 %] · 11.5 % | 3 [2–4] · 1 | 86 |
| 23 | 11 | 11 [10–11] · 10 | 11 [10–11] · 10 | 2.1 % [1.0 %–5.1 %] · 3.1 % | 6 [4–7] · 2 | 88 |
| 24 | 11 | 2026 [1671–2055] · 2055 | 1849 [1588–1903] · 1892 | 0.0 % [0.0 %–0.1 %] · 0.1 % | 13 [4–230] · 3 | 68 |
| 25 | 11 | 394 [366–510] · 1343 | 394 [366–510] · 1263 | 0.2 % [0.1 %–1.0 %] · 0.0 % | 375 [231–587] · 89 | 267 |
| 26 | 11 | 132 [126–138] · 138 | 132 [126–138] · 138 | 0.4 % [0.0 %–0.8 %] · 1.1 % | 49 [38–71] · 31 | 116 |

### 3.2 The frame, 256², 2,000 turns, one run per design (lattice seed = design seed)

| log2 size | alive at 2,000 | entropy (bits) | transients | domains | block change |
|---|---|---|---|---|---|
| 8 | 1 [1–1] · 1 | 0 [0–0] · 0 | 71.5 % [44.0 %–97.8 %] · 71.5 % | 120 [76–145] · 169 | 0.005 [0–0.009] · 0.022 |
| 9 | 1 [1–1] · 1 | 0 [0–0] · 0 | 76.6 % [44.0 %–84.5 %] · 84.6 % | 207 [159–384] · 107 | 0.006 [0.002–0.014] · 0.004 |
| 10 | 1 [1–1] · 1 | 0 [0–0] · 0 | 56.9 % [44.5 %–67.7 %] · 49.3 % | 149 [68–251] · 157 | 0.010 [0.004–0.014] · 0.019 |
| 11 | 3 [3–3] · 3 | 0.74 [0.52–0.94] · 0.59 | 53.0 % [41.4 %–79.6 %] · 89.3 % | 308 [284–383] · 234 | 0.010 [0.002–0.015] · 0 |
| 12 | 5 [4–5] · 5 | 0.95 [0.55–1.59] · 1.79 | 54.1 % [52.7 %–57.7 %] · 64.3 % | 492 [225–658] · 916 | 0.017 [0.012–0.021] · 0.028 |
| 13 | 5 [4.5–6] · 5 | 1.12 [0.99–1.99] · 1.12 | 72.5 % [58.7 %–82.8 %] · 50.2 % | 232 [196–312] · 217 | 0.008 [0.006–0.014] · 0.005 |
| 14 | 4 [3–5] · 5 | 1.06 [0.47–1.36] · 1.61 | 64.3 % [61.0 %–79.8 %] · 50.9 % | 121 [99–189] · 448 | 0.008 [0.007–0.009] · 0.008 |
| 15 | 1 [1–4] · 4 | 0 [0–1.02] · 1.17 | 51.4 % [41.4 %–56.2 %] · 58.8 % | 353 [281–483] · 307 | 0.018 [0.013–0.024] · 0.001 |
| 16 | 10 [8.5–14] · 14 | 2.24 [1.97–2.34] · 2.44 | 44.0 % [42.0 %–47.3 %] · 45.6 % | 873 [693–1241] · 2079 | 0.019 [0.016–0.028] · 0.028 |
| 17 | 10 [10–15.5] · 16 | 2.23 [1.89–2.51] · 2.21 | 53.0 % [47.9 %–55.1 %] · 53.1 % | 874 [594–999] · 1228 | 0.015 [0.014–0.017] · 0.017 |
| 18 | 9 [7.5–12] · 13 | 1.81 [1.42–2.44] · 2.69 | 55.1 % [51.9 %–64.4 %] · 54.1 % | 683 [473–791] · 1321 | 0.012 [0.010–0.022] · 0.026 |
| 19 | 6 [5–7.5] · 16 | 1.65 [1.35–2.06] · 2.71 | 61.3 % [59.7 %–69.7 %] · 59.5 % | 421 [339–801] · 758 | 0.013 [0.010–0.015] · 0.011 |
| 20 | 4 [4–6] · 12 | 1.45 [0.75–1.92] · 2.71 | 71.7 % [68.3 %–82.3 %] · 68.4 % | 314 [276–462] · 547 | 0.014 [0.007–0.018] · 0.009 |
| 21 | 5 [3.5–5.5] · 4 | 1.20 [0.72–1.55] · 1.02 | 68.5 % [62.3 %–81.2 %] · 58.9 % | 219 [200–315] · 370 | 0.008 [0.003–0.013] · 0.002 |
| 22 | 3 [2.5–4.5] · 1 | 1.22 [0.63–1.76] · 0.36 | 86.3 % [80.4 %–97.6 %] · 88.6 % | 160 [121–236] · 160 | 0.008 [0.002–0.016] · 0.008 |
| 23 | 2 [1.5–4] · 4 | 0.27 [0.13–0.33] · 0.27 | 73.5 % [71.6 %–81.6 %] · 73.5 % | 238 [173–372] · 389 | 0.016 [0.013–0.020] · 0.021 |
| 24 | 38 [26–57.5] · 37 | 4.59 [3.83–5.54] · 4.86 | 45.2 % [42.7 %–49.2 %] · 42.6 % | 2054 [1771–2472] · 2124 | 0.022 [0.017–0.028] · 0.035 |
| 25 | 5 [3.5–7.5] · 9 | 1.53 [1.31–2.40] · 1.32 | 83.2 % [73.7 %–91.3 %] · 57.8 % | 265 [250–384] · 525 | 0.011 [0.005–0.013] · 0.011 |
| 26 | 6 [5–6] · 5 | 2.07 [1.54–2.77] · 2.93 | 85.9 % [76.8 %–95.7 %] · 96.3 % | 328 [272–397] · 289 | 0.005 [0.001–0.009] · 0 |

### 3.3 The approaches per size (seed: form, Gray factor, period cap, pattern order → types designed / alive)

- 2^8: s1 13+3 d17 explicit, ×1, p4, shortest → 1 / 1; s2 7+9 d29 explicit, ×0.75, p4, longest → 1 / 1; s3 7+5+4 d25 explicit, ×0.75, p4, shortest → 1 / 1; s4 8+4+4 d25 explicit, ×0.75, p3, shuffled → 1 / 1; s5 7+6+3 d21 explicit, ×1, p4, shuffled → 1 / 1; s6 4+6+6 d16 ring, ×1, p4, shuffled → 1 / 1; s7 5+2+9 d19 explicit, ×0.5, p4, shortest → 1 / 1; s8 10+3+3 d25 explicit, ×0.5, p3, shortest → 1 / 1; s9 5+6+5 d16 ring, ×0.75, p4, longest → 1 / 1; s10 2+7+7 d16 ring, ×1, p4, longest → 1 / 1; s11 9+5+2 d21 explicit, ×2, p4, longest → 1 / 1
- 2^9: s1 13+3 d17 explicit, ×1, p4, shortest → 1 / 1; s2 9+5+2 d31 explicit, ×1.5, p3, longest → 1 / 1; s3 8+3+5 d17 explicit, ×2, p4, shortest → 1 / 1; s4 6+8+2 d21 explicit, ×0.5, p3, shuffled → 1 / 1; s5 7+7+2 d19 explicit, ×0.75, p3, shuffled → 1 / 1; s6 6+8+2 d19 explicit, ×0.5, p4, shuffled → 1 / 1; s7 9+3+4 d25 explicit, ×1, p3, shortest → 1 / 1; s8 8+3+5 d27 explicit, ×1, p4, shuffled → 1 / 1; s9 4+4+8 d26 explicit, ×1, p3, shortest → 1 / 1; s10 7+9 d27 explicit, ×1, p4, shortest → 1 / 1; s11 8+5+3 d17 explicit, ×0.5, p3, shuffled → 1 / 1
- 2^10: s1 13+3 d16 ring, ×1, p4, shortest → 1 / 1; s2 2+3+11 d16 ring, ×2, p4, shortest → 1 / 1; s3 8+6+2 d16 ring, ×1, p3, shuffled → 1 / 1; s4 10+2+4 d16 ring, ×0.5, p4, longest → 1 / 1; s5 4+12 d17 explicit, ×1, p4, longest → 1 / 1; s6 4+12 d17 explicit, ×0.5, p3, shuffled → 1 / 1; s7 5+6+5 d21 explicit, ×0.75, p4, shuffled → 1 / 1; s8 4+6+6 d25 explicit, ×1.5, p3, shuffled → 1 / 1; s9 6+2+8 d16 ring, ×1, p3, shortest → 1 / 1; s10 5+9+2 d29 explicit, ×0.75, p4, shuffled → 1 / 1; s11 5+6+5 d17 explicit, ×0.5, p3, shortest → 1 / 1
- 2^11: s1 3+13 d17 explicit, ×1, p4, shortest → 3 / 3; s2 7+4+5 d17 explicit, ×0.5, p3, shortest → 3 / 3; s3 2+7+7 d17 explicit, ×0.75, p4, shortest → 3 / 3; s4 6+4+6 d25 explicit, ×1, p4, shuffled → 3 / 3; s5 7+6+3 d22 explicit, ×1, p3, shuffled → 3 / 3; s6 6+7+3 d21 explicit, ×2, p4, shortest → 3 / 3; s7 6+7+3 d21 explicit, ×1, p4, longest → 3 / 3; s8 6+6+4 d24 explicit, ×2, p4, shuffled → 3 / 3; s9 8+2+6 d29 explicit, ×0.75, p3, shortest → 3 / 3; s10 6+6+4 d25 explicit, ×2, p4, longest → 3 / 3; s11 6+4+6 d25 explicit, ×1.5, p3, longest → 3 / 3
- 2^12: s1 4+12 d16 ring, ×1, p4, shortest → 5 / 5; s2 6+6+4 d17 explicit, ×0.5, p3, longest → 1 / 1; s3 10+2+4 d20 explicit, ×0.75, p4, shortest → 5 / 5; s4 2+7+7 d23 explicit, ×2, p4, shortest → 5 / 5; s5 10+6 d17 explicit, ×0.5, p4, longest → 5 / 5; s6 6+4+6 d17 explicit, ×2, p4, shortest → 5 / 4; s7 2+4+10 d17 explicit, ×1, p4, shuffled → 5 / 4; s8 10+6 d20 explicit, ×1.5, p4, shortest → 5 / 5; s9 10+2+4 d19 explicit, ×0.75, p4, shortest → 5 / 5; s10 3+7+6 d19 explicit, ×0.5, p4, longest → 1 / 1; s11 2+8+6 d31 explicit, ×2, p4, longest → 5 / 4
- 2^13: s1 3+13 d16 ring, ×1, p4, shortest → 6 / 5; s2 4+4+8 d29 explicit, ×0.75, p3, shuffled → 6 / 5; s3 3+3+10 d16 ring, ×1, p4, shuffled → 6 / 4; s4 4+2+10 d25 explicit, ×1.5, p4, shuffled → 6 / 5; s5 4+7+5 d28 explicit, ×0.5, p3, shortest → 6 / 6; s6 4+6+6 d16 explicit, ×2, p4, shuffled → 6 / 4; s7 4+8+4 d25 explicit, ×0.5, p4, shuffled → 6 / 6; s8 4+8+4 d24 explicit, ×2, p4, shortest → 6 / 6; s9 4+6+6 d23 explicit, ×0.75, p4, longest → 6 / 4; s10 4+3+9 d29 explicit, ×1, p3, shortest → 6 / 6; s11 4+2+10 d25 explicit, ×1.5, p4, longest → 6 / 5
- 2^14: s1 3+13 d16 ring, ×1, p4, shortest → 8 / 5; s2 3+4+9 d19 explicit, ×1, p4, shuffled → 8 / 2; s3 3+8+5 d20 explicit, ×0.5, p3, shuffled → 8 / 3; s4 3+7+6 d30 explicit, ×0.75, p4, longest → 8 / 3; s5 3+8+5 d16 explicit, ×0.75, p4, longest → 8 / 4; s6 3+6+7 d21 explicit, ×1.5, p3, shortest → 8 / 3; s7 3+8+5 d30 explicit, ×1.5, p4, shuffled → 8 / 1; s8 3+7+6 d16 explicit, ×1.5, p4, longest → 8 / 6; s9 3+6+7 d28 explicit, ×0.5, p4, longest → 8 / 4; s10 3+4+9 d21 explicit, ×2, p4, longest → 5 / 5; s11 3+6+7 d21 explicit, ×1, p3, shuffled → 8 / 7
- 2^15: s1 4+12 d16 explicit, ×1, p4, shortest → 9 / 4; s2 2+10+4 d21 explicit, ×2, p3, shortest → 1 / 1; s3 2+10+4 d20 explicit, ×0.5, p3, shuffled → 1 / 1; s4 2+6+8 d16 ring, ×0.75, p4, longest → 1 / 1; s5 2+6+8 d20 explicit, ×0.5, p4, shortest → 5 / 4; s6 4+8+4 d16 ring, ×1.5, p4, shuffled → 1 / 1; s7 2+5+9 d22 explicit, ×1.5, p4, longest → 1 / 1; s8 2+4+10 d22 explicit, ×0.75, p4, shuffled → 5 / 4; s9 2+5+9 d17 explicit, ×0.5, p3, longest → 1 / 1; s10 2+10+4 d21 explicit, ×1, p4, longest → 1 / 1; s11 2+9+5 d16 ring, ×1.5, p4, shortest → 5 / 5
- 2^16: s1 13+3 d17 explicit, ×1, p4, shortest → 25 / 14; s2 12+4 d17 explicit, ×0.75, p4, shortest → 22 / 15; s3 4+4+8 d16 ring, ×0.75, p4, longest → 22 / 10; s4 5+2+9 d20 explicit, ×1.5, p4, longest → 28 / 14; s5 8+6+2 d25 explicit, ×1, p4, shuffled → 25 / 11; s6 9+3+4 d29 explicit, ×2, p4, shuffled → 31 / 8; s7 9+4+3 d29 explicit, ×1.5, p3, shuffled → 28 / 6; s8 8+4+4 d21 explicit, ×0.5, p4, longest → 19 / 7; s9 8+4+4 d29 explicit, ×0.5, p4, shortest → 19 / 14; s10 8+6+2 d17 explicit, ×0.75, p4, longest → 22 / 10; s11 8+3+5 d25 explicit, ×2, p3, shuffled → 31 / 9
- 2^17: s1 13+3 d17 explicit, ×1, p4, shortest → 38 / 16; s2 9+3+4 d19 explicit, ×0.75, p4, shortest → 35 / 10; s3 9+7 d17 explicit, ×1.5, p4, longest → 44 / 10; s4 5+2+9 d17 explicit, ×2, p3, shortest → 50 / 15; s5 6+8+2 d19 explicit, ×2, p3, shuffled → 48 / 10; s6 7+9 d23 explicit, ×0.75, p3, longest → 35 / 9; s7 8+4+4 d25 explicit, ×1, p3, shortest → 38 / 15; s8 8+4+4 d21 explicit, ×1, p4, shuffled → 38 / 10; s9 7+5+4 d29 explicit, ×2, p4, longest → 48 / 5; s10 8+5+3 d23 explicit, ×0.5, p4, shortest → 32 / 18; s11 9+5+2 d31 explicit, ×1, p3, shortest → 38 / 19
- 2^18: s1 13+3 d16 ring, ×1, p4, shortest → 38 / 13; s2 4+12 d17 explicit, ×1.5, p3, longest → 23 / 13; s3 5+11 d17 explicit, ×1, p4, shuffled → 21 / 6; s4 8+4+4 d16 ring, ×0.75, p3, shortest → 16 / 7; s5 5+9+2 d17 explicit, ×0.5, p4, shortest → 32 / 15; s6 13+3 d16 ring, ×0.5, p4, shuffled → 32 / 9; s7 5+9+2 d25 explicit, ×1.5, p4, longest → 37 / 11; s8 3+5+8 d25 explicit, ×2, p4, shortest → 15 / 8; s9 7+6+3 d16 ring, ×1.5, p3, shortest → 15 / 8; s10 5+3+8 d17 explicit, ×0.5, p4, shuffled → 14 / 7; s11 3+2+11 d26 explicit, ×2, p4, longest → 37 / 9
- 2^19: s1 3+13 d17 explicit, ×1, p4, shortest → 70 / 16; s2 3+11+2 d21 explicit, ×1.5, p4, shuffled → 46 / 5; s3 7+5+4 d16 ring, ×0.75, p4, shuffled → 46 / 3; s4 4+12 d29 explicit, ×0.75, p4, shuffled → 64 / 5; s5 8+5+3 d16 ring, ×0.75, p4, shuffled → 26 / 6; s6 3+13 d21 explicit, ×1.5, p4, shortest → 71 / 5; s7 8+8 d31 explicit, ×2, p4, longest → 46 / 6; s8 8+4+4 d16 ring, ×2, p4, shortest → 30 / 7; s9 8+4+4 d16 ring, ×0.75, p4, shuffled → 39 / 5; s10 3+13 d17 explicit, ×0.5, p4, longest → 60 / 8; s11 8+8 d19 explicit, ×0.75, p3, shuffled → 52 / 18
- 2^20: s1 4+12 d16 ring, ×1, p4, shortest → 63 / 12; s2 3+3+10 d17 explicit, ×1, p4, shortest → 18 / 4; s3 10+6 d17 explicit, ×0.75, p4, longest → 30 / 3; s4 3+13 d23 explicit, ×1.5, p4, shuffled → 22 / 5; s5 3+13 d31 explicit, ×1, p3, shuffled → 24 / 8; s6 3+11+2 d31 explicit, ×2, p3, shuffled → 18 / 6; s7 3+13 d23 explicit, ×0.5, p3, longest → 20 / 3; s8 3+3+10 d25 explicit, ×0.75, p4, shuffled → 24 / 6; s9 3+13 d27 explicit, ×0.75, p4, shortest → 30 / 4; s10 6+10 d24 explicit, ×2, p3, longest → 51 / 4; s11 3+13 d27 explicit, ×1.5, p3, shortest → 22 / 4
- 2^21: s1 3+13 d16 ring, ×1, p4, shortest → 56 / 4; s2 3+10+3 d16 ring, ×2, p3, longest → 26 / 5; s3 3+10+3 d16 ring, ×2, p4, shortest → 34 / 5; s4 4+12 d16 ring, ×2, p3, shuffled → 54 / 4; s5 4+12 d16 ring, ×2, p4, shuffled → 34 / 0; s6 2+11+3 d16 ring, ×0.5, p3, shortest → 30 / 3; s7 3+11+2 d16 ring, ×0.75, p3, shuffled → 39 / 8; s8 2+4+10 d16 ring, ×0.75, p4, shuffled → 38 / 5; s9 3+13 d16 ring, ×1.5, p4, longest → 60 / 6; s10 3+10+3 d16 ring, ×2, p3, shortest → 38 / 3; s11 3+11+2 d16 ring, ×1, p3, longest → 41 / 9
- 2^22: s1 2+12+2 d16 ring, ×1, p4, shortest → 38 / 1; s2 3+3+10 d16 ring, ×2, p4, shortest → 34 / 5; s3 3+3+10 d16 ring, ×1, p4, longest → 30 / 2; s4 3+3+10 d16 ring, ×1.5, p4, shuffled → 30 / 2; s5 3+13 d16 ring, ×0.5, p4, shortest → 30 / 3; s6 3+3+10 d16 ring, ×1.5, p3, shuffled → 30 / 3; s7 3+3+10 d16 ring, ×1, p4, shuffled → 34 / 4; s8 2+12+2 d16 ring, ×1.5, p4, shuffled → 18 / 4; s9 3+13 d16 ring, ×2, p4, shuffled → 46 / 10; s10 3+11+2 d16 ring, ×0.75, p4, shuffled → 38 / 5; s11 3+13 d16 ring, ×1, p3, shuffled → 50 / 3
- 2^23: s1 4+12 d16 explicit, ×1, p4, shortest → 10 / 4; s2 4+12 d16 explicit, ×2, p3, longest → 11 / 4; s3 4+12 d16 explicit, ×1.5, p4, longest → 11 / 1; s4 4+12 d16 explicit, ×0.75, p4, shortest → 10 / 3; s5 4+12 d16 explicit, ×0.5, p4, shortest → 10 / 1; s6 4+12 d16 explicit, ×1, p3, shuffled → 10 / 5; s7 4+12 d16 explicit, ×2, p3, shortest → 10 / 2; s8 4+12 d16 explicit, ×2, p4, longest → 11 / 5; s9 4+12 d16 explicit, ×0.75, p4, shuffled → 12 / 1; s10 4+12 d16 explicit, ×0.75, p3, shuffled → 11 / 2; s11 4+12 d16 explicit, ×1, p3, longest → 11 / 2
- 2^24: s1 13+3 d17 explicit, ×1, p4, shortest → 2055 / 37; s2 12+4 d25 explicit, ×0.5, p3, shuffled → 1671 / 57; s3 10+6 d29 explicit, ×1.5, p4, longest → 2143 / 66; s4 11+5 d25 explicit, ×2, p4, shuffled → 2042 / 38; s5 10+6 d29 explicit, ×1, p4, shuffled → 2026 / 21; s6 10+6 d29 explicit, ×2, p3, shortest → 728 / 5; s7 12+4 d17 explicit, ×0.5, p4, longest → 1671 / 30; s8 10+6 d25 explicit, ×0.5, p4, shuffled → 1671 / 22; s9 12+4 d29 explicit, ×1, p4, shortest → 2055 / 74; s10 6+10 d29 explicit, ×1, p3, shortest → 1911 / 58; s11 8+8 d25 explicit, ×2, p4, shortest → 2109 / 41
- 2^25: s1 13+3 d17 explicit, ×1, p4, shortest → 1343 / 9; s2 13+3 d17 explicit, ×0.75, p4, longest → 534 / 5; s3 7+9 d29 explicit, ×1, p3, longest → 374 / 2; s4 9+7 d21 explicit, ×0.5, p4, shuffled → 1384 / 16; s5 7+9 d23 explicit, ×2, p3, longest → 374 / 4; s6 8+8 d25 explicit, ×0.75, p4, shuffled → 394 / 9; s7 9+7 d23 explicit, ×1.5, p3, shuffled → 334 / 6; s8 6+10 d31 explicit, ×0.75, p3, shuffled → 358 / 3; s9 7+9 d25 explicit, ×1, p3, longest → 342 / 2; s10 6+10 d17 explicit, ×2, p4, longest → 486 / 6; s11 8+8 d23 explicit, ×1.5, p4, shuffled → 406 / 5
- 2^26: s1 13+3 d16 ring, ×1, p4, shortest → 138 / 5; s2 13+3 d16 ring, ×1, p3, longest → 132 / 7; s3 8+8 d16 ring, ×2, p4, shortest → 138 / 5; s4 5+11 d17 explicit, ×1, p4, shortest → 32 / 5; s5 4+12 d25 explicit, ×1, p4, shuffled → 126 / 6; s6 11+5 d16 ring, ×0.75, p4, shuffled → 126 / 6; s7 11+5 d16 ring, ×0.75, p4, longest → 130 / 6; s8 6+10 d16 ring, ×1, p4, shortest → 138 / 6; s9 5+11 d17 explicit, ×1.5, p4, shortest → 138 / 7; s10 7+9 d16 ring, ×0.5, p3, longest → 132 / 5; s11 5+11 d29 explicit, ×0.75, p4, longest → 38 / 5

**Wall clock.** All 190 new dictionaries were generated in 24 minutes (01:23–01:47, twelve processes of two threads;
the pattern enumeration cached per size, cold 70–180 s per cache, the placement a few seconds except 2^24 with many
types and 2^25: 231–587 s single-threaded); the 209 map censuses and frame runs took 33 minutes (24 at a time, 150–
250 s a run). Three of the first attempt's designs had failed with colliding pads (two rotations of one pattern sharing
a position but serving two types); after the fix the rotations that share a position form one slot, seed 1 is still
byte-identical (sha256, 2^8 .. 2^26), and all 209 designs built and verified.

## 4. What the figure shows (`../figures/dictionary-size-seeds.png`)

- **Types designed.** The median over the 11 designs follows the shipped curve: 1 at 2^8–2^10, 3–8 at 2^11–2^14, 25
  and 38 at 2^16 and 2^17, 23–46 at 2^18–2^22, 11 at 2^23, 2,026 at 2^24, 394 at 2^25, 132 at 2^26. The interquartile
  ranges are narrow (within ±25 % of the median) except at 2^15 (1–5; seed 1 has 9), 2^18 (16–35), 2^24 (1,671–2,055)
  and 2^25 (366–510; seed 1 has 1,343). Seed 1 is at or above the upper quartile at 2^15, 2^18–2^21 and 2^25: the
  shipped approach (the best form, the shortest readings first, period cap 4) is the best of the eleven at those
  sizes, not a typical one. Section 3.3 shows what loses types: the period cap 3 (fewer pads), the three-command heads
  (longer heads, fewer safe spots), and at 2^25 every form but the shipped 13 + 3 (seed 4, with 9 + 7, matches it).
- **Alive at 2,000 on the frame.** Median 1 at 2^8–2^10, 3–5 at 2^11–2^14, 1 at 2^15, 10 at 2^16 and 2^17, 9, 6, 4,
  5, 3, 2 from 2^18 to 2^23, 38 at 2^24, 5–6 at 2^25–2^26. The shape of the single-design curve is the construction's
  shape, not an accident of one seed: a rise to about ten types alive by 2^16, a decline through 2^23 as the designs
  lose types, the one spike at 2^24, and little at 32 and 64 MB. Seed 1 lies above the interquartile range at 2^15,
  2^16 and 2^18–2^20 (14–16 alive against medians of 6–10), inside it elsewhere, and below it at 2^22 (1 against 3):
  the shipped dictionaries are among the richer designs where they have more types, and the "12–17 alive from 2^16 to
  2^20" of `dictionary-size.md` is a median of about 10 with an interquartile range of 4–15 over the construction.
- **Entropy** of the type shares: median 2.2 bits at 2^16–2^17, 1.5–1.8 at 2^18–2^20, 1.2 at 2^21–2^22, 4.6 at 2^24
  (IQR 3.8–5.5), 1.5 and 2.1 at 2^25–2^26; seed 1 above the range at 2^18–2^20 (2.7 bits).
- **Domains** at 2,000: medians 870 at 2^16–2^17, falling to 160–240 by 2^22–2^23, 2,054 at 2^24; seed 1's 2,079 at
  2^16 is the top of the 11 (IQR 693–1,241). Every design is frozen by turn 2,000 (block change medians 0.005–0.022).
- **Strays** (the map alone): median 29 % at 2^8 (one type, half the dictionary a block), 8 % at 2^9 and 2^13, under
  2.5 % from 2^14 on; the two seed-1 outliers of `dictionary-size.md` (16 % at 2^11, 11.5 % at 2^22) are outliers here
  too (medians 1.0 % and 1.8 %), and 2^13's seed 1 (0 %) is the exception the other way (median 8 %).

## 5. What 2^25 and 2^26 add

Nothing on the frame. With seed 1, 2^25 designs 1,343 types (4,093 distinct pads) and holds 9 alive at turn 2,000 with
58 % transients; 2^26 designs 138 (the pad supply: 250 distinct pads for 3,300 scheduled) and holds 5 alive with 95 %
transients; the medians over 11 designs are 5 and 6 alive, 83–86 % transients. The map alone is as good as ever
(transient 5.7 steps, strays ≤ 1 %), so the loss is the lattice's: with 25–26 of the cell's 128 bits selecting the
window, a crossover of two types lands almost anywhere in 32–64 MB of filler, and the funnel restarts; the domains
that form stay small. Generation: 267 s on four threads for 2^25 (165 s of it the single-threaded placement) and
116 s for 2^26; on two threads with the pattern cache 310 s and 75 s. The Pages workflow keeps regenerating 2^17 ..
2^24 (about 9 minutes on the runner); 2^25 would add about 8 more, so 2^25 and 2^26 are served locally only (the page
says so when their fetch fails). Memory: a 512² lattice with the 64 MB text and its buffers is about 90 MB in one
wasm32 memory; four page workers with the 2^26 dictionary take about 280 MB, plus the fetched text on the main
thread; headless Chrome reached ready with a clean console at 2^26 with four workers.

## 6. Caveats

- One lattice run per design (the lattice seed equal to the design seed), so the spread over designs includes the
  lattice's own seed variation (which `dictionary-size.md` found to be 1–3 types alive and 0.1–0.4 bits over three
  seeds at one design); 11 designs give a median and quartiles, not a distribution.
- The approach space is the construction's own knobs (form within 60 % of the best score, Gray share 0.5–2×, period
  cap 3 or 4, pattern order); other constructions (longer patterns, a second funnel stage, no letters in heads) are
  not in it. The approaches are drawn by the seed, so the eleven are not a designed experiment over the knobs: section
  3.3 lists them and the reader can see, for example, that every period-3 design at 2^20 has 18–24 types.
- The generation seconds in §3.1 are the placement, verification and census only; the pattern enumeration (70–180 s
  cold per size, head bytes and period cap) is cached and shared by the seeds. The census inside the design file
  draws its cells per worker chunk, so it differs with the worker count (the dictionary bytes do not); the map numbers
  here come from `scale-map.mjs`, which is worker-independent.
- 2^8 to 2^10 design one type whatever the seed; 2^15 designs one type in eight of eleven approaches (the 15-header-bit
  landing problem: only control-byte patterns land, 25 distinct pads with the shipped head).
- The 190 dictionaries of seeds 2–11 are under `../data/design-seeds/` (1.3 GB, git-ignored) and are not on the page.

