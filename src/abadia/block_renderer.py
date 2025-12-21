#!/usr/bin/env python3
"""
Block Renderer for "La Abadía del Crimen"

This library implements the game's building block interpreter, which executes
scripts to compose architectural elements from base tiles.

The block scripts are written in a custom bytecode language that the game
engine interprets to create complex structures from simple 16x8 tile primitives.
"""

import re
import os
from PIL import Image
from typing import Dict, List, Tuple, Optional

class TileLibrary:
    """Manages the 256 base tiles (16x8 pixels each)."""

    def __init__(self, tiles_dir: str, palette: str = 'day'):
        """
        Load all tiles from a palette directory.

        Args:
            tiles_dir: Base tiles directory
            palette: 'day' or 'night'
        """
        self.tiles: Dict[int, Image.Image] = {}
        self.palette = palette

        # Load all 256 tiles
        tile_path = os.path.join(tiles_dir, f'palette_{palette}')
        for tile_num in range(256):
            filename = f'tile_{tile_num:03d}_0x{tile_num:02X}.png'
            filepath = os.path.join(tile_path, filename)

            if os.path.exists(filepath):
                self.tiles[tile_num] = Image.open(filepath)
            else:
                # Create blank tile if missing
                self.tiles[tile_num] = Image.new('RGB', (16, 8), (0, 0, 0))

    def get_tile(self, tile_num: int) -> Image.Image:
        """Get a tile by number (0-255)."""
        return self.tiles.get(tile_num, self.tiles[0])


class BlockScript:
    """Represents a parsed building block script."""

    def __init__(self, block_id: int, description: str, bytecode: List[int]):
        self.block_id = block_id
        self.description = description
        self.bytecode = bytecode


class BlockInterpreter:
    """Interprets and executes building block scripts."""

    def __init__(self, tile_library: TileLibrary):
        self.tiles = tile_library
        self.canvas: Optional[Image.Image] = None

        # Drawing state
        self.tile_x = 0
        self.tile_y = 0
        self.position_stack = []

        # Parameters (used by scripts)
        self.param1 = 0
        self.param2 = 0

        # Registers (used by scripts)
        self.registers = {}

    def reset_state(self):
        """Reset interpreter state."""
        self.tile_x = 0
        self.tile_y = 0
        self.position_stack = []
        self.param1 = 0
        self.param2 = 0
        self.registers = {}

    def execute_script(self, script: BlockScript, canvas: Image.Image,
                       start_x: int, start_y: int,
                       param1: int = 1, param2: int = 1):
        """
        Execute a building block script.

        Args:
            script: The block script to execute
            canvas: Image to draw on
            start_x: Starting X position (in tiles)
            start_y: Starting Y position (in tiles)
            param1: Parameter 1 (often width/columns)
            param2: Parameter 2 (often height/rows)
        """
        self.canvas = canvas
        self.tile_x = start_x
        self.tile_y = start_y
        self.param1 = param1
        self.param2 = param2
        self.reset_state()

        # Execute bytecode
        pc = 0  # Program counter
        bytecode = script.bytecode

        while pc < len(bytecode):
            opcode = bytecode[pc]
            pc += 1

            if opcode == 0xFF:  # End
                break

            elif opcode == 0xF9:  # pintaTile - paint tile
                # F9 followed by tile number(s)
                if pc < len(bytecode):
                    tile_num = bytecode[pc]
                    pc += 1
                    self.draw_tile(tile_num)

                # Check for additional tiles (some commands draw multiple)
                # F9 61 80 61 means draw three tiles
                while pc < len(bytecode) and bytecode[pc] not in [0xF3, 0xF4, 0xF5, 0xF6, 0xFA, 0xFB, 0xFC, 0xFD, 0xFE, 0xFF]:
                    if bytecode[pc] >= 0x80:  # Looks like another tile or modifier
                        tile_num = bytecode[pc]
                        pc += 1
                        if tile_num < 0x80:  # Valid tile number
                            self.tile_y -= 1  # Multiple tiles drawn vertically
                            self.draw_tile(tile_num)
                    else:
                        tile_num = bytecode[pc]
                        pc += 1
                        if tile_num < 0x80:
                            self.tile_y -= 1
                            self.draw_tile(tile_num)

            elif opcode == 0xFC:  # pushTilePos - save position
                self.position_stack.append((self.tile_x, self.tile_y))

            elif opcode == 0xFB:  # popTilePos - restore position
                if self.position_stack:
                    self.tile_x, self.tile_y = self.position_stack.pop()

            elif opcode == 0xF5:  # incTilePosX - move right
                self.tile_x += 1

            elif opcode == 0xF6:  # incTilePosY - move down
                self.tile_y += 1

            elif opcode == 0xF4:  # decTilePosY - move up
                self.tile_y -= 1

            elif opcode == 0xF3:  # decTilePosX - move left
                self.tile_x -= 1

            elif opcode == 0xE0:  # IncParam1
                self.param1 += 1

            elif opcode == 0xEF:  # IncParam2
                self.param2 += 1

            elif opcode == 0xFD:  # while (param2 > 0) - start loop
                loop_start = pc
                loop_depth = 1

                # Find matching FA (end of loop)
                while self.param2 > 0:
                    # Execute loop body
                    temp_pc = loop_start
                    inner_depth = 0

                    while temp_pc < len(bytecode):
                        inner_opcode = bytecode[temp_pc]
                        temp_pc += 1

                        if inner_opcode == 0xFD or inner_opcode == 0xFE:
                            inner_depth += 1
                        elif inner_opcode == 0xFA:
                            if inner_depth == 0:
                                break
                            inner_depth -= 1
                        else:
                            # Execute this instruction recursively
                            # (simplified - in reality would need full recursion)
                            pass

                    self.param2 -= 1

                # Skip to after the loop
                depth = 1
                while pc < len(bytecode) and depth > 0:
                    if bytecode[pc] == 0xFD or bytecode[pc] == 0xFE:
                        depth += 1
                    elif bytecode[pc] == 0xFA:
                        depth -= 1
                    pc += 1

            elif opcode == 0xFE:  # while (param1 > 0) - start loop
                # Similar to 0xFD but for param1
                # Skip for now - complex to implement correctly
                pass

            # Skip other complex opcodes for this initial implementation

    def draw_tile(self, tile_num: int):
        """Draw a tile at the current position."""
        if not self.canvas:
            return

        tile = self.tiles.get_tile(tile_num)

        # Calculate pixel position (each tile is 16x8)
        pixel_x = self.tile_x * 16
        pixel_y = self.tile_y * 8

        # Paste tile onto canvas
        try:
            self.canvas.paste(tile, (pixel_x, pixel_y))
        except:
            pass  # Out of bounds


class BlockLibrary:
    """Manages the 96 building block scripts."""

    def __init__(self):
        self.blocks: Dict[int, BlockScript] = {}

    def add_block(self, block: BlockScript):
        """Add a block script to the library."""
        self.blocks[block.block_id] = block

    def get_block(self, block_id: int) -> Optional[BlockScript]:
        """Get a block by ID."""
        return self.blocks.get(block_id)

    def load_from_asm(self, asm_file: str):
        """
        Parse building block scripts from the .asm file.

        This is a simplified parser that extracts basic block information.
        A full parser would need to traverse the code and extract bytecode.
        """
        # For this demo, we'll manually create a few key blocks
        # A full implementation would parse all 96 from the .asm file

        # Block 0x0D - Floor tiles (simplified version)
        floor_script = BlockScript(
            block_id=0x0D,
            description="Floor of thick blue tiles",
            bytecode=[
                0xE0,  # IncParam1
                0xEF,  # IncParam2
                # Simplified: just draw a grid
                0xFF   # End
            ]
        )
        self.add_block(floor_script)


def create_simple_blocks():
    """Create simplified versions of key building blocks for demonstration."""
    library = BlockLibrary()

    # Block 0x10 - Yellow floor (simplified)
    yellow_floor = BlockScript(
        block_id=0x10,
        description="Floor of yellow tiles",
        bytecode=[0xF9, 0x20, 0xFF]  # Draw tile 0x20, end
    )
    library.add_block(yellow_floor)

    # Block 0x01 - Thin black brick wall (simplified)
    black_wall = BlockScript(
        block_id=0x01,
        description="Thin black brick parallel to y",
        bytecode=[0xF9, 0x30, 0xFF]  # Draw tile 0x30, end
    )
    library.add_block(black_wall)

    # Block 0x09 - White column (simplified)
    white_column = BlockScript(
        block_id=0x09,
        description="White column",
        bytecode=[0xF9, 0x40, 0xFF]  # Draw tile 0x40, end
    )
    library.add_block(white_column)

    return library


def render_example_scene():
    """Create an example scene combining multiple building blocks."""

    print("=" * 60)
    print("Abbey Block Renderer - Example Scene")
    print("=" * 60)

    # Load tiles
    print("\nLoading tile library...")
    tiles = TileLibrary('tiles', palette='day')
    print(f"Loaded {len(tiles.tiles)} tiles")

    # Create block library
    print("\nCreating block library...")
    blocks = create_simple_blocks()
    print(f"Created {len(blocks.blocks)} building blocks")

    # Create interpreter
    interpreter = BlockInterpreter(tiles)

    # Create canvas (40 tiles wide x 30 tiles tall = 640x240 pixels)
    canvas_width = 40 * 16  # 640 pixels
    canvas_height = 30 * 8  # 240 pixels
    canvas = Image.new('RGB', (canvas_width, canvas_height), (0, 0, 0))

    print("\nRendering example scene...")
    print(f"Canvas size: {canvas_width}x{canvas_height} pixels")

    # Draw a floor (using actual floor tiles from the game)
    print("  - Drawing floor...")
    for y in range(10, 20):  # 10 rows
        for x in range(5, 25):  # 20 columns
            # Use tile 0x20 for floor
            tile = tiles.get_tile(0x20)
            canvas.paste(tile, (x * 16, y * 8))

    # Draw some walls
    print("  - Drawing walls...")
    for y in range(10, 20):
        # Left wall
        tile = tiles.get_tile(0x30)
        canvas.paste(tile, (4 * 16, y * 8))
        # Right wall
        canvas.paste(tile, (25 * 16, y * 8))

    # Draw columns
    print("  - Drawing columns...")
    for y in range(11, 19):
        # Left column
        tile = tiles.get_tile(0x50)
        canvas.paste(tile, (8 * 16, y * 8))
        # Right column
        canvas.paste(tile, (21 * 16, y * 8))

    # Save the result
    output_file = "abbey_scene_example.png"
    canvas.save(output_file)
    print(f"\nScene saved to: {output_file}")
    print(f"Size: {os.path.getsize(output_file)} bytes")

    print("\n" + "=" * 60)
    print("DONE!")
    print("=" * 60)
    print("\nNote: This is a simplified demonstration.")
    print("A full implementation would:")
    print("  1. Parse all 96 block scripts from the .asm file")
    print("  2. Implement the complete bytecode interpreter")
    print("  3. Handle loops, parameters, and complex logic")
    print("  4. Support all drawing commands and transformations")


if __name__ == "__main__":
    render_example_scene()
