#!/usr/bin/env python3
"""
Extract all 96 building block scripts from the .asm file and convert them to Python functions.

This script parses the material table and extracts the bytecode for each building block,
then generates Python functions that can render each block.
"""

import re
import os

# Material table with all 96 blocks
MATERIAL_TABLE = {
    0x00: (0x0000, "(null/empty block)"),
    0x01: (0x1973, "Thin black brick parallel to y"),
    0x02: (0x196E, "Thin red brick parallel to x"),
    0x03: (0x193C, "Thick black brick parallel to y"),
    0x04: (0x1941, "Thick red brick parallel to x"),
    0x05: (0x1946, "Small windows block, slightly rounded and black parallel to y axis"),
    0x06: (0x194B, "Small windows block, slightly rounded and red parallel to x axis"),
    0x07: (0x1950, "Red railing parallel to y axis"),
    0x08: (0x1955, "Red railing parallel to x axis"),
    0x09: (0x195A, "White column parallel to y axis"),
    0x0A: (0x1969, "White column parallel to x axis"),
    0x0B: (0x1AEF, "Stairs with black brick on the edge parallel to y axis"),
    0x0C: (0x1B28, "Stairs with red brick on the edge parallel to x axis"),
    0x0D: (0x1BA0, "Floor of thick blue tiles"),
    0x0E: (0x1BA5, "Floor of red and blue tiles forming a checkerboard effect"),
    0x0F: (0x1BAA, "Floor of blue tiles"),
    0x10: (0x1BAF, "Floor of yellow tiles"),
    0x11: (0x1CB8, "Block of arches passing through pairs of columns parallel to y axis"),
    0x12: (0x1CFD, "Block of arches passing through pairs of columns parallel to x axis"),
    0x13: (0x1D23, "Block of arches with columns parallel to y axis"),
    0x14: (0x1D48, "Block of arches with columns parallel to x axis"),
    0x15: (0x1F5F, "Double yellow rivet on the brick parallel to y axis"),
    0x16: (0x1F64, "Double yellow rivet on the brick parallel to x axis"),
    0x17: (0x17FE, "Solid block of thin brick parallel to x axis"),
    0x18: (0x18A6, "Solid block of thin brick parallel to y axis"),
    0x19: (0x17F9, "White table parallel to x axis"),
    0x1A: (0x18A1, "White table parallel to y axis"),
    0x1B: (0x1932, "Small discharge pillar placed next to a wall on x axis"),
    0x1C: (0x1B9B, "Red and black terrain area"),
    0x1D: (0x1E0F, "Bookshelves parallel to y axis"),
    0x1E: (0x1E33, "Bed"),
    0x1F: (0x1E5F, "Large blue and yellow windows parallel to y axis"),
    0x20: (0x1E9D, "Large blue and yellow windows parallel to x axis"),
    0x21: (0x1ECC, "Candelabras with 2 candles parallel to x axis"),
    0x22: (0x1ED6, "(no-op/empty)"),
    0x23: (0x1EDE, "Yellow rivet with support parallel to y axis"),
    0x24: (0x18DA, "Red railing corner"),
    0x25: (0x1EE3, "Yellow rivet with support parallel to x axis"),
    0x26: (0x18EF, "Red railing corner (variant 2)"),
    0x27: (0x1F1A, "Rounded passage hole with thin red and black bricks parallel to x axis"),
    0x28: (0x192D, "Small windows block, rectangular and black parallel to y axis"),
    0x29: (0x1928, "Small windows block, rectangular and red parallel to x axis"),
    0x2A: (0x191E, "1 bottle and a jar"),
    0x2B: (0x1925, "(no-op/empty)"),
    0x2C: (0x1AE9, "Stairs with black brick on the edge parallel to y axis (variant 2)"),
    0x2D: (0x1A99, "Stairs with red brick on the edge parallel to x axis (variant 2)"),
    0x2E: (0x1726, "Rectangular passage hole with thin black bricks parallel to y axis"),
    0x2F: (0x177C, "Rectangular passage hole with thin red bricks parallel to x axis"),
    0x30: (0x17A4, "Thin black and red brick corner"),
    0x31: (0x17AE, "Thick black and red brick corner"),
    0x32: (0x1EE8, "Rounded passage hole with thin black and red bricks parallel to y axis"),
    0x33: (0x1C86, "Yellow rivet corner with support"),
    0x34: (0x1C96, "Yellow rivet corner"),
    0x35: (0x17B8, "(no-op/empty)"),
    0x36: (0x1903, "Red railing corner (variant 3)"),
    0x37: (0x1F76, "Thin red and black brick pyramid"),
    0x38: (0x18AB, "Solid block of thin red and black brick, with yellow and black tiles on top, parallel to y axis"),
    0x39: (0x1803, "Solid block of thin red and black brick, with yellow and black tiles on top, parallel to x axis"),
    0x3A: (0x18CD, "Solid block of thin red and black brick, with yellow and black tiles on top, that grows upwards"),
    0x3B: (0x1EC6, "Candelabras with 2 candles parallel to x axis (variant 2)"),
    0x3C: (0x1EA3, "Candelabras with 2 candles parallel to y axis"),
    0x3D: (0x1ED1, "Candelabras with wall support and 2 candles parallel to y axis"),
    0x3E: (0x1937, "Small discharge pillar placed next to a wall on y axis"),
    0x3F: (0x18B1, "Thin black and red brick corner (variant 2)"),
    0x40: (0x18BF, "Thin black and red brick corner (variant 3)"),
    0x41: (0x1F80, "Thin red brick forming a right triangle parallel to x axis"),
    0x42: (0x1F86, "Thin black brick forming a right triangle parallel to y axis"),
    0x43: (0x1F2B, "Rounded passage hole with thin red and black bricks parallel to y axis, with thick pillars between holes"),
    0x44: (0x1F59, "Rounded passage hole with thin red and black bricks parallel to x axis, with thick pillars between holes"),
    0x45: (0x1D99, "Bench to sit on parallel to x axis"),
    0x46: (0x1D6B, "Bench to sit on parallel to y axis"),
    0x47: (0x1797, "Very low thin black and red brick corner"),
    0x48: (0x178A, "Very low thick black and red brick corner"),
    0x49: (0x1B96, "Flat corner delimited with black line and blue floor"),
    0x4A: (0x1D9F, "Work table"),
    0x4B: (0x1DD8, "Plates"),
    0x4C: (0x1DFC, "Bottles with handles"),
    0x4D: (0x1E06, "Cauldron"),
    0x4E: (0x1BB4, "Flat corner delimited with black line and yellow floor"),
    0x4F: (0x17EF, "Solid block of thin red and black brick, with blue tiles on top, parallel to y axis"),
    0x50: (0x17F4, "Solid block of thin red and black brick, with blue top, parallel to y axis"),
    0x51: (0x1897, "Solid block of thin red and black brick, with blue tiles on top, parallel to x axis"),
    0x52: (0x189C, "Solid block of thin red and black brick, with blue top, parallel to x axis"),
    0x53: (0x17BB, "Solid block of thin red and black brick, with blue tiles on top and stair-stepped, parallel to x axis"),
    0x54: (0x17E7, "Solid block of thin red and black brick, with blue top and stair-stepped, parallel to x axis"),
    0x55: (0x1841, "Solid block of thin red and black brick, with blue tiles on top and stair-stepped, parallel to y axis"),
    0x56: (0x186D, "Solid block of thin red and black brick, with blue top and stair-stepped, parallel to y axis"),
    0x57: (0x1DDD, "Human skulls"),
    0x58: (0x1B91, "Skeleton remains"),
    0x59: (0x1914, "Monster face with horns"),
    0x5A: (0x1919, "Support with cross"),
    0x5B: (0x1E01, "Large cross"),
    0x5C: (0x1F69, "Library books parallel to x axis"),
    0x5D: (0x1ED9, "Library books parallel to y axis"),
    0x5E: (0x195F, "Top of a wall with small slightly rounded and black window parallel to y axis"),
    0x5F: (0x1964, "Top of a wall with small slightly rounded and red window parallel to x axis"),
}


def find_line_with_address(asm_file, address):
    """Find the line number for a given hex address in the .asm file."""
    addr_str = f"{address:04X}:"

    with open(asm_file, 'r') as f:
        for line_num, line in enumerate(f, 1):
            if line.strip().startswith(addr_str):
                return line_num
    return None


def extract_script_data(asm_file, start_address, max_lines=50):
    """
    Extract bytecode/data from an address in the .asm file.

    Returns a list of data found at that address.
    """
    line_num = find_line_with_address(asm_file, start_address)

    if not line_num:
        return []

    data = []

    with open(asm_file, 'r') as f:
        lines = f.readlines()

        # Start reading from the found line
        for i in range(line_num - 1, min(line_num + max_lines, len(lines))):
            line = lines[i].strip()

            # Skip blank lines and comments that are just comments
            if not line or line.startswith(';'):
                continue

            # Look for data definitions or interpreted pseudocode
            # Pattern like: "F9 61" or "FC" or "EA 1990"
            if re.search(r'^[0-9A-F]{2,4}(\s+[0-9A-F]{2})+', line):
                # Skip this - it's assembly/bytecode mixed
                continue

            # Look for the interpreted pseudocode format
            # Like: "F9 61 80 61    pintaTile(61, 0x80, 0x61);"
            if any(cmd in line for cmd in ['pintaTile', 'pushTilePos', 'popTilePos', 'UpdateReg',
                                            'IncParam', 'while', 'FlipX', 'ChangePC']):
                data.append(line)

            # Look for FF (end marker)
            if line.startswith('FF') or 'FF' in line.split()[:2]:
                data.append('FF  // End')
                break

    return data


def generate_python_function(block_id, address, description, script_data):
    """Generate a Python function for a building block."""

    func_name = f"block_{block_id:02X}_{description.lower().replace(' ', '_').replace(',', '').replace('(', '').replace(')', '').replace('-', '_')[:40]}"

    # Clean up function name
    func_name = re.sub(r'[^a-z0-9_]', '', func_name)

    func_code = f'''def {func_name}(canvas, tiles, x, y, param1=1, param2=1):
    """
    Block 0x{block_id:02X} - {description}
    Address: 0x{address:04X}

    Args:
        canvas: AbbeyCanvas to draw on
        tiles: AbbeyTiles library
        x, y: Starting position (in tiles)
        param1, param2: Block parameters (width/height)
    """
    # Script data from address 0x{address:04X}:
'''

    if script_data:
        for line in script_data[:10]:  # Limit to first 10 lines
            func_code += f"    # {line}\n"
    else:
        func_code += "    # (No script data extracted - may need manual implementation)\n"

    func_code += f'''
    # TODO: Implement bytecode interpreter for this block
    # For now, using simplified placeholder
    pass
'''

    return func_code


def main():
    asm_file = "abadia_del_crimen_disassembled_CPC_Amstrad_game_code.asm"

    print("=" * 70)
    print("EXTRACTING 96 BUILDING BLOCK SCRIPTS")
    print("=" * 70)

    output_file = "abbey_blocks_library.py"

    with open(output_file, 'w') as out:
        out.write('''#!/usr/bin/env python3
"""
Complete Library of 96 Building Block Functions for "La Abadía del Crimen"

Auto-generated from the game's .asm file.
Each function represents one of the 96 architectural building blocks.

These blocks are NOT bitmaps - they are small programs (bytecode scripts)
that tell the game engine how to compose base tiles into larger structures.
"""

# This would import the canvas and tiles from abbey_architect.py
# from abbey_architect import AbbeyCanvas, AbbeyTiles


''')

        extracted_count = 0

        for block_id in sorted(MATERIAL_TABLE.keys()):
            address, description = MATERIAL_TABLE[block_id]

            print(f"\n[{block_id:02X}] Extracting block at 0x{address:04X}: {description}")

            # Extract script data
            script_data = extract_script_data(asm_file, address) if address > 0 else []

            if script_data:
                print(f"     Found {len(script_data)} lines of script data")
                extracted_count += 1
            else:
                print(f"     (No script data found - may be empty or complex)")

            # Generate Python function
            func_code = generate_python_function(block_id, address, description, script_data)

            out.write(func_code)
            out.write("\n\n")

    print("\n" + "=" * 70)
    print(f"EXTRACTION COMPLETE!")
    print("=" * 70)
    print(f"Generated: {output_file}")
    print(f"Total blocks: {len(MATERIAL_TABLE)}")
    print(f"Blocks with extracted data: {extracted_count}")
    print(f"Empty/complex blocks: {len(MATERIAL_TABLE) - extracted_count}")
    print("\nNext steps:")
    print("  1. Review the generated functions in abbey_blocks_library.py")
    print("  2. Implement the bytecode interpreter for each block")
    print("  3. Test rendering each block individually")
    print("=" * 70)


if __name__ == "__main__":
    main()
