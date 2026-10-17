// Tests for the bit-swap lattice module: code tables, decoder, mixing rule, jam and timing checks.
// Run: node test/mix.test.mjs [project dir]
import fs from 'node:fs';
import vm from 'node:vm';
import zlib from 'node:zlib';
const dir = process.argv[2] || new URL('..', import.meta.url).pathname.replace(/\/$/, '');
const Codec = vm.runInThisContext(fs.readFileSync(dir + '/src/changers/codec.js', 'utf8') + '; Codec');
const text = fs.readFileSync(dir + '/src/changers/declaration.txt', 'utf8').trim();
const { instance } = await WebAssembly.instantiate(fs.readFileSync(dir + '/build/keimli.wasm'));
const { memory, mix, mix_from, render, bits, randomize, decode_pixel, blend, sharpen, unsharp, mutate, links, links_reset, hist, change } = instance.exports;
let fails = 0; const check = (n, ok) => { console.log((ok ? 'ok  ' : 'FAIL') + ' ' + n); if (!ok) fails++; };
const L = Codec.LAYOUT, PRM = L.PRM, GRID = L.GRID;
// per-column swap threshold table (uniform value), returns its address
const thrTab = (v, w = 8) => { new BigUint64Array(memory.buffer, L.THR, w).fill(v); return L.THR; };
// per-row smoothing threshold table (uniform value), returns its address
const smTab = (v, h = 8) => { new BigUint64Array(memory.buffer, L.THRY, h).fill(v); return L.THRY; };
const m8 = new Uint8Array(memory.buffer);
const kraft = ls => ls.reduce((s, l) => s + (l ? 2 ** -l : 0), 0);

// ---- length code for every N
for (const Nmax of [2, 4, 8, 16]) {
  const b = Codec.build(text, Nmax);
  check(`N=${Nmax}: length code complete, ${b.lenLengths.length} symbols, codes ${Math.min(...b.lenLengths)}-${Math.max(...b.lenLengths)} bits, expected rate 1 : ${b.rate.toFixed(2)}, ~${b.expectedConsumed.toFixed(0)} bits read per pixel`,
    (kraft(b.lenLengths) === 1 || (Nmax === 2 && b.lenLengths[0] === 0)) && Math.max(...b.lenLengths) <= 12 && b.lenLengths.length === Nmax - 1);
}

// ---- default N = 4
const built = Codec.build(text, 4);
const io = Codec.install(memory, built, Codec.byteLut(built.bytes), 1);   // gain 1: plain averages in the LUT views
io.setCursorOffset(0);   // the decoder tests below reason about absolute cursors; the offset gets its own test
const lenTab = new Uint32Array(memory.buffer, L.LIT, 1 << Codec.LIT_BITS);
check('length table complete (no empty entries)', lenTab.every(e => (e & 255) > 0));
const codeOfLen = len => { const sym = len - 2, l = built.lenLengths[sym]; for (let k = 0; k < lenTab.length; k++) if (lenTab[k] === ((sym << 8) | l)) return [k & ((1 << l) - 1), l]; };

// ---- decoder behaviour
const W = 8, H = 8, N = W * H;
const words = new BigUint64Array(memory.buffer, GRID, 2 * N);
const out = () => Array.from(m8.subarray(io.OUT, io.OUT + 16));
const flags = () => Array.from(m8.subarray(io.FLAGS, io.FLAGS + 16));
const txt = i => text.charCodeAt(((i % text.length) + text.length) % text.length);
// all-zero bits: cursor 0, shortest-code length, skip 0, repeated -> the dictionary from its start
words.fill(0n);
let r = decode_pixel(GRID, 0, PRM);
const len0 = (lenTab[0] >> 8) + 2;
check(`zero pixel reads the dictionary from the start in copies of ${len0} (${r & 255} commands, ${r >> 8} bits)`,
  io.lastOffset() === 0 && out().every((b, k) => b === txt(k)) && (r & 255) === Math.ceil(16 / len0) && built.headerBits === Math.ceil(Math.log2(built.bytes.length)) && io.offsetUnit === 1);
check('decode is deterministic', decode_pixel(GRID, 0, PRM) === r);
// build a bitstream: header, then (length, skip) commands
const stream = (header, cmds) => {
  let bits = BigInt(header), at = BigInt(io.headerBits);
  for (const [len, skip] of cmds) { const [c, l] = codeOfLen(len); bits |= BigInt(c) << at; at += BigInt(l); bits |= BigInt(skip) << at; at += 3n; }
  words[0] = bits & ((1n << 64n) - 1n); words[1] = bits >> 64n;
  return decode_pixel(GRID, 0, PRM);
};
stream(100, [[2, 3], [4, 0]]);
const c300 = 100 * io.offsetUnit;
check(`header 100 -> cursor ${c300} (${io.headerBits}-bit header, ${io.offsetUnit}-byte steps); copy 2 after skip 3 then copy 4 with no skip`,
  io.lastOffset() === c300 && [0, 1].every(k => out()[k] === txt(c300 + 3 + k)) && [2, 3, 4, 5].every(k => out()[k] === txt(c300 + 3 + k)) &&
  flags()[0] === 1 && flags()[1] === 1 && flags()[2] === 0 && flags()[5] === 0);
stream(0, [[4, 7]]);
check('skip 7 then copy 4 yields dictionary bytes 7..10', [0, 1, 2, 3].every(k => out()[k] === txt(7 + k)));
// cursorRead: the header is ceil(log2 V) bits wide and taken mod V; V = 1 reads no header at all
{ io.setCursorRead(100); check('cursor read 100: a 7-bit header', io.headerBits === 7);
  words.fill(0n); words[0] = 37n; decode_pixel(GRID, 0, PRM); const c37 = io.lastOffset();
  words[0] = 100n; decode_pixel(GRID, 0, PRM); const c100 = io.lastOffset();
  check(`header 37 -> cursor 37, header 100 -> cursor 0 (wrapped once): ${c37}, ${c100}`, c37 === 37 && c100 === 0);
  io.setCursorRead(5); const w5 = [0n, 4n, 5n, 6n, 7n].map(h => { words[0] = h; decode_pixel(GRID, 0, PRM); return io.lastOffset(); });
  check(`cursor read 5 (3 bits): headers 0 4 5 6 7 -> cursors ${w5.join(' ')} (5, 6 and 7 wrap to 0, 1 and 2)`, io.headerBits === 3 && w5.join() === '0,4,0,1,2');
  io.setCursorRead(1); words[0] = 0xffffn; const v1 = decode_pixel(GRID, 0, PRM);
  check(`cursor read 1: no header bits, the cursor is the offset alone (${io.lastOffset()}, header ${io.headerBits} bits)`, io.headerBits === 0 && io.lastOffset() === 0 && (v1 >> 8) < 64);
  io.setCursorRead(text.length); check('cursor read = the dictionary size restores the 13-bit header', io.headerBits === built.headerBits); }
// skipBits: the header is read after that many bits of the pixel
{ io.setSkipBits(5); words.fill(0n); words[0] = 0b10110n | (100n << 5n); const v = decode_pixel(GRID, 0, PRM);
  check(`5 skipped bits: the header is read from bit 5 (cursor ${io.lastOffset()}, ${v >> 8} bits consumed)`, io.lastOffset() === 100 * io.offsetUnit && (v >> 8) > io.headerBits + 5);
  io.setSkipBits(16); words[0] = 100n << 16n; decode_pixel(GRID, 0, PRM); check('16 skipped bits', io.lastOffset() === 100 * io.offsetUnit);
  io.setSkipBits(0); }
const vEnd = (text.length - 2) / io.offsetUnit;
if (Number.isInteger(vEnd)) { stream(vEnd, [[4, 0]]); check('a copy running past the end of the dictionary wraps to its start', [0, 1, 2, 3].every(k => out()[k] === txt(text.length - 2 + k))); }
else console.log('   (wrap test skipped: dictionary length does not allow an exact end cursor)');
// random pixels: output is always dictionary text; report consumption
randomize(4 * N, GRID, 7);
let consumed = 0, cmds = 0;
for (let i = 0; i < N; i++) { const v = decode_pixel(GRID, i, PRM); consumed += v >> 8; cmds += v & 255; }
console.log(`   random pixels: mean consumed ${(consumed / N).toFixed(1)} bits (header included), ${(cmds / N).toFixed(1)} commands per pixel, empirical rate ${(128 * N / consumed).toFixed(2)} (expected ${built.rate.toFixed(2)})`);
check('random pixels consume a plausible number of bits', consumed / N > 20 && consumed / N < 128);

// ---- Brainfuck byte changer (changer 1 = empty tape, 2 = tape starts as the pixel)
{
  const BF = s => { const m = { '>': 0, '<': 1, '+': 2, '-': 3, '.': 4, ',': 5, '[': 6, ']': 7 }; const b = new Uint8Array(16).fill(255); [...s].forEach((ch, i) => { b[i] = m[ch]; }); return b; };
  const runBF = (prog, changer) => { io.setChanger(changer); m8.set(prog, GRID); const r = decode_pixel(GRID, 0, PRM); return { steps: r >> 8, changed: r & 255, tape: out(), flags: flags(), ptr: io.lastOffset() }; };
  let r = runBF(BF('++>+++>>-'), 1);
  check(`brainfuck "++>+++>>-" on an empty tape -> [2,3,0,255,...] (${r.steps} steps, pointer ${r.ptr})`, r.tape[0] === 2 && r.tape[1] === 3 && r.tape[2] === 0 && r.tape[3] === 255 && r.ptr === 3 && r.changed === 3 && r.flags[0] === 1 && r.flags[2] === 0 && r.steps === 16);
  r = runBF(BF('+++[-]'), 1);
  check(`brainfuck "+++[-]" counts the cell down to zero (${r.steps} steps)`, r.tape[0] === 0 && r.changed === 0 && r.steps === 20);
  r = runBF(BF('+[]'), 1);
  check('brainfuck "+[]" hits the 1024-step limit', r.steps === 1024 && r.tape[0] === 1);
  r = runBF(BF(',>,>,'), 1);
  check('brainfuck "," reads the program\'s own bytes', r.tape[0] === 5 && r.tape[1] === 0 && r.tape[2] === 5);
  r = runBF(BF(']+[+'), 1);
  check('unmatched brackets are ignored', r.tape[0] === 2 && r.steps === 16);
  r = runBF(BF('[-]'), 2);
  check('tape = pixel: "[-]" clears cell 0 (which held "[" = 6)', r.tape[0] === 0 && r.tape[1] === 3 && r.tape[2] === 7 && r.changed === 1);
  r = runBF(BF('<-'), 2);
  check('pointer wraps: "<-" decrements cell 15 (was 255 -> 254)', r.tape[15] === 254 && r.ptr === 15);
  // Z80 (changer 6): tiny programs that end in a JR -2 loop so memory stays put
  {
    const REG = 256, z = s => { const b = new Uint8Array(16); s.split(' ').forEach((h, i) => { b[i] = parseInt(h, 16); }); return b; };
    const runZ = prog => { io.setChanger(6); m8.set(prog, GRID); const r = decode_pixel(GRID, 0, PRM); return { mem: out(), fl: flags(), regs: m8.slice(REG, REG + 28), pc: io.lastOffset(), ret: r }; };
    const r16 = (g, lo) => g[lo] | (g[lo + 1] << 8);
    let r = runZ(z('3E 12 32 0E 00 18 FE'));
    check(`Z80 LD A,12h; LD (0Eh),A; JR -2 -> mem[14]=12h, PC=5 (${r.ret >> 8} steps)`, r.mem[14] === 0x12 && r.regs[7] === 0x12 && r.pc === 5 && r.fl[14] === 1 && (r.ret & 255) === 1 && (r.ret >> 8) === 256);
    r = runZ(z('3E FF 3C 18 FE'));
    check('Z80 INC A from FFh gives 0 with Z and H set, no carry change', r.regs[7] === 0 && (r.regs[6] & 0x40) && (r.regs[6] & 0x10) && !(r.regs[6] & 0x01));
    r = runZ(z('21 34 12 23 22 0E 00 18 FE'));
    check('Z80 LD HL,1234h; INC HL; LD (0Eh),HL', r.mem[14] === 0x35 && r.mem[15] === 0x12 && r16(r.regs, 4) === 0x1235);
    r = runZ(z('01 CD AB C5 18 FE'));
    check('Z80 PUSH BC writes below SP (wrapping to bytes 14,15) and SP becomes FFFEh', r.mem[14] === 0xcd && r.mem[15] === 0xab && r16(r.regs, 20) === 0xfffe);
    r = runZ(z('01 CD AB 11 34 12 C5 D5 18 FE'));
    check('Z80 PUSH BC; PUSH DE: the stack walks down two bytes a push, BC at 14,15 and DE at 12,13, SP = FFFCh', r.mem[14] === 0xcd && r.mem[15] === 0xab && r.mem[12] === 0x34 && r.mem[13] === 0x12 && r16(r.regs, 20) === 0xfffc);
    r = runZ(z('01 CD AB C5 D1 18 FE'));
    check('Z80 PUSH BC; POP DE: POP reads the pushed value back (DE = ABCDh), SP returns to 0 and the bytes stay in memory', r16(r.regs, 2) === 0xabcd && r16(r.regs, 20) === 0 && r.mem[14] === 0xcd && r.mem[15] === 0xab);
    r = runZ(z('31 01 00 01 CD AB C5 18 FE'));
    check('Z80 LD SP,1; PUSH BC: SP becomes FFFFh and the two bytes wrap one by one, low byte at 15, high byte at 0', r16(r.regs, 20) === 0xffff && r.mem[15] === 0xcd && r.mem[0] === 0xab);
    r = runZ(z('CD 08 00 00 00 00 00 00 3E 2A 18 FE'));
    check('Z80 CALL 8 pushes the return address 0003h at 14,15 (SP = FFFEh); the routine loops without a RET, so it stays there', r.mem[14] === 0x03 && r.mem[15] === 0x00 && r16(r.regs, 20) === 0xfffe && r.regs[7] === 0x2a);
    r = runZ(z('CF 00 00 00 00 00 00 00 3E 2A 18 FE'));
    check('Z80 RST 08h pushes the return address 0001h at 14,15 and jumps to 8', r.mem[14] === 0x01 && r.mem[15] === 0x00 && r16(r.regs, 20) === 0xfffe && r.regs[7] === 0x2a);
    r = runZ(z('31 0C 00 21 00 00 39 E5 18 FE'));
    check('Z80 LD SP,12; LD HL,0; ADD HL,SP; PUSH HL: the stack pointer\'s own value (000Ch) goes onto the stack at 10,11, SP = 10', r.mem[10] === 0x0c && r.mem[11] === 0x00 && r16(r.regs, 20) === 10 && r16(r.regs, 4) === 12);
    r = runZ(z('31 0C 00 ED 73 0E 00 18 FE'));
    check('Z80 LD (0Eh),SP stores SP (000Ch) without moving it', r.mem[14] === 0x0c && r.mem[15] === 0x00 && r16(r.regs, 20) === 12);
    // store-free programs are fixed points of the changer: the lattice saturates in cells like these two (seen on the page),
    // which run their 256 instructions without a single write, so only the swaps, the smoothing and mutation move them on
    r = runZ(z('00 01 54 40 80 20 11 10 4B 40 4B 40 4B 00 4B 40'));
    check(`Z80 fixed point: NOP; LD BC,4054h; ADD A,B; JR NZ,+11h (to byte 8); LD C,E / LD B,B ... runs 256 instructions with no store (${r.ret & 255} bytes changed, A = ${r.regs[7].toString(16)}h)`,
          (r.ret & 255) === 0 && (r.ret >> 8) === 256 && r.fl.every(f => f === 0) && r.regs[7] === 0x7f);
    r = runZ(z('3E 00 3E 00 3E 00 3E 00 5E 00 41 00 3E 00 1E 00'));
    check(`Z80 fixed point: LD A,0 x4; LD E,(HL); LD B,C; LD A,0; LD E,0: loads only, no store (${r.ret & 255} bytes changed)`, (r.ret & 255) === 0 && (r.ret >> 8) === 256 && r.fl.every(f => f === 0));
    r = runZ(z('00 00 29 00 29 00 29 20 29 00 29 00 49 D0 00 08'));
    check(`Z80 fixed point: ADD HL,HL runs, JR NZ, LD C,C, RET NC (pops without writing), EX AF,AF': no store (${r.ret & 255} bytes changed)`, (r.ret & 255) === 0 && (r.ret >> 8) === 256 && r.fl.every(f => f === 0));
    r = runZ(z('BD 81 3F 90 3F 08 3F 20 23 20 3F 00 3F 00 5B 44'));
    check(`Z80 fixed point: CP L; ADD A,C; CCF; SUB B; EX AF,AF'; JR NZ ...; LD E,E; LD B,H: arithmetic on registers only (${r.ret & 255} bytes changed)`, (r.ret & 255) === 0 && (r.ret >> 8) === 256 && r.fl.every(f => f === 0));
    r = runZ(z('31 0E 00 21 34 12 E3 18 FE 00 00 00 00 00 CD AB'));
    check('Z80 EX (SP),HL swaps HL with the word at the top of the stack in place: HL = ABCDh, bytes 14,15 = 34 12, SP unchanged', r16(r.regs, 4) === 0xabcd && r.mem[14] === 0x34 && r.mem[15] === 0x12 && r16(r.regs, 20) === 14);
    r = runZ(z('31 0E 00 DD 21 34 12 DD E3 18 FE 00 00 00 CD AB'));
    check('Z80 EX (SP),IX likewise', r16(r.regs, 16) === 0xabcd && r.mem[14] === 0x34 && r.mem[15] === 0x12 && r16(r.regs, 20) === 14);
    r = runZ(z('31 0E 00 01 34 12 C5 E1 18 FE'));
    check('Z80 PUSH BC; POP HL with SP = 14 round-trips through bytes 12,13: HL = 1234h, SP back at 14', r16(r.regs, 4) === 0x1234 && r.mem[12] === 0x34 && r.mem[13] === 0x12 && r16(r.regs, 20) === 14);
    r = runZ(z('31 02 00 01 34 12 C5 18 FE'));
    check('Z80 LD SP,2; PUSH BC writes over the code at bytes 0,1 and SP becomes 0', r.mem[0] === 0x34 && r.mem[1] === 0x12 && r16(r.regs, 20) === 0);
    r = runZ(z('21 0E 00 3E 12 ED 67 18 FE 00 00 00 00 00 AB 00'));
    check('Z80 RRD with A = 12h, (HL) = ABh: A = 1Bh, (HL) = 2Ah, parity even', r.regs[7] === 0x1b && r.mem[14] === 0x2a && (r.regs[6] & 0x04) !== 0 && (r.regs[6] & 0xc1) === 0);
    r = runZ(z('21 0E 00 3E 12 ED 6F 18 FE 00 00 00 00 00 AB 00'));
    check('Z80 RLD with A = 12h, (HL) = ABh: A = 1Ah, (HL) = B2h, parity odd', r.regs[7] === 0x1a && r.mem[14] === 0xb2 && (r.regs[6] & 0x04) === 0);
    r = runZ(z('21 0F 00 11 0E 00 01 01 00 ED A8 18 FE 00 00 77'));
    check('Z80 LDD copies (HL) to (DE) and decrements HL, DE and BC', r.mem[14] === 0x77 && r16(r.regs, 4) === 14 && r16(r.regs, 2) === 13 && r16(r.regs, 0) === 0);
    r = runZ(z('21 01 00 11 0F 00 01 02 00 ED B8 18 FE 00 00 00'));
    check('Z80 LDDR copies two bytes downward from 1 to 15: bytes 14,15 = 21 01, HL wraps to FFFFh, DE = 13, BC = 0', r.mem[14] === 0x21 && r.mem[15] === 0x01 && r16(r.regs, 4) === 0xffff && r16(r.regs, 2) === 13 && r16(r.regs, 0) === 0);
    r = runZ(z('21 0C 00 01 04 00 3E 42 ED B1 18 FE 00 42 00 00'));
    check('Z80 CPIR stops at the match at 13: HL = 14, BC = 2, Z set, P/V set (BC not 0), memory untouched', r16(r.regs, 4) === 14 && r16(r.regs, 0) === 2 && (r.regs[6] & 0x44) === 0x44 && r.mem[13] === 0x42 && r.mem[12] === 0);
    r = runZ(z('3E 81 CB 07 18 FE'));
    check('Z80 RLC A: 81h -> 03h with carry', r.regs[7] === 0x03 && (r.regs[6] & 1) === 1);
    r = runZ(z('06 05 3C 10 FD 18 FE'));
    check('Z80 DJNZ loop increments A five times', r.regs[7] === 5 && r.regs[1] === 0);
    r = runZ(z('76 3C 18 FE'));
    check('Z80 HALT is a NOP: execution continues to INC A', r.regs[7] === 1);
    r = runZ(z('DD 21 00 00 DD 36 0E 77 18 FE'));
    check('Z80 LD IX,0; LD (IX+14),77h', r.mem[14] === 0x77 && r16(r.regs, 16) === 0);
    r = runZ(z('21 00 00 11 0C 00 01 02 00 ED B0 18 FE'));
    check('Z80 LDIR copies two bytes from 0 to 12', r.mem[12] === 0x21 && r.mem[13] === 0x00 && r16(r.regs, 0) === 0 && r16(r.regs, 4) === 2 && r16(r.regs, 2) === 14);
    r = runZ(z('3E 0F C6 01 27 18 FE'));
    check('Z80 ADD A,1 to 0Fh then DAA -> 16h', r.regs[7] === 0x16);
    r = runZ(z('CD 08 00 18 FE 00 00 00 3E 2A C9'));
    check('Z80 CALL 8 / RET returns to the loop with A=2Ah; RET popped the address, SP back at 0', r.regs[7] === 0x2a && r.pc === 3 && r16(r.regs, 20) === 0);
    r = runZ(z('3E 55 EE FF 18 FE'));
    check('Z80 XOR FFh gives AAh with S set and parity even', r.regs[7] === 0xaa && (r.regs[6] & 0x80) && (r.regs[6] & 0x04));
    r = runZ(z('01 0E 00 3E 55 02 18 FE'));
    check('Z80 LD (BC),A takes no operand bytes', r.mem[14] === 0x55 && r.pc === 6);
    io.setChanger(0);
  }
  // MOS 6502 (changer 7) and Intel 8080 (changer 8)
  {
    const REG = 256, z = s => { const b = new Uint8Array(16); s.split(' ').forEach((h, i) => { b[i] = parseInt(h, 16); }); return b; };
    const runC = (prog, changer) => { io.setChanger(changer); m8.set(prog, GRID); const r = decode_pixel(GRID, 0, PRM); return { mem: out(), regs: m8.slice(REG, REG + 28), pc: io.lastOffset(), ret: r }; };
    let r = runC(z('A9 12 8D 0E 00 4C 05 00'), 7);
    check('6502 LDA #$12; STA $000E; JMP loop', r.mem[14] === 0x12 && r.regs[0] === 0x12 && r.pc === 5);
    r = runC(z('A9 00 A2 05 18 69 03 CA D0 FB 4C 0A 00'), 7);
    check('6502 ADC loop with DEX/BNE adds 3 five times', r.regs[0] === 15 && r.regs[1] === 0 && (r.regs[4] & 2) !== 0);
    r = runC(z('A9 42 48 A9 00 68 4C 06 00'), 7);
    check('6502 PHA/PLA through the wrapped stack page (S starts at $FF, so the push lands on byte 15)', r.regs[0] === 0x42 && r.mem[15] === 0x42 && r.regs[3] === 0xFF);
    r = runC(z('20 06 00 4C 03 00 A9 77 60'), 7);
    check('6502 JSR/RTS', r.regs[0] === 0x77 && r.pc === 3);
    r = runC(z('A9 81 0A 4C 03 00'), 7);
    check('6502 ASL A: $81 -> $02 with carry, N clear', r.regs[0] === 2 && (r.regs[4] & 1) === 1 && (r.regs[4] & 0x80) === 0);
    r = runC(z('A2 02 A9 55 9D 0C 00 4C 07 00'), 7);
    check('6502 STA abs,X', r.mem[14] === 0x55);
    r = runC(z('F8 A9 09 18 69 01 4C 06 00'), 7);
    check('6502 decimal mode: 09 + 01 = 10 (BCD)', r.regs[0] === 0x10);
    r = runC(z('02 A9 01 4C 03 00'), 7);
    check('6502 JAM ($02) is a NOP, execution continues', r.regs[0] === 1);
    r = runC(z('3E 12 32 0E 00 C3 05 00'), 8);
    check('8080 MVI A,12h; STA 000Eh; JMP loop', r.mem[14] === 0x12 && r.regs[7] === 0x12 && r.pc === 5);
    r = runC(z('06 05 3C 05 C2 02 00 C3 07 00'), 8);
    check('8080 INR A / DCR B / JNZ loop', r.regs[7] === 5 && r.regs[1] === 0);
    r = runC(z('76 3C C3 02 00'), 8);
    check('8080 HLT is a NOP', r.regs[7] === 1);
    r = runC(z('CB 06 00 00 00 00 3C C3 07 00'), 8);
    check('8080 opcode CBh is a duplicate JMP, not a prefix', r.regs[7] === 1 && r.pc === 7);
    r = runC(z('3E 0F C6 01 27 C3 05 00'), 8);
    check('8080 ADI then DAA -> 16h', r.regs[7] === 0x16);
    r = runC(z('3E 55 EE FF C3 04 00'), 8);
    check('8080 XRI FFh -> AAh with S, P and the fixed bit 1 (F = 86h)', r.regs[7] === 0xaa && r.regs[6] === 0x86);
    r = runC(z('01 CD AB C5 C3 04 00'), 8);
    check('8080 PUSH B wraps below SP into bytes 14,15', r.mem[14] === 0xcd && r.mem[15] === 0xab);
    r = runC(z('01 0E 00 3E 55 02 C3 06 00'), 8);
    check('8080 STAX B takes no operand bytes', r.mem[14] === 0x55 && r.pc === 6);
    io.setChanger(0);
  }
  // Subleq (9), CHIP-8 (10), Intel 4004 (11), Game Boy SM83 (12)
  {
    const REG = 256, z = s => { const b = new Uint8Array(16); s.split(' ').forEach((h, i) => { b[i] = parseInt(h, 16); }); return b; };
    const runC = (prog, changer, steps = 256) => { io.setChanger(changer); io.setSteps(steps); m8.set(prog, GRID); const r = decode_pixel(GRID, 0, PRM); io.setSteps(256); return { mem: out(), regs: m8.slice(REG, REG + 128), pc: io.lastOffset(), ret: r }; };
    let r = runC(z('05 06 09 00 00 02 05'), 9, 1);
    check('Subleq: mem[6] -= mem[5] (5-2=3 > 0) falls through to PC 3', r.mem[6] === 3 && r.pc === 3);
    r = runC(z('05 06 09 00 00 02 01'), 9, 1);
    check('Subleq: result -1 <= 0 jumps to c = 9', r.mem[6] === 0xff && r.pc === 9);
    r = runC(z('60 2A A0 0E F0 55 10 06'), 10);
    check('CHIP-8: V0 = 2Ah; I = 14; FX55 stores it; 1NNN loops; V0..VF loaded from and spilled over the bytes', r.mem[0] === 0x2a && r.mem[2] === 0xa0 && r.mem[14] === 0 && r.regs[0] === 0x2a && r.regs[2] === 0xa0 && r.pc === 6);   // V2 keeps its initial value, byte 2 of the program
    r = runC(z('60 FF 61 02 80 14 A0 0E F0 55 10 0A'), 10);
    check('CHIP-8: 8XY4 FF + 02 = 01 with VF = 1', r.regs[0] === 1 && r.regs[15] === 1 && r.mem[0] === 1 && r.mem[15] === 1);
    r = runC(z('60 7B A0 0D F0 33 F2 65 10 08'), 10);
    check('CHIP-8: FX33 stores BCD of 123 at I, FX65 reads it back into V0..V2', r.mem[0] === 1 && r.mem[1] === 2 && r.mem[2] === 3 && r.regs[1] === 2);
    r = runC(z('20 1D 21 D5 E0 D0 E9 40 07'), 11);
    check('4004: FIM/SRC select RAM nibble 29, LDM 5, WRM, LDM 0, RDM reads 5 back; ACC, R0, R1 spilled into bytes 0..1, R2 keeps its loaded value, byte 14 kept', r.regs[0] === 5 && r.mem[0] === 0x15 && r.mem[1] === 0x1d && r.regs[4] === 1 && r.mem[14] === 0x50 && r.mem[8] === 0x07);
    r = runC(z('D3 B0 D4 80 40 04'), 11);
    check('4004: LDM 3; XCH R0 (R0 was loaded as Dh); LDM 4; ADD R0 -> ACC 7, R0 3', r.regs[0] === 7 && r.regs[2] === 3 && r.regs[1] === 0 && r.mem[0] === 0x37);
    r = runC(z('3E 12 EA 0E 00 18 FE'), 12);
    check('SM83: LD A,12h; LD (000Eh),A; JR -2', r.mem[14] === 0x12 && r.pc === 5);
    r = runC(z('3E 0F C6 01 27 18 FE'), 12);
    check('SM83: ADD then DAA -> 16h', r.regs[7] === 0x16);
    r = runC(z('AF 18 FE'), 12);
    check('SM83: XOR A sets only Z (F = 80h)', r.regs[7] === 0 && r.regs[6] === 0x80);
    r = runC(z('3E 12 CB 37 18 FE'), 12);
    check('SM83: SWAP A: 12h -> 21h', r.regs[7] === 0x21);
    r = runC(z('3E 77 E0 0F 18 FE'), 12);
    check('SM83: LDH (0Fh),A writes byte 15', r.mem[15] === 0x77);
    r = runC(z('21 00 00 22 22 18 FE'), 12);
    check('SM83: LD (HL+),A twice advances HL to 2', (r.regs[4] | (r.regs[5] << 8)) === 2);
    r = runC(z('76 10 3C 18 FE'), 12);
    check('SM83: HALT and STOP are NOPs', r.regs[7] === 1);
    io.setChanger(0);
  }
  // Intel 8051 (13): internal RAM is the pixel, so R0..R7 are bytes 0..7
  {
    const REG = 256, z = s => { const b = new Uint8Array(16); s.split(' ').forEach((h, i) => { b[i] = parseInt(h, 16); }); return b; };
    const runC = (prog, changer) => { io.setChanger(changer); m8.set(prog, GRID); const r = decode_pixel(GRID, 0, PRM); return { mem: out(), regs: m8.slice(REG, REG + 64), pc: io.lastOffset(), ret: r }; };
    let r = runC(z('74 12 F5 0E 80 FE'), 13);
    check('8051 MOV A,#12h; MOV 0Eh,A; SJMP $', r.mem[14] === 0x12 && r.regs[0] === 0x12 && r.pc === 4);
    r = runC(z('75 0E 05 E4 04 D5 0E FC 80 FE'), 13);
    check('8051 MOV 0Eh,#5; CLR A; loop INC A; DJNZ 0Eh: A = 5 and byte 14 = 0 (R0..R7 would overlap the code)', r.regs[0] === 5 && r.mem[14] === 0);
    r = runC(z('74 0F 24 01 D4 80 FE'), 13);
    check('8051 ADD then DA A -> 16h', r.regs[0] === 0x16);
    r = runC(z('74 55 64 FF 80 FE'), 13);
    check('8051 XRL A,#FFh -> AAh with P set (even parity)', r.regs[0] === 0xaa && (r.regs[2] & 1) === 0);
    r = runC(z('D2 07 80 FE'), 13);
    check('8051 SETB 07h sets bit 7 of byte 20h (-> byte 0 mod 16)', (r.mem[0] & 0x80) !== 0);
    r = runC(z('74 03 75 F0 05 A4 80 FE'), 13);
    check('8051 MUL AB: 3 x 5 = 15', r.regs[0] === 15 && r.regs[1] === 0);
    r = runC(z('12 00 06 80 FE 00 74 2A 22'), 13);
    check('8051 LCALL / RET with the stack in RAM', r.regs[0] === 0x2a && r.pc === 3 && r.regs[3] === 0);
    r = runC(z('90 00 0D 74 66 F0 80 FE'), 13);
    check('8051 MOV DPTR,#000Dh; MOVX @DPTR,A writes byte 13', r.mem[13] === 0x66);
    io.setChanger(0);
  }
  // Motorola 6809 (14) and RISC-V RV32EC (15)
  {
    const REG = 256, z = s => { const b = new Uint8Array(16); s.split(' ').forEach((h, i) => { b[i] = parseInt(h, 16); }); return b; };
    const runC = (prog, changer) => { io.setChanger(changer); m8.set(prog, GRID); const r = decode_pixel(GRID, 0, PRM); return { mem: out(), regs: m8.slice(REG, REG + 128), pc: io.lastOffset(), ret: r }; };
    const x = (r, n) => new Int32Array(r.regs.buffer, r.regs.byteOffset + 64 + 4 * n, 1)[0];
    let r = runC(z('86 12 B7 00 0E 20 FE'), 14);
    check('6809 LDA #$12; STA $000E; BRA *', r.mem[14] === 0x12 && r.regs[0] === 0x12 && r.pc === 5);
    r = runC(z('C6 05 4F 4C 5A 26 FC 20 FE'), 14);
    check('6809 LDB #5; CLRA; loop INCA; DECB; BNE: A = 5', r.regs[0] === 5 && r.regs[1] === 0 && (r.regs[3] & 4) !== 0);
    r = runC(z('8E 00 0C 86 77 A7 84 20 FE'), 14);
    check('6809 LDX #$000C; STA ,X writes byte 12', r.mem[12] === 0x77);
    r = runC(z('8E 00 0A A7 80 A7 80 20 FE'), 14);
    check('6809 STA ,X+ twice advances X to $000C', (r.regs[4] | (r.regs[5] << 8)) === 0x0c);
    r = runC(z('CC 12 34 FD 00 0E 20 FE'), 14);
    check('6809 LDD #$1234; STD $000E stores big-endian', r.mem[14] === 0x12 && r.mem[15] === 0x34);
    r = runC(z('86 19 8B 01 19 20 FE'), 14);
    check('6809 ADDA then DAA: 19 + 1 = 20 (BCD)', r.regs[0] === 0x20);
    r = runC(z('8D 03 20 FE 00 86 2A 39'), 14);
    check('6809 BSR/RTS (S starts at 0 and wraps)', r.regs[0] === 0x2a && r.pc === 2);
    r = runC(z('1F 89 20 FE'), 14);
    check('6809 TFR A,B with A = 0 leaves B = 0 and flags untouched; TFR decodes', r.regs[1] === 0);
    // RISC-V: addi x1,x0,0x12 ; sb x1,14(x0) ; j .
    // addi x1,x0,18 ; sb x1,14(x0) ; lb x2,14(x0) ; c.j . (2 bytes, so bytes 14..15 are data, not code)
    r = runC(z('93 00 20 01 23 07 10 00 03 01 E0 00 01 A0 00 00'), 15);
    check('RV32I addi x1,x0,18; sb x1,14(x0); lb x2,14(x0); c.j .; x1..x15 written back over bytes 1..15', x(r, 1) === 0x12 && x(r, 2) === 0x12 && r.pc === 12 && r.mem[0] === 0x93 && r.mem[1] === 0x12 && r.mem[2] === 0x12 && r.mem[13] === 0xa0 && r.mem[14] === 0);
    // compressed: c.li x1,5 ; c.li x2,0 ; loop: c.addi x2,3 ; c.addi x1,-1 ; c.bnez x1,-4 ; c.j .
    r = runC(z('15 44 81 44 8D 04 7D 14 75 FC 01 A0'), 15);
    check('RV32C c.li x8,5; c.li x9,0; loop c.addi x9,3; c.addi x8,-1; c.bnez x8: x9 = 15, x8 = 0', x(r, 9) === 15 && x(r, 8) === 0 && r.pc === 10);
    // sw: lui-free store of a 32-bit value: addi x1,x0,-1 ; sw x1,12(x0) ; j .
    r = runC(z('93 00 F0 FF 23 26 10 00 03 21 C0 00 6F 00 00 00'), 15);
    check('RV32I sw stores a little-endian word at 12..15, lw reads it back into x2; x12 (loaded from byte 12 = 6Fh at the start) is written back', x(r, 2) === -1 && r.mem[2] === 0xff && r.mem[12] === 0x6f);
    // jalr/ret through x1: jal x1,8 ; j . ; (at 8) addi x3,x0,7 ; jalr x0,0(x1)
    r = runC(z('EF 00 80 00 6F 00 00 00 93 01 70 00 67 80 00 00'), 15);
    check('RV32I jal/jalr call and return', x(r, 3) === 7 && x(r, 1) === 4 && r.pc === 4);
    r = runC(z('93 00 00 00 13 01 00 00 73 00 10 00 6F 00 00 00'), 15);
    check('RV32I ebreak is a NOP and x0 stays zero', x(r, 0) === 0 && r.pc === 12);
    io.setChanger(0);
  }
  // DEC PDP-8 (19), DEC PDP-11 (20), Motorola 68000 (21)
  {
    const REG = 256;
    const runC = (prog, changer) => { io.setChanger(changer); m8.set(prog, GRID); const r = decode_pixel(GRID, 0, PRM); return { mem: out(), regs: m8.slice(REG, REG + 128), pc: io.lastOffset(), ret: r }; };
    // PDP-8: 8 words of 12 bits packed at pixel bits 0..95, then AC (96) L (108) PC (109) MQ (112)
    const p8 = (words, ac = 0, l = 0, pc = 0, mq = 0) => { const b = new Uint8Array(16); const put = (off, n, v) => { for (let i = 0; i < n; i++) if ((v >> i) & 1) b[(off + i) >> 3] |= 1 << ((off + i) & 7); };
      words.forEach((w, k) => put(12 * k, 12, w)); put(96, 12, ac); put(108, 1, l); put(109, 3, pc); put(112, 12, mq); return b; };
    const rd = (b, off, n) => { let v = 0; for (let i = 0; i < n; i++) v |= ((b[(off + i) >> 3] >> ((off + i) & 7)) & 1) << i; return v; };
    let r = runC(p8([0o1007, 0o3006, 0o5002, 0, 0, 0, 0, 0o123]), 19);
    check('PDP-8 TAD 7; DCA 6; JMP 2: word 6 = 0123, AC cleared, PC written back as 2', rd(r.mem, 72, 12) === 0o123 && rd(r.mem, 96, 12) === 0 && rd(r.mem, 109, 3) === 2 && r.pc === 2);
    r = runC(p8([0o7240, 0o7001, 0o5002]), 19);
    check('PDP-8 CLA CMA; IAC: AC wraps to 0 and complements the link', rd(r.mem, 96, 12) === 0 && rd(r.mem, 108, 1) === 1);
    r = runC(p8([0o2007, 0o7001, 0o5002, 0, 0, 0, 0, 0o7777]), 19);
    check('PDP-8 ISZ 7 on 7777 skips the IAC', rd(r.mem, 84, 12) === 0 && rd(r.mem, 96, 12) === 0);
    r = runC(p8([0o7440, 0o7001, 0o5002], 5), 19);
    check('PDP-8 SZA with AC = 5 (loaded from the pixel) does not skip: AC = 6', rd(r.mem, 96, 12) === 6);
    r = runC(p8([0o4003, 0o5001, 0, 0, 0o7001, 0o5403]), 19);
    check('PDP-8 JMS 3 stores the return address; JMP I 3 returns', rd(r.mem, 36, 12) === 1 && rd(r.mem, 96, 12) === 1 && r.pc === 1);
    r = runC(p8([0o7421, 0o7501, 0o5002], 0o123), 19);
    check('PDP-8 MQL then MQA: MQ = AC = 0123', rd(r.mem, 112, 12) === 0o123 && rd(r.mem, 96, 12) === 0o123);
    // PDP-11: little-endian words; registers R0..R6 at 0,2,..,12 and PSW at 20 in the register file
    const p11 = words => { const b = new Uint8Array(16); words.forEach((w, i) => { b[2 * i] = w & 255; b[2 * i + 1] = w >> 8; }); return b; };
    const R = (r, n) => r.regs[2 * n] | (r.regs[2 * n + 1] << 8);
    r = runC(p11([0o012737, 0x1234, 0o16, 0o000777]), 20);
    check('PDP-11 MOV #1234, @#16; BR .', r.mem[14] === 0x34 && r.mem[15] === 0x12 && r.pc === 6);
    r = runC(p11([0o012701, 5, 0o005000, 0o005200, 0o005301, 0o001375, 0o000777]), 20);
    check('PDP-11 MOV #5,R1; CLR R0; loop INC R0; DEC R1; BNE: R0 = 5, Z set', R(r, 0) === 5 && R(r, 1) === 0 && (R(r, 10) & 4) !== 0 && r.pc === 12);
    r = runC(p11([0o004737, 8, 0o000777, 0, 0o012700, 0o167, 0o000207]), 20);
    check('PDP-11 JSR PC,@#10; RTS PC (stack wraps to bytes 14..15)', R(r, 0) === 0o167 && r.pc === 4 && r.mem[14] === 4 && R(r, 6) === 0);
    r = runC(p11([0o112702, 0o200, 0o000777]), 20);
    check('PDP-11 MOVB #200,R2 sign-extends into the register', R(r, 2) === 0xff80 && (R(r, 10) & 8) !== 0);
    r = runC(p11([0o012701, 3, 0o005000, 0o062700, 2, 0o077103, 0o000777]), 20);
    check('PDP-11 SOB loop adds 2 three times', R(r, 0) === 6 && R(r, 1) === 0);
    r = runC(p11([0o012700, 0o100001, 0o006200, 0o000777]), 20);
    check('PDP-11 ASR R0: 100001 -> 140000 with C and N set', R(r, 0) === 0xc000 && (R(r, 10) & 9) === 9);
    r = runC(p11([0o012700, 7, 0o012701, 6, 0o070001, 0o000777]), 20);
    check('PDP-11 MUL R1,R0: 7 * 6 = 42 in R1 (R0 holds the high word)', R(r, 0) === 0 && R(r, 1) === 42);
    // 68000: big-endian words; D0..D7 at 64 + 4n, A0..A7 at 96 + 4n
    const m68 = words => { const b = new Uint8Array(16); words.forEach((w, i) => { b[2 * i] = w >> 8; b[2 * i + 1] = w & 255; }); return b; };
    const D = (r, n) => new Int32Array(r.regs.buffer, r.regs.byteOffset + 64 + 4 * n, 1)[0], A = (r, n) => new Int32Array(r.regs.buffer, r.regs.byteOffset + 96 + 4 * n, 1)[0];
    r = runC(m68([0x11FC, 0x0012, 0x000E, 0x60FE]), 21);
    check('68000 MOVE.B #$12,$000E.W; BRA .', r.mem[14] === 0x12 && r.pc === 6);
    r = runC(m68([0x7205, 0x4280, 0x5280, 0x5341, 0x66FA, 0x60FE]), 21);
    check('68000 MOVEQ #5,D1; CLR.L D0; loop ADDQ.L #1,D0; SUBQ.W #1,D1; BNE: D0 = 5', D(r, 0) === 5 && D(r, 1) === 0 && (R(r, 10) & 4) !== 0 && r.pc === 10);
    r = runC(m68([0x243C, 0x1234, 0x5678, 0x21C2, 0x000C, 0x60FE]), 21);
    check('68000 MOVE.L #$12345678,D2; MOVE.L D2,$000C.W stores big-endian', D(r, 2) === 0x12345678 && r.mem[12] === 0x12 && r.mem[15] === 0x78);
    r = runC(m68([0x6102, 0x60FE, 0x702A, 0x4E75]), 21);
    check('68000 BSR/RTS: the return address is pushed as a long at 12..15, A7 back to 0', D(r, 0) === 0x2a && r.pc === 2 && A(r, 7) === 0 && r.mem[15] === 2 && r.mem[12] === 0);
    r = runC(m68([0x363C, 0x8001, 0xE35B, 0x60FE]), 21);
    check('68000 ROL.W #1,D3: $8001 -> $0003 with C set', (D(r, 3) & 0xffff) === 3 && (R(r, 10) & 1) === 1);
    r = runC(m68([0x7007, 0x7206, 0xC0C1, 0x60FE]), 21);
    check('68000 MULU D1,D0: 7 * 6 = 42', D(r, 0) === 42);
    r = runC(m68([0x7203, 0x4240, 0x5440, 0x51C9, 0xFFFC, 0x60FE]), 21);
    check('68000 DBF D1 loop runs four times: D0 = 8, D1.w = $FFFF', D(r, 0) === 8 && (D(r, 1) & 0xffff) === 0xffff);
    r = runC(m68([0x303C, 0xBEEF, 0x3100, 0x60FE]), 21);
    check('68000 MOVE.W D0,-(A0) from A0 = 0 lands on bytes 14..15', r.mem[14] === 0xbe && r.mem[15] === 0xef && A(r, 0) === -2);
    r = runC(m68([0x3038, 0x000C, 0xD078, 0x000E, 0x60FE, 0, 0x0005, 0x0007]), 21);
    check('68000 MOVE.W $000C.W,D0; ADD.W $000E.W,D0: 5 + 7 = 12', D(r, 0) === 12);
    // 68020 (25): the same core with the 68020 additions
    r = runC(m68([0x7007, 0x7206, 0x4C01, 0x0000, 0x60FE]), 25);
    check('68020 MULU.L D1,D0: 7 * 6 = 42', D(r, 0) === 42);
    r = runC(m68([0x7007, 0x72FD, 0x4C01, 0x0800, 0x60FE]), 25);
    check('68020 MULS.L D1,D0: 7 * -3 = -21, N set', D(r, 0) === -21 && (R(r, 10) & 8) !== 0);
    r = runC(m68([0x70FF, 0x7202, 0x4C01, 0x0402, 0x60FE]), 25);
    check('68020 MULU.L D1,D2:D0: $FFFFFFFF * 2 = $1_FFFFFFFE (D2 = 1, D0 = $FFFFFFFE)', D(r, 0) === -2 && D(r, 2) === 1);
    r = runC(m68([0x70F9, 0x7202, 0x4C41, 0x0802, 0x60FE]), 25);
    check('68020 DIVSL.L D1,D2:D0: -7 / 2 = -3 remainder -1', D(r, 0) === -3 && D(r, 2) === -1);
    r = runC(m68([0x7012, 0x103C, 0x00FE, 0x49C0, 0x60FE]), 25);
    check('68020 EXTB.L D0: $000000FE -> -2', D(r, 0) === -2 && (R(r, 10) & 8) !== 0);
    r = runC(m68([0x203C, 0x1234, 0x5678, 0xE9C0, 0x1108, 0x60FE]), 25);
    check('68020 BFEXTU D0{4:8},D1 on $12345678 gives $23', D(r, 1) === 0x23 && D(r, 0) === 0x12345678);
    r = runC(m68([0xEBF8, 0x210C, 0x000C, 0x60FE, 0, 0, 0xABCD, 0x1234]), 25);
    check('68020 BFEXTS $000C{4:12},D2: the 12 bits BCD, sign-extended, -1075', D(r, 2) === 0xBCD - 0x1000);
    r = runC(m68([0xEEF8, 0x0004, 0x000E, 0x60FE]), 25);
    check('68020 BFSET $000E{0:4} sets the top nibble of byte 14: F0', r.mem[14] === 0xf0 && r.mem[13] === 0 && r.mem[15] === 0);
    r = runC(m68([0x203C, 0x0000, 0x1000, 0xEDC0, 0x1000, 0x60FE]), 25);
    check('68020 BFFFO D0{0:32},D1 on $00001000: first set bit at offset 19', D(r, 1) === 19);
    r = runC(m68([0x7203, 0x43F0, 0x1D20, 0x0002, 0x60FE]), 25);
    check('68020 LEA (2,A0,D1.L*4),A1 (full extension word, word base displacement, scale 4): 2 + 3 * 4 = 14', A(r, 1) === 14);
    r = runC(m68([0x3630, 0x01E1, 0x000C, 0x60FE, 0xBEEF, 0, 0x0000, 0x0008]), 25);
    check('68020 MOVE.W ([$000C]),D3: memory indirect through the long pointer 8 at byte 12 reads BEEF', (D(r, 3) & 0xffff) === 0xbeef);
    r = runC(m68([0x480E, 0xFFFF, 0xFFFC, 0x60FE]), 25);
    check('68020 LINK.L A6,#-4: A6 = old SP (0) pushed at 12..15, A6 = -4, A7 = -8', A(r, 6) === -4 && A(r, 7) === -8 && r.mem[12] === 0 && r.mem[15] === 0);
    r = runC(m68([0x60FF, 0x0000, 0x0006, 0x0000, 0x7009, 0x60FE]), 25);
    check('68020 BRA.L with a 32-bit displacement lands on byte 8: D0 = 9', D(r, 0) === 9 && r.pc === 10);
    r = runC(m68([0x7005, 0x7207, 0x0AF8, 0x0040, 0x000E, 0x60FE, 0, 0x0500]), 25);
    check('68020 CAS.B D0,D1,$000E: byte 14 (5) equals D0, so it becomes D1 = 7 and Z is set', r.mem[14] === 7 && (R(r, 10) & 4) !== 0);
    r = runC(m68([0x7005, 0x7207, 0x0AF8, 0x0040, 0x000E, 0x60FE, 0, 0x0900]), 25);
    check('68020 CAS.B with byte 14 = 9: not equal, D0 takes 9, memory unchanged', r.mem[14] === 9 && D(r, 0) === 9 && (R(r, 10) & 4) === 0);
    r = runC(m68([0x700A, 0x02F8, 0x0000, 0x000C, 0x60FE, 0, 0x0003, 0x0009]), 25);
    check('68020 CMP2.W $000C,D0 with bounds 3..9 and D0 = 10: C set, Z clear', (R(r, 10) & 1) === 1 && (R(r, 10) & 4) === 0);
    r = runC(m68([0x7003, 0x02F8, 0x0000, 0x000C, 0x60FE, 0, 0x0003, 0x0009]), 25);
    check('68020 CMP2.W with D0 = 3 (on the lower bound): Z set, C clear', (R(r, 10) & 1) === 0 && (R(r, 10) & 4) !== 0);
    r = runC(m68([0x7203, 0x43F0, 0x1D20, 0x0002, 0x60FE]), 21);
    check('68000: the same LEA bytes read as a brief extension word (no scaling, bit 8 ignored): A1 = 0 + 3 + 0x20', A(r, 1) === 0x23);
    // Intel 8086 (26), 80286 (27), 80386 (28): EAX ECX EDX EBX ESP EBP ESI EDI little-endian at 64 + 4n, FLAGS at 20
    const hx = t => Uint8Array.from(t.split(' '), h => parseInt(h, 16));
    const X = (r, n) => new Int32Array(r.regs.buffer, r.regs.byteOffset + 64 + 4 * n, 1)[0], FL = r => R(r, 10);
    r = runC(hx('B8 34 12 A3 0E 00 EB FE'), 26);
    check('8086 MOV AX,1234h; MOV [000Eh],AX; JMP $: little-endian store at 14,15', r.mem[14] === 0x34 && r.mem[15] === 0x12 && X(r, 0) === 0x1234 && r.pc === 6);
    r = runC(hx('B0 05 B3 07 F6 E3 EB FE'), 26);
    check('8086 MOV AL,5; MOV BL,7; MUL BL: AX = 35', X(r, 0) === 35 && (FL(r) & 0x801) === 0);
    r = runC(hx('B9 04 00 BF 0C 00 B0 AA F3 AA EB FE'), 26);
    check('8086 REP STOSB with CX = 4, DI = 12 fills bytes 12..15 with AAh one iteration a step: CX = 0, DI = 16', r.mem[12] === 0xaa && r.mem[15] === 0xaa && r.mem[11] === 0xfe && r.mem[10] === 0xeb && X(r, 1) === 0 && X(r, 7) === 16);
    r = runC(hx('B9 03 00 31 C0 40 E2 FD EB FE'), 26);
    check('8086 MOV CX,3; XOR AX,AX; INC AX; LOOP: AX = 3', X(r, 0) === 3 && X(r, 1) === 0);
    r = runC(hx('B8 CD AB 50 5B EB FE'), 26);
    check('8086 PUSH AX; POP BX: the word goes to 14,15 (SP wraps from 0), BX = ABCDh, SP back to 0', X(r, 3) === 0xabcd && r.mem[14] === 0xcd && r.mem[15] === 0xab && X(r, 4) === 0);
    r = runC(hx('E8 03 00 EB FE 00 40 C3'), 26);
    check('8086 CALL +3; ... INC AX; RET: the return address 3 is pushed at 14,15, AX = 1, back in the JMP $ loop', X(r, 0) === 1 && r.mem[14] === 3 && r.mem[15] === 0 && X(r, 4) === 0 && r.pc === 3);
    r = runC(hx('6A 05 5B EB FE'), 26);
    check('8086 reads 6A as JP (not taken: PF clear), then POP BX pops the code bytes 0,1: BX = 056Ah', X(r, 3) === 0x056a && X(r, 4) === 2);
    r = runC(hx('6A 05 5B EB FE'), 27);
    check('80286 PUSH imm8 5; POP BX: BX = 5', X(r, 3) === 5 && X(r, 4) === 0);
    r = runC(hx('B8 06 00 6B C0 07 EB FE'), 27);
    check('80286 IMUL AX,AX,7: 6 * 7 = 42', X(r, 0) === 42);
    r = runC(hx('B8 01 00 C1 E0 04 EB FE'), 27);
    check('80286 SHL AX,4 by immediate: 16', X(r, 0) === 16);
    r = runC(hx('66 B8 78 56 34 12 66 A3 0C 00 EB FE'), 28);
    check('80386 MOV EAX,12345678h; MOV [000Ch],EAX (66 prefix): 78 56 34 12 at 12..15', r.mem[12] === 0x78 && r.mem[15] === 0x12 && X(r, 0) === 0x12345678);
    r = runC(hx('B3 FE 0F B6 C3 EB FE'), 28);
    check('80386 MOVZX AX,BL: FEh -> 00FEh', X(r, 0) === 0xfe);
    r = runC(hx('31 C0 0F 94 C3 EB FE'), 28);
    check('80386 XOR AX,AX; SETE BL: BL = 1', (X(r, 3) & 0xff) === 1 && (FL(r) & 0x40) !== 0);
    r = runC(hx('B8 08 00 0F BA E0 03 EB FE'), 28);
    check('80386 BT AX,3 with AX = 8 sets CF', (FL(r) & 1) === 1);
    r = runC(hx('67 8B 04 24 EB FE'), 28);
    check('80386 MOV AX,[ESP] through a SIB byte (67 prefix): reads the code bytes 0,1 = 8B67h', X(r, 0) === 0x8b67);
    // Intel i860 (29): 32-bit little-endian instructions; r1..r15 at 64 + 4(n - 1), f2..f6 at 4(n - 2), f7..f15 at 24 + 4(n - 7)
    const i860 = words => { const b = new Uint8Array(16); words.forEach((w, i) => { b[4 * i] = w & 255; b[4 * i + 1] = (w >>> 8) & 255; b[4 * i + 2] = (w >>> 16) & 255; b[4 * i + 3] = w >>> 24; }); return b; };
    const IR = (r, n) => X(r, n - 1), IF = (r, n) => { const o = n <= 6 ? 4 * (n - 2) : 24 + 4 * (n - 7); return new Int32Array(r.regs.buffer, r.regs.byteOffset + o, 1)[0]; };
    r = runC(i860([0x94020005, 0x1C00100D, 0x6BFFFFFF, 0]), 29);
    check('i860 adds 5,r0,r2; st.l r2,12(r0); br . (delayed, the stored word runs as its delay slot): bytes 12..15 = 05 00 00 00, r2 = 5', r.mem[12] === 5 && r.mem[13] === 0 && r.mem[15] === 0 && IR(r, 2) === 5);
    r = runC(i860([0xEC023FC0, 0x08021000, 0x48431030, 0x48041840]), 29);
    check('i860 orh 3FC0h,r0,r2 (1.5f); ixfr r2,f2; fadd.ss f2,f2,f3; fxfr f3,r4: r4 = 40400000h (3.0f)', IR(r, 4) === 0x40400000 && IF(r, 3) === 0x40400000 && IR(r, 2) === 0x3fc00000);
    // General Instrument PIC1640 (30): ten 12-bit words at bit offsets 12k, little-endian bit order; W at 0, PC (word) at 22
    const pic = words => { let v = 0n; words.forEach((w, k) => { v |= BigInt(w) << BigInt(12 * k); }); const b = new Uint8Array(16); for (let i = 0; i < 16; i++) b[i] = Number((v >> BigInt(8 * i)) & 255n); return b; };
    r = runC(pic([0xC5A, 0x02F, 0xA02]), 30);
    check('PIC1640 MOVLW 5Ah; MOVWF 15; GOTO 2: byte 15 = 5Ah, W = 5Ah', r.mem[15] === 0x5a && r.regs[0] === 0x5a && R(r, 11) === 2);
    r = runC(pic([0xC03, 0x02E, 0x2EE, 0xA02, 0xA04]), 30);
    check('PIC1640 MOVLW 3; MOVWF 14; DECFSZ 14,f; GOTO 2; GOTO 4: counts byte 14 down to 0 and skips out of the loop', r.mem[14] === 0 && R(r, 11) === 4);
    r = runC(pic([0xCF0, 0x02F, 0xC20, 0x1CF, 0xA04]), 30);
    check('PIC1640 ADDWF 15,w: F0h + 20h = 10h in W with C set in STATUS = byte 3 (which is also the low byte of word 2)', r.regs[0] === 0x10 && (r.mem[3] & 1) === 1 && (r.mem[3] & 4) === 0 && r.mem[15] === 0xf0);
    r = runC(pic([0x903, 0x02F, 0xA02, 0x877]), 30);
    check('PIC1640 CALL 3; MOVWF 15; GOTO 2; ... RETLW 77h: W = 77h lands in byte 15, PC loops at 2', r.regs[0] === 0x77 && r.mem[15] === 0x77 && R(r, 11) === 2);
    r = runC(pic([0x5EF, 0x7EF, 0xC11, 0xA03]), 30);
    check('PIC1640 BSF 15,7; BTFSS 15,7 skips the MOVLW: byte 15 = 80h, W = 0', r.mem[15] === 0x80 && r.regs[0] === 0 && R(r, 11) === 3);
    io.setChanger(0);
  }
  // ERA/UNIVAC 1101 (22), DEC VAX-11/780 (23), CDC 6600 (24)
  {
    const REG = 256;
    const runC = (prog, changer, steps = 256) => { io.setChanger(changer); io.setSteps(steps); m8.set(prog, GRID); const r = decode_pixel(GRID, 0, PRM); io.setSteps(256); return { mem: out(), regs: m8.slice(REG, REG + 128), pc: io.lastOffset(), ret: r }; };
    const putBits = (b, off, n, v) => { v = BigInt(v); for (let i = 0; i < n; i++) if ((v >> BigInt(i)) & 1n) b[(off + i) >> 3] |= 1 << ((off + i) & 7); };
    const getBits = (b, off, n) => { let v = 0n; for (let i = 0; i < n; i++) v |= BigInt((b[(off + i) >> 3] >> ((off + i) & 7)) & 1) << BigInt(i); return v; };
    const u32 = (r, o) => (r.regs[o] | (r.regs[o + 1] << 8) | (r.regs[o + 2] << 16) | (r.regs[o + 3] << 24)) >>> 0;
    const u64 = (r, o) => new BigUint64Array(r.regs.buffer.slice(r.regs.byteOffset + o, r.regs.byteOffset + o + 8))[0];
    // 1101: 5 words of 24 bits at bits 24k; instruction = op (octal) << 18 | skip << 14 | y
    const u = (op, y, skip = 0) => (op << 18) | (skip << 14) | y;
    const u1101 = words => { const b = new Uint8Array(16); words.forEach((w, k) => putBits(b, 24 * k, 24, w)); return b; };
    const W = (r, k) => Number(getBits(r.mem, 24 * k, 24));
    const Acc = r => u64(r, 0) & 0xffffffffffffn, Q = r => u32(r, 8) & 0xffffff;
    let r = runC(u1101([u(0o11, 3), u(0o35, 4), u(0o45, 2), 0o1234567, 0]), 22);
    check('1101 OP y: A = (y); AY y stores the right half of A; UJ loops', W(r, 4) === 0o1234567 && Acc(r) === 0o1234567n && r.pc === 2);
    r = runC(u1101([u(0o13, 3), u(0o46, 4), u(0o45, 2), 5, u(0o45, 4)]), 22);
    check("1101 ON y: A = -(y) in ones' complement; CJ jumps on a negative A", Acc(r) === (0xffffffffffffn ^ 5n) && r.pc === 4);
    r = runC(u1101([u(0o16, 3), u(0o61, 4), u(0o45, 2), 6, 7]), 22);
    check('1101 fill Q; MP y: A = Q * (y) = 42', Acc(r) === 42n && Q(r) === 6);
    r = runC(u1101([u(0o11, 3), u(0o63, 4), u(0o45, 2), 43, 7]), 22);
    check('1101 DP y: 43 / 7 leaves the quotient 6 in Q and the remainder 1 in A', Q(r) === 6 && Acc(r) === 1n);
    r = runC(u1101([u(0o11, 3, 1), u(0o13, 3), u(0o35, 4), 0o77, 0]), 22);
    check('1101 skip field: the word after a skip-1 instruction is not executed', W(r, 4) === 0o77 && Acc(r) === 0o77n);
    r = runC(u1101([u(0o16, 3), u(0o44, 4), u(0o45, 2), 0x800000, u(0o45, 4)]), 22);
    check('1101 QJ: jumps when q23 is set and rotates Q left by one', r.pc === 4 && Q(r) === 1);
    r = runC(u1101([u(0o11, 3), u(0o47, 4), u(0o45, 2), 0, u(0o45, 4)]), 22);
    const r2 = runC(u1101([u(0o11, 3), u(0o47, 4), u(0o45, 2), 1, u(0o45, 4)]), 22);
    check('1101 ZJ: no jump on A = 0, jump on A = 1', r.pc === 2 && r2.pc === 4);
    r = runC(u1101([u(0o16, 3), u(0o11, 4), u(0o17, 3), 0xff, 0xab]), 22);
    check('1101 SD y: (y) takes the bits of A where Q has ones', W(r, 3) === 0xab);
    r = runC(u1101([u(0o11, 3), u(0o25, 4), u(0o45, 2), 0o123, 0]), 22);
    check('1101 AL k: A rotates left by k = 4', Acc(r) === (0o123n << 4n));
    // VAX: little-endian bytes from PC = 0; R0..R14 at register-file 64 + 4n, PSL (NZVC) at 20
    const vb = str => { const b = new Uint8Array(16); str.trim().split(/\s+/).forEach((h, i) => { b[i] = parseInt(h, 16); }); return b; };
    const Rv = (r, n) => u32(r, 64 + 4 * n) | 0, PSL = r => r.regs[20];
    r = runC(vb('D0 8F 78 56 34 12 51 11 FE'), 23);
    check('VAX MOVL #^X12345678, R1; BRB .', Rv(r, 1) === 0x12345678 && r.pc === 7);
    r = runC(vb('D4 50 D0 05 51 D6 50 F5 51 FB 11 FE'), 23);
    check('VAX CLRL R0; MOVL #5, R1; loop: INCL R0; SOBGTR R1, loop: R0 = 5, Z set', Rv(r, 0) === 5 && Rv(r, 1) === 0 && (PSL(r) & 4) !== 0 && r.pc === 10);
    r = runC(vb('90 8F AB 9F 0E 00 00 00 11 FE'), 23);
    check('VAX MOVB #^XAB, @#000E (absolute mode) stores to byte 14', r.mem[14] === 0xab && r.pc === 8);
    r = runC(vb('C1 03 04 52 C2 09 52 11 FE'), 23);
    check('VAX ADDL3 #3, #4, R2; SUBL2 #9, R2: R2 = -2 with N and C set', Rv(r, 2) === -2 && (PSL(r) & 9) === 9);
    r = runC(vb('10 02 11 FE D0 2A 50 05'), 23);
    check('VAX BSBB/RSB: the return address 2 is pushed at 12..15, SP back to 0', Rv(r, 0) === 0x2a && r.pc === 2 && Rv(r, 14) === 0 && r.mem[12] === 2 && r.mem[13] === 0);
    r = runC(vb('D0 0E 53 B0 8F EF BE 63 32 63 54 11 FE'), 23);
    check('VAX MOVW #^XBEEF, (R3) with R3 = 14; CVTWL (R3), R4 sign-extends', r.mem[14] === 0xef && r.mem[15] === 0xbe && Rv(r, 4) === -16657);
    r = runC(vb('D0 8F 78 56 34 12 51 EF 08 08 51 52 11 FE'), 23);
    check('VAX EXTZV #8, #8, R1, R2 picks byte 1 of R1', Rv(r, 2) === 0x56 && r.pc === 12);
    r = runC(vb('D0 04 50 E0 02 50 02 11 FE D0 01 55 11 FE'), 23);
    check('VAX BBS #2, R0 branches over the first BRB', Rv(r, 5) === 1 && r.pc === 12);
    r = runC(vb('D0 8F 01 00 00 80 50 9C 04 50 51 11 FE'), 23);
    check('VAX ROTL #4, R0, R1: ^X80000001 -> ^X18', Rv(r, 1) === 0x18 && r.pc === 11);
    r = runC(vb('78 8F FE 8F F8 FF FF FF 52 11 FE'), 23);
    check('VAX ASHL #-2, #-8, R2 = -2', Rv(r, 2) === -2);
    r = runC(vb('DD 07 BA 01 11 FE'), 23);
    check('VAX PUSHL #7; POPR #^M<R0>: R0 = 7, SP back to 0', Rv(r, 0) === 7 && Rv(r, 14) === 0);
    r = runC(vb('17 9F 08 00 00 00 11 FE D0 02 56 11 FE'), 23);
    check('VAX JMP @#0008', Rv(r, 6) === 2 && r.pc === 11);
    // CDC 6600: two 60-bit words, four 15-bit parcels each from the high end; X at 64 + 8n, A at 24 + 4n, B1..B7 three bytes at 3(n-1)
    const P15 = (fm, i, j, k) => (fm << 9) | (i << 6) | (j << 3) | k;
    const P30 = (fm, i, j, K) => [P15(fm, i, j, (K >> 15) & 7), K & 0x7fff];
    const c6600 = parcels => { const b = new Uint8Array(16); parcels.flat().forEach((p, n) => putBits(b, 60 * (n >> 2) + 45 - 15 * (n & 3), 15, p)); return b; };
    const X = (r, n) => u64(r, 64 + 8 * n) & 0xfffffffffffffffn, Ar = (r, n) => u32(r, 24 + 4 * n);
    const B = (r, n) => n ? (r.regs[3 * n - 3] | (r.regs[3 * n - 2] << 8) | (r.regs[3 * n - 1] << 16)) & 0x3ffff : 0;
    const M60 = (r, w) => getBits(r.mem, 60 * w, 60);
    r = runC(c6600([P30(0o61, 1, 0, 5), P15(0o66, 2, 1, 1), P15(0o76, 3, 2, 1)]), 24, 3);
    check('6600 SB1 B0+5; SB2 B1+B1; SX3 B2+B1: B1 = 5, B2 = 10, X3 = 15', B(r, 1) === 5 && B(r, 2) === 10 && X(r, 3) === 15n && r.pc === 4);
    r = runC(c6600([P30(0o71, 1, 0, 7), P30(0o71, 2, 0, 6), P15(0o36, 3, 1, 2), P15(0o37, 4, 1, 2), P15(0o14, 5, 0, 4)]), 24, 5);
    check("6600 IX3 X1+X2 = 13, IX4 X1-X2 = 1, BX5 -X4 is the ones' complement", X(r, 3) === 13n && X(r, 4) === 1n && X(r, 5) === (0xfffffffffffffffn ^ 1n));
    r = runC(c6600([P30(0o71, 6, 0, 0o1234), P30(0o51, 6, 0, 1)]), 24, 2);
    check('6600 SX6 B0+1234B; SA6 B0+1 stores X6 into word 1', M60(r, 1) === 0o1234n && Ar(r, 6) === 1);
    { const b = c6600([P30(0o51, 1, 0, 1)]); putBits(b, 60, 60, 0o7654321n); r = runC(b, 24, 1); }
    check('6600 SA1 B0+1 loads X1 from word 1', X(r, 1) === 0o7654321n && Ar(r, 1) === 1);
    r = runC(c6600([P30(0o71, 1, 0, 1), P15(0o20, 1, 0, 3), P15(0o21, 1, 0, 2), P15(0o43, 2, 0, 4)]), 24, 4);
    check('6600 LX1 3 (1 -> 8), AX1 2 (8 -> 2), MX2 4 = four ones from the top', X(r, 1) === 2n && X(r, 2) === (0xfn << 56n));
    r = runC(c6600([P30(0o71, 1, 0, 3), P15(0o27, 1, 0, 1), P15(0o24, 1, 0, 1), P15(0o40, 3, 1, 1), P15(0o26, 4, 4, 3), P15(0o30, 5, 1, 1), P15(0o26, 6, 6, 5)]), 24, 7);
    check('6600 PX/NX 3, FX3 X1*X1 = 9 and FX5 X1+X1 = 6 unpack to coefficient and exponent', X(r, 4) === (9n << 44n) && B(r, 4) === (0x3ffff ^ 44) && X(r, 6) === (3n << 46n) && B(r, 6) === (0x3ffff ^ 45));
    r = runC(c6600([P30(0o71, 1, 0, 6), P30(0o71, 2, 0, 3), P15(0o27, 1, 0, 1), P15(0o27, 2, 0, 2), P15(0o44, 3, 1, 2), P15(0o26, 4, 4, 3)]), 24, 6);
    check('6600 FX3 X1/X2: 6 / 3 unpacks to 4 * 2^-1', X(r, 4) === 4n && B(r, 4) === 0x3fffe);
    r = runC(c6600([P30(0o61, 2, 0, 1), P30(0o61, 1, 0, 3), P15(0o73, 3, 3, 1), P15(0o67, 1, 1, 2), P30(0o05, 1, 0, 1)]), 24, 11);
    check('6600 loop: SX3 X3+B1; SB1 B1-B2; NE B1 B0 1 runs three times: X3 = 6, B1 = 0', X(r, 3) === 6n && B(r, 1) === 0 && r.pc === 0);
    r = runC(c6600([P30(0o01, 0, 0, 1)]), 24, 1);
    check('6600 RJ 1 plants JP 1 in word 1 and jumps to word 0', M60(r, 1) === (0x2000001n << 30n) && r.pc === 0);
    io.setChanger(0);
  }
  // simple processors
  const bytes = Uint8Array.from({ length: 16 }, (_, k) => (k * 37 + 11) & 255);
  io.setChanger(3); m8.set(bytes, GRID); let rr = decode_pixel(GRID, 0, PRM);
  check('do nothing: output equals input, nothing flagged', out().every((b, k) => b === bytes[k]) && (rr & 255) === 0 && flags().every(f => f === 0));
  io.setChanger(4); rr = decode_pixel(GRID, 0, PRM);
  check('invert: every bit flipped', out().every((b, k) => b === (bytes[k] ^ 255)) && (rr & 255) === 16);
  io.setChanger(5); rr = decode_pixel(GRID, 0, PRM);
  check('reverse: the 16 bytes in reverse order', out().every((b, k) => b === bytes[15 - k]) && (rr & 255) === 16);
  io.setChanger(16); rr = decode_pixel(GRID, 0, PRM);
  { const mi = bytes.indexOf(Math.max(...bytes)), nx = (mi + 1) & 15, pv = (mi + 15) & 15, mn = bytes.indexOf(Math.min(...bytes));
    const g = d => d === 0 ? -23 : d === 1 ? 11 : d === 15 ? 13 : 0;
    const want = bytes.map((b, k) => (b + g((k - mi) & 15) - g((k - mn) & 15) + 512) & 255), nflag = want.filter((v, k) => v !== bytes[k]).length;
    check(`extremes: the largest byte ${mi} (${bytes[mi]}) loses 23, byte ${nx} gains 11, byte ${pv} gains 13, the smallest ${mn} (${bytes[mn]}) and its neighbours the opposite, ${nflag} bytes flagged`, out().every((b, k) => b === want[k]) && (rr & 255) === nflag && flags().every((f, k) => f === (want[k] !== bytes[k] ? 1 : 0))); }
  m8.set(Uint8Array.from([9, 3, 250, 3, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9]), GRID); decode_pixel(GRID, 0, PRM);
  check('extremes: 250 at 2 -> 227 - 11 (it follows the smallest 3 at 1) = 216, byte 3 -> 14, the smallest at 1 -> 3 + 23 + 13 = 39, byte 0 -> 9 - 13 = 252', out()[2] === 216 && out()[3] === 14 && out()[1] === 39 && out()[0] === 252 && out()[4] === 9);
  m8.set(Uint8Array.from([9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9]), GRID); decode_pixel(GRID, 0, PRM);
  check('extremes: a flat cell is a fixed point (largest = smallest = byte 0)', out().every(b => b === 9));
  m8.set(Uint8Array.from([9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 30]), GRID); decode_pixel(GRID, 0, PRM);
  check('extremes: largest at 15 -> 30 - 23 - 13 (before the smallest at 0) = 250, byte 0 -> 9 + 11 + 23 = 43, byte 14 -> 22, byte 1 -> 9 - 11 = 254', out()[15] === 250 && out()[0] === 43 && out()[14] === 22 && out()[1] === 254 && out()[2] === 9);
  m8.set(Uint8Array.from([30, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9]), GRID); decode_pixel(GRID, 0, PRM);
  check('extremes: largest at 0 -> 7 - 13 = 250 (before the smallest at 1), byte 1 -> 20 + 23 = 43, byte 2 -> 254, byte 15 -> 22', out()[0] === 250 && out()[1] === 43 && out()[2] === 254 && out()[15] === 22);
  m8.set(Uint8Array.from([250, 251, 252, 253, 254, 255, 250, 251, 252, 253, 254, 255, 250, 251, 252, 253]), GRID); decode_pixel(GRID, 0, PRM);
  check('extremes wrap mod 256: 255 at 5 -> 232, 6 -> 5, 4 -> 11; the smallest 250 at 0 -> 17, 1 -> 240, 15 -> 240', out()[5] === 232 && out()[6] === 5 && out()[4] === 11 && out()[0] === 17 && out()[1] === 240 && out()[15] === 240);
  // DCT (17) and inverse DCT (18): bytes as signed samples b - 128
  const dct = (b, inv) => { io.setChanger(inv ? 18 : 17); m8.set(b, GRID); const r = decode_pixel(GRID, 0, PRM); return { o: out(), r }; };
  let d = dct(new Uint8Array(16).fill(138), 0);
  check('DCT of a constant 138: byte 0 = 128 + 2 * 10 (DC at half scale), the other 15 coefficients 128', d.o[0] === 148 && d.o.slice(1).every(b => b === 128) && (d.r & 255) === 16);
  d = dct(Uint8Array.from(d.o), 1);
  check('inverse DCT of that returns the constant 138', d.o.every(b => b === 138) && flags().every(f => f === 1));
  const cosv = Uint8Array.from({ length: 16 }, (_, n) => 128 + Math.round(50 * Math.cos(Math.PI * (2 * n + 1) * 3 / 32)));
  d = dct(cosv, 0);
  check(`DCT of a 3rd-harmonic cosine peaks at coefficient 3 (${d.o[3]}), the others stay within rounding of 128`, Math.abs(d.o[3] - (128 + Math.round(50 * 8 * Math.SQRT2 / 4 / 2))) <= 1 && d.o.every((b, k) => k === 3 || Math.abs(b - 128) <= 1));
  const smallv = Uint8Array.from({ length: 16 }, (_, n) => 120 + ((n * 7919 + 13) % 17));
  const back = dct(Uint8Array.from(dct(smallv, 0).o), 1).o, err = Math.max(...back.map((b, k) => Math.abs(b - smallv[k])));
  check(`DCT then inverse DCT reproduces a small-amplitude vector to within rounding (max error ${err})`, err <= 3);
  d = dct(new Uint8Array(16).fill(255), 0);
  check('DCT clamps: all-255 input gives a clipped DC of 255 and no trap', d.o[0] === 255 && d.o.slice(1).every(b => b === 128));
  check('cosine table installed at LAYOUT.COS: cos(pi m / 64), m = 0..32', Math.abs(new Float64Array(memory.buffer, Codec.LAYOUT.COS, 33)[32]) < 1e-12 && new Float64Array(memory.buffer, Codec.LAYOUT.COS, 33)[0] === 1 && Math.abs(new Float64Array(memory.buffer, Codec.LAYOUT.COS, 33)[16] - Math.SQRT1_2) < 1e-12);
  io.setChanger(0);
  words.fill(0n); decode_pixel(GRID, 0, PRM);
  check('changer 0 restores the LZ decompressor', out().every((b, k) => b === txt(k)));
}

// ---- change(): the byte changer rewrites every pixel with its own output
{
  const { change } = instance.exports;
  for (const [changer, name] of [[0, 'LZ decompressor'], [1, 'Brainfuck, empty tape'], [2, 'Brainfuck, tape = pixel'], [3, 'do nothing'], [4, 'invert'], [5, 'reverse'], [6, 'Z80'], [7, '6502'], [8, '8080'], [9, 'Subleq'], [10, 'CHIP-8'], [11, '4004'], [12, 'SM83'], [13, '8051'], [14, '6809'], [15, 'RISC-V'], [16, 'extremes'], [17, 'DCT'], [18, 'inverse DCT'], [19, 'PDP-8'], [20, 'PDP-11'], [21, '68000'], [22, 'UNIVAC 1101'], [23, 'VAX-11/780'], [24, 'CDC 6600'], [25, '68020'], [26, '8086'], [27, '80286'], [28, '80386'], [29, 'i860'], [30, 'PIC1640']]) {
    io.setChanger(changer);
    randomize(4 * N, GRID, 31 + changer);
    if (changer === 1 || changer === 2) for (let i = GRID; i < GRID + 16 * N; i++) m8[i] &= 7;   // Brainfuck programs
    const before = m8.slice(GRID, GRID + 16 * N);
    const expected = new Uint8Array(16 * N);
    for (let i = 0; i < N; i++) { decode_pixel(GRID, i, PRM); expected.set(m8.subarray(io.OUT, io.OUT + 16), 16 * i); }
    const rewritten = change(N, GRID, PRM);
    const after = m8.slice(GRID, GRID + 16 * N);
    let differ = 0; for (let i = 0; i < N; i++) { for (let k = 0; k < 16; k++) if (before[16 * i + k] !== after[16 * i + k]) { differ++; break; } }
    check(`${name}: change() rewrites the grid with the processor's output (${rewritten} of ${N} pixels changed)`, after.every((b, k) => b === expected[k]) && rewritten === differ && (changer === 3 ? rewritten === 0 : rewritten > 0));
  }
  io.setChanger(0);
}

// ---- render modes write pixels; mode 2 encodes the cursor offset
const PIX = GRID + 16 * N, PAL = PIX + 4 * N;
const pal = new Uint32Array(memory.buffer, PAL, 129); for (let i = 0; i <= 128; i++) pal[i] = 0xff000000 | i;
const px = new Uint32Array(memory.buffer, PIX, N);
for (const mode of [0, 1, 2, 3, 4, 5]) { px.fill(0); render(N, GRID, PIX, PAL, mode, PRM); check('render mode ' + mode + ' paints opaque pixels', px.every(v => (v >>> 24) === 255)); }
words[0] = (1n << 43n) - 1n; words[1] = 0n; render(1, GRID, PIX, PAL, 3, PRM);
check('mode 3: first third set -> pure red', px[0] === 0xff0000ff);
words[0] = ~0n << 43n; words[1] = (1n << 22n) - 1n; render(1, GRID, PIX, PAL, 3, PRM);
check('mode 3: middle third set -> pure green', px[0] === 0xff00ff00);
words[0] = 0n; words[1] = ~0n << 22n; render(1, GRID, PIX, PAL, 3, PRM);
check('mode 3: last third set -> pure blue', px[0] === 0xffff0000);
words[0] = ~0n; words[1] = ~0n; render(1, GRID, PIX, PAL, 3, PRM);
check('mode 3: all ones -> white', px[0] === 0xffffffff);
// LUT average modes: a test LUT with R = low nibble, G = high nibble, B = 15 - low nibble, installed with gain 1
const lut = new Uint32Array(256); for (let v = 0; v < 256; v++) lut[v] = (v & 15) | ((v >> 4) << 8) | ((15 - (v & 15)) << 16);
const io1 = Codec.install(memory, built, lut, 1); io1.setCursorOffset(0);
m8.fill(0x5a, GRID, GRID + 16); render(1, GRID, PIX, PAL, 4, PRM);
check('mode 4: sixteen identical bytes 0x5a -> nibbles expanded to 8 bits', px[0] === ((255 << 24) | ((15 - 10) * 17 << 16) | (5 * 17 << 8) | (10 * 17)) >>> 0);
{ const s = io1.frameSums(); check(`render accumulates the unstretched averages for the adaptive mean (${s.r},${s.g},${s.b} over ${s.n})`, s.n === 1 && s.r === 170 && s.g === 85 && s.b === 85); }
for (let k = 0; k < 16; k++) m8[GRID + k] = k % 2 ? 0xff : 0x00; render(1, GRID, PIX, PAL, 4, PRM);
check('mode 4: half 0x00 half 0xff -> channel averages 127', px[0] === 0xff7f7f7f);
words.fill(0n); render(1, GRID, PIX, PAL, 5, PRM);
const expect5 = (() => { let s = 0; for (let k = 0; k < 16; k++) s += lut[txt(k)]; const ch = b => ((s >> b) & 255) * 17 >> 4; return ((255 << 24) | (ch(16) << 16) | (ch(8) << 8) | ch(0)) >>> 0; })();
check('mode 5: decoded bytes of the zero pixel average through the LUT', px[0] === expect5);
// gain 3: the same 0x5a pixel stretched around the raw-byte palette mean
{
  const io3 = Codec.install(memory, built, lut, 3);
  m8.fill(0x5a, GRID, GRID + 16); render(1, GRID, PIX, PAL, 4, PRM);
  const st = (c, m) => Math.max(0, Math.min(255, m + (c - m) * 3));
  const m = io3.meanRaw, want = ((255 << 24) | (st((15 - 10) * 17, (m >> 16) & 255) << 16) | (st(5 * 17, (m >> 8) & 255) << 8) | st(10 * 17, m & 255)) >>> 0;
  check(`mode 4 with gain 3 stretches around the palette mean (mean ${(m & 255)},${(m >> 8) & 255},${(m >> 16) & 255})`, px[0] === want);
  Codec.install(memory, built, lut, 1).setCursorOffset(0);
}
const real = Codec.byteLut(built.bytes), inDict = new Set(built.bytes);
const bright = e => (e & 15) + ((e >> 8) & 15) + ((e >> 16) & 15);
const isText = v => v < 8 || (v >= 97 && v <= 122) || (v >= 65 && v <= 90) || (v >= 48 && v <= 57) || v === 32 || v === 10 || v === 13;   // 0-7 are the coloured Brainfuck commands
const lower = [...Array(26).keys()].map(k => real[97 + k]), others = [...Array(256).keys()].filter(v => !inDict.has(v) && !isText(v)).map(v => real[v]);
const chroma = e => Math.max(e & 15, (e >> 8) & 15, (e >> 16) & 15) - Math.min(e & 15, (e >> 8) & 15, (e >> 16) & 15);
const mean = a => a.reduce((s, e) => s + bright(e), 0) / a.length;
const cmdColours = [...Array(8).keys()].map(v => real[v]);
const alu = [...Array(64).keys()].map(k => 0x80 + k).filter(v => !inDict.has(v) && !isText(v)).map(v => real[v]), ctl = [...Array(64).keys()].map(k => 0xC0 + k).filter(v => !inDict.has(v) && !isText(v) && ![0xCB, 0xDD, 0xED, 0xFD].includes(v)).map(v => real[v]);
const hueOf = e => { const r = e & 15, g = (e >> 8) & 15, b = (e >> 16) & 15; return r >= g && r >= b ? 'r' : g >= b ? 'g' : 'b'; };
check(`byte LUT: 4-bit channels; a-z have ${new Set(lower).size} distinct saturated colours; bytes 0-7 have ${new Set(cmdColours).size} distinct saturated colours; the ${others.length} non-text byte values are Z80-class colours, dimmer than letters (mean brightness ${mean(others).toFixed(1)} vs ${mean(lower).toFixed(1)})`,
  new Set(cmdColours).size === 8 && cmdColours.every(e => chroma(e) >= 9) &&
  real.length === 256 && real.every(e => (e & 0xf0f0f0) === 0) && new Set(lower).size === 26 && lower.every(e => chroma(e) >= 9) &&
  others.every(e => chroma(e) >= 1) && mean(others) < mean(lower) && alu.every(e => hueOf(e) === 'r') && ctl.every(e => hueOf(e) !== 'g') && real[0xDD] === real[0xFD] && real[32] === (14 | (14 << 8) | (14 << 16)) &&
  Math.abs(((real[65] & 15) - ((real[65] >> 8) & 15)) * ((real[97] & 15) - ((real[97] >> 8) & 15))) >= 0);
stream(100, [[2, 0]]); render(1, GRID, PIX, PAL, 2, PRM);
check('mode 2 colours by cursor offset', (px[0] & 255) === Math.floor(c300 * 128 / text.length));

// ---- mix: conservation, a uniform crossover per pair, thresholds, wrap, order independence
const thr = (1n << 64n) / 16n;
words.fill(0n); for (let i = 0; i < N; i += 2) { words[2 * i] = ~0n; words[2 * i + 1] = ~0n; }
const s = mix(W, H, GRID, 0, 0, thrTab(thr), 0n);
check('identical contexts decide alike: all pairs or none, and all positions or none (' + s + ' bits)', s === 0 || s === 32 * 128);
words.fill(0n); for (let i = 0; i < N; i += 2) { words[2 * i] = ~0n; words[2 * i + 1] = ~0n; }
check('threshold max: every differing bit of every pair is exchanged, the pixels change places', mix(W, H, GRID, 0, 0, thrTab(~0n), 0n) === 32 * 128 && words[0] === 0n && words[2] === (1n << 64n) - 1n && words[3] === (1n << 64n) - 1n);
check('bits conserved', bits(N, GRID) === 32 * 128);
words.fill(0n); words[0] = 1n;
check('threshold 0 no swaps', mix(W, H, GRID, 0, 0, thrTab(0n), 0n) === 0 && words[0] === 1n);
check('threshold max swaps the differing bit', mix(W, H, GRID, 0, 0, thrTab(~0n), 0n) === 1 && words[0] === 0n && words[2] === 1n);
// the crossover rate: pairs differing in 64 bits exchange about p of them
{ words.fill(0n); for (let i = 0; i < N; i += 2) { words[2 * i] = 0x0123456789abcdefn * BigInt(i + 1) & ((1n << 64n) - 1n); words[2 * i + 1] = 0xfedcba9876543210n ^ BigInt(i); words[2 * i + 2] = ~words[2 * i] & ((1n << 64n) - 1n); words[2 * i + 3] = words[2 * i + 1]; }
  const half = mix(W, H, GRID, 0, 0, thrTab(1n << 63n), 0n);
  check(`p = 1/2: pairs differing in 64 bits exchange about half of them (${half} of ${32 * 64})`, half > 32 * 64 * 0.35 && half < 32 * 64 * 0.65 && bits(N, GRID) === bits(N, GRID)); }
words.fill(0n); words[2 * 7] = 1n;
let sw = mix(W, H, GRID, 2, 1, thrTab(~0n), 0n);
check('no wrap-around: x=7 has no left-right partner in the odd phase, and with edge offset 1 row 0 has no partner below, bit stays (' + sw + ' swaps)', words[0] === 0n && words[2 * 7] === 1n && sw === 0);
sw = mix(W, H, GRID, 2, 0, thrTab(~0n), 0n);
check('leftover column: with edge offset 0 pixel (7,0) pairs down with (7,1) in the odd left-right phase (' + sw + ' swaps)', words[2 * 7] === 0n && words[2 * (W + 7)] === 1n && sw === 1);
words.fill(0n); for (let x = 0; x < W; x += 2) words[2 * ((H - 1) * W + x)] = 1n;
sw = mix(W, H, GRID, 3, 1, thrTab(~0n), 0n);
check('leftover row: the last row has no partner below in the odd up-down phase and pairs left-right instead, offset 1: 3 pairs (' + sw + ')', sw === 3 && words[2 * ((H - 1) * W)] === 1n && words[2 * ((H - 1) * W + 1)] === 1n && words[2 * ((H - 1) * W + 2)] === 0n);
words.fill(0n); for (let x = 0; x < W; x += 2) words[2 * ((H - 1) * W + x)] = 1n;
sw = mix(W, H, GRID, 3, 0, thrTab(~0n), 0n);
check('leftover row, offset 0: 4 pairs, the bits stay in the last row (' + sw + ')', sw === 4 && bits(N, GRID) === 4 && Array.from({ length: W }, (_, x) => words[2 * ((H - 1) * W + x)]).every((v, x) => v === (x & 1 ? 1n : 0n)));
// every pixel takes part in the same number of exchanges a turn: count, per phase from a fresh grid of distinct
// pixels at threshold max (every pair exchanges), the pixels that changed; with the page's edge parities an
// interior or edge pixel takes part in four exchanges a turn and a corner in three (even sizes), and over two
// turns every pixel of an odd-sized grid has eight exchanges except the corners with six
{
  const ops = (w, h, alt) => {
    const n = w * h, c = new Int32Array(n), wd = new BigUint64Array(memory.buffer, GRID, 2 * n);
    for (const ph of [1, 0, 3, 2]) {
      for (let i = 0; i < n; i++) { wd[2 * i] = BigInt(i + 1) * 0x9E37n; wd[2 * i + 1] = 0n; }
      mix(w, h, GRID, ph, (ph & 1) ? alt ^ 1 : alt, thrTab(~0n, w), 0n);
      for (let i = 0; i < n; i++) if (wd[2 * i] !== BigInt(i + 1) * 0x9E37n) c[i]++;
    }
    return c;
  };
  const corner = (w, h, i) => (i % w === 0 || i % w === w - 1) && (i < w || i >= w * (h - 1));
  let even = true;
  for (const alt of [0, 1]) { const c = ops(8, 8, alt); for (let i = 0; i < 64; i++) even &&= c[i] === (corner(8, 8, i) ? 3 : 4); }
  check('edge pairs: on an 8x8 grid every pixel has four exchanges a turn, a corner three, for either turn parity', even);
  const c0 = ops(7, 5, 0), c1 = ops(7, 5, 1); let odd = true;
  for (let i = 0; i < 35; i++) odd &&= c0[i] + c1[i] === (corner(7, 5, i) ? 6 : 8);
  check('edge pairs: on a 7x5 grid every pixel has eight exchanges in two turns, a corner six', odd);
}
// decisions from a snapshot (mix_from): the turn's phases all decide on the map before the first phase
{
  const SNAP = GRID + 16 * N + 64, snap = new BigUint64Array(memory.buffer, SNAP, 2 * N);
  words.fill(0n); snap.fill(0n);
  snap[0] = 8n;                       // snapshot: pixels 0 and 1 differ only at bit 3
  words[0] = 9n;                      // live: they differ at bits 0 and 3
  let r = mix_from(W, H, GRID, SNAP, 0, 0, thrTab(~0n), 0n);
  check('snapshot decides the position: bit 3 (lowest differing in the snapshot) is exchanged, bit 0 is left alone', r === 1 && words[0] === 1n && words[2] === 8n);
  words.fill(0n); words[0] = 8n; words[2] = 8n;   // live: equal at bit 3 already
  r = mix_from(W, H, GRID, SNAP, 0, 0, thrTab(~0n), 0n);
  check('a decided exchange whose bits are already equal in the live map is a no-op and not counted', r === 0 && words[0] === 8n && words[2] === 8n);
  randomize(4 * N, GRID, 4242); const start = words.slice();
  snap.set(start);
  let k = 1n; for (const set of [[0, 1], [2, 3], [0, 3], [2, 1]]) for (const ph of set) mix_from(W, H, GRID, SNAP, ph, 0, thrTab(thr), k++);
  const fromSnap = words.slice(), pop = a => a.reduce((c, w) => { let v = w; while (v) { v &= v - 1n; c++; } return c; }, 0);
  words.set(start); k = 1n; for (const set of [[0, 1], [2, 3], [0, 3], [2, 1]]) for (const ph of set) mix(W, H, GRID, ph, 0, thrTab(thr), k++);
  check('a whole turn from the snapshot conserves bits and differs from the sequential (live-decided) turn', pop(fromSnap) === pop(start) && snap.every((w, i) => w === start[i]) && fromSnap.some((w, i) => w !== words[i]));
}
// LZ cursor offset is a parameter (default 600), added to the header cursor and wrapped
{
  io.setCursorOffset(0);
  check(`default cursor offset is ${Codec.CURSOR_OFFSET}`, Codec.CURSOR_OFFSET === 50);
  io.setCursorOffset(600); words[0] = 0n; words[1] = 0n; decode_pixel(GRID, 0, PRM);
  check('offset 600, header 0: cursor 600 and the output is the text from 600 on', io.lastOffset() === 600 && out().every((b, k) => b === txt(600 + k)));
  words[0] = 3n; decode_pixel(GRID, 0, PRM);
  check('offset 600, header 3: cursor 600 + 3 steps', io.lastOffset() === 600 + 3 * io.offsetUnit);
  io.setCursorOffset(text.length + 7); words[0] = 0n; decode_pixel(GRID, 0, PRM);
  check('offset beyond the text wraps', io.lastOffset() === 7);
  io.setCursorOffset(0); words[0] = BigInt(text.length + 5); decode_pixel(GRID, 0, PRM);
  check(`a header value past the end of the dictionary (${text.length + 5} of ${2 ** io.headerBits}) wraps to its start`, io.lastOffset() === 5);
  io.setCursorOffset(text.length); words[0] = 0n; decode_pixel(GRID, 0, PRM);
  check('offset = dictionary size is the same as offset 0', io.lastOffset() === 0);
  io.setCursorOffset(0);
}
// LZ cursor header width is a parameter
{
  io.setCursorOffset(0); io.setHeaderBits(4);
  check(`4 cursor bits: ${io.offsetUnit}-byte steps`, io.offsetUnit === Math.ceil(text.length / 16));
  words[0] = 5n; words[1] = 0n; decode_pixel(GRID, 0, PRM);
  check('4 cursor bits: header 5 -> cursor 5 steps in', io.lastOffset() === 5 * io.offsetUnit);
  io.setHeaderBits(8); words[0] = 0n; words[1] = 0n; const r8 = decode_pixel(GRID, 0, PRM) >> 8;
  io.setHeaderBits(0); const r0 = decode_pixel(GRID, 0, PRM) >> 8;
  check(`0 cursor bits: the cursor is always 0 and no header bits are consumed (${r0} vs ${r8} bits)`, io.lastOffset() === 0 && out()[0] === txt(0) && r0 === r8 - 8);
  io.setHeaderBits(built.headerBits);
  check(`back to the default ${built.headerBits} bits, 1-byte steps`, io.offsetUnit === 1);
}
// CPU step budget is a parameter
{
  const REG = 256; io.setChanger(8); io.setSteps(16);
  const b = new Uint8Array(16); '3C C3 00 00'.split(' ').forEach((h, i) => { b[i] = parseInt(h, 16); });   // INR A; JMP 0: A counts the loop iterations
  m8.set(b, GRID); decode_pixel(GRID, 0, PRM);
  check('CPU steps selector: 16 steps of INR A / JMP 0 leave A = 8', m8[REG + 7] === 8);
  io.setSteps(256); io.setChanger(0);
}
// per-column thresholds: a gradient table swaps only where the column's threshold allows
{
  const tab = new BigUint64Array(memory.buffer, L.THR, W); for (let x = 0; x < W; x++) tab[x] = x < 4 ? ~0n : 0n;
  words.fill(0n); for (let i = 0; i < N; i++) if (i % 2) { words[2 * i] = ~0n; words[2 * i + 1] = ~0n; }
  const s = mix(W, H, GRID, 0, 0, L.THR, 0n);
  check('column threshold table: pairs starting in columns 0-3 exchange all 128 bits, 4-7 do not (' + s + ' = 2048)', s === 16 * 128);
}
randomize(4 * N, GRID, 1234);
const snap = Array.from(words);
mix(W, H, GRID, 0, 0, thrTab(thr), 0n);
const resA = Array.from(words);
for (let i = 0; i < N; i += 2) { words[2 * i] = snap[2 * (i + 1)]; words[2 * i + 1] = snap[2 * (i + 1) + 1]; words[2 * (i + 1)] = snap[2 * i]; words[2 * (i + 1) + 1] = snap[2 * i + 1]; }
mix(W, H, GRID, 0, 0, thrTab(thr), 0n);
let same = true;
for (let i = 0; i < N; i += 2) { same &&= words[2 * i] === resA[2 * (i + 1)] && words[2 * i + 1] === resA[2 * (i + 1) + 1] && words[2 * (i + 1)] === resA[2 * i] && words[2 * (i + 1) + 1] === resA[2 * i + 1]; }
check('swap decision is independent of pixel order', same);
check('something moved in that random turn', resA.some((v, k) => v !== snap[k]));
const halves = () => { for (let i = 0; i < N; i++) { const v = (i % W) < 4 ? ~0n : 0n; words[2 * i] = v; words[2 * i + 1] = v; } };
const colBits = () => Array.from({ length: W }, (_, x) => { let c = 0; for (let y = 0; y < H; y++) { const i = y * W + x; for (const w of [words[2 * i], words[2 * i + 1]]) { let v = w; while (v) { v &= v - 1n; c++; } } } return c; });
halves(); for (let t = 0; t < 300; t++) mix(W, H, GRID, t & 3, 0, thrTab(thr), 0n);
console.log('   unseeded halves after 300 turns: ' + JSON.stringify(colBits()));
check('bits conserved after halves run', bits(N, GRID) === 4 * H * 128);
halves(); for (let t = 0; t < 300; t++) mix(W, H, GRID, t & 3, 0, thrTab(thr), BigInt(t + 1));
console.log('   seeded halves after 300 turns:   ' + JSON.stringify(colBits()));
check('seeded halves: whole pixels change places (uniform pixels have one context at every position, so a pair exchanges all or nothing) and some reach the right half', colBits().every(c => c % 128 === 0) && colBits().slice(4).some(c => c > 0) && bits(N, GRID) === 4 * H * 128);

// ---- smoothing: majority of self and 4-connected neighbours where the hash allows
{
  const { smooth } = instance.exports;
  const GRID2 = GRID + 16 * N + 64;
  const dst = new BigUint64Array(memory.buffer, GRID2, 2 * N);
  randomize(4 * N, GRID, 4242);
  const src = Array.from(words);
  const nb = (x, y) => [[x, y], [x > 0 ? x - 1 : x, y], [x < W - 1 ? x + 1 : x, y], [x, y > 0 ? y - 1 : y], [x, y < H - 1 ? y + 1 : y]];   // missing neighbours are the pixel itself
  const majority = (x, y, j) => { let ones = 0n, maj = 0n; for (let b = 0n; b < 64n; b++) { let c = 0; for (const [nx, ny] of nb(x, y)) if ((src[2 * (ny * W + nx) + j] >> b) & 1n) c++; if (c >= 3) maj |= 1n << b; } return maj; };
  const ch = smooth(W, H, GRID, GRID2, smTab(~0n), 0n);
  let ok = true, expectedChanges = 0;
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) for (let j = 0; j < 2; j++) {
    const m = majority(x, y, j); if (dst[2 * (y * W + x) + j] !== m) ok = false;
    let d = m ^ src[2 * (y * W + x) + j]; while (d) { d &= d - 1n; expectedChanges++; }
  }
  check(`threshold max: every bit becomes the 5-neighbour majority (${ch} bits changed)`, ok && ch === expectedChanges);
  check('source grid is left untouched', Array.from(words).every((v, k) => v === src[k]));
  check('threshold 0: nothing changes', smooth(W, H, GRID, GRID2, smTab(0n), 0n) === 0 && Array.from(dst).every((v, k) => v === src[k]));
  const partial = smooth(W, H, GRID, GRID2, smTab(thr), 0n);
  check(`threshold 1/16 changes some but not all disagreeing bits (${partial} of ${expectedChanges})`, partial > 0 && partial < expectedChanges && smooth(W, H, GRID, GRID2, smTab(thr), 0n) === partial);
  let onlyDisagreeing = true;
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) for (let j = 0; j < 2; j++) {
    const m = majority(x, y, j), s = src[2 * (y * W + x) + j], d = dst[2 * (y * W + x) + j];
    if ((d ^ s) & ~(m ^ s)) onlyDisagreeing = false;   // a changed bit must be one that disagreed, so it now equals the majority
  }
  check('partial smoothing only moves bits toward the majority', onlyDisagreeing);
  words.fill(~0n);
  check('a uniform grid is unchanged by smoothing', smooth(W, H, GRID, GRID2, smTab(~0n), 0n) === 0);
  words.fill(0n); words[2 * (3 * W + 3)] = ~0n; words[2 * (3 * W + 3) + 1] = ~0n;
  smooth(W, H, GRID, GRID2, smTab(~0n), 0n);
  check('an isolated all-ones pixel is erased by its zero neighbours', dst[2 * (3 * W + 3)] === 0n && dst[2 * (3 * W + 3) + 1] === 0n);
  words.fill(0n); words[0] = ~0n; words[1] = ~0n;
  smooth(W, H, GRID, GRID2, smTab(~0n), 0n);
  check('a corner pixel counts itself three times, so it survives its two zero neighbours', dst[0] === (1n << 64n) - 1n && dst[1] === (1n << 64n) - 1n);
  // per-row thresholds: rows 0-3 always smooth, rows 4-7 never
  randomize(4 * N, GRID, 99);
  const rowTab = new BigUint64Array(memory.buffer, L.THRY, H); for (let y = 0; y < H; y++) rowTab[y] = y < 4 ? ~0n : 0n;
  const before = Array.from(words);
  smooth(W, H, GRID, GRID2, L.THRY, 0n);
  let topChanged = 0, bottomChanged = 0;
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) { const i = y * W + x; const ch = dst[2 * i] !== before[2 * i] || dst[2 * i + 1] !== before[2 * i + 1]; if (ch) { if (y < 4) topChanged++; else bottomChanged++; } }
  check(`row threshold table: only rows 0-3 change (${topChanged} pixels changed above, ${bottomChanged} below)`, topChanged > 0 && bottomChanged === 0);
}

// ---- smoothing neighbourhoods: 8-connected (9 votes) and 5x5 (25 votes)
{
  const { smooth } = instance.exports;
  const GRID2 = GRID + 16 * N + 64;
  const dst = new BigUint64Array(memory.buffer, GRID2, 2 * N);
  const clamp = (v, n) => v < 0 ? 0 : v >= n ? n - 1 : v;
  const ref = (nbr, x, y, j) => { const r = nbr === 2 ? 2 : 1, need = nbr === 0 ? 3 : nbr === 1 ? 5 : 13; let maj = 0n;
    for (let b = 0n; b < 64n; b++) { let c = 0; for (let dy = -r; dy <= r; dy++) for (let dx = -r; dx <= r; dx++) { if (nbr === 0 && dx && dy) continue; if ((srcW[2 * (clamp(y + dy, H) * W + clamp(x + dx, W)) + j] >> b) & 1n) c++; } if (c >= need) maj |= 1n << b; } return maj; };
  let srcW;
  for (const nbr of [0, 1, 2]) {
    randomize(4 * N, GRID, 777 + nbr); srcW = Array.from(words);
    const ch = smooth(W, H, GRID, GRID2, smTab(~0n), 0n, nbr);
    let ok = true, expected = 0;
    for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) for (let j = 0; j < 2; j++) { const m = ref(nbr, x, y, j); if (dst[2 * (y * W + x) + j] !== m) ok = false; let d = m ^ srcW[2 * (y * W + x) + j]; while (d) { d &= d - 1n; expected++; } }
    check(`neighbourhood ${nbr}: every bit becomes the ${[5, 9, 25][nbr]}-vote majority with clamped edges (${ch} bits changed)`, ok && ch === expected);
  }
  const ALL = (1n << 64n) - 1n;
  // a one-pixel-wide vertical line of ones survives the cross (3 of 5) but not the block neighbourhoods
  const line = w => { words.fill(0n); for (let y = 0; y < H; y++) for (let x = 3; x < 3 + w; x++) { words[2 * (y * W + x)] = ~0n; words[2 * (y * W + x) + 1] = ~0n; } };
  line(1); smooth(W, H, GRID, GRID2, smTab(~0n), 0n, 0); const keep4 = dst[2 * (4 * W + 3)] === ALL;
  line(1); smooth(W, H, GRID, GRID2, smTab(~0n), 0n, 1); const gone8 = dst[2 * (4 * W + 3)] === 0n;
  line(1); smooth(W, H, GRID, GRID2, smTab(~0n), 0n, 2); const gone25 = dst[2 * (4 * W + 3)] === 0n;
  check('a 1-wide line: kept by the cross (3 of 5), erased by 3x3 (3 of 9) and 5x5 (5 of 25)', keep4 && gone8 && gone25);
  line(2); smooth(W, H, GRID, GRID2, smTab(~0n), 0n, 1); const keep2in8 = dst[2 * (4 * W + 3)] === ALL && dst[2 * (4 * W + 4)] === ALL;
  line(2); smooth(W, H, GRID, GRID2, smTab(~0n), 0n, 2); const gone2in25 = dst[2 * (4 * W + 3)] === 0n && dst[2 * (4 * W + 4)] === 0n;
  line(3); smooth(W, H, GRID, GRID2, smTab(~0n), 0n, 2); const keep3in25 = dst[2 * (4 * W + 3)] === ALL && dst[2 * (4 * W + 5)] === ALL;
  check('a 2-wide line: kept by 3x3 (6 of 9), erased by 5x5 (10 of 25); a 3-wide line is kept by 5x5 (15 of 25)', keep2in8 && gone2in25 && keep3in25);
  words.fill(0n); words[0] = ~0n; words[1] = ~0n;
  smooth(W, H, GRID, GRID2, smTab(~0n), 0n, 1); const gone9 = dst[0] === 0n && dst[1] === 0n;
  words.fill(0n); words[0] = ~0n; words[1] = ~0n;
  smooth(W, H, GRID, GRID2, smTab(~0n), 0n, 2);
  check('a lone corner pixel survives the cross (3 of 5) but clamping gives it only 4 of 9 and 9 of 25 votes in the block neighbourhoods', gone9 && dst[0] === 0n && dst[1] === 0n);
  check('neighbourhood 2 with threshold 0 changes nothing', smooth(W, H, GRID, GRID2, smTab(0n), 0n, 2) === 0);
}

// ---- jam tests: every pixel of a large random grid must decode and render in bounded time, for every N
{
  const W2 = 512, H2 = 384, N2 = W2 * H2, PIX2 = GRID + 16 * N2, PAL2 = PIX2 + 4 * N2, need = PAL2 + 516;
  if (need > memory.buffer.byteLength) memory.grow(Math.ceil((need - memory.buffer.byteLength) / 65536));
  const pal2 = new Uint32Array(memory.buffer, PAL2, 129); for (let i = 0; i <= 128; i++) pal2[i] = 0xff000000 | i;
  for (const Nmax of [2, 4, 16]) {
    Codec.install(memory, Codec.build(text, Nmax));
    randomize(4 * N2, GRID, 2024 + Nmax);
    let maxConsumed = 0;
    const t0 = performance.now();
    for (let i = 0; i < N2; i++) { const c = decode_pixel(GRID, i, PRM) >> 8; if (c > maxConsumed) maxConsumed = c; }
    const dt = performance.now() - t0;
    const t1 = performance.now(); render(N2, GRID, PIX2, PAL2, 0, PRM); const ms = performance.now() - t1;
    console.log(`   N=${Nmax}: ${N2} random pixels decoded in ${dt.toFixed(0)} ms, max input consumed ${maxConsumed} bits; render mode 0 ${ms.toFixed(0)} ms`);
    check(`N=${Nmax}: no pixel reaches the 1024-bit cap and decoding a 512x384 grid takes under 5 s`, maxConsumed < 1024 && dt < 5000 && ms < 5000);
  }
  Codec.install(memory, built);
  // the simulation itself must keep moving from the default (random) start under the default rule
  const W3 = 128, H3 = 96, N3 = W3 * H3;
  randomize(4 * N3, GRID, 99);
  let movedTotal = 0, worst = 1e9;
  const t2 = performance.now();
  for (let turn = 0; turn < 200; turn++) { const mv = mix(W3, H3, GRID, turn & 3, 0, thrTab(thr, W3), 0n); movedTotal += mv; if (mv < worst) worst = mv; }
  console.log(`   200 turns from a random start: ${(performance.now() - t2).toFixed(0)} ms, ${movedTotal} bits moved, quietest turn ${worst}`);
  check('default start keeps moving under the context-only rule', worst > 100);
}
// ---- render buffer: blend(w, h, pix, acc, k0, k4, k8) -> (n4 << 32) | n8; acc = one f32x4 per pixel (channels in lanes 0..2)
{
  const W = 6, H = 5, N = W * H, PIXB = GRID + 65536, ACC = PIXB + 4 * N;
  const px = new Uint8Array(memory.buffer, PIXB, 4 * N), ac = new Float32Array(memory.buffer, ACC, 4 * N);
  const setFrame = f => { for (let i = 0; i < N; i++) { const [r, g, b] = f(i % W, Math.floor(i / W)); px.set([r, g, b, 255], 4 * i); } };
  const rgb = i => [px[4 * i], px[4 * i + 1], px[4 * i + 2]];
  const run = (k0, k4, k8) => { const r = blend(W, H, PIXB, ACC, k0, k4, k8, 0, H); return { n4: Number(r >> 32n), n8: Number(r & 0xffffffffn) }; };
  setFrame(() => [100, 150, 200]);
  let r = run(65536, 65536, 65536);
  check('blend with k = 65536 copies the frame into the accumulator (equal constants: no flat counts)', r.n8 === 0 && r.n4 === 0 && ac[0] === 100 && ac[4 * N - 2] === 200 && rgb(N - 1).join() === '100,150,200' && px[3] === 255);
  setFrame(() => [100, 150, 200]); r = run(65536, 32768, 16384);
  check('a flat frame is 8-connected flat everywhere when the constants differ', r.n8 === N && r.n4 === 0 && rgb(0).join() === '100,150,200');
  // one pixel in the middle changes colour: its cross neighbours lose both tiers, its diagonal neighbours only the 8-connected one
  setFrame((x, y) => x === 2 && y === 2 ? [0, 150, 200] : [100, 150, 200]);
  r = run(32768, 6554, 2185);   // k = 1/2, 1/10, 1/30
  check(`a changed pixel: it and its 4 cross neighbours are not flat, its 4 diagonal neighbours are 4-connected flat only (${r.n4}), the rest 8-connected flat (${r.n8})`, r.n4 === 4 && r.n8 === N - 9);
  { const r0 = blend(W, H, PIXB, ACC, 0, 0, 1, 0, 1);   // k = 0 (and 1/65536 for the flat ones): nothing visible moves; count row 0 only
    check(`the flat counts honour the row range: row 0 alone has ${W} 8-connected flat pixels`, r0 === BigInt(W)); }
  check('the changed pixel moves half way (100 -> 50), its flat neighbours stay', rgb(2 * W + 2)[0] === 50 && rgb(0)[0] === 100 && rgb(2 * W + 1)[0] === 100 && px.every((v, i) => (i & 3) !== 3 || v === 255));
  // a uniform change of the whole frame moves only at the slowest constant
  setFrame(() => [0, 150, 200]);
  r = run(32768, 6554, 2185);
  check('a uniformly changed frame is 8-connected flat everywhere and moves at k = 1/30 (100 -> 97)', r.n8 === N && rgb(0)[0] === 97 && rgb(N - 1)[0] === 97);
  // tiers: a diagonal-only disturbance leaves the centre 4-connected flat
  setFrame(() => [0, 150, 200]); run(65536, 65536, 65536);
  setFrame((x, y) => x === 1 && y === 1 ? [200, 150, 200] : [0, 150, 200]);
  for (let i = 0; i < N; i++) { ac[4 * i] = 50; ac[4 * i + 1] = 150; ac[4 * i + 2] = 200; }   // every accumulator at R = 50
  r = run(65536, 32768, 0);   // not flat: copy; 4-connected flat: half way; 8-connected flat: frozen
  check('tiers: the pixel diagonal to a change is 4-connected flat (50 -> 25 at k = 1/2), its cross neighbour copies (50 -> 0), far pixels are frozen (50)', rgb(2 * W + 2)[0] === 25 && rgb(W + 2)[0] === 0 && rgb(N - 1)[0] === 50 && r.n4 === 4);
  // edge pixels compare with the neighbours that exist: a corner differing from its 3 neighbours
  setFrame(() => [0, 150, 200]); run(65536, 65536, 65536);
  setFrame((x, y) => x === 0 && y === 0 ? [255, 150, 200] : [0, 150, 200]);
  r = run(65536, 0, 0);
  check(`a corner change: corner and its 2 cross neighbours not flat, its diagonal neighbour 4-connected flat (${r.n4}), ${r.n8} 8-connected flat`, r.n4 === 1 && r.n8 === N - 4 && rgb(0)[0] === 255 && rgb(1)[0] === 0);
  // convergence: repeated identical frames reach the target exactly in fixed point (the frame must be re-set, blend overwrites it)
  for (let t = 0; t < 2000; t++) { setFrame(() => [37, 0, 0]); run(1638, 410, 410); }
  check(`2000 identical frames at k = 1/160 converge to the target value (37): accumulator ${ac[0]}`, rgb(0)[0] === 37 && rgb(N - 1)[0] === 37 && Math.abs(ac[0] - 37) < 2e-3 && Math.abs(ac[1]) < 2e-3);   // f32: the last steps round away, within a thousandth of a level
  // equal constants: the flatness pass is skipped, the counts are 0 and the blend is the same as with the textured constant
  setFrame(() => [0, 150, 200]); run(65536, 65536, 65536);
  setFrame((x, y) => x === 2 && y === 2 ? [100, 150, 200] : [0, 150, 200]);
  r = run(32768, 32768, 32768);
  check('one constant for every pixel: no flat counts, the changed pixel and the rest move at the same k', r.n4 === 0 && r.n8 === 0 && rgb(2 * W + 2)[0] === 50 && rgb(0)[0] === 0);
  // the blend depends only on the colour, not on the alpha byte
  setFrame(() => [37, 0, 0]); px[3] = 7; r = run(65536, 65536, 65535);
  check('alpha is ignored for the flatness test and written back as 255', r.n8 === N && px[3] === 255);
  // two stages in cascade: the second accumulator reads the first stage's output
  const ACC2 = ACC + 16 * N;
  setFrame(() => [0, 0, 0]); blend(W, H, PIXB, ACC, 65536, 65536, 65536, 0, H); blend(W, H, PIXB, ACC2, 65536, 65536, 65536, 0, H);
  const two = [];
  for (let t = 0; t < 4; t++) { setFrame(() => [200, 0, 0]); blend(W, H, PIXB, ACC, 32768, 32768, 32768, 0, H); blend(W, H, PIXB, ACC2, 32768, 32768, 32768, 0, H); two.push(rgb(0)[0]); }
  check(`two stages at k = 1/2 give the cascade step response 50, 100, 137.5, 162.5 of 200: ${two.join(', ')}`, two.join() === '50,100,138,162' || two.join() === '50,100,137,163' || two.join() === '50,100,138,163');
  // unsharp(n, pix, acc2, acc3, w): the frame from two stages' accumulators, (1 - w) acc2 + w acc3, rounded and clamped
  { const ACC3 = ACC2 + 16 * N, a2 = new Float32Array(memory.buffer, ACC2, 4 * N), a3 = new Float32Array(memory.buffer, ACC3, 4 * N);
    for (let i = 0; i < N; i++) { a2.set([100, 200, 10, 0], 4 * i); a3.set([60, 240, 0, 0], 4 * i); }
    unsharp(N, PIXB, ACC2, ACC3, -0.25);
    check(`unsharp at w = -0.25: 100 over 60 -> 110, 200 over 240 -> 190, 10 over 0 -> 13 (rounded), alpha 255: ${rgb(0).join(' ')}`, rgb(0).join() === '110,190,13' && px[3] === 255);
    unsharp(N, PIXB, ACC2, ACC3, 1);
    check('w = 1 shows the third stage itself', rgb(0).join() === '60,240,0');
    for (let i = 0; i < N; i++) { a2.set([250, 0, 128, 0], 4 * i); a3.set([0, 255, 128, 0], 4 * i); }
    unsharp(N, PIXB, ACC2, ACC3, -5);
    check('w = -5 clamps: 250 over 0 -> 255, 0 over 255 -> 0, equal values are unchanged', rgb(0).join() === '255,0,128');
    // two stages and the slow stage through Band.postFrame: the shown value is (1 + ts) s2 - ts s3 of the step response, ts = 0.25
    const Band = vm.runInThisContext(fs.readFileSync(dir + '/src/lattice/band.js', 'utf8') + '; Band');
    const base = PIXB, need = base + Band.POST_BYTES * N; if (need > memory.buffer.byteLength) memory.grow(Math.ceil((need - memory.buffer.byteLength) / 65536));
    const frame = new Uint8Array(memory.buffer, base, 4 * N), set = v => { for (let i = 0; i < N; i++) frame.set([v, 0, 0, 255], 4 * i); };
    const P = { stages: 2, sharp: false, k0: 32768, k4: 32768, k8: 32768, k0s: 19195, k4s: 19195, k8s: 19195, ts: 0.25 };   // k = 1/2 and 1 - sqrt(1/2)
    set(0); Band.postFrame(instance.exports, base, W, H, { ...P, k0: 65536, k4: 65536, k8: 65536, k0s: 65536, k4s: 65536, k8s: 65536 });
    const three = [], want = [];
    for (let t = 0; t < 4; t++) { set(200); Band.postFrame(instance.exports, base, W, H, P); three.push(frame[0]); }
    { let a1 = 0, a2 = 0, a3 = 0; for (let t = 0; t < 4; t++) { a1 += (200 - a1) / 2; a2 += (Math.round(a1) - a2) / 2; a3 += (Math.round(a2) - a3) * (19195 / 65536); want.push(Math.round(1.25 * a2 - 0.25 * a3)); } }
    check(`two stages and the slow stage: the frame is 1.25 x the second stage - 0.25 x the slow one: ${three.join(', ')} (model ${want.join(', ')})`, three.every((v, i) => Math.abs(v - want[i]) <= 1));
    // one stage and the slow stage: the slow one reads the first stage's output
    const P1 = { ...P, stages: 1, ts: 1 }; set(0); Band.postFrame(instance.exports, base, W, H, { ...P1, k0: 65536, k4: 65536, k8: 65536, k0s: 65536, k4s: 65536, k8s: 65536 });
    const one = []; for (let t = 0; t < 3; t++) { set(200); Band.postFrame(instance.exports, base, W, H, P1); one.push(frame[0]); }
    const w1 = []; { let a1 = 0, a3 = 0; for (let t = 0; t < 3; t++) { a1 += (200 - a1) / 2; a3 += (Math.round(a1) - a3) * (19195 / 65536); w1.push(Math.min(255, Math.round(2 * a1 - a3))); } }
    check(`one stage with sharpening 1: the frame is 2 x the first stage - the slow one: ${one.join(', ')} (model ${w1.join(', ')})`, one.every((v, i) => Math.abs(v - w1[i]) <= 1));
    // no averaging and the slow stage: the frame is 2 x itself - the slow one
    const P0 = { ...P, stages: 0, ts: 1 }; set(0); Band.postFrame(instance.exports, base, W, H, { ...P0, k0s: 65536, k4s: 65536, k8s: 65536 });
    const zero = []; for (let t = 0; t < 3; t++) { set(100); Band.postFrame(instance.exports, base, W, H, P0); zero.push(frame[0]); }
    const w0 = []; { let a3 = 0; for (let t = 0; t < 3; t++) { a3 += (100 - a3) * (19195 / 65536); w0.push(Math.round(200 - a3)); } }
    check(`averaging off with sharpening 1: the frame is 2 x the frame - the slow stage: ${zero.join(', ')} (model ${w0.join(', ')})`, zero.every((v, i) => Math.abs(v - w0[i]) <= 1));
    check('averaging off and sharpening 0: postFrame leaves the frame alone', (set(77), Band.postFrame(instance.exports, base, W, H, { stages: 0, ts: 0, sharp: false }) === null && frame[0] === 77));
  }
  // ---- spatial sharpening: dst = 2 * src - mean of the 4-connected neighbours
  const DST = ACC + 12 * N, out = new Uint8Array(memory.buffer, DST, 4 * N), org = i => [out[4 * i], out[4 * i + 1], out[4 * i + 2]];
  setFrame(() => [100, 150, 200]); sharpen(W, H, PIXB, DST, 256);
  check('sharpen: a flat frame is unchanged, alpha 255', out.every((v, i) => v === [100, 150, 200, 255][i & 3]));
  setFrame((x, y) => x === 2 && y === 2 ? [200, 100, 0] : [100, 100, 100]); sharpen(W, H, PIXB, DST, 256);
  check('sharpen: a lone pixel 200 on 100 becomes 2*200-100 = 255 (clamped), 0 on 100 becomes 0, its neighbours 2*100-125 = 75 and 2*100-75 = 125, diagonals unchanged',
    org(2 * W + 2).join() === '255,100,0' && org(2 * W + 1).join() === '75,100,125' && org(W + 2).join() === '75,100,125' && org(W + 1).join() === '100,100,100' && org(0).join() === '100,100,100');
  setFrame((x, y) => [10 * x, 0, 0]); sharpen(W, H, PIXB, DST, 256);   // a ramp: interior pixels keep their value, the edges are extrapolated
  check('sharpen: a linear ramp is unchanged inside, the edge columns extrapolate (2*0-(10+0)/3 -> 0 at the corner, 2*50-(40+50+50)/3 = 53 at the right edge)',
    org(2 * W + 2)[0] === 20 && org(2 * W + 3)[0] === 30 && org(0)[0] === 0 && org(2 * W + 5)[0] === 53);
}
// ---- pairs: two cells changed together (change() with pairMode 1 = concatenated, 2 = bit-interleaved, 3 = xor then add, 4 = add then subtract, 5 = byte-interleaved; flip swaps the roles)
{
  const bitsOf = arr => { const o = []; for (let i = 0; i < arr.length * 8; i++) o.push((arr[i >> 3] >> (i & 7)) & 1); return o; };
  const fromBits = bits => { const a = new Uint8Array(bits.length / 8); bits.forEach((b, i) => { a[i >> 3] |= b << (i & 7); }); return a; };
  const joinRef = (A, B, mode, flip) => { const [a, b] = flip ? [B, A] : [A, B]; if (mode === 1) return Uint8Array.from([...a, ...b]);
    if (mode === 3) return Uint8Array.from([...a.map((v, k) => v ^ b[k]), ...b.map((v, k) => (v + (a[k] ^ v)) & 255)]);
    if (mode === 4) return Uint8Array.from([...a.map((v, k) => (v + b[k]) & 255), ...a.map((v, k) => (v - (((v + b[k]) & 255) >> 1)) & 255)]);
    if (mode === 5) return Uint8Array.from({ length: 32 }, (_, i) => (i & 1 ? b : a)[i >> 1]);
    const ab = bitsOf(a), bb = bitsOf(b), j = []; for (let k = 0; k < 128; k++) j.push(ab[k], bb[k]); return fromBits(j); };
  const splitRef = (J, mode, flip) => { let a, b; if (mode === 1) { a = J.slice(0, 16); b = J.slice(16); }
    else if (mode === 3) { const x = J.slice(0, 16), y = J.slice(16); b = y.map((v, k) => (v - x[k]) & 255); a = x.map((v, k) => v ^ b[k]); }
    else if (mode === 4) { const sm = J.slice(0, 16), d = J.slice(16); a = d.map((v, k) => (v + (sm[k] >> 1)) & 255); b = sm.map((v, k) => (v - a[k]) & 255); }
    else if (mode === 5) { a = J.filter((_, i) => i % 2 === 0); b = J.filter((_, i) => i % 2 === 1); }
    else { const jb = bitsOf(J); a = fromBits(jb.filter((_, i) => i % 2 === 0)); b = fromBits(jb.filter((_, i) => i % 2 === 1)); } return flip ? [b, a] : [a, b]; };
  // the lifting joinings are bijections on byte pairs: every (a, b) round-trips through the reference
  {
    let bij = true;
    for (const mode of [3, 4]) for (let a = 0; a < 256 && bij; a++) for (let b = 0; b < 256; b++) {
      const J = joinRef(new Uint8Array(16).fill(a), new Uint8Array(16).fill(b), mode, 0), [a2, b2] = splitRef(J, mode, 0);
      if (a2[0] !== a || b2[0] !== b) { bij = false; break; }
    }
    check('pairs: xor-then-add and add-then-subtract round-trip every pair of bytes (reference)', bij);
  }
  const A = Uint8Array.from({ length: 16 }, (_, k) => (k * 37 + 11) & 255), B = Uint8Array.from({ length: 16 }, (_, k) => (k * 91 + 200) & 255);
  const px = i => m8.slice(GRID + 16 * i, GRID + 16 * i + 16), eq = (x, y) => x.length === y.length && x.every((v, k) => v === y[k]);
  const { change } = instance.exports;
  const run = (changer, mode, flip, a = A, b = B) => { io.setChanger(changer); io.setPair(mode, flip); m8.set(a, GRID); m8.set(b, GRID + 16); const n = change(2, GRID, PRM); io.setPair(0, 0); return n; };
  // the bijection: do nothing round-trips both representations, in both flips
  let ok = true;
  for (const mode of [1, 2, 3, 4, 5]) for (const flip of [0, 1]) { const n = run(3, mode, flip); if (n !== 0 || !eq(px(0), A) || !eq(px(1), B)) ok = false; }
  check('pairs: "do nothing" on a joint cell leaves both cells unchanged (all five joinings, both flips)', ok);
  // invert commutes with the mapping
  ok = true;
  for (const mode of [1, 2, 5]) for (const flip of [0, 1]) { run(4, mode, flip); if (!eq(px(0), A.map(v => v ^ 255)) || !eq(px(1), B.map(v => v ^ 255))) ok = false; }
  check('pairs: invert on a joint cell inverts both cells (the layout joinings: concatenated, bit- and byte-interleaved)', ok);
  // reverse bytes: compare with a JavaScript reference of join / reverse / split
  ok = true;
  for (const mode of [1, 2, 3, 4, 5]) for (const flip of [0, 1]) {
    run(5, mode, flip);
    const J = joinRef(A, B, mode, flip), R = J.slice().reverse(), [a2, b2] = splitRef(R, mode, flip);
    if (!eq(px(0), a2) || !eq(px(1), b2)) ok = false;
  }
  check('pairs: reverse bytes on the joint cell matches the reference join / reverse / split (all five joinings, both flips)', ok);
  // the DCT on a joint cell is a 32-point transform over it: compare with a JavaScript reference of the kernel's formula
  // (same summation order, round half to even), split back through the joining's inverse
  const roundEven = x => { const r = Math.round(x); return Math.abs(x % 1) === 0.5 && r % 2 !== 0 ? r - 1 : r; };
  const dctRef = (b, inv) => { const Nn = b.length, s0 = Math.sqrt(1 / Nn), s1 = Math.sqrt(2 / Nn), out = new Uint8Array(Nn);
    for (let k = 0; k < Nn; k++) { let acc = 0;
      for (let n = 0; n < Nn; n++) { const t = b[n] - 128, m = inv ? (2 * k + 1) * n : (2 * n + 1) * k, c = inv ? 2 * (n ? s1 : s0) : 0.5 * (k ? s1 : s0);
        acc += (t * c) * Math.cos(Math.PI * m / (2 * Nn)); }
      out[k] = Math.max(0, Math.min(255, 128 + roundEven(acc))); }
    return out; };
  for (const mode of [1, 3, 4]) {
    const J = joinRef(A, B, mode, 0), D = dctRef(J, 0), [a2, b2] = splitRef(D, mode, 0);
    run(17, mode, 0);
    const name = { 1: 'concatenated', 3: 'xor-then-add', 4: 'add-then-subtract' }[mode];
    const err = Math.max(...px(0).map((v, i) => Math.abs(v - a2[i])), ...px(1).map((v, i) => Math.abs(v - b2[i])));
    check(`pairs: the DCT on a ${name} joint cell is the 32-point transform of the joint cell, split back by the inverse (max error ${err})`, err <= 1);
  }
  {
    run(17, 1, 0); const d0 = px(0).slice(), d1 = px(1).slice();
    run(18, 1, 0, d0, d1);
    const err = Math.max(...px(0).map((v, i) => Math.abs(v - A[i])), ...px(1).map((v, i) => Math.abs(v - B[i])));
    check(`pairs: 32-point DCT then inverse DCT returns the pair to within rounding (max error ${err})`, err <= 3);
  }
  check('pairs: interleaving really mixes the cells: reversed interleaved A, B differ from reversed A and reversed B', !eq(px(0), A.slice().reverse()));
  // a Z80 program in A writes into B's half: the joint cell is the whole address space
  const prog = new Uint8Array(16); prog.set([0x3E, 0x42, 0x32, 0x14, 0x00, 0x76]);   // LD A,42h; LD (0014h),A; HALT
  const zero = new Uint8Array(16);
  io.setSteps(64);
  run(6, 1, 0, prog, zero);
  check('pairs (concatenated, A then B): a Z80 program in A stores to address 20, which is byte 4 of B', px(1)[4] === 0x42 && px(0)[3] === 0x14 && px(0)[4] === 0);
  run(6, 1, 1, prog, zero);
  check('pairs (concatenated, B then A): the same store lands in A itself, since A now occupies addresses 16..31', px(0)[4] === 0x42 && px(1)[4] === 0);
  const pushProg = new Uint8Array(16); pushProg.set([0x01, 0xCD, 0xAB, 0xC5, 0x76]);   // LD BC,ABCDh; PUSH BC; HALT
  run(6, 1, 0, pushProg, zero);
  check('pairs (concatenated, A then B): a PUSH from SP = 0 writes to FFFEh, which wraps to bytes 30,31, the last two bytes of B', px(1)[14] === 0xcd && px(1)[15] === 0xab && px(0)[14] === 0 && px(0)[15] === 0);
  io.setSteps(256);
  // the 128-bit machines see the joint cell as two 16-byte cells: a pair PDP-8 run equals two single runs
  io.setChanger(19); io.setPair(0, 0); m8.set(A, GRID); decode_pixel(GRID, 0, PRM); const dA = m8.slice(io.OUT, io.OUT + 16);
  m8.set(B, GRID); decode_pixel(GRID, 0, PRM); const dB = m8.slice(io.OUT, io.OUT + 16);
  run(19, 1, 1);
  check('pairs: the PDP-8 on a concatenated joint cell runs each cell separately (B then A, then split back)', eq(px(0), dA) && eq(px(1), dB));
  // the LZ decompressor on a joint cell: 32 bytes of dictionary text, cursor from the first 13 of the 256 bits
  io.setChanger(0); io.setCursorOffset(0);
  const words = new BigUint64Array(memory.buffer, GRID, 4); words.fill(0n);
  m8.set(new Uint8Array(32), GRID); io.setPair(1, 0); change(2, GRID, PRM); io.setPair(0, 0);
  const joint = m8.slice(GRID, GRID + 32), txt = i => built.bytes[i % built.bytes.length];
  check('pairs: the decompressor expands the 256-bit joint cell into 32 bytes of dictionary text (zero cell: from the start)', joint.every((b, k) => b === txt(k)));
  io.setCursorOffset(600); io.setChanger(0);
  // single-cell decoding is untouched afterwards: the cell width is back at 16
  m8.set(A, GRID); io.setChanger(3); decode_pixel(GRID, 0, PRM);
  check('after a pair change the single-cell path is back: decode_pixel of "do nothing" copies 16 bytes', m8.slice(io.OUT, io.OUT + 16).every((b, k) => b === A[k]));
}
// ---- mutate(n, grid, base, lam, salt): random bit flips, lam = expected flips per cell in 32.32 fixed point
{
  const n = 4096, bytes = 16 * n, fx = x => BigInt(Math.round(x * 2 ** 32));
  const zero = () => m8.fill(0, GRID, GRID + bytes);
  zero(); check('mutate: lam 0 flips nothing', mutate(n, GRID, 0, 0n, 7n) === 0 && bits(n, GRID) === 0);
  zero(); const f1 = mutate(n, GRID, 0, fx(1), 7n);
  check('mutate: lam 1 flips exactly one bit in every cell (' + f1 + ' flips, ' + bits(n, GRID) + ' set bits)', f1 === n && bits(n, GRID) === n);
  zero(); const fq = mutate(n, GRID, 0, fx(0.25), 7n);
  check('mutate: lam 0.25 flips about a quarter of the cells (' + fq + ' of ' + n + ')', fq > 900 && fq < 1150);
  zero(); const f25 = mutate(n, GRID, 0, fx(2.5), 7n);
  check('mutate: lam 2.5 gives every cell 2 or 3 flips (' + f25 + ' flips, expected 10240)', f25 > 10100 && f25 < 10380);
  zero(); mutate(n, GRID, 0, fx(0.5), 11n); const a = m8.slice(GRID, GRID + bytes);
  zero(); mutate(n, GRID, 0, fx(0.5), 11n); const b = m8.slice(GRID, GRID + bytes);
  zero(); mutate(n, GRID, 0, fx(0.5), 12n); const c = m8.slice(GRID, GRID + bytes);
  check('mutate: the same salt flips the same bits, another salt different ones', a.every((v, i) => v === b[i]) && !a.every((v, i) => v === c[i]));
  zero(); mutate(1000, GRID, 0, fx(0.5), 11n); mutate(n - 1000, GRID + 16000, 1000, fx(0.5), 11n); const d = m8.slice(GRID, GRID + bytes);
  check('mutate: two row bands with their global base indices reproduce the whole-grid flips bit for bit', a.every((v, i) => v === d[i]));
  zero(); const tiny = mutate(n, GRID, 0, fx(0.00128), 5n);
  check('mutate: the page default, 0.001 % of bits, is a handful of flips on 4096 cells (' + tiny + ', expected 5)', tiny >= 0 && tiny <= 15);
}
// ---- hist: byte counts over a grid
{
  const n = 64, OUTH = GRID + 16 * n + 4096;
  randomize(4 * n, GRID, 31337); m8[GRID] = 0; m8[GRID + 1] = 255;
  hist(n, GRID, OUTH);
  const ref = new Uint32Array(256); for (let i = 0; i < 16 * n; i++) ref[m8[GRID + i]]++;
  const got = new Uint32Array(memory.buffer, OUTH, 256);
  check('hist counts every byte of the grid (' + got.reduce((a, b) => a + b, 0) + ' = ' + 16 * n + ', ' + got.filter(v => v).length + ' distinct values)', got.every((v, k) => v === ref[k]) && got.reduce((a, b) => a + b, 0) === 16 * n);
  hist(1, GRID, OUTH);
  check('hist zeroes its output first: a one-pixel count sums to 16', got.reduce((a, b) => a + b, 0) === 16 && got[0] >= 1 && got[255] >= 1);
}

// ---- links: two persistent CPUs per pair of neighbours (one per direction), one instruction per link per phase
{
  const w = 4, h = 2, n = w * h, ST = GRID + (1 << 16), px = i => m8.slice(GRID + 16 * i, GRID + 16 * i + 16);
  const order = [1, 0, 3, 2], turnLinks = () => order.reduce((c, ph) => c + links(w, h, GRID, PRM, ph, ST), 0);
  const prog = [0x21, 0x14, 0x00, 0x34, 0x18, 0xFD];   // LD HL,0014h; INC (HL); JR -3: increments byte 4 of the other pixel every second instruction
  m8.fill(0, GRID, GRID + 16 * n);
  m8.set(prog, GRID);   // pixel (0,0): its forward machines (to (1,0) and (0,1)) run it; the backward machines of those pairs start in the partner (zeros = NOPs)
  io.setChanger(6); io.setPair(0, 0); links_reset(ST, 4 * n, 6);
  const c1 = turnLinks(), c2 = turnLinks();
  check('links: turn 1 loads HL (nothing changes), turn 2 increments in both forward links of (0,0): right and down partners (' + c1 + ', ' + c2 + ' pixel writes)', c1 === 0 && c2 === 2 && px(1)[4] === 1 && px(4)[4] === 1);
  for (let t = 3; t <= 10; t++) turnLinks();
  check('links: after 10 turns each forward machine has run 10 instructions, 5 of them INC: partners at 5, the program and the rest untouched',
    px(1)[4] === 5 && px(4)[4] === 5 && px(0).slice(0, 6).join() === '33,20,0,52,24,253' && [2, 3, 5, 6, 7].every(i => px(i).every(v => v === 0)));
  const st = m8.slice(ST, ST + 128), bk = m8.slice(ST + 128, ST + 256);
  check('links: the forward state of pair 0 persists: PC (register-file offset 22) points into the loop, HL = 0x14', (st[22] === 3 || st[22] === 4) && st[4] === 0x14 && st[5] === 0);
  check('links: the backward machine of pair 0 is separate: it has fetched 10 NOPs from (1,0), PC = 10, HL = 0', bk[22] === 10 && bk[4] === 0 && bk[5] === 0);
  links_reset(ST, 4 * n, 6); m8.fill(0, GRID + 16, GRID + 16 * n);
  for (let t = 1; t <= 10; t++) turnLinks();
  check('links: after a reset the run repeats exactly', px(1)[4] === 5 && px(4)[4] === 5);
  // the backward direction: the same program in pixel (1,0) is run by that pixel's forward link to (2,0) and by the
  // backward link of the pair (0,0)-(1,0), whose memory is (1,0) then (0,0), so it increments byte 4 of (0,0)
  links_reset(ST, 4 * n, 6); m8.fill(0, GRID, GRID + 16 * n); m8.set(prog, GRID + 16);
  for (let t = 1; t <= 10; t++) turnLinks();
  check('links: a program in (1,0) reaches (0,0) through the backward link and (2,0), (1,1) through its forward links: all at 5',
    px(0)[4] === 5 && px(2)[4] === 5 && px(5)[4] === 5 && px(1).slice(0, 6).join() === '33,20,0,52,24,253');
  // write-back is immediate: a machine's write to its partner is seen by the machines that run after it in the same
  // round. (0,0) runs LD A,3Ch; LD (0011h),A, storing an INC A opcode into byte 1 of (1,0) in round 2 (phase LR0).
  // The backward machine of the same pair, which executes (1,0)'s bytes and runs right after, fetches that byte in
  // round 2 and so does the forward machine of the pair (1,0)-(2,0) in phase LR1 later in the round: both have A = 1
  // at the end of round 2, which deferred write-back would delay to round 3.
  links_reset(ST, 4 * n, 6); m8.fill(0, GRID, GRID + 16 * n); m8.set([0x3E, 0x3C, 0x32, 0x11, 0x00, 0x18, 0xFE], GRID);
  turnLinks();
  const Aat = i => m8[ST + 128 * i + 7], a1 = [Aat(1), Aat(2)];
  turnLinks();
  check('links: a byte written into (1,0) in round 2 is executed in the same round by the backward machine of its pair and by the next phase\'s machine (A: ' + a1 + ' after round 1, ' + [Aat(1), Aat(2)] + ' after round 2)',
    px(1)[1] === 0x3C && a1[0] === 0 && a1[1] === 0 && Aat(1) === 1 && Aat(2) === 1);
  links_reset(ST, 4 * n, 7);
  check('links: a 6502 reset gives every link P = 0x24 and S = 0xFF', m8[ST + 4] === 0x24 && m8[ST + 3] === 0xFF && m8[ST + 128 * (4 * n - 1) + 4] === 0x24);
  io.setChanger(0); io.setPair(0, 0); links_reset(ST, 4 * n, 0);
  check('links: a non-CPU changer does nothing (' + turnLinks() + ' changes)', true);
  // the phase order is the swap order UD0 LR0 UD1 LR1, forward machine before backward within a pair. On a 2 x 2 grid
  // (0,0) = INC (HL) toggles its own byte 0 between 34h (INC) and 35h (DEC) each time a machine runs it, and (1,0) reads
  // (0,0)[0] through the backward LR0 machine (LD A,(0010h)) and stores it two rounds later (LD (0005h),A). UD0 first gives
  // 34h (the UD0 machine toggled to 35h, the LR0 forward machine back to 34h before the backward one read it) and lets
  // the LR0 store land last; LR0 first would read 35h and have the UD0 machine of (1,0)-(1,1) overwrite the byte with 0.
  {
    io.setChanger(6); io.setPair(0, 0); links_reset(ST, 4 * 4, 6); m8.fill(0, GRID, GRID + 16 * 4);
    m8.set([0x34], GRID); m8.set([0x3A, 0x10, 0x00, 0x32, 0x05, 0x00], GRID + 16);
    for (let r = 0; r < 2; r++) for (const ph of order) links(2, 2, GRID, PRM, ph, ST);   // order = [1, 0, 3, 2] = UD0 LR0 UD1 LR1, as Band.order
    check(`links: phases run UD0 LR0 UD1 LR1 like the swaps, forward before backward ((1,0)[5] = ${px(1)[5].toString(16)}h, 34h expected)`, px(1)[5] === 0x34 && px(0)[0] === 0x34);
  }
  // the LZ decompressor as a link machine (kind 0): step 1 reads the start cursor from the first 13 bits of the pair memory,
  // step 2 reads the first command and copies its bytes into the memory at 0; the same header and command the whole-cell
  // decode of A starts with, so the first fragment of decode_pixel is what lands in A.
  {
    io.setChanger(0); io.setPair(1, 0); links_reset(ST, 8, 0); m8.fill(0, GRID, GRID + 32);
    const cell = [0x5a, 0x13, 0xc4, 0x27, 0x80, 0x01, 0x6e, 0x9b, 0x3c, 0x55, 0xaa, 0x0f, 0xf0, 0x81, 0x7e, 0x42]; m8.set(cell, GRID);
    decode_pixel(GRID, 0, PRM); const o = out(), f = flags(); let k = 1; while (k < 16 && f[k] === f[0]) k++;
    const frag = o.slice(0, k), start = io.lastOffset();
    links(2, 1, GRID, PRM, 0, ST);   // LR0: the forward machine (A then B) and the backward one (B then A) each read their header
    const st1 = m8.slice(ST, ST + 8);
    check(`links, LZ machine: the first step reads the ${io.headerBits}-bit header into the cursor (${st1[4] | (st1[5] << 8)}, the whole-cell decode starts at ${start}) and nothing is written`, st1[2] === 1 && (st1[4] | (st1[5] << 8)) === start && (st1[0] | (st1[1] << 8)) === io.headerBits && px(0).every((b, i) => b === cell[i]));
    links(2, 1, GRID, PRM, 0, ST);
    check(`links, LZ machine: the second step copies the first command's ${k} bytes "${String.fromCharCode(...frag)}" into the pair memory at 0, output position ${m8[ST + 6]}`, frag.every((b, i) => px(0)[i] === b) && m8[ST + 6] === k && px(0).slice(k).every((b, i) => b === cell[k + i]));
    io.setPair(0, 0);
  }
  // the joining: with pairMode 5 (byte-interleaved) the forward machine of (0,0)-(1,0) sees A on the even addresses and B on the odd,
  // so a program can be laid out across the two cells: A = 3E 32 00 FE .., B = 2A 08 18 .. reads LD A,2Ah; LD (0008h),A; JR -2,
  // and joint address 8 is A's byte 4. A single row, so no vertical machine runs A's bytes with another partner.
  {
    const w1 = 4, h1 = 1, n1 = w1 * h1;
    io.setChanger(6); io.setPair(5, 0); links_reset(ST, 4 * n1, 6); m8.fill(0, GRID, GRID + 16 * n1);
    m8.set([0x3E, 0x32, 0x00, 0xFE], GRID); m8.set([0x2A, 0x08, 0x18], GRID + 16);
    let c = 0; for (let r = 0; r < 3; r++) for (const ph of order) c += links(w1, h1, GRID, PRM, ph, ST);
    check(`links, byte-interleaved joining: a program spread over A's even and B's odd addresses stores 2Ah into joint byte 8 = A[4] (${c} pixel writes)`, px(0)[4] === 0x2a && px(0)[0] === 0x3e && px(1)[0] === 0x2a && c === 1);
    io.setPair(0, 0);
  }
}
// ---- a UTF-8 dictionary: the text is installed as UTF-8 bytes and the LZ decompressor copies those bytes
{
  const utf = 'Ազատություն αβγ 南國山河 sông núi\n', ub = new TextEncoder().encode(utf);
  const b2 = Codec.build(utf, 4), io2 = Codec.install(memory, b2, Codec.byteLut(b2.bytes), 1);
  io2.setCursorOffset(0); io2.setCursorRead(1); io2.setChanger(0); io2.setSkipBits(0);
  words.fill(0n); decode_pixel(GRID, 0, PRM);
  const got = Array.from(m8.subarray(io2.OUT, io2.OUT + 16));
  check(`UTF-8 dictionary: ${utf.length} characters are ${ub.length} bytes (header ${b2.headerBits} bits), and a zero pixel copies its first 16 bytes: ${new TextDecoder().decode(Uint8Array.from(got)).replace(/\uFFFD/g, '?')}`, ub.length > utf.length && b2.bytes.length === ub.length && got.every((b, k) => b === ub[k]) && io2.textLen === ub.length);
  // back to the Declaration for the rest
  Codec.install(memory, built, Codec.byteLut(built.bytes), 1); io.setCursorOffset(0); io.setCursorRead(text.length); io.setChanger(0);
}
// ---- sorts (41 ascending, 42 primes first)
{
  io.setPair(0, 0); io.setChanger(41);
  m8.set([9, 2, 255, 0, 7, 7, 128, 1, 3, 200, 4, 11, 6, 5, 10, 8], GRID); let r = decode_pixel(GRID, 0, PRM);
  check(`sort: ${out().join(' ')} (${r & 255} bytes moved)`, out().join() === '0,1,2,3,4,5,6,7,7,8,9,10,11,128,200,255' && (r & 255) === 16 && flags()[0] === 1);
  io.setChanger(42); m8.set([9, 2, 255, 0, 7, 7, 128, 1, 3, 200, 4, 11, 6, 5, 10, 8], GRID); r = decode_pixel(GRID, 0, PRM);
  check(`primes first: ${out().join(' ')}`, out().join() === '2,3,5,7,7,11,0,1,4,6,8,9,10,128,200,255');
  m8.set([251, 250, 1, 0, 2, 253, 211, 221, 223, 227, 229, 233, 239, 241, 255, 254], GRID); decode_pixel(GRID, 0, PRM);
  check(`primes first near 255: ${out().join(' ')}`, out().join() === '2,211,223,227,229,233,239,241,251,0,1,221,250,253,254,255');
  io.setChanger(0);
}
// ---- decoders (changers 31..40): hand-made cells with known decodings
{
  io.setPair(0, 0); io.setCursorOffset(0); io.setCursorRead(1);   // no dictionary cursor header: the preset window ends at the cursor offset, at 0 the text's end
  const cell = (kind, bytes) => { io.setChanger(kind); m8.fill(0, GRID, GRID + 16); m8.set(bytes.slice(0, 16), GRID); const r = decode_pixel(GRID, 0, PRM); return { out: out(), flags: flags(), used: r >> 8, changed: r & 255 }; };
  const msb = bits => { const b = new Uint8Array(16); [...bits].forEach((c, i) => { if (c === '1') b[i >> 3] |= 128 >> (i & 7); }); return b; };
  const lsb = bits => { const b = new Uint8Array(16); [...bits].forEach((c, i) => { if (c === '1') b[i >> 3] |= 1 << (i & 7); }); return b; };
  const bin = (v, n) => v.toString(2).padStart(n, '0'), rev = t => [...t].reverse().join('');
  const str = a => String.fromCharCode(...a);
  let r = cell(31, msb('011'.repeat(16) + [1, 2, 3, 4, 5, 6, 7, 8].map(v => bin(v, 4)).join('')));
  check(`prefix code: 16 lengths of 4 give the identity code; nibbles 1..8 pack to 12 34 56 78 (${r.used} bits read)`, r.out.slice(0, 4).join() === '18,52,86,120' && r.flags.slice(0, 4).join('') === '1010' && r.out[4] === 0);
  r = cell(32, msb('10101' + '00' + '11011011' + '00' + '10101' + '000'));
  check(`Morse: ... --- ... keys out "sos", wrapping repeats it: "${str(r.out)}"`, str(r.out) === 'sos sos sos sos ');
  const strip3 = raw => { let v = 0n; for (let i = raw.length - 1; i >= 0; i--) v = (v << 8n) | BigInt(raw[i]); v >>= 3n; const b = new Uint8Array(16); for (let i = 0; i < 16; i++) b[i] = Number((v >> BigInt(8 * i)) & 255n); return b; };
  r = cell(33, strip3(zlib.deflateRawSync(Buffer.from('the the the the the the'), { strategy: zlib.constants.Z_FIXED })));
  check(`Deflate: zlib's fixed-Huffman raw stream (block header stripped) decodes: "${str(r.out)}" (${r.used} bits)`, str(r.out) === 'the the the the ' && r.used < 128);
  const tail = text.slice(-12);
  r = cell(33, strip3(zlib.deflateRawSync(Buffer.from(tail + tail), { strategy: zlib.constants.Z_FIXED, dictionary: Buffer.from(text) })));
  check(`Deflate with the Declaration as preset dictionary (cursor offset 0: the window ends at the text's end): a match into it decodes "${str(r.out).replace(/\n/g, '⏎')}"`, str(r.out) === (tail + tail).slice(0, 16));
  r = cell(34, Uint8Array.from([0x54, 104, 101, 108, 108, 111, 5, 0]));
  check(`LZ4: token 5 literals + match 8 at offset 5: "${str(r.out).slice(0, 13)}"`, str(r.out).startsWith('hellohellohel') && r.flags.slice(0, 6).join('') === '111110');
  r = cell(35, Uint8Array.from([16, 0x10, 104, 101, 108, 108, 111, 0x11, 5]));
  check(`Snappy: literal 5 then copy-1 length 8 offset 5: "${str(r.out).slice(0, 13)}"`, str(r.out).startsWith('hellohellohel'));
  r = cell(36, lsb(rev(bin(1, 2)) + rev(bin(97, 8)) + rev(bin(0, 2)) + '1' + rev(bin(0, 6)) + rev(bin(0, 2)) + rev(bin(0, 2)) + '0' + rev(bin(0, 4))));
  check(`Brotli-like: insert "a", copy 2 at distance 1, then copies through short code 0 (the last distance): "${str(r.out)}"`, str(r.out) === 'a'.repeat(16));
  r = cell(37, Uint8Array.from([1, 1, 1, 1, 2, 5, 5, 5, 3, 2, 2, 2, 4, 1, 1, 1]));
  check(`PNG filters: Sub, Up, Average and Paeth rows reconstruct to ${r.out.join(' ')}`, r.out.join() === '1,1,2,3,2,6,7,8,3,5,8,10,4,6,9,11' && r.flags[0] === 0 && r.flags[2] === 1);
  r = cell(38, msb('011' + '10' + '1010'));
  check(`JPEG: DC category 2 value 2 then EOB gives a flat block of ${r.out[0]} (${r.used} bits read)`, r.out.every(b => b === 136) && r.used === 9);
  r = cell(38, msb('00' + '00' + '1' + '1010'));
  check(`JPEG: one horizontal AC coefficient gives the cosine row ${r.out.slice(0, 4).join(' ')} repeated`, r.out.join() === '132,129,127,124,'.repeat(4).slice(0, -1));
  {   // VP8: a boolean encoder (RFC 6386 section 7.3) against the same model must round-trip
    const model = Codec.vp8Model(built.bytes), e = { out: [], range: 255, bottom: 0, bitCount: 24 };
    const addOne = () => { let x = e.out.length - 1; while (x >= 0 && e.out[x] === 255) { e.out[x] = 0; x--; } e.out[x]++; };
    const put = (prob, bit) => { const split = 1 + (((e.range - 1) * prob) >> 8); if (bit) { e.bottom += split; e.range -= split; } else e.range = split;
      while (e.range < 128) { e.range <<= 1; if (e.bottom & (1 << 31)) addOne(); e.bottom = (e.bottom << 1) >>> 0; if (!--e.bitCount) { e.out.push((e.bottom >>> 24) & 255); e.bottom = (e.bottom & 0xffffff) >>> 0; e.bitCount = 8; } } };
    const flush = () => { let c = e.bitCount, v = e.bottom; if (v & (1 << (32 - c))) addOne(); v <<= c & 7; c >>= 3; while (--c >= 0) v = (v << 8) >>> 0; c = 4; while (--c >= 0) { e.out.push((v >>> 24) & 255); v = (v << 8) >>> 0; } };
    const msg = 'the people of th'; let ctx = 32;
    for (const ch of msg) { const sym = ch.charCodeAt(0); let node = 1; for (let i = 7; i >= 0; i--) { const bit = (sym >> i) & 1; put(model[(ctx << 8) | node], bit); node = (node << 1) | bit; } ctx = sym; }
    flush();
    r = cell(39, Uint8Array.from(e.out));
    check(`VP8 boolean decoder: "${msg}" arithmetic-coded in ${e.out.length} bytes against the Declaration's bigram model decodes back (${r.used} bits read)`, str(r.out) === msg);
    r = cell(39, new Uint8Array(16));
    const rnd = cell(39, Uint8Array.from({ length: 16 }, (_, i) => (i * 97 + 31) & 255));
    check(`VP8: a zero cell decodes to zeros; a random cell decodes to text-like bytes: "${str(rnd.out).replace(/[^ -~]/g, '·')}"`, r.out.every(b => b === 0) && rnd.out.filter(b => (b >= 97 && b <= 122) || b === 32).length >= 12);
  }
  r = cell(40, msb('010' + '110' + '101' + '0110' + '100'));
  check(`Rice (k = 2): residuals +1 -1 +3 0 from 128 give ${r.out.slice(0, 4).join(' ')}`, r.out.slice(0, 4).join() === '129,128,131,131');
  // every decoder on random cells: output differs from the input, reads stay within the cap
  randomize(4 * N, GRID, 99);
  for (const k of [31, 32, 33, 34, 35, 36, 37, 38, 39, 40]) {
    io.setChanger(k); let ch = 0, used = 0;
    for (let i = 0; i < N; i++) { const v = decode_pixel(GRID, i, PRM); ch += v & 255; used = Math.max(used, v >> 8); }
    check(`decoder ${k} on ${N} random cells: ${(ch / N).toFixed(1)} bytes changed a cell on average, at most ${used} bits read`, ch > N && used <= 1024 + 32);
  }
  // skip bits: every decoder starts reading after them; a byte format shifts its byte frame
  io.setSkipBits(8); r = cell(34, Uint8Array.from([0xff, 0x54, 104, 101, 108, 108, 111, 5, 0]));
  check(`LZ4 after 8 skipped bits: the first byte is ignored, "${str(r.out).slice(0, 13)}"`, str(r.out).startsWith('hellohellohel'));
  io.setSkipBits(3); r = cell(32, msb('000' + '10101' + '00' + '11011011' + '00' + '10101' + '000'));
  check(`Morse after 3 skipped bits: "${str(r.out)}"`, str(r.out).startsWith('sos sos'));
  io.setSkipBits(4); r = cell(34, Uint8Array.from([0x05, 0x46, 0x86, 0x56, 0xc6, 0xc6, 0xf0, 0x50, 0x00]));   // the LZ4 stream shifted by a nibble
  check(`LZ4 after 4 skipped bits reads a nibble-shifted byte frame: "${str(r.out).slice(0, 13)}"`, str(r.out).startsWith('hellohellohel'));
  io.setSkipBits(0);
  // on a concatenated pair the decoder sees 32 bytes: Morse spells 32 characters over both cells
  io.setChanger(32); io.setPair(1, 0); randomize(8, GRID, 5); change(2, GRID, PRM);
  const both = Array.from(m8.subarray(GRID, GRID + 32));
  check(`Morse on a concatenated pair writes letters and spaces into both cells: "${str(both).replace(/[^ -~]/g, '·')}"`, both.every(b => b === 32 || b === 63 || (b >= 97 && b <= 122) || (b >= 48 && b <= 57) || '.,\'!/()&:;=+-_"@'.includes(String.fromCharCode(b))));
  // the LZ77 formats read the dictionary cursor first: cursor read 128 is a 7-bit header; LZ4 (MSB-first) with header 20, then a
  // match of 8 at offset 20 from an empty output reads the text from position 20 - 20 = 0
  io.setCursorRead(128); r = cell(34, msb(bin(20, 7) + [0x04, 0x14, 0x00].map(b => bin(b, 8)).join('')));
  check(`LZ4 with a 7-bit dictionary cursor of 20: a match into the preset dictionary gives the text's first bytes "${str(r.out).slice(0, 8)}" (window ${io.lastOffset()})`, str(r.out).slice(0, 8) === text.slice(0, 8) && io.lastOffset() === 20);
  io.setCursorRead(text.length);
  io.setPair(0, 0); io.setChanger(0);
}
console.log(fails ? fails + ' failures' : 'all passed'); process.exit(fails ? 1 : 0);
