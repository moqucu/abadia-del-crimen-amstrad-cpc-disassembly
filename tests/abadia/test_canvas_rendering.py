#!/usr/bin/env python3
"""
Test the full rendering pipeline: AbbeyTiles → AbbeyCanvas → PNG
"""
import os
import sys
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from abadia.graphics import AbbeyTiles, AbbeyCanvas

print("="*80)
print("CANVAS RENDERING TEST")
print("="*80)

# Load tiles via AbbeyTiles
tiles = AbbeyTiles(palette='day')

# Get the three tiles for the wall
tile_top = tiles.get(0x29)
tile_middle = tiles.get(0x09)
tile_bottom = tiles.get(0x28)

print("\nTile pixel data BEFORE drawing:")
print(f"  Top (0x29)    pixel[3,0]: {tile_top.getpixel((3, 0))}")
print(f"  Middle (0x09) pixel[3,0]: {tile_middle.getpixel((3, 0))}")
print(f"  Bottom (0x28) pixel[3,0]: {tile_bottom.getpixel((3, 0))}")

# Create canvas
canvas = AbbeyCanvas(1, 5, bg_color=(200, 200, 200))

# Draw wall manually (top to bottom)
print("\nDrawing wall to canvas...")
y = 0
canvas.draw_tile(tile_top, 0, y)
y += 1
for i in range(3):
    canvas.draw_tile(tile_middle, 0, y)
    y += 1
canvas.draw_tile(tile_bottom, 0, y)

# Save result
output = 'test_canvas_wall.png'
canvas.save(output)
print(f"\nSaved to: {output}")

# Check canvas pixel data
print(f"\nCanvas pixel data at position (3, 0): {canvas.image.getpixel((3, 0))}")
print(f"Canvas pixel data at position (3, 8): {canvas.image.getpixel((3, 8))}")

print("\nTile pixel data AFTER drawing:")
print(f"  Top (0x29)    pixel[3,0]: {tile_top.getpixel((3, 0))}")
print(f"  Middle (0x09) pixel[3,0]: {tile_middle.getpixel((3, 0))}")
print(f"  Bottom (0x28) pixel[3,0]: {tile_bottom.getpixel((3, 0))}")
