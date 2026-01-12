#!/usr/bin/env python3
"""
Add the missing critical blocks to abbey_blocks_library.py

Based on the Material Table analysis, these blocks are missing but heavily used:
0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x1A, 0x1B, 0x1C, 0x1E, 0x1F, 0x2A, 0x2B, 0x2C, 0x2D,
0x2E, 0x2F, 0x3A, 0x3C, 0x3D, 0x3E, 0x3F, 0x4A, 0x4B, 0x4F, 0x5B, 0x68, 0x69, 0x74, 0x79,
0x7A, 0x7D, 0x7E
"""

import os
import re

# Missing blocks from Material Table (lines 2720-2760)
MISSING_BLOCKS = {
    0x0A: ("1969", "white column parallel to the x axis"),
    0x0B: ("1AEF", "stairs with black brick on the edge parallel to the y axis"),
    0x0C: ("1B28", "stairs with red brick on the edge parallel to the x axis"),
    0x0D: ("1BA0", "floor of thick blue tiles"),
    0x0E: ("1BA5", "floor of red and blue tiles forming a checkerboard effect"),
    0x0F: ("1BAA", "floor of blue tiles"),
    0x1A: ("18A1", "white table parallel to the y axis"),
    0x1B: ("1932", "small discharge pillar placed next to a wall on the x axis"),
    0x1C: ("1B9B", "red and black terrain area"),
    0x1E: ("1E33", "bed"),
    0x1F: ("1E5F", "large blue and yellow windows parallel to the y axis"),
    0x2A: ("191E", "1 bottle and a jar"),
    0x2B: ("1925", "does nothing"),
    0x2C: ("1AE9", "stairs with black brick on the edge parallel to the y axis (2)"),
    0x2D: ("1A99", "stairs with red brick on the edge parallel to the x axis (2)"),
    0x2E: ("1726", "rectangular passage hole with thin black bricks parallel to the y axis"),
    0x2F: ("177C", "rectangular passage hole with thin red bricks parallel to the x axis"),
    0x3A: ("18C5", "thin black and red brick corner (4)"),
    0x3C: ("1B80", "railing and wooden floor corner"),
    0x3D: ("1B86", "railing and wooden floor corner (2)"),
    0x3E: ("1D6F", "piece of furniture parallel to the y axis"),
    0x3F: ("1DA5", "piece of furniture parallel to the x axis"),
    0x4A: ("1778", "work table"),
    0x4B: ("17BA", "does nothing"),
    0x4F: ("17BB", "does nothing"),
    0x5B: ("1F69", "thin black brick forming a right triangle parallel to the y axis (2)"),
    0x68: ("1E5F", "large blue and yellow windows parallel to the y axis"), # duplicate of 0x1F
    0x69: ("1E9D", "large blue and yellow windows parallel to the x axis"), # duplicate of 0x20
    0x74: ("1C86", "yellow rivet corner with support"), # duplicate of 0x33
    0x79: ("178F", "does nothing"),
    0x7A: ("1E66", "bookshelves parallel to the x axis"),
    0x7D: ("1D03", "block of arches with columns parallel to the y axis (2)"),
    0x7E: ("1D2E", "block of arches with columns parallel to the x axis (2)"),
}

def load_memory():
    """Load the memory map"""
    mem_file = 'src/abadia/resources/abbey_code.bin'
    if not os.path.exists(mem_file):
        print(f"Error: {mem_file} not found")
        return None

    with open(mem_file, 'rb') as f:
        return bytearray(f.read())

def extract_block_bytecode(memory, addr):
    """Extract bytecode starting from address"""
    bytecode = []
    pc = addr + 2  # Skip tile pointer

    while pc < len(memory):
        opcode = memory[pc]
        bytecode.append(opcode)
        pc += 1

        if opcode == 0xFF:  # End marker
            break

        if len(bytecode) > 200:  # Safety limit
            break

    return bytecode

def extract_tile_data(memory, tile_ptr):
    """Extract 12 bytes of tile data"""
    tile_data = []
    for i in range(12):
        if tile_ptr + i < len(memory):
            tile_data.append(memory[tile_ptr + i])
        else:
            tile_data.append(0)
    return tile_data

def main():
    print("Loading memory...")
    memory = load_memory()
    if memory is None:
        return

    print(f"\nExtracting {len(MISSING_BLOCKS)} missing blocks...")

    # Read existing library
    lib_file = 'src/abadia/abbey_blocks_library.py'
    with open(lib_file, 'r') as f:
        content = f.read()

    # Find the end of BLOCK_DEFINITIONS
    end_marker = "}"
    last_bracket = content.rfind(end_marker)

    if last_bracket == -1:
        print("Error: Could not find end of BLOCK_DEFINITIONS")
        return

    # Prepare new entries
    new_entries = []

    for block_id, (addr_str, desc) in sorted(MISSING_BLOCKS.items()):
        addr = int(addr_str, 16)

        # Read tile pointer
        # The ASM file already shows bytes in their memory order
        # So read them as-is: first byte goes to high, second to low
        if addr + 1 >= len(memory):
            print(f"Warning: Block 0x{block_id:02X} address 0x{addr:04X} out of range")
            continue

        byte0 = memory[addr]      # First byte in ASM
        byte1 = memory[addr + 1]  # Second byte in ASM
        tile_ptr = (byte0 << 8) | byte1  # ASM shows them in this order

        # Extract bytecode and tile data
        bytecode = extract_block_bytecode(memory, addr)
        tile_data = extract_tile_data(memory, tile_ptr)

        # Format entry
        bytecode_hex = ", ".join(f"0x{x:02X}" for x in bytecode)
        tile_data_hex = ", ".join(f"0x{x:02X}" for x in tile_data)

        entry = f"""    0x{block_id:02X}: BlockDef(
        block_id=0x{block_id:02X},
        description="{desc}",
        address=0x{addr:04X},
        tile_ptr=0x{tile_ptr:04X},
        tile_data=[{tile_data_hex}],
        bytecode=[{bytecode_hex}]
    ),
"""
        new_entries.append(entry)
        print(f"  Extracted 0x{block_id:02X}: {desc[:50]}...")

    # Insert new entries before the closing brace
    new_content = content[:last_bracket] + "".join(new_entries) + content[last_bracket:]

    # Write back
    with open(lib_file, 'w') as f:
        f.write(new_content)

    print(f"\nAdded {len(new_entries)} blocks to {lib_file}")
    print("Block library now has all critical missing blocks!")

if __name__ == "__main__":
    main()
