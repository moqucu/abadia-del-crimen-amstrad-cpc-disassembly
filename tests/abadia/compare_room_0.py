#!/usr/bin/env python3
import json
import sys
import os

# Add src to path
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from abadia.abbey_rooms_library import ROOM_DEFINITIONS

def compare_rooms():
    # Load JSON
    try:
        with open("/Users/seikenberg/GitHub/abadia/public/assets/abadia/rooms.json", "r") as f:
            ref_rooms = json.load(f)
    except FileNotFoundError:
        print("Error: Could not find reference rooms.json")
        return

    # Find Room 0 in JSON
    ref_room_0 = next((r for r in ref_rooms if r["id"] == 0), None)
    if not ref_room_0:
        print("Error: Room 0 not found in reference JSON")
        return

    my_room_0 = ROOM_DEFINITIONS[0]

    print(f"Comparing Room 0...")
    print(f"  My Blocks: {len(my_room_0.blocks)}")
    print(f"  Ref Blocks: {len(ref_room_0['blocks'])}")
    print("-" * 100)
    print(f"{'Idx':<4} | {'My ID':<6} {'(x2)':<6} {'Pos':<8} {'Size':<6} {'Ext':<4} | {'Ref ID':<6} {'Pos':<8} {'Size':<6} {'H':<4} | {'Status'}")
    print("-" * 100)

    max_len = max(len(my_room_0.blocks), len(ref_room_0['blocks']))

    for i in range(max_len):
        # My Block Data
        my_str = ""
        my_id_x2 = ""
        status = ""
        
        if i < len(my_room_0.blocks):
            mb = my_room_0.blocks[i]
            my_id_x2 = f"{mb.block_id * 2}"
            my_str = f"0x{mb.block_id:02X}   {my_id_x2:<6} ({mb.x_pos},{mb.y_pos}) {mb.x_length}x{mb.y_length}  {str(mb.extra_param):<4}"
        else:
            my_str = f"{'MISSING':<35}"

        # Ref Block Data
        ref_str = ""
        if i < len(ref_room_0['blocks']):
            rb = ref_room_0['blocks'][i]
            ref_str = f"{rb['type']:<6} ({rb['x']},{rb['y']}) {rb['param1']}x{rb['param2']}  {rb['height']:<4}"
        else:
            ref_str = f"{'MISSING':<30}"

        # Compare
        if i < len(my_room_0.blocks) and i < len(ref_room_0['blocks']):
            mb = my_room_0.blocks[i]
            rb = ref_room_0['blocks'][i]
            
            id_match = (mb.block_id * 2 == rb['type'])
            pos_match = (mb.x_pos == rb['x'] and mb.y_pos == rb['y'])
            size_match = (mb.x_length == rb['param1'] and mb.y_length == rb['param2'])
            
            # loose height check (None -> 255??)
            h_match = False
            if mb.extra_param is None and rb['height'] == 255:
                h_match = True
            elif mb.extra_param == rb['height']:
                h_match = True
            
            if not id_match: status += "ID_MIS "
            if not pos_match: status += "POS_MIS "
            if not size_match: status += "SIZ_MIS "
            if not h_match: status += "H_MIS "
            
            if status == "": status = "OK"
        else:
            status = "LEN_MIS"

        print(f"{i:<4} | {my_str} | {ref_str} | {status}")

if __name__ == "__main__":
    compare_rooms()
