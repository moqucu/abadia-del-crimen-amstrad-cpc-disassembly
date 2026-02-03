"""
Tile loading and management for La Abadia del Crimen.

Loads the 256 base tiles from generated sprite sheets.
"""

import os
from PIL import Image


class Tiles:
    """Load and manage the 256 base tiles from the generated sprite sheet."""

    def __init__(self, tiles_dir='python/resources/tiles', palette='day'):
        self.tiles = {}
        sheet_filename = f'tiles_{palette}.png'
        sheet_path = os.path.join(tiles_dir, sheet_filename)

        if os.path.exists(sheet_path):
            sheet = Image.open(sheet_path).convert('RGBA')

            for i in range(256):
                # Calculate position in the 16-tile-wide grid
                # X = Column * 16 pixels
                # Y = Row * 8 pixels
                col = i % 16
                row = i // 16
                x = col * 16
                y = row * 8

                # Crop the 16x8 tile
                tile = sheet.crop((x, y, x + 16, y + 8))
                self.tiles[i] = tile
        else:
            print(f"Warning: Tile sheet {sheet_path} not found.")
            # Fallback: create empty tiles
            for i in range(256):
                self.tiles[i] = Image.new('RGB', (16, 8), (0, 0, 0))

    def get(self, num):
        if num not in self.tiles:
            return self.tiles[0]
        return self.tiles[num]


# Backward compatibility alias
AbbeyTiles = Tiles
