  ;; simple(p, prm, kind): elementary byte processors. 3 = identity, 4 = bitwise NOT of all
  ;; 16 bytes, 5 = the 16 bytes in reverse order. flags[i] = 1 where the output byte differs
  ;; from the input byte. Returns the number of differing bytes (steps field 0).
  ;; simple(p, prm, kind): 3 = do nothing, 4 = invert, 5 = reverse bytes,
  ;; 16 = add 17: the smallest byte (the first one on ties) gains 1, the byte after it 17 and the byte
  ;; before it 5, all mod 256 with the index wrapping around the cell's $cw bytes (16, or 32 for a joint cell).
  (func $simple (param $p i32) (param $prm i32) (param $kind i32) (result i32)
    (local $out i32) (local $flags i32) (local $i i32) (local $v i32) (local $changed i32) (local $mi i32) (local $d i32)
    (local.set $out (i32.load (local.get $prm)))
    (local.set $flags (i32.load offset=36 (local.get $prm)))
    (if (i32.eq (local.get $kind) (i32.const 16)) (then   ;; index of the smallest byte
      (local.set $i (i32.const 1))
      (block $me (loop $ml (br_if $me (i32.ge_u (local.get $i) (global.get $cw)))
        (if (i32.lt_u (i32.load8_u (i32.add (local.get $p) (local.get $i))) (i32.load8_u (i32.add (local.get $p) (local.get $mi))))
          (then (local.set $mi (local.get $i))))
        (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $ml)))
      (local.set $i (i32.const 0))))
    (block $exit (loop $loop
      (br_if $exit (i32.ge_u (local.get $i) (global.get $cw)))
      (local.set $v
        (if (result i32) (i32.eq (local.get $kind) (i32.const 4))
          (then (i32.and (i32.xor (i32.load8_u (i32.add (local.get $p) (local.get $i))) (i32.const 255)) (i32.const 255)))
          (else (if (result i32) (i32.eq (local.get $kind) (i32.const 5))
            (then (i32.load8_u (i32.add (local.get $p) (i32.sub (i32.sub (global.get $cw) (i32.const 1)) (local.get $i)))))
            (else (if (result i32) (i32.eq (local.get $kind) (i32.const 16))
              (then   ;; d = distance from the smallest byte, mod 16: 0 -> +1, 1 (next) -> +17, 15 (previous) -> +5, else +0
                (local.set $d (i32.and (i32.sub (local.get $i) (local.get $mi)) (i32.sub (global.get $cw) (i32.const 1))))
                (i32.and (i32.add (i32.load8_u (i32.add (local.get $p) (local.get $i)))
                  (select (i32.const 1) (select (i32.const 17) (select (i32.const 5) (i32.const 0) (i32.eq (local.get $d) (i32.sub (global.get $cw) (i32.const 1)))) (i32.eq (local.get $d) (i32.const 1))) (i32.eqz (local.get $d))))
                  (i32.const 255)))
              (else (i32.load8_u (i32.add (local.get $p) (local.get $i))))))))))
      (i32.store8 (i32.add (local.get $out) (local.get $i)) (local.get $v))
      (i32.store8 (i32.add (local.get $flags) (local.get $i)) (i32.ne (local.get $v) (i32.load8_u (i32.add (local.get $p) (local.get $i)))))
      (local.set $changed (i32.add (local.get $changed) (i32.ne (local.get $v) (i32.load8_u (i32.add (local.get $p) (local.get $i))))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $loop)))
    (i32.store offset=48 (local.get $prm) (i32.const 0))
    (local.get $changed))
