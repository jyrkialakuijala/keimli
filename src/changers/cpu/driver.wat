  ;; cpu(p, prm, kind): shared driver for kinds 7..15 and 19..21 (6502, 8080, Subleq, CHIP-8, 4004, SM83, 8051, 6809, RISC-V, PDP-8, PDP-11, 68000).
  (func $cpu (param $p i32) (param $prm i32) (param $kind i32) (result i32)
    (local $out i32) (local $flags i32) (local $i i32) (local $changed i32) (local $c i32)
    (local.set $out (i32.load (local.get $prm)))
    (local.set $flags (i32.load offset=36 (local.get $prm)))
    (i64.store (local.get $out) (i64.load (local.get $p)))
    (i64.store offset=8 (local.get $out) (i64.load offset=8 (local.get $p)))
    (global.set $zp (local.get $out))
    (block $re (loop $rl (br_if $re (i32.ge_u (local.get $i) (i32.const 128))) (call $zw (local.get $i) (i32.const 0)) (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $rl)))
    (if (i32.eq (local.get $kind) (i32.const 7)) (then (call $zw (i32.const 4) (i32.const 0x24)) (call $zw (i32.const 3) (i32.const 0xFF))))   ;; 6502: P starts with I and the unused bit set, S at the top of the stack page
    (call $load (local.get $kind))   ;; CHIP-8, 4004, RISC-V, PDP-8: registers start from the pixel bytes and are written back by $spill
    (local.set $i (i32.const 0))
    (block $se (loop $sl (br_if $se (i32.ge_u (local.get $i) (i32.load offset=92 (local.get $prm))))
      (block $done (block $b24 (block $b23 (block $b22 (block $b21 (block $b20 (block $b19 (block $b16 (block $b15 (block $b14 (block $b13 (block $b12 (block $b11 (block $b10 (block $b9 (block $b8 (block $b7
        (br_table $b7 $b8 $b9 $b10 $b11 $b12 $b13 $b14 $b15 $b16 $b16 $b16 $b19 $b20 $b21 $b22 $b23 $b24 (i32.sub (local.get $kind) (i32.const 7))))
        (call $m6502step) (br $done))
        (call $i8080step) (br $done))
        (call $subleq_step) (br $done))
        (call $chip8_step) (br $done))
        (call $i4004_step) (br $done))
        (call $sm83_step) (br $done))
        (call $i8051_step) (br $done))
        (call $m6809_step) (br $done))
        (call $riscv_step) (br $done))
        (br $done))   ;; 16..18 never reach the driver
        (call $pdp8_step) (br $done))
        (call $pdp11_step) (br $done))
        (call $m68k_step) (br $done))
        (call $u1101_step) (br $done))
        (call $vax_step) (br $done))
        (call $cdc6600_step))
      (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $sl)))
    (call $spill (local.get $kind))
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

  ;; load(kind) / spill(kind): register machines whose code rarely stores to
  ;; memory keep their registers in the pixel. $load reads them from the 16
  ;; bytes when the run starts (instead of zeroing them), $spill writes them
  ;; back when it ends, so register state persists from turn to turn and the
  ;; registers, not just memory, are the pixel's content.
  ;;   CHIP-8 (10): V0..VF <-> bytes 0..15.
  ;;   4004 (11):   bytes 0..7 only: the 16 nibbles ACC, R0, R1, ..., R14 in
  ;;                order, low nibble first (R15, CY, PC, SRC and the stack are
  ;;                not kept); bytes 8..15 stay as the machine left them.
  ;;   RISC-V (15): bytes 1..15 <-> low bytes of x1..x15 (zero-extended on
  ;;                load); byte 0 is left alone.
  ;;   PDP-8 (19):  AC, L, PC and MQ live in bits 96..123 (see pdp8.wat).
  ;; 4004 nibble k of the sequence lives at register-file offset nib4(k): 0 for ACC, k + 1 for R(k-1).
  (func $nib4 (param $k i32) (result i32)
    (select (i32.const 0) (i32.add (local.get $k) (i32.const 1)) (i32.eqz (local.get $k))))
  (func $load (param $kind i32)
    (local $i i32) (local $b i32)
    (if (i32.eq (local.get $kind) (i32.const 10)) (then
      (block $e (loop $l (br_if $e (i32.ge_u (local.get $i) (i32.const 16)))
        (call $zw (local.get $i) (call $mrd (local.get $i)))
        (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $l)))))
    (if (i32.eq (local.get $kind) (i32.const 11)) (then
      (block $e (loop $l (br_if $e (i32.ge_u (local.get $i) (i32.const 8)))
        (local.set $b (call $mrd (local.get $i)))
        (call $zw (call $nib4 (i32.shl (local.get $i) (i32.const 1))) (i32.and (local.get $b) (i32.const 15)))
        (call $zw (call $nib4 (i32.add (i32.shl (local.get $i) (i32.const 1)) (i32.const 1))) (i32.shr_u (local.get $b) (i32.const 4)))
        (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $l)))))
    (if (i32.eq (local.get $kind) (i32.const 15)) (then
      (local.set $i (i32.const 1))
      (block $e (loop $l (br_if $e (i32.ge_u (local.get $i) (i32.const 16)))
        (call $xw (local.get $i) (call $mrd (local.get $i)))
        (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $l)))))
    (if (i32.eq (local.get $kind) (i32.const 19)) (then (call $p8_load))))
  (func $spill (param $kind i32)
    (local $i i32)
    (if (i32.eq (local.get $kind) (i32.const 10)) (then
      (block $e (loop $l (br_if $e (i32.ge_u (local.get $i) (i32.const 16)))
        (call $mwr (local.get $i) (call $zr (local.get $i)))
        (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $l)))))
    (if (i32.eq (local.get $kind) (i32.const 11)) (then
      (block $e (loop $l (br_if $e (i32.ge_u (local.get $i) (i32.const 8)))
        (call $mwr (local.get $i) (i32.or
          (i32.and (call $zr (call $nib4 (i32.shl (local.get $i) (i32.const 1)))) (i32.const 15))
          (i32.shl (i32.and (call $zr (call $nib4 (i32.add (i32.shl (local.get $i) (i32.const 1)) (i32.const 1)))) (i32.const 15)) (i32.const 4))))
        (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $l)))))
    (if (i32.eq (local.get $kind) (i32.const 15)) (then
      (local.set $i (i32.const 1))
      (block $e (loop $l (br_if $e (i32.ge_u (local.get $i) (i32.const 16)))
        (call $mwr (local.get $i) (i32.and (call $xr (local.get $i)) (i32.const 255)))
        (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $l)))))
    (if (i32.eq (local.get $kind) (i32.const 19)) (then (call $p8_spill))))
