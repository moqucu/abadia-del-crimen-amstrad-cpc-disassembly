# Event Scripting System Analysis

To manage complex game logic and interactions efficiently, "La Abadía del Crimen" uses a custom, data-driven scripting language embedded in the Z80 code.

## 1. System Overview

Instead of writing unique assembly code for every event (e.g., "If it's night and the Abbot is here, say this text"), the game uses a compact **bytecode** interpreted at runtime.

*   **Interpreter:** Located at `3DD1h` (called via `RST 08h`).
*   **Action Handler:** Located at `3DAFh` (called via `RST 10h`).

## 2. Bytecode Structure

A script is a sequence of bytes representing an expression or command.

### 2.1. Tokens
*   **Variables (`0x80+`):** Bytes `0x80` and above are tokens that reference specific memory addresses (Game Variables).
    *   *Example:* Token `0x88` -> Memory `2D81h` (Time of Day).
    *   *Example:* Token `0x80` -> Memory `3038h` (Guillermo X Pos).
    *   *Full Table:* Defined at `3D1D`.
*   **Literals (`< 0x80`):** Bytes below `0x80` are treated as raw numbers.
*   **Operators:** Special bytes for logic.
    *   `0x3D` (`=`): Equality
    *   `0x3E` (`>`): Greater Than
    *   `0x2A` (`*`): OR
    *   `0x26` (`&`): AND
    *   `0x2B` (`+`): Add

## 3. How It Works (Example)

Consider the logic for an AI decision:

```assembly
rst 08h             ; Call "EVALUATE" interpreter
db 88h, 00h, 3Dh    ; [TimeOfDay] == 0
db 88h, 06h, 3Dh    ; [TimeOfDay] == 6
db 2Ah              ; OR
jp nz, Action       ; If True (ZF=0), Jump to Action
```

1.  **`rst 08h`**: The CPU jumps to the interpreter.
2.  **Parsing**: The interpreter reads the bytes following the instruction pointer.
3.  **Fetch**: It sees `88h`, looks up address `2D81h`, and reads the current Time of Day (e.g., `5`).
4.  **Calc**: It evaluates `5 == 0` (False). It evaluates `5 == 6` (False). It evaluates `False OR False` (False).
5.  **Result**: It returns control to the main code with the **Zero Flag** set (indicating False).
6.  **`jp nz`**: The jump is NOT taken.

## 4. `RST 10h` (Assignment)

The `RST 10h` instruction handles **actions** (assignments).
*   **Format:** `RST 10h`, `[Destination_Token]`, `[Expression_Script]`.
*   **Logic:** It evaluates the expression using the `RST 08h` logic and stores the result in the variable referenced by the destination token.
*   **Use Case:** Updating AI goals (`SET [Malaquias_Goal] = [Cell]`).

## 5. Decompilation Potential

Because the bytecode maps 1:1 to logical operations, it is fully reversible. A tool could parse the binary, identify `rst 08h`/`10h` calls, and translate the subsequent hex bytes into high-level pseudo-code:

**Original Hex:** `88 00 3D`
**Decompiled:** `IF (TimeOfDay == 0)`

This system allowed the developers to pack a massive amount of narrative and logic into the limited memory of the CPC.
