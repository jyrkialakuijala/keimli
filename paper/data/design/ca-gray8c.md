# Designed dictionary ca-gray8c

8 species, V = 60000 (16 header bits), 61440 bytes, mode const, patterns "+#7" ";'/" "3#3" "'?/" "+" "3'" "'#" "/#", blocks 37124, 39040, 42116, 49412, 53516, 54404, 55432, 57472, bounds 7500, 15000, 22500, 30000, 37500, 45000, 52500, d = 17, tail Gray 1. Census: 10000 random cells, cap 4000.

| species | pattern | reading (bits) | H0 | state 0 | Hamming to next |
|---|---|---|---|---|---|
| A | `+#7` | 64 | 37124 | `0A$3$#D+#7+#7+#7` | 1 |
| B | `;'/` | 48 | 39040 | `1 &3$#D;'/;'/;'/` | 1 |
| C | `3#3` | 48 | 42116 | `2!)3$#D3#33#33#3` | 1 |
| D | `'?/` | 48 | 49412 | `3A03$#D'?/'?/'?/` | 1 |
| E | `+` | 48 | 53516 | `4C43$#D+++++++++` | 1 |
| F | `3'` | 62 | 54404 | `5!53$#D3'3'3'3'3` | 1 |
| G | `'#` | 64 | 55432 | `6"63$#D'#'#'#'#'` | 1 |
| H | `/#` | 64 | 57472 | `7 83$#D/#/#/#/#/` | 1 |

Planes constant along the cycle: 123 of 128 (48 are read by the decoder). Hamming between species (min, max over state pairs): {"AB":[17,20],"AC":[15,20],"AD":[25,26],"AE":[15,20],"AF":[18,21],"AG":[18,21],"AH":[20,23],"BC":[22,25],"BD":[22,25],"BE":[20,23],"BF":[19,24],"BG":[19,20],"BH":[17,18],"CD":[30,31],"CE":[24,29],"CF":[13,16],"CG":[19,22],"CH":[21,24],"DE":[20,21],"DF":[23,26],"DG":[21,24],"DH":[17,20],"EF":[23,26],"EG":[19,22],"EH":[17,20],"FG":[20,21],"FH":[24,25],"GH":[10,15]}.

Filler: the patterns tiled over the regions [[0,7500],[7500,15000],[15000,22500],[22500,30000],[30000,37500],[37500,45000],[45000,52500],[52500,60000]]; landing pads: A 56447..56453 (reads 48 bits, lands on off-cycle (head of state 0)) and 44223..44245 (reads 64 bits, lands on off-cycle (head wrong: "0a$3$#D3'3'3'0'3")) and 35967..35973 (reads 48 bits, lands on off-cycle (head of state 0)); B 48255..48261 (reads 48 bits, lands on off-cycle (head of state 0)) and 543..549 (reads 48 bits, lands on off-cycle (head of state 0)) and 40127..40133 (reads 48 bits, lands on off-cycle (head wrong: "1 &3$#d3'3'3'3'3")); C 52351..52357 (reads 48 bits, lands on off-cycle (head of state 0)) and 52415..52421 (reads 48 bits, lands on off-cycle (head of state 0)) and 36031..36037 (reads 48 bits, lands on off-cycle (head wrong: "2!)3$#d++++++2!)")); D 48319..48325 (reads 48 bits, lands on off-cycle (head wrong: "3a03$#d'#'#'#'#'")) and 40063..40069 (reads 48 bits, lands on off-cycle (head of state 0)) and 4639..4645 (reads 48 bits, lands on off-cycle (head of state 0)); E 44159..44165 (reads 48 bits, lands on off-cycle (head of state 0)); F 52367..52373 (reads 62 bits, lands on off-cycle (head wrong: "5!53$#d'#'#'#5!5")) and 40111..40117 (reads 48 bits, lands on state 0 of F); G 40047..40053 (reads 64 bits, lands on off-cycle (head of state 0)) and 35983..35989 (reads 62 bits, lands on off-cycle (head of state 0)); H 48207..48213 (reads 64 bits, lands on off-cycle (head of state 0)) and 36015..36021 (reads 48 bits, lands on off-cycle (head of state 0))

## Funnel

On a designed cycle after 1..8 steps from random cells: 0.0 %, 0.5 %, 17.3 %, 46.2 %, 64.4 %, 78.3 %, 85.8 %, 89.8 %. After one bit flip of a cycle state (8192 cases): return in 1.6 steps mean, p90 3, max 14, lost (> 100) 1, same species 85.4 %.

## Census

Shares (%): A 10.4, B 4.9, C 7.1, D 9.8, E 25.9, F 18.2, G 15.6, H 7.8, stray 0.20, unsettled 0. Transient mean 5.4, p90 8, max 38.

| cycle | length | basin | species |
|---|---|---|---|
| `"4C43$#D+++++++++"` | 8 | 25.92 % | E |
| `"5!53$#D3'3'3'3'3"` | 8 | 18.24 % | F |
| `"6\"63$#D'#'#'#'#'"` | 8 | 15.64 % | G |
| `"0A$3$#D+#7+#7+#7"` | 8 | 10.39 % | A |
| `"3A03$#D'?/'?/'?/"` | 8 | 9.78 % | D |
| `"7 83$#D/#/#/#/#/"` | 8 | 7.85 % | H |
| `"2!)3$#D3#33#33#3"` | 8 | 7.10 % | C |
| `"1 &3$#D;'/;'/;'/"` | 8 | 4.88 % | B |
| `"33#3333^33"` | 2 | 0.10 % | stray |
| `"\"óÉÈ\t\"óÉÈrd\t\"R"` | 9 | 0.08 % | stray |
| `"@@@@@@@@@+#\b 7+"` | 1 | 0.01 % | stray |
| `"@@@@@@@@@@@@@@@@"` | 1 | 0.01 % | stray |
