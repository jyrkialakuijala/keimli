# Designed pair dictionary ca-pairbit1

pair mode 2 (bit), 1 species of 8-cycles, V = 60000 (16 header bits), 61440 bytes; copies 10 + 10 + 12 at distance 33, transform 3; head 70 bits; Gray bits 5, 10, 11; alphabet `0123456789:;<=>?`.

| species | letter | reading (bits) | H0 | joint state 0 | its two cells | joint Hamming per step |
|---|---|---|---|---|---|---|
| A | `?` | 64 | 53440 | `0043838;811111111111111111111111` | "DVTTTUUUUUUUUUUU" "DTVvFDDDDDDDDDDD" | 2 |

## Census (random pairs, roles alternating, 10000 pairs)

Joint on a designed cycle: A 91.5 %, none 8.6 %; within 8 turns 85.2 %; transient mean 4.9, p90 7, max 18.

