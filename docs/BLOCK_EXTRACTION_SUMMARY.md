# Building Block Extraction Summary

**Source:** `translated_english_files/0 - abadia_del_crimen_disassembled_CPC_Amstrad_game_code.asm`
**Output:** `src/abadia/abbey_blocks_library.py`

## Overview
Successfully extracted **59 building block scripts** from the game's Material Table at `0x156D`. These scripts are the "DNA" of the game's screens, defining how base tiles are assembled into walls, arches, and furniture.

## Extraction Statistics
*   **Total Blocks in Table:** 96 (IDs 0x00 - 0x5F)
*   **Successfully Extracted:** 59 blocks
*   **Missing/Empty:** 37 blocks (mostly null pointers or unparsed memory regions)

## Python Class Structure
The blocks are stored in `src.abadia.abbey_blocks_library.BLOCK_DEFINITIONS` as `BlockDef` objects:

```python
class BlockDef:
    def __init__(self, block_id, description, tile_ptr, bytecode):
        self.block_id = block_id      # e.g., 0x01
        self.description = description # e.g., "thin black brick parallel to y"
        self.tile_ptr = tile_ptr      # Address of the tile list
        self.bytecode = bytecode      # List of int opcodes (e.g., [0xF9, 0x61...])
```

## Key Blocks Identified
*   **0x01:** Thin black brick wall (Vertical)
*   **0x02:** Thin red brick wall (Horizontal)
*   **0x0D:** Floor of thick blue tiles
*   **0x11/0x12:** Complex Arches
*   **0x4A:** Work Table

## Usage
You can now import this library to render screens:
```python
from src.abadia.abbey_blocks_library import BLOCK_DEFINITIONS

block = BLOCK_DEFINITIONS[0x01]
interpreter.execute(block.bytecode)
```