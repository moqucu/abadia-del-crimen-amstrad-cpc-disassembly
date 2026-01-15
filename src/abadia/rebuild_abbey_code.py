#!/usr/bin/env python3
"""
Rebuild the 64KB memory dump (abbey_code.bin) from the original BIN files.
This ensures we have exact binary parity with the game and avoids disassembler errors.
"""

import os

BIN_DIR = 'pirated_spanish_CPC_game_files'
OUTPUT_FILE = 'src/abadia/resources/abbey_code.bin'

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
