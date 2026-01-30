#!/usr/bin/env python3
"""
Extract and visualize the 256 base tiles from "La Abadía del Crimen"

This script extracts the 16x8 pixel tiles from the disassembled game code and saves them as PNG images.
The tiles are stored in Amstrad CPC Mode 1 format (4 colors, 2 bits per pixel).

Each tile is 32 bytes:
- 16 pixels wide (4 bytes per scanline in Mode 1)
- 8 scanlines tall
- Total: 256 tiles (0x00 to 0xFF)

The tile data is located in the .asm file at addresses 8300-A2FF (8192 bytes).

COLOR MAPPING AND TRANSPARENCY:
-------------------------------
The color/transparency mappings below were reverse-engineered empirically by comparing
output with the original game. They produce pixel-perfect matches with game screenshots.

1. **Tiles 0-10:** Fully opaque floor tiles, no transparency needed.

2. **Tiles 11-127:** Pen 1 is transparent, others opaque.
   - Pen 0 → Cyan, Pen 1 → Transparent, Pen 2 → Orange, Pen 3 → Black

3. **Tiles 128-255:** Pen 2 is transparent, others opaque.
   - Pen 0 → Cyan, Pen 1 → Yellow, Pen 2 → Transparent, Pen 3 → Black

NOTE ON LOOKUP TABLES (0x9D00-0xA0FF):
--------------------------------------
The original game has AND/OR lookup tables at addresses 0x9D00-0xA0FF that the assembly
code at 0x4E49 references. However, direct application of these tables produces dithered
color patterns (e.g., [0,1,1,0] instead of solid colors), which do NOT match the actual
game output. The tables may be used for sprite compositing or other effects, not regular
tile rendering. The empirical mappings above correctly reproduce the game's visuals.
"""

import re
import os
import shutil
from PIL import Image
from abadia.cpc_palette import CpcPalette

# Default paths
DEFAULT_ASM_FILE = "translated_english_files/0 - abadia_del_crimen_disassembled_CPC_Amstrad_game_code.asm"
DEFAULT_OUTPUT_DIR = "python_scripts/resources/tiles"

def get_palette_colors(palette_name='day'):
    """
    Get RGB colors for a palette.

    Args:
        palette_name: 'day' or 'night'

    Returns:
        List of 4 RGB tuples for pens 0-3
    """
    # Use the 'visual' mode to match actual gameplay screenshots
    return CpcPalette.get_palette_for_rendering(palette_name)

def decode_cpc_mode1_byte(byte_val):
    """
    Decode a single byte in CPC Mode 1 format to 4 pixel values.
    Mode 1: 4 pixels per byte, 2 bits per pixel

    Bit layout (MSB to LSB):
    Pixel 0: bits 7,3
    Pixel 1: bits 6,2
    Pixel 2: bits 5,1
    Pixel 3: bits 4,0
    """
    pixels = []
    for i in range(4):
        # Extract bits for this pixel
        bit_high = (byte_val >> (7 - i)) & 1
        bit_low = (byte_val >> (3 - i)) & 1
        pixel_value = (bit_high << 1) | bit_low
        pixels.append(pixel_value)
    return pixels

def tile_to_ascii_matrix(data, tile_number):
    """
    Generate an ASCII matrix representation of a tile for debugging.

    Args:
        data: Raw binary tile data
        tile_number: Tile index (0-255)

    Returns:
        String with ASCII representation showing pen values (0-3) for each pixel
    """
    tile_offset = tile_number * 32
    if tile_offset + 32 > len(data):
        return f"; Tile {tile_number} out of range"

    lines = [f"Tile {tile_number} (0x{tile_number:02X}):"]
    for y in range(8):
        row_pixels = []
        for x_byte in range(4):
            byte_val = data[tile_offset + y * 4 + x_byte]
            row_pixels.extend(decode_cpc_mode1_byte(byte_val))
        lines.append(" ".join(str(p) for p in row_pixels))
    return "\n".join(lines)


def generate_tile_debug_log(data, output_path):
    """
    Generate a debug log file with ASCII matrix representations of all 256 tiles.

    Args:
        data: Raw binary tile data
        output_path: Path to output log file
    """
    lines = [
        "Tile Debug Log - ASCII Matrix Representations",
        "=" * 50,
        "Each tile shown as 16x8 grid of pen values (0-3)",
        "Pen mapping depends on tile range:",
        "  Tiles 0-10:    All pens opaque",
        "  Tiles 11-127:  Pen 1 = transparent",
        "  Tiles 128-255: Pen 2 = transparent",
        "=" * 50,
        ""
    ]

    for tile_num in range(256):
        lines.append(tile_to_ascii_matrix(data, tile_num))
        lines.append("")

    with open(output_path, 'w') as f:
        f.write("\n".join(lines))
    print(f"  Debug log saved to: {output_path}")


def read_graphics_from_asm(asm_file):
    """
    Read the tile graphics data from the disassembled .asm file.

    The data is stored as hex dump lines in the format:
    8300: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00 ................

    We need to extract bytes from address 8300 to A2FF (exclusive).

    Args:
        asm_file: Path to the .asm file

    Returns:
        bytearray containing the graphics data
    """
    graphics_data = bytearray()

    # Pattern to match hex dump lines: "XXXX: HH HH ... HH-HH ... HH ..."
    pattern = re.compile(r'^([0-9A-F]{4}):\s+((?:[0-9A-F]{2}\s+)+[0-9A-F]{2}-(?:[0-9A-F]{2}\s+)+[0-9A-F]{2})')

    with open(asm_file, 'r') as f:
        for line in f:
            match = pattern.match(line.strip())
            if match:
                address = int(match.group(1), 16)

                # Check if this line is in the graphics range
                if 0x8300 <= address < 0xA300:
                    # Extract hex bytes (remove the dash separator)
                    hex_bytes = match.group(2).replace('-', ' ').split()

                    # Convert to bytes and append
                    for hex_byte in hex_bytes:
                        graphics_data.append(int(hex_byte, 16))

    return graphics_data

def extract_tile(data, tile_number, palette='day'):
    """
    Extract a single 16x8 tile from the graphics data.

    Args:
        data: Raw binary data (bytearray or bytes)
        tile_number: Tile index (0-255)
        palette: Palette name ('black', 'day', 'evening', 'night')

    Returns:
        PIL Image object (16x8 pixels)

    Note: Tiles >= 0x80 use different AND/OR lookup tables in the original game
    (tables at 0x9F00/0xA000 vs 0x9D00/0x9E00). This swaps pen 1 and pen 3.
    See assembly code at address 0x4E65 for the bit 7 check.
    """
    # Each tile is 32 bytes
    tile_offset = tile_number * 32

    if tile_offset + 32 > len(data):
        raise ValueError(f"Tile {tile_number} is out of range")

    # Get the palette colors
    palette_colors = get_palette_colors(palette)

    # Tiles >= 11 use masking tables and have different color mappings
    if 11 <= tile_number < 128:
        # Mapping for 11-127:
        # Bit 0 -> Cyan (P0) Opaque
        # Bit 1 -> Transparent
        # Bit 2 -> Orange (P2)
        # Bit 3 -> Black (P3)
        palette_colors = [
            palette_colors[0],  # 0 -> Cyan
            palette_colors[0],  # 1 -> Transparent
            palette_colors[2],  # 2 -> Orange
            palette_colors[3],  # 3 -> Black
        ]
    elif tile_number >= 128:
        # Mapping for 128-255:
        # Bit 0 -> Cyan (P0) Opaque ["0 is cyan"]
        # Bit 1 -> Yellow (P1)      ["1 is yellow"]
        # Bit 2 -> Transparent (P0) ["2 needs to be transparent... I don't see any orange"]
        # Bit 3 -> Black (P3)       ["3 is black"]
        palette_colors = [
            palette_colors[0],  # 0 -> Cyan
            palette_colors[1],  # 1 -> Yellow
            palette_colors[0],  # 2 -> Transparent
            palette_colors[3],  # 3 -> Black
        ]

    # Create an image for this tile (RGBA for transparency)
    img = Image.new('RGBA', (16, 8))
    pixels = img.load()

    # Decode each scanline (8 scanlines total)
    for y in range(8):
        scanline_offset = tile_offset + (y * 4)  # 4 bytes per scanline

        # Decode 4 bytes to get 16 pixels
        for x_byte in range(4):
            byte_val = data[scanline_offset + x_byte]
            pixel_values = decode_cpc_mode1_byte(byte_val)

            # Write the 4 pixels
            for i, pv in enumerate(pixel_values):
                x = x_byte * 4 + i
                
                # Get RGB color
                color = palette_colors[pv]
                
                # Handle transparency logic
                if 11 <= tile_number < 128:
                    # 11-127: Only Bit 1 is transparent
                    if pv == 1:
                        pixels[x, y] = (color[0], color[1], color[2], 0)
                    else:
                        pixels[x, y] = (color[0], color[1], color[2], 255)
                elif tile_number >= 128:
                    # 128-255: Only Bit 2 is transparent
                    if pv == 2:
                        pixels[x, y] = (color[0], color[1], color[2], 0)
                    else:
                        pixels[x, y] = (color[0], color[1], color[2], 255)
                else:
                    # 0-10: Fully opaque background (Pen 0 is visible Cyan)
                    pixels[x, y] = (color[0], color[1], color[2], 255)

    return img

def cleanup_individual_tiles(output_base_dir):
    """Remove legacy individual tile directories."""
    for palette in ['day', 'night']:
        dir_path = os.path.join(output_base_dir, f"palette_{palette}")
        if os.path.exists(dir_path):
            print(f"Removing legacy directory: {dir_path}")
            shutil.rmtree(dir_path)

def generate_tile_maps(asm_path, output_dir, tiles_per_row=16):
    """
    Create tile map images containing all tiles for each palette.
    Saves as 'tiles_day.png' and 'tiles_night.png'.

    Args:
        asm_path: Path to the .asm file
        output_dir: Directory to save the tile maps
        tiles_per_row: Number of tiles per row in the sheet
    """
    # Read graphics data from the .asm file
    print("Reading graphics data from .asm file...")
    graphics_data = read_graphics_from_asm(asm_path)
    generate_tile_maps_from_data(graphics_data, output_dir, tiles_per_row)


def generate_tile_maps_from_data(graphics_data, output_dir, tiles_per_row=16):
    """
    Create tile map images from pre-loaded graphics data.
    Saves as 'tiles_day.png' and 'tiles_night.png'.

    Args:
        graphics_data: Pre-loaded tile graphics data (bytearray)
        output_dir: Directory to save the tile maps
        tiles_per_row: Number of tiles per row in the sheet
    """
    os.makedirs(output_dir, exist_ok=True)

    # Create sprite sheets for each palette
    for palette_name in ['day', 'night']:
        print(f"\nGenerating tile map for '{palette_name}' palette...")

        # Calculate sheet dimensions
        total_tiles = 256
        rows = (total_tiles + tiles_per_row - 1) // tiles_per_row

        # Each tile is 16x8
        # NO SPACING as per requirements for easy programmatic access
        sheet_width = tiles_per_row * 16
        sheet_height = rows * 8

        # Create sprite sheet (RGBA)
        sheet = Image.new('RGBA', (sheet_width, sheet_height), (0, 0, 0, 0))

        for tile_num in range(total_tiles):
            tile_img = extract_tile(graphics_data, tile_num, palette=palette_name)

            # Calculate position in sheet
            row = tile_num // tiles_per_row
            col = tile_num % tiles_per_row
            x = col * 16
            y = row * 8

            # Paste tile into sheet (using alpha compositing)
            sheet.paste(tile_img, (x, y))

        # Save with standard filename
        output_path = os.path.join(output_dir, f'tiles_{palette_name}.png')
        sheet.save(output_path)
        print(f"  Tile map saved to: {output_path}")

if __name__ == "__main__":
    import sys

    # Use default paths or environment overrides
    asm_file = DEFAULT_ASM_FILE
    output_dir = DEFAULT_OUTPUT_DIR

    if not os.path.exists(asm_file):
        print(f"Error: {asm_file} not found")
        sys.exit(1)

    # Cleanup old files
    cleanup_individual_tiles(output_dir)

    # Read graphics data for both tile maps and debug log
    print("Reading graphics data from .asm file...")
    graphics_data = read_graphics_from_asm(asm_file)

    # Create tile maps
    print("\n" + "=" * 60)
    print("Generating Tile Maps...")
    print("=" * 60)
    generate_tile_maps_from_data(graphics_data, output_dir, tiles_per_row=16)

    # Generate debug log
    print("\n" + "=" * 60)
    print("Generating Tile Debug Log...")
    print("=" * 60)
    debug_log_path = os.path.join(output_dir, "tiles_debug.log")
    generate_tile_debug_log(graphics_data, debug_log_path)

    print("\n" + "=" * 60)
    print("DONE!")
    print("=" * 60)
    print(f"\nTile Maps generated in {output_dir}:")
    print(f"  tiles_day.png")
    print(f"  tiles_night.png")
    print(f"\nAccess Formula:")
    print(f"  X = (TileID % 16) * 16")
    print(f"  Y = (TileID // 16) * 8")
