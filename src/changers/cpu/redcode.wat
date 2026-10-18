  ;; Redcode, the language of Core War (kind 47), in a 16-bit form: a cell is a core of 8 instructions (16 on a pair),
  ;; each a little-endian word  op:4 | A-mode:2 | B-mode:2 | A:4 | B:4.  Opcodes 0 DAT 1 MOV 2 ADD 3 SUB 4 MUL 5 DIV
  ;; 6 MOD 7 JMP 8 JMZ 9 JMN 10 DJN 11 SEQ (CMP) 12 SNE 13 SLT 14 SPL 15 NOP; modes 0 # immediate, 1 $ direct, 2 @
  ;; B-indirect, 3 < predecrement B-indirect. Fields are unsigned offsets relative to the instruction, taken mod the core
  ;; size, so 7 is -1 in a core of 8 and 15 is -1 in one of 16; field arithmetic is mod 16. The 1988 rules: an immediate
  ;; A operates on the target's B-field, otherwise MOV copies the whole instruction and the arithmetic acts on both
  ;; fields; DIV and MOD by zero kill the process, as DAT does. A task queue of up to four processes lives in the
  ;; register file (byte 20 the count, 21 the current one, 24.. the four PCs, 22..23 a mirror of the current PC for the
  ;; inspector); SPL adds a process, the processes run round robin, and when the last one dies the core restarts with
  ;; one process at 0, so a cell is never silent for long.
  (global $rc_core (mut i32) (i32.const 8))
  (func $rc_addr (param $i i32) (result i32) (i32.shl (i32.rem_u (local.get $i) (global.get $rc_core)) (i32.const 1)))
  (func $rc_get (param $i i32) (result i32) (call $mrd16le (call $rc_addr (local.get $i))))
  (func $rc_put (param $i i32) (param $w i32) (call $mwr16le (call $rc_addr (local.get $i)) (i32.and (local.get $w) (i32.const 0xffff))))
  (func $rc_a (param $w i32) (result i32) (i32.and (i32.shr_u (local.get $w) (i32.const 4)) (i32.const 15)))
  (func $rc_b (param $w i32) (result i32) (i32.and (local.get $w) (i32.const 15)))
  (func $rc_seta (param $i i32) (param $v i32) (call $rc_put (local.get $i) (i32.or (i32.and (call $rc_get (local.get $i)) (i32.const 0xff0f)) (i32.shl (i32.and (local.get $v) (i32.const 15)) (i32.const 4)))))
  (func $rc_setb (param $i i32) (param $v i32) (call $rc_put (local.get $i) (i32.or (i32.and (call $rc_get (local.get $i)) (i32.const 0xfff0)) (i32.and (local.get $v) (i32.const 15)))))
  ;; the address an operand with mode m and field f at pc points to (immediate: pc itself); < decrements first
  (func $rc_resolve (param $pc i32) (param $m i32) (param $f i32) (result i32)
    (local $t i32) (local $nb i32)
    (if (i32.eqz (local.get $m)) (then (return (local.get $pc))))
    (local.set $t (i32.add (local.get $pc) (local.get $f)))
    (if (i32.eq (local.get $m) (i32.const 1)) (then (return (local.get $t))))
    (if (i32.eq (local.get $m) (i32.const 3)) (then
      (local.set $nb (i32.and (i32.sub (call $rc_b (call $rc_get (local.get $t))) (i32.const 1)) (i32.const 15)))
      (call $rc_setb (local.get $t) (local.get $nb))
      (return (i32.add (local.get $t) (local.get $nb)))))
    (i32.add (local.get $t) (call $rc_b (call $rc_get (local.get $t)))))
  (func $rc_arith (param $op i32) (param $x i32) (param $y i32) (result i32)   ;; x op y mod 16; -1 for a division by zero
    (if (i32.eq (local.get $op) (i32.const 2)) (then (return (i32.and (i32.add (local.get $x) (local.get $y)) (i32.const 15)))))
    (if (i32.eq (local.get $op) (i32.const 3)) (then (return (i32.and (i32.sub (local.get $x) (local.get $y)) (i32.const 15)))))
    (if (i32.eq (local.get $op) (i32.const 4)) (then (return (i32.and (i32.mul (local.get $x) (local.get $y)) (i32.const 15)))))
    (if (i32.eqz (local.get $y)) (then (return (i32.const -1))))
    (if (i32.eq (local.get $op) (i32.const 5)) (then (return (i32.div_u (local.get $x) (local.get $y)))))
    (i32.rem_u (local.get $x) (local.get $y)))
  (func $redcode_step
    (local $n i32) (local $cur i32) (local $pc i32) (local $w i32) (local $op i32) (local $am i32) (local $bm i32) (local $a i32) (local $b i32)
    (local $aa i32) (local $ba i32) (local $aw i32) (local $bw i32) (local $next i32) (local $alive i32) (local $r i32) (local $k i32) (local $v i32)
    (global.set $rc_core (i32.shr_u (global.get $cw) (i32.const 1)))
    (local.set $n (call $zr (i32.const 20)))
    (if (i32.or (i32.eqz (local.get $n)) (i32.gt_u (local.get $n) (i32.const 4))) (then (local.set $n (i32.const 1)) (call $zw (i32.const 21) (i32.const 0)) (call $zw16 (i32.const 24) (i32.const 0))))
    (local.set $cur (i32.rem_u (call $zr (i32.const 21)) (local.get $n)))
    (local.set $pc (i32.rem_u (call $zr16 (i32.add (i32.const 24) (i32.shl (local.get $cur) (i32.const 1)))) (global.get $rc_core)))
    (local.set $w (call $rc_get (local.get $pc)))
    (local.set $op (i32.shr_u (local.get $w) (i32.const 12)))
    (local.set $am (i32.and (i32.shr_u (local.get $w) (i32.const 10)) (i32.const 3)))
    (local.set $bm (i32.and (i32.shr_u (local.get $w) (i32.const 8)) (i32.const 3)))
    (local.set $a (call $rc_a (local.get $w))) (local.set $b (call $rc_b (local.get $w)))
    (local.set $aa (call $rc_resolve (local.get $pc) (local.get $am) (local.get $a)))
    (local.set $ba (call $rc_resolve (local.get $pc) (local.get $bm) (local.get $b)))
    (local.set $aw (call $rc_get (local.get $aa))) (local.set $bw (call $rc_get (local.get $ba)))
    (local.set $next (i32.add (local.get $pc) (i32.const 1))) (local.set $alive (i32.const 1))
    (block $done
      (if (i32.eqz (local.get $op)) (then (local.set $alive (i32.const 0)) (br $done)))   ;; DAT
      (if (i32.eq (local.get $op) (i32.const 1)) (then   ;; MOV
        (if (i32.eqz (local.get $am)) (then (call $rc_setb (local.get $ba) (local.get $a))) (else (call $rc_put (local.get $ba) (local.get $aw)))) (br $done)))
      (if (i32.and (i32.ge_u (local.get $op) (i32.const 2)) (i32.le_u (local.get $op) (i32.const 6))) (then   ;; ADD SUB MUL DIV MOD
        (if (i32.eqz (local.get $am))
          (then (local.set $r (call $rc_arith (local.get $op) (call $rc_b (local.get $bw)) (local.get $a)))
                (if (i32.lt_s (local.get $r) (i32.const 0)) (then (local.set $alive (i32.const 0))) (else (call $rc_setb (local.get $ba) (local.get $r)))))
          (else (local.set $r (call $rc_arith (local.get $op) (call $rc_b (local.get $bw)) (call $rc_b (local.get $aw))))
                (local.set $v (call $rc_arith (local.get $op) (call $rc_a (local.get $bw)) (call $rc_a (local.get $aw))))
                (if (i32.or (i32.lt_s (local.get $r) (i32.const 0)) (i32.lt_s (local.get $v) (i32.const 0))) (then (local.set $alive (i32.const 0)))
                  (else (call $rc_setb (local.get $ba) (local.get $r)) (call $rc_seta (local.get $ba) (local.get $v))))))
        (br $done)))
      (if (i32.eq (local.get $op) (i32.const 7)) (then (local.set $next (local.get $aa)) (br $done)))   ;; JMP
      (if (i32.eq (local.get $op) (i32.const 8)) (then (if (i32.eqz (call $rc_b (local.get $bw))) (then (local.set $next (local.get $aa)))) (br $done)))   ;; JMZ
      (if (i32.eq (local.get $op) (i32.const 9)) (then (if (call $rc_b (local.get $bw)) (then (local.set $next (local.get $aa)))) (br $done)))   ;; JMN
      (if (i32.eq (local.get $op) (i32.const 10)) (then   ;; DJN
        (local.set $r (i32.and (i32.sub (call $rc_b (local.get $bw)) (i32.const 1)) (i32.const 15))) (call $rc_setb (local.get $ba) (local.get $r))
        (if (local.get $r) (then (local.set $next (local.get $aa)))) (br $done)))
      (if (i32.or (i32.eq (local.get $op) (i32.const 11)) (i32.eq (local.get $op) (i32.const 12))) (then   ;; SEQ, SNE
        (local.set $r (select (i32.eq (local.get $a) (call $rc_b (local.get $bw))) (i32.eq (local.get $aw) (local.get $bw)) (i32.eqz (local.get $am))))
        (if (i32.eq (local.get $r) (i32.eq (local.get $op) (i32.const 11))) (then (local.set $next (i32.add (local.get $pc) (i32.const 2))))) (br $done)))
      (if (i32.eq (local.get $op) (i32.const 13)) (then   ;; SLT
        (if (i32.lt_u (select (local.get $a) (call $rc_a (local.get $aw)) (i32.eqz (local.get $am))) (call $rc_b (local.get $bw))) (then (local.set $next (i32.add (local.get $pc) (i32.const 2))))) (br $done)))
      (if (i32.eq (local.get $op) (i32.const 14)) (then   ;; SPL: a new process at A, this one continues
        (if (i32.lt_u (local.get $n) (i32.const 4)) (then
          (call $zw16 (i32.add (i32.const 24) (i32.shl (local.get $n) (i32.const 1))) (i32.rem_u (local.get $aa) (global.get $rc_core)))
          (local.set $n (i32.add (local.get $n) (i32.const 1)))))
        (br $done))))
    (if (local.get $alive)
      (then (call $zw16 (i32.add (i32.const 24) (i32.shl (local.get $cur) (i32.const 1))) (i32.rem_u (local.get $next) (global.get $rc_core)))
            (local.set $cur (i32.rem_u (i32.add (local.get $cur) (i32.const 1)) (local.get $n))))
      (else   ;; the process dies: close the gap; an empty core restarts at 0
        (local.set $k (local.get $cur))
        (block $se (loop $sl (br_if $se (i32.ge_u (i32.add (local.get $k) (i32.const 1)) (local.get $n)))
          (call $zw16 (i32.add (i32.const 24) (i32.shl (local.get $k) (i32.const 1))) (call $zr16 (i32.add (i32.const 26) (i32.shl (local.get $k) (i32.const 1)))))
          (local.set $k (i32.add (local.get $k) (i32.const 1))) (br $sl)))
        (local.set $n (i32.sub (local.get $n) (i32.const 1)))
        (if (i32.eqz (local.get $n)) (then (local.set $n (i32.const 1)) (call $zw16 (i32.const 24) (i32.const 0))))
        (local.set $cur (i32.rem_u (local.get $cur) (local.get $n)))))
    (call $zw (i32.const 20) (local.get $n)) (call $zw (i32.const 21) (local.get $cur))
    (call $zw16 (i32.const 22) (call $zr16 (i32.add (i32.const 24) (i32.shl (local.get $cur) (i32.const 1))))))
