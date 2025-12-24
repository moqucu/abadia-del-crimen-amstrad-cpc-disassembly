; --------------- Commented disassembly of the game "The Abbey of Crime" for Amstrad CPC 6128, by Manuel Abadia ------------------
;
; There are 2 versions of the game circulating, the original, which is loaded with '|cpm', and the pirate version, which is loaded with 'run "abadia'
; The pirate version is the same as the original, except that the presentation screen uses different colors for the palette, and that the
; game data is not stored directly on the tracks as in the original, but instead the disk has a file system.
; Another disadvantage of the pirate version is that since the game allows saving the game, and it does so on the cylinders where the
; information was in the original game, but since the data in the pirate version is not in the same place and the disk does not have the same
; format, it is not saved correctly.
;
; To understand how the game works, there are a series of files that accompany it. These files are:
; * mapamemoria.txt -> contains the game's memory map
; * maparoms.txt -> contains the memory map of the game files
; * mapadisco.txt -> contains information about what data and in what way it is saved on the original game disk
; * pista0.asm -> contains the code from track 0 of the game disk that loads the data into memory and jumps to the start of the game
; * pirata.asm -> contains the code to load the game data and jump to the start of the game in the pirate version
;
; To name the data areas, the name of the file containing the data in the pirate game is used, since it is more manageable
; to say that it places the data from abadia7.bin at 0x4000-0x7fff than to say it loads the data from tracks 0x12-0x16
;
; During game startup, the Amstrad's memory banks have ended up in the following state:
; 0 -> abadia1.bin (from 0x100)
; 1 -> abadia2.bin
; 2 -> abadia3.bin
; 3 -> abadia0.bin (screen memory)
; 4 -> abadia5.bin
; 5 -> abadia6.bin
; 6 -> abadia7.bin
; 7 -> abadia8.bin
;
; The memory configuration normally used throughout the program is (0, 1, 2, 3)
; Throughout the game, in positions 0x0000-0x3fff, 0x8000-0xbfff and 0xc000-0xffff banks 0, 2 and 3 are mapped respectively
; In the 0x4000-0x7fff area, bank 1 is usually mapped, although when necessary banks 4, 5, 6 and 7 are mapped
; Bank 4 contains a debugger for the Z80, which I suppose was used by Paco Menendez to debug the game. The commented code for
; this debugger is available in the file depurador.asm and the associated memory map is in the file depmem.txt
;
; Once the load is complete, it jumps to 0x0400, which is where the game really starts
;
; NOTE: some comments may be outdated or incorrect, but I have not had time to review all the code
; ------------------------------------------------------------------------------------------------------------------




; abadia1.bin (0x0100-0x3fff)
; -------------- from 0x0103 to 0x03ff there is code that gets overwritten with program data --------------------------
0100: F3          di
0101: 31 00 01    ld   sp,$0100		; sets the stack
0104: 21 00 03    ld   hl,$0300		; puts 0x0300 as return address (??? there is no valid code at 0x0300)
0107: E5          push hl
0108: 01 8D 7F    ld   bc,$7F8D		; gate array -> 10001101 (select screen mode, rom cfig and int control)
010B: ED 49       out  (c),c		;  selects mode 1 and disables upper and lower rom
010D: CD 82 01    call $0182		; writes the color palette
	00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00	; border color and pen colors (from 15 to 0)

0121: 3E 01       ld   a,$01
0123: 01 7E FA    ld   bc,$FA7E		; activates the disk drive motor
0126: ED 79       out  (c),a
0128: 3E 03       ld   a,$03
012A: CD B5 01    call $01B5		; delay sometimes

012D: 01 C7 01    ld   bc,$01C7		; initial track = 1, memory configuration 7 (0, 7, 2, 3)
0130: 21 FF FF    ld   hl,$FFFF		; data starts copying from 0xffff downwards
0133: 3E 11       ld   a,$11		; copies to 0xc000-0xffff abadia0.bin in 0x8000-0xbfff abadia3, in 0x4000-0x7fff abadia8.bin and in 0x0100-0x3fff abadia1.bin
0135: CD 5C 01    call $015C		; reads disk data from a tracks from track b, setting the memory configuration indicated by c, and saving the data at hl (downwards)
0138: 01 C6 12    ld   bc,$12C6		; copies to bank 6 (tracks 0x12-0x16) (abadia7.bin)
013B: CD 57 01    call $0157		; reads disk data from track b to track b+4, setting the memory configuration indicated by c, and saving the data at 0x4000-0x7fff
013E: 01 C5 17    ld   bc,$17C5		; copies to bank 5 (tracks 0x17-0x1b) (abadia6.bin)
0141: CD 57 01    call $0157		; reads disk data from track b to track b+4, setting the memory configuration indicated by c, and saving the data at 0x4000-0x7fff
0144: 01 C4 1C    ld   bc,$1CC4		; copies to bank 4 (tracks 0x1c-0x20) (abadia5.bin)
0147: CD 57 01    call $0157		; reads disk data from track b to track b+4, setting the memory configuration indicated by c, and saving the data at 0x4000-0x7fff
014A: 01 C0 21    ld   bc,$21C0		; copies to bank 0 (tracks 0x21-0x25) (abadia2.bin)
014D: CD 57 01    call $0157		; reads disk data from track b to track b+4, setting the memory configuration indicated by c, and saving the data at 0x4000-0x7fff
0150: AF          xor  a
0151: 01 7E FA    ld   bc,$FA7E
0154: ED 79       out  (c),a		; turns off the disk drive motor
0156: C9          ret				; jumps to 0x0300

; reads disk data from track b to track b+4, setting the memory configuration indicated by c, and saving the data at 0x4000-0x7fff
0157: 21 FF 7F    ld   hl,$7FFF		; copy to 0x4000-0x7fff
015A: 3E 05       ld   a,$05		; copies 5 tracks

; reads disk data from a tracks from track b, setting the memory configuration indicated by c, and saving the data at hl (downwards)
; a = number of tracks to copy
; b = initial track
; c = memory configuration to set
; hl = memory position where to start copying the data (copies from top to bottom)
015C: 80          add  a,b
015D: 32 7E 01    ld   ($017E),a	; modifies an instruction with the last track to read
0160: 78          ld   a,b			; a = initial track
0161: 06 7F       ld   b,$7F
0163: ED 49       out  (c),c		; sets the memory configuration passed in c
0165: 01 7E FB    ld   bc,$FB7E		; bc = disk drive main register

0168: F5          push af
0169: 32 25 02    ld   ($0225),a	; modifies the track in the command
016C: CD 96 01    call $0196		; writes a seek command for track a
016F: 11 22 02    ld   de,$0222		; points to the read command data
0172: CD C0 01    call $01C0		; writes the command pointed to by de to the drive
0175: CD 18 02    call $0218		; reads bytes from the disk drive and copies them to memory in descending order
0178: CD CD 01    call $01CD		; reads the bytes sent by the disk drive after a command, and saves them in a buffer
017B: F1          pop  af
017C: 3C          inc  a			; advances to the next track
017D: FE 12       cp   $12			; instruction modified from outside with the last track to read
017F: 20 E7       jr   nz,$0168
0181: C9          ret

; writes the color palette
0182: E1          pop  hl			; gets the return address
0183: 3E 11       ld   a,$11
0185: 06 7F       ld   b,$7F		; pen and border selection
0187: 4F          ld   c,a
0188: 0D          dec  c
0189: ED 49       out  (c),c		; selects a pen or border
018B: 4E          ld   c,(hl)
018C: 23          inc  hl
018D: CB F1       set  6,c
018F: ED 49       out  (c),c
0191: 3D          dec  a
0192: 20 F3       jr   nz,$0187		; repeats until all colors are complete
0194: E5          push hl
0195: C9          ret

; writes a seek command for track a
0196: F5          push af
0197: 3E 0F       ld   a,$0F		; seek command
0199: CD F8 01    call $01F8		; waits for the drive to be ready, and if possible, sends data
019C: AF          xor  a			; head 0, drive 0
019D: CD F8 01    call $01F8		; waits for the drive to be ready, and if possible, sends data
01A0: F1          pop  af			; recovers the track to seek
01A1: CD F8 01    call $01F8		; waits for the drive to be ready, and if possible, sends data
01A4: 3E 01       ld   a,$01
01A6: 11 20 4E    ld   de,$4E20
01A9: CD B5 01    call $01B5		; small delay
01AC: 3E 08       ld   a,$08		; command to get status information
01AE: CD F8 01    call $01F8		; waits for the drive to be ready, and if possible, sends data
01B1: CD CD 01    call $01CD		; reads the bytes sent by the disk drive after a command, and saves them in a buffer
01B4: C9          ret

; waits an amount of time proportional to a and de
01B5: F5          push af
01B6: 1B          dec  de
01B7: 7B          ld   a,e
01B8: B2          or   d
01B9: 20 FB       jr   nz,$01B6		; while de is not 0, decrements it
01BB: F1          pop  af
01BC: 3D          dec  a			; repeats a times
01BD: 20 F6       jr   nz,$01B5
01BF: C9          ret

; writes the command pointed to by de to the drive
01C0: 1A          ld   a,(de)		; reads the number of bytes in the command
01C1: 13          inc  de
01C2: F5          push af			; saves the number of bytes in the command
01C3: 1A          ld   a,(de)
01C4: CD F8 01    call $01F8		; waits for the drive to be ready, and if possible, sends data
01C7: 13          inc  de			; moves to the next position
01C8: F1          pop  af
01C9: 3D          dec  a
01CA: 20 F6       jr   nz,$01C2		; repeats until all command bytes are done
01CC: C9          ret

; reads the bytes sent by the disk drive after a command, and saves them in a buffer
01CD: E5          push hl
01CE: D5          push de
01CF: 16 00       ld   d,$00		; initializes the written bytes counter
01D1: 21 64 00    ld   hl,$0064		; points to a buffer
01D4: E5          push hl
01D5: ED 78       in   a,(c)		; reads status register 0
01D7: FE C0       cp   $C0
01D9: 38 FA       jr   c,$01D5		; waits for the drive to be ready
01DB: 0C          inc  c			; points to the data register
01DC: ED 78       in   a,(c)		; reads the result of the seek command
01DE: 0D          dec  c			; points to the status register
01DF: 77          ld   (hl),a		; saves the read data
01E0: 23          inc  hl
01E1: 14          inc  d
01E2: 3E 05       ld   a,$05		; waits a bit
01E4: 3D          dec  a
01E5: 20 FD       jr   nz,$01E4
01E7: ED 78       in   a,(c)		; waits for the transfer to finish
01E9: E6 10       and  $10
01EB: 20 E8       jr   nz,$01D5
01ED: E1          pop  hl			; recovers the initial buffer position
01EE: 7E          ld   a,(hl)		; checks the operation status
01EF: E6 C0       and  $C0
01F1: 2B          dec  hl
01F2: 72          ld   (hl),d		; saves the number of bytes read
01F3: D1          pop  de
01F4: E1          pop  hl
01F5: C0          ret  nz			; if there was an error, exits
01F6: 37          scf				; if things went well, sets the carry flag
01F7: C9          ret

; waits for the drive to be ready, and if possible, sends data
01F8: F5          push af
01F9: F5          push af
01FA: ED 78       in   a,(c)		; reads the drive status register
01FC: 87          add  a,a
01FD: 30 FB       jr   nc,$01FA		; waits for the data register to be ready to receive or send data
01FF: 87          add  a,a
0200: 30 03       jr   nc,$0205		; if a transfer from processor to data register is needed, jumps
0202: F1          pop  af
0203: F1          pop  af
0204: C9          ret

; arrives here if the drive expects data
0205: F1          pop  af			; recovers the value
0206: 0C          inc  c			; points to the data register
0207: ED 79       out  (c),a		; writes the value to the data register
0209: 0D          dec  c			; points to the control register
020A: 3E 05       ld   a,$05
020C: 3D          dec  a
020D: 00          nop
020E: 20 FC       jr   nz,$020C		; waits a bit
0210: F1          pop  af
0211: C9          ret

; reads a byte from the disk drive and copies it to memory
0212: 0C          inc  c			; points to the data register
0213: ED 78       in   a,(c)		; reads a byte from the selected sector of the current track
0215: 77          ld   (hl),a		; saves it to memory
0216: 0D          dec  c			; points to the status register
0217: 2B          dec  hl			; decrements the buffer pointer

; reads bytes from the disk drive and copies them to memory in descending order
0218: ED 78       in   a,(c)		; reads the status register
021A: F2 18 02    jp   p,$0218
021D: E6 20       and  $20
021F: 20 F1       jr   nz,$0212		; if the read operation is not complete, reads another byte
0221: C9          ret

; read command data
0222: 	09 -> number of bytes in the command
	66 -> read data command, double density, single track
	00 -> head 0, drive 0
	25 -> track number (modified from outside)
	00 -> head 0
	21 -> initial sector number for reading
	01 -> number of bytes per sector (in multiples of 0x100)
	2F -> final sector number for reading
	0E -> gap length (GAP3)
	1F -> not used

; write command data
022C: 	09 -> number of bytes in the command
	45 -> write data command, double density, single track
	00 -> head 0, drive 0
	11 -> track number
	00 -> head 0
	21 -> initial sector number for writing
	01 -> number of bytes per sector (in multiples of 0x100)
	2F -> final sector number for writing
	0E -> gap length (GAP3)
	FF -> not used

; ??? this routine is never called
0236: F3          di
0237: 3E 01       ld   a,$01
0239: 01 7E FA    ld   bc,$FA7E		; activates the disk drive motor
023C: ED 79       out  (c),a
023E: 3E 06       ld   a,$06
0240: CD B5 01    call $01B5		; delay sometimes

0243: CD D5 02    call $02D5		; recalibrates the disk drive

0246: 31 00 01    ld   sp,$0100		; sets the stack
0249: CD 21 01    call $0121		; loads all game data
024C: 3E 12       ld   a,$12
024E: 32 7E 01    ld   ($017E),a	; modifies the value of a routine (last track to read in the data read)
0251: 31 00 01    ld   sp,$0100		; sets the stack again

0254: F3          di
0255: CD EF 02    call $02EF		; copies the 4x8 cursor to the upper left corner of the screen and saves what it overwrote on the screen
0258: 3E 01       ld   a,$01
025A: 11 10 27    ld   de,$2710
025D: CD B5 01    call $01B5		; waits a while
0260: CD EF 02    call $02EF		; removes the cursor from the upper left corner and restores what was on the screen
0263: 3E 01       ld   a,$01
0265: 11 10 27    ld   de,$2710
0268: CD B5 01    call $01B5		; waits a while
026B: CD 0C 03    call $030C		; checks if space has been pressed
026E: 20 E4       jr   nz,$0254		; while space hasn't been pressed, keeps showing the blinking cursor

0270: 3E 01       ld   a,$01
0272: 01 7E FA    ld   bc,$FA7E		; activates the disk drive motor
0275: ED 79       out  (c),a
0277: 3E 06       ld   a,$06
0279: CD B5 01    call $01B5		; delay sometimes
027C: CD D5 02    call $02D5		; recalibrates the disk drive
027F: 01 C7 01    ld   bc,$01C7		; initial track = 1, memory configuration 7 (0, 7, 2, 3)
0282: 21 FF FF    ld   hl,$FFFF		; data starts copying from 0xffff downwards
0285: 3E 11       ld   a,$11		; copies 0xc000-0xffff abadia0.bin, 0x8000-0xbfff abadia3, 0x4000-0x7fff abadia8.bin and 0x0100-0x3fff abadia1.bin to disk
0287: CD AF 02    call $02AF		; writes data to disk from a tracks from track b, setting the memory configuration indicated by c, and reading the data from hl (downwards)
028A: 01 C6 12    ld   bc,$12C6		; writes what's in bank 6 (tracks 0x12-0x16) (abadia7.bin)
028D: CD AA 02    call $02AA		; copies the data to disk from track b to track b+4, setting the memory configuration indicated by c, and reading the data at 0x4000-0x7fff
0290: 01 C5 17    ld   bc,$17C5		; writes what's in bank 5 (tracks 0x17-0x1b) (abadia6.bin)
0293: CD AA 02    call $02AA		; copies the data to disk from track b to track b+4, setting the memory configuration indicated by c, and reading the data at 0x4000-0x7fff
0296: 01 C4 1C    ld   bc,$1CC4		; writes what's in bank 4 (tracks 0x1c-0x20) (abadia5.bin)
0299: CD AA 02    call $02AA		; copies the data to disk from track b to track b+4, setting the memory configuration indicated by c, and reading the data at 0x4000-0x7fff
029C: 01 C0 21    ld   bc,$21C0		; writes what's in bank 0 (tracks 0x21-0x25) (abadia2.bin)
029F: CD AA 02    call $02AA		; copies the data to disk from track b to track b+4, setting the memory configuration indicated by c, and reading the data at 0x4000-0x7fff
02A2: AF          xor  a
02A3: 01 7E FA    ld   bc,$FA7E
02A6: ED 79       out  (c),a		; turns off the disk drive motor
02A8: 18 AA       jr   $0254		; jumps to the routine that waits for space to be pressed to save the data again

; writes data to disk from track b to track b+4, setting the memory configuration indicated by c, and reading the data from 0x4000-0x7fff
02AA: 21 FF 7F    ld   hl,$7FFF
02AD: 3E 05       ld   a,$05

; writes data to disk from a tracks from track b, setting the memory configuration indicated by c, and reading the data from hl (downwards)
; a = number of tracks to write
; b = initial track
; c = memory configuration to set
; hl = memory position where to start getting the data (writes from top to bottom)
02AF: 80          add  a,b
02B0: 32 D1 02    ld   ($02D1),a	; modifies an instruction with the last track to write
02B3: 78          ld   a,b			; a = initial track
02B4: 06 7F       ld   b,$7F
02B6: ED 49       out  (c),c		; sets the memory configuration passed in c
02B8: 01 7E FB    ld   bc,$FB7E		; bc = disk drive main register
02BB: F5          push af
02BC: 32 2F 02    ld   ($022F),a	; modifies the track in the command
02BF: CD 96 01    call $0196		; writes a seek command for track a
02C2: 11 2C 02    ld   de,$022C		; points to the write command data
02C5: CD C0 01    call $01C0		; writes the command pointed to by de to the drive
02C8: CD 44 03    call $0344		; writes memory bytes to the disk drive
02CB: CD CD 01    call $01CD		; reads the bytes sent by the disk drive after a command, and saves them in a buffer
02CE: F1          pop  af
02CF: 3C          inc  a			; advances to the next track
02D0: FE 12       cp   $12			; instruction modified from outside with the last track to write
02D2: 20 E7       jr   nz,$02BB
02D4: C9          ret

; recalibrates the disk drive
02D5: 01 7E FB    ld   bc,$FB7E		; bc = disk drive main register
02D8: 3E 07       ld   a,$07		; command to recalibrate the drive
02DA: CD F8 01    call $01F8		; waits for the drive to be ready, and if possible, sends data
02DD: AF          xor  a			; drive 0
02DE: CD F8 01    call $01F8		; waits for the drive to be ready, and if possible, sends data
02E1: 3E 03       ld   a,$03
02E3: CD B5 01    call $01B5		; waits for the drive to be ready, and if possible, sends data
02E6: 3E 08       ld   a,$08		; command to get status information
02E8: CD F8 01    call $01F8		; waits for the drive to be ready, and if possible, sends data
02EB: CD CD 01    call $01CD		; reads the bytes sent by the disk drive after a command, and saves them in a buffer
02EE: C9          ret

; copies a 4x8 pixel rectangle from a buffer to screen, and saves what's on the screen in the buffer
02EF: 21 00 C0    ld   hl,$C000		; points to screen
02F2: 11 04 03    ld   de,$0304		; points to a buffer

; copies a 4x8 pixel rectangle from de to hl, and saves what's in hl to de
02F5: 06 08       ld   b,$08		; 8 bytes (32 pixels)
02F7: 4E          ld   c,(hl)		; reads a byte from screen
02F8: 1A          ld   a,(de)		; reads a byte from buffer
02F9: 77          ld   (hl),a		; copies the byte from buffer to screen
02FA: 79          ld   a,c
02FB: 12          ld   (de),a		; copies the byte from screen to buffer
02FC: 13          inc  de			; moves to the next buffer position
02FD: 7C          ld   a,h
02FE: C6 08       add  a,$08		; moves to the next screen line
0300: 67          ld   h,a
0301: 10 F4       djnz $02F7
0303: C9          ret

; buffer for the previous routine
0304: 00 00 0F 0F F0 F0 FF FF

; checks if space has been pressed
030C: F3          di
030D: 01 0E F4    ld   bc,$F40E		; 1111 0100 0000 1110 (8255 PPI port A)
0310: ED 49       out  (c),c
0312: 06 F6       ld   b,$F6
0314: ED 78       in   a,(c)
0316: E6 30       and  $30
0318: 4F          ld   c,a
0319: F6 C0       or   $C0
031B: ED 79       out  (c),a		; PSG write register index operation (activates 14 for port A communication)
031D: ED 49       out  (c),c		; PSG operation: inactive
031F: 04          inc  b			; points to the 8255 PPI control port
0320: 3E 92       ld   a,$92		; 1001 0010 (port A: input, port B: input, port C upper: output, port C lower: output)
0322: ED 79       out  (c),a
0324: C5          push bc

0325: 3E 45       ld   a,$45
0327: B1          or   c
0328: 4F          ld   c,a
0329: 06 F6       ld   b,$F6		; PSG operation: read data from register (line 5)
032B: ED 49       out  (c),c
032D: 06 F4       ld   b,$F4
032F: ED 78       in   a,(c)
0331: C1          pop  bc
0332: F5          push af			; saves the read line
0333: 3E 82       ld   a,$82		; 1001 0010 (port A: output, port B: input, port C upper: output, port C lower: output)
0335: ED 79       out  (c),a
0337: 05          dec  b
0338: ED 49       out  (c),c		; PSG operation: inactive
033A: F1          pop  af			; recovers the read line
033B: E6 80       and  $80			; keeps the space bar bit
033D: C9          ret

; writes a byte from memory to the disk drive
033E: 0C          inc  c			; points to the data register
033F: 7E          ld   a,(hl)		; reads a byte from memory
0340: ED 79       out  (c),a		; saves it to the selected sector of the current track
0342: 0D          dec  c			; points to the status register
0343: 2B          dec  hl			; points to the next byte to write

; writes bytes from memory to the disk drive
0344: ED 78       in   a,(c)		; reads the status register
0346: F2 44 03    jp   p,$0344
0349: E6 20       and  $20
034B: 20 F1       jr   nz,$033E		; if the write operation is not complete, writes another byte
034D: C9          ret

; ??? this routine is never called
034E: F1          pop  af
034F: 3C          inc  a
0350: FE 00       cp   $00
0352: 20 E7       jr   nz,$033B
0354: C9          ret

; recalibrates the disk drive
0355: 01 7E FB    ld   bc,$FB7E		; bc = disk drive main register
0358: 3E 07       ld   a,$07		; command to recalibrate the drive
035A: CD F8 01    call $01F8		; waits for the drive to be ready, and if possible, sends data
035D: AF          xor  a            ; drive 0
035E: CD F8 01    call $01F8        ; waits for the drive to be ready, and if possible, sends data
0361: 3E 03       ld   a,$03
0363: CD B5 01    call $01B5        ; waits for the drive to be ready, and if possible, sends data
0366: 3E 08       ld   a,$08        ; command to get status information
0368: CD F8 01    call $01F8        ; waits for the drive to be ready, and if possible, sends data
036B: CD CD 01    call $01CD        ; reads the bytes sent by the disk drive after a command, and saves them in a buffer
036E: C9          ret

; copies a 4x8 pixel rectangle from a buffer to screen, and saves what's on the screen in the buffer
036F: 21 00 C0    ld   hl,$C000		; points to screen
0372: 11 04 03    ld   de,$0304		; points to a buffer

; copies a 4x8 pixel rectangle from de to hl, and saves what's in hl to de
0375: 06 08       ld   b,$08        ; 8 bytes (32 pixels)
0377: 4E          ld   c,(hl)       ; reads a byte from screen
0378: 1A          ld   a,(de)       ; reads a byte from buffer
0379: 77          ld   (hl),a       ; copies the byte from buffer to screen
037A: 79          ld   a,c
037B: 12          ld   (de),a       ; copies the byte from screen to buffer
037C: 13          inc  de           ; moves to the next buffer position
037D: 7C          ld   a,h
037E: C6 08       add  a,$08        ; moves to the next screen line
; the routine is incomplete...
; from 0x380 to 0x3ff there are 0x00
; -------------- end of code that gets overwritten with program data --------------------------

; --------------------------------- actual game start --------------------------
; this is reached after copying the ROMs to the different memory banks
0400: C3 9A 24    jp   $249A	; jumps to perform game initialization

; -------------- code to save saved games from memory to disk --------------------------

; writes a seek command for track a
0403: F5          push af
0404: 3E 0F       ld   a,$0F	; seek command
0406: CD 65 04    call $0465	; waits for the drive to be ready, and if possible, sends data
0409: AF          xor  a		; head 0, drive 0
040A: CD 65 04    call $0465	; waits for the drive to be ready, and if possible, sends data
040D: F1          pop  af       ; recovers the track to seek
040E: CD 65 04    call $0465	; waits for the drive to be ready, and if possible, sends data
0411: 3E 01       ld   a,$01
0413: 11 20 4E    ld   de,$4E20
0416: CD 22 04    call $0422	; small delay
0419: 3E 08       ld   a,$08    ; command to get status information
041B: CD 65 04    call $0465	; waits for the drive to be ready, and if possible, sends data
041E: CD 3A 04    call $043A	; reads the bytes sent by the disk drive after a command, and saves them in a buffer
0421: C9          ret

; waits an amount of time proportional to a and de
0422: F5          push af
0423: 1B          dec  de
0424: 7B          ld   a,e
0425: B2          or   d
0426: 20 FB       jr   nz,$0423		; while de is not 0, decrements it
0428: F1          pop  af
0429: 3D          dec  a
042A: 20 F6       jr   nz,$0422		; repeats a times
042C: C9          ret

; writes the command pointed to by de to the drive
042D: 1A          ld   a,(de)		; reads the number of bytes in the command
042E: 13          inc  de
042F: F5          push af           ; saves the number of bytes in the command
0430: 1A          ld   a,(de)
0431: CD 65 04    call $0465		; waits for the drive to be ready, and if possible, sends data
0434: 13          inc  de           ; moves to the next position
0435: F1          pop  af
0436: 3D          dec  a
0437: 20 F6       jr   nz,$042F     ; repeats until all command bytes are done
0439: C9          ret

; reads the bytes sent by the disk drive after a command, and saves them in a buffer
043A: E5          push hl
043B: D5          push de
043C: 16 00       ld   d,$00			; initializes the written bytes counter
043E: 21 64 00    ld   hl,$0064         ; points to a buffer
0441: E5          push hl
0442: ED 78       in   a,(c)			; reads status register 0
0444: FE C0       cp   $C0
0446: 38 FA       jr   c,$0442          ; waits for the drive to be ready
0448: 0C          inc  c				; points to the data register
0449: ED 78       in   a,(c)            ; reads the result of the seek command
044B: 0D          dec  c				; points to the status register
044C: 77          ld   (hl),a           ; saves the read data
044D: 23          inc  hl
044E: 14          inc  d
044F: 3E 05       ld   a,$05            ; waits a bit
0451: 3D          dec  a
0452: 20 FD       jr   nz,$0451
0454: ED 78       in   a,(c)            ; waits for the transfer to finish
0456: E6 10       and  $10
0458: 20 E8       jr   nz,$0442
045A: E1          pop  hl               ; recovers the initial buffer position
045B: 7E          ld   a,(hl)           ; checks the operation status
045C: E6 C0       and  $C0
045E: 2B          dec  hl
045F: 72          ld   (hl),d           ; saves the number of bytes read
0460: D1          pop  de
0461: E1          pop  hl
0462: C0          ret  nz               ; if there was an error, exits
0463: 37          scf                   ; if things went well, sets the carry flag
0464: C9          ret

; waits for the drive to be ready, and if possible, sends data
0465: F5          push af
0466: F5          push af
0467: ED 78       in   a,(c)		; reads the status register
0469: 87          add  a,a
046A: 30 FB       jr   nc,$0467		; waits for the data register to be ready to receive or send data
046C: 87          add  a,a
046D: 30 03       jr   nc,$0472		; if a transfer from processor to data register is needed, jumps
046F: F1          pop  af
0470: F1          pop  af
0471: C9          ret

; arrives here if the drive expects data
0472: F1          pop  af			; recovers the value
0473: 0C          inc  c            ; points to the data register
0474: ED 79       out  (c),a		; writes the value to the data register
0476: 0D          dec  c            ; points to the control register
0477: 3E 05       ld   a,$05
0479: 3D          dec  a
047A: 00          nop
047B: 20 FC       jr   nz,$0479     ; waits a bit
047D: F1          pop  af
047E: C9          ret

; write command data
047F: 	09 -> number of bytes in the command
	45 -> write data command, double density, single track
	00 -> head 0, drive 0
	11 -> track number
	00 -> head 0
	21 -> initial sector number for writing
	01 -> number of bytes per sector (in multiples of 0x100)
	2F -> final sector number for writing
	0E -> gap length (GAP3)
	FF -> not used

; checks if ctrl+tab was pressed and acts accordingly
0489: 3E 44       ld   a,$44
048B: CD 72 34    call $3472		; checks if there was any change in the tab key state
048E: C8          ret  z			; if there was no change, exits
048F: 3E 17       ld   a,$17
0491: CD 82 34    call $3482		; checks if control is pressed
0494: C8          ret  z			; if not, exits

; enters here when pressing ctrl+tab
0495: F3          di
0496: 3E 07       ld   a,$07
0498: 0E 3F       ld   c,$3F
049A: CD 4E 13    call $134E		; disables sound output
049D: 3E 01       ld   a,$01
049F: 01 7E FA    ld   bc,$FA7E		; activates the disk drive motor
04A2: ED 79       out  (c),a
04A4: 3E 06       ld   a,$06
04A6: CD 22 04    call $0422		; delay
04A9: CD 36 05    call $0536		; recalibrates the disk drive
04AC: 3E 01       ld   a,$01		; initial track
04AE: F5          push af
04AF: CD 03 04    call $0403		; writes a seek command for track a
04B2: F1          pop  af
04B3: 3C          inc  a			; advances to the next track
04B4: FE 11       cp   $11
04B6: 38 F6       jr   c,$04AE		; at the end of this loop it's at cylinder 0x11

04B8: CD 50 05    call $0550		; shows the cursor graphic
04BB: 3E 01       ld   a,$01
04BD: 11 10 27    ld   de,$2710
04C0: CD 22 04    call $0422		; delay
04C3: CD 50 05    call $0550		; hides the cursor graphic
04C6: 3E 01       ld   a,$01
04C8: 11 10 27    ld   de,$2710
04CB: CD 22 04    call $0422		; delay
04CE: CD 6D 05    call $056D		; checks if S or N key was pressed
04D1: 28 E5       jr   z,$04B8		; repeat until one is pressed
04D3: 30 21       jr   nc,$04F6		; if N was pressed, jump
04D5: 2A D9 34    ld   hl,($34D9)	; gets the end address of the height of the mirror room
04D8: 01 C6 7F    ld   bc,$7FC6		; puts abadia7 at 0x4000
04DB: ED 49       out  (c),c
04DD: 7E          ld   a,(hl)		; reads the last byte
04DE: F5          push af
04DF: E5          push hl
04E0: 36 FF       ld   (hl),$FF		; restores the original height
04E2: 01 C6 12    ld   bc,$12C6		; saves what's in bank 6 (tracks 0x12-0x16) (abadia7.bin)
04E5: CD 0B 05    call $050B		; copies data to disk from track b to track b+4, setting the memory configuration indicated by c, and reading the data at 0x4000-0x7fff
04E8: 01 C5 17    ld   bc,$17C5		; saves what's in bank 5 (tracks 0x17-0x1b) (abadia6.bin)
04EB: CD 0B 05    call $050B		; copies data to disk from track b to track b+4, setting the memory configuration indicated by c, and reading the data at 0x4000-0x7fff
04EE: E1          pop  hl
04EF: F1          pop  af
04F0: 01 C6 7F    ld   bc,$7FC6		; places abadia7 at 0x4000
04F3: ED 49       out  (c),c
04F5: 77          ld   (hl),a		; restores the last byte

04F6: AF          xor  a			; turns off disk drive motor
04F7: 01 7E FA    ld   bc,$FA7E
04FA: ED 79       out  (c),a
04FC: 01 C0 7F    ld   bc,$7FC0		; sets the original configuration
04FF: ED 49       out  (c),c
0501: 3E 01       ld   a,$01
0503: 11 10 27    ld   de,$2710
0506: CD 22 04    call $0422		; delay
0509: FB          ei
050A: C9          ret

; saves data to disk from track b to track b+4, setting the memory configuration indicated by c, and reading data from 0x4000-0x7fff
050B: 21 FF 7F    ld   hl,$7FFF
050E: 3E 05       ld   a,$05		; data length = 5 cylinders

; saves data to disk from a tracks starting at track b, setting the memory configuration indicated by c, and reading data from hl (downwards)
; a = number of tracks to save
; b = initial track
; c = memory configuration to set
; hl = memory position where to start taking data (saves from top to bottom)
0510: 80          add  a,b			; modifies an instruction with the last track to save
0511: 32 32 05    ld   ($0532),a	; a = initial track
0514: 78          ld   a,b
0515: 06 7F       ld   b,$7F		; sets the memory configuration passed in c
0517: ED 49       out  (c),c        ; bc = main register of disk drive
0519: 01 7E FB    ld   bc,$FB7E
051C: F5          push af
051D: 32 82 04    ld   ($0482),a	; modifies the track of the command
0520: CD 03 04    call $0403		; writes a track seek command to a
0523: 11 7F 04    ld   de,$047F		; points to the write command data
0526: CD 2D 04    call $042D		; writes the command pointed by de to the drive
0529: CD 86 05    call $0586		; writes memory bytes to the disk drive
052C: CD 3A 04    call $043A        ; reads the bytes sent by the disk drive after a command, and stores them in a buffer
052F: F1          pop  af
0530: 3C          inc  a			; advance to the next track
0531: FE 00       cp   $00			; instruction modified externally with the last track to save
0533: 20 E7       jr   nz,$051C
0535: C9          ret

; recalibrates the disk drive
0536: 01 7E FB    ld   bc,$FB7E		; bc = main register of disk drive
0539: 3E 07       ld   a,$07        ; command to recalibrate the drive
053B: CD 65 04    call $0465		; waits for the drive to be ready, and if possible, sends data
053E: AF          xor  a            ; drive 0
053F: CD 65 04    call $0465		; waits for the drive to be ready, and if possible, sends data
0542: 3E 03       ld   a,$03
0544: CD 22 04    call $0422		; waits for the drive to be ready, and if possible, sends data
0547: 3E 08       ld   a,$08        ; command to get status information
0549: CD 65 04    call $0465		; waits for the drive to be ready, and if possible, sends data
054C: CD 3A 04    call $043A		; reads the bytes sent by the disk drive after a command, and stores them in a buffer
054F: C9          ret

; copies a 4x8 pixel rectangle from a buffer to screen, and saves what's on screen in the buffer
0550: 21 00 C0    ld   hl,$C000		; points to screen
0553: 11 65 05    ld   de,$0565		; points to the cursor graphics data

; copies a 4x8 pixel rectangle from de to hl, and saves what's in hl to de
0556: 06 08       ld   b,$08		; 8 bytes (32 pixels)
0558: 4E          ld   c,(hl)       ; reads a byte from screen
0559: 1A          ld   a,(de)		; reads a byte from buffer
055A: 77          ld   (hl),a       ; copies the buffer byte to screen
055B: 79          ld   a,c
055C: 12          ld   (de),a       ; copies the screen byte to buffer
055D: 13          inc  de           ; goes to next buffer position
055E: 7C          ld   a,h
055F: C6 08       add  a,$08        ; goes to next screen line
0561: 67          ld   h,a
0562: 10 F4       djnz $0558
0564: C9          ret

; cursor graphic shown when pressing ctrl+tab, and space to save what was on screen
0565: 00 00 0F 0F F0 F0 FF FF

; checks if S or N key was pressed
056D: CD BC 32    call $32BC	; reads key state and stores it in keyboard buffers
0570: 3E 3C       ld   a,$3C
0572: CD 72 34    call $3472	; checks if S state changes
0575: 37          scf
0576: C0          ret  nz		; if it has changed, exit (with carry)
0577: 3E 2E       ld   a,$2E
0579: CD 72 34    call $3472	; checks if N state changes
057C: C8          ret  z		; if it hasn't changed, exit
057D: F6 FF       or   $FF		; if it has changed, a = 0xff
057F: C9          ret

; writes a memory byte to the disk drive
0580: 0C          inc  c			; points to data register
0581: 7E          ld   a,(hl)       ; reads a byte from memory
0582: ED 79       out  (c),a        ; stores it in the selected sector of current track
0584: 0D          dec  c            ; points to status register
0585: 2B          dec  hl           ; points to the next byte to save
0586: ED 78       in   a,(c)		; reads the status register
0588: F2 86 05    jp   p,$0586
058B: E6 20       and  $20
058D: 20 F1       jr   nz,$0580		; if the write operation is not complete, save another byte
058F: C9          ret
; -------------- end of code for saving saved games from memory to disk --------------------------

; ------------------------ data related to pathfinding --------------------------------

0590: C3 9A 24    jp   $249A
0591: 00 00

; buffer of alternative positions. Each position takes 3 bytes
0593: 	00 00 00
	00 00 00
	00 00 00
	00 00 00
	00 00 00
	FF

05A3: 0000	; pointer to the alternative being tried

; displacement table according to orientation
05A5: 	02 00 -> [+2 00]
	00 FE -> [00 -2]
	FE 00 -> [-2 00]
	00 02 -> [00 +2]

; displacement table related to door orientations
; each entry takes 8 bytes
; byte 0: related to screen x position
; byte 1: related to screen y position
; byte 2: related to sprite depth
; byte 3: indicates the flipx state of graphics needed by the door
; byte 4: related to grid x position
; byte 5: related to grid y position
; byte 6-7: not used, but is the displacement in the height buffer
05AD: 	FF DE 01 00 00 00 0001 -> -01 -34  +01  00    00  00   +01
	FF D6 00 01 00 00 FFE8 -> -01 -42   00 +01    00  00   -24
	FB D6 00 00 00 00 FFFF -> -05 -42   00  00    00  00   -01
	FB DE 01 01 01 01 0018 -> -05 -34  +01 +01   +01 +01   +24

05CD: tables with room connections of the floors
if bit 0 = 0, indicates if it's a room from which you can exit right
if bit 1 = 0, indicates if it's a room from which you can exit up
if bit 2 = 0, indicates if it's a room from which you can exit left
if bit 3 = 0, indicates if it's a room from which you can exit down
if bit 4 = 1, indicates if from that screen you can go up to another floor
if bit 5 = 1, indicates if from that screen you can go down to another floor
; X 00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f  Y
; ================================================== ==
	00 00 00 00 00 00 00 00 08 00 08 08 00 00 00 00  00
	00 08 08 00 08 08 08 09 07 0D 07 07 0C 00 00 00  01
	01 1E 03 0D 06 0A 0A 0B 0C 02 08 08 03 04 00 00  02
	00 03 04 0A 01 0E 0A 0A 02 08 0A 0A 01 04 00 00  03
	00 01 05 0F 05 06 03 07 05 07 06 02 01 04 00 00  04
	00 09 04 02 01 0C 07 05 05 05 04 00 01 04 00 00  05
	01 1E 08 00 08 1B 05 05 05 05 04 08 09 04 00 00  06
	00 02 03 0C 0A 0A 01 0D 05 0D 05 06 02 00 00 00  07
	00 00 00 02 02 03 0C 0A 00 0A 09 06 00 00 00 00  08
	00 00 00 00 00 00 02 03 05 06 02 02 00 00 00 00  09
	00 00 00 00 00 00 00 01 0D 04 00 00 00 00 00 00  0a
	00 00 00 00 00 00 00 00 02 00 00 00 00 00 00 00  0b

067D y 0x685:
; X 00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f  Y
; ================================================== ==
	XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX  00
	00 08 08 00 08 08 00 00 XX XX XX XX XX XX XX XX  01
	01 2E 03 0D 06 1B 0D 06 XX XX XX XX XX XX XX XX  02
	00 03 04 0A 01 0E 0A 08 XX XX XX XX XX XX XX XX  03
	00 01 05 0F 05 06 03 07 XX XX XX XX XX XX XX XX  04
	00 09 04 0A 01 0C 01 05 XX XX XX XX XX XX XX XX  05
	01 2E 09 0F 0C 2B 05 05 XX XX XX XX XX XX XX XX  06
	00 02 03 0C 0A 0A 01 0D XX XX XX XX XX XX XX XX  07

; X 00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f  Y
; ================================================== ==
	XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX 00
	00 08 08 00 08 08 00 00 XX XX XX XX XX XX XX XX 01
	01 0E 03 0D 06 2B 0D 06 XX XX XX XX XX XX XX XX 02
	00 03 04 0A 01 0E 0A 08 XX XX XX XX XX XX XX XX 03
	00 01 05 0F 05 06 03 07 XX XX XX XX XX XX XX XX 04
	00 09 04 0A 01 0C 01 05 XX XX XX XX XX XX XX XX 05
	01 0E 09 0F 0C 0B 05 05 XX XX XX XX XX XX XX XX 06
	00 02 03 0C 0A 0A 01 0D XX XX XX XX XX XX XX XX 07

; ---------------------- end of data related to pathfinding ------------------------------

; executes malaquias' behavior
06FD: FD 21 54 30 ld   iy,$3054		; points to malaquias' characteristics
0701: DD 21 AB 3C ld   ix,$3CAB		; points to malaquias' movement variables
0705: AF          xor  a
0706: 32 9C 3C    ld   ($3C9C),a	; indicates that the character initially wants to move
0709: CD 5E 57    call $575E		; executes malaquias' logic (can change 0x3c9c)
070C: 0E 3F       ld   c,$3F
070E: CD A4 3E    call $3EA4		; modifies the table at 0x05cd with information from the door table and which rooms they're between
0711: 21 C2 2B    ld   hl,$2BC2		; points to the data table for moving malaquias
0714: CD 1D 29    call $291D		; checks if character can move where they want and updates their sprite and height buffer
0717: DD 21 AB 3C ld   ix,$3CAB		; points to malaquias' movement variables
071B: C3 3C 07    jp   $073C		; jump to generate more movement commands for malaquias according to where they want to move

; executes the abbot's behavior
071E: FD 21 63 30 ld   iy,$3063		; iy points to the abbot's characteristics
0722: DD 21 C9 3C ld   ix,$3CC9		; points to the abbot's movement variables
0726: AF          xor  a
0727: 32 9C 3C    ld   ($3C9C),a	; indicates that the character initially wants to move
072A: CD CB 5F    call $5FCB		; executes the abbot's logic
072D: 0E 3F       ld   c,$3F
072F: CD A4 3E    call $3EA4		; modifies the table at 0x05cd with information from the door table and which rooms they're between
0732: 21 CC 2B    ld   hl,$2BCC		; points to the table for moving the abbot
0735: CD 1D 29    call $291D		; checks if character can move where they want and updates their sprite and height buffer
0738: DD 21 C9 3C ld   ix,$3CC9		; points to the abbot's movement variables
	; generates more movement commands for the abbot according to where they want to move

; ----------------- movement generation for AI characters ------------------------------
; all "thinking" characters jump here to fill their action buffer
; ix = the character's logic variables
; iy = character position data
073C: FD CB 09 7E bit  7,(iy+$09)	; if they have a thought-out movement, skip the next part
0740: CA 72 08    jp   z,$0872

; arrives here if the character doesn't have a thought-out movement
0743: 3A 9C 3C    ld   a,($3C9C)	; if the character doesn't have to go anywhere, exit
0746: A7          and  a
0747: C0          ret  nz

0748: DD E5       push ix
074A: DD 7E FF    ld   a,(ix-$01)	; reads where to go
074D: FE FF       cp   $FF
074F: 28 4D       jr   z,$079E		; if going after guillermo, jump
0751: FE FE       cp   $FE
0753: 28 44       jr   z,$0799		; if going after the abbot, jump
0755: FE FD       cp   $FD
0757: 28 3B       jr   z,$0794		; if going after the book, jump
0759: FE FC       cp   $FC
075B: 28 32       jr   z,$078F		; if going after the parchment, jump

; arrives here if 0xff, 0xfe, 0xfd or 0xfc were not found in ix-1
075D: 4F          ld   c,a			; c = a
075E: 87          add  a,a			; a = 2*a
075F: 81          add  a,c			; a = 3*a
0760: 4F          ld   c,a
0761: 06 00       ld   b,$00		; bc = 3*a (each entry takes 3 bytes)
0763: DD 09       add  ix,bc		; indexes into the table of places the character usually goes
0765: DD E5       push ix
0767: E1          pop  hl			; hl = obtained address
0768: E5          push hl
0769: 11 93 05    ld   de,$0593		; points to destination
076C: ED A0       ldi
076E: ED A0       ldi
0770: ED A0       ldi				; copies 3 bytes to buffer used in position algorithms
0772: 3E FF       ld   a,$FF
0774: 12          ld   (de),a		; marks the end of the entry
0775: E1          pop  hl			; retrieves the obtained address
0776: 2B          dec  hl
0777: 2B          dec  hl			; goes back 2 positions, to treat the entry as position data
0778: 11 94 05    ld   de,$0594		; points to the next free position of buffer -2
077B: 18 27       jr   $07A4		; jump to generate alternatives

; jumps here to process an alternative
; ix position generated in buffer
; iy points to the character's position data
077D: CD 8A 09    call $098A		; goes after a character that isn't in the same screen area being shown (iy after ix)
0780: DD E1       pop  ix			; recovers pointer to character's logic variables
0782: 3A B6 2D    ld   a,($2DB6)	; if not at destination, exit
0785: FE FD       cp   $FD
0787: C0          ret  nz
0788: DD 7E FF    ld   a,(ix-$01)	; if reached the place, indicate it
078B: DD 77 FD    ld   (ix-$03),a
078E: C9          ret

; arrives here if 0xfc was found
078F: 21 17 30    ld   hl,$3017		; points to the parchment's position data
0792: 18 0D       jr   $07A1

; arrives here if 0xfd was found
0794: 21 08 30    ld   hl,$3008		; points to the book's position data
0797: 18 08       jr   $07A1

; arrives here if 0xfe was found
0799: 21 63 30    ld   hl,$3063		; points to the abbot's position data
079C: 18 03       jr   $07A1

; arrives here if 0xff was found
079E: 21 36 30    ld   hl,$3036		; points to guillermo's position data

07A1: 11 91 05    ld   de,$0591		; points to the first free position of buffer - 2

; hl has the address of a character's or object's position data to reach
; de points to an empty buffer position for searching alternative paths
; iy points to the character's position data to move
07A4: FD E5       push iy				; saves the character's position data
07A6: CD BD 07    call $07BD			; generates a movement proposal to the position indicated by hl for each possible orientation and saves it in the de buffer
07A9: DD 21 93 05 ld   ix,$0593			; points to the first buffer data entry
07AD: DD 22 A3 05 ld   ($05A3),ix		; initializes pointer to first alternative position
07B1: DD 7E 00    ld   a,(ix+$00)
07B4: FE FF       cp   $FF				; if alternatives are finished, exit
07B6: FD E1       pop  iy
07B8: 20 C3       jr   nz,$077D			; if there's at least one entry, jump
07BA: DD E1       pop  ix
07BC: C9          ret

; generates a movement proposal to the side of the position indicated by hl for each possible orientation and saves it in the de buffer
; hl has the address of a character's or object's position data to reach
; de points to an empty buffer position for searching alternative paths
; iy points to the character's position data to move
07BD: E5          push hl
07BE: DD E1       pop  ix			; ix = hl
07C0: D5          push de
07C1: FD E1       pop  iy			; iy = de
07C3: DD 46 01    ld   b,(ix+$01)	; reads the orientation of character/object to reach
07C6: CD D2 07    call $07D2		; given position data of ix, generates a proposal to reach 2 positions to the side of character according to orientation of b
07C9: 04          inc  b
07CA: CD D2 07    call $07D2		; given position data of ix, generates a proposal to reach 2 positions to the side of character according to orientation of b
07CD: 04          inc  b
07CE: CD D2 07    call $07D2		; given position data of ix, generates a proposal to reach 2 positions to the side of character according to orientation of b
07D1: 04          inc  b

; given position data of ix, generates a proposal to reach 2 positions to the side of character according to orientation of b
; ix has the address of a character's or object's position data to reach
; iy points to an empty buffer position for searching alternative paths
;  b = orientation
07D2: 21 A5 05    ld   hl,$05A5		; points to the displacement table according to orientation
07D5: 78          ld   a,b
07D6: E6 03       and  $03
07D8: 47          ld   b,a			; b = b & 0x03 (adjusts orientation to be among the 4 valid ones)
07D9: 87          add  a,a			; each entry takes 2 bytes
07DA: CD 2D 16    call $162D		; hl = hl + a
07DD: 78          ld   a,b			; a = adjusted orientation
07DE: 0F          rrca
07DF: 0F          rrca				; puts the 2 orientation bits as the 2 most significant bits of a
07E0: EE 80       xor  $80			; inverts the orientation in x and y
07E2: E6 C0       and  $C0			; keeps only the 2 orientation bits
07E4: DD B6 04    or   (ix+$04)		; combines with destination height/orientation with current and saves in c
07E7: 4F          ld   c,a
07E8: DD 7E 04    ld   a,(ix+$04)	; copies destination height/orientation to buffer
07EB: FD 77 04    ld   (iy+$04),a
07EE: DD 7E 02    ld   a,(ix+$02)	; gets destination x position
07F1: 86          add  a,(hl)
07F2: 23          inc  hl
07F3: FD 77 02    ld   (iy+$02),a	; copies destination x position plus a small displacement according to orientation in buffer
07F6: DD 7E 03    ld   a,(ix+$03)	; gets destination y position
07F9: 86          add  a,(hl)
07FA: FD 77 03    ld   (iy+$03),a	; copies destination y position plus a small displacement according to orientation in buffer
07FD: DD E5       push ix
07FF: C5          push bc
									; called with iy = address of position data associated with character/object
0800: CD BE 0C    call $0CBE		; if the position to go to isn't one of the center ones of the screen being shown, CF=1
									; otherwise, returns in ix a pointer to the height table entry of corresponding position
0803: C1          pop  bc
0804: FD 71 04    ld   (iy+$04),c	; saves height/orientation combined with destination
0807: DD 7E 00    ld   a,(ix+$00)	; reads the possible height buffer content
080A: DD E1       pop  ix
080C: 38 17       jr   c,$0825		; if position isn't one of those in screen buffer, jump

; arrives here if in a the height of the position to go was read because it's one of the positions shown on screen
080E: E6 EF       and  $EF			; removes from height buffer data the characters that are there (except adso) (???)
0810: C5          push bc
0811: 4F          ld   c,a			; saves the cell height in c
0812: DD 7E 04    ld   a,(ix+$04)	; gets destination height
0815: CD 73 24    call $2473		; depending on height, returns base height of floor in b
0818: 90          sub  b			; subtracts from destination height the base floor height
0819: 91          sub  c			; subtracts the height in height buffer
081A: 3C          inc  a
081B: FE 06       cp   $06
081D: C1          pop  bc
081E: 38 05       jr   c,$0825		; if there's little height difference, puts end marker at end of this entry
0820: FD 36 02 FF ld   (iy+$02),$FF	; puts end marker at start of this entry (this entry is discarded)
0824: C9          ret

; arrives here if the position to go to isn't one of those in screen's height buffer
0825: FD 23       inc  iy
0827: FD 23       inc  iy
0829: FD 23       inc  iy
082B: FD 36 02 FF ld   (iy+$02),$FF	; puts end marker at end of this entry
082F: C9          ret

; executes berengario's behavior
0830: FD 21 72 30 ld   iy,$3072		; points to berengario's position data
0834: DD 21 EA 3C ld   ix,$3CEA		; points to berengario's movement variables
0838: AF          xor  a
0839: 32 9C 3C    ld   ($3C9C),a	; indicates that initially wants to move
083C: CD 3F 59    call $593F		; executes berengario's logic
083F: 0E 3F       ld   c,$3F
0841: CD A4 3E    call $3EA4		; modifies the table at 0x05cd with information from the door table and which rooms they're between
0844: 21 D6 2B    ld   hl,$2BD6		; points to berengario's table
0847: CD 1D 29    call $291D		; checks if character can move where they want and updates their sprite and height buffer
084A: DD 21 EA 3C ld   ix,$3CEA		; points to berengario's movement variables
084E: C3 3C 07    jp   $073C		; jump to generate more movement commands for berengario according to where they want to move

; executes severino's behavior
0851: FD 21 81 30 ld   iy,$3081		; points to severino's position data
0855: DD 21 02 3D ld   ix,$3D02		; points to severino's state variables
0859: AF          xor  a
085A: 32 9C 3C    ld   ($3C9C),a	; indicates that character wants to move
085D: CD C6 5B    call $5BC6		; executes severino/jorge state changes
0860: 0E 2F       ld   c,$2F
0862: CD A4 3E    call $3EA4		; modifies the table at 0x05cd with information from the door table and which rooms they're between
0865: 21 E0 2B    ld   hl,$2BE0		; points to severino's table
0868: CD 1D 29    call $291D		; checks if character can move where they want and updates their sprite and height buffer
086B: DD 21 02 3D ld   ix,$3D02		; points to severino's state variables
086F: C3 3C 07    jp   $073C		; jump to generate more movement commands for severino according to where they want to move

; arrives here if they have a thought-out movement
0872: 3A C1 2D    ld   a,($2DC1)
0875: FE FF       cp   $FF			; if no movement
0877: C2 BE 08    jp   nz,$08BE		; discards thought-out movements and indicates that a new movement needs to be thought
087A: C9          ret

; ----------------- end of movement generation for AI characters ------------------------------

; adso's behavior
087B: FD 21 45 30 ld   iy,$3045		; points to adso's position data
087F: DD 21 14 3D ld   ix,$3D14		; points to adso's state data
0883: AF          xor  a
0884: 32 9C 3C    ld   ($3C9C),a	; indicates that character initially wants to move
0887: CD A1 5D    call $5DA1		; processes adso's behavior
088A: 0E 3C       ld   c,$3C
088C: CD A4 3E    call $3EA4		; modifies the table at 0x05cd with information from the door table and which rooms they're between
088F: 21 B8 2B    ld   hl,$2BB8		; points to the table for moving adso
0892: CD 1D 29    call $291D		; checks if character can move where they want and updates their sprite and height buffer
0895: DD 21 14 3D ld   ix,$3D14
0899: 3A 13 3D    ld   a,($3D13)	; reads where adso should go
089C: FE FF       cp   $FF
089E: C2 3C 07    jp   nz,$073C		; if doesn't have to follow guillermo, jump

08A1: 3A 8F 3C    ld   a,($3C8F)	; reads the character the camera follows
08A4: FE 02       cp   $02
08A6: D0          ret  nc			; if camera doesn't follow guillermo or adso, exit

08A7: FD CB 09 7E bit  7,(iy+$09)
08AB: 20 22       jr   nz,$08CF		; if doesn't have a thought-out movement, jump

; arrives here if had a thought-out movement
08AD: 21 AA 2D    ld   hl,$2DAA		; points to frustrated movement counter
08B0: 3A C1 2D    ld   a,($2DC1)	; if character could move where they wanted, exit
08B3: FE FF       cp   $FF
08B5: C8          ret  z

08B6: 7E          ld   a,(hl)		; gets the counter and increments it
08B7: 3C          inc  a
08B8: 77          ld   (hl),a
08B9: FE 0A       cp   $0A			; if < 10, exit
08BB: D8          ret  c
08BC: AF          xor  a
08BD: 77          ld   (hl),a		; keeps the value between 0 and 9

; arrives here if that counter overflows to 0

; discards thought-out movements and indicates that a new movement needs to be thought
08BE: FD 6E 0C    ld   l,(iy+$0c)		; hl = action data address
08C1: FD 66 0D    ld   h,(iy+$0d)
08C4: 36 10       ld   (hl),$10			; writes the command to set bit 7,(9)
08C6: FD 36 09 00 ld   (iy+$09),$00
08CA: FD 36 0B 00 ld   (iy+$0b),$00
08CE: C9          ret

; arrives here if didn't have a thought-out movement

; if control is pressed, adso stays still
08CF: 3E 17       ld   a,$17
08D1: CD 82 34    call $3482		; checks if control is pressed
08D4: CD C6 41    call $41C6		; puts a to 0, so control is never given as pressed
08D7: C0          ret  nz			; before this made it so if control was pressed, exit

08D8: FD 21 45 30 ld   iy,$3045
08DC: AF          xor  a
08DD: 32 B6 2D    ld   ($2DB6),a	; indicates that for now hasn't found a route to guillermo
08E0: CD BE 0C    call $0CBE		; if position isn't one of the center ones of screen being shown, CF=1
									; otherwise, returns in ix a pointer to the height table entry of corresponding position
08E3: DA 7F 09    jp   c,$097F		; if adso isn't on the screen being shown, jump
08E6: 3E 00       ld   a,$00
08E8: CD 82 34    call $3482		; if not pressing cursor up, jump
08EB: 28 1C       jr   z,$0909

; arrives here if adso is in center of screen and cursor up is pressed
08ED: FD 21 36 30 ld   iy,$3036		; points to guillermo's position data
08F1: CD B4 27    call $27B4		; checks the height of positions guillermo is going to move to and returns them in a and c
									; if character isn't visible, returns the same as passed in a
08F4: FD 21 45 30 ld   iy,$3045		; points to adso's position data
08F8: 21 C6 2D    ld   hl,$2DC6		; points to auxiliary buffer for height calculation of movements used by previous routine
08FB: 7E          ld   a,(hl)		; combines content of the 2 cells guillermo is going to move to
08FC: 23          inc  hl
08FD: B6          or   (hl)
08FE: 23          inc  hl			; goes to next line
08FF: 23          inc  hl
0900: 23          inc  hl
0901: B6          or   (hl)			; combines the 2 cells where guillermo is
0902: 23          inc  hl
0903: B6          or   (hl)
0904: CB 6F       bit  5,a
0906: C2 A4 45    jp   nz,$45A4		; if adso isn't in any of those, writes commands to move towards them

; arrives here if cursor up isn't pressed or if adso didn't bother guillermo to advance
0909: 3E 02       ld   a,$02
090B: CD 82 34    call $3482
090E: C2 82 45    jp   nz,$4582		; if cursor down is pressed, jump

0911: FD 21 36 30 ld   iy,$3036		; points to guillermo's position data
0915: 0E 00       ld   c,$00
0917: CD EF 28    call $28EF		; if sprite position is central and height is correct, clears positions guillermo occupies in height buffer
091A: FD 21 45 30 ld   iy,$3045		; points to adso's position data
091E: 0E 00       ld   c,$00
0920: CD EF 28    call $28EF		; if sprite position is central and height is correct, clears positions adso occupies in height buffer

0923: 2A 47 30    ld   hl,($3047)	; gets adso's position
0926: CD 9B 27    call $279B		; adjusts position passed in hl to the central 20x20 positions shown. If position is outside, CF=1
0929: 22 B4 2D    ld   ($2DB4),hl	; saves adso's relative position
092C: 2A 38 30    ld   hl,($3038)	; gets guillermo's position
092F: CD 9B 27    call $279B		; adjusts position passed in hl to the central 20x20 positions shown. If position is outside, CF=1
0932: 22 B2 2D    ld   ($2DB2),hl	; saves guillermo's relative position
0935: CD 29 44    call $4429		; searches path to go from guillermo to adso (or vice versa)
0938: 22 6B 46    ld   ($466B),hl	; saves the stack address where performed movements are
093B: CD AE 0B    call $0BAE		; removes all traces of the search from height buffer

093E: FD 21 36 30 ld   iy,$3036		; points to guillermo's position data
0942: FD 4E 0E    ld   c,(iy+$0e)
0945: CD EF 28    call $28EF		; if sprite position is central and height is correct, puts c in the positions it occupies in height buffer
0948: FD 21 45 30 ld   iy,$3045		; points to adso's position data
094C: FD 4E 0E    ld   c,(iy+$0e)
094F: CD EF 28    call $28EF		; if sprite position is central and height is correct, puts c in the positions it occupies in height buffer
0952: 3A B6 2D    ld   a,($2DB6)
0955: A7          and  a
0956: C8          ret  z			; if didn't find a path from origin to destination, exit

; arrives here if a path from origin to destination was found
; iy points to adso's position data
0957: 0E 04       ld   c,$04		; minimum number of algorithm iterations
0959: FD CB 05 7E bit  7,(iy+$05)
095D: 20 11       jr   nz,$0970		; if character occupies a single position in height buffer, jump
095F: 0D          dec  c			; if occupies 4 positions, one less iteration is allowed
0960: 2A 38 30    ld   hl,($3038)	; gets guillermo's position
0963: FD 7E 02    ld   a,(iy+$02)	; gets character's x position
0966: BD          cp   l
0967: 28 07       jr   z,$0970		; if x positions are equal, jump
0969: FD 7E 03    ld   a,(iy+$03)	; gets character's y position
096C: BC          cp   h
096D: 28 01       jr   z,$0970		; if y positions are equal, jump
096F: 0C          inc  c			; if neither coordinate is equal, increments minimum iterations of algorithm

0970: 3A 19 44    ld   a,($4419)	; gets recursion level of search routine
0973: B9          cp   c			; if number of iterations is less than tolerable, exit
0974: D8          ret  c

0975: 3A 18 44    ld   a,($4418)	; gets last orientation used to find character in search routine
0978: 4F          ld   c,a			; c = last orientation used in search algorithm
0979: CD 3F 46    call $463F		; writes a command to advance in character's new orientation
097C: C3 7B 08    jp   $087B		; call adso's behavior again

; arrives here if adso isn't in screen area being shown
; iy points to adso's data
097F: DD 21 38 30 ld   ix,$3038		; points to guillermo's position
0983: CD 8A 09    call $098A		; goes after a character that isn't in the same screen area being shown (iy after ix)
0986: DA 7B 08    jp   c,$087B		; if found a path, executes adso's movement again
0989: C9          ret

; ---------------- high-level algorithm for pathfinding between 2 positions -------------------------

; pathfinding algorithm between 2 points
; iy points to the character data searching for another
; ix points to the position of character/object being searched
098A: 3E FE       ld   a,$FE
098C: 32 B6 2D    ld   ($2DB6),a	; indicates that a path couldn't be searched
098F: 3E 00       ld   a,$00		; modified from main game loop with guillermo's animation
0991: E6 01       and  $01
0993: C0          ret  nz			; if in middle of animation, exit

0994: 3A A9 2D    ld   a,($2DA9)	; if in this iteration a path has already been found, exit (only one path search per iteration)
0997: A7          and  a			; if a path has already been found, exit
0998: C0          ret  nz

0999: 3E 76       ld   a,$76
099B: 32 A4 48    ld   ($48A4),a	; indicates to search for a position with bit 6 in pathfinding algorithm
099E: AF          xor  a
099F: 32 B6 2D    ld   ($2DB6),a	; indicates that for now a path hasn't been found
09A2: FD 7E 04    ld   a,(iy+$04)	; gets height of character searching for another
09A5: CD 73 24    call $2473		; depending on height, returns base height of floor in b
09A8: 58          ld   e,b			; e = base height of floor of character searching for another
09A9: DD 7E 02    ld   a,(ix+$02)	; gets height of searched character
09AC: E6 3F       and  $3F
09AE: CD 73 24    call $2473		; depending on height, returns base height of floor in b

09B1: 7B          ld   a,e			; a = base height of floor of character searching for another
09B2: 21 CD 05    ld   hl,$05CD		; points to table with room connections (ground floor)
09B5: A7          and  a
09B6: 28 0A       jr   z,$09C2		; if the character searching for another is on the ground floor, jump
09B8: 21 7D 06    ld   hl,$067D		; point to table with room connections (first floor)
09BB: FE 0B       cp   $0B
09BD: 28 03       jr   z,$09C2		; if the character searching for another is on the first floor, jump
09BF: 21 85 06    ld   hl,$0685		; point to table with room connections (second floor)

09C2: 22 0A 44    ld   ($440A),hl	; save the table address
09C5: B8          cp   b
09C6: 28 6F       jr   z,$0A37		; if they are on the same floor, jump

; arrive here if the characters are not on the same floor
09C8: 3E 10       ld   a,$10
09CA: 38 02       jr   c,$09CE		; if the character searching for another is on a lower floor than the target character, a = 0x10
09CC: 3E 20       ld   a,$20		; otherwise, a = 0x20

09CE: 4F          ld   c,a			; c = indicator of whether to go up or down a floor
09CF: FD 7E 03    ld   a,(iy+$03)	; get the y position of the character searching for another
09D2: E6 F0       and  $F0			; keep the most significant part of the y position
09D4: 5F          ld   e,a
09D5: FD 7E 02    ld   a,(iy+$02)	; get the x position of the character searching for another
09D8: 0F          rrca
09D9: 0F          rrca
09DA: 0F          rrca
09DB: 0F          rrca
09DC: E6 0F       and  $0F			; keep the most significant part of the x position in the lower nibble
09DE: B3          or   e			; combine the positions to find which room on the floor they are in
09DF: CD 2D 16    call $162D		; index into the floor table
09E2: 7E          ld   a,(hl)		; read the value corresponding to the room where the character searching for another is
09E3: A1          and  c
09E4: 79          ld   a,c			; a = indicator of whether to go up or down a floor
09E5: 20 25       jr   nz,$0A0C		; if from the room they are in it's possible to go up or down a floor, jump

; arrive here if from the current room it's not possible to go up or down
09E7: FE 10       cp   $10			; if needed to go up, a = 0x66 (check bit 4)
09E9: 3E 66       ld   a,$66
09EB: 28 02       jr   z,$09EF
09ED: 3E 6E       ld   a,$6E		; if needed to go down, a = 0x6e (check bit 5)
09EF: 32 A4 48    ld   ($48A4),a	; modify an instruction
09F2: CD 8E 0A    call $0A8E		; return in the lower part of hl the most significant part of the position of the character passed in iy
09F5: 22 B2 2D    ld   ($2DB2),hl	; save the most significant position of the character searching for another
09F8: CD 30 48    call $4830		; search for the direction to follow to find the nearest stairs on this floor
09FB: CD A3 0A    call $0AA3		; clear the bits used for pathfinding search in the current table
09FE: 3E 76       ld   a,$76
0A00: 32 A4 48    ld   ($48A4),a	; restore the instruction to indicate it has to search for bit 6
0A03: 3A B6 2D    ld   a,($2DB6)
0A06: A7          and  a
0A07: C8          ret  z			; if no path was found, exit

; arrive here if from the current room it's not possible to go up or down, but a path to a room on the floor with stairs was found
0A08: EB          ex   de,hl		; put the destination screen in hl
0A09: C3 C4 0A    jp   $0AC4		; search for a path to go from the current room to the destination room. If it finds the path,
							;  recreate the room and generate the route to reach where they want to go

; arrive here if from the current room it's possible to go up or down
0A0C: FE 10       cp   $10			; if needed to go up, a = 0x0d. if needed to go down a = 0x01;
0A0E: 3E 0D       ld   a,$0D
0A10: 28 02       jr   z,$0A14
0A12: 3E 01       ld   a,$01
0A14: 32 22 0A    ld   ($0A22),a	; modify an instruction
0A17: CD BF 0B    call $0BBF		; fill in a buffer the heights of the current screen of the character indicated by iy, mark the cells occupied by characters
							; that are near the current screen and by doors and clear the cells occupied by the character that calls this routine
0A1A: 21 F4 96    ld   hl,$96F4		; hl points to the start of the height buffer where the height of the current screen has been stored
0A1D: 01 40 02    ld   bc,$0240		; bc = buffer length (24*24)
0A20: 7E          ld   a,(hl)		; read a byte
0A21: FE 00       cp   $00			; instruction modified from outside with a value depending on whether to go up or down
0A23: 20 02       jr   nz,$0A27		; if it doesn't match the value, jump
0A25: CB F6       set  6,(hl)		; mark the position as an objective to search for
0A27: 23          inc  hl
0A28: 0B          dec  bc			; continue processing the height buffer until finished
0A29: 78          ld   a,b
0A2A: B1          or   c
0A2B: 20 F3       jr   nz,$0A20

0A2D: ED 43 B4 2D ld   ($2DB4),bc	; set the destination position to 0
0A31: CD 88 0F    call $0F88		; limit the options to try to the first option
0A34: C3 FD 0A    jp   $0AFD		; search for the route and set the instructions to reach the stairs

; arrive here searching for a path between 2 characters that are on the same floor
; iy points to the data of the character searching for another
; ix points to the data of the character being searched for
0A37: DD 6E 00    ld   l,(ix+$00)	; get the x coordinate of the position to reach
0A3A: DD 66 01    ld   h,(ix+$01)	; get the y coordinate of the position to reach
0A3D: FD 7E 02    ld   a,(iy+$02)	; get the x position of the character searching for the other
0A40: AD          xor  l
0A41: 4F          ld   c,a
0A42: E6 F0       and  $F0
0A44: 20 6E       jr   nz,$0AB4		; if not in the same room in x, jump to search for a path to go from the current room
							; to the destination room (hl). If found, recreate the room and generate the route to reach where they want to go
0A46: FD 7E 03    ld   a,(iy+$03)	; get the y position of the character searching for the other
0A49: AC          xor  h
0A4A: 47          ld   b,a
0A4B: E6 F0       and  $F0
0A4D: 20 65       jr   nz,$0AB4		; if not in the same room in y, jump to search for a path to go from the current room
							; to the destination room (hl). If found, recreate the room and generate the route to reach where they want to go

; arrive here if they are in the same room
0A4F: 3E FD       ld   a,$FD
0A51: 32 B6 2D    ld   ($2DB6),a	; indicate that the characters are in the same room
0A54: 78          ld   a,b
0A55: B1          or   c
0A56: 20 24       jr   nz,$0A7C		; if the origin position is not equal to the destination, jump

0A58: DD 7E 02    ld   a,(ix+$02)	; read the height and orientation of the destination position
0A5B: 07          rlca
0A5C: 07          rlca
0A5D: E6 03       and  $03			; keep the orientation in the 2 least significant bits
0A5F: 4F          ld   c,a
0A60: FD 7E 01    ld   a,(iy+$01)	; read the orientation of the searching character
0A63: B9          cp   c
0A64: C8          ret  z			; if the orientations are equal, exit

0A65: CD 73 0A    call $0A73		; set the first position of the command buffer
0A68: CD C3 47    call $47C3		; write some commands to change the character's orientation
0A6B: 21 00 10    ld   hl,$1000
0A6E: 06 0C       ld   b,$0C
0A70: CD E9 0C    call $0CE9		; write b bits of the command passed in hl for the character passed in iy

; set the first position of the command buffer
0A73: FD 36 09 00 ld   (iy+$09),$00
0A77: FD 36 0B 00 ld   (iy+$0b),$00
0A7B: C9          ret

; arrive when the 2 positions are within the same room but in different places
0A7C: AF          xor  a
0A7D: 32 B6 2D    ld   ($2DB6),a	; indicate that the search has failed
0A80: E5          push hl
0A81: CD BF 0B    call $0BBF		; fill in a buffer the heights of the current screen of the character indicated by iy, mark the cells occupied by characters
							; that are near the current screen and by doors and clear the cells occupied by the character that calls this routine
0A84: E1          pop  hl			; hl = destination position
0A85: CD 9B 27    call $279B		; adjust the position passed in hl to the 20x20 central positions shown. If the position is outside, CF=1
0A88: 22 B4 2D    ld   ($2DB4),hl
0A8B: C3 0E 0B    jp   $0B0E		; routine called to search for the route from the character's position to what's stored in 0x2db4-0x2db5

; return in the lower part of hl the most significant part of the position of the character passed in iy
0A8E: FD 7E 02    ld   a,(iy+$02)		; get the x position of the character
0A91: 0F          rrca
0A92: 0F          rrca
0A93: 0F          rrca
0A94: 0F          rrca
0A95: E6 0F       and  $0F
0A97: 6F          ld   l,a				; l = most significant part of the character's x position in the lower nibble
0A98: FD 7E 03    ld   a,(iy+$03)		; get the y position of the character
0A9B: 0F          rrca
0A9C: 0F          rrca
0A9D: 0F          rrca
0A9E: 0F          rrca
0A9F: E6 0F       and  $0F
0AA1: 67          ld   h,a				; h = most significant part of the character's y position in the lower nibble
0AA2: C9          ret

; make sure the table at 0x05cd is between 0x00 and 0x3f
0AA3: 21 CD 05    ld   hl,$05CD
0AA6: 01 30 01    ld   bc,$0130		; 0x130 bytes
0AA9: 7E          ld   a,(hl)
0AAA: E6 3F       and  $3F
0AAC: 77          ld   (hl),a		; [hl] = [hl] & 0x3f
0AAD: 23          inc  hl
0AAE: 0B          dec  bc
0AAF: 78          ld   a,b
0AB0: B1          or   c
0AB1: 20 F6       jr   nz,$0AA9		; repeat until finished
0AB3: C9          ret

; shift the positions to the lower nibble
0AB4: CB 3C       srl  h
0AB6: CB 3C       srl  h
0AB8: CB 3C       srl  h
0ABA: CB 3C       srl  h
0ABC: CB 3D       srl  l
0ABE: CB 3D       srl  l
0AC0: CB 3D       srl  l
0AC2: CB 3D       srl  l

; search for a path to go from the current room to the destination room. If found, recreate the room and generate the route to reach where they want to go
;  hl = destination screen
;  iy = position data of character that wants to go to the destination position
0AC4: 22 B2 2D    ld   ($2DB2),hl	; save the destination screen
0AC7: CD 8E 0A    call $0A8E		; return in the lower part of hl the most significant part of the position of the character passed in iy
0ACA: 22 B4 2D    ld   ($2DB4),hl	; save the origin screen
0ACD: CD 26 48    call $4826		; search for a path to go from the current room to the destination room
0AD0: CD A3 0A    call $0AA3		; clear the bits used for pathfinding search in the current table
0AD3: 3A B6 2D    ld   a,($2DB6)
0AD6: A7          and  a
0AD7: C8          ret  z			; if the path has not been found, exit

0AD8: 3A 18 44    ld   a,($4418)	; get the orientation to follow to reach the path
0ADB: 87          add  a,a
0ADC: 87          add  a,a			; each entry occupies 4 bytes
0ADD: 21 8A 0C    ld   hl,$0C8A		; hl points to an auxiliary table to mark the positions the character should go to
0AE0: 85          add  a,l
0AE1: 6F          ld   l,a
0AE2: 8C          adc  a,h
0AE3: 95          sub  l
0AE4: 67          ld   h,a			; index into the table
0AE5: 5E          ld   e,(hl)
0AE6: 23          inc  hl
0AE7: 56          ld   d,(hl)		; de = [hl]
0AE8: ED 53 FB 0A ld   ($0AFB),de	; modify the routine to call
0AEC: 23          inc  hl
0AED: CD 88 0F    call $0F88		; limit the options to try to the first option
0AF0: 5E          ld   e,(hl)
0AF1: 23          inc  hl
0AF2: 56          ld   d,(hl)		; de = next value of the entry
0AF3: ED 53 B4 2D ld   ($2DB4),de	; save the destination position
0AF7: CD BF 0B    call $0BBF		; fill in a buffer the heights of the current screen of the character indicated by iy, mark the cells occupied by characters
							; that are near the current screen and by doors and clear the cells occupied by the character that calls this routine

0AFA: CD 00 00    call $0000		; instruction modified from outside with the routine to call according to the orientation to follow
							; this routine sets bit 6 of the height buffer positions in the direction that should be followed
							; to move to the screen according to what the pathfinder calculated


0AFD: FD 66 03    ld   h,(iy+$03)	; get the character's position
0B00: FD 6E 02    ld   l,(iy+$02)
0B03: CD 9B 27    call $279B		; adjust the position passed in hl to the 20x20 central positions shown. If the position is outside, CF=1
0B06: 22 B2 2D    ld   ($2DB2),hl	; set the search origin
0B09: CD 29 44    call $4429		; routine called to search for the route from the position passed in 0x2db2-0x2db3 to the one in 0x2db4-0x2db5 and those with bit 6 set to 1
0B0C: 18 0F       jr   $0B1D

0B0E: FD 66 03    ld   h,(iy+$03)	; get the character's position
0B11: FD 6E 02    ld   l,(iy+$02)
0B14: CD 9B 27    call $279B		; adjust the position passed in hl to the 20x20 central positions shown. If the position is outside, CF=1
0B17: 22 B2 2D    ld   ($2DB2),hl	; set the search origin
0B1A: CD 35 44    call $4435		; routine called to search for the route from the position passed in 0x2db2-0x2db3 to the one with bit 6 set

0B1D: 22 6B 46    ld   ($466B),hl	; save the pointer to the stack movement that gave the solution
0B20: 3A B6 2D    ld   a,($2DB6)
0B23: A7          and  a
0B24: 20 45       jr   nz,$0B6B		; if a path was found, jump

; arrive here if no path was found
0B26: DD 2A A3 05 ld   ix,($05A3)	; get the pointer to the alternative that has been tried
0B2A: DD 23       inc  ix
0B2C: DD 23       inc  ix
0B2E: DD 23       inc  ix
0B30: DD 22 A3 05 ld   ($05A3),ix	; advance the pointer to the next alternative
0B34: DD 7E 00    ld   a,(ix+$00)	; if all alternatives have been tried, jump
0B37: FE FF       cp   $FF
0B39: 28 2B       jr   z,$0B66
0B3B: CD AE 0B    call $0BAE		; remove all traces of the search from the height buffer

0B3E: DD 6E 00    ld   l,(ix+$00)	; get the position of the next alternative
0B41: DD 66 01    ld   h,(ix+$01)
0B44: 3E FD       ld   a,$FD
0B46: 32 B6 2D    ld   ($2DB6),a	; indicate that the characters are in the same room
0B49: FD 7E 02    ld   a,(iy+$02)	; get the x position of the character
0B4C: AD          xor  l
0B4D: 4F          ld   c,a			; c = difference in character's x position
0B4E: FD 7E 03    ld   a,(iy+$03)	; get the y position of the character
0B51: AC          xor  h
0B52: B1          or   c			; c = difference in character's position in x and y
0B53: F5          push af
0B54: CC 58 0A    call z,$0A58		; if the alternative's position is the same as the character's, generate commands to get the correct orientation
0B57: F1          pop  af
0B58: 28 0C       jr   z,$0B66		; if the alternative's position is the same as the character's, exit

0B5A: AF          xor  a
0B5B: 32 B6 2D    ld   ($2DB6),a	; indicate that no path has been found

0B5E: CD 9B 27    call $279B		; adjust the position passed in hl to the 20x20 central positions shown. If the position is outside, CF=1
0B61: 22 B4 2D    ld   ($2DB4),hl	; modify the position the character should go to
0B64: 18 A8       jr   $0B0E		; try again to see if it finds that position

; arrive here if all alternatives have been tried and no path was found
0B66: CD 76 0B    call $0B76		; restore the height buffer
0B69: A7          and  a			; clear the carry flag
0B6A: C9          ret

; arrive here if a path was found
0B6B: 3E 01       ld   a,$01
0B6D: 32 A9 2D    ld   ($2DA9),a	; indicate that a path has been found in this iteration of the main loop
0B70: CD AE 0B    call $0BAE		; remove all traces of the search from the height buffer
0B73: CD E6 47    call $47E6		; generate all commands to go from origin to destination

0B76: 21 C0 01    ld   hl,$01C0
0B79: 22 8A 2D    ld   ($2D8A),hl	; restore the height buffer of the current screen
0B7C: FD E5       push iy
0B7E: FD 21 73 2D ld   iy,$2D73		; point to the data of the character the camera follows
0B82: CD 8F 0B    call $0B8F		; restore the minimum visible screen values to the values of the character the camera follows
0B85: FD 7E 04    ld   a,(iy+$04)	; get the character's height
0B88: 32 BA 2D    ld   ($2DBA),a	; set the floor's base height with the character's height and save them in the engine
0B8B: FD E1       pop  iy
0B8D: 37          scf				; set the carry flag
0B8E: C9          ret

; given in iy the position of a character, calculate the minimum visible screen values
0B8F: FD 7E 02    ld   a,(iy+$02)		; read the character's x position
0B92: E6 F0       and  $F0				; keep the most significant part
0B94: D6 04       sub  $04				; get the minimum visible X position
0B96: 32 A9 27    ld   ($27A9),a
0B99: FD 7E 03    ld   a,(iy+$03)		; read the character's y position
0B9C: E6 F0       and  $F0				; keep the most significant part
0B9E: D6 04       sub  $04
0BA0: 32 9D 27    ld   ($279D),a
0BA3: FD 7E 04    ld   a,(iy+$04)		; read the character's height
0BA6: CD 73 24    call $2473			; depending on the height, return the floor's base height in b
0BA9: 78          ld   a,b
0BAA: 32 BA 2D    ld   ($2DBA),a		; save the floor's base height
0BAD: C9          ret

; remove all traces of the search from the height buffer
0BAE: 01 40 02    ld   bc,$0240			; bc = 24*24
0BB1: 2A 8A 2D    ld   hl,($2D8A)		; get a pointer to the current screen's height buffer
0BB4: 7E          ld   a,(hl)
0BB5: E6 3F       and  $3F
0BB7: 77          ld   (hl),a			; remove the search traces from the height buffer
0BB8: 23          inc  hl
0BB9: 0B          dec  bc
0BBA: 78          ld   a,b
0BBB: B1          or   c
0BBC: 20 F6       jr   nz,$0BB4			; repeat until all search traces have been erased
0BBE: C9          ret

; fill in a buffer the heights of the current screen of the character indicated by iy, mark the cells occupied by characters
; that are near the current screen and by doors and clear the cells occupied by the character that calls this routine
0BBF: 11 F4 96    ld   de,$96F4		; change the pointer to the current screen's height buffer
0BC2: ED 53 8A 2D ld   ($2D8A),de
0BC6: CD 22 2D    call $2D22		; fill the height buffer with the clipped data for the screen where the character indicated by iy is
0BC9: 3A 38 30    ld   a,($3038)	; get guillermo's x position
0BCC: FD 4E 02    ld   c,(iy+$02)	; get the character's x position
0BCF: CD 75 0C    call $0C75		; calculate the distance in x between the most significant part of positions a and c, and indicate if it's >= 2
0BD2: 47          ld   b,a			; b = distance separating them in x + 1
0BD3: 30 1F       jr   nc,$0BF4		; if the distance is >= 2, jump

0BD5: 3A 39 30    ld   a,($3039)	; get guillermo's y position
0BD8: FD 4E 03    ld   c,(iy+$03)	; get the character's y position
0BDB: CD 75 0C    call $0C75		; calculate the distance in y between the most significant part of positions a and c, and indicate if it's >= 2
0BDE: 4F          ld   c,a			; c = distance separating them in y + 1
0BDF: 30 13       jr   nc,$0BF4		; if the distance is >= 2, jump
0BE1: C5          push bc
0BE2: FD 7E 04    ld   a,(iy+$04)	; get the character's height
0BE5: CD 73 24    call $2473		; depending on the height, return the floor's base height in b
0BE8: 48          ld   c,b
0BE9: 3A 3A 30    ld   a,($303A)	; get guillermo's height
0BEC: CD 73 24    call $2473		; depending on the height, return the floor's base height in b
0BEF: 78          ld   a,b
0BF0: B9          cp   c
0BF1: C1          pop  bc
0BF2: 28 23       jr   z,$0C17		; if the characters are on the same floor, jump

; arrive here if the distance between guillermo and the character is >= 2 in some coordinate, or they are not on the same floor
0BF4: 3A 75 2D    ld   a,($2D75)	; get the most significant part of the x position of the character shown on screen
0BF7: FD 4E 02    ld   c,(iy+$02)	; get the character's x position
0BFA: CD 75 0C    call $0C75		; calculate the distance between the most significant part of positions a and c, and indicate if it's >= 2
0BFD: 47          ld   b,a			; b = distance in x + 1
0BFE: D0          ret  nc			; if the distance in x is >= 2, exit
0BFF: 3A 76 2D    ld   a,($2D76)	; get the most significant part of the y position of the character shown on screen
0C02: FD 4E 03    ld   c,(iy+$03)	; get the character's y position
0C05: CD 75 0C    call $0C75		; calculate the distance between the most significant part of positions a and c, and indicate if it's >= 2
0C08: 4F          ld   c,a			; c = distance in y + 1
0C09: D0          ret  nc			; if the distance in y is >= 2, jump
0C0A: C5          push bc
0C0B: FD 7E 04    ld   a,(iy+$04)	; get the character's height
0C0E: CD 73 24    call $2473		; depending on the height, return the floor's base height in b
0C11: 3A 77 2D    ld   a,($2D77)	; get the height of the character the camera follows
0C14: B8          cp   b
0C15: C1          pop  bc
0C16: C0          ret  nz			; if the character is not on the same floor as the character the camera follows, exit

; arrive here if the character and guillermo are separated by a short distance on the same floor, or the character and who the camera shows are separated by a short distance on the same floor
; bc = distance in x and y of the character that was nearby
0C17: FD 22 30 0C ld   ($0C30),iy	; modify an instruction
0C1B: 21 BA 2B    ld   hl,$2BBA		; point to an address that contains a pointer to adso's position data
0C1E: 78          ld   a,b			; a = distance in x + 1
0C1F: FE 01       cp   $01
0C21: 06 05       ld   b,$05		; check 5 characters
0C23: 20 09       jr   nz,$0C2E		; if distance in x + 1 is not 1, jump
0C25: 79          ld   a,c			; a = distance in y + 1
0C26: FE 01       cp   $01
0C28: 20 04       jr   nz,$0C2E		; if distance in y + 1 is not 1, jump

; if the distance with the nearby character is very small, start drawing at guillermo
0C2A: 21 B0 2B    ld   hl,$2BB0		; point to an address that contains a pointer to guillermo's position data
0C2D: 04          inc  b			; check 6 characters

0C2E: C5          push bc
0C2F: 01 00 00    ld   bc,$0000		; instruction modified with the character's data address
0C32: 5E          ld   e,(hl)
0C33: 23          inc  hl
0C34: 56          ld   d,(hl)		; de = address of the position data of the character to check
0C35: 23          inc  hl
0C36: 7A          ld   a,d			; a = upper part of the address of the character to check
0C37: A8          xor  b
0C38: 20 04       jr   nz,$0C3E		; if it doesn't match the character's, jump
0C3A: 7B          ld   a,e			; a = lower part of the address of the character to check
0C3B: A9          xor  c
0C3C: 28 0A       jr   z,$0C48		; if it matches the character's, jump

; arrive here if the character passed to the routine is not the one being checked
0C3E: E5          push hl
0C3F: D5          push de
0C40: FD E1       pop  iy			; iy points to the address of the character being checked
0C42: 0E 10       ld   c,$10
0C44: CD EF 28    call $28EF		; if the sprite's position is central and the height is correct, fill in the height buffer the positions occupied by the character
0C47: E1          pop  hl

0C48: 01 08 00    ld   bc,$0008		; advance to the next character
0C4B: 09          add  hl,bc
0C4C: C1          pop  bc
0C4D: 10 DF       djnz $0C2E		; repeat while there are characters left to try

0C4F: FD 21 E4 2F ld   iy,$2FE4		; iy points to the door data
0C53: 11 05 00    ld   de,$0005		; each entry is 5 bytes

0C56: 3E 0F       ld   a,$0F		; 0x0f = height in the height buffer of a closed door
0C58: FD CB 01 76 bit  6,(iy+$01)	; if the door is open, mark its position in the height buffer
0C5C: C4 19 0E    call nz,$0E19
0C5F: 11 05 00    ld   de,$0005
0C62: FD 19       add  iy,de		; advance to the next door
0C64: FD 7E 00    ld   a,(iy+$00)
0C67: FE FF       cp   $FF
0C69: 20 EB       jr   nz,$0C56		; repeat until all doors are complete
0C6B: FD 2A 30 0C ld   iy,($0C30)	; recover the character's data address
0C6F: 0E 00       ld   c,$00
0C71: CD EF 28    call $28EF		; if the sprite's position is central and the height is correct, clear the positions it occupies in the height buffer
0C74: C9          ret

; calculate the distance between the most significant part of positions a and c, and indicate if it's >= 2
0C75: CB 39       srl  c		; leave in the lower nibble of c the most significant part of the position
0C77: CB 39       srl  c
0C79: CB 39       srl  c
0C7B: CB 39       srl  c
0C7D: CB 3F       srl  a		; leave in the lower nibble of a the most significant part of the position
0C7F: CB 3F       srl  a
0C81: CB 3F       srl  a
0C83: CB 3F       srl  a
0C85: 91          sub  c		; a = a - c + 1
0C86: 3C          inc  a
0C87: FE 03       cp   $03		; if a = 0, 1 or 2, CF = 1. That is, if the distance was -1, 0 or 1
0C89: C9          ret

; table to mark the positions the character should go to
; bytes 0-1: routine to call according to the orientation the character should follow to mark the screen exit
; byte 2: destination x position
; byte 3: destination y position
0C8A: 	0CAC 16 0C -> (22, 12) -> mark as destination point anyone going to the screen on the right
 		0C9A 0C 02 -> (12, 02) -> mark as destination point anyone going to the screen above
 		0CB4 02 0C -> (02, 12) -> mark as destination point anyone going to the screen on the left
 		0CB9 0C 16 -> (12, 22) -> mark as destination point anyone going to the screen below

 ; mark as destination point anyone going to the screen above
0C9A: 01 4C 00    ld   bc,$004C		; bc = 76 (X = 4, Y = 3)
0C9D: 11 01 00    ld   de,$0001		; de = 1
0CA0: 2A 8A 2D    ld   hl,($2D8A)	; hl = pointer to the current screen's height buffer
0CA3: 09          add  hl,bc		; get the initial position of the tile buffer

0CA4: 06 10       ld   b,$10		; 16 positions
0CA6: CB F6       set  6,(hl)		; indicate that it's a direction to go to
0CA8: 19          add  hl,de		; advance the tile buffer position
0CA9: 10 FB       djnz $0CA6		; repeat for the 16 positions
0CAB: C9          ret

; mark as destination point anyone going to the screen on the right
0CAC: 01 74 00    ld   bc,$0074		; bc = 116 (X = 20, Y = 4)
0CAF: 11 18 00    ld   de,$0018		; de = 24
0CB2: 18 EC       jr   $0CA0		; jump to mark the positions with increment of +24

; mark as destination point anyone going to the screen on the left
0CB4: 01 63 00    ld   bc,$0063		; bc = 99 (X = 3, Y = 4)
0CB7: 18 F6       jr   $0CAF		; jump to mark the positions with increment of +24

; mark as destination point anyone going to the screen below
0CB9: 01 E4 01    ld   bc,$01E4		; bc = 484 (X = 4, Y = 20)
0CBC: 18 DF       jr   $0C9D		; jump to mark the positions with increment of +1

; if the position is not one of those in the center of the screen or the character's height doesn't match the floor's base height, exit with CF=1
; otherwise, return in ix a pointer to the entry in the height table of the corresponding position
; called with iy = address of the position data associated with the character/object
0CBE: FD 7E 04    ld   a,(iy+$04)	; get the character's height
0CC1: CD 73 24    call $2473		; depending on the height, return the floor's base height in b
0CC4: 3A BA 2D    ld   a,($2DBA)	; get the floor's base height
0CC7: B8          cp   b
0CC8: 37          scf
0CC9: C0          ret  nz			; if the heights are different, exit with CF set

0CCA: FD 6E 02    ld   l,(iy+$02)	; hl = character's position
0CCD: FD 66 03    ld   h,(iy+$03)
0CD0: CD 9B 27    call $279B		; adjust the position passed in hl to the 20x20 central positions shown. If the position is outside, CF=1
0CD3: D8          ret  c			; if the position is outside the center of the screen, exit

; index into the height table with hl and return the corresponding address in ix
0CD4: 7D          ld   a,l
0CD5: 6C          ld   l,h
0CD6: 26 00       ld   h,$00
0CD8: 29          add  hl,hl
0CD9: 29          add  hl,hl
0CDA: 29          add  hl,hl	; hl = hl*8
0CDB: 54          ld   d,h		; de = hl*8 + a
0CDC: 85          add  a,l
0CDD: 5F          ld   e,a
0CDE: 29          add  hl,hl	; hl = hl*16
0CDF: 19          add  hl,de
0CE0: DD 2A 8A 2D ld   ix,($2D8A)	; ix = pointer to the current screen's height buffer
0CE4: EB          ex   de,hl
0CE5: DD 19       add  ix,de		; index into the table
0CE7: A7          and  a
0CE8: C9          ret

; write b bits of the command passed in hl for the character passed in iy
;  iy = points to the character's position data
;  b = command length
;  hl = command data
0CE9: FD 7E 09    ld   a,(iy+$09)	; read the counter
0CEC: FE 08       cp   $08
0CEE: 20 17       jr   nz,$0D07		; if it's not 8, jump

; arrive here when a complete byte has been processed
0CF0: FD 36 09 00 ld   (iy+$09),$00	; if it reaches 8 it's reset
0CF4: FD 7E 0B    ld   a,(iy+$0b)	; read the bc table index
0CF7: FD 86 0C    add  a,(iy+$0c)
0CFA: 5F          ld   e,a
0CFB: FD 8E 0D    adc  a,(iy+$0d)
0CFE: 93          sub  e
0CFF: 57          ld   d,a			; de = address[index]
0D00: FD 34 0B    inc  (iy+$0b)		; increment the table index
0D03: FD 7E 0A    ld   a,(iy+$0a)	; read the command and write it to the previous position

0D07: 29          add  hl,hl		; put the most significant bit into CF
0D08: FD CB 0A 16 rl   (iy+$0a)		; rotate the value left and put CF as bit 0
0D0C: FD 34 09    inc  (iy+$09)		; increment the counter
0D0F: 05          dec  b
0D10: 20 D7       jr   nz,$0CE9		; while the command is not finished, copy the bits
0D12: C9          ret

; ---------------- end of high-level algorithm for pathfinding between 2 positions -------------------------

; ----------- code to process objects and doors -----------------------

; arrive with ix = sprite of the object being dropped
; arrive with iy = data of the object being dropped
0D13: 3E C9       ld   a,$C9
0D15: 32 64 0D    ld   ($0D64),a		; make it only process one object from the list
0D18: 21 BB 0D    ld   hl,$0DBB			; routine to jump to for processing game objects
0D1B: CD 3B 0D    call $0D3B			; call the routine to redraw the object
0D1E: AF          xor  a
0D1F: 32 64 0D    ld   ($0D64),a		; restore the object routine
0D22: C9          ret

; routine called when changing screens to process the game objects we can pick up
0D23: 21 BB 0D    ld   hl,$0DBB			; routine to jump to for processing game objects
0D26: DD 21 1B 2F ld   ix,$2F1B			; point to the game object sprites
0D2A: FD 21 08 30 ld   iy,$3008			; point to the game object position data
0D2E: 18 0B       jr   $0D3B			; process the objects

; routine called when changing screens to process doors
0D30: 21 D2 0D    ld   hl,$0DD2			; routine to jump to for processing door sprites
0D33: DD 21 8F 2E ld   ix,$2E8F			; point to the door sprites
0D37: FD 21 E4 2F ld   iy,$2FE4			; point to the door data

0D3B: 22 4A 0D    ld   ($0D4A),hl		; modify the instruction to know which routine to jump to
0D3E: FD 7E 00    ld   a,(iy+$00)		; read a byte and if it finds 0xff finish
0D41: FE FF       cp   $FF
0D43: C8          ret  z
0D44: CD 4C 0E    call $0E4C			; get in hl the object's screen position. If not visible return CF = 1
0D47: DD E5       push ix				;  if the object is visible, jump to the next routine
0D49: D4 D2 0D    call nc,$0DD2			; instruction modified from outside
0D4C: DD E1       pop  ix
0D4E: DD 7E 01    ld   a,(ix+$01)		; set the sprite's current position as the old position
0D51: DD 77 03    ld   (ix+$03),a
0D54: DD 7E 02    ld   a,(ix+$02)
0D57: DD 77 04    ld   (ix+$04),a
0D5A: 01 05 00    ld   bc,$0005			; advance the entry
0D5D: FD 09       add  iy,bc
0D5F: 01 14 00    ld   bc,$0014			; point to the next sprite
0D62: DD 09       add  ix,bc
0D64: 00          nop					; changed from outside (ret or nop)
0D65: 18 D7       jr   $0D3E			; continue processing the objects

; ----------- end of code to process objects and doors -----------------------

; --------------------- code related to doors --------------------------------------------

0D67: DD 21 8F 2E ld   ix,$2E8F			; point to the door sprites
0D6B: FD 21 E4 2F ld   iy,$2FE4			; point to the door data
0D6F: AF          xor  a
0D70: 32 AF 2D    ld   ($2DAF),a		; indicate that the door doesn't require flipped graphics
0D73: FD 7E 00    ld   a,(iy+$00)		; if it has reached the last entry, exit
0D76: FE FF       cp   $FF
0D78: C8          ret  z

; check if any door needs to be opened or closed and update the sprites accordingly
0D79: AF          xor  a
0D7A: 32 FF 0D    ld   ($0DFF),a		; modify an instruction (initially no need to redraw the sprite)
0D7D: DD E5       push ix
0D7F: CD AD 0E    call $0EAD			; check if this door needs to be opened or closed
0D82: DD E1       pop  ix
0D84: CD 4C 0E    call $0E4C			; return the object's position in screen coordinates. If not visible return CF = 1
0D87: DD E5       push ix				; if CF=0, in c return the sprite's y coordinate on screen (-16) and in hl return the sprite's screen position
0D89: D4 D2 0D    call nc,$0DD2			; if the door is visible, draw the sprite (if the door's state has changed) and mark the positions the door occupies so you can't advance through it
0D8C: DD E1       pop  ix
0D8E: 3A B8 2D    ld   a,($2DB8)		: read if the screen will be redrawn
0D91: A7          and  a
0D92: 20 1B       jr   nz,$0DAF			; if the screen will be redrawn, go to the next door

; arrive here if the screen will not be redrawn
0D94: DD 7E 00    ld   a,(ix+$00)		; read the door sprite
0D97: FE FE       cp   $FE
0D99: 28 14       jr   z,$0DAF			; if the door is not visible, go to the next door
0D9B: CB 7F       bit  7,a
0D9D: 28 10       jr   z,$0DAF			; if the door is not redrawn, go to the next door
0D9F: DD E5       push ix
0DA1: FD CB 01 76 bit  6,(iy+$01)		; if the door is redrawn, plays a sound depending on its state
0DA5: F5          push af
0DA6: C4 1B 10    call nz,$101B			; if bit 6 was 1, plays the door opening sound
0DA9: F1          pop  af
0DAA: CC 16 10    call z,$1016			; if bit 6 was 0, plays the door closing sound
0DAD: DD E1       pop  ix

0DAF: 01 05 00    ld   bc,$0005			; advance to the next door
0DB2: FD 09       add  iy,bc
0DB4: 01 14 00    ld   bc,$0014
0DB7: DD 09       add  ix,bc
0DB9: 18 B8       jr   $0D73

; routine called when game objects are visible in the current screen
; if the object wasn't being drawn, adjusts the position and marks it to be drawn
; ix points to the object sprite
; iy points to the object data
; hl contains the screen position of the object
; c = the y coordinate of the sprite on screen (-16)
0DBB: FD CB 00 7E bit  7,(iy+$00)	; if the object has already been picked up, exit
0DBF: C0          ret  nz
0DC0: CB F9       set  7,c			; indicates that the object needs to be drawn
0DC2: DD 71 00    ld   (ix+$00),c	; updates the object's depth within the tile buffer
0DC5: 7C          ld   a,h
0DC6: D6 08       sub  $08
0DC8: DD 77 02    ld   (ix+$02),a	; modifies the object's y position (-8 pixels)
0DCB: 7D          ld   a,l
0DCC: D6 02       sub  $02
0DCE: DD 77 01    ld   (ix+$01),a	; modifies the object's x position (-8 pixels)
0DD1: C9          ret

; routine called when doors are visible in the current screen
; handles modifying the sprite position according to orientation, modifying the height buffer to indicate whether you can pass
;  through the door area or not, placing the door graphics and modifying 0x2daf
; ix points to a door sprite
; iy points to the door data
; hl contains the screen position of the object
; c has the door's depth on screen
0DD2: EB          ex   de,hl			; de = object's screen position
0DD3: CD B0 2A    call $2AB0			; sets the sprite's current position and dimensions as old position and dimensions
0DD6: C5          push bc
0DD7: CD 7C 0E    call $0E7C			; reads 2 values in bc related to orientation and modifies sprite position (in local coordinates) according to orientation
0DDA: 21 AD 05    ld   hl,$05AD			; points to the offset table related to door orientations
0DDD: FD 7E 00    ld   a,(iy+$00)		; reads the door orientation
0DE0: E6 03       and  $03
0DE2: CD 80 24    call $2480			; modifies the orientation passed in a with the current screen orientation
0DE5: 87          add  a,a				; each entry occupies 8 bytes
0DE6: 87          add  a,a
0DE7: 87          add  a,a
0DE8: CD 2D 16    call $162D			; indexes into the table
0DEB: 7E          ld   a,(hl)
0DEC: 83          add  a,e
0DED: 81          add  a,c
0DEE: DD 77 01    ld   (ix+$01),a		; modifies the sprite's x position
0DF1: 23          inc  hl
0DF2: 7E          ld   a,(hl)
0DF3: 82          add  a,d
0DF4: 80          add  a,b
0DF5: DD 77 02    ld   (ix+$02),a		; modifies the sprite's y position
0DF8: 23          inc  hl
0DF9: 7E          ld   a,(hl)
0DFA: C1          pop  bc				; recovers the depth
0DFB: 81          add  a,c
0DFC: F6 80       or   $80				; instruction modified from outside. If the screen is drawn, 0x80, otherwise 0
0DFE: F6 00       or   $00				; instruction modified from outside (or 0x00 or or 0x80 if the door is drawn)
0E00: DD 77 00    ld   (ix+$00),a
0E03: 23          inc  hl
0E04: 3A AF 2D    ld   a,($2DAF)		; reads if the door needs flipped graphics or not
0E07: B6          or   (hl)
0E08: 32 AF 2D    ld   ($2DAF),a
0E0B: CD 8C 0E    call $0E8C			; modifies the sprite's x and y position on the grid according to the next 2 values from hl
0E0E: 11 49 AA    ld   de,$AA49			; places the door graphic address in the sprite
0E11: DD 73 07    ld   (ix+$07),e
0E14: DD 72 08    ld   (ix+$08),d
0E17: 3E 0F       ld   a,$0F

0E19: CD 2C 0E    call $0E2C			; reads a value in bc related to the door's offset in the height buffer
0E1C: D8          ret  c				; if the object is not visible, exit. Otherwise, returns in ix a pointer to the height table entry for the corresponding position
0E1D: 08          ex   af,af'			; recovers a
0E1E: DD 77 00    ld   (ix+$00),a		; marks the height of this position in the height buffer
0E21: DD 09       add  ix,bc
0E23: DD 77 00    ld   (ix+$00),a		; marks the height of the next position in the height buffer
0E26: DD 09       add  ix,bc
0E28: DD 77 00    ld   (ix+$00),a		; marks the height of the next position in the height buffer
0E2B: C9          ret

; reads the offset for the height buffer in bc, and if the door is visible returns in ix a pointer to the height table entry for the corresponding position
0E2C: 08          ex   af,af'
0E2D: FD 7E 00    ld   a,(iy+$00)	; gets the door orientation
0E30: E6 03       and  $03
0E32: 21 44 0E    ld   hl,$0E44		; points to the offset table in the height buffer related to door orientation
0E35: 87          add  a,a			; each entry occupies 2 bytes
0E36: CD 2D 16    call $162D		; indexes into the table
0E39: 4E          ld   c,(hl)
0E3A: 23          inc  hl
0E3B: 46          ld   b,(hl)		; bc = [hl]
0E3C: D5          push de
0E3D: C5          push bc
0E3E: CD BE 0C    call $0CBE		; if the position is not one of the center ones on the screen or the character's height doesn't match the floor's base height, exit with CF=1
0E41: C1          pop  bc			;  otherwise, returns in ix a pointer to the height table entry for the corresponding position
0E42: D1          pop  de
0E43: C9          ret

; offset table in the height buffer related to door orientation
0E44: 	0001 -> +01
	FFE8 -> -24
	FFFF -> -01
	0018 -> +24

; returns the entity position in screen coordinates. If not visible, exits with CF = 1
; if CF=0, in c returns sprite depth and in hl returns the sprite's screen position
0E4C: 3E C9       ld   a,$C9
0E4E: 32 2F 2B    ld   ($2B2F),a	; modifies an instruction by placing a ret, so that the routine at 0x2add returns the sprite's screen position
0E51: CD 5A 0E    call $0E5A		; processes the objects

; arrives here if the sprite is visible
0E54: 4F          ld   c,a			; gets the sprite's y coordinate on screen -16 (the depth)
0E55: AF          xor  a
0E56: 32 2F 2B    ld   ($2B2F),a	; modifies an instruction by placing a nop
0E59: C9          ret

0E5A: CD DD 2A    call $2ADD		; processes the object and gets its screen address

; if the sprite is not visible, arrives here
0E5D: D1          pop  de			; gets the return address
0E5E: DD 36 00 FE ld   (ix+$00),$FE ; marks the sprite as not visible
0E62: AF          xor  a
0E63: 37          scf				; sets the carry flag
0E64: 18 F0       jr   $0E56

; checks if door graphics need to be flipped
0E66: 3A AF 2D    ld   a,($2DAF)	; reads the flipx state that the door expects
0E69: 4F          ld   c,a
0E6A: 3A 78 2D    ld   a,($2D78)	; reads if the doors are flipped or not
0E6D: A9          xor  c
0E6E: C8          ret  z			; if they are in the needed state, exit
0E6F: 79          ld   a,c
0E70: 32 78 2D    ld   ($2D78),a	; otherwise, flips the graphics
0E73: 01 06 28    ld   bc,$2806		; width and height of the door sprite
0E76: 21 49 AA    ld   hl,$AA49		; hl points to the door graphics
0E79: C3 52 35    jp   $3552		; flips the door graphics

; reads 2 values in bc related to orientation and modifies sprite position (in local coordinates) according to orientation
; ix points to a door sprite
0E7C: 21 9D 0E    ld   hl,$0E9D		; points to the table related to door offsets and orientation
0E7F: 3E 03       ld   a,$03		; orientation towards +y
0E81: CD 80 24    call $2480		; modifies the orientation passed in a with the current screen orientation
0E84: 87          add  a,a			; a = a*4 (each entry occupies 4 bytes)
0E85: 87          add  a,a
0E86: CD 2D 16    call $162D		; indexes into the table
0E89: 4E          ld   c,(hl)		; reads the values to add to the door sprite's screen coordinate position
0E8A: 23          inc  hl
0E8B: 46          ld   b,(hl)
0E8C: 23          inc  hl
0E8D: DD 7E 12    ld   a,(ix+$12)	; modifies the grid's x position according to camera orientation with the read value
0E90: 86          add  a,(hl)
0E91: DD 77 12    ld   (ix+$12),a
0E94: 23          inc  hl
0E95: DD 7E 13    ld   a,(ix+$13)	; modifies the grid's x position according to camera orientation with the read value
0E98: 86          add  a,(hl)
0E99: DD 77 13    ld   (ix+$13),a
0E9C: C9          ret

; table related to door offsets and orientation
; each entry occupies 4 bytes
; byte 0: value to add to the door sprite's x position in screen coordinates
; byte 1: value to add to the door sprite's y position in screen coordinates
; byte 2: value to add to the door sprite's x position in local coordinates
; byte 3: value to add to the door sprite's y position in local coordinates
0E9D: 	02 00 00 FF -> +2 00 00 -1
	00 FC FF FF -> 00 -4 -1 -1
	FE 00 FF 00 -> -2 00 -1 00
	00 04 00 00 -> 00 +4 00 00

; checks if a door needs to be opened or closed
; iy points to the door data
0EAD: FD 7E 01    ld   a,(iy+$01)
0EB0: CB 7F       bit  7,a			; if the door stays fixed, exit
0EB2: C0          ret  nz
0EB3: FD 5E 02    ld   e,(iy+$02)	; gets the door's x and y coordinates
0EB6: FD 56 03    ld   d,(iy+$03)
0EB9: 1D          dec  e
0EBA: 1D          dec  e
0EBB: 15          dec  d
0EBC: 15          dec  d
0EBD: E6 1F       and  $1F			; gets which door it is
0EBF: 4F          ld   c,a
0EC0: 21 A6 3C    ld   hl,$3CA6		; points to the doors that can be opened
0EC3: 7E          ld   a,(hl)
0EC4: F6 10       or   $10			; adds the passageway door behind the kitchen to the mask
0EC6: A1          and  c			; combines the mask with the current door
0EC7: 4F          ld   c,a
0EC8: 3A DC 2D    ld   a,($2DDC)	; reads the doors that Adso can enter
0ECB: 21 D9 2D    ld   hl,$2DD9		; points to the doors that Guillermo can enter
0ECE: CD 6C 0F    call $0F6C		; checks if Guillermo is near a door he doesn't have permission to open
0ED1: 38 73       jr   c,$0F46		; if so, check if it needs to be closed
0ED3: 3A D9 2D    ld   a,($2DD9)	; reads the doors that Guillermo can enter
0ED6: 21 DC 2D    ld   hl,$2DDC		; points to the doors that Adso can enter
0ED9: CD 6C 0F    call $0F6C		; checks if Adso is near a door he doesn't have permission to open
0EDC: 38 68       jr   c,$0F46		; if so, check if it needs to be closed

0EDE: 21 D9 2D    ld   hl,$2DD9		; points to the first character's permissions
0EE1: 1C          inc  e
0EE2: 14          inc  d

0EE3: 7E          ld   a,(hl)
0EE4: 23          inc  hl
0EE5: FE FF       cp   $FF
0EE7: 28 5D       jr   z,$0F46		; if all entries have been processed, jump to see if the door needs to be closed
0EE9: A1          and  c
0EEA: 20 04       jr   nz,$0EF0		; if this character has permission to open this door, jump
0EEC: 23          inc  hl
0EED: 23          inc  hl
0EEE: 18 F3       jr   $0EE3		; advance to the next character's door permissions

; arrives here if someone has permission to open a door
0EF0: CD 7C 0F    call $0F7C		; returns the position of the character who can open the door
0EF3: 93          sub  e
0EF4: FE 04       cp   $04
0EF6: 30 EB       jr   nc,$0EE3		; if not close in x, jump to process the next character
0EF8: 78          ld   a,b
0EF9: 92          sub  d
0EFA: FE 04       cp   $04			; if not close in y, jump to process the next character
0EFC: 30 E5       jr   nc,$0EE3
0EFE: FD CB 01 76 bit  6,(iy+$01)	; if the door is open, exit
0F02: C0          ret  nz
0F03: FD 4E 00    ld   c,(iy+$00)	; saves the door's orientation and state in case it needs to be restored later
0F06: FD 46 01    ld   b,(iy+$01)
0F09: D9          exx
0F0A: FD CB 01 F6 set  6,(iy+$01)	; marks the door as open
0F0E: 3E 80       ld   a,$80
0F10: 32 FF 0D    ld   ($0DFF),a	; modifies an instruction so that a sprite needs to be redrawn
0F13: FD 7E 04    ld   a,(iy+$04)	; gets the height at which the door is located
0F16: CD 19 0E    call $0E19		; modifies the height buffer since when the door opens it should be passable
0F19: FD 35 00    dec  (iy+$00)		; changes the door's orientation
0F1C: FD CB 01 6E bit  5,(iy+$01)
0F20: 20 06       jr   nz,$0F28		; if bit 5 is set, jump
0F22: FD 34 00    inc  (iy+$00)		; changes the door's orientation
0F25: FD 34 00    inc  (iy+$00)
0F28: CD 2C 0E    call $0E2C		; reads the door's offset in bc for the height buffer, and if the door is visible
0F2B: DD 09       add  ix,bc		; returns in ix a pointer to the height table entry for the corresponding position
0F2D: DD 09       add  ix,bc
0F2F: D9          exx
0F30: DD 7E 00    ld   a,(ix+$00)	; reads if there is a character in the position where the door opens
0F33: E6 F0       and  $F0
0F35: C8          ret  z			; if not, exit
0F36: FD 71 00    ld   (iy+$00),c	; if there is a character, restore the door's configuration
0F39: FD 70 01    ld   (iy+$01),b
0F3C: AF          xor  a
0F3D: 32 FF 0D    ld   ($0DFF),a	; modifies an instruction so that the sprite doesn't need to be redrawn
0F40: FD 7E 04    ld   a,(iy+$04)	; gets the height at which the door is located
0F43: C3 19 0E    jp   $0E19		; modifies the height buffer with the door's height

; arrives here to check if the door needs to be closed
0F46: FD CB 01 76 bit  6,(iy+$01)	; if the door is closed, exit
0F4A: C8          ret  z

0F4B: FD 4E 00    ld   c,(iy+$00)	; saves the door's orientation and state in case it needs to be restored later
0F4E: FD 46 01    ld   b,(iy+$01)
0F51: D9          exx
0F52: 3E 80       ld   a,$80
0F54: 32 FF 0D    ld   ($0DFF),a	; modifies an instruction so that the sprite is redrawn
0F57: FD 7E 04    ld   a,(iy+$04)	; gets the height at which the door is located
0F5A: CD 19 0E    call $0E19		; modifies the height buffer positions occupied by the door to allow passage
0F5D: FD CB 01 B6 res  6,(iy+$01)	; indicates that the door is closed
0F61: FD 35 00    dec  (iy+$00)		; changes the door's orientation
0F64: FD CB 01 6E bit  5,(iy+$01)	; if bit 5 is set, modifies the orientation
0F68: 28 BE       jr   z,$0F28
0F6A: 18 B6       jr   $0F22		; jump to redraw the sprite

; checks if the character approaches a door they can't open, and if so, closes it
0F6C: B6          or   (hl)		; combines the doors they can enter
0F6D: 23          inc  hl
0F6E: A1          and  c
0F6F: C0          ret  nz		; if they have permission to open the door, exit

0F70: CD 7C 0F    call $0F7C	; returns the position of the character who can open the door
0F73: 93          sub  e		; compares the character's x coordinate with the door's x coordinate
0F74: FE 06       cp   $06
0F76: D0          ret  nc		; if not close, exit
0F77: 78          ld   a,b		; repeat with y
0F78: 92          sub  d
0F79: FE 06       cp   $06
0F7B: C9          ret

; returns in ab what is in [[hl]] and increments hl
0F7C: 7E          ld   a,(hl)		; ab = [hl]
0F7D: 23          inc  hl
0F7E: 46          ld   b,(hl)
0F7F: 23          inc  hl
0F80: E5          push hl
0F81: 6F          ld   l,a			; hl = ba
0F82: 60          ld   h,b
0F83: 7E          ld   a,(hl)		; ab = [hl]
0F84: 23          inc  hl
0F85: 46          ld   b,(hl)
0F86: E1          pop  hl
0F87: C9          ret

; --------------------- end of door-related code --------------------------------------------

; limits options to try to the first option
0F88: 11 93 05    ld   de,$0593
0F8B: ED 53 A3 05 ld   ($05A3),de	; initializes the pointer to the alternatives buffer
0F8F: 13          inc  de
0F90: 13          inc  de
0F91: 13          inc  de
0F92: 3E FF       ld   a,$FF		; marks the end of the buffer after the first entry
0F94: 12          ld   (de),a
0F95: C9          ret

; ---------------------------- music-related code section ------------------------

0F96: mask indicating on which channels the tones and noise generator are active
0F97: copy of the mask indicating on which channels the tones and noise generator are active

0F98: counter that decrements and when it reaches 0 updates the notes

0F99: envelope period (low byte) related to what was read in 0x0a-0x0b + 0x0c
0F9A: envelope period (high byte) related to what was read in 0x0a-0x0b + 0x0c
0F9B: envelope type related to what was read in 0x0a-0x0b + 0x0c (only stores 4 lsb)

0F9C: noise generator period (only the last 5 bits are used)

; table with generation data for each sound channel (PSG registers + channel entry)
0F9D:
00 08 09
0FA0: 36 80 00 00 00 00 00 00 00 00 01 00 00 00 00 00 00 00 00 00 00
02 09 12
0FB8: 36 80 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
04 0A 24
0FD0: 36 80 00 00 00 00 00 00 00 00 00 00 00 00 00 1E 04 20 C7 21 F5

; table with chromatic scale tones
; the frequency is calculated as Freq = (1 MHz)/(16*Tone for the PSG), so each tone corresponds to:
0FE5: 	0EEE ; 0 -> frequency of C 	(octave 0) 16 Hz in the AY-8912, 16.4 theoretical
	0E18 ; 1 -> frequency of C#	(octave 0) 17 Hz in the AY-8912, 17.3 theoretical
	0D4D ; 2 -> frequency of D		(octave 0) 18 Hz in the AY-8912, 18.4 theoretical
	0C8E ; 3 -> frequency of D#	(octave 0) 19 Hz in the AY-8912, 19.4 theoretical
	0BDA ; 4 -> frequency of E		(octave 0) 20 Hz in the AY-8912, 20.6 theoretical
	0B2F ; 5 -> frequency of F		(octave 0) 21 Hz in the AY-8912, 21.8 theoretical
	0A8F ; 6 -> frequency of G		(octave 0) 23 Hz in the AY-8912, 23.1 theoretical
	09F7 ; 7 -> frequency of G#	(octave 0) 24 Hz in the AY-8912, 24.5 theoretical
	0968 ; 8 -> frequency of A		(octave 0) 25 Hz in the AY-8912, 26.0 theoretical
	08E1 ; 9 -> frequency of A#	(octave 0) 27 Hz in the AY-8912, 27.5 theoretical
	0861 ; A -> frequency of B		(octave 0) 29 Hz in the AY-8912, 29.1 theoretical
	07E9 ; B -> frequency of B#	(octave 0) 30 Hz in the AY-8912, 30.9 theoretical

0FFD: 21 80 14    ld   hl,$1480		; sound ??? on channel 1
1000: 18 3D       jr   $103F

1002: 21 96 14    ld   hl,$1496		; sound of Guillermo moving on channel 3
1005: 18 44       jr   $104B

1007: 21 FE 13    ld   hl,$13FE		; sound ???
100A: 18 28       jr   $1034

100C: 21 F3 14    ld   hl,$14F3		; sound ??? on channel 1
100F: 18 2E       jr   $103F

1011: 21 BA 14    ld   hl,$14BA		; bell sound after the square spiral on channel 1
1014: 18 29       jr   $103F

1016: 21 60 15    ld   hl,$1560		; sound ??? on channel 2
1019: 18 2A       jr   $1045

101B: 21 E7 14    ld   hl,$14E7		; sound ??? on channel 2
101E: 18 25       jr   $1045

1020: 21 B1 14    ld   hl,$14B1		; points to the data
1023: 18 26       jr   $104B		; initializes channel 3

1025: 21 9F 14    ld   hl,$149F		; sound of picking up/dropping object on channel 1
1028: 18 1B       jr   $1045

102A: 21 50 15    ld   hl,$1550		; sound ??? on channel 1
102D: 18 16       jr   $1045

102F: 21 A8 14    ld   hl,$14A8		; sound of picking up/dropping object on channel 1
1032: 18 11       jr   $1045

1034: DD 21 D0 0F ld   ix,$0FD0		; points to channel 3 control register
1038: DD 7E 0E    ld   a,(ix+$0e)
103B: A7          and  a
103C: C0          ret  nz
103D: 18 10       jr   $104F

103F: DD 21 A0 0F ld   ix,$0FA0			; points to entry 1
1043: 18 0A       jr   $104F			; initializes the channel
1045: DD 21 B8 0F ld   ix,$0FB8			; points to entry 2
1049: 18 04       jr   $104F			; initializes the channel
104B: DD 21 D0 0F ld   ix,$0FD0			; points to entry 3

; initializes the channel
104F: F3          di					; fills part of the selected entry
1050: DD 36 0E 05 ld   (ix+$0e),$05		; activates the sound
1054: DD 75 00    ld   (ix+$00),l		; saves the music data address
1057: DD 74 01    ld   (ix+$01),h
105A: DD 36 02 01 ld   (ix+$02),$01		; sets the note duration
105E: FB          ei					; enables interrupts
105F: C9          ret

; generates the music (called from the interrupt)
1060: F3          di
1061: F5          push af
1062: 3A AE 0F    ld   a,($0FAE)		; gets the value of the first entry + 0x0e
1065: C5          push bc
1066: 4F          ld   c,a
1067: 3A C6 0F    ld   a,($0FC6)		; gets the value of the second entry + 0x0e
106A: B1          or   c
106B: 4F          ld   c,a
106C: 3A DE 0F    ld   a,($0FDE)		; gets the value of the third entry + 0x0e
106F: B1          or   c
1070: E6 01       and  $01				; if any of the 3 entries had bit 0 active, jump, otherwise end the interrupt
1072: 20 05       jr   nz,$1079
1074: C1          pop  bc
1075: F1          pop  af
1076: FB          ei
1077: ED 4D       reti

; routine that updates the music (according to 0x0f98 value, the tempo is higher or lower)
1079: E5          push hl
107A: D5          push de
107B: DD E5       push ix
107D: 3A 98 0F    ld   a,($0F98)		; decrements the music tempo, but keeps it between 0 and [0x1086]
1080: 3D          dec  a
1081: FE FF       cp   $FF
1083: 20 02       jr   nz,$1087
1085: 3E 06       ld   a,$06			; related to the music tempo (instruction modified from outside)
1087: 32 98 0F    ld   ($0F98),a
108A: 3E 3F       ld   a,$3F
108C: 32 96 0F    ld   ($0F96),a		; activates the tones and noise generator for all channels

108F: DD 21 A0 0F ld   ix,$0FA0
1093: CD 4C 11    call $114C			; processes the first sound entry
1096: DD 21 B8 0F ld   ix,$0FB8
109A: CD 4C 11    call $114C			; processes the second sound entry
109D: DD 21 D0 0F ld   ix,$0FD0
10A1: CD 4C 11    call $114C			; processes the third sound entry

10A4: DD 21 A0 0F ld   ix,$0FA0			; writes channel 0 data to the PSG
10A8: CD D0 10    call $10D0
10AB: DD 21 B8 0F ld   ix,$0FB8			; writes channel 1 data to the PSG
10AF: CD D0 10    call $10D0
10B2: DD 21 D0 0F ld   ix,$0FD0			; writes channel 2 data to the PSG
10B6: CD D0 10    call $10D0

10B9: 2A 96 0F    ld   hl,($0F96)		; l = channel mask
10BC: 7D          ld   a,l
10BD: BC          cp   h
10BE: 28 09       jr   z,$10C9			; if the mask has changed, sets the channel state
10C0: 32 97 0F    ld   ($0F97),a		; copies the mask to avoid setting the state if there are no modifications
10C3: 4F          ld   c,a
10C4: 3E 07       ld   a,$07			; mixer control register
10C6: CD 4E 13    call $134E			; writes to the PSG on which channels the tones and noise generator are active

10C9: DD E1       pop  ix
10CB: D1          pop  de
10CC: E1          pop  hl
10CD: C3 74 10    jp   $1074			; ends the interrupt

; writes the channel data pointed to by ix to the PSG
10D0: DD 6E 0E    ld   l,(ix+$0e)		; reads the control register
10D3: CB 45       bit  0,l
10D5: C8          ret  z				; if the channel is not active, exit
10D6: CB 55       bit  2,l
10D8: C0          ret  nz				; if notes or envelopes don't need to be updated, exit
10D9: CB 7D       bit  7,l
10DB: C0          ret  nz

10DC: CB 75       bit  6,l			; if bit 6 = 0, skip the following (write note frequency to PSG)
10DE: 28 13       jr   z,$10F3
10E0: DD 4E 03    ld   c,(ix+$03)	; reads the note frequency (lower part)
10E3: DD 7E FD    ld   a,(ix-$03)	; reads the PSG register to write (channel frequency (lower 8 bits))
10E6: CD 4E 13    call $134E		; writes to PSG register number 'a' the value 'c'
10E9: DD 4E 04    ld   c,(ix+$04)	; reads the note frequency (upper part)
10EC: DD 7E FD    ld   a,(ix-$03)
10EF: 3C          inc  a			; PSG register to write (channel frequency (upper 4 bits))
10F0: CD 4E 13    call $134E

10F3: CB 6D       bit  5,l			; if bit 5 = 0, skip the following (write desired volume or envelope)
10F5: 28 32       jr   z,$1129
10F7: CB 65       bit  4,l
10F9: 20 0B       jr   nz,$1106		; if bit 4 != 0, envelopes are generated for the volume
10FB: DD 7E FE    ld   a,(ix-$02)	; reads the PSG register to write (amplitude)
10FE: DD 4E 07    ld   c,(ix+$07)	; reads the volume
1101: CD 4E 13    call $134E		; writes the new volume to the PSG
1104: 18 23       jr   $1129

1106: 3A 99 0F    ld   a,($0F99)	; reads the envelope period low byte
1109: 4F          ld   c,a
110A: 3E 0B       ld   a,$0B		; PSG envelope control register
110C: CD 4E 13    call $134E
110F: 3A 9A 0F    ld   a,($0F9A)	; reads the envelope period high byte
1112: 4F          ld   c,a
1113: 3E 0C       ld   a,$0C
1115: CD 4E 13    call $134E		; writes the new envelope period (in units of 128 microseconds)
1118: 3A 9B 0F    ld   a,($0F9B)	; reads the envelope type and writes it to the PSG
111B: 4F          ld   c,a
111C: 3E 0D       ld   a,$0D
111E: CD 4E 13    call $134E
1121: DD 7E FE    ld   a,(ix-$02)	; reads the PSG register to write (amplitude)
1124: 0E 10       ld   c,$10
1126: CD 4E 13    call $134E		; leaves the volume in the hands of the envelope generator

; l = (ix + 0x0e)
1129: 3E 07       ld   a,$07
112B: CB 4D       bit  1,l
112D: 28 11       jr   z,$1140		; if bit 1 of 0x0e is 0, doesn't activate the noise generator
112F: 3E 3F       ld   a,$3F
1131: CB 5D       bit  3,l
1133: 28 0B       jr   z,$1140		; if bit 3 of 0x0e is 0, skip the following
1135: 3A 9C 0F    ld   a,($0F9C)
1138: 4F          ld   c,a
1139: 3E 06       ld   a,$06
113B: CD 4E 13    call $134E		; sets the noise generator period
113E: 3E 3F       ld   a,$3F

1140: DD A6 FF    and  (ix-$01)		; AND with the bits representing the channel
1143: 4F          ld   c,a
1144: 3A 96 0F    ld   a,($0F96)	; updates the noise generator configuration
1147: A9          xor  c
1148: 32 96 0F    ld   ($0F96),a
114B: C9          ret

; processes a sound channel
114C: DD 7E 0E    ld   a,(ix+$0e)		; checks if the entry is active
114F: CB 47       bit  0,a
1151: C8          ret  z				; if not, exit
1152: E6 87       and  $87				; (10000111) ignores the bits that don't matter and updates the value
1154: DD 77 0E    ld   (ix+$0e),a
1157: 3A 98 0F    ld   a,($0F98)		; loads the tempo
115A: A7          and  a
115B: C2 F7 11    jp   nz,$11F7			; if it's not 0, skip the tone update part

115E: DD 35 02    dec  (ix+$02)			; decrements the current note duration
1161: C2 F7 11    jp   nz,$11F7			; if it hasn't finished yet, jump
1164: DD 36 0E 01 ld   (ix+$0e),$01		; marks entry to be processed

1168: DD 5E 00    ld   e,(ix+$00)		; loads the last note address into de
116B: DD 56 01    ld   d,(ix+$01)
116E: 06 06       ld   b,$06			; 6 entries total
1170: 21 06 13    ld   hl,$1306
1173: 1A          ld   a,(de)			; compares the first byte read with possible commands
1174: BE          cp   (hl)
1175: 20 11       jr   nz,$1188			; if not equal, advance to the next entry

1177: 23          inc  hl				; if a command has been identified, read the jump address
1178: 7E          ld   a,(hl)
1179: 23          inc  hl
117A: 66          ld   h,(hl)
117B: 6F          ld   l,a
117C: 01 6E 11    ld   bc,$116E			; saves the return address (to reprocess the entries)
117F: C5          push bc
1180: EB          ex   de,hl
1181: 23          inc  hl
1182: 4E          ld   c,(hl)			; loads the first parameter into bc
1183: 23          inc  hl
1184: 46          ld   b,(hl)
1185: 23          inc  hl
1186: EB          ex   de,hl
1187: E9          jp   (hl)				; jumps to the address

1188: 23          inc  hl				; advance to the next entry
1189: 23          inc  hl
118A: 23          inc  hl
118B: 10 E6       djnz $1173

; arrives here after processing the commands
118D: FE FF       cp   $FF				; if a = 0xff, notes end
118F: 20 05       jr   nz,$1196			; otherwise, continue
1191: DD 36 0E 00 ld   (ix+$0e),$00		; marks the channel as not active
1195: C9          ret

1196: EB          ex   de,hl			; continues processing the entry
1197: 06 01       ld   b,$01
1199: DD 70 11    ld   (ix+$11),b		; sets values so that changes occur in envelope generation, volume and base frequency
119C: DD 70 08    ld   (ix+$08),b
119F: DD 70 12    ld   (ix+$12),b
11A2: DD 70 0D    ld   (ix+$0d),b
11A5: 05          dec  b
11A6: DD 70 0C    ld   (ix+$0c),b		; initializes the indices in the envelope generation and base frequency tables
11A9: DD 70 09    ld   (ix+$09),b
11AC: 4E          ld   c,(hl)			; reads the first data byte (note + octave)
11AD: 23          inc  hl
11AE: 7E          ld   a,(hl)			; reads the second data byte (note duration)
11AF: 23          inc  hl
11B0: DD 77 02    ld   (ix+$02),a		; saves the note duration
11B3: CB 79       bit  7,c				; if bit 7 of the first byte = 1, the noise generator is activated
11B5: 28 0D       jr   z,$11C4
11B7: 7E          ld   a,(hl)			; reads the noise generator period and saves it
11B8: 32 9C 0F    ld   ($0F9C),a
11BB: DD CB 0E CE set  1,(ix+$0e)		; activates bits 1 and 3
11BF: DD CB 0E DE set  3,(ix+$0e)
11C3: 23          inc  hl

11C4: DD 36 07 00 ld   (ix+$07),$00		; sets the channel volume to 0
11C8: DD 75 00    ld   (ix+$00),l		; saves the current notes address
11CB: DD 74 01    ld   (ix+$01),h
11CE: DD CB 0E FE set  7,(ix+$0e)		; activates bit 7 in case byte one does not contain a note

11D2: 79          ld   a,c
11D3: E6 0F       and  $0F				; if the byte read & 0x0f = 0x0f, exit
11D5: FE 0F       cp   $0F
11D7: C8          ret  z

11D8: DD CB 0E BE res  7,(ix+$0e)		; deactivates bit 7 of 0x0e

; if it reaches here, in a there is a note of the chromatic scale
11DC: 87          add  a,a				; adjusts entry in note tone table
11DD: 21 E5 0F    ld   hl,$0FE5
11E0: CD 48 13    call $1348
11E3: 5E          ld   e,(hl)
11E4: 23          inc  hl
11E5: 56          ld   d,(hl)			; de = note tone
11E6: 79          ld   a,c				; gets the original value with which it was indexed
11E7: 0F          rrca					; keeps the 4 most significant bits of the first byte read
11E8: 0F          rrca
11E9: 0F          rrca
11EA: 0F          rrca
11EB: E6 07       and  $07				; gets the note octave
11ED: EB          ex   de,hl
11EE: CD 6C 13    call $136C			; hl = hl / (2 ^ a) (adjusts the octave tone)

11F1: DD 75 03    ld   (ix+$03),l		; saves the result
11F4: DD 74 04    ld   (ix+$04),h

11F7: DD CB 0E 7E bit  7,(ix+$0e)		; exit if what it read was not a note
11FB: C0          ret  nz
11FC: DD CB 0E 56 bit  2,(ix+$0e)		; exit if envelopes and volume do not need to be updated
1200: C0          ret  nz

1201: CD 75 12    call $1275			; updates some registers (checks if envelope generation and volume need to be updated)
1204: DD 35 11    dec  (ix+$11)			; decrements the counter and if it is not 0, exit
1207: C0          ret  nz
1208: DD 35 08    dec  (ix+$08)
120B: CC 31 12    call z,$1231			; updates some registers (checks if the base note tone needs to be updated)

120E: DD 7E 0F    ld   a,(ix+$0f)		; resets the counters
1211: DD 77 11    ld   (ix+$11),a
1214: DD 7E 13    ld   a,(ix+$13)		; gets the tone modification
1217: 16 00       ld   d,$00
1219: CB 7F       bit  7,a				; sign extends 0x13 and saves it in de
121B: 28 01       jr   z,$121E
121D: 15          dec  d
121E: DD 6E 03    ld   l,(ix+$03)		; hl = note frequency
1221: DD 66 04    ld   h,(ix+$04)
1224: 5F          ld   e,a
1225: 19          add  hl,de			; updates the note frequency
1226: DD 75 03    ld   (ix+$03),l
1229: DD 74 04    ld   (ix+$04),h
122C: DD CB 0E F6 set  6,(ix+$0e)		; indicates that the PSG frequency needs to be changed
1230: C9          ret

; checks if the base note tone needs to be updated
1231: DD 7E 09    ld   a,(ix+$09)		; reads the table index
1234: DD 6E 05    ld   l,(ix+$05)		; reads the data address
1237: DD 66 06    ld   h,(ix+$06)
123A: CD 48 13    call $1348			; hl = hl + a
123D: 7E          ld   a,(hl)
123E: FE 7F       cp   $7F
1240: 20 10       jr   nz,$1252			; if it did not read 0x7f, jump
1242: 3E FF       ld   a,$FF			; counters to maximum
1244: DD 77 11    ld   (ix+$11),a
1247: DD 77 0F    ld   (ix+$0f),a
124A: DD 77 08    ld   (ix+$08),a
124D: DD 36 13 00 ld   (ix+$13),$00		; note tone is not modified
1251: C9          ret

1252: FE 80       cp   $80
1254: 20 06       jr   nz,$125C			; if it did not read 0x80, jump
1256: AF          xor  a				; clears the table index and reprocesses the data from that address
1257: DD 77 09    ld   (ix+$09),a
125A: 18 D5       jr   $1231

; otherwise updates the values
125C: DD 77 08    ld   (ix+$08),a		; updates the change counter
125F: 23          inc  hl
1260: 7E          ld   a,(hl)
1261: DD 77 13    ld   (ix+$13),a		; updates the tone modification
1264: 23          inc  hl
1265: 7E          ld   a,(hl)
1266: DD 77 0F    ld   (ix+$0f),a		; starts the main counter and its limit
1269: DD 77 11    ld   (ix+$11),a
126C: DD 7E 09    ld   a,(ix+$09)		; points to the next table entry
126F: C6 03       add  a,$03
1271: DD 77 09    ld   (ix+$09),a
1274: C9          ret

; checks if envelope generation and volume need to be updated
1275: DD 35 12    dec  (ix+$12)
1278: C0          ret  nz
1279: DD 35 0D    dec  (ix+$0d)
127C: CC 9B 12    call z,$129B		; updates some envelope registers and volume

127F: DD CB 0E EE set  5,(ix+$0e)	; indicates that envelopes and volume need to be set
1283: DD 7E 10    ld   a,(ix+$10)
1286: DD 77 12    ld   (ix+$12),a	; reloads the counter for envelope generation and volume modification
1289: DD CB 0E 66 bit  4,(ix+$0e)	; if using the envelope generator, exit
128D: C0          ret  nz
128E: DD 7E 07    ld   a,(ix+$07)	; reads the note volume
1291: DD 86 14    add  a,(ix+$14)	; adds the volume increment
1294: E6 0F       and  $0F
1296: DD 77 07    ld   (ix+$07),a	; updates the note volume
1299: 4F          ld   c,a
129A: C9          ret

; reads values from the envelope and base volume table and updates the registers
129B: DD 7E 0C    ld   a,(ix+$0c)	; recovers the table index
129E: DD 6E 0A    ld   l,(ix+$0a)	; gets the data address
12A1: DD 66 0B    ld   h,(ix+$0b)
12A4: CD 48 13    call $1348		; hl = hl + a
12A7: 7E          ld   a,(hl)
12A8: FE 7F       cp   $7F			; if the byte read is not 0x7f, jump
12AA: 20 10       jr   nz,$12BC
12AC: 3E FF       ld   a,$FF
12AE: DD 77 12    ld   (ix+$12),a	; counters to maximum and without modifying note volume
12B1: DD 77 10    ld   (ix+$10),a
12B4: DD 77 0D    ld   (ix+$0d),a
12B7: DD 36 14 00 ld   (ix+$14),$00
12BB: C9          ret

12BC: FE 80       cp   $80			; if the byte read is not 0x80, jump
12BE: 20 06       jr   nz,$12C6
12C0: AF          xor  a
12C1: DD 77 0C    ld   (ix+$0c),a	; resets the table index and continues processing
12C4: 18 D5       jr   $129B

12C6: CB 7F       bit  7,a			; if bit 7 of the byte read is not active, jump
12C8: 28 23       jr   z,$12ED		; otherwise, updates the envelope period and type
12CA: E6 0F       and  $0F
12CC: 32 9B 0F    ld   ($0F9B),a	; updates the envelope type
12CF: 23          inc  hl
12D0: 7E          ld   a,(hl)
12D1: 32 99 0F    ld   ($0F99),a	; updates the envelope period
12D4: 23          inc  hl
12D5: 7E          ld   a,(hl)
12D6: 32 9A 0F    ld   ($0F9A),a
12D9: 23          inc  hl
12DA: 7E          ld   a,(hl)		; reads the new counter
12DB: DD 77 12    ld   (ix+$12),a
12DE: DD 36 0D 01 ld   (ix+$0d),$01
12E2: DD CB 0E E6 set  4,(ix+$0e)	; leaves the volume in the hands of the envelope generator
12E6: DD 7E 0C    ld   a,(ix+$0c)	; advances the table index by 4
12E9: C6 04       add  a,$04
12EB: 18 15       jr   $1302

12ED: DD 77 0D    ld   (ix+$0d),a	; updates the second counter
12F0: 23          inc  hl
12F1: 7E          ld   a,(hl)
12F2: DD 77 14    ld   (ix+$14),a	; updates the base volume
12F5: 23          inc  hl
12F6: 7E          ld   a,(hl)
12F7: DD 77 10    ld   (ix+$10),a	; updates the first counter and its limit
12FA: DD 77 12    ld   (ix+$12),a
12FD: DD 7E 0C    ld   a,(ix+$0c)	; advances the table index by 3
1300: C6 03       add  a,$03

1302: DD 77 0C    ld   (ix+$0c),a
1305: C9          ret

; table of 6 entries (related to 0x114c and tables 0x0fac)
; format:
	byte 1: pattern to search
	bytes 2 and 3: address to jump to if the pattern is found
1306: 	FE 131B -> saves a new note address in channel 2 and activates it
		FD 132A -> saves a new note address in channel 3 and activates it
		FB 1339 -> saves a new base note tone address
		FC 1347 -> does nothing
		FA 1340 -> saves a new address for volume changes and envelope generator
		F9 1318 -> changes by bc (changes to another position in the music table)

; routine reached with entry 5 of 0x1306
1318: 50          ld   d,b	; de = bc
1319: 59          ld   e,c
131A: C9          ret

; routine reached with entry 0 of 0x1306
131B: ED 43 B8 0F ld   ($0FB8),bc	; saves a new note address in channel 2
131F: 3E 05       ld   a,$05		; + 0x0e = 5
1321: 32 C6 0F    ld   ($0FC6),a	; and activates channel 2
1324: 3E 01       ld   a,$01
1326: 32 BA 0F    ld   ($0FBA),a	; sets a note duration of 1 unit
1329: C9          ret

; routine reached with entry 1 of 0x1306
132A: ED 43 D0 0F ld   ($0FD0),bc	; saves a new note address in channel 3
132E: 3E 05       ld   a,$05
1330: 32 DE 0F    ld   ($0FDE),a	; and activates channel 3
1333: 3E 01       ld   a,$01
1335: 32 D2 0F    ld   ($0FD2),a
1338: C9          ret

; routine reached with entry 2 of 0x1306
1339: DD 71 05    ld   (ix+$05),c	; saves what was read in the base tone change table
133C: DD 70 06    ld   (ix+$06),b
133F: C9          ret

; routine reached with entry 4 of 0x1306
1340: DD 71 0A    ld   (ix+$0a),c	; saves what was read in the volume change and envelope generator table
1343: DD 70 0B    ld   (ix+$0b),b
1346: C9          ret

; routine reached with entry 3 of 0x1306
1347: C9          ret

; sums hl + a
1348: 85          add  a,l
1349: 6F          ld   l,a
134A: 8C          adc  a,h
134B: 95          sub  l
134C: 67          ld   h,a
134D: C9          ret

; writes to PSG register number 'a' the value 'c'
; a = register number
; c = value to write
134E: 06 F4       ld   b,$F4	; PPI port A, write PSG register index
1350: ED 79       out  (c),a
1352: 06 F6       ld   b,$F6	; PPI port C
1354: ED 78       in   a,(c)
1356: F6 C0       or   $C0
1358: ED 79       out  (c),a	; selects the corresponding PSG register
135A: E6 3F       and  $3F
135C: ED 79       out  (c),a
135E: 06 F4       ld   b,$F4
1360: ED 49       out  (c),c	; writes the value to the corresponding register
1362: 06 F6       ld   b,$F6	; PPI port C
1364: 4F          ld   c,a
1365: F6 80       or   $80
1367: ED 79       out  (c),a	; writes the data to the PSG register
1369: ED 49       out  (c),c
136B: C9          ret

; hl = hl / (2 ^ a)
136C: A7          and  a			; if a = 0, exit
136D: C8          ret  z
136E: CB 3C       srl  h			; divide by 2
1370: CB 1D       rr   l
1372: 3D          dec  a			; continue while a > 0
1373: 20 F9       jr   nz,$136E
1375: C9          ret

; turns off sound
1376: 3E 84       ld   a,$84		; stops sound generation
1378: 32 AE 0F    ld   ($0FAE),a
137B: 32 C6 0F    ld   ($0FC6),a
137E: 32 DE 0F    ld   ($0FDE),a
1381: 0E 3F       ld   c,$3F		; 0011 1111 (turns off the 3 sound channels)
1383: 3E 07       ld   a,$07		; register 7 (PSG enable)
1385: C3 4E 13    jp   $134E

; ------- end of music code section -------

; ------- music data -------

; base note tone for voices
1388: 	01 01 01
		02 FF 01
		01 01 01
		80 			-> resets and continues processing

1390:       01 01 04 02 FF 04-01 01 04 80 0C 01 01 0C ................
13A0: FF 01 7F 01 FF 02 80 01-01 04 80 01 0F 08 0F FF ................
13B0: 0A 7F 0F 01 05 0F FF 09-7F 01 D8 02 80 01 00 01 ................
13C0: 7F

; envelopes and volume changes for voices
13C1: 01 05 01    ld   bc,$0105
13C4: 7F

13C5:                01 0F 01-01 00 28 0F FF 14 7F 05 ..........(.....
13D0: 01 02 05 02 01 05 FF 0F-01 00 3C 0A FF 14 7F 0F ..........<.....
13E0: 01 0F 01 01 00 28 0F FF 0F-7F 01 0C 01 01 00 28 0C ....(.........(.
13F0: FF 0A 7F 01 0C 14 02 FF-14 7F 01 0A 0A 7F FB 92 ................
1400: 13 FA CF 13 59 14 FA F3-13 5B 04 59 08 FA CF 13 ....Y....[.Y....
1410: 57 10 59 10 55 10 57 10-59 20 60 20 59 20 60 20 W.Y.U.W.Y ` Y `
1420: 59 08 60 08 59 10 59 14-FA F3 13 5B 04 59 08 FA Y.`.Y.Y....[.Y..
1430: CF 13 57 10 59 10 55 10-57 10 59 20 65 10 62 10 ..W.Y.U.W.Y e.b.
1440: 64 10 60 10 62 40 65 20-67 10 65 10 64 20 60 20 d.`.b@e g.e.d `
1450: 65 20 62 10 64 08 65 08-64 20 60 20 65 10 67 10 e b.d.e.d ` e.g.
1460: 69 10 6A 10 70 20 67 20-65 06 FA F3 13 67 04 65 i.j.p g e....g.e
1470: 06 FA CF 13 62 10 64 10-60 10 62 40 F9 FE 13 FF ....b.d.`.b@....
1480: FB BD 13 FA DF 13 FE 8D-14 82 50 1A FF FB A3 13 ..........P.....
1490: FA DF 13 20 50 FF FB B9-13 FA 9C 13 17 04 FF FB ... P...........
14A0: A3 13 FA CF 13 60 0F FF-FA CF 13 FB A7 13 7B 0F .....`........{.
14B0: FF

; initialization data of the voice for channel 3
14B1: FB 1388 -> saves a new base note tone address
14B4: FA 13C1 -> saves a new address for envelopes and volume changes
14B7: 54 -> note and octave

14B8:                         0A FF FB BD 13 FA AB 13 .......T........
14C0: FE D2 14 6B 04 6B 05 6B-04 6B 05 6B 04 6B 05 6B ...k.k.k.k.k.k.k
14D0: 0F FF FB BD 13 FA AB 13-76 04 76 05 76 04 76 05 ........v.v.v.v.
14E0: 76 04 76 05 76 0F FF FB-B9 13 FA B2 13 82 14 1A v.v.v...........
14F0: 0F 0F FF FB 92 13 FA C5-13 FE 3E 15 4B 1E 4F 01 ..........>.K.O.
1500: FE 47 15 49 28 4F 04 FE-3E 15 4B 1E 4F 01 FE 47 .G.I(O..>.K.O..G
1510: 15 49 28 4F 04 FE 3E 15-4B 1E 4F 01 FE 47 15 49 .I(O..>.K.O..G.I
1520: 28 4F 04 FE 3E 15 4B 1E-4F 01 FE 47 15 49 28 4F (O..>.K.O..G.I(O
1530: 04 FE 3E 15 4B 1E 4F 01-FE 47 15 49 3C FF FB 92 ..>.K.O..G.I<...
1540: 13 FA C5 13 43 1E FF FB-92 13 FA C5 13 43 28 FF ....C........C(.
1550: FB BD 13 FA E9 13 A2 14-1A A2 14 1A A0 1E 19 FF ................
1560: FB BD 13 FA E9 13 A0 1E-19 FF

; ------- end of game sound effects data -----------

; ---------------------- code and data related to screen generation -----------------------------------

156A-156B: address of the graphic data that forms the screen
156C: if it is 0, indicates if the screen is illuminated

; table of block types that form the screens. Each entry contains a pointer to the block information
156D: 	0000 -> 0x00 (0x00) -> this block does not exist
		1973 -> 0x01 (0x02) -> thin black brick parallel to y
		196E -> 0x02 (0x04) -> thin red brick parallel to x
		193C -> 0x03 (0x06)	-> thick black brick parallel to y
		1941 -> 0x04 (0x08) -> thick red brick parallel to x
		1946 -> 0x05 (0x0a) -> small windows block, slightly rounded and black parallel to the y axis
		194B -> 0x06 (0x0c) -> small windows block, slightly rounded and red parallel to the x axis
		1950 -> 0x07 (0x0e) -> red railing parallel to the y axis
		1955 -> 0x08 (0x10) -> red railing parallel to the x axis
		195A -> 0x09 (0x12) -> white column parallel to the y axis
		1969 -> 0x0a (0x14) -> white column parallel to the x axis
		1AEF -> 0x0b (0x16) -> stairs with black brick on the edge parallel to the y axis
		1B28 -> 0x0c (0x18) -> stairs with red brick on the edge parallel to the x axis
		1BA0 -> 0x0d (0x1a) -> floor of thick blue tiles
		1BA5 -> 0x0e (0x1c) -> floor of red and blue tiles forming a checkerboard effect
		1BAA -> 0x0f (0x1e) -> floor of blue tiles
		1BAF -> 0x10 (0x20) -> floor of yellow tiles
		1CB8 -> 0x11 (0x22) -> block of arches passing through pairs of columns parallel to the y axis
		1CFD -> 0x12 (0x24) -> block of arches passing through pairs of columns parallel to the x axis
		1D23 -> 0x13 (0x26) -> block of arches with columns parallel to the y axis
		1D48 -> 0x14 (0x28) -> block of arches with columns parallel to the x axis
		1F5F -> 0x15 (0x2a) -> double yellow rivet on the brick parallel to the y axis
		1F64 -> 0x16 (0x2c) -> double yellow rivet on the brick parallel to the x axis
		17FE -> 0x17 (0x2e) -> solid block of thin brick parallel to the x axis
		18A6 -> 0x18 (0x30) -> solid block of thin brick parallel to the y axis
		17F9 -> 0x19 (0x32) -> white table parallel to the x axis
		18A1 -> 0x1a (0x34) -> white table parallel to the y axis
		1932 -> 0x1b (0x36) -> small discharge pillar placed next to a wall on the x axis
		1B9B -> 0x1c (0x38) -> red and black terrain area
		1E0F -> 0x1d (0x3a) -> bookshelves parallel to the y axis
		1E33 -> 0x1e (0x3c) -> bed
		1E5F -> 0x1f (0x3e) -> large blue and yellow windows parallel to the y axis
		1E9D -> 0x20 (0x40) -> large blue and yellow windows parallel to the x axis
		1ECC -> 0x21 (0x42) -> candelabras with 2 candles parallel to the x axis
		1ED6 -> 0x22 (0x44) -> does nothing
		1EDE -> 0x23 (0x46) -> yellow rivet with support parallel to the y axis
		18DA -> 0x24 (0x48) -> red railing corner
		1EE3 -> 0x25 (0x4a) -> yellow rivet with support parallel to the x axis
		18EF -> 0x26 (0x4c) -> red railing corner (2)
		1F1A -> 0x27 (0x4e) -> rounded passage hole with thin red and black bricks parallel to the x axis
		192D -> 0x28 (0x50) -> small windows block, rectangular and black parallel to the y axis
		1928 -> 0x29 (0x52) -> small windows block, rectangular and red parallel to the x axis
		191E -> 0x2a (0x54) -> 1 bottle and a jar
		1925 -> 0x2b (0x56) -> does nothing
		1AE9 -> 0x2c (0x58) -> stairs with black brick on the edge parallel to the y axis (2)
		1A99 -> 0x2d (0x5a) -> stairs with red brick on the edge parallel to the x axis (2)
		1726 -> 0x2e (0x5c) -> rectangular passage hole with thin black bricks parallel to the y axis
		177C -> 0x2f (0x5e) -> rectangular passage hole with thin red bricks parallel to the x axis
		17A4 -> 0x30 (0x60) -> thin black and red brick corner
		17AE -> 0x31 (0x62) -> thick black and red brick corner
		1EE8 -> 0x32 (0x64) -> rounded passage hole with thin black and red bricks parallel to the y axis
		1C86 -> 0x33 (0x66) -> yellow rivet corner with support
		1C96 -> 0x34 (0x68) -> yellow rivet corner
		17B8 -> 0x35 (0x6a) -> does nothing
		1903 -> 0x36 (0x6c) -> red railing corner (3)
		1F76 -> 0x37 (0x6e) -> thin red and black brick pyramid
		18AB -> 0x38 (0x70) -> solid block of thin red and black brick, with yellow and black tiles on top, parallel to the y axis
		1803 -> 0x39 (0x72) -> solid block of thin red and black brick, with yellow and black tiles on top, parallel to the x axis
		18CD -> 0x3a (0x74) -> solid block of thin red and black brick, with yellow and black tiles on top, that grows upwards
		1EC6 -> 0x3b (0x76) -> candelabras with 2 candles parallel to the x axis (2)
		1EA3 -> 0x3c (0x78) -> candelabras with 2 candles parallel to the y axis
		1ED1 -> 0x3d (0x7a) -> candelabras with wall support and 2 candles parallel to the y axis
		1937 -> 0x3e (0x7c) -> small discharge pillar placed next to a wall on the y axis
		18B1 -> 0x3f (0x7e) -> thin black and red brick corner (2)
		18BF -> 0x40 (0x80) -> thin black and red brick corner (3)
		1F80 -> 0x41 (0x82) -> thin red brick forming a right triangle parallel to the x axis
		1F86 -> 0x42 (0x84) -> thin black brick forming a right triangle parallel to the y axis
		1F2B -> 0x43 (0x86) -> rounded passage hole with thin red and black bricks parallel to the y axis, with thick pillars between the holes
		1F59 -> 0x44 (0x88) -> rounded passage hole with thin red and black bricks parallel to the x axis, with thick pillars between the holes
		1D99 -> 0x45 (0x8a) -> bench to sit on parallel to the x axis
		1D6B -> 0x46 (0x8c) -> bench to sit on parallel to the y axis
		1797 -> 0x47 (0x8e) -> very low thin black and red brick corner
		178A -> 0x48 (0x90) -> very low thick black and red brick corner
		1B96 -> 0x49 (0x92) -> flat corner delimited with black line and blue floor
		1D9F -> 0x4a (0x94) -> work table
		1DD8 -> 0x4b (0x96) -> plates
		1DFC -> 0x4c (0x98) -> bottles with handles
		1E06 -> 0x4d (0x9a) -> cauldron
		1BB4 -> 0x4e (0x9c) -> flat corner delimited with black line and yellow floor
		17EF -> 0x4f (0x9e) -> solid block of thin red and black brick, with blue tiles on top, parallel to the y axis
		17F4 -> 0x50 (0xa0) -> solid block of thin red and black brick, with blue top, parallel to the y axis
		1897 -> 0x51 (0xa2) -> solid block of thin red and black brick, with blue tiles on top, parallel to the x axis
		189C -> 0x52 (0xa4) -> solid block of thin red and black brick, with blue top, parallel to the x axis
		17BB -> 0x53 (0xa6) -> solid block of thin red and black brick, with blue tiles on top and stair-stepped, parallel to the x axis
		17E7 -> 0x54 (0xa8) -> solid block of thin red and black brick, with blue top and stair-stepped, parallel to the x axis
		1841 -> 0x55 (0xaa) -> solid block of thin red and black brick, with blue tiles on top and stair-stepped, parallel to the y axis
		186D -> 0x56 (0xac) -> solid block of thin red and black brick, with blue top and stair-stepped, parallel to the y axis
		1DDD -> 0x57 (0xae) -> human skulls
		1B91 -> 0x58 (0xb0) -> skeleton remains???
		1914 -> 0x59 (0xb2) -> monster face with horns
		1919 -> 0x5a (0xb4) -> support with cross
		1E01 -> 0x5b (0xb6) -> large cross
		1F69 -> 0x5c (0xb8) -> library books parallel to the x axis
		1ED9 -> 0x5d (0xba) -> library books parallel to the y axis
		195F -> 0x5e (0xbc) -> top of a wall with small slightly rounded and black window parallel to the y axis???
		1964 -> 0x5f (0xbe) -> top of a wall with small slightly rounded and red window parallel to the x axis???

; hl = hl + a
162D: 85          add  a,l
162E: 6F          ld   l,a
162F: 8C          adc  a,h
1630: 95          sub  l
1631: 67          ld   h,a
1632: C9          ret

; checks if the tile indicated by hl is visible, and if so, updates the tile shown in this position and the associated depth data
; h = pos in y using the tile buffer coordinate system
; l = pos in x using the tile buffer coordinate system
; c = tile number to place
; ix = pointer to the block construction data

; the tile buffer is 16x20, although the grid is 32x36. The part of the grid that is mapped in the tile buffer is the central one
; (removing 8 units to the left, right, top and bottom)
1633: 7C          ld   a,h			; gets the position in y
1634: D6 08       sub  $08			; translates the position y 8 units upwards to have the coordinate at the origin
1636: FE 14       cp   $14
1638: D0          ret  nc			; if it is outside the visible area in y (y - 8 >= 20), exit
1639: 57          ld   d,a			; d = translated y position

163A: 7D          ld   a,l			; gets the position in x
163B: D6 08       sub  $08			; translates the position x 8 units to the left to have the coordinate at the origin
163D: FE 10       cp   $10			; if it is outside the visible area in x (x - 8 >= 16), exit
163F: D0          ret  nc
1640: 5F          ld   e,a			; e = translated x position

; here it arrives saving in de the final coordinates in the tile buffer, and in hl the old ones
1641: E5          push hl			; saves the non-translated coordinates of the tile buffer on the stack (will be retrieved by routine 0x1667)
1642: EB          ex   de,hl		; hl = positions calculated now, de = old positions
1643: 7D          ld   a,l
1644: 6C          ld   l,h
1645: 26 00       ld   h,$00
1647: 29          add  hl,hl
1648: 29          add  hl,hl
1649: 29          add  hl,hl
164A: 29          add  hl,hl
164B: 29          add  hl,hl
164C: 5D          ld   e,l
164D: 54          ld   d,h
164E: 29          add  hl,hl
164F: 19          add  hl,de
1650: 87          add  a,a
1651: 5F          ld   e,a
1652: 87          add  a,a
1653: 83          add  a,e
1654: 85          add  a,l			; hl = 96*translated y pos + 6*translated x pos
1655: 6F          ld   l,a
1656: 8C          adc  a,h
1657: 95          sub  l
1658: 67          ld   h,a

1659: 11 80 8D    ld   de,$8D80		; de points to the start of the tile buffer
165C: 19          add  hl,de		; indexes in the tile buffer with the translated positions
165D: C3 67 16    jp   $1667		; updates the current tile data, according to what is in the tile, the new tile to place and the local grid coordinates

; here never arrives (???)
1660: 11 80 07    ld   de,$0780
1663: 19          add  hl,de
1664: 71          ld   (hl),c
1665: E1          pop  hl
1666: C9          ret

; saves the tile data in hl, according to what the current depth coordinates are and c (tile to write)
; if a tile had already been projected before, the new one has higher priority over the old one
; hl = pointer to the current tile data in the tile buffer
; c = tile number to place
1667: C5          push bc		; preserves bc and hl
1668: E5          push hl
1669: 23          inc  hl
166A: 23          inc  hl
166B: 54          ld   d,h		; de = hl + 2
166C: 5D          ld   e,l
166D: 23          inc  hl		; hl = hl + 3

; gets the highest priority tile values currently in the grid
166E: 4E          ld   c,(hl)	; c = previous x depth ([hl+3])
166F: 23          inc  hl
1670: 46          ld   b,(hl)	; b = previous y depth ([hl+4])
1671: 23          inc  hl
1672: 7E          ld   a,(hl)	; a = previous tile with higher priority ([hl+5])

1673: 12          ld   (de),a	; [hl + 2] = a (the previous tile now has lower priority)
1674: 13          inc  de		; de = hl + 3
1675: 21 DE 1F    ld   hl,$1FDE	; points to the tile depth in the grid (local grid coordinate system)
1678: 7E          ld   a,(hl)	; a = new x depth
1679: 12          ld   (de),a	; [hl + 3] = sets the new x depth
167A: B9          cp   c		; compares x depth with old x depth
167B: 30 08       jr   nc,$1685	; if new x depth >= old x depth, jump
167D: 23          inc  hl
167E: 7E          ld   a,(hl)	; a = new y depth
167F: 2B          dec  hl
1680: B8          cp   b		; if new y depth >= old y depth, jump
1681: 30 02       jr   nc,$1685

1683: 47          ld   b,a		; otherwise, b = new y depth
1684: 4E          ld   c,(hl)	; c = new x depth

1685: 23          inc  hl		; hl points to the new y depth (local grid coordinate system)
1686: 13          inc  de		; de = hl + 4
1687: 7E          ld   a,(hl)
1688: 12          ld   (de),a	; [hl + 4] = new y depth
1689: 13          inc  de		; de = hl + 5
168A: E1          pop  hl
168B: 71          ld   (hl),c	; [hl + 0] = c modified by previous and calc1 (old x depth)
168C: 23          inc  hl
168D: 70          ld   (hl),b	; [hl + 1] = b modified by previous and calc2 (old y depth)
168E: EB          ex   de,hl
168F: C1          pop  bc
1690: 71          ld   (hl),c	; [hl + 5] = new tile with highest priority

1691: E1          pop  hl		; recovers from the stack the non-translated tile buffer coordinates (put by the calling routine)
1692: C9          ret

; data about the tiles that form the blocks
1693: 2A 2C  							; 1 bottle and a jar
1695: DE E0 DF 							; large cross
1698: FD FC 							; monster face with horns
169A: 5F FE								; support with cross
169C: 1B 3A 3A 							; library books parallel to the y axis?
169F: 69 39 39							; library books parallel to the x axis?
16A2: 28 09 29 00						; thin black brick
16A6: 2B 0A 2D 00						; thin red brick
16AA: 23 22 61 29						; small windows block, rectangular and black parallel to the y axis
16AE: 26 25 27 2D						; small windows block, rectangular and red parallel to the x axis
16B2: 62 02 63 03						; thick black brick
16B6: 6A 06 74 07						; thick red brick
16BA: 23 22 21 29   					; small windows, slightly rounded and black
16BE: 26 25 24 2D						; small windows, slightly rounded and red
16C2: 37 36 35 00						; red railing parallel to the y axis
16C6: 34 33 32 00						; red railing parallel to the x axis
16CA: 99 9A 97 98						; yellow column
16CE: 23 21 1B 3A    					; top of a wall with small slightly rounded and black window parallel to the y axis???
16D2: 26 24 69 39						; top of a wall with small slightly rounded and red window parallel to the x axis???
16D6: 7F 7E 7D 00						; small discharge pillar placed next to a wall on the x axis
16DA: 58 57 56 00  						; small discharge pillar placed next to a wall on the y axis
16DE: 41 17 16 1A 14 1D 1E 40 15 1F 20 19	; work table
16EA: 12 B2 B2 45 13 B4 B5 B3 B1		; stairs with black brick on the edge parallel to the y axis
16F3: 10 81 81 44 11 83 84 82 80		; stairs with red brick on the edge parallel to the x axis
16FC: 1C 1B B8 B7 BA B9 B6 BB 28 09		; stairs with black brick on the edge parallel to the y axis (2)
1706: 6B 69 6C B0 AD AC AF AE 2B 0A 	; stairs with red brick on the edge parallel to the x axis (2)
1710: 58 28 51 53 57 55 54 50 52 2B 0A	; rectangular passage hole with thin black bricks parallel to the y axis
171B: 7F 2B 78 7A 7E 7C 7B 77 79 28 09  ; rectangular passage hole with thin red bricks parallel to the x axis

; characteristics of material 0x2e
1726: 1710			; pointer to the tiles that form the block
FC
F2 01 6D 84
F1 6D

172F:
F7 70 02 84 70
F7 71 03 6D 6D 84 71
FC
F9 6A
FD
F9 6B
FA
FB
F5
F9 61
FD
F9 65
FA
F9 68 80 63 80 69
FB
EF
F7 71 02 6D 6D 71
F9 61
FD
F9 65
FA
F9 66 80 67
F7 70 02 70
F7 71 6D 6D 84 71
F6
F6
F5
FE
FC
F9 62 80 63 80 64
FB
F5
F4
FA
FF

; characteristics of material 0x2f
177C: 	171B		; pointer to the tiles that form the block
FC
F2 01 6D 84
F1 6D 84
E9
EA 172F

; characteristics of material 0x48
178A: 16B2			; pointer to the tiles that form the block
EC 193C
F1
6E
6E
01 EC 41
19
FF

; characteristics of material 0x47
1797: 16A2			; pointer to the tiles that form the block
EC 1973				Call(0x1973);
F1
6E
6E
01
EC 196E
FF

; characteristics of material 0x30
17A4: 16A6			; pointer to the tiles that form the block
EC 196E
6E
19
F5
EC 1973
FF

; characteristics of material 0x31
17AE: 16B6				; pointer to the tiles that form the block
EC 1941			Call(0x1941)
F5
EC 193C
FF

; characteristics of material 0x35
17B8: 1B31				; pointer to the tiles that form the block
FF

; characteristics of material 0x53
17BB: 1B49				; pointer to the tiles that form the block

EC 17EF
F7 70 02 84 70
F7 71 01 84 71
F2 6D 01 84
F9 61
F1 01 84 6D
F2 6D 6D 02
EC 1891
F5
F6
F7 6E 6D
F7 6D 00
EC 1B28
FF

; characteristics of material 0x54
17E7: 1B6D			; pointer to the tiles that form the block
EC 17F4				call(0x17f4);
EA 17C0				ChangePc(0x17c0)

; characteristics of material 0x4f
17EF: 1B49			; pointer to the tiles that form the block
17F1: EA 1805		; ChangePC(0x1805)

; characteristics of material 0x50
17F4: 1B6D			; pointer to the tiles that form the block
17F6: EA 1805		; ChangePC(0x1805)

; characteristics of material 0x19
17F9: 	1B88		; pointer to the tiles that form the block
		EA 1805		; ChangePC(0x1805)

; characteristics of material 0x17
17FE: 	1B31		; pointer to the tiles that form the block
		EA 1805		; ChangePC(0x1805)

; characteristics of material 0x39
1803: 	1B5B		; pointer to the tiles that form the block

1805:
F7 71 71 82 FF			actualizaRegistro(0x71, -(valorRegistro(0x71)) + 0xff);
F7 70 6E 6E 02 84 70	actualizaRegistro(0x70, -(valorRegistro(0x6e) + valorRegistro(0x6e) + 2) + valorRegistro(0x70));
FC
F9 64
FE
F9 69
FA
F9 61 81 65 80 62
FB
F3
FD
FC
F9 66
FE
F9 68
FA
F9 61 81 67 80 61 80 62
FB
F3
F4
FA
F9 66
FE
F9 68
FA
F9 61 81 67 80 63
FF

; characteristics of material 0x55
1841: 1B52			; pointer to the tiles that form the block
EC 1897
F7 71 02 84 71
F7 70 01 84 70
F2 01 6D 84
F9 61
F1 6D 84 01
F2 6D 6D 02
EC 1875
F3
F6
F7 6E 6D
F7 6D 00
EC 1AEF
FF

; characteristics of material 0x56
186D: 1B76			; pointer to the tiles that form the block
EC 189C
EA 1846

; auxiliary material characteristics called from material 0x55
1875: 16A2			; pointer to the tiles that form the block
F7 71 6D 6D 84 71
F7 6E 01
FE
FC
F9 61
FD
F9 62
FA
F7 6E 01 6E
FB
F5
F4
FA
FF

; auxiliary material characteristics called from material 0x53
1891:	16A6		; pointer to the tiles that form the block
E9
EA 1877

; characteristics of material 0x51
1897: 1B52			; pointer to the tiles that form the block
1899: EA 18AD		; changePC(0x18ad);

; characteristics of material 0x52
189C: 1B76			; pointer to the tiles that form the block
189E: EA 18AD		; changePC(0x18ad);

; characteristics of material 0x1a
18A1: 	1B7F		; pointer to the tiles that form the block
		EA 18AD		; changePC(0x18ad);

; characteristics of material 0x18
18A6: 	1B3A		; pointer to the tiles that form the block
		EA 18AD		; changePC(0x18ad);

; characteristics of material 0x38
18AB: 1B64			; pointer to the tiles that form the block
18AD: E9          	FlipX();
18AE: EA 1805 		ChangePC(0x1805);

; characteristics of material 0x3f
18B1: 	16A6			; pointer to the tiles that form the block
F5
EC 1973				Call(0x1973)
F3
F7 6E 00
EC 196E				Call(0x196e)
FF

; characteristics of material 0x40
18BF:	16A2				; pointer to the tiles that form the block
F3
EC 196E			Call(0x196e)
F5
F7 6E 00
EC 1973			Call(0x1973)
FF

; characteristics of material 0x3a
18CD: 1B5B			; pointer to the tiles that form the block
18CF: F7          rst  $30
18D0: 6D          ld   l,l
18D1: 6D          ld   l,l
18D2: 6E          ld   l,(hl)
18D3: F7          rst  $30
18D4: 6E          ld   l,(hl)
18D5: 00          nop
18D6: EC AB 18    call pe,$18AB
18D9: FF          rst  $38

; characteristics of material 0x24
18DA: 16C2 		; pointer to the tiles that form the block
18DC:
EC 18E7			Call(0x18e7);
F7 6E 00 		actualizaRegistro(0x6e, 00);
F3				decTilePosX();
EC 1955			Call(0x1955);
FF

; auxiliary material characteristics called from material 0x24, 0x26 and 0x36
18E7: 16C2		; pointer to the tiles that form the block
18E9:
F7 6D 00		actualizaRegistro(0x6d, 00);
EA 19CA			ChangePC(0x19ca)

; characteristics of material 0x26
18EF: 16C2		; pointer to the tiles that form the block
EC 18E7			Call(0x18e7)
F2 6E 84 6D		UpdateTilePosY(-valorRegistro(0x6e) + valorRegistro(0x6d));
F1 01 6E 6D		UpdateTilePosX(1 + valorRegistro(0x6e) + valorRegistro(0x6d));
F7 6E 00		actualizaRegistro(0x6e, 00);
EC 1955			Call(0x1955)
FF

; characteristics of material 0x36
1903: 16C2 		; pointer to the tiles that form the block
EC 18E7			Call(0x18e7)
F2 6D 01 		UpdateTilePosY(01 + valorRegistro(0x6d));
F1 6D           UpdateTilePosX(valorRegistro(0x6d));
F7 6E 00		actualizaRegistro(0x6e, 00);
EC 1955			Call(0x1955)
FF

; characteristics of material 0x59
1914: 	1698		; pointer to the tiles that form the block
		EA 1920		; ChangePC(0x1920);

; characteristics of material 0x5a
1919: 	169A		; pointer to the tiles that form the block
		EA 1920		; ChangePC(0x1920);

; characteristics of material 0x2a
191E: 	1693		; pointer to the tiles that form the block
1920:
F9 63 80 64			pintaTile(63, decrementaTilePosYyDibujaUnoMas, 64);
FF

1925: 16AE			; pointer to the tiles that form the block
		FF

; characteristics of material 0x29
1928: 16AE			; pointer to the tiles that form the block
		EA 19A9		; ChangePC(0x19a9);

; characteristics of material 0x28
192D: 16AA			; pointer to the tiles that form the block
		EA 1990		; ChangePC(0x1990);

; characteristics of material 0x1b
1932: 	16D6		; pointer to the tiles that form the block
		EA 198C		; ChangePC(0x198c);

; characteristics of material 0x3e
1937: 16DA 			; pointer to the tiles that form the block
		EA 1975		; ChangePC(0x1975);

; characteristics of material 0x03
193C: 	16B2		; pointer to the tiles that form the block
		EA 19AD		; ChangePC(0x19ad);

; characteristics of material 0x04
1941: 	16B6		; pointer to the tiles that form the block
		EA 19C6 	; ChangePC(0x19C6);

; characteristics of material 0x05
1946: 	16BA		; pointer to the tiles that form the block
		EA 1990		; ChangePC(0x1990);

; characteristics of material 0x06
194B: 	16BE		; pointer to the tiles that form the block
		EA 19A9		; ChangePC(0x19a9);

; characteristics of material 0x07
1950: 	16C2		; pointer to the tiles that form the block
		EA 19CA		; ChangePC(0x19ca);

; characteristics of material 0x08
1955:	16C6		; pointer to the tiles that form the block
		EA 19D4		; ChangePC(0x19d4);

; characteristics of material 0x09
195A: 	16CA		; pointer to the tiles that form the block
		EA 1990		; ChangePC(0x1990);

; characteristics of material 0x5e
195F: 	16CE		; pointer to the tiles that form the block
		EA 1990		; ChangePC(0x1990);

; characteristics of material 0x5f
1964: 	16D2		; pointer to the tiles that form the block
		EA 19A9		; ChangePC(0x1990);

; characteristics of material 0x0a
1969: 	16CA		; pointer to the tiles that form the block
		EA 19A9		; ChangePC(0x19a9);

; characteristics of material 0x02
196E: 	16A6		; pointer to the tiles that form the block
		EA 198C		; ChangePC(0x198c);

; characteristics of material 0x01
1973: 	16A2			; pointer to the tiles that form the block

1975:
							// depth and in grid = depth and in grid - (param2*2 + 1);
F7 71 01 6E 6E 84 71		actualizaRegistro(0x71, -(01 + valorRegistro(0x6e) + valorRegistro(0x6e)) + valorRegistro(0x71));

EF          				IncParam2();

FD 							while (param2 > 0){
  	     						// save the initial position
FC								pushTilePos();

F9 61 							pintaTile(61, decrementaTilePosY);

FE 								while (param1 > 0){
F9 62 								pintaTile(62, decrementaTilePosY);

									(param1--;)
FA								}

F9 63							pintaTile(63, decrementaTilePosY);

FB          					popTilePos();
F5 								incTilePosX();
F4 								decTilePosY();

								(param2--;)
FA 							}
FF

198C:
E9          				FlipX();
EA 1975						ChangePC(1975);

; code that generates the columns and more blocks
1990:
; interpreted as:
						// decrement the depth in y of the block so characters are not covered by columns if they pass in front of them
						// depth and in grid = depth and in grid - (numColumns*2 + 1);
F7 71 01 6E 6E 84 71	actualizaRegistro(0x71, -(01 + valorRegistro(0x6e) + valorRegistro(0x6e)) + valorRegistro(0x71));

						// at minimum paint one column
EF						IncParam2();

						// parameter 2 indicates the number of columns to paint
FD						while (param2 > 0){
							// save the initial position of the column
FC							pushTilePos();

							// paint the base of the column
F9 61						pintaTile(61, decrementaTilePosY);

							// parameter 1 indicates the height of the column
FE 							while (param1 > 0){
								// paint the tile that forms the column itself
F9 62							pintaTile(62, decrementaTilePosY);

								(param1--;)
FA							}

							// paint the capital of the column
F9 63 80 64					pintaTile(63, decrementaTilePosYyDibujaUnoMas, 64);

							// update the position to draw the next column
FB 							popTilePos();
F5 							incTilePosX();
F4 							decTilePosY();

							(param2--;)
FA 						}
FF


19A9: 	E9 -> flipX
		EA 1990 -> changepc(1990)

19AD:
							// depth and in grid = depth and in grid - (param2*2 + 1);
F7 71 01 6E 6E 84 71		actualizaRegistro(0x71, -(01 + valorRegistro(0x6e) + valorRegistro(0x6e)) + valorRegistro(0x71));

EF          				IncParam2();

FD 							while (param2 > 0){
  	     						// save the initial position
FC								pushTilePos();

F9 61 							pintaTile(61, decrementaTilePosY);

FE 								while (param1 > 0){

F9 62 80 64							pintaTile(62, decrementaTilePosYyDibujaUnoMas, 64);

									(param1--;)
FA 								}

F9 63 							pintaTile(63, decrementaTilePosY);

FB 								popTilePos();
F5 								incTilePosX();
F4 								decTilePosY();

								(param2--;)
FA 							}
FF

19C6:
E9 				FlipX();
EA 19AD			ChangePC(0x19ad)

19CA:
F7 6E 6E 6D		actualizaRegistro(0x6e, valorRegistro(0x6e) + valorRegistro(0x6d));
F7 6D 01		actualizaRegistro(0x6d, 01);
EA 1975			ChangePC(0x1975)

19D4:
E9				FlipX();
EA 19CA			ChangePC(0x19ca)

; draws the screen that is in the tiles buffer
19D8: 3A 6C 15    ld   a,($156C)	; read if it's an illuminated room or not
19DB: A7          and  a
19DC: 28 02       jr   z,$19E0		; if it's illuminated, jump
19DE: 3E FF       ld   a,$FF		; background color = black
19E0: CD 70 1A    call $1A70		; clear the grid and fill a 256x160 rectangle starting at (32, 0) with color a
19E3: DD 2A 6A 15 ld   ix,($156A)	; ix = address of the current screen data
19E7: DD 23       inc  ix			; advance the length byte
19E9: 21 67 16    ld   hl,$1667		; modify a jump in a routine
19EC: 22 5E 16    ld   ($165E),hl
19EF: 01 C7 7F    ld   bc,$7FC7		; load abadia8
19F2: ED 49       out  (c),c
19F4: CD 0A 1A    call $1A0A		; generate the scenery with abadia8 data and project it to the grid
19F7: 01 C0 7F    ld   bc,$7FC0		; load abadia0
19FA: ED 49       out  (c),c
19FC: 21 60 16    ld   hl,$1660		; modify a jump in a routine
19FF: 22 5E 16    ld   ($165E),hl
1A02: 3A 6C 15    ld   a,($156C)	; read if it's an illuminated room or not
1A05: A7          and  a
1A06: CA B2 4E    jp   z,$4EB2		; if it's an illuminated room, draw the grid contents to screen from center outwards
1A09: C9          ret

; generate the scenery from abadia8 data and project it
; read the abadia8 entry with a screen construction block and call 0x1bbc
1A0A: DD 7E 00    ld   a,(ix+$00)	; read a byte
1A0D: FE FF       cp   $FF			; 0xff indicates end of screen
1A0F: C8          ret  z
1A10: E6 FE       and  $FE			; discard the lower bit for indexing
1A12: 21 6D 15    ld   hl,$156D		; point to the block types table
1A15: 85          add  a,l			; hl = hl + a
1A16: 6F          ld   l,a
1A17: 8C          adc  a,h
1A18: 95          sub  l
1A19: 67          ld   h,a
1A1A: 5E          ld   e,(hl)		; de = pointer to the block characteristics
1A1B: 23          inc  hl
1A1C: 56          ld   d,(hl)
1A1D: ED 53 62 1A ld   ($1A62),de	; modify an instruction
1A21: DD 7E 01    ld   a,(ix+$01)	; read byte 1
1A24: 4F          ld   c,a
1A25: E6 1F       and  $1F
1A27: 6F          ld   l,a			; l = x position of the element (tiles buffer coordinate system)
1A28: 79          ld   a,c
1A29: 07          rlca
1A2A: 07          rlca
1A2B: 07          rlca
1A2C: E6 07       and  $07
1A2E: 4F          ld   c,a			; c = x length of the element
1A2F: DD 7E 02    ld   a,(ix+$02)	; read byte 2
1A32: 47          ld   b,a
1A33: E6 1F       and  $1F
1A35: 67          ld   h,a			; h = y position of the element (tiles buffer coordinate system)
1A36: 78          ld   a,b
1A37: 07          rlca
1A38: 07          rlca
1A39: 07          rlca
1A3A: E6 07       and  $07
1A3C: 47          ld   b,a			; b = y length of the element

1A3D: 11 00 00    ld   de,$0000
1A40: ED 53 DE 1F ld   ($1FDE),de	; initialize to (0, 0) the block position in the grid (local grid coordinate system)
1A44: DD 7E 00    ld   a,(ix+$00)	; read the first byte
1A47: DD 23       inc  ix
1A49: DD 23       inc  ix
1A4B: DD 23       inc  ix			; advance to the next entry
1A4D: E6 01       and  $01			; keep bit 0
1A4F: 3E FF       ld   a,$FF
1A51: 28 05       jr   z,$1A58		; if it's 0, the entry is 3 bytes
1A53: DD 7E 00    ld   a,(ix+$00)	; otherwise it's 4 bytes
1A56: DD 23       inc  ix
1A58: 32 DD 1F    ld   ($1FDD),a	; store 0xff or byte 4 to ???

1A5B: E5          push hl
1A5C: 21 0A 1A    ld   hl,$1A0A
1A5F: E3          ex   (sp),hl		; push the address of this routine as return address
1A60: E5          push hl
1A61: 21 00 00    ld   hl,$0000		; instruction modified from outside with the address of the block construction data
1A64: 5E          ld   e,(hl)
1A65: 23          inc  hl
1A66: 56          ld   d,(hl)
1A67: 23          inc  hl			; de = pointer from material to tiles that form the block
1A68: E3          ex   (sp),hl		; save on stack a pointer to the rest of material characteristics
1A69: C3 BC 1B    jp   $1BBC		; initialize the buffer with current block data and evaluate block construction parameters

; hide the game area
1A6C: 3E FF       ld   a,$FF
1A6E: 18 0D       jr   $1A7D

; clear 0x8d80-0x94ff and fill a rectangle 160 high by 256 wide starting at position (32, 0) with a
1A70: 21 80 8D    ld   hl,$8D80		; point to free memory
1A73: 11 81 8D    ld   de,$8D81
1A76: 36 00       ld   (hl),$00
1A78: 01 7F 07    ld   bc,$077F
1A7B: ED B0       ldir				; clear 0x8d80-0x94ff

; fill a rectangle 160 high by 256 wide starting at position (32, 0) with a
1A7D: 06 A0       ld   b,$A0		; b = 160
1A7F: 32 8B 1A    ld   ($1A8B),a	; modify the value to fill with
1A82: 21 08 C0    ld   hl,$C008		; position (32, 0)
1A85: C5          push bc
1A86: E5          push hl
1A87: 54          ld   d,h			; de = hl
1A88: 5D          ld   e,l
1A89: 13          inc  de
1A8A: 36 00       ld   (hl),$00		; this instruction is modified from outside
1A8C: 01 3F 00    ld   bc,$003F
1A8F: ED B0       ldir				; fill 64 bytes (256 pixels)
1A91: E1          pop  hl
1A92: CD 4D 3A    call $3A4D		; advance to the next line
1A95: C1          pop  bc
1A96: 10 ED       djnz $1A85		; repeat until complete
1A98: C9          ret

; characteristics of material 0x2d
1A99: 1706			; pointer to the tiles that form the block
1A9B:
F7 71 02 6E 6E 84 71
F7 70 01 84 70
FC
FC
F8 69
FE
F8 6A
FA
FB
F4
FC
F8 61
FE
F8 62
FA
F8 63
FB
F4
FD
FC
F8 66
FE
F8 64
FA
F8 65 80 63
FB
F4
F5
FA
F8 66
FE
F8 67
FA
F8 68
FB
F7 6E 00
FE
F5
F6
FC
F9 69
FD
F9 6A
FA
F7 6E 01 6E
FB
FA
FF

; characteristics of material 0x2c
1AE9: 	16FC		; pointer to the tiles that form the block
		E9			FlipX();
		EA 1A9B 	ChangePC(0x1a9b)

; characteristics of material 0x0b
1AEF: 	16EA 			; pointer to the tiles that form the block

// draws the stairs
1AF1:
						// depth x in the grid =  depth x in the grid - (param1*2 + 2);
F7 70 02 6D 6D 84 70	actualizaRegistro(0x70, -(02 + valorRegistro(0x6d) + valorRegistro(0x6d)) + valorRegistro(0x70));

						// depth y in the grid =  depth y in the grid- (param2*2 + 1);
F7 71 01 6E 6E 84 71	actualizaRegistro(0x71, -(01 + valorRegistro(0x6e) + valorRegistro(0x6e)) + valorRegistro(0x71));

EF						IncParam2();

FD						while (param2 > 0){
FC							pushTilePos();
FC							pushTilePos();

F9 61 80 65					pintaTile(61, decrementaTilePosYyDibujaUnoMas, 65);

FB 							popTilePos();
F3 							decTilePosX();

FE 							while (param1 > 0){
FC								pushTilePos();
F9 62 80 66 80 67				pintaTile(62, decrementaTilePosYyDibujaUnoMas, 66, decrementaTilePosYyDibujaUnoMas, 67);
FB 								popTilePos();

F4 								decTilePosY();
F3 								decTilePosX();

								(param1--;)
FA							}

F9 63 80 68 80 69			pintaTile(63, decrementaTilePosYyDibujaUnoMas, 68, decrementaTilePosYyDibujaUnoMas, 69);
FB 							popTilePos();
F4 							decTilePosY();
F4 							decTilePosY();
F5 							incTilePosX();

							(param2--;)
FA 						}
F3 						decTilePosX();

F0						IncParam1();

FE 						while (param1 > 0){
F9 64						pintaTile(64, decrementaTilePosY);
F3          				decTilePosX();

							(param1--;)
FA						}
FF

; characteristics of material 0x0c
1B28: 	16F3		; pointer to the tiles that form the block
		E9			FlipX();
		EA F1		ChangePc(0x1af1)

1B2E: 	EB EB EB					; skeleton remains???

; data for the generation of materials
1B31: 08 76 75 28 29 2B 2D 0A 09 	; solid block of thin brick parallel to the x axis
1B3A: 08 75 76 2B 2D 28 29 09 0A	; solid block of thin brick parallel to the y axis
1B43: 04 04 04						; floor of thick blue tiles
1B46: 01 4E 4D    					; floor of red and blue tiles forming a checkerboard effect
; floor of blue tiles (the following 3 bytes)
1B49: 05 4F 59 28 29 2B 2D 0A 09 	; solid block of thin red and black brick, with blue tiles on top, parallel to the y axis
1B52: 05 59 4F 2B 2D 28 29 09 0A	; solid block of thin red and black brick, with blue tiles on top, parallel to the x axis
; floor of yellow tiles (the following 3 bytes)
1B5B: 87 88 CF 28 29 2B 2D 0A 09	; solid block of thin red and black brick, with yellow and black tiles on top, parallel to the x axis
1B64: 87 CF 88 2B 2D 28 29 09 0A	; solid block of thin red and black brick, with yellow and black tiles on top, parallel to the y axis
1B6D: FF 45 44 28 29 2B 2D 0A 09	; solid block of thin red and black brick, with blue top, parallel to the y axis (also flat corner delimited with black line and with blue floor)
1B76: FF 44 45 2B 2D 28 29 09 0A	; solid block of thin red and black brick, with blue top, parallel to the x axis
1B7F: DB DA D4 D7 DD D8 DC D9 E2	; white table parallel to the y axis
1B88: DB D4 DA D8 DC D7 DD E2 D9    ; white table parallel to the x axis	(also the work table)

; characteristics of material 0x58
1B91: 1B2E			; pointer to the tiles that form the block
		EA 1BCF		ChangePc(0x1bcf)

; characteristics of material 0x49
1B96: 1B6D			; pointer to the tiles that form the block
EA 1BCF				ChangePc(0x1bcf)

; characteristics of material 0x1c
1B9B: 	1B31		; pointer to the tiles that form the block
		EA 1BCF		; ChangePC(0x1bcf);

; characteristics of material 0x0d
1BA0: 	1B43		; pointer to the tiles that form the block
		EA 1BCF		; ChangePC(0x1bcf);

; characteristics of material 0x0e
1BA5: 	1B46		; pointer to the tiles that form the block
		EA 1BCF		; ChangePC(0x1bcf);

; characteristics of material 0x0f
1BAA: 	1B49		; pointer to the tiles that form the block
		EA 1BCF		; ChangePC(0x1bcf);

; characteristics of material 0x10
1BAF: 	1B5B		; pointer to the tiles that form the block
		EA 1BCF		; ChangePC(0x1bcf);

; characteristics of material 0x4e
1BB4: 	1B88		; pointer to the tiles that form the block
		EA 1BCF		; ChangePC(0x1bcf);

; initiates the evaluation of the current block, but without modifying the tiles that form the block
1BB9: C5          push bc
1BBA: 18 0C       jr   $1BC8

; initiates the buffer for the construction of the current block and evaluates the construction parameters of the block
; a = 0xff if the entry is 3 bytes or the height otherwise
; h = initial position of the block in y (tile buffer coordinate system)
; l = initial position of the block in x (tile buffer coordinate system)
; b = length of the element in y
; c = length of the element in x
; de = pointer to the tiles that form the block
; sp = pointer to the construction data of the block
1BBC: C5          push bc		; preserves the read parameters
1BBD: E5          push hl
1BBE: EB          ex   de,hl	; hl = pointer to the tiles that form the block
1BBF: 11 CF 1F    ld   de,$1FCF	; de = destination buffer
1BC2: 01 0C 00    ld   bc,$000C
1BC5: ED B0       ldir			; copies the data of the tiles that form the block
1BC7: E1          pop  hl
1BC8: CD B8 1F    call $1FB8	; if the entry is 4 bytes, transforms the block position to grid coordinates
1BCB: C1          pop  bc
1BCC: C3 18 20    jp   $2018	; jumps to the block generator

// draws a type of floor
1BCF:

F7 70 02 6E 6E 84 70 	UpdateReg(0x70, -(2 + 2*Param2) + reg(0x70));
F7 71 03 6D 6D 84 71  	UpdateReg(0x71, -(3 + 2*Param1) + reg(0x71));

 						// at minimum paint tiles of 1x1
E0 						IncParam1();
EF 						IncParam2();

						// parameter 2 indicates the number of rows to paint
FD 						while (param2 > 0){
							// saves the initial position
FC 							PushTilePos();

							// parameter 1 indicates the number of columns to paint
FE 							while (param1 > 0){
								// paint 2 rows with X-shaped tile
F9 61 80 61 					DrawTileDecY(0x61, 0x80, 0x61);
F5 								IncTilePosX();
F6								IncTilePosY();

FA 			 				(param1--;)
							}

							// draws a border next to the last painted column
F9 61 80 62					DrawTileDecY(0x61, 0x80, 0x62);

							// updates the position to draw the next block
FB							PopTilePos();
F4							DecTilePosY();
F3							DecTilePosX();

FA							(param2--;)
						}
F5 						IncTilePosX();
F4 						DecTilePosY();

						// draws the other border next to the first painted column
FE 						while (param1 > 0){
F9 63 						DrawTileDecY(0x63);
F5							IncTilePosX();

FA		 					(param1--;)
						}
FF

; data for the generation of materials
1BF9: D8 95 94 EA D0 DC DB 96 D7 DD DA		; bed
1C04: A7 A5 A3 A1 9F 9D A6 A4 A2 A0 9E 00	; large blue and yellow windows parallel to the y axis
1C10: 93 91 8F 8D 8B 89 92 90 8E 8C 8A 00	; large blue and yellow windows parallel to the x axis
1C1C: 5F CB CD CA 46 						; candelabra with 2 candles parallel to the x axis
1C21: 5F CB CD CA 46 						; candelabra with 2 candles parallel to the x axis (2)
1C26: 5F CE CD CC 60						; candelabra with 2 candles parallel to the y axis
1C2B: 6D CE CD CC 60						; candelabra with wall support and with 2 candles parallel to the y axis
1C30: D6 D5 AB								; yellow rivet with support parallel to the y axis
1C33: D2 D1 A8  							; yellow rivet with support parallel to the x axis
1C36: 28 09 6E 6F 72 71 70 2B 0A 			; rounded hole to pass through with thin red and black bricks parallel to the x axis
1C3F: 2B 0A 5A 5B 5E 5D 5C 28 09 			; rounded hole to pass through with thin red and black bricks parallel to the y axis
1C48: C4 C3 C2 C0 C1 BF 9B BC BD BE			; block of arches that pass through pairs of columns parallel to the y axis
1C52: F6 F5 F4 F2 F3 F1 9B EE EF F0			; block of arches that pass through pairs of columns parallel to the X axis
1C5C: E3 									; plate
1C5D: 9C 									; skull
1C5E: 0D 0C 0B 								; cauldron
1C61: 31 0F 0E								; bottles with handle
1C64: 67 48 76 08 75 66 68 65 3B 64			; bench to sit on parallel to the y axis
1C6E: 41 47 75 08 76 40 38 20 42 1F			; bench to sit on parallel to the x axis
1C78: AA AB AB AA							; double yellow rivet on the brick parallel to the y axis
1C7C: A9 A8 A8 A9							; double yellow rivet on the brick parallel to the x axis
1C80: 3F 3E 3D 3C 3A 39 					; bookshelves parallel to the y axis

; characteristics of material 0x33
1C86: 1C30			; pointer to the tiles that form the block

EC 1CA6		Call(0x1ca6);
F7 6E 6D
F7 6D 01
F3
EC 1EE3		Call(0x1ee3);
FF

; characteristics of material 0x34
1C96: 1C78        ; pointer to the tiles that form the block
EC 1CAF
F7
6E
6D
F7
6D
00
F3
EC 64 1F
FF

; characteristics of auxiliary material called from material 0x33
1CA6: 1C30			; pointer to the tiles that form the block
F7
6D
01 EC DE
1E FF

; characteristics of auxiliary material called from material 0x34
1CAF: 1C78			; pointer to the tiles that form the block
F7
6D
00
EC 5F 1F
FF

; characteristics of material 0x11
1CB8: 	1C48	; pointer to the tiles that form the block

1CBA:
F7 70 01 70		actualizaRegistro(0x70, 1 + valorRegistro(0x70));
F7 71 01 71     actualizaRegistro(0x70, 1 + valorRegistro(0x71));

F0				IncParam1();

FE 				while (param1 > 0){
F7 71 08 84 71		actualizaRegistro(0x71, -8 + valorRegistro(0x71));
F9 67 80 82 FB 80 82 C8 80 82 C5 80 82 C6 80 82 C7	pintaTile(67, decrementaTilePosYyDibujaUnoMas, FB, decrementaTilePosYyDibujaUnoMas, C8, decrementaTilePosYyDibujaUnoMas, C5, decrementaTilePosYyDibujaUnoMas, C6, decrementaTilePosYyDibujaUnoMas, C7);

1CDA:
F5					IncTilePosX();
F6 					IncTilePosY();
F6					IncTilePosY();
F6 					IncTilePosY();
F9 61 80 62 80 63 80 64	pintaTile(61, decrementaTilePosYyDibujaUnoMas, 62, decrementaTilePosYyDibujaUnoMas, 63, decrementaTilePosYyDibujaUnoMas, 64);
F5					IncTilePosX();
F6 					IncTilePosY();
F6					IncTilePosY();
F9 65 80 66			pintaTile(65, decrementaTilePosYyDibujaUnoMas, 66);
F5					IncTilePosX();
F2 04 				UpdateTilePosY(4);
F9 67 80 68 80 69 80 6A pintaTile(67, decrementaTilePosYyDibujaUnoMas, 68, decrementaTilePosYyDibujaUnoMas, 69, decrementaTilePosYyDibujaUnoMas, 6a);
F5					IncTilePosX();
F2 03 				UpdateTilePosY(3);

					(param1--;)
FA				}
FF

; characteristics of material 0x12
1CFD: 	1C52		; pointer to the tiles that form the block
		E9			; FlipX();
F7 70 01 70 		actualizaRegistro(0x70, 1 + valorRegistro(0x70));
F7 71 01 71 		actualizaRegistro(0x71, 1 + valorRegistro(0x71));

F0 					IncParam1();

FE 					while (param1 > 0){
F7 71 08 84 71			actualizaRegistro(0x71, -8 + valorRegistro(0x71));
F9 67 80 82 FB 80 82 F7 80 82 F8 80 82 F9 80 82 FA pintaTile(67, decrementaTilePosYyDibujaUnoMas, FB, decrementaTilePosYyDibujaUnoMas, F7, decrementaTilePosYyDibujaUnoMas, F8, decrementaTilePosYyDibujaUnoMas, F9, decrementaTilePosYyDibujaUnoMas, FA);

EA 1CDA					ChangePC(0x1cda);

; characteristics of material 0x13
1D23: 	1C48		; pointer to the tiles that form the block

1D25:
FC				pushTilePos();

F2 05 84		updateTilePosY(-5);
F7 6F 0A 6F		actualizaRegistro(0x6f, 0x0a + valorRegistro(0x6f));
EC 1CB8			call(0x1cb8);

1D30:
F7 6F 0A 84 6F	actualizaRegistro(0x6f, -0x0a + valorRegistro(0x6f));

FB				popTilePos();
F0				IncParam1();

FE 				while (param1 > 0){
EC 1D59				call(0x1d59)
F4 					decTilePosY();
F4 					decTilePosY();
F4 					decTilePosY();
F5 					incTilePosX();
F5 					incTilePosX();
F5 					incTilePosX();
EC 1D59				call(0x1d59)
F4 					decTilePosY();
F5 					incTilePosX();

					(param1--;)
FA				}
FF

; characteristics of material 0x14
1D48: 	1C52		; pointer to the tiles that form the block

1D4A:
FC 				pushTilePos();
F2 05 84		updateTilePosY(-5);
F7 6F 0A 6F		actualizaRegistro(0x6f, 0A + valorRegistro(0x6f));
EC 1CFD			call(0x1cfd);
E9				FlipX();
EA 1D30			ChangePC(0x1d30);

1D59: 16CA			; pointer to the tiles that form the block

1D61:
F7 71 01 84 71					actualizaRegistro(0x71, -01 + valorRegistro(0x71));
F9 61 80 62 80 62 80 62 80 63	pintaTile(61, decrementaTilePosYyDibujaUnoMas, 62, decrementaTilePosYyDibujaUnoMas, 62, decrementaTilePosYyDibujaUnoMas, 62, decrementaTilePosYyDibujaUnoMas, 63);
FF

; characteristics of material 0x46
1D6B: 1C64          ; pointer to the tiles that form the block
F6
F5
FC
F9 61 80 62 80 63
FB
F3
F6
FE
FC
F9 61 80 62 80 64 80 65
FB
F3
F6
FA
FC
F9 66 80 67 80 64 80 65
FB
F3
F9 6A 80 68 80 69
FF

; characteristics of material 0x45
1D99: 1C6E			; pointer to the tiles that form the block
	E9          	FlipX();
	EA 1D6D			ChangePc(0x1d6d);

; characteristics of material 0x4a
1D9F: 16DE			; pointer to the tiles that form the block
E9
F6
F5
FC
F9 61 80 62 80 63 80 64
FB
F3
F6
FE
FC
F9 61 80 62 80 82 43 80 66 80 67
FB
F3
F6
FA
FC
F9 68 80 69 80 82 18 80 66 80 67
FB
F3
F9 6A 80 6B 80 6C 80 65
FF

; characteristics of material 0x4b
1DD8: 1C5C			; pointer to the tiles that form the block
1DDA: EA 1DDF		ChangePC(0x1ddf);

; characteristics of material 0x57
1DDD: 1C5D			; pointer to the tiles that form the block
1DDF:
FC 					pushTilePos();
F5 					IncTilePosX();
F4     		 		IncTilePosY();
E4 1DEF 			CallPreserve(0x1def);
FB         			popTilePos();
E9					FlipX();
F7 6D 6E 01			actualizaRegistro(0x6d, valorRegistro(0x6e) + 01);
E4 1DEF				CallPreserve(0x1def);
FF

; characteristics of auxiliary material called from material 0x57
1DEF: 1C5C			; pointer to the tiles that form the block
FE
F9 61
F7 71 02 84 71
F5
FA
FF

; characteristics of material 0x4c
1DFC: 1C61			; pointer to the tiles that form the block
1DFE: EA 1975     	ChangePc(0x1975);

; characteristics of material 0x5b
1E01: 1695			; pointer to the tiles that form the block
	EA 1E08			ChangePc(0x1e08);

; characteristics of material 0x4d
1E06: 1C5E			; pointer to the tiles that form the block
1E08:
F9 61 80 62 80 63
FF

; characteristics of material 0x1d
1E0F: 	1C80	; pointer to the tiles that form the block
1E01:
E9
F0
EF
FC
F9 61
FE
F9 62 80 63 80 61
FA
FB
F6
F5
FD
FC
F9 64
FE
F9 65 80 66 80 64
FA
FB
F6
F5
FA
FF

; characteristics of material 0x1e
1E33: 	1BF9	; pointer to the tiles that form the block
F7 71 04 84 71
F7 70 01 84 70
FC
F9 69 80 6A 80 6B
FB
F5
FC
F9 61 80 66 80 67 80 68
FB
F5
F4
F9 61 80 62 80 63 80 64 80 65
FF

; characteristics of material 0x1f
1E5F: 1C04		; pointer to the tiles that form the block
1E61:
F7 70 01 84 70
F7 71 03 6D 6D 6D 6D 84 71
F0
EF
FD
FC
FE
FC
F9 61 80 62 80 62 80 63 80 64 80 65 80 66
FB
F5
F4
FC
F9 67 80 68 80 68 80 69 80 6A 80 6B
FB
F5
F4
FA
FB
F2 07 84
FA
FF

; characteristics of material 0x20
1E9D: 1C10		; pointer to the tiles that form the block
	  E9		FlipX();
	  EA 1E61	ChangePC(0x1e61);

; characteristics of material 0x2c
1EA3: 1C26		; pointer to the tiles that form the block
1EA5:
F7 71 01 6D 6D 84 71
F0
EF
FD
FC
FE
FC
F9 61 80 62 80 63 80 64 80 65
FB
F5
F4
FA
FB
F2 05 84
FA
FF

; characteristics of material 0x3b
1EC6: 	1C21		; pointer to the tiles that form the block
1EC8: 	E9          FlipX();
		EA 1EA5		ChangePc(0x1ea5);

; characteristics of material 0x21
1ECC: 	1C1C 		; pointer to the tiles that form the block
		EA 1EC8		ChangePc(0x1ec8);

; characteristics of material 0x3d
1ED1: 	1C2B   		; pointer to the tiles that form the block
		EA 1EA5		ChangePc(0x1ea5);

; characteristics of material 0x22
1ED6: 	1C2B		; pointer to the tiles that form the block
FF

; characteristics of material 0x5d
1ED9: 	169C    	; pointer to the tiles that form the block
		EA 1975		ChangePc(0x1975);

; characteristics of material 0x23
1EDE: 	1C30		; pointer to the tiles that form the block
		EA 1975		ChangePc(0x1975);

; characteristics of material 0x25
1EE3: 	1C33		; pointer to the tiles that form the block
1EE5: 	EA 198C		ChangePc(0x198c);

; characteristics of material 0x32
1EE8: 	1C3F		; pointer to the tiles that form the block
1EEA:
F7 71 01 71
F0
F7 70 01 70
FE
FC
F5
F4
F4
E4 1F20			CallPreserve(0x1f20);
FB
F7 71 04 84 71
F9 65 80 66 80 66 80 66 80 66 80 67 80 64
F5
F6
F9 63 80 69
F5
F2 06
FA
FF

; characteristics of material 0x27
1F1A: 	1C36		; pointer to the tiles that form the block
1F1C:
		E9			FlipX();
		EA 1EEA		ChangePc(0x1eea);

; characteristics of auxiliary material called from material 0x32
1F20: 1C3F          ; pointer to the tiles that form the block
F7
6D
04
F7
6E
00
EA 8C 19

; characteristics of material 0x43
1F2B: 1C3F			; pointer to the tiles that form the block
F7 6E 6D 01
F7 71 01 71
F7 70 02 84 70
FD
F7 6D 00
E4 1EE8		CallPreserve(0x1ee8);
F5
F5
F4
F4
FC
F7 71 06 84 71
F7 6D 06
F9 68
FE
F9 69
FA
FB
F5
F4
FA
FF

; characteristics of material 0x44
1F59: 1C36			; pointer to the tiles that form the block
1F5B: E9        	FlipX();
1F5C: EA 1F2D		ChangePC(0x1f2d);

; characteristics of material 0x15
1F5F: 	1C78		; pointer to the tiles that form the block
	EA 19AD		; ChangePC(0x19ad)

; characteristics of material 0x16
1F64: 	1C7C		; pointer to the tiles that form the block
	EA 19C6		; ChangePC(0x19c6)

; characteristics of material 0x5c
1F69: 169F			; pointer to the tiles that form the block
	EA 19C6		; ChangePC(0x19c6)

1F6E: 2B 0A 49 4A		; thin red brick forming a right triangle parallel to the x axis
1F72: 28 09 4C 4B		; pyramid of thin red and black brick (and thin red brick forming a right triangle parallel to the y axis)

; characteristics of material 0x37
1F76: 1F72			; pointer to the tiles that form the block
EC 1F86   	Call(0x1f86)
F3
EC 1F80 	Call(0x1f80)
FF

; characteristics of material 0x41
1F80: 1F6E			; pointer to the tiles that form the block
	E9 	FlipX();
	EA 1F88

; characteristics of material 0x42
1F86: 1F72
1F88:
F7 6D 6E 6D
F7 6E 6D 01
F7 71 01 6D 6D 84 71
F7 70 02 6D 6D 84 70
FD
FC
F9 61
FE
F9 62 80 62 80 62
FA
F9 63 80 64
F7 6D 01 84 6D
FB
F5
F4
FA
FF

	// param1 = param 1 + param2
	actualizaRegistro(0x6d, valorRegistro(0x6e) + valorRegistro(0x6d));

	// param2 = param 1 + 1
	actualizaRegistro(0x6e, valorRegistro(0x6d) + 1);

	// pos y en el grid = pos y en el grid - (2*param1 + 1)
	actualizaRegistro(0x71, -(1 + 2*valorRegistro(0x6d)) + reg(0x71));

	// pos x en el grid = pos x en el grid - (2*param1 + 2)
	actualizaRegistro(0x70, -(2 + 2*valorRegistro(0x6d)) + reg(0x70));

	while (param2 > 0){
		PushTilePos();
		DrawTileDecY(0x61);
		while (param1 > 0){
			DrawTileDecY(0x62, 0x80, 0x62, 0x80, 0x62);
			(param1--;)
		}
		DrawTileDecY(0x63, 0x80, 0x64);
		UpdateReg(0x6d, -1 + Param1);
		PopTilepos();
		IncTilePosX();
		DecTilePosY();
		(param2--;)
	}

; if the entry is 4 bytes, transforms the block position to grid coordinates
; the coordinate system change equations are:
; tile map -> grid
; Xgrid = Ymap + Xmap - 15
; Ygrid = Ymap - Xmap + 16
; grid -> tile map
; Xmap = Xgrid - Ymap + 15
; Ymap = Ygrid + Xmap - 16
; this way the grid data is stored in the tile map so that conversion to screen is direct
; parameters:
; a = 0xff if the entry is 3 bytes or byte 3 otherwise
; h = block position in y (tile buffer coordinate system)
; l = block position in x (tile buffer coordinate system)
1FB8: FE FF       cp   $FF			; if the entry is 3 bytes, exit
1FBA: C8          ret  z
1FBB: CB 3F       srl  a			; a = a*2
1FBD: 84          add  a,h
1FBE: 57          ld   d,a			; d = h + a*2
1FBF: 85          add  a,l
1FC0: D6 0F       sub  $0F
1FC2: 5F          ld   e,a			; e = h + l + a*2 - 15
1FC3: 3E 10       ld   a,$10
1FC5: 82          add  a,d			; a = h + a*2 + 16
1FC6: 95          sub  l
1FC7: 57          ld   d,a			; d = h - l + a*2 + 16
1FC8: ED 53 DE 1F ld   ($1FDE),de	; save the new coordinates
1FCC: C9          ret

; variables used for block generation
1FCD-1FDF: 00

; table of routines related to block construction
1FE0: 	2032 -> 0x00 (0xff) retrieves the address of the next block to process and if coordinates x were changed (x = -x), undo the change
	2091 -> 0x01 (0xfe) saves on the stack the block length in y and the current position of the block construction data
	209E -> 0x02 (0xfd) saves on the stack the block length in x and the current position of the block construction data
	20CF -> 0x03 (0xfc)	saves on the stack the current position in the tile buffer
	20D3 -> 0x04 (0xfb)	retrieves from the stack the position stored in the tile buffer
	20D7 -> 0x05 (0xfa) retrieves the block length, decrements it and if not zero, returns to the address saved from the block
	20E7 -> 0x06 (0xf9) paints the tile indicated by hl with the next byte read and changes the position of hl (y--)
	20F5 -> 0x07 (0xf8) paints the tile indicated by hl with the next byte read and changes the position of hl (x++)
	2141 -> 0x08 (0xf7) modifies a position in the block construction buffer with a calculated expression
	204F -> 0x09 (0xf6) changes the position of hl (y++)
	2052 -> 0x0a (0xf5) changes the position of hl (x++)
	2055 -> 0x0b (0xf4) changes the position of hl (y--)
	2058 -> 0x0c (0xf3) changes the position of hl (x--)
	205B -> 0x0d (0xf2) modifies the position in y with the expression read
	2066 -> 0x0e (0xf1) modifies the position in x with the expression read
	2077 -> 0x0f (0xf0) increments the block length in y in the block construction buffer
	2071 -> 0x10 (0xef)	increments the block length in x in the block construction buffer
	2083 -> 0x11 (0xee) decrements the block length in y in the block construction buffer
	207D -> 0x12 (0xed) decrements the block length in x in the block construction buffer
	21B4 -> 0x13 (0xec) interprets another block modifying the values of the tiles to use
	20EE -> 0x14 (0xeb) paints the tile indicated by hl with the next byte read and changes the position of hl (x--)
	21A1 -> 0x15 (0xea)	changes the pointer to the block construction data with the first address read in the data
	218D -> 0x16 (0xe9) changes the instructions that update the x coordinate of the tiles (incx -> decx)
	218D -> 0x17 (0xe8) changes the instructions that update the x coordinate of the tiles (incx -> decx)
	218D -> 0x18 (0xe7) changes the instructions that update the x coordinate of the tiles (incx -> decx)
	218D -> 0x19 (0xe6) changes the instructions that update the x coordinate of the tiles (incx -> decx)
	218D -> 0x1a (0xe5) changes the instructions that update the x coordinate of the tiles (incx -> decx)
	21AA -> 0x1b (0xe4) interprets another block without modifying the values of the tiles to use, and changing the direction of x

; initiates the interpretation process of block construction bytes
; sp = pointer to the block construction data
2018: DD E3       ex   (sp),ix		; gets the pointer to the block construction data
201A: ED 43 DB 1F ld   ($1FDB),bc

; evaluates the block construction data
; h = initial block position in y (tile buffer coordinate system)
; l = initial block position in x (tile buffer coordinate system)
; b = element length in y
; c = element length in x
; ix = pointer to the block construction data
201E: DD 7E 00    ld   a,(ix+$00)	; reads the first byte and extracts the routine number to use
2021: DD 23       inc  ix
2023: 2F          cpl				; commands are stored complemented since parser routines interpret
2024: 87          add  a,a			;  values < 0x60 as immediate numbers that form part of expressions
2025: E5          push hl
2026: 21 E0 1F    ld   hl,$1FE0		; points to a routine table
2029: CD 2D 16    call $162D		; hl = hl + a
202C: 5E          ld   e,(hl)
202D: 23          inc  hl
202E: 56          ld   d,(hl)		; de = [hl]
202F: E1          pop  hl
2030: D5          push de			; puts on the stack the routine to jump to
2031: C9          ret				; jumps to the corresponding routine

; retrieves the address of the next block to process and if coordinates x were changed (x = -x), undo the change
2032: DD E1       pop  ix			; retrieves the address of the next block to process
2034: 3A CE 1F    ld   a,($1FCE)	; reads if the operations working with x coordinates in tiles were changed (from incx to decx)
2037: A7          and  a
2038: 3E 00       ld   a,$00
203A: 32 CE 1F    ld   ($1FCE),a	; clears the state
203D: C0          ret  nz			; if coordinates were changed, exit

; if they were not changed, restore the state of operations
203E: 3E 2C       ld   a,$2C
2040: 32 52 20    ld   ($2052),a	; updates the posx++ and posx-- instructions for tile position
2043: 32 F8 20    ld   ($20F8),a
2046: 3C          inc  a
2047: 32 58 20    ld   ($2058),a
204A: AF          xor  a
204B: 32 30 22    ld   ($2230),a
204E: C9          ret

; changes the position of hl (y++)
204F: 24          inc  h
2050: 18 CC       jr   $201E

; changes the position of hl (x++)
2052: 2C          inc  l
2053: 18 C9       jr   $201E

; changes the position of hl (y--)
2055: 25          dec  h
2056: 18 C6       jr   $201E

; changes the position of hl (x--)
2058: 2D          dec  l
2059: 18 C3       jr   $201E

205B: CD 14 22    call $2214	; reads an immediate value or a register
205E: CD 66 21    call $2166	; modifies c with an expression
2061: 7C          ld   a,h		; modifies the position in y with the expression read
2062: 81          add  a,c
2063: 67          ld   h,a
2064: 18 B8       jr   $201E

2066: CD 14 22    call $2214	; reads an immediate value or a register
2069: CD 66 21    call $2166	; modifies c with an expression
206C: 7D          ld   a,l		; modifies the position in x with the expression read
206D: 81          add  a,c
206E: 6F          ld   l,a
206F: 18 AD       jr   $201E

; increments the block length in x
2071: 0E 01       ld   c,$01
2073: 3E 6E       ld   a,$6E	; block length in x entry
2075: 18 10       jr   $2087	; block length in x = block length in x + 1

; increments the block length in y
2077: 3E 6D       ld   a,$6D	; block length in y entry
2079: 0E 01       ld   c,$01
207B: 18 0A       jr   $2087	; block length in y = block length in y + 1

; decrements the block length in x
207D: 3E 6E       ld   a,$6E	; block length in x entry
207F: 0E FF       ld   c,$FF
2081: 18 04       jr   $2087	; block length in x = block length in x - 1

; decrements the block length in y
2083: 3E 6D       ld   a,$6D	; block length in y entry
2085: 0E FF       ld   c,$FF

; modifies the value at position a of the block construction buffer, adding c to it
2087: C5          push bc
2088: CD 19 22    call $2219		; gets the value at position a of the block construction buffer
208B: 79          ld   a,c
208C: C1          pop  bc
208D: 81          add  a,c			; adds the value passed as parameter
208E: 12          ld   (de),a		; updates the material characteristics
208F: 18 8D       jr   $201E

2091: 3E 6D       ld   a,$6D
2093: CD 19 22    call $2219		; gets the block length in y
2096: 28 0D       jr   z,$20A5		; if it's != 0, continue processing the material, otherwise skip symbols until construction data ends

2098: DD E5       push ix
209A: C5          push bc
209B: C3 1E 20    jp   $201E		; continue processing the block

; saves on the stack the block length in x and the current position of the block construction data
209E: 3E 6E       ld   a,$6E
20A0: CD 19 22    call $2219		; gets the block length in x
20A3: 20 F3       jr   nz,$2098		; if it's != 0, continue processing the material, otherwise skip symbols until construction data ends

; if the loop doesn't execute, skip intermediate commands
20A5: 06 01       ld   b,$01		; initially we're inside a while
20A7: DD 7E 00    ld   a,(ix+$00)
20AA: DD 23       inc  ix
20AC: DD 23       inc  ix
20AE: FE 82       cp   $82
20B0: 28 F5       jr   z,$20A7		; if it's 0x82 (marker), advance by 2
20B2: DD 2B       dec  ix			; otherwise, by 1
20B4: 04          inc  b			; assume the instruction is a new loop
20B5: FE FE       cp   $FE			; if it finds 0xfe and 0xfd (new while) or 0xe8 and 0xe7 (patched???), continue advancing
20B7: 28 EE       jr   z,$20A7
20B9: FE FD       cp   $FD
20BB: 28 EA       jr   z,$20A7
20BD: FE E8       cp   $E8
20BF: 28 E6       jr   z,$20A7
20C1: FE E7       cp   $E7
20C3: 28 E2       jr   z,$20A7
20C5: 05          dec  b			; if it gets here the instruction was not a loop
20C6: FE FA       cp   $FA
20C8: 20 DD       jr   nz,$20A7		; continue until finding an end while
20CA: 10 DB       djnz $20A7		; repeat until reaching the end of the first loop
20CC: C3 1E 20    jp   $201E

20CF: E5          push hl
20D0: C3 1E 20    jp   $201E		; continue processing block data

20D3: E1          pop  hl
20D4: C3 1E 20    jp   $201E		; continue processing block data

; retrieves the length and if not 0, jumps back to process instructions from the saved address. Otherwise, clears the stack and continues
20D7: C1          pop  bc			; retrieves from the stack the block length (either in x or y)
20D8: 0D          dec  c			; decrements the length
20D9: 28 08       jr   z,$20E3		; if the length is finished, pop the other value from the stack and jump
20DB: DD E1       pop  ix			; otherwise, retrieve the sequence data, decrement the position and process the block again
20DD: DD E5       push ix
20DF: C5          push bc
20E0: C3 1E 20    jp   $201E		; continue processing the block

20E3: C1          pop  bc			; retrieves the current position of the block construction data
20E4: C3 1E 20    jp   $201E		; continue processing the block

; paints the tile indicated by hl with the next byte read and changes the position of hl (y--)
20E7: CD FC 20    call $20FC
20EA: 25          dec  h		; this instruction updates one from the previous routine
20EB: C3 1E 20    jp   $201E	; continue processing the block

; paints the tile indicated by hl with the next byte read and changes the position of hl (x--)
20EE: CD FC 20    call $20FC
20F1: 2D          dec  l		; this instruction updates one from the previous routine
20F2: C3 1E 20    jp   $201E	; continue processing the block

; paints the tile indicated by hl with the next byte read and changes the position of hl (x++)
20F5: CD FC 20    call $20FC
20F8: 2C          inc  l		; this instruction updates one from the previous routine
20F9: C3 1E 20    jp   $201E	; continue processing the block

; reads a byte from the block construction buffer indicating the tile number, reads the next byte and paints it at hl, modifying hl
;  if the next byte >= 0xc8, exit
;  if the next byte read is 0x80 draws the tile at hl, updates coordinates and continues processing
;  if the next byte read is 0x81, draws the tile at hl and continues processing
;  if it's something else != 0x00, draws the tile at hl, updates coordinates as many times as bytes read, checks if it skips a byte and exits
;  if it's something else = 0x00, checks if it skips a byte and exits
; hl = position in tile buffer (tile buffer coordinate system)
; ix = pointer to the block construction data
20FC: D1          pop  de			; gets the return address
20FD: 1A          ld   a,(de)
20FE: 32 1B 21    ld   ($211B),a	; modifies an instruction with the read data
2101: 13          inc  de
2102: D5          push de			; saves the new return address

2103: CD 14 22    call $2214		; reads a position from the block construction buffer or an operand
2106: DD 7E 00    ld   a,(ix+$00)	; reads the next byte of construction data
2109: FE C8       cp   $C8			; if it's >= 0xc8, paint, change hl according to operation and exit
210B: 30 0B       jr   nc,$2118
210D: DD 23       inc  ix			; if it gets here, the byte is used, so point to next element
210F: FE 80       cp   $80
2111: 20 0A       jr   nz,$211D		; if the byte read was not 0x80, jump

; arrives here if the byte read is 0x80
2113: CD 18 21    call $2118		; draws the tile at hl, updates coordinates and continues processing
2116: 18 EB       jr   $2103

; when it arrives here, paint, do operation and exit
2118: CD 33 16    call $1633		; checks if the tile indicated by hl is visible, and if so, updates the tile buffer
211B: 25          dec  h			; this instruction is changed from outside
211C: C9          ret

; arrives here if the byte read is not 0x80
211D: FE 81       cp   $81			; if the byte read was not 0x81, jump
211F: 20 05       jr   nz,$2126

; arrives here if the byte read is 0x81
2121: CD 33 16    call $1633		; draws the tile at hl and continues processing
2124: 18 DD       jr   $2103

; arrives here if the byte read is not 0x80 nor 0x81
2126: C5          push bc			; preserves the previously read byte
2127: CD 14 22    call $2214		; a = number of times to perform the operation
212A: 79          ld   a,c
212B: C1          pop  bc
212C: A7          and  a
212D: C4 3A 21    call nz,$213A		; if what was read is != 0, paint a times and perform the operation a times

2130: DD 7E 00    ld   a,(ix+$00)
2133: FE C8       cp   $C8			; if it's >= 0xc8, exit
2135: D0          ret  nc
2136: DD 23       inc  ix			; skip and continue processing
2138: 18 C9       jr   $2103

213A: CD 18 21    call $2118		; paint and do operation
213D: 3D          dec  a
213E: 20 FA       jr   nz,$213A		; repeat the same while a is not 0
2140: C9          ret


; modifies the block construction buffer position (indicated in the first byte) with a calculated expression (indicated by the following bytes)
; h = block position in y (tile buffer coordinate system)
; l = block position in x (tile buffer coordinate system)
; ix = pointer to the block construction data
2141: DD 7E 00    ld   a,(ix+$00)	; reads a byte
2144: FE 70       cp   $70
2146: F5          push af			; saves the read byte
2147: CD 14 22    call $2214		; reads a position from the block construction buffer and saves in de the accessed address
214A: D5          push de			; saves the buffer address obtained in the previous routine
214B: CD 14 22    call $2214		; c = initial value
214E: CD 66 21    call $2166		; modifies the initial value with sums of values or registers and sign changes
2151: D1          pop  de			; retrieves the address obtained with the first byte
2152: F1          pop  af			; a = first byte read
2153: 38 0C       jr   c,$2161		; if the first byte read < 0x70 (doesn't access local grid coordinates), jump

2155: 1A          ld   a,(de)		; reads the value of the position to modify in the block construction buffer
2156: A7          and  a
2157: CA 1E 20    jp   z,$201E		; if local grid data is not calculated for the block, exit
215A: 79          ld   a,c			; c = calculated value
215B: FE 64       cp   $64
215D: 38 02       jr   c,$2161		; adjusts the value to save between 0x00 and 0x64 (0 and 100)
215F: 0E 00       ld   c,$00		; otherwise set it to 0

2161: 79          ld   a,c			; updates the calculated value
2162: 12          ld   (de),a
2163: C3 1E 20    jp   $201E		; continue generating the block

; modifies c with sums of values or registers and sign changes read from the block construction data
; c = operand 1
; de = pointer to a position in the block construction buffer
; ix = pointer to the block construction data
2166: DD 7E 00    ld   a,(ix+$00)	; reads a byte
2169: FE C8       cp   $C8			; if it's >= 0xc8, exit
216B: D0          ret  nc
216C: FE 84       cp   $84
216E: 20 08       jr   nz,$2178		; if it's not 0x84, jump
2170: DD 23       inc  ix			; if it's 0x84, advance the pointer and negate the read byte
2172: 79          ld   a,c			; c = -c
2173: ED 44       neg
2175: 4F          ld   c,a
2176: 18 EE       jr   $2166

; if it arrives here it's because it accesses a register or is an immediate value
2178: C5          push bc
2179: CD 14 22    call $2214		; gets in c the next byte
217C: 79          ld   a,c
217D: C1          pop  bc
217E: 81          add  a,c			; adds it with what was already there
217F: 4F          ld   c,a
2180: 18 E4       jr   $2166

; gets in de the address of [ix]
2182: DD 5E 00    ld   e,(ix+$00)	; de = [ix]
2185: DD 23       inc  ix
2187: DD 56 00    ld   d,(ix+$00)
218A: DD 23       inc  ix
218C: C9          ret

; changes the instructions that update the x coordinate of the tiles (incx -> decx)
218D: 3E 2D       ld   a,$2D
218F: 32 52 20    ld   ($2052),a
2192: 32 F8 20    ld   ($20F8),a
2195: 3D          dec  a
2196: 32 58 20    ld   ($2058),a
2199: 3E 01       ld   a,$01
219B: 32 30 22    ld   ($2230),a
219E: C3 1E 20    jp   $201E

; h = block position in y (tile buffer coordinate system)
; l = block position in x (tile buffer coordinate system)
; b = element length in y
; c = element length in x
; ix = pointer to the block construction data
; changes the pointer to the block construction data
21A1: CD 82 21    call $2182	; gets the next address from the material entry
21A4: D5          push de
21A5: DD E1       pop  ix		; ix = de
21A7: C3 1E 20    jp   $201E	; continue evaluating the block data

21AA: 3E 01       ld   a,$01
21AC: 32 CE 1F    ld   ($1FCE),a	; marks that a change was made in the operations working with x coordinates in tiles
21AF: 11 B9 1B    ld   de,$1BB9		; points to the routine that initiates the evaluation of the current block without modifying the tiles that form the block
21B2: 18 03       jr   $21B7

21B4: 11 BC 1B    ld   de,$1BBC		; points to the routine that initiates the evaluation of the current block, modifying the tiles that form the block
21B7: ED 53 EE 21 ld   ($21EE),de	; modifies an instruction with the address
21BB: E5          push hl			; saves the current position in the grid
21BC: 3A 52 20    ld   a,($2052)	; gets the instructions used to work with x
21BF: 4F          ld   c,a			; c = what's used in incTilePosX
21C0: 3A 58 20    ld   a,($2058)
21C3: 47          ld   b,a			; b = what's used in decTilePosX
21C4: C5          push bc			; saves the values used in incTilePosX and decTilePosX instructions
21C5: 3A F8 20    ld   a,($20F8)
21C8: 4F          ld   c,a			; c = what's used in DrawTileIncX
21C9: 3A 30 22    ld   a,($2230)
21CC: 47          ld   b,a			; b = xor used for the possible swap between reg 0x70 and 0x71
21CD: C5          push bc			; saves the values on the stack
21CE: ED 4B DE 1F ld   bc,($1FDE)	; gets the positions in the grid coordinate system and saves them on the stack
21D2: C5          push bc
21D3: ED 4B DB 1F ld   bc,($1FDB)	; gets the parameters for block construction and saves them on the stack
21D7: C5          push bc
21D8: 3A DD 1F    ld   a,($1FDD)	; gets the parameter dependent on byte 4 and saves it on the stack
21DB: F5          push af

21DC: 11 F0 21    ld   de,$21F0		; saves the return address on the stack
21DF: D5          push de
21E0: CD 82 21    call $2182		; gets in de the pointer that's in the block construction data
21E3: 3A DD 1F    ld   a,($1FDD)	; a = parameter dependent on fourth byte
21E6: E5          push hl			; puts the position on the stack
21E7: EB          ex   de,hl		; de = [hl]
21E8: 5E          ld   e,(hl)
21E9: 23          inc  hl
21EA: 56          ld   d,(hl)
21EB: 23          inc  hl
21EC: E3          ex   (sp),hl		; retrieves the position from the stack and puts the address of the data that defines the block tiles
21ED: C3 BC 1B    jp   $1BBC		; instruction modified from outside

; retrieves all values saved on the stack
21F0: F1          pop  af
21F1: 32 DD 1F    ld   ($1FDD),a
21F4: C1          pop  bc
21F5: ED 43 DB 1F ld   ($1FDB),bc
21F9: C1          pop  bc
21FA: ED 43 DE 1F ld   ($1FDE),bc
21FE: C1          pop  bc
21FF: 79          ld   a,c
2200: 32 F8 20    ld   ($20F8),a
2203: 78          ld   a,b
2204: 32 30 22    ld   ($2230),a
2207: C1          pop  bc
2208: 79          ld   a,c
2209: 32 52 20    ld   ($2052),a
220C: 78          ld   a,b
220D: 32 58 20    ld   ($2058),a
2210: E1          pop  hl
2211: C3 1E 20    jp   $201E

; reads a byte from the block construction data, advancing the pointer. If it read data from the block construction buffer,
; at exit, de will point to that register
; if the byte read is < 0x60, it's a value and returns it
; if the byte read is 0x82, exits returning the next byte
; otherwise, it's a read operation of block characteristics register
; ix = pointer to the block construction data
2214: DD 7E 00    ld   a,(ix+$00)	; reads the current byte and increments the pointer
2217: DD 23       inc  ix

2219: 11 CF 1F    ld   de,$1FCF		; points to the texture data buffer
221C: FE 60       cp   $60			; if the byte read is < 0x60, check and exit
221E: 38 19       jr   c,$2239
2220: FE 82       cp   $82
2222: 20 07       jr   nz,$222B		; if the byte read != 0x82, jump
2224: DD 7E 00    ld   a,(ix+$00)	; gets the next byte and jumps
2227: DD 23       inc  ix
2229: 18 0E       jr   $2239

222B: FE 70       cp   $70			; if the byte read is < 0x70, jump
222D: 38 02       jr   c,$2231
222F: EE 00       xor  $00			; swaps between register 0x70 and 0x71

2231: D6 61       sub  $61			; a = index in the block construction buffer

; de points to the beginning of the buffer
2233: 83          add  a,e			; de = de + a
2234: 5F          ld   e,a
2235: 8A          adc  a,d
2236: 93          sub  e
2237: 57          ld   d,a
2238: 1A          ld   a,(de)		; reads the buffer entry

2239: 4F          ld   c,a			; checks if it's 0 before exiting
223A: A7          and  a
223B: C9          ret
; ---------------------- end of code and data related to screen generation -----------------------------------

; ??? never reaches here
223C: 00          nop
223D: C3 9A 24    jp   $249A		; jumps to the real start of the program

; restores the mirror room, changes the interrupt to a ret, turns off sound, gets the stack address at game start and jumps there
; probably this code is used in conjunction with the debugger to be able to debug the game, but the code that loads the debugger
; has been removed from the final version of the game
2240: F3          di
2241: 01 C6 7F    ld   bc,$7FC6
2244: ED 49       out  (c),c			; puts abadia7 at 0x4000
2246: 2A D9 34    ld   hl,($34D9)		; gets the pointer to the mirror room height data
2249: 36 FF       ld   (hl),$FF			; restores the original mirror height
224B: 01 C0 7F    ld   bc,$7FC0			; restores the previous configuration
224E: ED 49       out  (c),c
2250: CD 76 13    call $1376			; turns off sound
2253: ED 7B C2 2D ld   sp,($2DC2)		; gets the stack address at game start
2257: 3E C9       ld   a,$C9
2259: 38 32 00    ld   ($0038),a		; interrupt = ret
225C: C9          ret

;----------------------- data and code related to the graphics engine -------------------------------------
; table of routines to call at 0x2add according to camera orientation
225D:
	248A 2485 248B 2494

2265:
; table with ground floor data (0x2255-0x2304) (actually starts before because at Y = 0 there is nothing)
; X 00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f  Y
; ================================================== ==
	XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX  00
	00 00 00 00 00 00 00 00 27 00 3E 00 00 00 00 00	 01
	00 0A 09 00 07 08 2A 28 26 29 37 38 39 00 00 00	 02
	00 00 02 01 00 0D 0E 24 23 25 2B 2C 2D 00 00 00	 03
	00 00 03 00 1F 00 00 00 22 00 2E 2F 30 00 00 00	 04
	00 00 04 1D 1E 3E 3D 00 21 00 31 32 33 00 00 00	 05
	00 0C 0B 1C 05 06 3C 00 20 00 34 35 36 00 00 00	 06
	00 00 00 0F 10 11 12 00 1B 00 1A 3A 3B 00 00 00	 07
	00 00 00 00 00 00 13 14 15 18 19 00 00 00 00 00	 08
	00 00 00 00 00 00 00 00 16 00 00 00 00 00 00 00	 09
	00 00 00 00 00 00 00 00 17 00 00 00 00 00 00 00	 0a

2305:
; table with first floor data (actually starts earlier because at Y = 0 and Y = 1 there is nothing)
; X 00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f  Y
; ================================================== ==
	XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX  00
	XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX  01
	00 45 44 00 48 49 00 00 XX XX XX XX XX XX XX XX  02
	00 00 43 47 4A 00 00 00 XX XX XX XX XX XX XX XX	 03
	00 00 42 00 4B 00 00 00 XX XX XX XX XX XX XX XX	 04
	00 00 41 40 4C 00 00 00 XX XX XX XX XX XX XX XX	 05
	00 3F 46 00 4D 4E 00 00 XX XX XX XX XX XX XX XX	 06

230D:
; table with second floor data (actually starts earlier because at Y = 0 and Y = 1 there is nothing)
; X 00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f  Y
; ================================================== ==
	XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX  00
	XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX  01
	00 67 66 00 65 64 00 00 XX XX XX XX XX XX XX XX  02
	00 00 6A 69 68 00 00 00 XX XX XX XX XX XX XX XX	 03
	00 00 6C 00 6B 00 00 00 XX XX XX XX XX XX XX XX	 04
	00 00 6F 6D 6E 00 00 00 XX XX XX XX XX XX XX XX	 05
	00 73 72 00 71 70 00 00 XX XX XX XX XX XX XX XX	 06

; checks if the displayed character has changed screens and if so, gets the height data of the new screen,
; modifies the engine position values adjusted for the new screen, initializes door and object sprites
; of the game with the current screen orientation and modifies character sprites according to screen orientation
2355: 0E 00       ld   c,$00		; initially no changes have occurred
2357: 21 75 2D    ld   hl,$2D75		; hl points to current screen position data
235A: FD 2A 88 2D ld   iy,($2D88)	; iy = pointer to data of character being followed by the camera
235E: FD 7E 02    ld   a,(iy+$02)	; reads current character's X position
2361: E6 F0       and  $F0
2363: BE          cp   (hl)
2364: 28 07       jr   z,$236D		; if screen's X position hasn't changed, jump

2366: 0C          inc  c			; indicates the change
2367: 77          ld   (hl),a		; updates current screen position
2368: D6 0C       sub  $0C
236A: 32 E1 2A    ld   ($2AE1),a	; modifies a routine value

236D: 23          inc  hl
236E: FD 7E 03    ld   a,(iy+$03)	; reads current character's Y position
2371: E6 F0       and  $F0
2373: BE          cp   (hl)
2374: 28 07       jr   z,$237D		; if screen's Y position hasn't changed, jump

2376: 77          ld   (hl),a		; updates current screen position
2377: 0C          inc  c			; indicates the change
2378: D6 0C       sub  $0C
237A: 32 EB 2A    ld   ($2AEB),a	; modifies a routine value

237D: 23          inc  hl
237E: FD 7E 04    ld   a,(iy+$04)	; reads current character's Z position
2381: CD 73 24    call $2473		; depending on height, returns floor's base height in b
2384: 78          ld   a,b
2385: BE          cp   (hl)
2386: 28 18       jr   z,$23A0		; if height hasn't changed, jump
2388: 32 F9 2A    ld   ($2AF9),a	; modifies a routine value
238B: 77          ld   (hl),a
238C: 0C          inc  c			; indicates the change

238D: 21 55 22    ld   hl,$2255		; hl points to ground floor data
2390: A7          and  a
2391: 28 0A       jr   z,$239D		; if height is 0, done
2393: 21 E5 22    ld   hl,$22E5		; hl points to first floor data
2396: FE 0B       cp   $0B
2398: 28 03       jr   z,$239D		; if on first floor, done
239A: 21 ED 22    ld   hl,$22ED		; hl points to second floor data
239D: 22 EF 23    ld   ($23EF),hl	; modifies instruction value according to current floor

23A0: 79          ld   a,c			; if no screen change occurred, exit
23A1: A7          and  a
23A2: C8          ret  z

23A3: 32 B8 2D    ld   ($2DB8),a	; indicates a screen change occurred
23A6: 3A 77 2D    ld   a,($2D77)	; gets floor's base height of character shown on screen
23A9: FE 16       cp   $16
23AB: 3E 00       ld   a,$00
23AD: 20 17       jr   nz,$23C6		; if not on second floor, jump (with a = 0)
23AF: 3A 75 2D    ld   a,($2D75)	; reads most significant x coordinate of screen
23B2: FE 20       cp   $20
23B4: 3E 00       ld   a,$00
23B6: 38 0E       jr   c,$23C6		; if on screen < 0x20 (screen 0x67 or 0x73), jump
23B8: 3E 01       ld   a,$01
23BA: 20 0A       jr   nz,$23C6		; if not on 0x20-0x2f, jump (with a = 1)
23BC: 3A 76 2D    ld   a,($2D76)	; reads most significant y coordinate of screen
23BF: FE 60       cp   $60			; if not on 0x60-0x6f (screen 0x72), jump (with a = 1)
23C1: 3E 01       ld   a,$01
23C3: 20 01       jr   nz,$23C6
23C5: 3D          dec  a			; a = 0

; arrives here with a = 0 or a = 1 (on/off)
23C6: 32 6C 15    ld   ($156C),a	; records if screen is lit or not
23C9: 3E FE       ld   a,$FE
23CB: 32 CF 2F    ld   ($2FCF),a	; marks light sprite as not visible
23CE: 21 75 2D    ld   hl,$2D75		; in upper 4 bits of hl stores most significant part of x position of displayed character
23D1: 4E          ld   c,(hl)
23D2: ED 6F       rld  (hl)			; puts most significant 4 bits of [hl] in least significant 4 bits of a
23D4: 71          ld   (hl),c		; restores original value
23D5: E6 0F       and  $0F
23D7: 5F          ld   e,a			; e = high part of current character's X position (in lower 4 bits)
23D8: E6 01       and  $01
23DA: 47          ld   b,a			; b = pos X & 0x01
23DB: 23          inc  hl
23DC: 4E          ld   c,(hl)		; c = high part of current character's Y position
23DD: 79          ld   a,c
23DE: B3          or   e
23DF: 5F          ld   e,a			; e = (Y, X) (offset within floor map)
23E0: ED 6F       rld  (hl)			; puts most significant 4 bits of [hl] in least significant 4 bits of a
23E2: 71          ld   (hl),c		; restores original value
23E3: E6 01       and  $01			; a = (pos Y & 0x01)

23E5: A8          xor  b			; b = (pos Y & 0x01)^(pos X & 0x01)
23E6: CB 20       sla  b			; b = b*2 (b = 0 or 2)
23E8: B0          or   b			; a = (((pos Y & 0x01)^(pos X & 0x01)) | ((pos X & 0x01) << 1))
23E9: 32 81 24    ld   ($2481),a	; calculates current screen orientation

23EC: 16 00       ld   d,$00
23EE: 21 55 22    ld   hl,$2255		; instruction modified from outside to put floor map address in hl
23F1: 19          add  hl,de		; advance to corresponding screen data
23F2: 7E          ld   a,(hl)		; reads current screen
23F3: CD 00 2D    call $2D00		; stores address of current screen data at 0x156a-0x156b
23F6: CD 22 2D    call $2D22		; fills height buffer with data read from abadia7.bin and clipped for current screen
23F9: 3A 81 24    ld   a,($2481)	; reads orientation of screen to be drawn
23FC: 0F          rrca				; places orientation in upper 2 bits to index in table (each entry is 64 bytes)
23FD: 0F          rrca
23FE: 21 9F 30    ld   hl,$309F		; points to table for calculating offset according to game entity animation
2401: 85          add  a,l
2402: 6F          ld   l,a
2403: 8C          adc  a,h
2404: 95          sub  l
2405: 67          ld   h,a			; indexes in table according to orientation
2406: 22 84 2D    ld   ($2D84),hl	; saves pointer for later
2409: 3A 81 24    ld   a,($2481)	; retrieves current screen orientation
240C: 87          add  a,a
240D: 21 5D 22    ld   hl,$225D		; points to table of coordinate system change routines
2410: CD 2D 16    call $162D		; hl = hl + a
2413: 5E          ld   e,(hl)
2414: 23          inc  hl
2415: 56          ld   d,(hl)		; de = [hl]
2416: ED 53 01 2B ld   ($2B01),de	; modifies a call depending on screen orientation
241A: CD 30 0D    call $0D30		; initializes door sprites for current room
241D: CD 23 0D    call $0D23		; initializes object sprites for current room
2420: 21 AE 2B    ld   hl,$2BAE		; points to table with data for character sprites
2423: 5E          ld   e,(hl)
2424: 23          inc  hl
2425: 7E          ld   a,(hl)
2426: FE FF       cp   $FF			; while 0xff not read, continue
2428: C8          ret  z
2429: 57          ld   d,a			; de = address of sprite associated with character
242A: 23          inc  hl
242B: ED 53 4C 24 ld   ($244C),de	; modifies an instruction with first read value (16 bits)
242F: 5E          ld   e,(hl)		; de = next value
2430: 23          inc  hl
2431: 56          ld   d,(hl)
2432: ED 53 50 24 ld   ($2450),de	; modifies an instruction with second read value (16 bits)
2436: 23          inc  hl			; skips 16 bits and reads next value
2437: 23          inc  hl
2438: 23          inc  hl
2439: 5E          ld   e,(hl)
243A: 23          inc  hl
243B: 56          ld   d,(hl)
243C: 23          inc  hl
243D: ED 53 59 2A ld   ($2A59),de	; modifies an instruction with third read value (16 bits)
2441: 5E          ld   e,(hl)		; reads next value
2442: 23          inc  hl
2443: 56          ld   d,(hl)
2444: 23          inc  hl
2445: ED 53 84 2A ld   ($2A84),de	; modifies an instruction
2449: E5          push hl			; saves table position
244A: DD 21 00 00 ld   ix,$0000		; instruction modified from outside (puts address of sprite associated with character)
244E: FD 21 00 00 ld   iy,$0000		; instruction modified from outside (puts address of position data associated with character)
2452: CD 68 24    call $2468		; processes character data to change animation and sprite position and indicate if visible or not
2455: FD 4E 0E    ld   c,(iy+$0e)	; reads value indicating what type of character is at a position
2458: CD EF 28    call $28EF		; if sprite position is central and height is correct, puts c in occupied positions of height buffer
245B: E1          pop  hl			; retrieves table position
245C: 18 C5       jr   $2423		; continue getting entries until finding 0xffff

245E: CD DD 2A    call $2ADD		; checks if visible and if so, updates position if necessary. If visible doesn't return, but exits to calling routine
2461: DD 36 00 FE ld   (ix+$00),$FE	; marks sprite as unused
2465: E1          pop  hl			; removes return address and animation table address from stack and exits
2466: E1          pop  hl
2467: C9          ret

; processes character data to change animation and sprite position
;  ix = corresponding sprite address
;  iy = corresponding character position data
2468: CD 61 2A    call $2A61	; changes monk robes animation according to position and animation counter
								;  and gets address of animation data to put in hl
246B: E5          push hl		; saves animation table address
246C: CD 5E 24    call $245E	; checks if sprite is visible and updates sprite position. If sprite not visible, doesn't return
246F: E1          pop  hl		; retrieves animation table address
2470: C3 34 2A    jp   $2A34	; updates graphics address, sprite width and height, and flips graphics if necessary

; depending on height, returns floor's base height in b
2473: FE 0D       cp   $0D		; 13
2475: 06 00       ld   b,$00
2477: D8          ret  c		; if height is < 13 exits with b = 0 (00-12 -> ground floor)
2478: FE 18       cp   $18		; 24
247A: 06 16       ld   b,$16
247C: D0          ret  nc		; if height is >= 24 exits with b = 22 (24- -> second floor)
247D: 06 0B       ld   b,$0B	; if height is >= 13 and < 24 exits with b = 11 (13-23 -> first floor)
247F: C9          ret

; modifies orientation passed in a with current screen orientation
2480: D6 00       sub  $00		; modified by orientation with which character enters screen
2482: E6 03       and  $03
2484: C9          ret

; performs coordinate change if camera orientation is type 1
2485: 3E 28       ld   a,$28
2487: 94          sub  h
2488: 65          ld   h,l		; y = x
2489: 6F          ld   l,a		; x = 0x28 - y

; performs coordinate change if camera orientation is type 0
248A: C9          ret			; doesn't make any change

; performs coordinate change if camera orientation is type 2
248B: 3E 28       ld   a,$28
248D: 94          sub  h
248E: 67          ld   h,a		; y = 0x28 - y
248F: 3E 28       ld   a,$28
2491: 95          sub  l
2492: 6F          ld   l,a		; x = 0x28 - x
2493: C9          ret

; performs coordinate change if camera orientation is type 3
2494: 3E 28       ld   a,$28
2496: 95          sub  l
2497: 6C          ld   l,h		; x = y
2498: 67          ld   h,a		; y = 0x28 - x
2499: C9          ret
;----------------------- end of data and code related to graphics engine -------------------------------------

;--------------- arrives here from 0x0400 once data has been loaded into memory ---------------------------------------
249A: F3          di
249B: 3A FE 00    ld   a,($00FE)	; checks if it's first time arriving here
249E: FE 0D       cp   $0D
24A0: 28 67       jr   z,$2509		; if already entered here, skip gate array configuration and manuscript presentation

; initialization
24A2: 3E 0D       ld   a,$0D
24A4: 32 FE 00    ld   ($00FE),a	; indicates initialization has been done
24A7: 01 8D 7F    ld   bc,$7F8D		; 10001101 (GA select screen mode, rom cfig and int control)
24AA: ED 49       out  (c),c		; sets mode 1 (320x200 4 colors), disables upper and lower ROM areas (only RAM accessed in those zones)
24AC: CD 3A 3F    call $3F3A		; sets black color palette

24AF: 21 9D 65    ld   hl,$659D		; copies 0x659d-0x759c (manuscript routines to screen)
24B2: 11 00 C0    ld   de,$C000
24B5: D5          push de
24B6: 01 00 10    ld   bc,$1000
24B9: C5          push bc
24BA: ED B0       ldir

24BC: 01 C5 7F    ld   bc,$7FC5
24BF: ED 49       out  (c),c		; selects configuration (0, 5, 2, 3) (loads abadia6.bin at 0x4000)
24C1: C1          pop  bc
24C2: E1          pop  hl
24C3: 11 00 70    ld   de,$7000		; points to part of abadia6.bin
24C6: ED B0       ldir				; copies data it saved in video memory to abadia6.bin (although already at destination)
24C8: 01 C0 7F    ld   bc,$7FC0		; restores typical configuration (0, 1, 2, 3) (loads abadia2.bin at 0x4000)
24CB: ED 49       out  (c),c

24CD: 3E C3       ld   a,$C3		; sets code to execute when interrupt occurs = jp 0x2d48
24CF: 32 38 00    ld   ($0038),a
24D2: 21 48 2D    ld   hl,$2D48
24D5: 22 39 00    ld   ($0039),hl

24D8: 21 00 80    ld   hl,$8000		; address of manuscript music data
24DB: 3E 0B       ld   a,$0B
24DD: 32 86 10    ld   ($1086),a	; changes a value related to music tempo
24E0: CD 3F 10    call $103F		; initializes sound table and enables interrupts
24E3: F3          di
24E4: DD 21 00 73 ld   ix,$7300		; points to presentation manuscript text
24E8: CD 9D 65    call $659D		; draws manuscript and tells introduction. Returns from here when space is pressed
24EB: F3          di

24EC: CD 76 13    call $1376		; turns off sound
24EF: CD 3A 3F    call $3F3A		; sets palette colors to black

24F2: 21 00 83    ld   hl,$8300		; points to abadia3.bin graphics
24F5: 11 00 6D    ld   de,$6D00		; points to data no longer used (unless game ending is reached, so they were copied to abadia6.bin)
24F8: 01 00 20    ld   bc,$2000
24FB: ED B0       ldir				; copies graphics that make up abbey and game objects at 0x6d00-0x8cff

24FD: CD 12 27    call $2712		; clears bottom 40 lines of screen
2500: CD B6 37    call $37B6		; copies things from many places to 0x0103-0x01a9 (why??)
2503: CD 61 3A    call $3A61		; creates flipx table (0xa100-0xa1ff) for pixels, gets address from abadia7.bin where
									;  mirror height is, gets address of block forming mirror from abadia8.bin, and if
									;  it was open, closes it
2506: CD D1 3A    call $3AD1		; generates 4 tables (of 0x100 bytes) for pixel handling using AND and OR at 0x9d00-0xa0ff

; initialization for game is now complete
; now performs initialization to start playing a game
2509: F3          di
250A: CD 76 13    call $1376		; turns off sound
250D: CD BC 32    call $32BC		; reads key state and saves in keyboard buffers
2510: 3E 2F       ld   a,$2F
2512: CD 82 34    call $3482		; while space not released, wait
2515: 20 F2       jr   nz,$2509

2517: CD 1E 38    call $381E		; copies things from 0x0103-0x01a9 to many places (note: on initialization reverse operation was done). Also initializes
									;  sprite table and character characteristics, and clears logic data and auxiliary variables
251A: CD 5C 27    call $275C		; draws 256-wide rectangle in upper 160 screen lines
251D: CD 2C 27    call $272C		; draws scoreboard
2520: 3E 06       ld   a,$06
2522: 32 86 10    ld   ($1086),a	; sets new music tempo
2525: 3E C3       ld   a,$C3		; 0xc3 = jp xxxx instruction
2527: 32 38 00    ld   ($0038),a	; sets IRQ code (jp 2d48)

252A: 32 A6 4F    ld   ($4FA6),a	; ???
252D: 32 08 00    ld   ($0008),a	; modifies rst 0x08 and rst 0x10 code to call logic interpreter
2530: 32 10 00    ld   ($0010),a
2533: 21 48 2D    ld   hl,$2D48
2536: 22 39 00    ld   ($0039),hl
2539: 21 D1 3D    ld   hl,$3DD1		; rst 0x08 = jp 0x3dd1
253C: 22 09 00    ld   ($0009),hl
253F: 21 AF 3D    ld   hl,$3DAF		; rst 0x10 = jp 0x3daf
2542: 22 11 00    ld   ($0011),hl

2545: 3A 49 BF    ld   a,($BF49)	; reads abadia3.bin + 0x3f49
2548: 32 18 26    ld   ($2618),a	; replaces an instruction value (related to game speed)
254B: 2A 50 BF    ld   hl,($BF50)
254E: 22 38 30    ld   ($3038),hl	; sets Guillermo's initial position
2551: 24          inc  h
2552: 24          inc  h
2553: 2D          dec  l
2554: 2D          dec  l
2555: 22 47 30    ld   ($3047),hl	; sets Adso's initial position
2558: 3A 52 BF    ld   a,($BF52)
255B: 32 3A 30    ld   ($303A),a	; sets Guillermo and Adso's initial height
255E: 32 49 30    ld   ($3049),a

2561: 21 59 AB    ld   hl,$AB59		; points to monk movement graphics
2564: 11 2E AE    ld   de,$AE2E
2567: D5          push de
2568: 01 D5 02    ld   bc,$02D5		; copies 0xab59-0xae2d to 0xae2e-0xb102
256B: ED B0       ldir
256D: E1          pop  hl			; hl points to start of copied graphics

256E: 01 05 91    ld   bc,$9105		; graphics 5 bytes wide, 0x91 blocks of 5 bytes (= 0x2d5)
2571: CD 52 35    call $3552		; gets x-flipped monk graphics at 0xae2e-0xb102
2574: CD B0 34    call $34B0		; initializes mirror room and mirror-related variables
2577: CD D2 54    call $54D2		; initializes day and time of day with values read from 0xbf4f and 0xbf4e

257A: 3E 10       ld   a,$10		; data to enable commands when processing behavior
257C: 32 C0 A2    ld   ($A2C0),a	; initializes Adso's command
257F: 32 00 A2    ld   ($A200),a	; initializes Malaquias's command
2582: 32 30 A2    ld   ($A230),a	; initializes Abbot's command
2585: 32 60 A2    ld   ($A260),a	; initializes Berengario's command
2588: 32 90 A2    ld   ($A290),a	; initializes Severino's command

258B: AF          xor  a
258C: 32 4B 2D    ld   ($2D4B),a	; resets interrupt counter

; when loading a game also arrives here
258F: F3          di
2590: AF          xor  a
2591: 32 75 2D    ld   ($2D75),a		; initializes screen character is on
2594: 32 8F 28    ld   ($288F),a		; initializes Guillermo's state
2597: 3E 02       ld   a,$02
2599: 32 B1 28    ld   ($28B1),a		; modifies argument value of Guillermo's death behavior instruction
259C: ED 73 C2 2D ld   ($2DC2),sp		; saves stack value with which game was initialized

25A0: CD 5C 27    call $275C			; draws 256-wide rectangle in upper 160 screen lines
25A3: CD 76 13    call $1376			; turns off sound
25A6: CD B9 34    call $34B9			; initializes mirror room
25A9: CD D4 51    call $51D4			; draws objects we have in scoreboard
25AC: CD DF 54    call $54DF			; sets palette according to time of day, shows day number and advances time of day
25AF: CD D3 55    call $55D3			; decrements obsequium
25B2: 00          nop					; parameter of previous call (decrement 0 units)

25B3: CD 01 50    call $5001			; clears part of scoreboard where phrases are shown
25B6: FB          ei

; main game loop starts here
25B7: 00          nop
25B8: 3A 36 30    ld   a,($3036)		; gets Guillermo's animation counter and modifies a search routine
25BB: 32 90 09    ld   ($0990),a
25BE: CD 11 33    call $3311			; checks if QR was pressed in mirror room and acts accordingly
25C1: CD 9D 35    call $359D			; checks if delete pause, or ctrl+f? or shift+f? was pressed and acts accordingly
25C4: CD 89 04    call $0489            ; checks if ctrl+tab was pressed and if so, tries to save game data from memory to disk
25C7: 3E 07       ld   a,$07
25C9: CD 82 34    call $3482			; checks if numeric keypad period was pressed
25CC: C4 4C 3A    call nz,$3A4C			; if pressed, jump (it's a ret, probably jump address has changed)
25CF: CD B6 55    call $55B6			; checks if time-related variables need modifying (time of day, lamp fuel, etc)
25D2: CD ED 4F    call $4FED			; ret (probably jump address has changed)
25D5: CD E7 42    call $42E7			; if Guillermo has died, calculates mission completion percentage, shows on screen and waits for space press
25D8: CD AC 42    call $42AC            ; updates bonuses and if reading book without gloves, kills Guillermo
25DB: CD 99 54    call $5499			; if time of day change scroll hasn't completed, advances it one step
25DE: CD EA 3E    call $3EEA			; gets voice state, and executes actions depending on time of day
25E1: CD D6 41    call $41D6			; checks if camera-following character needs changing and calculates bonuses we've achieved (interpreted)
25E4: CD 55 23    call $2355			; checks if displayed character has changed screens and if so does many things
25E7: 3A B8 2D    ld   a,($2DB8)		; if screen doesn't need redrawing, jump
25EA: A7          and  a
25EB: 28 05       jr   z,$25F2
25ED: CD D8 19    call $19D8			; draws current screen

25F0: 3E 80       ld   a,$80
25F2: 32 FD 0D    ld   ($0DFD),a		; modifies door routine instruction indicating it paints screen
25F5: CD 96 50    call $5096			; checks if Guillermo and Adso pick up or drop any object
25F8: CD 67 0D    call $0D67			; checks if any door needs opening or closing and updates door sprites accordingly
25FB: 21 AE 2B    ld   hl,$2BAE			; hl points to Guillermo's table
25FE: CD 1D 29    call $291D			; checks if Guillermo can move where he wants and updates his sprite and height buffer
2601: CD 64 26    call $2664			; moves Adso and monks
2604: AF          xor  a
2605: 32 B8 2D    ld   ($2DB8),a		; indicates screen doesn't need redrawing
2608: 32 A9 2D    ld   ($2DA9),a		; indicates no path found
260B: CD A3 26    call $26A3			; modifies light sprite characteristics if it can be used by Adso
260E: CD 66 0E    call $0E66			; checks if door graphics need flipping and if so, does it
2611: CD 74 53    call $5374			; checks if graphics need reflecting in mirror

2614: 3A 4B 2D    ld   a,($2D4B)		; reads counter incremented in interrupt
2617: FE 2A       cp   $2A				; modified from outside (to 36)
2619: 38 F9       jr   c,$2614			; waits until value is >= what's there

261B: 3A 36 30    ld   a,($3036)		; if Guillermo is moving, plays a sound
261E: E6 01       and  $01
2620: C4 02 10    call nz,$1002
2623: AF          xor  a
2624: 32 4B 2D    ld   ($2D4B),a		; resets interrupt counter
2627: CD 74 26    call $2674			; draws sprites
; end of main loop

262A: 3E 42       ld   a,$42
262C: CD 82 34    call $3482		; checks if escape is pressed
262F: CD C6 41    call $41C6		; sets a to 0, so escape never registers as pressed
2632: CA B7 25    jp   z,$25B7		; if escape not pressed, jump to main loop

; if escape is pressed, jump to debugger, unless ctrl+shift+escape is pressed, which resets the computer
2635: 3E 15       ld   a,$15
2637: CD 82 34    call $3482		; checks if right shift is pressed
263A: CA 40 22    jp   z,$2240		; if not pressed, restores mirror room, changes interrupt to ret,
									;  turns off sound, gets stack address at game start and jumps there

263D: 3E 17       ld   a,$17
263F: CD 82 34    call $3482		; checks if control is pressed
2642: CA 40 22    jp   z,$2240		; if not pressed, restores mirror room, changes interrupt to ret,
									;  turns off sound, gets stack address at game start and jumps there

; arrives here if ctrl+right shift+escape is being pressed
2645: 01 08 00    ld   bc,$0008		; number of data bytes to copy
2648: 11 00 00    ld   de,$0000		; data destination
264B: 21 5C 26    ld   hl,$265C		; data source
264E: ED B0       ldir				; copies data
2650: ED 7B C2 2D ld   sp,($2DC2)	; gets stack address at game start
2654: E1          pop  hl
2655: 21 00 00    ld   hl,$0000		; puts a 0, to jump to routine just written
2658: E5          push hl
2659: C3 40 22    jp   $2240		; restores mirror room, changes interrupt to ret,
									;  turns off sound, gets stack address at game start and jumps there

; new code copied to 0x0000
265C: 01 89 7F    ld   bc,$7F89		; 10001101 (GA select screen mode, rom cfig and int control)
265F: ED 49       out  (c),c		; sets mode 1 (320x200 4 colors), disables upper ROM area and enables lower one
2661: C3 91 05    jp   $0591		; restarts machine


2664: CD 7B 08    call $087B		; executes Adso's behavior
2667: CD FD 06    call $06FD		; executes Malaquias's behavior
266A: CD 1E 07    call $071E		; executes Abbot's behavior
266D: CD 30 08    call $0830		; executes Berengario's behavior
2670: CD 51 08    call $0851		; executes Severino's behavior
2673: C9          ret

; ----------------------- code related to sprites and light ------------------------------------

; draws sprites
2674: 3A 6C 15    ld   a,($156C)	; reads if room is lit or not
2677: A7          and  a
2678: CA 14 49    jp   z,$4914		; if lit, jump to draw sprites

; sprite drawing when room is not lit
267B: 21 17 2E    ld   hl,$2E17		; hl points to first character sprite
267E: 11 14 00    ld   de,$0014		; length of each sprite
2681: 7E          ld   a,(hl)
2682: FE FF       cp   $FF
2684: 28 09       jr   z,$268F		; if reached end, jump
2686: FE FE       cp   $FE
2688: 28 02       jr   z,$268C		; if not visible, skip next instruction
268A: CB BE       res  7,(hl)		; marks sprite as not to be drawn (because it's dark)
268C: 19          add  hl,de
268D: 18 F2       jr   $2681		; advance to next sprite

268F: 3A 2B 2E    ld   a,($2E2B)	; if Adso's sprite is visible, continue
2692: FE FE       cp   $FE
2694: C8          ret  z
2695: 3A F3 2D    ld   a,($2DF3)	;  and Adso has lamp, continue
2698: E6 80       and  $80
269A: C8          ret  z

269B: 3E BC       ld   a,$BC
269D: 32 CF 2F    ld   ($2FCF),a	; activates light sprite
26A0: C3 14 49    jp   $4914		; jump to draw sprites

; modifies light sprite characteristics if it can be used by Adso
26A3: 3E FE       ld   a,$FE
26A5: 32 CF 2F    ld   ($2FCF),a	; deactivates light sprite
26A8: 3A 6C 15    ld   a,($156C)
26AB: A7          and  a
26AC: C8          ret  z			; if room is lit, exit

; arrives here if it's a dark room
26AD: 3A 2B 2E    ld   a,($2E2B)	; if Adso's sprite not visible, prevents sprite redrawing and exits
26B0: FE FE       cp   $FE
26B2: 28 C7       jr   z,$267B

26B4: 3A 2C 2E    ld   a,($2E2C)	; gets Adso sprite's x position
26B7: 4F          ld   c,a
26B8: E6 03       and  $03
26BA: 32 89 4B    ld   ($4B89),a	; modifies instruction with offset within tile in x
26BD: ED 44       neg
26BF: C6 04       add  a,$04
26C1: 32 B5 4B    ld   ($4BB5),a	; modifies an instruction
26C4: 79          ld   a,c
26C5: DD 21 CF 2F ld   ix,$2FCF		; points to light sprite
26C9: DD 36 12 FE ld   (ix+$12),$FE	; gives sprite maximum depth
26CD: DD 36 13 FE ld   (ix+$13),$FE
26D1: E6 FC       and  $FC			; adjusts Adso sprite's x position to nearest tile and translates it
26D3: D6 08       sub  $08
26D5: 30 01       jr   nc,$26D8
26D7: AF          xor  a
26D8: DD 77 01    ld   (ix+$01),a	; sets sprite's x position
26DB: DD 77 03    ld   (ix+$03),a
26DE: 3A 2D 2E    ld   a,($2E2D)	; gets Adso sprite's y position
26E1: 4F          ld   c,a
26E2: E6 07       and  $07			; gets offset within tile in y
26E4: FE 04       cp   $04
26E6: 21 EF 00    ld   hl,$00EF		; bytes to fill (tile and a half)
26E9: 11 9F 00    ld   de,$009F		; bytes to fill (tile)
26EC: 30 01       jr   nc,$26EF		; if >= 4, jump
26EE: EB          ex   de,hl		; exchange fills

26EF: 22 6B 4B    ld   ($4B6B),hl	; modifies 2 instructions
26F2: ED 53 D1 4B ld   ($4BD1),de
26F6: 79          ld   a,c			; gets Adso sprite's y position
26F7: E6 F8       and  $F8
26F9: D6 18       sub  $18			; adjusts Adso sprite's y position to nearest tile and translates it
26FB: 30 01       jr   nc,$26FE
26FD: AF          xor  a
26FE: DD 77 02    ld   (ix+$02),a	; modifies sprite's y position
2701: DD 77 04    ld   (ix+$04),a
2704: 21 4B 30    ld   hl,$304B		; points to Adso's flip
2707: AF          xor  a
2708: CB 46       bit  0,(hl)
270A: 28 02       jr   z,$270E		; if graphics not flipped, jump
270C: 3E 29       ld   a,$29
270E: 32 A0 4B    ld   ($4BA0),a	; modifies an instruction
2711: C9          ret

; ----------------------- end of code related to sprites and light ----------------------------------------

; clears bottom 40 lines of screen
2712: 21 40 C6    ld   hl,$C640		; points to video memory
2715: 06 08       ld   b,$08		; repeats process for 8 banks
2717: C5          push bc
2718: E5          push hl
2719: 5D          ld   e,l			; de = hl
271A: 54          ld   d,h
271B: 13          inc  de
271C: 36 FF       ld   (hl),$FF
271E: 01 8F 01    ld   bc,$018F		; 5 lines
2721: ED B0       ldir				; fills with 0xff from 0xc640 to 0xc7cf
2723: E1          pop  hl
2724: 01 00 08    ld   bc,$0800		; points to next bank
2727: 09          add  hl,bc
2728: C1          pop  bc
2729: 10 EC       djnz $2717		; repeat until done
272B: C9          ret

; draws scoreboard
272C: 01 C7 7F    ld   bc,$7FC7		; sets configuration 7 (0, 7, 2, 3)
272F: ED 49       out  (c),c
2731: 11 28 63    ld   de,$6328		; points to scoreboard data (from 0x6328 to 0x6b27)
2734: 21 48 C6    ld   hl,$C648		; points to memory address where scoreboard is placed (32, 160)
2737: 06 04       ld   b,$04
2739: C5          push bc
273A: E5          push hl
273B: 06 08       ld   b,$08		; 8 lines
273D: C5          push bc
273E: E5          push hl
273F: 01 40 00    ld   bc,$0040		; copies 64 bytes to screen (256 pixels)
2742: EB          ex   de,hl
2743: ED B0       ldir
2745: EB          ex   de,hl
2746: E1          pop  hl
2747: 01 00 08    ld   bc,$0800		; move to the next line
274A: 09          add  hl,bc
274B: C1          pop  bc
274C: 10 EF       djnz $273D		; repeat for the 8 lines
274E: E1          pop  hl
274F: 01 50 00    ld   bc,$0050		; point to the next line
2752: 09          add  hl,bc
2753: C1          pop  bc
2754: 10 E3       djnz $2739		; repeat for the rest of the marker (total 32 lines)

2756: 01 C0 7F    ld   bc,$7FC0		; set configuration 0 (0, 1, 2, 3)
2759: ED 49       out  (c),c
275B: C9          ret

; draws a rectangle 256 wide in the top 160 screen lines
275C: 06 A0       ld   b,$A0		; 160 lines
275E: 21 00 C0    ld   hl,$C000
2761: C5          push bc
2762: E5          push hl
2763: 5D          ld   e,l			; de = hl + 1
2764: 54          ld   d,h
2765: 13          inc  de
2766: 36 FF       ld   (hl),$FF
2768: 01 08 00    ld   bc,$0008		; fill 8 bytes with 0xff (32 pixels)
276B: ED B0       ldir
276D: 36 00       ld   (hl),$00
276F: 01 40 00    ld   bc,$0040		; fill 64 bytes with 0x00 (256 pixels)
2772: ED B0       ldir
2774: 36 FF       ld   (hl),$FF
2776: 01 08 00    ld   bc,$0008		; fill 8 bytes with 0xff (32 pixels)
2779: ED B0       ldir
277B: E1          pop  hl
277C: CD 4D 3A    call $3A4D		; move to the next line
277F: C1          pop  bc
2780: 10 DF       djnz $2761
2782: C9          ret

; ------------------------ auxiliary code for character movement --------------------------------------

; returns the address of the table to calculate the height of neighboring positions according to the size of the character's position and orientation
2783: 21 4D 28    ld   hl,$284D		; point to the table if the character occupies 4 tiles
2786: FD CB 05 7E bit  7,(iy+$05)
278A: 28 03       jr   z,$278F		; if bit 7 is not set (if the character occupies 4 tiles), jump
278C: 21 6D 28    ld   hl,$286D		; point to the table if the character occupies only 1 tile
278F: FD 7E 01    ld   a,(iy+$01)	; get the character's orientation

; hl = hl + 8*a
2792: 87          add  a,a
2793: 87          add  a,a
2794: 87          add  a,a
2795: 85          add  a,l
2796: 6F          ld   l,a
2797: 8C          adc  a,h
2798: 95          sub  l
2799: 67          ld   h,a
279A: C9          ret

; adjust the position passed in hl to the central 20x20 positions shown. If the position is outside, CF=1
279B: 7C          ld   a,h
279C: D6 00       sub  $00		; instruction modified from outside with the lower limit in y
279E: D8          ret  c		; if the position in y is < the lower limit in y on this screen, exit
279F: FE 02       cp   $02
27A1: D8          ret  c
27A2: FE 16       cp   $16		; if the position in y is > the upper limit in y on this screen, exit
27A4: 3F          ccf			; complement the carry flag
27A5: D8          ret  c

27A6: 67          ld   h,a
27A7: 7D          ld   a,l
27A8: D6 00       sub  $00		; instruction modified from outside with the lower limit in x
27AA: D8          ret  c		; if the position in x is < the lower limit in x on this screen, exit
27AB: FE 02       cp   $02
27AD: D8          ret  c
27AE: FE 16       cp   $16		; if the position in x is > the upper limit in x on this screen, exit
27B0: 3F          ccf           ; complement the carry flag
27B1: D8          ret  c
27B2: 6F          ld   l,a
27B3: C9          ret

; check the height of the positions the character is going to move to and return them in a and c
; if the character is not visible, return the same value as passed in a
; iy is passed the characteristics of the character moving forward
27B4: 47          ld   b,a		; save a
27B5: AF          xor  a		; set the relative height of the floor to 0
27B6: 18 13       jr   $27CB

; check the height of the positions the character is going to move to and return them in a and c
; if the character is not on the current screen, return the same value as passed in a (assuming the height difference has already been calculated outside)
; iy is passed the characteristics of the character moving forward
; called when pressing up cursor
27B8: 5F          ld   e,a
27B9: FD 7E 04    ld   a,(iy+$04)	; get the character's height
27BC: CD 73 24    call $2473		; depending on the height, return the base height of the floor in b
27BF: 3A BA 2D    ld   a,($2DBA)	; get the base height of the floor where the character is
27C2: B8          cp   b
27C3: 37          scf
27C4: 7B          ld   a,e
27C5: C0          ret  nz			; if the floor the character is on doesn't match the one being shown, exit

27C6: FD 7E 04    ld   a,(iy+$04)	; get the character's height
27C9: 90          sub  b			; subtract the base height of the floor
27CA: 43          ld   b,e

; arrives here with a = relative height within the floor
27CB: 32 1F 28    ld   ($281F),a	; modify an instruction
27CE: EB          ex   de,hl
27CF: FD 66 03    ld   h,(iy+$03)	; get the global position of the character
27D2: FD 6E 02    ld   l,(iy+$02)
27D5: CD 9B 27    call $279B		; adjust the position passed in hl to the central 20x20 positions shown. If the position is outside, CF=1
27D8: 78          ld   a,b
27D9: EB          ex   de,hl		; de = position adjusted to the central 20x20 positions
27DA: D8          ret  c			; if the position is not visible, exit

; arrives here if the position is visible. in a and b is the parameter passed, but it's no longer used
27DB: EB          ex   de,hl		; hl = position adjusted to the central 20x20 positions
27DC: 7D          ld   a,l			; a = adjusted x position
27DD: 6C          ld   l,h
27DE: 26 00       ld   h,$00
27E0: 29          add  hl,hl
27E1: 29          add  hl,hl
27E2: 29          add  hl,hl		; hl = adjusted y pos*8
27E3: 54          ld   d,h
27E4: 85          add  a,l
27E5: 5F          ld   e,a			; de = adjusted x pos + adjusted y pos*8
27E6: 29          add  hl,hl		; hl = adjusted y pos*16
27E7: 19          add  hl,de		; hl = adjusted y pos*24 + adjusted x pos
27E8: ED 5B 8A 2D ld   de,($2D8A)	; point de to the height buffer
27EC: 19          add  hl,de		; index into the height buffer
27ED: EB          ex   de,hl		; de <-> hl
27EE: CD 83 27    call $2783		; return the address to calculate the height of neighboring positions according to the size of the character's position and orientation
27F1: 7E          ld   a,(hl)		; modify some instructions according to the first 4 values read from the table
27F2: 32 23 28    ld   ($2823),a
27F5: 23          inc  hl
27F6: 7E          ld   a,(hl)
27F7: 32 24 28    ld   ($2824),a
27FA: 23          inc  hl
27FB: 7E          ld   a,(hl)
27FC: 32 2A 28    ld   ($282A),a
27FF: 23          inc  hl
2800: 7E          ld   a,(hl)
2801: 32 2B 28    ld   ($282B),a
2804: 23          inc  hl

2805: 7E          ld   a,(hl)		; read an offset from the table and save it in hl
2806: 23          inc  hl
2807: E5          push hl
2808: 66          ld   h,(hl)
2809: 6F          ld   l,a
280A: 19          add  hl,de		; add to the current position in the height buffer the offset read
280B: 11 C5 2D    ld   de,$2DC5		; de points to an auxiliary buffer
280E: 06 04       ld   b,$04		; the outer loop performs 4 iterations
2810: C5          push bc
2811: E5          push hl
2812: 06 04       ld   b,$04		; the inner loop performs 4 iterations
2814: C5          push bc
2815: 7E          ld   a,(hl)		; read the value from the current position of the height buffer
2816: FE 10       cp   $10			; check if there is any character at that position
2818: 38 04       jr   c,$281E		; if there is no one at that position, jump
281A: E6 30       and  $30			; keep only the characters at the position
281C: 18 02       jr   $2820		; skip the next instruction

281E: D6 00       sub  $00			; instruction modified from outside with the character's height relative to the current floor
2820: 12          ld   (de),a		; save the character or the height difference in the buffer
2821: 13          inc  de
2822: 01 00 00    ld   bc,$0000		; instruction modified from outside with the offset in the tile buffer for the inner loop
2825: 09          add  hl,bc		; change the position of the tile buffer
2826: C1          pop  bc
2827: 10 EB       djnz $2814
2829: 01 00 00    ld   bc,$0000		; instruction modified from outside with the offset in the tile buffer for the outer loop
282C: E1          pop  hl
282D: 09          add  hl,bc		; change the position of the tile buffer
282E: C1          pop  bc
282F: 10 DF       djnz $2810		; repeat until completing 16 positions

2831: E1          pop  hl
2832: 23          inc  hl
2833: FD CB 05 7E bit  7,(iy+$05)
2837: 28 08       jr   z,$2841		; if the character occupies 4 positions in the height buffer, jump. Otherwise (only occupies 1 position)

2839: 3A C6 2D    ld   a,($2DC6)	; save in a and c the content of the 2 positions the character is advancing towards
283C: 4F          ld   c,a
283D: 3A CA 2D    ld   a,($2DCA)
2840: C9          ret

; arrives here if the character occupies 4 positions in the height buffer
2841: 3A C6 2D    ld   a,($2DC6)	; if the 2 positions being advanced to don't have the same value, exit with equal values for a and c
2844: 4F          ld   c,a
2845: 3A C7 2D    ld   a,($2DC7)
2848: B9          cp   c
2849: C8          ret  z
284A: 3E 02       ld   a,$02		; indicate that there is a difference between heights > 1
284C: C9          ret

; table for calculating character advancement according to orientation (for characters occupying 4 tiles)
; bytes 0-1: offset in the inner loop of the tile buffer
; bytes 2-3: offset in the outer loop of the tile buffer
; bytes 4-5: initial offset in the height buffer for the loop
: byte 6: value to add to the character's x position if advancing in this direction
: byte 7: value to add to the character's y position if advancing in this direction
284D: 	0018 FFFF FFD1 01 00 -> +24 -1  -47 [+1 00]
	0001 0018 FFCE 00 FF -> +1  +24 -50 [00 -1]
	FFE8 0001 0016 FF 00 -> -24 +1  +22 [-1 00]
	FFFF FFE8 0019 00 01 -> -1  -24 +25 [00 +1]

; table for calculating character advancement according to orientation (for characters occupying 1 tile)
286D: 	0018 FFFF FFEA 01 00 -> +24  -1 -22 [+1 00]
	0001 0018 FFCF 00 FF -> +1  +24 -49 [00 -1]
	FFE8 0001 0016 FF 00 -> -24  +1 +22 [-1 00]
	FFFF FFE8 0031 00 01 -> -1  -24 +49 [00 +1]

; ---------------------- end of auxiliary code for character movement --------------------------------------

; guillermo's behavior routine
; ix pointing to guillermo's sprite
; iy points to guillermo's position data
288D: 00          nop
288E: 3E 00       ld   a,$00		; instruction modified from outside and related to 0x2e19
2890: A7          and  a
2891: 28 37       jr   z,$28CA		; if a is 0, jump
2893: 3D          dec  a
2894: C8          ret  z			; if a was 1, exit
2895: 32 8F 28    ld   ($288F),a	; guillermo's state = guillermo's state - 1
2898: FE 13       cp   $13
289A: 20 0D       jr   nz,$28A9		; if it's not 0x13, jump

; arrives here if guillermo's state is 0x13
289C: 3A B1 28    ld   a,($28B1)
289F: FE 02       cp   $02
28A1: 20 06       jr   nz,$28A9		; if the sprite is not modified with +2, jump to modify y
28A3: FD 35 02    dec  (iy+$02)		; decrement guillermo's x position
28A6: C3 27 2A    jp   $2A27		; advance sprite animation and redraw it

28A9: FE 01       cp   $01			; if the sprite's y is modified with 1, jump and mark the sprite as inactive
28AB: 28 18       jr   z,$28C5

28AD: DD 7E 02    ld   a,(ix+$02)
28B0: C6 02       add  a,$02		; modify the sprite's y position (this instruction is written from outside)
28B2: DD 77 02    ld   (ix+$02),a
28B5: DD 7E 00    ld   a,(ix+$00)
28B8: E6 3F       and  $3F
28BA: F6 80       or   $80
28BC: DD 77 00    ld   (ix+$00),a	; mark the sprite for drawing
28BF: 3E FF       ld   a,$FF
28C1: 32 C1 2D    ld   ($2DC1),a	; indicate that there has been movement
28C4: C9          ret

; arrives here if the sprite's y is modified with 1 and guillermo's state is 0x13
28C5: DD 36 00 FE ld   (ix+$00),$FE	; mark the sprite as inactive
28C9: C9          ret

; arrives here if guillermo's state is 0, which is the normal state
28CA: 3A 8F 3C    ld   a,($3C8F)	; if the camera doesn't follow guillermo, exit
28CD: A7          and  a
28CE: C0          ret  nz

28CF: 3E 08       ld   a,$08
28D1: CD 72 34    call $3472		; check if left cursor state has changed
28D4: 0E 01       ld   c,$01
28D6: C2 0C 2A    jp   nz,$2A0C		; if left cursor is pressed, rotate and redraw the sprite
28D9: 3E 01       ld   a,$01
28DB: CD 72 34    call $3472        ; check if right cursor state has changed
28DE: 0E FF       ld   c,$FF
28E0: C2 0C 2A    jp   nz,$2A0C		; if right cursor is pressed, rotate and redraw the sprite

28E3: 3E 00       ld   a,$00
28E5: CD 82 34    call $3482		; if up cursor hasn't been pressed, exit
28E8: C8          ret  z
28E9: CD B8 27    call $27B8		; check the height of the positions the character is going to move to and return them in a and c
28EC: C3 54 29    jp   $2954		; if it can move forward, update the character's sprite

; if the sprite position is central and the height is correct, put c in the positions occupied by the height buffer
;  iy = address of the position data associated with the character
;  c = value to put in the positions the character occupies in the height buffer
28EF: CD BE 0C    call $0CBE		; if the position is not one of the center of the screen or the character's height doesn't match
28F2: D8          ret  c			; the base height of the floor, CF=1, otherwise ix points to the height of the current pos

28F3: DD 7E 00    ld   a,(ix+$00)	; get the entry from the height buffer
28F6: E6 0F       and  $0F			; save the height
28F8: B1          or   c			; indicate that the character is at position (x, y)
28F9: DD 77 00    ld   (ix+$00),a	; update the height buffer
28FC: FD CB 05 7E bit  7,(iy+$05)	; if bit 7 of byte 5 is set, exit
2900: C0          ret  nz

2901: DD 7E FF    ld   a,(ix-$01)	; indicate that the character also occupies position (x - 1, y)
2904: E6 0F       and  $0F
2906: B1          or   c
2907: DD 77 FF    ld   (ix-$01),a
290A: DD 7E E8    ld   a,(ix-$18)	; indicate that the character also occupies position (x, y - 1)
290D: E6 0F       and  $0F
290F: B1          or   c
2910: DD 77 E8    ld   (ix-$18),a
2913: DD 7E E7    ld   a,(ix-$19)	; indicate that the character also occupies position (x - 1, y - 1)
2916: E6 0F       and  $0F
2918: B1          or   c
2919: DD 77 E7    ld   (ix-$19),a
291C: C9          ret

; check if the character can move where it wants and update its sprite and height buffer
; hl points to the character table to move
291D: CD F6 2B    call $2BF6		; place the parameters of this routine according to the character from table hl
2920: DD 21 17 2E ld   ix,$2E17		; point to the character sprites (instruction modified from outside)
2924: CD B0 2A    call $2AB0		; put the current position and dimensions of the sprite as old position and dimensions
2927: FD 21 36 30 ld   iy,$3036		; point to the position data of the characters (instruction modified from outside)
292B: 0E 00       ld   c,$00
292D: DD E5       push ix
292F: CD EF 28    call $28EF		; if the sprite position is central and the height is correct, clear the positions the sprite occupied in the height buffer
2932: DD E1       pop  ix
2934: 3A 84 43    ld   a,($4384)	; if malaquias is ascending when dying
2937: A7          and  a
2938: 3E 00       ld   a,$00
293A: 32 84 43    ld   ($4384),a	; set the variable to 0
293D: CD 45 29    call $2945
2940: FD 4E 0E    ld   c,(iy+$0e)	; read the value to put in the height buffer to indicate the character is there
2943: 18 AA       jr   $28EF		; if the sprite position is central and the height is correct, put c in the positions the height buffer occupies

2945: C2 27 2A    jp   nz,$2A27		; if malaquias is ascending when dying
2948: FD 7E 00    ld   a,(iy+$00)
294B: E6 01       and  $01
294D: C2 01 2A    jp   nz,$2A01		; if it's in the middle of a movement, increment the counter of bits 0 and 1 of byte 0, advance sprite animation and redraw it
2950: 21 8D 28    ld   hl,$288D		; address of the routine to execute for the character's behavior (instruction modified from outside)
2953: E9          jp   (hl)			; execute the character's behavior


; routine called to see if the character advances
; in a and c the height differences to the position it wants to advance to are passed
2954: FD CB 05 A6 res  4,(iy+$05)	; set to 0 the bit indicating if the character is going down or up
2958: FD CB 05 7E bit  7,(iy+$05)
295C: FD 5E 04    ld   e,(iy+$04)	; e = character's height
295F: 28 56       jr   z,$29B7		; if the character occupies 4 positions, jump

; arrives here if the character occupies a single position
;  a = height difference with the position closest to the character according to orientation
;  c = height difference with the character's position + 2 (according to its orientation)
2961: 57          ld   d,a			; d = height difference with the position closest to the character according to orientation
2962: 79          ld   a,c			; if at the character's position + 2 (according to its orientation) there is a character, exit
2963: FE 10       cp   $10			; if trying to advance to a position where there is a character, exit
2965: C8          ret  z
2966: FE 20       cp   $20
2968: C8          ret  z

2969: 7A          ld   a,d			; a = height difference with the position closest to the character according to orientation
296A: FD CB 05 6E bit  5,(iy+$05)	; if the character is not turned in the direction of going up or down the slope, jump
296E: 28 0D       jr   z,$297D

2970: 47          ld   b,a
2971: CD AE 29    call $29AE		; return 0 if the character's orientation is 0 or 3, otherwise return 1
2974: 78          ld   a,b			; when going right or down, converting the position to 4, there is only a difference of 1
2975: 28 01       jr   z,$2978		;  however, if going in the other directions when converting the position to 4 there is a diff of 2
2977: 79          ld   a,c			; a = height difference with the character's position + 2 (according to its orientation)
2978: A7          and  a
2979: C0          ret  nz			; if not at ground level, exit?
297A: C3 FE 29    jp   $29FE

; jumps here if bit 5 is 0. Arrives with:
;  a = height difference with the position closest to the character according to orientation
;  c = height difference with the character's position + 2 (according to its orientation)
297D: FD 34 04    inc  (iy+$04)		; increment the character's height
2980: FE 01       cp   $01
2982: 28 0D       jr   z,$2991		; if going up one unit, jump
2984: FD 35 04    dec  (iy+$04)		; undo the increment
2987: FE FF       cp   $FF			; if not going down one unit, exit
2989: C0          ret  nz
298A: FD CB 05 E6 set  4,(iy+$05)	; indicate that it's going down
298E: FD 35 04    dec  (iy+$04)		; decrement the character's height

2991: B9          cp   c			; compare the height of the position closest to the character with the next one
2992: 20 60       jr   nz,$29F4		;  if the heights are not equal, advance the position

; arrives here if advancing and the 2 following positions have the same height
2994: FD 7E 05    ld   a,(iy+$05)	; only keep bit 4 active, so the character goes from occupying one position in the buffer
2997: E6 10       and  $10			;  of heights to occupying 4
2999: FD 77 05    ld   (iy+$05),a
299C: E5          push hl
299D: CD E4 29    call $29E4		; update the character's x and y position according to the orientation it's advancing towards
29A0: E1          pop  hl
29A1: CD AE 29    call $29AE		; return 0 if the character's orientation is 0 or 3, otherwise return 1
29A4: CC E4 29    call z,$29E4		; update the character's x and y position according to the orientation it's advancing towards
29A7: 3E FF       ld   a,$FF
29A9: 32 C1 2D    ld   ($2DC1),a	; indicate that there has been movement
29AC: 18 53       jr   $2A01		; increment the counter of bits 0 and 1 of byte 0, advance sprite animation and redraw it

; return 0 if the character's orientation is 0 or 3, otherwise return 1
29AE: FD 7E 01    ld   a,(iy+$01)
29B1: E6 03       and  $03
29B3: C8          ret  z
29B4: EE 03       xor  $03
29B6: C9          ret

; jumps here if the character occupies 4 positions. Arrives with:
;  a = height difference with position 1 closest to the character according to orientation
;  c = height difference with position 2 closest to the character according to orientation
29B7: FE 01       cp   $01
29B9: 28 08       jr   z,$29C3		; if going upward, jump
29BB: FE FF       cp   $FF
29BD: 28 0B       jr   z,$29CA		; if going downward, jump
29BF: A7          and  a
29C0: C0          ret  nz			; otherwise, exit if wanting to go up or down more than one unit
29C1: 18 31       jr   $29F4		; if not changing height, update position according to advance direction, increment the counter of bits 0 and 1 of byte 0, advance sprite animation and redraw it

; arrives here if going up
29C3: FD 34 04    inc  (iy+$04)		; increment the character's height
29C6: 3E 80       ld   a,$80		; change the size occupied in the height buffer from 4 to 1
29C8: 18 05       jr   $29CF

; arrives here if going down
29CA: FD 35 04    dec  (iy+$04)		; decrement the character's height
29CD: 3E 90       ld   a,$90		; change the size occupied in the height buffer from 4 to 1 and indicate going down

29CF: FD 77 05    ld   (iy+$05),a
29D2: E5          push hl
29D3: CD E4 29    call $29E4		; update the character's x and y position according to the orientation it's advancing towards
29D6: E1          pop  hl
29D7: CD AE 29    call $29AE		; return 0 if the character's orientation is 0 or 3, otherwise return 1
29DA: C4 E4 29    call nz,$29E4		; update the character's x and y position according to the orientation it's advancing towards
29DD: 3E FF       ld   a,$FF
29DF: 32 C1 2D    ld   ($2DC1),a	; indicate that there has been movement
29E2: 18 1D       jr   $2A01		; increment the counter of bits 0 and 1 of byte 0, advance sprite animation and redraw it

; update the character's x and y position according to the orientation it's advancing towards
29E4: 7E          ld   a,(hl)		; read the increment in x for the current orientation
29E5: FD 86 02    add  a,(iy+$02)
29E8: FD 77 02    ld   (iy+$02),a	; modify the character's x position
29EB: 23          inc  hl
29EC: 7E          ld   a,(hl)		; read the increment in y for the current orientation
29ED: FD 86 03    add  a,(iy+$03)
29F0: FD 77 03    ld   (iy+$03),a	; modify the character's y position
29F3: C9          ret

; update position according to advance direction, increment the counter of bits 0 and 1 of byte 0, advance sprite animation and redraw it
; jumps here if the heights of the 2 positions are not equal. Arrives with:
;  a = height difference with the position closest to the character according to orientation
;  c = height difference with the character's position + 2 (according to its orientation)
29F4: 91          sub  c			; calculate the height difference
29F5: 3C          inc  a
29F6: FE 03       cp   $03			; if the height difference is -1,0 or 1, CF = 0
; ??? why is the comparison done if there is an unconditional jump???
29F8: 18 04       jr   $29FE		; update position according to advance direction, increment the counter of bits 0 and 1 of byte 0, advance sprite animation and redraw it

29FA: FD 73 04    ld   (iy+$04),e	; ??? this is never reached
29FD: C9          ret

; update position according to advance direction, increment the counter of bits 0 and 1 of byte 0, advance sprite animation and redraw it
29FE: CD E4 29    call $29E4		; update the character's x and y position according to the orientation it's advancing towards

; increment the counter of bits 0 and 1 of byte 0, advance sprite animation and redraw it
2A01: FD 7E 00    ld   a,(iy+$00)	; increment the counter of bits 0 and 1
2A04: 3C          inc  a
2A05: E6 03       and  $03
2A07: FD 77 00    ld   (iy+$00),a
2A0A: 18 1B       jr   $2A27		; advance sprite animation and redraw it

; arrives here if right or left cursor has been pressed
; c = 1 if left cursor was pressed or -1 if right cursor was pressed
; iy points to the character's position data
2A0C: FD 36 00 00 ld   (iy+$00),$00	; reset the animation counter
2A10: FD CB 05 7E bit  7,(iy+$05)
2A14: 28 08       jr   z,$2A1E		; if the character occupies more than one cell in the height buffer, jump
2A16: FD 7E 05    ld   a,(iy+$05)
2A19: EE 20       xor  $20
2A1B: FD 77 05    ld   (iy+$05),a
2A1E: FD 7E 01    ld   a,(iy+$01)	; change the character's orientation
2A21: 81          add  a,c
2A22: E6 03       and  $03
2A24: FD 77 01    ld   (iy+$01),a

; advance sprite animation and redraw it
2A27: CD 61 2A    call $2A61		; change monk robe animation according to position and animation counter and get the address of the
								;  animation data to put in hl
2A2A: 3E FF       ld   a,$FF
2A2C: 32 C1 2D    ld   ($2DC1),a	; indicate that there has been movement
2A2F: E5          push hl
2A30: CD C9 2A    call $2AC9		; check if the sprite is visible and if so, update its position

; only arrives here if the sprite is visible
2A33: E1          pop  hl

; arrives here from outside if a sprite is visible, after having updated its position.
;  hl points to the corresponding animation
;  ix = address of the corresponding sprite
;  iy = position data of the corresponding character
;  c = sprite's y position on screen
2A34: 7E          ld   a,(hl)
2A35: DD 77 07    ld   (ix+$07),a	; update the sprite graphics address with the current animation
2A38: 23          inc  hl
2A39: 7E          ld   a,(hl)
2A3A: DD 77 08    ld   (ix+$08),a
2A3D: 23          inc  hl
2A3E: 7E          ld   a,(hl)
2A3F: DD 77 05    ld   (ix+$05),a	; update the sprite width and height according to the current animation
2A42: 23          inc  hl
2A43: 7E          ld   a,(hl)
2A44: DD 77 06    ld   (ix+$06),a
2A47: 3E 80       ld   a,$80		; indicate that the sprite needs to be redrawn
2A49: B1          or   c			; combine the value with the sprite's y position on screen
2A4A: DD 77 00    ld   (ix+$00),a
2A4D: FD 7E 01    ld   a,(iy+$01)	; read the character's orientation
2A50: CD 80 24    call $2480		; modify the orientation passed in a with the current screen's orientation
2A53: CB 3F       srl  a
2A55: FD AE 06    xor  (iy+$06)		; check if the character's orientation has changed
2A58: C4 3B 35    call nz,$353B		; if so, jump to the corresponding method (this call is modified from outside) in case graphics need to be flipped
2A5B: 3E FF       ld   a,$FF
2A5D: 32 C1 2D    ld   ($2DC1),a	; indicate that there has been movement
2A60: C9          ret

; change monk robe animation according to position and animation counter and get the address of the
;  animation data to put in hl
;  ix = address of the corresponding sprite
;  iy = position data of the corresponding character
; on exit hl saves the index in the animation table
2A61: FD 5E 00    ld   e,(iy+$00)	; get the character's animation
2A64: FD 7E 01    ld   a,(iy+$01)	; get the character's orientation
2A67: CD 80 24    call $2480		; modify the orientation passed in a with the current screen's orientation
2A6A: 57          ld   d,a			; save the character's orientation on the current screen
2A6B: 87          add  a,a
2A6C: 87          add  a,a			; shift the orientation 2 to the left and combine it with the animation
2A6D: B3          or   e			;  to get the monk robe animation
2A6E: 6F          ld   l,a			; save the animation in l
2A6F: DD 7E 0B    ld   a,(ix+$0b)	; read the old value and keep only the bits that are not from the animation
2A72: E6 F0       and  $F0
2A74: B5          or   l
2A75: DD 77 0B    ld   (ix+$0b),a	; combine the previous value with the robe animation
2A78: 7A          ld   a,d			; recover the character's orientation on the current screen
2A79: 3C          inc  a
2A7A: E6 02       and  $02			; a indicates if the character is facing right or left
2A7C: 87          add  a,a			; shift 1 bit to the left
2A7D: B3          or   e			; combine with the current animation number
2A7E: 87          add  a,a			; shift 2 bits to the left (x and y animations are separated by 8 entries)
2A7F: 87          add  a,a
2A80: 6F          ld   l,a			; a = 0 0 0 (if moving in x, 0, if moving in y, 1) (animation sequence number (2 bits)) 0 0
2A81: 26 00       ld   h,$00		; hl = index in the animation table
2A83: 11 9F 31    ld   de,$319F		; instruction modified from outside (with the address of the animation table for the character)
2A86: 7A          ld   a,d
2A87: E6 C0       and  $C0
2A89: FE C0       cp   $C0
2A8B: 28 02       jr   z,$2A8F		; if the address put in the modified instruction starts with 0xc0, jump
2A8D: 19          add  hl,de		; index into the table
2A8E: C9          ret

; arrives here if the address put in the modified instruction starts with 0xc0
; hl = index in the animation table
; e has the monk number
2A8F: 7B          ld   a,e			; a = monk number (0, 2, 4 or 6)
2A90: EB          ex   de,hl		; de = index in the animation table
2A91: 21 DF 31    ld   hl,$31DF		; point to the monks' animation table
2A94: 19          add  hl,de		; index into the animation table
2A95: E5          push hl			; save the animation table address
2A96: 21 97 30    ld   hl,$3097		; point to the table with the monks' faces (each entry occupies 2 bytes)
2A99: CD 2D 16    call $162D		; hl = hl + a
2A9C: 7E          ld   a,(hl)
2A9D: 23          inc  hl
2A9E: 66          ld   h,(hl)
2A9F: 6F          ld   l,a			; hl = [hl] (pointer to the face data of the monk passed in a)
2AA0: 7B          ld   a,e
2AA1: E6 10       and  $10
2AA3: 28 04       jr   z,$2AA9		; depending on whether moving in x or y, put one head
2AA5: 11 32 00    ld   de,$0032		;  if bit 4 is 1 (moving in y), get the second face
2AA8: 19          add  hl,de
2AA9: EB          ex   de,hl		; de points to the face data
2AAA: E1          pop  hl			; recover the animation table address
2AAB: 73          ld   (hl),e
2AAC: 23          inc  hl
2AAD: 72          ld   (hl),d		; overwrite the first 2 bytes of the animation table entry with the face address
2AAE: 2B          dec  hl
2AAF: C9          ret

; put the current position and dimensions as old position and dimensions
2AB0: DD 7E 01    ld   a,(ix+$01)	; copy the current position in x and y as the old position
2AB3: DD 77 03    ld   (ix+$03),a
2AB6: DD 7E 02    ld   a,(ix+$02)
2AB9: DD 77 04    ld   (ix+$04),a
2ABC: DD 7E 05    ld   a,(ix+$05)	; copy the current sprite width and height as the old width and height
2ABF: DD 77 09    ld   (ix+$09),a
2AC2: DD 7E 06    ld   a,(ix+$06)
2AC5: DD 77 0A    ld   (ix+$0a),a
2AC8: C9          ret

2AC9: CD DD 2A    call $2ADD			; check if it's visible and if so, update its position if necessary. If it's visible it doesn't return, but exits to the calling routine

; arrives here if the sprite is not visible
2ACC: E1          pop  hl				; remove from stack the return address and the animation table address and exit
2ACD: E1          pop  hl

2ACE: DD 7E 00    ld   a,(ix+$00)		; if the sprite was not visible, exit
2AD1: FE FE       cp   $FE
2AD3: C8          ret  z
2AD4: DD 36 00 80 ld   (ix+$00),$80		; otherwise, indicate that the sprite needs to be redrawn
2AD8: DD CB 05 FE set  7,(ix+$05)		; indicate that the sprite is going to become inactive, and only want to redraw the area it occupied
2ADC: C9          ret

; check if the sprite is within the visible screen area. If not, exit. If it's within the visible area transform it
; to another coordinate system. Depending on a parameter it continues or not. If it continues update the position according to orientation
; if not visible, exit. If visible, exit twice (2 stack pops)
; iy points to the associated character's position data
; ix points to the associated sprite
2ADD: FD 7E 02    ld   a,(iy+$02)	; get the character's X coordinate
2AE0: D6 00       sub  $00			; modified from outside (4 most significant bits of the current screen's X position - 12)
2AE2: D8          ret  c			; if the object in X is < visible lower limit of X, exit
2AE3: FE 28       cp   $28
2AE5: D0          ret  nc			; if the object in X is >= visible upper limit of X, exit
2AE6: 6F          ld   l,a			; l = X coordinate of the object on the screen
2AE7: FD 7E 03    ld   a,(iy+$03)	; gets the Y coordinate of the character
2AEA: D6 00       sub  $00			; modified from outside (4 most significant bits of the Y position of the current screen - 12)
2AEC: D8          ret  c			; if the object in Y is < visible lower limit of Y, exits
2AED: FE 28       cp   $28
2AEF: D0          ret  nc			; if the object in Y is >= visible upper limit of Y, exits
2AF0: 67          ld   h,a			; h = Y coordinate of the object on the screen
2AF1: FD 7E 04    ld   a,(iy+$04)	; gets the height of the character
2AF4: CD 73 24    call $2473		; depending on the height, returns the base height of the floor in b
2AF7: 78          ld   a,b
2AF8: FE 00       cp   $00			; modified from outside (base height of the current screen)
2AFA: C0          ret  nz			; if the object is not on the same floor, exits
2AFB: FD 7E 04    ld   a,(iy+$04)
2AFE: 90          sub  b
2AFF: 47          ld   b,a			; b = object height adjusted for this screen

; upon arriving here the parameters are:
; l = X coordinate of the object on the grid
; h = Y coordinate of the object on the grid
; b = object height on the grid adjusted for this floor
2B00: CD 8A 24    call $248A		; routine that changes the coordinate system depending on screen orientation (this call is modified from outside)
2B03: DD 75 12    ld   (ix+$12),l	; saves the new x and y coordinates in the sprite
2B06: DD 74 13    ld   (ix+$13),h

; converts grid coordinates to screen coordinates
2B09: 7C          ld   a,h
2B0A: 85          add  a,l
2B0B: 4F          ld   c,a			; c = pos x + pos y = y coordinate on screen
2B0C: 90          sub  b			; subtracts the height (the taller the object, the lower y it has on screen)
2B0D: D8          ret  c			; if calculated y < 0, exits
2B0E: D6 06       sub  $06			; y calc = y calc - 6 (shifts 6 units up)
2B10: D8          ret  c			; if y calc < 0, exits
2B11: FE 08       cp   $08
2B13: D8          ret  c			; if y calc < 8, exits
2B14: FE 3A       cp   $3A
2B16: D0          ret  nc			; if y calc  >= 58, exits

; arrives here if y calc is between 8 and 57
2B17: 3C          inc  a			; a = y calc + 1
2B18: 87          add  a,a
2B19: 87          add  a,a			; a = 4*(y calc + 1)
2B1A: 47          ld   b,a			; b = 4*(y calc + 1)
2B1B: 7D          ld   a,l			; a = pos x
2B1C: 94          sub  h			; a = pos x - pos y = x coordinate on screen
2B1D: 87          add  a,a			; a = 2*(pos x - pos y)
2B1E: C6 50       add  a,$50		; a = 2*(pos x - pos y) + 80
2B20: D6 28       sub  $28			; 0x28 = 40
2B22: D8          ret  c
2B23: FE 50       cp   $50			; 0x50 = 80
2B25: D0          ret  nc

2B26: 6F          ld   l,a			; l = pos x with new coordinate system
2B27: 60          ld   h,b			; h = pos y with new coordinate system

2B28: D1          pop  de			; gets the return address
2B29: 79          ld   a,c			; a = pos x + pos y = y coordinate on screen
2B2A: D6 10       sub  $10			; a = y coordinate on screen - 16
2B2C: 30 01       jr   nc,$2B2F		; if position in y < 16, pos y = 0
2B2E: AF          xor  a
2B2F: 00          nop				; modified from outside (either ret or nop)

; if it reaches here it modifies the sprite position on screen
2B30: 4F          ld   c,a
2B31: 06 00       ld   b,$00		; b = first entry
2B33: FD 7E 05    ld   a,(iy+$05)
2B36: CB 7F       bit  7,a
2B38: 20 3E       jr   nz,$2B78		; if the character occupies one position, jumps

2B3A: FD CB 00 46 bit  0,(iy+$00)	; reads bit 0 of the animation counter
2B3E: 28 01       jr   z,$2B41		; if it's 1, advances to the next entry
2B40: 04          inc  b

2B41: ED 5B 84 2D ld   de,($2D84)	; gets an address related to screen orientation and table 0x309f
2B45: FD 7E 01    ld   a,(iy+$01)	; gets the character orientation
2B48: CD 80 24    call $2480		; modifies the orientation passed in a with the current screen orientation
2B4B: 0F          rrca				; shifts the orientation 4 bits to the left (each table entry is 16 bytes)
2B4C: 0F          rrca
2B4D: 0F          rrca
2B4E: 0F          rrca
2B4F: E6 30       and  $30			; a = orientation*16
2B51: 80          add  a,b			; a = orientation*16 + 2*b
2B52: 80          add  a,b
2B53: 83          add  a,e			; de = de + a
2B54: 5F          ld   e,a
2B55: 8A          adc  a,d
2B56: 93          sub  e
2B57: 57          ld   d,a

2B58: 1A          ld   a,(de)		; reads a byte from the table
2B59: 85          add  a,l			; adds the x of the new coordinate system
2B5A: FD 86 07    add  a,(iy+$07)	; adds an offset
2B5D: 6F          ld   l,a			; updates x
2B5E: 13          inc  de
2B5F: 1A          ld   a,(de)		; reads a byte from the table
2B60: 84          add  a,h			; adds the y of the new coordinate system
2B61: FD 86 08    add  a,(iy+$08)	; adds an offset
2B64: 67          ld   h,a			; updates y
2B65: DD 75 01    ld   (ix+$01),l	; saves the x position of the sprite (in bytes)
2B68: DD 74 02    ld   (ix+$02),h	; saves the y position of the sprite (in pixels)
2B6B: DD 7E 00    ld   a,(ix+$00)
2B6E: FE FE       cp   $FE
2B70: C0          ret  nz			; if the sprite is not visible, continues
2B71: DD 75 03    ld   (ix+$03),l	; saves the previous x position of the sprite (in bytes)
2B74: DD 74 04    ld   (ix+$04),h	; saves the previous y position of the sprite (in pixels)
2B77: C9          ret

; arrives here if the character occupies one position (because it's on the stairs)
2B78: 04          inc  b
2B79: 04          inc  b			; advances to the third entry
2B7A: FD CB 05 6E bit  5,(iy+$05)
2B7E: 20 BA       jr   nz,$2B3A		; if not oriented to go up or down the stairs, jumps
2B80: 04          inc  b			; advances to the fifth entry
2B81: 04          inc  b

; arrives here if the character occupies one position and is oriented to go up or down the stairs (already pointing to 5th entry)
2B82: FD 7E 05    ld   a,(iy+$05)
2B85: E6 03       and  $03
2B87: 20 10       jr   nz,$2B99		; does this ever happen???
2B89: FD CB 00 46 bit  0,(iy+$00)	; reads bit 0 of the animation counter
2B8D: 28 B2       jr   z,$2B41
2B8F: 04          inc  b			; advances to the sixth entry

2B90: FD CB 05 66 bit  4,(iy+$05)	; checks if going down
2B94: 28 AB       jr   z,$2B41
2B96: 04          inc  b			; advances one entry
2B97: 18 A8       jr   $2B41

; ??? when does it arrive here???
2B99: 04          inc  b			; advances to the eighth entry
2B9A: 04          inc  b
2B9B: 04          inc  b
2B9C: FD CB 05 76 bit  6,(iy+$05)
2BA0: 20 04       jr   nz,$2BA6
2BA2: 04          inc  b			; advances to the 12th entry
2BA3: 04          inc  b
2BA4: 04          inc  b
2BA5: 04          inc  b
2BA6: FE 01       cp   $01			; if bits 0 and 1 of (iy+05) != 1, jumps (entry 12 or 13)
2BA8: 20 E6       jr   nz,$2B90
2BAA: 04          inc  b			; advances to the 14th entry
2BAB: 04          inc  b
2BAC: 18 E2       jr   $2B90		; jumps (entry 14 or 15)

; table with data to move the characters
; the table has 6 entries of 10 bytes with the format:
; byte 0-1: address of the sprite associated with the character
; byte 2-3: address to the position data of the character associated with the sprite
; byte 4-5: address of the routine where the character thinks
; byte 6-7: routine to call if graphics need to be flipped
; byte 8-9: address of the animation table for the character
2BAE:	2E17 3036 288D 353B	319F	; guillermo
2BB8:	2E2B 3045 2C3A 34E2	31BF	; adso
2BC2:	2E3F 3054 2C3A 34FB C000	; malaquias
2BCC:	2E53 3063 2C3A 350B	C002	; the abbot
2BD6:	2E67 3072 2C3A 351B C004	; berengario
2BE0:	2E7B 3081 2C3A 352B C006	; severino
	FFFF

; table of pointers to the routine parameters
2BEC: 	2922 -> where to copy the address of the current character's sprite
	2929 -> where to copy the address of the current character's data
	2951 -> where to copy the address of the behavior routine
	2A59 -> where to copy the routine to call to flip the graphics
	2A84 -> where to copy the address of the animation table for the character

; sets the parameters of the 0x2920 routine for the current character
2BF6: 06 05       ld   b,$05		; 5 values
2BF8: DD 21 EC 2B ld   ix,$2BEC		; points to the table of addresses of the routine parameters
2BFC: DD 5E 00    ld   e,(ix+$00)	; de = [ix]
2BFF: DD 56 01    ld   d,(ix+$01)
2C02: DD 23       inc  ix
2C04: DD 23       inc  ix
2C06: 7E          ld   a,(hl)		; reads a value from hl and copies it to de
2C07: 12          ld   (de),a
2C08: 23          inc  hl
2C09: 13          inc  de
2C0A: 7E          ld   a,(hl)
2C0B: 12          ld   (de),a
2C0C: 23          inc  hl
2C0D: 10 ED       djnz $2BFC		; repeats until all values are done
2C0F: C9          ret


; reads a bit of data from the character's commands and puts it in the CF
2C10: FD 7E 09    ld   a,(iy+$09)	; if iy+09 != 0, jumps
2C13: A7          and  a
2C14: 20 13       jr   nz,$2C29

; enters here if the counter of bits 0-2 of iy+09 is 0, and bit 7 of iy+0x09 is not 1
2C16: FD 7E 0C    ld   a,(iy+$0c)	; at 0x0c and 0x0d a pointer to the character's movement commands data is saved
2C19: FD 86 0B    add  a,(iy+$0b)	; at 0x0b is the index within the commands
2C1C: FD 34 0B    inc  (iy+$0b)
2C1F: 6F          ld   l,a
2C20: FD 8E 0D    adc  a,(iy+$0d)
2C23: 95          sub  l
2C24: 67          ld   h,a			; hl = dir(iy+0x0c-iy+0x0d)[iy+0x0b]
2C25: 7E          ld   a,(hl)
2C26: FD 77 0A    ld   (iy+$0a),a	; gets a new command byte and saves it

2C29: FD 7E 09    ld   a,(iy+$09)	; increments the counter of bits 0-2
2C2C: 3C          inc  a
2C2D: E6 07       and  $07
2C2F: FD 77 09    ld   (iy+$09),a
2C32: FD 7E 0A    ld   a,(iy+$0a)	; shifts the command bits to the left one position
2C35: 87          add  a,a
2C36: FD 77 0A    ld   (iy+$0a),a
2C39: C9          ret

; executes movement commands for adso and for the monks
; ix that points to the character's sprite
; iy points to the character's position data
2C3A: FD CB 09 7E bit  7,(iy+$09)	; if there are no commands in the buffer, exits
2C3E: C0          ret  nz

2C3F: CD 83 27    call $2783		; returns the address to calculate the height of neighboring positions according to the size of the character's position and orientation
2C42: 11 06 00    ld   de,$0006
2C45: 19          add  hl,de		; points to the amount to add to the position if the character keeps advancing in that direction
2C46: E5          push hl
2C47: CD 5C 2D    call $2D5C		; prepares for copying character data to buffer
2C4A: ED B0       ldir				; copies the data to buffer (0x02-0x0b)
2C4C: CD B8 2C    call $2CB8		; reads a command from the character into c
2C4F: E1          pop  hl
2C50: 79          ld   a,c			; a = command read
2C51: 0E 01       ld   c,$01		; c = +1
2C53: FE 03       cp   $03
2C55: CA 0C 2A    jp   z,$2A0C		; if got a 3, turn left
2C58: 0E FF       ld   c,$FF		; c = -1
2C5A: FE 02       cp   $02
2C5C: CA 0C 2A    jp   z,$2A0C		; if got a 2, turn right

2C5F: FD CB 05 7E bit  7,(iy+$05)	; if the character occupies a single position in the height buffer, jumps
2C63: 20 12       jr   nz,$2C77

; arrives here if the character occupies 4 positions in the height buffer, and with c = -1
2C65: FE 01       cp   $01
2C67: 20 04       jr   nz,$2C6D		; if the command was not 1, jumps
2C69: AF          xor  a
2C6A: C3 A0 2C    jp   $2CA0		; if got a one, jumps to check if can move in that direction and if not, restores the character's position state

; arrives here with c = -1 if the character occupies a single position in the height buffer or if got something different from one and the character occupies 4 tile buffer positions
2C6D: FE 05       cp   $05
2C6F: 3E FF       ld   a,$FF
2C71: 28 2D       jr   z,$2CA0		; checks if can move in that direction and if not, restores the character's position state
2C73: 3E 01       ld   a,$01
2C75: 18 29       jr   $2CA0		; checks if can move in that direction and if not, restores the character's position state

; arrives here with c = -1 if the character occupies a single position in the height buffer
2C77: A7          and  a
2C78: 20 10       jr   nz,$2C8A		; if didn't get a 0, jumps
2C7A: FD CB 05 6E bit  5,(iy+$05)
2C7E: 28 04       jr   z,$2C84		; if bit 5 is 0 (if not rotated on a slope), jumps
2C80: AF          xor  a
2C81: 4F          ld   c,a			; a and c = 0
2C82: 18 1C       jr   $2CA0		; otherwise, checks if can move in that direction and if not, restores the character's position state

; arrives here if the character occupies one position, got a 0 and bit 5 was 0 (if not rotated on a slope)
2C84: 0E 02       ld   c,$02
2C86: 3E 01       ld   a,$01
2C88: 18 16       jr   $2CA0		; checks if can move in that direction and if not, restores the character's position state

; arrives here if the character occupies one position, and didn't get a 0
2C8A: FE 01       cp   $01
2C8C: 20 06       jr   nz,$2C94		; if didn't get a 1, jumps
2C8E: 0E FE       ld   c,$FE
2C90: 3E FF       ld   a,$FF
2C92: 18 0C       jr   $2CA0		; checks if can move in that direction and if not, restores the character's position state

; arrives here if the character occupies one position, and didn't get a 0 or a 1
2C94: FE 04       cp   $04
2C96: 20 05       jr   nz,$2C9D		; if didn't get a 4, jumps
2C98: 0E 01       ld   c,$01
2C9A: 79          ld   a,c

2C9B: 18 03       jr   $2CA0		; checks if can move in that direction and if not, restores the character's position state
2C9D: 0E FF       ld   c,$FF
2C9F: 79          ld   a,c

; checks if can move in that direction and if not, restores the character's position state
; in a passes the height difference to where it moves, which will be used if the character is not on the current screen
2CA0: 47          ld   b,a
2CA1: AF          xor  a
2CA2: 32 C1 2D    ld   ($2DC1),a	; indicates that for now there is no movement
2CA5: 78          ld   a,b
2CA6: CD B8 27    call $27B8		; checks the height of the positions the character is going to move to and returns them in a and c
								; if the character is not on the screen being shown, a = what was passed
2CA9: CD 54 29    call $2954		; if can move forward, updates the character's sprite
2CAC: 3A C1 2D    ld   a,($2DC1)	; if the character has moved, exits
2CAF: A7          and  a
2CB0: C0          ret  nz
2CB1: CD 5C 2D    call $2D5C		; otherwise, prepares for copying character data to buffer
2CB4: EB          ex   de,hl
2CB5: ED B0       ldir				; restores the original data since it couldn't move
2CB7: C9          ret

; reads and interprets the commands passed to the character. According to the bits it reads, values are returned:
; * if the character occupies 4 positions:
;   if reads 1 -> returns c = 1 -> tries to advance one position forward (with a = 0 and c = -1) -> advances
;   if reads 010 -> returns c = 2 -> turns right
;   if reads 011 -> returns c = 3 -> turns left
;   if reads 0010 -> returns c = 4 -> tries to advance one position forward (with a = 1 and c = -1) -> goes up (and comes to occupy one position)
;   if reads 0011 -> returns c = 5 -> tries to advance one position forward (with a = -1 and c = -1) -> goes down (and comes to occupy one position)
;   if reads 0001 -> sets bit 7,(9) and exits 2 routines outward
;   if reads 0000 -> resets the counter, the index, enables commands, and processes another command
; * if the character occupies 1 position:
;   if reads 10 -> returns c = 0 -> 	if bit 5 = 1, tries to advance one position forward (with a = 0 and c = 0) -> advances
;									if bit 5 = 0, goes up (and continues occupying one position) (with a = 1 and c = 2)
;   if reads 11 -> returns c = 1 -> goes down (and continues occupying one position) (with a = -1 and c = -2)
;   if reads 010 -> returns c = 2 -> turns right
;   if reads 011 -> returns c = 3 -> turns left
;   if reads 0010 -> returns c = 4 -> goes up (and comes to occupy 4 positions) (with a = 1 and c = 1)
;   if reads 0011 -> returns c = 5 -> goes down (and comes to occupy 4 positions) (with a = -1 and c = -1)
;   if reads 0001 -> sets bit 7,(9) and exits 2 routines outward
;   if reads 0000 -> exits with c = 0
2CB8: FD CB 05 7E bit  7,(iy+$05)	; if the character occupies 4 positions in the height buffer, jumps
2CBC: 28 0D       jr   z,$2CCB

; arrives here if the character occupies one position in the height buffer
2CBE: CD 10 2C    call $2C10		; reads a bit of data from the character's commands and puts it in the CF
2CC1: 30 0B       jr   nc,$2CCE		; if read a 0, jumps to process the rest as if it were 4 positions
2CC3: CD 10 2C    call $2C10		; reads a bit of data from the character's commands and puts it in the CF
2CC6: 0E 00       ld   c,$00
2CC8: CB 11       rl   c			; c = (c << 1) | CF
2CCA: C9          ret

; arrives here if the character occupies 4 positions in the height buffer
2CCB: CD 10 2C    call $2C10		; reads a bit of data from the character's commands and puts it in the CF

2CCE: 0E 01       ld   c,$01
2CD0: D8          ret  c			; if read a 1, exits

2CD1: CD 10 2C    call $2C10		; reads a bit of data from the character's commands and puts it in the CF
2CD4: 30 06       jr   nc,$2CDC		; if read a 0, jumps
2CD6: CD 10 2C    call $2C10		; reads a bit of data from the character's commands and puts it in the CF
2CD9: CB 11       rl   c			; c = (c << 1) | CF
2CDB: C9          ret

2CDC: CB 11       rl   c			; c = (c << 1) | CF
2CDE: CD 10 2C    call $2C10		; reads a bit of data from the character's commands and puts it in the CF
2CE1: 38 F3       jr   c,$2CD6		; if read a 1, jumps
2CE3: CD 10 2C    call $2C10		; reads a bit of data from the character's commands and puts it in the CF
2CE6: 38 11       jr   c,$2CF9		; if read a 1, jumps

2CE8: 0E 00       ld   c,$00
2CEA: FD CB 05 7E bit  7,(iy+$05)	; if it's a character that occupies only one position in the position buffer, exits
2CEE: C0          ret  nz
2CEF: FD 36 0B 00 ld   (iy+$0b),$00 ; resets the counter, the index and enables commands
2CF3: FD 36 09 00 ld   (iy+$09),$00
2CF7: 18 BF       jr   $2CB8

2CF9: FD CB 09 FE set  7,(iy+$09)	; indicates that commands have finished and exits 2 routines outward
2CFD: E1          pop  hl
2CFE: E1          pop  hl
2CFF: C9          ret

; saves in 0x156a-0x156b the address of screen data a
2D00: 32 BD 2D    ld   ($2DBD),a	; saves the current screen
2D03: 21 00 40    ld   hl,$4000
2D06: A7          and  a
2D07: 28 15       jr   z,$2D1E		; if the current screen is not defined (or is number 0), jumps
2D09: F3          di
2D0A: 01 C7 7F    ld   bc,$7FC7		; loads abadia8
2D0D: ED 49       out  (c),c

2D0F: 47          ld   b,a			; b = screen to search for
2D10: 7E          ld   a,(hl)		; the first byte indicates the length of the screen in bytes
2D11: 85          add  a,l
2D12: 6F          ld   l,a
2D13: 8C          adc  a,h
2D14: 95          sub  l
2D15: 67          ld   h,a			; increments the pointer according to the screen size
2D16: 10 F8       djnz $2D10		; repeats until reaching the desired screen

2D18: 01 C0 7F    ld   bc,$7FC0		; restores the configuration
2D1B: ED 49       out  (c),c
2D1D: FB          ei
2D1E: 22 6A 15    ld   ($156A),hl	; saves the address of the current screen data
2D21: C9          ret

; fills the height buffer indicated by 0x2d8a with data read from abadia7 and cropped for the character's screen passed in iy
2D22: 2A 8A 2D    ld   hl,($2D8A)	; hl = gets the height buffer to fill
2D25: 54          ld   d,h
2D26: 5D          ld   e,l
2D27: 13          inc  de
2D28: 01 3F 02    ld   bc,$023F		; clears 576 bytes (24x24) = (4 + 16 + 4)x2
2D2B: 36 00       ld   (hl),$00
2D2D: ED B0       ldir

2D2F: CD 8F 0B    call $0B8F		; calculates the minimum visible screen values for the character's position in iy
2D32: A7          and  a
2D33: 21 00 4A    ld   hl,$4A00		; height values of the ground floor
2D36: 28 0A       jr   z,$2D42
2D38: 21 00 4F    ld   hl,$4F00		; height values of the first floor
2D3B: FE 0B       cp   $0B
2D3D: 28 03       jr   z,$2D42
2D3F: 21 80 50    ld   hl,$5080		; height values of the second floor

2D42: 22 FB 38    ld   ($38FB),hl	; saves the address dependent on the floor
2D45: C3 45 39    jp   $3945		; fills the screen buffer at 0x2d8a with data read from abadia7 and cropped for the current screen

; ---------------- this routine is called on each interrupt --------------------------

2D48: F3          di
2D49: F5          push af
2D4A: 3E 00       ld   a,$00		; in the interrupt the value of this counter is changed
2D4C: 3C          inc  a
2D4D: 28 03       jr   z,$2D52		; if the counter is 0xff, doesn't modify the value
2D4F: 32 4B 2D    ld   ($2D4B),a	; updates the variable for the next execution
2D52: CD 60 10    call $1060		; updates music if necessary
2D55: CD 54 3B    call $3B54		; related to speech
2D58: F1          pop  af
2D59: FB          ei
2D5A: ED 4D       reti

; prepares for copying character data to buffer
2D5C: FD E5       push iy
2D5E: E1          pop  hl
2D5F: 23          inc  hl			; advances the pointer position to the x position data
2D60: 23          inc  hl
2D61: 11 68 2D    ld   de,$2D68		; de = destination
2D64: 01 0A 00    ld   bc,$000A		; data length
2D67: C9          ret

; auxiliary buffer for data
2D68: 01 23 3E 20 12 13 78 04 B9 38

2D72: 00	related to the demo key buffer

; used to simulate another character input
2D73: 00          nop
2D74: 00          nop
; X, Y position and height of the current character
2D75: 00 00 00

2D78: 01 	; indicates if door graphics were flipped
2D79: 0D 70    ld   bc,$700D
2D7B: 3D          dec  a
2D7C: CD B4 3B    call $3BB4

; copied to 0x114-0x121
2D7F: 1F 01 04 BC 4F 9F 30 AC 0D 36 30 C0 01 01
	0x2d7f energy (obsequium)
	0x2d80 current day number (from 1 to 7)
	0x2d81 current time of day
		0 = night
		1 = prime
		2 = terce
		3 = sext
		4 = none
		5 = vespers
		6 = compline
	0x2d82-0x2d83: pointer to the next hour of the day
	0x2d84-0x2d85 address of the table for calculating offset according to the animation of a game entity for the current screen orientation
	0x2d86-0x2d87 amount of time to wait for the time of day to advance (as long as it's not zero)
	0x2d88-0x2d89 pointer to the data of the current character followed by the camera
	0x2d8a-0x2d8b pointer to the current screen's height buffer (576 (24*24) byte buffer)
	0x2d8c if it's 1 indicates the mirror hasn't been opened. If it's 0, indicates the mirror has been opened

; --- clears from 0x2d8d to 0x2dd7

2D8D: 07
2D8E: 2313
2D90: 0D20

2D92: F7
2D93: 1838
2D95: E5D5

2D97-2DBB: 00
2DBC: 00 ; if != 0, contains the roman numeral generated for the mirror room puzzle
2DBD: 00          nop
2DBE: 0000 ; bonuses obtained
2DC0: 00          nop
2DC1: 00          nop

2DC2: used to save the stack on initialization
2DC4: C9          ret

; auxiliary buffer for moving the character (used in the routine for guillermo to advance position)
2DC5: 38 E1 D1 C1 23 13 10 E8 CD A0 00 7C B5 C8 3A 23

2DD5: 0000
2DD7: 0000

; copied to 0x122-0x131. doors that characters can enter
2DD9: 	08 3038
	08 3047
	1F 3056
	19 3065
	1F 3074
	0C 3083
	FF

; copied to 0x132-0x154. character objects
2DEC: 	01 3038 20 00 FD 00
	01 3047 00 80 02 00
	01 3056 00 80 02 00
	00 3065 00 00 10 00
	00 3074 00 00 00 00
	00 3083 00 00 00 00
	FF

; character sprites
2E17: FE 1E 42 1E 42 05 22 38B4 05 22 80 00 00 00 00 00 00 00 00 ; guillermo
2E2B: FE 28 32 28 32 05 22 38AA 05 24 80 00 00 00 00 00 00 00 00 ; adso
2E3F: FE 32 32 32 32 05 22 3A2A 05 22 00 00 00 00 00 00 00 00 00 ; malaquias
2E53: FE 32 32 32 32 05 22 3A2A 05 22 00 00 00 00 00 00 00 00 00 ; the abbot
2E67: FE 32 32 32 32 05 22 3A2A 05 22 00 00 00 00 00 00 00 00 00 ; berengario
2E7B: FE 32 32 32 32 05 22 3A2A 05 22 00 00 00 00 00 00 00 00 00 ; severino

; door sprites
2E8F: FE 00 00 00 00 06 28 3A98 06 28 80 00 00 00 00 00 00 00 00 ; door of the abbot's room
2EA3: FE 00 00 00 00 06 28 3A98 06 28 80 00 00 00 00 00 00 00 00 ; door of the monks' room (next to guillermo)
2EB7: FE 00 00 00 00 06 28 3A98 06 28 80 00 00 00 00 00 00 00 00 ; door of severino's room
2ECB: FE 00 00 00 00 06 28 3A98 06 28 80 00 00 00 00 00 00 00 00 ; exit door from the rooms towards the church
2EDF: FE 00 00 00 00 06 28 3A98 06 28 80 00 00 00 00 00 00 00 00 ; exit door from the passage behind the kitchen
2EF3: FE 00 00 00 00 06 28 3A98 06 28 80 00 00 00 00 00 00 00 00 ; door 1 that blocks the passage to the left part of the abbey's ground floor
2F07: FE 00 00 00 00 06 28 3A98 06 28 80 00 00 00 00 00 00 00 00 ; door 2 that blocks the passage to the left part of the abbey's ground floor

; object sprites
2F1B: FE 00 00 00 00 04 0C 72F0 04 0C 80 00 00 00 00 00 00 00 00 ; book
2F2F: FE 00 00 00 00 04 0C 89B0 04 0C 80 00 00 00 00 00 00 00 00 ; gloves
2F43: FE 00 00 00 00 04 0C 8980 04 0C 80 00 00 00 00 00 00 00 00 ; glasses
2F57: FE 00 00 00 00 04 0C 8A10 04 0C 80 00 00 00 00 00 00 00 00 ; parchment
2F6B: FE 00 00 00 00 04 0C 89E0 04 0C 80 00 00 00 00 00 00 00 00 ; key 1
2F7F: FE 00 00 00 00 04 0C 89E0 04 0C 80 00 00 00 00 00 00 00 00 ; key 2
2F93: FE 00 00 00 00 04 0C 89E0 04 0C 80 00 00 00 00 00 00 00 00 ; key 3
2FA7: FE 00 00 00 00 04 0C A006 04 0C 80 00 00 00 00 00 00 00 00 ; ???
2FBB: FE 00 00 00 00 04 0C 72C0 04 0C 80 00 00 00 00 00 00 00 00 ; lamp
2FCF: FE 00 00 00 00 14 50 0000 14 50 80 00 00 00 00 00 00 FE FE ; light sprite
2FE3: FF

; game door data. copied to 0x155-0x174. 5 bytes per entry
2FE4: 	01 21 61 37 02 ; door of the abbot's room
	02 22 B7 1E 02 ; door of the monks' room (next to guillermo)
	00 04 66 5F 02 ; door of severino's room
	03 28 9E 28 02 ; exit door from the rooms towards the church
	03 10 7E 26 02 ; exit door from the passage behind the kitchen
	02 E0 60 76 00 ; door 1 that blocks the passage to the left part of the abbey's ground floor
	02 C0 60 7B 00 ; door 2 that blocks the passage to the left part of the abbey's ground floor
	FF


; position of game objects (copied to 0x175-0x197). 5 bytes per entry
3008: 	00 01 34 5E 13
	00 00 6B 55 06
	80 00 EC 2D 00
	00 01 36 5E 13
	00 00 00 00 00
	00 00 00 00 00
	00 00 35 35 13
	00 00 08 08 02
	00 00 08 08 02
	FF

; character characteristics. 6 entries of 15 bytes
3036: 	00 01 22 22 00 00 00 FE DE 00 00 00 00 00 10
	00 01 24 24 00 00 00 FE E0 00 FD 00 C0 A2 20
	00 00 26 26 0F 00 00 FE DE 00 FD 00 00 A2 10
	00 00 88 84 02 00 00 FE DE 00 FD 00 30 A2 10
	00 00 28 48 0F 00 00 FE DE 00 FD 00 60 A2 10
	00 00 C8 28 00 00 00 FE DE 00 FD 00 90 A2 10
; -- end of the 6 table entries


3090: 0000
3092: 0000
3094: 00          nop
3095: 00          nop
3096: 00          nop

; table with the monks' faces
; the face data for each monk occupies 100 bytes and has 2 faces (50 bytes each, one if moving in x and another if moving in y)
;  each face occupies 10 pixels high
3097: 	B1CB	; pointer to the graphic data of malaquias's face
	B167	; pointer to the graphic data of the abbot's face
309B:	B22F	; pointer to the graphic data of berengario's face
	B103	; pointer to the graphic data of severino's face

	; note: these don't appear in this table but are listed here
	B293 ; pointer to the graphic data of bernardo gui's face
	B2F7 ; pointer to the graphic data of jorge's face
	B35B ; pointer to the graphic data of the hooded figure

; table for calculating offset according to the animation of a game entity
; each table is a subtable according to screen orientation. Each subtable entry is 16 bytes:
; according to a series of conditions, 2 bytes of the entry are used, one for x (in bytes) and another for y (in pixels).
; byte 0-1: used if occupies 4 positions and it's the second animation movement
; byte 2-3: used if occupies 4 positions and it's the first animation movement
; byte 4-5: used if occupies one position, is not oriented to go up or down stairs and it's the second animation movement
; byte 6-7: used if occupies one position, is not oriented to go up or down stairs and it's the first animation movement
; byte 8-9: used if occupies one position, is oriented to go up or down stairs and it's the second animation movement
; byte a-b: used if occupies one position and is going down stairs
; byte c-d: used if occupies one position and is going up stairs
; byte e-f: ???
309F: 	00 00 FF FE FF 02 FE 00 01 02 00 00 00 FE 00 00 -> [00 00] [-1 -2] [-1 +2] [-2 00] [+1 +2] [00 00] [00 -2] [00 00]
	00 00 FF 02 01 02 00 04 FF 02 FE 06 FE 00 00 00 -> [00 00] [-1 +2] [+1 +2] [00 +4] [-1 +2] [-2 +6] [-2 00] [00 00]
	00 00 01 02 FF 02 00 04 01 02 02 06 02 00 00 00	-> [00 00] [+1 +2] [-1 +2] [00 +4] [+1 +2] [+2 +6] [+2 00] [00 00]
	00 00 01 FE 01 02 02 00 FF 02 00 00	00 FE 00 00 -> [00 00] [+1 -2] [+1 +2] [+2 00] [-1 +2] [00 00] [00 -2] [00 00]

	00 00 FF FE FF 02 FE 00 FF FE FE FC FE FA 00 00 -> [00 00] [-1 -2] [-1 +2] [-2 00] [-1 -2] [-2 -4] [-2 -6] [00 00]
	00 00 FF 02 FF FE FE 00 FF 02 FE 06 FE 00 00 00 -> [00 00] [-1 +2] [-1 -2] [-2 00] [-1 +2] [-2 +6] [-2 00] [00 00]
	00 00 01 02 FF 02 00 04 FF FE 00 02 00 FC 00 00 -> [00 00] [+1 +2] [-1 +2] [00 +4] [-1 -2] [00 +2] [00 -4] [00 00]
	00 00 01 FE FF FE 00 FC FF 02 00 00 00 FE 00 00 -> [00 00] [+1 -2] [-1 -2] [00 -4] [-1 +2] [00 00] [00 -2] [00 00]

	00 00 FF FE 01 FE 00 FC FF FF FE FC FE FA 00 00 -> [00 00] [-1 -2] [+1 -2] [00 -4] [-1 -2] [-2 -4] [-2 -6] [00 00]
	00 00 FF 02 FF FE FE 00 01 FE 00 02 00 FD 00 00 -> [00 00] [-1 +2] [-1 -2] [-2 00] [+1 -2] [00 +2] [00 -3] [00 00]
	00 00 01 02 01 FE 02 00 FF FE 00 02 00 FC 00 00 -> [00 00] [+1 +2] [+1 -2] [+2 00] [-1 -2] [00 +2] [00 -4] [00 00]
	00 00 01 FE FF FE 00 FC 01 FE 02 FC 02 FA 00 00 -> [00 00] [+1 -2] [-1 -2] [00 -4] [+1 -2] [+2 -4] [+2 -6] [00 00]

	00 00 FF FE 01 FE 00 FC	01 02 00 00 00 FE 00 00 -> [00 00] [-1 -2] [+1 -2] [00 -4] [+1 +2] [00 00] [00 -2] [00 00]
	00 00 FF 02 01 02 00 04	01 FE 00 02 00 FC 00 00 -> [00 00] [-1 +2] [+1 +2] [00 +4] [+1 -2] [00 +2] [00 -4] [00 00]
	00 00 01 02 01 FE 02 00 01 02 02 06 02 00 00 00 -> [00 00] [+1 +2] [+1 -2] [+2 00] [+1 +2] [+2 +6] [+2 00] [00 00]
	00 00 01 FE 01 02 02 00 01 FE 02 FC 02 FA 00 00 -> [00 00] [+1 -2] [+1 +2] [+2 00] [+1 -2] [+2 -4] [+2 -6] [00 00]

; each animation table (for adso and guillermo) has 8 entries.
; The first 4 are if it moves on the x axis and the other 4 if it moves on the y axis
; each entry is 4 bytes:
; byte 0-1: address of the graphic data of the associated sprite
; byte 2: sprite width (in bytes)
; byte 3: sprite height (in pixels)
; table related to guillermo's animation
319F: 	A3B4 05 22
	A300 05 24
	A3B4 05 22
	A45E 05 22

	A666 04 21
	A508 05 23
	A666 04 21
	A5B7 05 21

; table related to adso's animation
31BF:	A78A 05 20
	A6EA 05 20
	A78A 05 20
	A82A 05 1F
 	A8C5 04 1E
 	A93D 04 1E
 	A8C5 04 1E
 	A9B5 04 1E

; table for the animation of the monks
; each monk has 1 entry. Each entry is 4 bytes (with similar structure to guillermo and adso's animations)
31DF:	B103 05 22
	B103 05 24
	B103 05 22
 	B103 05 22

31EF:
 	B135 05 21
 	B135 05 23
 	B135 05 21
 	B135 05 21

; ---------------------- code related to keys -------------------------------------------------

; routine called when keyboard data is recorded to the keystroke buffer
31FF: CD BC 32    call $32BC		; reads the state of the keys and saves it in the keyboard buffers
3202: CD 7E 33    call $337E		; checks if the keystroke buffer has finished and if not, jumps
3205: 38 20       jr   c,$3227

; arrives here if the stored demo keystroke buffer has finished
3207: FB          ei
3208: 06 14       ld   b,$14		; 20 times
320A: C5          push bc
320B: CD 20 10    call $1020		; starts channel 3
320E: 01 D0 07    ld   bc,$07D0
3211: CD 0E 49    call $490E		; waits a bit
3214: C1          pop  bc
3215: 10 F3       djnz $320A

; ensures that keys are read
3217: 21 BC 32    ld   hl,$32BC
321A: 22 12 33    ld   ($3312),hl	; changes the reading method of the QR routine, so it reads from keyboard
321D: AF          xor  a
321E: 32 09 33    ld   ($3309),a	; ensures that data is obtained from the keyboard
3221: 3D          dec  a
3222: 32 69 34    ld   ($3469),a	; ensures that the keyboard reading routine works properly for the keyboard
3225: F3          di
3226: C9          ret

; arrives here if the keystroke buffer has not finished
3227: DD 21 AC 36 ld   ix,$36AC		; ix points to the key recording table
322B: 01 00 08    ld   bc,$0800		; 8 keys
322E: CD B6 33    call $33B6		; records in the keystroke buffer the state of F0-F7
3231: 01 00 08    ld   bc,$0800		; 8 keys
3234: CD B6 33    call $33B6		; records in the keystroke buffer the state of F8-F9, cursors, space and shift
3237: 01 00 08    ld   bc,$0800		; 8 keys
323A: CD B6 33    call $33B6		; records in the keystroke buffer the state of q,r,n,s,y,period
323D: FD 2B       dec  iy
323F: FD 2B       dec  iy
3241: FD 2B       dec  iy			; points to the newly obtained keys
3243: FD 7E 00    ld   a,(iy+$00)
3246: FD BE FC    cp   (iy-$04)
3249: 20 18       jr   nz,$3263		; if any of the first 8 change, records the new state in the keystroke buffer
324B: FD 7E 01    ld   a,(iy+$01)
324E: FD BE FD    cp   (iy-$03)
3251: 20 10       jr   nz,$3263		; if any of the second 8 change, records the new state in the keystroke buffer
3253: FD 7E 02    ld   a,(iy+$02)
3256: FD BE FE    cp   (iy-$02)
3259: 20 08       jr   nz,$3263		; if any of the third 8 change, records the new state in the keystroke buffer

325B: FD 34 FF    inc  (iy-$01)		; if there is no change, increments the counter that indicates the number of times there have been no changes
325E: 20 13       jr   nz,$3273		;  for the last key state, and in that case, does not record the new state
3260: FD 35 FF    dec  (iy-$01)		; if the change counter overflows, leaves it at 0xff and starts the next state counter at 1

3263: FD 36 03 01 ld   (iy+$03),$01	; records the new state in the keystroke buffer
3267: FD 23       inc  iy
3269: FD 23       inc  iy
326B: FD 23       inc  iy
326D: FD 23       inc  iy
326F: FD 22 D1 33 ld   ($33D1),iy	; saves the position buffer pointer

3273: FD 36 00 00 ld   (iy+$00),$00	; marks the new entry as the last one, to identify where the demo recording ends
3277: FD 36 01 00 ld   (iy+$01),$00
327B: C9          ret

; routine called when data is read from the keystroke buffer and copied to the keyboard buffers
327C: F3          di
327D: CD 7E 33    call $337E			; checks if the keystroke buffer has finished
3280: 06 01       ld   b,$01
3282: D2 29 36    jp   nc,$3629			; if the buffer has finished, jumps and restarts the demo

3285: 3A 72 2D    ld   a,($2D72)		; decrements the counter of number of times the state has not changed
3288: 3D          dec  a
3289: 20 18       jr   nz,$32A3			; if the state doesn't need to be changed yet, jumps
328B: FD 23       inc  iy				; passes to the next key state stored in the buffer
328D: FD 23       inc  iy
328F: FD 23       inc  iy
3291: FD 23       inc  iy
3293: FD 22 D1 33 ld   ($33D1),iy		; updates the keystroke buffer pointer
3297: FD 7E 00    ld   a,(iy+$00)		; if the recorded demo has finished, jumps and restarts the demo
329A: FD A6 01    and  (iy+$01)
329D: CA 29 36    jp   z,$3629
32A0: FD 7E 03    ld   a,(iy+$03)		; reads the number of times this block is used

32A3: 32 72 2D    ld   ($2D72),a		; updates the number of times to use this block
32A6: DD 21 AC 36 ld   ix,$36AC			; ix points to the key table that was recorded in the demo
32AA: CD 94 33    call $3394			; retrieves from the keystroke buffer the state of F0-F7 8 keys and updates the buffer where pressed keys are stored
32AD: CD 94 33    call $3394			; retrieves from the keystroke buffer the state of F8-F9, cursors, space and shift and updates the buffer where pressed keys are stored
32B0: CD 94 33    call $3394			; retrieves from the keystroke buffer the state of q,r,n,s,y,period and updates the buffer where pressed keys are stored
32B3: FD 21 E7 33 ld   iy,$33E7			; places the buffer to read key presses
32B7: 3E 09       ld   a,$09
32B9: 32 09 33    ld   ($3309),a		; ensures that data is obtained from the buffer instead of from the keyboard

; reads the state of the keys and saves it in the keyboard buffers
; This assembly routine is the low-level keyboard scanning driver for the Amstrad CPC. It interacts directly with the system's hardware (the
; 8255 PPI chip and the AY-3-8912 PSG sound chip) to read the state of every key on the keyboard and update the game's internal buffers.
;
; High-Level Function
; It performs a full sweep of the 10 rows of the keyboard matrix. For each row, it:
;  1. Reads the raw state of the keys (which keys are pressed).
;  2. Updates a buffer (0x33D3) that stores the current state of all keys.
;  3. Updates a second buffer (0x33DD) that tracks changes (which keys were just pressed or released).
;
; Why this matters
; This routine is the source of truth for all input in the game. When check_special_keys or any other logic asks "Is the Space bar pressed?",
; it is checking the `0x33D3` buffer that this routine just populated. In our Python remake, pygame.event.pump() and pygame.key.get_pressed()
; perform this exact same role: querying the hardware and updating the internal state list.

;  1. Hardware Setup (`32BC - 32D4`):
;      * `di`: Disables interrupts to ensure the scanning process isn't interrupted.
;      * PPI & PSG Configuration: It sends commands to the 8255 PPI (Programmable Peripheral Interface) to configure Port A as an input (to
;        read data) and Ports C as outputs (to control the PSG).
;      * The keyboard on the CPC is connected to the PSG's I/O port (Register 14). The code selects Register 14 (0x0E) on the PSG.

32BC: F3          di
32BD: 01 0E F4    ld   bc,$F40E	; 1111 0100 0000 1110 (8255 PPI port A)
32C0: ED 49       out  (c),c
32C2: 06 F6       ld   b,$F6
32C4: ED 78       in   a,(c)
32C6: E6 30       and  $30
32C8: 4F          ld   c,a
32C9: F6 C0       or   $C0		; PSG write register index operation (activates 14 for port A communication)
32CB: ED 79       out  (c),a

32CD: ED 49       out  (c),c	; PSG operation: inactive
32CF: 04          inc  b		; b = 0xf7 write to 8255 PPI control
32D0: 3E 92       ld   a,$92	; 1001 0010 (port A: input, port B: input, port C upper: output, port C lower: output)
32D2: ED 79       out  (c),a
32D4: C5          push bc

;  2. Buffer Setup (`32D5 - 32D8`):
;      * `ld hl,$33D3`: Points HL to the "Current State" buffer.
;      * `ld de,$33DD`: Points DE to the "State Change" buffer.

32D5: 21 D3 33    ld   hl,$33D3	; points to the buffer to save the last press of each key
32D8: 11 DD 33    ld   de,$33DD ; points to the buffer where changes in key press state are saved

;  3. Scanning Loop (`32DB - 32FA`):
;      * Read Row: It tells the PSG to read the data from the currently selected keyboard row (out (c),c / in a,(c)).
;      * `call $3305`: A helper that likely filters or processes the raw byte (possibly handling ghosting or debounce).
;      * Update Buffers:
;          * It reads the old state from (HL).
;          * It compares it with the new state to detect changes.
;          * It saves the new state back to (HL) (at 32EC).
;          * It saves the "change" information to (DE) (at 32F1).
;      * Next Row: It increments the row counter (inc c).
;      * Loop: It checks if it has scanned all 10 rows (cp $0A). If not, it jumps back to 32DB.

32DB: CB F1       set  6,c		; PSG operation: read data from register
32DD: 06 F6       ld   b,$F6
32DF: ED 49       out  (c),c
32E1: 06 F4       ld   b,$F4	; port A of 8255 PPI
32E3: ED 78       in   a,(c)	; gets the data and saves it in b
32E5: 47          ld   b,a
32E6: CD 05 33    call $3305	; if there is carry, ignores the key press and gets from IY buffer
32E9: 78          ld   a,b
32EA: B6          or   (hl)		; combines them with the previous data
32EB: 2F          cpl			; complements them
32EC: 70          ld   (hl),b	; saves the read value
32ED: 47          ld   b,a
32EE: 1A          ld   a,(de)	; checks if there has been a change in the presses
32EF: A0          and  b
32F0: B6          or   (hl)
32F1: 12          ld   (de),a	; saves the changes
32F2: 0C          inc  c		; passes to the next keyboard line
32F3: 13          inc  de		; advances the press buffers
32F4: 23          inc  hl
32F5: 79          ld   a,c
32F6: E6 0F       and  $0F
32F8: FE 0A       cp   $0A
32FA: 38 DF       jr   c,$32DB	; while not finished with the lines, continues processing

;  4. Cleanup (`32FC - 3304`):
;      * Reset PPI: It reconfigures the PPI back to its standard state (Port A: output) so the system can continue normal operation.
;      * `ret`: Returns to the caller.

32FC: C1          pop  bc
32FD: 3E 82       ld   a,$82	; 1001 0010 (port A: output, port B: input, port C upper: output, port C lower: output)
32FF: ED 79       out  (c),a
3301: 05          dec  b
3302: ED 49       out  (c),c	; PSG operation: inactive
3304: C9          ret
; **********************************************************************************************************************

; checks if keyboard presses are ignored and presses stored in a buffer are taken
; This code is an Input Redirection Hook. It allows the game to bypass the physical keyboard and instead read input from a pre-recorded
; sequence in memory. This is the core mechanism used for the game's Demo Mode.
;
; Technical Breakdown:
;  1. `ld a,c` / `and $0F`: It retrieves the index of the current keyboard row being scanned (0-9) and ensures it's clean.
;  2. `cp $00`: It compares the current row index against a threshold.
;      * Crucial Note: The comment (this parameter is modified from outside) identifies this as Self-Modifying Code. A routine elsewhere in the
;        game writes a value to address 0x3309 to turn the "playback" on or off.
;  3. `ret nc`:
;      * If the current row index is greater than or equal to the threshold (which is 0 by default), it simply returns. The game continues
;        using the real keyboard data already stored in register B.
;  4. `ld b,(iy+$00)` / `inc iy`:
;      * If the threshold has been increased (e.g., to 10), this code executes.
;      * It overwrites register B (the real keyboard state) with a byte from a buffer pointed to by register `IY`.
;      * It then moves the IY pointer to the next byte in the recording.
;
; What this accomplishes:
; This is essentially a Macro Player.
;  * Normal Play: The threshold is 0. The game reads the physical keys.
;  * Demo/Replay Mode: The game sets the threshold to 10, points IY to a recording of a previous game session, and "replays" the exact keyboard
;    states row-by-row. Because the game's logic is deterministic, the characters on screen will perform the exact same actions as they did
;    during the recording.
;
; In modern programming terms, this is a Mocking or Dependency Injection pattern, where the "Real Keyboard" dependency is swapped out for a
; "Recorded Data" dependency.

3305: 79          ld   a,c			; gets the keyboard line being processed
3306: E6 0F       and  $0F
3308: FE 00       cp   $00			; (this parameter is modified from outside)
330A: D0          ret  nc			; if the line to process is not greater than indicated
330B: FD 46 00    ld   b,(iy+$00)	; gets the data from the buffer pointed to by iy instead of from the keyboard
330E: FD 23       inc  iy
3310: C9          ret
; **********************************************************************************************************************
; checks if QR was pressed in the mirror room and acts accordingly
; This assembly routine handles the "Secret Mirror" logic in the library. It determines whether the player has correctly solved the puzzle to
; open the secret passage or if they have triggered a deadly trap.
;
; High-Level Logic
;  1. Check Status: It first checks if the mirror is already open (ld a,($2D8C)). If so, it does nothing.
;  2. Input Check: It calls a helper ($33F1) to see if the player is standing in front of the mirror and pressing Q + R.
;  3. Validation: If the keys are pressed, it compares the current staircase identifier ($2DBC) with the required "key" value (e).
;      * Success: If they match, the mirror opens ($334E). The height map is modified so the player can walk through, and the mirror's visual
;        state is updated.
;      * Failure: If they don't match, or if a specific error condition is met (cp $04), Guillermo triggers a trap ($3334). A trapdoor opens,
;        Guillermo falls to his death, and the game displays the message: "ESTAIS MUERTO, FRAY GUILLERMO, HABEIS CAIDO EN LA TRAMPA" ("You are
;        dead, Friar William, you have fallen into the trap").
;
; Detailed Breakdown
;  * `3311 call $32BC`: Reads the keyboard state.
;  * `331A ld a,($2D8C)`: Reads the mirror state variable. (Non-zero = Closed).
;  * `331F call $33F1`: Checks position + Q + R. Returns result in E.
;  * `3331 cp e`: Compares the expected correct staircase value (loaded from $2DBC) with the player's input value.
;  * `3334 (Failure path)`: Sets the "Death" flag ($3C97) and changes Guillermo's state ($288F) to a falling/dying animation. It also visually
;    modifies the floor block to show an open trapdoor.
;  * `334E (Success path)`: Calls routines $3365 and $336F to modify the room's collision data (height map) and visual data, effectively
;    "opening" the passage. It finally sets $2D8C to 0, marking the mirror as permanently open.
;
; This is the core implementation of one of the game's most famous puzzles.
;
3311: CD BC 32    call $32BC		; reads the state of the keys and saves it in the keyboard buffers
3314: 01 C0 7F    ld   bc,$7FC0		; sets configuration 0 (0, 1, 2, 3)
3317: ED 49       out  (c),c
3319: FB          ei
331A: 3A 8C 2D    ld   a,($2D8C)	; checks if the mirror has been opened
331D: A7          and  a
331E: C8          ret  z			; if it has already been opened, exits

331F: CD F1 33    call $33F1		; checks if in front of the mirror and if so, if Q and R were pressed, returning the result in e
3322: 7B          ld   a,e
3323: A7          and  a
3324: C8          ret  z			; if QR was not pressed on any staircase, exits
3325: 3A BC 2D    ld   a,($2DBC)	; gets the roman numeral of the mirror room.
3328: FE 04       cp   $04
332A: 28 08       jr   z,$3334		; if it is 4, dies (when does this happen???)
332C: 21 BF 2D    ld   hl,$2DBF		; points to the bonuses
332F: CB D6       set  2,(hl)		; sets to 1 the bit that indicates QR was pressed on one of the mirror staircases
3331: BB          cp   e			; if it matches the roman numeral staircase, survives
3332: 28 1A       jr   z,$334E

; if it arrives here, guillermo dies
3334: 3E 01       ld   a,$01
3336: 32 97 3C    ld   ($3C97),a	; indicates that guillermo dies
3339: 3E 14       ld   a,$14
333B: 32 8F 28    ld   ($288F),a	; changes guillermo's state

333E: 3E 6B       ld   a,$6B
3340: 2A E0 34    ld   hl,($34E0)	; gets the pointer to the block that forms the mirror
3343: 2B          dec  hl
3344: 2B          dec  hl
3345: CD 72 33    call $3372		; changes the data of a block in the mirror room so that a trap opens and guillermo falls
3348: CD 1B 50    call $501B		; writes the sentence on the scoreboard
334B: 22 							ESTAIS MUERTO, FRAY GUILLERMO, HABEIS CAIDO EN LA TRAMPA
334C: 18 0C       jr   $335A

; if it arrives here, guillermo survives
334E: F3          di
334F: 3E FF       ld   a,$FF
3351: CD 65 33    call $3365		; modifies the height data of the mirror room
3354: 3E 51       ld   a,$51
3356: CD 6F 33    call $336F		; modifies the data of the mirror room so that the mirror is open
3359: FB          ei

335A: AF          xor  a
335B: 32 75 2D    ld   ($2D75),a	; indicates a screen change
335E: 32 8C 2D    ld   ($2D8C),a	; indicates that the mirror has been opened
3361: CD FD 0F    call $0FFD		; plays a sound
3364: C9          ret

; places abadia7 at 0x4000 and saves a in the height of the mirror room
3365: 01 C6 7F    ld   bc,$7FC6
3368: ED 49       out  (c),c
336A: 2A D9 34    ld   hl,($34D9)
336D: 77          ld   (hl),a
336E: C9          ret
; **********************************************************************************************************************
; saves a in the block that forms the mirror in the mirror room
; This code is a Dynamic Map Modifier. Its purpose is to physically change the visual graphics of a room by overwriting its data in the game's
; room database (abadia8.bin).
;
; Technical Breakdown:
;  1. `ld hl,($34E0)`: It retrieves a pointer stored at 0x34E0. This pointer identifies the exact location in the room definition (inside
;     abadia8.bin) where the "Mirror Block" or "Trapdoor Block" is defined.
;  2. `ld bc,$7FC7` / `out (c),c`: It switches the Amstrad CPC's memory bank to Bank 7. This is where abadia8.bin (the room/screen database) is
;     stored. Because this bank is normally read-only or hidden, the code must explicitly switch to it to make changes.
;  3. `ld (hl),a`: It writes the value currently in register `A` into the room data.
;      * If called from the "Success" path ($3354), A contains 0x51, which changes the mirror block to an "Open Passage" block.
;      * If called from the "Failure" path ($333E), A contains 0x6B, which changes a floor block into an "Open Trapdoor" block.
;  4. `ld bc,$7FC0` / `out (c),c`: It restores the standard memory configuration (Bank 0) so the main game logic can continue.
;  5. `ret`: Returns to the caller.
;
; Significance:
; This is a very sophisticated technique for an 8-bit game. Instead of simply having two versions of the room, the game edits the bytecode of
; the room definition in real-time. This saves memory and allows the game's rendering engine (19D8) to naturally "see" the updated
; architectural block the next time the screen is drawn.
336F: 2A E0 34    ld   hl,($34E0)		; retrieves the address of the block that forms the mirror
3372: 01 C7 7F    ld   bc,$7FC7
3375: ED 49       out  (c),c			; puts abadia8
3377: 77          ld   (hl),a
3378: 01 C0 7F    ld   bc,$7FC0			; restores the typical configuration
337B: ED 49       out  (c),c
337D: C9          ret
; **********************************************************************************************************************
; checks if the keystroke buffer has finished. If so, exits with CF = 0. If not finished, loads abadia6.bin at 0x4000
; puts in iy the address of the keystroke buffer and exits with CF = 1
337E: 2A D1 33    ld   hl,($33D1)		; gets the pointer to the demo keystroke buffer
3381: E5          push hl
3382: 11 F0 6F    ld   de,$6FF0
3385: A7          and  a
3386: ED 52       sbc  hl,de			; checks if the pointer reached the limit
3388: E1          pop  hl
3389: D0          ret  nc				; if hl >= de, exits
338A: 01 C5 7F    ld   bc,$7FC5			; puts abadia6.bin at 0x4000 and sets the carry flag
338D: ED 49       out  (c),c
338F: E5          push hl
3390: FD E1       pop  iy				; iy = current address of the keystroke buffer
3392: 37          scf					; sets the carry flag
3393: C9          ret

; retrieves from the keystroke buffer the state of 8 keys and updates the buffer where pressed keys are stored
3394: FD 4E 00    ld   c,(iy+$00)	; reads the current byte
3397: FD 23       inc  iy
3399: 06 08       ld   b,$08		; repeats for 8 keys
339B: C5          push bc
339C: DD 7E 00    ld   a,(ix+$00)	; reads the current key
339F: DD 23       inc  ix
33A1: 11 E7 33    ld   de,$33E7		; buffer where key presses are placed to later read them instead of keyboard presses
33A4: CD 8D 34    call $348D		; checks if the key read in iy+0 was pressed
33A7: 7E          ld   a,(hl)
33A8: 2F          cpl
33A9: 4F          ld   c,a
33AA: 1A          ld   a,(de)
33AB: A1          and  c
33AC: C1          pop  bc
33AD: CB 11       rl   c			; gets the current bit of the key that was checked
33AF: 30 01       jr   nc,$33B2
33B1: B6          or   (hl)
33B2: 12          ld   (de),a		; updates the buffer depending on whether the key was pressed or not
33B3: 10 E6       djnz $339B
33B5: C9          ret

; records in the keystroke buffer the state of the keys indicated in ix
33B6: C5          push bc
33B7: DD 7E 00    ld   a,(ix+$00)	; reads a key
33BA: DD 23       inc  ix
33BC: 11 D3 33    ld   de,$33D3		; de points to the table with the last keyboard press for each line
33BF: CD 8D 34    call $348D		; checks if key a was pressed using the keyboard buffer passed in de
33C2: 1A          ld   a,(de)		; reads the key and checks if it was pressed
33C3: A6          and  (hl)
33C4: C6 FF       add  a,$FF		; if it was not pressed, a = 0, so adding 0xff will not carry
33C6: C1          pop  bc
33C7: CB 11       rl   c			; puts whether it was pressed or not in c
33C9: 10 EB       djnz $33B6		; repeats for the rest of the keys
33CB: FD 71 00    ld   (iy+$00),c	; saves in the keystroke buffer the state of the keys that have been checked
33CE: FD 23       inc  iy
33D0: C9          ret

33D1-33D2: pointer to the demo keypresses
33D3-33DC: last keyboard press for each line
33DD-33E6: keyboard press changes for each line
33E7-33F0: buffer to store the demo keys

; checks if Q and R are pressed on any of the mirror staircases
; e indicates if QR was pressed on any staircase and on which staircase it was pressed
33F1: 1E 00       ld   e,$00		; initially e is 0
33F3: DD 21 36 30 ld   ix,$3036		; points to guillermo's position data
33F7: DD 7E 02    ld   a,(ix+$02)	; reads the x position
33FA: FE 22       cp   $22
33FC: C0          ret  nz			; if not in the appropriate place, exits
33FD: DD 7E 04    ld   a,(ix+$04)	; if not at the appropriate height, exits
3400: FE 1A       cp   $1A
3402: C0          ret  nz
3403: 3E 43       ld   a,$43
3405: CD 82 34    call $3482		; if the Q key has not been pressed, exits
3408: C8          ret  z
3409: 3E 32       ld   a,$32		; if the R key has not been pressed, exits
340B: CD 82 34    call $3482		; checks if the key with code a has been pressed
340E: C8          ret  z
340F: DD 7E 03    ld   a,(ix+$03)	; reads guillermo's y position and modifies e according to this position
3412: 1C          inc  e
3413: FE 6D       cp   $6D			; if on the left staircase, exits with e = 1
3415: C8          ret  z
3416: 1C          inc  e
3417: FE 69       cp   $69			; if on the center staircase, exits with e = 2
3419: C8          ret  z
341A: 1C          inc  e
341B: FE 65       cp   $65			; if on the right staircase, exits with e = 3
341D: C8          ret  z
341E: 1E 00       ld   e,$00		; if QR was pressed but not on any staircase, ignores it
3420: C9          ret

3421: key read
3422: FF
3423-3426: 08 25 4A FF keys that move left (cursor left, K, joystick left)
3427-342A: 2F 2F 49 FF action keys (space, joystick button)
342B-342E: 00 45 48 FF keys that move up (cursor up, A, joystick up)
342F-3432: 01 24 4B FF keys that move right (cursor right, L, joystick right)
3433-3436: 02 47 4D FF keys that move down (cursor down, Z, joystick down)

; checks if the key passed as parameter has been pressed (or one that does the same function). If so, returns non-zero
3437: ED 53 5F 34 ld   ($345F),de	; modifies an instruction with the buffer data
343B: 21 21 34    ld   hl,$3421		; saves the key to check
343E: 77          ld   (hl),a
343F: 23          inc  hl
3440: 23          inc  hl
3441: FE 08       cp   $08			; if it is the left cursor jumps
3443: 28 16       jr   z,$345B
3445: 21 27 34    ld   hl,$3427		; if it is space jumps
3448: FE 2F       cp   $2F
344A: 28 0F       jr   z,$345B
344C: 21 21 34    ld   hl,$3421
344F: FE 03       cp   $03			; if it is not one of the cursors, jumps
3451: 30 08       jr   nc,$345B

3453: 21 2B 34    ld   hl,$342B
3456: 87          add  a,a			; a = key*4
3457: 87          add  a,a
3458: CD 2D 16    call $162D		; hl = hl + a

345B: 7E          ld   a,(hl)		; reads what was in that position
345C: 23          inc  hl
345D: E5          push hl
345E: 11 00 00    ld   de,$0000		; de = destination buffer (the buffer is filled outside)
3461: CD 8D 34    call $348D		; checks if the key that was in that position was pressed
3464: E3          ex   (sp),hl		; saves the selected mask on the stack
3465: 20 09       jr   nz,$3470		; if the key was pressed, exits with a != 0
3467: 7E          ld   a,(hl)		; continues testing alternative keys for that function
3468: FE FF       cp   $FF			; (this instruction is changed from outside)
346A: 30 03       jr   nc,$346F		; if all have been tested, exits with a = 0
346C: D1          pop  de
346D: 18 EC       jr   $345B

346F: AF          xor  a
3470: E1          pop  hl
3471: C9          ret

; checks if there has been a change in the state of the key with code a. If pressed, returns non-zero
; This code is a Keyboard Event Processor. While the earlier routine (3482) checked if a key was held down, this routine checks if a key was
; just pressed or released (a state change). Crucially, it also "acknowledges" or consumes the event so it isn't processed twice.
;
; Technical Breakdown:
;  1. Input: Register `A` contains the code of the key to check.
;  2. `ld de,$33DD`: Points DE to the "Keyboard State Change" buffer (populated by the scanning routine at 32BC).
;  3. `call $3437`: Checks if the key in A has its "changed" bit set in the buffer.
;  4. `push af`: Saves the result of the check (the Zero flag state).
;  5. Consuming the event (`347B - 347D`):
;      * It reads the current "changed" mask.
;      * `or (hl)`: It performs a bitwise OR with the specific bit for this key.
;      * `ld (de),a`: It writes the mask back.
;      * Effect: By "ORing" the bit, it effectively ensures that specific bit is cleared/marked as handled in the state change buffer, so
;        future calls to this routine for the same key within the same frame won't trigger again.
;  6. `pop af`: Restores the original result of the check.
;  7. `ret`: Returns.
;
; Summary of function:
; This is an "Edge Trigger" check.
;  * If you use 3482, the code will return true as long as the player holds the key.
;  * If you use 3472 (this code), it returns true only on the exact frame the key is first pressed.
;
; In Python, this is equivalent to checking pygame.KEYDOWN versus pygame.key.get_pressed().
;
3472: E5          push hl
3473: D5          push de
3474: 11 DD 33    ld   de,$33DD		; de = keyboard press changes for each line
3477: CD 37 34    call $3437		; checks if the state of the key passed as parameter has changed
347A: F5          push af
347B: 1A          ld   a,(de)
347C: B6          or   (hl)
347D: 12          ld   (de),a
347E: F1          pop  af
347F: D1          pop  de
3480: E1          pop  hl
3481: C9          ret

;  checks if the key with code a has been pressed. If pressed, returns non-zero
;  Technical Breakdown:
;   1. Input: Register `A` contains the "Key Code" to be checked.
;   2. `push hl` / `push de`: It saves the current values of registers HL and DE so they aren't lost (preserving the caller's state).
;   3. `ld de,$33D3`: It sets DE to point to address `0x33D3`. Based on the memory map, this is the table where the game stores the status of
;      the keyboard matrix (updated by the interrupt routine).
;   4. `call $3437`: It calls a helper routine that does the actual work. It uses the key code in A to index into the table at DE and checks if
;      the corresponding bit is set (indicating a press).
;   5. `pop de` / `pop hl`: It restores the original values of the registers.
;   6. `ret`: Returns to the main loop.
;
;  Result:
;  After this code runs, the Zero Flag is affected:
;   * If the key is pressed, the routine returns a non-zero value (Z flag is cleared).
;   * If the key is NOT pressed, it returns zero (Z flag is set).

3482: E5          push hl
3483: D5          push de
3484: 11 D3 33    ld   de,$33D3	; points to the table with the last key press
3487: CD 37 34    call $3437	; checks if the key with code a has been pressed
348A: D1          pop  de
348B: E1          pop  hl
348C: C9          ret
; **********************************************************************************************************************
; checks if a key a was pressed using the keyboard buffer passed in de
348D: 4F          ld   c,a		; c = what was in that position
348E: CB 3F       srl  a		; c = c/8
3490: CB 3F       srl  a
3492: CB 3F       srl  a
3494: 83          add  a,e		; de = de + c/8 (finds the offset of the key to search in the pressed keys buffer)
3495: 5F          ld   e,a
3496: 8A          adc  a,d
3497: 93          sub  e
3498: 57          ld   d,a
3499: 79          ld   a,c
349A: E6 07       and  $07		; gets the bit of the line
349C: 21 A8 34    ld   hl,$34A8	; points to the bit masks
349F: 85          add  a,l		; indexes into the table
34A0: 6F          ld   l,a
34A1: 8C          adc  a,h
34A2: 95          sub  l
34A3: 67          ld   h,a
34A4: 1A          ld   a,(de)	; reads the position of pressed keys
34A5: 2F          cpl
34A6: A6          and  (hl)		; checks if the key in question was pressed
34A7: C9          ret

; masks for each bit
34A8: 01 02 04 08 10 20 40 80


; routine called during initialization
34B0: 3E 01       ld   a,$01
34B2: 32 8C 2D    ld   ($2D8C),a	; initially the secret room behind the mirror is not open
34B5: AF          xor  a
34B6: 32 BC 2D    ld   ($2DBC),a	; indicates that the roman numeral of the mirror room has not been generated yet

34B9: F3          di
34BA: 01 C6 7F    ld   bc,$7FC6		; loads abadia7.bin
34BD: ED 49       out  (c),c
34BF: 21 DB 34    ld   hl,$34DB		; points to the height data for the mirror room if the mirror is closed
34C2: ED 5B D9 34 ld   de,($34D9)	; gets the pointer where to copy the height data
34C6: 01 05 00    ld   bc,$0005
34C9: ED B0       ldir				; copies the bytes to abadia7.bin

34CB: 3E 11       ld   a,$11
34CD: CD 6F 33    call $336F		; modifies the mirror room so the mirror appears closed
34D0: 2B          dec  hl
34D1: 2B          dec  hl			; points to the beginning of the entry
34D2: 3E 1F       ld   a,$1F
34D4: CD 72 33    call $3372		; modifies the mirror room so the trap is closed
34D7: FB          ei				; enables interrupts
34D8: C9          ret

34D9-34DA: saves the address of the mirror height data in abadia7.bin

; height data if the mirror is closed
34DB: F5 20 62 0B FF

34E0-34E1: offset to the block that forms the mirror in the mirror screen of abadia8.bin

; this method is called when adso's sprite orientation changes and handles flipping adso's sprites
34E2: 3A 4B 30    ld   a,($304B)		; changes the state of bit 1
34E5: EE 01       xor  $01
34E7: 32 4B 30    ld   ($304B),a
34EA: 21 EA A6    ld   hl,$A6EA			; points to adso's sprites 5 bytes wide
34ED: 01 05 5F    ld   bc,$5F05
34F0: CD 52 35    call $3552			; flips them
34F3: 21 C5 A8    ld   hl,$A8C5			; points to adso's sprites 4 bytes wide
34F6: 01 04 5A    ld   bc,$5A04
34F9: 18 57       jr   $3552			; flips them

; this method is called when malaquias's sprite orientation changes and handles flipping the sprite faces
34FB: 3A 5A 30    ld   a,($305A)		; changes the state of bit 1
34FE: EE 01       xor  $01
3500: 32 5A 30    ld   ($305A),a
3503: 2A 97 30    ld   hl,($3097)		; hl points to malaquias's face data
3506: 01 05 14    ld   bc,$1405
3509: 18 47       jr   $3552			; flips malaquias's faces

; this method is called when the abbot's sprite orientation changes and handles flipping the sprite faces
350B: 3A 69 30    ld   a,($3069)
350E: EE 01       xor  $01
3510: 32 69 30    ld   ($3069),a		; changes the state of bit 1
3513: 2A 99 30    ld   hl,($3099)		; hl points to the abbot's face data
3516: 01 05 14    ld   bc,$1405
3519: 18 37       jr   $3552			; flips the abbot's faces

; this method is called when berengario's sprite orientation changes and handles flipping the sprite faces
351B: 3A 78 30    ld   a,($3078)		; changes the state of bit 1
351E: EE 01       xor  $01
3520: 32 78 30    ld   ($3078),a
3523: 2A 9B 30    ld   hl,($309B)		; hl points to berengario's face data
3526: 01 05 14    ld   bc,$1405
3529: 18 27       jr   $3552			; flips berengario's faces

; this method is called when severino's sprite orientation changes and handles flipping the sprite faces
352B: 3A 87 30    ld   a,($3087)		; changes the state of bit 1
352E: EE 01       xor  $01
3530: 32 87 30    ld   ($3087),a
3533: 2A 9D 30    ld   hl,($309D)		; hl points to severino's face data
3536: 01 05 14    ld   bc,$1405
3539: 18 17       jr   $3552			; flips severino's faces


; this method is called when guillermo's sprite orientation changes and handles flipping guillermo's sprites
353B: 3A 3C 30    ld   a,($303C)	; changes the state of bit 1
353E: EE 01       xor  $01
3540: 32 3C 30    ld   ($303C),a
3543: 21 00 A3    ld   hl,$A300		; hl points to guillermo's graphics 5 bytes wide
3546: 01 05 AE    ld   bc,$AE05		; bc -> indicates 5 bytes wide and 0x366 bytes (0xae*5)
3549: CD 52 35    call $3552		; flips guillermo's graphics 5 bytes wide with respect to xy
354C: 21 66 A6    ld   hl,$A666		; hl points to guillermo's graphics 4 bytes wide
354F: 01 04 21    ld   bc,$2104		; bc -> indicates 4 bytes wide and 0x84 bytes (0x21*4)

; rotates with respect to x a series of graphic data passed in hl (the graphics width is passed in c and in b a number
;  to calculate how many graphics to rotate)
3552: C5          push bc			; saves the original parameter
3553: 5D          ld   e,l			; de = source graphics address
3554: 54          ld   d,h
3555: 06 00       ld   b,$00
3557: ED 43 7B 35 ld   ($357B),bc	; saves the object width in the routine

355B: 0D          dec  c
355C: 09          add  hl,bc		; hl = points to the last byte of a group of object pixels (dependent on its width)
355D: 06 A1       ld   b,$A1		; in bc will point to the auxiliary table for flipx
355F: D9          exx				; exchanges registers
3560: C1          pop  bc			; retrieves the original parameter
3561: 0C          inc  c
3562: CB 39       srl  c
3564: 69          ld   l,c			; saves in l the number of swaps per block for the block to be completely rotated
3565: D9          exx				; exchanges registers
3566: D5          push de			; saves the original object address
3567: D9          exx

3568: D9          exx
3569: 4E          ld   c,(hl)		; gets the byte to swap
356A: 0A          ld   a,(bc)		; flips the 4 pixels using the flipx table and saves it in a' for later
356B: 08          ex   af,af'
356C: 1A          ld   a,(de)		; gets the other byte to swap
356D: 4F          ld   c,a
356E: 0A          ld   a,(bc)		; flips the 4 pixels using the flipx table
356F: 77          ld   (hl),a		; swaps the values obtained from the read bytes
3570: 08          ex   af,af'
3571: 12          ld   (de),a
3572: 2B          dec  hl			; tries for the next byte
3573: 13          inc  de
3574: D9          exx
3575: 2D          dec  l
3576: 20 F0       jr   nz,$3568		; repeats until the entire line has been copied

; when it arrives here, the block it has processed is perfectly rotated
3578: D9          exx
3579: E1          pop  hl			; retrieves the initial object address

357A: 11 00 00    ld   de,$0000		; this parameter is filled above with the width
357D: 19          add  hl,de		; passes to the next block
357E: EB          ex   de,hl
357F: 2D          dec  l
3580: 19          add  hl,de		; with hl points to the last byte of a group of object pixels (dependent on its width)
3581: D9          exx
3582: 10 E0       djnz $3564		; repeats until finished
3584: C9          ret

; opens the doors of the left wing of the abbey
3585: 21 02 E0    ld   hl,$E002
3588: 22 FD 2F    ld   ($2FFD),hl
358B: 26 C0       ld   h,$C0
358D: 22 02 30    ld   ($3002),hl
3590: C9          ret

; calculates in hl the position at which to save/load the data, in de points to the current data and in bc indicates the data length
3591: 25          dec  h
3592: CB F4       set  6,h			; adjusts the banks to 0x4000-0x49ff
3594: 2E 00       ld   l,$00
3596: 11 00 A2    ld   de,$A200
3599: 01 FF 00    ld   bc,$00FF
359C: C9          ret

; ----------------------------- code related to pause/load/save games ------------------------------------

; checks if delete key was pressed (pause), or ctrl+f? (save game or save demo) or shift+f? (load game or load demo) and acts accordingly
359D: 3E 4F       ld   a,$4F		; delete key
359F: CD 72 34    call $3472		; check if delete state has changed?
35A2: 28 26       jr   z,$35CA		; if not, jump

; arrives here if delete was pressed (delete is pause)
35A4: F3          di
35A5: 3E 3F       ld   a,$3F
35A7: 32 97 0F    ld   ($0F97),a	; modifies the copy of the mask with the channel status, so they need to be reactivated
35AA: 4F          ld   c,a
35AB: 3E 07       ld   a,$07
35AD: CD 4E 13    call $134E		; deactivates the 3 sound channels
35B0: 21 BC 32    ld   hl,$32BC
35B3: 22 12 33    ld   ($3312),hl	; ensures that the IR routine reads from keyboard
35B6: AF          xor  a
35B7: 32 09 33    ld   ($3309),a	; ensures that keyboard data is obtained
35BA: 3D          dec  a
35BB: 32 69 34    ld   ($3469),a	; ensures that the keyboard read routine works properly for the keyboard
35BE: CD BC 32    call $32BC		; reads the key state and saves it in the keyboard buffers
35C1: 3E 4F       ld   a,$4F
35C3: CD 72 34    call $3472
35C6: 28 F6       jr   z,$35BE		; waits until delete is pressed again
35C8: FB          ei
35C9: C9          ret

; arrives here if delete was not pressed
35CA: 3E 17       ld   a,$17
35CC: CD 82 34    call $3482		; checks if control was pressed
35CF: C4 F2 36    call nz,$36F2		; if it was pressed, checks if a function key was pressed
35D2: 28 4A       jr   z,$361E		; if control+function key was not pressed, jump

; arrives here if control+function key was pressed
35D4: F3          di
35D5: C5          push bc
35D6: 78          ld   a,b
35D7: FE 01       cp   $01
35D9: 20 1A       jr   nz,$35F5		; if ctrl+f9 was not pressed, jump

; specific code if ctrl+f9 was pressed
35DB: 21 FF 31    ld   hl,$31FF
35DE: 22 12 33    ld   ($3312),hl	; makes the IR routine record keyboard presses in the press buffer
35E1: CD 7E 33    call $337E		; checks if the press buffer has ended and loads abadia6.bin at 0x4000
35E4: 21 00 40    ld   hl,$4000
35E7: AF          xor  a			; initializes the first key state to 0
35E8: 77          ld   (hl),a
35E9: 23          inc  hl
35EA: 77          ld   (hl),a
35EB: 23          inc  hl
35EC: 77          ld   (hl),a
35ED: 23          inc  hl
35EE: 77          ld   (hl),a
35EF: 23          inc  hl
35F0: 22 D1 33    ld   ($33D1),hl	; saves the pointer to the press buffer
35F3: 06 01       ld   b,$01

35F5: CD 04 37    call $3704	; calculates the position to save data 1
35F8: EB          ex   de,hl
35F9: ED B0       ldir			; copies the data to destination
35FB: E1          pop  hl
35FC: E5          push hl
35FD: D5          push de
35FE: CD 91 35    call $3591	; calculates the position to save data 2
3601: EB          ex   de,hl
3602: ED B0       ldir			; copies the data to destination
3604: D1          pop  de
3605: 21 85 3C    ld   hl,$3C85
3608: 01 C8 00    ld   bc,$00C8
360B: CD 16 36    call $3616	; copies data 3 to destination and restores configuration 0
360E: C1          pop  bc
360F: 78          ld   a,b
3610: FE 01       cp   $01
3612: 28 39       jr   z,$364D	; if control+f9 was pressed, jump
3614: FB          ei
3615: C9          ret

; copies the data and restores configuration
3616: ED B0       ldir
3618: 01 C0 7F    ld   bc,$7FC0
361B: ED 49       out  (c),c
361D: C9          ret

; arrives here if control and a function key were not pressed
361E: 00          nop				; these 2 instructions are modified from outside (but only nop is set???)
361F: 00          nop
3620: 3E 15       ld   a,$15
3622: CD 82 34    call $3482		; checks if shift was pressed
3625: C4 F2 36    call nz,$36F2		; if it was pressed, checks if a function key was pressed
3628: C8          ret  z			; if not, exit

; also arrives here if the keys stored in the press buffer ran out
3629: 78          ld   a,b
362A: F3          di
362B: FE 01       cp   $01
362D: 20 1E       jr   nz,$364D		; if shift+f9 was not pressed, jump

; arrives here if shift+f9 was pressed
362F: 21 00 00    ld   hl,$0000
3632: 22 1E 36    ld   ($361E),hl	; puts 2 nops when arriving at the state load section
3635: 21 7C 32    ld   hl,$327C
3638: 22 12 33    ld   ($3312),hl	; ensures that in the IR routine, presses are read from the press buffer
363B: 21 00 40    ld   hl,$4000		; initializes the position of the demo key buffer
363E: 22 D1 33    ld   ($33D1),hl
3641: 3E 01       ld   a,$01
3643: 32 72 2D    ld   ($2D72),a	; indicates that the first block of presses is used only once
3646: 3E 48       ld   a,$48
3648: 32 69 34    ld   ($3469),a	; ensures that the keyboard read routine works properly for the demo
364B: 06 01       ld   b,$01

; also arrives here if control+f9 was pressed
364D: 3A 3C 30    ld   a,($303C)	; reads if adso and william's graphics are rotated
3650: 6F          ld   l,a
3651: 3A 4B 30    ld   a,($304B)
3654: 67          ld   h,a
3655: E5          push hl
3656: C5          push bc
3657: CD C4 36    call $36C4		; rotates the monk graphics if necessary
365A: C1          pop  bc
365B: C5          push bc
365C: CD 04 37    call $3704		; calculates in hl the position to save data
365F: 01 20 03    ld   bc,$0320		; doesn't save all data (only up to 0x309e)
3662: E5          push hl
3663: ED B0       ldir				; saves the data
3665: E1          pop  hl
3666: E3          ex   (sp),hl
3667: CD 91 35    call $3591		; calculates in hl the position to save data and saves it
366A: ED B0       ldir
366C: 2A D9 34    ld   hl,($34D9)	; modifies the height data of the mirror room
366F: 36 F5       ld   (hl),$F5
3671: E1          pop  hl
3672: 01 38 03    ld   bc,$0338
3675: 09          add  hl,bc		; points to the following data
3676: 11 85 3C    ld   de,$3C85
3679: 01 98 00    ld   bc,$0098
367C: CD 16 36    call $3616		; copies the data and restores configuration
367F: E1          pop  hl
3680: DD 21 3C 30 ld   ix,$303C		; points to graphics rotation
3684: DD 75 00    ld   (ix+$00),l	; restores william and adso's rotation
3687: DD 74 0F    ld   (ix+$0f),h
368A: AF          xor  a
368B: DD 77 1E    ld   (ix+$1e),a	; sets the monks' rotation
368E: DD 77 2D    ld   (ix+$2d),a
3691: DD 77 3C    ld   (ix+$3c),a
3694: DD 77 4B    ld   (ix+$4b),a
3697: CD 1A 37    call $371A
369A: AF          xor  a
369B: 32 6E 41    ld   ($416E),a
369E: 3A BC 2D    ld   a,($2DBC)	; gets the roman numeral of the mirror room
36A1: A7          and  a
36A2: C4 43 56    call nz,$5643		; if it was generated, copies the roman numerals of the mirror room to the scroll string
36A5: E1          pop  hl
36A6: FB          ei
36A7: 76          halt
36A8: F3          di
36A9: C3 8F 25    jp   $258F		; jumps to main loop

; table of keys to check when control is pressed: (F0, F1, F2, F3, F4, F5, F6, F7, F8, F9)
36AC: 0F 0D 0E 05 14 0C 04 0A 0B 03

; code of cursor up, left, down, right, space, shift, q, r, n, s keys
36B6: 00 01 02 08 2F 15 43 32 2E 3C

; code of 'y', '.' keys
36C0: 2B 07 07 07

; if any monk's graphic needs to be rotated, do it
36C4: FD E5       push iy
36C6: FD 21 54 30 ld   iy,$3054		; points to malaquias' characteristics
36CA: 21 97 30    ld   hl,$3097		; points to the table with monks' faces
36CD: 06 04       ld   b,$04		; repeat 4 times (for malaquias, the abbot, berengario and severino)
36CF: C5          push bc
36D0: 5E          ld   e,(hl)		; reads an address and saves it in de
36D1: 23          inc  hl
36D2: 56          ld   d,(hl)
36D3: 23          inc  hl
36D4: E5          push hl
36D5: FD 7E 06    ld   a,(iy+$06)	; reads if the monk needs to be rotated
36D8: A7          and  a
36D9: 28 0B       jr   z,$36E6
36DB: FD 36 06 00 ld   (iy+$06),$00
36DF: EB          ex   de,hl
36E0: 01 05 14    ld   bc,$1405		; width = 5, number = 20
36E3: CD 52 35    call $3552		; rotates in xy a series of graphic data passed in hl
36E6: E1          pop  hl
36E7: 01 0F 00    ld   bc,$000F		; advance to next entry
36EA: FD 09       add  iy,bc
36EC: C1          pop  bc
36ED: 10 E0       djnz $36CF		; repeat with remaining monks
36EF: FD E1       pop  iy
36F1: C9          ret

; called if delete state hasn't changed and control was pressed, to check if any function key was pressed
36F2: 06 0A       ld   b,$0A		; 10 keys
36F4: 21 AC 36    ld   hl,$36AC		; points to the function key table
36F7: 7E          ld   a,(hl)		; reads a key
36F8: 23          inc  hl
36F9: E5          push hl
36FA: C5          push bc
36FB: CD 72 34    call $3472		; checks if there was a state change in that key
36FE: C1          pop  bc
36FF: E1          pop  hl
3700: C0          ret  nz			; if so, exit
3701: 10 F4       djnz $36F7		; test for remaining keys
3703: C9          ret

; calculates in hl the position to save/load data, de points to current data and bc indicates data length
3704: 11 00 04    ld   de,$0400
3707: 21 00 54    ld   hl,$5400		; hl = 0x5400 + b*0x400 (so banks are stored at 0x5800-0x7fff)
370A: 19          add  hl,de
370B: 10 FD       djnz $370A
370D: F3          di
370E: 01 C6 7F    ld   bc,$7FC6		; loads abadia7
3711: ED 49       out  (c),c
3713: 11 7F 2D    ld   de,$2D7F		; source of data to copy
3716: 01 38 03    ld   bc,$0338		; amount of data to copy
3719: C9          ret

371A: 3A 30 30    ld   a,($3030)	; gets the lamp characteristics
371D: E6 80       and  $80
371F: 28 06       jr   z,$3727		; if the lamp is not picked up, jump
3721: 21 F3 2D    ld   hl,$2DF3		; indicates that adso has the lamp
3724: 22 32 30    ld   ($3032),hl

3727: 0E 80       ld   c,$80		; start with bit 7
3729: 06 08       ld   b,$08		; 8 objects
372B: DD 21 08 30 ld   ix,$3008		; points to object position data
372F: C5          push bc
3730: DD 7E 00    ld   a,(ix+$00)
3733: E6 80       and  $80
3735: 28 18       jr   z,$374F		; if the object is not picked up, jump
3737: 21 EF 2D    ld   hl,$2DEF		; points to the objects that characters have
373A: 06 05       ld   b,$05
373C: 7E          ld   a,(hl)
373D: A1          and  c
373E: 20 06       jr   nz,$3746		; if the character has the object, jump
3740: 11 07 00    ld   de,$0007
3743: 19          add  hl,de		; move to next entry
3744: 10 F6       djnz $373C
3746: 2B          dec  hl
3747: 2B          dec  hl
3748: 2B          dec  hl
3749: DD 75 02    ld   (ix+$02),l	; indicates that the character has the object
374C: DD 74 03    ld   (ix+$03),h
374F: 11 05 00    ld   de,$0005		; move to next object
3752: DD 19       add  ix,de
3754: C1          pop  bc
3755: CB 39       srl  c			; test next bit
3757: 10 D6       djnz $372F		; repeat until finishing objects

3759: 21 83 37    ld   hl,$3783		; points to the character position data table
375C: DD 21 D9 2D ld   ix,$2DD9		; points to door permissions
3760: FD 21 EC 2D ld   iy,$2DEC		; points to character objects
3764: 06 06       ld   b,$06		; 6 characters
3766: 7E          ld   a,(hl)
3767: DD 77 01    ld   (ix+$01),a	; sets the character's address for doors and objects
376A: FD 77 01    ld   (iy+$01),a
376D: 23          inc  hl
376E: 7E          ld   a,(hl)
376F: DD 77 02    ld   (ix+$02),a
3772: FD 77 02    ld   (iy+$02),a
3775: 23          inc  hl
3776: 11 03 00    ld   de,$0003
3779: DD 19       add  ix,de
377B: 11 07 00    ld   de,$0007
377E: FD 19       add  iy,de
3780: 10 E4       djnz $3766		; repeat until finishing characters
3782: C9          ret

3783: 	3038
	3047
	3056
	3065
	3074
	3083

; ------------------------- end of code related to pause/load/save games -----------------------------------

; this is never used???
378F: 00          nop
3790: 10 F0       djnz $3782
3792: 00          nop
3793: F0          ret  p
3794: F0          ret  p
3795: F0          ret  p
3796: 10 00       djnz $3798
3798: 00          nop
3799: 00          nop
379A: F0          ret  p
379B: 00          nop
379C: 10 10       djnz $37AE
379E: 00          nop
379F: 10 F0       djnz $3791
37A1: 10 00       djnz $37A3
37A3: 00          nop
37A4: C9          ret

; given in ix an address from the tile buffer, returns in hl the address relative to 0x9500
;  if carry is set, it's not a valid tile buffer address. Otherwise it is
37A5: DD E5       push ix
37A7: E1          pop  hl			; hl = ix (hl = a position within the tile buffer)
37A8: 11 80 8D    ld   de,$8D80		; de = start of tile buffer
37AB: A7          and  a
37AC: ED 52       sbc  hl,de		; hl =  hl - de
37AE: D8          ret  c			; if hl < de, exit with cf = 1
37AF: 11 80 07    ld   de,$0780
37B2: ED 52       sbc  hl,de		; hl = (hl - de) - 0x780
37B4: 3F          ccf				; complement carry flag
37B5: C9          ret

; called when initializing values after showing the scroll, and only the first time the game is loaded
37B6: 21 0E 38    ld   hl,$380E			; file copy routine

; performs a task with a series of byte blocks
37B9: 22 D2 37    ld   ($37D2),hl		; writes the routine to call
37BC: DD 21 DC 37 ld   ix,$37DC			; points to the block table
37C0: 21 03 01    ld   hl,$0103			; source/destination address of the block
37C3: DD 5E 00    ld   e,(ix+$00)		; de = source/destination address
37C6: DD 56 01    ld   d,(ix+$01)
37C9: 7A          ld   a,d				; if 0 was read, finish
37CA: B3          or   e
37CB: C8          ret  z
37CC: DD 4E 02    ld   c,(ix+$02)		; bc = block bytes
37CF: 06 00       ld   b,$00
37D1: CD 0E 38    call $380E			; calls the routine that processes the block
37D4: DD 23       inc  ix				; points to next entry
37D6: DD 23       inc  ix
37D8: DD 23       inc  ix
37DA: 18 E7       jr   $37C3			; repeat until finished

; table with blocks and bytes to do something
; character states
37DC: 3CA6 05
37DF: 3CC6 03
37E2: 3CE7 03
37E5: 3CFF 03
37E8: 3D11 03

37EB: 2D7F 0E	; obsequium, day and time of day, pointer to next time of day, table for sprite animation
		;  character followed by camera, pointer to height buffer, if mirror has been opened
37EE: 2DD9 10	; information about doors that characters can open
37F1: 2DEC 23	; data of objects that characters have
37F4: 2FE4 20	; game door data
37F7: 3008 23	; object positions

37FA: 3038 03	; william's position
37FD: 3047 03	; adso's position
3800: 3056 03	; malaquias' position
3803: 3065 03	; abbot's position
3806: 3074 03	; berengario's position
3809: 3083 03	; severino's position
380C: 0000

; copies bc bytes from de to hl
; bc = number of bytes to copy
; hl = data destination
; de = data source
380E: EB          ex   de,hl
380F: ED B0       ldir			; copies the selected bytes
3811: EB          ex   de,hl
3812: C9          ret

; copies bc bytes from hl to de
3813: ED B0       ldir
3815: C9          ret

; clears memory area from hl to hl + bc
3816: 36 00       ld   (hl),$00
3818: 5D          ld   e,l
3819: 54          ld   d,h
381A: 13          inc  de
381B: ED B0       ldir
381D: C9          ret

; initializes memory
381E: 21 85 3C    ld   hl,$3C85		; clears 0x3c85-0x3ca4 (logic data)
3821: 01 20 00    ld   bc,$0020
3824: CD 16 38    call $3816
3827: 21 8D 2D    ld   hl,$2D8D		; clears 0x2d8d-0x2dd8 (auxiliary variables for some routines)
382A: 01 4B 00    ld   bc,$004B
382D: CD 16 38    call $3816
3830: 21 13 38    ld   hl,$3813		; routine to call
3833: CD B9 37    call $37B9		; copies things from 0x0103-0x01a9 to many places (note: when initializing the reverse operation was done)

3836: 21 17 2E    ld   hl,$2E17		; points to the table with sprite data
3839: 11 14 00    ld   de,$0014		; each sprite takes 20 bytes
383C: 7E          ld   a,(hl)		; when it finds an entry with 0xff, exit
383D: FE FF       cp   $FF
383F: 28 05       jr   z,$3846
3841: 36 FE       ld   (hl),$FE		; sets all sprites as not visible
3843: 19          add  hl,de
3844: 18 F6       jr   $383C

3846: DD 21 36 30 ld   ix,$3036		; points to the character characteristics table
384A: 11 0F 00    ld   de,$000F		; each entry takes 15 bytes
384D: AF          xor  a
384E: 06 06       ld   b,$06		; 6 entries
3850: DD 77 00    ld   (ix+$00),a	; sets character animation counter to 0
3853: DD 77 01    ld   (ix+$01),a	; sets character orientation facing +x
3856: DD 77 05    ld   (ix+$05),a	; initially character occupies 4 positions
3859: DD 77 09    ld   (ix+$09),a	; indicates there are no character movements to process
385C: DD 36 0A FD ld   (ix+$0a),$FD	; action currently being executed
3860: DD 77 0B    ld   (ix+$0b),a	; initializes the index in the movement command table
3863: DD 19       add  ix,de		; move to next character
3865: 10 E9       djnz $3850
3867: C9          ret


; this routine is called to show the ending once the game has been completed
3868: 2A 12 33    ld   hl,($3312)
386B: E5          push hl
386C: 21 BC 32    ld   hl,$32BC
386F: 22 12 33    ld   ($3312),hl	; ensures that the IR routine reads from keyboard
3872: AF          xor  a
3873: 32 09 33    ld   ($3309),a
3876: 2A D1 33    ld   hl,($33D1)
3879: 2B          dec  hl
387A: 01 C5 7F    ld   bc,$7FC5		; sets configuration 5 (0, 5, 2, 3) (loads abadia6.bin at 0x4000)
387D: ED 49       out  (c),c
387F: 7E          ld   a,(hl)
3880: C6 08       add  a,$08
3882: 77          ld   (hl),a
3883: 01 C0 7F    ld   bc,$7FC0		; restores typical configuration
3886: ED 49       out  (c),c
3888: E1          pop  hl
3889: 11 FF 31    ld   de,$31FF
388C: A7          and  a
388D: ED 52       sbc  hl,de
388F: CC 95 04    call z,$0495		; jumps as if ctrl+tab had been pressed

3892: CD 3A 3F    call $3F3A		; sets black palette
3895: 01 C5 7F    ld   bc,$7FC5		; sets configuration 5 (0, 5, 2, 3) (loads abadia6.bin at 0x4000)
3898: ED 49       out  (c),c
389A: 21 00 70    ld   hl,$7000		; points to the code and data of the scroll routine
389D: 11 00 C0    ld   de,$C000		; points to destination
38A0: D5          push de
38A1: 01 00 10    ld   bc,$1000		; 0x1000 bytes
38A4: C5          push bc
38A5: ED B0       ldir				; copies the data to screen
38A7: 01 C7 7F    ld   bc,$7FC7		; sets configuration (0, 7, 2, 3) (loads abadia8.bin at 0x4000)
38AA: ED 49       out  (c),c
38AC: 11 00 80    ld   de,$8000		; points to destination
38AF: 21 28 6B    ld   hl,$6B28		; source of data
38B2: 01 18 15    ld   bc,$1518		; data length
38B5: ED B0       ldir				; copies the music and ending scroll text
38B7: 01 C0 7F    ld   bc,$7FC0		; restores usual configuration
38BA: ED 49       out  (c),c
38BC: 21 D8 8E    ld   hl,$8ED8		; points to the scroll graphic data
38BF: 11 8A 78    ld   de,$788A		; points to the address where scroll graphic data is expected to be
38C2: 01 00 06    ld   bc,$0600
38C5: ED B0       ldir				; copies the scroll graphic data
38C7: 3E 08       ld   a,$08
38C9: 32 86 10    ld   ($1086),a	; changes music tempo
38CC: C1          pop  bc
38CD: E1          pop  hl
38CE: 11 9D 65    ld   de,$659D		; copies the scroll routines from screen memory to where they were at the start
38D1: ED B0       ldir

38D3: 21 00 80    ld   hl,$8000		; points to the ending scroll music data
38D6: CD 3F 10    call $103F		; initializes the ending manuscript music
38D9: DD 21 30 83 ld   ix,$8330		; ix points to the text to show
38DD: CD 9D 65    call $659D		; calls the routine to show the manuscript
38E0: 18 F1       jr   $38D3		; if space is pressed, show the ending manuscript again

; punctuation symbol table
38E2: 	C0 -> 0x00 (0xfa) -> ¡
	BF -> 0x01 (0xfb) -> ?
	BB -> 0x02 (0xfc) -> ;
	BD -> 0x03 (0xfd) -> .
	BC -> 0x04 (0xfe) -> ,

; address of blank space character graphic data
38E7: 00 00 00 00 00 00 00 00

; table of instructions to modify a height calculation loop
38EF: 	00 00 -> 0 nop, nop (impossible case)
	3C 00 -> 1 inc a, nop
	00 3D -> 2 nop, dec a
	3D 00 -> 3 dec a, nop
	00 3C -> 4 nop, inc a
	00 00 -> 5 nop, nop (impossible case)

38CD: 00 4A

; routine to fill heights
38FD: F5          push af
38FE: 1A          ld   a,(de)		; modifies 2 instructions of the routine
38FF: 32 11 39    ld   ($3911),a
3902: 13          inc  de
3903: 1A          ld   a,(de)
3904: 32 16 39    ld   ($3916),a
3907: F1          pop  af			; a = initial height value of the block
3908: C5          push bc
3909: E5          push hl
390A: F5          push af
390B: 41          ld   b,c			; b = number of units in X
390C: 4F          ld   c,a
390D: CD 1D 39    call $391D		; if the position given in hl is within the buffer, modify it with c's height
3910: 79          ld   a,c
3911: 3C          inc  a			; instruction modified from outside to change height in x loop
3912: 2C          inc  l
3913: 10 F7       djnz $390C
3915: F1          pop  af
3916: 3C          inc  a			; instruction modified from outside to change height in y loop
3917: E1          pop  hl
3918: 24          inc  h
3919: C1          pop  bc
391A: 10 EC       djnz $3908		; repeat until completing units in Y
391C: C9          ret

; if the position given in hl is within the buffer, modify it with c's height
391D: 7C          ld   a,h
391E: D6 00       sub  $00			; adjusts coordinate to the start of visible in Y
3920: D8          ret  c
3921: FE 18       cp   $18			; if not visible, exit
3923: D0          ret  nc
3924: E5          push hl
3925: 6F          ld   l,a
3926: 26 00       ld   h,$00
3928: 29          add  hl,hl
3929: 29          add  hl,hl
392A: 29          add  hl,hl
392B: 54          ld   d,h
392C: 5D          ld   e,l
392D: 29          add  hl,hl
392E: 19          add  hl,de
392F: ED 5B 8A 2D ld   de,($2D8A)
3933: 19          add  hl,de
3934: EB          ex   de,hl
3935: E1          pop  hl
3936: 7D          ld   a,l
3937: D6 00       sub  $00			; adjusts coordinate to the start of visible in X
3939: D8          ret  c
393A: FE 18       cp   $18			; if not visible, exit
393C: D0          ret  nc
393D: 83          add  a,e
393E: 5F          ld   e,a
393F: 8A          adc  a,d
3940: 93          sub  e
3941: 57          ld   d,a
3942: 79          ld   a,c
3943: 12          ld   (de),a
3944: C9          ret

; fills the screen buffer at 0x2d8a with data read from abadia7 and cropped for the current screen
3945: DD E5       push ix
3947: DD 2A FB 38 ld   ix,($38FB)	; ix = address dependent on the floor the character is on
394B: 3A A9 27    ld   a,($27A9)	; retrieves the minimum x coordinate visible on screen
394E: 32 BA 39    ld   ($39BA),a	; modifies some instructions according to this
3951: 32 38 39    ld   ($3938),a
3954: 32 F0 39    ld   ($39F0),a
3957: 3A 9D 27    ld   a,($279D)	; retrieves the minimum y coordinate visible on screen
395A: 32 0B 3A    ld   ($3A0B),a	; modifies some instructions according to this
395D: 32 CA 39    ld   ($39CA),a
3960: 32 1F 39    ld   ($391F),a
3963: 01 C6 7F    ld   bc,$7FC6		; loads abadia7
3966: ED 49       out  (c),c
3968: CD 73 39    call $3973		; fills the screen buffer at 0x2d8a with data read from abadia7.bin
396B: 01 C0 7F    ld   bc,$7FC0		; restores usual configuration
396E: ED 49       out  (c),c
3970: DD E1       pop  ix
3972: C9          ret

entries:
	byte 0
		bits 7-4: initial height value
		bit 3: if 0, 4-byte entry. if 1, 5-byte entry
		bit 2-0: screen element type
			if 0, 6 or 7, exit
			if 1 to 4 crop (changing height)
			if 5, crop (constant height)
	byte 1: starting X coordinate
	byte 2: starting Y coordinate
	byte 3:	if length == 4 bytes
		bits 7-4: number of units in X
		bits 3-0: number of units in Y
			if length == 5 bytes
		bits 7-0: number of units in X
	byte 4 number of units in Y

; ix points to abadia7.bin data related to the floor
3973: DD 7E 00    ld   a,(ix+$00)	; reads a byte
3976: FE FF       cp   $FF			; if end of data reached, exit
3978: C8          ret  z
3979: 57          ld   d,a
397A: E6 07       and  $07			; if the 3 least significant bits of the read byte are 0, exit
397C: C8          ret  z
397D: FE 06       cp   $06			; if (data & 0x07) >= 0x06, exit
397F: D0          ret  nc
3980: CB 5A       bit  3,d			; if entry is 4 bytes, read last byte in a and jump
3982: DD 7E 03    ld   a,(ix+$03)
3985: 28 05       jr   z,$398C
3987: DD 46 04    ld   b,(ix+$04)	; otherwise, read last byte in b and jump
398A: 18 0B       jr   $3997

398C: 4F          ld   c,a		; c = byte 3
398D: E6 0F       and  $0F
398F: 47          ld   b,a		; b = 4 least significant bits of byte 3
3990: 79          ld   a,c

3991: 0F          rrca
3992: 0F          rrca
3993: 0F          rrca
3994: 0F          rrca
3995: E6 0F       and  $0F		; a = 4 most significant bits of byte 3

3997: 4F          ld   c,a		; c = value 1
3998: 7A          ld   a,d		; a = byte 0
3999: 0F          rrca
399A: 0F          rrca
399B: 0F          rrca
399C: 0F          rrca
399D: E6 0F       and  $0F			; gets the 4 upper bits of byte 0
399F: DD 6E 01    ld   l,(ix+$01)	; hl = address of bytes 1 and 2
39A2: DD 66 02    ld   h,(ix+$02)
39A5: DD CB 00 5E bit  3,(ix+$00)
39A9: 28 02       jr   z,$39AD		; advance the entry 4 or 5 bytes
39AB: DD 23       inc  ix
39AD: DD 23       inc  ix
39AF: DD 23       inc  ix
39B1: DD 23       inc  ix
39B3: DD 23       inc  ix

; arrives here with the parameters:
; a = bits 7-4 of byte 0
; c = block length in x
; b = block length in y
; l = initial x coordinate of the block
; h = initial y coordinate of the block
; If bit 3 of the read byte 0 is 1, b and c will be 8-bit numbers. Otherwise they will be 4 bits
39B5: 08          ex   af,af'		; saves a
39B6: 04          inc  b
39B7: 0C          inc  c
39B8: 7D          ld   a,l			; gets the initial X coordinate of the block
39B9: D6 00       sub  $00			; adjusts the coordinate to the start of what's visible in X
39BB: 30 07       jr   nc,$39C4		; if X coordinate >= lower limit in X, jump
39BD: ED 44       neg				; a = difference between the lower limit in X and the X coordinate
39BF: B9          cp   c			; if the difference >= c, go to the next entry
39C0: 30 B1       jr   nc,$3973
39C2: 18 04       jr   $39C8		; otherwise, check if visible in y

39C4: FE 18       cp   $18			; if X coordinate >= upper limit in X, go to the next entry
39C6: 30 AB       jr   nc,$3973

; if it reaches here, it's because this entry is valid in x
39C8: 7C          ld   a,h			; gets the starting Y coordinate of the block
39C9: D6 00       sub  $00			; adjusts the position to the start of what's visible in Y
39CB: 30 07       jr   nc,$39D4		; if Y coordinate > lower limit in Y, jump
39CD: ED 44       neg				; a = difference between the lower limit in y and the Y coordinate
39CF: B8          cp   b			; if the difference >= b, go to the next entry
39D0: 30 A1       jr   nc,$3973
39D2: 18 04       jr   $39D8

39D4: FE 18       cp   $18			; if Y coordinate >= upper limit in Y, go to the next entry
39D6: 30 9B       jr   nc,$3973

; if it enters here, it's because something from the entry is visible
39D8: 7A          ld   a,d			; a = initial height of the block
39D9: E6 07       and  $07			; keeps the 3 lower bits
39DB: FE 05       cp   $05
39DD: 28 0F       jr   z,$39EE		; if it's a 5, jump
39DF: 87          add  a,a
39E0: 11 EF 38    ld   de,$38EF		; otherwise, index into the instruction table to modify a loop of the height calculation
39E3: 83          add  a,e			; de = de + a
39E4: 5F          ld   e,a
39E5: 8A          adc  a,d
39E6: 93          sub  e
39E7: 57          ld   d,a
39E8: 08          ex   af,af'		; recover the value of byte 0
39E9: CD FD 38    call $38FD
39EC: 18 85       jr   $3973

; clip in X
39EE: 7D          ld   a,l			; gets the current X coordinate of the entry
39EF: D6 00       sub  $00			; adjusts the coordinate to the start of what's visible in X
39F1: 30 0C       jr   nc,$39FF		; if X coordinate > lower limit in X, jump
39F3: 81          add  a,c			; finds the last X coordinate of this entry
39F4: FE 18       cp   $18			; if the last X coordinate <= upper limit in X, jump
39F6: 38 02       jr   c,$39FA		;  otherwise truncate the last X coordinate to the X limit
39F8: 3E 18       ld   a,$18

39FA: 4F          ld   c,a			; c = number of elements to draw in X
39FB: 2E 00       ld   l,$00		; l = initial position in X
39FD: 18 0A       jr   $3A09		; go to clip in Y

; arrives here if X coordinate > lower limit in X
39FF: 6F          ld   l,a		; l = initial position in X
3A00: 81          add  a,c		; add to the initial position the number of elements in X
3A01: D6 18       sub  $18		; if final X coordinate <= upper limit in X, jump
3A03: 38 04       jr   c,$3A09
3A05: ED 44       neg			; a = difference between the upper limit in X and the final X coordinate
3A07: 81          add  a,c
3A08: 4F          ld   c,a		; c = number of elements to draw in X

; arrives here after clipping in X
3A09: 7C          ld   a,h			; gets the current Y coordinate of the entry
3A0A: D6 00       sub  $00			; adjusts the coordinate to the start of what's visible in Y
3A0C: 30 0C       jr   nc,$3A1A		; if Y coordinate > lower limit in Y, jump
3A0E: 80          add  a,b			; finds the last Y coordinate of this entry
3A0F: FE 18       cp   $18			; if the last Y coordinate <= upper limit in Y, jump
3A11: 38 02       jr   c,$3A15
3A13: 3E 18       ld   a,$18
3A15: 47          ld   b,a			; b = number of elements to draw in y
3A16: 26 00       ld   h,$00		; h = initial position in Y
3A18: 18 0A       jr   $3A24

; arrives here if Y coordinate > lower limit in Y
3A1A: 67          ld   h,a			; h = initial position in Y
3A1B: 80          add  a,b			; add to the initial position the number of elements in Y
3A1C: D6 18       sub  $18			; if final Y coordinate <= upper limit in Y, jump
3A1E: 38 04       jr   c,$3A24
3A20: ED 44       neg				; a = difference between the upper limit in Y and the final Y coordinate
3A22: 80          add  a,b
3A23: 47          ld   b,a			; b = number of elements to draw in Y

; the entry arrives here once it has been clipped in X and Y
; l = initial position in X
; h = initial position in Y
; c = number of elements to draw in X
; b = number of elements to draw in Y
3A24: 7D          ld   a,l			; a = initial position in X
3A25: 6C          ld   l,h			; l = initial position in Y
3A26: 26 00       ld   h,$00
3A28: 29          add  hl,hl
3A29: 29          add  hl,hl
3A2A: 29          add  hl,hl
3A2B: 54          ld   d,h			; de = 8*hl
3A2C: 5D          ld   e,l
3A2D: 29          add  hl,hl
3A2E: 19          add  hl,de		; hl = 24*hl
3A2F: ED 5B 8A 2D ld   de,($2D8A)	; reads the address of the screen buffer
3A33: 85          add  a,l			; hl = hl + initial pos in X
3A34: 6F          ld   l,a
3A35: 8C          adc  a,h
3A36: 95          sub  l
3A37: 67          ld   h,a
3A38: 19          add  hl,de		; hl = offset in the screen buffer for the initial position in X and Y
3A39: 11 18 00    ld   de,$0018		; each line occupies 24 bytes
3A3C: 08          ex   af,af'		; recover the 4 most significant bits of byte 0
3A3D: C5          push bc
3A3E: E5          push hl
3A3F: 41          ld   b,c			; b = width
3A40: 77          ld   (hl),a
3A41: 23          inc  hl
3A42: 10 FC       djnz $3A40		; write the value traversing the width
3A44: E1          pop  hl
3A45: 19          add  hl,de		; go to the next line
3A46: C1          pop  bc
3A47: 10 F4       djnz $3A3D		; continue processing the height
3A49: C3 73 39    jp   $3973		; continue processing the rest of elements

; here should be the routine that draws the map of the current screen, but for the final version it was removed
3A4C: C9          ret

; returns in hl the address of the next screen line
3A4D: 7C          ld   a,h			; go to the next bank
3A4E: C6 08       add  a,$08
3A50: 38 02       jr   c,$3A54
3A52: 67          ld   h,a
3A53: C9          ret

3A54: 7C          ld   a,h			; if there is carry, go to the next line and adjust so it's in the range 0xc000-0xffff
3A55: E6 C7       and  $C7
3A57: 67          ld   h,a
3A58: 3E 50       ld   a,$50
3A5A: 85          add  a,l
3A5B: 6F          ld   l,a
3A5C: D0          ret  nc
3A5D: 8C          adc  a,h
3A5E: 95          sub  l
3A5F: 67          ld   h,a
3A60: C9          ret

; The memory configuration when reaching this point is:
banks: (0, 1, 2, 3)
0 -> abadia1 (from 0x0100)
1 -> abadia2
2 -> abadia3
3 -> abadia3 (with one overwritten tile and the first 0x1000 bytes overwritten)
4 -> abadia5
5 -> abadia6
6 -> abadia7
7 -> abadia8

; creates a table to flip x to 4 pixels, and also initiates the mirror room data
3A61: 21 00 A1    ld   hl,$A100		; point to the memory where to create the table
3A64: 7D          ld   a,l
3A65: E6 F0       and  $F0
3A67: 4F          ld   c,a			; c = 4 most significant bits of l
3A68: 7D          ld   a,l
3A69: E6 0F       and  $0F			; a = 4 least significant bits of l
3A6B: CB 11       rl   c
3A6D: 1F          rra
3A6E: CB 11       rl   c
3A70: 1F          rra
3A71: CB 11       rl   c
3A73: 1F          rra
3A74: CB 11       rl   c
3A76: 1F          rra
3A77: CB 11       rl   c
3A79: B1          or   c			; a = b4 b5 b6 b7 b0 b1 b2 b3
3A7A: 77          ld   (hl),a
3A7B: 2C          inc  l
3A7C: 20 E6       jr   nz,$3A64		; complete the table

3A7E: 21 86 50    ld   hl,$5086		; point to abadia7 data (height data of floor 2)
3A81: 01 C6 7F    ld   bc,$7FC6		; set configuration 6 (0, 6, 2, 3)
3A84: ED 49       out  (c),c
3A86: CD C2 3A    call $3AC2		; increment hl until the end of the height data of floor 2
3A89: 01 C7 7F    ld   bc,$7FC7		; set configuration 7 (0, 7, 2, 3)
3A8C: ED 49       out  (c),c
3A8E: 22 D9 34    ld   ($34D9),hl	; save the end of table pointer (which points to the mirror room data)

3A91: 06 72       ld   b,$72		; 114 screens
3A93: 21 00 40    ld   hl,$4000		; point to abadia8 data
3A96: 7E          ld   a,(hl)		; read the number of bytes of the screen
3A97: 85          add  a,l
3A98: 6F          ld   l,a			; advance to the next screen
3A99: 8C          adc  a,h
3A9A: 95          sub  l
3A9B: 67          ld   h,a
3A9C: 10 F8       djnz $3A96

; hl points to the mirror room
3A9E: 06 00       ld   b,$00		; up to 256 blocks
3AA0: 7E          ld   a,(hl)		; read a byte
3AA1: 23          inc  hl
3AA2: FE 1F       cp   $1F			; if it's not 0x1f, jump
3AA4: 20 19       jr   nz,$3ABF
3AA6: 7E          ld   a,(hl)		; if it's 0x1f, read the next 2 bytes
3AA7: 23          inc  hl
3AA8: 4E          ld   c,(hl)
3AA9: 2B          dec  hl
3AAA: FE AA       cp   $AA			; if the next byte of the block is not 0xaa, keep advancing
3AAC: 20 11       jr   nz,$3ABF
3AAE: 79          ld   a,c
3AAF: FE 51       cp   $51			; if the second byte of the block is not 0x51, keep advancing
3AB1: 20 0C       jr   nz,$3ABF

3AB3: 23          inc  hl			; if it reaches here, the room data indicates the mirror is open
3AB4: 36 11       ld   (hl),$11		;  so modify the room so the mirror closes
3AB6: 22 E0 34    ld   ($34E0),hl	; save the offset of the mirror screen in abadia8.bin
3AB9: 01 C0 7F    ld   bc,$7FC0		; set configuration 0 (0, 1, 2, 3)
3ABC: ED 49       out  (c),c
3ABE: C9          ret

3ABF: 10 DF       djnz $3AA0
3AC1: C9          ret

; increment hl until finding the end of the table
3AC2: 7E          ld   a,(hl)		; read a byte
3AC3: FE FF       cp   $FF			; 0xff indicates the end
3AC5: C8          ret  z
3AC6: CB 5F       bit  3,a
3AC8: 28 01       jr   z,$3ACB
3ACA: 23          inc  hl			; increment the address 4 or 5 bytes depending on bit 3
3ACB: 23          inc  hl
3ACC: 23          inc  hl
3ACD: 23          inc  hl
3ACE: 23          inc  hl
3ACF: 18 F1       jr   $3AC2

; generates 4 tables of 0x100 bytes for pixel handling through AND and OR operations at 0x9d00 to 0xa0ff
3AD1: 01 00 9D    ld   bc,$9D00	; point to abadia3 data that has already been copied before, so it can be overwritten without problem
3AD4: 79          ld   a,c		; a = b7 b6 b5 b4 b3 b2 b1 b0
3AD5: E6 F0       and  $F0		; a = b7 b6 b5 b4 0 0 0 0
3AD7: 57          ld   d,a		; d = b7 b6 b5 b4 0 0 0 0
3AD8: 79          ld   a,c		; a = b7 b6 b5 b4 b3 b2 b1 b0
3AD9: 0F          rrca			; a = b0 b7 b6 b5 b4 b3 b2 b1
3ADA: 0F          rrca			; a = b1 b0 b7 b6 b5 b4 b3 b2
3ADB: 0F          rrca			; a = b2 b1 b0 b7 b6 b5 b4 b3
3ADC: 0F          rrca			; a = b3 b2 b1 b0 b7 b6 b5 b4
3ADD: 5F          ld   e,a		; e = b3 b2 b1 b0 b7 b6 b5 b4
3ADE: A1          and  c		; a = b3&b7 b2&b6 b1&b5 b0&b4 b3&b7 b2&b6 b1&b5 b0&b4
3ADF: E6 0F       and  $0F		; a = 0 0 0 0 b3&b7 b2&b6 b1&b5 b0&b4
3AE1: B2          or   d		; a = b7 b6 b5 b4 b3&b7 b2&b6 b1&b5 b0&b4
3AE2: 02          ld   (bc),a	; write pixel i = (Pi1&Pi0 Pi0) (0->0, 1->1, 2->0, 3->3)

3AE3: 04          inc  b		; point to the next table
3AE4: 7B          ld   a,e		; a = b3 b2 b1 b0 b7 b6 b5 b4
3AE5: A9          xor  c		; a = b3^b7 b2^b6 b1^b5 b0^b4 b3^b7 b2^b6 b1^b5 b0^b4
3AE6: A1          and  c		; a = (b3^b7)&b7 (b2^b6)&b6 (b1^b5)&b5 (b0^b4)&b4 (b3^b7)&b3 (b2^b6)&b2 (b1^b5)&b1 (b0^b4)&b0
3AE7: E6 0F       and  $0F		; a = 0 0 0 0 (b3^b7)&b3 (b2^b6)&b2 (b1^b5)&b1 (b0^b4)&b0
3AE9: 57          ld   d,a		; d = 0 0 0 0 (b3^b7)&b3 (b2^b6)&b2 (b1^b5)&b1 (b0^b4)&b0
3AEA: 87          add  a,a		; a = 0 0 0 (b3^b7)&b3 (b2^b6)&b2 (b1^b5)&b1 (b0^b4)&b0 0
3AEB: 87          add  a,a		; a = 0 0 (b3^b7)&b3 (b2^b6)&b2 (b1^b5)&b1 (b0^b4)&b0 0 0
3AEC: 87          add  a,a		; a = 0 (b3^b7)&b3 (b2^b6)&b2 (b1^b5)&b1 (b0^b4)&b0 0 0 0
3AED: 87          add  a,a		; a = (b3^b7)&b3 (b2^b6)&b2 (b1^b5)&b1 (b0^b4)&b0 0 0 0 0
3AEE: B2          or   d		; a = (b3^b7)&b3 (b2^b6)&b2 (b1^b5)&b1 (b0^b4)&b0 (b7^b3)&b3 (b6^b2)&b2 (b5^b1)&b1 (b0^b4)&b0
3AEF: 02          ld   (bc),a	; write pixel i = ((Pi1^Pi0)&Pi1 (Pi1^Pi0)&Pi1) (0->0, 1->0, 2->3, 3->0)

3AF0: 04          inc  b		; point to the next table
3AF1: 79          ld   a,c		; a = b7 b6 b5 b4 b3 b2 b1 b0
3AF2: E6 0F       and  $0F		; a = 0 0 0 0 b3 b2 b1 b0
3AF4: 57          ld   d,a		; d = 0 0 0 0 b3 b2 b1 b0
3AF5: 7B          ld   a,e		; a = b3 b2 b1 b0 b7 b6 b5 b4
3AF6: A1          and  c		; a = b3&b7 b2&b6 b1&b5 b0&b4 b3&b7 b2&b6 b1&b5 b0&b4
3AF7: E6 F0       and  $F0		; a = b3&b7 b2&b6 b1&b5 b0&b4 0 0 0 0
3AF9: B2          or   d		; a = b3&b7 b2&b6 b1&b5 b0&b4 b3 b2 b1 b0
3AFA: 02          ld   (bc),a	; write pixel i = (Pi1 Pi1&Pi0) (0->0, 1->0, 2->2, 3->3)

3AFB: 04          inc  b		; point to the next table
3AFC: 7B          ld   a,e		; a = b3 b2 b1 b0 b7 b6 b5 b4
3AFD: A9          xor  c		; a = b3^b7 b2^b6 b1^b5 b0^b4 b7^b3 b6^b2 b5^b1 b4^b0
3AFE: A1          and  c		; a = (b3^b7)&b7 (b2^b6)&b6 (b1^b5)&b5 (b0^b4)&b4 (b7^b3)&b3 (b6^b2)&b2 (b5^b1)&b1 (b4^b0)&b0
3AFF: E6 F0       and  $F0		; a = (b3^b7)&b7 (b2^b6)&b6 (b1^b5)&b5 (b0^b4)&b4 0 0 0 0
3B01: 57          ld   d,a		; d = (b3^b7)&b7 (b2^b6)&b6 (b1^b5)&b5 (b0^b4)&b4 0 0 0 0
3B02: CB 3F       srl  a		; a = 0 (b3^b7)&b7 (b2^b6)&b6 (b1^b5)&b5 (b0^b4)&b4 0 0 0
3B04: CB 3F       srl  a		; a = 0 0 (b3^b7)&b7 (b2^b6)&b6 (b1^b5)&b5 (b0^b4)&b4 0 0
3B06: CB 3F       srl  a		; a = 0 0 0 (b3^b7)&b7 (b2^b6)&b6 (b1^b5)&b5 (b0^b4)&b4 0
3B08: CB 3F       srl  a		; a = 0 0 0 0 (b3^b7)&b7 (b2^b6)&b6 (b1^b5)&b5 (b0^b4)&b4
3B0A: B2          or   d		; a = (b3^b7)&b7 (b2^b6)&b6 (b1^b5)&b5 (b0^b4)&b4 (b3^b7)&b7 (b2^b6)&b6 (b1^b5)&b5 (b0^b4)&b4
3B0B: 02          ld   (bc),a	; write pixel i = ((Pi1^Pi0)&Pi0 (Pi1^Pi0)&Pi0) (0->0, 1->3, 2->0, 3->0)

3B0C: 05          dec  b		; point to the initial table
3B0D: 05          dec  b
3B0E: 05          dec  b
3B0F: 0C          inc  c		; continue until completing the possible cases
3B10: 20 C2       jr   nz,$3AD4
3B12: C9          ret

; prints a character in the scoreboard
3B13: 0E FF       ld   c,$FF
3B15: 18 02       jr   $3B19

; prints the character passed in a on the screen
;  uses the screen position at 0x2d97
3B17: 0E 0F       ld   c,$0F		; c is used to adjust the color
3B19: E6 7F       and  $7F			; ensures the character is between 0 and 127
3B1B: FE 20       cp   $20
3B1D: 11 E7 38    ld   de,$38E7		; de = address of the blank space
3B20: 28 0E       jr   z,$3B30		; if the character to print is a space, jump
3B22: D6 2D       sub  $2D          ; if the character to print is < 0x2d, it's not printable and exit
3B24: D8          ret  c

3B25: 6F          ld   l,a			; each character in the character table occupies 8 bytes
3B26: 26 00       ld   h,$00		; hl = 8*(a - 0x2d)
3B28: 29          add  hl,hl
3B29: 29          add  hl,hl
3B2A: 29          add  hl,hl
3B2B: 11 00 B4    ld   de,$B400
3B2E: 19          add  hl,de		; the character graphics table starts at 0xb400
3B2F: EB          ex   de,hl		; de = character address
3B30: 2A 97 2D    ld   hl,($2D97)	; read the screen address currently being written to (h = y in pixels, l = x in bytes)
3B33: E5          push hl
3B34: CD 42 3C    call $3C42		; convert hl to screen address
3B37: 06 08       ld   b,$08		; 8 lines
3B39: 1A          ld   a,(de)		; read a byte that forms the character
3B3A: E6 F0       and  $F0			; keep the 4 upper bits (4 left pixels of the character)
3B3C: A9          xor  c
3B3D: 77          ld   (hl),a		; write the byte to screen
3B3E: 1A          ld   a,(de)		; read the byte that forms the character
3B3F: 87          add  a,a
3B40: 87          add  a,a
3B41: 87          add  a,a
3B42: 87          add  a,a			; keep the 4 lower bits in the upper part (4 right pixels of the character)
3B43: 23          inc  hl
3B44: A9          xor  c
3B45: 77          ld   (hl),a		; write the byte to screen
3B46: 2B          dec  hl
3B47: CD 4D 3A    call $3A4D		; go to the next screen line
3B4A: 13          inc  de			; point to the next byte of the character
3B4B: 10 EC       djnz $3B39		; repeat for 8 lines
3B4D: E1          pop  hl
3B4E: 2C          inc  l			; advance 8 pixels for the next execution
3B4F: 2C          inc  l
3B50: 22 97 2D    ld   ($2D97),hl	; save the new pointer
3B53: C9          ret

; -------------------------- code related to writing phrases on the scoreboard --------------------------------------
; called from the interrupt
3B54: F3          di
3B55: 3A 9A 2D    ld   a,($2D9A)
3B58: 3C          inc  a
3B59: FE 2D       cp   $2D
3B5B: 32 9A 2D    ld   ($2D9A),a		; if it's not 45 exit
3B5E: C0          ret  nz

3B5F: AF          xor  a				; keep between 0 and 44
3B60: 32 9A 2D    ld   ($2D9A),a

3B63: 3A A2 2D    ld   a,($2DA2)		; if not displaying a phrase, exit
3B66: A7          and  a
3B67: C8          ret  z

3B68: DD E5       push ix
3B6A: E5          push hl
3B6B: 2A 97 2D    ld   hl,($2D97)		; save the value of this variable, as it will be modified
3B6E: E5          push hl
3B6F: D5          push de
3B70: C5          push bc
3B71: 08          ex   af,af'
3B72: F5          push af
3B73: CD 20 10    call $1020			; start music entry 3

3B76: 3A A0 2D    ld   a,($2DA0)
3B79: 3D          dec  a
3B7A: 28 5B       jr   z,$3BD7			; if 0x2ad0 was 1, jump (a word has finished)

3B7C: 2A 9C 2D    ld   hl,($2D9C)		; get the address of the text being placed in the scoreboard
3B7F: CB 7E       bit  7,(hl)
3B81: 28 05       jr   z,$3B88			; if bit 7 is not set, jump
3B83: 3E 01       ld   a,$01
3B85: 32 A0 2D    ld   ($2DA0),a		; indicate that the word has finished

3B88: 7E          ld   a,(hl)
3B89: E6 07       and  $07				; keep the 3 least significant bits of the current letter
3B8B: 32 89 13    ld   ($1389),a		; modify the voice tones
3B8E: 32 8F 13    ld   ($138F),a
3B91: ED 44       neg
3B93: 32 8C 13    ld   ($138C),a
3B96: 7E          ld   a,(hl)			; get the 7 least significant bits of the current letter
3B97: E6 7F       and  $7F
3B99: 23          inc  hl
3B9A: 22 9C 2D    ld   ($2D9C),hl		; update the pointer to the text data

; scrolls the phrase part of the scoreboard and paints the character in a
3B9D: F5          push af
3B9E: 21 5A E6    ld   hl,$E65A		; hl points to the phrase screen area (104, 164)
3BA1: 01 1E 08    ld   bc,$081E		; b = 8 lines, c = 30 bytes
3BA4: E5          push hl
3BA5: C5          push bc
3BA6: 06 00       ld   b,$00
3BA8: 54          ld   d,h			; de = hl
3BA9: 5D          ld   e,l
3BAA: 1B          dec  de
3BAB: 1B          dec  de
3BAC: ED B0       ldir				; perform scroll 30 bytes to the left
3BAE: C1          pop  bc
3BAF: E1          pop  hl
3BB0: CD 4D 3A    call $3A4D		; go to the next line
3BB3: 10 EF       djnz $3BA4		; complete the 8 lines

3BB5: 21 2E A4    ld   hl,$A42E		; position (h = y in pixels, l = x in bytes) (184, 164)
3BB8: 22 97 2D    ld   ($2D97),hl	; set the position where the character should be drawn (used by routine 0x3b13)
3BBB: C1          pop  bc			; recover the parameter it was called with
3BBC: 78          ld   a,b			; get the letter to place
3BBD: FE 20       cp   $20			; is it a blank space?
3BBF: 3E 06       ld   a,$06
3BC1: 20 01       jr   nz,$3BC4
3BC3: AF          xor  a			; if it's a blank space, set 0
3BC4: 32 C2 13    ld   ($13C2),a	; modify the envelope and volume change table for the voice
3BC7: 78          ld   a,b
3BC8: CD 13 3B    call $3B13		; print a character in the scoreboard
3BCB: F1          pop  af
3BCC: 08          ex   af,af'
3BCD: C1          pop  bc
3BCE: D1          pop  de
3BCF: E1          pop  hl
3BD0: 22 97 2D    ld   ($2D97),hl	; restore the value of this variable, as it has been modified
3BD3: E1          pop  hl
3BD4: DD E1       pop  ix
3BD6: C9          ret

; arrives here if a word has finished (0x2da0 = 1)
3BD7: 3A 9B 2D    ld   a,($2D9B)	; read the characters remaining to say
3BDA: A7          and  a
3BDB: 28 0F       jr   z,$3BEC		; if there are still many left to say, jump
3BDD: 3D          dec  a
3BDE: 32 9B 2D    ld   ($2D9B),a	; decrement the characters remaining to say
3BE1: 3E 20       ld   a,$20
3BE3: 20 B8       jr   nz,$3B9D		; scroll the phrase part of the scoreboard and paint a blank space

3BE5: AF          xor  a			; if the phrase has finished (characters to say = 0), indicate it
3BE6: 32 A2 2D    ld   ($2DA2),a
3BE9: C3 CB 3B    jp   $3BCB		; restore the registers and exit

; arrives here if there are still characters left to say
3BEC: 32 A0 2D    ld   ($2DA0),a
3BEF: 2A 9E 2D    ld   hl,($2D9E)	; get the pointer to the current voice data
3BF2: 7E          ld   a,(hl)		; read a byte
3BF3: FE FF       cp   $FF
3BF5: 20 0C       jr   nz,$3C03		; if the voice data hasn't finished, jump
3BF7: 3E 11       ld   a,$11
3BF9: 32 9B 2D    ld   ($2D9B),a	; indicate that 11 characters remain to be displayed
3BFC: 3E 01       ld   a,$01
3BFE: 32 A0 2D    ld   ($2DA0),a	; indicate that the word has finished
3C01: 18 D4       jr   $3BD7

3C03: FE FA       cp   $FA			; if not >= 0xfa, continue
3C05: 30 21       jr   nc,$3C28
3C07: 23          inc  hl
3C08: FE F9       cp   $F9
3C0A: 0E 20       ld   c,$20		; c = blank space
3C0C: 38 04       jr   c,$3C12		; if the value is < 0xf9, jump
3C0E: 0E 00       ld   c,$00		; c = 00, no blank space
3C10: 7E          ld   a,(hl)		; if the read value is 0xf9, the next word must be said following the current one
3C11: 23          inc  hl

3C12: 22 9E 2D    ld   ($2D9E),hl	; update the address of the voice data

3C15: 21 80 B5    ld   hl,$B580		; point to the word table
3C18: 47          ld   b,a
3C19: A7          and  a
3C1A: C4 3A 3C    call nz,$3C3A		; if the byte read was not 0, search for the corresponding entry in the word table
3C1D: 22 9C 2D    ld   ($2D9C),hl	; save the word address
3C20: 79          ld   a,c
3C21: A7          and  a
3C22: CA 76 3B    jp   z,$3B76		; depending on c, jump to scroll and paint the character, or return to the beginning to process the next character
3C25: C3 9D 3B    jp   $3B9D		; scroll the phrase part of the scoreboard and paint the character in a

; arrives here if the read value is greater than or equal to 0xfa
3C28: D6 FA       sub  $FA
3C2A: 23          inc  hl
3C2B: 22 9E 2D    ld   ($2D9E),hl	; update the address of the phrase data
3C2E: 21 E2 38    ld   hl,$38E2		; hl points to the punctuation marks table
3C31: CD 2D 16    call $162D		; hl = hl + a
3C34: 22 9C 2D    ld   ($2D9C),hl	; change the address of the text being placed in the scoreboard
3C37: C3 76 3B    jp   $3B76

; search for entry number b in the word table
3C3A: CB 7E       bit  7,(hl)		; search for the end of the current word
3C3C: 23          inc  hl
3C3D: 28 FB       jr   z,$3C3A		; repeat until the current entry finishes
3C3F: 10 F9       djnz $3C3A		; repeat until finding the entry
3C41: C9          ret

; given hl (Y,X coordinates), calculates the corresponding screen offset
; the calculated value is added 32 pixels to the right (since the game area goes from x = 32 to x = 256 + 32 - 1
; l = X coordinate (in bytes)
; h = Y coordinate (in pixels)
3C42: D5          push de
3C43: 7D          ld   a,l
3C44: 08          ex   af,af'
3C45: 7C          ld   a,h
3C46: E6 F8       and  $F8			; get the value to calculate the offset within the VRAM bank
3C48: 6F          ld   l,a
3C49: 7C          ld   a,h
3C4A: 26 00       ld   h,$00
3C4C: 29          add  hl,hl		; within each bank, the line to go to can be calculated as (y & 0xf8)*10
3C4D: 54          ld   d,h			;  or what is the same, (y >> 3)*0x50
3C4E: 5D          ld   e,l
3C4F: 29          add  hl,hl
3C50: 29          add  hl,hl
3C51: 19          add  hl,de		; hl = offset within the bank
3C52: E6 07       and  $07          ; a = 3 least significant bits in y (to calculate the VRAM bank it goes to)
3C54: 87          add  a,a
3C55: 87          add  a,a
3C56: 87          add  a,a			; adjust the 3 bits
3C57: B4          or   h			; complete the bank calculation
3C58: F6 C0       or   $C0			; adjust so it's within 0xc000-0xffff
3C5A: 67          ld   h,a
3C5B: 08          ex   af,af'
3C5C: 85          add  a,l			; add the offset in x
3C5D: 6F          ld   l,a
3C5E: 8C          adc  a,h
3C5F: 95          sub  l
3C60: 67          ld   h,a
3C61: 11 08 00    ld   de,$0008		; adjust to be 32 pixels to the right
3C64: 19          add  hl,de
3C65: D1          pop  de
3C66: C9          ret
; ----------------------- end of code related to writing phrases on the scoreboard -----------------------------

; table to modify room access according to the keys held. 6 entries (one per door) of 5 bytes
; byte 0: room index in the ground floor room matrix
; byte 1: permissions for that room
; byte 2: room index in the ground floor room matrix
; byte 3: permissions for that room
; byte 4: 0xff
3C67: 	35 01 36 04 FF	; between room (3, 5) = 0x3e and (3, 6) = 0x3d there is a door (the abbot's room)
	1B 08 2B 02 FF	; between room (1, b) = 0x00 and (2, b) = 0x38 there is a door (the monks' room)
	56 08 66 02 FF	; between room (5, 6) = 0x3d and (6, 6) = 0x3c there is a door (severino's room)
	29 01 2A 04 FF	; between room (2, 9) = 0x29 and (2, a) = 0x37 there is a door (the exit from the rooms towards the church)
	27 01 28 04 FF	; between room (2, 7) = 0x28 and (2, 8) = 0x26 there is a door (the passage behind the kitchen)
	75 01 76 04 FF	; between room (7, 5) = 0x11 and (7, 6) = 0x12 there is a door (that blocks the way to the left part of the ground floor)

; ----------------------- code related to the character behavior interpreter -----------------------------

3C85-3CA5: variables related to the logic

	00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	04 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	00

; copied to 0x103-0x107. predefined positions of malaquias
3CA6: EF 02
	FA 00 00
3CAB:
	84 48 42 -> church
	2F 37 02 -> refectory
	37 38 4F -> position at the table at the entrance to the corridor to be able to go up to the library
	3A 34 8F -> position to block the corridor leading to the library
	5D 77 00 -> position to close the 2 doors of the left wing of the abbey
	58 2A 00 -> position in front of the kitchen table in front of the passage
	35 37 53 -> position where he leaves the key on the table at the entrance to the corridor to be able to go up to the library
	BC 18 02 -> position in his cell
	68 52 02 -> severino's cell

; copied to 0x108-0x10a. predefined positions of the abbot
3CC6: FA 00 00
3CC9:
	88 3C C4 -> position at the church altar
	3D 37 82 -> position in the refectory
	54 3C 02 -> position in his cell
	88 84 C2 -> position at the abbey entrance
	A4 58 40 -> position of the first stop during the welcome speech
	A5 21 02 -> position for us to enter our cell
	9C 2A 02 -> position at the monks' access door to the church
	C7 27 00 -> position on the screen where he presents jorge

68 61 42 -> position at the door of severino's cell
3A 34 0F -> position at the entrance of the hallway through which you go to the stairs leading up to the library

; copied at 0x10b-0x10d. State and predefined positions of berengario
3CE7: FA 00 00
	8C 48 42 -> church
	32 35 C2 -> refectory
	3D 5C 8F -> his desk in the scriptorium
	BC 15 02 -> monks' cell
	88 A8 C0 -> abbey exit
	52 67 04 -> position at the foot of the stairs to go up to the scriptorium
	68 57 02 -> severino's cell

; copied at 0x10e-0x110. State and predefined positions of severino/jorge
3CFF: FA 00 00
	8C 4B 42 -> church
	36 35 C2 -> refectory
	68 55 02 -> berengario's cell
	C9 2A 00 -> near the monks' cells
	19 2B 1A -> room where jorge dies

; copied at 0x111-0x113. State and predefined positions of adso
3D11: FF 00 00
3D14:	84 4E 42 -> church
		34 39 42 -> refectory
		A8 18 00 -> guillermo's cell

; table of association of constants to important memory addresses for the program (used by the script system)
3D1D: 	[0x3038] -> 0x00 (0x80) -> guillermo's x position
		[0x3039] -> 0x01 (0x81) -> guillermo's y position
		[0x303a] -> 0x02 (0x82) -> guillermo's height
		[0x3047] -> 0x03 (0x83) -> adso's x position
		[0x3075] -> 0x04 (0x84) -> berengario's x position
		[0x3049] -> 0x05 (0x85) -> adso's height
		[0x3caa] -> 0x06 (0x86) -> where malaquias is going
		[0x3ca8] -> 0x07 (0x87) -> where malaquias has arrived
		[0x2d81] -> 0x08 (0x88) -> time of day
		[0x2da1] -> 0x09 (0x89) -> indicates if a phrase is being played
		[0x3cc6] -> 0x0a (0x8a) -> where the abbot has arrived
		[0x3cc8] -> 0x0b (0x8b) -> where the abbot is going
		[0x3cc7] -> 0x0c (0x8c) -> abbot's state
		[0x2d80] -> 0x0d (0x8d) -> day number
		[0x3ca9] -> 0x0e (0x8e) -> malaquias' state
		[0x3c9e] -> 0x0f (0x8f) -> counter used to see how long guillermo is in the scriptorium without obeying
		[0x3ce9] -> 0x10 (0x90) -> where berengario is going
		[0x3ce7] -> 0x11 (0x91) -> where berengario has arrived
		[0x3ce8] -> 0x12 (0x92) -> berengario's state
		[0x3d01] -> 0x13 (0x93) -> where severino is going
		[0x3cff] -> 0x14 (0x94) -> where severino has arrived
		[0x3d00] -> 0x15 (0x95) -> severino's state
		[0x3d13] -> 0x16 (0x96) -> where adso is going
		[0x3d11] -> 0x17 (0x97) -> where adso has arrived
		[0x3d12] -> 0x18 (0x98) -> adso's state
		[0x3c98] -> 0x19 (0x99) -> counter
		[0x2dbd] -> 0x1a (0x9a) -> indicates the screen number shown by the camera
		[0x3c9a] -> 0x1b (0x9b) -> indicates if the time of day should advance
		[0x3c97] -> 0x1c (0x9c) -> indicates if guillermo has died
		[0x3074] -> 0x1d (0x9d) -> x position of berengario/bernardo gui/hooded/jorge
		[0x3ca6] -> 0x1e (0x9e) -> mask for the doors where each bit indicates which door is checked if it opens
		[0x2ffe] -> 0x1f (0x9f) -> number and state of door 1 that blocks passage to the left wing of the abbey
		[0x3003] -> 0x20 (0xa0) -> number and state of door 2 that blocks passage to the left wing of the abbey
		[0x3c99] -> 0x21 (0xa1) -> counter of guillermo's response time to adso's question about sleeping
		[0x3f0e] -> 0x22 (0xa2) -> modifies the phrase shown by routine 0x3f0b
		[0x3c96] -> 0x23 (0xa3) -> indicates if they are ready to start the mass/meal
		[0x2def] -> 0x24 (0xa4) -> objects guillermo has
		[0x3c94] -> 0x25 (0xa5) -> indicates that berengario has told the abbot that guillermo has taken the parchment
		[0x2e04] -> 0x26 (0xa6) -> objects the abbot has
		[0x3c92] -> 0x27 (0xa7) -> character followed by the camera if no keys are pressed for a while
		[0x2e0b] -> 0x28 (0xa8) -> berengario's objects
		[0x0840] -> 0x29 (0xa9) -> ??? not used ???
		[0x3c95] -> 0x2a (0xaa) -> indicates the time of day of the last executed actions
		[0x3ca1] -> 0x2b (0xab) -> indicates that jorge or bernardo gui are active for berengario's thinking routine
		[0x3ca2] -> 0x2c (0xac) -> indicates if malaquias is dead or dying
		[0x3ca3] -> 0x2d (0xad) -> indicates that jorge is active for severino's thinking routine
		[0x3ca5] -> 0x2e (0xae) -> more state information for severino, berengario and malaquias
		[0x3c9b] -> 0x2f (0xaf) -> indicates if guillermo is in his place in the refectory or at mass
		[0x2e0d] -> 0x30 (0xb0) -> mask with objects that berengario/bernardo gui can pick up
		[0x3ca4] -> 0x31 (0xb1) -> ???
		[0x3c9d] -> 0x32 (0xb2) -> random value obtained from adso's movements
		[0x3c90] -> 0x33 (0xb3) -> indicates that the parchment is held by the abbot in his room or is behind the mirror room
		[0x3c8c] -> 0x34 (0xb4) -> if the night is ending, it is set to 1. Otherwise, it is set to 0
		[0x3c8d] -> 0x35 (0xb5) -> indicates lamp state changes
		[0x3c8e] -> 0x36 (0xb6) -> counter of time they can go in the dark through the library
		[0x3c8b] -> 0x37 (0xb7) -> indicates that the lamp is being used
		[0x2df3] -> 0x38 (0xb8) -> indicates if adso has the lamp
		[0x3ca7] -> 0x39 (0xb9) -> if it is 0, indicates that the investigation has been completed
		[0x2dff] -> 0x3a (0xba) -> mask with objects that malaquias can pick up
		[0x2dfd] -> 0x3b (0xbb) -> malaquias' objects
		[0x416e] -> 0x3c (0xbc) -> ???
		[0x3c85] -> 0x3d (0xbd) -> counter used to kill guillermo if he reads the book without gloves
		[0x2df6] -> 0x3e (0xbe) -> adso's objects
		[0x2dbe] -> 0x3f (0xbf) -> indicates bonuses obtained 1
		[0x2dbf] -> 0x40 (0xc0) -> indicates bonuses obtained 2

; table of values for computing distance between characters, indexed by character orientation.
; Each entry has 4 bytes
; byte 0: value to add to the character's x distance
; byte 1: threshold value to say the character is near in x
; byte 2: value to add to the character's y distance
; byte 3: threshold value to say the character is near in y
3D9F: 	06 18 06 0C -> used when character orientation is 0 (facing towards +x)
		06 0C 0C 18 -> used when character orientation is 1 (facing towards -y)
		0C 18 06 0C -> used when character orientation is 2 (facing towards -x)
		06 0C 06 18 -> used when character orientation is 3 (facing towards +y)

; takes values from the return address, interpreting those values (reads related memory positions, performs calculations between
; them until finding a jump or call instruction, and updating the first related memory position) (called by rst 0x10)
3DAF: E1          pop  hl			; gets the return address
3DB0: 7E          ld   a,(hl)		; reads the first value
3DB1: 23          inc  hl
3DB2: E5          push hl
3DB3: CD C3 3D    call $3DC3		; gets in hl an address that is in [0x3d1d + 2*a]
3DB6: 22 C0 3D    ld   ($3DC0),hl	; sets the instruction parameter with the address read
3DB9: E1          pop  hl
3DBA: CD D9 3D    call $3DD9		; processes the string of bytes to see if it processes any instruction modifying c
3DBD: E5          push hl
3DBE: 79          ld   a,c			; writes the value read to the address
3DBF: 32 00 00    ld   ($0000),a	; modified from outside
3DC2: C9          ret

; gets in hl an address that is in 0x3d1d + 2*a (removing the upper bit)
3DC3: 87          add  a,a			; removes the upper bit and indexes (each entry is 2 bytes)
3DC4: 21 1D 3D    ld   hl,$3D1D		; points to the address table
3DC7: 85          add  a,l			; hl = hl + 2*a
3DC8: 6F          ld   l,a
3DC9: 8C          adc  a,h
3DCA: 95          sub  l
3DCB: 67          ld   h,a

3DCC: 5E          ld   e,(hl)		; de = [hl]
3DCD: 23          inc  hl
3DCE: 56          ld   d,(hl)
3DCF: EB          ex   de,hl
3DD0: C9          ret

; takes values from the return address, interpreting those values (reads related memory positions and performs
;  calculations between them until finding a jump or call instruction) (called by rst 0x08)
3DD1: E1          pop  hl			; hl = return address
3DD2: CD D9 3D    call $3DD9		; processes the string of bytes to see if it processes any instruction modifying c
3DD5: E5          push hl			; sets the return address after the bytes it has processed
3DD6: 79          ld   a,c			; returns if c != 0
3DD7: A7          and  a
3DD8: C9          ret

3DD9: CD 47 3E    call $3E47		; returns data (in c) related to what is at hl and advances hl

3DDC: 7E          ld   a,(hl)		; if the next instruction to execute at hl is:
3DDD: FE 20       cp   $20			;  jr nz,$xxxx, rst 0x10, jp nz,$xxxx, call $xxxxx, rst 0x08, ret, jp $xxxx, jr $xxxx
3DDF: C8          ret  z			;  exits the routine (evaluation finished)
3DE0: FE D7       cp   $D7
3DE2: C8          ret  z
3DE3: FE C2       cp   $C2
3DE5: C8          ret  z
3DE6: FE CD       cp   $CD
3DE8: C8          ret  z
3DE9: FE CF       cp   $CF
3DEB: C8          ret  z
3DEC: FE C9       cp   $C9
3DEE: C8          ret  z
3DEF: FE C3       cp   $C3
3DF1: C8          ret  z
3DF2: FE 18       cp   $18
3DF4: C8          ret  z

; if it reaches here, another operand needs to be read or an instruction executed between 2 operands
3DF5: 23          inc  hl			; advances the data pointer
3DF6: D1          pop  de			; recovers the possible last calculated value
3DF7: FE 3D       cp   $3D			; if any match is found with the operations, jump
3DF9: 28 43       jr   z,$3E3E		; 0x3d (char '=') -> c = c1 == c2
3DFB: FE 3E       cp   $3E
3DFD: 28 2D       jr   z,$3E2C		; 0x3e (char '>') -> c = c1 >= c2
3DFF: FE 3C       cp   $3C
3E01: 28 32       jr   z,$3E35		; 0x3c (char '<') -> c = c1 < c2
3E03: FE 2A       cp   $2A
3E05: 28 21       jr   z,$3E28		; 0x2a (char '*') -> c = c1 | c2 between booleans, c = c1 & c2 between values
3E07: FE 26       cp   $26
3E09: 28 19       jr   z,$3E24		; 0x26 (char '&') -> c = c1 & c2 between booleans, c = c1 | c2 between values
3E0B: FE 2B       cp   $2B
3E0D: 28 11       jr   z,$3E20		; 0x2b (char '+') -> c = c1 + c2
3E0F: FE 2D       cp   $2D
3E11: 28 08       jr   z,$3E1B		; 0x2d (char '-') -> c = c1 - c2

; if it reaches here, it's because no operation had to be executed
3E13: D5          push de			; saves the return address (since it's not an operand)
3E14: C5          push bc			; saves the last operand obtained
3E15: 2B          dec  hl			; moves the data pointer back
3E16: CD 47 3E    call $3E47		; returns data related to what is at hl and advances hl
3E19: 18 C1       jr   $3DDC		; returns to check the cases

; jumps here if it finds 0x2d (c = c1 - c2)
3E1B: 7B          ld   a,e
3E1C: 91          sub  c

3E1D: 4F          ld   c,a
3E1E: 18 BC       jr   $3DDC

; jumps here if it finds 0x2b (c = c1 + c2)
3E20: 79          ld   a,c
3E21: 83          add  a,e
3E22: 18 F9       jr   $3E1D

; jumps here if it finds 0x26 (c = c1 & c2 between booleans, c1 | c2 between values)
3E24: 79          ld   a,c
3E25: B3          or   e
3E26: 18 F5       jr   $3E1D

; jumps here if it finds 0x2a (c = c1 | c2 between booleans, c1 & c2 between values)
3E28: 79          ld   a,c
3E29: A3          and  e
3E2A: 18 F1       jr   $3E1D

; jumps here if it finds 0x3e (if c1 >= c2, c = 0, otherwise, c = 0xff)
3E2C: 7B          ld   a,e		; a = c1
3E2D: B9          cp   c		; compares it with c2
3E2E: 0E 00       ld   c,$00
3E30: 30 AA       jr   nc,$3DDC	; if c1 >= c2, jumps
3E32: 0D          dec  c
3E33: 18 A7       jr   $3DDC

; jumps here if it finds 0x3c (if c1 < c2, c = 0, otherwise, c = 0xff)
3E35: 7B          ld   a,e		; a = c1
3E36: B9          cp   c		; compares it with c2
3E37: 0E 00       ld   c,$00
3E39: 38 A1       jr   c,$3DDC	; if c2 > c1, jumps
3E3B: 0D          dec  c
3E3C: 18 9E       jr   $3DDC

; jumps here if it finds 0x3d (if c1 = c2, c = 0, otherwise, c = 0xff)
3E3E: 79          ld   a,c		; a = c2
3E3F: 0E 00       ld   c,$00
3E41: BB          cp   e		; is it equal to c1?
3E42: 28 98       jr   z,$3DDC
3E44: 0D          dec  c
3E45: 18 95       jr   $3DDC

; returns in c data related to what is at hl and advances hl. Used to obtain values from important program addresses for
;  the script system
;  if it's 0x40, returns [hl+1]. if it's < 0x80, returns [hl]. Otherwise, returns [0x3d1d + 2*[hl]]
3E47: 7E          ld   a,(hl)		; reads data
3E48: 23          inc  hl
3E49: FE 40       cp   $40			; if it's not 0x40, jumps
3E4B: 20 03       jr   nz,$3E50
3E4D: 4E          ld   c,(hl)		; if it's 0x40, returns the data that came after (used to return data >= 0x80 or data that has)
3E4E: 23          inc  hl			;  the same value as any of the instructions that stop the interpreter
3E4F: C9          ret

3E50: FE 80       cp   $80			; if it's < 0x80, exits returning the data that was read
3E52: 4F          ld   c,a
3E53: D8          ret  c
3E54: E5          push hl
3E55: CD C3 3D    call $3DC3		; gets in hl an address that is in the script constant association table
3E58: 4E          ld   c,(hl)		; returns a value from that address
3E59: E1          pop  hl
3E5A: C9          ret

; ----------------- end of code related to character behavior interpreter -----------------------------

; indicates that the character doesn't want to search for any path
3E5B: 3E 01       ld   a,$01
3E5D: 32 9C 3C    ld   ($3C9C),a
3E60: C9          ret

; compares the distance between guillermo and the character passed in iy
; if very close, returns 0, otherwise returns something != 0
; parameters: iy = character data
3E61: 3A 3A 30    ld   a,($303A)	; a = guillermo's height
3E64: CD 73 24    call $2473		; b = base height of the floor guillermo is on
3E67: 68          ld   l,b
3E68: FD 7E 04    ld   a,(iy+$04)	; a = character's height
3E6B: CD 73 24    call $2473		; b = base height of the floor the character is on
3E6E: 78          ld   a,b
3E6F: BD          cp   l
3E70: C0          ret  nz			; if the characters are not on the same floor, exits
3E71: FD 7E 01    ld   a,(iy+$01)	; gets the character's orientation
3E74: 87          add  a,a			; each entry occupies 4 bytes
3E75: 87          add  a,a
3E76: 21 9F 3D    ld   hl,$3D9F		; indexes the table of permissible distance values according to orientation
3E79: CD 2D 16    call $162D		; hl = hl + a
3E7C: 3A 38 30    ld   a,($3038)	; gets guillermo's x position
3E7F: 86          add  a,(hl)		; adds a constant according to orientation
3E80: 23          inc  hl
3E81: FD 96 02    sub  (iy+$02)		; subtracts the character's x position
3E84: BE          cp   (hl)
3E85: 30 0E       jr   nc,$3E95		; if the x distance between the abbot's position and guillermo exceeds the threshold, jumps
3E87: 23          inc  hl
3E88: 3A 39 30    ld   a,($3039)	; gets guillermo's y position
3E8B: 86          add  a,(hl)		; adds a constant according to orientation
3E8C: 23          inc  hl
3E8D: FD 96 03    sub  (iy+$03)		; subtracts the character's y position
3E90: BE          cp   (hl)
3E91: 30 02       jr   nc,$3E95		; if the y distance between the character's position and guillermo exceeds the threshold, jumps
3E93: AF          xor  a			; returns 0
3E94: C9          ret

3E95: F6 FF       or   $FF
3E97: C9          ret

; if has arrived at the place they wanted to reach, advances the state
3E98: DD 7E FF    ld   a,(ix-$01)	; gets where they're going
3E9B: DD BE FD    cp   (ix-$03)		; compares it with where they've arrived
3E9E: C0          ret  nz			; if they haven't arrived where they wanted to go, exits
3E9F: DD 34 FE    inc  (ix-$02)		; otherwise advances the state
3EA2: AF          xor  a
3EA3: C9          ret

; c = mask of doors of interest among all those that can be opened
; modifies the 0x05cd table with information from the door table and between which rooms they are
3EA4: DD E5       push ix
3EA6: 3A C0 A2    ld   a,($A2C0)	; reads adso's movement data
3EA9: 32 9D 3C    ld   ($3C9D),a	; saves that value which will later be used as if it were a random value
3EAC: 3A A6 3C    ld   a,($3CA6)	; gets the mask of doors that can be opened
3EAF: A1          and  c
3EB0: 4F          ld   c,a			; c = doors the character can pass through
3EB1: DD 21 67 3C ld   ix,$3C67		; points to the table with the rooms connected by doors
3EB5: 06 06       ld   b,$06		; 6 doors
3EB7: CB 39       srl  c			; shifts c to the right
3EB9: 3E 3F       ld   a,$3F		; ccf instruction (complements the carry flag)
3EBB: 38 01       jr   c,$3EBE		; if can enter through that door, jumps
3EBD: AF          xor  a
3EBE: 32 D7 3E    ld   ($3ED7),a	; modifies an instruction
3EC1: 21 CD 05    ld   hl,$05CD		; points to the room connections on the ground floor
3EC4: DD 7E 00    ld   a,(ix+$00)	; reads the index in the ground floor room matrix
3EC7: DD 23       inc  ix
3EC9: FE FF       cp   $FF
3ECB: 28 11       jr   z,$3EDE		; if it finds 0xff moves to the next iteration
3ECD: CD 2D 16    call $162D		; hl = hl + a
3ED0: DD 7E 00    ld   a,(ix+$00)	; reads the value for that room
3ED3: DD 23       inc  ix
3ED5: 5E          ld   e,(hl)		; gets the connections of that room
3ED6: A7          and  a			; clears the carry flag
3ED7: 00          nop				; instruction modified from outside (either ccf or nop) it's ccf if the door bit was 1
3ED8: CD E3 3E    call $3EE3		; if cf = 0 (that is, if can't go to that door), a = a | e. if cf = 1 a = ~a & e
3EDB: 77          ld   (hl),a		; modifies the value of that room
3EDC: 18 E3       jr   $3EC1
3EDE: 10 D7       djnz $3EB7		; repeats until finishing the 6 entries
3EE0: DD E1       pop  ix
3EE2: C9          ret

; if there's no carry, a = a | e. If there's carry, a = ~a & e
3EE3: 30 03       jr   nc,$3EE8
3EE5: 2F          cpl
3EE6: A3          and  e
3EE7: C9          ret
3EE8: B3          or   e
3EE9: C9          ret

; ------------- code and data related to pathfinding in the same screen ----------------------------------

; tries to execute actions depending on the time of day
3EEA: 3A A2 2D    ld   a,($2DA2)	; copies the phrase/voice playback state
3EED: 32 A1 2D    ld   ($2DA1),a
3EF0: 2A 88 2D    ld   hl,($2D88)	; hl points to the data of the character shown on screen
3EF3: CB 46       bit  0,(hl)		; if in the middle of an animation, exits
3EF5: C0          ret  nz

3EF6: 3A 9A 3C    ld   a,($3C9A)	; reads if the time of day should advance
3EF9: A7          and  a
3EFA: CA F9 5E    jp   z,$5EF9		; if the time of day doesn't need to advance, tries to execute scheduled actions according to time of day

3EFD: 3A A1 2D    ld   a,($2DA1)	; if a voice is being played, exits
3F00: A7          and  a
3F01: C0          ret  nz

3F02: 32 9A 3C    ld   ($3C9A),a	; indicates that the time of day no longer needs to advance
3F05: CD 3E 55    call $553E		; advances the time of day
3F08: C3 F9 5E    jp   $5EF9		; if the time of day has changed, executes actions depending on the time of day

; puts a phrase in the marker
3F0B: CD 26 50    call $5026        ; puts in the marker the phrase indicated by the next byte
	00								; this byte is modified from outside
3F0F: C9          ret

; executes the routine at hl[c] (unless hl[c] == 0)
3F10: E1          pop  hl			; recovers the address from the stack
3F11: 06 01       ld   b,$01		; if entering with c = 0, executes the loop once
3F13: 28 03       jr   z,$3F18
3F15: 41          ld   b,c			; otherwise, executes it c times
3F16: 23          inc  hl
3F17: 23          inc  hl
3F18: 5E          ld   e,(hl)		; de = [hl]
3F19: 23          inc  hl
3F1A: 56          ld   d,(hl)
3F1B: 23          inc  hl
3F1C: 7A          ld   a,d
3F1D: B3          or   e
3F1E: 28 04       jr   z,$3F24		; if [hl] = 0, exits
3F20: 10 F6       djnz $3F18
3F22: EB          ex   de,hl
3F23: E9          jp   (hl)
3F24: E5          push hl
3F25: C9          ret

; ----------------------- code and data related to the palette -----------------------------------

; color entries (3, 2, 1, 0 and border)
3F26: 14 14 14 14 14
3F2B: 0C 14 1C 07 1C
3F30: 14 03 0E 06 14
3F35: 14 00 1D 04 14

; sets the colors of the video mode
3F3A: 21 26 3F    ld   hl,$3F26	; selects palette 0
3F3D: 18 0D       jr   $3F4C
3F3F: 21 2B 3F    ld   hl,$3F2B	; selects palette 1
3F42: 18 08       jr   $3F4C
3F44: 21 30 3F    ld   hl,$3F30	; selects palette 2
3F47: 18 03       jr   $3F4C
3F49: 21 35 3F    ld   hl,$3F35	; selects palette 3

; sets a graphics palette in mode 1
3F4C: 3E 04       ld   a,$04	; 4 colors
3F4E: 06 7F       ld   b,$7F	; pen selection
3F50: 4F          ld   c,a
3F51: 0D          dec  c
3F52: ED 49       out  (c),c	; selects color i
3F54: 4E          ld   c,(hl)	: gets the color
3F55: 23          inc  hl
3F56: CB F1       set  6,c		; sets color i with the value read (hardware color of the hardware palette)
3F58: ED 49       out  (c),c
3F5A: 3D          dec  a
3F5B: 20 F3       jr   nz,$3F50	; repeats the process

3F5D: 0E 10       ld   c,$10
3F5F: ED 49       out  (c),c	; selects the border
3F61: 4E          ld   c,(hl)
3F62: CB F1       set  6,c
3F64: ED 49       out  (c),c	; sets the border color
3F66: C9          ret

; ----------------------- end of code and data related to the palette -----------------------------------

; -------------------- code and data for the spiral effect -----------------------

; auxiliary data for drawing the square spiral
3F67: 48 54 CD C1

; routine responsible for drawing and erasing the spiral
3F6B: AF          xor  a
3F6C: DD E5       push ix
3F6E: 1E FF       ld   e,$FF
3F70: CD 7F 3F    call $3F7F		; draws the spiral
3F73: 1E 00       ld   e,$00
3F75: CD 7F 3F    call $3F7F		; erases the spiral
3F78: DD E1       pop  ix
3F7A: AF          xor  a
3F7B: 32 75 2D    ld   ($2D75),a	; indicates a screen change
3F7E: C9          ret

; draws the spiral in the color indicated by e
3F7F: 21 00 00    ld   hl,$0000			; initial position (00, 00)
3F82: DD 21 67 3F ld   ix,$3F67			; writes the helper data for drawing the square spiral
3F86: DD 36 00 3F ld   (ix+$00),$3F		; width from left to right
3F8A: DD 36 01 4F ld   (ix+$01),$4F		; height from top to bottom
3F8E: DD 36 02 3F ld   (ix+$02),$3F		; width right to left
3F92: DD 36 03 4E ld   (ix+$03),$4E		; height from bottom to top

3F96: 06 20       ld   b,$20			; 32 times
3F98: AF          xor  a				; a = 0
3F99: C5          push bc
3F9A: DD 46 00    ld   b,(ix+$00)		; reads the width counter and jumps
3F9D: 18 07       jr   $3FA6

3F9F: C5          push bc
3FA0: DD 46 00    ld   b,(ix+$00)
3FA3: DD 35 00    dec  (ix+$00)

; draws a strip (of color a) of b*8 pixels wide and 2 high (from left to right)
3FA6: DD 35 00    dec  (ix+$00)
3FA9: CD E6 3F    call $3FE6			; converts hl to screen coordinates and writes a to that line and the next
3FAC: 2C          inc  l				; moves to the next byte in X
3FAD: 10 FA       djnz $3FA9			; repeats until b = 0

; draws a strip (of color a) of 8 pixels wide and [ix+0x01]*2 high (from top to bottom)
3FAF: DD 46 01    ld   b,(ix+$01)
3FB2: DD 35 01    dec  (ix+$01)
3FB5: DD 35 01    dec  (ix+$01)
3FB8: CD E6 3F    call $3FE6			; converts hl to screen coordinates and writes a to that line and the next
3FBB: 24          inc  h				; moves to the next 2 lines in Y
3FBC: 24          inc  h
3FBD: 10 F9       djnz $3FB8

; draws a strip (of color a) of [ix+0x02]*8 pixels wide and 2 high (from right to left)
3FBF: DD 46 02    ld   b,(ix+$02)
3FC2: DD 35 02    dec  (ix+$02)
3FC5: DD 35 02    dec  (ix+$02)
3FC8: CD E6 3F    call $3FE6			; converts hl to screen coordinates and writes a to that line and the next
3FCB: 2D          dec  l				; moves back in X
3FCC: 10 FA       djnz $3FC8

; draws a strip (of color a) of 8 pixels wide and [ix+0x03]*2 high (from bottom to top)
3FCE: DD 46 03    ld   b,(ix+$03)
3FD1: DD 35 03    dec  (ix+$03)
3FD4: DD 35 03    dec  (ix+$03)
3FD7: CD E6 3F    call $3FE6			; converts hl to screen coordinates and writes a to that line and the next
3FDA: 25          dec  h				; moves to the 2 previous coordinates in Y
3FDB: 25          dec  h
3FDC: 10 F9       djnz $3FD7

3FDE: C1          pop  bc				; recovers the counter
3FDF: AB          xor  e				; changes the strip color
3FE0: 10 BD       djnz $3F9F			; repeats until done

3FE2: CD E6 3F    call $3FE6			; converts hl to screen coordinates and writes a to that line and the next
3FE5: C9          ret

; converts hl to screen coordinates and writes a to that line and the next
3FE6: E5          push hl
3FE7: C5          push bc
3FE8: F5          push af
3FE9: CD 42 3C    call $3C42		; given hl (Y,X coordinates), calculates the corresponding screen offset
3FEC: F1          pop  af
3FED: 77          ld   (hl),a		; writes a
3FEE: F5          push af
3FEF: CD 4D 3A    call $3A4D		; moves to the next screen line
3FF2: F1          pop  af
3FF3: 77          ld   (hl),a		; writes a
3FF4: C1          pop  bc
3FF5: E1          pop  hl
3FF6: C9          ret

; -------------------- end of code and data for the spiral effect -----------------------

3FF7: 3A FA 2D    ld   a,($2DFA)	; reads if malaquias has the lamp
3FFA: E6 80       and  $80
3FFC: 2A 87 3C    ld   hl,($3C87)	; gets the lamp usage time
3FFF: B4          or   h

; abadia2.bin (0x4000-0x7fff)
4000: B5          or   l
4001: C8          ret  z			; if malaquias doesn't have the lamp and it hasn't been used, exits

4002: AF          xor  a
4003: 32 91 3C    ld   ($3C91),a	; indicates that the lamp has been used
4006: 6F          ld   l,a
4007: 67          ld   h,a
4008: 22 87 3C    ld   ($3C87),hl	; sets the lamp usage counter to 0
400B: 32 8B 3C    ld   ($3C8B),a	; indicates that the lamp is not being used
400E: 21 F3 2D    ld   hl,$2DF3
4011: CB BE       res  7,(hl)		; indicates that adso doesn't have the lamp
4013: 21 FA 2D    ld   hl,$2DFA
4016: CB BE       res  7,(hl)		; indicates that malaquias doesn't have the lamp
4018: CD 45 41    call $4145		; copies to 0x3030 -> 00 00 00 00 00 (clears the lamp position data)
		3030
		00 00 00 00 00

; leaves the passage key on malaquias' table
4022: 3A FD 2D    ld   a,($2DFD)	; gets malaquias' objects
4025: CB 4F       bit  1,a
4027: C8          ret  z			; if he doesn't have the key to the passage behind the kitchen, exits
4028: E6 FD       and  $FD
402A: 32 FD 2D    ld   ($2DFD),a	; removes the key to the passage behind the kitchen
402D: CD 45 41    call $4145		; copies to 0x3026 -> 00 00 35 35 13 (puts key3 on the table)
		3026
		00 00 35 35 13

4037: 3A EF 2D    ld   a,($2DEF)	; gets the objects we have
403A: E6 DF       and  $DF
403C: 32 EF 2D    ld   ($2DEF),a	; removes the glasses from the objects we have
403F: 3A 0B 2E    ld   a,($2E0B)	; gets berengario's objects
4042: E6 DF       and  $DF
4044: 32 0B 2E    ld   ($2E0B),a	; removes the glasses from berengario
4047: DD E5       push ix
4049: CD D4 51    call $51D4		; draws the objects we have in the marker
404C: DD E1       pop  ix
404E: CD 45 41    call $4145
		3012						; copies to 0x3012 -> 00 00 00 00 00 (the glasses disappear)
		00 00 00 00 00

4058: 21 9B 30    ld   hl,$309B		; pointer to berengario's face graphic data
405B: 11 93 B2    ld   de,$B293		; pointer to bernardo gui's face graphic data
405E: CD A2 40    call $40A2		; modifies the face pointed to by hl with the one passed in de. Also calls 0x4145 with what follows
		3073						; places bernardo gui's initial position in the abbey
		00 88 88 02 00

4068: 21 9D 30    ld   hl,$309D		; pointer to severino's face graphic data
406B: 11 F7 B2    ld   de,$B2F7		; pointer to jorge's face graphic data
406E: CD A2 40    call $40A2		; modifies the face pointed to by hl with the one passed in de. Also calls 0x4145 with what follows
		3082						; places jorge's initial position in the abbey (behind the mirror)
		03 12 65 18 00

4078: 2A 7E 30    ld   hl,($307E)	; reads the address of the data guiding berengario
407B: 36 10       ld   (hl),$10		; writes the value to think a new move
407D: AF          xor  a
407E: 32 7C 30    ld   ($307C),a	; stops the counter and index of the data guiding the character
4081: 32 8C 30    ld   ($308C),a
4084: 21 9B 30    ld   hl,$309B		; pointer to berengario's face graphic data
4087: 11 F7 B2    ld   de,$B2F7		; pointer to jorge's face graphic data
408A: CD A2 40    call $40A2		; modifies the face pointed to by hl with the one passed in de. Also calls 0x4145 with what follows
		3073
		00 C8 24 00 00

4094: CD C4 36    call $36C4		; rotates the monks' graphics if necessary
4097: 21 9B 30    ld   hl,$309B		; pointer to berengario's face graphic data
409A: 11 5B B3    ld   de,$B35B		; pointer to the hooded man's face graphic data

; modifies the face pointed to by hl with the one passed in de. Also calls 0x4145 with what follows
409D: 73          ld   (hl),e		; [hl] = de
409E: 23          inc  hl
409F: 72          ld   (hl),d
40A0: 23          inc  hl
40A1: C9          ret

; rotates the monks' graphics if necessary and modifies the face pointed to by hl with the one passed in de. Also calls 0x4145 with what follows
40A2: E5          push hl
40A3: D5          push de
40A4: CD C4 36    call $36C4		; rotates the monks' graphics if necessary
40A7: D1          pop  de
40A8: E1          pop  hl
40A9: CD 9D 40    call $409D		; [hl] = de
40AC: C3 45 41    jp   $4145		; copies to the indicated address after the stack 5 bytes that follow the address (but from the caller)

; called from jorge's behavior
40AF: DD E5       push ix
40B1: FD E5       push iy
40B3: DD 21 0F 2E ld   ix,$2E0F		; points to the object data table for severino
40B7: 18 12       jr   $40CB


40B9: 3A 04 2E    ld   a,($2E04)	; if the abbot doesn't have the parchment, exit
40BC: E6 10       and  $10
40BE: C8          ret  z

40BF: AF          xor  a
40C0: 32 06 2E    ld   ($2E06),a	; modifies the object mask to not pick up the parchment
40C3: DD E5       push ix
40C5: FD E5       push iy
40C7: DD 21 01 2E ld   ix,$2E01		; points to the object data table for the abbot

40CB: CD 77 52    call $5277		; drops the parchment
40CE: FD E1       pop  iy
40D0: DD E1       pop  ix
40D2: AF          xor  a
40D3: 32 93 3C    ld   ($3C93),a	; sets to 0 the counter that increments if we don't press the cursors
40D6: C9          ret

40D7: 3E 10       ld   a,$10
40D9: C9          ret

40DA: 32 06 2E    ld   ($2E06),a


; puts the parchment in the room behind the mirror
40DD: CD 45 41    call $4145			; copies to 0x3017 -> 00	00 18 64 18
	3017
	00	00 18 64 18

40E7: CD 45 41    call $4145			; copies to 0x3017 -> 00 00 58 3C 02
	3017
	00 00 58 3C 02

40F1: 3E 80       ld   a,$80
40F3: 32 12 2E    ld   ($2E12),a		; gives jorge the book

; leaves the book outside the abbey
40F6: CD 45 41    call $4145			; copies to 0x3008 -> 80 00 0F 2E 00
	3008
	80 00 0F 2E 00

4100: 3A 91 3C    ld   a,($3C91)		; if the lamp hasn't disappeared, exit
4103: A7          and  a
4104: C0          ret  nz
4105: 3C          inc  a
4106: 32 91 3C    ld   ($3C91),a		; indicate that the lamp is not disappeared

; puts the lamp in the kitchen
4109: CD 45 41    call $4145			; copies to 0x3030 -> 00 00 5A 2A 04
	3030
	00 00 5A 2A 04

; puts the key to the abbot's room on the altar
4113: CD 45 41    call $4145			; copies to 0x301C -> 00 00 89 3E 08
	301C
	00 00 89 3E 08

; the key to the abbot's room disappears
411D: CD 45 41    call $4145			; copies to 0x301C -> 00 00 00 00 00
	301C
	00 00 00 00 00 00

; puts key 2 on malachi's table
4127: CD 45 41    call $4145			; copies to 0x3021 -> 00 00 35 35 13
	3021
	00 00 35 35 13

; puts william's glasses in the illuminated room of the labyrinth
4131: CD 45 41    call $4145			; copies to 0x3012 -> 00 00 1B 23 18
	3012
	00 00 1B 23 18

413B: CD 45 41    call $4145			; copies to 0x301C -> 00 00 00 00 00
	301C
	00 00 00 00 00

; retrieves the stack address and copies the following 5 bytes from the stack to the destination address read from the stack
4145: E1          pop  hl			; retrieves the stack address
4146: 5E          ld   e,(hl)		; gets an address
4147: 23          inc  hl
4148: 56          ld   d,(hl)
4149: 23          inc  hl
414A: 01 05 00    ld   bc,$0005		; copies 5 bytes to that address
414D: ED B0       ldir
414F: C9          ret

4150: 30 0C       jr   nc,$415E		; if we don't have the gloves or jorge's state is not 0x0d, 0x0e or 0x0f, jump

; arrives here if we have the gloves and jorge's state is 0x0d, 0x0e or 0x0f
4152: 3E 32       ld   a,$32
4154: 32 93 3C    ld   ($3C93),a	; indicates that there's no need to wait to show jorge
4157: 3E 05       ld   a,$05
4159: 32 92 3C    ld   ($3C92),a	; indicates that the camera should follow jorge if william doesn't move
415C: AF          xor  a
415D: C9          ret

; if we don't have the gloves or jorge's state is not 0x0d, 0x0e or 0x0f, check if william's movement cursors were pressed
415E: AF          xor  a
415F: CD 82 34    call $3482		; if up cursor is pressed exit
4162: C0          ret  nz
4163: 3E 08       ld   a,$08
4165: CD 82 34    call $3482		; if left cursor is pressed exit
4168: C0          ret  nz
4169: 3E 01       ld   a,$01		; check if right cursor is pressed
416B: C3 82 34    jp   $3482

416E: 00          nop				; set to 0 when pressing ctrl+f9

; if we have the gloves and jorge's state is 0x0d, 0x0e or 0x0f (is talking about the book), exit with cf = 1, otherwise with cf = 0
416F: 3A EF 2D    ld   a,($2DEF)	; if we don't have the gloves, exit
4172: E6 40       and  $40
4174: C8          ret  z

4175: 3A 00 3D    ld   a,($3D00)	; if jorge's state is 0x0d, 0x0e or 0x0f, exit with cf = 1, otherwise with cf = 0
4178: FE 0D       cp   $0D
417A: 37          scf
417B: C8          ret  z

417C: FE 0E       cp   $0E
417E: 37          scf
417F: C8          ret  z

4180: FE 0F       cp   $0F
4182: 37          scf
4183: C8          ret  z

4184: A7          and  a
4185: C9          ret

; checks if the character the camera follows needs to be changed and calculates the bonuses we have achieved (interpreted)
4186: CD 91 56    call $5691		; checks if the character the camera follows needs to be changed and calculates the bonuses we have achieved (interpreted)
4189: CD 6F 41    call $416F		; if we have the gloves and jorge's state is 0x0d, 0x0e or 0x0f, exit with cf = 1, otherwise with cf = 0
418C: CD 50 41    call $4150		; check if cursors were pressed (cf = 1)
418F: 3E 00       ld   a,$00
4191: 20 24       jr   nz,$41B7		; if up, left or right cursor was pressed, follow william
4193: 3A 93 3C    ld   a,($3C93)	; [0x3c93]++
4196: 3C          inc  a
4197: 32 93 3C    ld   ($3C93),a
419A: FE 32       cp   $32			; if it's < 0x32, exit
419C: D8          ret  c

419D: 3D          dec  a
419E: 32 93 3C    ld   ($3C93),a	; leaves the counter as it was
41A1: 3A A1 2D    ld   a,($2DA1)	; reads the phrase state
41A4: A7          and  a
41A5: C4 BF 41    call nz,$41BF		; if a phrase is being shown, restore the wait counter value of the main loop
41A8: CC C2 41    call z,$41C2		;  otherwise, set the main loop counter to 0 (so that it doesn't wait)
41AB: CD 07 10    call $1007		; starts a sound on channel 1
41AE: 3A 8F 3C    ld   a,($3C8F)	; gets the character the camera follows
41B1: 4F          ld   c,a
41B2: 3A 92 3C    ld   a,($3C92)	; reads the character to follow if william is standing still
41B5: B9          cp   c
41B6: C8          ret  z			; if they are equal, exit

; also arrives here if up, left or right cursor was pressed, jump
41B7: 32 8F 3C    ld   ($3C8F),a	; makes the camera follow the character indicated in a
41BA: 32 93 3C    ld   ($3C93),a	; updates the counter with the entered value
41BD: A7          and  a
41BE: C0          ret  nz			; if the character to follow is not ours, exit

; restores the wait counter value of the main loop
41BF: 3A 49 BF    ld   a,($BF49)
41C2: 32 18 26    ld   ($2618),a	; restores the wait counter value of the main loop
41C5: C9          ret

; sets a to 0, so that it never registers a key press
41C6: AF          xor  a
41C7: C9          ret

; reads the first byte from stack and saves it in 0x3c93
41C8: E1          pop  hl			; gets the return address
41C9: 7E          ld   a,(hl)		; reads the first byte and saves it in 0x3c93
41CA: 23          inc  hl
41CB: 32 93 3C    ld   ($3C93),a
41CE: E5          push hl
41CF: C9          ret

41D0: 78          ld   a,b
41D1: 3D          dec  a
41D2: 32 8F 3C    ld   ($3C8F),a
41D5: C9          ret

; checks if the character the camera follows needs to be changed and calculates the bonuses we have achieved (interpreted)
41D6: CD 86 41    call $4186		; checks if the character the camera follows needs to be changed and calculates the bonuses we have achieved (interpreted)
41D9: 21 F1 41    ld   hl,$41F1		; hl points to the pointer table of character data
41DC: 3A 8F 3C    ld   a,($3C8F)	; reads the character the camera follows
41DF: 87          add  a,a
41E0: CD 2D 16    call $162D		; indexes into the table
41E3: 5E          ld   e,(hl)
41E4: 23          inc  hl
41E5: 56          ld   d,(hl)		; de = address of the character data that the camera follows
41E6: ED 53 88 2D ld   ($2D88),de
41EA: C9          ret

; this is never reached???
41EB: 31 38 39    ld   sp,$3938
41EE: 41          ld   b,c
41EF: 40          ld   b,b
41F0: 12          ld   (de),a

; table with pointers to character data related to 0x3c8f
41F1: 	3036 -> 0x00 william's characteristics
	3045 -> 0x01 adso's characteristics
	3054 -> 0x02 malachi's characteristics
	3063 -> 0x03 abbot's characteristics
	3072 -> 0x04 berengario's characteristics
	3081 -> 0x05 severino's characteristics

; checks if the lamp is running out
41FD: 3A 8D 3C    ld   a,($3C8D)	; reads the lamp state
4200: 4F          ld   c,a
4201: 3A F3 2D    ld   a,($2DF3)
4204: E6 80       and  $80			; if adso doesn't have the lamp, exit
4206: C8          ret  z

4207: 3A 8B 3C    ld   a,($3C8B)	; if hasn't entered the labyrinth/the lamp is not being used, exit
420A: A7          and  a
420B: C8          ret  z

420C: 3A 6C 15    ld   a,($156C)	; if the screen is illuminated, exit
420F: A7          and  a
4210: C8          ret  z

4211: 2A 87 3C    ld   hl,($3C87)	; increments the lamp usage time
4214: 23          inc  hl
4215: 22 87 3C    ld   ($3C87),hl
4218: 7D          ld   a,l
4219: A7          and  a
421A: C0          ret  nz			; if l is not 0, exit

421B: 79          ld   a,c			; a = lamp state
421C: A7          and  a
421D: C0          ret  nz			; if hasn't processed the lamp state change, exit

421E: 7C          ld   a,h			; if the lamp usage time has reached 0x3xx, exit with c = 1 (lamp is running out)
421F: 0E 01       ld   c,$01
4221: FE 03       cp   $03
4223: C8          ret  z
4224: 0C          inc  c			; if the lamp usage time has reached 0x6xx, exit with c = 2 (lamp has run out)
4225: FE 06       cp   $06
4227: C8          ret  z
4228: 0E 00       ld   c,$00		; otherwise, exit with c = 0
422A: C9          ret

; checks if the night is ending
422B: 0E 00       ld   c,$00
422D: 2A 86 2D    ld   hl,($2D86)	; gets the amount of time to wait for the time of day to advance
4230: 7C          ld   a,h
4231: B5          or   l
4232: C8          ret  z			; if it's 0, exit
4233: 7D          ld   a,l
4234: A7          and  a
4235: C0          ret  nz			; otherwise, wait if the lower part of the counter for the time of day to pass is not 0, exit

4236: 3A 81 2D    ld   a,($2D81)	; if it's not night, exit
4239: A7          and  a
423A: C0          ret  nz

423B: 7C          ld   a,h			; if the upper part of the counter is 2, exit with c = 1
423C: 0C          inc  c
423D: FE 02       cp   $02
423F: C8          ret  z

4240: 0D          dec  c
4241: A7          and  a
4242: C0          ret  nz			; otherwise, if it's not 0, exit with c = 0

4243: 3C          inc  a
4244: 32 9A 3C    ld   ($3C9A),a	; if it's 0, increment the time of day and exit with c = 0
4247: C9          ret

; turns off the screen light and takes the book from william
4248: 3E 01       ld   a,$01
424A: 32 6C 15    ld   ($156C),a	; indicates that the screen is not illuminated
424D: CD 6C 1A    call $1A6C		; hides the game area
4250: 3A EF 2D    ld   a,($2DEF)	; takes the book from william
4253: E6 7F       and  $7F
4255: 32 EF 2D    ld   ($2DEF),a
4258: 4F          ld   c,a
4259: 3E 80       ld   a,$80
425B: CD DA 51    call $51DA		; updates the scoreboard so the book is not shown
425E: CD 45 41    call $4145		; copies to 0x3008 -> 00 00 00 00 00 (makes the book disappear)
	3008
	00 00 00 00 00
4268: C9          ret

; ---------------- code to calculate mission completion percentage ----------------------------------

; calculates mission completion percentage and saves it in 0x431e
4269: 3A A7 3C    ld   a,($3CA7)	; if 0x3ca7 is 0, show the ending
426C: A7          and  a
426D: CA 68 38    jp   z,$3868
4270: 3A 80 2D    ld   a,($2D80)	; gets the day number
4273: 3D          dec  a			; adjusts between 0 and 6
4274: 47          ld   b,a
4275: 87          add  a,a
4276: 4F          ld   c,a
4277: 87          add  a,a
4278: 80          add  a,b
4279: 81          add  a,c
427A: 4F          ld   c,a			; c = 7*(day - 1)
427B: 3A 81 2D    ld   a,($2D81)	; gets the time of day
427E: 81          add  a,c			; a = 7*(day - 1) + time of day
427F: 2A BE 2D    ld   hl,($2DBE)	; reads the bonuses achieved
4282: 06 10       ld   b,$10		; checks 16 bits
4284: 29          add  hl,hl		; hl = hl*2
4285: 30 02       jr   nc,$4289		; if the current bit wasn't set, jump
4287: C6 04       add  a,$04		; for each bonus, add 4
4289: 10 F9       djnz $4284		; repeat until testing all 16 bits of the number
428B: FE 05       cp   $05
428D: 30 01       jr   nc,$4290		; if we haven't obtained a score >= 5, set the score to 0
428F: AF          xor  a

; arrives here with a = score obtained
4290: 01 00 00    ld   bc,$0000		; initially the score = 00
4293: 47          ld   b,a
4294: D6 0A       sub  $0A			; subtract 10 from the bonuses obtained
4296: 38 03       jr   c,$429B		; if the remaining number was < 10, jump
4298: 0C          inc  c			; increment the tens
4299: 18 F8       jr   $4293		; repeat while tens remain

429B: 21 30 30    ld   hl,$3030		; hl = ASCII characters of 00
429E: 09          add  hl,bc		; add the score obtained
429F: 22 A9 42    ld   ($42A9),hl	; modifies the call data to 0x4145
42A2: CD 45 41    call $4145		; copies to 0x431E -> 20 20 3X 3Y 20 and exit, where XY is the game completion percentage
	431E
	20 20 30 30 20


; updates bonuses if we have the gloves, keys and something else and if reading the book without gloves, kills william
42AC: 3A EF 2D    ld   a,($2DEF)	; reads william's objects
42AF: 4F          ld   c,a
42B0: E6 4C       and  $4C			; keeps only the gloves and the first 2 keys
42B2: 47          ld   b,a
42B3: 3A F6 2D    ld   a,($2DF6)	; reads adso's objects
42B6: E6 02       and  $02			; keeps key 3
42B8: B0          or   b
42B9: 47          ld   b,a
42BA: 3A BE 2D    ld   a,($2DBE)	; reads the bonuses
42BD: B0          or   b
42BE: 32 BE 2D    ld   ($2DBE),a	; updates the bonuses
42C1: 79          ld   a,c
42C2: E6 80       and  $80
42C4: C8          ret  z			; if we don't have the book, exit

42C5: CB 71       bit  6,c			; if we have the gloves, exit
42C7: C0          ret  nz

42C8: 3A 85 3C    ld   a,($3C85)	; increments the counter of time reading the book without gloves
42CB: 3C          inc  a
42CC: 32 85 3C    ld   ($3C85),a
42CF: C0          ret  nz

42D0: 3A 19 2E    ld   a,($2E19)	; a = y position of william's sprite
42D3: CB 3F       srl  a			; a = a/2
42D5: 32 8F 28    ld   ($288F),a	; changes william's state
42D8: 3E FE       ld   a,$FE
42DA: 32 B1 28    ld   ($28B1),a	; modifies an instruction that adds -2 to william's sprite y position
42DD: 3E 01       ld   a,$01
42DF: 32 97 3C    ld   ($3C97),a	; kills william
42E2: CD 1B 50    call $501B		; writes a phrase on the scoreboard
42E5: 22 							YOU ARE DEAD, FRIAR WILLIAM, YOU HAVE FALLEN INTO THE TRAP
42E6: C9          ret

; if william is dead, calculates the % of mission completed and shows it on screen
42E7: 3A 97 3C    ld   a,($3C97)	; reads if william is alive and if so, exit
42EA: A7          and  a
42EB: C8          ret  z

42EC: 3E 80       ld   a,$80
42EE: 32 8F 3C    ld   ($3C8F),a	; indicates that the camera should follow william and do it now
42F1: 3A A1 2D    ld   a,($2DA1)	; if showing a phrase/playing a voice, exit
42F4: A7          and  a
42F5: C0          ret  nz
42F6: CD 6C 1A    call $1A6C		; hides the game area
42F9: CD 69 42    call $4269		; calculates mission completion percentage and saves it in 0x431e
42FC: 21 10 20    ld   hl,$2010		; (h = y in pixels, l = x in bytes) (x = 64, y = 32)
42FF: 22 97 2D    ld   ($2D97),hl	; modifies the variable used as the address to put characters on screen
4302: CD EE 4F    call $4FEE		; prints the phrase that follows the call at the current screen position
	48 41 53 20 52 45 53 55 45 4C 54 4F 20 45 4C FF
	YOU HAVE SOLVED THE

4315: 21 0E 30    ld   hl,$300E		; (h = y in pixels, l = x in bytes) (x = 56, y = 48)
4318: 22 97 2D    ld   ($2D97),hl	; modifies the variable used as the address to put characters on screen
431B: CD EE 4F    call $4FEE		; prints the phrase that follows the call at the current screen position
	; here copies the data to put the scoreboard score
	20 20 30 20 20
	50 4F 52 20 43 49 45 4E 54 4F FF
	PERCENT

432E: 21 0C 40    ld   hl,$400C		; (h = y in pixels, l = x in bytes) (x = 48, y = 64)
4331: 22 97 2D    ld   ($2D97),hl	; modifies the variable used as the address to put characters on screen
4334: CD EE 4F    call $4FEE		; prints the phrase that follows the call at the current screen position
	44 45 20 4C 41 20 49 4E 56 45 53 54 49 47 41 43 49 4F 4E FF
	OF THE INVESTIGATION

434B: 21 06 80    ld   hl,$8006		; (h = y in pixels, l = x in bytes) (x = 24, y = 128)
434E: 22 97 2D    ld   ($2D97),hl	; modifies the variable used as the address to put characters on screen
4351: CD EE 4F    call $4FEE		; prints the phrase that follows the call at the current screen position
	50 55 4C 53 41 20 45 53 50 41 43 49 4F 20 50 41 52 41 20 45 4D 50 45 5A 41 52 FF
	PRESS SPACE TO START

436F: CD BC 32    call $32BC		; reads the keyboard buffers
4372: 3E 2F       ld   a,$2F
4374: CD 82 34    call $3482
4377: 28 F6       jr   z,$436F		; wait until space is pressed
4379: E1          pop  hl
437A: C3 09 25    jp   $2509		; jumps to what's after the initialization

; ---------------- end of mission completion percentage calculation ----------------------------------

; disables the counter for the time of day to advance automatically
437D: 21 00 00    ld   hl,$0000
4380: 22 86 2D    ld   ($2D86),hl
4383: C9          ret

4384: 00          nop				; indicates that malachi is ascending while dying
4385: 00          nop				; not used (maybe it was used before for something???)

4386: 3A 85 43    ld   a,($4385)	; if ??? is not 0, exit
4389: E6 0F       and  $0F
438B: 32 85 43    ld   ($4385),a
438E: C0          ret  nz
438F: 3E 01       ld   a,$01
4391: 32 84 43    ld   ($4384),a	; indicates that malachi is ascending while dying
4394: 3A 58 30    ld   a,($3058)	; increments malachi's height
4397: 3C          inc  a
4398: 32 58 30    ld   ($3058),a
439B: FE 14       cp   $14			; if it's < 20, exit
439D: D8          ret  c

; arrives here when malachi has disappeared from the screen
439E: AF          xor  a
439F: 32 56 30    ld   ($3056),a	; sets malachi's x position to 0
43A2: 3E 02       ld   a,$02
43A4: 32 A2 3C    ld   ($3CA2),a	; indicates that malachi has died
43A7: AF          xor  a
43A8: 32 A8 3C    ld   ($3CA8),a	; indicates that malachi has arrived at the church
43AB: C9          ret

; checks that william is in the correct position for mass
43AC: 11 84 4B    ld   de,$4B84		; de = william's position at mass
43AF: CD C4 43    call $43C4		; checks that william is in the position determined by de
43B2: A7          and  a
43B3: C0          ret  nz
43B4: 11 80 30    ld   de,$3080		; de = impossible position???
43B7: 18 0B       jr   $43C4		; checks that william is in the position determined by de

43B9: 11 38 39    ld   de,$3938		; de = william's position in the refectory
43BC: CD C4 43    call $43C4		; checks that william is in the position determined by de
43BF: A7          and  a
43C0: C0          ret  nz
43C1: 11 20 30    ld   de,$3020		; de = impossible position???

; checks that william is in a determined position (on the ground floor) indicated by de
; returns in c: 0, if not in the room of the position, 2 if in the room of the position and 1 if in the indicated position and with the correct orientation
43C4: 0E 00       ld   c,$00		; c = 0, not in his place
43C6: 3A 3A 30    ld   a,($303A)	; gets william's height
43C9: FE 0B       cp   $0B
43CB: 30 1B       jr   nc,$43E8		; if not on the ground floor (height >= 0x0b), exit updating 0x3c9b
43CD: 3A 38 30    ld   a,($3038)	; reads the x position
43D0: AB          xor  e
43D1: 5F          ld   e,a
43D2: 3A 39 30    ld   a,($3039)	; reads the y position
43D5: AA          xor  d
43D6: B3          or   e
43D7: FE 10       cp   $10
43D9: 30 0D       jr   nc,$43E8		; if the position is not in the same room (a >= 0x10), exit updating 0x3c9b
43DB: 0E 02       ld   c,$02		; c = 0x02, in the room but not in the correct position
43DD: A7          and  a
43DE: 20 08       jr   nz,$43E8		; if it's not 0, exit
43E0: 3A 37 30    ld   a,($3037)	; reads the character's orientation
43E3: FE 01       cp   $01
43E5: 20 01       jr   nz,$43E8		; if it's not equal, exit updating 0x3c9b
43E7: 0D          dec  c			; c = 1

43E8: 79          ld   a,c
43E9: 32 9B 3C    ld   ($3C9B),a	; saves the result
43EC: C9          ret


43ED: 3A A5 3C    ld   a,($3CA5)
43F0: E6 01       and  $01
43F2: C0          ret  nz			; if has warned the abbot, exit
43F3: 3A EF 2D    ld   a,($2DEF)	; reads the objects william has
43F6: E6 10       and  $10
43F8: FE 10       cp   $10
43FA: C8          ret  z			; if he has the parchment, exit
43FB: 3A 17 30    ld   a,($3017)	; if the parchment is picked up, exit
43FE: CB 7F       bit  7,a
4400: C0          ret  nz
4401: 3A 1B 30    ld   a,($301B)	; gets the parchment's height
4404: CD 73 24    call $2473		; depending on the height, returns the base height of the floor in b
4407: 78          ld   a,b
4408: A7          and  a
4409: C9          ret

440A: 05CD		; address of the connection table for the floor where the character is

; table of command lengths according to orientation
440C: 	01 03 06 03

; table of turn commands
4410: 	8800 -> 1000 1000 0000 0000 -> command to advance one position forward
	5100 -> 0101 0001 0000 0000 -> command to turn right
	6E20 -> 0110 1110 0010 0000 -> commands to turn left twice
	7100 -> 0111 0001 0000 0000 -> command to turn left

4418: 00  ; resulting orientation of the search process
4419: 00  ; number of iterations of the search process

; table of commands if the character rises in height
; each entry is 3 bytes (the first 2 the command and the third the command length)
441A: 	8000 02 -> 1000 0000 0000 0000
	2000 04 -> 0010 0000 0000 0000

; table of commands if the character descends in height
; each entry is 3 bytes (the first 2 the command and the third the command length)
4420: 	C000 02 -> 1100 0000 0000 0000
	3000 04 -> 0011 0000 0000 0000

; table of commands if the character doesn't change height
; each entry is 3 bytes (the first 2 the command and the third the command length)
4426: 	8000 01 -> 1000 0000 0000 0000

; routine called to search for the path from the position passed in 0x2db2-0x2db3 to the one in 0x2db4-0x2db5
4429: 2A B4 2D    ld   hl,($2DB4)	; gets the destination position
442C: CD D4 0C    call $0CD4		; indexes into the height table with hl and returns the corresponding address in ix
442F: DD CB 00 F6 set  6,(ix+$00)	; marks the position as search target
4433: 18 35       jr   $446A		; path search routine from source address to destination address

; routine called to search for the path from the position passed in 0x2db2-0x2db3 to the one in 0x2db4-0x2db5 checking if it's reachable
4435: 2A B4 2D    ld   hl,($2DB4)	; gets the destination position
4438: CD D4 0C    call $0CD4		; indexes into the height table with hl and returns the corresponding address in ix
443B: ED 73 B0 2D ld   ($2DB0),sp
443F: DD 7E 00    ld   a,(ix+$00)	; reads the height of that position
4442: E6 0F       and  $0F
4444: 32 1C 45    ld   ($451C),a	; modifies an instruction in the neighbor checking routine with the base height
4447: 4F          ld   c,a			; saves the height of that position for later
4448: FE 0E       cp   $0E
444A: 3E 00       ld   a,$00
444C: D2 75 45    jp   nc,$4575		; if height >= 0x0e, exit returning 0
444F: 3E C9       ld   a,$C9
4451: 32 59 45    ld   ($4559),a	; modifies an instruction in the neighbors routine with ret
4454: CD 17 45    call $4517		; checks 4 positions relative to ix ((x,y),(x,y-1),(x-1,y)(x-1,y-1) and if there's not much height difference, sets bit 7 of (x,y)
4457: AF          xor  a
4458: 32 59 45    ld   ($4559),a	; leaves the routine as it was putting nop
445B: DD CB 00 7E bit  7,(ix+$00)	; if the destination cannot be reached, exit with a = 0
445F: CA 75 45    jp   z,$4575
4462: DD CB 00 BE res  7,(ix+$00)	; otherwise, remove explored position mark
4466: DD CB 00 F6 set  6,(ix+$00)	; marks the position as search target

; path search routine from the position in 0x2db2 (destination) to the height buffer position that has bit 6 (origin)
446A: 2A 8A 2D    ld   hl,($2D8A)	; gets a pointer to the screen's height buffer
446D: 01 28 02    ld   bc,$0228
4470: 5D          ld   e,l			; de = hl
4471: 54          ld   d,h
4472: 09          add  hl,bc		; points hl to position (X = 0, Y = 23) of the height buffer
4473: EB          ex   de,hl		; de = position (X = 0, Y = 23) of the height buffer, hl = position (X = 0, Y = 0) of the height buffer
4474: DD 2A 8A 2D ld   ix,($2D8A)	; gets in ix a pointer to the height buffer
4478: 06 18       ld   b,$18		; b = 24 times
447A: CB FE       set  7,(hl)		; sets bit 7
447C: DD CB 00 FE set  7,(ix+$00)	; sets bit 7
4480: DD CB 17 FE set  7,(ix+$17)	; sets bit 7
4484: 1A          ld   a,(de)
4485: F6 80       or   $80
4487: 12          ld   (de),a		; sets bit 7
4488: 78          ld   a,b
4489: 01 18 00    ld   bc,$0018
448C: DD 09       add  ix,bc		; advances ix to the next line
448E: 47          ld   b,a
448F: 13          inc  de			; increments the pointer to the last line of the height buffer
4490: 23          inc  hl			; increments the pointer to the last first of the height buffer
4491: 10 E7       djnz $447A		; repeat until bit 7 of all positions on the edge of the height buffer have been set

4493: ED 73 B0 2D ld   ($2DB0),sp
4497: 31 FE 9C    ld   sp,$9CFE		; puts on the stack at the end of the sprite buffer
449A: 3E 01       ld   a,$01
449C: 32 19 44    ld   ($4419),a	; starts the recursion level
449F: ED 5B B2 2D ld   de,($2DB2)	; gets the initial position adjusted to the height buffer and puts it on the stack
44A3: D5          push de
44A4: EB          ex   de,hl		; hl = initial position adjusted to the height buffer and puts it on the stack
44A5: CD D4 0C    call $0CD4		; indexes into the height table with hl and returns the corresponding address in ix
44A8: DD CB 00 FE set  7,(ix+$00)	; marks the initial position as explored
44AC: 21 FF FF    ld   hl,$FFFF
44AF: E5          push hl			; puts -1 on the stack
44B0: 21 FE 9C    ld   hl,$9CFE		; hl points to the end of the stack

44B3: 2B          dec  hl
44B4: 56          ld   d,(hl)
44B5: 2B          dec  hl
44B6: 5E          ld   e,(hl)		; de = value taken from the stack
44B7: 7B          ld   a,e
44B8: E6 80       and  $80			; if -1 was not recovered, jumps to explore neighboring positions
44BA: 28 14       jr   z,$44D0

; arrives here if an iteration has finished
44BC: AF          xor  a			; a indicates that the search was not successful
44BD: 44          ld   b,h			; bc = hl
44BE: 4D          ld   c,l
44BF: ED 72       sbc  hl,sp		; obtains the difference between the element being processed and the last one put on the stack
44C1: 69          ld   l,c			; hl = bc
44C2: 60          ld   h,b
44C3: CA 75 45    jp   z,$4575		; if all elements have been processed, exit
44C6: D5          push de			; otherwise, puts a -1 to indicate that a level ends
44C7: 3A 19 44    ld   a,($4419)	; increments the recursion level
44CA: 3C          inc  a
44CB: 32 19 44    ld   ($4419),a
44CE: 18 E3       jr   $44B3		; continues processing elements

; arrives here if -1 was not read from the stack
44D0: E5          push hl			; saves the position being processed on the stack
44D1: D5          push de			; saves the value obtained from the stack
44D2: EB          ex   de,hl		; hl = value taken from the stack
44D3: CD D4 0C    call $0CD4		; indexes in the height table with hl and returns the corresponding address in ix
44D6: D1          pop  de			; de = value obtained from the stack
44D7: E1          pop  hl			; hl = position being processed on the stack

44D8: DD 7E 00    ld   a,(ix+$00)	; obtains the height of the position and modifies an instruction with that value
44DB: E6 0F       and  $0F
44DD: 32 1C 45    ld   ($451C),a

; tries to explore the positions surrounding the position value taken from the stack (if there is not much height difference)

44E0: 3E 02       ld   a,$02		; left orientation
44E2: DD 23       inc  ix			; moves to position (x+1,y)
44E4: 1C          inc  e
44E5: CD 0E 45    call $450E		; if bit 7 of the current position was not set, checks the 4 positions related to ix
							;  ((x,y),(x,y-1),(x-1,y)(x-1,y-1) and if there is not much height difference, sets bit 7 of (x,y)
44E8: 3E 03       ld   a,$03		; up orientation
44EA: 01 E7 FF    ld   bc,$FFE7		; bc = -25
44ED: DD 09       add  ix,bc		; moves to position (x,y-1)
44EF: 1D          dec  e
44F0: 15          dec  d
44F1: CD 0E 45    call $450E		; if bit 7 of the current position was not set, checks the 4 positions related to ix
							;  ((x,y),(x,y-1),(x-1,y)(x-1,y-1) and if there is not much height difference, sets bit 7 of (x,y)
44F4: 3E 00       ld   a,$00		; right orientation
44F6: 01 17 00    ld   bc,$0017		; bc = 23
44F9: DD 09       add  ix,bc		; moves to position (x-1,y)
44FB: 14          inc  d
44FC: 1D          dec  e
44FD: CD 0E 45    call $450E		; if bit 7 of the current position was not set, checks the 4 positions related to ix
							;  ((x,y),(x,y-1),(x-1,y)(x-1,y-1) and if there is not much height difference, sets bit 7 of (x,y)
4500: 3E 01       ld   a,$01		; down orientation
4502: 01 19 00    ld   bc,$0019		; bc = 25
4505: DD 09       add  ix,bc		; moves to position (x,y+1)
4507: 14          inc  d
4508: 1C          inc  e
4509: CD 0E 45    call $450E		; if bit 7 of the current position was not set, checks the 4 positions related to ix
							;  ((x,y),(x,y-1),(x-1,y)(x-1,y-1) and if there is not much height difference, sets bit 7 of (x,y)

450C: 18 A5       jr   $44B3		; once neighboring positions have been checked, continues taking values from the stack

; if this position had not been explored, checks the 4 neighboring positions ((x,y),(x,y-1),(x-1,y)(x-1,y-1) and
;  if there is not much height difference, sets bit 7 of (x,y). also writes the final orientation to 0x4418
450E: DD 4E 00    ld   c,(ix+$00)	; obtains the value of the height buffer of the current position
4511: 32 18 44    ld   ($4418),a	; saves the final orientation
4514: CB 79       bit  7,c
4516: C0          ret  nz			; if the position has already been explored, exit

; checks 4 positions relative to ix ((x,y),(x,y-1),(x-1,y)(x-1,y-1) and if there is not much height difference, sets bit 7 of (x,y)
; arrives here with:
;  c = content of the height buffer (without bit 7) for a position close to where the character was
;  ix = pointer to a position in the height buffer
4517: 79          ld   a,c
4518: E6 3F       and  $3F
451A: 4F          ld   c,a			; removes bit 7 and 6
451B: 3E 00       ld   a,$00		; instruction modified with the height of the character's main position in the height buffer
451D: 91          sub  c			; obtains the height difference between the character and the position being considered
451E: 3C          inc  a
451F: FE 03       cp   $03
4521: D0          ret  nc			; if the height difference is >= 0x02, exit

4522: DD 7E FF    ld   a,(ix-$01)	; compares the height of the left position with the height of the current position
4525: E6 3F       and  $3F
4527: 91          sub  c
4528: 28 17       jr   z,$4541		; if they match, jump

452A: 3C          inc  a
452B: FE 03       cp   $03
452D: D0          ret  nc			; if the height difference is very large, exit

452E: 47          ld   b,a			; saves the height difference
452F: DD 7E E8    ld   a,(ix-$18)	; obtains the height of position (x,y-1)
4532: E6 3F       and  $3F
4534: 91          sub  c
4535: C0          ret  nz			; if the height does not match that of (x,y), exit
4536: DD 7E E7    ld   a,(ix-$19)	; obtains the height of position (x-1,y-1)
4539: E6 3F       and  $3F
453B: 91          sub  c
453C: 3C          inc  a
453D: B8          cp   b
453E: C0          ret  nz			; if the height difference does not match that of (x-1,y), exit
453F: 18 14       jr   $4555		; jump

; arrives here if the height of pos (x,y) and pos (x-1,y) match
4541: DD 7E E8    ld   a,(ix-$18)	; obtains the height of position (x,y-1)
4544: E6 3F       and  $3F
4546: 91          sub  c			; if the height difference is very large, exit
4547: 3C          inc  a
4548: FE 03       cp   $03
454A: D0          ret  nc
454B: 47          ld   b,a
454C: DD 7E E7    ld   a,(ix-$19)	; obtains the height of position (x-1,y-1)
454F: E6 3F       and  $3F
4551: 91          sub  c
4552: 3C          inc  a			; if the height difference does not match that of (x,y-1), exit
4553: B8          cp   b
4554: C0          ret  nz

; arrives here if the height difference between the 4 positions considered is small
4555: DD CB 00 FE set  7,(ix+$00)	; sets bit 7 of the position to 1
4559: 00          nop				; modified from outside with a ret or a nop

455A: DD CB 00 BE res  7,(ix+$00)	; sets bit 7 to 0 (not an explored position)
455E: DD CB 00 76 bit  6,(ix+$00)
4562: 3A 18 44    ld   a,($4418)	; reads the parameter with which it jumps to the routine
4565: 20 08       jr   nz,$456F		; if bit 6 is 1 (found what it was looking for), jump

; if it has not found what it was looking for
4567: DD CB 00 FE set  7,(ix+$00)	; sets bit 7 to 1 (explored square), saves the current position on the stack and exits
456B: C1          pop  bc
456C: D5          push de
456D: C5          push bc
456E: C9          ret

; arrives here if bit 6 is 1 (found what was being searched for)
456F: C1          pop  bc			; removes the return address from the stack
4570: 32 18 44    ld   ($4418),a	; saves the final orientation
4573: 3E FF       ld   a,$FF		; 0xff indicates that the search was successful

; jumps here to exit (if there are no more combinations or if it has finished)
4575: 32 B6 2D    ld   ($2DB6),a	; writes the search result
4578: ED 7B B0 2D ld   sp,($2DB0)	; restores the stack from before executing the search algorithm
457C: FB          ei
457D: C9          ret				; exits the original routine

; ------------- end of code and data related to pathfinding on the same screen --------------------------

; this code is never executed
457E: C4 A9 1E    call nz,$1EA9
4581: 63          ld   h,e

; called from adso when down cursor is pressed
; tries to advance in guillermo's orientation
4582: CD 91 45    call $4591		; clears the height buffer positions occupied by adso and modifies a couple of instructions
4585: 3A 37 30    ld   a,($3037)	; obtains guillermo's orientation and selects a table entry according to guillermo's orientation
4588: 3C          inc  a			; 0 -> 1
4589: FE 03       cp   $03			; 1 -> 2
458B: 20 3A       jr   nz,$45C7		; 2 -> 7
458D: 3E 07       ld   a,$07		; 3 -> 4
458F: 18 36       jr   $45C7		; jumps to write the commands to advance in the orientation guillermo is facing
; it's about advancing in the orientation guillermo is facing, and trying the rest of the orientations clockwise,
; except for the opposite orientation to guillermo's orientation

4591: 0E 00       ld   c,$00
4593: CD EF 28    call $28EF		; if the sprite position is central and the height is correct, puts c in the height buffer positions it occupies
4596: 3E C9       ld   a,$C9
4598: 32 59 45    ld   ($4559),a	; modifies a routine by putting a ret
459B: DD 7E 00    ld   a,(ix+$00)	; obtains the height of the character's main position in the height buffer
459E: E6 0F       and  $0F
45A0: 32 1C 45    ld   ($451C),a	; sets a routine parameter
45A3: C9          ret

; called from adso when he prevents guillermo from advancing
45A4: CD 91 45    call $4591		; clears the height buffer positions occupied by adso and modifies a couple of instructions
; arrives here with ix pointing to adso's height buffer
45A7: ED 5B 38 30 ld   de,($3038)	; obtains guillermo's position
45AB: 0E 00       ld   c,$00
45AD: 3A 47 30    ld   a,($3047)	; obtains adso's x position
45B0: 93          sub  e
45B1: 30 04       jr   nc,$45B7		; if adso is to the right of guillermo, jump
45B3: ED 44       neg				; otherwise, makes the distance positive
45B5: CB D1       set  2,c			; indicates that guillermo is to the right of adso
45B7: 5F          ld   e,a			; e = distance in x between the 2 characters

45B8: 3A 48 30    ld   a,($3048)	; obtains adso's y position
45BB: 92          sub  d
45BC: 30 04       jr   nc,$45C2		; if adso is behind guillermo, jump
45BE: ED 44       neg				; otherwise, makes the distance positive
45C0: CB C9       set  1,c			;4 indicates that guillermo is behind adso
45C2: BB          cp   e			; compares the distances in both coordinates
45C3: 30 01       jr   nc,$45C6		; if distance in Y >= distance in X, jump
45C5: 0C          inc  c			; modifies the entry

45C6: 79          ld   a,c			; obtains the calculated value

45C7: 87          add  a,a			; each entry occupies 4 bytes
45C8: 87          add  a,a
45C9: 21 1F 46    ld   hl,$461F		; indexes in the table of orientations to try for movement
45CC: CD 2D 16    call $162D		; hl = hl + a
45CF: EB          ex   de,hl		; de points to the corresponding entry
45D0: 06 03       ld   b,$03		; repeats for 3 values (the opposite orientation to the desired movement is not tested)
45D2: 1A          ld   a,(de)		; reads a value from the table and saves it in c
45D3: 4F          ld   c,a			; character orientation
45D4: C5          push bc
45D5: DD E5       push ix
45D7: D5          push de
45D8: 21 17 46    ld   hl,$4617		; points to the height buffer displacement table according to orientation
45DB: 87          add  a,a			; each entry occupies 2 bytes
45DC: CD 2D 16    call $162D		; hl = hl + a
45DF: 4E          ld   c,(hl)
45E0: 23          inc  hl
45E1: 46          ld   b,(hl)		; reads the displacement according to the orientation to test
45E2: DD 09       add  ix,bc		; calculates the position in the height buffer
45E4: DD CB 00 BE res  7,(ix+$00)	; clears bit 7
45E8: DD 4E 00    ld   c,(ix+$00)	; obtains what's there
45EB: CD 17 45    call $4517		; checks 4 positions relative to ix ((x,y),(x,y-1),(x-1,y)(x-1,y-1) and if there is not much height difference, sets bit 7 of (x,y)
45EE: DD CB 00 7E bit  7,(ix+$00)	; if the previous routine has set bit 7 (because it can advance to that position), jump
45F2: 20 12       jr   nz,$4606
45F4: D1          pop  de
45F5: DD E1       pop  ix
45F7: C1          pop  bc
45F8: 13          inc  de			; if not, tries with another orientation from the table
45F9: 10 D7       djnz $45D2		; repeats for the 3 orientations available

; if it gets here, the character cannot move to any of the proposed orientations
45FB: AF          xor  a
45FC: 32 59 45    ld   ($4559),a	; leaves the previous routine as it was
45FF: FD 4E 0E    ld   c,(iy+$0e)
4602: CD EF 28    call $28EF		; if the sprite position is central and the height is correct, puts c in the height buffer positions it occupies
4605: C9          ret

;jumps here, the character is going to move to the orientation it was testing
4606: DD CB 00 BE res  7,(ix+$00)	; clears bit 7
460A: D1          pop  de
460B: DD E1       pop  ix
460D: C1          pop  bc
460E: CD 3F 46    call $463F		; writes a command to advance in the new character orientation
4611: CD FB 45    call $45FB		; leaves the previous routine as it was and sets the character's height buffer positions
4614: C3 7B 08    jp   $087B		; calls adso's behavior again

; displacement table within the height buffer according to orientation (related to 0x461f)
4617: 	0001 = +01 -> 0x00
	FFE8 = -24 -> 0x01
	FFFF = -01 -> 0x02
	0018 = +24 -> 0x03

; table of orientations to try for movement in a certain direction
; each entry occupies 4 bytes. The orientations of each entry are tested from left to right
; the entries are intelligently ordered.
; 2 large groups of entries can be distinguished. The first group of entries (the first 4)
; gives more priority to movements to the right and the second group of entries (the last 4)
; gives more priority to movements to the left. Within each group of entries, the first 2 entries
; give more priority to downward movements, and the other 2 entries give more priority
; to upward movements
461F: 	03 00 02 01	-> 0x00 -> (+y, +x, -x, -y) -> if adso is to the right and behind guillermo, with dist y >= dist x
	00 03 01 02 -> 0x01 -> (+x, +y, -y, -x) -> if adso is to the right and behind guillermo, with dist y < dist x
	01 00 02 03 -> 0x02 -> (-y, +x, -x, +y) -> if adso is to the right and in front of guillermo, with dist y >= dist x
	00 01 03 02 -> 0x03 -> (+x, -y, +y, -x) -> if adso is to the right and in front of guillermo, with dist y < dist x

	03 02 00 01 -> 0x04 -> (+y, -x, +x, -y) -> if adso is to the left and behind guillermo, with dist y >= dist x
	02 03 01 00 -> 0x05 -> (-x, +y, -y, +x) -> if adso is to the left and behind guillermo, with dist y < dist x
	01 02 00 03 -> 0x06 -> (-y, -x, +x, +y) -> if adso is to the left and in front of guillermo, with dist y >= dist x
	02 01 03 00 -> 0x07 -> (-x, -y, +y, +x) -> if adso is to the left and in front of guillermo, with dist y < dist x

; writes a command to change the character's orientation and advance in that orientation
;  c = new character orientation
463F: 21 4F 46    ld   hl,$464F			; points to a routine (writes a command depending on whether it goes up, down or stays)
4642: 22 01 48    ld   ($4801),hl		; modifies a routine that calls the next routine
4645: CD E6 47    call $47E6
4648: 21 60 46    ld   hl,$4660			; points to another routine
464B: 22 01 48    ld   ($4801),hl		; restores the original routine that was called by the previous routine
464E: C9          ret

; changes the character's orientation and advances in that orientation
; iy points to a character's position data
; c = new character orientation
464F: FD 7E 01    ld   a,(iy+$01)		; obtains the character's orientation
4652: FD 71 01    ld   (iy+$01),c		; sets the new character orientation
4655: B9          cp   c				; checks if it was the orientation the character had
4656: C4 C3 47    call nz,$47C3			; if it wasn't, writes some commands to change the character's orientation
4659: CD B8 27    call $27B8			; checks the height of the positions the character is going to move to and returns them in a and c
465C: CD 29 47    call $4729			; writes a command depending on whether it goes up, down or stays
465F: C9          ret

; ----------------- code related to path reconstruction from the search algorithm -------------------------

; generates the commands to follow a path on the same screen
4660: ED 73 B0 2D ld   ($2DB0),sp	; saves the current stack
4664: F3          di
4665: 3E FF       ld   a,$FF
4667: 32 4B 2D    ld   ($2D4B),a	; sets the interrupt counter to maximum so nothing is waited for in the main loop
466A: 31 00 00    ld   sp,$0000		; modified with the top of the stack that has the movements made
466D: D1          pop  de			; obtains the movement at the top of the stack
466E: 21 00 95    ld   hl,$9500
4671: 36 FF       ld   (hl),$FF		; marks the end of the movements
4673: 23          inc  hl
4674: ED 4B B4 2D ld   bc,($2DB4)	; obtains the position the character must go to
4678: 71          ld   (hl),c		;  and saves it at the beginning of the buffer
4679: 23          inc  hl
467A: 70          ld   (hl),b
467B: 23          inc  hl
467C: 3A 18 44    ld   a,($4418)	; reads the resulting orientation
467F: EE 02       xor  $02			; inverts the orientation
4681: 77          ld   (hl),a		; writes the orientation
4682: 3A 19 44    ld   a,($4419)	; reads the number of iterations performed
4685: FE 01       cp   $01
4687: 28 4A       jr   z,$46D3		; if it's 1, exit

4689: C1          pop  bc			; takes values from the stack until finding the iteration marker (-1)
468A: 78          ld   a,b
468B: E6 80       and  $80
468D: 28 FA       jr   z,$4689

; arrives here after taking FFFF from the stack
468F: 23          inc  hl
4690: 73          ld   (hl),e		; saves the movement from the top of the stack
4691: 23          inc  hl
4692: 72          ld   (hl),d
4693: C1          pop  bc			; obtains the next value from the stack
4694: 78          ld   a,b			; a = y coordinate of the position taken from the stack
4695: 92          sub  d			; subtracts the y coordinate of the final position
4696: 3C          inc  a			; increments a and jumps if it's >= 3 and < 0, so it doesn't jump if the distance was -1, 0 or 1
4697: FE 03       cp   $03
4699: 30 F8       jr   nc,$4693		; if the distance in y >= 2, continues taking values from the stack
469B: 32 A8 46    ld   ($46A8),a
469E: 79          ld   a,c			; a = x coordinate of the position taken from the stack
469F: 93          sub  e			; subtracts the x coordinate of the final position
46A0: 3C          inc  a
46A1: FE 03       cp   $03
46A3: 30 EE       jr   nc,$4693		; if the distance in x >= 2, continues taking values from the stack
46A5: 87          add  a,a			; otherwise, combines the distances +1 in x and in y in the lower 4 bits of a
46A6: 87          add  a,a
46A7: C6 00       add  a,$00		; modified with the distance in y between the position taken from the stack and the final one
46A9: ED 43 C3 46 ld   ($46C3),bc	; modifies an instruction with the value taken from the stack

46AD: 06 00       ld   b,$00		; tests orientation 0
46AF: FE 01       cp   $01			; a = 1 (00 01) when the distance in x is -1 and in y is 0 (x-1,y)
46B1: 28 0F       jr   z,$46C2		; if equal, jump
46B3: 04          inc  b			; tests orientation 1
46B4: FE 06       cp   $06			; a = 6 (01 10) when the distance in x is 0 and in y is 1 (x,y+1)
46B6: 28 0A       jr   z,$46C2		; if equal, jump
46B8: 04          inc  b			; tests orientation 2
46B9: FE 09       cp   $09			; a = 6 (10 01) when the distance in x is 1 and in y is 0 (x+1,y)
46BB: 28 05       jr   z,$46C2		; if equal, jump
46BD: 04          inc  b			; tests orientation 3
46BE: FE 04       cp   $04			; a = 6 (01 00) when the distance in x is 0 and in y is -1 (x,y-1)
46C0: 20 D1       jr   nz,$4693		; if it's none of the 4 cases where one unit was advanced, continues taking elements

; arrives here if the value taken from the stack was a previous iteration of one of the above
46C2: 11 00 00    ld   de,$0000		; instruction modified with the value taken from the stack
46C5: 23          inc  hl
46C6: 70          ld   (hl),b		; saves the movement orientation
46C7: 3A B2 2D    ld   a,($2DB2)	; reads the x coordinate of the origin
46CA: BB          cp   e			; if it's not the same as the one taken from the stack, continues processing one more iteration
46CB: 20 BC       jr   nz,$4689
46CD: 3A B3 2D    ld   a,($2DB3)	; reads the y coordinate of the origin
46D0: BA          cp   d			; if it's not the same as the one taken from the stack, continues processing one more iteration
46D1: 20 B6       jr   nz,$4689

; if it gets here, the complete path from destination to origin has been found
46D3: ED 7B B0 2D ld   sp,($2DB0)	; restores the stack
46D7: FB          ei
46D8: E5          push hl			; obtains the beginning of the movement stack in ix
46D9: DD E1       pop  ix

46DB: FD 46 01    ld   b,(iy+$01)	; obtains the character's orientation
46DE: DD 4E 00    ld   c,(ix+$00)	; reads the orientation it should take
46E1: FD CB 05 7E bit  7,(iy+$05)
46E5: 28 0E       jr   z,$46F5		; if the character occupies 4 positions, skips this part
46E7: 78          ld   a,b
46E8: A9          xor  c			; compares the character's orientation with the one it should take
46E9: E6 01       and  $01
46EB: 28 08       jr   z,$46F5		; if the character is not going to rotate ninety degrees in x, jump
46ED: FD 7E 05    ld   a,(iy+$05)	; otherwise, changes the rotated state on slope
46F0: EE 20       xor  $20
46F2: FD 77 05    ld   (iy+$05),a

46F5: 78          ld   a,b			; a = character orientation
46F6: FD 71 01    ld   (iy+$01),c	; modifies the character's orientation with that of the route it should follow
46F9: B9          cp   c			; checks if its orientation has changed
46FA: C4 C3 47    call nz,$47C3		; if its orientation has changed, writes some commands to change the character's orientation
46FD: DD E5       push ix
46FF: CD B8 27    call $27B8		; checks the height of the positions the character is going to move to and returns them in a and c
4702: CD 29 47    call $4729		; writes a command depending on whether it goes up, down or stays
4705: DD E1       pop  ix

4707: DD 2B       dec  ix			; advances to the next position of the path
4709: DD 2B       dec  ix
470B: DD 2B       dec  ix
470D: DD 7E 00    ld   a,(ix+$00)
4710: FE FF       cp   $FF			; if the last position of the path has been reached, exit
4712: C8          ret  z
4713: FD 6E 02    ld   l,(iy+$02)	; obtains the character's position
4716: FD 66 03    ld   h,(iy+$03)
4719: CD 9B 27    call $279B		; adjusts the position passed in hl to the central 20x20 positions shown. If the position is outside, CF=1
471C: DD 5E 01    ld   e,(ix+$01)	; obtains the position stored in this stack position
471F: DD 56 02    ld   d,(ix+$02)
4722: A7          and  a
4723: ED 52       sbc  hl,de		; compares the character's position with that of the stack
4725: 28 B4       jr   z,$46DB		; if they match, it's because it has reached the destination position and must take more values from the stack
4727: 18 DE       jr   $4707		; otherwise, continues processing entries

; writes a command depending on whether it goes up, down or stays
; called with:
;  iy = character position data
;  a and c = height of the positions the character is going to move to
4729: FD CB 05 A6 res  4,(iy+$05)		; indicates that the character is not descending in height
472D: FD CB 05 7E bit  7,(iy+$05)
4731: 28 46       jr   z,$4779			; if the character occupies 4 positions, jump

; arrives here if the character occupies one position
4733: FD CB 05 6E bit  5,(iy+$05)
4737: 28 08       jr   z,$4741			; if the character is not rotated with respect to the slope, jump
4739: D9          exx
473A: 21 1A 44    ld   hl,$441A			; points to the command table if the character goes up in height
473D: D9          exx
473E: C3 B4 47    jp   $47B4

; arrives here if the character occupies one position and bit 5 is 0
4741: FD 34 04    inc  (iy+$04)		; increments the character's height
4744: D9          exx
4745: 21 1A 44    ld   hl,$441A		; points to the command table if the character goes up in height
4748: D9          exx
4749: FE 01       cp   $01
474B: 28 0F       jr   z,$475C		; if the height difference is 1 (going up), jump

474D: D9          exx
474E: 21 20 44    ld   hl,$4420		; points to the command table if the character goes down in height
4751: D9          exx
4752: FD 35 04    dec  (iy+$04)
4755: FD CB 05 E6 set  4,(iy+$05)	; otherwise, it's descending
4759: FD 35 04    dec  (iy+$04)

475C: B9          cp   c
475D: 20 4F       jr   nz,$47AE		; if the height differences are not equal, jump

475F: D9          exx
4760: 23          inc  hl			; moves to another table entry
4761: 23          inc  hl
4762: 23          inc  hl
4763: D9          exx
4764: FD 7E 05    ld   a,(iy+$05)	; preserves only the bit for whether it goes up and down (and converts the character to one of 4 positions)
4767: E6 10       and  $10
4769: FD 77 05    ld   (iy+$05),a
476C: E5          push hl
476D: CD E4 29    call $29E4		; updates the character's x and y position according to the orientation it's advancing in
4770: E1          pop  hl
4771: CD AE 29    call $29AE		; returns 0 if the character's orientation is 0 or 3, otherwise returns 1
4774: CC E4 29    call z,$29E4		; updates the character's x and y position according to the orientation it's advancing in
4777: 18 3E       jr   $47B7

; arrives here if the character occupies four positions
;  a = height difference with position 1 closest to the character according to orientation
;  c = height difference with position 2 closest to the character according to orientation
4779: FE 01       cp   $01
477B: 28 0B       jr   z,$4788		; if going up, jump
477D: FE FF       cp   $FF
477F: 28 13       jr   z,$4794		; if going down, jump
4781: D9          exx
4782: 21 26 44    ld   hl,$4426		; points to the table if the character doesn't change height
4785: D9          exx
4786: 18 26       jr   $47AE

; arrives here if going up
4788: FD 34 04    inc  (iy+$04)		; increments the height
478B: 3E 80       ld   a,$80
478D: D9          exx
478E: 21 1D 44    ld   hl,$441D		; points to the table if the character goes up in height
4791: D9          exx
4792: 18 0A       jr   $479E

; arrives here if going down
4794: FD 35 04    dec  (iy+$04)		; decrements the height
4797: 3E 90       ld   a,$90
4799: D9          exx
479A: 21 23 44    ld   hl,$4423		; points to the table if the character goes down in height
479D: D9          exx

479E: FD 77 05    ld   (iy+$05),a	; updates the state
47A1: E5          push hl
47A2: CD E4 29    call $29E4		; updates the character's x and y position according to the orientation it's advancing in
47A5: E1          pop  hl
47A6: CD AE 29    call $29AE		; returns 0 if the character's orientation is 0 or 3, otherwise returns 1
47A9: C4 E4 29    call nz,$29E4		; updates the character's x and y position according to the orientation it's advancing in
47AC: 18 09       jr   $47B7

; arrives here if the heights are not equal or if the character occupies 4 positions and doesn't change height
47AE: 91          sub  c
47AF: 3C          inc  a
47B0: FE 03       cp   $03
47B2: 18 00       jr   $47B4		; unconditional jump ignoring the previous comparison

47B4: CD E4 29    call $29E4		; updates the character's x and y position according to the orientation it's advancing in

47B7: D9          exx
47B8: 56          ld   d,(hl)		; reads in de the command to set
47B9: 23          inc  hl
47BA: 5E          ld   e,(hl)
47BB: 23          inc  hl
47BC: 46          ld   b,(hl)		; reads the command length
47BD: EB          ex   de,hl
47BE: CD E9 0C    call $0CE9		; writes b bits of the command passed in hl of the character passed in iy
47C1: D9          exx
47C2: C9          ret

; writes some commands to change the character's orientation from the current orientation to the desired one
;  a = current character orientation
;  c = orientation the character will take
47C3: 91          sub  c			; obtains the difference between the orientations
47C4: 30 08       jr   nc,$47CE		; if the difference is positive, jump
47C6: ED 44       neg				; difference = -difference
47C8: EE 02       xor  $02			; changes the direction in x
47CA: 20 02       jr   nz,$47CE
47CC: 3E 02       ld   a,$02		; if it was 0, sets to 2

47CE: 4F          ld   c,a			; c = final orientation
47CF: 21 0C 44    ld   hl,$440C		; points to the command length table according to orientation
47D2: CD 2D 16    call $162D		; hl = hl + a
47D5: 46          ld   b,(hl)		; reads the command length
47D6: 21 10 44    ld   hl,$4410		; points to the command table for turning
47D9: 79          ld   a,c
47DA: 87          add  a,a			; each entry occupies 2 bytes
47DB: CD 2D 16    call $162D		; hl = hl + a
47DE: 56          ld   d,(hl)		; de = value read from the table
47DF: 23          inc  hl
47E0: 5E          ld   e,(hl)
47E1: EB          ex   de,hl
47E2: CD E9 0C    call $0CE9		; writes b bits of the command passed in hl of the character passed in iy
47E5: C9          ret

; iy points to a character's position data
; c = new character orientation
; can call routine 0x4660 or 0x464f
; routine 0x4660 handles generating all commands to go from origin to destination
; routine 0x464f writes a command depending on whether it goes up, down or stays or the orientation and exits
47E6: FD 56 03    ld   d,(iy+$03)
47E9: FD 5E 02    ld   e,(iy+$02)
47EC: D5          push de			; saves the character's position on the stack
47ED: FD 56 01    ld   d,(iy+$01)
47F0: FD 5E 04    ld   e,(iy+$04)
47F3: D5          push de			; saves the character's orientation and height on the stack

47F4: FD 36 09 00 ld   (iy+$09),$00	; resets the character's actions
47F8: FD 36 0B 00 ld   (iy+$0b),$00

47FC: FD 7E 05    ld   a,(iy+$05)
47FF: F5          push af			; saves the value of iy+05 (indicates where the character moves and its size)
4800: CD 60 46    call $4660		; instruction modified from outside with the routine to call (0x4660 or 0x464f)
4803: F1          pop  af			; restores the previous value of iy+05
4804: FD 77 05    ld   (iy+$05),a	; restores the value
4807: 21 00 10    ld   hl,$1000
480A: 06 0C       ld   b,$0C
480C: CD E9 0C    call $0CE9		; writes a command to wait a bit before moving again
480F: E1          pop  hl			; restores the character's orientation and height
4810: FD 75 04    ld   (iy+$04),l
4813: FD 74 01    ld   (iy+$01),h
4816: E1          pop  hl			; restores the character's position
4817: FD 75 02    ld   (iy+$02),l
481A: FD 74 03    ld   (iy+$03),h

481D: FD 36 09 00 ld   (iy+$09),$00	; resets the character's action pointer
4821: FD 36 0B 00 ld   (iy+$0b),$00
4825: C9          ret

; -------------end of code related to path reconstruction from the search algorithm -------------------------

; ------------- code related to pathfinding between screens ----------------------------------

; searches for the screen indicated in 0x2db4 starting at the position indicated in 0x2db2
4826: 2A B4 2D    ld   hl,($2DB4)	; obtains the screen being searched for
4829: CD B5 48    call $48B5		; given the most significant position of a character in hl, indexes in the floor table and returns the entry in ix
482C: DD CB 00 F6 set  6,(ix+$00)	; marks the searched screen as the destination within the floor

; searches for the indicated screen that meets a mask specified in 0x48a4, starting the search at the position indicated in 0x2db2
4830: ED 73 B0 2D ld   ($2DB0),sp	; saves the initial stack
4834: 31 FE 9C    ld   sp,$9CFE		; sets the stack address to the end of the sprite buffer
4837: ED 5B B2 2D ld   de,($2DB2)	; obtains the position of the character searching for another
483B: D5          push de			; saves the initial position on the stack
483C: EB          ex   de,hl
483D: CD B5 48    call $48B5		; given the most significant position of a character in hl, indexes in the floor table and returns the entry in ix
4840: DD CB 00 FE set  7,(ix+$00)	; marks the initial position as explored
4844: 21 FF FF    ld   hl,$FFFF		; puts a -1
4847: E5          push hl
4848: 21 FE 9C    ld   hl,$9CFE		; points hl to the processed part of the stack

484B: 2B          dec  hl
484C: 56          ld   d,(hl)
484D: 2B          dec  hl
484E: 5E          ld   e,(hl)		; de = current element of the stack
484F: 7B          ld   a,e
4850: E6 80       and  $80
4852: 28 0D       jr   z,$4861		; if an iteration has not been completed, jump
4854: AF          xor  a
4855: 44          ld   b,h			; bc = hl
4856: 4D          ld   c,l
4857: ED 72       sbc  hl,sp		; check if all stack elements have been processed
4859: 69          ld   l,c			; hl = bc
485A: 60          ld   h,b
485B: CA 75 45    jp   z,$4575		; if so, exit
485E: D5          push de			; push -1 onto the stack
485F: 18 EA       jr   $484B		; continue processing stack elements

; here it arrives to process a stack element
4861: E5          push hl
4862: D5          push de
4863: EB          ex   de,hl
4864: CD B5 48    call $48B5		; given the most significant position of a character in hl, index into the floor table and return the entry in ix
4867: D1          pop  de
4868: E1          pop  hl
4869: DD 23       inc  ix
486B: 1C          inc  e			; move to position (x+1,y)
486C: 01 04 02    ld   bc,$0204		; orientation = 2, try to exit through bit 2
486F: CD 9B 48    call $489B		; check if the position passed in ix can be accessed, and if so, if it has already been explored before.
									; if it hadn't been explored and was the one being searched for, exit the algorithm. Otherwise, push it onto the stack to explore from that position
4872: 01 EF FF    ld   bc,$FFEF
4875: DD 09       add  ix,bc		; move to position (x,y-1)
4877: 01 08 03    ld   bc,$0308		; orientation = 3, try to exit through bit 3
487A: 1D          dec  e
487B: 15          dec  d
487C: CD 9B 48    call $489B		; check if the position passed in ix can be accessed, and if so, if it has already been explored before.
									; if it hadn't been explored and was the one being searched for, exit the algorithm. Otherwise, push it onto the stack to explore from that position
487F: 01 0F 00    ld   bc,$000F
4882: DD 09       add  ix,bc
4884: 14          inc  d
4885: 1D          dec  e
4886: 01 01 00    ld   bc,$0001		; orientation = 0, try to enter through bit 1
4889: CD 9B 48    call $489B		; check if the position passed in ix can be accessed, and if so, if it has already been explored before.
									; if it hadn't been explored and was the one being searched for, exit the algorithm. Otherwise, push it onto the stack to explore from that position
488C: 01 11 00    ld   bc,$0011
488F: DD 09       add  ix,bc		; move to position (x,y+1)
4891: 14          inc  d
4892: 1C          inc  e
4893: 01 02 01    ld   bc,$0102		; orientation = 1, try to exit through bit 2
4896: CD 9B 48    call $489B		; check if the position passed in ix can be accessed, and if so, if it has already been explored before.
									; if it hadn't been explored and was the one being searched for, exit the algorithm. Otherwise, push it onto the stack to explore from that position
4899: 18 B0       jr   $484B		; continue trying stack combinations

; check if the position passed in ix can be accessed, and if so, if it has already been explored before.
; if it hadn't been explored and was the one being searched for, exit the algorithm. Otherwise, push it onto the stack to explore from that position
; c = orientation through which to exit the room
; b = orientation used to go from destination to origin
489B: DD 7E 00    ld   a,(ix+$00)	; get room data
489E: A1          and  c			; if unable to exit the room through the passed orientation, exit
489F: C0          ret  nz

48A0: 78          ld   a,b
48A1: DD CB 00 76 bit  6,(ix+$00)	; instruction modified from outside by changing the bit number to check
48A5: C2 6F 45    jp   nz,$456F		; if the searched bit is set, exit the algorithm saving the destination orientation and indicating the search was successful
48A8: DD CB 00 7E bit  7,(ix+$00)	; otherwise, if the position has already been explored, exit
48AC: C0          ret  nz

48AD: DD CB 00 FE set  7,(ix+$00)	; if the position hadn't been explored, mark it as explored
48B1: C1          pop  bc			; retrieve return address
48B2: D5          push de			; push current position onto stack
48B3: C5          push bc			; save return address again
48B4: C9          ret

; given the most significant position of a character in hl, index into the floor table and return the entry in ix
48B5: 7C          ld   a,h
48B6: 87          add  a,a
48B7: 87          add  a,a
48B8: 87          add  a,a
48B9: 87          add  a,a			; h = h*16
48BA: B5          or   l			; combine position into one byte
48BB: 5F          ld   e,a
48BC: 16 00       ld   d,$00		; de stores character position
48BE: DD 2A 0A 44 ld   ix,($440A)
48C2: DD 19       add  ix,de
48C4: C9          ret
; ------------- end of pathfinding code between screens ----------------------------------

48C5: C3 9A 24    jp   $249A

; ----------------------------- sprite drawing begins ------------------------------
; table with monk robes data for orientations and/or steps
48C8: 	ABDB -> 0x00
	AB59 -> 0x01
	ABDB -> 0x02
	AC53 -> 0x03
   	ADBB -> 0x04
   	ACCB -> 0x05
	ADBB -> 0x06
	AD48 -> 0x07
	B090 -> 0x08
	AFA0 -> 0x09
	B090 -> 0x0a
	B01D -> 0x0b
	AEB0 -> 0x0c
	AE2E -> 0x0d
	AEB0 -> 0x0e
	AF28 -> 0x0f

; table with light fill pattern
48E8: 	00E0 -> 0x00
	03F8 -> 0x01
	07FC -> 0x02
	07FC -> 0x03
	0FFE -> 0x04
	0FFE -> 0x05
	1FFF -> 0x06
	1FFF -> 0x07
	1FFF -> 0x08
	1FFF -> 0x09
	0FFE -> 0x0a
	0FFE -> 0x0b
	07FC -> 0x0c
	07FC -> 0x0d
	03F8 -> 0x0e
	00E0 -> 0x0f

4908: 0000 ; sprite buffer pointer
490A: 0000 ; original stack
490C: 0000 ; stack when working with sprite buffer

; delay until bc is 0
490E: 0B          dec  bc
490F: 78          ld   a,b
4910: B1          or   c
4911: 20 FB       jr   nz,$490E
4913: C9          ret

4914: ED 73 0A 49 ld   ($490A),sp	; save stack address
4918: 21 00 95    ld   hl,$9500		; hl points to start of sprite buffer
491B: 22 08 49    ld   ($4908),hl	; save sprite buffer pointer
491E: 21 00 00    ld   hl,$0000
4921: 4C          ld   c,h			; initially, no active entry (c = 0)
4922: E5          push hl			; save a 0 (to indicate it's the last entry)
4923: 21 17 2E    ld   hl,$2E17		; hl points to first sprite entry
4926: 11 14 00    ld   de,$0014		; de = 20 bytes per entry

4929: 7E          ld   a,(hl)		; read first byte of entry
492A: FE FF       cp   $FF
492C: 28 0D       jr   z,$493B		; if 0xff, jump (last entry)
492E: FE FE       cp   $FE
4930: 28 06       jr   z,$4938		; if 0xfe, advance to next entry
4932: E5          push hl			;  otherwise, save entry address
4933: CB 7F       bit  7,a			;  if sprite has changed, increment c
4935: 28 01       jr   z,$4938
4937: 0C          inc  c			; mark entry as active
4938: 19          add  hl,de
4939: 18 EE       jr   $4929

; here it arrives once it has pushed entries to process onto the stack
493B: ED 73 90 30 ld   ($3090),sp	; save stack address
493F: F3          di
4940: 79          ld   a,c
4941: A7          and  a
4942: 20 06       jr   nz,$494A		; if there was any active entry, jump
4944: ED 7B 0A 49 ld   sp,($490A)	; retrieve stack address and exit
4948: FB          ei
4949: C9          ret

; here it arrives if there was any entry that needed to be drawn
; first entries are sorted by depth using improved bubble sort method
494A: ED 7B 90 30 ld   sp,($3090)		; retrieve top of stack address
494E: 06 00       ld   b,$00			; initially, 0 swaps

4950: D1          pop  de				; retrieve last 2 stack entries
4951: E1          pop  hl
4952: 7D          ld   a,l
4953: B4          or   h
4954: 20 06       jr   nz,$495C			; if second entry is not 0 (end marker), jump
4956: 78          ld   a,b
4957: A7          and  a
4958: 20 F0       jr   nz,$494A			; if reached beginning and there was any swap, process stack again
495A: 18 13       jr   $496F			; if reached here, stack is sorted, so begin processing it

; here it arrives when an entry that is not the last has been retrieved
495C: 1A          ld   a,(de)
495D: E6 3F       and  $3F
495F: 4F          ld   c,a				; c = depth of last entry
4960: 7E          ld   a,(hl)
4961: E6 3F       and  $3F				; a = depth of second-to-last entry
4963: B9          cp   c				; compare depth of 2 entries
4964: 38 03       jr   c,$4969			; if (hl) < (de), perform a swap
4966: E5          push hl				; otherwise, these elements are well ordered, discard last entry and check rest until stack is empty
4967: 18 E7       jr   $4950

4969: 04          inc  b				; indicate that 2 elements have been swapped
496A: D5          push de				; swap entries
496B: E5          push hl
496C: E1          pop  hl				; last element is now sorted
496D: 18 E1       jr   $4950			; process entries again

; here it arrives once stack entries are sorted by depth
496F: ED 7B 90 30 ld   sp,($3090)	; retrieve top of stack address
4973: ED 73 92 30 ld   ($3092),sp	; save stack address pointing to object being processed

4977: 21 00 00    ld   hl,$0000
497A: 39          add  hl,sp		; hl points to stack
497B: F3          di
497C: ED 7B 92 30 ld   sp,($3092)	; get stack address
4980: D1          pop  de			; retrieve first stack value
4981: ED 73 92 30 ld   ($3092),sp	; save stack address
4985: F9          ld   sp,hl		; restore stack address to not overwrite following values

4986: FB          ei
4987: 7B          ld   a,e
4988: B2          or   d
4989: CA DF 4B    jp   z,$4BDF		; if de was the last stack value, jump (post-process sprites)

498C: D5          push de
498D: DD E1       pop  ix			; ix = de (value read from stack)
498F: DD CB 00 B6 res  6,(ix+$00)	; set bit 6 to 0
4993: DD CB 00 7E bit  7,(ix+$00)
4997: 28 DE       jr   z,$4977		; if sprite hasn't changed, continue processing rest of entries

4999: DD 6E 01    ld   l,(ix+$01)	; get entry values (x1 pos in bytes, y1 pos in pixels, width in bytes, height in pixels)
499C: DD 66 02    ld   h,(ix+$02)
499F: DD 56 06    ld   d,(ix+$06)
49A2: DD 5E 05    ld   e,(ix+$05)
49A5: CB BB       res  7,e			; bit7 of position 5 is also used, so set it to 0 as it's not needed now
49A7: CD 35 4D    call $4D35		; calculate tile position where sprite starts and expanded sprite dimensions (to cover all tiles where sprite will be drawn)
49AA: ED 53 D7 2D ld   ($2DD7),de	; save expanded sprite dimensions
49AE: 22 D5 2D    ld   ($2DD5),hl	; save tile position where sprite starts
49B1: DD 6E 03    ld   l,(ix+$03)	; get entry values (x2 pos in bytes, y2 pos in pixels, width2 in bytes, height2 in pixels)
49B4: DD 66 04    ld   h,(ix+$04)
49B7: DD 56 0A    ld   d,(ix+$0a)
49BA: DD 5E 09    ld   e,(ix+$09)
49BD: CD BF 4C    call $4CBF		; check minimum sprite dimensions (to erase old sprite) and update 0x2dd5 and 0x2dd7
49C0: 2A D5 2D    ld   hl,($2DD5)	; get initial tile position where sprite starts
49C3: DD 75 0C    ld   (ix+$0c),l
49C6: DD 74 0D    ld   (ix+$0d),h

; given hl, calculate corresponding tile buffer coordinate (16x20 tile buffer, where each tile is 16x8)
49C9: 7D          ld   a,l
49CA: E6 FC       and  $FC
49CC: 5F          ld   e,a			; e = initial tile x position where sprite starts (in bytes)
49CD: CB 3F       srl  a			; a = e/2
49CF: 83          add  a,e			; de = x + x/2 (since each byte has 4 pixels and each tile buffer entry is 6 bytes)
49D0: 5F          ld   e,a
49D1: 3E 00       ld   a,$00
49D3: 8F          adc  a,a
49D4: 57          ld   d,a
49D5: D5          push de			; save x offset

49D6: 6C          ld   l,h
49D7: 26 00       ld   h,$00		; hl = initial y tile where sprite starts (in pixels)
49D9: 29          add  hl,hl
49DA: 29          add  hl,hl
49DB: 5D          ld   e,l
49DC: 54          ld   d,h
49DD: 29          add  hl,hl
49DE: 19          add  hl,de		; hl = hl*12
49DF: D1          pop  de
49E0: 19          add  hl,de		; hl points to corresponding line in tile buffer

49E1: 11 94 8B    ld   de,$8B94		; index into tile buffer (0x8b94 corresponds to position X = -2, Y = -5 in tile buffer)
49E4: 19          add  hl,de		;  which in pixels is: (X = -32, Y = -40), so first pixel of tile buffer in sprite coordinates is (32,40)
49E5: 22 95 30    ld   ($3095),hl	; save current tile address in tile buffer
49E8: 2A D7 2D    ld   hl,($2DD7)	; get sprite width and height
49EB: DD 75 0E    ld   (ix+$0e),l
49EE: DD 74 0F    ld   (ix+$0f),h
49F1: 7C          ld   a,h			; a = sprite height
49F2: 26 00       ld   h,$00		; hl = sprite width
49F4: CD 24 4D    call $4D24		; de = sprite height*sprite width
49F7: 2A 08 49    ld   hl,($4908)	; get sprite buffer address
49FA: 22 FA 4A    ld   ($4AFA),hl	; modify an instruction
49FD: DD 75 10    ld   (ix+$10),l	; save sprite buffer address
4A00: DD 74 11    ld   (ix+$11),h
4A03: 42          ld   b,d			; bc = de
4A04: 4B          ld   c,e
4A05: E5          push hl			; save obtained sprite buffer address
4A06: 09          add  hl,bc
4A07: 22 08 49    ld   ($4908),hl	; save free sprite buffer address
4A0A: 11 FE 9C    ld   de,$9CFE		; de = sprite buffer limit
4A0D: ED 52       sbc  hl,de		; hl = de - hl
4A0F: D1          pop  de			; retrieve sprite buffer address
4A10: D2 DF 4B    jp   nc,$4BDF		; if no room for sprite, jump to empty processed list and process rest

; here it arrives if there's space to process sprite
4A13: DD CB 00 F6 set  6,(ix+$00)	; mark sprite as processed
4A17: 6B          ld   l,e			; hl = de = obtained sprite buffer address
4A18: 62          ld   h,d
4A19: 13          inc  de
4A1A: 0B          dec  bc
4A1B: 36 00       ld   (hl),$00
4A1D: ED B0       ldir				; clear assigned sprite buffer area

4A1F: 01 00 00    ld   bc,$0000
4A22: ED 43 D9 4D ld   ($4DD9),bc	; modify an instruction (initially depth = 0)
4A26: ED 7B 90 30 ld   sp,($3090)	; retrieve stack address of highest priority sprite (first on stack)
4A2A: ED 73 0C 49 ld   ($490C),sp

; here it arrives after drawing a sprite to continue drawing the next one
4A2E: 21 00 00    ld   hl,$0000
4A31: 39          add  hl,sp		; hl points to stack
4A32: F3          di
4A33: ED 7B 0C 49 ld   sp,($490C)	; get stack address
4A37: D1          pop  de			; get sprite address to process
4A38: ED 73 0C 49 ld   ($490C),sp	; save new stack address
4A3C: F9          ld   sp,hl		; restore stack address to not overwrite following values
4A3D: FB          ei
4A3E: 7A          ld   a,d
4A3F: B3          or   e
4A40: C2 56 4A    jp   nz,$4A56		; if not last stack value, jump

; here it arrives if all stack sprites have been processed (with respect to current sprite)
4A43: 01 FC FC    ld   bc,$FCFC		; pass a very high depth value
4A46: 3E 00       ld   a,$00
4A48: 32 85 4D    ld   ($4D85),a	; change a ret to a nop
4A4B: CD 9E 4D    call $4D9E		; draw tiles in sprite buffer that are in front of sprite
4A4E: 3E C9       ld   a,$C9
4A50: 32 85 4D    ld   ($4D85),a	; change a nop to a ret
4A53: C3 77 49    jp   $4977		; jump until stack is empty

; here it arrives if there was any sprite on stack (0x2dd5 and 0x2dd7 have been calculated for top stack sprite), but
;  other sprites also arrive here
4A56: D5          push de			; iy = de = sprite entry address
4A57: FD E1       pop  iy
4A59: FD CB 05 7E bit  7,(iy+$05)	; if sprite is going to disappear, skip to next sprite
4A5D: 20 CF       jr   nz,$4A2E

4A5F: 3A D5 2D    ld   a,($2DD5)
4A62: 6F          ld   l,a			; l = initial x tile position where original sprite starts (in bytes)
4A63: 3A D7 2D    ld   a,($2DD7)
4A66: 5F          ld   e,a			; e = expanded width of original sprite (in bytes)
4A67: FD 66 01    ld   h,(iy+$01)	; h = initial x position of current sprite
4A6A: FD 56 05    ld   d,(iy+$05)	; d = width of current sprite
4A6D: CD 54 4D    call $4D54		; check if current sprite can be seen in original sprite area. If not, skip
									;  to another current sprite. Otherwise, clip in x the part of current sprite that can be seen
									;  in original sprite
; returns in a the length to draw of current sprite for passed coordinate
; returns in h the distance from start of current sprite to start of original sprite (for passed coordinate)
; returns in l the distance from start of original sprite to start of current sprite (for passed coordinate)
4A70: 32 11 4B    ld   ($4B11),a	; modify some instructions with calculated data
4A73: 7C          ld   a,h
4A74: 32 E6 4A    ld   ($4AE6),a
4A77: 32 4E 4B    ld   ($4B4E),a
4A7A: 7D          ld   a,l
4A7B: 32 FE 4A    ld   ($4AFE),a
4A7E: 3A D6 2D    ld   a,($2DD6)
4A81: 6F          ld   l,a			; l = initial y tile position where original sprite starts (in bytes)
4A82: 3A D8 2D    ld   a,($2DD8)
4A85: 5F          ld   e,a			; e = height of original sprite (in pixels)
4A86: FD 66 02    ld   h,(iy+$02)	; h = initial y position of current sprite
4A89: FD 56 06    ld   d,(iy+$06)	; d = height of current sprite
4A8C: CD 54 4D    call $4D54		; check if current sprite can be seen in original sprite area. If not, skip
									;  to another current sprite. Otherwise, clip in y the part of current sprite that can be seen
									;  in original sprite
; returns in a the length to draw of current sprite for passed coordinate
; returns in h the distance from start of current sprite to start of original sprite (for passed coordinate)
; returns in l the distance from start of original sprite to start of current sprite (for passed coordinate)
4A8F: 32 0E 4B    ld   ($4B0E),a	; modify some instructions with calculated data
4A92: 7C          ld   a,h
4A93: 32 A5 4A    ld   ($4AA5),a
4A96: 7D          ld   a,l
4A97: 32 EE 4A    ld   ($4AEE),a

4A9A: FD 4E 12    ld   c,(iy+$12)	; bc = get sprite position in camera coordinates
4A9D: FD 46 13    ld   b,(iy+$13)
4AA0: CD 9E 4D    call $4D9E		; copy tiles that are behind sprite into sprite buffer

; when it arrives here it draws current sprite
4AA3: D9          exx
4AA4: 21 00 00    ld   hl,$0000		; instruction modified from outside (y distance from start of current sprite to start of original sprite)
4AA7: 7D          ld   a,l
4AA8: 32 0B 4B    ld   ($4B0B),a	; modify an instruction
4AAB: FE 0A       cp   $0A
4AAD: 38 26       jr   c,$4AD5		; if y distance from start of current sprite to start of original sprite < 10, jump
4AAF: FD CB 0B 7E bit  7,(iy+$0b)
4AB3: 20 20       jr   nz,$4AD5		; if not a monk, jump

; if it arrives here it's because y distance from start of current sprite to start of original sprite is >= 10, so of current
;  sprite (which is a monk), head has already passed. Therefore, get pointer to monk's robe
4AB5: 7D          ld   a,l
4AB6: D6 0A       sub  $0A
4AB8: 6F          ld   l,a
4AB9: FD 7E 05    ld   a,(iy+$05)	; read current sprite width
4ABC: 32 30 4B    ld   ($4B30),a	; modify an instruction
4ABF: CD 24 4D    call $4D24		; de = a*hl
4AC2: FD 7E 0B    ld   a,(iy+$0b)	; a = monk robe animation
4AC5: 21 C8 48    ld   hl,$48C8		; point to monk robes table
4AC8: 87          add  a,a			; each entry is 2 bytes
4AC9: 85          add  a,l			; hl = hl + a
4ACA: 6F          ld   l,a
4ACB: 8C          adc  a,h
4ACC: 95          sub  l
4ACD: 67          ld   h,a
4ACE: 7E          ld   a,(hl)
4ACF: 23          inc  hl
4AD0: 66          ld   h,(hl)		; hl = [hl]
4AD1: 6F          ld   l,a
4AD2: 19          add  hl,de
4AD3: 18 10       jr   $4AE5

; calculate line at which to start drawing current sprite (skipping distance between start of current sprite and start of original sprite)
4AD5: FD 7E 05    ld   a,(iy+$05)	; get current sprite width
4AD8: 32 30 4B    ld   ($4B30),a	; modify an instruction
4ADB: CD 24 4D    call $4D24		; de = a*hl
4ADE: FD 6E 07    ld   l,(iy+$07)	; hl = sprite graphics data address
4AE1: FD 66 08    ld   h,(iy+$08)

4AE4: 19          add  hl,de		; hl = sprite graphics data address (skipping what doesn't overlap with original sprite area in y)
4AE5: 3E 00       ld   a,$00		; instruction modified from outside (x distance from start of current sprite to start of original sprite)
4AE7: 85          add  a,l			; hl = hl + a
4AE8: 6F          ld   l,a
4AE9: 8C          adc  a,h
4AEA: 95          sub  l
4AEB: 67          ld   h,a
4AEC: E5          push hl			; save sprite graphics data address (skipping what's not in original sprite area in x and y)

4AED: 21 00 00    ld   hl,$0000		; instruction modified from outside (y distance from start of original sprite to start of current sprite)
4AF0: 3A D7 2D    ld   a,($2DD7)	; get expanded width of original sprite
4AF3: 32 54 4B    ld   ($4B54),a	; modify an instruction
4AF6: CD 24 4D    call $4D24		; de = a*hl
4AF9: 21 00 95    ld   hl,$9500		; instruction modified from outside with initial sprite buffer position for this sprite
4AFC: 19          add  hl,de		; hl = sprite buffer address for original sprite (skipping what current sprite can't overwrite in y)
4AFD: 3E 00       ld   a,$00		; instruction modified from outside (x distance from start of original sprite to start of current sprite)
4AFF: 85          add  a,l			; de = hl + a
4B00: 5F          ld   e,a
4B01: 8C          adc  a,h
4B02: 93          sub  e
4B03: 57          ld   d,a			; de = sprite buffer address for original sprite (skipping what current sprite can't overwrite in x and y)
4B04: E1          pop  hl			; retrieve current sprite graphics data address that can match original sprite's

4B05: 7C          ld   a,h			; if hl == 0 (it's the light sprite), jump
4B06: B5          or   l
4B07: CA 60 4B    jp   z,$4B60

4B0A: 0E 00       ld   c,$00		; instruction modified from outside (y distance from start of current sprite to start of original sprite)
4B0C: D9          exx
4B0D: 06 00       ld   b,$00		; instruction modified from outside (height to draw of current sprite)
4B0F: D9          exx
4B10: 06 00       ld   b,$00		; instruction modified from outside (width to draw of current sprite)
4B12: D5          push de			; save sprite buffer address
4B13: E5          push hl			; save graphics data address
4B14: 7E          ld   a,(hl)		; read a graphics byte
4B15: A7          and  a
4B16: 28 12       jr   z,$4B2A		; if 0, skip to next pixel
4B18: D9          exx
4B19: 6F          ld   l,a			; l = or mask
4B1A: 0F          rrca				; a = b3 b2 b1 b0 b7 b6 b5 b4
4B1B: 0F          rrca
4B1C: 0F          rrca
4B1D: 0F          rrca
4B1E: B5          or   l			; a = b7|b3 b6|b2 b5|b1 b4|b0 b7|b3 b6|b2 b5|b1 b4|b0
4B1F: 28 06       jr   z,$4B27		; if 0, jump (???, wouldn't it be 0 before too???)
4B21: 2F          cpl				; 0->1
4B22: 67          ld   h,a			; h = and mask (sprites use color 0 as transparent)
4B23: D9          exx
4B24: 1A          ld   a,(de)		; read a sprite buffer byte
4B25: D9          exx
4B26: A4          and  h
4B27: B5          or   l			; combine read byte
4B28: D9          exx
4B29: 12          ld   (de),a		; write byte to sprite buffer after combining it
4B2A: 13          inc  de			; advance to next x position in sprite buffer
4B2B: 23          inc  hl			; advance to next x position in graphics
4B2C: 10 E6       djnz $4B14		; repeat for width

4B2E: E1          pop  hl
4B2F: 11 00 00    ld   de,$0000		; modified with current sprite width
4B32: 19          add  hl,de		; move to next sprite line
4B33: D1          pop  de			; get sprite buffer pointer
4B34: 0C          inc  c
4B35: 79          ld   a,c
4B36: FE 0A       cp   $0A			; if reaches 10, change source graphics data address, since it goes from drawing
4B38: 20 19       jr   nz,$4B53		;  a monk's head to drawing his robe
4B3A: FD 7E 0B    ld   a,(iy+$0b)	; if bit 7 is 1, jump (not a monk)
4B3D: CB 7F       bit  7,a
4B3F: 20 12       jr   nz,$4B53

4B41: 21 C8 48    ld   hl,$48C8		; point to monk robe positions table
4B44: 87          add  a,a
4B45: 85          add  a,l
4B46: 6F          ld   l,a
4B47: 8C          adc  a,h
4B48: 95          sub  l
4B49: 67          ld   h,a			; hl = hl + a
4B4A: 7E          ld   a,(hl)
4B4B: 23          inc  hl
4B4C: 66          ld   h,(hl)
4B4D: C6 00       add  a,$00		; instruction modified from outside (x distance from start of current sprite to start of original sprite)
4B4F: 6F          ld   l,a
4B50: 8C          adc  a,h
4B51: 95          sub  l
4B52: 67          ld   h,a			; modify source graphics data address to point to monk robe animation

4B53: 3E 00       ld   a,$00		; modified from outside (with expanded width of original sprite)
4B55: 83          add  a,e			; de = de + a (move to next sprite buffer line)
4B56: 5F          ld   e,a
4B57: 8A          adc  a,d
4B58: 93          sub  e
4B59: 57          ld   d,a
4B5A: D9          exx
4B5B: 10 B2       djnz $4B0F		; repeat for height lines
4B5D: C3 2E 4A    jp   $4A2E		; continue processing rest of stack sprites

; here it arrives if sprite has graphics data pointer = 0 (it's the light sprite)
4B60: DD E5       push ix
4B62: 21 E8 48    ld   hl,$48E8		; hl points to light fill pattern table
4B65: D5          push de
4B66: D9          exx
4B67: E1          pop  hl			; get original sprite buffer address
4B68: 5D          ld   e,l			; de = hl
4B69: 54          ld   d,h
4B6A: 01 00 00    ld   bc,$0000		; this is modified from outside with 0x00ef or 0x009f
4B6D: 36 FF       ld   (hl),$FF
4B6F: 13          inc  de
4B70: ED B0       ldir				; fill one tile or tile and a half with black (upper part of light sprite)
4B72: D5          push de
4B73: DD E1       pop  ix			; ix points to what's after tile buffer
4B75: 11 50 00    ld   de,$0050		; de = 80 (half tile offset)
4B78: D9          exx
4B79: 06 0F       ld   b,$0F		; 15 times fill with 4x4 blocks

4B7B: DD E5       push ix
4B7D: 7E          ld   a,(hl)		; read a value from table
4B7E: D9          exx
4B7F: 67          ld   h,a
4B80: D9          exx
4B81: 23          inc  hl
4B82: 7E          ld   a,(hl)		; read another value from table
4B83: 23          inc  hl
4B84: D9          exx
4B85: 6F          ld   l,a			; hl = table value

4B86: 3E FF       ld   a,$FF		; black fill
4B88: 06 00       ld   b,$00		; modified from outside with adso sprite x position within tile
4B8A: 04          inc  b
4B8B: 05          dec  b
4B8C: 28 10       jr   z,$4B9E		; complete the 16 pixel part that extends left according to x position expansion
4B8E: DD 77 00    ld   (ix+$00),a
4B91: DD 77 14    ld   (ix+$14),a
4B94: DD 77 28    ld   (ix+$28),a
4B97: DD 77 3C    ld   (ix+$3c),a
4B9A: DD 23       inc  ix
4B9C: 10 F0       djnz $4B8E		; complete left side fill

; hl contains value read from table
4B9E: 06 10       ld   b,$10		; 16 bits
4BA0: 29          add  hl,hl		; 0x00 or 0x29 (if adso graphics are flipped or not)
4BA1: 29          add  hl,hl
4BA2: 38 0C       jr   c,$4BB0		; if most significant bit is 1, don't fill 4x4 block with black
4BA4: DD 77 00    ld   (ix+$00),a	; fill a 4x4 block with black
4BA7: DD 77 14    ld   (ix+$14),a
4BAA: DD 77 28    ld   (ix+$28),a
4BAD: DD 77 3C    ld   (ix+$3c),a
4BB0: DD 23       inc  ix
4BB2: 10 ED       djnz $4BA1		; complete 16 bits

4BB4: 06 00       ld   b,$00		; modified from outside with 4 - (adso sprite x position & 0x03)
4BB6: DD 77 00    ld   (ix+$00),a	; complete the 16 pixel part that extends right according to x position expansion
4BB9: DD 77 14    ld   (ix+$14),a
4BBC: DD 77 28    ld   (ix+$28),a
4BBF: DD 77 3C    ld   (ix+$3c),a
4BC2: DD 23       inc  ix
4BC4: 10 F0       djnz $4BB6		; complete right side

4BC6: DD E1       pop  ix
4BC8: DD 19       add  ix,de		; move to next half tile
4BCA: D9          exx
4BCB: 10 AE       djnz $4B7B		; repeat until completing 15 blocks of 4 pixels high

4BCD: DD E5       push ix
4BCF: E1          pop  hl
4BD0: 01 00 00    ld   bc,$0000		; this is modified from outside with 0x00ef or 0x009f
4BD3: 5D          ld   e,l
4BD4: 54          ld   d,h			; de = hl
4BD5: 13          inc  de
4BD6: 36 FF       ld   (hl),$FF		; fill one tile or tile and a half with black (lower part of light sprite)
4BD8: ED B0       ldir
4BDA: DD E1       pop  ix
4BDC: C3 2E 4A    jp   $4A2E		; continue processing rest of stack sprites

; here it arrives once it has processed all sprites that needed redrawing (or if there was no more space in sprite buffer)
4BDF: DD 21 17 2E ld   ix,$2E17			; ix points to sprites
4BE3: DD 7E 00    ld   a,(ix+$00)
4BE6: FE FF       cp   $FF
4BE8: 28 29       jr   z,$4C13			; when it finds the last one, exit
4BEA: FE FE       cp   $FE
4BEC: 28 1D       jr   z,$4C0B			; if inactive, go to next
4BEE: E6 40       and  $40
4BF0: 28 19       jr   z,$4C0B			; if bit 6 is not set, go to next
; here it arrives if current sprite has bit 6 set to 1 (sprite has been processed)
4BF2: CD 1A 4C    call $4C1A			; dump sprite buffer to screen, clipping what's not visible
4BF5: DD CB 00 BE res  7,(ix+$00)		; clear bit 6 and 7 of byte 0
4BF9: DD CB 00 B6 res  6,(ix+$00)
4BFD: DD CB 05 7E bit  7,(ix+$05)
4C01: 28 08       jr   z,$4C0B			; if bit 7 of byte 5 is 0, go to next sprite
4C03: DD CB 05 BE res  7,(ix+$05)		; otherwise, clear it
4C07: DD 36 00 FE ld   (ix+$00),$FE		; mark sprite as inactive
4C0B: 01 14 00    ld   bc,$0014			; go to next sprite
4C0E: DD 09       add  ix,bc
4C10: C3 E3 4B    jp   $4BE3

4C13: ED 7B 0A 49 ld   sp,($490A)		; retrieve original stack value
4C17: C3 14 49    jp   $4914			; jump to process remaining objects

; dump sprite buffer to screen
    1→4C1A: AF          xor  a
    2→4C1B: 32 A0 4C    ld   ($4CA0),a
    3→4C1E: DD 66 0D    ld   h,(ix+$0d)		; h = y position of the tile where the sprite starts
    4→4C21: DD 46 0F    ld   b,(ix+$0f)		; b = final height of the sprite (in pixels)
    5→4C24: D9          exx
    6→4C25: 11 00 00    ld   de,$0000
    7→4C28: D9          exx
    8→4C29: 7C          ld   a,h
    9→4C2A: FE C8       cp   $C8				; if y coordinate >= 200 (not visible on screen), exit
   10→4C2C: D0          ret  nc
   11→4C2D: D6 28       sub  $28
   12→4C2F: 67          ld   h,a				; adjust y coordinate
   13→4C30: 30 13       jr   nc,$4C45			; if y coordinate > 40 (visible on screen), jump
   14→4C32: ED 44       neg
   15→4C34: B8          cp   b				; if distance from the point where sprite begins to first visible point >= sprite height, exit (not visible)
   16→4C35: D0          ret  nc
   17→4C36: D9          exx
   18→4C37: 26 00       ld   h,$00
   19→4C39: DD 6E 0E    ld   l,(ix+$0e)		; l = final width of the sprite (in bytes)
   20→4C3C: CD 24 4D    call $4D24			; de = a*hl (skip the non-visible sprite lines)
   21→4C3F: D9          exx
   22→4C40: 78          ld   a,b
   23→4C41: 84          add  a,h				; modify sprite height due to clipping
   24→4C42: 47          ld   b,a
   25→4C43: 26 00       ld   h,$00			; sprite starts at y = 0

   27→4C45: D9          exx
   28→4C46: DD 6E 10    ld   l,(ix+$10)		; hl = address of sprite buffer assigned to this sprite
   29→4C49: DD 66 11    ld   h,(ix+$11)
   30→4C4C: 19          add  hl,de			; skip the bytes not visible in y
   31→4C4D: D9          exx
   32→4C4E: DD 6E 0C    ld   l,(ix+$0c)		; l = x position of the tile where the sprite starts (in bytes)
   33→4C51: DD 4E 0E    ld   c,(ix+$0e)		; c = final width of the sprite (in bytes)
   34→4C54: 7D          ld   a,l
   35→4C55: FE 48       cp   $48				; if x position >= (32 + 256 pixels)
   36→4C57: D0          ret  nc
   37→4C58: D6 08       sub  $08				; adjust x coordinate
   38→4C5A: 6F          ld   l,a
   39→4C5B: 30 15       jr   nc,$4C72			; if x position >= 32 pixels, jump
   40→4C5D: ED 44       neg
   41→4C5F: DD BE 0E    cp   (ix+$0e)			; if distance from the point where sprite begins to first visible point >= sprite width, exit (not visible)
   42→4C62: D0          ret  nc
   43→4C63: 32 A0 4C    ld   ($4CA0),a		; modify an instruction with the x distance
   44→4C66: D9          exx
   45→4C67: 85          add  a,l				; hl = hl + a (skip the clipped pixels)
   46→4C68: 6F          ld   l,a
   47→4C69: 8C          adc  a,h
   48→4C6A: 95          sub  l
   49→4C6B: 67          ld   h,a
   50→4C6C: D9          exx
   51→4C6D: 79          ld   a,c				; modify width to draw
   52→4C6E: 85          add  a,l
   53→4C6F: 4F          ld   c,a
   54→4C70: 2E 00       ld   l,$00			; sprite starts at x = 0

   56→4C72: 79          ld   a,c				; a = sprite width to draw
   57→4C73: 85          add  a,l				; l = initial x coordinate
   58→4C74: D6 40       sub  $40				; check if sprite is wider than screen (64*4 = 256)
   59→4C76: 38 07       jr   c,$4C7F
   60→4C78: 32 A0 4C    ld   ($4CA0),a		; modify an instruction
   61→4C7B: ED 44       neg
   62→4C7D: 81          add  a,c
   63→4C7E: 4F          ld   c,a				; set new width for sprite

   65→4C7F: 79          ld   a,c
   66→4C80: 32 9B 4C    ld   ($4C9B),a		; modify an instruction

   68→4C83: 78          ld   a,b				; a = sprite height to draw
   69→4C84: 4F          ld   c,a
   70→4C85: 84          add  a,h				; h = initial y coordinate
   71→4C86: D6 A0       sub  $A0				; check if sprite is taller than screen (160)
   72→4C88: 38 04       jr   c,$4C8E
   73→4C8A: ED 44       neg
   74→4C8C: 81          add  a,c
   75→4C8D: 4F          ld   c,a				; update height to draw

   77→4C8E: 79          ld   a,c
   78→4C8F: 32 96 4C    ld   ($4C96),a	; modify an instruction
   79→4C92: CD 42 3C    call $3C42		; given hl (Y,X coordinates), calculate corresponding screen offset
   80→									; 32 pixels to the right are added to the calculated value
   81→4C95: 06 00       ld   b,$00		; instruction modified from outside (with height to draw)
   82→4C97: E5          push hl			;
   83→4C98: D9          exx
   84→4C99: D1          pop  de			; de = screen position to copy bytes to
   85→4C9A: 01 00 00    ld   bc,$0000		; instruction modified from outside (with width to draw)
   86→4C9D: ED B0       ldir				; copy width bytes from sprite buffer to screen
   87→4C9F: 3E 00       ld   a,$00		; instruction modified from outside (with x distance of non-visible part)
   88→4CA1: 85          add  a,l			; hl = hl + a
   89→4CA2: 6F          ld   l,a
   90→4CA3: 8C          adc  a,h
   91→4CA4: 95          sub  l
   92→4CA5: 67          ld   h,a
   93→4CA6: D9          exx

   95→; returns in hl the address of the next screen line
   96→4CA7: 7C          ld   a,h
   97→4CA8: C6 08       add  a,$08
   98→4CAA: 67          ld   h,a			; move to next bank
   99→4CAB: E6 38       and  $38
  100→4CAD: 20 0D       jr   nz,$4CBC
  101→4CAF: 7C          ld   a,h
  102→4CB0: D6 08       sub  $08			; return to previous bank
  103→4CB2: E6 C7       and  $C7
  104→4CB4: 67          ld   h,a
  105→4CB5: 3E 50       ld   a,$50		; each line occupies 0x50 bytes
  106→4CB7: 85          add  a,l			; hl = hl + a
  107→4CB8: 6F          ld   l,a
  108→4CB9: 8C          adc  a,h
  109→4CBA: 95          sub  l
  110→4CBB: 67          ld   h,a

  112→4CBC: 10 D9       djnz $4C97		; repeat until finished
  113→4CBE: C9          ret

  115→; check minimum sprite dimensions (to erase old sprite) and update 0x2dd5 and 0x2dd7
  116→4CBF: 3A D5 2D    ld   a,($2DD5)	; get initial x position of the tile where sprite starts (Xtile)
  117→4CC2: 95          sub  l
  118→4CC3: 38 1E       jr   c,$4CE3		; if Xtile < X2, jump
  119→4CC5: 4F          ld   c,a			; c = Xtile - X2
  120→4CC6: 3A D7 2D    ld   a,($2DD7)	; get expanded sprite width
  121→4CC9: 81          add  a,c			; add the difference
  122→4CCA: BB          cp   e			; compare with minimum sprite width
  123→4CCB: 38 01       jr   c,$4CCE		; if expanded width is less than minimum, jump
  124→4CCD: 5F          ld   e,a			; otherwise, e = expanded width + Xtile - Xspr (take largest sprite width)

  126→4CCE: 7D          ld   a,l
  127→4CCF: E6 03       and  $03
  128→4CD1: 4F          ld   c,a			; c = x position within current tile
  129→4CD2: 7D          ld   a,l
  130→4CD3: E6 FC       and  $FC
  131→4CD5: 32 D5 2D    ld   ($2DD5),a	; update initial x position of the tile where sprite starts
  132→4CD8: 7B          ld   a,e			; get sprite width
  133→4CD9: 81          add  a,c
  134→4CDA: C6 03       add  a,$03
  135→4CDC: E6 FC       and  $FC			; round width to upper tile
  136→4CDE: 32 D7 2D    ld   ($2DD7),a	; update sprite width
  137→4CE1: 18 12       jr   $4CF5

  139→; arrives here if sprite x position > tile start x position
  140→4CE3: ED 44       neg				; a = difference in x position from tile to x2
  141→4CE5: 83          add  a,e			; add to sprite width the difference in x between sprite start and tile associated with sprite
  142→4CE6: 4F          ld   c,a
  143→4CE7: 3A D7 2D    ld   a,($2DD7)	; a = expanded sprite width
  144→4CEA: B9          cp   c
  145→4CEB: 30 08       jr   nc,$4CF5		; if expanded sprite width >= minimum sprite width, check y values
  146→4CED: 79          ld   a,c			; otherwise, expand minimum sprite width
  147→4CEE: C6 03       add  a,$03
  148→4CF0: E6 FC       and  $FC			; round width to upper tile
  149→4CF2: 32 D7 2D    ld   ($2DD7),a	; save sprite width

  151→; now do the same for y
  152→4CF5: 3A D6 2D    ld   a,($2DD6)	; get initial y position of the tile where sprite starts (Ytile)
  153→4CF8: 94          sub  h
  154→4CF9: 38 1D       jr   c,$4D18		; if Ytile < Y2, jump
  155→4CFB: 4F          ld   c,a			; c = Ytile - Y2
  156→4CFC: 3A D8 2D    ld   a,($2DD8)	; get expanded sprite height
  157→4CFF: 81          add  a,c
  158→4D00: BA          cp   d			; check with minimum height
  159→4D01: 38 01       jr   c,$4D04		; if expanded height is less than minimum, jump
  160→4D03: 57          ld   d,a

  162→4D04: 7C          ld   a,h
  163→4D05: E6 07       and  $07
  164→4D07: 4F          ld   c,a			; c = y position within current tile
  165→4D08: 7C          ld   a,h
  166→4D09: E6 F8       and  $F8
  167→4D0B: 32 D6 2D    ld   ($2DD6),a	; update initial y position of the tile where sprite starts
  168→4D0E: 7A          ld   a,d			; get sprite height
  169→4D0F: 81          add  a,c
  170→4D10: C6 07       add  a,$07
  171→4D12: E6 F8       and  $F8			; round height to upper tile
  172→4D14: 32 D8 2D    ld   ($2DD8),a	; update sprite height
  173→4D17: C9          ret

  175→4D18: ED 44       neg				; a = |Ytile - Y2|
  176→4D1A: 82          add  a,d			; subtract from sprite height what protrudes from tile start in y
  177→4D1B: 4F          ld   c,a
  178→4D1C: 3A D8 2D    ld   a,($2DD8)	; a = sprite height
  179→4D1F: B9          cp   c
  180→4D20: D0          ret  nc			; if sprite height >= minimum height, exit
  181→4D21: 79          ld   a,c
  182→4D22: 18 EC       jr   $4D10		; round height to upper tile and update sprite height

  184→; multiply a by hl and return result in de
  185→4D24: 06 08       ld   b,$08		; 8 bits at most
  186→4D26: 11 00 00    ld   de,$0000		; result = 0
  187→4D29: CB 3F       srl  a
  188→4D2B: 30 04       jr   nc,$4D31		; if least significant bit of number is 0, jump
  189→4D2D: E5          push hl
  190→4D2E: 19          add  hl,de		; if bit was 1, add
  191→4D2F: EB          ex   de,hl
  192→4D30: E1          pop  hl
  193→4D31: 29          add  hl,hl		; hl = hl*2
  194→4D32: 10 F5       djnz $4D29		; repeat for remaining bits
  195→4D34: C9          ret

  197→; returns in hl the initial position of the tile where sprite starts (h = initial Y pos in pixels, l = initial X pos in bytes)
  198→; returns in de the sprite dimensions expanded to cover all tiles where sprite will be drawn
  199→;  in hl the initial position is passed (h = Y pos in pixels, l = X pos in bytes)
  200→;  in de the sprite dimensions are passed (d = height in pixels, e = width in bytes)
  201→4D35: 7C          ld   a,h
  202→4D36: E6 07       and  $07
  203→4D38: 4F          ld   c,a		; c = h & 0x07 (Y pos within current tile (in pixels))
  204→4D39: 7C          ld   a,h
  205→4D3A: E6 F8       and  $F8
  206→4D3C: 67          ld   h,a		; h = h & 0xf8 (current tile position in Y (in pixels))
  207→4D3D: 7D          ld   a,l
  208→4D3E: E6 03       and  $03
  209→4D40: 47          ld   b,a		; b = l & 0x03 (X pos within current tile (in bytes))
  210→4D41: 7D          ld   a,l
  211→4D42: E6 FC       and  $FC
  212→4D44: 6F          ld   l,a		; l = l & 0xfc (current tile position in X (in bytes))
  213→4D45: 7A          ld   a,d
  214→4D46: 81          add  a,c
  215→4D47: C6 07       add  a,$07
  216→4D49: E6 F8       and  $F8
  217→4D4B: 57          ld   d,a		; calculate object height to cover all tiles where it will be drawn (d = (d + (h & 0x07) + 7) & 0xf8)
  218→4D4C: 7B          ld   a,e
  219→4D4D: 80          add  a,b
  220→4D4E: C6 03       add  a,$03
  221→4D50: E6 FC       and  $FC
  222→4D52: 5F          ld   e,a		; calculate object width to cover all tiles where it will be drawn (e = (d + (l & 0x03) + 3) & 0xfc)
  223→4D53: C9          ret


  226→; given l and e, and h and d, which are initial positions and lengths of original and current sprites, check if current sprite can
  227→;  be seen in original sprite area. If it can be seen, clip it. Otherwise, jump to next current sprite
  228→; in a returns the length to draw of current sprite for the passed coordinate
  229→; in h returns the distance from current sprite start to original sprite start
  230→; in l returns the distance from original sprite start to current sprite start
  231→4D54: 7D          ld   a,l		; a = initial position of original sprite
  232→4D55: 94          sub  h		; a = distance from original sprite to current sprite
  233→4D56: 28 11       jr   z,$4D69	; if original sprite starts at same point as current sprite, jump
  234→4D58: 38 17       jr   c,$4D71	; if original sprite starts before current sprite, jump

  236→; if it arrives here, current sprite starts before original sprite
  237→4D5A: BA          cp   d		; if distance between sprites is >= current sprite width, current sprite is not visible
  238→4D5B: 30 24       jr   nc,$4D81	;  in original sprite area, so jump to process next sprite

  240→4D5D: 67          ld   h,a		; h = distance from current sprite start to original sprite start
  241→4D5E: 2E 00       ld   l,$00
  242→4D60: 83          add  a,e		; if distance between sprites + original sprite length >= d, jump
  243→4D61: BA          cp   d
  244→4D62: 30 02       jr   nc,$4D66
  245→4D64: 7B          ld   a,e		; otherwise, original sprite is inside current sprite, so draw only original sprite length
  246→4D65: C9          ret
  247→4D66: 7A          ld   a,d		; since original sprite is not completely inside current sprite, draw only the part of
  248→4D67: 94          sub  h		;  current sprite that overlaps with original sprite
  249→4D68: C9          ret

  251→; arrives here if current sprite starts at same point as original
  252→4D69: 21 00 00    ld   hl,$0000
  253→4D6C: 7B          ld   a,e		; a = expanded sprite width (in bytes)
  254→4D6D: BA          cp   d		; compare expanded width with original width
  255→4D6E: D8          ret  c		; if expanded original sprite width is < current sprite width, exit returning original width
  256→4D6F: 7A          ld   a,d		; otherwise, return current sprite width
  257→4D70: C9          ret

  259→4D71: 26 00       ld   h,$00
  260→4D73: ED 44       neg			; a = distance between initial position of original and current sprite
  261→4D75: 6F          ld   l,a
  262→4D76: BB          cp   e		; if distance between origin of 2 sprites is >= expanded original sprite width, jump to next sprite
  263→4D77: 30 08       jr   nc,$4D81
  264→4D79: ED 44       neg
  265→4D7B: 83          add  a,e		; otherwise, save in a the length of visible part of current sprite in original sprite
  266→4D7C: BA          cp   d		; if that length is <= current sprite length, exit
  267→4D7D: D8          ret  c
  268→4D7E: C8          ret  z
  269→4D7F: 7A          ld   a,d		; otherwise, modify length to draw of current sprite
  270→4D80: C9          ret

  272→4D81: E1          pop  hl		; remove sprite from stack
  273→4D82: C3 2E 4A    jp   $4A2E	; continue processing remaining sprites from stack

  275→4D85: C9          ret				; this instruction is changed from outside and can be changed to nop
  276→4D86: CD A5 37    call $37A5		; returns associated tile buffer address in hl
  277→4D89: D8          ret  c
  278→4D8A: DD CB 00 BE res  7,(ix+$00)	; clear most significant bit of tile buffer
  279→4D8E: C9          ret

  281→4D8F: E1          pop  hl
  282→4D90: 11 80 8D    ld   de,$8D80
  283→4D93: A7          and  a
  284→4D94: ED 52       sbc  hl,de
  285→4D96: D8          ret  c
  286→4D97: 11 80 07    ld   de,$0780
  287→4D9A: ED 52       sbc  hl,de
  288→4D9C: 3F          ccf				; complement carry flag
  289→4D9D: C9          ret

  291→; copy to sprite buffer the tiles that are between initial and final depth
  292→4D9E: 2A D9 4D    ld   hl,($4DD9)	; get upper depth limit from previous iteration and place it as lower depth
  293→4DA1: 22 DC 4D    ld   ($4DDC),hl	;  limit for this iteration
  294→4DA4: 0C          inc  c
  295→4DA5: 04          inc  b
  296→4DA6: ED 43 D9 4D ld   ($4DD9),bc	; place upper depth limit for this iteration
  297→4DAA: D9          exx
  298→4DAB: ED 5B FA 4A ld   de,($4AFA)	; de = assigned sprite buffer address
  299→4DAF: D9          exx

  301→4DB0: DD 2A 95 30 ld   ix,($3095)	; ix = tile buffer position
  302→4DB4: ED 4B D7 2D ld   bc,($2DD7)	; get sprite width and height
  303→4DB8: CB 38       srl  b			; b = b/8 (number of tiles sprite occupies in y)
  304→4DBA: CB 38       srl  b
  305→4DBC: CB 38       srl  b
  306→4DBE: CB 39       srl  c			; c = c/4 (number of tiles sprite occupies in x)
  307→4DC0: CB 39       srl  c

  309→4DC2: C5          push bc			; save loop counters
  310→4DC3: DD E5       push ix			; save current position in tile buffer
  311→4DC5: D9          exx
  312→4DC6: D5          push de			; save current position in sprite buffer
  313→4DC7: D9          exx
  314→4DC8: 41          ld   b,c			; b = number of sprite tiles in x
  315→4DC9: 0E 02       ld   c,$02		; each tile has 2 priorities
  316→4DCB: 21 E6 4D    ld   hl,$4DE6
  317→4DCE: 22 E4 4D    ld   ($4DE4),hl	; change a jump

  319→4DD1: DD 7E 02    ld   a,(ix+$02)	; read tile number from current tile buffer entry
  320→4DD4: A7          and  a
  321→4DD5: 28 44       jr   z,$4E1B		; if there's no tile, advance to next tile or next priority
  322→4DD7: D9          exx
  323→4DD8: 01 00 00    ld   bc,$0000		; instruction modified from outside with upper depth limit
  324→4DDB: 21 00 00    ld   hl,$0000		; instruction modified from outside with lower depth limit
  325→4DDE: DD 7E 00    ld   a,(ix+$00)	; read x depth of current tile
  326→4DE1: CB 7F       bit  7,a			; if in this call hasn't drawn in this tile buffer position, check if tile in this
  327→									; depth layer needs to be drawn. If it has been drawn and tile in this layer was drawn
  328→									; in another previous iteration, combine it without checking depth
  329→4DE3: C2 E6 4D    jp   nz,$4DE6		; instruction modified from outside (jump changed from outside)
  330→4DE6: BD          cp   l			; compare tile x depth with minimum x depth
  331→4DE7: DD 7E 01    ld   a,(ix+$01)	; read y depth of current tile
  332→4DEA: 30 05       jr   nc,$4DF1		; if tile x depth >= minimum x depth, jump
  333→4DEC: BC          cp   h
  334→4DED: 30 02       jr   nc,$4DF1		; if tile y depth >= minimum y depth, jump
  335→4DEF: 18 29       jr   $4E1A		; advance to next tile or next priority (tile has less depth than minimum)

  337→4DF1: B8          cp   b			; if tile y depth >= sprite y position
  338→4DF2: 30 26       jr   nc,$4E1A		;  if sprite is hidden by tile, advance to next tile or next priority
  339→4DF4: DD 7E 00    ld   a,(ix+$00)	; read x depth of current tile
  340→4DF7: B9          cp   c			; if tile x depth >= sprite x position
  341→4DF8: 30 20       jr   nc,$4E1A		;  if sprite is hidden by tile, advance to next tile or next priority

  343→; arrives here if tile has greater depth than minimum and less depth than sprite
  344→4DFA: DD CB 00 7E bit  7,(ix+$00)
  345→4DFE: 20 1A       jr   nz,$4E1A		; if current tile has already been drawn, advance to next tile or next priority
  346→4E00: 21 11 4E    ld   hl,$4E11
  347→4E03: 22 E4 4D    ld   ($4DE4),hl	; modify a jump to indicate that in this call has drawn some tile for this tile buffer position
  348→4E06: D5          push de
  349→4E07: CD A5 37    call $37A5		; if ix is inside tile buffer, cf = 0
  350→4E0A: D1          pop  de
  351→4E0B: 38 04       jr   c,$4E11		; if current tile is not inside tile buffer, jump
  352→4E0D: DD CB 00 FE set  7,(ix+$00)	; indicate this tile has been processed

  354→4E11: D5          push de
  355→4E12: D9          exx
  356→4E13: C5          push bc
  357→4E14: CD 49 4E    call $4E49		; combine tile from ix+2 with what's in current sprite buffer position
  358→4E17: C1          pop  bc
  359→4E18: D9          exx
  360→4E19: D1          pop  de

  362→4E1A: D9          exx
  363→4E1B: CD 85 4D    call $4D85		; ret (if hasn't finished processing sprites from stack) or clear bit 7 of (ix+0) from tile buffer (if it's a valid tile buffer position)
  364→4E1E: DD 23       inc  ix			; move to higher priority tile in tile buffer
  365→4E20: DD 23       inc  ix
  366→4E22: DD 23       inc  ix
  367→4E24: 0D          dec  c
  368→4E25: 20 AA       jr   nz,$4DD1		; repeat until tile buffer entry priorities are completed

  370→4E27: D9          exx
  371→4E28: 13          inc  de			; move to next tile x position in sprite buffer
  372→4E2A: 13          inc  de
  373→4E2B: 13          inc  de
  374→4E2C: 13          inc  de
  375→4E2D: D9          exx
  376→4E2E: 10 9A       djnz $4DC9		; repeat while not finished in x
  377→4E2F: D9          exx

  379→4E30: D1          pop  de
  380→4E31: 2A D7 2D    ld   hl,($2DD7)
  381→4E32: 26 00       ld   h,$00		; hl = sprite width
  382→4E36: 29          add  hl,hl
  383→4E37: 29          add  hl,hl
  384→4E38: 29          add  hl,hl		; hl = sprite width*8
  385→4E39: 19          add  hl,de		; move to next tile y position in sprite buffer
  386→4E3A: EB          ex   de,hl
  387→4E3B: D9          exx
  388→4E3C: DD E1       pop  ix			; recover tile buffer position
  389→4E3E: 01 60 00    ld   bc,$0060
  390→4E41: DD 09       add  ix,bc		; move to next tile buffer line
  391→4E43: C1          pop  bc
  392→4E44: 05          dec  b			; repeat until tiles in y are finished
  393→4E45: C2 C2 4D    jp   nz,$4DC2
  394→4E48: C9          ret

  396→; enters here with ix pointing to some tile buffer entry and de pointing to some sprite buffer position
  397→; combine tile from current ix entry into current sprite buffer position
  398→4E49: 26 00       ld   h,$00
  399→4E4B: DD 6E 02    ld   l,(ix+$02)	; hl = tile number of current entry
  400→4E4E: 4D          ld   c,l			; c = tile number of current entry
  401→4E4F: 29          add  hl,hl
  402→4E50: 29          add  hl,hl
  403→4E51: 29          add  hl,hl
  404→4E52: 29          add  hl,hl
  405→4E53: 29          add  hl,hl		; hl = hl*32 (each tile occupies 32 bytes)
  406→4E54: 3E 6D       ld   a,$6D		; tiles graphics that form screens start at 0x6d00
  407→4E56: 84          add  a,h
  408→4E57: 67          ld   h,a			; hl = pointer to corresponding tile graphic data

  410→4E58: 79          ld   a,c
  411→4E59: FE 0B       cp   $0B			; if graphic is less than 0x0b (graphics without transparency), jump (simpler case)
  412→4E5B: 3A D7 2D    ld   a,($2DD7)	; a = sprite x width
  413→4E5E: 38 32       jr   c,$4E92
  414→4E60: D6 04       sub  $04			; x width = x width - 4
  415→4E62: 32 87 4E    ld   ($4E87),a	: modify an instruction
  416→4E65: DD CB 02 7E bit  7,(ix+$02)	; check which table to use according to tile number
  417→4E69: D9          exx
  418→4E6A: 26 9D       ld   h,$9D		; tables 0 and 1
  419→4E6C: 28 02       jr   z,$4E70
  420→4E6E: 26 9F       ld   h,$9F		; tables 2 and 3
  421→4E70: D9          exx
  422→4E71: 0E 08       ld   c,$08		; c = 8 pixels high
  423→4E73: 06 04       ld   b,$04		; b = 4 bytes wide (16 pixels)
  424→4E75: 7E          ld   a,(hl)		; get a byte from graphic
  425→4E76: D9          exx
  426→4E77: 6F          ld   l,a			; index into ands and ors tables with graphic byte
  427→4E78: 4E          ld   c,(hl)		; get or value
  428→4E79: 24          inc  h
  429→4E7A: 46          ld   b,(hl)		; get and value
  430→4E7B: 25          dec  h
  431→4E7C: 1A          ld   a,(de)		; get a value from sprite buffer
  432→4E7D: A0          and  b			; apply value to masks
  433→4E7E: B1          or   c
  434→4E7F: 12          ld   (de),a		; write value obtained combining background with sprite
  435→4E80: 13          inc  de			; advance to next buffer position
  436→4E81: D9          exx
  437→4E82: 23          inc  hl			; advance to next graphic byte
  438→4E83: 10 F0       djnz $4E75
  439→4E85: D9          exx
  440→4E86: 3E 00       ld   a,$00		; instruction modified from outside with width - 4
  441→4E88: 83          add  a,e			; de = de + a (move to next sprite line)
  442→4E89: 5F          ld   e,a
  443→4E8A: 8A          adc  a,d
  444→4E8B: 93          sub  e
  445→4E8C: 57          ld   d,a
  446→4E8D: D9          exx
  447→4E8E: 0D          dec  c
  448→4E8F: 20 E2       jr   nz,$4E73		; repeat until tile height is completed
  449→4E91: C9          ret

  451→; arrives here if tile number was < 0x0b (graphics without transparency)
  452→4E92: D6 04       sub  $04			; x width = x width - 4
  453→4E94: 32 A8 4E    ld   ($4EA8),a	; modify an instruction
  454→4E97: E5          push hl
  455→4E98: D9          exx
  456→4E99: E1          pop  hl			; hl = graphic address
  457→4E9A: 01 04 08    ld   bc,$0804		; 8 pixels high, 4 bytes wide (16 pixels)
  458→4E9D: 0E 08       ld   c,$08		; this instruction has no purpose here (???)
  459→4E9F: ED A0       ldi				; copy 16 pixels from tile line to sprite buffer
  460→4EA1: ED A0       ldi
  461→4EA3: ED A0       ldi
  462→4EA5: ED A0       ldi
  463→4EA7: 3E 00       ld   a,$00		; instruction modified from outside (with width - 4)
  464→4EA9: 83          add  a,e			; de = de + a (move to next sprite line)
  465→4EAA: 5F          ld   e,a
  466→4EAB: 8A          adc  a,d
  467→4EAC: 93          sub  e
  468→4EAD: 57          ld   d,a
  469→4EAE: 10 ED       djnz $4E9D		; repeat for remaining tile lines
  470→4EB0: D9          exx
  471→4EB1: C9          ret
  472→; ----------------------------- end of sprite drawing ------------------------------

  474→; ------------------- tile buffer drawing code -----------------------------------

  476→; draw grid contents on screen from center outwards
  477→4EB2: 11 A4 C2    ld   de,$C2A4			; de = (144, 64)
  478→4EB5: DD 21 AA 90 ld   ix,$90AA			; ix = (7, 8)

  480→; modify some instructions
  481→4EB9: 3E 04       ld   a,$04			; initially draw 4 vertical positions downwards
  482→4EBB: 32 CC 4E    ld   ($4ECC),a
  483→4EBE: 3C          inc  a
  484→4EBF: 32 F3 4E    ld   ($4EF3),a		; initially draw 5 vertical positions upwards
  485→4EC2: 3E 01       ld   a,$01
  486→4EC4: 32 E1 4E    ld   ($4EE1),a		; initially draw 1 horizontal position to the right
  487→4EC7: 3C          inc  a
  488→4EC8: 32 05 4F    ld   ($4F05),a		; initially draw 2 horizontal positions to the left

  490→4ECB: 3E 14       ld   a,$14			; instruction modified from outside
  491→4ECD: FE 14       cp   $14				; if draws more than 20 vertical positions, exit
  492→4ECF: D0          ret  nc
  493→4ED0: 47          ld   b,a				; b = number of vertical positions to draw (downwards)
  494→4ED1: 3C          inc  a
  495→4ED2: 3C          inc  a
  496→4ED3: 32 CC 4E    ld   ($4ECC),a		; in next iteration will draw 2 more vertical positions downwards
  497→4ED6: 78          ld   a,b				; a = number of positions to draw
  498→4ED7: 01 60 00    ld   bc,$0060			; bc = size between grid lines
  499→4EDD: CD 18 4F    call $4F18			; draw a vertical grid positions in video memory
  500→4EE0: 3E 0F       ld   a,$0F			; instruction modified from outside

  502→4EE2: 47          ld   b,a
  503→4EE3: 3C          inc  a
  504→4EE4: 3C          inc  a
  505→4EE5: 32 E1 4E    ld   ($4EE1),a		; in next iteration will draw 2 more horizontal positions to the right
  506→4EE8: 78          ld   a,b				; a = number of horizontal positions to draw
  507→4EE9: 01 06 00    ld   bc,$0006			; bc = size between grid x positions
  508→4EEC: 21 04 00    ld   hl,$0004			; hl = size between each 16 pixels in video memory
  509→4EEF: CD 18 4F    call $4F18			; draw a horizontal grid positions in video memory

  511→4EF2: 3E 0F       ld   a,$0F			; instruction modified from outside
  512→4EF4: 47          ld   b,a
  513→4EF5: 3C          inc  a
  514→4EF6: 3C          inc  a
  515→4EF7: 32 F3 4E    ld   ($4EF3),a		; in next iteration will draw 2 more vertical positions upwards
  516→4EFA: 78          ld   a,b
  517→4EFB: 01 A0 FF    ld   bc,$FFA0			; bc = value to return to previous grid line
  518→4EFE: 21 B0 FF    ld   hl,$FFB0			; hl = value to return to previous screen line
  519→4F01: CD 18 4F    call $4F18			; draw a vertical grid positions in video memory
  520→4F04: 3E 0F       ld   a,$0F			; instruction modified from outside
  521→4F06: 47          ld   b,a
  522→4F07: 3C          inc  a
  523→4F08: 3C          inc  a
  524→4F09: 32 05 4F    ld   ($4F05),a		; in next iteration will draw 2 more horizontal positions to the left
  525→4F0C: 78          ld   a,b
  526→4F0D: 01 FA FF    ld   bc,$FFFA			; bc = value to return to previous grid x position
  527→4F10: 21 FC FF    ld   hl,$FFFC			; bc = value to return to previous screen x position
  528→4F13: CD 18 4F    call $4F18			; draw a horizontal grid positions in video memory
  529→4F16: 18 B3       jr   $4ECB			; repeat until finished

  531→; draw a horizontal or vertical grid positions in video memory
  532→; a = number of positions to draw
  533→; bc = size between grid positions
  534→; hl = size between positions in video memory
  535→; ix = position in buffer
  536→; de = position in video memory
  537→4F18: 22 35 4F    ld   ($4F35),hl		; fill some parameters
  538→4F1B: ED 43 30 4F ld   ($4F30),bc

  540→4F1F: 47          ld   b,a				; b = number of positions to draw

  542→4F20: C5          push bc
  543→4F21: DD 7E 02    ld   a,(ix+$02)		; read graphic number to draw (background)
  544→4F24: A7          and  a
  545→4F25: C4 3D 4F    call nz,$4F3D			; copy a 16x8 graphic to video memory (de), combining it with what was there
  546→4F28: DD 7E 05    ld   a,(ix+$05)		; read graphic number to draw (foreground)
  547→4F2B: A7          and  a
  548→4F2C: C4 3D 4F    call nz,$4F3D			; copy a 16x8 graphic to video memory (de), combining it with what was there

  550→4F2F: 01 00 00    ld   bc,$0000			; instruction modified from outside
  551→4F32: DD 09       add  ix,bc			; move to next screen position
  552→4F34: 21 00 00    ld   hl,$0000			; instruction modified from outside
  553→4F37: 19          add  hl,de			; move to next grid position
  554→4F38: EB          ex   de,hl
  555→4F39: C1          pop  bc
  556→4F3A: 10 E4       djnz $4F20			; repeat for remaining positions
  557→4F3C: C9          ret

  559→; copy graphic a (16x8) to video memory (de), combining it with what was there
  560→; a = bits 7-0: graphic number. Bit 7 = indicates which color serves as mask (2 or 1)
  561→; de = position in video memory
  562→4F3D: D5          push de
  563→4F3E: D9          exx				; exchange all registers
  564→4F3F: 26 00       ld   h,$00
  565→4F41: 6F          ld   l,a
  566→4F42: 29          add  hl,hl
  567→4F43: 29          add  hl,hl
  568→4F44: 29          add  hl,hl
  569→4F45: 29          add  hl,hl
  570→4F46: 29          add  hl,hl		; hl = graphic address (32*a)
  571→4F47: 4F          ld   c,a			; c = graphic number
  572→4F48: 3E 6D       ld   a,$6D		; abbey graphics start at 0x6d00
  573→4F4A: 84          add  a,h
  574→4F4B: 67          ld   h,a			; hl points to corresponding graphic
  575→4F4C: CB 79       bit  7,c
  576→4F4E: D9          exx				; exchange all registers
  577→4F4F: 26 9D       ld   h,$9D		; depending on bit 7 choose an AND and OR table
  578→4F51: 28 02       jr   z,$4F55		; if bit 7 is not set, jump
  579→4F53: 26 9F       ld   h,$9F
  580→4F55: D9          exx				; exchange all registers
  581→4F56: 0E 08       ld   c,$08		; 8 pixels high
  582→4F58: 06 04       ld   b,$04		; 4 bytes wide (16 pixels)

  584→4F5A: 7E          ld   a,(hl)		; read a byte from graphic
  585→4F5B: D9          exx				; exchange all registers
  586→4F5C: 6F          ld   l,a			; index into tables
  587→4F5D: 4E          ld   c,(hl)		; c = OR table value
  588→4F5E: 24          inc  h
  589→4F5F: 46          ld   b,(hl)		; b = AND table value
  590→4F60: 1A          ld   a,(de)		; a = read what's on screen
  591→4F61: A0          and  b			; combine graphic with what's on screen
  592→4F62: B1          or   c
  593→4F63: 12          ld   (de),a		; update screen
  594→4F64: 25          dec  h
  595→4F65: 13          inc  de			; advance to next x position (screen)
  596→4F66: D9          exx
  597→4F67: 23          inc  hl			; advance to next graphic byte
  598→4F68: 10 F0       djnz $4F5A		; finish line
  599→4F6A: D9          exx

4F6B: 3E FC       ld   a,$FC		; move to the next screen line
4F6D: 83          add  a,e
4F6E: 5F          ld   e,a
4F6F: 3E 07       ld   a,$07
4F71: 8A          adc  a,d
4F72: 57          ld   d,a
4F73: D9          exx
4F74: 0D          dec  c
4F75: 20 E1       jr   nz,$4F58		; repeat until the height is finished
4F77: D1          pop  de
4F78: C9          ret

4F79: 00          nop
  ld   a,$6D		; the abbey graphics are from 0x6d00 onwards
4F4A: 84          add  a,h
4F4B: 67          ld   h,a			; hl points to the corresponding graphic
4F4C: CB 79       bit  7,c
4F4E: D9          exx				; exchanges all registers
4F4F: 26 9D       ld   h,$9D		; depending on bit 7 choose an AND and OR table
4F51: 28 02       jr   z,$4F55		; if bit 7 is not set jump
4F53: 26 9F       ld   h,$9F
4F55: D9          exx				; exchanges all registers
4F56: 0E 08       ld   c,$08		; 8 pixels high
4F58: 06 04       ld   b,$04		; 4 bytes wide (16 pixels)

4F5A: 7E          ld   a,(hl)		; read a byte from the graphic
4F5B: D9          exx				; exchanges all registers
4F5C: 6F          ld   l,a			; index into the tables
4F5D: 4E          ld   c,(hl)		; c = OR table value
4F5E: 24          inc  h
4F5F: 46          ld   b,(hl)		; b = AND table value
4F60: 1A          ld   a,(de)		; a = read what's on screen
4F61: A0          and  b			; combine the graphic with what's on screen
4F62: B1          or   c
4F63: 12          ld   (de),a		; update the screen
4F64: 25          dec  h
4F65: 13          inc  de			; advance to the next x position (screen)
4F66: D9          exx
4F67: 23          inc  hl			; advance to the next graphic byte
4F68: 10 F0       djnz $4F5A		; finish the line
4F6A: D9          exx
4F6B: 3E FC       ld   a,$FC		; move to the next screen line
4F6D: 83          add  a,e
4F6E: 5F          ld   e,a
4F6F: 3E 07       ld   a,$07
4F71: 8A          adc  a,d
4F72: 57          ld   d,a
4F73: D9          exx
4F74: 0D          dec  c
4F75: 20 E1       jr   nz,$4F58		; repeat until the height is finished
4F77: D1          pop  de
4F78: C9          ret

4F79: 00          nop

; ------------------- end of tile buffer drawing -----------------------------------

; table of duration of the day stages for each day and period of the day
4F7A: 	00 00 00 00 00 00 00
	00 00 05 00 05 00 00
	00 00 05 00 05 00 00
	0F 00 00 00 05 00 00
	0F 00 05 00 00 00 00
	0F 00 05 00 05 00 00
	0F 00 00				; day 7 only has until terce because the game ends at that time of day

; table used to fill in the day number in the scoreboard
4FA7: 	00 02 00	; -I-
	00 02 02	; -II
	02 02 02	; III
	00 02 01  	; -IV
	00 01 00	; -V-
	00 01 02	; -VI
	01 02 02 	; VII

; table of the names of the times of day
4FBC: 	-NOCHE-
	-PRIMA-
	TERCIA-
	-SEXTA-
	-NONA--
	VISPERAS
	COMPLETAS

4FED: C9          ret

; prints the phrase that follows the call at the current screen position
4FEE: DD E1       pop  ix				; get the return address in ix
4FF0: DD 7E 00    ld   a,(ix+$00)		; read a byte from the return address
4FF3: DD 23       inc  ix				; advance the return address and put it on stack
4FF5: DD E5       push ix
4FF7: FE FF       cp   $FF
4FF9: C8          ret  z				; if it reads 0xff, exit
4FFA: E6 7F       and  $7F				; adjust the character between 0 and 127
4FFC: CD 13 3B    call $3B13			; print the character in a on the screen
4FFF: 18 ED       jr   $4FEE			; repeat until the phrase is finished

; clears the part of the scoreboard where phrases are shown
5001: 06 08       ld   b,$08			; 8 lines high
5003: 21 58 E6    ld   hl,$E658			; points to screen (96, 164)
5006: 0E 1F       ld   c,$1F
5008: C5          push bc
5009: E5          push hl
500A: 5D          ld   e,l				; de = hl
500B: 54          ld   d,h
500C: 13          inc  de
500D: 36 FF       ld   (hl),$FF
500F: 06 00       ld   b,$00
5011: ED B0       ldir					; repeat until filling 128 pixels of this line
5013: E1          pop  hl
5014: CD 4D 3A    call $3A4D			; move to the next screen line
5017: C1          pop  bc
5018: 10 EE       djnz $5008
501A: C9          ret

; puts a phrase on screen and starts its sound (if another phrase is displayed, it's interrupted)
; parameter = byte read after the address from which the routine was called
501B: F3          di
501C: AF          xor  a
501D: 32 A1 2D    ld   ($2DA1),a
5020: 32 A2 2D    ld   ($2DA2),a	; indicates that no voice is being played
5023: CD 01 50    call $5001		; clears the part of the scoreboard where phrases are shown

; puts a phrase on screen and starts its sound (as long as it's not putting one already)
; parameter = byte read after the address from which the routine was called
5026: E1          pop  hl			; return address = return address + 1
5027: 23          inc  hl
5028: E5          push hl
5029: 3A A1 2D    ld   a,($2DA1)	; read if there's a voice being played
502C: A7          and  a
502D: C0          ret  nz			; if a phrase is being played, exit

502E: F3          di
502F: 2B          dec  hl			; point to the parameter
5030: 11 59 56    ld   de,$5659		; point to the table of octaves and notes for the game phrases
5033: 7E          ld   a,(hl)		; read the parameter
5034: EB          ex   de,hl
5035: CD 2D 16    call $162D		; index into the table according to the parameter
5038: 7E          ld   a,(hl)		; read the note and octave of the voice and record it
5039: 32 B7 14    ld   ($14B7),a	; modify the note and octave of the voice of channel3
503C: EB          ex   de,hl
503D: 46          ld   b,(hl)		; read the parameter again
503E: 23          inc  hl
503F: 3E 01       ld   a,$01		; start playing the voice
5041: 32 A1 2D    ld   ($2DA1),a
5044: 32 A2 2D    ld   ($2DA2),a
5047: 32 A0 2D    ld   ($2DA0),a
504A: 21 00 BB    ld   hl,$BB00		; point to the phrases table
504D: 78          ld   a,b
504E: A7          and  a
504F: C4 5C 50    call nz,$505C		; advance to the phrase that will be said
5052: 22 9E 2D    ld   ($2D9E),hl	; save the pointer to the phrase
5055: AF          xor  a
5056: 32 9B 2D    ld   ($2D9B),a	; set to 0 the blank characters remaining to be output so that the phrase has fully appeared on screen
5059: 37          scf
505A: FB          ei
505B: C9          ret

; advance in the table advancing b entries (ending in 0xff)
505C: 7E          ld   a,(hl)
505D: 23          inc  hl
505E: FE FF       cp   $FF
5060: 20 FA       jr   nz,$505C
5062: 10 F8       djnz $505C
5064: C9          ret

; prints S:N or erases S:N depending on 0x3c99
5065: DD E5       push ix
5067: 21 1D A4    ld   hl,$A41D		; set position (116, 164)
506A: 22 97 2D    ld   ($2D97),hl
506D: 3A 99 3C    ld   a,($3C99)
5070: E6 01       and  $01
5072: 28 0A       jr   z,$507E
5074: CD EE 4F    call $4FEE		; prints the phrase that follows the call at the current screen position
	20 20 20 FF
	[3 spaces]
507B: DD E1       pop  ix
507D: C9          ret

507E: CD EE 4F    call $4FEE		; prints the phrase that follows the call at the current screen position
	53 3A 4E FF
	S : N
5085: DD E1       pop  ix
5087: C9          ret

; ---------------------------- code related to picking up/dropping objects ------------------------------------------

; plays a sound depending on a and c
5088: F5          push af
5089: C5          push bc
508A: A1          and  c
508B: F5          push af
508C: CC 2F 10    call z,$102F
508F: F1          pop  af
5090: C4 25 10    call nz,$1025
5093: C1          pop  bc
5094: F1          pop  af
5095: C9          ret

; checks if characters pick up or drop any object, and if it's a key, updates their permissions and if they can read the parchment, they read it
5096: DD 21 EC 2D ld   ix,$2DEC			; point to the table related to characters' objects
509A: DD 7E 03    ld   a,(ix+$03)		; read the objects we have
509D: 32 99 2D    ld   ($2D99),a		; save a copy of the objects we have
50A0: DD 7E 07    ld   a,(ix+$07)		; read something from adso and save it on stack
50A3: F5          push af
50A4: 3A F6 2D    ld   a,($2DF6)		; read adso's objects
50A7: F5          push af				; save adso's objects
50A8: CD F0 50    call $50F0			; check if characters pick up any object
50AB: CD 6D 52    call $526D			; check if any object is dropped
50AE: CD 41 52    call $5241			; update the doors that guillermo and adso can enter
50B1: 3A F6 2D    ld   a,($2DF6)		; get adso's objects
50B4: 4F          ld   c,a
50B5: F1          pop  af				; recover adso's original objects
50B6: A9          xor  c				; if adso's objects changed, play a sound
50B7: C4 88 50    call nz,$5088

50BA: 3A F3 2D    ld   a,($2DF3)		; read adso's other objects
50BD: 4F          ld   c,a
50BE: F1          pop  af				; read the other objects on entry from adso
50BF: A9          xor  c
50C0: C4 88 50    call nz,$5088			; if adso's objects changed, play a sound

50C3: 3A EF 2D    ld   a,($2DEF)		; get the objects that guillermo has
50C6: 4F          ld   c,a
50C7: 3A 99 2D    ld   a,($2D99)		; get the objects that guillermo had on entry
50CA: A9          xor  c
50CB: F5          push af
50CC: C5          push bc
50CD: C4 88 50    call nz,$5088			; if guillermo's objects changed, play a sound

50D0: E6 30       and  $30				; check if we picked up the glasses or the parchment
50D2: 28 08       jr   z,$50DC			;  if not, jump
50D4: 79          ld   a,c
50D5: E6 30       and  $30				; check if we have the glasses and the parchment
50D7: FE 30       cp   $30
50D9: CC 2E 56    call z,$562E			; if the roman number of the mirror room riddle hadn't been generated, generate it

50DC: C1          pop  bc
50DD: F1          pop  af				; if guillermo's objects changed
50DE: C4 DA 51    call nz,$51DA			; draw the objects indicated by a on the scoreboard

50E1: 21 08 30    ld   hl,$3008			; point to the object position data
50E4: 01 05 00    ld   bc,$0005
50E7: 3E FF       ld   a,$FF
50E9: BE          cp   (hl)
50EA: C8          ret  z				; if it passed the last entry, exit
50EB: CB 86       res  0,(hl)			; clear bit 0
50ED: 09          add  hl,bc
50EE: 18 F9       jr   $50E9

; check if characters pick up any object
; ix points to the table related to characters' objects
50F0: DD 7E 00    ld   a,(ix+$00)	; if passed the last character, exit
50F3: FE FF       cp   $FF
50F5: C8          ret  z

50F6: DD 35 06    dec  (ix+$06)
50F9: DD 7E 06    ld   a,(ix+$06)
50FC: FE FF       cp   $FF
50FE: C2 CC 51    jp   nz,$51CC		; if (ix+$06) was not 0 on entry, jump to next character (just picked up/dropped an object)
5101: DD 34 06    inc  (ix+$06)
5104: CD 4F 53    call $534F		; modify a routine with the character's position data and their orientation
5107: DD 7E 04    ld   a,(ix+$04)	; read the objects that can be picked up
510A: DD AE 00    xor  (ix+$00)		; remove from the list those we already have
510D: DD A6 04    and  (ix+$04)		; save the result
5110: 6F          ld   l,a			; h = bits indicating the objects we can pick up (2)
5111: DD 7E 05    ld   a,(ix+$05)	; read the mask of objects we can pick up
5114: DD AE 03    xor  (ix+$03)		; remove from the list those we already have
5117: DD A6 05    and  (ix+$05)
511A: 67          ld   h,a			; h = bits indicating the objects we can pick up
511B: DD 7E 00    ld   a,(ix+$00)
511E: E6 01       and  $01
5120: 32 54 51    ld   ($5154),a	; modify an instruction with bit 0 of (ix+00)

; arrive here with hl = mask of objects we can pick up
5123: DD E5       push ix
5125: D9          exx
5126: 21 00 80    ld   hl,$8000		; start checking with the object represented by bit 7 of hl
5129: D9          exx
512A: DD 21 1B 2F ld   ix,$2F1B		; ix points to object sprites
512E: FD 21 08 30 ld   iy,$3008		; ix points to object positions
5132: 29          add  hl,hl		; move the most significant bit to the carry flag
5133: E5          push hl
5134: D2 B1 51    jp   nc,$51B1		; if the bit was not 1, we can't pick up the object, so jump to next object

5137: FD 7E 00    ld   a,(iy+$00)	; check if the object is being picked up/dropped
513A: CB 47       bit  0,a
513C: C2 B1 51    jp   nz,$51B1		; if bit 0 is 1, jump to next object (the object is being picked up/dropped?)
513F: CB 77       bit  6,a
5141: C2 B1 51    jp   nz,$51B1		; if bit 6 is 1, jump to next object (is this bit used???)
5144: FD 66 03    ld   h,(iy+$03)	; hl = object position
5147: FD 6E 02    ld   l,(iy+$02)
514A: FD 7E 04    ld   a,(iy+$04)	; a = object height
514D: FD CB 00 7E bit  7,(iy+$00)	; if the object is not picked up, jump
5151: 28 13       jr   z,$5166

; if the object is picked up, in (iy+$02) and (iy+$03) the address of the character who has it is saved
5153: 3E 00       ld   a,$00		; instruction modified from outside with bit 1 of byte 0 of the character's objects entry
5155: A7          and  a			;  (which is 1 if objects can be taken from the character?)
5156: C2 B1 51    jp   nz,$51B1		; if objects can't be taken from the character, jump to next object
5159: E5          push hl
515A: 23          inc  hl
515B: 5E          ld   e,(hl)
515C: 23          inc  hl
515D: 56          ld   d,(hl)		; de = [hl]
515E: EB          ex   de,hl		; hl = address of data of the character who picked up the object
515F: 5E          ld   e,(hl)
5160: 23          inc  hl
5161: 56          ld   d,(hl)		; de = position of the character who picked up the object
5162: 23          inc  hl
5163: 7E          ld   a,(hl)		; a = height of the character who picked up the object
5164: EB          ex   de,hl		; hl = position of the character who picked up the object
5165: D1          pop  de

; arrive here with hl = object position or position of the character who has the object
5166: D6 00       sub  $00			; instruction modified with the character's height
5168: FE 05       cp   $05
516A: 30 45       jr   nc,$51B1		; if the height difference is > 5, jump to process next object
516C: 7D          ld   a,l			; a = object x position
516D: FE 00       cp   $00			; instruction modified with the character's x position + 2*x displacement according to orientation
516F: 20 40       jr   nz,$51B1		; if the character is not next to the object and looking at it in x, jump to process next object
5171: 7C          ld   a,h			; a = object y position
5172: FE 00       cp   $00			; instruction modified with the character's y position + 2*y displacement according to orientation
5174: 20 3B       jr   nz,$51B1		; if the character is not next to the object and looking at it in y, jump to process next object
5176: FD CB 00 7E bit  7,(iy+$00)	; if the object is not picked up by a character, jump
517A: 28 0D       jr   z,$5189

517C: 1A          ld   a,(de)
517D: D9          exx
517E: AD          xor  l			; remove the object being processed from the character
517F: D9          exx
5180: 12          ld   (de),a
5181: 13          inc  de
5182: 13          inc  de
5183: 13          inc  de
5184: 1A          ld   a,(de)
5185: D9          exx
5186: AC          xor  h			; remove the object being processed from the character
5187: D9          exx
5188: 12          ld   (de),a

5189: CD CE 2A    call $2ACE		; if the sprite is visible, indicate that it needs to be redrawn and indicate to go inactive after restoring the area it occupied
518C: E1          pop  hl			; recover hl (bits indicating which objects we need to try to pick up)
518D: D1          pop  de			; de = pointer to the character's object characteristics
518E: D5          push de
518F: DD E1       pop  ix
5191: FD 73 02    ld   (iy+$02),e	; save the address of the character's data who has the object where the object position was previously saved
5194: FD 72 03    ld   (iy+$03),d
5197: FD 36 00 81 ld   (iy+$00),$81	; indicate that the object has been picked up
519B: DD 36 06 10 ld   (ix+$06),$10	; initialize the counter
519F: D9          exx
51A0: DD 7E 00    ld   a,(ix+$00)
51A3: B5          or   l			; indicate that the character has the object
51A4: DD 77 00    ld   (ix+$00),a
51A7: DD 7E 03    ld   a,(ix+$03)
51AA: B4          or   h			; indicate that the character has the object
51AB: DD 77 03    ld   (ix+$03),a
51AE: D9          exx
51AF: 18 1B       jr   $51CC		; jump to next character

; arrive here to move to the next object
51B1: 01 05 00    ld   bc,$0005		; move to the next object entry
51B4: FD 09       add  iy,bc
51B6: 01 14 00    ld   bc,$0014		; move to the next object sprite
51B9: DD 09       add  ix,bc
51BB: D9          exx
51BC: CB 3C       srl  h			; test the next bit of hl
51BE: CB 1D       rr   l
51C0: D9          exx
51C1: E1          pop  hl
51C2: FD 7E 00    ld   a,(iy+$00)	; if not reached the last object, continue processing
51C5: FE FF       cp   $FF
51C7: C2 32 51    jp   nz,$5132

51CA: DD E1       pop  ix
51CC: 01 07 00    ld   bc,$0007		; point to the next character
51CF: DD 09       add  ix,bc
51D1: C3 F0 50    jp   $50F0		; continue processing objects for the next character

; draw the objects that guillermo has on the scoreboard
51D4: 3A EF 2D    ld   a,($2DEF)	; read the objects we have
51D7: 4F          ld   c,a
51D8: 3E FF       ld   a,$FF

; check if you have the objects passed in c (those indicated by mask a are checked), and if you have them they are drawn
51DA: 5F          ld   e,a			; e = 0xff (8 objects)
51DB: 51          ld   d,c			; d = objects we have
51DC: FD 21 08 30 ld   iy,$3008		; point to positions about the game objects
51E0: DD 21 1B 2F ld   ix,$2F1B		; point to object sprites (referenced by 0x3836) 0x2e17-0x2fe2
51E4: 21 F9 C6    ld   hl,$C6F9		; point to the video memory of the first slot (100, 176)
51E7: 06 06       ld   b,$06		; there are 6 slots to place objects
51E9: CB 22       sla  d			; put the most significant bit in the carry and save it
51EB: 08          ex   af,af'
51EC: 7B          ld   a,e			; if all objects have been processed, exit
51ED: A7          and  a
51EE: C8          ret  z

51EF: C5          push bc			; save the object slot counter
51F0: CB 23       sla  e			; advance the counter
51F2: E5          push hl			; save the original address
51F3: 30 14       jr   nc,$5209		; if the object is not checked, move to next object
51F5: 08          ex   af,af'
51F6: 38 27       jr   c,$521F		; if we have the object jump, otherwise clear the slot

51F8: 0E 0C       ld   c,$0C		; 12 pixels high
51FA: 06 04       ld   b,$04		; 16 pixels wide
51FC: E5          push hl			; save the current screen address
51FD: 36 00       ld   (hl),$00		; clear the current pixel
51FF: 23          inc  hl
5200: 10 FB       djnz $51FD
5202: E1          pop  hl			; recover the previous address
5203: CD 4D 3A    call $3A4D		; move to the next line
5206: 0D          dec  c			; continue clearing the slot
5207: 20 F1       jr   nz,$51FA

5209: E1          pop  hl			; recover the previous address
520A: 01 05 00    ld   bc,$0005
520D: 09          add  hl,bc		; move to the next slot
520E: FD 09       add  iy,bc		; advance the positions about the game objects
5210: 01 14 00    ld   bc,$0014
5213: DD 09       add  ix,bc		; advance to the next object characteristics entry
5215: C1          pop  bc			; recover the object counter
5216: 78          ld   a,b
5217: FE 04       cp   $04
5219: 20 01       jr   nz,$521C		; when moving from slot 3 to 4 there are 4 extra pixels
521B: 23          inc  hl
521C: 10 CB       djnz $51E9		; repeat for the rest of objects
521E: C9          ret

; draw a specific object
521F: DD 46 06    ld   b,(ix+$06)	; read the object height
5222: DD 4E 05    ld   c,(ix+$05)	; read the object width
5225: CB B9       res  7,c			; set bit 7 to 0
5227: D5          push de
5228: DD 5E 07    ld   e,(ix+$07)	; de = address of the object graphics
522B: DD 56 08    ld   d,(ix+$08)
522E: C5          push bc
522F: E5          push hl
5230: 41          ld   b,c			; b = object width
5231: 1A          ld   a,(de)		; read a byte of graphic data and write it to screen
5232: 77          ld   (hl),a
5233: 13          inc  de
5234: 23          inc  hl
5235: 10 FA       djnz $5231		; repeat until the width is complete
5237: E1          pop  hl
5238: CD 4D 3A    call $3A4D		; advance hl to the next line
523B: C1          pop  bc			; repeat until the object is finished
523C: 10 F0       djnz $522E
523E: D1          pop  de
523F: 18 C8       jr   $5209		; advance to the next slot

; update the doors that guillermo and adso can enter
5241: 3A F6 2D    ld   a,($2DF6)	; read adso's objects
5244: E6 02       and  $02			; keep key 3
5246: 87          add  a,a			; shift 3 positions to the left
5247: 87          add  a,a
5248: 87          add  a,a
5249: 4F          ld   c,a
524A: 3E EF       ld   a,$EF
524C: 21 DC 2D    ld   hl,$2DDC		; point to the doors that adso can open
524F: A6          and  (hl)			; keep bit 4 (permission for the passage door behind the kitchen)
5250: B1          or   c			; combine with key3
5251: 77          ld   (hl),a		; update the value
5252: 3A EF 2D    ld   a,($2DEF)	; read the objects that guillermo has
5255: E6 0C       and  $0C			; keep key 1 and key 2
5257: 4F          ld   c,a
5258: CB 91       res  2,c			; keep only key 1 in c
525A: CB 39       srl  c
525C: CB 39       srl  c
525E: CB 39       srl  c			; move key 1 to bit 0
5260: E6 04       and  $04			; keep key 2 in a (bit 2)
5262: B1          or   c			; combine a and c
5263: 4F          ld   c,a
5264: 21 D9 2D    ld   hl,$2DD9		; point to the doors that guillermo can open
5267: 3E FA       ld   a,$FA
5269: A6          and  (hl)			; update the doors that guillermo can open according to the keys he has
526A: B1          or   c
526B: 77          ld   (hl),a
526C: C9          ret


; check if we drop any object and if so, mark the object sprite to draw
526D: 3E 2F       ld   a,$2F
526F: CD 82 34    call $3482		; if space wasn't being pressed, exit
5272: C8          ret  z
5273: DD 21 EC 2D ld   ix,$2DEC		; point to guillermo's object data

; also arrive here from other places
5277: DD 7E 03    ld   a,(ix+$03)	; read the objects we have
527A: 01 00 08    ld   bc,$0800		; b = 8 objects
527D: 0C          inc  c			; c = object number being checked for possession
527E: 87          add  a,a
527F: 38 03       jr   c,$5284		; if they have the object being checked, jump
5281: 10 FA       djnz $527D		; check for all objects
5283: C9          ret

; arrive here when space was pressed and had some object (c = object number)
5284: 79          ld   a,c
5285: 32 F4 52    ld   ($52F4),a	; modify an instruction with the object number being checked if dropped
5288: DD 35 06    dec  (ix+$06)		; decrement the counter
528B: DD 7E 06    ld   a,(ix+$06)
528E: FE FF       cp   $FF
5290: C0          ret  nz			; if it was not 0, exit
5291: DD 34 06    inc  (ix+$06)
5294: CD 4F 53    call $534F		; get the position where the object will be dropped and the height at which the character is
5297: C5          push bc
5298: CD 73 24    call $2473		; depending on the height, return the base height of the floor in b
529B: 90          sub  b
529C: 32 C1 52    ld   ($52C1),a	; modify a comparison with the relative height of the object
529F: 3A BA 2D    ld   a,($2DBA)	; get the base height of the floor where the character is from the grid
52A2: B8          cp   b
52A3: E1          pop  hl			; recover the position where the object will be dropped in hl
52A4: DD E5       push ix
52A6: E5          push hl
52A7: 20 3C       jr   nz,$52E5		; if the object is not dropped on the same floor, jump
52A9: CD 9B 27    call $279B		; adjust the position passed in hl to the central 20x20 positions shown. If the position is outside, CF=1
52AC: 38 37       jr   c,$52E5		; if there's carry, the position is not inside the visible rectangle, so jump
52AE: CD D4 0C    call $0CD4    	; index into the height table and return the corresponding address in ix
52B1: DD 7E 00    ld   a,(ix+$00)	; get the corresponding entry from the height buffer
52B4: 4F          ld   c,a
52B5: E6 F0       and  $F0			; keep the upper part
52B7: 20 29       jr   nz,$52E2		; if there's any character in that position, exit
52B9: 79          ld   a,c
52BA: E6 0F       and  $0F			; otherwise get the height of that position
52BC: FE 0D       cp   $0D			; if dropped at a position with a height >= 0x0d, exit
52BE: 30 22       jr   nc,$52E2
52C0: D6 00       sub  $00			; instruction modified from outside with the height of the character dropping the object
52C2: FE 05       cp   $05			; if the height of the position where it's dropped - height of the character dropping the object >= 0x05, exit
52C4: 30 1C       jr   nc,$52E2
52C6: 79          ld   a,c
52C7: E6 0F       and  $0F			; otherwise get the height of that position
52C9: DD BE FF    cp   (ix-$01)		; compare it with its neighbors and if not equal, exit
52CC: 20 14       jr   nz,$52E2
52CE: DD BE E8    cp   (ix-$18)
52D1: 20 0F       jr   nz,$52E2
52D3: DD BE E7    cp   (ix-$19)
52D6: 20 0A       jr   nz,$52E2
52D8: 4F          ld   c,a			; c = relative height of the position where the object is dropped
52D9: 3A BA 2D    ld   a,($2DBA)	; a = base height of the floor where you are
52DC: 81          add  a,c			; a = total height of the position where the object is dropped
52DD: D1          pop  de
52DE: DD E1       pop  ix
52E0: 18 11       jr   $52F3		; jump to record the object data and remove the object from the character dropping it

; jump here if the height of the position where the object is dropped and its neighbors don't match
52E2: E1          pop  hl
52E3: E1          pop  hl
52E4: C9          ret

; arrive here if the object is not dropped on the same floor as the screen you're on or not dropped in the same room
52E5: E1          pop  hl
52E6: DD E1       pop  ix
52E8: DD 6E 01    ld   l,(ix+$01)	; get the address of the character's position
52EB: DD 66 02    ld   h,(ix+$02)
52EE: 5E          ld   e,(hl)		; de = character's global position
52EF: 23          inc  hl
52F0: 56          ld   d,(hl)
52F1: 23          inc  hl
52F2: 7E          ld   a,(hl)		; a = character's global height

; also arrive here if the object is in the same room shown on screen
52F3: 0E 00       ld   c,$00		; instruction modified with the object number being dropped
52F5: DD 6E 01    ld   l,(ix+$01)	; hl = address of the character's position
52F8: DD 66 02    ld   h,(ix+$02)
52FB: 2B          dec  hl
52FC: 67          ld   h,a			; save the orientation in h
52FD: 7E          ld   a,(hl)		; game bug! wants to get the character's orientation but has overwritten h
52FE: EE 02       xor  $02
5300: 6F          ld   l,a			; l = supposed object orientation
5301: E5          push hl
5302: DD 36 06 10 ld   (ix+$06),$10	; initialize the counter for picking up/dropping objects
5306: 79          ld   a,c
5307: 21 00 80    ld   hl,$8000		; start checking if it has the object indicated by bit 7
530A: 3D          dec  a
530B: 28 06       jr   z,$5313		; if we modified the mask to reach the object, exit
530D: CB 3C       srl  h
530F: CB 1D       rr   l
5311: 18 F7       jr   $530A		; otherwise continue modifying the mask
5313: 7D          ld   a,l
5314: 2F          cpl
5315: DD A6 00    and  (ix+$00)		; combine the objects we had to remove the one being dropped
5318: DD 77 00    ld   (ix+$00),a	; combine the objects we had to remove the one being dropped
531B: 7C          ld   a,h
531C: 2F          cpl				; the bit of the object being dropped is 0 and the rest of the bits are 1
531D: DD A6 03    and  (ix+$03)		; combine the objects we had to remove the one being dropped
5320: DD 77 03    ld   (ix+$03),a	; update the objects we have

5323: DD 21 1B 2F ld   ix,$2F1B		; point to object sprites
5327: FD 21 08 30 ld   iy,$3008		; point to object position data
532B: 79          ld   a,c
532C: 3D          dec  a
532D: 28 0C       jr   z,$533B		; if reached the object, exit
532F: 01 14 00    ld   bc,$0014		; advance to the next sprite
5332: DD 09       add  ix,bc
5334: 01 05 00    ld   bc,$0005		; advance to the next position data
5337: FD 09       add  iy,bc
5339: 18 F1       jr   $532C

533B: FD CB 00 BE res  7,(iy+$00)	; indicate that the object is not held
533F: E1          pop  hl
5340: FD 74 04    ld   (iy+$04),h	; stores the destination height of the object
5343: FD 75 01    ld   (iy+$01),l	; stores the orientation of the object
5346: FD 73 02    ld   (iy+$02),e	; stores the global destination position of the object
5349: FD 72 03    ld   (iy+$03),d
534C: C3 13 0D    jp   $0D13		; jumps to the object redraw routine to redraw only the object being dropped

; modifies a routine with the character's position data and orientation
; returns in bc the character's position + 2*displacement according to orientation
;  and in a the character's height
534F: DD 5E 01    ld   e,(ix+$01)		; reads the address of the character's position data
5352: DD 56 02    ld   d,(ix+$02)
5355: 1B          dec  de
5356: 1A          ld   a,(de)			; reads the character's orientation
5357: 21 53 28    ld   hl,$2853			; hl points to the displacement table to add if continuing to advance in that orientation
535A: CD 92 27    call $2792			; hl = hl + 8*a
535D: 13          inc  de
535E: 1A          ld   a,(de)			; reads the character's x position
535F: 86          add  a,(hl)			; adds 2 times the value read from the table
5360: 86          add  a,(hl)
5361: 32 6E 51    ld   ($516E),a		; modifies a comparison
5364: 4F          ld   c,a				; stores the position value in c
5365: 13          inc  de
5366: 23          inc  hl
5367: 1A          ld   a,(de)			; reads the character's y position
5368: 86          add  a,(hl)			; adds 2 times the value read from the table
5369: 86          add  a,(hl)
536A: 32 73 51    ld   ($5173),a		; modifies a comparison
536D: 47          ld   b,a
536E: 13          inc  de
536F: 1A          ld   a,(de)			; reads the character's height
5370: 32 67 51    ld   ($5167),a		; modifies a subtraction
5373: C9          ret
; ---------------------------- end of code related to picking up/dropping objects ---------------------------------------

; ------------- code to perform the mirror reflection effect ------------------------

; if the mirror is not open, perform the mirror effect
5374: 3A 8C 2D    ld   a,($2D8C)		; reads if the mirror's secret room is open
5377: A7          and  a
5378: C8          ret  z				; if it's open, exit
5379: FD 21 36 30 ld   iy,$3036			; points to william's characteristics
537D: DD 21 53 2E ld   ix,$2E53			; points to the abbot's sprite
5381: 21 DC 9A    ld   hl,$9ADC			; points to a buffer for flipping graphics
5384: 11 9F 31    ld   de,$319F			; points to william's animation table
5387: 01 8D 2D    ld   bc,$2D8D			; points to a buffer
538A: CD 9E 53    call $539E			; performs the mirror effect in the mirror room for william
538D: 01 92 2D    ld   bc,$2D92			; points to a buffer
5390: 21 D6 9B    ld   hl,$9BD6			; points to a buffer for flipping graphics
5393: 11 BF 31    ld   de,$31BF			; points to adso's animation table
5396: FD 21 45 30 ld   iy,$3045			; points to adso's characteristics
539A: DD 21 67 2E ld   ix,$2E67			; points to berengario's sprite
									; performs the mirror effect in the mirror room for adso

; iy points to the character's position data
; ix points to a sprite
; hl points to a buffer for flipping graphics
; de points to the character's animation table
; bc points to a buffer
539E: C5          push bc
539F: CD AD 53    call $53AD		; performs the mirror effect in the mirror room
53A2: C1          pop  bc
53A3: 7D          ld   a,l
53A4: 02          ld   (bc),a		; saves the sprite's visibility state
53A5: FE FE       cp   $FE			; if the sprite is visible, exit
53A7: C0          ret  nz
53A8: DD CB 0B BE res  7,(ix+$0b)	; indicates that the sprite is of a monk
53AC: C9          ret

; if the character is in front of the mirror, fills the sprite passed in ix to perform the mirror effect
; iy points to the character's position data
; ix points to a sprite
; hl points to a buffer for flipping graphics
; de points to the character's animation table
; bc points to a buffer
53AD: 22 83 54    ld   ($5483),hl	; modifies an instruction with the buffer address
53B0: 2E FE       ld   l,$FE		; indicates that initially the sprite is not visible
53B2: 3A A9 27    ld   a,($27A9)	; a = minimum x position visible on screen
53B5: FE 1C       cp   $1C			; if not in the mirror room, exit
53B7: C0          ret  nz
53B8: 3A 9D 27    ld   a,($279D)	; a = minimum y position visible on screen
53BB: FE 5C       cp   $5C			; if not in the mirror room, exit
53BD: C0          ret  nz

53BE: 0A          ld   a,(bc)		; gets the sprite's previous state
53BF: 32 53 54    ld   ($5453),a	; modifies a call
53C2: 03          inc  bc
53C3: ED 43 44 54 ld   ($5444),bc	; modifies 2 instructions
53C7: ED 43 4C 54 ld   ($544C),bc
53CB: 03          inc  bc
53CC: 03          inc  bc
53CD: ED 43 48 54 ld   ($5448),bc	; modifies 2 instructions
53D1: ED 43 50 54 ld   ($5450),bc
53D5: FD 7E 04    ld   a,(iy+$04)	; a = character's height
53D8: CD 73 24    call $2473		; depending on the height, returns the floor's base height in b
53DB: 90          sub  b
53DC: FE 08       cp   $08			; if the height above the floor's base is >= 0x08, exit
53DE: D0          ret  nc
53DF: 78          ld   a,b
53E0: FE 16       cp   $16			; if not on the second floor, exit
53E2: C0          ret  nz

53E3: FD 7E 02    ld   a,(iy+$02)	; a = character's x position
53E6: 47          ld   b,a
53E7: D6 20       sub  $20			; if not in the mirror's visible zone in x, exit
53E9: D8          ret  c
53EA: FE 0A       cp   $0A
53EC: D0          ret  nc
53ED: FD 7E 03    ld   a,(iy+$03)	; a = character's y position
53F0: D6 62       sub  $62
53F2: D8          ret  c			; if not in the mirror's visible zone in y, exit
53F3: FE 0A       cp   $0A
53F5: D0          ret  nc

53F6: FD 4E 01    ld   c,(iy+$01)	; c = character's orientation
53F9: FD 7E 00    ld   a,(iy+$00)	; a = character's animation
53FC: F5          push af			; saves the character's animation
53FD: EE 02       xor  $02			; inverts the animation
53FF: FD 77 00    ld   (iy+$00),a
5402: C5          push bc			; saves the orientation and x position
5403: 78          ld   a,b			; recovers the character's x position
5404: D6 21       sub  $21
5406: ED 44       neg
5408: C6 21       add  a,$21		; reflects the x position with respect to the mirror
540A: FD 77 02    ld   (iy+$02),a
540D: 79          ld   a,c
540E: CB 47       bit  0,a
5410: 20 02       jr   nz,$5414		; reflects the character's orientation
5412: EE 02       xor  $02
5414: FD 77 01    ld   (iy+$01),a

5417: FD CB 05 7E bit  7,(iy+$05)	; if the character occupies 4 positions, jump
541B: 28 03       jr   z,$5420
541D: FD 35 02    dec  (iy+$02)		; decrements the x position

5420: 21 73 54    ld   hl,$5473
5423: 22 59 2A    ld   ($2A59),hl	; modifies the address of the routine in charge of flipping graphics
5426: ED 53 84 2A ld   ($2A84),de	; modifies the character's animation table
542A: DD CB 0B FE set  7,(ix+$0b)	; indicates that it's not a monk
542E: DD 7E 00    ld   a,(ix+$00)	; reads and preserves the sprite's state
5431: F5          push af
5432: CD 27 2A    call $2A27		; advances the sprite's animation and redraws it
5435: F1          pop  af
5436: DD 6E 01    ld   l,(ix+$01)	; reads the sprite's position
5439: DD 66 02    ld   h,(ix+$02)
543C: DD 5E 05    ld   e,(ix+$05)	; reads the sprite's width and height
543F: DD 56 06    ld   d,(ix+$06)
5442: D9          exx
5443: 2A 8D 2D    ld   hl,($2D8D)	; instruction modified from outside
5446: ED 5B 8F 2D ld   de,($2D8F)	; instruction modified from outside
544A: D9          exx
544B: 22 8D 2D    ld   ($2D8D),hl	; instruction modified from outside
544E: ED 53 8F 2D ld   ($2D8F),de	; instruction modified from outside
5452: 3E 00       ld   a,$00		; instruction modified from outside
5454: FE FE       cp   $FE
5456: 28 01       jr   z,$5459		; if the sprite is not visible, don't change the registers
5458: D9          exx
5459: DD 75 03    ld   (ix+$03),l	; writes the previous position and the previous width and height of the sprite
545C: DD 74 04    ld   (ix+$04),h
545F: DD 73 09    ld   (ix+$09),e
5462: DD 72 0A    ld   (ix+$0a),d
5465: C1          pop  bc
5466: FD 70 02    ld   (iy+$02),b	; restores the character's orientation and x position
5469: FD 71 01    ld   (iy+$01),c
546C: F1          pop  af
546D: FD 77 00    ld   (iy+$00),a	; restores the character's animation counter
5470: 2E 00       ld   l,$00		; indicates that the sprite is visible
5472: C9          ret

; routine in charge of flipping graphics
5473: DD 6E 05    ld   l,(ix+$05)	; gets the sprite's width and height
5476: DD 66 06    ld   h,(ix+$06)
5479: E5          push hl
547A: 7C          ld   a,h
547B: 26 00       ld   h,$00
547D: CD 24 4D    call $4D24		; de = a*hl (de = width*height)
5480: 42          ld   b,d			; bc = de
5481: 4B          ld   c,e
5482: 11 40 9B    ld   de,$9B40		; instruction modified from outside
5485: D5          push de
5486: DD 6E 07    ld   l,(ix+$07)	; hl = address of the sprite's graphics
5489: DD 66 08    ld   h,(ix+$08)
548C: DD 73 07    ld   (ix+$07),e	; sets the new graphics address
548F: DD 72 08    ld   (ix+$08),d
5492: ED B0       ldir				; copies the graphics to the destination
5494: E1          pop  hl
5495: C1          pop  bc
5496: C3 52 35    jp   $3552		; flips the graphics pointed to by hl according to the characteristics indicated by bc

; ------------- end of code to perform the mirror reflection effect ------------------------

; if the scroll of the time of day change hasn't completed, advance it one step
5499: 3A A5 2D    ld   a,($2DA5)	; checks if the scroll of the time of day change has completed
549C: A7          and  a
549D: C8          ret  z			; if the day has already changed completely, exit
549E: 3D          dec  a
549F: 32 A5 2D    ld   ($2DA5),a	; otherwise, one less iteration remains
54A2: FE 07       cp   $07
54A4: 3E 20       ld   a,$20		; a = blank space
54A6: 30 08       jr   nc,$54B0		; if no character needs to be placed yet (0x2da5 > 7), jump with space
54A8: 2A 82 2D    ld   hl,($2D82)	; gets the pointer to the next time of day
54AB: 7E          ld   a,(hl)		; reads a character
54AC: 23          inc  hl
54AD: 22 82 2D    ld   ($2D82),hl	; updates the pointer

; performs the scroll effect of the day text 8 pixels to the left
54B0: 21 0D B4    ld   hl,$B40D		; l = X coordinate (in bytes) + 32 pixels, h = Y coordinate (in pixels)
54B3: 22 97 2D    ld   ($2D97),hl	; saves the initial position for the scroll (84, 180)

54B6: 21 EB E6    ld   hl,$E6EB		; points to screen (44, 180)
54B9: 06 08       ld   b,$08		; b = 8 lines
54BB: F5          push af
54BC: C5          push bc
54BD: E5          push hl
54BE: 01 0C 00    ld   bc,$000C		; c = 12 bytes
54C1: 54          ld   d,h			; de = hl
54C2: 5D          ld   e,l
54C3: 1B          dec  de
54C4: 1B          dec  de
54C5: ED B0       ldir				; performs the scroll 8 pixels to the left
54C7: E1          pop  hl
54C8: CD 4D 3A    call $3A4D		; goes to the next line
54CB: C1          pop  bc
54CC: 10 EE       djnz $54BC		; completes the 8 lines
54CE: F1          pop  af			; recovers the character to print
54CF: C3 17 3B    jp   $3B17		; prints a character

; initializes the day and time of day
54D2: 3A 4F BF    ld   a,($BF4F)
54D5: 32 80 2D    ld   ($2D80),a	; writes the day
54D8: 3A 4E BF    ld   a,($BF4E)
54DB: 32 81 2D    ld   ($2D81),a	; writes the time of day
54DE: C9          ret

; sets the palette according to the time of day and displays the day number
54DF: 3A 81 2D    ld   a,($2D81)	; reads the time of day
54E2: 3D          dec  a
54E3: FE 05       cp   $05
54E5: F5          push af
54E6: DC 44 3F    call c,$3F44		; if a <=, select palette 2
54E9: F1          pop  af
54EA: F5          push af
54EB: D4 49 3F    call nc,$3F49		; otherwise, select palette 3

54EE: 3A 80 2D    ld   a,($2D80)
54F1: CD 59 55    call $5559		; draws the day number on the indicator
54F4: 21 BC 4F    ld   hl,$4FBC
54F7: F1          pop  af			; recovers the time of day
54F8: 32 81 2D    ld   ($2D81),a
54FB: 3C          inc  a
54FC: 47          ld   b,a
54FD: 87          add  a,a
54FE: 4F          ld   c,a
54FF: 87          add  a,a
5500: 81          add  a,c
5501: 80          add  a,b
5502: CD 2D 16    call $162D		; hl = hl + 7*(a + 1)
5505: 22 82 2D    ld   ($2D82),hl	; points to the name of the time of day
5508: 18 34       jr   $553E		; advances the time of day

550A: 3A 80 2D    ld   a,($2D80)	; reads the day
550D: 3D          dec  a			; adjusts for indexing
550E: 47          ld   b,a
550F: 87          add  a,a
5510: 4F          ld   c,a
5511: 87          add  a,a
5512: 80          add  a,b
5513: 81          add  a,c			; a = 7*a
5514: 21 7A 4F    ld   hl,$4F7A		; hl = hl + a
5517: CD 2D 16    call $162D
551A: 3A 81 2D    ld   a,($2D81)	; reads the day period
551D: CD 2D 16    call $162D		; adjusts the index in the table
5520: 66          ld   h,(hl)		; stores the duration of the day stage
5521: 2E 00       ld   l,$00
5523: 22 86 2D    ld   ($2D86),hl
5526: C9          ret

; checks if it's time to move to the next time of day
5527: 3E 06       ld   a,$06
5529: CD 72 34    call $3472		; checks if the enter state has changed
552C: CD C6 41    call $41C6		; sets a to 0, so enter is never considered pressed
552F: 20 0D       jr   nz,$553E		; if enter was pressed, advance the day stage
5531: 2A 86 2D    ld   hl,($2D86)	; if the counter for the time of day to pass is 0, exit
5534: 7C          ld   a,h
5535: B5          or   l
5536: C8          ret  z

5537: 2B          dec  hl			; decrements the time of day counter and if it reaches 0, updates the time of day
5538: 22 86 2D    ld   ($2D86),hl
553B: 7C          ld   a,h
553C: B5          or   l
553D: C0          ret  nz

; updates the time of day
553E: 3A 81 2D    ld   a,($2D81)	; gets the time of day
5541: 3C          inc  a
5542: FE 07       cp   $07			; advances the time of day
5544: 20 2F       jr   nz,$5575		; if it went out of the table, return to the first time of day
5546: 21 BC 4F    ld   hl,$4FBC
5549: 22 82 2D    ld   ($2D82),hl
554C: 3A 80 2D    ld   a,($2D80)	; advances one day
554F: 3C          inc  a
5550: 32 80 2D    ld   ($2D80),a	; in case it went past the seventh day, return to the first day
5553: FE 08       cp   $08
5555: 38 05       jr   c,$555C
5557: 3E 01       ld   a,$01

; updates the day, reflecting it on the indicator
5559: 32 80 2D    ld   ($2D80),a	; updates the day
555C: 3D          dec  a			; adjusts the index to 0
555D: 4F          ld   c,a
555E: 87          add  a,a
555F: 81          add  a,c			; each table entry occupies 3 bytes
5560: 21 A7 4F    ld   hl,$4FA7		; indexes into the days table
5563: CD 2D 16    call $162D
5566: EB          ex   de,hl
5567: 21 51 EE    ld   hl,$EE51		; points to screen (68, 165)
556A: CD 83 55    call $5583		; places the first day number on the indicator
556D: CD 83 55    call $5583		; places the second day number on the indicator
5570: CD 83 55    call $5583		; places the third day number on the indicator
5573: 3E 00       ld   a,$00		; sets the first time of day
5575: 32 81 2D    ld   ($2D81),a
5578: 3E 09       ld   a,$09
557A: 32 A5 2D    ld   ($2DA5),a	; 9 positions to perform the scroll of the time of day change
557D: CD 0A 55    call $550A		; sets a value in 0x2d86 depending on the day and time
5580: C9          ret

; table of 8 pixels with color 3
5581: FF FF

; places a day number
5583: E5          push hl			; saves the screen address
5584: 3E 03       ld   a,$03
5586: 32 A8 55    ld   ($55A8),a	; initially inc bc
5589: 1A          ld   a,(de)		; reads a byte from the data that forms the day number
558A: 01 49 AB    ld   bc,$AB49		; points to 'I'
558D: FE 02       cp   $02
558F: 28 0E       jr   z,$559F		; if a 2 was read, jump
5591: 01 39 AB    ld   bc,$AB39		; points to 'V'
5594: A7          and  a
5595: 20 08       jr   nz,$559F		; if it's not a 0, jump
5597: 3E 0B       ld   a,$0B
5599: 32 A8 55    ld   ($55A8),a	; changes inc bc to dec bc
559C: 01 81 55    ld   bc,$5581		; points to pixels with colors 3, 3, 3, 3

559F: 3E 08       ld   a,$08		; fills the 8 lines that the letter occupies (8x8)
55A1: F5          push af
55A2: 0A          ld   a,(bc)		; reads a byte and copies it to screen
55A3: 77          ld   (hl),a
55A4: 23          inc  hl			; advance
55A5: 03          inc  bc
55A6: 0A          ld   a,(bc)		; reads another byte and copies it to screen
55A7: 77          ld   (hl),a
55A8: 03          inc  bc			; instruction modified from outside (advance or go back)
55A9: 2B          dec  hl
55AA: CD 4D 3A    call $3A4D		; advances to the next screen line
55AD: F1          pop  af
55AE: 3D          dec  a
55AF: 20 F0       jr   nz,$55A1		; repeats for the 8 lines
55B1: E1          pop  hl
55B2: 23          inc  hl			; advances to the next position
55B3: 23          inc  hl
55B4: 13          inc  de
55B5: C9          ret

; checks if time-related variables need to be modified (time of day, lamp fuel, etc)
55B6: C5          push bc
55B7: E5          push hl
55B8: D5          push de
55B9: CD 27 55    call $5527		; checks if the day stage needs to advance (also changes if enter was pressed)
55BC: CD FD 41    call $41FD		; checks if the lamp is being used, and if so, if it's running out
55BF: 79          ld   a,c
55C0: 32 8D 3C    ld   ($3C8D),a	; updates the lamp state
55C3: CD 2B 42    call $422B		; checks if the night is ending
55C6: 79          ld   a,c
55C7: 32 8C 3C    ld   ($3C8C),a	; updates the variable that indicates if the night is ending
55CA: D1          pop  de
55CB: E1          pop  hl
55CC: C1          pop  bc
55CD: C9          ret

55CE: CD D3 55    call $55D3		; decrements william's life by 2 units
55D1: 02
55D2: C9          ret

; decrements and updates the energy bar on screen (obsequium)
55D3: E1          pop  hl			; gets the address it would have to return to and reads the byte there
55D4: 4E          ld   c,(hl)		; gets the life units to subtract
55D5: 23          inc  hl
55D6: E5          push hl			; will return to the address after that byte
55D7: 3A 7F 2D    ld   a,($2D7F)	; reads the energy
55DA: 91          sub  c			; subtracts the read units
55DB: 30 0C       jr   nc,$55E9		; if energy >= 0, jump

; arrives here if there's no energy left
55DD: 3A 97 3C    ld   a,($3C97)
55E0: A7          and  a
55E1: 20 05       jr   nz,$55E8		; if william has died, jump
55E3: 3E 0B       ld   a,$0B
55E5: 32 C7 3C    ld   ($3CC7),a	; changes the abbot's state to throw him out of the abbey
55E8: AF          xor  a			; resets the counter

55E9: 32 7F 2D    ld   ($2D7F),a	; updates the energy counter
55EC: 4F          ld   c,a			; saves the counter
55ED: 21 2A 56    ld   hl,$562A		; points to a pixel table for the last 4 pixels of life
55F0: E6 03       and  $03
55F2: CD 2D 16    call $162D		; indexes into the table according to the 2 least significant bits
55F5: 5E          ld   e,(hl)		; e = value from the table
55F6: 21 1C CF    ld   hl,$CF1C		; points to screen (252, 177)
55F9: CB 39       srl  c
55FB: CB 39       srl  c
55FD: 79          ld   a,c			; calculates the life bar width rounded to the nearest multiple of 4
55FE: 16 0F       ld   d,$0F		; value to write
5600: CD 0E 56    call $560E		; draws the first part of the life bar
5603: 3E 01       ld   a,$01		; 4 pixels wide
5605: 53          ld   d,e			; value to write depending on remaining life
5606: CD 0E 56    call $560E		; draws the second part of the life bar
5609: 3E 07       ld   a,$07		; gets the lost life
560B: 91          sub  c
560C: 16 FF       ld   d,$FF		; fills with black

; draws a rectangle of a bytes wide and 6 lines high (writes d)
560E: A7          and  a			; if a = 0, exit
560F: C8          ret  z
5610: 47          ld   b,a			; b = number of bytes wide
5611: C5          push bc
5612: E5          push hl
5613: 06 06       ld   b,$06		; 6 lines high
5615: 72          ld   (hl),d		; writes to screen
5616: CD 4D 3A    call $3A4D		; goes to the next line
5619: 10 FA       djnz $5615
561B: E1          pop  hl
561C: C1          pop  bc
561D: 23          inc  hl			; advances to the next byte in x
561E: 10 F1       djnz $5611
5620: C9          ret

; table with the roman numerals of the stairs in the mirror room
5621: 	49 58 D8 -> IXX
	58 49 D8 -> XIX
	58 58 C9 -> XXI

; table with pixels to fill the last 4 pixels of the obsequium bar
562A: FF 7F 3F 1F

; if the roman numeral of the mirror room puzzle hasn't been generated, generate it
562E: 3A BC 2D    ld   a,($2DBC)		; gets the roman numeral of the mirror room puzzle
5631: A7          and  a
5632: 20 07       jr   nz,$563B			; if the number was already calculated, jump
5634: ED 5F       ld   a,r				; otherwise, generate a random number between 1 and 3
5636: E6 03       and  $03
5638: 20 01       jr   nz,$563B
563A: 3C          inc  a
563B: C4 43 56    call nz,$5643			; copies the generated number to the scroll string
563E: CD 26 50    call $5026			; places on the indicator the phrase SECRETUM FINISH AFRICAE, MANUS SUPRA XXX AGE PRIMUM ET SEPTIMUM DE QUATOR
	00								;  (where XXX is the generated number)
5642: C9          ret

; copies the roman numerals of the mirror room to the scroll string
5643: 32 BC 2D    ld   ($2DBC),a		; gets the entry for the roman numeral of the stairs where QR must be pressed in front of the mirror
5646: 3D          dec  a
5647: 4F          ld   c,a				; each entry occupies 3 bytes
5648: 87          add  a,a
5649: 81          add  a,c
564A: 21 21 56    ld   hl,$5621			; table with the roman numerals of the stairs in the mirror room
564D: CD 2D 16    call $162D			; hl = hl + a
5650: 11 9E B5    ld   de,$B59E			; points to the scroll string data
5653: 01 03 00    ld   bc,$0003
5656: ED B0       ldir					; copies the roman numerals to the scroll string
5658: C9          ret

; table of octaves and notes for the game phrases
5659: 	38 41 41 41 35 45 41 41 41 49 49 54 54 41 41 51
	41 41 54 54 41 41 41 41 41 41 41 41 41 41 41 49
	41 39 39 54 54 41 51 54 54 41 54 54 51 41 39 39
	41 41 39 49 49 35 35 51

; --------------- code related to bonus calculation and camera changes ---------------------------------
5691: CF          rst  $08			; interprets the commands following this instruction
	90 -> c1a = [0x3ce9]
	40 FD -> c2a = 0xfd
	3D -> ca = [0x3ce9] == 0xfd ; ca = if berengario is going for the book
	9D -> c1b = [0x3074]
	50 -> c2b = 0x50
	3C -> cb = c1b < c2b		; cb = if berengario's x position is < 0x50
	26 -> cc = ca & cb
	AB -> cd = [0x3ca1]			; cd = berengario is alive
	26 -> ce = cc & cd
	90 -> c1f = [0x3ce9]
	40 FE -> c2f = 0xfe			; ce = if berengario/bernardo gui is going for the abbot
	3D -> cf = c1f == c2f
	2A -> c = ce | cf
56A1: 20 04       jr   nz,$56A7		; if need to follow berengario
56A3: D7          rst  $10			; interprets the commands following this instruction
	A7 04 -> [0x3c92] = 0x04	; indicates that the camera follows berengario
56A6: C9          ret

56A7: CF          rst  $08			; interprets the commands following this instruction
	88 -> c1a = [0x2d81]
	03 -> c2a = 0x03
	3D -> ca = if the time of day is sext
	8A -> c1b = [0x3cc6]
	02 -> c2b = 0x02
	3E -> cb = [0x3cc6] >= 2
	26 -> cc = if the time of day is sext and the abbot has reached some interesting place
	8C -> c1d = [0x3cc7]
	15 -> c2d = 0x15
	3D -> cd = [0x3cc7] == 0x15
	2A -> ce = (if the time of day is sext and the abbot has reached some interesting place) or (the abbot is going to leave the scroll)
	A5 -> c1f = [0x3c94]
	01 -> c2f = 0x01
	3D -> cf = [0x3c94] == 0x01
	2A -> cg = ((if the time of day is sext and [0x3cc6] > 2) or ([0x3cc7] == 0x15)) or (the abbot is going to ask william for the scroll)
	8C -> c1h = [0x3cc7]
	0B -> c2h = 0x0b
	3D -> ch = [0x3cc7] == 0x0b
	2A -> c = (((if the time of day is sext and [0x3cc6] > 2) or ([0x3cc7] == 0x15)) or ([0x3c94] == 0x01)) or (if the abbot is going to throw william out)
56BB: 20 04       jr   nz,$56C1		; if in an interesting situation
56BD: D7          rst  $10			; interprets the commands following this instruction
A7 03 -> [0x3c92] = 0x03		; indicates that the camera follows the abbot
56C0: C9          ret

56C1: CF          rst  $08			; interprets the commands following this instruction
	86 -> c1a = [0x3caa]
	40 FE -> c2a = 0xfe
	3D -> ca = [0x3caa] == 0xfe	; if malachi is going to warn the abbot
	88 -> c1b = [0x2d81]
	05 -> c2b = 0x05
	3D -> cb = if the time of day is vespers
	8E -> c1c = [0x3ca9]
	06 -> c2c = 0x06
	3C -> cc = [0x3ca9] < 0x06
	26 -> cd = (if the time of day is vespers) and (malachi's state < 0x06)
	2A -> c = ((if the time of day is vespers) and (malachi's state < 0x06)) or (if malachi is going to warn the abbot)
56CE: 20 04       jr   nz,$56D4		; if malachi is in an interesting situation
56D0: D7          rst  $10			; interprets the commands following this instruction
	A7 02 -> [0x3c92] = 0x02	; indicates that the camera follows malachi
56D3: C9          ret

56D4: CF          rst  $08			; interprets the commands following this instruction
93 -> c1 = [0x3d01]
40 FF -> c2 = 0xff
3D -> c = [0x3d01] == 0xff
56D9: 20 04       jr   nz,$56DF		; if severino is going for william
56DB: D7          rst  $10			; interprets the commands following this instruction
A7 05 -> [0x3c92] = 0x05		; indicates that the camera follows severino
56DE: C9          ret

56DF: D7          rst  $10			; interprets the commands following this instruction
A7 00 -> [0x3c92] = 0x00		; indicates that the camera follows william

56E2: CF          rst  $08			; interprets the commands following this instruction
	A4 -> c1a = [0x2def]
	10 -> c2a = 0x10
	2A -> ca = [0x2def] & 0x10
	10 -> cb = 0x10
	3D -> c = if we have the scroll
56E8: 20 2E       jr   nz,$5718		; if we have the scroll
56EA: CF          rst  $08			; interprets the commands following this instruction
	8D -> c1a = [0x2d80]
	03 -> c2a = 0x03
	3D -> ca = if it's the third day
	88 -> c1b = [0x2d81]
	00 -> c2b = 0x00
	3D -> cb = if it's night
	26 -> c = if it's the third day and it's night
56F2: 20 05       jr   nz,$56F9		; if it's the third day and it's night
56F4: D7          rst  $10			; interprets the commands following this instruction
C0 C0 10 26 -> [0x2dbf] = [0x2dbf] | 0x10	; gives us a bonus

56F9: CF          rst  $08			; interprets the commands following this instruction
	A4 -> c1a = [0x2def]
	40 20 -> c2a = 0x20
	2A -> ca = [0x2def] & 0x20
	40 20 -> cb = 0x20
	3D -> c = if william has the glasses
5701: 20 05       jr   nz,$5708		; if william has the glasses
5703: D7          rst  $10			; interprets the commands following this instruction
	C0 C0 01 26 -> [0x2dbf] = [0x2dbf] | 0x01
5708: CF          rst  $08			; interprets the commands following this instruction
	9A -> c1a = [0x2dbd]
	0D -> c2a = 0x0d
	3D -> ca = [0x2dbd] == 0x0d
	A7 -> c1b = [0x3c92]
	00 -> c2b = 0x00
	3D -> cb = [0x3c92] == 0x00
	26 -> c = ([0x2dbd] == 0x0d) && ([0x3c92] == 0x00)
5710: 20 06       jr   nz,$5718		; if william enters the abbot's room
5712: D7          rst  $10			; interprets the commands following this instruction
	C0 C0 40 20 26 -> [0x2dbf] = [0x2dbf] | 0x20	; gets a bonus

5718: CF          rst  $08			; interprets the commands following this instruction
	88 -> c1a = [0x2d81]
	00 -> c2a = 0x00
	3D -> ca = if it's night
	80 -> c1b = [0x3038]
	60 -> c2b = 0x60
	3C -> cb = if [0x3038] < 0x60
	26 -> c = it's night and ([0x3038] < 0x60)
5720: 20 05       jr   nz,$5727		; if it's night and in the left wing of the abbey
5722: D7          rst  $10			; interprets the commands following this instruction
	BF BF 01 26 -> [0x2dbe] = [0x2dbe] | 0x01	; gets a bonus

5727: CF          rst  $08			; interprets the commands following this instruction
	82 -> c1 = [0x303a]
	16 -> c2 = 0x16
	3E -> c = [0x303a] >= 0x16
572B: 20 25       jr   nz,$5752		; if william goes up to the library
572D: CF          rst  $08			; interprets the commands following this instruction
	A4 -> c1a = [0x2def]
	40 20 -> c2a = 0x20
	2A -> ca = [0x2def] & 0x20
	40 20 -> cb = 0x20
	3D -> c = if william has the glasses
5735: 20 06       jr   nz,$573D		; if william has the glasses
5737: D7          rst  $10			; interprets the commands following this instruction
	BF BF 40 80 26 -> [0x2dbe] = [0x2dbe] | 0x80
573D: CF          rst  $08			; interprets the commands following this instruction
	B8 -> c1a = [0x2df3]
	40 80 -> c2a = 0x80
	2A -> ca = [0x2df3] & 0x80
	40 80 -> cb = 0x80
	3D -> c = ([0x2df3] & 0x80) == 0x80
5745: 20 06       jr   nz,$574D		; if adso has the lamp
5747: D7          rst  $10			; interprets the commands following this instruction
	BF BF 40 20 26 -> [0x2dbe] = [0x2dbe] | 0x20
574D: D7          rst  $10			; interprets the commands following this instruction
	BF BF 10 26 -> [0x2dbe] = [0x2dbe] | 0x10

5752: CF          rst  $08			; interprets the commands following this instruction
	9A -> c1 = [0x2dbd]
	72 -> c2 = 0x72
	3D -> compares c1 and c2
5756: 20 05       jr   nz,$575D		; if he's in the mirror room
5758: D7          rst  $10			; interprets the commands following this instruction
	C0 C0 02 26 -> [0x2dbf] = [0x2dbf] | 0x02
575D: C9          ret
; ------------------------------------------------------

; ------------------ malaquias logic ----------------
575E: CF          rst  $08
	AC -> c1a = [0x3ca2]
	02 -> c2a = 0x02
	3D -> c = [0x3ca2] == 0x02	; if malaquias has died, exits
5762: 20 03       jr   nz,$5767
5764: C3 5B 3E    jp   $3E5B		; indicates that the character doesn't want to search for any route

5767: CF          rst  $08
	AC -> c1a = [0x3ca2]
	01 -> c2a = 0x01
	3D -> c = [0x3ca2] == 0x01
576B: 20 06       jr   nz,$5773
576C: CD 86 43    call $4386		; if he's dying, advances malaquias' height
5770: C3 5B 3E    jp   $3E5B		; indicates that the character doesn't want to search for any route

5773: CF          rst  $08
	8C -> c1a = [0x3cc7]
	0B -> c2a = 0x0b
	3D -> c = [0x3cc7] == 0x0b
5777: 20 03       jr   nz,$577C		; if the abbot is in the state of throwing william out of the abbey
5779: C3 5B 3E    jp   $3E5B		; indicates that the character doesn't want to search for any route

577C: CF          rst  $08
	88 -> c1a = [0x2d81]
	00 -> c2a = 0x00
	3D -> ca = [0x2d81] == 0x00
	88 -> c1a = [0x2d81]
	06 -> c1b = 0x06
	3D -> cb = [0x2d81] = 0x06
	2A -> c = ([0x2d81] == 0x00) | ([0x2d81] == 0x06)
5784: 20 07       jr   nz,$578D		; if it's night or compline
5786: D7          rst  $10
	86 07 -> [0x3caa] = 0x07	; goes to his cell
5789: D7          rst  $10
	8E 08 -> [0x3ca9] = 0x08	; moves to state 8
578C: C9          ret

578D: CF          rst  $08
	88 -> c1a = [0x2d81]
	05 -> c2a = 0x05
	3D -> c = [0x2d81] == 0x05
5791: C2 89 58    jp   nz,$5889		; if it's vespers
5794: CF          rst  $08
	8E -> c1a = [0x3ca9]
	0C -> c2a = 0x0c
	3D -> c = [0x3ca9] == 0x0c	; if he's in state 0x0c
5798: 20 12       jr   nz,$57AC
579A: D7          rst  $10
	86 40 FE -> [0x3caa] = 0xfe	; goes to look for the abbot
579E: CF          rst  $08
	87 -> c1a = [0x3ca8]
	40 FE -> c2a = 0xfe
	3D -> c = [0x3ca8] == 0xfe
57A3: 20 06       jr   nz,$57AB		; if he has reached the abbot's position
57A5: D7          rst  $10
	8C 0B -> [0x3cc7] = 0x0b		; changes the abbot's state so he throws william out
57A8: D7          rst  $10
	8E 06 -> [0x3ca9] = 0x06	; changes to state 6
57AB: C9          ret

57AC: CF          rst  $08
	8E -> c1a = [0x3ca9]
	00 -> c2a = 0x00
	3D -> c = [0x3ca9] = 0x00
57B0: 20 12       jr   nz,$57C4		; if he's in state 0
57B2: D7          rst  $10
	BA 02 -> [0x2dff] = 0x02	; modifies the mask of objects that malaquias can take (can take the passage key)
57B5: D7          rst  $10
	86 06 -> [0x3caa] = 0x06	; goes to the scriptorium table to take the key
57B8: CF          rst  $08
	87 -> c1a = [0x3ca8]
	06 -> c2a = 0x06
	3D -> c = [0x3ca8] == 0x06
57BC: 20 05       jr   nz,$57C3		; if he has reached the scriptorium table where the key is
57BE: D7          rst  $10
	8E 02 -> [0x3ca9] = 0x02	; moves to state 2
57C1: 18 01       jr   $57C4
57C3: C9          ret

57C4: CF          rst  $08
	8E -> c1a = [0x3ca9]
	04 -> c2a = 0x04
	3C -> c = [0x3ca9] < 0x04
57C8: 20 40       jr   nz,$580A		; if his state is < 4
57CA: CF          rst  $08
	82 -> c1a = [0x303a]
	0C -> c2a = 0x0c
	3E -> c = [0x303a] >= 0x0c	; if william's height is >= 0x0c
57CE: 20 06       jr   nz,$57D6
57D0: D7          rst  $10
	86 40 FF -> [0x3caa] = 0xff	; goes after william
57D4: 18 04       jr   $57DA
57D6: D7          rst  $10
	8E 04 -> [0x3ca9] = 0x04	; moves to state 4
57D9: C9          ret

57DA: CF          rst  $08
	8E -> c1a = [0x3ca9]
	02 -> c2a = 0x02
	3D -> c = [0x3ca9] == 0x02
57DE: 20 10       jr   nz,$57F0		; if he's in state 2
57E0: CD 61 3E    call $3E61		; compares the distance between william and malaquias (if very close returns 0, otherwise != 0)
57E3: 20 0A       jr   nz,$57EF		; if he's close
57E5: CD 1B 50    call $501B		; writes the phrase on the scoreboard
	09          				THOU MUST ABANDON BUILDING, BROTHER
57E9: D7          rst  $10
	8E 03 -> [0x3ca9] = 0x03	; moves to state 3
57EC: D7          rst  $10
	8F 00 -> [0x3c9e] = 0x00	; starts the counter for the time allowed for william to be in the scriptorium
57EF: C9          ret

57F0: CF          rst  $08
	8E -> c1a = [0x3ca9]
	03 -> c2a = 0x03
	3D -> c = [0x3ca9] == 0x03
57F4: 20 14       jr   nz,$580A		; if he's in state 3
57F6: D7          rst  $10
	8F 8F 01 2B -> [0x3c9e] = [0x3c9e] + 1	; increments the counter
57FB: CF          rst  $08
	8F -> c1a = [0x3c9e]
	40 FA -> c2a = 0xfa
	3E -> c = [0x3c9e] >= 0xfa
5800: 20 07       jr   nz,$5809		; if the counter reaches the tolerable limit
5802: CD 1B 50    call $501B		; writes the phrase on the scoreboard
	0A							I SHALL WARN THE ABBOT
5806: D7          rst  $10
	8E 0C -> [0x3ca9] = 0x0c	; changes to state 0x0c
5809: C9          ret

580A: CF          rst  $08
	8E -> c1a = [0x3ca9]
	04 -> c2a = 0x04
	3D -> c = [0x3ca9] == 0x04
580E: 20 22       jr   nz,$5832		; if he's in state 4
5810: D7          rst  $10
	86 04 -> [0x3caa] = 0x04	; goes to close the doors of the abbey's left wing
5813: CF          rst  $08
	87 -> c1a = [0x3ca8]
	04 -> c2a = 0x04
	3D -> c = [0x3ca8] == 0x04
5817: 20 18       jr   nz,$5831		; if he has reached the doors of the abbey's left wing
5819: CF          rst  $08
	9D -> c1a = [0x3074]
	62 -> c2a = 0x62
	3C -> ca = [0x3074] < 0x62
	AB -> cb = [0x3ca1]
	26 -> c = ([0x3074] < 0x62) & ([0x3ca1])
581F: 20 03       jr   nz,$5824		; if berengario or bernardo gui haven't left the abbey's left wing
5821: C3 5B 3E    jp   $3E5B			; indicates that the character doesn't want to search for any route

5824: D7          rst  $10
	8E 05 -> [0x3ca9] = 0x05	; moves to state 5
5827: D7          rst  $10
	9F 9F 7F 2A -> [0x2ffe] = [0x2ffe] & 0x7f	; indicates that the doors no longer remain fixed
582C: D7          rst  $10
	A0 A0 7F 2A -> [0x3003] = [0x3003] & 0x7f
5831: C9          ret

5832: CF          rst  $08
	8E -> c1a = [0x3ca9]
	05 -> c2a = 0x05
	3D -> c = [0x3ca9] == 0x05
5836: 20 13       jr   nz,$584B			; if he's in state 5
5838: D7          rst  $10
	86 05 -> [0x3caa] = 0x05		; goes to the kitchen table in front of the passage
583B: D7          rst  $10
	9E 40 DF -> [0x3ca6] = 0xdf;	; modifies the mask of doors that can be opened
583F: CF          rst  $08
	80 -> c1a = [0x3038]
	60 -> c2a = 0x60
	3C -> c = [0x3038] < 0x60
5843: 20 03       jr   nz,$5848			; if william is in the abbey's left wing
5845: D7          rst  $10
	8E 0C -> [0x3ca9] = 0x0c		; moves to state 0x0c to warn the abbot
5848: C3 98 3E    jp   $3E98			; if he has reached the place he wanted to go, advances the state

584B: CF          rst  $08
	8E -> c1a = [0x3ca9]
	06 -> c2a = 0x06
	3D -> c = [0x3ca9] == 0x06
584F: 20 06       jr   nz,$5857		; if he's in state 6
5851: D7          rst  $10
	86 00 -> [0x3caa] = 0x00	; goes to the church
5854: CD 98 3E    call $3E98		; if he has reached the place he wanted to go, advances the state
5857: CF          rst  $08
	8E -> c1a = [0x3ca9]
	0B -> c2a = 0x0b
	3D -> c = [0x3ca9] == 0x0b
585B: 20 0A       jr   nz,$5867		; if malaquias' state is 0x0b
585D: CF          rst  $08
	89 -> c1a = [0x2da1]
	00 -> c2a = 0x00
	3D -> c = [0x2da1] == 0x00
5861: 20 03       jr   nz,$5866		; if no phrase is being played
5863: D7          rst  $10
	AC 01 -> [0x3ca2] = 0x01	; indicates that malaquias is dying
5866: C9          ret

5867: CF          rst  $08
	8E -> c1a = [0x3ca9]
	07 -> c2a = 0x07
	3D -> c = [0x3ca9] == 0x07
586B: 20 1B       jr   nz,$5888			; if he's in state 7
586D: CF          rst  $08
	8D -> c1a = [0x2d80]
	05 -> c2a = 0x05
	3D -> c = [0x2d80] == 0x05
5871: 20 14       jr   nz,$5887			; if it's the fifth day
5873: CF          rst  $08
	9A -> c1a = [0x2dbd]
	22 -> c2a = 0x22
	3D -> ca = [0x2dbd] == 0x22
	9A -> c1b = [0x2dbd]
	23 -> c2b = 0x23
	3D -> cb = [0x2dbd] == 0x23
	2A -> c = ([0x2dbd] == 0x22) | ([0x2dbd] == 0x23)
587B: 20 0A       jr   nz,$5887			; if he's in the church (the comparison with 0x23 isn't necessary?)
587D: D7          rst  $10
	87 01 -> [0x3ca8] = 0x01		; indicates that he hasn't reached the church yet
5880: D7          rst  $10
	8E 0B -> [0x3ca9] = 0x0b		; moves to state 0x0b
5883: CD 1B 50    call $501B			; writes the phrase on the scoreboard
	1F								IT WAS TRUE, HE HAD THE POWER OF A THOUSAND SCORPIONS
5887: C9          ret
5888: C9          ret

5889: CF          rst  $08
	88 -> c1 = [0x2d81]
	01 -> c2 = 0x01
	3D -> c = [0x2d81] == 0x01
588D: 20 07       jr   nz,$5896			; if it's prime
588F: D7          rst  $10
	8E 09 -> [0x3ca9] = 0x09		; changes to state 9
5892: D7          rst  $10
	86 00 -> [0x3caa] = 0x00		; goes to mass
5895: C9          ret

5896: CF          rst  $08
	87 -> c1 = [0x3ca8]
	02 -> c2 = 0x02
	3D -> c = [0x3ca8] == 0x02
589A: 20 09       jr   nz,$58A5		; if malaquias has reached his position in the scriptorium
589C: D7          rst  $10
	8E 00 -> [0x3ca9] = 0x00		; changes to state 0
589F: D7          rst  $10
	BA 00 -> [0x2dff] = 0x00		; modifies the mask of objects that malaquias can take
58A2: CD 22 40    call $4022		; leaves the passage key on malaquias' table
58A5: CF          rst  $08
	8E -> c1 = [0x3ca9]
	00 -> c2 = 0x00
	3D -> c = [0x3ca9] == 0x00
58A9: C2 13 59    jp   nz,$5913		; if he's in state 0
58AC: CD 61 3E    call $3E61		; compares the distance between william and malaquias (if very close returns 0, otherwise != 0)
58AF: C2 0F 59    jp   nz,$590F		; if he's close to william
58B2: CF          rst  $08
	86 -> c1 = [0x3caa]
	03 -> c2 = 0x03
	3D -> c = [0x3caa] == 0x03
58B6: 20 47       jr   nz,$58FF		; if he has gone out to block william's way
58B8: CF          rst  $08
	AE -> c1 = [0x3ca5]
	40 80 -> c2 = 0x80
	2A -> c = [0x3ca5] & 0x80
58BD: 20 12       jr   nz,$58D1		; if berengario hasn't reached his work position
58BF: CF          rst  $08
	81 -> c1 = [0x3039]
	38 -> c2 = 0x38
	3C -> c = [0x3039] < 0x38
58C3: 20 0A       jr   nz,$58CF		; if william's y position < 0x38
58C5: D7          rst  $10
	AE AE 40 80 26 -> [0x3ca5] = [0x3ca5] | 0x80
58CB: CD 1B 50    call $501B		; says the phrase
	33								I'M SORRY, VENERABLE BROTHER, YOU CANNOT GO UP TO THE LIBRARY
58CF: 18 2D       jr   $58FE

58D1: CF          rst  $08
	AE -> c1 = [0x3ca5]
	40 40 -> c2 = 0x40
	2A -> c = [0x3ca5] & 0x40
58D6: 20 15       jr   nz,$58ED
58D8: CF          rst  $08
	8D -> c1a = [0x2d80]
	02 -> c2a = 0x02
	3D -> ca = [0x2d80] == 0x02
	89 -> cb = [0x2da1]
	26 -> c = ([0x2d80] == 0x02) && ([0x2da1] == 0)
58DE: 20 0B       jr   nz,$58EB	; if it's the second day and no phrase is being played
58E0: D7          rst  $10
	AE AE 40 40 26 -> [0x3ca5] = [0x3ca5] | 0x40
58E6: CD 26 50    call $5026	; says the phrase
	34 							IF YOU WISH, BERENGARIO WILL SHOW YOU THE SCRIPTORIUM
58EA: C9          ret

58EB: 18 11       jr   $58FE

58ED: CF          rst  $08
	AE -> c1 = [0x3ca5]
	10 -> c2 = 0x10
	2A -> c = [0x3ca5] & 0x10
58F1: 20 0B       jr   nz,$58FE
58F3: CD 61 3E    call $3E61		; compares the distance between william and malaquias (if very close returns 0, otherwise != 0)
58F6: 20 01       jr   nz,$58F9		; if he's very close, exits
58F8: C9          ret

; arrives here if he's far away, but this can't be, since this is inside a (if william is close...) (???)
58F9: D7          rst  $10
	AE AE 10 26 -> [0x3ca5] = [0x3ca5] | 0x10 ; ???
58FE: C9          ret

58FF: CD BE 08    call $08BE		; discards planned movements and indicates that a new movement needs to be planned
5902: AF          xor  a
5903: CD 82 34    call $3482		; checks if cursor up is pressed
5906: 20 03       jr   nz,$590B		; if cursor up has been pressed, jumps
5908: C3 5B 3E    jp   $3E5B		; indicates that the character doesn't want to search for any route

590B: D7          rst  $10
	86 03 -> [0x3caa] = 0x03	; goes out to block william's way
590E: C9          ret

590F: D7          rst  $10
	86 02 -> [0x3caa] = 0x02	; returns to his table
5912: C9          ret

5913: CF          rst  $08
	88 -> c1 = [0x2d81]
	02 -> c2 = 0x02
	3D -> c = [0x2d81] == 0x02
5917: 20 25       jr   nz,$593E		; if it's terce
5919: CF          rst  $08
	8E -> c1a = [0x3ca9]
	09 -> c2a = 0x09
	3D -> ca = [0x3ca9] == 0x09
	8D -> c1b = [0x2d80]
	05 -> c2b = 0x05
	3D -> cb = [0x2d80] == 0x05
	26 -> ca = ([0x3ca9] == 0x09) && ([0x2d80] == 0x05)
5921: 20 14       jr   nz,$5937		; if he's in state 0x09 on the fifth day
5923: D7          rst  $10
	86 08 -> [0x3caa] = 0x08	; goes to severino's cell
5926: CF          rst  $08
	87 -> c1a = [0x3ca8]
	08 -> c2a = 0x08
	3D -> ca = [0x3ca8] == 0x08
	94 -> c1b = [0x3cff]
	02 -> c2b = 0x02
	3D -> cb = [0x3cff]
	26 -> c = ([0x3ca8] == 0x08) && ([0x3cff] == 0x02)
592E: 20 06       jr   nz,$5936		; if malaquias and severino are in severino's cell
5930: D7          rst  $10
	AD 01 -> [0x3ca3] = 0x01	; kills severino
5933: D7          rst  $10
	8E 0A -> [0x3ca9] = 0x0a	; changes to state 0x0a
5936: C9          ret

5937: D7          rst  $10
	8E 0A -> [0x3ca9] = 0x0a	; changes to state 0x0a
593A: D7          rst  $10
	86 02 -> [0x3caa] = 0x02	; goes to his work table
593D: C9          ret
593E: C9          ret

; ------------------ end of malaquias logic ----------------

; ------------------ logic of berengario/jorge/bernardo ----------------
593F: CF          rst  $08
	AB -> c1a = [0x3ca1]
	01 -> c2a = 0x01
	3D -> c = [0x3ca1] == 0x01
5943: 20 03       jr   nz,$5948		; if jorge is not doing anything, exits
5945: C3 5B 3E    jp   $3E5B		; indicates that the character doesn't want to search for any route

5948: CF          rst  $08
	8D -> c1a = [0x2d80]
	03 -> c2a = 0x03
	3D -> c = [0x2d80] == 0x03
594C: 20 65       jr   nz,$59B3		; if it's the third day
594E: CF          rst  $08
	88 -> c1a = [0x2d81]
	01 -> c2a = 0x01
	3D -> c = [0x2d81] == 0x01
5952: 20 03       jr   nz,$5957		; if it's prime
5954: C3 5B 3E    jp   $3E5B		; indicates that the character doesn't want to search for any route

5957: CF          rst  $08
	88 -> c1a = [0x2d81]
	02 -> c2a = 0x02
	3D -> c = [0x2d81] == 0x02
595B: 20 36       jr   nz,$5993		; if it's terce
595D: CF          rst  $08
	92 -> c1a = [0x3ce8]
	1E -> c2a = 0x1e
	3D -> c = [0x3ce8] == 0x1e
5961: 20 0C       jr   nz,$596F		; if he's in state 0x1e
5963: CF          rst  $08
	89 -> c1a = [0x2da1]
	00 -> c2a = 0x00
	3D -> c = [0x2da1] == 0x00
5967: 20 03       jr   nz,$596C		; if no voice is being played
5969: D7          rst  $10
	92 1F -> [0x3ce8] = 0x1f	; moves to state 0x1f
596C: C3 5B 3E    jp   $3E5B		; indicates that the character doesn't want to search for any route

596F: CF          rst  $08
	92 -> c1a = [0x3ce8]
	1F -> c2a = 0x1f
	3D -> c = [0x3ce8] == 0x1f
5973: 20 0F       jr   nz,$5984		; if he's in state 0x1f
5975: CD 61 3E    call $3E61		; compares the distance between william and jorge (if very close returns 0, otherwise != 0)
5978: 20 07       jr   nz,$5981		; if he's far, jumps
597A: CD 26 50    call $5026		; puts the phrase on the scoreboard
	32 							BE WELCOME, VENERABLE BROTHER; AND HEAR WHAT I SAY. THE WAYS OF THE ANTICHRIST ARE SLOW AND TORTUOUS. HE ARRIVES WHEN YOU LEAST EXPECT IT. DO NOT WASTE THE LAST DAYS
597E: D7          rst  $10
	9B 01 -> [0x3c9a] = 0x01	; indicates to advance the time of day
5981: C3 5B 3E    jp   $3E5B		; indicates that the character doesn't want to search for any route

5984: CD 3E 61    call $3E61		; compares the distance between william and jorge (if very close returns 0, otherwise != 0)
5987: 20 07       jr   nz,$5990		; if he's far from jorge, jumps
5989: CD 1B 50    call $501B		; writes the phrase on the scoreboard
	31 							VENERABLE JORGE, THE ONE BEFORE YOU IS FRIAR WILLIAM, OUR GUEST
598D: D7
	92 1E -> [0x3ce8] = 0x1e		; moves to state 0x1e
5990: C3 5B 3E    jp   $3E5B		; indicates that the character doesn't want to search for any route

5993: CF          rst  $08
	88 -> c1a = [0x2d81]
	03 -> c2a = 0x03
	3D -> c = [0x2d81] == 0x03
5997: 20 1A       jr   nz,$59B3		; if it's sext
5999: D7          rst  $10
	90 03 -> [0x3ce9] = 0x03	; goes to the monks' cell
599C: D7          rst  $10
	92 00 -> [0x3ce8] = 0x00	; moves to state 0

599F: CF          rst  $08
	9D -> c1a = [0x3074]
	60 -> c2a = 0x60
	3D -> c = [0x3074] == 0x60
59A3: 20 04       jr   nz,$59A9		; if jorge's x position ??? this doesn't make much sense, because it's a phrase that adso says!!!
59A5: CD 26 50    call $5026      	; puts the phrase on the scoreboard
	27							DAWN WILL SOON BREAK, MASTER
59A9: CF          rst  $08
	91 -> c1a = [0x3ce7]
	03 -> c2a = 0x03
	3D -> c = [0x3ce7] == 0x03
59AD: 20 03       jr   nz,$59B2		; if he has reached his cell, indicates it
59AF: D7          rst  $10
	AB 01 -> [0x3ca1] = 0x01	; indicates that jorge won't do anything else for now
59B2: C9          ret


; arrives here if it's not the third day
59B3: CF          rst  $08
	88 -> c1a = [0x2d81]
	03 -> c2a = 0x03
	3D -> c = [0x2d81] == 0x03
59B7: 20 04       jr   nz,$59BD		; if it's sext
59B9: D7          rst  $10
	90 01 -> [0x3ce9] = 0x01	; goes to the refectory
59BC: C9          ret

59BD: CF          rst  $08
	88 -> c1a = [0x2d81]
	01 -> c2a = 0x01
	3D -> c = [0x2d81] == 0x01
59C1: 20 04       jr   nz,$59C7		; if it's prime
59C3: D7          rst  $10
	90 00 -> [0x3ce9] = 0x00	; goes to the church
59C6: C9          ret

59C7: CF          rst  $08
	8D -> c1a = [0x2d80]
	05 -> c2a = 0x05
	3D -> c = [0x2d80] == 0x05
59CB: 20 0F       jr   nz,$59DC		; if it's the fifth day
59CD: CF          rst  $08
	91 -> c1a = [0x3ce7]
	04 -> c2a = 0x04
	3D -> c = [0x3ce7] == 0x04
59D1: 20 06       jr   nz,$59D9		; if he has reached the abbey exit, indicates it
59D3: D7          rst  $10
	AB 01 -> [0x3ca1] = 0x01
59D6: D7
	9D 00 -> [0x3074] = 0x00	; berengario's x position = 0
59D9: D7          rst  $10
	90 04 -> [0x3ce9] = 0x04	; leaves the abbey

59DC: CF          rst  $08
	88 -> c1a = [0x2d81]
	06 -> c2a = 0x06
	3D -> c = [0x2d81] == 0x06
59E0: 20 04       jr   nz,$59E6		; if it's compline
59E2: D7          rst  $10
	90 03 -> [0x3ce9] = 0x03	; goes to the monks' cell
59E5: C9          ret

59E6: CF          rst  $08
	88 -> c1a = [0x2d81]
	00 -> c2a = 0x00
	3D -> c = [0x2d81] == 0x00	; if it's night
59EA: C2 34 5A    jp   nz,$5A34
59ED: CF          rst  $08
	8D -> c1a = [0x2d80]
	03 -> c2a = 0x03
	3D -> c = [0x2d80] == 0x03	; if it's the third day
59F1: C2 30 5A    jp   nz,$5A30
59F4: CF          rst  $08
	92 -> c1a = [0x3ce8]
	06 -> c2a = 0x06
	3D -> c = [0x3ce8] == 0x06
59F8: 20 29       jr   nz,$5A23		; if he's in state 6
59FA: D7          rst  $10
	B0 40 80 -> [0x2e0d] = 0x80	; modifies the mask of objects he can take
59FE: CF          rst  $08
	91 -> c1a = [0x3ce7]
	03 -> c2a = 0x03
	3D -> c = [0x3ce7] == 0x03
5A02: 20 04       jr   nz,$5A08		; if he's in his cell
5A04: D7          rst  $10
	90 05 -> [0x3ce9] = 0x05	; indicates he's going towards the stairs at the foot of the scriptorium
5A07: C9          ret

5A08: D7          rst  $10
	90 40 FD -> [0x3ce9] = 0xfd	; heads towards the book
5A0C: CF          rst  $08
	A8 -> c1a = [0x2e0b]
	40 80 -> c2a = 0x80
	2A -> ca = [0x2e0b] & 0x80
	40 80 -> cb = 0x80
	3D -> c = ([0x2e0b] & 0x80) == 0x80
5A14: 20 0C       jr   nz,$5A22		; if he has the book
5A16: CF          rst  $08
	91 -> c1a = [0x3ce7]
	06 -> c2a = 0x06
	3D -> c = [0x3ce7] == 0x06
5A1A: 20 03       jr   nz,$5A1F		; if he has reached severino's cell
5A1C: D7          rst  $10
	9B 01 -> [0x3c9a] = 0x01	; indicates to advance the time of day
5A1F: D7          rst  $10
	90 06 -> [0x3ce9] = 0x06	; heads to severino's cell
5A22: C9          ret

5A23: CF          rst  $08
	91 -> c1a = [0x3ce7]
	03 -> c2a = 0x03
	3D -> c = [0x3ce7] == 0x03	; if he's in his cell
5A27: 20 07       jr   nz,$5A30
5A29: D7          rst  $10
	92 06 -> [0x3ce8] = 0x06	; moves to state 6
5A2C: CD 94 40    call $4094		; changes berengario's face to the hooded one
5A2F: C9          ret

5A30: D7          rst  $10
	90 03 -> [0x3ce9] = 0x03	; heads to the monks' cell
5A33: C9          ret

5A34: CF          rst  $08
	88 -> c1a = [0x2d81]
	05 -> c2a = 0x05
	3D -> c = [0x2d81] == 0x05
5A38: 20 14       jr   nz,$5A4E		; if it's vespers
5A3A: CF          rst  $08
	8D -> c1a = [0x2d80]
	02 -> c2a = 0x02
	3D -> ca = [0x2d80] == 0x02
	8E -> c1b = [0x3ca9]
	04 -> c2b = 0x04
	3C -> cb = [0x3ca9] < 0x04
	26 -> c = ([0x2d80] == 0x02) && ([0x3ca9] < 0x04)
5A42: 20 03       jr   nz,$5A47	; if it's the second day and malaquias hasn't left the scriptorium
5A44: C3 5B 3E    jp   $3E5B			; indicates that the character doesn't want to search for any route

5A47: D7          rst  $10
	92 01 -> [0x3ce8] = 0x01	; goes to state 1
5A4A: D7
	90 00 -> [0x3ce9] = 0x00	; goes to the church
5A4D: C9          ret

5A4E: CF          rst  $08
	8D -> c1 = [0x2d80]
	03 -> c2 = 0x03
	3C -> c = [0x2d80] < 3
5A52: C2 2C 5B    jp   nz,$5B2C		; if it's the first or second day
5A55: CF          rst  $08
	92 -> c1 = [0x3ce8]
	04 -> c2 = 0x04
	3D -> c = [0x3ce8] == 0x04
5A59: 20 21       jr   nz,$5A7C		; if he's in state 4
5A5B: D7          rst  $10
	99 99 01 -> [0x3c98] = [0x3c98] + 1
5A60: CF          rst  $08
	99 -> c1a = [0x3c98]
	41 -> c2a = 0x41
	3C -> ca = [0x3c98] < 0x41
	9A -> c1b = [0x2dbd]
	40 40 -> c2b = 0x40
	3D -> cb = [0x2dbd] == 0x40
	26 -> c = ([0x3c98] < 0x41) && ([0x2dbd] == 0x40)
5A69: 20 0A       jr   nz,$5A75	; if the parchment hasn't been there long and hasn't changed screen
5A6B: CF          rst  $08
	A4 -> c1 = [0x2def]
	10 -> c2 = 0x10
	2A -> c = [0x2def] & 0x10
5A6F: 20 03       jr   nz,$5A74		; if guillermo doesn't have the parchment
5A71: D7          rst  $10
	92 00 -> [0x3ce8] = 0		; changes berengario's state
5A74: C9          ret

5A75: D7          rst  $10
	92 05 -> [0x3ce8] = 5		; changes berengario's state
5A78: CD 7D 43    call $437D		; disables the counter so the time of day advances automatically
5A7B: C9          ret

5A7C: CF          rst  $08
	92 -> c1 = [0x3ce8]
	05 -> c2 = 0x05
	3D -> c = [0x3ce8] == 0x05
5A80: 20 1B       jr   nz,$5A9D		; if he's in state 5
5A82: D7          rst  $10
	90 40 FE -> [0x3ce9] = 0xfe	; goes towards the abbot's position
5A86: CF          rst  $08
	91 -> c1 = [0x3ce7]
	40 FE -> c2 = 0xfe
	3D -> c1 = [0x3ce7] == 0xfe
5A8B: 20 0F       jr   nz,$5A9C		; if berengario has reached the abbot's position
5A8D:	D7          rst  $10
	99 40 C9 -> [0x3c98] = 0xc9
5A91: D7          rst  $10
	92 00 -> [0x3ce8] = 0		; changes berengario's state
5A94: D7          rst  $10
	A5 01 -> [0x3c94] = 1		; indicates that guillermo has taken the parchment
5A97: D7
	AE AE 01 26 -> [0x3ca5] = [0x3ca5] | 0x01
5A9C: C9          ret

5A9D: CF          rst  $08
	91 -> c1 = [0x3ce7]
	02 -> c2 = 0x02
	3D -> c = [0x3ce7] == 0x02
5AA1: 20 1D       jr   nz,$5AC0		; if he has arrived at his desk in the scriptorium
5AA3: CD ED 43    call $43ED		; checks something related to the parchment
5AA6: 20 18       jr   nz,$5AC0		; if guillermo has taken the parchment
5AA8: D7          rst  $10
	99 00 -> [0x3c98] = 0x00	; resets the counter
5AAB: D7          rst  $10
	92 04 -> [0x3ce8] = 0x04	; goes to state 4
5AAE: CD 61 3E    call $3E61		; compares the distance between guillermo and berengario (if very close returns 0, otherwise != 0)
5AB1: 20 06       jr   nz,$5AB9		; if he's close to guillermo
5AB3: CD 26 50    call $5026		; puts the phrase in the display
5AB6: 04          					LEAVE THE MANUSCRIPT OF VENANTIUS OR I WILL WARN THE ABBOT
5AB7: 18 06       jr   $5ABF
5AB9: D7          rst  $10
	92 05 -> [0x3ce8] = 0x05	; goes to state 5
5ABC: CD 7D 43    call $437D		; disables the counter so the time of day advances automatically
5ABF: C9          ret

5AC0: CF          rst  $08
	AE -> c1a = [0x3ca5]
	40 40 -> c2a = 0x40
	2A -> ca = [0x3ca5] & 0x40
	40 40 -> cb = 0x40
	3D -> cc = ([0x3ca5] & 0x40) == 0x40
	82 -> c1d = [0x303a]
	0D -> c2d = 0x0d
	3E -> cd = [0x303a] >= 0x0d
	26 -> c = (([0x3ca5] & 0x40) == 0x40) && ([0x303a] >= 0x0d)
5ACC: 20 57       jr   nz,$5B25		; if malaquias has told him that berengario can show him the scriptorium and guillermo's height >= 0x0d
5ACE: CF          rst  $08
	AE -> c1 = [0x3ca5]
	10 -> c2 = 0x10
	2A -> c = [0x3ca5] & 0x10
5AD2: 20 25       jr   nz,$5AF9		; if he hadn't told him about the best copyists in the west
5AD4: D7          rst  $10
	90 40 FF -> [0x3ce9] = 0xff	; berengario goes after guillermo
5AD8: CD 61 3E    call $3E61		; compares the distance between guillermo and berengario (if very close returns 0, otherwise != 0)
5ADB: 20 19       jr   nz,$5AF6		; if he's close to guillermo
5ADD: CF          rst  $08
	89 -> c1 = [0x2da1]
	00 -> c2 = 0x00
	3D -> c = [0x2da1] == 0x00
5AE1: 20 10       jr   nz,$5AF3		; if no phrase is being played
5AE3: D7          rst  $10
	91 40 FF -> [0x3ce7] = 0xff	; indicates that berengario has arrived where guillermo is
5AE7: CD BE 08    call $08BE		; discards planned movements and indicates a new movement must be planned
5AEA: D7          rst  $10
	AE AE 10 26 -> [0x3ca5] = [0x3ca5] | 0x10	; indicates that he has already told him about the best copyists
5AEF: CD 26 50    call $5026		; puts the phrase in the display
5AF2: 35          					HERE WORK THE BEST COPYISTS IN THE WEST
5AF3: C3 5B 3E    jp   $3E5B		; indicates that the character doesn't want to search for any route

5AF6: C9          ret

5AF7: 18 2C       jr   $5B25		; this is never reached???

5AF9: CF          rst  $08
	AE -> c1 = [0x3ca5]
	08 -> c2 = 0x08
	2A -> c = [0x3ca5] & 0x08
5AFD: 20 26       jr   nz,$5B25		; if he hasn't told him about venantius
5AFF: D7          rst  $10
	90 02 -> [0x3ce9] = 0x02	; goes to his desk in the scriptorium
5B02: CD 61 3E    call $3E61		; compares the distance between guillermo and berengario (if very close returns 0, otherwise != 0)
5B05: 20 12       jr   nz,$5B19		; if he's close to guillermo
5B07: CF          rst  $08
	91 -> c1a = [0x3ce7]
	02 -> c2a = 0x02
	3D -> ca = [0x3ce7] == 0x02
	89 -> cb = [0x2da1]
	26 -> c = ([0x3ce7] == 0x02) && [0x2da1]
5B0D: 20 09       jr   nz,$5B18		; if berengario has arrived at the scriptorium and no phrase was being played
5B0F: D7          rst  $10
	AE AE 08 26 -> [0x3ca5] = [0x3ca5] | 0x08	; indicates he has already shown where venantius works
5B13: CD 26 50    call $5026		; puts the phrase in the display
	36 							HERE WORKED VENANTIUS
5B18: C9          ret

5B19: CF          rst  $08
	91 -> c1 = [0x3ce7]
	02 -> c2 = 0x02
	3D -> c = [0x3ce7] == 0x02
5B1D: 20 06       jr   nz,$5B25		; if he has arrived at his place in the scriptorium and guillermo hasn't followed him
5B1F: D7          rst  $10
	AE AE 40 80 26 -> [0x3ca5] = [0x3ca5] | 0x80	; ??? is this a game bug??? I think it should be 0x08 instead of 0x80
5B25: D7          rst  $10
	92 00 -> [0x3ce8] = 0x00	; changes berengario's state
5B28: D7          rst  $10
	90 02 -> [0x3ce9] = 0x02	; doesn't move from his work place
5B2B: C9          ret

5B2C: CF          rst  $08
	92 -> c1 = [0x3ce8]
	14 -> c2 = 0x14
	3D -> c = [0x3ce8] == 0x14
5B30: 20 0C       jr   nz,$5B3E		; if he's in state 0x14
5B32: CF          rst  $08
	90 -> c1 = [0x3ce9]
	91 -> c2 = [0x3ce7]
	3D -> c = [0x3ce9] == [0x3ce7]
5B36: 20 05       jr   nz,$5B3D		; if he has arrived at the place he wanted to go
5B38: D7          rst  $10
	90 B2 03 2A -> [0x3ce9] = [0x3c9d] & 0x03 ; moves randomly through the abbey
5B3D: C9          ret

5B3E: CF          rst  $08
	8D -> c1 = [0x2d80]
	04 -> c2 = 0x04
	3D -> c = [0x2d80] == 0x04
5B42: C2 C5 5B    jp   nz,$5BC5		; if it's the fourth day
5B45: CF          rst  $08
	90 -> c1a = [0x3ce9]
	40 FE -> c2a = 0xfe
	3D -> ca = [0x3ce9] == 0xfe
	A6 -> c1b = [0x2e04]
	10 -> c2b = 0x10
	2A -> cb = [0x2e04] & 0x10
	10 -> cc = 0x10
	3D -> cd = ([0x2e04] & 0x10) == 0x10
	26 -> ([0x3ce9] == 0xfe) && (([0x2e04] & 0x10) == 0x10)
5B50: 20 0A       jr   nz,$5B5C	; if bernardo is going after the abbot and the abbot has the parchment
5B52: D7          rst  $10
	92 14 -> [0x3ce8] = 0x14	; changes berengario's state
5B55: D7          rst  $10
	90 01 -> [0x3ce9] = 0x01	; goes to the refectory
5B58: D7          rst  $10
	8C 15 -> [0x3cc7] = 0x15	; changes the abbot's state
5B5B: C9          ret

5B5C: CF          rst  $08
	A8 -> c1a = [0x2e0b]
	10 -> c2a = 0x10
	2A -> ca = [0x2e0b] & 0x10
	10 -> cb = 0x10
	3D -> c = ([0x2e0b] & 0x10) == 0x10
5B62: 20 0B       jr   nz,$5B6F		; if bernardo has the parchment
5B64: D7          rst  $10
	90 40 FE -> [0x3ce9] = 0xfe	; goes after the abbot
5B67: CD 43 7D    call $437D		; disables the counter so the time of day advances automatically
5B6B: D7          rst  $10
	B0 00 -> [0x2e0d] = 0		; changes the mask of objects that bernardo can take
5B6E: C9          ret

5B6F: CF          rst  $08
	B3 -> c1a = [0x3c90]
	01 -> c2a = 0x01
	3D -> ca = [0x3c90] == 0x01
	A6 -> c1b = [0x2e04]
	10 -> c2b = 0x10
	2A -> cb = [0x2e04] & 0x10
	10 -> cc = 0x10
	3D -> cd = ([0x2e04] & 0x10) == 0x10
	2A -> ce = ([0x3c90] == 0x01) || (([0x2e04] & 0x10) == 0x10)
	8C -> c1f = [0x3cc7]
	0B -> c2f = 0x0b
	3D -> cf = [0x3cc7] == 0x0b
	2A -> c = ([0x3c90] == 0x01) || (([0x2e04] & 0x10) == 0x10) || ([0x3cc7] == 0x0b)
5B7D: 20 07       jr  nz,$5B86		; if the parchment is safe or the abbot is going to kick out guillermo
5B7F: D7          rst  $10
	90 02 -> [0x3ce9] = 0x02	; goes to his place in the scriptorium
5B82: D7          rst  $10
	92 14 -> [0x3ce8] = 0x14	; changes bernardo's state
5B85: C9          ret

5B86: D7          rst  $10
	B3 00 -> [0x3c90] = 0x00	; indicates the parchment hasn't been taken from guillermo
5B89: CD 7D 43    call $437D		; disables the counter so the time of day advances automatically
5B8C: CF          rst  $08
	A4 -> c1a = [0x2def]
	10 -> c2a = 0x10
	2A -> ca = [0x2def] & 0x10
	10 -> cb = 0x10
	3D -> c = ([0x2def] & 0x10) == 0x10
5B92: 20 2D       jr   nz,$5BC1		; if guillermo has the parchment
5B94: CF          rst  $08
	92 -> c1 = [0x3ce8]
	07 -> c2 = 0x07
	3D -> c = [0x3ce8] == 0x07
5B98: 20 18       jr   nz,$5BB2		; if he's in state 7
5B9A: D7          rst  $10
	90 40 FF -> [0x3ce9] = 0xff	; goes after guillermo
5B9E: CD 61 3E    call $3E61		; compares the distance between guillermo and bernardo gui (if very close returns 0, otherwise != 0)
5BA1: 20 0D       jr   nz,$5BB0		; if he's close to guillermo
5BA3: CF          rst  $08
	89 -> c1 = [0x2da1]
	00 -> c2 = 0x00
	3D -> c = [0x2da1] == 0x00
5BA7: 20 07       jr   nz,$5BB0		; if not showing a phrase
5BA9: CD 26 50    call $5026		; puts the phrase in the display
	05          				GIVE ME THE MANUSCRIPT, BROTHER WILLIAM
5BAD: CD CE 55    call $55CE		; decreases guillermo's life by 2 units
5BB0: 18 0D       jr   $5BBF

5BB2: CD 61 3E    call $3E61		; compares the distance between guillermo and bernardo gui (if very close returns 0, otherwise != 0)
5BB5: 20 04       jr   nz,$5BBB		; if he's close to guillermo
5BB7: D7          rst  $10
	90 03 -> [0x3ce9] = 0x03	; goes to the monks' cell
5BBA: C9          ret

5BBB: D7          rst  $10
	92 07 -> [0x3ce8] = 0x07	; changes berengario's state
5BBE: C9          ret
5BBF: 18 04       jr   $5BC5

5BC1: D7          rst  $10
	90 40 FC -> [0x3ce9] = 0xfc	; goes after the parchment
5BC5: C9          ret

; ------------------ end of berengario/jorge/bernardo gui logic ----------------

; ------------------ severino/jorge logic ----------------

5BC6: CF          rst  $08
	AD -> c1a = [0x3ca3]
	01 -> c2a = 0x01
	3D -> c = [0x3ca3] == 0x01
5BCA: 20 03       jr   nz,$5BCF
5BCC: C3 5B 3E    jp   $3E5B		; indicates that the character doesn't want to search for any route

5BCF: CF          rst  $08
	8D -> c1a = [0x2d80]
	06 -> c2a = 0x06
	3E -> c = [0x2d80] >= 0x06
5BD3: C2 B0 5C    jp   nz,$5CB0		; if it's day 6 or 7, the character is jorge and not severino
5BD6: CF          rst  $08
	95 -> c1a = [0x3d00]
	0B -> c2a = 0x0b
	3D -> c = [0x3d00] == 0x0b
5BDA: 20 0F       jr   nz,$5BEB		; if he's in state 0x0b
5BDC: CF          rst  $08
	89 -> c1a = [0x2da1]
	00 -> c2a = 0x00
	3D -> c = [0x2da1] == 0x00
5BE0: 20 06       jr   nz,$5BE8		; if not playing a voice
5BE2: CD AF 40    call $40AF		; drops the book
5BE5: D7          rst  $10
	95 0C -> [0x3d00] = 0x0c
5BE8: C3 5B 3E    jp   $3E5B		; indicates that the character doesn't want to search for any route

5BEB: CF          rst  $08
	95 -> c1a = [0x3d00]
	0C -> c2a = 0x0c
	3D -> c = [0x3d00] == 0x0c
5BEF: 20 14       jr   nz,$5C05		; if he's in state 0x0c
5BF1: CF          rst  $08
	A4 -> c1a = [0x2def]
	40 80 -> c2a = 0x80
	2A -> c = ([0x2def] & 0x80) == 0
5BF6: 20 03       jr   nz,$5BFB		; if guillermo doesn't have the book
5BF8: C3 5B 3E    jp   $3E5B		; indicates that the character doesn't want to search for any route

5BFB: CD 26 50    call $5026		; puts the phrase in the display
	2E 							IT IS THE COENA CIPRIANI BY ARISTOTLE. NOW YOU WILL UNDERSTAND WHY I HAD TO PROTECT IT. EVERY WORD WRITTEN BY THE PHILOSOPHER HAS DESTROYED A PART OF CHRISTIAN KNOWLEDGE. I KNOW I HAVE ACTED FOLLOWING THE LORD'S WILL... READ IT THEN, BROTHER WILLIAM. AFTERWARDS I WILL SHOW IT TO YOU BOY
5BFF: D7       ld   l,$D7
	95 0D -> [0x3d00] = 0x0d
5C02: C3 5B 3E    jp   $3E5B		; indicates that the character doesn't want to search for any route

5C05: CF          rst  $08
	95 -> c1a = [0x3d00]
	0D -> c2a = 0x0d
	3D -> c = [0x3d00] = 0x0d	; if he's in state 0x0d
5C09: 20 31       jr   nz,$5C3C
5C0B: CF          rst  $08
	A4 -> c1a = [0x2def]
	40 40 -> c2a = 0x40
	2A -> c = ([0x2def] & 0x40) == 0
5C10: 20 1A       jr   nz,$5C2C		; if guillermo doesn't have the gloves
5C12: CF          rst  $08
	9C -> c1a = [0x3c97]
	00 -> c2a = 0x00
	3D -> c = [0x3c97] == 0x00
5C16: 20 11       jr   nz,$5C29		; if guillermo is still alive
5C18: CF          rst  $08
	9A -> c1a = [0x2dbd]
	72 -> c2a = 0x72
	3D -> ca = [0x2dbd] == 0x72
	89 -> cb = [0x2da1]
	2A -> c = ([0x2dbd] == 0x72) || ([0x2da1] == 0x00)
5C1E: 20 06       jr   nz,$5C26		; if he has exited to the mirror room or has finished playing the phrase
5C20: D7          rst  $10
	BD 40 FF -> [0x3c85] = 0xff ; sets the counter to kill guillermo in the next logic execution for reading the book without gloves
5C24: 18 03       jr   $5C29		; indicates that the logic execution has finished

5C26: D7          rst  $10
	BD 01 -> [0x3c85] = 0x01 	; starts the counter to kill guillermo for reading the book without gloves
5C29: C3 5B 3E    jp   $3E5B		; indicates that the character doesn't want to search for any route

5C2C: CF          rst  $08
	89 -> c1a = [0x2da1]
	00 -> c2a = 0x00
	3D -> c = [0x2da1] == 0x00
5C30: 20 07       jr   nz,$5C39		; if no phrase is being played
5C32: CD 26 50    call $5026		; puts the phrase in the display
	23							VENERABLE JORGE, YOU CANNOT SEE IT, BUT MY MASTER IS WEARING GLOVES. TO SEPARATE THE PAGES HE WOULD HAVE TO WET HIS FINGERS ON HIS TONGUE, UNTIL HE HAD RECEIVED ENOUGH POISON
5C36: D7          rst  $10
	95 0E -> [0x3d00] = 0x0e
5C39: C3 5B 3E    jp   $3E5B		; indicates that the character doesn't want to search for any route

5C3C: CF          rst  $08
	95 -> c1a = [0x3d00]
	0E -> c2a = 0x0e
	3D -> c = [0x3d00] == 0x0e
5C40: 20 13       jr   nz,$5C55		; if he's in state 0x0e
5C42: CF          rst  $08
	89 -> c1a = [0x2da1]
	00 -> c2a = 0x00
	3D -> c = [0x2da1] == 0x00
5C46: 20 0A       jr   nz,$5C52		; if no phrase is being played
5C48: D7          rst  $10
	99 00 -> [0x3c98] = 0x00
5C4B: D7          rst  $10
	95 0F -> [0x3d00] = 0x0f
5C4E: CD 26 50    call $5026		; puts the phrase in the display
	2F 							IT WAS A GOOD IDEA, WASN'T IT?; BUT IT IS TOO LATE
5C52: C3 5B 3E    jp   $3E5B		; indicates that the character doesn't want to search for any route

5C55: CF          rst  $08
	95 -> c1a = [0x3d00]
	0F -> c2a = 0x0f
	3D -> c = [0x3d00] == 0x0f
5C59: 20 1E       jr   nz,$5C79
5C5B: D7          rst  $10
	99 99 01 2B -> [0x3c98] = [0x3c98] + 1
5C60: CF          rst  $08
	99 -> c1a = [0x3c98]
	28 -> c2a = 0x28
	3D -> c = [0x3c98] == 0x28
5C64: 20 10       jr   nz,$5C76		; if the counter has reached the limit
5C66: CD 6C 1A    call $1A6C		; hides the game area
5C69: D7          rst  $10
	93 04 -> [0x3d01] = 0x04
5C6C: CD 48 42    call $4248		; turns off the screen light and takes the book from guillermo
5C6F: D7          rst  $10
	BC 00 -> [0x416e] = 0x00	; ???
5C72: D7          rst  $10
	95 10 -> [0x3d00] = 0x10
5C75: C9          ret

5C76: C3 5B 3E    jp   $3E5B		; indicates that the character doesn't want to search for any route

5C79: CF          rst  $08
	95 -> c1a = [0x3d00]
	10 -> c2a = 0x10
	3D -> c = [0x3d00] == 0x10
5C7D: 20 1C       jr   nz,$5C9B
5C7F: CF          rst  $08
	94 -> c1a = [0x3cff]
	04 -> c2a = 0x04
	2D -> ca = [0x3cff] - 0x04
	9A -> c1b = [0x2dbd]
	67 -> c2b = 0x67
	3D -> cb = [0x2dbd] == 0x67
	26 -> cc = (([0x3cff] - 0x04) == 0) && ([0x2dbd] == 0x67)
	82 -> c1d = [0x303a]
	1E -> c2d = 0x1e
	3C -> cd = [0x303a] < 0x1e
	26 -> c = (([0x3cff] - 0x04) == 0) && ([0x2dbd] == 0x67) && ([0x303a] < 0x1e)
5C8B: 20 0D       jr   nz,$5C9A		; if jorge has reached his destination and guillermo is in the room where jorge goes with the book and approaches him
5C8D: D7          rst  $10
	B9 00 -> [0x3ca7] = 0x00	; indicates that the investigation has been completed
5C90: D7          rst  $10
	AD 01 -> [0x3ca3] = 0x01	; indicates that jorge has died
5C93: CD 1B 50    call $501B		; writes the phrase in the display
	24							HE IS EATING THE BOOK, MASTER
5C97: D7          rst  $10
	9C 01 -> [0x3c97] = 0x01	; indicates that the investigation has concluded
5C9A: C9          ret

5C9B: CF          rst  $08
	9A -> c1a = [0x2dbd]
	73 -> c2a = 0x73
	3D -> c = [0x2dbd] == 0x73
5C9F: 20 0C       jr   nz,$5CAD		; if he's in the room behind the mirror, gives him a bonus
5CA1: D7          rst  $10
	C0 C0 08 26 -> [0x2dbf] = [0x2dbf] | 0x08
5CA6: CD 1B 50	  call $501B		; writes the phrase in the display
	21 							IT IS YOU, WILLIAM... COME IN, I WAS WAITING FOR YOU. TAKE IT, HERE IS YOUR REWARD
5CAA: D7
	95 0B -> [0x3d00] = 0x0b	; starts the state of the final sequence
5CAD: C3 5B 3E    jp   $3E5B		; indicates that the character doesn't want to search for any route


; arrives here day < 6 (if it's severino)
5CB0: CF          rst  $08
	88 -> c1a = [0x2d81]
	00 -> c2a = 0x00
	3D -> ca = [0x2d81] == 0x00
	88 -> c1b = [0x2d81]
	06 -> c2b = 0x06
	3D -> cb = [0x2d81] == 0x06
	2A -> c = ([0x2d81] == 0x00) || ([0x2d81] == 0x06)
5CB8: 20 07       jr   nz,$5CC1		; if it's night or compline
5CBA: D7          rst  $10
	94 02 -> [0x3cff] = 0x02	; goes to his cell
5CBD: D7          rst  $10
	93 02 -> [0x3d01] = 0x02
5CC0: C9          ret

5CC1: CF          rst  $08
	88 -> c1a = [0x2d81]
	01 -> c2a = 0x01
	3D -> c = [0x2d81] == 0x01
5CC5: 20 36       jr   nz,$5CFD		; if it's prime
5CC7: CF          rst  $08
	89 -> c1a = [0x2da1]
	01 -> c2a = 0x01
	3E -> c = [0x2da1] >= 0x01
	93 -> c1b = [0x3d01]
	40 FF -> c2b = 0xff
	3D -> c = [0x3d01] == 0xff
	26 -> c = ([0x2da1] >= 0x01) && ([0x3d01] == 0xff)
5CD0: 20 01       jr  nz,$5CD3		; if playing a voice and going after guillermo, exit
5CD2: C9          ret

5CD3: D7          rst  $10
	93 00 -> [0x3d01] = 0x00	; goes to the church
5CD6: CF          rst  $08
	8D -> c1a = [0x2d80]
	05 -> c2a = 0x05
	3D -> ca = [0x2d80] == 0x05
	B1 -> c1b = [0x3ca4]
	00 -> c2b = 0x00
	3D -> cb = [0x3ca4] == 0x00
	26 -> c = ([0x2d80] == 0x05) && ([0x3ca4] == 0x00)
5CDE: 20 1C       jr   nz,$5CFC		; if it's the fifth day and guillermo is not in the left wing of the abbey
5CE0: CF          rst  $08
	80 -> c1a = [0x3038]
	60 -> c2a = 0x60
	3C -> c = [0x3038] < 0x60
5CE4: 20 04       jr   nz,$5CEA		; if guillermo is in the left wing of the abbey
5CE6: D7          rst  $10
	B1 01 -> [0x3ca4] = 0x01	; indicates that guillermo is in the left wing of the abbey
5CE9: C9          ret

5CEA: D7          rst  $10
	93 40 FF -> [0x3d01] = 0xff	; goes after guillermo
5CEE: CF          rst  $08
	94 -> c1a = [0x3cff]
	40 FF -> c2a = 0xff
	3D -> c = [0x3cff] == 0xff
5CF3: 20 07       jr   nz,$5CFC			; if he has reached where guillermo is
5CF5: CD 1B 50    call $501B			; writes the phrase in the display
	0F								LISTEN BROTHER, I HAVE FOUND A STRANGE BOOK IN MY CELL
5CF9: D7          rst  $10
	B1 01 -> [0x3ca4] = 0x01	; indicates he has already given the message
5CFB: 01
5CFC: C9          ret

5CFD: CF          rst  $08
	88 -> c1a = [0x2d81]
	03 -> c2a = 0x03
	3D -> c = [0x2d81] == 0x03
5D01: 20 04       jr   nz,$5D07			; if it's sext
5D03: D7          rst  $10
	93 01 -> [0x3d01] = 0x01
5D06: C9          ret

5D07: CF          rst  $08
	88 -> c1a = [0x2d81]
	05 -> c2a = 0x05
	3C -> c = [0x2d81] < 0x05
5D0B: C2 9D 5D    jp   nz,$5D9D		; if it's not yet vespers
5D0E: CF          rst  $08
	AE -> c1a = [0x3ca5]
	02 -> c1b = 0x02
	2A -> ca = [0x3ca5] & 0x02
	94 -> c1b = [0x3cff]
	02 -> c2b = 0x02
	3E -> cb = [0x3cff] >= 0x02
	26 -> cc = (([0x3ca5] & 0x02) == 0) && ([0x3cff] >= 0x02)
	8D -> c1d = [0x2d80]
	02 -> c2d = 0x02
	3E -> cd = [0x2d80] >= 0x02
	26 -> ce = ((([0x3ca5] & 0x02) == 0) && ([0x3cff] >= 0x02)) && ([0x2d80] >= 0x02)
	8B -> c1f = [0x3cc8]
	40 FF -> c2f = 0xff
	3C -> cf = [0x3cc8] < 0xff
	26 -> c = (((([0x3ca5] & 0x02) == 0) && ([0x3cff] >= 0x02)) && ([0x2d80] >= 0x02)) && ([0x3cc8] < 0xff)
5D1F: 20 37       jp   nz,$5D58		; if not going to his cell, if walking around, if the day is >= 2 and if the abbot is not going after guillermo
5D21: CF          rst  $08
	AE -> c1a = [0x3ca5]
	04 -> c2a = 0x04
	2A -> ca = [0x3ca5] & 0x04
	89 -> cb = [0x2da1]
	26 -> c = (([0x3ca5] & 0x04) == 0) && ([0x2da1] == 0)
5D27: 20 11       jr   nz,$5D3A		; if severino hasn't introduced himself and no voice is being played
5D29: CD 61 3E    call $3E61		; compares the distance between guillermo and severino (if very close returns 0, otherwise != 0)
5D2C: 20 0C       jr   nz,$5D3A		; if severino is close to guillermo
5D2E: D7          rst  $10
	AE 04 -> [0x3ca5] = 0x04
5D31: D7          rst  $10
	93 40 FF -> [0x3d01] = 0xff	; goes after guillermo
5D35: CD 26 50    call $5026		; puts the phrase in the display
	37							VENERABLE BROTHER, I AM SEVERINUS, THE PERSON IN CHARGE OF THE HOSPITAL. I WANT TO WARN YOU THAT IN THIS ABBEY VERY STRANGE THINGS HAPPEN. SOMEONE DOES NOT WANT THE MONKS TO DECIDE FOR THEMSELVES WHAT THEY SHOULD KNOW
5D39: C9          ret

5D3A: CF          rst  $08
	AE -> c1a = [0x3ca5]
	04 -> c2a = 0x04
	2A -> ca = [0x3ca5] & 0x04
	04 -> cb = 0x04
	3D -> c = ([0x3ca5] & 0x04) == 0x04
5D40: 20 16       jr   nz,$5D58		; if severino has introduced himself, continue
5D42: D7          rst  $10
	93 40 FF -> [0x3d01] = 0xff	; follows guillermo
5D46: CF          rst  $08
	89 -> c1a = [0x2da1]
	00 -> c2a = 0x00
	3D -> c = [0x2da1] == 0x00
5D4A: 20 0B       jr   nz,$5D57		; if he has finished speaking
5D4C: D7          rst  $10
	93 02 -> [0x3d01] = 0x02	; goes to his cell
5D4F: D7          rst  $10
	94 03 -> [0x3cff] = 0x03
5D52: D7          rst  $10
	AE AE 02 26 -> [0x3ca5] = [0x3ca5] | 0x02	; indicates that he's going to his cell
5D57: C9          ret

5D58: CF          rst  $08
	94 -> c1a = [0x3cff]
	40 FF -> c2a = 0xff
	3D -> c = [0x3cff] == 0xff
5D5D: 20 0E       jr   nz,$5D6D		; if he has reached guillermo's position
5D5F: CF          rst  $08
	89 -> c1a = [0x2da1]
	00 -> c2a = 0x00
	3D -> c = [0x2da1] == 0x00
5D63: 20 07       jr   nz,$5D6C		; if no voice is being played
5D65: CD 26 50    call $5026		; puts the phrase in the marker
	26 							IT IS VERY STRANGE, BROTHER GUILLERMO. BERENGARIO HAD BLACK SPOTS ON HIS TONGUE AND FINGERS
5D69: D7          rst  $10
	9B 01 -> [0x3c9a] = 0x01	; indicates that upon finishing the phrase the time of day advances
5D6C: C9          ret

5D6D: CF          rst  $08
	94 -> c1a = [0x3cff]		; if he has reached his cell
	02 -> c2a = 0x02
	3D -> c = [0x3cff] == 0x02
5D71: 20 26       jr   nz,$5D99
5D73: CF          rst  $08
	8D -> c1a = [0x2d80]
	05 -> c2a = 0x05
	3D -> c = [0x2d80] == 0x05
5D77: 20 03       jr   nz,$5D7C		; if it's the fifth day
5D79: C3 5B 3E    jp   $3E5B		; indicates that the character doesn't want to find any route

5D7C: CF          rst  $08
	88 -> c1a = [0x2d81]
	02 -> c2a = 0x02
	3D -> ca = [0x2d81] == 0x02
	8D -> c1b = [0x2d80]
	04 -> c2b = 0x04
	3D -> cb = [0x2d80] == 0x04
	26 -> c = ([0x2d81] == 0x02) && ([0x2d80] == 0x04)
5D84: 20 0E       jr   nz,$5D94		; if it's terce of the fourth day
5D86: D7          rst  $10
	93 40 FF -> [0x3d01] = 0xff	; goes after guillermo
5D8A: CD 61 3E    call $3E61		; compares the distance between guillermo and severino (if very close returns 0, otherwise != 0)
5D8D: 20 04       jr   nz,$5D93		; if he's far away, exits
5D8F: CD 26 50    call $5026		; puts the phrase in the marker
	2C         					WAIT, BROTHER
5D93: C9          ret

5D94: D7          rst  $10
	93 03 -> [0x3d01] = 0x03	; goes to the room next to the monks' cells
5D97: 18 03       jr   $5D9C
5D99: D7          rst  $10
	93 02 -> [0x3d01] = 0x02	; goes to his cell
5D9C: C9          ret

5D9D: D7          rst  $10
	93 00 -> [0x3d01] = 0x00	; goes to the church
5DA0: C9          ret
; -------------------- end of severino/jorge logic ----------------------------------------

; -------------------- start of adso logic ----------------------------------------
5DA1: CF          rst  $08
	A4 -> c1a = [0x2def]
	10 -> c2a = 0x10
	2A -> ca = [0x2def] & 0x10
	10 -> cb = 0x10
	3D -> c = ([0x2def] & 0x10) == 0x10
5DA7: 20 03       jr   nz,$5DAC		; if guillermo has the parchment
5DA9: D7          rst  $10
	B3 00 -> [0x3c90] = 0x00	; indicates it

5DAC: CF          rst  $08
	B4 -> ca = [0x3c8c]
	01 -> cb = 0x01
	3D -> [0x3c8c] == 0x01		; if the night is ending, informs of it
5DB0: 20 04       jr   nz,$5DB6
5DB2: CD 26 50    call $5026		; puts the phrase in the marker
	27          				IT WILL BE DAWN SOON, MASTER

5DB6: CF          rst  $08
	B5 -> ca = [0x3c8d]
	01 -> cb = 0x01
	3D -> c = [0x3c8d] == 0x01	; if the lamp state has changed to 1
5DBA: 20 07       jr   nz,$5DC3
5DBC: D7          rst  $10
	B5 00 -> [0x3c8d] = 0x00	; indicates that the lamp state change has been processed
5DBF: CD 1B 50    call $501B		; writes the phrase in the marker
	28 							THE LAMP IS RUNNING OUT

5DC3: CF          rst  $08
	B5 -> ca = [0x3c8d]			; if the lamp state has changed to 2
	02 -> cb = 0x02
	3D -> c = [0x3c8d] == 0x02
5DC7: 20 13       jr   nz,$5DDC
5DC9: D7          rst  $10
	B5 00 -> [0x3c8d] = 0		; indicates that the lamp state change has been processed
5DCC: D7          rst  $10
	B6 32 -> [0x3c8e] = 0x32	; initiates the counter for the time they can go in the dark
5DCF: D7          rst  $10
	B7 00 -> [0x3c8b] = 0x00	; indicates that the lamp is no longer being used?
5DD2: CD 6C 1A    call $1A6C		; hides the game area
5DD5: CD F7 3F    call $3FF7		; takes the lamp from adso and resets the counters?
5DD8: CD 1B 50    call $501B		; writes the phrase in the marker
	2A 							THE LAMP HAS RUN OUT

5DDC: CF          rst  $08
	9C -> ca = [0x3c97]
	00 -> cb = 0x00
	3D -> c = [0x3c97] == 0
5DE0: 20 4A       jr   nz,$5E2C		; if 0x3c97 == 0

; if guillermo hasn't died, execute this
5DE2: CF          rst  $08
	B6 -> [0x3c8e]
	01 -> 0x01
	3E -> [0x3c8e] >= 0x01
5DE6: 20 20       jr   nz,$5E08		; if the darkness time counter has been activated
5DE8: CF          rst  $08
	82 -> ca = [0x303a]
	40 18 -> cb = 0x18
	3C -> [0x303a] < 0x18
5DED: 20 04       jr   nz,$5DF3		; guillermo's height in the scenario < 0x18, i.e., if he has left the library
5DEF: D7          rst  $10
	B6 00 -> [0x3c8e] = 0x00	; if he has left the library, sets the counter to 0
5DF2: C9          ret

; arrives here if he's still in the library
5DF3: D7          rst  $10
	B6 B6 01 2D -> [0x3c8e] = [0x3c8e] - 0x01	; decrements the counter for the time they can go in the dark
5DF8: CF          rst  $08
	B6 -> c1a = [0x3c8e]
	01 -> c2a = 0x01
	3D -> [0x3c8e] == 0x01
5DFC: 20 08       jr   nz,$5E06		; if it's not 1, jumps
5DFE: D7          rst  $10
	9C 01 -> [0x3c97] = 0x01	; indicates that guillermo has died
5E01: CD 1B 50    call $501B		; writes the phrase in the marker
	2B							WE WILL NEVER GET OUT OF HERE
5E05: C9          ret

; arrives here if the darkness time counter is active, but hasn't finished yet
5E06: 18 24       jr   $5E2C

; arrives here if the darkness time counter hasn't been activated
5E08: CF          rst  $08
	85 -> c1a = [0x3049]
	40 18 -> c2a = 0x18
	3E -> c = [0x3049] >= 0x18
5E0D: 20 17       jr   nz,$5E26			; if adso's height >= 0x18 (if adso just entered the library)
5E0F: D7          rst  $10
	96 40 FF -> [0x3d13] = 0xff		; indicates that adso follows guillermo
5E13: CF          rst  $08
	B8 -> c1a = [0x2df3]
	40 80 -> c2a = 0x80
	2A -> c = [0x2df3] & 0x80		; if adso doesn't have the lamp
5E18: 20 08       jr   nz,$5E22
5E1A: CD 1B 50    call $501B			; writes the phrase in the marker
	13								WE MUST FIND A LAMP, MASTER
5E1E: D7          rst  $10
	B6 64 -> [0x3c8e] = 0x64		; activates the counter for the time they can be in the dark
5E21: C9          ret

; arrives here if adso has the lamp and just entered the library
5E22: D7          rst  $10
	B7 01 -> [0x3c8b] = 0x01
5E25: C9          ret

; arrives here if adso is not in the library
5E26: D7          rst  $10
	B7 00 -> [0x3c8b] = 0x00		; indicates that the lamp is not being used
5E29: D7          rst  $10
	B6 00 -> [0x3c8e] = 0x00		; cancels the counter for the time they can go in the dark

; also arrives here if guillermo has died
5E2C: CF          rst  $08
	88 -> c1a = [0x2d81]
	03 -> c2a = 0x03
	3D -> c = [0x2d81] == 0x03
5E30: 20 0C       jr   nz,$5E3E			; if it's sext
5E32: D7          rst  $10
	96 01 -> [0x3d13] = 0x01		; goes to the refectory
5E35: D7          rst  $10
	A3 07 -> [0x3c96] = 0x07
5E38: D7          rst  $10
	A2 0C -> [0x3f0e] = 0x0c		; changes the phrase to display to WE MUST GO TO THE REFECTORY, MASTER
5E3B: C3 E5 5E    jp   $5EE5

5E3E: CF          rst  $08
	88 -> c1a = [0x2d81]
	05 -> c2a = 0x05
	3D -> ca = [0x2d81] == 0x05
	88 -> c1b = [0x2d81]
	01 -> c2b = 0x01
	3D -> cb = [0x2d81] == 0x01
	2A -> c = ([0x2d81] == 0x05) || ([0x2d81] == 0x01)
5E46: 20 0C       jr   nz,$5E54		; if it's prime or vespers
5E48: D7          rst  $10
	96 00 -> [0x3d13] = 0x00	; goes to the church
5E4B: D7          rst  $10
	A3 01 -> [0x3c96] = 0x01
5E4E: D7          rst $10
	A2 0B -> [0x3f0e] = 0x0b	; changes the phrase to display to WE MUST GO TO THE CHURCH, MASTER
5E51: C3 E5 5E    jp   $5EE5

; arrives here if it's not prime nor vespers nor sext
5E54: CF          rst  $08
	88 -> c1a = [0x2d81]
	06 -> c2a = 0x06
	3D -> c = [0x2d81] == 0x06
5E58: 20 07       jr   nz,$5E61		; if it's compline
5E5A: D7          rst  $10
	98 06 -> [0x3d12] = 0x06	; changes adso's state
5E5D: D7       ld   b,$D7
	96 02 -> [0x3d13] = 0x02	; heads to the cell
5E60: C9          ret

; arrives here if it's not prime nor vespers nor sext nor compline
5E61: CF          rst  $08
	88 -> c1a = [0x2d81]
	00 -> c2a = 0x00
	3D -> c = [0x2d81] == 0x00
5E65: C2 E0 5E    jp   nz,$5EE0		; if it's nighttime
5E68: CF          rst  $08
	98 -> c1a = [0x3d12]
	04 -> c2a = 0x04
	3D -> c = [0x3d12] == 0x04
5E6C: 20 40       jr   nz,$5EAE		; if the state is 4 (was in the cell waiting for answer)
5E6E: CF          rst  $08
	9A -> c1a = [0x2dbd]
	37 -> c2a = 0x37
	3D -> c = [0x2dbd] == 0x37
5E72: 20 03       jr   nz,$5E77		; if screen number 0x37 is shown (outside our cell)
5E74: D7          rst  $10
	9B 02 -> [0x3c9a] = 0x02	; advances to the next day

5E77: CF          rst  $08
	89 -> c1a = [0x2da1]
	00 -> c2a = 0x00
	3D -> c = [0x2da1] == 0x00
5E7B: 20 30       jr   nz,$5EAD		; if no voice is being played
5E7D: CF          rst  $08
	A1 -> c1a = [0x3c99]
	64 -> c2a = 0x64
	3E -> c = [0x3c99] >= 0x64	; if the answer counter is >= 100
5E81: 20 04       jr   nz,$5E87
5E83: D7          rst  $10
	9B 02 -> [0x3c9a] = 0x02	; if we take too long to answer, advances to the next day
5E86: C9          ret

5E87: D7          rst  $10
	A1 A1 01 2B -> [0x3c99] = [0x3c99] + 0x01	; increments the counter
5E8C: CD 65 50    call $5065		; prints S:N or clears S:N depending on bit 1 of 0x3c99
5E8F: CF          rst  $08
	A1 -> c1a = [0x3c99]
	01 -> c2a = 0x01
	2A -> ca = [0x3c99] & 0x01
	01 -> cb = 0x01
	3D -> c = ([0x3c99] & 0x01) == 0x01
5E95: 20 16       jr   nz,$5EAD		; depending on bit 1, reads keyboard state
5E97: 3E 3C       ld   a,$3C
5E99: CD 82 34    call $3482		; checks if S has been pressed
5E9C: 20 0C       jr   nz,$5EAA
5E9E: 3E 2E       ld   a,$2E
5EA0: CD 82 34    call $3482		; checks if N has been pressed
5EA3: 20 01       jr   nz,$5EA6
5EA5: C9          ret

; arrives here if N is pressed
5EA6: D7          rst  $10
	98 05 -> [0x3d12] = 0x05
5EA9: C9          ret

; arrives here if S is pressed
5EAA: D7          rst  $10
	9B 02 -> [0x3c9a] = 0x02	; advances to the next day
5EAD: C9          ret

; arrives here if it's nighttime and 0x3d12 was not 4
5EAE: D7          rst  $10
	96 40 FF -> [0x3d13] = 0xff	; follows guillermo
5EB2: CF          rst  $08
	98 -> c1a = [0x3d12]
	05 -> c2a = 0x05
	3D -> c = [0x3d12] == 0x05
5EB6: 20 0B       jr   nz,$5EC3		; if the state is 5 (we don't sleep)
5EB8: CF          rst  $08
	9A -> c1a = [0x2dbd]
	40 3E -> c2a = 0x03e
	3D -> c = [0x2dbd] == 0x3e
5EBD: 20 01       jr   nz,$5EC0			; if we're on screen 0x3e, jumps
5EBF: C9          ret

; arrives here if we're not in our cell
5EC0: D7          rst  $10
	98 06 -> [0x3d12] = 0x06		; if we leave our cell, changes to state 6

5EC3: CF          rst  $08
	98 -> c1a = [0x3d12]
	06 -> c2a = 0x06
	3D -> c = [0x3d12] == 0x06
5EC7: 20 17       jr   nz,$5EE0
5EC9: CD 61 3E    call $3E61			; compares the distance between guillermo and adso (if very close returns 0, otherwise != 0)
5ECC: 20 11       jr   nz,$5EDF			; if not close to guillermo, jumps
5ECE: CF          rst  $08
	9A -> c1a = [0x2dbd]
	40 3E -> c2a = 0x03e
	3D -> c = [0x2dbd] == 0x3e
5ED3: 20 0A       jr   nz,$5EDF			; if we're on screen 0x3e (our cell)
5ED5: D7          rst  $10
	A1 00 -> [0x3c99] = 0x00		; initiates the counter for guillermo's response time to the sleep question
5ED8: D7          rst  $10
	98 04 -> [0x3d12] = 0x04
5EDB: CD 26 50    call $5026			; puts the phrase in the marker
	12					a			SHALL WE SLEEP?, MASTER
5EDF: C9          ret

5EE0: D7          rst  $10
	96 40 FF -> [0x3d13] = 0xff		; follows guillermo
5EE4: C9          ret


5EE5: CF          rst  $08
	98 -> c1a = [0x3d12]
	A3 -> c2a = [0x3c96]
	3D -> c = c1a == c2a
5EE9: 20 01       jr   nz,$5EEC		; if they're equal, exits
5EEB: C9          ret

5EEC: CD 61 3E    call $3E61		; compares the distance between guillermo and adso (if very close returns 0, otherwise != 0)
5EEF: 20 03       jr   nz,$5EF4		; if not close to guillermo, jumps
5EF1: CD 0B 3F    call $3F0B		; puts a phrase in the marker (the phrase changes depending on the state)
5EF4: D7          rst  $10
	98 A3 -> [0x3d12] = [0x3c96]
5EF7: C9          ret

5EF8: C9          ret
; ------------ end of adso logic ----------------------------------------

; ------------ logic dependent on the time of day ----------------------------------------

; if the time of day has changed, execute some actions depending on the time of day
5EF9: CF          rst  $08			; interprets the commands following this instruction
	88 -> c1 = [0x2d81]
	AA -> c2 = [0x3c95]
	3D -> compares c1 and c2
5EFD: 20 03       jr   nz,$5F02		; if the time of day hasn't changed, exits
5EFF: C9          ret

5F00: 18 1C       jr   $5F1E		; jumps to ret (???)

5F02: D7          rst  $10			; interprets the commands following this instruction
	AA 88 -> [0x3c95] = [0x2d81]; puts the time of day in 0x3c95
5F05: CD C8 41    call $41C8		; [0x3c93] = next data
5F08: 00							; data used by previous call
5F09: CF          rst  $08			; interprets the commands following this instruction
	88 -> c = [0x2d81]
5F0B: CD 10 3F    call $3F10		; jumps to a routine depending on the current time of day (in c)
	5F1F -> 0 (night)
	5F3B -> 1 (prime)
	5F8C -> 2 (terce)
	5F93 -> 3 (sext)
	5FA6 -> 4 (none)
	5FB9 -> 5 (vespers)
	5FBD -> 6 (compline)
	0000
5F1E: C9          ret

; routine called at night
5F1F: CF          rst  $08			; interprets the commands following this instruction
	8D -> c1 = [0x2d80]
	05 -> c2 = 0x05
	3D -> compares c1 and c2
5F23: 20 06       jr   nz,$5F2B		; if it's not day 5, jumps
5F25: CD 31 41    call $4131		; puts guillermo's glasses in the illuminated room of the labyrinth
5F28: CD 13 41    call $4113		; puts the key to the altar room on the altar

5F2B: CF          rst  $08			; interprets the commands following this instruction
	8D -> c1 = [0x2d80]
	06 -> c2 = 0x06
	3D -> compares c1 and c2
5F2F: 20 09       jr   nz,$5F3A		; if it's not day 6, jumps
5F31: CD 27 41    call $4127		; puts the key to severino's room on malaquias's table
5F34: CD 68 40    call $4068		; changes severino's face to jorge's and appears in the mirror room
5F37: D7          rst  $10			; interprets the commands following this instruction
	AD 00 -> [0x3ca3] = 0		; indicates that jorge is active
5F3A: C9          ret

; routine called at prime
5F3B: CD 6B 3F    call $3F6B		; draws and clears the spiral
5F3E: D7          rst  $10			; interprets the commands following this instruction
	9E 40 EF-> [0x3ca6] = 0xef	; modifies the mask of doors that can be opened
5F42: CD 44 3F    call $3F44		; selects palette 2
5F45: CD 85 35    call $3585		; opens the doors of the left wing of the abbey
5F48: CD 0C 10    call $100C		; sound
5F4B: CF          rst  $08			; interprets the commands following this instruction
	8D -> c1 = [0x2d80]
	03 -> c2 = 0x03
	3E -> c1 >= c2?
5F4F: 20 06       jr   nz,$5F57		; if we haven't reached the third day, jumps
5F51: CD F7 3F    call $3FF7		; takes the lamp from adso and resets the lamp counters
5F54: CD 00 41    call $4100		; if the lamp was missing, it appears in the kitchen

5F57: CF          rst  $08			; interprets the commands following this instruction
	8D -> c1 = [0x2d80]
	02 -> c2 = 0x02
	3D -> compares c1 and c2
5F5B: 20 03       jr   nz,$5F60		; if it's not day 2, jumps
5F5D: CD 37 40    call $4037		; the lenses disappear

5F60: CF          rst  $08			; interprets the commands following this instruction
	8D -> c1 = [0x2d80]
	03 -> c2 = 0x03
	3D -> compares c1 and c2
5F64: 20 18       jr   nz,$5F7E		; if it's not day 3, jumps
5F66: CD F1 40    call $40F1		; gives the book to jorge
5F69: CD 78 40    call $4078		; changes berengario's face to jorge's and places him at the end of the cell corridor
5F6C: D7          rst  $10			; interprets the commands following this instruction
	A8 00 -> [0x2e0b] = 0x00	; berengario/jorge has no object
5F6F: D7          rst  $10			; interprets the commands following this instruction
	A6 00 -> [0x2e04] = 0x00	; the abbot has no object
5F72: CF          rst  $08			; interprets the commands following this instruction
	A4 -> c1 = [0x2def]
	10 -> c2 = 0x10
	2A -> c = c1 & c2
5F76: 20 06       jr   nz,$5F7E		; if guillermo has the parchment, jumps
5F78: CD DD 40    call $40DD		; puts the parchment in the room behind the mirror
5F7B: D7          rst  $10			; interprets the commands following this instruction
	B3 01 -> [0x3c90] = 0x01	; indicates that guillermo doesn't have the parchment
5F7E: CF          rst $08			; interprets the commands following this instruction
	8D -> c1a = [0x2d80]
	05 -> c2a = 5
	3D -> ca = compares c1 and c2	; ca = if it's the fifth day
	A4 -> c1b = [0x2def]
	08 -> c2b = 0x08
	2A -> cb = c1b & c2b		; cb = 0 if we don't have the key to the abbot's room
	26 -> c = ca & cb			; c = if it's the fifth day and we don't have the key to the abbot's room
5F86: 20 03       jr   nz,$5F8B		; if it's the fifth day and we don't have the key to the abbot's room, it disappears
5F88: CD 1D 41    call $411D		; key 1 disappears
5F8B: C9          ret

; routine called at terce
5F8C: CD 6B 3F    call $3F6B		; draws and clears the spiral
5F8F: CD 11 10    call $1011		; puts the bell sound on channel 1
5F92: C9          ret

; routine called at sext
5F93: CD 0C 10    call $100C
5F96: CF          rst  $08			; interprets the commands following this instruction
	8D -> c1 = [0x2d80]
	04 -> c2 = 0x04
	3D -> compares c1 and c2
5F9A: 20 09       jr   nz,$5FA5		; if it's not the fourth day, exits
5F9C: CD 58 40    call $4058		; bernardo appears at the church entrance
5F9F: D7          rst  $10			; interprets the commands following this instruction
	AB 00 -> [0x3ca1] = 0x00
5FA2: D7          rst  $10			; interprets the commands following this instruction
	B0 10 -> [0x2e0d] = 0x10
5FA5: C9          ret

; routine called at none
5FA6: CD 6B 3F    call $3F6B		; draws and clears the spiral
5FA9: CF          rst  $08			; interprets the commands following this instruction
	8D -> c1 = [0x2d80]
	03 -> c2 = 0x03
	3D -> compares c1 and c2
5FAD: 20 06       jr   nz,$5FB5		; if it's not the third day, jumps
5FAF: D7          rst  $10			; interprets the commands following this instruction
	AB 01 -> [0x3ca1] = 0x01	; jorge becomes inactive
5FB2: D7          rst  $10			; interprets the commands following this instruction
	9D 00 -> [0x3074] = 0x00	; jorge disappears
5FB5: CD 11 10    call $1011		; puts the bell sound on channel 1
5FB8: C9          ret

; routine called at vespers
5FB9: CD 0C 10    call $100C		; sound
5FBC: C9          ret

; routine called at compline
5FBD: CD 6B 3F    call $3F6B		; draws and clears the spiral
5FC0: CD 49 3F    call $3F49		; sets palette 3
5FC3: D7          rst  $10			; interprets the commands following this instruction
	9E 40 DF -> [0x3ca6] = 0xdf		; modifies the doors that can be opened
5FC7: CD 11 10    call $1011		; puts the bell sound on channel 1
5FCA: C9          ret

; ------------ end of logic dependent on the time of day ----------------------------------------

; ------------------ abbot logic ----------------
5FCB: CF          rst  $08
	80 -> c1a = [0x3038]
	60 -> c2a = 0x60
	3C -> ca = c1a < c2a			; ca = 0 if guillermo's position is < 0x60
	88 -> c1b = [0x2d81]
	01 -> c2b = 0x01
	3D -> cb = [0x2d81] == 0x01		; cb = 0 if it's prime
	8D -> c1c = [0x2d80]
	01 -> c2c = 0x01
	3D -> cc = [0x2d80] == 0x01		; cc = 0 if it's day 1
	2A -> cd = cb | cc				; cd = 0 if it's day 1 or if it's prime
	26 -> c = ca & cd				; c = (if guillermo's position is < 0x60) and (it's day 1 or it's prime)
5FD7: 20 03       jr  nz,$5fdc
5FD9: D7          rst  $10
	8C 0B -> [0x3cc7] = 0x0b	; changes the abbot's state to kick guillermo out of the abbey
5FDC: CF          rst  $08
	88 -> c1a = [0x2d81]
	01 -> c2a = 0x01
	3E -> ca = [0x2d81] >= 0x01 ; ca = 0 if the time of day is >= prime (not nighttime)
	82 -> c1b = [0x303a]
	16 -> c2b = 0x16
	3E -> cb = [0x303a] >= 0x16	; cb = 0 if guillermo's height is >= 0x16 (goes up to the library)
	26 -> c = ca & cb			; c = 0 if guillermo goes up to the library when it's not nighttime
5FE3: 20 07       jr   nz,$5FED		; if guillermo goes up to the library when it's not nighttime, he gets kicked out, otherwise jumps
5FE6: D7          rst  $10
	8B 09 -> [0x3cc8] = 0x09	; indicates that the abbot goes to the door of the corridor leading to the library
5FE9: D7          rst  $10
	8C 0B -> [0x3cc7] = 0x0b	; changes the abbot's state to kick guillermo out of the abbey
5FEC: C9          ret

5FED: CF          rst  $08
	8C -> c1 = [0x3cc7]
	0B -> c2 = 0x0b
	3D -> c = [0x3cc7] == 0x0b	; c = 0 if the abbot is in the state to expel guillermo from the abbey
5FF1: 20 1E       jr   nz,$6011
5FF3: D7          rst  $10
	8B 40 FF -> [0x3cc8] = 0xff	; indicates that the abbot chases guillermo
5FF7: CD 61 3E    call $3E61		; checks if the abbot is close to guillermo
5FFA: 20 14       jr   nz,$6010		; if guillermo is not close, exits
5FFC: CF          rst  $08
	9C -> c1 = [0x3c97]
	01 -> c2 = 0x01
	3D -> c = [0x3c97] == 0x01
6000: 20 01       jr   nz,$6003		; if guillermo is not dead, jumps
6002: C9          ret

; arrives here if guillermo is close to the abbot when he's going to kick him out, but still alive
6003: CF          rst  $08
	89 -> c1 = [0x2da1]
	00 -> c2 = 0x00
	3D -> c = [0x2da1] == 0
6007: 20 07       jr   nz,$6010		; if any voice is being played, jumps
6009: CD 26 50    call $5026		; otherwise, puts the phrase in the marker
	0E 							YOU HAVE NOT RESPECTED MY ORDERS. LEAVE THIS ABBEY FOREVER
600D: D7          rst  $10
	9C 01 -> [0x3c97] = 0x01		; kills guillermo
6010: C9          ret

6011: CF          rst  $08
	9A -> c1a = [0x2dbd]
	0D -> c2a = 0x0d
	3D -> ca = [0x2dbd] == 0x0d	; ca = if the screen currently being shown is the abbot's
	A7 -> cb = [0x3c92]
	26 -> c = ca & cb			; c = 0 if the screen currently being shown is the abbot's and the camera follows guillermo
6017: 20 15       jr   nz,$602E
6019: CD 61 3E    call $3E61		; checks if the abbot is close to guillermo
601C: 20 0C       jr   nz,$602A		; if close to guillermo
601E: CD 26 50    call $5026		; puts the phrase in the marker
	29          				YOU HAVE ENTERED MY CELL
6022: D7          rst  $10
	8B 40 FF -> [0x3cc8] = 0xff	; goes after guillermo
6026: D7          rst  $10
	8C 0B -> [0x3cc7] = 0x0b	; puts the abbot in the state to expel guillermo from the abbey
6029: C9          ret

602A: D7          rst  $10
	8B 02 -> [0x3cc8] = 0x02	; goes to his cell
602D: C9          ret


602E: CF          rst  $08
	8B -> c1a = [0x3cc8]
	8A -> c2a = [0x3cc6]
	3D -> ca = [0x3cc6] == [0x3cc8]	; if the abbot has reached where he wanted to go
	8A -> c1b = [0x3cc6]
	02 -> c2b = 0x02
	3D -> cb = [0x3cc6] == 0x02		; if he has reached his cell
	26 -> cc = ca & cb
	A6 -> c1d = [0x2e04]
	10 -> c2d = 0x10
	2A -> cd = [0x2e04] & 0x10		; if he has the parchment
	10 -> ce = 0x10
	3D -> cf = cd == ce
	26 -> c = cc & cf
603C: 20 16       jr   nz,$6054			; if he has reached his cell and has the parchment
603E: D7          rst  $10
	B3 01 -> [0x3c90] = 0x01		; indicates that guillermo doesn't have the parchment
6041: CD B9 40   call $40B9				; leaves the parchment
6044: CF         rst  $08
	8C -> c1a = [0x3cc7]
	15 -> c2a = 0x15
	3D -> ca = [0x3cc7] == 0x15
	A6 -> c1b = [0x2e04]
	10 -> c2b = 0x10
	2A -> cb = [0x2e04] & 0x10
	26 -> c = ca & cb
604C: 20 06      jr  nz,$6054			; if he's in state 0x15 and doesn't have the parchment
604E: D7         rst  $10
	9B 01 -> [0x3c9a] = 0x01			; indicates that the time of day must advance
6051: D7         rst  $10
	8C 10 -> [0x3cc7] = 0x10			; moves to state 0x10

6054: CF          rst  $08
	8C -> ca = [0x3cc7]
	15 -> cb = 0x15
	3D -> c = [0x3cc7] == 0x15
6058: 20 04       jr   nz,$605E			; if he's in state 0x15
605A: D7          rst  $10
	8B 02 -> [0x3cc8] = 0x02		; goes to his cell
605D: C9          ret

605E: CF          rst  $08
	8C -> ca = [0x3cc7]
	40 80 -> cb = 0x80
	3E -> c = [0x3cc7] >= 0x80
6063: 20 12       jr  nz,$6077			; if the abbot has bit 7 of his state set
6065: CF          rst  $08
	89 -> ca = [0x2da1]
	00 -> cb = 0x00
	3D -> c = [0x2da1] == 0x00
6069: 20 07       jr   nz,$6072			; if not playing a phrase
606B: D7          rst  $10
	8C 8C 7F 2A = [0x3cc7] = [0x3cc7] & 0x7f	; removes bit 7 from his state
6070: 18 05       jr   $6077

6072: D7          rst  $10
	8B 40 FF -> [0x3cc8] = 0xff		; goes to guillermo
6076: C9          ret

6077: CF          rst  $08
	88 -> ca = [0x2d81]
	05 -> cb = 0x05
	3D -> c = [0x2d81] == 0x05
607B: 20 17       jr   nz,$6094		; if it's vespers
607D: D7          rst  $10
	8C 05 -> [0x3cc7] = 0x05	; goes to state 5
6080: CD AC 43    call $43AC		; checks that guillermo is in the correct mass position (if it equals 0 he's in another room, if it equals 2 he's in the room but poorly positioned, and if it equals 1 he's well positioned)
6083: D7          rst  $10
	8B 00 -> [0x3cc8] = 0x00	; goes to the altar
6086: D7          rst  $10
	A2 17 -> [0x3f0e] = 0x17	; phrase = LET US PRAY
6089: CF          rst  $08
	8D -> ca = [0x2d80]
	01 -> cb = 0x01
	2D -> c = [0x2d80] - 0x01
608D: CD 87 64    call $6487		; jumps to a routine to check which characters should have arrived
6090: CD 20 65    call $6520		; waits for the abbot, the rest of the monks and guillermo to be in their place and if so advances the time of day
6093: C9          ret

6094: CF          rst  $08
	88 -> ca = [0x2d81]
	01 -> cb = 0x01
	3D -> c = [0x2d81] == 0x01
6097: 20 17       jr   nz,$60B1		; if it's prime
609A: D7          rst  $10
	8C 0E -> [0x3cc7] = 0x0e	; goes to state 0x0e
609D: CD AC 43    call  $43AC		; checks that guillermo is in the correct mass position (if it equals 0 he's in another room, if it equals 2 he's in the room but poorly positioned, and if it equals 1 he's well positioned)
60A0: D7          rst  $10
	8B 00 -> [0x3cc8] = 0x00	; goes to mass
60A3: D7          rst  $10
	A2 17 -> [0x3f0e] = 0x17	; phrase = LET US PRAY
60A6: CF          rst  $08
	8D -> ca = [0x2d80]
	02 -> cb = 0x02
	2D -> c = [0x2d80] - 0x02
60AA: CD C0 64    call $64C0		; checks if the monks have arrived at their place
60AD: CD 20 65    call $6520		; waits for the abbot, the rest of the monks and guillermo to be in their place and if so advances the time of day
60B0: C9          ret

60B1: CF          rst  $08
	88 -> ca = [0x2d81]
	03 -> cb = 0x03
	3D -> c = [0x2d81] == 0x03
60B5: 20 1A       jr   nz,$60D1		; if it's sext
60B7: D7          rst  $10
	8B 01 -> [0x3cc8] = 0x01	; goes to the refectory
60BA: CD B9 43    call $43B9		; checks if guillermo is in the proper position of the refectory (if it equals 0 he's in another room, if it equals 2 he's in the room but poorly positioned, and if it equals 1 he's well positioned)
60BD: D7          rst  $10
	8C 10 -> [0x3cc7] = 0x10 	; goes to state 0x10
60C0: D7          rst  $10
	A2 19 -> [0x3f0e] = 0x19	; phrase = YOU MAY EAT, BROTHERS
60C3: D7          rst  $10
	A3 01 -> [0x3c96] = 0x01	; indicates that the check is negative initially
60C6: CF          rst  $08
	8D -> c1 = [0x2d80]
	02 -> c2 = 0x02
	2D -> c = [0x2d80] - 0x02
60CA: CD EA 64    call $64EA		; jumps to a routine to check if the monks have arrived depending on c (day)
60CD: CD 20 65    call $6520		; waits for the abbot, the rest of the monks and guillermo to be in their place and if so advances the time of day
60D0: C9          ret

60D1: CF          rst  $08
	88 -> c1a = [0x2d81]
	06 -> c2a = 0x06
	3D -> ca = [0x2d81] == 0x06
	8C -> c1b = [0x3cc7]
	05 -> c2b = 0x05
	3D -> cb = [0x3cc7] == 0x05
	26 -> c = ([0x2d81] == 0x06) && ([0x3cc7] == 0x05)
60D9: 20 0E       jr   nz,$60E9		; if it's compline and he's in state 5
60DB: D7          rst  $10
	8C 06 -> [0x3cc7] = 0x06	; goes to state 6
60DE: CF          rst  $08
	9A -> c1a = [0x2dbd]
	22 -> c2a = 0x22
	3D -> c = [0x2dbd] == 0x22
60E2: 20 04       jr   nz,$60E8		; if the mass screen is being shown
60E4: CD 26 50    call $5026		; puts the phrase on the scoreboard
	0D 							YOU MAY GO TO YOUR CELLS
60E8: C9          ret

60E9: CF          rst  $08
	A5 -> c1a = [0x3c94]
	01 -> c2a = 0x01
	3D -> c = [0x3c94] == 0x01
60ED: 20 3C       jr   nz,$612B		; if berengario has warned him that guillermo has taken the parchment
60EF: D7          rst  $10
	8B 40 FF -> [0x3cc8] = 0xff	; goes to guillermo
60F3: CD D7 40    call $40D7		; a = 0x10 (parchment)
60F6: CF          rst  $08
	A6 -> c1a = [0x2e04]
	10 -> c2a = 0x10
	2A -> ca = [0x2e04] & 0x10
	10 -> cb = 0x10
	3D -> c = ([0x2e04] & 0x10) == 0x10
60FC: 20 0B       jr   nz,$6109		; if the abbot has the parchment
60FE: D7          rst  $10
	8C 15 -> [0x3cc7] = 0x15	; state = 0x15
6101: D7          rst  $10
	8A 40 FF -> [0x3cc6] = 0xff	; indicates that he has reached where guillermo was
6105: D7          rst  $10
	A5 00 -> [0x3c94] = 0x00	; clears berengario's warning
6108: C9          ret

6109: CD 61 3E    call $3E61		; compares the distance between guillermo and the abbot (if he's very close returns 0, otherwise != 0)
610C: 20 18       jr   nz,$6126		; if he's close to guillermo
610E: CF          rst  $08
	99 -> c1a = [0x3c98]
	40 C8 -> c2a = 0xc8
	3E -> c = [0x3c98] >= 0xc8
6113: 20 0A       jr   nz,$611F		; if the counter has passed the limit
6115: CD CE 55    call $55CE		; decrements guillermo's life by 2 units
6118: CD 26 50    call $5026		; puts the phrase on the scoreboard
	05          				GIVE ME THE MANUSCRIPT, BROTHER GUILLERMO
611C: D7          rst  $10
	99 00 -> [0x3c98] = 0x00	; resets the counter
611F: D7          rst  $10
	99 99 01 2B -> [0x3c98] = [0x3c98] + 0x01	; increments the counter
6124: 18 04       jr   $612A

6126: D7          rst  $10
	99 40 C9 -> [0x3c98] = 0xc9;	; sets the counter to maximum
612A: C9          ret

612B: CF          rst  $08
	88 -> c1a = [0x2d81]
	06 -> c2a = 0x06
	3D -> c = [0x2d81] == 0x06
612F: C2 DF 61    jp   nz,$61DF		; if it's compline
6132: CF          rst  $08
	8C -> c1a = [0x3cc7]
	06 -> c2a = 0x06
	3D -> c = [0x3cc7] == 0x06
6136: 20 10       jr   nz,$6148		; if he's in state 0x06
6138: CF          rst  $08
	89 -> c1a = [0x2da1]
	00 -> c2a = 0x00
	3D -> c = [0x2da1] == 0x00
613C: 20 09       jr   nz,$6147		; if a phrase is not being shown
613E: D7          rst  $10
	99 00 -> [0x3c98] = 0x00	; clears the counter
6141: D7          rst  $10
	8B 05 -> [0x3cc8] = 0x05	; goes to the position for us to enter our cell
6144: CD 98 3E    call $3E98		; if he has reached the place he wanted to reach, advances the state
6147: C9          ret

6148: CF          rst  $08
	8C -> c1a = [0x3cc7]
	07 -> c2a = 0x07
	3D -> c = [0x3cc7] == 0x07
614C: 20 27       jr   nz,$6175		; if he's in state 0x07
614E: CF          rst  $08
	9A -> c1a = [0x2dbd]
	40 3E -> c2a = 0x3e
	3D -> c = [0x2dbd] == 0x3e
6153: 20 04       jr   nz,$6159		; if guillermo is in his cell
6155: D7          rst  $10
	8C 09 -> [0x3cc7] = 0x09	; goes to state 0x09
6158: C9          ret

6159: CD 61 3E    call $3E61		; compares the distance between guillermo and the abbot (if he's very close returns 0, otherwise != 0)
615C: 20 08       jr   nz,$6166		; if he's not close, jumps
615E: D7          rst  $10
	8C 08 -> [0x3cc7] = 0x08	; goes to state 0x08
6161: CD 26 50    call $5026		; puts the phrase on the scoreboard
	10 							ENTER YOUR CELL, BROTHER GUILLERMO
6165: C9          ret

6166: D7          rst  $10			; advances the counter
	99 99 01 2B -> [0x3c98] = [0x3c98] + 0x01
616B: CF          rst $08
99 -> c1a = [0x3c98]
32 -> c2a = 0x32
3E -> c = [0x3c98] >= 0x32
616F: 20 03       jr   nz,$6174		; if the counter exceeds the tolerable limit
6171: D7          rst  $10
	8C 08 -> [0x3cc7] = 0x08	; goes to state 0x08
6174: C9          ret

6175: CF          rst  $08
	8C -> c1a = [0x3cc7]
	08 -> c2a = 0x08
	3D -> c = [0x3cc7] == 0x08
6179: 20 34       jr   nz,$61AF		; if he's in state 0x08
617B: CF          rst  $08
	9A -> c1a = [0x2dbd]
	40 3E -> c2a = 0x3e
	3D -> c = [0x2dbd] == 0x3e
6180: 20 04       jr   nz,$6186		; if guillermo has entered his cell
6182: D7          rst  $10
	8C 09 -> [0x3cc7] = 0x09	; goes to state 0x09
6185: C9          ret

6186: D7          rst  $10
	99 99 01 2B -> [0x3c98] = [0x3c98] + 1	; increments the counter
618B: CF          rst  $08
	99 -> c1a = [0x3c98]
	32 -> c2b = 0x32
	3E -> c = [0x3c98] >= 0x32
618F: 20 03       jr   nz,$6194		; if it has passed the limit, keeps it
6191: D7          rst  $10
	99 32 -> [0x3c98] = 0x32
6194: CD 61 3E    call $3E61		; compares the distance between guillermo and the abbot (if he's very close returns 0, otherwise != 0)
6197: 20 11       jr   nz,$61AA		; if guillermo is close
6199: CF          rst  $08
	99 -> c1a = [0x3c98]
	32 -> c2a = 0x32
	3D -> c = [0x3c98] == 0x32
619D: 20 0A       jr   nz,$61A9		; if the counter is at the limit
619F: CD CE 55    call $55CE		; decrements guillermo's life by 2 units
61A2: CD 26 50    call $5026		; puts the phrase on the scoreboard
	10 							ENTER YOUR CELL, BROTHER GUILLERMO
61A6: D7          rst  $10
	99 00 -> [0x3c98] = 0x00	; resets the counter
61A9: C9          ret

61AA: D7          rst  $10
	8B 40 FF -> [0x3cc8] = 0xff	; goes to guillermo
61AE: C9          ret


61AF: CF          rst  $08
	8C -> c1a = [0x3cc7]
	09 -> c2a = 0x09
	3D -> c = [0x3cc7] == 0x09
61B3: 20 1A       jr   nz,$61CF		; if he's in state 0x09
61B5: CF          rst  $08
	9A -> c1a = [0x2dbd]
	40 3E -> c1b = 0x3e
	3D -> c = [0x2dbd] == 0x3e	; if the screen being shown is guillermo's cell
61BA: 20 08       jr   nz,$61C4
61BC: D7          rst  $10
	8B 06 -> [0x3cc8] = 0x06	; moves towards the door
61BE: CD 3E 98    call $3E98		; if he has reached the place he wanted to reach, advances the state
61C2: 18 0A       jr   $61CE

61C4: CD BE 08    call $08BE		; discards planned movements and indicates that a new movement must be thought
61C7: D7          rst  $10
	8C 08 -> [0x3cc7] = 0x08	; changes state
61CA: D7          rst  $10
	8B 40 FF -> [0x3cc8] = 0xff	; goes to guillermo
61CE: C9          ret

61CF: CF          rst  $08
	8C -> c1a = [0x3cc7]
	0A -> c2a = 0x0a
	3D -> c = [0x3cc7] == 0x0a
61D3: 20 09       jr   nz,$61DE		; if he's in state 0x0a
61D5: D7          rst  $10
	9B 01 -> [0x3c9a] = 0x01	; indicates that the time of day must be advanced
61D8: D7          rst  $10
	9E 9E 40 F7 2A -> [0x3ca6] = [0x3ca6] & 0xf7	; modifies the door mask that can be opened so that the door next to guillermo's cell cannot be opened
61DE: C9          ret

61DF: CF          rst  $08
	88 -> c1a = [0x2d81]
	00 -> c2a = 0x00
	3D -> c = [0x2d81] == 0x00
61E3: C2 45 62    jp   nz,$6245		; if it's night
61E6: D7          rst  $10
	8B 02 -> [0x3cc8] = 0x02	; goes to his cell
61E9: CF          rst  $08
	8C -> c1a = [0x3cc7]
	0A -> c2a = 0x0a
	3D -> ca = [0x3cc7] == 0x0a
	8A -> c1b = [0x3cc6]
	02 -> c2b = 0x02
	3D -> cb = [0x3cc6] == 0x02
	26 -> c = ([0x3cc7] == 0x0a) && ([0x3cc6] == 0x02)
61F1: 20 06       jr   nz,$61F9	; if he's in state 0x0a and has reached his cell
61F3: D7          rst  $10
	99 00 -> [0x3c98] = 0x00	; sets the counter to 0
61F6: D7          rst  $10
	8C 0C -> [0x3cc7] = 0x0c	; goes to state 0x0c

61F9: CF          rst  $08
	8C -> c1a = [0x3cc7]
	0C -> c2a = 0x0c
	3D -> c = [0x3cc7] == 0x0c
61FD: 20 20       jr   nz,$621F		; if he's in state 0x0c
61FF: CF          rst  $08
	80 -> c1 = [0x3038]
	60 -> c2 = 0x60
	3E -> c = [0x3038] >= 0x60	; if guillermo is not in the left wing of the abbey
6203: 20 19       jr   nz,$621e
6205: D7          rst  $10
	99 99 01 2B -> [0x3c98] = [0x3c98] + 1	; increments the counter
620A: CF          rst  $08
	99 -> c1a = [0x3c98]
	40 FA -> c2a = 0xfa
	3E -> ca = [0x3c98] >= 0xfa
	8D -> c1b = [0x2d80]
	05 -> c2b = 0x05
	3D -> cb = [0x2d80] == 0x05
	A4 -> c1c = [0x2def]
	08 -> c2c = 0x08
	2A -> cc = [0x2def] & 0x08
	08 -> cd = 0x08
	3D -> ce = ([0x2def] & 0x08) == 0x08
	26 -> cf = ([0x2d80] == 0x05) && ([0x2def] & 0x08) == 0x08
	2A -> c = ([0x3c98] >= 0xfa) || ([0x2d80] == 0x05) && ([0x2def] & 0x08) == 0x08
6219: 20 03       jr   nz,$621E	; if the counter has exceeded the limit, or it's the fifth day and we have the key to the abbot's room
621B: D7          rst  $10
	8C 0D -> [0x3cc7] = 0x0d	; changes to state 0x0d
621E: C9          ret

621F: CF          rst  $08
	8C -> c1 = [0x3cc7]
	0D -> c2 = 0x0d
	3D -> c = [0x3cc7] == 0x0d
6223: 20 1F       jr   nz,$6244		; if he's in state 0x0d
6225: CF          rst  $08
	80 -> c1a = [0x3038]
	60 -> c2a = 0x60
	3C -> ca = [0x3038] < 0x60
	9A -> c1b = [0x2dbd]
	40 3E -> c2b = 0x3e
	3D -> cb = [0x2dbd] == 0x3e
	2A -> c = ([0x3038] < 0x60) || ([0x2dbd] == 0x3e)
622E: 20 07       jr   nz,$6237		; if guillermo is in the left wing of the abbey or in his cell
6230: D7          rst  $10
	8C 0C -> [0x3cc7] = 0x0c	; changes to state 0x0c
6233: D7          rst  $10
	99 32 -> [0x3c98] = 0x32;
6236: C9          ret

6237: CD 61 3E    call $3E61		; compares the distance between guillermo and the abbot (if he's very close, returns 0, otherwise returns something != 0)
623A: 20 03       jr   nz,$623F		; if he's very close
623C: D7          rst  $10
	8C 0B -> [0x3cc7] = 0x0b	; changes to state to kick him out of the abbey
623F: D7          rst  $10
	8B 40 FF -> [0x3cc8] = 0xff ; goes to guillermo
6243: C9          ret

6244: C9          ret

6245: CF          rst  $08
8D -> c1 = [0x2d80]
01 -> c2 = 0x01
3D -> c = [0x2d80] == 0x01
6249: C2 FA 62    jp   nz,$62FA		; if it's the first day
624C: CF          rst  $08
	88 -> c1 = [0x2d81]
	04 -> c2 = 0x04
	3D -> c = [0x2d81] == 0x04
6250: C2 F9 62    jp   nz,$62F9		; if it's none
6253: CF          rst  $08
	8C -> c1 = [0x3cc7]
	04 -> c2 = 0x04
	3D -> c = [0x3cc7] == 0x04
6257: 20 0D       jr   nz,$6266		; if he's in state 0x04
6259: D7          rst  $10
	8B 02 -> [0x3cc8] = 0x02	; goes to his cell
625C: CF          rst  $08
	8A -> c1 = [0x3cc6]
	02 -> c2 = 0x02
	3D -> c = [0x3cc6] == 0x02
6260: 20 03       jr   nz,$6265		; if he has reached his cell
6262: D7          rst  $10
	9B 01 -> [0x3c9a] = 0x01	; indicates that the time of day must be advanced
6265: C9          ret

6266: CF          rst  $08
	8C -> c1 = [0x3cc7]
	00 -> c2 = 0x00
	3D -> c = [0x3cc7] == 0x00
626A: 20 17       jr   nz,$6283		; if he's in state 0x00
626C: CD 61 3E    call $3E61		; compares the distance between guillermo and the abbot (if he's very close returns 0, otherwise != 0)
626F: 20 0E       jr   nz,$627F
6271: CD 26 50    call $5026		; puts the phrase on the scoreboard
01 							WELCOME TO THIS ABBEY, BROTHER. I BEG YOU TO FOLLOW ME. SOMETHING TERRIBLE HAS HAPPENED
6275: D7          rst  $10
8C 01 -> [0x3cc7] = 0x01		; changes to state 0x01
6278: D7          rst  $10
8B 40 FF -> [0x3cc8] = 0xff		; goes to guillermo
627C: C9          ret

627D: 18 04       jr   $6283

627F: D7          rst  $10
	8B 03 -> [0x3cc8] = 0x03	; goes to the abbey entrance
6282: C9          ret

6283: CD 61 3E    call $3E61		; compares the distance between guillermo and the abbot (if he's very close returns 0, otherwise != 0)
6286: C2 F6 62    jp   nz,$62F6		; if he's not close
6289: CF          rst  $08
	8C -> c1 = [0x3cc7]
	01 -> c2 = 0x01
	3D -> c = [0x3cc7] == 0x01
628D: 20 1A       jr   nz,$62A9		; if he's in state 0x01
628F: CF          rst  $08
	8B -> c1a = [0x3cc8]
	04 -> c2a = 0x04
	3D -> ca = [0x3cc8] == 0x04
	89 -> cb = [0x2da1]
	26 -> cc = ([0x3cc8] == 0x04) && ([0x2da1] == 0)
6295: 20 05       jr   nz,$629C		; if he goes to the first stop and no phrase is playing
6297: D7          rst  $10
	8C 02 -> [0x3cc7] = 0x02	; changes to state 0x02
629A: 18 0D       jr   $62A9

629C: CF          rst  $08
	89 -> c1 = [0x2da1]
	00 -> c2 = 0x00
	3D -> c = [0x2da1] == 0x00
62A0: 20 07       jr   nz,$62A9		; if a phrase is not playing
62A2: D7          rst  $10
	8B 04 -> [0x3cc8] = 0x04	; goes to the first stop during the welcome speech
62A5: CD 26 50    call $5026		; puts the phrase on the scoreboard
	02							I FEAR THAT ONE OF THE MONKS HAS COMMITTED A CRIME. I BEG YOU TO FIND HIM BEFORE BERNARDO GUI ARRIVES, FOR I DO NOT WISH THE NAME OF THIS ABBEY TO BE STAINED
62A9: CF          rst  $08
	8C -> c1 = [0x3cc7]
	02 -> c2 = 0x02
	3D -> c = [0x3cc7]
62AD: 20 0E       jr   nz,$62BD	; if he's in state 0x02
62AF: D7          rst  $10
	8B 04 -> [0x3cc8] = 0x04  ; goes to the first stop during the welcome speech
62B2: CF          rst  $08
	8A -> c1a = [0x3cc6]
	04 -> c2a = 0x04
	3D -> ca = [0x3cc6] == 0x04
	89 -> cb = [0x2da1]
	26 -> c = ([0x3cc6] == 0x04) && ([0x2da1] == 0x00)
62B8: 20 03       jr   nz,$62BD		; if he has arrived at the first stop and is not playing a phrase
62BA: D7          rst  $10
	8C 03 -> [0x3cc7] = 0x03	; goes to state 0x03
62BD: CF          rst  $08
8C -> c1 = [0x3cc7]
03 -> c2 = 0x03
3D -> c = [0x3cc7] == 0x03
62C1: 20 1A       jr   nz,$62DD		; if he's in state 0x03
62C3: CF          rst  $08
8B -> c1a = [0x3cc8]
05 -> c2a = 0x05
3D -> ca = [0x3cc8] == 0x05
89 -> cb = [0x2da1]
26 -> c = ([0x3cc8] == 0x05) && ([0x2da1] == 0)
62C9: 20 05       jr   nz,$62D0		; if he goes to our cell and is not playing a voice
62CB: D7          rst  $10
	8C 1F -> [0x3cc7] = 0x1f	; changes to state 0x1f
62CE: 18 0D       jr   $62DD

62D0: CF          rst  $08
	89 -> c1 = [0x2da1]
	00 -> c2 = 0x00
	3D -> c = [0x2da1] == 0x00
62D4: 20 07       jr   nz,$62DD		; if he's not playing a voice
62D6: D7          rst  $10
	8B 05 -> [0x3cc8] = 0x05	; goes to the entrance of our cell
62D9: CD 26 50    call $5026		; puts the phrase on the scoreboard
	03							YOU MUST RESPECT MY ORDERS AND THOSE OF THE ABBEY. ATTEND THE OFFICES AND THE MEAL. AT NIGHT YOU MUST BE IN YOUR CELL
62DD: CF          rst  $08
	8C -> c1 = [0x3cc7]
	1F -> c2 = 0x1f
	3D -> c = [0x3cc7] == 0x1f
62E1: 20 12       jr   nz,$62F5		; if he's in state 0x1f
62E3: D7          rst  $10
	8B 05 -> [0x3cc8] = 0x05	; goes to the entrance of our cell
62E6: CF          rst  $08
	8A -> c1a = [0x3cc6]
	05 -> c2a = 0x05
	3D -> ca = [0x3cc6] == 0x05
	89 -> cb = [0x2da1] == 0x00
	26 -> c = ([0x3cc6] == 0x05) && ([0x2da1] == 0x00)
62EC: 20 07       jr   nz,$62F5		; if he has reached the entrance of our cell and is not playing a voice
62EE: D7          rst  $10
	8C 04 -> [0x3cc7] = 0x04	; goes to state 0x04
62F1: CD 26 50    call $5026		; puts the phrase on the scoreboard
	07							THIS IS YOUR CELL, I MUST GO
62F5: C9          ret

62F6: C3 6C 64    jp   $646C		; scolds guillermo

62F9: C9          ret

62FA: CF          rst  $08
	8D -> c1 = [0x2d80]
	02 -> c2 = 0x02
	3D -> c = [0x2d80] == 0x02
62FE: 20 06       jr   nz,$6306		; if it's the second day
6300: D7          rst  $10
A2 16 -> [0x3f0e] = 0x16		; phrase = YOU MUST KNOW THAT THE LIBRARY IS A SECRET PLACE. ONLY MALAQUIAS MAY ENTER. YOU MAY GO
6303: C3 CF 63    jp   $63CF

6306: CF          rst  $08
	8D -> c1 = [0x2d80]
	03 -> c2 = 0x03
	3D -> c = [0x2d80] == 0x03
630A: 20 2A       jr   nz,$6336		; if it's the third day
630C: CF          rst  $08
	8C -> c1a = [0x3cc7]
	10 -> c2a = 0x10
	3D -> ca = [0x3cc7] == 0x10
	88 -> c1b = [0x2d81]
	02 -> c2b = 0x02
	3D -> cb = [0x2d81] == 0x02
	26 -> c = ([0x3cc7] == 0x10) && ([0x2d81] == 0x02)
6314: 20 1A       jr   nz,$6330		; if he's in state 0x10 and the time of day is terce
6316: CD 61 3E    call $3E61		; compares the distance between guillermo and the abbot (if he's very close returns 0, otherwise != 0)
6319: 20 04       jr   nz,$631F		; if he's close to guillermo
631B: D7          rst  $10
	8B 07 -> [0x3cc8] = 0x07	; goes to the screen where he introduces jorge
631E: C9          ret

631F: CF          rst  $08
	92 -> c1 = [0x3ce8]
	1E -> c2 = 0x1e
	3E -> c = [0x3ce8] >= 0x1e
6323: 20 05       jr   nz,$632A		; if jorge's state >= 0x1e (has already introduced guillermo to jorge)
6325: D7          rst  $10
	92 92 01 2D -> [0x3ce8] = [0x3ce8] - 1
632A: D7          rst  $10
	9B 00 -> [0x3c9a] = 0x00	; no need to advance the time of day
632D: C3 6C 64    jp   $646C		; scolds guillermo

6330: D7          rst  $10
	A2 30 -> [0x3f0e] = 0x30	; phrase = I WANT YOU TO MEET THE OLDEST AND WISEST MAN IN THE ABBEY
6333: C3 CF 63    jp  $63CF

6336: CF          rst  $08
	8D -> c1 = [0x2d80]
	04 -> c2 = 0x04
	3D -> c = [0x2d80] == 0x04
633A: 20 06       jr   nz,$6342		; if it's the fourth day
633C: D7          rst  $10
	A2 11 -> [0x3f0e] = 0x11	; phrase = BERNARDO HAS ARRIVED, YOU MUST ABANDON THE INVESTIGATION
633F: C3 CF 63    jp  $63CF

6342: CF          rst  $08
8D -> c1 = [0x2d80]
05 -> c2 = 0x05
3D -> c = [0x2d80] == 0x05
6346: 20 65       jr   nz,$63AD		; if it's the fifth day
6348: CF          rst  $08
88 -> c1 = [0x2d81]
04 -> c2 = 0x04
3D -> c = [0x2d81] == 0x04
634C: 20 59       jr   nz,$63A7		; if it's none
634E: CF          rst  $08
8A -> c1 = [0x3cc6]
08 -> c2 = 0x08
3D -> c = [0x3cc6] == 0x08		; if he has arrived at severino's cell door
6352: 20 20       jr   nz,$6374
6354: CF          rst  $08
99 -> c1 = [0x3c98]
00 -> c2 = 0x00
3D -> c = [0x3c98] == 0x00
6358: 20 03       jr   nz,$635D		; if the counter has not been started
635A: CD 2A 10    call $102A		; plays a sound
635D: D7          rst  $10
99 99 01 2B -> [0x3c98] = [0x3c98] + 1	; increments the counter
6362: CF          rst  $08
	99 -> c1 = [0x3c98]
	1E -> c2 = 0x1e
	3C -> c = [0x3c98] < 0x1e
6366: 20 01       jr   nz,$6369		; if the counter is < 0x1e, exits
6368: C9          ret

6369: D7          rst  $10
8C 10 -> [0x3cc7] = 0x10		; changes the state 0x10
636C: CD 26 50    call $5026		; puts the phrase on the scoreboard
1C 								GOOD GOD... THEY HAVE MURDERED SEVERINO AND LOCKED HIM IN
6370: D7          rst  $10
	9B 01 -> [0x3c9a] = 0x01	; advances the time of day
6373: C9          ret

6374: CF          rst  $08
	8B -> c1a = [0x3cc8]
	08 -> c2a = 0x08
	3D -> ca = [0x3cc8] == 0x08
	8C -> c1b = [0x3cc7]
	13 -> c2b = 0x13
	3E -> cb = [0x3cc7] == 0x13
	2A -> c = ([0x3cc8] == 0x08) || ([0x3cc7] == 0x13)
637C: 20 21       jr   nz,$639F		; if the abbot goes to severino's cell or is in state 0x13
637E: D7          rst  $10
99 00 -> [0x3c9a] = 0x00		; starts the counter
6381: CF          rst  $08
8C -> c1 = [0x3cc7]
13 -> c2 = 0x13
3D -> c = [0x3cc7] == 0x13
6385: 20 0C       jr   nz,$6393		; if he is in state 0x13
6387: CD 61 3E    call $3E61		; compares the distance between guillermo and the abbot (if very close returns 0, otherwise != 0)
638A: 20 04       jr   nz,$6390		; if he is close to guillermo
638C: D7          rst  $10
	8B 08 -> [0x3cc8] = 0x08		; goes to the door of severino's cell
638F: C9          ret

6390: C3 6C 64    jp   $646C		; scolds guillermo

6393: CF          rst  $08
	89 -> c1 = [0x2da1]
	00 -> c2 = 0x00
	3D -> c = [0x2da1] == 0x00
6397: 20 03       jr   nz,$639C		; if no voice is being played
6399: D7          rst  $10
	8C 13 -> [0x3cc7] = 0x13		; goes to state 0x13
639C: C9          ret

639D: 18 08       jr   $63A7		; never reaches here???

639F: CD 1B 50    call $501B		; writes the phrase in the marker
		1B							VENID, FRAY GUILLERMO, DEBEMOS ENCONTRAR A SEVERINO
63A3: D7          rst  $10
	8B 08 -> [0x3cc8] = 0x08		; goes to the door of severino's cell
63A6: C9          ret

63A7: D7          rst  $10
	A2 1D -> [0x3f0e] = 0x1d		; phrase = BERNARDO ABANDONARA HOY LA ABADIA
63AA: C3 CF 63    jp   $63CF

63AD: CF          rst  $08
		8D -> c1 = [0x2d80]
		06 -> c2 = 0x06
		3D -> c = [0x2d80] == 0x06
63B1: 20 06       jr   nz,$63B9		; if it's the sixth day
63B3: D7          rst  $10
	A2 1E -> [0x3f0e] = 0x1e		; phrase = MA�ANA ABANDONAREIS LA ABADIA
63B6: C3 CF 63    jp   $63CF

63B9: CF          rst  $08
		8D -> c1 = [0x2d80]
		07 -> c2 = 0x07
		3D -> c = [0x2d80] == 0x07
63BD: 20 0F       jr   nz,$63CE		; if it's the seventh day
63BF: D7          rst  $10
	A2 25 -> [0x3f0e] = 0x25		; phrase = DEBEIS ABANDONAR YA LA ABADIA
63C2: CF          rst  $08
	88 -> c1 = [0x2d81]
	02 -> c2 = 0x02
	3D -> c = [0x2d81] == 0x02		; if it's terce
63C6: 20 03       jr   nz,$63CB
63C8: D7          rst  $10
	9C 01 -> [0x3c97] = 0x01		; indicates that guillermo has died
63CB: C3 CF 63    jp   $63CF

63CE: C9          ret


63CF: CF          rst  $08
		8C -> c1 = [0x3cc7]
		10 -> c2 = 0x10
		3D -> c = [0x3cc7] == 0x10
63D3: 20 03       jr   nz,$63D8		; if he is in state 0x10
63D5: C3 E2 63    jp   $63E2

63D8: CF          rst  $08
	88 -> c1 = [0x2d81]
	02 -> c2 = 0x02
	3D -> c = [0x2d81] == 0x02
63DC: 20 03       jr   nz,$63E1		; if it's terce
63DE: C3 20 64    jp   $6420

63E1: C9          ret

63E2: CF          rst  $08
		90 -> c1a = [0x3ce9]
		40 FE -> c2a = 0xfe
		3D -> ca = [0x3ce9] == 0xfe
		86 -> c1b = [0x3caa]
		40 FE -> c2b = 0xfe
		3D -> cb = [0x3caa] == 0xfe
		2A -> ([0x3ce9] == 0xfe) || ([0x3caa] == 0xfe)
63EC: 20 18       jr   nz,$6406		; if malaquias or berengario/bernardo are going to fetch the abbot
63EE: CF          rst  $08
		8B -> c1 = [0x3cc8]
		8A -> c2 = [0x3cc6]
		3D -> c = [0x3cc8] == [0x3cc6]
63F2: 20 03       jr   nz,$63F7		; if the abbot has arrived where he wanted to go
63F4: C3 5B 3E    jp   $3E5B		; indicates that the character doesn't want to find any route

63F7: D7          rst  $10
		8B 02 -> [0x3cc8] = 0x02	; goes to his cell
63FA: CF          rst  $08
	A8 -> c1a = [0x2e0b]
	10 -> c2a = 0x10
	2A -> ca = [0x2e0b] & 0x10
	10 -> cb = 0x10
	3D -> c = ([0x2e0b] & 0x10) == 0x10
6400: 20 03       jr   nz,$6405		; if bernardo has the parchment
6402: D7          rst  $10
	8B 03 -> [0x3cc8] = 0x03		; goes to the abbey entrance
6405: C9          ret

6406: CF          rst  $08
		A6 -> c1a = [0x2e04]
		10 -> c2a = 0x10
		2A -> ca = [0x2e04] & 0x10
		10 -> cb = 0x10
		3D -> c = ([0x2e04] & 0x10) == 0x10
640C: 20 03       jr   nz,$6411		; if the abbot has the parchment
640E: D7          rst  $10
	8B 02 -> [0x3cc8] = 0x02		; goes to his cell
6411: CF          rst  $08
	8A -> c1 = [0x3cc6]
	8B -> c2 = [0x3cc8]
	3D -> c = [0x3cc6] == [0x3cc8]
6415: 20 08       jr   nz,$641F		; if the abbot has arrived where he wanted to go
6417: D7          rst  $10
		8B B2 03 2A 02 2B -> [0x3cc8] = ([0x3c9d] & 0x03) + 2	; moves randomly
641E: C9          ret
641F: C9          ret

6420: CF          rst  $08
		8C -> c1a = [0x3cc7]
		0E -> c2a = 0x0e
		3D -> c = [0x3cc7] == 0x0e
6424: 20 07       jr   nz,$642D		; if he is in state 0x0e
6426: CD 26 50    call $5026		; puts the phrase in the marker
		14							VENID AQUI, FRAY GUILLERMO
642A: D7          rst  $10
		8C 11 -> [0x3cc7] = 0x11	; goes to state 0x11

642D: CF          rst  $08
		8C -> c1a = [0x3cc7]
		11 -> c2a = 0x11
		3D -> c = [0x3cc7] == 0x11	; if he is in state 0x11
6431: 20 0C       jr   nz,$643F
6433: CF          rst  $08
		89 -> c1a = [0x2da1]
		00 -> c2a = 0x00
		3D -> c = [0x2da1] == 0x00
6437: 20 06       jr   nz,$643F		; if not playing a phrase
6439: D7          rst  $10
		8C 12 -> [0x3cc7] = 0x12	; goes to state 0x12
643C: D7          rst  $10
		99 00 -> [0x3c98] = 0x00	; initializes the counter
643F: CF          rst  $08
		8C -> c1a = [0x3cc7]
		12 -> c2a = 0x12
		3D -> c = [0x3cc7] == 0x12
6443: 20 0A       jr   nz,$644F		; if he is in state 0x12
6445: D7          rst  $10
		8C 0F -> [0x3cc7] = 0x0f	; goes to state 0x0f
6448: D7          rst  $10
		8B 00 -> [0x3cc8] = 0x00	; goes to the church altar
644B: CD 0B 3F    call $3F0B		; puts the corresponding phrase in the marker
644E: C9          ret

644F: CF          rst  $08
		8C -> c1a = [0x3cc7]
		0F -> c2a = 0x0f
		3D -> c = [0x3cc7] == 0x0f
6453: 20 16       jr   nz,$646B		; if he is in state 0x0f
6455: CF          rst  $08
		89 -> c1 = [0x2da1]
		00 -> c2 = 0x00
		3D -> c = [0x2da1] == 0x00
6459: 20 04       jr   nz,$645F		; if not playing a voice
645B: D7          rst  $10
		8C 10 -> [0x3cc7] = 0x10	; goes to state 0x10
645E: C9          ret

645F: CD 61 3E    call $3E61		; compares the distance between guillermo and the abbot (if very close returns 0, otherwise != 0)
6462: 20 01       jr   nz,$6465		; if guillermo is close, exits
6464: C9          ret

6465: D7          rst  $10
		8C 12 -> [0x3cc7] = 0x12	; goes to state 0x12
6468: C3 6C 64    jp   $646C		; scolds guillermo
646B: C9          ret

; scolds guillermo
646C: CF          rst  $08
		8C -> c1a = [0x3cc7]
		40 80 -> c2a = 0x80
		3E -> c = [0x3cc7] >= 0x80
6471: 20 01       jr   nz,$6474		; if it has bit 7 set
6473: C9          ret

6474: CD CE 55    call $55CE		; decreases guillermo's health by 2 units
6477: CD BE 08    call $08BE		; discards planned moves and indicates that a new move must be thought
647A: D7          rst  $10
		8C 8C 40 80 2B -> [0x3cc7] = [0x3cc7] + 0x80
6480: CD 1B 50    call $501B		; writes the phrase in the marker
		08							OS ORDENO QUE VENGAIS
6484: C3 5B 3E    jp   $3E5B		; indicates that the character doesn't want to find any route


; called if he is in mass (vespers) and day is passed in c
6487: CD 10 3F    call $3F10		; jumps to a routine depending on what's in c
		6498 -> day 1
		6498 -> day 2
		64A2 -> day 3
		6498 -> day 4
		64AA -> day 5
		64BC -> day 6
		0000

; called on day 1, 2 and 4
6498: D7          rst  $10
		A3 -> [0x3c96] = the following:
		91 -> c1a = [0x3ce7]	; where berengario/bernardo has arrived
		97 -> c2a = [0x3d11]	; where adso has arrived
		26 -> ca = c1a | c2a
		94 -> cb = [0x3cff]		; where severino has arrived
		26 -> cc = ca | cb
		87 -> cd = [0x3ca8]		; where malaquias has arrived
		26 -> c = cc | cd
64A1: C9          ret

; called on day 3
64A2: D7          rst  $10
		A3 -> [0x3c96] = the following:
		97 -> c1a = [0x3d11]	; where adso has arrived
		94 -> c2a = [0x3cff]	; where severino has arrived
		26 -> ca = c1a & c2a
		87 -> cb = [0x3ca8]		; where malaquias has arrived
		26 -> c = ca & cb
64A9: C9          ret

; called on day 5
64AA: CF          rst  $08
		AC -> ca = [0x3ca2]
		01 -> cb = 0x01
		3E -> c = [0x3ca2] >= 0x01
64AE: 20 08       jp   nz,$64B8		; if malaquias is dying

64B0: D7          rst  $10
		A2 40 20 -> [0x3f0e] = 0x20	; phrase = MALAQUIAS HA MUERTO
64B4: D7          rst  $10
		A3 00 -> [0x3c96] = 0x00	; indicates that everyone is in place
64B7: C9          ret

64B8: D7          rst  $10
		A3 01 -> [0x3c96] = 0x01	; indicates that not everyone is in place yet
64BB: C9          ret


; called on day 6
64BC: D7          rst  $10
		A3 97 -> [0x3c96] = [0x3d11] ; if adso is in his place
64BF: C9          ret


; called if he is in mass (prime) and day is passed in c
64C0: CD 10 3F    call $3F10		; jumps to a routine depending on the day (in c)
		64D1 -> jumps if the day is 2
		64D7 -> jumps if the day is 3
		64DE -> jumps if the day is 4
		6498 -> jumps if the day is 5
		64BC -> jumps if the day is 6
		64E4 -> jumps if the day is 7
		0000

; called on day 2
64D1: D7          rst  $10
		A2 15 -> [0x3f0e] = 0x15	; phrase = HERMANOS, VENACIO HA SIDO ASESINADO
64D4: C3 98 64    jp   $6498		; waits for berengario/bernardo, adso, severino and malaquias

; called on day 3
64D7: D7          rst  $10
		A2 18 -> [0x3f0e] = 0x18	; phrase = HERMANOS, BERENGARIO HA DESAPARECIDO. TEMO QUE SE HAYA COMETIDO OTRO CRIMEN
64DB: C3 A2 64    jp   $64A2		; waits for adso, severino and malaquias

; called on day 4
64DE: D7          rst  $10
		A2 1A -> [0x3f0e] = 0x1a	; phrase = HERMANOS, HAN ENCONTRADO A BERENGARIO ASESINADO
64E1: C3 A2 64    jp   $64A2		; waits for adso, severino and malaquias

; called on day 7
64E4: D7          rst  $10
		A2 17 -> [0x3f0e] = 0x17	; phrase = OREMOS
64E7: C3 BC 64    jp   $64BC		; waits for adso

; called if he is in the refectory and day is passed in c
64EA: CD 10 3F    call $3F10		; jumps to a routine depending on c
		64FA -> day 2
		650C -> day 3
		650C -> day 4
		651A -> day 5
		651A -> day 6
		0000
64F9: C9          ret

64FA: CF          rst  $08
		91 -> c1a = [0x3ce7]
		01 -> c2a = 0x01
		3D -> ca = [0x3ce7] == 0x01	; if berengario has arrived at the dining hall
		97 -> c1b = [0x3d11]
		01 -> c2b = 0x01			; if adso has arrived at the dining hall
		3D -> cb = [0x3d11] == 0x01
		26 -> cc = ca & cb
		94 -> c1d = [0x3cff]
		01 -> c2d = 0x01
		3D -> cd = [0x3cff] == 0x01 ; if severino has arrived at the dining hall
		26 -> c = cc & cd
6506: 20 03       jr   nz,$650B		; if berengario, severino and adso have arrived at the dining hall
6508: D7          rst  $10
		A3 00 -> [0x3c96] = 0x00	; indicates that all monks are ready
650B: C9          ret

650C: CF          rst  $08
		97 -> c1a = [0x3d11]
		01 -> c2a = 0x01
		3D -> ca = [0x3d11] == 0x01	; if adso has arrived at the dining hall
		94 -> c1b = [0x3cff]
		01 -> c2b = 0x01
		3D -> cb = [0x3cff] == 0x01 ; if severino has arrived at the dining hall
		26 -> c = ca & cb
6514: 20 03       jr   nz,$6519		; if adso and severino are ready to eat
6516: D7          rst  $10
		A3 00 -> [0x3c96] = 0x00	; indicates it
6519: C9          ret

651A: D7          rst  $10
		A3 97 01 3D -> [0x3c96] = [0x3d11] == 0x01	; if adso is ready
651F: C9          ret

; waits for the abbot, the rest of the monks and guillermo to be in place and if so advances the time of day
6520: CF          rst  $08
		8A -> c1 = [0x3cc6]
		8B -> c2 = [0x3cc8]
		3D -> c = [0x3cc6] == [0x3cc8]
6524: 20 73       jr   nz,$6599		; if the abbot has arrived where he was going
6526: CF          rst  $08
		A3 -> c1 = [0x3c96]
		00 -> c2 = 0x00
		3D -> c = [0x3c96] == 0x00
652A: 20 6B       jr   nz,$6597		; if the monks are ready to start mass
652C: CF          rst  $08
		AF -> c1 = [0x3c9b]
		01 -> c2 = 0x01
		3E -> c = [0x3c9b] >= 0x01
6530: 20 52       jp   nz,$6584		; if guillermo has at least arrived at the room
6532: CF          rst  $08
		99 -> c1a = [0x3c98]
		32 -> c2a = 0x32
		3E -> c = [0x3c98] >= 0x32
6536: 20 0C       jp   nz,$6544		; if the punctuality counter has been exceeded
6538: D7          rst  $10
		99 00 -> [0x3c98] = 0x00	; resets the counter
653B: CD 26 50    call $5026		; puts the phrase in the marker
		06 							LLEGAIS TARDE, FRAY GUILLERMO
653F: CD CE 55    call $55CE		; decreases guillermo's health by 2 units
6542: 18 3F       jr   $6583

6544: CF          rst  $08
	89 -> c1 = [0x2da1]
	00 -> c2 = 0
	3D -> c = [0x2da1] == 0
6548: 20 22       jr   nz,$656C		; if no voice is being played
654A: CF          rst  $08
		AF -> c1 = [0x3c9b]
		02 -> c2 = 0x02
		3D -> c = [0x3c9b] == 0x02
654E: 20 16       jr   nz,$6566		; if guillermo is not in his place
6550: D7          rst  $10			; interprets the commands following this instruction
	99 99 01 -> [0x3c98] = [0x3c98] + 0x01
6555: CF          rst  $08
		99 -> c1 = [0x3c98]
		1E -> c2 = 0x1e
		3E -> c = c1 >= c2
6559: 20 0A       jr   nz,$6565		; if the counter exceeds the limit
655B: D7          rst  $10
	99 00 -> [0x3c98] = 0x00		; sets the counter to 0
655E: CD 26 50    call $5026		; puts the phrase in the marker
		2D          				OCUPAD VUESTRO SITIO, FRAY GUILLERMO
6562: CD CE 55    call $55CE		; decreases guillermo's health by 2 units
6565: C9          ret

6566: CD 0B 3F    call $3F0B		; puts the phrase that was saved in the marker
6569: D7          rst  $10
		9B 01 -> [0x3c9a] = 0x01	; indicates that the time of day must be advanced
656C: CF          rst  $08
		9B -> c1a = [0x3c9a]
		01 -> c2a = 0x01
		3D -> ca = [0x3c9a] == 0x01
		AF -> c1b = [0x3c9b]
		02 -> c2b = 0x02
		3D -> cb = [0x3c9b] == 0x02
		26 -> c = ([0x3c9a] == 0x01) && ([0x3c9b] == 0x02)
6574: 20 0D       jr   nz,$6583		; if the time of day must be advanced and guillermo is not in his place
6576: D7          rst  $10
		99 00 -> [0x3c98] = 0x00	; resets the counter
6579: D7          rst  $10
		9B 00 -> [0x3c9a] = 0		; indicates that the time of day should not be advanced
657C: CD 1B 50    call $501B		; writes the phrase in the marker
		2D          				OCUPAD VUESTRO SITIO, FRAY GUILLERMO
6580: CD CE 55    call $55CE		; decreases guillermo's health by 2 units
6583: C9          ret

; here it arrives when guillermo hasn't yet arrived at the church
6584: CF          rst  $08
		99 -> c1a = [0x3c98]
		40 C8 -> c2a = 0xc8
		3E -> c = [0x3c98] >= 0xc8
6589: 20 07       jr   nz,$6592		; if the counter exceeds the tolerable limit
658B: D7          rst  $10
		8C 0B -> [0x3cc7] = 0x0b	; changes to the scolding state
658E: D7          rst  $10
		9B 01 -> [0x3c9a] = 0x01	; advances the time of day
6591: C9          ret

6592: D7          rst  $10
		99 99 01 2B -> [0x3c98] = [0x3c98] + 0x01	; increments the counter
6597: 18 03       jr   $659c

6599: D7          rst  $10
		99 00 -> [0x3c98] = 0x00
659C: C9          ret
; ------------------ end of the abbot's logic ----------------

; -------------------------------- code and data related to the parchment --------------------------

; draws the parchment
659D: DD E5       push ix
659F: CD 3A 3F    call $3F3A	; sets the black palette
65A2: CD AF 65    call $65AF	; draws the parchment
65A5: CD 3F 3F    call $3F3F	; sets the parchment palette
65A8: DD E1       pop  ix
65AA: FB          ei

65AB: CD 25 67    call $6725	; draws the texts on the manuscript while space is not pressed
65AE: C9          ret

; draws the parchment
65AF: 21 00 C0    ld   hl,$C000	; points to video memory
65B2: E5          push hl
65B3: 54          ld   d,h		; de = hl + 1
65B4: 5D          ld   e,l
65B5: 13          inc  de
65B6: 36 00       ld   (hl),$00
65B8: 01 FF 3F    ld   bc,$3FFF	; clears video memory
65BB: ED B0       ldir
65BD: E1          pop  hl

; leaves a rectangle of 192 pixels wide in the middle of the screen, the rest clean
65BE: 0E C8       ld   c,$C8	; c = 200, number of lines to fill
65C0: 06 10       ld   b,$10	; b = 16, width of the fills
65C2: 3E F0       ld   a,$F0	; a = 240, value to fill with
65C4: E5          push hl
65C5: 11 40 00    ld   de,$0040	; de = 64, jump between fills
65C8: EB          ex   de,hl	; de = points to the fill on the left

65C9: 19          add  hl,de	; hl = points to the fill on the right
65CA: C5          push bc
65CB: 77          ld   (hl),a	; fills on the right
65CC: ED A0       ldi			; fills on the left
65CE: C1          pop  bc
65CF: 10 F9       djnz $65CA	; completes 16 bytes (64 pixels)
65D1: E1          pop  hl
65D2: CD F2 68    call $68F2	; moves to the next screen line
65D5: 0D          dec  c		; repeats for 200 lines
65D6: 20 E8       jr   nz,$65C0

; clears the 8 lines at the bottom of the screen
65D8: 21 80 C7    ld   hl,$C780	; points to a line (the eighth from the bottom)
65DB: 06 08       ld   b,$08	; repeat for 8 lines
65DD: C5          push bc
65DE: E5          push hl
65DF: 5D          ld   e,l		; de = hl
65E0: 54          ld   d,h
65E1: 13          inc  de
65E2: 01 4F 00    ld   bc,$004F
65E5: ED B0       ldir			; copies what's in the first position of the line to the rest of the line's pixels
65E7: E1          pop  hl
65E8: CD F2 68    call $68F2	; advances hl 0x0800 bytes and if it reaches the end, moves to the next line (+0x50)
65EB: C1          pop  bc
65EC: 10 EF       djnz $65DD	; repeats for the other lines

65EE: 21 20 00    ld   hl,$0020	; hl = (00,32)
65F1: CD C7 68    call $68C7	; calculates the screen offset
65F4: 11 8A 78    ld   de,$788A ; points to the parchment data
65F7: CD 1B 66    call $661B	; draws the top part of the parchment
65FA: 21 DA 00    ld   hl,$00DA	; hl = (00,218)
65FD: CD C7 68    call $68C7	; calculates the screen offset
6600: 11 0A 7A    ld   de,$7A0A	; fills the right part of the parchment
6603: CD 2E 66    call $662E
6606: 21 20 00    ld   hl,$0020	; hl = (00,32)
6609: CD C7 68    call $68C7	; calculates the screen offset
660C: 11 8A 7B    ld   de,$7B8A
660F: CD 2E 66    call $662E	; fills the left part of the parchment
6612: 21 20 B8    ld   hl,$B820	; hl = (184,32)
6615: CD C7 68    call $68C7	; calculates the screen offset
6618: 11 0A 7D    ld   de,$7D0A

; fills the top (or bottom of the parchment)
661B: 0E 30       ld   c,$30		; 48 bytes (= 192 pixels to fill)
661D: 06 08       ld   b,$08		; 8 lines high
661F: E5          push hl
6620: 1A          ld   a,(de)		; reads a byte and writes it to the screen
6621: 77          ld   (hl),a
6622: CD F2 68    call $68F2		; advances to the next line
6625: 13          inc  de			; reads the next graphic byte
6626: 10 F8       djnz $6620		; fills the 8 lines
6628: E1          pop  hl
6629: 23          inc  hl			; moves to the next pixel
662A: 0D          dec  c			; repeats until the parchment width is filled
662B: 20 F0       jr   nz,$661D
662D: C9          ret

; fills 2 bytes (8 pixels) per line
662E: 06 C0       ld   b,$C0		; b = 192 lines
6630: 1A          ld   a,(de)		; reads 2 bytes and writes them to the screen
6631: 77          ld   (hl),a
6632: 23          inc  hl
6633: 13          inc  de
6634: 1A          ld   a,(de)
6635: 77          ld   (hl),a
6636: 2B          dec  hl			; goes back to the start of the line
6637: 13          inc  de
6638: CD F2 68    call $68F2		; advances to the next line
663B: 10 F3       djnz $6630		; repeats for the rest of the lines
663D: C9          ret

663E: E5          push hl
663F: C5          push bc
6640: 16 00       ld   d,$00
6642: 7D          ld   a,l
6643: C6 04       add  a,$04
6645: 6F          ld   l,a			; advances the position 4 pixels in x
6646: 3E 30       ld   a,$30
6648: 91          sub  c			; calculates the part of the parchment that remains to be processed
6649: 87          add  a,a
664A: 87          add  a,a			; converts to pixels
664B: 5F          ld   e,a			; de = pixel number after the triangle in the top part of the parchment
664C: EB          ex   de,hl
664D: 29          add  hl,hl		; hl = offset in the parchment data corresponding to the erased part
664E: 01 8A 78    ld   bc,$788A		; bc points to the graphic data of the top part of the parchment
6651: 09          add  hl,bc
6652: EB          ex   de,hl		; saves in de the pointer to the erased data of the top part of the parchment
6653: CD C7 68    call $68C7		; converts the current position to VRAM address
6656: E5          push hl			; saves the current position on the stack
6657: 06 08       ld   b,$08		; 8 lines high
6659: 1A          ld   a,(de)		; reads a byte from the parchment and writes it to the screen
665A: 77          ld   (hl),a
665B: CD F2 68    call $68F2		; advances to the next screen line
665E: 13          inc  de
665F: 10 F8       djnz $6659		; completes the 8 lines

6661: E1          pop  hl			; recovers the current position and advances 4 pixels in x
6662: 23          inc  hl
6663: 06 08       ld   b,$08		; copies the next 4 pixels from another 8 lines
6665: 1A          ld   a,(de)
6666: 77          ld   (hl),a
6667: CD F2 68    call $68F2		; advances to the next screen line
666A: 13          inc  de
666B: 10 F8       djnz $6665

666D: C1          pop  bc
666E: C5          push bc
666F: 79          ld   a,c
6670: 3D          dec  a
6671: 3D          dec  a
6672: 3D          dec  a
6673: 87          add  a,a
6674: 87          add  a,a
6675: 67          ld   h,a
6676: 2E DA       ld   l,$DA		; x = pixel 248
6678: 5F          ld   e,a
6679: 16 00       ld   d,$00
667B: EB          ex   de,hl
667C: 29          add  hl,hl		; hl = offset to the erased part of the right edge of the parchment
667D: 01 0A 7A    ld   bc,$7A0A		; points to graphic data of the right part of the parchment
6680: 09          add  hl,bc
6681: EB          ex   de,hl
6682: CD C7 68    call $68C7		; converts the current position to VRAM address
6685: 06 08       ld   b,$08		; b = 8 lines high
6687: 1A          ld   a,(de)		; copies 8 pixels
6688: 77          ld   (hl),a
6689: 23          inc  hl
668A: 13          inc  de
668B: 1A          ld   a,(de)
668C: 77          ld   (hl),a
668D: 2B          dec  hl
668E: 13          inc  de
668F: CD F2 68    call $68F2		; moves to the next screen line
6692: 10 F3       djnz $6687
6694: C1          pop  bc
6695: E1          pop  hl
6696: C9          ret

; turns the page
6697: 06 2D       ld   b,$2D		; repeats for 45 lines
6699: 0E 03       ld   c,$03		; c = initial width of the triangle (multiples of 4)
669B: 21 D3 00    ld   hl,$00D3		; (00, 240) -> starting position
669E: C5          push bc
669F: E5          push hl
66A0: 41          ld   b,c
66A1: CD 06 69    call $6906		; draws a right triangle with side b
66A4: 01 D0 07    ld   bc,$07D0
66A7: CD C6 67    call $67C6		; small delay (20 ms)
66AA: E1          pop  hl			; recover the original position
66AB: C1          pop  bc
66AC: CD 3E 66    call $663E		; clears the upper and right part of the scroll border that has been erased
66AF: 2D          dec  l			; x = x - 4
66B0: 2D          dec  l
66B1: 2D          dec  l
66B2: 2D          dec  l
66B3: 0C          inc  c			; increment the padding
66B4: 10 E8       djnz $669E
66B6: CD 3E 66    call $663E		; clears the upper and right part of the scroll border that has been erased

66B9: 06 2E       ld   b,$2E		; repeat 46 times
66BB: 0E 2F       ld   c,$2F		; c = initial width for the triangle (multiples of 4)
66BD: 21 20 04    ld   hl,$0420		; (04, 64) -> starting position
66C0: C5          push bc
66C1: 41          ld   b,c
66C2: E5          push hl
66C3: CD 06 69    call $6906		; draws a right triangle with side b
66C6: 01 D0 07    ld   bc,$07D0
66C9: CD C6 67    call $67C6		; small delay (20 ms)
66CC: E1          pop  hl
66CD: E5          push hl
66CE: 7C          ld   a,h
66CF: D6 04       sub  $04
66D1: 67          ld   h,a			; y = y - 4
66D2: F5          push af
66D3: CD C7 68    call $68C7		; calculates the offset of the coordinates of hl on screen
66D6: F1          pop  af
66D7: 5F          ld   e,a
66D8: 16 00       ld   d,$00
66DA: EB          ex   de,hl
66DB: 29          add  hl,hl
66DC: 01 8A 7B    ld   bc,$7B8A
66DF: 09          add  hl,bc		; hl = offset of the erased data from the left part of the scroll
66E0: EB          ex   de,hl
66E1: 06 04       ld   b,$04		; 4 lines high
66E3: 1A          ld   a,(de)		; copy 8 pixels
66E4: 77          ld   (hl),a
66E5: 13          inc  de
66E6: 23          inc  hl
66E7: 1A          ld   a,(de)
66E8: 77          ld   (hl),a
66E9: 13          inc  de
66EA: 2B          dec  hl
66EB: CD F2 68    call $68F2		; move to the next screen line
66EE: 10 F3       djnz $66E3		; repeat until completing 4 lines
66F0: E1          pop  hl
66F1: C1          pop  bc
66F2: C5          push bc
66F3: E5          push hl
66F4: CD 05 67    call $6705		; restore the lower part of the scroll modified by side c
66F7: E1          pop  hl
66F8: 7C          ld   a,h			; y = y + 4
66F9: C6 04       add  a,$04
66FB: 67          ld   h,a
66FC: C1          pop  bc
66FD: 0D          dec  c
66FE: 10 C0       djnz $66C0

6700: CD 05 67    call $6705	; restore the lower part of the scroll modified by side c
6703: 0E 00       ld   c,$00

; restore the lower part of the scroll modified by side c
6705: 79          ld   a,c
6706: 87          add  a,a
6707: 87          add  a,a
6708: 5F          ld   e,a			; e = a*4
6709: 16 00       ld   d,$00
670B: C6 20       add  a,$20
670D: 6F          ld   l,a
670E: 26 B8       ld   h,$B8		; y = 184
6710: CD C7 68    call $68C7		; calculates the offset of the coordinates of hl on screen
6713: EB          ex   de,hl
6714: 29          add  hl,hl
6715: 01 0A 7D    ld   bc,$7D0A		; hl = offset of the erased data from the lower part of the scroll
6718: 09          add  hl,bc
6719: EB          ex   de,hl
671A: 06 08       ld   b,$08
671C: 1A          ld   a,(de)
671D: 77          ld   (hl),a
671E: 13          inc  de
671F: CD F2 68    call $68F2		; move to the next screen line
6722: 10 F8       djnz $671C
6724: C9          ret

6725: 2E 2C       ld   l,$2C		; l = 44
6727: 26 10       ld   h,$10		; h = 16
6729: 22 0A 68    ld   ($680A),hl	; save the current position
672C: DD E5       push ix
672E: CD BC 32    call $32BC		; read the state of the keys
6731: FB          ei
6732: 3E 2F       ld   a,$2F		; check if space was pressed
6734: CD 82 34    call $3482
6737: DD E1       pop  ix
6739: C0          ret  nz			; if it was pressed, exit

673A: DD 7E 00    ld   a,(ix+$00)	; read the character to print
673D: FE 1A       cp   $1A			; if the end of scroll character is found, wait for space to be pressed to finish
673F: 28 EB       jr   z,$672C
6741: DD 23       inc  ix			; point to the next character
6743: FE 0D       cp   $0D
6745: 20 08       jr   nz,$674F		; if a line feed character is not found, jump
6747: 2A 0A 68    ld   hl,($680A)
674A: CD DE 67    call $67DE
674D: 18 DD       jr   $672C		; continue processing the string

674F: FE 20       cp   $20			; if it's not a space, jump
6751: 20 07       jr   nz,$675A
6753: 3E 0A       ld   a,$0A
6755: CD CD 67    call $67CD		; wait a bit and advance the position by 10 pixels
6758: 18 D2       jr   $672C		; continue processing the string

675A: FE 0A       cp   $0A			; if it's not the character 0x0a, jump
675C: 20 05       jr   nz,$6763
675E: CD F0 67    call $67F0		; wait a while and turn the page
6761: 18 C9       jr   $672C		; continue processing the string

6763: 4F          ld   c,a			; save a copy of the character
6764: E6 60       and  $60			; check if it's uppercase or lowercase
6766: FE 40       cp   $40
6768: 3E FF       ld   a,$FF
676A: 28 02       jr   z,$676E
676C: 3E 0F       ld   a,$0F
676E: 32 C0 67    ld   ($67C0),a	; fill a parameter depending on whether it's an uppercase or lowercase letter
6771: 79          ld   a,c			; get the character
6772: 21 0C 68    ld   hl,$680C		; point to the table that indicates how characters are formed
6775: D6 20       sub  $20			; only has characters from 0x20 onwards
6777: 87          add  a,a			; each entry occupies 2 bytes
6778: CD 2D 16    call $162D		; hl = hl + a
677B: 5E          ld   e,(hl)		; get a pointer in de
677C: 23          inc  hl
677D: 56          ld   d,(hl)
677E: D5          push de
677F: FD E1       pop  iy			; IY points to the character

6781: 01 20 03    ld   bc,$0320		; small delay (approx. 8 ms)
6784: CD C6 67    call $67C6
6787: FD 7E 00    ld   a,(iy+$00)	; get a byte from the character
678A: FD 23       inc  iy
678C: 4F          ld   c,a			; save a copy of the character
678D: E6 F0       and  $F0
678F: FE F0       cp   $F0
6791: 20 08       jr   nz,$679B		; if it's not the last byte of the character, jump
6793: 79          ld   a,c
6794: E6 0F       and  $0F
6796: CD CD 67    call $67CD		; print a space and return to the loop to print more characters
6799: 18 91       jr   $672C

679B: 79          ld   a,c			; get the character
679C: E6 0F       and  $0F
679E: 2A 0A 68    ld   hl,($680A)	; advance the x position according to the 4 least significant bits of the byte read from the character drawing
67A1: 85          add  a,l
67A2: 6F          ld   l,a
67A3: F5          push af
67A4: 79          ld   a,c
67A5: 07          rlca
67A6: 07          rlca
67A7: 07          rlca
67A8: 07          rlca
67A9: E6 0F       and  $0F
67AB: 84          add  a,h			; advance the y position according to the 4 most significant bits of the byte read from the character drawing
67AC: 67          ld   h,a
67AD: CD C7 68    call $68C7		; convert the pixels to VRAM address
67B0: F1          pop  af
67B1: E6 03       and  $03			; keep the 2 least significant bits of the position to know which pixel to paint
67B3: 47          ld   b,a
67B4: 3E 88       ld   a,$88		; calculate the mask for the corresponding pixel
67B6: 28 03       jr   z,$67BB
67B8: 0F          rrca
67B9: 10 FD       djnz $67B8

67BB: 4F          ld   c,a			; save the calculated mask
67BC: 2F          cpl
67BD: A6          and  (hl)			; get the value of the rest of the screen pixels
67BE: 47          ld   b,a
67BF: 3E 00       ld   a,$00		; a is filled from outside. a = 0xff if it's uppercase, or 0x0f if it's lowercase, to paint in red or black
67C1: A1          and  c			; activate the pixel to paint
67C2: B0          or   b			; combine with the screen pixels
67C3: 77          ld   (hl),a		; update the video memory with the new pixel
67C4: 18 BB       jr   $6781		; repeat for the rest of the letter values

67C6: 00          nop				; delay until bc = 0x0000. Each iteration is 32 cycles (approx 10 microseconds, since
67C7: 0B          dec  bc			;  although the Z80 runs at 4 MHz, the CPC architecture has a synchronization for the
67C8: 78          ld   a,b			;  video that makes it effectively run around 3.2 MHz)
67C9: B1          or   c
67CA: 20 FA       jr   nz,$67C6
67CC: C9          ret

; jump here to print a space
67CD: F5          push af
67CE: 01 B8 0B    ld   bc,$0BB8		; wait a bit (approx. 30 ms)
67D1: CD C6 67    call $67C6
67D4: F1          pop  af
67D5: 2A 0A 68    ld   hl,($680A)	; get the current position
67D8: 85          add  a,l
67D9: 6F          ld   l,a
67DA: 22 0A 68    ld   ($680A),hl	; increment the current position
67DD: C9          ret

; jump here to print a carriage return
67DE: 01 60 EA    ld   bc,$EA60		; wait a while (approx. 600 ms)
67E1: CD C6 67    call $67C6
67E4: 3E 10       ld   a,$10		; calculate the position of the next line
67E6: 2E 2C       ld   l,$2C
67E8: 84          add  a,h
67E9: 67          ld   h,a
67EA: 22 0A 68    ld   ($680A),hl
67ED: FE A4       cp   $A4			; has the end of the sheet been reached?
67EF: D8          ret  c

; called when the page needs to be turned
67F0: 21 2C 10    ld   hl,$102C
67F3: 22 0A 68    ld   ($680A),hl	; reset the position to the beginning of the line
67F6: 06 03       ld   b,$03
67F8: C5          push bc
67F9: 01 00 00    ld   bc,$0000		; (approx. 655 ms)
67FC: CD C6 67    call $67C6		; delay
67FF: C1          pop  bc
6800: 10 F6       djnz $67F8		; repeat the delays 3 times
6802: DD E5       push ix
6804: CD 97 66    call $6697		; turn the page
6807: DD E1       pop  ix
6809: C9          ret

680A: current position on the scroll (y,x in pixels)

; table of pointers to character data for the scroll (those pointing to 0x0000 are not defined)
680C: 0000 ; character 0x20: ' '
680E: 0000 ; character 0x21: '!'
6810: 0000 ; character 0x22: '"'
6812: 0000 ; character 0x23: '#'
6814: 0000 ; character 0x24: '$'
6816: 0000 ; character 0x25: '%'
6818: 0000 ; character 0x26: '&'
681A: 0000 ; character 0x27: '''
681C: 0000 ; character 0x28: '('
681E: 0000 ; character 0x29: ')'
6820: 0000 ; character 0x2a: '*'
6822: 0000 ; character 0x2b: '+'
6824: 6947 ; character 0x2c: ','
6826: 694E ; character 0x2d: '-'
6828: 695F ; character 0x2e: '.'
682A: 0000 ; character 0x2f: '/'
682C: 0000 ; character 0x30: '0'
682E: 6964 ; character 0x31: '1'
6830: 697A ; character 0x32: '2'
6832: 699E ; character 0x33: '3'
6834: 0000 ; character 0x34: '4'
6836: 0000 ; character 0x35: '5'
6838: 0000 ; character 0x36: '6'
683A: 69BE ; character 0x37: '7'
683C: 0000 ; character 0x38: '8'
683E: 0000 ; character 0x39: '9'
6840: 69D9 ; character 0x3a: ':'
6842: 69E2 ; character 0x3b: ';'
6844: 0000 ; character 0x3c: '<'
6846: 0000 ; character 0x3d: '='
6848: 0000 ; character 0x3e: '>'
684A: 0000 ; character 0x3f: '?'
684C: 0000 ; character 0x40: '@'
684E: 6A28 ; character 0x41: 'A'
6850: 0000 ; character 0x42: 'B'
6852: 6A78 ; character 0x43: 'C'
6854: 6AD6 ; character 0x44: 'D'
6856: 6B3D ; character 0x45: 'E'
6858: 0000 ; character 0x46: 'F'
685A: 6B88 ; character 0x47: 'G'
685C: 6BF7 ; character 0x48: 'H'
685E: 0000 ; character 0x49: 'I'
6860: 6C4D ; character 0x4a: 'J'
6862: 0000 ; character 0x4b: 'K'
6864: 6C8B ; character 0x4c: 'L'
6866: 6CCD ; character 0x4d: 'M'
6868: 0000 ; character 0x4e: 'N'
686A: 6D3D ; character 0x4f: 'O'
686C: 6DA8 ; character 0x50: 'P'
686E: 0000 ; character 0x51: 'Q'
6870: 0000 ; character 0x52: 'R'
6872: 6E0C ; character 0x53: 'S'
6874: 6E6C ; character 0x54: 'T'
6876: 0000 ; character 0x55: 'U'
6878: 0000 ; character 0x56: 'V'
687A: 0000 ; character 0x57: 'W'
687C: 0000 ; character 0x58: 'X'
687E: 6EAF ; character 0x59: 'Y'
6880: 0000 ; character 0x5a: 'Z'
6882: 0000 ; character 0x5b: '['
6884: 0000 ; character 0x5c: '\'
6886: 0000 ; character 0x5d: ']'
6888: 0000 ; character 0x5e: '^'
688A: 0000 ; character 0x5f: '_'
688C: 0000 ; character 0x60: '`'
688E: 6F0F ; character 0x61: 'a'
6890: 6F37 ; character 0x62: 'b'
6892: 6F66 ; character 0x63: 'c'
6894: 6F84 ; character 0x64: 'd'
6896: 6FB3 ; character 0x65: 'e'
6898: 6FD3 ; character 0x66: 'f
689A: 6FF7 ; character 0x67: 'g'
689C: 7026 ; character 0x68: 'h'
689E: 7055 ; character 0x69: 'i'
68A0: 706C ; character 0x6a: 'j'
68A2: 708A ; character 0x6b: 'q'
68A4: 70AE ; character 0x6c: 'l'
68A6: 70C9 ; character 0x6d: 'm'
68A8: 7103 ; character 0x6e: 'n'
68AA: 7129 ; character 0x6f: 'o'
68AC: 714E ; character 0x70: 'p'
68AE: 7179 ; character 0x71: 'q'
68B0: 71A7 ; character 0x72: 'r'
68B2: 71C3 ; character 0x73: 's'
68B4: 71DF ; character 0x74: 't'
68B6: 7203 ; character 0x75: 'u'
68B8: 7229 ; character 0x76: 'v'
68BA: 724D ; character 0x77: 'w'
68BC: 727B ; character 0x78: 'x'
68BE: 7298 ; character 0x79: 'y'
68C0: 72C2 ; character 0x7a: 'z'
68C2: 0000 ; character 0x7b: '{'
68C4: 0000 ; character 0x7c: '|'

68C6: 00

; given hl (coordinates in pixels), calculates the corresponding offset on screen
; the calculated value is made starting from the nearest x coordinate multiple of 4 and adding 32 pixels to the right
; l = X coordinate (in pixels)
; h = Y coordinate (in pixels)
68C7: D5          push de
68C8: CB 3D       srl  l
68CA: CB 3D       srl  l
68CC: 7D          ld   a,l			; a = l / 4 (every 4 pixels = 1 byte)
68CD: 08          ex   af,af'
68CE: F5          push af
68CF: 7C          ld   a,h
68D0: E6 F8       and  $F8			; get the value to calculate the offset within the VRAM bank
68D2: 6F          ld   l,a
68D3: 7C          ld   a,h
68D4: 26 00       ld   h,$00
68D6: 29          add  hl,hl		; within each bank, the line to go to can be calculated as (y & 0xf8)*10
68D7: 54          ld   d,h			;  or in other words, (y >> 3)*0x50
68D8: 5D          ld   e,l
68D9: 29          add  hl,hl
68DA: 29          add  hl,hl
68DB: 19          add  hl,de		; hl = offset within the bank
68DC: E6 07       and  $07			; a = 3 least significant bits in y (to calculate which VRAM bank it goes to)
68DE: 87          add  a,a
68DF: 87          add  a,a
68E0: 87          add  a,a			; adjust the 3 bits
68E1: B4          or   h			; complete the bank calculation
68E2: F6 C0       or   $C0			; adjust so it's within 0xc000-0xffff
68E4: 67          ld   h,a
68E5: F1          pop  af
68E6: 08          ex   af,af'
68E7: 85          add  a,l			; add the x offset
68E8: 6F          ld   l,a
68E9: 8C          adc  a,h
68EA: 95          sub  l
68EB: 67          ld   h,a
68EC: 11 08 00    ld   de,$0008		; adjust so it comes out 32 pixels to the right
68EF: 19          add  hl,de
68F0: D1          pop  de
68F1: C9          ret

; advance to the next line
68F2: 7C          ld   a,h		; advance hl 0x0800 bytes (move to the next line)
68F3: C6 08       add  a,$08
68F5: 38 02       jr   c,$68F9	; if it goes past 0xffff, jump
68F7: 67          ld   h,a
68F8: C9          ret
68F9: 7C          ld   a,h
68FA: E6 C7       and  $C7		; adjust so the minimum is at 0xc000
68FC: 67          ld   h,a
68FD: 3E 50       ld   a,$50	; if there was carry, move to the next line
68FF: 85          add  a,l
6900: 6F          ld   l,a
6901: D0          ret  nc
6902: 8C          adc  a,h
6903: 95          sub  l
6904: 67          ld   h,a
6905: C9          ret

; draws a right triangle with the legs parallel to the coordinate axes and length b
6906: CD C7 68    call $68C7			; calculates the offset of the coordinates of hl on screen
6909: 16 00       ld   d,$00			; counter for the outer loop

690B: 0E 04       ld   c,$04			; 4 lines to process per iteration

690D: C5          push bc
690E: E5          push hl
690F: 79          ld   a,c
6910: 3D          dec  a
6911: E5          push hl
6912: 21 43 69    ld   hl,$6943			; point to the fill pattern
6915: CD 2D 16    call $162D			; hl = hl + a
6918: 7E          ld   a,(hl)			; read the byte to write
6919: E1          pop  hl				; recover the screen coordinates
691A: 1E 00       ld   e,$00			; initialize ???
691C: 32 32 69    ld   ($6932),a		; modify the code parameter with the byte read

691F: 7A          ld   a,d
6920: BB          cp   e				; if the outer loop counter has been reached, jump
6921: 28 0E       jr   z,$6931
6923: 36 F0       ld   (hl),$F0			; write 4 pixels to screen
6925: 05          dec  b				; repeat for the size of the triangle
6926: 20 05       jr   nz,$692D			; if b is not 0, jump
6928: 1C          inc  e				; increment the inner loop counter
6929: 23          inc  hl				; advance 4 pixels
692A: 04          inc  b
692B: 18 F2       jr   $691F

692D: 04          inc  b
692E: CD 2D 16    call $162D			; hl = hl + a

6931: 36 00       ld   (hl),$00			; write to screen (fill the parameter from outside with the value to be written to screen)
6933: 23          inc  hl
6934: 36 00       ld   (hl),$00			; clear remnants from a previous execution
6936: E1          pop  hl				; recover the original screen coordinates
6937: CD F2 68    call $68F2			; move to the next screen line
693A: C1          pop  bc
693B: 0D          dec  c				; complete the 4 lines
693C: 20 CF       jr   nz,$690D
693E: 1C          inc  e				; increment the size of the area to process
693F: 14          inc  d
6940: 10 C9       djnz $690B			; repeat b times
6942: C9          ret

; triangular fill
6943: F0 E0 C0 80

; character data for the scroll
6947: A2 A3 B2 B3 C3 D2 F4 -> character ','
694E: 70 80 91 81 82 92 93 83 73 74 84 75 85 86 86 97 F8  -> character '-'
695F: A2 A3 B2 B3 F4 -> character '.'
6964: 60 51 42 33 43 53 52 63 62 73 72 83 82 93 92 A3 A2 B3 B2 C3 B4 F5 -> character '1'
697A: 60 50 41 32 33 34 35 44 45 46 56 55 65 64 74 73 83 82 92 91 A1 A0 B0 C0 B1 B2 B3 C3 B4 C4 B5 A6 B5 A6 97 F8 -> character '2'
699E: 50 41 32 33 34 43 44 45 46 37 46 55 64 73 72 73 74 85 96 95 A6 A5 B5 C4 C3 B3 C2 B2 B1 A0 90 F8 -> character '3'
69BE: 50 41 32 33 34 43 44 45 46 37 46 55 64 73 82 83 92 93 A2 A3 B2 B3 C3 B4 81 84 F8 -> character '7'
69D9: 72 73 82 83 A2 A3 B2 B3 F4 -> character ':'
69E2: 72 73 82 83 A2 A3 B2 B3 C3 D2 F4 -> character ';'
69ED: 50 41 52 51 62 61 72 71 82 81 92 91 A2 A1 B2 B1 C1 C0 D0 63 54 45 56 55 66 65 76 75 86 85 96 95 A6 A5 B6 B5 C5 C4 D4 67 58 49 5A 59
	6A 69 7A 79 8A 89 9A 99 AA A9 BA B9 C9 C8 F0 -> this character is not in the table and is an 'm' slightly different from the 'm' that it displays
6A28: 22 13 04 05 06 15 14 25 16 17 27 26 35 36 37 38 47 48 57 58 59 68 79 69 78 7A 8A 89 99 9A 9B AA AB BA BB BC CB DB CC DD DC 60 51 42
	43 44 54 53 52 63 64 73 82 92 A1 B1 C0 D0 C1 D1 D2 C2 D3 C4 83 93 84 94 85 95 86 96 87 97 88 98 65 66 67 FE -> character 'A'
6A78: 03 12 21 22 32 31 40 41 42 52 51 50 60 61 62 72 71 70 80 81 82 83 93 92 91 90 A1 A2 B1 C2 B2 A3 B3 C3 D4 C4 B4 A4 A5 B5 C5 D5 D6 C6
	B6 B7 C7 D7 D8 C8 B8 B9 C9 D9 CA BA BB CB BC AD 24 25 26 16 17 07 08 18 19 09 1A 1B 0C 35 36 45 46 55 56 66 65 75 76 85 28 38 48 58 68
	78 88 98 A8 FE -> character 'C'
6AD6: 00 10 11 21 12 22 13 23 33 34 24 14 15 25 35 36 26 16 17 27 37 38 28 18 19 29 39 49 4A 3A 2A 2B 3B 3C 4C 4B 5A 5B 5C 6C 6B 6A 7A 7B
	7C 8C 8B 8A 9A 9B 9C AC AB AA BB BA C9 D8 C8 C7 D7 D6 C6 B6 B5 C5 C4 B4 B3 C3 C2 B2 C1 D0 42 52 53 63 62 72 73 83 82 93 92 A3 A5 95 85
	75 65 55 45 66 67 68 69 89 88 87 86 71 FE -> character 'D'
6B3D: 20 11 02 03 04 13 14 15 24 34 33 43 42 52 53 63 62 73 72 83 82 92 A2 B1 C0 A4 95 86 85 76 75 66 65 56 55 46 45 36 27 18 09 0A 19 1A
	1B 2B 2A 3A D2 C3 C4 B4 B5 C5 B6 C6 B7 C7 D7 C8 B9 BA AB 60 71 74 77 67 68 58 59 69 6A 5B FE -> character 'E'
6B88: 80 91 92 93 83 84 85 76 77 68 78 69 79 7A 6A 6B 6C 7B 8A 8B 9A 9B AA AB BA BB CA CB DA DB EA EB DC C9 D8 D7 E7 E6 D6 E5 D5 C5 D4 E4
	D3 C4 C3 C2 C1 B2 B3 B4 A4 A3 A2 92 93 94 83 82 72 73 74 64 63 62 52 53 54 44 43 42 32 33 34 10 21 22 23 24 15 16 07 17 08 18 09 19 28
	29 1A 2A 39 3A 2B 1C 26 36 46 56 66 76 86 96 A6 B6 C6 D6 D8 C8 FE -> character 'G'
6BF7: 00 11 12 13 04 05 06 07 16 15 14 24 25 26 36 35 34 44 45 46 56 55 54 64 65 66 76 75 74 84 85 86 96 95 94 A4 A5 A6 B5 C4 B4 C3 B3 B2
	A2 A1 B0 22 23 32 42 52 62 72 82 92 97 88 79 6A 5A 4A 3A 57 48 39 49 4A 3B 5A 59 69 6A 7A 89 8A 99 9A A9 AA B9 CA BA BB AC FE -> character 'H'
6C4D: 3A 2B 2A 1B 1A 0A 09 19 18 27 36 47 37 46 57 56 67 66 77 76 87 86 97 96 A7 A6 B6 C5 D4 D3 C3 D2 C2 C1 B1 B0 A0 A1 B2 A1 91 90 80 81
	71 62 B4 A4 94 84 74 64 54 44 34 25 16 07 55 85 51 FC -> character 'J'
6C8B: 10 01 02 03 14 13 23 22 32 33 44 45 46 47 48 39 2A 29 1A 19 09 08 18 17 26 36 35 54 55 56 66 65 64 74 75 76 86 85 84 94 95 96 A5 A4
	B3 C2 B4 B5 B6 C6 B7 C7 B8 C8 B9 C9 BA BB AC A8 98 88 78 68 58 FE -> character 'L'
6CCD: B0 B1 A2 A1 92 91 82 81 72 71 62 61 52 51 42 41 31 32 21 20 21 22 13 04 05 14 24 34 44 54 64 74 84 94 A4 B4 C3 D2 D1 D0 15 16 25 26
	27 36 37 46 47 56 57 66 67 76 77 86 87 96 97 A6 A7 B7 B6 C6 D6 D5 C7 D6 18 09 0A 1A 19 29 39 49 59 69 79 89 99 A9 B9 C9 1B 2A 2B 2C 3B
	3C 4B 4C 5B 5C 6B 6C 7B 7C 8B 8C 9B 9C AB AC BC BB CB DA 6A 65 64 FE -> character 'M'
6D3D: 12 22 21 32 31 30 40 41 42 52 51 50 60 61 62 72 71 70 80 81 82 92 91 90 A1 A2 B2 B3 C3 C4 B4 C5 D6 C6 C7 B7 B8 B9 A8 A9 AA AB 9B 9A
	99 98 88 89 8A 8B 7B 7A 79 78 68 69 6A 6B 5B 5A 59 58 48 48 49 4A 4B 3B 3A 39 38 29 28 18 27 17 07 06 16 26 15 05 04 14 13 03 13 36
	35 45 46 56 55 56 66 65 75 76 86 85 95 96 A5 A4 57 87 FC -> character 'O'
6DA8: 03 04 14 13 12 22 23 24 34 33 32 42 43 44 54 53 52 62 63 64 74 73 72 82 83 84 94 93 92 A2 A3 A4 B4 B3 B2 C2 C3 C4 D3 D2 D1 C0 10 21
	25 16 26 27 17 07 08 18 09 19 1A 1B 1C 0D 2B 2A 29 39 3A 3B 4B 4A 49 59 5A 5B 6B 6A 69 79 7A 7B 89 78 88 98 97 87 77 76 86 75 65 61 70
	37 47 57 67 77 A7 B7 C7 D6 48 FE -> character 'P'
6E0C: D0 C1 B2 C2 B3 C3 B4 C4 B5 C5 D6 C6 C7 D7 D8 C8 D9 C9 CA BA BB AC AB AA 9A 9B 9C 9D 8C 8B 8A 7B 7A 69 79 78 68 67 77 76 66 65 75 64
	74 73 63 62 51 52 53 42 43 33 24 25 15 06 16 26 27 17 07 08 18 28 38 49 39 29 19 1A 2A 3A 2B 1C 0D 58 85 94 A3 60 70 71 81 82 92
	93 94 95 96 97 98 A9 B9 FE -> character 'S'
6E6C: 20 11 02 12 03 13 04 14 05 15 25 26 16 06 07 17 27 28 18 08 19 29 1A 2A 2B 1B 1C 0D 34 43 44 53 54 63 64 73 74 83 84 93 94 A3 A4 B3
	B4 C4 B5 C5 D5 D6 C6 C7 D7 C8 B8 B9 A9 9A A7 97 87 77 67 57 47 37 FE -> character 'T'
6EAF: 20 11 02 03 14 13 12 22 23 24 34 33 32 42 43 44 54 53 52 62 63 64 74 75 76 77 78 79 68 69 6A 5A 59 58 48 49 4A 3A 39 38 28 29 2A 1B
	2A 19 18 08 07 16 27 26 36 47 46 56 66 76 86 85 94 93 A2 A3 A4 B4 B3 B2 C2 C3 C4 D4 D5 C5 C6 B7 A8 99 9A AB AA BB BA CB CA D9 C8 B7 A6
	95 94 93 82 81 90 FE -> character 'Y'
6F0F: 40 41 51 52 43 44 54 55 46 65 64 75 74 84 85 95 94 A4 A5 B4 B5 B6 C5 B4 C3 C2 C1 B2 B1 B0 A1 A0 91 90 81 80 71 72 83 F8 -> character 'a'
6F37: 01 10 11 12 21 22 32 31 41 42 52 51 61 62 72 71 81 82 92 91 A2 A1 B0 B1 B2 B3 C2 C3 C4 B5 B6 A5 A6 95 96 85 86 75 76 65 66 55 56 45
	44 53 F8 -> character 'b'
6F66: B6 B5 C4 C3 C2 B3 B2 B1 B0 A1 A2 92 91 82 81 72 71 62 61 52 51 43 44 45 54 55 56 66 65 F8 -> character 'c'
6F84: 50 51 60 61 70 71 80 90 81 91 A0 A1 B0 B1 B2 C1 C2 C3 B4 B5 B6 A5 A4 95 94 85 84 75 74 65 64 55 54 53 44 43 42 33 32 31 22 21 20 11 10 00 F7 -> character 'd'
6FB3: A6 B5 C4 C3 C2 B3 B2 B1 B0 A1 A2 91 92 81 82 71 72 61 62 51 52 43 44 45 54 55 56 66 65 74 83 F8 -> character 'e'
6FD3: C2 B3 B2 B1 A2 A1 92 91 82 81 72 71 62 61 52 51 42 41 42 31 32 21 22 11 12 03 04 14 15 16 40 41 42 43 44 F7 -> character 'f'
6FF7: B3 B2 B1 A2 A1 A0 A0 A0 91 90 81 80 71 70 61 60 50 51 42 43 44 53 54 55 64 56 65 74 75 84 85 94 95 A4 A5 B4 B5 C5 C4 D5 D4 E3 E2 D2
	D1 D0 F7 -> character 'g'
7026: 03 02 11 10 10 21 20 31 30 41 40 51 50 61 60 71 70 81 80 91 90 A1 A0 B0 B1 C1 B2 62 53 44 55 54 65 64 75 74 85 84 95 94 A4 A5 B4 B5
	C5 B6 F7 -> character 'h'
7055: 50 41 52 51 61 62 72 71 81 82 92 91 A1 A2 B2 B1 C2 B3 21 11 21 22 F5 -> character 'i'
706C: 44 53 54 55 64 65 75 74 84 85 95 94 A4 A5 B5 B4 C4 C5 D5 D4 E4 E3 E2 D2 D1 24 14 14 25 F8 -> character 'j'
708A: 40 41 42 51 52 61 62 71 72 81 82 91 92 A1 A2 B2 B1 C0 C1 C2 57 56 65 64 74 83 94 95 A5 A6 B5 B6 C6 C7 B8 F9 -> character 'q'
70AE: 00 11 22 21 32 31 42 41 52 51 62 61 72 71 82 81 92 91 A2 A1 B0 B1 B2 C2 C3 B4 F5 -> character 'l'
70C9: 50 41 52 51 61 62 72 71 81 82 92 91 A1 A2 B2 B1 C2 B3 63 54 45 55 56 66 65 75 76 86 85 95 96 A6 A5 B5 B6 C6 B7 67 58 49 5A 59 69 6A
 	7A 79 89 8A 9A 99 A9 AA BA B9 CA BB BB FC -> character 'm'
7103: 50 41 52 51 61 62 72 71 81 82 92 91 A1 A2 B2 B1 C2 B3 63 54 45 55 56 66 65 75 76 86 85 95 96 A6 A5 B5 B6 C6 B7 F8 -> character 'n'
7129: 42 43 44 53 54 55 64 65 74 75 84 85 94 95 A5 A4 B5 B4 C3 C2 C1 B2 B1 B0 A1 A0 91 90 81 80 71 70 61 60 51 50 F7 -> character 'o'
714E: B3 A3 B4 A5 A6 95 96 85 86 75 76 65 54 55 66 56 45 44 43 52 41 40 51 62 61 72 71 82 81 92 91 A2 A1 B2 B1 C2 C1 D2 D1 E2 E1 E0 F8 -> character 'p'
7179: B3 B2 B1 A2 A1 A0 91 90 81 80 71 70 61 60 50 51 42 43 44 53 54 55 56 65 64 75 74 85 84 95 94 A5 A4 B5 B4 C5 C4 D5 D4 E5 E4 E3 E4 E5
	E6 F7 -> character 'q'
71A7: B4 C3 C2 B1 B0 B2 A1 A2 91 92 81 82 71 72 61 62 51 40 41 52 43 44 45 54 55 56 65 F8 -> character 'r'
71C3: 47 56 55 54 44 43 52 51 61 62 72 73 74 85 86 96 95 A6 A5 B6 B5 C4 C3 B3 B2 B1 C0 F8 -> character 's'
71DF: 01 12 23 22 33 32 43 42 53 52 53 62 63 72 73 82 83 92 93 A2 A3 B2 B3 B1 B2 B3 C3 C4 B5 60 51 52 53 54 45 F6 -> character 't'
7203: 50 41 52 51 61 62 72 71 81 82 92 91 A1 A2 B2 B1 C2 C3 B4 54 45 56 55 65 66 76 75 85 86 96 95 A5 A6 B6 B5 C6 B7 F8 -> character 'u'
7229: 50 41 52 51 61 62 72 71 81 82 92 91 A1 A2 B2 B1 C2 C3 55 56 46 57 66 65 75 76 86 85 95 96 A5 A6 B5 B4 C4 F8-> character 'v'
724D: 50 41 52 51 61 62 72 71 81 82 92 91 A1 A2 B2 B1 C2 B3 63 54 45 55 56 66 65 75 76 86 85 95 96 A6 A5 B5 B6 C6 B7 20 21 22 32 33 34 35
	26 F8 40 41-> character 'w'
727B: 52 53 62 63 73 74 83 84 93 94 A4 A5 B4 B5 C6 C7 C0 B1 A2 93 74 84 74 65 56 47 F8 -> character 'x'
7298: 40 41 51 52 61 62 71 72 81 82 91 92 93 A2 A3 A4 95 96 85 86 75 76 65 66 55 56 46 47 A6 B5 B6 C6 C5 D6 D5 E4 E3 D3 D2 D1 E2 F8 -> character 'y'
72C2: 60 51 42 43 44 53 54 55 56 47 56 65 74 83 93 A2 B1 C0 B1 B2 B3 B4 C3 C4 C5 B6 A7 73 74 75 F8 -> character 'z'

72E1: 00 55 56 66 65 75 76 86 85 95 96 A6 A5 B5 B6 C6 B7 20 21 22 32 33 34 35 26 F8 -> ??? unrecognizable character
72FB: 40 41 52 53 62 ; ???

; scroll text for the presentation
7300: 20 59 61 20 61 6C 20 66-69 6E 61 6C 20 64 65 20  Ya al final de
7310: 6D 69 0D 76 69 64 61 20-64 65 20 70 65 63 61 64 mi.vida de pecad
7320: 6F 72 2C 20 6D 69 65 6E-2D 0D 74 72 61 73 20 65 or, mien-.tras e
7330: 73 70 65 72 6F 20 65 6C-20 6D 6F 2D 0D 6D 65 6E spero el mo-.men
7340: 74 6F 20 64 65 20 70 65-72 64 65 72 6D 65 20 65 to de perderme e
7350: 6E 0D 65 6C 20 61 62 69-73 6D 6F 20 73 69 6E 20 n.el abismo sin
7360: 66 6F 6E 64 6F 20 64 65-0D 6C 61 20 64 69 76 69 fondo de.la divi
7370: 6E 69 64 61 64 20 64 65-73 69 65 72 74 61 20 79 nidad desierta y
7380: 0D 73 69 6C 65 6E 63 69-6F 73 61 3B 20 65 6E 20 .silenciosa; en
7390: 65 73 74 61 0D 63 65 6C-64 61 20 64 65 20 6D 69 esta.celda de mi
73A0: 20 71 75 65 72 69 64 6F-0D 6D 6F 6E 61 73 74 65  querido.monaste
73B0: 72 69 6F 20 64 65 20 4D-65 6C 6B 2C 0D 64 6F 6E rio de Melk,.don
73C0: 64 65 20 61 75 6E 20 6D-65 20 72 65 74 69 65 6E de aun me retien
73D0: 65 0D 6D 69 20 63 75 65-72 70 6F 20 70 65 73 61 e.mi cuerpo pesa
73E0: 64 6F 20 79 0D 65 6E 66-65 72 6D 6F 2C 20 6D 65 do y.enfermo, me
73F0: 20 64 69 73 70 6F 6E 67-6F 0D 61 20 64 65 6A 61  dispongo.a deja
7400: 72 20 63 6F 6E 73 74 61-6E 63 69 61 20 65 6E 0D r constancia en.
7410: 65 73 74 65 20 70 65 72-67 61 6D 69 6E 6F 20 64 este pergamino d
7420: 65 20 6C 6F 73 0D 68 65-63 68 6F 73 20 61 73 6F e los.hechos aso
7430: 6D 62 72 6F 73 6F 73 20-79 0D 74 65 72 72 69 62 mbrosos y.terrib
7440: 6C 65 73 20 71 75 65 20-6D 65 20 66 75 65 0D 64 les que me fue.d
7450: 61 64 6F 20 70 72 65 73-65 6E 63 69 61 72 20 65 ado presenciar e
7460: 6E 20 6D 69 0D 6A 75 76-65 6E 74 75 64 2E 0D 0D n mi.juventud...
7470: 20 45 6C 20 53 65 77 6F-72 20 6D 65 20 63 6F 6E  El Sewor me con
7480: 63 65 2D 0D 64 65 20 6C-61 20 67 72 61 63 69 61 ce-.de la gracia
7490: 20 64 65 20 64 61 72 0D-66 69 65 6C 20 74 65 73  de dar.fiel tes
74A0: 74 69 6D 6F 6E 69 6F 20-64 65 20 6C 6F 73 0D 61 timonio de los.a
74B0: 63 6F 6E 74 65 63 69 6D-69 65 6E 74 6F 73 20 71 contecimientos q
74C0: 75 65 20 73 65 0D 70 72-6F 64 75 6A 65 72 6F 6E ue se.produjeron
74D0: 20 65 6E 20 6C 61 20 61-62 61 2D 0D 64 69 61 20  en la aba-.dia
74E0: 63 75 79 6F 20 6E 6F 6D-62 72 65 20 69 6E 2D 0D cuyo nombre in-.
74F0: 63 6C 75 73 6F 20 63 6F-6E 76 69 65 6E 65 20 61 cluso conviene a
7500: 68 6F 72 61 0D 63 75 62-72 69 72 20 63 6F 6E 20 hora.cubrir con
7510: 75 6E 20 70 69 61 64 6F-73 6F 0D 6D 61 6E 74 6F un piadoso.manto
7520: 20 64 65 20 73 69 6C 65-6E 63 69 6F 3B 20 68 61  de silencio; ha
7530: 2D 0D 63 69 61 20 66 69-6E 61 6C 65 73 20 64 65 -.cia finales de
7540: 20 31 33 32 37 2C 0D 63-75 61 6E 64 6F 20 6D 69  1327,.cuando mi
7550: 20 70 61 64 72 65 20 64-65 63 69 2D 0D 64 69 6F  padre deci-.dio
7560: 20 71 75 65 20 61 63 6F-6D 70 61 77 61 72 61 20  que acompawara
7570: 61 0D 66 72 61 79 20 47-75 69 6C 6C 65 72 6D 6F a.fray Guillermo
7580: 20 64 65 20 0D 4F 63 63-61 6D 2C 20 73 61 62 69  de .Occam, sabi
7590: 6F 20 66 72 61 6E 63 69-73 2D 0D 63 61 6E 6F 20 o francis-.cano
75A0: 71 75 65 20 65 73 74 61-62 61 20 61 0D 70 75 6E que estaba a.pun
75B0: 74 6F 20 64 65 20 69 6E-69 63 69 61 72 20 75 6E to de iniciar un
75C0: 61 0D 6D 69 73 69 6F 6E-20 65 6E 20 65 6C 20 64 a.mision en el d
75D0: 65 73 65 6D 2D 0D 70 65-77 6F 20 64 65 20 6C 61 esem-.pewo de la
75E0: 20 63 75 61 6C 20 74 6F-2D 0D 63 61 72 69 61 20  cual to-.caria
75F0: 6D 75 63 68 61 73 20 63-69 75 64 61 2D 0D 64 65 muchas ciuda-.de
7600: 73 20 66 61 6D 6F 73 61-73 20 79 20 61 62 61 2D s famosas y aba-
7610: 0D 64 69 61 73 20 61 6E-74 69 71 75 69 73 69 6D .dias antiquisim
7620: 61 73 2E 20 41 73 69 0D-66 75 65 20 63 6F 6D 6F as. Asi.fue como
7630: 20 6D 65 20 63 6F 6E 76-65 72 2D 0D 74 69 20 61  me conver-.ti a
7640: 6C 20 6D 69 73 6D 6F 20-74 69 65 6D 70 6F 20 65 l mismo tiempo e
7650: 6E 0D 73 75 20 61 6D 61-6E 75 65 6E 73 65 20 79 n.su amanuense y
7660: 20 64 69 73 2D 0D 63 69-70 75 6C 6F 3B 20 79 20  dis-.cipulo; y
7670: 6E 6F 20 74 75 76 65 20-71 75 65 0D 61 72 72 65 no tuve que.arre
7680: 70 65 6E 74 69 72 6D 65-2C 20 70 6F 72 71 75 65 pentirme, porque
7690: 0D 63 6F 6E 20 65 6C 20-66 75 69 20 74 65 73 74 .con el fui test
76A0: 69 67 6F 20 64 65 0D 61-63 6F 6E 74 65 63 69 6D igo de.acontecim
76B0: 69 65 6E 74 6F 73 20 64-69 67 6E 6F 73 0D 64 65 ientos dignos.de
76C0: 20 73 65 72 20 72 65 67-69 73 74 72 61 64 6F 73  ser registrados
76D0: 2C 0D 70 61 72 61 20 6D-65 6D 6F 72 69 61 20 64 ,.para memoria d
76E0: 65 20 6C 6F 73 0D 71 75-65 20 76 65 6E 67 61 6E e los.que vengan
76F0: 20 64 65 73 70 75 65 73-2E 0D 0D 20 41 73 69 2C  despues... Asi,
7700: 20 6D 69 65 6E 74 72 61-73 20 63 6F 6E 0D 6C 6F  mientras con.lo
7710: 73 20 64 69 61 73 20 69-62 61 20 63 6F 6E 6F 63 s dias iba conoc
7720: 69 65 6E 2D 0D 64 6F 20-6D 65 6A 6F 72 20 61 20 ien-.do mejor a
7730: 6D 69 20 6D 61 65 73 2D-0D 74 72 6F 2C 20 6C 6C mi maes-.tro, ll
7740: 65 67 61 6D 6F 73 20 61-20 6C 61 73 0D 66 61 6C egamos a las.fal
7750: 64 61 73 20 64 65 6C 20-6D 6F 6E 74 65 20 64 6F das del monte do
7760: 6E 2D 0D 64 65 20 73 65-20 6C 65 76 61 6E 74 61 n-.de se levanta
7770: 62 61 20 6C 61 0D 61 62-61 64 69 61 2E 20 59 20 ba la.abadia. Y
7780: 79 61 20 65 73 20 68 6F-72 61 0D 64 65 20 71 75 ya es hora.de qu
7790: 65 2C 20 63 6F 6D 6F 20-6E 6F 73 6F 74 72 6F 73 e, como nosotros
77A0: 0D 65 6E 74 6F 6E 63 65-73 2C 20 61 20 65 6C 6C .entonces, a ell
77B0: 61 20 73 65 0D 61 63 65-72 71 75 65 20 6D 69 20 a se.acerque mi
77C0: 72 65 6C 61 74 6F 2C 20-79 0D 6F 6A 61 6C 61 20 relato, y.ojala
77D0: 6D 69 20 6D 61 6E 6F 20-6E 6F 0D 74 69 65 6D 62 mi mano no.tiemb
77E0: 6C 65 20 63 75 61 6E 64-6F 20 6D 65 0D 64 69 73 le cuando me.dis
77F0: 70 6F 6E 67 6F 20 61 20-6E 61 72 72 61 72 20 6C pongo a narrar l
7800: 6F 0D 71 75 65 20 73 75-63 65 64 69 6F 20 64 65 o.que sucedio de
7810: 73 70 75 65 73 2E 2E 2E-0D 0D 0D 0D 0D 0D 61 75 spues.........au
7820: 74 6F 72 3A 20 0D 20 20-20 20 50 61 63 6F 20 4D tor: .    Paco M
7830: 65 6E 65 6E 64 65 7A 0D-0D 67 72 61 66 69 63 6F enendez..grafico
7840: 73 20 79 20 63 61 72 61-74 75 6C 61 3A 20 0D 20 s y caratula: .
7850: 20 20 20 4A 75 61 6E 20-44 65 6C 63 61 6E 0D 0D    Juan Delcan..
7860: 63 6F 70 79 72 69 67 68-74 3A 0D 20 20 20 20 4F copyright:.    O
7870: 70 65 72 61 20 53 6F 66-74 0D 1A 00 00 1A 1A 1A pera Soft.......
7880: 1A 1A 1A 00 00 00 00 00-00 00

; graphic data for the upper part of the scroll
788A: F0 F0 F0 F0 E1 C2
7890: 84 08 F0 C3 84 08 01 01-01 01 87 08 03 0F 0E 0E
78A0: 0E 0E 0F 00 0C 00 00 00-00 00 0F 00 08 00 00 00
78B0: 00 00 0F 00 00 00 00 00-00 00 0F 00 00 00 00 00
78C0: 00 00 0F 00 00 00 00 00-00 00 0F 00 00 00 00 00
78D0: 00 00 0F 00 00 00 00 00-00 00 0F 00 00 00 00 00
78E0: 00 00 0F 00 00 00 00 00-00 00 3C 03 04 08 09 09
78F0: 04 03 F0 0F 00 00 02 02-09 0F F0 0F 00 00 04 04
7900: 02 0F F0 0F 00 00 09 09-04 0F F0 0F 00 00 02 02
7910: 09 0F F0 0F 00 00 04 04-02 0F F0 0F 00 00 09 09
7920: 04 0F F0 0F 00 00 02 02-09 0F F0 0F 00 00 04 04
7930: 02 0F F0 0F 00 00 09 09-04 0F F0 0F 01 02 03 02
7940: 09 0E F0 78 3C 12 1A 09-09 00 F0 F0 E1 C2 C2 84
7950: 84 08 F0 0F 0C 02 0E 0A-0C 03 F0 0F 00 00 04 04
7960: 09 0F F0 0F 00 00 09 09-02 0F F0 0F 00 00 02 02
7970: 04 0F F0 0F 00 00 04 04-09 0F F0 0F 00 00 09 09
7980: 02 0F F0 0F 00 00 02 02-04 0F F0 0F 00 00 04 04
7990: 09 0F F0 0F 00 00 09 09-02 0F F0 0F 00 00 02 02
79A0: 04 0F C3 0E 01 00 04 04-09 0E 0F 00 00 08 08 08
79B0: 00 00 78 34 25 12 12 12-01 00 0F 08 00 08 08 08
79C0: 00 08 0F 00 00 00 00 00-00 00 0F 00 00 00 00 00
79D0: 00 00 0F 00 00 00 00 00-00 00 0F 00 00 00 00 00
79E0: 00 00 0F 00 01 00 00 00-00 00 0F 00 03 00 00 00
79F0: 00 00 3C 03 08 0E 07 07-07 07 F0 3C 12 01 08 08
7A00: 08 08 F0 F0 F0 F0 78 34-12 01

; graphic data for the right part of the scroll
7A0A: F0 F0 3C F0 12 F0
7A10: 01 F0 08 78 08 34 08 12-08 01 08 01 08 01 08 16
7A20: 07 3C 00 34 00 34 00 34-00 34 00 34 00 34 00 34
7A30: 00 34 00 34 00 34 00 34-00 34 00 34 00 34 00 34
7A40: 00 34 00 34 00 34 00 34-00 34 00 34 00 3C 01 F0
7A50: 12 F0 07 78 00 78 00 78-00 78 00 78 00 78 00 78
7A60: 00 78 00 78 00 78 00 78-00 78 00 78 00 78 00 78
7A70: 00 78 00 78 00 78 00 78-00 78 00 78 07 78 0F 78
7A80: 3C F0 3C F0 3C F0 3C F0-3C F0 3C F0 34 F0 34 F0
7A90: 34 F0 34 F0 12 F0 12 F0-01 F0 01 F0 00 78 00 78
7AA0: 00 78 00 78 00 78 00 78-00 78 00 78 00 78 00 78
7AB0: 00 78 00 78 00 78 00 78-00 78 00 78 00 78 00 78
7AC0: 00 78 00 78 00 78 00 78-00 78 00 78 00 78 00 78
7AD0: 00 78 00 78 00 78 00 78-00 78 00 78 00 78 00 78
7AE0: 00 78 0F 78 34 F0 12 F0-01 F0 00 78 00 34 00 34
7AF0: 00 34 00 34 00 34 00 34-00 34 00 34 00 34 00 34
7B00: 00 34 00 34 00 34 00 34-00 34 00 34 00 34 00 34
7B10: 00 34 00 34 00 34 00 34-00 34 00 34 00 34 00 34
7B20: 00 34 00 34 00 34 00 34-00 34 00 34 00 34 00 34
7B30: 00 34 00 34 00 34 00 34-00 34 00 34 00 34 00 34
7B40: 00 34 03 78 04 34 00 34-00 34 00 34 00 34 00 34
7B50: 00 34 00 34 00 34 00 34-00 34 00 34 00 34 00 34
7B60: 00 34 00 34 00 34 00 34-00 34 00 34 00 34 00 34
7B70: 00 34 07 3C 08 16 08 01-08 01 08 01 08 12 08 34
7B80: 08 78 01 F0 12 F0 3C F0-F0 F0

; graphic data for the left part of the scroll
7B8A: F0 F0 F0 C3 F0 84
7B90: F0 08 E1 01 C2 01 84 01-08 01 08 01 08 01 86 01
7BA0: C3 0E C2 00 C2 00 C2 00-C2 00 C2 00 C2 00 C2 00
7BB0: C2 00 C2 00 C2 00 C2 00-C2 00 C2 00 C2 00 C2 00
7BC0: C2 00 E1 00 E1 00 E1 00-E1 00 E1 00 E1 00 E1 00
7BD0: E1 00 E1 00 E1 00 E1 00-E1 00 E1 00 E1 00 E1 00
7BE0: E1 00 E1 00 E1 00 E1 00-E1 00 E1 00 E1 00 E1 00
7BF0: F0 08 F0 84 F0 C2 E1 0F-E1 01 E1 00 E1 00 E1 00
7C00: E1 00 E1 00 E1 00 E1 00-E1 00 E1 00 E1 00 E1 00
7C10: E1 00 E1 00 E1 00 E1 00-E1 00 E1 00 E1 00 E1 00
7C20: E1 00 E1 00 E1 00 E1 00-E1 00 E1 00 E1 00 E1 00
7C30: E1 00 E1 00 E1 00 E1 00-E1 00 E1 00 E1 00 E1 00
7C40: E1 00 E1 00 E1 00 E1 00-E1 00 E1 00 E1 00 E1 00
7C50: E1 00 E1 00 E1 00 E1 00-E1 00 E1 00 E1 00 E1 00
7C60: E1 00 E1 00 E1 00 E1 00-E1 00 E1 00 E1 00 E1 00
7C70: E1 00 E1 00 E1 00 E1 00-E1 00 E1 00 E1 00 E1 00
7C80: E1 00 E1 00 E1 00 E1 00-E1 00 E1 00 E1 00 E1 01
7C90: E1 0F F0 C2 F0 84 F0 08-E1 00 C2 00 C2 00 C2 00
7CA0: C2 00 C2 00 C2 00 C2 00-C2 00 C2 00 C2 00 C2 00
7CB0: C2 00 C2 00 C2 00 C2 00-C2 00 C2 00 C2 00 C2 00
7CC0: C2 00 C2 00 C2 00 C2 00-C2 00 C2 00 C2 00 C2 00
7CD0: C2 00 C2 00 C2 00 C2 00-C2 00 C2 00 C2 00 C2 00
7CE0: C2 00 C2 00 C2 00 C2 00-C2 00 C2 00 C2 00 C2 00
7CF0: C2 00 C3 0E 86 01 08 01-08 01 08 01 84 01 C2 01
7D00: E1 01 F0 08 F0 84 F0 C3-F0 F0

; graphic data for the lower part of the scroll
7D0A: 08 84 C2 E1 F0 F0
7D10: F0 F0 01 01 01 01 08 84-C3 F0 0E 0E 0E 0E 0F 03
7D20: 08 87 00 00 00 00 00 0C-00 0F 00 00 00 00 00 08
7D30: 00 0F 00 00 00 00 00 00-00 0F 00 00 00 00 00 00
7D40: 00 0F 00 00 00 00 00 00-00 0F 00 00 01 03 03 16
7D50: 16 3C 06 0F 0F 0F 0F F0-F0 F0 00 0E 0F 0F 0F F0
7D60: F0 F0 00 00 0E 0F 0F 0F-F0 F0 00 00 00 08 0C 0F
7D70: F0 F0 00 00 00 00 00 00-08 87 00 00 00 00 00 00
7D80: 00 0F 00 00 00 00 00 00-00 0F 00 00 00 00 00 00
7D90: 00 0F 00 00 00 00 00 00-00 0F 00 00 00 00 00 00
7DA0: 00 0F 00 00 00 00 00 00-00 0F 02 02 01 00 00 00
7DB0: 00 0F 00 00 00 08 08 08-0F F0 00 00 00 00 00 00
7DC0: 0F F0 00 00 00 00 00 00-0F F0 00 00 00 00 00 00
7DD0: 0F F0 00 00 00 00 00 00-0F F0 00 00 00 00 00 00
7DE0: 0F F0 08 04 04 02 02 03-1E F0 00 00 00 00 00 0F
7DF0: F0 F0 00 00 01 01 01 0F-E1 F0 04 08 00 00 00 00
7E00: 0F F0 00 00 00 00 00 00-0F F0 00 00 00 00 00 00
7E10: 0F F0 00 00 00 00 00 00-0F F0 00 00 00 00 00 00
7E20: 0F F0 00 00 01 01 01 01-0F E1 08 08 00 00 00 00
7E30: 00 0F 00 00 00 00 00 00-00 0F 00 00 00 00 00 00
7E40: 00 0F 00 00 00 00 00 00-00 0F 00 00 00 00 00 00
7E50: 00 0F 00 00 00 00 00 00-00 0F 00 00 00 00 00 00
7E60: 00 0F 00 00 00 00 00 01-00 0F 00 00 00 00 00 03
7E70: 00 0F 07 07 07 07 0F 08-03 3C 08 08 08 08 01 12
7E80: 3C F0 01 12 34 78 F0 F0-F0 F0

7E8A-7FFF: 00

; ---------------------------- end of the code and data related to the scroll --------------------------

; abadia3.bin (0x8000-0xbfff)

; -------------- start of scroll melody data -------------------------
8000: F9 46 80 01 01 04 02 FF-04 01 01 04 80 01 00 01 .F..............
8010: 7F 01 0F 01 01 00 28 0A-FF 14 7F 01 0F 01 02 00 ......(.........
8020: 28 0A FF 1E 7F 01 0F 01-01 00 1E 0A FF 0F 7F 05 (...............
8030: 01 02 05 02 01 05 FF 0F-01 00 3C 0A FF 14 7F 01 ..........<.....
8040: 0C 14 02 FF 14 7F FA 11-80 FB 0D 80 FE D8 81 5A ...............Z
8050: 10 59 10 57 10 59 10 52-10 52 10 57 10 FA 25 80 .Y.W.Y.R.R.W..%.
8060: 47 08 49 08 4A 08 50 08-FA 1B 80 52 30 FA 11 80 G.I.J.P....R0...
8070: 53 10 FA 25 80 55 08 53-08 52 08 50 08 FA 11 80 S..%.U.S.R.P....
8080: 52 10 FA 25 80 53 08 52-08 50 08 4B 08 FA 11 80 R..%.S.R.P.K....
8090: 50 10 FA 25 80 52 08 50-08 4A 08 50 08 49 08 4A P..%.R.P.J.P.I.J
80A0: 08 FA 1B 80 49 20 FA 11-80 5A 10 FA 25 80 59 04 ....I ...Z..%.Y.
80B0: 5A 04 59 08 FA 11 80 57-10 59 10 52 10 52 10 57 Z.Y....W.Y.R.R.W
80C0: 10 FA 25 80 47 08 49 08-4A 08 50 08 FA 1B 80 52 ..%.G.I.J.P....R
80D0: 30 FA 25 80 55 04 53 04-55 08 57 08 55 08 53 08 0.%.U.S.U.W.U.S.
80E0: 52 08 FA 11 80 53 10 FA-25 80 55 08 53 08 52 08 R....S..%.U.S.R.
80F0: 50 08 FA 11 80 52 10 57-10 FA 25 80 50 04 52 04 P....R.W..%.P.R.
8100: 50 08 FA 1B 80 FD F4 82-42 30 FA 11 80 52 10 FA P.......B0...R..
8110: 25 80 4A 08 50 08 52 08-54 08 FA 11 80 55 10 57 %.J.P.R.T....U.W
8120: 10 59 10 5A 10 FA 25 80-57 08 59 08 5A 08 57 08 .Y.Z..%.W.Y.Z.W.
8130: FA 11 80 59 10 FA 25 80-57 08 59 08 FA 11 80 55 ...Y..%.W.Y....U
8140: 10 FA 25 80 45 08 47 08-49 08 4A 08 50 08 52 08 ..%.E.G.I.J.P.R.
8150: FA 11 80 53 10 FA 25 80-52 04 53 04 52 08 FA 11 ...S..%.R.S.R...
8160: 80 50 10 55 10 4A 10 49-10 FA 1B 80 4A 30 FA 11 .P.U.J.I....J0..
8170: 80 47 10 FA 25 80 52 08-50 08 FA 11 80 52 10 47 .G..%.R.P....R.G
8180: 10 FA 25 80 53 08 52 08-FA 11 80 53 10 FA 25 80 ..%.S.R....S..%.
8190: 47 08 52 08 46 08 50 08-47 08 4A 08 FA 1B 80 49 G.R.F.P.G.J....I
81A0: 30 FA 25 80 42 08 44 08-46 08 47 08 49 08 4A 08 0.%.B.D.F.G.I.J.
81B0: FA 11 80 50 10 4A 10 49-10 FA 25 80 4A 02 49 02 ...P.J.I..%.J.I.
81C0: 4A 04 50 04 52 04 FA 11-80 47 10 46 10 FA 1B 80 J.P.R....G.F....
81D0: FD EB 82 4A 30 F9 46 80-FA 1B 80 FB 0D 80 37 30 ...J0.F.......70
81E0: 35 30 36 30 FA 11 80 32-10 FA 25 80 42 08 40 08 5060...2..%.B.@.
81F0: 3A 08 39 08 FA 1B 80 FD-D9 82 37 20 39 10 3A 20 :.9.......7 9.:
8200: FA 11 80 37 10 39 10 36-10 37 10 32 10 FA 25 80 ...7.9.6.7.2..%.
8210: 42 08 40 08 3A 08 39 08-FA 1B 80 37 30 35 30 33 B.@.:.9....70503
8220: 30 FA 11 80 32 10 FA 25-80 42 08 40 08 3B 08 39 0...2..%.B.@.;.9
8230: 08 FA 1B 80 FE D0 82 3B-20 FA 11 80 37 10 40 10 .......; ...7.@.
8240: 39 10 35 10 3A 10 34 10-FE E2 82 35 10 3A 10 FA 9.5.:.4....5.:..
8250: 1B 80 2A 20 4A 30 FA 11-80 49 10 47 10 45 10 47 ..* J0...I.G.E.G
8260: 10 44 10 40 10 FA 1B 80-45 30 FA 11 80 49 10 47 .D.@....E0...I.G
8270: 10 45 10 FA 1B 80 47 20-FA 11 80 45 10 43 10 42 .E....G ...E.C.B
8280: 10 43 10 45 10 3A 10 42-10 40 10 FD C7 82 FA 1B .C.E.:.B.@......
8290: 80 3B 30 40 30 FA 11 80-3A 10 39 10 37 10 42 10 .;0@0...:.9.7.B.
82A0: FA 25 80 39 08 37 08 36-08 34 08 FA 1B 80 32 30 .%.9.7.6.4....20
82B0: FA 11 80 33 10 32 10 30-10 2A 10 30 10 32 10 37 ...3.2.0.*.0.2.7
82C0: 10 FA 1B 80 27 20 FF FA-1B 80 FB 0D 80 32 30 FF ....' .......20.
82D0: FA 1B 80 FB 0D 80 42 20-FF FA 1B 80 FB 0D 80 3A ......B .......:
82E0: 20 FF FA 11 80 FB 0D 80-39 10 FF FA 1B 80 FB 0D  .......9.......
82F0: 80 47 30 FF FA 1B 80 FB-0D 80 4A 30 FF 00 00 00 .G0.......J0....
; -------------- end of scroll melody data -------------

; -------------- start of abbey graphics ----------------------
8300: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00 ................
8310: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00 ................
8320: FC F0 F0 F3 33 F0 F0 CC-00 FC F3 00 00 33 CC 00 ....3........3..
8330: 00 33 CC 00 00 FC F3 00-33 F0 F0 CC FC F0 F0 F3 .3......3.......
8340: F7 EE EE FC F7 BB BB F3-E6 EE FC FF F7 BB F3 FF ................
8350: E6 FC F7 EE F7 F0 FF BB-F0 FE EE EE F3 BA FF BB ................
8360: EE FE EE FC BB BA FF F1-EE FE F4 FF BB B8 F3 FF ................
8370: EE FC FF DD BB F3 FF 77-FC FF DD DD F3 FF 77 77 .......w......ww
8380: 88 00 00 F3 CC 88 B8 FF-33 70 F3 00 00 FF CC 00 ........3p......
8390: 00 F3 00 00 30 CC 88 88-F3 00 00 00 CC 22 22 30 ....0........""0
83A0: CC 00 00 33 33 00 00 CC-00 CC 33 00 00 33 CC 00 ...33.....3..3..
83B0: 00 33 CC 00 00 CC 33 00-33 00 00 CC CC 00 00 33 .3....3.3......3
83C0: FC F8 70 71 F3 D0 D0 F1-B0 FC 70 71 E0 F3 D0 D1 ..pq......pq....
83D0: B0 B0 FC 71 E0 F0 FB F1-B0 B0 F8 FD E0 F0 D8 F3 ...q............
83E0: FC F0 F8 F8 F3 F0 D8 D0-B0 FC F8 F8 F1 F3 D8 D0 ................
83F0: B0 B0 FC F8 F1 F0 F3 D0-B0 B0 B0 FC F1 E0 E0 F3 ................
8400: F0 B3 E0 B3 D0 FC 50 FC-B3 E0 B3 E0 FC 50 FC 50 ......P......P.P
8410: E0 B3 E2 B3 D8 FC A0 FC-B3 E0 73 E0 FC 50 FC 10 ..........s..P..
8420: FE FC FF FC FE F2 FF F3-FC FE FC FF F3 76 F2 FF .............v..
8430: DD FC FE FC 77 F3 76 F2-FC DD FC FE F2 77 F3 FE ....w.v......w..
8440: FC F0 FC F8 F3 F0 FB F8-F0 FC F8 FC F0 FB E8 F3 ................
8450: FC F8 FC B0 FB D8 F3 E0-F8 FC 70 FC F8 F3 D0 FB ..........p.....
8460: 0F FF 0F 0F 1F 00 CF 0F-2E 07 33 0F 2E 0F 1D 8F ..........3.....
8470: 2E 0F 0E 8F 2E 0F 0F 47-2E 0F 0F 47 2E FF FF 47 .......G...G...G
8480: 3F F0 F0 47 7C FF FF 67-FB FF FF 75 F8 FF FF 75 ?..G|..g...u...u
8490: 7F F0 F0 EF 7D FF FF E3-F8 F7 FE F9 E8 F0 F0 F5 ....}...........
84A0: D8 F0 F0 F5 D8 F0 F0 F5-F8 F0 F0 F5 F8 F0 F0 F9 ................
84B0: 7C F0 F3 E3 3E F0 F0 C7-1F FC F3 8F 0F 3F CF 0F |...>........?..
84C0: 0F 7F CF 0F 2F F8 E3 8F-5F F7 FD 4F 8F F8 E3 2F ..../..._..O.../
84D0: 8F 7F CF 2F 8F FB EB 2F-5F F4 F5 4F 3E F3 F8 8F .../.../_..O>...
84E0: 7C F0 F1 C7 7D F0 F6 C7-7C F5 F9 CF 7C F1 F6 C7 |...}...|...|...
84F0: 7C F1 F9 CF 7C F0 F6 C7-7C F1 F9 CF 7C F1 F6 C7 |...|...|...|...
8500: FC F0 CC 00 3F F0 F3 00-0F FC F0 CC 0F 3F F0 F3 ....?........?..
8510: 0F 0F FC F1 0F 0F 3F F1-0F 0F 0F FD 0F 0F 0F 3F ......?........?
8520: CC 00 00 33 F3 00 00 FF-F0 CC 33 FF F0 FB FF FF ...3......3.....
8530: FC F8 FF CC FB F8 FF 00-F8 FC CC 00 F8 F3 00 00 ................
8540: 00 F3 FF FC 30 FF FF C3-F3 FF FC 0F F7 FF C3 0F ....0...........
8550: F7 FC 0F 0F F7 C3 0F 0F-F4 0F 0F 0F C3 0F 0F 0F ................
8560: CC 00 00 30 FF 00 00 F3-FF CC 30 FF FF FF F2 FF ...0......0.....
8570: 33 FE FE FC 00 FE FE F2-00 32 FC FE 00 10 F3 FE 3........2......
8580: CF 0F 0F 0F FF 0F 0F 0F-F3 CF 0F 0F F0 FF 0F 0F ................
8590: F0 F3 CF 0F F0 F0 FB 0F-FC F3 F8 CF 33 CC F8 FB ............3...
85A0: FC F0 F1 88 FF F0 E2 88-FF FC C4 88 FF FF 88 00 ................
85B0: FF FF 00 33 3F FF 00 FF-0F FF 33 FC 0F 7F FF F0 ...3?.....3.....
85C0: 0F 1F F0 F0 0F 3E F0 F0-0F 7D F8 F0 0F F8 F6 F0 .....>...}......
85D0: 1F F0 F0 F0 3F F8 F0 F0-7C F6 F0 F0 F8 F1 F8 F0 ....?...|.......
85E0: FC F0 F0 F0 FF F0 F0 F0-FF FC F0 F0 FF FF F0 F0 ................
85F0: FF FF FC F0 3F FF FF F0-1F FF FF FC 1F FF FF FF ....?...........
8600: F0 F0 F0 F7 F0 F0 F0 FF-F1 F0 FC F6 F0 FC F1 F0 ................
8610: F0 F3 F0 FD F0 F0 FC E2-F0 F0 F3 E6 F0 F0 F0 AA ................
8620: D1 00 FC F8 E2 00 FB F8-C4 00 F8 FC 88 00 E8 F3 ................
8630: 00 00 FC B0 00 00 FB F0-00 00 B8 FC 00 00 F8 FB ................
8640: 0F 0F 0F 0F 0F 0F 0F 1F-0F 0F 0F 7E 0F 0F 1F F8 ...........~....
8650: 0F 0F 1F FC 0F 0F 3E 33-0F 0F 7C C0 0F 0F F8 F0 ......>3..|.....
8660: CC 00 CC 00 33 00 33 00-00 CC 00 CC 00 33 00 33 ....3.3......3.3
8670: 00 30 00 30 00 F3 00 F2-30 FF 30 FE F2 FF F3 FE .0.0....0.0.....
8680: CC 00 CF 0F 33 00 33 0F-00 CC 00 CF 00 33 00 33 ....3.3......3.3
8690: 00 30 00 30 00 F3 00 F2-30 FF 30 FE F2 FF F3 FE .0.0....0.0.....
86A0: C0 FC F0 F3 F0 33 F0 F0-F0 C0 FC F0 F0 F0 33 F0 .....3........3.
86B0: F0 F0 C0 FC F0 F0 F0 33-F0 F0 F0 C0 F0 F0 F0 F0 .......3........
86C0: 0F 0F 0F 0F CF 0F 0F 0F-F3 0F 0F 0F F0 CF 0F 0F ................
86D0: F0 F3 0F 0F F0 F0 CF 0F-FC F0 F3 0F 33 F0 F0 CF ............3...
86E0: FC E3 0F 0F 7E CF 0F 0F-3F 0F 0F 0F 0F 0F 0F 0F ....~...?.......
86F0: 0F 0F 0F 0F 0F 0F 0F 0F-0F 0F 0F 0F 0F 0F 0F 0F ................
8700: 11 33 0F 0F 11 EF 0F 0F-33 EF 0F 0F FF E3 0F 0F .3......3.......
8710: FC E3 0F 0F F0 E3 0F 0F-F0 E3 0F 0F F0 E3 0F 0F ................
8720: FE FC FF FC FE F3 FF FF-FC EF 3F FF F3 8F 3F FF ..........?...?.
8730: DD 0F 3F FC EF 0F 3F FE-EF 0F 3F FE C7 0F 3F FE ..?...?...?...?.
8740: CF 0F 3F FC CF 0F 3F FF-CF 0F 3F FF C7 0F 3F FF ..?...?...?...?.
8750: CF 0F 3F FC CF 0F 3F FE-CF 0F 3F FE C7 0F 3F FE ..?...?...?...?.
8760: CF 0F FC FC CF 3F F0 F3-CF FC F0 FF F7 F0 F3 FF .....?..........
8770: FC F0 FF FC FC F3 FE F2-FC FF FC FE F7 FF F3 FE ................
8780: FC F0 FC F8 F3 FE FB F8-F3 DF F8 FC F3 CF 7E F3 ..............~.
8790: FF CF 1F B0 FB CF 0F F8-FB CF 0F 7C FB CF 0F 7F ...........|....
87A0: FF CF 0F 3E F3 CF 0F 3E-F3 CF 0F 3E F3 CF 0F 3F ...>...>...>...?
87B0: FF CF 0F 3E FB CF 0F 3E-FB CF 0F 3E FB CF 0F 3F ...>...>...>...?
87C0: FF F3 0F 3E F4 F0 CF 3E-F7 F0 F3 3E F3 FC F0 FF ...>...>...>....
87D0: FC FF F0 F2 FB FB FC F2-F8 FC FF F2 F8 F3 F3 FF ................
87E0: FC F0 FC F8 F3 F0 FB F8-F3 FC F8 FC F3 FF F8 F3 ................
87F0: FF CF FC B0 FB CF 3F F0-FB CF 0F FC FB CF 0F 3F ......?........?
8800: FE FC FF FC FE F2 FF C3-FC FE FC 0F F3 76 C3 0F .............v..
8810: DD FC 0F 0F 77 C3 0F 0F-FC 0F 0F 0F C3 0F 0F 0F ....w...........
8820: 0F 0F 0F 3C 0F 0F 0F F3-0F 0F 3C FF 0F 0F F2 FF ...<......<.....
8830: 0F 3C FE FC 0F F3 76 F2-3C DD FC FE F2 77 F3 FE .<....v.<....w..
8840: F8 F4 FF FD F8 F4 FF FD-F8 F4 FF FF F8 F4 FF FF ................
8850: F8 F0 FF CF FC F0 9F 8F-3F F3 0F 0F 0F CF 0F 0F ........?.......
8860: FC F0 FC F8 3F F0 FB F8-0F FC F8 FC 0F 3F E8 F3 ....?........?..
8870: 0F 0F FC B0 0F 0F 3F F0-0F 0F 0F FC 0F 0F 0F 3F ......?........?
8880: 0F CF 0F 0F 1F E3 3F 8F-1F E3 7C CF 3F E3 3F 8F ......?...|.?.?.
8890: 7C FD 4C EF FC F0 FF FB-FB F0 FE FD F8 FC FF FD |.L.............
88A0: CF 0F 0F 0F F3 0F 0F 0F-F0 CF 0F 0F F0 FB 0F 0F ................
88B0: FC F8 CF 0F FB E8 F3 0F-F8 FC B0 CF F8 F3 F0 FB ................
88C0: 57 00 00 00 AE 00 00 00-44 00 00 00 EA 00 11 CC W.......D.......
88D0: F9 EE 32 E2 F8 F1 FC DB-75 FE F5 F9 74 FF F9 DB ..2.....u...t...
88E0: 56 F3 FD E2 32 F0 F1 CC-11 5A 7B 00 00 FF EE 00 V...2....Z{.....
88F0: 00 00 66 00 00 11 F9 88-00 76 F0 E6 11 F8 F0 F1 ..f......v......
8900: 76 F0 F0 F1 F8 F0 F0 E6-F8 F0 F1 8E FE F0 E7 79 v..............y
8910: F9 F9 9E E6 76 E7 79 88-11 E9 E6 00 00 77 88 00 ....v.y......w..
8920: 7C F1 F9 CF 7C F1 F6 C7-7C F0 F9 CF 7C F1 F6 C7 |...|...|...|...
8930: 7C F0 F9 8F 3F F8 F7 8F-0F FF EF 0F 0F 3F 8F 0F |...?........?..
8940: CF 0F 0F 0F F3 0F 0F 0F-FC CF 0F 0F F0 F3 0F 0F ................
8950: 7C F0 CF 0F EF F0 F3 0F-E3 7C F0 CF E3 EF F0 F3 |........|......
8960: E3 E3 7C F0 E3 E3 EF F0-E3 E3 E3 7C 4F E3 E3 EF ..|........|O...
8970: C7 E3 E3 E3 F7 4F E3 E3-FC C7 E3 E3 F0 F4 4F E3 .....O........O.
8980: FC F0 C7 E3 3F F0 F4 4F-0F FC F0 C7 0F 3F F0 F4 ....?..O.....?..
8990: 0F 0F FC F0 0F 0F 3F F0-0F 0F 0F FC 0F 0F 0F 3F ......?........?
89A0: 0F 0F 0F 3F 0F 0F 0F FC-0F 0F 3F F3 0F 0F FC F0 ...?......?.....
89B0: 0F 3F F0 E3 0F FC F0 7F-3F F0 E3 7C FC F0 7F 7C .?......?..|...|
89C0: F0 E3 7C 7C F0 7F 7C 7C-E3 7C 7C 7C 7F 7C 7C 2F ..||..||.|||.||/
89D0: 7C 7C 7C 3E 7C 7C 2F FE-7C 7C 3E F3 7C 2F F2 F1 |||>||/.||>.|/..
89E0: 7C 3E F0 F3 2F F2 F0 CF-3E F0 F3 0F F2 F0 CF 0F |>../...>.......
89F0: F0 F3 0F 0F F0 CF 0F 0F-F3 0F 0F 0F CF 0F 0F 0F ................
8A00: 20 B3 A0 B3 CC DC 50 DD-FF 20 B3 11 FF CC DD 11  .....P.. ......
8A10: FF FF 11 33 3F FF 11 FF-0F FF 33 FC 0F 7F FF F0 ...3?.....3.....
8A20: FC F7 FF FD 33 F7 FF F1-00 FF FF F1 CC 33 FF F1 ....3........3..
8A30: FF FD FF F1 32 F1 FF F1-FE F3 FF F1 DD FD FF F1 ....2...........
8A40: 11 F1 FF F1 99 F1 FF F1-11 F1 FF F1 11 F1 FF F3 ................
8A50: 99 F3 33 CC 11 FD 00 00-11 F1 00 30 99 E2 00 F3 ..3........0....
8A60: 0F 0F 0F 3F 0F 0F 0F DC-0F 0F 3F A0 0F 0F DC 50 ...?......?....P
8A70: 0F 0F E8 B3 0F 0F DC DC-0F 0F FF A0 0F 0F FF DC ................
8A80: 11 44 30 FF 11 00 F3 FF-33 30 FF FF CC F3 FF 33 .D0.....30.....3
8A90: 30 FF CC CC F3 FF FF 33-FF FF 33 CC FF F7 CC FF 0......3..3.....
8AA0: FE FC FC F8 FE F2 FB F8-FC FE F8 FC F3 FE E8 F3 ................
8AB0: FC FC FC B0 33 F7 F3 E0-FF F7 70 FC DD F7 D0 FB ....3.....p.....
8AC0: 33 F7 F0 F8 DD CC FC F8-11 00 33 F8 33 00 00 FC 3.........3.3...
8AD0: FF 00 00 33 DD 00 00 00-11 00 00 30 33 00 00 F3 ...3.......03...
8AE0: FD 00 30 FF F3 00 F3 FF-CC 30 FF FC 00 F3 FF F3 ..0......0......
8AF0: 30 FF FC B0 F3 FF F3 E0-FF FF FC FC FF FF F3 FB 0...............
8B00: 0F 7F FC F3 0F 7F F0 F3-0F 7F F0 C7 0F 7F F0 C7 ................
8B10: 0F 7F F0 8F 0F 7F F0 8F-0F 7F F3 0F 0F 1F CF 0F ................
8B20: 1F FC FF FF 1F FC F3 FF-1F FC F1 FF 1F FC F1 3F ...............?
8B30: 1F FC E3 0F 1F FC E3 0F-1F FC CF 0F 0F 7F 0F 0F ................
8B40: CF 0F 0F 0F 73 0F 0F 0F-B3 CF 0F 0F CC 73 0F 0F ....s........s..
8B50: 20 B3 0F 0F D8 DD 0F 0F-B3 11 0F 0F DD 11 0F 0F  ...............
8B60: F0 F0 F0 F0 F0 F0 F0 F0-F0 F0 F0 F0 F0 F0 F0 F0 ................
8B70: F0 F0 F0 F0 F0 F0 F0 F0-F0 F0 F0 F0 F0 F0 F0 F0 ................
8B80: 0F 0F 0F 3F 0F 0F 0F CC-0F 0F 3F 00 0F 0F CC 00 ...?......?.....
8B90: 0F 3F 00 00 0F CC 00 00-3F 00 00 00 CC 00 00 00 .?......?.......
8BA0: CF 0F 0F 0F 33 0F 0F 0F-00 CF 0F 0F 00 33 0F 0F ....3........3..
8BB0: 00 00 CF 0F 00 00 33 0F-00 00 00 CF 00 00 00 33 ......3........3
8BC0: 4F 0F 0F 0F 4F 0F 0F 0F-6B 0F 0F 0F 79 0F 0F 0F O...O...k...y...
8BD0: F9 0F 0F 0F 7D 0F 1F 0F-6F 0F 1F 0F FD 0F 1E 8F ....}...o.......
8BE0: F0 B3 E0 B3 DC FC 50 FC-FF E0 B3 E0 FF DC FC 50 ......P........P
8BF0: FF FF E2 B3 3F FF EC FC-1F FF FF E0 1F FF FF DC ....?...........
8C00: A0 B3 A0 B3 50 DC 50 DD-B3 20 B3 11 CC 50 DD 11 ....P.P.. ...P..
8C10: 20 B3 11 33 D8 DD 11 CF-B3 11 33 8F DD 11 77 8F  ..3......3...w.
8C20: 0F 1F F4 F0 0F 3E F3 F0-0F 7C F0 FC 0F FB F0 F3 .....>...|......
8C30: 1F F0 FC F0 3E F0 F3 F0-7C FC F0 FC F8 F3 F0 F3 ....>...|.......
8C40: 0F 0F 0F 1F 0F 0F 0F 3E-0F 0F 0F 7C 0F 0F 0F FB .......>...|....
8C50: 0F 0F 1F F0 0F 0F 3E F0-0F 0F 7C FC 0F 0F F8 F3 ......>...|.....
8C60: 87 0F 0F 0F CB 0F 0F 0F-ED 0F 0F 0F F2 0F 0F 0F ................
8C70: FF 87 0F 0F FF CB 0F 0F-FC ED 0F 0F F3 FE 0F 0F ................
8C80: FF FC 87 0F FF F3 CB 0F-FC FF ED 0F F3 FF F2 0F ................
8C90: FF FC FF 87 FF F3 FF C3-FC FF FC ED F3 FF F3 FE ................
8CA0: 0F 0F 0F 3F 0F 0F 0F CC-0F 0F 3F 00 0F 0F CC 00 ...?......?.....
8CB0: 0F 3F CC 00 0F FC F3 00-3F F0 F0 CC FC F0 F0 F3 .?......?.......
8CC0: CF 0F 0F 0F 33 0F 0F 0F-00 CF 0F 0F 00 33 0F 0F ....3........3..
8CD0: 00 33 CF 0F 00 FC F3 0F-33 F0 F0 CF FC F0 F0 F3 .3......3.......
8CE0: CF 0F 0F 0F 33 0F 0F 0F-00 CF 0F 0F 00 33 0F 0F ....3........3..
8CF0: 00 33 CF 0F 00 CC 33 0F-33 00 00 CF CC 00 00 33 .3....3.3......3
8D00: FE FC FF FC FE F2 FF F2-FC FE FC FE F3 FE F2 FE ................
8D10: FF FC FE FC FF F0 FE F2-FC FC FC FE F2 F3 F3 FE ................
8D20: FF FC FF FC FF F2 FF F2-FC FE FC FE F3 FE F2 FE ................
8D30: FF FC FE FC FF F3 FE F2-FC FF FC FE F2 FF F3 FE ................
8D40: FE FC FF FC FE F2 FF F3-FC FE FC FC F3 76 F3 FF .............v..
8D50: DD FC F3 FC 77 F3 FD F2-FC FF FC FE F3 FF F3 FE ....w...........
8D60: FE FC FF FC FE F2 FF F3-FC FE FC FF F3 76 F3 FF .............v..
8D70: DD FC F3 FC 77 F3 FD F3-FC FF FC FF F3 FF F3 FF ....w...........
8D80: FE FC FF FC FE F2 FF F3-FC FE FC FF F3 76 F3 FF .............v..
8D90: DD FC F3 FC 77 F3 FD F3-FC F3 FC FF F3 F0 FB FF ....w...........
8DA0: FF F0 FF FC FF F0 FF F3-FC FC FC FF F3 F3 F2 FF ................
8DB0: FF F0 FE FC FF F0 FE F2-FC FC FC FE F3 F3 F3 FE ................
8DC0: 0F 0F 0F 3C 0F 0F 0F F3-0F 0F 3C FF 0F 0F C0 F3 ...<......<.....
8DD0: 0F 3C 00 30 0F C0 00 F2-3C CC 30 FE F3 F3 F3 FE .<.0....<.0.....
8DE0: FF F0 FF FC FF F0 FF F2-FC FC FC FE F3 F3 F2 FE ................
8DF0: FF F0 FE FC FF F0 FE F2-FC FC FC FE F3 F3 F3 FE ................
8E00: FF F0 FF FC FF F0 FF F2-FC FC FC FE F3 F3 F2 FE ................
8E10: FF F0 FE FC FF F0 FE C3-FC FC FC 0F C3 3F C3 0F .............?..
8E20: 0F 0F 0F 3F 0F 0F 0F CC-0F 0F 3F 00 0F 0F CC 00 ...?......?.....
8E30: 0F 3F CC 00 0F CC 33 00-3F 00 00 CC CC 00 00 33 .?....3.?......3
8E40: FE F0 FF FC FF F0 F0 F3-F8 FC F8 F1 F0 FB E8 F2 ................
8E50: FC F8 FC B0 FB D8 F3 E0-F8 FC 70 FC F8 F3 D0 FB ..........p.....
8E60: FE FC FF FC FE F2 FF F3-FC FE FC FF F3 76 F2 FF .............v..
8E70: DD FC FE FE 77 F3 76 E1-FC DD FC CB F2 77 F3 87 ....w.v......w..
8E80: FE FC FF 87 FE F2 FE 0F-FC FE FC 0F F3 76 E1 0F .............v..
8E90: DD FC ED 0F 77 F3 43 0F-FC DD CB 0F F2 77 87 0F ....w.C......w..
8EA0: FE FC 0F 0F FE F2 0F 0F-FC FE 0F 0F F3 76 0F 0F .............v..
8EB0: DD FC 0F 0F 77 F2 0F 0F-FC DC 0F 0F F2 76 0F 0F ....w........v..
8EC0: FE FC 0F 0F FE F2 0F 0F-FC FE 0F 0F F3 76 0F 0F .............v..
8ED0: DD FC 0F 0F 77 C3 0F 0F-FC 0F 0F 0F C3 0F 0F 0F ....w...........
8EE0: 0F 3F 8F 0F 0F 3F 8F 0F-0F 3F 8F 0F 0F FF EF 0F .?...?...?......
8EF0: 1F 33 99 0F 1F 91 31 0F-0F CC 67 0F 0F 3F 8F 0F .3....1...g..?..
8F00: 0F 0F 0F 2F 0F 0F 0F 2F-0F 0F 0F 4D 0F 0F 0F 09 .../.../...M....
8F10: 0F 0F 0F 08 0F 8F 0F 22-0F 8F 0F 66 1F 07 0F 2B ......."...f...+
8F20: FE FC FF FC FE F2 FF F3-FC FE FC FF F3 FE F3 FF ................
8F30: DD FC 3F FC FF C3 3F FE-FC 0F 3F FE C3 0F 3F FE ..?...?...?...?.
8F40: FF FE EE FC FF BA FF C3-EE FE F4 0F BB B8 C3 0F ................
8F50: EE FC 0F 0F BB C3 0F 0F-FC 0F 0F 0F C3 0F 0F 0F ................
8F60: 0F 0F 0F 0F 0F 0F 0F 3F-0F 0F 0F FF 0F 0F 3F FF .......?......?.
8F70: 0F 0F F7 EE 0F 3C FF BB-0F FE EE EE 3F FE FF BB .....<......?...
8F80: 0F 0F 7C F3 0F 0F 3F E7-0F 0F 0F CF 0F 0F 0F 0F ..|...?.........
8F90: 0F 0F 0F 0F 0F 0F 0F 0F-0F 0F 0F 0F 0F 0F 0F 0F ................
8FA0: 0F 0F FF FF 0F 0F 7F FF-0F 0F 7F FF 0F 0F 7C FF ..............|.
8FB0: 0F 0F 7C F3 0F 0F 7C F0-0F 0F 7C F0 0F 0F 7C F0 ..|...|...|...|.
8FC0: FC F3 EF 0F FC F0 EF 0F-3E F0 EF 0F 3E F0 EF 0F ........>...>...
8FD0: 1F F0 EF 0F 1F F0 EF 0F-0F FC EF 0F 0F 3F 8F 0F .............?..
8FE0: 11 33 F3 8F 11 FC F3 8F-33 F8 F3 8F CF F8 F3 8F .3......3.......
8FF0: 0F 7C F3 8F 0F 7C F3 8F-0F 3F F3 8F 0F 0F EF 0F .|...|...?......
9000: A0 B3 A0 B3 DC DC 50 DD-FF A0 B3 11 FF DC DD 11 ......P.........
9010: FF FF 11 33 FF FF 11 CC-F3 FF 33 00 F0 FF EE 00 ...3......3.....
9020: 00 33 00 33 00 CC 00 CC-33 00 33 00 CC 00 CC 00 .3.3....3.3.....
9030: CC 00 CC 00 FB 00 FB 00-F8 CC B8 CC F8 F3 E8 FB ................
9040: FC F0 F8 70 3F F0 D8 D0-0F FC F8 70 0F 3F D8 D0 ...p?......p.?..
9050: 0F 0F FC 70 0F 0F 3F F0-0F 0F 0F FC 0F 0F 0F 3F ...p..?........?
9060: 0F 3F 00 33 0F CC 00 CC-3F 00 33 00 CC 00 CC 00 .?.3....?.3.....
9070: CC 00 CC 00 F3 00 FB 00-F0 CC B8 CC F0 F3 E8 FB ................
9080: 00 00 00 33 00 00 00 CF-00 00 33 0F 00 00 CF 0F ...3......3.....
9090: 00 33 0F 0F 00 CF 0F 0F-33 0F 0F 0F CF 0F 0F 0F .3......3.......
90A0: 0F 2E 67 0F 2F 3F CF 0F-5D 2E 47 0F 88 AE 47 0F ..g./?..].G...G.
90B0: BB EE 47 0F 99 EE 8F 0F-5D 7F 0F 0F 2F 0F 0F 0F ..G.....].../...
90C0: FC F0 FF F8 F3 FF FF F4-F7 FE FC FE FF 76 F2 FF .............v..
90D0: DD FC FE FC 77 F3 76 F2-FC DD FC FE F2 77 F3 FE ....w.v......w..
90E0: FC F0 FC F8 F3 F0 FB F8-F0 FC F8 FC F0 FB E8 F3 ................
90F0: F8 F8 FC B0 7F F8 73 F0-3E FC D0 FC 1F F3 E0 FB ......s.>.......
9100: 1F F0 FC F8 0F F8 FB F8-0F FC F8 FC 0F 7F E8 F3 ................
9110: 0F 7C FC B0 0F 3E F3 F0-0F 3E B0 FC 0F 1F E0 FB .|...>...>......
9120: 0F 1F FC F8 0F 1F FB F8-0F 1F F8 FC 0F 1F E8 F3 ................
9130: 0F 1F FC B0 0F 1F F3 E0-0F 1F 70 FC 0F 1F D0 FB ..........p.....
9140: 0F 1F FC F8 0F 1F FB F8-0F 1F F8 FC 0F 1F E8 F3 ................
9150: 0F 0F FC B0 0F 0F 3F E0-0F 0F 0F FC 0F 0F 0F 3F ......?........?
9160: 0F CC 8F 0F 0F 7F 8F 8F-0F 4C 9F 47 0F 4C AE 23 .........L.G.L.#
9170: 0F 4C FF AB 0F 2E FF 23-0F 1F DF 47 0F 0F 0F 8F .L.....#...G....
9180: CF 0F 0F 0F 73 0F 0F 0F-D0 CF 0F 0F 70 F3 0F 0F ....s.......p...
9190: D0 F0 CF 0F 70 70 FB 0F-D0 F0 D8 CF 70 70 F8 73 ....pp......pp.s
91A0: 0F 0F 0F 3F 0F 0F 0F DC-0F 0F 3F A0 0F 0F CC 50 ...?......?....P
91B0: 0F 3F 62 B3 0F CC A0 FC-3F 20 73 E0 DC 50 FC 10 .?b.....? s..P..
91C0: CF 0F 0F 0F 73 0F 0F 0F-B3 CF 0F 0F CC 73 0F 0F ....s........s..
91D0: 20 B3 CF 0F D8 CC B3 0F-B3 20 73 CF DC 50 DC 33  ........ s..P.3
91E0: FC F0 FC F8 FB F0 F3 F8-F8 FC F0 F4 F8 FB F0 F3 ................
91F0: FC F8 FC F0 FB F8 FF F0-F8 FC FC FC F8 F3 F3 FF ................
9200: FC F0 FF FF FB F0 F7 FF-F8 FC F4 FF F8 FB F4 F3 ................
9210: FC F8 FC F0 FB F8 F3 F0-F8 F4 F0 FC F8 F3 F0 FB ................
9220: FC F0 FC F8 F3 F0 FB F8-F3 FC F8 FC FF FF F8 F3 ................
9230: FF FF FC F0 FB FF FF F0-F8 FF FC FC F8 F3 F3 FF ................
9240: FC F0 FC F8 FF F0 FB F8-FC FC F8 FC F3 FF F8 F3 ................
9250: FF FF FC F0 FB FF FF F0-F8 FF FF FC F8 F3 FF FF ................
9260: FC F0 FC F8 FF F0 FB F8-FC FC F8 FC F3 FF F8 F3 ................
9270: FF FF FC F0 FB FF FF F0-F8 FF FC FC F8 F3 F3 F3 ................
9280: FC F0 FF F8 F3 F0 FF F8-F0 FC FC FC F0 FB F3 FB ................
9290: FC F8 FF F8 FB F8 FF F8-F8 FC FC FC F8 F3 F3 FB ................
92A0: FC F0 FC F8 F3 F0 FB F8-F0 FC F8 FC F3 33 F0 F3 .............3..
92B0: CC 00 FC F0 FB 00 33 F0-F8 CC FD FC F8 F3 F3 F3 ......3.........
92C0: FC F0 FF F8 FB F0 FF F8-F8 FC FC FC F8 FB F3 FB ................
92D0: FC F8 FF F8 FB F8 FF F8-F8 FC FC FC F8 F3 F3 FB ................
92E0: FC F0 FF F8 FB F0 FF F8-F8 FC FC FC F8 FB F3 FB ................
92F0: FC F8 FF F8 3F F8 FF F8-0F FC FF FC 0F 3F CF 3F ....?........?.?
9300: FC F0 F0 F0 33 F0 F0 F0-00 FC F0 F0 00 33 F0 F0 ....3........3..
9310: 00 33 F0 F0 00 FF F0 F0-33 FF F0 F0 FF FF F0 F0 .3......3.......
9320: 00 33 FF CC 00 FF FF 00-33 FF CC 00 FF FF 00 00 .3......3.......
9330: FF CC 00 00 FF 00 00 00-CC 00 00 00 00 00 00 00 ................
9340: FF CC FC F0 FF 00 33 F0-CC 00 00 FC 00 00 00 33 ......3........3
9350: 00 00 00 33 00 00 00 FF-00 00 33 FF 00 00 FF FF ...3......3.....
9360: FF CC 00 00 FF 00 00 00-CC 00 00 00 00 00 00 00 ................
9370: 00 00 00 33 00 00 00 FF-00 00 33 FF 00 00 FF FF ...3......3.....
9380: 00 00 00 33 00 00 00 FF-00 00 33 FF 00 00 FF FF ...3......3.....
9390: 00 33 FF CC 00 FF FF 00-33 FF CC 00 FF FF 00 00 .3......3.......
93A0: F0 F0 CC 88 F0 F0 F3 88-F0 F0 F0 CC F0 F0 F0 F3 ................
93B0: F0 F0 F0 F0 F0 F0 F0 F0-F0 F0 F0 F0 F0 F0 F0 F0 ................
93C0: FF FF F0 F0 FF FC F0 F0-FF F0 F0 F0 FC F0 F0 F0 ................
93D0: F0 F0 F0 F0 F0 F0 F0 F0-F0 F0 F0 F0 F0 F0 F0 F0 ................
93E0: 0D 3F CF 0B 07 CF 3F 0D-3F 0F 0F CF CF 06 0E 3F .?....?.?......?
93F0: CF 0B 0D 3F 3F 0F 07 CF-0F CF 3F 0F 0E 3F CF 0E ...??.....?..?..
9400: FC F0 F0 F0 37 F0 F0 F0-3F FC F0 F0 CF 37 F0 F0 ....7...?....7..
9410: CF 0B FC F0 3F 0F 37 F0-0F CF 3F FC 0E 3F CF 3F ....?.7...?..?.?
9420: F8 F0 F0 F0 FC F0 F0 F0-FE F0 F0 F0 76 F0 F0 F0 ............v...
9430: 77 F0 F0 F0 77 F8 F0 F0-57 F8 F0 F0 47 FC F0 F0 w...w...W...G...
9440: F0 F0 F0 F1 F0 F0 F0 F7-F0 F0 F0 EE F0 F0 F1 AE ................
9450: F0 F0 F3 2E F0 F0 F7 2E-F0 F0 DD 2E F0 F1 99 2E ................
9460: 47 FC F0 F0 47 FE F0 F0-47 FE F0 F0 47 FF F0 F0 G...G...G...G...
9470: 47 BB F0 F0 47 BB F8 F0-47 99 F8 F0 CF 99 FC F0 G...G...G.......
9480: F0 F1 11 2E F0 F3 11 2E-F0 F7 11 2E F0 EF DD 2E ................
9490: F0 CF 3F 2E F0 FF 0F EE-F0 CC CF FF F0 FF 33 FF ..?...........3.
94A0: FF 11 FC F0 FF CC FE F0-7F 3F FE F0 7F 0F FF F0 .........?......
94B0: FF CF 7F F0 FF 33 7F F0-FF CC FF F0 FF 3F 33 F0 .....3.......?3.
94C0: F0 CF CC FF F0 CF 3F FF-F0 FF 0F EF F0 CC CF EF ......?.........
94D0: F0 CC 33 FF F0 CC 11 7F-F0 CC 11 3F F0 CC 11 2E ..3........?....
94E0: 77 0F FF F0 47 CF 3F F0-47 BB 3F F0 47 88 FF F0 w...G.?.G.?.G...
94F0: 47 88 33 F0 47 88 33 F0-47 88 33 F0 CF 88 33 F0 G.3.G.3.G.3...3.
9500: F0 CC 11 2E F0 CC 11 2E-F0 FF 11 2E F0 CC DD 2E ................
9510: F0 CC 33 2E F0 CC 11 EE-F0 CC 11 3F F0 CC 11 2E ..3........?....
9520: 77 00 33 F0 47 CC 33 F0-47 BB 33 F0 47 88 FF F0 w.3.G.3.G.3.G...
9530: 47 88 33 F0 47 88 33 F0-47 88 33 F0 CF 88 33 F0 G.3.G.3.G.3...3.
9540: F0 CC 11 2E F0 CC 11 2E-F0 FF 11 2E F0 F3 DD 2E ................
9550: F0 F0 FF 2E F0 F0 F3 EE-F0 F0 F0 FF F0 F0 F0 F3 ................
9560: FF 00 33 F0 F3 CC 33 F0-F0 FF 33 F0 F0 F3 FF F0 ..3...3...3.....
9570: F0 F0 FF F0 F0 F0 F3 F0-F0 F0 F0 F0 F0 F0 F0 F0 ................
9580: 0F 7F F0 9F 8F 0F FC 9B-AF 0F 3F 9F 2F 8F 0F 9B ..........?./...
9590: CF AF 0F 7F 33 2F 8F 1F-00 CF AF 3F CC 33 2F 5D ....3/.....?.3/]
95A0: 33 00 DF 33 0C CC 22 DD-3F 33 33 55 CF 0C DD 55 3..3..".?33U...U
95B0: 0F 3F 5D 55 0F CE 5D 33-3F 06 4C DF CF 06 7F 1B .?]U..]3?.L.....
95C0: F0 F0 F0 F3 F0 F0 F0 CF-F0 F0 F3 47 F0 F0 CC 33 ...........G...3
95D0: F0 F1 33 00 F0 F7 0C CC-F1 8F 0F 33 EF 0F 0F 0C ..3........3....
95E0: F1 2F DF FC F1 2F 6F 7C-F0 9F 8F F8 F0 8F 8F F8 ./.../o|........
95F0: F0 EF BF F8 F0 BF EF F8-F0 AF AF F8 F0 AF AF F8 ................
9600: F0 F1 F8 F0 F0 E7 7E F0-F1 8F 1F F8 E7 6F 6F 7E ......~......oo~
9610: 9F 1F 8F 9F BF 0F 0F DF-9F 1F 8F 9F E7 EF 7F 7E ...............~
9620: F3 AF AF FE E7 6F BF 3F-F7 9F CF FF C7 EF 3F 1B .....o.?......?.
9630: C7 3F EE 1B F3 0F 8A 7E-F0 CF 9B F8 F0 F3 FE F0 .?.....~........
9640: F0 AF AF F8 F0 AF AF F8-F0 AF AF F8 F0 AF AF F8 ................
9650: F0 AF AF F8 F0 AF AF F8-F0 AF AF F8 F0 AF AF F8 ................
9660: EF 0F DF 7F F3 8F DF FC-F1 EF FF F8 E7 7F EF 7E ...............~
9670: 9F 1F 8F 9F BF 0F 0F DF-9F 1F 8F 9F E7 EF 7F 7E ...............~
9680: F0 C5 0F F8 F0 8B 0F 7C-F1 09 0F FC F1 0D EF BE .......|........
9690: F1 07 EF 3A F7 CF 0F BE-F1 FF CF 1F F0 F3 EF BE ...:............
96A0: F0 F0 F0 F1 F0 F0 F0 F3-F0 F0 F0 F7 F0 F0 F0 E6 ................
96B0: F0 F0 F0 EE F0 F0 F1 EE-F0 F0 F1 AE F0 F0 F3 2E ................
96C0: F8 F0 F0 F0 FE F0 F0 F0-77 F0 F0 F0 57 F8 F0 F0 ........w...W...
96D0: 47 FC F0 F0 47 FE F0 F0-47 BB F0 F0 47 99 F8 F0 G...G...G...G...
96E0: F0 F0 F3 2E F0 F0 F7 2E-F0 F0 F7 2E F0 F0 FF 2E ................
96F0: F0 F0 DD 2E F0 F1 DD 2E-F0 F1 99 2E F0 F3 99 3F ...............?
9700: 47 88 F8 F0 47 88 FC F0-47 88 FE F0 47 BB 7F F0 G...G...G...G...
9710: 47 CF 3F F0 77 0F FF F0-FF 3F 33 F0 FF CC FF F0 G.?.w....?3.....
9720: F0 F3 88 FF F0 F7 33 FF-F0 F7 CF EF F0 FF 0F EF ......3.........
9730: F0 EF 3F FF F0 EF CC FF-F0 FF 33 FF F0 CC CF FF ..?.......3.....
9740: FF 33 3F F0 FF CF 3F F0-7F 0F FF F0 7F 3F 33 F0 .3?...?......?3.
9750: FF CC 33 F0 EF 88 33 F0-CF 88 33 F0 47 88 33 F0 ..3...3...3.G.3.
9760: F0 FF 0F EE F0 CF 3F 2E-F0 CF DD 2E F0 FF 11 2E ......?.........
9770: F0 CC 11 2E F0 CC 11 2E-F0 CC 11 2E F0 CC 11 3F ...............?
9780: 47 88 33 F0 47 88 33 F0-47 88 FF F0 47 BB 33 F0 G.3.G.3.G...G.3.
9790: 47 CC 33 F0 77 88 33 F0-CF 88 33 F0 47 88 33 F0 G.3.w.3...3.G.3.
97A0: F0 CC 00 EE F0 CC 33 2E-F0 CC DD 2E F0 FF 11 2E ......3.........
97B0: F0 CC 11 2E F0 CC 11 2E-F0 CC 11 2E F0 CC 11 3F ...............?
97C0: 47 88 33 F0 47 88 33 F0-47 88 FF F0 47 BB FC F0 G.3.G.3.G...G...
97D0: 47 FF F0 F0 77 FC F0 F0-FF F0 F0 F0 FC F0 F0 F0 G...w...........
97E0: F0 CC 00 FF F0 CC 33 FC-F0 CC FF F0 F0 FF FC F0 ......3.........
97F0: F0 FF F0 F0 F0 FC F0 F0-F0 F0 F0 F0 F0 F0 F0 F0 ................
9800: FC F0 F0 F0 3F F0 F0 F0-CF FC F0 F0 3F 3F F0 F0 ....?.......??..
9810: 0F CF FC F0 CF 3F 3F F0-FF 1F CF FC 3F DF 7F 3F .....??.....?..?
9820: CF FF 5F CF F3 3F DF 3F-F0 CF FF 0F F0 F3 3F CF .._..?.?......?.
9830: F0 F0 CF FF F0 F0 F3 3F-F0 F0 F0 CF F0 F0 F0 F3 .......?........
9840: 3F 57 FF 3F CC 77 CF FC-00 FF 3F F0 33 CF FC F0 ?W.?.w....?.3...
9850: FF 3F F0 F0 CF FC F0 F0-3F F0 F0 F0 FC F0 F0 F0 .?......?.......
9860: F0 F0 F0 F3 F0 F0 F0 CF-F0 F0 F3 3F F0 F0 CF CC ...........?....
9870: F0 F3 3F 00 F0 CF CC 33-F3 3F 4C FF CF DF 7F CF ..?....3.?L.....
9880: F0 F0 F0 F0 F0 F0 F0 F0-F0 F0 F0 F0 F0 F0 F0 F0 ................
9890: F0 F0 F0 F3 F0 F0 F0 CC-F0 F0 F3 00 F0 F0 CC 00 ................
98A0: 00 33 00 33 00 CC 00 CC-33 00 33 00 CC 00 CC 00 .3.3....3.3.....
98B0: 00 33 00 00 00 CC 00 00-33 00 00 00 CC 00 00 00 .3......3.......
98C0: F0 F0 F0 F0 F0 F0 F0 F0-F0 F0 F0 F0 FC F0 F0 F0 ................
98D0: 33 F3 FC F0 00 CC 33 F0-33 00 00 FC CC 00 00 33 3.....3.3......3
98E0: F0 F0 F0 F0 F0 F0 F0 F0-F0 F0 F0 F0 FC F0 FC F0 ................
98F0: 33 F3 33 F3 00 CC 00 CC-33 00 33 00 CC 00 CC 00 3.3.....3.3.....
9900: 00 33 00 33 00 CC 00 CC-33 00 33 00 CC 00 CC 00 .3.3....3.3.....
9910: 00 33 00 33 00 CC 00 CC-33 00 33 00 CC 00 CC 00 .3.3....3.3.....
9920: F0 F0 F0 F3 F0 F0 F0 CC-F0 F0 F3 00 F0 F0 CC 00 ................
9930: F0 F0 CC 00 F0 F0 FF 00-F0 F0 FF CC F0 F0 FF FF ................
9940: 33 FF CC 00 00 FF FF 00-00 33 FF CC 00 00 FF FF 3........3......
9950: 00 00 33 FF 00 00 00 FF-00 00 00 33 00 00 00 00 ..3........3....
9960: F0 F3 33 FF F0 CC 00 FF-F3 00 00 33 CC 00 00 00 ..3........3....
9970: CC 00 00 00 FF 00 00 00-FF CC 00 00 FF FF 00 00 ................
9980: 00 00 33 FF 00 00 00 FF-00 00 00 33 00 00 00 00 ..3........3....
9990: CC 00 00 00 FF 00 00 00-FF CC 00 00 FF FF 00 00 ................
99A0: CC 00 00 00 FF 00 00 00-FF CC 00 00 FF FF 00 00 ................
99B0: 33 FF CC 00 00 FF FF 00-00 33 FF CC 00 00 FF FF 3........3......
99C0: F0 F0 F0 F0 F0 F0 F0 F0-F0 F0 F0 F0 F0 F3 F0 F3 ................
99D0: FC CC FC CC 33 00 33 00-00 CC 00 CC 00 33 00 33 ....3.3......3.3
99E0: CC 00 CC 00 33 00 33 00-00 CC 00 CC 00 33 00 33 ....3.3......3.3
99F0: CC 00 CC 00 33 00 33 00-00 CC 00 CC 00 33 00 33 ....3.3......3.3
9A00: CC 00 00 00 F3 00 00 00-F0 CC 00 00 F0 F3 00 00 ................
9A10: F0 F0 CC 00 F0 F0 F3 00-F0 F0 F0 CC F0 F0 F0 F3 ................
9A20: F0 F0 F0 F0 F0 F0 F0 F0-F0 F0 F0 F0 F0 F0 F0 F0 ................
9A30: FC F0 F0 F0 33 F0 F0 F0-00 FC F0 F0 00 33 F0 F0 ....3........3..
9A40: CC 00 CC 00 33 00 33 00-00 CC 00 CC 00 33 00 33 ....3.3......3.3
9A50: 00 00 CC 00 00 00 33 00-00 00 00 CC 00 00 00 33 ......3........3
9A60: F0 F0 F0 F0 F0 F0 F0 F0-F0 F0 F0 F0 F0 F0 F0 F3 ................
9A70: F0 F3 FC CC F0 CC 33 00-F3 00 00 CC CC 00 00 33 ......3........3
9A80: 0F FF FF FF 0F 7F FF FF-0F 3F FF FF 0F 1F FF FF .........?......
9A90: CF 0F FF CF BF 0F FF 1F-8F CF CF 5F 8F 3F 1F 5F ..........._.?._
9AA0: FF FF FE F0 FF FF DF F0-FF FF BF F8 FF FF 7F FC ................
9AB0: FF EF FF FC FF DF FF FE-FF BF FF FE 3F 7F FF FE ............?...
9AC0: F0 F0 F0 F0 F0 F0 F0 F0-F0 F0 F0 F0 FC F0 F0 F0 ................
9AD0: 7F F0 F0 F0 7F FC F0 F0-FF FF F0 F0 FF FF FC F0 ................
9AE0: 0F 0F 0F F0 8F 0F 0F 3C-6F 0F 1F 8F 1F 8F FF FF .......<o.......
9AF0: 1F BF FF FF 7F BF FF FF-FF BF FF EF FF BF FF EF ................
9B00: F0 F0 F0 EF F0 F0 F7 1F-F0 F1 8F 0F F0 F7 0F 0F ................
9B10: F1 8F 6F 0F E7 0F 1F 8F-8F 0F 0F 3F 0F 0F 0F BF ..o........?....
9B20: 9F BF FF DF 8F BF FF DF-0F BF FF BF 1F BF FF BF ................
9B30: 9F BF FF 7F 9F BF FF 7F-FF BC E1 0F EF 78 F0 C3 .............x..
9B40: 0F 0F 1F BF 0F 0F FF BF-0F 3F FF BF 0F FF FF BF .........?......
9B50: 0F FF FF BF 3F FF FF BF-3F FF FF BF FF FF FF BF ....?...?.......
9B60: FF FF FF BF FF FF FF 8F-FF FF FF F0 7F FF FE F0 ................
9B70: 7F FF F8 F0 BF FF F0 F0-BF FE F0 F0 DF FC F0 F0 ................
9B80: DF F8 F0 F0 FF F0 F0 F0-FF F0 F0 F0 FE F0 F0 F0 ................
9B90: FE F0 F0 F0 FC F0 F0 F0-F8 F0 F0 F0 F8 F0 F0 F0 ................
9BA0: C7 0F 1F FF C7 0F 3F FF-8F 0F 3F FF 8F 0F 7F FF ......?...?.....
9BB0: 8F 0F 7F FF 8F 0F 7F FF-8F 0F FF FF 8F 0F FF FF ................
9BC0: F0 C7 0F 5F F0 8F 0F 2F-F1 0F 0F 2F F1 0F 0F 7F ..._.../.../....
9BD0: E3 0F 0F FF E3 0F 0F FF-C7 0F 1F FF C7 0F 1F FF ................
9BE0: F0 F0 F0 C7 F0 F0 F1 8F-F0 F0 E3 0F F0 F0 C7 0F ................
9BF0: F0 F0 8F 0F F0 F1 8F 0F-F0 F1 6F 0F F0 E3 1F 8F ..........o.....
9C00: CF 0F FF FF BF 0F FF FF-8F CF FF FF 8F 3F 0F 0F .............?..
9C10: 8F 0F FF FF 8F 0F FF FF-8F 0F FF FF 8F 0F FF FF ................
9C20: FF FF 9F FC FF FC 9F FC-FF F0 9F FC FC F0 9F FC ................
9C30: F0 F0 9F FC F0 F0 9F FC-F0 F0 9F FC F0 F0 FF FC ................
9C40: F0 F0 F0 30 F7 F8 E0 B8-C7 F8 E0 98 C7 F8 E0 DC ...0............
9C50: C7 F8 F0 B8 C7 F8 F0 F0-C7 F8 F1 FE C7 F8 F1 3E ...............>
9C60: FF F0 F1 3E 66 F8 F1 3E-CC 74 F1 3E F3 33 F9 3E ...>f..>.t.>.3.>
9C70: F0 CC 75 3E F0 C4 33 3F-F0 E2 77 FE F0 F3 F8 FC ..u>..3?..w.....
9C80: C0 F0 F0 F0 D1 70 F1 FE-91 70 F1 3E B3 70 F1 3E .....p...p.>.p.>
9C90: D1 F0 F1 3E F0 F0 F1 3E-F7 F8 F1 3E C7 F8 F1 3E ...>...>...>...>
9CA0: C7 F8 F1 3E C7 F8 F1 3E-C7 F8 F1 3E C7 F8 F1 3E ...>...>...>...>
9CB0: C7 F8 F1 3E C7 F8 F1 3E-C7 F8 F1 3E C7 F8 F1 3E ...>...>...>...>
9CC0: C7 F8 F1 FE C7 F8 E2 FC-C7 F8 C4 76 C7 FB 99 F8 ...........v....
9CD0: C7 CC 76 F0 CF 88 74 F0-F7 CC F8 F0 F3 F3 F8 F0 ..v...t.........
9CE0: F0 F0 F0 F3 F0 F0 F0 CD-F0 F0 F3 CF F0 F0 CE 3F ...............?
9CF0: F0 F3 0D 3F F0 CF 07 CF-F3 CF 3F 0F CE 3F CF 0E ...?......?..?..
9D00: F7 F1 F8 F0 BB EF F8 F0-88 CF FC F0 CC 23 7C F0 .............#|.
9D10: FF 23 FF F0 9F EF BB FC-9D F3 00 FF 9F F0 CC 33 .#.............3
9D20: CF FF 5F CF BF 3F DF 3F-8F CF FF 0F 8F 7F 3F CF .._..?.?......?.
9D30: CF 7F CF FF F3 7F F3 3F-E3 FF F0 CF E3 3F F0 F3 .......?.....?..
9D40: E3 1F F0 F0 F3 1F F0 F0-F0 DF F0 F0 F0 F3 F0 F0 ................
9D50: F0 F0 F0 F0 F0 F0 F0 F0-F0 F0 F0 F0 F0 F0 F0 F0 ................
9D60: F0 F0 9F FC F0 F0 F7 F8-F0 F0 F0 F0 F0 F0 F0 F0 ................
9D70: F0 F0 F0 F0 F0 F0 F0 F0-F0 F0 F0 F0 F0 F0 F0 F0 ................
9D80: FC F0 F0 F0 3F F0 F0 F0-0F FC F0 F0 0F 3F F0 F0 ....?........?..
9D90: 0F 0F FC F0 0F 0F 3F F0-0F 0F 0F FC 0F 0F 0F 3E ......?........>
9DA0: 3F 57 FF 3F CC 77 CF DF-00 FF 3F 1F 33 CF EF 1F ?W.?.w....?.3...
9DB0: FF 3F EF 3F CF FC EF FC-3F F0 FF 74 FC F0 CC 74 .?.?....?..t...t
9DC0: F0 F0 88 74 F0 F0 88 FC-F0 F0 BB F0 F0 F0 FC F0 ...t............
9DD0: F0 F0 F0 F0 F0 F0 F0 F0-F0 F0 F0 F0 F0 F0 F0 F0 ................
9DE0: CF 09 02 05 F3 8F 02 05-F0 F7 02 05 F0 F0 CE 05 ................
9DF0: F0 F0 E3 05 F0 F0 F1 0D-F0 F0 F0 CF F0 F0 F0 F3 ................
9E00: 06 0D 0D 3B 06 0E 1D FC-07 8E FE F0 0B BF F0 F0 ...;............
9E10: 0B FC F0 F0 0B F8 F0 F0-3B F0 F0 F0 FC F0 F0 F0 ........;.......
9E20: 8E 0D 0B 17 06 0D 0B 17-06 0D 0B 17 06 0D 0B 17 ................
9E30: 06 0D 0B 17 06 0D 0B 17-06 0D 0B 17 0E 0D 0B 07 ................
9E40: F0 F0 F0 F3 F0 F0 F0 CF-F0 F0 F3 0F F0 F0 CF 0F ................
9E50: F0 F3 0F 0F F0 CF 0F 0F-F3 0F 0F 0F C7 0F 0F 0F ................
9E60: 0F 0F 0F 0F 0F 0F 0F 0F-0F 0F 0F 0F 0F 0F 0F 0F ................
9E70: 0F 0F 0F 0F 0F 0F 0F 0F-0F 0F 0F 0F 0F 0F 0F 0F ................
9E80: 0F 0F 0F 3E 0F 0F 0F BF-0F 0F 3F 17 0F 0F CF 17 ...>......?.....
9E90: 0F 2F 0B 17 0F CD 0B 17-2E 0D 0B 17 CC 0D 0B 17 ./..............
9EA0: E7 0F 0F 0F 9F 0F 0F 0F-8C CF 0F 0F 8C 3B 0F 0F .............;..
9EB0: 8C 09 4F 0F 8C 09 33 0F-8C 09 02 4F 8C 09 02 37 ..O...3....O...7
9EC0: F0 F1 FC F0 F0 F7 FF F0-F0 97 FF F0 F1 AF 7F F0 ................
9ED0: F7 9D 7F F0 17 9D 7F F0-07 1D 7F F8 17 9D 7F FE ................
9EE0: 83 55 37 FF 81 19 9F FF-E0 04 67 7F F0 15 09 7F .U7.......g.....
9EF0: F0 15 0F 7F F0 15 6F 7F-F0 15 7F FC F0 15 7F F0 ......o.........
9F00: F0 15 7F F0 F0 15 7F F0-F0 15 7F F0 F0 15 7F F0 ................
9F10: F0 15 7F F0 F0 17 7F F0-F0 81 7F F0 F0 E0 74 F0 ..............t.
9F20: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00 ................
9F30: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00 ................
9F40: 8C 09 02 04 8C 09 02 04-8C 09 02 04 8C 09 02 04 ................
9F50: 8C 09 02 04 8C 09 02 04-8C 09 02 04 0C 09 02 04 ................
9F60: F1 0F 0F F8 E7 7F EF 7E-9F FF FF 9F BF FF FF DF .......~........
9F70: CF CF 3F 3F E7 3F CF 7E-F3 8F 1F FC F1 FF FF F8 ..??.?.~........
9F80: 00 2E 00 00 01 DF 2E 00-13 89 9B 00 13 89 CF 88 ................
9F90: 13 89 BF 4C 13 EF 6E 26-01 DF 6E 26 00 2E 6E 26 ...L..n&..n&..n&
9FA0: 00 00 6E 04 00 00 37 08-00 00 03 00 00 00 00 00 ..n...7.........
9FB0: 00 77 00 00 00 47 CC 00-77 EF 3F EE 8F 1F 8F 1F .w...G..w.?.....
9FC0: 33 EF 4F 1F 8F 0F 4F 6E-77 8F 2F 1F 47 0F 0F 1F 3.O...Onw./.G...
9FD0: 33 EF 1F EE 00 8F EE 00-00 77 00 00 00 00 00 00 3........w......
9FE0: 01 4C 00 00 17 AE 00 00-7F 4C 00 00 6F 3F 00 44 .L.......L..o?.D
9FF0: 9F E9 CC BF FF EF 3F 6F-66 77 8F 3D 00 11 EF 6A ......?ofw.=...j
A000: 00 00 77 AE 00 00 11 CC-00 00 00 00 00 00 00 00 ..w.............
A010: 00 11 88 00 00 23 6E 00-00 47 1F CC 66 57 0F 2E .....#n..G..fW..
A020: 9F 8F CF DF 0F 6F 1F AE-0F 1F 3F 44 8F 6F 2E 00 .....o....?D.o..
A030: 67 AF 4C 00 11 8F 88 00-00 77 00 00 00 00 00 00 g.L......w......
A040: BF F0 F3 33 CC FC F0 FF-BF 33 F0 DF 9D CC FC 9B ...3.....3......
A050: 9D F3 33 9F 9F F0 CC 9B-DD F0 F3 9F 3F F0 F0 9B ..3.........?...
A060: EF FD 6F CC 17 AF F9 A6-AB 6F FE BF FF 13 BF EF ..o......o......
A070: F3 AF 6F 5F F0 F7 07 BF-71 FF DF F4 30 FE F2 E0 ..o_....q...0...
A080: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00 ................
A090: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00 ................
A0A0: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00 ................
A0B0: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00 ................
A0C0: 8F 0F 0F FF 8F 0F 1F FF-8F 0F 3F FF 8F 0F 7F FF ..........?.....
A0D0: C7 0F FF CF BF 0F FF 1F-8F CF CF 5F 8F 3F 1F 5F ..........._.?._
A0E0: F0 C7 0F 0F F0 CF 0F 0F-F1 2F 0F 0F E3 1F 0F 0F ........./......
A0F0: E3 0F 8F 0F C7 0F 4F 0F-C7 0F 2F 0F C7 0F 1F 3F ......O.../....?
A100: F0 F0 F0 F0 F0 F0 F0 F0-F0 F0 F0 F0 F0 F0 F0 F3 ................
A110: F0 F0 F0 DF F0 F0 F3 1F-F0 F0 CF 0F F0 F3 0F 0F ................
A120: F0 FF FF FF F3 FF FF EF-FF FF FF 9F EF 7F EF 7F ................
A130: 0F 0F EF 7F 0F 0F 2F 1F-8F 0F 2F 0F 8F 0F 2F 0D ....../.../.../.
A140: F9 F0 F0 F0 F7 FC F0 F0-FF FF F8 F0 FF EF 7E F0 ..............~.
A150: FF 9F FF F8 EF 7F FF FE-3F FF FF FF 2F FF FF FF ........?.../...
A160: 4F 0F 2F 09 4F 0F 2F 01-2F 0F 2F 00 2F 0F 2F 08 O./.O./././././.
A170: 1F 0F 2F 09 1F 0F 2F 09-FF F8 E3 0F FC F0 F0 87 ../.../.........
A180: 2F 7F FF FF 2F 0F FF FF-2F 0F 3F FF 2F 0F 0F FF /.../.../.?./...
A190: 2F 0F 0F FF 2F 0F 0F 3F-2F 0F 0F 3F 2F 0F 0F 0F /.../..?/..?/...
A1A0: EF 0F 0F 0F F3 0F 0F 0F-F0 8F 0F 0F F0 E7 0F 1F ................
A1B0: F0 F1 0F 1F F0 F0 8F 2F-F0 F0 C7 2F F0 F0 E3 4F ......./.../...O
A1C0: F0 F0 F1 4F F0 F0 F0 8F-F0 F0 F0 8F F0 F0 F0 C7 ...O............
A1D0: F0 F0 F0 C7 F0 F0 F0 E3-F0 F0 F0 F1 F0 F0 F0 F1 ................
A1E0: 8F 0F FF CF 8F 0F FF 3F-8F 0F CF FF FF FF 3F FF .......?......?.
A1F0: 8F 0F FF FF 8F 0F FF FF-8F 0F FF FF 8F 0F FF FF ................
A200: 0F 7F FF FE 0F 3F FF FE-0F 3F FF FF 0F 1F FF FF .....?...?......
A210: 0F 1F FF FF 0F 1F FF FF-0F 0F FF FF 0F 0F FF FF ................
A220: 5F FF FE F0 BF FF FF F0-BF FF FF F8 1F FF FF F8 _...............
A230: 0F FF FF FC 0F FF FF FC-0F 7F FF FE 0F 7F FF FE ................
A240: FE F0 F0 F0 FF F8 F0 F0-FF FC F0 F0 FF FE F0 F0 ................
A250: FF FF F0 F0 FF EF F8 F0-FF 9F F8 F0 EF 7F FC F0 ................
A260: 8F 0F FF FF 8F 0F FF FF-8F 0F FF FF C7 0F FF CF ................
A270: BF 0F FF 1F 8F CF CF 5F-8F 3F 1F 5F 8F 0F DF 5F ......._.?._..._
A280: F6 F0 F6 F0 9F F8 9F F0-E7 7E EF F8 E7 9F 1F F8 .........~......
A290: F3 AF 0F 7C F3 CF 01 3E-F1 DF 0E 7E F0 CF FF 5F ...|...>...~..._
A2A0: F1 CF 7F 1F F0 EF 0F 1B-F0 FF EE 5F F0 CC 9F 7E ..........._...~
A2B0: F0 E6 57 FE F0 E6 57 DF-F0 F3 57 5F F0 F1 EF 3E ..W...W...W_...>
A2C0: F0 E3 F8 F0 F0 C7 7C F0-F0 E3 F8 F0 F1 EF FF F0 ......|.........
A2D0: E2 33 88 F8 D7 00 11 7C-E3 AA AB F8 F1 DF 7F F0 .3.....|........
A2E0: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00 ................
A2F0: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00 ................
; -------------- end of the abbey graphics ------------------------

; ------------ start of the object graphics --------------------
A300: 00 00 11 FF 88 00 00 33-FF CC 00 00 77 CB 6A 00 .......3....w.j.
A310: 00 57 FF 6E 00 00 75 7F-6E 00 00 FF B7 2E 00 77 .W.n..u.n......w
A320: F3 DF 4C 11 F8 F2 DF C4-32 F8 E3 FF CC FC F8 F3 ..L.....2.......
A330: ED EE F8 F4 F0 FF EA F9-FE F0 F0 F7 F8 D5 F3 FD ................
A340: FD F8 D5 CF 7A F1 F8 D5-FF 1F F1 77 99 ED 97 F1 ....z......w....
A350: BF 11 FF B7 F1 8F 88 FF-FE E2 57 5D F7 FF C4 57 ..........W]...W
A360: 99 F3 FF 88 33 32 F0 F4-88 00 32 F0 F4 88 00 32 ....32....2....2
A370: F0 F4 C4 00 32 F0 F4 C4-00 32 F0 F4 C4 00 76 F0 ....2....2....v.
A380: F8 C4 00 BF F0 F0 88 00-BD F0 F0 88 00 BF F0 F1 ................
A390: 00 00 9F F1 FF 00 00 57-F2 F1 00 00 22 F8 FF 00 .......W...."...
A3A0: 00 00 75 EE 00 00 00 33-3D 88 00 00 00 8F 4C 00 ..u....3=.....L.
A3B0: 00 00 77 88 00 00 77 EE-00 00 00 FF FF 00 00 11 ..w...w.........
A3C0: FE 1E 88 00 11 7F DF 88-00 11 D7 DF 88 00 11 ED ................
A3D0: CF 88 00 00 FF 5F 00 00-77 FB 7D 00 00 F8 BF FF ....._..w.}.....
A3E0: 00 11 F0 FF B7 00 32 F0-F3 EE 00 74 F0 F1 FD 00 ......2....t....
A3F0: 74 F0 F0 F1 00 32 F0 F0-F1 00 75 FC F0 E2 00 74 t....2....u....t
A400: F7 FF EE CC 74 FB FF EF-2E 74 F0 FF EF 9F 74 F1 ....t....t....t.
A410: FF EF 5F 32 E3 3F FD EE-11 E3 1F FC C4 11 FA 2F .._2.?........./
A420: FB 88 11 F7 5F E2 00 11-F1 FB E2 00 11 F0 F1 E2 ...._...........
A430: 00 11 F0 F1 E2 00 00 F8-F1 E2 00 00 F8 F0 E2 00 ................
A440: 00 F8 F0 E2 00 00 F8 F1-FF 00 00 FF FF 9F 00 00 ................
A450: 32 3D FF 00 00 33 CB 88-00 00 00 77 00 00 00 00 2=...3.....w....
A460: 77 EE 00 00 00 FF FF 00-00 11 FE 1E 88 00 11 7F w...............
A470: DF 88 00 11 D7 DF 88 00-11 ED CF 88 00 00 FF 5F ..............._
A480: 00 00 77 FB 7D 00 00 F8-BF FF 00 00 F8 FF B7 00 ..w.}...........
A490: 11 F0 F3 EE 00 11 F0 F0-E2 00 11 F0 F0 F7 CC 11 ................
A4A0: F0 F0 C7 2E 11 FF FF ED-6E 00 FC F3 F7 4C 00 FC ........n....L..
A4B0: F4 F3 4C 00 FC F0 F1 CC-00 76 F0 F1 88 00 33 F0 ..L......v....3.
A4C0: F1 00 00 33 FF FF 00 00-74 FF EA 00 00 74 F7 E2 ...3....t....t..
A4D0: 00 00 74 F1 E2 00 00 74-F1 E2 00 11 F8 F1 E2 00 ..t....t........
A4E0: 11 F0 F1 E2 00 33 F0 F0-E2 00 57 F0 F8 EE 77 57 .....3....W...wW
A4F0: F8 F5 F1 9E 65 FE F0 F7-3F 23 7F F8 CF EE 32 1F ....e...?#....2.
A500: 77 57 CC 11 EE 00 33 00-00 11 FF CC 00 00 67 F7 wW....3.......g.
A510: A6 00 00 76 FF 2E 00 00-77 FF 6E 00 00 33 EF 5F ...v....w.n..3._
A520: 00 00 11 F3 5F 00 00 77-3F 6E 00 00 FB BF 4C 00 ...._..w?n....L.
A530: 11 F0 FF DD 00 76 F0 F1-AB CC FA F0 FE D5 2E FA .....v..........
A540: F3 F0 E3 1F F9 F4 F0 F1-9F 74 F8 F0 F1 DF 76 F0 .........t....v.
A550: F0 FF F3 F9 FC F3 FE F9-F9 FF FF F8 F9 F9 FF FF ................
A560: F0 F1 75 FF FF F8 E2 33-F7 FF FC CC 32 F3 FF F7 ..u....3....2...
A570: 00 32 F0 F0 C4 00 32 F0-F0 C4 00 32 F0 F0 C4 00 .2....2....2....
A580: 33 FC F0 AA 00 74 F0 F0-DF 00 77 F8 F0 9F 00 74 3....t....w....t
A590: F6 F1 9F 00 77 F0 F1 2E-00 77 F8 E3 2E 00 33 FC ....w....w....3.
A5A0: D5 A6 00 65 FC 88 CC 00-9F 3F 00 00 00 CF 0F 88 ...e.....?......
A5B0: 00 00 33 FF 00 00 00 00-11 FF CC 00 00 67 F7 A6 ..3..........g..
A5C0: 00 00 76 FF 2E 00 00 77-FF 6E 00 00 33 EF 5F 00 ..v....w.n..3._.
A5D0: 00 11 7B 5F 00 00 FF 3F-6E 00 11 F3 BF 4C 00 32 ..{_...?n....L.2
A5E0: F0 FF CC 00 32 F0 F3 00-00 74 F3 FC 88 00 32 FF ....2....t....2.
A5F0: F0 C4 88 75 FC F0 F7 4C-74 F8 F0 E7 88 32 F1 FC ...u...Lt....2..
A600: E7 88 11 FE F3 FE 4C 00-FE F0 FB 88 00 FF F0 CC ......L.........
A610: 00 00 FF F0 CC 00 11 F7-F0 CC 00 32 F1 F8 CC 00 ...........2....
A620: 32 F1 FF CC 00 32 E3 DA-CC 00 33 F1 1F C4 00 74 2....2....3....t
A630: F0 FE C4 00 77 F0 F0 C4-00 F8 F8 F0 C4 00 FE F4 ....w...........
A640: F0 E6 00 7B F0 F0 F3 88-BD F8 F0 E5 4C BF FC F0 ...{........L...
A650: CF 88 CB FF F9 BF 00 77-00 66 CC 00 00 32 F0 E2 .......w.f...2..
A660: 00 00 76 F0 F7 88 00 77-FF 00 11 BD ED 88 11 FB ..v....w........
A670: CF 88 11 FF DF 88 00 FF-9F 4C 00 74 DF 4C 11 CF .........L.t.L..
A680: DF CC 32 EF DF 00 74 F7-FF 00 F8 F0 C4 00 F8 F3 ..2...t.........
A690: E2 00 F8 FC F1 00 F5 F1-F0 88 F2 F2 F0 88 F8 F0 ................
A6A0: F0 88 76 F3 FE 88 33 FC-F3 00 33 FC F7 44 33 FC ..v...3...3..D3.
A6B0: F3 AE 75 FC F1 97 74 F6-F0 9F 74 F3 F1 2E 74 F1 ..u...t...t...t.
A6C0: FF CC 75 F0 F1 00 74 F8-F1 00 74 F8 F1 00 74 F8 ..u...t...t...t.
A6D0: F1 00 74 F0 F1 00 74 F0-F1 00 F8 F8 F1 00 76 F8 ..t...t.......v.
A6E0: F0 88 11 F0 F3 88 00 FF-EE 00 00 00 FF CC 00 00 ................
A6F0: 55 7B FF 00 00 77 FF FF-88 00 77 FF 1E 88 00 33 U{...w....w....3
A700: 6F DF 88 00 77 EF DB 00-00 11 CF 5B 00 00 11 ED o...w......[....
A710: AE 00 00 76 BE 4C 00 00-FA FF EA 00 11 F1 F7 E2 ...v.L..........
A720: 00 33 F8 F8 F5 00 74 F8-F6 F0 88 F8 F4 F0 F0 88 .3....t.........
A730: F9 FE F3 FB CC F8 FF CF-7E C4 F8 BB FF B7 E2 74 ........~......t
A740: FF EF 9F E2 33 7D FF FE-E2 47 7C F3 F3 C4 23 FC ....3}...G|...#.
A750: F1 F3 88 11 74 F1 E2 00-00 74 F1 E2 00 00 74 F1 ....t....t....t.
A760: E2 00 00 76 F1 E6 00 00-BE F0 C4 00 00 BE F7 CC ...v............
A770: 00 00 BF F0 C4 00 00 75-F7 C8 00 00 33 FC EE 00 .......u....3...
A780: 00 00 76 1F 00 00 00 11-FF 00 00 11 FF 88 00 00 ..v.............
A790: 23 F7 EE 00 00 77 FF FF-00 00 FF EF 3D 00 00 67 #....w......=..g
A7A0: DF AE 00 00 FF DF A6 00-00 FF 8F A6 00 00 33 DB ..............3.
A7B0: 4C 00 00 33 6D 88 00 00-75 FF 00 00 00 FC FC 88 L..3m...u.......
A7C0: 00 11 F2 F1 C4 00 32 F0-F0 C4 00 75 FE F0 C4 00 ......2....u....
A7D0: 76 F3 F0 FF 00 32 F3 FF-CF 88 32 F5 FF ED 88 32 v....2....2....2
A7E0: F0 DF FF 00 11 F1 8F CC-00 00 F9 DB 88 00 00 FC ................
A7F0: FF 88 00 00 FB FF C4 00-00 F8 F6 C4 00 00 F8 F2 ................
A800: C4 00 00 F8 F2 C4 00 00-F8 F4 C4 00 11 F0 F4 C4 ................
A810: 00 11 F0 F4 E2 00 11 F0-F1 CC 00 00 FB FF 2E 00 ................
A820: 00 76 3F CC 00 00 11 CC-00 00 00 00 FF CC 00 00 .v?.............
A830: 11 7B FF 00 00 77 FF FF-88 00 33 FF 1E 88 00 77 .{...w....3....w
A840: 6F DF 00 00 77 EF DB 00-00 44 CF 5B 00 00 11 ED o...w....D.[....
A850: AE 00 00 32 BE 4C 00 00-FC FF 88 00 11 FA F6 88 ...2.L..........
A860: 00 33 F9 F0 CC 00 33 F0-F0 E6 00 11 FF F0 FD 00 .3....3.........
A870: 00 F8 FF 9F 00 00 F8 F7-9F 00 00 F8 F8 EA 00 00 ................
A880: 74 F0 CC 00 00 74 F0 C4-00 00 FA F1 88 00 00 F9 t....t..........
A890: FE 88 00 00 F8 F2 C4 00-00 F8 F2 C4 00 11 F8 F2 ................
A8A0: C4 00 11 F0 F2 E6 00 00-F8 F2 F9 00 11 FC F0 F7 ................
A8B0: 88 11 F6 F0 EF 4C 11 F3-FF F9 CC 00 CB 88 BF 88 .....L..........
A8C0: 00 77 00 66 00 00 77 FF-00 00 BD FF 00 11 FF FD .w.f..w.........
A8D0: 00 11 FF CF 88 77 EF BF-88 33 FE AF 88 00 BF 2D .....w...3.....-
A8E0: 88 77 FB 5F 00 F8 FF AE-00 F8 F1 CC 00 F8 F2 88 .w._............
A8F0: 00 F8 FE CC 00 F9 F8 E2-00 FE F0 F1 00 F8 F0 FF ................
A900: 00 FF F1 FB CC FB FE F2-2E 77 FE F1 AE 33 FF F0 .........w...3..
A910: AE 74 FF F8 EE 74 F0 F7-88 74 F0 E2 00 75 F0 E2 .t...t...t...u..
A920: 00 74 F8 EA 00 74 F8 E2-00 74 F8 EA 00 FC F0 FB .t...t...t......
A930: 00 F8 F0 F9 00 76 F0 E6-00 11 FF 88 00 00 33 FF .....v........3.
A940: 00 00 56 FF 88 00 FF FE-88 00 FF EF 4C 11 FF D7 ..V.........L...
A950: 88 00 FF 5F 4C 11 FF 9E-4C 32 F7 AF 88 32 F0 DF ..._L...L2...2..
A960: 00 76 F0 E6 EE FA F3 F3-9F FA F4 F2 FF FA F8 F4 .v..............
A970: F9 F9 F0 F1 F5 F9 FC F2-F1 F9 FF FE E2 67 FF FF .............g..
A980: CC 47 FF FF 88 33 FF FE-88 00 F9 F8 88 00 F8 F0 .G...3..........
A990: 88 00 F8 F0 CC 11 FE F0-EA 32 F1 F1 AE 33 FC F3 .........2...3..
A9A0: 6A 32 7E F6 4C 65 FB 99-88 32 1E 88 00 11 FF 00 j2~.Le...2......
A9B0: 00 00 00 00 00 00 33 FF-00 00 56 FF 88 00 FF EF ......3...V.....
A9C0: 88 00 FF EF 4C 11 FF D7-88 11 FF 5F 4C 32 FF 9E ....L......_L2..
A9D0: 4C 74 F1 AF 88 F8 FE DF-00 77 FE E6 00 74 F0 C4 Lt.......w...t..
A9E0: CC 33 F3 DD A6 33 FE F7-2E 33 FC F5 6A 11 F8 FD .3...3...3..j...
A9F0: CC 11 F8 EE 00 33 F8 CC-00 67 FF CC 00 76 97 CC .....3...g...v..
AA00: 00 75 FF C4 00 74 F0 E2-00 74 F0 E2 00 76 F0 E2 .u...t...t...v..
AA10: 00 75 F8 F3 00 F8 F6 F1-00 FF F0 F1 EE 9F F8 F3 .u..............
AA20: 3D ED FC E7 6E 77 7B DF-88 00 CC 22 00 F0 88 00 =...nw{...."....
AA30: 77 F8 F0 FF 00 47 FC F1-9E 00 76 7E F3 3F 00 33 w....G....v~.?.3
AA40: BD EF CC 00 00 66 11 00-00 00 00 00 00 00 00 00 .....f..........
AA50: 00 00 00 11 EE 00 00 00-00 77 FD 00 00 00 11 FF .........w......
AA60: F1 00 00 00 77 FC F1 00-00 11 FF F1 FD 00 00 77 ....w..........w
AA70: FC F1 3F 00 11 FF F1 FC-FD 00 77 FC F1 3E F5 11 ..?.......w..>..
AA80: FF F1 FC FC F7 77 FC F1-3E F0 DF F3 F1 FC FC F1 .....w..>.......
AA90: 1F F4 F1 3E F0 F1 3F F5-FC FC F7 F1 FD F5 3E F1 ...>..?.......>.
AAA0: BF F9 F5 F5 FC E3 BF F8-F5 F5 F0 E3 9F F8 F5 F5 ................
AAB0: F0 E7 3F F8 F5 F5 FC C7-BF F8 F7 F3 7C E7 BF F8 ..?.........|...
AAC0: DF CF 7C E7 9F F9 1F CF-FC E7 3F F9 3F F3 F0 C7 ..|.......?.?...
AAD0: BF F9 FD F5 F0 E7 FE F1-F5 F5 F0 F7 F9 F8 F5 F5 ................
AAE0: F0 F6 F6 F0 F5 F5 F0 F1-F8 F1 FD F5 FC F6 F0 F1 ................
AAF0: 3F F3 7C F0 F1 FC FD CF-7C F0 F1 3E E6 CF FC F1 ?.|.....|..>....
AB00: FC FD 88 F3 F0 F1 3E E6-00 F5 F1 FC FD 88 00 F5 ......>.........
AB10: F1 3E E6 00 00 F5 FC FD-88 00 00 F5 3E E6 00 00 .>..........>...
AB20: 00 F4 FD 88 00 00 00 F4-E6 00 00 00 00 F5 88 00 ................
AB30: 00 00 00 62 00 00 00 00-00 FF FF 13 89 13 89 13 ...b............
AB40: 89 01 01 88 13 CC 37 EE-7F FF FF CC 13 EE 37 EE ......7.......7.
AB50: 37 EE 37 EE 37 EE 37 CC-13 72 FF FF FF C8 F7 F7 7.7.7.7..r......
AB60: FF FF EC F7 F9 FF 7E F6-F7 FC C7 3D FE F6 F4 F6 ......~....=....
AB70: 1F FE F7 F8 E3 96 FE F7-F8 F1 3C FE BF FA F1 FD ..........<.....
AB80: EC 8F FB F0 F5 C8 57 7F-FF FC 80 57 FB FF FA 00 ......W....W....
AB90: 22 73 FF FB 80 00 73 FF-FB 80 00 73 FF FB 80 00 "s....s....s....
ABA0: 73 FF FB 80 00 75 FF F7-80 00 FD FF FF 80 00 BE s....u..........
ABB0: FF FE 00 00 BE FF E0 00-00 9F F6 FE 00 00 75 F7 ..............u.
ABC0: F1 00 00 33 F6 FE 00 00-00 71 EE 00 00 00 11 1F ...3.....q......
ABD0: 88 00 00 00 8F 4C 00 00-00 77 88 73 FF FF FE 00 .....L...w.s....
ABE0: F7 FF FF FF 80 FC FF FF-FF 80 F3 F3 FF FE 00 73 ...............s
ABF0: FC FF FD 00 73 FC F0 F3-CC 73 F2 F0 E7 2E 73 FD ....s....s....s.
AC00: FE EF BD 73 EF 3F FB 5F-31 EB 1F FB EE 30 E7 2F ...s.?._1....0./
AC10: FB CC 31 FF 5F FC 80 31-FF FF EC 00 31 FF FE EC ..1._..1....1...
AC20: 00 10 FF FE EC 00 10 FF-FE EC 00 10 FF FE EC 00 ................
AC30: 10 FF FF EC 00 31 FF FF-FE 00 31 FC F7 F9 00 10 .....1....1.....
AC40: F3 FF 97 00 00 76 3D FF-00 00 11 8F 88 00 00 00 .....v=.........
AC50: 77 00 00 73 FF FD FF 88-70 F3 FE E2 00 F6 FC F7 w..s....p.......
AC60: FF 88 72 FF F9 AD 4C 11-F7 FD CF C4 11 F7 FF ED ..r...L.........
AC70: 88 00 FB FF ED 88 00 F8-FF FC 88 00 F8 F3 FF 80 ................
AC80: 00 F6 F0 F3 80 00 F7 F8-F3 80 00 F7 FD FC 00 00 ................
AC90: F7 FE FE 00 00 F7 FE FE-00 00 F7 FE FE 00 10 F7 ................
ACA0: FE FE 00 10 FF FE FF 00-32 FF FF FC 00 75 F7 F7 ........2....u..
ACB0: F3 77 57 FB FA FF 9E 56-FD FF FF 3F 23 D4 F7 C7 .wW....V...?#...
ACC0: EE 32 1F 70 57 CC 11 EE-00 33 00 F5 FF F1 DD 6E .2.pW....3.....n
ACD0: F5 FC FF FF 9F F6 FB FF-FF 9F F7 F7 FF FD DF F9 ................
ACE0: FF FF F1 FF FE F7 FC FE-FE FE F0 F1 FE FE FF F0 ................
ACF0: F5 FF FE BF F0 F5 FF EC-BF FC F2 FF C0 77 FF FF .............w..
AD00: F0 00 73 FF FF C8 00 73-FF FF C8 00 73 FF FF C8 ..s....s....s...
AD10: 00 73 FF FF EA 00 73 FF-FF D7 00 74 FF FE 9F 00 .s....s....t....
AD20: 77 F3 FE 9F 00 F9 FD FD-2E 00 FE F7 EB 2E 00 77 w..............w
AD30: FB DD 2E 00 47 FC C4 CC-00 9F 3F 00 00 00 CF 0F ....G.....?.....
AD40: 88 00 00 33 FF 00 00 00-31 FF FF CC 00 73 FF FF ...3....1....s..
AD50: EC 00 30 FF F8 FA 00 11-F7 F7 F3 88 11 F1 F7 FB ..0.............
AD60: 4C 11 F0 FF EB 2E 10 FC-FF EB AE 31 FE FF F5 44 L..........1...D
AD70: 31 FE FF C4 00 31 FF F3-C0 00 73 FF FC 80 00 73 1....1....s....s
AD80: DF 3F 80 00 73 ED 7B 80-00 72 FF F7 80 00 73 FB .?..s.{..r....s.
AD90: FF C8 00 73 FD FB C8 00-73 FE F7 EC 00 F5 FB FF ...s....s.......
ADA0: EC 88 FF FD FB FB 4C 3E-FE F7 E7 4C DF F7 FE E9 ......L>...L....
ADB0: 88 8F FB EC DB 00 77 30-C0 66 00 F5 FC FF EC 00 ......w0.f......
ADC0: F6 F3 FF C8 00 F7 FF FF-C8 00 F7 FF FC C4 00 FB ................
ADD0: FF F2 CC 00 F9 FC FE 88-00 FC F3 FE CC 00 F4 F3 ................
ADE0: F9 BF 00 72 F1 FF 8F 88-31 F9 FF CF 88 73 FE F3 ...r....1....s..
ADF0: DB 00 73 FF FC E6 00 73-FF FF 80 00 72 FF FF 80 ..s....s....r...
AE00: 00 73 F7 FD 80 00 73 F7-FF 80 00 73 FF FF 80 00 .s....s....s....
AE10: 73 FF FD 80 00 72 FF FD-80 00 F7 F1 FD 80 00 73 s....r.........s
AE20: FF FD C8 00 30 FF FE 80-00 10 F0 E0 00 00 FF C8 ....0...........
AE30: 00 31 FF FF A2 00 31 FF-FF D3 00 71 F7 FF 97 00 .1....1....q....
AE40: 73 F9 FE 97 00 70 FF FE-2E 00 70 F7 ED 2E 00 30 s....p....p....0
AE50: F3 D9 2E 00 47 F3 80 CC-00 9F 3C 00 00 00 CF 0F ....G.....<.....
AE60: 88 00 00 33 FF 00 00 00-72 F3 FF FA 00 73 F7 FF ...3....r....s..
AE70: FB 80 31 FF FF FA 4C 10-F1 FF E9 2E 00 F0 F4 E7 ..1...L.........
AE80: AE 00 F0 F7 D9 44 00 F0-FF C8 00 10 F8 FE C4 00 .....D..........
AE90: 31 FE FF CC 00 31 FE FF-C8 00 31 FE FF C0 00 31 1....1....1....1
AEA0: FF F6 4C 00 31 FF E9 2E-00 70 FD FC 2E 00 F7 FC ..L.1....p......
AEB0: ED 5F 00 F1 FE F6 E2 00-3C FE F7 D9 88 9E F7 F3 ._......<.......
AEC0: CB 4C BF F3 FF CB 88 8F-F9 FF B7 00 77 10 F0 44 .L..........w..D
AED0: 00 FA FF F7 80 00 FD FE-FF 80 00 F7 FF FF 80 00 ................
AEE0: 70 FE F0 80 00 30 F1 FE-80 00 30 F3 FE 00 00 30 p....0....0....0
AEF0: F3 F8 22 00 72 F3 FF D7-00 73 F3 FF 87 00 72 FB ..".r....s....r.
AF00: FF C7 00 72 FD FC 97 00-72 FE F2 66 00 72 FF FE ...r....r..f.r..
AF10: 00 00 72 FF FE 00 00 72-FF FE 00 00 72 FF FE 00 ..r....r....r...
AF20: 00 73 FD FE 00 00 73 FD-FE 00 00 31 FE FE 00 00 .s....s....1....
AF30: 30 FF FC 00 00 00 F0 E0-00 00 6D 32 20 01 00 20 0.........m2 ..
AF40: 02 00 6D 32 01 00 32 01-00 6D 01 00 6D 08 00 6D ..m2..2..m..m..m
AF50: 31 20 20 20 20 06 1E 01-00 1E 07 00 6D 31 20 20 1    .......m1
AF60: 20 20 06 01 00 06 06 00-6D 31 20 20 20 20 01 00   ......m1    ..
AF70: 20 05 00 6D 31 20 20 20-01 00 20 04 00 6D 31 20  ..m1   .. ..m1
AF80: 20 01 00 20 03 00 6D 31-20 01 00 20 02 00 6D 31  .. ..m1 .. ..m1
AF90: 01 00 31 01 00 6D 01 00-6D 08 00 67 75 69 33 20 ..1..m..m..gui3
AFA0: 20 05 22 01 00 22 07 00-67 75 69 33 20 20 05 01  .".."..gui3  ..
AFB0: 00 05 06 00 67 75 69 33-20 20 01 00 20 05 00 67 ....gui3  .. ..g
AFC0: 75 69 33 20 01 00 20 04-00 67 75 69 33 01 00 33 ui3 .. ..gui3..3
AFD0: 03 00 67 75 69 01 00 69-02 00 67 75 01 00 75 01 ..gui..i..gu..u.
AFE0: 00 67 01 00 67 00 00 00-00 00 00 00 00 00 00 00 .g..g...........
AFF0: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00 ................
B000: 00 00 00 00 00 00 00 00-00 00 11 FF 88 00 00 33 ...............3
B010: FF 88 00 00 77 8F 2E 00-00 57 FF 6E 00 00 57 7F ....w....W.n..W.
B020: 6E 00 77 FF 3F 2E 00 74-F3 DF 4C 11 FC E3 DF 4C n.w.?..t..L....L
B030: 32 F4 E3 FF CC FC F2 F3-CF EE F8 F3 F0 FF EA F9 2...............
B040: DD F8 F0 E6 F8 D5 FF 7F-FD F8 D5 CF 3E F1 F8 D5 ............>...
B050: EF 1F F1 77 99 EF 1F F1-BF 11 FF 3F F1 8F 88 FF ...w.......?....
B060: FE E2 57 5D F7 FF C4 57-11 F3 FF 88 22 32 F0 F4 ..W]...W...."2..
B070: 88 00 32 F0 F4 88 00 32-F0 F4 C4 00 32 F0 F4 C4 ..2....2....2...
B080: 00 32 F0 F4 C4 00 76 F0-F8 C4 00 BF F0 F0 88 00 .2....v.........
B090: 9F F0 F0 88 00 BF F0 F1-00 00 9F F0 FD 00 00 57 ...............W
B0A0: F0 E2 00 00 22 F8 E2 00-00 00 77 CC 00 00 00 11 ....".....w.....
B0B0: 0E 00 00 00 00 8F 08 00-00 00 77 88 00 00 77 EE ..........w...w.
B0C0: 00 00 00 FF EE 00 00 11-EF 0F 88 00 11 7F DF 88 ................
B0D0: 00 11 5F DF 88 00 11 CF-CF 88 00 00 FF 5F 00 00 .._.........._..
B0E0: 77 BF 5F 00 00 F8 BF FF-00 11 F0 FF 3F 00 32 F0 w._.........?.2.
B0F0: F3 EE 00 74 F0 F1 FD 00-74 F0 F0 F1 00 32 F0 F0 ...t....t....2..
B100: F1 00 75 00 22 FF FF 88-00 75 F8 BD 88 00 74 F4 ..u."....u....t.
B110: 9E 88 00 32 F1 0F C4 00-32 FF EF CC 00 11 BF A7 ...2....2.......
B120: 88 00 F0 FF A7 88 00 F7-F7 FF 88 10 FF FB DF 88 ................
B130: 30 FF FF EE 00 00 75 FF-88 00 00 FB F9 C4 00 00 0.....u.........
B140: FA F1 AE 00 00 74 F3 9F-00 00 32 F7 7F 00 00 33 .....t....2....3
B150: FD 5F 00 10 F0 F7 DF 00-11 FF FB EE 00 11 FF FD ._..............
B160: DF 00 31 FF FE EE 00 00-00 00 00 00 00 00 FF FF ..1.............
B170: 00 00 11 7E F3 88 00 67-F8 F1 88 00 EB FB FB 00 ...~...g........
B180: 00 DF FC F9 00 00 73 FF-FB 00 00 F5 CF DF 00 10 ......s.........
B190: FE BF EF 88 31 FE FF 3F-00 00 66 FF CC 00 00 BF ....1..?..f.....
B1A0: 6F EE 00 00 CF DF F9 00-00 BF BF F7 00 00 47 F7 o.............G.
B1B0: F5 00 00 F7 FF FD 00 10-F8 FF 2E 00 31 FF E7 EE ............1...
B1C0: 00 73 FF F7 AE 00 73 FF-FB EE 00 00 00 00 00 00 .s....s.........
B1D0: 00 00 33 FF 00 00 00 77-C3 EE 11 FF FF EF 6E 32 ..3....w......n2
B1E0: FC FF CB A6 32 F7 DF F7-6E 32 F0 F7 B5 6A 11 F1 ....2...n2...j..
B1F0: FB 7F CC 32 F7 FD FC C4-75 FF FE FC CC 00 00 00 ...2....u.......
B200: 00 00 00 00 FF 88 00 00-33 E9 4C 00 00 33 FF AE ........3.L..3..
B210: 00 00 FF FF 9F 00 11 F0-EF BF 00 11 F0 F7 AF 88 ................
B220: 11 FE F3 7F 00 32 F3 FB-7D 00 31 FD FD FD 00 00 .....2..}.1.....
B230: 00 70 E0 00 00 00 F7 FF-80 00 30 ED 7F CC 00 73 .p........0....s
B240: FF 9E CC 00 F7 FE 8F C4-30 F7 AF EF CC 73 FB FA ........0....s..
B250: 2F C4 73 F1 FE FF CC 72-FE FF 9F 88 31 FF F3 FF /.s....r....1...
B260: 00 00 00 F0 80 00 00 30-FF EE 00 00 73 9E FD 00 .......0....s...
B270: 00 F7 FF DB 00 10 FF FF-CF 88 10 FF DF BF 00 30 ...............0
B280: F3 FF AF 88 73 FC FF F7-00 73 FF E7 DF 00 30 F1 ....s....s....0.
B290: FB EE 00 00 00 00 FF CC-00 00 11 FD EE 00 00 33 ...............3
B2A0: F8 DF 00 00 33 FC 1F 00-00 23 FC 5B 00 00 32 BF ....3....#.[..2.
B2B0: EA 00 00 FB DA BD 00 33-F9 FC AE 00 F7 FB 7F EE .......3........
B2C0: 10 F7 FD F7 6E 00 31 FF-EC 00 00 73 FD EC 00 00 ....n.1....s....
B2D0: F7 FE 6C 00 00 F7 FF AE-00 00 F7 FB A6 00 00 F7 ..l.............
B2E0: ED CC 00 00 73 ED AE 00-30 E7 FE AE 00 73 FF FB ....s...0....s..
B2F0: CC 00 F3 FF FF 4C 00 00-00 FF CC 00 00 00 F8 E2 .....L..........
B300: 00 00 11 F0 F1 00 00 71-F3 FF 88 00 73 E7 DF 00 .......q....s...
B310: 00 73 FD FB 00 00 F7 FF-FB 00 00 F5 CF DF 00 10 .s..............
B320: FE BF E3 88 31 FE FF FF-80 00 11 FF CC 00 00 32 ....1..........2
B330: F0 C4 00 00 74 F0 E2 00-00 74 FE EE 00 00 F5 FB ....t....t......
B340: 4C 00 10 FF FE EA 00 10-FF FF EA 00 10 F0 F7 4C L..............L
B350: 00 31 FF FB 4C 00 31 FF-F3 88 00 00 FF FE C0 00 .1..L.1.........
B360: 11 F1 FF EC 00 11 F4 F0-FE 00 32 FE F3 FF 80 11 ..........2.....
B370: F7 F7 FF 80 00 F7 F7 FF-80 10 FF FB FE 00 10 FB ................
B380: FB FE 00 31 FD FB FE 00-73 FD FC FF 80 11 88 00 ...1....s.......
B390: 00 00 32 F7 EE 00 00 75-F0 F5 00 00 75 F8 F0 CC ..2....u....u...
B3A0: 00 22 FE F0 CC 00 00 F8-F0 CC 00 31 FC F1 88 00 .".........1....
B3B0: 72 F7 F1 88 00 F7 F9 FD-88 00 F7 FE F5 88 00 FC r...............
B3C0: F0 8F 74 F4 F0 CF 74 F2-F3 9F 74 F1 FD 66 74 F0 ..t...t...t..ft.
B3D0: F1 00 74 F0 F1 00 74 F0-F1 00 74 F0 F1 00 74 F0 ..t...t...t...t.
B3E0: F1 00 74 F0 F1 00 32 F0-F0 88 33 F0 F3 88 00 FF ..t...2...3.....
B3F0: EE 00 00 00 FF CC 00 00-11 3F FF 88 00 33 FF FF .........?...3..
; ------------ end of the object graphics --------------------

; table with the graphic data of the characters used during the game
B400: 	00 76 DB DB F3 C3 C3 81 ; 0x2d -> PL
	00 39 6D 60 78 60 2C 98 ; 0x2e -> ET (half t)
	00 FB 66 66 67 66 66 42 ; 0x2f -> TA (half t and half a)
	00 7C EE C6 C6 C6 EE 7C ; 0x30 -> 0
	00 18 38 38 18 18 3E 7C ; 0x31 -> 1
	00 78 FC 9C 38 70 E6 FC ; 0x32 -> 2
	00 7E CC 98 3C 0E CE 7C ; 0x33 -> 3
	00 60 C8 D8 7E 18 18 10 ; 0x34 -> 4
	00 FC 66 60 7C 0E CE 7C ; 0x35 -> 5
	00 3C 60 DC F6 C2 E6 7C ; 0x36 -> 6
	00 7E E6 0E 1C 38 30 30 ; 0x37 -> 7
	00 7C EE C6 7C C6 EE 7C ; 0x38 -> 8
	00 7C CE 86 DE 76 0C 78 ; 0x39 -> 9
	00 00 00 30 30 00 30 30 ; 0x3a -> :
	00 00 00 18 18 00 18 30 ; 0x3b -> ;
	00 00 00 00 00 00 18 30 ; 0x3c -> ,
	00 00 00 00 00 00 1C 1C ; 0x3d -> .
	00 6E DD D8 CE C3 DB 8E ; 0x3e -> |S (used for vespers and compline)
	00 7C C6 46 1C 30 00 30 ; 0x3f -> ?
	0C 00 0C 38 62 63 3E 00 ; 0x40 -> �
	00 3C 66 C6 FE C6 E6 66 ; 0x41 -> A
	00 D8 EC CC FC C6 E6 DC ; 0x42 -> B
	00 38 6C C6 C0 C2 EE 7C ; 0x43 -> C
	00 DC E6 C6 C6 C6 CC F8 ; 0x44 -> D
	00 DC E6 60 7C 60 E6 DC ; 0x45 -> E
	00 EE 72 60 7C 60 E0 C0 ; 0x46 -> F
	00 3C 66 C0 CE C4 EC 78 ; 0x47 -> G
	00 CC C6 C6 FE C6 C6 66 ; 0x48 -> H
	00 7E 98 30 30 30 1A FC ; 0x49 -> I
	00 3E 0C 0C E6 66 C6 7C ; 0x4a -> J
	00 C0 66 6C 78 78 EC C6 ; 0x4b -> K
	00 C0 E0 60 60 60 FC C2 ; 0x4c -> L
	00 66 FE D6 D6 C6 E6 66 ; 0x4d -> M
	00 CC E6 E6 D6 CE CE 66 ; 0x4e -> N
	00 38 6C C6 C6 C6 EE 7C ; 0x4f -> O
	00 DC 66 66 6E 78 60 60 ; 0x50 -> P
	00 38 6C C6 D6 CC EC 76 ; 0x51 -> Q
	00 DC E6 C6 EC D8 CC C6 ; 0x52 -> R
	00 3C 66 62 3C 46 C6 7C ; 0x53 -> S
	00 FE BA 18 18 18 38 30 ; 0x54 -> T
	00 E6 66 C6 C6 C6 C6 7C ; 0x55 -> U
	00 CE CC C6 C6 C6 6C 38 ; 0x56 -> V
	8C 72 CC E6 F6 D6 CE 64 ; 0x57 -> �
	00 EE C6 6C 38 6C C6 EE ; 0x58 -> X
	00 CC C6 66 3C 18 30 60 ; 0x59 -> Y
	00 76 8C 18 30 60 C2 BC ; 0x5A -> Z
	00 32 F8 E6 00 00 32 F7 ; 0x5B -> [
	EA 00 00 32 F0 F9 00 00 ; 0x5C -> \

; word table
B580: 	0x00 -> 53 45 43 52 45 D4 -> SECRET
	0x01 -> 55 CD -> UM
	0x02 -> 46 49 4E 49 D3 -> FINIS
	0x03 -> 41 46 52 49 43 41 C5 -> AFRICAE
	0x04 -> 4D 41 4E 55 D3 -> MANUS
	0x05 -> 53 55 50 52 C1 -> SUPRA
	0x06 -> 41 41 C1 -> AAA (this is overwritten with the Roman numerals)
	0x07 -> 49 44 4F 4C 55 CD -> IDOLUM
	0x08 -> 41 47 C5 -> AGE
	0x09 -> 50 52 49 CD -> PRIM
	0x0a -> 45 D4 -> ET
	0x0b -> 53 45 50 54 49 CD -> SEPTIM
	0x0c -> 44 C5 -> DE
	0x0d -> 51 55 41 54 55 4F D2 -> QUATUOR
	0x0e -> 42 49 45 CE -> BIEN
	0x0f -> 56 45 4E 49 C4 -> VENID
	0x10 -> CF -> O
	0x11 -> C1 -> A
	0x12 -> 45 53 D4 -> EST
	0x13 -> 41 42 41 44 49 C1 -> ABADIA
	0x14 -> 48 45 52 4D 41 4E CF -> HERMANO
	0x15 -> 4F D3 -> OS
	0x16 -> 52 55 45 47 CF -> RUEGO
	0x17 -> 51 55 C5 -> QUE
	0x18 -> 4D C5 -> ME
	0x19 -> 53 49 C7 -> SIG
	0x1a -> 41 49 D3 -> AIS
	0x1b -> 48 C1 -> HA
	0x1c -> 53 55 43 45 C4 -> SUCED
	0x1d -> 49 44 CF -> IDO
	0x1e -> 41 4C 47 CF -> ALGO
	0x1f -> 54 45 52 52 49 42 4C C5 -> TERRIBLE
	0x20 -> 54 45 4D CF -> TEMO
	0x21 -> 55 CE -> UN
	0x22 -> 4C 4F D3 -> LOS
	0x23 -> 4D 4F 4E 4A C5 -> MONJE
	0x24 -> D3 -> S
	0x25 -> 43 4F CD -> COM
	0x26 -> 43 52 49 4D 45 CE -> CRIMEN
	0x27 -> 4C CF -> LO
	0x28 -> 45 4E 43 4F 4E 54 D2 -> ENCONTR
	0x29 -> 45 49 D3 ->EIS
	0x2a -> 41 4E 54 C5 -> ANTE
	0x2b -> 4C 4C 45 47 D5 -> LLEGU
	0x2c -> C5 -> E
	0x2d -> 42 45 52 4E 41 52 44 CF -> BERNARDO
	0x2e -> 47 55 C9 -> GUI
	0x2f -> 50 55 C5 -> PUE
	0x30 -> 4E CF -> NO
	0x31 -> 53 C5 -> SE
	0x32 -> 4D 41 4E 43 C8 -> MANCH
	0x33 -> 45 CC -> EL
	0x34 -> 4E 4F 4D 42 52 C5 -> NOMBRE
	0x35 -> 44 45 C2 -> DEB
	0x36 -> 52 45 53 50 45 D4 -> RESPET
	0x37 -> 41 D2 -> AR
	0x38 -> 4D C9 -> MI
	0x39 -> 4F 52 44 45 CE -> ORDEN
	0x3a -> 45 D3 -> ES
	0x3b -> D9 -> Y
	0x3c -> 4C 41 D3 -> LAS
	0x3d -> 4C C1 -> LA
	0x3e -> 41 53 49 53 54 49 D2 -> ASISTIR
	0x3f -> 4F 46 49 43 49 4F D3 -> OFICIOS
	0x40 -> 49 44 C1 -> IDA
	0x41 -> 4E 4F 43 48 C5 -> NOCHE
	0x42 -> 45 CE -> EN
	0x43 -> 56 55 45 53 54 D2 -> VUESTR
	0x44 -> 43 45 4C 44 C1 -> CELDA
	0x45 -> 44 45 4A 41 C4 -> DEJAD
	0x46 -> 4D 41 4E 55 53 43 52 49 54 CF -> MANUSCRITO
	0x47 -> 56 45 4E 41 4E 43 49 CF VENANCI0
	0x48 -> 41 44 56 45 52 54 49 D2 -> ADVERTIR
	0x49 -> 41 CC -> AL
	0x4a -> 41 42 41 C4 -> ABAD
	0x4b -> 44 41 C4 -> DAD
	0x4c -> 46 52 41 D9 -> FRAY
	0x4d -> 47 55 49 4C 4C 45 52 4D CF -> GUILLERMO
	0x4e -> 4C 4C 45 C7 -> LLEG
	0x4f -> 54 41 52 44 C5 -> TARDE
	0x50 -> 49 D2 -> IR
	0x51 -> 56 45 4E C7 -> VENG
	0x52 -> 41 42 41 4E 44 4F CE -> ABANDON
	0x53 -> 45 44 49 46 49 43 49 CF -> EDIFICIO
	0x54 -> 45 4D 4F D3 -> EMOS
	0x55 -> 49 47 4C 45 53 49 C1 -> IGLESIA
	0x56 -> 4D 41 45 53 54 52 CF -> MAESTRO
	0x57 -> 52 45 46 45 43 54 4F 52 49 CF -> REFECTORIO
	0x58 -> 50 4F C4 -> POR
	0x59 -> 41 D3 -> AS
	0x5a -> 48 41 42 45 49 D3 -> HABEIS
	0x5b -> 41 44 CF -> ADO
	0x5c -> 4F 52 44 45 4E 45 D3 -> ORDENES
	0x5d -> 41 C4 -> AR
	0x5e -> 50 41 52 C1 -> PARA
	0x5f -> 53 49 45 4D 50 52 C5 -> SIEMPRE
	0x60 -> 45 53 43 55 43 48 41 C4 -> ESCUCHAD
	0x61 -> 48 C5 -> HE
	0x62 -> 45 58 54 52 41 D7 -> EXTRA�
	0x63 -> 4C 49 42 52 CF -> LIBRO
	0x64 -> 45 4E 54 D2 -> ENTR
	0x65 -> 49 4E 56 45 53 54 49 47 41 43 49 4F CE -> INVESTIGACION
	0x66 -> 44 4F 52 4D 49 4D 4F D3 -> DORMIMOS
	0x67 -> 55 4E C1 -> UNA
	0x68 -> 4C 41 4D 50 41 52 C1 -> LAMPARA
	0x69 -> 41 51 55 C9 -> AQUI
	0x6a -> 53 49 44 CF -> SIDO
	0x6b -> 41 53 45 53 49 CE -> ASESIN
	0x6c -> 53 41 42 45 D2 -> SABER
	0x6d -> 42 49 42 4C 49 4F 54 45 43 C1 -> BIBLIOTECA
	0x6e -> 4C 55 47 41 D2 -> LUGAR
	0x6f -> 53 4F 4C CF -> SOLO
	0x70 -> 4D 41 4C 41 51 55 49 41 D3 -> MALAQUIAS
	0x71 -> 4F D2 -> OR
	0x72 -> 42 45 52 45 4E 47 41 52 49 CF -> BERENGARIO
	0x73 -> 44 45 53 41 50 41 52 45 43 49 44 CF -> DESAPARECIDO
	0x74 -> 48 41 4C 4C C1 -> HALLA
	0x75 -> 4F 54 52 CF -> OTRO
	0x76 -> 45 D2 -> ER
	0x77 -> 48 41 CE -> HAN
	0x78 -> 53 45 56 45 52 49 4E CF -> SEVERINO
	0x79 -> 44 49 4F D3 -> DIOS
	0x7a -> 53 41 4E 54 CF -> SANTO
	0x7b -> 4C C5 -> LE
	0x7c -> 43 45 52 D2 -> CERR
	0x7d -> 48 4F D9 -> HOY
	0x7e -> 4D 41 57 41 4E C1 -> MA�ANA
	0x7f -> 56 45 D2 -> VER
	0x80 -> 54 45 4E 49 C1 -> TENIA
	0x81 -> 4D 49 CC -> MIL
	0x82 -> 45 53 43 4F 52 50 49 4F 4E 45 D3 -> ESCORPIONES
	0x83 -> 4D 55 45 52 54 CF -> MUERTO
	0x84 -> 53 4F 49 D3 -> SOIS
	0x85 -> 56 4F D3 -> VOS
	0x86 -> 50 41 53 41 C4 -> PASAD
	0x87 -> 41 42 C1 -> ABA
	0x88 -> 45 53 50 45 D2 -> ESPER
	0x89 -> 41 4E 44 CF -> ANDO
	0x8a -> 54 4F 4D 41 C4 -> TOMAD
	0x8b -> 50 52 45 4D 49 CF -> PREMIO
	0x8c -> 43 41 49 44 CF -> CAIDO
	0x8d -> 54 52 41 4D 50 C1 -> TRAMPA
	0x8e -> 56 45 4E 45 52 41 42 4C C5 -> VENERABLE
	0x8f -> 4A 4F 52 47 C5 -> JORGE
	0x90 -> 50 45 52 CF -> PERO
	0x91 -> 4C 4C 45 56 C1 -> LLEVA
	0x92 -> 47 55 41 4E 54 45 D3 -> GUANTES
	0x93 -> 53 45 50 41 52 41 D2 -> SEPARAR
	0x94 -> 46 4F 4C 49 4F D3 -> FOLIOS
	0x95 -> 54 45 4E 44 52 49 C1 -> TENDRIA
	0x96 -> 48 55 4D 45 44 45 43 45 D2 -> HUMEDECER
	0x97 -> 44 45 44 4F D3 -> DEDOS
	0x98 -> 4C 45 4E 47 55 C1 -> LENGUA
	0x99 -> 48 41 53 54 C1 -> HASTA
	0x9a -> 48 55 42 49 45 52 C1 -> HUBIERA
	0x9b -> 52 45 43 49 42 49 44 CF -> RECIBIDO
	0x9c -> 46 49 43 49 45 4E 54 C5 -> SUFICIENTE
	0x9d -> 56 45 4E 45 4E CF -> VENENO
	0x9e -> 49 45 4E 44 CF -> IENDO
	0x9f -> 4D 55 D9 -> MUY
	0xa0 -> 4E 45 47 52 41 D3 -> NEGRAS
	0xa1 -> 50 52 4F 4E 54 CF -> PRONTO
	0xa2 -> 41 4D 41 4E 45 C3 -> AMANEC
	0xa3 -> 45 52 C1 -> ERA
	0xa4 -> 41 47 4F D4 -> AGOT
	0xa5 -> 4A 41 4D 41 D3 -> JAMAS
	0xa6 -> 43 4F 4E 53 45 47 55 49 D2 -> CONSEGUIR
	0xa7 -> 53 41 4C 49 D2 -> SALIR
	0xa8 -> 4F 43 55 50 41 C4 -> OCUPAD
	0xa9 -> 53 49 54 49 CF -> SITIO
	0xaa -> 43 4F 45 4E C1 -> COENA
	0xab -> 43 49 50 52 49 41 4E C9 -> CIPRIANI
	0xac -> 41 52 49 53 54 4F 54 45 4C 45 D3 -> ARISTOTELES
	0xad -> 41 48 4F 52 C1 -> AHORA
	0xae -> 43 4F 4D 50 52 45 4E 44 45 52 45 49 D3 -> COMPRENDEIS
	0xaf -> 50 4F D2 -> POR
	0xb0 -> 50 52 4F 54 45 47 45 52 4C CF -> PROTEGERLO
	0xb1 -> 43 41 44 C1 -> CADA
	0xb2 -> 50 41 4C 41 42 52 C1 -> PALABRA
	0xb3 -> 53 43 52 49 54 C1 -> ESCRITA
	0xb4 -> 46 49 4C 4F 53 4F 46 CF -> FILOSOFO
	0xb5 -> 44 45 53 54 52 55 49 44 CF -> DESTRUIDO
	0xb6 -> 50 41 52 54 C5 -> PARTE
	0xb7 -> 44 45 CC -> DEL
	0xb8 -> 43 52 49 53 54 49 41 4E 44 41 C4 -> CRISTIANDAD
	0xb9 -> 41 43 54 55 41 44 CF -> ACTUADO
	0xba -> 53 49 47 55 49 45 4E 44 CF -> SIGUIENDO
	0xbb -> 56 4F 4C 55 4E 54 41 C4 -> VOLUNTAD
	0xbc -> 53 45 57 4F D2 -> SE�OR
	0xbd -> 4C 45 45 44 4C CF -> LEEDLO
	0xbe -> 44 45 53 50 55 45 D3 -> DESPUES
	0xbf -> 54 C5 -> TE
	0xc0 -> 4D 4F 53 54 52 41 D2 -> MOSTRAR
	0xc1 -> 54 C9 -> TI
	0xc2 -> 4D 55 43 48 41 43 48 CF -> MUCHACHO
	0xc3 -> 46 55 C5 -> FUE
	0xc4 -> 42 55 45 4E C1 -> BUENA
	0xc5 -> 49 44 45 C1 -> IDEA
	0xc6 -> 51 55 49 45 52 CF -> QUIERO
	0xc7 -> 43 4F 4E 4F 5A C3 -> CONOZC
	0xc8 -> 48 4F 4D 42 52 C5 -> HOMBRE
	0xc9 -> 4D 41 D3 -> MAS
	0xca -> 56 49 45 4A CF -> VIEJO
	0xcb -> 53 41 42 49 CF -> SABIO
	0xcc -> 4E 55 45 53 54 52 CF -> NUESTRO
	0xcd -> 48 55 45 53 50 45 C4 -> HUESPED
	0xce -> 53 45 C4 -> SED
	0xcf -> 56 45 4E 49 44 CF -> VENIDO
	0xd0 -> 44 49 47 CF -> DIGO
	0xd1 -> 56 49 41 D3 -> VIAS
	0xd2 -> 41 4E 54 49 43 52 49 53 54 CF -> ANTICRISTO
	0xd3 -> 53 4F CE -> SON
	0xd4 -> 4C 45 4E 54 41 D3 -> LENTAS
	0xd5 -> 54 4F 52 54 55 4F 53 41 D3 -> TORTUOSAS
	0xd6 -> 4C 4C 45 47 C1 -> LLEGAN
	0xd7 -> 43 55 41 4E 44 CF -> CUANDO
	0xd8 -> 4D 45 4E 4F D3 -> MENOS
	0xd9 -> 44 45 53 50 45 52 44 49 43 49 45 49 D3 -> DESPERDICIESIS
	0xda -> 55 4C 54 49 4D 4F D3 -> ULTIMOS
	0xdb -> 44 49 41 D3 -> DIAS
	0xdc -> 53 49 45 4E 54 CF -> SIENTO
	0xdd -> 53 55 42 49 D2 -> SUBIR
	0xde -> 53 C9 -> SI
	0xdf -> 44 45 53 C5 -> DESE
	0xe0 -> 53 43 52 49 50 54 4F 52 49 55 CD -> SCRIPTORIUM
	0xe1 -> 54 52 41 42 41 CA -> TRABAJ
	0xe2 -> 41 CE -> AN
	0xe3 -> 4D 45 4A 4F 52 45 D3 -> MEJORES
	0xe4 -> 43 4F 50 49 53 54 41 D3 -> COPISTAS
	0xe5 -> 4F 43 43 49 44 45 4E 54 C5 -> OCCIDENTE
	0xe6 -> 53 4F D9 -> SOY
	0xe7 -> 45 4E 43 41 52 47 41 44 CF -> ENCARGADO
	0xe8 -> 48 4F 53 50 49 54 41 CC -> HOSPITAL
	0xe9 -> 45 53 54 C1 -> ESTA
	0xea -> 53 55 43 45 44 45 CE -> SUCEDEN
	0xeb -> 43 4F 53 41 D3 -> COSAS
	0xec -> 41 4C 47 55 49 45 CE -> ALGUIEN
	0xed -> 0xe0 -> 51 55 49 45 52 C5 -> QUIERE
	0xee -> 44 45 43 49 44 41 CE -> DECIDAN

; phrase table
BB00: 	0x00 -> 00 F9 01 02 03 FE 04 05 06 07 08 09 F9 01 0A 0B	F9 01 0C 0D FF
			SECRETUM FINISH AFRICAE, MANUS SUPRA XXX AGE PRIMUM ET SEPTIMUM DE QUATOR
	0x01 -> 0E F9 0F F9 10 11 12 F9 11 13 FE 14 FD 15 16 17 18 19 F9 1A FD 1B 1C F9 1D 1E 1F FF
			BIENVENIDO A ESTA ABADIA, HERMANO. OS RUEGO QUE ME SIGAIS. HA SUCEDIDO ALGO TERRIBLE
	0x02 -> 20 17 21 F9 10 0C 22 23 F9 24 1B 25 F9 0A F9 1D 21 26 FD 15 16 17 27 28 F9 29 2A F9 24 0C 17 2B F9 2C 2D 2E FE 2F F9 24 30 0C F9 31 F9 10 17 31 32 F9 2C 33 34 0C 12 F9 11 13 FF
			TEMO QUE UNO DE LOS MONJES HA COMETIDO UN CRIMEN. OS RUEGO QUE LO ENCONTREIS ANTES DE QUE LLEGUE BERNARDO GUI, PUES	NO DESEO QUE SE MANCHE EL NOMBRE DE ESTA ABADIA
	0x03 -> 35 F9 29 36 F9 37 38 F9 24 39 F9 3A 3B 3C 0C 3D 13 FD 3E 11 22 3F 3B 11 3D 25 F9 40 FD 0C 41 35 F9 29 12 F9 37 42 43 F9 11 44 FF
			DEBEIS RESPETAR MIS ORDENES Y LAS DE LA ABADIA. ASISTIR A LOS OFICIOS Y A LA COMIDA. DE NOCHE DEBEIS ESTAR EN VUESTRA CELDA
	0x04 -> 45 33 46 0C 47 10 48 F9 2C 49 4A FF
			DEJAD EL MANUSCRITO DE VENACIO O ADVERTIRE AL ABAD
	0x05 -> 4B F9 18 33 46 FE 4C 4D FF
			DADME EL MANUSCRITO, FRAY GUILLERMO
	0x06 -> 4E F9 1A 4F	FE 4C 4D FF
			LLEGAIS TARDE, FRAY GUILLERMO
	0x07 -> 12 F9 11 3A 43 F9 11 44 FD 35 F9 10	50 F9 18 FF
			ESTA ES VUESTRA CELDA, DEBO IRME
	0x08 ->	15 39 F9 10 17 51 F9 1A FF
			OS ORDENO QUE VENGAIS
	0x09 -> 35 F9 29 52 F9 37 53 FE 14 FF
			DEBEIS ABANDONAR EDIFICIO, HERMANO
	0x0a -> 48 F9 2C 49 4A FF
			ADVERTIRE AL ABAD
	0x0b -> 35 F9 54 50 11 3D 55 FE 56 FF
			DEBEMOS IR A LA IGLESIA, MAESTRO
	0x0c -> 35 F9 54 50 49 57 FE 56 FF
			DEBEMOS IR AL REFECTORIO, MAESTRO
	0x0d -> 58 F9 29 50 11 43 F9 59 44 F9 24 FF
			PODEIS IR A VUESTRAS CELDAS
	0x0e -> 30 5A 36 F9	5B 38 F9 24 5C FD 52 F9 5D 5E 5F 12 F9 11 13 FF
			NO HABEIS RESPETADO MIS ORDENES. ABANDONAD PARA SIEMPRE ESTA ABADIA
	0x0f -> 60 14 FE 61 28 F9 5B 21 62 F9 10 63 42 38 44 FF
			ESCUCHAD HERMANO, HE ENCONTRADO UN EXTRA�O LIBRO EN MI CELDA
	0x10 -> 64 F9 5D 42 43 F9 11 44 FE 4C 4D FF
			ENTRAD EN VUESTRA CELDA, FRAY GUILLERMO
	0x11 -> 1B 4E F9 5B 2D FE 35 F9 29 52 F9 37 3D 65 FF
			HA LLEGADO BERNARDO, DEBEIS ABANDONAR LA INVESTIGACION
	0x12 -> FA 66 FB FE 56 FF
			�DORMIMOS?, MAESTRO
	0x13 -> 35 F9 54 28 F9 37 67 68 FE 56 FF
			DEBEMOS ENCONTRAR UNA LAMPARA, MAESTRO
	0x14 -> 0F 69 FE 4C 4D FF
			VENID AQUI, FRAY GUILLERMO
	0x15 -> 14 F9 24 FE 47 1B 6A 6B F9 5B FF
			HERMANOS, VENACIO HA SIDO ASESINADO
	0x16 -> 35 F9 29 6C 17 3D 6D 3A 21 6E 00 F9 10 FD 6F 70 2F F9 0C 64 F9 37 FD 58 F9 29 50 F9 15 FF
			DEBEIS SABER QUE LA BIBLIOTECA ES UN LUGAR SECRETO. SOLO MALAQUIAS PUEDE ENTRAR. PODEIS IROS
	0x17 -> 71 F9 54 FF
			OREMOS
	0x18 -> 14 F9 24 FE 72 1B 73 FD 20 17 31 74 25 F9 0A F9 1D 75 26 FF
			HERMANOS, BERENGARIO HA DESAPARECIDO. TEMO QUE SE HAYA COMETIDO OTRO CRIMEN
	0x19 -> 58 F9 29 25 F9 76 FE 14 F9 24 FF
			PODEIS COMER, HERMANOS
	0x1a -> 14 F9 24 FE 77 28 F9 5B 11 72 6B F9 5B FF
			HERMANOS, HAN ENCONTRADO A BERENGARIO ASESINADO
	0x1b -> 0F FE 4C 4D	FE 35 F9 54 28 F9 37 11 78 FF
			VENID, FRAY GUILLERMO, DEBEMOS ENCONTRAR A SEVERINO
	0x1c -> 79 7A FD FD FD 77 6B F9 5B 11 78 3B 7B 77 42 F9 7C F9 5B FF
			DIOS SANTO... HAN ASESINADO A SEVERINO Y LE HAN ENCERRADO
	0x1d -> 2D 52 F9 37 F9 11 7D 3D 13 FF
			BERNARDO ABANDONARA HOY LA ABADIA
	0x1e -> 7E FE 52 F9 37 F9 29 3D	13 FF
			MA�ANA ABANDONAREIS LA ABADIA
	0x1f -> 76 F9 11 7F F9 4B FE 80 33 58 F9 76 0C 81 82 FF
			ERA VERDAD, TENIA EL PODER DE MIL ESCORPIONES
	0x20 -> 70 1B 83 FF
			MALAQUIAS HA MUERTO
	0x21 -> 84 85 FE 4D FD FD FD 86 FE 15 12 F9 87 88 F9 89 FD 8A FE 69 12 F9 11 43 F9 10 8B FF
			SOIS VOS, GUILERMO... PASAD, OS ESTABA ESPERANDO. TOMAD, AQUI ESTA VUESTRO PREMIO
	0x22 -> 12 F9 1A 83 FE 4C 4D FE 5A 8C 42 3D 8D FF
			ESTAIS MUERTO, FRAY GUILLERMO, HABEIS CAIDO EN LA TRAMPA
	0x23 -> 8E 8F FE 85 30 58 F9 29 7F F9 27 FE 90 38 56 91	92 FD 5E 93 22 94 95 17 96 22 97 42 3D 98 FE 99	17 9A 9B 9C 9D FF
			VENERABLE JORGE, VOIS NO PODEIS VERLO, PERO MI MAESTRO LLEVA GUANTES.  PARA SEPARAR LOS FOLIOS TENDRIA QUE HUMEDECER LOS DEDOS EN LA LENGUA, HASTA QUE HUBIERA RECIBIDO SUFICIENTE VENENO
	0x24 -> 31 12 F9 11 25 F9 9E 33 63 FE 56 FF
			SE ESTA COMIENDO EL LIBRO, MAESTRO
	0x25 -> 35 F9 29 52 F9 37 3B F9 11 3D 13 FF
			DEBEIS ABANDONAR YA LA ABADIA
	0x26 -> 3A 9F 62 F9 10 FE 14 4D FD 72 80 32 F9 59 A0 42 3D 98 3B 42 22 97 FF
			ES MUY EXTRA�O, HERMANO GUILLERMO. BERENGARIO TENIA MANCHAS NEGRAS EN LA LENGUA Y EN LOS DEDOS
	0x27 -> A1 A2 F9 A3 FE 56 FF
			PRONTO AMANECERA, MAESTRO
	0x28 -> 3D 68 31 A4 F9 11 FF
			LA LAMPARA SE AGOTA
	0x29 -> 5A 64 F9 5B 42 38 44 FF
			HABEIS ENTRADO EN MI CELDA
	0x2a -> 31 1B A4 F9 5B 3D 68 FF
			SE HA AGOTADO LA LAMPARA
	0x2b -> A5 A6 F9 54 A7 0C 69 FF
			JAMAS CONSEGUIREMOS SALIR DE AQUI
	0x2c -> 88 F9 5D FE 14 FF
			ESPERAD, HERMANO
	0x2d -> A8 43 F9 10 A9 FE 4C 4D FF
			OCUPAD VUESTRO SITIO, FRAY GUILLERMO
	0x2e -> 3A 33 AA AB 0C AC FD AD AE AF F9 17 80 17 B0 FD B1 B2 B3 AF 33 B4 1B B5 67 B6 B7 6C 0C 3D B8 FD 31 17 61 B9 BA 3D BB B7 BC FD FD FD BD FE 2F F9 24 FE 4C 4D FD BE BF 27 C0 F9 2C 11 C1 C2 FF
			ES EL COENA CIPRIANI DE ARISTOTELES. AHORA COMPRENDEREIS POR QUE TENIA QUE PROTEGERLO. CADA PALABRA ESCRITA POR EL FILOSOFO HA DESTRUIDO UNA PARTE DEL SABER DE LA CRISTIANDAD. SE QUE HE ACTUADO SIGUIENDO LA VOLUNTAD DEL SE�OR... LEEDLO, PUES, FRAY GUILLERMO. DESPUES TE LO MOSTRATE A TI MUCHACHO
	0x2f -> C3 67 C4 C5 FA 7F F9 4B FB FC 90 3B F9 11 3A 4F FF
			FUE UNA BUENA IDEA �VERDAD?; PERO YA ES TARDE
	0x30 -> C6 17 C7 F9 1A 49 C8 C9 CA 3B CB 0C 3D 13 FF
			QUIERO QUE CONOZCAIS AL HOMBRE MAS VIEJO Y SABIO DE LA ABADIA
	0x31 -> 8E 8F FE 33 17 12 F9 11 2A 85 3A 4C 4D FE CC CD FF
			VENERABLE JORGE, EL QUE ESTA ANTE VOS ES FRAY GUILLERMO, NUESTRO HUESPED
	0x32 -> CE 0E F9 CF FE 8E 14 FC 3B 60 27 17 15 D0 FD 3C D1 B7 D2 D3 D4 3B D5 FD D6 D7 D8 27 88 F9 59 FD 30 D9 22 DA DB FF
			SED BIENVENIDO, VENERABLE HERMANO; Y ESCUCHAD LO QUE OS DIGO. LAS VIAS DEL ANTICRISTO SON LENTAS Y TORTUOSAS. LLEGA CUANDO MENOS LO ESPERAS. NO DESPERDICIEIS LOS ULTIMOS DIAS
	0x33 -> 27 DC FE 8E 14 FE 30 58 F9 29 DD 11 3D 6D FF
			LO SIENTO, VENERABLE HERMANO, NO PODEIS SUBIR A LA BIBLIOTECA
	0x34 -> DE 27 DF F9 1A FE 72 15 C0 F9 11 33 E0 FF
			SI LO DESEAIS, BERENGARIO OS MOSTRARA EL SCRIPTORIUM
	0x35 -> 69 E1 F9 E2 22 E3 E4 0C E5 FF
			AQUI TRABAJAN LOS MEJORES COPISTAS DE OCCIDENTE
	0x36 -> 69 E1 F9 87 47 FF
			AQUI TRABAJABA VENACIO
	0x37 -> 8E 14 FE E6 78 FE 33 E7 B7 E8 FD C6 48 F9 15 17 42 E9 13 EA EB 9F 62 F9 59 FD EC 30 ED 17 22 23 F9 24 EE AF DE 6F F9 24 27 17 35 F9 42 6C FF
			VENERABLE HERMANO, SOY SEVERINO, EL ENCARGADO DEL HOSPITAL. QUIERO ADVERTIROS QUE EN ESTA ABADIA SUCEDEN COSAS MUY EXTRA�AS. ALGUIEN NO QUIERE QUE LOS MONJES DECIDAN POR SI SOLOS LO QUE DEBEN SABER

	00 00 00 00
	00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00

BF00:	7E 3C 7E 3C 7E 3C 7E 3C 7E 3C 7E 3C 7E 3C 7E 3C
	7E 3C 7E 3C 7E 3C 7E 3C 7E 3C 7E 3C 7E 3C 7E 3C
	7E 3C 7E 3C 7E 3C 7E 3C 7E 3C 7E 3C 7E 3C 7E 3C
	7E 3C 7E 3C 7E 3C 7E 3C 7E 3C 7E 3C 7E 3C 7E 3C
	7E 3C 7E 3C 7E 3C 7E 3C 7E 24 7E 3C 7E 3C 04 01
	88 A8 00 3C 7E 3C 7E 3C 7E 3C 7E 3C 7E 3C 7E 3C
	50 10 7E 3C 7E 3C 7E 3C 7E 3C 6E 2C 7E 3C 7E 3C
	7E 3C 7E 3C 7E 3C 7E 3C 7E 3C 7E 3C 7E 3C 7E 3C
	FE BD FE BD FE BD FE BD FE BD FE BD FE BD FF BD
	FE BD FF BD FF BD 00 F7 49 1D D2 00 00 F7 00 F7
	49 1D DC 00 53 B9 00 F7 00 F7 00 F7 00 F7 00 F7
	49 1D DC 00 D2 00 53 B9 00 F7 4C BE 00 23 B0 AB
	FC C8 0A C9 00 00 D2 00 53 B9 4C 00 CF C8 45 00
	55 BE 00 00 58 BE 56 C5 F1 D9 F4 62 2D 65 F4 F4
	62 F4 62 F4 62 F4 62 F4 62 1C 17 4C 02 F4 62 AC
	FF 03 FF 03 FF C7 01 03 01 CB 02 83 05 8A 02 DE
