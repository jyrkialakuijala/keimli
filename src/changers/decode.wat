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
  ;; 104 pairMode   0 = every cell on its own; 1 = pairs concatenated; 2 = pairs bit-interleaved; 3 = xor then add;
  ;;              4 = add then subtract (byte-wise lifting steps); 5 = byte-interleaved (see join)
  ;; 108 pairFlip   0 or 1: which cell of a pair takes the first role this turn (the host alternates it)
  ;; 112 pairBuf    32-byte scratch for the joint cell of a pair
  ;;
  ;; $cw is the cell width in bytes seen by every changer: 16, or 32 while a pair's joint cell is being changed.
  (global $cw (mut i32) (i32.const 16))
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
  ;; peekm(p, off, n): n <= 24 bits at bit offset off of the ring of $cw bytes at p (the 256-bit joint cell);
  ;; pk() chooses it when the cell is wide and the two-word peek otherwise, so single cells decode as before.
  (func $peekm (param $p i32) (param $off i32) (param $n i32) (result i32)
    (local $b i32) (local $k i32) (local $v i64) (local $m i32)
    (local.set $m (i32.sub (global.get $cw) (i32.const 1)))
    (local.set $off (i32.and (local.get $off) (i32.sub (i32.shl (global.get $cw) (i32.const 3)) (i32.const 1))))
    (local.set $b (i32.shr_u (local.get $off) (i32.const 3)))
    (block $e (loop $l (br_if $e (i32.ge_u (local.get $k) (i32.const 5)))
      (local.set $v (i64.or (local.get $v) (i64.shl
        (i64.load8_u (i32.add (local.get $p) (i32.and (i32.add (local.get $b) (local.get $k)) (local.get $m))))
        (i64.extend_i32_u (i32.shl (local.get $k) (i32.const 3))))))
      (local.set $k (i32.add (local.get $k) (i32.const 1))) (br $l)))
    (i32.and (i32.wrap_i64 (i64.shr_u (local.get $v) (i64.extend_i32_u (i32.and (local.get $off) (i32.const 7)))))
             (i32.sub (i32.shl (i32.const 1) (local.get $n)) (i32.const 1))))
  (func $pk (param $p i32) (param $w0 i64) (param $w1 i64) (param $off i32) (param $n i32) (result i32)
    (if (result i32) (i32.eq (global.get $cw) (i32.const 16))
      (then (call $peek (local.get $w0) (local.get $w1) (local.get $off) (local.get $n)))
      (else (call $peekm (local.get $p) (local.get $off) (local.get $n)))))
  ;; halfkind(kind): changers defined on exactly 128 bits (PDP-8, UNIVAC 1101, CDC 6600); a joint cell is handed
  ;; to them as two consecutive 16-byte cells. (The DCT scales with the cell width: 32 points on a joint cell.)
  (func $halfkind (param $k i32) (result i32)
    (i32.or (i32.eq (local.get $k) (i32.const 19)) (i32.or (i32.eq (local.get $k) (i32.const 22)) (i32.eq (local.get $k) (i32.const 24)))))

  (func $decode (param $p i32) (param $prm i32) (result i32)
    (local $w0 i64) (local $w1 i64) (local $bp i32)
    (local $out i32) (local $L i32) (local $flags i32) (local $textLen i32) (local $text i32)
    (local $pos i32) (local $entry i32) (local $len i32) (local $cursor i32) (local $cmds i32)
    (if (i32.and (i32.eq (global.get $cw) (i32.const 32)) (call $halfkind (i32.load offset=72 (local.get $prm)))) (then
      (local.set $out (i32.load (local.get $prm))) (local.set $flags (i32.load offset=36 (local.get $prm)))
      (global.set $cw (i32.const 16))
      (drop (call $decode (local.get $p) (local.get $prm)))
      (i32.store (local.get $prm) (i32.add (local.get $out) (i32.const 16)))
      (i32.store offset=36 (local.get $prm) (i32.add (local.get $flags) (i32.const 16)))
      (local.set $cmds (call $decode (i32.add (local.get $p) (i32.const 16)) (local.get $prm)))
      (i32.store (local.get $prm) (local.get $out))
      (i32.store offset=36 (local.get $prm) (local.get $flags))
      (global.set $cw (i32.const 32))
      (return (local.get $cmds))))
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
    (local.set $L (global.get $cw))   ;; output bytes: the cell width (prm.outLen is 16, the single-cell value)
    (local.set $textLen (i32.load offset=32 (local.get $prm)))
    (local.set $flags (i32.load offset=36 (local.get $prm)))
    (local.set $text (i32.sub (local.get $out) (local.get $textLen)))
    ;; header: cursor into the dictionary
    (local.set $cursor (i32.rem_u
      (i32.add
        (i32.mul (call $pk (local.get $p) (local.get $w0) (local.get $w1) (i32.const 0) (i32.load offset=96 (local.get $prm)))
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
        (i32.shl (call $pk (local.get $p) (local.get $w0) (local.get $w1) (local.get $bp) (i32.const 12)) (i32.const 2)))))
      (local.set $len (i32.add (i32.shr_u (local.get $entry) (i32.const 8)) (i32.const 2)))
      (local.set $bp (i32.add (local.get $bp) (i32.and (local.get $entry) (i32.const 255))))
      ;; 3-bit skip, then copy from the cursor
      (local.set $cursor (i32.rem_u
        (i32.add (local.get $cursor) (call $pk (local.get $p) (local.get $w0) (local.get $w1) (local.get $bp) (i32.const 3)))
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

  ;; ---- pairs: two cells changed together ----
  ;; spread(x): the 32 low bits of x moved to the even bit positions of an i64; squeeze(x): the inverse.
  (func $spread (param $x i64) (result i64)
    (local.set $x (i64.and (i64.or (local.get $x) (i64.shl (local.get $x) (i64.const 16))) (i64.const 0x0000FFFF0000FFFF)))
    (local.set $x (i64.and (i64.or (local.get $x) (i64.shl (local.get $x) (i64.const 8))) (i64.const 0x00FF00FF00FF00FF)))
    (local.set $x (i64.and (i64.or (local.get $x) (i64.shl (local.get $x) (i64.const 4))) (i64.const 0x0F0F0F0F0F0F0F0F)))
    (local.set $x (i64.and (i64.or (local.get $x) (i64.shl (local.get $x) (i64.const 2))) (i64.const 0x3333333333333333)))
    (i64.and (i64.or (local.get $x) (i64.shl (local.get $x) (i64.const 1))) (i64.const 0x5555555555555555)))
  (func $squeeze (param $x i64) (result i64)
    (local.set $x (i64.and (local.get $x) (i64.const 0x5555555555555555)))
    (local.set $x (i64.and (i64.or (local.get $x) (i64.shr_u (local.get $x) (i64.const 1))) (i64.const 0x3333333333333333)))
    (local.set $x (i64.and (i64.or (local.get $x) (i64.shr_u (local.get $x) (i64.const 2))) (i64.const 0x0F0F0F0F0F0F0F0F)))
    (local.set $x (i64.and (i64.or (local.get $x) (i64.shr_u (local.get $x) (i64.const 4))) (i64.const 0x00FF00FF00FF00FF)))
    (local.set $x (i64.and (i64.or (local.get $x) (i64.shr_u (local.get $x) (i64.const 8))) (i64.const 0x0000FFFF0000FFFF)))
    (i64.and (i64.or (local.get $x) (i64.shr_u (local.get $x) (i64.const 16))) (i64.const 0x00000000FFFFFFFF)))
  ;; join(a, b, j, mode, flip): build the 32-byte joint cell at j from the pixels at a and b. mode 1 concatenates
  ;; (a then b), mode 2 interleaves bit by bit (pixel bit k of a at joint bit 2k, of b at 2k + 1). Modes 3 and 4 are
  ;; byte-wise lifting steps, each byte k of the two cells giving byte k and byte 16 + k of the joint cell:
  ;;   3, xor then add:       x = a ^ b,  y = b + x
  ;;   4, add then subtract:  s = a + b,  d = a - (s >> 1)
  ;; (bytes mod 256; >> is the unsigned shift). Both are bijections on the pair of bytes, inverted exactly by split.
  ;; Mode 5 interleaves byte by byte: byte k of a at joint byte 2k, of b at 2k + 1.
  ;; flip = 1 swaps the roles of a and b, so on alternating turns the pair is b-a, b on the even positions, etc.
  (func $join (param $a i32) (param $b i32) (param $j i32) (param $mode i32) (param $flip i32)
    (local $m i32) (local $t i32) (local $x i32) (local $y i32)
    (if (local.get $flip) (then (local.set $t (local.get $a)) (local.set $a (local.get $b)) (local.set $b (local.get $t))))
    (if (i32.eq (local.get $mode) (i32.const 1))
      (then
        (i64.store (local.get $j) (i64.load (local.get $a))) (i64.store offset=8 (local.get $j) (i64.load offset=8 (local.get $a)))
        (i64.store offset=16 (local.get $j) (i64.load (local.get $b))) (i64.store offset=24 (local.get $j) (i64.load offset=8 (local.get $b))))
      (else (if (i32.eq (local.get $mode) (i32.const 2))
        (then   ;; joint word m: even bits from a's 32-bit chunk m, odd bits from b's
          (block $e (loop $l (br_if $e (i32.ge_u (local.get $m) (i32.const 4)))
            (i64.store (i32.add (local.get $j) (i32.shl (local.get $m) (i32.const 3)))
              (i64.or (call $spread (i64.load32_u (i32.add (local.get $a) (i32.shl (local.get $m) (i32.const 2)))))
                      (i64.shl (call $spread (i64.load32_u (i32.add (local.get $b) (i32.shl (local.get $m) (i32.const 2))))) (i64.const 1))))
            (local.set $m (i32.add (local.get $m) (i32.const 1))) (br $l))))
        (else (if (i32.eq (local.get $mode) (i32.const 5))
        (then   ;; byte-interleaved
          (block $e (loop $l (br_if $e (i32.ge_u (local.get $m) (i32.const 16)))
            (i32.store8 (i32.add (local.get $j) (i32.shl (local.get $m) (i32.const 1))) (i32.load8_u (i32.add (local.get $a) (local.get $m))))
            (i32.store8 offset=1 (i32.add (local.get $j) (i32.shl (local.get $m) (i32.const 1))) (i32.load8_u (i32.add (local.get $b) (local.get $m))))
            (local.set $m (i32.add (local.get $m) (i32.const 1))) (br $l))))
        (else   ;; byte-wise lifting: x (or s) to the first half, y (or d) to the second
          (block $e (loop $l (br_if $e (i32.ge_u (local.get $m) (i32.const 16)))
            (local.set $x (i32.load8_u (i32.add (local.get $a) (local.get $m))))
            (local.set $y (i32.load8_u (i32.add (local.get $b) (local.get $m))))
            (if (i32.eq (local.get $mode) (i32.const 3))
              (then (local.set $x (i32.xor (local.get $x) (local.get $y))) (local.set $y (i32.add (local.get $y) (local.get $x))))
              (else (local.set $t (i32.and (i32.add (local.get $x) (local.get $y)) (i32.const 255)))
                    (local.set $y (i32.sub (local.get $x) (i32.shr_u (local.get $t) (i32.const 1)))) (local.set $x (local.get $t))))
            (i32.store8 (i32.add (local.get $j) (local.get $m)) (local.get $x))
            (i32.store8 offset=16 (i32.add (local.get $j) (local.get $m)) (local.get $y))
            (local.set $m (i32.add (local.get $m) (i32.const 1))) (br $l))))))))))
  ;; split(o, a, b, mode, flip): the inverse of join, from the 32-byte joint cell at o to 16 bytes at a and at b.
  ;; Modes 3 and 4 invert the lifting steps: b = y - x, a = x ^ b; and a = d + (s >> 1), b = s - a. Mode 5 de-interleaves bytes.
  (func $split (param $o i32) (param $a i32) (param $b i32) (param $mode i32) (param $flip i32)
    (local $m i32) (local $t i32) (local $w i64) (local $x i32) (local $y i32)
    (if (local.get $flip) (then (local.set $t (local.get $a)) (local.set $a (local.get $b)) (local.set $b (local.get $t))))
    (if (i32.eq (local.get $mode) (i32.const 1))
      (then
        (i64.store (local.get $a) (i64.load (local.get $o))) (i64.store offset=8 (local.get $a) (i64.load offset=8 (local.get $o)))
        (i64.store (local.get $b) (i64.load offset=16 (local.get $o))) (i64.store offset=8 (local.get $b) (i64.load offset=24 (local.get $o))))
      (else (if (i32.eq (local.get $mode) (i32.const 2))
        (then
          (block $e (loop $l (br_if $e (i32.ge_u (local.get $m) (i32.const 4)))
            (local.set $w (i64.load (i32.add (local.get $o) (i32.shl (local.get $m) (i32.const 3)))))
            (i64.store32 (i32.add (local.get $a) (i32.shl (local.get $m) (i32.const 2))) (call $squeeze (local.get $w)))
            (i64.store32 (i32.add (local.get $b) (i32.shl (local.get $m) (i32.const 2))) (call $squeeze (i64.shr_u (local.get $w) (i64.const 1))))
            (local.set $m (i32.add (local.get $m) (i32.const 1))) (br $l))))
        (else (if (i32.eq (local.get $mode) (i32.const 5))
        (then
          (block $e (loop $l (br_if $e (i32.ge_u (local.get $m) (i32.const 16)))
            (i32.store8 (i32.add (local.get $a) (local.get $m)) (i32.load8_u (i32.add (local.get $o) (i32.shl (local.get $m) (i32.const 1)))))
            (i32.store8 (i32.add (local.get $b) (local.get $m)) (i32.load8_u offset=1 (i32.add (local.get $o) (i32.shl (local.get $m) (i32.const 1)))))
            (local.set $m (i32.add (local.get $m) (i32.const 1))) (br $l))))
        (else
          (block $e (loop $l (br_if $e (i32.ge_u (local.get $m) (i32.const 16)))
            (local.set $x (i32.load8_u (i32.add (local.get $o) (local.get $m))))
            (local.set $y (i32.load8_u offset=16 (i32.add (local.get $o) (local.get $m))))
            (if (i32.eq (local.get $mode) (i32.const 3))
              (then (local.set $y (i32.and (i32.sub (local.get $y) (local.get $x)) (i32.const 255))) (local.set $x (i32.xor (local.get $x) (local.get $y))))
              (else (local.set $t (i32.and (i32.add (local.get $y) (i32.shr_u (local.get $x) (i32.const 1))) (i32.const 255)))
                    (local.set $y (i32.sub (local.get $x) (local.get $t))) (local.set $x (local.get $t))))
            (i32.store8 (i32.add (local.get $a) (local.get $m)) (local.get $x))
            (i32.store8 (i32.add (local.get $b) (local.get $m)) (local.get $y))
            (local.set $m (i32.add (local.get $m) (i32.const 1))) (br $l))))))))))
  ;; commit(p, s): copy the 16 bytes at s over the pixel at p if they differ; returns 1 if they did
  (func $commit (param $p i32) (param $s i32) (result i32)
    (local $o0 i64) (local $o1 i64)
    (local.set $o0 (i64.load (local.get $s))) (local.set $o1 (i64.load offset=8 (local.get $s)))
    (if (result i32) (i32.or (i64.ne (local.get $o0) (i64.load (local.get $p))) (i64.ne (local.get $o1) (i64.load offset=8 (local.get $p))))
      (then (i64.store (local.get $p) (local.get $o0)) (i64.store offset=8 (local.get $p) (local.get $o1)) (i32.const 1))
      (else (i32.const 0))))

  ;; change(n, grid, prm): run the local changer on every pixel and write its 16-byte output back over the
  ;; pixel. With prm.pairMode set, pixels 2i and 2i + 1 (a horizontal pair: the width is even, so a pair never
  ;; crosses a row) are joined into a 32-byte cell (see join), changed once as a whole with $cw = 32, and split
  ;; back by the inverse mapping. Returns the number of pixels whose content changed.
  (func (export "change") (param $n i32) (param $grid i32) (param $prm i32) (result i32)
    (local $i i32) (local $p i32) (local $out i32) (local $changed i32) (local $mode i32) (local $flip i32) (local $j i32)
    (local.set $out (i32.load (local.get $prm)))
    (local.set $mode (i32.load offset=104 (local.get $prm)))
    (if (i32.eqz (local.get $mode)) (then
      (block $exit (loop $loop
        (br_if $exit (i32.ge_u (local.get $i) (local.get $n)))
        (local.set $p (i32.add (local.get $grid) (i32.shl (local.get $i) (i32.const 4))))
        (drop (call $decode (local.get $p) (local.get $prm)))
        (local.set $changed (i32.add (local.get $changed) (call $commit (local.get $p) (local.get $out))))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $loop)))
      (return (local.get $changed))))
    (local.set $flip (i32.load offset=108 (local.get $prm)))
    (local.set $j (i32.load offset=112 (local.get $prm)))
    (global.set $cw (i32.const 32))
    (block $exit (loop $loop
      (br_if $exit (i32.ge_u (i32.add (local.get $i) (i32.const 1)) (local.get $n)))
      (local.set $p (i32.add (local.get $grid) (i32.shl (local.get $i) (i32.const 4))))
      (call $join (local.get $p) (i32.add (local.get $p) (i32.const 16)) (local.get $j) (local.get $mode) (local.get $flip))
      (drop (call $decode (local.get $j) (local.get $prm)))
      (call $split (local.get $out) (local.get $j) (i32.add (local.get $j) (i32.const 16)) (local.get $mode) (local.get $flip))
      (local.set $changed (i32.add (local.get $changed) (call $commit (local.get $p) (local.get $j))))
      (local.set $changed (i32.add (local.get $changed) (call $commit (i32.add (local.get $p) (i32.const 16)) (i32.add (local.get $j) (i32.const 16)))))
      (local.set $i (i32.add (local.get $i) (i32.const 2)))
      (br $loop)))
    (global.set $cw (i32.const 16))
    (local.get $changed))

  ;; decode_pixel(grid, index, prm): inflate one pixel into the output buffer
  (func (export "decode_pixel") (param $grid i32) (param $index i32) (param $prm i32) (result i32)
    (call $decode (i32.add (local.get $grid) (i32.shl (local.get $index) (i32.const 4))) (local.get $prm)))
