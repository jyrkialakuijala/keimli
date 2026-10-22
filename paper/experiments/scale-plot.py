# Figures for results/dictionary-size.md from paper/data/scale/summary.json: dictionary-size.png (richness against
# log2 size: types designed, realised by the map and alive on the lattice at turn 2,000 in both settings; the entropy
# of the type shares; the domains; the block change) and dictionary-size-snapshots.png (the frame at turns 200, 1,000
# and 2,000 and the uniform setting at 2,000, seed 1, for every other size).
import json, os, sys
import numpy as np
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from PIL import Image, ImageDraw
root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
S = os.path.join(root, 'paper/data/scale'); rows = json.load(open(os.path.join(S, 'summary.json')))['rows']
C = {'designed': '#52514e', 'map': '#2a78d6', 'frame': '#eb6834', 'uniform': '#1baf7a'}   # the reference palette: grey, blue, orange, aqua
n = [r['n'] for r in rows]
def col(key, sub=None, nozero=False):
    v = [((r.get(sub) or {}).get(key) if sub else r.get(key)) if (not sub or r.get(sub)) else np.nan for r in rows]
    return [np.nan if (nozero and x == 0) else x for x in v]   # a zero cannot sit on a log axis: left out (the table has it)
fig, ax = plt.subplots(2, 2, figsize=(11, 7.5))
a = ax[0, 0]
a.plot(n, col('designed'), '-', color=C['designed'], marker='o', ms=4, lw=1.5, label='types designed')
a.plot(n, col('reached'), '--', color=C['map'], marker='s', ms=4, lw=1.5, label='designed types reached by the map alone')
a.plot(n, col('alive', 'frame', True), '-', color=C['frame'], marker='^', ms=5, lw=1.5, label='alive at turn 2,000 (share ≥ 0.1 %), the frame')
a.plot(n, col('alive', 'uniform', True), '-', color=C['uniform'], marker='v', ms=5, lw=1.5, label='alive at turn 2,000, uniform (0.25, 0.5); none alive: no mark')
a.set_yscale('log', base=2); a.set_ylabel('types'); a.set_title('(a) types against the dictionary size', fontsize=10); a.legend(fontsize=7, loc='upper left')
a = ax[0, 1]
a.plot(n, col('entropy', 'frame'), '-', color=C['frame'], marker='^', ms=5, lw=1.5, label='the frame')
a.plot(n, col('entropy', 'uniform'), '-', color=C['uniform'], marker='v', ms=5, lw=1.5, label='uniform')
a.plot(n, [np.log2(max(1, d)) for d in col('designed')], ':', color=C['designed'], lw=1, label='log2 of the types designed (the maximum)')
a.set_ylabel('Shannon entropy of the type shares at 2,000 (bits)'); a.set_title('(b) entropy of the type shares', fontsize=10); a.legend(fontsize=7)
a = ax[1, 0]
a.plot(n, col('domains', 'frame', True), '-', color=C['frame'], marker='^', ms=5, lw=1.5, label='the frame')
a.plot(n, col('domains', 'uniform', True), '-', color=C['uniform'], marker='v', ms=5, lw=1.5, label='uniform (none: no mark)')
a.set_yscale('log'); a.set_ylabel('domains at 2,000 (4-connected, 256²)'); a.set_xlabel('log2 of the dictionary size (= header bits)'); a.set_title('(c) domains', fontsize=10); a.legend(fontsize=7)
a = ax[1, 1]
a.plot(n, col('blockChange', 'frame'), '-', color=C['frame'], marker='^', ms=5, lw=1.5, label='the frame')
a.plot(n, col('blockChange', 'uniform'), '-', color=C['uniform'], marker='v', ms=5, lw=1.5, label='uniform')
a.plot(n, col('transient', 'frame'), '--', color=C['frame'], lw=1, label='transient share at 2,000, the frame')
a.plot(n, col('transient', 'uniform'), '--', color=C['uniform'], lw=1, label='transient share, uniform')
a.set_ylim(0, 1); a.set_ylabel('share'); a.set_xlabel('log2 of the dictionary size (= header bits)'); a.set_title('(d) block change at 2,000 (type differs from turn 1,800)\nand the transient share', fontsize=9); a.legend(fontsize=7)
for a in ax.flat: a.set_xticks(range(8, 25, 2)); a.grid(alpha=0.25, lw=0.5)
fig.suptitle('One construction at every size 2^8 .. 2^24: 256², 2,000 turns, three settling passes, rotating order, quenched hashing, 3 seeds', fontsize=10)
fig.tight_layout(); fig.savefig(os.path.join(root, 'paper/figures/dictionary-size.png'), dpi=130); print('dictionary-size.png')
# the snapshot sheet
sizes = [8, 10, 12, 14, 16, 18, 20, 22, 24]; cols = [('frame', 200), ('frame', 1000), ('frame', 2000), ('uniform', 2000)]; T = 128; pad = 4; left = 70; top = 22
sheet = Image.new('RGB', (left + len(cols) * (T + pad), top + len(sizes) * (T + pad)), 'white'); d = ImageDraw.Draw(sheet)
for j, (setting, t) in enumerate(cols): d.text((left + j * (T + pad) + 4, 4), f'{setting} t = {t}', fill='black')
for i, s in enumerate(sizes):
    d.text((4, top + i * (T + pad) + T // 2 - 6), f'2^{s}', fill='black')
    for j, (setting, t) in enumerate(cols):
        f = os.path.join(S, 'png', f'ca-size-{s:02d}-{setting}-s1-n256-t{t:04d}.png')
        if os.path.exists(f): sheet.paste(Image.open(f).resize((T, T), Image.BOX), (left + j * (T + pad), top + i * (T + pad)))
sheet.save(os.path.join(root, 'paper/data/scale/dictionary-size-snapshots-full.png')); sheet.quantize(256, method=Image.Quantize.MEDIANCUT).save(os.path.join(root, 'paper/figures/dictionary-size-snapshots.png'), optimize=True); print('dictionary-size-snapshots.png')
