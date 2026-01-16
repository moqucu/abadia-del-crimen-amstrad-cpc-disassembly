import os

def analyze():
    with open('src/abadia/resources/lookup_tables.bin', 'rb') as f:
        data = f.read()
    
    # 4 Tables of 256 bytes
    # Table 1: 0x9D00 (Offset 0)
    # Table 2: 0x9E00 (Offset 256)
    # Table 3: 0x9F00 (Offset 512)
    # Table 4: 0xA000 (Offset 768)
    
    tables = [
        data[0:256],
        data[256:512],
        data[512:768],
        data[768:1024]
    ]
    
    print("Analyzing Lookup Tables (Color Swaps)...")
    
    # Test bytes representing solid colors (4 pixels of same color)
    # 00 = 00 00 00 00 (Pen 0)
    # 55 = 01 01 01 01 (Pen 1)
    # AA = 10 10 10 10 (Pen 2)
    # FF = 11 11 11 11 (Pen 3)
    
    test_bytes = {
        0x00: "Pen 0",
        0x55: "Pen 1",
        0xAA: "Pen 2",
        0xFF: "Pen 3"
    }
    
    for i, table in enumerate(tables):
        print(f"\nTable {i+1} (Offset {i*256}):")
        for byte_val, name in test_bytes.items():
            result = table[byte_val]
            # Decode result to see what color it maps to
            # If result is solid color, it's a direct swap
            res_name = "Mixed/Unknown"
            for k, v in test_bytes.items():
                if result == k:
                    res_name = v
                    break
            
            print(f"  Input {name} ({byte_val:02X}) -> {result:02X} ({res_name})")

if __name__ == "__main__":
    analyze()
