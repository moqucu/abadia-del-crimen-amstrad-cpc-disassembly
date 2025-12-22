# Main Game Loop Analysis

**Location:** `0x25B7` (Bank 0 / `abadia1.bin`)

The main loop orchestrates the game's logic, AI, input, and rendering. It runs continuously during gameplay.

## Structure

| Address | Function | Description |
| :--- | :--- | :--- |
| **25B7** | **Start** | Loop entry point. |
| **25B8 - 25C7** | **Input & System** | Checks for special keys (Pause, Save) and updates search routine parameters. |
| **25CF** | **Time Update** | Calls `55B6` to update time-related variables (time of day, lamp fuel). |
| **25D5 - 25D8** | **Game Over Check** | Checks if Guillermo has died or failed the investigation (`42E7`, `42AC`). |
| **25DB** | **Scroll** | Advances the "Time of Day" text scroll if active (`5499`). |
| **25DE** | **Voice & Events** | Calls `3EEA` to process voice lines and time-specific events. |
| **25E1** | **Camera & Bonus** | Updates camera target and calculates score bonuses (`41D6`). |
| **25E4** | **Screen Check** | Calls `2355` to check if the character has moved to a new screen. |
| **25E7 - 25ED** | **Render Screen** | If the redraw flag (`2DB8`) is set, calls `19D8` to render the isometric background. |
| **25F0 - 25F8** | **Objects & Doors** | Handles picking up/dropping objects (`5096`) and updating door states (`0D67`). |
| **25FB - 25FE** | **Player Move** | Updates Guillermo's position and sprite (`291D`). |
| **2601** | **NPC Move** | Calls `2664` to execute AI/movement for Adso and other monks. |
| **260B** | **Light Logic** | Updates the light sprite characteristics (`26A3`). |
| **260E - 2611** | **Mirror/Flip** | Handles door flipping (`0E66`) and mirror reflections (`5374`). |
| **2614 - 2619** | **Sync** | **Frame Limiter:** Waits for interrupt counter (`2D4B`) to reach threshold. |
| **261B - 2620** | **Sound** | Plays footstep sounds if Guillermo is moving. |
| **2627** | **Draw Sprites** | Calls `2674` to render all dynamic sprites (characters, objects) over the background. |
| **262A - 2632** | **Loop Control** | Checks for ESC key. Jumps back to `25B7`. |

## Key Subroutines

*   **`19D8` (Draw Screen):** Renders the static room using building blocks.
*   **`2674` / `4914` (Draw Sprites):** Renders dynamic elements using the painter's algorithm.
*   **`55B6` (Time):** manages the passage of game time (canonical hours).
*   **`2664` (NPC AI):** Calls individual behavior routines for each monk.

## Memory Variables

*   **`0x2D4B`:** Interrupt counter used for frame synchronization.
*   **`0x2DB8`:** Screen redraw flag (nonzero = redraw needed).
*   **`0x3036`:** Guillermo's animation state.
