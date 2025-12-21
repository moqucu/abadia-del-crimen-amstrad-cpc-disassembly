#!/usr/bin/env python3
"""
CORRECTED Sprite Extraction Script for La Abadía del Crimen (CPC Amstrad)

Based on analysis of sprite drawing routine at 0x4914 and metadata table at 0x2E17.
All file locations have been verified by code analysis.
"""

import re
from PIL import Image
import os

# CPC hardware colors
CPC_PALETTE = {
    0x00: (0, 0, 0),           # Black
    0x02: (0, 0, 255),         # Bright Blue
    0x08: (255, 0, 255),       # Bright Magenta
    0x11: (255, 128, 255),     # Pastel Magenta
    0x14: (0, 255, 255),       # Bright Cyan
    0x18: (255, 255, 0),       # Bright Yellow
    0x1A: (255, 255, 255),     # Bright White
}

# Game palettes
PALETTE_DAY = {
    0: CPC_PALETTE[0x00],  # Black (transparent)
    1: CPC_PALETTE[0x14],  # Bright Cyan
    2: CPC_PALETTE[0x18],  # Bright Yellow
    3: CPC_PALETTE[0x1A],  # Bright White
}

PALETTE_NIGHT = {
    0: CPC_PALETTE[0x00],  # Black (transparent)
    1: CPC_PALETTE[0x02],  # Bright Blue
    2: CPC_PALETTE[0x08],  # Bright Magenta
    3: CPC_PALETTE[0x11],  # Pastel Magenta
}

# Sprite definitions with VERIFIED file locations
# Format: name, file_address, width_bytes, height_pixels
SPRITE_DEFINITIONS = [
    # Characters from "object graphics" section (0xA300+)
    ("adso", 0xA300, 5, 0x24),           # File offset 0
    ("guillermo", 0xA3B4, 5, 0x22),      # File offset 180
    ("monk", 0xA45E, 5, 0x22),           # File offset 350

    # Door from "object graphics" section
    ("door", 0xA508, 6, 0x28),           # File offset 520

    # Objects from copied section (file 0x8300 → runtime 0x6D00)
    # Runtime addresses: book=0x72F0, lamp=0x72C0
    # File = runtime + (0x8300 - 0x6D00) = runtime + 0x1600
    ("lamp", 0x88C0, 4, 0x0C),           # Runtime 0x72C0
    ("book", 0x88F0, 4, 0x0C),           # Runtime 0x72F0

    # Objects from bank 3 (direct file addresses)
    ("glasses", 0x8980, 4, 0x0C),
    ("gloves", 0x89B0, 4, 0x0C),
    ("key", 0x89E0, 4, 0x0C),
    ("parchment", 0x8A10, 4, 0x0C),
    ("unknown", 0xA006, 4, 0x0C),
]


def read_all_graphics_from_asm(asm_file):
    """Read all graphics data from the .asm file into a 64KB memory buffer"""
    # Initialize 64KB memory with zeros
    memory = bytearray(65536)
    
    print(f"Reading {asm_file}...")
    bytes_read = 0

    with open(asm_file, 'r', encoding='latin-1') as f:
        for line in f:
            # Parse hex dump lines: ADDR: XX XX XX XX-XX XX XX XX ...
            # Example: A300: 00 00 11 ...
            match = re.match(r'^([0-9A-F]{4}):\s+([0-9A-F\- ]+)', line)
            if match:
                addr_str = match.group(1)
                data_str = match.group(2)
                
                try:
                    current_addr = int(addr_str, 16)
                    hex_bytes = data_str.replace('-', ' ').split()
                    
                    for hb in hex_bytes:
                        if len(hb) == 2:
                            val = int(hb, 16)
                            if current_addr < len(memory):
                                memory[current_addr] = val
                                current_addr += 1
                                bytes_read += 1
                except ValueError:
                    continue

    print(f"Populated memory map with {bytes_read} bytes from .asm file")
    return memory


def decode_cpc_mode1_byte(byte_val):
    """
    Decode a single byte in CPC Mode 1 format into 4 pixels
    Bit layout: Pixel 0: bits 7,3; Pixel 1: bits 6,2; Pixel 2: bits 5,1; Pixel 3: bits 4,0
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


def extract_sprite(graphics_data, file_addr, width_bytes, height, palette='day'):
    """
    Extract a sprite from graphics data at a specific memory address

    Args:
        graphics_data: 64KB bytearray representing memory
        file_addr: Memory address (e.g., 0xA300)
        width_bytes: Width in bytes
        height: Height in pixels
        palette: 'day' or 'night'
    """
    palette_colors = PALETTE_DAY if palette == 'day' else PALETTE_NIGHT
    width_pixels = width_bytes * 4

    # Create image with transparency
    img = Image.new('RGBA', (width_pixels, height), (0, 0, 0, 0))
    pixels = img.load()

    # Extract sprite data
    for y in range(height):
        for x_byte in range(width_bytes):
            byte_offset = file_addr + y * width_bytes + x_byte

            if byte_offset >= len(graphics_data):
                continue

            byte_val = graphics_data[byte_offset]
            decoded_pixels = decode_cpc_mode1_byte(byte_val)

            for px_num, color_idx in enumerate(decoded_pixels):
                x = x_byte * 4 + px_num
                if color_idx == 0:
                    # Color 0 is transparent
                    pixels[x, y] = (0, 0, 0, 0)
                else:
                    rgb = palette_colors[color_idx]
                    pixels[x, y] = rgb + (255,)  # Add alpha channel

    return img


def extract_all_sprites(asm_file):
    """Extract all sprites and create individual PNGs and sprite sheets"""

    # Read complete file
    graphics_data = read_all_graphics_from_asm(asm_file)

    # Create output directories
    os.makedirs('sprites_correct/day', exist_ok=True)
    os.makedirs('sprites_correct/night', exist_ok=True)

    print("\n" + "="*70)
    print("EXTRACTING SPRITES (CORRECTED)")
    print("="*70)

    for idx, (name, file_addr, width_bytes, height) in enumerate(SPRITE_DEFINITIONS):
        width_pixels = width_bytes * 4
        size_bytes = width_bytes * height

        print(f"[{idx:02d}] {name:12s} - {width_pixels:2d}×{height:2d}px "
              f"({width_bytes}×{height} bytes) @ Address 0x{file_addr:04X}, size {size_bytes} bytes")

        # Extract for both palettes
        for palette in ['day', 'night']:
            img = extract_sprite(graphics_data, file_addr, width_bytes, height, palette)

            # Save individual sprite with transparency
            filename = f'sprites_correct/{palette}/{idx:02d}_{name}.png'
            img.save(filename)

    # Create sprite sheets
    print("\n" + "="*70)
    print("CREATING SPRITE SHEETS")
    print("="*70)

    create_sprite_sheet('day')
    create_sprite_sheet('night')

    print("\nDone! Sprites extracted with correct transparency.")


def create_sprite_sheet(palette='day'):
    """Create a sprite sheet from all individual sprites"""

    sprite_dir = f'sprites_correct/{palette}'
    try:
        sprite_files = sorted([f for f in os.listdir(sprite_dir) if f.endswith('.png')])
    except FileNotFoundError:
        print(f"Directory not found: {sprite_dir}")
        return

    if not sprite_files:
        print(f"No sprite files found in {sprite_dir}")
        return

    # Load all sprites
    sprite_images = []
    for filename in sprite_files:
        try:
            img = Image.open(os.path.join(sprite_dir, filename))
            sprite_images.append((filename, img))
        except Exception as e:
            print(f"Error loading {filename}: {e}")

    if not sprite_images:
        return

    # Calculate dimensions (8 sprites per row)
    sprites_per_row = 8
    num_rows = (len(sprite_images) + sprites_per_row - 1) // sprites_per_row

    max_width = max(img.width for _, img in sprite_images)
    max_height = max(img.height for _, img in sprite_images)

    padding = 4
    cell_width = max_width + padding * 2
    cell_height = max_height + padding * 2

    sheet_width = sprites_per_row * cell_width
    sheet_height = num_rows * cell_height

    # Create sheet with transparency
    bg_color = PALETTE_DAY[0] if palette == 'day' else PALETTE_NIGHT[0]
    sheet = Image.new('RGB', (sheet_width, sheet_height), bg_color)

    # Paste sprites
    for idx, (filename, img) in enumerate(sprite_images):
        row = idx // sprites_per_row
        col = idx % sprites_per_row

        x = col * cell_width + padding
        y = row * cell_height + padding

        # Paste with transparency support
        if img.mode == 'RGBA':
            sheet.paste(img, (x, y), img)
        else:
            sheet.paste(img, (x, y))

    output_file = f'abbey_sprites_sheet_{palette}_corrected.png'
    sheet.save(output_file)
    print(f"Created: {output_file} ({sheet_width}×{sheet_height}px, {len(sprite_images)} sprites)")


if __name__ == '__main__':
    extract_all_sprites('abadia_del_crimen_disassembled_CPC_Amstrad_game_code.asm')