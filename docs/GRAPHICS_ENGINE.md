# Isometric 3D Graphics Engine Analysis

The visual core of "La Abadía del Crimen" is a sophisticated **2D tile-based isometric engine**. Despite its 3D appearance, the world is constructed from pre-drawn 2D bitmap assets and a powerful interpreter that composes them.

## 1. Architectural Overview

The engine does not use vector graphics or real-time polygons. Instead, it relies on a hierarchical construction system:

*   **Tiles (Bitmaps):** The smallest visual unit.
*   **Blocks (Scripts):** Programs that assemble tiles into structures (walls, arches).
*   **Rooms (Data):** Lists of blocks placed at specific coordinates.
*   **Sprites:** Dynamic elements like characters and objects.

## 2. Background Graphics

### 2.1. Tiles
There are exactly **256 base tiles** (numbered `0x00` to `0xFF`).
*   **Size:** 16×8 pixels.
*   **Storage:** `abadia3.bin` (mapped to `0x6D00-0x8CFF`).
*   **Format:** Amstrad CPC Mode 1 (4 colors, 2 bits per pixel).

#### Tile Color Palette (Day Mode)
*   **Pen 0:** Bright Cyan `(0, 255, 255)` - floor/background
*   **Pen 1:** Bright Yellow `(255, 255, 0)` - highlights
*   **Pen 2:** Orange `(255, 128, 0)` - bricks/walls
*   **Pen 3:** Black `(0, 0, 0)` - outlines

#### Selective Color Mapping by Tile Index
The game uses **three different rendering paths** based on tile index, identified in assembly at address `0x4E49`. This logic is mirrored in `extract_tiles.py` to correctly reconstruct the assets.

```assembly
4E59: cp   $0B        ; compare tile with 0x0B (11)
4E5E: jr   c,$4E92    ; if tile < 11, jump to simple LDI path
...
4E65: bit  7,(ix+$02) ; check bit 7 of tile number
4E6A: ld   h,$9D      ; tiles 11-127: use tables at 0x9D00/0x9E00
4E6C: jr   z,$4E70
4E6E: ld   h,$9F      ; tiles 128-255: use tables at 0x9F00/0xA000
```

**1. Tier 1: Base Tiles (0-10 / 0x00-0x0A)**
*   **Assembly:** Direct copy (`LDI`), no masking.
*   **Logic:** Fully opaque tiles used for floors.
*   **Colors:** Standard palette (Opaque Cyan background).

**2. Tier 2: Masked Tiles (11-127 / 0x0B-0x7F)**
*   **Assembly:** Uses Lookup Tables 1 & 2 (`0x9D00`).
*   **Logic:** Applies masking/transparency.
*   **Mapping:** 
    *   Bit 0: Cyan
    *   Bit 1: **Transparent**
    *   Bit 2: Orange
    *   Bit 3: Black

**3. Tier 3: High Masked Tiles (128-255 / 0x80-0xFF)**
*   **Assembly:** Uses Lookup Tables 3 & 4 (`0x9F00`).
*   **Logic:** Applies different masking and color swapping.
*   **Mapping:**
    *   Bit 0: Cyan
    *   Bit 1: Yellow
    *   Bit 2: **Transparent**
    *   Bit 3: Black

This system allows the game to reuse the same 2-bit storage format for different visual purposes (walls vs. objects) by interpreting the bits differently at runtime.

### 2.2. Building Blocks (The Material Table)
The game defines **96 building blocks** (indexed `0x00` to `0x5F`) in a table at `156Dh`.
*   **Nature:** These are **NOT** large bitmaps. They are **scripts** (bytecode).
*   **Function:** A block script tells the engine how to loop and stamp the 256 base tiles to create a larger shape.
*   **Efficiency:** A huge wall or complex archway takes up only a few bytes of script, reusing the same small brick tile repeatedly.

**Example Script - Floor Block (0x0D):**
```assembly
F7 70 ...       ; Update registers
FD              ; Outer Loop
  FC            ; Push position
  FE            ; Inner Loop
    F9 61 80 61 ; DrawTile(0x61, ...)
    F5          ; Inc X
    F6          ; Inc Y
    FA          ; End Inner Loop
  FB            ; Pop position
  F4            ; Dec Y
  FF            ; End
```

### 2.3. The Block Interpreter
Located at `1BBC` and `2018h`. It executes the block scripts.
*   **Commands:** `pintaTile` (draw), `incTilePosX`, `pushTilePos`, etc.
*   **Z-Buffer:** It draws into an off-screen **tile buffer** (`8D80h`) that stores depth information, ensuring correct occlusion of elements.

### 2.4. Room Construction
Rooms are stored in `abadia8.bin` (ROM bank 7).
*   **Data Structure:** A variable-length list of `(BlockID, Position)` pairs.
*   **Rendering:** The engine iterates through this list, calling the interpreter for each block to compose the full scene in the tile buffer.

## 3. Dynamic Elements (Sprites)

Characters and objects are handled as sprites.
*   **Drawing Routine:** `4914h`.
*   **Depth Sorting:** Sprites are sorted by their Y-coordinate (Painter's Algorithm) to ensure they are drawn in the correct order relative to each other and the background.
*   **Masking:** Transparency is handled via pre-calculated AND/OR masks (`3AD1h`).

## 4. Camera & Perspective

The engine supports **four 90-degree rotations**.
*   **Implementation:** Four distinct coordinate transformation routines (`2485h`).
*   **Assets:** Blocks likely have logic or different tiles to handle the visual changes required for each perspective.
*   **Rotation:** Changing the view involves updating the orientation variable (`2481h`) and triggering a full screen redraw.
