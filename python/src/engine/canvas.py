"""
Canvas classes for rendering tiles to images.

Provides both direct drawing (Canvas) and buffered depth-sorted rendering (BufferedCanvas).
"""

from PIL import Image
from .tiles import Tiles
from .buffer import TileBuffer


class Canvas:
    """Drawing canvas with tile-based coordinate system."""

    def __init__(self, width_tiles, height_tiles, bg_color=(0, 0, 0)):
        self.width_tiles = width_tiles
        self.height_tiles = height_tiles
        # Canvas size in pixels
        self.image = Image.new('RGB', (width_tiles * 16, height_tiles * 8), bg_color)

    def draw_tile(self, tile_img, x_tile, y_tile):
        """Draw a tile at tile coordinates (direct mode, no buffer)."""
        x_pixel = x_tile * 16
        y_pixel = y_tile * 8

        # Bounds check
        if 0 <= x_pixel < self.image.width and 0 <= y_pixel < self.image.height:
            try:
                if tile_img.mode == 'RGBA':
                    self.image.paste(tile_img, (x_pixel, y_pixel), tile_img)
                else:
                    self.image.paste(tile_img, (x_pixel, y_pixel))
            except ValueError:
                pass

    def save(self, filename):
        self.image.save(filename)


class BufferedCanvas:
    """
    Canvas that uses the TileBuffer system for proper isometric rendering.

    This matches the original game's approach:
    1. Interpreter draws to a tile buffer (not directly to pixels)
    2. Buffer stores tiles with depth info
    3. Final render sorts by depth for correct occlusion
    """

    def __init__(self, tiles: Tiles, bg_color=(0, 0, 0)):
        self.tiles = tiles
        self.bg_color = bg_color
        self.buffer = TileBuffer()

        # Output image: 320x200 to match JS output
        # Content area: 256x160 (16x20 tiles) starting at x=32
        self.image = Image.new('RGB', (320, 200), bg_color)

    def clear(self):
        """Clear both buffer and image for a new render."""
        self.buffer.clear()
        self.image = Image.new('RGB', (320, 200), self.bg_color)

    def set_height(self, h):
        """Set current height for depth calculations."""
        self.buffer.set_height(h)

    def draw_tile_by_id(self, tile_id, world_x, world_y, depth=None, prio=0):
        """
        Add a tile to the buffer by ID for later rendering.

        This is the preferred method - stores in buffer with depth info.
        """
        self.buffer.draw_tile(tile_id, world_x, world_y, depth, prio)

    def get_trace(self):
        return self.buffer.get_trace()

    def get_render_list(self):
        """Return the sorted render list."""
        return self.buffer.get_render_list()

    def render(self):
        """
        Render the buffer to the image with proper depth sorting.

        Call this after all tiles have been queued via draw_tile_by_id().
        """
        # Get all tiles sorted by depth
        sorted_tiles = self.buffer.get_all_tiles()

        # Draw each tile in depth order
        # Note: 32 pixel X offset to match JS viewport (game interface area)
        for buf_x, buf_y, tile_id, depth, prio in sorted_tiles:
            tile_img = self.tiles.get(tile_id)

            x_pixel = buf_x * 16 + 32  # 32px offset matches JS viewport
            y_pixel = buf_y * 8

            if 0 <= x_pixel < self.image.width and 0 <= y_pixel < self.image.height:
                try:
                    if tile_img.mode == 'RGBA':
                        self.image.paste(tile_img, (x_pixel, y_pixel), tile_img)
                    else:
                        self.image.paste(tile_img, (x_pixel, y_pixel))
                except ValueError:
                    pass

    def save(self, filename):
        self.image.save(filename)


# Backward compatibility aliases
AbbeyCanvas = Canvas
