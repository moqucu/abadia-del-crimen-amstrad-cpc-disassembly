#!/usr/bin/env python3
"""
Rebuild the 64KB Memory Dump from Original Game Files.

This script reconstructs the complete Z80 memory image (abbey_code.bin) from the
original Amstrad CPC game files. It is essential for reproducibility and documents
the provenance of the binary data used throughout this project.

MEMORY MAP:
-----------
The Amstrad CPC has 64KB of addressable memory. The game loads 4 BIN files into
specific memory regions:

    Address Range    File          Content
    ─────────────────────────────────────────────────
    0x0000-0x00FF    (unused)      Zero-filled
    0x0100-0x3FFF    ABADIA1.BIN   Main game code
    0x4000-0x7FFF    ABADIA2.BIN   Code and data
    0x8000-0xBFFF    ABADIA3.BIN   Graphics and tile data
    0xC000-0xFFFF    ABADIA0.BIN   Presentation/video

AMSDOS HEADER:
--------------
Each BIN file has a 128-byte AMSDOS header that contains metadata (filename,
file type, load address, etc.). This header is stripped when loading into memory.

OUTPUT:
-------
Creates: python_scripts/src/abadia/resources/abbey_code.bin (65536 bytes)

This file is used by:
  - interpreter.py (executes block bytecode)
  - dsl_converter.py (disassembles bytecode to DSL)
  - extract_block_scripts.py (extracts block definitions)
  - room_renderer.py (renders complete rooms)

USAGE:
------
    python rebuild_abbey_code.py

Requires the original BIN files in the 'pirated_spanish_CPC_game_files' directory.
"""

import os

BIN_DIR = 'pirated_spanish_CPC_game_files'
OUTPUT_FILE = 'python_scripts/src/abadia/resources/abbey_code.bin'

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
            header = f.read(128)
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
