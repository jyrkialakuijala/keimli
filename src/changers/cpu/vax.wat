  ;; DEC VAX-11/780 (kind 23). 16 little-endian bytes, byte addressed; R0..R14 (R12 AP, R13 FP,
  ;; R14 SP) live in the register file at 64 + 4n, R15 is the PC at 22, the PSL condition codes
  ;; (N8 Z4 V2 C1) at 20. Every operand specifier: short literal, index, register, register
  ;; deferred, autodecrement, autoincrement (immediate), autoincrement deferred (absolute) and the
  ;; byte/word/longword displacement modes, deferred or not, PC relative included.
  (func $v_r (param $n i32) (result i32)
    (if (i32.eq (local.get $n) (i32.const 15)) (then (return (call $zr16 (i32.const 22)))))
    (call $zr32 (i32.add (i32.const 64) (i32.shl (local.get $n) (i32.const 2)))))
  (func $v_rw (param $n i32) (param $v i32)
    (if (i32.eq (local.get $n) (i32.const 15)) (then (call $zw16 (i32.const 22) (i32.and (local.get $v) (i32.const 0xffff))))
    (else (call $zw32 (i32.add (i32.const 64) (i32.shl (local.get $n) (i32.const 2))) (local.get $v)))))
  (func $v_fetch32 (result i32) (local $v i32) (local.set $v (call $fetch16)) (i32.or (local.get $v) (i32.shl (call $fetch16) (i32.const 16))))
  (func $v_mrd (param $a i32) (param $sz i32) (result i32)
    (if (i32.eq (local.get $sz) (i32.const 1)) (then (return (call $mrd (local.get $a)))))
    (if (i32.eq (local.get $sz) (i32.const 2)) (then (return (call $mrd16le (local.get $a)))))
    (call $mrd32 (local.get $a)))
  (func $v_mwr (param $a i32) (param $sz i32) (param $v i32)
    (if (i32.eq (local.get $sz) (i32.const 1)) (then (call $mwr (local.get $a) (local.get $v)) (return)))
    (if (i32.eq (local.get $sz) (i32.const 2)) (then (call $mwr16le (local.get $a) (local.get $v)) (return)))
    (call $mwr32 (local.get $a) (local.get $v)))
  (func $v_mask (param $v i32) (param $sz i32) (result i32)
    (if (i32.eq (local.get $sz) (i32.const 1)) (then (return (i32.and (local.get $v) (i32.const 0xff)))))
    (if (i32.eq (local.get $sz) (i32.const 2)) (then (return (i32.and (local.get $v) (i32.const 0xffff)))))
    (local.get $v))
  (func $v_sx (param $v i32) (param $sz i32) (result i32)
    (if (i32.eq (local.get $sz) (i32.const 1)) (then (return (call $sext8 (local.get $v)))))
    (if (i32.eq (local.get $sz) (i32.const 2)) (then (return (call $sx (local.get $v) (i32.const 16)))))
    (local.get $v))
  (func $v_sign (param $sz i32) (result i32) (i32.shl (i32.const 1) (i32.sub (i32.shl (local.get $sz) (i32.const 3)) (i32.const 1))))
  ;; operand specifier -> tag: 0x30000 + literal, 0x10000 + n for Rn, else a 16-bit address
  (func $v_ea (param $sz i32) (result i32)
    (local $b i32) (local $m i32) (local $n i32) (local $a i32) (local $d i32)
    (local.set $b (call $fetch)) (local.set $m (i32.shr_u (local.get $b) (i32.const 4))) (local.set $n (i32.and (local.get $b) (i32.const 15)))
    (if (i32.lt_u (local.get $m) (i32.const 4)) (then (return (i32.or (i32.const 0x30000) (local.get $b)))))
    (if (i32.eq (local.get $m) (i32.const 4)) (then   ;; indexed: the base specifier follows
      (local.set $a (call $v_ea (local.get $sz)))
      (if (i32.ge_u (local.get $a) (i32.const 0x10000)) (then (local.set $a (i32.const 0))))
      (return (i32.and (i32.add (local.get $a) (i32.mul (call $v_r (local.get $n)) (local.get $sz))) (i32.const 0xffff)))))
    (if (i32.eq (local.get $m) (i32.const 5)) (then (return (i32.or (i32.const 0x10000) (local.get $n)))))
    (if (i32.eq (local.get $m) (i32.const 6)) (then (return (i32.and (call $v_r (local.get $n)) (i32.const 0xffff)))))
    (if (i32.eq (local.get $m) (i32.const 7)) (then
      (call $v_rw (local.get $n) (i32.sub (call $v_r (local.get $n)) (local.get $sz)))
      (return (i32.and (call $v_r (local.get $n)) (i32.const 0xffff)))))
    (if (i32.eq (local.get $m) (i32.const 8)) (then
      (local.set $a (call $v_r (local.get $n)))
      (call $v_rw (local.get $n) (i32.add (local.get $a) (local.get $sz)))
      (return (i32.and (local.get $a) (i32.const 0xffff)))))
    (if (i32.eq (local.get $m) (i32.const 9)) (then
      (local.set $a (call $v_r (local.get $n)))
      (call $v_rw (local.get $n) (i32.add (local.get $a) (i32.const 4)))
      (return (i32.and (call $mrd32 (local.get $a)) (i32.const 0xffff)))))
    (if (i32.lt_u (local.get $m) (i32.const 12)) (then (local.set $d (call $sext8 (call $fetch))))
    (else (if (i32.lt_u (local.get $m) (i32.const 14)) (then (local.set $d (call $sx (call $fetch16) (i32.const 16))))
    (else (local.set $d (call $v_fetch32))))))
    (local.set $a (i32.add (call $v_r (local.get $n)) (local.get $d)))
    (if (i32.and (local.get $m) (i32.const 1)) (then (local.set $a (call $mrd32 (local.get $a)))))
    (i32.and (local.get $a) (i32.const 0xffff)))
  (func $v_ld (param $t i32) (param $sz i32) (result i32)
    (if (i32.ge_u (local.get $t) (i32.const 0x30000)) (then (return (i32.and (local.get $t) (i32.const 63)))))
    (if (i32.ge_u (local.get $t) (i32.const 0x10000)) (then (return (call $v_mask (call $v_r (i32.and (local.get $t) (i32.const 15))) (local.get $sz)))))
    (call $v_mask (call $v_mrd (local.get $t) (local.get $sz)) (local.get $sz)))
  (func $v_st (param $t i32) (param $sz i32) (param $v i32)
    (local $n i32)
    (if (i32.ge_u (local.get $t) (i32.const 0x30000)) (then (return)))
    (if (i32.ge_u (local.get $t) (i32.const 0x10000)) (then
      (local.set $n (i32.and (local.get $t) (i32.const 15)))
      (if (i32.eq (local.get $sz) (i32.const 4)) (then (call $v_rw (local.get $n) (local.get $v)))
      (else (call $v_rw (local.get $n) (i32.or (i32.and (call $v_r (local.get $n)) (i32.xor (call $v_mask (i32.const -1) (local.get $sz)) (i32.const -1)))
                                                (call $v_mask (local.get $v) (local.get $sz))))))
      (return)))
    (call $v_mwr (local.get $t) (local.get $sz) (local.get $v)))
  (func $v_addr (param $t i32) (result i32)   ;; the address a specifier names (a register or literal gives its number)
    (i32.and (local.get $t) (i32.const 0xffff)))
  (func $v_psl (result i32) (call $zr (i32.const 20)))
  ;; N and Z from v (by size), V and C from the low two bits of vc
  (func $v_nz (param $v i32) (param $sz i32) (param $vc i32)
    (local $s i32)
    (local.set $s (call $v_sx (local.get $v) (local.get $sz)))
    (call $zw (i32.const 20) (i32.or (i32.or (select (i32.const 8) (i32.const 0) (i32.lt_s (local.get $s) (i32.const 0)))
                                             (select (i32.const 4) (i32.const 0) (i32.eqz (local.get $s))))
                                     (i32.and (local.get $vc) (i32.const 3)))))
  (func $v_nzk (param $v i32) (param $sz i32) (param $vbit i32)   ;; keeps C
    (call $v_nz (local.get $v) (local.get $sz) (i32.or (i32.and (call $v_psl) (i32.const 1)) (i32.and (local.get $vbit) (i32.const 2)))))
  (func $v_addf (param $a i32) (param $b i32) (param $cin i32) (param $sz i32) (result i32)
    (local $r i32) (local $c i32) (local $full i64)
    (local.set $full (i64.add (i64.add (i64.extend_i32_u (call $v_mask (local.get $a) (local.get $sz))) (i64.extend_i32_u (call $v_mask (local.get $b) (local.get $sz)))) (i64.extend_i32_u (local.get $cin))))
    (local.set $r (call $v_mask (i32.wrap_i64 (local.get $full)) (local.get $sz)))
    (local.set $c (i64.ne (i64.shr_u (local.get $full) (i64.extend_i32_u (i32.shl (local.get $sz) (i32.const 3)))) (i64.const 0)))
    (call $v_nz (local.get $r) (local.get $sz) (i32.or (local.get $c)
      (select (i32.const 2) (i32.const 0) (i32.and (i32.and (i32.xor (local.get $a) (local.get $r)) (i32.xor (local.get $b) (local.get $r))) (call $v_sign (local.get $sz))))))
    (local.get $r))
  (func $v_subf (param $a i32) (param $b i32) (param $bin i32) (param $sz i32) (result i32)   ;; a - b - bin, C = borrow
    (local $r i32) (local $full i64)
    (local.set $full (i64.sub (i64.sub (i64.extend_i32_u (call $v_mask (local.get $a) (local.get $sz))) (i64.extend_i32_u (call $v_mask (local.get $b) (local.get $sz)))) (i64.extend_i32_u (local.get $bin))))
    (local.set $r (call $v_mask (i32.wrap_i64 (local.get $full)) (local.get $sz)))
    (call $v_nz (local.get $r) (local.get $sz) (i32.or (i64.lt_s (local.get $full) (i64.const 0))
      (select (i32.const 2) (i32.const 0) (i32.and (i32.and (i32.xor (local.get $a) (local.get $b)) (i32.xor (local.get $a) (local.get $r))) (call $v_sign (local.get $sz))))))
    (local.get $r))
  (func $v_cmpf (param $a i32) (param $b i32) (param $sz i32)
    (drop (call $v_subf (local.get $a) (local.get $b) (i32.const 0) (local.get $sz)))
    (call $zw (i32.const 20) (i32.and (call $v_psl) (i32.const 13))))
  (func $v_mulf (param $a i32) (param $b i32) (param $sz i32) (result i32)
    (local $p i64) (local $r i32)
    (local.set $p (i64.mul (i64.extend_i32_s (call $v_sx (local.get $a) (local.get $sz))) (i64.extend_i32_s (call $v_sx (local.get $b) (local.get $sz)))))
    (local.set $r (call $v_mask (i32.wrap_i64 (local.get $p)) (local.get $sz)))
    (call $v_nz (local.get $r) (local.get $sz) (select (i32.const 2) (i32.const 0) (i64.ne (local.get $p) (i64.extend_i32_s (call $v_sx (local.get $r) (local.get $sz))))))
    (local.get $r))
  (func $v_divf (param $a i32) (param $b i32) (param $sz i32) (result i32)   ;; a / b; by zero: V set, a returned
    (local $q i64) (local $r i32)
    (local.set $b (call $v_sx (local.get $b) (local.get $sz))) (local.set $a (call $v_sx (local.get $a) (local.get $sz)))
    (if (i32.eqz (local.get $b)) (then (call $v_nz (local.get $a) (local.get $sz) (i32.const 2)) (return (call $v_mask (local.get $a) (local.get $sz)))))
    (local.set $q (i64.div_s (i64.extend_i32_s (local.get $a)) (i64.extend_i32_s (local.get $b))))
    (local.set $r (call $v_mask (i32.wrap_i64 (local.get $q)) (local.get $sz)))
    (call $v_nz (local.get $r) (local.get $sz) (select (i32.const 2) (i32.const 0) (i64.ne (local.get $q) (i64.extend_i32_s (call $v_sx (local.get $r) (local.get $sz))))))
    (local.get $r))
  (func $v_push (param $v i32)
    (call $v_rw (i32.const 14) (i32.sub (call $v_r (i32.const 14)) (i32.const 4)))
    (call $mwr32 (call $v_r (i32.const 14)) (local.get $v)))
  (func $v_pop (result i32)
    (local $v i32)
    (local.set $v (call $mrd32 (call $v_r (i32.const 14))))
    (call $v_rw (i32.const 14) (i32.add (call $v_r (i32.const 14)) (i32.const 4)))
    (local.get $v))
  (func $v_br (param $d i32) (call $zw16 (i32.const 22) (i32.and (i32.add (call $zr16 (i32.const 22)) (local.get $d)) (i32.const 0xffff))))
  (func $v_cond (param $c i32) (result i32)   ;; branch conditions by the low opcode nibble
    (local $p i32) (local $n i32) (local $z i32) (local $v i32) (local $cy i32)
    (local.set $p (call $v_psl))
    (local.set $n (i32.and (i32.shr_u (local.get $p) (i32.const 3)) (i32.const 1))) (local.set $z (i32.and (i32.shr_u (local.get $p) (i32.const 2)) (i32.const 1)))
    (local.set $v (i32.and (i32.shr_u (local.get $p) (i32.const 1)) (i32.const 1))) (local.set $cy (i32.and (local.get $p) (i32.const 1)))
    (if (i32.lt_u (local.get $c) (i32.const 4)) (then (return (i32.eq (local.get $z) (i32.and (local.get $c) (i32.const 1))))))   ;; 2 BNEQ 3 BEQL
    (if (i32.lt_u (local.get $c) (i32.const 6)) (then (return (i32.eq (i32.or (local.get $n) (local.get $z)) (i32.and (local.get $c) (i32.const 1))))))   ;; 4 BGTR 5 BLEQ
    (if (i32.lt_u (local.get $c) (i32.const 10)) (then (return (i32.eq (local.get $n) (i32.and (local.get $c) (i32.const 1))))))   ;; 8 BGEQ 9 BLSS
    (if (i32.lt_u (local.get $c) (i32.const 12)) (then (return (i32.eq (i32.or (local.get $cy) (local.get $z)) (i32.and (local.get $c) (i32.const 1))))))   ;; A BGTRU B BLEQU
    (if (i32.lt_u (local.get $c) (i32.const 14)) (then (return (i32.eq (local.get $v) (i32.and (local.get $c) (i32.const 1))))))   ;; C BVC D BVS
    (i32.eq (local.get $cy) (i32.and (local.get $c) (i32.const 1))))   ;; E BGEQU F BLSSU
  ;; bit fields: base tag t (register or address), bit position pos, size bits -> zero-extended value
  (func $v_fld (param $t i32) (param $pos i32) (param $size i32) (result i32)
    (local $v i64) (local $a i32) (local $i i32)
    (if (i32.eqz (local.get $size)) (then (return (i32.const 0))))
    (if (i32.ge_u (local.get $t) (i32.const 0x10000)) (then
      (return (i32.and (i32.shr_u (call $v_r (i32.and (local.get $t) (i32.const 15))) (i32.and (local.get $pos) (i32.const 31))) (call $v_mask32 (local.get $size))))))
    (local.set $a (i32.add (local.get $t) (i32.shr_s (local.get $pos) (i32.const 3))))
    (block $e (loop $l (br_if $e (i32.ge_u (local.get $i) (i32.const 5)))
      (local.set $v (i64.or (local.get $v) (i64.shl (i64.extend_i32_u (call $mrd (i32.add (local.get $a) (local.get $i)))) (i64.extend_i32_u (i32.shl (local.get $i) (i32.const 3))))))
      (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $l)))
    (i32.and (i32.wrap_i64 (i64.shr_u (local.get $v) (i64.extend_i32_u (i32.and (local.get $pos) (i32.const 7))))) (call $v_mask32 (local.get $size))))
  (func $v_mask32 (param $size i32) (result i32)
    (if (i32.ge_u (local.get $size) (i32.const 32)) (then (return (i32.const -1))))
    (i32.sub (i32.shl (i32.const 1) (local.get $size)) (i32.const 1)))
  (func $v_setbit (param $t i32) (param $pos i32) (param $bit i32)
    (local $a i32) (local $n i32) (local $m i32)
    (if (i32.ge_u (local.get $t) (i32.const 0x10000)) (then
      (local.set $n (i32.and (local.get $t) (i32.const 15))) (local.set $m (i32.shl (i32.const 1) (i32.and (local.get $pos) (i32.const 31))))
      (call $v_rw (local.get $n) (select (i32.or (call $v_r (local.get $n)) (local.get $m)) (i32.and (call $v_r (local.get $n)) (i32.xor (local.get $m) (i32.const -1))) (local.get $bit)))
      (return)))
    (local.set $a (i32.add (local.get $t) (i32.shr_s (local.get $pos) (i32.const 3)))) (local.set $m (i32.shl (i32.const 1) (i32.and (local.get $pos) (i32.const 7))))
    (call $mwr (local.get $a) (select (i32.or (call $mrd (local.get $a)) (local.get $m)) (i32.and (call $mrd (local.get $a)) (i32.xor (local.get $m) (i32.const -1))) (local.get $bit))))
  (func $v_insv (param $t i32) (param $pos i32) (param $size i32) (param $src i32)
    (local $i i32)
    (block $e (loop $l (br_if $e (i32.ge_u (local.get $i) (local.get $size))) (br_if $e (i32.ge_u (local.get $i) (i32.const 32)))
      (call $v_setbit (local.get $t) (i32.add (local.get $pos) (local.get $i)) (i32.and (i32.shr_u (local.get $src) (local.get $i)) (i32.const 1)))
      (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $l))))
  ;; the two-operand / three-operand arithmetic group: lo = low five opcode bits, 0..13
  (func $v_arith (param $lo i32) (param $sz i32)
    (local $s i32) (local $d i32) (local $t i32) (local $kind i32) (local $r i32)
    (local.set $kind (i32.shr_u (local.get $lo) (i32.const 1)))
    (local.set $s (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)))
    (local.set $t (call $v_ea (local.get $sz))) (local.set $d (call $v_ld (local.get $t) (local.get $sz)))
    (if (i32.and (local.get $lo) (i32.const 1)) (then (local.set $t (call $v_ea (local.get $sz)))))
    (if (i32.eqz (local.get $kind)) (then (local.set $r (call $v_addf (local.get $d) (local.get $s) (i32.const 0) (local.get $sz)))) (else
    (if (i32.eq (local.get $kind) (i32.const 1)) (then (local.set $r (call $v_subf (local.get $d) (local.get $s) (i32.const 0) (local.get $sz)))) (else
    (if (i32.eq (local.get $kind) (i32.const 2)) (then (local.set $r (call $v_mulf (local.get $d) (local.get $s) (local.get $sz)))) (else
    (if (i32.eq (local.get $kind) (i32.const 3)) (then (local.set $r (call $v_divf (local.get $d) (local.get $s) (local.get $sz)))) (else
      (local.set $r (call $v_mask (select (i32.or (local.get $d) (local.get $s)) (select (i32.and (local.get $d) (i32.xor (local.get $s) (i32.const -1))) (i32.xor (local.get $d) (local.get $s)) (i32.eq (local.get $kind) (i32.const 5))) (i32.eq (local.get $kind) (i32.const 4))) (local.get $sz)))
      (call $v_nzk (local.get $r) (local.get $sz) (i32.const 0))))))))))
    (call $v_st (local.get $t) (local.get $sz) (local.get $r)))
  (func $v_acb (param $sz i32)   ;; ACBx limit.rx add.rx index.mx displ.bw
    (local $lim i32) (local $add i32) (local $t i32) (local $idx i32) (local $d i32)
    (local.set $lim (call $v_sx (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)) (local.get $sz)))
    (local.set $add (call $v_sx (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)) (local.get $sz)))
    (local.set $t (call $v_ea (local.get $sz)))
    (local.set $idx (call $v_addf (call $v_ld (local.get $t) (local.get $sz)) (local.get $add) (i32.const 0) (local.get $sz)))
    (call $zw (i32.const 20) (i32.and (call $v_psl) (i32.const 14)))
    (call $v_st (local.get $t) (local.get $sz) (local.get $idx))
    (local.set $idx (call $v_sx (local.get $idx) (local.get $sz)))
    (local.set $d (call $sx (call $fetch16) (i32.const 16)))
    (if (select (i32.le_s (local.get $idx) (local.get $lim)) (i32.ge_s (local.get $idx) (local.get $lim)) (i32.ge_s (local.get $add) (i32.const 0))) (then (call $v_br (local.get $d)))))
  (func $v_case (param $sz i32)
    (local $sel i32) (local $base i32) (local $lim i32) (local $tmp i32) (local $tab i32)
    (local.set $sel (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)))
    (local.set $base (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)))
    (local.set $lim (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)))
    (local.set $tmp (call $v_mask (i32.sub (local.get $sel) (local.get $base)) (local.get $sz)))
    (call $v_cmpf (local.get $tmp) (local.get $lim) (local.get $sz))
    (local.set $tab (call $zr16 (i32.const 22)))
    (if (i32.le_u (local.get $tmp) (local.get $lim))
      (then (call $v_br (call $sx (call $mrd16le (i32.add (local.get $tab) (i32.shl (local.get $tmp) (i32.const 1)))) (i32.const 16))))
      (else (call $v_br (i32.shl (i32.add (local.get $lim) (i32.const 1)) (i32.const 1))))))
  (func $v_quad (param $t i32) (param $hi i32) (result i32)   ;; one longword of a quadword operand
    (if (i32.ge_u (local.get $t) (i32.const 0x30000)) (then (return (select (i32.const 0) (i32.and (local.get $t) (i32.const 63)) (local.get $hi)))))
    (if (i32.ge_u (local.get $t) (i32.const 0x10000)) (then (return (call $v_r (i32.and (i32.add (local.get $t) (local.get $hi)) (i32.const 15))))))
    (call $mrd32 (i32.add (local.get $t) (i32.shl (local.get $hi) (i32.const 2)))))
  (func $v_quadw (param $t i32) (param $hi i32) (param $v i32)
    (if (i32.ge_u (local.get $t) (i32.const 0x30000)) (then (return)))
    (if (i32.ge_u (local.get $t) (i32.const 0x10000)) (then (call $v_rw (i32.and (i32.add (local.get $t) (local.get $hi)) (i32.const 15)) (local.get $v)) (return)))
    (call $mwr32 (i32.add (local.get $t) (i32.shl (local.get $hi) (i32.const 2))) (local.get $v)))
  (func $vax_step
    (local $op i32) (local $sz i32) (local $lo i32) (local $s i32) (local $d i32) (local $t i32) (local $r i32) (local $i i32) (local $pos i32) (local $size i32) (local $want i32)
    (local.set $op (call $fetch))
    (block $end
      (if (i32.and (i32.ge_u (local.get $op) (i32.const 0x80)) (i32.le_u (local.get $op) (i32.const 0xdf))) (then
        (local.set $sz (i32.shl (i32.const 1) (i32.sub (i32.shr_u (local.get $op) (i32.const 5)) (i32.const 4))))
        (local.set $lo (i32.and (local.get $op) (i32.const 0x1f)))
        (if (i32.lt_u (local.get $lo) (i32.const 0x0e)) (then (call $v_arith (local.get $lo) (local.get $sz)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x0e)) (then   ;; MNEG
          (local.set $s (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)))
          (call $v_st (call $v_ea (local.get $sz)) (local.get $sz) (call $v_subf (i32.const 0) (local.get $s) (i32.const 0) (local.get $sz))) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x0f)) (then (call $v_case (local.get $sz)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x10)) (then   ;; MOV
          (local.set $s (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)))
          (call $v_st (call $v_ea (local.get $sz)) (local.get $sz) (local.get $s)) (call $v_nzk (local.get $s) (local.get $sz) (i32.const 0)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x11)) (then   ;; CMP
          (local.set $s (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)))
          (call $v_cmpf (local.get $s) (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)) (local.get $sz)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x12)) (then   ;; MCOM
          (local.set $s (call $v_mask (i32.xor (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)) (i32.const -1)) (local.get $sz)))
          (call $v_st (call $v_ea (local.get $sz)) (local.get $sz) (local.get $s)) (call $v_nzk (local.get $s) (local.get $sz) (i32.const 0)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x13)) (then   ;; BIT
          (local.set $s (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)))
          (call $v_nzk (i32.and (local.get $s) (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz))) (local.get $sz) (i32.const 0)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x14)) (then   ;; CLR
          (call $v_st (call $v_ea (local.get $sz)) (local.get $sz) (i32.const 0)) (call $v_nzk (i32.const 0) (local.get $sz) (i32.const 0)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x15)) (then   ;; TST
          (call $v_nz (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)) (local.get $sz) (i32.const 0)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x16)) (then   ;; INC
          (local.set $t (call $v_ea (local.get $sz)))
          (call $v_st (local.get $t) (local.get $sz) (call $v_addf (call $v_ld (local.get $t) (local.get $sz)) (i32.const 1) (i32.const 0) (local.get $sz))) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x17)) (then   ;; DEC
          (local.set $t (call $v_ea (local.get $sz)))
          (call $v_st (local.get $t) (local.get $sz) (call $v_subf (call $v_ld (local.get $t) (local.get $sz)) (i32.const 1) (i32.const 0) (local.get $sz))) (br $end)))
        (if (i32.eq (local.get $sz) (i32.const 1)) (then   ;; 98 CVTBL 99 CVTBW 9A MOVZBL 9B MOVZBW 9C ROTL 9D ACBB 9E MOVAB 9F PUSHAB
          (if (i32.lt_u (local.get $lo) (i32.const 0x1c)) (then
            (local.set $s (call $v_ld (call $v_ea (i32.const 1)) (i32.const 1)))
            (if (i32.lt_u (local.get $lo) (i32.const 0x1a)) (then (local.set $s (call $sext8 (local.get $s)))))
            (local.set $sz (select (i32.const 4) (i32.const 2) (i32.eqz (i32.and (local.get $lo) (i32.const 1)))))
            (call $v_st (call $v_ea (local.get $sz)) (local.get $sz) (local.get $s))
            (if (i32.lt_u (local.get $lo) (i32.const 0x1a)) (then (call $v_nz (local.get $s) (local.get $sz) (i32.const 0))) (else (call $v_nzk (local.get $s) (local.get $sz) (i32.const 0))))
            (br $end)))
          (if (i32.eq (local.get $lo) (i32.const 0x1c)) (then
            (local.set $s (call $sext8 (call $v_ld (call $v_ea (i32.const 1)) (i32.const 1))))
            (local.set $r (i32.rotl (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4)) (local.get $s)))
            (call $v_st (call $v_ea (i32.const 4)) (i32.const 4) (local.get $r)) (call $v_nzk (local.get $r) (i32.const 4) (i32.const 0)) (br $end)))
          (if (i32.eq (local.get $lo) (i32.const 0x1d)) (then (call $v_acb (i32.const 1)) (br $end)))
          (local.set $sz (i32.const 1))))
        (if (i32.eq (local.get $sz) (i32.const 2)) (then   ;; B8 BISPSW B9 BICPSW BA POPR BB PUSHR BC..BF CHMx
          (if (i32.lt_u (local.get $lo) (i32.const 0x1a)) (then
            (local.set $s (i32.and (call $v_ld (call $v_ea (i32.const 2)) (i32.const 2)) (i32.const 15)))
            (call $zw (i32.const 20) (select (i32.or (call $v_psl) (local.get $s)) (i32.and (call $v_psl) (i32.xor (local.get $s) (i32.const -1))) (i32.eq (local.get $lo) (i32.const 0x18))))
            (br $end)))
          (if (i32.eq (local.get $lo) (i32.const 0x1a)) (then
            (local.set $s (call $v_ld (call $v_ea (i32.const 2)) (i32.const 2)))
            (block $e (loop $l (br_if $e (i32.ge_u (local.get $i) (i32.const 15)))
              (if (i32.and (i32.shr_u (local.get $s) (local.get $i)) (i32.const 1)) (then (call $v_rw (local.get $i) (call $v_pop))))
              (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $l)))
            (br $end)))
          (if (i32.eq (local.get $lo) (i32.const 0x1b)) (then
            (local.set $s (call $v_ld (call $v_ea (i32.const 2)) (i32.const 2))) (local.set $i (i32.const 15))
            (block $e (loop $l (br_if $e (i32.eqz (local.get $i)))
              (local.set $i (i32.sub (local.get $i) (i32.const 1)))
              (if (i32.and (i32.shr_u (local.get $s) (local.get $i)) (i32.const 1)) (then (call $v_push (call $v_r (local.get $i)))))
              (br $l)))
            (br $end)))
          (drop (call $v_ld (call $v_ea (i32.const 2)) (i32.const 2))) (br $end)))
        ;; D8 ADWC D9 SBWC DA MTPR DB MFPR DC MOVPSL DD PUSHL DE MOVAL DF PUSHAL
        (if (i32.lt_u (local.get $lo) (i32.const 0x1a)) (then
          (local.set $s (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4))) (local.set $t (call $v_ea (i32.const 4)))
          (local.set $r (select (call $v_addf (call $v_ld (local.get $t) (i32.const 4)) (local.get $s) (i32.and (call $v_psl) (i32.const 1)) (i32.const 4))
                                (call $v_subf (call $v_ld (local.get $t) (i32.const 4)) (local.get $s) (i32.and (call $v_psl) (i32.const 1)) (i32.const 4))
                                (i32.eq (local.get $lo) (i32.const 0x18))))
          (call $v_st (local.get $t) (i32.const 4) (local.get $r)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x1a)) (then (drop (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4))) (drop (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4))) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x1b)) (then (drop (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4))) (call $v_st (call $v_ea (i32.const 4)) (i32.const 4) (i32.const 0)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x1c)) (then (call $v_st (call $v_ea (i32.const 4)) (i32.const 4) (call $v_psl)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x1d)) (then
          (local.set $s (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4))) (call $v_push (local.get $s)) (call $v_nzk (local.get $s) (i32.const 4) (i32.const 0)) (br $end)))
        (local.set $sz (i32.const 4))))
      ;; MOVAx / PUSHAx: 9E 9F (byte), 3E 3F (word), DE DF (long), 7E 7F (quad)
      (if (i32.eq (i32.and (local.get $op) (i32.const 0xfe)) (i32.const 0x9e)) (then (local.set $i (i32.const 1))))
      (if (i32.eq (i32.and (local.get $op) (i32.const 0xfe)) (i32.const 0x3e)) (then (local.set $i (i32.const 2))))
      (if (i32.eq (i32.and (local.get $op) (i32.const 0xfe)) (i32.const 0xde)) (then (local.set $i (i32.const 4))))
      (if (i32.eq (i32.and (local.get $op) (i32.const 0xfe)) (i32.const 0x7e)) (then (local.set $i (i32.const 8))))
      (if (local.get $i) (then
        (local.set $s (call $v_addr (call $v_ea (local.get $i))))
        (if (i32.and (local.get $op) (i32.const 1)) (then (call $v_push (local.get $s))) (else (call $v_st (call $v_ea (i32.const 4)) (i32.const 4) (local.get $s))))
        (call $v_nzk (local.get $s) (i32.const 4) (i32.const 0)) (br $end)))
      (if (i32.eq (i32.shr_u (local.get $op) (i32.const 4)) (i32.const 1)) (then   ;; 10 BSBB 11 BRB 12..1F Bcc, 16 JSB, 17 JMP
        (if (i32.eq (local.get $op) (i32.const 0x16)) (then (local.set $s (call $v_addr (call $v_ea (i32.const 1)))) (call $v_push (call $zr16 (i32.const 22))) (call $zw16 (i32.const 22) (local.get $s)) (br $end)))
        (if (i32.eq (local.get $op) (i32.const 0x17)) (then (call $zw16 (i32.const 22) (call $v_addr (call $v_ea (i32.const 1)))) (br $end)))
        (local.set $d (call $sext8 (call $fetch)))
        (if (i32.eq (local.get $op) (i32.const 0x10)) (then (call $v_push (call $zr16 (i32.const 22))) (call $v_br (local.get $d)) (br $end)))
        (if (i32.eq (local.get $op) (i32.const 0x11)) (then (call $v_br (local.get $d)) (br $end)))
        (if (call $v_cond (i32.and (local.get $op) (i32.const 15))) (then (call $v_br (local.get $d))))
        (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x05)) (then (call $zw16 (i32.const 22) (i32.and (call $v_pop) (i32.const 0xffff))) (br $end)))   ;; RSB
      (if (i32.eq (local.get $op) (i32.const 0x04)) (then (call $zw16 (i32.const 22) (i32.and (call $v_pop) (i32.const 0xffff))) (br $end)))   ;; RET (no frame)
      (if (i32.lt_u (local.get $op) (i32.const 0x30)) (then (br $end)))   ;; HALT NOP REI BPT ... INDEX CRC PROBE INSQUE REMQUE, the 2x string group
      (if (i32.eq (local.get $op) (i32.const 0x30)) (then (local.set $d (call $sx (call $fetch16) (i32.const 16))) (call $v_push (call $zr16 (i32.const 22))) (call $v_br (local.get $d)) (br $end)))   ;; BSBW
      (if (i32.eq (local.get $op) (i32.const 0x31)) (then (call $v_br (call $sx (call $fetch16) (i32.const 16))) (br $end)))   ;; BRW
      (if (i32.or (i32.eq (local.get $op) (i32.const 0x32)) (i32.eq (local.get $op) (i32.const 0x33))) (then   ;; CVTWL CVTWB
        (local.set $s (call $sx (call $v_ld (call $v_ea (i32.const 2)) (i32.const 2)) (i32.const 16)))
        (local.set $sz (select (i32.const 4) (i32.const 1) (i32.eq (local.get $op) (i32.const 0x32))))
        (call $v_st (call $v_ea (local.get $sz)) (local.get $sz) (local.get $s))
        (call $v_nz (local.get $s) (local.get $sz) (select (i32.const 2) (i32.const 0) (i32.ne (local.get $s) (call $v_sx (local.get $s) (local.get $sz))))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x3c)) (then   ;; MOVZWL
        (local.set $s (call $v_ld (call $v_ea (i32.const 2)) (i32.const 2))) (call $v_st (call $v_ea (i32.const 4)) (i32.const 4) (local.get $s)) (call $v_nzk (local.get $s) (i32.const 4) (i32.const 0)) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x3d)) (then (call $v_acb (i32.const 2)) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x78)) (then   ;; ASHL cnt.rb src.rl dst.wl
        (local.set $s (call $sext8 (call $v_ld (call $v_ea (i32.const 1)) (i32.const 1))))
        (local.set $d (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4)))
        (if (i32.ge_s (local.get $s) (i32.const 0))
          (then (local.set $r (select (i32.const 0) (i32.shl (local.get $d) (local.get $s)) (i32.gt_u (local.get $s) (i32.const 31))))
                (local.set $i (i32.ne (select (i32.const 0) (i32.shr_s (local.get $r) (local.get $s)) (i32.gt_u (local.get $s) (i32.const 31))) (local.get $d))))
          (else (local.set $r (i32.shr_s (local.get $d) (select (i32.const 31) (i32.sub (i32.const 0) (local.get $s)) (i32.lt_s (local.get $s) (i32.const -31)))))))
        (call $v_st (call $v_ea (i32.const 4)) (i32.const 4) (local.get $r)) (call $v_nz (local.get $r) (i32.const 4) (i32.shl (local.get $i) (i32.const 1))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x7c)) (then   ;; CLRQ
        (local.set $t (call $v_ea (i32.const 8))) (call $v_quadw (local.get $t) (i32.const 0) (i32.const 0)) (call $v_quadw (local.get $t) (i32.const 1) (i32.const 0))
        (call $v_nzk (i32.const 0) (i32.const 4) (i32.const 0)) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x7d)) (then   ;; MOVQ
        (local.set $t (call $v_ea (i32.const 8))) (local.set $s (call $v_quad (local.get $t) (i32.const 0))) (local.set $d (call $v_quad (local.get $t) (i32.const 1)))
        (local.set $t (call $v_ea (i32.const 8))) (call $v_quadw (local.get $t) (i32.const 0) (local.get $s)) (call $v_quadw (local.get $t) (i32.const 1) (local.get $d))
        (call $v_nzk (i32.or (local.get $d) (i32.ne (local.get $s) (i32.const 0))) (i32.const 4) (i32.const 0)) (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0xe0)) (then (br $end)))   ;; floating point, EMUL/EDIV/ASHQ, packed decimal: NOPs
      (if (i32.lt_u (local.get $op) (i32.const 0xe8)) (then   ;; E0 BBS E1 BBC E2 BBSS E3 BBCS E4 BBSC E5 BBCC E6 BBSSI E7 BBCCI
        (local.set $pos (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4))) (local.set $t (call $v_ea (i32.const 1)))
        (local.set $s (call $v_fld (local.get $t) (local.get $pos) (i32.const 1)))
        (local.set $d (call $sext8 (call $fetch)))
        (if (i32.ge_u (local.get $op) (i32.const 0xe2)) (then
          (call $v_setbit (local.get $t) (local.get $pos) (i32.or (i32.eq (local.get $op) (i32.const 0xe2)) (i32.or (i32.eq (local.get $op) (i32.const 0xe3)) (i32.eq (local.get $op) (i32.const 0xe6)))))))
        (if (i32.eq (local.get $s) (i32.eqz (i32.and (local.get $op) (i32.const 1)))) (then (call $v_br (local.get $d))))
        (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0xea)) (then   ;; E8 BLBS E9 BLBC
        (local.set $s (i32.and (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4)) (i32.const 1))) (local.set $d (call $sext8 (call $fetch)))
        (if (i32.eq (local.get $s) (i32.eqz (i32.and (local.get $op) (i32.const 1)))) (then (call $v_br (local.get $d))))
        (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0xf1)) (then   ;; EA FFS EB FFC EC CMPV ED CMPZV EE EXTV EF EXTZV F0 INSV
        (if (i32.eq (local.get $op) (i32.const 0xf0)) (then (local.set $want (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4)))))
        (local.set $pos (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4))) (local.set $size (i32.and (call $v_ld (call $v_ea (i32.const 1)) (i32.const 1)) (i32.const 63)))
        (local.set $t (call $v_ea (i32.const 1)))
        (if (i32.eq (local.get $op) (i32.const 0xf0)) (then (call $v_insv (local.get $t) (local.get $pos) (local.get $size) (local.get $want)) (br $end)))
        (local.set $s (call $v_fld (local.get $t) (local.get $pos) (local.get $size)))
        (if (i32.and (i32.eqz (i32.and (local.get $op) (i32.const 1))) (i32.ge_u (local.get $op) (i32.const 0xec))) (then   ;; signed field for CMPV / EXTV
          (if (i32.and (local.get $size) (i32.const 31)) (then (if (i32.lt_u (local.get $size) (i32.const 32)) (then (local.set $s (call $sx (local.get $s) (local.get $size)))))))))
        (if (i32.lt_u (local.get $op) (i32.const 0xec)) (then   ;; find first set/clear bit in the field
          (local.set $i (i32.const 0))
          (block $e (loop $l (br_if $e (i32.ge_u (local.get $i) (local.get $size)))
            (br_if $e (i32.eq (i32.and (i32.shr_u (local.get $s) (local.get $i)) (i32.const 1)) (i32.eqz (i32.and (local.get $op) (i32.const 1)))))
            (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $l)))
          (call $v_st (call $v_ea (i32.const 4)) (i32.const 4) (i32.add (local.get $pos) (local.get $i)))
          (call $zw (i32.const 20) (select (i32.const 4) (i32.const 0) (i32.ge_u (local.get $i) (local.get $size)))) (br $end)))
        (if (i32.lt_u (local.get $op) (i32.const 0xee)) (then (call $v_cmpf (local.get $s) (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4)) (i32.const 4)) (br $end)))
        (call $v_st (call $v_ea (i32.const 4)) (i32.const 4) (local.get $s)) (call $v_nzk (local.get $s) (i32.const 4) (i32.const 0)) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0xf1)) (then (call $v_acb (i32.const 4)) (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0xf4)) (then   ;; F2 AOBLSS F3 AOBLEQ limit.rl index.ml displ.bb
        (local.set $s (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4))) (local.set $t (call $v_ea (i32.const 4)))
        (local.set $r (call $v_addf (call $v_ld (local.get $t) (i32.const 4)) (i32.const 1) (i32.const 0) (i32.const 4)))
        (call $v_st (local.get $t) (i32.const 4) (local.get $r)) (local.set $d (call $sext8 (call $fetch)))
        (if (select (i32.le_s (local.get $r) (local.get $s)) (i32.lt_s (local.get $r) (local.get $s)) (i32.and (local.get $op) (i32.const 1))) (then (call $v_br (local.get $d))))
        (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0xf6)) (then   ;; F4 SOBGEQ F5 SOBGTR index.ml displ.bb
        (local.set $t (call $v_ea (i32.const 4)))
        (local.set $r (call $v_subf (call $v_ld (local.get $t) (i32.const 4)) (i32.const 1) (i32.const 0) (i32.const 4)))
        (call $v_st (local.get $t) (i32.const 4) (local.get $r)) (local.set $d (call $sext8 (call $fetch)))
        (if (select (i32.gt_s (local.get $r) (i32.const 0)) (i32.ge_s (local.get $r) (i32.const 0)) (i32.and (local.get $op) (i32.const 1))) (then (call $v_br (local.get $d))))
        (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0xf8)) (then   ;; F6 CVTLB F7 CVTLW
        (local.set $s (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4)))
        (local.set $sz (select (i32.const 1) (i32.const 2) (i32.eq (local.get $op) (i32.const 0xf6))))
        (call $v_st (call $v_ea (local.get $sz)) (local.get $sz) (local.get $s))
        (call $v_nz (local.get $s) (local.get $sz) (select (i32.const 2) (i32.const 0) (i32.ne (local.get $s) (call $v_sx (local.get $s) (local.get $sz))))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0xfa)) (then   ;; CALLG arglist.ab dst.ab: push the list address and the PC, no frame
        (local.set $s (call $v_addr (call $v_ea (i32.const 1)))) (local.set $d (call $v_addr (call $v_ea (i32.const 1))))
        (call $v_push (local.get $s)) (call $v_push (call $zr16 (i32.const 22))) (call $zw16 (i32.const 22) (local.get $d)) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0xfb)) (then   ;; CALLS numarg.rl dst.ab
        (local.set $s (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4))) (local.set $d (call $v_addr (call $v_ea (i32.const 1))))
        (call $v_push (local.get $s)) (call $v_push (call $zr16 (i32.const 22))) (call $zw16 (i32.const 22) (local.get $d)) (br $end)))))
