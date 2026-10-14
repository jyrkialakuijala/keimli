  ;; ========================================================================
  ;; Intel 8080 byte processor. Same conventions as the Z80 core (16-byte address
  ;; space wrapping mod 16, registers zeroed, 256 instructions, HLT/DI/EI/IN/OUT
  ;; are NOPs) and the same register file layout, so it reuses $fetch, $push,
  ;; $pop, $getr/$setr (prefix byte stays 0, so (HL) is always HL), $cc and $swap.
  ;; Flags are 8080 flags: S Z 0 AC 0 P 1 CY, with P always parity.
  (func $f80 (param $r i32) (param $ac i32) (param $cy i32) (result i32)   ;; build an 8080 flag byte
    (i32.or (i32.or (i32.and (local.get $r) (i32.const 0x80)) (select (i32.const 0x40) (i32.const 0) (i32.eqz (i32.and (local.get $r) (i32.const 255)))))
      (i32.or (i32.or (select (i32.const 0x10) (i32.const 0) (local.get $ac)) (select (i32.const 4) (i32.const 0) (i32.eqz (i32.and (i32.popcnt (i32.and (local.get $r) (i32.const 255))) (i32.const 1)))))
              (i32.or (i32.const 2) (select (i32.const 1) (i32.const 0) (local.get $cy))))))
  (func $alu80 (param $op i32) (param $b i32)
    (local $a i32) (local $r i32) (local $c i32) (local $ac i32)
    (local.set $a (call $zr (i32.const 7))) (local.set $c (i32.and (call $zr (i32.const 6)) (i32.const 1)))
    (if (i32.lt_u (local.get $op) (i32.const 2)) (then
      (local.set $r (i32.add (i32.add (local.get $a) (local.get $b)) (select (local.get $c) (i32.const 0) (local.get $op))))
      (call $zw (i32.const 7) (i32.and (local.get $r) (i32.const 255)))
      (call $zw (i32.const 6) (call $f80 (local.get $r) (i32.and (i32.xor (i32.xor (local.get $a) (local.get $b)) (local.get $r)) (i32.const 0x10)) (i32.and (local.get $r) (i32.const 0x100))))
      (return)))
    (if (i32.or (i32.lt_u (local.get $op) (i32.const 4)) (i32.eq (local.get $op) (i32.const 7))) (then
      (local.set $r (i32.sub (i32.sub (local.get $a) (local.get $b)) (select (local.get $c) (i32.const 0) (i32.eq (local.get $op) (i32.const 3)))))
      (if (i32.ne (local.get $op) (i32.const 7)) (then (call $zw (i32.const 7) (i32.and (local.get $r) (i32.const 255)))))
      (call $zw (i32.const 6) (call $f80 (local.get $r) (i32.eqz (i32.and (i32.xor (i32.xor (local.get $a) (local.get $b)) (local.get $r)) (i32.const 0x10))) (i32.and (local.get $r) (i32.const 0x100))))
      (return)))
    (if (i32.eq (local.get $op) (i32.const 4))
      (then (local.set $r (i32.and (local.get $a) (local.get $b))) (local.set $ac (i32.and (i32.or (local.get $a) (local.get $b)) (i32.const 8))))
      (else (local.set $r (select (i32.xor (local.get $a) (local.get $b)) (i32.or (local.get $a) (local.get $b)) (i32.eq (local.get $op) (i32.const 5))))))
    (call $zw (i32.const 7) (local.get $r))
    (call $zw (i32.const 6) (call $f80 (local.get $r) (local.get $ac) (i32.const 0))))
  (func $i8080step
    (local $op i32) (local $x i32) (local $y i32) (local $z i32) (local $p i32) (local $q i32) (local $t i32) (local $v i32) (local $hl i32) (local $f i32)
    (local.set $op (call $fetch))
    (local.set $x (i32.shr_u (local.get $op) (i32.const 6))) (local.set $y (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 7)))
    (local.set $z (i32.and (local.get $op) (i32.const 7))) (local.set $p (i32.shr_u (local.get $y) (i32.const 1))) (local.set $q (i32.and (local.get $y) (i32.const 1)))
    (local.set $hl (call $zr16 (i32.const 4)))
    (block $end
      (if (i32.eq (local.get $x) (i32.const 1)) (then
        (if (i32.eq (local.get $op) (i32.const 0x76)) (then (br $end)))   ;; HLT -> NOP
        (call $setr (local.get $y) (local.get $hl) (call $getr (local.get $z) (local.get $hl))) (br $end)))
      (if (i32.eq (local.get $x) (i32.const 2)) (then (call $alu80 (local.get $y) (call $getr (local.get $z) (local.get $hl))) (br $end)))
      (if (i32.eqz (local.get $x)) (then
        (if (i32.eqz (local.get $z)) (then (br $end)))   ;; NOP and its duplicates
        (if (i32.eq (local.get $z) (i32.const 1)) (then
          (if (local.get $q)
            (then   ;; DAD rp: only CY
              (local.set $t (i32.add (local.get $hl) (call $zr16 (call $rpoff (local.get $p)))))
              (call $zw16 (i32.const 4) (i32.and (local.get $t) (i32.const 0xffff)))
              (call $zw (i32.const 6) (i32.or (i32.and (call $zr (i32.const 6)) (i32.const 0xFE)) (i32.and (i32.shr_u (local.get $t) (i32.const 16)) (i32.const 1)))))
            (else (call $zw16 (call $rpoff (local.get $p)) (call $fetch16))))
          (br $end)))
        (if (i32.eq (local.get $z) (i32.const 2)) (then
          (if (i32.eqz (local.get $p)) (then (local.set $t (call $zr16 (i32.const 0))))
            (else (if (i32.eq (local.get $p) (i32.const 1)) (then (local.set $t (call $zr16 (i32.const 2)))) (else (local.set $t (call $fetch16))))))   ;; no select here: fetch16 has side effects
          (if (local.get $q)
            (then (if (i32.eq (local.get $p) (i32.const 2)) (then (call $zw16 (i32.const 4) (call $mrd16 (local.get $t)))) (else (call $zw (i32.const 7) (call $mrd (local.get $t))))))
            (else (if (i32.eq (local.get $p) (i32.const 2)) (then (call $mwr16 (local.get $t) (local.get $hl))) (else (call $mwr (local.get $t) (call $zr (i32.const 7)))))))
          (br $end)))
        (if (i32.eq (local.get $z) (i32.const 3)) (then
          (local.set $t (call $rpoff (local.get $p)))
          (call $zw16 (local.get $t) (i32.and (i32.add (call $zr16 (local.get $t)) (select (i32.const -1) (i32.const 1) (local.get $q))) (i32.const 0xffff)))
          (br $end)))
        (if (i32.lt_u (local.get $z) (i32.const 6)) (then   ;; INR / DCR: S Z AC P, not CY
          (local.set $v (call $getr (local.get $y) (local.get $hl)))
          (local.set $t (i32.and (i32.add (local.get $v) (select (i32.const 1) (i32.const -1) (i32.eq (local.get $z) (i32.const 4)))) (i32.const 255)))
          (call $setr (local.get $y) (local.get $hl) (local.get $t))
          (call $zw (i32.const 6) (i32.or (i32.and (call $zr (i32.const 6)) (i32.const 1))
            (i32.and (call $f80 (local.get $t)
              (select (i32.eqz (i32.and (local.get $t) (i32.const 15))) (i32.ne (i32.and (local.get $t) (i32.const 15)) (i32.const 15)) (i32.eq (local.get $z) (i32.const 4)))
              (i32.const 0)) (i32.const 0xFE))))
          (br $end)))
        (if (i32.eq (local.get $z) (i32.const 6)) (then (call $setr (local.get $y) (local.get $hl) (call $fetch)) (br $end)))
        ;; z = 7: RLC RRC RAL RAR DAA CMA STC CMC
        (local.set $f (call $zr (i32.const 6)))
        (if (i32.lt_u (local.get $y) (i32.const 4)) (then
          (call $zw (i32.const 7) (call $rot (local.get $y) (call $zr (i32.const 7))))
          (call $zw (i32.const 6) (i32.or (i32.and (local.get $f) (i32.const 0xFE)) (i32.and (call $zr (i32.const 6)) (i32.const 1))))
          (br $end)))
        (if (i32.eq (local.get $y) (i32.const 4)) (then   ;; DAA (8080: always adds)
          (local.set $v (call $zr (i32.const 7))) (local.set $t (i32.const 0))
          (if (i32.or (i32.and (local.get $f) (i32.const 0x10)) (i32.gt_u (i32.and (local.get $v) (i32.const 15)) (i32.const 9))) (then (local.set $t (i32.const 6))))
          (if (i32.or (i32.and (local.get $f) (i32.const 1)) (i32.gt_u (local.get $v) (i32.const 0x99))) (then (local.set $t (i32.or (local.get $t) (i32.const 0x60)))))
          (local.set $p (i32.add (local.get $v) (local.get $t)))
          (call $zw (i32.const 7) (i32.and (local.get $p) (i32.const 255)))
          (call $zw (i32.const 6) (call $f80 (local.get $p) (i32.and (i32.xor (local.get $v) (local.get $p)) (i32.const 0x10)) (i32.or (i32.and (local.get $f) (i32.const 1)) (i32.and (local.get $t) (i32.const 0x60)))))
          (br $end)))
        (if (i32.eq (local.get $y) (i32.const 5)) (then (call $zw (i32.const 7) (i32.xor (call $zr (i32.const 7)) (i32.const 255))) (br $end)))
        (if (i32.eq (local.get $y) (i32.const 6)) (then (call $zw (i32.const 6) (i32.or (local.get $f) (i32.const 1))) (br $end)))
        (call $zw (i32.const 6) (i32.xor (local.get $f) (i32.const 1)))
        (br $end)))
      ;; x = 3
      (if (i32.eqz (local.get $z)) (then (if (call $cc (local.get $y)) (then (call $zw16 (i32.const 22) (call $pop)))) (br $end)))
      (if (i32.eq (local.get $z) (i32.const 1)) (then
        (if (i32.eqz (local.get $q)) (then (call $zw16 (call $rp2off (local.get $p)) (call $pop)) (br $end)))
        (if (i32.lt_u (local.get $p) (i32.const 2)) (then (call $zw16 (i32.const 22) (call $pop)) (br $end)))   ;; RET and its duplicate
        (if (i32.eq (local.get $p) (i32.const 2)) (then (call $zw16 (i32.const 22) (local.get $hl)) (br $end)))
        (call $zw16 (i32.const 20) (local.get $hl)) (br $end)))
      (if (i32.eq (local.get $z) (i32.const 2)) (then (local.set $t (call $fetch16)) (if (call $cc (local.get $y)) (then (call $zw16 (i32.const 22) (local.get $t)))) (br $end)))
      (if (i32.eq (local.get $z) (i32.const 3)) (then
        (if (i32.lt_u (local.get $y) (i32.const 2)) (then (call $zw16 (i32.const 22) (call $fetch16)) (br $end)))   ;; JMP and its duplicate
        (if (i32.lt_u (local.get $y) (i32.const 4)) (then (drop (call $fetch)) (br $end)))                        ;; OUT / IN: NOP
        (if (i32.eq (local.get $y) (i32.const 4)) (then   ;; XTHL
          (local.set $t (call $zr16 (i32.const 20))) (local.set $v (call $mrd16 (local.get $t)))
          (call $mwr16 (local.get $t) (local.get $hl)) (call $zw16 (i32.const 4) (local.get $v)) (br $end)))
        (if (i32.eq (local.get $y) (i32.const 5)) (then (call $swap (i32.const 2) (i32.const 4) (i32.const 2)) (br $end)))
        (br $end)))   ;; DI / EI
      (if (i32.eq (local.get $z) (i32.const 4)) (then
        (local.set $t (call $fetch16))
        (if (call $cc (local.get $y)) (then (call $push (call $zr16 (i32.const 22))) (call $zw16 (i32.const 22) (local.get $t))))
        (br $end)))
      (if (i32.eq (local.get $z) (i32.const 5)) (then
        (if (i32.eqz (local.get $q)) (then (call $push (call $zr16 (call $rp2off (local.get $p)))) (br $end)))
        (local.set $t (call $fetch16)) (call $push (call $zr16 (i32.const 22))) (call $zw16 (i32.const 22) (local.get $t))   ;; CALL and its duplicates
        (br $end)))
      (if (i32.eq (local.get $z) (i32.const 6)) (then (call $alu80 (local.get $y) (call $fetch)) (br $end)))
      (call $push (call $zr16 (i32.const 22)))
      (call $zw16 (i32.const 22) (i32.shl (local.get $y) (i32.const 3)))))

  ;; ========================================================================
  ;; MOS 6502 byte processor. Register file: 0 A, 1 X, 2 Y, 3 S, 4 P, 22 PC.
  ;; The stack lives at $0100+S, which wraps into the same 16 bytes. All 151
  ;; documented opcodes; every undocumented opcode (the JAM/KIL halts included)
  ;; is a one-byte NOP. BRK pushes PC+2 and P and jumps through the vector at
  ;; $FFFE/$FFFF (bytes 14 and 15). Decimal mode is honoured by ADC/SBC.
  (func $nz (param $v i32)   ;; set N and Z from v, keep the rest of P
    (call $zw (i32.const 4) (i32.or (i32.and (call $zr (i32.const 4)) (i32.const 0x7D))
      (i32.or (i32.and (local.get $v) (i32.const 0x80)) (select (i32.const 2) (i32.const 0) (i32.eqz (i32.and (local.get $v) (i32.const 255))))))))
  (func $push6 (param $v i32)
    (call $mwr (i32.add (i32.const 0x100) (call $zr (i32.const 3))) (local.get $v))
    (call $zw (i32.const 3) (i32.and (i32.sub (call $zr (i32.const 3)) (i32.const 1)) (i32.const 255))))
  (func $pop6 (result i32)
    (call $zw (i32.const 3) (i32.and (i32.add (call $zr (i32.const 3)) (i32.const 1)) (i32.const 255)))
    (call $mrd (i32.add (i32.const 0x100) (call $zr (i32.const 3)))))
  ;; effective address for addressing mode bbb within group cc; mode 2 of group 1 and
  ;; mode 0 of groups 0/2 are immediate: the operand byte's own address is returned
  (func $ea6 (param $bbb i32) (param $cc i32) (param $aaa i32) (result i32)
    (local $t i32) (local $idx i32)
    ;; index register for the indexed modes: Y instead of X for STX/LDX zp,X and LDX abs,X
    (local.set $idx (call $zr (select (i32.const 2) (i32.const 1)
      (i32.and (i32.eq (local.get $cc) (i32.const 2)) (i32.or (i32.eq (local.get $aaa) (i32.const 4)) (i32.eq (local.get $aaa) (i32.const 5)))))))
    (if (i32.eq (local.get $cc) (i32.const 1)) (then
      (if (i32.eqz (local.get $bbb)) (then (return (call $mrd16 (i32.and (i32.add (call $fetch) (call $zr (i32.const 1))) (i32.const 255))))))
      (if (i32.eq (local.get $bbb) (i32.const 4)) (then (return (i32.and (i32.add (call $mrd16 (call $fetch)) (call $zr (i32.const 2))) (i32.const 0xffff)))))
      (if (i32.eq (local.get $bbb) (i32.const 6)) (then (return (i32.and (i32.add (call $fetch16) (call $zr (i32.const 2))) (i32.const 0xffff)))))
      (if (i32.eq (local.get $bbb) (i32.const 2)) (then (local.set $t (call $zr16 (i32.const 22))) (drop (call $fetch)) (return (local.get $t))))))
    (if (i32.eqz (local.get $bbb)) (then (local.set $t (call $zr16 (i32.const 22))) (drop (call $fetch)) (return (local.get $t))))
    (if (i32.eq (local.get $bbb) (i32.const 1)) (then (return (call $fetch))))
    (if (i32.eq (local.get $bbb) (i32.const 3)) (then (return (call $fetch16))))
    (if (i32.eq (local.get $bbb) (i32.const 5)) (then (return (i32.and (i32.add (call $fetch) (local.get $idx)) (i32.const 255)))))
    (i32.and (i32.add (call $fetch16) (select (local.get $idx) (call $zr (i32.const 1)) (i32.eq (local.get $cc) (i32.const 2)))) (i32.const 0xffff)))
  (func $adc6 (param $b i32)   ;; ADC with decimal mode
    (local $a i32) (local $p i32) (local $c i32) (local $r i32) (local $lo i32) (local $hi i32)
    (local.set $a (call $zr (i32.const 0))) (local.set $p (call $zr (i32.const 4))) (local.set $c (i32.and (local.get $p) (i32.const 1)))
    (local.set $r (i32.add (i32.add (local.get $a) (local.get $b)) (local.get $c)))
    (local.set $p (i32.or (i32.and (local.get $p) (i32.const 0x3C))
      (i32.or (select (i32.const 2) (i32.const 0) (i32.eqz (i32.and (local.get $r) (i32.const 255))))
              (i32.shr_u (i32.and (i32.and (i32.xor (local.get $a) (local.get $r)) (i32.xor (local.get $b) (local.get $r))) (i32.const 0x80)) (i32.const 1)))))
    (if (i32.and (local.get $p) (i32.const 8))
      (then   ;; decimal adjust
        (local.set $lo (i32.add (i32.add (i32.and (local.get $a) (i32.const 15)) (i32.and (local.get $b) (i32.const 15))) (local.get $c)))
        (if (i32.gt_u (local.get $lo) (i32.const 9)) (then (local.set $lo (i32.add (local.get $lo) (i32.const 6)))))
        (local.set $hi (i32.add (i32.add (i32.shr_u (local.get $a) (i32.const 4)) (i32.shr_u (local.get $b) (i32.const 4))) (i32.shr_u (local.get $lo) (i32.const 4))))
        (if (i32.gt_u (local.get $hi) (i32.const 9)) (then (local.set $hi (i32.add (local.get $hi) (i32.const 6)))))
        (local.set $r (i32.or (i32.shl (local.get $hi) (i32.const 4)) (i32.and (local.get $lo) (i32.const 15))))
        (local.set $p (i32.or (local.get $p) (select (i32.const 1) (i32.const 0) (i32.gt_u (local.get $hi) (i32.const 15))))))
      (else (local.set $p (i32.or (local.get $p) (i32.and (i32.shr_u (local.get $r) (i32.const 8)) (i32.const 1))))))
    (call $zw (i32.const 0) (i32.and (local.get $r) (i32.const 255)))
    (call $zw (i32.const 4) (i32.or (local.get $p) (i32.and (local.get $r) (i32.const 0x80)))))
  (func $sbc6 (param $b i32)
    (local $a i32) (local $p i32) (local $c i32) (local $r i32) (local $lo i32) (local $hi i32)
    (local.set $a (call $zr (i32.const 0))) (local.set $p (call $zr (i32.const 4))) (local.set $c (i32.xor (i32.and (local.get $p) (i32.const 1)) (i32.const 1)))
    (local.set $r (i32.sub (i32.sub (local.get $a) (local.get $b)) (local.get $c)))
    (local.set $p (i32.or (i32.and (local.get $p) (i32.const 0x3C))
      (i32.or (i32.or (select (i32.const 2) (i32.const 0) (i32.eqz (i32.and (local.get $r) (i32.const 255)))) (i32.and (local.get $r) (i32.const 0x80)))
        (i32.or (i32.shr_u (i32.and (i32.and (i32.xor (local.get $a) (local.get $b)) (i32.xor (local.get $a) (local.get $r))) (i32.const 0x80)) (i32.const 1))
                (i32.xor (i32.and (i32.shr_u (local.get $r) (i32.const 8)) (i32.const 1)) (i32.const 1))))))
    (if (i32.and (local.get $p) (i32.const 8)) (then
      (local.set $lo (i32.sub (i32.sub (i32.and (local.get $a) (i32.const 15)) (i32.and (local.get $b) (i32.const 15))) (local.get $c)))
      (if (i32.and (local.get $lo) (i32.const 0x10)) (then (local.set $lo (i32.sub (local.get $lo) (i32.const 6)))))
      (local.set $hi (i32.sub (i32.sub (i32.shr_u (local.get $a) (i32.const 4)) (i32.shr_u (local.get $b) (i32.const 4))) (i32.and (i32.shr_u (local.get $lo) (i32.const 4)) (i32.const 1))))
      (if (i32.and (local.get $hi) (i32.const 0x10)) (then (local.set $hi (i32.sub (local.get $hi) (i32.const 6)))))
      (local.set $r (i32.or (i32.shl (i32.and (local.get $hi) (i32.const 15)) (i32.const 4)) (i32.and (local.get $lo) (i32.const 15))))))
    (call $zw (i32.const 0) (i32.and (local.get $r) (i32.const 255)))
    (call $zw (i32.const 4) (local.get $p)))
  (func $cmp6 (param $a i32) (param $b i32)   ;; CMP/CPX/CPY flags
    (local $r i32)
    (local.set $r (i32.sub (local.get $a) (local.get $b)))
    (call $zw (i32.const 4) (i32.or (i32.and (call $zr (i32.const 4)) (i32.const 0x7C))
      (i32.or (i32.or (i32.and (local.get $r) (i32.const 0x80)) (select (i32.const 2) (i32.const 0) (i32.eqz (i32.and (local.get $r) (i32.const 255)))))
              (i32.ge_u (local.get $a) (local.get $b))))))
  (func $shift6 (param $aaa i32) (param $v i32) (result i32)   ;; ASL ROL LSR ROR with flags
    (local $r i32) (local $c i32) (local $p i32)
    (local.set $p (call $zr (i32.const 4)))
    (if (i32.lt_u (local.get $aaa) (i32.const 2))
      (then (local.set $c (i32.shr_u (local.get $v) (i32.const 7))) (local.set $r (i32.and (i32.or (i32.shl (local.get $v) (i32.const 1)) (select (i32.and (local.get $p) (i32.const 1)) (i32.const 0) (local.get $aaa))) (i32.const 255))))
      (else (local.set $c (i32.and (local.get $v) (i32.const 1))) (local.set $r (i32.or (i32.shr_u (local.get $v) (i32.const 1)) (select (i32.shl (i32.and (local.get $p) (i32.const 1)) (i32.const 7)) (i32.const 0) (i32.eq (local.get $aaa) (i32.const 3)))))))
    (call $zw (i32.const 4) (i32.or (i32.and (local.get $p) (i32.const 0xFE)) (local.get $c)))
    (call $nz (local.get $r))
    (local.get $r))
  (func $m6502step
    (local $op i32) (local $aaa i32) (local $bbb i32) (local $cc i32) (local $ea i32) (local $v i32) (local $t i32) (local $p i32)
    (local.set $op (call $fetch))
    (local.set $aaa (i32.shr_u (local.get $op) (i32.const 5))) (local.set $bbb (i32.and (i32.shr_u (local.get $op) (i32.const 2)) (i32.const 7))) (local.set $cc (i32.and (local.get $op) (i32.const 3)))
    (block $end
      ;; ---- group cc = 1: ORA AND EOR ADC STA LDA CMP SBC
      (if (i32.eq (local.get $cc) (i32.const 1)) (then
        (local.set $ea (call $ea6 (local.get $bbb) (i32.const 1) (local.get $aaa)))
        (if (i32.eq (local.get $aaa) (i32.const 4)) (then (call $mwr (local.get $ea) (call $zr (i32.const 0))) (br $end)))   ;; STA (STA # is a documented-NOP-ish: writes nowhere useful)
        (local.set $v (call $mrd (local.get $ea)))
        (if (i32.eq (local.get $aaa) (i32.const 5)) (then (call $zw (i32.const 0) (local.get $v)) (call $nz (local.get $v)) (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 6)) (then (call $cmp6 (call $zr (i32.const 0)) (local.get $v)) (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 3)) (then (call $adc6 (local.get $v)) (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 7)) (then (call $sbc6 (local.get $v)) (br $end)))
        (local.set $t (select (i32.or (call $zr (i32.const 0)) (local.get $v)) (select (i32.and (call $zr (i32.const 0)) (local.get $v)) (i32.xor (call $zr (i32.const 0)) (local.get $v)) (i32.eq (local.get $aaa) (i32.const 1))) (i32.eqz (local.get $aaa))))
        (call $zw (i32.const 0) (local.get $t)) (call $nz (local.get $t))
        (br $end)))
      ;; ---- group cc = 2: ASL ROL LSR ROR STX LDX DEC INC (and the implied ones in column 2 and 6)
      (if (i32.eq (local.get $cc) (i32.const 2)) (then
        (if (i32.eq (local.get $bbb) (i32.const 2)) (then
          (if (i32.lt_u (local.get $aaa) (i32.const 4)) (then (call $zw (i32.const 0) (call $shift6 (local.get $aaa) (call $zr (i32.const 0)))) (br $end)))
          (if (i32.eq (local.get $aaa) (i32.const 4)) (then (call $zw (i32.const 0) (call $zr (i32.const 1))) (call $nz (call $zr (i32.const 0))) (br $end)))   ;; TXA
          (if (i32.eq (local.get $aaa) (i32.const 5)) (then (call $zw (i32.const 1) (call $zr (i32.const 0))) (call $nz (call $zr (i32.const 1))) (br $end)))   ;; TAX
          (if (i32.eq (local.get $aaa) (i32.const 6)) (then (call $zw (i32.const 1) (i32.and (i32.sub (call $zr (i32.const 1)) (i32.const 1)) (i32.const 255))) (call $nz (call $zr (i32.const 1))) (br $end)))   ;; DEX
          (br $end)))   ;; NOP
        (if (i32.eq (local.get $bbb) (i32.const 6)) (then
          (if (i32.eq (local.get $aaa) (i32.const 4)) (then (call $zw (i32.const 3) (call $zr (i32.const 1)))))                                   ;; TXS
          (if (i32.eq (local.get $aaa) (i32.const 5)) (then (call $zw (i32.const 1) (call $zr (i32.const 3))) (call $nz (call $zr (i32.const 1)))))   ;; TSX
          (br $end)))
        (if (i32.and (i32.eqz (local.get $bbb)) (i32.ne (local.get $aaa) (i32.const 5))) (then (br $end)))   ;; only LDX has an immediate form
        (if (i32.and (i32.eq (local.get $bbb) (i32.const 4)) (i32.const 1)) (then (br $end)))                ;; column 4 is undocumented
        (local.set $ea (call $ea6 (local.get $bbb) (i32.const 2) (local.get $aaa)))
        (if (i32.eq (local.get $aaa) (i32.const 4)) (then (call $mwr (local.get $ea) (call $zr (i32.const 1))) (br $end)))   ;; STX
        (local.set $v (call $mrd (local.get $ea)))
        (if (i32.eq (local.get $aaa) (i32.const 5)) (then (call $zw (i32.const 1) (local.get $v)) (call $nz (local.get $v)) (br $end)))   ;; LDX
        (if (i32.lt_u (local.get $aaa) (i32.const 4)) (then (call $mwr (local.get $ea) (call $shift6 (local.get $aaa) (local.get $v))) (br $end)))
        (local.set $t (i32.and (i32.add (local.get $v) (select (i32.const -1) (i32.const 1) (i32.eq (local.get $aaa) (i32.const 6)))) (i32.const 255)))   ;; DEC / INC
        (call $mwr (local.get $ea) (local.get $t)) (call $nz (local.get $t))
        (br $end)))
      ;; ---- group cc = 3: undocumented -> NOP
      (if (i32.eq (local.get $cc) (i32.const 3)) (then (br $end)))
      ;; ---- group cc = 0
      (if (i32.eq (local.get $bbb) (i32.const 4)) (then   ;; branches: BPL BMI BVC BVS BCC BCS BNE BEQ
        (local.set $t (call $sext8 (call $fetch)))
        (local.set $p (call $zr (i32.const 4)))
        (local.set $v (i32.and (local.get $p) (select (i32.const 0x80) (select (i32.const 0x40) (select (i32.const 1) (i32.const 2) (i32.lt_u (local.get $aaa) (i32.const 6))) (i32.lt_u (local.get $aaa) (i32.const 4))) (i32.lt_u (local.get $aaa) (i32.const 2)))))
        (if (i32.eq (i32.ne (local.get $v) (i32.const 0)) (i32.and (local.get $aaa) (i32.const 1)))
          (then (call $zw16 (i32.const 22) (i32.and (i32.add (call $zr16 (i32.const 22)) (local.get $t)) (i32.const 0xffff)))))
        (br $end)))
      (if (i32.eq (local.get $bbb) (i32.const 6)) (then   ;; CLC SEC CLI SEI TYA CLV CLD SED
        (local.set $p (call $zr (i32.const 4)))
        (if (i32.eq (local.get $aaa) (i32.const 4)) (then (call $zw (i32.const 0) (call $zr (i32.const 2))) (call $nz (call $zr (i32.const 0))) (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 5)) (then (call $zw (i32.const 4) (i32.and (local.get $p) (i32.const 0xBF))) (br $end)))
        (local.set $t (select (i32.const 1) (select (i32.const 4) (i32.const 8) (i32.lt_u (local.get $aaa) (i32.const 4))) (i32.lt_u (local.get $aaa) (i32.const 2))))
        (call $zw (i32.const 4) (select (i32.or (local.get $p) (local.get $t)) (i32.and (local.get $p) (i32.xor (local.get $t) (i32.const 255))) (i32.and (local.get $aaa) (i32.const 1))))
        (br $end)))
      (if (i32.eq (local.get $bbb) (i32.const 2)) (then   ;; PHP PLP PHA PLA DEY TAY INY INX
        (if (i32.eqz (local.get $aaa)) (then (call $push6 (i32.or (call $zr (i32.const 4)) (i32.const 0x30))) (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 1)) (then (call $zw (i32.const 4) (i32.or (i32.and (call $pop6) (i32.const 0xCF)) (i32.const 0x20))) (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 2)) (then (call $push6 (call $zr (i32.const 0))) (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 3)) (then (call $zw (i32.const 0) (call $pop6)) (call $nz (call $zr (i32.const 0))) (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 4)) (then (call $zw (i32.const 2) (i32.and (i32.sub (call $zr (i32.const 2)) (i32.const 1)) (i32.const 255))) (call $nz (call $zr (i32.const 2))) (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 5)) (then (call $zw (i32.const 2) (call $zr (i32.const 0))) (call $nz (call $zr (i32.const 2))) (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 6)) (then (call $zw (i32.const 2) (i32.and (i32.add (call $zr (i32.const 2)) (i32.const 1)) (i32.const 255))) (call $nz (call $zr (i32.const 2))) (br $end)))
        (call $zw (i32.const 1) (i32.and (i32.add (call $zr (i32.const 1)) (i32.const 1)) (i32.const 255))) (call $nz (call $zr (i32.const 1)))
        (br $end)))
      (if (i32.eqz (local.get $bbb)) (then
        (if (i32.eqz (local.get $aaa)) (then   ;; BRK
          (local.set $t (i32.and (i32.add (call $zr16 (i32.const 22)) (i32.const 1)) (i32.const 0xffff)))
          (call $push6 (i32.shr_u (local.get $t) (i32.const 8))) (call $push6 (i32.and (local.get $t) (i32.const 255)))
          (call $push6 (i32.or (call $zr (i32.const 4)) (i32.const 0x30)))
          (call $zw (i32.const 4) (i32.or (call $zr (i32.const 4)) (i32.const 4)))
          (call $zw16 (i32.const 22) (call $mrd16 (i32.const 0xFFFE)))
          (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 1)) (then   ;; JSR
          (local.set $t (call $fetch16))
          (local.set $v (i32.and (i32.sub (call $zr16 (i32.const 22)) (i32.const 1)) (i32.const 0xffff)))
          (call $push6 (i32.shr_u (local.get $v) (i32.const 8))) (call $push6 (i32.and (local.get $v) (i32.const 255)))
          (call $zw16 (i32.const 22) (local.get $t))
          (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 2)) (then   ;; RTI
          (call $zw (i32.const 4) (i32.or (i32.and (call $pop6) (i32.const 0xCF)) (i32.const 0x20)))
          (local.set $t (call $pop6)) (call $zw16 (i32.const 22) (i32.or (local.get $t) (i32.shl (call $pop6) (i32.const 8))))
          (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 3)) (then   ;; RTS
          (local.set $t (call $pop6)) (call $zw16 (i32.const 22) (i32.and (i32.add (i32.or (local.get $t) (i32.shl (call $pop6) (i32.const 8))) (i32.const 1)) (i32.const 0xffff)))
          (br $end)))
        (if (i32.lt_u (local.get $aaa) (i32.const 5)) (then (br $end)))))   ;; $80 undocumented NOP
      (if (i32.and (i32.eq (local.get $bbb) (i32.const 3)) (i32.or (i32.eq (local.get $aaa) (i32.const 2)) (i32.eq (local.get $aaa) (i32.const 3)))) (then   ;; JMP abs / JMP (ind)
        (local.set $t (call $fetch16))
        (call $zw16 (i32.const 22) (select (local.get $t) (call $mrd16 (local.get $t)) (i32.eq (local.get $aaa) (i32.const 2))))
        (br $end)))
      (if (i32.and (i32.or (i32.eq (local.get $bbb) (i32.const 5)) (i32.eq (local.get $bbb) (i32.const 7))) (i32.and (i32.ne (local.get $aaa) (i32.const 4)) (i32.ne (local.get $aaa) (i32.const 5)))) (then (br $end)))   ;; undocumented
      (if (i32.and (i32.eq (local.get $bbb) (i32.const 7)) (i32.eq (local.get $aaa) (i32.const 4))) (then (br $end)))   ;; $9C undocumented
      (if (i32.lt_u (local.get $aaa) (i32.const 4)) (then   ;; only BIT remains here (aaa = 1, zp or abs)
        (if (i32.ne (local.get $aaa) (i32.const 1)) (then (br $end)))
        (local.set $v (call $mrd (call $ea6 (local.get $bbb) (i32.const 0) (local.get $aaa))))
        (call $zw (i32.const 4) (i32.or (i32.and (call $zr (i32.const 4)) (i32.const 0x3D))
          (i32.or (i32.and (local.get $v) (i32.const 0xC0)) (select (i32.const 2) (i32.const 0) (i32.eqz (i32.and (local.get $v) (call $zr (i32.const 0))))))))
        (br $end)))
      (local.set $ea (call $ea6 (local.get $bbb) (i32.const 0) (local.get $aaa)))
      (if (i32.eq (local.get $aaa) (i32.const 4)) (then (call $mwr (local.get $ea) (call $zr (i32.const 2))) (br $end)))   ;; STY
      (local.set $v (call $mrd (local.get $ea)))
      (if (i32.eq (local.get $aaa) (i32.const 5)) (then (call $zw (i32.const 2) (local.get $v)) (call $nz (local.get $v)) (br $end)))   ;; LDY
      (call $cmp6 (call $zr (select (i32.const 2) (i32.const 1) (i32.eq (local.get $aaa) (i32.const 6)))) (local.get $v))))   ;; CPY / CPX

  ;; cpu(p, prm, kind): shared driver for the 8080 (kind 8) and 6502 (kind 7) cores.
  (func $cpu (param $p i32) (param $prm i32) (param $kind i32) (result i32)
    (local $out i32) (local $flags i32) (local $i i32) (local $changed i32) (local $c i32)
    (local.set $out (i32.load (local.get $prm)))
    (local.set $flags (i32.load offset=36 (local.get $prm)))
    (i64.store (local.get $out) (i64.load (local.get $p)))
    (i64.store offset=8 (local.get $out) (i64.load offset=8 (local.get $p)))
    (global.set $zp (local.get $out))
    (block $re (loop $rl (br_if $re (i32.ge_u (local.get $i) (i32.const 28))) (call $zw (local.get $i) (i32.const 0)) (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $rl)))
    (if (i32.eq (local.get $kind) (i32.const 7)) (then (call $zw (i32.const 4) (i32.const 0x24)) (call $zw (i32.const 3) (i32.const 0xFF))))   ;; 6502: P starts with I and the unused bit set, S at the top of the stack page
    (local.set $i (i32.const 0))
    (block $se (loop $sl (br_if $se (i32.ge_u (local.get $i) (i32.const 256)))
      (if (i32.eq (local.get $kind) (i32.const 7)) (then (call $m6502step)) (else (call $i8080step)))
      (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $sl)))
    (local.set $i (i32.const 0))
    (block $ce (loop $cl
      (br_if $ce (i32.ge_u (local.get $i) (i32.const 16)))
      (local.set $c (i32.ne (i32.load8_u (i32.add (local.get $out) (local.get $i))) (i32.load8_u (i32.add (local.get $p) (local.get $i)))))
      (i32.store8 (i32.add (local.get $flags) (local.get $i)) (local.get $c))
      (local.set $changed (i32.add (local.get $changed) (local.get $c)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $cl)))
    (i32.store offset=48 (local.get $prm) (call $zr16 (i32.const 22)))
    (i32.or (i32.shl (i32.const 256) (i32.const 8)) (local.get $changed)))
