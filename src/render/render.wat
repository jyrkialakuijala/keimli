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
