#!/usr/bin/env python3
"""Inline a compiled wasm module (and optional helper files) into a page template.

usage: build.py TEMPLATE WASM OUTPUT [--artifact] [--codec FILE] [--text FILE]

Placeholders: __WASM_BASE64__, __WASM_SIZE__, __CODEC_JS__, __BAND_JS__, __DECL_TEXT__.
Without --artifact the output is wrapped in a full HTML document skeleton so it
works from file://; with --artifact the fragment is emitted as-is.
"""
import argparse, base64, pathlib

ap = argparse.ArgumentParser()
ap.add_argument('template'); ap.add_argument('wasm'); ap.add_argument('output')
ap.add_argument('--artifact', action='store_true')
ap.add_argument('--codec'); ap.add_argument('--text'); ap.add_argument('--band')
a = ap.parse_args()

wasm = pathlib.Path(a.wasm).read_bytes()
page = pathlib.Path(a.template).read_text()
page = page.replace('__WASM_BASE64__', base64.b64encode(wasm).decode()).replace('__WASM_SIZE__', str(len(wasm)))
if a.codec:
    page = page.replace('__CODEC_JS__', pathlib.Path(a.codec).read_text())
if a.text:
    page = page.replace('__DECL_TEXT__', pathlib.Path(a.text).read_text())
if a.band:
    page = page.replace('__BAND_JS__', pathlib.Path(a.band).read_text())
if not a.artifact:
    page = ('<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
            '<meta name="viewport" content="width=device-width, initial-scale=1">\n</head>\n<body>\n'
            + page + '</body>\n</html>\n')
pathlib.Path(a.output).write_text(page)
print(f'built {a.output} ({len(page)} bytes, {a.wasm} {len(wasm)} bytes)')
