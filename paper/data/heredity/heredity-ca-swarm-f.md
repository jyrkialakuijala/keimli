<!-- provenance: paper/experiments/heredity.mjs (2afc69a700f6089a) dict=ca-swarm-f cread=4096 | commit 48f9653+dirty | wasm 90ec8c30bca92b5b | 2026-10-21T12:03:41.654Z -->
# Heredity: ca-swarm-f

## The map alone: every one-bit mutant of every state of each type, after 300 turns

| type | period | basin | mutants | repaired | converted to another type | new attractor | still transient | the mutant is itself on a cycle |
|---|---|---|---|---|---|---|---|---|
| #0 | 3 | 100.00 % | 384 | 100.0 % | 0.0 % | 0.0 % | 0.0 % | 0.0 % |

## The lattice: a 3 x 3 patch of a one-bit mutant in an in-phase domain of its parent, 64², 200 turns, 12 trials each

erased / persists (≤ 9 cells off the parent type) / spread (> 9) / domain lost (more than half the cells off)

| type | swap p \ median m | 0 | 0.25 | 0.5 | 1 |
|---|---|---|---|---|---|
| #0 (period 3) | 0 | 12/0/0/0 | 12/0/0/0 | 12/0/0/0 | 12/0/0/0 |
| #0 (period 3) | 0.1 | 10/0/0/2 | 9/1/0/2 | 11/0/1/0 | 12/0/0/0 |
| #0 (period 3) | 0.25 | 10/0/0/2 | 11/0/0/1 | 12/0/0/0 | 12/0/0/0 |
| #0 (period 3) | 0.5 | 11/0/0/1 | 11/0/0/1 | 12/0/0/0 | 12/0/0/0 |
