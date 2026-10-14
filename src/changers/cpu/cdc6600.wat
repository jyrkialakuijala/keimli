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
