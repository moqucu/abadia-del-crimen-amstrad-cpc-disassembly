"""
Opcode Definitions for La Abadia del Crimen Block Bytecode.

This is the SINGLE SOURCE OF TRUTH for all bytecode opcodes used by the
building block interpreter. Both interpreter.py and dsl_converter.py
import from this module.

OPCODE STRUCTURE:
-----------------
Each opcode has:
  - value: The byte value (0x00-0xFF)
  - name: Human-readable name for tracing/DSL
  - operands: What follows the opcode ("none", "address", "reg_expr", "expr", "tile_seq")
  - category: Grouping for documentation

OPERAND TYPES:
--------------
  none      - No operands
  address   - 2-byte little-endian address (for CALL/JMP)
  reg_expr  - Register byte followed by expression (for LD)
  expr      - Expression (for ADD X/Y)
  tile_seq  - Tile painting sequence with control bytes (for DRAWTILE)
"""

from dataclasses import dataclass
from typing import Dict


@dataclass
class OpcodeDef:
    """Definition of a single opcode."""
    value: int
    name: str
    operands: str = "none"
    category: str = "misc"
    description: str = ""


# Master opcode table - the single source of truth
OPCODES: Dict[int, OpcodeDef] = {
    # Termination / Control Flow
    0xFF: OpcodeDef(0xFF, "END", "none", "control", "End script or return from subroutine"),
    0x00: OpcodeDef(0x00, "END", "none", "control", "Alternative end marker"),

    # Loops
    0xFE: OpcodeDef(0xFE, "WHILE PARAM1", "none", "loop", "Loop using PARAM1 as counter"),
    0xFD: OpcodeDef(0xFD, "WHILE PARAM2", "none", "loop", "Loop using PARAM2 as counter"),
    0xFA: OpcodeDef(0xFA, "ENDWHILE", "none", "loop", "End of loop body"),

    # Position Stack
    0xFC: OpcodeDef(0xFC, "PUSH POS", "none", "stack", "Push current X,Y position"),
    0xFB: OpcodeDef(0xFB, "POP POS", "none", "stack", "Restore X,Y position"),

    # Tile Drawing
    0xF9: OpcodeDef(0xF9, "DRAWTILE DEC_Y", "tile_seq", "draw", "Draw tile(s), then DEC Y"),
    0xF8: OpcodeDef(0xF8, "DRAWTILE INC_X", "tile_seq", "draw", "Draw tile(s), then INC X"),
    0xEB: OpcodeDef(0xEB, "DRAWTILE DEC_X", "tile_seq", "draw", "Draw tile(s), then DEC X"),

    # Register Operations
    0xF7: OpcodeDef(0xF7, "LD", "reg_expr", "register", "Load register with expression"),

    # Coordinate Increment/Decrement
    0xF6: OpcodeDef(0xF6, "INC Y", "none", "coord", "Increment Y coordinate"),
    0xF5: OpcodeDef(0xF5, "INC X", "none", "coord", "Increment X coordinate"),
    0xF4: OpcodeDef(0xF4, "DEC Y", "none", "coord", "Decrement Y coordinate"),
    0xF3: OpcodeDef(0xF3, "DEC X", "none", "coord", "Decrement X coordinate"),

    # Coordinate Add
    0xF2: OpcodeDef(0xF2, "ADD Y", "expr", "coord", "Add expression to Y"),
    0xF1: OpcodeDef(0xF1, "ADD X", "expr", "coord", "Add expression to X"),

    # Parameter Increment/Decrement
    0xF0: OpcodeDef(0xF0, "INC PARAM1", "none", "param", "Increment PARAM1 register"),
    0xEF: OpcodeDef(0xEF, "INC PARAM2", "none", "param", "Increment PARAM2 register"),
    0xEE: OpcodeDef(0xEE, "DEC PARAM1", "none", "param", "Decrement PARAM1 register"),
    0xED: OpcodeDef(0xED, "DEC PARAM2", "none", "param", "Decrement PARAM2 register"),

    # Subroutine Calls
    0xEC: OpcodeDef(0xEC, "CALL", "address", "call", "Call subroutine (saves state, loads tiles)"),
    0xEA: OpcodeDef(0xEA, "JMP", "address", "call", "Jump to address (no return, terminal)"),
    0xE4: OpcodeDef(0xE4, "CALL_PRESERVE", "address", "call", "Call subroutine (preserves tileset)"),

    # Flip Mode
    0xE9: OpcodeDef(0xE9, "FLIP X", "none", "flip", "Toggle X mirror mode"),
    0xE8: OpcodeDef(0xE8, "FLIP X", "none", "flip", "Toggle X mirror mode (variant)"),
    0xE7: OpcodeDef(0xE7, "FLIP X", "none", "flip", "Toggle X mirror mode (variant)"),
    0xE6: OpcodeDef(0xE6, "FLIP X", "none", "flip", "Toggle X mirror mode (variant)"),
    0xE5: OpcodeDef(0xE5, "FLIP X", "none", "flip", "Toggle X mirror mode (variant)"),

    # No Operation
    0xE0: OpcodeDef(0xE0, "NOP", "none", "misc", "No operation"),

    # Skip opcodes (consume 2 bytes but do nothing meaningful)
    0xC2: OpcodeDef(0xC2, "SKIP_2", "none", "misc", "Skip 2 bytes"),
    0xC6: OpcodeDef(0xC6, "SKIP_2", "none", "misc", "Skip 2 bytes"),
    0xB6: OpcodeDef(0xB6, "SKIP_2", "none", "misc", "Skip 2 bytes"),
    0xBA: OpcodeDef(0xBA, "SKIP_2", "none", "misc", "Skip 2 bytes"),
}


# Register name mappings
REGISTER_NAMES: Dict[int, str] = {
    0x6D: "PARAM1",
    0x6E: "PARAM2",
    0x6F: "HEIGHT",
    0x70: "DEPTHX",
    0x71: "DEPTHY",
    0x72: "HEIGHT2",
}

# Add T0-T11 (tile registers)
for i in range(12):
    REGISTER_NAMES[0x61 + i] = f"T{i}"


def get_opcode_name(opcode: int) -> str:
    """Get the name of an opcode, or a formatted unknown string."""
    if opcode in OPCODES:
        return OPCODES[opcode].name
    if opcode < 0xE0:
        return "TILE_HEADER"
    return f"UNK_{opcode:02X}"


def get_register_name(reg_byte: int) -> str:
    """Get the name of a register, or a formatted string."""
    if reg_byte in REGISTER_NAMES:
        return REGISTER_NAMES[reg_byte]
    if reg_byte >= 0x60:
        return f"REG{reg_byte:02X}"
    return str(reg_byte)


def is_opcode(byte_val: int) -> bool:
    """Check if a byte value is an opcode (>= 0xC8) or tile header (< 0xE0)."""
    return byte_val >= 0xC8 or byte_val < 0xE0


def is_terminal(opcode: int) -> bool:
    """Check if an opcode terminates execution (END or JMP)."""
    return opcode in (0xFF, 0x00, 0xEA)


# Legacy compatibility: OPCODE_NAMES dict for existing code
OPCODE_NAMES: Dict[int, str] = {op.value: op.name for op in OPCODES.values()}
