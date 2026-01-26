
import os

def check_memory():
    path = 'src/abadia/resources/abbey_code.bin'
    if not os.path.exists(path):
        print("File not found")
        return

    with open(path, 'rb') as f:
        data = f.read()
    
    start = 0x1D23
    end = 0x1D60
    print(f"Dumping {path} from {start:04X} to {end:04X}")
    
    chunk = data[start:end]
    for i, b in enumerate(chunk):
        addr = start + i
        print(f"{addr:04X}: {b:02X}")

if __name__ == "__main__":
    check_memory()
