#!/usr/bin/env python3
"""
Trace the actual execution of Block 0x0C bytecode step-by-step
"""
import os
import sys
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from abadia.graphics import AbbeyTiles, AbbeyCanvas
from abadia.abbey_blocks_library import BLOCK_DEFINITIONS

# Create a modified interpreter with detailed logging
class TracingInterpreter:
    def __init__(self, tiles):
        self.tiles = tiles
        self.regs = {}
        self.l = 0
        self.h = 0
        self.iteration_count = 0
        self.max_iterations = 50000
        self.trace_log = []

    def log(self, msg):
        self.trace_log.append(f"[{self.iteration_count:4d}] L={self.l:2d} H={self.h:2d} | {msg}")

    def execute(self, block_def, canvas, start_l, start_h, param1=0, param2=0):
        self.l = start_l
        self.h = start_h
        self.iteration_count = 0
        self.trace_log = []

        # Initialize registers with tile data
        for i, tile_id in enumerate(block_def.tile_data, 1):
            self.regs[i] = tile_id

        # Initialize params
        self.regs[71] = param1  # 0x47
        self.regs[72] = param2  # 0x48

        self.log(f"START: Block 0x{block_def.block_id:02X}, params=({param1},{param2})")

        # Execute bytecode
        pc = 0  # program counter
        bytecode = block_def.bytecode
        stack = []
        loop_stack = []

        while pc < len(bytecode):
            self.iteration_count += 1
            if self.iteration_count > self.max_iterations:
                self.log(f"MAX ITERATIONS EXCEEDED")
                break

            opcode = bytecode[pc]

            if opcode == 0xFF:  # END
                self.log(f"PC={pc:3d}: END")
                break
            elif opcode == 0xF9:  # PAINT_TILE
                reg = bytecode[pc + 1]
                tile_id = self.regs.get(reg, 0)
                self.log(f"PC={pc:3d}: PAINT_TILE reg[{reg}]=0x{tile_id:02X}")
                tile = self.tiles.get(tile_id)
                canvas.draw_tile(tile, self.l, self.h)
                pc += 2
                continue
            elif opcode == 0xFA:  # DEC_Y
                self.h -= 1
                self.log(f"PC={pc:3d}: DEC_Y -> H={self.h}")
                pc += 1
                continue
            elif opcode == 0xF6:  # INC_X
                self.l += 1
                self.log(f"PC={pc:3d}: INC_X -> L={self.l}")
                pc += 1
                continue
            elif opcode == 0xFE:  # LOOP_START
                loop_reg = self.regs.get(71, 0)  # Usually param1
                self.log(f"PC={pc:3d}: LOOP_START count={loop_reg}")
                loop_stack.append({'start': pc + 1, 'counter': loop_reg})
                pc += 1
                continue
            elif opcode == 0xFD:  # LOOP_END
                if loop_stack:
                    loop = loop_stack[-1]
                    loop['counter'] -= 1
                    if loop['counter'] > 0:
                        self.log(f"PC={pc:3d}: LOOP_END -> repeat, counter={loop['counter']}")
                        pc = loop['start']
                    else:
                        self.log(f"PC={pc:3d}: LOOP_END -> exit loop")
                        loop_stack.pop()
                        pc += 1
                else:
                    pc += 1
                continue
            elif opcode == 0xF4:  # INC_X_DEC_Y
                self.l += 1
                self.h -= 1
                self.log(f"PC={pc:3d}: INC_X_DEC_Y -> L={self.l}, H={self.h}")
                pc += 1
                continue
            else:
                # Unknown opcode - skip it for now
                pc += 1
                continue

print("="*80)
print("BLOCK 0x0C EXECUTION TRACE")
print("="*80)

block_def = BLOCK_DEFINITIONS[0x0C]
tiles = AbbeyTiles(palette='day')
canvas = AbbeyCanvas(15, 20, bg_color=(128, 128, 128))

interpreter = TracingInterpreter(tiles)
interpreter.execute(block_def, canvas, 5, 12, param1=1, param2=1)

print(f"\nExecution completed in {interpreter.iteration_count} iterations")
print(f"\nExecution trace (first 50 steps):")
for line in interpreter.trace_log[:50]:
    print(line)

if len(interpreter.trace_log) > 50:
    print(f"\n... ({len(interpreter.trace_log) - 50} more lines)")
    print("\nLast 10 steps:")
    for line in interpreter.trace_log[-10:]:
        print(line)
