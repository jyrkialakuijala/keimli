# Designed pair dictionary ca-paircat6

pair mode 1 (concatenated), 6 species of 8-cycles, V = 60000 (16 header bits), 61440 bytes; copies 6 + 13 + 13 at distance 33; head 70 cell bits.

| species | letter | reading (bits) | H0 | state 0 (cell) | joint word of state 0 | Hamming per step |
|---|---|---|---|---|---|---|
| A | `/` | 80 | 39168 | `0@&#(?(?(1111111` | `0@&#(?(?(11111110@&#(?(?(1111111` | 2 |
| B | `+` | 80 | 53504 | `1@4#(?(?(2222222` | `1@4#(?(?(22222221@4#(?(?(2222222` | 2 |
| C | `;` | 64 | 35072 | `2@"#(?(?(3333333` | `2@"#(?(?(33333332@"#(?(?(3333333` | 2 |
| D | `'` | 96 | 57472 | `3 8#(?(?(4444444` | `3 8#(?(?(44444443 8#(?(?(4444444` | 2 |
| E | `7` | 64 | 37120 | `4@$#(?(?(5555555` | `4@$#(?(?(55555554@$#(?(?(5555555` | 2 |
| F | `?` | 64 | 51328 | `5 2#(?(?(6666666` | `5 2#(?(?(66666665 2#(?(?(6666666` | 2 |

## Census (random pairs, roles alternating, 10000 pairs)

Both cells on one designed cycle: A 25.9 %, B 8.5 %, C 9.0 %, D 13.5 %, E 24.3 %, F 18.7 %, none 0.0 %; within 8 turns 81.7 %; transient mean 6.4, p90 10, max 32.

