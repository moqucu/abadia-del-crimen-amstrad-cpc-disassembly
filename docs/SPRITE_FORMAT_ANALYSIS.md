# Sprite Format Analysis - La Abadía del Crimen (CPC Amstrad)

## Part 1: Understanding the Sprite Drawing Routine

### Sprite Metadata Structure (20 bytes per sprite at 0x2E17)

From analyzing the sprite table at **0x2E17**:

| Offset | Size | Name | Description |
|--------|------|------|-------------|
| 0x00 | 1 byte | Status | Bit 7 = sprite needs redraw, bits 0-1 = animation counter |
| 0x01 | 1 byte | X position | Current X position (bytes) |
| 0x02 | 1 byte | Y position | Current Y position (pixels) |
| 0x03 | 1 byte | Old X | Previous X position for erasing |
| 0x04 | 1 byte | Old Y | Previous Y position for erasing |
| 0x05 | 1 byte | Width | Width in bytes (bit 7 = disappearing flag) |
| 0x06 | 1 byte | Height | Height in pixels |
| **0x07-0x08** | 2 bytes | **Graphics pointer** | **Little-endian pointer to sprite graphics data** |
| 0x09 | 1 byte | Old Width | Width for erasing old sprite |
| 0x0A | 1 byte | Old Height | Height for erasing old sprite |
| 0x0B | 1 byte | Animation | Animation state (bit 7 = not a monk) |
| 0x0C-0x13 | 8 bytes | Misc | Various runtime data |

### Sprite Graphics Format

From analyzing the drawing routine at **0x4914** (line 10330):

**Key code sections:**
- **0x4ADE-0x4AE1** (lines 10573-10575): Load graphics pointer
  ```
  4ADE: FD 6E 07    ld   l,(iy+$07)	; Load low byte of graphics pointer
  4AE1: FD 66 08    ld   h,(iy+$08)    ; Load high byte of graphics pointer
  ```

- **0x4B14-0x4B2C** (lines 10606-10628): Main drawing loop
  ```
  4B14: 7E          ld   a,(hl)        ; Read graphics byte
  4B15: A7          and  a             ; Test if zero
  4B16: 28 12       jr   z,$4B2A       ; If 0, skip (transparent)
  ...
  4B2C: 10 E6       djnz $4B14         ; Repeat for width
  ```

**Format discovered:**
1. **Linear byte array**: Width × Height bytes total
2. **Scanline format**: Rows of `width` bytes each
3. **Encoding**: CPC Mode 1 (4 pixels per byte, 2 bits each)
4. **Transparency**: Color 0 is transparent (tested at 0x4B15-0x4B16)
5. **AND/OR masking**: Non-zero pixels use AND/OR to preserve background

### Special Handling

**Monk Sprites** (from 0x4B36-0x4B52):
- Characters with bit 7 of byte 0x0B cleared are monks
- Monks have TWO parts:
  - **Head**: First 10 scanlines
  - **Robe**: Remaining scanlines (fetched from separate table at 0x48C8)
- After 10 lines, graphics pointer switches to robe graphics based on animation state

**Light Sprite**:
- Has graphics pointer = 0x0000 (special case at 0x4B05-0x4B07)
- Uses fill pattern table at 0x48E8 instead of sprite data

## Part 2: Sprite Metadata Table Entries

### Character Sprites

| Name | Metadata Addr | Width | Height | Graphics Ptr | Notes |
|------|---------------|-------|--------|--------------|-------|
| **Guillermo** | 0x2E17 | 5 bytes | 0x22 (34px) | **0x38B4** | Player character |
| **Adso** | 0x2E2B | 5 bytes | 0x24 (36px) | **0x38AA** | Companion |
| **Malaquias** | 0x2E3F | 5 bytes | 0x22 (34px) | **0x3A2A** | NPC monk (shared) |
| **Abbot** | 0x2E53 | 5 bytes | 0x22 (34px) | **0x3A2A** | NPC monk (shared) |
| **Berengario** | 0x2E67 | 5 bytes | 0x22 (34px) | **0x3A2A** | NPC monk (shared) |
| **Severino** | 0x2E7B | 5 bytes | 0x22 (34px) | **0x3A2A** | NPC monk (shared) |

Total character graphics:
- Guillermo: 5 × 34 = 170 bytes
- Adso: 5 × 36 = 180 bytes
- Monk (shared): 5 × 34 = 170 bytes

### Door Sprites

| Name | Metadata Addr | Width | Height | Graphics Ptr | Notes |
|------|---------------|-------|--------|--------------|-------|
| **All 7 doors** | 0x2E8F-0x2F07 | 6 bytes | 0x28 (40px) | **0x3A98** | Single shared graphic |

Total door graphics:
- Door: 6 × 40 = 240 bytes

### Object Sprites

| Name | Metadata Addr | Width | Height | Graphics Ptr | Notes |
|------|---------------|-------|--------|--------------|-------|
| **Book** | 0x2F1B | 4 bytes | 0x0C (12px) | **0x72F0** | Item |
| **Gloves** | 0x2F2F | 4 bytes | 0x0C (12px) | **0x89B0** | Item |
| **Glasses** | 0x2F43 | 4 bytes | 0x0C (12px) | **0x8980** | Item |
| **Parchment** | 0x2F57 | 4 bytes | 0x0C (12px) | **0x8A10** | Item |
| **Key 1** | 0x2F6B | 4 bytes | 0x0C (12px) | **0x89E0** | Item (shared) |
| **Key 2** | 0x2F7F | 4 bytes | 0x0C (12px) | **0x89E0** | Item (shared) |
| **Key 3** | 0x2F93 | 4 bytes | 0x0C (12px) | **0x89E0** | Item (shared) |
| **Unknown** | 0x2FA7 | 4 bytes | 0x0C (12px) | **0xA006** | Item |
| **Lamp** | 0x2FBB | 4 bytes | 0x0C (12px) | **0x72C0** | Item |

Total object graphics (unique):
- Each object: 4 × 12 = 48 bytes
- 7 unique objects × 48 = 336 bytes

### Special Sprites

| Name | Metadata Addr | Width | Height | Graphics Ptr | Notes |
|------|---------------|-------|--------|--------------|-------|
| **Light** | 0x2FCF | 0x14 (20 bytes) | 0x50 (80px) | **0x0000** | Special: uses pattern table |

## Part 3: Memory Layout and File Mapping

### Runtime Memory Banks (CPC 6128)

The CPC 6128 uses bank switching:
- **0x0000-0x3FFF**: Bank 0/1 (abadia1.bin)
- **0x4000-0x7FFF**: Bank 1/4/5/6/7 (switchable)
- **0x8000-0xBFFF**: Bank 3 (abadia3.bin)
- **0xC000-0xFFFF**: Bank 0 (abadia0.bin)

### Graphics Pointers Analysis

**Characters (0x3800-0x3AFF range):**
- 0x38AA, 0x38B4, 0x3A2A, 0x3A98
- These are in Bank 1 range (0x0000-0x3FFF)
- **Problem**: These are RUNTIME addresses after copying/reorganization

**Objects (0x7000-0xA000 range):**
- 0x72C0, 0x72F0 (lamp, book) - Bank 1 range
- 0x8980, 0x89B0, 0x89E0, 0x8A10 (glasses, gloves, keys, parchment) - Bank 3 range
- 0xA006 (unknown) - Bank 3 range

### Key Discovery: Graphics Reorganization

From initialization code at **0x24F2** (line 5093):
```
24F2: 21 00 83    ld   hl,$8300      ; Source: abadia3.bin graphics
24F5: 11 00 6D    ld   de,$6D00      ; Destination: RAM
24F8: 01 00 20    ld   bc,$2000      ; 8192 bytes
24FB: ED B0       ldir               ; Copy 0x8300-0xA2FF → 0x6D00-0x8CFF
```

From **0x2561** (line 5161):
```
2561: 21 59 AB    ld   hl,$AB59      ; Source: monk graphics
2564: 11 2E AE    ld   de,$AE2E      ; Destination
2568: 01 D5 02    ld   bc,$02D5      ; 725 bytes
256B: ED B0       ldir               ; Copy 0xAB59-0xAE2D → 0xAE2E-0xB102
256E: 01 05 91    ld   bc,$9105      ; 5 bytes wide, 145 blocks
2571: CD 52 35    call $3552         ; Create FlipX version
```

**Critical Insight**: The graphics pointers in the sprite table point to RAM addresses AFTER multiple copy and reorganization operations. We cannot directly map them to file offsets.

## Part 4: Finding Sprites in the File

### Strategy

Since graphics pointers are runtime RAM addresses, we need to:
1. Identify source file locations BEFORE copying
2. Understand the reorganization process
3. Extract from source locations

### File Section Analysis

**"Object Graphics" section** (0xA300-0xB400, line 16886):
- Comment says "start of the object graphics"
- Contains 4,352 bytes (0xA300 to 0xB400)
- This likely contains CHARACTER sprites (not small objects)

**Monk Graphics** (file 0xAB59):
- Explicitly referenced in code
- 725 bytes (0x02D5)
- Gets copied to 0xAE2E at runtime

**Small Objects** (file 0x8980-0x8A10):
- Glasses at 0x8980 (found at line 16476)
- Gloves at 0x89B0 (found at line 16479)
- Key at 0x89E0 (found at line 16482)
- Parchment at 0x8A10 (found at line 16485)
- These addresses ARE in the file (Bank 3 section)
- Book and Lamp at 0x72F0, 0x72C0 NOT found in file searches

### Next Steps

To correctly extract sprites:
1. **Small objects at 0x8980-0xA010**: Extract directly from file
2. **Character sprites at 0xA300+**: Analyze "object graphics" section structure
3. **Book/Lamp at 0x72xx**: Search for these in different file section
4. **Determine actual sprite count**: May have animation frames

---

**Status**: Format fully understood from code analysis. File mapping in progress.
**Next**: Locate all sprite graphics in file and create corrected extraction script.
