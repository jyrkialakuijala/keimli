  ;; ========================================================================
  ;; Intel 8051 (kind 13). Internal RAM is the pixel's 16 bytes (direct and
  ;; indirect addresses below 80h wrap mod 16), so the register banks live in
  ;; the pixel: R0..R7 of bank 0 are bytes 0..7. Program memory is the same 16
  ;; bytes; MOVX and MOVC also read/write them. SFRs live in the register file:
  ;; ACC 0, B 1, PSW 2, SP 3, DPL 4, DPH 5; any other SFR address maps to a
  ;; scratch byte at 40 + (addr & 15). Bit addresses below 80h map into bytes
  ;; 20h..2Fh (mod 16 -> the pixel), those at or above 80h into the SFR bytes.
  ;; PC at 22. Reserved opcode A5h is a NOP. PSW.P is the parity of ACC.
  (func $sfr51 (param $a i32) (result i32)   ;; register-file offset of an SFR address
    (if (i32.eq (local.get $a) (i32.const 0xE0)) (then (return (i32.const 0))))
    (if (i32.eq (local.get $a) (i32.const 0xF0)) (then (return (i32.const 1))))
    (if (i32.eq (local.get $a) (i32.const 0xD0)) (then (return (i32.const 2))))
    (if (i32.eq (local.get $a) (i32.const 0x81)) (then (return (i32.const 3))))
    (if (i32.eq (local.get $a) (i32.const 0x82)) (then (return (i32.const 4))))
    (if (i32.eq (local.get $a) (i32.const 0x83)) (then (return (i32.const 5))))
    (i32.add (i32.const 40) (i32.and (local.get $a) (i32.const 15))))
  (func $drd (param $a i32) (result i32)   ;; direct read
    (if (result i32) (i32.and (local.get $a) (i32.const 0x80)) (then (call $zr (call $sfr51 (local.get $a)))) (else (call $mrd (local.get $a)))))
  (func $dwr (param $a i32) (param $v i32)
    (if (i32.and (local.get $a) (i32.const 0x80)) (then (call $zw (call $sfr51 (local.get $a)) (local.get $v))) (else (call $mwr (local.get $a) (local.get $v)))))
  (func $rn (param $n i32) (result i32)   ;; RAM address of register n in the selected bank
    (i32.add (i32.shl (i32.and (i32.shr_u (call $zr (i32.const 2)) (i32.const 3)) (i32.const 3)) (i32.const 3)) (local.get $n)))
  (func $bitaddr (param $b i32) (result i32)   ;; direct address of the byte holding bit b
    (select (i32.and (local.get $b) (i32.const 0xF8)) (i32.add (i32.const 0x20) (i32.shr_u (local.get $b) (i32.const 3))) (i32.and (local.get $b) (i32.const 0x80))))
  (func $bitrd (param $b i32) (result i32)
    (i32.and (i32.shr_u (call $drd (call $bitaddr (local.get $b))) (i32.and (local.get $b) (i32.const 7))) (i32.const 1)))
  (func $bitwr (param $b i32) (param $v i32)
    (local $a i32) (local $m i32)
    (local.set $a (call $bitaddr (local.get $b))) (local.set $m (i32.shl (i32.const 1) (i32.and (local.get $b) (i32.const 7))))
    (call $dwr (local.get $a) (select (i32.or (call $drd (local.get $a)) (local.get $m)) (i32.and (call $drd (local.get $a)) (i32.xor (local.get $m) (i32.const 255))) (local.get $v))))
  (func $cy51 (result i32) (i32.shr_u (call $zr (i32.const 2)) (i32.const 7)))
  (func $setcy (param $c i32) (call $zw (i32.const 2) (i32.or (i32.and (call $zr (i32.const 2)) (i32.const 0x7F)) (i32.shl (local.get $c) (i32.const 7)))))
  (func $add51 (param $b i32) (param $c i32)   ;; ACC = ACC + b + c with CY AC OV
    (local $a i32) (local $r i32)
    (local.set $a (call $zr (i32.const 0))) (local.set $r (i32.add (i32.add (local.get $a) (local.get $b)) (local.get $c)))
    (call $zw (i32.const 0) (i32.and (local.get $r) (i32.const 255)))
    (call $zw (i32.const 2) (i32.or (i32.and (call $zr (i32.const 2)) (i32.const 0x3B))
      (i32.or (i32.or (i32.shl (i32.shr_u (local.get $r) (i32.const 8)) (i32.const 7)) (i32.shl (i32.gt_u (i32.add (i32.add (i32.and (local.get $a) (i32.const 15)) (i32.and (local.get $b) (i32.const 15))) (local.get $c)) (i32.const 15)) (i32.const 6)))
              (i32.shl (i32.shr_u (i32.and (i32.and (i32.xor (local.get $a) (local.get $r)) (i32.xor (local.get $b) (local.get $r))) (i32.const 0x80)) (i32.const 7)) (i32.const 2))))))
  (func $subb51 (param $b i32)   ;; ACC = ACC - b - CY
    (local $a i32) (local $r i32) (local $c i32)
    (local.set $a (call $zr (i32.const 0))) (local.set $c (call $cy51)) (local.set $r (i32.sub (i32.sub (local.get $a) (local.get $b)) (local.get $c)))
    (call $zw (i32.const 0) (i32.and (local.get $r) (i32.const 255)))
    (call $zw (i32.const 2) (i32.or (i32.and (call $zr (i32.const 2)) (i32.const 0x3B))
      (i32.or (i32.or (i32.shl (i32.and (i32.shr_u (local.get $r) (i32.const 8)) (i32.const 1)) (i32.const 7)) (i32.shl (i32.lt_s (i32.sub (i32.sub (i32.and (local.get $a) (i32.const 15)) (i32.and (local.get $b) (i32.const 15))) (local.get $c)) (i32.const 0)) (i32.const 6)))
              (i32.shl (i32.shr_u (i32.and (i32.and (i32.xor (local.get $a) (local.get $b)) (i32.xor (local.get $a) (local.get $r))) (i32.const 0x80)) (i32.const 7)) (i32.const 2))))))
  ;; operand of the regular groups by low nibble: 4 = immediate, 5 = direct, 6/7 = @R0/@R1, 8..F = Rn.
  ;; Returns the value; for 5..F also leaves the operand's address in global $zp-independent local via $lastaddr.
  (global $lastaddr (mut i32) (i32.const 0))
  (func $src51 (param $lo i32) (result i32)
    (if (i32.eq (local.get $lo) (i32.const 4)) (then (return (call $fetch))))
    (if (i32.eq (local.get $lo) (i32.const 5)) (then (global.set $lastaddr (call $fetch)) (return (call $drd (global.get $lastaddr)))))
    (if (i32.lt_u (local.get $lo) (i32.const 8)) (then (global.set $lastaddr (call $mrd (call $rn (i32.and (local.get $lo) (i32.const 1))))) (return (call $mrd (global.get $lastaddr)))))
    (global.set $lastaddr (call $rn (i32.and (local.get $lo) (i32.const 7))))
    (call $mrd (global.get $lastaddr)))
  (func $dst51 (param $lo i32) (param $v i32)   ;; write back to the operand selected by $src51 (modes 5..F)
    (if (i32.eq (local.get $lo) (i32.const 5)) (then (call $dwr (global.get $lastaddr) (local.get $v))) (else (call $mwr (global.get $lastaddr) (local.get $v)))))
  (func $push51 (param $v i32)
    (call $zw (i32.const 3) (i32.and (i32.add (call $zr (i32.const 3)) (i32.const 1)) (i32.const 255)))
    (call $mwr (call $zr (i32.const 3)) (local.get $v)))
  (func $pop51 (result i32) (local $v i32)
    (local.set $v (call $mrd (call $zr (i32.const 3))))
    (call $zw (i32.const 3) (i32.and (i32.sub (call $zr (i32.const 3)) (i32.const 1)) (i32.const 255)))
    (local.get $v))
  (func $rel51 (param $cond i32)   ;; conditional relative jump; the offset byte is fetched here
    (local $e i32) (local.set $e (call $sext8 (call $fetch)))
    (if (local.get $cond) (then (call $zw16 (i32.const 22) (i32.and (i32.add (call $zr16 (i32.const 22)) (local.get $e)) (i32.const 0xffff))))))
  (func $i8051_step
    (local $op i32) (local $hi i32) (local $lo i32) (local $a i32) (local $v i32) (local $t i32) (local $u i32) (local $d i32)
    (local.set $op (call $fetch)) (local.set $hi (i32.shr_u (local.get $op) (i32.const 4))) (local.set $lo (i32.and (local.get $op) (i32.const 15)))
    (local.set $a (call $zr (i32.const 0)))
    (block $end
      ;; ---- column 1: AJMP / ACALL (odd rows call)
      (if (i32.eq (local.get $lo) (i32.const 1)) (then
        (local.set $t (i32.or (i32.shl (i32.shr_u (local.get $op) (i32.const 5)) (i32.const 8)) (call $fetch)))
        (if (i32.and (local.get $hi) (i32.const 1)) (then (call $push51 (i32.and (call $zr16 (i32.const 22)) (i32.const 255))) (call $push51 (i32.shr_u (call $zr16 (i32.const 22)) (i32.const 8)))))
        (call $zw16 (i32.const 22) (i32.or (i32.and (call $zr16 (i32.const 22)) (i32.const 0xF800)) (local.get $t)))
        (br $end)))
      ;; ---- regular groups (columns 4..F) by row
      (if (i32.ge_u (local.get $lo) (i32.const 4)) (then
        (if (i32.eqz (local.get $hi)) (then (local.set $v (call $src51 (local.get $lo))) (if (i32.eq (local.get $lo) (i32.const 4)) (then (call $zw (i32.const 0) (i32.and (i32.add (local.get $a) (i32.const 1)) (i32.const 255)))) (else (call $dst51 (local.get $lo) (i32.and (i32.add (local.get $v) (i32.const 1)) (i32.const 255))))) (br $end)))   ;; INC (04 INC A has no operand byte: src51(4) would fetch; handle below)
        (if (i32.eq (local.get $hi) (i32.const 1)) (then (local.set $v (call $src51 (local.get $lo))) (if (i32.eq (local.get $lo) (i32.const 4)) (then (call $zw (i32.const 0) (i32.and (i32.sub (local.get $a) (i32.const 1)) (i32.const 255)))) (else (call $dst51 (local.get $lo) (i32.and (i32.sub (local.get $v) (i32.const 1)) (i32.const 255))))) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 2)) (then (call $add51 (call $src51 (local.get $lo)) (i32.const 0)) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 3)) (then (call $add51 (call $src51 (local.get $lo)) (call $cy51)) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 4)) (then (call $zw (i32.const 0) (i32.or (local.get $a) (call $src51 (local.get $lo)))) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 5)) (then (call $zw (i32.const 0) (i32.and (local.get $a) (call $src51 (local.get $lo)))) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 6)) (then (call $zw (i32.const 0) (i32.xor (local.get $a) (call $src51 (local.get $lo)))) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 7)) (then   ;; MOV dst,#imm (74: MOV A,#)
          (if (i32.eq (local.get $lo) (i32.const 4)) (then (call $zw (i32.const 0) (call $fetch)) (br $end)))
          (if (i32.eq (local.get $lo) (i32.const 5)) (then (local.set $d (call $fetch)) (call $dwr (local.get $d) (call $fetch)) (br $end)))
          (if (i32.lt_u (local.get $lo) (i32.const 8)) (then (call $mwr (call $mrd (call $rn (i32.and (local.get $lo) (i32.const 1)))) (call $fetch)) (br $end)))
          (call $mwr (call $rn (i32.and (local.get $lo) (i32.const 7))) (call $fetch)) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 8)) (then   ;; 84 DIV AB, 85 MOV dir,dir, 86.. MOV dir,src
          (if (i32.eq (local.get $lo) (i32.const 4)) (then
            (local.set $v (call $zr (i32.const 1)))
            (if (local.get $v) (then (call $zw (i32.const 0) (i32.div_u (local.get $a) (local.get $v))) (call $zw (i32.const 1) (i32.rem_u (local.get $a) (local.get $v))) (call $zw (i32.const 2) (i32.and (call $zr (i32.const 2)) (i32.const 0x7B))))
              (else (call $zw (i32.const 2) (i32.or (i32.and (call $zr (i32.const 2)) (i32.const 0x7B)) (i32.const 4)))))
            (br $end)))
          (if (i32.eq (local.get $lo) (i32.const 5)) (then (local.set $v (call $drd (call $fetch))) (call $dwr (call $fetch) (local.get $v)) (br $end)))
          (local.set $v (call $src51 (local.get $lo))) (call $dwr (call $fetch) (local.get $v)) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 9)) (then (call $subb51 (call $src51 (local.get $lo))) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 10)) (then   ;; A4 MUL AB, A5 reserved, A6.. MOV dst,direct
          (if (i32.eq (local.get $lo) (i32.const 4)) (then
            (local.set $v (i32.mul (local.get $a) (call $zr (i32.const 1))))
            (call $zw (i32.const 0) (i32.and (local.get $v) (i32.const 255))) (call $zw (i32.const 1) (i32.shr_u (local.get $v) (i32.const 8)))
            (call $zw (i32.const 2) (i32.or (i32.and (call $zr (i32.const 2)) (i32.const 0x7B)) (i32.shl (i32.gt_u (local.get $v) (i32.const 255)) (i32.const 2))))
            (br $end)))
          (if (i32.eq (local.get $lo) (i32.const 5)) (then (br $end)))
          (local.set $d (call $fetch))
          (if (i32.lt_u (local.get $lo) (i32.const 8)) (then (call $mwr (call $mrd (call $rn (i32.and (local.get $lo) (i32.const 1)))) (call $drd (local.get $d)))) (else (call $mwr (call $rn (i32.and (local.get $lo) (i32.const 7))) (call $drd (local.get $d)))))
          (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 11)) (then   ;; CJNE
          (if (i32.eq (local.get $lo) (i32.const 4)) (then (local.set $u (local.get $a)) (local.set $v (call $fetch)))
            (else (if (i32.eq (local.get $lo) (i32.const 5)) (then (local.set $u (local.get $a)) (local.set $v (call $drd (call $fetch))))
              (else (local.set $u (call $src51 (local.get $lo))) (local.set $v (call $fetch))))))
          (call $setcy (i32.lt_u (local.get $u) (local.get $v)))
          (call $rel51 (i32.ne (local.get $u) (local.get $v)))
          (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 12)) (then   ;; C4 SWAP A, C5.. XCH A,src
          (if (i32.eq (local.get $lo) (i32.const 4)) (then (call $zw (i32.const 0) (i32.or (i32.shr_u (local.get $a) (i32.const 4)) (i32.shl (i32.and (local.get $a) (i32.const 15)) (i32.const 4)))) (br $end)))
          (local.set $v (call $src51 (local.get $lo))) (call $dst51 (local.get $lo) (local.get $a)) (call $zw (i32.const 0) (local.get $v)) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 13)) (then   ;; D4 DA A, D5 DJNZ dir, D6/D7 XCHD, D8.. DJNZ Rn
          (if (i32.eq (local.get $lo) (i32.const 4)) (then
            (local.set $v (local.get $a)) (local.set $t (call $cy51))
            (if (i32.or (i32.gt_u (i32.and (local.get $v) (i32.const 15)) (i32.const 9)) (i32.and (call $zr (i32.const 2)) (i32.const 0x40))) (then (local.set $v (i32.add (local.get $v) (i32.const 6)))))
            (if (i32.or (i32.gt_u (i32.and (local.get $v) (i32.const 0x1F0)) (i32.const 0x90)) (local.get $t)) (then (local.set $v (i32.add (local.get $v) (i32.const 0x60))) (local.set $t (i32.const 1))))
            (call $zw (i32.const 0) (i32.and (local.get $v) (i32.const 255))) (call $setcy (local.get $t)) (br $end)))
          (if (i32.lt_u (local.get $lo) (i32.const 8)) (then
            (if (i32.eq (local.get $lo) (i32.const 5)) (then (local.set $v (call $src51 (i32.const 5))) (local.set $v (i32.and (i32.sub (local.get $v) (i32.const 1)) (i32.const 255))) (call $dst51 (i32.const 5) (local.get $v)) (call $rel51 (local.get $v)) (br $end)))
            (local.set $t (call $mrd (call $rn (i32.and (local.get $lo) (i32.const 1))))) (local.set $v (call $mrd (local.get $t)))   ;; XCHD
            (call $mwr (local.get $t) (i32.or (i32.and (local.get $v) (i32.const 0xF0)) (i32.and (local.get $a) (i32.const 15))))
            (call $zw (i32.const 0) (i32.or (i32.and (local.get $a) (i32.const 0xF0)) (i32.and (local.get $v) (i32.const 15))))
            (br $end)))
          (local.set $v (i32.and (i32.sub (call $src51 (local.get $lo)) (i32.const 1)) (i32.const 255))) (call $dst51 (local.get $lo) (local.get $v)) (call $rel51 (local.get $v)) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 14)) (then (if (i32.eq (local.get $lo) (i32.const 4)) (then (call $zw (i32.const 0) (i32.const 0))) (else (call $zw (i32.const 0) (call $src51 (local.get $lo))))) (br $end)))
        ;; F: F4 CPL A, F5.. MOV dst,A
        (if (i32.eq (local.get $lo) (i32.const 4)) (then (call $zw (i32.const 0) (i32.xor (local.get $a) (i32.const 255))) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 5)) (then (call $dwr (call $fetch) (local.get $a)) (br $end)))
        (if (i32.lt_u (local.get $lo) (i32.const 8)) (then (call $mwr (call $mrd (call $rn (i32.and (local.get $lo) (i32.const 1)))) (local.get $a)) (br $end)))
        (call $mwr (call $rn (i32.and (local.get $lo) (i32.const 7))) (local.get $a)) (br $end)))
      ;; ---- columns 0, 2, 3
      (if (i32.eqz (local.get $lo)) (then
        (if (i32.eq (local.get $hi) (i32.const 1)) (then (local.set $t (call $fetch)) (local.set $v (call $bitrd (local.get $t))) (if (local.get $v) (then (call $bitwr (local.get $t) (i32.const 0)))) (call $rel51 (local.get $v)) (br $end)))   ;; JBC
        (if (i32.eq (local.get $hi) (i32.const 2)) (then (call $rel51 (call $bitrd (call $fetch))) (br $end)))                                   ;; JB
        (if (i32.eq (local.get $hi) (i32.const 3)) (then (call $rel51 (i32.eqz (call $bitrd (call $fetch)))) (br $end)))                        ;; JNB
        (if (i32.eq (local.get $hi) (i32.const 4)) (then (call $rel51 (call $cy51)) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 5)) (then (call $rel51 (i32.eqz (call $cy51))) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 6)) (then (call $rel51 (i32.eqz (local.get $a))) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 7)) (then (call $rel51 (i32.ne (local.get $a) (i32.const 0))) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 8)) (then (call $rel51 (i32.const 1)) (br $end)))                                                 ;; SJMP
        (if (i32.eq (local.get $hi) (i32.const 9)) (then (call $zw (i32.const 4) (i32.const 0)) (call $zw16 (i32.const 4) (i32.or (i32.shl (call $fetch) (i32.const 8)) (call $fetch))) (br $end)))   ;; MOV DPTR,#
        (if (i32.eq (local.get $hi) (i32.const 10)) (then (call $setcy (i32.or (call $cy51) (i32.xor (call $bitrd (call $fetch)) (i32.const 1)))) (br $end)))   ;; ORL C,/bit
        (if (i32.eq (local.get $hi) (i32.const 11)) (then (call $setcy (i32.and (call $cy51) (i32.xor (call $bitrd (call $fetch)) (i32.const 1)))) (br $end)))  ;; ANL C,/bit
        (if (i32.eq (local.get $hi) (i32.const 12)) (then (call $push51 (call $drd (call $fetch))) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 13)) (then (call $dwr (call $fetch) (call $pop51)) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 14)) (then (call $zw (i32.const 0) (call $mrd (call $zr16 (i32.const 4)))) (br $end)))       ;; MOVX A,@DPTR
        (if (i32.eq (local.get $hi) (i32.const 15)) (then (call $mwr (call $zr16 (i32.const 4)) (local.get $a)) (br $end)))                  ;; MOVX @DPTR,A
        (br $end)))   ;; 00 NOP
      (if (i32.eq (local.get $lo) (i32.const 2)) (then
        (if (i32.eqz (local.get $hi)) (then (call $zw16 (i32.const 22) (i32.or (i32.shl (call $fetch) (i32.const 8)) (call $fetch))) (br $end)))   ;; LJMP
        (if (i32.eq (local.get $hi) (i32.const 1)) (then (local.set $t (i32.or (i32.shl (call $fetch) (i32.const 8)) (call $fetch))) (call $push51 (i32.and (call $zr16 (i32.const 22)) (i32.const 255))) (call $push51 (i32.shr_u (call $zr16 (i32.const 22)) (i32.const 8))) (call $zw16 (i32.const 22) (local.get $t)) (br $end)))   ;; LCALL
        (if (i32.or (i32.eq (local.get $hi) (i32.const 2)) (i32.eq (local.get $hi) (i32.const 3))) (then (local.set $t (call $pop51)) (call $zw16 (i32.const 22) (i32.or (i32.shl (local.get $t) (i32.const 8)) (call $pop51))) (br $end)))   ;; RET / RETI
        (if (i32.eq (local.get $hi) (i32.const 4)) (then (local.set $d (call $fetch)) (call $dwr (local.get $d) (i32.or (call $drd (local.get $d)) (local.get $a))) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 5)) (then (local.set $d (call $fetch)) (call $dwr (local.get $d) (i32.and (call $drd (local.get $d)) (local.get $a))) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 6)) (then (local.set $d (call $fetch)) (call $dwr (local.get $d) (i32.xor (call $drd (local.get $d)) (local.get $a))) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 7)) (then (call $setcy (i32.or (call $cy51) (call $bitrd (call $fetch)))) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 8)) (then (call $setcy (i32.and (call $cy51) (call $bitrd (call $fetch)))) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 9)) (then (call $bitwr (call $fetch) (call $cy51)) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 10)) (then (call $setcy (call $bitrd (call $fetch))) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 11)) (then (local.set $t (call $fetch)) (call $bitwr (local.get $t) (i32.xor (call $bitrd (local.get $t)) (i32.const 1))) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 12)) (then (call $bitwr (call $fetch) (i32.const 0)) (br $end)))
        (if (i32.eq (local.get $hi) (i32.const 13)) (then (call $bitwr (call $fetch) (i32.const 1)) (br $end)))
        ;; E2/E3 MOVX A,@Ri ; F2/F3 MOVX @Ri,A  (column 2 and 3 for rows E and F)
        (if (i32.eq (local.get $hi) (i32.const 14)) (then (call $zw (i32.const 0) (call $mrd (call $mrd (call $rn (i32.const 0))))) (br $end)))
        (call $mwr (call $mrd (call $rn (i32.const 0))) (local.get $a)) (br $end)))
      ;; column 3
      (if (i32.eqz (local.get $hi)) (then (call $zw (i32.const 0) (i32.or (i32.shr_u (local.get $a) (i32.const 1)) (i32.shl (local.get $a) (i32.const 7)))) (br $end)))   ;; RR A
      (if (i32.eq (local.get $hi) (i32.const 1)) (then (call $zw (i32.const 0) (i32.or (i32.shr_u (local.get $a) (i32.const 1)) (i32.shl (call $cy51) (i32.const 7)))) (call $setcy (i32.and (local.get $a) (i32.const 1))) (br $end)))   ;; RRC A
      (if (i32.eq (local.get $hi) (i32.const 2)) (then (call $zw (i32.const 0) (i32.and (i32.or (i32.shl (local.get $a) (i32.const 1)) (i32.shr_u (local.get $a) (i32.const 7))) (i32.const 255))) (br $end)))   ;; RL A
      (if (i32.eq (local.get $hi) (i32.const 3)) (then (call $zw (i32.const 0) (i32.and (i32.or (i32.shl (local.get $a) (i32.const 1)) (call $cy51)) (i32.const 255))) (call $setcy (i32.shr_u (local.get $a) (i32.const 7))) (br $end)))   ;; RLC A
      (if (i32.eq (local.get $hi) (i32.const 4)) (then (local.set $d (call $fetch)) (call $dwr (local.get $d) (i32.or (call $drd (local.get $d)) (call $fetch))) (br $end)))   ;; ORL dir,#
      (if (i32.eq (local.get $hi) (i32.const 5)) (then (local.set $d (call $fetch)) (call $dwr (local.get $d) (i32.and (call $drd (local.get $d)) (call $fetch))) (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 6)) (then (local.set $d (call $fetch)) (call $dwr (local.get $d) (i32.xor (call $drd (local.get $d)) (call $fetch))) (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 7)) (then (call $zw16 (i32.const 22) (i32.and (i32.add (call $zr16 (i32.const 4)) (local.get $a)) (i32.const 0xffff))) (br $end)))   ;; JMP @A+DPTR
      (if (i32.eq (local.get $hi) (i32.const 8)) (then (call $zw (i32.const 0) (call $mrd (i32.add (call $zr16 (i32.const 22)) (local.get $a)))) (br $end)))   ;; MOVC A,@A+PC
      (if (i32.eq (local.get $hi) (i32.const 9)) (then (call $zw (i32.const 0) (call $mrd (i32.add (call $zr16 (i32.const 4)) (local.get $a)))) (br $end)))    ;; MOVC A,@A+DPTR
      (if (i32.eq (local.get $hi) (i32.const 10)) (then (call $zw16 (i32.const 4) (i32.and (i32.add (call $zr16 (i32.const 4)) (i32.const 1)) (i32.const 0xffff))) (br $end)))   ;; INC DPTR
      (if (i32.eq (local.get $hi) (i32.const 11)) (then (call $setcy (i32.xor (call $cy51) (i32.const 1))) (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 12)) (then (call $setcy (i32.const 0)) (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 13)) (then (call $setcy (i32.const 1)) (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 14)) (then (call $zw (i32.const 0) (call $mrd (call $mrd (call $rn (i32.const 1))))) (br $end)))
      (call $mwr (call $mrd (call $rn (i32.const 1))) (local.get $a)))
    ;; parity flag
    (call $zw (i32.const 2) (i32.or (i32.and (call $zr (i32.const 2)) (i32.const 0xFE)) (i32.and (i32.popcnt (call $zr (i32.const 0))) (i32.const 1)))))
