# The decoder iterated on one cell: attractors

N = 5000 random cells per dictionary, V = 4096, skip 6, cap 4000 steps. A cycle is identified by its lexicographically smallest state. Transient = steps before the cycle is entered.

| dictionary | cycles found | cycle lengths (count) | largest basin % | transient mean | transient p90 | transient max | not settled |
|---|---|---|---|---|---|---|---|
| ca-swarm-f | 1 | 3 (5000) | 100.0 | 9.4 | 15 | 33 | 0 |
| ca-swarm-f-shuffle1 | 1 | 29 (5000) | 100.0 | 21.7 | 37 | 68 | 0 |
| ca-swarm-f-shuffle2 | 3 | 5 (13), 10 (2), 23 (4985) | 99.7 | 20.3 | 36 | 83 | 0 |
| ca-swarm-f-shuffle3 | 4 | 4 (3), 10 (2876), 19 (698), 38 (1423) | 57.5 | 26.8 | 54 | 95 | 0 |
| ca-swarm-f-wordshuffle1 | 1 | 3 (5000) | 100.0 | 10.1 | 17 | 39 | 0 |
| ca-swarm-f-reverse1 | 2 | 3 (4896), 8 (104) | 97.9 | 12.4 | 21 | 38 | 0 |
