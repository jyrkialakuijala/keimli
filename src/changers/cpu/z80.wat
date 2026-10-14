  ;; Zilog Z80 byte processor. The pixel's 16 bytes are the whole address
  ;; space (addresses wrap mod 16, stack included). Registers start at zero,
  ;; PC = 0, and 256 instructions are executed; the memory afterwards is the
  ;; output. HALT, DI, EI, IM and all port I/O are NOPs. Interrupts do not
  ;; exist. Covered: every unprefixed opcode, every CB opcode, DD/FD (IX/IY)
  ;; addressing including DDCB/FDCB, and the ED subset: ADC/SBC HL,rp;
  ;; LD (nn),rp / LD rp,(nn); NEG; RETN/RETI (as RET); LD I/R,A and A,I/R;
  ;; RRD/RLD; LDI/LDD/LDIR/LDDR; CPI/CPD/CPIR/CPDR. Other ED opcodes are NOPs.
  ;;
  ;; Register file at byte 256 of linear memory (low byte first in each pair):
  ;;   0 C  1 B  2 E  3 D  4 L  5 H  6 F  7 A   8..15 the alternate set
  ;;   16 IX  18 IY  20 SP  22 PC  24 I  25 R  27 prefix (0 none, 1 DD, 2 FD)

  ;; offset of HL, or of IX/IY under a DD/FD prefix
  (func $hloff (result i32) (local $p i32)
    (local.set $p (call $zr (i32.const 27)))
    (select (i32.const 16) (select (i32.const 18) (i32.const 4) (i32.eq (local.get $p) (i32.const 2))) (i32.eq (local.get $p) (i32.const 1))))
  (func $rpoff (param $i i32) (result i32)     ;; BC DE HL SP
    (select (i32.const 20) (select (call $hloff) (i32.shl (local.get $i) (i32.const 1)) (i32.eq (local.get $i) (i32.const 2))) (i32.eq (local.get $i) (i32.const 3))))
  (func $rp2off (param $i i32) (result i32)    ;; BC DE HL AF
    (select (i32.const 6) (select (call $hloff) (i32.shl (local.get $i) (i32.const 1)) (i32.eq (local.get $i) (i32.const 2))) (i32.eq (local.get $i) (i32.const 3))))
  ;; effective address of the (HL) operand: HL, or IX/IY + displacement byte fetched now
  (func $ea (result i32)
    (if (result i32) (call $zr (i32.const 27))
      (then (i32.and (i32.add (call $zr16 (call $hloff)) (call $sext8 (call $fetch))) (i32.const 0xffff)))
      (else (call $zr16 (i32.const 4)))))
  (func $getr (param $i i32) (param $ea i32) (result i32)
    (if (result i32) (i32.eq (local.get $i) (i32.const 6)) (then (call $mrd (local.get $ea)))
      (else (call $zr (select (i32.const 7) (i32.xor (local.get $i) (i32.const 1)) (i32.eq (local.get $i) (i32.const 7)))))))
  (func $setr (param $i i32) (param $ea i32) (param $v i32)
    (if (i32.eq (local.get $i) (i32.const 6)) (then (call $mwr (local.get $ea) (local.get $v)))
      (else (call $zw (select (i32.const 7) (i32.xor (local.get $i) (i32.const 1)) (i32.eq (local.get $i) (i32.const 7))) (local.get $v)))))
  ;; flags: S 0x80 Z 0x40 Y 0x20 H 0x10 X 0x08 PV 0x04 N 0x02 C 0x01
  (func $szp (param $v i32) (result i32)
    (i32.or (i32.or (i32.and (local.get $v) (i32.const 0xA8)) (select (i32.const 0x40) (i32.const 0) (i32.eqz (local.get $v))))
            (select (i32.const 4) (i32.const 0) (i32.eqz (i32.and (i32.popcnt (local.get $v)) (i32.const 1))))))
  ;; 8-bit ALU on A: 0 ADD 1 ADC 2 SUB 3 SBC 4 AND 5 XOR 6 OR 7 CP
  (func $alu (param $op i32) (param $b i32)
    (local $a i32) (local $r i32) (local $f i32) (local $c i32)
    (local.set $a (call $zr (i32.const 7)))
    (local.set $c (i32.and (call $zr (i32.const 6)) (i32.const 1)))
    (block $done
      (if (i32.lt_u (local.get $op) (i32.const 2)) (then   ;; ADD / ADC
        (local.set $r (i32.add (i32.add (local.get $a) (local.get $b)) (select (local.get $c) (i32.const 0) (local.get $op))))
        (local.set $f (i32.or (i32.or (i32.and (local.get $r) (i32.const 0xA8)) (select (i32.const 0x40) (i32.const 0) (i32.eqz (i32.and (local.get $r) (i32.const 255)))))
          (i32.or (i32.and (i32.xor (i32.xor (local.get $a) (local.get $b)) (local.get $r)) (i32.const 0x10))
            (i32.or (i32.shr_u (i32.and (i32.and (i32.xor (local.get $a) (local.get $r)) (i32.xor (local.get $b) (local.get $r))) (i32.const 0x80)) (i32.const 5))
                    (i32.and (i32.shr_u (local.get $r) (i32.const 8)) (i32.const 1))))))
        (call $zw (i32.const 7) (i32.and (local.get $r) (i32.const 255)))
        (br $done)))
      (if (i32.or (i32.lt_u (local.get $op) (i32.const 4)) (i32.eq (local.get $op) (i32.const 7))) (then   ;; SUB / SBC / CP
        (local.set $r (i32.sub (i32.sub (local.get $a) (local.get $b)) (select (local.get $c) (i32.const 0) (i32.eq (local.get $op) (i32.const 3)))))
        (local.set $f (i32.or (i32.or (i32.and (local.get $r) (i32.const 0xA8)) (select (i32.const 0x40) (i32.const 0) (i32.eqz (i32.and (local.get $r) (i32.const 255)))))
          (i32.or (i32.or (i32.and (i32.xor (i32.xor (local.get $a) (local.get $b)) (local.get $r)) (i32.const 0x10)) (i32.const 2))
            (i32.or (i32.shr_u (i32.and (i32.and (i32.xor (local.get $a) (local.get $b)) (i32.xor (local.get $a) (local.get $r))) (i32.const 0x80)) (i32.const 5))
                    (i32.and (i32.shr_u (local.get $r) (i32.const 8)) (i32.const 1))))))
        (if (i32.ne (local.get $op) (i32.const 7)) (then (call $zw (i32.const 7) (i32.and (local.get $r) (i32.const 255)))))
        (br $done)))
      ;; AND / XOR / OR
      (local.set $r (select (i32.and (local.get $a) (local.get $b))
                      (select (i32.xor (local.get $a) (local.get $b)) (i32.or (local.get $a) (local.get $b)) (i32.eq (local.get $op) (i32.const 5)))
                      (i32.eq (local.get $op) (i32.const 4))))
      (local.set $f (i32.or (call $szp (local.get $r)) (select (i32.const 0x10) (i32.const 0) (i32.eq (local.get $op) (i32.const 4)))))
      (call $zw (i32.const 7) (local.get $r)))
    (call $zw (i32.const 6) (local.get $f)))
  (func $inc8 (param $v i32) (result i32) (local $r i32)
    (local.set $r (i32.and (i32.add (local.get $v) (i32.const 1)) (i32.const 255)))
    (call $zw (i32.const 6) (i32.or (i32.or (i32.and (call $zr (i32.const 6)) (i32.const 1)) (i32.and (local.get $r) (i32.const 0xA8)))
      (i32.or (i32.or (select (i32.const 0x40) (i32.const 0) (i32.eqz (local.get $r))) (select (i32.const 0x10) (i32.const 0) (i32.eqz (i32.and (local.get $r) (i32.const 15)))))
              (select (i32.const 4) (i32.const 0) (i32.eq (local.get $r) (i32.const 0x80))))))
    (local.get $r))
  (func $dec8 (param $v i32) (result i32) (local $r i32)
    (local.set $r (i32.and (i32.sub (local.get $v) (i32.const 1)) (i32.const 255)))
    (call $zw (i32.const 6) (i32.or (i32.or (i32.and (call $zr (i32.const 6)) (i32.const 1)) (i32.or (i32.and (local.get $r) (i32.const 0xA8)) (i32.const 2)))
      (i32.or (i32.or (select (i32.const 0x40) (i32.const 0) (i32.eqz (local.get $r))) (select (i32.const 0x10) (i32.const 0) (i32.eq (i32.and (local.get $r) (i32.const 15)) (i32.const 15))))
              (select (i32.const 4) (i32.const 0) (i32.eq (local.get $r) (i32.const 0x7f))))))
    (local.get $r))
  ;; 16-bit add into HL/IX/IY: mode 0 ADD, 1 ADC, 2 SBC
  (func $add16 (param $mode i32) (param $b i32)
    (local $o i32) (local $a i32) (local $r i32) (local $f i32) (local $c i32)
    (local.set $o (call $hloff)) (local.set $a (call $zr16 (local.get $o)))
    (local.set $c (select (i32.and (call $zr (i32.const 6)) (i32.const 1)) (i32.const 0) (local.get $mode)))
    (if (i32.eq (local.get $mode) (i32.const 2))
      (then (local.set $r (i32.sub (i32.sub (local.get $a) (local.get $b)) (local.get $c))))
      (else (local.set $r (i32.add (i32.add (local.get $a) (local.get $b)) (local.get $c)))))
    (local.set $f (i32.or (i32.and (i32.shr_u (local.get $r) (i32.const 8)) (i32.const 0x28))
      (i32.or (i32.and (i32.shr_u (i32.xor (i32.xor (local.get $a) (local.get $b)) (local.get $r)) (i32.const 8)) (i32.const 0x10))
              (i32.and (i32.shr_u (local.get $r) (i32.const 16)) (i32.const 1)))))
    (if (local.get $mode)
      (then
        (local.set $f (i32.or (local.get $f) (i32.or (i32.and (i32.shr_u (local.get $r) (i32.const 8)) (i32.const 0x80))
          (select (i32.const 0x40) (i32.const 0) (i32.eqz (i32.and (local.get $r) (i32.const 0xffff)))))))
        (if (i32.eq (local.get $mode) (i32.const 2))
          (then (local.set $f (i32.or (local.get $f) (i32.or (i32.const 2)
                  (i32.shr_u (i32.and (i32.and (i32.xor (local.get $a) (local.get $b)) (i32.xor (local.get $a) (local.get $r))) (i32.const 0x8000)) (i32.const 13))))))
          (else (local.set $f (i32.or (local.get $f)
                  (i32.shr_u (i32.and (i32.and (i32.xor (local.get $a) (local.get $r)) (i32.xor (local.get $b) (local.get $r))) (i32.const 0x8000)) (i32.const 13)))))))
      (else (local.set $f (i32.or (local.get $f) (i32.and (call $zr (i32.const 6)) (i32.const 0xC4))))))
    (call $zw16 (local.get $o) (i32.and (local.get $r) (i32.const 0xffff)))
    (call $zw (i32.const 6) (local.get $f)))
  ;; rotates/shifts: 0 RLC 1 RRC 2 RL 3 RR 4 SLA 5 SRA 6 SLL 7 SRL; sets full flags (CB style)
  (func $rot (param $op i32) (param $v i32) (result i32)
    (local $r i32) (local $c i32) (local $cf i32)
    (local.set $cf (i32.and (call $zr (i32.const 6)) (i32.const 1)))
    (local.set $c (select (i32.and (local.get $v) (i32.const 1)) (i32.shr_u (local.get $v) (i32.const 7)) (i32.and (local.get $op) (i32.const 1))))
    (block $done (block $b7 (block $b6 (block $b5 (block $b4 (block $b3 (block $b2 (block $b1 (block $b0
      (br_table $b0 $b1 $b2 $b3 $b4 $b5 $b6 $b7 (local.get $op)))
      (local.set $r (i32.or (i32.shl (local.get $v) (i32.const 1)) (i32.shr_u (local.get $v) (i32.const 7)))) (br $done))
      (local.set $r (i32.or (i32.shr_u (local.get $v) (i32.const 1)) (i32.shl (local.get $v) (i32.const 7)))) (br $done))
      (local.set $r (i32.or (i32.shl (local.get $v) (i32.const 1)) (local.get $cf))) (br $done))
      (local.set $r (i32.or (i32.shr_u (local.get $v) (i32.const 1)) (i32.shl (local.get $cf) (i32.const 7)))) (br $done))
      (local.set $r (i32.shl (local.get $v) (i32.const 1))) (br $done))
      (local.set $r (i32.or (i32.shr_u (local.get $v) (i32.const 1)) (i32.and (local.get $v) (i32.const 0x80)))) (br $done))
      (local.set $r (i32.or (i32.shl (local.get $v) (i32.const 1)) (i32.const 1))) (br $done))
      (local.set $r (i32.shr_u (local.get $v) (i32.const 1))))
    (local.set $r (i32.and (local.get $r) (i32.const 255)))
    (call $zw (i32.const 6) (i32.or (call $szp (local.get $r)) (local.get $c)))
    (local.get $r))
  ;; condition cc[y]: NZ Z NC C PO PE P M
  (func $cc (param $y i32) (result i32) (local $f i32) (local $bit i32)
    (local.set $f (call $zr (i32.const 6)))
    (local.set $bit (select (i32.const 0x40) (select (i32.const 1) (select (i32.const 4) (i32.const 0x80) (i32.lt_u (local.get $y) (i32.const 6))) (i32.lt_u (local.get $y) (i32.const 4))) (i32.lt_u (local.get $y) (i32.const 2))))
    (i32.ne (i32.ne (i32.and (local.get $f) (local.get $bit)) (i32.const 0)) (i32.eqz (i32.and (local.get $y) (i32.const 1)))))
  (func $swap (param $a i32) (param $b i32) (param $n i32)   ;; swap n register bytes
    (local $t i32)
    (block $e (loop $l (br_if $e (i32.eqz (local.get $n)))
      (local.set $t (call $zr (local.get $a))) (call $zw (local.get $a) (call $zr (local.get $b))) (call $zw (local.get $b) (local.get $t))
      (local.set $a (i32.add (local.get $a) (i32.const 1))) (local.set $b (i32.add (local.get $b) (i32.const 1))) (local.set $n (i32.sub (local.get $n) (i32.const 1)))
      (br $l))))
  (func $daa
    (local $a i32) (local $f i32) (local $adj i32) (local $c i32) (local $r i32)
    (local.set $a (call $zr (i32.const 7))) (local.set $f (call $zr (i32.const 6)))
    (if (i32.or (i32.and (local.get $f) (i32.const 0x10)) (i32.gt_u (i32.and (local.get $a) (i32.const 15)) (i32.const 9))) (then (local.set $adj (i32.const 6))))
    (if (i32.or (i32.and (local.get $f) (i32.const 1)) (i32.gt_u (local.get $a) (i32.const 0x99))) (then (local.set $adj (i32.or (local.get $adj) (i32.const 0x60))) (local.set $c (i32.const 1))))
    (local.set $r (i32.and (select (i32.sub (local.get $a) (local.get $adj)) (i32.add (local.get $a) (local.get $adj)) (i32.and (local.get $f) (i32.const 2))) (i32.const 255)))
    (call $zw (i32.const 7) (local.get $r))
    (call $zw (i32.const 6) (i32.or (i32.or (call $szp (local.get $r)) (i32.and (local.get $f) (i32.const 2)))
      (i32.or (local.get $c) (i32.and (i32.xor (local.get $a) (local.get $r)) (i32.const 0x10))))))
  ;; CB-prefixed operation on value v with op byte; returns the new value (BIT returns v)
  (func $cbop (param $op i32) (param $v i32) (result i32)
    (local $x i32) (local $y i32) (local $bit i32)
    (local.set $x (i32.shr_u (local.get $op) (i32.const 6))) (local.set $y (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 7)))
    (local.set $bit (i32.shl (i32.const 1) (local.get $y)))
    (if (i32.eqz (local.get $x)) (then (return (call $rot (local.get $y) (local.get $v)))))
    (if (i32.eq (local.get $x) (i32.const 1)) (then   ;; BIT
      (call $zw (i32.const 6) (i32.or (i32.or (i32.and (call $zr (i32.const 6)) (i32.const 1)) (i32.const 0x10))
        (i32.or (select (i32.const 0x44) (select (i32.const 0x80) (i32.const 0) (i32.eq (local.get $y) (i32.const 7))) (i32.eqz (i32.and (local.get $v) (local.get $bit))))
                (i32.and (local.get $v) (i32.const 0x28)))))
      (return (local.get $v))))
    (if (i32.eq (local.get $x) (i32.const 2)) (then (return (i32.and (local.get $v) (i32.xor (local.get $bit) (i32.const 255))))))
    (i32.or (local.get $v) (local.get $bit)))
  ;; ED-prefixed instruction (op byte already fetched)
  (func $edop (param $op i32)
    (local $x i32) (local $y i32) (local $z i32) (local $p i32) (local $q i32) (local $a i32) (local $m i32) (local $r i32) (local $hl i32) (local $bc i32)
    (local.set $x (i32.shr_u (local.get $op) (i32.const 6))) (local.set $y (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 7)))
    (local.set $z (i32.and (local.get $op) (i32.const 7))) (local.set $p (i32.shr_u (local.get $y) (i32.const 1))) (local.set $q (i32.and (local.get $y) (i32.const 1)))
    (call $zw (i32.const 27) (i32.const 0))   ;; ED ignores DD/FD
    (if (i32.eq (local.get $x) (i32.const 1)) (then
      (if (i32.eq (local.get $z) (i32.const 2)) (then (call $add16 (select (i32.const 1) (i32.const 2) (local.get $q)) (call $zr16 (call $rpoff (local.get $p)))) (return)))
      (if (i32.eq (local.get $z) (i32.const 3)) (then
        (local.set $a (call $fetch16))
        (if (local.get $q) (then (call $zw16 (call $rpoff (local.get $p)) (call $mrd16 (local.get $a))))
          (else (call $mwr16 (local.get $a) (call $zr16 (call $rpoff (local.get $p))))))
        (return)))
      (if (i32.eq (local.get $z) (i32.const 4)) (then (local.set $a (call $zr (i32.const 7))) (call $zw (i32.const 7) (i32.const 0)) (call $alu (i32.const 2) (local.get $a)) (return)))
      (if (i32.eq (local.get $z) (i32.const 5)) (then (call $zw16 (i32.const 22) (call $pop)) (return)))
      (if (i32.eq (local.get $z) (i32.const 7)) (then
        (if (i32.eq (local.get $y) (i32.const 0)) (then (call $zw (i32.const 24) (call $zr (i32.const 7))) (return)))
        (if (i32.eq (local.get $y) (i32.const 1)) (then (call $zw (i32.const 25) (call $zr (i32.const 7))) (return)))
        (if (i32.lt_u (local.get $y) (i32.const 4)) (then   ;; LD A,I / LD A,R
          (local.set $a (call $zr (i32.add (i32.const 22) (local.get $y))))
          (call $zw (i32.const 7) (local.get $a))
          (call $zw (i32.const 6) (i32.or (i32.and (call $zr (i32.const 6)) (i32.const 1)) (i32.and (call $szp (local.get $a)) (i32.const 0xE8))))
          (return)))
        (if (i32.lt_u (local.get $y) (i32.const 6)) (then   ;; RRD / RLD
          (local.set $hl (call $zr16 (i32.const 4))) (local.set $m (call $mrd (local.get $hl))) (local.set $a (call $zr (i32.const 7)))
          (if (i32.eq (local.get $y) (i32.const 4))
            (then (call $mwr (local.get $hl) (i32.and (i32.or (i32.shl (local.get $a) (i32.const 4)) (i32.shr_u (local.get $m) (i32.const 4))) (i32.const 255)))
                  (local.set $a (i32.or (i32.and (local.get $a) (i32.const 0xf0)) (i32.and (local.get $m) (i32.const 15)))))
            (else (call $mwr (local.get $hl) (i32.and (i32.or (i32.shl (local.get $m) (i32.const 4)) (i32.and (local.get $a) (i32.const 15))) (i32.const 255)))
                  (local.set $a (i32.or (i32.and (local.get $a) (i32.const 0xf0)) (i32.shr_u (local.get $m) (i32.const 4))))))
          (call $zw (i32.const 7) (local.get $a))
          (call $zw (i32.const 6) (i32.or (i32.and (call $zr (i32.const 6)) (i32.const 1)) (call $szp (local.get $a))))
          (return)))))
      (return)))   ;; IN/OUT/IM and the rest: NOP
    (if (i32.and (i32.eq (local.get $x) (i32.const 2)) (i32.and (i32.ge_u (local.get $y) (i32.const 4)) (i32.lt_u (local.get $z) (i32.const 2)))) (then
      (local.set $hl (call $zr16 (i32.const 4))) (local.set $bc (i32.and (i32.sub (call $zr16 (i32.const 0)) (i32.const 1)) (i32.const 0xffff)))
      (local.set $m (call $mrd (local.get $hl)))
      (if (i32.eqz (local.get $z))
        (then   ;; LDI/LDD/LDIR/LDDR
          (call $mwr (call $zr16 (i32.const 2)) (local.get $m))
          (call $zw16 (i32.const 2) (i32.and (i32.add (call $zr16 (i32.const 2)) (select (i32.const -1) (i32.const 1) (i32.and (local.get $y) (i32.const 1)))) (i32.const 0xffff)))
          (call $zw (i32.const 6) (i32.or (i32.and (call $zr (i32.const 6)) (i32.const 0xC1)) (select (i32.const 4) (i32.const 0) (local.get $bc))))
          (if (i32.and (i32.ge_u (local.get $y) (i32.const 6)) (i32.ne (local.get $bc) (i32.const 0)))
            (then (call $zw16 (i32.const 22) (i32.and (i32.sub (call $zr16 (i32.const 22)) (i32.const 2)) (i32.const 0xffff))))))
        (else   ;; CPI/CPD/CPIR/CPDR
          (local.set $a (call $zr (i32.const 7))) (local.set $r (i32.and (i32.sub (local.get $a) (local.get $m)) (i32.const 255)))
          (call $zw (i32.const 6) (i32.or (i32.or (i32.and (call $zr (i32.const 6)) (i32.const 1)) (i32.const 2))
            (i32.or (i32.or (i32.and (local.get $r) (i32.const 0xA8)) (select (i32.const 0x40) (i32.const 0) (i32.eqz (local.get $r))))
              (i32.or (i32.and (i32.xor (i32.xor (local.get $a) (local.get $m)) (local.get $r)) (i32.const 0x10)) (select (i32.const 4) (i32.const 0) (local.get $bc))))))
          (if (i32.and (i32.ge_u (local.get $y) (i32.const 6)) (i32.and (i32.ne (local.get $bc) (i32.const 0)) (i32.ne (local.get $r) (i32.const 0))))
            (then (call $zw16 (i32.const 22) (i32.and (i32.sub (call $zr16 (i32.const 22)) (i32.const 2)) (i32.const 0xffff)))))))
      (call $zw16 (i32.const 4) (i32.and (i32.add (local.get $hl) (select (i32.const -1) (i32.const 1) (i32.and (local.get $y) (i32.const 1)))) (i32.const 0xffff)))
      (call $zw16 (i32.const 0) (local.get $bc)))))
  ;; one instruction (prefix bytes are part of it)
  (func $zstep
    (local $op i32) (local $x i32) (local $y i32) (local $z i32) (local $p i32) (local $q i32) (local $ea i32) (local $t i32) (local $v i32)
    (call $zw (i32.const 27) (i32.const 0))
    (local.set $op (call $fetch))
    (if (i32.or (i32.eq (local.get $op) (i32.const 0xDD)) (i32.eq (local.get $op) (i32.const 0xFD))) (then
      (call $zw (i32.const 27) (select (i32.const 1) (i32.const 2) (i32.eq (local.get $op) (i32.const 0xDD))))
      (local.set $op (call $fetch))
      ;; a prefix followed by another prefix: this step ends here (like the 4 cycles a real Z80
      ;; spends on it); rewind PC so the next step starts at the second prefix
      (if (i32.or (i32.eq (local.get $op) (i32.const 0xDD)) (i32.eq (local.get $op) (i32.const 0xFD))) (then
        (call $zw16 (i32.const 22) (i32.and (i32.sub (call $zr16 (i32.const 22)) (i32.const 1)) (i32.const 0xffff)))
        (call $zw (i32.const 27) (i32.const 0))
        (return)))))
    (local.set $x (i32.shr_u (local.get $op) (i32.const 6))) (local.set $y (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 7)))
    (local.set $z (i32.and (local.get $op) (i32.const 7))) (local.set $p (i32.shr_u (local.get $y) (i32.const 1))) (local.set $q (i32.and (local.get $y) (i32.const 1)))
    (block $end
      ;; ---- x = 1: LD r,r' (HALT -> NOP)
      (if (i32.eq (local.get $x) (i32.const 1)) (then
        (if (i32.and (i32.eq (local.get $y) (i32.const 6)) (i32.eq (local.get $z) (i32.const 6))) (then (br $end)))
        (if (i32.or (i32.eq (local.get $y) (i32.const 6)) (i32.eq (local.get $z) (i32.const 6))) (then (local.set $ea (call $ea))))
        (call $setr (local.get $y) (local.get $ea) (call $getr (local.get $z) (local.get $ea)))
        (br $end)))
      ;; ---- x = 2: ALU A,r
      (if (i32.eq (local.get $x) (i32.const 2)) (then
        (if (i32.eq (local.get $z) (i32.const 6)) (then (local.set $ea (call $ea))))
        (call $alu (local.get $y) (call $getr (local.get $z) (local.get $ea)))
        (br $end)))
      ;; ---- x = 0
      (if (i32.eqz (local.get $x)) (then
        (if (i32.eqz (local.get $z)) (then
          (if (i32.eq (local.get $y) (i32.const 1)) (then (call $swap (i32.const 6) (i32.const 14) (i32.const 2)) (br $end)))
          (if (i32.ge_u (local.get $y) (i32.const 2)) (then
            (local.set $t (call $sext8 (call $fetch)))
            (if (i32.eq (local.get $y) (i32.const 2)) (then   ;; DJNZ
              (call $zw (i32.const 1) (i32.and (i32.sub (call $zr (i32.const 1)) (i32.const 1)) (i32.const 255)))
              (if (call $zr (i32.const 1)) (then (call $zw16 (i32.const 22) (i32.and (i32.add (call $zr16 (i32.const 22)) (local.get $t)) (i32.const 0xffff)))))
              (br $end)))
            (if (i32.or (i32.eq (local.get $y) (i32.const 3)) (call $cc (i32.sub (local.get $y) (i32.const 4))))
              (then (call $zw16 (i32.const 22) (i32.and (i32.add (call $zr16 (i32.const 22)) (local.get $t)) (i32.const 0xffff)))))
            (br $end)))
          (br $end)))   ;; NOP
        (if (i32.eq (local.get $z) (i32.const 1)) (then
          (if (local.get $q) (then (call $add16 (i32.const 0) (call $zr16 (call $rpoff (local.get $p)))))
            (else (call $zw16 (call $rpoff (local.get $p)) (call $fetch16))))
          (br $end)))
        (if (i32.eq (local.get $z) (i32.const 2)) (then
          (if (i32.eqz (local.get $p)) (then (local.set $t (call $zr16 (i32.const 0))))
            (else (if (i32.eq (local.get $p) (i32.const 1)) (then (local.set $t (call $zr16 (i32.const 2)))) (else (local.set $t (call $fetch16))))))   ;; no select here: fetch16 has side effects
          (if (local.get $q)
            (then (if (i32.eq (local.get $p) (i32.const 2)) (then (call $zw16 (call $hloff) (call $mrd16 (local.get $t)))) (else (call $zw (i32.const 7) (call $mrd (local.get $t))))))
            (else (if (i32.eq (local.get $p) (i32.const 2)) (then (call $mwr16 (local.get $t) (call $zr16 (call $hloff)))) (else (call $mwr (local.get $t) (call $zr (i32.const 7)))))))
          (br $end)))
        (if (i32.eq (local.get $z) (i32.const 3)) (then
          (local.set $t (call $rpoff (local.get $p)))
          (call $zw16 (local.get $t) (i32.and (i32.add (call $zr16 (local.get $t)) (select (i32.const -1) (i32.const 1) (local.get $q))) (i32.const 0xffff)))
          (br $end)))
        (if (i32.lt_u (local.get $z) (i32.const 6)) (then   ;; INC r / DEC r
          (if (i32.eq (local.get $y) (i32.const 6)) (then (local.set $ea (call $ea))))
          (local.set $v (call $getr (local.get $y) (local.get $ea)))
          (if (i32.eq (local.get $z) (i32.const 4))
            (then (call $setr (local.get $y) (local.get $ea) (call $inc8 (local.get $v))))
            (else (call $setr (local.get $y) (local.get $ea) (call $dec8 (local.get $v)))))
          (br $end)))
        (if (i32.eq (local.get $z) (i32.const 6)) (then   ;; LD r,n
          (if (i32.eq (local.get $y) (i32.const 6)) (then (local.set $ea (call $ea))))
          (call $setr (local.get $y) (local.get $ea) (call $fetch))
          (br $end)))
        ;; z = 7: RLCA RRCA RLA RRA DAA CPL SCF CCF
        (if (i32.lt_u (local.get $y) (i32.const 4)) (then
          (local.set $t (call $zr (i32.const 6)))
          (local.set $v (call $rot (local.get $y) (call $zr (i32.const 7))))
          (call $zw (i32.const 7) (local.get $v))
          (call $zw (i32.const 6) (i32.or (i32.and (local.get $t) (i32.const 0xC4)) (i32.or (i32.and (local.get $v) (i32.const 0x28)) (i32.and (call $zr (i32.const 6)) (i32.const 1)))))
          (br $end)))
        (if (i32.eq (local.get $y) (i32.const 4)) (then (call $daa) (br $end)))
        (if (i32.eq (local.get $y) (i32.const 5)) (then
          (call $zw (i32.const 7) (i32.xor (call $zr (i32.const 7)) (i32.const 255)))
          (call $zw (i32.const 6) (i32.or (i32.and (call $zr (i32.const 6)) (i32.const 0xC5)) (i32.or (i32.const 0x12) (i32.and (call $zr (i32.const 7)) (i32.const 0x28)))))
          (br $end)))
        (local.set $t (call $zr (i32.const 6)))
        (if (i32.eq (local.get $y) (i32.const 6))
          (then (call $zw (i32.const 6) (i32.or (i32.and (local.get $t) (i32.const 0xC4)) (i32.or (i32.const 1) (i32.and (call $zr (i32.const 7)) (i32.const 0x28))))))
          (else (call $zw (i32.const 6) (i32.or (i32.and (local.get $t) (i32.const 0xC4))
                  (i32.or (i32.or (i32.shl (i32.and (local.get $t) (i32.const 1)) (i32.const 4)) (i32.xor (i32.and (local.get $t) (i32.const 1)) (i32.const 1)))
                          (i32.and (call $zr (i32.const 7)) (i32.const 0x28)))))))
        (br $end)))
      ;; ---- x = 3
      (if (i32.eqz (local.get $z)) (then (if (call $cc (local.get $y)) (then (call $zw16 (i32.const 22) (call $pop)))) (br $end)))
      (if (i32.eq (local.get $z) (i32.const 1)) (then
        (if (i32.eqz (local.get $q)) (then (call $zw16 (call $rp2off (local.get $p)) (call $pop)) (br $end)))
        (if (i32.eqz (local.get $p)) (then (call $zw16 (i32.const 22) (call $pop)) (br $end)))
        (if (i32.eq (local.get $p) (i32.const 1)) (then (call $swap (i32.const 0) (i32.const 8) (i32.const 6)) (br $end)))
        (if (i32.eq (local.get $p) (i32.const 2)) (then (call $zw16 (i32.const 22) (call $zr16 (call $hloff))) (br $end)))
        (call $zw16 (i32.const 20) (call $zr16 (call $hloff)))
        (br $end)))
      (if (i32.eq (local.get $z) (i32.const 2)) (then
        (local.set $t (call $fetch16))
        (if (call $cc (local.get $y)) (then (call $zw16 (i32.const 22) (local.get $t))))
        (br $end)))
      (if (i32.eq (local.get $z) (i32.const 3)) (then
        (if (i32.eqz (local.get $y)) (then (call $zw16 (i32.const 22) (call $fetch16)) (br $end)))
        (if (i32.eq (local.get $y) (i32.const 1)) (then   ;; CB prefix
          (if (call $zr (i32.const 27))
            (then (local.set $ea (call $ea)) (local.set $op (call $fetch))
                  (local.set $v (call $cbop (local.get $op) (call $mrd (local.get $ea))))
                  (if (i32.ne (i32.shr_u (local.get $op) (i32.const 6)) (i32.const 1)) (then (call $mwr (local.get $ea) (local.get $v)))))
            (else (local.set $op (call $fetch)) (local.set $z (i32.and (local.get $op) (i32.const 7)))
                  (local.set $ea (select (call $zr16 (i32.const 4)) (i32.const 0) (i32.eq (local.get $z) (i32.const 6))))
                  (local.set $v (call $cbop (local.get $op) (call $getr (local.get $z) (local.get $ea))))
                  (if (i32.ne (i32.shr_u (local.get $op) (i32.const 6)) (i32.const 1)) (then (call $setr (local.get $z) (local.get $ea) (local.get $v))))))
          (br $end)))
        (if (i32.lt_u (local.get $y) (i32.const 4)) (then (drop (call $fetch)) (br $end)))   ;; OUT (n),A / IN A,(n): NOP
        (if (i32.eq (local.get $y) (i32.const 4)) (then   ;; EX (SP),HL
          (local.set $t (call $zr16 (i32.const 20))) (local.set $v (call $mrd16 (local.get $t)))
          (call $mwr16 (local.get $t) (call $zr16 (call $hloff))) (call $zw16 (call $hloff) (local.get $v))
          (br $end)))
        (if (i32.eq (local.get $y) (i32.const 5)) (then (call $swap (i32.const 2) (i32.const 4) (i32.const 2)) (br $end)))
        (br $end)))   ;; DI / EI: NOP
      (if (i32.eq (local.get $z) (i32.const 4)) (then
        (local.set $t (call $fetch16))
        (if (call $cc (local.get $y)) (then (call $push (call $zr16 (i32.const 22))) (call $zw16 (i32.const 22) (local.get $t))))
        (br $end)))
      (if (i32.eq (local.get $z) (i32.const 5)) (then
        (if (i32.eqz (local.get $q)) (then (call $push (call $zr16 (call $rp2off (local.get $p)))) (br $end)))
        (if (i32.eqz (local.get $p)) (then (local.set $t (call $fetch16)) (call $push (call $zr16 (i32.const 22))) (call $zw16 (i32.const 22) (local.get $t)) (br $end)))
        (if (i32.eq (local.get $p) (i32.const 2)) (then (call $edop (call $fetch)) (br $end)))
        (br $end)))
      (if (i32.eq (local.get $z) (i32.const 6)) (then (call $alu (local.get $y) (call $fetch)) (br $end)))
      ;; RST y*8
      (call $push (call $zr16 (i32.const 22)))
      (call $zw16 (i32.const 22) (i32.shl (local.get $y) (i32.const 3))))
    (call $zw (i32.const 27) (i32.const 0)))
  ;; z80(p, prm): run 256 instructions over the pixel's 16 bytes; memory afterwards is the output.
  ;; flags[i] = 1 where the byte changed; prm.lastOffset = final PC. Returns (256 << 8) | changed bytes.
  (func $z80 (param $p i32) (param $prm i32) (result i32)
    (local $out i32) (local $flags i32) (local $i i32) (local $changed i32) (local $c i32)
    (local.set $out (i32.load (local.get $prm)))
    (local.set $flags (i32.load offset=36 (local.get $prm)))
    ;; work on a copy in the output buffer so the pixel itself is untouched until change() commits it
    (i64.store (local.get $out) (i64.load (local.get $p)))
    (i64.store offset=8 (local.get $out) (i64.load offset=8 (local.get $p)))
    (global.set $zp (local.get $out))
    (block $re (loop $rl (br_if $re (i32.ge_u (local.get $i) (i32.const 28))) (call $zw (local.get $i) (i32.const 0)) (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $rl)))
    (local.set $i (i32.const 0))
    (block $se (loop $sl (br_if $se (i32.ge_u (local.get $i) (i32.load offset=92 (local.get $prm)))) (call $zstep) (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $sl)))
    (local.set $i (i32.const 0))
    (block $ce (loop $cl
      (br_if $ce (i32.ge_u (local.get $i) (i32.const 16)))
      (local.set $c (i32.ne (i32.load8_u (i32.add (local.get $out) (local.get $i))) (i32.load8_u (i32.add (local.get $p) (local.get $i)))))
      (i32.store8 (i32.add (local.get $flags) (local.get $i)) (local.get $c))
      (local.set $changed (i32.add (local.get $changed) (local.get $c)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $cl)))
    (i32.store offset=48 (local.get $prm) (call $zr16 (i32.const 22)))
    (i32.or (i32.shl (i32.load offset=92 (local.get $prm)) (i32.const 8)) (local.get $changed)))
