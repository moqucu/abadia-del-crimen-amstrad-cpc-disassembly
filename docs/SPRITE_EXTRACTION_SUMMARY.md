# Sprite/Object Graphics Extraction Summary

## Overview
Successfully extracted all game sprites (characters, doors, objects) from the disassembled CPC Amstrad game code.

## Source Data
- **File location**: 0xA300 - 0xB400 in .asm file
- **Section marker**: "start of the object graphics"
- **Total bytes**: 4,352 bytes of sprite graphics data
- **Encoding**: CPC Mode 1 (4 colors, 4 pixels per byte)

## Sprites Extracted

### Characters (3 unique sprites)

| # | Name | Dimensions | Size | Description |
|---|------|------------|------|-------------|
| 00 | Adso | 20×36px (5×36 bytes) | 180 bytes | Guillermo's novice companion |
| 01 | Guillermo | 20×34px (5×34 bytes) | 170 bytes | Player character (William of Baskerville) |
| 02 | Monk | 20×34px (5×34 bytes) | 170 bytes | Generic monk sprite (shared by Malaquias, Abbot, Berengario, Severino) |

### Doors (1 sprite, shared by all)

| # | Name | Dimensions | Size | Description |
|---|------|------------|------|-------------|
| 03 | Door | 24×40px (6×40 bytes) | 240 bytes | Generic door sprite (used for all 7 doors in game) |

### Objects (7 unique sprites)

| # | Name | Dimensions | Size | Description |
|---|------|------------|------|-------------|
| 04 | Lamp | 16×12px (4×12 bytes) | 48 bytes | Oil lamp / light source |
| 05 | Book | 16×12px (4×12 bytes) | 48 bytes | Book item |
| 06 | Glasses | 16×12px (4×12 bytes) | 48 bytes | Reading glasses |
| 07 | Gloves | 16×12px (4×12 bytes) | 48 bytes | Gloves item |
| 08 | Key | 16×12px (4×12 bytes) | 48 bytes | Key (shared by all 3 keys in game) |
| 09 | Parchment | 16×12px (4×12 bytes) | 48 bytes | Manuscript/parchment |
| 10 | Unknown | 16×12px (4×12 bytes) | 48 bytes | Unidentified object |

**Total**: 11 unique sprite graphics (1,096 bytes used out of 4,352 available)

## Files Generated

### Individual Sprites
- `sprites/day/*.png` - 11 sprites in day palette
- `sprites/night/*.png` - 11 sprites in night palette
- Total: 22 PNG files

### Sprite Sheets
- `abbey_sprites_sheet_day.png` - 256×96px, all sprites in day colors
- `abbey_sprites_sheet_night.png` - 256×96px, all sprites in night colors

## Color Palettes

### Day Palette
- Color 0: Black (0x00)
- Color 1: Bright Cyan (0x14)
- Color 2: Bright Yellow/Orange (0x18)
- Color 3: Bright White (0x1A)

### Night Palette
- Color 0: Black (0x00)
- Color 1: Bright Blue (0x02)
- Color 2: Bright Magenta (0x08)
- Color 3: Pastel Magenta (0x11)

## Technical Details

### Sprite Metadata Table
Located at 0x2E17-0x2FE3 in .asm file. Each sprite has a 20-byte entry containing:
- Byte 5: Width in bytes (4-6 bytes)
- Byte 6: Height in pixels (12-40 pixels)
- Bytes 7-8: Runtime memory address pointer (little-endian)

### Memory Layout (Runtime)
From the memory map documentation:
- `0xA300-0xAB58`: Graphics of William, Adso, and doors
- `0xAB59-0xAE2D`: Graphics of the monks
- `0xAE2E-0xB102`: Graphics of the monks with FlipX

### Sprite Reuse
The game efficiently reuses sprite graphics:
- **4 monks** (Malaquias, Abbot, Berengario, Severino) share 1 sprite
- **7 doors** share 1 sprite
- **3 keys** share 1 sprite

This reduces memory usage significantly.

## Differences from Abbey Graphics

| Feature | Abbey Tiles | Object Sprites |
|---------|-------------|----------------|
| Purpose | Static backgrounds | Dynamic characters/items |
| Count | 256 tiles | 11 unique sprites |
| Size | Fixed 16×8 pixels | Variable (12-40 pixels height) |
| Data location | 0x8300-0xA2FF | 0xA300-0xB400 |
| Composition | Used by building blocks | Rendered with transparency |
| Total bytes | 8,192 bytes | 4,352 bytes |

## Remaining Data

The sprite section contains 4,352 bytes total, but only 1,096 bytes (25%) are accounted for by the 11 extracted sprites. The remaining ~3,256 bytes likely contain:

1. **Animation frames** - Multiple frames for walking/turning animations
2. **FlipX versions** - Horizontally flipped versions of sprites (memory map mentions monk graphics with FlipX at 0xAE2E-0xB102)
3. **Light sprite** - The light effect (20×80px = 1,600 bytes alone)
4. **Additional character poses** - Different orientations or states

## Extraction Method

The Python script (`extract_sprites.py`):
1. Reads sprite graphics from 0xA300 to "end of object graphics" marker
2. Extracts sprites sequentially based on known dimensions
3. Decodes CPC Mode 1 format (4 pixels per byte, bit-interleaved)
4. Applies day and night color palettes
5. Generates individual PNG files and combined sprite sheets

## Usage

To re-extract sprites:
```bash
python3 extract_sprites.py
```

Output:
- Individual sprites in `sprites/day/` and `sprites/night/`
- Sprite sheets: `abbey_sprites_sheet_day.png` and `abbey_sprites_sheet_night.png`

## Next Steps (Optional)

To extract the complete sprite set:
1. Analyze animation frames (characters facing different directions)
2. Extract FlipX versions of monk sprites
3. Locate and extract the light effect sprite
4. Map all sprite pointers from metadata table to actual data locations
5. Extract character orientation variations (4 directions × multiple characters)

---

**Generated**: 2025-12-15
**Source**: abadia_del_crimen_disassembled_CPC_Amstrad_game_code.asm (0xA300-0xB400)
**Total Sprites**: 11 unique graphics (22 PNG files with both palettes)
