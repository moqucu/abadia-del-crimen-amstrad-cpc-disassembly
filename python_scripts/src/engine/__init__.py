"""
Engine package for La Abadia del Crimen.

Core rendering, interpretation, and graphics subsystems.
"""

from .tiles import Tiles, AbbeyTiles
from .buffer import TileBuffer
from .canvas import Canvas, BufferedCanvas, AbbeyCanvas
from .interpreter import AbadiaInterpreter
from .opcodes import OPCODES, OPCODE_NAMES, REGISTER_NAMES, get_opcode_name, get_register_name
from .palette import CpcPalette
from .dsl import BytecodeToDSL, disassemble_single_block, disassemble_all_blocks

__all__ = [
    # Tiles
    'Tiles', 'AbbeyTiles',
    # Buffer
    'TileBuffer',
    # Canvas
    'Canvas', 'BufferedCanvas', 'AbbeyCanvas',
    # Interpreter
    'AbadiaInterpreter',
    # Opcodes
    'OPCODES', 'OPCODE_NAMES', 'REGISTER_NAMES', 'get_opcode_name', 'get_register_name',
    # Palette
    'CpcPalette',
    # DSL
    'BytecodeToDSL', 'disassemble_single_block', 'disassemble_all_blocks',
]
