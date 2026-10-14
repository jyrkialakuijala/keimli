;; Bit-swap lattice with a deflate-style decoder, in hand-written WebAssembly.
;;
;; Every pixel is a 128-bit string (two little-endian i64 words, 16 bytes).
;; mix() exchanges single bits between neighbouring pixels under a context
;; hash rule (see below). decode() treats a pixel's 128 bits as a stream of
;; copy commands (prefix-coded length + 3-bit skip) that read forward through a
;; static dictionary text from a 10-bit start cursor; nothing else makes output. The host builds the code tables and writes them, the dictionary
;; and a parameter block into memory before calling in.

(module
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

  ;; mix_zone(w, grid, snap, phase, thrTab, gy0, h, a, b, ca, cb, salt) -> bits exchanged in rows [ca, cb)
  ;; snap is a copy of the grid buffer (same layout) taken before the turn's first phase: every
  ;; decision of the turn is read from it, and the exchanges are applied to grid (snap = grid
  ;; decides on the live pixels).
  ;; (pairs with first row in [a, b) are processed, only those with first row in [ca, cb) are counted).
  ;; grid points at local row 0, which is global row gy0 (may be negative for a band
  ;; buffer whose halo reaches above the grid; such rows are never inside [a, b)).
  ;; Pairs whose first row lies in [a, b) are processed; the grid is a plane with
  ;; edges: left-right pairs never cross a row end, and up-down pairs need both rows
  ;; inside [a, b) and inside the grid. phase: 0 LR even, 1 UD even, 2 LR odd, 3 UD odd.
  (func $mix_zone (export "mix_zone") (param $w i32) (param $grid i32) (param $snap i32) (param $phase i32) (param $thrTab i32) (param $gy0 i32) (param $h i32) (param $a i32) (param $b i32) (param $ca i32) (param $cb i32) (param $salt i64) (result i32)
    (local $x i32) (local $r i32) (local $row i32) (local $swaps i32) (local $off i32) (local $stride i32) (local $inc i32) (local $d i32)
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
          (local.set $x (local.get $off))
          (block $xe (loop $xl (br_if $xe (i32.ge_u (i32.add (local.get $x) (i32.const 1)) (local.get $w)))
            (local.set $swaps (i32.add (local.get $swaps) (i32.mul (local.get $inc) (call $pair
              (i32.add (local.get $row) (i32.shl (local.get $x) (i32.const 4)))
              (i32.add (local.get $row) (i32.shl (i32.add (local.get $x) (i32.const 1)) (i32.const 4)))
              (local.get $d)
              (i64.load (i32.add (local.get $thrTab) (i32.shl (local.get $x) (i32.const 3)))) (local.get $salt)))))
            (local.set $x (i32.add (local.get $x) (i32.const 2))) (br $xl)))
          (local.set $r (i32.add (local.get $r) (i32.const 1))) (br $yl))))
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
          (local.set $r (i32.add (local.get $r) (i32.const 1))) (br $yl2)))))
    (local.get $swaps))

  ;; mix(w, h, grid, phase, thrTab, salt): the whole grid as one zone, deciding on the live pixels
  (func (export "mix") (param $w i32) (param $h i32) (param $grid i32) (param $phase i32) (param $thrTab i32) (param $salt i64) (result i32)
    (call $mix_zone (local.get $w) (local.get $grid) (local.get $grid) (local.get $phase) (local.get $thrTab) (i32.const 0) (local.get $h) (i32.const 0) (local.get $h) (i32.const 0) (local.get $h) (local.get $salt)))
  ;; mix_from(w, h, grid, snap, phase, thrTab, salt): the whole grid as one zone, deciding on the snapshot at snap
  (func (export "mix_from") (param $w i32) (param $h i32) (param $grid i32) (param $snap i32) (param $phase i32) (param $thrTab i32) (param $salt i64) (result i32)
    (call $mix_zone (local.get $w) (local.get $grid) (local.get $snap) (local.get $phase) (local.get $thrTab) (i32.const 0) (local.get $h) (i32.const 0) (local.get $h) (i32.const 0) (local.get $h) (local.get $salt)))

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

  ;; ------------------------------------------------------------------------
  ;; Decoder. Parameter block (i32 fields) at $prm:
  ;;   0 out      output buffer, placed directly after the dictionary text
  ;;   4 outLen   bytes to produce (16 = 128 bits)
  ;;   8 lenTab   4096-entry lookup table for the copy-length code, entry = sym << 8 | codeLen
  ;;  32 textLen  length of the static dictionary text
  ;;  36 flags    one byte per output byte: parity of the command that produced it
  ;;  44 offsetUnit bytes per step of the 10-bit header cursor
  ;;  48 lastOffset written by decode: the cursor the last decoded pixel started at
  ;;  56 lut      256 x i32 byte-colour LUT, 4 bits per channel (R bit 0, G bit 8, B bit 16)
  ;;  60 meanRaw  packed 8-bit mean LUT colour over all byte values (raw-byte view)
  ;;  64 meanDec  packed 8-bit mean LUT colour weighted by the dictionary's byte frequencies
  ;;  68 gain     contrast gain applied around the mean after averaging (1 = plain average)
  ;;  72 changer  0 = LZ decompressor, 1 = Brainfuck with an empty tape, 2 = Brainfuck on a copy of the pixel,
  ;;              3 = do nothing, 4 = invert, 5 = reverse bytes, 6 = Z80, 7 = MOS 6502, 8 = Intel 8080,
  ;;              9 = Subleq, 10 = CHIP-8, 11 = Intel 4004, 12 = Game Boy SM83, 13 = Intel 8051, 14 = Motorola 6809, 15 = RISC-V RV32EC,
  ;;              16 = add 17 (1 to the smallest byte, 17 to the next, 5 to the previous), 17 = DCT, 18 = inverse DCT
  ;; 512 cosTab   64 x f64: cos(pi m / 32), m = 0..63, written by Codec.install (used by the DCT processors)
  ;;  76/80/84 frame sums of the unstretched R, G, B averages in the LUT views, 88 their count (reset by render)
  ;;  92 steps    instructions per pixel for the CPU cores (256 by default)
  ;;  96 headerBits leading bits of a pixel that select the LZ start cursor (ceil log2 textLen, 13 for the Declaration)
  ;; 100 cursorOffset bytes 0..textLen added to the LZ start cursor before wrapping (600)
  ;;  (12..28 are unused by this decoder and kept for layout stability)

  ;; peek(w0, w1, bitpos, n): n (<= 16) bits LSB-first starting at bitpos, wrapping at 128
  (func $peek (param $w0 i64) (param $w1 i64) (param $bp i32) (param $n i32) (result i32)
    (local $off i32) (local $lo i64) (local $hi i64) (local $v i64)
    (local.set $bp (i32.and (local.get $bp) (i32.const 127)))
    (local.set $off (i32.and (local.get $bp) (i32.const 63)))
    (if (i32.lt_u (local.get $bp) (i32.const 64))
      (then (local.set $lo (local.get $w0)) (local.set $hi (local.get $w1)))
      (else (local.set $lo (local.get $w1)) (local.set $hi (local.get $w0))))
    (local.set $v (i64.shr_u (local.get $lo) (i64.extend_i32_u (local.get $off))))
    (if (i32.gt_u (i32.add (local.get $off) (local.get $n)) (i32.const 64))
      (then (local.set $v (i64.or (local.get $v)
              (i64.shl (local.get $hi) (i64.extend_i32_u (i32.sub (i32.const 64) (local.get $off))))))))
    (i32.and (i32.wrap_i64 (local.get $v))
             (i32.sub (i32.shl (i32.const 1) (local.get $n)) (i32.const 1))))

  ;; decode(p, prm): expand the 128 bits at p into exactly outLen bytes.
  ;; The first prm.headerBits bits (ceil log2 textLen) set a byte cursor into the dictionary (times prm.offsetUnit, 1 at that
  ;; width; plus prm.cursorOffset; mod textLen, so values past the end wrap to the start).
  ;; Every command is a prefix-coded copy length (2..N bytes) followed by a 3-bit skip:
  ;; the cursor first skips that many bytes, then the copy is taken from the dictionary
  ;; at the cursor, which advances past it. Copies are the only source of output; the
  ;; input wraps at 128 bits and consumption is capped at 1024 bits (fallback: continue
  ;; the dictionary from the cursor). flags[i] holds the parity of the command that
  ;; produced byte i, so the inspector can show the fragments.
  ;; Returns (input bits consumed << 8) | number of copy commands.
  (func $decode (param $p i32) (param $prm i32) (result i32)
    (local $w0 i64) (local $w1 i64) (local $bp i32)
    (local $out i32) (local $L i32) (local $flags i32) (local $textLen i32) (local $text i32)
    (local $pos i32) (local $entry i32) (local $len i32) (local $cursor i32) (local $cmds i32)
    ;; changer 1 = Brainfuck on an empty tape, 2 = Brainfuck on a copy of the pixel,
    ;; 3 = do nothing, 4 = invert, 5 = reverse bytes, 16 = add 17 (1 to the smallest byte, 17 to the next, 5 to the previous); 0 = LZ decompressor below
    (if (i32.eq (i32.load offset=72 (local.get $prm)) (i32.const 16)) (then
      (return (call $simple (local.get $p) (local.get $prm) (i32.const 16)))))
    (if (i32.eq (i32.load offset=72 (local.get $prm)) (i32.const 17)) (then
      (return (call $dct (local.get $p) (local.get $prm) (i32.const 0)))))
    (if (i32.eq (i32.load offset=72 (local.get $prm)) (i32.const 18)) (then
      (return (call $dct (local.get $p) (local.get $prm) (i32.const 1)))))
    (if (i32.eq (i32.load offset=72 (local.get $prm)) (i32.const 6)) (then
      (return (call $z80 (local.get $p) (local.get $prm)))))
    (if (i32.ge_u (i32.load offset=72 (local.get $prm)) (i32.const 7)) (then
      (return (call $cpu (local.get $p) (local.get $prm) (i32.load offset=72 (local.get $prm))))))
    (if (i32.ge_u (i32.load offset=72 (local.get $prm)) (i32.const 3)) (then
      (return (call $simple (local.get $p) (local.get $prm) (i32.load offset=72 (local.get $prm))))))
    (if (i32.load offset=72 (local.get $prm)) (then
      (return (call $brainfuck (local.get $p) (local.get $prm) (i32.eq (i32.load offset=72 (local.get $prm)) (i32.const 2))))))
    (local.set $w0 (i64.load (local.get $p)))
    (local.set $w1 (i64.load offset=8 (local.get $p)))
    (local.set $out (i32.load (local.get $prm)))
    (local.set $L (i32.load offset=4 (local.get $prm)))
    (local.set $textLen (i32.load offset=32 (local.get $prm)))
    (local.set $flags (i32.load offset=36 (local.get $prm)))
    (local.set $text (i32.sub (local.get $out) (local.get $textLen)))
    ;; header: cursor into the dictionary
    (local.set $cursor (i32.rem_u
      (i32.add
        (i32.mul (call $peek (local.get $w0) (local.get $w1) (i32.const 0) (i32.load offset=96 (local.get $prm)))
                 (i32.load offset=44 (local.get $prm)))
        (i32.load offset=100 (local.get $prm)))
      (local.get $textLen)))
    (i32.store offset=48 (local.get $prm) (local.get $cursor))
    (local.set $bp (i32.load offset=96 (local.get $prm)))
    (block $done (loop $cmd
      (br_if $done (i32.ge_u (local.get $pos) (local.get $L)))
      (br_if $done (i32.ge_u (local.get $bp) (i32.const 1024)))
      ;; copy length symbol: len = symbol + 2
      (local.set $entry (i32.load (i32.add (i32.load offset=8 (local.get $prm))
        (i32.shl (call $peek (local.get $w0) (local.get $w1) (local.get $bp) (i32.const 12)) (i32.const 2)))))
      (local.set $len (i32.add (i32.shr_u (local.get $entry) (i32.const 8)) (i32.const 2)))
      (local.set $bp (i32.add (local.get $bp) (i32.and (local.get $entry) (i32.const 255))))
      ;; 3-bit skip, then copy from the cursor
      (local.set $cursor (i32.rem_u
        (i32.add (local.get $cursor) (call $peek (local.get $w0) (local.get $w1) (local.get $bp) (i32.const 3)))
        (local.get $textLen)))
      (local.set $bp (i32.add (local.get $bp) (i32.const 3)))
      (local.set $cmds (i32.add (local.get $cmds) (i32.const 1)))
      (block $cdone (loop $copy
        (br_if $cdone (i32.or (i32.eqz (local.get $len)) (i32.ge_u (local.get $pos) (local.get $L))))
        (i32.store8 (i32.add (local.get $out) (local.get $pos))
          (i32.load8_u (i32.add (local.get $text) (local.get $cursor))))
        (i32.store8 (i32.add (local.get $flags) (local.get $pos)) (i32.and (local.get $cmds) (i32.const 1)))
        (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
        (local.set $cursor (i32.rem_u (i32.add (local.get $cursor) (i32.const 1)) (local.get $textLen)))
        (local.set $len (i32.sub (local.get $len) (i32.const 1)))
        (br $copy)))
      (br $cmd)))
    ;; fallback fill (cap reached): continue the dictionary from the cursor
    (block $fdone (loop $fill
      (br_if $fdone (i32.ge_u (local.get $pos) (local.get $L)))
      (i32.store8 (i32.add (local.get $out) (local.get $pos))
        (i32.load8_u (i32.add (local.get $text) (local.get $cursor))))
      (i32.store8 (i32.add (local.get $flags) (local.get $pos)) (i32.const 1))
      (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
      (local.set $cursor (i32.rem_u (i32.add (local.get $cursor) (i32.const 1)) (local.get $textLen)))
      (br $fill)))
    (i32.or (i32.shl (local.get $bp) (i32.const 8)) (local.get $cmds)))

  ;; brainfuck(p, prm, init): run the 16 bytes at p as a Brainfuck program on a 16-cell
  ;; circular tape; the tape afterwards is the output. Byte values 0..7 are the commands
  ;; > < + - . , [ ] in that order; any other byte is a comment. '.' does nothing and ','
  ;; reads the next byte of the program itself (cyclic). Unmatched brackets are no-ops.
  ;; init = 0 starts with an empty tape, init = 1 with a copy of the pixel's bytes.
  ;; Execution stops after 1024 steps. flags[i] = 1 where the tape cell differs from its
  ;; initial value; prm.lastOffset receives the final tape pointer.
  ;; Returns (steps << 8) | number of changed cells.
  (func $brainfuck (param $p i32) (param $prm i32) (param $init i32) (result i32)
    (local $out i32) (local $flags i32) (local $ip i32) (local $ptr i32) (local $steps i32)
    (local $c i32) (local $depth i32) (local $in i32) (local $i i32) (local $changed i32) (local $cell i32)
    (local.set $out (i32.load (local.get $prm)))
    (local.set $flags (i32.load offset=36 (local.get $prm)))
    (block $ie (loop $il
      (br_if $ie (i32.ge_u (local.get $i) (i32.const 16)))
      (i32.store8 (i32.add (local.get $out) (local.get $i))
        (select (i32.load8_u (i32.add (local.get $p) (local.get $i))) (i32.const 0) (local.get $init)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $il)))
    (block $done (loop $run
      (br_if $done (i32.ge_u (local.get $ip) (i32.const 16)))
      (br_if $done (i32.ge_u (local.get $steps) (i32.const 1024)))
      (local.set $steps (i32.add (local.get $steps) (i32.const 1)))
      (local.set $c (i32.load8_u (i32.add (local.get $p) (local.get $ip))))
      (local.set $cell (i32.add (local.get $out) (local.get $ptr)))
      (block $next
        (if (i32.eq (local.get $c) (i32.const 0)) (then (local.set $ptr (i32.and (i32.add (local.get $ptr) (i32.const 1)) (i32.const 15))) (br $next)))
        (if (i32.eq (local.get $c) (i32.const 1)) (then (local.set $ptr (i32.and (i32.sub (local.get $ptr) (i32.const 1)) (i32.const 15))) (br $next)))
        (if (i32.eq (local.get $c) (i32.const 2)) (then (i32.store8 (local.get $cell) (i32.add (i32.load8_u (local.get $cell)) (i32.const 1))) (br $next)))
        (if (i32.eq (local.get $c) (i32.const 3)) (then (i32.store8 (local.get $cell) (i32.sub (i32.load8_u (local.get $cell)) (i32.const 1))) (br $next)))
        (if (i32.eq (local.get $c) (i32.const 5)) (then
          (i32.store8 (local.get $cell) (i32.load8_u (i32.add (local.get $p) (i32.and (local.get $in) (i32.const 15)))))
          (local.set $in (i32.add (local.get $in) (i32.const 1)))
          (br $next)))
        (if (i32.eq (local.get $c) (i32.const 6)) (then
          (if (i32.eqz (i32.load8_u (local.get $cell))) (then
            (local.set $depth (i32.const 1)) (local.set $i (local.get $ip))
            (block $fe (loop $fl
              (local.set $i (i32.add (local.get $i) (i32.const 1)))
              (br_if $fe (i32.ge_u (local.get $i) (i32.const 16)))
              (if (i32.eq (i32.load8_u (i32.add (local.get $p) (local.get $i))) (i32.const 6)) (then (local.set $depth (i32.add (local.get $depth) (i32.const 1)))))
              (if (i32.eq (i32.load8_u (i32.add (local.get $p) (local.get $i))) (i32.const 7)) (then (local.set $depth (i32.sub (local.get $depth) (i32.const 1)))))
              (br_if $fl (local.get $depth))))
            (if (i32.eqz (local.get $depth)) (then (local.set $ip (local.get $i))))))
          (br $next)))
        (if (i32.eq (local.get $c) (i32.const 7)) (then
          (if (i32.load8_u (local.get $cell)) (then
            (local.set $depth (i32.const 1)) (local.set $i (local.get $ip))
            (block $be (loop $bl
              (br_if $be (i32.eqz (local.get $i)))
              (local.set $i (i32.sub (local.get $i) (i32.const 1)))
              (if (i32.eq (i32.load8_u (i32.add (local.get $p) (local.get $i))) (i32.const 7)) (then (local.set $depth (i32.add (local.get $depth) (i32.const 1)))))
              (if (i32.eq (i32.load8_u (i32.add (local.get $p) (local.get $i))) (i32.const 6)) (then (local.set $depth (i32.sub (local.get $depth) (i32.const 1)))))
              (br_if $bl (local.get $depth))))
            (if (i32.eqz (local.get $depth)) (then (local.set $ip (local.get $i))))))
          (br $next))))
      (local.set $ip (i32.add (local.get $ip) (i32.const 1)))
      (br $run)))
    (local.set $i (i32.const 0))
    (block $ce (loop $cl
      (br_if $ce (i32.ge_u (local.get $i) (i32.const 16)))
      (local.set $c (i32.ne (i32.load8_u (i32.add (local.get $out) (local.get $i)))
        (select (i32.load8_u (i32.add (local.get $p) (local.get $i))) (i32.const 0) (local.get $init))))
      (i32.store8 (i32.add (local.get $flags) (local.get $i)) (local.get $c))
      (local.set $changed (i32.add (local.get $changed) (local.get $c)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $cl)))
    (i32.store offset=48 (local.get $prm) (local.get $ptr))
    (i32.or (i32.shl (local.get $steps) (i32.const 8)) (local.get $changed)))

  ;; simple(p, prm, kind): elementary byte processors. 3 = identity, 4 = bitwise NOT of all
  ;; 16 bytes, 5 = the 16 bytes in reverse order. flags[i] = 1 where the output byte differs
  ;; from the input byte. Returns the number of differing bytes (steps field 0).
  ;; simple(p, prm, kind): 3 = do nothing, 4 = invert, 5 = reverse bytes,
  ;; 16 = add 17: the smallest byte (the first one on ties) gains 1, the byte after it 17 and the byte
  ;; before it 5, all mod 256 with the index wrapping around the 16 bytes.
  (func $simple (param $p i32) (param $prm i32) (param $kind i32) (result i32)
    (local $out i32) (local $flags i32) (local $i i32) (local $v i32) (local $changed i32) (local $mi i32) (local $d i32)
    (local.set $out (i32.load (local.get $prm)))
    (local.set $flags (i32.load offset=36 (local.get $prm)))
    (if (i32.eq (local.get $kind) (i32.const 16)) (then   ;; index of the smallest byte
      (local.set $i (i32.const 1))
      (block $me (loop $ml (br_if $me (i32.ge_u (local.get $i) (i32.const 16)))
        (if (i32.lt_u (i32.load8_u (i32.add (local.get $p) (local.get $i))) (i32.load8_u (i32.add (local.get $p) (local.get $mi))))
          (then (local.set $mi (local.get $i))))
        (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $ml)))
      (local.set $i (i32.const 0))))
    (block $exit (loop $loop
      (br_if $exit (i32.ge_u (local.get $i) (i32.const 16)))
      (local.set $v
        (if (result i32) (i32.eq (local.get $kind) (i32.const 4))
          (then (i32.and (i32.xor (i32.load8_u (i32.add (local.get $p) (local.get $i))) (i32.const 255)) (i32.const 255)))
          (else (if (result i32) (i32.eq (local.get $kind) (i32.const 5))
            (then (i32.load8_u (i32.add (local.get $p) (i32.sub (i32.const 15) (local.get $i)))))
            (else (if (result i32) (i32.eq (local.get $kind) (i32.const 16))
              (then   ;; d = distance from the smallest byte, mod 16: 0 -> +1, 1 (next) -> +17, 15 (previous) -> +5, else +0
                (local.set $d (i32.and (i32.sub (local.get $i) (local.get $mi)) (i32.const 15)))
                (i32.and (i32.add (i32.load8_u (i32.add (local.get $p) (local.get $i)))
                  (select (i32.const 1) (select (i32.const 17) (select (i32.const 5) (i32.const 0) (i32.eq (local.get $d) (i32.const 15))) (i32.eq (local.get $d) (i32.const 1))) (i32.eqz (local.get $d))))
                  (i32.const 255)))
              (else (i32.load8_u (i32.add (local.get $p) (local.get $i))))))))))
      (i32.store8 (i32.add (local.get $out) (local.get $i)) (local.get $v))
      (i32.store8 (i32.add (local.get $flags) (local.get $i)) (i32.ne (local.get $v) (i32.load8_u (i32.add (local.get $p) (local.get $i)))))
      (local.set $changed (i32.add (local.get $changed) (i32.ne (local.get $v) (i32.load8_u (i32.add (local.get $p) (local.get $i))))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $loop)))
    (i32.store offset=48 (local.get $prm) (i32.const 0))
    (local.get $changed))

  ;; dct(p, prm, inv): 16-point DCT-II (inv = 0) or its inverse, DCT-III (inv = 1), over the 16
  ;; bytes taken as signed samples b - 128. Forward: out[k] = 128 + round(s(k)/2 * sum_n x[n]
  ;; cos(pi (2n+1) k / 32)) with s(0) = 1/4 and s(k>0) = sqrt(2)/4 (the orthonormal scale); the
  ;; extra halving keeps typical coefficients inside a byte. Inverse: x[n] = sum_k 2 s(k)
  ;; (b[k] - 128) cos(pi (2n+1) k / 32), out = 128 + round(x). Results are clamped to 0..255.
  ;; Cosines come from the 64-entry table cos(pi m / 32) at address 512.
  (func $dct (param $p i32) (param $prm i32) (param $inv i32) (result i32)
    (local $out i32) (local $flags i32) (local $k i32) (local $n i32) (local $acc f64) (local $v i32) (local $changed i32) (local $c f64) (local $m i32) (local $t f64)
    (local.set $out (i32.load (local.get $prm)))
    (local.set $flags (i32.load offset=36 (local.get $prm)))
    (block $ke (loop $kl (br_if $ke (i32.ge_u (local.get $k) (i32.const 16)))
      (local.set $acc (f64.const 0))
      (local.set $n (i32.const 0))
      (block $ne (loop $nl (br_if $ne (i32.ge_u (local.get $n) (i32.const 16)))
        (local.set $t (f64.convert_i32_s (i32.sub (i32.load8_u (i32.add (local.get $p) (local.get $n))) (i32.const 128))))
        (if (local.get $inv)
          (then   ;; output sample k from coefficient n: 2 s(n) cos(pi (2k+1) n / 32)
            (local.set $m (i32.mul (i32.add (i32.shl (local.get $k) (i32.const 1)) (i32.const 1)) (local.get $n)))
            (local.set $c (select (f64.const 0.5) (f64.const 0.70710678118654752) (i32.eqz (local.get $n)))))
          (else   ;; coefficient k from sample n: s(k)/2 cos(pi (2n+1) k / 32)
            (local.set $m (i32.mul (i32.add (i32.shl (local.get $n) (i32.const 1)) (i32.const 1)) (local.get $k)))
            (local.set $c (select (f64.const 0.125) (f64.const 0.17677669529663688) (i32.eqz (local.get $k))))))
        (local.set $acc (f64.add (local.get $acc) (f64.mul (f64.mul (local.get $t) (local.get $c))
          (f64.load (i32.add (i32.const 512) (i32.shl (i32.and (local.get $m) (i32.const 63)) (i32.const 3)))))))
        (local.set $n (i32.add (local.get $n) (i32.const 1))) (br $nl)))
      (local.set $v (i32.add (i32.const 128) (i32.trunc_f64_s (f64.nearest (local.get $acc)))))
      (local.set $v (select (i32.const 0) (select (i32.const 255) (local.get $v) (i32.gt_s (local.get $v) (i32.const 255))) (i32.lt_s (local.get $v) (i32.const 0))))
      (i32.store8 (i32.add (local.get $out) (local.get $k)) (local.get $v))
      (local.set $changed (i32.add (local.get $changed) (i32.ne (local.get $v) (i32.load8_u (i32.add (local.get $p) (local.get $k))))))
      (i32.store8 (i32.add (local.get $flags) (local.get $k)) (i32.ne (local.get $v) (i32.load8_u (i32.add (local.get $p) (local.get $k)))))
      (local.set $k (i32.add (local.get $k) (i32.const 1))) (br $kl)))
    (i32.store offset=48 (local.get $prm) (i32.const 0))
    (local.get $changed))

  ;; change(n, grid, prm): run the byte changer on every pixel and write its 16-byte output
  ;; back over the pixel. Returns the number of pixels whose content changed.
  (func (export "change") (param $n i32) (param $grid i32) (param $prm i32) (result i32)
    (local $i i32) (local $p i32) (local $out i32) (local $o0 i64) (local $o1 i64) (local $changed i32)
    (local.set $out (i32.load (local.get $prm)))
    (block $exit (loop $loop
      (br_if $exit (i32.ge_u (local.get $i) (local.get $n)))
      (local.set $p (i32.add (local.get $grid) (i32.shl (local.get $i) (i32.const 4))))
      (drop (call $decode (local.get $p) (local.get $prm)))
      (local.set $o0 (i64.load (local.get $out)))
      (local.set $o1 (i64.load offset=8 (local.get $out)))
      (if (i32.or (i64.ne (local.get $o0) (i64.load (local.get $p))) (i64.ne (local.get $o1) (i64.load offset=8 (local.get $p))))
        (then
          (i64.store (local.get $p) (local.get $o0))
          (i64.store offset=8 (local.get $p) (local.get $o1))
          (local.set $changed (i32.add (local.get $changed) (i32.const 1)))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $loop)))
    (local.get $changed))

  ;; decode_pixel(grid, index, prm): inflate one pixel into the output buffer
  (func (export "decode_pixel") (param $grid i32) (param $index i32) (param $prm i32) (result i32)
    (call $decode (i32.add (local.get $grid) (i32.shl (local.get $index) (i32.const 4))) (local.get $prm)))

  ;; hbytes(ptr, len): hash a byte run down to one 8-bit colour channel
  (func $hbytes (param $ptr i32) (param $len i32) (result i32)
    (local $h i32) (local $i i32)
    (local.set $h (i32.const 0x811c9dc5))
    (block $exit (loop $loop
      (br_if $exit (i32.ge_u (local.get $i) (local.get $len)))
      (local.set $h (i32.mul (i32.xor (local.get $h) (i32.load8_u (i32.add (local.get $ptr) (local.get $i))))
                             (i32.const 0x9E3779B1)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $loop)))
    (local.set $h (i32.mul (i32.xor (local.get $h) (i32.shr_u (local.get $h) (i32.const 15))) (i32.const 0x85EBCA6B)))
    (i32.shr_u (i32.xor (local.get $h) (i32.shr_u (local.get $h) (i32.const 13))) (i32.const 24)))

  ;; chan(word, shift): hash a 16-bit slice of a raw word down to one 8-bit channel
  (func $chan (param $word i64) (param $shift i64) (result i32)
    (i32.shr_u
      (i32.mul
        (i32.and (i32.wrap_i64 (i64.shr_u (local.get $word) (local.get $shift))) (i32.const 0xffff))
        (i32.const 0x9E3779B1))
      (i32.const 24)))

  ;; rgb(r, g, b) -> packed little-endian RGBA pixel
  (func $rgb (param $r i32) (param $g i32) (param $b i32) (result i32)
    (i32.or (i32.const 0xff000000)
      (i32.or (local.get $r)
        (i32.or (i32.shl (local.get $g) (i32.const 8)) (i32.shl (local.get $b) (i32.const 16))))))

  ;; stretch(c, m, gain): amplify the deviation of channel value c from the palette mean m, clamped to 0..255
  (func $stretch (param $c i32) (param $m i32) (param $gain i32) (result i32)
    (local $v i32)
    (local.set $v (i32.add (local.get $m) (i32.mul (i32.sub (local.get $c) (local.get $m)) (local.get $gain))))
    (select (i32.const 0) (select (i32.const 255) (local.get $v) (i32.gt_s (local.get $v) (i32.const 255))) (i32.lt_s (local.get $v) (i32.const 0))))

  ;; lutavg(ptr, prm, meanOff): sum the 16 LUT entries (4 bits per channel, R at bit 0, G at 8,
  ;; B at 16) of the 16 bytes at ptr; the per-channel sums (0..240) are scaled to 0..255, added to
  ;; the frame accumulators (prm 76/80/84, count at 88) so the host can derive the frame's mean,
  ;; then stretched by prm.gain around the packed 8-bit mean at prm[meanOff].
  (func $lutavg (param $ptr i32) (param $prm i32) (param $meanOff i32) (result i32)
    (local $i i32) (local $sum i32) (local $r i32) (local $g i32) (local $b i32) (local $mean i32) (local $gain i32)
    (block $exit (loop $loop
      (br_if $exit (i32.ge_u (local.get $i) (i32.const 16)))
      (local.set $sum (i32.add (local.get $sum)
        (i32.load (i32.add (i32.load offset=56 (local.get $prm)) (i32.shl (i32.load8_u (i32.add (local.get $ptr) (local.get $i))) (i32.const 2))))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $loop)))
    (local.set $r (i32.shr_u (i32.mul (i32.and (local.get $sum) (i32.const 255)) (i32.const 17)) (i32.const 4)))
    (local.set $g (i32.shr_u (i32.mul (i32.and (i32.shr_u (local.get $sum) (i32.const 8)) (i32.const 255)) (i32.const 17)) (i32.const 4)))
    (local.set $b (i32.shr_u (i32.mul (i32.and (i32.shr_u (local.get $sum) (i32.const 16)) (i32.const 255)) (i32.const 17)) (i32.const 4)))
    (i32.store offset=76 (local.get $prm) (i32.add (i32.load offset=76 (local.get $prm)) (local.get $r)))
    (i32.store offset=80 (local.get $prm) (i32.add (i32.load offset=80 (local.get $prm)) (local.get $g)))
    (i32.store offset=84 (local.get $prm) (i32.add (i32.load offset=84 (local.get $prm)) (local.get $b)))
    (i32.store offset=88 (local.get $prm) (i32.add (i32.load offset=88 (local.get $prm)) (i32.const 1)))
    (local.set $mean (i32.load (i32.add (local.get $prm) (local.get $meanOff))))
    (local.set $gain (i32.load offset=68 (local.get $prm)))
    (call $rgb
      (call $stretch (local.get $r) (i32.and (local.get $mean) (i32.const 255)) (local.get $gain))
      (call $stretch (local.get $g) (i32.and (i32.shr_u (local.get $mean) (i32.const 8)) (i32.const 255)) (local.get $gain))
      (call $stretch (local.get $b) (i32.and (i32.shr_u (local.get $mean) (i32.const 16)) (i32.const 255)) (local.get $gain))))

  ;; render(n, grid, pix, pal, mode, prm):
  ;;   mode 0: decode each pixel; R, G, B = hash of the first, middle and last third of the output
  ;;   mode 1: raw bits: R = hash(bits 0..15), G = hash(16..31), B = hash(32..47)
  ;;   mode 2: decode; colour by the pixel's dictionary cursor offset (129-entry palette)
  ;;   mode 3: bit density in thirds: set bits of positions 0-42, 43-85, 86-127 scaled to R, G, B
  ;;   mode 4: average of the byte-colour LUT (prm.lut) over the pixel's 16 raw bytes
  ;;   mode 5: the same over the 16 decoded bytes
  (func (export "render") (param $n i32) (param $grid i32) (param $pix i32) (param $pal i32) (param $mode i32) (param $prm i32)
    (local $i i32) (local $p i32) (local $w0 i64) (local $w1 i64) (local $out i32) (local $L i32) (local $third i32)
    (local.set $out (i32.load (local.get $prm)))
    (local.set $L (i32.load offset=4 (local.get $prm)))
    (local.set $third (i32.div_u (local.get $L) (i32.const 3)))
    (i32.store offset=76 (local.get $prm) (i32.const 0)) (i32.store offset=80 (local.get $prm) (i32.const 0))
    (i32.store offset=84 (local.get $prm) (i32.const 0)) (i32.store offset=88 (local.get $prm) (i32.const 0))
    (block $exit (loop $loop
      (br_if $exit (i32.ge_u (local.get $i) (local.get $n)))
      (local.set $p (i32.add (local.get $grid) (i32.shl (local.get $i) (i32.const 4))))
      (local.set $w0 (i64.load (local.get $p)))
      (i32.store (i32.add (local.get $pix) (i32.shl (local.get $i) (i32.const 2)))
        (if (result i32) (i32.ge_u (local.get $mode) (i32.const 4))
          (then
            (if (i32.eq (local.get $mode) (i32.const 5)) (then (drop (call $decode (local.get $p) (local.get $prm)))))
            (call $lutavg (select (local.get $p) (local.get $out) (i32.eq (local.get $mode) (i32.const 4)))
                          (local.get $prm)
                          (select (i32.const 60) (i32.const 64) (i32.eq (local.get $mode) (i32.const 4)))))
        (else
        (if (result i32) (i32.eqz (local.get $mode))
          (then
            (drop (call $decode (local.get $p) (local.get $prm)))
            (call $rgb
              (call $hbytes (local.get $out) (local.get $third))
              (call $hbytes (i32.add (local.get $out) (local.get $third)) (local.get $third))
              (call $hbytes (i32.add (local.get $out) (i32.shl (local.get $third) (i32.const 1)))
                            (i32.sub (local.get $L) (i32.shl (local.get $third) (i32.const 1))))))
          (else (if (result i32) (i32.eq (local.get $mode) (i32.const 1))
            (then (call $rgb
              (call $chan (local.get $w0) (i64.const 0))
              (call $chan (local.get $w0) (i64.const 16))
              (call $chan (local.get $w0) (i64.const 32))))
            (else (if (result i32) (i32.eq (local.get $mode) (i32.const 2))
              (then
                (drop (call $decode (local.get $p) (local.get $prm)))
                (i32.load (i32.add (local.get $pal) (i32.shl
                  (i32.div_u (i32.shl (i32.load offset=48 (local.get $prm)) (i32.const 7))
                             (i32.load offset=32 (local.get $prm)))
                  (i32.const 2)))))
              (else   ;; mode 3: set-bit counts of bits 0-42, 43-85, 86-127 as R, G, B
                (local.set $w1 (i64.load offset=8 (local.get $p)))
                (call $rgb
                  (i32.div_u (i32.mul (i32.wrap_i64 (i64.popcnt (i64.and (local.get $w0) (i64.const 0x7ffffffffff)))) (i32.const 255)) (i32.const 43))
                  (i32.div_u (i32.mul (i32.wrap_i64 (i64.add
                      (i64.popcnt (i64.shr_u (local.get $w0) (i64.const 43)))
                      (i64.popcnt (i64.and (local.get $w1) (i64.const 0x3fffff))))) (i32.const 255)) (i32.const 43))
                  (i32.div_u (i32.mul (i32.wrap_i64 (i64.popcnt (i64.shr_u (local.get $w1) (i64.const 22)))) (i32.const 255)) (i32.const 42))))))))))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $loop))))

  ;; bits(n, grid): total number of set bits in the lattice (conserved by mix)
  ;; blend(w, h, pix, acc, k0, k4, k8) -> (n4 << 32) | n8: the render buffer, an exponential average of
  ;; the rendered frames. acc holds three 16.16 fixed-point channels per pixel. Every pixel of the RGBA
  ;; frame at pix pulls its accumulator towards the frame colour by k/65536 of the difference, where k is
  ;; k8 if the pixel's whole 3x3 neighbourhood in the frame has its colour (8-connected flat), k4 if only
  ;; the pixel and its 4-connected neighbours do, k0 otherwise (edge pixels: the neighbours that exist);
  ;; the frame is then replaced by the rounded accumulator. k = 65536 copies the frame (first frame,
  ;; resets). Pass 1 marks the tier in the alpha byte (253 / 254 / 255), pass 2 blends and restores alpha
  ;; 255. n4 counts the pixels that were 4- but not 8-connected flat, n8 the 8-connected flat ones.
  (func (export "blend") (param $w i32) (param $h i32) (param $pix i32) (param $acc i32) (param $k0 i32) (param $k4 i32) (param $k8 i32) (result i64)
    (local $x i32) (local $y i32) (local $i i32) (local $c i32) (local $f4 i32) (local $f8 i32) (local $dx i32) (local $dy i32) (local $xx i32) (local $yy i32)
    (local $n i32) (local $n4 i32) (local $n8 i32) (local $k i32) (local $ch i32) (local $a i32) (local $p i32) (local $q i32) (local $t i32)
    (local.set $n (i32.mul (local.get $w) (local.get $h)))
    (block $ye (loop $yl (br_if $ye (i32.ge_u (local.get $y) (local.get $h)))
      (local.set $x (i32.const 0))
      (block $xe (loop $xl (br_if $xe (i32.ge_u (local.get $x) (local.get $w)))
        (local.set $i (i32.add (i32.mul (local.get $y) (local.get $w)) (local.get $x)))
        (local.set $p (i32.add (local.get $pix) (i32.shl (local.get $i) (i32.const 2))))
        (local.set $c (i32.and (i32.load (local.get $p)) (i32.const 0xffffff)))
        (local.set $f4 (i32.const 1)) (local.set $f8 (i32.const 1))
        (local.set $dy (i32.const -1))
        (block $de (loop $dl (br_if $de (i32.gt_s (local.get $dy) (i32.const 1)))
          (local.set $yy (i32.add (local.get $y) (local.get $dy)))
          (if (i32.lt_u (local.get $yy) (local.get $h)) (then   ;; unsigned compare rejects -1 as well
            (local.set $dx (i32.const -1))
            (block $ee (loop $el (br_if $ee (i32.gt_s (local.get $dx) (i32.const 1)))
              (local.set $xx (i32.add (local.get $x) (local.get $dx)))
              (if (i32.lt_u (local.get $xx) (local.get $w)) (then
                (if (i32.ne (i32.and (i32.load (i32.add (local.get $pix) (i32.shl (i32.add (i32.mul (local.get $yy) (local.get $w)) (local.get $xx)) (i32.const 2)))) (i32.const 0xffffff)) (local.get $c))
                  (then
                    (local.set $f8 (i32.const 0))
                    (if (i32.or (i32.eqz (local.get $dx)) (i32.eqz (local.get $dy))) (then (local.set $f4 (i32.const 0))))))))
              (local.set $dx (i32.add (local.get $dx) (i32.const 1))) (br $el)))))
          (local.set $dy (i32.add (local.get $dy) (i32.const 1))) (br $dl)))
        (i32.store8 offset=3 (local.get $p) (i32.sub (i32.sub (i32.const 255) (local.get $f4)) (local.get $f8)))
        (local.set $n8 (i32.add (local.get $n8) (local.get $f8)))
        (local.set $n4 (i32.add (local.get $n4) (i32.and (local.get $f4) (i32.eqz (local.get $f8)))))
        (local.set $x (i32.add (local.get $x) (i32.const 1))) (br $xl)))
      (local.set $y (i32.add (local.get $y) (i32.const 1))) (br $yl)))
    (local.set $i (i32.const 0))
    (block $ie (loop $il (br_if $ie (i32.ge_u (local.get $i) (local.get $n)))
      (local.set $p (i32.add (local.get $pix) (i32.shl (local.get $i) (i32.const 2))))
      (local.set $q (i32.add (local.get $acc) (i32.mul (local.get $i) (i32.const 12))))
      (local.set $t (i32.load8_u offset=3 (local.get $p)))
      (local.set $k (select (local.get $k8) (select (local.get $k4) (local.get $k0) (i32.eq (local.get $t) (i32.const 254))) (i32.eq (local.get $t) (i32.const 253))))
      (local.set $ch (i32.const 0))
      (block $ce (loop $cl (br_if $ce (i32.ge_u (local.get $ch) (i32.const 3)))
        (local.set $a (i32.load (i32.add (local.get $q) (i32.shl (local.get $ch) (i32.const 2)))))
        (local.set $a (i32.add (local.get $a) (i32.wrap_i64 (i64.shr_s (i64.mul
          (i64.extend_i32_s (i32.sub (i32.shl (i32.load8_u (i32.add (local.get $p) (local.get $ch))) (i32.const 16)) (local.get $a)))
          (i64.extend_i32_s (local.get $k))) (i64.const 16)))))
        (i32.store (i32.add (local.get $q) (i32.shl (local.get $ch) (i32.const 2))) (local.get $a))
        (i32.store8 (i32.add (local.get $p) (local.get $ch)) (i32.shr_u (i32.add (local.get $a) (i32.const 32768)) (i32.const 16)))
        (local.set $ch (i32.add (local.get $ch) (i32.const 1))) (br $cl)))
      (i32.store8 offset=3 (local.get $p) (i32.const 255))
      (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $il)))
    (i64.or (i64.shl (i64.extend_i32_u (local.get $n4)) (i64.const 32)) (i64.extend_i32_u (local.get $n8))))

  ;; sharpen(w, h, src, dst): spatial sharpening of an RGBA frame, dst = 2 * src - mean of the 4-connected
  ;; neighbours (those that exist at the edges), per channel, rounded and clamped to 0..255; alpha becomes 255.
  (func (export "sharpen") (param $w i32) (param $h i32) (param $src i32) (param $dst i32)
    (local $x i32) (local $y i32) (local $i i32) (local $ch i32) (local $s i32) (local $n i32) (local $v i32) (local $p i32) (local $o i32)
    (block $ye (loop $yl (br_if $ye (i32.ge_u (local.get $y) (local.get $h)))
      (local.set $x (i32.const 0))
      (block $xe (loop $xl (br_if $xe (i32.ge_u (local.get $x) (local.get $w)))
        (local.set $i (i32.add (i32.mul (local.get $y) (local.get $w)) (local.get $x)))
        (local.set $p (i32.add (local.get $src) (i32.shl (local.get $i) (i32.const 2))))
        (local.set $o (i32.add (local.get $dst) (i32.shl (local.get $i) (i32.const 2))))
        (local.set $ch (i32.const 0))
        (block $ce (loop $cl (br_if $ce (i32.ge_u (local.get $ch) (i32.const 3)))
          (local.set $s (i32.const 0)) (local.set $n (i32.const 0))
          (if (i32.gt_u (local.get $x) (i32.const 0)) (then (local.set $s (i32.add (local.get $s) (i32.load8_u (i32.sub (i32.add (local.get $p) (local.get $ch)) (i32.const 4))))) (local.set $n (i32.add (local.get $n) (i32.const 1)))))
          (if (i32.lt_u (i32.add (local.get $x) (i32.const 1)) (local.get $w)) (then (local.set $s (i32.add (local.get $s) (i32.load8_u offset=4 (i32.add (local.get $p) (local.get $ch))))) (local.set $n (i32.add (local.get $n) (i32.const 1)))))
          (if (i32.gt_u (local.get $y) (i32.const 0)) (then (local.set $s (i32.add (local.get $s) (i32.load8_u (i32.sub (i32.add (local.get $p) (local.get $ch)) (i32.shl (local.get $w) (i32.const 2)))))) (local.set $n (i32.add (local.get $n) (i32.const 1)))))
          (if (i32.lt_u (i32.add (local.get $y) (i32.const 1)) (local.get $h)) (then (local.set $s (i32.add (local.get $s) (i32.load8_u (i32.add (i32.add (local.get $p) (local.get $ch)) (i32.shl (local.get $w) (i32.const 2)))))) (local.set $n (i32.add (local.get $n) (i32.const 1)))))
          ;; v = 2 * value * n - sum, in units of 1/n; a 1x1 frame has n = 0 and keeps its value
          (local.set $v (i32.load8_u (i32.add (local.get $p) (local.get $ch))))
          (if (local.get $n) (then
            (local.set $v (i32.sub (i32.mul (i32.shl (local.get $v) (i32.const 1)) (local.get $n)) (local.get $s)))
            (local.set $v (select (i32.const 0) (i32.div_u (i32.add (local.get $v) (i32.shr_u (local.get $n) (i32.const 1))) (local.get $n)) (i32.le_s (local.get $v) (i32.const 0))))
            (local.set $v (select (i32.const 255) (local.get $v) (i32.gt_u (local.get $v) (i32.const 255))))))
          (i32.store8 (i32.add (local.get $o) (local.get $ch)) (local.get $v))
          (local.set $ch (i32.add (local.get $ch) (i32.const 1))) (br $cl)))
        (i32.store8 offset=3 (local.get $o) (i32.const 255))
        (local.set $x (i32.add (local.get $x) (i32.const 1))) (br $xl)))
      (local.set $y (i32.add (local.get $y) (i32.const 1))) (br $yl))))

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

  ;; ========================================================================
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
  (global $zp (mut i32) (i32.const 0))   ;; base address of the current pixel's 16 bytes

  (func $zr (param $o i32) (result i32) (i32.load8_u offset=256 (local.get $o)))
  (func $zw (param $o i32) (param $v i32) (i32.store8 offset=256 (local.get $o) (local.get $v)))
  (func $zr16 (param $o i32) (result i32) (i32.load16_u offset=256 (local.get $o)))
  (func $zw16 (param $o i32) (param $v i32) (i32.store16 offset=256 (local.get $o) (local.get $v)))
  (func $mrd (param $a i32) (result i32) (i32.load8_u (i32.add (global.get $zp) (i32.and (local.get $a) (i32.const 15)))))
  (func $mwr (param $a i32) (param $v i32) (i32.store8 (i32.add (global.get $zp) (i32.and (local.get $a) (i32.const 15))) (local.get $v)))
  (func $mrd16 (param $a i32) (result i32)
    (i32.or (call $mrd (local.get $a)) (i32.shl (call $mrd (i32.add (local.get $a) (i32.const 1))) (i32.const 8))))
  (func $mwr16 (param $a i32) (param $v i32)
    (call $mwr (local.get $a) (i32.and (local.get $v) (i32.const 255)))
    (call $mwr (i32.add (local.get $a) (i32.const 1)) (i32.shr_u (local.get $v) (i32.const 8))))
  (func $sext8 (param $v i32) (result i32) (i32.shr_s (i32.shl (local.get $v) (i32.const 24)) (i32.const 24)))
  (func $fetch (result i32)
    (local $pc i32) (local $v i32)
    (local.set $pc (call $zr16 (i32.const 22)))
    (local.set $v (call $mrd (local.get $pc)))
    (call $zw16 (i32.const 22) (i32.and (i32.add (local.get $pc) (i32.const 1)) (i32.const 0xffff)))
    (call $zw (i32.const 25) (i32.or (i32.and (local.get $v) (i32.const 0)) (i32.or (i32.and (call $zr (i32.const 25)) (i32.const 0x80)) (i32.and (i32.add (call $zr (i32.const 25)) (i32.const 1)) (i32.const 0x7f)))))
    (local.get $v))
  (func $fetch16 (result i32) (local $lo i32) (local.set $lo (call $fetch)) (i32.or (local.get $lo) (i32.shl (call $fetch) (i32.const 8))))
  (func $push (param $v i32) (local $sp i32)
    (local.set $sp (i32.and (i32.sub (call $zr16 (i32.const 20)) (i32.const 2)) (i32.const 0xffff)))
    (call $zw16 (i32.const 20) (local.get $sp))
    (call $mwr16 (local.get $sp) (local.get $v)))
  (func $pop (result i32) (local $sp i32) (local $v i32)
    (local.set $sp (call $zr16 (i32.const 20)))
    (local.set $v (call $mrd16 (local.get $sp)))
    (call $zw16 (i32.const 20) (i32.and (i32.add (local.get $sp) (i32.const 2)) (i32.const 0xffff)))
    (local.get $v))
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
  ;; ========================================================================
  ;; Intel 8080 byte processor. Same conventions as the Z80 core (16-byte address
  ;; space wrapping mod 16, registers zeroed, 256 instructions, HLT/DI/EI/IN/OUT
  ;; are NOPs) and the same register file layout, so it reuses $fetch, $push,
  ;; $pop, $getr/$setr (prefix byte stays 0, so (HL) is always HL), $cc and $swap.
  ;; Flags are 8080 flags: S Z 0 AC 0 P 1 CY, with P always parity.
  (func $f80 (param $r i32) (param $ac i32) (param $cy i32) (result i32)   ;; build an 8080 flag byte
    (i32.or (i32.or (i32.and (local.get $r) (i32.const 0x80)) (select (i32.const 0x40) (i32.const 0) (i32.eqz (i32.and (local.get $r) (i32.const 255)))))
      (i32.or (i32.or (select (i32.const 0x10) (i32.const 0) (local.get $ac)) (select (i32.const 4) (i32.const 0) (i32.eqz (i32.and (i32.popcnt (i32.and (local.get $r) (i32.const 255))) (i32.const 1)))))
              (i32.or (i32.const 2) (select (i32.const 1) (i32.const 0) (local.get $cy))))))
  (func $alu80 (param $op i32) (param $b i32)
    (local $a i32) (local $r i32) (local $c i32) (local $ac i32)
    (local.set $a (call $zr (i32.const 7))) (local.set $c (i32.and (call $zr (i32.const 6)) (i32.const 1)))
    (if (i32.lt_u (local.get $op) (i32.const 2)) (then
      (local.set $r (i32.add (i32.add (local.get $a) (local.get $b)) (select (local.get $c) (i32.const 0) (local.get $op))))
      (call $zw (i32.const 7) (i32.and (local.get $r) (i32.const 255)))
      (call $zw (i32.const 6) (call $f80 (local.get $r) (i32.and (i32.xor (i32.xor (local.get $a) (local.get $b)) (local.get $r)) (i32.const 0x10)) (i32.and (local.get $r) (i32.const 0x100))))
      (return)))
    (if (i32.or (i32.lt_u (local.get $op) (i32.const 4)) (i32.eq (local.get $op) (i32.const 7))) (then
      (local.set $r (i32.sub (i32.sub (local.get $a) (local.get $b)) (select (local.get $c) (i32.const 0) (i32.eq (local.get $op) (i32.const 3)))))
      (if (i32.ne (local.get $op) (i32.const 7)) (then (call $zw (i32.const 7) (i32.and (local.get $r) (i32.const 255)))))
      (call $zw (i32.const 6) (call $f80 (local.get $r) (i32.eqz (i32.and (i32.xor (i32.xor (local.get $a) (local.get $b)) (local.get $r)) (i32.const 0x10))) (i32.and (local.get $r) (i32.const 0x100))))
      (return)))
    (if (i32.eq (local.get $op) (i32.const 4))
      (then (local.set $r (i32.and (local.get $a) (local.get $b))) (local.set $ac (i32.and (i32.or (local.get $a) (local.get $b)) (i32.const 8))))
      (else (local.set $r (select (i32.xor (local.get $a) (local.get $b)) (i32.or (local.get $a) (local.get $b)) (i32.eq (local.get $op) (i32.const 5))))))
    (call $zw (i32.const 7) (local.get $r))
    (call $zw (i32.const 6) (call $f80 (local.get $r) (local.get $ac) (i32.const 0))))
  (func $i8080step
    (local $op i32) (local $x i32) (local $y i32) (local $z i32) (local $p i32) (local $q i32) (local $t i32) (local $v i32) (local $hl i32) (local $f i32)
    (local.set $op (call $fetch))
    (local.set $x (i32.shr_u (local.get $op) (i32.const 6))) (local.set $y (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 7)))
    (local.set $z (i32.and (local.get $op) (i32.const 7))) (local.set $p (i32.shr_u (local.get $y) (i32.const 1))) (local.set $q (i32.and (local.get $y) (i32.const 1)))
    (local.set $hl (call $zr16 (i32.const 4)))
    (block $end
      (if (i32.eq (local.get $x) (i32.const 1)) (then
        (if (i32.eq (local.get $op) (i32.const 0x76)) (then (br $end)))   ;; HLT -> NOP
        (call $setr (local.get $y) (local.get $hl) (call $getr (local.get $z) (local.get $hl))) (br $end)))
      (if (i32.eq (local.get $x) (i32.const 2)) (then (call $alu80 (local.get $y) (call $getr (local.get $z) (local.get $hl))) (br $end)))
      (if (i32.eqz (local.get $x)) (then
        (if (i32.eqz (local.get $z)) (then (br $end)))   ;; NOP and its duplicates
        (if (i32.eq (local.get $z) (i32.const 1)) (then
          (if (local.get $q)
            (then   ;; DAD rp: only CY
              (local.set $t (i32.add (local.get $hl) (call $zr16 (call $rpoff (local.get $p)))))
              (call $zw16 (i32.const 4) (i32.and (local.get $t) (i32.const 0xffff)))
              (call $zw (i32.const 6) (i32.or (i32.and (call $zr (i32.const 6)) (i32.const 0xFE)) (i32.and (i32.shr_u (local.get $t) (i32.const 16)) (i32.const 1)))))
            (else (call $zw16 (call $rpoff (local.get $p)) (call $fetch16))))
          (br $end)))
        (if (i32.eq (local.get $z) (i32.const 2)) (then
          (if (i32.eqz (local.get $p)) (then (local.set $t (call $zr16 (i32.const 0))))
            (else (if (i32.eq (local.get $p) (i32.const 1)) (then (local.set $t (call $zr16 (i32.const 2)))) (else (local.set $t (call $fetch16))))))   ;; no select here: fetch16 has side effects
          (if (local.get $q)
            (then (if (i32.eq (local.get $p) (i32.const 2)) (then (call $zw16 (i32.const 4) (call $mrd16 (local.get $t)))) (else (call $zw (i32.const 7) (call $mrd (local.get $t))))))
            (else (if (i32.eq (local.get $p) (i32.const 2)) (then (call $mwr16 (local.get $t) (local.get $hl))) (else (call $mwr (local.get $t) (call $zr (i32.const 7)))))))
          (br $end)))
        (if (i32.eq (local.get $z) (i32.const 3)) (then
          (local.set $t (call $rpoff (local.get $p)))
          (call $zw16 (local.get $t) (i32.and (i32.add (call $zr16 (local.get $t)) (select (i32.const -1) (i32.const 1) (local.get $q))) (i32.const 0xffff)))
          (br $end)))
        (if (i32.lt_u (local.get $z) (i32.const 6)) (then   ;; INR / DCR: S Z AC P, not CY
          (local.set $v (call $getr (local.get $y) (local.get $hl)))
          (local.set $t (i32.and (i32.add (local.get $v) (select (i32.const 1) (i32.const -1) (i32.eq (local.get $z) (i32.const 4)))) (i32.const 255)))
          (call $setr (local.get $y) (local.get $hl) (local.get $t))
          (call $zw (i32.const 6) (i32.or (i32.and (call $zr (i32.const 6)) (i32.const 1))
            (i32.and (call $f80 (local.get $t)
              (select (i32.eqz (i32.and (local.get $t) (i32.const 15))) (i32.ne (i32.and (local.get $t) (i32.const 15)) (i32.const 15)) (i32.eq (local.get $z) (i32.const 4)))
              (i32.const 0)) (i32.const 0xFE))))
          (br $end)))
        (if (i32.eq (local.get $z) (i32.const 6)) (then (call $setr (local.get $y) (local.get $hl) (call $fetch)) (br $end)))
        ;; z = 7: RLC RRC RAL RAR DAA CMA STC CMC
        (local.set $f (call $zr (i32.const 6)))
        (if (i32.lt_u (local.get $y) (i32.const 4)) (then
          (call $zw (i32.const 7) (call $rot (local.get $y) (call $zr (i32.const 7))))
          (call $zw (i32.const 6) (i32.or (i32.and (local.get $f) (i32.const 0xFE)) (i32.and (call $zr (i32.const 6)) (i32.const 1))))
          (br $end)))
        (if (i32.eq (local.get $y) (i32.const 4)) (then   ;; DAA (8080: always adds)
          (local.set $v (call $zr (i32.const 7))) (local.set $t (i32.const 0))
          (if (i32.or (i32.and (local.get $f) (i32.const 0x10)) (i32.gt_u (i32.and (local.get $v) (i32.const 15)) (i32.const 9))) (then (local.set $t (i32.const 6))))
          (if (i32.or (i32.and (local.get $f) (i32.const 1)) (i32.gt_u (local.get $v) (i32.const 0x99))) (then (local.set $t (i32.or (local.get $t) (i32.const 0x60)))))
          (local.set $p (i32.add (local.get $v) (local.get $t)))
          (call $zw (i32.const 7) (i32.and (local.get $p) (i32.const 255)))
          (call $zw (i32.const 6) (call $f80 (local.get $p) (i32.and (i32.xor (local.get $v) (local.get $p)) (i32.const 0x10)) (i32.or (i32.and (local.get $f) (i32.const 1)) (i32.and (local.get $t) (i32.const 0x60)))))
          (br $end)))
        (if (i32.eq (local.get $y) (i32.const 5)) (then (call $zw (i32.const 7) (i32.xor (call $zr (i32.const 7)) (i32.const 255))) (br $end)))
        (if (i32.eq (local.get $y) (i32.const 6)) (then (call $zw (i32.const 6) (i32.or (local.get $f) (i32.const 1))) (br $end)))
        (call $zw (i32.const 6) (i32.xor (local.get $f) (i32.const 1)))
        (br $end)))
      ;; x = 3
      (if (i32.eqz (local.get $z)) (then (if (call $cc (local.get $y)) (then (call $zw16 (i32.const 22) (call $pop)))) (br $end)))
      (if (i32.eq (local.get $z) (i32.const 1)) (then
        (if (i32.eqz (local.get $q)) (then (call $zw16 (call $rp2off (local.get $p)) (call $pop)) (br $end)))
        (if (i32.lt_u (local.get $p) (i32.const 2)) (then (call $zw16 (i32.const 22) (call $pop)) (br $end)))   ;; RET and its duplicate
        (if (i32.eq (local.get $p) (i32.const 2)) (then (call $zw16 (i32.const 22) (local.get $hl)) (br $end)))
        (call $zw16 (i32.const 20) (local.get $hl)) (br $end)))
      (if (i32.eq (local.get $z) (i32.const 2)) (then (local.set $t (call $fetch16)) (if (call $cc (local.get $y)) (then (call $zw16 (i32.const 22) (local.get $t)))) (br $end)))
      (if (i32.eq (local.get $z) (i32.const 3)) (then
        (if (i32.lt_u (local.get $y) (i32.const 2)) (then (call $zw16 (i32.const 22) (call $fetch16)) (br $end)))   ;; JMP and its duplicate
        (if (i32.lt_u (local.get $y) (i32.const 4)) (then (drop (call $fetch)) (br $end)))                        ;; OUT / IN: NOP
        (if (i32.eq (local.get $y) (i32.const 4)) (then   ;; XTHL
          (local.set $t (call $zr16 (i32.const 20))) (local.set $v (call $mrd16 (local.get $t)))
          (call $mwr16 (local.get $t) (local.get $hl)) (call $zw16 (i32.const 4) (local.get $v)) (br $end)))
        (if (i32.eq (local.get $y) (i32.const 5)) (then (call $swap (i32.const 2) (i32.const 4) (i32.const 2)) (br $end)))
        (br $end)))   ;; DI / EI
      (if (i32.eq (local.get $z) (i32.const 4)) (then
        (local.set $t (call $fetch16))
        (if (call $cc (local.get $y)) (then (call $push (call $zr16 (i32.const 22))) (call $zw16 (i32.const 22) (local.get $t))))
        (br $end)))
      (if (i32.eq (local.get $z) (i32.const 5)) (then
        (if (i32.eqz (local.get $q)) (then (call $push (call $zr16 (call $rp2off (local.get $p)))) (br $end)))
        (local.set $t (call $fetch16)) (call $push (call $zr16 (i32.const 22))) (call $zw16 (i32.const 22) (local.get $t))   ;; CALL and its duplicates
        (br $end)))
      (if (i32.eq (local.get $z) (i32.const 6)) (then (call $alu80 (local.get $y) (call $fetch)) (br $end)))
      (call $push (call $zr16 (i32.const 22)))
      (call $zw16 (i32.const 22) (i32.shl (local.get $y) (i32.const 3)))))

  ;; ========================================================================
  ;; MOS 6502 byte processor. Register file: 0 A, 1 X, 2 Y, 3 S, 4 P, 22 PC.
  ;; The stack lives at $0100+S, which wraps into the same 16 bytes. All 151
  ;; documented opcodes; every undocumented opcode (the JAM/KIL halts included)
  ;; is a one-byte NOP. BRK pushes PC+2 and P and jumps through the vector at
  ;; $FFFE/$FFFF (bytes 14 and 15). Decimal mode is honoured by ADC/SBC.
  (func $nz (param $v i32)   ;; set N and Z from v, keep the rest of P
    (call $zw (i32.const 4) (i32.or (i32.and (call $zr (i32.const 4)) (i32.const 0x7D))
      (i32.or (i32.and (local.get $v) (i32.const 0x80)) (select (i32.const 2) (i32.const 0) (i32.eqz (i32.and (local.get $v) (i32.const 255))))))))
  (func $push6 (param $v i32)
    (call $mwr (i32.add (i32.const 0x100) (call $zr (i32.const 3))) (local.get $v))
    (call $zw (i32.const 3) (i32.and (i32.sub (call $zr (i32.const 3)) (i32.const 1)) (i32.const 255))))
  (func $pop6 (result i32)
    (call $zw (i32.const 3) (i32.and (i32.add (call $zr (i32.const 3)) (i32.const 1)) (i32.const 255)))
    (call $mrd (i32.add (i32.const 0x100) (call $zr (i32.const 3)))))
  ;; effective address for addressing mode bbb within group cc; mode 2 of group 1 and
  ;; mode 0 of groups 0/2 are immediate: the operand byte's own address is returned
  (func $ea6 (param $bbb i32) (param $cc i32) (param $aaa i32) (result i32)
    (local $t i32) (local $idx i32)
    ;; index register for the indexed modes: Y instead of X for STX/LDX zp,X and LDX abs,X
    (local.set $idx (call $zr (select (i32.const 2) (i32.const 1)
      (i32.and (i32.eq (local.get $cc) (i32.const 2)) (i32.or (i32.eq (local.get $aaa) (i32.const 4)) (i32.eq (local.get $aaa) (i32.const 5)))))))
    (if (i32.eq (local.get $cc) (i32.const 1)) (then
      (if (i32.eqz (local.get $bbb)) (then (return (call $mrd16 (i32.and (i32.add (call $fetch) (call $zr (i32.const 1))) (i32.const 255))))))
      (if (i32.eq (local.get $bbb) (i32.const 4)) (then (return (i32.and (i32.add (call $mrd16 (call $fetch)) (call $zr (i32.const 2))) (i32.const 0xffff)))))
      (if (i32.eq (local.get $bbb) (i32.const 6)) (then (return (i32.and (i32.add (call $fetch16) (call $zr (i32.const 2))) (i32.const 0xffff)))))
      (if (i32.eq (local.get $bbb) (i32.const 2)) (then (local.set $t (call $zr16 (i32.const 22))) (drop (call $fetch)) (return (local.get $t))))))
    (if (i32.eqz (local.get $bbb)) (then (local.set $t (call $zr16 (i32.const 22))) (drop (call $fetch)) (return (local.get $t))))
    (if (i32.eq (local.get $bbb) (i32.const 1)) (then (return (call $fetch))))
    (if (i32.eq (local.get $bbb) (i32.const 3)) (then (return (call $fetch16))))
    (if (i32.eq (local.get $bbb) (i32.const 5)) (then (return (i32.and (i32.add (call $fetch) (local.get $idx)) (i32.const 255)))))
    (i32.and (i32.add (call $fetch16) (select (local.get $idx) (call $zr (i32.const 1)) (i32.eq (local.get $cc) (i32.const 2)))) (i32.const 0xffff)))
  (func $adc6 (param $b i32)   ;; ADC with decimal mode
    (local $a i32) (local $p i32) (local $c i32) (local $r i32) (local $lo i32) (local $hi i32)
    (local.set $a (call $zr (i32.const 0))) (local.set $p (call $zr (i32.const 4))) (local.set $c (i32.and (local.get $p) (i32.const 1)))
    (local.set $r (i32.add (i32.add (local.get $a) (local.get $b)) (local.get $c)))
    (local.set $p (i32.or (i32.and (local.get $p) (i32.const 0x3C))
      (i32.or (select (i32.const 2) (i32.const 0) (i32.eqz (i32.and (local.get $r) (i32.const 255))))
              (i32.shr_u (i32.and (i32.and (i32.xor (local.get $a) (local.get $r)) (i32.xor (local.get $b) (local.get $r))) (i32.const 0x80)) (i32.const 1)))))
    (if (i32.and (local.get $p) (i32.const 8))
      (then   ;; decimal adjust
        (local.set $lo (i32.add (i32.add (i32.and (local.get $a) (i32.const 15)) (i32.and (local.get $b) (i32.const 15))) (local.get $c)))
        (if (i32.gt_u (local.get $lo) (i32.const 9)) (then (local.set $lo (i32.add (local.get $lo) (i32.const 6)))))
        (local.set $hi (i32.add (i32.add (i32.shr_u (local.get $a) (i32.const 4)) (i32.shr_u (local.get $b) (i32.const 4))) (i32.shr_u (local.get $lo) (i32.const 4))))
        (if (i32.gt_u (local.get $hi) (i32.const 9)) (then (local.set $hi (i32.add (local.get $hi) (i32.const 6)))))
        (local.set $r (i32.or (i32.shl (local.get $hi) (i32.const 4)) (i32.and (local.get $lo) (i32.const 15))))
        (local.set $p (i32.or (local.get $p) (select (i32.const 1) (i32.const 0) (i32.gt_u (local.get $hi) (i32.const 15))))))
      (else (local.set $p (i32.or (local.get $p) (i32.and (i32.shr_u (local.get $r) (i32.const 8)) (i32.const 1))))))
    (call $zw (i32.const 0) (i32.and (local.get $r) (i32.const 255)))
    (call $zw (i32.const 4) (i32.or (local.get $p) (i32.and (local.get $r) (i32.const 0x80)))))
  (func $sbc6 (param $b i32)
    (local $a i32) (local $p i32) (local $c i32) (local $r i32) (local $lo i32) (local $hi i32)
    (local.set $a (call $zr (i32.const 0))) (local.set $p (call $zr (i32.const 4))) (local.set $c (i32.xor (i32.and (local.get $p) (i32.const 1)) (i32.const 1)))
    (local.set $r (i32.sub (i32.sub (local.get $a) (local.get $b)) (local.get $c)))
    (local.set $p (i32.or (i32.and (local.get $p) (i32.const 0x3C))
      (i32.or (i32.or (select (i32.const 2) (i32.const 0) (i32.eqz (i32.and (local.get $r) (i32.const 255)))) (i32.and (local.get $r) (i32.const 0x80)))
        (i32.or (i32.shr_u (i32.and (i32.and (i32.xor (local.get $a) (local.get $b)) (i32.xor (local.get $a) (local.get $r))) (i32.const 0x80)) (i32.const 1))
                (i32.xor (i32.and (i32.shr_u (local.get $r) (i32.const 8)) (i32.const 1)) (i32.const 1))))))
    (if (i32.and (local.get $p) (i32.const 8)) (then
      (local.set $lo (i32.sub (i32.sub (i32.and (local.get $a) (i32.const 15)) (i32.and (local.get $b) (i32.const 15))) (local.get $c)))
      (if (i32.and (local.get $lo) (i32.const 0x10)) (then (local.set $lo (i32.sub (local.get $lo) (i32.const 6)))))
      (local.set $hi (i32.sub (i32.sub (i32.shr_u (local.get $a) (i32.const 4)) (i32.shr_u (local.get $b) (i32.const 4))) (i32.and (i32.shr_u (local.get $lo) (i32.const 4)) (i32.const 1))))
      (if (i32.and (local.get $hi) (i32.const 0x10)) (then (local.set $hi (i32.sub (local.get $hi) (i32.const 6)))))
      (local.set $r (i32.or (i32.shl (i32.and (local.get $hi) (i32.const 15)) (i32.const 4)) (i32.and (local.get $lo) (i32.const 15))))))
    (call $zw (i32.const 0) (i32.and (local.get $r) (i32.const 255)))
    (call $zw (i32.const 4) (local.get $p)))
  (func $cmp6 (param $a i32) (param $b i32)   ;; CMP/CPX/CPY flags
    (local $r i32)
    (local.set $r (i32.sub (local.get $a) (local.get $b)))
    (call $zw (i32.const 4) (i32.or (i32.and (call $zr (i32.const 4)) (i32.const 0x7C))
      (i32.or (i32.or (i32.and (local.get $r) (i32.const 0x80)) (select (i32.const 2) (i32.const 0) (i32.eqz (i32.and (local.get $r) (i32.const 255)))))
              (i32.ge_u (local.get $a) (local.get $b))))))
  (func $shift6 (param $aaa i32) (param $v i32) (result i32)   ;; ASL ROL LSR ROR with flags
    (local $r i32) (local $c i32) (local $p i32)
    (local.set $p (call $zr (i32.const 4)))
    (if (i32.lt_u (local.get $aaa) (i32.const 2))
      (then (local.set $c (i32.shr_u (local.get $v) (i32.const 7))) (local.set $r (i32.and (i32.or (i32.shl (local.get $v) (i32.const 1)) (select (i32.and (local.get $p) (i32.const 1)) (i32.const 0) (local.get $aaa))) (i32.const 255))))
      (else (local.set $c (i32.and (local.get $v) (i32.const 1))) (local.set $r (i32.or (i32.shr_u (local.get $v) (i32.const 1)) (select (i32.shl (i32.and (local.get $p) (i32.const 1)) (i32.const 7)) (i32.const 0) (i32.eq (local.get $aaa) (i32.const 3)))))))
    (call $zw (i32.const 4) (i32.or (i32.and (local.get $p) (i32.const 0xFE)) (local.get $c)))
    (call $nz (local.get $r))
    (local.get $r))
  (func $m6502step
    (local $op i32) (local $aaa i32) (local $bbb i32) (local $cc i32) (local $ea i32) (local $v i32) (local $t i32) (local $p i32)
    (local.set $op (call $fetch))
    (local.set $aaa (i32.shr_u (local.get $op) (i32.const 5))) (local.set $bbb (i32.and (i32.shr_u (local.get $op) (i32.const 2)) (i32.const 7))) (local.set $cc (i32.and (local.get $op) (i32.const 3)))
    (block $end
      ;; ---- group cc = 1: ORA AND EOR ADC STA LDA CMP SBC
      (if (i32.eq (local.get $cc) (i32.const 1)) (then
        (local.set $ea (call $ea6 (local.get $bbb) (i32.const 1) (local.get $aaa)))
        (if (i32.eq (local.get $aaa) (i32.const 4)) (then (call $mwr (local.get $ea) (call $zr (i32.const 0))) (br $end)))   ;; STA (STA # is a documented-NOP-ish: writes nowhere useful)
        (local.set $v (call $mrd (local.get $ea)))
        (if (i32.eq (local.get $aaa) (i32.const 5)) (then (call $zw (i32.const 0) (local.get $v)) (call $nz (local.get $v)) (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 6)) (then (call $cmp6 (call $zr (i32.const 0)) (local.get $v)) (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 3)) (then (call $adc6 (local.get $v)) (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 7)) (then (call $sbc6 (local.get $v)) (br $end)))
        (local.set $t (select (i32.or (call $zr (i32.const 0)) (local.get $v)) (select (i32.and (call $zr (i32.const 0)) (local.get $v)) (i32.xor (call $zr (i32.const 0)) (local.get $v)) (i32.eq (local.get $aaa) (i32.const 1))) (i32.eqz (local.get $aaa))))
        (call $zw (i32.const 0) (local.get $t)) (call $nz (local.get $t))
        (br $end)))
      ;; ---- group cc = 2: ASL ROL LSR ROR STX LDX DEC INC (and the implied ones in column 2 and 6)
      (if (i32.eq (local.get $cc) (i32.const 2)) (then
        (if (i32.eq (local.get $bbb) (i32.const 2)) (then
          (if (i32.lt_u (local.get $aaa) (i32.const 4)) (then (call $zw (i32.const 0) (call $shift6 (local.get $aaa) (call $zr (i32.const 0)))) (br $end)))
          (if (i32.eq (local.get $aaa) (i32.const 4)) (then (call $zw (i32.const 0) (call $zr (i32.const 1))) (call $nz (call $zr (i32.const 0))) (br $end)))   ;; TXA
          (if (i32.eq (local.get $aaa) (i32.const 5)) (then (call $zw (i32.const 1) (call $zr (i32.const 0))) (call $nz (call $zr (i32.const 1))) (br $end)))   ;; TAX
          (if (i32.eq (local.get $aaa) (i32.const 6)) (then (call $zw (i32.const 1) (i32.and (i32.sub (call $zr (i32.const 1)) (i32.const 1)) (i32.const 255))) (call $nz (call $zr (i32.const 1))) (br $end)))   ;; DEX
          (br $end)))   ;; NOP
        (if (i32.eq (local.get $bbb) (i32.const 6)) (then
          (if (i32.eq (local.get $aaa) (i32.const 4)) (then (call $zw (i32.const 3) (call $zr (i32.const 1)))))                                   ;; TXS
          (if (i32.eq (local.get $aaa) (i32.const 5)) (then (call $zw (i32.const 1) (call $zr (i32.const 3))) (call $nz (call $zr (i32.const 1)))))   ;; TSX
          (br $end)))
        (if (i32.and (i32.eqz (local.get $bbb)) (i32.ne (local.get $aaa) (i32.const 5))) (then (br $end)))   ;; only LDX has an immediate form
        (if (i32.and (i32.eq (local.get $bbb) (i32.const 4)) (i32.const 1)) (then (br $end)))                ;; column 4 is undocumented
        (local.set $ea (call $ea6 (local.get $bbb) (i32.const 2) (local.get $aaa)))
        (if (i32.eq (local.get $aaa) (i32.const 4)) (then (call $mwr (local.get $ea) (call $zr (i32.const 1))) (br $end)))   ;; STX
        (local.set $v (call $mrd (local.get $ea)))
        (if (i32.eq (local.get $aaa) (i32.const 5)) (then (call $zw (i32.const 1) (local.get $v)) (call $nz (local.get $v)) (br $end)))   ;; LDX
        (if (i32.lt_u (local.get $aaa) (i32.const 4)) (then (call $mwr (local.get $ea) (call $shift6 (local.get $aaa) (local.get $v))) (br $end)))
        (local.set $t (i32.and (i32.add (local.get $v) (select (i32.const -1) (i32.const 1) (i32.eq (local.get $aaa) (i32.const 6)))) (i32.const 255)))   ;; DEC / INC
        (call $mwr (local.get $ea) (local.get $t)) (call $nz (local.get $t))
        (br $end)))
      ;; ---- group cc = 3: undocumented -> NOP
      (if (i32.eq (local.get $cc) (i32.const 3)) (then (br $end)))
      ;; ---- group cc = 0
      (if (i32.eq (local.get $bbb) (i32.const 4)) (then   ;; branches: BPL BMI BVC BVS BCC BCS BNE BEQ
        (local.set $t (call $sext8 (call $fetch)))
        (local.set $p (call $zr (i32.const 4)))
        (local.set $v (i32.and (local.get $p) (select (i32.const 0x80) (select (i32.const 0x40) (select (i32.const 1) (i32.const 2) (i32.lt_u (local.get $aaa) (i32.const 6))) (i32.lt_u (local.get $aaa) (i32.const 4))) (i32.lt_u (local.get $aaa) (i32.const 2)))))
        (if (i32.eq (i32.ne (local.get $v) (i32.const 0)) (i32.and (local.get $aaa) (i32.const 1)))
          (then (call $zw16 (i32.const 22) (i32.and (i32.add (call $zr16 (i32.const 22)) (local.get $t)) (i32.const 0xffff)))))
        (br $end)))
      (if (i32.eq (local.get $bbb) (i32.const 6)) (then   ;; CLC SEC CLI SEI TYA CLV CLD SED
        (local.set $p (call $zr (i32.const 4)))
        (if (i32.eq (local.get $aaa) (i32.const 4)) (then (call $zw (i32.const 0) (call $zr (i32.const 2))) (call $nz (call $zr (i32.const 0))) (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 5)) (then (call $zw (i32.const 4) (i32.and (local.get $p) (i32.const 0xBF))) (br $end)))
        (local.set $t (select (i32.const 1) (select (i32.const 4) (i32.const 8) (i32.lt_u (local.get $aaa) (i32.const 4))) (i32.lt_u (local.get $aaa) (i32.const 2))))
        (call $zw (i32.const 4) (select (i32.or (local.get $p) (local.get $t)) (i32.and (local.get $p) (i32.xor (local.get $t) (i32.const 255))) (i32.and (local.get $aaa) (i32.const 1))))
        (br $end)))
      (if (i32.eq (local.get $bbb) (i32.const 2)) (then   ;; PHP PLP PHA PLA DEY TAY INY INX
        (if (i32.eqz (local.get $aaa)) (then (call $push6 (i32.or (call $zr (i32.const 4)) (i32.const 0x30))) (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 1)) (then (call $zw (i32.const 4) (i32.or (i32.and (call $pop6) (i32.const 0xCF)) (i32.const 0x20))) (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 2)) (then (call $push6 (call $zr (i32.const 0))) (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 3)) (then (call $zw (i32.const 0) (call $pop6)) (call $nz (call $zr (i32.const 0))) (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 4)) (then (call $zw (i32.const 2) (i32.and (i32.sub (call $zr (i32.const 2)) (i32.const 1)) (i32.const 255))) (call $nz (call $zr (i32.const 2))) (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 5)) (then (call $zw (i32.const 2) (call $zr (i32.const 0))) (call $nz (call $zr (i32.const 2))) (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 6)) (then (call $zw (i32.const 2) (i32.and (i32.add (call $zr (i32.const 2)) (i32.const 1)) (i32.const 255))) (call $nz (call $zr (i32.const 2))) (br $end)))
        (call $zw (i32.const 1) (i32.and (i32.add (call $zr (i32.const 1)) (i32.const 1)) (i32.const 255))) (call $nz (call $zr (i32.const 1)))
        (br $end)))
      (if (i32.eqz (local.get $bbb)) (then
        (if (i32.eqz (local.get $aaa)) (then   ;; BRK
          (local.set $t (i32.and (i32.add (call $zr16 (i32.const 22)) (i32.const 1)) (i32.const 0xffff)))
          (call $push6 (i32.shr_u (local.get $t) (i32.const 8))) (call $push6 (i32.and (local.get $t) (i32.const 255)))
          (call $push6 (i32.or (call $zr (i32.const 4)) (i32.const 0x30)))
          (call $zw (i32.const 4) (i32.or (call $zr (i32.const 4)) (i32.const 4)))
          (call $zw16 (i32.const 22) (call $mrd16 (i32.const 0xFFFE)))
          (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 1)) (then   ;; JSR
          (local.set $t (call $fetch16))
          (local.set $v (i32.and (i32.sub (call $zr16 (i32.const 22)) (i32.const 1)) (i32.const 0xffff)))
          (call $push6 (i32.shr_u (local.get $v) (i32.const 8))) (call $push6 (i32.and (local.get $v) (i32.const 255)))
          (call $zw16 (i32.const 22) (local.get $t))
          (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 2)) (then   ;; RTI
          (call $zw (i32.const 4) (i32.or (i32.and (call $pop6) (i32.const 0xCF)) (i32.const 0x20)))
          (local.set $t (call $pop6)) (call $zw16 (i32.const 22) (i32.or (local.get $t) (i32.shl (call $pop6) (i32.const 8))))
          (br $end)))
        (if (i32.eq (local.get $aaa) (i32.const 3)) (then   ;; RTS
          (local.set $t (call $pop6)) (call $zw16 (i32.const 22) (i32.and (i32.add (i32.or (local.get $t) (i32.shl (call $pop6) (i32.const 8))) (i32.const 1)) (i32.const 0xffff)))
          (br $end)))
        (if (i32.lt_u (local.get $aaa) (i32.const 5)) (then (br $end)))))   ;; $80 undocumented NOP
      (if (i32.and (i32.eq (local.get $bbb) (i32.const 3)) (i32.or (i32.eq (local.get $aaa) (i32.const 2)) (i32.eq (local.get $aaa) (i32.const 3)))) (then   ;; JMP abs / JMP (ind)
        (local.set $t (call $fetch16))
        (call $zw16 (i32.const 22) (select (local.get $t) (call $mrd16 (local.get $t)) (i32.eq (local.get $aaa) (i32.const 2))))
        (br $end)))
      (if (i32.and (i32.or (i32.eq (local.get $bbb) (i32.const 5)) (i32.eq (local.get $bbb) (i32.const 7))) (i32.and (i32.ne (local.get $aaa) (i32.const 4)) (i32.ne (local.get $aaa) (i32.const 5)))) (then (br $end)))   ;; undocumented
      (if (i32.and (i32.eq (local.get $bbb) (i32.const 7)) (i32.eq (local.get $aaa) (i32.const 4))) (then (br $end)))   ;; $9C undocumented
      (if (i32.lt_u (local.get $aaa) (i32.const 4)) (then   ;; only BIT remains here (aaa = 1, zp or abs)
        (if (i32.ne (local.get $aaa) (i32.const 1)) (then (br $end)))
        (local.set $v (call $mrd (call $ea6 (local.get $bbb) (i32.const 0) (local.get $aaa))))
        (call $zw (i32.const 4) (i32.or (i32.and (call $zr (i32.const 4)) (i32.const 0x3D))
          (i32.or (i32.and (local.get $v) (i32.const 0xC0)) (select (i32.const 2) (i32.const 0) (i32.eqz (i32.and (local.get $v) (call $zr (i32.const 0))))))))
        (br $end)))
      (local.set $ea (call $ea6 (local.get $bbb) (i32.const 0) (local.get $aaa)))
      (if (i32.eq (local.get $aaa) (i32.const 4)) (then (call $mwr (local.get $ea) (call $zr (i32.const 2))) (br $end)))   ;; STY
      (local.set $v (call $mrd (local.get $ea)))
      (if (i32.eq (local.get $aaa) (i32.const 5)) (then (call $zw (i32.const 2) (local.get $v)) (call $nz (local.get $v)) (br $end)))   ;; LDY
      (call $cmp6 (call $zr (select (i32.const 2) (i32.const 1) (i32.eq (local.get $aaa) (i32.const 6)))) (local.get $v))))   ;; CPY / CPX

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
  ;; ========================================================================
  ;; Subleq (kind 9): one instruction, three byte operands a b c at PC.
  ;; mem[b] -= mem[a]; if the result is <= 0 (signed byte) jump to c, else PC += 3.
  (func $subleq_step
    (local $pc i32) (local $a i32) (local $b i32) (local $c i32) (local $v i32)
    (local.set $pc (call $zr16 (i32.const 22)))
    (local.set $a (call $mrd (local.get $pc))) (local.set $b (call $mrd (i32.add (local.get $pc) (i32.const 1)))) (local.set $c (call $mrd (i32.add (local.get $pc) (i32.const 2))))
    (local.set $v (i32.and (i32.sub (call $mrd (local.get $b)) (call $mrd (local.get $a))) (i32.const 255)))
    (call $mwr (local.get $b) (local.get $v))
    (call $zw16 (i32.const 22) (i32.and
      (select (local.get $c) (i32.add (local.get $pc) (i32.const 3)) (i32.or (i32.eqz (local.get $v)) (i32.and (local.get $v) (i32.const 0x80))))
      (i32.const 0xffff))))

  ;; ========================================================================
  ;; CHIP-8 (kind 10). Register file: V0..VF at 0..15, I at 16 (u16), PC at 22,
  ;; SP at 24, delay timer 26, sound timer 27, xorshift state at 28 (u32), stack
  ;; (16 x u16) at 32. Big-endian 2-byte instructions, PC starts at 0. There is
  ;; no display and no keypad: 00E0 and DXYN do nothing (VF cleared), EX9E never
  ;; skips, EXA1 always skips, FX0A (wait for key) is a NOP.
  (func $chip8_step
    (local $pc i32) (local $op i32) (local $x i32) (local $y i32) (local $n i32) (local $nn i32) (local $nnn i32) (local $vx i32) (local $vy i32) (local $t i32) (local $i i32)
    (local.set $pc (call $zr16 (i32.const 22)))
    (local.set $op (i32.or (i32.shl (call $mrd (local.get $pc)) (i32.const 8)) (call $mrd (i32.add (local.get $pc) (i32.const 1)))))
    (local.set $pc (i32.and (i32.add (local.get $pc) (i32.const 2)) (i32.const 0xffff)))
    (local.set $x (i32.and (i32.shr_u (local.get $op) (i32.const 8)) (i32.const 15))) (local.set $y (i32.and (i32.shr_u (local.get $op) (i32.const 4)) (i32.const 15)))
    (local.set $n (i32.and (local.get $op) (i32.const 15))) (local.set $nn (i32.and (local.get $op) (i32.const 255))) (local.set $nnn (i32.and (local.get $op) (i32.const 0xfff)))
    (local.set $vx (call $zr (local.get $x))) (local.set $vy (call $zr (local.get $y)))
    ;; timers tick once per instruction
    (if (call $zr (i32.const 26)) (then (call $zw (i32.const 26) (i32.sub (call $zr (i32.const 26)) (i32.const 1)))))
    (if (call $zr (i32.const 27)) (then (call $zw (i32.const 27) (i32.sub (call $zr (i32.const 27)) (i32.const 1)))))
    (block $end
      (local.set $t (i32.shr_u (local.get $op) (i32.const 12)))
      (if (i32.eqz (local.get $t)) (then
        (if (i32.eq (local.get $op) (i32.const 0x00EE)) (then   ;; RET
          (call $zw (i32.const 24) (i32.and (i32.sub (call $zr (i32.const 24)) (i32.const 1)) (i32.const 15)))
          (local.set $pc (call $zr16 (i32.add (i32.const 32) (i32.shl (call $zr (i32.const 24)) (i32.const 1)))))))
        (br $end)))
      (if (i32.eq (local.get $t) (i32.const 1)) (then (local.set $pc (local.get $nnn)) (br $end)))
      (if (i32.eq (local.get $t) (i32.const 2)) (then   ;; CALL
        (call $zw16 (i32.add (i32.const 32) (i32.shl (call $zr (i32.const 24)) (i32.const 1))) (local.get $pc))
        (call $zw (i32.const 24) (i32.and (i32.add (call $zr (i32.const 24)) (i32.const 1)) (i32.const 15)))
        (local.set $pc (local.get $nnn)) (br $end)))
      (if (i32.eq (local.get $t) (i32.const 3)) (then (if (i32.eq (local.get $vx) (local.get $nn)) (then (local.set $pc (i32.add (local.get $pc) (i32.const 2))))) (br $end)))
      (if (i32.eq (local.get $t) (i32.const 4)) (then (if (i32.ne (local.get $vx) (local.get $nn)) (then (local.set $pc (i32.add (local.get $pc) (i32.const 2))))) (br $end)))
      (if (i32.eq (local.get $t) (i32.const 5)) (then (if (i32.eq (local.get $vx) (local.get $vy)) (then (local.set $pc (i32.add (local.get $pc) (i32.const 2))))) (br $end)))
      (if (i32.eq (local.get $t) (i32.const 6)) (then (call $zw (local.get $x) (local.get $nn)) (br $end)))
      (if (i32.eq (local.get $t) (i32.const 7)) (then (call $zw (local.get $x) (i32.and (i32.add (local.get $vx) (local.get $nn)) (i32.const 255))) (br $end)))
      (if (i32.eq (local.get $t) (i32.const 8)) (then
        (if (i32.eqz (local.get $n)) (then (call $zw (local.get $x) (local.get $vy)) (br $end)))
        (if (i32.eq (local.get $n) (i32.const 1)) (then (call $zw (local.get $x) (i32.or (local.get $vx) (local.get $vy))) (br $end)))
        (if (i32.eq (local.get $n) (i32.const 2)) (then (call $zw (local.get $x) (i32.and (local.get $vx) (local.get $vy))) (br $end)))
        (if (i32.eq (local.get $n) (i32.const 3)) (then (call $zw (local.get $x) (i32.xor (local.get $vx) (local.get $vy))) (br $end)))
        (if (i32.eq (local.get $n) (i32.const 4)) (then (local.set $i (i32.add (local.get $vx) (local.get $vy))) (call $zw (local.get $x) (i32.and (local.get $i) (i32.const 255))) (call $zw (i32.const 15) (i32.shr_u (local.get $i) (i32.const 8))) (br $end)))
        (if (i32.eq (local.get $n) (i32.const 5)) (then (call $zw (local.get $x) (i32.and (i32.sub (local.get $vx) (local.get $vy)) (i32.const 255))) (call $zw (i32.const 15) (i32.ge_u (local.get $vx) (local.get $vy))) (br $end)))
        (if (i32.eq (local.get $n) (i32.const 6)) (then (call $zw (local.get $x) (i32.shr_u (local.get $vx) (i32.const 1))) (call $zw (i32.const 15) (i32.and (local.get $vx) (i32.const 1))) (br $end)))
        (if (i32.eq (local.get $n) (i32.const 7)) (then (call $zw (local.get $x) (i32.and (i32.sub (local.get $vy) (local.get $vx)) (i32.const 255))) (call $zw (i32.const 15) (i32.ge_u (local.get $vy) (local.get $vx))) (br $end)))
        (if (i32.eq (local.get $n) (i32.const 14)) (then (call $zw (local.get $x) (i32.and (i32.shl (local.get $vx) (i32.const 1)) (i32.const 255))) (call $zw (i32.const 15) (i32.shr_u (local.get $vx) (i32.const 7))) (br $end)))
        (br $end)))
      (if (i32.eq (local.get $t) (i32.const 9)) (then (if (i32.ne (local.get $vx) (local.get $vy)) (then (local.set $pc (i32.add (local.get $pc) (i32.const 2))))) (br $end)))
      (if (i32.eq (local.get $t) (i32.const 10)) (then (call $zw16 (i32.const 16) (local.get $nnn)) (br $end)))
      (if (i32.eq (local.get $t) (i32.const 11)) (then (local.set $pc (i32.add (local.get $nnn) (call $zr (i32.const 0)))) (br $end)))
      (if (i32.eq (local.get $t) (i32.const 12)) (then   ;; CXNN: xorshift32
        (local.set $i (i32.load offset=284 (i32.const 0)))
        (if (i32.eqz (local.get $i)) (then (local.set $i (i32.const 0x2545F491))))
        (local.set $i (i32.xor (local.get $i) (i32.shl (local.get $i) (i32.const 13)))) (local.set $i (i32.xor (local.get $i) (i32.shr_u (local.get $i) (i32.const 17)))) (local.set $i (i32.xor (local.get $i) (i32.shl (local.get $i) (i32.const 5))))
        (i32.store offset=284 (i32.const 0) (local.get $i))
        (call $zw (local.get $x) (i32.and (i32.and (local.get $i) (i32.const 255)) (local.get $nn))) (br $end)))
      (if (i32.eq (local.get $t) (i32.const 13)) (then (call $zw (i32.const 15) (i32.const 0)) (br $end)))   ;; DXYN: no display
      (if (i32.eq (local.get $t) (i32.const 14)) (then (if (i32.eq (local.get $nn) (i32.const 0xA1)) (then (local.set $pc (i32.add (local.get $pc) (i32.const 2))))) (br $end)))
      ;; F
      (if (i32.eq (local.get $nn) (i32.const 0x07)) (then (call $zw (local.get $x) (call $zr (i32.const 26))) (br $end)))
      (if (i32.eq (local.get $nn) (i32.const 0x15)) (then (call $zw (i32.const 26) (local.get $vx)) (br $end)))
      (if (i32.eq (local.get $nn) (i32.const 0x18)) (then (call $zw (i32.const 27) (local.get $vx)) (br $end)))
      (if (i32.eq (local.get $nn) (i32.const 0x1E)) (then (call $zw16 (i32.const 16) (i32.and (i32.add (call $zr16 (i32.const 16)) (local.get $vx)) (i32.const 0xffff))) (br $end)))
      (if (i32.eq (local.get $nn) (i32.const 0x29)) (then (call $zw16 (i32.const 16) (i32.mul (i32.and (local.get $vx) (i32.const 15)) (i32.const 5))) (br $end)))
      (if (i32.eq (local.get $nn) (i32.const 0x33)) (then   ;; BCD
        (local.set $i (call $zr16 (i32.const 16)))
        (call $mwr (local.get $i) (i32.div_u (local.get $vx) (i32.const 100)))
        (call $mwr (i32.add (local.get $i) (i32.const 1)) (i32.rem_u (i32.div_u (local.get $vx) (i32.const 10)) (i32.const 10)))
        (call $mwr (i32.add (local.get $i) (i32.const 2)) (i32.rem_u (local.get $vx) (i32.const 10)))
        (br $end)))
      (if (i32.or (i32.eq (local.get $nn) (i32.const 0x55)) (i32.eq (local.get $nn) (i32.const 0x65))) (then
        (local.set $i (i32.const 0))
        (block $le (loop $ll (br_if $le (i32.gt_u (local.get $i) (local.get $x)))
          (if (i32.eq (local.get $nn) (i32.const 0x55))
            (then (call $mwr (i32.add (call $zr16 (i32.const 16)) (local.get $i)) (call $zr (local.get $i))))
            (else (call $zw (local.get $i) (call $mrd (i32.add (call $zr16 (i32.const 16)) (local.get $i))))))
          (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $ll)))
        (br $end))))
    (call $zw16 (i32.const 22) (i32.and (local.get $pc) (i32.const 0xffff))))

  ;; ========================================================================
  ;; Intel 4004 (kind 11). 4-bit accumulator at 0, carry at 1, index registers
  ;; R0..R15 (one nibble each) at 2..17, SRC address at 18, stack level at 19,
  ;; the 3-level stack (u16) at 32, PC (12-bit) at 22. The 16 bytes are both the
  ;; ROM (8-bit instructions, PC mod 16) and the RAM: 32 nibbles, nibble n in the
  ;; low (even n) or high (odd n) half of byte n/2, addressed by SRC mod 32.
  ;; Output/status-character instructions and DCL do nothing; TEST reads 0.
  (func $ram4 (param $n i32) (result i32)
    (local $b i32) (local.set $b (call $mrd (i32.shr_u (i32.and (local.get $n) (i32.const 31)) (i32.const 1))))
    (select (i32.shr_u (local.get $b) (i32.const 4)) (i32.and (local.get $b) (i32.const 15)) (i32.and (local.get $n) (i32.const 1))))
  (func $ram4w (param $n i32) (param $v i32)
    (local $a i32) (local $b i32)
    (local.set $a (i32.shr_u (i32.and (local.get $n) (i32.const 31)) (i32.const 1))) (local.set $b (call $mrd (local.get $a)))
    (call $mwr (local.get $a) (select
      (i32.or (i32.and (local.get $b) (i32.const 15)) (i32.shl (local.get $v) (i32.const 4)))
      (i32.or (i32.and (local.get $b) (i32.const 0xF0)) (local.get $v))
      (i32.and (local.get $n) (i32.const 1)))))
  (func $acc4add (param $v i32)   ;; acc += v (v already includes carry-in); carry out
    (local $r i32) (local.set $r (i32.add (call $zr (i32.const 0)) (local.get $v)))
    (call $zw (i32.const 0) (i32.and (local.get $r) (i32.const 15))) (call $zw (i32.const 1) (i32.shr_u (local.get $r) (i32.const 4))))
  (func $i4004_step
    (local $pc i32) (local $op i32) (local $hi i32) (local $lo i32) (local $t i32) (local $acc i32) (local $cy i32) (local $r i32)
    (local.set $pc (call $zr16 (i32.const 22)))
    (local.set $op (call $mrd (local.get $pc))) (local.set $pc (i32.and (i32.add (local.get $pc) (i32.const 1)) (i32.const 0xfff)))
    (local.set $hi (i32.shr_u (local.get $op) (i32.const 4))) (local.set $lo (i32.and (local.get $op) (i32.const 15)))
    (local.set $acc (call $zr (i32.const 0))) (local.set $cy (call $zr (i32.const 1)))
    (block $end
      (if (i32.eqz (local.get $hi)) (then (br $end)))   ;; NOP
      (if (i32.eq (local.get $hi) (i32.const 1)) (then   ;; JCN
        (local.set $t (call $mrd (local.get $pc))) (local.set $pc (i32.and (i32.add (local.get $pc) (i32.const 1)) (i32.const 0xfff)))
        (local.set $r (i32.or (i32.or (i32.and (i32.eqz (local.get $acc)) (i32.shr_u (i32.and (local.get $lo) (i32.const 4)) (i32.const 2)))
                                      (i32.and (local.get $cy) (i32.shr_u (i32.and (local.get $lo) (i32.const 2)) (i32.const 1))))
                              (i32.and (local.get $lo) (i32.const 1))))   ;; TEST pin is 0, so the "test = 0" condition holds
        (if (i32.xor (i32.ne (local.get $r) (i32.const 0)) (i32.shr_u (local.get $lo) (i32.const 3)))
          (then (local.set $pc (i32.or (i32.and (local.get $pc) (i32.const 0xf00)) (local.get $t)))))
        (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 2)) (then
        (local.set $r (i32.add (i32.const 2) (i32.and (local.get $lo) (i32.const 14))))   ;; register pair base
        (if (i32.and (local.get $lo) (i32.const 1))
          (then (call $zw (i32.const 18) (i32.or (i32.shl (call $zr (local.get $r)) (i32.const 4)) (call $zr (i32.add (local.get $r) (i32.const 1))))))   ;; SRC
          (else (local.set $t (call $mrd (local.get $pc))) (local.set $pc (i32.and (i32.add (local.get $pc) (i32.const 1)) (i32.const 0xfff)))      ;; FIM
                (call $zw (local.get $r) (i32.shr_u (local.get $t) (i32.const 4))) (call $zw (i32.add (local.get $r) (i32.const 1)) (i32.and (local.get $t) (i32.const 15)))))
        (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 3)) (then
        (local.set $r (i32.add (i32.const 2) (i32.and (local.get $lo) (i32.const 14))))
        (if (i32.and (local.get $lo) (i32.const 1))
          (then (local.set $pc (i32.or (i32.and (local.get $pc) (i32.const 0xf00)) (i32.or (i32.shl (call $zr (local.get $r)) (i32.const 4)) (call $zr (i32.add (local.get $r) (i32.const 1)))))))   ;; JIN
          (else (local.set $t (call $mrd (i32.or (i32.and (local.get $pc) (i32.const 0xf00)) (i32.or (i32.shl (call $zr (i32.const 2)) (i32.const 4)) (call $zr (i32.const 3))))))   ;; FIN
                (call $zw (local.get $r) (i32.shr_u (local.get $t) (i32.const 4))) (call $zw (i32.add (local.get $r) (i32.const 1)) (i32.and (local.get $t) (i32.const 15)))))
        (br $end)))
      (if (i32.or (i32.eq (local.get $hi) (i32.const 4)) (i32.eq (local.get $hi) (i32.const 5))) (then   ;; JUN / JMS
        (local.set $t (i32.or (i32.shl (local.get $lo) (i32.const 8)) (call $mrd (local.get $pc)))) (local.set $pc (i32.and (i32.add (local.get $pc) (i32.const 1)) (i32.const 0xfff)))
        (if (i32.eq (local.get $hi) (i32.const 5)) (then
          (call $zw16 (i32.add (i32.const 32) (i32.shl (call $zr (i32.const 19)) (i32.const 1))) (local.get $pc))
          (call $zw (i32.const 19) (i32.rem_u (i32.add (call $zr (i32.const 19)) (i32.const 1)) (i32.const 3)))))
        (local.set $pc (local.get $t)) (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 6)) (then (call $zw (i32.add (i32.const 2) (local.get $lo)) (i32.and (i32.add (call $zr (i32.add (i32.const 2) (local.get $lo))) (i32.const 1)) (i32.const 15))) (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 7)) (then   ;; ISZ
        (local.set $t (call $mrd (local.get $pc))) (local.set $pc (i32.and (i32.add (local.get $pc) (i32.const 1)) (i32.const 0xfff)))
        (local.set $r (i32.and (i32.add (call $zr (i32.add (i32.const 2) (local.get $lo))) (i32.const 1)) (i32.const 15)))
        (call $zw (i32.add (i32.const 2) (local.get $lo)) (local.get $r))
        (if (local.get $r) (then (local.set $pc (i32.or (i32.and (local.get $pc) (i32.const 0xf00)) (local.get $t)))))
        (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 8)) (then (call $acc4add (i32.add (call $zr (i32.add (i32.const 2) (local.get $lo))) (local.get $cy))) (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 9)) (then (call $acc4add (i32.add (i32.xor (call $zr (i32.add (i32.const 2) (local.get $lo))) (i32.const 15)) (i32.xor (local.get $cy) (i32.const 1)))) (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 10)) (then (call $zw (i32.const 0) (call $zr (i32.add (i32.const 2) (local.get $lo)))) (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 11)) (then (call $zw (i32.const 0) (call $zr (i32.add (i32.const 2) (local.get $lo)))) (call $zw (i32.add (i32.const 2) (local.get $lo)) (local.get $acc)) (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 12)) (then   ;; BBL
        (call $zw (i32.const 19) (i32.rem_u (i32.add (call $zr (i32.const 19)) (i32.const 2)) (i32.const 3)))
        (local.set $pc (call $zr16 (i32.add (i32.const 32) (i32.shl (call $zr (i32.const 19)) (i32.const 1)))))
        (call $zw (i32.const 0) (local.get $lo)) (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 13)) (then (call $zw (i32.const 0) (local.get $lo)) (br $end)))
      (if (i32.eq (local.get $hi) (i32.const 14)) (then   ;; RAM group
        (local.set $t (call $zr (i32.const 18)))
        (if (i32.eqz (local.get $lo)) (then (call $ram4w (local.get $t) (local.get $acc))))                                                 ;; WRM
        (if (i32.eq (local.get $lo) (i32.const 8)) (then (call $acc4add (i32.add (i32.xor (call $ram4 (local.get $t)) (i32.const 15)) (i32.xor (local.get $cy) (i32.const 1))))))   ;; SBM
        (if (i32.eq (local.get $lo) (i32.const 9)) (then (call $zw (i32.const 0) (call $ram4 (local.get $t)))))                              ;; RDM
        (if (i32.eq (local.get $lo) (i32.const 11)) (then (call $acc4add (i32.add (call $ram4 (local.get $t)) (local.get $cy)))))            ;; ADM
        (br $end)))
      ;; accumulator group (F)
      (if (i32.eqz (local.get $lo)) (then (call $zw (i32.const 0) (i32.const 0)) (call $zw (i32.const 1) (i32.const 0)) (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 1)) (then (call $zw (i32.const 1) (i32.const 0)) (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 2)) (then (call $acc4add (i32.const 1)) (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 3)) (then (call $zw (i32.const 1) (i32.xor (local.get $cy) (i32.const 1))) (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 4)) (then (call $zw (i32.const 0) (i32.xor (local.get $acc) (i32.const 15))) (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 5)) (then (call $zw (i32.const 0) (i32.and (i32.or (i32.shl (local.get $acc) (i32.const 1)) (local.get $cy)) (i32.const 15))) (call $zw (i32.const 1) (i32.shr_u (local.get $acc) (i32.const 3))) (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 6)) (then (call $zw (i32.const 0) (i32.or (i32.shr_u (local.get $acc) (i32.const 1)) (i32.shl (local.get $cy) (i32.const 3)))) (call $zw (i32.const 1) (i32.and (local.get $acc) (i32.const 1))) (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 7)) (then (call $zw (i32.const 0) (local.get $cy)) (call $zw (i32.const 1) (i32.const 0)) (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 8)) (then (call $zw (i32.const 0) (i32.and (i32.sub (local.get $acc) (i32.const 1)) (i32.const 15))) (call $zw (i32.const 1) (i32.ne (local.get $acc) (i32.const 0))) (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 9)) (then (call $zw (i32.const 0) (select (i32.const 10) (i32.const 9) (local.get $cy))) (call $zw (i32.const 1) (i32.const 0)) (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 10)) (then (call $zw (i32.const 1) (i32.const 1)) (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 11)) (then   ;; DAA
        (if (i32.or (i32.gt_u (local.get $acc) (i32.const 9)) (local.get $cy)) (then
          (local.set $r (i32.add (local.get $acc) (i32.const 6)))
          (call $zw (i32.const 0) (i32.and (local.get $r) (i32.const 15)))
          (if (i32.gt_u (local.get $r) (i32.const 15)) (then (call $zw (i32.const 1) (i32.const 1))))))
        (br $end)))
      (if (i32.eq (local.get $lo) (i32.const 12)) (then   ;; KBP
        (call $zw (i32.const 0) (select (local.get $acc) (select (i32.const 3) (select (i32.const 4) (i32.const 15) (i32.eq (local.get $acc) (i32.const 8))) (i32.eq (local.get $acc) (i32.const 4))) (i32.lt_u (local.get $acc) (i32.const 3))))
        (br $end))))
    (call $zw16 (i32.const 22) (local.get $pc)))

  ;; ========================================================================
  ;; Game Boy SM83 (kind 12). Register file as the 8080/Z80 (C B E D L H F A at
  ;; 0..7, SP 20, PC 22); flags Z 0x80 N 0x40 H 0x20 C 0x10. HALT and STOP are
  ;; NOPs, DI/EI do nothing, invalid opcodes are NOPs, LDH/LD (C) addresses wrap
  ;; into the 16 bytes like everything else.
  (func $gbf (param $z i32) (param $n i32) (param $h i32) (param $c i32) (result i32)
    (i32.or (i32.or (select (i32.const 0x80) (i32.const 0) (local.get $z)) (select (i32.const 0x40) (i32.const 0) (local.get $n)))
            (i32.or (select (i32.const 0x20) (i32.const 0) (local.get $h)) (select (i32.const 0x10) (i32.const 0) (local.get $c)))))
  (func $alu_gb (param $op i32) (param $b i32)
    (local $a i32) (local $r i32) (local $c i32)
    (local.set $a (call $zr (i32.const 7))) (local.set $c (i32.and (i32.shr_u (call $zr (i32.const 6)) (i32.const 4)) (i32.const 1)))
    (if (i32.lt_u (local.get $op) (i32.const 2)) (then
      (if (i32.eqz (local.get $op)) (then (local.set $c (i32.const 0))))
      (local.set $r (i32.add (i32.add (local.get $a) (local.get $b)) (local.get $c)))
      (call $zw (i32.const 7) (i32.and (local.get $r) (i32.const 255)))
      (call $zw (i32.const 6) (call $gbf (i32.eqz (i32.and (local.get $r) (i32.const 255))) (i32.const 0)
        (i32.gt_u (i32.add (i32.add (i32.and (local.get $a) (i32.const 15)) (i32.and (local.get $b) (i32.const 15))) (local.get $c)) (i32.const 15)) (i32.gt_u (local.get $r) (i32.const 255))))
      (return)))
    (if (i32.or (i32.lt_u (local.get $op) (i32.const 4)) (i32.eq (local.get $op) (i32.const 7))) (then
      (if (i32.ne (local.get $op) (i32.const 3)) (then (local.set $c (i32.const 0))))
      (local.set $r (i32.sub (i32.sub (local.get $a) (local.get $b)) (local.get $c)))
      (if (i32.ne (local.get $op) (i32.const 7)) (then (call $zw (i32.const 7) (i32.and (local.get $r) (i32.const 255)))))
      (call $zw (i32.const 6) (call $gbf (i32.eqz (i32.and (local.get $r) (i32.const 255))) (i32.const 1)
        (i32.lt_s (i32.sub (i32.sub (i32.and (local.get $a) (i32.const 15)) (i32.and (local.get $b) (i32.const 15))) (local.get $c)) (i32.const 0)) (i32.lt_s (local.get $r) (i32.const 0))))
      (return)))
    (local.set $r (select (i32.and (local.get $a) (local.get $b)) (select (i32.xor (local.get $a) (local.get $b)) (i32.or (local.get $a) (local.get $b)) (i32.eq (local.get $op) (i32.const 5))) (i32.eq (local.get $op) (i32.const 4))))
    (call $zw (i32.const 7) (local.get $r))
    (call $zw (i32.const 6) (call $gbf (i32.eqz (local.get $r)) (i32.const 0) (i32.eq (local.get $op) (i32.const 4)) (i32.const 0))))
  (func $rot_gb (param $op i32) (param $v i32) (result i32)   ;; 0 RLC 1 RRC 2 RL 3 RR 4 SLA 5 SRA 6 SWAP 7 SRL; sets Z and C
    (local $r i32) (local $c i32) (local $cf i32)
    (local.set $cf (i32.and (i32.shr_u (call $zr (i32.const 6)) (i32.const 4)) (i32.const 1)))
    (if (i32.eq (local.get $op) (i32.const 6))
      (then (local.set $r (i32.or (i32.shr_u (local.get $v) (i32.const 4)) (i32.shl (i32.and (local.get $v) (i32.const 15)) (i32.const 4)))) (local.set $c (i32.const 0)))
      (else
        (local.set $c (select (i32.and (local.get $v) (i32.const 1)) (i32.shr_u (local.get $v) (i32.const 7)) (i32.and (local.get $op) (i32.const 1))))
        (local.set $r (select (i32.or (i32.shl (local.get $v) (i32.const 1)) (i32.shr_u (local.get $v) (i32.const 7)))
          (select (i32.or (i32.shr_u (local.get $v) (i32.const 1)) (i32.shl (local.get $v) (i32.const 7)))
          (select (i32.or (i32.shl (local.get $v) (i32.const 1)) (local.get $cf))
          (select (i32.or (i32.shr_u (local.get $v) (i32.const 1)) (i32.shl (local.get $cf) (i32.const 7)))
          (select (i32.shl (local.get $v) (i32.const 1))
          (select (i32.or (i32.shr_u (local.get $v) (i32.const 1)) (i32.and (local.get $v) (i32.const 0x80)))
                  (i32.shr_u (local.get $v) (i32.const 1))
          (i32.eq (local.get $op) (i32.const 5))) (i32.eq (local.get $op) (i32.const 4))) (i32.eq (local.get $op) (i32.const 3))) (i32.eq (local.get $op) (i32.const 2))) (i32.eq (local.get $op) (i32.const 1))) (i32.eqz (local.get $op))))))
    (local.set $r (i32.and (local.get $r) (i32.const 255)))
    (call $zw (i32.const 6) (call $gbf (i32.eqz (local.get $r)) (i32.const 0) (i32.const 0) (local.get $c)))
    (local.get $r))
  (func $cc_gb (param $y i32) (result i32)   ;; NZ Z NC C
    (local $f i32) (local.set $f (call $zr (i32.const 6)))
    (i32.eq (i32.ne (i32.and (local.get $f) (select (i32.const 0x80) (i32.const 0x10) (i32.lt_u (local.get $y) (i32.const 2)))) (i32.const 0)) (i32.and (local.get $y) (i32.const 1))))
  (func $sm83_step
    (local $op i32) (local $x i32) (local $y i32) (local $z i32) (local $p i32) (local $q i32) (local $t i32) (local $v i32) (local $hl i32) (local $f i32) (local $sp i32) (local $e i32)
    (local.set $op (call $fetch))
    (local.set $x (i32.shr_u (local.get $op) (i32.const 6))) (local.set $y (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 7)))
    (local.set $z (i32.and (local.get $op) (i32.const 7))) (local.set $p (i32.shr_u (local.get $y) (i32.const 1))) (local.set $q (i32.and (local.get $y) (i32.const 1)))
    (local.set $hl (call $zr16 (i32.const 4))) (local.set $f (call $zr (i32.const 6)))
    (block $end
      (if (i32.eq (local.get $x) (i32.const 1)) (then
        (if (i32.eq (local.get $op) (i32.const 0x76)) (then (br $end)))
        (call $setr (local.get $y) (local.get $hl) (call $getr (local.get $z) (local.get $hl))) (br $end)))
      (if (i32.eq (local.get $x) (i32.const 2)) (then (call $alu_gb (local.get $y) (call $getr (local.get $z) (local.get $hl))) (br $end)))
      (if (i32.eqz (local.get $x)) (then
        (if (i32.eqz (local.get $z)) (then
          (if (i32.eq (local.get $y) (i32.const 1)) (then (call $mwr16 (call $fetch16) (call $zr16 (i32.const 20))) (br $end)))   ;; LD (nn),SP
          (if (i32.lt_u (local.get $y) (i32.const 3)) (then (br $end)))   ;; NOP, STOP
          (local.set $e (call $sext8 (call $fetch)))
          (if (i32.or (i32.eq (local.get $y) (i32.const 3)) (call $cc_gb (i32.sub (local.get $y) (i32.const 4))))
            (then (call $zw16 (i32.const 22) (i32.and (i32.add (call $zr16 (i32.const 22)) (local.get $e)) (i32.const 0xffff)))))
          (br $end)))
        (if (i32.eq (local.get $z) (i32.const 1)) (then
          (if (local.get $q)
            (then   ;; ADD HL,rp: N 0, H from bit 11, C from bit 15, Z kept
              (local.set $v (call $zr16 (call $rpoff (local.get $p)))) (local.set $t (i32.add (local.get $hl) (local.get $v)))
              (call $zw16 (i32.const 4) (i32.and (local.get $t) (i32.const 0xffff)))
              (call $zw (i32.const 6) (i32.or (i32.and (local.get $f) (i32.const 0x80)) (call $gbf (i32.const 0) (i32.const 0)
                (i32.gt_u (i32.add (i32.and (local.get $hl) (i32.const 0xfff)) (i32.and (local.get $v) (i32.const 0xfff))) (i32.const 0xfff)) (i32.gt_u (local.get $t) (i32.const 0xffff))))))
            (else (call $zw16 (call $rpoff (local.get $p)) (call $fetch16))))
          (br $end)))
        (if (i32.eq (local.get $z) (i32.const 2)) (then   ;; (BC) (DE) (HL+) (HL-)
          (local.set $t (select (call $zr16 (i32.const 0)) (select (call $zr16 (i32.const 2)) (local.get $hl) (i32.eq (local.get $p) (i32.const 1))) (i32.eqz (local.get $p))))
          (if (local.get $q) (then (call $zw (i32.const 7) (call $mrd (local.get $t)))) (else (call $mwr (local.get $t) (call $zr (i32.const 7)))))
          (if (i32.eq (local.get $p) (i32.const 2)) (then (call $zw16 (i32.const 4) (i32.and (i32.add (local.get $hl) (i32.const 1)) (i32.const 0xffff)))))
          (if (i32.eq (local.get $p) (i32.const 3)) (then (call $zw16 (i32.const 4) (i32.and (i32.sub (local.get $hl) (i32.const 1)) (i32.const 0xffff)))))
          (br $end)))
        (if (i32.eq (local.get $z) (i32.const 3)) (then
          (local.set $t (call $rpoff (local.get $p)))
          (call $zw16 (local.get $t) (i32.and (i32.add (call $zr16 (local.get $t)) (select (i32.const -1) (i32.const 1) (local.get $q))) (i32.const 0xffff)))
          (br $end)))
        (if (i32.lt_u (local.get $z) (i32.const 6)) (then   ;; INC r / DEC r: Z N H, C kept
          (local.set $v (call $getr (local.get $y) (local.get $hl)))
          (local.set $t (i32.and (i32.add (local.get $v) (select (i32.const 1) (i32.const -1) (i32.eq (local.get $z) (i32.const 4)))) (i32.const 255)))
          (call $setr (local.get $y) (local.get $hl) (local.get $t))
          (call $zw (i32.const 6) (i32.or (i32.and (local.get $f) (i32.const 0x10)) (call $gbf (i32.eqz (local.get $t)) (i32.eq (local.get $z) (i32.const 5))
            (select (i32.eqz (i32.and (local.get $t) (i32.const 15))) (i32.eq (i32.and (local.get $t) (i32.const 15)) (i32.const 15)) (i32.eq (local.get $z) (i32.const 4))) (i32.const 0))))
          (br $end)))
        (if (i32.eq (local.get $z) (i32.const 6)) (then (call $setr (local.get $y) (local.get $hl) (call $fetch)) (br $end)))
        ;; z = 7: RLCA RRCA RLA RRA DAA CPL SCF CCF
        (if (i32.lt_u (local.get $y) (i32.const 4)) (then
          (call $zw (i32.const 7) (call $rot_gb (local.get $y) (call $zr (i32.const 7))))
          (call $zw (i32.const 6) (i32.and (call $zr (i32.const 6)) (i32.const 0x10)))   ;; Z cleared on the A-register rotates
          (br $end)))
        (if (i32.eq (local.get $y) (i32.const 4)) (then   ;; DAA
          (local.set $v (call $zr (i32.const 7))) (local.set $t (i32.const 0)) (local.set $e (i32.and (local.get $f) (i32.const 0x10)))
          (if (i32.and (local.get $f) (i32.const 0x40))
            (then
              (if (i32.and (local.get $f) (i32.const 0x20)) (then (local.set $t (i32.const 6))))
              (if (local.get $e) (then (local.set $t (i32.or (local.get $t) (i32.const 0x60)))))
              (local.set $v (i32.and (i32.sub (local.get $v) (local.get $t)) (i32.const 255))))
            (else
              (if (i32.or (i32.and (local.get $f) (i32.const 0x20)) (i32.gt_u (i32.and (local.get $v) (i32.const 15)) (i32.const 9))) (then (local.set $t (i32.const 6))))
              (if (i32.or (local.get $e) (i32.gt_u (local.get $v) (i32.const 0x99))) (then (local.set $t (i32.or (local.get $t) (i32.const 0x60))) (local.set $e (i32.const 1))))
              (local.set $v (i32.and (i32.add (local.get $v) (local.get $t)) (i32.const 255)))))
          (call $zw (i32.const 7) (local.get $v))
          (call $zw (i32.const 6) (call $gbf (i32.eqz (local.get $v)) (i32.and (local.get $f) (i32.const 0x40)) (i32.const 0) (local.get $e)))
          (br $end)))
        (if (i32.eq (local.get $y) (i32.const 5)) (then (call $zw (i32.const 7) (i32.xor (call $zr (i32.const 7)) (i32.const 255))) (call $zw (i32.const 6) (i32.or (local.get $f) (i32.const 0x60))) (br $end)))
        (if (i32.eq (local.get $y) (i32.const 6)) (then (call $zw (i32.const 6) (i32.or (i32.and (local.get $f) (i32.const 0x80)) (i32.const 0x10))) (br $end)))
        (call $zw (i32.const 6) (i32.or (i32.and (local.get $f) (i32.const 0x80)) (i32.xor (i32.and (local.get $f) (i32.const 0x10)) (i32.const 0x10))))
        (br $end)))
      ;; x = 3
      (if (i32.eqz (local.get $z)) (then
        (if (i32.lt_u (local.get $y) (i32.const 4)) (then (if (call $cc_gb (local.get $y)) (then (call $zw16 (i32.const 22) (call $pop)))) (br $end)))
        (if (i32.eq (local.get $y) (i32.const 4)) (then (call $mwr (i32.add (i32.const 0xFF00) (call $fetch)) (call $zr (i32.const 7))) (br $end)))
        (if (i32.eq (local.get $y) (i32.const 6)) (then (call $zw (i32.const 7) (call $mrd (i32.add (i32.const 0xFF00) (call $fetch)))) (br $end)))
        ;; ADD SP,e / LD HL,SP+e
        (local.set $e (call $sext8 (call $fetch))) (local.set $sp (call $zr16 (i32.const 20)))
        (local.set $t (i32.and (i32.add (local.get $sp) (local.get $e)) (i32.const 0xffff)))
        (call $zw (i32.const 6) (call $gbf (i32.const 0) (i32.const 0)
          (i32.gt_u (i32.add (i32.and (local.get $sp) (i32.const 15)) (i32.and (local.get $e) (i32.const 15))) (i32.const 15))
          (i32.gt_u (i32.add (i32.and (local.get $sp) (i32.const 255)) (i32.and (local.get $e) (i32.const 255))) (i32.const 255))))
        (call $zw16 (select (i32.const 20) (i32.const 4) (i32.eq (local.get $y) (i32.const 5))) (local.get $t))
        (br $end)))
      (if (i32.eq (local.get $z) (i32.const 1)) (then
        (if (i32.eqz (local.get $q)) (then
          (call $zw16 (call $rp2off (local.get $p)) (call $pop))
          (if (i32.eq (local.get $p) (i32.const 3)) (then (call $zw (i32.const 6) (i32.and (call $zr (i32.const 6)) (i32.const 0xF0)))))
          (br $end)))
        (if (i32.lt_u (local.get $p) (i32.const 2)) (then (call $zw16 (i32.const 22) (call $pop)) (br $end)))   ;; RET / RETI
        (if (i32.eq (local.get $p) (i32.const 2)) (then (call $zw16 (i32.const 22) (local.get $hl)) (br $end)))
        (call $zw16 (i32.const 20) (local.get $hl)) (br $end)))
      (if (i32.eq (local.get $z) (i32.const 2)) (then
        (if (i32.lt_u (local.get $y) (i32.const 4)) (then (local.set $t (call $fetch16)) (if (call $cc_gb (local.get $y)) (then (call $zw16 (i32.const 22) (local.get $t)))) (br $end)))
        (if (i32.eq (local.get $y) (i32.const 4)) (then (call $mwr (i32.add (i32.const 0xFF00) (call $zr (i32.const 0))) (call $zr (i32.const 7))) (br $end)))
        (if (i32.eq (local.get $y) (i32.const 5)) (then (call $mwr (call $fetch16) (call $zr (i32.const 7))) (br $end)))
        (if (i32.eq (local.get $y) (i32.const 6)) (then (call $zw (i32.const 7) (call $mrd (i32.add (i32.const 0xFF00) (call $zr (i32.const 0))))) (br $end)))
        (call $zw (i32.const 7) (call $mrd (call $fetch16))) (br $end)))
      (if (i32.eq (local.get $z) (i32.const 3)) (then
        (if (i32.eqz (local.get $y)) (then (call $zw16 (i32.const 22) (call $fetch16)) (br $end)))
        (if (i32.eq (local.get $y) (i32.const 1)) (then   ;; CB prefix
          (local.set $op (call $fetch)) (local.set $z (i32.and (local.get $op) (i32.const 7))) (local.set $x (i32.shr_u (local.get $op) (i32.const 6))) (local.set $y (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 7)))
          (local.set $v (call $getr (local.get $z) (local.get $hl)))
          (if (i32.eqz (local.get $x)) (then (call $setr (local.get $z) (local.get $hl) (call $rot_gb (local.get $y) (local.get $v))) (br $end)))
          (if (i32.eq (local.get $x) (i32.const 1)) (then   ;; BIT
            (call $zw (i32.const 6) (i32.or (i32.and (call $zr (i32.const 6)) (i32.const 0x10)) (call $gbf (i32.eqz (i32.and (local.get $v) (i32.shl (i32.const 1) (local.get $y)))) (i32.const 0) (i32.const 1) (i32.const 0))))
            (br $end)))
          (call $setr (local.get $z) (local.get $hl) (select (i32.and (local.get $v) (i32.xor (i32.shl (i32.const 1) (local.get $y)) (i32.const 255))) (i32.or (local.get $v) (i32.shl (i32.const 1) (local.get $y))) (i32.eq (local.get $x) (i32.const 2))))
          (br $end)))
        (br $end)))   ;; invalid, DI, EI
      (if (i32.eq (local.get $z) (i32.const 4)) (then
        (if (i32.lt_u (local.get $y) (i32.const 4)) (then (local.set $t (call $fetch16)) (if (call $cc_gb (local.get $y)) (then (call $push (call $zr16 (i32.const 22))) (call $zw16 (i32.const 22) (local.get $t))))))
        (br $end)))
      (if (i32.eq (local.get $z) (i32.const 5)) (then
        (if (i32.eqz (local.get $q)) (then (call $push (call $zr16 (call $rp2off (local.get $p)))) (br $end)))
        (if (i32.eqz (local.get $p)) (then (local.set $t (call $fetch16)) (call $push (call $zr16 (i32.const 22))) (call $zw16 (i32.const 22) (local.get $t))))
        (br $end)))
      (if (i32.eq (local.get $z) (i32.const 6)) (then (call $alu_gb (local.get $y) (call $fetch)) (br $end)))
      (call $push (call $zr16 (i32.const 22)))
      (call $zw16 (i32.const 22) (i32.shl (local.get $y) (i32.const 3)))))
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
        (if (i32.lt_u (local.get $hi) (i32.const 2)) (then   ;; INC / DEC: 04/14 act on A without an operand byte
          (local.set $t (select (i32.const 1) (i32.const -1) (i32.eqz (local.get $hi))))
          (if (i32.eq (local.get $lo) (i32.const 4)) (then (call $zw (i32.const 0) (i32.and (i32.add (local.get $a) (local.get $t)) (i32.const 255))))
            (else (local.set $v (call $src51 (local.get $lo))) (call $dst51 (local.get $lo) (i32.and (i32.add (local.get $v) (local.get $t)) (i32.const 255)))))
          (br $end)))
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
  ;; ========================================================================
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
  (func $fetch16be (result i32) (local $hi i32) (local.set $hi (call $fetch)) (i32.or (i32.shl (local.get $hi) (i32.const 8)) (call $fetch)))
  (func $mrd16be (param $a i32) (result i32) (i32.or (i32.shl (call $mrd (local.get $a)) (i32.const 8)) (call $mrd (i32.add (local.get $a) (i32.const 1)))))
  (func $mwr16be (param $a i32) (param $v i32) (call $mwr (local.get $a) (i32.shr_u (local.get $v) (i32.const 8))) (call $mwr (i32.add (local.get $a) (i32.const 1)) (i32.and (local.get $v) (i32.const 255))))
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
  ;; ========================================================================
  ;; DEC PDP-8 (kind 19). The pixel is 8 words of 12 bits: word k is pixel bits
  ;; 12k..12k+11 (bit j of the word = pixel bit 12k+j), i.e. bits 0..95. The
  ;; registers live in the remaining bits and are loaded at the start and
  ;; written back at the end: AC bits 96..107, L bit 108, PC bits 109..111,
  ;; MQ bits 112..123; bits 124..127 are untouched. Register file: AC 0 (u16),
  ;; L 2, MQ 4 (u16), PC 22. Addresses are taken mod 8 (the page bit is
  ;; ignored); indirect through a word also mod 8, no auto-index. IOT, OSR and
  ;; HLT are NOPs; the OPR groups are complete (incl. BSW and the MQ group).
  (func $p8_rd (param $off i32) (param $n i32) (result i32)   ;; n <= 16 bits at pixel bit offset off
    (local $b i32)
    (local.set $b (i32.shr_u (local.get $off) (i32.const 3)))
    (i32.and
      (i32.shr_u (i32.or (i32.or (call $mrd (local.get $b)) (i32.shl (call $mrd (i32.add (local.get $b) (i32.const 1))) (i32.const 8)))
                         (i32.shl (call $mrd (i32.add (local.get $b) (i32.const 2))) (i32.const 16)))
                 (i32.and (local.get $off) (i32.const 7)))
      (i32.sub (i32.shl (i32.const 1) (local.get $n)) (i32.const 1))))
  (func $p8_wr (param $off i32) (param $n i32) (param $v i32)
    (local $b i32) (local $cur i32) (local $mask i32) (local $s i32)
    (local.set $b (i32.shr_u (local.get $off) (i32.const 3))) (local.set $s (i32.and (local.get $off) (i32.const 7)))
    (local.set $mask (i32.shl (i32.sub (i32.shl (i32.const 1) (local.get $n)) (i32.const 1)) (local.get $s)))
    (local.set $cur (i32.or (i32.or (call $mrd (local.get $b)) (i32.shl (call $mrd (i32.add (local.get $b) (i32.const 1))) (i32.const 8)))
                            (i32.shl (call $mrd (i32.add (local.get $b) (i32.const 2))) (i32.const 16))))
    (local.set $cur (i32.or (i32.and (local.get $cur) (i32.xor (local.get $mask) (i32.const -1))) (i32.and (i32.shl (local.get $v) (local.get $s)) (local.get $mask))))
    (call $mwr (local.get $b) (i32.and (local.get $cur) (i32.const 255)))
    (call $mwr (i32.add (local.get $b) (i32.const 1)) (i32.and (i32.shr_u (local.get $cur) (i32.const 8)) (i32.const 255)))
    (call $mwr (i32.add (local.get $b) (i32.const 2)) (i32.shr_u (local.get $cur) (i32.const 16))))
  (func $p8_mem (param $a i32) (result i32) (call $p8_rd (i32.mul (i32.and (local.get $a) (i32.const 7)) (i32.const 12)) (i32.const 12)))
  (func $p8_set (param $a i32) (param $v i32) (call $p8_wr (i32.mul (i32.and (local.get $a) (i32.const 7)) (i32.const 12)) (i32.const 12) (i32.and (local.get $v) (i32.const 0xfff))))
  (func $p8_load
    (call $zw16 (i32.const 0) (call $p8_rd (i32.const 96) (i32.const 12)))
    (call $zw (i32.const 2) (call $p8_rd (i32.const 108) (i32.const 1)))
    (call $zw16 (i32.const 22) (call $p8_rd (i32.const 109) (i32.const 3)))
    (call $zw16 (i32.const 4) (call $p8_rd (i32.const 112) (i32.const 12))))
  (func $p8_spill
    (call $p8_wr (i32.const 96) (i32.const 12) (call $zr16 (i32.const 0)))
    (call $p8_wr (i32.const 108) (i32.const 1) (call $zr (i32.const 2)))
    (call $p8_wr (i32.const 109) (i32.const 3) (call $zr16 (i32.const 22)))
    (call $p8_wr (i32.const 112) (i32.const 12) (call $zr16 (i32.const 4))))
  (func $pdp8_step
    (local $pc i32) (local $w i32) (local $op i32) (local $a i32) (local $ac i32) (local $l i32) (local $t i32) (local $skip i32)
    (local.set $pc (call $zr16 (i32.const 22)))
    (local.set $w (call $p8_mem (local.get $pc)))
    (local.set $pc (i32.and (i32.add (local.get $pc) (i32.const 1)) (i32.const 7)))
    (local.set $op (i32.shr_u (local.get $w) (i32.const 9)))
    (local.set $ac (call $zr16 (i32.const 0))) (local.set $l (i32.and (call $zr (i32.const 2)) (i32.const 1)))
    (block $end
      (if (i32.lt_u (local.get $op) (i32.const 6)) (then
        (local.set $a (i32.and (local.get $w) (i32.const 7)))
        (if (i32.and (local.get $w) (i32.const 0x100)) (then (local.set $a (i32.and (call $p8_mem (local.get $a)) (i32.const 7)))))
        (if (i32.eqz (local.get $op)) (then (local.set $ac (i32.and (local.get $ac) (call $p8_mem (local.get $a)))) (br $end)))
        (if (i32.eq (local.get $op) (i32.const 1)) (then
          (local.set $t (i32.add (i32.or (i32.shl (local.get $l) (i32.const 12)) (local.get $ac)) (call $p8_mem (local.get $a))))
          (local.set $ac (i32.and (local.get $t) (i32.const 0xfff))) (local.set $l (i32.and (i32.shr_u (local.get $t) (i32.const 12)) (i32.const 1))) (br $end)))
        (if (i32.eq (local.get $op) (i32.const 2)) (then
          (local.set $t (i32.and (i32.add (call $p8_mem (local.get $a)) (i32.const 1)) (i32.const 0xfff)))
          (call $p8_set (local.get $a) (local.get $t))
          (if (i32.eqz (local.get $t)) (then (local.set $pc (i32.and (i32.add (local.get $pc) (i32.const 1)) (i32.const 7))))) (br $end)))
        (if (i32.eq (local.get $op) (i32.const 3)) (then (call $p8_set (local.get $a) (local.get $ac)) (local.set $ac (i32.const 0)) (br $end)))
        (if (i32.eq (local.get $op) (i32.const 4)) (then (call $p8_set (local.get $a) (local.get $pc)) (local.set $pc (i32.and (i32.add (local.get $a) (i32.const 1)) (i32.const 7))) (br $end)))
        (local.set $pc (local.get $a)) (br $end)))   ;; JMP
      (if (i32.eq (local.get $op) (i32.const 6)) (then (br $end)))   ;; IOT
      (if (i32.eqz (i32.and (local.get $w) (i32.const 0x100))) (then   ;; group 1
        (if (i32.and (local.get $w) (i32.const 0x80)) (then (local.set $ac (i32.const 0))))
        (if (i32.and (local.get $w) (i32.const 0x40)) (then (local.set $l (i32.const 0))))
        (if (i32.and (local.get $w) (i32.const 0x20)) (then (local.set $ac (i32.xor (local.get $ac) (i32.const 0xfff)))))
        (if (i32.and (local.get $w) (i32.const 0x10)) (then (local.set $l (i32.xor (local.get $l) (i32.const 1)))))
        (if (i32.and (local.get $w) (i32.const 1)) (then
          (local.set $t (i32.add (local.get $ac) (i32.const 1))) (local.set $ac (i32.and (local.get $t) (i32.const 0xfff)))
          (if (i32.and (local.get $t) (i32.const 0x1000)) (then (local.set $l (i32.xor (local.get $l) (i32.const 1)))))))
        (local.set $t (i32.or (i32.shl (local.get $l) (i32.const 12)) (local.get $ac)))   ;; 13-bit L:AC for the rotates
        (if (i32.and (local.get $w) (i32.const 0x08)) (then   ;; RAR / RTR
          (local.set $t (i32.or (i32.shr_u (local.get $t) (i32.const 1)) (i32.shl (i32.and (local.get $t) (i32.const 1)) (i32.const 12))))
          (if (i32.and (local.get $w) (i32.const 2)) (then (local.set $t (i32.or (i32.shr_u (local.get $t) (i32.const 1)) (i32.shl (i32.and (local.get $t) (i32.const 1)) (i32.const 12))))))))
        (if (i32.and (local.get $w) (i32.const 4)) (then   ;; RAL / RTL
          (local.set $t (i32.or (i32.shl (local.get $t) (i32.const 1)) (i32.shr_u (local.get $t) (i32.const 12))))
          (if (i32.and (local.get $w) (i32.const 2)) (then (local.set $t (i32.or (i32.shl (local.get $t) (i32.const 1)) (i32.shr_u (local.get $t) (i32.const 12))))))))
        (if (i32.eq (i32.and (local.get $w) (i32.const 0x0e)) (i32.const 2)) (then   ;; BSW: swap the two 6-bit halves
          (local.set $t (i32.or (i32.and (local.get $t) (i32.const 0x1000)) (i32.or (i32.shr_u (i32.and (local.get $t) (i32.const 0xfc0)) (i32.const 6)) (i32.shl (i32.and (local.get $t) (i32.const 0x3f)) (i32.const 6)))))))
        (local.set $ac (i32.and (local.get $t) (i32.const 0xfff))) (local.set $l (i32.and (i32.shr_u (local.get $t) (i32.const 12)) (i32.const 1)))
        (br $end)))
      (if (i32.eqz (i32.and (local.get $w) (i32.const 1))) (then   ;; group 2: skips, CLA, OSR/HLT as NOPs
        (local.set $skip (i32.or (i32.or
          (i32.and (i32.ne (i32.and (local.get $w) (i32.const 0x40)) (i32.const 0)) (i32.ne (i32.and (local.get $ac) (i32.const 0x800)) (i32.const 0)))
          (i32.and (i32.ne (i32.and (local.get $w) (i32.const 0x20)) (i32.const 0)) (i32.eqz (local.get $ac))))
          (i32.and (i32.ne (i32.and (local.get $w) (i32.const 0x10)) (i32.const 0)) (local.get $l))))
        (if (i32.and (local.get $w) (i32.const 0x08)) (then (local.set $skip (i32.eqz (local.get $skip)))))
        (if (local.get $skip) (then (local.set $pc (i32.and (i32.add (local.get $pc) (i32.const 1)) (i32.const 7)))))
        (if (i32.and (local.get $w) (i32.const 0x80)) (then (local.set $ac (i32.const 0))))
        (br $end)))
      ;; group 3: CLA, MQA, MQL (both = swap AC and MQ)
      (if (i32.and (local.get $w) (i32.const 0x80)) (then (local.set $ac (i32.const 0))))
      (local.set $t (call $zr16 (i32.const 4)))
      (if (i32.and (local.get $w) (i32.const 0x10)) (then (call $zw16 (i32.const 4) (local.get $ac)) (local.set $ac (i32.const 0))))
      (if (i32.and (local.get $w) (i32.const 0x40)) (then (local.set $ac (i32.or (local.get $ac) (local.get $t))))))
    (call $zw16 (i32.const 0) (local.get $ac)) (call $zw (i32.const 2) (local.get $l)) (call $zw16 (i32.const 22) (local.get $pc)))
  ;; ========================================================================
  ;; DEC PDP-11 (kind 20). Register file: R0..R6 as u16 at 0,2,..,12 (R6 = SP),
  ;; PSW at 20 (N 8, Z 4, V 2, C 1, T 16), PC (R7) at 22. The 16 bytes are the
  ;; whole address space (little-endian words, byte addressed, wrapping mod 16;
  ;; odd word addresses are allowed). All eight addressing modes incl. the PC
  ;; forms; the basic instruction set plus EIS (MUL DIV ASH ASHC), XOR, SOB,
  ;; SXT, MFPS/MTPS, JSR/RTS, RTI/RTT. HALT WAIT RESET BPT IOT EMT TRAP MARK
  ;; SPL and the MMU/floating-point groups are NOPs. Registers start at zero.
  (func $p11_r (param $n i32) (result i32) (call $zr16 (select (i32.const 22) (i32.shl (local.get $n) (i32.const 1)) (i32.eq (local.get $n) (i32.const 7)))))
  (func $p11_w (param $n i32) (param $v i32) (call $zw16 (select (i32.const 22) (i32.shl (local.get $n) (i32.const 1)) (i32.eq (local.get $n) (i32.const 7))) (i32.and (local.get $v) (i32.const 0xffff))))
  (func $p11_fetch (result i32) (local $pc i32)
    (local.set $pc (call $zr16 (i32.const 22))) (call $zw16 (i32.const 22) (i32.and (i32.add (local.get $pc) (i32.const 2)) (i32.const 0xffff))) (call $mrd16le (local.get $pc)))
  (func $p11_push (param $v i32) (call $p11_w (i32.const 6) (i32.sub (call $p11_r (i32.const 6)) (i32.const 2))) (call $mwr16le (call $p11_r (i32.const 6)) (local.get $v)))
  (func $p11_pop (result i32) (local $v i32) (local.set $v (call $mrd16le (call $p11_r (i32.const 6)))) (call $p11_w (i32.const 6) (i32.add (call $p11_r (i32.const 6)) (i32.const 2))) (local.get $v))
  (func $p11_mask (param $b i32) (result i32) (select (i32.const 0xff) (i32.const 0xffff) (local.get $b)))
  (func $p11_msb (param $b i32) (result i32) (select (i32.const 0x80) (i32.const 0x8000) (local.get $b)))
  ;; effective address: registers are reported as 0x10000 + n; auto-increment is 1 for byte operands except on SP and PC
  (func $p11_ea (param $spec i32) (param $b i32) (result i32)
    (local $m i32) (local $n i32) (local $inc i32) (local $v i32) (local $x i32)
    (local.set $m (i32.and (i32.shr_u (local.get $spec) (i32.const 3)) (i32.const 7))) (local.set $n (i32.and (local.get $spec) (i32.const 7)))
    (local.set $inc (select (i32.const 1) (i32.const 2) (i32.and (local.get $b) (i32.lt_u (local.get $n) (i32.const 6)))))
    (local.set $v (call $p11_r (local.get $n)))
    (if (i32.eqz (local.get $m)) (then (return (i32.add (i32.const 0x10000) (local.get $n)))))
    (if (i32.eq (local.get $m) (i32.const 1)) (then (return (local.get $v))))
    (if (i32.eq (local.get $m) (i32.const 2)) (then (call $p11_w (local.get $n) (i32.add (local.get $v) (local.get $inc))) (return (local.get $v))))
    (if (i32.eq (local.get $m) (i32.const 3)) (then (call $p11_w (local.get $n) (i32.add (local.get $v) (i32.const 2))) (return (call $mrd16le (local.get $v)))))
    (if (i32.eq (local.get $m) (i32.const 4)) (then (local.set $v (i32.and (i32.sub (local.get $v) (local.get $inc)) (i32.const 0xffff))) (call $p11_w (local.get $n) (local.get $v)) (return (local.get $v))))
    (if (i32.eq (local.get $m) (i32.const 5)) (then (local.set $v (i32.and (i32.sub (local.get $v) (i32.const 2)) (i32.const 0xffff))) (call $p11_w (local.get $n) (local.get $v)) (return (call $mrd16le (local.get $v)))))
    (local.set $x (call $p11_fetch)) (local.set $v (i32.and (i32.add (call $p11_r (local.get $n)) (local.get $x)) (i32.const 0xffff)))   ;; index: register read after the index word
    (if (i32.eq (local.get $m) (i32.const 6)) (then (return (local.get $v))))
    (call $mrd16le (local.get $v)))
  (func $p11_ld (param $ea i32) (param $b i32) (result i32)
    (if (i32.ge_u (local.get $ea) (i32.const 0x10000)) (then (return (i32.and (call $p11_r (i32.sub (local.get $ea) (i32.const 0x10000))) (call $p11_mask (local.get $b))))))
    (if (result i32) (local.get $b) (then (call $mrd (local.get $ea))) (else (call $mrd16le (local.get $ea)))))
  (func $p11_st (param $ea i32) (param $b i32) (param $v i32)
    (local $n i32)
    (if (i32.ge_u (local.get $ea) (i32.const 0x10000)) (then
      (local.set $n (i32.sub (local.get $ea) (i32.const 0x10000)))
      (call $p11_w (local.get $n) (select (i32.or (i32.and (call $p11_r (local.get $n)) (i32.const 0xff00)) (i32.and (local.get $v) (i32.const 0xff))) (local.get $v) (local.get $b)))
      (return)))
    (if (local.get $b) (then (call $mwr (local.get $ea) (i32.and (local.get $v) (i32.const 255)))) (else (call $mwr16le (local.get $ea) (local.get $v)))))
  ;; PSW <- N Z from r (width b), V and C as given (0/1)
  (func $p11_fl (param $r i32) (param $b i32) (param $v i32) (param $c i32)
    (call $zw16 (i32.const 20) (i32.or (i32.and (call $zr16 (i32.const 20)) (i32.const 0xfff0)) (i32.or (i32.or
      (select (i32.const 8) (i32.const 0) (i32.and (local.get $r) (call $p11_msb (local.get $b))))
      (select (i32.const 4) (i32.const 0) (i32.eqz (i32.and (local.get $r) (call $p11_mask (local.get $b))))))
      (i32.or (i32.shl (i32.ne (local.get $v) (i32.const 0)) (i32.const 1)) (i32.ne (local.get $c) (i32.const 0)))))))
  (func $p11_C (result i32) (i32.and (call $zr16 (i32.const 20)) (i32.const 1)))
  (func $p11_cond (param $k i32) (result i32)   ;; branch code 1..7 (BR..BLE) and 8..15 (BPL..BCS)
    (local $p i32) (local $n i32) (local $z i32) (local $v i32) (local $c i32)
    (local.set $p (call $zr16 (i32.const 20)))
    (local.set $n (i32.and (i32.shr_u (local.get $p) (i32.const 3)) (i32.const 1))) (local.set $z (i32.and (i32.shr_u (local.get $p) (i32.const 2)) (i32.const 1)))
    (local.set $v (i32.and (i32.shr_u (local.get $p) (i32.const 1)) (i32.const 1))) (local.set $c (i32.and (local.get $p) (i32.const 1)))
    (block $r (block $b15 (block $b14 (block $b13 (block $b12 (block $b11 (block $b10 (block $b9 (block $b8 (block $b7 (block $b6 (block $b5 (block $b4 (block $b3 (block $b2 (block $b1 (block $b0
      (br_table $b0 $b1 $b2 $b3 $b4 $b5 $b6 $b7 $b8 $b9 $b10 $b11 $b12 $b13 $b14 $b15 (local.get $k)))
      (return (i32.const 0)))
      (return (i32.const 1)))
      (return (i32.eqz (local.get $z))))
      (return (local.get $z)))
      (return (i32.eqz (i32.xor (local.get $n) (local.get $v)))))
      (return (i32.xor (local.get $n) (local.get $v))))
      (return (i32.eqz (i32.or (local.get $z) (i32.xor (local.get $n) (local.get $v))))))
      (return (i32.or (local.get $z) (i32.xor (local.get $n) (local.get $v)))))
      (return (i32.eqz (local.get $n))))
      (return (local.get $n)))
      (return (i32.eqz (i32.or (local.get $c) (local.get $z)))))
      (return (i32.or (local.get $c) (local.get $z))))
      (return (i32.eqz (local.get $v))))
      (return (local.get $v)))
      (return (i32.eqz (local.get $c))))
      (return (local.get $c)))
    (i32.const 0))
  ;; double-operand group: op 1 MOV 2 CMP 3 BIT 4 BIC 5 BIS 6 ADD (b=0) / SUB (b=1)
  (func $p11_dop (param $w i32)
    (local $op i32) (local $b i32) (local $s i32) (local $d i32) (local $r i32) (local $de i32) (local $msb i32) (local $mask i32)
    (local.set $op (i32.and (i32.shr_u (local.get $w) (i32.const 12)) (i32.const 7))) (local.set $b (i32.shr_u (local.get $w) (i32.const 15)))
    (if (i32.eq (local.get $op) (i32.const 6)) (then   ;; ADD / SUB are word only
      (local.set $s (call $p11_ld (call $p11_ea (i32.shr_u (local.get $w) (i32.const 6)) (i32.const 0)) (i32.const 0)))
      (local.set $de (call $p11_ea (local.get $w) (i32.const 0))) (local.set $d (call $p11_ld (local.get $de) (i32.const 0)))
      (if (local.get $b)
        (then (local.set $r (i32.and (i32.sub (local.get $d) (local.get $s)) (i32.const 0xffff)))
          (call $p11_fl (local.get $r) (i32.const 0) (i32.and (i32.and (i32.xor (local.get $d) (local.get $s)) (i32.xor (local.get $d) (local.get $r))) (i32.const 0x8000)) (i32.gt_u (local.get $s) (local.get $d))))
        (else (local.set $r (i32.add (local.get $d) (local.get $s)))
          (call $p11_fl (local.get $r) (i32.const 0) (i32.and (i32.and (i32.xor (i32.xor (local.get $d) (local.get $s)) (i32.const -1)) (i32.xor (local.get $d) (local.get $r))) (i32.const 0x8000)) (i32.shr_u (local.get $r) (i32.const 16)))))
      (call $p11_st (local.get $de) (i32.const 0) (local.get $r))
      (return)))
    (local.set $msb (call $p11_msb (local.get $b))) (local.set $mask (call $p11_mask (local.get $b)))
    (local.set $s (call $p11_ld (call $p11_ea (i32.shr_u (local.get $w) (i32.const 6)) (local.get $b)) (local.get $b)))
    (local.set $de (call $p11_ea (local.get $w) (local.get $b)))
    (if (i32.eq (local.get $op) (i32.const 1)) (then   ;; MOV; MOVB to a register sign-extends
      (call $p11_fl (local.get $s) (local.get $b) (i32.const 0) (call $p11_C))
      (if (i32.and (local.get $b) (i32.ge_u (local.get $de) (i32.const 0x10000)))
        (then (call $p11_st (local.get $de) (i32.const 0) (call $sext8 (local.get $s))))
        (else (call $p11_st (local.get $de) (local.get $b) (local.get $s))))
      (return)))
    (local.set $d (call $p11_ld (local.get $de) (local.get $b)))
    (if (i32.eq (local.get $op) (i32.const 2)) (then   ;; CMP src - dst
      (local.set $r (i32.and (i32.sub (local.get $s) (local.get $d)) (local.get $mask)))
      (call $p11_fl (local.get $r) (local.get $b) (i32.and (i32.and (i32.xor (local.get $s) (local.get $d)) (i32.xor (local.get $s) (local.get $r))) (local.get $msb)) (i32.lt_u (local.get $s) (local.get $d)))
      (return)))
    (if (i32.eq (local.get $op) (i32.const 3)) (then (call $p11_fl (i32.and (local.get $s) (local.get $d)) (local.get $b) (i32.const 0) (call $p11_C)) (return)))
    (local.set $r (select (i32.and (local.get $d) (i32.xor (local.get $s) (i32.const -1))) (i32.or (local.get $d) (local.get $s)) (i32.eq (local.get $op) (i32.const 4))))
    (call $p11_fl (local.get $r) (local.get $b) (i32.const 0) (call $p11_C))
    (call $p11_st (local.get $de) (local.get $b) (local.get $r)))
  ;; single-operand group; k = 0 CLR 1 COM 2 INC 3 DEC 4 NEG 5 ADC 6 SBC 7 TST 8 ROR 9 ROL 10 ASR 11 ASL
  (func $p11_sop (param $k i32) (param $ea i32) (param $b i32)
    (local $d i32) (local $r i32) (local $c i32) (local $msb i32) (local $mask i32) (local $v i32) (local $cc i32) (local $shb i32)
    (local.set $msb (call $p11_msb (local.get $b))) (local.set $mask (call $p11_mask (local.get $b))) (local.set $c (call $p11_C))
    (local.set $d (call $p11_ld (local.get $ea) (local.get $b))) (local.set $shb (select (i32.const 7) (i32.const 15) (local.get $b)))
    (block $done
      (if (i32.eqz (local.get $k)) (then (local.set $r (i32.const 0)) (local.set $cc (i32.const 0)) (br $done)))
      (if (i32.eq (local.get $k) (i32.const 1)) (then (local.set $r (i32.and (i32.xor (local.get $d) (i32.const -1)) (local.get $mask))) (local.set $cc (i32.const 1)) (br $done)))
      (if (i32.eq (local.get $k) (i32.const 2)) (then (local.set $r (i32.and (i32.add (local.get $d) (i32.const 1)) (local.get $mask))) (local.set $v (i32.eq (local.get $d) (i32.sub (local.get $msb) (i32.const 1)))) (local.set $cc (local.get $c)) (br $done)))
      (if (i32.eq (local.get $k) (i32.const 3)) (then (local.set $r (i32.and (i32.sub (local.get $d) (i32.const 1)) (local.get $mask))) (local.set $v (i32.eq (local.get $d) (local.get $msb))) (local.set $cc (local.get $c)) (br $done)))
      (if (i32.eq (local.get $k) (i32.const 4)) (then (local.set $r (i32.and (i32.sub (i32.const 0) (local.get $d)) (local.get $mask))) (local.set $v (i32.eq (local.get $r) (local.get $msb))) (local.set $cc (i32.ne (local.get $r) (i32.const 0))) (br $done)))
      (if (i32.eq (local.get $k) (i32.const 5)) (then (local.set $r (i32.and (i32.add (local.get $d) (local.get $c)) (local.get $mask)))
        (local.set $v (i32.and (i32.eq (local.get $d) (i32.sub (local.get $msb) (i32.const 1))) (local.get $c))) (local.set $cc (i32.and (i32.eq (local.get $d) (local.get $mask)) (local.get $c))) (br $done)))
      (if (i32.eq (local.get $k) (i32.const 6)) (then (local.set $r (i32.and (i32.sub (local.get $d) (local.get $c)) (local.get $mask)))
        (local.set $v (i32.eq (local.get $d) (local.get $msb))) (local.set $cc (i32.and (i32.eqz (local.get $d)) (local.get $c))) (br $done)))
      (if (i32.eq (local.get $k) (i32.const 7)) (then (call $p11_fl (local.get $d) (local.get $b) (i32.const 0) (i32.const 0)) (return)))
      (if (i32.eq (local.get $k) (i32.const 8)) (then (local.set $r (i32.or (i32.shr_u (local.get $d) (i32.const 1)) (i32.shl (local.get $c) (local.get $shb)))) (local.set $cc (i32.and (local.get $d) (i32.const 1))) (br $done)))
      (if (i32.eq (local.get $k) (i32.const 9)) (then (local.set $r (i32.and (i32.or (i32.shl (local.get $d) (i32.const 1)) (local.get $c)) (local.get $mask))) (local.set $cc (i32.shr_u (local.get $d) (local.get $shb))) (br $done)))
      (if (i32.eq (local.get $k) (i32.const 10)) (then (local.set $r (i32.or (i32.shr_u (local.get $d) (i32.const 1)) (i32.and (local.get $d) (local.get $msb)))) (local.set $cc (i32.and (local.get $d) (i32.const 1))) (br $done)))
      (local.set $r (i32.and (i32.shl (local.get $d) (i32.const 1)) (local.get $mask))) (local.set $cc (i32.shr_u (local.get $d) (local.get $shb))))
    (if (i32.ge_u (local.get $k) (i32.const 8)) (then (local.set $v (i32.xor (i32.shr_u (local.get $r) (local.get $shb)) (local.get $cc)))))   ;; rotates and shifts: V = N xor C
    (call $p11_fl (local.get $r) (local.get $b) (local.get $v) (local.get $cc))
    (call $p11_st (local.get $ea) (local.get $b) (local.get $r)))
  (func $p11_eis (param $w i32)
    (local $sub i32) (local $n i32) (local $r i32) (local $s i32) (local $p i32) (local $q i32) (local $cnt i32) (local $v i32) (local $c i32) (local $ea i32) (local $lo i32)
    (local.set $sub (i32.and (i32.shr_u (local.get $w) (i32.const 9)) (i32.const 7))) (local.set $n (i32.and (i32.shr_u (local.get $w) (i32.const 6)) (i32.const 7)))
    (if (i32.eq (local.get $sub) (i32.const 7)) (then   ;; SOB
      (local.set $r (i32.and (i32.sub (call $p11_r (local.get $n)) (i32.const 1)) (i32.const 0xffff))) (call $p11_w (local.get $n) (local.get $r))
      (if (local.get $r) (then (call $zw16 (i32.const 22) (i32.and (i32.sub (call $zr16 (i32.const 22)) (i32.shl (i32.and (local.get $w) (i32.const 63)) (i32.const 1))) (i32.const 0xffff)))))
      (return)))
    (if (i32.ge_u (local.get $sub) (i32.const 5)) (then (return)))   ;; FIS
    (local.set $ea (call $p11_ea (local.get $w) (i32.const 0))) (local.set $s (call $p11_ld (local.get $ea) (i32.const 0))) (local.set $r (call $p11_r (local.get $n)))
    (if (i32.eq (local.get $sub) (i32.const 4)) (then (local.set $p (i32.xor (local.get $s) (local.get $r))) (call $p11_fl (local.get $p) (i32.const 0) (i32.const 0) (call $p11_C)) (call $p11_st (local.get $ea) (i32.const 0) (local.get $p)) (return)))
    (if (i32.eqz (local.get $sub)) (then   ;; MUL
      (local.set $p (i32.mul (call $sx (local.get $r) (i32.const 16)) (call $sx (local.get $s) (i32.const 16))))
      (if (i32.and (local.get $n) (i32.const 1)) (then (call $p11_w (local.get $n) (local.get $p)))
        (else (call $p11_w (local.get $n) (i32.shr_u (local.get $p) (i32.const 16))) (call $p11_w (i32.or (local.get $n) (i32.const 1)) (local.get $p))))
      (call $zw16 (i32.const 20) (i32.or (i32.and (call $zr16 (i32.const 20)) (i32.const 0xfff0)) (i32.or (i32.or
        (select (i32.const 8) (i32.const 0) (i32.lt_s (local.get $p) (i32.const 0))) (select (i32.const 4) (i32.const 0) (i32.eqz (local.get $p))))
        (i32.ne (call $sx (local.get $p) (i32.const 16)) (local.get $p)))))
      (return)))
    (local.set $lo (call $p11_r (i32.or (local.get $n) (i32.const 1)))) (local.set $p (i32.or (i32.shl (local.get $r) (i32.const 16)) (local.get $lo)))   ;; 32-bit R:R|1
    (if (i32.eq (local.get $sub) (i32.const 1)) (then   ;; DIV
      (if (i32.eqz (local.get $s)) (then (call $p11_fl (i32.const 0) (i32.const 0) (i32.const 1) (i32.const 1)) (return)))
      (local.set $s (call $sx (local.get $s) (i32.const 16)))
      (if (i32.and (i32.eq (local.get $p) (i32.const 0x80000000)) (i32.eq (local.get $s) (i32.const -1))) (then (call $p11_fl (i32.const 0) (i32.const 0) (i32.const 1) (i32.const 0)) (return)))
      (local.set $q (i32.div_s (local.get $p) (local.get $s)))
      (if (i32.ne (call $sx (local.get $q) (i32.const 16)) (local.get $q)) (then (call $p11_fl (local.get $q) (i32.const 0) (i32.const 1) (i32.const 0)) (return)))
      (call $p11_w (local.get $n) (local.get $q)) (call $p11_w (i32.or (local.get $n) (i32.const 1)) (i32.rem_s (local.get $p) (local.get $s)))
      (call $p11_fl (local.get $q) (i32.const 0) (i32.const 0) (i32.const 0))
      (return)))
    (local.set $cnt (call $sx (local.get $s) (i32.const 6)))
    (if (i32.eq (local.get $sub) (i32.const 2)) (then   ;; ASH
      (local.set $p (call $sx (local.get $r) (i32.const 16)))
      (if (i32.gt_s (local.get $cnt) (i32.const 0)) (then
        (local.set $q (i32.shl (local.get $p) (local.get $cnt)))
        (local.set $c (i32.and (i32.shr_u (local.get $p) (i32.sub (i32.const 16) (local.get $cnt))) (i32.const 1)))
        (local.set $v (i32.ne (call $sx (local.get $q) (i32.const 16)) (local.get $q))))
      (else (if (local.get $cnt) (then
        (local.set $cnt (i32.sub (i32.const 0) (local.get $cnt)))
        (local.set $q (i32.shr_s (local.get $p) (local.get $cnt)))
        (local.set $c (i32.and (i32.shr_s (local.get $p) (i32.sub (local.get $cnt) (i32.const 1))) (i32.const 1))))
        (else (local.set $q (local.get $p))))))
      (call $p11_w (local.get $n) (local.get $q)) (call $p11_fl (local.get $q) (i32.const 0) (local.get $v) (local.get $c))
      (return)))
    ;; ASHC on the 32-bit pair
    (if (i32.gt_s (local.get $cnt) (i32.const 0)) (then
      (local.set $q (i32.shl (local.get $p) (local.get $cnt)))
      (local.set $c (i32.and (i32.shr_u (local.get $p) (i32.sub (i32.const 32) (local.get $cnt))) (i32.const 1)))
      (local.set $v (i32.ne (i32.shr_s (local.get $q) (local.get $cnt)) (local.get $p))))
    (else (if (local.get $cnt) (then
      (local.set $cnt (i32.sub (i32.const 0) (local.get $cnt)))
      (local.set $q (i32.shr_s (local.get $p) (local.get $cnt)))
      (local.set $c (i32.and (i32.shr_s (local.get $p) (i32.sub (local.get $cnt) (i32.const 1))) (i32.const 1))))
      (else (local.set $q (local.get $p))))))
    (if (i32.and (local.get $n) (i32.const 1)) (then (call $p11_w (local.get $n) (local.get $q)))
      (else (call $p11_w (local.get $n) (i32.shr_u (local.get $q) (i32.const 16))) (call $p11_w (i32.or (local.get $n) (i32.const 1)) (local.get $q))))
    (call $zw16 (i32.const 20) (i32.or (i32.and (call $zr16 (i32.const 20)) (i32.const 0xfff0)) (i32.or (i32.or
      (select (i32.const 8) (i32.const 0) (i32.lt_s (local.get $q) (i32.const 0))) (select (i32.const 4) (i32.const 0) (i32.eqz (local.get $q))))
      (i32.or (i32.shl (local.get $v) (i32.const 1)) (local.get $c))))))
  (func $pdp11_step
    (local $w i32) (local $b i32) (local $c i32) (local $t i32) (local $n i32) (local $ea i32)
    (local.set $w (call $p11_fetch)) (local.set $b (i32.shr_u (local.get $w) (i32.const 15)))
    (local.set $t (i32.and (i32.shr_u (local.get $w) (i32.const 12)) (i32.const 7)))
    (if (i32.and (i32.ge_u (local.get $t) (i32.const 1)) (i32.le_u (local.get $t) (i32.const 6))) (then (call $p11_dop (local.get $w)) (return)))
    (if (i32.eq (local.get $t) (i32.const 7)) (then (if (i32.eqz (local.get $b)) (then (call $p11_eis (local.get $w)))) (return)))   ;; 17xxxx: floating point, NOP
    (local.set $c (i32.and (i32.shr_u (local.get $w) (i32.const 6)) (i32.const 0x1ff)))
    (if (i32.eqz (local.get $b)) (then
      (if (i32.eqz (local.get $c)) (then   ;; HALT WAIT RTI BPT IOT RESET RTT
        (local.set $t (i32.and (local.get $w) (i32.const 63)))
        (if (i32.or (i32.eq (local.get $t) (i32.const 2)) (i32.eq (local.get $t) (i32.const 6))) (then (call $zw16 (i32.const 22) (call $p11_pop)) (call $zw16 (i32.const 20) (i32.and (call $p11_pop) (i32.const 0xff)))))
        (return)))
      (if (i32.eq (local.get $c) (i32.const 1)) (then (local.set $ea (call $p11_ea (local.get $w) (i32.const 0))) (if (i32.lt_u (local.get $ea) (i32.const 0x10000)) (then (call $zw16 (i32.const 22) (local.get $ea)))) (return)))   ;; JMP
      (if (i32.eq (local.get $c) (i32.const 2)) (then
        (local.set $t (i32.and (local.get $w) (i32.const 0x38)))
        (if (i32.eqz (local.get $t)) (then (local.set $n (i32.and (local.get $w) (i32.const 7))) (call $zw16 (i32.const 22) (call $p11_r (local.get $n))) (call $p11_w (local.get $n) (call $p11_pop)) (return)))   ;; RTS
        (if (i32.ge_u (local.get $t) (i32.const 0x20)) (then   ;; condition codes: 24x clear, 26x set
          (if (i32.and (local.get $w) (i32.const 0x10)) (then (call $zw16 (i32.const 20) (i32.or (call $zr16 (i32.const 20)) (i32.and (local.get $w) (i32.const 15)))))
            (else (call $zw16 (i32.const 20) (i32.and (call $zr16 (i32.const 20)) (i32.xor (i32.and (local.get $w) (i32.const 15)) (i32.const -1))))))))
        (return)))
      (if (i32.eq (local.get $c) (i32.const 3)) (then   ;; SWAB
        (local.set $ea (call $p11_ea (local.get $w) (i32.const 0))) (local.set $t (call $p11_ld (local.get $ea) (i32.const 0)))
        (local.set $t (i32.or (i32.shl (i32.and (local.get $t) (i32.const 0xff)) (i32.const 8)) (i32.shr_u (local.get $t) (i32.const 8))))
        (call $p11_fl (local.get $t) (i32.const 1) (i32.const 0) (i32.const 0)) (call $p11_st (local.get $ea) (i32.const 0) (local.get $t)) (return)))
      (if (i32.lt_u (local.get $c) (i32.const 32)) (then   ;; BR .. BLE
        (if (call $p11_cond (i32.and (i32.shr_u (local.get $w) (i32.const 8)) (i32.const 7))) (then (call $zw16 (i32.const 22) (i32.and (i32.add (call $zr16 (i32.const 22)) (i32.shl (call $sext8 (local.get $w)) (i32.const 1))) (i32.const 0xffff)))))
        (return)))
      (if (i32.lt_u (local.get $c) (i32.const 40)) (then   ;; JSR R,dst
        (local.set $n (i32.and (i32.shr_u (local.get $w) (i32.const 6)) (i32.const 7))) (local.set $ea (call $p11_ea (local.get $w) (i32.const 0)))
        (if (i32.lt_u (local.get $ea) (i32.const 0x10000)) (then (call $p11_push (call $p11_r (local.get $n))) (call $p11_w (local.get $n) (call $zr16 (i32.const 22))) (call $zw16 (i32.const 22) (local.get $ea))))
        (return)))
      (if (i32.eq (local.get $c) (i32.const 55)) (then   ;; SXT
        (local.set $ea (call $p11_ea (local.get $w) (i32.const 0))) (local.set $t (select (i32.const 0xffff) (i32.const 0) (i32.and (call $zr16 (i32.const 20)) (i32.const 8))))
        (call $p11_fl (local.get $t) (i32.const 0) (i32.const 0) (call $p11_C)) (call $p11_st (local.get $ea) (i32.const 0) (local.get $t)) (return))))
    (else
      (if (i32.lt_u (local.get $c) (i32.const 16)) (then   ;; BPL .. BCS
        (if (call $p11_cond (i32.add (i32.const 8) (i32.and (i32.shr_u (local.get $w) (i32.const 8)) (i32.const 7)))) (then (call $zw16 (i32.const 22) (i32.and (i32.add (call $zr16 (i32.const 22)) (i32.shl (call $sext8 (local.get $w)) (i32.const 1))) (i32.const 0xffff)))))
        (return)))
      (if (i32.eq (local.get $c) (i32.const 52)) (then (call $zw16 (i32.const 20) (i32.and (call $p11_ld (call $p11_ea (local.get $w) (i32.const 1)) (i32.const 1)) (i32.const 0xef))) (return)))   ;; MTPS
      (if (i32.eq (local.get $c) (i32.const 55)) (then   ;; MFPS
        (local.set $ea (call $p11_ea (local.get $w) (i32.const 1))) (local.set $t (i32.and (call $zr16 (i32.const 20)) (i32.const 0xff)))
        (call $p11_fl (local.get $t) (i32.const 1) (i32.const 0) (call $p11_C))
        (if (i32.ge_u (local.get $ea) (i32.const 0x10000)) (then (call $p11_st (local.get $ea) (i32.const 0) (call $sext8 (local.get $t)))) (else (call $p11_st (local.get $ea) (i32.const 1) (local.get $t))))
        (return)))))
    (if (i32.and (i32.ge_u (local.get $c) (i32.const 40)) (i32.lt_u (local.get $c) (i32.const 52))) (then   ;; CLR .. ASL and the byte forms
      (call $p11_sop (i32.sub (local.get $c) (i32.const 40)) (call $p11_ea (local.get $w) (local.get $b)) (local.get $b)))))
  ;; ========================================================================
  ;; Motorola 68000 (kind 21). Register file: D0..D7 as i32 at offset 64 + 4n,
  ;; A0..A7 at 96 + 4n (A7 = SP), SR at 20 (X 16, N 8, Z 4, V 2, C 1), PC at
  ;; 22. Memory is the pixel: 16 bytes, big-endian, every access wrapping mod 16
  ;; byte by byte (so odd addresses are fine). All 68000 addressing modes incl.
  ;; the brief extension word; the integer instruction set: MOVE/MOVEA/MOVEQ,
  ;; ADD SUB CMP AND OR EOR with their I/Q/A/X/M forms, NEG NEGX NOT CLR TST
  ;; TAS EXT SWAP, the bit instructions, all shifts and rotates, MULU MULS
  ;; DIVU DIVS, Bcc BRA BSR DBcc Scc JMP JSR RTS RTR RTE, LEA PEA LINK UNLK
  ;; MOVEM EXG, MOVE to/from SR/CCR. ABCD SBCD NBCD CHK TRAP TRAPV STOP RESET
  ;; ILLEGAL MOVEP MOVE USP and lines A/F are NOPs; divide by zero is a NOP.
  (func $m_d (param $n i32) (result i32) (i32.load offset=320 (i32.shl (i32.and (local.get $n) (i32.const 7)) (i32.const 2))))
  (func $m_dw (param $n i32) (param $v i32) (i32.store offset=320 (i32.shl (i32.and (local.get $n) (i32.const 7)) (i32.const 2)) (local.get $v)))
  (func $m_a (param $n i32) (result i32) (i32.load offset=352 (i32.shl (i32.and (local.get $n) (i32.const 7)) (i32.const 2))))
  (func $m_aw (param $n i32) (param $v i32) (i32.store offset=352 (i32.shl (i32.and (local.get $n) (i32.const 7)) (i32.const 2)) (local.get $v)))
  (func $m_rr (param $k i32) (result i32) (if (result i32) (i32.and (local.get $k) (i32.const 8)) (then (call $m_a (local.get $k))) (else (call $m_d (local.get $k)))))
  (func $m_rw (param $k i32) (param $v i32) (if (i32.and (local.get $k) (i32.const 8)) (then (call $m_aw (local.get $k) (local.get $v))) (else (call $m_dw (local.get $k) (local.get $v)))))
  (func $m_rd32 (param $a i32) (result i32) (i32.or (i32.shl (call $mrd16be (local.get $a)) (i32.const 16)) (call $mrd16be (i32.add (local.get $a) (i32.const 2)))))
  (func $m_wr32 (param $a i32) (param $v i32) (call $mwr16be (local.get $a) (i32.shr_u (local.get $v) (i32.const 16))) (call $mwr16be (i32.add (local.get $a) (i32.const 2)) (i32.and (local.get $v) (i32.const 0xffff))))
  (func $m_fetch (result i32) (local $pc i32)
    (local.set $pc (call $zr16 (i32.const 22))) (call $zw16 (i32.const 22) (i32.and (i32.add (local.get $pc) (i32.const 2)) (i32.const 0xffff))) (call $mrd16be (local.get $pc)))
  (func $m_fetch32 (result i32) (local $hi i32) (local.set $hi (call $m_fetch)) (i32.or (i32.shl (local.get $hi) (i32.const 16)) (call $m_fetch)))
  (func $m_push (param $v i32) (call $m_aw (i32.const 7) (i32.sub (call $m_a (i32.const 7)) (i32.const 4))) (call $m_wr32 (call $m_a (i32.const 7)) (local.get $v)))
  (func $m_pop (result i32) (local $v i32) (local.set $v (call $m_rd32 (call $m_a (i32.const 7)))) (call $m_aw (i32.const 7) (i32.add (call $m_a (i32.const 7)) (i32.const 4))) (local.get $v))
  (func $m_push16 (param $v i32) (call $m_aw (i32.const 7) (i32.sub (call $m_a (i32.const 7)) (i32.const 2))) (call $mwr16be (call $m_a (i32.const 7)) (local.get $v)))
  (func $m_pop16 (result i32) (local $v i32) (local.set $v (call $mrd16be (call $m_a (i32.const 7)))) (call $m_aw (i32.const 7) (i32.add (call $m_a (i32.const 7)) (i32.const 2))) (local.get $v))
  (func $m_mask (param $sz i32) (result i32) (select (i32.const 0xff) (select (i32.const 0xffff) (i32.const -1) (i32.eq (local.get $sz) (i32.const 1))) (i32.eqz (local.get $sz))))
  (func $m_msb (param $sz i32) (result i32) (select (i32.const 0x80) (select (i32.const 0x8000) (i32.const 0x80000000) (i32.eq (local.get $sz) (i32.const 1))) (i32.eqz (local.get $sz))))
  (func $m_sx (param $v i32) (param $sz i32) (result i32)   ;; sign-extend a byte/word/long operand to 32 bits
    (select (call $sext8 (local.get $v)) (select (call $sx (local.get $v) (i32.const 16)) (local.get $v) (i32.eq (local.get $sz) (i32.const 1))) (i32.eqz (local.get $sz))))
  ;; index from a brief extension word: Dn/An, word (sign-extended) or long, plus the 8-bit displacement
  (func $m_index (param $ext i32) (result i32)
    (local $v i32)
    (local.set $v (call $m_rr (i32.and (i32.shr_u (local.get $ext) (i32.const 12)) (i32.const 15))))
    (if (i32.eqz (i32.and (local.get $ext) (i32.const 0x800))) (then (local.set $v (call $sx (local.get $v) (i32.const 16)))))
    (i32.add (local.get $v) (call $sext8 (local.get $ext))))
  ;; effective address with side effects; registers are reported as 0x10000 + n (Dn) and 0x20000 + n (An)
  (func $m_ea (param $mode i32) (param $reg i32) (param $sz i32) (result i32)
    (local $a i32) (local $n i32) (local $pc i32)
    (local.set $n (i32.shl (i32.const 1) (local.get $sz)))
    (if (i32.and (i32.eqz (local.get $sz)) (i32.eq (local.get $reg) (i32.const 7))) (then (local.set $n (i32.const 2))))   ;; byte on the stack pointer moves by 2
    (block $done
      (if (i32.eqz (local.get $mode)) (then (return (i32.add (i32.const 0x10000) (local.get $reg)))))
      (if (i32.eq (local.get $mode) (i32.const 1)) (then (return (i32.add (i32.const 0x20000) (local.get $reg)))))
      (local.set $a (call $m_a (local.get $reg)))
      (if (i32.eq (local.get $mode) (i32.const 2)) (then (br $done)))
      (if (i32.eq (local.get $mode) (i32.const 3)) (then (call $m_aw (local.get $reg) (i32.add (local.get $a) (local.get $n))) (br $done)))
      (if (i32.eq (local.get $mode) (i32.const 4)) (then (local.set $a (i32.sub (local.get $a) (local.get $n))) (call $m_aw (local.get $reg) (local.get $a)) (br $done)))
      (if (i32.eq (local.get $mode) (i32.const 5)) (then (local.set $a (i32.add (local.get $a) (call $sx (call $m_fetch) (i32.const 16)))) (br $done)))
      (if (i32.eq (local.get $mode) (i32.const 6)) (then (local.set $a (i32.add (local.get $a) (call $m_index (call $m_fetch)))) (br $done)))
      (local.set $pc (call $zr16 (i32.const 22)))
      (if (i32.eqz (local.get $reg)) (then (local.set $a (call $sx (call $m_fetch) (i32.const 16))) (br $done)))
      (if (i32.eq (local.get $reg) (i32.const 1)) (then (local.set $a (call $m_fetch32)) (br $done)))
      (if (i32.eq (local.get $reg) (i32.const 2)) (then (local.set $a (i32.add (local.get $pc) (call $sx (call $m_fetch) (i32.const 16)))) (br $done)))
      (if (i32.eq (local.get $reg) (i32.const 3)) (then (local.set $a (i32.add (local.get $pc) (call $m_index (call $m_fetch)))) (br $done)))
      ;; immediate (reg 4) and the invalid forms 5..7: the operand is the next word(s)
      (local.set $a (select (i32.add (local.get $pc) (i32.const 1)) (local.get $pc) (i32.eqz (local.get $sz))))
      (call $zw16 (i32.const 22) (i32.and (i32.add (local.get $pc) (select (i32.const 4) (i32.const 2) (i32.eq (local.get $sz) (i32.const 2)))) (i32.const 0xffff))))
    (i32.and (local.get $a) (i32.const 0xffff)))
  (func $m_ld (param $ea i32) (param $sz i32) (result i32)
    (if (i32.ge_u (local.get $ea) (i32.const 0x10000)) (then (return (i32.and (call $m_rr (i32.or (i32.and (local.get $ea) (i32.const 7)) (select (i32.const 8) (i32.const 0) (i32.and (local.get $ea) (i32.const 0x20000))))) (call $m_mask (local.get $sz))))))
    (if (i32.eqz (local.get $sz)) (then (return (call $mrd (local.get $ea)))))
    (if (i32.eq (local.get $sz) (i32.const 1)) (then (return (call $mrd16be (local.get $ea)))))
    (call $m_rd32 (local.get $ea)))
  (func $m_st (param $ea i32) (param $sz i32) (param $v i32)
    (local $n i32)
    (if (i32.ge_u (local.get $ea) (i32.const 0x10000)) (then
      (local.set $n (i32.and (local.get $ea) (i32.const 7)))
      (if (i32.and (local.get $ea) (i32.const 0x20000))
        (then (call $m_aw (local.get $n) (call $m_sx (local.get $v) (local.get $sz))))   ;; address registers take the whole 32 bits, sign-extended
        (else (call $m_dw (local.get $n) (i32.or (i32.and (call $m_d (local.get $n)) (i32.xor (call $m_mask (local.get $sz)) (i32.const -1))) (i32.and (local.get $v) (call $m_mask (local.get $sz)))))))
      (return)))
    (if (i32.eqz (local.get $sz)) (then (call $mwr (local.get $ea) (i32.and (local.get $v) (i32.const 255))) (return)))
    (if (i32.eq (local.get $sz) (i32.const 1)) (then (call $mwr16be (local.get $ea) (i32.and (local.get $v) (i32.const 0xffff))) (return)))
    (call $m_wr32 (local.get $ea) (local.get $v)))
  ;; SR <- N Z from r (width sz), V and C as given; x: 0 keep X, 1 X = C
  (func $m_fl (param $r i32) (param $sz i32) (param $v i32) (param $c i32) (param $x i32)
    (local $sr i32)
    (local.set $sr (i32.and (call $zr16 (i32.const 20)) (select (i32.const 0xffe0) (i32.const 0xfff0) (local.get $x))))
    (call $zw16 (i32.const 20) (i32.or (local.get $sr) (i32.or (i32.or
      (select (i32.const 8) (i32.const 0) (i32.and (local.get $r) (call $m_msb (local.get $sz))))
      (select (i32.const 4) (i32.const 0) (i32.eqz (i32.and (local.get $r) (call $m_mask (local.get $sz))))))
      (i32.or (i32.or (i32.shl (i32.ne (local.get $v) (i32.const 0)) (i32.const 1)) (i32.ne (local.get $c) (i32.const 0)))
              (select (i32.shl (i32.ne (local.get $c) (i32.const 0)) (i32.const 4)) (i32.const 0) (local.get $x)))))))
  (func $m_X (result i32) (i32.and (i32.shr_u (call $zr16 (i32.const 20)) (i32.const 4)) (i32.const 1)))
  (func $m_cc (param $k i32) (result i32)   ;; T F HI LS CC CS NE EQ VC VS GE LT GT LE
    (local $p i32) (local $n i32) (local $z i32) (local $v i32) (local $c i32)
    (local.set $p (call $zr16 (i32.const 20)))
    (local.set $n (i32.and (i32.shr_u (local.get $p) (i32.const 3)) (i32.const 1))) (local.set $z (i32.and (i32.shr_u (local.get $p) (i32.const 2)) (i32.const 1)))
    (local.set $v (i32.and (i32.shr_u (local.get $p) (i32.const 1)) (i32.const 1))) (local.set $c (i32.and (local.get $p) (i32.const 1)))
    (block $b15 (block $b14 (block $b13 (block $b12 (block $b11 (block $b10 (block $b9 (block $b8 (block $b7 (block $b6 (block $b5 (block $b4 (block $b3 (block $b2 (block $b1 (block $b0
      (br_table $b0 $b1 $b2 $b3 $b4 $b5 $b6 $b7 $b8 $b9 $b10 $b11 $b12 $b13 $b14 $b15 (i32.and (local.get $k) (i32.const 15))))
      (return (i32.const 1)))
      (return (i32.const 0)))
      (return (i32.eqz (i32.or (local.get $c) (local.get $z)))))
      (return (i32.or (local.get $c) (local.get $z))))
      (return (i32.eqz (local.get $c))))
      (return (local.get $c)))
      (return (i32.eqz (local.get $z))))
      (return (local.get $z)))
      (return (i32.eqz (local.get $v))))
      (return (local.get $v)))
      (return (i32.eqz (i32.xor (local.get $n) (local.get $v)))))
      (return (i32.xor (local.get $n) (local.get $v))))
      (return (i32.eqz (i32.or (local.get $z) (i32.xor (local.get $n) (local.get $v))))))
      (return (i32.or (local.get $z) (i32.xor (local.get $n) (local.get $v))))))
    (i32.const 0))
  ;; add/subtract with flags: mode bit 1 = subtract (d - s), 2 = include X, 4 = Z sticky (X forms), 8 = compare (X untouched)
  (func $m_arith (param $d i32) (param $s i32) (param $sz i32) (param $mode i32) (result i32)
    (local $a i32) (local $b i32) (local $r i32) (local $x i32) (local $v i32) (local $c i32) (local $msb i32) (local $mask i32) (local $z i32)
    (local.set $mask (call $m_mask (local.get $sz))) (local.set $msb (call $m_msb (local.get $sz)))
    (local.set $a (i32.and (local.get $d) (local.get $mask))) (local.set $b (i32.and (local.get $s) (local.get $mask)))
    (if (i32.and (local.get $mode) (i32.const 2)) (then (local.set $x (call $m_X))))
    (if (i32.and (local.get $mode) (i32.const 1))
      (then (local.set $r (i32.and (i32.sub (i32.sub (local.get $a) (local.get $b)) (local.get $x)) (local.get $mask)))
        (local.set $v (i32.and (i32.and (i32.xor (local.get $a) (local.get $b)) (i32.xor (local.get $a) (local.get $r))) (local.get $msb)))
        (local.set $c (i32.and (i32.or (i32.and (i32.xor (local.get $a) (i32.const -1)) (local.get $b)) (i32.and (i32.or (i32.xor (local.get $a) (i32.const -1)) (local.get $b)) (local.get $r))) (local.get $msb))))
      (else (local.set $r (i32.and (i32.add (i32.add (local.get $a) (local.get $b)) (local.get $x)) (local.get $mask)))
        (local.set $v (i32.and (i32.and (i32.xor (local.get $a) (local.get $r)) (i32.xor (local.get $b) (local.get $r))) (local.get $msb)))
        (local.set $c (i32.and (i32.or (i32.and (local.get $a) (local.get $b)) (i32.and (i32.or (local.get $a) (local.get $b)) (i32.xor (local.get $r) (i32.const -1)))) (local.get $msb)))))
    (local.set $z (i32.and (call $zr16 (i32.const 20)) (i32.const 4)))
    (call $m_fl (local.get $r) (local.get $sz) (local.get $v) (local.get $c) (i32.eqz (i32.and (local.get $mode) (i32.const 8))))
    (if (i32.and (i32.and (local.get $mode) (i32.const 4)) (i32.eqz (local.get $z))) (then (call $zw16 (i32.const 20) (i32.and (call $zr16 (i32.const 20)) (i32.const 0xfffb)))))   ;; sticky Z: only ever cleared
    (local.get $r))
  ;; shifts and rotates one bit at a time: type 0 AS, 1 LS, 2 ROX, 3 RO; returns the result and sets the flags
  (func $m_shift (param $type i32) (param $left i32) (param $cnt i32) (param $v i32) (param $sz i32) (result i32)
    (local $r i32) (local $c i32) (local $x i32) (local $ov i32) (local $msb i32) (local $mask i32) (local $top i32) (local $sign i32)
    (local.set $mask (call $m_mask (local.get $sz))) (local.set $msb (call $m_msb (local.get $sz))) (local.set $top (i32.sub (i32.shl (i32.const 8) (local.get $sz)) (i32.const 1)))
    (local.set $r (i32.and (local.get $v) (local.get $mask))) (local.set $x (call $m_X)) (local.set $sign (i32.and (local.get $r) (local.get $msb)))
    (if (i32.eqz (local.get $cnt)) (then
      (call $m_fl (local.get $r) (local.get $sz) (i32.const 0) (select (local.get $x) (i32.const 0) (i32.eq (local.get $type) (i32.const 2))) (i32.const 0))
      (return (local.get $r))))
    (block $e (loop $l (br_if $e (i32.eqz (local.get $cnt)))
      (if (local.get $left)
        (then (local.set $c (i32.ne (i32.and (local.get $r) (local.get $msb)) (i32.const 0)))
          (local.set $r (i32.and (i32.shl (local.get $r) (i32.const 1)) (local.get $mask)))
          (if (i32.eq (local.get $type) (i32.const 2)) (then (local.set $r (i32.or (local.get $r) (local.get $x)))))
          (if (i32.eq (local.get $type) (i32.const 3)) (then (local.set $r (i32.or (local.get $r) (local.get $c)))))
          (if (i32.ne (i32.and (local.get $r) (local.get $msb)) (local.get $sign)) (then (local.set $ov (i32.const 1)))))
        (else (local.set $c (i32.and (local.get $r) (i32.const 1)))
          (local.set $r (i32.shr_u (local.get $r) (i32.const 1)))
          (if (i32.eqz (local.get $type)) (then (local.set $r (i32.or (local.get $r) (local.get $sign)))))
          (if (i32.eq (local.get $type) (i32.const 2)) (then (local.set $r (i32.or (local.get $r) (i32.shl (local.get $x) (local.get $top))))))
          (if (i32.eq (local.get $type) (i32.const 3)) (then (local.set $r (i32.or (local.get $r) (i32.shl (local.get $c) (local.get $top))))))))
      (if (i32.ne (local.get $type) (i32.const 3)) (then (local.set $x (local.get $c))))
      (local.set $cnt (i32.sub (local.get $cnt) (i32.const 1))) (br $l)))
    (call $m_fl (local.get $r) (local.get $sz) (i32.and (local.get $ov) (i32.and (i32.eqz (local.get $type)) (local.get $left))) (local.get $c) (i32.ne (local.get $type) (i32.const 3)))
    (local.get $r))
  ;; Dn <op> ea / ea <op> Dn for OR (0) AND (1) ADD (2) SUB (3) CMP (4) EOR (5); opmode from the opcode
  (func $m_dyadic (param $op i32) (param $kind i32)
    (local $opmode i32) (local $sz i32) (local $dn i32) (local $ea i32) (local $d i32) (local $s i32) (local $r i32) (local $tomem i32)
    (local.set $opmode (i32.and (i32.shr_u (local.get $op) (i32.const 6)) (i32.const 7))) (local.set $sz (i32.and (local.get $opmode) (i32.const 3)))
    (local.set $dn (i32.and (i32.shr_u (local.get $op) (i32.const 9)) (i32.const 7))) (local.set $tomem (i32.and (local.get $opmode) (i32.const 4)))
    (local.set $ea (call $m_ea (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 7)) (i32.and (local.get $op) (i32.const 7)) (local.get $sz)))
    (if (local.get $tomem)
      (then (local.set $d (call $m_ld (local.get $ea) (local.get $sz))) (local.set $s (call $m_d (local.get $dn))))
      (else (local.set $d (call $m_d (local.get $dn))) (local.set $s (call $m_ld (local.get $ea) (local.get $sz)))))
    (if (i32.ge_u (local.get $kind) (i32.const 2)) (then (if (i32.lt_u (local.get $kind) (i32.const 5)) (then
      (local.set $r (call $m_arith (local.get $d) (local.get $s) (local.get $sz) (select (i32.const 0) (select (i32.const 1) (i32.const 9) (i32.eq (local.get $kind) (i32.const 3))) (i32.eq (local.get $kind) (i32.const 2)))))   ;; ADD 0, SUB 1, CMP 9
      (if (i32.eq (local.get $kind) (i32.const 4)) (then (return)))
      (if (local.get $tomem) (then (call $m_st (local.get $ea) (local.get $sz) (local.get $r))) (else (call $m_st (i32.add (i32.const 0x10000) (local.get $dn)) (local.get $sz) (local.get $r))))
      (return)))))
    (local.set $r (select (i32.or (local.get $d) (local.get $s)) (select (i32.and (local.get $d) (local.get $s)) (i32.xor (local.get $d) (local.get $s)) (i32.eq (local.get $kind) (i32.const 1))) (i32.eqz (local.get $kind))))
    (call $m_fl (local.get $r) (local.get $sz) (i32.const 0) (i32.const 0) (i32.const 0))
    (if (local.get $tomem) (then (call $m_st (local.get $ea) (local.get $sz) (local.get $r))) (else (call $m_st (i32.add (i32.const 0x10000) (local.get $dn)) (local.get $sz) (local.get $r)))))
  ;; BTST BCHG BCLR BSET (type 0..3) on ea with bit number b: long on a data register, byte in memory
  (func $m_bitop (param $op i32) (param $type i32) (param $b i32)
    (local $ea i32) (local $sz i32) (local $d i32) (local $m i32)
    (local.set $sz (select (i32.const 2) (i32.const 0) (i32.eqz (i32.and (local.get $op) (i32.const 0x38)))))
    (local.set $ea (call $m_ea (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 7)) (i32.and (local.get $op) (i32.const 7)) (local.get $sz)))
    (local.set $m (i32.shl (i32.const 1) (i32.and (local.get $b) (select (i32.const 31) (i32.const 7) (local.get $sz)))))
    (local.set $d (call $m_ld (local.get $ea) (local.get $sz)))
    (call $zw16 (i32.const 20) (i32.or (i32.and (call $zr16 (i32.const 20)) (i32.const 0xfffb)) (select (i32.const 0) (i32.const 4) (i32.and (local.get $d) (local.get $m)))))
    (if (i32.eqz (local.get $type)) (then (return)))
    (if (i32.eq (local.get $type) (i32.const 1)) (then (local.set $d (i32.xor (local.get $d) (local.get $m)))))
    (if (i32.eq (local.get $type) (i32.const 2)) (then (local.set $d (i32.and (local.get $d) (i32.xor (local.get $m) (i32.const -1))))))
    (if (i32.eq (local.get $type) (i32.const 3)) (then (local.set $d (i32.or (local.get $d) (local.get $m)))))
    (call $m_st (local.get $ea) (local.get $sz) (local.get $d)))
  (func $m_movem (param $op i32) (param $tomem i32)
    (local $mask i32) (local $sz i32) (local $mode i32) (local $reg i32) (local $a i32) (local $k i32) (local $n i32)
    (local.set $mask (call $m_fetch)) (local.set $sz (select (i32.const 2) (i32.const 1) (i32.and (local.get $op) (i32.const 0x40)))) (local.set $n (i32.shl (i32.const 1) (local.get $sz)))
    (local.set $mode (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 7))) (local.set $reg (i32.and (local.get $op) (i32.const 7)))
    (if (i32.and (local.get $tomem) (i32.eq (local.get $mode) (i32.const 4))) (then   ;; predecrement: A7 first, mask reversed
      (local.set $a (call $m_a (local.get $reg)))
      (block $e (loop $l (br_if $e (i32.ge_u (local.get $k) (i32.const 16)))
        (if (i32.and (local.get $mask) (i32.shl (i32.const 1) (local.get $k))) (then
          (local.set $a (i32.sub (local.get $a) (local.get $n))) (call $m_st (i32.and (local.get $a) (i32.const 0xffff)) (local.get $sz) (call $m_rr (i32.sub (i32.const 15) (local.get $k))))))
        (local.set $k (i32.add (local.get $k) (i32.const 1))) (br $l)))
      (call $m_aw (local.get $reg) (local.get $a))
      (return)))
    (local.set $a (call $m_ea (select (i32.const 2) (local.get $mode) (i32.eq (local.get $mode) (i32.const 3))) (local.get $reg) (local.get $sz)))   ;; postincrement is applied at the end
    (if (i32.ge_u (local.get $a) (i32.const 0x10000)) (then (return)))
    (block $e (loop $l (br_if $e (i32.ge_u (local.get $k) (i32.const 16)))
      (if (i32.and (local.get $mask) (i32.shl (i32.const 1) (local.get $k))) (then
        (if (local.get $tomem) (then (call $m_st (local.get $a) (local.get $sz) (call $m_rr (local.get $k))))
          (else (call $m_rw (local.get $k) (call $m_sx (call $m_ld (local.get $a) (local.get $sz)) (local.get $sz)))))
        (local.set $a (i32.and (i32.add (local.get $a) (local.get $n)) (i32.const 0xffff)))))
      (local.set $k (i32.add (local.get $k) (i32.const 1))) (br $l)))
    (if (i32.eq (local.get $mode) (i32.const 3)) (then (call $m_aw (local.get $reg) (local.get $a)))))
  (func $m68k_step
    (local $op i32) (local $line i32) (local $sz i32) (local $mode i32) (local $reg i32) (local $ea i32) (local $d i32) (local $s i32) (local $r i32) (local $t i32) (local $n i32) (local $pc i32) (local $opmode i32) (local $cnt i32)
    (local.set $op (call $m_fetch)) (local.set $line (i32.shr_u (local.get $op) (i32.const 12)))
    (local.set $mode (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 7))) (local.set $reg (i32.and (local.get $op) (i32.const 7)))
    (local.set $sz (i32.and (i32.shr_u (local.get $op) (i32.const 6)) (i32.const 3))) (local.set $n (i32.and (i32.shr_u (local.get $op) (i32.const 9)) (i32.const 7)))
    (local.set $opmode (i32.and (i32.shr_u (local.get $op) (i32.const 6)) (i32.const 7)))
    (block $end
      (if (i32.eqz (local.get $line)) (then
        (if (i32.and (local.get $op) (i32.const 0x100)) (then   ;; dynamic bit ops (MOVEP is a NOP)
          (if (i32.ne (local.get $mode) (i32.const 1)) (then (call $m_bitop (local.get $op) (local.get $sz) (call $m_d (local.get $n)))))
          (br $end)))
        (if (i32.eq (local.get $n) (i32.const 4)) (then (call $m_bitop (local.get $op) (local.get $sz) (i32.and (call $m_fetch) (i32.const 0xff))) (br $end)))   ;; static bit ops
        (if (i32.eq (local.get $sz) (i32.const 3)) (then (br $end)))
        ;; ORI ANDI SUBI ADDI EORI CMPI #imm,ea (imm first in the stream); ea = #imm means CCR/SR
        (local.set $s (select (i32.and (call $m_fetch) (i32.const 0xff)) (select (call $m_fetch32) (call $m_fetch) (i32.eq (local.get $sz) (i32.const 2))) (i32.eqz (local.get $sz))))
        (if (i32.eq (i32.and (local.get $op) (i32.const 0x3f)) (i32.const 0x3c)) (then
          (local.set $d (call $zr16 (i32.const 20)))
          (local.set $r (select (i32.or (local.get $d) (local.get $s)) (select (i32.and (local.get $d) (local.get $s)) (i32.xor (local.get $d) (local.get $s)) (i32.eq (local.get $n) (i32.const 1))) (i32.eqz (local.get $n))))
          (if (i32.or (i32.eqz (local.get $n)) (i32.or (i32.eq (local.get $n) (i32.const 1)) (i32.eq (local.get $n) (i32.const 5)))) (then (call $zw16 (i32.const 20) (i32.and (local.get $r) (i32.const 0xff1f)))))
          (br $end)))
        (local.set $ea (call $m_ea (local.get $mode) (local.get $reg) (local.get $sz))) (local.set $d (call $m_ld (local.get $ea) (local.get $sz)))
        (if (i32.eq (local.get $n) (i32.const 6)) (then (drop (call $m_arith (local.get $d) (local.get $s) (local.get $sz) (i32.const 9))) (br $end)))
        (if (i32.eq (local.get $n) (i32.const 2)) (then (call $m_st (local.get $ea) (local.get $sz) (call $m_arith (local.get $d) (local.get $s) (local.get $sz) (i32.const 1))) (br $end)))
        (if (i32.eq (local.get $n) (i32.const 3)) (then (call $m_st (local.get $ea) (local.get $sz) (call $m_arith (local.get $d) (local.get $s) (local.get $sz) (i32.const 0))) (br $end)))
        (local.set $r (select (i32.or (local.get $d) (local.get $s)) (select (i32.and (local.get $d) (local.get $s)) (i32.xor (local.get $d) (local.get $s)) (i32.eq (local.get $n) (i32.const 1))) (i32.eqz (local.get $n))))
        (if (i32.eq (local.get $n) (i32.const 7)) (then (br $end)))
        (call $m_fl (local.get $r) (local.get $sz) (i32.const 0) (i32.const 0) (i32.const 0)) (call $m_st (local.get $ea) (local.get $sz) (local.get $r))
        (br $end)))
      (if (i32.le_u (local.get $line) (i32.const 3)) (then   ;; MOVE / MOVEA
        (local.set $sz (select (i32.const 0) (select (i32.const 2) (i32.const 1) (i32.eq (local.get $line) (i32.const 2))) (i32.eq (local.get $line) (i32.const 1))))
        (local.set $s (call $m_ld (call $m_ea (local.get $mode) (local.get $reg) (local.get $sz)) (local.get $sz)))
        (if (i32.eq (local.get $opmode) (i32.const 1)) (then (call $m_aw (local.get $n) (call $m_sx (local.get $s) (local.get $sz))) (br $end)))
        (call $m_fl (local.get $s) (local.get $sz) (i32.const 0) (i32.const 0) (i32.const 0))
        (call $m_st (call $m_ea (local.get $opmode) (local.get $n) (local.get $sz)) (local.get $sz) (local.get $s))
        (br $end)))
      (if (i32.eq (local.get $line) (i32.const 4)) (then
        (if (i32.eq (local.get $opmode) (i32.const 7)) (then (call $m_aw (local.get $n) (call $m_ea (local.get $mode) (local.get $reg) (i32.const 2))) (br $end)))   ;; LEA
        (if (i32.eq (local.get $opmode) (i32.const 6)) (then (drop (call $m_ea (local.get $mode) (local.get $reg) (i32.const 1))) (br $end)))   ;; CHK: NOP
        (local.set $t (i32.and (i32.shr_u (local.get $op) (i32.const 8)) (i32.const 15)))
        (if (i32.eq (i32.and (local.get $op) (i32.const 0xff80)) (i32.const 0x4e80)) (then   ;; JSR / JMP
          (local.set $ea (call $m_ea (local.get $mode) (local.get $reg) (i32.const 2)))
          (if (i32.lt_u (local.get $ea) (i32.const 0x10000)) (then
            (if (i32.eqz (i32.and (local.get $op) (i32.const 0x40))) (then (call $m_push (call $zr16 (i32.const 22)))))
            (call $zw16 (i32.const 22) (local.get $ea))))
          (br $end)))
        (if (i32.eq (i32.and (local.get $op) (i32.const 0xfff0)) (i32.const 0x4e70)) (then   ;; RESET NOP STOP RTE RTD RTS TRAPV RTR
          (if (i32.eq (local.get $op) (i32.const 0x4e72)) (then (drop (call $m_fetch))))
          (if (i32.eq (local.get $op) (i32.const 0x4e73)) (then (call $zw16 (i32.const 20) (i32.and (call $m_pop16) (i32.const 0xff1f))) (call $zw16 (i32.const 22) (i32.and (call $m_pop) (i32.const 0xffff)))))
          (if (i32.eq (local.get $op) (i32.const 0x4e75)) (then (call $zw16 (i32.const 22) (i32.and (call $m_pop) (i32.const 0xffff)))))
          (if (i32.eq (local.get $op) (i32.const 0x4e77)) (then (call $zw16 (i32.const 20) (i32.or (i32.and (call $zr16 (i32.const 20)) (i32.const 0xff00)) (i32.and (call $m_pop16) (i32.const 0x1f)))) (call $zw16 (i32.const 22) (i32.and (call $m_pop) (i32.const 0xffff)))))
          (br $end)))
        (if (i32.eq (i32.and (local.get $op) (i32.const 0xfff8)) (i32.const 0x4e50)) (then   ;; LINK
          (call $m_push (call $m_a (local.get $reg))) (call $m_aw (local.get $reg) (call $m_a (i32.const 7)))
          (call $m_aw (i32.const 7) (i32.add (call $m_a (i32.const 7)) (call $sx (call $m_fetch) (i32.const 16)))) (br $end)))
        (if (i32.eq (i32.and (local.get $op) (i32.const 0xfff8)) (i32.const 0x4e58)) (then   ;; UNLK
          (call $m_aw (i32.const 7) (call $m_a (local.get $reg))) (call $m_aw (local.get $reg) (call $m_pop)) (br $end)))
        (if (i32.eq (i32.and (local.get $op) (i32.const 0xff00)) (i32.const 0x4e00)) (then (br $end)))   ;; TRAP, MOVE USP, others
        (if (i32.eq (i32.and (local.get $op) (i32.const 0xfb80)) (i32.const 0x4880)) (then   ;; MOVEM (mode != 0) or EXT (mode 0)
          (if (local.get $mode) (then (call $m_movem (local.get $op) (i32.eqz (i32.and (local.get $op) (i32.const 0x400)))) (br $end)))
          (if (i32.and (local.get $op) (i32.const 0x400)) (then (br $end)))
          (local.set $d (call $m_d (local.get $reg)))
          (if (i32.and (local.get $op) (i32.const 0x40))
            (then (local.set $r (call $sx (local.get $d) (i32.const 16))) (call $m_dw (local.get $reg) (local.get $r)) (call $m_fl (local.get $r) (i32.const 2) (i32.const 0) (i32.const 0) (i32.const 0)))
            (else (local.set $r (i32.or (i32.and (local.get $d) (i32.const 0xffff0000)) (i32.and (call $sext8 (local.get $d)) (i32.const 0xffff)))) (call $m_dw (local.get $reg) (local.get $r)) (call $m_fl (local.get $r) (i32.const 1) (i32.const 0) (i32.const 0) (i32.const 0))))
          (br $end)))
        (if (i32.eq (i32.and (local.get $op) (i32.const 0xfff8)) (i32.const 0x4840)) (then   ;; SWAP
          (local.set $d (call $m_d (local.get $reg))) (local.set $r (i32.or (i32.shl (local.get $d) (i32.const 16)) (i32.shr_u (local.get $d) (i32.const 16))))
          (call $m_dw (local.get $reg) (local.get $r)) (call $m_fl (local.get $r) (i32.const 2) (i32.const 0) (i32.const 0) (i32.const 0)) (br $end)))
        (if (i32.eq (i32.and (local.get $op) (i32.const 0xffc0)) (i32.const 0x4840)) (then   ;; PEA (BKPT is in 0x4848..4f, mode 1: NOP)
          (if (i32.ne (local.get $mode) (i32.const 1)) (then (local.set $ea (call $m_ea (local.get $mode) (local.get $reg) (i32.const 2))) (if (i32.lt_u (local.get $ea) (i32.const 0x10000)) (then (call $m_push (local.get $ea))))))
          (br $end)))
        (if (i32.eq (i32.and (local.get $op) (i32.const 0xffc0)) (i32.const 0x4800)) (then (br $end)))   ;; NBCD
        (if (i32.eq (i32.and (local.get $op) (i32.const 0xff00)) (i32.const 0x4a00)) (then   ;; TST / TAS / ILLEGAL
          (if (i32.eq (local.get $op) (i32.const 0x4afc)) (then (br $end)))
          (if (i32.eq (local.get $sz) (i32.const 3)) (then
            (local.set $ea (call $m_ea (local.get $mode) (local.get $reg) (i32.const 0))) (local.set $d (call $m_ld (local.get $ea) (i32.const 0)))
            (call $m_fl (local.get $d) (i32.const 0) (i32.const 0) (i32.const 0) (i32.const 0)) (call $m_st (local.get $ea) (i32.const 0) (i32.or (local.get $d) (i32.const 0x80))) (br $end)))
          (call $m_fl (call $m_ld (call $m_ea (local.get $mode) (local.get $reg) (local.get $sz)) (local.get $sz)) (local.get $sz) (i32.const 0) (i32.const 0) (i32.const 0))
          (br $end)))
        (if (i32.eq (local.get $sz) (i32.const 3)) (then   ;; MOVE from SR (40C0), to CCR (44C0), to SR (46C0)
          (if (i32.eqz (local.get $t)) (then (call $m_st (call $m_ea (local.get $mode) (local.get $reg) (i32.const 1)) (i32.const 1) (i32.or (call $zr16 (i32.const 20)) (i32.const 0x2000))) (br $end)))
          (local.set $s (call $m_ld (call $m_ea (local.get $mode) (local.get $reg) (i32.const 1)) (i32.const 1)))
          (if (i32.eq (local.get $t) (i32.const 4)) (then (call $zw16 (i32.const 20) (i32.or (i32.and (call $zr16 (i32.const 20)) (i32.const 0xff00)) (i32.and (local.get $s) (i32.const 0x1f))))))
          (if (i32.eq (local.get $t) (i32.const 6)) (then (call $zw16 (i32.const 20) (i32.and (local.get $s) (i32.const 0xff1f)))))
          (br $end)))
        ;; NEGX (40) CLR (42) NEG (44) NOT (46)
        (local.set $ea (call $m_ea (local.get $mode) (local.get $reg) (local.get $sz))) (local.set $d (call $m_ld (local.get $ea) (local.get $sz)))
        (if (i32.eqz (local.get $t)) (then (call $m_st (local.get $ea) (local.get $sz) (call $m_arith (i32.const 0) (local.get $d) (local.get $sz) (i32.const 7))) (br $end)))
        (if (i32.eq (local.get $t) (i32.const 2)) (then (call $m_fl (i32.const 0) (local.get $sz) (i32.const 0) (i32.const 0) (i32.const 0)) (call $m_st (local.get $ea) (local.get $sz) (i32.const 0)) (br $end)))
        (if (i32.eq (local.get $t) (i32.const 4)) (then (call $m_st (local.get $ea) (local.get $sz) (call $m_arith (i32.const 0) (local.get $d) (local.get $sz) (i32.const 1))) (br $end)))
        (if (i32.eq (local.get $t) (i32.const 6)) (then (local.set $r (i32.xor (local.get $d) (i32.const -1))) (call $m_fl (local.get $r) (local.get $sz) (i32.const 0) (i32.const 0) (i32.const 0)) (call $m_st (local.get $ea) (local.get $sz) (local.get $r))))
        (br $end)))
      (if (i32.eq (local.get $line) (i32.const 5)) (then
        (if (i32.eq (local.get $sz) (i32.const 3)) (then   ;; Scc / DBcc
          (local.set $t (call $m_cc (i32.shr_u (local.get $op) (i32.const 8))))
          (if (i32.eq (local.get $mode) (i32.const 1)) (then
            (local.set $pc (call $zr16 (i32.const 22))) (local.set $s (call $sx (call $m_fetch) (i32.const 16)))
            (if (i32.eqz (local.get $t)) (then
              (local.set $r (i32.and (i32.sub (call $m_d (local.get $reg)) (i32.const 1)) (i32.const 0xffff)))
              (call $m_st (i32.add (i32.const 0x10000) (local.get $reg)) (i32.const 1) (local.get $r))
              (if (i32.ne (local.get $r) (i32.const 0xffff)) (then (call $zw16 (i32.const 22) (i32.and (i32.add (local.get $pc) (local.get $s)) (i32.const 0xffff)))))))
            (br $end)))
          (call $m_st (call $m_ea (local.get $mode) (local.get $reg) (i32.const 0)) (i32.const 0) (select (i32.const 0xff) (i32.const 0) (local.get $t)))
          (br $end)))
        (local.set $s (select (i32.const 8) (local.get $n) (i32.eqz (local.get $n))))   ;; ADDQ / SUBQ
        (if (i32.eq (local.get $mode) (i32.const 1)) (then
          (call $m_aw (local.get $reg) (select (i32.sub (call $m_a (local.get $reg)) (local.get $s)) (i32.add (call $m_a (local.get $reg)) (local.get $s)) (i32.and (local.get $op) (i32.const 0x100)))) (br $end)))
        (local.set $ea (call $m_ea (local.get $mode) (local.get $reg) (local.get $sz)))
        (call $m_st (local.get $ea) (local.get $sz) (call $m_arith (call $m_ld (local.get $ea) (local.get $sz)) (local.get $s) (local.get $sz) (i32.shr_u (i32.and (local.get $op) (i32.const 0x100)) (i32.const 8))))
        (br $end)))
      (if (i32.eq (local.get $line) (i32.const 6)) (then   ;; Bcc BRA BSR
        (local.set $pc (call $zr16 (i32.const 22))) (local.set $s (call $sext8 (local.get $op)))
        (if (i32.eqz (local.get $s)) (then (local.set $s (call $sx (call $m_fetch) (i32.const 16)))))
        (local.set $t (i32.and (i32.shr_u (local.get $op) (i32.const 8)) (i32.const 15)))
        (if (i32.eq (local.get $t) (i32.const 1)) (then (call $m_push (call $zr16 (i32.const 22))) (local.set $t (i32.const 0))))
        (if (call $m_cc (local.get $t)) (then (call $zw16 (i32.const 22) (i32.and (i32.add (local.get $pc) (local.get $s)) (i32.const 0xffff)))))
        (br $end)))
      (if (i32.eq (local.get $line) (i32.const 7)) (then   ;; MOVEQ
        (if (i32.eqz (i32.and (local.get $op) (i32.const 0x100))) (then (local.set $r (call $sext8 (local.get $op))) (call $m_dw (local.get $n) (local.get $r)) (call $m_fl (local.get $r) (i32.const 2) (i32.const 0) (i32.const 0) (i32.const 0))))
        (br $end)))
      (if (i32.or (i32.eq (local.get $line) (i32.const 8)) (i32.eq (local.get $line) (i32.const 12))) (then   ;; OR/DIV/SBCD, AND/MUL/ABCD/EXG
        (if (i32.eq (i32.and (local.get $opmode) (i32.const 3)) (i32.const 3)) (then   ;; MULU MULS DIVU DIVS
          (local.set $s (call $m_ld (call $m_ea (local.get $mode) (local.get $reg) (i32.const 1)) (i32.const 1))) (local.set $d (call $m_d (local.get $n)))
          (if (i32.eq (local.get $line) (i32.const 12)) (then
            (local.set $r (select (i32.mul (call $sx (local.get $d) (i32.const 16)) (call $sx (local.get $s) (i32.const 16))) (i32.mul (i32.and (local.get $d) (i32.const 0xffff)) (local.get $s)) (i32.and (local.get $opmode) (i32.const 4))))
            (call $m_dw (local.get $n) (local.get $r)) (call $m_fl (local.get $r) (i32.const 2) (i32.const 0) (i32.const 0) (i32.const 0)) (br $end)))
          (if (i32.eqz (local.get $s)) (then (br $end)))
          (if (i32.and (local.get $opmode) (i32.const 4))
            (then (local.set $s (call $sx (local.get $s) (i32.const 16)))
              (if (i32.and (i32.eq (local.get $d) (i32.const 0x80000000)) (i32.eq (local.get $s) (i32.const -1))) (then (call $m_fl (local.get $d) (i32.const 2) (i32.const 1) (i32.const 0) (i32.const 0)) (br $end)))
              (local.set $r (i32.div_s (local.get $d) (local.get $s))) (local.set $t (i32.rem_s (local.get $d) (local.get $s)))
              (if (i32.ne (call $sx (local.get $r) (i32.const 16)) (local.get $r)) (then (call $m_fl (local.get $d) (i32.const 2) (i32.const 1) (i32.const 0) (i32.const 0)) (br $end))))
            (else (local.set $r (i32.div_u (local.get $d) (local.get $s))) (local.set $t (i32.rem_u (local.get $d) (local.get $s)))
              (if (i32.gt_u (local.get $r) (i32.const 0xffff)) (then (call $m_fl (local.get $d) (i32.const 2) (i32.const 1) (i32.const 0) (i32.const 0)) (br $end)))))
          (call $m_dw (local.get $n) (i32.or (i32.shl (local.get $t) (i32.const 16)) (i32.and (local.get $r) (i32.const 0xffff))))
          (call $m_fl (local.get $r) (i32.const 1) (i32.const 0) (i32.const 0) (i32.const 0))
          (br $end)))
        (if (i32.and (i32.and (local.get $opmode) (i32.const 4)) (i32.lt_u (local.get $mode) (i32.const 2))) (then   ;; SBCD/ABCD (NOPs) and EXG
          (if (i32.eq (local.get $line) (i32.const 12)) (then
            (local.set $t (i32.and (local.get $op) (i32.const 0xf8)))
            (if (i32.eq (local.get $t) (i32.const 0x40)) (then (local.set $d (call $m_d (local.get $n))) (call $m_dw (local.get $n) (call $m_d (local.get $reg))) (call $m_dw (local.get $reg) (local.get $d))))
            (if (i32.eq (local.get $t) (i32.const 0x48)) (then (local.set $d (call $m_a (local.get $n))) (call $m_aw (local.get $n) (call $m_a (local.get $reg))) (call $m_aw (local.get $reg) (local.get $d))))
            (if (i32.eq (local.get $t) (i32.const 0x88)) (then (local.set $d (call $m_d (local.get $n))) (call $m_dw (local.get $n) (call $m_a (local.get $reg))) (call $m_aw (local.get $reg) (local.get $d))))))
          (br $end)))
        (call $m_dyadic (local.get $op) (i32.eq (local.get $line) (i32.const 12)))
        (br $end)))
      (if (i32.or (i32.eq (local.get $line) (i32.const 9)) (i32.eq (local.get $line) (i32.const 13))) (then   ;; SUB/SUBA/SUBX, ADD/ADDA/ADDX
        (local.set $t (i32.eq (local.get $line) (i32.const 9)))   ;; 1 = subtract
        (if (i32.eq (i32.and (local.get $opmode) (i32.const 3)) (i32.const 3)) (then
          (local.set $sz (select (i32.const 2) (i32.const 1) (i32.and (local.get $opmode) (i32.const 4))))
          (local.set $s (call $m_sx (call $m_ld (call $m_ea (local.get $mode) (local.get $reg) (local.get $sz)) (local.get $sz)) (local.get $sz)))
          (call $m_aw (local.get $n) (select (i32.sub (call $m_a (local.get $n)) (local.get $s)) (i32.add (call $m_a (local.get $n)) (local.get $s)) (local.get $t)))
          (br $end)))
        (if (i32.and (i32.and (local.get $opmode) (i32.const 4)) (i32.lt_u (local.get $mode) (i32.const 2))) (then   ;; ADDX / SUBX: Dy,Dx or -(Ay),-(Ax)
          (if (local.get $mode)
            (then (local.set $s (call $m_ld (call $m_ea (i32.const 4) (local.get $reg) (local.get $sz)) (local.get $sz)))
              (local.set $ea (call $m_ea (i32.const 4) (local.get $n) (local.get $sz))))
            (else (local.set $s (call $m_d (local.get $reg))) (local.set $ea (i32.add (i32.const 0x10000) (local.get $n)))))
          (call $m_st (local.get $ea) (local.get $sz) (call $m_arith (call $m_ld (local.get $ea) (local.get $sz)) (local.get $s) (local.get $sz) (i32.or (i32.const 6) (local.get $t))))
          (br $end)))
        (call $m_dyadic (local.get $op) (select (i32.const 3) (i32.const 2) (local.get $t)))
        (br $end)))
      (if (i32.eq (local.get $line) (i32.const 11)) (then   ;; CMP CMPA CMPM EOR
        (if (i32.eq (i32.and (local.get $opmode) (i32.const 3)) (i32.const 3)) (then
          (local.set $sz (select (i32.const 2) (i32.const 1) (i32.and (local.get $opmode) (i32.const 4))))
          (local.set $s (call $m_sx (call $m_ld (call $m_ea (local.get $mode) (local.get $reg) (local.get $sz)) (local.get $sz)) (local.get $sz)))
          (drop (call $m_arith (call $m_a (local.get $n)) (local.get $s) (i32.const 2) (i32.const 9)))
          (br $end)))
        (if (i32.and (local.get $opmode) (i32.const 4)) (then
          (if (i32.eq (local.get $mode) (i32.const 1)) (then   ;; CMPM (Ay)+,(Ax)+
            (local.set $s (call $m_ld (call $m_ea (i32.const 3) (local.get $reg) (local.get $sz)) (local.get $sz)))
            (drop (call $m_arith (call $m_ld (call $m_ea (i32.const 3) (local.get $n) (local.get $sz)) (local.get $sz)) (local.get $s) (local.get $sz) (i32.const 9)))
            (br $end)))
          (call $m_dyadic (local.get $op) (i32.const 5)) (br $end)))
        (call $m_dyadic (local.get $op) (i32.const 4))
        (br $end)))
      (if (i32.eq (local.get $line) (i32.const 14)) (then   ;; shifts and rotates
        (if (i32.eq (local.get $sz) (i32.const 3)) (then   ;; memory form: word, by one
          (local.set $ea (call $m_ea (local.get $mode) (local.get $reg) (i32.const 1)))
          (call $m_st (local.get $ea) (i32.const 1) (call $m_shift (i32.and (local.get $n) (i32.const 3)) (i32.and (local.get $op) (i32.const 0x100)) (i32.const 1) (call $m_ld (local.get $ea) (i32.const 1)) (i32.const 1)))
          (br $end)))
        (local.set $cnt (select (i32.and (call $m_d (local.get $n)) (i32.const 63)) (select (i32.const 8) (local.get $n) (i32.eqz (local.get $n))) (i32.and (local.get $op) (i32.const 0x20))))
        (call $m_st (i32.add (i32.const 0x10000) (local.get $reg)) (local.get $sz) (call $m_shift (i32.and (i32.shr_u (local.get $op) (i32.const 3)) (i32.const 3)) (i32.and (local.get $op) (i32.const 0x100)) (local.get $cnt) (call $m_d (local.get $reg)) (local.get $sz)))
        (br $end)))))
  ;; ========================================================================
  ;; Shared helpers for the wide-word machines: an n-bit field (n <= 64) at pixel bit offset
  ;; off (off + n <= 128) read and written as an i64, and 32/64-bit register-file access.
  (func $zr32 (param $o i32) (result i32) (i32.load offset=256 (local.get $o)))
  (func $zw32 (param $o i32) (param $v i32) (i32.store offset=256 (local.get $o) (local.get $v)))
  (func $zr64 (param $o i32) (result i64) (i64.load offset=256 (local.get $o)))
  (func $zw64 (param $o i32) (param $v i64) (i64.store offset=256 (local.get $o) (local.get $v)))
  (func $fmask (param $n i32) (result i64)
    (if (i32.ge_u (local.get $n) (i32.const 64)) (then (return (i64.const -1))))
    (i64.sub (i64.shl (i64.const 1) (i64.extend_i32_u (local.get $n))) (i64.const 1)))
  (func $fld_rd (param $off i32) (param $n i32) (result i64)
    (local $lo i64) (local $hi i64) (local $v i64)
    (local.set $lo (i64.load (global.get $zp))) (local.set $hi (i64.load offset=8 (global.get $zp)))
    (if (i32.ge_u (local.get $off) (i32.const 64)) (then
      (return (i64.and (i64.shr_u (local.get $hi) (i64.extend_i32_u (i32.sub (local.get $off) (i32.const 64)))) (call $fmask (local.get $n))))))
    (local.set $v (i64.shr_u (local.get $lo) (i64.extend_i32_u (local.get $off))))
    (if (local.get $off) (then
      (local.set $v (i64.or (local.get $v) (i64.shl (local.get $hi) (i64.extend_i32_u (i32.sub (i32.const 64) (local.get $off))))))))
    (i64.and (local.get $v) (call $fmask (local.get $n))))
  (func $fld_wr (param $off i32) (param $n i32) (param $v i64)
    (local $lo i64) (local $hi i64) (local $m i64) (local $s i32)
    (local.set $lo (i64.load (global.get $zp))) (local.set $hi (i64.load offset=8 (global.get $zp)))
    (local.set $m (call $fmask (local.get $n)))
    (local.set $v (i64.and (local.get $v) (local.get $m)))
    (if (i32.ge_u (local.get $off) (i32.const 64)) (then
      (local.set $s (i32.sub (local.get $off) (i32.const 64)))
      (local.set $hi (i64.or (i64.and (local.get $hi) (i64.xor (i64.shl (local.get $m) (i64.extend_i32_u (local.get $s))) (i64.const -1)))
                             (i64.shl (local.get $v) (i64.extend_i32_u (local.get $s))))))
    (else
      (local.set $lo (i64.or (i64.and (local.get $lo) (i64.xor (i64.shl (local.get $m) (i64.extend_i32_u (local.get $off))) (i64.const -1)))
                             (i64.shl (local.get $v) (i64.extend_i32_u (local.get $off)))))
      (if (i32.and (i32.ne (local.get $off) (i32.const 0)) (i32.gt_u (i32.add (local.get $off) (local.get $n)) (i32.const 64))) (then
        (local.set $s (i32.sub (i32.const 64) (local.get $off)))
        (local.set $hi (i64.or (i64.and (local.get $hi) (i64.xor (i64.shr_u (local.get $m) (i64.extend_i32_u (local.get $s))) (i64.const -1)))
                               (i64.shr_u (local.get $v) (i64.extend_i32_u (local.get $s)))))))))
    (i64.store (global.get $zp) (local.get $lo)) (i64.store offset=8 (global.get $zp) (local.get $hi)))

  ;; ========================================================================
  ;; ERA / UNIVAC 1101 (kind 22). The pixel is 5 words of 24 bits (word k = bits 24k..24k+23).
  ;; Register file: A (48 bits, ones' complement) at 0..7, Q (24 bits) at 8..11, X (the operand
  ;; last read) at 12..15, PC (word number) at 22. Instruction word: operation (bits 23..18, two
  ;; octal digits as in the January 1950 ERA list), skip (17..14) and address y (13..0). The next
  ;; instruction is PC + 1 + skip (mod 5), jumps go to y mod 5, operands come from y mod 5.
  ;; A shifts and Q shifts are circular; multiply forms the 48-bit product of Q and (y); divide
  ;; leaves the quotient in Q and a non-negative remainder in A. Print and the three stops are NOPs.
  (func $u_mem (param $a i32) (result i32) (i32.wrap_i64 (call $fld_rd (i32.mul (i32.rem_u (local.get $a) (i32.const 5)) (i32.const 24)) (i32.const 24))))
  (func $u_set (param $a i32) (param $v i32) (call $fld_wr (i32.mul (i32.rem_u (local.get $a) (i32.const 5)) (i32.const 24)) (i32.const 24) (i64.extend_i32_u (local.get $v))))
  ;; 48-bit ones' complement add with end-around carry; -0 only comes out of -0 + -0
  (func $u_add (param $a i64) (param $b i64) (result i64)
    (local $s i64)
    (local.set $s (i64.add (local.get $a) (local.get $b)))
    (local.set $s (i64.add (i64.and (local.get $s) (i64.const 0xffffffffffff)) (i64.shr_u (local.get $s) (i64.const 48))))
    (if (i64.eq (local.get $s) (i64.const 0xffffffffffff)) (then
      (if (i32.eqz (i32.and (i64.eq (local.get $a) (i64.const 0xffffffffffff)) (i64.eq (local.get $b) (i64.const 0xffffffffffff))))
        (then (local.set $s (i64.const 0))))))
    (local.get $s))
  (func $u_sub (param $a i64) (param $b i64) (result i64) (call $u_add (local.get $a) (i64.xor (local.get $b) (i64.const 0xffffffffffff))))
  (func $u_sx (param $v i32) (result i64)   ;; 24-bit word sign-extended to 48 bits
    (i64.and (i64.extend_i32_s (i32.shr_s (i32.shl (local.get $v) (i32.const 8)) (i32.const 8))) (i64.const 0xffffffffffff)))
  (func $u_abs (param $v i32) (result i64)
    (if (i32.and (local.get $v) (i32.const 0x800000)) (then (return (i64.extend_i32_u (i32.and (i32.xor (local.get $v) (i32.const -1)) (i32.const 0xffffff))))))
    (i64.extend_i32_u (local.get $v)))
  (func $u_val (param $v i32) (result i64)   ;; ones' complement 24-bit word as a signed value
    (if (i32.and (local.get $v) (i32.const 0x800000)) (then (return (i64.sub (i64.const 0) (i64.extend_i32_u (i32.and (i32.xor (local.get $v) (i32.const -1)) (i32.const 0xffffff)))))))
    (i64.extend_i32_u (local.get $v)))
  (func $u_val48 (param $v i64) (result i64)
    (if (i64.ne (i64.and (local.get $v) (i64.const 0x800000000000)) (i64.const 0)) (then (return (i64.sub (i64.const 0) (i64.and (i64.xor (local.get $v) (i64.const -1)) (i64.const 0xffffffffffff))))))
    (local.get $v))
  (func $u_oc48 (param $v i64) (result i64)   ;; signed value -> 48-bit ones' complement
    (if (i64.lt_s (local.get $v) (i64.const 0)) (then (return (i64.and (i64.xor (i64.sub (i64.const 0) (local.get $v)) (i64.const -1)) (i64.const 0xffffffffffff)))))
    (i64.and (local.get $v) (i64.const 0xffffffffffff)))
  (func $u_rotl48 (param $a i64) (param $k i32) (result i64)
    (local.set $k (i32.rem_u (local.get $k) (i32.const 48)))
    (i64.and (i64.or (i64.shl (local.get $a) (i64.extend_i32_u (local.get $k))) (i64.shr_u (local.get $a) (i64.extend_i32_u (i32.sub (i32.const 48) (local.get $k))))) (i64.const 0xffffffffffff)))
  (func $u_rotl24 (param $q i32) (param $k i32) (result i32)
    (local.set $k (i32.rem_u (local.get $k) (i32.const 24)))
    (i32.and (i32.or (i32.shl (local.get $q) (local.get $k)) (i32.shr_u (local.get $q) (i32.sub (i32.const 24) (local.get $k)))) (i32.const 0xffffff)))
  (func $u1101_step
    (local $pc i32) (local $w i32) (local $op i32) (local $y i32) (local $x i32) (local $a i64) (local $q i32) (local $next i32) (local $jump i32)
    (local $n i64) (local $d i64) (local $r i64)
    (local.set $pc (call $zr16 (i32.const 22)))
    (local.set $w (call $u_mem (local.get $pc)))
    (local.set $op (i32.shr_u (local.get $w) (i32.const 18)))
    (local.set $y (i32.and (local.get $w) (i32.const 0x3fff)))
    (local.set $next (i32.rem_u (i32.add (i32.add (local.get $pc) (i32.const 1)) (i32.and (i32.shr_u (local.get $w) (i32.const 14)) (i32.const 15))) (i32.const 5)))
    (local.set $a (call $zr64 (i32.const 0)))
    (local.set $q (i32.and (call $zr32 (i32.const 8)) (i32.const 0xffffff)))
    (local.set $x (call $u_mem (local.get $y)))
    (call $zw32 (i32.const 12) (local.get $x))
    (block $end
      ;; 11 OP, 12 OA, 13 ON, 14 OS: clear/hold add/subtract (y)
      (if (i32.eq (local.get $op) (i32.const 0x09)) (then (local.set $a (call $u_sx (local.get $x))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x0a)) (then (local.set $a (call $u_add (local.get $a) (call $u_sx (local.get $x)))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x0b)) (then (local.set $a (call $u_sub (i64.const 0) (call $u_sx (local.get $x)))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x0c)) (then (local.set $a (call $u_sub (local.get $a) (call $u_sx (local.get $x)))) (br $end)))
      ;; 15 clear right half of A, 16 fill Q, 17 SD substitute digits: (y) <- (A) where Q has ones
      (if (i32.eq (local.get $op) (i32.const 0x0d)) (then (local.set $a (i64.and (local.get $a) (i64.const 0xffffff000000))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x0e)) (then (local.set $q (local.get $x)) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x0f)) (then
        (call $u_set (local.get $y) (i32.or (i32.and (local.get $x) (i32.xor (local.get $q) (i32.const -1))) (i32.and (i32.wrap_i64 (local.get $a)) (local.get $q)))) (br $end)))
      ;; 21 AP, 22 AA, 23 AN, 24 AS: the absolute value of (y)
      (if (i32.eq (local.get $op) (i32.const 0x11)) (then (local.set $a (call $u_abs (local.get $x))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x12)) (then (local.set $a (call $u_add (local.get $a) (call $u_abs (local.get $x)))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x13)) (then (local.set $a (call $u_sub (i64.const 0) (call $u_abs (local.get $x)))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x14)) (then (local.set $a (call $u_sub (local.get $a) (call $u_abs (local.get $x)))) (br $end)))
      ;; 25 AL k shift A left, 26 QL k shift Q left (circular, count = address field), 27 SE substitute execution address
      (if (i32.eq (local.get $op) (i32.const 0x15)) (then (local.set $a (call $u_rotl48 (local.get $a) (local.get $y))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x16)) (then (local.set $q (call $u_rotl24 (local.get $q) (local.get $y))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x17)) (then
        (call $u_set (local.get $y) (i32.or (i32.and (local.get $x) (i32.const 0xffc000)) (i32.and (i32.wrap_i64 (local.get $a)) (i32.const 0x3fff)))) (br $end)))
      ;; 31 SP, 32 SA, 33 SN, 34 SS: split (multiple precision) forms, (y) taken as 24 unsigned bits
      (if (i32.eq (local.get $op) (i32.const 0x19)) (then (local.set $a (i64.extend_i32_u (local.get $x))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x1a)) (then (local.set $a (call $u_add (local.get $a) (i64.extend_i32_u (local.get $x)))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x1b)) (then (local.set $a (call $u_sub (i64.const 0) (i64.extend_i32_u (local.get $x)))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x1c)) (then (local.set $a (call $u_sub (local.get $a) (i64.extend_i32_u (local.get $x)))) (br $end)))
      ;; 35 AY store the right half of A, 36 QY store Q
      (if (i32.eq (local.get $op) (i32.const 0x1d)) (then (call $u_set (local.get $y) (i32.wrap_i64 (local.get $a))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x1e)) (then (call $u_set (local.get $y) (local.get $q)) (br $end)))
      ;; 41 QP clear add from Q, 42 QA hold add from Q, 43 AQ transmit A to Q
      (if (i32.eq (local.get $op) (i32.const 0x21)) (then (local.set $a (call $u_sx (local.get $q))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x22)) (then (local.set $a (call $u_add (local.get $a) (call $u_sx (local.get $q)))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x23)) (then (local.set $q (i32.and (i32.wrap_i64 (local.get $a)) (i32.const 0xffffff))) (br $end)))
      ;; 44 QJ jump if q23 = 1 (Q shifts left 1 either way), 45 UJ jump, 46 CJ jump if A negative, 47 ZJ jump if A not zero
      (if (i32.eq (local.get $op) (i32.const 0x24)) (then
        (local.set $jump (i32.and (local.get $q) (i32.const 0x800000)))
        (local.set $q (call $u_rotl24 (local.get $q) (i32.const 1))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x25)) (then (local.set $jump (i32.const 1)) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x26)) (then (local.set $jump (i64.ne (i64.and (local.get $a) (i64.const 0x800000000000)) (i64.const 0))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x27)) (then
        (local.set $jump (i32.and (i64.ne (local.get $a) (i64.const 0)) (i64.ne (local.get $a) (i64.const 0xffffffffffff)))) (br $end)))
      ;; 51 LP clear logical multiply, 52 LA hold logical multiply: Q and (y)
      (if (i32.eq (local.get $op) (i32.const 0x29)) (then (local.set $a (i64.extend_i32_u (i32.and (local.get $q) (local.get $x)))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x2a)) (then (local.set $a (call $u_add (local.get $a) (i64.extend_i32_u (i32.and (local.get $q) (local.get $x))))) (br $end)))
      ;; 53 PO, 54 PP, 55 IS, 56 CS, 57 FS: print and stops are NOPs
      ;; 61 MP clear multiply, 62 MA hold multiply (Q times (y)), 63 DP divide A by (y)
      (if (i32.eq (local.get $op) (i32.const 0x31)) (then (local.set $a (call $u_oc48 (i64.mul (call $u_val (local.get $q)) (call $u_val (local.get $x))))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x32)) (then (local.set $a (call $u_add (local.get $a) (call $u_oc48 (i64.mul (call $u_val (local.get $q)) (call $u_val (local.get $x)))))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x33)) (then
        (local.set $d (call $u_val (local.get $x)))
        (br_if $end (i64.eqz (local.get $d)))
        (local.set $n (call $u_val48 (local.get $a)))
        (local.set $r (i64.rem_s (local.get $n) (local.get $d)))
        (if (i64.lt_s (local.get $r) (i64.const 0)) (then
          (local.set $r (i64.add (local.get $r) (select (i64.sub (i64.const 0) (local.get $d)) (local.get $d) (i64.lt_s (local.get $d) (i64.const 0)))))))
        (local.set $q (i32.and (i32.wrap_i64 (call $u_oc48 (i64.div_s (i64.sub (local.get $n) (local.get $r)) (local.get $d)))) (i32.const 0xffffff)))
        (local.set $a (local.get $r)) (br $end)))
      ;; 71 NP clear add (y) + 1
      (if (i32.eq (local.get $op) (i32.const 0x39)) (then (local.set $a (call $u_add (call $u_sx (local.get $x)) (i64.const 1))) (br $end))))
    (call $zw64 (i32.const 0) (i64.and (local.get $a) (i64.const 0xffffffffffff)))
    (call $zw32 (i32.const 8) (local.get $q))
    (call $zw16 (i32.const 22) (select (i32.rem_u (local.get $y) (i32.const 5)) (local.get $next) (local.get $jump))))
  ;; ========================================================================
  ;; DEC VAX-11/780 (kind 23). 16 little-endian bytes, byte addressed; R0..R14 (R12 AP, R13 FP,
  ;; R14 SP) live in the register file at 64 + 4n, R15 is the PC at 22, the PSL condition codes
  ;; (N8 Z4 V2 C1) at 20. Every operand specifier: short literal, index, register, register
  ;; deferred, autodecrement, autoincrement (immediate), autoincrement deferred (absolute) and the
  ;; byte/word/longword displacement modes, deferred or not, PC relative included.
  (func $v_r (param $n i32) (result i32)
    (if (i32.eq (local.get $n) (i32.const 15)) (then (return (call $zr16 (i32.const 22)))))
    (call $zr32 (i32.add (i32.const 64) (i32.shl (local.get $n) (i32.const 2)))))
  (func $v_rw (param $n i32) (param $v i32)
    (if (i32.eq (local.get $n) (i32.const 15)) (then (call $zw16 (i32.const 22) (i32.and (local.get $v) (i32.const 0xffff))))
    (else (call $zw32 (i32.add (i32.const 64) (i32.shl (local.get $n) (i32.const 2))) (local.get $v)))))
  (func $v_fetch32 (result i32) (local $v i32) (local.set $v (call $fetch16)) (i32.or (local.get $v) (i32.shl (call $fetch16) (i32.const 16))))
  (func $v_mrd (param $a i32) (param $sz i32) (result i32)
    (if (i32.eq (local.get $sz) (i32.const 1)) (then (return (call $mrd (local.get $a)))))
    (if (i32.eq (local.get $sz) (i32.const 2)) (then (return (call $mrd16le (local.get $a)))))
    (call $mrd32 (local.get $a)))
  (func $v_mwr (param $a i32) (param $sz i32) (param $v i32)
    (if (i32.eq (local.get $sz) (i32.const 1)) (then (call $mwr (local.get $a) (local.get $v)) (return)))
    (if (i32.eq (local.get $sz) (i32.const 2)) (then (call $mwr16le (local.get $a) (local.get $v)) (return)))
    (call $mwr32 (local.get $a) (local.get $v)))
  (func $v_mask (param $v i32) (param $sz i32) (result i32)
    (if (i32.eq (local.get $sz) (i32.const 1)) (then (return (i32.and (local.get $v) (i32.const 0xff)))))
    (if (i32.eq (local.get $sz) (i32.const 2)) (then (return (i32.and (local.get $v) (i32.const 0xffff)))))
    (local.get $v))
  (func $v_sx (param $v i32) (param $sz i32) (result i32)
    (if (i32.eq (local.get $sz) (i32.const 1)) (then (return (call $sext8 (local.get $v)))))
    (if (i32.eq (local.get $sz) (i32.const 2)) (then (return (call $sx (local.get $v) (i32.const 16)))))
    (local.get $v))
  (func $v_sign (param $sz i32) (result i32) (i32.shl (i32.const 1) (i32.sub (i32.shl (local.get $sz) (i32.const 3)) (i32.const 1))))
  ;; operand specifier -> tag: 0x30000 + literal, 0x10000 + n for Rn, else a 16-bit address
  (func $v_ea (param $sz i32) (result i32)
    (local $b i32) (local $m i32) (local $n i32) (local $a i32) (local $d i32)
    (local.set $b (call $fetch)) (local.set $m (i32.shr_u (local.get $b) (i32.const 4))) (local.set $n (i32.and (local.get $b) (i32.const 15)))
    (if (i32.lt_u (local.get $m) (i32.const 4)) (then (return (i32.or (i32.const 0x30000) (local.get $b)))))
    (if (i32.eq (local.get $m) (i32.const 4)) (then   ;; indexed: the base specifier follows
      (local.set $a (call $v_ea (local.get $sz)))
      (if (i32.ge_u (local.get $a) (i32.const 0x10000)) (then (local.set $a (i32.const 0))))
      (return (i32.and (i32.add (local.get $a) (i32.mul (call $v_r (local.get $n)) (local.get $sz))) (i32.const 0xffff)))))
    (if (i32.eq (local.get $m) (i32.const 5)) (then (return (i32.or (i32.const 0x10000) (local.get $n)))))
    (if (i32.eq (local.get $m) (i32.const 6)) (then (return (i32.and (call $v_r (local.get $n)) (i32.const 0xffff)))))
    (if (i32.eq (local.get $m) (i32.const 7)) (then
      (call $v_rw (local.get $n) (i32.sub (call $v_r (local.get $n)) (local.get $sz)))
      (return (i32.and (call $v_r (local.get $n)) (i32.const 0xffff)))))
    (if (i32.eq (local.get $m) (i32.const 8)) (then
      (local.set $a (call $v_r (local.get $n)))
      (call $v_rw (local.get $n) (i32.add (local.get $a) (local.get $sz)))
      (return (i32.and (local.get $a) (i32.const 0xffff)))))
    (if (i32.eq (local.get $m) (i32.const 9)) (then
      (local.set $a (call $v_r (local.get $n)))
      (call $v_rw (local.get $n) (i32.add (local.get $a) (i32.const 4)))
      (return (i32.and (call $mrd32 (local.get $a)) (i32.const 0xffff)))))
    (if (i32.lt_u (local.get $m) (i32.const 12)) (then (local.set $d (call $sext8 (call $fetch))))
    (else (if (i32.lt_u (local.get $m) (i32.const 14)) (then (local.set $d (call $sx (call $fetch16) (i32.const 16))))
    (else (local.set $d (call $v_fetch32))))))
    (local.set $a (i32.add (call $v_r (local.get $n)) (local.get $d)))
    (if (i32.and (local.get $m) (i32.const 1)) (then (local.set $a (call $mrd32 (local.get $a)))))
    (i32.and (local.get $a) (i32.const 0xffff)))
  (func $v_ld (param $t i32) (param $sz i32) (result i32)
    (if (i32.ge_u (local.get $t) (i32.const 0x30000)) (then (return (i32.and (local.get $t) (i32.const 63)))))
    (if (i32.ge_u (local.get $t) (i32.const 0x10000)) (then (return (call $v_mask (call $v_r (i32.and (local.get $t) (i32.const 15))) (local.get $sz)))))
    (call $v_mask (call $v_mrd (local.get $t) (local.get $sz)) (local.get $sz)))
  (func $v_st (param $t i32) (param $sz i32) (param $v i32)
    (local $n i32)
    (if (i32.ge_u (local.get $t) (i32.const 0x30000)) (then (return)))
    (if (i32.ge_u (local.get $t) (i32.const 0x10000)) (then
      (local.set $n (i32.and (local.get $t) (i32.const 15)))
      (if (i32.eq (local.get $sz) (i32.const 4)) (then (call $v_rw (local.get $n) (local.get $v)))
      (else (call $v_rw (local.get $n) (i32.or (i32.and (call $v_r (local.get $n)) (i32.xor (call $v_mask (i32.const -1) (local.get $sz)) (i32.const -1)))
                                                (call $v_mask (local.get $v) (local.get $sz))))))
      (return)))
    (call $v_mwr (local.get $t) (local.get $sz) (local.get $v)))
  (func $v_addr (param $t i32) (result i32)   ;; the address a specifier names (a register or literal gives its number)
    (i32.and (local.get $t) (i32.const 0xffff)))
  (func $v_psl (result i32) (call $zr (i32.const 20)))
  ;; N and Z from v (by size), V and C from the low two bits of vc
  (func $v_nz (param $v i32) (param $sz i32) (param $vc i32)
    (local $s i32)
    (local.set $s (call $v_sx (local.get $v) (local.get $sz)))
    (call $zw (i32.const 20) (i32.or (i32.or (select (i32.const 8) (i32.const 0) (i32.lt_s (local.get $s) (i32.const 0)))
                                             (select (i32.const 4) (i32.const 0) (i32.eqz (local.get $s))))
                                     (i32.and (local.get $vc) (i32.const 3)))))
  (func $v_nzk (param $v i32) (param $sz i32) (param $vbit i32)   ;; keeps C
    (call $v_nz (local.get $v) (local.get $sz) (i32.or (i32.and (call $v_psl) (i32.const 1)) (i32.and (local.get $vbit) (i32.const 2)))))
  (func $v_addf (param $a i32) (param $b i32) (param $cin i32) (param $sz i32) (result i32)
    (local $r i32) (local $c i32) (local $full i64)
    (local.set $full (i64.add (i64.add (i64.extend_i32_u (call $v_mask (local.get $a) (local.get $sz))) (i64.extend_i32_u (call $v_mask (local.get $b) (local.get $sz)))) (i64.extend_i32_u (local.get $cin))))
    (local.set $r (call $v_mask (i32.wrap_i64 (local.get $full)) (local.get $sz)))
    (local.set $c (i64.ne (i64.shr_u (local.get $full) (i64.extend_i32_u (i32.shl (local.get $sz) (i32.const 3)))) (i64.const 0)))
    (call $v_nz (local.get $r) (local.get $sz) (i32.or (local.get $c)
      (select (i32.const 2) (i32.const 0) (i32.and (i32.and (i32.xor (local.get $a) (local.get $r)) (i32.xor (local.get $b) (local.get $r))) (call $v_sign (local.get $sz))))))
    (local.get $r))
  (func $v_subf (param $a i32) (param $b i32) (param $bin i32) (param $sz i32) (result i32)   ;; a - b - bin, C = borrow
    (local $r i32) (local $full i64)
    (local.set $full (i64.sub (i64.sub (i64.extend_i32_u (call $v_mask (local.get $a) (local.get $sz))) (i64.extend_i32_u (call $v_mask (local.get $b) (local.get $sz)))) (i64.extend_i32_u (local.get $bin))))
    (local.set $r (call $v_mask (i32.wrap_i64 (local.get $full)) (local.get $sz)))
    (call $v_nz (local.get $r) (local.get $sz) (i32.or (i64.lt_s (local.get $full) (i64.const 0))
      (select (i32.const 2) (i32.const 0) (i32.and (i32.and (i32.xor (local.get $a) (local.get $b)) (i32.xor (local.get $a) (local.get $r))) (call $v_sign (local.get $sz))))))
    (local.get $r))
  (func $v_cmpf (param $a i32) (param $b i32) (param $sz i32)
    (drop (call $v_subf (local.get $a) (local.get $b) (i32.const 0) (local.get $sz)))
    (call $zw (i32.const 20) (i32.and (call $v_psl) (i32.const 13))))
  (func $v_mulf (param $a i32) (param $b i32) (param $sz i32) (result i32)
    (local $p i64) (local $r i32)
    (local.set $p (i64.mul (i64.extend_i32_s (call $v_sx (local.get $a) (local.get $sz))) (i64.extend_i32_s (call $v_sx (local.get $b) (local.get $sz)))))
    (local.set $r (call $v_mask (i32.wrap_i64 (local.get $p)) (local.get $sz)))
    (call $v_nz (local.get $r) (local.get $sz) (select (i32.const 2) (i32.const 0) (i64.ne (local.get $p) (i64.extend_i32_s (call $v_sx (local.get $r) (local.get $sz))))))
    (local.get $r))
  (func $v_divf (param $a i32) (param $b i32) (param $sz i32) (result i32)   ;; a / b; by zero: V set, a returned
    (local $q i64) (local $r i32)
    (local.set $b (call $v_sx (local.get $b) (local.get $sz))) (local.set $a (call $v_sx (local.get $a) (local.get $sz)))
    (if (i32.eqz (local.get $b)) (then (call $v_nz (local.get $a) (local.get $sz) (i32.const 2)) (return (call $v_mask (local.get $a) (local.get $sz)))))
    (local.set $q (i64.div_s (i64.extend_i32_s (local.get $a)) (i64.extend_i32_s (local.get $b))))
    (local.set $r (call $v_mask (i32.wrap_i64 (local.get $q)) (local.get $sz)))
    (call $v_nz (local.get $r) (local.get $sz) (select (i32.const 2) (i32.const 0) (i64.ne (local.get $q) (i64.extend_i32_s (call $v_sx (local.get $r) (local.get $sz))))))
    (local.get $r))
  (func $v_push (param $v i32)
    (call $v_rw (i32.const 14) (i32.sub (call $v_r (i32.const 14)) (i32.const 4)))
    (call $mwr32 (call $v_r (i32.const 14)) (local.get $v)))
  (func $v_pop (result i32)
    (local $v i32)
    (local.set $v (call $mrd32 (call $v_r (i32.const 14))))
    (call $v_rw (i32.const 14) (i32.add (call $v_r (i32.const 14)) (i32.const 4)))
    (local.get $v))
  (func $v_br (param $d i32) (call $zw16 (i32.const 22) (i32.and (i32.add (call $zr16 (i32.const 22)) (local.get $d)) (i32.const 0xffff))))
  (func $v_cond (param $c i32) (result i32)   ;; branch conditions by the low opcode nibble
    (local $p i32) (local $n i32) (local $z i32) (local $v i32) (local $cy i32)
    (local.set $p (call $v_psl))
    (local.set $n (i32.and (i32.shr_u (local.get $p) (i32.const 3)) (i32.const 1))) (local.set $z (i32.and (i32.shr_u (local.get $p) (i32.const 2)) (i32.const 1)))
    (local.set $v (i32.and (i32.shr_u (local.get $p) (i32.const 1)) (i32.const 1))) (local.set $cy (i32.and (local.get $p) (i32.const 1)))
    (if (i32.lt_u (local.get $c) (i32.const 4)) (then (return (i32.eq (local.get $z) (i32.and (local.get $c) (i32.const 1))))))   ;; 2 BNEQ 3 BEQL
    (if (i32.lt_u (local.get $c) (i32.const 6)) (then (return (i32.eq (i32.or (local.get $n) (local.get $z)) (i32.and (local.get $c) (i32.const 1))))))   ;; 4 BGTR 5 BLEQ
    (if (i32.lt_u (local.get $c) (i32.const 10)) (then (return (i32.eq (local.get $n) (i32.and (local.get $c) (i32.const 1))))))   ;; 8 BGEQ 9 BLSS
    (if (i32.lt_u (local.get $c) (i32.const 12)) (then (return (i32.eq (i32.or (local.get $cy) (local.get $z)) (i32.and (local.get $c) (i32.const 1))))))   ;; A BGTRU B BLEQU
    (if (i32.lt_u (local.get $c) (i32.const 14)) (then (return (i32.eq (local.get $v) (i32.and (local.get $c) (i32.const 1))))))   ;; C BVC D BVS
    (i32.eq (local.get $cy) (i32.and (local.get $c) (i32.const 1))))   ;; E BGEQU F BLSSU
  ;; bit fields: base tag t (register or address), bit position pos, size bits -> zero-extended value
  (func $v_fld (param $t i32) (param $pos i32) (param $size i32) (result i32)
    (local $v i64) (local $a i32) (local $i i32)
    (if (i32.eqz (local.get $size)) (then (return (i32.const 0))))
    (if (i32.ge_u (local.get $t) (i32.const 0x10000)) (then
      (return (i32.and (i32.shr_u (call $v_r (i32.and (local.get $t) (i32.const 15))) (i32.and (local.get $pos) (i32.const 31))) (call $v_mask32 (local.get $size))))))
    (local.set $a (i32.add (local.get $t) (i32.shr_s (local.get $pos) (i32.const 3))))
    (block $e (loop $l (br_if $e (i32.ge_u (local.get $i) (i32.const 5)))
      (local.set $v (i64.or (local.get $v) (i64.shl (i64.extend_i32_u (call $mrd (i32.add (local.get $a) (local.get $i)))) (i64.extend_i32_u (i32.shl (local.get $i) (i32.const 3))))))
      (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $l)))
    (i32.and (i32.wrap_i64 (i64.shr_u (local.get $v) (i64.extend_i32_u (i32.and (local.get $pos) (i32.const 7))))) (call $v_mask32 (local.get $size))))
  (func $v_mask32 (param $size i32) (result i32)
    (if (i32.ge_u (local.get $size) (i32.const 32)) (then (return (i32.const -1))))
    (i32.sub (i32.shl (i32.const 1) (local.get $size)) (i32.const 1)))
  (func $v_setbit (param $t i32) (param $pos i32) (param $bit i32)
    (local $a i32) (local $n i32) (local $m i32)
    (if (i32.ge_u (local.get $t) (i32.const 0x10000)) (then
      (local.set $n (i32.and (local.get $t) (i32.const 15))) (local.set $m (i32.shl (i32.const 1) (i32.and (local.get $pos) (i32.const 31))))
      (call $v_rw (local.get $n) (select (i32.or (call $v_r (local.get $n)) (local.get $m)) (i32.and (call $v_r (local.get $n)) (i32.xor (local.get $m) (i32.const -1))) (local.get $bit)))
      (return)))
    (local.set $a (i32.add (local.get $t) (i32.shr_s (local.get $pos) (i32.const 3)))) (local.set $m (i32.shl (i32.const 1) (i32.and (local.get $pos) (i32.const 7))))
    (call $mwr (local.get $a) (select (i32.or (call $mrd (local.get $a)) (local.get $m)) (i32.and (call $mrd (local.get $a)) (i32.xor (local.get $m) (i32.const -1))) (local.get $bit))))
  (func $v_insv (param $t i32) (param $pos i32) (param $size i32) (param $src i32)
    (local $i i32)
    (block $e (loop $l (br_if $e (i32.ge_u (local.get $i) (local.get $size))) (br_if $e (i32.ge_u (local.get $i) (i32.const 32)))
      (call $v_setbit (local.get $t) (i32.add (local.get $pos) (local.get $i)) (i32.and (i32.shr_u (local.get $src) (local.get $i)) (i32.const 1)))
      (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $l))))
  ;; the two-operand / three-operand arithmetic group: lo = low five opcode bits, 0..13
  (func $v_arith (param $lo i32) (param $sz i32)
    (local $s i32) (local $d i32) (local $t i32) (local $kind i32) (local $r i32)
    (local.set $kind (i32.shr_u (local.get $lo) (i32.const 1)))
    (local.set $s (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)))
    (local.set $t (call $v_ea (local.get $sz))) (local.set $d (call $v_ld (local.get $t) (local.get $sz)))
    (if (i32.and (local.get $lo) (i32.const 1)) (then (local.set $t (call $v_ea (local.get $sz)))))
    (if (i32.eqz (local.get $kind)) (then (local.set $r (call $v_addf (local.get $d) (local.get $s) (i32.const 0) (local.get $sz)))) (else
    (if (i32.eq (local.get $kind) (i32.const 1)) (then (local.set $r (call $v_subf (local.get $d) (local.get $s) (i32.const 0) (local.get $sz)))) (else
    (if (i32.eq (local.get $kind) (i32.const 2)) (then (local.set $r (call $v_mulf (local.get $d) (local.get $s) (local.get $sz)))) (else
    (if (i32.eq (local.get $kind) (i32.const 3)) (then (local.set $r (call $v_divf (local.get $d) (local.get $s) (local.get $sz)))) (else
      (local.set $r (call $v_mask (select (i32.or (local.get $d) (local.get $s)) (select (i32.and (local.get $d) (i32.xor (local.get $s) (i32.const -1))) (i32.xor (local.get $d) (local.get $s)) (i32.eq (local.get $kind) (i32.const 5))) (i32.eq (local.get $kind) (i32.const 4))) (local.get $sz)))
      (call $v_nzk (local.get $r) (local.get $sz) (i32.const 0))))))))))
    (call $v_st (local.get $t) (local.get $sz) (local.get $r)))
  (func $v_acb (param $sz i32)   ;; ACBx limit.rx add.rx index.mx displ.bw
    (local $lim i32) (local $add i32) (local $t i32) (local $idx i32) (local $d i32)
    (local.set $lim (call $v_sx (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)) (local.get $sz)))
    (local.set $add (call $v_sx (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)) (local.get $sz)))
    (local.set $t (call $v_ea (local.get $sz)))
    (local.set $idx (call $v_addf (call $v_ld (local.get $t) (local.get $sz)) (local.get $add) (i32.const 0) (local.get $sz)))
    (call $zw (i32.const 20) (i32.and (call $v_psl) (i32.const 14)))
    (call $v_st (local.get $t) (local.get $sz) (local.get $idx))
    (local.set $idx (call $v_sx (local.get $idx) (local.get $sz)))
    (local.set $d (call $sx (call $fetch16) (i32.const 16)))
    (if (select (i32.le_s (local.get $idx) (local.get $lim)) (i32.ge_s (local.get $idx) (local.get $lim)) (i32.ge_s (local.get $add) (i32.const 0))) (then (call $v_br (local.get $d)))))
  (func $v_case (param $sz i32)
    (local $sel i32) (local $base i32) (local $lim i32) (local $tmp i32) (local $tab i32)
    (local.set $sel (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)))
    (local.set $base (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)))
    (local.set $lim (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)))
    (local.set $tmp (call $v_mask (i32.sub (local.get $sel) (local.get $base)) (local.get $sz)))
    (call $v_cmpf (local.get $tmp) (local.get $lim) (local.get $sz))
    (local.set $tab (call $zr16 (i32.const 22)))
    (if (i32.le_u (local.get $tmp) (local.get $lim))
      (then (call $v_br (call $sx (call $mrd16le (i32.add (local.get $tab) (i32.shl (local.get $tmp) (i32.const 1)))) (i32.const 16))))
      (else (call $v_br (i32.shl (i32.add (local.get $lim) (i32.const 1)) (i32.const 1))))))
  (func $v_quad (param $t i32) (param $hi i32) (result i32)   ;; one longword of a quadword operand
    (if (i32.ge_u (local.get $t) (i32.const 0x30000)) (then (return (select (i32.const 0) (i32.and (local.get $t) (i32.const 63)) (local.get $hi)))))
    (if (i32.ge_u (local.get $t) (i32.const 0x10000)) (then (return (call $v_r (i32.and (i32.add (local.get $t) (local.get $hi)) (i32.const 15))))))
    (call $mrd32 (i32.add (local.get $t) (i32.shl (local.get $hi) (i32.const 2)))))
  (func $v_quadw (param $t i32) (param $hi i32) (param $v i32)
    (if (i32.ge_u (local.get $t) (i32.const 0x30000)) (then (return)))
    (if (i32.ge_u (local.get $t) (i32.const 0x10000)) (then (call $v_rw (i32.and (i32.add (local.get $t) (local.get $hi)) (i32.const 15)) (local.get $v)) (return)))
    (call $mwr32 (i32.add (local.get $t) (i32.shl (local.get $hi) (i32.const 2))) (local.get $v)))
  (func $vax_step
    (local $op i32) (local $sz i32) (local $lo i32) (local $s i32) (local $d i32) (local $t i32) (local $r i32) (local $i i32) (local $pos i32) (local $size i32) (local $want i32)
    (local.set $op (call $fetch))
    (block $end
      (if (i32.and (i32.ge_u (local.get $op) (i32.const 0x80)) (i32.le_u (local.get $op) (i32.const 0xdf))) (then
        (local.set $sz (i32.shl (i32.const 1) (i32.sub (i32.shr_u (local.get $op) (i32.const 5)) (i32.const 4))))
        (local.set $lo (i32.and (local.get $op) (i32.const 0x1f)))
        (if (i32.lt_u (local.get $lo) (i32.const 0x0e)) (then (call $v_arith (local.get $lo) (local.get $sz)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x0e)) (then   ;; MNEG
          (local.set $s (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)))
          (call $v_st (call $v_ea (local.get $sz)) (local.get $sz) (call $v_subf (i32.const 0) (local.get $s) (i32.const 0) (local.get $sz))) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x0f)) (then (call $v_case (local.get $sz)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x10)) (then   ;; MOV
          (local.set $s (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)))
          (call $v_st (call $v_ea (local.get $sz)) (local.get $sz) (local.get $s)) (call $v_nzk (local.get $s) (local.get $sz) (i32.const 0)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x11)) (then   ;; CMP
          (local.set $s (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)))
          (call $v_cmpf (local.get $s) (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)) (local.get $sz)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x12)) (then   ;; MCOM
          (local.set $s (call $v_mask (i32.xor (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)) (i32.const -1)) (local.get $sz)))
          (call $v_st (call $v_ea (local.get $sz)) (local.get $sz) (local.get $s)) (call $v_nzk (local.get $s) (local.get $sz) (i32.const 0)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x13)) (then   ;; BIT
          (local.set $s (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)))
          (call $v_nzk (i32.and (local.get $s) (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz))) (local.get $sz) (i32.const 0)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x14)) (then   ;; CLR
          (call $v_st (call $v_ea (local.get $sz)) (local.get $sz) (i32.const 0)) (call $v_nzk (i32.const 0) (local.get $sz) (i32.const 0)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x15)) (then   ;; TST
          (call $v_nz (call $v_ld (call $v_ea (local.get $sz)) (local.get $sz)) (local.get $sz) (i32.const 0)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x16)) (then   ;; INC
          (local.set $t (call $v_ea (local.get $sz)))
          (call $v_st (local.get $t) (local.get $sz) (call $v_addf (call $v_ld (local.get $t) (local.get $sz)) (i32.const 1) (i32.const 0) (local.get $sz))) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x17)) (then   ;; DEC
          (local.set $t (call $v_ea (local.get $sz)))
          (call $v_st (local.get $t) (local.get $sz) (call $v_subf (call $v_ld (local.get $t) (local.get $sz)) (i32.const 1) (i32.const 0) (local.get $sz))) (br $end)))
        (if (i32.eq (local.get $sz) (i32.const 1)) (then   ;; 98 CVTBL 99 CVTBW 9A MOVZBL 9B MOVZBW 9C ROTL 9D ACBB 9E MOVAB 9F PUSHAB
          (if (i32.lt_u (local.get $lo) (i32.const 0x1c)) (then
            (local.set $s (call $v_ld (call $v_ea (i32.const 1)) (i32.const 1)))
            (if (i32.lt_u (local.get $lo) (i32.const 0x1a)) (then (local.set $s (call $sext8 (local.get $s)))))
            (local.set $sz (select (i32.const 4) (i32.const 2) (i32.eqz (i32.and (local.get $lo) (i32.const 1)))))
            (call $v_st (call $v_ea (local.get $sz)) (local.get $sz) (local.get $s))
            (if (i32.lt_u (local.get $lo) (i32.const 0x1a)) (then (call $v_nz (local.get $s) (local.get $sz) (i32.const 0))) (else (call $v_nzk (local.get $s) (local.get $sz) (i32.const 0))))
            (br $end)))
          (if (i32.eq (local.get $lo) (i32.const 0x1c)) (then
            (local.set $s (call $sext8 (call $v_ld (call $v_ea (i32.const 1)) (i32.const 1))))
            (local.set $r (i32.rotl (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4)) (local.get $s)))
            (call $v_st (call $v_ea (i32.const 4)) (i32.const 4) (local.get $r)) (call $v_nzk (local.get $r) (i32.const 4) (i32.const 0)) (br $end)))
          (if (i32.eq (local.get $lo) (i32.const 0x1d)) (then (call $v_acb (i32.const 1)) (br $end)))
          (local.set $sz (i32.const 1))))
        (if (i32.eq (local.get $sz) (i32.const 2)) (then   ;; B8 BISPSW B9 BICPSW BA POPR BB PUSHR BC..BF CHMx
          (if (i32.lt_u (local.get $lo) (i32.const 0x1a)) (then
            (local.set $s (i32.and (call $v_ld (call $v_ea (i32.const 2)) (i32.const 2)) (i32.const 15)))
            (call $zw (i32.const 20) (select (i32.or (call $v_psl) (local.get $s)) (i32.and (call $v_psl) (i32.xor (local.get $s) (i32.const -1))) (i32.eq (local.get $lo) (i32.const 0x18))))
            (br $end)))
          (if (i32.eq (local.get $lo) (i32.const 0x1a)) (then
            (local.set $s (call $v_ld (call $v_ea (i32.const 2)) (i32.const 2)))
            (block $e (loop $l (br_if $e (i32.ge_u (local.get $i) (i32.const 15)))
              (if (i32.and (i32.shr_u (local.get $s) (local.get $i)) (i32.const 1)) (then (call $v_rw (local.get $i) (call $v_pop))))
              (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $l)))
            (br $end)))
          (if (i32.eq (local.get $lo) (i32.const 0x1b)) (then
            (local.set $s (call $v_ld (call $v_ea (i32.const 2)) (i32.const 2))) (local.set $i (i32.const 15))
            (block $e (loop $l (br_if $e (i32.eqz (local.get $i)))
              (local.set $i (i32.sub (local.get $i) (i32.const 1)))
              (if (i32.and (i32.shr_u (local.get $s) (local.get $i)) (i32.const 1)) (then (call $v_push (call $v_r (local.get $i)))))
              (br $l)))
            (br $end)))
          (drop (call $v_ld (call $v_ea (i32.const 2)) (i32.const 2))) (br $end)))
        ;; D8 ADWC D9 SBWC DA MTPR DB MFPR DC MOVPSL DD PUSHL DE MOVAL DF PUSHAL
        (if (i32.lt_u (local.get $lo) (i32.const 0x1a)) (then
          (local.set $s (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4))) (local.set $t (call $v_ea (i32.const 4)))
          (local.set $r (select (call $v_addf (call $v_ld (local.get $t) (i32.const 4)) (local.get $s) (i32.and (call $v_psl) (i32.const 1)) (i32.const 4))
                                (call $v_subf (call $v_ld (local.get $t) (i32.const 4)) (local.get $s) (i32.and (call $v_psl) (i32.const 1)) (i32.const 4))
                                (i32.eq (local.get $lo) (i32.const 0x18))))
          (call $v_st (local.get $t) (i32.const 4) (local.get $r)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x1a)) (then (drop (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4))) (drop (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4))) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x1b)) (then (drop (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4))) (call $v_st (call $v_ea (i32.const 4)) (i32.const 4) (i32.const 0)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x1c)) (then (call $v_st (call $v_ea (i32.const 4)) (i32.const 4) (call $v_psl)) (br $end)))
        (if (i32.eq (local.get $lo) (i32.const 0x1d)) (then
          (local.set $s (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4))) (call $v_push (local.get $s)) (call $v_nzk (local.get $s) (i32.const 4) (i32.const 0)) (br $end)))
        (local.set $sz (i32.const 4))))
      ;; MOVAx / PUSHAx: 9E 9F (byte), 3E 3F (word), DE DF (long), 7E 7F (quad)
      (if (i32.eq (i32.and (local.get $op) (i32.const 0xfe)) (i32.const 0x9e)) (then (local.set $i (i32.const 1))))
      (if (i32.eq (i32.and (local.get $op) (i32.const 0xfe)) (i32.const 0x3e)) (then (local.set $i (i32.const 2))))
      (if (i32.eq (i32.and (local.get $op) (i32.const 0xfe)) (i32.const 0xde)) (then (local.set $i (i32.const 4))))
      (if (i32.eq (i32.and (local.get $op) (i32.const 0xfe)) (i32.const 0x7e)) (then (local.set $i (i32.const 8))))
      (if (local.get $i) (then
        (local.set $s (call $v_addr (call $v_ea (local.get $i))))
        (if (i32.and (local.get $op) (i32.const 1)) (then (call $v_push (local.get $s))) (else (call $v_st (call $v_ea (i32.const 4)) (i32.const 4) (local.get $s))))
        (call $v_nzk (local.get $s) (i32.const 4) (i32.const 0)) (br $end)))
      (if (i32.eq (i32.shr_u (local.get $op) (i32.const 4)) (i32.const 1)) (then   ;; 10 BSBB 11 BRB 12..1F Bcc, 16 JSB, 17 JMP
        (if (i32.eq (local.get $op) (i32.const 0x16)) (then (local.set $s (call $v_addr (call $v_ea (i32.const 1)))) (call $v_push (call $zr16 (i32.const 22))) (call $zw16 (i32.const 22) (local.get $s)) (br $end)))
        (if (i32.eq (local.get $op) (i32.const 0x17)) (then (call $zw16 (i32.const 22) (call $v_addr (call $v_ea (i32.const 1)))) (br $end)))
        (local.set $d (call $sext8 (call $fetch)))
        (if (i32.eq (local.get $op) (i32.const 0x10)) (then (call $v_push (call $zr16 (i32.const 22))) (call $v_br (local.get $d)) (br $end)))
        (if (i32.eq (local.get $op) (i32.const 0x11)) (then (call $v_br (local.get $d)) (br $end)))
        (if (call $v_cond (i32.and (local.get $op) (i32.const 15))) (then (call $v_br (local.get $d))))
        (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x05)) (then (call $zw16 (i32.const 22) (i32.and (call $v_pop) (i32.const 0xffff))) (br $end)))   ;; RSB
      (if (i32.eq (local.get $op) (i32.const 0x04)) (then (call $zw16 (i32.const 22) (i32.and (call $v_pop) (i32.const 0xffff))) (br $end)))   ;; RET (no frame)
      (if (i32.lt_u (local.get $op) (i32.const 0x30)) (then (br $end)))   ;; HALT NOP REI BPT ... INDEX CRC PROBE INSQUE REMQUE, the 2x string group
      (if (i32.eq (local.get $op) (i32.const 0x30)) (then (local.set $d (call $sx (call $fetch16) (i32.const 16))) (call $v_push (call $zr16 (i32.const 22))) (call $v_br (local.get $d)) (br $end)))   ;; BSBW
      (if (i32.eq (local.get $op) (i32.const 0x31)) (then (call $v_br (call $sx (call $fetch16) (i32.const 16))) (br $end)))   ;; BRW
      (if (i32.or (i32.eq (local.get $op) (i32.const 0x32)) (i32.eq (local.get $op) (i32.const 0x33))) (then   ;; CVTWL CVTWB
        (local.set $s (call $sx (call $v_ld (call $v_ea (i32.const 2)) (i32.const 2)) (i32.const 16)))
        (local.set $sz (select (i32.const 4) (i32.const 1) (i32.eq (local.get $op) (i32.const 0x32))))
        (call $v_st (call $v_ea (local.get $sz)) (local.get $sz) (local.get $s))
        (call $v_nz (local.get $s) (local.get $sz) (select (i32.const 2) (i32.const 0) (i32.ne (local.get $s) (call $v_sx (local.get $s) (local.get $sz))))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x3c)) (then   ;; MOVZWL
        (local.set $s (call $v_ld (call $v_ea (i32.const 2)) (i32.const 2))) (call $v_st (call $v_ea (i32.const 4)) (i32.const 4) (local.get $s)) (call $v_nzk (local.get $s) (i32.const 4) (i32.const 0)) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x3d)) (then (call $v_acb (i32.const 2)) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x78)) (then   ;; ASHL cnt.rb src.rl dst.wl
        (local.set $s (call $sext8 (call $v_ld (call $v_ea (i32.const 1)) (i32.const 1))))
        (local.set $d (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4)))
        (if (i32.ge_s (local.get $s) (i32.const 0))
          (then (local.set $r (select (i32.const 0) (i32.shl (local.get $d) (local.get $s)) (i32.gt_u (local.get $s) (i32.const 31))))
                (local.set $i (i32.ne (select (i32.const 0) (i32.shr_s (local.get $r) (local.get $s)) (i32.gt_u (local.get $s) (i32.const 31))) (local.get $d))))
          (else (local.set $r (i32.shr_s (local.get $d) (select (i32.const 31) (i32.sub (i32.const 0) (local.get $s)) (i32.lt_s (local.get $s) (i32.const -31)))))))
        (call $v_st (call $v_ea (i32.const 4)) (i32.const 4) (local.get $r)) (call $v_nz (local.get $r) (i32.const 4) (i32.shl (local.get $i) (i32.const 1))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x7c)) (then   ;; CLRQ
        (local.set $t (call $v_ea (i32.const 8))) (call $v_quadw (local.get $t) (i32.const 0) (i32.const 0)) (call $v_quadw (local.get $t) (i32.const 1) (i32.const 0))
        (call $v_nzk (i32.const 0) (i32.const 4) (i32.const 0)) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0x7d)) (then   ;; MOVQ
        (local.set $t (call $v_ea (i32.const 8))) (local.set $s (call $v_quad (local.get $t) (i32.const 0))) (local.set $d (call $v_quad (local.get $t) (i32.const 1)))
        (local.set $t (call $v_ea (i32.const 8))) (call $v_quadw (local.get $t) (i32.const 0) (local.get $s)) (call $v_quadw (local.get $t) (i32.const 1) (local.get $d))
        (call $v_nzk (i32.or (local.get $d) (i32.ne (local.get $s) (i32.const 0))) (i32.const 4) (i32.const 0)) (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0xe0)) (then (br $end)))   ;; floating point, EMUL/EDIV/ASHQ, packed decimal: NOPs
      (if (i32.lt_u (local.get $op) (i32.const 0xe8)) (then   ;; E0 BBS E1 BBC E2 BBSS E3 BBCS E4 BBSC E5 BBCC E6 BBSSI E7 BBCCI
        (local.set $pos (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4))) (local.set $t (call $v_ea (i32.const 1)))
        (local.set $s (call $v_fld (local.get $t) (local.get $pos) (i32.const 1)))
        (local.set $d (call $sext8 (call $fetch)))
        (if (i32.ge_u (local.get $op) (i32.const 0xe2)) (then
          (call $v_setbit (local.get $t) (local.get $pos) (i32.or (i32.eq (local.get $op) (i32.const 0xe2)) (i32.or (i32.eq (local.get $op) (i32.const 0xe3)) (i32.eq (local.get $op) (i32.const 0xe6)))))))
        (if (i32.eq (local.get $s) (i32.eqz (i32.and (local.get $op) (i32.const 1)))) (then (call $v_br (local.get $d))))
        (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0xea)) (then   ;; E8 BLBS E9 BLBC
        (local.set $s (i32.and (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4)) (i32.const 1))) (local.set $d (call $sext8 (call $fetch)))
        (if (i32.eq (local.get $s) (i32.eqz (i32.and (local.get $op) (i32.const 1)))) (then (call $v_br (local.get $d))))
        (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0xf1)) (then   ;; EA FFS EB FFC EC CMPV ED CMPZV EE EXTV EF EXTZV F0 INSV
        (if (i32.eq (local.get $op) (i32.const 0xf0)) (then (local.set $want (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4)))))
        (local.set $pos (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4))) (local.set $size (i32.and (call $v_ld (call $v_ea (i32.const 1)) (i32.const 1)) (i32.const 63)))
        (local.set $t (call $v_ea (i32.const 1)))
        (if (i32.eq (local.get $op) (i32.const 0xf0)) (then (call $v_insv (local.get $t) (local.get $pos) (local.get $size) (local.get $want)) (br $end)))
        (local.set $s (call $v_fld (local.get $t) (local.get $pos) (local.get $size)))
        (if (i32.and (i32.eqz (i32.and (local.get $op) (i32.const 1))) (i32.ge_u (local.get $op) (i32.const 0xec))) (then   ;; signed field for CMPV / EXTV
          (if (i32.and (local.get $size) (i32.const 31)) (then (if (i32.lt_u (local.get $size) (i32.const 32)) (then (local.set $s (call $sx (local.get $s) (local.get $size)))))))))
        (if (i32.lt_u (local.get $op) (i32.const 0xec)) (then   ;; find first set/clear bit in the field
          (local.set $i (i32.const 0))
          (block $e (loop $l (br_if $e (i32.ge_u (local.get $i) (local.get $size)))
            (br_if $e (i32.eq (i32.and (i32.shr_u (local.get $s) (local.get $i)) (i32.const 1)) (i32.eqz (i32.and (local.get $op) (i32.const 1)))))
            (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $l)))
          (call $v_st (call $v_ea (i32.const 4)) (i32.const 4) (i32.add (local.get $pos) (local.get $i)))
          (call $zw (i32.const 20) (select (i32.const 4) (i32.const 0) (i32.ge_u (local.get $i) (local.get $size)))) (br $end)))
        (if (i32.lt_u (local.get $op) (i32.const 0xee)) (then (call $v_cmpf (local.get $s) (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4)) (i32.const 4)) (br $end)))
        (call $v_st (call $v_ea (i32.const 4)) (i32.const 4) (local.get $s)) (call $v_nzk (local.get $s) (i32.const 4) (i32.const 0)) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0xf1)) (then (call $v_acb (i32.const 4)) (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0xf4)) (then   ;; F2 AOBLSS F3 AOBLEQ limit.rl index.ml displ.bb
        (local.set $s (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4))) (local.set $t (call $v_ea (i32.const 4)))
        (local.set $r (call $v_addf (call $v_ld (local.get $t) (i32.const 4)) (i32.const 1) (i32.const 0) (i32.const 4)))
        (call $v_st (local.get $t) (i32.const 4) (local.get $r)) (local.set $d (call $sext8 (call $fetch)))
        (if (select (i32.le_s (local.get $r) (local.get $s)) (i32.lt_s (local.get $r) (local.get $s)) (i32.and (local.get $op) (i32.const 1))) (then (call $v_br (local.get $d))))
        (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0xf6)) (then   ;; F4 SOBGEQ F5 SOBGTR index.ml displ.bb
        (local.set $t (call $v_ea (i32.const 4)))
        (local.set $r (call $v_subf (call $v_ld (local.get $t) (i32.const 4)) (i32.const 1) (i32.const 0) (i32.const 4)))
        (call $v_st (local.get $t) (i32.const 4) (local.get $r)) (local.set $d (call $sext8 (call $fetch)))
        (if (select (i32.gt_s (local.get $r) (i32.const 0)) (i32.ge_s (local.get $r) (i32.const 0)) (i32.and (local.get $op) (i32.const 1))) (then (call $v_br (local.get $d))))
        (br $end)))
      (if (i32.lt_u (local.get $op) (i32.const 0xf8)) (then   ;; F6 CVTLB F7 CVTLW
        (local.set $s (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4)))
        (local.set $sz (select (i32.const 1) (i32.const 2) (i32.eq (local.get $op) (i32.const 0xf6))))
        (call $v_st (call $v_ea (local.get $sz)) (local.get $sz) (local.get $s))
        (call $v_nz (local.get $s) (local.get $sz) (select (i32.const 2) (i32.const 0) (i32.ne (local.get $s) (call $v_sx (local.get $s) (local.get $sz))))) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0xfa)) (then   ;; CALLG arglist.ab dst.ab: push the list address and the PC, no frame
        (local.set $s (call $v_addr (call $v_ea (i32.const 1)))) (local.set $d (call $v_addr (call $v_ea (i32.const 1))))
        (call $v_push (local.get $s)) (call $v_push (call $zr16 (i32.const 22))) (call $zw16 (i32.const 22) (local.get $d)) (br $end)))
      (if (i32.eq (local.get $op) (i32.const 0xfb)) (then   ;; CALLS numarg.rl dst.ab
        (local.set $s (call $v_ld (call $v_ea (i32.const 4)) (i32.const 4))) (local.set $d (call $v_addr (call $v_ea (i32.const 1))))
        (call $v_push (local.get $s)) (call $v_push (call $zr16 (i32.const 22))) (call $zw16 (i32.const 22) (local.get $d)) (br $end)))))
  ;; ========================================================================
  ;; CDC 6600 central processor (kind 24). The pixel is 2 words of 60 bits (word w = bits
  ;; 60w..60w+59), each holding four 15-bit parcels executed from the high end; P counts parcels
  ;; 0..7 and is kept at 22. Register file: X0..X7 (60 bits) at 64 + 8n, A0..A7 (18 bits) at
  ;; 24 + 4n, B1..B7 (18 bits, three bytes each) at 3(n-1); B0 reads as zero. Ones' complement
  ;; integers, the 6600 floating-point format (11-bit biased exponent, 48-bit coefficient) with
  ;; FX/DX/RX add, subtract, multiply and divide (RX is not rounded), NX/ZX normalize, UX/PX unpack
  ;; and pack; setting A1..A5 loads X from the word, A6/A7 store it. Memory addresses are mod 2.
  (func $c_x (param $n i32) (result i64) (i64.and (call $zr64 (i32.add (i32.const 64) (i32.shl (local.get $n) (i32.const 3)))) (i64.const 0xfffffffffffffff)))
  (func $c_wx (param $n i32) (param $v i64) (call $zw64 (i32.add (i32.const 64) (i32.shl (local.get $n) (i32.const 3))) (i64.and (local.get $v) (i64.const 0xfffffffffffffff))))
  (func $c_a (param $n i32) (result i32) (i32.and (call $zr32 (i32.add (i32.const 24) (i32.shl (local.get $n) (i32.const 2)))) (i32.const 0x3ffff)))
  (func $c_wa (param $n i32) (param $v i32) (call $zw32 (i32.add (i32.const 24) (i32.shl (local.get $n) (i32.const 2))) (i32.and (local.get $v) (i32.const 0x3ffff))))
  (func $c_b (param $n i32) (result i32)
    (local $o i32)
    (if (i32.eqz (local.get $n)) (then (return (i32.const 0))))
    (local.set $o (i32.mul (i32.sub (local.get $n) (i32.const 1)) (i32.const 3)))
    (i32.and (i32.or (i32.or (call $zr (local.get $o)) (i32.shl (call $zr (i32.add (local.get $o) (i32.const 1))) (i32.const 8))) (i32.shl (call $zr (i32.add (local.get $o) (i32.const 2))) (i32.const 16))) (i32.const 0x3ffff)))
  (func $c_wb (param $n i32) (param $v i32)
    (local $o i32)
    (if (i32.eqz (local.get $n)) (then (return)))
    (local.set $o (i32.mul (i32.sub (local.get $n) (i32.const 1)) (i32.const 3)))
    (call $zw (local.get $o) (local.get $v)) (call $zw (i32.add (local.get $o) (i32.const 1)) (i32.shr_u (local.get $v) (i32.const 8))) (call $zw (i32.add (local.get $o) (i32.const 2)) (i32.and (i32.shr_u (local.get $v) (i32.const 16)) (i32.const 3))))
  (func $c_mem (param $a i32) (result i64) (call $fld_rd (i32.mul (i32.and (local.get $a) (i32.const 1)) (i32.const 60)) (i32.const 60)))
  (func $c_set (param $a i32) (param $v i64) (call $fld_wr (i32.mul (i32.and (local.get $a) (i32.const 1)) (i32.const 60)) (i32.const 60) (local.get $v)))
  (func $c_parcel (param $p i32) (result i32)
    (local.set $p (i32.and (local.get $p) (i32.const 7)))
    (i32.wrap_i64 (call $fld_rd (i32.add (i32.mul (i32.shr_u (local.get $p) (i32.const 2)) (i32.const 60)) (i32.sub (i32.const 45) (i32.mul (i32.and (local.get $p) (i32.const 3)) (i32.const 15)))) (i32.const 15))))
  ;; ones' complement helpers: 18-bit and 60-bit add with end-around carry (-0 only from -0 + -0)
  (func $c_add18 (param $a i32) (param $b i32) (result i32)
    (local $s i32)
    (local.set $s (i32.add (i32.and (local.get $a) (i32.const 0x3ffff)) (i32.and (local.get $b) (i32.const 0x3ffff))))
    (local.set $s (i32.add (i32.and (local.get $s) (i32.const 0x3ffff)) (i32.shr_u (local.get $s) (i32.const 18))))
    (if (i32.eq (local.get $s) (i32.const 0x3ffff)) (then
      (if (i32.eqz (i32.and (i32.eq (i32.and (local.get $a) (i32.const 0x3ffff)) (i32.const 0x3ffff)) (i32.eq (i32.and (local.get $b) (i32.const 0x3ffff)) (i32.const 0x3ffff)))) (then (local.set $s (i32.const 0))))))
    (local.get $s))
  (func $c_sub18 (param $a i32) (param $b i32) (result i32) (call $c_add18 (local.get $a) (i32.xor (local.get $b) (i32.const 0x3ffff))))
  (func $c_add60 (param $a i64) (param $b i64) (result i64)
    (local $s i64)
    (local.set $s (i64.add (local.get $a) (local.get $b)))
    (local.set $s (i64.add (i64.and (local.get $s) (i64.const 0xfffffffffffffff)) (i64.shr_u (local.get $s) (i64.const 60))))
    (if (i64.eq (local.get $s) (i64.const 0xfffffffffffffff)) (then
      (if (i32.eqz (i32.and (i64.eq (local.get $a) (i64.const 0xfffffffffffffff)) (i64.eq (local.get $b) (i64.const 0xfffffffffffffff)))) (then (local.set $s (i64.const 0))))))
    (local.get $s))
  (func $c_val18 (param $v i32) (result i32)   ;; 18-bit ones' complement -> signed
    (if (i32.and (local.get $v) (i32.const 0x20000)) (then (return (i32.sub (i32.const 0) (i32.and (i32.xor (local.get $v) (i32.const -1)) (i32.const 0x3ffff))))))
    (i32.and (local.get $v) (i32.const 0x3ffff)))
  (func $c_oc18 (param $v i32) (result i32)   ;; signed -> 18-bit ones' complement
    (if (i32.lt_s (local.get $v) (i32.const 0)) (then (return (i32.and (i32.xor (i32.sub (i32.const 0) (local.get $v)) (i32.const -1)) (i32.const 0x3ffff)))))
    (i32.and (local.get $v) (i32.const 0x3ffff)))
  (func $c_sx18 (param $v i32) (result i64)   ;; 18-bit value sign-extended to 60 bits
    (if (i32.and (local.get $v) (i32.const 0x20000)) (then (return (i64.or (i64.extend_i32_u (i32.and (local.get $v) (i32.const 0x3ffff))) (i64.const 0xffffffffffc0000)))))
    (i64.extend_i32_u (i32.and (local.get $v) (i32.const 0x3ffff))))
  (func $c_rotl60 (param $x i64) (param $n i32) (result i64)
    (local.set $n (i32.rem_u (local.get $n) (i32.const 60)))
    (i64.and (i64.or (i64.shl (local.get $x) (i64.extend_i32_u (local.get $n))) (i64.shr_u (local.get $x) (i64.extend_i32_u (i32.sub (i32.const 60) (local.get $n))))) (i64.const 0xfffffffffffffff)))
  (func $c_sar60 (param $x i64) (param $n i32) (result i64)   ;; arithmetic right shift of a 60-bit value
    (local $s i64)
    (local.set $s (i64.shl (local.get $x) (i64.const 4)))   ;; sign into bit 63
    (if (i32.ge_u (local.get $n) (i32.const 60)) (then (local.set $n (i32.const 63))))
    (i64.and (i64.shr_s (local.get $s) (i64.extend_i32_u (i32.add (local.get $n) (i32.const 4)))) (i64.const 0xfffffffffffffff)))
  ;; floating point: unpack into sign (0/1), unbiased exponent and 48-bit coefficient held in globals
  (global $c_sg (mut i32) (i32.const 0)) (global $c_ex (mut i32) (i32.const 0)) (global $c_co (mut i64) (i64.const 0))
  (func $c_unpack (param $x i64)
    (global.set $c_sg (i64.ne (i64.and (local.get $x) (i64.const 0x800000000000000)) (i64.const 0)))
    (if (global.get $c_sg) (then (local.set $x (i64.and (i64.xor (local.get $x) (i64.const -1)) (i64.const 0xfffffffffffffff)))))
    (global.set $c_ex (i32.sub (i32.and (i32.wrap_i64 (i64.shr_u (local.get $x) (i64.const 48))) (i32.const 0x7ff)) (i32.const 1024)))
    (global.set $c_co (i64.and (local.get $x) (i64.const 0xffffffffffff))))
  (func $c_pack (param $sg i32) (param $ex i32) (param $co i64) (result i64)
    (local $x i64)
    (if (i64.eqz (local.get $co)) (then (return (i64.const 0))))
    (local.set $ex (i32.add (local.get $ex) (i32.const 1024)))
    (if (i32.gt_s (local.get $ex) (i32.const 0x7ff)) (then (local.set $ex (i32.const 0x7ff)) (local.set $co (i64.const 0))))   ;; overflow: infinite
    (if (i32.lt_s (local.get $ex) (i32.const 0)) (then (return (i64.const 0))))   ;; underflow: zero
    (local.set $x (i64.or (i64.shl (i64.extend_i32_u (local.get $ex)) (i64.const 48)) (i64.and (local.get $co) (i64.const 0xffffffffffff))))
    (if (local.get $sg) (then (local.set $x (i64.and (i64.xor (local.get $x) (i64.const -1)) (i64.const 0xfffffffffffffff)))))
    (local.get $x))
  (func $c_fadd (param $a i64) (param $b i64) (param $sub i32) (result i64)
    (local $sa i32) (local $ea i32) (local $ca i64) (local $sb i32) (local $eb i32) (local $cb i64) (local $e i32) (local $sum i64)
    (call $c_unpack (local.get $a)) (local.set $sa (global.get $c_sg)) (local.set $ea (global.get $c_ex)) (local.set $ca (global.get $c_co))
    (call $c_unpack (local.get $b)) (local.set $sb (i32.xor (global.get $c_sg) (local.get $sub))) (local.set $eb (global.get $c_ex)) (local.set $cb (global.get $c_co))
    (if (i32.ge_s (local.get $ea) (local.get $eb))
      (then (local.set $e (local.get $ea))
            (local.set $cb (select (i64.const 0) (i64.shr_u (local.get $cb) (i64.extend_i32_u (i32.sub (local.get $ea) (local.get $eb)))) (i32.gt_u (i32.sub (local.get $ea) (local.get $eb)) (i32.const 63)))))
      (else (local.set $e (local.get $eb))
            (local.set $ca (select (i64.const 0) (i64.shr_u (local.get $ca) (i64.extend_i32_u (i32.sub (local.get $eb) (local.get $ea)))) (i32.gt_u (i32.sub (local.get $eb) (local.get $ea)) (i32.const 63))))))
    (local.set $sum (i64.add (select (i64.sub (i64.const 0) (local.get $ca)) (local.get $ca) (local.get $sa)) (select (i64.sub (i64.const 0) (local.get $cb)) (local.get $cb) (local.get $sb))))
    (local.set $sa (i64.lt_s (local.get $sum) (i64.const 0)))
    (if (local.get $sa) (then (local.set $sum (i64.sub (i64.const 0) (local.get $sum)))))
    (if (i64.ge_u (local.get $sum) (i64.const 0x1000000000000)) (then (local.set $sum (i64.shr_u (local.get $sum) (i64.const 1))) (local.set $e (i32.add (local.get $e) (i32.const 1)))))
    (call $c_pack (local.get $sa) (local.get $e) (local.get $sum)))
  (func $c_fmul (param $a i64) (param $b i64) (param $low i32) (result i64)
    (local $sa i32) (local $ea i32) (local $ca i64) (local $eb i32) (local $cb i64) (local $ah i64) (local $al i64) (local $bh i64) (local $bl i64)
    (local $mid i64) (local $t i64) (local $lo i64) (local $hi i64)
    (call $c_unpack (local.get $a)) (local.set $sa (global.get $c_sg)) (local.set $ea (global.get $c_ex)) (local.set $ca (global.get $c_co))
    (call $c_unpack (local.get $b)) (local.set $sa (i32.xor (local.get $sa) (global.get $c_sg))) (local.set $eb (global.get $c_ex)) (local.set $cb (global.get $c_co))
    (local.set $ah (i64.shr_u (local.get $ca) (i64.const 24))) (local.set $al (i64.and (local.get $ca) (i64.const 0xffffff)))
    (local.set $bh (i64.shr_u (local.get $cb) (i64.const 24))) (local.set $bl (i64.and (local.get $cb) (i64.const 0xffffff)))
    (local.set $mid (i64.add (i64.mul (local.get $ah) (local.get $bl)) (i64.mul (local.get $al) (local.get $bh))))
    (local.set $t (i64.add (i64.mul (local.get $al) (local.get $bl)) (i64.shl (i64.and (local.get $mid) (i64.const 0xffffff)) (i64.const 24))))
    (local.set $lo (i64.and (local.get $t) (i64.const 0xffffffffffff)))
    (local.set $hi (i64.add (i64.add (i64.mul (local.get $ah) (local.get $bh)) (i64.shr_u (local.get $mid) (i64.const 24))) (i64.shr_u (local.get $t) (i64.const 48))))
    (if (local.get $low) (then (return (call $c_pack (local.get $sa) (i32.add (local.get $ea) (local.get $eb)) (local.get $lo)))))
    (if (i32.and (i32.and (i64.ne (i64.and (local.get $ca) (i64.const 0x800000000000)) (i64.const 0)) (i64.ne (i64.and (local.get $cb) (i64.const 0x800000000000)) (i64.const 0)))
                 (i64.eqz (i64.and (local.get $hi) (i64.const 0x800000000000)))) (then   ;; normalized operands give a normalized product
      (local.set $hi (i64.or (i64.shl (local.get $hi) (i64.const 1)) (i64.shr_u (local.get $lo) (i64.const 47))))
      (local.set $ea (i32.sub (local.get $ea) (i32.const 1)))))
    (call $c_pack (local.get $sa) (i32.add (i32.add (local.get $ea) (local.get $eb)) (i32.const 48)) (local.get $hi)))
  (func $c_fdiv (param $a i64) (param $b i64) (result i64)
    (local $sa i32) (local $ea i32) (local $ca i64) (local $eb i32) (local $cb i64) (local $q i64) (local $e i32)
    (call $c_unpack (local.get $a)) (local.set $sa (global.get $c_sg)) (local.set $ea (global.get $c_ex)) (local.set $ca (global.get $c_co))
    (call $c_unpack (local.get $b)) (local.set $sa (i32.xor (local.get $sa) (global.get $c_sg))) (local.set $eb (global.get $c_ex)) (local.set $cb (global.get $c_co))
    (if (i64.eqz (local.get $cb)) (then (return (i64.const 0x1ff7000000000000))))   ;; 1777 exponent: indefinite
    (local.set $e (i32.sub (i32.wrap_i64 (i64.clz (local.get $cb))) (i32.const 16)))   ;; normalize the divisor so the quotient fits 48 bits
    (local.set $cb (i64.shl (local.get $cb) (i64.extend_i32_u (local.get $e)))) (local.set $eb (i32.sub (local.get $eb) (local.get $e)))
    (local.set $q (i64.trunc_sat_f64_u (f64.mul (f64.div (f64.convert_i64_u (local.get $ca)) (f64.convert_i64_u (local.get $cb))) (f64.const 140737488355328.0))))
    (local.set $e (i32.sub (i32.sub (local.get $ea) (local.get $eb)) (i32.const 47)))
    (block $e (loop $l (br_if $e (i64.lt_u (local.get $q) (i64.const 0x1000000000000)))
      (local.set $q (i64.shr_u (local.get $q) (i64.const 1))) (local.set $e (i32.add (local.get $e) (i32.const 1))) (br $l)))
    (call $c_pack (local.get $sa) (local.get $e) (local.get $q)))
  (func $c_xrange (param $x i64) (result i32)   ;; 1 infinite, 2 indefinite, 0 otherwise, by the top 12 bits
    (local $t i32)
    (local.set $t (i32.wrap_i64 (i64.shr_u (local.get $x) (i64.const 48))))
    (if (i32.or (i32.eq (local.get $t) (i32.const 0x7ff)) (i32.eq (local.get $t) (i32.const 0x800))) (then (return (i32.const 1))))
    (if (i32.or (i32.eq (local.get $t) (i32.const 0x3ff)) (i32.eq (local.get $t) (i32.const 0xc00))) (then (return (i32.const 2))))
    (i32.const 0))
  (func $cdc6600_step
    (local $p i32) (local $ins i32) (local $fm i32) (local $i i32) (local $j i32) (local $k i32) (local $K i32) (local $next i32) (local $long i32)
    (local $xj i64) (local $xk i64) (local $r i64) (local $n i32) (local $v i32) (local $g i32) (local $t i64)
    (local.set $p (i32.and (call $zr16 (i32.const 22)) (i32.const 7)))
    (local.set $ins (call $c_parcel (local.get $p)))
    (local.set $fm (i32.shr_u (local.get $ins) (i32.const 9))) (local.set $i (i32.and (i32.shr_u (local.get $ins) (i32.const 6)) (i32.const 7)))
    (local.set $j (i32.and (i32.shr_u (local.get $ins) (i32.const 3)) (i32.const 7))) (local.set $k (i32.and (local.get $ins) (i32.const 7)))
    (local.set $g (i32.shr_u (local.get $fm) (i32.const 3)))   ;; octal first digit
    (local.set $long (i32.or (i32.and (i32.ge_u (local.get $fm) (i32.const 1)) (i32.le_u (local.get $fm) (i32.const 7)))
                             (i32.and (i32.ge_u (local.get $fm) (i32.const 0x28)) (i32.lt_u (i32.and (local.get $fm) (i32.const 7)) (i32.const 2)))))
    (local.set $next (i32.and (i32.add (local.get $p) (i32.const 1)) (i32.const 7)))
    (if (local.get $long) (then
      (local.set $K (i32.or (i32.shl (local.get $k) (i32.const 15)) (call $c_parcel (local.get $next))))
      (local.set $next (i32.and (i32.add (local.get $p) (i32.const 2)) (i32.const 7)))))
    (call $zw16 (i32.const 22) (local.get $next))
    (local.set $xj (call $c_x (local.get $j))) (local.set $xk (call $c_x (local.get $k)))
    (block $end
      (if (i32.eqz (local.get $fm)) (then (br $end)))   ;; 00 PS program stop: pass
      (if (i32.eq (local.get $fm) (i32.const 1)) (then   ;; 01 RJ K: plant a jump to the next word at K, go to K + 1
        (call $c_set (local.get $K) (i64.shl (i64.extend_i32_u (i32.or (i32.const 0x2000000) (i32.and (i32.shr_u (i32.add (local.get $next) (i32.const 3)) (i32.const 2)) (i32.const 1)))) (i64.const 30)))
        (call $zw16 (i32.const 22) (i32.shl (i32.and (i32.add (local.get $K) (i32.const 1)) (i32.const 1)) (i32.const 2))) (br $end)))
      (if (i32.eq (local.get $fm) (i32.const 2)) (then   ;; 02 JP Bi + K
        (call $zw16 (i32.const 22) (i32.shl (i32.and (call $c_add18 (call $c_b (local.get $i)) (local.get $K)) (i32.const 1)) (i32.const 2))) (br $end)))
      (if (i32.eq (local.get $fm) (i32.const 3)) (then   ;; 03 ZR NZ PL NG IR OR DF ID Xj K
        (local.set $v (i32.const 0))
        (if (i32.lt_u (local.get $i) (i32.const 2)) (then (local.set $v (i32.or (i64.eqz (local.get $xj)) (i64.eq (local.get $xj) (i64.const 0xfffffffffffffff))))))
        (if (i32.and (i32.ge_u (local.get $i) (i32.const 2)) (i32.lt_u (local.get $i) (i32.const 4))) (then (local.set $v (i64.eqz (i64.and (local.get $xj) (i64.const 0x800000000000000))))))
        (if (i32.and (i32.ge_u (local.get $i) (i32.const 4)) (i32.lt_u (local.get $i) (i32.const 6))) (then (local.set $v (i32.ne (call $c_xrange (local.get $xj)) (i32.const 1)))))
        (if (i32.ge_u (local.get $i) (i32.const 6)) (then (local.set $v (i32.ne (call $c_xrange (local.get $xj)) (i32.const 2)))))
        (if (i32.ne (local.get $v) (i32.and (local.get $i) (i32.const 1))) (then (call $zw16 (i32.const 22) (i32.shl (i32.and (local.get $K) (i32.const 1)) (i32.const 2)))))
        (br $end)))
      (if (i32.lt_u (local.get $fm) (i32.const 8)) (then   ;; 04 EQ 05 NE 06 GE 07 LT Bi Bj K
        (local.set $n (call $c_val18 (call $c_b (local.get $i)))) (local.set $v (call $c_val18 (call $c_b (local.get $j))))
        (if (i32.eq (local.get $fm) (i32.const 4)) (then (local.set $v (i32.eq (local.get $n) (local.get $v)))) (else
        (if (i32.eq (local.get $fm) (i32.const 5)) (then (local.set $v (i32.ne (local.get $n) (local.get $v)))) (else
        (if (i32.eq (local.get $fm) (i32.const 6)) (then (local.set $v (i32.ge_s (local.get $n) (local.get $v)))) (else
          (local.set $v (i32.lt_s (local.get $n) (local.get $v)))))))))
        (if (local.get $v) (then (call $zw16 (i32.const 22) (i32.shl (i32.and (local.get $K) (i32.const 1)) (i32.const 2)))))
        (br $end)))
      (if (i32.eq (local.get $g) (i32.const 1)) (then   ;; 10..17 BXi boolean
        (local.set $k (i32.and (local.get $fm) (i32.const 7)))
        (if (i32.ge_u (local.get $k) (i32.const 4)) (then (local.set $xk (i64.and (i64.xor (local.get $xk) (i64.const -1)) (i64.const 0xfffffffffffffff)))))
        (local.set $k (i32.and (local.get $k) (i32.const 3)))
        (if (i32.eqz (local.get $k)) (then (local.set $r (select (local.get $xj) (local.get $xk) (i32.lt_u (local.get $fm) (i32.const 0xc))))) (else
        (if (i32.eq (local.get $k) (i32.const 1)) (then (local.set $r (i64.and (local.get $xj) (local.get $xk)))) (else
        (if (i32.eq (local.get $k) (i32.const 2)) (then (local.set $r (i64.or (local.get $xj) (local.get $xk)))) (else
          (local.set $r (i64.xor (local.get $xj) (local.get $xk)))))))))
        (call $c_wx (local.get $i) (local.get $r)) (br $end)))
      (if (i32.eq (local.get $g) (i32.const 2)) (then   ;; 20 LX 21 AX jk, 22 LX 23 AX Bj Xk, 24 NX 25 ZX 26 UX 27 PX Bj Xk
        (local.set $k (i32.and (local.get $fm) (i32.const 7)))
        (if (i32.eq (local.get $k) (i32.const 0)) (then (call $c_wx (local.get $i) (call $c_rotl60 (call $c_x (local.get $i)) (i32.and (local.get $ins) (i32.const 63)))) (br $end)))
        (if (i32.eq (local.get $k) (i32.const 1)) (then (call $c_wx (local.get $i) (call $c_sar60 (call $c_x (local.get $i)) (i32.and (local.get $ins) (i32.const 63)))) (br $end)))
        (if (i32.lt_u (local.get $k) (i32.const 4)) (then
          (local.set $n (call $c_val18 (call $c_b (local.get $j))))
          (if (i32.eq (local.get $k) (i32.const 3)) (then (local.set $n (i32.sub (i32.const 0) (local.get $n)))))   ;; AX: nominal right
          (if (i32.ge_s (local.get $n) (i32.const 0))
            (then (local.set $r (call $c_rotl60 (local.get $xk) (i32.and (local.get $n) (i32.const 63)))))
            (else (local.set $r (call $c_sar60 (local.get $xk) (i32.sub (i32.const 0) (local.get $n))))))
          (call $c_wx (local.get $i) (local.get $r)) (br $end)))
        (call $c_unpack (local.get $xk))
        (if (i32.lt_u (local.get $k) (i32.const 6)) (then   ;; NX / ZX normalize
          (if (i64.eqz (global.get $c_co)) (then (call $c_wx (local.get $i) (i64.const 0)) (call $c_wb (local.get $j) (i32.const 48)) (br $end)))
          (local.set $n (i32.sub (i32.wrap_i64 (i64.clz (global.get $c_co))) (i32.const 16)))
          (call $c_wx (local.get $i) (call $c_pack (global.get $c_sg) (i32.sub (global.get $c_ex) (local.get $n)) (i64.shl (global.get $c_co) (i64.extend_i32_u (local.get $n)))))
          (call $c_wb (local.get $j) (local.get $n)) (br $end)))
        (if (i32.eq (local.get $k) (i32.const 6)) (then   ;; UX: coefficient to Xi, exponent to Bj
          (call $c_wx (local.get $i) (select (i64.and (i64.xor (global.get $c_co) (i64.const -1)) (i64.const 0xfffffffffffffff)) (global.get $c_co) (global.get $c_sg)))
          (call $c_wb (local.get $j) (call $c_oc18 (global.get $c_ex))) (br $end)))
        ;; PX: Xk holds the coefficient as an integer, Bj the exponent
        (local.set $v (i64.ne (i64.and (local.get $xk) (i64.const 0x800000000000000)) (i64.const 0)))
        (local.set $t (select (i64.and (i64.xor (local.get $xk) (i64.const -1)) (i64.const 0xffffffffffff)) (i64.and (local.get $xk) (i64.const 0xffffffffffff)) (local.get $v)))
        (call $c_wx (local.get $i) (call $c_pack (local.get $v) (call $c_val18 (call $c_b (local.get $j))) (local.get $t))) (br $end)))
      (if (i32.eq (local.get $g) (i32.const 3)) (then   ;; 30-35 floating add/subtract, 36 IX add, 37 IX subtract
        (local.set $k (i32.and (local.get $fm) (i32.const 7)))
        (if (i32.lt_u (local.get $k) (i32.const 6)) (then (call $c_wx (local.get $i) (call $c_fadd (local.get $xj) (local.get $xk) (i32.and (local.get $k) (i32.const 1)))) (br $end)))
        (if (i32.eq (local.get $k) (i32.const 7)) (then (local.set $xk (i64.and (i64.xor (local.get $xk) (i64.const -1)) (i64.const 0xfffffffffffffff)))))
        (call $c_wx (local.get $i) (call $c_add60 (local.get $xj) (local.get $xk))) (br $end)))
      (if (i32.eq (local.get $g) (i32.const 4)) (then   ;; 40 FX 41 RX 42 DX multiply, 43 MX jk, 44 FX 45 RX divide, 46 NO, 47 CX
        (local.set $k (i32.and (local.get $fm) (i32.const 7)))
        (if (i32.lt_u (local.get $k) (i32.const 3)) (then (call $c_wx (local.get $i) (call $c_fmul (local.get $xj) (local.get $xk) (i32.eq (local.get $k) (i32.const 2)))) (br $end)))
        (if (i32.eq (local.get $k) (i32.const 3)) (then
          (local.set $n (i32.and (local.get $ins) (i32.const 63)))
          (call $c_wx (local.get $i) (select (i64.and (i64.shl (i64.const -1) (i64.extend_i32_u (i32.sub (i32.const 60) (local.get $n)))) (i64.const 0xfffffffffffffff)) (i64.const 0) (i32.and (i32.ne (local.get $n) (i32.const 0)) (i32.lt_u (local.get $n) (i32.const 60)))))
          (if (i32.ge_u (local.get $n) (i32.const 60)) (then (call $c_wx (local.get $i) (i64.const 0xfffffffffffffff))))
          (br $end)))
        (if (i32.lt_u (local.get $k) (i32.const 6)) (then (call $c_wx (local.get $i) (call $c_fdiv (local.get $xj) (local.get $xk))) (br $end)))
        (if (i32.eq (local.get $k) (i32.const 7)) (then (call $c_wx (local.get $i) (i64.popcnt (local.get $xk)))))
        (br $end)))
      ;; 50-57 SAi, 60-67 SBi, 70-77 SXi: Aj+K Bj+K Xj+K Xj+Bk Aj+Bk Aj-Bk Bj+Bk Bj-Bk
      (local.set $k (i32.and (local.get $fm) (i32.const 7)))
      (if (i32.eq (local.get $k) (i32.const 0)) (then (local.set $v (call $c_add18 (call $c_a (local.get $j)) (local.get $K)))) (else
      (if (i32.eq (local.get $k) (i32.const 1)) (then (local.set $v (call $c_add18 (call $c_b (local.get $j)) (local.get $K)))) (else
      (if (i32.eq (local.get $k) (i32.const 2)) (then (local.set $v (call $c_add18 (i32.wrap_i64 (local.get $xj)) (local.get $K)))) (else
      (if (i32.eq (local.get $k) (i32.const 3)) (then (local.set $v (call $c_add18 (i32.wrap_i64 (local.get $xj)) (call $c_b (i32.and (local.get $ins) (i32.const 7)))))) (else
      (if (i32.eq (local.get $k) (i32.const 4)) (then (local.set $v (call $c_add18 (call $c_a (local.get $j)) (call $c_b (i32.and (local.get $ins) (i32.const 7)))))) (else
      (if (i32.eq (local.get $k) (i32.const 5)) (then (local.set $v (call $c_sub18 (call $c_a (local.get $j)) (call $c_b (i32.and (local.get $ins) (i32.const 7)))))) (else
      (if (i32.eq (local.get $k) (i32.const 6)) (then (local.set $v (call $c_add18 (call $c_b (local.get $j)) (call $c_b (i32.and (local.get $ins) (i32.const 7)))))) (else
        (local.set $v (call $c_sub18 (call $c_b (local.get $j)) (call $c_b (i32.and (local.get $ins) (i32.const 7)))))))))))))))))))
      (if (i32.eq (local.get $g) (i32.const 5)) (then
        (call $c_wa (local.get $i) (local.get $v))
        (if (i32.and (i32.ge_u (local.get $i) (i32.const 1)) (i32.le_u (local.get $i) (i32.const 5))) (then (call $c_wx (local.get $i) (call $c_mem (local.get $v)))))
        (if (i32.ge_u (local.get $i) (i32.const 6)) (then (call $c_set (local.get $v) (call $c_x (local.get $i)))))
        (br $end)))
      (if (i32.eq (local.get $g) (i32.const 6)) (then (call $c_wb (local.get $i) (local.get $v)) (br $end)))
      (call $c_wx (local.get $i) (call $c_sx18 (local.get $v)))))
)
