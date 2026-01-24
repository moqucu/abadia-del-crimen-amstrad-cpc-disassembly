#!/usr/bin/env python3
"""
Render all rooms (0-99) to PNG files
"""
import os
import sys
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from abadia.graphics import AbbeyTiles, BufferedCanvas
from abadia.interpreter import AbadiaInterpreter
from abadia.abbey_blocks_library import BLOCK_DEFINITIONS
from abadia.abbey_rooms_library import ROOM_DEFINITIONS

print("="*80)
print("RENDERING ALL ROOMS")
print("="*80)

tiles = AbbeyTiles(palette='day')

# Create output directory
output_dir = 'rendered_rooms'
os.makedirs(output_dir, exist_ok=True)

for room_id in range(100):
    if room_id not in ROOM_DEFINITIONS:
        print(f"\nRoom {room_id:02d}: NOT FOUND - skipping")
        continue

    room = ROOM_DEFINITIONS[room_id]
    print(f"\nRoom {room_id:02d}: {len(room.blocks)} blocks")

    # Create canvas using BufferedCanvas for proper isometric rendering
    canvas = BufferedCanvas(tiles, bg_color=(20, 20, 20))
    interpreter = AbadiaInterpreter(tiles)

    blocks_rendered = 0
    blocks_skipped = 0

    for i, block_entry in enumerate(room.blocks):
        b_id = block_entry.block_id

        if b_id not in BLOCK_DEFINITIONS:
            blocks_skipped += 1
            continue

        block_def = BLOCK_DEFINITIONS[b_id]

        try:
            height = block_entry.extra_param if block_entry.extra_param is not None else 0
            interpreter.execute(block_def, canvas,
                              block_entry.x_pos, block_entry.y_pos,
                              param1=block_entry.x_length,
                              param2=block_entry.y_length,
                              height=height,
                              prio=i)
            blocks_rendered += 1
        except Exception as e:
            blocks_skipped += 1

    # Render and save room
    canvas.render()
    output_file = os.path.join(output_dir, f'room_{room_id:02d}.png')
    canvas.save(output_file)
    print(f"  Rendered: {blocks_rendered}/{len(room.blocks)} blocks -> {output_file}")
    if blocks_skipped > 0:
        print(f"  Skipped: {blocks_skipped} blocks")

print("\n" + "="*80)
print(f"All rooms rendered to {output_dir}/ directory")
print("="*80)
