# Designed pair dictionary ca-pairbyte4

pair mode 5 (byte), 4 species of 8-cycles, V = 60000 (16 header bits), 61440 bytes; copies 6 + 13 + 13 at distance 33, transform 2; head 70 bits; Gray bits 5, 6, 10; alphabet ` !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`{\|}~`.

| species | letter | reading (bits) | H0 | joint state 0 | its two cells | joint Hamming per step |
|---|---|---|---|---|---|---|
| A | `?` | 64 | 39168 | `0@&#(?(?(                       ` | "0&(((           " "@#??            " | 2 |
| B | `;` | 64 | 35072 | `0@"#(?(?(!!!!!!!!!!!!!!!!!!!!!!!` | "0\"(((!!!!!!!!!!!" "@#??!!!!!!!!!!!!" | 2 |
| C | `/` | 80 | 41216 | `0@(#(?(?("""""""""""""""""""""""` | "0((((\"\"\"\"\"\"\"\"\"\"\"" "@#??\"\"\"\"\"\"\"\"\"\"\"\"" | 2 |
| D | `7` | 64 | 43136 | `0 *#(?(?(#######################` | "0*(((###########" " #??############" | 2 |

## Census (random pairs, roles alternating, 10000 pairs)

Joint on a designed cycle: A 0.1 %, B 0.0 %, C 59.0 %, D 40.8 %, none 0.0 %; within 8 turns 87.0 %; transient mean 6.2, p90 9, max 21.

