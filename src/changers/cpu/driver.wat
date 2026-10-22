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
    (if (i32.eqz (local.get $kind)) (then (call $lz_step) (return)))   ;; 0: the LZ decompressor, one copy command a step
    (if (i32.eq (local.get $kind) (i32.const 25)) (then (global.set $m20 (i32.const 1)) (call $m68k_step) (global.set $m20 (i32.const 0)) (return)))   ;; 25: the 68000 core as a 68020
    (if (i32.and (i32.ge_u (local.get $kind) (i32.const 26)) (i32.le_u (local.get $kind) (i32.const 28))) (then (global.set $xm (i32.sub (local.get $kind) (i32.const 26))) (call $x86_step) (return)))   ;; 26..28: 8086, 80286, 80386
    (if (i32.eq (local.get $kind) (i32.const 29)) (then (call $i860_step) (return)))
    (if (i32.eq (local.get $kind) (i32.const 30)) (then (call $pic1640_step) (return)))
    (if (i32.eq (local.get $kind) (i32.const 43)) (then (call $alpha_step) (return)))   ;; 43: DEC Alpha 21064
    (if (i32.eq (local.get $kind) (i32.const 44)) (then (call $parisc_step) (return)))   ;; 44: HP PA-RISC
    (if (i32.eq (local.get $kind) (i32.const 47)) (then (call $redcode_step) (return)))   ;; 47: Redcode
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
  ;; link_run(a, b, st, out, kind, mode) -> pixels changed (0..2): one instruction of the machine whose 32-byte memory
  ;; is the pixel at a joined with the pixel at b by joining `mode` ($join in decode.wat: 1 concatenated, a first;
  ;; 2 bit-interleaved, a on the even bits; 3 nibble-interleaved, a on the low nibbles; 5 byte-interleaved), registers restored from
  ;; and saved to the 128-byte state at st; the joint cell is split back and a pixel counts as written when a byte
  ;; of it changed.
  ;; links_snapshot(d): the machines read their two pixels from the copy d bytes away (the snapshot of the round, taken by
  ;; the host before the round's first phase) and write only the bytes they change to the live pixels, so every machine
  ;; of a round sees the state before the round and the order of the phases and of a pair's two machines matters only
  ;; where two machines write the same byte. d = 0 reads the live pixels (every machine sees the writes before it).
  (global $lsnap (mut i32) (i32.const 0))
  (func (export "links_snapshot") (param $d i32) (global.set $lsnap (local.get $d)))
  ;; link_run(a, b, st, out, kind, mode) -> pixels changed (0..2): one instruction of the machine whose state is at st, on
  ;; the joint cell of the pixels at a (first role) and b, read from the snapshot; the result is split to out + 32 and
  ;; out + 48, and the bytes that differ from the snapshot are stored to the live pixels
  (func $link_run (param $a i32) (param $b i32) (param $st i32) (param $out i32) (param $kind i32) (param $mode i32) (result i32)
    (local $d i32) (local $k i32) (local $ca i32) (local $cb i32) (local $v i32)
    (local.set $d (global.get $lsnap))
    (call $join (i32.add (local.get $a) (local.get $d)) (i32.add (local.get $b) (local.get $d)) (local.get $out) (local.get $mode) (i32.const 0))
    (memory.copy (i32.const 256) (local.get $st) (i32.const 128))   ;; registers in
    (call $step (local.get $kind))
    (memory.copy (local.get $st) (i32.const 256) (i32.const 128))   ;; registers out
    (call $split (local.get $out) (i32.add (local.get $out) (i32.const 32)) (i32.add (local.get $out) (i32.const 48)) (local.get $mode) (i32.const 0))
    (block $e (loop $l (br_if $e (i32.ge_u (local.get $k) (i32.const 16)))
      (local.set $v (i32.load8_u offset=32 (i32.add (local.get $out) (local.get $k))))
      (if (i32.ne (local.get $v) (i32.load8_u (i32.add (i32.add (local.get $a) (local.get $d)) (local.get $k))))
        (then (i32.store8 (i32.add (local.get $a) (local.get $k)) (local.get $v)) (local.set $ca (i32.const 1))))
      (local.set $v (i32.load8_u offset=48 (i32.add (local.get $out) (local.get $k))))
      (if (i32.ne (local.get $v) (i32.load8_u (i32.add (i32.add (local.get $b) (local.get $d)) (local.get $k))))
        (then (i32.store8 (i32.add (local.get $b) (local.get $k)) (local.get $v)) (local.set $cb (i32.const 1))))
      (local.set $k (i32.add (local.get $k) (i32.const 1))) (br $l)))
    (i32.add (local.get $ca) (local.get $cb)))

  ;; links_zone(w, grid, gy0, prm, phase, hst, r0h, vst, r0v, a, b) -> pixel writes. The pairs of one phase (0 left-right
  ;; from even x, 1 up-down from even y, 2 left-right from odd x, 3 up-down from odd y, the swap phases' numbering)
  ;; whose first row is a local row in [a, b); grid points at local row 0, which is global row gy0 (the parity of an
  ;; up-down pair's first row is global), and an up-down pair also needs its second row inside [a, b). Every pair
  ;; carries two directed links, each with a CPU (kind prm.changer) of its own: the forward link sees the first pixel
  ;; (left or top) at addresses 0..15 and the second at 16..31, the backward link the other way round. Each runs one
  ;; instruction, both on the round's snapshot when the host has set one (links_snapshot), writing its changed bytes. The states (128 bytes a
  ;; machine, forward then backward) of the left-right pair (x, r) are at hst + 256 ((r - r0h) w + x), those of the
  ;; up-down pair (x, r)-(x, r+1) at vst + 256 ((r - r0v) w + x). The two pixels are joined into the machine's memory
  ;; by prm.pairMode (0 counts as 1, concatenated), the forward machine's own pixel in the first role.
  (func $links_zone (export "links_zone") (param $w i32) (param $grid i32) (param $gy0 i32) (param $prm i32) (param $phase i32) (param $hst i32) (param $r0h i32) (param $vst i32) (param $r0v i32) (param $a i32) (param $b i32) (result i32)
    (local $kind i32) (local $out i32) (local $x i32) (local $r i32) (local $p i32) (local $q i32) (local $st i32) (local $changed i32)
    (local $vert i32) (local $off i32) (local $row i32) (local $stride i32) (local $mode i32)
    (local.set $kind (i32.load offset=72 (local.get $prm)))
    (local.set $mode (i32.load offset=104 (local.get $prm)))
    (if (i32.eqz (local.get $mode)) (then (local.set $mode (i32.const 1))))
    (if (i32.or (i32.and (i32.ge_u (local.get $kind) (i32.const 1)) (i32.lt_u (local.get $kind) (i32.const 6))) (i32.or (i32.and (i32.and (i32.gt_u (local.get $kind) (i32.const 30)) (i32.or (i32.lt_u (local.get $kind) (i32.const 43)) (i32.gt_u (local.get $kind) (i32.const 44)))) (i32.ne (local.get $kind) (i32.const 47)))
        (i32.and (i32.ge_u (local.get $kind) (i32.const 16)) (i32.le_u (local.get $kind) (i32.const 18))))) (then (return (i32.const 0))))
    (local.set $out (i32.load (local.get $prm)))
    (global.set $prmg (local.get $prm))
    (local.set $vert (i32.and (local.get $phase) (i32.const 1)))
    (local.set $off (i32.shr_u (local.get $phase) (i32.const 1)))
    (local.set $stride (i32.shl (local.get $w) (i32.const 4)))
    (global.set $zp (local.get $out))
    (global.set $cw (i32.const 32))
    (local.set $r (local.get $a))
    (block $re (loop $rl (br_if $re (i32.ge_s (local.get $r) (local.get $b)))
      (local.set $row (i32.add (local.get $grid) (i32.mul (local.get $r) (local.get $stride))))
      (if (local.get $vert)
        (then
          (if (i32.and (i32.eq (i32.and (i32.add (local.get $gy0) (local.get $r)) (i32.const 1)) (local.get $off))
                       (i32.lt_s (i32.add (local.get $r) (i32.const 1)) (local.get $b))) (then
            (local.set $x (i32.const 0))
            (block $xe (loop $xl (br_if $xe (i32.ge_u (local.get $x) (local.get $w)))
              (local.set $p (i32.add (local.get $row) (i32.shl (local.get $x) (i32.const 4))))
              (local.set $q (i32.add (local.get $p) (local.get $stride)))
              (local.set $st (i32.add (local.get $vst) (i32.shl (i32.add (i32.mul (i32.sub (local.get $r) (local.get $r0v)) (local.get $w)) (local.get $x)) (i32.const 8))))
              (local.set $changed (i32.add (local.get $changed) (call $link_run (local.get $p) (local.get $q) (local.get $st) (local.get $out) (local.get $kind) (local.get $mode))))
              (local.set $changed (i32.add (local.get $changed) (call $link_run (local.get $q) (local.get $p) (i32.add (local.get $st) (i32.const 128)) (local.get $out) (local.get $kind) (local.get $mode))))
              (local.set $x (i32.add (local.get $x) (i32.const 1))) (br $xl))))))
        (else
          (local.set $x (local.get $off))
          (block $xe2 (loop $xl2 (br_if $xe2 (i32.ge_u (i32.add (local.get $x) (i32.const 1)) (local.get $w)))
            (local.set $p (i32.add (local.get $row) (i32.shl (local.get $x) (i32.const 4))))
            (local.set $q (i32.add (local.get $p) (i32.const 16)))
            (local.set $st (i32.add (local.get $hst) (i32.shl (i32.add (i32.mul (i32.sub (local.get $r) (local.get $r0h)) (local.get $w)) (local.get $x)) (i32.const 8))))
            (local.set $changed (i32.add (local.get $changed) (call $link_run (local.get $p) (local.get $q) (local.get $st) (local.get $out) (local.get $kind) (local.get $mode))))
            (local.set $changed (i32.add (local.get $changed) (call $link_run (local.get $q) (local.get $p) (i32.add (local.get $st) (i32.const 128)) (local.get $out) (local.get $kind) (local.get $mode))))
            (local.set $x (i32.add (local.get $x) (i32.const 2))) (br $xl2)))))
      (local.set $r (i32.add (local.get $r) (i32.const 1))) (br $rl)))
    (global.set $cw (i32.const 16))
    (local.get $changed))

  ;; links(w, h, grid, prm, phase, states): the whole grid as one zone. Pair index p: y * w + x for the pair
  ;; (x, y)-(x+1, y), w * h + y * w + x for (x, y)-(x, y+1); the forward link's state is at states + 128 * 2p, the
  ;; backward link's at states + 128 * (2p + 1).
  (func (export "links") (param $w i32) (param $h i32) (param $grid i32) (param $prm i32) (param $phase i32) (param $states i32) (result i32)
    (call $links_zone (local.get $w) (local.get $grid) (i32.const 0) (local.get $prm) (local.get $phase)
      (local.get $states) (i32.const 0) (i32.add (local.get $states) (i32.shl (i32.mul (local.get $w) (local.get $h)) (i32.const 8))) (i32.const 0)
      (i32.const 0) (local.get $h)))

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
