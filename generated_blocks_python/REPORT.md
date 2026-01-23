# Python Block Rendering Report

**Date:** January 22, 2026

## Overview
This directory contains the results of replicating the JavaScript-based block rendering logic in Python.
The goal was to verify that the Python `AbadiaInterpreter` correctly executes the game's bytecode scripts and produces identical output (traces and images) to the reference implementation.

## Contents
*   `block_traces.log`: A comprehensive execution trace of visible occurrences of every block type found in the game rooms, plus manually rendered traces for unused block types.
*   `block_type_XX.png`: Rendered images of each block type.

## Changes Implemented
To match the reference behavior, the following updates were made to `src/abadia/interpreter.py`:

1.  **Depth Register Initialization**:
    *   `DEPTHX` (Reg 16) and `DEPTHY` (Reg 17) are now initialized to `start_x + height + 3` and `start_y + height + 3` respectively. This offset of `+3` was empirically derived from the reference traces.

2.  **Reverse Subtraction (Opcode 0x84)**:
    *   The `0x84` opcode in expression evaluation was identified as a "Reverse Subtract" (`val2 - val`) rather than standard subtract or add. This ensures correct coordinate/depth calculations in complex scripts.

3.  **FlipX Register Swapping**:
    *   Implemented logic to swap `DEPTHX` (Reg 16) and `DEPTHY` (Reg 17) accesses when `flipX` mode is active. This affects `LD` instructions and expression evaluation, ensuring that depth calculations are correctly mirrored when the block geometry is flipped.

4.  **Implicit Tileset Loading (The "Header" Fix)**:
    *   Many blocks call subroutines that start with bytes invalid in the bytecode instruction set (e.g., `0xC2`, `0xC6`, `0x52`).
    *   Analysis revealed these are **Tile Set Pointers** (2 bytes) embedded at the start of blocks/routines.
    *   The interpreter was updated to detect these invalid opcodes (`< 0xE0`), treat them as a pointer, load 12 bytes of tile data from that address into the registers, and then continue execution. This resolved empty renderings for Block 54, Block 9, and many others.

5.  **Trace Logging**:
    *   Added a detailed tracing mechanism to capture opcode execution, register updates, and draw commands in a format comparable to the reference logs.

## Verification
*   **Block 2 Trace**: The generated trace for Block Type 2 (Room 0) matches the reference trace structure.
*   **Rendering**: Most blocks now render correctly.
*   **Visibility Fix**: The replication script (`replicate_block_traces.py`) prioritizes visible block occurrences to avoid clipping issues.
*   **Orphaned Blocks**: Unused blocks (e.g., Block 17) are rendered manually.

## Remaining Issues
*   **Z80 Routines**: Some blocks (e.g., Block 56, 83) appear to rely on subroutines (like `0x1805`) that contain Z80 machine code or complex logic not expressible in the high-level bytecode. These blocks currently produce empty outputs because the interpreter cannot execute Z80 instructions. The reference implementation likely includes specific handlers or hacks for these cases (e.g. `TILE_HACKS` mentioned in documentation).

## Conclusion
The Python interpreter now correctly handles the vast majority of the game's rendering logic, including the discovery of the implicit tileset loading mechanism.