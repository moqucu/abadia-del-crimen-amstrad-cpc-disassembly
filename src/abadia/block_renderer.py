#!/usr/bin/env python3
"""
Test Renderer for Abadia Interpreter.
Renders specific building blocks using the extracted scripts and new interpreter.
"""

import os
from src.abadia.graphics import AbbeyTiles, AbbeyCanvas
from src.abadia.interpreter import AbadiaInterpreter
from src.abadia.abbey_blocks_library import BLOCK_DEFINITIONS

def render_block(block_id, output_name):
    if block_id not in BLOCK_DEFINITIONS:
        print(f"Block 0x{block_id:02X} not found in library.")
        return

    print(f"Rendering Block 0x{block_id:02X}...")
    block = BLOCK_DEFINITIONS[block_id]
    print(f"  Description: {block.description}")
    
    # Setup
    tiles = AbbeyTiles()
    canvas = AbbeyCanvas(20, 20, bg_color=(50, 50, 50))
    interpreter = AbadiaInterpreter(tiles)
    
    # Execute
    # Start at center (10, 10)
    # try:
    interpreter.execute(block, canvas, 10, 10, param1=4, param2=4)
    
    # Save
    filename = f"block_0x{block_id:02X}_{output_name}.png"
    canvas.save(filename)
    print(f"  Saved to {filename}")
    # except Exception as e:
    #     print(f"  Error: {e}")

def main():
    # Render a few interesting blocks
    render_block(0x01, "thin_black_wall_y")
    render_block(0x02, "thin_red_wall_x")
    render_block(0x0D, "blue_floor")
    render_block(0x4A, "work_table")
    # render_block(0x11, "arch_y") # Complex

if __name__ == "__main__":
    main()