# Session Handover - La Abadía del Crimen Disassembly

**Date:** December 21, 2025
**Status:** Interpreter & Block Extraction Phase Complete

## 1. Achievements
*   **Building Blocks Extracted:** Successfully parsed the "Material Table" at `0x156D`. Extracted 59 unique block scripts (bytecode) into a reusable Python library.
*   **Bytecode Decoded:** Reverse-engineered the game's custom building block opcodes (`F9` PaintTile, `FC` PushPos, etc.) and register mapping.
*   **Interpreter Built:** Implemented a full Python interpreter (`src/abadia/interpreter.py`) that executes real game scripts using a 64KB memory dump.
*   **Memory Dumped:** Created `src/abadia/resources/abbey_code.bin` (64KB) to allow the interpreter to handle `ChangePC` jumps and global memory access.
*   **Main Loop Located:** Identified the main game loop at `0x25B7` and documented it in `docs/GAME_LOOP.md`.

## 2. Key Artifacts
| File | Purpose |
| :--- | :--- |
| `src/abadia/abbey_blocks_library.py` | Contains the `BLOCK_DEFINITIONS` dictionary (Scripts & Metadata). |
| `src/abadia/interpreter.py` | The engine that runs the block scripts. |
| `src/abadia/block_renderer.py` | Tool to render individual blocks to PNGs (for verification). |
| `src/abadia/resources/abbey_code.bin` | Binary dump of the game memory (required by interpreter). |
| `docs/GAME_LOOP.md` | Documentation of the main game loop logic. |

## 3. Current State
*   The **Block Interpreter** is functional and verified (rendered Blocks 0x01 and 0x02 successfully).
*   The **Sprite Extraction** is complete (11 unique sprites).
*   **Missing:** We have not yet parsed `abadia8.bin` (Room Data). We can render *blocks*, but not yet full *screens/rooms*.

## 4. Immediate Next Steps
1.  **Analyze `abadia8.bin`:** Understand the format of the Room Definitions (Bank 7).
2.  **Implement Room Renderer:** Create a script that reads a Room ID, looks up the list of blocks in `abadia8.bin`, and uses the `AbadiaInterpreter` to draw them all onto a single `AbbeyCanvas`.
3.  **Connect Sprites:** Overlay the extracted sprites onto the rendered rooms.

## 5. How to Resume
Run the following commands to verify the current state:
```bash
# Verify Block Rendering
PYTHONPATH=. python3 src/abadia/block_renderer.py
```
Then, proceed with analyzing `abadia8.bin`.
