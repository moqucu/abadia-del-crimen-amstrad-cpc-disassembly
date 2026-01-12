#!/usr/bin/env python3
"""
Trace execution of a single block to understand control flow
"""

import os
import sys
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from abadia.graphics import AbbeyTiles, AbbeyCanvas
from abadia.abbey_blocks_library import BLOCK_DEFINITIONS

class TracingInterpreter:
    """Interpreter with detailed execution tracing"""

    def __init__(self, tiles):
        self.tiles = tiles
        self.canvas = None

        # Load Memory
        self.memory = bytearray(65536)
        memory_file = 'src/abadia/resources/abbey_code.bin'
        if os.path.exists(memory_file):
            with open(memory_file, 'rb') as f:
                self.memory = bytearray(f.read())

        self.regs = [0] * 32
        self.call_stack = []
        self.pc = 0
        self.h = 0
        self.l = 0
        self.iteration_count = 0
        self.max_iterations = 200  # Lower for tracing

        self.trace_log = []

    def log(self, msg):
        self.trace_log.append(msg)
        if len(self.trace_log) <= 50:  # Print first 50
            print(msg)

    def execute(self, block_def, canvas, start_x, start_y, param1, param2):
        self.canvas = canvas
        self.pc = block_def.address + 2
        self.h = start_y
        self.l = start_x
        self.regs[13] = param2
        self.regs[14] = param1
        self.iteration_count = 0

        # Load tile data
        if hasattr(block_def, 'tile_data') and block_def.tile_data:
            for i, val in enumerate(block_def.tile_data):
                if i < 12:
                    self.regs[2 + i] = val

        self.log(f'=== Starting Block 0x{block_def.block_id:02X} ===')
        self.log(f'Start PC: 0x{self.pc:04X}, Pos: ({self.l},{self.h}), Params: ({param1},{param2})')

        while True:
            self.iteration_count += 1
            if self.iteration_count > self.max_iterations:
                self.log(f'!!! Max iterations reached')
                break

            if self.pc >= len(self.memory):
                self.log(f'!!! PC out of bounds: 0x{self.pc:04X}')
                break

            opcode = self.memory[self.pc]
            pc_before = self.pc
            self.pc += 1

            # Log the opcode
            if opcode >= 0xE4:
                self.log(f'{self.iteration_count:3d}. PC=0x{pc_before:04X} Op=0x{opcode:02X} Pos=({self.l},{self.h})')

            if opcode == 0xFF:
                self.log(f'     -> END')
                break
            elif opcode == 0xEA:  # ChangePC
                high = self.memory[self.pc]
                low = self.memory[self.pc + 1]
                self.pc += 2
                addr = (high << 8) | low
                self.log(f'     -> JUMP to 0x{addr:04X}')
                self.pc = addr
            elif opcode == 0xEC:  # CallBlock
                high = self.memory[self.pc]
                low = self.memory[self.pc + 1]
                self.pc += 2
                addr = (high << 8) | low
                self.call_stack.append(self.pc)
                self.log(f'     -> CALL 0x{addr:04X} (return to 0x{self.pc:04X})')
                self.pc = addr
            elif opcode == 0xFE:  # Loop Param1
                count = self.regs[14]
                self.log(f'     -> LOOP Param1={count}')
            elif opcode == 0xFD:  # Loop Param2
                count = self.regs[13]
                self.log(f'     -> LOOP Param2={count}')
            elif opcode == 0xF9:  # PaintTile DecY
                self.log(f'     -> PAINT DecY')
            elif opcode == 0xF8:  # PaintTile IncX
                self.log(f'     -> PAINT IncX')
            elif opcode < 0xE4:
                if len(self.call_stack) > 0:
                    ret_addr = self.call_stack.pop()
                    self.log(f'{self.iteration_count:3d}. PC=0x{pc_before:04X} Op=0x{opcode:02X} <- RETURN to 0x{ret_addr:04X}')
                    self.pc = ret_addr
                else:
                    self.log(f'{self.iteration_count:3d}. PC=0x{pc_before:04X} Op=0x{opcode:02X} NON-BLOCK (no return addr), continue')

def main():
    print("="*80)
    print("TRACING Block 0x0F Execution")
    print("="*80)

    block_def = BLOCK_DEFINITIONS[0x0F]
    tiles = AbbeyTiles(palette='day')
    canvas = AbbeyCanvas(15, 15)

    tracer = TracingInterpreter(tiles)
    tracer.execute(block_def, canvas, 7, 7, param1=1, param2=1)

    print(f"\n{'='*80}")
    print(f"Total iterations: {tracer.iteration_count}")
    print(f"Final position: ({tracer.l}, {tracer.h})")
    print(f"Call stack remaining: {len(tracer.call_stack)}")
    print(f"{'='*80}")

if __name__ == "__main__":
    main()
