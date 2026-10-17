  ;; HP PA-RISC 1.1 (kind 44), the PA-7100 generation (1992): a 32-bit big-endian RISC with 32-bit instructions, four
  ;; to a cell, delayed branches and nullification. Register file: GR1..GR15 as 32-bit words at 64 + 4n (GR0 reads 0 and
  ;; drops writes; GR16..GR31 alias GR0..GR15, so GR16 is zero too), PC at 22 (a byte address), byte 21 the state
  ;; (bit 0: nullify the next instruction, bit 1: a branch is pending), the pending target at 24. Memory is the cell,
  ;; big-endian, addresses wrapping byte by byte. Implemented: LDO/LDI, LDIL, ADDIL; LDW LDH LDB STW STH STB with the
  ;; 14-bit displacement, LDWM/STWM; the three-register arithmetic and logical group (ADD ADDC ADDL SH1/2/3ADD(L) SUB SUBB
  ;; SUBT DS AND ANDCM OR XOR UXOR UADDCM COMCLR, the /O forms without traps) with the arithmetic, logical and compare
  ;; conditions nullifying the next instruction; ADDI ADDIT SUBI COMICLR; the fixed shifts and bit fields SHD EXTRU
  ;; EXTRS ZDEP DEP ZDEPI DEPI; the branches BL, BLR, BV, COMBT/COMBF, COMIBT/COMIBF, ADDBT/ADDBF, ADDIBT/ADDIBF, BB,
  ;; MOVB and MOVIB, each with its delay slot and the nullify bit (a conditional branch's slot is nullified when the
  ;; branch is taken forward or not taken backward). The system, memory-management, coprocessor and floating-point
  ;; groups, the external branches and the variable shifts are NOPs.
  (func $pa_get (param $n i32) (result i32)
    (local.set $n (i32.and (local.get $n) (i32.const 15)))
    (if (i32.eqz (local.get $n)) (then (return (i32.const 0))))
    (call $zr32 (i32.add (i32.const 64) (i32.shl (local.get $n) (i32.const 2)))))
  (func $pa_set (param $n i32) (param $v i32)
    (local.set $n (i32.and (local.get $n) (i32.const 15)))
    (if (local.get $n) (then (call $zw32 (i32.add (i32.const 64) (i32.shl (local.get $n) (i32.const 2))) (local.get $v)))))
  (func $pa_rd32 (param $a i32) (result i32) (i32.or (i32.shl (call $mrd16be (local.get $a)) (i32.const 16)) (call $mrd16be (i32.add (local.get $a) (i32.const 2)))))
  (func $pa_wr32 (param $a i32) (param $v i32) (call $mwr16be (local.get $a) (i32.shr_u (local.get $v) (i32.const 16))) (call $mwr16be (i32.add (local.get $a) (i32.const 2)) (local.get $v)))
  (func $pa_im14 (param $ins i32) (result i32)   ;; the low-sign 14-bit immediate: the sign is the last bit
    (local $f i32) (local.set $f (i32.and (local.get $ins) (i32.const 0x3fff)))
    (i32.or (i32.shr_u (local.get $f) (i32.const 1)) (i32.mul (i32.and (local.get $f) (i32.const 1)) (i32.const -8192))))
  (func $pa_im11 (param $f i32) (result i32)   ;; low-sign 11 bits
    (local.set $f (i32.and (local.get $f) (i32.const 0x7ff)))
    (i32.or (i32.shr_u (local.get $f) (i32.const 1)) (i32.mul (i32.and (local.get $f) (i32.const 1)) (i32.const -1024))))
  (func $pa_im5 (param $f i32) (result i32)   ;; low-sign 5 bits
    (local.set $f (i32.and (local.get $f) (i32.const 31)))
    (i32.or (i32.shr_u (local.get $f) (i32.const 1)) (i32.mul (i32.and (local.get $f) (i32.const 1)) (i32.const -16))))
  (func $pa_asm21 (param $x i32) (result i32)   ;; assemble_21: cat(x{20}, x{9..19}, x{5..6}, x{0..4}, x{7..8}) of the 21-bit field
    (i32.or (i32.or (i32.shl (i32.and (local.get $x) (i32.const 1)) (i32.const 20)) (i32.shl (i32.and (i32.shr_u (local.get $x) (i32.const 1)) (i32.const 0x7ff)) (i32.const 9)))
            (i32.or (i32.or (i32.shl (i32.and (i32.shr_u (local.get $x) (i32.const 14)) (i32.const 3)) (i32.const 7)) (i32.shl (i32.and (i32.shr_u (local.get $x) (i32.const 16)) (i32.const 31)) (i32.const 2)))
                    (i32.and (i32.shr_u (local.get $x) (i32.const 12)) (i32.const 3)))))
  (func $pa_disp12 (param $ins i32) (result i32)   ;; assemble_12(w1, w) of a conditional branch, in words, signed
    (local $w1 i32) (local.set $w1 (i32.and (i32.shr_u (local.get $ins) (i32.const 2)) (i32.const 0x7ff)))
    (call $sx (i32.or (i32.or (i32.shl (i32.and (local.get $ins) (i32.const 1)) (i32.const 11)) (i32.shl (i32.and (local.get $w1) (i32.const 1)) (i32.const 10))) (i32.shr_u (local.get $w1) (i32.const 1))) (i32.const 12)))
  (func $pa_disp17 (param $ins i32) (result i32)   ;; assemble_17(w1, w2, w) of BL, in words, signed
    (local $w2 i32) (local.set $w2 (i32.and (i32.shr_u (local.get $ins) (i32.const 2)) (i32.const 0x7ff)))
    (call $sx (i32.or (i32.or (i32.shl (i32.and (local.get $ins) (i32.const 1)) (i32.const 16)) (i32.shl (i32.and (i32.shr_u (local.get $ins) (i32.const 16)) (i32.const 31)) (i32.const 11)))
                      (i32.or (i32.shl (i32.and (local.get $w2) (i32.const 1)) (i32.const 10)) (i32.shr_u (local.get $w2) (i32.const 1)))) (i32.const 17)))
  ;; conditions: kind 0 = add (res, carry out, signed overflow), 1 = subtract/compare of a - b (a, b given), 2 = logical/unit
  (func $pa_cond (param $c i32) (param $f i32) (param $kind i32) (param $res i32) (param $a i32) (param $b i32) (param $carry i32) (param $ovf i32) (result i32)
    (local $r i32)
    (if (i32.eq (local.get $c) (i32.const 1)) (then (local.set $r (i32.eqz (local.get $res)))))
    (if (i32.eq (local.get $c) (i32.const 2)) (then (local.set $r (select (i32.lt_s (local.get $a) (local.get $b)) (i32.lt_s (local.get $res) (i32.const 0)) (i32.eq (local.get $kind) (i32.const 1))))))
    (if (i32.eq (local.get $c) (i32.const 3)) (then (local.set $r (select (i32.le_s (local.get $a) (local.get $b)) (i32.le_s (local.get $res) (i32.const 0)) (i32.eq (local.get $kind) (i32.const 1))))))
    (if (i32.eq (local.get $c) (i32.const 4)) (then (local.set $r (select (i32.lt_u (local.get $a) (local.get $b)) (i32.eqz (local.get $carry)) (i32.eq (local.get $kind) (i32.const 1))))))   ;; << or NUV
    (if (i32.eq (local.get $c) (i32.const 5)) (then (local.set $r (select (i32.le_u (local.get $a) (local.get $b)) (i32.or (i32.eqz (local.get $res)) (i32.eqz (local.get $ovf))) (i32.eq (local.get $kind) (i32.const 1))))))   ;; <<= or ZNV
    (if (i32.eq (local.get $c) (i32.const 6)) (then (local.set $r (local.get $ovf))))
    (if (i32.eq (local.get $c) (i32.const 7)) (then (local.set $r (i32.and (local.get $res) (i32.const 1)))))
    (if (i32.eq (local.get $kind) (i32.const 2)) (then (if (i32.and (i32.ge_u (local.get $c) (i32.const 4)) (i32.le_u (local.get $c) (i32.const 6))) (then (local.set $r (i32.const 0))))))   ;; logical: never
    (i32.xor (local.get $r) (local.get $f)))
  (func $pa_scond (param $c i32) (param $res i32) (result i32)   ;; the shift/extract/deposit conditions: 0 never 1 = 2 < 3 OD, 4..7 their negations
    (local $r i32)
    (if (i32.eq (i32.and (local.get $c) (i32.const 3)) (i32.const 1)) (then (local.set $r (i32.eqz (local.get $res)))))
    (if (i32.eq (i32.and (local.get $c) (i32.const 3)) (i32.const 2)) (then (local.set $r (i32.lt_s (local.get $res) (i32.const 0)))))
    (if (i32.eq (i32.and (local.get $c) (i32.const 3)) (i32.const 3)) (then (local.set $r (i32.and (local.get $res) (i32.const 1)))))
    (i32.xor (local.get $r) (i32.shr_u (local.get $c) (i32.const 2))))
  (func $pa_nullify (call $zw (i32.const 21) (i32.or (call $zr (i32.const 21)) (i32.const 1))))
  (func $pa_branch (param $target i32) (call $zw16 (i32.const 24) (i32.and (local.get $target) (i32.const 0xfffc))) (call $zw (i32.const 21) (i32.or (call $zr (i32.const 21)) (i32.const 2))))
  ;; a conditional branch: taken -> pending; the delay slot is nullified with n = 1 when taken forward or not taken backward
  (func $pa_cbranch (param $taken i32) (param $pc i32) (param $disp i32) (param $n i32)
    (if (local.get $taken) (then (call $pa_branch (i32.add (i32.add (local.get $pc) (i32.const 8)) (i32.shl (local.get $disp) (i32.const 2))))))
    (if (local.get $n) (then
      (if (i32.ne (local.get $taken) (i32.lt_s (local.get $disp) (i32.const 0))) (then (call $pa_nullify))))))
  (func $pa_addsub (param $kind i32) (param $a i32) (param $b i32) (param $cin i32) (result i32)   ;; kind 0 add, 1 sub; sets the carry/borrow in byte 20 and returns the result, overflow in the register file byte 26
    (local $r i64) (local $res i32) (local $ovf i32)
    (if (local.get $kind)
      (then (local.set $r (i64.add (i64.sub (i64.extend_i32_u (local.get $a)) (i64.extend_i32_u (local.get $b))) (i64.extend_i32_s (local.get $cin))))   ;; cin = 0 or -1 (the borrow) for SUBB
            (local.set $res (i32.wrap_i64 (local.get $r)))
            (local.set $ovf (i32.and (i32.lt_s (i32.xor (local.get $a) (local.get $b)) (i32.const 0)) (i32.lt_s (i32.xor (local.get $a) (local.get $res)) (i32.const 0))))
            (call $zw (i32.const 20) (i64.ge_s (local.get $r) (i64.const 0))))   ;; the PA "carry" of a subtract: no borrow
      (else (local.set $r (i64.add (i64.add (i64.extend_i32_u (local.get $a)) (i64.extend_i32_u (local.get $b))) (i64.extend_i32_u (local.get $cin))))
            (local.set $res (i32.wrap_i64 (local.get $r)))
            (local.set $ovf (i32.and (i32.ge_s (i32.xor (local.get $a) (local.get $b)) (i32.const 0)) (i32.lt_s (i32.xor (local.get $a) (local.get $res)) (i32.const 0))))
            (call $zw (i32.const 20) (i32.wrap_i64 (i64.shr_u (local.get $r) (i64.const 32))))))
    (call $zw (i32.const 26) (local.get $ovf))
    (local.get $res))
  (func $parisc_step
    (local $pc i32) (local $ins i32) (local $op i32) (local $r1 i32) (local $r2 i32) (local $t i32) (local $c i32) (local $f i32) (local $ext i32) (local $a i32) (local $b i32) (local $res i32)
    (local $st i32) (local $n i32) (local $disp i32) (local $imm i32) (local $p i32) (local $len i32) (local $mask i32) (local $sh i32) (local $k i32) (local $taken i32)
    (local.set $pc (call $zr16 (i32.const 22)))
    (local.set $ins (call $pa_rd32 (local.get $pc)))
    (call $zw16 (i32.const 22) (i32.and (i32.add (local.get $pc) (i32.const 4)) (i32.const 0xffff)))
    (local.set $st (call $zr (i32.const 21)))
    (if (i32.and (local.get $st) (i32.const 1)) (then   ;; nullified: this instruction does nothing
      (call $zw (i32.const 21) (i32.and (local.get $st) (i32.const 2)))
      (local.set $st (i32.and (local.get $st) (i32.const 2)))
      (local.set $ins (i32.const 0))))
    (if (i32.and (local.get $st) (i32.const 2)) (then   ;; this was a delay slot: the branch takes effect after it
      (call $zw (i32.const 21) (i32.and (call $zr (i32.const 21)) (i32.const 1)))
      (call $zw16 (i32.const 22) (call $zr16 (i32.const 24)))))
    (local.set $op (i32.shr_u (local.get $ins) (i32.const 26)))
    (local.set $r2 (i32.and (i32.shr_u (local.get $ins) (i32.const 21)) (i32.const 31)))   ;; bits 6..10: b / r2 / t
    (local.set $r1 (i32.and (i32.shr_u (local.get $ins) (i32.const 16)) (i32.const 31)))   ;; bits 11..15: t / r1 / x
    (local.set $c (i32.and (i32.shr_u (local.get $ins) (i32.const 13)) (i32.const 7)))
    (local.set $f (i32.and (i32.shr_u (local.get $ins) (i32.const 12)) (i32.const 1)))
    (local.set $n (i32.and (i32.shr_u (local.get $ins) (i32.const 1)) (i32.const 1)))
    (block $done
      ;; 0D LDO: t = b + im14
      (if (i32.eq (local.get $op) (i32.const 0x0D)) (then (call $pa_set (local.get $r1) (i32.add (call $pa_get (local.get $r2)) (call $pa_im14 (local.get $ins)))) (br $done)))
      ;; 08 LDIL: t = assemble_21 << 11; 0A ADDIL: GR1 = r + (assemble_21 << 11)
      (if (i32.eq (local.get $op) (i32.const 0x08)) (then (call $pa_set (local.get $r2) (i32.shl (call $pa_asm21 (i32.and (local.get $ins) (i32.const 0x1fffff))) (i32.const 11))) (br $done)))
      (if (i32.eq (local.get $op) (i32.const 0x0A)) (then (call $pa_set (i32.const 1) (i32.add (call $pa_get (local.get $r2)) (i32.shl (call $pa_asm21 (i32.and (local.get $ins) (i32.const 0x1fffff))) (i32.const 11)))) (br $done)))
      ;; loads and stores with a 14-bit displacement: 10 LDB 11 LDH 12 LDW 13 LDWM 18 STB 19 STH 1A STW 1B STWM
      (if (i32.and (i32.ge_u (local.get $op) (i32.const 0x10)) (i32.le_u (local.get $op) (i32.const 0x1B))) (then
        (if (i32.and (i32.gt_u (local.get $op) (i32.const 0x13)) (i32.lt_u (local.get $op) (i32.const 0x18))) (then (br $done)))   ;; 14..17: FP and others
        (local.set $imm (call $pa_im14 (local.get $ins)))
        (local.set $a (call $pa_get (local.get $r2)))
        (local.set $b (i32.add (local.get $a) (local.get $imm)))   ;; the address, or the base before modification for LDWM/STWM
        (if (i32.eq (local.get $op) (i32.const 0x10)) (then (call $pa_set (local.get $r1) (call $mrd (local.get $b))) (br $done)))
        (if (i32.eq (local.get $op) (i32.const 0x11)) (then (call $pa_set (local.get $r1) (call $mrd16be (local.get $b))) (br $done)))
        (if (i32.eq (local.get $op) (i32.const 0x12)) (then (call $pa_set (local.get $r1) (call $pa_rd32 (local.get $b))) (br $done)))
        (if (i32.eq (local.get $op) (i32.const 0x13)) (then (call $pa_set (local.get $r1) (call $pa_rd32 (local.get $a))) (call $pa_set (local.get $r2) (local.get $b)) (br $done)))   ;; LDWM: load from b, then b += im14
        (if (i32.eq (local.get $op) (i32.const 0x18)) (then (call $mwr (local.get $b) (call $pa_get (local.get $r1))) (br $done)))
        (if (i32.eq (local.get $op) (i32.const 0x19)) (then (call $mwr16be (local.get $b) (call $pa_get (local.get $r1))) (br $done)))
        (if (i32.eq (local.get $op) (i32.const 0x1A)) (then (call $pa_wr32 (local.get $b) (call $pa_get (local.get $r1))) (br $done)))
        (call $pa_wr32 (local.get $a) (call $pa_get (local.get $r1))) (call $pa_set (local.get $r2) (local.get $b))   ;; 1B STWM: store at b, then b += im14
        (br $done)))
      ;; 02: three-register arithmetic and logical
      (if (i32.eq (local.get $op) (i32.const 0x02)) (then
        (local.set $ext (i32.and (i32.shr_u (local.get $ins) (i32.const 6)) (i32.const 0x3f)))
        (local.set $t (i32.and (local.get $ins) (i32.const 31)))
        (local.set $a (call $pa_get (local.get $r1))) (local.set $b (call $pa_get (local.get $r2)))
        (local.set $k (select (i32.or (i32.and (local.get $ext) (i32.const 0x0f)) (i32.const 0x10)) (local.get $ext) (i32.and (local.get $ext) (i32.const 0x20))))   ;; fold the L (2x) and /O (3x) variants onto 1x
        ;; adds: 18 ADD, 1C ADDC, 19/1A/1B SHnADD (and 28.. ADDL, 38.. ADDO forms)
        (if (i32.or (i32.eq (local.get $k) (i32.const 0x18)) (i32.or (i32.eq (local.get $k) (i32.const 0x1C)) (i32.and (i32.ge_u (local.get $k) (i32.const 0x19)) (i32.le_u (local.get $k) (i32.const 0x1B))))) (then
          (if (i32.and (i32.ge_u (local.get $k) (i32.const 0x19)) (i32.le_u (local.get $k) (i32.const 0x1B))) (then (local.set $a (i32.shl (local.get $a) (i32.sub (local.get $k) (i32.const 0x18))))))
          (local.set $res (call $pa_addsub (i32.const 0) (local.get $a) (local.get $b) (select (call $zr (i32.const 20)) (i32.const 0) (i32.eq (local.get $k) (i32.const 0x1C)))))
          (call $pa_set (local.get $t) (local.get $res))
          (if (call $pa_cond (local.get $c) (local.get $f) (i32.const 0) (local.get $res) (local.get $a) (local.get $b) (call $zr (i32.const 20)) (call $zr (i32.const 26))) (then (call $pa_nullify)))
          (br $done)))
        ;; subtracts: 10 SUB, 14 SUBB, 13 SUBT, 11 DS (as SUB)
        (if (i32.or (i32.or (i32.eq (local.get $k) (i32.const 0x10)) (i32.eq (local.get $k) (i32.const 0x14))) (i32.or (i32.eq (local.get $k) (i32.const 0x13)) (i32.eq (local.get $k) (i32.const 0x11)))) (then
          (local.set $res (call $pa_addsub (i32.const 1) (local.get $a) (local.get $b) (select (i32.sub (call $zr (i32.const 20)) (i32.const 1)) (i32.const 0) (i32.eq (local.get $k) (i32.const 0x14)))))
          (call $pa_set (local.get $t) (local.get $res))
          (if (call $pa_cond (local.get $c) (local.get $f) (i32.const 1) (local.get $res) (local.get $a) (local.get $b) (call $zr (i32.const 20)) (call $zr (i32.const 26))) (then (call $pa_nullify)))
          (br $done)))
        ;; 22 COMCLR: t = 0, nullify on the compare condition
        (if (i32.eq (local.get $ext) (i32.const 0x22)) (then
          (local.set $res (call $pa_addsub (i32.const 1) (local.get $a) (local.get $b) (i32.const 0))) (call $pa_set (local.get $t) (i32.const 0))
          (if (call $pa_cond (local.get $c) (local.get $f) (i32.const 1) (local.get $res) (local.get $a) (local.get $b) (call $zr (i32.const 20)) (call $zr (i32.const 26))) (then (call $pa_nullify)))
          (br $done)))
        ;; logical: 08 AND, 00 ANDCM, 09 OR, 0A XOR, 0E UXOR, 26 UADDCM
        (local.set $k (i32.const -1))
        (if (i32.eq (local.get $ext) (i32.const 0x08)) (then (local.set $res (i32.and (local.get $a) (local.get $b))) (local.set $k (i32.const 2))))
        (if (i32.eq (local.get $ext) (i32.const 0x00)) (then (local.set $res (i32.and (local.get $a) (i32.xor (local.get $b) (i32.const -1)))) (local.set $k (i32.const 2))))
        (if (i32.eq (local.get $ext) (i32.const 0x09)) (then (local.set $res (i32.or (local.get $a) (local.get $b))) (local.set $k (i32.const 2))))
        (if (i32.or (i32.eq (local.get $ext) (i32.const 0x0A)) (i32.eq (local.get $ext) (i32.const 0x0E))) (then (local.set $res (i32.xor (local.get $a) (local.get $b))) (local.set $k (i32.const 2))))
        (if (i32.eq (local.get $ext) (i32.const 0x26)) (then (local.set $res (i32.add (local.get $a) (i32.xor (local.get $b) (i32.const -1)))) (local.set $k (i32.const 2))))
        (if (i32.ge_s (local.get $k) (i32.const 0)) (then
          (call $pa_set (local.get $t) (local.get $res))
          (if (call $pa_cond (local.get $c) (local.get $f) (i32.const 2) (local.get $res) (local.get $a) (local.get $b) (i32.const 0) (i32.const 0)) (then (call $pa_nullify)))))
        (br $done)))
      ;; immediates: 2D ADDI/ADDIO, 2C ADDIT, 25 SUBI/SUBIO, 24 COMICLR: t = im11 (+|-) GR[r]; r in bits 6..10, t in 11..15
      (if (i32.or (i32.or (i32.eq (local.get $op) (i32.const 0x2D)) (i32.eq (local.get $op) (i32.const 0x2C))) (i32.or (i32.eq (local.get $op) (i32.const 0x25)) (i32.eq (local.get $op) (i32.const 0x24)))) (then
        (local.set $imm (call $pa_im11 (local.get $ins))) (local.set $b (call $pa_get (local.get $r2)))
        (if (i32.or (i32.eq (local.get $op) (i32.const 0x2D)) (i32.eq (local.get $op) (i32.const 0x2C)))
          (then (local.set $res (call $pa_addsub (i32.const 0) (local.get $imm) (local.get $b) (i32.const 0))) (call $pa_set (local.get $r1) (local.get $res))
                (if (call $pa_cond (local.get $c) (local.get $f) (i32.const 0) (local.get $res) (local.get $imm) (local.get $b) (call $zr (i32.const 20)) (call $zr (i32.const 26))) (then (call $pa_nullify))))
          (else (local.set $res (call $pa_addsub (i32.const 1) (local.get $imm) (local.get $b) (i32.const 0))) (call $pa_set (local.get $r1) (select (i32.const 0) (local.get $res) (i32.eq (local.get $op) (i32.const 0x24))))
                (if (call $pa_cond (local.get $c) (local.get $f) (i32.const 1) (local.get $res) (local.get $imm) (local.get $b) (call $zr (i32.const 20)) (call $zr (i32.const 26))) (then (call $pa_nullify)))))
        (br $done)))
      ;; 34: SHD (ext 2), EXTRU (6), EXTRS (7); fields: r2 6..10, r1 11..15, c, ext3 19..21, cp/p 22..26, clen 27..31
      (if (i32.eq (local.get $op) (i32.const 0x34)) (then
        (local.set $ext (i32.and (i32.shr_u (local.get $ins) (i32.const 10)) (i32.const 7)))
        (local.set $p (i32.and (i32.shr_u (local.get $ins) (i32.const 5)) (i32.const 31)))
        (local.set $len (i32.sub (i32.const 32) (i32.and (local.get $ins) (i32.const 31))))
        (local.set $mask (select (i32.const -1) (i32.sub (i32.shl (i32.const 1) (local.get $len)) (i32.const 1)) (i32.eq (local.get $len) (i32.const 32))))
        (local.set $k (i32.const -1))
        (if (i32.eq (local.get $ext) (i32.const 2)) (then   ;; SHD r1,r2,cp,t: (r1:r2) >> (31 - cp)
          (local.set $sh (i32.sub (i32.const 31) (local.get $p)))
          (local.set $res (i32.wrap_i64 (i64.shr_u (i64.or (i64.shl (i64.extend_i32_u (call $pa_get (local.get $r1))) (i64.const 32)) (i64.extend_i32_u (call $pa_get (local.get $r2)))) (i64.extend_i32_u (local.get $sh)))))
          (local.set $k (i32.and (local.get $ins) (i32.const 31)))))
        (if (i32.eq (local.get $ext) (i32.const 6)) (then (local.set $res (i32.and (i32.shr_u (call $pa_get (local.get $r2)) (i32.sub (i32.const 31) (local.get $p))) (local.get $mask))) (local.set $k (local.get $r1))))   ;; EXTRU r,p,len,t
        (if (i32.eq (local.get $ext) (i32.const 7)) (then (local.set $res (call $sx (i32.and (i32.shr_u (call $pa_get (local.get $r2)) (i32.sub (i32.const 31) (local.get $p))) (local.get $mask)) (local.get $len))) (local.set $k (local.get $r1))))   ;; EXTRS
        (if (i32.ge_s (local.get $k) (i32.const 0)) (then
          (call $pa_set (local.get $k) (local.get $res))
          (if (call $pa_scond (local.get $c) (local.get $res)) (then (call $pa_nullify)))))
        (br $done)))
      ;; 35: ZDEP (2), DEP (3), ZDEPI (6), DEPI (7); fields: t 6..10, r/im5 11..15, c, ext3 19..21, cp 22..26, clen 27..31
      (if (i32.eq (local.get $op) (i32.const 0x35)) (then
        (local.set $ext (i32.and (i32.shr_u (local.get $ins) (i32.const 10)) (i32.const 7)))
        (local.set $sh (i32.and (i32.shr_u (local.get $ins) (i32.const 5)) (i32.const 31)))   ;; cp = 31 - p, the shift
        (local.set $len (i32.sub (i32.const 32) (i32.and (local.get $ins) (i32.const 31))))
        (local.set $mask (select (i32.const -1) (i32.sub (i32.shl (i32.const 1) (local.get $len)) (i32.const 1)) (i32.eq (local.get $len) (i32.const 32))))
        (local.set $a (select (call $pa_im5 (local.get $r1)) (call $pa_get (local.get $r1)) (i32.and (local.get $ext) (i32.const 4))))
        (if (i32.or (i32.eq (local.get $ext) (i32.const 2)) (i32.eq (local.get $ext) (i32.const 6))) (then   ;; ZDEP/ZDEPI
          (call $pa_set (local.get $r2) (i32.shl (i32.and (local.get $a) (local.get $mask)) (local.get $sh)))
          (if (call $pa_scond (local.get $c) (call $pa_get (local.get $r2))) (then (call $pa_nullify)))
          (br $done)))
        (if (i32.or (i32.eq (local.get $ext) (i32.const 3)) (i32.eq (local.get $ext) (i32.const 7))) (then   ;; DEP/DEPI
          (call $pa_set (local.get $r2) (i32.or (i32.and (call $pa_get (local.get $r2)) (i32.xor (i32.shl (local.get $mask) (local.get $sh)) (i32.const -1))) (i32.shl (i32.and (local.get $a) (local.get $mask)) (local.get $sh))))
          (if (call $pa_scond (local.get $c) (call $pa_get (local.get $r2))) (then (call $pa_nullify)))
          (br $done)))
        (br $done)))
      ;; 3A: BL (ext 0), GATE (1, as BL), BLR (2), BV (6)
      (if (i32.eq (local.get $op) (i32.const 0x3A)) (then
        (local.set $ext (i32.and (i32.shr_u (local.get $ins) (i32.const 13)) (i32.const 7)))
        (if (i32.le_u (local.get $ext) (i32.const 1)) (then
          (call $pa_set (local.get $r2) (i32.add (local.get $pc) (i32.const 8)))
          (call $pa_branch (i32.add (i32.add (local.get $pc) (i32.const 8)) (i32.shl (call $pa_disp17 (local.get $ins)) (i32.const 2))))
          (if (local.get $n) (then (call $pa_nullify))) (br $done)))
        (if (i32.eq (local.get $ext) (i32.const 2)) (then   ;; BLR x,t
          (call $pa_set (local.get $r2) (i32.add (local.get $pc) (i32.const 8)))
          (call $pa_branch (i32.add (i32.add (local.get $pc) (i32.const 8)) (i32.shl (call $pa_get (local.get $r1)) (i32.const 3))))
          (if (local.get $n) (then (call $pa_nullify))) (br $done)))
        (if (i32.eq (local.get $ext) (i32.const 6)) (then   ;; BV x(b)
          (call $pa_branch (i32.add (call $pa_get (local.get $r2)) (i32.shl (call $pa_get (local.get $r1)) (i32.const 3))))
          (if (local.get $n) (then (call $pa_nullify))) (br $done)))
        (br $done)))
      ;; conditional branches: 20 COMBT 22 COMBF 21 COMIBT 23 COMIBF 28 ADDBT 2A ADDBF 29 ADDIBT 2B ADDIBF 30 BVB 31 BB 32 MOVB 33 MOVIB
      (if (i32.and (i32.ge_u (local.get $op) (i32.const 0x20)) (i32.le_u (local.get $op) (i32.const 0x33))) (then
        (local.set $disp (call $pa_disp12 (local.get $ins)))
        (local.set $f (i32.and (i32.shr_u (local.get $op) (i32.const 1)) (i32.const 1)))   ;; the F forms are the odd pairs: 22, 23, 2A, 2B
        (local.set $a (select (call $pa_im5 (local.get $r1)) (call $pa_get (local.get $r1)) (i32.and (local.get $op) (i32.const 1))))   ;; r1 or im5
        (local.set $b (call $pa_get (local.get $r2)))
        (if (i32.and (i32.ge_u (local.get $op) (i32.const 0x20)) (i32.le_u (local.get $op) (i32.const 0x23))) (then   ;; compare and branch: a ? b
          (local.set $res (call $pa_addsub (i32.const 1) (local.get $a) (local.get $b) (i32.const 0)))
          (call $pa_cbranch (call $pa_cond (local.get $c) (local.get $f) (i32.const 1) (local.get $res) (local.get $a) (local.get $b) (call $zr (i32.const 20)) (call $zr (i32.const 26))) (local.get $pc) (local.get $disp) (local.get $n))
          (br $done)))
        (if (i32.and (i32.ge_u (local.get $op) (i32.const 0x28)) (i32.le_u (local.get $op) (i32.const 0x2B))) (then   ;; add and branch: r2 += a
          (local.set $res (call $pa_addsub (i32.const 0) (local.get $a) (local.get $b) (i32.const 0))) (call $pa_set (local.get $r2) (local.get $res))
          (call $pa_cbranch (call $pa_cond (local.get $c) (local.get $f) (i32.const 0) (local.get $res) (local.get $a) (local.get $b) (call $zr (i32.const 20)) (call $zr (i32.const 26))) (local.get $pc) (local.get $disp) (local.get $n))
          (br $done)))
        (if (i32.eq (local.get $op) (i32.const 0x31)) (then   ;; BB r,p: r in bits 6..10, p in 11..15; branch on bit p (big-endian numbering) of r, c = 2 if set, 6 if clear
          (local.set $taken (i32.and (i32.shr_u (local.get $b) (i32.sub (i32.const 31) (local.get $r1))) (i32.const 1)))
          (call $pa_cbranch (i32.eq (local.get $taken) (i32.eq (local.get $c) (i32.const 2))) (local.get $pc) (local.get $disp) (local.get $n))
          (br $done)))
        (if (i32.or (i32.eq (local.get $op) (i32.const 0x32)) (i32.eq (local.get $op) (i32.const 0x33))) (then   ;; MOVB/MOVIB: r2 = a, branch on the logical condition of a
          (call $pa_set (local.get $r2) (local.get $a))
          (call $pa_cbranch (call $pa_cond (local.get $c) (i32.const 0) (i32.const 2) (local.get $a) (i32.const 0) (i32.const 0) (i32.const 0) (i32.const 0)) (local.get $pc) (local.get $disp) (local.get $n))
          (br $done)))
        (br $done)))))
