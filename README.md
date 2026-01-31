# Abadía del Crimen - Disassembly & Remake Project

This repository serves as a comprehensive preservation and reverse-engineering project for the Amstrad CPC version of "La Abadía del Crimen" (The Abbey of Crime). It contains the original disassembly, extracted assets, preservation artifacts, and modern tooling/implementations in Python and JavaScript.

## 📂 Project Structure

The repository is organized into three main components:

### 1. `cpc_disassembly/` - The Original Source
This directory contains the historical core of the project:
*   **`original_spanish_disassembly/`**: The original Spanish assembly source code and memory maps.
*   **`translated_english_disassembly/`**: English translations of the assembly code (`0 - abadia_del_crimen...asm`) and memory maps.

### 2. `python/` - Engine & Tools
A modern Python-based environment for analyzing the game data, extracting assets, and implementing a game engine/interpreter.

*   **`src/engine/`**: Core rendering and logic.
    *   `interpreter.py`: Bytecode interpreter for the game's custom scripting language.
    *   `opcodes.py`: Definitions of the game's custom opcodes.
    *   `dsl.py`: Domain Specific Language tools for the game scripts.
    *   `tiles.py`, `buffer.py`, `canvas.py`: Graphics rendering subsystems and CPC palette handling (`palette.py`).
*   **`src/game/`**: A Python implementation of the game logic.
    *   `main.py`: Main game loop.
    *   `player.py`: Logic for the player character (Guillermo).
    *   `objects.py`, `input.py`: Game object management and input handling.
*   **`src/codegen/`**: Scripts to extract data from the binary files (`cpc_disassembly`) and generate Python modules.
    *   `scripts.py`: Extracts and decompiles the game logic scripts.
    *   `memory.py`: Memory layout analysis and reconstruction.
    *   `blocks.py`, `rooms.py`, `tiles.py`, `sprites.py`: Asset extractors.
*   **`src/tools/`**: Visualization and debugging utilities.
    *   `room_viewer.py`: Render game rooms to images.
    *   `block_viewer.py`: Visualize individual game blocks.
    *   `check_memory.py`: Utility for verifying memory structures.

### 3. `java_script/` - Visualization Tools
Node.js scripts focused on visual rendering and tracing.
*   `src/generate_rooms_with_trace.js`: Generates visual representations of game rooms.
*   `src/trace_blocks.js`: Traces and visualizes the isometric blocks.
*   `src/generate_room_names.js`: Helper to process room naming.
*   `resources/`: Contains generated output images (`generated_rooms/`, `generated_blocks/`).

---

## 🚀 Setup & Usage

### Python Environment

The Python project uses [uv](https://docs.astral.sh/uv/) for dependency management.

1.  **Navigate to the python directory:**
    ```bash
    cd python
    ```

2.  **Install/Sync dependencies:**
    ```bash
    # Install uv if needed: curl -LsSf https://astral.sh/uv/install.sh | sh
    uv sync
    ```

3.  **Run Tools:**
    ```bash
    # Run the room viewer
    uv run python -m tools.room_viewer

    # Run the block viewer
    uv run python -m tools.block_viewer
    ```

4.  **Development:**
    *   **Linting**: `uv run ruff check src/`
    *   **Formatting**: `uv run ruff format src/`
    *   **Tests**: `uv run pytest`

### JavaScript Environment

1.  **Navigate to the java_script directory:**
    ```bash
    cd java_script
    ```

2.  **Install dependencies:**
    ```bash
    npm install
    ```

3.  **Run Scripts:**
    ```bash
    node src/generate_rooms_with_trace.js
    ```

---

## 📚 Documentation

The `cpc_disassembly/translated_english_disassembly/` folder contains text files detailing the internal systems:
*   **Memory Maps**: `1 - game_debugger_memory_map.txt`, `4 - game_memory_map.txt`
*   **Disk Structure**: `3 - game_disk_content_map.txt`
*   **File Maps**: `5 - game_file_rom_maps.txt`

The Python code in `python/src/engine` and `python/src/codegen` also serves as live documentation of the game's data formats (sprites, tiles, room geometry).