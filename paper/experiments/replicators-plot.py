#!/usr/bin/env python3
"""Figures for the replicator Monte Carlo (replicators.mjs): the takeover curves of the leading species per dictionary
and setting, and the takeover time against the basin. Reads paper/data/replicators/*.json, writes paper/figures/."""
import json, glob, os, re, math
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt

root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ddir = os.path.join(root, 'paper', 'data', 'replicators'); fdir = os.path.join(root, 'paper', 'figures'); os.makedirs(fdir, exist_ok=True)
NAMES = {'ca-swarm-f': 'Swarm F', 'ca-brotli-1': 'Brotli 1', 'ca-brotli-12': 'Brotli 12', 'ca-brotli-13': 'Brotli 13', 'declaration': 'Declaration',
         'ca-gray3c': '3 Gray 8-cycles', 'ca-gray20c': '20 Gray 8-cycles', 'ca-gray32c': '32 Gray 8-cycles', 'ca-cyc5to12': 'cycles 5 to 12'}
CPU = {2: 'Brainfuck', 6: 'Z80', 7: '6502', 8: '8080', 9: 'Subleq', 10: 'CHIP-8', 11: '4004', 12: 'SM83', 13: '8051', 14: '6809', 15: 'RISC-V', 19: 'PDP-8', 20: 'PDP-11', 21: '68000', 22: 'UNIVAC 1101', 23: 'VAX', 24: 'CDC 6600', 25: '68020', 26: '8086', 27: '80286', 28: '80386', 29: 'i860', 30: 'PIC1640', 43: 'Alpha', 44: 'PA-RISC', 47: 'Redcode'}
def name_of(d):
    if d in NAMES: return NAMES[d]
    if d.startswith('cpu'): return CPU.get(int(d[3:]), d)
    m = re.match(r'ca-gray(\d+)c', d)
    if m: return f'{m.group(1)} Gray 8-cycles'
    return d.replace('ca-', '').replace('brotli-', 'Brotli ').replace('swarm-', 'Swarm ').upper() if d.startswith('ca-swarm') else d.replace('ca-', '').replace('brotli-', 'Brotli ')
GROUPS = [('searched dictionaries', lambda d: d.startswith('ca-brotli') or d.startswith('ca-swarm')), ('texts', lambda d: not d.startswith('ca-') and not d.startswith('cpu')),
          ('designed dictionaries', lambda d: d.startswith('ca-gray') or d.startswith('ca-cyc')), ('processors', lambda d: d.startswith('cpu'))]
runs = []
for f in sorted(glob.glob(os.path.join(ddir, '*.json'))):
    if '-seed' in f: continue
    r = json.load(open(f)); r['file'] = f
    leads = {}
    for g in glob.glob(f[:-5] + '-seed*-lead.json'):
        seed = int(re.search(r'-seed(\d+)-lead', g).group(1)); leads[seed] = json.load(open(g))
    r['leads'] = leads; runs.append(r)
dicts = sorted({r['dict'] for r in runs}, key=lambda d: [i for i, (_, f) in enumerate(GROUPS) if f(d)] + [name_of(d)])
COL = {False: '#1f6fb2', True: '#d9541e'}   # uniform, frame
STYLE = {128: ':', 256: '-', 512: '--'}

# ---- figure 1: every type that held 1 % or more, its share against the turn (the leader at the end drawn full, the
# others thin), so that a change of leader shows as two crossing curves and not as a kink of one
import numpy as np
cols = 4 if len(dicts) > 9 else 3; rows_n = max(1, math.ceil(len(dicts) / cols))
fig, axes = plt.subplots(rows_n, cols, figsize=(3.4 * cols, 2.6 * rows_n + 1), sharex=True, sharey=True, squeeze=False)
for ax in axes.flat[len(dicts):]: ax.axis('off')
for ax, d in zip(axes.flat, dicts):
    for r in [x for x in runs if x['dict'] == d]:
        if r['turns'] > 2000: continue
        for seed, lead in r['leads'].items():
            if not lead or len(lead[0]) < 4: continue
            ids = {}
            for p in lead:
                for sid, sh in p[3].items(): ids.setdefault(sid, []).append((p[0] + 1, 100 * sh))
            final_leader = lead[-1][2]
            for sid, pts in ids.items():
                if max(v for _, v in pts) < 5: continue
                t, v = zip(*pts)
                ax.plot(t, v, STYLE.get(r['n'], '-'), color=COL[r['page']], lw=1.1 if sid == final_leader else 0.6, alpha=0.9 if sid == final_leader else 0.5)
    ax.set_title(name_of(d), fontsize=9); ax.set_xscale('log'); ax.set_ylim(0, 100); ax.grid(True, alpha=0.3)
for ax in axes[-1]: ax.set_xlabel('turn')
for ax in axes[:, 0]: ax.set_ylabel('share of cells (%)')
from matplotlib.lines import Line2D
h = [Line2D([0], [0], color=COL[False], lw=1.5), Line2D([0], [0], color=COL[True], lw=1.5), Line2D([0], [0], color='k', ls=':', lw=1.2), Line2D([0], [0], color='k', ls='-', lw=1.2), Line2D([0], [0], color='k', ls='--', lw=1.2)]
fig.legend(h, ['uniform: swap ½, median 1', 'the page frame', '128²', '256²', '512²'], loc='lower center', ncol=5, frameon=False, fontsize=9)
fig.suptitle('Every species that reached 5 % of the cells: its share against the turn, per seed (full line: the leader at the end)', fontsize=11)
fig.tight_layout(rect=(0, 0.04, 1, 0.97)); fig.savefig(os.path.join(fdir, 'replicators-takeover.png'), dpi=150); plt.close(fig)

# ---- figure 2: takeover time (to 50 %, else to 10 %) against the basin of the leader, per seed
fig, ax = plt.subplots(figsize=(7, 5))
for r in runs:
    if r['turns'] > 2000: continue
    by_seed = {}
    for row in r['rows']: by_seed.setdefault(row['seed'], []).append(row)
    for seed, rows in by_seed.items():
        lead = max(rows, key=lambda x: x['final'])
        if lead['basin'] <= 0: continue
        t = lead['t50'] if lead['t50'] is not None else lead['t10']
        if t is None: continue
        ax.scatter(100 * lead['basin'], t + 1, s=28 if r['n'] == 256 else 14, color=COL[r['page']], marker='o' if lead['t50'] is not None else 'v', alpha=0.8, edgecolor='none')
    lead = max(r['rows'], key=lambda x: x['final'])
    if r['n'] == 256 and lead['basin'] > 0 and (lead['t50'] is not None or lead['t10'] is not None):
        ax.annotate(name_of(r['dict']), (100 * lead['basin'], (lead['t50'] if lead['t50'] is not None else lead['t10']) + 1), fontsize=7, xytext=(3, 3), textcoords='offset points', color=COL[r['page']])
ax.set_xscale('log'); ax.set_yscale('log'); ax.set_xlabel("basin of the leading species under the decoder alone (% of random cells)"); ax.set_ylabel('turn at which it held 50 % of the cells (▼: 10 %)')

h = [Line2D([0], [0], marker='o', color=COL[False], ls=''), Line2D([0], [0], marker='o', color=COL[True], ls='')]
ax.legend(h, ['uniform: swap ½, median 1', 'the page frame'], frameon=False, fontsize=9)
ax.set_title('Takeover time against basin: the medium, not the basin, sets the pace', fontsize=10); ax.grid(True, alpha=0.3, which='both')
fig.tight_layout(); fig.savefig(os.path.join(fdir, 'replicators-basin-vs-takeover.png'), dpi=150); plt.close(fig)
# ---- figure 3: by group, the end leader's share (median over seeds) against the turn, one curve per dictionary or processor
fig, axes = plt.subplots(2, 2, figsize=(11, 8), sharex=True, sharey=True)
for ax, (gname, gf) in zip(axes.flat, GROUPS):
    for r in runs:
        if r['turns'] > 2000 or not gf(r['dict']) or r.get('salt'): continue
        curves = []
        for seed, lead in r['leads'].items():
            if not lead or len(lead[0]) < 4: continue
            fl = lead[-1][2]; curves.append([(p[0] + 1, 100 * p[3].get(fl, 0)) for p in lead])
        if not curves: continue
        T = [t for t, _ in curves[0]]; M = [float(np.median([c[i][1] for c in curves if i < len(c)])) for i in range(len(T))]
        ax.plot(T, M, STYLE.get(r['n'], '-'), color=COL[r['page']], lw=1.0, alpha=0.8)
        ax.annotate(name_of(r['dict']), (T[-1], M[-1]), fontsize=6, xytext=(2, 0), textcoords='offset points', color=COL[r['page']])
    ax.set_title(gname, fontsize=10); ax.set_xscale('log'); ax.set_ylim(0, 100); ax.grid(True, alpha=0.3)
for ax in axes[-1]: ax.set_xlabel('turn')
for ax in axes[:, 0]: ax.set_ylabel('share of the species leading at the end (%), median over seeds')
fig.legend(h[:2], ['uniform: swap ½, median 1', 'the page frame'], loc='lower center', ncol=2, frameon=False, fontsize=9)
fig.suptitle('Takeover curves by kind of rewriting rule', fontsize=11)
fig.tight_layout(rect=(0, 0.04, 1, 0.97)); fig.savefig(os.path.join(fdir, 'replicators-groups.png'), dpi=150); plt.close(fig)
print('figures written to', fdir)
