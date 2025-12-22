#!/usr/bin/env python3
"""
Extract Building Block Scripts from Disassembled Code.

This script parses the '0 - abadia.asm' file to:
1. Build a memory map of the game code.
2. Parse the Material Table at 0x156D to find block definitions.
3. Extract the bytecode for each of the 96 building blocks.
4. Generate 'src/abadia/abbey_blocks_library.py'.
"""

import re
import os

ASM_FILE = "translated_english_files/0 - abadia_del_crimen_disassembled_CPC_Amstrad_game_code.asm"
OUTPUT_FILE = "src/abadia/abbey_blocks_library.py"

def parse_asm_file(filepath):
    """
    Parses the ASM file to build a memory map and extract specific table text.
    Returns (memory, material_table_lines)
    """
    memory = {} # Sparse memory map: addr -> byte
    material_table_text = []
    
    current_addr = None
    
    # Regex for standard hex dump lines: "1234: AB CD EF  ; comment"
    # We capture the address and the rest of the line
    addr_line_re = re.compile(r'^\s*([0-9A-Fa-f]{4}):\s*(.*)$')
    
    # Regex for the specific arrow format in the material table: "1973 -> 0x01"
    arrow_re = re.compile(r'([0-9A-Fa-f]{4})\s*->\s*0x([0-9A-Fa-f]{2})')

    in_material_table = False

    with open(filepath, 'r', encoding='latin-1') as f:
        for line in f:
            line = line.strip('\n') 
            
            # 1. Capture Material Table Text
            if "156D:" in line:
                in_material_table = True
            
            if in_material_table:
                if arrow_re.search(line):
                    material_table_text.append(line)
            
            # 2. Populate Memory
            # Extract potential bytes string
            bytes_text = ""
            
            match = addr_line_re.match(line)
            if match:
                addr_str = match.group(1)
                bytes_text = match.group(2)
                try:
                    current_addr = int(addr_str, 16)
                except ValueError:
                    current_addr = None # Should not happen with regex
            elif current_addr is not None and line.strip():
                # Continuation line? Assumes indented or just data
                # We simply try to parse the whole line as bytes if current_addr is set
                bytes_text = line.strip()
            
            if current_addr is not None and bytes_text:
                # Parse tokens until non-hex
                # Handle comments starting with ;
                if ';' in bytes_text:
                    bytes_text = bytes_text.split(';')[0]
                
                tokens = bytes_text.split()
                for token in tokens:
                    # Clean token (though split handles whitespace)
                    token = token.strip()
                    if not token: continue
                    
                    # Check if valid hex
                    if all(c in '0123456789ABCDEFabcdef' for c in token):
                        # Handle grouped hex "16A2"
                        if len(token) % 2 == 0:
                            for i in range(0, len(token), 2):
                                b_val = int(token[i:i+2], 16)
                                memory[current_addr] = b_val
                                current_addr += 1
                        else:
                            # Odd length hex string? Unlikely to be code bytes.
                            # Treat as start of mnemonic/garbage
                            break
                    else:
                        # Non-hex token encountered (e.g. "FlipX", "add", "ld")
                        # Stop processing this line
                        break

    return memory, material_table_text

def extract_block_definitions(memory, material_table_text):
    """
    Extracts block definitions based on the parsed table text.
    """
    blocks = {} 
    
    arrow_re = re.compile(r'([0-9A-F]{4})\s*->\s*0x([0-9A-F]{2})\s*(?:\([^)]+\))?\s*->\s*(.*)')
    
    for line in material_table_text:
        match = arrow_re.search(line)
        if match:
            addr_str = match.group(1)
            id_str = match.group(2)
            desc = match.group(3).strip()
            
            addr = int(addr_str, 16)
            block_id = int(id_str, 16)
            
            if addr == 0:
                continue 
                
            if addr not in memory:
                print(f"Warning: Block 0x{block_id:02X} at 0x{addr:04X} not found in parsed memory.")
                continue
                
            tile_ptr_low = memory.get(addr, 0)
            tile_ptr_high = memory.get(addr+1, 0)
            tile_ptr = (tile_ptr_high << 8) | tile_ptr_low
            
            bytecode = []
            pc = addr + 2
            while True:
                opcode = memory.get(pc)
                if opcode is None:
                    print(f"Warning: Unexpected end of memory for block 0x{block_id:02X} at 0x{pc:04X}")
                    break
                
                bytecode.append(opcode)
                pc += 1
                
                if opcode == 0xFF:
                    break
                    
                if len(bytecode) > 200:
                    print(f"Warning: Block 0x{block_id:02X} bytecode too long (>200 bytes). Truncating.")
                    break
            
            # Read Tile Data (12 bytes)
            tile_data = []
            for i in range(12):
                val = memory.get(tile_ptr + i, 0)
                tile_data.append(val)

            blocks[block_id] = {
                'address': addr,
                'tile_ptr': tile_ptr,
                'tile_data': tile_data,
                'bytecode': bytecode,
                'description': desc
            }
            
    return blocks

def generate_python_file(blocks):
    """Generates the output Python file."""
    
    content = [
        '"""',
        'Abbey Blocks Library',
        '',
        'Auto-generated from disassembled code.',
        'Contains the 96 building block scripts used by the game engine.',
        '"""',
        '',
        'class BlockDef:',
        '    def __init__(self, block_id, description, address, tile_ptr, tile_data, bytecode):',
        '        self.block_id = block_id',
        '        self.description = description',
        '        self.address = address',
        '        self.tile_ptr = tile_ptr',
        '        self.tile_data = tile_data',
        '        self.bytecode = bytecode',
        '',
        'BLOCK_DEFINITIONS = {'
    ]
    
    for block_id in sorted(blocks.keys()):
        b = blocks[block_id]
        bytecode_hex = ", ".join(f"0x{x:02X}" for x in b['bytecode'])
        tile_data_hex = ", ".join(f"0x{x:02X}" for x in b['tile_data'])
        
        content.append(f"    0x{block_id:02X}: BlockDef(")
        content.append(f"        block_id=0x{block_id:02X},")
        content.append(f"        description=\"{b['description']}\",")
        content.append(f"        address=0x{b['address']:04X},")
        content.append(f"        tile_ptr=0x{b['tile_ptr']:04X},")
        content.append(f"        tile_data=[{tile_data_hex}],")
        content.append(f"        bytecode=[{bytecode_hex}]")
        content.append(f"    ),")
        
    content.append("}")
    
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        f.write("\n".join(content))
        
    print(f"Generated {OUTPUT_FILE} with {len(blocks)} blocks.")

def main():
    print("Parsing ASM file...")
    memory, material_table_text = parse_asm_file(ASM_FILE)
    print(f"Parsed {len(memory)} bytes of memory.")
    print(f"Found {len(material_table_text)} entries in Material Table.")
    
    blocks = extract_block_definitions(memory, material_table_text)
    
    generate_python_file(blocks)
    
    # Save memory map
    print("Saving memory map...")
    mem_bytes = bytearray(65536)
    for addr, val in memory.items():
        if 0 <= addr < 65536:
            mem_bytes[addr] = val
            
    os.makedirs('src/abadia/resources', exist_ok=True)
    with open('src/abadia/resources/abbey_code.bin', 'wb') as f:
        f.write(mem_bytes)
    print("Saved src/abadia/resources/abbey_code.bin")

if __name__ == "__main__":
    main()
