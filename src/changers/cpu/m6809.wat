  ;; Motorola 6809 (kind 14). Register file: A 0, B 1, DP 2, CC 3, X 4, Y 6,
  ;; U 8, S 10 (u16 each), PC 22. CC: E 80 F 40 H 20 I 10 N 08 Z 04 V 02 C 01.
  ;; All addressing modes including the full indexed postbyte with indirection,
  ;; both prefix pages. SYNC, CWAI and the SWIs are NOPs; undefined opcodes too.
  (func $nz8 (param $v i32) (result i32) (i32.or (select (i32.const 8) (i32.const 0) (i32.and (local.get $v) (i32.const 0x80))) (select (i32.const 4) (i32.const 0) (i32.eqz (i32.and (local.get $v) (i32.const 255))))))
  (func $nz16 (param $v i32) (result i32) (i32.or (select (i32.const 8) (i32.const 0) (i32.and (local.get $v) (i32.const 0x8000))) (select (i32.const 4) (i32.const 0) (i32.eqz (i32.and (local.get $v) (i32.const 0xffff))))))
  (func $cc9 (param $keep i32) (param $set i32)   ;; CC = (CC & keep) | set
    (call $zw (i32.const 3) (i32.or (i32.and (call $zr (i32.const 3)) (local.get $keep)) (local.get $set))))
  (func $ixreg (param $pb i32) (result i32) (i32.add (i32.const 4) (i32.shl (i32.and (i32.shr_u (local.get $pb) (i32.const 5)) (i32.const 3)) (i32.const 1))))
  ;; effective address for the indexed mode (postbyte fetched here)
  (func $ea_idx (result i32)
    (local $pb i32) (local $r i32) (local $ea i32) (local $m i32) (local $v i32)
    (local.set $pb (call $fetch)) (local.set $r (call $ixreg (local.get $pb))) (local.set $v (call $zr16 (local.get $r)))
    (if (i32.eqz (i32.and (local.get $pb) (i32.const 0x80))) (then   ;; 5-bit offset
      (return (i32.and (i32.add (local.get $v) (i32.sub (i32.and (local.get $pb) (i32.const 31)) (select (i32.const 32) (i32.const 0) (i32.and (local.get $pb) (i32.const 16))))) (i32.const 0xffff)))))
    (local.set $m (i32.and (local.get $pb) (i32.const 15)))
    (block $done
      (if (i32.eqz (local.get $m)) (then (local.set $ea (local.get $v)) (call $zw16 (local.get $r) (i32.and (i32.add (local.get $v) (i32.const 1)) (i32.const 0xffff))) (br $done)))
      (if (i32.eq (local.get $m) (i32.const 1)) (then (local.set $ea (local.get $v)) (call $zw16 (local.get $r) (i32.and (i32.add (local.get $v) (i32.const 2)) (i32.const 0xffff))) (br $done)))
      (if (i32.eq (local.get $m) (i32.const 2)) (then (local.set $ea (i32.and (i32.sub (local.get $v) (i32.const 1)) (i32.const 0xffff))) (call $zw16 (local.get $r) (local.get $ea)) (br $done)))
      (if (i32.eq (local.get $m) (i32.const 3)) (then (local.set $ea (i32.and (i32.sub (local.get $v) (i32.const 2)) (i32.const 0xffff))) (call $zw16 (local.get $r) (local.get $ea)) (br $done)))
      (if (i32.eq (local.get $m) (i32.const 4)) (then (local.set $ea (local.get $v)) (br $done)))
      (if (i32.eq (local.get $m) (i32.const 5)) (then (local.set $ea (i32.add (local.get $v) (call $sext8 (call $zr (i32.const 1))))) (br $done)))
      (if (i32.eq (local.get $m) (i32.const 6)) (then (local.set $ea (i32.add (local.get $v) (call $sext8 (call $zr (i32.const 0))))) (br $done)))
      (if (i32.eq (local.get $m) (i32.const 8)) (then (local.set $ea (i32.add (local.get $v) (call $sext8 (call $fetch)))) (br $done)))
      (if (i32.eq (local.get $m) (i32.const 9)) (then (local.set $ea (i32.add (local.get $v) (call $fetch16be))) (br $done)))
      (if (i32.eq (local.get $m) (i32.const 11)) (then (local.set $ea (i32.add (local.get $v) (i32.or (i32.shl (call $zr (i32.const 0)) (i32.const 8)) (call $zr (i32.const 1))))) (br $done)))
      (if (i32.eq (local.get $m) (i32.const 12)) (then (local.set $ea (call $sext8 (call $fetch))) (local.set $ea (i32.add (local.get $ea) (call $zr16 (i32.const 22)))) (br $done)))
      (if (i32.eq (local.get $m) (i32.const 13)) (then (local.set $ea (call $fetch16be)) (local.set $ea (i32.add (local.get $ea) (call $zr16 (i32.const 22)))) (br $done)))
      (if (i32.eq (local.get $m) (i32.const 15)) (then (local.set $ea (call $fetch16be)) (br $done)))
      (local.set $ea (local.get $v)))   ;; undefined forms: ,R
    (local.set $ea (i32.and (local.get $ea) (i32.const 0xffff)))
    (if (i32.and (local.get $pb) (i32.const 0x10)) (then (local.set $ea (call $mrd16be (local.get $ea)))))
    (local.get $ea))
  ;; effective address by mode: 0 immediate (returns PC and advances by n bytes), 1 direct, 2 indexed, 3 extended
  (func $ea9 (param $mode i32) (param $n i32) (result i32)
    (local $t i32)
    (if (i32.eqz (local.get $mode)) (then (local.set $t (call $zr16 (i32.const 22))) (call $zw16 (i32.const 22) (i32.and (i32.add (local.get $t) (local.get $n)) (i32.const 0xffff))) (return (local.get $t))))
    (if (i32.eq (local.get $mode) (i32.const 1)) (then (return (i32.or (i32.shl (call $zr (i32.const 2)) (i32.const 8)) (call $fetch)))))
    (if (i32.eq (local.get $mode) (i32.const 2)) (then (return (call $ea_idx))))
    (call $fetch16be))
  ;; read-modify-write group (NEG COM LSR ROR ASR ASL ROL DEC INC TST JMP CLR) on value v, returns the new value; op is the low nibble
  (func $rmw9 (param $op i32) (param $v i32) (result i32)
    (local $r i32) (local $c i32) (local $cc i32)
    (local.set $cc (call $zr (i32.const 3))) (local.set $c (i32.and (local.get $cc) (i32.const 1)))
    (block $done
      (if (i32.eqz (local.get $op)) (then (local.set $r (i32.and (i32.sub (i32.const 0) (local.get $v)) (i32.const 255)))
        (call $cc9 (i32.const 0xF0) (i32.or (call $nz8 (local.get $r)) (i32.or (select (i32.const 2) (i32.const 0) (i32.eq (local.get $v) (i32.const 0x80))) (i32.ne (local.get $v) (i32.const 0))))) (br $done)))
      (if (i32.eq (local.get $op) (i32.const 3)) (then (local.set $r (i32.xor (local.get $v) (i32.const 255))) (call $cc9 (i32.const 0xF0) (i32.or (call $nz8 (local.get $r)) (i32.const 1))) (br $done)))
      (if (i32.eq (local.get $op) (i32.const 4)) (then (local.set $r (i32.shr_u (local.get $v) (i32.const 1))) (call $cc9 (i32.const 0xF0) (i32.or (call $nz8 (local.get $r)) (i32.and (local.get $v) (i32.const 1)))) (br $done)))
      (if (i32.eq (local.get $op) (i32.const 6)) (then (local.set $r (i32.or (i32.shr_u (local.get $v) (i32.const 1)) (i32.shl (local.get $c) (i32.const 7)))) (call $cc9 (i32.const 0xF2) (i32.or (call $nz8 (local.get $r)) (i32.and (local.get $v) (i32.const 1)))) (br $done)))
      (if (i32.eq (local.get $op) (i32.const 7)) (then (local.set $r (i32.or (i32.shr_u (local.get $v) (i32.const 1)) (i32.and (local.get $v) (i32.const 0x80)))) (call $cc9 (i32.const 0xF2) (i32.or (call $nz8 (local.get $r)) (i32.and (local.get $v) (i32.const 1)))) (br $done)))
      (if (i32.eq (local.get $op) (i32.const 8)) (then (local.set $r (i32.and (i32.shl (local.get $v) (i32.const 1)) (i32.const 255)))
        (call $cc9 (i32.const 0xF0) (i32.or (call $nz8 (local.get $r)) (i32.or (i32.shl (i32.and (i32.xor (local.get $v) (local.get $r)) (i32.const 0x80)) (i32.const 1) ) (i32.shr_u (local.get $v) (i32.const 7)))))
        (call $cc9 (i32.const 0xFD) (select (i32.const 2) (i32.const 0) (i32.and (i32.xor (local.get $v) (local.get $r)) (i32.const 0x80)))) (br $done)))
      (if (i32.eq (local.get $op) (i32.const 9)) (then (local.set $r (i32.and (i32.or (i32.shl (local.get $v) (i32.const 1)) (local.get $c)) (i32.const 255)))
        (call $cc9 (i32.const 0xF0) (i32.or (call $nz8 (local.get $r)) (i32.or (select (i32.const 2) (i32.const 0) (i32.and (i32.xor (local.get $v) (local.get $r)) (i32.const 0x80))) (i32.shr_u (local.get $v) (i32.const 7))))) (br $done)))
      (if (i32.eq (local.get $op) (i32.const 10)) (then (local.set $r (i32.and (i32.sub (local.get $v) (i32.const 1)) (i32.const 255))) (call $cc9 (i32.const 0xF1) (i32.or (call $nz8 (local.get $r)) (select (i32.const 2) (i32.const 0) (i32.eq (local.get $v) (i32.const 0x80))))) (br $done)))
      (if (i32.eq (local.get $op) (i32.const 12)) (then (local.set $r (i32.and (i32.add (local.get $v) (i32.const 1)) (i32.const 255))) (call $cc9 (i32.const 0xF1) (i32.or (call $nz8 (local.get $r)) (select (i32.const 2) (i32.const 0) (i32.eq (local.get $v) (i32.const 0x7F))))) (br $done)))
      (if (i32.eq (local.get $op) (i32.const 13)) (then (local.set $r (local.get $v)) (call $cc9 (i32.const 0xF1) (call $nz8 (local.get $v))) (br $done)))
      (if (i32.eq (local.get $op) (i32.const 15)) (then (local.set $r (i32.const 0)) (call $cc9 (i32.const 0xF0) (i32.const 4)) (br $done)))
      (local.set $r (local.get $v)))
    (local.get $r))
  ;; 8-bit arithmetic/logic on accumulator a (0 or 1) with operand b: op = low nibble of the 8x/Cx rows
  (func $alu9 (param $acc i32) (param $op i32) (param $b i32)
    (local $a i32) (local $r i32) (local $c i32)
    (local.set $a (call $zr (local.get $acc))) (local.set $c (i32.and (call $zr (i32.const 3)) (i32.const 1)))
    (block $done
      (if (i32.or (i32.lt_u (local.get $op) (i32.const 3)) (i32.eq (local.get $op) (i32.const 1))) (then   ;; SUB (0), CMP (1), SBC (2)
        (local.set $r (i32.sub (i32.sub (local.get $a) (local.get $b)) (select (local.get $c) (i32.const 0) (i32.eq (local.get $op) (i32.const 2)))))
        (call $cc9 (i32.const 0xF0) (i32.or (call $nz8 (local.get $r)) (i32.or (i32.shr_u (i32.and (i32.and (i32.xor (local.get $a) (local.get $b)) (i32.xor (local.get $a) (local.get $r))) (i32.const 0x80)) (i32.const 6)) (i32.and (i32.shr_u (local.get $r) (i32.const 8)) (i32.const 1)))))
        (if (i32.ne (local.get $op) (i32.const 1)) (then (call $zw (local.get $acc) (i32.and (local.get $r) (i32.const 255)))))
        (br $done)))
      (if (i32.eq (local.get $op) (i32.const 4)) (then (local.set $r (i32.and (local.get $a) (local.get $b))) (call $zw (local.get $acc) (local.get $r)) (call $cc9 (i32.const 0xF1) (call $nz8 (local.get $r))) (br $done)))
      (if (i32.eq (local.get $op) (i32.const 5)) (then (call $cc9 (i32.const 0xF1) (call $nz8 (i32.and (local.get $a) (local.get $b)))) (br $done)))   ;; BIT
      (if (i32.eq (local.get $op) (i32.const 6)) (then (call $zw (local.get $acc) (local.get $b)) (call $cc9 (i32.const 0xF1) (call $nz8 (local.get $b))) (br $done)))   ;; LD
      (if (i32.eq (local.get $op) (i32.const 8)) (then (local.set $r (i32.xor (local.get $a) (local.get $b))) (call $zw (local.get $acc) (local.get $r)) (call $cc9 (i32.const 0xF1) (call $nz8 (local.get $r))) (br $done)))
      (if (i32.eq (local.get $op) (i32.const 10)) (then (local.set $r (i32.or (local.get $a) (local.get $b))) (call $zw (local.get $acc) (local.get $r)) (call $cc9 (i32.const 0xF1) (call $nz8 (local.get $r))) (br $done)))
      ;; ADC (9), ADD (11)
      (local.set $r (i32.add (i32.add (local.get $a) (local.get $b)) (select (local.get $c) (i32.const 0) (i32.eq (local.get $op) (i32.const 9)))))
      (call $cc9 (i32.const 0xD0) (i32.or (call $nz8 (local.get $r)) (i32.or (i32.or (i32.shl (i32.and (i32.xor (i32.xor (local.get $a) (local.get $b)) (local.get $r)) (i32.const 0x10)) (i32.const 1))
        (i32.shr_u (i32.and (i32.and (i32.xor (local.get $a) (local.get $r)) (i32.xor (local.get $b) (local.get $r))) (i32.const 0x80)) (i32.const 6))) (i32.and (i32.shr_u (local.get $r) (i32.const 8)) (i32.const 1)))))
      (call $zw (local.get $acc) (i32.and (local.get $r) (i32.const 255)))))
  (func $cmp16 (param $a i32) (param $b i32)
    (local $r i32) (local.set $r (i32.sub (local.get $a) (local.get $b)))
    (call $cc9 (i32.const 0xF0) (i32.or (call $nz16 (local.get $r)) (i32.or (i32.shr_u (i32.and (i32.and (i32.xor (local.get $a) (local.get $b)) (i32.xor (local.get $a) (local.get $r))) (i32.const 0x8000)) (i32.const 14)) (i32.and (i32.shr_u (local.get $r) (i32.const 16)) (i32.const 1))))))
  (func $branch9 (param $cond i32) (param $long i32)
    (local $e i32)
    (if (local.get $long) (then (local.set $e (call $fetch16be))) (else (local.set $e (call $sext8 (call $fetch)))))
    (if (local.get $long) (then (local.set $e (i32.shr_s (i32.shl (local.get $e) (i32.const 16)) (i32.const 16)))))
    (if (local.get $cond) (then (call $zw16 (i32.const 22) (i32.and (i32.add (call $zr16 (i32.const 22)) (local.get $e)) (i32.const 0xffff))))))
  (func $cond9 (param $y i32) (result i32)   ;; branch conditions 0..15: RA RN HI LS CC CS NE EQ VC VS PL MI GE LT GT LE
    (local $cc i32) (local $n i32) (local $z i32) (local $v i32) (local $c i32) (local $r i32)
    (local.set $cc (call $zr (i32.const 3)))
    (local.set $n (i32.and (i32.shr_u (local.get $cc) (i32.const 3)) (i32.const 1))) (local.set $z (i32.and (i32.shr_u (local.get $cc) (i32.const 2)) (i32.const 1)))
    (local.set $v (i32.and (i32.shr_u (local.get $cc) (i32.const 1)) (i32.const 1))) (local.set $c (i32.and (local.get $cc) (i32.const 1)))
    (local.set $r (select (i32.const 1) (select (i32.eqz (i32.or (local.get $c) (local.get $z))) (select (i32.eqz (local.get $c)) (select (i32.eqz (local.get $z)) (select (i32.eqz (local.get $v)) (select (i32.eqz (local.get $n))
      (select (i32.eq (local.get $n) (local.get $v)) (i32.and (i32.eq (local.get $n) (local.get $v)) (i32.eqz (local.get $z))) (i32.lt_u (local.get $y) (i32.const 14)))
      (i32.lt_u (local.get $y) (i32.const 12))) (i32.lt_u (local.get $y) (i32.const 10))) (i32.lt_u (local.get $y) (i32.const 8))) (i32.lt_u (local.get $y) (i32.const 6))) (i32.lt_u (local.get $y) (i32.const 4))) (i32.lt_u (local.get $y) (i32.const 2))))
    (i32.xor (local.get $r) (i32.and (local.get $y) (i32.const 1))))
  (func $pshpul (param $post i32) (param $sreg i32) (param $pull i32)   ;; PSHS/PULS (sreg 10) and PSHU/PULU (sreg 8)
    (local $sp i32) (local $i i32) (local $other i32)
    (local.set $sp (call $zr16 (local.get $sreg))) (local.set $other (select (i32.const 8) (i32.const 10) (i32.eq (local.get $sreg) (i32.const 10))))
    (if (local.get $pull)
      (then
        (if (i32.and (local.get $post) (i32.const 1)) (then (call $zw (i32.const 3) (call $mrd (local.get $sp))) (local.set $sp (i32.add (local.get $sp) (i32.const 1)))))
        (if (i32.and (local.get $post) (i32.const 2)) (then (call $zw (i32.const 0) (call $mrd (local.get $sp))) (local.set $sp (i32.add (local.get $sp) (i32.const 1)))))
        (if (i32.and (local.get $post) (i32.const 4)) (then (call $zw (i32.const 1) (call $mrd (local.get $sp))) (local.set $sp (i32.add (local.get $sp) (i32.const 1)))))
        (if (i32.and (local.get $post) (i32.const 8)) (then (call $zw (i32.const 2) (call $mrd (local.get $sp))) (local.set $sp (i32.add (local.get $sp) (i32.const 1)))))
        (if (i32.and (local.get $post) (i32.const 16)) (then (call $zw16 (i32.const 4) (call $mrd16be (local.get $sp))) (local.set $sp (i32.add (local.get $sp) (i32.const 2)))))
        (if (i32.and (local.get $post) (i32.const 32)) (then (call $zw16 (i32.const 6) (call $mrd16be (local.get $sp))) (local.set $sp (i32.add (local.get $sp) (i32.const 2)))))
        (if (i32.and (local.get $post) (i32.const 64)) (then (call $zw16 (local.get $other) (call $mrd16be (local.get $sp))) (local.set $sp (i32.add (local.get $sp) (i32.const 2)))))
        (if (i32.and (local.get $post) (i32.const 128)) (then (call $zw16 (i32.const 22) (call $mrd16be (local.get $sp))) (local.set $sp (i32.add (local.get $sp) (i32.const 2))))))
      (else
        (if (i32.and (local.get $post) (i32.const 128)) (then (local.set $sp (i32.sub (local.get $sp) (i32.const 2))) (call $mwr16be (local.get $sp) (call $zr16 (i32.const 22)))))
        (if (i32.and (local.get $post) (i32.const 64)) (then (local.set $sp (i32.sub (local.get $sp) (i32.const 2))) (call $mwr16be (local.get $sp) (call $zr16 (local.get $other)))))
        (if (i32.and (local.get $post) (i32.const 32)) (then (local.set $sp (i32.sub (local.get $sp) (i32.const 2))) (call $mwr16be (local.get $sp) (call $zr16 (i32.const 6)))))
        (if (i32.and (local.get $post) (i32.const 16)) (then (local.set $sp (i32.sub (local.get $sp) (i32.const 2))) (call $mwr16be (local.get $sp) (call $zr16 (i32.const 4)))))
        (if (i32.and (local.get $post) (i32.const 8)) (then (local.set $sp (i32.sub (local.get $sp) (i32.const 1))) (call $mwr (local.get $sp) (call $zr (i32.const 2)))))
        (if (i32.and (local.get $post) (i32.const 4)) (then (local.set $sp (i32.sub (local.get $sp) (i32.const 1))) (call $mwr (local.get $sp) (call $zr (i32.const 1)))))
        (if (i32.and (local.get $post) (i32.const 2)) (then (local.set $sp (i32.sub (local.get $sp) (i32.const 1))) (call $mwr (local.get $sp) (call $zr (i32.const 0)))))
        (if (i32.and (local.get $post) (i32.const 1)) (then (local.set $sp (i32.sub (local.get $sp) (i32.const 1))) (call $mwr (local.get $sp) (call $zr (i32.const 3)))))))
    (call $zw16 (local.get $sreg) (i32.and (local.get $sp) (i32.const 0xffff))))
  ;; register codes for EXG/TFR: 0 D 1 X 2 Y 3 U 4 S 5 PC 8 A 9 B A CC B DP
  (func $treg_get (param $c i32) (result i32)
    (if (i32.eqz (local.get $c)) (then (return (i32.or (i32.shl (call $zr (i32.const 0)) (i32.const 8)) (call $zr (i32.const 1))))))
    (if (i32.lt_u (local.get $c) (i32.const 5)) (then (return (call $zr16 (i32.add (i32.const 2) (i32.shl (local.get $c) (i32.const 1)))))))
    (if (i32.eq (local.get $c) (i32.const 5)) (then (return (call $zr16 (i32.const 22)))))
    (if (i32.eq (local.get $c) (i32.const 8)) (then (return (call $zr (i32.const 0)))))
    (if (i32.eq (local.get $c) (i32.const 9)) (then (return (call $zr (i32.const 1)))))
    (if (i32.eq (local.get $c) (i32.const 10)) (then (return (call $zr (i32.const 3)))))
    (if (i32.eq (local.get $c) (i32.const 11)) (then (return (call $zr (i32.const 2)))))
    (i32.const 0xffff))
  (func $treg_set (param $c i32) (param $v i32)
    (if (i32.eqz (local.get $c)) (then (call $zw (i32.const 0) (i32.shr_u (local.get $v) (i32.const 8))) (call $zw (i32.const 1) (i32.and (local.get $v) (i32.const 255))) (return)))
    (if (i32.lt_u (local.get $c) (i32.const 5)) (then (call $zw16 (i32.add (i32.const 2) (i32.shl (local.get $c) (i32.const 1))) (local.get $v)) (return)))
    (if (i32.eq (local.get $c) (i32.const 5)) (then (call $zw16 (i32.const 22) (local.get $v)) (return)))
    (if (i32.eq (local.get $c) (i32.const 8)) (then (call $zw (i32.const 0) (i32.and (local.get $v) (i32.const 255))) (return)))
    (if (i32.eq (local.get $c) (i32.const 9)) (then (call $zw (i32.const 1) (i32.and (local.get $v) (i32.const 255))) (return)))
    (if (i32.eq (local.get $c) (i32.const 10)) (then (call $zw (i32.const 3) (i32.and (local.get $v) (i32.const 255))) (return)))
    (if (i32.eq (local.get $c) (i32.const 11)) (then (call $zw (i32.const 2) (i32.and (local.get $v) (i32.const 255))))))
  (func $m6809_step
    (local $op i32) (local $page i32) (local $hi i32) (local $lo i32) (local $mode i32) (local $ea i32) (local $v i32) (local $t i32) (local $a i32) (local $b i32) (local $r i32) (local $d i32)
    (local.set $op (call $fetch))
    (if (i32.eq (local.get $op) (i32.const 0x10)) (then (local.set $page (i32.const 1)) (local.set $op (call $fetch))))
    (if (i32.eq (local.get $op) (i32.const 0x11)) (then (local.set $page (i32.const 2)) (local.set $op (call $fetch))))
    (local.set $hi (i32.shr_u (local.get $op) (i32.const 4))) (local.set $lo (i32.and (local.get $op) (i32.const 15)))
    (block $end
      ;; ---- page 2 / 3
      (if (local.get $page) (then
        (if (i32.eq (local.get $hi) (i32.const 2)) (then (if (i32.eq (local.get $page) (i32.const 1)) (then (call $branch9 (call $cond9 (local.get $lo)) (i32.const 1)))) (br $end)))
        (if (i32.lt_u (local.get $hi) (i32.const 8)) (then (br $end)))   ;; SWI2/SWI3 and undefined
        (local.set $mode (i32.and (local.get $hi) (i32.const 3)))
        (if (i32.eq (local.get $lo) (i32.const 3)) (then   ;; CMPD / CMPU
          (local.set $ea (call $ea9 (local.get $mode) (i32.const 2)))
          (call $cmp16 (select (i32.or (i32.shl (call $zr (i32.const 0)) (i32.const 8)) (call $zr (i32.const 1))) (call $zr16 (i32.const 8)) (i32.eq (local.get $page) (i32.const 1))) (call $mrd16be (local.get $ea)))
          (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 12)) (then   ;; CMPY / CMPS
          (local.set $ea (call $ea9 (local.get $mode) (i32.const 2)))
          (call $cmp16 (call $zr16 (select (i32.const 6) (i32.const 10) (i32.eq (local.get $page) (i32.const 1)))) (call $mrd16be (local.get $ea)))
          (br $end)))
        (if (i32.eq (local.get $page) (i32.const 2)) (then (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 14)) (then   ;; LDY (8x..Bx) / LDS (Cx..Fx)
          (local.set $ea (call $ea9 (local.get $mode) (i32.const 2))) (local.set $v (call $mrd16be (local.get $ea)))
          (call $zw16 (select (i32.const 6) (i32.const 10) (i32.lt_u (local.get $hi) (i32.const 12))) (local.get $v)) (call $cc9 (i32.const 0xF1) (call $nz16 (local.get $v))) (br $end)))
        (if (i32.and (i32.eq (local.get $lo) (i32.const 15)) (local.get $mode)) (then   ;; STY / STS
          (local.set $ea (call $ea9 (local.get $mode) (i32.const 0))) (local.set $v (call $zr16 (select (i32.const 6) (i32.const 10) (i32.lt_u (local.get $hi) (i32.const 12)))))
          (call $mwr16be (local.get $ea) (local.get $v)) (call $cc9 (i32.const 0xF1) (call $nz16 (local.get $v))) (br $end)))
        (br $end)))
      ;; ---- 0x: direct RMW; 6x indexed; 7x extended; 4x/5x inherent on A/B
      (if (i32.or (i32.eqz (local.get $hi)) (i32.or (i32.eq (local.get $hi) (i32.const 6)) (i32.eq (local.get $hi) (i32.const 7)))) (then
        (local.set $ea (call $ea9 (select (i32.const 1) (select (i32.const 2) (i32.const 3) (i32.eq (local.get $hi) (i32.const 6))) (i32.eqz (local.get $hi))) (i32.const 0)))
        (if (i32.eq (local.get $lo) (i32.const 14)) (then (call $zw16 (i32.const 22) (local.get $ea)) (br $end)))   ;; JMP
        (if (i32.or (i32.eq (local.get $lo) (i32.const 1)) (i32.or (i32.eq (local.get $lo) (i32.const 2)) (i32.or (i32.eq (local.get $lo) (i32.const 5)) (i32.eq (local.get $lo) (i32.const 11))))) (then (br $end)))
        (local.set $v (call $rmw9 (local.get $lo) (call $mrd (local.get $ea))))
        (if (i32.ne (local.get $lo) (i32.const 13)) (then (call $mwr (local.get $ea) (local.get $v))))
        (br $end)))
      (if (i32.or (i32.eq (local.get $hi) (i32.const 4)) (i32.eq (local.get $hi) (i32.const 5))) (then
        (local.set $a (i32.sub (local.get $hi) (i32.const 4)))
        (if (i32.or (i32.eq (local.get $lo) (i32.const 1)) (i32.or (i32.eq (local.get $lo) (i32.const 2)) (i32.or (i32.eq (local.get $lo) (i32.const 5)) (i32.or (i32.eq (local.get $lo) (i32.const 11)) (i32.eq (local.get $lo) (i32.const 14)))))) (then (br $end)))
        (local.set $v (call $rmw9 (local.get $lo) (call $zr (local.get $a))))
        (if (i32.ne (local.get $lo) (i32.const 13)) (then (call $zw (local.get $a) (local.get $v))))
        (br $end)))
      ;; ---- 1x
      (if (i32.eq (local.get $hi) (i32.const 1)) (then
        (if (i32.eq (local.get $lo) (i32.const 6)) (then (call $branch9 (i32.const 1) (i32.const 1)) (br $end)))   ;; LBRA
        (if (i32.eq (local.get $lo) (i32.const 7)) (then (local.set $t (call $fetch16be)) (call $pshpul (i32.const 0x80) (i32.const 10) (i32.const 0)) (call $zw16 (i32.const 22) (i32.and (i32.add (call $zr16 (i32.const 22)) (i32.shr_s (i32.shl (local.get $t) (i32.const 16)) (i32.const 16))) (i32.const 0xffff))) (br $end)))   ;; LBSR
        (if (i32.eq (local.get $lo) (i32.const 9)) (then   ;; DAA
          (local.set $a (call $zr (i32.const 0))) (local.set $t (i32.const 0)) (local.set $r (call $zr (i32.const 3)))
          (if (i32.or (i32.and (local.get $r) (i32.const 0x20)) (i32.gt_u (i32.and (local.get $a) (i32.const 15)) (i32.const 9))) (then (local.set $t (i32.const 6))))
          (if (i32.or (i32.and (local.get $r) (i32.const 1)) (i32.or (i32.gt_u (local.get $a) (i32.const 0x99)) (i32.and (i32.gt_u (local.get $a) (i32.const 0x8F)) (i32.gt_u (i32.and (local.get $a) (i32.const 15)) (i32.const 9))))) (then (local.set $t (i32.or (local.get $t) (i32.const 0x60)))))
          (local.set $v (i32.add (local.get $a) (local.get $t)))
          (call $zw (i32.const 0) (i32.and (local.get $v) (i32.const 255)))
          (call $cc9 (i32.const 0xF2) (i32.or (call $nz8 (local.get $v)) (i32.or (i32.and (local.get $r) (i32.const 1)) (i32.shr_u (local.get $v) (i32.const 8)))))
          (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 10)) (then (call $zw (i32.const 3) (i32.or (call $zr (i32.const 3)) (call $fetch))) (br $end)))     ;; ORCC
        (if (i32.eq (local.get $lo) (i32.const 12)) (then (call $zw (i32.const 3) (i32.and (call $zr (i32.const 3)) (call $fetch))) (br $end)))    ;; ANDCC
        (if (i32.eq (local.get $lo) (i32.const 13)) (then (call $zw (i32.const 0) (select (i32.const 255) (i32.const 0) (i32.and (call $zr (i32.const 1)) (i32.const 0x80)))) (call $cc9 (i32.const 0xF1) (call $nz16 (i32.or (i32.shl (call $zr (i32.const 0)) (i32.const 8)) (call $zr (i32.const 1))))) (br $end)))   ;; SEX
        (if (i32.or (i32.eq (local.get $lo) (i32.const 14)) (i32.eq (local.get $lo) (i32.const 15))) (then   ;; EXG / TFR
          (local.set $t (call $fetch)) (local.set $a (call $treg_get (i32.shr_u (local.get $t) (i32.const 4)))) (local.set $b (call $treg_get (i32.and (local.get $t) (i32.const 15))))
          (call $treg_set (i32.and (local.get $t) (i32.const 15)) (local.get $a))
          (if (i32.eq (local.get $lo) (i32.const 14)) (then (call $treg_set (i32.shr_u (local.get $t) (i32.const 4)) (local.get $b))))
          (br $end)))
        (br $end)))   ;; NOP, SYNC, undefined
      ;; ---- 2x branches
      (if (i32.eq (local.get $hi) (i32.const 2)) (then (call $branch9 (call $cond9 (local.get $lo)) (i32.const 0)) (br $end)))
      ;; ---- 3x
      (if (i32.eq (local.get $hi) (i32.const 3)) (then
        (if (i32.lt_u (local.get $lo) (i32.const 4)) (then   ;; LEAX LEAY LEAS LEAU
          (local.set $ea (call $ea_idx)) (call $zw16 (i32.add (i32.const 4) (i32.shl (local.get $lo) (i32.const 1))) (local.get $ea))
          (if (i32.lt_u (local.get $lo) (i32.const 2)) (then (call $cc9 (i32.const 0xFB) (select (i32.const 4) (i32.const 0) (i32.eqz (local.get $ea))))))
          (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 4)) (then (call $pshpul (call $fetch) (i32.const 10) (i32.const 0)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 5)) (then (call $pshpul (call $fetch) (i32.const 10) (i32.const 1)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 6)) (then (call $pshpul (call $fetch) (i32.const 8) (i32.const 0)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 7)) (then (call $pshpul (call $fetch) (i32.const 8) (i32.const 1)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 9)) (then (call $pshpul (i32.const 0x80) (i32.const 10) (i32.const 1)) (br $end)))   ;; RTS
        (if (i32.eq (local.get $lo) (i32.const 10)) (then (call $zw16 (i32.const 4) (i32.and (i32.add (call $zr16 (i32.const 4)) (call $zr (i32.const 1))) (i32.const 0xffff))) (br $end)))   ;; ABX
        (if (i32.eq (local.get $lo) (i32.const 11)) (then   ;; RTI: pull CC, then everything if E is set, else PC only
          (call $pshpul (i32.const 1) (i32.const 10) (i32.const 1))
          (call $pshpul (select (i32.const 0xFE) (i32.const 0x80) (i32.and (call $zr (i32.const 3)) (i32.const 0x80))) (i32.const 10) (i32.const 1))
          (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 13)) (then   ;; MUL
          (local.set $v (i32.mul (call $zr (i32.const 0)) (call $zr (i32.const 1))))
          (call $zw (i32.const 0) (i32.shr_u (local.get $v) (i32.const 8))) (call $zw (i32.const 1) (i32.and (local.get $v) (i32.const 255)))
          (call $cc9 (i32.const 0xFA) (i32.or (select (i32.const 4) (i32.const 0) (i32.eqz (local.get $v))) (i32.and (i32.shr_u (local.get $v) (i32.const 7)) (i32.const 1))))
          (br $end)))
        (br $end)))   ;; CWAI, SWI
      ;; ---- 8x..Fx: accumulator A (8x-Bx) and B (Cx-Fx) with mode = hi & 3
      (local.set $mode (i32.and (local.get $hi) (i32.const 3))) (local.set $a (i32.shr_u (i32.and (local.get $hi) (i32.const 4)) (i32.const 2)))   ;; 0 = A rows, 1 = B rows
      (if (i32.eq (local.get $lo) (i32.const 3)) (then   ;; SUBD (A rows) / ADDD (B rows)
        (local.set $ea (call $ea9 (local.get $mode) (i32.const 2))) (local.set $v (call $mrd16be (local.get $ea)))
        (local.set $d (i32.or (i32.shl (call $zr (i32.const 0)) (i32.const 8)) (call $zr (i32.const 1))))
        (if (local.get $a)
          (then (local.set $r (i32.add (local.get $d) (local.get $v)))
                (call $cc9 (i32.const 0xF0) (i32.or (call $nz16 (local.get $r)) (i32.or (i32.shr_u (i32.and (i32.and (i32.xor (local.get $d) (local.get $r)) (i32.xor (local.get $v) (local.get $r))) (i32.const 0x8000)) (i32.const 14)) (i32.and (i32.shr_u (local.get $r) (i32.const 16)) (i32.const 1))))))
          (else (local.set $r (i32.sub (local.get $d) (local.get $v)))
                (call $cc9 (i32.const 0xF0) (i32.or (call $nz16 (local.get $r)) (i32.or (i32.shr_u (i32.and (i32.and (i32.xor (local.get $d) (local.get $v)) (i32.xor (local.get $d) (local.get $r))) (i32.const 0x8000)) (i32.const 14)) (i32.and (i32.shr_u (local.get $r) (i32.const 16)) (i32.const 1)))))))
        (call $zw (i32.const 0) (i32.and (i32.shr_u (local.get $r) (i32.const 8)) (i32.const 255))) (call $zw (i32.const 1) (i32.and (local.get $r) (i32.const 255)))
        (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 12)) (then   ;; CMPX (A rows) / LDD (B rows)
        (local.set $ea (call $ea9 (local.get $mode) (i32.const 2))) (local.set $v (call $mrd16be (local.get $ea)))
        (if (local.get $a)
          (then (call $zw (i32.const 0) (i32.shr_u (local.get $v) (i32.const 8))) (call $zw (i32.const 1) (i32.and (local.get $v) (i32.const 255))) (call $cc9 (i32.const 0xF1) (call $nz16 (local.get $v))))
          (else (call $cmp16 (call $zr16 (i32.const 4)) (local.get $v))))
        (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 13)) (then   ;; BSR/JSR (A rows) / STD (B rows)
        (if (local.get $a)
          (then (if (local.get $mode) (then (local.set $ea (call $ea9 (local.get $mode) (i32.const 0))) (call $mwr16be (local.get $ea) (i32.or (i32.shl (call $zr (i32.const 0)) (i32.const 8)) (call $zr (i32.const 1)))) (call $cc9 (i32.const 0xF1) (call $nz16 (i32.or (i32.shl (call $zr (i32.const 0)) (i32.const 8)) (call $zr (i32.const 1))))))))
          (else
            (if (local.get $mode) (then (local.set $ea (call $ea9 (local.get $mode) (i32.const 0)))) (else (local.set $t (call $sext8 (call $fetch))) (local.set $ea (i32.and (i32.add (call $zr16 (i32.const 22)) (local.get $t)) (i32.const 0xffff)))))   ;; BSR is 8D: fetch the offset before reading PC
            (call $pshpul (i32.const 0x80) (i32.const 10) (i32.const 0)) (call $zw16 (i32.const 22) (local.get $ea))))
        (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 14)) (then   ;; LDX (A rows) / LDU (B rows)
        (local.set $ea (call $ea9 (local.get $mode) (i32.const 2))) (local.set $v (call $mrd16be (local.get $ea)))
        (call $zw16 (select (i32.const 8) (i32.const 4) (local.get $a)) (local.get $v)) (call $cc9 (i32.const 0xF1) (call $nz16 (local.get $v))) (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 15)) (then   ;; STX / STU (not immediate)
        (if (local.get $mode) (then (local.set $ea (call $ea9 (local.get $mode) (i32.const 0))) (local.set $v (call $zr16 (select (i32.const 8) (i32.const 4) (local.get $a)))) (call $mwr16be (local.get $ea) (local.get $v)) (call $cc9 (i32.const 0xF1) (call $nz16 (local.get $v)))))
        (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 7)) (then   ;; STA / STB (not immediate)
        (if (local.get $mode) (then (local.set $ea (call $ea9 (local.get $mode) (i32.const 0))) (local.set $v (call $zr (local.get $a))) (call $mwr (local.get $ea) (local.get $v)) (call $cc9 (i32.const 0xF1) (call $nz8 (local.get $v)))))
        (br $end)))
      ;; remaining 8-bit ops: SUB CMP SBC AND BIT LDA EOR ADC ORA ADD
      (local.set $ea (call $ea9 (local.get $mode) (i32.const 1)))
      (call $alu9 (local.get $a) (local.get $lo) (call $mrd (local.get $ea)))))
