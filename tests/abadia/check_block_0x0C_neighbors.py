#!/usr/bin/env python3
"""
Check what blocks are adjacent to Block 0x0C in Room 0
"""
import os
import sys
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from abadia.abbey_rooms_library import ROOM_DEFINITIONS
from abadia.abbey_blocks_library import BLOCK_DEFINITIONS

print("="*80)
print("BLOCK 0x0C NEIGHBORS IN ROOM 0")
print("="*80)

room = ROOM_DEFINITIONS[0]

# Find Block 0x0C placement
stair_block = None
stair_index = None
for i, block_entry in enumerate(room.blocks):
    if block_entry.block_id == 0x0C:
        stair_block = block_entry
        stair_index = i
        print(f"\nBlock 0x0C (stairs) found at index [{i}]:")
        print(f"  Position: ({block_entry.x_pos}, {block_entry.y_pos})")
        print(f"  Params: ({block_entry.x_length}, {block_entry.y_length})")
        print(f"  Description: {BLOCK_DEFINITIONS[0x0C].description}")
        break

if stair_block is None:
    print("Block 0x0C not found in Room 0!")
    sys.exit(1)

# Define a search radius around the staircase
stair_x = stair_block.x_pos
stair_y = stair_block.y_pos
search_radius = 5

print(f"\n{'='*80}")
print(f"Blocks within {search_radius} units of position ({stair_x}, {stair_y}):")
print('='*80)

nearby_blocks = []
for i, block_entry in enumerate(room.blocks):
    if i == stair_index:
        continue  # Skip the staircase itself

    dx = abs(block_entry.x_pos - stair_x)
    dy = abs(block_entry.y_pos - stair_y)
    distance = max(dx, dy)  # Chebyshev distance

    if distance <= search_radius:
        nearby_blocks.append((distance, i, block_entry))

# Sort by distance
nearby_blocks.sort(key=lambda x: x[0])

for distance, i, block_entry in nearby_blocks:
    b_id = block_entry.block_id
    desc = BLOCK_DEFINITIONS[b_id].description if b_id in BLOCK_DEFINITIONS else "UNKNOWN"
    rel_x = block_entry.x_pos - stair_x
    rel_y = block_entry.y_pos - stair_y

    print(f"\n[{i:2d}] Block 0x{b_id:02X} - Distance: {distance}")
    print(f"    Position: ({block_entry.x_pos:2d}, {block_entry.y_pos:2d}) - Relative: ({rel_x:+3d}, {rel_y:+3d})")
    print(f"    Params: ({block_entry.x_length}, {block_entry.y_length})")
    print(f"    Description: {desc}")

# Create a simple ASCII map showing relative positions
print(f"\n{'='*80}")
print("ASCII MAP (relative to staircase at 0,0):")
print('='*80)

# Create coordinate map
coord_map = {}
coord_map[(0, 0)] = f"0C*"  # Staircase

for distance, i, block_entry in nearby_blocks:
    rel_x = block_entry.x_pos - stair_x
    rel_y = block_entry.y_pos - stair_y
    key = (rel_x, rel_y)
    coord_map[key] = f"{block_entry.block_id:02X}"

# Find bounds
all_coords = list(coord_map.keys())
min_x = min(x for x, y in all_coords)
max_x = max(x for x, y in all_coords)
min_y = min(y for y, y in all_coords)
max_y = max(y for y, y in all_coords)

# Print map
print(f"\n    ", end="")
for x in range(min_x, max_x + 1):
    print(f"{x:+3d} ", end="")
print()

for y in range(min_y, max_y + 1):
    print(f"{y:+3d} ", end="")
    for x in range(min_x, max_x + 1):
        key = (x, y)
        if key in coord_map:
            print(f"{coord_map[key]:>3s} ", end="")
        else:
            print("  . ", end="")
    print()

print("\n" + "="*80)
