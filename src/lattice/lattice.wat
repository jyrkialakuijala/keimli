;; Keimli: the bit swap lattice, its byte changers and its renderer, in hand-written WebAssembly.
;;
;; Every pixel is a 128-bit string (two little-endian i64 words, 16 bytes). The module is assembled
;; by build.sh from the parts under src/ in this order: lattice (swap phases, bit-plane smoothing,
;; grid utilities), changers (the decode entry point with the LZ decoder, Brainfuck, the simple
;; transforms, the DCT), render (views, render buffer, sharpening) and the CPU cores. The host
;; (src/changers/codec.js) writes the code tables, the dictionary and a parameter block into memory
;; before calling in; src/lattice/band.js drives a turn.

  (memory (export "memory") 64)

  ;; ------------------------------------------------------------------------
  ;; ctx(s0, s1, i): the 32 bits neighbouring position i of the 128-bit ring (16 below,
  ;; 16 above, position i itself excluded). Branchless 128-bit rotate, then pick.
  (func $ctx (param $s0 i64) (param $s1 i64) (param $i i32) (result i64)
    (local $k i32) (local $lo i64) (local $hi i64) (local $sh i64) (local $win i64)
    (local.set $k (i32.and (i32.add (local.get $i) (i32.const 112)) (i32.const 127)))
    (local.set $lo (select (local.get $s0) (local.get $s1) (i32.lt_u (local.get $k) (i32.const 64))))
    (local.set $hi (select (local.get $s1) (local.get $s0) (i32.lt_u (local.get $k) (i32.const 64))))
    (local.set $sh (i64.extend_i32_u (i32.and (local.get $k) (i32.const 63))))
    (local.set $win (i64.or (i64.shr_u (local.get $lo) (local.get $sh))
                            (i64.shl (i64.shl (local.get $hi) (i64.sub (i64.const 63) (local.get $sh))) (i64.const 1))))
    (i64.or (i64.and (local.get $win) (i64.const 0xffff))
            (i64.shl (i64.and (i64.shr_u (local.get $win) (i64.const 17)) (i64.const 0xffff)) (i64.const 16))))

  ;; mix64(x): splitmix64 finaliser, one pixel's context -> 64-bit hash
  (func $mix64 (param $x i64) (result i64)
    (local.set $x (i64.add (local.get $x) (i64.const 0x9E3779B97F4A7C15)))
    (local.set $x (i64.mul (i64.xor (local.get $x) (i64.shr_u (local.get $x) (i64.const 30))) (i64.const 0xBF58476D1CE4E5B9)))
    (local.set $x (i64.mul (i64.xor (local.get $x) (i64.shr_u (local.get $x) (i64.const 27))) (i64.const 0x94D049BB133111EB)))
    (i64.xor (local.get $x) (i64.shr_u (local.get $x) (i64.const 31))))

  ;; pair(p, q, d, thr, salt) -> 1 if a bit was exchanged between pixels p and q.
  ;; The decision is taken on the snapshot copies of the two pixels at p + d and q + d
  ;; (d = 0 decides on the live pixels): it walks only the positions where the snapshot
  ;; pixels differ and at each, hash(context of p) + hash(context of q) + salt (mod 2^64)
  ;; decides, independent of pixel order; the first position below thr is the decision.
  ;; The exchange is then applied to the live pixels: if they still differ there, the bit
  ;; is swapped (returns 1); if an earlier phase already moved it, nothing happens (0).
  ;; thr = 0 never swaps and thr = 2^64-1 always picks the lowest differing bit, both
  ;; without hashing.
  (func $pair (param $p i32) (param $q i32) (param $d i32) (param $thr i64) (param $salt i64) (result i32)
    (local $a0 i64) (local $a1 i64) (local $b0 i64) (local $b1 i64) (local $x i64) (local $i i32) (local $mask i64) (local $always i32)
    (local $la i64) (local $lb i64)
    (if (i64.eqz (local.get $thr)) (then (return (i32.const 0))))
    (local.set $always (i64.eq (local.get $thr) (i64.const -1)))
    (local.set $a0 (i64.load (i32.add (local.get $p) (local.get $d)))) (local.set $a1 (i64.load offset=8 (i32.add (local.get $p) (local.get $d))))
    (local.set $b0 (i64.load (i32.add (local.get $q) (local.get $d)))) (local.set $b1 (i64.load offset=8 (i32.add (local.get $q) (local.get $d))))
    (local.set $x (i64.xor (local.get $a0) (local.get $b0)))
    (block $lo (loop $l0
      (br_if $lo (i64.eqz (local.get $x)))
      (local.set $i (i32.wrap_i64 (i64.ctz (local.get $x))))
      (if (i32.or (local.get $always) (i64.lt_u (i64.add (local.get $salt) (i64.add
            (call $mix64 (call $ctx (local.get $a0) (local.get $a1) (local.get $i)))
            (call $mix64 (call $ctx (local.get $b0) (local.get $b1) (local.get $i)))))
          (local.get $thr)))
        (then
          (local.set $mask (i64.shl (i64.const 1) (i64.extend_i32_u (local.get $i))))
          (local.set $la (i64.load (local.get $p))) (local.set $lb (i64.load (local.get $q)))
          (if (i64.eqz (i64.and (i64.xor (local.get $la) (local.get $lb)) (local.get $mask))) (then (return (i32.const 0))))
          (i64.store (local.get $p) (i64.xor (local.get $la) (local.get $mask)))
          (i64.store (local.get $q) (i64.xor (local.get $lb) (local.get $mask)))
          (return (i32.const 1))))
      (local.set $x (i64.and (local.get $x) (i64.sub (local.get $x) (i64.const 1))))
      (br $l0)))
    (local.set $x (i64.xor (local.get $a1) (local.get $b1)))
    (block $hi (loop $l1
      (br_if $hi (i64.eqz (local.get $x)))
      (local.set $i (i32.wrap_i64 (i64.ctz (local.get $x))))
      (if (i32.or (local.get $always) (i64.lt_u (i64.add (local.get $salt) (i64.add
            (call $mix64 (call $ctx (local.get $a0) (local.get $a1) (i32.add (local.get $i) (i32.const 64))))
            (call $mix64 (call $ctx (local.get $b0) (local.get $b1) (i32.add (local.get $i) (i32.const 64))))))
          (local.get $thr)))
        (then
          (local.set $mask (i64.shl (i64.const 1) (i64.extend_i32_u (local.get $i))))
          (local.set $la (i64.load offset=8 (local.get $p))) (local.set $lb (i64.load offset=8 (local.get $q)))
          (if (i64.eqz (i64.and (i64.xor (local.get $la) (local.get $lb)) (local.get $mask))) (then (return (i32.const 0))))
          (i64.store offset=8 (local.get $p) (i64.xor (local.get $la) (local.get $mask)))
          (i64.store offset=8 (local.get $q) (i64.xor (local.get $lb) (local.get $mask)))
          (return (i32.const 1))))
      (local.set $x (i64.and (local.get $x) (i64.sub (local.get $x) (i64.const 1))))
      (br $l1)))
    (i32.const 0))

  ;; row_pairs(row, w, x0, thrTab, d, salt) -> bits exchanged: the horizontal pairs (x, x+1), x = x0, x0+2, ...
  ;; of the row at address row, each under the column threshold thrTab[x]
  (func $row_pairs (param $row i32) (param $w i32) (param $x i32) (param $thrTab i32) (param $d i32) (param $salt i64) (result i32)
    (local $swaps i32)
    (block $xe (loop $xl (br_if $xe (i32.ge_u (i32.add (local.get $x) (i32.const 1)) (local.get $w)))
      (local.set $swaps (i32.add (local.get $swaps) (call $pair
        (i32.add (local.get $row) (i32.shl (local.get $x) (i32.const 4)))
        (i32.add (local.get $row) (i32.shl (i32.add (local.get $x) (i32.const 1)) (i32.const 4)))
        (local.get $d)
        (i64.load (i32.add (local.get $thrTab) (i32.shl (local.get $x) (i32.const 3)))) (local.get $salt))))
      (local.set $x (i32.add (local.get $x) (i32.const 2))) (br $xl)))
    (local.get $swaps))

  ;; col_pairs(grid, stride, x, gy0, h, a, b, ca, cb, par, thrTab, d, salt) -> bits exchanged in rows [ca, cb):
  ;; the vertical pairs (r, r+1) of column x whose first row has global parity par, with both rows inside
  ;; [a, b) and the grid, under the column threshold thrTab[x]
  (func $col_pairs (param $grid i32) (param $stride i32) (param $x i32) (param $gy0 i32) (param $h i32) (param $a i32) (param $b i32) (param $ca i32) (param $cb i32) (param $par i32) (param $thrTab i32) (param $d i32) (param $salt i64) (result i32)
    (local $r i32) (local $swaps i32) (local $p i32) (local $thr i64)
    (local.set $thr (i64.load (i32.add (local.get $thrTab) (i32.shl (local.get $x) (i32.const 3)))))
    (local.set $r (local.get $a))
    (if (i32.ne (i32.and (i32.add (local.get $gy0) (local.get $r)) (i32.const 1)) (local.get $par))
      (then (local.set $r (i32.add (local.get $r) (i32.const 1)))))
    (block $ye (loop $yl (br_if $ye (i32.ge_s (i32.add (local.get $r) (i32.const 1)) (local.get $b)))
      (br_if $ye (i32.ge_s (i32.add (i32.add (local.get $gy0) (local.get $r)) (i32.const 1)) (local.get $h)))
      (local.set $p (i32.add (i32.add (local.get $grid) (i32.mul (local.get $r) (local.get $stride))) (i32.shl (local.get $x) (i32.const 4))))
      (local.set $swaps (i32.add (local.get $swaps) (i32.mul
        (i32.and (i32.ge_s (local.get $r) (local.get $ca)) (i32.lt_s (local.get $r) (local.get $cb)))
        (call $pair (local.get $p) (i32.add (local.get $p) (local.get $stride)) (local.get $d) (local.get $thr) (local.get $salt)))))
      (local.set $r (i32.add (local.get $r) (i32.const 2))) (br $yl)))
    (local.get $swaps))

  ;; leftover(n, off): does the brick pattern of pairs (off, off+1), (off+2, off+3), ... over n pixels leave the
  ;; first pixel (off = 1) or the last pixel (n - 1 - off even) without a partner? Returns bit 0 for the first
  ;; pixel, bit 1 for the last.
  (func $leftover (param $n i32) (param $off i32) (result i32)
    (i32.or (local.get $off)
      (i32.shl (i32.eqz (i32.and (i32.sub (i32.sub (local.get $n) (i32.const 1)) (local.get $off)) (i32.const 1))) (i32.const 1))))

  ;; mix_zone(w, grid, snap, phase, alt, thrTab, gy0, h, a, b, ca, cb, salt) -> bits exchanged in rows [ca, cb)
  ;; snap is a copy of the grid buffer (same layout) taken before the turn's first phase: every
  ;; decision of the turn is read from it, and the exchanges are applied to grid (snap = grid
  ;; decides on the live pixels).
  ;; (pairs with first row in [a, b) are processed, only those with first row in [ca, cb) are counted).
  ;; grid points at local row 0, which is global row gy0 (may be negative for a band
  ;; buffer whose halo reaches above the grid; such rows are never inside [a, b)).
  ;; Pairs whose first row lies in [a, b) are processed; the grid is a plane with
  ;; edges: left-right pairs never cross a row end, and up-down pairs need both rows
  ;; inside [a, b) and inside the grid. phase: 0 LR even, 1 UD even, 2 LR odd, 3 UD odd.
  ;; The brick pattern of a phase leaves an edge column (left-right phases) or an edge row (up-down
  ;; phases) without partners: the left column when the offset is 1, the right column when w - 1 - off
  ;; is even, and likewise the top and bottom rows. Those pixels pair along their edge instead, up and
  ;; down in a left-right phase and left and right in an up-down phase, with the brick offset alt (0 or 1,
  ;; the host alternates it by turn), so that every pixel takes part in the same number of exchanges.
  (func $mix_zone (export "mix_zone") (param $w i32) (param $grid i32) (param $snap i32) (param $phase i32) (param $alt i32) (param $thrTab i32) (param $gy0 i32) (param $h i32) (param $a i32) (param $b i32) (param $ca i32) (param $cb i32) (param $salt i64) (result i32)
    (local $x i32) (local $r i32) (local $row i32) (local $swaps i32) (local $off i32) (local $stride i32) (local $inc i32) (local $d i32) (local $left i32)
    (local.set $d (i32.sub (local.get $snap) (local.get $grid)))
    (local.set $salt (i64.mul (local.get $salt) (i64.const 0x9E3779B97F4A7C15)))
    (local.set $off (i32.and (i32.shr_u (local.get $phase) (i32.const 1)) (i32.const 1)))
    (local.set $stride (i32.shl (local.get $w) (i32.const 4)))
    (local.set $r (local.get $a))
    (if (i32.eqz (i32.and (local.get $phase) (i32.const 1)))
      (then
        (block $ye (loop $yl (br_if $ye (i32.ge_s (local.get $r) (local.get $b)))
          (local.set $row (i32.add (local.get $grid) (i32.mul (local.get $r) (local.get $stride))))
          (local.set $inc (i32.and (i32.ge_s (local.get $r) (local.get $ca)) (i32.lt_s (local.get $r) (local.get $cb))))
          (local.set $swaps (i32.add (local.get $swaps) (i32.mul (local.get $inc)
            (call $row_pairs (local.get $row) (local.get $w) (local.get $off) (local.get $thrTab) (local.get $d) (local.get $salt)))))
          (local.set $r (i32.add (local.get $r) (i32.const 1))) (br $yl)))
        ;; the leftover columns pair up and down with offset alt
        (local.set $left (call $leftover (local.get $w) (local.get $off)))
        (if (i32.and (local.get $left) (i32.const 1)) (then
          (local.set $swaps (i32.add (local.get $swaps) (call $col_pairs (local.get $grid) (local.get $stride) (i32.const 0) (local.get $gy0) (local.get $h)
            (local.get $a) (local.get $b) (local.get $ca) (local.get $cb) (local.get $alt) (local.get $thrTab) (local.get $d) (local.get $salt))))))
        (if (i32.and (local.get $left) (i32.const 2)) (then
          (local.set $swaps (i32.add (local.get $swaps) (call $col_pairs (local.get $grid) (local.get $stride) (i32.sub (local.get $w) (i32.const 1)) (local.get $gy0) (local.get $h)
            (local.get $a) (local.get $b) (local.get $ca) (local.get $cb) (local.get $alt) (local.get $thrTab) (local.get $d) (local.get $salt)))))))
      (else
        ;; first rows of pairs have global parity == off; the partner row r+1 must be inside [a, b) and the grid
        (block $ye2 (loop $yl2 (br_if $ye2 (i32.ge_s (i32.add (local.get $r) (i32.const 1)) (local.get $b)))
          (if (i32.and (i32.eq (i32.and (i32.add (local.get $gy0) (local.get $r)) (i32.const 1)) (local.get $off))
                       (i32.lt_s (i32.add (i32.add (local.get $gy0) (local.get $r)) (i32.const 1)) (local.get $h))) (then
            (local.set $row (i32.add (local.get $grid) (i32.mul (local.get $r) (local.get $stride))))
            (local.set $inc (i32.and (i32.ge_s (local.get $r) (local.get $ca)) (i32.lt_s (local.get $r) (local.get $cb))))
            (local.set $x (i32.const 0))
            (block $xe2 (loop $xl2 (br_if $xe2 (i32.ge_u (local.get $x) (local.get $w)))
              (local.set $swaps (i32.add (local.get $swaps) (i32.mul (local.get $inc) (call $pair
                (i32.add (local.get $row) (i32.shl (local.get $x) (i32.const 4)))
                (i32.add (i32.add (local.get $row) (local.get $stride)) (i32.shl (local.get $x) (i32.const 4)))
                (local.get $d)
                (i64.load (i32.add (local.get $thrTab) (i32.shl (local.get $x) (i32.const 3)))) (local.get $salt)))))
              (local.set $x (i32.add (local.get $x) (i32.const 1))) (br $xl2)))))
          (local.set $r (i32.add (local.get $r) (i32.const 1))) (br $yl2)))
        ;; the leftover rows (global 0 and h-1, when inside the zone) pair left and right with offset alt
        (local.set $left (call $leftover (local.get $h) (local.get $off)))
        (local.set $r (i32.sub (i32.const 0) (local.get $gy0)))
        (if (i32.and (i32.and (local.get $left) (i32.const 1)) (i32.and (i32.ge_s (local.get $r) (local.get $a)) (i32.lt_s (local.get $r) (local.get $b)))) (then
          (local.set $swaps (i32.add (local.get $swaps) (i32.mul
            (i32.and (i32.ge_s (local.get $r) (local.get $ca)) (i32.lt_s (local.get $r) (local.get $cb)))
            (call $row_pairs (i32.add (local.get $grid) (i32.mul (local.get $r) (local.get $stride))) (local.get $w) (local.get $alt) (local.get $thrTab) (local.get $d) (local.get $salt)))))))
        (local.set $r (i32.sub (i32.sub (local.get $h) (i32.const 1)) (local.get $gy0)))
        (if (i32.and (i32.shr_u (local.get $left) (i32.const 1)) (i32.and (i32.ge_s (local.get $r) (local.get $a)) (i32.lt_s (local.get $r) (local.get $b)))) (then
          (local.set $swaps (i32.add (local.get $swaps) (i32.mul
            (i32.and (i32.ge_s (local.get $r) (local.get $ca)) (i32.lt_s (local.get $r) (local.get $cb)))
            (call $row_pairs (i32.add (local.get $grid) (i32.mul (local.get $r) (local.get $stride))) (local.get $w) (local.get $alt) (local.get $thrTab) (local.get $d) (local.get $salt)))))))))
    (local.get $swaps))

  ;; mix(w, h, grid, phase, alt, thrTab, salt): the whole grid as one zone, deciding on the live pixels
  (func (export "mix") (param $w i32) (param $h i32) (param $grid i32) (param $phase i32) (param $alt i32) (param $thrTab i32) (param $salt i64) (result i32)
    (call $mix_zone (local.get $w) (local.get $grid) (local.get $grid) (local.get $phase) (local.get $alt) (local.get $thrTab) (i32.const 0) (local.get $h) (i32.const 0) (local.get $h) (i32.const 0) (local.get $h) (local.get $salt)))
  ;; mix_from(w, h, grid, snap, phase, alt, thrTab, salt): the whole grid as one zone, deciding on the snapshot at snap
  (func (export "mix_from") (param $w i32) (param $h i32) (param $grid i32) (param $snap i32) (param $phase i32) (param $alt i32) (param $thrTab i32) (param $salt i64) (result i32)
    (call $mix_zone (local.get $w) (local.get $grid) (local.get $snap) (local.get $phase) (local.get $alt) (local.get $thrTab) (i32.const 0) (local.get $h) (i32.const 0) (local.get $h) (i32.const 0) (local.get $h) (local.get $salt)))

  ;; majority(src, o, x, w, g, h, stride, nbr, off): bitwise majority over a neighbourhood of
  ;; the pixel at src + o (column x, global row g; off = 0 or 8 selects the i64 half).
  ;; nbr 0: the pixel and its 4-connected neighbours (5 votes, at least 3 set);
  ;; nbr 1: the 3x3 block (9 votes, at least 5); nbr 2: the 5x5 block (25 votes, at least 13).
  ;; Coordinates are clamped to the grid, so a missing neighbour at an edge counts as the
  ;; nearest pixel (the pixel itself for the immediate neighbours). Bit-sliced counter.
  (func $majority (param $src i32) (param $o i32) (param $x i32) (param $w i32) (param $g i32) (param $h i32) (param $stride i32) (param $nbr i32) (param $off i32) (result i64)
    (local $c0 i64) (local $c1 i64) (local $c2 i64) (local $c3 i64) (local $c4 i64) (local $v i64) (local $t i64)
    (local $r i32) (local $dy i32) (local $dx i32) (local $yy i32) (local $xx i32) (local $rowo i32)
    (local.set $r (select (i32.const 1) (local.get $nbr) (i32.eqz (local.get $nbr))))
    (local.set $dy (i32.sub (i32.const 0) (local.get $r)))
    (block $ye (loop $yl (br_if $ye (i32.gt_s (local.get $dy) (local.get $r)))
      (local.set $yy (i32.add (local.get $g) (local.get $dy)))
      (local.set $yy (select (i32.const 0) (local.get $yy) (i32.lt_s (local.get $yy) (i32.const 0))))
      (local.set $yy (select (i32.sub (local.get $h) (i32.const 1)) (local.get $yy) (i32.ge_s (local.get $yy) (local.get $h))))
      (local.set $rowo (i32.add (i32.add (local.get $src) (local.get $off)) (i32.add (local.get $o) (i32.mul (i32.sub (local.get $yy) (local.get $g)) (local.get $stride)))))
      (local.set $dx (i32.sub (i32.const 0) (local.get $r)))
      (block $xe (loop $xl (br_if $xe (i32.gt_s (local.get $dx) (local.get $r)))
        (if (i32.or (local.get $nbr) (i32.or (i32.eqz (local.get $dx)) (i32.eqz (local.get $dy)))) (then   ;; nbr 0: cross only
          (local.set $xx (i32.add (local.get $x) (local.get $dx)))
          (local.set $xx (select (i32.const 0) (local.get $xx) (i32.lt_s (local.get $xx) (i32.const 0))))
          (local.set $xx (select (i32.sub (local.get $w) (i32.const 1)) (local.get $xx) (i32.ge_s (local.get $xx) (local.get $w))))
          (local.set $v (i64.load (i32.add (local.get $rowo) (i32.shl (i32.sub (local.get $xx) (local.get $x)) (i32.const 4)))))
          (local.set $t (i64.and (local.get $c0) (local.get $v))) (local.set $c0 (i64.xor (local.get $c0) (local.get $v))) (local.set $v (local.get $t))
          (local.set $t (i64.and (local.get $c1) (local.get $v))) (local.set $c1 (i64.xor (local.get $c1) (local.get $v))) (local.set $v (local.get $t))
          (local.set $t (i64.and (local.get $c2) (local.get $v))) (local.set $c2 (i64.xor (local.get $c2) (local.get $v))) (local.set $v (local.get $t))
          (local.set $t (i64.and (local.get $c3) (local.get $v))) (local.set $c3 (i64.xor (local.get $c3) (local.get $v))) (local.set $v (local.get $t))
          (local.set $c4 (i64.xor (local.get $c4) (local.get $v)))))
        (local.set $dx (i32.add (local.get $dx) (i32.const 1))) (br $xl)))
      (local.set $dy (i32.add (local.get $dy) (i32.const 1))) (br $yl)))
    (if (i32.eqz (local.get $nbr)) (then (return (i64.or (local.get $c2) (i64.and (local.get $c1) (local.get $c0))))))                         ;; >= 3
    (if (i32.eq (local.get $nbr) (i32.const 1)) (then (return (i64.or (local.get $c3) (i64.and (local.get $c2) (i64.or (local.get $c1) (local.get $c0)))))))   ;; >= 5
    (i64.or (local.get $c4) (i64.and (i64.and (local.get $c3) (local.get $c2)) (i64.or (local.get $c1) (local.get $c0)))))                      ;; >= 13

  ;; smooth_px(src, o, x, w, g, h, stride, nbr, d, thr, salt) -> bits changed. Writes the smoothed pixel to d.
  ;; thr = 0 copies the pixel unchanged and thr = 2^64-1 takes the majority outright, without hashing.
  (func $smooth_px (param $src i32) (param $o i32) (param $x i32) (param $w i32) (param $g i32) (param $h i32) (param $stride i32) (param $nbr i32) (param $d i32) (param $thr i64) (param $salt i64) (result i32)
    (local $s0 i64) (local $s1 i64) (local $diff i64) (local $res i64) (local $i i32) (local $changed i32) (local $always i32) (local $p i32)
    (local.set $p (i32.add (local.get $src) (local.get $o)))
    (local.set $s0 (i64.load (local.get $p))) (local.set $s1 (i64.load offset=8 (local.get $p)))
    (if (i64.eqz (local.get $thr)) (then (i64.store (local.get $d) (local.get $s0)) (i64.store offset=8 (local.get $d) (local.get $s1)) (return (i32.const 0))))
    (local.set $always (i64.eq (local.get $thr) (i64.const -1)))
    (local.set $res (local.get $s0))
    (local.set $diff (i64.xor (local.get $s0) (call $majority (local.get $src) (local.get $o) (local.get $x) (local.get $w) (local.get $g) (local.get $h) (local.get $stride) (local.get $nbr) (i32.const 0))))
    (if (local.get $always)
      (then (local.set $changed (i32.wrap_i64 (i64.popcnt (local.get $diff)))) (local.set $res (i64.xor (local.get $res) (local.get $diff))))
      (else (block $e0 (loop $l0
        (br_if $e0 (i64.eqz (local.get $diff)))
        (local.set $i (i32.wrap_i64 (i64.ctz (local.get $diff))))
        (if (i64.lt_u (i64.add (local.get $salt) (call $mix64 (i64.xor (i64.const 0x5bd1e9955bd1e995)
              (call $ctx (local.get $s0) (local.get $s1) (local.get $i))))) (local.get $thr))
          (then (local.set $res (i64.xor (local.get $res) (i64.shl (i64.const 1) (i64.extend_i32_u (local.get $i)))))
                (local.set $changed (i32.add (local.get $changed) (i32.const 1)))))
        (local.set $diff (i64.and (local.get $diff) (i64.sub (local.get $diff) (i64.const 1))))
        (br $l0)))))
    (i64.store (local.get $d) (local.get $res))
    (local.set $res (local.get $s1))
    (local.set $diff (i64.xor (local.get $s1) (call $majority (local.get $src) (local.get $o) (local.get $x) (local.get $w) (local.get $g) (local.get $h) (local.get $stride) (local.get $nbr) (i32.const 8))))
    (if (local.get $always)
      (then (local.set $changed (i32.add (local.get $changed) (i32.wrap_i64 (i64.popcnt (local.get $diff))))) (local.set $res (i64.xor (local.get $res) (local.get $diff))))
      (else (block $e1 (loop $l1
        (br_if $e1 (i64.eqz (local.get $diff)))
        (local.set $i (i32.wrap_i64 (i64.ctz (local.get $diff))))
        (if (i64.lt_u (i64.add (local.get $salt) (call $mix64 (i64.xor (i64.const 0x5bd1e9955bd1e995)
              (call $ctx (local.get $s0) (local.get $s1) (i32.add (local.get $i) (i32.const 64)))))) (local.get $thr))
          (then (local.set $res (i64.xor (local.get $res) (i64.shl (i64.const 1) (i64.extend_i32_u (local.get $i)))))
                (local.set $changed (i32.add (local.get $changed) (i32.const 1)))))
        (local.set $diff (i64.and (local.get $diff) (i64.sub (local.get $diff) (i64.const 1))))
        (br $l1)))))
    (i64.store offset=8 (local.get $d) (local.get $res))
    (local.get $changed))

  ;; smooth_zone(w, src, dst, thrTab, gy0, h, a, b, ca, cb, salt, nbr) -> bits changed in rows [ca, cb). Smooths local rows [a, b)
  ;; of a buffer whose local row 0 is global row gy0, reading up to R rows above a and below b (R = 1 for
  ;; nbr 0 and 1, 2 for nbr 2), which must exist in the buffer unless they lie outside the grid. Coordinates
  ;; are clamped to the grid. Synchronous: reads src, writes dst. thrTab is indexed by global row.
  (func $smooth_zone (export "smooth_zone") (param $w i32) (param $src i32) (param $dst i32) (param $thrTab i32) (param $gy0 i32) (param $h i32) (param $a i32) (param $b i32) (param $ca i32) (param $cb i32) (param $salt i64) (param $nbr i32) (result i32)
    (local $x i32) (local $r i32) (local $g i32) (local $o i32) (local $changed i32) (local $row i32) (local $stride i32) (local $thr i64) (local $inc i32)
    (local.set $salt (i64.mul (local.get $salt) (i64.const 0x9E3779B97F4A7C15)))
    (local.set $stride (i32.shl (local.get $w) (i32.const 4)))
    (local.set $r (local.get $a))
    (block $ye (loop $yl (br_if $ye (i32.ge_s (local.get $r) (local.get $b)))
      (local.set $g (i32.add (local.get $gy0) (local.get $r)))
      (local.set $row (i32.mul (local.get $r) (local.get $stride)))
      (local.set $thr (i64.load (i32.add (local.get $thrTab) (i32.shl (local.get $g) (i32.const 3)))))
      (local.set $inc (i32.and (i32.ge_s (local.get $r) (local.get $ca)) (i32.lt_s (local.get $r) (local.get $cb))))
      (local.set $x (i32.const 0))
      (block $xe (loop $xl (br_if $xe (i32.ge_u (local.get $x) (local.get $w)))
        (local.set $o (i32.add (local.get $row) (i32.shl (local.get $x) (i32.const 4))))
        (local.set $changed (i32.add (local.get $changed) (i32.mul (local.get $inc) (call $smooth_px
          (local.get $src) (local.get $o) (local.get $x) (local.get $w) (local.get $g) (local.get $h) (local.get $stride) (local.get $nbr)
          (i32.add (local.get $dst) (local.get $o))
          (local.get $thr) (local.get $salt)))))
        (local.set $x (i32.add (local.get $x) (i32.const 1))) (br $xl)))
      (local.set $r (i32.add (local.get $r) (i32.const 1))) (br $yl)))
    (local.get $changed))

  ;; smooth(w, h, src, dst, thrTab, salt, nbr): the whole grid as one zone
  (func (export "smooth") (param $w i32) (param $h i32) (param $src i32) (param $dst i32) (param $thrTab i32) (param $salt i64) (param $nbr i32) (result i32)
    (call $smooth_zone (local.get $w) (local.get $src) (local.get $dst) (local.get $thrTab) (i32.const 0) (local.get $h) (i32.const 0) (local.get $h) (i32.const 0) (local.get $h) (local.get $salt) (local.get $nbr)))

  ;; hist(n, grid, out): the counts of the 256 byte values over n pixels, as 256 i32 at out
  (func (export "hist") (param $n i32) (param $grid i32) (param $out i32)
    (local $p i32) (local $e i32) (local $a i32)
    (memory.fill (local.get $out) (i32.const 0) (i32.const 1024))
    (local.set $p (local.get $grid))
    (local.set $e (i32.add (local.get $grid) (i32.shl (local.get $n) (i32.const 4))))
    (block $x (loop $l (br_if $x (i32.ge_u (local.get $p) (local.get $e)))
      (local.set $a (i32.add (local.get $out) (i32.shl (i32.load8_u (local.get $p)) (i32.const 2))))
      (i32.store (local.get $a) (i32.add (i32.load (local.get $a)) (i32.const 1)))
      (local.set $p (i32.add (local.get $p) (i32.const 1))) (br $l))))

  (func (export "bits") (param $n i32) (param $grid i32) (result i32)
    (local $i i32) (local $p i32) (local $sum i64)
    (block $exit (loop $loop
      (br_if $exit (i32.ge_u (local.get $i) (local.get $n)))
      (local.set $p (i32.add (local.get $grid) (i32.shl (local.get $i) (i32.const 4))))
      (local.set $sum (i64.add (local.get $sum)
        (i64.add (i64.popcnt (i64.load (local.get $p))) (i64.popcnt (i64.load offset=8 (local.get $p))))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $loop)))
    (i32.wrap_i64 (local.get $sum)))

  ;; mutate(n, grid, base, lam, salt): random bit flips, the mutation step of a turn. lam is the expected number of
  ;; flips per pixel as 32.32 fixed point (128 x the per-bit rate): every pixel gets floor(lam) flips, plus one more
  ;; with probability frac(lam), each at a bit position drawn from the hash of (salt, base + i), so a band of rows
  ;; starting at pixel base produces the same flips as the whole grid would. Two flips on the same bit cancel.
  ;; Returns the number of flips.
  (func (export "mutate") (param $n i32) (param $grid i32) (param $base i32) (param $lam i64) (param $salt i64) (result i32)
    (local $i i32) (local $p i32) (local $c i32) (local $h i64) (local $pos i32) (local $flips i32)
    (block $exit (loop $loop
      (br_if $exit (i32.ge_u (local.get $i) (local.get $n)))
      (local.set $p (i32.add (local.get $grid) (i32.shl (local.get $i) (i32.const 4))))
      (local.set $h (call $mix64 (i64.xor (local.get $salt)
        (i64.mul (i64.extend_i32_u (i32.add (local.get $base) (local.get $i))) (i64.const 0x9E3779B97F4A7C15)))))
      (local.set $c (i32.add (i32.wrap_i64 (i64.shr_u (local.get $lam) (i64.const 32)))
        (i64.lt_u (i64.and (local.get $h) (i64.const 0xFFFFFFFF)) (i64.and (local.get $lam) (i64.const 0xFFFFFFFF)))))
      (block $done (loop $flip
        (br_if $done (i32.eqz (local.get $c)))
        (local.set $pos (i32.and (i32.wrap_i64 (i64.shr_u (local.get $h) (i64.const 32))) (i32.const 127)))
        (if (i32.lt_u (local.get $pos) (i32.const 64))
          (then (i64.store (local.get $p) (i64.xor (i64.load (local.get $p)) (i64.shl (i64.const 1) (i64.extend_i32_u (local.get $pos))))))
          (else (i64.store offset=8 (local.get $p) (i64.xor (i64.load offset=8 (local.get $p)) (i64.shl (i64.const 1) (i64.extend_i32_u (i32.sub (local.get $pos) (i32.const 64))))))))
        (local.set $flips (i32.add (local.get $flips) (i32.const 1)))
        (local.set $h (call $mix64 (local.get $h)))
        (local.set $c (i32.sub (local.get $c) (i32.const 1)))
        (br $flip)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $loop)))
    (local.get $flips))

  ;; randomize(nwords, dst, seed): fill 32-bit words with xorshift32. Returns the new seed.
  (func (export "randomize") (param $n i32) (param $dst i32) (param $seed i32) (result i32)
    (local $i i32)
    (if (i32.eqz (local.get $seed)) (then (local.set $seed (i32.const 0x9e3779b9))))
    (block $exit (loop $loop
      (br_if $exit (i32.ge_u (local.get $i) (local.get $n)))
      (local.set $seed (i32.xor (local.get $seed) (i32.shl (local.get $seed) (i32.const 13))))
      (local.set $seed (i32.xor (local.get $seed) (i32.shr_u (local.get $seed) (i32.const 17))))
      (local.set $seed (i32.xor (local.get $seed) (i32.shl (local.get $seed) (i32.const 5))))
      (i32.store (i32.add (local.get $dst) (i32.shl (local.get $i) (i32.const 2))) (local.get $seed))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $loop)))
    (local.get $seed))
