#!/usr/bin/env python3
"""
Rebuild the 64KB Memory Dump from Original Game Files.

This script reconstructs the complete Z80 memory image (abbey_code.bin) from the
original Amstrad CPC game files. It is essential for reproducibility and documents
the provenance of the binary data used throughout this project.

═══════════════════════════════════════════════════════════════════════════════
MEMORY BANK & FILE STRUCTURE ANALYSIS
═══════════════════════════════════════════════════════════════════════════════

The game uses "windowing" where 0x4000-0x7FFF is swapped with different content
depending on game state (Game Logic, Room Rendering, Debugging, etc.).

MAIN MEMORY MAP (Configuration 0):
──────────────────────────────────────────────────────────────────────────────
    Address Range    File          Content
    0x0000-0x00FF    (unused)      Zero-filled
    0x0100-0x3FFF    ABADIA1.BIN   Core Kernel: main loop, interrupts, HW control
    0x4000-0x7FFF    ABADIA2.BIN   The Window: swappable logic/data
    0x8000-0xBFFF    ABADIA3.BIN   Assets: sprites, fonts, audio data
    0xC000-0xFFFF    ABADIA0.BIN   Video RAM: active screen buffer

ADDITIONAL BANK FILES (swapped into 0x4000-0x7FFF):
  ABADIA5.BIN  Development debugger left by Paco Menéndez
  ABADIA6.BIN  0x0000-0x2FFF: Demo recording (Attract Mode keystrokes)
               0x3000-0x3FFF: Manuscript/intro scroll logic
  ABADIA7.BIN  0x0A00-0x1414: Height maps (3D geometry, collision, depth)
               0x1800-0x3FFF: AI navigation/pathfinding data
  ABADIA8.BIN  0x0000-0x2237: Room definitions (116 rooms)
               0x2328-0x2B27: Scoreboard/UI graphics
               0x2B28-0x37FF: Endgame content (music, final scroll)

AMSDOS HEADER:
──────────────────────────────────────────────────────────────────────────────
Each BIN file has a 128-byte AMSDOS header with metadata (filename, file type,
load address, etc.). This header is stripped when loading into memory.

OUTPUT:
──────────────────────────────────────────────────────────────────────────────
Creates: python/resources/abbey_code.bin (65536 bytes)

This file is used by:
  - interpreter.py (executes block bytecode)
  - dsl_converter.py (disassembles bytecode to DSL)
  - extract_block_scripts.py (extracts block definitions)
  - room_renderer.py (renders complete rooms)

USAGE:
------
    python rebuild_abbey_code.py

Requires the original BIN files in the 'cracked_spanish_cpc_game_files' directory.
"""

import os

BIN_DIR = 'cracked_spanish_cpc_game_files'
OUTPUT_FILE = 'python_scripts/resources/abbey_code.bin'

def rebuild():
    # Initialize 64KB memory
    memory = bytearray(65536)
    
    # Mapping configuration
    # (Filename, RAM Start, Max Bytes)
    mappings = [
        ('ABADIA1.BIN', 0x0100, 0x3F00), # Code
        ('ABADIA2.BIN', 0x4000, 0x4000), # Code/Data
        ('ABADIA3.BIN', 0x8000, 0x4000), # Graphics/Data
        ('ABADIA0.BIN', 0xC000, 0x4000), # Presentation/Video
    ]
    
    for filename, ram_start, max_bytes in mappings:
        filepath = os.path.join(BIN_DIR, filename)
        if not os.path.exists(filepath):
            print(f"Error: {filepath} not found")
            continue
            
        with open(filepath, 'rb') as f:
            # Skip 128-byte AMSDOS header
            f.read(128)
            # Read data
            data = f.read(max_bytes)
            
            # Load into memory
            memory[ram_start : ram_start + len(data)] = data
            print(f"Loaded {len(data)} bytes from {filename} to 0x{ram_start:04X}")

    # Ensure output directory exists
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    
    # Save the dump
    with open(OUTPUT_FILE, 'wb') as f:
        f.write(memory)
    print(f"Successfully rebuilt {OUTPUT_FILE}")

if __name__ == "__main__":
    rebuild()
