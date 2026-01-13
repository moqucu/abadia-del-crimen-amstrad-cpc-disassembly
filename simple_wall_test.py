#!/usr/bin/env python3
"""
Simple test: Load 3 tile PNGs and draw a vertical wall
"""
from PIL import Image

# Load the three tiles
tile_top = Image.open('src/abadia/resources/tiles/palette_day/tile_041_0x29.png')
tile_middle = Image.open('src/abadia/resources/tiles/palette_day/tile_009_0x09.png')
tile_bottom = Image.open('src/abadia/resources/tiles/palette_day/tile_040_0x28.png')

print('Loaded tiles:')
print(f'  Top (0x29): {tile_top.size}')
print(f'  Middle (0x09): {tile_middle.size}')
print(f'  Bottom (0x28): {tile_bottom.size}')

# Create canvas: 5 tiles tall (1 top + 3 middle + 1 bottom), 1 tile wide
# Each tile is 16x8 pixels
canvas = Image.new('RGB', (16, 5 * 8), (200, 200, 200))

print('\nDrawing wall (top to bottom):')
y_pos = 0

# Draw top
print(f'  Top at y={y_pos}')
canvas.paste(tile_top, (0, y_pos))
y_pos += 8

# Draw 3 middle
for i in range(3):
    print(f'  Middle {i+1} at y={y_pos}')
    canvas.paste(tile_middle, (0, y_pos))
    y_pos += 8

# Draw bottom
print(f'  Bottom at y={y_pos}')
canvas.paste(tile_bottom, (0, y_pos))

output = 'simple_wall_direct.png'
canvas.save(output)
print(f'\nSaved to: {output}')
