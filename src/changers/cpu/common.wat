  ;; Shared by every CPU core: the register file and the pixel memory.
  ;; The register file lives at byte 256 of linear memory, 128 bytes, zeroed (or loaded by the driver)
  ;; before a run: $zr/$zw and the 16-, 32- and 64-bit forms read and write it at an offset. $zp is the
  ;; address of the pixel being run; $mrd/$mwr read and write its 16 bytes with the address taken mod 16,
  ;; and the 16-bit little-endian ($mrd16, $mrd16le), big-endian ($mrd16be) and 32-bit forms build on
  ;; them byte by byte, so every access wraps. $fetch reads the byte at PC (register-file offset 22) and
  ;; advances it; $push/$pop use SP at offset 20. $fld_rd/$fld_wr access an n-bit field (n <= 64) at any
  ;; bit offset of the pixel for the wide-word machines.
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
  (func $fetch16be (result i32) (local $hi i32) (local.set $hi (call $fetch)) (i32.or (i32.shl (local.get $hi) (i32.const 8)) (call $fetch)))
  (func $mrd16be (param $a i32) (result i32) (i32.or (i32.shl (call $mrd (local.get $a)) (i32.const 8)) (call $mrd (i32.add (local.get $a) (i32.const 1)))))
  (func $mwr16be (param $a i32) (param $v i32) (call $mwr (local.get $a) (i32.shr_u (local.get $v) (i32.const 8))) (call $mwr (i32.add (local.get $a) (i32.const 1)) (i32.and (local.get $v) (i32.const 255))))
  (func $mrd16le (param $a i32) (result i32) (i32.or (call $mrd (local.get $a)) (i32.shl (call $mrd (i32.add (local.get $a) (i32.const 1))) (i32.const 8))))
  (func $mrd32 (param $a i32) (result i32) (i32.or (call $mrd16le (local.get $a)) (i32.shl (call $mrd16le (i32.add (local.get $a) (i32.const 2))) (i32.const 16))))
  (func $mwr16le (param $a i32) (param $v i32) (call $mwr (local.get $a) (i32.and (local.get $v) (i32.const 255))) (call $mwr (i32.add (local.get $a) (i32.const 1)) (i32.and (i32.shr_u (local.get $v) (i32.const 8)) (i32.const 255))))
  (func $mwr32 (param $a i32) (param $v i32) (call $mwr16le (local.get $a) (local.get $v)) (call $mwr16le (i32.add (local.get $a) (i32.const 2)) (i32.shr_u (local.get $v) (i32.const 16))))
  (func $sx (param $v i32) (param $bits i32) (result i32) (i32.shr_s (i32.shl (local.get $v) (i32.sub (i32.const 32) (local.get $bits))) (i32.sub (i32.const 32) (local.get $bits))))

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
