#!/usr/bin/env python3
"""
Room Renderer for La Abadía del Crimen

Renders complete rooms/screens using:
- Room definitions from abbey_rooms_library
- Block definitions from abbey_blocks_library
- AbadiaInterpreter to execute block scripts

Merged features from test suite:
- Robust error handling (skips bad blocks instead of crashing)
- JS-compatible numbering (Room 0 -> room_1)
- Cyan background color (0, 128, 128) for 'day' palette matches
- Detailed logging (Block params + Tile trace)
"""

import os
import sys

# Add src to path if needed
if os.path.exists('src'):
    sys.path.insert(0, 'src')

from abadia.graphics import AbbeyTiles, AbbeyCanvas, BufferedCanvas
from abadia.interpreter import AbadiaInterpreter
from abadia.abbey_blocks_library import BLOCK_DEFINITIONS
from abadia.abbey_rooms_library import ROOM_DEFINITIONS


class RoomRenderer:
    """Renders complete game rooms"""

    def __init__(self, palette='day'):
        """
        Initialize the renderer with a color palette

        Args:
            palette: 'day' or 'night'
        """
        self.tiles = AbbeyTiles(palette=palette)
        self.interpreter = AbadiaInterpreter(self.tiles)
        self.palette = palette

    def render_room(self, room_id: int, output_dir: str = None):
        """
        Render a complete room

        Args:
            room_id: Room ID (0-based)
            output_dir: Directory to save results

        Returns:
            BufferedCanvas with the rendered room
        """
        # Get room definition
        if room_id not in ROOM_DEFINITIONS:
            raise ValueError(f"Room {room_id} not found in ROOM_DEFINITIONS")

        room = ROOM_DEFINITIONS[room_id]
        js_room_id = room_id + 1  # JS uses 1-indexed room IDs
        
        print(f"\nRendering Room {room_id} (JS: {js_room_id})...")
        print(f"  Offset: 0x{room.file_offset:04X}")
        print(f"  Blocks: {len(room.blocks)}")

        # Create buffered canvas
        # Use Cyan background for Day palette to match JS debug output, Black for Night
        bg_color = (0, 128, 128) if self.palette == 'day' else (0, 0, 0)
        canvas = BufferedCanvas(self.tiles, bg_color=bg_color)

        # Logging collections
        used_block_ids = set()
        block_execution_trace = []
        all_draw_events = [] # Section 2: Chronological Events
        blocks_rendered = 0
        blocks_skipped = 0

        # Render each block in the room
        for i, block_entry in enumerate(room.blocks):
            block_id = block_entry.block_id
            used_block_ids.add(block_id)
            
            # Helper for logging
            h_val = block_entry.extra_param if block_entry.extra_param is not None else 255

            # Get block definition
            if block_id not in BLOCK_DEFINITIONS:
                print(f"  Warning: Block 0x{block_id:02X} not in library, skipping")
                blocks_skipped += 1
                block_execution_trace.append(
                    f"Block #{i:02d}: ID 0x{block_id*2:02X} | Pos: ({block_entry.x_pos},{block_entry.y_pos}) | Size: ({block_entry.x_length},{block_entry.y_length}) | H: {h_val} [MISSING DEF]"
                )
                continue

            block_def = BLOCK_DEFINITIONS[block_id]

            # Execute the block script
            # If extra_param is None, it defaults to 255 (Floor), not 0.
            height = block_entry.extra_param if block_entry.extra_param is not None else 255
            
            try:
                self.interpreter.execute(
                    block_def,
                    canvas,
                    start_x=block_entry.x_pos,
                    start_y=block_entry.y_pos,
                    param1=block_entry.x_length,
                    param2=block_entry.y_length,
                    height=height,
                    prio=i
                )
                
                blocks_rendered += 1
                all_draw_events.extend(self.interpreter.get_draw_events())
                
                block_execution_trace.append(
                    f"Block #{i:02d}: ID 0x{block_id*2:02X} | Pos: ({block_entry.x_pos},{block_entry.y_pos}) | Size: ({block_entry.x_length},{block_entry.y_length}) | H: {h_val} [OK]"
                )

            except Exception as e:
                print(f"  Error rendering block 0x{block_id:02X} at ({block_entry.x_pos},{block_entry.y_pos}): {e}")
                blocks_skipped += 1
                block_execution_trace.append(
                    f"Block #{i:02d}: ID 0x{block_id*2:02X} | Pos: ({block_entry.x_pos},{block_entry.y_pos}) | Size: ({block_entry.x_length},{block_entry.y_length}) | H: {h_val} [ERROR: {e}]"
                )
                continue

        # Render the buffer with depth sorting
        canvas.render()

        # Determine output path
        if output_dir is None:
            script_dir = os.path.dirname(os.path.abspath(__file__))
            output_dir = os.path.join(script_dir, "resources", "rendered_rooms")
        
        os.makedirs(output_dir, exist_ok=True)
        
        # Use JS numbering for filename
        filename_base = f"room_{js_room_id}_{self.palette}"
        png_path = os.path.join(output_dir, f"{filename_base}.png")
        log_path = os.path.join(output_dir, f"{filename_base}.log")

        # Save Image
        canvas.save(png_path)
        print(f"  Saved image: {png_path}")

        # Save Detailed Log (3-Layer Format)
        render_list = canvas.get_render_list()
        
        with open(log_path, "w") as f:
            # SECTION 1: BLOCK MANIFEST
            f.write(f"Room Index: {room_id} (JS ID: {js_room_id}) - Palette: {self.palette}\n")
            f.write("=" * 80 + "\n")
            f.write("SECTION 1: BLOCK MANIFEST\n")
            f.write(f"Summary: {blocks_rendered} rendered, {blocks_skipped} skipped\n")
            f.write(f"Unique Block Types: {', '.join([f'0x{b*2:02X}' for b in sorted(used_block_ids)])}\n")
            f.write("-" * 80 + "\n")
            for line in block_execution_trace:
                f.write("  " + line + "\n")
            f.write("-" * 80 + "\n")
            
            # SECTION 2: CHRONOLOGICAL DRAW EVENTS
            f.write("SECTION 2: CHRONOLOGICAL DRAW EVENTS (Interpreter Output)\n")
            for ev in all_draw_events:
                line = f"Event: Block #{ev['block_prio']:02d} -> DrawTile({ev['tile_id']}) @ ({ev['x']},{ev['y']}) | RawRegs: ({ev['raw_dx']}, {ev['raw_dy']})"
                f.write("  " + line + "\n")
            f.write("-" * 80 + "\n")
            
            # SECTION 3: FINAL RENDER LIST
            f.write("SECTION 3: FINAL RENDER LIST (Graphics Output)\n")
            for idx, (buf_x, buf_y, tile_id, depth, prio) in enumerate(render_list):
                screen_x = buf_x * 16 + 32
                screen_y = buf_y * 8
                line = f"Order #{idx:03d} | Depth: {depth:>3} | Prio: {prio:02d} | Tile: {tile_id:<3} | Screen: ({screen_x}, {screen_y})"
                f.write("  " + line + "\n")
        
        print(f"  Saved log:   {log_path}")

        return canvas


def main():
    """Render all rooms in both day and night palettes"""

    # Render in both day and night palettes
    for palette in ['day', 'night']:
        print(f"\n{'#'*80}")
        print(f"Rendering ALL rooms with {palette.upper()} palette")
        print(f"{'#'*80}")

        renderer = RoomRenderer(palette=palette)

        # Render ALL rooms
        for room_id in sorted(ROOM_DEFINITIONS.keys()):
            try:
                renderer.render_room(room_id)
            except Exception as e:
                print(f"CRITICAL ERROR rendering room {room_id}: {e}")
                import traceback
                traceback.print_exc()

    print(f"\n{'='*80}")
    print(f"Room rendering complete! Generated {len(ROOM_DEFINITIONS) * 2} images")
    print(f"Location: src/abadia/resources/rendered_rooms/")
    print(f"{'='*80}\n")


if __name__ == "__main__":
    main()