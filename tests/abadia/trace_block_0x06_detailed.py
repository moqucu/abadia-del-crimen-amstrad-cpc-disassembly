#!/usr/bin/env python3
"""
Detailed trace of Block 0x06 tile positions
"""
import os
import sys
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from abadia.graphics import AbbeyTiles, AbbeyCanvas
from abadia.interpreter import AbadiaInterpreter
from abadia.abbey_blocks_library import BLOCK_DEFINITIONS

# Tracked canvas that records tile positions
class TrackedCanvas(AbbeyCanvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.painted_sequence = []

    def draw_tile(self, tile_img, x_tile, y_tile):
        super().draw_tile(tile_img, x_tile, y_tile)
        self.painted_sequence.append((x_tile, y_tile, tile_img))

print("="*80)
print("BLOCK 0x06 DETAILED TILE POSITION TRACE")
print("="*80)

block_def = BLOCK_DEFINITIONS[0x06]
tiles = AbbeyTiles(palette='day')

# Create a mapping of tile images to their IDs
tile_to_id = {}
for tile_id in block_def.tile_data:
    tile_img = tiles.get(tile_id)
    if hasattr(tile_img, 'tobytes'):
        tile_to_id[tile_img.tobytes()] = tile_id

# Test with both Room 0 parameters
test_cases = [
    (2, 6, "Room 0 usage #1"),
    (2, 1, "Room 0 usage #2"),
]

for param1, param2, desc in test_cases:
    print(f"\n{'='*80}")
    print(f"{desc}: params=({param1},{param2})")
    print('='*80)

    canvas = TrackedCanvas(15, 20, bg_color=(128, 128, 128))
    interpreter = AbadiaInterpreter(tiles)
    interpreter.execute(block_def, canvas, 5, 12, param1=param1, param2=param2)

    print(f"\nTile painting sequence ({len(canvas.painted_sequence)} tiles):")
    print("  # | Pos (x,y) | Tile ID")
    print("  --+-----------+---------")

    for i, (x, y, tile_img) in enumerate(canvas.painted_sequence):
        tile_id = None
        if hasattr(tile_img, 'tobytes'):
            tile_bytes = tile_img.tobytes()
            if tile_bytes in tile_to_id:
                tile_id = tile_to_id[tile_bytes]

        tile_str = f"0x{tile_id:02X}" if tile_id is not None else "???"
        print(f" {i:2d} | ({x:2d},{y:2d})    | {tile_str}")

    # Group by Y coordinate to see vertical structures
    print(f"\nGrouped by Y coordinate:")
    y_groups = {}
    for x, y, tile_img in canvas.painted_sequence:
        if y not in y_groups:
            y_groups[y] = []
        tile_id = None
        if hasattr(tile_img, 'tobytes'):
            tile_bytes = tile_img.tobytes()
            if tile_bytes in tile_to_id:
                tile_id = tile_to_id[tile_bytes]
        y_groups[y].append((x, tile_id))

    for y in sorted(y_groups.keys()):
        tiles_at_y = y_groups[y]
        tile_str = ", ".join([f"x={x}:0x{tid:02X}" if tid else f"x={x}:???" for x, tid in tiles_at_y])
        print(f"  Y={y:2d}: {tile_str}")

print("\n" + "="*80)
