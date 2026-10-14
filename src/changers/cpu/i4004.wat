  ;; Intel 4004 (kind 11). 4-bit accumulator at 0, carry at 1, index registers
  ;; R0..R15 (one nibble each) at 2..17, SRC address at 18, stack level at 19,
  ;; the 3-level stack (u16) at 32, PC (12-bit) at 22. The 16 bytes are both the
  ;; ROM (8-bit instructions, PC mod 16) and the RAM: 32 nibbles, nibble n in the
  ;; low (even n) or high (odd n) half of byte n/2, addressed by SRC mod 32.
  ;; Output/status-character instructions and DCL do nothing; TEST reads 0.
  (func $ram4 (param $n i32) (result i32)
    (local $b i32) (local.set $b (call $mrd (i32.shr_u (i32.and (local.get $n) (i32.const 31)) (i32.const 1))))
    (select (i32.shr_u (local.get $b) (i32.const 4)) (i32.and (local.get $b) (i32.const 15)) (i32.and (local.get $n) (i32.const 1))))
  (func $ram4w (param $n i32) (param $v i32)
    (local $a i32) (local $b i32)
    (local.set $a (i32.shr_u (i32.and (local.get $n) (i32.const 31)) (i32.const 1))) (local.set $b (call $mrd (local.get $a)))
    (call $mwr (local.get $a) (select
      (i32.or (i32.and (local.get $b) (i32.const 15)) (i32.shl (local.get $v) (i32.const 4)))
      (i32.or (i32.and (local.get $b) (i32.const 0xF0)) (local.get $v))
      (i32.and (local.get $n) (i32.const 1)))))
  (func $acc4add (param $v i32)   ;; acc += v (v already includes carry-in); carry out
    (local $r i32) (local.set $r (i32.add (call $zr (i32.const 0)) (local.get $v)))
    (call $zw (i32.const 0) (i32.and (local.get $r) (i32.const 15))) (call $zw (i32.const 1) (i32.shr_u (local.get $r) (i32.const 4))))
  (func $i4004_step
    (local $pc i32) (local $op i32) (local $hi i32) (local $lo i32) (local $t i32) (local $acc i32) (local $cy i32) (local $r i32)
    (local.set $pc (call $zr16 (i32.const 22)))
    (local.set $op (call $mrd (local.get $pc))) (local.set $pc (i32.and (i32.add (local.get $pc) (i32.const 1)) (i32.const 0xfff)))
    (local.set $hi (i32.shr_u (local.get $op) (i32.const 4))) (local.set $lo (i32.and (local.get $op) (i32.const 15)))
    (local.set $acc (call $zr (i32.const 0))) (local.set $cy (call $zr (i32.const 1)))
    (block $end
      (if (i32.eqz (local.get $hi)) (then (br $end)))   ;; NOP
      (if (i32.eq (local.get $hi) (i32.const 1)) (then   ;; JCN
        (local.set $t (call $mrd (local.get $pc))) (local.set $pc (i32.and (i32.add (local.get $pc) (i32.const 1)) (i32.const 0xfff)))
        (local.set $r (i32.or (i32.or (i32.and (i32.eqz (local.get $acc)) (i32.shr_u (i32.and (local.get $lo) (i32.const 4)) (i32.const 2)))
                                      (i32.and (local.get $cy) (i32.shr_u (i32.and (local.get $lo) (i32.const 2)) (i32.const 1))))
                              (i32.and (local.get $lo) (i32.const 1))))   ;; TEST pin is 0, so the "test = 0" condition holds
        (if (i32.xor (i32.ne (local.get $r) (i32.const 0)) (i32.shr_u (local.get $lo) (i32.const 3)))
          (then (local.set $pc (i32.or (i32.and (local.get $pc) (i32.const 0xf00)) (local.get $t)))))
        (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 2)) (then
        (local.set $r (i32.add (i32.const 2) (i32.and (local.get $lo) (i32.const 14))))   ;; register pair base
        (if (i32.and (local.get $lo) (i32.const 1))
          (then (call $zw (i32.const 18) (i32.or (i32.shl (call $zr (local.get $r)) (i32.const 4)) (call $zr (i32.add (local.get $r) (i32.const 1))))))   ;; SRC
          (else (local.set $t (call $mrd (local.get $pc))) (local.set $pc (i32.and (i32.add (local.get $pc) (i32.const 1)) (i32.const 0xfff)))      ;; FIM
                (call $zw (local.get $r) (i32.shr_u (local.get $t) (i32.const 4))) (call $zw (i32.add (local.get $r) (i32.const 1)) (i32.and (local.get $t) (i32.const 15)))))
        (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 3)) (then
        (local.set $r (i32.add (i32.const 2) (i32.and (local.get $lo) (i32.const 14))))
        (if (i32.and (local.get $lo) (i32.const 1))
          (then (local.set $pc (i32.or (i32.and (local.get $pc) (i32.const 0xf00)) (i32.or (i32.shl (call $zr (local.get $r)) (i32.const 4)) (call $zr (i32.add (local.get $r) (i32.const 1)))))))   ;; JIN
          (else (local.set $t (call $mrd (i32.or (i32.and (local.get $pc) (i32.const 0xf00)) (i32.or (i32.shl (call $zr (i32.const 2)) (i32.const 4)) (call $zr (i32.const 3))))))   ;; FIN
                (call $zw (local.get $r) (i32.shr_u (local.get $t) (i32.const 4))) (call $zw (i32.add (local.get $r) (i32.const 1)) (i32.and (local.get $t) (i32.const 15)))))
        (br $end)))
      (if (i32.or (i32.eq (local.get $hi) (i32.const 4)) (i32.eq (local.get $hi) (i32.const 5))) (then   ;; JUN / JMS
        (local.set $t (i32.or (i32.shl (local.get $lo) (i32.const 8)) (call $mrd (local.get $pc)))) (local.set $pc (i32.and (i32.add (local.get $pc) (i32.const 1)) (i32.const 0xfff)))
        (if (i32.eq (local.get $hi) (i32.const 5)) (then
          (call $zw16 (i32.add (i32.const 32) (i32.shl (call $zr (i32.const 19)) (i32.const 1))) (local.get $pc))
          (call $zw (i32.const 19) (i32.rem_u (i32.add (call $zr (i32.const 19)) (i32.const 1)) (i32.const 3)))))
        (local.set $pc (local.get $t)) (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 6)) (then (call $zw (i32.add (i32.const 2) (local.get $lo)) (i32.and (i32.add (call $zr (i32.add (i32.const 2) (local.get $lo))) (i32.const 1)) (i32.const 15))) (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 7)) (then   ;; ISZ
        (local.set $t (call $mrd (local.get $pc))) (local.set $pc (i32.and (i32.add (local.get $pc) (i32.const 1)) (i32.const 0xfff)))
        (local.set $r (i32.and (i32.add (call $zr (i32.add (i32.const 2) (local.get $lo))) (i32.const 1)) (i32.const 15)))
        (call $zw (i32.add (i32.const 2) (local.get $lo)) (local.get $r))
        (if (local.get $r) (then (local.set $pc (i32.or (i32.and (local.get $pc) (i32.const 0xf00)) (local.get $t)))))
        (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 8)) (then (call $acc4add (i32.add (call $zr (i32.add (i32.const 2) (local.get $lo))) (local.get $cy))) (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 9)) (then (call $acc4add (i32.add (i32.xor (call $zr (i32.add (i32.const 2) (local.get $lo))) (i32.const 15)) (i32.xor (local.get $cy) (i32.const 1)))) (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 10)) (then (call $zw (i32.const 0) (call $zr (i32.add (i32.const 2) (local.get $lo)))) (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 11)) (then (call $zw (i32.const 0) (call $zr (i32.add (i32.const 2) (local.get $lo)))) (call $zw (i32.add (i32.const 2) (local.get $lo)) (local.get $acc)) (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 12)) (then   ;; BBL
        (call $zw (i32.const 19) (i32.rem_u (i32.add (call $zr (i32.const 19)) (i32.const 2)) (i32.const 3)))
        (local.set $pc (call $zr16 (i32.add (i32.const 32) (i32.shl (call $zr (i32.const 19)) (i32.const 1)))))
        (call $zw (i32.const 0) (local.get $lo)) (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 13)) (then (call $zw (i32.const 0) (local.get $lo)) (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 14)) (then   ;; RAM group
        (local.set $t (call $zr (i32.const 18)))
        (if (i32.eqz (local.get $lo)) (then (call $ram4w (local.get $t) (local.get $acc))))                                                 ;; WRM
        (if (i32.eq (local.get $lo) (i32.const 8)) (then (call $acc4add (i32.add (i32.xor (call $ram4 (local.get $t)) (i32.const 15)) (i32.xor (local.get $cy) (i32.const 1))))))   ;; SBM
        (if (i32.eq (local.get $lo) (i32.const 9)) (then (call $zw (i32.const 0) (call $ram4 (local.get $t)))))                              ;; RDM
        (if (i32.eq (local.get $lo) (i32.const 11)) (then (call $acc4add (i32.add (call $ram4 (local.get $t)) (local.get $cy)))))            ;; ADM
        (br $end)))
      ;; accumulator group (F)
      (if (i32.eqz (local.get $lo)) (then (call $zw (i32.const 0) (i32.const 0)) (call $zw (i32.const 1) (i32.const 0)) (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 1)) (then (call $zw (i32.const 1) (i32.const 0)) (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 2)) (then (call $acc4add (i32.const 1)) (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 3)) (then (call $zw (i32.const 1) (i32.xor (local.get $cy) (i32.const 1))) (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 4)) (then (call $zw (i32.const 0) (i32.xor (local.get $acc) (i32.const 15))) (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 5)) (then (call $zw (i32.const 0) (i32.and (i32.or (i32.shl (local.get $acc) (i32.const 1)) (local.get $cy)) (i32.const 15))) (call $zw (i32.const 1) (i32.shr_u (local.get $acc) (i32.const 3))) (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 6)) (then (call $zw (i32.const 0) (i32.or (i32.shr_u (local.get $acc) (i32.const 1)) (i32.shl (local.get $cy) (i32.const 3)))) (call $zw (i32.const 1) (i32.and (local.get $acc) (i32.const 1))) (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 7)) (then (call $zw (i32.const 0) (local.get $cy)) (call $zw (i32.const 1) (i32.const 0)) (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 8)) (then (call $zw (i32.const 0) (i32.and (i32.sub (local.get $acc) (i32.const 1)) (i32.const 15))) (call $zw (i32.const 1) (i32.ne (local.get $acc) (i32.const 0))) (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 9)) (then (call $zw (i32.const 0) (select (i32.const 10) (i32.const 9) (local.get $cy))) (call $zw (i32.const 1) (i32.const 0)) (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 10)) (then (call $zw (i32.const 1) (i32.const 1)) (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 11)) (then   ;; DAA
        (if (i32.or (i32.gt_u (local.get $acc) (i32.const 9)) (local.get $cy)) (then
          (local.set $r (i32.add (local.get $acc) (i32.const 6)))
          (call $zw (i32.const 0) (i32.and (local.get $r) (i32.const 15)))
          (if (i32.gt_u (local.get $r) (i32.const 15)) (then (call $zw (i32.const 1) (i32.const 1))))))
        (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 12)) (then   ;; KBP
        (call $zw (i32.const 0) (select (local.get $acc) (select (i32.const 3) (select (i32.const 4) (i32.const 15) (i32.eq (local.get $acc) (i32.const 8))) (i32.eq (local.get $acc) (i32.const 4))) (i32.lt_u (local.get $acc) (i32.const 3))))
        (br $end))))
    (call $zw16 (i32.const 22) (local.get $pc)))
