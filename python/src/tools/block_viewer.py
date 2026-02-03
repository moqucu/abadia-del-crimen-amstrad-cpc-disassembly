#!/usr/bin/env python3
"""
Block Generation Script
Implementation of BLOCK_GENERATION_SPEC.md

Goals:
1. Iterate all rooms to find the FIRST occurrence of each Block Type (Script ID).
2. Render that specific block instance with its actual parameters.
3. Save as `generated_blocks/block_{SCRIPT_ID}.png`.
4. Generate a log `generated_blocks/block_{SCRIPT_ID}.log` matching the spec.
"""

import os

from engine import Tiles, BufferedCanvas, AbadiaInterpreter
from data import BLOCK_DEFINITIONS, ROOM_DEFINITIONS

OUTPUT_DIR = "python/resources/generated_blocks"

from PIL import Image

def upscale_image(image, scale):
    """
    Upscale an image by a factor using nearest neighbor interpolation.
    """
    new_size = (image.width * scale, image.height * scale)
    return image.resize(new_size, Image.NEAREST)

def scan_for_unique_blocks():
    """
    Scans all rooms to find the first instance of every Script ID.
    Returns a dict: {script_id: (room_id, block_index, block_entry)}
    """
    unique_blocks = {}
    
    # Iterate Rooms 0 to 115
    for room_id in sorted(ROOM_DEFINITIONS.keys()):
        room = ROOM_DEFINITIONS[room_id]
        
        for blk_idx, block in enumerate(room.blocks):
            script_id = block.block_id
            
            # If this script ID hasn't been seen yet, record it
            if script_id not in unique_blocks:
                unique_blocks[script_id] = (room_id, blk_idx, block)
                
    return unique_blocks

def generate_block_outputs(script_id, room_id, blk_idx, block_entry, scales=None, explode_factor=1.0):
    """
    Render the block and generate logs.
    """
    if scales is None:
        scales = [1]

    if script_id not in BLOCK_DEFINITIONS:
        print(f"Warning: Script ID {script_id} defined in Room {room_id} but not in Library")
        return

    block_def = BLOCK_DEFINITIONS[script_id]
    
    # Setup Engine
    # Transparent background (Alpha 0)
    tiles = Tiles(palette='day')
    
    # Determine canvas size
    # Default 16x20. If exploded, give more room (e.g. 32x32) to avoid clipping.
    if explode_factor > 1.0:
        width, height = 32, 32
    else:
        width, height = 16, 20
        
    # Origin for explosion is the block's start position
    origin = (block_entry.x_pos, block_entry.y_pos)
    
    canvas = BufferedCanvas(
        tiles, 
        bg_color=(0, 0, 0, 0), 
        width=width, 
        height=height,
        origin=origin,
        explode_factor=explode_factor
    ) 
    
    # Re-create as transparent RGBA image (BufferedCanvas creates RGB by default in some paths, but we force RGBA here)
    # Note: BufferedCanvas.__init__ creates 'RGB'. We replace it.
    # We must match the pixel dimensions calculated by BufferedCanvas
    canvas.image = Image.new('RGBA', canvas.image.size, (0, 0, 0, 0))
    canvas.buffer.clear() # clear internal buffer
    
    interpreter = AbadiaInterpreter(tiles)
    
    # Prepare params
    # If extra_param is None, use 255 (Floor) as per previous findings
    height_val = block_entry.extra_param if block_entry.extra_param is not None else 255
    # Do NOT clamp P1/P2 to 1. The script often increments them (e.g. Block 3).
    p1 = block_entry.x_length
    p2 = block_entry.y_length
    
    # Execute
    interpreter.execute(
        block_def,
        canvas,
        start_x=block_entry.x_pos,
        start_y=block_entry.y_pos,
        param1=p1,
        param2=p2,
        height=height_val,
        prio=blk_idx,
        trace=True
    )
    
    # Render (Z-Sort)
    canvas.render()
    
    # Save Image(s)
    explode_suffix = "_exploded" if explode_factor > 1.0 else ""
    filename_base = f"block_{script_id}{explode_suffix}"
    
    for scale in scales:
        if scale == 1:
            img_to_save = canvas.image
            suffix = ""
        else:
            img_to_save = upscale_image(canvas.image, scale)
            suffix = f"_x{scale}"
            
        png_path = os.path.join(OUTPUT_DIR, f"{filename_base}{suffix}.png")
        img_to_save.save(png_path)
    
    # Save Log
    log_path = os.path.join(OUTPUT_DIR, f"{filename_base}.log")
    
    js_room_id = room_id + 1
    raw_type = script_id * 2
    
    with open(log_path, "w") as f:
        # 1. Header
        f.write(f"BLOCK TRACE: #{script_id}\n")
        f.write(f"SOURCE ROOM: {js_room_id}\n")
        f.write(f"BLOCK PARAMS: x={block_entry.x_pos}, y={block_entry.y_pos}, h={height_val}, p1={p1}, p2={p2}, type={raw_type}, explode={explode_factor}\n")
        
        # 2. Script Source (Placeholder)
        f.write("\nSCRIPT SOURCE:\n")
        f.write("(Bytecode disassembly not available in text format)\n")
        
        # 3. Execution Trace
        f.write("\nEXECUTION TRACE:\n")
        trace_log = interpreter.get_trace_log()
        for line in trace_log:
            # Format is already similar, but we check specific requirements
            # Spec: [{SCRIPT_ID}:{LINE_NUM}] {OPCODE}
            # Ours: [{OFFSET}] {OPCODE}
            # Deviations allowed.
            f.write(line + "\n")

    print(f"Generated Block {script_id} (from Room {room_id})")

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    print("Scanning rooms for unique blocks...")
    unique_blocks = scan_for_unique_blocks()
    print(f"Found {len(unique_blocks)} unique block types.")
    
    for script_id in sorted(unique_blocks.keys()):
        room_id, blk_idx, block_entry = unique_blocks[script_id]
        # Standard
        generate_block_outputs(script_id, room_id, blk_idx, block_entry, scales=[1, 8])
        # Exploded (2.0x)
        generate_block_outputs(script_id, room_id, blk_idx, block_entry, scales=[1, 8], explode_factor=2.0)
        
    print("Done.")

if __name__ == "__main__":
    main()
