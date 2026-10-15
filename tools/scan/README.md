# Offset scan

Tools that look for "interesting" LZ cursor offsets: ones where, with the
page defaults (128 × 128, swap p 0 → 1 across x, median p 0 → 1 down y, 3 passes
of the 3 × 3 neighbourhood, LZ changer with N = 3, random start), a frozen floor
forms and isolated active pixels keep appearing in it and moving about.
Run `./build.sh` first; all scripts read `build/keimli.wasm`.

- `orbits.mjs FROM TO STEP [K] [MAXITER]` – the decode map on its own: for K
  random pixels, iterate decode until the state repeats; prints per offset how
  many pixels reach a fixed point, the mean transient, cycle lengths and the
  number of attractors. Offsets with a dominant fixed point are ten times more
  likely to produce dancers than the rest, so this is the cheap prefilter.
- `lattice5.mjs TURNS OFFSET...` – the full lattice for TURNS turns. Over the
  last 300 turns: stone (pixels periodic in place with period ≤ 16; frozen =
  period 1), defects (non-stone pixels with ≥ 3 stone 4-neighbours), defects per
  1000 stone pixels (perK), the share still a defect within one pixel next turn
  (alive), the share of those that moved (dance), and the mean 8-connected
  defect cluster size. The dancer score is perK × alive × dance.
- `snap2.mjs TURNS OFFSET...` – after TURNS turns writes `snap_OFFSET.png` (the
  byte-colour view averaged over the last 8 frames, 2 ×) and `act_OFFSET.png`
  (how many of the last 16 turns changed each pixel).
- `montage.mjs COLS OUT.png FILES...` – tiles snapshots (`TILE=256` for the 2 ×
  ones).

Example: `node tools/scan/lattice5.mjs 2000 2494 1084 0 1` and
`node tools/scan/snap2.mjs 3000 2494`.
