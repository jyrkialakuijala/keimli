  ;; DEC PDP-8 (kind 19). The pixel is 8 words of 12 bits: word k is pixel bits
  ;; 12k..12k+11 (bit j of the word = pixel bit 12k+j), i.e. bits 0..95. The
  ;; registers live in the remaining bits and are loaded at the start and
  ;; written back at the end: AC bits 96..107, L bit 108, PC bits 109..111,
  ;; MQ bits 112..123; bits 124..127 are untouched. Register file: AC 0 (u16),
  ;; L 2, MQ 4 (u16), PC 22. Addresses are taken mod 8 (the page bit is
  ;; ignored); indirect through a word also mod 8, no auto-index. IOT, OSR and
  ;; HLT are NOPs; the OPR groups are complete (incl. BSW and the MQ group).
  (func $p8_rd (param $off i32) (param $n i32) (result i32)   ;; n <= 16 bits at pixel bit offset off
    (local $b i32)
    (local.set $b (i32.shr_u (local.get $off) (i32.const 3)))
    (i32.and
      (i32.shr_u (i32.or (i32.or (call $mrd (local.get $b)) (i32.shl (call $mrd (i32.add (local.get $b) (i32.const 1))) (i32.const 8)))
                         (i32.shl (call $mrd (i32.add (local.get $b) (i32.const 2))) (i32.const 16)))
                 (i32.and (local.get $off) (i32.const 7)))
      (i32.sub (i32.shl (i32.const 1) (local.get $n)) (i32.const 1))))
  (func $p8_wr (param $off i32) (param $n i32) (param $v i32)
    (local $b i32) (local $cur i32) (local $mask i32) (local $s i32)
    (local.set $b (i32.shr_u (local.get $off) (i32.const 3))) (local.set $s (i32.and (local.get $off) (i32.const 7)))
    (local.set $mask (i32.shl (i32.sub (i32.shl (i32.const 1) (local.get $n)) (i32.const 1)) (local.get $s)))
    (local.set $cur (i32.or (i32.or (call $mrd (local.get $b)) (i32.shl (call $mrd (i32.add (local.get $b) (i32.const 1))) (i32.const 8)))
                            (i32.shl (call $mrd (i32.add (local.get $b) (i32.const 2))) (i32.const 16))))
    (local.set $cur (i32.or (i32.and (local.get $cur) (i32.xor (local.get $mask) (i32.const -1))) (i32.and (i32.shl (local.get $v) (local.get $s)) (local.get $mask))))
    (call $mwr (local.get $b) (i32.and (local.get $cur) (i32.const 255)))
    (call $mwr (i32.add (local.get $b) (i32.const 1)) (i32.and (i32.shr_u (local.get $cur) (i32.const 8)) (i32.const 255)))
    (call $mwr (i32.add (local.get $b) (i32.const 2)) (i32.shr_u (local.get $cur) (i32.const 16))))
  (func $p8_mem (param $a i32) (result i32) (call $p8_rd (i32.mul (i32.and (local.get $a) (i32.const 7)) (i32.const 12)) (i32.const 12)))
  (func $p8_set (param $a i32) (param $v i32) (call $p8_wr (i32.mul (i32.and (local.get $a) (i32.const 7)) (i32.const 12)) (i32.const 12) (i32.and (local.get $v) (i32.const 0xfff))))
  (func $p8_load
    (call $zw16 (i32.const 0) (call $p8_rd (i32.const 96) (i32.const 12)))
    (call $zw (i32.const 2) (call $p8_rd (i32.const 108) (i32.const 1)))
    (call $zw16 (i32.const 22) (call $p8_rd (i32.const 109) (i32.const 3)))
    (call $zw16 (i32.const 4) (call $p8_rd (i32.const 112) (i32.const 12))))
  (func $p8_spill
    (call $p8_wr (i32.const 96) (i32.const 12) (call $zr16 (i32.const 0)))
    (call $p8_wr (i32.const 108) (i32.const 1) (call $zr (i32.const 2)))
    (call $p8_wr (i32.const 109) (i32.const 3) (call $zr16 (i32.const 22)))
    (call $p8_wr (i32.const 112) (i32.const 12) (call $zr16 (i32.const 4))))
  (func $pdp8_step
    (local $pc i32) (local $w i32) (local $op i32) (local $a i32) (local $ac i32) (local $l i32) (local $t i32) (local $skip i32)
    (local.set $pc (call $zr16 (i32.const 22)))
    (local.set $w (call $p8_mem (local.get $pc)))
    (local.set $pc (i32.and (i32.add (local.get $pc) (i32.const 1)) (i32.const 7)))
    (local.set $op (i32.shr_u (local.get $w) (i32.const 9)))
    (local.set $ac (call $zr16 (i32.const 0))) (local.set $l (i32.and (call $zr (i32.const 2)) (i32.const 1)))
    (block $end
      (if (i32.lt_u (local.get $op) (i32.const 6)) (then
        (local.set $a (i32.and (local.get $w) (i32.const 7)))
        (if (i32.and (local.get $w) (i32.const 0x100)) (then (local.set $a (i32.and (call $p8_mem (local.get $a)) (i32.const 7)))))
        (if (i32.eqz (local.get $op)) (then (local.set $ac (i32.and (local.get $ac) (call $p8_mem (local.get $a)))) (br $end)))
        (if (i32.eq (local.get $op) (i32.const 1)) (then
          (local.set $t (i32.add (i32.or (i32.shl (local.get $l) (i32.const 12)) (local.get $ac)) (call $p8_mem (local.get $a))))
          (local.set $ac (i32.and (local.get $t) (i32.const 0xfff))) (local.set $l (i32.and (i32.shr_u (local.get $t) (i32.const 12)) (i32.const 1))) (br $end)))
        (if (i32.eq (local.get $op) (i32.const 2)) (then
          (local.set $t (i32.and (i32.add (call $p8_mem (local.get $a)) (i32.const 1)) (i32.const 0xfff)))
          (call $p8_set (local.get $a) (local.get $t))
          (if (i32.eqz (local.get $t)) (then (local.set $pc (i32.and (i32.add (local.get $pc) (i32.const 1)) (i32.const 7))))) (br $end)))
        (if (i32.eq (local.get $op) (i32.const 3)) (then (call $p8_set (local.get $a) (local.get $ac)) (local.set $ac (i32.const 0)) (br $end)))
        (if (i32.eq (local.get $op) (i32.const 4)) (then (call $p8_set (local.get $a) (local.get $pc)) (local.set $pc (i32.and (i32.add (local.get $a) (i32.const 1)) (i32.const 7))) (br $end)))
        (local.set $pc (local.get $a)) (br $end)))   ;; JMP
      (if (i32.eq (local.get $op) (i32.const 6)) (then (br $end)))   ;; IOT
      (if (i32.eqz (i32.and (local.get $w) (i32.const 0x100))) (then   ;; group 1
        (if (i32.and (local.get $w) (i32.const 0x80)) (then (local.set $ac (i32.const 0))))
        (if (i32.and (local.get $w) (i32.const 0x40)) (then (local.set $l (i32.const 0))))
        (if (i32.and (local.get $w) (i32.const 0x20)) (then (local.set $ac (i32.xor (local.get $ac) (i32.const 0xfff)))))
        (if (i32.and (local.get $w) (i32.const 0x10)) (then (local.set $l (i32.xor (local.get $l) (i32.const 1)))))
        (if (i32.and (local.get $w) (i32.const 1)) (then
          (local.set $t (i32.add (local.get $ac) (i32.const 1))) (local.set $ac (i32.and (local.get $t) (i32.const 0xfff)))
          (if (i32.and (local.get $t) (i32.const 0x1000)) (then (local.set $l (i32.xor (local.get $l) (i32.const 1)))))))
        (local.set $t (i32.or (i32.shl (local.get $l) (i32.const 12)) (local.get $ac)))   ;; 13-bit L:AC for the rotates
        (if (i32.and (local.get $w) (i32.const 0x08)) (then   ;; RAR / RTR
          (local.set $t (i32.or (i32.shr_u (local.get $t) (i32.const 1)) (i32.shl (i32.and (local.get $t) (i32.const 1)) (i32.const 12))))
          (if (i32.and (local.get $w) (i32.const 2)) (then (local.set $t (i32.or (i32.shr_u (local.get $t) (i32.const 1)) (i32.shl (i32.and (local.get $t) (i32.const 1)) (i32.const 12))))))))
        (if (i32.and (local.get $w) (i32.const 4)) (then   ;; RAL / RTL
          (local.set $t (i32.or (i32.shl (local.get $t) (i32.const 1)) (i32.shr_u (local.get $t) (i32.const 12))))
          (if (i32.and (local.get $w) (i32.const 2)) (then (local.set $t (i32.or (i32.shl (local.get $t) (i32.const 1)) (i32.shr_u (local.get $t) (i32.const 12))))))))
        (if (i32.eq (i32.and (local.get $w) (i32.const 0x0e)) (i32.const 2)) (then   ;; BSW: swap the two 6-bit halves
          (local.set $t (i32.or (i32.and (local.get $t) (i32.const 0x1000)) (i32.or (i32.shr_u (i32.and (local.get $t) (i32.const 0xfc0)) (i32.const 6)) (i32.shl (i32.and (local.get $t) (i32.const 0x3f)) (i32.const 6)))))))
        (local.set $ac (i32.and (local.get $t) (i32.const 0xfff))) (local.set $l (i32.and (i32.shr_u (local.get $t) (i32.const 12)) (i32.const 1)))
        (br $end)))
      (if (i32.eqz (i32.and (local.get $w) (i32.const 1))) (then   ;; group 2: skips, CLA, OSR/HLT as NOPs
        (local.set $skip (i32.or (i32.or
          (i32.and (i32.ne (i32.and (local.get $w) (i32.const 0x40)) (i32.const 0)) (i32.ne (i32.and (local.get $ac) (i32.const 0x800)) (i32.const 0)))
          (i32.and (i32.ne (i32.and (local.get $w) (i32.const 0x20)) (i32.const 0)) (i32.eqz (local.get $ac))))
          (i32.and (i32.ne (i32.and (local.get $w) (i32.const 0x10)) (i32.const 0)) (local.get $l))))
        (if (i32.and (local.get $w) (i32.const 0x08)) (then (local.set $skip (i32.eqz (local.get $skip)))))
        (if (local.get $skip) (then (local.set $pc (i32.and (i32.add (local.get $pc) (i32.const 1)) (i32.const 7)))))
        (if (i32.and (local.get $w) (i32.const 0x80)) (then (local.set $ac (i32.const 0))))
        (br $end)))
      ;; group 3: CLA, MQA, MQL (both = swap AC and MQ)
      (if (i32.and (local.get $w) (i32.const 0x80)) (then (local.set $ac (i32.const 0))))
      (local.set $t (call $zr16 (i32.const 4)))
      (if (i32.and (local.get $w) (i32.const 0x10)) (then (call $zw16 (i32.const 4) (local.get $ac)) (local.set $ac (i32.const 0))))
      (if (i32.and (local.get $w) (i32.const 0x40)) (then (local.set $ac (i32.or (local.get $ac) (local.get $t))))))
    (call $zw16 (i32.const 0) (local.get $ac)) (call $zw (i32.const 2) (local.get $l)) (call $zw16 (i32.const 22) (local.get $pc)))
