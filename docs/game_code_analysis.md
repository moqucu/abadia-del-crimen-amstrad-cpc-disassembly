# Analysis of "La Abadía del Crimen" Game Code

This document provides a high-level overview of the disassembled Z80 code for the Amstrad CPC. Detailed technical analysis for individual subsystems is available in the linked documents within each section.

## 1. System Map Overview

| Address Range | Component | Key Document |
|:---|:---|:---|
| `0400h - 058Fh` | **Boot & Save/Load** | [Memory Bank Analysis](MEMORY_BANK_ANALYSIS.md) |
| `0590h - 0D12h` | **AI & Pathfinding** | [AI & Pathfinding](AI_PATHFINDING.md) |
| `0D13h - 0F95h` | **Objects & Doors** | - |
| `0F96h - 1569h` | **Sound & Music** | - |
| `156Ah - 2499h` | **Graphics Engine** | [Graphics Engine](GRAPHICS_ENGINE.md) |
| `249Ah - 2782h` | **Main Loop & Rendering** | [Graphics Engine](GRAPHICS_ENGINE.md) |
| `2783h - 359Ch` | **Input & Interrupts** | - |
| `359Dh - 659Ch` | **Logic & Event Scripts** | [Scripting System](SCRIPTING_SYSTEM.md) |
| `8000h - BFFFh` | **Static Assets** | [Graphics Engine](GRAPHICS_ENGINE.md) |

---

## 2. Component Analysis

### 2.1. Boot & Save/Load (`0400h - 058Fh`)
The game initializes at `0400h`. This section handles the high-level setup and the system for persisting game state by writing memory banks directly to disk tracks.
*   **See:** [MEMORY_BANK_ANALYSIS.md](MEMORY_BANK_ANALYSIS.md) for the file structure and memory windowing details.

### 2.2. AI & Pathfinding (`0590h - 0D12h`)
This section contains the "brains" of the NPCs (Abbot, Malaquias, etc.) and the algorithms that allow them to navigate the Abbey's floors. It manages the **Height Buffer**, which is the logical 3D model of the game world.
*   **See:** [AI_PATHFINDING.md](AI_PATHFINDING.md) for height maps, collision, and NPC logic.

### 2.3. Objects & Doors (`0D13h - 0F95h`)
Handles the inventory system and interaction with the Abbey's doors. It includes permission tables (who can go where) and logic for picking up or dropping items like the lamp or keys.

### 2.4. Sound & Music (`0F96h - 1569h`)
A custom driver for the AY-3-8910 sound chip. It handles multi-channel music playback, ADSR envelopes, and sound effects for the game.

### 2.5. Graphics Engine (`156Ah - 2499h`)
The "Block Interpreter" resides here. It uses custom bytecode to assemble 256 base tiles into complex architectural elements like arches, stairs, and furniture.
*   **See:** [GRAPHICS_ENGINE.md](GRAPHICS_ENGINE.md) for the bytecode language and tile-composition logic.

### 2.6. Main Loop & Rendering (`249Ah - 2782h`)
The central orchestrator that runs every frame. It checks input, triggers AI updates, and performs the final sprite rendering pass using a depth-sorted "Painter's Algorithm."
*   **See:** [GRAPHICS_ENGINE.md](GRAPHICS_ENGINE.md) for sprite sorting and VRAM drawing.

### 2.7. Input & Interrupts (`2783h - 359Ch`)
Manages the hardware-level interrupts (at `0038h`) used for timing and music. It also handles the keyboard scanning and identifies special key combinations (e.g., Save/Load/Pause).

### 2.8. Logic & Event Scripts (`359Dh - 659Ch`)
Much of the game's high-level narrative logic is written in a custom scripting language invoked via `RST 08h` and `RST 10h`. This section contains the triggers for conversations and scripted plot points.
*   **See:** [SCRIPTING_SYSTEM.md](SCRIPTING_SYSTEM.md) for the bytecode operator and variable token reference.

### 2.9. Static Assets (`8000h - BFFFh`)
This region in Bank 2 contains the raw data for the game, including tile bitmaps, font data, and music sequences.
*   **See:** [GRAPHICS_ENGINE.md](GRAPHICS_ENGINE.md) for tile format and palette details.