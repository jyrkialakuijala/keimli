# Designed pair dictionary ca-paircat3

pair mode 1 (concatenated), 3 species of 8-cycles, V = 60000 (16 header bits), 61440 bytes; copies 6 + 13 + 13 at distance 33; head 70 cell bits.

| species | letter | reading (bits) | H0 | state 0 (cell) | joint word of state 0 | Hamming per step |
|---|---|---|---|---|---|---|
| A | `7` | 64 | 43136 | `0 *#(?(?(1111111` | `0 *#(?(?(11111110 *#(?(?(1111111` | 2 |
| B | `?` | 64 | 41088 | `1 (#(?(?(2222222` | `1 (#(?(?(22222221 (#(?(?(2222222` | 2 |
| C | `;` | 64 | 32896 | `2  #(?(?(3333333` | `2  #(?(?(33333332  #(?(?(3333333` | 2 |

## Census (random pairs, roles alternating, 10000 pairs)

Both cells on one designed cycle: A 41.4 %, B 19.1 %, C 39.4 %, none 0.0 %; within 8 turns 81.7 %; transient mean 6.2, p90 10, max 26.

