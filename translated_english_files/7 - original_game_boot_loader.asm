;  This file, pista0.asm, contains the assembly code for the boot loader of the original version of "La abadía del crimen." It's the very first
;  code that executes from the game disk when loaded on an Amstrad CPC.
;
;  Its main functions are:
;
;   1. System Initialization: It sets up the computer's initial state by disabling interrupts, setting the stack pointer, configuring the screen
;      mode (Mode 0), and writing the color palette for the game's presentation screen.
;   2. Low-Level Disk Access: The file contains all the necessary low-level routines to directly control the floppy disk drive. This includes
;      functions to turn the drive motor on/off, seek specific tracks, send commands to the disk controller, and read data sector by sector.
;   3. Loading Game Data: Its primary responsibility is to load the main game files from the disk tracks into the correct memory banks. It reads
;      the data for abadia0.bin, abadia1.bin, abadia2.bin, etc., and places them in their designated memory locations.
;   4. Starting the Game: After all the necessary files have been loaded into memory, the loader executes a ret instruction. This pops an
;      address (0x0400) previously pushed to the stack, effectively jumping to the main game code and starting the game.
;
;  In summary, pista0.asm is a custom, high-performance boot loader that bypasses the standard operating system to load the game's data directly
;  and efficiently from the disk, a common practice for commercial games of that era to maximize performance and implement custom loading
;  schemes.

; ------------- code on track 0, sector 0 of the game disk ---------------------------
;  (this is reached after typing "|cpm" at AMSDOS)
0100: F3          di
0101: 31 00 01    ld   sp,$0100		; set the stack
0104: 21 00 04    ld   hl,$0400
0107: E5          push hl           ; push 0x400 as return address
0108: 01 8C 7F    ld   bc,$7F8C     ; gate array -> 10001100 (select screen mode, rom config and int control)
010B: ED 49       out  (c),c        ;  select mode 0 and disable upper and lower rom
010D: CD 82 01    call $0182		; write color palette for presentation image
	14 1B 1F 1C 00 1D 0E 05 0D 15 04 0C 06 03 0B 14 07 	; border color and pen colors (from 15 to 0)

0121: 3E 01       ld   a,$01
0123: 01 7E FA    ld   bc,$FA7E		; enable disk drive motor
0126: ED 79       out  (c),a
0128: 3E 03       ld   a,$03
012A: CD B5 01    call $01B5		; delay sometimes

012D: 01 C7 01    ld   bc,$01C7		; initial track = 1, memory configuration 7 (0, 7, 2, 3)
0130: 21 FF FF    ld   hl,$FFFF		; data starts copying from 0xffff downwards
0133: 3E 11       ld   a,$11		; copy to 0xc000-0xffff abadia0.bin, to 0x8000-0xbfff abadia3, to 0x4000-0x7fff abadia8.bin and to 0x0100-0x3fff abadia1.bin
0135: CD 5C 01    call $015C		; read disk data from track b for a tracks, setting memory configuration indicated by c, and saving data at hl (downwards)
0138: 01 C6 12    ld   bc,$12C6		; copy to bank 6 (tracks 0x12-0x16) (abadia7.bin)
013B: CD 57 01    call $0157		; read disk data from track b to track b+4, setting memory configuration indicated by c, and saving data at 0x4000-0x7fff
013E: 01 C5 17    ld   bc,$17C5		; copy to bank 5 (tracks 0x17-0x1b) (abadia6.bin)
0141: CD 57 01    call $0157		; read disk data from track b to track b+4, setting memory configuration indicated by c, and saving data at 0x4000-0x7fff
0144: 01 C4 1C    ld   bc,$1CC4		; copy to bank 4 (tracks 0x1c-0x20) (abadia5.bin)
0147: CD 57 01    call $0157		; read disk data from track b to track b+4, setting memory configuration indicated by c, and saving data at 0x4000-0x7fff
014A: 01 C0 21    ld   bc,$21C0		; copy to bank 0 (tracks 0x21-0x25) (abadia2.bin)
014D: CD 57 01    call $0157		; read disk data from track b to track b+4, setting memory configuration indicated by c, and saving data at 0x4000-0x7fff
0150: AF          xor  a
0151: 01 7E FA    ld   bc,$FA7E
0154: ED 79       out  (c),a		; turn off disk drive motor
0156: C9          ret				; jump to game start (0x0400)

; read disk data from track b to track b+4, setting memory configuration indicated by c, and saving data at 0x4000-0x7fff
0157: 21 FF 7F    ld   hl,$7FFF		; copy to 0x4000-0x7fff
015A: 3E 05       ld   a,$05		; copy 5 tracks

; read disk data from track b for a tracks, setting memory configuration indicated by c, and saving data at hl (downwards)
; a = number of tracks to copy
; b = initial track
; c = memory configuration to set
; hl = memory position where to start copying data (copies from top to bottom)
015C: 80          add  a,b
015D: 32 7E 01    ld   ($017E),a	; modify instruction with the last track to read
0160: 78          ld   a,b			; a = initial track
0161: 06 7F       ld   b,$7F
0163: ED 49       out  (c),c		; set memory configuration passed in c
0165: 01 7E FB    ld   bc,$FB7E		; bc = main disk drive register

0168: F5          push af
0169: 32 25 02    ld   ($0225),a	; modify track in command
016C: CD 96 01    call $0196		; write seek command for track a
016F: 11 22 02    ld   de,$0222		; point to read command data
0172: CD C0 01    call $01C0		; write command pointed by de to drive
0175: CD 18 02    call $0218		; read bytes from disk drive and copy to memory in descending order
0178: CD CD 01    call $01CD		; read bytes sent by disk drive after a command, and save to buffer
017B: F1          pop  af
017C: 3C          inc  a			; advance to next track
017D: FE 12       cp   $12			; instruction modified from outside with the last track to read
017F: 20 E7       jr   nz,$0168
0181: C9          ret

; write color palette for presentation image
0182: E1          pop  hl			; get return address
0183: 3E 11       ld   a,$11
0185: 06 7F       ld   b,$7F		; pen and border selection
0187: 4F          ld   c,a
0188: 0D          dec  c
0189: ED 49       out  (c),c		; select a pen or border
018B: 4E          ld   c,(hl)
018C: 23          inc  hl
018D: CB F1       set  6,c
018F: ED 49       out  (c),c
0191: 3D          dec  a
0192: 20 F3       jr   nz,$0187		; repeat until colors are complete
0194: E5          push hl
0195: C9          ret

; write seek command for track a
0196: F5          push af
0197: 3E 0F       ld   a,$0F		; seek command
0199: CD F8 01    call $01F8		; wait for drive to be ready, and if possible, send data
019C: AF          xor  a			; head 0, drive 0
019D: CD F8 01    call $01F8		; wait for drive to be ready, and if possible, send data
01A0: F1          pop  af			; recover track to seek
01A1: CD F8 01    call $01F8		; wait for drive to be ready, and if possible, send data
01A4: 3E 01       ld   a,$01
01A6: 11 20 4E    ld   de,$4E20
01A9: CD B5 01    call $01B5		; small delay
01AC: 3E 08       ld   a,$08		; command to get status information
01AE: CD F8 01    call $01F8		; wait for drive to be ready, and if possible, send data
01B1: CD CD 01    call $01CD		; read bytes sent by disk drive after a command, and save to buffer
01B4: C9          ret

; wait an amount of time proportional to a and de
01B5: F5          push af
01B6: 1B          dec  de
01B7: 7B          ld   a,e
01B8: B2          or   d
01B9: 20 FB       jr   nz,$01B6		; while de is not 0, decrement it
01BB: F1          pop  af
01BC: 3D          dec  a			; repeat a times
01BD: 20 F6       jr   nz,$01B5
01BF: C9          ret

; write command pointed by de to drive
01C0: 1A          ld   a,(de)		; read number of bytes in command
01C1: 13          inc  de
01C2: F5          push af			; save number of bytes in command
01C3: 1A          ld   a,(de)
01C4: CD F8 01    call $01F8		; wait for drive to be ready, and if possible, send data
01C7: 13          inc  de			; move to next position
01C8: F1          pop  af
01C9: 3D          dec  a
01CA: 20 F6       jr   nz,$01C2		; repeat until command bytes are finished
01CC: C9          ret

; read bytes sent by disk drive after a command, and save to buffer
01CD: E5          push hl
01CE: D5          push de
01CF: 16 00       ld   d,$00		; initialize byte counter
01D1: 21 64 00    ld   hl,$0064		; point to buffer
01D4: E5          push hl
01D5: ED 78       in   a,(c)		; read status register 0
01D7: FE C0       cp   $C0
01D9: 38 FA       jr   c,$01D5		; wait for drive to be ready
01DB: 0C          inc  c			; point to data register
01DC: ED 78       in   a,(c)		; read result of seek command
01DE: 0D          dec  c			; point to status register
01DF: 77          ld   (hl),a		; save read data
01E0: 23          inc  hl
01E1: 14          inc  d
01E2: 3E 05       ld   a,$05		; wait a bit
01E4: 3D          dec  a
01E5: 20 FD       jr   nz,$01E4
01E7: ED 78       in   a,(c)		; wait for transfer to complete
01E9: E6 10       and  $10
01EB: 20 E8       jr   nz,$01D5
01ED: E1          pop  hl			; recover initial buffer position
01EE: 7E          ld   a,(hl)		; check operation status
01EF: E6 C0       and  $C0
01F1: 2B          dec  hl
01F2: 72          ld   (hl),d		; save number of bytes read
01F3: D1          pop  de
01F4: E1          pop  hl
01F5: C0          ret  nz			; if there was any error, exit
01F6: 37          scf				; if everything went well, set carry flag
01F7: C9          ret

; wait for drive to be ready, and if possible, send data
01F8: F5          push af
01F9: F5          push af
01FA: ED 78       in   a,(c)		; read drive status register
01FC: 87          add  a,a
01FD: 30 FB       jr   nc,$01FA		; wait for data register to be ready to receive or send data
01FF: 87          add  a,a
0200: 30 03       jr   nc,$0205		; if a transfer from processor to data register must be done, jump
0202: F1          pop  af
0203: F1          pop  af
0204: C9          ret

; arrive here if drive expects data
0205: F1          pop  af			; recover value
0206: 0C          inc  c			; point to data register
0207: ED 79       out  (c),a		; write value to data register
0209: 0D          dec  c			; point to control register
020A: 3E 05       ld   a,$05
020C: 3D          dec  a
020D: 00          nop
020E: 20 FC       jr   nz,$020C		; wait a bit
0210: F1          pop  af
0211: C9          ret

; read a byte from disk drive and copy to memory
0212: 0C          inc  c			; point to data register
0213: ED 78       in   a,(c)		; read a byte from selected sector of current track
0215: 77          ld   (hl),a		; save to memory
0216: 0D          dec  c			; point to status register
0217: 2B          dec  hl			; decrement buffer pointer

; read bytes from disk drive and copy to memory in descending order
0218: ED 78       in   a,(c)		; read status register
021A: F2 18 02    jp   p,$0218
021D: E6 20       and  $20
021F: 20 F1       jr   nz,$0212		; if read operation not completed, read another byte
0221: C9          ret

; read command data
0222: 	09 -> number of bytes in command
	66 -> read data command, double density, single track
	00 -> head 0, drive 0
	01 -> track number (modified from outside)
	00 -> head 0
	21 -> initial sector number for reading
	01 -> bytes per sector (in multiples of 0x100)
	2F -> final sector number for reading
	0E -> gap length (GAP3)
	1F -> not used

; -------------------- this part of code is never used -----------------------
022C: 3E 08       ld   a,$08		; command to get status information
022E: CD F8 01    call $01F8		; wait for drive to be ready, and if possible, send data
0231: CD CD 01    call $01CD		; read bytes sent by disk drive after a command, and save to buffer
0234: C9          ret

; wait an amount of time proportional to a and de
0235: F5          push af
0236: 1B          dec  de
0237: 7B          ld   a,e
0238: B2          or   d
0239: 20 FB       jr   nz,$0236		; while de is not 0, decrement it
023B: F1          pop  af
023C: 3D          dec  a			; repeat a times
023D: 20 F6       jr   nz,$0235
023F: C9          ret

; write command pointed by de to drive
0240: 1A          ld   a,(de)
0241: 13          inc  de
0242: F5          push af
0243: 1A          ld   a,(de)
0244: CD F8 01    call $01F8		; wait for drive to be ready, and if possible, send data
0247: 13          inc  de
0248: F1          pop  af
0249: 3D          dec  a
024A: 20 F6       jr   nz,$0242
024C: C9          ret

; read bytes sent by disk drive after a command, and save to buffer
024D: E5          push hl
024E: D5          push de
024F: 16 00       ld   d,$00
0251: 21 64 00    ld   hl,$0064
0254: E5          push hl
0255: ED 78       in   a,(c)
0257: FE C0       cp   $C0
0259: 38 FA       jr   c,$0255
025B: 0C          inc  c
025C: ED 78       in   a,(c)
025E: 0D          dec  c
025F: 77          ld   (hl),a
0260: 23          inc  hl
0261: 14          inc  d
0262: 3E 05       ld   a,$05
0264: 3D          dec  a
0265: 20 00       jr   nz,$0267
; the routine is incomplete...
;  from 0x267 to 0x3ff there is 0x00
; -----------------------------------------------------------------
