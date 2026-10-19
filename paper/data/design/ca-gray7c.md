# Designed dictionary ca-gray7c

7 species, V = 60000 (16 header bits), 61440 bytes, mode const, patterns "+#7" "3#3" "'?/" "+" "3'" "'#" "/#", blocks 37124, 42116, 49412, 53516, 54404, 55432, 57472, bounds 8571, 17143, 25714, 34286, 42857, 51429, d = 17, tail Gray 1. Census: 10000 random cells, cap 4000.

| species | pattern | reading (bits) | H0 | state 0 | Hamming to next |
|---|---|---|---|---|---|
| A | `+#7` | 64 | 37124 | `0A$3$#D+#7+#7+#7` | 1 |
| B | `3#3` | 48 | 42116 | `1!)3$#D3#33#33#3` | 1 |
| C | `'?/` | 48 | 49412 | `2A03$#D'?/'?/'?/` | 1 |
| D | `+` | 48 | 53516 | `3C43$#D+++++++++` | 1 |
| E | `3'` | 62 | 54404 | `4!53$#D3'3'3'3'3` | 1 |
| F | `'#` | 64 | 55432 | `5"63$#D'#'#'#'#'` | 1 |
| G | `/#` | 64 | 57472 | `6 83$#D/#/#/#/#/` | 1 |

Planes constant along the cycle: 123 of 128 (48 are read by the decoder). Hamming between species (min, max over state pairs): {"AB":[15,20],"AC":[24,25],"AD":[16,21],"AE":[17,20],"AF":[18,21],"AG":[19,22],"BC":[31,32],"BD":[23,28],"BE":[12,15],"BF":[19,22],"BG":[22,25],"CD":[18,19],"CE":[23,26],"CF":[22,25],"CG":[17,20],"DE":[25,28],"DF":[20,23],"DG":[17,20],"EF":[19,20],"EG":[24,25],"FG":[11,16]}.

Filler: the patterns tiled over the regions [[0,8571],[8571,17143],[17143,25714],[25714,34286],[34286,42857],[42857,51429],[51429,60000]]; landing pads: A 56447..56453 (reads 48 bits, lands on off-cycle (head of state 0)) and 44223..44245 (reads 64 bits, lands on off-cycle (head wrong: "0a$3$#D#'#'#'0'#")) and 35967..35973 (reads 48 bits, lands on off-cycle (head of state 0)); B 52351..52357 (reads 48 bits, lands on off-cycle (head of state 0)) and 52415..52421 (reads 48 bits, lands on off-cycle (head of state 0)) and 36031..36037 (reads 48 bits, lands on off-cycle (head wrong: "1!)3$#d3'3'3'1!)")); C 48319..48325 (reads 48 bits, lands on off-cycle (head wrong: "2a03$#d#'#'#'#'#")) and 40063..40069 (reads 48 bits, lands on off-cycle (head of state 0)) and 4639..4645 (reads 48 bits, lands on off-cycle (head of state 0)); D 44159..44165 (reads 48 bits, lands on off-cycle (head of state 0)); E 52367..52373 (reads 62 bits, lands on off-cycle (head wrong: "4!53$#d#/#/#/4!5")) and 40111..40117 (reads 48 bits, lands on state 0 of E); F 40047..40053 (reads 64 bits, lands on off-cycle (head of state 0)) and 35983..35989 (reads 62 bits, lands on off-cycle (head of state 0)); G 48207..48213 (reads 64 bits, lands on off-cycle (head of state 0)) and 36015..36021 (reads 48 bits, lands on off-cycle (head of state 0))

## Funnel

On a designed cycle after 1..8 steps from random cells: 0.0 %, 0.6 %, 17.2 %, 49.1 %, 68.1 %, 79.7 %, 85.8 %, 89.9 %. After one bit flip of a cycle state (7168 cases): return in 1.6 steps mean, p90 3, max 18, lost (> 100) 0, same species 85.1 %.

## Census

Shares (%): A 10.2, B 9.3, C 6.5, D 6.6, E 29.9, F 23.5, G 13.7, stray 0.25, unsettled 0. Transient mean 5.3, p90 8, max 21.

| cycle | length | basin | species |
|---|---|---|---|
| `"4!53$#D3'3'3'3'3"` | 8 | 29.92 % | E |
| `"5\"63$#D'#'#'#'#'"` | 8 | 23.54 % | F |
| `"6 83$#D/#/#/#/#/"` | 8 | 13.66 % | G |
| `"0A$3$#D+#7+#7+#7"` | 8 | 10.21 % | A |
| `"1!)3$#D3#33#33#3"` | 8 | 9.29 % | B |
| `"3C43$#D+++++++++"` | 8 | 6.64 % | D |
| `"2A03$#D'?/'?/'?/"` | 8 | 6.49 % | C |
| `"?/'?/?/'?/"` | 1 | 0.24 % | stray |
| `"@@@@@@@@@@@@@@@@"` | 1 | 0.01 % | stray |
