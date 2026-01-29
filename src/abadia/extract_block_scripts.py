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

def read_expression(memory, pc):
    """
    Read an expression from bytecode, returning (bytes_consumed, list_of_bytes).
    Expressions continue until we hit a byte >= 0xC8 (which is an opcode).

    Key: 0x82 is a literal escape prefix - the next byte is always a literal value,
    even if it would otherwise look like a register (>=0x60) or opcode (>=0xC8).
    """
    expr_bytes = []
    while pc < 65536:
        byte = memory[pc]

        # 0x82 = literal prefix, next byte is literal value
        if byte == 0x82:
            expr_bytes.append(byte)
            pc += 1
            if pc < 65536:
                expr_bytes.append(memory[pc])  # This is the literal (could be 0xFF!)
                pc += 1
        elif byte >= 0xC8:
            # This is an opcode, expression ends (don't consume it)
            break
        else:
            # Regular value or register reference
            expr_bytes.append(byte)
            pc += 1

    return expr_bytes


def extract_bytecode(memory, start_addr, max_length=500):
    """
    Extract bytecode starting at start_addr, properly parsing opcodes and their operands.
    Returns list of bytes.

    Key fix: 0xFF is only END when it appears in opcode position.
    When it appears after 0x82 (literal prefix), it's just the value -1.
    """
    bytecode = []
    pc = start_addr

    while pc < 65536 and len(bytecode) < max_length:
        opcode = memory[pc]
        bytecode.append(opcode)
        pc += 1

        # END opcode - we're done
        if opcode == 0xFF:
            break

        # JMP, CALL, CALL_FLIP - consume 2 address bytes
        elif opcode in [0xEA, 0xEC, 0xE4]:
            for _ in range(2):
                if pc < 65536:
                    bytecode.append(memory[pc])
                    pc += 1

        # LD (UpdateReg) - consume register byte + expression
        elif opcode == 0xF7:
            if pc < 65536:
                bytecode.append(memory[pc])  # Register byte
                pc += 1
            expr = read_expression(memory, pc)
            bytecode.extend(expr)
            pc += len(expr)

        # ADD X, ADD Y - consume expression
        elif opcode in [0xF1, 0xF2]:
            expr = read_expression(memory, pc)
            bytecode.extend(expr)
            pc += len(expr)

        # DRAWTILE variants (F9, F8, EB) - consume tile/control sequence
        elif opcode in [0xF9, 0xF8, 0xEB]:
            # These consume pairs of (value, control) until we hit an opcode (>=0xC8)
            while pc < 65536:
                # Read tile value (could be 0x82 prefixed literal or register)
                if memory[pc] == 0x82:
                    bytecode.append(memory[pc])
                    pc += 1
                    if pc < 65536:
                        bytecode.append(memory[pc])
                        pc += 1
                elif memory[pc] >= 0xC8:
                    # Hit an opcode, done with this DRAWTILE sequence
                    break
                else:
                    bytecode.append(memory[pc])
                    pc += 1

                # Now read control byte
                if pc >= 65536 or memory[pc] >= 0xC8:
                    # Next byte is an opcode, done
                    break

                ctrl = memory[pc]
                bytecode.append(ctrl)
                pc += 1

                # If control is 0x80 or 0x81, continue reading tiles
                # Otherwise (count), we continue reading
                # Actually the loop continues until we hit opcode

        # Other opcodes have no additional operands
        # (FE, FD, FC, FB, FA, F6, F5, F4, F3, F0, EF, EE, ED, E9-E5, E0)

    return bytecode


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

        # Extract bytecode with proper opcode parsing
        bytecode = extract_bytecode(memory, addr + 2)

        blocks[block_id] = {
            'address': addr,
            'tile_ptr': tile_ptr,
            'tile_data': tile_data,
            'bytecode': bytecode,
            'description': item['desc']
        }
    return blocks

def generate_python_file(blocks):
    """Generates the output Python file with DSL metadata."""
    from abadia.bytecode_to_dsl import disassemble_single_block

    content = [
        '"""',
        'Abbey Blocks Library',
        '',
        'Auto-generated from binary memory dump.',
        'Contains the 96 building block scripts used by the game engine.',
        'Each block includes raw bytecode and human-readable DSL representation.',
        '"""',
        '',
        'class BlockDef:',
        '    def __init__(self, block_id, description, address, tile_ptr, tile_data, bytecode, dsl=""):',
        '        self.block_id = block_id',
        '        self.description = description',
        '        self.address = address',
        '        self.tile_ptr = tile_ptr',
        '        self.tile_data = tile_data',
        '        self.bytecode = bytecode',
        '        self.dsl = dsl',
        '',
        'BLOCK_DEFINITIONS = {'
    ]

    for block_id in sorted(blocks.keys()):
        b = blocks[block_id]
        bytecode_hex = ", ".join(f"0x{x:02X}" for x in b['bytecode'])
        tile_data_hex = ", ".join(f"0x{x:02X}" for x in b['tile_data'])

        # Generate DSL for this block
        try:
            dsl = disassemble_single_block(block_id)
        except Exception as e:
            dsl = f"; Error generating DSL: {e}"

        content.append(f"    0x{block_id:02X}: BlockDef(")
        content.append(f"        block_id=0x{block_id:02X},")
        content.append(f"        description=\"{b['description']}\",")
        content.append(f"        address=0x{b['address']:04X},")
        content.append(f"        tile_ptr=0x{b['tile_ptr']:04X},")
        content.append(f"        tile_data=[{tile_data_hex}],")
        content.append(f"        bytecode=[{bytecode_hex}],")
        # Add DSL as triple-quoted string
        content.append(f"        dsl=\"\"\"\\")
        for line in dsl.split('\n'):
            content.append(line)
        content.append("\"\"\"")
        content.append(f"    ),")

    content.append("}")

    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        f.write("\n".join(content))
    print(f"Generated {OUTPUT_FILE} with {len(blocks)} blocks (including DSL).")

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