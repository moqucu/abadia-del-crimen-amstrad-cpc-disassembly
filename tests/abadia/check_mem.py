
import sys

def check_memory(addr):
    with open('src/abadia/resources/abbey_code.bin', 'rb') as f:
        data = f.read()
    
    print(f"Checking 0x{addr:04X}:")
    for i in range(32):
        print(f"{data[addr+i]:02X}", end=" ")
    print()

if __name__ == "__main__":
    check_memory(0x1B28)
