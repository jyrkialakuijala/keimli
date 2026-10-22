# Figure for results/nucleation.md from paper/data/nucleation/*.json: (a) the share of seeds in which a disc grows
# against its radius (N1); (b) the effective radius of the R = 16 disc against time (the wall speed); (c) spontaneous
# appearance in a disordered sea: clusters at first 0.1 % against the lattice area (N2) and the median waiting time (N3).
import json, glob, sys, os
import numpy as np
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ddir = sys.argv[1] if len(sys.argv) > 1 else os.path.join(root, 'paper/data/nucleation')
out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(root, 'paper/figures/nucleation.png')
files = [json.load(open(f)) for f in glob.glob(os.path.join(ddir, '*.json'))]
fig, ax = plt.subplots(1, 3, figsize=(13.5, 4))
styles = {'ca-brotli-12': '-', 'ca-brotli-13': '--'}; names = {'ca-brotli-12': 'Brotli 12', 'ca-brotli-13': 'Brotli 13'}
colors = {'0.1/0.5': 'C0', '0.25/0.5': 'C2', '0.5/0.5': 'C3', '0.1/0.75': 'C1'}
for d in styles:
    rad = [f for f in files if f['dict'] == d and f['mode'] == 'radius']
    for s in colors:
        p, m = map(float, s.split('/')); fl = [f for f in rad if f['p'] == p and f['m'] == m]
        if not fl: continue
        R = sorted({r['r'] for f in fl for r in f['runs']})
        pg = [100 * np.mean([r['xT'] >= 0.5 for f in fl for r in f['runs'] if r['r'] == rr]) for rr in R]
        ax[0].plot(R, pg, styles[d], color=colors[s], marker='o', ms=4, label=f'{names[d]} {s}')
        tr = [r['track'] for f in fl for r in f['runs'] if r['r'] == 16]
        if tr:
            N = fl[0]['n'] ** 2; t = [z[0] for z in tr[0]]; rad_t = np.mean([[np.sqrt(z[1] * N / np.pi) for z in k] for k in tr], axis=0)
            ax[1].plot(t, rad_t, styles[d], color=colors[s], label=f'{names[d]} {s}')
ax[0].set_xlabel('disc radius R (cells)'); ax[0].set_ylabel('seeds in which the disc grows, %'); ax[0].set_title('(a) N1: a critical radius against an in-phase sea\n(10 seeds a point)', fontsize=9); ax[0].legend(fontsize=6)
ax[1].set_xlabel('turn'); ax[1].set_ylabel('effective radius √(share·N/π), cells'); ax[1].set_title('(b) the R = 16 disc: the radius grows at a constant speed\n(128²; 72 is the whole lattice)', fontsize=9); ax[1].legend(fontsize=6); ax[1].set_xlim(0, 1000)
for d in styles:
    sp = [f for f in files if f['dict'] == d and f['mode'] == 'spontaneous' and f['runs'][0]['q'] == 1]
    for s in ['0.1/0.5', '0.25/0.5', '0.5/0.5']:
        p, m = map(float, s.split('/')); sizes = [64, 128, 256]; cl = []; wt = []
        for n in sizes:
            rr = [f['runs'][0] for f in sp if f['p'] == p and f['m'] == m and f['n'] == n]
            c = [next((z[3] for z in r['track'] if z[1] >= 0.001), np.nan) for r in rr]; cl.append(np.nanmean(c) if rr else np.nan)
            w = [r['first'] for r in rr if r['first'] is not None]; wt.append(np.median(w) if w else np.nan)
        ax[2].plot([n * n for n in sizes], cl, styles[d], color=colors[s], marker='o', ms=4, label=f'{names[d]} {s}')
ax[2].plot([64 ** 2, 256 ** 2], [1.5, 1.5 * 16], ':', color='grey', lw=1, label='∝ area')
ax[2].set_xscale('log', base=2); ax[2].set_yscale('log', base=2); ax[2].set_xlabel('lattice area (cells)'); ax[2].set_ylabel('clusters of X when X first reaches 0.1 %')
ax[2].set_title('(c) N2: in a disordered sea X starts as a few clusters,\ntheir number scaling with the area', fontsize=9); ax[2].legend(fontsize=6)
plt.tight_layout(); plt.savefig(out, dpi=130); print('written', out)
