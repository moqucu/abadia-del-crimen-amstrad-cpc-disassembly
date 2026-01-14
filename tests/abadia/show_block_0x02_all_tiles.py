#!/usr/bin/env python3
"""
Display all tiles referenced by Block 0x02
"""
import os
import sys
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from PIL import Image
from abadia.graphics import AbbeyTiles
from abadia.abbey_blocks_library import BLOCK_DEFINITIONS

print("="*80)
print("BLOCK 0x02 - ALL REFERENCED TILES")
print("="*80)

block_def = BLOCK_DEFINITIONS[0x02]
tiles = AbbeyTiles(palette='day')

# Create a canvas showing all tiles
tile_data = block_def.tile_data
num_tiles = len(tile_data)

# Create grid: 4 columns
cols = 4
rows = (num_tiles + cols - 1) // cols

# Each tile is 16x8, with spacing
tile_width = 16
tile_height = 8
spacing = 4
label_height = 12

canvas = Image.new('RGB',
                   (cols * (tile_width + spacing) + spacing,
                    rows * (tile_height + label_height + spacing) + spacing),
                   (64, 64, 64))

print("\nTiles referenced by Block 0x02:")
for i, tile_id in enumerate(tile_data):
    row = i // cols
    col = i % cols

    x = spacing + col * (tile_width + spacing)
    y = spacing + row * (tile_height + label_height + spacing) + label_height

    # Get and paste tile
    tile_img = tiles.get(tile_id)
    canvas.paste(tile_img, (x, y))

    print(f"  reg[{i+1:2d}] = 0x{tile_id:02X} at position ({col}, {row})")

output = 'block_0x02_all_tiles.png'
canvas.save(output)
print(f"\nSaved visual grid: {output}")

# Also save individual enlarged versions of the "mystery" tiles
mystery_tiles = [0x00, 0x23, 0x22, 0x61, 0x29, 0x26, 0x25, 0x27]
print("\nCreating enlarged views of non-painted tiles:")

for tile_id in mystery_tiles:
    tile_img = tiles.get(tile_id)
    # Scale up 4x for easier viewing
    enlarged = tile_img.resize((64, 32), Image.NEAREST)
    output = f'tile_0x{tile_id:02X}_enlarged.png'
    enlarged.save(output)
    print(f"  Saved: {output} (tile_0x{tile_id:02X})")

print("\n" + "="*80)
