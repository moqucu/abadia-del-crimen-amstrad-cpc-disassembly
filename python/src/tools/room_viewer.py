#!/usr/bin/env python3
"""
Room Renderer for La Abadía del Crimen

Renders complete rooms/screens using:
- Room definitions from abbey_rooms_library
- Block definitions from abbey_blocks_library
- AbadiaInterpreter to execute block scripts

═══════════════════════════════════════════════════════════════════════════════
LOG FILE SPECIFICATION (for cross-implementation comparison)
═══════════════════════════════════════════════════════════════════════════════

NAMING: room_{JS_ID}_{PALETTE}.log (JS_ID = Python_ID + 1)

SECTION 1: BLOCK MANIFEST
  Records input parameters for each block processed.
  Format: Block #{INDEX:02d}: ID 0x{BLOCK_ID:02X} | Pos: (X,Y) | Size: (W,H) | H: {HEIGHT} [{STATUS}]

SECTION 2: CHRONOLOGICAL DRAW EVENTS
  Every DRAWTILE command in execution order (before buffering/sorting).
  Format: Event: Block #{PRIO:02d} -> DrawTile({TILE_ID}) @ (X,Y) | RawRegs: (DX, DY)

SECTION 3: FINAL RENDER LIST
  Flattened, sorted tiles in Painter's Algorithm order.
  Format: Order #{IDX:03d} | Depth: {DEPTH:>3} | Prio: {PRIO:02d} | Tile: {TILE_ID:<3} | Screen: (X, Y)
  Where: Depth = DepthX + DepthY - 16, Screen_X = BufferX*16+32, Screen_Y = BufferY*8

SECTION 4: BLOCK DSL SCRIPTS
  Human-readable disassembly of each unique block script used.

═══════════════════════════════════════════════════════════════════════════════
RENDERING FEATURES:
  - JS-compatible numbering (Room 0 -> room_1)
  - Cyan background (0, 128, 128) for 'day' palette
  - Robust error handling (skips bad blocks)
"""

import os

from engine import Tiles, BufferedCanvas, AbadiaInterpreter
from engine.dsl import disassemble_single_block
from data import BLOCK_DEFINITIONS, ROOM_DEFINITIONS

from PIL import Image

def upscale_image(image, scale):
    """
    Upscale an image by a factor using nearest neighbor interpolation.
    """
    new_size = (image.width * scale, image.height * scale)
    return image.resize(new_size, Image.NEAREST)


class RoomRenderer:
    """Renders complete game rooms"""

    def __init__(self, palette='day'):
        """
        Initialize the renderer with a color palette

        Args:
            palette: 'day' or 'night'
        """
        self.tiles = Tiles(palette=palette)
        self.interpreter = AbadiaInterpreter(self.tiles)
        self.palette = palette

    def render_room(self, room_id: int, output_dir: str = None, scales=None, explode_factor=1.0):
        """
        Render a complete room

        Args:
            room_id: Room ID (0-based)
            output_dir: Directory to save results
            scales: List of scales to generate (default: [1])
            explode_factor: Factor to spread blocks apart (default: 1.0)

        Returns:
            BufferedCanvas with the rendered room
        """
        if scales is None:
            scales = [1]

        # Get room definition
        if room_id not in ROOM_DEFINITIONS:
            raise ValueError(f"Room {room_id} not found in ROOM_DEFINITIONS")

        room = ROOM_DEFINITIONS[room_id]
        js_room_id = room_id + 1  # JS uses 1-indexed room IDs
        
        print(f"\nRendering Room {room_id} (JS: {js_room_id}) [Explode: {explode_factor}]...")
        print(f"  Offset: 0x{room.file_offset:04X}")
        print(f"  Blocks: {len(room.blocks)}")

        # Calculate Canvas Dimensions
        # Default: 16x20 tiles (256x160 content + margins)
        buf_w = 16
        buf_h = 20
        
        if explode_factor > 1.0:
            # Calculate required bounds based on scaled block positions
            max_x = 0
            max_y = 0
            for b in room.blocks:
                # Scale the position relative to room center? 
                # Or just scale from origin (easier, moves things down-right)
                # Let's scale from origin for simplicity.
                sx = int(b.x_pos * explode_factor)
                sy = int(b.y_pos * explode_factor)
                # Add margin for block content (approx 12 tiles)
                if sx + 12 > max_x: max_x = sx + 12
                if sy + 12 > max_y: max_y = sy + 12
            
            # Ensure we don't shrink below default
            buf_w = max(16, max_x)
            buf_h = max(20, max_y)
            print(f"  Dynamic Buffer Size: {buf_w}x{buf_h}")

        # Create buffered canvas
        # Use Cyan background for Day palette to match JS debug output, Black for Night
        bg_color = (0, 128, 128) if self.palette == 'day' else (0, 0, 0)
        
        # Pass dimensions
        canvas = BufferedCanvas(self.tiles, bg_color=bg_color, width=buf_w, height=buf_h)

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
            
            # Calculate exploded position
            draw_x = int(block_entry.x_pos * explode_factor)
            draw_y = int(block_entry.y_pos * explode_factor)

            try:
                self.interpreter.execute(
                    block_def,
                    canvas,
                    start_x=draw_x,
                    start_y=draw_y,
                    param1=block_entry.x_length,
                    param2=block_entry.y_length,
                    height=height,
                    prio=i
                )
                
                blocks_rendered += 1
                all_draw_events.extend(self.interpreter.get_draw_events())
                
                block_execution_trace.append(
                    f"Block #{i:02d}: ID 0x{block_id*2:02X} | Pos: ({draw_x},{draw_y}) [Orig: {block_entry.x_pos},{block_entry.y_pos}] | Size: ({block_entry.x_length},{block_entry.y_length}) | H: {h_val} [OK]"
                )

            except Exception as e:
                print(f"  Error rendering block 0x{block_id:02X} at ({draw_x},{draw_y}): {e}")
                blocks_skipped += 1
                block_execution_trace.append(
                    f"Block #{i:02d}: ID 0x{block_id*2:02X} | Pos: ({draw_x},{draw_y}) | Size: ({block_entry.x_length},{block_entry.y_length}) | H: {h_val} [ERROR: {e}]"
                )
                continue

        # Render the buffer with depth sorting
        canvas.render()

        # Determine output path
        if output_dir is None:
            script_dir = os.path.dirname(os.path.abspath(__file__))
            # Go up from src/abadia to python_scripts, then into resources
            python_scripts_dir = os.path.dirname(os.path.dirname(script_dir))
            output_dir = os.path.join(python_scripts_dir, "resources", "rendered_rooms")
        
        os.makedirs(output_dir, exist_ok=True)
        
        # Use JS numbering for filename
        explode_suffix = "_exploded" if explode_factor > 1.0 else ""
        filename_base = f"room_{js_room_id}_{self.palette}{explode_suffix}"
        log_path = os.path.join(output_dir, f"{filename_base}.log")

        # Save Image(s)
        for scale in scales:
            if scale == 1:
                img_to_save = canvas.image
                suffix = ""
            else:
                img_to_save = upscale_image(canvas.image, scale)
                suffix = f"_x{scale}"
            
            png_path = os.path.join(output_dir, f"{filename_base}{suffix}.png")
            img_to_save.save(png_path)
            print(f"  Saved image: {png_path}")

        # Save Detailed Log (3-Layer Format)
        render_list = canvas.get_render_list()
        
        with open(log_path, "w") as f:
            # SECTION 1: BLOCK MANIFEST
            f.write(f"Room Index: {room_id} (JS ID: {js_room_id}) - Palette: {self.palette} - Explode Factor: {explode_factor}\n")
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
            f.write("-" * 80 + "\n")

            # SECTION 4: BLOCK DSL SCRIPTS
            f.write("SECTION 4: BLOCK DSL SCRIPTS (Human-readable bytecode)\n")
            f.write("-" * 80 + "\n")
            for block_id in sorted(used_block_ids):
                if block_id in BLOCK_DEFINITIONS:
                    dsl = disassemble_single_block(block_id)
                    f.write(dsl + "\n\n")

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
                # 1. Standard Render
                renderer.render_room(room_id, scales=[1, 8])
                
                # 2. Exploded View (2.0x spread)
                # Only generate exploded view for 1x scale to save time/space, unless 8x is critical?
                # The user "wants to show... more clearly". 8x might be overkill for exploded if image is huge.
                # But let's stick to consistent scales=[1, 8] if feasible.
                renderer.render_room(room_id, scales=[1, 8], explode_factor=2.0)
                
            except Exception as e:
                print(f"CRITICAL ERROR rendering room {room_id}: {e}")
                import traceback
                traceback.print_exc()

    print(f"\n{'='*80}")
    print(f"Room rendering complete! Generated {len(ROOM_DEFINITIONS) * 2} images")
    print(f"Location: python/resources/rendered_rooms/")
    print(f"{'='*80}\n")


if __name__ == "__main__":
    main()