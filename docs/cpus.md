# The sixteen machines

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

On random pixels these three rewrite 84–97% of them in a first pass.

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

## Adding a machine

Give it a kind number in `codec.js` and the page's CPU box, write
`src/changers/cpu/<name>.wat` with a `$<name>_step` function using the
helpers of `common.wat`, add it to the `br_table` in `driver.wat` (and to
`$load`/`$spill` if it should keep registers in the pixel), list the file in
`build.sh`, and add a program to `test/mix.test.mjs` and the name to
`test/activity.test.mjs`.
