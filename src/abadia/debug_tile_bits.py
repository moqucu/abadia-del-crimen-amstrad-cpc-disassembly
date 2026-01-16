
import os

def decode_cpc_mode1_byte(byte_val):
    pixels = []
    for i in range(4):
        # bit_high from {7,6,5,4}, bit_low from {3,2,1,0}
        bit_high = (byte_val >> (7 - i)) & 1
        bit_low = (byte_val >> (3 - i)) & 1
        pixel_value = (bit_high << 1) | bit_low
        pixels.append(pixel_value)
    return pixels

def print_tile_matrix(tile_num):
    with open('src/abadia/resources/abbey_code.bin', 'rb') as f:
        f.seek(0x8300 + tile_num * 32)
        data = f.read(32)
    
    print(f"ASCII Matrix for Tile {tile_num} (ID 0x{tile_num:02X})")
    print("-" * 33)
    for y in range(8):
        row_pixels = []
        for x_byte in range(4):
            byte_val = data[y * 4 + x_byte]
            row_pixels.extend(decode_cpc_mode1_byte(byte_val))
        
        # Format the row for display
        line = " ".join(str(p) for p in row_pixels)
        print(line)
    print("-" * 33)

if __name__ == "__main__":
    import sys
    tile_num = 12
    if len(sys.argv) > 1:
        tile_num = int(sys.argv[1], 16) if sys.argv[1].startswith("0x") else int(sys.argv[1])
    print_tile_matrix(tile_num)
