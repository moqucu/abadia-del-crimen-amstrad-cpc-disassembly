# Rendering Logic Documentation

This document details the rendering logic for the *Abadía del Crimen* JavaScript conversion. It explains how "building blocks" are interpreted and rendered to the screen.

## Overview

The game logic separates the visual representation of rooms into "Blocks". A room is composed of a list of blocks. Each block is a programmatic entity defined by a script (byte code). These scripts allow for complex, reusable, and parametric structures (like arches, stairs, pillars) to be defined compactly.

The rendering pipeline has two main stages:
1.  **Interpretation**: Executing the block scripts to generate a list of "Tiles" with associated 3D depth information.
2.  **Rasterization**: Drawing these tiles to the screen, sorted by depth (Painter's Algorithm).

## Coordinate System

*   **Grid**: The game operates on a 16x20 grid.
*   **Screen**: The screen resolution is 320x200.
*   **Tiles**: Each grid cell is 16x8 pixels in screen space (isometric projection effect).
    *   Screen X = `Offset X` + `Grid X` * 16
    *   Screen Y = `Grid Y` * 8
*   **Depth**: Depth is calculated to handle occlusion. It is derived from the X, Y, and Height properties of the block.

## Building Blocks

A block in `rooms.json` is defined by:
*   `type`: The ID of the block type. This maps to a script (e.g., `type` 2 maps to `SCRIPT1`). The formula is roughly `SCRIPT_ID = type >> 1`.
*   `x`, `y`: The position of the block origin in the 16x20 grid.
*   `height`: The base height of the block (used for depth calculation).
*   `param1`, `param2`: customizable parameters passed to the script (e.g., number of steps in a stair, height of a column).

## Script Interpreter

The core logic resides in the `ScriptInterpreter`. It executes a custom bytecode.

### Variables

The interpreter maintains a state with the following variables:
*   `X`, `Y`: Current cursor position in the local block coordinate system.
*   `DEPTHX`, `DEPTHY`: Variables used to calculate the Z-depth of a tile. They are initialized based on the block's `x`, `y`, and `height`.
*   `PARAM1`, `PARAM2`: Input parameters from the block definition, often used as loop counters.
*   `HEIGHT`: The block's height property.
*   `flipX`: A boolean flag. When true, `X` coordinate operations are inverted, and `DEPTHX`/`DEPTHY` references are swapped in `LD` instructions.

### Opcodes

| Opcode | Arguments | Description |
| :--- | :--- | :--- |
| `JMP` | `ScriptID`, `Line` | Unconditional jump to another script at a specific line. |
| `LD` | `Target`, `Expression` | Loads the result of an expression into a variable (`DEPTHX`, `DEPTHY`, `PARAM1`, etc.). If `Target` is a depth var and current value is 0, the load is skipped. |
| `ADD` | `Target`, `Value` | Adds a value to a variable. |
| `WHILE` | `Variable` | Starts a loop. The loop continues as long as `Variable > 0`. |
| `ENDWHILE` | - | Ends a loop block. Decrements the loop variable and jumps back if > 0. |
| `PUSH` | `Variable` | Pushes the value of a variable onto the stack. |
| `POP` | `Variable` | Pops a value from the stack into a variable. |
| `DRAWTILE` | `TileID` | Generates a draw command for `TileID` at current `X`, `Y` with current `DEPTHX`, `DEPTHY`. `TileID` can be a literal or a reference `T0`-`T9` to the script's local tile palette. |
| `DEC` | `Variable` | Decrements a variable. If `flipX` is active and variable is `X`, it increments instead. |
| `INC` | `Variable` | Increments a variable. If `flipX` is active and variable is `X`, it decrements instead. |
| `CALL` | `ScriptID` | Calls another script as a subroutine. Preserves current state (block, flipX, line). Tileset is updated to the called script's tiles. |
| `CALLP` | `ScriptID` | Calls another script but **does not** update the tileset (uses caller's tiles). |
| `FLIP` | - | Toggles the `flipX` state. |
| `END` | - | Terminates execution of the current script. |

### Expressions

The `LD` and `ADD` instructions support simple mathematical expressions (e.g., `-( 1 + PARAM2 + PARAM2 ) + DEPTHY`). These are evaluated dynamically.
*   **Flip Handling**: If `flipX` is true during expression evaluation, `X` and `Y` variable references in the expression string are swapped (`X` becomes `Y`, `Y` becomes `X`).

## Rendering Process

1.  **Initialization**: The interpreter clears a 2D buffer (`16 x 20` array of lists).
2.  **Execution**: For every block in the room:
    *   The interpreter runs the corresponding script.
    *   `DRAWTILE` commands calculate the screen position (`px`, `py`) based on `block.x` and `block.y`.
    *   A "Renderable Tile" object is created containing: `tileId`, `depthX`, `depthY`.
    *   This object is pushed into the `tileBuffer[px][py]` list.
3.  **Depth Sorting (Within Cell)**:
    *   Within each cell `(x,y)`, multiple tiles might exist (e.g., a wall behind a pillar).
    *   When a new tile is added to a cell, the buffer logic checks if the new tile's depth is greater than the existing ones.
    *   *Correction Logic*: `AbadiaBuilder` contains logic to adjust depth if `(tOld.depthX + tOld.depthY) > (tNew.depthX + tNew.depthY)`.
4.  **Global Sorting**:
    *   All tiles from the buffer are flattened into a list.
    *   Each tile is assigned a global `depth` value: `depth = depthX + depthY - 16`.
    *   The list is sorted by `depth` (ascending), then by insertion `priority`.
5.  **Drawing**:
    *   Sprites are drawn to the canvas in the sorted order.

## Hacks & Fixes

The codebase includes specific "hacks" (`TILE_HACKS` in `generate_all_rooms.js` and `AbadiaBuilder.js`) to fix visual glitches in specific rooms (e.g., Room 38 stairs, Room 116 mirror). These manually override the `depthX`/`depthY` or add extra tiles after the script execution.
