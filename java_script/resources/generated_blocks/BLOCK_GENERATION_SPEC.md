# Block Generation Specification

This document defines the exact logic used to generate the reference "Example Blocks" (`block_{N}.png` and `block_{N}.log`). This specification allows other implementations (e.g., Python) to reproduce the exact same set of test cases for verification.

## 1. Goal
To create a comprehensive "visual unit test" suite by rendering one example of every unique building block type found in the game, using real-world parameters from the game data.

## 2. Block Selection Strategy

The script iterates through the entire `rooms.json` file sequentially (Room 0 to Room 115).

1.  **Iterate Rooms**: Loop through `rooms` array by index `i` (0 to 115).
2.  **Iterate Blocks**: Inside each room, loop through the `blocks` array.
3.  **Calculate Script ID**: For each block, calculate the unique Script ID:
    ```javascript
    scriptId = block.type >> 1; // Integer division by 2
    ```
4.  **Filter Unique**: Keep track of `scriptId`s that have already been processed.
    *   **IF** this `scriptId` has *not* been seen before:
        *   **SELECT** this specific block instance (with its `x`, `y`, `height`, `param1`, `param2`) as the canonical example for this Script ID.
        *   Mark `scriptId` as seen.
    *   **ELSE**: Skip it.

**Result:** A list of unique test cases, where each case corresponds to the *first time* that specific block type appears in the game map.

## 3. Naming Convention

The output files must be named based on the **Script ID**, not the Raw Block Type.

*   **Image**: `generated_blocks/block_{SCRIPT_ID}.png`
*   **Log**: `generated_blocks/block_{SCRIPT_ID}.log`

*Example:* A block with raw type `0x1E` (30) corresponds to Script ID `15`. The output files are `block_15.png` and `block_15.log`.

## 4. Execution & Logging Logic

For each selected block, the interpreter must be reset and executed in isolation.

### A. Log File Structure
The log file must contain:
1.  **Header**:
    *   `BLOCK TRACE: #{SCRIPT_ID}`
    *   `SOURCE ROOM: {ROOM_ID}` (0-based index from rooms.json + 1)
    *   `BLOCK PARAMS: x={X}, y={Y}, h={HEIGHT}, p1={PARAM1}, p2={PARAM2}, type={RAW_TYPE}`
2.  **Script Source**:
    *   The raw text of the script from `scripts.abs`.
3.  **Execution Trace**:
    *   A line-by-line log of every instruction executed.
    *   Format: `[{SCRIPT_ID}:{LINE_NUM}] {OPCODE} {PARAMS}`
    *   Variable updates: `-> Set {VAR} = {VALUE}`
    *   Draw commands: `-> DRAWTILE ID {TILE_ID} @ ({GRID_X}, {GRID_Y}) Depth({DX}, {DY})`

### B. Rendering Logic
1.  **Canvas**: 320x200 pixels.
2.  **Background**: Transparent (Alpha 0).
3.  **Positioning**:
    *   Screen X = `32 + GridX * 16`
    *   Screen Y = `GridY * 8`
4.  **Z-Order**:
    *   Calculate depth: `DepthX + DepthY - 16`
    *   Sort tiles by **Depth** (ascending), then by **Creation Order** (ascending).
5.  **Draw**: Render tiles using the standard "Day" tileset.

## 5. Summary of Data Flow
`rooms.json` -> **Filter (First unique ScriptID)** -> **Execute (Trace Log)** -> **Render (PNG)** -> `generated_blocks/`
