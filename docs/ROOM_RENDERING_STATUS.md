# Room Rendering Status & Remaining Gaps

## Overview
The Python room rendering engine has been significantly improved to match the JavaScript reference implementation. The core Z-depth sorting logic for the two primary block types (Walls and Floor) now matches exactly.

## Achieved Milestones
*   **Initialization Logic:** Implemented `H=255` special case (Regs=0) and `H=20` standard case (Offset=-3).
*   **Floor Depth:** Floor tiles (H=255) now correctly render at Depth `-16`, matching the reference.
*   **Wall Depth:** Standard walls (H=20) correctly render at Depth `46`, matching the reference.
*   **Coordinate System:** Grid and Screen coordinates align perfectly with the reference.
*   **Logging:** Implemented 3-layer logging (Manifest, Events, Render List) to isolate discrepancies.

## Remaining Discrepancies (Room 1 Analysis)

Comparison of the full trace logs reveals specific block-level differences that persist:

### 1. Execution Flow Mismatches (Loops)
Some blocks execute fewer draw commands in Python than in JS, indicating potential bugs in the `WHILE/ENDWHILE` opcode implementation or Parameter handling.

*   **Block #04 (Prio 4):**
    *   **JS:** Draws 36 tiles (Loops 2x4 times?).
    *   **Python:** Draws only 2 tiles (`106`, `6`) and stops.
    *   *Impact:* Missing visual parts of the wall/pillar.

### 2. Register Initialization for H=0
*   **Block #03 (Prio 3):**
    *   **Properties:** `Pos (21, 13)`, `H=0`.
    *   **JS RawRegs:** `(16, 8)`. (Implies Offset `-5`? `21-5=16`, `13-5=8`).
    *   **Python RawRegs:** `(15, 10)`. (Implies Offset `-6` and `-3`?).
    *   *Impact:* Depth calculation is off for `H=0` blocks (Depth 8 vs 14?).

### 3. Tile ID Mismatches
*   **Block #00 (Prio 0):** Python draws `Tile 5`, JS draws `Tile 89`. (Likely Block Data difference).
*   **Block #29 (Prio 29):** Python draws `Tile 6`, JS draws `Tile 116`.

## Next Steps
1.  **Debug Interpreter Loops:** Investigate why Block 4 loops terminate early. Trace `OP_WHILE` (0xFE/0xFD) logic.
2.  **Refine Offsets:** Determine exact offset for `H=0`.
3.  **Audit Block Data:** Verify Block Definitions for Tile IDs.
