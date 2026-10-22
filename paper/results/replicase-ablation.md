<!-- provenance: paper/experiments/replicase.mjs (27131eef3a4b5c8b) mode=summary | commit 48f9653+dirty | wasm 90ec8c30bca92b5b | 2026-10-21T13:09:57.089Z -->
<!-- provenance: paper/experiments/replicase.mjs (d4f4aca124c10742) mode=decoder seeds=5 | commit 48f9653+dirty | wasm 90ec8c30bca92b5b | 2026-10-21T12:14:19.959Z -->
# Replicase ablation: what each built-in ingredient contributes

2026-10-21. `experiments/replicase.mjs`, 1,150 runs of 128 × 128 cells ×
2,000 turns, seeds 1 to 5 for every condition, plus the plain-decoder
reference. Raw data `../data/replicase/runs/*.json` (one file per run,
each with a `provenance` field), `../data/replicase/summary.json`,
`../data/replicase/summary-table.md` (every condition) and
`../data/replicase/decoder-mutants-n128.json`. Two script versions made
the runs: `d4f4aca1` and `27131eef`. The second only adds the `template`
copy mode and relabels a summary column, so the runs agree across the
change.

**The objection.** "You built replicators into the rule, so of course they
appear." The experiment does not dispute this. Everything below is built
in. What it measures is which built-in ingredient is needed for which
property, what each costs in entropy, and how the plain decoder compares.
It does not show that replicators exist for free.

## Design

A cell's 128 bits are **[control: bytes 0–3 | tape: bytes 4–15]**. A
cell is a **replicator** when the low *m* bits of its control word equal a
fixed motif, so a random cell matches with probability p = 2⁻ᵐ (default
m = 16; 0.25 matches expected in 16,384 random cells). On turn t every
replicator may write into one neighbour, in the direction t mod 4 (right,
down, left, up). Each cell then has exactly one possible writer and the
update is synchronous. The rewrite runs as a JS `rewrite` hook in
`tools/ca-harness.mjs`, after the page's mixing and settling (rotating
swap order, quenched hashing). No wasm was changed.

| switch | levels |
|---|---|
| **copy** (a) | `none`; `template`: the child is the canonical replicator, with the motif, free control bits zero and the tape derived from the motif, so there is no heredity at all (Langton's crystal growth); `derived`: the tape is a fixed hash of the parent's control word, so the tape carries nothing of its own and heredity is limited to the 32 − m = 16 free control bits; `verbatim`: the 96 tape bits are copied unread (unlimited heredity) |
| **self** (b) | 1: the control word is copied too, so the child is a replicator; 0: only the tape is copied |
| **trait** (c) | 1: copy probability q = (1 + popcount(tape byte 0))/9, ranging from 1/9 to 1; 0: q = 5/9 for all (the mean over random tapes) |
| **erase** (d) | the background map for non-replicators: `id`; `r90`, elementary rule 90 on the 128-bit ring, which loses exactly 2 bits a turn (entropy-manipulators.md); `dec`, one step of the Brotli-like decoder (kind 36, Swarm F, wasm) |
| **protect** | 1 (default): replicators are exempt from the background map; 0: they are not |
| **medium** | `off`; `mild` (swap 0.002, median 0.01); `weak` (0.05, 0.1); `strong` (½, 1: the uniform setting of entropy-manipulators.md); and a scan |
| **mu** | 0 or 10⁻³ single-bit flips per cell per turn |

The factorial covered copy × self × trait × erase × medium
{off, mild, strong} × mu, 162 conditions. Further sets:
- m ∈ {8, 12, 20, 24};
- the `template` set;
- protect = 0;
- a medium scan;
- twin runs.

**Measures.**
- **Lineages** are kept in side arrays that the rule updates. A cell that
  becomes a replicator without being copied into founds a lineage; a copy
  inherits its writer's lineage; the background map changing a cell
  clears it.
- The **emergence time** is the first turn at which some lineage holds at
  least 16 cells.
- **Heredity.** At turn 500, 48 marked point mutations go into
  replicators' tapes:
  - 16 neutral (a bit of tape bytes 1–11);
  - 16 "up" (a 0 bit of the trait byte set);
  - 16 "down" (a 1 bit cleared).

  Heredity is the fraction of copied descendants that still carry the
  mutated bit value, 100 turns later.
- **Selection** has two measures:
  - log₂ of the ratio of descendants per up mutant to descendants per down
    mutant at turn 2,000, each count plus 1;
  - Δtrait: the mean trait (popcount) of replicators at the end minus the
    mean over all founders.
- **Entropy**, at turn 2,000:
  - collision entropy H₂ per cell (resolvable to 27 bits at this N; "> 27"
    means no equal pair);
  - distinct cells / N;
  - copy bits: bits changed by copies, per cell per turn;
  - bg bits: bits changed by the background map, per cell per turn.

  Copy and bg bits are averaged over the whole run.
- **Intervals.** Every ± is the 95 % t-interval over the 5 seeds, unless
  n is given. Emergence is bimodal under `id` and `dec`: it happens only in
  seeds 1 and 3, the seeds whose random start contains a matching cell. For
  those conditions the mean ± is a poor summary; the counts "x/5" are the
  result.

## Results

### 1. The core ablation (rule-90 background, medium off, mu = 10⁻³)

| condition | lineage ≥ 16 | median turn | replicator share | descendants per neutral mutant (k = 100) | heredity (k = 100) | log₂ up/down | Δtrait | H₂ (bits) | distinct/N | copy bits | bg bits |
|---|---|---|---|---|---|---|---|---|---|---|---|
| none | 0/5 | – | 0.00 | 0 | – | – | 0.33 ± 0.20 | 0.2 ± 0.0 | 0.055 ± 0.002 | 0 | 3.44 |
| template, self | 5/5 | 10 | 1.00 | 1.9 ± 2.5 | 0.00 (n = 3) | 0.00 | 0.34 ± 0.16 | 0.0 | 0.002 | 0.04 | 2.01 |
| derived, self 0, trait 1 | 0/5 | – | 0.00 | 0.5 ± 0.2 | 0.66 ± 0.27 (chance level, see below) | – | 0.40 ± 0.18 | 0.2 | 0.059 | 0.03 | 3.73 |
| derived, self 1, trait 0 | 5/5 | 10 | 1.00 | 1.9 ± 2.5 | 0.00 (n = 3) | 0.00 | 0.07 ± 0.35 | 3.9 ± 0.5 | 0.006 | 6.02 ± 0.67 | 2.01 |
| derived, self 1, trait 1 | 5/5 | 11 | 1.00 | 1.5 ± 1.5 | 0.00 ± 0.00 | 0.65 ± 2.30 | **3.74 ± 0.78** | 1.0 ± 0.8 | 0.001 | 2.07 ± 0.85 | 2.01 |
| verbatim, self 0, trait 1 | 0/5 to 1 % (lineages ≤ 20 cells) | – | 0.003 | 0.8 ± 0.5 | 0.97 ± 0.08 | 1.25 ± 1.22 (n = 4) | 0.87 ± 0.76 | 0.2 | 0.063 | 0.05 | 3.79 |
| verbatim, self 1, trait 0 | 5/5 | 10 | 1.00 | 1.9 ± 2.5 | **1.00** (n = 3) | 0.00 ± 0.00 | 0.37 ± 0.40 | 6.7 ± 0.5 | 0.027 | 4.83 ± 0.42 | 2.01 |
| verbatim, self 1, trait 1 | 5/5 | 9 | 1.00 | 1.0 ± 1.2 | **1.00** (n = 4) | **7.48 ± 1.00** | **4.34 ± 0.15** | 5.9 ± 0.6 | 0.330 ± 0.025 | 1.94 ± 0.44 | 2.01 |

**Self-reference.**
- **Without it nothing spreads.** With self = 0 the largest lineage stays
  at 20 cells or fewer, and the replicators hold 0.3 % of the lattice at
  the end. These are founders that rule 90's transients made and
  protection keeps.
- **The heredity reading for self = 0 measures nothing.** Its "heredity"
  for `derived` (0.66) is chance. The parents' own tapes were random, so
  a derived tape matches the mutated bit half the time, and the
  descendants never copy further.
- **With self = 1 every copy mode takes over.** Template, derived and
  verbatim grow a lineage of 16 cells by turn 9 to 11, hold half the
  lattice by turn 100 to 125 and 99 % by turn 200 to 375.

**Heredity.**
- **Tape heredity requires verbatim copying of unread bits.** It is
  exactly 1.00 for verbatim, and 0.00 for template and derived.
- **Derived copying is limited heredity, not none.** Its 16 free control
  bits are copied verbatim with the control word. Selection therefore
  still acts on control-word variants: Δtrait is +3.7 ± 0.8, while the up
  and down tape mutants show no response (log₂ 0.65 ± 2.30).
- **Template copying has neither.** No heredity and no response:
  Δtrait is +0.3, the same as the no-copy row (+0.33), which is founder
  noise.

**Selection.**
- **It needs all three: trait, self and some heredity.**
- **Verbatim with the trait** makes the up mutants about 180 times as
  prolific as the down mutants (log₂ 7.5 ± 1.0). The population's trait
  rises from about 4 to 8 (Δ +4.3 ± 0.2).
- **With the trait inert** the same contrast is exactly 0. This is the
  required negative control.

The mu = 0 table (data) gives the same pattern: verbatim/self/trait has
log₂ up/down 10.0 ± 0.0 and Δtrait +3.4 ± 0.9, and heredity is 1.00 versus
0.00.

### 2. Emergence: the novelty supply decides, and the decoder supplies none

Verbatim, self, trait, medium off. The table gives the seeds with a
lineage of at least 16 cells, and the median turn at which it appeared.

| m (p = 2⁻ᵐ) | id, mu 0 | id, mu 10⁻³ | r90, mu 0 | r90, mu 10⁻³ | dec, mu 0 | dec, mu 10⁻³ |
|---|---|---|---|---|---|---|
| 8 | 5/5, t 6 | 5/5, 6 | 5/5, 6 | 5/5, 6 | 5/5, 6 | 5/5, 6 |
| 12 | 5/5, 8 | 5/5, 8 | 5/5, 8 | 5/5, 8 | 5/5, 8 | 5/5, 8 |
| 16 | 2/5, 9 | 2/5, 9 | 5/5, 9 | 5/5, 9 | 2/5, 9 | 2/5, 9 |
| 20 | 0/5 | 0/5 | 4/5, 22 | 4/5, 22 | 0/5 | 0/5 |
| 24 | 0/5 | 0/5 | 1/5, 66 | 2/5, 66 | 0/5 | 0/5 |

**Where replicators come from.**
- **Under the identity and the decoder they come only from the random
  start.** These are the seeds with a matching cell at turn 0
  (expectation N·2⁻ᵐ).
- **Rule 90's 64-turn transient is a supply of new states.** About 64
  fresh states per cell before the cell reaches zero, so it finds motifs
  that are 16 times rarer.
- **The decoder supplies none.** Its output is drawn from a printable
  dictionary and collapses to a 3-cycle within about 35 turns, so it never
  writes the motif. It supplies no novelty for the replicase to act on.
- **Mutation at 10⁻³ a cell a turn adds nothing measurable.** It creates a
  motif at a rate of about N·μ·m·2⁻ᵐ/128 ≈ 3·10⁻⁵ a turn.
- **The emergence time is set by p and the novelty rate.** Once a match
  exists the takeover is fast: 99 % of the lattice by turn 200 to 375
  (rule 90).

### 3. The medium: an error threshold

Verbatim (or derived), self, trait, rule 90, mu = 10⁻³:

| medium (swap / median) | verbatim: lineage ≥ 16 | heredity | log₂ up/down | H₂ | distinct/N | derived: lineage ≥ 16 |
|---|---|---|---|---|---|---|
| off | 5/5 (t 9) | 1.00 | 7.5 ± 1.0 | 5.9 | 0.33 | 5/5 |
| 0.001 / 0 | 5/5 (9) | 1.00 | 6.1 ± 0.9 | 8.9 | 0.53 | 5/5 |
| 0.002 / 0 | 5/5 (12) | 1.00 | 4.9 ± 0.6 | 10.3 | 0.62 | 5/5 |
| 0.005 / 0 | 5/5 (18) | 1.00 | 0.9 (n = 1) | 14.4 | 0.83 | 5/5 |
| 0.01 / 0 | 5/5 (52) | 0.80 ± 0.23 | 2.1 ± 1.7 | 18.6 | 0.98 | 5/5 |
| 0.02 / 0 | 1/5 (1,142), extinct by turn 2,000 | – | – | > 27 | 1.00 | 0/5 |
| 0.05 / 0 | 0/5 | – | – | > 27 | 1.00 | 0/5 |
| 0 / 0.01 | 5/5 | 1.00 | 7.9 ± 0.6 | 6.5 | 0.36 | 5/5 |
| 0 / 0.1 | 5/5 | 0.95 ± 0.08 | 6.3 ± 0.6 | 10.1 | 0.61 | 5/5 |
| 0 / 1 | 2/5 (1,653) | – | – | 0.1 | 0.01 | 2/5 |
| mild 0.002 / 0.01 | 5/5 (11) | 0.99 ± 0.03 | 4.5 ± 1.3 | 10.8 | 0.66 | 5/5 |
| weak 0.05 / 0.1 | 0/5 | – | – | > 27 | 1.00 | 0/5 |
| strong ½ / 1 | 0/5 | – | – | 0.1 | 0.01 | 0/5 |

**An error threshold in Eigen's sense.**
- **Mixing destroys the motif faster than it can be copied** once the
  swap exceeds about 0.01, an exchange rate of about 0.02 per bit per
  phase. Replicators are founded by the hundred (about 1,000 per run at
  weak) and none survives.
- **Below the threshold the medium mutates the tape.** Distinct cells and
  H₂ rise towards the threshold (0.33 → 0.98, 5.9 → 18.6 bits),
  heredity begins to fail (0.80), and the selection response weakens.
- **The page's settings are far above the threshold.** At the uniform
  setting (½, 1) and at weak, no constructed replicator of this family
  survives, with or without heredity.
- **Settling at strength 1 copies by itself.** A 3×3 majority makes
  neighbours equal, so it competes with the replicase as a copier, but
  only of the local majority. Replicators emerged in only 2/5 runs.

### 4. Protection from the background map is a necessary built-in

With protect = 0, rule 90 or the decoder also rewrites replicators. Then
**0/5** runs grow a lineage, for both derived and verbatim (against 5/5
with protection under r90). A replicator must be exempt from the eraser
that acts on everything else. This is the most "built in" of the
ingredients and must be stated as such.

### 5. Entropy: replication is an eraser, and heredity is what it spares

These are the end-of-run lattice entropies. For `id` and `dec` the values
come from the two seeds in which replicators emerged (m = 16, mu = 10⁻³,
medium off); once replicators fill the lattice the background no longer
matters.

| background | no copy | template | derived (trait 0 / 1) | verbatim (trait 0 / 1) |
|---|---|---|---|---|
| id | > 27 bits, distinct 1.00 | 0.0, 0.002 | 1.0–1.5 / 0.5–0.8, 0.004 / 0.001 | 4.3–6.4 / 5.0–5.2, 0.025 / 0.24 |
| r90 | 0.2, 0.055 | 0.0, 0.002 | 3.9 / 1.0, 0.006 / 0.001 | 6.7 / 5.9, 0.027 / 0.33 |
| dec | 1.6, 0.003 | – | 1.5–1.6 / 0.0–0.8 | 5.1–6.4 / 5.0–5.7 |

**Takeover destroys the background's information.**
- **On a random background** it is an eraser of the same order as the
  decoder: from more than 27 bits to between 0 and 6.
- **Template replication is the strongest eraser.** One state, 0 bits.
- **Against an equal eraser** (rule 90, decoder) the protected
  replicators keep more than the background (6 bits against 0.2).
- **What is kept is the heredity.** The mutational diversity stored in
  copied tapes (distinct 2.7 % → 33 % with the trait; mutation-selection
  balance at q = 1). Without heredity, derived and template copies stay
  at 0 to 4 bits.

**The running cost is the copy churn.**
- **Verbatim copying overwrites about 2 to 5 bits a cell a turn** (rule
  90, medium off), the order of rule 90's own 2 bits.
- **Template copying overwrites 0.04,** because its copies are identical
  to their targets.
- **Near the error threshold** (swap 0.01) the churn rises to 20 bits a
  cell a turn.
- **Heredity therefore costs entropy production.** The lattice must
  overwrite to keep variants that differ.

### 6. Reference: the plain decoder's mutant fate (Swarm F, kind 36)

**In isolation.**
- **Every single-bit mutant is repaired.** All 384 (3 states × 128 bits)
  return to the 3-cycle, in 3.2 steps on average.
- **Some come back out of phase.** 348 return in phase and 36 are shifted
  in phase; no new attractor is reached.
- **About half of all point mutations are erased in one step.** The
  decoder never reads those bits: on the lattice with the medium off, the
  footprint is only 0.54 cells per mutation at k = 1.

**On the lattice: twin runs**, 64 mutations at turn 300, measured against
an unmutated twin. "Novel" counts cells whose content occurs nowhere in
the twin.

| medium | footprint per mutation, k = 1 / 10 / 200 | novel per mutation, k = 1 / 10 / 50 / 200 |
|---|---|---|
| off | 0.54 / 0.10 / 0.09 | 0.54 / 0.04 / 0.00 / 0.00 |
| mild | 0.62 / 0.68 / 0.72 | 0.61 / 0.27 / 0.00 / 0.00 |
| weak | 3.5 / 246 / 256 | 3.4 / 231 / 240 / 240 |
| strong | 0.02 / 0.12 / 0.08 | 0.02 / 0.08 / 0.08 / 0.02 |

**How each medium treats a mutant.**
- **Medium off or mild: no mutant state survives 50 turns.** Novel cells
  are 0 in all seeds. The lasting footprint (0.09 to 0.7 cells) is phase
  shifts among the cycle's three states, which is one of three existing
  variants and nothing new.
- **Weak: damage spreads to the whole lattice.** This is chaotic
  divergence of a disordered lattice under content-hashed mixing, not
  copying.
- **Strong: settling repairs the flip before the decoder reads it.**

**The constructed rule behaves differently.**
- **Verbatim twin runs** (rule 90, off) have 5 to 244 novel cells from the
  48 mutants (turns 600 to 2,000), and the carriers equal the descendants.
- **Under mild mixing** the twin-novel count grows to thousands. This too
  is damage spreading through the content-hashed medium.
- **So the twin measure cannot tell heredity from chaos.** The lineage
  measure (heredity = carriers/descendants) is the one to report.

## Plain statements

1. **Heredity requires one ingredient: copying bits that the copier does
   not read** (verbatim tape). Template and derived copying give tape
   heredity 0.00; verbatim gives 1.00 (0.99 under mild mixing). The
   decoder has no such bits. It reads, and so erases, what it copies, and
   its mutants are repaired (384/384) or erased.
2. **Spread requires self-reference and protection.** Without the control
   word in the copy, lineages stay at 20 cells or fewer. Without exemption
   from the background map, 0/5 runs grow a lineage.
3. **Selection requires a trait coupled to the copy rate, plus some
   heredity.**
   - **Verbatim tapes:** log₂ up/down 7.5 ± 1.0 and Δtrait +4.3 ± 0.2.
   - **Inert trait:** exactly 0.
   - **Derived:** selection acts only on the 16 free control bits (Δtrait
     +3.7, no response to tape variants).
   - **Template:** none.
4. **Spontaneous emergence requires a background that makes new states.**
   Rule 90's transients do; the identity and the decoder do not. At
   p ≤ 2⁻²⁰ replicators arose only on rule 90 (4/5 at m = 20, 1–2/5 at
   m = 24).
5. **The lattice's mixing must stay below an error threshold** (swap
   around 0.01). The page's uniform and weak settings kill every
   constructed replicator.
6. **Entropy.**
   - **Takeover is an erasure:** from more than 27 bits to 0 to 6 bits a
     cell.
   - **Heredity keeps 4 to 6 bits a cell** of mutational variety, where
     non-hereditary copies keep 0 to 4.
   - **Heredity costs a copy churn of 2 to 5 bits a cell a turn,** the
     order of rule 90's calibrated 2 bits.

**How this answers "you built it in".** Yes: the match condition, the
copy, self-reference, protection and the trait are all built in. The
ablation shows that they are separable and that each is necessary for a
different property:
- self and protection for spread;
- unread verbatim bits for heredity;
- the trait for selection;
- a novelty-producing background for spontaneous origin;
- a quiet medium for persistence.

None of them is sufficient alone. The decoder's "replicators" lack the
heredity ingredient specifically, and the measured difference is
heredity 0 against 1 and repaired against inherited mutants. The claim
the paper can make is about which ingredient buys which property and at
what entropy cost. It cannot claim that heritable replicators emerge
unassisted.

## Null results and caveats

- **No replicator of this family survives the page's own media**
  (uniform ½/1, weak), so this is not a mechanism that operates in
  Keimli's default frames.
- **Under the identity and the decoder, emergence at m = 16 is a lottery
  of the initial random cells** (2/5 seeds). Mean ± over such bimodal
  outcomes is not meaningful; the x/5 counts are.
- **Mutation at 10⁻³ never created a replicator de novo.**
- **The heredity estimates rest on few descendants.** A neutral mutant
  injected into a full lattice has about 1 to 2 copied descendants at
  k = 100 (voter-model drift), so some seeds have none (the n < 5
  entries).
- **The "up/down" contrast for self = 0** (log₂ 1.25) is fecundity
  without further generations, not selection across generations.
- **Everything is at N = 128², T = 2,000, 5 seeds.** The rule is one
  hand-chosen family (motif in the control word's low bits, rotating
  direction, q from one byte); other constructions may move the
  thresholds.
- **Quenched hashing** makes identity plus mild mixing nearly periodic,
  with about 6,700 cells cycling and few new states. That is part of why
  the identity background supplies no novelty under mixing.

## Reproduce

```
node paper/experiments/replicase.mjs mode=grid set=all seeds=5 jobs=9      # 1,070 runs, about 2 h on 9 cores
node paper/experiments/replicase.mjs mode=grid set=template seeds=5 jobs=1 # 80 runs
node paper/experiments/replicase.mjs mode=decoder seeds=5
node paper/experiments/replicase.mjs mode=summary > paper/data/replicase/summary-table.md
```
