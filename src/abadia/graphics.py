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
        if num not in self.tiles:
            # print(f"Warning: Tile {num} not found, using fallback.")
            return self.tiles[0]
        return self.tiles[num]


class TileBuffer:
    """
    Tile buffer system matching the original game's approach exactly.

    The game uses a 16x20 tile buffer where:
    - Interpreter coordinates (x, y) are offset by 8 to get buffer coords
    - Coordinates outside 0-15, 0-19 are clipped
    - Each cell can hold multiple tiles with depth info
    - Final render sorts by depth for proper occlusion

    From reference ScriptInterpreter.js:
      const pX = this.block.x - 8;
      const pY = this.block.y - 8;
      if (pX < 0 || pX >= 16) return;
      if (pY < 0 || pY >= 20) return;
    """

    # Buffer dimensions - exact match to reference
    BUFFER_WIDTH = 16
    BUFFER_HEIGHT = 20

    # Coordinate offset from world to buffer space
    X_OFFSET = 8
    Y_OFFSET = 8

    def __init__(self):
        # Each cell holds a list of (tile_id, depth) tuples
        self.buffer = [[[] for _ in range(self.BUFFER_HEIGHT)]
                       for _ in range(self.BUFFER_WIDTH)]
        self.current_height = 0  # Z height for depth calculation
        self.trace_data = []

    def clear(self):
        """Clear the buffer for a new render."""
        for x in range(self.BUFFER_WIDTH):
            for y in range(self.BUFFER_HEIGHT):
                self.buffer[x][y] = []
        self.trace_data = []

    def set_height(self, h):
        """Set the current height (Z) for depth calculations."""
        self.current_height = h

    def draw_tile(self, tile_id, world_x, world_y, depth=None, prio=0):
        """
        Add a tile to the buffer at world coordinates.

        Exactly matches reference ScriptInterpreter.js drawTileHandler:
        - Offset by 8
        - Clip outside 0-15, 0-19
        - Store with depth info for sorting
        """
        # Transform to buffer coordinates (matches reference exactly)
        buf_x = world_x - self.X_OFFSET
        buf_y = world_y - self.Y_OFFSET

        # Clip outside buffer bounds (matches reference exactly)
        if buf_x < 0 or buf_x >= self.BUFFER_WIDTH:
            return
        if buf_y < 0 or buf_y >= self.BUFFER_HEIGHT:
            return

        # Calculate depth for proper occlusion
        # If explicit depth is provided (calculated per-block), use it.
        # Otherwise, fallback to the old implicit calculation (though this is likely incorrect for Abadia)
        if depth is None:
            h = self.current_height
            depth_x = (world_y + h // 2) + world_x - 15
            depth_y = (world_y + h // 2) - world_x + 16
            depth = depth_x + depth_y - 16

        self.buffer[buf_x][buf_y].append((tile_id, depth))
        
        # Trace (Screen X offset 32 matches debug_trace.txt)
        screen_x = buf_x * 16 + 32
        screen_y = buf_y * 8
        trace_line = f"Tile: {tile_id:<3} | Grid: ({buf_x:>2}, {buf_y:>2}) | Screen: ({screen_x:>3}, {screen_y:>3}) | Depth: {depth:>3} | Prio: {prio}"
        self.trace_data.append(trace_line)

    def get_trace(self):
        return self.trace_data

    def get_all_tiles(self):
        """
        Return all tiles sorted by depth for rendering.

        Returns: list of (buf_x, buf_y, tile_id, depth)
        """
        tiles = []
        for x in range(self.BUFFER_WIDTH):
            for y in range(self.BUFFER_HEIGHT):
                for tile_id, depth in self.buffer[x][y]:
                    tiles.append((x, y, tile_id, depth))

        # Sort by depth (lower depth = further back = draw first)
        tiles.sort(key=lambda t: t[3])
        return tiles


class AbbeyCanvas:
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
            except:
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

    def __init__(self, tiles: AbbeyTiles, bg_color=(0, 0, 0)):
        self.tiles = tiles
        self.bg_color = bg_color
        self.buffer = TileBuffer()

        # Output image: 16x20 tile buffer * 16x8 pixel tiles = 256x160 pixels
        # This matches the game's room viewport
        self.image = Image.new('RGB',
                               (TileBuffer.BUFFER_WIDTH * 16,
                                TileBuffer.BUFFER_HEIGHT * 8),
                               bg_color)

    def clear(self):
        """Clear both buffer and image for a new render."""
        self.buffer.clear()
        self.image = Image.new('RGB',
                               (TileBuffer.BUFFER_WIDTH * 16,
                                TileBuffer.BUFFER_HEIGHT * 8),
                               self.bg_color)

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

    def render(self):
        """
        Render the buffer to the image with proper depth sorting.

        Call this after all tiles have been queued via draw_tile_by_id().
        """
        # Get all tiles sorted by depth
        sorted_tiles = self.buffer.get_all_tiles()

        # Draw each tile in depth order
        for buf_x, buf_y, tile_id, depth in sorted_tiles:
            tile_img = self.tiles.get(tile_id)

            x_pixel = buf_x * 16
            y_pixel = buf_y * 8

            if 0 <= x_pixel < self.image.width and 0 <= y_pixel < self.image.height:
                try:
                    if tile_img.mode == 'RGBA':
                        self.image.paste(tile_img, (x_pixel, y_pixel), tile_img)
                    else:
                        self.image.paste(tile_img, (x_pixel, y_pixel))
                except:
                    pass

    def save(self, filename):
        self.image.save(filename)
