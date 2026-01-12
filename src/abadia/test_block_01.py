#!/usr/bin/env python3
"""
Test script for verifying Block 0x01 rendering.
"""
from src.abadia.graphics import AbbeyTiles, AbbeyCanvas
from src.abadia.interpreter import AbadiaInterpreter
from src.abadia.abbey_blocks_library import BLOCK_DEFINITIONS

def test_block_01():
    print("Testing Block 0x01...")
    if 0x01 not in BLOCK_DEFINITIONS:
        print("Block 0x01 not found!")
        return

    block = BLOCK_DEFINITIONS[0x01]
    tiles = AbbeyTiles()
    canvas = AbbeyCanvas(20, 20, bg_color=(50, 50, 50))
    interpreter = AbadiaInterpreter(tiles)

    # Force debug prints by modifying the class instance or method if possible,
    # or rely on the prints I added previously to interpreter.py (which I should verify).
    
    print(f"Executing Block 0x01 with Param1=4, Param2=4")
    try:
        interpreter.execute(block, canvas, 10, 10, param1=4, param2=4)
        print("Execution finished successfully.")
        canvas.save("debug_block_01.png")
        print("Saved debug_block_01.png")
    except Exception as e:
        print(f"CRASH: {e}")
        import traceback
        traceback.print_exc()

    print("\nTesting Block 0x0F...")
    if 0x0F in BLOCK_DEFINITIONS:
        block_0f = BLOCK_DEFINITIONS[0x0F]
        print(f"Executing Block 0x0F ({block_0f.description})")
        try:
            interpreter.execute(block_0f, canvas, 10, 10, param1=4, param2=4)
            print("Execution finished successfully.")
            canvas.save("debug_block_0F.png")
        except Exception as e:
            print(f"CRASH: {e}")
            import traceback
            traceback.print_exc()
    else:
        print("Block 0x0F not found.")

if __name__ == "__main__":
    test_block_01()
