;  The file pirtata.asm is the assembly language loader for a pirated version of "La abadía del crimen."
;
;  Here's a breakdown of its function:
;
;   1. Initial BASIC Loader: The initial comments describe a BASIC program that sets up the screen and palette, then loads and runs abadia.bin,
;      which contains the assembly code from this file.
;   2. Self-relocation: The first part of the assembly code copies a portion of itself to a lower memory address (0x0050) and then jumps to it.
;      This is a common technique to free up the original loading address for other data.
;   3. File Loading Sequence: The core function of this code is to load the various game files (abadia0.bin, abadia1.bin, abadia2.bin, etc.)
;      into the correct memory addresses and banks. It does this by repeatedly modifying a filename template ("ABADIA") and calling a
;      file-loading routine.
;   4. Memory Reconstruction: After loading, it performs several memory copy operations, moving blocks of data around. This suggests that the
;      pirate version split the original game into multiple files, and this loader's job is to piece them back together in memory to match the
;      layout of the original, non-pirated version.
;   5. Game Start: Once all files are loaded and the memory is correctly set up, it executes a final jump to address 0x0400, which the comments
;      identify as "the real start of the game."
;
;  In essence, pirtata.asm is a custom loader designed to bypass the original copy protection by reassembling the game from a collection of
;  split files.



; The pirate version of the game has a BASIC loader:
;
; 10 	Mode 0
; 	Border 0
; 20 	For i = 0 to 15
; 		Read a$
; 		Ink i,Val(a$)
; 	Next
; 30	Memory &9fff
; 	Load "abadia.bin", &a000
; 40	Call &A000
; 50	Data 	16, 00, 26, 24, 10, 15, 01, 00,
; 				00, 00, 24, 00, 14, 03 ,00, 20

;  which is in charge of setting the palette (which by the way, is not the same as the original game) and jumping to the following code,
; which loads the files in which the original game track data has been split into the same memory positions
; as the original version

A000: F3          di				; disable interrupts
A001: 21 0F A0    ld   hl,$A00F		; source of the data (abadia.bin)
A004: 11 50 00    ld   de,$0050		; destination address
A007: 01 B0 00    ld   bc,$00B0		; length of data to copy
A00A: ED B0       ldir				; copy bytes from source to destination
A00C: C3 50 00    jp   $0050		; jump to copied data

A00F: ; data copied to 0x0050-0x00ff

; data copied from abadia.bin and to which we jump at start
0050: ld   hl,$C000					; point to video memory
0053: ld   ($00F6),hl				; save destination address at 0x00f6
0056: ld   a,$30
0058: ld   ($00F5),a				; place a 0 in the filename (abadia0.bin)
005B: call $00D6					; show presentation screen
005E: ld   bc,$7FC7					; set configuration 7 (0, 7, 2, 3)
0063: ld   hl,$4000
0066: ld   ($00F6),hl				; save destination address at 0x00f6
0069: ld   a,$38
006B: ld   ($00F5),a				; place an 8 in the filename (abadia8.bin)
006E: call $00D6					; load file in bank 7
0071: ld   bc,$7FC6					; set configuration 6 (0, 6, 2, 3)
0074: out  (c),c
0076: call $00D6					; load file (abadia7.bin)
0079: ld   bc,$7FC5					; set configuration 5 (0, 5, 2, 3)
007C: out  (c),c
007E: call $00D6					; load file (abadia6.bin)
0081: ld   bc,$7FC4					; set configuration 4 (0, 4, 2, 3)
0084: out  (c),c
0086: call $00D6					; load file (abadia5.bin)
0089: ld   bc,$7FC0					; set configuration 0 (0, 1, 2, 3)
008C: out  (c),c
008E: ld   a,$32
0090: ld   ($00F5),a				; place a 2 in the filename (abadia2.bin)
0093: call $00D6					; load file
0096: ld   hl,$0100
0099: ld   ($00F6),hl				; save destination address at 0x00f6
009C: call $00D6					; load file (abadia1.bin)

009F: di
00A0: ld   hl,$C7D0					; point to video memory
00A3: ld   de,$0050					; point to destination
00A6: ld   bc,$0030
00A9: ldir							; copy some bytes read from the presentation screen (???)

00AB: ld   hl,$C000					; set 0xc000 as destination
00AE: ld   ($00F6),hl
00B1: ld   a,$33					; place a 3 in the filename (abadia3.bin)
00B3: ld   ($00F5),a
00B6: call $00D6					; load file
00B9: di
00BA: ld   sp,$0100					; place stack at 0x0100
00BD: ld   hl,$C000					; copy what was just read to the gap that was there
00C0: ld   de,$8000
00C3: ld   bc,$4000
00C6: ldir
00C8: ld   hl,$0050					; copy what was saved from abadia0.bin to what was copied from abadia3.bin (???)
00CB: ld   de,$C7D0
00CE: ld   bc,$0030
00D1: ldir

00D3: jp   $0400					; jump to the real start of the game

00D6: ld   b,$07					; filename length
00D8: ld   de,$C000					; destination buffer
00DB: ld   hl,$00EF					; filename address
00DE: call $BC77					; open buffer and read address
00E1: ld   hl,($00F6)				; get destination pointer
00E4: call $BC83					; read complete file to memory
00E7: call $BC7A					; close file
00EA: ld   hl,$00F5
00ED: dec  (hl)						; decrement filename
00EE: ret

00EF: ABADIA
