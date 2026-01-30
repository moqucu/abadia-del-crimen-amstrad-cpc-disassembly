"""
Tile buffer and rendering system for La Abadia del Crimen.

Provides AbbeyTiles for loading tile graphics, TileBuffer for depth-aware tile storage,
and BufferedCanvas for rendering rooms with proper isometric z-ordering.
"""

import os
from PIL import Image


class AbbeyTiles:
    """Load and manage the 256 base tiles from the generated sprite sheet."""

    def __init__(self, tiles_dir='python_scripts/src/abadia/resources/tiles', palette='day'):
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

    # Buffer dimensions - match game viewport (16x20 tiles = 256x160 pixels)
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

    def clear(self):
        """Clear the buffer for a new render."""
        for x in range(self.BUFFER_WIDTH):
            for y in range(self.BUFFER_HEIGHT):
                self.buffer[x][y] = []

    def set_height(self, h):
        """Set the current height (Z) for depth calculations."""
        self.current_height = h

    def draw_tile(self, tile_id, world_x, world_y, depth=None, prio=0):
        """
        Add a tile to the buffer at world coordinates.

        Exactly matches reference ScriptInterpreter.js drawTileHandler:
        - Offset by 8
        - Clip outside 0-15, 0-19
        - Store with depthX/depthY for in-cell correction
        - Apply in-cell depth clamping
        """
        # Transform to buffer coordinates (matches reference exactly)
        buf_x = world_x - self.X_OFFSET
        buf_y = world_y - self.Y_OFFSET

        # Clip outside buffer bounds (matches reference exactly)
        if buf_x < 0 or buf_x >= self.BUFFER_WIDTH:
            return
        if buf_y < 0 or buf_y >= self.BUFFER_HEIGHT:
            return

        # Use depthX/depthY from interpreter (passed via depth as tuple or use defaults)
        if isinstance(depth, tuple):
            depth_x, depth_y = depth
        elif depth is not None:
            # Legacy: single depth value, split evenly
            depth_x = depth // 2 + 8
            depth_y = depth - depth_x + 16
        else:
            h = self.current_height
            depth_x = (world_y + h // 2) + world_x - 15
            depth_y = (world_y + h // 2) - world_x + 16

        # Create new tile entry
        # Store prio for tracing
        new_tile = {'tile': tile_id, 'depthX': depth_x, 'depthY': depth_y, 'prio': prio}

        # Add to cell buffer
        cell_buffer = self.buffer[buf_x][buf_y]
        cell_buffer.append(new_tile)

        # IN-CELL DEPTH CORRECTION (from RENDERING_Z_ORDER.md)
        # If an older tile is closer to camera than the new tile, clamp its depth
        for i in range(len(cell_buffer) - 2, -1, -1):
            t_old = cell_buffer[i]
            t_new = cell_buffer[i + 1]

            # If older tile is mathematically "closer" than new one
            if (t_old['depthX'] + t_old['depthY']) > (t_new['depthX'] + t_new['depthY']):
                # Clamp older tile's depth to match new one
                if t_old['depthX'] > t_new['depthX']:
                    t_old['depthX'] = t_new['depthX']
                if t_old['depthY'] > t_new['depthY']:
                    t_old['depthY'] = t_new['depthY']

    def get_trace(self):
        """
        Generate a spatial trace of the buffer content (Column-Major order: X then Y).
        Matches the reference implementation's logging format.
        """
        trace_lines = []
        for x in range(self.BUFFER_WIDTH):
            for y in range(self.BUFFER_HEIGHT):
                cell = self.buffer[x][y]
                for tile in cell:
                    tile_id = tile['tile']
                    depth = tile['depthX'] + tile['depthY'] - 16
                    prio = tile['prio']
                    
                    screen_x = x * 16 + 32
                    screen_y = y * 8
                    
                    line = f"Tile: {tile_id:<3} | Grid: ({x:>2}, {y:>2}) | Screen: ({screen_x:>3}, {screen_y:>3}) | Depth: {depth:>3} | Prio: {prio}"
                    trace_lines.append(line)
        return trace_lines

    def get_render_list(self):
        """
        Return the flattened, sorted list of tiles ready for rendering.
        This represents the final 'Painter's Algorithm' state.
        """
        # get_all_tiles already performs the sort
        return self.get_all_tiles()

    def get_all_tiles(self):
        """
        Return all tiles sorted by depth for rendering.
        Uses the Painter's Algorithm from RENDERING_Z_ORDER.md:
        - Primary sort: depth (depthX + depthY - 16)
        - Secondary sort: priority (index within cell = creation order)

        Returns: list of (buf_x, buf_y, tile_id, depth, block_prio)
        """
        draw_list = []
        for x in range(self.BUFFER_WIDTH):
            for y in range(self.BUFFER_HEIGHT):
                cell = self.buffer[x][y]
                for index, tile in enumerate(cell):
                    depth = tile['depthX'] + tile['depthY'] - 16
                    # Store everything needed for sort and output
                    # sort_index is 'index' (creation order)
                    draw_list.append({
                        'x': x, 'y': y, 
                        'tile': tile['tile'], 
                        'depth': depth, 
                        'prio': tile['prio'], # Block Priority
                        'sort_index': index   # Creation Order
                    })

        # Sort by depth (lower = further = draw first), then by block priority
        # This matches JS behavior where same-depth tiles are ordered by Prio
        draw_list.sort(key=lambda t: (t['depth'], t['prio']))
        
        # Convert to tuple format expected by renderer
        return [(t['x'], t['y'], t['tile'], t['depth'], t['prio']) for t in draw_list]


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
                except:
                    pass

    def save(self, filename):
        self.image.save(filename)
