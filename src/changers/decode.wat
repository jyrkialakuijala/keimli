  ;; ------------------------------------------------------------------------
  ;; Decoder. Parameter block (i32 fields) at $prm:
  ;;   0 out      output buffer, placed directly after the dictionary text
  ;;   4 outLen   bytes to produce (16 = 128 bits)
  ;;   8 lenTab   4096-entry lookup table for the copy-length code, entry = sym << 8 | codeLen
  ;;  32 textLen  length of the static dictionary text
  ;;  36 flags    one byte per output byte: parity of the command that produced it
  ;;  44 offsetUnit bytes per step of the 10-bit header cursor
  ;;  48 lastOffset written by decode: the cursor the last decoded pixel started at
  ;;  56 lut      256 x i32 byte-colour LUT, 4 bits per channel (R bit 0, G bit 8, B bit 16)
  ;;  60 meanRaw  packed 8-bit mean LUT colour over all byte values (raw-byte view)
  ;;  64 meanDec  packed 8-bit mean LUT colour weighted by the dictionary's byte frequencies
  ;;  68 gain     contrast gain applied around the mean after averaging (1 = plain average)
  ;;  72 changer  0 = LZ decompressor, 1 = Brainfuck with an empty tape, 2 = Brainfuck on a copy of the pixel,
  ;;              3 = do nothing, 4 = invert, 5 = reverse bytes, 6 = Z80, 7 = MOS 6502, 8 = Intel 8080,
  ;;              9 = Subleq, 10 = CHIP-8, 11 = Intel 4004, 12 = Game Boy SM83, 13 = Intel 8051, 14 = Motorola 6809, 15 = RISC-V RV32EC,
  ;;              16 = add 17 (1 to the smallest byte, 17 to the next, 5 to the previous), 17 = DCT, 18 = inverse DCT
  ;; 512 cosTab   64 x f64: cos(pi m / 32), m = 0..63, written by Codec.install (used by the DCT processors)
  ;;  76/80/84 frame sums of the unstretched R, G, B averages in the LUT views, 88 their count (reset by render)
  ;;  92 steps    instructions per pixel for the CPU cores (256 by default)
  ;;  96 headerBits leading bits of a pixel that select the LZ start cursor (ceil log2 textLen, 13 for the Declaration)
  ;; 100 cursorOffset bytes 0..textLen added to the LZ start cursor before wrapping (600)
  ;;  (12..28 are unused by this decoder and kept for layout stability)

  ;; peek(w0, w1, bitpos, n): n (<= 16) bits LSB-first starting at bitpos, wrapping at 128
  (func $peek (param $w0 i64) (param $w1 i64) (param $bp i32) (param $n i32) (result i32)
    (local $off i32) (local $lo i64) (local $hi i64) (local $v i64)
    (local.set $bp (i32.and (local.get $bp) (i32.const 127)))
    (local.set $off (i32.and (local.get $bp) (i32.const 63)))
    (if (i32.lt_u (local.get $bp) (i32.const 64))
      (then (local.set $lo (local.get $w0)) (local.set $hi (local.get $w1)))
      (else (local.set $lo (local.get $w1)) (local.set $hi (local.get $w0))))
    (local.set $v (i64.shr_u (local.get $lo) (i64.extend_i32_u (local.get $off))))
    (if (i32.gt_u (i32.add (local.get $off) (local.get $n)) (i32.const 64))
      (then (local.set $v (i64.or (local.get $v)
              (i64.shl (local.get $hi) (i64.extend_i32_u (i32.sub (i32.const 64) (local.get $off))))))))
    (i32.and (i32.wrap_i64 (local.get $v))
             (i32.sub (i32.shl (i32.const 1) (local.get $n)) (i32.const 1))))

  ;; decode(p, prm): expand the 128 bits at p into exactly outLen bytes.
  ;; The first prm.headerBits bits (ceil log2 textLen) set a byte cursor into the dictionary (times prm.offsetUnit, 1 at that
  ;; width; plus prm.cursorOffset; mod textLen, so values past the end wrap to the start).
  ;; Every command is a prefix-coded copy length (2..N bytes) followed by a 3-bit skip:
  ;; the cursor first skips that many bytes, then the copy is taken from the dictionary
  ;; at the cursor, which advances past it. Copies are the only source of output; the
  ;; input wraps at 128 bits and consumption is capped at 1024 bits (fallback: continue
  ;; the dictionary from the cursor). flags[i] holds the parity of the command that
  ;; produced byte i, so the inspector can show the fragments.
  ;; Returns (input bits consumed << 8) | number of copy commands.
  (func $decode (param $p i32) (param $prm i32) (result i32)
    (local $w0 i64) (local $w1 i64) (local $bp i32)
    (local $out i32) (local $L i32) (local $flags i32) (local $textLen i32) (local $text i32)
    (local $pos i32) (local $entry i32) (local $len i32) (local $cursor i32) (local $cmds i32)
    ;; changer 1 = Brainfuck on an empty tape, 2 = Brainfuck on a copy of the pixel,
    ;; 3 = do nothing, 4 = invert, 5 = reverse bytes, 16 = add 17 (1 to the smallest byte, 17 to the next, 5 to the previous); 0 = LZ decompressor below
    (if (i32.eq (i32.load offset=72 (local.get $prm)) (i32.const 16)) (then
      (return (call $simple (local.get $p) (local.get $prm) (i32.const 16)))))
    (if (i32.eq (i32.load offset=72 (local.get $prm)) (i32.const 17)) (then
      (return (call $dct (local.get $p) (local.get $prm) (i32.const 0)))))
    (if (i32.eq (i32.load offset=72 (local.get $prm)) (i32.const 18)) (then
      (return (call $dct (local.get $p) (local.get $prm) (i32.const 1)))))
    (if (i32.eq (i32.load offset=72 (local.get $prm)) (i32.const 6)) (then
      (return (call $z80 (local.get $p) (local.get $prm)))))
    (if (i32.ge_u (i32.load offset=72 (local.get $prm)) (i32.const 7)) (then
      (return (call $cpu (local.get $p) (local.get $prm) (i32.load offset=72 (local.get $prm))))))
    (if (i32.ge_u (i32.load offset=72 (local.get $prm)) (i32.const 3)) (then
      (return (call $simple (local.get $p) (local.get $prm) (i32.load offset=72 (local.get $prm))))))
    (if (i32.load offset=72 (local.get $prm)) (then
      (return (call $brainfuck (local.get $p) (local.get $prm) (i32.eq (i32.load offset=72 (local.get $prm)) (i32.const 2))))))
    (local.set $w0 (i64.load (local.get $p)))
    (local.set $w1 (i64.load offset=8 (local.get $p)))
    (local.set $out (i32.load (local.get $prm)))
    (local.set $L (i32.load offset=4 (local.get $prm)))
    (local.set $textLen (i32.load offset=32 (local.get $prm)))
    (local.set $flags (i32.load offset=36 (local.get $prm)))
    (local.set $text (i32.sub (local.get $out) (local.get $textLen)))
    ;; header: cursor into the dictionary
    (local.set $cursor (i32.rem_u
      (i32.add
        (i32.mul (call $peek (local.get $w0) (local.get $w1) (i32.const 0) (i32.load offset=96 (local.get $prm)))
                 (i32.load offset=44 (local.get $prm)))
        (i32.load offset=100 (local.get $prm)))
      (local.get $textLen)))
    (i32.store offset=48 (local.get $prm) (local.get $cursor))
    (local.set $bp (i32.load offset=96 (local.get $prm)))
    (block $done (loop $cmd
      (br_if $done (i32.ge_u (local.get $pos) (local.get $L)))
      (br_if $done (i32.ge_u (local.get $bp) (i32.const 1024)))
      ;; copy length symbol: len = symbol + 2
      (local.set $entry (i32.load (i32.add (i32.load offset=8 (local.get $prm))
        (i32.shl (call $peek (local.get $w0) (local.get $w1) (local.get $bp) (i32.const 12)) (i32.const 2)))))
      (local.set $len (i32.add (i32.shr_u (local.get $entry) (i32.const 8)) (i32.const 2)))
      (local.set $bp (i32.add (local.get $bp) (i32.and (local.get $entry) (i32.const 255))))
      ;; 3-bit skip, then copy from the cursor
      (local.set $cursor (i32.rem_u
        (i32.add (local.get $cursor) (call $peek (local.get $w0) (local.get $w1) (local.get $bp) (i32.const 3)))
        (local.get $textLen)))
      (local.set $bp (i32.add (local.get $bp) (i32.const 3)))
      (local.set $cmds (i32.add (local.get $cmds) (i32.const 1)))
      (block $cdone (loop $copy
        (br_if $cdone (i32.or (i32.eqz (local.get $len)) (i32.ge_u (local.get $pos) (local.get $L))))
        (i32.store8 (i32.add (local.get $out) (local.get $pos))
          (i32.load8_u (i32.add (local.get $text) (local.get $cursor))))
        (i32.store8 (i32.add (local.get $flags) (local.get $pos)) (i32.and (local.get $cmds) (i32.const 1)))
        (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
        (local.set $cursor (i32.rem_u (i32.add (local.get $cursor) (i32.const 1)) (local.get $textLen)))
        (local.set $len (i32.sub (local.get $len) (i32.const 1)))
        (br $copy)))
      (br $cmd)))
    ;; fallback fill (cap reached): continue the dictionary from the cursor
    (block $fdone (loop $fill
      (br_if $fdone (i32.ge_u (local.get $pos) (local.get $L)))
      (i32.store8 (i32.add (local.get $out) (local.get $pos))
        (i32.load8_u (i32.add (local.get $text) (local.get $cursor))))
      (i32.store8 (i32.add (local.get $flags) (local.get $pos)) (i32.const 1))
      (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
      (local.set $cursor (i32.rem_u (i32.add (local.get $cursor) (i32.const 1)) (local.get $textLen)))
      (br $fill)))
    (i32.or (i32.shl (local.get $bp) (i32.const 8)) (local.get $cmds)))

  ;; change(n, grid, prm): run the byte changer on every pixel and write its 16-byte output
  ;; back over the pixel. Returns the number of pixels whose content changed.
  (func (export "change") (param $n i32) (param $grid i32) (param $prm i32) (result i32)
    (local $i i32) (local $p i32) (local $out i32) (local $o0 i64) (local $o1 i64) (local $changed i32)
    (local.set $out (i32.load (local.get $prm)))
    (block $exit (loop $loop
      (br_if $exit (i32.ge_u (local.get $i) (local.get $n)))
      (local.set $p (i32.add (local.get $grid) (i32.shl (local.get $i) (i32.const 4))))
      (drop (call $decode (local.get $p) (local.get $prm)))
      (local.set $o0 (i64.load (local.get $out)))
      (local.set $o1 (i64.load offset=8 (local.get $out)))
      (if (i32.or (i64.ne (local.get $o0) (i64.load (local.get $p))) (i64.ne (local.get $o1) (i64.load offset=8 (local.get $p))))
        (then
          (i64.store (local.get $p) (local.get $o0))
          (i64.store offset=8 (local.get $p) (local.get $o1))
          (local.set $changed (i32.add (local.get $changed) (i32.const 1)))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $loop)))
    (local.get $changed))

  ;; decode_pixel(grid, index, prm): inflate one pixel into the output buffer
  (func (export "decode_pixel") (param $grid i32) (param $index i32) (param $prm i32) (result i32)
    (call $decode (i32.add (local.get $grid) (i32.shl (local.get $index) (i32.const 4))) (local.get $prm)))
