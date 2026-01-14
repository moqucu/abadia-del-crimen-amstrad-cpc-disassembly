#!/usr/bin/env python3
"""
Check ALL blocks in Room 0 to see what might fill the staircase gaps
"""
import os
import sys
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from abadia.abbey_rooms_library import ROOM_DEFINITIONS
from abadia.abbey_blocks_library import BLOCK_DEFINITIONS

room = ROOM_DEFINITIONS[0]

# Staircase is at (22, 28)
# Based on the tile trace, the narrow top steps are around Y=11-12 in tile coordinates
# Let's check blocks near X=22-24, Y=26-30 range

print("="*80)
print("ALL BLOCKS NEAR STAIRCASE AREA")
print("="*80)
print("\nStaircase: Block 0x0C at position (22, 28)")
print("\nAll blocks in X range [20-25], Y range [24-30]:")

for i, block_entry in enumerate(room.blocks):
    if 20 <= block_entry.x_pos <= 25 and 24 <= block_entry.y_pos <= 30:
        b_id = block_entry.block_id
        desc = BLOCK_DEFINITIONS[b_id].description if b_id in BLOCK_DEFINITIONS else "UNKNOWN"
        print(f"\n[{i:2d}] Block 0x{b_id:02X}: {desc}")
        print(f"     Position: ({block_entry.x_pos:2d}, {block_entry.y_pos:2d})")
        print(f"     Params: ({block_entry.x_length}, {block_entry.y_length})")

print("\n" + "="*80)
print("OBSERVATION:")
print("="*80)
print("If no other blocks fill the gap, then either:")
print("1. The staircase rendering has a bug (variable step width is incorrect)")
print("2. The staircase is intentionally asymmetric (unlikely)")
print("3. This is how the game actually renders it (architectural choice)")
