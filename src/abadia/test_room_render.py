#!/usr/bin/env python3
"""
Test script for verifying Room 0 rendering.
"""
from src.abadia.graphics import AbbeyTiles, AbbeyCanvas
from src.abadia.interpreter import AbadiaInterpreter
from src.abadia.abbey_blocks_library import BLOCK_DEFINITIONS
from src.abadia.abbey_rooms_library import ROOM_DEFINITIONS

def test_room_00():
    print("Testing Room 00...")
    if 0 not in ROOM_DEFINITIONS:
        print("Room 00 not found!")
        return

    room = ROOM_DEFINITIONS[0]
    print(f"Room 00 has {len(room.blocks)} blocks.")
    
    tiles = AbbeyTiles()
    canvas = AbbeyCanvas(40, 40, bg_color=(20, 20, 20)) # 640x320 approx
    interpreter = AbadiaInterpreter(tiles)

    for i, block_entry in enumerate(room.blocks):
        # block_entry is a dataclass BlockEntry
        b_id = block_entry.block_id
        x = block_entry.x_pos
        y = block_entry.y_pos
        lx = block_entry.x_length
        ly = block_entry.y_length
        
        if b_id not in BLOCK_DEFINITIONS:
            print(f"  Warning: Block 0x{b_id:02X} not found (Skipping)")
            continue
            
        block_def = BLOCK_DEFINITIONS[b_id]
        print(f"  [{i}] Drawing Block 0x{b_id:02X} at ({x},{y}) size ({lx},{ly})")
        
        try:
            # Note: Room coordinates might need transformation?
            # 1FB8: Grid -> Tile Buffer transformation.
            # Xgrid = Ymap + Xmap - 15
            # Ygrid = Ymap - Xmap + 16
            # The room data has Xmap, Ymap.
            # The interpreter expects Tile Buffer Coords?
            # Let's try raw first, then transform if it looks wrong.
            interpreter.execute(block_def, canvas, x, y, param1=lx, param2=ly)
        except Exception as e:
            print(f"  CRASH in Block 0x{b_id:02X}: {e}")
            import traceback
            traceback.print_exc()

    canvas.save("debug_room_00.png")
    print("Saved debug_room_00.png")

if __name__ == "__main__":
    test_room_00()
