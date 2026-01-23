#!/usr/bin/env python3
"""
Room Renderer for La Abadía del Crimen

Renders complete rooms/screens using:
- Room definitions from abbey_rooms_library
- Block definitions from abbey_blocks_library
- AbadiaInterpreter to execute block scripts
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

    def render_room(self, room_id: int, output_path: str = None):
        """
        Render a complete room

        Args:
            room_id: Room ID (0-32)
            output_path: Optional output file path. If None, auto-generates name.

        Returns:
            BufferedCanvas with the rendered room
        """
        # Get room definition
        if room_id not in ROOM_DEFINITIONS:
            raise ValueError(f"Room {room_id} not found in ROOM_DEFINITIONS")

        room = ROOM_DEFINITIONS[room_id]
        print(f"\nRendering Room {room_id}...")
        print(f"  Offset: 0x{room.file_offset:04X}")
        print(f"  Blocks: {len(room.blocks)}")

        # Create buffered canvas for proper isometric rendering with depth sorting
        # Uses 16x20 tile buffer matching the original game
        canvas = BufferedCanvas(self.tiles, bg_color=(0, 0, 0))

        # Render each block in the room
        for i, block_entry in enumerate(room.blocks):
            block_id = block_entry.block_id

            # Get block definition
            if block_id not in BLOCK_DEFINITIONS:
                print(f"  Warning: Block 0x{block_id:02X} not in library, skipping")
                continue

            block_def = BLOCK_DEFINITIONS[block_id]

            # Execute the block script at the specified position
            # The x_length and y_length from the room data are the param1/param2
            # extra_param is usually the height
            height = block_entry.extra_param if block_entry.extra_param is not None else 0
            
            try:
                self.interpreter.execute(
                    block_def,
                    canvas,
                    start_x=block_entry.x_pos,
                    start_y=block_entry.y_pos,
                    param1=block_entry.x_length if block_entry.x_length > 0 else 1,
                    param2=block_entry.y_length if block_entry.y_length > 0 else 1,
                    height=height,
                    prio=i
                )

                if (i + 1) % 5 == 0:
                    print(f"  Rendered {i + 1}/{len(room.blocks)} blocks...")

            except Exception as e:
                print(f"  Error rendering block 0x{block_id:02X} at ({block_entry.x_pos},{block_entry.y_pos}): {e}")
                continue

        print(f"  Completed rendering {len(room.blocks)} blocks")

        # Render the buffer with depth sorting to produce final image
        canvas.render()

        # Save the result
        if output_path is None:
            # Default output to src/abadia/resources/rendered_rooms
            script_dir = os.path.dirname(os.path.abspath(__file__))
            output_dir = os.path.join(script_dir, "resources", "rendered_rooms")
            os.makedirs(output_dir, exist_ok=True)
            output_path = os.path.join(output_dir, f"room_{room_id:02d}_{self.palette}.png")

        canvas.save(output_path)
        print(f"  Saved to: {output_path}")

        return canvas


def main():
    """Render all rooms in both day and night palettes"""

    # Render in both day and night palettes
    for palette in ['day', 'night']:
        print(f"\n{'='*80}")
        print(f"Rendering ALL rooms with {palette.upper()} palette")
        print(f"{'='*80}")

        renderer = RoomRenderer(palette=palette)

        # Render ALL rooms
        for room_id in range(len(ROOM_DEFINITIONS)):
            try:
                renderer.render_room(room_id)
            except Exception as e:
                print(f"Error rendering room {room_id}: {e}")
                import traceback
                traceback.print_exc()

    print(f"\n{'='*80}")
    print(f"Room rendering complete! Generated {len(ROOM_DEFINITIONS) * 2} images")
    print(f"Location: src/abadia/resources/rendered_rooms/")
    print(f"{'='*80}\n")


if __name__ == "__main__":
    main()
