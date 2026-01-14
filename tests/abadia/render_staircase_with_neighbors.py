#!/usr/bin/env python3
"""
Render Block 0x0C (staircase) together with its adjacent blocks from Room 0
"""
import os
import sys
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from abadia.graphics import AbbeyTiles, AbbeyCanvas
from abadia.interpreter import AbadiaInterpreter
from abadia.abbey_blocks_library import BLOCK_DEFINITIONS
from abadia.abbey_rooms_library import ROOM_DEFINITIONS

print("="*80)
print("STAIRCASE + NEIGHBORS RENDERING")
print("="*80)

tiles = AbbeyTiles(palette='day')
room = ROOM_DEFINITIONS[0]

# Find the staircase and its immediate neighbors
stair_entry = None
stair_index = None
for i, block_entry in enumerate(room.blocks):
    if block_entry.block_id == 0x0C:
        stair_entry = block_entry
        stair_index = i
        break

# Select neighbors to render
neighbor_indices = [13, 22, 25, 26]  # Blocks closest to the staircase

# Create a large canvas
canvas = AbbeyCanvas(30, 30, bg_color=(64, 64, 64))

print("\nRendering blocks:")
blocks_to_render = [(stair_index, stair_entry)] + [(i, room.blocks[i]) for i in neighbor_indices]

for idx, block_entry in blocks_to_render:
    b_id = block_entry.block_id
    desc = BLOCK_DEFINITIONS[b_id].description if b_id in BLOCK_DEFINITIONS else "UNKNOWN"

    print(f"\n[{idx:2d}] Block 0x{b_id:02X}: {desc}")
    print(f"     Position: ({block_entry.x_pos:2d}, {block_entry.y_pos:2d})")
    print(f"     Params: ({block_entry.x_length}, {block_entry.y_length})")

    if b_id in BLOCK_DEFINITIONS:
        block_def = BLOCK_DEFINITIONS[b_id]
        interpreter = AbadiaInterpreter(tiles)

        # Use room position for canvas coordinates
        # Adjust to fit on canvas
        x_canvas = block_entry.x_pos - 10
        y_canvas = block_entry.y_pos - 15

        try:
            interpreter.execute(block_def, canvas, x_canvas, y_canvas,
                              param1=block_entry.x_length, param2=block_entry.y_length)
            print(f"     Rendered at canvas pos ({x_canvas}, {y_canvas})")
        except Exception as e:
            print(f"     ERROR: {e}")

output = 'staircase_with_neighbors.png'
canvas.save(output)
print(f"\n{'='*80}")
print(f"Saved: {output}")
print("="*80)
