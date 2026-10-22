# Designed dictionary ca-votebyte2: a cell with its 4-neighbour vote, byte-interleaved

pair mode 13 (self and vote, byte-interleaved), 2 species of 8-cycles, V = 60000 (16 header bits), 61440 bytes. Every word is the next state in its doubled form, so the cell gets it in either role; 74 cell byte values allowed. Heads found by enumerating 4 command tails.

| species | head (copies, distance, transform) | head bits | Gray bits of cell byte 0 | filler letter | cell letter | reading (bits) | cell state 0 | Hamming per step |
|---|---|---|---|---|---|---|---|---|
| A | 8e+12e+12e d 45 tf 3 | 70 | 3 4 5 | `;` | 0x3b | 64 | "\u0003+;;{\u0001\u0001\u0001\u0001\u0001\u0001\u0001\u0001\u0001\u0001\u0001" | 2 |
| B | 6e+13e+13e d 61 tf 3 | 70 | 3 4 5 | `/` | 0x2f | 80 | "\u0006#??\u0001\u0001\u0001\u0001\u0001\u0001\u0001\u0001\u0001\u0001\u0001" | 2 |

## Census (5000 random cells)

Vote equal to the cell (a synchronised start): on a designed cycle A 54.3 %, B 45.5 %, none 0.2 %; within 8 turns 92.8 %; transient mean 5.9, p90 8, max 20.
Random vote on the first turn, then equal: A 53.8 %, B 46.1 %, none 0.0 %; within 8 turns 92.3 %.
