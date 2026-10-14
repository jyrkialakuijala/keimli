  ;; ========================================================================
  ;; RISC-V RV32EC (kind 15): 16 registers x0..x15 (i32 each at register-file
  ;; offset 64 + 4n; x0 reads as zero; field values 16..31 alias x0..x15), PC at
  ;; 22. The 16 bytes are the whole address space; words and halfwords are
  ;; little-endian and wrap byte by byte. Full RV32I base (FENCE, ECALL and
  ;; EBREAK are NOPs) plus the C extension's integer subset. Misaligned
  ;; accesses are allowed. Unknown encodings are NOPs.
  (func $xr (param $n i32) (result i32)
    (if (result i32) (i32.and (local.get $n) (i32.const 15)) (then (i32.load offset=320 (i32.shl (i32.and (local.get $n) (i32.const 15)) (i32.const 2)))) (else (i32.const 0))))
  (func $xw (param $n i32) (param $v i32)
    (if (i32.and (local.get $n) (i32.const 15)) (then (i32.store offset=320 (i32.shl (i32.and (local.get $n) (i32.const 15)) (i32.const 2)) (local.get $v)))))
  (func $mrd16le (param $a i32) (result i32) (i32.or (call $mrd (local.get $a)) (i32.shl (call $mrd (i32.add (local.get $a) (i32.const 1))) (i32.const 8))))
  (func $mrd32 (param $a i32) (result i32) (i32.or (call $mrd16le (local.get $a)) (i32.shl (call $mrd16le (i32.add (local.get $a) (i32.const 2))) (i32.const 16))))
  (func $mwr16le (param $a i32) (param $v i32) (call $mwr (local.get $a) (i32.and (local.get $v) (i32.const 255))) (call $mwr (i32.add (local.get $a) (i32.const 1)) (i32.and (i32.shr_u (local.get $v) (i32.const 8)) (i32.const 255))))
  (func $mwr32 (param $a i32) (param $v i32) (call $mwr16le (local.get $a) (local.get $v)) (call $mwr16le (i32.add (local.get $a) (i32.const 2)) (i32.shr_u (local.get $v) (i32.const 16))))
  (func $sx (param $v i32) (param $bits i32) (result i32) (i32.shr_s (i32.shl (local.get $v) (i32.sub (i32.const 32) (local.get $bits))) (i32.sub (i32.const 32) (local.get $bits))))
  (func $bit (param $v i32) (param $pos i32) (param $to i32) (result i32) (i32.shl (i32.and (i32.shr_u (local.get $v) (local.get $pos)) (i32.const 1)) (local.get $to)))
  (func $bits (param $v i32) (param $pos i32) (param $n i32) (param $to i32) (result i32)
    (i32.shl (i32.and (i32.shr_u (local.get $v) (local.get $pos)) (i32.sub (i32.shl (i32.const 1) (local.get $n)) (i32.const 1))) (local.get $to)))
  (func $alu_rv (param $f3 i32) (param $a i32) (param $b i32) (param $sub i32) (result i32)   ;; shared by OP and OP-IMM; sub = 1 selects SUB/SRA
    (block $r (block $b7 (block $b6 (block $b5 (block $b4 (block $b3 (block $b2 (block $b1 (block $b0
      (br_table $b0 $b1 $b2 $b3 $b4 $b5 $b6 $b7 (local.get $f3)))
      (return (select (i32.sub (local.get $a) (local.get $b)) (i32.add (local.get $a) (local.get $b)) (local.get $sub))))
      (return (i32.shl (local.get $a) (i32.and (local.get $b) (i32.const 31)))))
      (return (i32.lt_s (local.get $a) (local.get $b))))
      (return (i32.lt_u (local.get $a) (local.get $b))))
      (return (i32.xor (local.get $a) (local.get $b))))
      (return (select (i32.shr_s (local.get $a) (i32.and (local.get $b) (i32.const 31))) (i32.shr_u (local.get $a) (i32.and (local.get $b) (i32.const 31))) (local.get $sub))))
      (return (i32.or (local.get $a) (local.get $b))))
      (return (i32.and (local.get $a) (local.get $b))))
    (i32.const 0))
  (func $rv_load (param $f3 i32) (param $a i32) (result i32)
    (if (i32.eqz (local.get $f3)) (then (return (call $sext8 (call $mrd (local.get $a))))))
    (if (i32.eq (local.get $f3) (i32.const 1)) (then (return (call $sx (call $mrd16le (local.get $a)) (i32.const 16)))))
    (if (i32.eq (local.get $f3) (i32.const 2)) (then (return (call $mrd32 (local.get $a)))))
    (if (i32.eq (local.get $f3) (i32.const 4)) (then (return (call $mrd (local.get $a)))))
    (if (i32.eq (local.get $f3) (i32.const 5)) (then (return (call $mrd16le (local.get $a)))))
    (i32.const 0))
  (func $rv_store (param $f3 i32) (param $a i32) (param $v i32)
    (if (i32.eqz (local.get $f3)) (then (call $mwr (local.get $a) (i32.and (local.get $v) (i32.const 255))) (return)))
    (if (i32.eq (local.get $f3) (i32.const 1)) (then (call $mwr16le (local.get $a) (local.get $v)) (return)))
    (if (i32.eq (local.get $f3) (i32.const 2)) (then (call $mwr32 (local.get $a) (local.get $v)))))
  (func $riscv_step
    (local $pc i32) (local $npc i32) (local $inst i32) (local $op i32) (local $rd i32) (local $f3 i32) (local $rs1 i32) (local $rs2 i32) (local $imm i32) (local $t i32) (local $q i32) (local $f2 i32)
    (local.set $pc (call $zr16 (i32.const 22)))
    (local.set $inst (call $mrd16le (local.get $pc)))
    (if (i32.eq (i32.and (local.get $inst) (i32.const 3)) (i32.const 3))
      (then (local.set $inst (i32.or (local.get $inst) (i32.shl (call $mrd16le (i32.add (local.get $pc) (i32.const 2))) (i32.const 16)))) (local.set $npc (i32.add (local.get $pc) (i32.const 4))))
      (else (local.set $npc (i32.add (local.get $pc) (i32.const 2)))))
    (call $zw16 (i32.const 22) (i32.and (local.get $npc) (i32.const 0xffff)))
    (block $end
      (if (i32.eq (i32.and (local.get $inst) (i32.const 3)) (i32.const 3)) (then
        ;; ---------------- 32-bit instructions
        (local.set $op (i32.and (local.get $inst) (i32.const 0x7f))) (local.set $rd (i32.and (i32.shr_u (local.get $inst) (i32.const 7)) (i32.const 31)))
        (local.set $f3 (i32.and (i32.shr_u (local.get $inst) (i32.const 12)) (i32.const 7))) (local.set $rs1 (i32.and (i32.shr_u (local.get $inst) (i32.const 15)) (i32.const 31)))
        (local.set $rs2 (i32.and (i32.shr_u (local.get $inst) (i32.const 20)) (i32.const 31))) (local.set $imm (i32.shr_s (local.get $inst) (i32.const 20)))
        (if (i32.eq (local.get $op) (i32.const 0x37)) (then (call $xw (local.get $rd) (i32.and (local.get $inst) (i32.const 0xfffff000))) (br $end)))
        (if (i32.eq (local.get $op) (i32.const 0x17)) (then (call $xw (local.get $rd) (i32.add (local.get $pc) (i32.and (local.get $inst) (i32.const 0xfffff000)))) (br $end)))
        (if (i32.eq (local.get $op) (i32.const 0x6F)) (then
          (local.set $t (call $sx (i32.or (i32.or (call $bit (local.get $inst) (i32.const 31) (i32.const 20)) (call $bits (local.get $inst) (i32.const 12) (i32.const 8) (i32.const 12)))
                                          (i32.or (call $bit (local.get $inst) (i32.const 20) (i32.const 11)) (call $bits (local.get $inst) (i32.const 21) (i32.const 10) (i32.const 1)))) (i32.const 21)))
          (call $xw (local.get $rd) (local.get $npc)) (call $zw16 (i32.const 22) (i32.and (i32.add (local.get $pc) (local.get $t)) (i32.const 0xffff))) (br $end)))
        (if (i32.eq (local.get $op) (i32.const 0x67)) (then
          (local.set $t (i32.and (i32.add (call $xr (local.get $rs1)) (local.get $imm)) (i32.const -2)))
          (call $xw (local.get $rd) (local.get $npc)) (call $zw16 (i32.const 22) (i32.and (local.get $t) (i32.const 0xffff))) (br $end)))
        (if (i32.eq (local.get $op) (i32.const 0x63)) (then
          (local.set $t (call $sx (i32.or (i32.or (call $bit (local.get $inst) (i32.const 31) (i32.const 12)) (call $bit (local.get $inst) (i32.const 7) (i32.const 11)))
                                          (i32.or (call $bits (local.get $inst) (i32.const 25) (i32.const 6) (i32.const 5)) (call $bits (local.get $inst) (i32.const 8) (i32.const 4) (i32.const 1)))) (i32.const 13)))
          (local.set $rs1 (call $xr (local.get $rs1))) (local.set $rs2 (call $xr (local.get $rs2)))
          (local.set $q (select (i32.eq (local.get $rs1) (local.get $rs2)) (select (i32.ne (local.get $rs1) (local.get $rs2)) (select (i32.lt_s (local.get $rs1) (local.get $rs2)) (select (i32.ge_s (local.get $rs1) (local.get $rs2))
            (select (i32.lt_u (local.get $rs1) (local.get $rs2)) (select (i32.ge_u (local.get $rs1) (local.get $rs2)) (i32.const 0) (i32.eq (local.get $f3) (i32.const 7))) (i32.eq (local.get $f3) (i32.const 6)))
            (i32.eq (local.get $f3) (i32.const 5))) (i32.eq (local.get $f3) (i32.const 4))) (i32.eq (local.get $f3) (i32.const 1))) (i32.eqz (local.get $f3))))
          (if (local.get $q) (then (call $zw16 (i32.const 22) (i32.and (i32.add (local.get $pc) (local.get $t)) (i32.const 0xffff)))))
          (br $end)))
        (if (i32.eq (local.get $op) (i32.const 0x03)) (then (call $xw (local.get $rd) (call $rv_load (local.get $f3) (i32.add (call $xr (local.get $rs1)) (local.get $imm)))) (br $end)))
        (if (i32.eq (local.get $op) (i32.const 0x23)) (then
          (local.set $t (call $sx (i32.or (call $bits (local.get $inst) (i32.const 25) (i32.const 7) (i32.const 5)) (call $bits (local.get $inst) (i32.const 7) (i32.const 5) (i32.const 0))) (i32.const 12)))
          (call $rv_store (local.get $f3) (i32.add (call $xr (local.get $rs1)) (local.get $t)) (call $xr (local.get $rs2))) (br $end)))
        (if (i32.eq (local.get $op) (i32.const 0x13)) (then
          (local.set $t (select (i32.and (i32.shr_u (local.get $inst) (i32.const 30)) (i32.const 1)) (i32.const 0) (i32.eq (local.get $f3) (i32.const 5))))   ;; SRAI
          (call $xw (local.get $rd) (call $alu_rv (local.get $f3) (call $xr (local.get $rs1)) (select (local.get $rs2) (local.get $imm) (i32.or (i32.eq (local.get $f3) (i32.const 1)) (i32.eq (local.get $f3) (i32.const 5)))) (local.get $t)))
          (br $end)))
        (if (i32.eq (local.get $op) (i32.const 0x33)) (then
          (call $xw (local.get $rd) (call $alu_rv (local.get $f3) (call $xr (local.get $rs1)) (call $xr (local.get $rs2)) (i32.and (i32.shr_u (local.get $inst) (i32.const 30)) (i32.const 1))))
          (br $end)))
        (br $end)))   ;; FENCE, SYSTEM, others
      ;; ---------------- 16-bit instructions
      (local.set $q (i32.and (local.get $inst) (i32.const 3))) (local.set $f3 (i32.and (i32.shr_u (local.get $inst) (i32.const 13)) (i32.const 7)))
      (local.set $rd (i32.and (i32.shr_u (local.get $inst) (i32.const 7)) (i32.const 31))) (local.set $rs2 (i32.and (i32.shr_u (local.get $inst) (i32.const 2)) (i32.const 31)))
      (local.set $rs1 (i32.add (i32.const 8) (i32.and (i32.shr_u (local.get $inst) (i32.const 7)) (i32.const 7))))   ;; rs1'/rd'
      (local.set $f2 (i32.add (i32.const 8) (i32.and (i32.shr_u (local.get $inst) (i32.const 2)) (i32.const 7))))    ;; rs2'/rd'
      (if (i32.eqz (local.get $q)) (then
        (if (i32.eqz (local.get $f3)) (then   ;; C.ADDI4SPN
          (local.set $t (i32.or (i32.or (call $bits (local.get $inst) (i32.const 7) (i32.const 4) (i32.const 6)) (call $bits (local.get $inst) (i32.const 11) (i32.const 2) (i32.const 4)))
                                (i32.or (call $bit (local.get $inst) (i32.const 5) (i32.const 3)) (call $bit (local.get $inst) (i32.const 6) (i32.const 2)))))
          (if (local.get $t) (then (call $xw (local.get $f2) (i32.add (call $xr (i32.const 2)) (local.get $t)))))
          (br $end)))
        (local.set $t (i32.or (i32.or (call $bits (local.get $inst) (i32.const 10) (i32.const 3) (i32.const 3)) (call $bit (local.get $inst) (i32.const 6) (i32.const 2))) (call $bit (local.get $inst) (i32.const 5) (i32.const 6))))
        (if (i32.eq (local.get $f3) (i32.const 2)) (then (call $xw (local.get $f2) (call $mrd32 (i32.add (call $xr (local.get $rs1)) (local.get $t)))) (br $end)))
        (if (i32.eq (local.get $f3) (i32.const 6)) (then (call $mwr32 (i32.add (call $xr (local.get $rs1)) (local.get $t)) (call $xr (local.get $f2))) (br $end)))
        (br $end)))
      (if (i32.eq (local.get $q) (i32.const 1)) (then
        (local.set $imm (call $sx (i32.or (call $bit (local.get $inst) (i32.const 12) (i32.const 5)) (call $bits (local.get $inst) (i32.const 2) (i32.const 5) (i32.const 0))) (i32.const 6)))
        (if (i32.eqz (local.get $f3)) (then (call $xw (local.get $rd) (i32.add (call $xr (local.get $rd)) (local.get $imm))) (br $end)))
        (if (i32.or (i32.eq (local.get $f3) (i32.const 1)) (i32.eq (local.get $f3) (i32.const 5))) (then   ;; C.JAL / C.J
          (local.set $t (call $sx (i32.or (i32.or (i32.or (call $bit (local.get $inst) (i32.const 12) (i32.const 11)) (call $bit (local.get $inst) (i32.const 11) (i32.const 4)))
                                                  (i32.or (call $bits (local.get $inst) (i32.const 9) (i32.const 2) (i32.const 8)) (call $bit (local.get $inst) (i32.const 8) (i32.const 10))))
                                          (i32.or (i32.or (call $bit (local.get $inst) (i32.const 7) (i32.const 6)) (call $bit (local.get $inst) (i32.const 6) (i32.const 7)))
                                                  (i32.or (call $bits (local.get $inst) (i32.const 3) (i32.const 3) (i32.const 1)) (call $bit (local.get $inst) (i32.const 2) (i32.const 5))))) (i32.const 12)))
          (if (i32.eq (local.get $f3) (i32.const 1)) (then (call $xw (i32.const 1) (local.get $npc))))
          (call $zw16 (i32.const 22) (i32.and (i32.add (local.get $pc) (local.get $t)) (i32.const 0xffff))) (br $end)))
        (if (i32.eq (local.get $f3) (i32.const 2)) (then (call $xw (local.get $rd) (local.get $imm)) (br $end)))
        (if (i32.eq (local.get $f3) (i32.const 3)) (then
          (if (i32.eq (local.get $rd) (i32.const 2))
            (then (local.set $t (call $sx (i32.or (i32.or (call $bit (local.get $inst) (i32.const 12) (i32.const 9)) (call $bit (local.get $inst) (i32.const 6) (i32.const 4)))
                                                  (i32.or (i32.or (call $bit (local.get $inst) (i32.const 5) (i32.const 6)) (call $bits (local.get $inst) (i32.const 3) (i32.const 2) (i32.const 7))) (call $bit (local.get $inst) (i32.const 2) (i32.const 5)))) (i32.const 10)))
                  (if (local.get $t) (then (call $xw (i32.const 2) (i32.add (call $xr (i32.const 2)) (local.get $t))))))
            (else (local.set $t (call $sx (i32.or (call $bit (local.get $inst) (i32.const 12) (i32.const 17)) (call $bits (local.get $inst) (i32.const 2) (i32.const 5) (i32.const 12))) (i32.const 18)))
                  (if (local.get $t) (then (call $xw (local.get $rd) (local.get $t))))))
          (br $end)))
        (if (i32.eq (local.get $f3) (i32.const 4)) (then
          (local.set $t (i32.and (i32.shr_u (local.get $inst) (i32.const 10)) (i32.const 3)))
          (local.set $op (i32.or (call $bit (local.get $inst) (i32.const 12) (i32.const 5)) (call $bits (local.get $inst) (i32.const 2) (i32.const 5) (i32.const 0))))   ;; shamt
          (if (i32.eqz (local.get $t)) (then (call $xw (local.get $rs1) (i32.shr_u (call $xr (local.get $rs1)) (i32.and (local.get $op) (i32.const 31)))) (br $end)))
          (if (i32.eq (local.get $t) (i32.const 1)) (then (call $xw (local.get $rs1) (i32.shr_s (call $xr (local.get $rs1)) (i32.and (local.get $op) (i32.const 31)))) (br $end)))
          (if (i32.eq (local.get $t) (i32.const 2)) (then (call $xw (local.get $rs1) (i32.and (call $xr (local.get $rs1)) (local.get $imm))) (br $end)))
          (if (i32.eqz (i32.and (local.get $inst) (i32.const 0x1000))) (then
            (local.set $t (i32.and (i32.shr_u (local.get $inst) (i32.const 5)) (i32.const 3)))
            (call $xw (local.get $rs1) (select (i32.sub (call $xr (local.get $rs1)) (call $xr (local.get $f2))) (select (i32.xor (call $xr (local.get $rs1)) (call $xr (local.get $f2)))
              (select (i32.or (call $xr (local.get $rs1)) (call $xr (local.get $f2))) (i32.and (call $xr (local.get $rs1)) (call $xr (local.get $f2))) (i32.eq (local.get $t) (i32.const 2))) (i32.eq (local.get $t) (i32.const 1))) (i32.eqz (local.get $t))))))
          (br $end)))
        ;; C.BEQZ / C.BNEZ
        (local.set $t (call $sx (i32.or (i32.or (call $bit (local.get $inst) (i32.const 12) (i32.const 8)) (call $bits (local.get $inst) (i32.const 10) (i32.const 2) (i32.const 3)))
                                        (i32.or (i32.or (call $bits (local.get $inst) (i32.const 5) (i32.const 2) (i32.const 6)) (call $bits (local.get $inst) (i32.const 3) (i32.const 2) (i32.const 1))) (call $bit (local.get $inst) (i32.const 2) (i32.const 5)))) (i32.const 9)))
        (if (i32.eq (i32.eqz (call $xr (local.get $rs1))) (i32.eq (local.get $f3) (i32.const 6)))
          (then (call $zw16 (i32.const 22) (i32.and (i32.add (local.get $pc) (local.get $t)) (i32.const 0xffff)))))
        (br $end)))
      (if (i32.eq (local.get $q) (i32.const 2)) (then
        (if (i32.eqz (local.get $f3)) (then (call $xw (local.get $rd) (i32.shl (call $xr (local.get $rd)) (i32.and (i32.or (call $bit (local.get $inst) (i32.const 12) (i32.const 5)) (local.get $rs2)) (i32.const 31)))) (br $end)))
        (if (i32.eq (local.get $f3) (i32.const 2)) (then
          (local.set $t (i32.or (i32.or (call $bit (local.get $inst) (i32.const 12) (i32.const 5)) (call $bits (local.get $inst) (i32.const 4) (i32.const 3) (i32.const 2))) (call $bits (local.get $inst) (i32.const 2) (i32.const 2) (i32.const 6))))
          (call $xw (local.get $rd) (call $mrd32 (i32.add (call $xr (i32.const 2)) (local.get $t)))) (br $end)))
        (if (i32.eq (local.get $f3) (i32.const 4)) (then
          (if (i32.eqz (i32.and (local.get $inst) (i32.const 0x1000)))
            (then (if (local.get $rs2) (then (call $xw (local.get $rd) (call $xr (local.get $rs2)))) (else (call $zw16 (i32.const 22) (i32.and (call $xr (local.get $rd)) (i32.const 0xfffe))))))
            (else (if (local.get $rs2) (then (call $xw (local.get $rd) (i32.add (call $xr (local.get $rd)) (call $xr (local.get $rs2)))))
                    (else (if (local.get $rd) (then (local.set $t (call $xr (local.get $rd))) (call $xw (i32.const 1) (local.get $npc)) (call $zw16 (i32.const 22) (i32.and (local.get $t) (i32.const 0xfffe)))))))))   ;; C.JALR; C.EBREAK is a NOP
          (br $end)))
        (if (i32.eq (local.get $f3) (i32.const 6)) (then
          (local.set $t (i32.or (call $bits (local.get $inst) (i32.const 9) (i32.const 4) (i32.const 2)) (call $bits (local.get $inst) (i32.const 7) (i32.const 2) (i32.const 6))))
          (call $mwr32 (i32.add (call $xr (i32.const 2)) (local.get $t)) (call $xr (local.get $rs2))) (br $end)))
        (br $end)))))
