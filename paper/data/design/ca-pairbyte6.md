# Designed pair dictionary ca-pairbyte6

pair mode 5 (byte), 6 species of 8-cycles, V = 60000 (16 header bits), 61440 bytes; copies 6 + 13 + 13 at distance 33, transform 2; head 70 bits; Gray bits 5, 6, 10; alphabet ` !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`{\|}~`.

| species | letter | reading (bits) | H0 | joint state 0 | its two cells | joint Hamming per step |
|---|---|---|---|---|---|---|
| A | `'` | 96 | 57600 | `0@8#(?(?(                       ` | "08(((           " "@#??            " | 2 |
| B | `;` | 64 | 51456 | `0@2#(?(?(!!!!!!!!!!!!!!!!!!!!!!!` | "02(((!!!!!!!!!!!" "@#??!!!!!!!!!!!!" | 2 |
| C | `?` | 64 | 34944 | `0 "#(?(?("""""""""""""""""""""""` | "0\"(((\"\"\"\"\"\"\"\"\"\"\"" " #??\"\"\"\"\"\"\"\"\"\"\"\"" | 2 |
| D | `7` | 64 | 55552 | `0@6#(?(?(#######################` | "06(((###########" "@#??############" | 2 |
| E | `+` | 80 | 51328 | `0 2#(?(?($$$$$$$$$$$$$$$$$$$$$$$` | "02((($$$$$$$$$$$" " #??$$$$$$$$$$$$" | 2 |
| F | `/` | 80 | 57472 | `0 8#(?(?(%%%%%%%%%%%%%%%%%%%%%%%` | "08(((%%%%%%%%%%%" " #??%%%%%%%%%%%%" | 2 |

## Census (random pairs, roles alternating, 10000 pairs)

Joint on a designed cycle: A 31.1 %, B 0.0 %, C 3.4 %, D 0.1 %, E 43.2 %, F 21.7 %, none 0.4 %; within 8 turns 91.0 %; transient mean 5.6, p90 8, max 32.

