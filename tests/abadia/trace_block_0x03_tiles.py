#!/usr/bin/env python3
"""
Trace which tiles Block 0x03 actually uses during execution
"""
import os
import sys
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from abadia.graphics import AbbeyTiles, AbbeyCanvas
from abadia.interpreter import AbadiaInterpreter
from abadia.abbey_blocks_library import BLOCK_DEFINITIONS

# Monkey-patch the canvas to track painted tiles
class TrackedCanvas(AbbeyCanvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.painted_tiles = []

    def draw_tile(self, tile_img, x_tile, y_tile):
        super().draw_tile(tile_img, x_tile, y_tile)
        self.painted_tiles.append((x_tile, y_tile, tile_img))

print("="*80)
print("BLOCK 0x03 TILE USAGE TRACE")
print("="*80)

block_def = BLOCK_DEFINITIONS[0x03]
print(f"\nBlock 0x03 tile_data: {[f'0x{t:02X}' for t in block_def.tile_data]}")
print("\nTile mapping to registers:")
for i, tile_id in enumerate(block_def.tile_data, 1):
    print(f"  reg[{i}] = 0x{tile_id:02X} (tile_{tile_id:03d}_0x{tile_id:02X}.png)")

# Load tiles
tiles = AbbeyTiles(palette='day')

# Test with different parameters
test_cases = [
    (1, 0),
    (1, 1),
    (2, 1),
    (2, 4),
]

for param1, param2 in test_cases:
    print(f"\n{'='*80}")
    print(f"Testing with param1={param1}, param2={param2}")
    print('='*80)

    canvas = TrackedCanvas(15, 15, bg_color=(128, 128, 128))
    interpreter = AbadiaInterpreter(tiles)

    # Execute
    interpreter.execute(block_def, canvas, 5, 10, param1=param1, param2=param2)

    print(f"Total tiles painted: {len(canvas.painted_tiles)}")

    # Identify which tiles were used by comparing pixel data
    tiles_used = set()
    for _, _, tile_img in canvas.painted_tiles:
        for tile_id in block_def.tile_data:
            known_tile = tiles.get(tile_id)
            if tile_img == known_tile or (hasattr(tile_img, 'tobytes') and
                                          hasattr(known_tile, 'tobytes') and
                                          tile_img.tobytes() == known_tile.tobytes()):
                tiles_used.add(tile_id)
                break

    print(f"Unique tiles painted: {sorted([f'0x{t:02X}' for t in tiles_used])}")

print("\n" + "="*80)
print("SUMMARY: Only a few tiles are actually painted.")
print("The rest are loaded into registers but never used.")
print("="*80)
