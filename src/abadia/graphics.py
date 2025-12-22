import os
from PIL import Image

class AbbeyTiles:
    """Load and manage the 256 base tiles."""

    def __init__(self, tiles_dir='src/abadia/resources/tiles', palette='day'):
        self.tiles = {}
        tile_path = os.path.join(tiles_dir, f'palette_{palette}')

        for i in range(256):
            filename = f'tile_{i:03d}_0x{i:02X}.png'
            filepath = os.path.join(tile_path, filename)
            if os.path.exists(filepath):
                self.tiles[i] = Image.open(filepath).copy()
            else:
                # Fallback: create empty tile
                self.tiles[i] = Image.new('RGB', (16, 8), (0, 0, 0))

    def get(self, num):
        return self.tiles.get(num, self.tiles[0])


class AbbeyCanvas:
    """Drawing canvas with tile-based coordinate system."""

    def __init__(self, width_tiles, height_tiles, bg_color=(0, 0, 0)):
        self.width_tiles = width_tiles
        self.height_tiles = height_tiles
        # Canvas size in pixels
        self.image = Image.new('RGB', (width_tiles * 16, height_tiles * 8), bg_color)

    def draw_tile(self, tile_img, x_tile, y_tile):
        """Draw a tile at tile coordinates."""
        # Isometric engine draws using grid coordinates.
        # But this Canvas is a 2D buffer.
        # x_tile, y_tile are 0-based indices in the buffer.
        
        x_pixel = x_tile * 16
        y_pixel = y_tile * 8

        # Bounds check
        if 0 <= x_pixel < self.image.width and 0 <= y_pixel < self.image.height:
            try:
                self.image.paste(tile_img, (x_pixel, y_pixel))
            except:
                pass

    def save(self, filename):
        self.image.save(filename)
