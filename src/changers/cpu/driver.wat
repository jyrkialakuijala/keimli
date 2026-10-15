  ;; cpu(p, prm, kind): shared driver for kinds 7..15 and 19..21 (6502, 8080, Subleq, CHIP-8, 4004, SM83, 8051, 6809, RISC-V, PDP-8, PDP-11, 68000).
  (func $cpu (param $p i32) (param $prm i32) (param $kind i32) (result i32)
    (local $out i32) (local $flags i32) (local $i i32) (local $changed i32) (local $c i32)
    (local.set $out (i32.load (local.get $prm)))
    (local.set $flags (i32.load offset=36 (local.get $prm)))
    (i64.store (local.get $out) (i64.load (local.get $p)))
    (i64.store offset=8 (local.get $out) (i64.load offset=8 (local.get $p)))
    (if (i32.eq (global.get $cw) (i32.const 32)) (then   ;; a joint cell of two pixels
      (i64.store offset=16 (local.get $out) (i64.load offset=16 (local.get $p)))
      (i64.store offset=24 (local.get $out) (i64.load offset=24 (local.get $p)))))
    (global.set $zp (local.get $out))
    (block $re (loop $rl (br_if $re (i32.ge_u (local.get $i) (i32.const 128))) (call $zw (local.get $i) (i32.const 0)) (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $rl)))
    (if (i32.eq (local.get $kind) (i32.const 7)) (then (call $zw (i32.const 4) (i32.const 0x24)) (call $zw (i32.const 3) (i32.const 0xFF))))   ;; 6502: P starts with I and the unused bit set, S at the top of the stack page
    (call $load (local.get $kind))   ;; CHIP-8, 4004, RISC-V, PDP-8: registers start from the pixel bytes and are written back by $spill
    (local.set $i (i32.const 0))
    (block $se (loop $sl (br_if $se (i32.ge_u (local.get $i) (i32.load offset=92 (local.get $prm))))
      (call $step (local.get $kind))
      (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $sl)))
    (call $spill (local.get $kind))
    (local.set $i (i32.const 0))
    (block $ce (loop $cl
      (br_if $ce (i32.ge_u (local.get $i) (global.get $cw)))
      (local.set $c (i32.ne (i32.load8_u (i32.add (local.get $out) (local.get $i))) (i32.load8_u (i32.add (local.get $p) (local.get $i)))))
      (i32.store8 (i32.add (local.get $flags) (local.get $i)) (local.get $c))
      (local.set $changed (i32.add (local.get $changed) (local.get $c)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $cl)))
    (i32.store offset=48 (local.get $prm) (call $zr16 (i32.const 22)))
    (i32.or (i32.shl (i32.load offset=92 (local.get $prm)) (i32.const 8)) (local.get $changed)))

  ;; step(kind): one instruction of the core for kind 6..24 on the register file and the memory at $zp
  (func $step (param $kind i32)
    (block $done (block $b24 (block $b23 (block $b22 (block $b21 (block $b20 (block $b19 (block $b16 (block $b15 (block $b14 (block $b13 (block $b12 (block $b11 (block $b10 (block $b9 (block $b8 (block $b7 (block $b6
      (br_table $b6 $b7 $b8 $b9 $b10 $b11 $b12 $b13 $b14 $b15 $b16 $b16 $b16 $b19 $b20 $b21 $b22 $b23 $b24 $done (i32.sub (local.get $kind) (i32.const 6))))
      (call $zstep) (br $done))
      (call $m6502step) (br $done))
      (call $i8080step) (br $done))
      (call $subleq_step) (br $done))
      (call $chip8_step) (br $done))
      (call $i4004_step) (br $done))
      (call $sm83_step) (br $done))
      (call $i8051_step) (br $done))
      (call $m6809_step) (br $done))
      (call $riscv_step) (br $done))
      (br $done))   ;; 16..18 are not CPUs
      (call $pdp8_step) (br $done))
      (call $pdp11_step) (br $done))
      (call $m68k_step) (br $done))
      (call $u1101_step) (br $done))
      (call $vax_step) (br $done))
      (call $cdc6600_step)))

  ;; ---- links: one persistent CPU per pair of neighbouring pixels ----
  ;; The link between (x, y) and (x + 1, y) has index y * w + x, the link between (x, y) and (x, y + 1) index
  ;; w * h + y * w + x; each keeps a 128-byte copy of the register file at states + 128 * index.
  ;; links_reset(states, nlinks, kind): fresh registers for every link (nlinks = 4wh: two directed links a pair) (zero; the 6502 starts with P = 0x24, S = 0xFF).
  (func (export "links_reset") (param $states i32) (param $n i32) (param $kind i32)
    (local $i i32) (local $s i32)
    (block $e (loop $l (br_if $e (i32.ge_u (local.get $i) (local.get $n)))
      (local.set $s (i32.add (local.get $states) (i32.shl (local.get $i) (i32.const 7))))
      (memory.fill (local.get $s) (i32.const 0) (i32.const 128))
      (if (i32.eq (local.get $kind) (i32.const 7)) (then (i32.store8 offset=4 (local.get $s) (i32.const 0x24)) (i32.store8 offset=3 (local.get $s) (i32.const 0xFF))))
      (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $l))))
  ;; link_run(a, b, st, out, kind) -> pixels changed (0..2): one instruction of the machine whose memory is the
  ;; pixel at a followed by the pixel at b (addresses 0..15 and 16..31), registers restored from and saved to
  ;; the 128-byte state at st; the pixels are written back only when their bytes changed.
  (func $link_run (param $a i32) (param $b i32) (param $st i32) (param $out i32) (param $kind i32) (result i32)
    (local $a0 i64) (local $a1 i64) (local $b0 i64) (local $b1 i64) (local $changed i32)
    (local.set $a0 (i64.load (local.get $a))) (local.set $a1 (i64.load offset=8 (local.get $a)))
    (local.set $b0 (i64.load (local.get $b))) (local.set $b1 (i64.load offset=8 (local.get $b)))
    (i64.store (local.get $out) (local.get $a0)) (i64.store offset=8 (local.get $out) (local.get $a1))
    (i64.store offset=16 (local.get $out) (local.get $b0)) (i64.store offset=24 (local.get $out) (local.get $b1))
    (memory.copy (i32.const 256) (local.get $st) (i32.const 128))   ;; registers in
    (call $step (local.get $kind))
    (memory.copy (local.get $st) (i32.const 256) (i32.const 128))   ;; registers out
    (if (i32.or (i64.ne (local.get $a0) (i64.load (local.get $out))) (i64.ne (local.get $a1) (i64.load offset=8 (local.get $out)))) (then
      (i64.store (local.get $a) (i64.load (local.get $out))) (i64.store offset=8 (local.get $a) (i64.load offset=8 (local.get $out)))
      (local.set $changed (i32.const 1))))
    (if (i32.or (i64.ne (local.get $b0) (i64.load offset=16 (local.get $out))) (i64.ne (local.get $b1) (i64.load offset=24 (local.get $out)))) (then
      (i64.store (local.get $b) (i64.load offset=16 (local.get $out))) (i64.store offset=8 (local.get $b) (i64.load offset=24 (local.get $out)))
      (local.set $changed (i32.add (local.get $changed) (i32.const 1)))))
    (local.get $changed))

  ;; links(w, h, grid, prm, phase, states): every pair of one phase (0 left-right from even x, 1 up-down from even y,
  ;; 2 left-right from odd x, 3 up-down from odd y, the swap phases' numbering) carries two directed links, each with
  ;; a CPU (kind prm.changer) of its own: the forward link sees the first pixel (left or top) at addresses 0..15 and
  ;; the second at 16..31, the backward link the other way round. Each runs one instruction, forward first, and the
  ;; backward machine sees what the forward one wrote. Pair index p: y * w + x for the pair (x, y)-(x+1, y),
  ;; w * h + y * w + x for (x, y)-(x, y+1); the forward link's state is at states + 128 * 2p, the backward link's at
  ;; states + 128 * (2p + 1). Returns the number of pixel writes.
  (func (export "links") (param $w i32) (param $h i32) (param $grid i32) (param $prm i32) (param $phase i32) (param $states i32) (result i32)
    (local $kind i32) (local $out i32) (local $x i32) (local $y i32) (local $a i32) (local $b i32) (local $st i32) (local $changed i32)
    (local $vert i32) (local $step i32)
    (local.set $kind (i32.load offset=72 (local.get $prm)))
    (if (i32.or (i32.lt_u (local.get $kind) (i32.const 6)) (i32.or (i32.gt_u (local.get $kind) (i32.const 24))
        (i32.and (i32.ge_u (local.get $kind) (i32.const 16)) (i32.le_u (local.get $kind) (i32.const 18))))) (then (return (i32.const 0))))
    (local.set $out (i32.load (local.get $prm)))
    (local.set $vert (i32.and (local.get $phase) (i32.const 1)))
    (local.set $step (i32.shr_u (local.get $phase) (i32.const 1)))   ;; the parity of the first pixel's x (or y)
    (global.set $zp (local.get $out))
    (global.set $cw (i32.const 32))
    (local.set $y (select (local.get $step) (i32.const 0) (local.get $vert)))
    (block $ye (loop $yl (br_if $ye (i32.ge_u (local.get $y) (local.get $h)))
      (local.set $x (select (i32.const 0) (local.get $step) (local.get $vert)))
      (block $xe (loop $xl (br_if $xe (i32.ge_u (local.get $x) (local.get $w)))
        (if (local.get $vert)
          (then (br_if $xe (i32.ge_u (i32.add (local.get $y) (i32.const 1)) (local.get $h)))
                (local.set $b (i32.add (local.get $grid) (i32.shl (i32.add (i32.mul (i32.add (local.get $y) (i32.const 1)) (local.get $w)) (local.get $x)) (i32.const 4))))
                (local.set $st (i32.add (local.get $states) (i32.shl (i32.add (i32.mul (local.get $w) (local.get $h)) (i32.add (i32.mul (local.get $y) (local.get $w)) (local.get $x))) (i32.const 8)))))
          (else (br_if $xe (i32.ge_u (i32.add (local.get $x) (i32.const 1)) (local.get $w)))
                (local.set $b (i32.add (local.get $grid) (i32.shl (i32.add (i32.mul (local.get $y) (local.get $w)) (i32.add (local.get $x) (i32.const 1))) (i32.const 4))))
                (local.set $st (i32.add (local.get $states) (i32.shl (i32.add (i32.mul (local.get $y) (local.get $w)) (local.get $x)) (i32.const 8))))))
        (local.set $a (i32.add (local.get $grid) (i32.shl (i32.add (i32.mul (local.get $y) (local.get $w)) (local.get $x)) (i32.const 4))))
        (local.set $changed (i32.add (local.get $changed) (call $link_run (local.get $a) (local.get $b) (local.get $st) (local.get $out) (local.get $kind))))
        (local.set $changed (i32.add (local.get $changed) (call $link_run (local.get $b) (local.get $a) (i32.add (local.get $st) (i32.const 128)) (local.get $out) (local.get $kind))))
        (local.set $x (i32.add (local.get $x) (select (i32.const 1) (i32.const 2) (local.get $vert)))) (br $xl)))
      (local.set $y (i32.add (local.get $y) (select (i32.const 2) (i32.const 1) (local.get $vert)))) (br $yl)))
    (global.set $cw (i32.const 16))
    (local.get $changed))

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
