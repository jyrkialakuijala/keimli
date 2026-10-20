# Designed pair dictionary ca-pairbit22

pair mode 4 (bit2), 2 species of 8-cycles, V = 60000 (16 header bits), 61440 bytes; copies 4 + 10 + 13 + 5 at distance 34, transform 2; head 80 bits; Gray bits 5, 10, 11; 69 head bytes allowed.

| species | letter | reading (bits) | H0 | joint state 0 | its two cells | joint Hamming per step |
|---|---|---|---|---|---|---|
| A | `P` | 169 | 21257 | `PÂÊÊPPPPPPPPPPPPPPPPPPPPPP` | "$dBr\u0012DDDDDDDDDDD" "Ä!>>DDDDDDDDDDD" | 2 |
| B | `_` | 159 | 29189 | `_ÊÊQQQQQQQQQQQQQQQQQQQQQQ` | "\u0017dBr\u0012UUUUUUUUUUU" "#>>DDDDDDDDDDD" | 2 |

## Census (random pairs, roles alternating, 10000 pairs)

Joint on a designed cycle: A 85.2 %, B 0.9 %, none 13.9 %; within 8 turns 42.9 %; transient mean 9.8, p90 16, max 31.

