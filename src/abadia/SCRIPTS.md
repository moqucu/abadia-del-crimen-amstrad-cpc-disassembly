# Python Scripts Reference

This document provides a summary of all Python scripts in the `src/abadia/` directory.

| Script | Summary |
|--------|---------|
| `__init__.py` | Top-level package for Abadia del Crimen tools |
| `abbey_architect.py` | Complete Block Renderer demonstrating isometric engine assembly |
| `abbey_blocks_library.py` | Auto-generated library of 96 building block scripts from memory dump |
| `abbey_rooms_library.py` | Room definitions extracted from abadia8.bin (116 rooms) |
| `dsl_converter.py` | Internal library for converting bytecode to human-readable DSL |
| `cpc_palette.py` | Amstrad CPC color palette definitions and RGB mappings |
| `decompile_scripts.py` | Decompile custom scripting language (rst 08h/10h) to pseudo-code |
| `extract_block_scripts.py` | Extract building block scripts from binary memory dump |
| `extract_rooms.py` | Extract room/screen definitions from abadia8.bin |
| `extract_sprites.py` | Extract sprites from disassembled game code as PNGs |
| `extract_tiles.py` | Extract 256 base tiles (16x8) from game code to PNG tilesheets and debug log |
| `generate_block_examples.py` | Render first occurrence of each block type from rooms |
| `graphics.py` | Tile buffer and rendering system with isometric z-ordering |
| `guillermo.py` | Player character state for Friar Guillermo |
| `input.py` | Keyboard input handler wrapping pygame for game control |
| `inspect_memory.py` | Utility to inspect raw bytes at specific memory addresses |
| `interpreter.py` | Bytecode interpreter for building block scripts |
| `main.py` | Main game loop controller emulating original Z80 logic |
| `mirror.py` | State management for secret mirror puzzle object |
| `rebuild_abbey_code.py` | Rebuild 64KB memory dump from original BIN files |
| `replicate_block_traces.py` | Replicate block traces and renderings from JS version |
| `room_renderer.py` | Render complete rooms using block definitions and interpreter |
| `trace_block_execution.py` | Trace execution of a single block for debugging |
