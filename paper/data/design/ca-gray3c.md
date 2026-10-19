# Designed dictionary ca-gray3c

mode const, d = 16, tail Gray 1, filler search 0 iterations on 400 cells (score 1.377). Census: 10000 random cells, cap 4000.

| species | H0 | states (k: position, header, text, Hamming to next) |
|---|---|---|
| A | 128 | 0: 176, 128, `0 0?0@1111111111`, 2<br>1: 112, 144, `0$0?0@5111111111`, 2<br>2: 128, 176, `0,0?0@5511111111`, 2<br>3: 160, 160, `0(0?0@1511111111`, 2<br>4: 144, 224, `080?0@1551111111`, 2<br>5: 208, 240, `0<0?0@5551111111`, 2<br>6: 224, 208, `040?0@5151111111`, 2<br>7: 192, 192, `000?0@1151111111`, 2 |
| B | 2304 | 0: 2352, 2304, `1@2?0@2222222222`, 2<br>1: 2288, 2320, `1D2?0@6222222222`, 2<br>2: 2304, 2352, `1L2?0@6622222222`, 2<br>3: 2336, 2336, `1H2?0@2622222222`, 2<br>4: 2320, 2400, `1X2?0@2662222222`, 2<br>5: 2384, 2416, `1\2?0@6662222222`, 2<br>6: 2400, 2384, `1T2?0@6262222222`, 2<br>7: 2368, 2368, `1P2?0@2262222222`, 2 |
| C | 3328 | 0: 3376, 3328, `2@3?0@3333333333`, 2<br>1: 3312, 3344, `2D3?0@7333333333`, 2<br>2: 3328, 3376, `2L3?0@7733333333`, 2<br>3: 3360, 3360, `2H3?0@3733333333`, 2<br>4: 3344, 3424, `2X3?0@3773333333`, 2<br>5: 3408, 3440, `2\3?0@7773333333`, 2<br>6: 3424, 3408, `2T3?0@7373333333`, 2<br>7: 3392, 3392, `2P3?0@3373333333`, 2 |

Planes constant along the cycle: 122, 122, 122 of 128 (46 are read by the decoder). Hamming between species (min, max over state pairs): {"AB":[24,30],"AC":[15,21],"BC":[13,19]}.

Filler: constant bytes "1", "2", "3" per region [[0,1365],[1365,2730],[2730,4096]]; landing pads A: 1211..1219 (9 bytes, all-X reads 72 bits, src DDDDDDDDDSLSSLLL, lands on off-cycle "0 0?0@1110L 0ÄÄÄ" (head of state 0)); B: 2235..2247 (13 bytes, all-X reads 60 bits, src DDDDDDDDDDDDDSSS, lands on off-cycle "1@2?0@22222221@2" (head of state 0)); C: 3263..3275 (13 bytes, all-X reads 44 bits, src DDDDDDDDDDDDDSSS, lands on off-cycle "2@3?0@33333332@3" (head of state 0))

## Funnel

On a designed cycle after 1..8 steps from random cells: 0.0 %, 1.1 %, 20.1 %, 48.2 %, 66.4 %, 77.5 %, 85.1 %, 93.4 %. After one bit flip of a cycle state (3072 cases): return in 1.5 steps mean, p90 3, max 10, lost (> 100) 0, same species 94.4 %.

## Census

Shares: A 42.9 %, B 30.3 %, C 26.8 %, stray 0.00 %, unsettled 0. Transient mean 5.1, p90 8, max 17 (A 5.8, B 4.9, C 4.4).

| cycle | length | basin | species |
|---|---|---|---|
| `"0 0?0@1111111111"` | 8 | 42.91 % | A |
| `"1@2?0@2222222222"` | 8 | 30.34 % | B |
| `"2@3?0@3333333333"` | 8 | 26.75 % | C |
