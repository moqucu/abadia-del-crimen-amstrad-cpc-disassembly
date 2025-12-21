# Abadía del Crimen - Disassembly & Analysis Tools

This project hosts the disassembly of the Amstrad CPC version of "La Abadía del Crimen" along with Python-based analysis and asset extraction tools.

## Project Structure

### 🛠 Source Code (`src/abadia/`)
Python tools for reverse engineering and asset extraction:
- **`extract_sprites.py` / `extract_sprites_corrected.py`**: Tools for extracting game sprites.
- **`extract_tiles.py`**: Extractor for tile graphics.
- **`extract_block_scripts.py`**: Extracts scripting logic for game blocks.
- **`abbey_architect.py` & `abbey_blocks_library.py`**: Logic for reconstructing game rooms and screens.
- **`decompile_scripts.py`**: Decompiler for the game's custom scripting language.
- **`visualize_palette.py`**: Utility to visualize the Amstrad CPC color palette.

### 📚 Documentation (`docs/`)
Comprehensive analysis of the game's internal systems:
- **`game_code_analysis.md`**: The central hub and high-level overview of the codebase.
- **`MEMORY_BANK_ANALYSIS.md`**: Details on memory banking (`abadia*.bin` files) and the "Windowing" technique.
- **`GRAPHICS_ENGINE.md`**: Deep dive into the tile-based isometric engine, blocks, and rendering.
- **`AI_PATHFINDING.md`**: Analysis of the Height Buffer, collision detection, and NPC navigation.
- **`SCRIPTING_SYSTEM.md`**: Documentation of the custom bytecode interpreter (`RST 08h`/`10h`) used for game events.
- **`SPRITE_*.md`**: Details on sprite formats and extraction results.

### 📂 Disassembly Data
- **`translated_english_files/`**: English translations of the assembly code and memory maps.
    - Includes `translated_abadia_chunks/` containing modularized code segments.
- **`original_spanish_files/`**: The original Spanish assembly source and text files.
- **`pirated_spanish_CPC_game_files/`**: The binary files (`abadia*.bin`) extracted from the "pirate" disk version, used as the reference for memory banking.

### ⚙️ Configuration
- **`pyproject.toml`**: Project build and dependency configuration.
- **`tests/`**: Unit tests for the Python tools.

## Getting Started

1. **Install Dependencies:**
   ```bash
   pip install -e ".[dev]"
   ```

2. **Run Tools:**
   Example: Run the main entry point (if configured) or specific scripts directly.
   ```bash
   python -m abadia.main
   ```

3. **Run Tests:**
   ```bash
   pytest
   ```

4. **Linting:**
   ```bash
   ruff check .
   ```
