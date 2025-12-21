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
Analysis reports and visual assets:
- **`game_code_analysis.md`**: High-level analysis of the game's code structure.
- **`SPRITE_*.md`**: Details on sprite formats and extraction results.
- **`BLOCK_EXTRACTION_SUMMARY.md`**: Summary of block logic extraction.
- **Screenshots**: Visual references (Day/Night modes, Palette).

### 📂 Disassembly Data
- **`translated_english_files/`**: English translations of the assembly code and memory maps.
    - Includes `translated_abadia_chunks/` containing modularized code segments.
- **`original_spanish_files/`**: The original Spanish assembly source and text files.

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