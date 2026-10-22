# Round 2, second panel: artificial-life and biology reviewer

2026-10-22. After reading the other six round-1 notes. References are to `round1-<role>.md` in this folder by
finding or section number; "my round 1" is `round1-alife-biology.md`.

## 1. Agreement and disagreement, by file and number

**Mathematics, finding 10 ("heritable bits = log₂ of the fixed-point family size = bytes the map copies without
reading"), and finding 6 (Keimli's self-read-literal families as BFF heredity "in miniature").** Agree with the
quantity; disagree that it is heredity on its own. Log₂ of the family size is a *capacity*: the number of bits a
lineage could carry. Heredity needs a second thing, a step that puts a parent's unread bytes into an offspring. BFF
has it (g writes R into the partner slot) and the capacity is realised: the final soups keep 28–88 % of tapes
distinct after takeover (`bff-census.md` §5), so lineages do traverse the neutral set. Keimli's families (up to 3
free bytes, `map-spine.md` §1) have no such step: a family member is a fixed point of f, but nothing copies its free
bytes into a neighbour, and a neighbour that receives them by crossover is repaired or converted (`mechanism.md` §5).
So the families are capacity without transmission, and the mathematician's "in miniature" should read "the
*combinatorics* of BFF heredity in miniature, with no copier to use it". The definition for the paper is then two
numbers per system: log₂|family| (capacity) and the measured transmission per generation (BFF 80–85 % conditional
on slot, about 40 % per encounter; Keimli 0). This is my round-2 "heritable bits" observable with the mathematician's
exact first half, and I take his half as the better statement of it.

**Information theory, findings 20–21 and 25 ("repair against inheritance: heredity needs bits the copier does not
read").** Agree entirely, and it is the sentence I would put on the first page in place of "nothing replicates".
Two refinements. (a) In my field's words it is Maynard Smith and Szathmáry's limited against unlimited heredity, and
the capacity-against-transmission split above is what makes it measurable; the information theorist's "channel
capacity about 400 bits against a few bits" is the capacity half. (b) His falsifiable form, "a rule that reads every
bit it copies cannot inherit a mutation", is right but should say *reads and acts on*: BFF's loop code is both read
(executed) and copied, and 4–22 % of its code mutants still breed true (`bff-census.md` §4). Reading does not forbid
inheritance; repair does. The decoder repairs because it writes dictionary bytes rather than copying anything.

**Physics, §2.2 (droplets and closure at one settling pass, the frame and replicators at three).** Agree, and this
is the finding of the round. I missed it, and my own Swarm F run (round 1, §8) inherits it: `droplets.mjs` at
`passes: 1`. So every number in `closure-vs-survival.md`, in `mechanism.md` §2–3, and my "fourth hit" is at one third
of the frame's settling, and the chain "closure → melting → the frame's winner" is not measured at one parameter set.
The physicist's track reading (the closed fixed point's droplet dies in the melting sea at one pass; at three passes
on the frame it ends at 100 %) means that at one pass the frame's result is not reproduced in uniform parameters. I
agree with the physicist's §2.3 and the mathematician's finding 8 and the computation reviewer's finding 2 that
"nucleation" has no experiment behind it: share curves are size-free below the plateau, no radius series exists, and
the droplet tracks show no fixed point forming from the melt in 400 turns. The word should go until a radius series
shows a critical radius. I would add the biological reading of the mathematician's experiment (i), replacing every
fixed-point-basin cell at turn 0: it is a *lineage* test. If the fixed point still wins, the medium re-creates the
type and nothing in Keimli descends from anything, which was my round-3 point ("types recur, they do not descend");
if it does not, the winners are the survivors of the start, and "present from the start" becomes literally true for
the domains that win. Either answer is worth a sentence; the experiment costs an hour.

**Professor, finding 9 ("von Neumann's tape, measured in three substrates").** Agree, and it is where my rounds 2–3
were pointing. One precision, because an ALife referee will make it. Von Neumann's description is *both*
interpreted (by the constructor) and copied uninterpreted (by the copier). BFF has both halves: the loop code is
executed and copied as data; the 48–54 neutral bytes are copied only. Keimli's types have neither half copied; the
decoder's "copy" is a dictionary lookup. So the measured heredity contrast is between "copied as data" and "not
copied", and Langton's non-trivial criterion (the copied description is also interpreted) is met by BFF's loop, not
by its neutral tape. The paper should say the three substrates measure the *copy-as-data* half, and that the imp
(one instruction, no unread bytes) sits with Keimli on it. Also agree with the professor's finding 10 and my own
round 3: an author from outside the 2024 team.

**Computation, finding 5 (the Declaration at kmax = 64 is unmeasured).** Agree; I quoted "the Declaration produces no
takeover" in round 1 §4 as if it were measured. It is not, and it matters for me because the Declaration is the one
dictionary whose attractors are long cycles with many competitors, the closest Keimli has to an open-ended type set.

**Optimization, findings 3, 5, 10 and 14.** Finding 3 (basin against survival r = −0.57): endorse as the figure
that states the result in the hypothesis's own quantity. Finding 5 (closure is silent among closed types; the winner
among designs is unexplained): agree, and that is the edge of the selection rule, not a flaw in it. Finding 10
(gray3c coexists under uniform settings too, two leaders over 20 seeds): this is the one case of coexistence without
a frame, and the question it raises is mine from round 2, whether it is a frozen stand-off or negative frequency
dependence; see §4 item c. Finding 14 ("lively" is the off-diagonal cross-closure, asymmetric invasion without
melting): in ecological terms that is the pairwise invasibility plot, and the droplet JSON already holds the data
for a first version; endorse.

**Physics, §4.2 ("error threshold" should be "lethal noise threshold").** Agree, against my round 1 §4.4, where I
called it Eigen's threshold. Eigen's relation needs the genome length varied; the replicase tape is 96 bits
throughout. Item d in §4 would make it Eigen's.

## 2. What I revise in my own round 1

1. **The 2^−100 argument (round 1, §4.3) is withdrawn as a number.** I computed the rarity of a random tape being a
   member of an *evolved* replicator's family (one fixed loop, 51 neutral bytes). The relevant set is all minimal
   self-copiers at every tape position with every tolerated code variant, which is far larger: a 6–8-byte core at any
   of about 60 positions already gives of order 2^−40, and the code tolerance (4–33 % of code mutants breed true) and
   the second loop family widen it further. Knierim et al. 2026, cited in `RELATED_WORK.md` l.42, report that
   mutation random walks without interaction find replicators as fast as the soup, which is only possible if the
   self-copier set is many orders larger than my estimate. What survives of the argument is the qualitative half,
   which does not depend on the number: no self-copier is present in the initial 2^17 tapes (top share 0.00 %,
   high-order entropy 0.1 for thousands of epochs before the jump, `bff-census.md` §5), so BFF's replicators are not
   "listed" at a share ≥ 1/N as Keimli's are; they are reached, by a walk or by selection on partial copiers. Which
   of those two is the open question between the 2024 paper and the 2026 follow-up, and the paper should cite it as
   open rather than settle it. The quantity to print is the measured self-copier fraction of random tapes (§4 item a),
   not an extrapolation.
2. **"Melting, then nucleation" (round 1 §2.3–2.4):** I accepted the first half and loosely the second. Revised to:
   melting is measured (at one pass); what fills the melt is not, and the sentence should be "seeded growth from the
   start's own cells or from the settled rows" until the lineage test and a radius series are run at three passes.
3. **The Swarm F "fourth hit" (round 1 §2.2, §8):** stands as a one-pass result only, like the rest of the table.
4. **The borderline pair (round 1 §2.2):** I repeated `mechanism.md` l.56, "survive mixing alone but die under partial
   settling". The optimization reviewer's finding 4 is right: the 11-cycle dies at median 0 as well (1 / 1 / 1 / 100).
   Only the 5-cycle survives mixing alone.
5. **The Declaration (round 1 §4, item 7 of §1):** unmeasured, per computation finding 5.
6. **"Error threshold in Eigen's sense" (round 1 §4.4):** lethal-noise threshold at fixed length.
7. **The processor rows:** the computation reviewer's finding 1a (the harness hash behind every closure, droplet,
   heredity and frame-mechanism file matches no commit) means the mechanism data I checked by rerun were reproduced
   with the current harness, not the one that made them; my reruns agreed bit for bit, which is evidence the
   difference is immaterial, but the stamp cannot prove it.

What I keep: the heredity verdict (0 of 2,944 Keimli mutants heritable; BFF 100 % on unread bytes), the conditional
nature of the 80–85 % (slot), the imp as a limited-heredity replicator, the vocabulary, the co-authorship declaration.

## 3. The panel's three most important corrections, ranked

1. **The mechanism was measured at two different settling strengths, and its second half is not shown** (physics
   §2.2–2.3; mathematics finding 8; computation finding 2; optimization finding 6). The closure and droplet set at
   one pass, the frame and the replicator Monte Carlo at three. "Closed types nucleate in the melt" has no
   uniform-parameter experiment behind it, and at one pass the closed droplet dies. This decides whether the central
   sentence stands; it is 1–2 days and under 50 CPU-hours to settle (three-pass droplets and whole-lattice survival
   with seeds, a radius series, the lineage test, the lattice-basin measurement).
2. **The heredity reframing** (mathematics 10, information 20–21 and 25, professor 9, my §1 above): the second
   paper's thesis is not "computation against entropy reduction" (infodyn returned the opposite) but heredity as
   the copying of unread bytes, split into capacity (log₂ family size) and transmission (measured per generation),
   in von Neumann's and Maynard Smith–Szathmáry's terms. With it, the BFF origin question must be stated as open and
   the self-copier fraction of random tapes measured rather than estimated (my §2.1).
3. **The statistics and the hand-typed numbers** (all six on r = 0.79; optimization 11 on 38/39 and 94/95;
   computation 5 on the Declaration; computation 6 and professor on the CPU rows without files; information 4 on the
   look-and-say bound one digit short). Replace r by the 2 × 2 count with its two exceptions and the basin's negative
   correlation; generate every results table from the data; rerun the Declaration at kmax ≥ 200 and the 6502 and
   Redcode single-cell rows with the fixed script.

The writing (drafts contradicting the results, no co-authorship declaration) is the largest risk, as every reviewer
says, but it is not a correction of a finding and I leave it off this list.

## 4. Minimum work for my role, deduplicated

Already demanded by others and not repeated here: three-pass droplets, closure and survival with 3 seeds (physics 1);
the radius series (physics 2); the melting threshold p* per type (physics 3, professor 3, information 4); the lattice
basin of the fixed point (physics 4); the lineage test and the pre-melted-sea droplet (mathematics finding 8);
closure for every named dictionary with predictions written first (optimization a, computation Q6); a frame map for
Swarm F and gray3c (optimization c); the imp's mutant census (information 6, mathematics 10); seeds for dose-response
and infodyn (several); the 6502 and Redcode single-cell rerun (computation, professor); twenty BFF soups for a rate
(physics 7, professor); the Declaration at kmax 200 (computation); exact fixed points of Brotli 12 and 13 (professor
2); the rewrite with the co-authorship declaration and the vocabulary row in RELATED_WORK (professor 15, all).

Mine, in addition:

| # | item | what it decides | cost |
|---|---|---|---|
| a | The self-copier fraction of uniformly random tapes (`bff.mjs` soupStats protocol on 10⁷ tapes) and of each emerged soup at epochs −1,024, −256, −64 before its transition; plus one Knierim-style mutation walk without interaction (2^17 tapes, 12,000 epochs, no pairing) counting the first self-copier | whether BFF's replicators are listed, built by a walk, or built by selection; replaces my withdrawn 2^−100 | 5 CPU-h, half a day |
| b | Heredity as transmission: for BFF, log₂ of the number of distinct self-copier tapes in each final soup (data exist, `bff-census.md` §3 self-copier sample) beside log₂\|family\|; for Keimli, plant one member of a 3-free-byte family (window 69) in a lattice at three settings and count neighbours that ever acquire its free bytes (expected 0) | capacity against transmission in both systems; the mathematician's quantity made into heredity | 1 CPU-h |
| c | Invasion when rare for the gray3c trio under (½, 1), three passes, 5 seeds: each type planted as a 5 % disc in each other's domain, 1,000 turns; growth rate when rare per ordered pair | whether the only frame-free coexistence (optimization 10) is a frozen stand-off or negative frequency dependence; my round-2 s* for the one case where it matters | 18 runs at 256², 2 CPU-h |
| d | Replicase at three tape lengths (48, 96, 192 bits) × swap {0.002, 0.005, 0.01, 0.02} × 5 seeds, lineage heredity as the readout | whether the lethal-noise threshold scales as 1/length, which would make it Eigen's and justify the citation | 60 runs, 4 CPU-h; for paper 2 only |
| e | Text: the slot condition beside every BFF heredity figure; "seeded growth" for "nucleation"; "lethal-noise threshold"; the capacity/transmission definition; Wilke 2001 and Vasas 2010 beside Schaper–Louis in the related-work row the professor adds | | half a day |

About two days and 12 CPU-hours beyond the shared list; items a–c belong to the first paper if the BFF section is
folded into it, as I recommended in round 1.
