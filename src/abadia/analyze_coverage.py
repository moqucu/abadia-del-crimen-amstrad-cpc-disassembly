#!/usr/bin/env python3
"""
Analyze room rendering coverage - which blocks are missing
"""

import sys
import os
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from abadia.abbey_rooms_library import ROOM_DEFINITIONS
from abadia.abbey_blocks_library import BLOCK_DEFINITIONS

def main():
    # Collect all block IDs used across all rooms
    used_blocks = set()
    available_blocks = set(BLOCK_DEFINITIONS.keys())

    for room_id, room in ROOM_DEFINITIONS.items():
        for block in room.blocks:
            used_blocks.add(block.block_id)

    missing_blocks = used_blocks - available_blocks
    unused_available = available_blocks - used_blocks

    print("="*80)
    print("ROOM RENDERING COVERAGE ANALYSIS")
    print("="*80)
    print(f"\nTotal rooms extracted: {len(ROOM_DEFINITIONS)}")
    print(f"Total blocks used in rooms: {len(used_blocks)}")
    print(f"Total blocks in library: {len(available_blocks)}")
    print(f"Missing blocks: {len(missing_blocks)}")
    print(f"Coverage: {len(used_blocks - missing_blocks)}/{len(used_blocks)} ({100*(len(used_blocks - missing_blocks))/len(used_blocks):.1f}%)")

    print(f"\n{'='*80}")
    print(f"MISSING BLOCKS ({len(missing_blocks)} blocks)")
    print(f"{'='*80}")
    missing_sorted = sorted(missing_blocks)
    for i, block_id in enumerate(missing_sorted):
        # Count how many rooms use this block
        room_count = sum(1 for room in ROOM_DEFINITIONS.values()
                        if any(b.block_id == block_id for b in room.blocks))
        print(f"  0x{block_id:02X} - Used in {room_count} room(s)")

    print(f"\n{'='*80}")
    print(f"ROOM-BY-ROOM ANALYSIS")
    print(f"{'='*80}")

    for room_id in sorted(ROOM_DEFINITIONS.keys())[:10]:  # First 10 rooms
        room = ROOM_DEFINITIONS[room_id]
        room_blocks = set(b.block_id for b in room.blocks)
        room_missing = room_blocks & missing_blocks
        completeness = 100 * (1 - len(room_missing) / len(room_blocks)) if room_blocks else 100

        status = "✓ COMPLETE" if len(room_missing) == 0 else f"✗ PARTIAL ({len(room_missing)} missing)"
        print(f"\nRoom {room_id:2d}: {len(room.blocks):2d} blocks, {completeness:5.1f}% complete - {status}")

        if room_missing:
            print(f"         Missing: {', '.join(f'0x{b:02X}' for b in sorted(room_missing))}")

    if len(ROOM_DEFINITIONS) > 10:
        print(f"\n... and {len(ROOM_DEFINITIONS) - 10} more rooms")

    print(f"\n{'='*80}")
    print(f"SUMMARY")
    print(f"{'='*80}")

    # Count fully renderable rooms
    fully_renderable = 0
    for room in ROOM_DEFINITIONS.values():
        room_blocks = set(b.block_id for b in room.blocks)
        if len(room_blocks & missing_blocks) == 0:
            fully_renderable += 1

    print(f"Fully renderable rooms: {fully_renderable}/{len(ROOM_DEFINITIONS)} " +
          f"({100*fully_renderable/len(ROOM_DEFINITIONS):.1f}%)")
    print(f"Rooms with missing blocks: {len(ROOM_DEFINITIONS) - fully_renderable}")
    print(f"\nTo achieve 100% coverage, extract these {len(missing_blocks)} blocks from Material Table at 0x156D:")
    print(f"  {', '.join(f'0x{b:02X}' for b in sorted(missing_blocks))}")

if __name__ == "__main__":
    main()
