# Designed dictionary ca-vote1: a cell with its 4-neighbour vote, bit-interleaved

pair mode 10 (self and vote, bit-interleaved), 1 species of 8-cycles, V = 60000 (16 header bits), 61440 bytes; copies 10 + 13 + 9 at distance 49, transform 0; head 68 joint bits; Gray pairs at header bits 4,5 6,7 10,11. Every word is the next state with its bits doubled, so the cell gets it in either role; word bytes are '0' '3' '<' '?'.

| species | filler letter | cell letter | reading (bits) | H0 | cell state 0 | Hamming per step |
|---|---|---|---|---|---|---|
| A | `?` | 0x77 | 64 | 12288 | "\u0000Rr2@DDDDDDDDDDD" | 2 |

## Census (10000 random cells)

Vote equal to the cell (a synchronised start): on a designed cycle A 76.6 %, none 23.4 %; within 8 turns 73.2 %; transient mean 5.2, p90 7, max 15.
Random vote on the first turn, then equal: A 82.0 %, none 18.0 %; within 8 turns 80.0 %.
