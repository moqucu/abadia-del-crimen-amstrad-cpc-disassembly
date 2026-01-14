#!/usr/bin/env python3
"""
Test Block 0x03 - "thick black brick parallel to y"
"""
import os
import sys
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from abadia.graphics import AbbeyTiles, AbbeyCanvas
from abadia.interpreter import AbadiaInterpreter
from abadia.abbey_blocks_library import BLOCK_DEFINITIONS

print("="*80)
print("BLOCK 0x03 - 'thick black brick parallel to y'")
print("="*80)

# Get Block 0x03
block_def = BLOCK_DEFINITIONS[0x03]
print(f"\nBlock: 0x{block_def.block_id:02X}")
print(f"Description: {block_def.description}")
print(f"Tile data: {[f'0x{t:02X}' for t in block_def.tile_data]}")

# Load tiles
tiles = AbbeyTiles(palette='day')

# Test different parameter combinations
test_cases = [
    (1, 0, "param1=1, param2=0 (minimal)"),
    (1, 1, "param1=1, param2=1 (small)"),
    (2, 1, "param1=2, param2=1"),
    (2, 4, "param1=2, param2=4"),
    (2, 0, "param1=2, param2=0 (from Room 0)")
]

for param1, param2, desc in test_cases:
    print(f"\n--- Test: {desc} ---")

    # Create canvas
    canvas = AbbeyCanvas(10, 15, bg_color=(128, 128, 128))

    # Create interpreter
    interpreter = AbadiaInterpreter(tiles)

    # Execute block
    interpreter.execute(block_def, canvas, 3, 10, param1=param1, param2=param2)

    print(f"  Iterations: {interpreter.iteration_count}")
    print(f"  Final position: ({interpreter.l}, {interpreter.h})")

    # Save result
    output = f'block_0x03_p1_{param1}_p2_{param2}.png'
    canvas.save(output)
    print(f"  Saved: {output}")

print("\n" + "="*80)
print("All test cases rendered. Check the PNG files.")
print("="*80)
