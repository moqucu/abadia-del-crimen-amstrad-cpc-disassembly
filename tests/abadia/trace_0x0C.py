#!/usr/bin/env python3
"""
Trace Block 0x0C execution
"""
import os
import sys
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from abadia.graphics import AbbeyTiles
from abadia.abbey_blocks_library import BLOCK_DEFINITIONS
from abadia.trace_block_execution import TracingInterpreter, AbbeyCanvas

block_id = 0x0C
param1 = 1
param2 = 1

if block_id not in BLOCK_DEFINITIONS:
    print(f"Block 0x{block_id:02X} not found!")
    sys.exit(1)

block_def = BLOCK_DEFINITIONS[block_id]
tiles = AbbeyTiles(palette='day')
canvas = AbbeyCanvas(15, 15, bg_color=(128, 128, 128))

print("="*80)
print(f"TRACING Block 0x{block_id:02X} Execution")
print("="*80)

interpreter = TracingInterpreter(tiles)
interpreter.execute(block_def, canvas, 7, 7, param1, param2)

print("\n" + "="*80)
print(f"Total iterations: {interpreter.iteration_count}")
print(f"Final position: ({interpreter.l}, {interpreter.h})")
print(f"Call stack remaining: {len(interpreter.call_stack)}")
print("="*80)
