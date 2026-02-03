"""
DSL Converter - Internal library for bytecode disassembly.

Converts binary bytecode scripts into human-readable DSL (Domain-Specific Language)
format. Used by extract_block_scripts.py to embed DSL in abbey_blocks_library.py
and by room_renderer.py to include DSL in room log files.

Main exports:
- BytecodeToDSL: Class for converting bytecode to DSL
- disassemble_single_block(block_id): Convenience function for single block
- disassemble_all_blocks(output_path): Batch disassembly to file

Opcode definitions are imported from opcodes.py (single source of truth).
"""

import os
from typing import List, Tuple, Optional
from .opcodes import get_register_name


class BytecodeToDSL:
    """Disassembler for Abbey bytecode."""

    def __init__(self, memory_file='python/resources/abbey_code.bin'):
        self.memory_file = memory_file
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
            0x18E3: 96,   0x18E7: 97,
            0x1D59: 96,   # Shared logic with SCRIPT96
            0x1CA6: 99,   0x1CAF: 100,
            0x1CB4: 101,  0x1CBD: 102,
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

    def read_operand(self) -> Tuple[int, str]:
        """
        Read an operand/value following the game's logic at 0x2214.
        Returns (value, string_representation).
        """
        val = self.read_byte()

        # 0x82 is a literal escape prefix
        if val == 0x82:
            literal = self.read_byte()
            return literal, str(literal)

        if val >= 0x60:
            # Register reference - use shared REGISTER_NAMES from opcodes.py
            return 0, get_register_name(val)  # Value is unknown at disassembly time
        else:
            return val, str(val)

    def emit(self, text: str):
        """Emit a line of DSL with proper indentation."""
        self.output_lines.append("  " * self.indent + text)

    def read_value_str(self) -> str:
        """Read a value/register and return DSL string representation."""
        _, s = self.read_operand()
        return s

    def read_expression_str(self) -> str:
        """Read an expression and return DSL string representation."""
        parts = []
        
        # Read first term
        _, s = self.read_operand()
        parts.append(s)

        # Continue reading expression parts
        while self.pc < len(self.memory):
            peek = self.peek_byte()
            if peek >= 0xC8:  # Opcode boundary
                break

            self.pc += 1

            if peek == 0x84:
                # 0x84 is the SUB operator
                # Check what follows
                if self.peek_byte() >= 0xC8:
                    # End of expression - negate everything so far
                    expr_so_far = "".join(parts)
                    return f"-( {expr_so_far} )"
                
                # Otherwise read next operand to subtract
                _, next_s = self.read_operand()
                
                # Handle special pattern "-( operand ) + register" from "register 84 operand"
                # Reference DSL represents "A - B" as "-( B ) + A" if A is a register?
                # Actually, SCRIPT38 says "ADD Y, -( PARAM2 ) + PARAM1" for "F2 6E 84 6D"
                # If 6E=PARAM1 and 6D=PARAM2, then "PARAM1 84 PARAM2" -> "-( PARAM2 ) + PARAM1"
                if len(parts) == 1 and parts[0] != "0":
                    return f"-( {next_s} ) + {parts[0]}"
                
                parts.append(f" - {next_s}")
            else:
                # Addition
                self.pc -= 1 # Unread
                _, s = self.read_operand()
                parts.append(f" + {s}")

        return "".join(parts)

    def disassemble_paint_tile(self, move_type: str) -> List[str]:
        """Disassemble F9/F8/EB paint tile sequence."""
        lines = []

        while True:
            # Read tile ID (operand)
            _, tile_str = self.read_operand()

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
                # Count is also an operand!
                # We need to unread it and read it as operand
                self.pc -= 1
                count_val, count_str = self.read_operand()

                lines.append(f"DRAWTILE {tile_str}  ; x{count_str}")
                
                # If it's a literal count < 60, we can emit multiple movements
                # Otherwise (register count), we just show the comment
                if 0 < count_val < 0x60:
                    for _ in range(count_val):
                        if move_type == "DEC Y":
                            lines.append("DEC Y")
                        elif move_type == "INC X":
                            lines.append("INC X")
                        elif move_type == "DEC X":
                            lines.append("DEC X")

        return lines

    def disassemble_block(self, address: int, tile_data: List[int], blk_id: int = 0) -> str:
        """
        Disassemble a block starting at the given address.

        Args:
            address: Start address of block script (after tile pointer)
            tile_data: List of tile IDs loaded for this block
            blk_id: Block ID for labeling

        Returns:
            DSL string representation
        """
        self.pc = address
        self.output_lines = []
        self.indent = 0
        self.loop_depth = 0

        # Emit header (Script N = Block N, since block 0x00 doesn't exist)
        self.emit(f"[SCRIPT{blk_id}]")

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
                reg_name = get_register_name(reg_byte)
                formatted = self.read_expression_str()
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
                formatted = self.read_expression_str()
                self.emit(f"ADD Y, {formatted}")

            elif opcode == 0xF1:  # ADD X, expr
                formatted = self.read_expression_str()
                self.emit(f"ADD X, {formatted}")

            elif opcode == 0xF0:  # INC PARAM1
                self.emit("INC PARAM1")

            elif opcode == 0xEF:  # INC PARAM2
                self.emit("INC PARAM2")

            elif opcode == 0xEE:  # DEC PARAM2
                self.emit("DEC PARAM2")

            elif opcode == 0xED:  # DEC PARAM1
                self.emit("DEC PARAM1")

            elif opcode == 0xEC:  # CALL
                low = self.read_byte()
                high = self.read_byte()
                addr = (high << 8) | low
                # Try to resolve to script number and offset
                res = self.resolve_address_to_script_with_offset(addr)
                if res:
                    script_num, offset = res
                    if offset > 0:
                        self.emit(f"CALL SCRIPT{script_num}, {offset}")
                    else:
                        self.emit(f"CALL SCRIPT{script_num}")
                else:
                    self.emit(f"CALL ${addr:04X}")

            elif opcode == 0xEA:  # JMP
                low = self.read_byte()
                high = self.read_byte()
                addr = (high << 8) | low
                res = self.resolve_address_to_script_with_offset(addr)
                if res:
                    script_num, offset = res
                    self.emit(f"JMP SCRIPT{script_num}, {offset}")
                else:
                    self.emit(f"JMP ${addr:04X}, 0")
                break  # JMP ends this script

            elif opcode in [0xE9, 0xE8, 0xE7, 0xE6, 0xE5]:  # FLIP X
                self.emit("FLIP X")

            elif opcode == 0xE4:  # CALL with FLIP X
                self.emit("FLIP X")
                low = self.read_byte()
                high = self.read_byte()
                addr = (high << 8) | low
                res = self.resolve_address_to_script_with_offset(addr)
                if res:
                    script_num, offset = res
                    if offset > 0:
                        self.emit(f"CALL SCRIPT{script_num}, {offset}")
                    else:
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

    def resolve_address_to_script_with_offset(self, addr: int) -> Optional[Tuple[int, int]]:
        """Try to resolve an address to a (script_number, offset) tuple."""
        # 1. Check exact matches in known script addresses (subroutines)
        if addr in self.script_addresses:
            return self.script_addresses[addr], 0
            
        # 2. Check blocks
        # We need the block list sorted by address
        from data.blocks import BLOCK_DEFINITIONS as BLOCK_LIBRARY
        
        # Build list if not cached? For now just iterate.
        sorted_blocks = sorted(BLOCK_LIBRARY.values(), key=lambda x: x.address)

        # Find the block that contains this address
        best_match = None
        for blk in sorted_blocks:
            if blk.address <= addr:
                best_match = blk
            else:
                break
                
        if best_match:
            # Check if it's within a reasonable range (e.g. 256 bytes)
            # Or just assume if it's after address, it belongs to this block
            offset = addr - (best_match.address + 2) # Offset from bytecode start
            if offset < 0:
                # Target is the tile pointer or block start?
                return best_match.block_id, 0
            return best_match.block_id, offset
            
        return None

    def set_script_addresses(self, addresses: dict):
        """Set known script address mappings, preserving common subroutines."""
        # Merge with existing (common subroutines), new addresses take precedence for conflicts
        self.script_addresses.update(addresses)


def disassemble_all_blocks(output_path: str = "tests/abadia/resouces/scripts_disassembled.abs"):
    """Disassemble all blocks to DSL format."""
    from data.blocks import BLOCK_DEFINITIONS as BLOCK_LIBRARY

    converter = BytecodeToDSL()

    # Build script address mapping (block_id = script_number since block 0x00 doesn't exist)
    script_addresses = {}
    for blk_id, blk_def in BLOCK_LIBRARY.items():
        # Map both block address and script address (block + 2)
        # CALL instructions often use the raw block address
        script_addresses[blk_def.address] = blk_id
        script_addresses[blk_def.address + 2] = blk_id  # Script start
    converter.set_script_addresses(script_addresses)

    all_scripts = []

    for blk_id in sorted(BLOCK_LIBRARY.keys()):
        block_def = BLOCK_LIBRARY[blk_id]

        # Get tile data - trim trailing zeros for cleaner output
        tile_data = list(block_def.tile_data) if block_def.tile_data else []
        # Remove trailing zeros (unused tile slots)
        while tile_data and tile_data[-1] == 0:
            tile_data.pop()

        # Script starts after tile pointer (2 bytes)
        script_addr = block_def.address + 2

        try:
            dsl = converter.disassemble_block(script_addr, tile_data, blk_id)
            all_scripts.append(dsl)
            all_scripts.append("")  # Blank line between scripts
        except Exception as e:
            all_scripts.append(f"[SCRIPT{blk_id}]")
            all_scripts.append(f"; Error disassembling: {e}")
            all_scripts.append("")

    # Write output
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w') as f:
        f.write("\n".join(all_scripts))

    print(f"Disassembled {len(BLOCK_LIBRARY)} blocks to {output_path}")
    return output_path


def disassemble_single_block(blk_id: int) -> str:
    """Disassemble a single block and return DSL string."""
    from data.blocks import BLOCK_DEFINITIONS as BLOCK_LIBRARY

    if blk_id not in BLOCK_LIBRARY:
        return f"; Block 0x{blk_id:02X} not found in library"

    converter = BytecodeToDSL()

    # Build address mapping for JMP resolution
    script_addresses = {}
    for bid, bdef in BLOCK_LIBRARY.items():
        script_addresses[bdef.address] = bid
        script_addresses[bdef.address + 2] = bid
    converter.set_script_addresses(script_addresses)

    block_def = BLOCK_LIBRARY[blk_id]

    # Get tile data - trim trailing zeros
    tile_data = list(block_def.tile_data) if block_def.tile_data else []
    while tile_data and tile_data[-1] == 0:
        tile_data.pop()

    script_addr = block_def.address + 2

    return converter.disassemble_block(script_addr, tile_data, blk_id)


def main():
    """CLI entry point."""
    import sys

    if len(sys.argv) > 1:
        # Disassemble specific block
        target_id = int(sys.argv[1], 16) if sys.argv[1].startswith("0x") else int(sys.argv[1])
        print(disassemble_single_block(target_id))
    else:
        # Disassemble all blocks
        disassemble_all_blocks()


if __name__ == "__main__":
    main()
