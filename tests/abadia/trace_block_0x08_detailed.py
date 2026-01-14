#!/usr/bin/env python3
"""
Detailed trace of Block 0x08 tile positions to understand height control
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
print("BLOCK 0x08 DETAILED TILE POSITION TRACE")
print("="*80)

block_def = BLOCK_DEFINITIONS[0x08]
tiles = AbbeyTiles(palette='day')

# Create a mapping of tile images to their IDs
tile_to_id = {}
for tile_id in block_def.tile_data:
    tile_img = tiles.get(tile_id)
    if hasattr(tile_img, 'tobytes'):
        tile_to_id[tile_img.tobytes()] = tile_id

# Test with different parameter values to understand height control
test_cases = [
    (0, 1, "Room 0 actual: params=(0,1)"),
    (0, 0, "Test: params=(0,0)"),
    (0, 2, "Test: params=(0,2)"),
    (0, 3, "Test: params=(0,3)"),
    (1, 1, "Test: params=(1,1)"),
]

for param1, param2, desc in test_cases:
    print(f"\n{'='*80}")
    print(f"{desc}")
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

    # Calculate height span
    if canvas.painted_sequence:
        y_coords = [y for x, y, _ in canvas.painted_sequence]
        height_span = max(y_coords) - min(y_coords) + 1
        print(f"\nHeight span: {height_span} tiles (Y from {min(y_coords)} to {max(y_coords)})")

print("\n" + "="*80)
print("CONCLUSION: Which parameter controls height?")
print("="*80)
