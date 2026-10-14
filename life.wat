;; Conway's Game of Life in hand-written WebAssembly.
;;
;; Memory layout is decided by the host (JavaScript). Cells are one byte each:
;; 0 = dead, 1..255 = alive, value is the cell's age in generations (saturating).
;; The grid wraps around at the edges (torus).

(module
  (memory (export "memory") 64)   ;; 64 pages = 4 MiB, host may grow it

  ;; step(w, h, src, dst): compute the next generation of the src grid into dst.
  (func (export "step") (param $w i32) (param $h i32) (param $src i32) (param $dst i32)
    (local $x i32) (local $y i32)
    (local $row i32) (local $up i32) (local $down i32)
    (local $xl i32) (local $xr i32)
    (local $n i32) (local $age i32) (local $out i32)

    (local.set $out (local.get $dst))
    (local.set $y (i32.const 0))
    (block $yexit
      (loop $yloop
        (br_if $yexit (i32.ge_u (local.get $y) (local.get $h)))

        (local.set $row (i32.add (local.get $src) (i32.mul (local.get $y) (local.get $w))))
        ;; row above, wrapping to the last row when y == 0
        (local.set $up
          (select
            (i32.add (local.get $src)
                     (i32.mul (i32.sub (local.get $h) (i32.const 1)) (local.get $w)))
            (i32.sub (local.get $row) (local.get $w))
            (i32.eqz (local.get $y))))
        ;; row below, wrapping to the first row when y == h-1
        (local.set $down
          (select
            (local.get $src)
            (i32.add (local.get $row) (local.get $w))
            (i32.eq (local.get $y) (i32.sub (local.get $h) (i32.const 1)))))

        (local.set $x (i32.const 0))
        (block $xexit
          (loop $xloop
            (br_if $xexit (i32.ge_u (local.get $x) (local.get $w)))

            (local.set $xl
              (select (i32.sub (local.get $w) (i32.const 1))
                      (i32.sub (local.get $x) (i32.const 1))
                      (i32.eqz (local.get $x))))
            (local.set $xr
              (select (i32.const 0)
                      (i32.add (local.get $x) (i32.const 1))
                      (i32.eq (local.get $x) (i32.sub (local.get $w) (i32.const 1)))))

            ;; count live neighbours (a cell is alive when its byte is non-zero)
            (local.set $n
              (i32.add
                (i32.add
                  (i32.add
                    (i32.ne (i32.load8_u (i32.add (local.get $up) (local.get $xl))) (i32.const 0))
                    (i32.ne (i32.load8_u (i32.add (local.get $up) (local.get $x))) (i32.const 0)))
                  (i32.add
                    (i32.ne (i32.load8_u (i32.add (local.get $up) (local.get $xr))) (i32.const 0))
                    (i32.ne (i32.load8_u (i32.add (local.get $row) (local.get $xl))) (i32.const 0))))
                (i32.add
                  (i32.add
                    (i32.ne (i32.load8_u (i32.add (local.get $row) (local.get $xr))) (i32.const 0))
                    (i32.ne (i32.load8_u (i32.add (local.get $down) (local.get $xl))) (i32.const 0)))
                  (i32.add
                    (i32.ne (i32.load8_u (i32.add (local.get $down) (local.get $x))) (i32.const 0))
                    (i32.ne (i32.load8_u (i32.add (local.get $down) (local.get $xr))) (i32.const 0))))))

            (local.set $age (i32.load8_u (i32.add (local.get $row) (local.get $x))))

            ;; B3/S23: lives if n == 3, or if already alive and n == 2.
            ;; Survivors age by one (saturating at 255), newborns start at 1.
            (i32.store8 (local.get $out)
              (select
                (select
                  (select (i32.const 255)
                          (i32.add (local.get $age) (i32.const 1))
                          (i32.eq (local.get $age) (i32.const 255)))
                  (i32.const 1)
                  (local.get $age))
                (i32.const 0)
                (i32.or (i32.eq (local.get $n) (i32.const 3))
                        (i32.and (i32.ne (local.get $age) (i32.const 0))
                                 (i32.eq (local.get $n) (i32.const 2))))))

            (local.set $out (i32.add (local.get $out) (i32.const 1)))
            (local.set $x (i32.add (local.get $x) (i32.const 1)))
            (br $xloop)))

        (local.set $y (i32.add (local.get $y) (i32.const 1)))
        (br $yloop))))

  ;; render(n, src, pix, pal): paint n cells as RGBA pixels.
  ;; pal points at 256 little-endian RGBA colours indexed by cell age.
  (func (export "render") (param $n i32) (param $src i32) (param $pix i32) (param $pal i32)
    (local $i i32)
    (local.set $i (i32.const 0))
    (block $exit
      (loop $loop
        (br_if $exit (i32.ge_u (local.get $i) (local.get $n)))
        (i32.store
          (i32.add (local.get $pix) (i32.shl (local.get $i) (i32.const 2)))
          (i32.load
            (i32.add (local.get $pal)
                     (i32.shl (i32.load8_u (i32.add (local.get $src) (local.get $i)))
                              (i32.const 2)))))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $loop))))

  ;; population(n, src): number of live cells.
  (func (export "population") (param $n i32) (param $src i32) (result i32)
    (local $i i32) (local $count i32)
    (local.set $i (i32.const 0))
    (block $exit
      (loop $loop
        (br_if $exit (i32.ge_u (local.get $i) (local.get $n)))
        (local.set $count
          (i32.add (local.get $count)
                   (i32.ne (i32.load8_u (i32.add (local.get $src) (local.get $i))) (i32.const 0))))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $loop)))
    (local.get $count))

  ;; randomize(n, dst, seed, threshold): fill n cells at random using xorshift32.
  ;; A cell becomes alive when (rand & 0xffff) < threshold. Returns the new seed.
  (func (export "randomize") (param $n i32) (param $dst i32) (param $seed i32) (param $threshold i32) (result i32)
    (local $i i32)
    (if (i32.eqz (local.get $seed)) (then (local.set $seed (i32.const 0x9e3779b9))))
    (local.set $i (i32.const 0))
    (block $exit
      (loop $loop
        (br_if $exit (i32.ge_u (local.get $i) (local.get $n)))
        (local.set $seed (i32.xor (local.get $seed) (i32.shl (local.get $seed) (i32.const 13))))
        (local.set $seed (i32.xor (local.get $seed) (i32.shr_u (local.get $seed) (i32.const 17))))
        (local.set $seed (i32.xor (local.get $seed) (i32.shl (local.get $seed) (i32.const 5))))
        (i32.store8
          (i32.add (local.get $dst) (local.get $i))
          (i32.lt_u (i32.and (local.get $seed) (i32.const 0xffff)) (local.get $threshold)))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $loop)))
    (local.get $seed))
)
