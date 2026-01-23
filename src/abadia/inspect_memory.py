import os

memory_file = 'src/abadia/resources/abbey_code.bin'

if os.path.exists(memory_file):
    with open(memory_file, 'rb') as f:
        memory = bytearray(f.read())
        
    start_addr = 0x1897
    length = 32
    print(f"Bytes at 0x{start_addr:04X}:")
    for i in range(length):
        print(f"{memory[start_addr + i]:02X}", end=" ")
    print()
else:
    print("Memory file not found")
