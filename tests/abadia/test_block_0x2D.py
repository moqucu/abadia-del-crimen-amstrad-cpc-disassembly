#!/usr/bin/env python3
"""
Test Block 0x2D - "stairs with red brick on the edge parallel to the x axis (2)"
Compare with Block 0x0C to see if both have variable step widths
"""
import os
import sys
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from abadia.graphics import AbbeyTiles, AbbeyCanvas
from abadia.interpreter import AbadiaInterpreter
from abadia.abbey_blocks_library import BLOCK_DEFINITIONS

# Tracked canvas
class TrackedCanvas(AbbeyCanvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.painted_sequence = []

    def draw_tile(self, tile_img, x_tile, y_tile):
        super().draw_tile(tile_img, x_tile, y_tile)
        self.painted_sequence.append((x_tile, y_tile, tile_img))

print("="*80)
print("BLOCK 0x2D TEST - Compare with 0x0C")
print("="*80)

block_def = BLOCK_DEFINITIONS[0x2D]
tiles = AbbeyTiles(palette='day')

# Create a mapping of tile images to their IDs
tile_to_id = {}
for tile_id in block_def.tile_data:
    tile_img = tiles.get(tile_id)
    if hasattr(tile_img, 'tobytes'):
        tile_to_id[tile_img.tobytes()] = tile_id

print(f"\nBlock: 0x{block_def.block_id:02X}")
print(f"Description: {block_def.description}")

# Test with same params as we used for Block 0x0C
test_cases = [
    (1, 1, "Test: params=(1,1) - same as 0x0C"),
]

for param1, param2, desc in test_cases:
    print(f"\n{'='*80}")
    print(f"{desc}")
    print('='*80)

    canvas = TrackedCanvas(15, 20, bg_color=(128, 128, 128))
    interpreter = AbadiaInterpreter(tiles)
    interpreter.execute(block_def, canvas, 5, 12, param1=param1, param2=param2)

    print(f"Iterations: {interpreter.iteration_count}")
    print(f"Total tiles painted: {len(canvas.painted_sequence)}")

    # Group by Y coordinate to see step lengths
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

    print(f"\nStep widths by Y coordinate:")
    for y in sorted(y_groups.keys()):
        tiles_at_y = y_groups[y]
        print(f"  Y={y:2d}: {len(tiles_at_y)} tiles wide")

    # Save result
    output = f'block_0x2D_p1_{param1}_p2_{param2}.png'
    canvas.save(output)
    print(f"\nSaved: {output}")

print("\n" + "="*80)
print("COMPARISON:")
print("="*80)
print("Block 0x0C params=(1,1) step widths: 2, 3, 4, 3, 2 (VARIABLE)")
print("Block 0x2D params=(1,1) step widths: (see above)")
print("\nIf Block 0x2D also has variable widths, it's likely intentional.")
print("If Block 0x2D has constant widths, then 0x0C might have a bug.")
