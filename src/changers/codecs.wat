  ;; ------------------------------------------------------------------------
  ;; Decoders (kinds 31..40): the cell read as a coded signal and replaced by what a decoder makes of it.
  ;; Every decoder reads the $cw-byte cell as a bitstream or byte stream that wraps at the end (reads are capped at
  ;; 1024 bits), writes its output from byte 0, and when the output runs short the remaining bytes keep the cell's own
  ;; bytes. Back-references past the start of the output read a preset dictionary: the Declaration text ending at the
  ;; LZ cursor offset (prm + 100), the way zlib, LZ4 and Snappy accept a preset dictionary.
  ;;   31 prefix code: 16 nibble symbols with 3-bit code lengths (1..8), canonical as in Deflate, then nibbles
  ;;   32 Morse: a run of 1 bit is a dot, a longer run a dash; a gap of 2 bits ends a letter, of 3 or more a word
  ;;   33 Deflate with the fixed Huffman code (BTYPE 01, gzip's static block), the usual length and distance codes
  ;;   34 LZ4 block format: token, literals, 2-byte offset, match
  ;;   35 Snappy: a varint preamble, then literal, copy-1, copy-2 and copy-4 tags
  ;;   36 Brotli-like: insert-and-copy commands, the last four distances as short codes, dictionary words with transforms
  ;;   37 PNG filters: rows of 4 bytes, a filter byte (None Sub Up Average Paeth) and 3 samples each, reconstructed
  ;;   38 JPEG: one 4x4 block entropy-coded with the standard luminance Huffman tables, dequantised, inverse DCT
  ;;   39 WebP's VP8 boolean decoder: the bits arithmetic-decoded against an order-1 model of the dictionary's bytes
  ;;   40 Rice-coded residuals of a first-order predictor, as in FLAC: a 3-bit parameter, then unary quotient and remainder
  ;; Tables at $DT, written by Codec.install: 0 Deflate length bases (i16 x 29), 64 their extra bits, 96 distance bases
  ;; (i32 x 30), 224 their extra bits, 256 the Morse alphabet by path, 384 the JPEG DC code (16 counts, 12 values),
  ;; 416 the AC code (16 counts, 162 values), 608 the 4x4 quantiser in zigzag order, 624 the zigzag, 1024.. scratch.
  ;; The VP8 model at $VP: 256 contexts x 256 nodes, the probability (1..255 of 256) that the next bit is 0.
  (global $DT i32 (i32.const 17408))
  (global $VP i32 (i32.const 65536))
  (global $cp (mut i32) (i32.const 0))     ;; the cell being decoded
  (global $cprm (mut i32) (i32.const 0))
  (global $cbp (mut i32) (i32.const 0))    ;; bit position in the cell (wraps)
  (global $cused (mut i32) (i32.const 0))  ;; bits consumed
  (global $cby (mut i32) (i32.const 0))    ;; byte position for the byte-oriented formats
  (global $opos (mut i32) (i32.const 0))   ;; output position
  (global $ocmd (mut i32) (i32.const 0))   ;; commands so far (the parity marks the fragments)
  (global $oout (mut i32) (i32.const 0))
  (global $oflg (mut i32) (i32.const 0))

  (func $nbits (result i32) (i32.shl (global.get $cw) (i32.const 3)))
  (func $bitM (result i32)   ;; next bit, most significant bit of each byte first
    (local $b i32)
    (local.set $b (i32.and (global.get $cbp) (i32.sub (call $nbits) (i32.const 1))))
    (global.set $cbp (i32.add (global.get $cbp) (i32.const 1)))
    (global.set $cused (i32.add (global.get $cused) (i32.const 1)))
    (i32.and (i32.shr_u (i32.load8_u (i32.add (global.get $cp) (i32.shr_u (local.get $b) (i32.const 3)))) (i32.sub (i32.const 7) (i32.and (local.get $b) (i32.const 7)))) (i32.const 1)))
  (func $bitL (result i32)   ;; next bit, least significant bit of each byte first (Deflate, Brotli)
    (local $b i32)
    (local.set $b (i32.and (global.get $cbp) (i32.sub (call $nbits) (i32.const 1))))
    (global.set $cbp (i32.add (global.get $cbp) (i32.const 1)))
    (global.set $cused (i32.add (global.get $cused) (i32.const 1)))
    (i32.and (i32.shr_u (i32.load8_u (i32.add (global.get $cp) (i32.shr_u (local.get $b) (i32.const 3)))) (i32.and (local.get $b) (i32.const 7))) (i32.const 1)))
  (func $bitsM (param $n i32) (result i32)   ;; n bits as a big-endian number
    (local $v i32)
    (block $e (loop $l (br_if $e (i32.eqz (local.get $n)))
      (local.set $v (i32.or (i32.shl (local.get $v) (i32.const 1)) (call $bitM)))
      (local.set $n (i32.sub (local.get $n) (i32.const 1))) (br $l)))
    (local.get $v))
  (func $bitsL (param $n i32) (result i32)   ;; n bits, first bit least significant (Deflate extra bits)
    (local $v i32) (local $i i32)
    (block $e (loop $l (br_if $e (i32.ge_u (local.get $i) (local.get $n)))
      (local.set $v (i32.or (local.get $v) (i32.shl (call $bitL) (local.get $i))))
      (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $l)))
    (local.get $v))
  (func $hbitsL (param $n i32) (result i32)   ;; a Huffman code of n bits from the LSB-first stream, assembled MSB-first
    (local $v i32)
    (block $e (loop $l (br_if $e (i32.eqz (local.get $n)))
      (local.set $v (i32.or (i32.shl (local.get $v) (i32.const 1)) (call $bitL)))
      (local.set $n (i32.sub (local.get $n) (i32.const 1))) (br $l)))
    (local.get $v))
  (func $rbyte (result i32)   ;; next byte of the cell, wrapping
    (local $v i32)
    (local.set $v (i32.load8_u (i32.add (global.get $cp) (i32.and (global.get $cby) (i32.sub (global.get $cw) (i32.const 1))))))
    (global.set $cby (i32.add (global.get $cby) (i32.const 1)))
    (global.set $cused (i32.add (global.get $cused) (i32.const 8)))
    (local.get $v))
  (func $cap (result i32) (i32.ge_u (global.get $cused) (i32.const 1024)))
  (func $full (result i32) (i32.ge_u (global.get $opos) (global.get $cw)))
  (func $stop (result i32) (i32.or (call $cap) (call $full)))
  (func $oput (param $v i32)   ;; one output byte, flagged with the parity of the command that made it
    (if (call $full) (then (return)))
    (i32.store8 (i32.add (global.get $oout) (global.get $opos)) (local.get $v))
    (i32.store8 (i32.add (global.get $oflg) (global.get $opos)) (i32.and (global.get $ocmd) (i32.const 1)))
    (global.set $opos (i32.add (global.get $opos) (i32.const 1))))
  (func $oref (param $d i32) (result i32)   ;; the byte d back from the output position; past the start, the preset dictionary
    (local $tl i32) (local $k i32)
    (if (i32.le_u (local.get $d) (global.get $opos)) (then
      (return (i32.load8_u (i32.add (global.get $oout) (i32.sub (global.get $opos) (local.get $d)))))))
    (local.set $tl (i32.load offset=32 (global.get $cprm)))
    (local.set $k (i32.rem_u (i32.sub (local.get $d) (global.get $opos)) (local.get $tl)))   ;; 1.. bytes before the end of the dictionary window
    (local.set $k (i32.add (i32.sub (i32.rem_u (i32.load offset=100 (global.get $cprm)) (local.get $tl)) (local.get $k)) (local.get $tl)))
    (if (i32.ge_u (local.get $k) (local.get $tl)) (then (local.set $k (i32.sub (local.get $k) (local.get $tl)))))
    (i32.load8_u (i32.add (i32.sub (i32.load (global.get $cprm)) (local.get $tl)) (local.get $k))))
  (func $ocopy (param $d i32) (param $len i32)
    (if (i32.eqz (local.get $d)) (then (local.set $d (i32.const 1))))
    (block $e (loop $l (br_if $e (i32.or (i32.eqz (local.get $len)) (call $full)))
      (call $oput (call $oref (local.get $d)))
      (local.set $len (i32.sub (local.get $len) (i32.const 1))) (br $l))))
  (func $cmd (global.set $ocmd (i32.add (global.get $ocmd) (i32.const 1))))

  ;; 31: canonical prefix code over nibbles. Header: 16 code lengths of 3 bits (length = value + 1). Codes are assigned
  ;; as in Deflate (shorter codes first, then by symbol) and read bit by bit; a code that matches nothing within
  ;; 8 bits decodes as nibble 0. Two nibbles make a byte, high nibble first; a nibble is one command.
  (func $dec_huff
    (local $s i32) (local $l i32) (local $S i32) (local $idx i32) (local $code i32) (local $first i32) (local $count i32) (local $sym i32) (local $hi i32) (local $have i32)
    (local.set $S (i32.add (global.get $DT) (i32.const 1024)))   ;; scratch: 16 lengths, counts (i32 x 9) at +16, symbols at +64
    (memory.fill (local.get $S) (i32.const 0) (i32.const 96))
    (block $e (loop $l (br_if $e (i32.ge_u (local.get $s) (i32.const 16)))
      (local.set $l (i32.add (call $bitsM (i32.const 3)) (i32.const 1)))
      (i32.store8 (i32.add (local.get $S) (local.get $s)) (local.get $l))
      (i32.store (i32.add (local.get $S) (i32.add (i32.const 16) (i32.shl (local.get $l) (i32.const 2))))
        (i32.add (i32.load (i32.add (local.get $S) (i32.add (i32.const 16) (i32.shl (local.get $l) (i32.const 2))))) (i32.const 1)))
      (local.set $s (i32.add (local.get $s) (i32.const 1))) (br $l)))
    (local.set $l (i32.const 1))
    (block $le (loop $ll (br_if $le (i32.gt_u (local.get $l) (i32.const 8)))
      (local.set $s (i32.const 0))
      (block $se (loop $sl (br_if $se (i32.ge_u (local.get $s) (i32.const 16)))
        (if (i32.eq (i32.load8_u (i32.add (local.get $S) (local.get $s))) (local.get $l)) (then
          (i32.store8 (i32.add (local.get $S) (i32.add (i32.const 64) (local.get $idx))) (local.get $s))
          (local.set $idx (i32.add (local.get $idx) (i32.const 1)))))
        (local.set $s (i32.add (local.get $s) (i32.const 1))) (br $sl)))
      (local.set $l (i32.add (local.get $l) (i32.const 1))) (br $ll)))
    (block $de (loop $dl (br_if $de (call $stop))
      (local.set $code (i32.const 0)) (local.set $first (i32.const 0)) (local.set $idx (i32.const 0)) (local.set $sym (i32.const -1))
      (local.set $l (i32.const 1))
      (block $fe (loop $fl (br_if $fe (i32.gt_u (local.get $l) (i32.const 8)))
        (local.set $code (i32.or (local.get $code) (call $bitM)))
        (local.set $count (i32.load (i32.add (local.get $S) (i32.add (i32.const 16) (i32.shl (local.get $l) (i32.const 2))))))
        (if (i32.lt_u (local.get $code) (i32.add (local.get $first) (local.get $count))) (then
          (local.set $sym (i32.load8_u (i32.add (local.get $S) (i32.add (i32.const 64) (i32.add (local.get $idx) (i32.sub (local.get $code) (local.get $first)))))))
          (br $fe)))
        (local.set $idx (i32.add (local.get $idx) (local.get $count)))
        (local.set $first (i32.shl (i32.add (local.get $first) (local.get $count)) (i32.const 1)))
        (local.set $code (i32.shl (local.get $code) (i32.const 1)))
        (local.set $l (i32.add (local.get $l) (i32.const 1))) (br $fl)))
      (if (i32.lt_s (local.get $sym) (i32.const 0)) (then (local.set $sym (i32.const 0))))
      (if (local.get $have)
        (then (call $oput (i32.or (i32.shl (local.get $hi) (i32.const 4)) (local.get $sym))) (local.set $have (i32.const 0)))
        (else (call $cmd) (local.set $hi (local.get $sym)) (local.set $have (i32.const 1))))
      (br $dl))))

  ;; 32: Morse. Bits MSB-first; a run of a single 1 is a dot, two or more a dash; a run of a single 0 separates
  ;; elements, two end the letter, three or more end the letter and the word (a space). Letters come out in lower
  ;; case from the table at $DT + 256, indexed by 1 followed by the element bits (dash = 1); an unknown or
  ;; over-long (7 elements) pattern is '?'. The rest of the cell is silence: spaces.
  (func $dec_morse
    (local $b i32) (local $r i32) (local $path i32)
    (local.set $path (i32.const 1))
    (block $z (loop $zl (br_if $z (i32.or (call $bitM) (call $cap))) (br $zl)))   ;; leading silence
    (block $e (loop $l
      (br_if $e (call $stop))
      (local.set $r (i32.const 1))   ;; the run of 1s, its first bit already read
      (block $re (loop $rl (local.set $b (call $bitM)) (br_if $re (i32.or (i32.eqz (local.get $b)) (call $cap))) (local.set $r (i32.add (local.get $r) (i32.const 1))) (br $rl)))
      (local.set $path (i32.or (i32.shl (local.get $path) (i32.const 1)) (i32.ge_u (local.get $r) (i32.const 2))))
      (if (i32.ge_u (local.get $path) (i32.const 128)) (then (call $cmd) (call $oput (i32.const 63)) (local.set $path (i32.const 1))))
      (br_if $e (call $stop))
      (local.set $r (i32.const 1))   ;; the run of 0s
      (block $ze (loop $zl2 (local.set $b (call $bitM)) (br_if $ze (i32.or (local.get $b) (call $cap))) (local.set $r (i32.add (local.get $r) (i32.const 1))) (br $zl2)))
      (if (i32.ge_u (local.get $r) (i32.const 2)) (then
        (call $cmd) (call $oput (i32.load8_u (i32.add (global.get $DT) (i32.add (i32.const 256) (local.get $path))))) (local.set $path (i32.const 1))
        (if (i32.ge_u (local.get $r) (i32.const 3)) (then (call $oput (i32.const 32))))))
      (br $l)))
    (if (i32.gt_u (local.get $path) (i32.const 1)) (then (call $cmd) (call $oput (i32.load8_u (i32.add (global.get $DT) (i32.add (i32.const 256) (local.get $path)))))))
    (block $fe (loop $fl (br_if $fe (call $full)) (call $oput (i32.const 32)) (br $fl))))

  ;; 33: Deflate, fixed Huffman block (gzip's BTYPE 01), bits LSB-first, codes MSB-first within the stream:
  ;; 7-bit codes 0..23 are symbols 256..279, 8-bit 48..191 literals 0..143, 8-bit 192..199 symbols 280..287,
  ;; 9-bit 400..511 literals 144..255. Lengths 257..285 and 5-bit distance codes 0..29 with their extra bits;
  ;; end of block (256) just continues with the next block; 286, 287 count as 285 and distance codes 30, 31 wrap.
  (func $dec_deflate
    (local $c i32) (local $sym i32) (local $i i32) (local $len i32) (local $dc i32) (local $d i32)
    (block $e (loop $l (br_if $e (call $stop))
      (local.set $c (call $hbitsL (i32.const 7)))
      (if (i32.lt_u (local.get $c) (i32.const 24)) (then (local.set $sym (i32.add (local.get $c) (i32.const 256))))
        (else
          (local.set $c (i32.or (i32.shl (local.get $c) (i32.const 1)) (call $bitL)))
          (if (i32.lt_u (local.get $c) (i32.const 200))
            (then (local.set $sym (select (i32.sub (local.get $c) (i32.const 48)) (i32.add (local.get $c) (i32.const 88)) (i32.lt_u (local.get $c) (i32.const 192)))))
            (else (local.set $c (i32.or (i32.shl (local.get $c) (i32.const 1)) (call $bitL))) (local.set $sym (i32.sub (local.get $c) (i32.const 256)))))))
      (if (i32.lt_u (local.get $sym) (i32.const 256)) (then (call $cmd) (call $oput (local.get $sym)) (br $l)))
      (if (i32.eq (local.get $sym) (i32.const 256)) (then (br $l)))
      (if (i32.gt_u (local.get $sym) (i32.const 285)) (then (local.set $sym (i32.const 285))))
      (local.set $i (i32.sub (local.get $sym) (i32.const 257)))
      (local.set $len (i32.add (i32.load16_u (i32.add (global.get $DT) (i32.shl (local.get $i) (i32.const 1))))
                               (call $bitsL (i32.load8_u (i32.add (global.get $DT) (i32.add (i32.const 64) (local.get $i)))))))
      (local.set $dc (i32.rem_u (call $hbitsL (i32.const 5)) (i32.const 30)))
      (local.set $d (i32.add (i32.load (i32.add (global.get $DT) (i32.add (i32.const 96) (i32.shl (local.get $dc) (i32.const 2)))))
                             (call $bitsL (i32.load8_u (i32.add (global.get $DT) (i32.add (i32.const 224) (local.get $dc)))))))
      (call $cmd) (call $ocopy (local.get $d) (local.get $len))
      (br $l))))

  ;; 34: LZ4 block format. A sequence is a token (literal length in the high nibble, match length - 4 in the low,
  ;; 15 meaning more bytes follow, 255 continuing), the literals, a little-endian 2-byte offset and the match.
  ;; Offset 0 counts as 1; length extensions are read up to 4 bytes.
  (func $lz4len (param $n i32) (result i32)
    (local $k i32) (local $x i32)
    (if (i32.ne (local.get $n) (i32.const 15)) (then (return (local.get $n))))
    (block $e (loop $l (br_if $e (i32.ge_u (local.get $k) (i32.const 4)))
      (local.set $x (call $rbyte)) (local.set $n (i32.add (local.get $n) (local.get $x)))
      (br_if $e (i32.ne (local.get $x) (i32.const 255)))
      (local.set $k (i32.add (local.get $k) (i32.const 1))) (br $l)))
    (local.get $n))
  (func $dec_lz4
    (local $t i32) (local $n i32) (local $off i32)
    (block $e (loop $l (br_if $e (call $stop))
      (local.set $t (call $rbyte))
      (local.set $n (call $lz4len (i32.shr_u (local.get $t) (i32.const 4))))
      (if (local.get $n) (then (call $cmd)))
      (block $le (loop $ll (br_if $le (i32.or (i32.eqz (local.get $n)) (call $stop))) (call $oput (call $rbyte)) (local.set $n (i32.sub (local.get $n) (i32.const 1))) (br $ll)))
      (br_if $e (call $stop))
      (local.set $off (call $rbyte)) (local.set $off (i32.or (local.get $off) (i32.shl (call $rbyte) (i32.const 8))))
      (local.set $n (i32.add (call $lz4len (i32.and (local.get $t) (i32.const 15))) (i32.const 4)))
      (call $cmd) (call $ocopy (local.get $off) (local.get $n))
      (br $l))))

  ;; 35: Snappy. A varint length preamble (skipped), then tags: 00 literal (length in the upper 6 bits, 60..63 meaning
  ;; 1..4 length bytes follow), 01 copy with a 1-byte offset (length 4..11, offset 11 bits), 10 copy with a 2-byte
  ;; offset, 11 copy with a 4-byte offset; copy lengths are the upper 6 bits + 1. Offset 0 counts as 1.
  (func $dec_snappy
    (local $t i32) (local $n i32) (local $off i32) (local $k i32) (local $i i32)
    (block $pe (loop $pl (br_if $pe (i32.ge_u (local.get $k) (i32.const 5))) (local.set $t (call $rbyte)) (br_if $pe (i32.eqz (i32.and (local.get $t) (i32.const 128)))) (local.set $k (i32.add (local.get $k) (i32.const 1))) (br $pl)))
    (block $e (loop $l (br_if $e (call $stop))
      (local.set $t (call $rbyte))
      (local.set $n (i32.shr_u (local.get $t) (i32.const 2)))
      (block $tags
        (if (i32.eqz (i32.and (local.get $t) (i32.const 3))) (then   ;; literal
          (if (i32.ge_u (local.get $n) (i32.const 60)) (then
            (local.set $k (i32.sub (local.get $n) (i32.const 59))) (local.set $n (i32.const 0)) (local.set $i (i32.const 0))
            (block $ne (loop $nl (br_if $ne (i32.ge_u (local.get $i) (local.get $k)))
              (local.set $n (i32.or (local.get $n) (i32.shl (call $rbyte) (i32.shl (local.get $i) (i32.const 3)))))
              (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $nl)))))
          (local.set $n (i32.add (local.get $n) (i32.const 1)))
          (call $cmd)
          (block $le (loop $ll (br_if $le (i32.or (i32.eqz (local.get $n)) (call $stop))) (call $oput (call $rbyte)) (local.set $n (i32.sub (local.get $n) (i32.const 1))) (br $ll)))
          (br $tags)))
        (if (i32.eq (i32.and (local.get $t) (i32.const 3)) (i32.const 1)) (then
          (local.set $n (i32.add (i32.and (local.get $n) (i32.const 7)) (i32.const 4)))
          (local.set $off (i32.or (i32.shl (i32.shr_u (local.get $t) (i32.const 5)) (i32.const 8)) (call $rbyte))))
        (else
          (local.set $n (i32.add (local.get $n) (i32.const 1)))
          (local.set $off (call $rbyte)) (local.set $off (i32.or (local.get $off) (i32.shl (call $rbyte) (i32.const 8))))
          (if (i32.eq (i32.and (local.get $t) (i32.const 3)) (i32.const 3)) (then
            (local.set $off (i32.or (local.get $off) (i32.shl (call $rbyte) (i32.const 16))))
            (local.set $off (i32.or (local.get $off) (i32.shl (i32.and (call $rbyte) (i32.const 127)) (i32.const 24))))))))
        (call $cmd) (call $ocopy (local.get $off) (local.get $n)))
      (br $l))))

  ;; 36: Brotli-like. Bits LSB-first. A command is an insert length (2-bit code: 0, 1, 2 + 1 bit, 4 + 2 bits) and
  ;; that many 8-bit literals, a copy length (2-bit code: 2, 3, 4 + 1 bit, 6 + 3 bits) and a distance: one bit chooses
  ;; between Brotli's 16 short codes on the ring of the last four distances (the last, second, third, fourth, then the
  ;; last and second with -1 +1 -2 +2 -3 +3) and an explicit distance 1 + 6 bits. The ring starts at 4 11 15 16 as
  ;; in Brotli and is pushed by every distance except short code 0. A distance reaching past the output is a
  ;; dictionary reference and takes 2 more bits of transform: as is, first letter upper case, all upper, all lower.
  (func $xf_case (param $v i32) (param $tf i32) (param $first i32) (result i32)
    (if (i32.or (i32.eq (local.get $tf) (i32.const 2)) (i32.and (i32.eq (local.get $tf) (i32.const 1)) (local.get $first))) (then
      (if (i32.lt_u (i32.sub (local.get $v) (i32.const 97)) (i32.const 26)) (then (return (i32.sub (local.get $v) (i32.const 32)))))))
    (if (i32.eq (local.get $tf) (i32.const 3)) (then
      (if (i32.lt_u (i32.sub (local.get $v) (i32.const 65)) (i32.const 26)) (then (return (i32.add (local.get $v) (i32.const 32)))))))
    (local.get $v))
  (func $dec_brotli
    (local $r0 i32) (local $r1 i32) (local $r2 i32) (local $r3 i32) (local $c i32) (local $n i32) (local $len i32) (local $d i32) (local $sc i32) (local $tf i32) (local $k i32) (local $push i32)
    (local.set $r0 (i32.const 4)) (local.set $r1 (i32.const 11)) (local.set $r2 (i32.const 15)) (local.set $r3 (i32.const 16))
    (block $e (loop $l (br_if $e (call $stop))
      (local.set $c (call $bitsL (i32.const 2)))
      (local.set $n (local.get $c))
      (if (i32.eq (local.get $c) (i32.const 2)) (then (local.set $n (i32.add (i32.const 2) (call $bitsL (i32.const 1))))))
      (if (i32.eq (local.get $c) (i32.const 3)) (then (local.set $n (i32.add (i32.const 4) (call $bitsL (i32.const 2))))))
      (if (local.get $n) (then (call $cmd)))
      (block $ie (loop $il (br_if $ie (i32.or (i32.eqz (local.get $n)) (call $stop))) (call $oput (call $bitsL (i32.const 8))) (local.set $n (i32.sub (local.get $n) (i32.const 1))) (br $il)))
      (br_if $e (call $stop))
      (local.set $c (call $bitsL (i32.const 2)))
      (local.set $len (i32.add (local.get $c) (i32.const 2)))
      (if (i32.eq (local.get $c) (i32.const 2)) (then (local.set $len (i32.add (i32.const 4) (call $bitsL (i32.const 1))))))
      (if (i32.eq (local.get $c) (i32.const 3)) (then (local.set $len (i32.add (i32.const 6) (call $bitsL (i32.const 3))))))
      (local.set $push (i32.const 1))
      (if (i32.eqz (call $bitsL (i32.const 1)))
        (then
          (local.set $sc (call $bitsL (i32.const 4)))
          (if (i32.lt_u (local.get $sc) (i32.const 4))
            (then (local.set $d (select (local.get $r0) (select (local.get $r1) (select (local.get $r2) (local.get $r3) (i32.eq (local.get $sc) (i32.const 2))) (i32.eq (local.get $sc) (i32.const 1))) (i32.eqz (local.get $sc))))
                  (if (i32.eqz (local.get $sc)) (then (local.set $push (i32.const 0)))))
            (else
              (local.set $k (i32.add (i32.shr_u (i32.sub (local.get $sc) (i32.const 4)) (i32.const 1)) (i32.const 1)))   ;; 1, 1, 2, 2, 3, 3 for codes 4..9 and 10..15
              (if (i32.ge_u (local.get $sc) (i32.const 10)) (then (local.set $k (i32.sub (local.get $k) (i32.const 3)))))
              (local.set $d (select (local.get $r0) (local.get $r1) (i32.lt_u (local.get $sc) (i32.const 10))))
              (local.set $d (select (i32.sub (local.get $d) (local.get $k)) (i32.add (local.get $d) (local.get $k)) (i32.eqz (i32.and (local.get $sc) (i32.const 1))))))))
        (else (local.set $d (i32.add (i32.const 1) (call $bitsL (i32.const 6))))))
      (if (i32.lt_s (local.get $d) (i32.const 1)) (then (local.set $d (i32.const 1))))
      (local.set $tf (i32.const 0))
      (if (i32.gt_u (local.get $d) (global.get $opos)) (then (local.set $tf (call $bitsL (i32.const 2)))))
      (if (local.get $push) (then (local.set $r3 (local.get $r2)) (local.set $r2 (local.get $r1)) (local.set $r1 (local.get $r0)) (local.set $r0 (local.get $d))))
      (call $cmd)
      (local.set $k (i32.const 1))
      (block $ce (loop $cl (br_if $ce (i32.or (i32.eqz (local.get $len)) (call $full)))
        (call $oput (call $xf_case (call $oref (local.get $d)) (local.get $tf) (local.get $k)))
        (local.set $k (i32.const 0))
        (local.set $len (i32.sub (local.get $len) (i32.const 1))) (br $cl)))
      (br $l))))

  ;; 37: PNG filters. The cell is rows of 4 bytes: a filter type (its low 3 bits mod 5: 0 None, 1 Sub, 2 Up,
  ;; 3 Average, 4 Paeth) and three samples, one byte per pixel. Each sample is reconstructed from the filtered value
  ;; and the predictor over the reconstructed left (a), upper (b) and upper-left (c) neighbours, zero outside the
  ;; image; the filter bytes are kept. Applied every turn, the cell integrates itself: Sub makes running sums along
  ;; a row, Up down the columns.
  (func $paeth (param $a i32) (param $b i32) (param $c i32) (result i32)
    (local $p i32) (local $pa i32) (local $pb i32) (local $pc i32)
    (local.set $p (i32.sub (i32.add (local.get $a) (local.get $b)) (local.get $c)))
    (local.set $pa (i32.sub (local.get $p) (local.get $a))) (local.set $pa (select (i32.sub (i32.const 0) (local.get $pa)) (local.get $pa) (i32.lt_s (local.get $pa) (i32.const 0))))
    (local.set $pb (i32.sub (local.get $p) (local.get $b))) (local.set $pb (select (i32.sub (i32.const 0) (local.get $pb)) (local.get $pb) (i32.lt_s (local.get $pb) (i32.const 0))))
    (local.set $pc (i32.sub (local.get $p) (local.get $c))) (local.set $pc (select (i32.sub (i32.const 0) (local.get $pc)) (local.get $pc) (i32.lt_s (local.get $pc) (i32.const 0))))
    (if (i32.and (i32.le_s (local.get $pa) (local.get $pb)) (i32.le_s (local.get $pa) (local.get $pc))) (then (return (local.get $a))))
    (select (local.get $b) (local.get $c) (i32.le_s (local.get $pb) (local.get $pc))))
  (func $dec_png
    (local $r i32) (local $i i32) (local $f i32) (local $a i32) (local $b i32) (local $c i32) (local $x i32) (local $v i32) (local $row i32)
    (block $re (loop $rl (br_if $re (i32.ge_u (local.get $r) (i32.shr_u (global.get $cw) (i32.const 2))))
      (local.set $row (i32.shl (local.get $r) (i32.const 2)))
      (local.set $f (i32.rem_u (i32.and (i32.load8_u (i32.add (global.get $cp) (local.get $row))) (i32.const 7)) (i32.const 5)))
      (i32.store8 (i32.add (global.get $oout) (local.get $row)) (i32.load8_u (i32.add (global.get $cp) (local.get $row))))
      (local.set $i (i32.const 1))
      (block $ie (loop $il (br_if $ie (i32.ge_u (local.get $i) (i32.const 4)))
        (local.set $x (i32.load8_u (i32.add (global.get $cp) (i32.add (local.get $row) (local.get $i)))))
        (local.set $a (select (i32.load8_u (i32.add (global.get $oout) (i32.add (local.get $row) (i32.sub (local.get $i) (i32.const 1))))) (i32.const 0) (i32.gt_u (local.get $i) (i32.const 1))))
        (local.set $b (select (i32.load8_u (i32.add (global.get $oout) (i32.add (i32.sub (local.get $row) (i32.const 4)) (local.get $i)))) (i32.const 0) (local.get $r)))
        (local.set $c (select (i32.load8_u (i32.add (global.get $oout) (i32.add (i32.sub (local.get $row) (i32.const 5)) (local.get $i)))) (i32.const 0) (i32.and (i32.ne (local.get $r) (i32.const 0)) (i32.gt_u (local.get $i) (i32.const 1)))))
        (local.set $v (i32.and (i32.add (local.get $x)
          (select (i32.const 0) (select (local.get $a) (select (local.get $b) (select (i32.shr_u (i32.add (local.get $a) (local.get $b)) (i32.const 1)) (call $paeth (local.get $a) (local.get $b) (local.get $c)) (i32.eq (local.get $f) (i32.const 3))) (i32.eq (local.get $f) (i32.const 2))) (i32.eq (local.get $f) (i32.const 1))) (i32.eqz (local.get $f))))
          (i32.const 255)))
        (i32.store8 (i32.add (global.get $oout) (i32.add (local.get $row) (local.get $i))) (local.get $v))
        (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $il)))
      (local.set $r (i32.add (local.get $r) (i32.const 1))) (br $rl)))
    (global.set $opos (global.get $cw)))

  ;; 38: JPEG. The 128 bits are the entropy-coded data of one 4x4 block (a restart before every block, so the DC
  ;; predictor is 0): the DC category and bits, then run/size pairs for the 15 AC coefficients in zigzag order, with
  ;; the standard luminance Huffman tables (Annex K.3) read MSB-first; EOB ends the block, ZRL skips past it, and a
  ;; code that matches nothing counts as EOB. Coefficients are dequantised with the top-left 4x4 of the standard
  ;; luminance quantiser (K.1), inverse-transformed (4-point DCT per axis) and level-shifted into 16 samples, row by row.
  (func $jhuff (param $tab i32) (result i32)
    (local $l i32) (local $code i32) (local $first i32) (local $idx i32) (local $n i32)
    (local.set $l (i32.const 1))
    (block $e (loop $lp (br_if $e (i32.gt_u (local.get $l) (i32.const 16)))
      (local.set $code (i32.or (i32.shl (local.get $code) (i32.const 1)) (call $bitM)))
      (local.set $n (i32.load8_u (i32.add (local.get $tab) (i32.sub (local.get $l) (i32.const 1)))))
      (if (i32.lt_u (local.get $code) (i32.add (local.get $first) (local.get $n))) (then
        (return (i32.load8_u (i32.add (local.get $tab) (i32.add (i32.const 16) (i32.add (local.get $idx) (i32.sub (local.get $code) (local.get $first)))))))))
      (local.set $idx (i32.add (local.get $idx) (local.get $n)))
      (local.set $first (i32.shl (i32.add (local.get $first) (local.get $n)) (i32.const 1)))
      (local.set $l (i32.add (local.get $l) (i32.const 1))) (br $lp)))
    (i32.const 0))
  (func $jextend (param $s i32) (result i32)   ;; s magnitude bits -> signed value, as JPEG's EXTEND
    (local $v i32)
    (if (i32.eqz (local.get $s)) (then (return (i32.const 0))))
    (local.set $v (call $bitsM (local.get $s)))
    (select (i32.add (local.get $v) (i32.add (i32.shl (i32.const -1) (local.get $s)) (i32.const 1))) (local.get $v) (i32.lt_u (local.get $v) (i32.shl (i32.const 1) (i32.sub (local.get $s) (i32.const 1))))))
  (func $dec_jpeg
    (local $S i32) (local $k i32) (local $rs i32) (local $s i32) (local $m i32) (local $n i32) (local $u i32) (local $v i32) (local $acc f64) (local $x i32) (local $cu f64) (local $t f64)
    (local.set $S (i32.add (global.get $DT) (i32.const 1152)))   ;; 16 coefficients, i32, in raster order
    (memory.fill (local.get $S) (i32.const 0) (i32.const 64))
    (i32.store (local.get $S) (i32.mul (call $jextend (call $jhuff (i32.add (global.get $DT) (i32.const 384)))) (i32.load8_u (i32.add (global.get $DT) (i32.const 608)))))
    (local.set $k (i32.const 1))
    (block $e (loop $l (br_if $e (i32.or (i32.ge_u (local.get $k) (i32.const 16)) (call $cap)))
      (local.set $rs (call $jhuff (i32.add (global.get $DT) (i32.const 416))))
      (br_if $e (i32.eqz (local.get $rs)))
      (local.set $s (i32.and (local.get $rs) (i32.const 15)))
      (local.set $k (i32.add (local.get $k) (i32.shr_u (local.get $rs) (i32.const 4))))
      (if (i32.eqz (local.get $s)) (then (local.set $k (i32.add (local.get $k) (i32.const 1))) (br $l)))   ;; ZRL: 16 zeros
      (br_if $e (i32.ge_u (local.get $k) (i32.const 16)))
      (i32.store (i32.add (local.get $S) (i32.shl (i32.load8_u (i32.add (global.get $DT) (i32.add (i32.const 624) (local.get $k)))) (i32.const 2)))
        (i32.mul (call $jextend (local.get $s)) (i32.load8_u (i32.add (global.get $DT) (i32.add (i32.const 608) (local.get $k))))))
      (global.set $ocmd (i32.add (global.get $ocmd) (i32.const 1)))
      (local.set $k (i32.add (local.get $k) (i32.const 1))) (br $l)))
    ;; inverse 4x4 DCT: x[m][n] = 1/2 sum_u sum_v C(u) C(v) F[u][v] cos((2m+1)u pi/8) cos((2n+1)v pi/8)
    (local.set $m (i32.const 0))
    (block $me (loop $ml (br_if $me (i32.ge_u (local.get $m) (i32.const 4)))
      (local.set $n (i32.const 0))
      (block $ne (loop $nl (br_if $ne (i32.ge_u (local.get $n) (i32.const 4)))
        (local.set $acc (f64.const 0)) (local.set $u (i32.const 0))
        (block $ue (loop $ul (br_if $ue (i32.ge_u (local.get $u) (i32.const 4)))
          (local.set $v (i32.const 0))
          (block $ve (loop $vl (br_if $ve (i32.ge_u (local.get $v) (i32.const 4)))
            (local.set $x (i32.load (i32.add (local.get $S) (i32.shl (i32.add (i32.shl (local.get $u) (i32.const 2)) (local.get $v)) (i32.const 2)))))
            (if (local.get $x) (then
              (local.set $cu (select (f64.const 0.7071067811865476) (f64.const 1) (i32.eqz (local.get $u))))
              (local.set $t (select (f64.const 0.7071067811865476) (f64.const 1) (i32.eqz (local.get $v))))
              (local.set $acc (f64.add (local.get $acc) (f64.mul (f64.mul (f64.mul (local.get $cu) (local.get $t)) (f64.convert_i32_s (local.get $x)))
                (f64.mul (call $cos64 (i32.mul (i32.mul (i32.add (i32.shl (local.get $m) (i32.const 1)) (i32.const 1)) (local.get $u)) (i32.const 8)))
                         (call $cos64 (i32.mul (i32.mul (i32.add (i32.shl (local.get $n) (i32.const 1)) (i32.const 1)) (local.get $v)) (i32.const 8)))))))))
            (local.set $v (i32.add (local.get $v) (i32.const 1))) (br $vl)))
          (local.set $u (i32.add (local.get $u) (i32.const 1))) (br $ul)))
        (local.set $x (i32.add (i32.const 128) (i32.trunc_f64_s (f64.nearest (f64.mul (local.get $acc) (f64.const 0.5))))))
        (local.set $x (select (i32.const 0) (select (i32.const 255) (local.get $x) (i32.gt_s (local.get $x) (i32.const 255))) (i32.lt_s (local.get $x) (i32.const 0))))
        (i32.store8 (i32.add (global.get $oout) (i32.add (i32.shl (local.get $m) (i32.const 2)) (local.get $n))) (local.get $x))
        (local.set $n (i32.add (local.get $n) (i32.const 1))) (br $nl)))
      (local.set $m (i32.add (local.get $m) (i32.const 1))) (br $ml)))
    (global.set $opos (i32.const 16)))

  ;; 39: the VP8 boolean decoder of WebP (RFC 6386 section 7), fed the cell's bytes in order. Each output byte is
  ;; decoded as 8 binary decisions down a tree whose probabilities come from the model at $VP: for the context of
  ;; the previous output byte (a space to begin with) and the bits so far, the probability that the next bit is 0,
  ;; estimated from the dictionary text. So the 128 bits are read as the arithmetic code of text in the
  ;; Declaration's statistics, and a cell decodes to the most probable text consistent with its bits.
  (global $vval (mut i32) (i32.const 0)) (global $vrange (mut i32) (i32.const 0)) (global $vcnt (mut i32) (i32.const 0))
  (func $vbool (param $prob i32) (result i32)
    (local $split i32) (local $big i32) (local $r i32)
    (local.set $split (i32.add (i32.const 1) (i32.shr_u (i32.mul (i32.sub (global.get $vrange) (i32.const 1)) (local.get $prob)) (i32.const 8))))
    (local.set $big (i32.shl (local.get $split) (i32.const 8)))
    (if (i32.ge_u (global.get $vval) (local.get $big))
      (then (local.set $r (i32.const 1)) (global.set $vrange (i32.sub (global.get $vrange) (local.get $split))) (global.set $vval (i32.sub (global.get $vval) (local.get $big))))
      (else (global.set $vrange (local.get $split))))
    (block $e (loop $l (br_if $e (i32.ge_u (global.get $vrange) (i32.const 128)))
      (global.set $vval (i32.shl (global.get $vval) (i32.const 1)))
      (global.set $vrange (i32.shl (global.get $vrange) (i32.const 1)))
      (global.set $vcnt (i32.add (global.get $vcnt) (i32.const 1)))
      (if (i32.eq (global.get $vcnt) (i32.const 8)) (then (global.set $vcnt (i32.const 0)) (global.set $vval (i32.or (global.get $vval) (call $rbyte)))))
      (br $l)))
    (local.get $r))
  (func $dec_vp8
    (local $ctx i32) (local $node i32) (local $i i32)
    (global.set $vval (i32.shl (call $rbyte) (i32.const 8))) (global.set $vval (i32.or (global.get $vval) (call $rbyte)))
    (global.set $vrange (i32.const 255)) (global.set $vcnt (i32.const 0))
    (local.set $ctx (i32.const 32))
    (block $e (loop $l (br_if $e (call $full))
      (local.set $node (i32.const 1)) (local.set $i (i32.const 0))
      (block $be (loop $bl (br_if $be (i32.ge_u (local.get $i) (i32.const 8)))
        (local.set $node (i32.or (i32.shl (local.get $node) (i32.const 1))
          (call $vbool (i32.load8_u (i32.add (global.get $VP) (i32.or (i32.shl (local.get $ctx) (i32.const 8)) (local.get $node)))))))
        (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $bl)))
      (local.set $ctx (i32.and (local.get $node) (i32.const 255)))
      (call $cmd) (call $oput (local.get $ctx))
      (br $l))))

  ;; 40: Rice-coded residuals, as in a FLAC subframe with a first-order fixed predictor: a 3-bit Rice parameter k,
  ;; then per sample a unary quotient (zeros ended by a 1, at most 32) and k remainder bits, MSB-first; the folded
  ;; value is unfolded to a signed residual and added to the previous sample (128 before the first).
  (func $dec_rice
    (local $k i32) (local $q i32) (local $u i32) (local $e i32) (local $prev i32)
    (local.set $k (call $bitsM (i32.const 3))) (local.set $prev (i32.const 128))
    (block $e (loop $l (br_if $e (call $stop))
      (local.set $q (i32.const 0))
      (block $qe (loop $ql (br_if $qe (i32.or (call $bitM) (i32.or (i32.ge_u (local.get $q) (i32.const 32)) (call $cap)))) (local.set $q (i32.add (local.get $q) (i32.const 1))) (br $ql)))
      (local.set $u (i32.or (i32.shl (local.get $q) (local.get $k)) (call $bitsM (local.get $k))))
      (local.set $e (i32.xor (i32.shr_u (local.get $u) (i32.const 1)) (i32.sub (i32.const 0) (i32.and (local.get $u) (i32.const 1)))))
      (local.set $prev (i32.and (i32.add (local.get $prev) (local.get $e)) (i32.const 255)))
      (call $cmd) (call $oput (local.get $prev))
      (br $l))))

  ;; codec(p, prm, kind): run decoder `kind` (31..40) on the $cw-byte cell at p into prm.out; bytes the decoder did not
  ;; produce keep the cell's own value. flags[i] = command parity (31..36, 39, 40) or whether the byte changed (37, 38).
  ;; prm.lastOffset = bits consumed. Returns (bits consumed << 8) | number of bytes that differ from the input.
  (func $codec (param $p i32) (param $prm i32) (param $kind i32) (result i32)
    (local $i i32) (local $changed i32)
    (global.set $cp (local.get $p)) (global.set $cprm (local.get $prm))
    (global.set $cbp (i32.const 0)) (global.set $cused (i32.const 0)) (global.set $cby (i32.const 0))
    (global.set $opos (i32.const 0)) (global.set $ocmd (i32.const 0))
    (global.set $oout (i32.load (local.get $prm))) (global.set $oflg (i32.load offset=36 (local.get $prm)))
    (memory.fill (global.get $oflg) (i32.const 0) (global.get $cw))
    (block $d (block $b40 (block $b39 (block $b38 (block $b37 (block $b36 (block $b35 (block $b34 (block $b33 (block $b32 (block $b31
      (br_table $b31 $b32 $b33 $b34 $b35 $b36 $b37 $b38 $b39 $b40 $d (i32.sub (local.get $kind) (i32.const 31))))
      (call $dec_huff) (br $d)) (call $dec_morse) (br $d)) (call $dec_deflate) (br $d)) (call $dec_lz4) (br $d)) (call $dec_snappy) (br $d))
      (call $dec_brotli) (br $d)) (call $dec_png) (br $d)) (call $dec_jpeg) (br $d)) (call $dec_vp8) (br $d)) (call $dec_rice))
    (block $fe (loop $fl (br_if $fe (call $full))   ;; what was not produced stays
      (i32.store8 (i32.add (global.get $oout) (global.get $opos)) (i32.load8_u (i32.add (local.get $p) (global.get $opos))))
      (i32.store8 (i32.add (global.get $oflg) (global.get $opos)) (i32.const 0))
      (global.set $opos (i32.add (global.get $opos) (i32.const 1))) (br $fl)))
    (block $ce (loop $cl (br_if $ce (i32.ge_u (local.get $i) (global.get $cw)))
      (if (i32.ne (i32.load8_u (i32.add (global.get $oout) (local.get $i))) (i32.load8_u (i32.add (local.get $p) (local.get $i)))) (then
        (local.set $changed (i32.add (local.get $changed) (i32.const 1)))
        (if (i32.or (i32.eq (local.get $kind) (i32.const 37)) (i32.eq (local.get $kind) (i32.const 38))) (then (i32.store8 (i32.add (global.get $oflg) (local.get $i)) (i32.const 1))))))
      (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $cl)))
    (i32.store offset=48 (local.get $prm) (global.get $cused))
    (i32.or (i32.shl (global.get $cused) (i32.const 8)) (local.get $changed)))
