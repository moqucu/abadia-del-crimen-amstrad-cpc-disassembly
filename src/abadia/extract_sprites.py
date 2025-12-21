#!/usr/bin/env python3
"""
Extract sprite/object graphics from La Abadía del Crimen (CPC Amstrad version)

Sprites are stored differently from tiles:
- Variable dimensions (characters are larger than objects)
- Metadata table at 0x2E17 defines each sprite
- Graphics data starts at 0xA300
"""

import re
from PIL import Image
import os

# CPC hardware colors (same as for tiles)
CPC_PALETTE = {
    0x00: (0, 0, 0),           # Black
    0x01: (0, 0, 128),         # Blue
    0x02: (0, 0, 255),         # Bright Blue
    0x03: (128, 0, 0),         # Red
    0x04: (128, 0, 128),       # Magenta
    0x05: (128, 0, 255),       # Mauve
    0x06: (255, 0, 0),         # Bright Red
    0x07: (255, 0, 128),       # Purple
    0x08: (255, 0, 255),       # Bright Magenta
    0x09: (0, 128, 0),         # Green
    0x0A: (0, 128, 128),       # Cyan
    0x0B: (0, 128, 255),       # Sky Blue
    0x0C: (128, 128, 0),       # Yellow
    0x0D: (128, 128, 128),     # White
    0x0E: (128, 128, 255),     # Pastel Blue
    0x0F: (255, 128, 0),       # Orange
    0x10: (255, 128, 128),     # Pink
    0x11: (255, 128, 255),     # Pastel Magenta
    0x12: (0, 255, 0),         # Bright Green
    0x13: (0, 255, 128),       # Sea Green
    0x14: (0, 255, 255),       # Bright Cyan
    0x15: (128, 255, 0),       # Lime
    0x16: (128, 255, 128),     # Pastel Green
    0x17: (128, 255, 255),     # Pastel Cyan
    0x18: (255, 255, 0),       # Bright Yellow
    0x19: (255, 255, 128),     # Pastel Yellow
    0x1A: (255, 255, 255),     # Bright White
}

# Game palettes (from actual screenshots)
PALETTE_DAY = {
    0: CPC_PALETTE[0x00],  # Black
    1: CPC_PALETTE[0x14],  # Bright Cyan
    2: CPC_PALETTE[0x18],  # Bright Yellow/Orange
    3: CPC_PALETTE[0x1A],  # Bright White
}

PALETTE_NIGHT = {
    0: CPC_PALETTE[0x00],  # Black
    1: CPC_PALETTE[0x02],  # Bright Blue
    2: CPC_PALETTE[0x08],  # Bright Magenta
    3: CPC_PALETTE[0x11],  # Pastel Magenta
}

# Sprite metadata (parsed from 0x2E17-0x2FE3 in .asm)
SPRITE_METADATA = [
    # Characters
    {'name': 'guillermo', 'width_bytes': 5, 'height': 0x22, 'addr': 0x38B4},
    {'name': 'adso', 'width_bytes': 5, 'height': 0x24, 'addr': 0x38AA},
    {'name': 'malaquias', 'width_bytes': 5, 'height': 0x22, 'addr': 0x3A2A},
    {'name': 'abbot', 'width_bytes': 5, 'height': 0x22, 'addr': 0x3A2A},
    {'name': 'berengario', 'width_bytes': 5, 'height': 0x22, 'addr': 0x3A2A},
    {'name': 'severino', 'width_bytes': 5, 'height': 0x22, 'addr': 0x3A2A},
    # Doors
    {'name': 'door_abbot', 'width_bytes': 6, 'height': 0x28, 'addr': 0x3A98},
    {'name': 'door_monks', 'width_bytes': 6, 'height': 0x28, 'addr': 0x3A98},
    {'name': 'door_severino', 'width_bytes': 6, 'height': 0x28, 'addr': 0x3A98},
    {'name': 'door_church', 'width_bytes': 6, 'height': 0x28, 'addr': 0x3A98},
    {'name': 'door_kitchen', 'width_bytes': 6, 'height': 0x28, 'addr': 0x3A98},
    {'name': 'door_left1', 'width_bytes': 6, 'height': 0x28, 'addr': 0x3A98},
    {'name': 'door_left2', 'width_bytes': 6, 'height': 0x28, 'addr': 0x3A98},
    # Objects
    {'name': 'book', 'width_bytes': 4, 'height': 0x0C, 'addr': 0x72F0},
    {'name': 'gloves', 'width_bytes': 4, 'height': 0x0C, 'addr': 0x89B0},
    {'name': 'glasses', 'width_bytes': 4, 'height': 0x0C, 'addr': 0x8980},
    {'name': 'parchment', 'width_bytes': 4, 'height': 0x0C, 'addr': 0x8A10},
    {'name': 'key1', 'width_bytes': 4, 'height': 0x0C, 'addr': 0x89E0},
    {'name': 'key2', 'width_bytes': 4, 'height': 0x0C, 'addr': 0x89E0},
    {'name': 'key3', 'width_bytes': 4, 'height': 0x0C, 'addr': 0x89E0},
    {'name': 'unknown', 'width_bytes': 4, 'height': 0x0C, 'addr': 0xA006},
    {'name': 'lamp', 'width_bytes': 4, 'height': 0x0C, 'addr': 0x72C0},
    {'name': 'light', 'width_bytes': 0x14, 'height': 0x50, 'addr': 0x0000},
]


def read_sprite_graphics_from_asm(asm_file):
    """Read sprite graphics data from A300 onwards in the .asm file"""
    graphics_data = bytearray()
    in_sprite_section = False

    with open(asm_file, 'r', encoding='latin-1') as f:
        for line in f:
            # Look for start of object graphics
            if 'start of the object graphics' in line:
                in_sprite_section = True
                continue

            # Stop at end marker
            if in_sprite_section and 'end of the object graphics' in line.lower():
                break

            # Parse hex dump lines like: A300: 00 00 11 FF 88 00 00 33-FF CC 00 00 77 CB 6A 00
            if in_sprite_section:
                match = re.match(r'^[0-9A-F]{4}:\s+([0-9A-F\- ]+)', line)
                if match:
                    hex_bytes = match.group(1).replace('-', ' ').split()
                    for hb in hex_bytes:
                        if len(hb) == 2 and hb.replace('0','').replace('1','').replace('2','').replace('3','').replace('4','').replace('5','').replace('6','').replace('7','').replace('8','').replace('9','').replace('A','').replace('B','').replace('C','').replace('D','').replace('E','').replace('F','') == '':
                            graphics_data.append(int(hb, 16))

    print(f"Read {len(graphics_data)} bytes of sprite graphics data (from 0xA300 to 0x{0xA300 + len(graphics_data):04X})")
    return graphics_data


def decode_cpc_mode1_byte(byte_val):
    """
    Decode a single byte in CPC Mode 1 format into 4 pixels
    Each pixel uses 2 bits, stored in an interleaved format
    """
    pixels = []
    for pixel_num in range(4):
        if pixel_num == 0:
            pixel_value = ((byte_val >> 7) & 1) | ((byte_val >> 2) & 2)
        elif pixel_num == 1:
            pixel_value = ((byte_val >> 6) & 1) | ((byte_val >> 1) & 2)
        elif pixel_num == 2:
            pixel_value = ((byte_val >> 5) & 1) | ((byte_val >> 0) & 2)
        elif pixel_num == 3:
            pixel_value = ((byte_val >> 4) & 1) | ((byte_val << 1) & 2)
        pixels.append(pixel_value)
    return pixels


def extract_sprite(graphics_data, offset, width_bytes, height, palette='day'):
    """
    Extract a single sprite from the graphics data

    Args:
        graphics_data: Raw sprite graphics bytes
        offset: Byte offset into graphics_data
        width_bytes: Width of sprite in bytes
        height: Height of sprite in pixels
        palette: 'day' or 'night'

    Returns:
        PIL Image object
    """
    palette_colors = PALETTE_DAY if palette == 'day' else PALETTE_NIGHT

    # Each byte contains 4 pixels in Mode 1
    width_pixels = width_bytes * 4

    # Create image
    img = Image.new('RGB', (width_pixels, height))
    pixels = img.load()

    # Decode sprite data
    for y in range(height):
        for x_byte in range(width_bytes):
            byte_offset = offset + y * width_bytes + x_byte
            if byte_offset >= len(graphics_data):
                print(f"Warning: byte_offset {byte_offset} exceeds data length {len(graphics_data)}")
                continue

            byte_val = graphics_data[byte_offset]
            decoded_pixels = decode_cpc_mode1_byte(byte_val)

            for px_num, color_idx in enumerate(decoded_pixels):
                x = x_byte * 4 + px_num
                rgb = palette_colors[color_idx]
                pixels[x, y] = rgb

    return img


def extract_all_sprites(asm_file):
    """Extract all sprites and create individual PNGs and sprite sheets"""

    # Read graphics data
    graphics_data = read_sprite_graphics_from_asm(asm_file)

    if not graphics_data:
        print("ERROR: No sprite graphics data found!")
        return

    print(f"Total sprite data available: {len(graphics_data)} bytes")

    # Create output directories
    os.makedirs('sprites/day', exist_ok=True)
    os.makedirs('sprites/night', exist_ok=True)

    # Map memory addresses to file offsets
    # The sprite data in file starts at 0xA300
    # Runtime memory addresses in metadata don't directly map to file offsets
    # We'll extract sprites sequentially from the data

    # From memory map comments:
    # 0xa300-0xab58: graphics of william (guillermo), adso and the doors
    # This suggests Guillermo and Adso are early in the data

    # Manual sprite order based on analysis (sequential in file)
    sprite_order = [
        # Characters - unique graphics
        {'name': 'adso', 'width_bytes': 5, 'height': 0x24},         # First character
        {'name': 'guillermo', 'width_bytes': 5, 'height': 0x22},    # Second character
        {'name': 'monk', 'width_bytes': 5, 'height': 0x22},         # Generic monk (shared by 4 NPCs)

        # Door - one graphic shared by all doors
        {'name': 'door', 'width_bytes': 6, 'height': 0x28},

        # Objects - each unique
        {'name': 'lamp', 'width_bytes': 4, 'height': 0x0C},
        {'name': 'book', 'width_bytes': 4, 'height': 0x0C},
        {'name': 'glasses', 'width_bytes': 4, 'height': 0x0C},
        {'name': 'gloves', 'width_bytes': 4, 'height': 0x0C},
        {'name': 'key', 'width_bytes': 4, 'height': 0x0C},          # One graphic for all 3 keys
        {'name': 'parchment', 'width_bytes': 4, 'height': 0x0C},
        {'name': 'unknown', 'width_bytes': 4, 'height': 0x0C},

        # Note: Light sprite may not be in this section - skipping for now
    ]

    # Extract sprites sequentially
    print("\n" + "="*70)
    print("EXTRACTING SPRITES")
    print("="*70)

    current_offset = 0
    for idx, sprite in enumerate(sprite_order):
        name = sprite['name']
        width_bytes = sprite['width_bytes']
        height = sprite['height']

        width_pixels = width_bytes * 4
        size_bytes = width_bytes * height

        # Check if we have enough data
        if current_offset + size_bytes > len(graphics_data):
            print(f"[{idx:02d}] WARNING: {name} - not enough data (need {size_bytes} bytes from offset {current_offset}, only {len(graphics_data) - current_offset} available)")
            break

        print(f"[{idx:02d}] {name:20s} - {width_pixels:2d}x{height:2d}px ({width_bytes}×{height} bytes) "
              f"@ offset {current_offset:5d} (size: {size_bytes} bytes)")

        # Extract for both palettes
        for palette in ['day', 'night']:
            img = extract_sprite(graphics_data, current_offset, width_bytes, height, palette)

            # Save individual sprite
            filename = f'sprites/{palette}/{idx:02d}_{name}.png'
            img.save(filename)

        current_offset += size_bytes

    # Create sprite sheets
    print("\n" + "="*70)
    print("CREATING SPRITE SHEETS")
    print("="*70)

    create_sprite_sheet('day')
    create_sprite_sheet('night')

    print("\nDone!")


def create_sprite_sheet(palette='day'):
    """Create a sprite sheet from all individual sprites"""

    # Load all sprites
    sprite_images = []
    sprite_dir = f'sprites/{palette}'

    sprite_files = sorted([f for f in os.listdir(sprite_dir) if f.endswith('.png')])

    for filename in sprite_files:
        img = Image.open(os.path.join(sprite_dir, filename))
        sprite_images.append((filename, img))

    if not sprite_images:
        print(f"No sprites found for {palette} palette")
        return

    # Calculate sprite sheet dimensions
    # Arrange in a grid with max 8 sprites per row
    sprites_per_row = 8
    num_rows = (len(sprite_images) + sprites_per_row - 1) // sprites_per_row

    # Find max dimensions
    max_width = max(img.width for _, img in sprite_images)
    max_height = max(img.height for _, img in sprite_images)

    # Add padding
    padding = 4
    cell_width = max_width + padding * 2
    cell_height = max_height + padding * 2

    # Create sprite sheet
    sheet_width = sprites_per_row * cell_width
    sheet_height = num_rows * cell_height

    bg_color = PALETTE_DAY[0] if palette == 'day' else PALETTE_NIGHT[0]
    sheet = Image.new('RGB', (sheet_width, sheet_height), bg_color)

    # Paste sprites
    for idx, (filename, img) in enumerate(sprite_images):
        row = idx // sprites_per_row
        col = idx % sprites_per_row

        x = col * cell_width + padding
        y = row * cell_height + padding

        sheet.paste(img, (x, y))

    # Save sprite sheet
    output_file = f'abbey_sprites_sheet_{palette}.png'
    sheet.save(output_file)
    print(f"Created sprite sheet: {output_file} ({sheet_width}x{sheet_height}px, {len(sprite_images)} sprites)")


if __name__ == '__main__':
    extract_all_sprites('abadia_del_crimen_disassembled_CPC_Amstrad_game_code.asm')
