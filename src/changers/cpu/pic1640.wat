  ;; General Instrument PIC1640 (kind 30): the original PIC, 12-bit instructions, the baseline set of 33. The 16
  ;; bytes are both memories: the program is read as ten 12-bit words at bit offsets 12k (the last 8 bits are never
  ;; fetched), and the file registers are the bytes, f -> byte f mod 16 (so f = 16..31 reach bytes 0..15 directly),
  ;; with the special files on top of them: f = 0 INDF (indirect through FSR, byte 4), f = 2 PCL (the program
  ;; counter, a word index 0..9; a write is a jump), STATUS is byte 3 (C bit 0, DC bit 1, Z bit 2), FSR byte 4.
  ;; A write to a file is a write to the program. Register file: W at 0, PC at 22, the two-level stack at 24 and
  ;; 26 with its pointer in byte 21. OPTION, TRIS, SLEEP and CLRWDT are NOPs; a pair is handed over as two cells.
  (func $pic_pc (result i32) (call $zr16 (i32.const 22)))
  (func $pic_setpc (param $v i32) (call $zw16 (i32.const 22) (i32.rem_u (local.get $v) (i32.const 10))))
  (func $pic_rd (param $f i32) (result i32)
    (local.set $f (i32.and (local.get $f) (i32.const 31)))
    (if (i32.eqz (local.get $f)) (then (local.set $f (i32.and (call $mrd (i32.const 4)) (i32.const 31))) (if (i32.eqz (local.get $f)) (then (return (i32.const 0))))))
    (if (i32.eq (local.get $f) (i32.const 2)) (then (return (call $pic_pc))))
    (call $mrd (local.get $f)))
  (func $pic_wr (param $f i32) (param $v i32)
    (local.set $f (i32.and (local.get $f) (i32.const 31))) (local.set $v (i32.and (local.get $v) (i32.const 255)))
    (if (i32.eqz (local.get $f)) (then (local.set $f (i32.and (call $mrd (i32.const 4)) (i32.const 31))) (if (i32.eqz (local.get $f)) (then (return)))))
    (if (i32.eq (local.get $f) (i32.const 2)) (then (call $pic_setpc (local.get $v)) (return)))
    (call $mwr (local.get $f) (local.get $v)))
  (func $pic_flag (param $bit i32) (param $on i32)   ;; STATUS is byte 3 of the cell
    (call $mwr (i32.const 3) (i32.or (i32.and (call $mrd (i32.const 3)) (i32.xor (i32.shl (i32.const 1) (local.get $bit)) (i32.const -1))) (i32.shl (i32.ne (local.get $on) (i32.const 0)) (local.get $bit)))))
  (func $pic_z (param $v i32) (result i32) (call $pic_flag (i32.const 2) (i32.eqz (i32.and (local.get $v) (i32.const 255)))) (i32.and (local.get $v) (i32.const 255)))
  (func $pic_dst (param $I i32) (param $v i32)   ;; d bit (5): 0 to W, 1 back to the file
    (if (i32.and (local.get $I) (i32.const 32)) (then (call $pic_wr (local.get $I) (local.get $v))) (else (call $zw (i32.const 0) (local.get $v)))))
  (func $pic_skip (call $pic_setpc (i32.add (call $pic_pc) (i32.const 1))))
  (func $pic1640_step
    (local $I i32) (local $f i32) (local $v i32) (local $w i32) (local $r i32) (local $k i32) (local $sp i32)
    (local.set $I (i32.wrap_i64 (call $fld_rd (i32.mul (call $pic_pc) (i32.const 12)) (i32.const 12))))
    (call $pic_setpc (i32.add (call $pic_pc) (i32.const 1)))
    (local.set $w (call $zr (i32.const 0))) (local.set $f (i32.and (local.get $I) (i32.const 31))) (local.set $k (i32.and (local.get $I) (i32.const 255)))
    (block $end
      (if (i32.ge_u (local.get $I) (i32.const 0x800)) (then   ;; literal and control: RETLW CALL GOTO MOVLW IORLW ANDLW XORLW
        (if (i32.ge_u (local.get $I) (i32.const 0xc00)) (then
          (local.set $r (i32.and (i32.shr_u (local.get $I) (i32.const 8)) (i32.const 3)))
          (if (i32.eqz (local.get $r)) (then (call $zw (i32.const 0) (local.get $k)))
            (else (call $zw (i32.const 0) (call $pic_z (select (i32.or (local.get $w) (local.get $k)) (select (i32.and (local.get $w) (local.get $k)) (i32.xor (local.get $w) (local.get $k)) (i32.eq (local.get $r) (i32.const 2))) (i32.eq (local.get $r) (i32.const 1)))))))
          (br $end)))
        (if (i32.ge_u (local.get $I) (i32.const 0xa00)) (then (call $pic_setpc (i32.and (local.get $I) (i32.const 0x1ff))) (br $end)))   ;; GOTO
        (local.set $sp (i32.and (call $zr (i32.const 21)) (i32.const 1)))
        (if (i32.ge_u (local.get $I) (i32.const 0x900))
          (then (call $zw16 (i32.add (i32.const 24) (i32.shl (local.get $sp) (i32.const 1))) (call $pic_pc)) (call $zw (i32.const 21) (i32.xor (local.get $sp) (i32.const 1))) (call $pic_setpc (local.get $k)))   ;; CALL
          (else (local.set $sp (i32.xor (local.get $sp) (i32.const 1))) (call $zw (i32.const 21) (local.get $sp)) (call $zw (i32.const 0) (local.get $k)) (call $pic_setpc (call $zr16 (i32.add (i32.const 24) (i32.shl (local.get $sp) (i32.const 1)))))))   ;; RETLW
        (br $end)))
      (if (i32.ge_u (local.get $I) (i32.const 0x400)) (then   ;; bit operations: BCF BSF BTFSC BTFSS, bit in 7..5
        (local.set $k (i32.shl (i32.const 1) (i32.and (i32.shr_u (local.get $I) (i32.const 5)) (i32.const 7)))) (local.set $v (call $pic_rd (local.get $f)))
        (local.set $r (i32.and (i32.shr_u (local.get $I) (i32.const 8)) (i32.const 3)))
        (if (i32.eqz (local.get $r)) (then (call $pic_wr (local.get $f) (i32.and (local.get $v) (i32.xor (local.get $k) (i32.const -1)))) (br $end)))
        (if (i32.eq (local.get $r) (i32.const 1)) (then (call $pic_wr (local.get $f) (i32.or (local.get $v) (local.get $k))) (br $end)))
        (if (i32.eq (i32.eqz (i32.and (local.get $v) (local.get $k))) (i32.eq (local.get $r) (i32.const 2))) (then (call $pic_skip)))
        (br $end)))
      (if (i32.lt_u (local.get $I) (i32.const 0x40)) (then   ;; NOP, OPTION, SLEEP, CLRWDT, TRIS (NOPs) and MOVWF
        (if (i32.and (local.get $I) (i32.const 0x20)) (then (call $pic_wr (local.get $f) (local.get $w))))
        (br $end)))
      (if (i32.lt_u (local.get $I) (i32.const 0x80)) (then   ;; CLRW / CLRF
        (if (i32.and (local.get $I) (i32.const 0x20)) (then (call $pic_wr (local.get $f) (i32.const 0))) (else (call $zw (i32.const 0) (i32.const 0))))
        (call $pic_flag (i32.const 2) (i32.const 1)) (br $end)))
      (local.set $v (call $pic_rd (local.get $f))) (local.set $r (i32.shr_u (local.get $I) (i32.const 6)))   ;; 2..15: SUBWF DECF IORWF ANDWF XORWF ADDWF MOVF COMF INCF DECFSZ RRF RLF SWAPF INCFSZ
      (block $b15 (block $b14 (block $b13 (block $b12 (block $b11 (block $b10 (block $b9 (block $b8 (block $b7 (block $b6 (block $b5 (block $b4 (block $b3 (block $b2
        (br_table $b2 $b3 $b4 $b5 $b6 $b7 $b8 $b9 $b10 $b11 $b12 $b13 $b14 $b15 (i32.sub (local.get $r) (i32.const 2))))
        (local.set $r (i32.sub (local.get $v) (local.get $w))) (call $pic_flag (i32.const 0) (i32.ge_u (local.get $v) (local.get $w))) (call $pic_flag (i32.const 1) (i32.ge_u (i32.and (local.get $v) (i32.const 15)) (i32.and (local.get $w) (i32.const 15)))) (call $pic_dst (local.get $I) (call $pic_z (local.get $r))) (br $end))
        (call $pic_dst (local.get $I) (call $pic_z (i32.sub (local.get $v) (i32.const 1)))) (br $end))
        (call $pic_dst (local.get $I) (call $pic_z (i32.or (local.get $v) (local.get $w)))) (br $end))
        (call $pic_dst (local.get $I) (call $pic_z (i32.and (local.get $v) (local.get $w)))) (br $end))
        (call $pic_dst (local.get $I) (call $pic_z (i32.xor (local.get $v) (local.get $w)))) (br $end))
        (local.set $r (i32.add (local.get $v) (local.get $w))) (call $pic_flag (i32.const 0) (i32.gt_u (local.get $r) (i32.const 255))) (call $pic_flag (i32.const 1) (i32.gt_u (i32.add (i32.and (local.get $v) (i32.const 15)) (i32.and (local.get $w) (i32.const 15))) (i32.const 15))) (call $pic_dst (local.get $I) (call $pic_z (local.get $r))) (br $end))
        (call $pic_dst (local.get $I) (call $pic_z (local.get $v))) (br $end))
        (call $pic_dst (local.get $I) (call $pic_z (i32.xor (local.get $v) (i32.const 255)))) (br $end))
        (call $pic_dst (local.get $I) (call $pic_z (i32.add (local.get $v) (i32.const 1)))) (br $end))
        (local.set $r (i32.and (i32.sub (local.get $v) (i32.const 1)) (i32.const 255))) (call $pic_dst (local.get $I) (local.get $r)) (if (i32.eqz (local.get $r)) (then (call $pic_skip))) (br $end))
        (local.set $r (i32.or (i32.shr_u (local.get $v) (i32.const 1)) (i32.shl (i32.and (call $mrd (i32.const 3)) (i32.const 1)) (i32.const 7)))) (call $pic_flag (i32.const 0) (i32.and (local.get $v) (i32.const 1))) (call $pic_dst (local.get $I) (local.get $r)) (br $end))
        (local.set $r (i32.and (i32.or (i32.shl (local.get $v) (i32.const 1)) (i32.and (call $mrd (i32.const 3)) (i32.const 1))) (i32.const 255))) (call $pic_flag (i32.const 0) (i32.and (local.get $v) (i32.const 0x80))) (call $pic_dst (local.get $I) (local.get $r)) (br $end))
        (call $pic_dst (local.get $I) (i32.or (i32.shr_u (local.get $v) (i32.const 4)) (i32.and (i32.shl (local.get $v) (i32.const 4)) (i32.const 0xf0)))) (br $end))
      (local.set $r (i32.and (i32.add (local.get $v) (i32.const 1)) (i32.const 255))) (call $pic_dst (local.get $I) (local.get $r)) (if (i32.eqz (local.get $r)) (then (call $pic_skip)))))
