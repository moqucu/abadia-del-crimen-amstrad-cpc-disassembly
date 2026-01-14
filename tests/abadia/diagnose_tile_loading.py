#!/usr/bin/env python3
"""
Diagnostic script to find why AbbeyTiles loads corrupted pixel data
"""
import os
import sys
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from PIL import Image
from abadia.graphics import AbbeyTiles

print("="*80)
print("TILE LOADING DIAGNOSTIC")
print("="*80)

# Test tile 0x28 (40 decimal)
tile_id = 0x28

# Method 1: Direct loading (KNOWN TO WORK)
print("\n1. Direct Image.open():")
direct_path = 'src/abadia/resources/tiles/palette_day/tile_040_0x28.png'
print(f"   Path: {direct_path}")
print(f"   Exists: {os.path.exists(direct_path)}")

tile_direct = Image.open(direct_path)
print(f"   Mode: {tile_direct.mode}")
print(f"   Size: {tile_direct.size}")
print(f"   Pixel[3,0]: {tile_direct.getpixel((3, 0))}")
print(f"   Pixel[0,0]: {tile_direct.getpixel((0, 0))}")

# Method 2: Via AbbeyTiles class (BROKEN)
print("\n2. Via AbbeyTiles class:")
tiles = AbbeyTiles(palette='day')
tile_class = tiles.get(tile_id)
print(f"   Mode: {tile_class.mode}")
print(f"   Size: {tile_class.size}")
print(f"   Pixel[3,0]: {tile_class.getpixel((3, 0))}")
print(f"   Pixel[0,0]: {tile_class.getpixel((0, 0))}")

# Method 3: Manually replicate what AbbeyTiles does
print("\n3. Manual replication of AbbeyTiles logic:")
tiles_dir = 'src/abadia/resources/tiles'
palette = 'day'
tile_path = os.path.join(tiles_dir, f'palette_{palette}')
filename = f'tile_{tile_id:03d}_0x{tile_id:02X}.png'
filepath = os.path.join(tile_path, filename)
print(f"   Path: {filepath}")
print(f"   Exists: {os.path.exists(filepath)}")

tile_manual = Image.open(filepath).copy()
print(f"   Mode: {tile_manual.mode}")
print(f"   Size: {tile_manual.size}")
print(f"   Pixel[3,0]: {tile_manual.getpixel((3, 0))}")
print(f"   Pixel[0,0]: {tile_manual.getpixel((0, 0))}")

# Comparison
print("\n" + "="*80)
print("COMPARISON:")
print("="*80)
print(f"Direct vs Class pixel[3,0]: {tile_direct.getpixel((3, 0))} vs {tile_class.getpixel((3, 0))}")
print(f"Direct vs Manual pixel[3,0]: {tile_direct.getpixel((3, 0))} vs {tile_manual.getpixel((3, 0))}")

if tile_direct.getpixel((3, 0)) == tile_class.getpixel((3, 0)):
    print("✓ Tiles match!")
else:
    print("✗ Tiles DO NOT match - AbbeyTiles is corrupted")

# Save comparison images
tile_direct.save('diagnostic_tile_direct.png')
tile_class.save('diagnostic_tile_class.png')
tile_manual.save('diagnostic_tile_manual.png')

print("\nSaved diagnostic tiles:")
print("  diagnostic_tile_direct.png")
print("  diagnostic_tile_class.png")
print("  diagnostic_tile_manual.png")
