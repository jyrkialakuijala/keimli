# Round 2: artificial-life and biology reviewer (methodology)

New evidence comes from my own small runs, in scratch only: `inv.mjs` in my scratchpad, using the project's harness. The settings were Brotli 12, cread 4096, skip 6, pair mode 0, the **rotating** swap order, quenched hashing, 96² or 128², one seed. The resident was a phase-coherent domain of one attractor; I implanted an s × s patch at turn 10 and followed it for 200 to 300 turns. Brotli 12's attractors under the isolated decoder: a 3-cycle (99.72 %) and a fixed point (0.26 %).

## (a) Responses to the panel

**Professor (von Neumann, Langton 1984, trivial replication).** I agree, and it is the same point as my "limited heredity" concern under its older name. One refinement: Langton dropped universal construction but kept a description that is both *interpreted and copied*. Tierra, Avida and BFF keep that too: a copy loop copies the tape byte by byte, the unused bytes included. Keimli has neither. What it shows is trivial replication, and my runs show it is a poor kind of trivial replication: crystal-like domain growth that needs a nucleus, not spreading from a single seed.

**Computation reviewer (1/(N·b) uses the wrong basin).** I agree and would go further. The unit is the wrong one, not only the basin. In my runs, a 1×1 or 2×2 patch of *any* attractor inside a resident domain is erased within 10 turns at every strong-settling point (ps = 1; pm = 0.5, 0.1, 0.02). A 16×16 fixed-point patch in a 3-cycle domain survives (256 → 144 to 244 cells, then frozen). So what has to happen first is a supercritical nucleus of side s* ≈ 4 to 16, and its probability is far below b. Under the medium, first appearance of a type that persists can therefore be genuinely late: nucleation, as in an Allee effect. Still a medium phenomenon, not computation, but the formula and "never late" are wrong as they stand. (My runs used the rotating order.)

**Physicist (takeover is not a front).** I agree, and my data point to a mechanism other than a front.
- Under uniform strong settling, a rare type never grows. A 32×32 fixed-point patch stays at 908 to 1,012 cells for 300 turns, pinned. A 32×32 3-cycle patch in a fixed-point domain shrinks from 1,024 to 44 cells by turn 300 (pm 0.5) or to 764 (pm 0.02). The fixed point wins contests at the wall, but slowly or not at all.
- Under weak settling (ps = 0.3), *both* resident domains dissolve into off-cycle noise once disturbed. A single random cell brought down a whole 3-cycle domain (9,216 → 290 cells by turn 200). Fixed-point domains dissolve more slowly (8×8 random patch: 6,968 cells left against 28).

So the fixed point's win under the frame most likely comes from *robustness*: it survives in the noisy rows where the cycle melts, and then holds its ground. That is not invasion. It is "survival of the flattest" (Wilke et al. 2001, Avida; cite it): selection on robustness.

**Mathematician ("replicator = attractor" is a definition).** I partly disagree, and the disagreement can be made formal. An unlimited-heredity copier is not one fixed point. It is a map whose fixed-point set is *a family*: every variant of the copier that keeps the copy loop is also copied. Proposed observable: **heritable bits**, the log₂ of the number of distinct contents that maintain themselves and are propagated by the medium within one type.
- Keimli: at most log₂ of the number of attractors, which is 1.6 to 5 bits. The designed dictionaries' 82 "free" bits are overwritten by the dictionary copy, so they are not heritable.
- BFF: about 8 bits for each byte the copy loop ignores.

This is the sharp line between Keimli and computational life, and it is measurable.

**Information theorist (the "pump" is erasure).** I agree, and it is the biological point turned round. The decoder repairing a mutant *is* the erasure of that variation. A system whose dissipation erases variation cannot have heredity of variants. Eigen's error threshold does not apply here: there is no information above the attractor's identity for errors to destroy.

**Optimiser.** Selection does exist in this project, one level up. The dictionaries were chosen by a score and by the author's eye, as in Picbreeder. "Nothing is selected" is false at that level too. The paper should say "the lattice has no fitness function; the dictionaries were selected".

## (b) Methodology

**1. Maynard Smith and Szathmáry's terms.** A unit of evolution needs multiplication, heredity and heritable variation.
- *Multiplication:* yes, by the medium (majority voting plus the funnel converts neighbours), but only above a critical nucleus.
- *Heredity:* limited. A type's identity passes to the neighbours it converts, and the number of types is the attractor count (3 to 32).
- *Variation:* none that is heritable (test 2).

Keimli's types therefore fall in the attractor-replicator, limited-heredity class: prions, Cairns-Smith clays, and autocatalytic sets (Vasas, Szathmáry and Santos 2010; Kauffman). Selection among types does occur (concern 1 of round 1, now with the robustness mechanism above), but Darwinian evolution cannot.

**2. Is a variant ever copied?** I ran two kinds of mutant patch (s = 1, 8, 32) in both resident domains at three (pm, ps) points:
- a one-bit flip of the resident state (byte 8, bit 3): the exact mutant content had zero copies at turn 1 and was never seen outside the patch. Off-attractor cells went back to 0 within 1 to 2 turns.
- a random 16-byte content: also zero copies from turn 1, never outside the patch. Under strong settling, repaired within 20 to 50 turns. Under ps = 0.3 it did not revert; it nucleated the disordered phase.

Variation is **always repaired or turned into noise, never copied**. Only attractor states travelled: 4 to 20 cells of the implanted type outside a fixed-point or 3-cycle patch at ps = 0.3. Caveats: one dictionary, one seed, idealised residents; repeat over designed dictionaries, 10 seeds, three hashings, every bit position.

**3. Fitness measure.** For each ordered pair of attractors (X, R) and each (pm, ps, hashing), measure three things:
- **s\***(X | R): the smallest square patch of X that is still above its initial size after 500 turns (critical nucleus);
- **v**(X | R): the velocity of a straight X/R wall on a strip, to remove curvature, in cells per turn;
- **ρ**(X): the half-life of a pure X domain after one random cell is planted at ps = 0.3 (robustness).

Invasion fitness in the ecological sense, the growth rate when rare, is negative everywhere I looked. The text should then say "domain competition" rather than "invasion", or show a case with s\* = 1. Pairwise-invasibility plots would come from s\* and v. The test: do (v, ρ) measured on uniform strips predict the winners in replicators.md under the frame? If they do, "the medium chooses" becomes a quantitative theory of selection without a fitness function.

**4. The census of the Computational Life programs.**
- (i) Use the BFF of the 2024 paper itself (64-byte tapes, pair concatenation, 2¹³ steps). Also use Keimli's own Brainfuck changer on concatenated cell pairs, so the medium is shared.
- (ii) Operational replicator: a tape a such that, for random partners b, F(a, b) leaves a in the partner's half with probability q ≥ ½.
- (iii) Sample 10⁸ to 10⁹ random tapes for p_rep, and compare it with 1 / (number of tapes × number of interactions before the transition). If p_rep is that small, BFF replicators were *built*, not listed, and Keimli's deflation does not carry over. It then becomes a question for arXiv:2607.01483 (a random walk of mutations against computation), which the draft must discuss.
- (iv) Heredity: mutate a replicator at bytes outside its copy loop and check whether the offspring carry the mutation. Report heritable bits per family against Keimli's.
- (v) Repair against propagation after k-byte damage, the same test as (2) above.
- (vi) No-mutation and spatial (2D) BFF controls. With their runs on Keimli's lattice, these give a matched-medium comparison row.

## (c) The claim as my community would accept it

> "A rewriting map with no copy instruction, placed in a medium of neighbour exchange and majority voting, reproduces the *multiplication and competitive exclusion of a fixed, listable set of types*: trivial replication in von Neumann's and Langton's sense, with limited heredity. Which type wins is set by the medium, through the types' robustness and wall mobility, not by their basins. Variants are never inherited. Phenomena of computational life that need only multiplication and differential persistence of types, such as takeover, coexistence and the late spread of a rare attractor, therefore need neither computation nor a copy instruction. Phenomena that need heritable variation, such as diversification, parasites arising as mutants, arms races and rising complexity, cannot be explained by local entropy reduction. In computational life they are candidates for what descriptional (template) copying adds."

Drop "nothing replicates, nothing is selected" and "replicators are fixed points" as unqualified statements. The author's co-authorship of the 2024 paper should be declared next to this paragraph.

**Experiments that would settle it:**
1. The heritable-bits comparison: Keimli's designed dictionaries against BFF families.
2. The fitness matrix (s\*, v, ρ) predicting the frame's winners.
3. The BFF random-tape census against 1/(N·interactions).
4. First appearance of a *supercritical cluster* against N (48 to 512), rotating order, with the hashing salted by position.

What would change my mind: a Keimli variant, off the listed attractors or carrying a changed "free" byte, that is propagated by the medium for more than 100 turns. That would show heritable variation without a copier.
