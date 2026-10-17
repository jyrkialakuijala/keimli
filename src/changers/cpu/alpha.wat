  ;; DEC Alpha 21064, EV4 (kind 43): the first Alpha (1992), a 64-bit RISC with 32-bit little-endian instructions, four
  ;; to a cell. The 128-byte register file holds fifteen 64-bit registers: R0 at 0, R1 at 8, R2..R14 at 24 + 8 (n - 2)
  ;; (bytes 16..23 hold the PC at 22, a byte address); R16..R30 alias R0..R14 and R15 and R31 are the zero register
  ;; (reads 0, writes vanish), the convention of the RV32E and i860 cores here. Memory is the cell, addresses wrapping
  ;; at its end byte by byte, so a quadword may wrap round. The EV4 has no byte or word loads (BWX came with EV56), so
  ;; the byte-manipulation group (EXT/INS/MSK/ZAP) is what moves bytes. Implemented: LDA/LDAH, LDL/LDQ (the /L forms as
  ;; plain loads), LDQ_U, STL/STQ (the /C forms store and set Ra = 1), STQ_U, the integer arithmetic (ADD/SUB with the
  ;; S4/S8 forms, the /V forms without traps, CMPEQ/LT/LE/ULT/ULE, CMPBGE), the logical group (AND BIC BIS ORNOT XOR EQV,
  ;; the CMOVxx, AMASK = Rb and IMPLVER = 0 as on an EV4), shifts (SLL SRL SRA), EXTxL/EXTxH, INSxL/INSxH, MSKxL/MSKxH,
  ;; ZAP/ZAPNOT, MULL/MULQ/UMULH, BR/BSR, the eight integer conditional branches, and JMP/JSR/RET/JSR_COROUTINE.
  ;; CALL_PAL, the floating-point loads, stores, operates and branches, the miscellaneous group (TRAPB, MB, RPCC, ...)
  ;; and the opcodes the EV4 lacks are NOPs.
  (func $al_off (param $n i32) (result i32)   ;; byte offset of register n's slot, -1 for the zero register
    (local $s i32)
    (local.set $s (i32.and (local.get $n) (i32.const 15)))
    (if (i32.eq (local.get $s) (i32.const 15)) (then (return (i32.const -1))))
    (if (i32.eqz (local.get $s)) (then (return (i32.const 0))))
    (if (i32.eq (local.get $s) (i32.const 1)) (then (return (i32.const 8))))
    (i32.add (i32.const 24) (i32.shl (i32.sub (local.get $s) (i32.const 2)) (i32.const 3))))
  (func $al_get (param $n i32) (result i64)
    (local $o i32) (local.set $o (call $al_off (local.get $n)))
    (if (i32.lt_s (local.get $o) (i32.const 0)) (then (return (i64.const 0))))
    (call $zr64 (local.get $o)))
  (func $al_set (param $n i32) (param $v i64)
    (local $o i32) (local.set $o (call $al_off (local.get $n)))
    (if (i32.ge_s (local.get $o) (i32.const 0)) (then (call $zw64 (local.get $o) (local.get $v)))))
  (func $al_ld64 (param $a i32) (result i64)
    (i64.or (i64.extend_i32_u (call $mrd32 (local.get $a))) (i64.shl (i64.extend_i32_u (call $mrd32 (i32.add (local.get $a) (i32.const 4)))) (i64.const 32))))
  (func $al_st64 (param $a i32) (param $v i64)
    (call $mwr32 (local.get $a) (i32.wrap_i64 (local.get $v)))
    (call $mwr32 (i32.add (local.get $a) (i32.const 4)) (i32.wrap_i64 (i64.shr_u (local.get $v) (i64.const 32)))))
  (func $al_sx32 (param $v i64) (result i64) (i64.extend_i32_s (i32.wrap_i64 (local.get $v))))
  (func $al_umulh (param $a i64) (param $b i64) (result i64)   ;; the high 64 bits of the unsigned 128-bit product
    (local $a0 i64) (local $a1 i64) (local $b0 i64) (local $b1 i64) (local $t i64) (local $u i64) (local $v i64)
    (local.set $a0 (i64.and (local.get $a) (i64.const 0xffffffff))) (local.set $a1 (i64.shr_u (local.get $a) (i64.const 32)))
    (local.set $b0 (i64.and (local.get $b) (i64.const 0xffffffff))) (local.set $b1 (i64.shr_u (local.get $b) (i64.const 32)))
    (local.set $t (i64.mul (local.get $a0) (local.get $b0)))
    (local.set $u (i64.add (i64.mul (local.get $a1) (local.get $b0)) (i64.shr_u (local.get $t) (i64.const 32))))
    (local.set $v (i64.add (i64.mul (local.get $a0) (local.get $b1)) (i64.and (local.get $u) (i64.const 0xffffffff))))
    (i64.add (i64.add (i64.mul (local.get $a1) (local.get $b1)) (i64.shr_u (local.get $u) (i64.const 32))) (i64.shr_u (local.get $v) (i64.const 32))))
  (func $al_bmask (param $sz i32) (result i64)   ;; the low sz bytes
    (select (i64.const -1) (i64.sub (i64.shl (i64.const 1) (i64.extend_i32_u (i32.shl (local.get $sz) (i32.const 3)))) (i64.const 1)) (i32.eq (local.get $sz) (i32.const 8))))
  (func $al_zap (param $v i64) (param $m i32) (result i64)   ;; zero the bytes whose bits are set in m
    (local $i i32)
    (block $e (loop $l (br_if $e (i32.ge_u (local.get $i) (i32.const 8)))
      (if (i32.and (i32.shr_u (local.get $m) (local.get $i)) (i32.const 1)) (then
        (local.set $v (i64.and (local.get $v) (i64.xor (i64.shl (i64.const 0xff) (i64.extend_i32_u (i32.shl (local.get $i) (i32.const 3)))) (i64.const -1))))))
      (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $l)))
    (local.get $v))
  (func $al_cmpbge (param $a i64) (param $b i64) (result i64)
    (local $i i32) (local $r i64)
    (block $e (loop $l (br_if $e (i32.ge_u (local.get $i) (i32.const 8)))
      (if (i64.ge_u (i64.and (i64.shr_u (local.get $a) (i64.extend_i32_u (i32.shl (local.get $i) (i32.const 3)))) (i64.const 0xff))
                    (i64.and (i64.shr_u (local.get $b) (i64.extend_i32_u (i32.shl (local.get $i) (i32.const 3)))) (i64.const 0xff)))
        (then (local.set $r (i64.or (local.get $r) (i64.shl (i64.const 1) (i64.extend_i32_u (local.get $i)))))))
      (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $l)))
    (local.get $r))
  (func $alpha_step
    (local $pc i32) (local $ins i32) (local $op i32) (local $ra i32) (local $rb i32) (local $rc i32) (local $fn i32) (local $av i64) (local $bv i64) (local $r i64)
    (local $disp i32) (local $ea i32) (local $sh i32) (local $sz i32) (local $cond i32) (local $wr i32) (local $k i32)
    (local.set $pc (call $zr16 (i32.const 22)))
    (local.set $ins (call $mrd32 (local.get $pc)))
    (call $zw16 (i32.const 22) (i32.and (i32.add (local.get $pc) (i32.const 4)) (i32.const 0xffff)))
    (local.set $op (i32.shr_u (local.get $ins) (i32.const 26)))
    (local.set $ra (i32.and (i32.shr_u (local.get $ins) (i32.const 21)) (i32.const 31)))
    (local.set $rb (i32.and (i32.shr_u (local.get $ins) (i32.const 16)) (i32.const 31)))
    (local.set $av (call $al_get (local.get $ra)))
    ;; memory format: opcodes 08 09 0B 0F and 28..2F
    (if (i32.or (i32.or (i32.eq (local.get $op) (i32.const 0x08)) (i32.eq (local.get $op) (i32.const 0x09)))
                (i32.or (i32.or (i32.eq (local.get $op) (i32.const 0x0B)) (i32.eq (local.get $op) (i32.const 0x0F)))
                        (i32.and (i32.ge_u (local.get $op) (i32.const 0x28)) (i32.le_u (local.get $op) (i32.const 0x2F))))) (then
      (local.set $disp (call $sx (i32.and (local.get $ins) (i32.const 0xffff)) (i32.const 16)))
      (local.set $bv (call $al_get (local.get $rb)))
      (local.set $ea (i32.add (i32.wrap_i64 (local.get $bv)) (local.get $disp)))
      (if (i32.eq (local.get $op) (i32.const 0x08)) (then (call $al_set (local.get $ra) (i64.add (local.get $bv) (i64.extend_i32_s (local.get $disp)))) (return)))
      (if (i32.eq (local.get $op) (i32.const 0x09)) (then (call $al_set (local.get $ra) (i64.add (local.get $bv) (i64.shl (i64.extend_i32_s (local.get $disp)) (i64.const 16)))) (return)))
      (if (i32.eq (local.get $op) (i32.const 0x0B)) (then (call $al_set (local.get $ra) (call $al_ld64 (i32.and (local.get $ea) (i32.const -8)))) (return)))
      (if (i32.eq (local.get $op) (i32.const 0x0F)) (then (call $al_st64 (i32.and (local.get $ea) (i32.const -8)) (local.get $av)) (return)))
      (if (i32.or (i32.eq (local.get $op) (i32.const 0x28)) (i32.eq (local.get $op) (i32.const 0x2A))) (then (call $al_set (local.get $ra) (i64.extend_i32_s (call $mrd32 (local.get $ea)))) (return)))
      (if (i32.or (i32.eq (local.get $op) (i32.const 0x29)) (i32.eq (local.get $op) (i32.const 0x2B))) (then (call $al_set (local.get $ra) (call $al_ld64 (local.get $ea))) (return)))
      (if (i32.or (i32.eq (local.get $op) (i32.const 0x2C)) (i32.eq (local.get $op) (i32.const 0x2E))) (then
        (call $mwr32 (local.get $ea) (i32.wrap_i64 (local.get $av)))
        (if (i32.eq (local.get $op) (i32.const 0x2E)) (then (call $al_set (local.get $ra) (i64.const 1)))) (return)))
      (call $al_st64 (local.get $ea) (local.get $av))   ;; 2D STQ, 2F STQ_C
      (if (i32.eq (local.get $op) (i32.const 0x2F)) (then (call $al_set (local.get $ra) (i64.const 1))))
      (return)))
    ;; branch format: 30..3F
    (if (i32.ge_u (local.get $op) (i32.const 0x30)) (then
      (local.set $disp (call $sx (i32.and (local.get $ins) (i32.const 0x1fffff)) (i32.const 21)))
      (local.set $cond (i32.const 0))
      (if (i32.or (i32.eq (local.get $op) (i32.const 0x30)) (i32.eq (local.get $op) (i32.const 0x34))) (then   ;; BR, BSR
        (call $al_set (local.get $ra) (i64.extend_i32_u (i32.add (local.get $pc) (i32.const 4)))) (local.set $cond (i32.const 1))))
      (if (i32.eq (local.get $op) (i32.const 0x38)) (then (local.set $cond (i64.eqz (i64.and (local.get $av) (i64.const 1))))))   ;; BLBC
      (if (i32.eq (local.get $op) (i32.const 0x39)) (then (local.set $cond (i64.eqz (local.get $av)))))                           ;; BEQ
      (if (i32.eq (local.get $op) (i32.const 0x3A)) (then (local.set $cond (i64.lt_s (local.get $av) (i64.const 0)))))           ;; BLT
      (if (i32.eq (local.get $op) (i32.const 0x3B)) (then (local.set $cond (i64.le_s (local.get $av) (i64.const 0)))))           ;; BLE
      (if (i32.eq (local.get $op) (i32.const 0x3C)) (then (local.set $cond (i32.wrap_i64 (i64.and (local.get $av) (i64.const 1))))))   ;; BLBS
      (if (i32.eq (local.get $op) (i32.const 0x3D)) (then (local.set $cond (i64.ne (local.get $av) (i64.const 0)))))             ;; BNE
      (if (i32.eq (local.get $op) (i32.const 0x3E)) (then (local.set $cond (i64.ge_s (local.get $av) (i64.const 0)))))           ;; BGE
      (if (i32.eq (local.get $op) (i32.const 0x3F)) (then (local.set $cond (i64.gt_s (local.get $av) (i64.const 0)))))           ;; BGT
      (if (local.get $cond) (then (call $zw16 (i32.const 22) (i32.and (i32.add (i32.add (local.get $pc) (i32.const 4)) (i32.shl (local.get $disp) (i32.const 2))) (i32.const 0xffff)))))
      (return)))
    ;; jumps: 1A JMP, JSR, RET, JSR_COROUTINE all alike
    (if (i32.eq (local.get $op) (i32.const 0x1A)) (then
      (local.set $bv (call $al_get (local.get $rb)))
      (call $al_set (local.get $ra) (i64.extend_i32_u (i32.add (local.get $pc) (i32.const 4))))
      (call $zw16 (i32.const 22) (i32.and (i32.wrap_i64 (local.get $bv)) (i32.const 0xfffc)))
      (return)))
    ;; operate format: 10 arithmetic, 11 logical, 12 shifts and bytes, 13 multiply; the rest are NOPs
    (if (i32.or (i32.lt_u (local.get $op) (i32.const 0x10)) (i32.gt_u (local.get $op) (i32.const 0x13))) (then (return)))
    (local.set $rc (i32.and (local.get $ins) (i32.const 31)))
    (local.set $fn (i32.and (i32.shr_u (local.get $ins) (i32.const 5)) (i32.const 0x7f)))
    (local.set $bv (if (result i64) (i32.and (local.get $ins) (i32.const 0x1000))
      (then (i64.extend_i32_u (i32.and (i32.shr_u (local.get $ins) (i32.const 13)) (i32.const 0xff))))
      (else (call $al_get (local.get $rb)))))
    (local.set $wr (i32.const 1))
    (if (i32.eq (local.get $op) (i32.const 0x10)) (then
      (local.set $k (i32.and (local.get $fn) (i32.const 0x1f)))   ;; the /V bit (0x40) does not change the result here
      (local.set $cond (i32.and (local.get $fn) (i32.const 0x20)))   ;; 0 = longword forms, 0x20 = quadword
      (if (i32.eq (local.get $k) (i32.const 0x00)) (then (local.set $r (i64.add (local.get $av) (local.get $bv)))))                                         ;; ADDL/ADDQ
      (if (i32.eq (local.get $k) (i32.const 0x02)) (then (local.set $r (i64.add (i64.shl (local.get $av) (i64.const 2)) (local.get $bv)))))               ;; S4ADD
      (if (i32.eq (local.get $k) (i32.const 0x12)) (then (local.set $r (i64.add (i64.shl (local.get $av) (i64.const 3)) (local.get $bv)))))               ;; S8ADD
      (if (i32.eq (local.get $k) (i32.const 0x09)) (then (local.set $r (i64.sub (local.get $av) (local.get $bv)))))                                         ;; SUBL/SUBQ
      (if (i32.eq (local.get $k) (i32.const 0x0B)) (then (local.set $r (i64.sub (i64.shl (local.get $av) (i64.const 2)) (local.get $bv)))))               ;; S4SUB
      (if (i32.eq (local.get $k) (i32.const 0x1B)) (then (local.set $r (i64.sub (i64.shl (local.get $av) (i64.const 3)) (local.get $bv)))))               ;; S8SUB
      (if (i32.or (i32.or (i32.eq (local.get $k) (i32.const 0x00)) (i32.eq (local.get $k) (i32.const 0x02))) (i32.or (i32.or (i32.eq (local.get $k) (i32.const 0x12)) (i32.eq (local.get $k) (i32.const 0x09))) (i32.or (i32.eq (local.get $k) (i32.const 0x0B)) (i32.eq (local.get $k) (i32.const 0x1B)))))
        (then (if (i32.eqz (local.get $cond)) (then (local.set $r (call $al_sx32 (local.get $r))))) (call $al_set (local.get $rc) (local.get $r)) (return)))
      (if (i32.eq (local.get $fn) (i32.const 0x0F)) (then (call $al_set (local.get $rc) (call $al_cmpbge (local.get $av) (local.get $bv))) (return)))
      (if (i32.eq (local.get $fn) (i32.const 0x1D)) (then (call $al_set (local.get $rc) (i64.extend_i32_u (i64.lt_u (local.get $av) (local.get $bv)))) (return)))   ;; CMPULT
      (if (i32.eq (local.get $fn) (i32.const 0x3D)) (then (call $al_set (local.get $rc) (i64.extend_i32_u (i64.le_u (local.get $av) (local.get $bv)))) (return)))   ;; CMPULE
      (if (i32.eq (local.get $fn) (i32.const 0x2D)) (then (call $al_set (local.get $rc) (i64.extend_i32_u (i64.eq (local.get $av) (local.get $bv)))) (return)))     ;; CMPEQ
      (if (i32.eq (local.get $fn) (i32.const 0x4D)) (then (call $al_set (local.get $rc) (i64.extend_i32_u (i64.lt_s (local.get $av) (local.get $bv)))) (return)))   ;; CMPLT
      (if (i32.eq (local.get $fn) (i32.const 0x6D)) (then (call $al_set (local.get $rc) (i64.extend_i32_u (i64.le_s (local.get $av) (local.get $bv)))) (return)))   ;; CMPLE
      (return)))
    (if (i32.eq (local.get $op) (i32.const 0x11)) (then
      (if (i32.eq (local.get $fn) (i32.const 0x00)) (then (call $al_set (local.get $rc) (i64.and (local.get $av) (local.get $bv))) (return)))
      (if (i32.eq (local.get $fn) (i32.const 0x08)) (then (call $al_set (local.get $rc) (i64.and (local.get $av) (i64.xor (local.get $bv) (i64.const -1)))) (return)))   ;; BIC
      (if (i32.eq (local.get $fn) (i32.const 0x20)) (then (call $al_set (local.get $rc) (i64.or (local.get $av) (local.get $bv))) (return)))                              ;; BIS
      (if (i32.eq (local.get $fn) (i32.const 0x28)) (then (call $al_set (local.get $rc) (i64.or (local.get $av) (i64.xor (local.get $bv) (i64.const -1)))) (return)))    ;; ORNOT
      (if (i32.eq (local.get $fn) (i32.const 0x40)) (then (call $al_set (local.get $rc) (i64.xor (local.get $av) (local.get $bv))) (return)))                             ;; XOR
      (if (i32.eq (local.get $fn) (i32.const 0x48)) (then (call $al_set (local.get $rc) (i64.xor (local.get $av) (i64.xor (local.get $bv) (i64.const -1)))) (return)))   ;; EQV
      (if (i32.eq (local.get $fn) (i32.const 0x61)) (then (call $al_set (local.get $rc) (local.get $bv)) (return)))                                                       ;; AMASK: an EV4 clears nothing
      (if (i32.eq (local.get $fn) (i32.const 0x6C)) (then (call $al_set (local.get $rc) (i64.const 0)) (return)))                                                         ;; IMPLVER: 0 = EV4
      (local.set $cond (i32.const -1))
      (if (i32.eq (local.get $fn) (i32.const 0x14)) (then (local.set $cond (i32.wrap_i64 (i64.and (local.get $av) (i64.const 1))))))   ;; CMOVLBS
      (if (i32.eq (local.get $fn) (i32.const 0x16)) (then (local.set $cond (i64.eqz (i64.and (local.get $av) (i64.const 1))))))         ;; CMOVLBC
      (if (i32.eq (local.get $fn) (i32.const 0x24)) (then (local.set $cond (i64.eqz (local.get $av)))))                                 ;; CMOVEQ
      (if (i32.eq (local.get $fn) (i32.const 0x26)) (then (local.set $cond (i64.ne (local.get $av) (i64.const 0)))))                   ;; CMOVNE
      (if (i32.eq (local.get $fn) (i32.const 0x44)) (then (local.set $cond (i64.lt_s (local.get $av) (i64.const 0)))))                 ;; CMOVLT
      (if (i32.eq (local.get $fn) (i32.const 0x46)) (then (local.set $cond (i64.ge_s (local.get $av) (i64.const 0)))))                 ;; CMOVGE
      (if (i32.eq (local.get $fn) (i32.const 0x64)) (then (local.set $cond (i64.le_s (local.get $av) (i64.const 0)))))                 ;; CMOVLE
      (if (i32.eq (local.get $fn) (i32.const 0x66)) (then (local.set $cond (i64.gt_s (local.get $av) (i64.const 0)))))                 ;; CMOVGT
      (if (i32.eq (local.get $cond) (i32.const 1)) (then (call $al_set (local.get $rc) (local.get $bv))))
      (return)))
    (if (i32.eq (local.get $op) (i32.const 0x12)) (then
      (local.set $sh (i32.shl (i32.and (i32.wrap_i64 (local.get $bv)) (i32.const 7)) (i32.const 3)))
      (local.set $sz (select (i32.const 1) (select (i32.const 2) (select (i32.const 4) (i32.const 8) (i32.eq (i32.and (local.get $fn) (i32.const 0x30)) (i32.const 0x20))) (i32.eq (i32.and (local.get $fn) (i32.const 0x30)) (i32.const 0x10))) (i32.eqz (i32.and (local.get $fn) (i32.const 0x30)))))   ;; byte size from bits 5..4 of fn for the EXT/INS/MSK families
      (if (i32.eq (local.get $fn) (i32.const 0x39)) (then (call $al_set (local.get $rc) (i64.shl (local.get $av) (i64.and (local.get $bv) (i64.const 63)))) (return)))    ;; SLL
      (if (i32.eq (local.get $fn) (i32.const 0x34)) (then (call $al_set (local.get $rc) (i64.shr_u (local.get $av) (i64.and (local.get $bv) (i64.const 63)))) (return)))  ;; SRL
      (if (i32.eq (local.get $fn) (i32.const 0x3C)) (then (call $al_set (local.get $rc) (i64.shr_s (local.get $av) (i64.and (local.get $bv) (i64.const 63)))) (return)))  ;; SRA
      (if (i32.eq (local.get $fn) (i32.const 0x30)) (then (call $al_set (local.get $rc) (call $al_zap (local.get $av) (i32.and (i32.wrap_i64 (local.get $bv)) (i32.const 0xff)))) (return)))          ;; ZAP
      (if (i32.eq (local.get $fn) (i32.const 0x31)) (then (call $al_set (local.get $rc) (call $al_zap (local.get $av) (i32.and (i32.xor (i32.wrap_i64 (local.get $bv)) (i32.const -1)) (i32.const 0xff)))) (return)))   ;; ZAPNOT
      (local.set $k (i32.and (local.get $fn) (i32.const 0x4f)))   ;; the family: 06 EXTxL, 0B INSxL, 02 MSKxL, 4A EXTxH, 47 INSxH, 42 MSKxH
      (if (i32.eq (local.get $k) (i32.const 0x06)) (then (call $al_set (local.get $rc) (i64.and (i64.shr_u (local.get $av) (i64.extend_i32_u (local.get $sh))) (call $al_bmask (local.get $sz)))) (return)))
      (if (i32.eq (local.get $k) (i32.const 0x0B)) (then (call $al_set (local.get $rc) (i64.shl (i64.and (local.get $av) (call $al_bmask (local.get $sz))) (i64.extend_i32_u (local.get $sh)))) (return)))
      (if (i32.eq (local.get $k) (i32.const 0x02)) (then (call $al_set (local.get $rc) (i64.and (local.get $av) (i64.xor (i64.shl (call $al_bmask (local.get $sz)) (i64.extend_i32_u (local.get $sh))) (i64.const -1)))) (return)))
      (if (i32.eq (local.get $k) (i32.const 0x4A)) (then (call $al_set (local.get $rc) (i64.and (i64.shl (local.get $av) (i64.extend_i32_u (i32.and (i32.sub (i32.const 64) (local.get $sh)) (i32.const 63)))) (call $al_bmask (local.get $sz)))) (return)))
      (if (i32.eq (local.get $k) (i32.const 0x47)) (then (call $al_set (local.get $rc) (select (i64.const 0) (i64.shr_u (i64.and (local.get $av) (call $al_bmask (local.get $sz))) (i64.extend_i32_u (i32.sub (i32.const 64) (local.get $sh)))) (i32.eqz (local.get $sh)))) (return)))
      (if (i32.eq (local.get $k) (i32.const 0x42)) (then (call $al_set (local.get $rc) (select (local.get $av) (i64.and (local.get $av) (i64.xor (i64.shr_u (call $al_bmask (local.get $sz)) (i64.extend_i32_u (i32.sub (i32.const 64) (local.get $sh)))) (i64.const -1))) (i32.eqz (local.get $sh)))) (return)))
      (return)))
    ;; 13: multiplies
    (local.set $k (i32.and (local.get $fn) (i32.const 0x3f)))
    (if (i32.eq (local.get $k) (i32.const 0x00)) (then (call $al_set (local.get $rc) (call $al_sx32 (i64.mul (local.get $av) (local.get $bv)))) (return)))   ;; MULL
    (if (i32.eq (local.get $k) (i32.const 0x20)) (then (call $al_set (local.get $rc) (i64.mul (local.get $av) (local.get $bv))) (return)))                   ;; MULQ
    (if (i32.eq (local.get $k) (i32.const 0x30)) (then (call $al_set (local.get $rc) (call $al_umulh (local.get $av) (local.get $bv))) (return))))             ;; UMULH
