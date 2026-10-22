#!/usr/bin/env python3
"""Figure for results/dose-response.md: (left) the leading type's share of the lattice against the instruction budget,
processors on joined pairs, mean over seeds with the individual seeds as dots; (right) the 8-bit block entropy against
the budget, single cells, with the decoder and look-and-say as horizontal references."""
import json, glob, os, collections
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
D = os.path.join(root, 'paper', 'data', 'dose'); F = os.path.join(root, 'paper', 'figures')
NAMES = {2: 'Brainfuck', 6: 'Z80', 7: '6502', 9: 'Subleq', 15: 'RISC-V', 47: 'Redcode'}
COL = {2: '#7f8c8d', 6: '#2e86c1', 7: '#27ae60', 9: '#8e44ad', 15: '#d35400', 47: '#c0392b'}
runs = [json.load(open(f)) for f in glob.glob(f'{D}/*.json')]
fig, (a, b) = plt.subplots(1, 2, figsize=(11, 4.4))
for k in NAMES:
    pts = collections.defaultdict(list)
    for r in runs:
        if r['changer'] == k and r.get('pair'):
            for row in r['rows']: pts[row['steps']].append(100 * row['lattice']['leader'])
    if not pts: continue
    xs = sorted(pts); a.plot(xs, [sum(pts[x]) / len(pts[x]) for x in xs], '-o', color=COL[k], ms=3, label=NAMES[k])
    for x in xs:
        if len(pts[x]) > 1: a.scatter([x] * len(pts[x]), pts[x], s=8, color=COL[k], alpha=0.5)
    single = [r for r in runs if r['changer'] == k and not r.get('pair') and r.get('seed', 1) == 1]
    if single:
        rows = sorted(single[0]['rows'], key=lambda x: x['steps']); b.plot([x['steps'] for x in rows], [x['lattice']['block8'] for x in rows], '-o', color=COL[k], ms=3, label=NAMES[k])
for r in runs:
    if r['changer'] in (36, 58) and not r.get('pair'):
        v = r['rows'][0]['lattice']['block8']; name = 'decoder, ' + r['dict'].replace('ca-', '') if r['changer'] == 36 else 'look-and-say'
        b.axhline(v, ls='--', lw=0.8, color='k'); b.text(300, v, ' ' + name, fontsize=7, va='center')
for ax in (a, b): ax.set_xscale('log', base=2); ax.set_xlabel('instructions per cell per turn'); ax.grid(alpha=0.3)
a.set_ylabel('leading type, share of the lattice (%)'); a.set_title('Joined pairs (two programs share 32 bytes): takeover', fontsize=9); a.legend(fontsize=7)
b.set_ylabel('8-bit block entropy (bits per bit)'); b.set_title('Single cells: local order rises with the budget', fontsize=9); b.set_xlim(0.8, 2048)
fig.suptitle('Processor dose-response, 128², swap ½, median 1, turn 400', fontsize=10)
fig.tight_layout(rect=(0, 0, 1, 0.94)); fig.savefig(f'{F}/dose-response.png', dpi=150); print('written dose-response.png')
