# Entropy decrease through local changers

Source: `src/changers/` — `decode.wat` (the entry point and the LZ
decoder), `codec.js` (code tables, memory layout, the byte colour LUT),
`declaration.txt` (the dictionary), `brainfuck.wat`, `simple.wat`,
`dct.wat`, and `cpu/` for the emulated machines (see [cpus.md](cpus.md)).
Tests: `test/mix.test.mjs` and `test/activity.test.mjs`.

A local changer takes a pixel's 16 bytes and produces 16 bytes. At the end of
every turn `change` runs the selected changer over every pixel and writes
the output back over it, so what the changer makes of a pixel becomes the
pixel's new content: the decompressed text, the Brainfuck tape, the memory
a CPU left behind. `decode_pixel` runs it on one pixel for the inspector and
the views without writing back.

The section's on/off box switches the rewrite off altogether; with it on,
the "Changer" box picks a mode: none, a transform (second box: do nothing,
invert, reverse, extremes, DCT, inverse DCT, the sorts), a decoder (second
box: the LZ decompressor, the ten decoders of kinds 31 to 40 and the
codebook, kind 45, the default) or a CPU (second box: Brainfuck and the twenty-five machines; a "CPU
steps" box appears with it).

## The entry point

`$decode` in `decode.wat` dispatches on the changer number in the parameter
block (`codec.js` keeps the numbering: 0 LZ, 1 and 2 Brainfuck (1 unused), 3 to 5 the
simple transforms, 6 to 15, 19 to 30, 43, 44 and 47 CPUs, 16 extremes, 17 and 18 DCT,
31 to 40 decoders, 41 and 42 the sorts),
and is itself the LZ decoder. The parameter block, output buffer, flags
(one byte per output byte, for the inspector) and the dictionary are placed
in memory by `Codec.install`, whose `LAYOUT` is the module's memory map.

## The LZ decompressor

Each pixel's 128 bits are expanded to exactly 128 bits of output against a
static dictionary, the Declaration of Independence, which is not part of
the image. The first ⌈log₂ N⌉ leading bits, 13 for the Declaration's
N = 8,122 bytes, are read as the start cursor, so every byte of the
dictionary is a start position (values past the end wrap to its start), and
the "LZ cursor offset" slider (0 to N, default 0) is added to that cursor,
again wrapping at the end of the text, so the start positions can be
shifted away from the dictionary's opening.

Every command is a prefix-coded copy length of 2..N bytes (N is the
"Decompression" slider, 2 to 16, default 3) followed by a 3-bit skip: the
cursor skips that many bytes, the copy is taken from the dictionary at the
cursor, and the cursor advances past it, wrapping at the end of the text.
Copies are the only source of output: there are no literals and no
distances, and neither the output nor the image is ever read back. The
length code weights all lengths equally, so shorter copies get shorter
codes; the resulting expected rate on random bits is reported, not tuned.
Unused input bits are ignored; a 1024-bit cap on input consumption remains
as a safety net. `codec.js` builds the length-limited code and its lookup
table.

On cell pairs the decompressor runs as a link machine like the CPUs
(`$lz_step`, see the Links section): one copy command a step, with the bit
position, the dictionary cursor and the output position kept in the
machine's state between steps. Its memory is the joined pair, read for the
input bits as it stands at each step and written at the output position,
both wrapping around the 32 bytes like a CPU's addresses, so a machine can
read its own output back as commands and the decoder's output does not
stop at the cell's end as it does in the whole-cell decode. The first step
reads the start cursor from the leading header bits.

The "LZ cursor read" slider (1 to the dictionary size on a semi-logarithmic
scale: 1 to 8 one by one, then quarter octaves; `prm + 52`), or the number
box beside it for an exact value (the slider then moves to its nearest
stop, and moving the slider fills the box), sets the
range V the header is read over: the header is ceil(log₂ V) bits wide and
its value is the start position, wrapped round once when it is V or more
(with V = 5 the 3-bit values 6 and 7 read as 0 and 1), to which the constant "LZ cursor
offset" (`prm + 100`, never read from the pixel) is added before wrapping at
the end of the dictionary. V = 1 reads no header bits, so every pixel starts
at the offset; V = the dictionary size (the default) makes every byte a
start position with a 13-bit header; the LZ examples above use V = 5, a
3-bit header. The page starts in the codebook search's setting: a 128 × 128 grid,
the Brotli-like decoder on single cells with the 4,400-byte "Swarm search F"
dictionary, 6 skipped bits, a cursor read of 4096 (a 12-bit header), offset 0 and both
entropy stages on; the LZ decompressor with the Declaration, 6 skipped
bits and an offset of 50 is the setting the examples above describe.

The "Skip bits" slider (0 to 16, `prm + 40`) makes the decoder skip that
many bits of the pixel before it reads the cursor header, so the header and
the commands move along the pixel; the link machine's first step skips them
too. The ten decoders of kinds 31 to 40 start reading after the same skip
(a byte-oriented format reads its bytes from that bit on, so a skip that is
not a multiple of 8 shifts its byte frame; the PNG decoder sees the cell
from the skip on). The CPUs and the transforms ignore it.

## Brainfuck

Each pixel's 16 bytes run as a Brainfuck program on a 16-cell circular
tape; the tape afterwards is the pixel's new content. Byte values 0–7 are
the commands `> < + - . , [ ]` in that order and any other value is a
comment, so the "Random bytes 0–7" start fills the field with programs. `.`
does nothing, `,` reads the program's own bytes cyclically, unmatched
brackets are ignored, and execution stops after 1024 steps. The tape starts
as a copy of the pixel (changer 2; changer 1, the same interpreter on an
empty tape, is still in the module but no longer offered, since a program
on an empty tape rarely leaves anything in it that survives). The
inspector shows the disassembled program and the tape with changed cells
highlighted.

## Simple transforms

"Do nothing" (identity), "Invert" (all 128 bits flipped), "Reverse bytes"
(the 16 bytes in reverse order) and "Extremes ±23": the largest of the 16
bytes, the first one on ties, loses 23, the byte after it gains 11 and the
byte before it gains 13, and the smallest, the first one on ties, gains 23,
the byte after it loses 11 and the byte before it loses 13; the two sets add
where they overlap, modulo 256 with the index wrapping around the 16 bytes.
A flat cell, whose largest and smallest byte are the same, is a fixed point.
These are useful as controls and as a slow, deterministic drift.

"Sort bytes" (kind 41) rewrites the cell's bytes in ascending order, and
"Primes first" (kind 42) puts the bytes whose value is a prime number first
in ascending order and the other values after them, also ascending (an
insertion sort on the key value + 256 for a non-prime; primality by trial
division). On a pair they sort the 32 bytes of the joint cell. Both are
fixed points after one turn, so what they show is the swapping and the
mutation: the cell becomes a sorted histogram of what it receives.

## DCT and inverse DCT

Both treat the cell's bytes as signed samples (byte − 128), N = 16 of
them, or 32 when the changer runs on a joint cell of a pair. The forward
transform replaces them with their N-point DCT-II coefficients at half the
orthonormal scale, so byte 0 becomes the mean and the rest the frequencies
in rising order; the inverse rebuilds the samples from coefficients read the
same way. Both offset by 128 and clamp to 0..255. The cosines come from a
33-entry table cos(πm/64), m = 0..32, that `Codec.install` writes at
`LAYOUT.COS`, extended by symmetry (`$cos64`). A DCT followed by an inverse
DCT returns a pixel, or a pair, to within rounding unless a coefficient
clipped. On a concatenated pair the first cell receives the 16 lowest
frequencies and the second the 16 highest; on the interleaved joinings the
coefficients are dealt back to the two cells bit, nibble or byte by byte.

## Decoders

Kinds 31 to 40, 45 and 46 (`src/changers/codecs.wat`) read the cell as a coded signal
rather than as a program: the information-centric changers. Every one of
them reads the `$cw`-byte cell as a bitstream or byte stream that starts
after the "Skip bits" and wraps at the end of the cell (reads are capped at
1024 bits), writes its output from
byte 0, and leaves the cell's own bytes where its output falls short. The
LZ77 formats among them (Deflate, LZ4, Snappy, the Brotli-like) take a
*preset dictionary*, the way zlib, LZ4 and Snappy accept one: a
back-reference reaching past the start of the output reads the Declaration
text ending at a window position that the decoder reads from the stream
first, as the LZ decompressor reads its start cursor: ceil(log₂ V) bits for
the "LZ cursor read" range V (LSB-first for Deflate and the Brotli-like,
MSB-first for LZ4 and Snappy), the value (wrapped round once when V or
more) plus the constant "LZ cursor
offset" (`prm + 100`), wrapping at the end of the text; V = 1 reads no bits
and the window ends at the offset. `prm + 48` holds the window for them. The
output flags carry the parity of the command that produced each byte (a
nibble, letter, literal run, match or sample), or for the two image
decoders whether the byte changed, and `prm + 48` holds the bits consumed.
The return value is the bits consumed in the high bits and the number of
bytes that differ from the input in the low 8.

| kind | decoder | what the bits are |
|---|---|---|
| 31 | prefix code | 16 code lengths of 3 bits (1..8) for the nibbles 0..F, assigned canonically as in Deflate, then nibbles read bit by bit (MSB-first); a code matching nothing within 8 bits reads as 0; two nibbles make a byte |
| 32 | Morse | a telegraph key, MSB-first: a run of one 1 is a dot, two or more a dash; one 0 separates elements, two end the letter, three or more the word (a space); letters come out in lower case from a 128-entry table indexed by 1 followed by the elements, unknown patterns as `?`, the rest of the cell is spaces |
| 33 | Deflate | gzip's fixed Huffman block (BTYPE 01) without header or checksum: 7/8/9-bit literal/length codes, lengths 257..285 and 5-bit distance codes with their extra bits; end of block continues with the next; 286/287 count as 285, distance codes 30/31 wrap |
| 34 | LZ4 | the block format: token, literals, 2-byte little-endian offset, match (offset 0 counts as 1; length extensions read up to 4 bytes) |
| 35 | Snappy | a varint preamble (skipped), then literal, copy-1, copy-2 and copy-4 tags as in the format |
| 36 | Brotli-like | not the format, a small cousin: insert length (2-bit code: 0, 1, 2+1 bit, 4+2 bits) and 8-bit literals, copy length (2, 3, 4+1 bit, 6+3 bits), and a distance that is either one of Brotli's 16 short codes on the ring of the last four distances (starting 4 11 15 16, pushed by all but short code 0) or an explicit 1 + 6 bits; a distance past the output is a dictionary word with a 2-bit transform (as is, first letter upper case, upper case, lower case); bits LSB-first |
| 37 | PNG filters | rows of 4 bytes, a filter byte (low 3 bits mod 5: None Sub Up Average Paeth) and 3 one-byte samples, reconstructed from the left, upper and upper-left reconstructed neighbours (zero outside); the filter bytes are kept, so the cell integrates itself turn after turn |
| 38 | JPEG | one 4×4 block with a restart before it (DC predictor 0): the DC category and bits, run/size pairs for the 15 AC coefficients in zigzag order, with the standard luminance Huffman tables of Annex K (K.3 and K.5), MSB-first; EOB ends the block, ZRL skips past it, a code matching nothing is EOB; dequantised with the top-left 4×4 of the K.1 luminance quantiser, 4-point inverse DCT per axis, level shift, clamp; a pair is two blocks |
| 39 | VP8 boolean decoder | WebP's arithmetic coder (RFC 6386 section 7) fed the cell's bytes; each output byte is eight binary decisions down a tree whose probabilities are an order-1 model of the Declaration (context: the previous output byte, a space to begin with; bigram counts smoothed towards the byte frequencies with 16 pseudo-counts), 256 × 256 bytes at `LAYOUT.VP8` built by `Codec.vp8Model` |
| 40 | Rice | a FLAC-style subframe: a 3-bit Rice parameter k, then per sample a unary quotient (zeros ended by a 1, at most 32) and k remainder bits, MSB-first; the folded value is a signed residual added to the previous sample (128 before the first) |

The tables (`Codec.decoderTables`, written at `LAYOUT.DEC` by the installer)
are the Deflate length and distance bases and extra bits, the Morse
alphabet, the JPEG code tables, quantiser and zigzag, and 1 KB of scratch for
the prefix code and the JPEG coefficients. The decoders are not link
machines: with Cells set to a pair joining they run once over the joint
cell like the transforms (the JPEG block as two cells).

Why these: the LZ decompressor of kind 0 has no literals and no distances
and so always writes dictionary text. The decoders span the other
possibilities an information-centric cell can have. Literals and
back-references into its own output (Deflate, LZ4, Snappy), a distance
cache and transforms (Brotli-like), an entropy code whose table is in the
cell itself (prefix), run lengths as symbols (Morse), prediction with coded
residuals (Rice, PNG), a transform code (JPEG) and an arithmetic code
against a language model (VP8), under which every bit string is a valid
code and decodes to text-like bytes.

**Codebook (45)** is the odd one out: not borrowed from a file format but
made for cellular-automaton dynamics with the entropy stages off, where
every cell, or every concatenated pair, iterates the decoder on its own
and the dictionary decides its fixed points and cycles. Before anything is
read, the second half of the cell is folded into the first two bytes as
the decoder sees them (byte 0 xor the even bytes of the second half, byte
1 xor its odd bytes; the cell itself is untouched), so in a pair each half
steers the other: the second half shifts the window and the first code of
the first half, while the first half's codes write most of the second.
Then come the skip bits, the cursor header (MSB-first, the window start as
for LZ4) and 10-bit codes read MSB-first until the output is full, each
giving the two dictionary bytes at (window + code · L / 1024) mod L and
the position after it, L being the text length, so neighbouring codes
land on neighbouring places of the dictionary. A 32-byte pair holds the
header and 16 codes with 89 bits to spare; the output is a chain of 16
dictionary bigrams, and reading those bigrams back as codes is the
iterated map. `tools/ca-search.mjs` looks for dictionaries whose map has several
attractors with balanced basins, short cycles and moderate transients.

**Bit codebook (46)** is the codebook with entries of 11, 12 or 13 bits,
decoded in place. The cell is copied to the output buffer and both read
and written there: after the skip bits and the cursor header the reader
takes 10-bit codes, and the writer, starting where the header ended, lays
down each code's entry, the bits of the dictionary bytes at
(window + code · L / 1024) mod L and the next, MSB-first, 11 + (first byte
mod 3) of them. Every entry puts the writer one to three bits further
ahead of the reader, so later codes are read from
bits the decoder itself has just written, and the stream wraps round the
end of the cell: the last bits land over the header, so the next decoding
starts from a window the previous one chose. Decoding stops when the
reader has been once round the cell, skip and header included; there is
no fold, the wrap is the feedback. Made for an 8-bit header (cursor read
256) over a 512-byte dictionary.

## Dictionaries

The LZ decompressor copies from a static dictionary, the four LZ77 decoders
take it as their preset dictionary, and the VP8 boolean decoder's order-1
model is built from it. The "Dictionary" box chooses it among short
public-domain texts in many scripts (`src/changers/dict/`, listed in
`manifest.json`, embedded into the page by `tools/build.py --dicts`). A
dictionary is its UTF-8 bytes: the text length, the cursor read range, the
cursor offset and the preset-dictionary windows are byte counts, and every
decoder treats the bytes as bytes; only the inspector decodes a window or an
output back to text for display. Changing the dictionary rebuilds the code
tables and the VP8 model and re-installs them in every worker; the sliders
that run over the text are clamped to the new length. The byte colours
stay those of the Declaration's alphabet, so a non-Latin text shows in the
darker opcode colours of the bytes above 127.

| id | bytes | text | author | language |
|---|---|---|---|---|
| declaration | 8,123 | US Declaration of Independence | Thomas Jefferson and the Second Continental Congress | English, Latin script, 1776 |
| nam-quoc-son-ha-han | 88 | Nam quốc sơn hà | anonymous (traditionally attributed to Lý Thường Kiệt) | Classical Chinese (Vietnamese Chữ Hán), Han script, 1077 |
| nam-quoc-son-ha-viet | 165 | Nam quoc son ha | anonymous (traditionally attributed to Lý Thường Kiệt) | Vietnamese (Sino-Vietnamese reading), Latin (Vietnamese alphabet) script, 1077 |
| azatutyun | 1,648 | Azatutyun (Liberty) | Mikael Nalbandian | Armenian, Armenian script, 1859 |
| nocturne | 955 | Nocturne | Eino Leino | Finnish, Latin script, 1903 |
| kalevala-1 | 2,486 | Kalevala, first poem (opening) | Elias Lönnrot (compiler), Finnish oral tradition | Finnish, Latin script, 1849 |
| qaro-kozum | 779 | Qaro ko'zum (Kara Ko'zum) | Alisher Navoiy | Uzbek (Chagatai Turkic), Latin (Uzbek Latin alphabet) script, 15th century |
| catullus-5 | 442 | Catullus 5 (Vivamus, mea Lesbia) | Gaius Valerius Catullus | Latin, Latin script, c. 55 BC |
| iroha | 275 | Iroha-uta | anonymous | Japanese (Classical), Hiragana (second stanza kanji and kana) script, c. 1000 (10th–11th century) |
| ya-vas-lyubil | 489 | Ya vas lyubil (I loved you) | Alexander Pushkin | Russian, Cyrillic script, 1829 |
| iliad-1 | 1,755 | Iliad, Book 1, lines 1–21 | Homer | Ancient Greek, Greek (polytonic) script, 8th century BC |
| psalm-23 | 1,027 | Tehillim 23 (Psalm 23) | traditional (attributed to David) | Biblical Hebrew, Hebrew (with vowel points and cantillation) script, antiquity (Masoretic text, c. 10th century AD) |
| hunminjeongeum | 707 | Hunminjeongeum eonhae, preface | King Sejong the Great | Middle Korean, Hangul (15th-century Old Hangul with tone marks and some Hanja) script, 1446 (eonhae edition 1459) |
| vepkhistqaosani | 3,062 | Vepkhistqaosani (The Knight in the Panther's Skin), prologue 1–6 | Shota Rustaveli | Georgian, Georgian (Mkhedruli) script, c. 1200 |
| don-quijote | 2,336 | Don Quixote, Part I, chapter I (opening) | Miguel de Cervantes | Spanish, Latin script, 1605 |
| bhagavad-gita-2 | 1,411 | Bhagavad Gita 2.45–2.50 | traditional (attributed to Vyasa) | Sanskrit, Devanagari script, c. 2nd century BC – 2nd century AD |
| voluspa | 1,502 | Voluspa, stanzas 1–10 | anonymous | Old Norse, Latin (Old Norse orthography) script, 10th century (Codex Regius c. 1270) |
| muallaqa | 1,622 | Mu'allaqa of Imru' al-Qais, verses 1–10 | Imru' al-Qais | Classical Arabic, Arabic (vocalized) script, 6th century |

Provenance (all public domain; the texts were fetched from the sources
given, not typed from memory):

- declaration: The full text; public domain as a US government work of 1776.
- nam-quoc-son-ha-han: The complete four-line poem in the original Chinese characters (the typographic spaces between characters in the Wikisource table were removed; the main reading 定分 is used); an 11th-century anonymous text, public domain. Source: <https://vi.wikisource.org/w/index.php?title=Nam_quốc_sơn_hà&action=raw>
- nam-quoc-son-ha-viet: Only the four-line Sino-Vietnamese reading: the verse translation 'Sông núi nước Nam vua Nam ở' is attributed to Trần Trọng Kim (d. 1953) in secondary web sources but could not be found in any public-domain edition read (his Việt Nam sử lược on Wikisource quotes only the Sino-Vietnamese reading), so it was omitted; the reading of an 11th-century text is public domain. Source: <https://vi.wikisource.org/w/index.php?title=Nam_quốc_sơn_hà&action=raw>
- azatutyun: The complete poem in six eight-line stanzas; Nalbandian died in 1866, so the text is public domain. Source: <https://hy.wikisource.org/w/index.php?title=Ազատություն_(Միքայել_Նալբանդյան)&action=raw>
- nocturne: The complete poem (three ten-line stanzas) from Talvi-yö; Leino died in 1926, so the text is public domain. Source: <https://fi.wikisource.org/w/index.php?title=Nocturne&action=raw>
- kalevala-1: The opening of the first poem of the 1849 Kalevala, 51 lines (Mieleni minun tekevi ... uuen aamun alkeheksi); Lönnrot died in 1884, public domain. Source: <https://fi.wikisource.org/w/index.php?title=Kalevala_-_Ensimm%C3%A4inen_runo&action=raw>
- qaro-kozum: The complete ghazal of eight couplets ('Qaro ko‘zum, kel-u, mardumliq emdi fan qilg‘il', radif 'qilg‘il', takhallus Navoiy in the last couplet) in Uzbek Latin script from the multilingual Wikisource; Navoiy died in 1501, so the text is public domain. Source: <https://wikisource.org/w/index.php?title=Qaro_ko‘zum...&action=raw>
- catullus-5: The complete 13-line poem from the F. W. Cornish edition (1904, Cornish d. 1916) with marginal line numbers removed; an ancient text, public domain. Source: <https://la.wikisource.org/w/index.php?title=Carmina_(Catullus,_ed._Cornish)/5&action=render>
- iroha: The complete 47-kana pangram in historical kana spelling, followed after a blank line by its traditional kanji-and-kana rendering as given on the same page; an anonymous Heian-period text, public domain. Source: <https://ja.wikipedia.org/w/index.php?title=いろは歌&action=raw>
- ya-vas-lyubil: The complete eight-line poem; Pushkin died in 1837, so the text is public domain. Source: <https://ru.wikisource.org/w/index.php?title=Я_вас_любил:_любовь_ещё,_быть_может_(Пушкин)&action=raw>
- iliad-1: The opening 21 lines (proem and the priest Chryses' plea) from the Monro–Allen Oxford text (1920, Allen d. 1950) with marginal line numbers removed; an ancient text, public domain. Source: <https://el.wikisource.org/w/index.php?title=Ιλιάς/Α&action=render>
- psalm-23: The complete six-verse psalm in the Masoretic text with niqqud and te'amim, verse numerals removed and each verse as a stanza; an ancient text, public domain. Source: <https://he.wikisource.org/w/index.php?title=תהלים_כג&action=render>
- hunminjeongeum: The eight-clause Korean preface of the Hunminjeongeum eonhae (Worin seokbo edition of 1459) in its original Old Hangul with side-dot tone marks, excluding the interlinear glosses; a 15th-century text, public domain. Source: <https://ko.wikisource.org/w/index.php?title=훈민정음언해&action=render>
- vepkhistqaosani: The first six quatrains of the prologue, stanza numbers removed; a 12th-century text, public domain. Source: <https://ka.wikisource.org/w/index.php?title=ვეფხისტყაოსანი/დასაწყისი&action=raw>
- don-quijote: The first paragraph of chapter I from the 1905 edition (with its orthography, e.g. 'á'); Cervantes died in 1616, so the text is public domain. Source: <https://es.wikisource.org/w/index.php?title=El_ingenioso_hidalgo_Don_Quijote_de_la_Mancha_(1905)/Tomo_I/Capítulo_I&action=render>
- bhagavad-gita-2: Verses 2.45 to 2.50 (including 2.47 karmaṇy evādhikāras te), each verse a two-line stanza with verse numerals removed; an ancient text, public domain. Source: <https://sa.wikisource.org/w/index.php?title=भगवद्गीता/साङ्ख्ययोगः&action=raw>
- voluspa: The first ten stanzas in Sophus Bugge's 1867 text in normalized spelling, stanza numbers removed; a medieval anonymous text, public domain. Source: <https://is.wikisource.org/w/index.php?title=Völuspá&action=raw>
- muallaqa: The first ten verses (qifā nabki), each verse a two-line stanza with the two hemistichs on separate lines; a pre-Islamic text, public domain. Source: <https://ar.wikisource.org/w/index.php?title=معلقة_امرئ_القيس&action=raw>

## Pairs: two cells changed together

The "Cells" box in the Local changer section can change two neighbouring
cells as one. For the LZ decompressor, the transforms and Brainfuck the pair
is columns 2i and 2i + 1: their 256 bits are joined into a 32-byte joint
cell, the changer runs once on it, and the result is split back by the same
mapping in reverse (`$join` and `$split` in `decode.wat`; the host sets
`pairMode` and this turn's `pairFlip` in the parameter block, and `change`
walks the pairs), the roles alternating from turn to turn so that neither
cell keeps the first role. For a CPU changer the same joinings define the
memory of the link CPUs of the next section, where every 4-connected pair
of pixels is a pair and the two roles are the two directions. Four joinings
are offered:

- **Concatenated.** A then B (B then A for the other role). A CPU then has
  32 bytes of memory, so a program in one cell can read and write the
  other; the decompressor reads its cursor and commands from 256 input
  bits and emits 32 bytes.
- **Bit-interleaved.** On even turns A's bits take the even positions of
  the joint cell and B's the odd ones; on odd turns the other way round.
  Every byte of the joint cell then mixes four bits of each cell, so
  whatever the changer does is spread over both.
- **Nibble-interleaved.** The 32 nibbles of each cell, counted from the
  low nibble of byte 0, are dealt alternately: A's nibble k becomes the
  low nibble of joint byte k and B's nibble k its high nibble (the other
  way round on odd turns). Every joint byte holds one nibble of each cell,
  so a changer that works on bytes couples the two cells four bits at a
  time, between the bit and the byte interleavings in grain.
- **Byte-interleaved.** A's byte k at joint byte 2k and B's at 2k + 1 on
  even turns, the other way round on odd turns. The bytes stay whole, so
  a CPU sees the two cells as alternating memory bytes and the
  decompressor's output alternates between them.

All four are permutations of the 256 bits, so the "do nothing" changer
leaves both cells as they were, and the copy back is the exact inverse of
the joining: the split de-interleaves what the join interleaved.

The "Segment influence" statistic measures, each turn and before the
changer runs, how much each half of a pair decides the other half's new
content (`influence` in `decode.wat`): every pair is decoded as it is,
then with the right pixel replaced by pseudo-random bits (its bits xor a
hash of the pair index and the turn; an inversion would leave the
codebook's parity folds unchanged), counting the bits of the left pixel's
new content that differ (B → A), then with the left pixel replaced,
counting the right pixel's differing bits (A → B). A is always
the left pixel, whatever the roles that turn. The page shows the mean
bits of 128 per pair and the share of pairs with any difference, for grids
up to 256 × 256; the measurement costs three extra decodings per pair.

The changers see the joint cell through the cell width `$cw` (16 or 32
bytes): memory accesses wrap at it, Brainfuck's program and tape have that
many cells, the simple transforms run over it, and the decompressor's bit
reader covers 256 bits, and the DCT has 32 points. The changers defined on
exactly 128 bits, the PDP-8, the UNIVAC 1101 and the CDC 6600, are handed
the joint cell as two consecutive 16-byte cells. The inspector always
decodes a single cell. A pair never crosses a row (the width is even), so
the band pipeline is unaffected; `test/band.test.mjs` runs pair
configurations through it. With pairs on, the inspector decodes the
selected pixel's joint cell (`decode_pair`), so its bit counts are those
of the 256-bit cell the changer sees, and it names the pixel's role.

## Links: a persistent CPU per pair of neighbours

With the "Cells" box on any pair joining, the CPU changers (Z80 and up,
kinds 6 to 15, 19 to 30, 43, 44 and 47) and the LZ decompressor (kind 0, one copy
command a step) change regime. Instead of a fresh machine
running 256 instructions over one cell, every link of the lattice has a
machine of its own whose registers persist from round to round. A link is
directed: the pair of horizontally or vertically adjacent pixels A, B
carries two links, A→B and B→A, with two separate machines. The A→B
machine's memory is the 32-byte joint cell of A and B with A in the first
role, under the selected joining (concatenated: A at addresses 0 to 15
followed by B at 16 to 31; byte-interleaved: A on the even addresses;
bit-interleaved: A on the even bits; nibble-interleaved: A on the low
nibbles), the B→A machine's the joint cell with B in the first
role. The joint cell is built when the instruction runs and split back
straight after, so under the bit and nibble interleavings a store into one
byte lands in both pixels. A round runs the four link phases in the swap-phase order
(UD0, LR0, UD1, LR1) on even rounds and in the reverse order (LR1, UD1,
LR0, UD0) on odd ones, because with one fixed order information travels
two cells down and right in a round but only one cell up and left, and the
lattice grew streaks along the down-right diagonal (the VAX link machines
showed it first): in each phase every pair of that phase runs one
instruction of its forward machine (left or top pixel first) and then one
of its backward machine, which sees what the forward one wrote. So a pixel
is visited by eight machines a round, four of them running code that starts
in the pixel itself, and each machine advances one instruction a round. A turn makes a number of rounds in a row (the
"CPU cycles per frame" box: any whole number, 2 by default; 0 leaves the machines
idle for the turn) before the lattice is drawn, so
by default each machine runs 2 instructions a turn, interleaved with its
neighbours' machines one instruction at a time. The "CPU reset" box says
how often the machines are reset to PC 0 and zero registers: never by
default (the "never" checkbox), so the registers persist and carry state
the pixels do not show, the machines running on from frame to frame; or
every n frames for any whole number n, every frame making what a turn does
a function of the pixels alone, so that the code in them has a meaning by
itself. The steps setting does not apply.

The states live in a buffer of 128 bytes per directed link, 4WH of them
(512 bytes a pixel), allocated the first time the mode runs and reset to fresh
registers (zero; the 6502 with P = 0x24 and S = 0xFF) when the mode starts,
the grid changes size or the CPU kind changes, and on the turns the reset
setting names (`links_reset`). The pair
(x, y), (x + 1, y) has index p = y·W + x, the pair (x, y), (x, y + 1) index
p = W·H + y·W + x; the forward link's state is entry 2p and the backward
link's entry 2p + 1 (`links` in `driver.wat`, which shares the
one-instruction `$step` with the ordinary driver). Machines that keep
registers in the pixel in the ordinary regime (CHIP-8, 4004, RISC-V, PDP-8)
keep them in the link state here instead, and the three 128-bit machines
(PDP-8, UNIVAC 1101, CDC 6600) see only the first pixel of their link, so
the forward machine works on one pixel of the pair and the backward machine
on the other.
The mode runs on the worker pool too (`Band.linkBand`, `links_zone`).
Within a phase the pairs are disjoint and every machine touches only its own
two pixels, so a phase splits over the bands exactly; only the up-down pairs
across a band edge need care. A band owns the left-right pairs of its rows
and the up-down pairs whose first row is y0 − 1 to y1 − 2, so the pair
across its top edge is its own (an odd first row, a UD1 pair) and the pair
across its bottom edge belongs to the band below. Each round a band runs
UD0 and LR0 on its rows, sends its bottom row to the band below, receives
the row above from the band above into its halo and runs UD1 including the
top-edge pair, hands that row back changed, puts the returned bottom row in
place and runs LR1. The rows travel over direct channels between
neighbouring workers, two short messages per band edge per round, and the
result is bit-identical to the single-instance run (`test/band.test.mjs`).
With a transform or Brainfuck there are no link machines: the joining
applies to the column pairs of the previous section and the changer runs
once a turn on each joint cell.

A pixel is written back only when one of its bytes differs after the
instruction, so a store of the value already there leaves no trace and does
not count as a write; with the machines reset every turn the lattice can
settle into a state where every store reproduces what is there, and the
"pixels rewritten" counter falls to the few pixels the swaps and mutation
keep disturbing. The inspector in this mode shows the four link machines
whose code starts in the selected cell (the forward machines of its pairs to
the right and below, the backward machines of the pairs to the left and
above) with their registers as they stand, instead of the single-cell run,
which is not what changes the cell here.

## How much each changer changes

`test/activity.test.mjs` rewrites a random 64 × 64 grid with every changer,
twice, and reports the share of pixels and bytes changed. It asserts which
changers change fewer than 5% of random pixels: only "do nothing" since the
register spill (before it CHIP-8 and the 4004 were in that set).

The second pass is much quieter than the first for every CPU (the Z80 drops
from 78% of pixels to 14%), and on the lattice the share keeps falling: a
cell whose 16 bytes hold no store instruction is a fixed point of the
changer, its program runs its 256 instructions and leaves the memory as it
was, and once a cell gets there only the swaps, the smoothing and mutation
move it on. The lattice saturates in such cells, for instance
`00 01 54 40 80 20 11 10 4b 40 4b 40 4b 00 4b 40` (NOP; LD BC,4054h; ADD
A,B; JR NZ to byte 8; then LD C,E and LD B,B) or
`3e 00 3e 00 3e 00 3e 00 5e 00 41 00 3e 00 1e 00` (LD A,0 four times, LD
E,(HL), LD B,C, LD A,0, LD E,0); four such cells are in `test/mix.test.mjs`. The byte
histogram then stays broad, since many different store-free programs
coexist, while the "pixels rewritten" counter falls.
