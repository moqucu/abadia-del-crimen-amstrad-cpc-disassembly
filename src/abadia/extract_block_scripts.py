#!/usr/bin/env python3
"""
Extract Building Block Scripts from Binary Memory Dump.

Uses 'src/abadia/resources/abbey_code.bin' as the source of truth for bytes.
Uses the ASM file only to find the Material Table mapping (ID -> Address).
"""

import re
import os

ASM_FILE = "translated_english_files/0 - abadia_del_crimen_disassembled_CPC_Amstrad_game_code.asm"
MEM_FILE = "src/abadia/resources/abbey_code.bin"
OUTPUT_FILE = "src/abadia/abbey_blocks_library.py"

def load_memory(filepath):
    """Load the full 64KB memory dump."""
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"Memory file {filepath} not found. Run rebuild_abbey_code.py first.")
    with open(filepath, 'rb') as f:
        return bytearray(f.read())

def parse_material_table(filepath):
    """Extract the block ID -> address mapping from the ASM Material Table."""
    material_table_text = []
    arrow_re = re.compile(r'([0-9A-Fa-f]{4})\s*->\s*0x([0-9A-Fa-f]{2})\s*(?:\([^)]+\))?\s*->\s*(.*)')
    
    in_material_table = False
    with open(filepath, 'r', encoding='latin-1') as f:
        for line in f:
            if "156D:" in line:
                in_material_table = True
            if in_material_table:
                match = arrow_re.search(line)
                if match:
                    material_table_text.append({
                        'addr': int(match.group(1), 16),
                        'id': int(match.group(2), 16),
                        'desc': match.group(3).strip()
                    })
    return material_table_text

def extract_blocks(memory, mappings):
    """Extract bytecode and tile data for each block."""
    blocks = {}
    for item in mappings:
        addr = item['addr']
        block_id = item['id']
        
        if addr == 0: continue
        
        # Read Tile Pointer (2 bytes, Little Endian)
        ptr_low = memory[addr]
        ptr_high = memory[addr+1]
        tile_ptr = (ptr_high << 8) | ptr_low
        
        # Read Tile Data (12 bytes) from the tile_ptr address
        tile_data = []
        for i in range(12):
            if tile_ptr + i < 65536:
                tile_data.append(memory[tile_ptr + i])
            else:
                tile_data.append(0)
                
        # Read Bytecode (starting at addr + 2) until 0xFF
        bytecode = []
        pc = addr + 2
        while pc < 65536:
            opcode = memory[pc]
            bytecode.append(opcode)
            pc += 1
            if opcode == 0xFF:
                break
            if len(bytecode) > 500: # Safety
                break
                
        blocks[block_id] = {
            'address': addr,
            'tile_ptr': tile_ptr,
            'tile_data': tile_data,
            'bytecode': bytecode,
            'description': item['desc']
        }
    return blocks

def generate_python_file(blocks):
    """Generates the output Python file."""
    content = [
        '"""',
        'Abbey Blocks Library',
        '',
        'Auto-generated from binary memory dump.',
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
        content.append(f"    ), ")
        
    content.append("}")
    
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        f.write("\n".join(content))
    print(f"Generated {OUTPUT_FILE} with {len(blocks)} blocks.")

def main():
    print("Loading memory dump...")
    memory = load_memory(MEM_FILE)
    
    print("Parsing material table from ASM...")
    mappings = parse_material_table(ASM_FILE)
    print(f"Found {len(mappings)} entries.")
    
    print("Extracting blocks...")
    blocks = extract_blocks(memory, mappings)
    
    print("Generating library...")
    generate_python_file(blocks)

if __name__ == "__main__":
    main()