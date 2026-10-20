# The codebook cycles coupled through the 4-neighbour vote

2026-10-20. The page's preset "Codebook cycles on pairs, no mixing" (the
codebook decoder, kind 45, on concatenated pairs of the 512-byte Codebook
search 5 dictionary, both entropy stages off) was a field of independent
pairs, each on its own short cycle: 100 % of cells periodic (periods 2 to
16, mean 8), 1 % distinct contents, no agreement between neighbours. The
author asked for something more interesting.

**Any coupling through the entropy stages destroys the cycles.** Swaps at
p = 0.001 (about one exchanged bit per cell every few turns) leave 11 % of
the cells periodic; at p = 0.003 none. The cross median at p = 0.005 keeps
every cell periodic but hardly couples (neighbour agreement 0.04); at
p = 0.02 a quarter of the cells are periodic and the rest wander. The
codebook's attractors were searched for isolated pairs and are fragile
against a single flipped bit.

**The vote partner couples without noise, and the field coarsens.** With
the Cells entry "Self and its 4-neighbour vote" the pair partner is the
neighbourhood's bit-plane vote; no bit is ever flipped at random, every
cell's next content is a function of itself and its four neighbours. The
cells are then mostly aperiodic, but neighbouring cells come to agree, and
the agreement grows with time (128², scratch run, agreement = share of
horizontal neighbours with identical content):

| codebook | joining | t = 50 | 200 | 800 | 2000 |
|---|---|---|---|---|---|
| 45, Codebook search 5 | concatenated | 0.01 | 0.01 | 0.02 | 0.05 |
| 45, Codebook search 5 | nibble | 0.01 | 0.03 | 0.11 | 0.52 |
| 45, Codebook search 5 | bit | 0.00 | 0.00 | 0.00 | 0.00 |
| 46, Codebook search 8 (bit codebook) | concatenated | 0.01 | 0.02 | 0.05 | 0.25 |
| 46, Codebook search 8 | nibble | 0.01 | 0.01 | 0.03 | 0.06 |

In the page the nibble-joined codebook 45 shows two phases, a striped
quiet one and a mottled active one, in domains that grow; the
concatenated bit codebook 46 shows two striped phases with smooth
boundaries, coarsening like a spinodal decomposition. The vertical
stripes inside a domain are a period-2 texture along x: with the vote's
ties going to the cell's own bit, a cell whose left and right neighbours
differ from it and whose up and down neighbours agree sees itself as its
partner, and such alternating columns are fixed points of the self-joined
decode. The two presets "Codebook cycles meeting their neighbours" and
"Bit codebook on the 4-neighbour vote" replace the old one (256², scale 2,
no mixing or settling; the flat twin is hidden since the frame is flat).
