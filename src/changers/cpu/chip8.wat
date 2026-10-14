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
