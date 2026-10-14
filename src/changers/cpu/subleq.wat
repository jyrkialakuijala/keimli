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
