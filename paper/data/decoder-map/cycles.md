# The decoder iterated on one cell: attractors

N = 10000 random cells per dictionary, V = 4096, skip 6, cap 4000 steps. A cycle is identified by its lexicographically smallest state. Transient = steps before the cycle is entered.

| dictionary | cycles found | cycle lengths (count) | largest basin % | transient mean | transient p90 | transient max | not settled |
|---|---|---|---|---|---|---|---|
| declaration | 7 | 3 (1), 6 (118), 9 (14), 22 (9), 67 (94), 154 (1687), 182 (8077) | 80.8 | 89.4 | 198 | 431 | 0 |
| don-quijote | 4 | 2 (1), 4 (1), 55 (6280), 64 (3718) | 62.8 | 82.4 | 145 | 273 | 0 |
| kalevala-1 | 55 | 3 (13), 8 (207), 9 (522), 20 (2), 41 (26), 77 (2762), 303 (6468) | 64.7 | 209.3 | 418 | 670 | 0 |
| ca-brotli-1 | 6 | 2 (7751), 3 (1), 4 (900), 15 (1348) | 77.5 | 25.7 | 50 | 92 | 0 |
| ca-brotli-9 | 2 | 1 (5), 14 (9995) | 100.0 | 13.8 | 25 | 56 | 0 |
| ca-brotli-13 | 4 | 1 (295), 9 (9324), 18 (381) | 93.2 | 24.5 | 46 | 75 | 0 |
| ca-swarm-a | 3 | 1 (23), 6 (9483), 8 (494) | 94.8 | 7.4 | 14 | 30 | 0 |
| ca-swarm-d | 4 | 1 (76), 3 (9392), 12 (532) | 93.9 | 18.0 | 40 | 71 | 0 |
| ca-swarm-f | 1 | 3 (10000) | 100.0 | 9.6 | 15 | 35 | 0 |
