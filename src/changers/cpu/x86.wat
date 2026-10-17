  ;; Intel 8086 (kind 26), 80286 (kind 27) and 80386 (kind 28): one core, $xm = 0, 1, 2. Register file: EAX ECX
  ;; EDX EBX ESP EBP ESI EDI as little-endian i32 at offset 64 + 4n (so AL is byte 64 + 4n and AH byte 65 + 4n),
  ;; ES CS SS DS FS GS as i16 at 96 + 2n, FLAGS at 20 (CF 1, PF 4, AF 16, ZF 64, SF 128, DF 1024, OF 2048), IP at
  ;; 22. Memory is the pixel: 16 bytes (32 on a pair), little-endian, every access wrapping byte by byte; the
  ;; segment registers are kept and moved but take no part in addressing (there is one tiny flat memory), and the
  ;; stack pointer is 16-bit. Real mode throughout: no descriptors, no privilege.
  ;;   8086: the whole instruction set. IN/OUT, HLT, WAIT, LOCK, INT/INTO and ESC (the 8087) are NOPs that consume
  ;;         their operands; opcodes 60..6F are the Jcc aliases and C0/C1, C8/C9 the RET/RETF aliases as on the chip.
  ;;   80286: adds the 186/286 instructions PUSHA/POPA, PUSH imm, IMUL r,rm,imm, shifts and rotates by an immediate,
  ;;         ENTER/LEAVE, BOUND (no trap), INS/OUTS (NOPs) and the 0F page, whose protected-mode instructions
  ;;         (LGDT family, LAR/LSL, CLTS, ARPL) are NOPs that consume their operands; shift counts are masked to 31.
  ;;   80386: adds 32-bit operands and addresses (the 66/67 prefixes, SIB addressing, FS/GS), CWDE/CDQ, MOVZX/MOVSX,
  ;;         SETcc, Jcc rel16/32, BT/BTS/BTR/BTC, BSF/BSR, SHLD/SHRD, IMUL r,rm, LSS/LFS/LGS, PUSH/POP FS/GS; MOV to
  ;;         and from the control, debug and test registers are NOPs.
  ;; A string instruction with REP runs one iteration per step and repeats itself (IP back to the prefix) while
  ;; CX allows, so a REP MOVSB takes CX steps, as the chip's interruptible loop would.
  (global $xm (mut i32) (i32.const 0))       ;; 0 8086, 1 80286, 2 80386
  (global $x_osz (mut i32) (i32.const 2))    ;; operand size of the current instruction (2 or 4)
  (global $x_asz (mut i32) (i32.const 2))    ;; address size (2 or 4)
  (global $x_rep (mut i32) (i32.const 0))    ;; 0 none, 2 REPNE, 3 REP/REPE
  (global $x_ip0 (mut i32) (i32.const 0))    ;; IP at the start of the instruction, for REP
  (global $x_reg (mut i32) (i32.const 0))    ;; ModRM reg field
  (global $x_mod (mut i32) (i32.const 0))    ;; ModRM mod field
  (global $x_rm (mut i32) (i32.const 0))     ;; the ModRM operand: 0x10000 + n for a register, else an address
  (func $x_mask (param $sz i32) (result i32) (select (i32.const 0xff) (select (i32.const 0xffff) (i32.const -1) (i32.eq (local.get $sz) (i32.const 2))) (i32.eq (local.get $sz) (i32.const 1))))
  (func $x_msb (param $sz i32) (result i32) (select (i32.const 0x80) (select (i32.const 0x8000) (i32.const 0x80000000) (i32.eq (local.get $sz) (i32.const 2))) (i32.eq (local.get $sz) (i32.const 1))))
  (func $x_sx (param $v i32) (param $sz i32) (result i32)
    (select (call $sext8 (local.get $v)) (select (call $sx (local.get $v) (i32.const 16)) (local.get $v) (i32.eq (local.get $sz) (i32.const 2))) (i32.eq (local.get $sz) (i32.const 1))))
  ;; registers: n = 0..7; byte size: 0..3 the low bytes of EAX ECX EDX EBX, 4..7 their high bytes
  (func $xg (param $n i32) (param $sz i32) (result i32)
    (if (i32.eq (local.get $sz) (i32.const 1)) (then
      (return (i32.load8_u offset=320 (i32.add (i32.shl (i32.and (local.get $n) (i32.const 3)) (i32.const 2)) (i32.shr_u (local.get $n) (i32.const 2)))))))
    (i32.and (i32.load offset=320 (i32.shl (local.get $n) (i32.const 2))) (call $x_mask (local.get $sz))))
  (func $xs (param $n i32) (param $sz i32) (param $v i32)
    (if (i32.eq (local.get $sz) (i32.const 1)) (then
      (i32.store8 offset=320 (i32.add (i32.shl (i32.and (local.get $n) (i32.const 3)) (i32.const 2)) (i32.shr_u (local.get $n) (i32.const 2))) (local.get $v)) (return)))
    (if (i32.eq (local.get $sz) (i32.const 2)) (then (i32.store16 offset=320 (i32.shl (local.get $n) (i32.const 2)) (local.get $v)) (return)))
    (i32.store offset=320 (i32.shl (local.get $n) (i32.const 2)) (local.get $v)))
  (func $x_sg (param $n i32) (result i32) (i32.load16_u offset=352 (i32.shl (i32.and (local.get $n) (i32.const 7)) (i32.const 1))))
  (func $x_ss (param $n i32) (param $v i32) (i32.store16 offset=352 (i32.shl (i32.and (local.get $n) (i32.const 7)) (i32.const 1)) (local.get $v)))
  (func $x_ld (param $ea i32) (param $sz i32) (result i32)
    (if (i32.ge_u (local.get $ea) (i32.const 0x10000)) (then (return (call $xg (i32.and (local.get $ea) (i32.const 7)) (local.get $sz)))))
    (if (i32.eq (local.get $sz) (i32.const 1)) (then (return (call $mrd (local.get $ea)))))
    (if (i32.eq (local.get $sz) (i32.const 2)) (then (return (call $mrd16le (local.get $ea)))))
    (call $mrd32 (local.get $ea)))
  (func $x_st (param $ea i32) (param $sz i32) (param $v i32)
    (if (i32.ge_u (local.get $ea) (i32.const 0x10000)) (then (call $xs (i32.and (local.get $ea) (i32.const 7)) (local.get $sz) (local.get $v)) (return)))
    (if (i32.eq (local.get $sz) (i32.const 1)) (then (call $mwr (local.get $ea) (local.get $v)) (return)))
    (if (i32.eq (local.get $sz) (i32.const 2)) (then (call $mwr16le (local.get $ea) (local.get $v)) (return)))
    (call $mwr32 (local.get $ea) (local.get $v)))
  (func $x_f32 (result i32) (local $lo i32) (local.set $lo (call $fetch16)) (i32.or (local.get $lo) (i32.shl (call $fetch16) (i32.const 16))))
  (func $x_imm (param $sz i32) (result i32)
    (if (i32.eq (local.get $sz) (i32.const 1)) (then (return (call $fetch))))
    (if (i32.eq (local.get $sz) (i32.const 2)) (then (return (call $fetch16))))
    (call $x_f32))
  (func $x_fl (result i32) (call $zr16 (i32.const 20)))
  (func $x_setf (param $m i32) (param $on i32)
    (call $zw16 (i32.const 20) (i32.or (i32.and (call $zr16 (i32.const 20)) (i32.xor (local.get $m) (i32.const -1))) (select (local.get $m) (i32.const 0) (local.get $on)))))
  (func $x_cf (result i32) (i32.and (call $zr16 (i32.const 20)) (i32.const 1)))
  (func $x_szp (param $r i32) (param $sz i32)   ;; SF ZF PF from a result
    (local.set $r (i32.and (local.get $r) (call $x_mask (local.get $sz))))
    (call $x_setf (i32.const 0x80) (i32.and (local.get $r) (call $x_msb (local.get $sz))))
    (call $x_setf (i32.const 0x40) (i32.eqz (local.get $r)))
    (call $x_setf (i32.const 0x04) (i32.eqz (i32.and (i32.popcnt (i32.and (local.get $r) (i32.const 0xff))) (i32.const 1)))))
  (func $x_add (param $a i32) (param $b i32) (param $sz i32) (param $cin i32) (result i32)
    (local $r i32) (local $m i32)
    (local.set $m (call $x_mask (local.get $sz))) (local.set $a (i32.and (local.get $a) (local.get $m))) (local.set $b (i32.and (local.get $b) (local.get $m)))
    (local.set $r (i32.and (i32.add (i32.add (local.get $a) (local.get $b)) (local.get $cin)) (local.get $m)))
    (call $x_setf (i32.const 1) (i64.gt_u (i64.add (i64.add (i64.extend_i32_u (local.get $a)) (i64.extend_i32_u (local.get $b))) (i64.extend_i32_u (local.get $cin))) (i64.extend_i32_u (local.get $m))))
    (call $x_setf (i32.const 0x800) (i32.and (i32.and (i32.xor (local.get $a) (local.get $r)) (i32.xor (local.get $b) (local.get $r))) (call $x_msb (local.get $sz))))
    (call $x_setf (i32.const 0x10) (i32.and (i32.xor (i32.xor (local.get $a) (local.get $b)) (local.get $r)) (i32.const 0x10)))
    (call $x_szp (local.get $r) (local.get $sz))
    (local.get $r))
  (func $x_sub (param $a i32) (param $b i32) (param $sz i32) (param $bin i32) (result i32)
    (local $r i32) (local $m i32)
    (local.set $m (call $x_mask (local.get $sz))) (local.set $a (i32.and (local.get $a) (local.get $m))) (local.set $b (i32.and (local.get $b) (local.get $m)))
    (local.set $r (i32.and (i32.sub (i32.sub (local.get $a) (local.get $b)) (local.get $bin)) (local.get $m)))
    (call $x_setf (i32.const 1) (i64.lt_u (i64.extend_i32_u (local.get $a)) (i64.add (i64.extend_i32_u (local.get $b)) (i64.extend_i32_u (local.get $bin)))))
    (call $x_setf (i32.const 0x800) (i32.and (i32.and (i32.xor (local.get $a) (local.get $b)) (i32.xor (local.get $a) (local.get $r))) (call $x_msb (local.get $sz))))
    (call $x_setf (i32.const 0x10) (i32.and (i32.xor (i32.xor (local.get $a) (local.get $b)) (local.get $r)) (i32.const 0x10)))
    (call $x_szp (local.get $r) (local.get $sz))
    (local.get $r))
  (func $x_logic (param $r i32) (param $sz i32) (result i32)
    (call $x_setf (i32.const 0x811) (i32.const 0)) (call $x_szp (local.get $r) (local.get $sz)) (i32.and (local.get $r) (call $x_mask (local.get $sz))))
  ;; the eight ALU operations of the 00..3F block and groups 1: ADD OR ADC SBB AND SUB XOR CMP
  (func $x_alu (param $op i32) (param $a i32) (param $b i32) (param $sz i32) (result i32)
    (block $b7 (block $b6 (block $b5 (block $b4 (block $b3 (block $b2 (block $b1 (block $b0
      (br_table $b0 $b1 $b2 $b3 $b4 $b5 $b6 $b7 (i32.and (local.get $op) (i32.const 7))))
      (return (call $x_add (local.get $a) (local.get $b) (local.get $sz) (i32.const 0))))
      (return (call $x_logic (i32.or (local.get $a) (local.get $b)) (local.get $sz))))
      (return (call $x_add (local.get $a) (local.get $b) (local.get $sz) (call $x_cf))))
      (return (call $x_sub (local.get $a) (local.get $b) (local.get $sz) (call $x_cf))))
      (return (call $x_logic (i32.and (local.get $a) (local.get $b)) (local.get $sz))))
      (return (call $x_sub (local.get $a) (local.get $b) (local.get $sz) (i32.const 0))))
      (return (call $x_logic (i32.xor (local.get $a) (local.get $b)) (local.get $sz))))
    (drop (call $x_sub (local.get $a) (local.get $b) (local.get $sz) (i32.const 0)))
    (local.get $a))   ;; CMP: the destination is unchanged
  (func $x_push (param $v i32)
    (local $sp i32)
    (local.set $sp (i32.and (i32.sub (call $xg (i32.const 4) (i32.const 2)) (global.get $x_osz)) (i32.const 0xffff)))
    (call $xs (i32.const 4) (i32.const 2) (local.get $sp)) (call $x_st (local.get $sp) (global.get $x_osz) (local.get $v)))
  (func $x_pop (result i32)
    (local $sp i32) (local $v i32)
    (local.set $sp (call $xg (i32.const 4) (i32.const 2))) (local.set $v (call $x_ld (local.get $sp) (global.get $x_osz)))
    (call $xs (i32.const 4) (i32.const 2) (i32.and (i32.add (local.get $sp) (global.get $x_osz)) (i32.const 0xffff)))
    (local.get $v))
  ;; ModRM (and SIB, displacements): sets $x_mod, $x_reg, $x_rm
  (func $x_modrm
    (local $m i32) (local $rm i32) (local $a i32) (local $sib i32) (local $base i32)
    (local.set $m (call $fetch)) (global.set $x_mod (i32.shr_u (local.get $m) (i32.const 6))) (global.set $x_reg (i32.and (i32.shr_u (local.get $m) (i32.const 3)) (i32.const 7)))
    (local.set $rm (i32.and (local.get $m) (i32.const 7)))
    (if (i32.eq (global.get $x_mod) (i32.const 3)) (then (global.set $x_rm (i32.add (i32.const 0x10000) (local.get $rm))) (return)))
    (if (i32.eq (global.get $x_asz) (i32.const 4))
      (then   ;; 32-bit addressing
        (if (i32.eq (local.get $rm) (i32.const 4))
          (then (local.set $sib (call $fetch)) (local.set $base (i32.and (local.get $sib) (i32.const 7)))
            (if (i32.ne (i32.and (i32.shr_u (local.get $sib) (i32.const 3)) (i32.const 7)) (i32.const 4)) (then
              (local.set $a (i32.shl (call $xg (i32.and (i32.shr_u (local.get $sib) (i32.const 3)) (i32.const 7)) (i32.const 4)) (i32.shr_u (local.get $sib) (i32.const 6))))))
            (if (i32.and (i32.eq (local.get $base) (i32.const 5)) (i32.eqz (global.get $x_mod)))
              (then (local.set $a (i32.add (local.get $a) (call $x_f32))))
              (else (local.set $a (i32.add (local.get $a) (call $xg (local.get $base) (i32.const 4)))))))
          (else (if (i32.and (i32.eq (local.get $rm) (i32.const 5)) (i32.eqz (global.get $x_mod)))
            (then (local.set $a (call $x_f32)))
            (else (local.set $a (call $xg (local.get $rm) (i32.const 4)))))))
        (if (i32.eq (global.get $x_mod) (i32.const 1)) (then (local.set $a (i32.add (local.get $a) (call $sext8 (call $fetch))))))
        (if (i32.eq (global.get $x_mod) (i32.const 2)) (then (local.set $a (i32.add (local.get $a) (call $x_f32))))))
      (else   ;; 16-bit addressing: BX+SI BX+DI BP+SI BP+DI SI DI BP/disp16 BX
        (if (i32.lt_u (local.get $rm) (i32.const 4))
          (then (local.set $a (i32.add (call $xg (select (i32.const 3) (i32.const 5) (i32.lt_u (local.get $rm) (i32.const 2))) (i32.const 2))
                                       (call $xg (select (i32.const 6) (i32.const 7) (i32.eqz (i32.and (local.get $rm) (i32.const 1)))) (i32.const 2)))))
          (else
            (if (i32.eq (local.get $rm) (i32.const 4)) (then (local.set $a (call $xg (i32.const 6) (i32.const 2)))))
            (if (i32.eq (local.get $rm) (i32.const 5)) (then (local.set $a (call $xg (i32.const 7) (i32.const 2)))))
            (if (i32.eq (local.get $rm) (i32.const 7)) (then (local.set $a (call $xg (i32.const 3) (i32.const 2)))))
            (if (i32.eq (local.get $rm) (i32.const 6)) (then
              (if (i32.eqz (global.get $x_mod)) (then (local.set $a (call $fetch16))) (else (local.set $a (call $xg (i32.const 5) (i32.const 2)))))))))
        (if (i32.eq (global.get $x_mod) (i32.const 1)) (then (local.set $a (i32.add (local.get $a) (call $sext8 (call $fetch))))))
        (if (i32.eq (global.get $x_mod) (i32.const 2)) (then (local.set $a (i32.add (local.get $a) (call $fetch16)))))))
    (global.set $x_rm (i32.and (local.get $a) (i32.const 0xffff))))
  ;; conditions 0..15: O NO B AE E NE BE A S NS P NP L GE LE G
  (func $x_cc (param $k i32) (result i32)
    (local $f i32) (local $r i32) (local $sf i32) (local $of i32)
    (local.set $f (call $x_fl)) (local.set $sf (i32.and (i32.shr_u (local.get $f) (i32.const 7)) (i32.const 1))) (local.set $of (i32.and (i32.shr_u (local.get $f) (i32.const 11)) (i32.const 1)))
    (block $b7 (block $b6 (block $b5 (block $b4 (block $b3 (block $b2 (block $b1 (block $b0
      (br_table $b0 $b1 $b2 $b3 $b4 $b5 $b6 $b7 (i32.shr_u (i32.and (local.get $k) (i32.const 15)) (i32.const 1))))
      (local.set $r (local.get $of)) (br $b7))
      (local.set $r (i32.and (local.get $f) (i32.const 1))) (br $b7))
      (local.set $r (i32.and (i32.shr_u (local.get $f) (i32.const 6)) (i32.const 1))) (br $b7))
      (local.set $r (i32.ne (i32.and (local.get $f) (i32.const 0x41)) (i32.const 0))) (br $b7))
      (local.set $r (local.get $sf)) (br $b7))
      (local.set $r (i32.and (i32.shr_u (local.get $f) (i32.const 2)) (i32.const 1))) (br $b7))
      (local.set $r (i32.xor (local.get $sf) (local.get $of))) (br $b7))
      (local.set $r (i32.or (i32.and (i32.shr_u (local.get $f) (i32.const 6)) (i32.const 1)) (i32.xor (local.get $sf) (local.get $of))))
    (i32.xor (local.get $r) (i32.and (local.get $k) (i32.const 1))))
  ;; shifts and rotates: ROL ROR RCL RCR SHL SHR SAL SAR; count masked to 31 (0 leaves the flags alone)
  (func $x_shift (param $op i32) (param $v i32) (param $cnt i32) (param $sz i32) (result i32)
    (local $m i32) (local $msb i32) (local $c i32) (local $bits i32) (local $r i32) (local $k i32) (local $sign i32)
    (local.set $m (call $x_mask (local.get $sz))) (local.set $msb (call $x_msb (local.get $sz))) (local.set $bits (i32.shl (local.get $sz) (i32.const 3)))
    (local.set $r (i32.and (local.get $v) (local.get $m))) (local.set $cnt (i32.and (local.get $cnt) (i32.const 31)))
    (if (i32.eqz (local.get $cnt)) (then (return (local.get $r))))
    (local.set $c (call $x_cf)) (local.set $sign (i32.ne (i32.and (local.get $r) (local.get $msb)) (i32.const 0)))
    (block $e (loop $l (br_if $e (i32.ge_u (local.get $k) (local.get $cnt)))
      (block $d (block $s7 (block $s6 (block $s5 (block $s4 (block $s3 (block $s2 (block $s1 (block $s0
        (br_table $s0 $s1 $s2 $s3 $s4 $s5 $s6 $s7 (i32.and (local.get $op) (i32.const 7))))
        (local.set $c (i32.ne (i32.and (local.get $r) (local.get $msb)) (i32.const 0))) (local.set $r (i32.and (i32.or (i32.shl (local.get $r) (i32.const 1)) (local.get $c)) (local.get $m))) (br $d))
        (local.set $c (i32.and (local.get $r) (i32.const 1))) (local.set $r (i32.or (i32.shr_u (local.get $r) (i32.const 1)) (i32.shl (local.get $c) (i32.sub (local.get $bits) (i32.const 1))))) (br $d))
        (local.set $r (i32.or (i32.shl (local.get $r) (i32.const 1)) (local.get $c))) (local.set $c (i32.ne (i32.and (local.get $r) (i32.shl (local.get $msb) (i32.const 1))) (i32.const 0))) (if (i32.eq (local.get $sz) (i32.const 4)) (then (local.set $c (i32.ne (i32.and (local.get $v) (i32.const 0x80000000)) (i32.const 0))) (local.set $v (i32.shl (local.get $v) (i32.const 1))))) (local.set $r (i32.and (local.get $r) (local.get $m))) (br $d))
        (local.set $r (i32.or (i32.shr_u (local.get $r) (i32.const 1)) (i32.shl (local.get $c) (i32.sub (local.get $bits) (i32.const 1))))) (local.set $c (i32.and (local.get $v) (i32.const 1))) (local.set $v (i32.or (i32.shr_u (local.get $r) (i32.const 0)) (i32.const 0))) (br $d))
        (local.set $c (i32.ne (i32.and (local.get $r) (local.get $msb)) (i32.const 0))) (local.set $r (i32.and (i32.shl (local.get $r) (i32.const 1)) (local.get $m))) (br $d))
        (local.set $c (i32.and (local.get $r) (i32.const 1))) (local.set $r (i32.shr_u (local.get $r) (i32.const 1))) (br $d))
        (local.set $c (i32.ne (i32.and (local.get $r) (local.get $msb)) (i32.const 0))) (local.set $r (i32.and (i32.shl (local.get $r) (i32.const 1)) (local.get $m))) (br $d))
        (local.set $c (i32.and (local.get $r) (i32.const 1))) (local.set $r (i32.or (i32.shr_u (local.get $r) (i32.const 1)) (i32.and (local.get $r) (local.get $msb)))))
      (local.set $k (i32.add (local.get $k) (i32.const 1))) (br $l)))
    (call $x_setf (i32.const 1) (local.get $c))
    (if (i32.ge_u (i32.and (local.get $op) (i32.const 7)) (i32.const 4)) (then (call $x_szp (local.get $r) (local.get $sz))))
    (call $x_setf (i32.const 0x800) (i32.xor (i32.ne (i32.and (local.get $r) (local.get $msb)) (i32.const 0)) (select (local.get $c) (local.get $sign) (i32.or (i32.eq (i32.and (local.get $op) (i32.const 7)) (i32.const 5)) (i32.eq (i32.and (local.get $op) (i32.const 7)) (i32.const 1))))))   ;; OF after a count of 1
    (local.get $r))
  ;; group 3 (F6/F7): TEST imm, (TEST), NOT, NEG, MUL, IMUL, DIV, IDIV on the ModRM operand
  (func $x_grp3 (param $sz i32)
    (local $v i32) (local $a i32) (local $q i64) (local $d i64) (local $r i64) (local $hi i32)
    (local.set $v (call $x_ld (global.get $x_rm) (local.get $sz)))
    (block $b7 (block $b6 (block $b5 (block $b4 (block $b3 (block $b2 (block $b1 (block $b0
      (br_table $b0 $b0 $b2 $b3 $b4 $b5 $b6 $b7 (global.get $x_reg)))
      (drop (call $x_logic (i32.and (local.get $v) (call $x_imm (local.get $sz))) (local.get $sz))) (return))
      (unreachable))
      (call $x_st (global.get $x_rm) (local.get $sz) (i32.xor (local.get $v) (i32.const -1))) (return))
      (call $x_st (global.get $x_rm) (local.get $sz) (call $x_sub (i32.const 0) (local.get $v) (local.get $sz) (i32.const 0))) (call $x_setf (i32.const 1) (i32.ne (i32.and (local.get $v) (call $x_mask (local.get $sz))) (i32.const 0))) (return))
      ;; MUL: AX = AL * v / DX:AX = AX * v / EDX:EAX = EAX * v; CF = OF = high half non-zero
      (local.set $q (i64.mul (i64.extend_i32_u (call $xg (i32.const 0) (local.get $sz))) (i64.extend_i32_u (local.get $v))))
      (call $x_mulout (local.get $q) (local.get $sz)) (call $x_setf (i32.const 0x801) (i64.ne (i64.shr_u (local.get $q) (i64.extend_i32_u (i32.shl (local.get $sz) (i32.const 3)))) (i64.const 0))) (return))
      (local.set $q (i64.mul (i64.extend_i32_s (call $x_sx (call $xg (i32.const 0) (local.get $sz)) (local.get $sz))) (i64.extend_i32_s (call $x_sx (local.get $v) (local.get $sz)))))
      (call $x_mulout (local.get $q) (local.get $sz)) (call $x_setf (i32.const 0x801) (i64.ne (local.get $q) (i64.extend_i32_s (call $x_sx (i32.wrap_i64 (local.get $q)) (local.get $sz))))) (return))
      ;; DIV / IDIV: dividend AX, DX:AX or EDX:EAX; divide by zero and an overflowing quotient leave everything alone
      (if (i32.eqz (local.get $v)) (then (return)))
      (local.set $d (call $x_divin (local.get $sz)))
      (local.set $q (i64.div_u (local.get $d) (i64.extend_i32_u (local.get $v)))) (local.set $r (i64.rem_u (local.get $d) (i64.extend_i32_u (local.get $v))))
      (if (i64.gt_u (local.get $q) (i64.extend_i32_u (call $x_mask (local.get $sz)))) (then (return)))
      (call $x_divout (local.get $q) (local.get $r) (local.get $sz)) (return))
    (if (i32.eqz (local.get $v)) (then (return)))
    (local.set $d (call $x_divin (local.get $sz)))
    (if (i32.eq (local.get $sz) (i32.const 1)) (then (local.set $d (i64.extend_i32_s (call $sx (i32.wrap_i64 (local.get $d)) (i32.const 16))))))
    (if (i32.eq (local.get $sz) (i32.const 2)) (then (local.set $d (i64.extend_i32_s (i32.wrap_i64 (local.get $d))))))
    (local.set $a (call $x_sx (local.get $v) (local.get $sz)))
    (if (i32.and (i64.eq (local.get $d) (i64.const 0x8000000000000000)) (i32.eq (local.get $a) (i32.const -1))) (then (return)))
    (local.set $q (i64.div_s (local.get $d) (i64.extend_i32_s (local.get $a)))) (local.set $r (i64.rem_s (local.get $d) (i64.extend_i32_s (local.get $a))))
    (if (i64.ne (local.get $q) (i64.extend_i32_s (call $x_sx (i32.wrap_i64 (local.get $q)) (local.get $sz)))) (then (return)))
    (call $x_divout (local.get $q) (local.get $r) (local.get $sz)))
  (func $x_mulout (param $q i64) (param $sz i32)
    (if (i32.eq (local.get $sz) (i32.const 1)) (then (call $xs (i32.const 0) (i32.const 2) (i32.wrap_i64 (local.get $q))) (return)))
    (call $xs (i32.const 0) (local.get $sz) (i32.wrap_i64 (local.get $q)))
    (call $xs (i32.const 2) (local.get $sz) (i32.wrap_i64 (i64.shr_u (local.get $q) (i64.extend_i32_u (i32.shl (local.get $sz) (i32.const 3)))))))
  (func $x_divin (param $sz i32) (result i64)
    (if (i32.eq (local.get $sz) (i32.const 1)) (then (return (i64.extend_i32_u (call $xg (i32.const 0) (i32.const 2))))))
    (i64.or (i64.extend_i32_u (call $xg (i32.const 0) (local.get $sz))) (i64.shl (i64.extend_i32_u (call $xg (i32.const 2) (local.get $sz))) (i64.extend_i32_u (i32.shl (local.get $sz) (i32.const 3))))))
  (func $x_divout (param $q i64) (param $r i64) (param $sz i32)
    (if (i32.eq (local.get $sz) (i32.const 1)) (then
      (call $xs (i32.const 0) (i32.const 1) (i32.wrap_i64 (local.get $q))) (call $xs (i32.const 4) (i32.const 1) (i32.wrap_i64 (local.get $r))) (return)))
    (call $xs (i32.const 0) (local.get $sz) (i32.wrap_i64 (local.get $q))) (call $xs (i32.const 2) (local.get $sz) (i32.wrap_i64 (local.get $r))))
  ;; one iteration of a string instruction (A4..AF without A8/A9); with REP it repeats itself next step while CX allows
  (func $x_string (param $op i32)
    (local $sz i32) (local $d i32) (local $si i32) (local $di i32) (local $cx i32) (local $z i32) (local $kind i32)
    (local.set $sz (select (global.get $x_osz) (i32.const 1) (i32.and (local.get $op) (i32.const 1))))
    (local.set $d (select (i32.sub (i32.const 0) (local.get $sz)) (local.get $sz) (i32.and (call $x_fl) (i32.const 0x400))))
    (local.set $kind (i32.and (i32.shr_u (local.get $op) (i32.const 1)) (i32.const 7)))   ;; 2 MOVS 3 CMPS 5 STOS 6 LODS 7 SCAS
    (if (global.get $x_rep) (then (if (i32.eqz (call $xg (i32.const 1) (global.get $x_asz))) (then (return)))))
    (local.set $si (call $xg (i32.const 6) (global.get $x_asz))) (local.set $di (call $xg (i32.const 7) (global.get $x_asz)))
    (if (i32.eq (local.get $kind) (i32.const 2)) (then (call $x_st (i32.and (local.get $di) (i32.const 0xffff)) (local.get $sz) (call $x_ld (i32.and (local.get $si) (i32.const 0xffff)) (local.get $sz)))))
    (if (i32.eq (local.get $kind) (i32.const 3)) (then (drop (call $x_sub (call $x_ld (i32.and (local.get $si) (i32.const 0xffff)) (local.get $sz)) (call $x_ld (i32.and (local.get $di) (i32.const 0xffff)) (local.get $sz)) (local.get $sz) (i32.const 0)))))
    (if (i32.eq (local.get $kind) (i32.const 5)) (then (call $x_st (i32.and (local.get $di) (i32.const 0xffff)) (local.get $sz) (call $xg (i32.const 0) (local.get $sz)))))
    (if (i32.eq (local.get $kind) (i32.const 6)) (then (call $xs (i32.const 0) (local.get $sz) (call $x_ld (i32.and (local.get $si) (i32.const 0xffff)) (local.get $sz)))))
    (if (i32.eq (local.get $kind) (i32.const 7)) (then (drop (call $x_sub (call $xg (i32.const 0) (local.get $sz)) (call $x_ld (i32.and (local.get $di) (i32.const 0xffff)) (local.get $sz)) (local.get $sz) (i32.const 0)))))
    (if (i32.or (i32.eq (local.get $kind) (i32.const 2)) (i32.or (i32.eq (local.get $kind) (i32.const 3)) (i32.eq (local.get $kind) (i32.const 6)))) (then (call $xs (i32.const 6) (global.get $x_asz) (i32.add (local.get $si) (local.get $d)))))
    (if (i32.ne (local.get $kind) (i32.const 6)) (then (call $xs (i32.const 7) (global.get $x_asz) (i32.add (local.get $di) (local.get $d)))))
    (if (i32.eqz (global.get $x_rep)) (then (return)))
    (local.set $cx (i32.sub (call $xg (i32.const 1) (global.get $x_asz)) (i32.const 1))) (call $xs (i32.const 1) (global.get $x_asz) (local.get $cx))
    (if (i32.eqz (i32.and (local.get $cx) (call $x_mask (global.get $x_asz)))) (then (return)))
    (if (i32.or (i32.eq (local.get $kind) (i32.const 3)) (i32.eq (local.get $kind) (i32.const 7))) (then   ;; REPE / REPNE stop on the flag
      (local.set $z (i32.ne (i32.and (call $x_fl) (i32.const 0x40)) (i32.const 0)))
      (if (i32.ne (local.get $z) (i32.eq (global.get $x_rep) (i32.const 3))) (then (return)))))
    (call $zw16 (i32.const 22) (global.get $x_ip0)))
  ;; bit test group: BT BTS BTR BTC (op 4..7) with the bit offset; a register bit offset addresses memory beyond the operand
  (func $x_bt (param $op i32) (param $off i32) (param $sz i32) (param $fromreg i32)
    (local $ea i32) (local $v i32) (local $bit i32) (local $m i32)
    (local.set $ea (global.get $x_rm))
    (if (i32.and (local.get $fromreg) (i32.lt_u (local.get $ea) (i32.const 0x10000))) (then
      (local.set $ea (i32.and (i32.add (local.get $ea) (i32.mul (i32.shr_s (local.get $off) (select (i32.const 4) (i32.const 5) (i32.eq (local.get $sz) (i32.const 2)))) (local.get $sz))) (i32.const 0xffff)))))
    (local.set $bit (i32.and (local.get $off) (i32.sub (i32.shl (local.get $sz) (i32.const 3)) (i32.const 1)))) (local.set $m (i32.shl (i32.const 1) (local.get $bit)))
    (local.set $v (call $x_ld (local.get $ea) (local.get $sz)))
    (call $x_setf (i32.const 1) (i32.and (local.get $v) (local.get $m)))
    (if (i32.eq (local.get $op) (i32.const 5)) (then (call $x_st (local.get $ea) (local.get $sz) (i32.or (local.get $v) (local.get $m)))))
    (if (i32.eq (local.get $op) (i32.const 6)) (then (call $x_st (local.get $ea) (local.get $sz) (i32.and (local.get $v) (i32.xor (local.get $m) (i32.const -1))))))
    (if (i32.eq (local.get $op) (i32.const 7)) (then (call $x_st (local.get $ea) (local.get $sz) (i32.xor (local.get $v) (local.get $m))))))
  ;; the 0F page (80286 and 80386)
  (func $x_0f
    (local $op i32) (local $sz i32) (local $v i32) (local $cnt i32) (local $r i32) (local $t i32)
    (local.set $op (call $fetch)) (local.set $sz (global.get $x_osz))
    (if (i32.lt_u (local.get $op) (i32.const 4)) (then (call $x_modrm) (return)))   ;; LGDT/LIDT/SGDT/..., LLDT/LTR/VERR, LAR, LSL
    (if (i32.lt_u (global.get $xm) (i32.const 2)) (then (return)))   ;; the rest is 80386
    (if (i32.eq (i32.and (local.get $op) (i32.const 0xfc)) (i32.const 0x20)) (then (call $x_modrm) (return)))   ;; MOV CRn/DRn
    (if (i32.eq (i32.and (local.get $op) (i32.const 0xf0)) (i32.const 0x80)) (then   ;; Jcc rel16/32
      (local.set $v (call $x_imm (local.get $sz))) (if (i32.eq (local.get $sz) (i32.const 2)) (then (local.set $v (call $sx (local.get $v) (i32.const 16)))))
      (if (call $x_cc (local.get $op)) (then (call $zw16 (i32.const 22) (i32.and (i32.add (call $zr16 (i32.const 22)) (local.get $v)) (i32.const 0xffff)))))
      (return)))
    (if (i32.eq (i32.and (local.get $op) (i32.const 0xf0)) (i32.const 0x90)) (then (call $x_modrm) (call $x_st (global.get $x_rm) (i32.const 1) (call $x_cc (local.get $op))) (return)))   ;; SETcc
    (if (i32.eq (local.get $op) (i32.const 0xa0)) (then (call $x_push (call $x_sg (i32.const 4))) (return)))
    (if (i32.eq (local.get $op) (i32.const 0xa1)) (then (call $x_ss (i32.const 4) (call $x_pop)) (return)))
    (if (i32.eq (local.get $op) (i32.const 0xa8)) (then (call $x_push (call $x_sg (i32.const 5))) (return)))
    (if (i32.eq (local.get $op) (i32.const 0xa9)) (then (call $x_ss (i32.const 5) (call $x_pop)) (return)))
    (if (i32.eq (i32.and (local.get $op) (i32.const 0xc7)) (i32.const 0x83)) (then   ;; A3 BT, AB BTS, B3 BTR, BB BTC rm,r
      (call $x_modrm) (call $x_bt (i32.add (i32.const 4) (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 3))) (call $xg (global.get $x_reg) (local.get $sz)) (local.get $sz) (i32.const 1)) (return)))
    (if (i32.eq (local.get $op) (i32.const 0xba)) (then (call $x_modrm) (local.set $v (call $fetch)) (if (i32.ge_u (global.get $x_reg) (i32.const 4)) (then (call $x_bt (global.get $x_reg) (local.get $v) (local.get $sz) (i32.const 0)))) (return)))
    (if (i32.eq (i32.and (local.get $op) (i32.const 0xf6)) (i32.const 0xa4)) (then   ;; A4/A5 SHLD, AC/AD SHRD rm,r,imm8/CL
      (call $x_modrm) (local.set $cnt (i32.and (select (call $xg (i32.const 1) (i32.const 1)) (call $fetch) (i32.and (local.get $op) (i32.const 1))) (i32.const 31)))
      (if (i32.eqz (local.get $cnt)) (then (return)))
      (local.set $v (call $x_ld (global.get $x_rm) (local.get $sz))) (local.set $t (call $xg (global.get $x_reg) (local.get $sz)))
      (if (i32.and (local.get $op) (i32.const 8))
        (then (local.set $r (i32.wrap_i64 (i64.shr_u (i64.or (i64.extend_i32_u (local.get $v)) (i64.shl (i64.extend_i32_u (local.get $t)) (i64.extend_i32_u (i32.shl (local.get $sz) (i32.const 3))))) (i64.extend_i32_u (local.get $cnt)))))
          (call $x_setf (i32.const 1) (i32.and (i32.shr_u (local.get $v) (i32.sub (local.get $cnt) (i32.const 1))) (i32.const 1))))
        (else (local.set $r (i32.wrap_i64 (i64.shr_u (i64.shl (i64.or (i64.shl (i64.extend_i32_u (local.get $v)) (i64.extend_i32_u (i32.shl (local.get $sz) (i32.const 3)))) (i64.extend_i32_u (local.get $t))) (i64.extend_i32_u (local.get $cnt))) (i64.extend_i32_u (i32.shl (local.get $sz) (i32.const 3))))))
          (call $x_setf (i32.const 1) (i32.and (i32.shr_u (local.get $v) (i32.sub (i32.shl (local.get $sz) (i32.const 3)) (local.get $cnt))) (i32.const 1)))))
      (call $x_szp (local.get $r) (local.get $sz)) (call $x_st (global.get $x_rm) (local.get $sz) (local.get $r)) (return)))
    (if (i32.eq (local.get $op) (i32.const 0xaf)) (then   ;; IMUL r,rm
      (call $x_modrm) (local.set $r (i32.mul (call $xg (global.get $x_reg) (local.get $sz)) (call $x_ld (global.get $x_rm) (local.get $sz))))
      (call $x_setf (i32.const 0x801) (i32.ne (call $x_sx (local.get $r) (local.get $sz)) (i32.mul (call $x_sx (call $xg (global.get $x_reg) (local.get $sz)) (local.get $sz)) (call $x_sx (call $x_ld (global.get $x_rm) (local.get $sz)) (local.get $sz)))))
      (call $xs (global.get $x_reg) (local.get $sz) (local.get $r)) (return)))
    (if (i32.or (i32.eq (local.get $op) (i32.const 0xb2)) (i32.or (i32.eq (local.get $op) (i32.const 0xb4)) (i32.eq (local.get $op) (i32.const 0xb5)))) (then   ;; LSS LFS LGS
      (call $x_modrm) (if (i32.lt_u (global.get $x_rm) (i32.const 0x10000)) (then
        (call $xs (global.get $x_reg) (local.get $sz) (call $x_ld (global.get $x_rm) (local.get $sz)))
        (call $x_ss (select (i32.const 2) (select (i32.const 4) (i32.const 5) (i32.eq (local.get $op) (i32.const 0xb4))) (i32.eq (local.get $op) (i32.const 0xb2))) (call $x_ld (i32.and (i32.add (global.get $x_rm) (local.get $sz)) (i32.const 0xffff)) (i32.const 2)))))
      (return)))
    (if (i32.eq (i32.and (local.get $op) (i32.const 0xf6)) (i32.const 0xb6)) (then   ;; B6/B7 MOVZX, BE/BF MOVSX
      (call $x_modrm) (local.set $v (call $x_ld (global.get $x_rm) (select (i32.const 2) (i32.const 1) (i32.and (local.get $op) (i32.const 1)))))
      (if (i32.and (local.get $op) (i32.const 8)) (then (local.set $v (call $x_sx (local.get $v) (select (i32.const 2) (i32.const 1) (i32.and (local.get $op) (i32.const 1)))))))
      (call $xs (global.get $x_reg) (local.get $sz) (local.get $v)) (return)))
    (if (i32.or (i32.eq (local.get $op) (i32.const 0xbc)) (i32.eq (local.get $op) (i32.const 0xbd))) (then   ;; BSF / BSR
      (call $x_modrm) (local.set $v (i32.and (call $x_ld (global.get $x_rm) (local.get $sz)) (call $x_mask (local.get $sz))))
      (call $x_setf (i32.const 0x40) (i32.eqz (local.get $v)))
      (if (local.get $v) (then (call $xs (global.get $x_reg) (local.get $sz) (select (i32.ctz (local.get $v)) (i32.sub (i32.const 31) (i32.clz (local.get $v))) (i32.eq (local.get $op) (i32.const 0xbc))))))
      (return))))
  ;; ---- one instruction ----
  (func $x86_step
    (local $op i32) (local $sz i32) (local $d i32) (local $s i32) (local $r i32) (local $n i32) (local $k i32) (local $t i32) (local $w i32)
    (global.set $x_osz (i32.const 2)) (global.set $x_asz (i32.const 2)) (global.set $x_rep (i32.const 0)) (global.set $x_ip0 (call $zr16 (i32.const 22)))
    ;; prefixes (at most 15)
    (block $pe (loop $pl (br_if $pe (i32.ge_u (local.get $k) (i32.const 15)))
      (local.set $op (call $fetch))
      (if (i32.or (i32.eq (local.get $op) (i32.const 0xf0)) (i32.eq (i32.and (local.get $op) (i32.const 0xe7)) (i32.const 0x26))) (then (local.set $k (i32.add (local.get $k) (i32.const 1))) (br $pl)))   ;; LOCK, ES CS SS DS
      (if (i32.or (i32.eq (local.get $op) (i32.const 0xf2)) (i32.eq (local.get $op) (i32.const 0xf3))) (then (global.set $x_rep (i32.sub (local.get $op) (i32.const 0xf0))) (local.set $k (i32.add (local.get $k) (i32.const 1))) (br $pl)))
      (if (i32.eq (global.get $xm) (i32.const 2)) (then
        (if (i32.or (i32.eq (local.get $op) (i32.const 0x64)) (i32.eq (local.get $op) (i32.const 0x65))) (then (local.set $k (i32.add (local.get $k) (i32.const 1))) (br $pl)))   ;; FS GS
        (if (i32.eq (local.get $op) (i32.const 0x66)) (then (global.set $x_osz (i32.const 4)) (local.set $k (i32.add (local.get $k) (i32.const 1))) (br $pl)))
        (if (i32.eq (local.get $op) (i32.const 0x67)) (then (global.set $x_asz (i32.const 4)) (local.set $k (i32.add (local.get $k) (i32.const 1))) (br $pl)))))
      (br $pe)))
    (local.set $sz (global.get $x_osz)) (local.set $w (select (global.get $x_osz) (i32.const 1) (i32.and (local.get $op) (i32.const 1))))   ;; w: byte or full operand by bit 0
    ;; the 8086 reads 60..6F as 70..7F and C0/C1, C8/C9 as C2/C3, CA/CB
    (if (i32.eqz (global.get $xm)) (then
      (if (i32.eq (i32.and (local.get $op) (i32.const 0xf0)) (i32.const 0x60)) (then (local.set $op (i32.or (local.get $op) (i32.const 0x10)))))
      (if (i32.eq (i32.and (local.get $op) (i32.const 0xf6)) (i32.const 0xc0)) (then (local.set $op (i32.or (local.get $op) (i32.const 2)))))))
    (block $end
      (if (i32.lt_u (local.get $op) (i32.const 0x40)) (then
        (local.set $n (i32.shr_u (local.get $op) (i32.const 3))) (local.set $t (i32.and (local.get $op) (i32.const 7)))
        (if (i32.lt_u (local.get $t) (i32.const 4)) (then   ;; ALU rm,r / r,rm
          (call $x_modrm)
          (if (i32.and (local.get $op) (i32.const 2))
            (then (call $xs (global.get $x_reg) (local.get $w) (call $x_alu (local.get $n) (call $xg (global.get $x_reg) (local.get $w)) (call $x_ld (global.get $x_rm) (local.get $w)) (local.get $w))))
            (else (local.set $r (call $x_alu (local.get $n) (call $x_ld (global.get $x_rm) (local.get $w)) (call $xg (global.get $x_reg) (local.get $w)) (local.get $w)))
              (if (i32.ne (local.get $n) (i32.const 7)) (then (call $x_st (global.get $x_rm) (local.get $w) (local.get $r))))))
          (br $end)))
        (if (i32.lt_u (local.get $t) (i32.const 6)) (then (call $xs (i32.const 0) (local.get $w) (call $x_alu (local.get $n) (call $xg (i32.const 0) (local.get $w)) (call $x_imm (local.get $w)) (local.get $w))) (br $end)))   ;; ALU AL/AX,imm
        (if (i32.lt_u (local.get $op) (i32.const 0x20)) (then   ;; PUSH/POP ES CS SS DS; 0F
          (if (i32.eq (local.get $op) (i32.const 0x0f)) (then (if (global.get $xm) (then (call $x_0f))) (br $end)))
          (if (i32.eq (local.get $t) (i32.const 6)) (then (call $x_push (call $x_sg (local.get $n)))) (else (call $x_ss (local.get $n) (call $x_pop))))
          (br $end)))
        ;; 27 DAA 2F DAS 37 AAA 3F AAS
        (local.set $d (call $xg (i32.const 0) (i32.const 1)))
        (if (i32.lt_u (local.get $op) (i32.const 0x30))
          (then (local.set $s (i32.const 0))
            (if (i32.or (i32.gt_u (i32.and (local.get $d) (i32.const 15)) (i32.const 9)) (i32.and (call $x_fl) (i32.const 0x10))) (then (local.set $s (i32.const 6)) (call $x_setf (i32.const 0x10) (i32.const 1))))
            (if (i32.or (i32.gt_u (local.get $d) (i32.const 0x99)) (call $x_cf)) (then (local.set $s (i32.add (local.get $s) (i32.const 0x60))) (call $x_setf (i32.const 1) (i32.const 1))))
            (local.set $r (i32.and (select (i32.sub (local.get $d) (local.get $s)) (i32.add (local.get $d) (local.get $s)) (i32.eq (local.get $op) (i32.const 0x2f))) (i32.const 0xff)))
            (call $xs (i32.const 0) (i32.const 1) (local.get $r)) (call $x_szp (local.get $r) (i32.const 1)))
          (else
            (if (i32.or (i32.gt_u (i32.and (local.get $d) (i32.const 15)) (i32.const 9)) (i32.and (call $x_fl) (i32.const 0x10)))
              (then (call $xs (i32.const 0) (i32.const 2) (i32.and (select (i32.sub (call $xg (i32.const 0) (i32.const 2)) (i32.const 0x106)) (i32.add (call $xg (i32.const 0) (i32.const 2)) (i32.const 0x106)) (i32.eq (local.get $op) (i32.const 0x3f))) (i32.const 0xff0f))) (call $x_setf (i32.const 0x11) (i32.const 1)))
              (else (call $x_setf (i32.const 0x11) (i32.const 0)) (call $xs (i32.const 0) (i32.const 1) (i32.and (local.get $d) (i32.const 15)))))))
        (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0x50)) (then   ;; INC / DEC r
        (local.set $n (i32.and (local.get $op) (i32.const 7))) (local.set $t (call $x_cf))
        (call $xs (local.get $n) (local.get $sz) (select (call $x_sub (call $xg (local.get $n) (local.get $sz)) (i32.const 1) (local.get $sz) (i32.const 0)) (call $x_add (call $xg (local.get $n) (local.get $sz)) (i32.const 1) (local.get $sz) (i32.const 0)) (i32.and (local.get $op) (i32.const 8))))
        (call $x_setf (i32.const 1) (local.get $t)) (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0x60)) (then   ;; PUSH / POP r
        (local.set $n (i32.and (local.get $op) (i32.const 7)))
        (if (i32.and (local.get $op) (i32.const 8)) (then (call $xs (local.get $n) (local.get $sz) (call $x_pop))) (else (call $x_push (call $xg (local.get $n) (local.get $sz)))))
        (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0x70)) (then   ;; 186: PUSHA POPA BOUND ARPL PUSH imm IMUL INS OUTS
        (if (i32.eq (local.get $op) (i32.const 0x60)) (then (local.set $t (call $xg (i32.const 4) (i32.const 2)))
          (block $e (loop $l (br_if $e (i32.ge_u (local.get $n) (i32.const 8))) (call $x_push (select (local.get $t) (call $xg (local.get $n) (local.get $sz)) (i32.eq (local.get $n) (i32.const 4)))) (local.set $n (i32.add (local.get $n) (i32.const 1))) (br $l))) (br $end)))
        (if (i32.eq (local.get $op) (i32.const 0x61)) (then (local.set $n (i32.const 7))
          (block $e (loop $l (br_if $e (i32.lt_s (local.get $n) (i32.const 0))) (local.set $t (call $x_pop)) (if (i32.ne (local.get $n) (i32.const 4)) (then (call $xs (local.get $n) (local.get $sz) (local.get $t)))) (local.set $n (i32.sub (local.get $n) (i32.const 1))) (br $l))) (br $end)))
        (if (i32.or (i32.eq (local.get $op) (i32.const 0x62)) (i32.eq (local.get $op) (i32.const 0x63))) (then (call $x_modrm) (br $end)))
        (if (i32.eq (local.get $op) (i32.const 0x68)) (then (call $x_push (call $x_imm (local.get $sz))) (br $end)))
        (if (i32.eq (local.get $op) (i32.const 0x6a)) (then (call $x_push (call $sext8 (call $fetch))) (br $end)))
        (if (i32.eq (i32.and (local.get $op) (i32.const 0xfd)) (i32.const 0x69)) (then   ;; IMUL r,rm,imm
          (call $x_modrm) (local.set $d (call $x_sx (call $x_ld (global.get $x_rm) (local.get $sz)) (local.get $sz)))
          (local.set $s (select (call $sext8 (call $fetch)) (call $x_sx (call $x_imm (local.get $sz)) (local.get $sz)) (i32.and (local.get $op) (i32.const 2))))
          (local.set $r (i32.mul (local.get $d) (local.get $s)))
          (call $x_setf (i32.const 0x801) (i64.ne (i64.mul (i64.extend_i32_s (local.get $d)) (i64.extend_i32_s (local.get $s))) (i64.extend_i32_s (call $x_sx (local.get $r) (local.get $sz)))))
          (call $xs (global.get $x_reg) (local.get $sz) (local.get $r)) (br $end)))
        (br $end)))   ;; 64..67 on the 286, 6C..6F: NOPs
      (if (i32.lt_u (local.get $op) (i32.const 0x80)) (then   ;; Jcc rel8
        (local.set $s (call $sext8 (call $fetch)))
        (if (call $x_cc (local.get $op)) (then (call $zw16 (i32.const 22) (i32.and (i32.add (call $zr16 (i32.const 22)) (local.get $s)) (i32.const 0xffff)))))
        (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0x84)) (then   ;; group 1: ALU rm,imm (83: sign-extended imm8)
        (call $x_modrm)
        (local.set $s (select (call $sext8 (call $fetch)) (call $x_imm (local.get $w)) (i32.eq (local.get $op) (i32.const 0x83))))
        (local.set $r (call $x_alu (global.get $x_reg) (call $x_ld (global.get $x_rm) (local.get $w)) (local.get $s) (local.get $w)))
        (if (i32.ne (global.get $x_reg) (i32.const 7)) (then (call $x_st (global.get $x_rm) (local.get $w) (local.get $r))))
        (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0x86)) (then (call $x_modrm) (drop (call $x_logic (i32.and (call $x_ld (global.get $x_rm) (local.get $w)) (call $xg (global.get $x_reg) (local.get $w))) (local.get $w))) (br $end)))   ;; TEST
      (if (i32.lt_u (local.get $op) (i32.const 0x88)) (then (call $x_modrm) (local.set $t (call $x_ld (global.get $x_rm) (local.get $w)))   ;; XCHG
        (call $x_st (global.get $x_rm) (local.get $w) (call $xg (global.get $x_reg) (local.get $w))) (call $xs (global.get $x_reg) (local.get $w) (local.get $t)) (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0x8c)) (then (call $x_modrm)   ;; MOV
        (if (i32.and (local.get $op) (i32.const 2)) (then (call $xs (global.get $x_reg) (local.get $w) (call $x_ld (global.get $x_rm) (local.get $w)))) (else (call $x_st (global.get $x_rm) (local.get $w) (call $xg (global.get $x_reg) (local.get $w)))))
        (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x8c)) (then (call $x_modrm) (call $x_st (global.get $x_rm) (i32.const 2) (call $x_sg (global.get $x_reg))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x8e)) (then (call $x_modrm) (call $x_ss (global.get $x_reg) (call $x_ld (global.get $x_rm) (i32.const 2))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x8d)) (then (call $x_modrm) (if (i32.lt_u (global.get $x_rm) (i32.const 0x10000)) (then (call $xs (global.get $x_reg) (local.get $sz) (global.get $x_rm)))) (br $end)))   ;; LEA
      (if (i32.eq (local.get $op) (i32.const 0x8f)) (then (call $x_modrm) (call $x_st (global.get $x_rm) (local.get $sz) (call $x_pop)) (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0x98)) (then (local.set $n (i32.and (local.get $op) (i32.const 7)))   ;; XCHG AX,r (90 = NOP)
        (local.set $t (call $xg (i32.const 0) (local.get $sz))) (call $xs (i32.const 0) (local.get $sz) (call $xg (local.get $n) (local.get $sz))) (call $xs (local.get $n) (local.get $sz) (local.get $t)) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x98)) (then   ;; CBW / CWDE
        (if (i32.eq (local.get $sz) (i32.const 2)) (then (call $xs (i32.const 0) (i32.const 2) (call $sext8 (call $xg (i32.const 0) (i32.const 1))))) (else (call $xs (i32.const 0) (i32.const 4) (call $sx (call $xg (i32.const 0) (i32.const 2)) (i32.const 16)))))
        (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x99)) (then (call $xs (i32.const 2) (local.get $sz) (i32.shr_s (call $x_sx (call $xg (i32.const 0) (local.get $sz)) (local.get $sz)) (i32.const 31))) (br $end)))   ;; CWD / CDQ
      (if (i32.eq (local.get $op) (i32.const 0x9a)) (then   ;; CALL far
        (local.set $t (call $x_imm (local.get $sz))) (local.set $s (call $fetch16))
        (call $x_push (call $x_sg (i32.const 1))) (call $x_push (call $zr16 (i32.const 22))) (call $x_ss (i32.const 1) (local.get $s)) (call $zw16 (i32.const 22) (i32.and (local.get $t) (i32.const 0xffff))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x9c)) (then (call $x_push (i32.or (call $x_fl) (i32.const 0xf002))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x9d)) (then (call $zw16 (i32.const 20) (i32.and (call $x_pop) (i32.const 0x0fd5))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x9e)) (then (call $zw16 (i32.const 20) (i32.or (i32.and (call $x_fl) (i32.const 0xff00)) (i32.or (i32.and (call $xg (i32.const 4) (i32.const 1)) (i32.const 0xd5)) (i32.const 2)))) (br $end)))   ;; SAHF
      (if (i32.eq (local.get $op) (i32.const 0x9f)) (then (call $xs (i32.const 4) (i32.const 1) (i32.or (i32.and (call $x_fl) (i32.const 0xd5)) (i32.const 2))) (br $end)))   ;; LAHF
      (if (i32.eq (local.get $op) (i32.const 0x9b)) (then (br $end)))   ;; WAIT
      (if (i32.lt_u (local.get $op) (i32.const 0xa4)) (then   ;; MOV AL/AX,moffs and back
        (local.set $t (i32.and (call $x_imm (global.get $x_asz)) (i32.const 0xffff)))
        (if (i32.and (local.get $op) (i32.const 2)) (then (call $x_st (local.get $t) (local.get $w) (call $xg (i32.const 0) (local.get $w)))) (else (call $xs (i32.const 0) (local.get $w) (call $x_ld (local.get $t) (local.get $w)))))
        (br $end)))
      (if (i32.or (i32.eq (local.get $op) (i32.const 0xa8)) (i32.eq (local.get $op) (i32.const 0xa9))) (then (drop (call $x_logic (i32.and (call $xg (i32.const 0) (local.get $w)) (call $x_imm (local.get $w))) (local.get $w))) (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0xb0)) (then (call $x_string (local.get $op)) (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0xb8)) (then (call $xs (i32.and (local.get $op) (i32.const 7)) (i32.const 1) (call $fetch)) (br $end)))   ;; MOV r8,imm8
      (if (i32.lt_u (local.get $op) (i32.const 0xc0)) (then (call $xs (i32.and (local.get $op) (i32.const 7)) (local.get $sz) (call $x_imm (local.get $sz))) (br $end)))   ;; MOV r,imm
      (if (i32.lt_u (local.get $op) (i32.const 0xc2)) (then (call $x_modrm) (local.set $t (call $fetch)) (call $x_st (global.get $x_rm) (local.get $w) (call $x_shift (global.get $x_reg) (call $x_ld (global.get $x_rm) (local.get $w)) (local.get $t) (local.get $w))) (br $end)))   ;; shift rm,imm8 (186)
      (if (i32.lt_u (local.get $op) (i32.const 0xc4)) (then   ;; RET (imm16)
        (local.set $t (select (call $fetch16) (i32.const 0) (i32.eqz (i32.and (local.get $op) (i32.const 1)))))
        (call $zw16 (i32.const 22) (i32.and (call $x_pop) (i32.const 0xffff))) (call $xs (i32.const 4) (i32.const 2) (i32.add (call $xg (i32.const 4) (i32.const 2)) (local.get $t))) (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0xc6)) (then   ;; LES / LDS
        (call $x_modrm) (if (i32.lt_u (global.get $x_rm) (i32.const 0x10000)) (then
          (call $xs (global.get $x_reg) (local.get $sz) (call $x_ld (global.get $x_rm) (local.get $sz)))
          (call $x_ss (select (i32.const 0) (i32.const 3) (i32.eq (local.get $op) (i32.const 0xc4))) (call $x_ld (i32.and (i32.add (global.get $x_rm) (local.get $sz)) (i32.const 0xffff)) (i32.const 2)))))
        (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0xc8)) (then (call $x_modrm) (call $x_st (global.get $x_rm) (local.get $w) (call $x_imm (local.get $w))) (br $end)))   ;; MOV rm,imm
      (if (i32.eq (local.get $op) (i32.const 0xc8)) (then   ;; ENTER imm16,imm8 (nesting level ignored beyond the frame link)
        (local.set $t (call $fetch16)) (drop (call $fetch))
        (call $x_push (call $xg (i32.const 5) (local.get $sz))) (call $xs (i32.const 5) (local.get $sz) (call $xg (i32.const 4) (i32.const 2)))
        (call $xs (i32.const 4) (i32.const 2) (i32.sub (call $xg (i32.const 4) (i32.const 2)) (local.get $t))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0xc9)) (then (call $xs (i32.const 4) (i32.const 2) (call $xg (i32.const 5) (i32.const 2))) (call $xs (i32.const 5) (local.get $sz) (call $x_pop)) (br $end)))   ;; LEAVE
      (if (i32.lt_u (local.get $op) (i32.const 0xcc)) (then   ;; RETF (imm16)
        (local.set $t (select (call $fetch16) (i32.const 0) (i32.eqz (i32.and (local.get $op) (i32.const 1)))))
        (call $zw16 (i32.const 22) (i32.and (call $x_pop) (i32.const 0xffff))) (call $x_ss (i32.const 1) (call $x_pop)) (call $xs (i32.const 4) (i32.const 2) (i32.add (call $xg (i32.const 4) (i32.const 2)) (local.get $t))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0xcd)) (then (drop (call $fetch)) (br $end)))   ;; INT n (CC INT3, CE INTO: NOPs)
      (if (i32.eq (local.get $op) (i32.const 0xcf)) (then (call $zw16 (i32.const 22) (i32.and (call $x_pop) (i32.const 0xffff))) (call $x_ss (i32.const 1) (call $x_pop)) (call $zw16 (i32.const 20) (i32.and (call $x_pop) (i32.const 0x0fd5))) (br $end)))   ;; IRET
      (if (i32.lt_u (local.get $op) (i32.const 0xd0)) (then (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0xd4)) (then   ;; shift rm,1 / rm,CL
        (call $x_modrm) (local.set $t (select (call $xg (i32.const 1) (i32.const 1)) (i32.const 1) (i32.and (local.get $op) (i32.const 2))))
        (call $x_st (global.get $x_rm) (local.get $w) (call $x_shift (global.get $x_reg) (call $x_ld (global.get $x_rm) (local.get $w)) (local.get $t) (local.get $w))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0xd4)) (then (local.set $t (call $fetch)) (local.set $d (call $xg (i32.const 0) (i32.const 1)))   ;; AAM
        (if (local.get $t) (then (call $xs (i32.const 4) (i32.const 1) (i32.div_u (local.get $d) (local.get $t))) (call $xs (i32.const 0) (i32.const 1) (i32.rem_u (local.get $d) (local.get $t))) (call $x_szp (call $xg (i32.const 0) (i32.const 1)) (i32.const 1))))
        (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0xd5)) (then (local.set $t (call $fetch))   ;; AAD
        (call $xs (i32.const 0) (i32.const 2) (i32.and (i32.add (call $xg (i32.const 0) (i32.const 1)) (i32.mul (call $xg (i32.const 4) (i32.const 1)) (local.get $t))) (i32.const 0xff))) (call $x_szp (call $xg (i32.const 0) (i32.const 1)) (i32.const 1)) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0xd6)) (then (call $xs (i32.const 0) (i32.const 1) (select (i32.const 0xff) (i32.const 0) (call $x_cf))) (br $end)))   ;; SALC
      (if (i32.eq (local.get $op) (i32.const 0xd7)) (then (call $xs (i32.const 0) (i32.const 1) (call $mrd (i32.add (call $xg (i32.const 3) (global.get $x_asz)) (call $xg (i32.const 0) (i32.const 1))))) (br $end)))   ;; XLAT
      (if (i32.lt_u (local.get $op) (i32.const 0xe0)) (then (call $x_modrm) (br $end)))   ;; ESC: the 8087 is not there
      (if (i32.lt_u (local.get $op) (i32.const 0xe4)) (then   ;; LOOPNE LOOPE LOOP JCXZ
        (local.set $s (call $sext8 (call $fetch))) (local.set $t (call $xg (i32.const 1) (global.get $x_asz)))
        (if (i32.eq (local.get $op) (i32.const 0xe3)) (then (local.set $d (i32.eqz (local.get $t))))
          (else (local.set $t (i32.and (i32.sub (local.get $t) (i32.const 1)) (call $x_mask (global.get $x_asz)))) (call $xs (i32.const 1) (global.get $x_asz) (local.get $t))
            (local.set $d (i32.ne (local.get $t) (i32.const 0)))
            (if (i32.eq (local.get $op) (i32.const 0xe0)) (then (local.set $d (i32.and (local.get $d) (i32.eqz (i32.and (call $x_fl) (i32.const 0x40)))))))
            (if (i32.eq (local.get $op) (i32.const 0xe1)) (then (local.set $d (i32.and (local.get $d) (i32.ne (i32.and (call $x_fl) (i32.const 0x40)) (i32.const 0))))))))
        (if (local.get $d) (then (call $zw16 (i32.const 22) (i32.and (i32.add (call $zr16 (i32.const 22)) (local.get $s)) (i32.const 0xffff)))))
        (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0xe8)) (then (drop (call $fetch)) (br $end)))   ;; IN/OUT imm8
      (if (i32.lt_u (local.get $op) (i32.const 0xea)) (then   ;; CALL / JMP rel
        (local.set $s (call $x_imm (local.get $sz))) (if (i32.eq (local.get $sz) (i32.const 2)) (then (local.set $s (call $sx (local.get $s) (i32.const 16)))))
        (if (i32.eq (local.get $op) (i32.const 0xe8)) (then (call $x_push (call $zr16 (i32.const 22)))))
        (call $zw16 (i32.const 22) (i32.and (i32.add (call $zr16 (i32.const 22)) (local.get $s)) (i32.const 0xffff))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0xea)) (then (local.set $t (call $x_imm (local.get $sz))) (call $x_ss (i32.const 1) (call $fetch16)) (call $zw16 (i32.const 22) (i32.and (local.get $t) (i32.const 0xffff))) (br $end)))   ;; JMP far
      (if (i32.eq (local.get $op) (i32.const 0xeb)) (then (local.set $s (call $sext8 (call $fetch))) (call $zw16 (i32.const 22) (i32.and (i32.add (call $zr16 (i32.const 22)) (local.get $s)) (i32.const 0xffff))) (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0xf5)) (then (br $end)))   ;; IN/OUT DX, F1, HLT
      (if (i32.eq (local.get $op) (i32.const 0xf5)) (then (call $x_setf (i32.const 1) (i32.eqz (call $x_cf))) (br $end)))   ;; CMC
      (if (i32.lt_u (local.get $op) (i32.const 0xf8)) (then (call $x_modrm) (call $x_grp3 (local.get $w)) (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0xfe)) (then   ;; CLC STC CLI STI CLD STD
        (if (i32.lt_u (local.get $op) (i32.const 0xfa)) (then (call $x_setf (i32.const 1) (i32.and (local.get $op) (i32.const 1)))))
        (if (i32.ge_u (local.get $op) (i32.const 0xfc)) (then (call $x_setf (i32.const 0x400) (i32.and (local.get $op) (i32.const 1)))))
        (br $end)))
      ;; FE / FF: INC DEC CALL CALLF JMP JMPF PUSH on the ModRM operand
      (call $x_modrm) (local.set $n (global.get $x_reg))
      (if (i32.lt_u (local.get $n) (i32.const 2)) (then (local.set $t (call $x_cf))
        (call $x_st (global.get $x_rm) (local.get $w) (select (call $x_sub (call $x_ld (global.get $x_rm) (local.get $w)) (i32.const 1) (local.get $w) (i32.const 0)) (call $x_add (call $x_ld (global.get $x_rm) (local.get $w)) (i32.const 1) (local.get $w) (i32.const 0)) (local.get $n)))
        (call $x_setf (i32.const 1) (local.get $t)) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0xfe)) (then (br $end)))
      (local.set $t (call $x_ld (global.get $x_rm) (local.get $sz)))
      (if (i32.eq (local.get $n) (i32.const 6)) (then (call $x_push (local.get $t)) (br $end)))
      (if (i32.and (local.get $n) (i32.const 1)) (then   ;; far forms: the segment follows the offset in memory
        (if (i32.ge_u (global.get $x_rm) (i32.const 0x10000)) (then (br $end)))
        (if (i32.eq (local.get $n) (i32.const 3)) (then (call $x_push (call $x_sg (i32.const 1))) (call $x_push (call $zr16 (i32.const 22)))))
        (call $x_ss (i32.const 1) (call $x_ld (i32.and (i32.add (global.get $x_rm) (local.get $sz)) (i32.const 0xffff)) (i32.const 2)))
        (call $zw16 (i32.const 22) (i32.and (local.get $t) (i32.const 0xffff))) (br $end)))
      (if (i32.eq (local.get $n) (i32.const 2)) (then (call $x_push (call $zr16 (i32.const 22)))))
      (call $zw16 (i32.const 22) (i32.and (local.get $t) (i32.const 0xffff)))))
