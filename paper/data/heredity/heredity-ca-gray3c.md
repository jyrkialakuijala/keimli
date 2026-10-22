<!-- provenance: paper/experiments/heredity.mjs (2afc69a700f6089a) dict=ca-gray3c cread=4096 | commit 48f9653+dirty | wasm 90ec8c30bca92b5b | 2026-10-21T12:05:51.852Z -->
# Heredity: ca-gray3c

## The map alone: every one-bit mutant of every state of each type, after 300 turns

| type | period | basin | mutants | repaired | converted to another type | new attractor | still transient | the mutant is itself on a cycle |
|---|---|---|---|---|---|---|---|---|
| #0 | 8 | 42.59 % | 1024 | 99.2 % | 0.8 % | 0.0 % | 0.0 % | 0.0 % |
| #1 | 8 | 30.59 % | 1024 | 90.8 % | 9.2 % | 0.0 % | 0.0 % | 0.0 % |
| #2 | 8 | 26.82 % | 1024 | 93.2 % | 6.8 % | 0.0 % | 0.0 % | 0.0 % |

## The lattice: a 3 x 3 patch of a one-bit mutant in an in-phase domain of its parent, 64², 200 turns, 12 trials each

erased / persists (≤ 9 cells off the parent type) / spread (> 9) / domain lost (more than half the cells off)

| type | swap p \ median m | 0 | 0.25 | 0.5 | 1 |
|---|---|---|---|---|---|
| #0 (period 8) | 0 | 12/0/0/0 | 11/1/0/0 | 12/0/0/0 | 12/0/0/0 |
| #0 (period 8) | 0.1 | 11/0/0/1 | 12/0/0/0 | 12/0/0/0 | 12/0/0/0 |
| #0 (period 8) | 0.25 | 9/0/0/3 | 9/0/0/3 | 11/0/0/1 | 12/0/0/0 |
| #0 (period 8) | 0.5 | 10/0/0/2 | 9/0/0/3 | 11/0/0/1 | 12/0/0/0 |
| #1 (period 8) | 0 | 12/0/0/0 | 11/1/0/0 | 10/2/0/0 | 12/0/0/0 |
| #1 (period 8) | 0.1 | 10/1/0/1 | 11/0/0/1 | 10/0/0/2 | 12/0/0/0 |
| #1 (period 8) | 0.25 | 10/0/0/2 | 11/0/0/1 | 11/0/0/1 | 12/0/0/0 |
| #1 (period 8) | 0.5 | 10/0/0/2 | 11/0/0/1 | 12/0/0/0 | 12/0/0/0 |
| #2 (period 8) | 0 | 11/1/0/0 | 9/3/0/0 | 11/1/0/0 | 12/0/0/0 |
| #2 (period 8) | 0.1 | 10/0/0/2 | 11/0/0/1 | 11/0/0/1 | 12/0/0/0 |
| #2 (period 8) | 0.25 | 7/2/0/3 | 8/0/0/4 | 10/0/0/2 | 12/0/0/0 |
| #2 (period 8) | 0.5 | 9/0/0/3 | 12/0/0/0 | 10/0/0/2 | 12/0/0/0 |
