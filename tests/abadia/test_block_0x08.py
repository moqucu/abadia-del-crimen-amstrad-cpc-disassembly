#!/usr/bin/env python3
"""
Test Block 0x08 - with tile tracing
"""
import os
import sys
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from abadia.graphics import AbbeyTiles, AbbeyCanvas
from abadia.interpreter import AbadiaInterpreter
from abadia.abbey_blocks_library import BLOCK_DEFINITIONS

# Tracked canvas for tile tracing
class TrackedCanvas(AbbeyCanvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.painted_tiles = []

    def draw_tile(self, tile_img, x_tile, y_tile):
        super().draw_tile(tile_img, x_tile, y_tile)
        self.painted_tiles.append((x_tile, y_tile, tile_img))

print("="*80)
print("BLOCK 0x08 TEST")
print("="*80)

# Get Block 0x08
# IMPORTANT FINDING: param2 controls the railing height by repeating the middle segment.
# Tile pattern: 0x34 (top) → 0x33 (repeated param2 times) → 0x32 (bottom)
#   - param2=0: No middle tiles → Height = 2-3 tiles
#   - param2=1: One 0x33 middle → Height = 3 tiles (Room 0 uses this)
#   - param2=2: Two 0x33 middles → Height = 4 tiles
#   - param2=3: Three 0x33 middles → Height = 5 tiles
# Room 0 uses params=(0,1) which gives a 3-tile high railing.
block_def = BLOCK_DEFINITIONS[0x08]
print(f"\nBlock: 0x{block_def.block_id:02X}")
print(f"Description: {block_def.description}")
print(f"Tile data: {[f'0x{t:02X}' for t in block_def.tile_data]}")

# Load tiles
tiles = AbbeyTiles(palette='day')

# Test with actual Room 0 parameters
test_cases = [
    (0, 1, "Room 0 usage: params=(0,1)"),
]

for param1, param2, desc in test_cases:
    print(f"\n{'='*80}")
    print(f"Test: {desc}")
    print('='*80)

    # Create canvas
    canvas = TrackedCanvas(15, 20, bg_color=(128, 128, 128))

    # Create interpreter
    interpreter = AbadiaInterpreter(tiles)

    # Execute block
    interpreter.execute(block_def, canvas, 5, 12, param1=param1, param2=param2)

    print(f"Iterations: {interpreter.iteration_count}")
    print(f"Final position: ({interpreter.l}, {interpreter.h})")
    print(f"Total tiles painted: {len(canvas.painted_tiles)}")

    # Identify which tiles were used
    tiles_used = set()
    for _, _, tile_img in canvas.painted_tiles:
        for tile_id in block_def.tile_data:
            known_tile = tiles.get(tile_id)
            if hasattr(tile_img, 'tobytes') and hasattr(known_tile, 'tobytes'):
                if tile_img.tobytes() == known_tile.tobytes():
                    tiles_used.add(tile_id)
                    break

    print(f"Unique tiles painted: {sorted([f'0x{t:02X}' for t in tiles_used])}")

    # Save result
    output = f'block_0x08_p1_{param1}_p2_{param2}.png'
    canvas.save(output)
    print(f"Saved: {output}")

print("\n" + "="*80)
print("GENERATED FILES:")
print("  block_0x08_p1_0_p2_1.png")
print("="*80)
