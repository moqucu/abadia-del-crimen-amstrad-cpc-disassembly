#!/usr/bin/env python3
"""
Detailed bytecode analysis for Block 0x0C to understand variable step widths
"""
import os
import sys
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from abadia.abbey_blocks_library import BLOCK_DEFINITIONS

print("="*80)
print("BLOCK 0x0C BYTECODE ANALYSIS")
print("="*80)

block_def = BLOCK_DEFINITIONS[0x0C]

print(f"\nBlock: 0x{block_def.block_id:02X}")
print(f"Description: {block_def.description}")
print(f"Address: 0x{block_def.address:04X}")
print(f"Tile pointer: 0x{block_def.tile_ptr:04X}")

print(f"\nTile data ({len(block_def.tile_data)} tiles):")
for i, tile_id in enumerate(block_def.tile_data, 1):
    print(f"  reg[{i:2d}] = 0x{tile_id:02X} (tile_{tile_id:03d}_0x{tile_id:02X}.png)")

print(f"\nBytecode ({len(block_def.bytecode)} bytes):")
bytecode = block_def.bytecode

# Opcode reference (from interpreter.py)
opcode_names = {
    0xFF: "END",
    0xFE: "LOOP_START",
    0xFD: "LOOP_END",
    0xFC: "PUSH_POS",
    0xFB: "POP_POS",
    0xFA: "DEC_Y",
    0xF9: "PAINT_TILE",
    0xF8: "INC_Y",
    0xF7: "LOAD_REG",
    0xF6: "INC_X",
    0xF5: "DEC_X",
    0xF4: "INC_X_DEC_Y",
    0xF3: "DEC_X_INC_Y",
    0xF2: "INC_X_INC_Y",
    0xF1: "DEC_X_DEC_Y",
    0xF0: "PAINT_TILE_INC_X",
    0xEF: "PAINT_TILE_DEC_Y",
    0xEE: "PAINT_TILE_INC_Y",
    0xED: "PAINT_TILE_INC_X_DEC_Y",
    0xEC: "PAINT_TILE_DEC_X_INC_Y",
    0xEB: "PAINT_TILE_INC_X_INC_Y",
    0xEA: "CALL_SUBROUTINE",
}

# Disassemble bytecode
print("\nDisassembly:")
i = 0
indent = 0
while i < len(bytecode):
    opcode = bytecode[i]

    # Format output with indentation
    prefix = "  " * indent
    print(f"  {i:3d}: {prefix}0x{opcode:02X}", end="")

    if opcode in opcode_names:
        name = opcode_names[opcode]
        print(f" - {name}", end="")

        if opcode == 0xFE:  # LOOP_START
            print(f" (loop)", end="")
            indent += 1
        elif opcode == 0xFD:  # LOOP_END
            indent = max(0, indent - 1)
        elif opcode == 0xF9:  # PAINT_TILE
            if i + 1 < len(bytecode):
                reg = bytecode[i + 1]
                if 1 <= reg <= len(block_def.tile_data):
                    tile_id = block_def.tile_data[reg - 1]
                    print(f" reg[{reg}]=0x{tile_id:02X}", end="")
                else:
                    print(f" reg[{reg}]", end="")
                i += 1
        elif opcode == 0xEF:  # PAINT_TILE_DEC_Y
            if i + 1 < len(bytecode):
                reg = bytecode[i + 1]
                if 1 <= reg <= len(block_def.tile_data):
                    tile_id = block_def.tile_data[reg - 1]
                    print(f" reg[{reg}]=0x{tile_id:02X}, then DecY", end="")
                else:
                    print(f" reg[{reg}], then DecY", end="")
                i += 1
        elif opcode == 0xF0:  # PAINT_TILE_INC_X
            if i + 1 < len(bytecode):
                reg = bytecode[i + 1]
                if 1 <= reg <= len(block_def.tile_data):
                    tile_id = block_def.tile_data[reg - 1]
                    print(f" reg[{reg}]=0x{tile_id:02X}, then IncX", end="")
                else:
                    print(f" reg[{reg}], then IncX", end="")
                i += 1
        elif opcode == 0xF7:  # LOAD_REG
            if i + 3 < len(bytecode):
                reg = bytecode[i + 1]
                val1 = bytecode[i + 2]
                val2 = bytecode[i + 3]
                print(f" reg[{reg}] = 0x{val1:02X}{val2:02X}", end="")
                i += 3
        elif opcode == 0xEA:  # CALL_SUBROUTINE
            if i + 3 < len(bytecode):
                addr_high = bytecode[i + 1]
                addr_low = bytecode[i + 2]
                reg = bytecode[i + 3]
                addr = (addr_high << 8) | addr_low
                print(f" addr=0x{addr:04X}, reg={reg}", end="")
                i += 3
    else:
        print(f" - (unknown)", end="")

    print()
    i += 1

print("\n" + "="*80)
print("ANALYSIS:")
print("="*80)
print("Looking for patterns that cause variable step widths...")
