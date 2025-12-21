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
"""

import re
import os
from PIL import Image

# Amstrad CPC hardware colors (27 colors, indexed 0-26)
# Each color is defined by its RGB values
CPC_HARDWARE_COLORS = [
    (0x00, 0x00, 0x00),  # 0x00: Black
    (0x00, 0x00, 0x80),  # 0x01: Blue
    (0x00, 0x00, 0xFF),  # 0x02: Bright Blue
    (0x80, 0x00, 0x00),  # 0x03: Red
    (0x80, 0x00, 0x80),  # 0x04: Magenta
    (0x80, 0x00, 0xFF),  # 0x05: Mauve
    (0xFF, 0x00, 0x00),  # 0x06: Bright Red
    (0xFF, 0x00, 0x80),  # 0x07: Purple
    (0xFF, 0x00, 0xFF),  # 0x08: Bright Magenta
    (0x00, 0x80, 0x00),  # 0x09: Green
    (0x00, 0x80, 0x80),  # 0x0A: Cyan
    (0x00, 0x80, 0xFF),  # 0x0B: Sky Blue
    (0x80, 0x80, 0x00),  # 0x0C: Yellow
    (0x80, 0x80, 0x80),  # 0x0D: White (Gray)
    (0x80, 0x80, 0xFF),  # 0x0E: Pastel Blue
    (0xFF, 0x80, 0x00),  # 0x0F: Orange
    (0xFF, 0x80, 0x80),  # 0x10: Pink
    (0xFF, 0x80, 0xFF),  # 0x11: Pastel Magenta
    (0x00, 0xFF, 0x00),  # 0x12: Bright Green
    (0x00, 0xFF, 0x80),  # 0x13: Sea Green
    (0x00, 0xFF, 0xFF),  # 0x14: Bright Cyan
    (0x80, 0xFF, 0x00),  # 0x15: Lime
    (0x80, 0xFF, 0x80),  # 0x16: Pastel Green
    (0x80, 0xFF, 0xFF),  # 0x17: Pastel Cyan
    (0xFF, 0xFF, 0x00),  # 0x18: Bright Yellow
    (0xFF, 0xFF, 0x80),  # 0x19: Pastel Yellow
    (0xFF, 0xFF, 0xFF),  # 0x1A: Bright White
]

# Game palettes - only 2 palettes used: day and night
# Colors matched from actual CPC game screenshots
# Each palette defines 4 pens (pen 0-3) using CPC hardware color indices
GAME_PALETTES = {
    'day': {
        'pen0': 0x00,  # Black (outlines, text)
        'pen1': 0x14,  # Bright Cyan (floor/background)
        'pen2': 0x0C,  # Yellow (appears orange on CPC - walls, bricks)
        'pen3': 0x1A,  # Bright White (highlights)
    },
    'night': {
        'pen0': 0x00,  # Black (outlines, text)
        'pen1': 0x02,  # Bright Blue (floor/background)
        'pen2': 0x08,  # Bright Magenta (walls, structures)
        'pen3': 0x11,  # Pastel Magenta (highlights)
    },
}

def get_palette_colors(palette_name='day'):
    """
    Get RGB colors for a palette.

    Args:
        palette_name: 'day' or 'night'

    Returns:
        List of 4 RGB tuples for pens 0-3
    """
    palette = GAME_PALETTES.get(palette_name, GAME_PALETTES['day'])

    # Convert hardware color indices to RGB
    rgb_palette = []
    for pen_num in range(4):
        hw_color = palette[f'pen{pen_num}']
        if hw_color < len(CPC_HARDWARE_COLORS):
            rgb_palette.append(CPC_HARDWARE_COLORS[hw_color])
        else:
            # Fallback to black if invalid
            rgb_palette.append((0x00, 0x00, 0x00))

    return rgb_palette

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
    """
    # Each tile is 32 bytes
    tile_offset = tile_number * 32

    if tile_offset + 32 > len(data):
        raise ValueError(f"Tile {tile_number} is out of range")

    # Get the palette colors
    palette_colors = get_palette_colors(palette)

    # Create an image for this tile
    img = Image.new('RGB', (16, 8))
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
                pixels[x, y] = palette_colors[pv]

    return img

def extract_all_tiles(asm_path, output_base_dir):
    """
    Extract all 256 tiles from the disassembled .asm file and save as individual PNG files.
    Creates separate directories for each palette.

    Args:
        asm_path: Path to the .asm file
        output_base_dir: Base directory to save tile images
    """
    # Read graphics data from the .asm file
    print("Reading graphics data from .asm file...")
    graphics_data = read_graphics_from_asm(asm_path)

    print(f"Read {len(graphics_data)} bytes of graphics data")
    print(f"Expected tiles: {len(graphics_data) // 32}")

    # Extract tiles for each palette
    for palette_name in ['day', 'night']:
        print(f"\nExtracting tiles with '{palette_name}' palette...")

        # Create output directory for this palette
        output_dir = os.path.join(output_base_dir, f"palette_{palette_name}")
        os.makedirs(output_dir, exist_ok=True)

        # Extract each tile
        for tile_num in range(256):
            try:
                tile_img = extract_tile(graphics_data, tile_num, palette=palette_name)

                # Save as PNG
                output_path = os.path.join(output_dir, f"tile_{tile_num:03d}_0x{tile_num:02X}.png")
                tile_img.save(output_path)

                if tile_num % 64 == 0:
                    print(f"  Extracted tile {tile_num}/256...")

            except Exception as e:
                print(f"  Error extracting tile {tile_num}: {e}")

        print(f"  Completed {palette_name} palette tiles")

def create_tile_sheet(asm_path, output_base_path, tiles_per_row=16):
    """
    Create sprite sheet images containing all tiles for each palette.

    Args:
        asm_path: Path to the .asm file
        output_base_path: Base path for saving sprite sheets (palette name will be added)
        tiles_per_row: Number of tiles per row in the sheet
    """
    # Read graphics data from the .asm file
    print("Reading graphics data from .asm file...")
    graphics_data = read_graphics_from_asm(asm_path)

    # Create sprite sheets for each palette
    for palette_name in ['day', 'night']:
        print(f"\nCreating sprite sheet for '{palette_name}' palette...")

        # Calculate sheet dimensions
        total_tiles = 256
        rows = (total_tiles + tiles_per_row - 1) // tiles_per_row

        # Each tile is 16x8, add 1 pixel spacing
        sheet_width = tiles_per_row * 17  # 16 pixels + 1 spacing
        sheet_height = rows * 9  # 8 pixels + 1 spacing

        # Create sprite sheet
        sheet = Image.new('RGB', (sheet_width, sheet_height), (0x40, 0x40, 0x40))

        for tile_num in range(total_tiles):
            tile_img = extract_tile(graphics_data, tile_num, palette=palette_name)

            # Calculate position in sheet
            row = tile_num // tiles_per_row
            col = tile_num % tiles_per_row
            x = col * 17
            y = row * 9

            # Paste tile into sheet
            sheet.paste(tile_img, (x, y))

            if tile_num % 64 == 0:
                print(f"  Processing tile {tile_num}/256...")

        # Save with palette name in filename
        output_path = output_base_path.replace('.png', f'_{palette_name}.png')
        sheet.save(output_path)
        print(f"  Sprite sheet saved to: {output_path}")

if __name__ == "__main__":
    import sys

    # Check if the .asm file exists in current directory
    asm_file = "abadia_del_crimen_disassembled_CPC_Amstrad_game_code.asm"

    if not os.path.exists(asm_file):
        print(f"Error: {asm_file} not found in current directory")
        print("\nUsage:")
        print("  1. Ensure the disassembled .asm file is in the same directory as this script")
        print("  2. Run: python3 extract_tiles.py")
        print("\nThe script will extract tile graphics from addresses 8300-A2FF in the .asm file")
        sys.exit(1)

    # Extract individual tiles
    print("=" * 60)
    print("Extracting individual tiles from .asm file...")
    print("=" * 60)
    extract_all_tiles(asm_file, "tiles")

    # Create sprite sheets
    print("\n" + "=" * 60)
    print("Creating sprite sheets...")
    print("=" * 60)
    create_tile_sheet(asm_file, "abbey_tiles_spritesheet.png", tiles_per_row=16)

    print("\n" + "=" * 60)
    print("DONE!")
    print("=" * 60)
    print(f"\nIndividual tiles organized by palette:")
    print(f"  ./tiles/palette_day/    (256 tiles)")
    print(f"  ./tiles/palette_night/  (256 tiles)")
    print(f"\nSprite sheets:")
    print(f"  ./abbey_tiles_spritesheet_day.png")
    print(f"  ./abbey_tiles_spritesheet_night.png")
    print("\nPalette colors matched from CPC game screenshots:")
    print("  Day palette:")
    print("    Pen 0: Black (outlines, text)")
    print("    Pen 1: Bright Cyan (floor/background)")
    print("    Pen 2: Yellow/Orange (walls, bricks)")
    print("    Pen 3: Bright White (highlights)")
    print("  Night palette:")
    print("    Pen 0: Black (outlines, text)")
    print("    Pen 1: Bright Blue (floor/background)")
    print("    Pen 2: Bright Magenta (walls, structures)")
    print("    Pen 3: Pastel Magenta (highlights)")
    print("\nTile data extracted from addresses 8300-A2FF in the .asm file")
