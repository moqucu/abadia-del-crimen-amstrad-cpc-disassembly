# Function and Inner Working of Building Blocks in La Abadía del Crimen

Here is a summary of the building block system in *La Abadía del Crimen*, illustrating how the game achieves its complex architecture within the limited memory of the Amstrad CPC.

### 1. Function and Inner Workings

The game engine acts as a **virtual machine**. Instead of storing the game world as a giant image (which would require megabytes of RAM), it stores the world as a list of "Blocks."

*   **Procedural Generation:** Each "Block" is actually a tiny computer program (bytecode).
*   **The Interpreter:** When the game enters a room, the engine reads the list of blocks. For each block, it sets up initial coordinates $(X, Y)$ and dimensions (Width `P1`, Height `P2`).
*   **Registers:** The engine uses specific memory slots (Registers) to control drawing:
    *   **`T0` - `T11`**: Registers holding the specific 2D Tile IDs (graphics) to be used for this specific block (e.g., a brick tile, a window tile).
    *   **`PARAM1`**: Typically controls the **Width** (loop count X).
    *   **`PARAM2`**: Typically controls the **Height** (loop count Y).
*   **Execution:** The script loops, moves a virtual cursor in isometric space (e.g., "Move Decrement Y"), and stamps tiles into the Depth Buffer.

This allows a massive wall to be defined by just a few bytes: *"Load 'Brick' tile. Repeat 20 times: Draw Brick, Move Up. End."*

---

### 2. Simple Example: Floor Block (0x0D)

Here is a real example based on **Block 0x0D**, which renders a tiled floor. This block draws a grid of tiles based on `PARAM1` (width) and `PARAM2` (depth).

#### A. Original Amstrad CPC Bytecode (Hex)
This is what is actually stored in the game's memory (ROM).

```text
FD FC FE F9 61 80 61 F5 F6 FA FB F4 FF
```

#### B. Human-Readable Translation (DSL)
This is how the `dsl.py` module I enhanced translates that bytecode so humans can understand it.

```assembly
[SCRIPT 0x0D]       ; Start of Block 0x0D script
WHILE PARAM2        ; (FD) Loop 'Height' times (Outer Loop)
  PUSH X            ; (FC) Save current X position
  PUSH Y            ; (FC) Save current Y position (FC does both)
  
  WHILE PARAM1      ; (FE) Loop 'Width' times (Inner Loop)
    DRAWTILE T1     ; (F9 61) Draw Tile stored in Register T1 (0x61)
    DEC Y           ; (80) Control byte: Draw and Move "DEC Y" (part of F9)
    
    INC X           ; (F5) Move cursor: X = X + 1
    INC Y           ; (F6) Move cursor: Y = Y + 1
  ENDWHILE          ; (FA) End Inner Loop

  POP Y             ; (FB) Restore saved Y position
  POP X             ; (FB) Restore saved X position
  
  DEC Y             ; (F4) Move cursor down one row for the next line
ENDWHILE            ; (Implicit in FD logic, loops back)

END                 ; (FF) End of script
```

### 3. Step-by-Step Explanation of the Example

1.  **`WHILE PARAM2`**: The script checks the Height passed to it. If the room definition says this floor is 5 units deep, it loops 5 times.
2.  **`PUSH X/Y`**: It remembers where the row started.
3.  **`WHILE PARAM1`**: It checks the Width. If the floor is 4 units wide, it enters this inner loop 4 times.
4.  **`DRAWTILE T1`**: It draws the tile currently loaded in register `T1` (e.g., a blue floor tile). The `DEC Y` is a side-effect of the specific draw opcode `0xF9` (Draw and step back).
5.  **`INC X`, `INC Y`**: It moves the "cursor" to the right in isometric space to prepare for the next tile in the row.
6.  **`POP`**: After finishing a horizontal row, it resets the position to the start of the row.
7.  **`DEC Y`**: It steps "down" one isometric unit to begin drawing the next row.

By changing just `PARAM1`, `PARAM2`, and the graphic in `T1`, this exact same script can draw a tiny rug or a massive cathedral hall.
