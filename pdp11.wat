  ;; ========================================================================
  ;; DEC PDP-11 (kind 20). Register file: R0..R6 as u16 at 0,2,..,12 (R6 = SP),
  ;; PSW at 20 (N 8, Z 4, V 2, C 1, T 16), PC (R7) at 22. The 16 bytes are the
  ;; whole address space (little-endian words, byte addressed, wrapping mod 16;
  ;; odd word addresses are allowed). All eight addressing modes incl. the PC
  ;; forms; the basic instruction set plus EIS (MUL DIV ASH ASHC), XOR, SOB,
  ;; SXT, MFPS/MTPS, JSR/RTS, RTI/RTT. HALT WAIT RESET BPT IOT EMT TRAP MARK
  ;; SPL and the MMU/floating-point groups are NOPs. Registers start at zero.
  (func $p11_r (param $n i32) (result i32) (call $zr16 (select (i32.const 22) (i32.shl (local.get $n) (i32.const 1)) (i32.eq (local.get $n) (i32.const 7)))))
  (func $p11_w (param $n i32) (param $v i32) (call $zw16 (select (i32.const 22) (i32.shl (local.get $n) (i32.const 1)) (i32.eq (local.get $n) (i32.const 7))) (i32.and (local.get $v) (i32.const 0xffff))))
  (func $p11_fetch (result i32) (local $pc i32)
    (local.set $pc (call $zr16 (i32.const 22))) (call $zw16 (i32.const 22) (i32.and (i32.add (local.get $pc) (i32.const 2)) (i32.const 0xffff))) (call $mrd16le (local.get $pc)))
  (func $p11_push (param $v i32) (call $p11_w (i32.const 6) (i32.sub (call $p11_r (i32.const 6)) (i32.const 2))) (call $mwr16le (call $p11_r (i32.const 6)) (local.get $v)))
  (func $p11_pop (result i32) (local $v i32) (local.set $v (call $mrd16le (call $p11_r (i32.const 6)))) (call $p11_w (i32.const 6) (i32.add (call $p11_r (i32.const 6)) (i32.const 2))) (local.get $v))
  (func $p11_mask (param $b i32) (result i32) (select (i32.const 0xff) (i32.const 0xffff) (local.get $b)))
  (func $p11_msb (param $b i32) (result i32) (select (i32.const 0x80) (i32.const 0x8000) (local.get $b)))
  ;; effective address: registers are reported as 0x10000 + n; auto-increment is 1 for byte operands except on SP and PC
  (func $p11_ea (param $spec i32) (param $b i32) (result i32)
    (local $m i32) (local $n i32) (local $inc i32) (local $v i32) (local $x i32)
    (local.set $m (i32.and (i32.shr_u (local.get $spec) (i32.const 3)) (i32.const 7))) (local.set $n (i32.and (local.get $spec) (i32.const 7)))
    (local.set $inc (select (i32.const 1) (i32.const 2) (i32.and (local.get $b) (i32.lt_u (local.get $n) (i32.const 6)))))
    (local.set $v (call $p11_r (local.get $n)))
    (if (i32.eqz (local.get $m)) (then (return (i32.add (i32.const 0x10000) (local.get $n)))))
    (if (i32.eq (local.get $m) (i32.const 1)) (then (return (local.get $v))))
    (if (i32.eq (local.get $m) (i32.const 2)) (then (call $p11_w (local.get $n) (i32.add (local.get $v) (local.get $inc))) (return (local.get $v))))
    (if (i32.eq (local.get $m) (i32.const 3)) (then (call $p11_w (local.get $n) (i32.add (local.get $v) (i32.const 2))) (return (call $mrd16le (local.get $v)))))
    (if (i32.eq (local.get $m) (i32.const 4)) (then (local.set $v (i32.and (i32.sub (local.get $v) (local.get $inc)) (i32.const 0xffff))) (call $p11_w (local.get $n) (local.get $v)) (return (local.get $v))))
    (if (i32.eq (local.get $m) (i32.const 5)) (then (local.set $v (i32.and (i32.sub (local.get $v) (i32.const 2)) (i32.const 0xffff))) (call $p11_w (local.get $n) (local.get $v)) (return (call $mrd16le (local.get $v)))))
    (local.set $x (call $p11_fetch)) (local.set $v (i32.and (i32.add (call $p11_r (local.get $n)) (local.get $x)) (i32.const 0xffff)))   ;; index: register read after the index word
    (if (i32.eq (local.get $m) (i32.const 6)) (then (return (local.get $v))))
    (call $mrd16le (local.get $v)))
  (func $p11_ld (param $ea i32) (param $b i32) (result i32)
    (if (i32.ge_u (local.get $ea) (i32.const 0x10000)) (then (return (i32.and (call $p11_r (i32.sub (local.get $ea) (i32.const 0x10000))) (call $p11_mask (local.get $b))))))
    (if (result i32) (local.get $b) (then (call $mrd (local.get $ea))) (else (call $mrd16le (local.get $ea)))))
  (func $p11_st (param $ea i32) (param $b i32) (param $v i32)
    (local $n i32)
    (if (i32.ge_u (local.get $ea) (i32.const 0x10000)) (then
      (local.set $n (i32.sub (local.get $ea) (i32.const 0x10000)))
      (call $p11_w (local.get $n) (select (i32.or (i32.and (call $p11_r (local.get $n)) (i32.const 0xff00)) (i32.and (local.get $v) (i32.const 0xff))) (local.get $v) (local.get $b)))
      (return)))
    (if (local.get $b) (then (call $mwr (local.get $ea) (i32.and (local.get $v) (i32.const 255)))) (else (call $mwr16le (local.get $ea) (local.get $v)))))
  ;; PSW <- N Z from r (width b), V and C as given (0/1)
  (func $p11_fl (param $r i32) (param $b i32) (param $v i32) (param $c i32)
    (call $zw16 (i32.const 20) (i32.or (i32.and (call $zr16 (i32.const 20)) (i32.const 0xfff0)) (i32.or (i32.or
      (select (i32.const 8) (i32.const 0) (i32.and (local.get $r) (call $p11_msb (local.get $b))))
      (select (i32.const 4) (i32.const 0) (i32.eqz (i32.and (local.get $r) (call $p11_mask (local.get $b))))))
      (i32.or (i32.shl (i32.ne (local.get $v) (i32.const 0)) (i32.const 1)) (i32.ne (local.get $c) (i32.const 0)))))))
  (func $p11_C (result i32) (i32.and (call $zr16 (i32.const 20)) (i32.const 1)))
  (func $p11_cond (param $k i32) (result i32)   ;; branch code 1..7 (BR..BLE) and 8..15 (BPL..BCS)
    (local $p i32) (local $n i32) (local $z i32) (local $v i32) (local $c i32)
    (local.set $p (call $zr16 (i32.const 20)))
    (local.set $n (i32.and (i32.shr_u (local.get $p) (i32.const 3)) (i32.const 1))) (local.set $z (i32.and (i32.shr_u (local.get $p) (i32.const 2)) (i32.const 1)))
    (local.set $v (i32.and (i32.shr_u (local.get $p) (i32.const 1)) (i32.const 1))) (local.set $c (i32.and (local.get $p) (i32.const 1)))
    (block $r (block $b15 (block $b14 (block $b13 (block $b12 (block $b11 (block $b10 (block $b9 (block $b8 (block $b7 (block $b6 (block $b5 (block $b4 (block $b3 (block $b2 (block $b1 (block $b0
      (br_table $b0 $b1 $b2 $b3 $b4 $b5 $b6 $b7 $b8 $b9 $b10 $b11 $b12 $b13 $b14 $b15 (local.get $k)))
      (return (i32.const 0)))
      (return (i32.const 1)))
      (return (i32.eqz (local.get $z))))
      (return (local.get $z)))
      (return (i32.eqz (i32.xor (local.get $n) (local.get $v)))))
      (return (i32.xor (local.get $n) (local.get $v))))
      (return (i32.eqz (i32.or (local.get $z) (i32.xor (local.get $n) (local.get $v))))))
      (return (i32.or (local.get $z) (i32.xor (local.get $n) (local.get $v)))))
      (return (i32.eqz (local.get $n))))
      (return (local.get $n)))
      (return (i32.eqz (i32.or (local.get $c) (local.get $z)))))
      (return (i32.or (local.get $c) (local.get $z))))
      (return (i32.eqz (local.get $v))))
      (return (local.get $v)))
      (return (i32.eqz (local.get $c))))
      (return (local.get $c)))
    (i32.const 0))
  ;; double-operand group: op 1 MOV 2 CMP 3 BIT 4 BIC 5 BIS 6 ADD (b=0) / SUB (b=1)
  (func $p11_dop (param $w i32)
    (local $op i32) (local $b i32) (local $s i32) (local $d i32) (local $r i32) (local $de i32) (local $msb i32) (local $mask i32)
    (local.set $op (i32.and (i32.shr_u (local.get $w) (i32.const 12)) (i32.const 7))) (local.set $b (i32.shr_u (local.get $w) (i32.const 15)))
    (if (i32.eq (local.get $op) (i32.const 6)) (then   ;; ADD / SUB are word only
      (local.set $s (call $p11_ld (call $p11_ea (i32.shr_u (local.get $w) (i32.const 6)) (i32.const 0)) (i32.const 0)))
      (local.set $de (call $p11_ea (local.get $w) (i32.const 0))) (local.set $d (call $p11_ld (local.get $de) (i32.const 0)))
      (if (local.get $b)
        (then (local.set $r (i32.and (i32.sub (local.get $d) (local.get $s)) (i32.const 0xffff)))
          (call $p11_fl (local.get $r) (i32.const 0) (i32.and (i32.and (i32.xor (local.get $d) (local.get $s)) (i32.xor (local.get $d) (local.get $r))) (i32.const 0x8000)) (i32.gt_u (local.get $s) (local.get $d))))
        (else (local.set $r (i32.add (local.get $d) (local.get $s)))
          (call $p11_fl (local.get $r) (i32.const 0) (i32.and (i32.and (i32.xor (i32.xor (local.get $d) (local.get $s)) (i32.const -1)) (i32.xor (local.get $d) (local.get $r))) (i32.const 0x8000)) (i32.shr_u (local.get $r) (i32.const 16)))))
      (call $p11_st (local.get $de) (i32.const 0) (local.get $r))
      (return)))
    (local.set $msb (call $p11_msb (local.get $b))) (local.set $mask (call $p11_mask (local.get $b)))
    (local.set $s (call $p11_ld (call $p11_ea (i32.shr_u (local.get $w) (i32.const 6)) (local.get $b)) (local.get $b)))
    (local.set $de (call $p11_ea (local.get $w) (local.get $b)))
    (if (i32.eq (local.get $op) (i32.const 1)) (then   ;; MOV; MOVB to a register sign-extends
      (call $p11_fl (local.get $s) (local.get $b) (i32.const 0) (call $p11_C))
      (if (i32.and (local.get $b) (i32.ge_u (local.get $de) (i32.const 0x10000)))
        (then (call $p11_st (local.get $de) (i32.const 0) (call $sext8 (local.get $s))))
        (else (call $p11_st (local.get $de) (local.get $b) (local.get $s))))
      (return)))
    (local.set $d (call $p11_ld (local.get $de) (local.get $b)))
    (if (i32.eq (local.get $op) (i32.const 2)) (then   ;; CMP src - dst
      (local.set $r (i32.and (i32.sub (local.get $s) (local.get $d)) (local.get $mask)))
      (call $p11_fl (local.get $r) (local.get $b) (i32.and (i32.and (i32.xor (local.get $s) (local.get $d)) (i32.xor (local.get $s) (local.get $r))) (local.get $msb)) (i32.lt_u (local.get $s) (local.get $d)))
      (return)))
    (if (i32.eq (local.get $op) (i32.const 3)) (then (call $p11_fl (i32.and (local.get $s) (local.get $d)) (local.get $b) (i32.const 0) (call $p11_C)) (return)))
    (local.set $r (select (i32.and (local.get $d) (i32.xor (local.get $s) (i32.const -1))) (i32.or (local.get $d) (local.get $s)) (i32.eq (local.get $op) (i32.const 4))))
    (call $p11_fl (local.get $r) (local.get $b) (i32.const 0) (call $p11_C))
    (call $p11_st (local.get $de) (local.get $b) (local.get $r)))
  ;; single-operand group; k = 0 CLR 1 COM 2 INC 3 DEC 4 NEG 5 ADC 6 SBC 7 TST 8 ROR 9 ROL 10 ASR 11 ASL
  (func $p11_sop (param $k i32) (param $ea i32) (param $b i32)
    (local $d i32) (local $r i32) (local $c i32) (local $msb i32) (local $mask i32) (local $v i32) (local $cc i32) (local $shb i32)
    (local.set $msb (call $p11_msb (local.get $b))) (local.set $mask (call $p11_mask (local.get $b))) (local.set $c (call $p11_C))
    (local.set $d (call $p11_ld (local.get $ea) (local.get $b))) (local.set $shb (select (i32.const 7) (i32.const 15) (local.get $b)))
    (block $done
      (if (i32.eqz (local.get $k)) (then (local.set $r (i32.const 0)) (local.set $cc (i32.const 0)) (br $done)))
      (if (i32.eq (local.get $k) (i32.const 1)) (then (local.set $r (i32.and (i32.xor (local.get $d) (i32.const -1)) (local.get $mask))) (local.set $cc (i32.const 1)) (br $done)))
      (if (i32.eq (local.get $k) (i32.const 2)) (then (local.set $r (i32.and (i32.add (local.get $d) (i32.const 1)) (local.get $mask))) (local.set $v (i32.eq (local.get $d) (i32.sub (local.get $msb) (i32.const 1)))) (local.set $cc (local.get $c)) (br $done)))
      (if (i32.eq (local.get $k) (i32.const 3)) (then (local.set $r (i32.and (i32.sub (local.get $d) (i32.const 1)) (local.get $mask))) (local.set $v (i32.eq (local.get $d) (local.get $msb))) (local.set $cc (local.get $c)) (br $done)))
      (if (i32.eq (local.get $k) (i32.const 4)) (then (local.set $r (i32.and (i32.sub (i32.const 0) (local.get $d)) (local.get $mask))) (local.set $v (i32.eq (local.get $r) (local.get $msb))) (local.set $cc (i32.ne (local.get $r) (i32.const 0))) (br $done)))
      (if (i32.eq (local.get $k) (i32.const 5)) (then (local.set $r (i32.and (i32.add (local.get $d) (local.get $c)) (local.get $mask)))
        (local.set $v (i32.and (i32.eq (local.get $d) (i32.sub (local.get $msb) (i32.const 1))) (local.get $c))) (local.set $cc (i32.and (i32.eq (local.get $d) (local.get $mask)) (local.get $c))) (br $done)))
      (if (i32.eq (local.get $k) (i32.const 6)) (then (local.set $r (i32.and (i32.sub (local.get $d) (local.get $c)) (local.get $mask)))
        (local.set $v (i32.eq (local.get $d) (local.get $msb))) (local.set $cc (i32.and (i32.eqz (local.get $d)) (local.get $c))) (br $done)))
      (if (i32.eq (local.get $k) (i32.const 7)) (then (call $p11_fl (local.get $d) (local.get $b) (i32.const 0) (i32.const 0)) (return)))
      (if (i32.eq (local.get $k) (i32.const 8)) (then (local.set $r (i32.or (i32.shr_u (local.get $d) (i32.const 1)) (i32.shl (local.get $c) (local.get $shb)))) (local.set $cc (i32.and (local.get $d) (i32.const 1))) (br $done)))
      (if (i32.eq (local.get $k) (i32.const 9)) (then (local.set $r (i32.and (i32.or (i32.shl (local.get $d) (i32.const 1)) (local.get $c)) (local.get $mask))) (local.set $cc (i32.shr_u (local.get $d) (local.get $shb))) (br $done)))
      (if (i32.eq (local.get $k) (i32.const 10)) (then (local.set $r (i32.or (i32.shr_u (local.get $d) (i32.const 1)) (i32.and (local.get $d) (local.get $msb)))) (local.set $cc (i32.and (local.get $d) (i32.const 1))) (br $done)))
      (local.set $r (i32.and (i32.shl (local.get $d) (i32.const 1)) (local.get $mask))) (local.set $cc (i32.shr_u (local.get $d) (local.get $shb))))
    (if (i32.ge_u (local.get $k) (i32.const 8)) (then (local.set $v (i32.xor (i32.shr_u (local.get $r) (local.get $shb)) (local.get $cc)))))   ;; rotates and shifts: V = N xor C
    (call $p11_fl (local.get $r) (local.get $b) (local.get $v) (local.get $cc))
    (call $p11_st (local.get $ea) (local.get $b) (local.get $r)))
  (func $p11_eis (param $w i32)
    (local $sub i32) (local $n i32) (local $r i32) (local $s i32) (local $p i32) (local $q i32) (local $cnt i32) (local $v i32) (local $c i32) (local $ea i32) (local $lo i32)
    (local.set $sub (i32.and (i32.shr_u (local.get $w) (i32.const 9)) (i32.const 7))) (local.set $n (i32.and (i32.shr_u (local.get $w) (i32.const 6)) (i32.const 7)))
    (if (i32.eq (local.get $sub) (i32.const 7)) (then   ;; SOB
      (local.set $r (i32.and (i32.sub (call $p11_r (local.get $n)) (i32.const 1)) (i32.const 0xffff))) (call $p11_w (local.get $n) (local.get $r))
      (if (local.get $r) (then (call $zw16 (i32.const 22) (i32.and (i32.sub (call $zr16 (i32.const 22)) (i32.shl (i32.and (local.get $w) (i32.const 63)) (i32.const 1))) (i32.const 0xffff)))))
      (return)))
    (if (i32.ge_u (local.get $sub) (i32.const 5)) (then (return)))   ;; FIS
    (local.set $ea (call $p11_ea (local.get $w) (i32.const 0))) (local.set $s (call $p11_ld (local.get $ea) (i32.const 0))) (local.set $r (call $p11_r (local.get $n)))
    (if (i32.eq (local.get $sub) (i32.const 4)) (then (local.set $p (i32.xor (local.get $s) (local.get $r))) (call $p11_fl (local.get $p) (i32.const 0) (i32.const 0) (call $p11_C)) (call $p11_st (local.get $ea) (i32.const 0) (local.get $p)) (return)))
    (if (i32.eqz (local.get $sub)) (then   ;; MUL
      (local.set $p (i32.mul (call $sx (local.get $r) (i32.const 16)) (call $sx (local.get $s) (i32.const 16))))
      (if (i32.and (local.get $n) (i32.const 1)) (then (call $p11_w (local.get $n) (local.get $p)))
        (else (call $p11_w (local.get $n) (i32.shr_u (local.get $p) (i32.const 16))) (call $p11_w (i32.or (local.get $n) (i32.const 1)) (local.get $p))))
      (call $zw16 (i32.const 20) (i32.or (i32.and (call $zr16 (i32.const 20)) (i32.const 0xfff0)) (i32.or (i32.or
        (select (i32.const 8) (i32.const 0) (i32.lt_s (local.get $p) (i32.const 0))) (select (i32.const 4) (i32.const 0) (i32.eqz (local.get $p))))
        (i32.ne (call $sx (local.get $p) (i32.const 16)) (local.get $p)))))
      (return)))
    (local.set $lo (call $p11_r (i32.or (local.get $n) (i32.const 1)))) (local.set $p (i32.or (i32.shl (local.get $r) (i32.const 16)) (local.get $lo)))   ;; 32-bit R:R|1
    (if (i32.eq (local.get $sub) (i32.const 1)) (then   ;; DIV
      (if (i32.eqz (local.get $s)) (then (call $p11_fl (i32.const 0) (i32.const 0) (i32.const 1) (i32.const 1)) (return)))
      (local.set $s (call $sx (local.get $s) (i32.const 16)))
      (if (i32.and (i32.eq (local.get $p) (i32.const 0x80000000)) (i32.eq (local.get $s) (i32.const -1))) (then (call $p11_fl (i32.const 0) (i32.const 0) (i32.const 1) (i32.const 0)) (return)))
      (local.set $q (i32.div_s (local.get $p) (local.get $s)))
      (if (i32.ne (call $sx (local.get $q) (i32.const 16)) (local.get $q)) (then (call $p11_fl (local.get $q) (i32.const 0) (i32.const 1) (i32.const 0)) (return)))
      (call $p11_w (local.get $n) (local.get $q)) (call $p11_w (i32.or (local.get $n) (i32.const 1)) (i32.rem_s (local.get $p) (local.get $s)))
      (call $p11_fl (local.get $q) (i32.const 0) (i32.const 0) (i32.const 0))
      (return)))
    (local.set $cnt (call $sx (local.get $s) (i32.const 6)))
    (if (i32.eq (local.get $sub) (i32.const 2)) (then   ;; ASH
      (local.set $p (call $sx (local.get $r) (i32.const 16)))
      (if (i32.gt_s (local.get $cnt) (i32.const 0)) (then
        (local.set $q (i32.shl (local.get $p) (local.get $cnt)))
        (local.set $c (i32.and (i32.shr_u (local.get $p) (i32.sub (i32.const 16) (local.get $cnt))) (i32.const 1)))
        (local.set $v (i32.ne (call $sx (local.get $q) (i32.const 16)) (local.get $q))))
      (else (if (local.get $cnt) (then
        (local.set $cnt (i32.sub (i32.const 0) (local.get $cnt)))
        (local.set $q (i32.shr_s (local.get $p) (local.get $cnt)))
        (local.set $c (i32.and (i32.shr_s (local.get $p) (i32.sub (local.get $cnt) (i32.const 1))) (i32.const 1))))
        (else (local.set $q (local.get $p))))))
      (call $p11_w (local.get $n) (local.get $q)) (call $p11_fl (local.get $q) (i32.const 0) (local.get $v) (local.get $c))
      (return)))
    ;; ASHC on the 32-bit pair
    (if (i32.gt_s (local.get $cnt) (i32.const 0)) (then
      (local.set $q (i32.shl (local.get $p) (local.get $cnt)))
      (local.set $c (i32.and (i32.shr_u (local.get $p) (i32.sub (i32.const 32) (local.get $cnt))) (i32.const 1)))
      (local.set $v (i32.ne (i32.shr_s (local.get $q) (local.get $cnt)) (local.get $p))))
    (else (if (local.get $cnt) (then
      (local.set $cnt (i32.sub (i32.const 0) (local.get $cnt)))
      (local.set $q (i32.shr_s (local.get $p) (local.get $cnt)))
      (local.set $c (i32.and (i32.shr_s (local.get $p) (i32.sub (local.get $cnt) (i32.const 1))) (i32.const 1))))
      (else (local.set $q (local.get $p))))))
    (if (i32.and (local.get $n) (i32.const 1)) (then (call $p11_w (local.get $n) (local.get $q)))
      (else (call $p11_w (local.get $n) (i32.shr_u (local.get $q) (i32.const 16))) (call $p11_w (i32.or (local.get $n) (i32.const 1)) (local.get $q))))
    (call $zw16 (i32.const 20) (i32.or (i32.and (call $zr16 (i32.const 20)) (i32.const 0xfff0)) (i32.or (i32.or
      (select (i32.const 8) (i32.const 0) (i32.lt_s (local.get $q) (i32.const 0))) (select (i32.const 4) (i32.const 0) (i32.eqz (local.get $q))))
      (i32.or (i32.shl (local.get $v) (i32.const 1)) (local.get $c))))))
  (func $pdp11_step
    (local $w i32) (local $b i32) (local $c i32) (local $t i32) (local $n i32) (local $ea i32)
    (local.set $w (call $p11_fetch)) (local.set $b (i32.shr_u (local.get $w) (i32.const 15)))
    (local.set $t (i32.and (i32.shr_u (local.get $w) (i32.const 12)) (i32.const 7)))
    (if (i32.and (i32.ge_u (local.get $t) (i32.const 1)) (i32.le_u (local.get $t) (i32.const 6))) (then (call $p11_dop (local.get $w)) (return)))
    (if (i32.eq (local.get $t) (i32.const 7)) (then (if (i32.eqz (local.get $b)) (then (call $p11_eis (local.get $w)))) (return)))   ;; 17xxxx: floating point, NOP
    (local.set $c (i32.and (i32.shr_u (local.get $w) (i32.const 6)) (i32.const 0x1ff)))
    (if (i32.eqz (local.get $b)) (then
      (if (i32.eqz (local.get $c)) (then   ;; HALT WAIT RTI BPT IOT RESET RTT
        (local.set $t (i32.and (local.get $w) (i32.const 63)))
        (if (i32.or (i32.eq (local.get $t) (i32.const 2)) (i32.eq (local.get $t) (i32.const 6))) (then (call $zw16 (i32.const 22) (call $p11_pop)) (call $zw16 (i32.const 20) (i32.and (call $p11_pop) (i32.const 0xff)))))
        (return)))
      (if (i32.eq (local.get $c) (i32.const 1)) (then (local.set $ea (call $p11_ea (local.get $w) (i32.const 0))) (if (i32.lt_u (local.get $ea) (i32.const 0x10000)) (then (call $zw16 (i32.const 22) (local.get $ea)))) (return)))   ;; JMP
      (if (i32.eq (local.get $c) (i32.const 2)) (then
        (local.set $t (i32.and (local.get $w) (i32.const 0x38)))
        (if (i32.eqz (local.get $t)) (then (local.set $n (i32.and (local.get $w) (i32.const 7))) (call $zw16 (i32.const 22) (call $p11_r (local.get $n))) (call $p11_w (local.get $n) (call $p11_pop)) (return)))   ;; RTS
        (if (i32.ge_u (local.get $t) (i32.const 0x20)) (then   ;; condition codes: 24x clear, 26x set
          (if (i32.and (local.get $w) (i32.const 0x10)) (then (call $zw16 (i32.const 20) (i32.or (call $zr16 (i32.const 20)) (i32.and (local.get $w) (i32.const 15)))))
            (else (call $zw16 (i32.const 20) (i32.and (call $zr16 (i32.const 20)) (i32.xor (i32.and (local.get $w) (i32.const 15)) (i32.const -1))))))))
        (return)))
      (if (i32.eq (local.get $c) (i32.const 3)) (then   ;; SWAB
        (local.set $ea (call $p11_ea (local.get $w) (i32.const 0))) (local.set $t (call $p11_ld (local.get $ea) (i32.const 0)))
        (local.set $t (i32.or (i32.shl (i32.and (local.get $t) (i32.const 0xff)) (i32.const 8)) (i32.shr_u (local.get $t) (i32.const 8))))
        (call $p11_fl (local.get $t) (i32.const 1) (i32.const 0) (i32.const 0)) (call $p11_st (local.get $ea) (i32.const 0) (local.get $t)) (return)))
      (if (i32.lt_u (local.get $c) (i32.const 32)) (then   ;; BR .. BLE
        (if (call $p11_cond (i32.and (i32.shr_u (local.get $w) (i32.const 8)) (i32.const 7))) (then (call $zw16 (i32.const 22) (i32.and (i32.add (call $zr16 (i32.const 22)) (i32.shl (call $sext8 (local.get $w)) (i32.const 1))) (i32.const 0xffff)))))
        (return)))
      (if (i32.lt_u (local.get $c) (i32.const 40)) (then   ;; JSR R,dst
        (local.set $n (i32.and (i32.shr_u (local.get $w) (i32.const 6)) (i32.const 7))) (local.set $ea (call $p11_ea (local.get $w) (i32.const 0)))
        (if (i32.lt_u (local.get $ea) (i32.const 0x10000)) (then (call $p11_push (call $p11_r (local.get $n))) (call $p11_w (local.get $n) (call $zr16 (i32.const 22))) (call $zw16 (i32.const 22) (local.get $ea))))
        (return)))
      (if (i32.eq (local.get $c) (i32.const 55)) (then   ;; SXT
        (local.set $ea (call $p11_ea (local.get $w) (i32.const 0))) (local.set $t (select (i32.const 0xffff) (i32.const 0) (i32.and (call $zr16 (i32.const 20)) (i32.const 8))))
        (call $p11_fl (local.get $t) (i32.const 0) (i32.const 0) (call $p11_C)) (call $p11_st (local.get $ea) (i32.const 0) (local.get $t)) (return))))
    (else
      (if (i32.lt_u (local.get $c) (i32.const 16)) (then   ;; BPL .. BCS
        (if (call $p11_cond (i32.add (i32.const 8) (i32.and (i32.shr_u (local.get $w) (i32.const 8)) (i32.const 7)))) (then (call $zw16 (i32.const 22) (i32.and (i32.add (call $zr16 (i32.const 22)) (i32.shl (call $sext8 (local.get $w)) (i32.const 1))) (i32.const 0xffff)))))
        (return)))
      (if (i32.eq (local.get $c) (i32.const 52)) (then (call $zw16 (i32.const 20) (i32.and (call $p11_ld (call $p11_ea (local.get $w) (i32.const 1)) (i32.const 1)) (i32.const 0xef))) (return)))   ;; MTPS
      (if (i32.eq (local.get $c) (i32.const 55)) (then   ;; MFPS
        (local.set $ea (call $p11_ea (local.get $w) (i32.const 1))) (local.set $t (i32.and (call $zr16 (i32.const 20)) (i32.const 0xff)))
        (call $p11_fl (local.get $t) (i32.const 1) (i32.const 0) (call $p11_C))
        (if (i32.ge_u (local.get $ea) (i32.const 0x10000)) (then (call $p11_st (local.get $ea) (i32.const 0) (call $sext8 (local.get $t)))) (else (call $p11_st (local.get $ea) (i32.const 1) (local.get $t))))
        (return)))))
    (if (i32.and (i32.ge_u (local.get $c) (i32.const 40)) (i32.lt_u (local.get $c) (i32.const 52))) (then   ;; CLR .. ASL and the byte forms
      (call $p11_sop (i32.sub (local.get $c) (i32.const 40)) (call $p11_ea (local.get $w) (local.get $b)) (local.get $b)))))
