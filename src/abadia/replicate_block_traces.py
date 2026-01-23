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
from abadia.interpreter import AbadiaInterpreter

def main():
    output_dir = "generated_blocks_python"
    os.makedirs(output_dir, exist_ok=True)
    trace_file = os.path.join(output_dir, "block_traces.log")
    
    print(f"Output directory: {output_dir}")
    print(f"Trace file: {trace_file}")
    
    # Clear trace file
    with open(trace_file, "w") as f:
        f.write("Python Generated Block Traces\n")

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
        selected = occurrences[0]
        for occ in occurrences:
            entry = occ[2]
            # Check if likely visible (buffer coords >= 0)
            # Offset is 8. So need x >= 8, y >= 8.
            if entry.x_pos >= 8 and entry.y_pos >= 8:
                selected = occ
                break
        
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
        
        # Save Trace
        logs = interpreter.get_trace_log()
        with open(trace_file, "a") as f:
            f.write(f"\n=== TRACE START: Block Type {block_id} ===\n")
            f.write(f"Source: Room {room_id}, Block Index {i} (x={x}, y={y}, h={h}, p1={p1}, p2={p2})\n")
            for line in logs:
                f.write(line + "\n")
        
        # Render and Save Image
        canvas.render()
        img_path = os.path.join(output_dir, f"block_type_{block_id}.png")
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
        with open(trace_file, "a") as f:
            f.write(f"\n=== TRACE START: Block Type {block_id} ===\n")
            f.write(f"Source: Manual (Not found in rooms) (x={x}, y={y}, h={h}, p1={p1}, p2={p2})\n")
            for line in logs:
                f.write(line + "\n")
        
        canvas.render()
        img_path = os.path.join(output_dir, f"block_type_{block_id}.png")
        canvas.save(img_path)

    print(f"Finished. Processed {len(block_occurrences)} found blocks + {len(orphans)} orphans.")

if __name__ == "__main__":
    main()
