  ;; ========================================================================
  ;; Subleq (kind 9): one instruction, three byte operands a b c at PC.
  ;; mem[b] -= mem[a]; if the result is <= 0 (signed byte) jump to c, else PC += 3.
  (func $subleq_step
    (local $pc i32) (local $a i32) (local $b i32) (local $c i32) (local $v i32)
    (local.set $pc (call $zr16 (i32.const 22)))
    (local.set $a (call $mrd (local.get $pc))) (local.set $b (call $mrd (i32.add (local.get $pc) (i32.const 1)))) (local.set $c (call $mrd (i32.add (local.get $pc) (i32.const 2))))
    (local.set $v (i32.and (i32.sub (call $mrd (local.get $b)) (call $mrd (local.get $a))) (i32.const 255)))
    (call $mwr (local.get $b) (local.get $v))
    (call $zw16 (i32.const 22) (i32.and
      (select (local.get $c) (i32.add (local.get $pc) (i32.const 3)) (i32.or (i32.eqz (local.get $v)) (i32.and (local.get $v) (i32.const 0x80))))
      (i32.const 0xffff))))

  ;; ========================================================================
  ;; CHIP-8 (kind 10). Register file: V0..VF at 0..15, I at 16 (u16), PC at 22,
  ;; SP at 24, delay timer 26, sound timer 27, xorshift state at 28 (u32), stack
  ;; (16 x u16) at 32. Big-endian 2-byte instructions, PC starts at 0. There is
  ;; no display and no keypad: 00E0 and DXYN do nothing (VF cleared), EX9E never
  ;; skips, EXA1 always skips, FX0A (wait for key) is a NOP.
  (func $chip8_step
    (local $pc i32) (local $op i32) (local $x i32) (local $y i32) (local $n i32) (local $nn i32) (local $nnn i32) (local $vx i32) (local $vy i32) (local $t i32) (local $i i32)
    (local.set $pc (call $zr16 (i32.const 22)))
    (local.set $op (i32.or (i32.shl (call $mrd (local.get $pc)) (i32.const 8)) (call $mrd (i32.add (local.get $pc) (i32.const 1)))))
    (local.set $pc (i32.and (i32.add (local.get $pc) (i32.const 2)) (i32.const 0xffff)))
    (local.set $x (i32.and (i32.shr_u (local.get $op) (i32.const 8)) (i32.const 15))) (local.set $y (i32.and (i32.shr_u (local.get $op) (i32.const 4)) (i32.const 15)))
    (local.set $n (i32.and (local.get $op) (i32.const 15))) (local.set $nn (i32.and (local.get $op) (i32.const 255))) (local.set $nnn (i32.and (local.get $op) (i32.const 0xfff)))
    (local.set $vx (call $zr (local.get $x))) (local.set $vy (call $zr (local.get $y)))
    ;; timers tick once per instruction
    (if (call $zr (i32.const 26)) (then (call $zw (i32.const 26) (i32.sub (call $zr (i32.const 26)) (i32.const 1)))))
    (if (call $zr (i32.const 27)) (then (call $zw (i32.const 27) (i32.sub (call $zr (i32.const 27)) (i32.const 1)))))
    (block $end
      (local.set $t (i32.shr_u (local.get $op) (i32.const 12)))
      (if (i32.eqz (local.get $t)) (then
        (if (i32.eq (local.get $op) (i32.const 0x00EE)) (then   ;; RET
          (call $zw (i32.const 24) (i32.and (i32.sub (call $zr (i32.const 24)) (i32.const 1)) (i32.const 15)))
          (local.set $pc (call $zr16 (i32.add (i32.const 32) (i32.shl (call $zr (i32.const 24)) (i32.const 1)))))))
        (br $end)))
      (if (i32.eq (local.get $t) (i32.const 1)) (then (local.set $pc (local.get $nnn)) (br $end)))
      (if (i32.eq (local.get $t) (i32.const 2)) (then   ;; CALL
        (call $zw16 (i32.add (i32.const 32) (i32.shl (call $zr (i32.const 24)) (i32.const 1))) (local.get $pc))
        (call $zw (i32.const 24) (i32.and (i32.add (call $zr (i32.const 24)) (i32.const 1)) (i32.const 15)))
        (local.set $pc (local.get $nnn)) (br $end)))
      (if (i32.eq (local.get $t) (i32.const 3)) (then (if (i32.eq (local.get $vx) (local.get $nn)) (then (local.set $pc (i32.add (local.get $pc) (i32.const 2))))) (br $end)))
      (if (i32.eq (local.get $t) (i32.const 4)) (then (if (i32.ne (local.get $vx) (local.get $nn)) (then (local.set $pc (i32.add (local.get $pc) (i32.const 2))))) (br $end)))
      (if (i32.eq (local.get $t) (i32.const 5)) (then (if (i32.eq (local.get $vx) (local.get $vy)) (then (local.set $pc (i32.add (local.get $pc) (i32.const 2))))) (br $end)))
      (if (i32.eq (local.get $t) (i32.const 6)) (then (call $zw (local.get $x) (local.get $nn)) (br $end)))
      (if (i32.eq (local.get $t) (i32.const 7)) (then (call $zw (local.get $x) (i32.and (i32.add (local.get $vx) (local.get $nn)) (i32.const 255))) (br $end)))
      (if (i32.eq (local.get $t) (i32.const 8)) (then
        (if (i32.eqz (local.get $n)) (then (call $zw (local.get $x) (local.get $vy)) (br $end)))
        (if (i32.eq (local.get $n) (i32.const 1)) (then (call $zw (local.get $x) (i32.or (local.get $vx) (local.get $vy))) (br $end)))
        (if (i32.eq (local.get $n) (i32.const 2)) (then (call $zw (local.get $x) (i32.and (local.get $vx) (local.get $vy))) (br $end)))
        (if (i32.eq (local.get $n) (i32.const 3)) (then (call $zw (local.get $x) (i32.xor (local.get $vx) (local.get $vy))) (br $end)))
        (if (i32.eq (local.get $n) (i32.const 4)) (then (local.set $i (i32.add (local.get $vx) (local.get $vy))) (call $zw (local.get $x) (i32.and (local.get $i) (i32.const 255))) (call $zw (i32.const 15) (i32.shr_u (local.get $i) (i32.const 8))) (br $end)))
        (if (i32.eq (local.get $n) (i32.const 5)) (then (call $zw (local.get $x) (i32.and (i32.sub (local.get $vx) (local.get $vy)) (i32.const 255))) (call $zw (i32.const 15) (i32.ge_u (local.get $vx) (local.get $vy))) (br $end)))
        (if (i32.eq (local.get $n) (i32.const 6)) (then (call $zw (local.get $x) (i32.shr_u (local.get $vx) (i32.const 1))) (call $zw (i32.const 15) (i32.and (local.get $vx) (i32.const 1))) (br $end)))
        (if (i32.eq (local.get $n) (i32.const 7)) (then (call $zw (local.get $x) (i32.and (i32.sub (local.get $vy) (local.get $vx)) (i32.const 255))) (call $zw (i32.const 15) (i32.ge_u (local.get $vy) (local.get $vx))) (br $end)))
        (if (i32.eq (local.get $n) (i32.const 14)) (then (call $zw (local.get $x) (i32.and (i32.shl (local.get $vx) (i32.const 1)) (i32.const 255))) (call $zw (i32.const 15) (i32.shr_u (local.get $vx) (i32.const 7))) (br $end)))
        (br $end)))
      (if (i32.eq (local.get $t) (i32.const 9)) (then (if (i32.ne (local.get $vx) (local.get $vy)) (then (local.set $pc (i32.add (local.get $pc) (i32.const 2))))) (br $end)))
      (if (i32.eq (local.get $t) (i32.const 10)) (then (call $zw16 (i32.const 16) (local.get $nnn)) (br $end)))
      (if (i32.eq (local.get $t) (i32.const 11)) (then (local.set $pc (i32.add (local.get $nnn) (call $zr (i32.const 0)))) (br $end)))
      (if (i32.eq (local.get $t) (i32.const 12)) (then   ;; CXNN: xorshift32
        (local.set $i (i32.load offset=284 (i32.const 0)))
        (if (i32.eqz (local.get $i)) (then (local.set $i (i32.const 0x2545F491))))
        (local.set $i (i32.xor (local.get $i) (i32.shl (local.get $i) (i32.const 13)))) (local.set $i (i32.xor (local.get $i) (i32.shr_u (local.get $i) (i32.const 17)))) (local.set $i (i32.xor (local.get $i) (i32.shl (local.get $i) (i32.const 5))))
        (i32.store offset=284 (i32.const 0) (local.get $i))
        (call $zw (local.get $x) (i32.and (i32.and (local.get $i) (i32.const 255)) (local.get $nn))) (br $end)))
      (if (i32.eq (local.get $t) (i32.const 13)) (then (call $zw (i32.const 15) (i32.const 0)) (br $end)))   ;; DXYN: no display
      (if (i32.eq (local.get $t) (i32.const 14)) (then (if (i32.eq (local.get $nn) (i32.const 0xA1)) (then (local.set $pc (i32.add (local.get $pc) (i32.const 2))))) (br $end)))
      ;; F
      (if (i32.eq (local.get $nn) (i32.const 0x07)) (then (call $zw (local.get $x) (call $zr (i32.const 26))) (br $end)))
      (if (i32.eq (local.get $nn) (i32.const 0x15)) (then (call $zw (i32.const 26) (local.get $vx)) (br $end)))
      (if (i32.eq (local.get $nn) (i32.const 0x18)) (then (call $zw (i32.const 27) (local.get $vx)) (br $end)))
      (if (i32.eq (local.get $nn) (i32.const 0x1E)) (then (call $zw16 (i32.const 16) (i32.and (i32.add (call $zr16 (i32.const 16)) (local.get $vx)) (i32.const 0xffff))) (br $end)))
      (if (i32.eq (local.get $nn) (i32.const 0x29)) (then (call $zw16 (i32.const 16) (i32.mul (i32.and (local.get $vx) (i32.const 15)) (i32.const 5))) (br $end)))
      (if (i32.eq (local.get $nn) (i32.const 0x33)) (then   ;; BCD
        (local.set $i (call $zr16 (i32.const 16)))
        (call $mwr (local.get $i) (i32.div_u (local.get $vx) (i32.const 100)))
        (call $mwr (i32.add (local.get $i) (i32.const 1)) (i32.rem_u (i32.div_u (local.get $vx) (i32.const 10)) (i32.const 10)))
        (call $mwr (i32.add (local.get $i) (i32.const 2)) (i32.rem_u (local.get $vx) (i32.const 10)))
        (br $end)))
      (if (i32.or (i32.eq (local.get $nn) (i32.const 0x55)) (i32.eq (local.get $nn) (i32.const 0x65))) (then
        (local.set $i (i32.const 0))
        (block $le (loop $ll (br_if $le (i32.gt_u (local.get $i) (local.get $x)))
          (if (i32.eq (local.get $nn) (i32.const 0x55))
            (then (call $mwr (i32.add (call $zr16 (i32.const 16)) (local.get $i)) (call $zr (local.get $i))))
            (else (call $zw (local.get $i) (call $mrd (i32.add (call $zr16 (i32.const 16)) (local.get $i))))))
          (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $ll)))
        (br $end))))
    (call $zw16 (i32.const 22) (i32.and (local.get $pc) (i32.const 0xffff))))

  ;; ========================================================================
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

  ;; ========================================================================
  ;; Game Boy SM83 (kind 12). Register file as the 8080/Z80 (C B E D L H F A at
  ;; 0..7, SP 20, PC 22); flags Z 0x80 N 0x40 H 0x20 C 0x10. HALT and STOP are
  ;; NOPs, DI/EI do nothing, invalid opcodes are NOPs, LDH/LD (C) addresses wrap
  ;; into the 16 bytes like everything else.
  (func $gbf (param $z i32) (param $n i32) (param $h i32) (param $c i32) (result i32)
    (i32.or (i32.or (select (i32.const 0x80) (i32.const 0) (local.get $z)) (select (i32.const 0x40) (i32.const 0) (local.get $n)))
            (i32.or (select (i32.const 0x20) (i32.const 0) (local.get $h)) (select (i32.const 0x10) (i32.const 0) (local.get $c)))))
  (func $alu_gb (param $op i32) (param $b i32)
    (local $a i32) (local $r i32) (local $c i32)
    (local.set $a (call $zr (i32.const 7))) (local.set $c (i32.and (i32.shr_u (call $zr (i32.const 6)) (i32.const 4)) (i32.const 1)))
    (if (i32.lt_u (local.get $op) (i32.const 2)) (then
      (if (i32.eqz (local.get $op)) (then (local.set $c (i32.const 0))))
      (local.set $r (i32.add (i32.add (local.get $a) (local.get $b)) (local.get $c)))
      (call $zw (i32.const 7) (i32.and (local.get $r) (i32.const 255)))
      (call $zw (i32.const 6) (call $gbf (i32.eqz (i32.and (local.get $r) (i32.const 255))) (i32.const 0)
        (i32.gt_u (i32.add (i32.add (i32.and (local.get $a) (i32.const 15)) (i32.and (local.get $b) (i32.const 15))) (local.get $c)) (i32.const 15)) (i32.gt_u (local.get $r) (i32.const 255))))
      (return)))
    (if (i32.or (i32.lt_u (local.get $op) (i32.const 4)) (i32.eq (local.get $op) (i32.const 7))) (then
      (if (i32.ne (local.get $op) (i32.const 3)) (then (local.set $c (i32.const 0))))
      (local.set $r (i32.sub (i32.sub (local.get $a) (local.get $b)) (local.get $c)))
      (if (i32.ne (local.get $op) (i32.const 7)) (then (call $zw (i32.const 7) (i32.and (local.get $r) (i32.const 255)))))
      (call $zw (i32.const 6) (call $gbf (i32.eqz (i32.and (local.get $r) (i32.const 255))) (i32.const 1)
        (i32.lt_s (i32.sub (i32.sub (i32.and (local.get $a) (i32.const 15)) (i32.and (local.get $b) (i32.const 15))) (local.get $c)) (i32.const 0)) (i32.lt_s (local.get $r) (i32.const 0))))
      (return)))
    (local.set $r (select (i32.and (local.get $a) (local.get $b)) (select (i32.xor (local.get $a) (local.get $b)) (i32.or (local.get $a) (local.get $b)) (i32.eq (local.get $op) (i32.const 5))) (i32.eq (local.get $op) (i32.const 4))))
    (call $zw (i32.const 7) (local.get $r))
    (call $zw (i32.const 6) (call $gbf (i32.eqz (local.get $r)) (i32.const 0) (i32.eq (local.get $op) (i32.const 4)) (i32.const 0))))
  (func $rot_gb (param $op i32) (param $v i32) (result i32)   ;; 0 RLC 1 RRC 2 RL 3 RR 4 SLA 5 SRA 6 SWAP 7 SRL; sets Z and C
    (local $r i32) (local $c i32) (local $cf i32)
    (local.set $cf (i32.and (i32.shr_u (call $zr (i32.const 6)) (i32.const 4)) (i32.const 1)))
    (if (i32.eq (local.get $op) (i32.const 6))
      (then (local.set $r (i32.or (i32.shr_u (local.get $v) (i32.const 4)) (i32.shl (i32.and (local.get $v) (i32.const 15)) (i32.const 4)))) (local.set $c (i32.const 0)))
      (else
        (local.set $c (select (i32.and (local.get $v) (i32.const 1)) (i32.shr_u (local.get $v) (i32.const 7)) (i32.and (local.get $op) (i32.const 1))))
        (local.set $r (select (i32.or (i32.shl (local.get $v) (i32.const 1)) (i32.shr_u (local.get $v) (i32.const 7)))
          (select (i32.or (i32.shr_u (local.get $v) (i32.const 1)) (i32.shl (local.get $v) (i32.const 7)))
          (select (i32.or (i32.shl (local.get $v) (i32.const 1)) (local.get $cf))
          (select (i32.or (i32.shr_u (local.get $v) (i32.const 1)) (i32.shl (local.get $cf) (i32.const 7)))
          (select (i32.shl (local.get $v) (i32.const 1))
          (select (i32.or (i32.shr_u (local.get $v) (i32.const 1)) (i32.and (local.get $v) (i32.const 0x80)))
                  (i32.shr_u (local.get $v) (i32.const 1))
          (i32.eq (local.get $op) (i32.const 5))) (i32.eq (local.get $op) (i32.const 4))) (i32.eq (local.get $op) (i32.const 3))) (i32.eq (local.get $op) (i32.const 2))) (i32.eq (local.get $op) (i32.const 1))) (i32.eqz (local.get $op))))))
    (local.set $r (i32.and (local.get $r) (i32.const 255)))
    (call $zw (i32.const 6) (call $gbf (i32.eqz (local.get $r)) (i32.const 0) (i32.const 0) (local.get $c)))
    (local.get $r))
  (func $cc_gb (param $y i32) (result i32)   ;; NZ Z NC C
    (local $f i32) (local.set $f (call $zr (i32.const 6)))
    (i32.eq (i32.ne (i32.and (local.get $f) (select (i32.const 0x80) (i32.const 0x10) (i32.lt_u (local.get $y) (i32.const 2)))) (i32.const 0)) (i32.and (local.get $y) (i32.const 1))))
  (func $sm83_step
    (local $op i32) (local $x i32) (local $y i32) (local $z i32) (local $p i32) (local $q i32) (local $t i32) (local $v i32) (local $hl i32) (local $f i32) (local $sp i32) (local $e i32)
    (local.set $op (call $fetch))
    (local.set $x (i32.shr_u (local.get $op) (i32.const 6))) (local.set $y (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 7)))
    (local.set $z (i32.and (local.get $op) (i32.const 7))) (local.set $p (i32.shr_u (local.get $y) (i32.const 1))) (local.set $q (i32.and (local.get $y) (i32.const 1)))
    (local.set $hl (call $zr16 (i32.const 4))) (local.set $f (call $zr (i32.const 6)))
    (block $end
      (if (i32.eq (local.get $x) (i32.const 1)) (then
        (if (i32.eq (local.get $op) (i32.const 0x76)) (then (br $end)))
        (call $setr (local.get $y) (local.get $hl) (call $getr (local.get $z) (local.get $hl))) (br $end)))
      (if (i32.eq (local.get $x) (i32.const 2)) (then (call $alu_gb (local.get $y) (call $getr (local.get $z) (local.get $hl))) (br $end)))
      (if (i32.eqz (local.get $x)) (then
        (if (i32.eqz (local.get $z)) (then
          (if (i32.eq (local.get $y) (i32.const 1)) (then (call $mwr16 (call $fetch16) (call $zr16 (i32.const 20))) (br $end)))   ;; LD (nn),SP
          (if (i32.lt_u (local.get $y) (i32.const 3)) (then (br $end)))   ;; NOP, STOP
          (local.set $e (call $sext8 (call $fetch)))
          (if (i32.or (i32.eq (local.get $y) (i32.const 3)) (call $cc_gb (i32.sub (local.get $y) (i32.const 4))))
            (then (call $zw16 (i32.const 22) (i32.and (i32.add (call $zr16 (i32.const 22)) (local.get $e)) (i32.const 0xffff)))))
          (br $end)))
        (if (i32.eq (local.get $z) (i32.const 1)) (then
          (if (local.get $q)
            (then   ;; ADD HL,rp: N 0, H from bit 11, C from bit 15, Z kept
              (local.set $v (call $zr16 (call $rpoff (local.get $p)))) (local.set $t (i32.add (local.get $hl) (local.get $v)))
              (call $zw16 (i32.const 4) (i32.and (local.get $t) (i32.const 0xffff)))
              (call $zw (i32.const 6) (i32.or (i32.and (local.get $f) (i32.const 0x80)) (call $gbf (i32.const 0) (i32.const 0)
                (i32.gt_u (i32.add (i32.and (local.get $hl) (i32.const 0xfff)) (i32.and (local.get $v) (i32.const 0xfff))) (i32.const 0xfff)) (i32.gt_u (local.get $t) (i32.const 0xffff))))))
            (else (call $zw16 (call $rpoff (local.get $p)) (call $fetch16))))
          (br $end)))
        (if (i32.eq (local.get $z) (i32.const 2)) (then   ;; (BC) (DE) (HL+) (HL-)
          (local.set $t (select (call $zr16 (i32.const 0)) (select (call $zr16 (i32.const 2)) (local.get $hl) (i32.eq (local.get $p) (i32.const 1))) (i32.eqz (local.get $p))))
          (if (local.get $q) (then (call $zw (i32.const 7) (call $mrd (local.get $t)))) (else (call $mwr (local.get $t) (call $zr (i32.const 7)))))
          (if (i32.eq (local.get $p) (i32.const 2)) (then (call $zw16 (i32.const 4) (i32.and (i32.add (local.get $hl) (i32.const 1)) (i32.const 0xffff)))))
          (if (i32.eq (local.get $p) (i32.const 3)) (then (call $zw16 (i32.const 4) (i32.and (i32.sub (local.get $hl) (i32.const 1)) (i32.const 0xffff)))))
          (br $end)))
        (if (i32.eq (local.get $z) (i32.const 3)) (then
          (local.set $t (call $rpoff (local.get $p)))
          (call $zw16 (local.get $t) (i32.and (i32.add (call $zr16 (local.get $t)) (select (i32.const -1) (i32.const 1) (local.get $q))) (i32.const 0xffff)))
          (br $end)))
        (if (i32.lt_u (local.get $z) (i32.const 6)) (then   ;; INC r / DEC r: Z N H, C kept
          (local.set $v (call $getr (local.get $y) (local.get $hl)))
          (local.set $t (i32.and (i32.add (local.get $v) (select (i32.const 1) (i32.const -1) (i32.eq (local.get $z) (i32.const 4)))) (i32.const 255)))
          (call $setr (local.get $y) (local.get $hl) (local.get $t))
          (call $zw (i32.const 6) (i32.or (i32.and (local.get $f) (i32.const 0x10)) (call $gbf (i32.eqz (local.get $t)) (i32.eq (local.get $z) (i32.const 5))
            (select (i32.eqz (i32.and (local.get $t) (i32.const 15))) (i32.eq (i32.and (local.get $t) (i32.const 15)) (i32.const 15)) (i32.eq (local.get $z) (i32.const 4))) (i32.const 0))))
          (br $end)))
        (if (i32.eq (local.get $z) (i32.const 6)) (then (call $setr (local.get $y) (local.get $hl) (call $fetch)) (br $end)))
        ;; z = 7: RLCA RRCA RLA RRA DAA CPL SCF CCF
        (if (i32.lt_u (local.get $y) (i32.const 4)) (then
          (call $zw (i32.const 7) (call $rot_gb (local.get $y) (call $zr (i32.const 7))))
          (call $zw (i32.const 6) (i32.and (call $zr (i32.const 6)) (i32.const 0x10)))   ;; Z cleared on the A-register rotates
          (br $end)))
        (if (i32.eq (local.get $y) (i32.const 4)) (then   ;; DAA
          (local.set $v (call $zr (i32.const 7))) (local.set $t (i32.const 0)) (local.set $e (i32.and (local.get $f) (i32.const 0x10)))
          (if (i32.and (local.get $f) (i32.const 0x40))
            (then
              (if (i32.and (local.get $f) (i32.const 0x20)) (then (local.set $t (i32.const 6))))
              (if (local.get $e) (then (local.set $t (i32.or (local.get $t) (i32.const 0x60)))))
              (local.set $v (i32.and (i32.sub (local.get $v) (local.get $t)) (i32.const 255))))
            (else
              (if (i32.or (i32.and (local.get $f) (i32.const 0x20)) (i32.gt_u (i32.and (local.get $v) (i32.const 15)) (i32.const 9))) (then (local.set $t (i32.const 6))))
              (if (i32.or (local.get $e) (i32.gt_u (local.get $v) (i32.const 0x99))) (then (local.set $t (i32.or (local.get $t) (i32.const 0x60))) (local.set $e (i32.const 1))))
              (local.set $v (i32.and (i32.add (local.get $v) (local.get $t)) (i32.const 255)))))
          (call $zw (i32.const 7) (local.get $v))
          (call $zw (i32.const 6) (call $gbf (i32.eqz (local.get $v)) (i32.and (local.get $f) (i32.const 0x40)) (i32.const 0) (local.get $e)))
          (br $end)))
        (if (i32.eq (local.get $y) (i32.const 5)) (then (call $zw (i32.const 7) (i32.xor (call $zr (i32.const 7)) (i32.const 255))) (call $zw (i32.const 6) (i32.or (local.get $f) (i32.const 0x60))) (br $end)))
        (if (i32.eq (local.get $y) (i32.const 6)) (then (call $zw (i32.const 6) (i32.or (i32.and (local.get $f) (i32.const 0x80)) (i32.const 0x10))) (br $end)))
        (call $zw (i32.const 6) (i32.or (i32.and (local.get $f) (i32.const 0x80)) (i32.xor (i32.and (local.get $f) (i32.const 0x10)) (i32.const 0x10))))
        (br $end)))
      ;; x = 3
      (if (i32.eqz (local.get $z)) (then
        (if (i32.lt_u (local.get $y) (i32.const 4)) (then (if (call $cc_gb (local.get $y)) (then (call $zw16 (i32.const 22) (call $pop)))) (br $end)))
        (if (i32.eq (local.get $y) (i32.const 4)) (then (call $mwr (i32.add (i32.const 0xFF00) (call $fetch)) (call $zr (i32.const 7))) (br $end)))
        (if (i32.eq (local.get $y) (i32.const 6)) (then (call $zw (i32.const 7) (call $mrd (i32.add (i32.const 0xFF00) (call $fetch)))) (br $end)))
        ;; ADD SP,e / LD HL,SP+e
        (local.set $e (call $sext8 (call $fetch))) (local.set $sp (call $zr16 (i32.const 20)))
        (local.set $t (i32.and (i32.add (local.get $sp) (local.get $e)) (i32.const 0xffff)))
        (call $zw (i32.const 6) (call $gbf (i32.const 0) (i32.const 0)
          (i32.gt_u (i32.add (i32.and (local.get $sp) (i32.const 15)) (i32.and (local.get $e) (i32.const 15))) (i32.const 15))
          (i32.gt_u (i32.add (i32.and (local.get $sp) (i32.const 255)) (i32.and (local.get $e) (i32.const 255))) (i32.const 255))))
        (call $zw16 (select (i32.const 20) (i32.const 4) (i32.eq (local.get $y) (i32.const 5))) (local.get $t))
        (br $end)))
      (if (i32.eq (local.get $z) (i32.const 1)) (then
        (if (i32.eqz (local.get $q)) (then
          (call $zw16 (call $rp2off (local.get $p)) (call $pop))
          (if (i32.eq (local.get $p) (i32.const 3)) (then (call $zw (i32.const 6) (i32.and (call $zr (i32.const 6)) (i32.const 0xF0)))))
          (br $end)))
        (if (i32.lt_u (local.get $p) (i32.const 2)) (then (call $zw16 (i32.const 22) (call $pop)) (br $end)))   ;; RET / RETI
        (if (i32.eq (local.get $p) (i32.const 2)) (then (call $zw16 (i32.const 22) (local.get $hl)) (br $end)))
        (call $zw16 (i32.const 20) (local.get $hl)) (br $end)))
      (if (i32.eq (local.get $z) (i32.const 2)) (then
        (if (i32.lt_u (local.get $y) (i32.const 4)) (then (local.set $t (call $fetch16)) (if (call $cc_gb (local.get $y)) (then (call $zw16 (i32.const 22) (local.get $t)))) (br $end)))
        (if (i32.eq (local.get $y) (i32.const 4)) (then (call $mwr (i32.add (i32.const 0xFF00) (call $zr (i32.const 0))) (call $zr (i32.const 7))) (br $end)))
        (if (i32.eq (local.get $y) (i32.const 5)) (then (call $mwr (call $fetch16) (call $zr (i32.const 7))) (br $end)))
        (if (i32.eq (local.get $y) (i32.const 6)) (then (call $zw (i32.const 7) (call $mrd (i32.add (i32.const 0xFF00) (call $zr (i32.const 0))))) (br $end)))
        (call $zw (i32.const 7) (call $mrd (call $fetch16))) (br $end)))
      (if (i32.eq (local.get $z) (i32.const 3)) (then
        (if (i32.eqz (local.get $y)) (then (call $zw16 (i32.const 22) (call $fetch16)) (br $end)))
        (if (i32.eq (local.get $y) (i32.const 1)) (then   ;; CB prefix
          (local.set $op (call $fetch)) (local.set $z (i32.and (local.get $op) (i32.const 7))) (local.set $x (i32.shr_u (local.get $op) (i32.const 6))) (local.set $y (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 7)))
          (local.set $v (call $getr (local.get $z) (local.get $hl)))
          (if (i32.eqz (local.get $x)) (then (call $setr (local.get $z) (local.get $hl) (call $rot_gb (local.get $y) (local.get $v))) (br $end)))
          (if (i32.eq (local.get $x) (i32.const 1)) (then   ;; BIT
            (call $zw (i32.const 6) (i32.or (i32.and (call $zr (i32.const 6)) (i32.const 0x10)) (call $gbf (i32.eqz (i32.and (local.get $v) (i32.shl (i32.const 1) (local.get $y)))) (i32.const 0) (i32.const 1) (i32.const 0))))
            (br $end)))
          (call $setr (local.get $z) (local.get $hl) (select (i32.and (local.get $v) (i32.xor (i32.shl (i32.const 1) (local.get $y)) (i32.const 255))) (i32.or (local.get $v) (i32.shl (i32.const 1) (local.get $y))) (i32.eq (local.get $x) (i32.const 2))))
          (br $end)))
        (br $end)))   ;; invalid, DI, EI
      (if (i32.eq (local.get $z) (i32.const 4)) (then
        (if (i32.lt_u (local.get $y) (i32.const 4)) (then (local.set $t (call $fetch16)) (if (call $cc_gb (local.get $y)) (then (call $push (call $zr16 (i32.const 22))) (call $zw16 (i32.const 22) (local.get $t))))))
        (br $end)))
      (if (i32.eq (local.get $z) (i32.const 5)) (then
        (if (i32.eqz (local.get $q)) (then (call $push (call $zr16 (call $rp2off (local.get $p)))) (br $end)))
        (if (i32.eqz (local.get $p)) (then (local.set $t (call $fetch16)) (call $push (call $zr16 (i32.const 22))) (call $zw16 (i32.const 22) (local.get $t))))
        (br $end)))
      (if (i32.eq (local.get $z) (i32.const 6)) (then (call $alu_gb (local.get $y) (call $fetch)) (br $end)))
      (call $push (call $zr16 (i32.const 22)))
      (call $zw16 (i32.const 22) (i32.shl (local.get $y) (i32.const 3)))))
