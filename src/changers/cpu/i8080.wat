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
