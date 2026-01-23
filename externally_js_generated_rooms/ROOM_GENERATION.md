# Abadía del Crimen Room Generation Algorithm

This document details the algorithm used to generate rooms in the JavaScript port of *La Abadía del Crimen*. This logic is a direct reimplementation of the original Z80 assembly routines found in the Amstrad CPC version (1987).

## 1. High-Level Hierarchy

The game world is constructed using a hierarchical data structure to save memory, a critical constraint on 8-bit systems.

1.  **Floors:** The map is divided into 3 floors (Main, Scriptorium, Library).
2.  **Rooms:** Each floor is a 16x16 grid. Each cell in this grid contains a **Room ID**.
3.  **Blocks:** A Room is defined by a list of **Blocks**. A block represents a geometric structure (e.g., a wall, a column, a floor patch).
4.  **Scripts:** A Block is essentially a call to a specific **Script** (Bytecode) with specific parameters (X, Y, Height).
5.  **Tiles:** The Script executes instructions to place **Tiles** (16x8 pixel bitmaps) onto a 2D isometric grid.

## 2. Block Definition

A room is constructed by processing a list of Blocks. In the binary data, a Block is defined by 4 bytes:

| Byte | Name | Description |
| :--- | :--- | :--- |
| 0 | `Type` | Determines the Script ID. `ScriptID = Type >> 1`. Bit 0 is a flag (often for height). |
| 1 | `X` | The starting X coordinate (0-31) in the isometric grid. |
| 2 | `Y` | The starting Y coordinate (0-31) in the isometric grid. |
| 3 | `Height`| The vertical height of the block (if applicable). |

**Assembly Context:** In the original game, this data is read sequentially from memory until a `0xFF` marker is reached, indicating the end of the room definition.

## 3. The Script Interpreter (Virtual Machine)

The core of the generation is a custom Virtual Machine (VM) that interprets a domain-specific bytecode. This allowed the original developers to define complex isometric shapes using very little memory.

### 3.1. Virtual Registers (State)

The VM maintains the following state for the current block being processed:

*   **X, Y:** Current cursor position in the local room grid (0-15 x 0-19).
*   **Z (Height):** Current vertical height (often implicit or manipulated via `HEIGHT`).
*   **PARAM1, PARAM2:** General-purpose loop counters extracted from the Block definition bits.
*   **DEPTHX, DEPTHY:** Values used for the isometric depth-sorting (painter's algorithm).
*   **FLIP:** A boolean flag. If true, `X` and `Y` axes are swapped, allowing the same script to draw a left-facing wall and a right-facing wall.
*   **Stack:** A LIFO stack used for `CALL` (subroutines) and `WHILE` loops.

### 3.2. Opcode Reference

The bytecode consists of opcodes that control the cursor, loop, and draw tiles.

#### Drawing & Movement
| Opcode | Description |
| :--- | :--- |
| `DRAWTILE [id]` | Places a tile at the current `(X, Y)` position. `id` is the tile index. The depth values (`DEPTHX`, `DEPTHY`) are associated with this placement. |
| `INC X` / `DEC X` | Increments or decrements the `X` register. |
| `INC Y` / `DEC Y` | Increments or decrements the `Y` register. |

#### Flow Control
| Opcode | Description |
| :--- | :--- |
| `JMP [id], [line]` | Unconditional jump to a specific Script ID and line number. |
| `CALL [id]` | Calls another script as a subroutine. Pushes current state to stack. |
| `CALLP [id]` | Same as `CALL`, but preserves the `FLIP` state differently (context-dependent). |
| `WHILE [reg]` | Starts a loop. Decrements the register (`PARAM1` or `PARAM2`). If > 0, pushes loop context to stack. |
| `ENDWHILE` | Ends a loop block. Checks the stack to decide whether to loop back or continue. |
| `END` | Terminates the script execution for the current block. |

#### Logic & State
| Opcode | Description |
| :--- | :--- |
| `FLIP` | Toggles the `FLIP` flag. Swaps the semantic meaning of X and Y axes for subsequent operations. |
| `LD [reg], [val]` | Loads a value into a register (`DEPTHX`, `DEPTHY`, etc.). |
| `ADD [reg], [val]`| Adds a value to a register. |
| `PUSH [reg]` | Pushes a register value onto the stack. |
| `POP [reg]` | Pops a value from the stack into a register. |

*Note: In `FLIP` mode, instructions like `INC X` typically behave as `INC Y` relative to the screen, allowing mirrored geometry reuse.*

## 4. Rendering Pipeline

The generation of a single frame (Room) follows this pipeline:

### Step 1: Initialization
An empty 2D buffer is created: `TileBuffer[16][20]`. This grid represents the isometric floor space.

### Step 2: Block Execution
For every Block in the Room's list:
1.  The VM initializes registers (`X`, `Y`, `HEIGHT`, `PARAM1`, `PARAM2`) from the Block data.
2.  `DEPTHX` and `DEPTHY` are calculated based on the block's geometric center (used for occlusion).
3.  The specific Script (Bytecode) is executed line-by-line.
4.  When `DRAWTILE` is encountered, a record is added to `TileBuffer[currentX][currentY]`.
    *   **Record:** `{ TileID, DepthX, DepthY }`

### Step 3: Depth Sorting (The "Painter's Algorithm")
Since isometric projection is 2.5D, the order of drawing matters.
1.  All tile records generated in Step 2 are collected into a flat list.
2.  The list is sorted primarily by **Depth** and secondarily by **Priority** (order of execution).
    *   `Depth = DepthX + DepthY`
    *   This represents the "Manhattan distance" from the camera. Tiles with lower depth values (further away) are drawn first. Tiles with higher depth (closer) are drawn last, covering the background.

### Step 4: Rasterization
1.  The system iterates through the sorted list.
2.  For each tile, the screen coordinates are calculated:
    *   `ScreenX = OffsetX + (GridX * 16)`
    *   `ScreenY = GridY * 8`
3.  The 16x8 pixel bitmap corresponding to the `TileID` is copied to the framebuffer (handling transparency).

## 5. Comparison to Z80 Assembly

In the original assembly:
*   **Self-Modifying Code:** The `FLIP` instruction likely utilized self-modifying code or jump tables to swap opcode handlers (e.g., swapping the memory address for `INC X` with `INC Y`).
*   **Memory Pointers:** Instead of array lookups (`scripts[id]`), the original used a jump table (`BASE_ADDRESS_BLOCK_TABLE`) pointing to memory addresses where the bytecode resided.
*   **Stack:** The VM likely used the actual Z80 hardware stack (`SP`) or a dedicated software stack in RAM to handle nested `CALL`s and `WHILE` loops.
