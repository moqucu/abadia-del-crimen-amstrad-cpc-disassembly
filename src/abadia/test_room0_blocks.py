#!/usr/bin/env python3
"""
Test individual blocks from Room 0 to diagnose rendering issues
"""

import os
import sys
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from abadia.graphics import AbbeyTiles, AbbeyCanvas
from abadia.interpreter import AbadiaInterpreter
from abadia.abbey_blocks_library import BLOCK_DEFINITIONS
from abadia.abbey_rooms_library import ROOM_DEFINITIONS

def test_single_block(block_id, x, y, param1, param2, filename):
    """Test rendering a single block"""

    if block_id not in BLOCK_DEFINITIONS:
        print(f"Block 0x{block_id:02X} not in library")
        return False

    block_def = BLOCK_DEFINITIONS[block_id]
    print(f"\nTesting Block 0x{block_id:02X}: {block_def.description}")
    print(f"  Position: ({x}, {y}), Params: ({param1}, {param2})")
    print(f"  Address: 0x{block_def.address:04X}")
    print(f"  Bytecode length: {len(block_def.bytecode)} bytes")
    print(f"  Bytecode: {' '.join(f'{b:02X}' for b in block_def.bytecode[:20])}...")

    # Create small canvas centered around the block
    tiles = AbbeyTiles(palette='day')
    canvas = AbbeyCanvas(25, 25, bg_color=(0, 0, 0))
    interpreter = AbadiaInterpreter(tiles)

    try:
        # Execute at center of canvas
        interpreter.execute(block_def, canvas, 12, 12, param1, param2)

        # Save result
        canvas.save(filename)
        print(f"  ✓ Rendered successfully to {filename}")
        print(f"  Iterations: {interpreter.iteration_count}")
        return True

    except Exception as e:
        print(f"  ✗ Error: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    print("="*80)
    print("ROOM 0 BLOCK TESTING")
    print("="*80)

    # Get Room 0 blocks
    room = ROOM_DEFINITIONS[0]

    # Test directory
    test_dir = "test_room0_blocks"
    os.makedirs(test_dir, exist_ok=True)

    # Test first 5 blocks from Room 0
    print(f"\nTesting first 5 blocks from Room 0:")

    for i, block_entry in enumerate(room.blocks[:5]):
        filename = f"{test_dir}/block_{i:02d}_0x{block_entry.block_id:02X}.png"

        param1 = block_entry.x_length if block_entry.x_length > 0 else 1
        param2 = block_entry.y_length if block_entry.y_length > 0 else 1

        success = test_single_block(
            block_entry.block_id,
            block_entry.x_pos,
            block_entry.y_pos,
            param1,
            param2,
            filename
        )

        if not success:
            print(f"  Stopping due to error")
            break

    print(f"\n{'='*80}")
    print(f"Test blocks saved to {test_dir}/")
    print(f"{'='*80}")

if __name__ == "__main__":
    main()
