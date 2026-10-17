  ;; Intel i860 (kind 29). 32-bit little-endian instructions, four of them in a 16-byte cell (eight in a pair).
  ;; Register file: integer r1..r15 as i32 at offset 64 + 4(n - 1) (r0 reads as zero and swallows writes; field
  ;; values 16..31 alias 0..15), floating-point f2..f15 at i_f(n) (f0 and f1 read as zero; 16..31 alias 0..15; a
  ;; double occupies the pair fn, fn+1 with the low word in fn), CC in bit 0 and LCC in bit 1 of byte 20, PC
  ;; (byte address) at 22, the pending delayed branch in byte 21 with its target at 60, the shift count SC at 62.
  ;; The core integer set: ld.b/.s/.l, st.b/.s/.l, addu adds subu subs, shl shr shra shrd, and andh andnot andnoth
  ;; or orh xor xorh, bte btne, br call bri calli, bc bnc with their .t forms, bla, ixfr fxfr, fld.l/.d fst.l/.d,
  ;; and the scalar floating-point core (fadd fsub fmul famov fix ftrunc frcp frsqr pfgt pfeq fiadd fisub in single
  ;; or double; the pipelined forms run as their scalar equivalents, the dual-operation forms are NOPs).
  ;; Delayed branches execute the following instruction first (bc.t/bnc.t skip it when not taken). ld.c returns
  ;; the psr with CC; st.c, flush, trap, intovr, lock/unlock, pfld and pst.d are NOPs.
  (func $i_r (param $n i32) (result i32)
    (if (result i32) (i32.and (local.get $n) (i32.const 15)) (then (i32.load offset=316 (i32.shl (i32.and (local.get $n) (i32.const 15)) (i32.const 2)))) (else (i32.const 0))))
  (func $i_w (param $n i32) (param $v i32)
    (if (i32.and (local.get $n) (i32.const 15)) (then (i32.store offset=316 (i32.shl (i32.and (local.get $n) (i32.const 15)) (i32.const 2)) (local.get $v)))))
  (func $i_foff (param $n i32) (result i32)   ;; register-file offset of fn (n = 2..15), -1 for f0/f1
    (local.set $n (i32.and (local.get $n) (i32.const 15)))
    (if (i32.lt_u (local.get $n) (i32.const 2)) (then (return (i32.const -1))))
    (if (i32.le_u (local.get $n) (i32.const 6)) (then (return (i32.shl (i32.sub (local.get $n) (i32.const 2)) (i32.const 2)))))
    (i32.add (i32.const 24) (i32.shl (i32.sub (local.get $n) (i32.const 7)) (i32.const 2))))
  (func $i_f (param $n i32) (result i32) (local $o i32) (local.set $o (call $i_foff (local.get $n))) (if (result i32) (i32.lt_s (local.get $o) (i32.const 0)) (then (i32.const 0)) (else (call $zr32 (local.get $o)))))
  (func $i_fw (param $n i32) (param $v i32) (local $o i32) (local.set $o (call $i_foff (local.get $n))) (if (i32.ge_s (local.get $o) (i32.const 0)) (then (call $zw32 (local.get $o) (local.get $v)))))
  (func $i_fd (param $n i32) (result f64) (f64.reinterpret_i64 (i64.or (i64.extend_i32_u (call $i_f (local.get $n))) (i64.shl (i64.extend_i32_u (call $i_f (i32.add (local.get $n) (i32.const 1)))) (i64.const 32)))))
  (func $i_fdw (param $n i32) (param $v f64) (local $b i64) (local.set $b (i64.reinterpret_f64 (local.get $v)))
    (call $i_fw (local.get $n) (i32.wrap_i64 (local.get $b))) (call $i_fw (i32.add (local.get $n) (i32.const 1)) (i32.wrap_i64 (i64.shr_u (local.get $b) (i64.const 32)))))
  (func $i_fsrc (param $n i32) (param $dbl i32) (result f64)   ;; an operand in double precision
    (if (result f64) (local.get $dbl) (then (call $i_fd (local.get $n))) (else (f64.promote_f32 (f32.reinterpret_i32 (call $i_f (local.get $n)))))))
  (func $i_fres (param $n i32) (param $dbl i32) (param $v f64)
    (if (local.get $dbl) (then (call $i_fdw (local.get $n) (local.get $v))) (else (call $i_fw (local.get $n) (i32.reinterpret_f32 (f32.demote_f64 (local.get $v)))))))
  (func $i_cc (param $v i32) (call $zw (i32.const 20) (i32.or (i32.and (call $zr (i32.const 20)) (i32.const 2)) (i32.ne (local.get $v) (i32.const 0)))))
  (func $i_sbroff (param $I i32) (result i32)   ;; split 16-bit branch offset: bits 20..16 high, 10..0 low, in words
    (call $sx (i32.or (i32.shl (i32.and (i32.shr_u (local.get $I) (i32.const 16)) (i32.const 31)) (i32.const 11)) (i32.and (local.get $I) (i32.const 0x7ff))) (i32.const 16)))
  (func $i_branch (param $target i32)   ;; a delayed branch: taken after the next instruction
    (call $zw (i32.const 21) (i32.const 1)) (call $zw16 (i32.const 60) (i32.and (local.get $target) (i32.const 0xffff))))
  (func $i860_step
    (local $I i32) (local $op i32) (local $s1 i32) (local $s2 i32) (local $d i32) (local $imm i32) (local $a i32) (local $b i32) (local $r i32) (local $pc i32) (local $pend i32) (local $sub i32) (local $sd i32) (local $rd i32) (local $x f64) (local $y f64)
    (local.set $pc (call $zr16 (i32.const 22))) (local.set $I (call $mrd32 (local.get $pc)))
    (local.set $pc (i32.and (i32.add (local.get $pc) (i32.const 4)) (i32.const 0xffff))) (call $zw16 (i32.const 22) (local.get $pc))
    (local.set $pend (call $zr (i32.const 21))) (call $zw (i32.const 21) (i32.const 0))
    (local.set $op (i32.shr_u (local.get $I) (i32.const 26))) (local.set $s2 (i32.and (i32.shr_u (local.get $I) (i32.const 21)) (i32.const 31)))
    (local.set $d (i32.and (i32.shr_u (local.get $I) (i32.const 16)) (i32.const 31))) (local.set $s1 (i32.and (i32.shr_u (local.get $I) (i32.const 11)) (i32.const 31)))
    (local.set $imm (call $sx (local.get $I) (i32.const 16)))
    (local.set $a (select (local.get $imm) (call $i_r (local.get $s1)) (i32.and (local.get $op) (i32.const 1))))   ;; src1 or the immediate for the odd opcodes
    (local.set $b (call $i_r (local.get $s2)))
    (block $end
      (if (i32.lt_u (local.get $op) (i32.const 0x10)) (then   ;; loads, stores, transfers
        (if (i32.le_u (local.get $op) (i32.const 1)) (then (call $i_w (local.get $d) (call $sext8 (call $mrd (i32.add (local.get $a) (local.get $b))))) (br $end)))   ;; ld.b
        (if (i32.eq (local.get $op) (i32.const 2)) (then (call $i_fw (local.get $d) (call $i_r (local.get $s1))) (br $end)))   ;; ixfr
        (if (i32.or (i32.eq (local.get $op) (i32.const 4)) (i32.eq (local.get $op) (i32.const 5))) (then   ;; ld.s / ld.l (bit 0 of the offset or instruction: 1 = .l)
          (local.set $r (i32.add (i32.and (local.get $a) (i32.const -2)) (local.get $b)))
          (if (i32.and (local.get $I) (i32.const 1)) (then (call $i_w (local.get $d) (call $mrd32 (local.get $r)))) (else (call $i_w (local.get $d) (call $sx (call $mrd16le (local.get $r)) (i32.const 16)))))
          (br $end)))
        (if (i32.or (i32.eq (local.get $op) (i32.const 3)) (i32.eq (local.get $op) (i32.const 7))) (then   ;; st.b / st.s / st.l with the split offset
          (local.set $imm (call $i_sbroff (local.get $I))) (local.set $r (i32.add (i32.and (local.get $imm) (i32.const -2)) (local.get $b)))
          (if (i32.eq (local.get $op) (i32.const 3)) (then (call $mwr (i32.add (local.get $imm) (local.get $b)) (call $i_r (local.get $s1))))
            (else (if (i32.and (local.get $I) (i32.const 1)) (then (call $mwr32 (local.get $r) (call $i_r (local.get $s1)))) (else (call $mwr16le (local.get $r) (call $i_r (local.get $s1)))))))
          (br $end)))
        (if (i32.or (i32.eq (local.get $op) (i32.const 8)) (i32.eq (local.get $op) (i32.const 9))) (then   ;; fld.l / fld.d (bit 0: 1 = .d)
          (local.set $r (i32.add (i32.and (local.get $a) (i32.const -4)) (local.get $b)))
          (call $i_fw (local.get $d) (call $mrd32 (local.get $r)))
          (if (i32.and (local.get $I) (i32.const 1)) (then (call $i_fw (i32.add (local.get $d) (i32.const 1)) (call $mrd32 (i32.add (local.get $r) (i32.const 4))))))
          (br $end)))
        (if (i32.or (i32.eq (local.get $op) (i32.const 10)) (i32.eq (local.get $op) (i32.const 11))) (then   ;; fst.l / fst.d
          (if (i32.and (local.get $op) (i32.const 1)) (then (local.set $a (call $i_sbroff (local.get $I)))))
          (local.set $r (i32.add (i32.and (local.get $a) (i32.const -4)) (local.get $b)))
          (call $mwr32 (local.get $r) (call $i_f (local.get $d)))
          (if (i32.and (local.get $I) (i32.const 1)) (then (call $mwr32 (i32.add (local.get $r) (i32.const 4)) (call $i_f (i32.add (local.get $d) (i32.const 1))))))
          (br $end)))
        (if (i32.eq (local.get $op) (i32.const 12)) (then (call $i_w (local.get $d) (i32.shl (i32.and (call $zr (i32.const 20)) (i32.const 1)) (i32.const 2))) (br $end)))   ;; ld.c: psr with CC in bit 2
        (br $end)))   ;; flush, st.c, pst.d
      (if (i32.lt_u (local.get $op) (i32.const 0x20)) (then   ;; branches and escapes
        (if (i32.eq (local.get $op) (i32.const 0x10)) (then (call $i_branch (i32.and (call $i_r (local.get $s1)) (i32.const -4))) (br $end)))   ;; bri
        (if (i32.eq (local.get $op) (i32.const 0x12)) (then (call $i_fpu (local.get $I)) (br $end)))
        (if (i32.eq (local.get $op) (i32.const 0x13)) (then   ;; core escape: calli (2); lock, unlock, intovr: NOPs
          (if (i32.eq (i32.and (local.get $I) (i32.const 31)) (i32.const 2)) (then (call $i_w (i32.const 1) (i32.add (local.get $pc) (i32.const 4))) (call $i_branch (i32.and (call $i_r (local.get $s1)) (i32.const -4)))))
          (br $end)))
        (if (i32.and (i32.ge_u (local.get $op) (i32.const 0x14)) (i32.le_u (local.get $op) (i32.const 0x17))) (then   ;; btne / bte (reg or 5-bit constant), no delay slot
          (local.set $a (select (local.get $s1) (call $i_r (local.get $s1)) (i32.and (local.get $op) (i32.const 1))))
          (if (i32.eq (i32.eq (local.get $a) (local.get $b)) (i32.ne (i32.and (local.get $op) (i32.const 2)) (i32.const 0)))
            (then (call $zw16 (i32.const 22) (i32.and (i32.add (local.get $pc) (i32.shl (call $i_sbroff (local.get $I)) (i32.const 2))) (i32.const 0xffff)))))
          (br $end)))
        (if (i32.eq (local.get $op) (i32.const 0x1a)) (then (call $i_branch (i32.add (local.get $pc) (i32.shl (call $sx (local.get $I) (i32.const 26)) (i32.const 2)))) (br $end)))   ;; br
        (if (i32.eq (local.get $op) (i32.const 0x1b)) (then (call $i_w (i32.const 1) (i32.add (local.get $pc) (i32.const 4))) (call $i_branch (i32.add (local.get $pc) (i32.shl (call $sx (local.get $I) (i32.const 26)) (i32.const 2)))) (br $end)))   ;; call
        (if (i32.ge_u (local.get $op) (i32.const 0x1c)) (then   ;; bc bc.t bnc bnc.t
          (local.set $r (i32.eq (i32.and (call $zr (i32.const 20)) (i32.const 1)) (i32.eqz (i32.and (local.get $op) (i32.const 2)))))   ;; taken?
          (if (local.get $r)
            (then (call $i_branch (i32.add (local.get $pc) (i32.shl (call $i_sbroff (local.get $I)) (i32.const 2)))))
            (else (if (i32.and (local.get $op) (i32.const 1)) (then (call $zw16 (i32.const 22) (i32.and (i32.add (local.get $pc) (i32.const 4)) (i32.const 0xffff)))))))   ;; .t forms skip the delay slot when not taken
          (br $end)))
        (br $end)))   ;; trap, pfld
      (if (i32.lt_u (local.get $op) (i32.const 0x30)) (then   ;; arithmetic and shifts
        (if (i32.eq (local.get $op) (i32.const 0x2d)) (then   ;; bla: LCC-temp = carry of src1 + src2; src2 += src1; branch (delayed) when LCC; LCC = LCC-temp
          (local.set $r (i32.add (local.get $a) (local.get $b))) (local.set $sd (i32.lt_u (local.get $r) (local.get $a)))
          (call $i_w (local.get $s2) (local.get $r))
          (if (i32.and (call $zr (i32.const 20)) (i32.const 2)) (then (call $i_branch (i32.add (local.get $pc) (i32.shl (call $i_sbroff (local.get $I)) (i32.const 2))))))
          (call $zw (i32.const 20) (i32.or (i32.and (call $zr (i32.const 20)) (i32.const 1)) (i32.shl (local.get $sd) (i32.const 1))))
          (br $end)))
        (if (i32.eq (local.get $op) (i32.const 0x2c)) (then (call $i_w (local.get $d) (i32.wrap_i64 (i64.shr_u (i64.or (i64.extend_i32_u (local.get $b)) (i64.shl (i64.extend_i32_u (local.get $a)) (i64.const 32))) (i64.extend_i32_u (i32.and (call $zr (i32.const 62)) (i32.const 31)))))) (br $end)))   ;; shrd: src1:src2 >> SC
        (local.set $sub (i32.shr_u (i32.and (local.get $op) (i32.const 15)) (i32.const 1)))   ;; 0 addu 1 subu 2 adds 3 subs 4 shl 5 shr 7 shra
        (if (i32.eqz (local.get $sub)) (then (local.set $r (i32.add (local.get $a) (local.get $b))) (call $i_cc (i32.lt_u (local.get $r) (local.get $a))) (call $i_w (local.get $d) (local.get $r)) (br $end)))
        (if (i32.eq (local.get $sub) (i32.const 1)) (then (call $i_cc (i32.ge_u (local.get $a) (local.get $b))) (call $i_w (local.get $d) (i32.sub (local.get $a) (local.get $b))) (br $end)))
        (if (i32.eq (local.get $sub) (i32.const 2)) (then (call $i_cc (i32.lt_s (local.get $b) (i32.sub (i32.const 0) (local.get $a)))) (call $i_w (local.get $d) (i32.add (local.get $a) (local.get $b))) (br $end)))
        (if (i32.eq (local.get $sub) (i32.const 3)) (then (call $i_cc (i32.gt_s (local.get $b) (local.get $a))) (call $i_w (local.get $d) (i32.sub (local.get $a) (local.get $b))) (br $end)))
        (if (i32.eq (local.get $sub) (i32.const 4)) (then (call $i_w (local.get $d) (i32.shl (local.get $b) (i32.and (local.get $a) (i32.const 31)))) (br $end)))
        (if (i32.eq (local.get $sub) (i32.const 5)) (then (call $zw (i32.const 62) (i32.and (local.get $a) (i32.const 31))) (call $i_w (local.get $d) (i32.shr_u (local.get $b) (i32.and (local.get $a) (i32.const 31)))) (br $end)))
        (if (i32.eq (local.get $sub) (i32.const 7)) (then (call $i_w (local.get $d) (i32.shr_s (local.get $b) (i32.and (local.get $a) (i32.const 31)))) (br $end)))
        (br $end)))
      ;; logical: and andh andnot andnoth or orh xor xorh; immediates zero-extended, the h forms shifted left 16; CC = result is zero
      (if (i32.and (local.get $op) (i32.const 1)) (then (local.set $a (i32.and (local.get $I) (i32.const 0xffff))) (if (i32.and (local.get $op) (i32.const 2)) (then (local.set $a (i32.shl (local.get $a) (i32.const 16)))))))
      (local.set $sub (i32.and (i32.shr_u (local.get $op) (i32.const 2)) (i32.const 3)))
      (if (i32.eqz (local.get $sub)) (then (local.set $r (i32.and (local.get $a) (local.get $b)))))
      (if (i32.eq (local.get $sub) (i32.const 1)) (then (local.set $r (i32.and (i32.xor (local.get $a) (i32.const -1)) (local.get $b)))))
      (if (i32.eq (local.get $sub) (i32.const 2)) (then (local.set $r (i32.or (local.get $a) (local.get $b)))))
      (if (i32.eq (local.get $sub) (i32.const 3)) (then (local.set $r (i32.xor (local.get $a) (local.get $b)))))
      (call $i_cc (i32.eqz (local.get $r))) (call $i_w (local.get $d) (local.get $r)))
    (if (local.get $pend) (then (call $zw16 (i32.const 22) (call $zr16 (i32.const 60))))))   ;; the delay slot has run: take the branch
  ;; the floating-point escape (opcode 12h): bits 6..0 the operation, 8 source double, 7 result double, 10 pipelined (ignored)
  (func $i_fpu (param $I i32)
    (local $sub i32) (local $s1 i32) (local $s2 i32) (local $d i32) (local $sd i32) (local $rd i32) (local $x f64) (local $y f64) (local $r f64)
    (local.set $sub (i32.and (local.get $I) (i32.const 0x7f))) (local.set $s2 (i32.and (i32.shr_u (local.get $I) (i32.const 21)) (i32.const 31)))
    (local.set $d (i32.and (i32.shr_u (local.get $I) (i32.const 16)) (i32.const 31))) (local.set $s1 (i32.and (i32.shr_u (local.get $I) (i32.const 11)) (i32.const 31)))
    (local.set $sd (i32.and (i32.shr_u (local.get $I) (i32.const 8)) (i32.const 1))) (local.set $rd (i32.and (i32.shr_u (local.get $I) (i32.const 7)) (i32.const 1)))
    (if (i32.eq (local.get $sub) (i32.const 0x40)) (then (call $i_w (local.get $d) (call $i_f (local.get $s1))) (return)))   ;; fxfr
    (if (i32.or (i32.eq (local.get $sub) (i32.const 0x49)) (i32.eq (local.get $sub) (i32.const 0x4d))) (then   ;; fiadd / fisub: integer arithmetic in the f registers
      (call $i_fw (local.get $d) (select (i32.add (call $i_f (local.get $s1)) (call $i_f (local.get $s2))) (i32.sub (call $i_f (local.get $s1)) (call $i_f (local.get $s2))) (i32.eq (local.get $sub) (i32.const 0x49)))) (return)))
    (local.set $x (call $i_fsrc (local.get $s1) (local.get $sd))) (local.set $y (call $i_fsrc (local.get $s2) (local.get $sd)))
    (if (i32.eq (local.get $sub) (i32.const 0x34)) (then (call $i_cc (f64.gt (local.get $x) (local.get $y))) (return)))   ;; pfgt
    (if (i32.eq (local.get $sub) (i32.const 0x35)) (then (call $i_cc (f64.eq (local.get $x) (local.get $y))) (return)))   ;; pfeq
    (if (i32.or (i32.eq (local.get $sub) (i32.const 0x32)) (i32.eq (local.get $sub) (i32.const 0x3a))) (then   ;; fix (round) / ftrunc to a 32-bit integer in fdest
      (local.set $r (select (f64.nearest (local.get $x)) (f64.trunc (local.get $x)) (i32.eq (local.get $sub) (i32.const 0x32))))
      (if (f64.ne (local.get $r) (local.get $r)) (then (local.set $r (f64.const 0))))
      (local.set $r (f64.max (f64.const -2147483648) (f64.min (f64.const 2147483647) (local.get $r))))
      (call $i_fw (local.get $d) (i32.trunc_f64_s (local.get $r))) (return)))
    (if (i32.eq (local.get $sub) (i32.const 0x20)) (then (local.set $r (f64.mul (local.get $x) (local.get $y))))
      (else (if (i32.eq (local.get $sub) (i32.const 0x30)) (then (local.set $r (f64.add (local.get $x) (local.get $y))))
      (else (if (i32.eq (local.get $sub) (i32.const 0x31)) (then (local.set $r (f64.sub (local.get $x) (local.get $y))))
      (else (if (i32.eq (local.get $sub) (i32.const 0x33)) (then (local.set $r (local.get $x)))   ;; famov
      (else (if (i32.eq (local.get $sub) (i32.const 0x22)) (then (local.set $r (f64.div (f64.const 1) (local.get $y))))   ;; frcp
      (else (if (i32.eq (local.get $sub) (i32.const 0x23)) (then (local.set $r (f64.div (f64.const 1) (f64.sqrt (local.get $y)))))   ;; frsqr
      (else (return)))))))))))))
    (call $i_fres (local.get $d) (local.get $rd) (local.get $r)))
