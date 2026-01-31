; This file, depurador.asm, is a commented disassembly of a Z80 assembly language debugger specifically designed 
; for "La abadía del crimen" onthe Amstrad CPC.
;
;  It appears to be a powerful debugging tool used during the game's development, containing code for:
;
;   * Loading and initialization: Setting up the debugger environment.
;   * User Interface: Displaying registers, memory dumps (both raw hex and disassembled instructions), and breakpoints.
;   * User Interaction: Handling keyboard input for various debugger commands, such as navigating memory, setting breakpoints, modifying
;     register values, and changing display modes.
;   * Disassembler: Interpreting Z80 machine code into human-readable mnemonics, including handling different instruction sets and operand
;     types.
;   * Memory and Register Manipulation: Functions to read from and write to memory locations and CPU registers.
;   * Text Rendering: Routines for drawing characters and controlling cursor position on the screen.
;
;  In essence, it's a comprehensive, in-game debugger that allowed the original developers to inspect and control the game's execution at a low
;  level.


; ------------ Commented disassembly of the debugger included with "La abadía del crimen", by Manuel Abadía  -----------
; the debugger starts loading at 0x6200. References to the debugger in the original code have been
; removed, but this debugger was probably used by Paco Menendez to debug the game.
; the debugger interacts with an expansion ROM that we don't have, so we don't know what code
; is received from the expansion ROM
; ------------------------------------------------------------------------------------------------------------------



; ------------------- code copied when loading the debugger ---------------------
; arrives here after returning from the program when the run program option has been pressed
0048: F5          push af
0049: 22 79 00    ld   ($0079),hl	; save af and hl
004C: E1          pop  hl
004D: 22 75 00    ld   ($0075),hl
0050: 3E 00       ld   a,$00		; modified with the counter
0052: D6 01       sub  $01			; decrement the counter
0054: 38 05       jr   c,$005B		; if counter is 0, jump

0056: 32 51 00    ld   ($0051),a	; if counter is not 0, decrement it and continue executing
0059: 18 19       jr   $0074

; arrive here if counter is 0
005B: 2A 75 00    ld   hl,($0075)	; recover af and hl
005E: E5          push hl
005F: 2A 79 00    ld   hl,($0079)
0062: F1          pop  af
0063: 00          nop				; modified from outside with the condition to push the condition register onto the stack
0064: E5          push hl
0065: E1          pop  hl
0066: 7D          ld   a,l
0067: E6 00       and  $00			; modified with the lower part of the condition mask
0069: EE 00       xor  $00			; modified with the lower part of the condition value
006B: 20 07       jr   nz,$0074		; if condition is not met, continue executing
006D: 7C          ld   a,h
006E: E6 00       and  $00			; modified with the upper part of the condition mask
0070: EE 00       xor  $00			; modified with the upper part of the condition value
0072: 28 0A       jr   z,$007E		; if condition is met, jump to debugger

; jump here to continue executing code
0074: 21 00 00    ld   hl,$0000		; recover af and hl
0077: E5          push hl
0078: 21 00 00    ld   hl,$0000
007B: F1          pop  af
007C: 00          nop				; here the value that was at the active breakpoint position is saved
007D: C9          ret				; jump to pc

; arrive here if 2 is pressed in the menu that appears when pressing escape in the debugger (jump to mons)
007E: 60          ld   h,b			; hl = bc
007F: 69          ld   l,c
0080: 01 C4 7F    ld   bc,$7FC4		; set configuration 4 (0, 4, 2, 3)
0083: ED 49       out  (c),c
0085: C3 6C 6C    jp   $6C6C		; show debugger

; jump here if J is pressed, after restoring registers, putting af in 0x0075-0x0076, putting hl in 0x0079-0x007a, and bc in hl
0088: 01 C0 7F    ld   bc,$7FC0
008B: ED 49       out  (c),c		; set configuration 0 (0, 1, 2, 3)
008D: 44          ld   b,h			; bc = hl
008E: 4D          ld   c,l
008F: 37          scf				; set carry flag to 1
0090: 38 09       jr   c,$009B		; changed from outside (jr c or jr nc), depending on active breakpoint address and pc

; if going to execute, recover hl and af and jump to PC
0092: 2A 75 00    ld   hl,($0075)
0095: E5          push hl
0096: 2A 79 00    ld   hl,($0079)
0099: F1          pop  af
009A: C9          ret

; arrive here if jumped to where a breakpoint was
009B: E1          pop  hl			; get return address and advance it by one unit
009C: 23          inc  hl
009D: E5          push hl
009E: 18 D4       jr   $0074		; execute code from next instruction

; return in a a byte read from hl setting original configuration (then restore debug configuration)
00A0: 01 C0 7F    ld   bc,$7FC0		; set configuration 0 (0, 1, 2, 3)
00A3: ED 49       out  (c),c
00A5: 7E          ld   a,(hl)

00A6: 0E C4       ld   c,$C4		; set configuration 4 (0, 4, 2, 3)
00A8: ED 49       out  (c),c
00AA: C9          ret

; set configuration 0 (0, 1, 2, 3), write a to hl and set configuration 4 (0, 4, 2, 3)
00AB: 01 C0 7F    ld   bc,$7FC0		; set configuration 0 (0, 1, 2, 3)
00AE: ED 49       out  (c),c
00B0: 77          ld   (hl),a		; modify a value
00B1: 18 F3       jr   $00A6

; arrive here if 1 is pressed in the menu that appears when pressing escape in the debugger (run program)
00B3: C1          pop  bc			; recover return address
00B4: 01 30 00    ld   bc,$0030
00B7: C5          push bc			; put 0x0030 as return address (where there is a jp 0x0048)
00B8: 3A 34 65    ld   a,($6534)	; get screen mode we were in
00BB: 01 8C 7F    ld   bc,$7F8C		; gate array -> 10001100 (select screen mode, rom config and int control)
00BE: B1          or   c			; disable upper and lower ROM
00BF: 4F          ld   c,a			; combine screen mode
00C0: ED 49       out  (c),c
00C2: 01 C0 7F    ld   bc,$7FC0		; set configuration 0 (0, 1, 2, 3)
00C5: ED 49       out  (c),c
00C7: C3 00 01    jp   $0100		; jump to program start

; set configuration 5 (0, 5, 2, 3), copy 0x4000 bytes from hl to de and set configuration 4 (0, 4, 2, 3)
00CA: 01 C5 7F    ld   bc,$7FC5		; set configuration 5 (0, 5, 2, 3)
00CD: ED 49       out  (c),c
00CF: 01 00 40    ld   bc,$4000		; 0x4000 bytes
00D2: ED B0       ldir
00D4: 01 C4 7F    ld   bc,$7FC4		; set configuration 4 (0, 4, 2, 3)
00D7: ED 49       out  (c),c
00D9: C9          ret
00DA-00FF: 00
; ------------------- end of code copied when loading the debugger ---------------------
; mnemonic table (separated by 0x0d)
4000: 	0x00 -> nop
		0x01 -> ld bc,G
		0x02 -> ld (bc),a
 		0x03 -> inc bc
 		0x04 -> inc b
 		0x05 -> dec b
 		0x06 -> ld b,N
 		0x07 -> rlca
 		0x08 -> ex af,af'
 		0x09 -> add,I,bc
 		0x0a -> ld a,(bc)
 		0x0b -> dec bc
 		0x0c -> inc c
 		0x0d -> dec c
 		0x0e -> ld c,N
 		0x0f -> rrca
 		0x10 -> djnz D
 		0x11 -> ld de,G
 		0x12 -> ld (de),a
 		0x13 -> inc de
 		0x14 -> inc d
 		0x15 -> dec d
 		0x16 -> ld d,N
 		0x17 -> rla
 		0x18 -> jr D
 		0x19 -> add I,de
 		0x1a -> ld a,(de)
 		0x1b -> dec de
 		0x1c -> inc e
 		0x1d -> dec e
  		0x1e -> ld e,N
 		0x1f -> rra
 		0x20 -> jr nz,D
 		0x21 -> ld I,G
 		0x22 -> ld (G),I
 		0x23 -> inc I
 		0x24 -> inc h
 		0x25 -> dec h
 		0x26 -> ld h,N
 		0x27 -> daa
 		0x28 -> jr z,D
 		0x29 -> add I,I
 		0x2a -> ld I,(G)
 		0x2b -> dec I
 		0x2c -> inc l
 		0x2d -> dec l
 		0x2e -> ld l,N
 		0x2f -> cpl
 		0x30 -> jr nc,D
 		0x31 -> ld sp,G
 		0x32 -> ld (G),a
 		0x33 -> inc sp
 		0x34 -> inc (H)
 		0x35 -> dec (H)
 		0x36 -> ld (H),N
 		0x37 -> scf
 		0x38 -> jr c,D
 		0x39 -> add I,sp
 		0x3a -> ld a,(G)
 		0x3b -> dec sp
 		0x3c -> inc a
 		0x3d -> dec a
 		0x3e -> ld a,N
 		0x3f -> ccf
 		0x40 -> ld b,b
 		0x41 -> ld b,c
 		0x42 -> ld b,d
		0x43 -> ld b,d
		0x44 -> ld b,h
 		0x45 -> ld b,l
 		0x46 -> ld b,(H)
 		0x47 -> ld b,a
 		0x48 -> ld c,b
 		0x49 -> ld c,c
 		0x4a -> ld c,d
 		0x4b -> ld c,e
 		0x4c -> ld c,h
 		0x4d -> ld c,l
 		0x4e -> ld c,(H)
 		0x4f -> ld c,a
 		0x50 -> ld d,b
 		0x51 -> ld d,c
 		0x52 -> ld d,d
 		0x53 -> ld d,e
 		0x54 -> ld d,h
 		0x55 -> ld d,l
 		0x56 -> ld d,(H)
 		0x57 -> ld d,a
 		0x58 -> ld e,b
 		0x59 -> ld e,c
 		0x5a -> ld e,d
 		0x5b -> ld e,e
		0x5c -> ld e,h
 		0x5d -> ld e,l
  		0x5e -> ld e,(H)
 		0x5f -> ld e,a
 		0x60 -> ld h,b
 		0x61 -> ld h,c
 		0x62 -> ld h,d
 		0x63 -> ld h,e
 		0x64 -> ld h,h
 		0x65 -> ld h,l
 		0x66 -> ld h,(H)
 		0x67 -> ld h,a
 		0x68 -> ld l,b
 		0x69 -> ld l,c
 		0x6a -> ld l,d
 		0x6b -> ld l,e
 		0x6c -> ld l,h
 		0x6d -> ld l,l
 		0x6e -> ld l,(H)
 		0x6f -> ld (H),a
 		0x70 -> ld (H),b
 		0x71 -> ld (H),c
 		0x72 -> ld (H),d
 		0x73 -> ld (H),e
 		0x74 -> ld (H),h
 		0x75 -> ld (H),l
 		0x76 -> halt
 		0x77 -> ld (H),a
 		0x78 -> ld a,b
 		0x79 -> ld a,c
 		0x7a -> ld a,d
 		0x7b -> ld a,e
 		0x7c -> ld a,h
  		0x7d -> ld a,l
  		0x7e -> ld a,(H)
  		0x7f -> ld a,a
  		0x80 -> add a,b
  		0x81 -> add a,c
  		0x82 -> add a,d
  		0x83 -> add a,e
  		0x84 -> add a,h
  		0x85 -> add a,l
  		0x86 -> add a,(H)
  		0x87 -> add a,a
  		0x88 -> adc a,b
  		0x89 -> adc a,c
  		0x8a -> adc a,d
  		0x8b -> adc a,e
  		0x8c -> adc a,h
  		0x8d -> adc a,l
  		0x8e -> adc a,(H)
  		0x8f -> adc a,a
  		0x90 -> sub b
  		0x91 -> sub c
  		0x92 -> sub d
  		0x93 -> sub e
  		0x94 -> sub h
  		0x95 -> sub l
  		0x96 -> sub (H)
  		0x97 -> sub a
  		0x98 -> sbc a,b
  		0x99 -> sbc a,c
  		0x9a -> sbc a,d
  		0x9b -> sbc a,e
  		0x9c -> sbc a,h
  		0x9d -> sbc a,l
  		0x9e -> sbc a,(H)
  		0x9f -> sbc a,a
  		0xa0 -> and b
  		0xa1 -> and c
  		0xa2 -> and d
  		0xa3 -> and e
  		0xa4 -> and h
  		0xa5 -> and l
  		0xa6 -> and (H)
  		0xa7 -> and a
  		0xa8 -> xor b
  		0xa9 -> xor c
  		0xaa -> xor d
  		0xab -> xor e
  		0xac -> xor h
  		0xad -> xor l
  		0xae -> xor (H)
  		0xaf -> xor a
  		0xb0 -> or b
  		0xb1 -> or c
  		0xb2 -> or d
  		0xb3 -> or e
  		0xb4 -> or h
  		0xb5 -> or l
  		0xb6 -> or (H)
  		0xb7 -> or a
  		0xb8 -> cp b
  		0xb9 -> cp c
  		0xba -> cp d
  		0xbb -> cp e
  		0xbc -> cp h
  		0xbd -> cp l
  		0xbe -> cp (H)
  		0xbf -> cp a
  		0xc0 -> ret nz
  		0xc1 -> pop bc
  		0xc2 -> jp nz,G
  		0xc3 -> jp G
  		0xc4 -> call nz,G
  		0xc5 -> push bc
  		0xc6 -> add a,N
  		0xc7 -> rst 0
  		0xc8 -> ret z
  		0xc9 -> ret
  		0xca -> jp z,G
  		0xcb -> C
  		0xcc -> call z,G
  		0xcd -> call G
  		0xce -> adc a,N
  		0xcf -> rst 8
  		0xd0 -> ret nc
  		0xd1 -> pop de
  		0xd2 -> jp nc,G
  		0xd3 -> out (N),a
  		0xd4 -> call nc,G
  		0xd5 -> push de
  		0xd6 -> sub N
  		0xd7 -> rst 16
  		0xd8 -> ret c
  		0xd9 -> exx
  		0xda -> jp c,G
  		0xdb -> in a,(N)
  		0xdc -> call c,G
  		0xdd -> X
  		0xde -> sbc a,N
  		0xdf -> rst 24
  		0xe0 -> ret po
  		0xe1 -> pop I
  		0xe2 -> jp po,G
  		0xe3 -> ex (sp),I
  		0xe4 -> call po,G
  		0xe5 -> push I
  		0xe6 -> and N
  		0xe7 -> rst 32
  		0xe8 -> ret pe
  		0xe9 -> jp (I)
  		0xea -> jp pe,G
  		0xeb -> ex de,I
  		0xec -> call pe,G
  		0xed -> E
  		0xee -> xor N
  		0xef -> rst 40
  		0xf0 -> ret p
  		0xf1 -> pop af
  		0xf2 -> jp p,G
  		0xf3 -> di
  		0xf4 -> call p,G
  		0xf5 -> push af
  		0xf6 -> or n
  		0xf7 -> rst 48
  		0xf8 -> ret m
  		0xf9 -> ld sp,I
  		0xfa -> jp m,G
  		0xfb -> ei
  		0xfc -> call m,G
  		0xfd -> Y
  		0xfe -> cp N
  		0xff -> rst 56

466E-4A37: 00

; auxiliary mnemonic table for 0xcb (type C) (separated by 0x0d)
4A38: 	0x00 -> rlc b
		0x01 -> rlc c
		0x02 -> rlc d
		0x03 -> rlc e
		0x04 -> rlc h
		0x05 -> rlc l
		0x06 -> rlc (H)
		0x07 -> rlc a
		0x08 -> rrc b
		0x09 -> rrc c
		0x0a -> rrc d
		0x0b -> rrc e
		0x0c -> rrc h
		0x0d -> rrc l
		0x0e -> rr c (H)
		0x0f -> rrc a
		0x10 -> rl b
 		0x11 -> rl c
		0x12 -> rl d
		0x13 -> rl e
		0x14 -> rl h
		0x15 -> rl l
		0x16 -> rl (H)
 		0x17 -> rl a
		0x18 -> rr b
		0x19 -> rr c
		0x1a -> rr d
		0x1b -> rr e
		0x1c -> rr h
		0x1d -> rr l
		0x1e -> rr (H)
		0x1f -> rr a
		0x20 -> sla b
		0x21 -> sla c
		0x22 -> sla d
		0x23 -> sla e
		0x24 -> sla h
		0x25 -> sl a l
		0x26 -> sla (H)
		0x27 -> sla a
		0x28 -> sra b
		0x29 -> sra c
		0x2a -> sra d
		0x2b -> sra e
		0x2c -> sra h
		0x2d -> sra l
		0x2e -> sra (H)
		0x2f -> sra a
		0x30 ->
		0x31 ->
		0x32 ->
		0x33 ->
		0x34 ->
		0x35 ->
		0x36 ->
		0x37 ->
		0x38 -> srl b
		0x39 -> srl c
		0x3a -> srl d
		0x3b -> srl e
		0x3c -> srl h
		0x3d -> srl l
		0x3e -> srl (H)
		0x3f -> srl a
		0x40 -> bit 0,b
		0x41 -> bit 0,c
		0x42 -> bit 0,d
		0x43 -> bit 0,e
		0x44 -> bit 0,h
		0x45 -> bit 0,l
		0x46 -> bit 0,(H)
		0x47 -> bit 0,a
		0x48 -> bit 1,b
		0x49 -> bit 1,c
		0x4a -> bit 1,d
		0x4b -> bit 1,e
		0x4c -> bit 1,h
		0x4d -> bit 1,l
		0x4e -> bit 1,(H)
		0x4f -> bit 1,a
		0x50 -> bit 2,b
		0x51 -> bit 2,c
		0x52 -> bit 2,d
		0x53 -> bit 2,e
		0x54 -> bit 2,h
		0x55 -> bit 2,l
		0x56 -> bit 2,(H)
		0x57 -> bit 2,a
		0x58 -> bit 3,b
		0x59 -> bit 3,c
		0x5a -> bit 3,d
		0x5b -> bit 3,e
		0x5c -> bit 3,h
		0x5d -> bit 3,l
		0x5e -> bit 3,(H)
		0x5f -> bit 3,a
		0x60 -> bit 4,b
		0x61 -> bit 4,c
		0x62 -> bit 4,d
		0x63 -> bit 4,e
		0x64 -> bit 4,h
		0x65 -> bit 4,l
		0x66 -> bit 4,(H)
		0x67 -> bit 4,a
		0x68 -> bit 5,b
		0x69 -> bit 5,c
		0x6a -> bit 5,d
		0x6b -> bit 5,e
		0x6c -> bit 5,h
		0x6d -> bit 5,l
		0x6e -> bit 5,(H)
		0x6f -> bit 5,a
		0x70 -> bit 6,b
		0x71 -> bit 6,c
		0x72 -> bit 6,d
		0x73 -> bit 6,e
		0x74 -> bit 6,h
		0x75 -> bit 6,l
		0x76 -> bit 6,(H)
		0x77 -> bit 6,a
		0x78 -> bit 7,b
		0x79 -> bit 7,c
		0x7a -> bit 7,d
		0x7b -> bit 7,e
		0x7c -> bit 7,h
		0x7d -> bit 7,l
		0x7e -> bit 7,(H)
		0x7f -> bit 7,a
		0x80 -> res 0,b
		0x81 -> res 0,c
		0x82 -> res 0,d
		0x83 -> res 0,e
		0x84 -> res 0,h
		0x85 -> res 0,l
		0x86 -> res 0,(H)
		0x87 -> res 0,a
		0x88 -> res 1,b
		0x89 -> res 1,c
		0x8a -> res 1,d
		0x8b -> res 1,e
		0x8c -> res 1,h
		0x8d -> res 1,l
		0x8e -> res 1,(H)
		0x8f -> res 1,a
		0x90 -> res 2,b
		0x91 -> res 2,c
		0x92 -> res 2,d
		0x93 -> res 2,e
		0x94 -> res 2,h
		0x95 -> res 2,l
		0x96 -> res 2,(H)
		0x97 -> res 2,a
		0x98 -> res 3,b
		0x99 -> res 3,c
		0x9a -> res 3,d
		0x9b -> res 3,e
		0x9c -> res 3,h
		0x9d -> res 3,l
		0x9e -> res 3,(H)
		0x9f -> res 3,a
		0xa0 -> res 4,b
		0xa1 -> res 4,c
		0xa2 -> res 4,d
		0xa3 -> res 4,e
		0xa4 -> res 4,h
		0xa5 -> res 4,l
		0xa6 -> res 4,(H)
		0xa7 -> res 4,a
		0xa8 -> res 5,b
		0xa9 -> res 5,c
		0xaa -> res 5,d
		0xab -> res 5,e
		0xac -> res 5,h
		0xad -> res 5,l
		0xae -> res 5,(H)
		0xaf -> res 5,a
		0xb0 -> res 6,b
		0xb1 -> res 6,c
		0xb2 -> res 6,d
		0xb3 -> res 6,e
		0xb4 -> res 6,h
		0xb5 -> res 6,l
		0xb6 -> res 6,(H)
		0xb7 -> res 6,a
		0xb8 -> res 7,b
		0xb9 -> res 7,c
		0xba -> res 7,d
		0xbb -> res 7,e
		0xbc -> res 7,h
		0xbd -> res 7,l
		0xbe -> res 7,(H)
		0xbf -> res 7,a
		0xc0 -> set 0,b
		0xc1 -> set 0,c
		0xc2 -> set 0,d
		0xc3 -> set 0,e
		0xc4 -> set 0,h
		0xc5 -> set 0,l
		0xc6 -> set 0,(H)
		0xc7 -> set 0,a
		0xc8 -> set 1,b
		0xc9 -> set 1,c
		0xca -> set 1,d
		0xcb -> set 1,e
		0xcc -> set 1,h
		0xcd -> set 1,l
		0xce -> set 1,(H)
		0xcf -> set 1,a
		0xd0 -> set 2,b
		0xd1 -> set 2,c
		0xd2 -> set 2,d
		0xd3 -> set 2,e
		0xd4 -> set 2,h
		0xd5 -> set 2,l
		0xd6 -> set 2,(H)
		0xd7 -> set 2,a
		0xd8 -> set 3,b
		0xd9 -> set 3,c
		0xda -> set 3,d
		0xdb -> set 3,e
		0xdc -> set 3,h
		0xdd -> set 3,l
		0xde -> set 3,(H)
		0xdf -> set 3,a
		0xe0 -> set 4,b
		0xe1 -> set 4,c
		0xe2 -> set 4,d
		0xe3 -> set 4,e
		0xe4 -> set 4,h
		0xe5 -> set 4,l
		0xe6 -> set 4,(H)
		0xe7 -> set 4,a
		0xe8 -> set 5,b
		0xe9 -> set 5,c
		0xea -> set 5,d
		0xeb -> set 5,e
		0xec -> set 5,h
		0xed -> set 5,l
		0xee -> set 5,(H)
		0xef -> set 5,a
		0xf0 -> set 6,b
		0xf1 -> set 6,c
		0xf2 -> set 6,d
		0xf3 -> set 6,e
		0xf4 -> set 6,h
		0xf5 -> set 6,l
		0xf6 -> set 6,(H)
		0xf7 -> set 6,a
		0xf8 -> set 7,b
		0xf9 -> set 7,c
		0xfa -> set 7,d
		0xfb -> set 7,e
		0xfc -> set 7,h
		0xfd -> set 7,l
		0xfe -> set 7,(H)
		0xff -> set 7,a

51BE-5207: 00

; auxiliary mnemonic table for 0xed (type E) (separated by 0x0d)
5208: 	0x40 -> in b,(c)
		0x41 -> out (c),b
		0x42 -> sbc hl,bc
		0x43 -> ld (G),bc
		0x44 -> neg
		0x45 -> retn
		0x46 -> im 0
		0x47 -> ldi,a
		0x48 -> in (c),c
		0x49 -> out (c),c
		0x4a -> adc hl,bc
		0x4b -> ld bc,(G)
		0x4c ->
		0x4d -> reti
		0x4e ->
		0x4f -> ld r,a
		0x50 -> in d,(c)
		0x51 -> out (c),d
		0x52 -> sbc hl,de
		0x53 -> ld (G),de
		0x54 ->
		0x55 ->
		0x56 -> im 1
		0x57 -> ld a,i
		0x58 -> in e,(c)
		0x59 -> out (c),e
		0x5a -> adc hl,de
		0x5b -> ld de,(G)
		0x5c ->
		0x5d ->
		0x5e -> im 2
		0x5f -> ld a,r
		0x60 -> in h,(c)
		0x61 -> out (c),h
		0x62 -> sbc hl,hl
		0x63 -> ld (G),hl
		0x64 ->
		0x65 ->
		0x66 ->
		0x67 -> rrd
		0x68 -> in l,(c)
		0x69 -> out (c),l
		0x6a -> adc hl,hl
		0x6b -> ld hl,(G)
		0x6c ->
		0x6d ->
		0x6e ->
		0x6f -> rld
		0x70 -> in f,(c)
		0x71 ->
		0x72 -> sbc hl,sp
		0x73 -> ld (G),hl
		0x74 ->
		0x75 ->
		0x76 ->
		0x77 ->
		0x78 -> in a,(c)
		0x79 -> out (c),a
		0x7a -> adc hl,sp
		0x7b -> ld sp,(G)
		0x7c ->
		0x7d ->
		0x7e ->
		0x7f ->
		0x80 ->
		0x81 ->
		0x82 ->
		0x83 ->
		0x84 ->
		0x85 ->
		0x86 ->
		0x87 ->
		0x88 ->
		0x89 ->
		0x8a ->
		0x8b ->
		0x8c ->
		0x8d ->
		0x8e ->
		0x8f ->
		0x90 ->
		0x91 ->
		0x92 ->
		0x93 ->
		0x94 ->
		0x95 ->
		0x96 ->
		0x97 ->
		0x98 ->
		0x99 ->
		0x9a ->
		0x9b ->
		0x9c ->
		0x9d ->
		0x9e ->
		0x9f ->
		0xa0 -> ldi
		0xa1 -> cpi
		0xa2 -> ini
		0xa3 -> outi
		0xa4 ->
		0xa5 ->
		0xa6 ->
		0xa7 ->
		0xa8 -> ldd
		0xa9 -> cpd
		0xaa -> ind
		0xab -> outd
		0xac ->
		0xad ->
		0xae ->
		0xaf ->
		0xb0 -> ldir
		0xb1 -> cpir
		0xb2 -> inir
		0xb3 -> otir
		0xb4 ->
		0xb5 ->
		0xb6 ->
		0xb7 ->
		0xb8 -> lddr
		0xb9 -> cpdr
		0xba -> indr
		0xbb -> otdr

5403-59D7: 00

; character table (each character occupies 8 bytes)
59D8: 	00 00 00 00 00 00 00 00 -> 0x20 (' ')
		18 18 18 18 18 00 18 00 -> 0x21 ('!')
		6C 6C 6C 00 00 00 00 00 -> 0x22 ('"')
 		6C 6C FE 6C FE 6C 6C 00 -> 0x23 ('#')
 		18 3E 58 3C 1A 7C 18 00 -> 0x24 ('$')
 		00 C6 CC 18 30 66 C6 00 -> 0x25 ('%')
 		38 6C 38 76 DC CC 76 00 -> 0x26 ('&')
 		18 18 30 00 00 00 00 00 -> 0x27 (''')
 		0C 18 30 30 30 18 0C 00 -> 0x28 ('(')
 		30 18 0C 0C 0C 18 30 00 -> 0x29 (')')
 		00 66 3C FF 3C 66 00 00 -> 0x2a ('*')
 		00 18 18 7E 18 18 00 00 -> 0x2b ('+')
 		00 00 00 00 00 18 18 30 -> 0x2c (',')
 		00 00 00 7E 00 00 00 00 -> 0x2d ('-')
 		00 00 00 00 00 18 18 00 -> 0x2e ('.')
 		06 0C 18 30 60 C0 80 00 -> 0x2f ('/')
 		7C C6 CE D6 E6 C6 7C 00 -> 0x30 ('0')
 		18 38 18 18 18 18 7E 00 -> 0x31 ('1')
 		3C 66 06 3C 60 66 7E 00 -> 0x32 ('2')
 		3C 66 06 1C 06 66 3C 00 -> 0x33 ('3')
 		1C 3C 6C CC FE 0C 1E 00 -> 0x34 ('4')
 		7E 62 60 7C 06 66 3C 00 -> 0x35 ('5')
 		3C 66 60 7C 66 66 3C 00 -> 0x36 ('6')
 		7E 66 06 0C 18 18 18 00 -> 0x37 ('7')
 		3C 66 66 3C 66 66 3C 00 -> 0x38 ('8')
 		3C 66 66 3E 06 66 3C 00 -> 0x39 ('9')
 		00 00 18 18 00 18 18 00 -> 0x3a (':')
 		00 00 18 18 00 18 18 30 -> 0x3b (';')
 		0C 18 30 60 30 18 0C 00 -> 0x3c ('<')
 		00 00 7E 00 00 7E 00 00 -> 0x3d ('=')
 		60 30 18 0C 18 30 60 00 -> 0x3e ('>')
 		3C 66 66 0C 18 00 18 00 -> 0x3f ('?')
 		7C C6 DE DE DE C0 7C 00 -> 0x40 ('@')
 		18 3C 66 66 7E 66 66 00 -> 0x41 ('A')
 		FC 66 66 7C 66 66 FC 00 -> 0x42 ('B')
 		3C 66 C0 C0 C0 66 3C 00 -> 0x43 ('C')
 		F8 6C 66 66 66 6C F8 00 -> 0x44 ('D')
 		FE 62 68 78 68 62 FE 00 -> 0x45 ('E')
 		FE 62 68 78 68 60 F0 00 -> 0x46 ('F')
 		3C 66 C0 C0 CE 66 3E 00 -> 0x47 ('G')
 		66 66 66 7E 66 66 66 00 -> 0x48 ('H')
 		7E 18 18 18 18 18 7E 00 -> 0x49 ('I')
 		1E 0C 0C 0C CC CC 78 00 -> 0x4a ('J')
 		E6 66 6C 78 6C 66 E6 00 -> 0x4b ('K')
 		F0 60 60 60 62 66 FE 00 -> 0x4c ('L')
 		C6 EE FE FE D6 C6 C6 00 -> 0x4d ('M')
 		C6 E6 F6 DE CE C6 C6 00 -> 0x4e ('N')
 		38 6C C6 C6 C6 6C 38 00 -> 0x4f ('O')
 		FC 66 66 7C 60 60 F0 00 -> 0x50 ('P')
 		38 6C C6 C6 DA CC 76 00 -> 0x51 ('Q')
 		FC 66 66 7C 6C 66 E6 00 -> 0x52 ('R')
 		3C 66 60 3C 06 66 3C 00 -> 0x53 ('S')
 		7E 5A 18 18 18 18 3C 00 -> 0x54 ('T')
 		66 66 66 66 66 66 3C 00 -> 0x55 ('U')
 		66 66 66 66 66 3C 18 00 -> 0x56 ('V')
 		C6 C6 C6 D6 FE EE C6 00 -> 0x57 ('W')
 		C6 6C 38 38 6C C6 C6 00 -> 0x58 ('X')
 		66 66 66 3C 18 18 3C 00 -> 0x59 ('Y')
 		FE C6 8C 18 32 66 FE 00 -> 0x5a ('Z')
 		3C 30 30 30 30 30 3C 00 -> 0x5b ('[')
 		C0 60 30 18 0C 06 02 00 -> 0x5c ('\')
 		3C 0C 0C 0C 0C 0C 3C 00 -> 0x5d (']')
 		18 3C 7E 18 18 18 18 00 -> 0x5e ('^')
        00 00 00 00 00 00 00 FF -> 0x5f ('_')
 		30 18 0C 00 00 00 00 00 -> 0x60 ('`')
 		00 00 78 0C 7C CC 76 00 -> 0x61 ('a')
 		E0 60 7C 66 66 66 DC 00 -> 0x62 ('b')
 		00 00 3C 66 60 66 3C 00 -> 0x63 ('c')
 		1C 0C 7C CC CC CC 76 00 -> 0x64 ('d')
 		00 00 3C 66 7E 60 3C 00 -> 0x65 ('e')
 		1C 36 30 78 30 30 78 00 -> 0x66 ('f')
 		00 00 3E 66 66 3E 06 7C -> 0x67 ('g')
		E0 60 6C 76 66 66 E6 00 -> 0x68 ('h')
 		18 00 38 18 18 18 3C 00 -> 0x69 ('i')
 		06 00 0E 06 06 66 66 3C -> 0x6a ('j')
 		E0 60 66 6C 78 6C E6 00 -> 0x6b ('k')
 		38 18 18 18 18 18 3C 00 -> 0x6c ('l')
 		00 00 6C FE D6 D6 C6 00 -> 0x6d ('m')
 		00 00 DC 66 66 66 66 00 -> 0x6e ('n')
 		00 00 3C 66 66 66 3C 00 -> 0x6f ('o')
 		00 00 DC 66 66 7C 60 F0 -> 0x70 ('p')
 		00 00 76 CC CC 7C 0C 1E -> 0x71 ('q')
 		00 00 DC 76 60 60 F0 00 -> 0x72 ('r')
 		00 00 3C 60 3C 06 7C 00 -> 0x73 ('s')
 		30 30 7C 30 30 36 1C 00 -> 0x74 ('t')
 		00 00 66 66 66 66 3E 00 -> 0x75 ('u')
 		00 00 66 66 66 3C 18 00 -> 0x76 ('v')
 		00 00 C6 D6 D6 FE 6C 00 -> 0x77 ('w')
 		00 00 C6 6C 38 6C C6 00 -> 0x78 ('x')
 		00 00 66 66 66 3E 06 7C -> 0x79 ('y')
 		00 00 7E 4C 18 32 7E 00 -> 0x7a ('z')
 		0E 18 18 70 18 18 0E 00 -> 0x7b ('{')
 		18 18 18 18 18 18 18 00 -> 0x7c ('|')
 		70 18 18 0E 18 18 70 00 -> 0x7d ('}')
 		76 DC 00 00 00 00 00 00 -> 0x7e ('~')
 		CC 33 CC 33 CC 33 CC 33 -> 0x7f (fill character)

5CD8-61FF:00

; -------------------- start of debugger loading code ---------------------------------
6200: 11 48 00    ld   de,$0048		; points to destination
6203: 01 B4 00    ld   bc,$00B4		; number of bytes to copy
6206: 21 26 6E    ld   hl,$6E26		; points to code to copy
6209: ED B0       ldir				; performs the copy

620B: 3E C3       ld   a,$C3
620D: 32 30 00    ld   ($0030),a	; changes the code at 0x30 (rst 0x30) so it jumps to 0x0048
6210: 21 48 00    ld   hl,$0048
6213: 22 31 00    ld   ($0031),hl

6216: 21 7C 00    ld   hl,$007C
6219: 22 36 65    ld   ($6536),hl	; sets 0x007c as active break point
621C: C3 7E 00    jp   $007E		; loads abadia5.bin at 0x4000 and jumps to 0x6c6c
; -------------------- end of debugger loading code ---------------------------------

; this code is never called
621F: 06 0F       ld   b,$0F
6221: 21 01 00    ld   hl,$0001
6224: DD 21 01 00 ld   ix,$0001
6228: FD 21 01 00 ld   iy,$0001
622C: 11 14 00    ld   de,$0014
622F: 3E 07       ld   a,$07
6231: 23          inc  hl
6232: DD 23       inc  ix
6234: FD 23       inc  iy
6236: 1B          dec  de
6237: 10 F8       djnz $6231
6239: C9          ret

; ----------------------------------- main debugger code ---------------------------------------------
; once the debugger has started it jumps here
623A: CD 12 67    call $6712		; displays registers and their values, indicates which is selected
623D: CD F5 69    call $69F5		; writes the prompt
6240: CD 80 6B    call $6B80		; prints the state of the break points (and if any is active, its address)
6243: 21 00 00    ld   hl,$0000		; hl = 0
6246: 5D          ld   e,l			; de = 0
6247: 55          ld   d,l
6248: CD B8 6A    call $6AB8		; saves and prints the current condition
624B: CD 42 6B    call $6B42		; writes the counter
624E: CD 60 64    call $6460		; displays a dump of memory from an area or the code in that memory area
6251: CD 34 68    call $6834		; displays the 3 columns of the bottom part of the screen with memory dump

; debugger main loop
6254: DD 21 83 62 ld   ix,$6283		; points to the key table and routines to call
6258: 3E 42       ld   a,$42
625A: CD 98 63    call $6398		; checks if escape was pressed
625D: C2 52 6D    jp   nz,$6D52		; if escape was pressed, jump
6260: DD 7E 00    ld   a,(ix+$00)	; reads a key
6263: FE FF       cp   $FF
6265: 28 ED       jr   z,$6254		; if the last one has been reached, jump

6267: CD 98 63    call $6398		; checks if the read key was pressed
626A: 20 08       jr   nz,$6274		; if pressed, jump
626C: DD 23       inc  ix			; advances to the next entry
626E: DD 23       inc  ix
6270: DD 23       inc  ix
6272: 18 EC       jr   $6260		; continues testing the rest of the keys

; arrives here if a key from the list has been pressed
6274: DD 6E 01    ld   l,(ix+$01)	; gets the address of the routine associated with the key
6277: DD 66 02    ld   h,(ix+$02)
627A: 11 54 62    ld   de,$6254
627D: D5          push de			; pushes the return address onto the stack
627E: ED 73 C3 62 ld   ($62C3),sp
6282: E9          jp   (hl)			; jumps to the corresponding routine

; key table and routines to call (each entry takes 3 bytes)
6283: 	02 6427 -> cursor down -> advances one memory position
		00 642C -> cursor up -> goes back one memory position
		08 6436 -> cursor left -> goes back 8 memory positions
		01 6431 -> cursor right -> advances 8 memory positions
		26 69DA -> 'M' -> moves to the memory position that is entered
		07 67BD -> '.' -> advances circularly the selected register
		32 6BE6 -> 'R' -> modifies the selected register with the entered value
		33 6C0E -> 'T' -> copies bytes from source to destination
		40 6A1E -> '1' -> sets break point 1 at the current memory address
		41 6B5C -> '2' -> sets break point 2 at the current memory address
		10 6A45 -> 'CLR' -> clears the break points
		23 63E0 -> 'I' -> asks for a value and modifies what is at the current memory address
		43 6B28 -> 'Q' -> modifies the counter
		1B 6A60 -> 'P' -> modifies the condition of the active break point
		2D 6A01 -> 'J' -> reads the jump address (0 was where it stopped), restores registers and jumps
		35 6458 -> 'F' -> changes what is shown on the right (the disassembled code or the memory)
		2F 63FF -> space -> advances the current position according to what the current instruction takes up
		FF
; ------------------------------- end of main debugger code -----------------------------------------

; ------------------------ code for writing characters and positioning the cursor -------------------------
; puts the cursor at the position indicated by hl (h = x position, l = y position) (origin = 1,1)
62B7: 25          dec  h
62B8: 2D          dec  l
62B9: 7D          ld   a,l
62BA: 6C          ld   l,h
62BB: 67          ld   h,a
62BC: 22 C0 62    ld   ($62C0),hl
62BF: C9          ret

62C0: 35 ; cursor x position
62C1: 13 ; cursor y position
62C2: 00 ; operating mode for the routine at 0x62c5

62C3-62C4: stack saved here

; if 0x62c2 is 0, writes the character passed in a, if it is 1, sets the cursor x position, and if it is 2, sets the cursor y position
; special characters: 0x1f -> changes state and waits for the cursor position to be passed
; special characters: 0x0d -> carriage return
; special characters: 0x0a -> line feed
; special characters: 0x08 -> move back the cursor x position
; special characters: 0x18 -> invert text color
; special characters: 0x12 -> clear to end of line
62C5: C5          push bc
62C6: 4F          ld   c,a			; saves the parameter in c
62C7: 3A C2 62    ld   a,($62C2)	; reads the function to perform
62CA: FE 01       cp   $01
62CC: 20 0B       jr   nz,$62D9		; if not 1, jump

; arrives here if 0x62c2 == 0x01, with c = routine parameter
62CE: 3C          inc  a
62CF: 32 C2 62    ld   ($62C2),a	; changes state to set y position
62D2: 79          ld   a,c			; restores the parameter
62D3: 3D          dec  a
62D4: 32 C0 62    ld   ($62C0),a	; sets cursor x position
62D7: C1          pop  bc
62D8: C9          ret

; arrives here if 0x62c2 != 0x01
62D9: FE 02       cp   $02
62DB: 20 0B       jr   nz,$62E8		; if not 2, jump

; arrives here if 0x62c2 == 0x02, with c = routine parameter
62DD: AF          xor  a
62DE: 32 C2 62    ld   ($62C2),a	; changes state to print a character
62E1: 79          ld   a,c			; reads the parameter
62E2: 3D          dec  a
62E3: 32 C1 62    ld   ($62C1),a	; sets cursor y position
62E6: C1          pop  bc
62E7: C9          ret

; arrives here if 0x62c2 == 0, with c = parameter
62E8: 79          ld   a,c			; reads the character
62E9: FE 20       cp   $20
62EB: 38 1F       jr   c,$630C		; if it is a non-printable character, jump
62ED: D6 20       sub  $20			; otherwise adjusts the number for the character table
62EF: E5          push hl
62F0: D5          push de
62F1: CD 6B 63    call $636B		; given a character in a, returns in de a pointer to the data that forms the character and in hl the screen position where it should be written
62F4: 06 08       ld   b,$08		; 8 lines
62F6: 1A          ld   a,(de)		; reads 8 pixels of the character
62F7: EE 00       xor  $00			; modified instruction from outside (in case you want to change the color)
62F9: 77          ld   (hl),a		; writes 8 pixels to screen
62FA: 7C          ld   a,h
62FB: C6 08       add  a,$08		; moves to the next screen line
62FD: 67          ld   h,a
62FE: 13          inc  de
62FF: 10 F5       djnz $62F6		; completes the 8 lines
6301: 3A C0 62    ld   a,($62C0)	; advances the cursor 8 pixels
6304: 3C          inc  a
6305: 32 C0 62    ld   ($62C0),a
6308: D1          pop  de
6309: E1          pop  hl
630A: C1          pop  bc
630B: C9          ret

; arrives here if it is a non-printable character
630C: C1          pop  bc
630D: FE 1F       cp   $1F
630F: 20 06       jr   nz,$6317		; if character '?' is passed, changes state and waits for new cursor positions
6311: 3E 01       ld   a,$01
6313: 32 C2 62    ld   ($62C2),a
6316: C9          ret

6317: FE 0D       cp   $0D			; if CR (carriage return) is read
6319: 20 05       jr   nz,$6320
631B: AF          xor  a
631C: 32 C0 62    ld   ($62C0),a	; moves to position 0 in x
631F: C9          ret

6320: FE 0A       cp   $0A			; if LF (line feed) is read
6322: 20 08       jr   nz,$632C
6324: 3A C1 62    ld   a,($62C1)
6327: 3C          inc  a
6328: 32 C1 62    ld   ($62C1),a	; moves to the next line
632B: C9          ret

632C: FE 08       cp   $08			; if BS (backspace) is read
632E: 20 08       jr   nz,$6338
6330: 3A C0 62    ld   a,($62C0)	; moves back the cursor position in x
6333: 3D          dec  a
6334: 32 C0 62    ld   ($62C0),a
6337: C9          ret

6338: FE 18       cp   $18			; if 0x18 is read
633A: 20 08       jr   nz,$6344
633C: 3A F8 62    ld   a,($62F8)	; changes the text color
633F: 2F          cpl
6340: 32 F8 62    ld   ($62F8),a
6343: C9          ret

6344: FE 12       cp   $12			; if 0x12 is read, clears from x position to end of line
6346: C0          ret  nz			; otherwise, exits

6347: C5          push bc
6348: E5          push hl
6349: D5          push de
634A: CD 6B 63    call $636B		; given a character in a, returns in de a pointer to the data that forms the character and in hl the screen position where it should be written
634D: 3A C0 62    ld   a,($62C0)	; reads cursor x position
6350: ED 44       neg
6352: C6 50       add  a,$50
6354: 28 B2       jr   z,$6308		; if it has reached the end of the line in x, exits

; clears what remains until reaching the end of the line
6356: 4F          ld   c,a			; c = 80 - pos x
6357: 06 08       ld   b,$08		; 8 lines high
6359: C5          push bc
635A: E5          push hl
635B: 36 00       ld   (hl),$00		; clears 8 pixels
635D: 23          inc  hl
635E: 0D          dec  c
635F: 20 FA       jr   nz,$635B		; repeats until reaching the end of this line
6361: E1          pop  hl
6362: 7C          ld   a,h
6363: C6 08       add  a,$08		; moves to the next screen line
6365: 67          ld   h,a
6366: C1          pop  bc
6367: 10 F0       djnz $6359		; repeats for 8 lines
6369: 18 9D       jr   $6308

; given a character in a, returns in de a pointer to the data that forms the character and in hl the screen position where it should be written
636B: 6F          ld   l,a
636C: 26 00       ld   h,$00		; hl = a
636E: 29          add  hl,hl
636F: 29          add  hl,hl
6370: 29          add  hl,hl		; hl = a*8 (each character takes 8 bytes)
6371: 11 D8 59    ld   de,$59D8		; de points to the character table
6374: 19          add  hl,de		; indexes in the table
6375: EB          ex   de,hl		; de = character data
6376: 21 00 00    ld   hl,$0000
6379: 3A C1 62    ld   a,($62C1)	; reads cursor y position
637C: A7          and  a			; a = b7 b6 b5 b4 b3 b2 b1 b0
637D: 1F          rra				; a = 0 b7 b6 b5 b4 b3 b2 b1, CF = b0
637E: CB 1D       rr   l			; l = b0 0 0 0 0 0 0 0
6380: 1F          rra				; a = 0 0 b7 b6 b5 b4 b3 b2, CF = b1
6381: CB 1D       rr   l			; l = b1 b0 0 0 0 0 0 0
6383: 47          ld   b,a			; b = 0 0 b7 b6 b5 b4 b3 b2, CF = 0
6384: 4D          ld   c,l			; c = b1 b0 0 0 0 0 0 0
6385: 1F          rra				; a = 0 0 0 b7 b6 b5 b4 b3, CF = b2
6386: CB 1D       rr   l			; l = b2 b1 b0 0 0 0 0 0
6388: 1F          rra				; a = 0 0 0 0 b7 b6 b5 b4, CF = b3
6389: CB 1D       rr   l			; l = b3 b2 b1 b0 0 0 0 0
638B: F6 C0       or   $C0			; a = 1 1 0 0 b7 b6 b5 b4
638D: 67          ld   h,a			; hl = 1 1 0  0  b7 b6 b5 b4  b2 b1 b0 0 0 0 0 0
									; bc = 0 0 b7 b6 b5 b4 b3 b2  b1 b0 0  0 0 0 0 0
638E: 09          add  hl,bc
638F: 3A C0 62    ld   a,($62C0)	; reads cursor x position
6392: 85          add  a,l
6393: 6F          ld   l,a
6394: 8C          adc  a,h
6395: 95          sub  l
6396: 67          ld   h,a			; hl = hl + a
6397: C9          ret
; ------------------------ end of code for writing characters and positioning cursor -------------------------

; ------------------------ code related to key pressing --------------------------------
; checks if key a was pressed. if pressed returns NZ
6398: F3          di
6399: C5          push bc
639A: F5          push af
639B: 01 0E F4    ld   bc,$F40E		; 1111 0100 0000 1110 (8255 PPI port A)
639E: ED 49       out  (c),c
63A0: 06 F6       ld   b,$F6
63A2: ED 78       in   a,(c)
63A4: E6 30       and  $30
63A6: 4F          ld   c,a
63A7: F6 C0       or   $C0
63A9: ED 79       out  (c),a		; PSG operation write register index (activates 14 for communication via port A)
63AB: ED 49       out  (c),c		; PSG operation: inactive
63AD: 04          inc  b			; points to the 8255 PPI control port
63AE: 3E 92       ld   a,$92
63B0: ED 79       out  (c),a		; 1001 0010 (port A: input, port B: input, port C upper: output, port C lower: output)
63B2: F1          pop  af
63B3: C5          push bc

63B4: 47          ld   b,a			; b = key to check
63B5: E6 07       and  $07			; gets the bit of the line to check
63B7: 87          add  a,a
63B8: 87          add  a,a
63B9: 87          add  a,a
63BA: F6 47       or   $47
63BC: 32 DD 63    ld   ($63DD),a	; modifies an instruction to check the corresponding bit
63BF: 78          ld   a,b			; reads the key to check
63C0: 0F          rrca
63C1: 0F          rrca
63C2: 0F          rrca
63C3: E6 0F       and  $0F			; finds the corresponding line
63C5: B1          or   c
63C6: F6 40       or   $40
63C8: 4F          ld   c,a
63C9: 06 F6       ld   b,$F6		; PSG operation: read register data (line a)
63CB: ED 49       out  (c),c
63CD: 06 F4       ld   b,$F4
63CF: ED 78       in   a,(c)
63D1: C1          pop  bc
63D2: F5          push af			; saves the read line
63D3: 3E 82       ld   a,$82
63D5: ED 79       out  (c),a		; 1001 0010 (port A: output, port B: input, port C upper: output, port C lower: output)
63D7: 05          dec  b
63D8: ED 49       out  (c),c		; PSG operation: inactive
63DA: F1          pop  af			; recovers the read line
63DB: 2F          cpl				; pressed keys are now 1
63DC: CB 57       bit  2,a			; modified instruction from outside to check the corresponding bit
63DE: C1          pop  bc
63DF: C9          ret
; ------------------------ end of code related to key pressing --------------------------------

; arrives here if 'I' was pressed
63E0: CD 72 65    call $6572		; calls the character printing routine and position change routine according to values after the call
		1F 30 14 -> changes cursor to position (0x30, 0x14)
		49 3A 20 5F 08 FF -> I: _ (and moves cursor back one position)
63EC: CD 01 69    call $6901		; reads up to 20 keyboard characters and interprets them as binary or hexadecimal to return the number converted in hl
63EF: 7D          ld   a,l			; saves the last 2 read digits
63F0: 2A 22 65    ld   hl,($6522)	; gets the current memory address
63F3: CD AB 00    call $00AB		; sets config 0 (0, 1, 2, 3), writes a in hl and sets config 4 (0, 4, 2, 3)
63F6: CD 60 64    call $6460		; displays a dump of memory from an area or the code in that memory area
63F9: CD 34 68    call $6834		; displays the 3 columns of the bottom part of the screen with memory dump
63FC: C3 F5 69    jp   $69F5		; writes the prompt

; arrives here if space was pressed
63FF: CD F5 69    call $69F5		; writes the prompt
6402: DD 2A 22 65 ld   ix,($6522)	; gets the current memory address
6406: CD 8F 65    call $658F		; reads an instruction and displays the associated mnemonic on screen
6409: CD F5 69    call $69F5		; writes the prompt
640C: 3A 2D 65    ld   a,($652D)	; increments the address with the length of the instruction
640F: 3C          inc  a
6410: 2A 22 65    ld   hl,($6522)
6413: 85          add  a,l
6414: 6F          ld   l,a
6415: 8C          adc  a,h
6416: 95          sub  l
6417: 67          ld   h,a
6418: 22 22 65    ld   ($6522),hl
641B: CD 60 64    call $6460		; displays a dump of memory from an area or the code in that memory area
641E: 3E 2F       ld   a,$2F
6420: CD 98 63    call $6398		; checks if key a was pressed
6423: CA 34 68    jp   z,$6834		; if space was released, displays the 3 columns of the bottom part of the screen with memory dump
6426: C9          ret

; arrives here if cursor down was pressed
6427: 11 01 00    ld   de,$0001		; offset = 1
642A: 18 0D       jr   $6439		; offsets the current memory position and updates

; arrives here if cursor up was pressed
642C: 11 FF FF    ld   de,$FFFF		; offset = -1
642F: 18 08       jr   $6439		; offsets the current memory position and updates

; arrives here if cursor right was pressed
6431: 11 08 00    ld   de,$0008		; offset = 8
6434: 18 03       jr   $6439		; offsets the current memory position and updates

; arrives here if cursor left was pressed
6436: 11 F8 FF    ld   de,$FFF8		; offset = -8

6439: 2A 22 65    ld   hl,($6522)	; gets the current address from which it disassembles and displays the dump
643C: 19          add  hl,de		; adds the offset and updates it
643D: 22 22 65    ld   ($6522),hl
6440: CD 34 68    call $6834		; displays the 3 columns of the bottom part of the screen with memory dump
6443: 3E 17       ld   a,$17
6445: CD 98 63    call $6398		; checks if control was pressed
6448: 01 98 3A    ld   bc,$3A98
644B: CC 6C 65    call z,$656C		; if not pressed, does a small delay until bc is 0
644E: DD 7E 00    ld   a,(ix+$00)
6451: CD 98 63    call $6398		; checks if key a was pressed
6454: CA 60 64    jp   z,$6460		; if the key that led to this routine has been released, displays a dump of the memory
6457: C9          ret				; from an area or the code in that memory area

; arrives here if 'F' was pressed
6458: 3A 35 65    ld   a,($6535)	; changes what is shown on the right (the disassembled code or the memory)
645B: EE 01       xor  $01
645D: 32 35 65    ld   ($6535),a

; displays a dump of memory from an area or the code in that memory area
6460: 3A 35 65    ld   a,($6535)	; reads whether to show memory or disassemble code
6463: A7          and  a
6464: 28 56       jr   z,$64BC		; if disassemble code, jump

; arrives here to show memory
6466: 21 03 2A    ld   hl,$2A03		; initial cursor position
6469: ED 5B 22 65 ld   de,($6522)	; gets the initial memory address to show
646D: 06 0C       ld   b,$0C		; shows 12 lines of memory
646F: C5          push bc
6470: E5          push hl
6471: CD B7 62    call $62B7		; puts cursor at position indicated by hl (h = x position, l = y position)
6474: 7A          ld   a,d
6475: CD FC 65    call $65FC		; prints d
6478: 7B          ld   a,e
6479: CD FC 65    call $65FC		; prints e
647C: 3E 20       ld   a,$20
647E: CD C5 62    call $62C5		; prints a space
6481: 3E 20       ld   a,$20
6483: CD C5 62    call $62C5		; prints a space

6486: 06 08       ld   b,$08		; 8 bytes
6488: D5          push de
6489: EB          ex   de,hl
648A: C5          push bc
648B: CD A0 00    call $00A0		; returns in a a byte read from hl setting the original config (then restores debug config)
648E: CD FC 65    call $65FC		; given a number in a, prints in the current position the hexadecimal value of the number
6491: 3E 20       ld   a,$20
6493: CD C5 62    call $62C5		; prints a space
6496: 23          inc  hl
6497: C1          pop  bc
6498: 10 F0       djnz $648A		; continues printing the 8 bytes
649A: E1          pop  hl

649B: 3E 20       ld   a,$20
649D: CD C5 62    call $62C5		; prints a space
64A0: 06 08       ld   b,$08		; 8 bytes
64A2: C5          push bc
64A3: CD A0 00    call $00A0		; returns in a a byte read from hl setting the original config (then restores debug config)
64A6: E6 7F       and  $7F
64A8: FE 20       cp   $20
64AA: 30 02       jr   nc,$64AE		; if not a printable character, displays it
64AC: 3E 2E       ld   a,$2E		; otherwise shows a '.'
64AE: CD C5 62    call $62C5
64B1: 23          inc  hl
64B2: C1          pop  bc
64B3: 10 ED       djnz $64A2		; completes the 8 bytes

64B5: EB          ex   de,hl
64B6: E1          pop  hl
64B7: 2C          inc  l			; advances cursor to next line
64B8: C1          pop  bc
64B9: 10 B4       djnz $646F		; repeats until completing the 12 lines
64BB: C9          ret

; arrives here if code should be disassembled
64BC: DD 2A 22 65 ld   ix,($6522)	; gets the memory address of the first instruction
64C0: CD 72 65    call $6572		; calls the character printing routine and position change routine according to values after the call
		1F 01 0C FF -> changes cursor position to (0x01, 0x0c)
64C7: 06 0C       ld   b,$0C		; 12 lines
64C9: 21 03 2A    ld   hl,$2A03		; initial cursor position
64CC: C5          push bc
64CD: E5          push hl
64CE: CD D7 64    call $64D7		; changes cursor position, disassembles an instruction and displays the instruction address, the bytes that form it and its mnemonic
64D1: E1          pop  hl
64D2: 2C          inc  l			; advances cursor to next line
64D3: C1          pop  bc
64D4: 10 F6       djnz $64CC		; completes the 12 lines
64D6: C9          ret

; changes cursor position, disassembles an instruction and displays the address of the instruction, the bytes that form it and its mnemonic
64D7: DD E5       push ix
64D9: E5          push hl
64DA: CD B7 62    call $62B7		; puts cursor at position indicated by hl (h = x position, l = y position)
64DD: 3E 12       ld   a,$12
64DF: CD C5 62    call $62C5		; clears to end of line
64E2: E1          pop  hl
64E3: E5          push hl
64E4: 7C          ld   a,h
64E5: C6 16       add  a,$16		; advances 16 positions in x
64E7: 67          ld   h,a
64E8: CD B7 62    call $62B7		; puts cursor at position indicated by hl (h = x position, l = y position)
64EB: CD 8F 65    call $658F		; reads an instruction and displays the associated mnemonic on screen
64EE: E1          pop  hl
64EF: CD B7 62    call $62B7		; puts cursor at position indicated by hl (h = x position, l = y position)
64F2: 3E 20       ld   a,$20
64F4: CD C5 62    call $62C5		; prints a blank space
64F7: 3E 20       ld   a,$20
64F9: CD C5 62    call $62C5		; prints a blank space
64FC: E1          pop  hl
64FD: 7C          ld   a,h
64FE: CD FC 65    call $65FC		; prints the instruction address
6501: 7D          ld   a,l
6502: CD FC 65    call $65FC
6505: 3E 20       ld   a,$20
6507: CD C5 62    call $62C5		; prints a blank space
650A: 3A 2D 65    ld   a,($652D)	; reads the bytes read in the instruction
650D: 3C          inc  a
650E: 47          ld   b,a			; repeats the length of the instruction (bytes read + 1)
650F: C5          push bc
6510: 3E 20       ld   a,$20
6512: CD C5 62    call $62C5		; writes a space
6515: CD A0 00    call $00A0		; returns in a a byte read from hl setting the original config (then restores debug config)
6518: CD FC 65    call $65FC		; given a number in a, prints in the current position the hexadecimal value of the number
651B: 23          inc  hl
651C: C1          pop  bc
651D: 10 F0       djnz $650F		; completes the instruction bytes
651F: DD 23       inc  ix
6521: C9          ret

6522-6537: used to store debugger data

; used to compare mnemonics and process them (each entry has 3 bytes)
6538: 	44  66B0 -> D
		43  66D6 -> C
		4E  6620 -> N
		59  6686 -> Y
		58  665C -> X
		47  65E3 -> G
		48  6641 -> H
		49  662E -> I
		45  66F2 -> E
		FF

6554-656B: used to store debugger data

; small delay until bc is 0
656C: 0B          dec  bc
656D: 78          ld   a,b
656E: B1          or   c
656F: 20 FB       jr   nz,$656C
6571: C9          ret

; calls the character printing routine and position change routine according to values after the call
6572: E1          pop  hl			; gets the return address
6573: 7E          ld   a,(hl)		; reads the parameter and saves the new return address
6574: 23          inc  hl
6575: E5          push hl
6576: FE FF       cp   $FF			; if 0xff is read, exits
6578: C8          ret  z
6579: E6 7F       and  $7F			; adjusts the character to 0x00-0x7f
657B: CD C5 62    call $62C5		; if 0x62c2 is 0, writes the character passed in a, if it is 1, sets cursor x position, and if it is 2, sets cursor y position
657E: 18 F2       jr   $6572		; repeats until 0xff is found

; advances hl until finding mnemonic number a
6580: 2A 24 65    ld   hl,($6524)	; gets the pointer to mnemonic strings
6583: A7          and  a
6584: C8          ret  z			; if a is 0, exits
6585: 47          ld   b,a			; repeats a times
6586: 7E          ld   a,(hl)		; reads a byte from hl
6587: 23          inc  hl
6588: FE 0D       cp   $0D			; repeats until 0x0d character is found
658A: 20 FA       jr   nz,$6586
658C: 10 F8       djnz $6586
658E: C9          ret

; reads an instruction and displays the associated mnemonic on screen
658F: 21 3D 66    ld   hl,$663D		; hl points to the hl string
6592: 22 26 65    ld   ($6526),hl	; initializes string 1 to hl
6595: 22 28 65    ld   ($6528),hl   ; initializes string 2 to hl
6598: 21 00 40    ld   hl,$4000
659B: 22 24 65    ld   ($6524),hl	; initializes the pointer to mnemonic strings
659E: AF          xor  a
659F: 32 56 66    ld   ($6656),a	; initially there is a nop in this routine
65A2: 32 2C 65    ld   ($652C),a	; indicates that so far no instruction with ix++ or iy++ has been processed
65A5: 32 2D 65    ld   ($652D),a	; sets the number of bytes read to 0

; sometimes arrives here when processing a mnemonic letter
65A8: DD E5       push ix
65AA: E3          ex   (sp),hl		; exchanges hl and stack contents
65AB: CD A0 00    call $00A0		; returns in a a byte read from hl setting the original config (then restores debug config)
65AE: E1          pop  hl			; recovers what was written
65AF: CD 80 65    call $6580		; advances hl until finding mnemonic number a

; sometimes arrives here when processing a mnemonic letter
65B2: 7E          ld   a,(hl)		; reads a byte of the mnemonic
65B3: 22 2A 65    ld   ($652A),hl	; saves the current mnemonic position
65B6: 11 38 65    ld   de,$6538		; de points to a table with letters and related routines
65B9: EB          ex   de,hl

65BA: BE          cp   (hl)			; compares first mnemonic letter with table value
65BB: 28 13       jr   z,$65D0		; if match, jump
65BD: CB 7E       bit  7,(hl)
65BF: 20 05       jr   nz,$65C6		; if bit 7 is set, jump (end of table)
65C1: 23          inc  hl
65C2: 23          inc  hl
65C3: 23          inc  hl
65C4: 18 F4       jr   $65BA		; advances to next entry and continues checking

65C6: FE 0D       cp   $0D			; if end of table was reached and mnemonic end (0x0d) was found, exits
65C8: C8          ret  z

65C9: CD C5 62    call $62C5		; writes the read character
65CC: EB          ex   de,hl
65CD: 23          inc  hl
65CE: 18 E2       jr   $65B2		; continues analyzing next byte

; arrives here if a table letter was found
65D0: 01 DD 65    ld   bc,$65DD
65D3: C5          push bc			; saves the return address
65D4: 23          inc  hl
65D5: 7E          ld   a,(hl)		; hl = address associated with the letter in the table
65D6: 23          inc  hl
65D7: 66          ld   h,(hl)
65D8: 6F          ld   l,a
65D9: 11 2D 65    ld   de,$652D		; de points to address where number of bytes read from instruction is stored
65DC: E9          jp   (hl)			; jumps to corresponding routine to handle the specific case

; usually arrives here after executing specific code from a table entry (though sometimes changes return address)
65DD: 2A 2A 65    ld   hl,($652A)	; hl = pointer to mnemonic string
65E0: 23          inc  hl			; advances to next position
65E1: 18 CF       jr   $65B2		; continues processing the mnemonic

; routine that processes mnemonics with a G, printing (in hexadecimal) the next 2 bytes
65E3: EB          ex   de,hl
65E4: 34          inc  (hl)			; indicates it took 2 bytes
65E5: 34          inc  (hl)
65E6: DD 23       inc  ix			; advances to next instruction byte
65E8: DD E5       push ix
65EA: E3          ex   (sp),hl
65EB: 23          inc  hl
65EC: CD A0 00    call $00A0		; returns in a a byte read from hl setting the original config (then restores debug config)
65EF: E1          pop  hl
65F0: CD FC 65    call $65FC		; given a number in a, prints in the current position the hexadecimal value of the number
65F3: DD E5       push ix
65F5: E3          ex   (sp),hl
65F6: CD A0 00    call $00A0		; returns in a a byte read from hl setting the original config (then restores debug config)
65F9: E1          pop  hl
65FA: DD 23       inc  ix			; advances to next instruction byte

; given a number in a, prints in the current position the hexadecimal value of the number
65FC: CD 07 66    call $6607		; returns in bc the 2 ASCII characters representing the number passed in a in hexadecimal
65FF: 79          ld   a,c
6600: CD C5 62    call $62C5		; writes the most significant digit to screen
6603: 78          ld   a,b
6604: C3 C5 62    jp   $62C5		; writes the least significant digit to screen

; returns in bc the 2 ASCII characters representing the number passed in a in hexadecimal
6607: 4F          ld   c,a
6608: CD 16 66    call $6616	; converts the 4 least significant bits of a into a printable hexadecimal digit
660B: 47          ld   b,a		; saves the least significant digit in b
660C: 79          ld   a,c
660D: 0F          rrca
660E: 0F          rrca
660F: 0F          rrca
6610: 0F          rrca
6611: CD 16 66    call $6616	; converts the 4 least significant bits of a into a printable hexadecimal digit
6614: 4F          ld   c,a		; saves the most significant digit in c
6615: C9          ret

; converts the 4 least significant bits of a into a printable hexadecimal digit
6616: E6 0F       and  $0F
6618: C6 30       add  a,$30
661A: FE 3A       cp   $3A
661C: D8          ret  c
661D: C6 07       add  a,$07
661F: C9          ret

; routine that processes mnemonics with an N, printing the hexadecimal number of the following byte
6620: DD 23       inc  ix			; advances to next instruction byte
6622: EB          ex   de,hl
6623: 34          inc  (hl)			; indicates it took a byte
6624: DD E5       push ix
6626: DD E3       ex   (sp),ix
6628: CD A0 00    call $00A0		; returns in a a byte read from hl setting the original config (then restores debug config)
662B: E1          pop  hl
662C: 18 CE       jr   $65FC		; given a number in a, prints in the current position the hexadecimal value of the number

; routine that processes mnemonics with an I, printing a string for loading a register with a value
662E: 2A 26 65    ld   hl,($6526)	; reads the string of the register to load
6631: E5          push hl
6632: C3 72 65    jp   $6572		; calls the character printing routine and position change routine according to values after the call
		69 78 FF -> ix
6638: C9          ret

		69 79 FF -> iy

663C: C9          ret

		68 6C FF -> hl

6640: C9          ret

; routine that processes mnemonics with an H, printing a register string
6641: 2A 28 65    ld   hl,($6528)	; gets the pointer to the string to display
6644: E5          push hl
6645: C3 72 65    jp   $6572		; calls the character printing routine and position change routine according to values after the call
		69 78 2B 00 00 FF -> ix+
664E: 18 06       jr   $6656

		69 79 2B 00 00 FF -> iy+

6656: 00          nop				; modified instruction from outside (nop or ret)
6657: DD 23       inc  ix
6659: EB          ex   de,hl
665A: 34          inc  (hl)			; indicates it took a byte
665B: C9          ret

; routine that processes mnemonics with an X, copies the next byte to the ix+ string and continues processing instructions
665C: 3E 01       ld   a,$01
665E: 32 2C 65    ld   ($652C),a	; indicates that an instruction with ix++ or iy++ has been processed
6661: 21 35 66    ld   hl,$6635		; points to the ix string
6664: 22 26 65    ld   ($6526),hl
6667: 21 48 66    ld   hl,$6648		; points to the ix+ string
666A: 22 28 65    ld   ($6528),hl
666D: DD E5       push ix
666F: E3          ex   (sp),hl
6670: 23          inc  hl			; skips 2 bytes of the instruction
6671: 23          inc  hl
6672: CD A0 00    call $00A0		; returns in a a byte read from hl setting the original config (then restores debug config)
6675: E1          pop  hl
6676: CD 07 66    call $6607		; returns in bc the 2 ASCII characters representing the number passed in a in hexadecimal
6679: ED 43 4B 66 ld   ($664B),bc	; saves the 2 characters in the ix+ string forming ix+XX
667D: DD 23       inc  ix
667F: EB          ex   de,hl
6680: 34          inc  (hl)			; indicates it took a byte
6681: 21 A8 65    ld   hl,$65A8		; changes the return address so it continues processing the command
6684: E3          ex   (sp),hl
6685: C9          ret

; routine that processes mnemonics with a Y, copies the next byte to the iy+ string and continues processing instructions
6686: 3E 01       ld   a,$01
6688: 32 2C 65    ld   ($652C),a	; indicates that an instruction with ix++ or iy++ has been processed
668B: 21 39 66    ld   hl,$6639		; points to the iy string
668E: 22 26 65    ld   ($6526),hl
6691: 21 50 66    ld   hl,$6650		; points to the iy+ string
6694: 22 28 65    ld   ($6528),hl
6697: DD E5       push ix
6699: E3          ex   (sp),hl
669A: 23          inc  hl			; skips 2 bytes of the instruction
669B: 23          inc  hl
669C: CD A0 00    call $00A0		; returns in a a byte read from hl setting the original config (then restores debug config)
669F: E1          pop  hl
66A0: CD 07 66    call $6607		; returns in bc the 2 ASCII characters representing the number passed in a in hexadecimal
66A3: ED 43 53 66 ld   ($6653),bc	; saves the 2 characters in the iy+ string forming iy+XX
66A7: DD 23       inc  ix
66A9: EB          ex   de,hl
66AA: 34          inc  (hl)			; indicates it took a byte
66AB: 21 A8 65    ld   hl,$65A8
66AE: E3          ex   (sp),hl
66AF: C9          ret				; changes the return address so it continues processing the command

; routine that processes mnemonics with a D, calculates the jump address and prints it
66B0: DD E5       push ix
66B2: E1          pop  hl			; hl = ix
66B3: 23          inc  hl
66B4: 23          inc  hl			; hl points to next instruction address
66B5: DD 23       inc  ix			; advances to the offset
66B7: DD E5       push ix
66B9: E3          ex   (sp),hl
66BA: CD A0 00    call $00A0		; returns in a a byte read from hl setting the original config (then restores debug config)
66BD: E1          pop  hl			; recovers next instruction address
66BE: CB 7F       bit  7,a
66C0: 20 07       jr   nz,$66C9		; if it is a jump with negative offset, jump
66C2: 85          add  a,l
66C3: 6F          ld   l,a
66C4: 8C          adc  a,h
66C5: 95          sub  l
66C6: 67          ld   h,a			; hl = hl + a
66C7: 18 05       jr   $66CE

; arrives here if it is a jump with negative offset
66C9: 85          add  a,l			; adds negative offset taking carry into account
66CA: 6F          ld   l,a
66CB: 38 01       jr   c,$66CE
66CD: 25          dec  h
66CE: 7C          ld   a,h
66CF: CD FC 65    call $65FC		; prints the first byte of the jump address
66D2: 7D          ld   a,l
66D3: C3 FC 65    jp   $65FC		; prints the second byte of the jump address

; routine that processes mnemonics with a C
66D6: 21 38 4A    ld   hl,$4A38		; points to the table of strings with phrases for bit operations
66D9: 22 24 65    ld   ($6524),hl	; sets the address from which to get mnemonics
66DC: 21 A8 65    ld   hl,$65A8		; changes the return address to continue processing commands
66DF: E3          ex   (sp),hl
66E0: 3A 2C 65    ld   a,($652C)	; checks if an instruction with ix++ or iy++ has been processed
66E3: DD 23       inc  ix			; advances to next instruction byte
66E5: EB          ex   de,hl
66E6: 34          inc  (hl)			; indicates it took a byte
66E7: A7          and  a			; if no instruction with ix++ or iy++ has been processed, exits
66E8: C8          ret  z

; arrives here if an instruction with ix++ or iy++ has been processed
66E9: DD 23       inc  ix
66EB: 34          inc  (hl)			; indicates it took another byte
66EC: 3E C9       ld   a,$C9
66EE: 32 56 66    ld   ($6656),a	; puts a ret in a routine (so it doesn't indicate it took another byte)
66F1: C9          ret

; routine that processes mnemonics with an E
66F2: 21 08 52    ld   hl,$5208		; points to the table of strings with phrases for operations starting with 0xed
66F5: 22 24 65    ld   ($6524),hl	; sets the address from which to get mnemonics
66F8: E1          pop  hl
66F9: DD 23       inc  ix			; advances to next instruction byte
66FB: EB          ex   de,hl
66FC: 34          inc  (hl)
66FD: DD E5       push ix
66FF: E3          ex   (sp),hl
6700: CD A0 00    call $00A0		; returns in a a byte read from hl setting the original config (then restores debug config)
6703: E1          pop  hl
6704: D6 40       sub  $40			; if read byte is < 0x40, exits
6706: D8          ret  c
6707: FE 7C       cp   $7C			; if read byte is >= 0xbc, exits
6709: D0          ret  nc
670A: 21 B2 65    ld   hl,$65B2		; sets the return address
670D: E5          push hl
670E: CD 80 65    call $6580		; advances hl until finding mnemonic number a
6711: C9          ret

; displays registers and their values, indicates which is selected
6712: DD 21 54 65 ld   ix,$6554		; points to the address where registers are stored
6716: CD 72 65    call $6572		; calls the character printing routine and position change routine according to values after the call
		1F 01 03 FF -> places cursor at (1, 3)
671D: 06 0A       ld   b,$0A		; 10 16-bit registers
671F: C5          push bc
6720: CD D2 67    call $67D2		; writes 6 spaces, 4 hexadecimal digits corresponding to what is in ix (which loads it in hl) and 3 spaces

6723: 06 09       ld   b,$09		; 9 memory positions starting from where the register points
6725: C5          push bc
6726: CD A0 00    call $00A0		; returns in a a byte read from hl setting the original config (then restores debug config)
6729: CD FC 65    call $65FC		; given a number in a, prints in the current position the hexadecimal value of the number
672C: 3E 20       ld   a,$20
672E: CD C5 62    call $62C5		; prints a blank space
6731: 23          inc  hl			; moves to next position
6732: C1          pop  bc
6733: 10 F0       djnz $6725		; repeats until completing 9 bytes

6735: CD 2A 68    call $682A		; advances cursor to start of next line
6738: C1          pop  bc
6739: DD 23       inc  ix			; moves to next register
673B: DD 23       inc  ix
673D: 10 E0       djnz $671F		; repeats until completing 16-bit registers

673F: CD D2 67    call $67D2		; writes 6 spaces, 4 hexadecimal digits corresponding to what is in ix (which loads it in hl) and 3 spaces
6742: DD 7E 00    ld   a,(ix+$00)	; reads flags
6745: DD 23       inc  ix			; advances to next register
6747: DD 23       inc  ix
6749: CD F4 67    call $67F4		; writes a string showing the state of the flags
674C: CD 2A 68    call $682A		; advances cursor to start of next line

674F: CD D2 67    call $67D2		; writes 6 spaces, 4 hexadecimal digits corresponding to what is in ix (which loads it in hl) and 3 spaces
6752: DD 7E 00    ld   a,(ix+$00)	; reads flags
6755: CD F4 67    call $67F4		; writes a string showing the state of the flags
6758: CD 72 65    call $6572		; calls the character printing routine and position change routine according to values after the call
	1F 01 03 -> places cursor at (1, 3)
	20 20 50 C3 0D 0A -> "  PC\n"
	20 20 53 D0 0D 0A -> "  SP\n"
	20 20 49 D9 0D 0A -> "  IY\n"
	20 20 49 D8 0D 0A -> "  IX\n"
	20 20 48 CC 0D 0A -> "  HL\n"
	20 20 48 CC 27 20 0D 0A -> "  HL' \n"
	20 20 44 C5 0D 0A -> "  DE\n"
	20 20 44 C5 27 20 0D 0A -> "  DE' \n"
	20 20 42 C3 0D 0A -> "  BC\n"
	20 20 42 C3 27 20 0D 0A -> "  BC' \n"
	20 20 41 C6 0D 0A -> "  AF\n"
	20 20 41 C6 27 FF -> "  AF'"

67AC: 3A 2E 65    ld   a,($652E)	; reads the selected register
67AF: 21 03 02    ld   hl,$0203		; initial position of first selected register (2,3)
67B2: 85          add  a,l
67B3: 6F          ld   l,a
67B4: CD B7 62    call $62B7		; places cursor at selected register position
67B7: 3E 3E       ld   a,$3E
67B9: CD C5 62    call $62C5		; writes '>' character beside selected register
67BC: C9          ret

; arrives here if '.' was pressed
67BD: 01 98 3A    ld   bc,$3A98
67C0: CD 6C 65    call $656C		; small delay until bc is 0
67C3: 3A 2E 65    ld   a,($652E)	; advances circularly the selected register
67C6: 3C          inc  a
67C7: FE 0C       cp   $0C
67C9: 38 01       jr   c,$67CC
67CB: AF          xor  a
67CC: 32 2E 65    ld   ($652E),a
67CF: C3 58 67    jp   $6758		; updates registers

; writes 6 spaces, 4 hexadecimal digits corresponding to what is in ix (which loads it in hl) and 3 spaces
67D2: CD 72 65    call $6572		; calls the character printing routine and position change routine according to values after the call
		20 20 20 20 20 20 FF -> writes 6 spaces
67DC: DD 6E 00    ld   l,(ix+$00)	; reads 2 bytes
67DF: DD 66 01    ld   h,(ix+$01)
67E2: E5          push hl
67E3: 7C          ld   a,h			; reads upper 8 bits
67E4: CD FC 65    call $65FC		; given a number in a, prints in the current position the hexadecimal value of the number
67E7: 7D          ld   a,l			; reads lower 8 bits
67E8: CD FC 65    call $65FC		; given a number in a, prints in the current position the hexadecimal value of the number
67EB: CD 72 65    call $6572		; calls the character printing routine and position change routine according to values after the call
		20 20 20 FF -> writes 3 spaces
67F2: E1          pop  hl
67F3: C9          ret

; writes a string showing the state of the flags
67F4: 4F          ld   c,a			; saves flags in c
67F5: CB 79       bit  7,c
67F7: 3E 50       ld   a,$50
67F9: 28 02       jr   z,$67FD
67FB: 3E 4D       ld   a,$4D
67FD: CD C5 62    call $62C5		; if sign flag is 1 writes M otherwise writes P
6800: 3E 2C       ld   a,$2C
6802: CD C5 62    call $62C5		; writes a comma

6805: CB 71       bit  6,c
6807: 20 05       jr   nz,$680E		; if zero flag is 1, writes Z, otherwise writes NZ
6809: 3E 4E       ld   a,$4E
680B: CD C5 62    call $62C5
680E: 3E 5A       ld   a,$5A
6810: CD C5 62    call $62C5
6813: 3E 2C       ld   a,$2C
6815: CD C5 62    call $62C5		; writes a comma

6818: CB 41       bit  0,c
681A: 20 05       jr   nz,$6821		; if carry flag is set, writes C, otherwise writes NC
681C: 3E 4E       ld   a,$4E
681E: CD C5 62    call $62C5
6821: CD 72 65    call $6572		; besides C writes 3 spaces
		43 20 20 20 FF
6829: C9          ret

; advances cursor to start of next line
682A: 3E 0D       ld   a,$0D
682C: CD C5 62    call $62C5		; writes CR, LF
682F: 3E 0A       ld   a,$0A
6831: C3 C5 62    jp   $62C5

; displays the 3 columns of the bottom part of the screen with memory dump
6834: 2A 22 65    ld   hl,($6522)	; gets the initial memory address shown or disassembled in the right part of the screen
6837: 11 0B 00    ld   de,$000B		; subtracts 0x0b from it
683A: A7          and  a
683B: ED 52       sbc  hl,de
683D: EB          ex   de,hl		; de = initial address to show
683E: 21 11 03    ld   hl,$0311		; initial cursor position (0x03, 0x11)
6841: 06 03       ld   b,$03		; repeat for 3 columns
6843: C5          push bc
6844: E5          push hl
6845: 06 08       ld   b,$08		; each column has 8 rows
6847: C5          push bc
6848: E5          push hl
6849: CD B7 62    call $62B7		; puts cursor at position indicated by hl (h = x position, l = y position)
684C: 7A          ld   a,d
684D: CD FC 65    call $65FC		; prints the most significant part of current address
6850: 7B          ld   a,e
6851: CD FC 65    call $65FC		; prints the least significant part of current address
6854: 3E 20       ld   a,$20
6856: CD C5 62    call $62C5		; prints a blank space
6859: 3E 20       ld   a,$20
685B: CD C5 62    call $62C5		; prints a blank space
685E: EB          ex   de,hl
685F: CD A0 00    call $00A0		; returns in a a byte read from hl setting the original config (then restores debug config)
6862: CD FC 65    call $65FC		; given a number in a, prints in the current position the hexadecimal value of the number
6865: 3E 20       ld   a,$20
6867: CD C5 62    call $62C5		; prints a blank space
686A: CD A0 00    call $00A0		; returns in a a byte read from hl setting the original config (then restores debug config)
686D: E6 7F       and  $7F
686F: FE 20       cp   $20
6871: 30 02       jr   nc,$6875		; if what was in the read memory address is not printable, jump
6873: 3E 20       ld   a,$20
6875: CD C5 62    call $62C5		; otherwise writes the character

6878: EB          ex   de,hl
6879: E1          pop  hl
687A: 13          inc  de
687B: 2C          inc  l			; moves to next screen line
687C: C1          pop  bc
687D: 10 C8       djnz $6847		; completes 8 rows of a column
687F: E1          pop  hl
6880: 7C          ld   a,h
6881: C6 0D       add  a,$0D		; advances cursor in x
6883: 67          ld   h,a
6884: C1          pop  bc
6885: 10 BC       djnz $6843		; completes 3 columns
6887: CD 72 65    call $6572		; calls the character printing routine and position change routine according to values after the call
		1F 0F 14 -> puts cursor at (0x0f, 0x14)
		3E -> writes '>'
		1F 1A 14 -> puts cursor at (0x1a, 0x14)
		3C FF -> writes '<'
6893: C9          ret

; reads up to 20 characters and stores them in a buffer, along with two numbers associated with each character
6894: DD 21 49 69 ld   ix,$6949		; points to a buffer to store the read characters
6898: 21 85 69    ld   hl,$6985
689B: 7E          ld   a,(hl)		; reads a byte
689C: FE FF       cp   $FF
689E: 28 F8       jr   z,$6898		; if 0xff is found, starts again from beginning of table
68A0: E5          push hl
68A1: CD 98 63    call $6398		; checks if key a was pressed
68A4: E1          pop  hl
68A5: 20 06       jr   nz,$68AD		; if pressed, jump
68A7: 23          inc  hl			; otherwise advances to next entry
68A8: 23          inc  hl
68A9: 23          inc  hl
68AA: 23          inc  hl
68AB: 18 EE       jr   $689B

68AD: 7E          ld   a,(hl)
68AE: FE 18       cp   $18
68B0: 20 08       jr   nz,$68BA		; if 0x18 key is read (pound symbol and up arrow)
68B2: ED 7B C3 62 ld   sp,($62C3)	; cancels the command
68B6: CD F5 69    call $69F5		; writes the prompt
68B9: C9          ret

; arrives here if 0x18 key is not read
68BA: E5          push hl
68BB: CD 98 63    call $6398		; checks if key a was pressed
68BE: E1          pop  hl
68BF: 20 EC       jr   nz,$68AD		; waits for key release or command cancellation
68C1: 23          inc  hl			; advances to next byte of table
68C2: 7E          ld   a,(hl)		; reads ASCII character representing the pressed key
68C3: FE 08       cp   $08
68C5: 20 13       jr   nz,$68DA		; if not DEL, jump
68C7: DD 2B       dec  ix			; goes back in buffer
68C9: 3E 20       ld   a,$20
68CB: CD C5 62    call $62C5		; prints a space
68CE: 3E 08       ld   a,$08
68D0: CD C5 62    call $62C5		; moves cursor x position back
68D3: 3E 08       ld   a,$08
68D5: CD C5 62    call $62C5		; moves cursor x position back
68D8: 18 1A       jr   $68F4

; arrives here if DEL was not pressed
68DA: DD 77 00    ld   (ix+$00),a
68DD: FE 0D       cp   $0D			; if RETURN was pressed, exit routine
68DF: C8          ret  z

68E0: CD C5 62    call $62C5		; otherwise prints character on screen
68E3: 7E          ld   a,(hl)
68E4: FE 40       cp   $40
68E6: 28 0A       jr   z,$68F2		; if '@' was pressed, jump

68E8: 23          inc  hl
68E9: 7E          ld   a,(hl)		; reads next byte and copies it to buffer
68EA: DD 77 14    ld   (ix+$14),a
68ED: 23          inc  hl
68EE: 7E          ld   a,(hl)		; reads next byte and copies it to buffer
68EF: DD 77 28    ld   (ix+$28),a

; also arrives here if '|' was pressed
68F2: DD 23       inc  ix
68F4: 3E 5F       ld   a,$5F
68F6: CD C5 62    call $62C5		; writes '_'
68F9: 3E 08       ld   a,$08
68FB: CD C5 62    call $62C5		; moves cursor back one position
68FE: C3 98 68    jp   $6898		; jumps to continue checking table values

; reads up to 20 keyboard characters and interprets them as binary or hexadecimal to return the number converted in hl
6901: CD 94 68    call $6894		; reads up to 20 characters and stores them in a buffer, with two numbers associated with each character
6904: 21 00 00    ld   hl,$0000		; hl = 0 (hl will store the read number)
6907: 55          ld   d,l			; de = 0 (de will store the mask of the read number)
6908: 5D          ld   e,l
6909: DD 21 49 69 ld   ix,$6949		; points to buffer of read characters

690D: DD 7E 00    ld   a,(ix+$00)	; reads a character
6910: FE 0D       cp   $0D
6912: C8          ret  z			; if return found, exits
6913: FE 40       cp   $40
6915: 28 18       jr   z,$692F		; if '@' found, jump

6917: 29          add  hl,hl		; hl = hl*16
6918: 29          add  hl,hl
6919: 29          add  hl,hl
691A: 29          add  hl,hl
691B: DD 7E 14    ld   a,(ix+$14)	; gets numeric value of character and combines in l
691E: 85          add  a,l
691F: 6F          ld   l,a
6920: EB          ex   de,hl
6921: 29          add  hl,hl		; hl = hl*16
6922: 29          add  hl,hl
6923: 29          add  hl,hl
6924: 29          add  hl,hl
6925: DD 7E 28    ld   a,(ix+$28)	; gets character mask and combines in l
6928: 85          add  a,l
6929: 6F          ld   l,a
692A: EB          ex   de,hl
692B: DD 23       inc  ix			; advances to next position in buffers
692D: 18 DE       jr   $690D		; continues processing

; arrives here if '@' is found (switches to bit mode)
692F: DD 23       inc  ix
6931: DD 7E 00    ld   a,(ix+$00)	; advances to next character
6934: FE 0D       cp   $0D
6936: C8          ret  z			; if return exits
6937: 29          add  hl,hl		; hl = hl*2
6938: DD 7E 14    ld   a,(ix+$14)	; gets numeric value of character and combines in l
693B: 85          add  a,l
693C: 6F          ld   l,a
693D: EB          ex   de,hl
693E: 29          add  hl,hl		; hl = hl*2
693F: DD 7E 28    ld   a,(ix+$28)	; gets character mask (only one bit) and combines in l
6942: E6 01       and  $01
6944: 85          add  a,l
6945: 6F          ld   l,a
6946: EB          ex   de,hl
6947: 18 E6       jr   $692F		; continues processing

; buffer to store read characters (up to 20 characters)
6949: 32 35 34 0D 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00

; here the number is stored (up to 20 digits)
695D: 02 05 04 09 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00

; here the mask is stored
6971: 0F 0F 0F 0F 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00

; table with keys that can be read (each entry takes 4 bytes)
6985: 	20 30 00 0F -> key '0'
		40 31 01 0F -> key '1'
		41 32 02 0F -> key '2'
		39 33 03 0F -> key '3'
		38 34 04 0F -> key '4'
		31 35 05 0F -> key '5'
		30 36 06 0F -> key '6'
		29 37 07 0F -> key '7'
		28 38 08 0F -> key '8'
		21 39 09 0F -> key '9'
		45 41 0A 0F -> key 'A'
		36 42 0B 0F -> key 'B'
		3E 43 0C 0F -> key 'C'
		3D 44 0D 0F -> key 'D'
		3A 45 0E 0F -> key 'E'
		35 46 0F 0F -> key 'F'
		3F 58 00 00 -> key 'X'
		4F 08 00 00 -> key 'DEL'
		1A 40 00 00 -> key '@'
		12 0D 00 00 -> key 'RETURN'
		18 00 00 00 -> key pound symbol and up arrow
		FF

; arrives here if 'M' was pressed
69DA: 21 14 30    ld   hl,$3014
69DD: CD B7 62    call $62B7		; puts cursor at position indicated by hl (h = x position, l = y position)
69E0: CD 72 65    call $6572		; calls the character printing routine and position change routine according to values after the call
		4D 3A 20 5F 08 FF -> M: _ (and moves back in x cursor position)
69E9: CD 01 69    call $6901		; reads up to 20 keyboard characters and interprets them as binary or hexadecimal to return the number converted in hl
69EC: 22 22 65    ld   ($6522),hl	; modifies the memory position shown
69EF: CD 60 64    call $6460		; displays a dump of memory from an area or the code in that memory area
69F2: CD 34 68    call $6834		; displays the 3 columns of the bottom part of the screen with memory dump

; writes the prompt
69F5: CD 72 65    call $6572		; calls the character printing routine and position change routine according to values after the call
		1F 2F 14 -> changes cursor to (0x2f, 0x14)
		3E -> '>'
		12 -> clear to end of line
		5F -> '_'
		08 FF -> moves cursor x position back
6A00: C9          ret

; arrives here if 'J' was pressed
6A01: 21 14 30    ld   hl,$3014
6A04: CD B7 62    call $62B7		; puts cursor at position indicated by hl (h = x position, l = y position)
6A07: CD 72 65    call $6572		; calls the character printing routine and position change routine according to values after the call
		4A 3A 20 5F 08 FF -> J: _ (and moves cursor back one position)
6A10: CD 01 69    call $6901		; reads up to 20 keyboard characters and interprets them as binary or hexadecimal to return the number converted in hl
6A13: 7C          ld   a,h
6A14: B5          or   l
6A15: CA CF 6C    jp   z,$6CCF		; if 0 was read, jump
6A18: 22 54 65    ld   ($6554),hl	; otherwise modifies PC and jumps
6A1B: C3 CF 6C    jp   $6CCF

; arrives here if '1' was pressed
6A1E: 3A 33 65    ld   a,($6533)	; reads break point state
6A21: A7          and  a			; modifies flags to know if any break point is active
6A22: 3A 7C 00    ld   a,($007C)	; reads value at break point position
6A25: 2A 36 65    ld   hl,($6536)	; gets active break point address in hl
6A28: C4 AB 00    call nz,$00AB		; if any break point is active, sets config 0 (0, 1, 2, 3), writes a in hl and sets config 4 (0, 4, 2, 3)
6A2B: 2A 22 65    ld   hl,($6522)
6A2E: 22 36 65    ld   ($6536),hl	; sets current address as break point 1 address
6A31: 2A 22 65    ld   hl,($6522)
6A34: 22 36 65    ld   ($6536),hl
6A37: CD A0 00    call $00A0		; returns in a a byte read from hl setting the original config (then restores debug config)
6A3A: 32 7C 00    ld   ($007C),a	; saves value at break point position
6A3D: 3E 01       ld   a,$01
6A3F: 32 33 65    ld   ($6533),a	; indicates break point 1 is active
6A42: C3 80 6B    jp   $6B80		; prints break point state (and if any is active, its address)

; arrives here if 'CLR' was pressed
6A45: 3A 33 65    ld   a,($6533)	; reads break point state
6A48: A7          and  a			; modifies flags to know if any break point is active
6A49: 3A 7C 00    ld   a,($007C)	; gets value at break point position
6A4C: 2A 36 65    ld   hl,($6536)	; gets active break point address in hl
6A4F: C4 AB 00    call nz,$00AB		; if any break point is active, sets config 0 (0, 1, 2, 3), writes a in hl and sets config 4 (0, 4, 2, 3)
6A52: AF          xor  a
6A53: 32 33 65    ld   ($6533),a	; indicates no break point is active
6A56: CD 80 6B    call $6B80		; prints break point state (and if any is active, its address)
6A59: CD 60 64    call $6460		; displays a dump of memory from an area or the code in that memory area
6A5C: CD 34 68    call $6834		; displays the 3 columns of the bottom part of the screen with memory dump
6A5F: C9          ret

; arrives here if 'P' was pressed
6A60: CD 72 65    call $6572		; calls the character printing routine and position change routine according to values after the call
		1F 30 14 -> changes cursor position to (0x30, 0x14)
		51 75 65 3F 08 FF -> What? (and moves cursor back one position)
6A6C: DD 21 09 6B ld   ix,$6B09		; points to key table for setting conditions
6A70: DD 7E 00    ld   a,(ix+$00)	; reads a key
6A73: FE FF       cp   $FF
6A75: 28 E9       jr   z,$6A60		; if all keys processed, returns to start and repeats
6A77: CD 98 63    call $6398		; checks if key a was pressed
6A7A: 20 0C       jr   nz,$6A88		; if pressed, jump
6A7C: DD 23       inc  ix			; otherwise advances to next entry
6A7E: DD 23       inc  ix
6A80: DD 23       inc  ix
6A82: DD 23       inc  ix
6A84: DD 23       inc  ix
6A86: 18 E8       jr   $6A70		; continues testing keys

; arrives here if a key from list was pressed
6A88: DD 7E 00    ld   a,(ix+$00)	; reads pressed key
6A8B: CD 98 63    call $6398		; checks if key a was pressed
6A8E: 20 F8       jr   nz,$6A88		; waits for key release
6A90: DD 6E 01    ld   l,(ix+$01)
6A93: DD 66 02    ld   h,(ix+$02)	; reads instruction to push register indicated into stack
6A96: 22 63 00    ld   ($0063),hl	; modifies debugger code with instruction
6A99: DD 6E 03    ld   l,(ix+$03)	; reads characters associated with key
6A9C: DD 66 04    ld   h,(ix+$04)
6A9F: 22 D3 6A    ld   ($6AD3),hl	; modifies phrase to print
6AA2: 22 AE 6A    ld   ($6AAE),hl	; modifies condition string
6AA5: 21 14 30    ld   hl,$3014
6AA8: CD B7 62    call $62B7		; puts cursor at position indicated by hl (h = x position, l = y position)
6AAB: CD 72 65    call $6572		; calls the character printing routine and position change routine according to values after the call
	XX XX 3D 20 DF 08 FF -> the 2 overwritten characters + "= _" (and moves cursor back one position)
6AB5: CD 01 69    call $6901		; reads up to 20 keyboard characters and interprets them as binary or hexadecimal to return the number converted in hl

; saves and prints the current condition
6AB8: 22 31 65    ld   ($6531),hl	; writes condition value
6ABB: ED 53 2F 65 ld   ($652F),de	; writes condition mask
6ABF: CD F5 69    call $69F5		; writes the prompt
6AC2: CD 72 65    call $6572		; calls the character printing routine and position change routine according to values after the call
		1F 14 01 -> places cursor at (0x14, 0x01)
		43 4F 4E 44 49 43 49 4F 4E 3A 3A A0 48 4C 3D A0 FF -> CONDITION: HL=
6AD8: 2A 31 65    ld   hl,($6531)
6ADB: ED 5B 2F 65 ld   de,($652F)
6ADF: 7D          ld   a,l
6AE0: B4          or   h
6AE1: B2          or   d
6AE2: B3          or   e
6AE3: 28 16       jr   z,$6AFB		; if hl and de are 0, jump
6AE5: 7C          ld   a,h
6AE6: CD FC 65    call $65FC		; prints h
6AE9: 7D          ld   a,l
6AEA: CD FC 65    call $65FC		; prints l
6AED: 3E 20       ld   a,$20
6AEF: CD C5 62    call $62C5		; prints a space
6AF2: 7A          ld   a,d
6AF3: CD FC 65    call $65FC		; prints d
6AF6: 7B          ld   a,e
6AF7: CD FC 65    call $65FC		; prints e
6AFA: C9          ret

; jumps here if condition is 0
6AFB: CD 72 65    call $6572		; calls the character printing routine and position change routine according to values after the call
		4E 4F 4E 45 20 20 20 20 A0 FF -> NONE
6B08: C9          ret

; table for setting conditions (each entry is 5 bytes)
6B09: 	2C E500 48 4C -> key 'H' -> HL
 		3D D500 44 45 -> key 'D' -> DE
 		36 C500 42 43 -> key 'B' -> BC
 		45 F500 41 46 -> key 'A' -> AF
 		3F E5DD 49 58 -> key 'X' -> IX
 		2B E5FD 49 59 -> key 'Y' -> IY
 		FF

; arrives here if 'Q' was pressed
6B28: CD 72 65    call $6572		; calls the character printing routine and position change routine according to values after the call
		1F 30 14 -> changes cursor position to (0x30, 0x14)
		43 6F 6E 74 61 64 6F 72 3D 20 DF 08 FF -> Counter= _ (and moves back one space)
6B3B: CD 01 69    call $6901		; reads up to 20 keyboard characters and interprets them as binary or hexadecimal to return the number converted in hl
6B3E: 7D          ld   a,l
6B3F: 32 51 00    ld   ($0051),a	; modifies counter with last 2 bytes read

; writes the counter
6B42: CD 72 65    call $6572		; calls the character printing routine and position change routine according to values after the call
		1F 37 01 ->  places cursor at (0x37, 0x01)
		63 6F 6E 74 61 64 6F 72 3D A0 FF -> COUNTER=
6B53: 3A 51 00    ld   a,($0051)   	; reads counter
6B56: CD FC 65    call $65FC		; given a number in a, prints in the current position the hexadecimal value of the number
6B59: C3 F5 69    jp   $69F5		; writes the prompt

; arrives here if '2' was pressed
6B5C: 3A 33 65    ld   a,($6533)    ; reads break point state
6B5F: A7          and  a            ; modifies flags to know if any break point is active
6B60: 3A 7C 00    ld   a,($007C)    ; reads value at break point position
6B63: 2A 36 65    ld   hl,($6536)   ; gets active break point address in hl
6B66: C4 AB 00    call nz,$00AB     ; if any break point is active, sets config 0 (0, 1, 2, 3), writes a in hl and sets config 4 (0, 4, 2, 3)
6B69: 2A 22 65    ld   hl,($6522)
6B6C: 22 36 65    ld   ($6536),hl   ; sets current address as active break point
6B6F: 2A 22 65    ld   hl,($6522)
6B72: 22 36 65    ld   ($6536),hl
6B75: CD A0 00    call $00A0        ; returns in a a byte read from hl setting the original config (then restores debug config)
6B78: 32 7C 00    ld   ($007C),a    ; saves value at break point position
6B7B: 3E 02       ld   a,$02
6B7D: 32 33 65    ld   ($6533),a    ; indicates break point 2 is active

; prints break point state (and if any is active, its address)
6B80: 21 01 01    ld   hl,$0101
6B83: CD B7 62    call $62B7		; puts cursor at position (1,1)
6B86: CD 72 65    call $6572		; calls the character printing routine and position change routine according to values after the call
	20 20 20 20 20 20 20 20 20 20 20 20 20 FF -> prints 13 spaces
6B97: 21 01 01    ld   hl,$0101
6B9A: CD B7 62    call $62B7		; puts cursor at position (1,1)
6B9D: 21 CD 6B    ld   hl,$6BCD		; points to text string
6BA0: 3A 33 65    ld   a,($6533)	; reads break point state
6BA3: 87          add  a,a			; a = a*8
6BA4: 87          add  a,a
6BA5: 87          add  a,a
6BA6: 85          add  a,l			; hl = hl + a
6BA7: 6F          ld   l,a
6BA8: 8C          adc  a,h
6BA9: 95          sub  l
6BAA: 67          ld   h,a

6BAB: 06 08       ld   b,$08		; 8 characters length
6BAD: 7E          ld   a,(hl)
6BAE: 23          inc  hl
6BAF: E6 7F       and  $7F
6BB1: CD C5 62    call $62C5		; reads byte and writes it on screen
6BB4: 10 F7       djnz $6BAD

6BB6: 3E 20       ld   a,$20
6BB8: CD C5 62    call $62C5		; prints a space
6BBB: 3A 33 65    ld   a,($6533)	; if no break point is set, exits
6BBE: A7          and  a
6BBF: C8          ret  z

; prints the active break point address
6BC0: 3A 37 65    ld   a,($6537)
6BC3: CD FC 65    call $65FC		; given a number in a, prints in the current position the hexadecimal value of the number
6BC6: 3A 36 65    ld   a,($6536)
6BC9: CD FC 65    call $65FC		; given a number in a, prints in the current position the hexadecimal value of the number
6BCC: C9          ret

6BCD: 	4E 6F 20 62 72 65 61 6B -> No break
		42 72 65 61 6B 20 31 3D -> Break 1=
		42 72 65 61 6B 20 32 BD -> Break 2=
6BE5: C9          ret

; arrives here if 'R' was pressed
6BE6: 21 14 30    ld   hl,$3014
6BE9: CD B7 62    call $62B7		; puts cursor at position indicated by hl (h = x position, l = y position)
6BEC: CD 72 65    call $6572		; calls the character printing routine and position change routine according to values after the call
		52 3A 20 5F 08 FF -> R: _ (and moves cursor back one position)
6BF5: CD 01 69    call $6901		; reads up to 20 keyboard characters and interprets them as binary or hexadecimal to return the number converted in hl
6BF8: 11 54 65    ld   de,$6554		; de points to first register
6BFB: 3A 2E 65    ld   a,($652E)	; gets currently selected register
6BFE: 87          add  a,a
6BFF: 83          add  a,e
6C00: 5F          ld   e,a
6C01: 8A          adc  a,d
6C02: 93          sub  e
6C03: 57          ld   d,a			; de points to selected register
6C04: EB          ex   de,hl
6C05: 73          ld   (hl),e		; modifies selected register value with what was read
6C06: 23          inc  hl
6C07: 72          ld   (hl),d
6C08: CD 12 67    call $6712		; displays registers and their values, indicates which is selected
6C0B: C3 F5 69    jp   $69F5		; writes the prompt

; arrives here if 'T' was pressed
6C0E: 21 14 30    ld   hl,$3014
6C11: CD B7 62    call $62B7		; puts cursor at position indicated by hl (h = x position, l = y position)
6C14: CD 72 65    call $6572		; calls the character printing routine and position change routine according to values after the call
		66 72 6F 6D 3A 20 DF 08 FF -> from: _ (and moves cursor back one position)
6C20: CD 01 69    call $6901		; reads up to 20 keyboard characters and interprets them as binary or hexadecimal to return the number converted in hl
6C23: E5          push hl			; saves read address
6C24: CD F5 69    call $69F5		; writes the prompt
6C27: 21 14 30    ld   hl,$3014
6C2A: CD B7 62    call $62B7		; puts cursor at position indicated by hl (h = x position, l = y position)
6C2D: CD 72 65    call $6572		; calls the character printing routine and position change routine according to values after the call
		74 6F 3A 20 DF 08 FF -> to: _ (and moves cursor back one position)
6C37: CD 01 69    call $6901		; reads up to 20 keyboard characters and interprets them as binary or hexadecimal to return the number converted in hl
6C3A: E5          push hl			; saves read address
6C3B: CD F5 69    call $69F5		; writes the prompt
6C3E: 21 14 30    ld   hl,$3014
6C41: CD B7 62    call $62B7		; puts cursor at position indicated by hl (h = x position, l = y position)
6C44: CD 72 65    call $6572		; calls the character printing routine and position change routine according to values after the call
		63 75 61 6E 74 6F 73 3A 20 DF 08 FF -> cuantos: _ (and moves cursor back one position)
6C53: CD 01 69    call $6901		; reads up to 20 keyboard characters and interprets them as binary or hexadecimal to return the number converted in hl
6C56: 44          ld   b,h			; bc = number of bytes to copy
6C57: 4D          ld   c,l
6C58: D1          pop  de			; de = "to" address
6C59: E1          pop  hl			; hl = "from" address
6C5A: C5          push bc
6C5B: CD A0 00    call $00A0		; returns in a a byte read from hl setting the original config (then restores debug config)
6C5E: EB          ex   de,hl
6C5F: CD AB 00    call $00AB		; sets config 0 (0, 1, 2, 3), writes a in hl and sets config 4 (0, 4, 2, 3)
6C62: EB          ex   de,hl
6C63: C1          pop  bc
6C64: 0B          dec  bc
6C65: 78          ld   a,b
6C66: B1          or   c
6C67: 20 F1       jr   nz,$6C5A		; copies bytes from "from" to "to" while bc > 0
6C69: C3 F5 69    jp   $69F5		; writes the prompt

; --------------- actual start of debugger ---------------------------
6C6C: 22 64 65    ld   ($6564),hl	; saves bc
6C6F: ED 53 60 65 ld   ($6560),de	; saves de
6C73: 2A 79 00    ld   hl,($0079)	; reads address where hl is stored
6C76: 22 5C 65    ld   ($655C),hl	; saves hl
6C79: 2A 75 00    ld   hl,($0075)	; reads af address
6C7C: 22 68 65    ld   ($6568),hl	; saves af
6C7F: E1          pop  hl			; recovers return address
6C80: ED 73 56 65 ld   ($6556),sp	; saves actual sp
6C84: E5          push hl			; saves return address again
6C85: 2B          dec  hl
6C86: 22 54 65    ld   ($6554),hl	; saves pc
6C89: DD 22 5A 65 ld   ($655A),ix	; saves ix
6C8D: FD 22 58 65 ld   ($6558),iy	; saves iy
6C91: 3A 7C 00    ld   a,($007C)	; reads value at active break point
6C94: 2A 36 65    ld   hl,($6536)	; reads active break point address
6C97: CD AB 00    call $00AB		; sets config 0 (0, 1, 2, 3), writes a in hl and sets config 4 (0, 4, 2, 3)
6C9A: F3          di
6C9B: D9          exx
6C9C: 22 5E 65    ld   ($655E),hl	; saves hl'
6C9F: ED 53 62 65 ld   ($6562),de	; saves de'
6CA3: ED 43 66 65 ld   ($6566),bc	; saves bc'
6CA7: D9          exx
6CA8: 08          ex   af,af'
6CA9: F5          push af
6CAA: E1          pop  hl
6CAB: 22 6A 65    ld   ($656A),hl	; saves af'
6CAE: 08          ex   af,af'

6CAF: 11 00 40    ld   de,$4000
6CB2: 21 00 40    ld   hl,$4000		; ???
6CB5: CD CA 00    call $00CA		; sets config 5 (0, 5, 2, 3), copies 0x4000 bytes from hl to de and sets config 4 (0, 4, 2, 3)
6CB8: 3E 5F       ld   a,$5F
6CBA: CD C5 62    call $62C5		; writes '_' at current cursor position
6CBD: 3E 2F       ld   a,$2F
6CBF: CD 98 63    call $6398		; checks if space was pressed
6CC2: 28 F9       jr   z,$6CBD		; while space is not pressed, jump

6CC4: CD 17 6E    call $6E17		; clears video memory
6CC7: 01 8E 7F    ld   bc,$7F8E		; 10001110 (GA select screen mode, rom config and int control)
6CCA: ED 49       out  (c),c		; selects mode 2 and disables upper and lower rom
6CCC: C3 3A 62    jp   $623A		; jumps to main debugger loop

; --------------- end of actual debugger start ---------------------------

; arrives here after pressing 'J'
6CCF: 2A 31 65    ld   hl,($6531)	; gets condition mask
6CD2: ED 5B 2F 65 ld   de,($652F)	; gets condition value
6CD6: 3A 33 65    ld   a,($6533)	; reads break point state
6CD9: FE 02       cp   $02
6CDB: 28 06       jr   z,$6CE3		; if 2 is active, jump
6CDD: 21 00 00    ld   hl,$0000		; otherwise sets condition and mask to 0
6CE0: 11 00 00    ld   de,$0000

6CE3: 7C          ld   a,h			; modifies some instructions
6CE4: 32 71 00    ld   ($0071),a
6CE7: 7D          ld   a,l
6CE8: 32 6A 00    ld   ($006A),a
6CEB: 7B          ld   a,e
6CEC: 32 68 00    ld   ($0068),a
6CEF: 7A          ld   a,d
6CF0: 32 6F 00    ld   ($006F),a

6CF3: 2A 36 65    ld   hl,($6536)	; hl = active break point address
6CF6: ED 5B 54 65 ld   de,($6554)	; de = PC address
6CFA: 7B          ld   a,e
6CFB: AD          xor  l
6CFC: AA          xor  d
6CFD: AC          xor  h			; if pc matches active break point, ends execution
6CFE: 3E 38       ld   a,$38		; jr c
6D00: 28 02       jr   z,$6D04
6D02: 3E 30       ld   a,$30		; jr nc
6D04: 32 90 00    ld   ($0090),a	; modifies an instruction
6D07: 7E          ld   a,(hl)		; reads what is at break point position and saves it
6D08: 32 7C 00    ld   ($007C),a
6D0B: 36 F7       ld   (hl),$F7		; modifies what was at break point position with rst 0x048
6D0D: 2A 6A 65    ld   hl,($656A)	; hl = af'

6D10: 11 00 C0    ld   de,$C000
6D13: 21 00 40    ld   hl,$4000
6D16: CD CA 00    call $00CA		; sets config 5 (0, 5, 2, 3), copies 0x4000 bytes from hl to de and sets config 4 (0, 4, 2, 3)
6D19: F3          di
6D1A: 08          ex   af,af'
6D1B: E5          push hl			; bug!?! hl has been overwritten and no longer contains af'
6D1C: F1          pop  af
6D1D: 08          ex   af,af'
6D1E: D9          exx
6D1F: ED 4B 66 65 ld   bc,($6566)	; restores bc'
6D23: ED 5B 62 65 ld   de,($6562)	; restores de'
6D27: 2A 5E 65    ld   hl,($655E)	; restores hl'
6D2A: D9          exx
6D2B: FB          ei
6D2C: FD 2A 58 65 ld   iy,($6558)	; restores iy
6D30: DD 2A 5A 65 ld   ix,($655A)	; restores ix
6D34: ED 7B 56 65 ld   sp,($6556)	; restores sp
6D38: 2A 54 65    ld   hl,($6554)	; restores pc and pushes it onto stack
6D3B: E5          push hl
6D3C: ED 5B 60 65 ld   de,($6560)	; restores de
6D40: 2A 5C 65    ld   hl,($655C)	; restores hl
6D43: 22 79 00    ld   ($0079),hl
6D46: 2A 68 65    ld   hl,($6568)	; restores af
6D49: 22 75 00    ld   ($0075),hl
6D4C: 2A 64 65    ld   hl,($6564)	; hl = original bc
6D4F: C3 88 00    jp   $0088		; jumps to execute code

; arrives here if escape was pressed
6D52: 01 8E 7F    ld   bc,$7F8E
6D55: CD 17 6E    call $6E17		; clears video memory
6D58: 31 FF BF    ld   sp,$BFFF		; puts stack at ???
6D5B: CD 72 65    call $6572		; calls the character printing routine and position change routine according to values after the call
		1F 01 05 -> puts cursor at (1, 5)
		31 2D 20 43 4F 52 52 45 52 20 45 4C 20 50 52 4F 47 52 41 4D C1 0D 0A 0A -> 1- RUN THE PROGRAM
		32 2D 20 53 41 4C 54 4F 20 41 20 4D 4F 4E D3 0D 0A 0A -> 2- JUMP TO MONITOR
		33 2D 20 52 45 43 49 42 49 D2 FF -> 3- RECEIVE

6D96: 21 52 6D    ld   hl,$6D52		; saves address of this routine as return address
6D99: E5          push hl

6D9A: 3E 40       ld   a,$40
6D9C: CD 98 63    call $6398		; checks if 1 was pressed
6D9F: C2 B3 00    jp   nz,$00B3		; if 1 was pressed, jump
6DA2: 3E 41       ld   a,$41
6DA4: CD 98 63    call $6398		; checks if 2 was pressed
6DA7: C2 7E 00    jp   nz,$007E		; if 2 was pressed, jump
6DAA: 3E 39       ld   a,$39
6DAC: CD 98 63    call $6398		; checks if 3 was pressed
6DAF: C2 B4 6D    jp   nz,$6DB4		; if 3 was pressed, jump
6DB2: 18 E6       jr   $6D9A		; repeats until an option is pressed

; arrives here if 3 was pressed (receive)
6DB4: CD 17 6E    call $6E17		; clears video memory
6DB7: CD 72 65    call $6572		; calls the character printing routine and position change routine according to values after the call
		1F 01 05 -> positions cursor at (1, 5)
		45 53 43 20 50 41 52 41 20 43 4F 52 54 41 D2 FF -> ESC TO STOP
6DCD: 21 00 01    ld   hl,$0100		; saves address where to start copying data

6DD0: E5          push hl
6DD1: CD ED 6D    call $6DED		; ??? (does something with expansion rom 6, but since it is not available, it is unknown what it does)
6DD4: 3A 10 6E    ld   a,($6E10)
6DD7: A7          and  a
6DD8: 20 0A       jr   nz,$6DE4		; if finished copying data?, jump
6DDA: 3A 11 6E    ld   a,($6E11)	; reads received byte
6DDD: E1          pop  hl			; gets address where to copy it
6DDE: CD AB 00    call $00AB		; sets config 0 (0, 1, 2, 3), writes a in hl and sets config 4 (0, 4, 2, 3)
6DE1: 23          inc  hl			; advances to next address
6DE2: 18 EC       jr   $6DD0

; arrives here if 0x6e10 is not 0 (if finished copying data?)
6DE4: 3E 42       ld   a,$42
6DE6: CD 98 63    call $6398		; checks if escape was pressed
6DE9: E1          pop  hl
6DEA: C0          ret  nz			; if pressed, exits
6DEB: 18 E3       jr   $6DD0		; otherwise jumps to receive

; routine that loads expansion rom 6 and does something
6DED: 01 06 DF    ld   bc,$DF06		; selects expansion rom 6 (???) (will be available at 0xc000-0xffff)
6DF0: ED 49       out  (c),c
6DF2: 01 86 7F    ld   bc,$7F86		; gate array -> 10000110 (select screen mode, rom config and int control)
6DF5: ED 49       out  (c),c		; selects mode 2 and disables lower rom, but not upper
6DF7: DD 21 13 6E ld   ix,$6E13		; points to pointers for storing data and state???
6DFB: 3E 02       ld   a,$02
6DFD: FD 21 8E 6E ld   iy,$6E8E		; points to part of debugger execution code???
6E01: CD C2 C4    call $C4C2		; ???
6E04: 01 00 DF    ld   bc,$DF00		; selects expansion rom of basic (will be available at 0xc000-0xffff)
6E07: ED 49       out  (c),c
6E09: 01 8E 7F    ld   bc,$7F8E		; 10001110 (GA select screen mode, rom config and int control)
6E0C: ED 49       out  (c),c		; selects mode 2 and disables upper and lower rom

6E0E: C9          ret

; variables modified by expansion rom
6E0F: 00
6E10: 02
6E11: 01
6E12: 00

6E13-6E14: 6E11
6E15-6E16: 6E0F

; clears video memory
6E17: 21 00 C0    ld   hl,$C000
6E1A: 11 01 C0    ld   de,$C001
6E1D: 01 FF 3F    ld   bc,$3FFF
6E20: 36 00       ld   (hl),$00
6E22: ED B0       ldir
6E24: C9          ret

6E25: 00          nop

; ------------------- code copied to 0x0048-0x00ff ---------------------
6E26: F5          push af
6E27: 22 79 00    ld   ($0079),hl
6E2A: E1          pop  hl
6E2B: 22 75 00    ld   ($0075),hl
6E2E: 3E 00       ld   a,$00
6E30: D6 01       sub  $01
6E32: 38 05       jr   c,$6E39
6E34: 32 51 00    ld   ($0051),a
6E37: 18 19       jr   $6E52
6E39: 2A 75 00    ld   hl,($0075)
6E3C: E5          push hl
6E3D: 2A 79 00    ld   hl,($0079)
6E40: F1          pop  af
6E41: 00          nop
6E42: E5          push hl
6E43: E1          pop  hl
6E44: 7D          ld   a,l
6E45: E6 00       and  $00
6E47: EE 00       xor  $00
6E49: 20 07       jr   nz,$6E52
6E4B: 7C          ld   a,h
6E4C: E6 00       and  $00
6E4E: EE 00       xor  $00
6E50: 28 0A       jr   z,$6E5C
6E52: 21 00 00    ld   hl,$0000
6E55: E5          push hl
6E56: 21 00 00    ld   hl,$0000
6E59: F1          pop  af
6E5A: 00          nop
6E5B: C9          ret
6E5C: 60          ld   h,b
6E5D: 69          ld   l,c
6E5E: 01 C4 7F    ld   bc,$7FC4
6E61: ED 49       out  (c),c
6E63: C3 6C 6C    jp   $6C6C
6E66: 01 C0 7F    ld   bc,$7FC0
6E69: ED 49       out  (c),c
6E6B: 44          ld   b,h
6E6C: 4D          ld   c,l
6E6D: 37          scf
6E6E: 38 09       jr   c,$6E79
6E70: 2A 75 00    ld   hl,($0075)
6E73: E5          push hl
6E74: 2A 79 00    ld   hl,($0079)
6E77: F1          pop  af
6E78: C9          ret
6E79: E1          pop  hl
6E7A: 23          inc  hl
6E7B: E5          push hl
6E7C: 18 D4       jr   $6E52
6E7E: 01 C0 7F    ld   bc,$7FC0
6E81: ED 49       out  (c),c
6E83: 7E          ld   a,(hl)
6E84: 0E C4       ld   c,$C4
6E86: ED 49       out  (c),c
6E88: C9          ret
6E89: 01 C0 7F    ld   bc,$7FC0
6E8C: ED 49       out  (c),c
6E8E: 77          ld   (hl),a
6E8F: 18 F3       jr   $6E84
6E91: C1          pop  bc
6E92: 01 30 00    ld   bc,$0030
6E95: C5          push bc
6E96: 3A 34 65    ld   a,($6534)
6E99: 01 8C 7F    ld   bc,$7F8C
6E9C: B1          or   c
6E9D: 4F          ld   c,a
6E9E: ED 49       out  (c),c
6EA0: 01 C0 7F    ld   bc,$7FC0
6EA3: ED 49       out  (c),c
6EA5: C3 00 01    jp   $0100
6EA8: 01 C5 7F    ld   bc,$7FC5
6EAB: ED 49       out  (c),c
6EAD: 01 00 40    ld   bc,$4000
6EB0: ED B0       ldir
6EB2: 01 C4 7F    ld   bc,$7FC4
6EB5: ED 49       out  (c),c
6EB7: C9          ret
6EB8: 00          nop
6EB9: 00          nop
6EBA: 00          nop
6EBB: 00          nop
6EBC: 00          nop
6EBD: 00          nop
6EBE: FF          rst  $38
6EBF: 6A          ld   l,d
6EC0: 01 00 01    ld   bc,$0100
6EC3: 00          nop
6EC4: FF          rst  $38
6EC5: 00          nop
6EC6: 00          nop
6EC7: 00          nop
6EC8: 00          nop
6EC9: 00          nop
6ECA: 00          nop
6ECB: 00          nop
6ECC: 00          nop
6ECD: 00          nop
6ECE: 00          nop
6ECF: 00          nop
6ED0: 00          nop
6ED1: 00          nop
6ED2: 00          nop
6ED3: 00          nop
6ED4: 00          nop
6ED5: 00          nop
6ED6: 00          nop
6ED7: 00          nop
6ED8: 00          nop
6ED9: 00          nop
6EDA: 00          nop
6EDB: 00          nop
6EDC: 00          nop
6EDD: 00          nop
6EDE: 00          nop
6EDF: 00          nop
; ------------------- end of code copied to 0x0048-0x00ff ---------------------

6EE0: BA 5E 9A 5E BA 5E BA 5E-BA 5E BA 5E BA 5E BA 5E .^.^.^.^.^.^.^.^
6EF0: BA 5E BA 5E BA 5E BA 5E-BA 5E BA 5E BA 5E BA 5E .^.^.^.^.^.^.^.^
6F00: 8A 0A 8A 0A 8A 0A 8A 0A-8A 0A 8A 0A 8A 0A 8A 0A ................
6F10: 8A 0A 8A 0A 8A 0A 8A 0A-8A 0A 8A 0A 8A 0A 8A 0A ................
6F20: 8A 0A 8A 0A 8A 0A 8A 0A-8A 0A 8A 0A 8A 0A 8A 0A ................
6F30: 8A 0A 8A 0A 8A 0A 8A 0A-8A 0A 8A 0A 8A 0A 8A 0A ................
6F40: 8A 0A 8A 0A 8A 0A 8A 0A-8A 0A 8A 0A 8A 0A 8A 0A ................
6F50: 8A 0A 8A 0A 8A 0A 8A 0A-8A 0A 8A 0A 8A 0A 8A 0A ................
6F60: 08 08 8A 0A 8A 0A 8A 0A-8A 0A 8A 0A 8A 0A 8A 0A ................
6F70: 8A 0A 8A 0A 8A 0A 8A 0A-8A 0A 8A 0A 8A 0A 8A 0A ................
6F80: 9A 5E BA 5E 9A 5E 9A 5E-9A 5E 9A 4E 9A 5E BA 5E .^.^.^.^.^.N.^.^
6F90: 9A 5E 9A 5E 9A 5E BA 5E-9A 5E 9A 5E BA 5E 9A 5E .^.^.^.^.^.^.^.^
6FA0: 9A 5E 9A 5E 9A 5E 9A 5E-9A 5E BA 5E BA 5E BA 5E .^.^.^.^.^.^.^.^
6FB0: BA 5E 9A 5E BA 5E BA 5E-9A 5E 9A 5E BA 5E BA 5E .^.^.^.^.^.^.^.^
6FC0: BA 5E 9A 5E 9A 5E 9A 5E-9A 5E 9A 5E BA 5E BA 5E .^.^.^.^.^.^.^.^
6FD0: 9A 5E 9A 5E 9A 5E BA 5E-9A 5E BA 5E 9A 5E BA 5E .^.^.^.^.^.^.^.^
6FE0: 9A 4E 9A 5E 9A 5E BA 5E-9A 5E 9A 5E 9A 5E BA 5E .N.^.^.^.^.^.^.^
6FF0: 9A 5E 9A 5E 9A 4E 92 1A-9A 5E BA 5E 9A 5E 82 0A .^.^.N...^.^.^..
7000: 99 80 99 80 99 80 99 80-99 80 99 80 99 80 99 80 ................
7010: 99 80 99 80 99 80 99 80-99 80 99 80 99 80 99 80 ................
7020: 99 80 99 80 99 80 99 80-99 80 99 80 99 80 99 80 ................
7030: 99 80 99 80 99 80 99 80-99 80 99 80 99 80 99 80 ................
7040: 99 80 99 80 99 80 99 80-99 80 99 80 99 80 99 80 ................
7050: 99 80 99 80 99 80 99 80-99 80 99 80 99 80 99 80 ................
7060: 99 80 99 80 99 80 99 80-99 80 99 80 99 80 99 80 ................
7070: 99 80 99 80 91 80 99 80-99 80 99 80 99 80 99 80 ................
7080: DF 82 DF 82 DF 82 DF 82-DF 82 DF 82 DF 82 DF 82 ................
7090: DF 82 DF 82 DD 82 DF 82-DF 82 DF 82 DF 82 DD 82 ................
70A0: DF 82 DF 82 DF 82 DF 82-DF 82 DF 82 DF 82 DF 82 ................
70B0: DF 82 DF 82 DF 82 DF 82-DF 82 DF 82 DF 82 DF 82 ................
70C0: DF 82 DF 82 DF 82 DF 82-DF 82 DF 82 DF 82 DF 82 ................
70D0: DF 82 DF 82 DF 82 DF 82-DF 82 DF 82 DD 82 DF 82 ................
70E0: DF 82 DF 82 DF 82 DF 82-DF 82 DF 82 DF 82 DF 82 ................
70F0: DF 82 DF 82 DF 82 DF 82-DF 82 DF 82 DF 82 DF 82 ................
7100: 99 80 99 80 99 80 99 80-99 80 99 80 99 80 99 80 ................
7110: 99 80 99 80 99 80 99 80-99 80 99 80 99 80 99 80 ................
7120: 99 80 99 80 99 80 99 80-99 80 99 80 99 80 99 80 ................
7130: 99 80 99 80 99 80 99 80-99 80 99 80 99 80 99 80 ................
7140: 99 80 99 80 99 80 99 80-99 80 99 80 99 80 99 80 ................
7150: 99 80 99 80 99 80 99 80-99 80 99 80 99 80 99 80 ................
7160: 18 00 99 80 99 80 99 80-99 80 99 80 99 80 99 80 ................
7170: 99 80 99 80 99 80 99 80-99 80 89 80 99 80 99 80 ................
7180: 9F 82 DF 82 9F 80 9F 82-9F 82 9F 82 DF 82 DF 82 ................
7190: DF 82 DF 82 DF 82 DF 82-DF 82 DF 82 DF 82 DF 82 ................
71A0: DF 82 DF 82 DF 82 DF 80-DF 82 DF 82 DF 82 DF 82 ................
71B0: DF 82 9F 80 DF 82 DF 80-DF 82 DF 82 DF 80 DF 82 ................
71C0: DF 82 DF 82 9F 82 DF 82-9F 82 9F 82 DB 82 DF 82 ................
71D0: 9F 82 DF 82 DF 80 DF 80-DF 82 9F 82 DF 80 DF 82 ................
71E0: 9F 82 9F 82 DF 82 DF 80-9F 82 9F 80 DF 80 DF 82 ................
71F0: 9F 82 9F 82 DF 80 9D 80-DF 82 DF 82 DF 82 19 80 ................
7200: 32 D6 32 D6 32 D6 32 D6-32 D6 32 D6 32 D6 32 D6 2.2.2.2.2.2.2.2.
7210: 32 D6 32 D6 32 D6 32 D6-32 D6 32 D6 32 D6 32 D6 2.2.2.2.2.2.2.2.
7220: 32 D6 32 D6 32 D6 32 D6-32 D6 32 D6 32 D6 32 D6 2.2.2.2.2.2.2.2.
7230: 32 D6 32 D6 32 D6 32 D6-32 96 32 D6 32 D6 32 D6 2.2.2.2.2.2.2.2.
7240: 32 D6 32 D6 32 D6 32 D6-32 96 32 96 32 D6 32 D6 2.2.2.2.2.2.2.2.
7250: 32 D6 32 96 32 D6 32 D6-32 86 32 D6 32 D6 32 D6 2.2.2.2.2.2.2.2.
7260: 32 96 32 96 32 D6 32 D6-32 96 32 96 32 D6 32 D6 2.2.2.2.2.2.2.2.
7270: 32 96 32 D6 32 D6 32 D6-32 96 32 D6 32 D6 32 D6 2.2.2.2.2.2.2.2.
7280: 3A F6 7E F6 7E F6 3E F6-3A F6 7A F6 3A F6 7E F6 :.~.~.>.:.z.:.~.
7290: 7A F6 7E F6 7A F6 7E F6-3A F6 3A F6 7E F6 7A F6 z.~.z.~.:.:.~.z.
72A0: 7E F6 7E F6 7E F6 7E F6-3E F6 3E F6 7A F6 7E F6 ~.~.~.~.>.>.z.~.
72B0: 3E F6 7E F6 7E F6 7E F6-7E F6 7E F6 7E F6 7E F6 >.~.~.~.~.~.~.~.
72C0: 3A F6 3E F6 7E F6 7E F6-7E F6 3A F6 7E F6 7A F6 :.>.~.~.~.:.~.z.
72D0: 3E F6 3E F6 3E F6 7E F6-7E F6 3E F6 7E F6 7E F6 >.>.>.~.~.>.~.~.
72E0: 7E F6 3E F6 7E F6 7E F6-3E F6 3E F6 7E F6 7A F6 ~.>.~.~.>.>.~.z.
72F0: 7A F6 3A F6 7E F6 7E F6-7E F6 7A F6 7A F6 3E F6 z.:.~.~.~.z.z.>.
7300: 32 D6 32 D6 32 D6 32 D6-32 D6 32 D6 32 D6 32 D6 2.2.2.2.2.2.2.2.
7310: 32 D6 32 D6 32 D6 32 D6-32 D6 32 D6 32 D6 32 D6 2.2.2.2.2.2.2.2.
7320: 32 D2 32 D6 32 D6 32 D6-32 D6 32 D6 32 D6 32 D6 2.2.2.2.2.2.2.2.
7330: 32 D6 32 D6 32 D6 32 D6-32 D6 32 D6 32 D6 32 D6 2.2.2.2.2.2.2.2.
7340: 32 D6 32 D6 32 D6 32 D6-32 D6 32 D6 32 D6 32 D6 2.2.2.2.2.2.2.2.
7350: 32 D6 32 D6 32 D6 32 D6-32 D6 32 D6 32 D6 32 D6 2.2.2.2.2.2.2.2.
7360: 10 14 32 D2 32 D6 32 D6-32 D6 32 D6 32 D6 32 D6 ..2.2.2.2.2.2.2.
7370: 32 D6 32 D6 32 D6 32 D6-32 D6 22 C6 32 D6 32 D6 2.2.2.2.2.".2.2.
7380: 3A F6 3A F6 3A F6 3A F6-3A F6 3A F6 3A F6 3E F6 :.:.:.:.:.:.:.>.
7390: 3E F6 3A F6 7A F6 7A F6-7E F6 7E F6 7E F6 7A F6 >.:.z.z.~.~.~.z.
73A0: 3E F6 7A F6 7A F6 72 F6-72 F6 7A F6 7E F6 7E F6 >.z.z.r.r.z.~.~.
73B0: 7A F6 3E F6 7E F6 7A F6-7E F6 7A F6 7E F6 7E F6 z.>.~.z.~.z.~.~.
73C0: 3E F6 3E F6 3A F6 3A F6-3A F6 3E F6 3E F6 3A F6 >.>.:.:.:.>.>.:.
73D0: 3A F6 3A F6 7E F6 3A F6-3A F6 3A F6 3A F6 7E F6 :.:.~.:.:.:.:.~.
73E0: 3A F6 3E F6 3A F6 3A F6-3A F6 3A F6 7A F6 3E F6 :.>.:.:.:.:.z.>.
73F0: 3A F6 3E F6 3E F6 32 D6-3E F6 3E F6 7E F6 32 D6 :.>.>.2.>.>.~.2.
7400: DF A8 D3 A0 D7 A0 D7 A0-D7 A8 D3 A0 C7 A0 D7 A0 ................
7410: D3 A0 D3 A0 D7 A0 D7 A0-C3 A0 D3 A0 D7 A0 D7 A0 ................
7420: D3 A0 C3 A0 D7 A0 D7 A0-83 A0 83 A0 D3 A0 D7 A0 ................
7430: C3 A0 C3 A0 D7 A0 D7 A0-C3 A0 C3 A0 D7 A0 D7 A0 ................
7440: 83 A0 C3 A0 C3 A0 D7 A0-83 A0 83 A0 C3 A0 D3 A0 ................
7450: 83 A0 C3 A0 D7 A0 D7 A0-83 A0 C3 A0 D7 A0 D7 A0 ................
7460: 83 A0 83 A0 D7 A0 D7 A0-83 A0 83 A0 C7 A0 93 A0 ................
7470: C3 A0 83 A0 D7 A0 D7 A0-83 A0 83 A0 D7 A0 D7 A0 ................
7480: DF EC FF EC FF EC FF EC-DF EC FF EC FF EC FF EC ................
7490: FF EC FF EC FF EC FF EC-FF EC DF EC FF EC FF EC ................
74A0: FF EC DF EC FF EC FF EC-FF EC DF EC FF EC FF EC ................
74B0: FF EC FF EC FF EC FF EC-DF EC FF EC FF EC FF EC ................
74C0: FF EC FF EC FF EC FF EC-DF EC FF EC DF EC FF EC ................
74D0: FF EC FF EC FF EC FF EC-DF EC FF EC FF EC FF EC ................
74E0: FF EC DF EC FF EC FF EC-DF EC FF EC FF EC FF EC ................
74F0: FF EC FF EC FF EC FF EC-FF EC DF EC FF EC FF EC ................
7500: D7 A0 D3 A0 D7 A0 D7 A0-D3 A0 D3 A0 D7 A0 93 A0 ................
7510: D3 A0 D7 A0 D7 A0 D7 A0-D3 A0 D3 A0 D7 A0 D7 A0 ................
7520: D3 A0 D3 A0 D7 A0 D7 A0-D3 A0 D3 A0 D7 A0 D7 A0 ................
7530: D3 A0 D7 A0 D7 A0 D7 A0-D3 A0 D7 A0 D7 A0 D7 A0 ................
7540: D3 A0 D3 A0 D7 A0 D7 A0-D3 A0 D3 A0 D7 A0 D7 A0 ................
7550: D7 A0 D7 A0 D7 A0 D7 A0-D3 A0 D7 A0 D7 A0 D7 A0 ................
7560: 10 00 D3 A0 D7 A0 D7 A0-D3 A0 D3 A0 D7 A0 D7 A0 ................
7570: D3 A0 D3 A0 D7 A0 D7 A0-D3 A0 C7 A0 D7 A0 D7 A0 ................
7580: DF EC FF EC DF EC DF EC-DF EC FF EC FF EC FF EC ................
7590: FF EC FF EC DF EC FF EC-DF EC FF EC FF EC FF EC ................
75A0: DF EC FF EC FF EC DF EC-DF EC DF EC DF EC FF EC ................
75B0: DF EC DF EC DF EC FF EC-DF EC DF EC FF EC FF EC ................
75C0: FF EC DF EC FF EC DF EC-FF EC FF EC FF EC FF E8 ................
75D0: FF EC DF EC FF EC FF EC-FF EC FF EC FF EC FF EC ................
75E0: DF EC FF EC FF EC DF EC-DF EC FF EC DF EC FF EC ................
75F0: FF EC FF EC DF EC D7 E8-FF EC FF E8 FF EC D7 A8 ................
7600: BE 22 AE 02 AE 02 AE 02-AE 02 AE 02 AE 02 AE 02 ."..............
7610: AE 02 AE 02 AE 02 AE 02-AE 02 AE 02 AE 02 AE 02 ................
7620: AE 02 AE 02 AE 02 AE 02-AE 02 AE 02 AE 02 AE 02 ................
7630: AE 02 AE 02 AE 02 AE 02-AE 02 AE 02 AE 02 AE 02 ................
7640: AE 02 AE 02 AE 02 AE 02-AA 02 AE 02 AE 02 AE 02 ................
7650: AE 02 AE 02 AE 02 AE 02-AE 02 AE 02 AE 02 AE 02 ................
7660: AE 02 AE 02 AE 02 AE 02-AA 02 AE 02 AE 02 AE 02 ................
7670: AE 02 AE 02 A6 02 AE 02-AE 02 AE 02 AE 02 AE 02 ................
7680: FE 32 FE 36 FE 36 FE 36-FE 36 FE 36 FE 36 FE 32 .2.6.6.6.6.6.6.2
7690: FE 36 FE 36 FE 36 FE 32-FE 32 FE 32 FE 36 FE 32 .6.6.6.2.2.2.6.2
76A0: FE 36 FE 36 FE 36 FE 36-FE 36 FE 36 FE 32 FE 36 .6.6.6.6.6.6.2.6
76B0: FE 36 FE 36 FE 36 FE 36-FE 36 FE 36 FE 32 FE 36 .6.6.6.6.6.6.2.6
76C0: FE 36 FE 36 FE 32 FE 32-FE 36 FE 36 FE 36 FE 32 .6.6.2.2.6.6.6.2
76D0: FE 36 FE 36 FE 36 FE 32-FE 36 FE 36 FE 32 FE 32 .6.6.6.2.6.6.2.2
76E0: FE 36 FE 36 FE 32 FE 32-FE 32 FE 36 FE 32 FE 36 .6.6.2.2.2.6.2.6
76F0: FE 36 FE 36 FE 32 FE 36-FE 36 FE 36 FE 36 FE 32 .6.6.2.6.6.6.6.2
7700: AE 02 AE 02 AE 02 AE 02-AE 02 AE 02 AE 02 AE 02 ................
7710: AE 02 AE 02 AE 02 AE 02-AE 02 AE 02 AE 02 AE 02 ................
7720: AE 02 AE 02 AE 02 AE 02-AE 02 AE 02 AE 02 AE 02 ................
7730: AE 02 AE 02 AE 02 AE 02-AE 02 AE 02 AE 02 AE 02 ................
7740: AE 02 AE 02 AE 02 AE 02-AE 02 AE 02 AE 02 AE 02 ................
7750: AE 02 AE 02 AE 02 AE 02-AE 02 AE 02 AE 02 AE 02 ................
7760: 0C 00 AA 02 AE 02 AE 02-AE 02 AE 02 AE 02 AE 02 ................
7770: AE 02 AE 02 AE 02 AE 02-AE 02 AE 02 AE 02 AE 02 ................
7780: FE 36 FE 36 FE 32 FE 36-FE 36 FE 32 FE 36 FE 36 .6.6.2.6.6.2.6.6
7790: FE 36 FE 36 FE 32 FE 36-FE 36 FE 32 FE 36 FE 36 .6.6.2.6.6.2.6.6
77A0: FE 36 FE 32 FE 32 FE 32-FE 36 FE 36 FE 36 FE 36 .6.2.2.2.6.6.6.6
77B0: FE 36 FE 36 FE 36 FE 36-FE 36 FE 32 FE 36 FE 36 .6.6.6.6.6.2.6.6
77C0: FE 32 FE 32 FE 36 FE 36-FE 36 FE 32 FE 32 FE 32 .2.2.6.6.6.2.2.2
77D0: FE 36 FE 36 FE 36 FE 32-FE 36 FE 32 FE 32 FE 36 .6.6.6.2.6.2.2.6
77E0: FE 32 FE 32 FE 36 FE 32-FE 36 FE 36 FE 36 FE 36 .2.2.6.2.6.6.6.6
77F0: FE 36 FE 32 FE 32 FE 12-FE 36 FE 32 FE 36 BE 02 .6.2.2...6.2.6..
7800: 44 0D 00 09 00 09 00 09-00 09 00 09 00 09 00 09 D...............
7810: 00 09 00 09 00 09 00 09-00 09 00 09 00 09 00 09 ................
7820: 00 09 00 09 00 09 00 09-00 09 00 09 00 09 00 09 ................
7830: 00 09 00 09 00 09 00 09-00 09 00 09 00 09 00 09 ................
7840: 00 09 00 09 00 09 00 09-00 09 00 09 00 09 00 09 ................
7850: 00 09 00 09 00 09 00 09-00 09 00 09 00 09 00 09 ................
7860: 00 09 00 09 00 09 00 09-00 09 00 09 00 09 00 09 ................
7870: 00 09 00 09 00 01 00 09-00 09 00 09 00 09 00 09 ................
7880: 56 1D 56 1D 56 1D 54 1D-56 1D 56 1D 56 1D 56 1D V.V.V.T.V.V.V.V.
7890: 56 1D 56 1D 56 1D 56 1D-56 1D 56 1D 56 1D 56 1D V.V.V.V.V.V.V.V.
78A0: 56 1D 56 1D 56 1D 56 1D-56 1D 56 1D 56 1D 56 1D V.V.V.V.V.V.V.V.
78B0: 56 1D 56 1D 56 1D 56 1D-56 1D 56 1D 56 1D 56 1D V.V.V.V.V.V.V.V.
78C0: 56 1D 56 1D 56 1D 56 1D-56 1D 56 1D 56 1D 56 1D V.V.V.V.V.V.V.V.
78D0: 56 1D 56 1D 54 1D 56 1D-56 1D 56 1D 56 1D 56 1D V.V.T.V.V.V.V.V.
78E0: 56 1D 56 1D 56 1D 56 1D-56 1D 56 1D 56 1D 56 1D V.V.V.V.V.V.V.V.
78F0: 56 1D 56 1D 56 1D 56 1D-56 1D 56 1D 54 1D 56 1D V.V.V.V.V.V.T.V.
7900: 00 09 00 09 00 09 00 09-00 09 00 09 00 09 00 09 ................
7910: 00 09 00 09 00 09 00 09-00 09 00 09 00 09 00 09 ................
7920: 00 09 00 09 00 09 00 09-00 09 00 09 00 09 00 09 ................
7930: 00 09 00 09 00 09 00 09-00 09 00 09 00 09 00 09 ................
7940: 00 09 00 09 00 09 00 09-00 09 00 09 00 09 00 09 ................
7950: 00 09 00 09 00 09 00 09-00 09 00 09 00 09 00 09 ................
7960: 00 08 00 09 00 09 00 09-00 09 00 09 00 09 00 09 ................
7970: 00 09 00 09 00 09 00 09-00 09 00 09 00 09 00 09 ................
7980: 56 1D 56 1D 56 1D 54 1D-56 1D 54 1D 56 1D 56 1D V.V.V.T.V.T.V.V.
7990: 56 1D 56 1D 56 1D 56 1D-56 1D 56 1D 56 1D 56 1D V.V.V.V.V.V.V.V.
79A0: 56 1D 56 1D 56 1D 56 1D-56 1D 56 1D 56 1D 56 1D V.V.V.V.V.V.V.V.
79B0: 56 1D 54 1D 56 1D 56 1D-56 1D 56 1D 56 1D 56 1D V.T.V.V.V.V.V.V.
79C0: 56 1D 56 1D 56 1D 56 1D-56 1D 56 1D 56 1D 56 1D V.V.V.V.V.V.V.V.
79D0: 56 1D 56 1D 56 1D 56 1D-54 1D 56 1D 56 1D 56 1D V.V.V.V.T.V.V.V.
79E0: 54 1D 54 1D 54 1D 56 1D-56 1D 56 1D 56 1D 56 1D T.T.T.V.V.V.V.V.
79F0: 56 1D 56 1D 56 1D 16 0D-56 1D 56 1D 56 1D 44 0D V.V.V...V.V.V.D.
7A00: 83 14 83 10 83 10 83 10-83 10 83 10 83 10 83 10 ................
7A10: 83 10 83 10 83 10 83 10-83 10 83 10 83 10 83 10 ................
7A20: 83 10 83 10 83 10 83 10-83 10 83 10 83 10 83 10 ................
7A30: 83 10 83 10 83 10 83 10-83 10 83 10 83 10 83 10 ................
7A40: 83 10 83 10 83 10 83 10-83 10 83 10 83 10 83 10 ................
7A50: 83 10 83 10 83 10 83 10-83 10 83 10 83 10 83 10 ................
7A60: 83 10 83 10 83 10 83 10-83 10 83 10 83 10 83 10 ................
7A70: 83 10 83 10 83 10 83 10-83 10 83 10 83 10 83 10 ................
7A80: D7 54 F7 54 F7 54 F7 54-D7 54 F7 54 F7 54 F7 54 .T.T.T.T.T.T.T.T
7A90: F7 54 F7 54 F7 54 F7 54-F7 54 F7 54 F7 54 F7 54 .T.T.T.T.T.T.T.T
7AA0: F7 54 F7 54 F7 54 F7 54-F7 54 F7 54 F7 54 F7 54 .T.T.T.T.T.T.T.T
7AB0: F7 54 F7 54 F7 54 F7 54-F7 54 F7 54 F7 54 F7 54 .T.T.T.T.T.T.T.T
7AC0: F7 54 D7 54 F7 54 F7 54-D7 54 F7 54 F7 54 F7 54 .T.T.T.T.T.T.T.T
7AD0: F7 54 F7 54 F7 54 F7 54-F7 54 F7 54 F7 54 F7 54 .T.T.T.T.T.T.T.T
7AE0: F7 54 D7 54 F7 54 F7 54-F7 54 F7 54 F7 54 F7 54 .T.T.T.T.T.T.T.T
7AF0: F7 54 F7 54 F7 54 F7 54-F7 54 F7 54 F7 54 F7 54 .T.T.T.T.T.T.T.T
7B00: 83 10 83 10 83 10 83 10-83 10 83 10 83 10 83 10 ................
7B10: 83 10 83 10 83 10 83 10-83 10 83 10 83 10 83 10 ................
7B20: 83 10 83 10 83 10 83 10-83 10 83 10 83 10 83 10 ................
7B30: 83 10 83 10 83 10 83 10-83 10 83 10 83 10 83 10 ................
7B40: 83 10 83 10 83 10 83 10-83 10 83 10 83 10 83 10 ................
7B50: 83 10 83 10 83 10 83 10-83 10 83 10 83 10 83 10 ................
7B60: 00 10 83 10 83 10 83 10-83 10 83 10 83 10 83 10 ................
7B70: 83 10 83 10 83 10 83 10-83 10 83 00 83 10 83 10 ................
7B80: D7 54 F7 54 D7 54 97 54-97 54 F7 54 D7 54 F7 54 .T.T.T.T.T.T.T.T
7B90: D7 54 D7 54 D7 54 F7 54-D7 54 D7 54 F7 54 F7 54 .T.T.T.T.T.T.T.T
7BA0: D7 54 D7 54 F7 54 F7 54-D7 54 D7 54 D7 54 D7 54 .T.T.T.T.T.T.T.T
7BB0: D7 54 D7 54 F7 54 F7 54-D7 54 F7 54 F7 54 F7 54 .T.T.T.T.T.T.T.T
7BC0: F7 54 D7 54 D7 54 D7 54-D7 54 D7 54 D7 54 F7 54 .T.T.T.T.T.T.T.T
7BD0: 97 54 D7 54 D7 54 F7 54-F7 54 D7 54 F7 54 F7 54 .T.T.T.T.T.T.T.T
7BE0: D7 54 D7 54 97 54 D7 54-D7 54 F7 54 D7 54 F7 54 .T.T.T.T.T.T.T.T
7BF0: 97 54 D7 54 F7 54 D3 50-D7 54 D7 54 F7 54 83 10 .T.T.T.P.T.T.T..
7C00: 0B 16 0B 12 0B 12 0B 12-0B 16 0B 12 0B 12 0B 12 ................
7C10: 0B 12 0B 12 0B 12 0B 12-0B 12 0B 12 0B 12 0B 12 ................
7C20: 0B 12 0B 12 0B 12 0B 12-0B 12 0B 12 0B 12 0B 12 ................
7C30: 0B 12 0B 12 0B 12 0B 12-0B 12 0B 12 0B 12 0B 12 ................
7C40: 0B 12 0B 12 0B 12 0B 12-0B 12 0B 12 0B 12 0B 12 ................
7C50: 0B 12 0B 12 0B 12 0B 12-0B 12 0B 12 0B 12 0B 12 ................
7C60: 0B 12 0B 12 0B 12 0B 12-0B 12 0B 12 0B 12 0B 12 ................
7C70: 0B 12 0B 12 03 12 0B 12-0B 12 0B 12 0B 12 0B 12 ................
7C80: 9B 56 BF 56 9F 56 BF 56-BB 56 BF 56 9F 56 BB 56 .V.V.V.V.V.V.V.V
7C90: BF 56 9B 56 BF 56 BF 56-BB 56 AF 56 BF 56 BF 56 .V.V.V.V.V.V.V.V
7CA0: BB 56 BF 56 BF 56 BF 56-9B 56 BF 56 BF 56 BF 56 .V.V.V.V.V.V.V.V
7CB0: 9F 56 BF 56 BF 56 BF 56-AB 56 BF 56 BF 56 BF 56 .V.V.V.V.V.V.V.V
7CC0: BF 56 BB 56 BF 56 BF 56-BF 56 BF 56 BF 56 BF 56 .V.V.V.V.V.V.V.V
7CD0: BF 56 BF 56 BF 56 BF 56-AF 56 BF 56 BB 56 BB 56 .V.V.V.V.V.V.V.V
7CE0: BF 56 BF 56 9F 56 BF 56-BF 56 9F 56 BB 56 9F 56 .V.V.V.V.V.V.V.V
7CF0: AB 56 BF 56 BF 56 BF 56-BB 56 BF 56 BF 56 8F 56 .V.V.V.V.V.V.V.V
7D00: 0B 12 0B 12 0B 12 0B 12-0B 12 0B 12 0B 12 0B 12 ................
7D10: 0B 12 0B 12 0B 12 0B 12-0B 12 0B 12 0B 12 0B 12 ................
7D20: 0B 12 0B 12 0B 12 0B 12-0B 12 0B 12 0B 12 0B 12 ................
7D30: 0B 12 0B 12 0B 12 8B 12-0B 12 0B 12 0B 12 0B 12 ................
7D40: 0B 12 0B 12 0B 12 0B 12-0B 12 0B 12 0B 12 0B 12 ................
7D50: 0B 12 0B 12 0B 12 0B 12-0B 12 0B 12 0B 12 0B 12 ................
7D60: 08 10 0B 12 0B 12 0B 12-0B 12 0B 12 0B 12 0B 12 ................
7D70: 0B 12 0B 12 0B 12 0B 12-0B 12 0B 02 0B 12 8B 12 ................
7D80: 9B 56 8F 56 AF 56 BF 56-BF 56 8F 56 AF 56 BB 56 .V.V.V.V.V.V.V.V
7D90: BB 56 BB 56 BF 56 BF 56-BF 56 BF 56 BB 56 BF 56 .V.V.V.V.V.V.V.V
7DA0: AB 56 BB 56 BF 56 BF 56-BF 56 BF 56 BF 56 BF 56 .V.V.V.V.V.V.V.V
7DB0: BF 56 BF 56 BF 56 BF 56-BF 56 BB 56 BF 56 BF 56 .V.V.V.V.V.V.V.V
7DC0: BB 56 BF 56 AF 56 BF 56-BB 56 BF 56 BB 56 BB 56 .V.V.V.V.V.V.V.V
7DD0: BB 56 BB 56 BF 56 BB 56-9F 56 BF 56 BB 56 BF 56 .V.V.V.V.V.V.V.V
7DE0: BB 56 AB 56 AF 56 BB 56-BB 56 BB 56 BB 56 BB 56 .V.V.V.V.V.V.V.V
7DF0: BB 56 BB 56 AF 56 9F 16-BB 56 BB 56 BF 56 8B 16 .V.V.V...V.V.V..
7E00: 0E AC 02 A8 02 A8 02 A8-06 A8 02 A8 02 A8 02 A8 ................
7E10: 02 A8 02 A8 02 A8 02 A8-02 A8 02 A8 02 A8 02 A8 ................
7E20: 02 A8 02 A8 02 A8 02 A8-02 A8 02 A8 02 A8 02 A8 ................
7E30: 02 A8 02 A8 02 A8 02 A8-02 A8 02 A8 02 A8 02 A8 ................
7E40: 02 A8 02 A8 02 A8 02 A8-02 A8 02 A8 02 A8 02 A8 ................
7E50: 02 A8 02 A8 02 A8 02 A8-02 A8 02 A8 02 A8 02 A8 ................
7E60: 02 A8 02 A8 02 A8 02 A8-02 A8 02 A8 02 A8 02 A8 ................
7E70: 02 A8 02 A8 02 A0 02 A8-02 A8 02 A8 02 A8 02 A8 ................
7E80: 0E FE 0E FE 0E FE 0E FE-0E FE 0E FE 0E FE 0E FE ................
7E90: 0E FE 0E FE 0E FE 0E FE-0E FE 0E FE 0E FE 0E FE ................
7EA0: 0E FE 0E FE 0E FE 0E FE-0E FE 0E FE 0E FE 0E FE ................
7EB0: 0E FE 0E FE 0E FE 0E FE-0E FE 0E FE 0E FE 0E FE ................
7EC0: 0E FE 0E FE 0E FE 0E FE-0E FE 0E FE 0E FE 0E FE ................
7ED0: 0E FE 0E FE 0E FE 0E FE-0E FE 0E FE 0E FE 0E FE ................
7EE0: 0E FE 0E FE 0E FE 0E FE-0E FE 0E FE 0E FE 0E FE ................
7EF0: 0E FE 0E FE 0E FE 0E FE-0E FE 0E FE 0E FE 0E FE ................
7F00: 02 A8 02 A8 02 A8 02 A8-02 A8 02 A8 02 A8 02 A8 ................
7F10: 02 A8 02 A8 02 A8 02 A8-02 A8 02 A8 02 A8 02 A8 ................
7F20: 02 A8 02 A8 02 A8 02 A8-02 A8 02 A8 02 A8 02 A8 ................
7F30: 02 A8 02 A8 02 A8 02 A8-02 A8 02 A8 02 A8 02 A8 ................
7F40: 02 A8 02 A8 02 A8 02 A8-02 A8 02 A8 02 A8 02 A8 ................
7F50: 02 A8 02 A8 02 A8 02 A8-02 A8 02 A8 02 A8 02 A8 ................
7F60: 00 08 02 A8 02 A8 02 A8-02 A8 02 A8 02 A8 02 A8 ................
7F70: 02 A8 02 A8 02 A8 02 A8-02 A8 02 A8 02 A8 02 A8 ................
7F80: 0E FE 0E FE 0E FE 0E FE-0E FE 0E FE 0E FE 0E FE ................
7F90: 0E FE 0E FE 0E FE 0E FE-0E FE 0E FE 06 FE 0E FE ................
7FA0: 0E FE 0E FE 0E FE 0E FE-0E FE 0E FE 0E FE 0E FE ................
7FB0: 0E FE 0E FE 0E FE 0E FE-0E FE 0E FE 0E FE 0E FE ................
7FC0: 0E FE 06 FE 0E FE 0E FE-0E FE 0E FE 0E FE 0E FE ................
7FD0: 0E FE 0E FE 0E FE 0E FE-0E FE 0E FE 0E FE 0E FE ................
7FE0: 0E FE 0E FE 0E FE 0E FE-0E FE 0E FE 0E FE 0E FE ................
7FF0: 0E FE 0E FE 0E FE 06 FC-0E FE 0E FE 0E FE 02 AC ................

