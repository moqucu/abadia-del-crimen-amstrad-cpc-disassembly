#!/usr/bin/env python3
"""
Bytecode to DSL Converter for La Abadia del Crimen building blocks.

Converts the binary bytecode scripts into a human-readable DSL format
compatible with the scripts.abs format from the web version.

This allows easy comparison and debugging of block rendering.
"""

import os
from typing import List, Tuple, Optional


class BytecodeToDSL:
    """Converts block bytecode to human-readable DSL."""

    def __init__(self, memory_file='src/abadia/resources/abbey_code.bin'):
        """Load the memory file containing all bytecode."""
        self.memory = bytearray(65536)
        if os.path.exists(memory_file):
            with open(memory_file, 'rb') as f:
                self.memory = bytearray(f.read())
        else:
            raise FileNotFoundError(f"Memory file {memory_file} not found")

        self.pc = 0
        self.output_lines = []
        self.indent = 0
        self.loop_depth = 0

        # Known script addresses for JMP/CALL resolution
        # Common subroutines (not blocks) - named SCRIPT96+ in reference DSL
        self.script_addresses = {
            # Subroutines 96-105 (commonly called routines)
            0x18E3: 96,   # Common subroutine
            0x18E7: 97,   # Common subroutine (floor pattern)
            0x1CA6: 99,   # Common subroutine
            0x1CAF: 100,  # Common subroutine
            0x1CB4: 101,  # Common subroutine
            0x1CBD: 102,  # Common subroutine
            # Subroutines 106-113
            0x198C: 106,  # FLIP X then JMP SCRIPT1
            0x19AD: 107,  # Common column/window code
            0x19C6: 108,  # FLIP X then JMP SCRIPT107
            0x1990: 109,  # Column generation code
            0x19A9: 110,  # FLIP X then JMP SCRIPT109
            0x19CA: 111,  # LD PARAM2 manipulation
            0x19D4: 112,  # FLIP X then JMP SCRIPT111
            0x1BCF: 113,  # Block rendering code
        }

    def read_byte(self) -> int:
        """Read a byte and advance PC."""
        if self.pc < len(self.memory):
            val = self.memory[self.pc]
            self.pc += 1
            return val
        return 0

    def peek_byte(self) -> int:
        """Peek at next byte without advancing PC."""
        if self.pc < len(self.memory):
            return self.memory[self.pc]
        return 0

    def emit(self, text: str):
        """Emit a line of DSL with proper indentation."""
        self.output_lines.append("  " * self.indent + text)

    def read_value_str(self) -> str:
        """Read a value/register and return DSL string representation."""
        val = self.read_byte()
        if val >= 0x70:
            # Register reference
            reg_names = {
                0x70: "DEPTHX", 0x71: "DEPTHY",
                0x6F: "HEIGHT", 0x72: "HEIGHT2",
                0x6D: "PARAM1", 0x6E: "PARAM2",
            }
            if val in reg_names:
                return reg_names[val]
            elif 0x61 <= val <= 0x6C:
                return f"T{val - 0x61}"
            else:
                return f"REG{val:02X}"
        elif val >= 0x60:
            # Registers 0x60-0x6F
            reg_names = {
                0x70: "DEPTHX", 0x71: "DEPTHY",
                0x6F: "HEIGHT", 0x72: "HEIGHT2",
                0x6D: "PARAM1", 0x6E: "PARAM2",
            }
            if val in reg_names:
                return reg_names[val]
            elif 0x61 <= val <= 0x6C:
                return f"T{val - 0x61}"
            else:
                return f"REG{val:02X}"
        else:
            return str(val)

    def read_expression_str(self) -> str:
        """Read an expression and return DSL string representation."""
        parts = []
        first_val = self.read_byte()

        # Register names matching reference DSL convention
        reg_names = {
            0x70: "DEPTHX", 0x71: "DEPTHY",
            0x6F: "HEIGHT", 0x72: "HEIGHT2",
            0x6D: "PARAM1", 0x6E: "PARAM2",  # Swapped to match reference
        }

        # First value
        if first_val >= 0x60:
            if first_val in reg_names:
                parts.append(reg_names[first_val])
            elif 0x61 <= first_val <= 0x6C:
                parts.append(f"T{first_val - 0x61}")
            else:
                parts.append(f"REG{first_val:02X}")
        else:
            parts.append(str(first_val))

        # Continue reading expression parts
        while self.pc < len(self.memory):
            peek = self.peek_byte()
            if peek >= 0xC8:  # Opcode boundary
                break

            self.pc += 1

            if peek == 0x84:
                # Subtraction operator
                # Check if next byte is an opcode - if so, 84 means "negate expression"
                if self.pc < len(self.memory) and self.memory[self.pc] >= 0xC8:
                    # Expression ends here - just negate what we have
                    # Transform "a + b + c" to "-( a + b + c )"
                    expr_so_far = "".join(parts)
                    parts = [f"-( {expr_so_far} )"]
                    break
                next_val = self.read_byte()
                if next_val >= 0x60:
                    if next_val in reg_names:
                        parts.append(f" - {reg_names[next_val]}")
                    else:
                        parts.append(f" - REG{next_val:02X}")
                else:
                    parts.append(f" - {next_val}")
            elif peek >= 0x60:
                # Register addition
                if peek in reg_names:
                    parts.append(f" + {reg_names[peek]}")
                elif 0x61 <= peek <= 0x6C:
                    parts.append(f" + T{peek - 0x61}")
                else:
                    parts.append(f" + REG{peek:02X}")
            else:
                # Literal addition
                parts.append(f" + {peek}")

        return "".join(parts)

    def format_expression_negative(self, expr_str: str, target_reg: str) -> str:
        """Format expression for LD statement, handling negative patterns."""
        # Try to detect patterns like "val + PARAM2 + PARAM2 - REG70" -> "-( val + PARAM2 + PARAM2 ) + DEPTHX"
        # This is a simplification - the actual pattern matching would be more complex

        if " - " in expr_str and target_reg in expr_str:
            # Pattern: "X + Y - TARGET" becomes "-( X + Y ) + TARGET"
            parts = expr_str.rsplit(" - ", 1)
            if len(parts) == 2 and target_reg in parts[1]:
                return f"-( {parts[0]} ) + {target_reg}"

        return expr_str

    def disassemble_paint_tile(self, move_type: str) -> List[str]:
        """Disassemble F9/F8/EB paint tile sequence."""
        lines = []

        while True:
            # Read tile ID
            tile_val = self.read_byte()
            if tile_val >= 0x61 and tile_val <= 0x6C:
                tile_str = f"T{tile_val - 0x61}"
            else:
                tile_str = str(tile_val)

            # Check control byte
            if self.pc >= len(self.memory):
                lines.append(f"DRAWTILE {tile_str}")
                break

            ctrl = self.peek_byte()

            if ctrl >= 0xC8:
                # It's an opcode - emit single draw and movement, then exit
                lines.append(f"DRAWTILE {tile_str}")
                if move_type == "DEC Y":
                    lines.append("DEC Y")
                elif move_type == "INC X":
                    lines.append("INC X")
                elif move_type == "DEC X":
                    lines.append("DEC X")
                break

            self.pc += 1  # Consume control byte

            if ctrl == 0x80:
                # Draw and move
                lines.append(f"DRAWTILE {tile_str}")
                if move_type == "DEC Y":
                    lines.append("DEC Y")
                elif move_type == "INC X":
                    lines.append("INC X")
                elif move_type == "DEC X":
                    lines.append("DEC X")
                # Continue loop
            elif ctrl == 0x81:
                # Draw and stay
                lines.append(f"DRAWTILE {tile_str}")
                # Continue loop
            else:
                # Count - draw multiple times
                if ctrl >= 0x60:
                    count_str = f"REG{ctrl:02X}"
                else:
                    count_str = str(ctrl)

                # For simplicity, just note the count
                lines.append(f"DRAWTILE {tile_str}  ; x{count_str}")
                for _ in range(ctrl if ctrl < 0x60 else 1):
                    if move_type == "DEC Y":
                        lines.append("DEC Y")
                    elif move_type == "INC X":
                        lines.append("INC X")
                    elif move_type == "DEC X":
                        lines.append("DEC X")

        return lines

    def disassemble_block(self, address: int, tile_data: List[int], block_id: int = 0) -> str:
        """
        Disassemble a block starting at the given address.

        Args:
            address: Start address of block script (after tile pointer)
            tile_data: List of tile IDs loaded for this block
            block_id: Block ID for labeling

        Returns:
            DSL string representation
        """
        self.pc = address
        self.output_lines = []
        self.indent = 0
        self.loop_depth = 0

        # Emit header (Script N = Block N, since block 0x00 doesn't exist)
        self.emit(f"[SCRIPT{block_id}]")

        # Emit TILES line
        if tile_data:
            tiles_str = ",".join(str(t) for t in tile_data)
            self.emit(f"TILES {tiles_str}")

        max_iterations = 1000
        iterations = 0

        while iterations < max_iterations:
            iterations += 1

            if self.pc >= len(self.memory):
                break

            opcode = self.read_byte()

            if opcode == 0xFF:  # END
                self.emit("END")
                break

            elif opcode == 0xFE:  # WHILE PARAM1
                self.emit("WHILE PARAM1")
                self.indent += 1
                self.loop_depth += 1

            elif opcode == 0xFD:  # WHILE PARAM2
                self.emit("WHILE PARAM2")
                self.indent += 1
                self.loop_depth += 1

            elif opcode == 0xFC:  # PUSH X, PUSH Y
                self.emit("PUSH X")
                self.emit("PUSH Y")

            elif opcode == 0xFB:  # POP Y, POP X
                self.emit("POP Y")
                self.emit("POP X")

            elif opcode == 0xFA:  # ENDWHILE
                self.indent = max(0, self.indent - 1)
                self.emit("ENDWHILE")
                self.loop_depth = max(0, self.loop_depth - 1)

            elif opcode == 0xF9:  # DRAWTILE with DEC Y
                lines = self.disassemble_paint_tile("DEC Y")
                for line in lines:
                    self.emit(line)

            elif opcode == 0xF8:  # DRAWTILE with INC X
                lines = self.disassemble_paint_tile("INC X")
                for line in lines:
                    self.emit(line)

            elif opcode == 0xEB:  # DRAWTILE with DEC X
                lines = self.disassemble_paint_tile("DEC X")
                for line in lines:
                    self.emit(line)

            elif opcode == 0xF7:  # LD register
                reg_byte = self.read_byte()
                reg_names = {
                    0x70: "DEPTHX", 0x71: "DEPTHY",
                    0x6F: "HEIGHT", 0x72: "HEIGHT2",
                    0x6D: "PARAM1", 0x6E: "PARAM2",
                }
                reg_name = reg_names.get(reg_byte, f"REG{reg_byte:02X}")
                expr = self.read_expression_str()
                formatted = self.format_expression_negative(expr, reg_name)
                self.emit(f"LD {reg_name}, {formatted}")

            elif opcode == 0xF6:  # INC Y
                self.emit("INC Y")

            elif opcode == 0xF5:  # INC X
                self.emit("INC X")

            elif opcode == 0xF4:  # DEC Y
                self.emit("DEC Y")

            elif opcode == 0xF3:  # DEC X
                self.emit("DEC X")

            elif opcode == 0xF2:  # ADD Y, expr
                expr = self.read_expression_str()
                self.emit(f"ADD Y, {expr}")

            elif opcode == 0xF1:  # ADD X, expr
                expr = self.read_expression_str()
                self.emit(f"ADD X, {expr}")

            elif opcode == 0xF0:  # INC PARAM1
                self.emit("INC PARAM1")

            elif opcode == 0xEF:  # INC PARAM2
                self.emit("INC PARAM2")

            elif opcode == 0xEE:  # DEC PARAM2
                self.emit("DEC PARAM2")

            elif opcode == 0xED:  # DEC PARAM1
                self.emit("DEC PARAM1")

            elif opcode == 0xEC:  # CALL
                high = self.read_byte()
                low = self.read_byte()
                addr = (high << 8) | low
                # Try to resolve to script number
                script_num = self.resolve_address_to_script(addr)
                if script_num:
                    self.emit(f"CALL SCRIPT{script_num}")
                else:
                    self.emit(f"CALL ${addr:04X}")

            elif opcode == 0xEA:  # JMP
                high = self.read_byte()
                low = self.read_byte()
                addr = (high << 8) | low
                script_num = self.resolve_address_to_script(addr)
                if script_num:
                    self.emit(f"JMP SCRIPT{script_num}, 0")
                else:
                    self.emit(f"JMP ${addr:04X}, 0")
                break  # JMP ends this script

            elif opcode in [0xE9, 0xE8, 0xE7, 0xE6, 0xE5]:  # FLIP X
                self.emit("FLIP X")

            elif opcode == 0xE4:  # CALL with FLIP X
                self.emit("FLIP X")
                high = self.read_byte()
                low = self.read_byte()
                addr = (high << 8) | low
                script_num = self.resolve_address_to_script(addr)
                if script_num:
                    self.emit(f"CALL SCRIPT{script_num}")
                else:
                    self.emit(f"CALL ${addr:04X}")

            elif opcode < 0xE4:
                # Unknown/Z80 opcode - likely end of script or jump target
                self.emit(f"; Unknown opcode ${opcode:02X} at ${self.pc-1:04X}")
                break

            else:
                self.emit(f"; Unhandled opcode ${opcode:02X}")

        return "\n".join(self.output_lines)

    def resolve_address_to_script(self, addr: int) -> Optional[int]:
        """Try to resolve an address to a script number."""
        # This would need a mapping of known script addresses
        # For now, return None
        return self.script_addresses.get(addr)

    def set_script_addresses(self, addresses: dict):
        """Set known script address mappings, preserving common subroutines."""
        # Merge with existing (common subroutines), new addresses take precedence for conflicts
        self.script_addresses.update(addresses)


def disassemble_all_blocks(output_path: str = "tests/abadia/resouces/scripts_disassembled.abs"):
    """Disassemble all blocks to DSL format."""
    from abadia.abbey_blocks_library import BLOCK_DEFINITIONS as BLOCK_LIBRARY

    converter = BytecodeToDSL()

    # Build script address mapping (block_id = script_number since block 0x00 doesn't exist)
    script_addresses = {}
    for block_id, block_def in BLOCK_LIBRARY.items():
        # Map both block address and script address (block + 2)
        # CALL instructions often use the raw block address
        script_addresses[block_def.address] = block_id
        script_addresses[block_def.address + 2] = block_id  # Script start
    converter.set_script_addresses(script_addresses)

    all_scripts = []

    for block_id in sorted(BLOCK_LIBRARY.keys()):
        block_def = BLOCK_LIBRARY[block_id]

        # Get tile data - trim trailing zeros for cleaner output
        tile_data = list(block_def.tile_data) if block_def.tile_data else []
        # Remove trailing zeros (unused tile slots)
        while tile_data and tile_data[-1] == 0:
            tile_data.pop()

        # Script starts after tile pointer (2 bytes)
        script_addr = block_def.address + 2

        try:
            dsl = converter.disassemble_block(script_addr, tile_data, block_id)
            all_scripts.append(dsl)
            all_scripts.append("")  # Blank line between scripts
        except Exception as e:
            all_scripts.append(f"[SCRIPT{block_id}]")
            all_scripts.append(f"; Error disassembling: {e}")
            all_scripts.append("")

    # Write output
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w') as f:
        f.write("\n".join(all_scripts))

    print(f"Disassembled {len(BLOCK_LIBRARY)} blocks to {output_path}")
    return output_path


def disassemble_single_block(block_id: int) -> str:
    """Disassemble a single block and return DSL string."""
    from abadia.abbey_blocks_library import BLOCK_DEFINITIONS as BLOCK_LIBRARY

    if block_id not in BLOCK_LIBRARY:
        return f"; Block 0x{block_id:02X} not found in library"

    converter = BytecodeToDSL()

    # Build address mapping for JMP resolution
    script_addresses = {}
    for bid, bdef in BLOCK_LIBRARY.items():
        script_addresses[bdef.address] = bid
        script_addresses[bdef.address + 2] = bid
    converter.set_script_addresses(script_addresses)

    block_def = BLOCK_LIBRARY[block_id]

    # Get tile data - trim trailing zeros
    tile_data = list(block_def.tile_data) if block_def.tile_data else []
    while tile_data and tile_data[-1] == 0:
        tile_data.pop()

    script_addr = block_def.address + 2

    return converter.disassemble_block(script_addr, tile_data, block_id)


if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1:
        # Disassemble specific block
        block_id = int(sys.argv[1], 16) if sys.argv[1].startswith("0x") else int(sys.argv[1])
        print(disassemble_single_block(block_id))
    else:
        # Disassemble all blocks
        disassemble_all_blocks()
