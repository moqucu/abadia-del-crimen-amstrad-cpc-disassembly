#!/usr/bin/env python3
"""
Replicate block traces and renderings from the JS version.
Finds the first occurrence of each block type in the room definitions,
renders it, and captures the execution trace.
"""

import os
import sys

# Add src to path if needed
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from abadia.abbey_rooms_library import ROOM_DEFINITIONS
from abadia.abbey_blocks_library import BLOCK_DEFINITIONS
from abadia.graphics import AbbeyTiles, BufferedCanvas
from abadia.interpreter import AbadiaInterpreter, OPCODE_NAMES, REG_NAMES


def decode_expr_to_string(bytecode, pc):
    """
    Decode an expression starting at pc and return (string_repr, new_pc).
    """
    parts = []
    start_pc = pc

    # First value
    if pc >= len(bytecode):
        return "?", pc

    b = bytecode[pc]
    pc += 1

    if b == 0x82 and pc < len(bytecode):
        # Literal prefix
        lit = bytecode[pc]
        pc += 1
        if lit > 127:
            parts.append(str(lit - 256))  # Show as signed
        else:
            parts.append(str(lit))
    elif b >= 0x60:
        parts.append(REG_NAMES.get(b, f"R{b - 0x60}"))
    else:
        parts.append(str(b))

    # Continue reading expression
    while pc < len(bytecode):
        b = bytecode[pc]
        if b >= 0xC8:
            break
        pc += 1

        if b == 0x84:
            # Negate - wrap what we have so far
            parts = [f"-({'+'.join(parts)})"]
        elif b == 0x82 and pc < len(bytecode):
            # Literal prefix
            lit = bytecode[pc]
            pc += 1
            if lit > 127:
                parts.append(str(lit - 256))
            else:
                parts.append(str(lit))
        elif b >= 0x60:
            parts.append(REG_NAMES.get(b, f"R{b - 0x60}"))
        else:
            parts.append(str(b))

    return "+".join(parts).replace("+-", "-"), pc


def disassemble_bytecode(bytecode, tile_data=None):
    """
    Disassemble bytecode into a human-readable format.
    One instruction per line with byte offset and hex bytes as table prefix.
    Format: [offset] HEX_BYTES    INSTRUCTION
    """
    lines = []
    lines.append("--- BYTECODE DISASSEMBLY ---")

    # First, show tile data if available
    if tile_data:
        tiles_str = ",".join(str(t) for t in tile_data)
        lines.append(f"TILES {tiles_str}")

    lines.append("")

    def format_line(start_pc, end_pc, instr):
        """Format a disassembly line with offset, hex bytes, and instruction."""
        hex_bytes = " ".join(f"{bytecode[i]:02X}" for i in range(start_pc, end_pc))
        return f"[{start_pc:3d}] {hex_bytes:20s} {instr}"

    def format_continuation(instr):
        """Format a continuation line (no offset/bytes, just instruction)."""
        return f"      {'':20s} {instr}"

    pc = 0
    while pc < len(bytecode):
        start_pc = pc
        opcode = bytecode[pc]
        pc += 1

        if opcode == 0xFF:
            lines.append(format_line(start_pc, pc, "END"))
            break
        elif opcode == 0xEA:  # JMP
            if pc + 1 < len(bytecode):
                low, high = bytecode[pc], bytecode[pc + 1]
                addr = (high << 8) | low
                pc += 2
                lines.append(format_line(start_pc, pc, f"JMP 0x{addr:04X}"))
            else:
                lines.append(format_line(start_pc, pc, "JMP (incomplete)"))
        elif opcode == 0xEC:  # CALL
            if pc + 1 < len(bytecode):
                low, high = bytecode[pc], bytecode[pc + 1]
                addr = (high << 8) | low
                pc += 2
                lines.append(format_line(start_pc, pc, f"CALL 0x{addr:04X}"))
            else:
                lines.append(format_line(start_pc, pc, "CALL (incomplete)"))
        elif opcode == 0xE4:  # CALL FLIP
            if pc + 1 < len(bytecode):
                low, high = bytecode[pc], bytecode[pc + 1]
                addr = (high << 8) | low
                pc += 2
                lines.append(format_line(start_pc, pc, f"CALL_FLIP 0x{addr:04X}"))
            else:
                lines.append(format_line(start_pc, pc, "CALL_FLIP (incomplete)"))
        elif opcode == 0xF7:  # LD
            if pc < len(bytecode):
                reg = bytecode[pc]
                reg_name = REG_NAMES.get(reg, f"R{reg - 0x60}" if reg >= 0x60 else f"0x{reg:02X}")
                pc += 1
                expr_str, pc = decode_expr_to_string(bytecode, pc)
                lines.append(format_line(start_pc, pc, f"LD {reg_name}, {expr_str}"))
            else:
                lines.append(format_line(start_pc, pc, "LD (incomplete)"))
        elif opcode == 0xF9:  # DRAWTILE DEC_Y
            if pc < len(bytecode):
                tile_reg = bytecode[pc]
                tile_name = REG_NAMES.get(tile_reg, f"R{tile_reg - 0x60}" if tile_reg >= 0x60 else str(tile_reg))
                pc += 1
                lines.append(format_line(start_pc, pc, f"DRAWTILE {tile_name}"))
                lines.append(format_continuation("DEC Y"))
                # Handle continuation (0x80 = draw+move, 0x81 = draw+stay)
                while pc < len(bytecode) and bytecode[pc] < 0xC8:
                    ctrl_start = pc
                    ctrl = bytecode[pc]
                    pc += 1
                    if ctrl == 0x80 and pc < len(bytecode):
                        tile_reg = bytecode[pc]
                        tile_name = REG_NAMES.get(tile_reg, f"R{tile_reg - 0x60}" if tile_reg >= 0x60 else str(tile_reg))
                        pc += 1
                        lines.append(format_line(ctrl_start, pc, f"DRAWTILE {tile_name}"))
                        lines.append(format_continuation("DEC Y"))
                    elif ctrl == 0x81 and pc < len(bytecode):
                        tile_reg = bytecode[pc]
                        tile_name = REG_NAMES.get(tile_reg, f"R{tile_reg - 0x60}" if tile_reg >= 0x60 else str(tile_reg))
                        pc += 1
                        lines.append(format_line(ctrl_start, pc, f"DRAWTILE {tile_name}"))
                    elif ctrl >= 0xC8:
                        pc -= 1  # Put it back, it's an opcode
                        break
            else:
                lines.append(format_line(start_pc, pc, "DRAWTILE (incomplete)"))
        elif opcode == 0xF8:  # DRAWTILE INC_X
            if pc < len(bytecode):
                tile_reg = bytecode[pc]
                tile_name = REG_NAMES.get(tile_reg, f"R{tile_reg - 0x60}" if tile_reg >= 0x60 else str(tile_reg))
                pc += 1
                lines.append(format_line(start_pc, pc, f"DRAWTILE {tile_name}"))
                lines.append(format_continuation("INC X"))
                while pc < len(bytecode) and bytecode[pc] < 0xC8:
                    ctrl_start = pc
                    ctrl = bytecode[pc]
                    pc += 1
                    if ctrl == 0x80 and pc < len(bytecode):
                        tile_reg = bytecode[pc]
                        tile_name = REG_NAMES.get(tile_reg, f"R{tile_reg - 0x60}" if tile_reg >= 0x60 else str(tile_reg))
                        pc += 1
                        lines.append(format_line(ctrl_start, pc, f"DRAWTILE {tile_name}"))
                        lines.append(format_continuation("INC X"))
                    elif ctrl == 0x81 and pc < len(bytecode):
                        tile_reg = bytecode[pc]
                        tile_name = REG_NAMES.get(tile_reg, f"R{tile_reg - 0x60}" if tile_reg >= 0x60 else str(tile_reg))
                        pc += 1
                        lines.append(format_line(ctrl_start, pc, f"DRAWTILE {tile_name}"))
                    elif ctrl >= 0xC8:
                        pc -= 1
                        break
            else:
                lines.append(format_line(start_pc, pc, "DRAWTILE (incomplete)"))
        elif opcode == 0xEB:  # DRAWTILE DEC_X
            if pc < len(bytecode):
                tile_reg = bytecode[pc]
                tile_name = REG_NAMES.get(tile_reg, f"R{tile_reg - 0x60}" if tile_reg >= 0x60 else str(tile_reg))
                pc += 1
                lines.append(format_line(start_pc, pc, f"DRAWTILE {tile_name}"))
                lines.append(format_continuation("DEC X"))
                while pc < len(bytecode) and bytecode[pc] < 0xC8:
                    ctrl_start = pc
                    ctrl = bytecode[pc]
                    pc += 1
                    if ctrl == 0x80 and pc < len(bytecode):
                        tile_reg = bytecode[pc]
                        tile_name = REG_NAMES.get(tile_reg, f"R{tile_reg - 0x60}" if tile_reg >= 0x60 else str(tile_reg))
                        pc += 1
                        lines.append(format_line(ctrl_start, pc, f"DRAWTILE {tile_name}"))
                        lines.append(format_continuation("DEC X"))
                    elif ctrl == 0x81 and pc < len(bytecode):
                        tile_reg = bytecode[pc]
                        tile_name = REG_NAMES.get(tile_reg, f"R{tile_reg - 0x60}" if tile_reg >= 0x60 else str(tile_reg))
                        pc += 1
                        lines.append(format_line(ctrl_start, pc, f"DRAWTILE {tile_name}"))
                    elif ctrl >= 0xC8:
                        pc -= 1
                        break
            else:
                lines.append(format_line(start_pc, pc, "DRAWTILE (incomplete)"))
        elif opcode == 0xF2:  # ADD Y
            expr_str, pc = decode_expr_to_string(bytecode, pc)
            lines.append(format_line(start_pc, pc, f"LD Y, {expr_str}+Y"))
        elif opcode == 0xF1:  # ADD X
            expr_str, pc = decode_expr_to_string(bytecode, pc)
            lines.append(format_line(start_pc, pc, f"LD X, {expr_str}+X"))
        elif opcode == 0xFE:
            lines.append(format_line(start_pc, pc, "WHILE PARAM1"))
        elif opcode == 0xFD:
            lines.append(format_line(start_pc, pc, "WHILE PARAM2"))
        elif opcode == 0xFC:
            lines.append(format_line(start_pc, pc, "PUSH X"))
            lines.append(format_continuation("PUSH Y"))
        elif opcode == 0xFB:
            lines.append(format_line(start_pc, pc, "POP Y"))
            lines.append(format_continuation("POP X"))
        elif opcode == 0xFA:
            lines.append(format_line(start_pc, pc, "ENDWHILE"))
        elif opcode == 0xF6:
            lines.append(format_line(start_pc, pc, "INC Y"))
        elif opcode == 0xF5:
            lines.append(format_line(start_pc, pc, "INC X"))
        elif opcode == 0xF4:
            lines.append(format_line(start_pc, pc, "DEC Y"))
        elif opcode == 0xF3:
            lines.append(format_line(start_pc, pc, "DEC X"))
        elif opcode == 0xF0:
            lines.append(format_line(start_pc, pc, "INC PARAM1"))
        elif opcode == 0xEF:
            lines.append(format_line(start_pc, pc, "INC PARAM2"))
        elif opcode == 0xEE:
            lines.append(format_line(start_pc, pc, "DEC PARAM1"))
        elif opcode == 0xED:
            lines.append(format_line(start_pc, pc, "DEC PARAM2"))
        elif opcode in [0xE9, 0xE8, 0xE7, 0xE6, 0xE5]:
            lines.append(format_line(start_pc, pc, "FLIP X"))
        elif opcode == 0xE0:
            lines.append(format_line(start_pc, pc, "NOP"))
        elif opcode < 0xE0:
            # Likely a tile header pointer
            if pc < len(bytecode):
                high = bytecode[pc]
                addr = (high << 8) | opcode
                pc += 1
                lines.append(format_line(start_pc, pc, f"TILE_HEADER 0x{addr:04X}"))
            else:
                lines.append(format_line(start_pc, pc, f"UNKNOWN 0x{opcode:02X}"))
        else:
            lines.append(format_line(start_pc, pc, f"UNKNOWN 0x{opcode:02X}"))

    lines.append("---")
    return lines


def main():
    output_dir = "src/abadia/resources/generated_blocks"
    os.makedirs(output_dir, exist_ok=True)

    print(f"Output directory: {output_dir}")

    tiles = AbbeyTiles(palette='day')
    interpreter = AbadiaInterpreter(tiles)
    
    # Collect all occurrences
    block_occurrences = {} # block_id -> list of (room_id, index, block_entry)
    
    for room_id in sorted(ROOM_DEFINITIONS.keys()):
        room = ROOM_DEFINITIONS[room_id]
        for i, block_entry in enumerate(room.blocks):
            block_id = block_entry.block_id
            if block_id not in BLOCK_DEFINITIONS:
                continue
            
            if block_id not in block_occurrences:
                block_occurrences[block_id] = []
            block_occurrences[block_id].append((room_id, i, block_entry))

    # Process each block type found in rooms
    for block_id in sorted(block_occurrences.keys()):
        occurrences = block_occurrences[block_id]

        # Find best occurrence (visible)
        # Buffer is 16x20 tiles with offset 8, so visible range: x in [8, 23], y in [8, 27]
        # Prefer occurrences closer to center (more room for block content)
        selected = occurrences[0]
        found_visible = False
        best_score = -1
        for occ in occurrences:
            entry = occ[2]
            # Check if likely visible within buffer bounds
            if 8 <= entry.x_pos <= 20 and 8 <= entry.y_pos <= 27:
                # Score based on distance from edges (higher Y is better for downward-drawing blocks)
                score = min(entry.x_pos - 8, 20 - entry.x_pos) + entry.y_pos
                if score > best_score:
                    selected = occ
                    best_score = score
                    found_visible = True

        room_id, i, block_entry = selected

        print(f"Processing Block Type {block_id} (0x{block_id:02X}) from Room {room_id} (Block {i})...")

        # Setup Canvas
        canvas = BufferedCanvas(tiles, bg_color=(50, 50, 50))
        block_def = BLOCK_DEFINITIONS[block_id]

        # Extract parameters
        x = block_entry.x_pos
        y = block_entry.y_pos
        p1 = block_entry.x_length if block_entry.x_length > 0 else 1
        p2 = block_entry.y_length if block_entry.y_length > 0 else 1
        h = block_entry.extra_param if block_entry.extra_param is not None else 0

        # If no visible occurrence found, adjust coordinates to make it visible
        # The buffer has an offset of 8, so we need x >= 8 for visibility
        if not found_visible:
            x_offset = max(0, 10 - x)  # Shift to at least x=10
            y_offset = max(0, 15 - y)  # Shift to at least y=15
            x += x_offset
            y += y_offset
            print(f"  -> Adjusted coords by ({x_offset}, {y_offset}) for visibility")
        
        # Execute with tracing
        interpreter.execute(
            block_def, 
            canvas, 
            start_x=x, 
            start_y=y, 
            param1=p1, 
            param2=p2, 
            height=h, 
            prio=i, 
            trace=True
        )
        
        # Save Trace to individual log file
        logs = interpreter.get_trace_log()
        log_path = os.path.join(output_dir, f"block_{block_id}.log")
        with open(log_path, "w") as f:
            f.write(f"BLOCK TRACE: #{block_id}\n")
            f.write(f"SOURCE ROOM: {room_id}\n")
            f.write(f"BLOCK PARAMS: x={x}, y={y}, h={h}, p1={p1}, p2={p2}\n\n")

            # Add bytecode disassembly
            disasm = disassemble_bytecode(block_def.bytecode, block_def.tile_data)
            for line in disasm:
                f.write(line + "\n")
            f.write("\n")

            f.write("[EXECUTION LOG]\n")
            for line in logs:
                f.write(line + "\n")

        # Render and Save Image
        canvas.render()
        img_path = os.path.join(output_dir, f"block_{block_id}.png")
        canvas.save(img_path)

    # Process orphaned blocks
    all_defined_blocks = set(BLOCK_DEFINITIONS.keys())
    found_blocks = set(block_occurrences.keys())
    orphans = all_defined_blocks - found_blocks
    
    for block_id in sorted(orphans):
        print(f"Processing Orphan Block Type {block_id} (0x{block_id:02X})...")
        
        canvas = BufferedCanvas(tiles, bg_color=(50, 50, 50))
        block_def = BLOCK_DEFINITIONS[block_id]
        
        # Default parameters for orphans
        x, y, h = 10, 10, 0
        p1, p2 = 4, 4 # Give them some size
        
        interpreter.execute(
            block_def, 
            canvas, 
            start_x=x, 
            start_y=y, 
            param1=p1, 
            param2=p2, 
            height=h, 
            prio=0, 
            trace=True
        )
        
        logs = interpreter.get_trace_log()
        log_path = os.path.join(output_dir, f"block_{block_id}.log")
        with open(log_path, "w") as f:
            f.write(f"BLOCK TRACE: #{block_id}\n")
            f.write(f"SOURCE ROOM: Manual (Not found in rooms)\n")
            f.write(f"BLOCK PARAMS: x={x}, y={y}, h={h}, p1={p1}, p2={p2}\n\n")

            # Add bytecode disassembly
            disasm = disassemble_bytecode(block_def.bytecode, block_def.tile_data)
            for line in disasm:
                f.write(line + "\n")
            f.write("\n")

            f.write("[EXECUTION LOG]\n")
            for line in logs:
                f.write(line + "\n")

        canvas.render()
        img_path = os.path.join(output_dir, f"block_{block_id}.png")
        canvas.save(img_path)

    print(f"Finished. Processed {len(block_occurrences)} found blocks + {len(orphans)} orphans.")

if __name__ == "__main__":
    main()
