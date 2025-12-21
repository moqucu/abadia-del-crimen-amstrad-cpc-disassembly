# Analysis of "La Abadía del Crimen" Game Code

This document provides a high-level analysis of the disassembled Z80 assembly code for the game "La Abadía del Crimen". The analysis is based on the provided source files, including the chunked disassembly and various map files. The goal is to create a foundational document that can be expanded upon later.

*Note: All address references are in hexadecimal and refer to the memory layout after the game has been loaded.*

## 1. Game Initialization (`0400h` - `2509h` in `chunk_aa`, `chunk_ai`)

The game's execution begins at `0400h`. The initial code is responsible for setting up the game environment.

- **Initial Setup (`0400h` -> `249Ah`):** A jump from `0400h` leads to the main initialization routine at `249Ah`.
- **First-Time Setup (`24A2h`):** On the very first run, the game configures the Amstrad's Gate Array for **Mode 1 graphics (320x200, 4 colors)**, disables system ROMs, and sets a black palette.
- **Scroll Presentation:** It copies and executes the code for the introductory manuscript scroll effect from `abadia6.bin` (see `maparoms.txt` and `chunk_bc`). This involves music, text rendering, and the iconic page-turning animation.
- **Interrupts (`24CDh`):** The game sets up its own interrupt service routine by placing a jump to `2D48h` at the system's interrupt vector (`0038h`). This routine is crucial for timing-based events, music, and controlling the overall game speed.
- **Graphics Initialization (`24F2h`):** It copies essential graphics data, including sprites for characters and objects, from `abadia3.bin` into active memory (`0x6d00-0x8cff`), as detailed in `mapamemoria.txt`.
- **Data Structures Initialization (`2503h`):** Various game data structures are initialized:
    - **`flipx` table (`3A61h`):** A lookup table for horizontally flipping sprites is generated.
    - **AND/OR tables (`3AD1h`):** Color mask tables for sprite rendering are created.
    - **Game State (`381Eh`):** Core game variables, object states, and character data are cleared and initialized to their starting values.

## 2. Main Game Loop (`25B7h` in `chunk_aj`)

Once initialization is complete, the game enters its main loop at `25B7h`. This loop orchestrates all the core gameplay systems on each frame.

The sequence of operations is as follows:
1.  **Input Check (`25BEh`):** The game checks for special key presses like **pause (DELETE)** or the **save/load game functions (CTRL+F-key)**.
2.  **Game Logic and Time (`25D5h`):** A series of calls to routines that manage the passage of time, character AI, and scripted events.
3.  **Screen Update (`25E4h`):** Checks if the camera's view has changed. If so, the screen is redrawn (`19D8h`). This involves re-rendering the entire 3D environment for the new view.
4.  **Object/Door Processing (`25F8h`):** Updates the state of all objects and doors on the current screen.
5.  **Character Updates (`25FBh`):** Updates the state and position of all characters, including the player (Guillermo) and NPCs.
6.  **Light/Darkness (`26A3h`):** Handles the logic for the lamp and the effect of darkness in certain rooms.
7.  **Sprite Rendering (`2674h`):** Finally, all visible sprites are drawn to the screen. The routine at `4914h` sorts sprites by depth before drawing them to ensure correct layering.
8.  **Loop/Wait (`2614h`):** A delay is introduced to control the game speed before the loop repeats.

## 3. Game Engine and Core Systems

### 3.1. Isometric 3D Engine: A Deeper Look

The game's 3D effect is achieved through a sophisticated **2D tile-based isometric engine**. It is not a vector-based or real-time polygonal rendering system. The world is constructed from pre-drawn 2D bitmap assets, which are composed to create the illusion of a 3D space. The graphics data is fundamentally organized into two types: background tiles and sprites.

#### Background Graphics (Tile-Based Composition)

The static background of each room is not a single large bitmap. Instead, it is dynamically constructed from smaller building blocks using a powerful, multi-layered system:

1.  **Tiles (Bitmaps):** The most fundamental graphical units are small bitmaps. There are exactly **256 base tiles** (numbered `0x00` to `0xFF`), each measuring **16×8 pixels**. These tiles are stored in `abadia3.bin` at offset `0x0300-0x22FF` and are copied to memory at `0x6D00-0x8CFF` during game initialization. Each tile occupies 32 bytes in Amstrad CPC Mode 1 format (4 colors, 2 bits per pixel, 4 bytes per scanline × 8 scanlines).
2.  **Blocks/Materials (Scripts - Not Bitmaps!):** This is the key architectural innovation of the engine. The material table at address `156Dh` contains exactly **96 different building blocks** (indexed `0x00` to `0x5F`). **Critically, these are NOT pre-rendered bitmaps** - they are **small programs** written in a custom bytecode language that tell the engine how to assemble the 256 base tiles into larger architectural structures.

    Each building block consists of:
    - A pointer in the material table
    - A script of drawing commands (bytecode)

    **Example Script - Floor Block (0x0D at address 1BCF):**
    ```
    F7 70 02 6E 6E 84 70    UpdateReg(0x70, -(2 + 2*Param2) + reg(0x70));
    F7 71 03 6D 6D 84 71    UpdateReg(0x71, -(3 + 2*Param1) + reg(0x71));
    E0                      IncParam1();
    EF                      IncParam2();
    FD                      while (param2 > 0){
      FC                      PushTilePos();
      FE                      while (param1 > 0){
        F9 61 80 61             DrawTile(0x61, 0x80, 0x61);
        F5                      IncTilePosX();
        F6                      IncTilePosY();
        FA                    }
      F9 61 80 62             DrawTile(0x61, 0x80, 0x62);
      FB                      PopTilePos();
      F4                      DecTilePosY();
      F3                      DecTilePosX();
      FA                    }
    FF                      // end
    ```

    **Scripting Language Commands:**

    | Bytecode | Command | Function |
    |----------|---------|----------|
    | `F9 XX` | `pintaTile(XX, ...)` | Paint base tile #XX |
    | `FC` | `pushTilePos()` | Save current drawing position |
    | `FB` | `popTilePos()` | Restore saved position |
    | `F5` | `incTilePosX()` | Move cursor right |
    | `F6` | `incTilePosY()` | Move cursor down |
    | `F4` | `decTilePosY()` | Move cursor up |
    | `F3` | `decTilePosX()` | Move cursor left |
    | `FD...FA` | `while (param2 > 0)` | Loop structure |
    | `FE...FA` | `while (param1 > 0)` | Nested loop |
    | `E9` | `FlipX()` | Horizontal flip |
    | `EA XXXX` | `ChangePC(XXXX)` | Jump to different script |
    | `FF` | End | End of script |

    **Memory Efficiency:** Instead of storing 96 large pre-rendered blocks as bitmaps, the game stores only 256 small tiles (8KB) plus 96 tiny scripts (10-50 bytes each). The scripts can create walls of any length, floors of any size, columns of any height, and complex arches - all by cleverly composing the same 256 base tiles.

    **Complete List of 96 Building Blocks:**

    | ID | Hex | Description |
    |----|-----|-------------|
    | 0x00 | 0x00 | (null/empty block) |
    | 0x01 | 0x02 | Thin black brick parallel to y |
    | 0x02 | 0x04 | Thin red brick parallel to x |
    | 0x03 | 0x06 | Thick black brick parallel to y |
    | 0x04 | 0x08 | Thick red brick parallel to x |
    | 0x05 | 0x0A | Small windows block, slightly rounded and black parallel to y axis |
    | 0x06 | 0x0C | Small windows block, slightly rounded and red parallel to x axis |
    | 0x07 | 0x0E | Red railing parallel to y axis |
    | 0x08 | 0x10 | Red railing parallel to x axis |
    | 0x09 | 0x12 | White column parallel to y axis |
    | 0x0A | 0x14 | White column parallel to x axis |
    | 0x0B | 0x16 | Stairs with black brick on the edge parallel to y axis |
    | 0x0C | 0x18 | Stairs with red brick on the edge parallel to x axis |
    | 0x0D | 0x1A | Floor of thick blue tiles |
    | 0x0E | 0x1C | Floor of red and blue tiles forming a checkerboard effect |
    | 0x0F | 0x1E | Floor of blue tiles |
    | 0x10 | 0x20 | Floor of yellow tiles |
    | 0x11 | 0x22 | Block of arches passing through pairs of columns parallel to y axis |
    | 0x12 | 0x24 | Block of arches passing through pairs of columns parallel to x axis |
    | 0x13 | 0x26 | Block of arches with columns parallel to y axis |
    | 0x14 | 0x28 | Block of arches with columns parallel to x axis |
    | 0x15 | 0x2A | Double yellow rivet on the brick parallel to y axis |
    | 0x16 | 0x2C | Double yellow rivet on the brick parallel to x axis |
    | 0x17 | 0x2E | Solid block of thin brick parallel to x axis |
    | 0x18 | 0x30 | Solid block of thin brick parallel to y axis |
    | 0x19 | 0x32 | White table parallel to x axis |
    | 0x1A | 0x34 | White table parallel to y axis |
    | 0x1B | 0x36 | Small discharge pillar placed next to a wall on x axis |
    | 0x1C | 0x38 | Red and black terrain area |
    | 0x1D | 0x3A | Bookshelves parallel to y axis |
    | 0x1E | 0x3C | Bed |
    | 0x1F | 0x3E | Large blue and yellow windows parallel to y axis |
    | 0x20 | 0x40 | Large blue and yellow windows parallel to x axis |
    | 0x21 | 0x42 | Candelabras with 2 candles parallel to x axis |
    | 0x22 | 0x44 | (no-op/empty) |
    | 0x23 | 0x46 | Yellow rivet with support parallel to y axis |
    | 0x24 | 0x48 | Red railing corner |
    | 0x25 | 0x4A | Yellow rivet with support parallel to x axis |
    | 0x26 | 0x4C | Red railing corner (variant 2) |
    | 0x27 | 0x4E | Rounded passage hole with thin red and black bricks parallel to x axis |
    | 0x28 | 0x50 | Small windows block, rectangular and black parallel to y axis |
    | 0x29 | 0x52 | Small windows block, rectangular and red parallel to x axis |
    | 0x2A | 0x54 | 1 bottle and a jar |
    | 0x2B | 0x56 | (no-op/empty) |
    | 0x2C | 0x58 | Stairs with black brick on the edge parallel to y axis (variant 2) |
    | 0x2D | 0x5A | Stairs with red brick on the edge parallel to x axis (variant 2) |
    | 0x2E | 0x5C | Rectangular passage hole with thin black bricks parallel to y axis |
    | 0x2F | 0x5E | Rectangular passage hole with thin red bricks parallel to x axis |
    | 0x30 | 0x60 | Thin black and red brick corner |
    | 0x31 | 0x62 | Thick black and red brick corner |
    | 0x32 | 0x64 | Rounded passage hole with thin black and red bricks parallel to y axis |
    | 0x33 | 0x66 | Yellow rivet corner with support |
    | 0x34 | 0x68 | Yellow rivet corner |
    | 0x35 | 0x6A | (no-op/empty) |
    | 0x36 | 0x6C | Red railing corner (variant 3) |
    | 0x37 | 0x6E | Thin red and black brick pyramid |
    | 0x38 | 0x70 | Solid block of thin red and black brick, with yellow and black tiles on top, parallel to y axis |
    | 0x39 | 0x72 | Solid block of thin red and black brick, with yellow and black tiles on top, parallel to x axis |
    | 0x3A | 0x74 | Solid block of thin red and black brick, with yellow and black tiles on top, that grows upwards |
    | 0x3B | 0x76 | Candelabras with 2 candles parallel to x axis (variant 2) |
    | 0x3C | 0x78 | Candelabras with 2 candles parallel to y axis |
    | 0x3D | 0x7A | Candelabras with wall support and 2 candles parallel to y axis |
    | 0x3E | 0x7C | Small discharge pillar placed next to a wall on y axis |
    | 0x3F | 0x7E | Thin black and red brick corner (variant 2) |
    | 0x40 | 0x80 | Thin black and red brick corner (variant 3) |
    | 0x41 | 0x82 | Thin red brick forming a right triangle parallel to x axis |
    | 0x42 | 0x84 | Thin black brick forming a right triangle parallel to y axis |
    | 0x43 | 0x86 | Rounded passage hole with thin red and black bricks parallel to y axis, with thick pillars between holes |
    | 0x44 | 0x88 | Rounded passage hole with thin red and black bricks parallel to x axis, with thick pillars between holes |
    | 0x45 | 0x8A | Bench to sit on parallel to x axis |
    | 0x46 | 0x8C | Bench to sit on parallel to y axis |
    | 0x47 | 0x8E | Very low thin black and red brick corner |
    | 0x48 | 0x90 | Very low thick black and red brick corner |
    | 0x49 | 0x92 | Flat corner delimited with black line and blue floor |
    | 0x4A | 0x94 | Work table |
    | 0x4B | 0x96 | Plates |
    | 0x4C | 0x98 | Bottles with handles |
    | 0x4D | 0x9A | Cauldron |
    | 0x4E | 0x9C | Flat corner delimited with black line and yellow floor |
    | 0x4F | 0x9E | Solid block of thin red and black brick, with blue tiles on top, parallel to y axis |
    | 0x50 | 0xA0 | Solid block of thin red and black brick, with blue top, parallel to y axis |
    | 0x51 | 0xA2 | Solid block of thin red and black brick, with blue tiles on top, parallel to x axis |
    | 0x52 | 0xA4 | Solid block of thin red and black brick, with blue top, parallel to x axis |
    | 0x53 | 0xA6 | Solid block of thin red and black brick, with blue tiles on top and stair-stepped, parallel to x axis |
    | 0x54 | 0xA8 | Solid block of thin red and black brick, with blue top and stair-stepped, parallel to x axis |
    | 0x55 | 0xAA | Solid block of thin red and black brick, with blue tiles on top and stair-stepped, parallel to y axis |
    | 0x56 | 0xAC | Solid block of thin red and black brick, with blue top and stair-stepped, parallel to y axis |
    | 0x57 | 0xAE | Human skulls |
    | 0x58 | 0xB0 | Skeleton remains |
    | 0x59 | 0xB2 | Monster face with horns |
    | 0x5A | 0xB4 | Support with cross |
    | 0x5B | 0xB6 | Large cross |
    | 0x5C | 0xB8 | Library books parallel to x axis |
    | 0x5D | 0xBA | Library books parallel to y axis |
    | 0x5E | 0xBC | Top of a wall with small slightly rounded and black window parallel to y axis |
    | 0x5F | 0xBE | Top of a wall with small slightly rounded and red window parallel to x axis |

3.  **Block Interpreter (`1BBC`, `2018h`):** When a room is drawn, a high-level interpreter reads these scripts. The scripts contain a sequence of commands that tell the engine *how* to combine the basic tiles to form a larger structure. Commands include operations like `pintaTile` (paint tile), `incTilePosX` (increment X position), and looping constructs. This scripted approach allows for the creation of large, complex, and varied structures (like walls, arches, and furniture) from a relatively small set of reusable tiles, saving a significant amount of memory.
4.  **Scene Composition (Tile Buffer):** The process of building a scene does not happen directly on the screen. Instead, the results are drawn into an off-screen **tile buffer** (`8D80h`). Each entry in this buffer stores not just the graphic number for the foreground and background tile, but also their **depth information** (as described in `mapamemoria.txt`). When the Block Interpreter "paints" a tile, it first checks the depth of the existing tile in the buffer. The new tile is only drawn if it is in front of the old one. This acts as a Z-buffer, ensuring that objects correctly occlude each other.
5.  **Final Render (`4EB2h`):** Once the entire scene is fully composed in the tile buffer, a final routine traverses this buffer and copies the final tile graphics to the video memory, making the scene visible to the player.

#### Character/Object Graphics (Sprites)

Dynamic elements like characters and objects are handled separately as sprites.

1.  **Sprite Data:** Each sprite's properties are defined in a data structure (starting at `2E17h`), which includes its screen position, width, height, current visibility status, and a pointer to its graphical bitmap data.
2.  **Drawing Process:** In each frame of the main game loop, the engine processes the list of active sprites.
3.  **Depth Sorting (Painter's Algorithm):** The sprite drawing routine (`4914h`) first sorts all active sprites based on their depth (primarily their Y-coordinate). This is a classic painter's algorithm, ensuring that objects further "down" the screen are drawn on top of those further "up."
4.  **Rendering:** After sorting, the sprites are drawn one by one, from back to front. The raw bitmap data for the sprite is copied to the screen. Transparency is handled using AND/OR color masking operations, for which the tables at `9D00h` are generated during initialization.

#### Camera Perspective and Rotation

The game does not have a true 3D model of the abbey that can be freely rotated. Instead, it has **four pre-defined, 90-degree-rotated isometric views**.

- **Coordinate Transformation:** The engine contains four distinct routines for coordinate transformation, one for each camera angle (starting at `2485h`). When the camera view changes, the game selects the appropriate routine to convert the world coordinates of characters and objects into the correct screen coordinates for that specific perspective.
- **Asset-Based Views:** Many of the game's graphical assets (the tiles and blocks) are likely pre-drawn for each of the four possible orientations. The block interpreter scripts may select different tiles or use different logic depending on the current camera angle (`2481h`).

Therefore, you **can** rotate the perspective in 90-degree steps, as this is a core feature of the game's engine. However, you **cannot** implement free rotation or arbitrary camera angles without fundamentally changing the engine and creating entirely new graphical assets for every possible angle. The "3D" effect is a clever illusion built upon a highly optimized 2D tile and sprite system.

#### Rendering Architecture and Modding Potential

The engine's architecture provides interesting possibilities for analysis and modification.

- **Block Perspectives:** It is unlikely that every block has four complete, unique sets of pre-rendered bitmaps. It's more probable that the engine uses a combination of techniques to achieve the four perspectives:
    - **Symmetrical Tiles:** Simple, symmetrical tiles can be reused across different perspectives without any changes.
    - **Programmatic Flips:** The engine can horizontally flip tiles (`flipx` routine) to create mirrored versions on the fly.
    - **Conditional Logic:** The block-building scripts likely contain conditional logic to select different tiles or apply different transformations based on the current camera orientation.
    - **Unique Assets:** For complex, asymmetrical parts of a structure, unique tiles pre-drawn for that specific perspective are used.
    
    In essence, the engine has a toolbox of graphical components and uses programmatic logic to assemble them correctly for the chosen viewpoint, which is a highly memory-efficient strategy.

- **Tile Extraction Tool:** A Python script (`extract_tiles.py`) has been created to extract and visualize all 256 base tiles directly from the disassembled .asm file with authentic CPC colors matched from actual game screenshots. The script:
    1.  Parses the .asm file to extract tile bitmap data from addresses `8300h-A2FFh`
    2.  Uses 2 accurate color palettes matched from CPC gameplay screenshots
    3.  Decodes the Amstrad CPC Mode 1 pixel format (4 pixels per byte, 2 bits per pixel)
    4.  Maps CPC hardware color codes to accurate RGB values
    5.  Generates tiles with correct colors for day and night palettes
    6.  Creates both individual tile images and complete sprite sheets

    **To use:** Simply run `python3 extract_tiles.py` in the project directory.

    **Output:**
    - `tiles/palette_day/` - 256 tiles with day palette
    - `tiles/palette_night/` - 256 tiles with night palette
    - `abbey_tiles_spritesheet_day.png` - Complete sprite sheet for day
    - `abbey_tiles_spritesheet_night.png` - Complete sprite sheet for night

    **Day Palette (daytime scenes):**
    - Pen 0: Black (outlines, text)
    - Pen 1: Bright Cyan (floor/background)
    - Pen 2: Yellow/Orange (walls, bricks)
    - Pen 3: Bright White (highlights)

    **Night Palette (nighttime scenes):**
    - Pen 0: Black (outlines, text)
    - Pen 1: Bright Blue (floor/background)
    - Pen 2: Bright Magenta (walls, structures)
    - Pen 3: Pastel Magenta (highlights)

- **Python Block Renderer:** Creating a script to render the complete building blocks is **feasible but complex**. The main challenge would be to re-implement the game's custom **Block Interpreter**. Such a script would need to:
    1.  Parse the material table at address `156Dh` from the .asm file to locate the 96 building block scripts
    2.  Extract the raw tile bitmaps (already handled by `extract_tiles.py`)
    3.  Implement a parser for the material scripts' custom bytecode (the drawing commands like `pintaTile`, `pushTilePos`, loops, etc.)
    4.  Use a graphics library like `Pillow` or `Pygame` to execute the parsed commands and render each complete building block to an image

    This would be a significant reverse-engineering project but would offer unparalleled insight into the game's construction and enable full visualization of all architectural elements.

- **Rotating a Room:** This is surprisingly straightforward. The entire rendering pipeline is controlled by a single variable:
    1.  **Modify Camera State:** Change the byte at memory address `2481h` to the desired orientation (0, 1, 2, or 3).
    2.  **Trigger Redraw:** Set the "redraw flag" at memory address `2DB8h` to a non-zero value.
    
    The next time the main game loop runs, it will see the redraw flag, call the screen generation routine, and use the *new* orientation to perform all coordinate calculations, re-running the block interpreter scripts and re-rendering the entire scene from the new 90-degree rotated perspective.

### 3.2. AI and Pathfinding: Navigation and Collision

The non-player characters (NPCs) exhibit complex behaviors driven by a state-based AI and a sophisticated pathfinding system that allows them to navigate the pseudo-3D world.

- **Character Logic (`06FDh` onwards in `chunk_ab`):** Each major character (Malaquias, the Abbot, Berengario, etc.) has a dedicated high-level logic routine. These routines determine the character's goals based on the current day, time, and game events (e.g., "go to the church," "follow Guillermo").

- **Movement Generation (`073Ch` in `chunk_ab`):** Based on its current goal, the AI generates a sequence of movement commands (e.g., turn left, move forward) that are stored in a buffer for the character to execute.

#### The Height Buffer: The Key to 3D Illusion

The core of the game's navigation and collision system is the **Height Buffer** (`2D8Ah`). This is not a graphical buffer, but a 24x24 grid in memory that represents the physical topology of the current screen. Each byte in this grid stores the height of the corresponding tile.

- A floor tile might have a height of `0x01`.
- A tabletop could be `0x05`.
- A wall would be marked with a very high or impassable value.

This data structure provides the "virtual" third dimension, allowing the 2D game engine to make decisions based on 3D spatial relationships.

#### Collision Detection as Height-Checking

The game does not perform geometric collision detection. Instead, "collision" is simply an invalid move based on the height buffer. This is how sprites "work around" objects:

- When a character attempts to move, the engine calls a validation routine (like the one at `27B4h`).
- This routine reads the height of the character's current tile and the target tile from the height buffer.
- If the height difference is too large (e.g., walking into a wall or off a cliff), the move is rejected. A small, permissible difference (like `+1`) allows the character to walk up a step.
- An object is therefore just a set of impassable tiles in the height buffer, which characters' pathfinding will naturally avoid.

#### Two-Tiered Pathfinding

The game uses a clever, two-level pathfinding system to navigate the abbey.

1.  **Inter-Screen Pathfinding (High-Level):** When a character needs to go to a different room, the high-level pathfinder at `4826h` is used. It consults a **room connection graph** (defined at `05CDh`) to find the shortest sequence of rooms to traverse. Its output is a high-level goal, such as "go to the left doorway."

2.  **Intra-Screen Pathfinding (Low-Level):** Once the AI has a local target (like a doorway), the intra-screen pathfinder at `4429h` takes over. This is a search algorithm (akin to A* or Breadth-First Search) that operates directly on the 24x24 **height buffer**. It finds the shortest valid path from the character's current tile to the target tile, treating the buffer as a grid where the cost of moving between nodes is based on height differences. To avoid getting stuck in loops, it temporarily marks visited nodes by setting bit 7 of their value in the height buffer. The result is a precise sequence of steps for the character to follow.

### 3.3. The Event Scripting System: A Deeper Look

A significant portion of the game's high-level logic is driven by a custom, data-driven scripting system. It uses the Z80's `RST` (Restart) instructions to create a mini-programming language interpreter, which acts as the "brain" for game events and character AI.

#### Core Components

1.  **The "Script" (Bytecode):** The logic is not written in assembly but as a sequence of bytes (bytecode) embedded in the data sections of the code. This bytecode represents conditions and actions. It is composed of:
    *   **Variable Tokens:** Single bytes (from `0x80` onwards) that act as stand-ins for game state variables. A lookup table at `3D1D` translates these tokens into the actual memory addresses of the variables (e.g., token `0x88` maps to address `2D81h`, which stores the "time of day").
    *   **Immediate Values:** Bytes with a value less than `0x80` are treated as literal numbers in expressions.
    *   **Operators:** Specific bytes represent operations like `=` (`3Dh`), `>` (`3Eh`), `+` (`2Bh`), and `&` (`26h`).

2.  **The Interpreter (`RST 08h` at `3DD1h`):** This routine is the "EVALUATOR". It parses a script that follows it in memory, fetches the required values (either literal numbers or from game variables via the token table), performs the specified comparisons or calculations, and sets the Z80's processor flags (like the Zero Flag) based on the final `true`/`false` result.

3.  **The Assignment Handler (`RST 10h` at `3DAFh`):** This routine is the "ASSIGNER". It executes an action. It takes a destination variable token and an expression script as arguments. It calls the `RST 08h` logic to evaluate the expression and then stores the result in the destination variable. This is how the script system changes the game state (e.g., `SET [Malaquias_Goal] = [Go_To_Church]`).

#### How Triggers Work: An Example

Events are structured as **IF-THEN** statements using a distinct `EVALUATE -> JUMP -> ACT` pattern. Let's examine a line from Malaquias's AI at `575Eh`:

```assembly
; Is it night OR compline?
rst 08h
db 88h, 00h, 3Dh, 88h, 06h, 3Dh, 2Ah ; Script: ([time_of_day] == 0) OR ([time_of_day] == 6)
jp nz, 578Dh ; IF the condition is true, THEN jump to the action
```

This is how it works:
1.  **Evaluation:** The `RST 08h` instruction is called. The interpreter then reads the bytecode that follows it: `(VAR_TIME_OF_DAY), (VALUE_0), (OP_EQUALS), (VAR_TIME_OF_DAY), (VALUE_6), (OP_EQUALS), (OP_OR)`. It evaluates this expression and sets the Z80's Zero Flag based on the boolean result.
2.  **The Trigger:** The next instruction, `jp nz, 578Dh` (Jump if Not Zero), acts on the result. If the expression was true, the Zero Flag is not set, and the jump is taken.
3.  **The Action:** The code at `578Dh` is the "THEN" part of the statement. It contains another script, likely using `RST 10h`, to assign a new objective to Malaquias, such as setting his goal to "go to his cell."

This elegant, data-driven system allows for incredibly complex and varied game logic without requiring unique assembly code for every single event, forming the backbone of the game's interactivity.

#### Scripting Language Reference

**Operators**

The interpreter recognizes the following bytecode operators within a script:

| Bytecode | Character | Operation         |
| :------- | :-------: | :---------------- |
| `0x3D`   |    `=`    | Equality check    |
| `0x3E`   |    `>`    | Greater than      |
| `0x3C`   |    `<`    | Less than         |
| `0x2A`   |    `*`    | Logical OR        |
| `0x26`   |    `&`    | Logical AND       |
| `0x2B`   |    `+`    | Addition          |
| `0x2D`   |    `-`    | Subtraction       |
| `0x84`   |    n/a    | Negation (unary)  |

**Variables**

This is a partial list of the game's state variables that can be accessed by the scripting system via their tokens. The full table is defined at `3D1D`.

| Token | Address | Description                                 |
| :---- | :------ | :------------------------------------------ |
| `0x80`| `3038h` | Guillermo's X position                      |
| `0x81`| `3039h` | Guillermo's Y position                      |
| `0x82`| `303Ah` | Guillermo's height                          |
| `0x83`| `3047h` | Adso's X position                           |
| `0x84`| `3075h` | Berengario's X position                     |
| `0x85`| `3049h` | Adso's height                               |
| `0x86`| `3CAAh` | Where Malaquias is going                    |
| `0x87`| `3CA8h` | Where Malaquias has arrived                 |
| `0x88`| `2D81h` | Time of day                                 |
| `0x89`| `2DA1h` | Indicates if a phrase is being played       |
| `0x8A`| `3CC6h` | Where the Abbot has arrived                 |
| `0x8B`| `3CC8h` | Where the Abbot is going                    |
| `0x8C`| `3CC7h` | Abbot's state                               |
| `0x8D`| `2D80h` | Day number                                  |
| `0x8E`| `3CA9h` | Malaquias' state                            |
| `0x8F`| `3C9Eh` | Counter for Guillermo in scriptorium        |
| `0x90`| `3CE9h` | Where Berengario is going                   |
| `0x91`| `3CE7h` | Where Berengario has arrived                |
| `0x92`| `3CE8h` | Berengario's state                          |
| `0x93`| `3D01h` | Where Severino is going                     |
| `0x94`| `3CFFh` | Where Severino has arrived                  |
| `0x95`| `3D00h` | Severino's state                            |
| `0x96`| `3D13h` | Where Adso is going                         |
| `0x97`| `3D11h` | Where Adso has arrived                      |
| `0x98`| `3D12h` | Adso's state                                |
| `0x99`| `3C98h` | General purpose counter                     |
| `0x9A`| `2DBDh` | Current screen number                       |
| `0x9B`| `3C9Ah` | Flag to advance time of day                 |
| `0x9C`| `3C97h` | Flag indicating if Guillermo has died       |
| `0x9D`| `3074h` | X pos of Berengario/Bernardo/Jorge          |
| `0x9E`| `3CA6h` | Mask for which doors are being checked      |
| `0x9F`| `2FFEh` | State of door 1 to the wing                 |
| `0xA0`| `3003h` | State of door 2 to the wing                 |
| `0xA1`| `3C99h` | Guillermo's response timer for sleep question|
| `0xA2`| `3F0Eh` | The phrase to be shown by the sub-system    |
| `0xA3`| `3C96h` | Flag for monks in place for mass/meal       |
| `0xA4`| `2DEFh` | Guillermo's objects (inventory)             |
| `0xA5`| `3C94h` | Flag that Berengario warned the Abbot       |
| `0xA6`| `2E04h` | The Abbot's objects (inventory)             |
| `0xA7`| `3C92h` | Character to follow if player is idle       |
| `0xA8`| `2E0Bh` | Berengario's objects (inventory)            |
| ...   | ...     | *(table continues with more variables)*     |

#### Decompiling to Pseudo-code

It is entirely feasible to write a Python script to act as a "decompiler" for this scripting language. Such a tool would read the `.asm` source file and translate the bytecode into human-readable pseudo-code, which would be invaluable for porting the game logic to a modern language.

The process would be:
1.  **Parse Assembly:** Read the `.asm` file line by line.
2.  **Identify Script Blocks:** Find all instances of the `rst 08h` and `rst 10h` instructions.
3.  **Extract Bytecode:** For each `rst` instruction, parse the subsequent `db` (define byte) lines to collect the sequence of hexadecimal values that form the script.
4.  **Decompile Logic:** Process the bytecode sequence. Using lookup dictionaries for operators and variable tokens (as detailed above), substitute the raw hex values with their meaningful representations (e.g., replace `88h` with `[time_of_day]` and `3Dh` with `==`).
5.  **Format Output:** Assemble the translated tokens into a readable string. For example, the bytecode `db 88h, 00h, 3Dh` would become the pseudo-code string `EVALUATE: [time_of_day] == 0`.

## 4. Character & Object Collision and Rendering

### 4.1. Sprite-to-Sprite Collision

The game unifies all collision detection through the **Height Buffer**. There isn't a separate system for checking sprite-against-sprite collisions. Instead, characters are treated as temporary parts of the environment.

-   **Marking the Grid:** Before the game's pathfinding or movement logic runs, it "stamps" the tiles that each character occupies in the height buffer with a special value indicating a character's presence (`28EFh`).
-   **Pathfinding around Sprites:** When another character's pathfinding algorithm (`4429h`) runs, it sees these "stamped" tiles as temporary obstacles with an impassable height. The algorithm will automatically route the character around the occupied space, treating it just like a wall or a table.
-   **Dynamic Obstacles:** After a character moves, their old position in the height buffer is cleared (`28EFh` called with `c=0`), making those tiles walkable again. This elegant system integrates dynamic sprite collision seamlessly into the static world collision system.

### 4.2. Z-Axis Movement and Rendering (Stairs)

The illusion of climbing stairs is handled through a combination of sprite positioning and a change in the character's logical "footprint."

-   **Screen Position:** The game's isometric projection means that a character's vertical position on the screen (its Y-coordinate) is directly tied to their perceived height. As a character's internal Z-coordinate increases (e.g., by walking up a step), their sprite is simply drawn higher up on the screen (a lower screen Y-coordinate), creating the illusion of vertical movement.
-   **Changing Footprint:** The most critical part is how the character's interaction with the world changes. The character data structure (`3036h`) contains a flag (`bit 7` of byte `0x05`) that indicates whether the character occupies a 2x2 area of tiles (normal movement) or a **1x1 area**. The comments explicitly state: *"normally the character occupies four positions, but on the stairs it occupies only one."*
-   When a character starts climbing stairs, the engine sets this flag. Their logical footprint shrinks, allowing them to navigate the narrow staircase path in the height buffer. Their `z` value (height) is incremented one "step" at a time, and the rendering engine automatically places their sprite higher on the screen, creating a convincing climbing animation. The flag `bit 4` of that same byte is used to indicate if the character is descending.

### 4.3. Object & Door Interaction (`0D13h` onwards in `chunk_ac`, `chunk_ad`)

A set of routines handles the logic for picking up, dropping, and using objects, as well as opening and closing doors. Door permissions for each character are stored at `2DD9h`.

### 4.4. Screen/Room Data Management

The game's abbey is divided into discrete screens (rooms), each defined by a compact data structure that describes how to construct the 3D environment for that location.

#### Screen Data Storage and Organization

All screen definitions are stored sequentially in **`abadia8.bin`** (ROM bank 7) at addresses **`0x0000-0x2237`**. When the game needs to access screen data, it maps this ROM bank to memory address `0x4000` using the gate array command `0x7FC7`.

**Key Memory Locations:**

| Address       | Purpose                                                     |
|---------------|-------------------------------------------------------------|
| `0x2DBD`      | Current screen number (which room the camera is showing)    |
| `0x156A-0x156B` | Pointer to current screen's data in memory              |
| `0x156C`      | Illumination flag (0 = illuminated room)                   |
| `0x2481`      | Camera orientation (0-3, representing 90° rotations)       |
| `0x2D8A-0x2D8B` | Pointer to height buffer for current screen (24x24 grid)|

#### Screen Loading Routine (`2D00h`)

The routine at `0x2D00` is responsible for locating and loading a specific screen's data:

```assembly
2D00: ld ($2DBD),a    ; Save current screen number
2D03: ld hl,$4000    ; Start at beginning of screen data in abadia8
2D06: and a
2D07: jr z,$2D1E     ; If screen 0, use address as-is
; Otherwise, iterate through screen data to find the requested screen
2D09: di              ; Disable interrupts
2D0A: ld bc,$7FC7    ; Load abadia8.bin into memory at 0x4000
2D0D: out (c),c
2D0F: ld b,a         ; b = target screen number
; Loop through screens by adding each screen's length until we reach the target
2D10: ld a,(hl)      ; Read screen length byte
2D11: add a,l        ; Add length to pointer
2D12: ld l,a
2D13: adc a,h
2D14: sub l
2D15: ld h,a         ; hl now points to next screen
2D16: djnz $2D10     ; Repeat until we've skipped (screen_number) screens
2D18: ld bc,$7FC0    ; Restore default bank configuration
2D1B: out (c),c
2D1D: ei              ; Re-enable interrupts
2D1E: ld ($156A),hl  ; Save pointer to screen data
```

#### Screen Data Format

Each screen is stored as a variable-length sequence of **block placement commands**. The structure is:

1. **Length byte** (offset 0): Total size of this screen's data in bytes
2. **Block entries** (2 bytes each): A series of commands describing which blocks to place and where
   - Byte 0: Block type index (references material table at `0x156D`)
   - Byte 1: Position encoding (contains both X and Y tile coordinates)
3. **Terminator**: The sequence ends with `0xFF`

The screen rendering routine at `1A0A` reads these entries:

```assembly
1A0A: ld a,(ix+$00)   ; Read block type byte
1A0D: cp $FF          ; Check for end-of-screen marker
1A0F: ret z           ; Return if done
1A10: and $FE         ; Clear bit 0 for table indexing
1A12: ld hl,$156D    ; Point to materials/blocks table
; ...lookup block characteristics...
1A21: ld a,(ix+$01)  ; Read position byte
1A24: ld c,a
1A25: and $1F        ; Extract X coordinate (bits 0-4)
1A27: ld l,a
; ...extract Y coordinate from upper bits...
; ...then call block interpreter to draw this block...
```

Each block type in the table at `0x156D` points to a drawing script (as described in section 3.1), which contains the instructions for composing that architectural element from basic tiles.

#### Height Data Companion Structure

In addition to visual data, each screen has corresponding **height/collision data** stored in `abadia7.bin`:

- **Floor 0**: `0x0A00-0x0EFF` (ground floor height maps)
- **Floor 1**: `0x0F00-0x107F` (first floor height maps)
- **Floor 2**: `0x1080-0x1414` (second floor height maps)

The routine at `2D22` fills the 24x24 height buffer (`0x2D8A`) with the appropriate floor data based on the character's location, which is then used for pathfinding and collision detection.

## 5. Other Notable Systems

- **Sound Engine (`0F96h` onwards in `chunk_ad`, `chunk_ae`):** The game uses the AY-3-8910 sound chip. The code includes a music player that can handle multiple channels, envelopes, and noise generation. The music data itself, including the notes for the parchment melodies, is stored in tables (e.g., `804Fh`).
- **Save/Load System (`0489h` in `chunk_aa`):** The game includes a feature to save the game state to disk, triggered by `CTRL+F-key`. It copies the relevant memory sections containing the game state directly to disk tracks.

## 6. Code Structure Map

This map provides a sequential, high-level overview of the main components of the game's code.

| Address Range | Component                               | Summary                                                                       |
|---------------|-----------------------------------------|-------------------------------------------------------------------------------|
| `0400h-058Fh` | Game Start & Save/Load System           | Game entry point and low-level routines for the save/load game feature.         |
| `0590h-06FCh` | Pathfinding Data & Tables               | Contains room connection tables and other data for character navigation.        |
| `06FDh-0989h` | Character AI Logic                      | High-level "thinking" routines for each NPC (Malaquias, Adso, etc.).           |
| `098Ah-0D12h` | Pathfinding Engine                      | Core algorithms for intra-screen and inter-screen pathfinding.                |
| `0D13h-0F95h` | Object and Door Logic                   | Manages interaction with doors and collectible objects.                         |
| `0F96h-1569h` | Sound & Music Engine                    | Controls the AY-3-8910 sound chip for music and sound effects.                  |
| `156Ah-2499h` | 3D Engine & Graphics Rendering          | Core of the isometric engine; includes the block interpreter and rendering logic. |
| `249Ah-2673h` | Main Loop & High-Level Game Flow        | Contains the main game initialization, the main loop, and sprite drawing logic. |
| `2674h-2782h` | Sprite, Light & Screen Utilities        | Routines for drawing sprites, handling the lamp effect, and screen clears.      |
| `2783h-2D47h` | Character Movement & Collision          | Low-level routines for character movement, animation, and collision detection.  |
| `2D48h-359Ch` | Interrupt Service & Input Handling      | The main interrupt routine, keyboard processing, and save/load/pause logic.     |
| `359Dh-38E1h` | Game State & Dialogue System            | More game logic, state variables, and routines for displaying dialogue text.    |
| `3C85h-659Ch` | High-Level Logic & Event Scripts        | Contains most game state variables and the data-driven scripts for game events. |
| `659Dh-7FFFh` | Manuscript/Scroll Presentation          | Routines dedicated to displaying the introductory and final text scrolls.       |
| `8000h-`      | Game Data                               | ROM data for music, graphics, character/object properties, etc.               |


## 7. Conclusion

The code of "La Abadía del Crimen" reveals a remarkably advanced game for its time. The developers created a sophisticated set of integrated systems, including a flexible 3D engine, a data-driven scripting system for game logic, and a multi-layered AI for character behavior. This analysis provides a starting point for a deeper dive into any of these specific systems.