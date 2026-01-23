#!/usr/bin/env python3
"""
Generate trace for Room 0 to compare with debug_trace.txt
"""

import os
import sys

# Add src to path if needed
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from abadia.room_renderer import RoomRenderer

def main():
    print("Generating trace for Room 0...")
    
    renderer = RoomRenderer(palette='day')
    canvas = renderer.render_room(0, output_path="trace_room_00.png")
    
    trace_lines = canvas.get_trace()
    
    output_file = "trace_python_room_00.txt"
    with open(output_file, "w") as f:
        f.write("Room 0:\n")
        for line in trace_lines:
            f.write("  " + line + "\n")
            
    print(f"Trace written to {output_file}")
    
    # Print first few lines for verification
    print("First 10 lines of trace:")
    for i in range(min(10, len(trace_lines))):
        print(trace_lines[i])

if __name__ == "__main__":
    main()

