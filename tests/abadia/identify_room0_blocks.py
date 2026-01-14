#!/usr/bin/env python3
"""
Identify which blocks are used in Room 0
"""
import os
import sys
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from abadia.abbey_rooms_library import ROOM_DEFINITIONS
from abadia.abbey_blocks_library import BLOCK_DEFINITIONS

print("="*80)
print("BLOCKS USED IN ROOM 0")
print("="*80)

room = ROOM_DEFINITIONS[0]
print(f"\nRoom 0 has {len(room.blocks)} block placements")

# Collect unique block IDs and their parameters
blocks_used = {}
for i, block_entry in enumerate(room.blocks):
    b_id = block_entry.block_id
    if b_id not in blocks_used:
        blocks_used[b_id] = []
    blocks_used[b_id].append({
        'index': i,
        'x': block_entry.x_pos,
        'y': block_entry.y_pos,
        'param1': block_entry.x_length,
        'param2': block_entry.y_length
    })

print(f"\nUnique blocks used: {len(blocks_used)}")
print("\nSorted by block ID:")
for b_id in sorted(blocks_used.keys()):
    if b_id in BLOCK_DEFINITIONS:
        desc = BLOCK_DEFINITIONS[b_id].description
        print(f"\nBlock 0x{b_id:02X}: {desc}")
        print(f"  Used {len(blocks_used[b_id])} times in Room 0:")
        for usage in blocks_used[b_id]:
            print(f"    [{usage['index']:2d}] pos=({usage['x']:2d},{usage['y']:2d}) params=({usage['param1']},{usage['param2']})")
    else:
        print(f"\nBlock 0x{b_id:02X}: NOT FOUND IN DEFINITIONS")

# Already reviewed
already_done = [0x01, 0x02, 0x03]
print("\n" + "="*80)
print("ALREADY REVIEWED:")
print(f"  {[f'0x{b:02X}' for b in already_done]}")

# Remaining to review
remaining = [b for b in sorted(blocks_used.keys()) if b not in already_done]
print("\nREMAINING TO REVIEW:")
print(f"  {[f'0x{b:02X}' for b in remaining]}")
print(f"  Total: {len(remaining)} blocks")
print("="*80)
