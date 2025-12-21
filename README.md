# Abadía del Crimen - Disassembly & Analysis Tools

This project hosts the disassembly of the Amstrad CPC version of "La Abadía del Crimen" along with Python-based analysis and asset extraction tools.

## Project Structure

### 🛠 Source Code (`src/abadia/`)
Python tools for reverse engineering and asset extraction:
- **`cpc_palette.py`**: Centralized CPC Amstrad palette utilities. Can be run directly to generate a palette visualization.
- **`extract_sprites.py`**: Tool for extracting game sprites with correct transparency.
- **`extract_tiles.py`**: Extractor for tile graphics.
- **`extract_block_scripts.py`**: Extracts scripting logic for game blocks.
- **`abbey_architect.py` & `abbey_blocks_library.py`**: Logic for reconstructing game rooms and screens.
- **`decompile_scripts.py`**: Decompiler for the game's custom scripting language.

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

---

## Development & Setup

### Environment Setup

This project uses a modern Python development environment:
- **Python 3.8+**
- **Build System**: `hatchling`
- **Virtual Environment**: `.venv/`

```bash
# Create and activate virtual environment
python3 -m venv .venv
source .venv/bin/activate  # macOS/Linux
# or
.venv\Scripts\activate     # Windows

# Install in editable mode with dev dependencies
pip install -e ".[dev]"
```

### Workflow (Make Commands)

A `Makefile` is provided for common tasks:
- `make dev`: Install development dependencies.
- `make test`: Run unit tests with `pytest`.
- `make lint`: Check code quality with `ruff`.
- `make format`: Auto-format code with `ruff`.
- `make clean`: Remove build artifacts and caches.

### Manual Commands

```bash
# Run tests
pytest

# Run a specific tool (example)
PYTHONPATH=src python3 src/abadia/extract_sprites.py

# Linting and Type Checking
ruff check src/
mypy src/
```

### PyCharm Configuration

1. Open **Settings > Project > Python Interpreter**.
2. Select **Add Local Interpreter** and choose the existing environment at `.venv/bin/python`.
3. Ensure `src/` is marked as a **Sources Root**.

### Code Quality Standards

- **Formatting**: Adheres to `ruff` defaults (88 char line length).
- **Type Hints**: Recommended for all new logic.
- **Tests**: New tools should include unit tests in the `tests/` directory.

---

## Troubleshooting

### Import Errors
If PyCharm or the shell doesn't recognize the `abadia` package, ensure you have installed the project in editable mode (`pip install -e .`) or set `PYTHONPATH=src`.

### Palette Mismatches
If extracted graphics look incorrect, check `src/abadia/cpc_palette.py`. The `VISUAL_PALETTES` are tuned to match authentic game screenshots rather than strict hardware specs.