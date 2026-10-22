# The paper in ten sentences, twenty passes

2026-10-22. Each pass keeps ten sentences, one per section of OUTLINE.md, and changes one thing, named above it.
Terms as in TERMS.md. "[to show]" marks the one claim whose experiment (A9) has not run.

## 1. First draft

1. Keimli is a cellular automaton whose cells are 128-bit strings and whose local rule is a dictionary decompressor.
2. We ask what persists in such a lattice when neighbours exchange bits and settle by majority, and whether anything inherits.
3. The decoder's map has an exactly countable attractor set: 68,964,123 fixed points in 15,693 families and one 3-cycle holding 99.995 % of the basin.
4. The structure is carried by the dictionary's words: a random map with the same contraction, or a byte-shuffled dictionary, does not reproduce it, while a word-shuffled one does.
5. Attractors can be built into the dictionary by construction and proved closed under any bitwise combination of their states.
6. On the lattice, uniform domains are invariant, open cycles dissolve when their phases are disordered, closed types hold, and the leading fixed point fills what dissolves and invades what does not.
7. This is nucleation: a critical radius of 5–8 cells against an ordered sea, a constant wall speed, and spontaneous starts in disordered seas at 10⁻⁶ to 10⁻⁴ per cell and turn.
8. The types that win are crystals, not replicators: none of 2,944 one-bit variants is inherited.
9. BFF's loops inherit 80–85 % of variants through bytes copied unread, and a decoder type given one copy command and a free tail does the same [to show].
10. Self-maintenance and heredity are thus two separate properties of a map, and a decompressor as a rule has the first and can be designed to have the second.

## 2. Say in the first sentence what the rule does to a cell, not what the system is called

1. A cellular automaton is built whose local rule is a dictionary decompressor: each 128-bit cell is read as a compressed stream and replaced by what it decodes to.
2. We ask what persists in such a lattice when neighbours exchange bits and settle by majority, and whether anything inherits.
3. The decoder's map has an exactly countable attractor set: 68,964,123 fixed points in 15,693 families and one 3-cycle holding 99.995 % of the basin.
4. The structure is carried by the dictionary's words: a random map with the same contraction, or a byte-shuffled dictionary, does not reproduce it, while a word-shuffled one does.
5. Attractors can be built into the dictionary by construction and proved closed under any bitwise combination of their states.
6. On the lattice, uniform domains are invariant, open cycles dissolve when their phases are disordered, closed types hold, and the leading fixed point fills what dissolves and invades what does not.
7. This is nucleation: a critical radius of 5–8 cells against an ordered sea, a constant wall speed, and spontaneous starts in disordered seas at 10⁻⁶ to 10⁻⁴ per cell and turn.
8. The types that win are crystals, not replicators: none of 2,944 one-bit variants is inherited.
9. BFF's loops inherit 80–85 % of variants through bytes copied unread, and a decoder type given one copy command and a free tail does the same [to show].
10. Self-maintenance and heredity are thus two separate properties of a map, and a decompressor as a rule has the first and can be designed to have the second.

## 3. Put the two axes into sentence 2, so the reader knows what is being measured

1. A cellular automaton is built whose local rule is a dictionary decompressor: each 128-bit cell is read as a compressed stream and replaced by what it decodes to.
2. Two properties of the rule are measured: which of its attractors persist when neighbours exchange bits and settle by majority, and whether any of them pass on a change.
3. The decoder's map has an exactly countable attractor set: 68,964,123 fixed points in 15,693 families and one 3-cycle holding 99.995 % of the basin.
4. The structure is carried by the dictionary's words: a random map with the same contraction, or a byte-shuffled dictionary, does not reproduce it, while a word-shuffled one does.
5. Attractors can be built into the dictionary by construction and proved closed under any bitwise combination of their states.
6. On the lattice, uniform domains are invariant, open cycles dissolve when their phases are disordered, closed types hold, and the leading fixed point fills what dissolves and invades what does not.
7. This is nucleation: a critical radius of 5–8 cells against an ordered sea, a constant wall speed, and spontaneous starts in disordered seas at 10⁻⁶ to 10⁻⁴ per cell and turn.
8. The types that win are crystals, not replicators: none of 2,944 one-bit variants is inherited.
9. BFF's loops inherit 80–85 % of variants through bytes copied unread, and a decoder type given one copy command and a free tail does the same [to show].
10. Self-maintenance and heredity are thus two separate properties of a map, and a decompressor as a rule has the first and can be designed to have the second.

## 4. Define "closed" where it is first used (sentence 5), since sentence 6 depends on it

1. A cellular automaton is built whose local rule is a dictionary decompressor: each 128-bit cell is read as a compressed stream and replaced by what it decodes to.
2. Two properties of the rule are measured: which of its attractors persist when neighbours exchange bits and settle by majority, and whether any of them pass on a change.
3. The decoder's map has an exactly countable attractor set: 68,964,123 fixed points in 15,693 families and one 3-cycle holding 99.995 % of the basin.
4. The structure is carried by the dictionary's words: a random map with the same contraction, or a byte-shuffled dictionary, does not reproduce it, while a word-shuffled one does.
5. Attractors can also be built into the dictionary, and the built ones are provably closed: any bitwise combination of their states is mapped back onto them, which fixed points are trivially and ordinary cycles are not.
6. On the lattice, uniform domains are invariant, open cycles dissolve when their phases are disordered, closed types hold, and the leading fixed point fills what dissolves and invades what does not.
7. This is nucleation: a critical radius of 5–8 cells against an ordered sea, a constant wall speed, and spontaneous starts in disordered seas at 10⁻⁶ to 10⁻⁴ per cell and turn.
8. The types that win are crystals, not replicators: none of 2,944 one-bit variants is inherited.
9. BFF's loops inherit 80–85 % of variants through bytes copied unread, and a decoder type given one copy command and a free tail does the same [to show].
10. Self-maintenance and heredity are thus two separate properties of a map, and a decompressor as a rule has the first and can be designed to have the second.

## 5. Sentence 6 carries the central result; give it the number that makes it a result

1. A cellular automaton is built whose local rule is a dictionary decompressor: each 128-bit cell is read as a compressed stream and replaced by what it decodes to.
2. Two properties of the rule are measured: which of its attractors persist when neighbours exchange bits and settle by majority, and whether any of them pass on a change.
3. The decoder's map has an exactly countable attractor set: 68,964,123 fixed points in 15,693 families and one 3-cycle holding 99.995 % of the basin.
4. The structure is carried by the dictionary's words: a random map with the same contraction, or a byte-shuffled dictionary, does not reproduce it, while a word-shuffled one does.
5. Attractors can also be built into the dictionary, and the built ones are provably closed: any bitwise combination of their states is mapped back onto them, which fixed points are trivially and ordinary cycles are not.
6. On the lattice the basin does not pick the winner: a fixed point with 0.3 % of the basin takes the lattice from a cycle with 99.7 % in 99 of 100 seeds, because uniform domains are invariant, disordered open domains dissolve, and the closed type fills what dissolves and invades what does not.
7. This is nucleation: a critical radius of 5–8 cells against an ordered sea, a constant wall speed, and spontaneous starts in disordered seas at 10⁻⁶ to 10⁻⁴ per cell and turn.
8. The types that win are crystals, not replicators: none of 2,944 one-bit variants is inherited.
9. BFF's loops inherit 80–85 % of variants through bytes copied unread, and a decoder type given one copy command and a free tail does the same [to show].
10. Self-maintenance and heredity are thus two separate properties of a map, and a decompressor as a rule has the first and can be designed to have the second.

## 6. Sentence 7: say what nucleation is before saying it happens

1. A cellular automaton is built whose local rule is a dictionary decompressor: each 128-bit cell is read as a compressed stream and replaced by what it decodes to.
2. Two properties of the rule are measured: which of its attractors persist when neighbours exchange bits and settle by majority, and whether any of them pass on a change.
3. The decoder's map has an exactly countable attractor set: 68,964,123 fixed points in 15,693 families and one 3-cycle holding 99.995 % of the basin.
4. The structure is carried by the dictionary's words: a random map with the same contraction, or a byte-shuffled dictionary, does not reproduce it, while a word-shuffled one does.
5. Attractors can also be built into the dictionary, and the built ones are provably closed: any bitwise combination of their states is mapped back onto them, which fixed points are trivially and ordinary cycles are not.
6. On the lattice the basin does not pick the winner: a fixed point with 0.3 % of the basin takes the lattice from a cycle with 99.7 % in 99 of 100 seeds, because uniform domains are invariant, disordered open domains dissolve, and the closed type fills what dissolves and invades what does not.
7. The closed type nucleates in the sense of a critical radius (5–8 cells against an ordered domain, a wall then advancing at a constant 0.06–0.13 cells a turn) and of rare spontaneous starts (10⁻⁶ to 10⁻⁴ per cell and turn in a disordered domain, none in an ordered one).
8. The types that win are crystals, not replicators: none of 2,944 one-bit variants is inherited.
9. BFF's loops inherit 80–85 % of variants through bytes copied unread, and a decoder type given one copy command and a free tail does the same [to show].
10. Self-maintenance and heredity are thus two separate properties of a map, and a decompressor as a rule has the first and can be designed to have the second.

## 7. Sentence 8 uses "crystal" and "replicator" before defining them; define by the test

1. A cellular automaton is built whose local rule is a dictionary decompressor: each 128-bit cell is read as a compressed stream and replaced by what it decodes to.
2. Two properties of the rule are measured: which of its attractors persist when neighbours exchange bits and settle by majority, and whether any of them pass on a change.
3. The decoder's map has an exactly countable attractor set: 68,964,123 fixed points in 15,693 families and one 3-cycle holding 99.995 % of the basin.
4. The structure is carried by the dictionary's words: a random map with the same contraction, or a byte-shuffled dictionary, does not reproduce it, while a word-shuffled one does.
5. Attractors can also be built into the dictionary, and the built ones are provably closed: any bitwise combination of their states is mapped back onto them, which fixed points are trivially and ordinary cycles are not.
6. On the lattice the basin does not pick the winner: a fixed point with 0.3 % of the basin takes the lattice from a cycle with 99.7 % in 99 of 100 seeds, because uniform domains are invariant, disordered open domains dissolve, and the closed type fills what dissolves and invades what does not.
7. The closed type nucleates in the sense of a critical radius (5–8 cells against an ordered domain, a wall then advancing at a constant 0.06–0.13 cells a turn) and of rare spontaneous starts (10⁻⁶ to 10⁻⁴ per cell and turn in a disordered domain, none in an ordered one).
8. Whether a change is passed on is tested by perturbing the winner: none of 2,944 one-bit variants of the decoder's types survives a turn, so these types grow like crystals, taking the form the rule prefers and propagating no defect.
9. BFF's loops inherit 80–85 % of variants through bytes copied unread, and a decoder type given one copy command and a free tail does the same [to show].
10. Self-maintenance and heredity are thus two separate properties of a map, and a decompressor as a rule has the first and can be designed to have the second.

## 8. Sentence 9: the quantity, not just the percentage

1. A cellular automaton is built whose local rule is a dictionary decompressor: each 128-bit cell is read as a compressed stream and replaced by what it decodes to.
2. Two properties of the rule are measured: which of its attractors persist when neighbours exchange bits and settle by majority, and whether any of them pass on a change.
3. The decoder's map has an exactly countable attractor set: 68,964,123 fixed points in 15,693 families and one 3-cycle holding 99.995 % of the basin.
4. The structure is carried by the dictionary's words: a random map with the same contraction, or a byte-shuffled dictionary, does not reproduce it, while a word-shuffled one does.
5. Attractors can also be built into the dictionary, and the built ones are provably closed: any bitwise combination of their states is mapped back onto them, which fixed points are trivially and ordinary cycles are not.
6. On the lattice the basin does not pick the winner: a fixed point with 0.3 % of the basin takes the lattice from a cycle with 99.7 % in 99 of 100 seeds, because uniform domains are invariant, disordered open domains dissolve, and the closed type fills what dissolves and invades what does not.
7. The closed type nucleates in the sense of a critical radius (5–8 cells against an ordered domain, a wall then advancing at a constant 0.06–0.13 cells a turn) and of rare spontaneous starts (10⁻⁶ to 10⁻⁴ per cell and turn in a disordered domain, none in an ordered one).
8. Whether a change is passed on is tested by perturbing the winner: none of 2,944 one-bit variants of the decoder's types survives a turn, so these types grow like crystals, taking the form the rule prefers and propagating no defect.
9. The heritable information of a copier is log₂ the size of the family of variants that still copy, which is eight bits for every byte the map copies verbatim: 384–432 bits for the self-copying loops of BFF, which inherit 80–85 % of single-byte variants, about 1.6 for Core War's imp, and zero for every type of the decoder.
10. Self-maintenance and heredity are thus two separate properties of a map, and a decompressor as a rule has the first and can be designed to have the second [to show].

## 9. Sentence 10 should state the design result as the paper's last word, and name the test

1. A cellular automaton is built whose local rule is a dictionary decompressor: each 128-bit cell is read as a compressed stream and replaced by what it decodes to.
2. Two properties of the rule are measured: which of its attractors persist when neighbours exchange bits and settle by majority, and whether any of them pass on a change.
3. The decoder's map has an exactly countable attractor set: 68,964,123 fixed points in 15,693 families and one 3-cycle holding 99.995 % of the basin.
4. The structure is carried by the dictionary's words: a random map with the same contraction, or a byte-shuffled dictionary, does not reproduce it, while a word-shuffled one does.
5. Attractors can also be built into the dictionary, and the built ones are provably closed: any bitwise combination of their states is mapped back onto them, which fixed points are trivially and ordinary cycles are not.
6. On the lattice the basin does not pick the winner: a fixed point with 0.3 % of the basin takes the lattice from a cycle with 99.7 % in 99 of 100 seeds, because uniform domains are invariant, disordered open domains dissolve, and the closed type fills what dissolves and invades what does not.
7. The closed type nucleates in the sense of a critical radius (5–8 cells against an ordered domain, a wall then advancing at a constant 0.06–0.13 cells a turn) and of rare spontaneous starts (10⁻⁶ to 10⁻⁴ per cell and turn in a disordered domain, none in an ordered one).
8. Whether a change is passed on is tested by perturbing the winner: none of 2,944 one-bit variants of the decoder's types survives a turn, so these types grow like crystals, taking the form the rule prefers and propagating no defect.
9. The heritable information of a copier is log₂ the size of the family of variants that still copy, which is eight bits for every byte the map copies verbatim: 384–432 bits for the self-copying loops of BFF, which inherit 80–85 % of single-byte variants, about 1.6 for Core War's imp, and zero for every type of the decoder.
10. A decoder type given one copy command and a free tail of k bytes is a replicator with 8k heritable bits and no processor behind it [to show], so persistence and heredity are two properties of a map, and a dictionary can be written to have either, both, or neither.

## 10. Cut what sentence 4 does not need; one null is enough in a sketch

1. A cellular automaton is built whose local rule is a dictionary decompressor: each 128-bit cell is read as a compressed stream and replaced by what it decodes to.
2. Two properties of the rule are measured: which of its attractors persist when neighbours exchange bits and settle by majority, and whether any of them pass on a change.
3. The decoder's map has an exactly countable attractor set: 68,964,123 fixed points in 15,693 families and one 3-cycle holding 99.995 % of the basin.
4. The structure is in the words: a word-shuffled dictionary has the same attractors and a byte-shuffled one does not.
5. Attractors can also be built into the dictionary, and the built ones are provably closed: any bitwise combination of their states is mapped back onto them, which fixed points are trivially and ordinary cycles are not.
6. On the lattice the basin does not pick the winner: a fixed point with 0.3 % of the basin takes the lattice from a cycle with 99.7 % in 99 of 100 seeds, because uniform domains are invariant, disordered open domains dissolve, and the closed type fills what dissolves and invades what does not.
7. The closed type nucleates in the sense of a critical radius (5–8 cells against an ordered domain, a wall then advancing at a constant 0.06–0.13 cells a turn) and of rare spontaneous starts (10⁻⁶ to 10⁻⁴ per cell and turn in a disordered domain, none in an ordered one).
8. Whether a change is passed on is tested by perturbing the winner: none of 2,944 one-bit variants of the decoder's types survives a turn, so these types grow like crystals, taking the form the rule prefers and propagating no defect.
9. The heritable information of a copier is log₂ the size of the family of variants that still copy, which is eight bits for every byte the map copies verbatim: 384–432 bits for the self-copying loops of BFF, which inherit 80–85 % of single-byte variants, about 1.6 for Core War's imp, and zero for every type of the decoder.
10. A decoder type given one copy command and a free tail of k bytes is a replicator with 8k heritable bits and no processor behind it [to show], so persistence and heredity are two properties of a map, and a dictionary can be written to have either, both, or neither.

## 11. Sentence 6 is three sentences long; split the result from its mechanism and let 7 carry the mechanism

1. A cellular automaton is built whose local rule is a dictionary decompressor: each 128-bit cell is read as a compressed stream and replaced by what it decodes to.
2. Two properties of the rule are measured: which of its attractors persist when neighbours exchange bits and settle by majority, and whether any of them pass on a change.
3. The decoder's map has an exactly countable attractor set: 68,964,123 fixed points in 15,693 families and one 3-cycle holding 99.995 % of the basin.
4. The structure is in the words: a word-shuffled dictionary has the same attractors and a byte-shuffled one does not.
5. Attractors can also be built into the dictionary, and the built ones are provably closed: any bitwise combination of their states is mapped back onto them, which fixed points are trivially and ordinary cycles are not.
6. On the lattice the basin does not pick the winner: a fixed point with 0.3 % of the basin takes the lattice from a cycle with 99.7 % in 99 of 100 seeds.
7. The mechanism is nucleation of the closed type: uniform domains are invariant, disordered open domains dissolve and are filled, ordered ones are invaded from seeds above a critical radius of 5–8 cells by a wall of constant speed, and spontaneous starts occur at 10⁻⁶ to 10⁻⁴ per cell and turn in disordered domains and never in ordered ones.
8. Whether a change is passed on is tested by perturbing the winner: none of 2,944 one-bit variants of the decoder's types survives a turn, so these types grow like crystals, taking the form the rule prefers and propagating no defect.
9. The heritable information of a copier is log₂ the size of the family of variants that still copy, which is eight bits for every byte the map copies verbatim: 384–432 bits for the self-copying loops of BFF, which inherit 80–85 % of single-byte variants, about 1.6 for Core War's imp, and zero for every type of the decoder.
10. A decoder type given one copy command and a free tail of k bytes is a replicator with 8k heritable bits and no processor behind it [to show], so persistence and heredity are two properties of a map, and a dictionary can be written to have either, both, or neither.

## 12. The two settling regimes are part of the result (weak dissolves all, strong freezes all); one clause in 7

1. A cellular automaton is built whose local rule is a dictionary decompressor: each 128-bit cell is read as a compressed stream and replaced by what it decodes to.
2. Two properties of the rule are measured: which of its attractors persist when neighbours exchange bits and settle by majority, and whether any of them pass on a change.
3. The decoder's map has an exactly countable attractor set: 68,964,123 fixed points in 15,693 families and one 3-cycle holding 99.995 % of the basin.
4. The structure is in the words: a word-shuffled dictionary has the same attractors and a byte-shuffled one does not.
5. Attractors can also be built into the dictionary, and the built ones are provably closed: any bitwise combination of their states is mapped back onto them, which fixed points are trivially and ordinary cycles are not.
6. On the lattice the basin does not pick the winner: a fixed point with 0.3 % of the basin takes the lattice from a cycle with 99.7 % in 99 of 100 seeds.
7. This happens only at partial settling, where disordered open domains dissolve and ordered ones hold, and it happens by nucleation: the closed type fills what dissolves, starting spontaneously at 10⁻⁶ to 10⁻⁴ per cell and turn, and invades what holds from seeds above a critical radius of 5–8 cells, by a wall of constant speed; weaker settling dissolves every type and stronger settling freezes every wall.
8. Whether a change is passed on is tested by perturbing the winner: none of 2,944 one-bit variants of the decoder's types survives a turn, so these types grow like crystals, taking the form the rule prefers and propagating no defect.
9. The heritable information of a copier is log₂ the size of the family of variants that still copy, which is eight bits for every byte the map copies verbatim: 384–432 bits for the self-copying loops of BFF, which inherit 80–85 % of single-byte variants, about 1.6 for Core War's imp, and zero for every type of the decoder.
10. A decoder type given one copy command and a free tail of k bytes is a replicator with 8k heritable bits and no processor behind it [to show], so persistence and heredity are two properties of a map, and a dictionary can be written to have either, both, or neither.

## 13. Sentence 2 says "persist"; sentence 10 says "persistence"; sentence 5 says "closed". One word: a type holds

1. A cellular automaton is built whose local rule is a dictionary decompressor: each 128-bit cell is read as a compressed stream and replaced by what it decodes to.
2. Two properties of the rule are measured: which of its attractors hold their ground when neighbours exchange bits and settle by majority, and whether any of them pass on a change.
3. The decoder's map has an exactly countable attractor set: 68,964,123 fixed points in 15,693 families and one 3-cycle holding 99.995 % of the basin.
4. The structure is in the words: a word-shuffled dictionary has the same attractors and a byte-shuffled one does not.
5. Attractors can also be built into the dictionary, and the built ones are provably closed, meaning that any bitwise combination of their states is mapped back onto them; fixed points are closed trivially and ordinary cycles are not, and closed is what holds.
6. On the lattice the basin does not pick the winner: a fixed point with 0.3 % of the basin takes the lattice from a cycle with 99.7 % in 99 of 100 seeds.
7. This happens only at partial settling, where disordered open domains dissolve and ordered ones hold, and it happens by nucleation: the closed type fills what dissolves, starting spontaneously at 10⁻⁶ to 10⁻⁴ per cell and turn, and invades what holds from seeds above a critical radius of 5–8 cells, by a wall of constant speed; weaker settling dissolves every type and stronger settling freezes every wall.
8. Whether a change is passed on is tested by perturbing the winner: none of 2,944 one-bit variants of the decoder's types survives a turn, so these types grow like crystals, taking the form the rule prefers and propagating no defect.
9. The heritable information of a copier is log₂ the size of the family of variants that still copy, which is eight bits for every byte the map copies verbatim: 384–432 bits for the self-copying loops of BFF, which inherit 80–85 % of single-byte variants, about 1.6 for Core War's imp, and zero for every type of the decoder.
10. A decoder type given one copy command and a free tail of k bytes is a replicator with 8k heritable bits and no processor behind it [to show], so holding and inheriting are two properties of a map, and a dictionary can be written to have either, both, or neither.

## 14. Honesty pass: closure says who holds, not who wins a wall; sentence 7 must not overclaim

1. A cellular automaton is built whose local rule is a dictionary decompressor: each 128-bit cell is read as a compressed stream and replaced by what it decodes to.
2. Two properties of the rule are measured: which of its attractors hold their ground when neighbours exchange bits and settle by majority, and whether any of them pass on a change.
3. The decoder's map has an exactly countable attractor set: 68,964,123 fixed points in 15,693 families and one 3-cycle holding 99.995 % of the basin.
4. The structure is in the words: a word-shuffled dictionary has the same attractors and a byte-shuffled one does not.
5. Attractors can also be built into the dictionary, and the built ones are provably closed, meaning that any bitwise combination of their states is mapped back onto them; fixed points are closed trivially and ordinary cycles are not, and closed is what holds.
6. On the lattice the basin does not pick the winner: a fixed point with 0.3 % of the basin takes the lattice from a cycle with 99.7 % in 99 of 100 seeds.
7. This happens only at partial settling, where disordered open domains dissolve and ordered ones hold, and it happens by nucleation: the winning fixed point fills what dissolves, starting spontaneously at 10⁻⁶ to 10⁻⁴ per cell and turn, and invades what holds from seeds above a critical radius of 5–8 cells, by a wall of constant speed; a second, equally closed fixed point holds its ground and loses the wall, so closure decides who holds and not who advances.
8. Whether a change is passed on is tested by perturbing the winner: none of 2,944 one-bit variants of the decoder's types survives a turn, so these types grow like crystals, taking the form the rule prefers and propagating no defect.
9. The heritable information of a copier is log₂ the size of the family of variants that still copy, which is eight bits for every byte the map copies verbatim: 384–432 bits for the self-copying loops of BFF, which inherit 80–85 % of single-byte variants, about 1.6 for Core War's imp, and zero for every type of the decoder.
10. A decoder type given one copy command and a free tail of k bytes is a replicator with 8k heritable bits and no processor behind it [to show], so holding and inheriting are two properties of a map, and a dictionary can be written to have either, both, or neither.

## 15. Sentence 7 is now too long for a reader; move the settling regimes to 6 and keep 7 for nucleation and the caveat

1. A cellular automaton is built whose local rule is a dictionary decompressor: each 128-bit cell is read as a compressed stream and replaced by what it decodes to.
2. Two properties of the rule are measured: which of its attractors hold their ground when neighbours exchange bits and settle by majority, and whether any of them pass on a change.
3. The decoder's map has an exactly countable attractor set: 68,964,123 fixed points in 15,693 families and one 3-cycle holding 99.995 % of the basin.
4. The structure is in the words: a word-shuffled dictionary has the same attractors and a byte-shuffled one does not.
5. Attractors can also be built into the dictionary, and the built ones are provably closed, meaning that any bitwise combination of their states is mapped back onto them; fixed points are closed trivially and ordinary cycles are not, and closed is what holds.
6. On the lattice, at partial settling, the basin does not pick the winner: a fixed point with 0.3 % of the basin takes the lattice from a cycle with 99.7 % in 99 of 100 seeds, while weaker settling dissolves every type and stronger settling freezes every wall.
7. The winner nucleates: it starts spontaneously in disordered domains at 10⁻⁶ to 10⁻⁴ per cell and turn, never in ordered ones, and it invades ordered domains from seeds above a critical radius of 5–8 cells by a wall of constant speed; a second, equally closed fixed point holds its ground and loses the wall, so closure decides who holds and not who advances.
8. Whether a change is passed on is tested by perturbing the winner: none of 2,944 one-bit variants of the decoder's types survives a turn, so these types grow like crystals, taking the form the rule prefers and propagating no defect.
9. The heritable information of a copier is log₂ the size of the family of variants that still copy, which is eight bits for every byte the map copies verbatim: 384–432 bits for the self-copying loops of BFF, which inherit 80–85 % of single-byte variants, about 1.6 for Core War's imp, and zero for every type of the decoder.
10. A decoder type given one copy command and a free tail of k bytes is a replicator with 8k heritable bits and no processor behind it [to show], so holding and inheriting are two properties of a map, and a dictionary can be written to have either, both, or neither.

## 16. The co-authored prior work must be named as such; one clause in 9

1. A cellular automaton is built whose local rule is a dictionary decompressor: each 128-bit cell is read as a compressed stream and replaced by what it decodes to.
2. Two properties of the rule are measured: which of its attractors hold their ground when neighbours exchange bits and settle by majority, and whether any of them pass on a change.
3. The decoder's map has an exactly countable attractor set: 68,964,123 fixed points in 15,693 families and one 3-cycle holding 99.995 % of the basin.
4. The structure is in the words: a word-shuffled dictionary has the same attractors and a byte-shuffled one does not.
5. Attractors can also be built into the dictionary, and the built ones are provably closed, meaning that any bitwise combination of their states is mapped back onto them; fixed points are closed trivially and ordinary cycles are not, and closed is what holds.
6. On the lattice, at partial settling, the basin does not pick the winner: a fixed point with 0.3 % of the basin takes the lattice from a cycle with 99.7 % in 99 of 100 seeds, while weaker settling dissolves every type and stronger settling freezes every wall.
7. The winner nucleates: it starts spontaneously in disordered domains at 10⁻⁶ to 10⁻⁴ per cell and turn, never in ordered ones, and it invades ordered domains from seeds above a critical radius of 5–8 cells by a wall of constant speed; a second, equally closed fixed point holds its ground and loses the wall, so closure decides who holds and not who advances.
8. Whether a change is passed on is tested by perturbing the winner: none of 2,944 one-bit variants of the decoder's types survives a turn, so these types grow like crystals, taking the form the rule prefers and propagating no defect.
9. The heritable information of a copier is log₂ the size of the family of variants that still copy, which is eight bits for every byte the map copies verbatim: 384–432 bits for the self-copying loops of the BFF soup we studied earlier (Agüera y Arcas et al. 2024), which inherit 80–85 % of single-byte variants, about 1.6 for Core War's imp, and zero for every type of the decoder.
10. A decoder type given one copy command and a free tail of k bytes is a replicator with 8k heritable bits and no processor behind it [to show], so holding and inheriting are two properties of a map, and a dictionary can be written to have either, both, or neither.

## 17. Sentence 3's numbers are for one dictionary; say so, and say the method is exact

1. A cellular automaton is built whose local rule is a dictionary decompressor: each 128-bit cell is read as a compressed stream and replaced by what it decodes to.
2. Two properties of the rule are measured: which of its attractors hold their ground when neighbours exchange bits and settle by majority, and whether any of them pass on a change.
3. The attractors of the map can be counted exactly: the default dictionary has 68,964,123 fixed points in 15,693 families, at least 51 two-cycles, and one 3-cycle that takes 99.995 % of random cells.
4. The structure is in the words: a word-shuffled dictionary has the same attractors and a byte-shuffled one does not.
5. Attractors can also be built into the dictionary, and the built ones are provably closed, meaning that any bitwise combination of their states is mapped back onto them; fixed points are closed trivially and ordinary cycles are not, and closed is what holds.
6. On the lattice, at partial settling, the basin does not pick the winner: a fixed point with 0.3 % of the basin takes the lattice from a cycle with 99.7 % in 99 of 100 seeds, while weaker settling dissolves every type and stronger settling freezes every wall.
7. The winner nucleates: it starts spontaneously in disordered domains at 10⁻⁶ to 10⁻⁴ per cell and turn, never in ordered ones, and it invades ordered domains from seeds above a critical radius of 5–8 cells by a wall of constant speed; a second, equally closed fixed point holds its ground and loses the wall, so closure decides who holds and not who advances.
8. Whether a change is passed on is tested by perturbing the winner: none of 2,944 one-bit variants of the decoder's types survives a turn, so these types grow like crystals, taking the form the rule prefers and propagating no defect.
9. The heritable information of a copier is log₂ the size of the family of variants that still copy, which is eight bits for every byte the map copies verbatim: 384–432 bits for the self-copying loops of the BFF soup we studied earlier (Agüera y Arcas et al. 2024), which inherit 80–85 % of single-byte variants, about 1.6 for Core War's imp, and zero for every type of the decoder.
10. A decoder type given one copy command and a free tail of k bytes is a replicator with 8k heritable bits and no processor behind it [to show], so holding and inheriting are two properties of a map, and a dictionary can be written to have either, both, or neither.

## 18. Sentence 10's moral is the paper's; make it the plain claim and drop "either, both, or neither"

1. A cellular automaton is built whose local rule is a dictionary decompressor: each 128-bit cell is read as a compressed stream and replaced by what it decodes to.
2. Two properties of the rule are measured: which of its attractors hold their ground when neighbours exchange bits and settle by majority, and whether any of them pass on a change.
3. The attractors of the map can be counted exactly: the default dictionary has 68,964,123 fixed points in 15,693 families, at least 51 two-cycles, and one 3-cycle that takes 99.995 % of random cells.
4. The structure is in the words: a word-shuffled dictionary has the same attractors and a byte-shuffled one does not.
5. Attractors can also be built into the dictionary, and the built ones are provably closed, meaning that any bitwise combination of their states is mapped back onto them; fixed points are closed trivially and ordinary cycles are not, and closed is what holds.
6. On the lattice, at partial settling, the basin does not pick the winner: a fixed point with 0.3 % of the basin takes the lattice from a cycle with 99.7 % in 99 of 100 seeds, while weaker settling dissolves every type and stronger settling freezes every wall.
7. The winner nucleates: it starts spontaneously in disordered domains at 10⁻⁶ to 10⁻⁴ per cell and turn, never in ordered ones, and it invades ordered domains from seeds above a critical radius of 5–8 cells by a wall of constant speed; a second, equally closed fixed point holds its ground and loses the wall, so closure decides who holds and not who advances.
8. Whether a change is passed on is tested by perturbing the winner: none of 2,944 one-bit variants of the decoder's types survives a turn, so these types grow like crystals, taking the form the rule prefers and propagating no defect.
9. The heritable information of a copier is log₂ the size of the family of variants that still copy, which is eight bits for every byte the map copies verbatim: 384–432 bits for the self-copying loops of the BFF soup we studied earlier (Agüera y Arcas et al. 2024), which inherit 80–85 % of single-byte variants, about 1.6 for Core War's imp, and zero for every type of the decoder.
10. A decoder type given one copy command and a free tail of k bytes is a replicator with 8k heritable bits and no processor behind it [to show]: what holds and what inherits are separate properties of the local map, and a few kilobytes of dictionary can be written to set each.

## 19. Read aloud; shorten every sentence that runs past two lines, keeping every number

1. A cellular automaton is built whose local rule is a dictionary decompressor: each 128-bit cell is read as a compressed stream and replaced by what it decodes to.
2. Two properties of the rule are measured: which of its attractors hold when neighbours exchange bits and settle by majority, and whether any of them pass on a change.
3. The attractors of the map can be counted exactly: the default dictionary has 68,964,123 fixed points in 15,693 families, at least 51 two-cycles, and one 3-cycle that takes 99.995 % of random cells.
4. The structure is in the words: a word-shuffled dictionary has the same attractors and a byte-shuffled one does not.
5. Attractors can also be built into the dictionary, and the built ones are provably closed: any bitwise combination of their states maps back onto them, as it does for fixed points and not for ordinary cycles; closed is what holds.
6. At partial settling the basin does not pick the winner: a fixed point with 0.3 % of the basin takes the lattice from a cycle with 99.7 % in 99 of 100 seeds; weaker settling dissolves every type, stronger settling freezes every wall.
7. The winner nucleates, spontaneously in disordered domains at 10⁻⁶ to 10⁻⁴ per cell and turn and never in ordered ones, which it invades from seeds above a critical radius of 5–8 cells by a wall of constant speed; a second, equally closed fixed point holds and loses the wall, so closure decides who holds, not who advances.
8. Perturbing the winner tests inheritance: none of 2,944 one-bit variants of the decoder's types survives a turn, so these types grow like crystals, taking the rule's preferred form and propagating no defect.
9. A copier's heritable information is log₂ the size of the family of variants that still copy, eight bits per byte the map copies verbatim: 384–432 bits for the loops of the BFF soup we studied earlier (Agüera y Arcas et al. 2024), which inherit 80–85 % of single-byte variants; about 1.6 for Core War's imp; zero for every type of the decoder.
10. A decoder type given one copy command and a free tail of k bytes is a replicator with 8k heritable bits and no processor behind it [to show]: what holds and what inherits are separate properties of the local map, and a few kilobytes of dictionary can set each.

## 20. Final: the first sentence names the object as the title will; the last names the test still owed

1. A dictionary decompressor is used as the local rule of a cellular automaton: each 128-bit cell is read as a compressed stream and replaced by what it decodes to, so the rule's genome is a few kilobytes of text.
2. Two properties of the rule are measured: which of its attractors hold when neighbours exchange bits and settle by majority, and whether any of them pass on a change.
3. The attractors of the map can be counted exactly: the default dictionary has 68,964,123 fixed points in 15,693 families, at least 51 two-cycles, and one 3-cycle that takes 99.995 % of random cells.
4. The structure is in the words: a word-shuffled dictionary has the same attractors and a byte-shuffled one does not.
5. Attractors can also be built into the dictionary, and the built ones are provably closed: any bitwise combination of their states maps back onto them, as it does for fixed points and not for ordinary cycles; closed is what holds.
6. At partial settling the basin does not pick the winner: a fixed point with 0.3 % of the basin takes the lattice from a cycle with 99.7 % in 99 of 100 seeds; weaker settling dissolves every type, stronger settling freezes every wall.
7. The winner nucleates, spontaneously in disordered domains at 10⁻⁶ to 10⁻⁴ per cell and turn and never in ordered ones, which it invades from seeds above a critical radius of 5–8 cells by a wall of constant speed; a second, equally closed fixed point holds and loses the wall, so closure decides who holds, not who advances.
8. Perturbing the winner tests inheritance: none of 2,944 one-bit variants of the decoder's types survives a turn, so these types grow like crystals, taking the rule's preferred form and propagating no defect.
9. A copier's heritable information is log₂ the size of the family of variants that still copy, eight bits per byte the map copies verbatim: 384–432 bits for the loops of the BFF soup we studied earlier (Agüera y Arcas et al. 2024), which inherit 80–85 % of single-byte variants; about 1.6 for Core War's imp; zero for the decoder's winning fixed point, whose every bit is read, and at most 24 bits of medium-carried capacity for the largest families of unread bytes [E8b].
10. What holds and what inherits are separate properties of the local map, and the one experiment this paper still owes is the dictionary that sets both: a decoder type with one copy command and a free tail of k bytes, which should be a replicator with 8k heritable bits and no processor behind it.

## Correction after pass 20 (the same day)

Sentence 9: "zero for every type of the decoder" overclaimed. Family members differ in unread bytes that mixing can
carry between neighbours of the same family, a channel of up to 8 bits per free byte through the medium rather than
the map; the winning fixed point of Brotli 12 has no free bytes, Swarm F's largest families have three. Measured in
DESIGN_SENTENCES.md E8b.

## What the twenty passes did

Passes 1–3 fixed the opening (what the rule does to a cell; the two axes stated up front). Passes 4–7 made each
term carry its definition at first use (closed, nucleation, crystal, replicator) so the sketch reads without the
glossary. Passes 8–9 replaced percentages with the quantity (heritable bits) and made the design result the last
word. Passes 10–13 cut (one null, one word for "holds") and split the overloaded sixth sentence. Pass 14 was the
honesty pass (closure decides who holds, not who advances). Passes 15–17 rebalanced length, declared the prior
co-authorship, and scoped the census to one dictionary. Passes 18–20 shortened everything to be read aloud and
ended on the experiment still owed rather than on a claim not yet earned.
