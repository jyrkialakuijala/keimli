  ;; ERA / UNIVAC 1101 (kind 22). The pixel is 5 words of 24 bits (word k = bits 24k..24k+23).
  ;; Register file: A (48 bits, ones' complement) at 0..7, Q (24 bits) at 8..11, X (the operand
  ;; last read) at 12..15, PC (word number) at 22. Instruction word: operation (bits 23..18, two
  ;; octal digits as in the January 1950 ERA list), skip (17..14) and address y (13..0). The next
  ;; instruction is PC + 1 + skip (mod 5), jumps go to y mod 5, operands come from y mod 5.
  ;; A shifts and Q shifts are circular; multiply forms the 48-bit product of Q and (y); divide
  ;; leaves the quotient in Q and a non-negative remainder in A. Print and the three stops are NOPs.
  (func $u_mem (param $a i32) (result i32) (i32.wrap_i64 (call $fld_rd (i32.mul (i32.rem_u (local.get $a) (i32.const 5)) (i32.const 24)) (i32.const 24))))
  (func $u_set (param $a i32) (param $v i32) (call $fld_wr (i32.mul (i32.rem_u (local.get $a) (i32.const 5)) (i32.const 24)) (i32.const 24) (i64.extend_i32_u (local.get $v))))
  ;; 48-bit ones' complement add with end-around carry; -0 only comes out of -0 + -0
  (func $u_add (param $a i64) (param $b i64) (result i64)
    (local $s i64)
    (local.set $s (i64.add (local.get $a) (local.get $b)))
    (local.set $s (i64.add (i64.and (local.get $s) (i64.const 0xffffffffffff)) (i64.shr_u (local.get $s) (i64.const 48))))
    (if (i64.eq (local.get $s) (i64.const 0xffffffffffff)) (then
      (if (i32.eqz (i32.and (i64.eq (local.get $a) (i64.const 0xffffffffffff)) (i64.eq (local.get $b) (i64.const 0xffffffffffff))))
        (then (local.set $s (i64.const 0))))))
    (local.get $s))
  (func $u_sub (param $a i64) (param $b i64) (result i64) (call $u_add (local.get $a) (i64.xor (local.get $b) (i64.const 0xffffffffffff))))
  (func $u_sx (param $v i32) (result i64)   ;; 24-bit word sign-extended to 48 bits
    (i64.and (i64.extend_i32_s (i32.shr_s (i32.shl (local.get $v) (i32.const 8)) (i32.const 8))) (i64.const 0xffffffffffff)))
  (func $u_abs (param $v i32) (result i64)
    (if (i32.and (local.get $v) (i32.const 0x800000)) (then (return (i64.extend_i32_u (i32.and (i32.xor (local.get $v) (i32.const -1)) (i32.const 0xffffff))))))
    (i64.extend_i32_u (local.get $v)))
  (func $u_val (param $v i32) (result i64)   ;; ones' complement 24-bit word as a signed value
    (if (i32.and (local.get $v) (i32.const 0x800000)) (then (return (i64.sub (i64.const 0) (i64.extend_i32_u (i32.and (i32.xor (local.get $v) (i32.const -1)) (i32.const 0xffffff)))))))
    (i64.extend_i32_u (local.get $v)))
  (func $u_val48 (param $v i64) (result i64)
    (if (i64.ne (i64.and (local.get $v) (i64.const 0x800000000000)) (i64.const 0)) (then (return (i64.sub (i64.const 0) (i64.and (i64.xor (local.get $v) (i64.const -1)) (i64.const 0xffffffffffff))))))
    (local.get $v))
  (func $u_oc48 (param $v i64) (result i64)   ;; signed value -> 48-bit ones' complement
    (if (i64.lt_s (local.get $v) (i64.const 0)) (then (return (i64.and (i64.xor (i64.sub (i64.const 0) (local.get $v)) (i64.const -1)) (i64.const 0xffffffffffff)))))
    (i64.and (local.get $v) (i64.const 0xffffffffffff)))
  (func $u_rotl48 (param $a i64) (param $k i32) (result i64)
    (local.set $k (i32.rem_u (local.get $k) (i32.const 48)))
    (i64.and (i64.or (i64.shl (local.get $a) (i64.extend_i32_u (local.get $k))) (i64.shr_u (local.get $a) (i64.extend_i32_u (i32.sub (i32.const 48) (local.get $k))))) (i64.const 0xffffffffffff)))
  (func $u_rotl24 (param $q i32) (param $k i32) (result i32)
    (local.set $k (i32.rem_u (local.get $k) (i32.const 24)))
    (i32.and (i32.or (i32.shl (local.get $q) (local.get $k)) (i32.shr_u (local.get $q) (i32.sub (i32.const 24) (local.get $k)))) (i32.const 0xffffff)))
  (func $u1101_step
    (local $pc i32) (local $w i32) (local $op i32) (local $y i32) (local $x i32) (local $a i64) (local $q i32) (local $next i32) (local $jump i32)
    (local $n i64) (local $d i64) (local $r i64)
    (local.set $pc (call $zr16 (i32.const 22)))
    (local.set $w (call $u_mem (local.get $pc)))
    (local.set $op (i32.shr_u (local.get $w) (i32.const 18)))
    (local.set $y (i32.and (local.get $w) (i32.const 0x3fff)))
    (local.set $next (i32.rem_u (i32.add (i32.add (local.get $pc) (i32.const 1)) (i32.and (i32.shr_u (local.get $w) (i32.const 14)) (i32.const 15))) (i32.const 5)))
    (local.set $a (call $zr64 (i32.const 0)))
    (local.set $q (i32.and (call $zr32 (i32.const 8)) (i32.const 0xffffff)))
    (local.set $x (call $u_mem (local.get $y)))
    (call $zw32 (i32.const 12) (local.get $x))
    (block $end
      ;; 11 OP, 12 OA, 13 ON, 14 OS: clear/hold add/subtract (y)
      (if (i32.eq (local.get $op) (i32.const 0x09)) (then (local.set $a (call $u_sx (local.get $x))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x0a)) (then (local.set $a (call $u_add (local.get $a) (call $u_sx (local.get $x)))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x0b)) (then (local.set $a (call $u_sub (i64.const 0) (call $u_sx (local.get $x)))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x0c)) (then (local.set $a (call $u_sub (local.get $a) (call $u_sx (local.get $x)))) (br $end)))
      ;; 15 clear right half of A, 16 fill Q, 17 SD substitute digits: (y) <- (A) where Q has ones
      (if (i32.eq (local.get $op) (i32.const 0x0d)) (then (local.set $a (i64.and (local.get $a) (i64.const 0xffffff000000))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x0e)) (then (local.set $q (local.get $x)) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x0f)) (then
        (call $u_set (local.get $y) (i32.or (i32.and (local.get $x) (i32.xor (local.get $q) (i32.const -1))) (i32.and (i32.wrap_i64 (local.get $a)) (local.get $q)))) (br $end)))
      ;; 21 AP, 22 AA, 23 AN, 24 AS: the absolute value of (y)
      (if (i32.eq (local.get $op) (i32.const 0x11)) (then (local.set $a (call $u_abs (local.get $x))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x12)) (then (local.set $a (call $u_add (local.get $a) (call $u_abs (local.get $x)))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x13)) (then (local.set $a (call $u_sub (i64.const 0) (call $u_abs (local.get $x)))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x14)) (then (local.set $a (call $u_sub (local.get $a) (call $u_abs (local.get $x)))) (br $end)))
      ;; 25 AL k shift A left, 26 QL k shift Q left (circular, count = address field), 27 SE substitute execution address
      (if (i32.eq (local.get $op) (i32.const 0x15)) (then (local.set $a (call $u_rotl48 (local.get $a) (local.get $y))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x16)) (then (local.set $q (call $u_rotl24 (local.get $q) (local.get $y))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x17)) (then
        (call $u_set (local.get $y) (i32.or (i32.and (local.get $x) (i32.const 0xffc000)) (i32.and (i32.wrap_i64 (local.get $a)) (i32.const 0x3fff)))) (br $end)))
      ;; 31 SP, 32 SA, 33 SN, 34 SS: split (multiple precision) forms, (y) taken as 24 unsigned bits
      (if (i32.eq (local.get $op) (i32.const 0x19)) (then (local.set $a (i64.extend_i32_u (local.get $x))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x1a)) (then (local.set $a (call $u_add (local.get $a) (i64.extend_i32_u (local.get $x)))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x1b)) (then (local.set $a (call $u_sub (i64.const 0) (i64.extend_i32_u (local.get $x)))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x1c)) (then (local.set $a (call $u_sub (local.get $a) (i64.extend_i32_u (local.get $x)))) (br $end)))
      ;; 35 AY store the right half of A, 36 QY store Q
      (if (i32.eq (local.get $op) (i32.const 0x1d)) (then (call $u_set (local.get $y) (i32.wrap_i64 (local.get $a))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x1e)) (then (call $u_set (local.get $y) (local.get $q)) (br $end)))
      ;; 41 QP clear add from Q, 42 QA hold add from Q, 43 AQ transmit A to Q
      (if (i32.eq (local.get $op) (i32.const 0x21)) (then (local.set $a (call $u_sx (local.get $q))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x22)) (then (local.set $a (call $u_add (local.get $a) (call $u_sx (local.get $q)))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x23)) (then (local.set $q (i32.and (i32.wrap_i64 (local.get $a)) (i32.const 0xffffff))) (br $end)))
      ;; 44 QJ jump if q23 = 1 (Q shifts left 1 either way), 45 UJ jump, 46 CJ jump if A negative, 47 ZJ jump if A not zero
      (if (i32.eq (local.get $op) (i32.const 0x24)) (then
        (local.set $jump (i32.and (local.get $q) (i32.const 0x800000)))
        (local.set $q (call $u_rotl24 (local.get $q) (i32.const 1))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x25)) (then (local.set $jump (i32.const 1)) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x26)) (then (local.set $jump (i64.ne (i64.and (local.get $a) (i64.const 0x800000000000)) (i64.const 0))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x27)) (then
        (local.set $jump (i32.and (i64.ne (local.get $a) (i64.const 0)) (i64.ne (local.get $a) (i64.const 0xffffffffffff)))) (br $end)))
      ;; 51 LP clear logical multiply, 52 LA hold logical multiply: Q and (y)
      (if (i32.eq (local.get $op) (i32.const 0x29)) (then (local.set $a (i64.extend_i32_u (i32.and (local.get $q) (local.get $x)))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x2a)) (then (local.set $a (call $u_add (local.get $a) (i64.extend_i32_u (i32.and (local.get $q) (local.get $x))))) (br $end)))
      ;; 53 PO, 54 PP, 55 IS, 56 CS, 57 FS: print and stops are NOPs
      ;; 61 MP clear multiply, 62 MA hold multiply (Q times (y)), 63 DP divide A by (y)
      (if (i32.eq (local.get $op) (i32.const 0x31)) (then (local.set $a (call $u_oc48 (i64.mul (call $u_val (local.get $q)) (call $u_val (local.get $x))))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x32)) (then (local.set $a (call $u_add (local.get $a) (call $u_oc48 (i64.mul (call $u_val (local.get $q)) (call $u_val (local.get $x)))))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x33)) (then
        (local.set $d (call $u_val (local.get $x)))
        (br_if $end (i64.eqz (local.get $d)))
        (local.set $n (call $u_val48 (local.get $a)))
        (local.set $r (i64.rem_s (local.get $n) (local.get $d)))
        (if (i64.lt_s (local.get $r) (i64.const 0)) (then
          (local.set $r (i64.add (local.get $r) (select (i64.sub (i64.const 0) (local.get $d)) (local.get $d) (i64.lt_s (local.get $d) (i64.const 0)))))))
        (local.set $q (i32.and (i32.wrap_i64 (call $u_oc48 (i64.div_s (i64.sub (local.get $n) (local.get $r)) (local.get $d)))) (i32.const 0xffffff)))
        (local.set $a (local.get $r)) (br $end)))
      ;; 71 NP clear add (y) + 1
      (if (i32.eq (local.get $op) (i32.const 0x39)) (then (local.set $a (call $u_add (call $u_sx (local.get $x)) (i64.const 1))) (br $end))))
    (call $zw64 (i32.const 0) (i64.and (local.get $a) (i64.const 0xffffffffffff)))
    (call $zw32 (i32.const 8) (local.get $q))
    (call $zw16 (i32.const 22) (select (i32.rem_u (local.get $y) (i32.const 5)) (local.get $next) (local.get $jump))))
