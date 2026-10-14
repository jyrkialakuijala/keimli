  ;; brainfuck(p, prm, init): run the $cw (16, or 32 for a joint cell) bytes at p as a Brainfuck program on a
  ;; circular tape of as many cells; the tape afterwards is the output. Byte values 0..7 are the commands
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
      (br_if $ie (i32.ge_u (local.get $i) (global.get $cw)))
      (i32.store8 (i32.add (local.get $out) (local.get $i))
        (select (i32.load8_u (i32.add (local.get $p) (local.get $i))) (i32.const 0) (local.get $init)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $il)))
    (block $done (loop $run
      (br_if $done (i32.ge_u (local.get $ip) (global.get $cw)))
      (br_if $done (i32.ge_u (local.get $steps) (i32.const 1024)))
      (local.set $steps (i32.add (local.get $steps) (i32.const 1)))
      (local.set $c (i32.load8_u (i32.add (local.get $p) (local.get $ip))))
      (local.set $cell (i32.add (local.get $out) (local.get $ptr)))
      (block $next
        (if (i32.eq (local.get $c) (i32.const 0)) (then (local.set $ptr (i32.and (i32.add (local.get $ptr) (i32.const 1)) (i32.sub (global.get $cw) (i32.const 1)))) (br $next)))
        (if (i32.eq (local.get $c) (i32.const 1)) (then (local.set $ptr (i32.and (i32.sub (local.get $ptr) (i32.const 1)) (i32.sub (global.get $cw) (i32.const 1)))) (br $next)))
        (if (i32.eq (local.get $c) (i32.const 2)) (then (i32.store8 (local.get $cell) (i32.add (i32.load8_u (local.get $cell)) (i32.const 1))) (br $next)))
        (if (i32.eq (local.get $c) (i32.const 3)) (then (i32.store8 (local.get $cell) (i32.sub (i32.load8_u (local.get $cell)) (i32.const 1))) (br $next)))
        (if (i32.eq (local.get $c) (i32.const 5)) (then
          (i32.store8 (local.get $cell) (i32.load8_u (i32.add (local.get $p) (i32.and (local.get $in) (i32.sub (global.get $cw) (i32.const 1))))))
          (local.set $in (i32.add (local.get $in) (i32.const 1)))
          (br $next)))
        (if (i32.eq (local.get $c) (i32.const 6)) (then
          (if (i32.eqz (i32.load8_u (local.get $cell))) (then
            (local.set $depth (i32.const 1)) (local.set $i (local.get $ip))
            (block $fe (loop $fl
              (local.set $i (i32.add (local.get $i) (i32.const 1)))
              (br_if $fe (i32.ge_u (local.get $i) (global.get $cw)))
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
      (br_if $ce (i32.ge_u (local.get $i) (global.get $cw)))
      (local.set $c (i32.ne (i32.load8_u (i32.add (local.get $out) (local.get $i)))
        (select (i32.load8_u (i32.add (local.get $p) (local.get $i))) (i32.const 0) (local.get $init))))
      (i32.store8 (i32.add (local.get $flags) (local.get $i)) (local.get $c))
      (local.set $changed (i32.add (local.get $changed) (local.get $c)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $cl)))
    (i32.store offset=48 (local.get $prm) (local.get $ptr))
    (i32.or (i32.shl (local.get $steps) (i32.const 8)) (local.get $changed)))
