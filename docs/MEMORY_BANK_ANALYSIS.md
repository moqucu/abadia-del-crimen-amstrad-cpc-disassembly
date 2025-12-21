# Memory Bank & File Structure Analysis

## Overview
The game's memory management relies on a "windowing" technique where the Z80 memory bank from `0x4000` to `0x7FFF` is swapped with different content depending on the game state (Game Logic, Room Rendering, Debugging, etc.).

The disassembled code listing primarily represents **Memory Configuration 0** (Main Game Loop), where `abadia2.bin` occupies this window.

## Binary File Definitions

### `abadia5.bin` (The Debugger)
*   **Purpose:** Development tool left in the code by Paco Menéndez.
*   **Content:** A Z80 debugger used to step through code and inspect memory during development.

### `abadia6.bin` (Demo & Manuscript)
*   **0x0000 - 0x2FFF:** **Demo Recording.** Stores the sequence of keystrokes used for the "Attract Mode" demo (gameplay shown when idling at the title).
*   **0x3000 - 0x3FFF:** **Manuscript Logic.** Contains code routines for the intro scroll effect (partially duplicative of code in `abadia2.bin`).

### `abadia7.bin` (The 3D Engine Data)
*   **0x0A00 - 0x1414:** **Height Maps.** Defines the 3D geometry (elevation) for the Abbey's 3 floors. This data is essential for:
    *   **Collision Detection:** Determining where characters can walk.
    *   **Depth Sorting:** Correctly drawing sprites in front of or behind walls.
*   **0x1800 - 0x3FFF:** **AI Navigation.** Contains pathfinding data (banks 9-0) allowing monks to navigate the abbey's complex layout.

### `abadia8.bin` (Level Design & UI)
*   **0x0000 - 0x2237:** **Room Definitions.** The "Map" of the game. Defines the specific arrangement of isometric tiles for every screen in the Abbey.
*   **0x2328 - 0x2B27:** **Scoreboard/UI.** Graphics for the HUD (Day counter, Obsequium rating, Inventory).
*   **0x2B28 - 0x37FF:** **Endgame Content.** Music and text for the Final Scroll sequence.

## Memory Mapping Strategy
The game loads data into the CPC RAM banks as follows:

| RAM Address | Bank | Typical Content | Purpose |
| :--- | :--- | :--- | :--- |
| **0x0100 - 0x3FFF** | Bank 0 | `abadia1.bin` | **Core Kernel:** Main loop, interrupts, and hardware control. |
| **0x4000 - 0x7FFF** | Bank 1 | **Swappable** | **The Window:** Swaps between `abadia2` (Logic), `abadia5` (Debug), `abadia8` (Map), etc. |
| **0x8000 - 0xBFFF** | Bank 2 | `abadia3.bin` | **Assets:** Sprites, Fonts, and Audio data. |
| **0xC000 - 0xFFFF** | Bank 3 | `abadia0.bin` | **Video RAM:** The active screen buffer. |
