  ;; Motorola 68000 (kind 21) and 68020 (kind 25, the same core with $m20 set: the full extension word with base
  ;; displacement, scaled index and memory indirection, MULU.L/MULS.L/DIVU.L/DIVS.L with 64-bit forms, the bit field
  ;; instructions, EXTB.L, LINK.L, Bcc.L, RTD, CAS, CMP2/CHK2; TRAPcc, PACK/UNPK, CAS2, CALLM/RTM, MOVEC/MOVES, BKPT and
  ;; the coprocessor line are NOPs). Register file: D0..D7 as i32 at offset 64 + 4n,
  ;; A0..A7 at 96 + 4n (A7 = SP), SR at 20 (X 16, N 8, Z 4, V 2, C 1), PC at
  ;; 22. Memory is the pixel: 16 bytes, big-endian, every access wrapping mod 16
  ;; byte by byte (so odd addresses are fine). All 68000 addressing modes incl.
  ;; the brief extension word; the integer instruction set: MOVE/MOVEA/MOVEQ,
  ;; ADD SUB CMP AND OR EOR with their I/Q/A/X/M forms, NEG NEGX NOT CLR TST
  ;; TAS EXT SWAP, the bit instructions, all shifts and rotates, MULU MULS
  ;; DIVU DIVS, Bcc BRA BSR DBcc Scc JMP JSR RTS RTR RTE, LEA PEA LINK UNLK
  ;; MOVEM EXG, MOVE to/from SR/CCR. ABCD SBCD NBCD CHK TRAP TRAPV STOP RESET
  ;; ILLEGAL MOVEP MOVE USP and lines A/F are NOPs; divide by zero is a NOP.
  (func $m_d (param $n i32) (result i32) (i32.load offset=320 (i32.shl (i32.and (local.get $n) (i32.const 7)) (i32.const 2))))
  (func $m_dw (param $n i32) (param $v i32) (i32.store offset=320 (i32.shl (i32.and (local.get $n) (i32.const 7)) (i32.const 2)) (local.get $v)))
  (func $m_a (param $n i32) (result i32) (i32.load offset=352 (i32.shl (i32.and (local.get $n) (i32.const 7)) (i32.const 2))))
  (func $m_aw (param $n i32) (param $v i32) (i32.store offset=352 (i32.shl (i32.and (local.get $n) (i32.const 7)) (i32.const 2)) (local.get $v)))
  (func $m_rr (param $k i32) (result i32) (if (result i32) (i32.and (local.get $k) (i32.const 8)) (then (call $m_a (local.get $k))) (else (call $m_d (local.get $k)))))
  (func $m_rw (param $k i32) (param $v i32) (if (i32.and (local.get $k) (i32.const 8)) (then (call $m_aw (local.get $k) (local.get $v))) (else (call $m_dw (local.get $k) (local.get $v)))))
  (func $m_rd32 (param $a i32) (result i32) (i32.or (i32.shl (call $mrd16be (local.get $a)) (i32.const 16)) (call $mrd16be (i32.add (local.get $a) (i32.const 2)))))
  (func $m_wr32 (param $a i32) (param $v i32) (call $mwr16be (local.get $a) (i32.shr_u (local.get $v) (i32.const 16))) (call $mwr16be (i32.add (local.get $a) (i32.const 2)) (i32.and (local.get $v) (i32.const 0xffff))))
  (func $m_fetch (result i32) (local $pc i32)
    (local.set $pc (call $zr16 (i32.const 22))) (call $zw16 (i32.const 22) (i32.and (i32.add (local.get $pc) (i32.const 2)) (i32.const 0xffff))) (call $mrd16be (local.get $pc)))
  (func $m_fetch32 (result i32) (local $hi i32) (local.set $hi (call $m_fetch)) (i32.or (i32.shl (local.get $hi) (i32.const 16)) (call $m_fetch)))
  (func $m_push (param $v i32) (call $m_aw (i32.const 7) (i32.sub (call $m_a (i32.const 7)) (i32.const 4))) (call $m_wr32 (call $m_a (i32.const 7)) (local.get $v)))
  (func $m_pop (result i32) (local $v i32) (local.set $v (call $m_rd32 (call $m_a (i32.const 7)))) (call $m_aw (i32.const 7) (i32.add (call $m_a (i32.const 7)) (i32.const 4))) (local.get $v))
  (func $m_push16 (param $v i32) (call $m_aw (i32.const 7) (i32.sub (call $m_a (i32.const 7)) (i32.const 2))) (call $mwr16be (call $m_a (i32.const 7)) (local.get $v)))
  (func $m_pop16 (result i32) (local $v i32) (local.set $v (call $mrd16be (call $m_a (i32.const 7)))) (call $m_aw (i32.const 7) (i32.add (call $m_a (i32.const 7)) (i32.const 2))) (local.get $v))
  (func $m_mask (param $sz i32) (result i32) (select (i32.const 0xff) (select (i32.const 0xffff) (i32.const -1) (i32.eq (local.get $sz) (i32.const 1))) (i32.eqz (local.get $sz))))
  (func $m_msb (param $sz i32) (result i32) (select (i32.const 0x80) (select (i32.const 0x8000) (i32.const 0x80000000) (i32.eq (local.get $sz) (i32.const 1))) (i32.eqz (local.get $sz))))
  (func $m_sx (param $v i32) (param $sz i32) (result i32)   ;; sign-extend a byte/word/long operand to 32 bits
    (select (call $sext8 (local.get $v)) (select (call $sx (local.get $v) (i32.const 16)) (local.get $v) (i32.eq (local.get $sz) (i32.const 1))) (i32.eqz (local.get $sz))))
  ;; index from a brief extension word: Dn/An, word (sign-extended) or long, plus the 8-bit displacement
  (global $m20 (mut i32) (i32.const 0))   ;; 1 while a 68020 runs
  (func $m_index (param $ext i32) (result i32)
    (local $v i32)
    (local.set $v (call $m_rr (i32.and (i32.shr_u (local.get $ext) (i32.const 12)) (i32.const 15))))
    (if (i32.eqz (i32.and (local.get $ext) (i32.const 0x800))) (then (local.set $v (call $sx (local.get $v) (i32.const 16)))))
    (if (global.get $m20) (then (local.set $v (i32.shl (local.get $v) (i32.and (i32.shr_u (local.get $ext) (i32.const 9)) (i32.const 3))))))   ;; 68020: scale 1, 2, 4, 8
    (i32.add (local.get $v) (call $sext8 (local.get $ext))))
  ;; 68020 full extension word (bit 8): base displacement (bits 5..4: 2 word, 3 long), base suppress (bit 7), index
  ;; suppress (bit 6), scaled index, and memory indirection (bits 2..0: 0 none, 1..3 pre-indexed with a null, word
  ;; or long outer displacement, 5..7 post-indexed)
  (func $m_full (param $ext i32) (param $base i32) (result i32)
    (local $bd i32) (local $od i32) (local $idx i32) (local $iis i32) (local $a i32)
    (local.set $bd (i32.and (i32.shr_u (local.get $ext) (i32.const 4)) (i32.const 3)))
    (if (i32.eq (local.get $bd) (i32.const 2)) (then (local.set $bd (call $sx (call $m_fetch) (i32.const 16))))
      (else (if (i32.eq (local.get $bd) (i32.const 3)) (then (local.set $bd (call $m_fetch32))) (else (local.set $bd (i32.const 0))))))
    (if (i32.and (local.get $ext) (i32.const 0x80)) (then (local.set $base (i32.const 0))))
    (if (i32.eqz (i32.and (local.get $ext) (i32.const 0x40))) (then
      (local.set $idx (call $m_rr (i32.and (i32.shr_u (local.get $ext) (i32.const 12)) (i32.const 15))))
      (if (i32.eqz (i32.and (local.get $ext) (i32.const 0x800))) (then (local.set $idx (call $sx (local.get $idx) (i32.const 16)))))
      (local.set $idx (i32.shl (local.get $idx) (i32.and (i32.shr_u (local.get $ext) (i32.const 9)) (i32.const 3))))))
    (local.set $iis (i32.and (local.get $ext) (i32.const 7)))
    (if (i32.eqz (local.get $iis)) (then (return (i32.add (i32.add (local.get $base) (local.get $bd)) (local.get $idx)))))
    (local.set $od (i32.and (local.get $iis) (i32.const 3)))
    (if (i32.eq (local.get $od) (i32.const 2)) (then (local.set $od (call $sx (call $m_fetch) (i32.const 16))))
      (else (if (i32.eq (local.get $od) (i32.const 3)) (then (local.set $od (call $m_fetch32))) (else (local.set $od (i32.const 0))))))
    (local.set $a (i32.add (local.get $base) (local.get $bd)))
    (if (i32.lt_u (local.get $iis) (i32.const 4)) (then (local.set $a (i32.add (local.get $a) (local.get $idx))) (local.set $idx (i32.const 0))))   ;; pre-indexed
    (i32.add (i32.add (call $m_rd32 (i32.and (local.get $a) (i32.const 0xffff))) (local.get $idx)) (local.get $od)))
  (func $m_xidx (param $ext i32) (param $base i32) (result i32)   ;; indexed address from a brief or (68020) full extension word
    (if (result i32) (i32.and (global.get $m20) (i32.ne (i32.and (local.get $ext) (i32.const 0x100)) (i32.const 0)))
      (then (call $m_full (local.get $ext) (local.get $base)))
      (else (i32.add (local.get $base) (call $m_index (local.get $ext))))))
  ;; effective address with side effects; registers are reported as 0x10000 + n (Dn) and 0x20000 + n (An)
  (func $m_ea (param $mode i32) (param $reg i32) (param $sz i32) (result i32)
    (local $a i32) (local $n i32) (local $pc i32)
    (local.set $n (i32.shl (i32.const 1) (local.get $sz)))
    (if (i32.and (i32.eqz (local.get $sz)) (i32.eq (local.get $reg) (i32.const 7))) (then (local.set $n (i32.const 2))))   ;; byte on the stack pointer moves by 2
    (block $done
      (if (i32.eqz (local.get $mode)) (then (return (i32.add (i32.const 0x10000) (local.get $reg)))))
      (if (i32.eq (local.get $mode) (i32.const 1)) (then (return (i32.add (i32.const 0x20000) (local.get $reg)))))
      (local.set $a (call $m_a (local.get $reg)))
      (if (i32.eq (local.get $mode) (i32.const 2)) (then (br $done)))
      (if (i32.eq (local.get $mode) (i32.const 3)) (then (call $m_aw (local.get $reg) (i32.add (local.get $a) (local.get $n))) (br $done)))
      (if (i32.eq (local.get $mode) (i32.const 4)) (then (local.set $a (i32.sub (local.get $a) (local.get $n))) (call $m_aw (local.get $reg) (local.get $a)) (br $done)))
      (if (i32.eq (local.get $mode) (i32.const 5)) (then (local.set $a (i32.add (local.get $a) (call $sx (call $m_fetch) (i32.const 16)))) (br $done)))
      (if (i32.eq (local.get $mode) (i32.const 6)) (then (local.set $a (call $m_xidx (call $m_fetch) (local.get $a))) (br $done)))
      (local.set $pc (call $zr16 (i32.const 22)))
      (if (i32.eqz (local.get $reg)) (then (local.set $a (call $sx (call $m_fetch) (i32.const 16))) (br $done)))
      (if (i32.eq (local.get $reg) (i32.const 1)) (then (local.set $a (call $m_fetch32)) (br $done)))
      (if (i32.eq (local.get $reg) (i32.const 2)) (then (local.set $a (i32.add (local.get $pc) (call $sx (call $m_fetch) (i32.const 16)))) (br $done)))
      (if (i32.eq (local.get $reg) (i32.const 3)) (then (local.set $a (call $m_xidx (call $m_fetch) (local.get $pc))) (br $done)))
      ;; immediate (reg 4) and the invalid forms 5..7: the operand is the next word(s)
      (local.set $a (select (i32.add (local.get $pc) (i32.const 1)) (local.get $pc) (i32.eqz (local.get $sz))))
      (call $zw16 (i32.const 22) (i32.and (i32.add (local.get $pc) (select (i32.const 4) (i32.const 2) (i32.eq (local.get $sz) (i32.const 2)))) (i32.const 0xffff))))
    (i32.and (local.get $a) (i32.const 0xffff)))
  (func $m_ld (param $ea i32) (param $sz i32) (result i32)
    (if (i32.ge_u (local.get $ea) (i32.const 0x10000)) (then (return (i32.and (call $m_rr (i32.or (i32.and (local.get $ea) (i32.const 7)) (select (i32.const 8) (i32.const 0) (i32.and (local.get $ea) (i32.const 0x20000))))) (call $m_mask (local.get $sz))))))
    (if (i32.eqz (local.get $sz)) (then (return (call $mrd (local.get $ea)))))
    (if (i32.eq (local.get $sz) (i32.const 1)) (then (return (call $mrd16be (local.get $ea)))))
    (call $m_rd32 (local.get $ea)))
  (func $m_st (param $ea i32) (param $sz i32) (param $v i32)
    (local $n i32)
    (if (i32.ge_u (local.get $ea) (i32.const 0x10000)) (then
      (local.set $n (i32.and (local.get $ea) (i32.const 7)))
      (if (i32.and (local.get $ea) (i32.const 0x20000))
        (then (call $m_aw (local.get $n) (call $m_sx (local.get $v) (local.get $sz))))   ;; address registers take the whole 32 bits, sign-extended
        (else (call $m_dw (local.get $n) (i32.or (i32.and (call $m_d (local.get $n)) (i32.xor (call $m_mask (local.get $sz)) (i32.const -1))) (i32.and (local.get $v) (call $m_mask (local.get $sz)))))))
      (return)))
    (if (i32.eqz (local.get $sz)) (then (call $mwr (local.get $ea) (i32.and (local.get $v) (i32.const 255))) (return)))
    (if (i32.eq (local.get $sz) (i32.const 1)) (then (call $mwr16be (local.get $ea) (i32.and (local.get $v) (i32.const 0xffff))) (return)))
    (call $m_wr32 (local.get $ea) (local.get $v)))
  ;; SR <- N Z from r (width sz), V and C as given; x: 0 keep X, 1 X = C
  (func $m_fl (param $r i32) (param $sz i32) (param $v i32) (param $c i32) (param $x i32)
    (local $sr i32)
    (local.set $sr (i32.and (call $zr16 (i32.const 20)) (select (i32.const 0xffe0) (i32.const 0xfff0) (local.get $x))))
    (call $zw16 (i32.const 20) (i32.or (local.get $sr) (i32.or (i32.or
      (select (i32.const 8) (i32.const 0) (i32.and (local.get $r) (call $m_msb (local.get $sz))))
      (select (i32.const 4) (i32.const 0) (i32.eqz (i32.and (local.get $r) (call $m_mask (local.get $sz))))))
      (i32.or (i32.or (i32.shl (i32.ne (local.get $v) (i32.const 0)) (i32.const 1)) (i32.ne (local.get $c) (i32.const 0)))
              (select (i32.shl (i32.ne (local.get $c) (i32.const 0)) (i32.const 4)) (i32.const 0) (local.get $x)))))))
  (func $m_X (result i32) (i32.and (i32.shr_u (call $zr16 (i32.const 20)) (i32.const 4)) (i32.const 1)))
  (func $m_cc (param $k i32) (result i32)   ;; T F HI LS CC CS NE EQ VC VS GE LT GT LE
    (local $p i32) (local $n i32) (local $z i32) (local $v i32) (local $c i32)
    (local.set $p (call $zr16 (i32.const 20)))
    (local.set $n (i32.and (i32.shr_u (local.get $p) (i32.const 3)) (i32.const 1))) (local.set $z (i32.and (i32.shr_u (local.get $p) (i32.const 2)) (i32.const 1)))
    (local.set $v (i32.and (i32.shr_u (local.get $p) (i32.const 1)) (i32.const 1))) (local.set $c (i32.and (local.get $p) (i32.const 1)))
    (block $b15 (block $b14 (block $b13 (block $b12 (block $b11 (block $b10 (block $b9 (block $b8 (block $b7 (block $b6 (block $b5 (block $b4 (block $b3 (block $b2 (block $b1 (block $b0
      (br_table $b0 $b1 $b2 $b3 $b4 $b5 $b6 $b7 $b8 $b9 $b10 $b11 $b12 $b13 $b14 $b15 (i32.and (local.get $k) (i32.const 15))))
      (return (i32.const 1)))
      (return (i32.const 0)))
      (return (i32.eqz (i32.or (local.get $c) (local.get $z)))))
      (return (i32.or (local.get $c) (local.get $z))))
      (return (i32.eqz (local.get $c))))
      (return (local.get $c)))
      (return (i32.eqz (local.get $z))))
      (return (local.get $z)))
      (return (i32.eqz (local.get $v))))
      (return (local.get $v)))
      (return (i32.eqz (i32.xor (local.get $n) (local.get $v)))))
      (return (i32.xor (local.get $n) (local.get $v))))
      (return (i32.eqz (i32.or (local.get $z) (i32.xor (local.get $n) (local.get $v))))))
      (return (i32.or (local.get $z) (i32.xor (local.get $n) (local.get $v))))))
    (i32.const 0))
  ;; add/subtract with flags: mode bit 1 = subtract (d - s), 2 = include X, 4 = Z sticky (X forms), 8 = compare (X untouched)
  (func $m_arith (param $d i32) (param $s i32) (param $sz i32) (param $mode i32) (result i32)
    (local $a i32) (local $b i32) (local $r i32) (local $x i32) (local $v i32) (local $c i32) (local $msb i32) (local $mask i32) (local $z i32)
    (local.set $mask (call $m_mask (local.get $sz))) (local.set $msb (call $m_msb (local.get $sz)))
    (local.set $a (i32.and (local.get $d) (local.get $mask))) (local.set $b (i32.and (local.get $s) (local.get $mask)))
    (if (i32.and (local.get $mode) (i32.const 2)) (then (local.set $x (call $m_X))))
    (if (i32.and (local.get $mode) (i32.const 1))
      (then (local.set $r (i32.and (i32.sub (i32.sub (local.get $a) (local.get $b)) (local.get $x)) (local.get $mask)))
        (local.set $v (i32.and (i32.and (i32.xor (local.get $a) (local.get $b)) (i32.xor (local.get $a) (local.get $r))) (local.get $msb)))
        (local.set $c (i32.and (i32.or (i32.and (i32.xor (local.get $a) (i32.const -1)) (local.get $b)) (i32.and (i32.or (i32.xor (local.get $a) (i32.const -1)) (local.get $b)) (local.get $r))) (local.get $msb))))
      (else (local.set $r (i32.and (i32.add (i32.add (local.get $a) (local.get $b)) (local.get $x)) (local.get $mask)))
        (local.set $v (i32.and (i32.and (i32.xor (local.get $a) (local.get $r)) (i32.xor (local.get $b) (local.get $r))) (local.get $msb)))
        (local.set $c (i32.and (i32.or (i32.and (local.get $a) (local.get $b)) (i32.and (i32.or (local.get $a) (local.get $b)) (i32.xor (local.get $r) (i32.const -1)))) (local.get $msb)))))
    (local.set $z (i32.and (call $zr16 (i32.const 20)) (i32.const 4)))
    (call $m_fl (local.get $r) (local.get $sz) (local.get $v) (local.get $c) (i32.eqz (i32.and (local.get $mode) (i32.const 8))))
    (if (i32.and (i32.and (local.get $mode) (i32.const 4)) (i32.eqz (local.get $z))) (then (call $zw16 (i32.const 20) (i32.and (call $zr16 (i32.const 20)) (i32.const 0xfffb)))))   ;; sticky Z: only ever cleared
    (local.get $r))
  ;; shifts and rotates one bit at a time: type 0 AS, 1 LS, 2 ROX, 3 RO; returns the result and sets the flags
  (func $m_shift (param $type i32) (param $left i32) (param $cnt i32) (param $v i32) (param $sz i32) (result i32)
    (local $r i32) (local $c i32) (local $x i32) (local $ov i32) (local $msb i32) (local $mask i32) (local $top i32) (local $sign i32)
    (local.set $mask (call $m_mask (local.get $sz))) (local.set $msb (call $m_msb (local.get $sz))) (local.set $top (i32.sub (i32.shl (i32.const 8) (local.get $sz)) (i32.const 1)))
    (local.set $r (i32.and (local.get $v) (local.get $mask))) (local.set $x (call $m_X)) (local.set $sign (i32.and (local.get $r) (local.get $msb)))
    (if (i32.eqz (local.get $cnt)) (then
      (call $m_fl (local.get $r) (local.get $sz) (i32.const 0) (select (local.get $x) (i32.const 0) (i32.eq (local.get $type) (i32.const 2))) (i32.const 0))
      (return (local.get $r))))
    (block $e (loop $l (br_if $e (i32.eqz (local.get $cnt)))
      (if (local.get $left)
        (then (local.set $c (i32.ne (i32.and (local.get $r) (local.get $msb)) (i32.const 0)))
          (local.set $r (i32.and (i32.shl (local.get $r) (i32.const 1)) (local.get $mask)))
          (if (i32.eq (local.get $type) (i32.const 2)) (then (local.set $r (i32.or (local.get $r) (local.get $x)))))
          (if (i32.eq (local.get $type) (i32.const 3)) (then (local.set $r (i32.or (local.get $r) (local.get $c)))))
          (if (i32.ne (i32.and (local.get $r) (local.get $msb)) (local.get $sign)) (then (local.set $ov (i32.const 1)))))
        (else (local.set $c (i32.and (local.get $r) (i32.const 1)))
          (local.set $r (i32.shr_u (local.get $r) (i32.const 1)))
          (if (i32.eqz (local.get $type)) (then (local.set $r (i32.or (local.get $r) (local.get $sign)))))
          (if (i32.eq (local.get $type) (i32.const 2)) (then (local.set $r (i32.or (local.get $r) (i32.shl (local.get $x) (local.get $top))))))
          (if (i32.eq (local.get $type) (i32.const 3)) (then (local.set $r (i32.or (local.get $r) (i32.shl (local.get $c) (local.get $top))))))))
      (if (i32.ne (local.get $type) (i32.const 3)) (then (local.set $x (local.get $c))))
      (local.set $cnt (i32.sub (local.get $cnt) (i32.const 1))) (br $l)))
    (call $m_fl (local.get $r) (local.get $sz) (i32.and (local.get $ov) (i32.and (i32.eqz (local.get $type)) (local.get $left))) (local.get $c) (i32.ne (local.get $type) (i32.const 3)))
    (local.get $r))
  ;; Dn <op> ea / ea <op> Dn for OR (0) AND (1) ADD (2) SUB (3) CMP (4) EOR (5); opmode from the opcode
  (func $m_dyadic (param $op i32) (param $kind i32)
    (local $opmode i32) (local $sz i32) (local $dn i32) (local $ea i32) (local $d i32) (local $s i32) (local $r i32) (local $tomem i32)
    (local.set $opmode (i32.and (i32.shr_u (local.get $op) (i32.const 6)) (i32.const 7))) (local.set $sz (i32.and (local.get $opmode) (i32.const 3)))
    (local.set $dn (i32.and (i32.shr_u (local.get $op) (i32.const 9)) (i32.const 7))) (local.set $tomem (i32.and (local.get $opmode) (i32.const 4)))
    (local.set $ea (call $m_ea (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 7)) (i32.and (local.get $op) (i32.const 7)) (local.get $sz)))
    (if (local.get $tomem)
      (then (local.set $d (call $m_ld (local.get $ea) (local.get $sz))) (local.set $s (call $m_d (local.get $dn))))
      (else (local.set $d (call $m_d (local.get $dn))) (local.set $s (call $m_ld (local.get $ea) (local.get $sz)))))
    (if (i32.ge_u (local.get $kind) (i32.const 2)) (then (if (i32.lt_u (local.get $kind) (i32.const 5)) (then
      (local.set $r (call $m_arith (local.get $d) (local.get $s) (local.get $sz) (select (i32.const 0) (select (i32.const 1) (i32.const 9) (i32.eq (local.get $kind) (i32.const 3))) (i32.eq (local.get $kind) (i32.const 2)))))   ;; ADD 0, SUB 1, CMP 9
      (if (i32.eq (local.get $kind) (i32.const 4)) (then (return)))
      (if (local.get $tomem) (then (call $m_st (local.get $ea) (local.get $sz) (local.get $r))) (else (call $m_st (i32.add (i32.const 0x10000) (local.get $dn)) (local.get $sz) (local.get $r))))
      (return)))))
    (local.set $r (select (i32.or (local.get $d) (local.get $s)) (select (i32.and (local.get $d) (local.get $s)) (i32.xor (local.get $d) (local.get $s)) (i32.eq (local.get $kind) (i32.const 1))) (i32.eqz (local.get $kind))))
    (call $m_fl (local.get $r) (local.get $sz) (i32.const 0) (i32.const 0) (i32.const 0))
    (if (local.get $tomem) (then (call $m_st (local.get $ea) (local.get $sz) (local.get $r))) (else (call $m_st (i32.add (i32.const 0x10000) (local.get $dn)) (local.get $sz) (local.get $r)))))
  ;; BTST BCHG BCLR BSET (type 0..3) on ea with bit number b: long on a data register, byte in memory
  (func $m_bitop (param $op i32) (param $type i32) (param $b i32)
    (local $ea i32) (local $sz i32) (local $d i32) (local $m i32)
    (local.set $sz (select (i32.const 2) (i32.const 0) (i32.eqz (i32.and (local.get $op) (i32.const 0x38)))))
    (local.set $ea (call $m_ea (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 7)) (i32.and (local.get $op) (i32.const 7)) (local.get $sz)))
    (local.set $m (i32.shl (i32.const 1) (i32.and (local.get $b) (select (i32.const 31) (i32.const 7) (local.get $sz)))))
    (local.set $d (call $m_ld (local.get $ea) (local.get $sz)))
    (call $zw16 (i32.const 20) (i32.or (i32.and (call $zr16 (i32.const 20)) (i32.const 0xfffb)) (select (i32.const 0) (i32.const 4) (i32.and (local.get $d) (local.get $m)))))
    (if (i32.eqz (local.get $type)) (then (return)))
    (if (i32.eq (local.get $type) (i32.const 1)) (then (local.set $d (i32.xor (local.get $d) (local.get $m)))))
    (if (i32.eq (local.get $type) (i32.const 2)) (then (local.set $d (i32.and (local.get $d) (i32.xor (local.get $m) (i32.const -1))))))
    (if (i32.eq (local.get $type) (i32.const 3)) (then (local.set $d (i32.or (local.get $d) (local.get $m)))))
    (call $m_st (local.get $ea) (local.get $sz) (local.get $d)))
  (func $m_movem (param $op i32) (param $tomem i32)
    (local $mask i32) (local $sz i32) (local $mode i32) (local $reg i32) (local $a i32) (local $k i32) (local $n i32)
    (local.set $mask (call $m_fetch)) (local.set $sz (select (i32.const 2) (i32.const 1) (i32.and (local.get $op) (i32.const 0x40)))) (local.set $n (i32.shl (i32.const 1) (local.get $sz)))
    (local.set $mode (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 7))) (local.set $reg (i32.and (local.get $op) (i32.const 7)))
    (if (i32.and (local.get $tomem) (i32.eq (local.get $mode) (i32.const 4))) (then   ;; predecrement: A7 first, mask reversed
      (local.set $a (call $m_a (local.get $reg)))
      (block $e (loop $l (br_if $e (i32.ge_u (local.get $k) (i32.const 16)))
        (if (i32.and (local.get $mask) (i32.shl (i32.const 1) (local.get $k))) (then
          (local.set $a (i32.sub (local.get $a) (local.get $n))) (call $m_st (i32.and (local.get $a) (i32.const 0xffff)) (local.get $sz) (call $m_rr (i32.sub (i32.const 15) (local.get $k))))))
        (local.set $k (i32.add (local.get $k) (i32.const 1))) (br $l)))
      (call $m_aw (local.get $reg) (local.get $a))
      (return)))
    (local.set $a (call $m_ea (select (i32.const 2) (local.get $mode) (i32.eq (local.get $mode) (i32.const 3))) (local.get $reg) (local.get $sz)))   ;; postincrement is applied at the end
    (if (i32.ge_u (local.get $a) (i32.const 0x10000)) (then (return)))
    (block $e (loop $l (br_if $e (i32.ge_u (local.get $k) (i32.const 16)))
      (if (i32.and (local.get $mask) (i32.shl (i32.const 1) (local.get $k))) (then
        (if (local.get $tomem) (then (call $m_st (local.get $a) (local.get $sz) (call $m_rr (local.get $k))))
          (else (call $m_rw (local.get $k) (call $m_sx (call $m_ld (local.get $a) (local.get $sz)) (local.get $sz)))))
        (local.set $a (i32.and (i32.add (local.get $a) (local.get $n)) (i32.const 0xffff)))))
      (local.set $k (i32.add (local.get $k) (i32.const 1))) (br $l)))
    (if (i32.eq (local.get $mode) (i32.const 3)) (then (call $m_aw (local.get $reg) (local.get $a)))))
  ;; ---- 68020 ----
  ;; MULU.L MULS.L (4C00) and DIVU.L DIVS.L DIVUL DIVSL (4C40) with their extension word: bits 14..12 Dl (the
  ;; quotient register Dq for divides), 11 signed, 10 64-bit (product Dh:Dl, dividend Dr:Dq), 2..0 Dh (Dr)
  (func $m_muldiv32 (param $op i32)
    (local $ext i32) (local $s i32) (local $dl i32) (local $dh i32) (local $sg i32) (local $w64 i32) (local $a i64) (local $b i64) (local $p i64) (local $q i64) (local $rm i64) (local $v i32)
    (local.set $ext (call $m_fetch))
    (local.set $s (call $m_ld (call $m_ea (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 7)) (i32.and (local.get $op) (i32.const 7)) (i32.const 2)) (i32.const 2)))
    (local.set $dl (i32.and (i32.shr_u (local.get $ext) (i32.const 12)) (i32.const 7))) (local.set $dh (i32.and (local.get $ext) (i32.const 7)))
    (local.set $sg (i32.and (local.get $ext) (i32.const 0x800))) (local.set $w64 (i32.and (local.get $ext) (i32.const 0x400)))
    (local.set $b (select (i64.extend_i32_s (local.get $s)) (i64.extend_i32_u (local.get $s)) (local.get $sg)))
    (local.set $a (select (i64.extend_i32_s (call $m_d (local.get $dl))) (i64.extend_i32_u (call $m_d (local.get $dl))) (local.get $sg)))
    (if (i32.eqz (i32.and (local.get $op) (i32.const 0x40))) (then   ;; multiply
      (local.set $p (i64.mul (local.get $a) (local.get $b)))
      (call $m_dw (local.get $dl) (i32.wrap_i64 (local.get $p)))
      (if (local.get $w64)
        (then (call $m_dw (local.get $dh) (i32.wrap_i64 (i64.shr_u (local.get $p) (i64.const 32))))
          (call $zw16 (i32.const 20) (i32.or (i32.and (call $zr16 (i32.const 20)) (i32.const 0xfff0))
            (i32.or (i32.shl (i64.lt_s (local.get $p) (i64.const 0)) (i32.const 3)) (i32.shl (i64.eqz (local.get $p)) (i32.const 2))))))
        (else   ;; V when the product does not fit 32 bits
          (local.set $v (select (i64.ne (local.get $p) (i64.extend_i32_s (i32.wrap_i64 (local.get $p)))) (i64.ne (i64.shr_u (local.get $p) (i64.const 32)) (i64.const 0)) (local.get $sg)))
          (call $m_fl (i32.wrap_i64 (local.get $p)) (i32.const 2) (local.get $v) (i32.const 0) (i32.const 0))))
      (return)))
    (if (i32.eqz (local.get $s)) (then (return)))   ;; divide by zero: a NOP
    (if (local.get $w64) (then (local.set $a (i64.or (i64.shl (i64.extend_i32_u (call $m_d (local.get $dh))) (i64.const 32)) (i64.extend_i32_u (call $m_d (local.get $dl)))))))
    (if (local.get $sg)
      (then
        (if (i32.and (i64.eq (local.get $a) (i64.const 0x8000000000000000)) (i64.eq (local.get $b) (i64.const -1))) (then (local.set $v (i32.const 1)))
          (else (local.set $q (i64.div_s (local.get $a) (local.get $b))) (local.set $rm (i64.rem_s (local.get $a) (local.get $b)))
            (local.set $v (i64.ne (local.get $q) (i64.extend_i32_s (i32.wrap_i64 (local.get $q))))))))
      (else (local.set $q (i64.div_u (local.get $a) (local.get $b))) (local.set $rm (i64.rem_u (local.get $a) (local.get $b)))
        (local.set $v (i64.ne (i64.shr_u (local.get $q) (i64.const 32)) (i64.const 0)))))
    (if (local.get $v) (then (call $m_fl (call $m_d (local.get $dl)) (i32.const 2) (i32.const 1) (i32.const 0) (i32.const 0)) (return)))   ;; overflow: V set, registers unchanged
    (call $m_dw (local.get $dl) (i32.wrap_i64 (local.get $q)))
    (if (i32.ne (local.get $dh) (local.get $dl)) (then (call $m_dw (local.get $dh) (i32.wrap_i64 (local.get $rm)))))
    (call $m_fl (i32.wrap_i64 (local.get $q)) (i32.const 2) (i32.const 0) (i32.const 0) (i32.const 0)))
  ;; bit fields: BFTST 0 BFEXTU 1 BFCHG 2 BFEXTS 3 BFCLR 4 BFFFO 5 BFSET 6 BFINS 7 (opcode bits 10..8); the extension
  ;; word gives the data register (14..12), the offset (bit 11: in a Dn, else bits 10..6) and the width (bit 5: in a
  ;; Dn, else bits 4..0, 0 = 32). On a data register the field wraps around the 32 bits; in memory it starts at
  ;; ea + offset div 8 (the offset signed) and spans up to five bytes.
  (func $m_bitfield (param $op i32)
    (local $ext i32) (local $type i32) (local $off i32) (local $off0 i32) (local $w i32) (local $ea i32) (local $dn i32) (local $data i64) (local $wm i64) (local $sh i32) (local $k i32) (local $a i32) (local $r i32)
    (local.set $ext (call $m_fetch)) (local.set $type (i32.and (i32.shr_u (local.get $op) (i32.const 8)) (i32.const 7)))
    (local.set $off (select (call $m_d (i32.and (i32.shr_u (local.get $ext) (i32.const 6)) (i32.const 7))) (i32.and (i32.shr_u (local.get $ext) (i32.const 6)) (i32.const 31)) (i32.and (local.get $ext) (i32.const 0x800))))
    (local.set $w (select (i32.and (call $m_d (i32.and (local.get $ext) (i32.const 7))) (i32.const 31)) (i32.and (local.get $ext) (i32.const 31)) (i32.and (local.get $ext) (i32.const 0x20))))
    (if (i32.eqz (local.get $w)) (then (local.set $w (i32.const 32))))
    (local.set $off0 (local.get $off)) (local.set $dn (i32.and (i32.shr_u (local.get $ext) (i32.const 12)) (i32.const 7)))
    (local.set $ea (call $m_ea (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 7)) (i32.and (local.get $op) (i32.const 7)) (i32.const 0)))
    ;; gather the bits left-aligned into data: a register rotated so the field starts at the top, or five bytes shifted by the bit offset
    (if (i32.ge_u (local.get $ea) (i32.const 0x10000))
      (then (local.set $off (i32.and (local.get $off) (i32.const 31)))
        (local.set $data (i64.shl (i64.extend_i32_u (i32.rotl (call $m_d (i32.and (local.get $ea) (i32.const 7))) (local.get $off))) (i64.const 32))))
      (else (local.set $a (i32.and (i32.add (local.get $ea) (i32.shr_s (local.get $off) (i32.const 3))) (i32.const 0xffff))) (local.set $off (i32.and (local.get $off) (i32.const 7)))
        (block $e (loop $l (br_if $e (i32.ge_u (local.get $k) (i32.const 5)))
          (local.set $data (i64.or (local.get $data) (i64.shl (i64.extend_i32_u (call $mrd (i32.add (local.get $a) (local.get $k)))) (i64.extend_i32_u (i32.sub (i32.const 56) (i32.shl (local.get $k) (i32.const 3)))))))
          (local.set $k (i32.add (local.get $k) (i32.const 1))) (br $l)))
        (local.set $data (i64.shl (local.get $data) (i64.extend_i32_u (local.get $off))))))
    (local.set $sh (i32.sub (i32.const 64) (local.get $w)))
    (local.set $wm (i64.sub (i64.shl (i64.const 1) (i64.extend_i32_u (local.get $w))) (i64.const 1)))
    (local.set $r (i32.wrap_i64 (i64.shr_u (local.get $data) (i64.extend_i32_u (local.get $sh)))))   ;; the field, right-aligned
    (if (i32.eq (local.get $type) (i32.const 7)) (then (local.set $r (i32.wrap_i64 (i64.and (i64.extend_i32_u (call $m_d (local.get $dn))) (local.get $wm))))))   ;; BFINS: flags from the inserted value
    (call $zw16 (i32.const 20) (i32.or (i32.and (call $zr16 (i32.const 20)) (i32.const 0xfff0))
      (i32.or (i32.shl (i32.ne (i32.and (local.get $r) (i32.shl (i32.const 1) (i32.sub (local.get $w) (i32.const 1)))) (i32.const 0)) (i32.const 3)) (i32.shl (i32.eqz (local.get $r)) (i32.const 2)))))
    (if (i32.eqz (local.get $type)) (then (return)))
    (if (i32.eq (local.get $type) (i32.const 1)) (then (call $m_dw (local.get $dn) (local.get $r)) (return)))
    (if (i32.eq (local.get $type) (i32.const 3)) (then (call $m_dw (local.get $dn) (call $sx (local.get $r) (local.get $w))) (return)))
    (if (i32.eq (local.get $type) (i32.const 5)) (then   ;; BFFFO: the offset of the first set bit of the field, offset + width when there is none
      (call $m_dw (local.get $dn) (i32.add (local.get $off0) (select (i32.sub (i32.clz (local.get $r)) (i32.sub (i32.const 32) (local.get $w))) (local.get $w) (local.get $r)))) (return)))
    (if (i32.eq (local.get $type) (i32.const 2)) (then (local.set $r (i32.xor (local.get $r) (i32.wrap_i64 (local.get $wm))))))
    (if (i32.eq (local.get $type) (i32.const 4)) (then (local.set $r (i32.const 0))))
    (if (i32.eq (local.get $type) (i32.const 6)) (then (local.set $r (i32.wrap_i64 (local.get $wm)))))
    (local.set $data (i64.or (i64.and (local.get $data) (i64.xor (i64.shl (local.get $wm) (i64.extend_i32_u (local.get $sh))) (i64.const -1)))
                             (i64.shl (i64.and (i64.extend_i32_u (local.get $r)) (local.get $wm)) (i64.extend_i32_u (local.get $sh)))))
    (if (i32.ge_u (local.get $ea) (i32.const 0x10000))
      (then (call $m_dw (i32.and (local.get $ea) (i32.const 7)) (i32.rotr (i32.wrap_i64 (i64.shr_u (local.get $data) (i64.const 32))) (local.get $off))))
      (else (local.set $data (i64.shr_u (local.get $data) (i64.extend_i32_u (local.get $off)))) (local.set $k (i32.const 0))
        (block $e2 (loop $l2 (br_if $e2 (i32.ge_u (i32.shl (local.get $k) (i32.const 3)) (i32.add (local.get $off) (local.get $w))))
          (call $mwr (i32.add (local.get $a) (local.get $k)) (i32.wrap_i64 (i64.and (i64.shr_u (local.get $data) (i64.extend_i32_u (i32.sub (i32.const 56) (i32.shl (local.get $k) (i32.const 3))))) (i64.const 255))))
          (local.set $k (i32.add (local.get $k) (i32.const 1))) (br $l2))))))
  ;; CAS Dc,Du,ea: compare the operand with Dc; equal: the operand becomes Du, else Dc becomes the operand (CAS2 is a NOP after its two words)
  (func $m_cas (param $op i32)
    (local $ext i32) (local $sz i32) (local $ea i32) (local $d i32) (local $dc i32)
    (local.set $sz (i32.sub (i32.and (i32.shr_u (local.get $op) (i32.const 9)) (i32.const 7)) (i32.const 5)))
    (local.set $ext (call $m_fetch))
    (if (i32.eq (i32.and (local.get $op) (i32.const 0x3f)) (i32.const 0x3c)) (then (drop (call $m_fetch)) (return)))
    (local.set $ea (call $m_ea (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 7)) (i32.and (local.get $op) (i32.const 7)) (local.get $sz)))
    (local.set $d (call $m_ld (local.get $ea) (local.get $sz))) (local.set $dc (i32.and (local.get $ext) (i32.const 7)))
    (drop (call $m_arith (local.get $d) (call $m_d (local.get $dc)) (local.get $sz) (i32.const 9)))
    (if (i32.and (call $zr16 (i32.const 20)) (i32.const 4))
      (then (call $m_st (local.get $ea) (local.get $sz) (call $m_d (i32.and (i32.shr_u (local.get $ext) (i32.const 6)) (i32.const 7)))))
      (else (call $m_st (i32.add (i32.const 0x10000) (local.get $dc)) (local.get $sz) (local.get $d)))))
  ;; CMP2 / CHK2 ea,Rn: Z when Rn equals a bound, C when it lies outside the bounds at ea (signed unless lower > upper); CHK2 does not trap
  (func $m_cmp2 (param $op i32)
    (local $ext i32) (local $sz i32) (local $ea i32) (local $lo i32) (local $hi i32) (local $v i32) (local $r i32) (local $c i32) (local $z i32)
    (local.set $sz (i32.and (i32.shr_u (local.get $op) (i32.const 9)) (i32.const 3)))
    (local.set $ext (call $m_fetch))
    (local.set $ea (call $m_ea (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 7)) (i32.and (local.get $op) (i32.const 7)) (local.get $sz)))
    (if (i32.ge_u (local.get $ea) (i32.const 0x10000)) (then (return)))
    (local.set $lo (call $m_sx (call $m_ld (local.get $ea) (local.get $sz)) (local.get $sz)))
    (local.set $hi (call $m_sx (call $m_ld (i32.and (i32.add (local.get $ea) (i32.shl (i32.const 1) (local.get $sz))) (i32.const 0xffff)) (local.get $sz)) (local.get $sz)))
    (local.set $r (i32.and (i32.shr_u (local.get $ext) (i32.const 12)) (i32.const 15))) (local.set $v (call $m_rr (local.get $r)))
    (if (i32.eqz (i32.and (local.get $r) (i32.const 8))) (then (local.set $v (call $m_sx (local.get $v) (local.get $sz)))))
    (local.set $z (i32.or (i32.eq (local.get $v) (local.get $lo)) (i32.eq (local.get $v) (local.get $hi))))
    (if (i32.le_s (local.get $lo) (local.get $hi))
      (then (local.set $c (i32.or (i32.lt_s (local.get $v) (local.get $lo)) (i32.gt_s (local.get $v) (local.get $hi)))))
      (else (local.set $c (i32.or (i32.lt_u (local.get $v) (local.get $lo)) (i32.gt_u (local.get $v) (local.get $hi))))))
    (call $zw16 (i32.const 20) (i32.or (i32.and (call $zr16 (i32.const 20)) (i32.const 0xfffa)) (i32.or (i32.shl (local.get $z) (i32.const 2)) (local.get $c)))))

  (func $m68k_step
    (local $op i32) (local $line i32) (local $sz i32) (local $mode i32) (local $reg i32) (local $ea i32) (local $d i32) (local $s i32) (local $r i32) (local $t i32) (local $n i32) (local $pc i32) (local $opmode i32) (local $cnt i32)
    (local.set $op (call $m_fetch)) (local.set $line (i32.shr_u (local.get $op) (i32.const 12)))
    (local.set $mode (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 7))) (local.set $reg (i32.and (local.get $op) (i32.const 7)))
    (local.set $sz (i32.and (i32.shr_u (local.get $op) (i32.const 6)) (i32.const 3))) (local.set $n (i32.and (i32.shr_u (local.get $op) (i32.const 9)) (i32.const 7)))
    (local.set $opmode (i32.and (i32.shr_u (local.get $op) (i32.const 6)) (i32.const 7)))
    (block $end
      (if (i32.eqz (local.get $line)) (then
        (if (i32.and (local.get $op) (i32.const 0x100)) (then   ;; dynamic bit ops (MOVEP is a NOP)
          (if (i32.ne (local.get $mode) (i32.const 1)) (then (call $m_bitop (local.get $op) (local.get $sz) (call $m_d (local.get $n)))))
          (br $end)))
        (if (i32.eq (local.get $n) (i32.const 4)) (then (call $m_bitop (local.get $op) (local.get $sz) (i32.and (call $m_fetch) (i32.const 0xff))) (br $end)))   ;; static bit ops
        (if (i32.eq (local.get $sz) (i32.const 3)) (then   ;; 68020: CAS (n 5..7), CMP2/CHK2 (n 0..2); CALLM/RTM (n 3) are NOPs
          (if (global.get $m20) (then
            (if (i32.ge_u (local.get $n) (i32.const 5)) (then (call $m_cas (local.get $op)) (br $end)))
            (if (i32.le_u (local.get $n) (i32.const 2)) (then (call $m_cmp2 (local.get $op)) (br $end)))))
          (br $end)))
        ;; ORI ANDI SUBI ADDI EORI CMPI #imm,ea (imm first in the stream); ea = #imm means CCR/SR
        (local.set $s (select (i32.and (call $m_fetch) (i32.const 0xff)) (select (call $m_fetch32) (call $m_fetch) (i32.eq (local.get $sz) (i32.const 2))) (i32.eqz (local.get $sz))))
        (if (i32.eq (i32.and (local.get $op) (i32.const 0x3f)) (i32.const 0x3c)) (then
          (local.set $d (call $zr16 (i32.const 20)))
          (local.set $r (select (i32.or (local.get $d) (local.get $s)) (select (i32.and (local.get $d) (local.get $s)) (i32.xor (local.get $d) (local.get $s)) (i32.eq (local.get $n) (i32.const 1))) (i32.eqz (local.get $n))))
          (if (i32.or (i32.eqz (local.get $n)) (i32.or (i32.eq (local.get $n) (i32.const 1)) (i32.eq (local.get $n) (i32.const 5)))) (then (call $zw16 (i32.const 20) (i32.and (local.get $r) (i32.const 0xff1f)))))
          (br $end)))
        (local.set $ea (call $m_ea (local.get $mode) (local.get $reg) (local.get $sz))) (local.set $d (call $m_ld (local.get $ea) (local.get $sz)))
        (if (i32.eq (local.get $n) (i32.const 6)) (then (drop (call $m_arith (local.get $d) (local.get $s) (local.get $sz) (i32.const 9))) (br $end)))
        (if (i32.eq (local.get $n) (i32.const 2)) (then (call $m_st (local.get $ea) (local.get $sz) (call $m_arith (local.get $d) (local.get $s) (local.get $sz) (i32.const 1))) (br $end)))
        (if (i32.eq (local.get $n) (i32.const 3)) (then (call $m_st (local.get $ea) (local.get $sz) (call $m_arith (local.get $d) (local.get $s) (local.get $sz) (i32.const 0))) (br $end)))
        (local.set $r (select (i32.or (local.get $d) (local.get $s)) (select (i32.and (local.get $d) (local.get $s)) (i32.xor (local.get $d) (local.get $s)) (i32.eq (local.get $n) (i32.const 1))) (i32.eqz (local.get $n))))
        (if (i32.eq (local.get $n) (i32.const 7)) (then (br $end)))
        (call $m_fl (local.get $r) (local.get $sz) (i32.const 0) (i32.const 0) (i32.const 0)) (call $m_st (local.get $ea) (local.get $sz) (local.get $r))
        (br $end)))
      (if (i32.le_u (local.get $line) (i32.const 3)) (then   ;; MOVE / MOVEA
        (local.set $sz (select (i32.const 0) (select (i32.const 2) (i32.const 1) (i32.eq (local.get $line) (i32.const 2))) (i32.eq (local.get $line) (i32.const 1))))
        (local.set $s (call $m_ld (call $m_ea (local.get $mode) (local.get $reg) (local.get $sz)) (local.get $sz)))
        (if (i32.eq (local.get $opmode) (i32.const 1)) (then (call $m_aw (local.get $n) (call $m_sx (local.get $s) (local.get $sz))) (br $end)))
        (call $m_fl (local.get $s) (local.get $sz) (i32.const 0) (i32.const 0) (i32.const 0))
        (call $m_st (call $m_ea (local.get $opmode) (local.get $n) (local.get $sz)) (local.get $sz) (local.get $s))
        (br $end)))
      (if (i32.eq (local.get $line) (i32.const 4)) (then
        (if (global.get $m20) (then
          (if (i32.eq (i32.and (local.get $op) (i32.const 0xfff8)) (i32.const 0x49c0)) (then   ;; EXTB.L
            (local.set $r (call $sext8 (call $m_d (local.get $reg)))) (call $m_dw (local.get $reg) (local.get $r)) (call $m_fl (local.get $r) (i32.const 2) (i32.const 0) (i32.const 0) (i32.const 0)) (br $end)))
          (if (i32.eq (i32.and (local.get $op) (i32.const 0xff80)) (i32.const 0x4c00)) (then (call $m_muldiv32 (local.get $op)) (br $end)))   ;; MULU.L MULS.L DIVU.L DIVS.L
          (if (i32.eq (i32.and (local.get $op) (i32.const 0xfff8)) (i32.const 0x4808)) (then   ;; LINK.L
            (call $m_push (call $m_a (local.get $reg))) (call $m_aw (local.get $reg) (call $m_a (i32.const 7)))
            (call $m_aw (i32.const 7) (i32.add (call $m_a (i32.const 7)) (call $m_fetch32))) (br $end)))
          (if (i32.eq (local.get $op) (i32.const 0x4e74)) (then   ;; RTD #d
            (local.set $s (call $sx (call $m_fetch) (i32.const 16))) (call $zw16 (i32.const 22) (i32.and (call $m_pop) (i32.const 0xffff)))
            (call $m_aw (i32.const 7) (i32.add (call $m_a (i32.const 7)) (local.get $s))) (br $end)))
          (if (i32.eq (i32.and (local.get $op) (i32.const 0xfffe)) (i32.const 0x4e7a)) (then (drop (call $m_fetch)) (br $end)))))   ;; MOVEC: a NOP with its word
        (if (i32.eq (local.get $opmode) (i32.const 7)) (then (call $m_aw (local.get $n) (call $m_ea (local.get $mode) (local.get $reg) (i32.const 2))) (br $end)))   ;; LEA
        (if (i32.eq (local.get $opmode) (i32.const 6)) (then (drop (call $m_ea (local.get $mode) (local.get $reg) (i32.const 1))) (br $end)))   ;; CHK: NOP
        (local.set $t (i32.and (i32.shr_u (local.get $op) (i32.const 8)) (i32.const 15)))
        (if (i32.eq (i32.and (local.get $op) (i32.const 0xff80)) (i32.const 0x4e80)) (then   ;; JSR / JMP
          (local.set $ea (call $m_ea (local.get $mode) (local.get $reg) (i32.const 2)))
          (if (i32.lt_u (local.get $ea) (i32.const 0x10000)) (then
            (if (i32.eqz (i32.and (local.get $op) (i32.const 0x40))) (then (call $m_push (call $zr16 (i32.const 22)))))
            (call $zw16 (i32.const 22) (local.get $ea))))
          (br $end)))
        (if (i32.eq (i32.and (local.get $op) (i32.const 0xfff0)) (i32.const 0x4e70)) (then   ;; RESET NOP STOP RTE RTD RTS TRAPV RTR
          (if (i32.eq (local.get $op) (i32.const 0x4e72)) (then (drop (call $m_fetch))))
          (if (i32.eq (local.get $op) (i32.const 0x4e73)) (then (call $zw16 (i32.const 20) (i32.and (call $m_pop16) (i32.const 0xff1f))) (call $zw16 (i32.const 22) (i32.and (call $m_pop) (i32.const 0xffff)))))
          (if (i32.eq (local.get $op) (i32.const 0x4e75)) (then (call $zw16 (i32.const 22) (i32.and (call $m_pop) (i32.const 0xffff)))))
          (if (i32.eq (local.get $op) (i32.const 0x4e77)) (then (call $zw16 (i32.const 20) (i32.or (i32.and (call $zr16 (i32.const 20)) (i32.const 0xff00)) (i32.and (call $m_pop16) (i32.const 0x1f)))) (call $zw16 (i32.const 22) (i32.and (call $m_pop) (i32.const 0xffff)))))
          (br $end)))
        (if (i32.eq (i32.and (local.get $op) (i32.const 0xfff8)) (i32.const 0x4e50)) (then   ;; LINK
          (call $m_push (call $m_a (local.get $reg))) (call $m_aw (local.get $reg) (call $m_a (i32.const 7)))
          (call $m_aw (i32.const 7) (i32.add (call $m_a (i32.const 7)) (call $sx (call $m_fetch) (i32.const 16)))) (br $end)))
        (if (i32.eq (i32.and (local.get $op) (i32.const 0xfff8)) (i32.const 0x4e58)) (then   ;; UNLK
          (call $m_aw (i32.const 7) (call $m_a (local.get $reg))) (call $m_aw (local.get $reg) (call $m_pop)) (br $end)))
        (if (i32.eq (i32.and (local.get $op) (i32.const 0xff00)) (i32.const 0x4e00)) (then (br $end)))   ;; TRAP, MOVE USP, others
        (if (i32.eq (i32.and (local.get $op) (i32.const 0xfb80)) (i32.const 0x4880)) (then   ;; MOVEM (mode != 0) or EXT (mode 0)
          (if (local.get $mode) (then (call $m_movem (local.get $op) (i32.eqz (i32.and (local.get $op) (i32.const 0x400)))) (br $end)))
          (if (i32.and (local.get $op) (i32.const 0x400)) (then (br $end)))
          (local.set $d (call $m_d (local.get $reg)))
          (if (i32.and (local.get $op) (i32.const 0x40))
            (then (local.set $r (call $sx (local.get $d) (i32.const 16))) (call $m_dw (local.get $reg) (local.get $r)) (call $m_fl (local.get $r) (i32.const 2) (i32.const 0) (i32.const 0) (i32.const 0)))
            (else (local.set $r (i32.or (i32.and (local.get $d) (i32.const 0xffff0000)) (i32.and (call $sext8 (local.get $d)) (i32.const 0xffff)))) (call $m_dw (local.get $reg) (local.get $r)) (call $m_fl (local.get $r) (i32.const 1) (i32.const 0) (i32.const 0) (i32.const 0))))
          (br $end)))
        (if (i32.eq (i32.and (local.get $op) (i32.const 0xfff8)) (i32.const 0x4840)) (then   ;; SWAP
          (local.set $d (call $m_d (local.get $reg))) (local.set $r (i32.or (i32.shl (local.get $d) (i32.const 16)) (i32.shr_u (local.get $d) (i32.const 16))))
          (call $m_dw (local.get $reg) (local.get $r)) (call $m_fl (local.get $r) (i32.const 2) (i32.const 0) (i32.const 0) (i32.const 0)) (br $end)))
        (if (i32.eq (i32.and (local.get $op) (i32.const 0xffc0)) (i32.const 0x4840)) (then   ;; PEA (BKPT is in 0x4848..4f, mode 1: NOP)
          (if (i32.ne (local.get $mode) (i32.const 1)) (then (local.set $ea (call $m_ea (local.get $mode) (local.get $reg) (i32.const 2))) (if (i32.lt_u (local.get $ea) (i32.const 0x10000)) (then (call $m_push (local.get $ea))))))
          (br $end)))
        (if (i32.eq (i32.and (local.get $op) (i32.const 0xffc0)) (i32.const 0x4800)) (then (br $end)))   ;; NBCD
        (if (i32.eq (i32.and (local.get $op) (i32.const 0xff00)) (i32.const 0x4a00)) (then   ;; TST / TAS / ILLEGAL
          (if (i32.eq (local.get $op) (i32.const 0x4afc)) (then (br $end)))
          (if (i32.eq (local.get $sz) (i32.const 3)) (then
            (local.set $ea (call $m_ea (local.get $mode) (local.get $reg) (i32.const 0))) (local.set $d (call $m_ld (local.get $ea) (i32.const 0)))
            (call $m_fl (local.get $d) (i32.const 0) (i32.const 0) (i32.const 0) (i32.const 0)) (call $m_st (local.get $ea) (i32.const 0) (i32.or (local.get $d) (i32.const 0x80))) (br $end)))
          (call $m_fl (call $m_ld (call $m_ea (local.get $mode) (local.get $reg) (local.get $sz)) (local.get $sz)) (local.get $sz) (i32.const 0) (i32.const 0) (i32.const 0))
          (br $end)))
        (if (i32.eq (local.get $sz) (i32.const 3)) (then   ;; MOVE from SR (40C0), to CCR (44C0), to SR (46C0)
          (if (i32.eqz (local.get $t)) (then (call $m_st (call $m_ea (local.get $mode) (local.get $reg) (i32.const 1)) (i32.const 1) (i32.or (call $zr16 (i32.const 20)) (i32.const 0x2000))) (br $end)))
          (local.set $s (call $m_ld (call $m_ea (local.get $mode) (local.get $reg) (i32.const 1)) (i32.const 1)))
          (if (i32.eq (local.get $t) (i32.const 4)) (then (call $zw16 (i32.const 20) (i32.or (i32.and (call $zr16 (i32.const 20)) (i32.const 0xff00)) (i32.and (local.get $s) (i32.const 0x1f))))))
          (if (i32.eq (local.get $t) (i32.const 6)) (then (call $zw16 (i32.const 20) (i32.and (local.get $s) (i32.const 0xff1f)))))
          (br $end)))
        ;; NEGX (40) CLR (42) NEG (44) NOT (46)
        (local.set $ea (call $m_ea (local.get $mode) (local.get $reg) (local.get $sz))) (local.set $d (call $m_ld (local.get $ea) (local.get $sz)))
        (if (i32.eqz (local.get $t)) (then (call $m_st (local.get $ea) (local.get $sz) (call $m_arith (i32.const 0) (local.get $d) (local.get $sz) (i32.const 7))) (br $end)))
        (if (i32.eq (local.get $t) (i32.const 2)) (then (call $m_fl (i32.const 0) (local.get $sz) (i32.const 0) (i32.const 0) (i32.const 0)) (call $m_st (local.get $ea) (local.get $sz) (i32.const 0)) (br $end)))
        (if (i32.eq (local.get $t) (i32.const 4)) (then (call $m_st (local.get $ea) (local.get $sz) (call $m_arith (i32.const 0) (local.get $d) (local.get $sz) (i32.const 1))) (br $end)))
        (if (i32.eq (local.get $t) (i32.const 6)) (then (local.set $r (i32.xor (local.get $d) (i32.const -1))) (call $m_fl (local.get $r) (local.get $sz) (i32.const 0) (i32.const 0) (i32.const 0)) (call $m_st (local.get $ea) (local.get $sz) (local.get $r))))
        (br $end)))
      (if (i32.eq (local.get $line) (i32.const 5)) (then
        (if (i32.eq (local.get $sz) (i32.const 3)) (then   ;; Scc / DBcc (68020: TRAPcc, mode 7 reg 2..4, a NOP with its word or long)
          (if (i32.and (global.get $m20) (i32.and (i32.eq (local.get $mode) (i32.const 7)) (i32.ge_u (local.get $reg) (i32.const 2)))) (then
            (if (i32.eq (local.get $reg) (i32.const 2)) (then (drop (call $m_fetch))))
            (if (i32.eq (local.get $reg) (i32.const 3)) (then (drop (call $m_fetch32))))
            (br $end)))
          (local.set $t (call $m_cc (i32.shr_u (local.get $op) (i32.const 8))))
          (if (i32.eq (local.get $mode) (i32.const 1)) (then
            (local.set $pc (call $zr16 (i32.const 22))) (local.set $s (call $sx (call $m_fetch) (i32.const 16)))
            (if (i32.eqz (local.get $t)) (then
              (local.set $r (i32.and (i32.sub (call $m_d (local.get $reg)) (i32.const 1)) (i32.const 0xffff)))
              (call $m_st (i32.add (i32.const 0x10000) (local.get $reg)) (i32.const 1) (local.get $r))
              (if (i32.ne (local.get $r) (i32.const 0xffff)) (then (call $zw16 (i32.const 22) (i32.and (i32.add (local.get $pc) (local.get $s)) (i32.const 0xffff)))))))
            (br $end)))
          (call $m_st (call $m_ea (local.get $mode) (local.get $reg) (i32.const 0)) (i32.const 0) (select (i32.const 0xff) (i32.const 0) (local.get $t)))
          (br $end)))
        (local.set $s (select (i32.const 8) (local.get $n) (i32.eqz (local.get $n))))   ;; ADDQ / SUBQ
        (if (i32.eq (local.get $mode) (i32.const 1)) (then
          (call $m_aw (local.get $reg) (select (i32.sub (call $m_a (local.get $reg)) (local.get $s)) (i32.add (call $m_a (local.get $reg)) (local.get $s)) (i32.and (local.get $op) (i32.const 0x100)))) (br $end)))
        (local.set $ea (call $m_ea (local.get $mode) (local.get $reg) (local.get $sz)))
        (call $m_st (local.get $ea) (local.get $sz) (call $m_arith (call $m_ld (local.get $ea) (local.get $sz)) (local.get $s) (local.get $sz) (i32.shr_u (i32.and (local.get $op) (i32.const 0x100)) (i32.const 8))))
        (br $end)))
      (if (i32.eq (local.get $line) (i32.const 6)) (then   ;; Bcc BRA BSR
        (local.set $pc (call $zr16 (i32.const 22))) (local.set $s (call $sext8 (local.get $op)))
        (if (i32.eqz (local.get $s)) (then (local.set $s (call $sx (call $m_fetch) (i32.const 16)))))
        (if (i32.and (global.get $m20) (i32.eq (local.get $s) (i32.const -1))) (then (local.set $s (call $m_fetch32))))   ;; 68020: Bcc.L
        (local.set $t (i32.and (i32.shr_u (local.get $op) (i32.const 8)) (i32.const 15)))
        (if (i32.eq (local.get $t) (i32.const 1)) (then (call $m_push (call $zr16 (i32.const 22))) (local.set $t (i32.const 0))))
        (if (call $m_cc (local.get $t)) (then (call $zw16 (i32.const 22) (i32.and (i32.add (local.get $pc) (local.get $s)) (i32.const 0xffff)))))
        (br $end)))
      (if (i32.eq (local.get $line) (i32.const 7)) (then   ;; MOVEQ
        (if (i32.eqz (i32.and (local.get $op) (i32.const 0x100))) (then (local.set $r (call $sext8 (local.get $op))) (call $m_dw (local.get $n) (local.get $r)) (call $m_fl (local.get $r) (i32.const 2) (i32.const 0) (i32.const 0) (i32.const 0))))
        (br $end)))
      (if (i32.or (i32.eq (local.get $line) (i32.const 8)) (i32.eq (local.get $line) (i32.const 12))) (then   ;; OR/DIV/SBCD, AND/MUL/ABCD/EXG
        (if (i32.eq (i32.and (local.get $opmode) (i32.const 3)) (i32.const 3)) (then   ;; MULU MULS DIVU DIVS
          (local.set $s (call $m_ld (call $m_ea (local.get $mode) (local.get $reg) (i32.const 1)) (i32.const 1))) (local.set $d (call $m_d (local.get $n)))
          (if (i32.eq (local.get $line) (i32.const 12)) (then
            (local.set $r (select (i32.mul (call $sx (local.get $d) (i32.const 16)) (call $sx (local.get $s) (i32.const 16))) (i32.mul (i32.and (local.get $d) (i32.const 0xffff)) (local.get $s)) (i32.and (local.get $opmode) (i32.const 4))))
            (call $m_dw (local.get $n) (local.get $r)) (call $m_fl (local.get $r) (i32.const 2) (i32.const 0) (i32.const 0) (i32.const 0)) (br $end)))
          (if (i32.eqz (local.get $s)) (then (br $end)))
          (if (i32.and (local.get $opmode) (i32.const 4))
            (then (local.set $s (call $sx (local.get $s) (i32.const 16)))
              (if (i32.and (i32.eq (local.get $d) (i32.const 0x80000000)) (i32.eq (local.get $s) (i32.const -1))) (then (call $m_fl (local.get $d) (i32.const 2) (i32.const 1) (i32.const 0) (i32.const 0)) (br $end)))
              (local.set $r (i32.div_s (local.get $d) (local.get $s))) (local.set $t (i32.rem_s (local.get $d) (local.get $s)))
              (if (i32.ne (call $sx (local.get $r) (i32.const 16)) (local.get $r)) (then (call $m_fl (local.get $d) (i32.const 2) (i32.const 1) (i32.const 0) (i32.const 0)) (br $end))))
            (else (local.set $r (i32.div_u (local.get $d) (local.get $s))) (local.set $t (i32.rem_u (local.get $d) (local.get $s)))
              (if (i32.gt_u (local.get $r) (i32.const 0xffff)) (then (call $m_fl (local.get $d) (i32.const 2) (i32.const 1) (i32.const 0) (i32.const 0)) (br $end)))))
          (call $m_dw (local.get $n) (i32.or (i32.shl (local.get $t) (i32.const 16)) (i32.and (local.get $r) (i32.const 0xffff))))
          (call $m_fl (local.get $r) (i32.const 1) (i32.const 0) (i32.const 0) (i32.const 0))
          (br $end)))
        (if (i32.and (i32.and (local.get $opmode) (i32.const 4)) (i32.lt_u (local.get $mode) (i32.const 2))) (then   ;; SBCD/ABCD (NOPs) and EXG; 68020 PACK/UNPK (line 8, opmode 5/6): NOPs with their word
          (if (i32.and (global.get $m20) (i32.and (i32.eq (local.get $line) (i32.const 8)) (i32.ne (local.get $opmode) (i32.const 4)))) (then (drop (call $m_fetch))))
          (if (i32.eq (local.get $line) (i32.const 12)) (then
            (local.set $t (i32.and (local.get $op) (i32.const 0xf8)))
            (if (i32.eq (local.get $t) (i32.const 0x40)) (then (local.set $d (call $m_d (local.get $n))) (call $m_dw (local.get $n) (call $m_d (local.get $reg))) (call $m_dw (local.get $reg) (local.get $d))))
            (if (i32.eq (local.get $t) (i32.const 0x48)) (then (local.set $d (call $m_a (local.get $n))) (call $m_aw (local.get $n) (call $m_a (local.get $reg))) (call $m_aw (local.get $reg) (local.get $d))))
            (if (i32.eq (local.get $t) (i32.const 0x88)) (then (local.set $d (call $m_d (local.get $n))) (call $m_dw (local.get $n) (call $m_a (local.get $reg))) (call $m_aw (local.get $reg) (local.get $d))))))
          (br $end)))
        (call $m_dyadic (local.get $op) (i32.eq (local.get $line) (i32.const 12)))
        (br $end)))
      (if (i32.or (i32.eq (local.get $line) (i32.const 9)) (i32.eq (local.get $line) (i32.const 13))) (then   ;; SUB/SUBA/SUBX, ADD/ADDA/ADDX
        (local.set $t (i32.eq (local.get $line) (i32.const 9)))   ;; 1 = subtract
        (if (i32.eq (i32.and (local.get $opmode) (i32.const 3)) (i32.const 3)) (then
          (local.set $sz (select (i32.const 2) (i32.const 1) (i32.and (local.get $opmode) (i32.const 4))))
          (local.set $s (call $m_sx (call $m_ld (call $m_ea (local.get $mode) (local.get $reg) (local.get $sz)) (local.get $sz)) (local.get $sz)))
          (call $m_aw (local.get $n) (select (i32.sub (call $m_a (local.get $n)) (local.get $s)) (i32.add (call $m_a (local.get $n)) (local.get $s)) (local.get $t)))
          (br $end)))
        (if (i32.and (i32.and (local.get $opmode) (i32.const 4)) (i32.lt_u (local.get $mode) (i32.const 2))) (then   ;; ADDX / SUBX: Dy,Dx or -(Ay),-(Ax)
          (if (local.get $mode)
            (then (local.set $s (call $m_ld (call $m_ea (i32.const 4) (local.get $reg) (local.get $sz)) (local.get $sz)))
              (local.set $ea (call $m_ea (i32.const 4) (local.get $n) (local.get $sz))))
            (else (local.set $s (call $m_d (local.get $reg))) (local.set $ea (i32.add (i32.const 0x10000) (local.get $n)))))
          (call $m_st (local.get $ea) (local.get $sz) (call $m_arith (call $m_ld (local.get $ea) (local.get $sz)) (local.get $s) (local.get $sz) (i32.or (i32.const 6) (local.get $t))))
          (br $end)))
        (call $m_dyadic (local.get $op) (select (i32.const 3) (i32.const 2) (local.get $t)))
        (br $end)))
      (if (i32.eq (local.get $line) (i32.const 11)) (then   ;; CMP CMPA CMPM EOR
        (if (i32.eq (i32.and (local.get $opmode) (i32.const 3)) (i32.const 3)) (then
          (local.set $sz (select (i32.const 2) (i32.const 1) (i32.and (local.get $opmode) (i32.const 4))))
          (local.set $s (call $m_sx (call $m_ld (call $m_ea (local.get $mode) (local.get $reg) (local.get $sz)) (local.get $sz)) (local.get $sz)))
          (drop (call $m_arith (call $m_a (local.get $n)) (local.get $s) (i32.const 2) (i32.const 9)))
          (br $end)))
        (if (i32.and (local.get $opmode) (i32.const 4)) (then
          (if (i32.eq (local.get $mode) (i32.const 1)) (then   ;; CMPM (Ay)+,(Ax)+
            (local.set $s (call $m_ld (call $m_ea (i32.const 3) (local.get $reg) (local.get $sz)) (local.get $sz)))
            (drop (call $m_arith (call $m_ld (call $m_ea (i32.const 3) (local.get $n) (local.get $sz)) (local.get $sz)) (local.get $s) (local.get $sz) (i32.const 9)))
            (br $end)))
          (call $m_dyadic (local.get $op) (i32.const 5)) (br $end)))
        (call $m_dyadic (local.get $op) (i32.const 4))
        (br $end)))
      (if (i32.eq (local.get $line) (i32.const 14)) (then   ;; shifts and rotates
        (if (i32.eq (local.get $sz) (i32.const 3)) (then   ;; memory form: word, by one; 68020 bit fields with bit 11 set
          (if (i32.and (global.get $m20) (i32.ne (i32.and (local.get $op) (i32.const 0x800)) (i32.const 0))) (then (call $m_bitfield (local.get $op)) (br $end)))
          (local.set $ea (call $m_ea (local.get $mode) (local.get $reg) (i32.const 1)))
          (call $m_st (local.get $ea) (i32.const 1) (call $m_shift (i32.and (local.get $n) (i32.const 3)) (i32.and (local.get $op) (i32.const 0x100)) (i32.const 1) (call $m_ld (local.get $ea) (i32.const 1)) (i32.const 1)))
          (br $end)))
        (local.set $cnt (select (i32.and (call $m_d (local.get $n)) (i32.const 63)) (select (i32.const 8) (local.get $n) (i32.eqz (local.get $n))) (i32.and (local.get $op) (i32.const 0x20))))
        (call $m_st (i32.add (i32.const 0x10000) (local.get $reg)) (local.get $sz) (call $m_shift (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 3)) (i32.and (local.get $op) (i32.const 0x100)) (local.get $cnt) (call $m_d (local.get $reg)) (local.get $sz)))
        (br $end)))))
