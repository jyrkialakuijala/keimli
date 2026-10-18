# The twenty-five machines

Source: `src/changers/cpu/` — `common.wat` (register file and pixel memory
helpers shared by every core), `driver.wat` (the run loop, register load
and spill), and one file per machine. Tests: `test/mix.test.mjs` runs small
programs on every core; `test/activity.test.mjs` measures how much each
rewrites random pixels.

## Conventions

Every core sees the pixel's 16 bytes as its entire address space: addresses
wrap mod 16, stack included, and wider words wrap byte by byte, so odd and
misaligned addresses are fine. Registers live in a 128-byte register file
at byte 256 of linear memory, zeroed before a run (or loaded from the pixel,
below), with the program counter at register-file offset 22 and, for the
8-bit machines, the stack pointer at 20. A selectable number of
instructions (32 to 256, "CPU steps") execute from PC = 0, and the memory
afterwards is the pixel's new content. Halting, interrupt, I/O and
privileged instructions are NOPs, so nothing can stall. The inspector shows
each machine's registers after the run.

`$cpu` in `driver.wat` copies the pixel to the output buffer, zeroes the
register file, calls `$load`, runs the step function of the selected
machine for the step budget, calls `$spill`, and flags the changed bytes.
The Z80 has its own driver of the same shape in `z80.wat`, and the 8080 and
SM83 build on the Z80's register helpers.

**Register load and spill.** Register machines whose random code rarely
stores to memory would converge to a fixed point at once, so they keep
their registers in the pixel instead: `$load` reads them from the 16 bytes
when the run starts, instead of zeroing them, and `$spill` writes them back
when it ends, so register state carries from turn to turn and random code
keeps moving. CHIP-8 maps V0..VF to bytes 0..15; the 4004 maps the 16
nibbles ACC, R0..R14 to bytes 0..7 and leaves bytes 8..15 as memory (a full
spill converged too fast); RISC-V maps the low bytes of x1..x15 to bytes
1..15 and leaves byte 0 alone; the PDP-8 keeps AC, L, PC and MQ in bits
96..123.

## 8-bit microprocessors

- **Zilog Z80** (`z80.wat`). Every unprefixed opcode, every CB opcode, DD/FD
  (IX/IY) addressing including DDCB/FDCB, and the ED subset ADC/SBC HL,rp;
  LD (nn),rp / LD rp,(nn); NEG; RETN/RETI; LD I/R,A and A,I/R; RRD/RLD;
  LDI/LDD/LDIR/LDDR; CPI/CPD/CPIR/CPDR. Other ED opcodes are NOPs. Flags S,
  Z, H, P/V, N, C follow the documented behaviour (X/Y approximately). A
  prefix byte followed by another prefix ends the instruction step, so
  memory full of prefixes cannot stall the core. On a 128 × 128 grid the Z80
  rewrite costs about 74 ms single-threaded.
- **Intel 8080** (`i8080.wat`). The full instruction set with 8080 flags
  (S Z AC P CY, parity always), the duplicate opcodes behaving as on the
  real chip (CBh is JMP, D9h is RET, DDh/EDh/FDh are CALL).
- **MOS 6502** (`m6502.wat`). All 151 documented opcodes including decimal
  mode, the stack page wrapping into the same 16 bytes, BRK vectoring
  through bytes 14–15, every undocumented opcode (the JAM/KIL halts
  included) a NOP.
- **Game Boy SM83** (`sm83.wat`). The 8080/Z80 relative with Z N H C flags;
  LDH and LD (C) wrap into the 16 bytes like everything else.
- **Intel 8051** (`i8051.wat`). The pixel is the internal RAM, so the
  register banks, the stack and the bit area live in it; program memory,
  MOVX and MOVC read the same bytes; the SFRs live in the register file.
- **Motorola 6809** (`m6809.wat`). Every addressing mode including the full
  indexed postbyte with indirection, both prefix pages.

## Small and odd machines

- **Subleq** (`subleq.wat`). One instruction, three byte operands a b c:
  mem[b] -= mem[a], jump to c if the result is ≤ 0. Every step rewrites
  memory.
- **CHIP-8** (`chip8.wat`). 2-byte big-endian instructions, no display or
  keypad (00E0 and DXYN do nothing, EX9E never skips, EXA1 always skips).
- **Intel 4004** (`i4004.wat`). 4-bit; the 16 bytes are both the ROM and 32
  RAM nibbles addressed by SRC mod 32.
- **RISC-V RV32EC** (`riscv.wat`). Full RV32I base plus the integer subset
  of the C extension, 16 registers (x0 reads as zero).

## DEC and Motorola 16/32-bit

- **PDP-8** (`pdp8.wat`). The pixel is 8 words of 12 bits (word k is bits
  12k..12k+11); addresses mod 8, the OPR groups complete, IOT a NOP.
- **PDP-11** (`pdp11.wat`). 8 little-endian words with all eight addressing
  modes including the PC forms; the basic set plus EIS (MUL, DIV, ASH,
  ASHC), XOR, SOB, SXT, MFPS/MTPS, JSR/RTS, RTI/RTT. HALT, WAIT, RESET, the
  traps, the MMU and floating-point groups are NOPs.
- **Motorola 68000** (`m68k.wat`). 16 big-endian bytes with every 68000
  addressing mode and the integer instruction set (MOVE, the
  ADD/SUB/CMP/AND/OR/EOR families with their immediate, quick, address and
  extended forms, shifts and rotates, bit instructions, MULU/MULS/DIVU/DIVS,
  Bcc/DBcc/Scc, JSR/RTS, LEA/PEA, LINK/UNLK, MOVEM, EXG); the BCD
  instructions, CHK, TRAP and lines A/F are NOPs.
- **Motorola 68020** (kind 25, the same `m68k.wat` with the `$m20` flag).
  The 68000 core plus the 68020 additions: the full extension word (16- and
  32-bit base displacements, index scaled by 1, 2, 4 or 8, suppressed base
  or index, memory indirect pre- and post-indexed with an outer
  displacement; the brief format's scale bits count too), MULU.L/MULS.L and
  DIVU.L/DIVS.L with the 64-bit product and dividend forms, the eight bit
  field instructions on registers (the field wraps around the 32 bits) and
  in memory (up to five bytes from ea + offset div 8), EXTB.L, LINK.L,
  Bcc.L (displacement byte FF), RTD, CAS and CMP2 (CHK2 compares without
  trapping). TRAPcc, PACK/UNPK, CAS2, CALLM/RTM, MOVEC/MOVES, BKPT and the
  coprocessor line are NOPs that consume their extension words.

On random pixels these four rewrite 84–97% of them in a first pass.

## Wide-word machines

`common.wat` provides `$fld_rd`/`$fld_wr`, which read and write an n-bit
field (n ≤ 64) at any bit offset of the pixel, and 32- and 64-bit
register-file access.

- **ERA / UNIVAC 1101** (`u1101.wat`). The pixel is 5 words of 24 bits
  (bits 0..119). The 38 operations of the January 1950 ERA instruction list
  under their octal codes (11 OP clear add … 71 NP clear add +1): a 48-bit
  ones' complement accumulator, Q, circular shifts, substitute digits and
  execution address, the four jumps, logical multiply, multiply,
  multiply-add and divide; print and the three stops are NOPs. The skip
  field picks the next word and y is taken mod 5.
- **DEC VAX-11/780** (`vax.wat`). 16 little-endian bytes with every operand
  specifier (short literal, index, register and register deferred,
  autodecrement, autoincrement and immediate, autoincrement deferred and
  absolute, the displacement modes deferred or not, PC relative) and the
  integer, address, branch, loop, bit-field and stack instructions.
  Floating point, decimal, strings, queues and the privileged group are
  NOPs; CALLS/CALLG push only the argument and the PC.
- **CDC 6600** (`cdc6600.wat`). The pixel is 2 words of 60 bits as 8
  parcels of 15 bits executed from the high end. The whole central
  processor set, with the 6600 floating-point format (FX/DX/RX add,
  subtract, multiply, divide, NX/UX/PX), ones' complement IX arithmetic and
  the SA/SB/SX address forms whose A1..A5 loads and A6/A7 stores are the
  only memory traffic. RX is not rounded and a DX add equals an FX add.

Random pixels are rewritten less often by the two tiny-memory machines,
about 12% for the 1101 and 26% for the 6600 on a first pass against 90% for
the VAX, because a 5- or 2-word program has few places to store to.

## Intel 16/32-bit, the i860 and the PIC

- **Intel 8086, 80286, 80386** (`x86.wat`, kinds 26, 27, 28: one core with
  `$xm` = 0, 1, 2). EAX..EDI little-endian at 64 + 4n (so AL is byte 64 + 4n
  and AH 65 + 4n), the six segment registers at 96 + 2n, FLAGS at 20, IP at
  22. Real mode on one flat 16-byte memory: the segment registers are kept
  and moved but take no part in addressing, the stack pointer is 16-bit.
  The 8086 runs its whole instruction set (all addressing modes, the string
  instructions, the decimal adjusts, MUL/IMUL/DIV/IDIV, far calls and
  jumps) with IN/OUT, HLT, WAIT, LOCK, INT and the 8087 escapes as NOPs,
  and reads 60..6F as the Jcc aliases and C0/C1, C8/C9 as the RET aliases
  like the chip. The 80286 adds PUSHA/POPA, PUSH imm, IMUL r,rm,imm, shifts
  by an immediate (counts masked to 31), ENTER/LEAVE, BOUND, INS/OUTS and
  the 0F page, whose protected-mode instructions are NOPs. The 80386 adds
  the 66/67 prefixes (32-bit operands and addresses, SIB), FS/GS,
  CWDE/CDQ, MOVZX/MOVSX, SETcc, Jcc rel32, the bit tests, BSF/BSR,
  SHLD/SHRD, IMUL r,rm and LSS/LFS/LGS; MOV CRn/DRn are NOPs. A REP string
  instruction runs one iteration a step and sets IP back to itself while
  CX allows, as the interruptible loop on the chip does.
- **Intel i860** (`i860.wat`, kind 29). 32-bit little-endian instructions,
  four to a cell. r1..r15 at 64 + 4(n − 1) (r0 is zero, 16..31 alias
  0..15), f2..f15 in the low part of the register file (f0 and f1 zero,
  16..31 alias; a double is the pair fn, fn+1), CC and LCC in byte 20, PC
  at 22. The core integer set with delayed branches (the .t forms skip the
  delay slot when not taken), ld/st in three widths, fld/fst in .l and .d,
  and the scalar floating-point core in single and double precision; the
  pipelined forms run unpipelined, the dual-operation forms, trap, flush,
  lock/unlock, st.c, pfld and pst.d are NOPs.
- **General Instrument PIC1640** (`pic1640.wat`, kind 30). The first PIC
  (1976): 12-bit instructions, the baseline set of 33. The cell is both
  memories: the program is ten 12-bit words at bit offsets 12k (the last 8
  bits are never fetched), the file registers are the bytes, f mod 16,
  with INDF through FSR (byte 4), PCL (f 2, a write is a jump) and STATUS
  (byte 3: C, DC, Z) on top of them, so a write to a file register is a
  write to the program. W and the two-level stack live in the register
  file; OPTION, TRIS, SLEEP and CLRWDT are NOPs. Like the other 128-bit
  machines it sees a pair as two cells.

## DEC Alpha 21064

Kind 43, `alpha.wat`: the first Alpha, the EV4 of 1992, a 64-bit RISC with
32-bit little-endian instructions, four to a cell. The 128-byte register
file holds fifteen 64-bit registers, R0 at 0, R1 at 8 and R2 to R14 at
24 + 8 (n − 2), with the PC at 22 as a byte address; R16 to R30 alias R0
to R14 and R15 and R31 are the zero register, the convention of the RV32E
and i860 cores. Memory is the cell with addresses wrapping byte by byte, so
a quadword may wrap round the end. Implemented: LDA and LDAH; LDL, LDQ and
LDQ_U, with the locked forms as plain loads; STL, STQ and STQ_U, with the
conditional forms storing and setting Ra to 1; the integer arithmetic with
its S4 and S8 forms, the /V forms without traps, the compares and CMPBGE;
the logical group with the conditional moves, AMASK returning Rb and
IMPLVER 0 as on an EV4; SLL, SRL and SRA; the byte-manipulation group
EXTxL/EXTxH, INSxL/INSxH, MSKxL/MSKxH and ZAP/ZAPNOT, which on an EV4 stands
in for the byte and word loads it lacks; MULL, MULQ and UMULH; BR and BSR,
the eight integer conditional branches, and the JMP group. CALL_PAL, the
floating-point loads, stores, operates and branches, the miscellaneous
group (TRAPB, MB, RPCC, ...) and the opcodes of later Alphas (BWX, CIX,
MVI) are NOPs. The test programs cover a store loop, a SUBQ/BNE countdown,
EXTBL, INSBL with ZAPNOT, CMOVEQ, UMULH of 2^64 − 1 squared, ADDL with a
literal and SRA, and the register aliasing.

## HP PA-RISC 1.1

Kind 44, `parisc.wat`: Hewlett-Packard's Precision Architecture in its 1.1
form, the PA-7100 generation of 1992, a 32-bit big-endian RISC with 32-bit
instructions, four to a cell, delayed branches and nullification. The
register file holds GR1 to GR15 as 32-bit words at 64 + 4n; GR0 reads zero
and drops writes, and GR16 to GR31 alias GR0 to GR15, so GR16 is a second
zero register. The PC is at 22 as a byte address, byte 21 the branch state
(nullify the next instruction, a branch is pending) and the pending target
at 24. Memory is the cell, big-endian, wrapping byte by byte. Implemented:
LDO and LDI, LDIL and ADDIL with the scrambled 21-bit immediate, the byte,
halfword and word loads and stores with the 14-bit low-sign displacement
and the modify forms LDWM and STWM; the three-register arithmetic group
(ADD, ADDC, ADDL, the SHnADD forms, SUB, SUBB, SUBT, DS, COMCLR and the /O
forms without traps) and the logical group (AND, ANDCM, OR, XOR, UXOR,
UADDCM), each with its condition completer nullifying the next
instruction; ADDI, ADDIT, SUBI and COMICLR; SHD, EXTRU, EXTRS, ZDEP, DEP,
ZDEPI and DEPI with the shift conditions; BL, BLR and BV; and the compare,
add, bit and move branches COMBT/COMBF, COMIBT/COMIBF, ADDBT/ADDBF,
ADDIBT/ADDIBF, BB, MOVB and MOVIB. Every branch has a delay slot; with the
nullify bit, BL and BV skip the slot and a conditional branch skips it when
taken forward or not taken backward, the loop idiom. The system,
memory-management, coprocessor and floating-point groups, the external
branches and the variable shifts (VSHD, VEXTR, VDEP) are NOPs. The tests
cover a store loop through BL, an ADDIB countdown with the store in the
slot, EXTRU and ZDEP, forward nullification, SH2ADD, LDIL with LDO, ADDI
nullifying its successor, BV, and the register aliasing.

## Redcode

Kind 47, `redcode.wat`: the language of Core War, A. K. Dewdney's 1984
game of programs fighting in a shared memory, here in a 16-bit form so a
cell is a core of 8 instructions and a pair one of 16. An instruction is
a little-endian word op:4, A-mode:2, B-mode:2, A:4, B:4, with the opcodes
DAT, MOV, ADD, SUB, MUL, DIV, MOD, JMP, JMZ, JMN, DJN, SEQ (CMP), SNE, SLT,
SPL and NOP and the modes immediate, direct, B-indirect and predecrement
B-indirect. Fields are unsigned offsets relative to the instruction, taken
mod the core size, so 7 is −1 in a core of 8, and field arithmetic is mod
16. The 1988 rules apply: an immediate A operates on the target's B-field,
otherwise MOV copies the whole instruction and the arithmetic acts on both
fields; DIV and MOD by zero kill the process, as DAT does. A task queue of
up to four processes lives in the register file (byte 20 the count, 21 the
current one, 24 onward the PCs, 22 a mirror of the current PC); SPL adds a
process, the processes run round robin, and when the last one dies the
core restarts with one process at 0. The tests run the Imp, the Dwarf's
first round, an SPL pair, a dying core and a DJN loop.

## Adding a machine

Give it a kind number in `codec.js` and the page's CPU box, write
`src/changers/cpu/<name>.wat` with a `$<name>_step` function using the
helpers of `common.wat`, add it to the `br_table` in `driver.wat` (and to
`$load`/`$spill` if it should keep registers in the pixel), list the file in
`build.sh`, and add a program to `test/mix.test.mjs` and the name to
`test/activity.test.mjs`.
