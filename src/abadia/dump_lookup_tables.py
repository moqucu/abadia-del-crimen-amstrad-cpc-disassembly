
import sys

def dump_tables():
    with open('src/abadia/resources/abbey_code.bin', 'rb') as f:
        data = f.read()
    
    # 0x9D00 - 0xA0FF (4 tables of 256 bytes)
    start = 0x9D00
    length = 0x400
    
    tables = data[start : start+length]
    
    with open('src/abadia/resources/lookup_tables.bin', 'wb') as f:
        f.write(tables)
    
    print(f"Dumped {len(tables)} bytes to src/abadia/resources/lookup_tables.bin")

if __name__ == "__main__":
    dump_tables()
