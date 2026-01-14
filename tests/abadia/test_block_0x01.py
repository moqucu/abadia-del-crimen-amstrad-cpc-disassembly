#!/usr/bin/env python3
"""
Test Block 0x01 rendering with the interpreter
"""
import os
import sys
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from abadia.graphics import AbbeyTiles, AbbeyCanvas
from abadia.interpreter import AbadiaInterpreter
from abadia.abbey_blocks_library import BLOCK_DEFINITIONS

print("="*80)
print("BLOCK 0x01 RENDERING TEST")
print("="*80)

# Get Block 0x01
block_def = BLOCK_DEFINITIONS[0x01]
print(f"\nBlock: 0x{block_def.block_id:02X}")
print(f"Description: {block_def.description}")
print(f"Tile data: {[f'0x{t:02X}' for t in block_def.tile_data[:3]]}")

# Load tiles
tiles = AbbeyTiles(palette='day')

# Create canvas (enough space for a vertical wall)
canvas = AbbeyCanvas(3, 10, bg_color=(128, 128, 128))

# Create interpreter
interpreter = AbadiaInterpreter(tiles)

# Execute block at center position
print(f"\nExecuting block with params (1, 1)...")
interpreter.execute(block_def, canvas, 1, 5, param1=1, param2=1)

print(f"Iterations: {interpreter.iteration_count}")
print(f"Final position: ({interpreter.l}, {interpreter.h})")

# Save result
output = 'test_block_0x01_render.png'
canvas.save(output)
print(f"\nSaved to: {output}")

# Check a few pixels
print(f"\nCanvas pixel checks:")
print(f"  Pixel (19, 40): {canvas.image.getpixel((19, 40))}")  # Should be part of brick
print(f"  Pixel (19, 32): {canvas.image.getpixel((19, 32))}")  # Should be part of brick
