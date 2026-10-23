#!/usr/bin/env python3
"""Inline a compiled wasm module (and optional helper files) into a page template.

usage: build.py TEMPLATE WASM OUTPUT [--artifact] [--codec FILE] [--text FILE] [--dicts MANIFEST]

Placeholders: __WASM_BASE64__, __WASM_SIZE__, __CODEC_JS__, __BAND_JS__, __DECL_TEXT__, __DICTS_JSON__ (the dictionaries of a
manifest with their texts; a manifest entry with a url is inlined gzip-compressed when its file is present, else left to be fetched).
Without --artifact the output is wrapped in a full HTML document skeleton so it
works from file://; with --artifact the fragment is emitted as-is.
"""
import argparse, base64, gzip, pathlib

ap = argparse.ArgumentParser()
ap.add_argument('template'); ap.add_argument('wasm'); ap.add_argument('output')
ap.add_argument('--artifact', action='store_true')
ap.add_argument('--codec'); ap.add_argument('--text'); ap.add_argument('--band'); ap.add_argument('--dicts')
a = ap.parse_args()

wasm = pathlib.Path(a.wasm).read_bytes()
page = pathlib.Path(a.template).read_text()
page = page.replace('__WASM_BASE64__', base64.b64encode(wasm).decode()).replace('__WASM_SIZE__', str(len(wasm)))
if a.codec:
    page = page.replace('__CODEC_JS__', pathlib.Path(a.codec).read_text())
if a.text:
    page = page.replace('__DECL_TEXT__', pathlib.Path(a.text).read_text())
if a.dicts:
    import json, unicodedata
    man = pathlib.Path(a.dicts); entries = json.loads(man.read_text(encoding='utf-8'))
    for e in entries:
        f = man.parent / e['file']
        if e.get('url'):   # a large dictionary: inlined gzip-compressed in base64 when its file is there (field gz, deterministic:
            if f.exists():   # no name or time in the header), else only its size from the manifest and the page fetches it from its url
                data = (unicodedata.normalize('NFC', f.read_text(encoding='utf-8')).strip('\n') + '\n').encode('utf-8')
                e['bytes'] = len(data); e['gz'] = base64.b64encode(gzip.compress(data, 9, mtime=0)).decode()
            elif 'bytes' not in e:
                raise SystemExit(f'{e["file"]} is absent and the manifest gives no byte count')
        else:
            e['text'] = unicodedata.normalize('NFC', f.read_text(encoding='utf-8')).strip('\n') + '\n'
    page = page.replace('__DICTS_JSON__', json.dumps(entries, ensure_ascii=False).replace('</', '<\\/'))
if a.band:
    page = page.replace('__BAND_JS__', pathlib.Path(a.band).read_text())
if not a.artifact:
    page = ('<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
            '<meta name="viewport" content="width=device-width, initial-scale=1">\n</head>\n<body>\n'
            + page + '</body>\n</html>\n')
pathlib.Path(a.output).write_text(page)
print(f'built {a.output} ({len(page)} bytes, {a.wasm} {len(wasm)} bytes)')
