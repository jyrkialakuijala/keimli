#!/usr/bin/env python3
"""Assemble the article draft from the Markdown sections under paper/ into one HTML page and print it to PDF with
headless Chrome. Citation keys in square brackets ([dewdney1984], [ray1991, adami1994]) become numbered references
drawn from paper/references.bib; unknown keys are left as they are and listed at the end.
Usage: python3 tools/paper-pdf.py [out.pdf]   (default paper/draft/keimli-draft.pdf)"""
import re, sys, os, subprocess, html, datetime
import markdown

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
paper = os.path.join(root, 'paper')
out_pdf = sys.argv[1] if len(sys.argv) > 1 else os.path.join(paper, 'draft', 'keimli-draft.pdf')
os.makedirs(os.path.dirname(out_pdf), exist_ok=True)

# ---- the bibliography
def parse_bib(path):
    txt = open(path, encoding='utf8').read()
    entries = {}
    for m in re.finditer(r'@(\w+)\s*\{\s*([^,\s]+)\s*,', txt):
        start = m.end(); depth = 1; i = start
        while i < len(txt) and depth:
            if txt[i] == '{': depth += 1
            elif txt[i] == '}': depth -= 1
            i += 1
        body = txt[start:i - 1]
        fields = {}
        for fm in re.finditer(r'(\w+)\s*=\s*(\{(?:[^{}]|\{[^{}]*\})*\}|"[^"]*"|[^,\n]+)', body):
            v = fm.group(2).strip()
            if v[:1] in '{"': v = v[1:-1]
            fields[fm.group(1).lower()] = re.sub(r'[{}]', '', v).strip()
        entries[m.group(2)] = (m.group(1).lower(), fields)
    return entries

ACC = {'\\"u': 'ü', '\\"o': 'ö', '\\"a': 'ä', "\\'e": 'é', "\\'a": 'á', "\\'o": 'ó', "\\'i": 'í', '\\`e': 'è', '\\^o': 'ô', '\\~n': 'ñ', '\\c{c}': 'ç', '\\v{c}': 'č', '\\v{s}': 'š', '--': '–', '``': '“', "''": '”'}
def deaccent(v):
    for k, u in ACC.items(): v = v.replace(k, u)
    return v
def fmt_ref(key, kind, f):
    f = {k: deaccent(v) for k, v in f.items()}
    au = f.get('author', '').replace(' and ', ', ')
    au = re.sub(r'\s+', ' ', au)
    title = f.get('title', '')
    year = f.get('year', '')
    where = f.get('journal') or f.get('booktitle') or f.get('publisher') or f.get('howpublished') or ''
    vol = f.get('volume', ''); pages = f.get('pages', '')
    bits = [b for b in [au, f'“{title}”' if title else '', where, (f'{vol}' if vol else '') + (f', {pages}' if pages else ''), year] if b]
    s = '. '.join(bits).replace('..', '.')
    if f.get('verified', '').lower() == 'no': s += ' [unverified]'
    return s

bib = parse_bib(os.path.join(paper, 'references.bib'))

# ---- the sections, in order
sections = [
    ('INTRODUCTION.md', None),
    ('METHODS.md', None),
    ('RESULTS_REPLICATORS.md', None),
]
front = f"""# Keimli: a decompressive cellular automaton

**Jyrki Alakuijala**

*Draft assembled {datetime.date.today().isoformat()} from the section files under `paper/`. Sections not yet drafted are listed at the end.*

## Abstract

Artificial life runs either programs, which give the richest phenomena but are general computations that can only be understood by being run, or rules, which are tractable but compute nothing. We propose a lattice whose local rule is a decompressor: each cell's 128 bits are read once as a Brotli-like stream against a shared dictionary and the decoded bytes replace the cell, so that every cell is a program that is run every turn, while the rule is a fixed-depth map, linear in the cell's size, whose image, fixed points and cycles can be sampled, enumerated and even prescribed. The decompression alone only repeats; we manage the entropy around it with two classical automata, neighbours trading bits and bit planes smoothed by majority, whose strengths vary across the image so that one frame holds the whole parameter range. The construction separates the two things a running program does, the subtle entropy reduction of its memory and the finesse of computation itself: the decoder has the first in full and the second not at all. We show that the replicators of computational life are, here, fixed points and short cycles of the rewriting map, listed by census and built by design, that their spread is the work of the medium, and that late and elaborate appearances are those of rare attractors in a slow medium rather than of computation. Twenty-five emulated processors on the same lattice form the comparison arm. The lattice, its decoders and processors, and every experiment run in the browser from a single page, which is the artifact.
"""
body_md = [front]
for fname, title in sections:
    p = os.path.join(paper, fname)
    txt = open(p, encoding='utf8').read()
    # drop the italic drafting note at the top (first paragraph starting with *A ...*)
    txt = re.sub(r'^(# [^\n]*\n)\n\*[^\n]*(\n[^\n]*)*?\*\n', r'\1\n', txt, count=1, flags=re.M)
    body_md.append(txt)
todo = """# Sections still to draft

3 Related work (the map is in `RELATED_WORK.md`); 4 The decoder as a map and the designed dictionaries (`results/decoder-map.md`, `results/design-gray3.md`); 5 Ablations, scans and the one-frame diagram (`results/ablation-*.md`, `results/swap-order.md`, `results/life-vote.md`); 5.y Type, invasion and coexistence (`results/design-gray3.md`); 6 The processors and the comparison; 7 Discussion. The replicator Monte Carlo (`experiments/replicators.mjs`) is running and will give Section 5.x its table.
"""
figs = []
fdir = os.path.join(paper, 'figures')
captions = {
    'replicators-takeover.png': 'Figure R1. Takeover by the leading type: the share of cells on the most common cycle against the turn, one panel per dictionary, every seed a line; blue the uniform setting (swap ½, median 1), orange the page frame; dotted 128², solid 256². Every type that ever mattered is present as soon as its period can be seen (a k-cycle from turn 2k − 1); what differs is how fast, and whether, it takes the lattice. The type leading at the end is the full line, the others thin: under the frame the large-basin cycle of Brotli 12 and 13 rises first and gives way to a fixed point.',
    'replicators-groups.png': 'Figure R3. Takeover curves by kind of rewriting rule: the share of the type leading at the end, median over seeds, one curve per dictionary or processor; searched dictionaries, texts, designed dictionaries and processors in the four panels.',
    'replicators-basin-vs-takeover.png': 'Figure R2. The turn at which the leading type held half the cells against its basin under the decoder alone, per seed. Under the uniform setting the takeover takes 24 to 80 turns whatever the basin; under the frame the time falls with the basin from about a thousand turns at 0.3 % to forty at 100 %, and the winner can be a fixed point whose basin is a three-hundredth of the leading cycle\'s.',
}
if os.path.isdir(fdir):
    for fn in sorted(os.listdir(fdir)):
        if fn.endswith('.png'): figs.append(f'<figure><img src="{os.path.join(fdir, fn)}" style="width:100%"><figcaption>{html.escape(captions.get(fn, fn))}</figcaption></figure>')
if figs: body_md.append('# Figures\n\n' + '\n\n'.join(figs))
body_md.append(todo)
md = '\n\n'.join(body_md)

# ---- citations: [key, key] -> [n, m]
cited = []
def cite(m):
    keys = [k.strip() for k in m.group(1).split(',')]
    if not all(re.fullmatch(r'[A-Za-z][A-Za-z0-9]*\d{4}[a-z]?', k) for k in keys): return m.group(0)
    nums = []
    for k in keys:
        if k not in cited: cited.append(k)
        nums.append(str(cited.index(k) + 1))
    return '[' + ', '.join(nums) + ']'
md = re.sub(r'\[([A-Za-z][A-Za-z0-9]*\d{4}[a-z]?(?:\s*,\s*[A-Za-z][A-Za-z0-9]*\d{4}[a-z]?)*)\]', cite, md)
refs = ['# References', '']
missing = []
for i, k in enumerate(cited):
    if k in bib: kind, f = bib[k]; refs.append(f'{i + 1}. {html.escape(fmt_ref(k, kind, f))}')
    else: refs.append(f'{i + 1}. {k} (not in references.bib)'); missing.append(k)
md += '\n\n' + '\n'.join(refs) + '\n'

body = markdown.markdown(md, extensions=['tables', 'smarty'])
page = f"""<!doctype html><html><head><meta charset="utf-8"><title>Keimli draft</title>
<style>
@page {{ size: A4; margin: 22mm 20mm; }}
body {{ font-family: "Source Serif Pro", "Georgia", "Times New Roman", serif; font-size: 10.5pt; line-height: 1.42; color: #111; max-width: 170mm; margin: 0 auto; }}
h1 {{ font-size: 17pt; margin: 1.4em 0 0.5em; }} h2 {{ font-size: 12.5pt; margin: 1.3em 0 0.4em; }} h3 {{ font-size: 11pt; }}
p {{ text-align: justify; margin: 0 0 0.75em; }} em {{ font-style: italic; }}
code {{ font-family: "DejaVu Sans Mono", monospace; font-size: 8.8pt; }}
table {{ border-collapse: collapse; font-size: 9pt; margin: 0.6em 0; }} td, th {{ border-bottom: 1px solid #999; padding: 2px 6px; text-align: left; vertical-align: top; }}
ol {{ padding-left: 1.4em; }} li {{ margin-bottom: 0.3em; }}
figure {{ margin: 1em 0; page-break-inside: avoid; }} figcaption {{ font-size: 9pt; color: #333; margin-top: 0.3em; text-align: justify; }}
</style></head><body>{body}</body></html>"""
out_html = out_pdf[:-4] + '.html'
open(out_html, 'w', encoding='utf8').write(page)
subprocess.run(['google-chrome', '--headless=new', '--disable-gpu', '--no-sandbox', '--no-pdf-header-footer', f'--print-to-pdf={out_pdf}', 'file://' + out_html], check=True, capture_output=True)
print(f'{out_pdf}: {len(cited)} references cited' + (f', missing from the bibliography: {", ".join(missing)}' if missing else ''))
