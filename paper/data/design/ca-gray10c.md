# Designed dictionary ca-gray10c

10 species, V = 60000 (16 header bits), 61440 bytes, mode const, patterns "++'" "';" "?'?" "+3" "3'" "+/;" "'/" ";/3" "/+" "23", blocks 35972, 38144, 42124, 46220, 50444, 53380, 53508, 54408, 56452, 57472, bounds 6000, 12000, 18000, 24000, 30000, 36000, 42000, 48000, 54000, d = 17, tail Gray 1. Census: 10000 random cells, cap 4000.

| species | pattern | reading (bits) | H0 | state 0 | Hamming to next |
|---|---|---|---|---|---|
| A | `++'` | 64 | 35972 | `0!#3$#D++'++'++'` | 1 |
| B | `';` | 64 | 38144 | `1@%3$#D';';';';'` | 1 |
| C | `?'?` | 48 | 42124 | `2#)3$#D?'??'??'?` | 1 |
| D | `+3` | 48 | 46220 | `3#-3$#D+3+3+3+3+` | 1 |
| E | `3'` | 62 | 50444 | `4C13$#D3'3'3'3'3` | 1 |
| F | `+/;` | 48 | 53380 | `5!43$#D+/;+/;+/;` | 1 |
| G | `'/` | 64 | 53508 | `6A43$#D'/'/'/'/'` | 1 |
| H | `;/3` | 48 | 54408 | `7"53$#D;/3;/3;/3` | 1 |
| I | `/+` | 48 | 56452 | `8!73$#D/+/+/+/+/` | 1 |
| J | `23` | 60 | 57472 | `9 83$#D232323232` | 1 |

Planes constant along the cycle: 123 of 128 (48 are read by the decoder).

Filler: the patterns tiled over the regions [[0,6000],[6000,12000],[12000,18000],[18000,24000],[24000,30000],[30000,36000],[36000,42000],[42000,48000],[48000,54000],[54000,60000]]; landing pads: A 40063..40069 (reads 64 bits, lands on off-cycle (head of state 0)) and 44159..44165 (reads 48 bits, lands on off-cycle (head of state 0)) and 44159..44165 (reads 64 bits, lands on off-cycle (head of state 0)); B 40143..40149 (reads 48 bits, lands on off-cycle (head of state 0)) and 527..533 (reads 64 bits, lands on off-cycle (head wrong: "1@%3$#d++'++'++'")); C 4639..4645 (reads 48 bits, lands on off-cycle (head of state 0)) and 4703..4709 (reads 48 bits, lands on off-cycle (head wrong: "2#)3$#d'++'++'++")) and 40127..40133 (reads 48 bits, lands on off-cycle (head wrong: "2#)3$#d'/'/'/'/'")); D 44191..44197 (reads 48 bits, lands on off-cycle (head of state 0)) and 52383..52389 (reads 48 bits, lands on off-cycle (head wrong: "3#-3$#d/+/+/+3#-")); E 52367..52373 (reads 62 bits, lands on off-cycle (head wrong: "4c13$#d/+/+/+4c1")) and 40111..40117 (reads 48 bits, lands on off-cycle (head of state 0)); F 543..549 (reads 48 bits, lands on off-cycle (head of state 0)) and 44223..44229 (reads 48 bits, lands on off-cycle (head wrong: "5!43$#d/33;/3;/3")) and 48255..48261 (reads 48 bits, lands on off-cycle (head of state 0)); G 40095..40101 (reads 48 bits, lands on state 0 of G) and 48223..48229 (reads 64 bits, lands on off-cycle (head of state 0)); H 52351..52357 (reads 48 bits, lands on off-cycle (head of state 0)) and 607..613 (reads 48 bits, lands on off-cycle (head wrong: "7\"53$#d'++'++'++")) and 48319..48325 (reads 48 bits, lands on off-cycle (head wrong: "7\"53$#d/+/+/+7\"5")); I 48239..48245 (reads 48 bits, lands on state 0 of I) and 44175..44181 (reads 48 bits, lands on off-cycle (head of state 0)); J 51395..51401 (reads 46 bits, lands on off-cycle (head wrong: "9 83$#d/+9 83$#d")) and 52408..52417 (reads 60 bits, lands on off-cycle (head wrong: "9 83$#d/+/+/+9 8"))

## Funnel

On a designed cycle after 1..8 steps from random cells: 0.0 %, 0.9 %, 19.5 %, 47.1 %, 67.3 %, 80.8 %, 87.8 %, 91.9 %. After one bit flip of a cycle state (10240 cases): return in 1.6 steps mean, p90 3, max 18, lost (> 100) 0, same species 85.3 %.

## Census

Shares (%): A 17.5, B 2.8, C 3.3, D 5.5, E 5.8, F 9.6, G 16.9, H 11.5, I 22.9, J 4.1, stray 0.03, unsettled 0. Transient mean 5.3, p90 8, max 24.

| cycle | length | basin | species |
|---|---|---|---|
| `"8!73$#D/+/+/+/+/"` | 8 | 22.87 % | I |
| `"0!#3$#D++'++'++'"` | 8 | 17.53 % | A |
| `"6A43$#D'/'/'/'/'"` | 8 | 16.87 % | G |
| `"7\"53$#D;/3;/3;/3"` | 8 | 11.54 % | H |
| `"5!43$#D+/;+/;+/;"` | 8 | 9.61 % | F |
| `"4C13$#D3'3'3'3'3"` | 8 | 5.82 % | E |
| `"3#-3$#D+3+3+3+3+"` | 8 | 5.50 % | D |
| `"9 83$#D232323232"` | 8 | 4.09 % | J |
| `"2#)3$#D?'??'??'?"` | 8 | 3.34 % | C |
| `"1@%3$#D';';';';'"` | 8 | 2.80 % | B |
| `"ò²òÊËÊ+/+/+/ò²Ê+"` | 1 | 0.02 % | stray |
| `"@@@@@@@@@@@@@@@@"` | 1 | 0.01 % | stray |
