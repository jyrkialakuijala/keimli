# Designed dictionary ca-vote1-check: a cell with its 4-neighbour vote, bit-interleaved

pair mode 10 (self and vote, bit-interleaved), 1 species of 8-cycles, V = 60000 (16 header bits), 61440 bytes; copies 10 + 13 + 9 at distance 49, transform 0; head 68 joint bits; Gray header masks 0x30 0xc0 0xc00. Every word is the next state in its doubled form, so the cell gets it in either role; 64 cell byte values allowed.

| species | filler letter | cell letter | reading (bits) | H0 | cell state 0 | Hamming per step |
|---|---|---|---|---|---|---|
| A | `?` | 0x77 | 64 | 12288 | "\u0000Rr2\u0000\u0001\u0001\u0001\u0001\u0001\u0001\u0001\u0001\u0001\u0001\u0001" | 2 |

## Census (2000 random cells)

Vote equal to the cell (a synchronised start): on a designed cycle A 77.6 %, none 22.4 %; within 8 turns 74.8 %; transient mean 5.2, p90 7, max 13.
Random vote on the first turn, then equal: A 82.2 %, none 17.8 %; within 8 turns 80.0 %.
