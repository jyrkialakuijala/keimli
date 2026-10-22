<!-- provenance: paper/experiments/closure.mjs (de664a567cd4e3c6) dict=ca-swarm-f cread=4096 | commit 48f9653+dirty | wasm 90ec8c30bca92b5b | 2026-10-21T12:41:36.537Z -->
# Closure: ca-swarm-f

Types: #0 3-cycle (basin 100.00 %)

A random state of A crossed with a random state of B (each differing bit from B with probability r), then f applied 1 or 8 times: the share landing on A, on B, and on either (closed).

| A × B | r | after 1 step: on A / on B / closed | after 8 steps: on A / on B / closed |
|---|---|---|---|
| #0 × #0 | 0.05 | 52 / 0 / **52 %** | 91 / 0 / **91 %** |
| #0 × #0 | 0.25 | 34 / 0 / **34 %** | 78 / 0 / **78 %** |
| #0 × #0 | 0.5 | 33 / 0 / **33 %** | 76 / 0 / **76 %** |

| type | majority closure: maj of three random-phase states, then f once / 8 times |
|---|---|
| #0 | 77 % / 100 % |
