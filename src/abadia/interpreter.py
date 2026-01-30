"""
Bytecode Interpreter for La Abadia del Crimen Building Block Scripts.

This is a CORE COMPONENT of the rendering system - the engine that executes
the bytecode scripts defining how isometric building blocks are drawn.

ARCHITECTURE:
-------------
    BlockDef (bytecode) --> AbadiaInterpreter --> BufferedCanvas --> PNG
                                   |
                            64KB Memory Dump
                           (abbey_code.bin)

STATE MACHINE:
--------------
The interpreter maintains:
  - Registers (regs[0-31]): T0-T11 (tile IDs), PARAM1/2, HEIGHT, DEPTHX/Y
  - Stacks: call_stack (subroutines), pos_stack (push/pop position), loop_stack
  - Coordinates: l (X), h (Y)
  - Flags: flip_x_mode (mirror mode)
  - PC: Program counter

OPCODES IMPLEMENTED:
--------------------
  0xFF        END/RET       End script or return from subroutine
  0xFE        WHILE PARAM1  Loop using PARAM1 as counter
  0xFD        WHILE PARAM2  Loop using PARAM2 as counter
  0xFC        PUSH POS      Push current X,Y position
  0xFB        POP POS       Restore X,Y position
  0xFA        ENDWHILE      End of loop body
  0xF9        DRAWTILE      Draw tile, then DEC Y
  0xF8        DRAWTILE      Draw tile, then INC X
  0xEB        DRAWTILE      Draw tile, then DEC X
  0xF7        LD            Load register with expression
  0xF6        INC Y         Increment Y coordinate
  0xF5        INC X         Increment X coordinate
  0xF4        DEC Y         Decrement Y coordinate
  0xF3        DEC X         Decrement X coordinate
  0xF2        ADD Y         Add expression to Y
  0xF1        ADD X         Add expression to X
  0xF0        INC PARAM1    Increment PARAM1 register
  0xEF        INC PARAM2    Increment PARAM2 register
  0xEE        DEC PARAM1    Decrement PARAM1 register
  0xED        DEC PARAM2    Decrement PARAM2 register
  0xEC        CALL          Call subroutine (saves state, loads tiles)
  0xEA        JMP           Jump to address (no return)
  0xE9-0xE5   FLIP X        Toggle mirror mode
  0xE4        CALL_PRESERVE Call subroutine (preserves current tileset)
  0xE0        NOP           No operation
  <0xE0       TILE HEADER   Load tileset from pointer

SAFETY FEATURES:
----------------
  - Max 50,000 opcodes per block (prevents infinite loops)
  - Max 20 nested call depth
  - PC bounds checking

RELATIONSHIP TO OTHER FILES:
----------------------------
  - Uses: graphics.py (AbbeyTiles, canvas), abbey_code.bin (memory)
  - Used by: room_renderer.py (renders complete rooms)
  - Complements: dsl_converter.py (human-readable disassembly of same bytecode)
  - Opcodes: Defined in opcodes.py (single source of truth)
"""

import os
from .graphics import AbbeyCanvas, AbbeyTiles
from .opcodes import OPCODE_NAMES, REGISTER_NAMES, get_opcode_name, get_register_name

# Alias for backward compatibility
REG_NAMES = REGISTER_NAMES

class AbadiaInterpreter:
    """
    Bytecode interpreter for La Abadía del Crimen building blocks.
    Executes scripts from the extracted BlockDef objects using the full memory map.
    """

    def __init__(self, tiles: AbbeyTiles, memory_file='src/abadia/resources/abbey_code.bin'):
        self.tiles = tiles
        self.canvas = None

        # Load Memory
        self.memory = bytearray(65536)
        if os.path.exists(memory_file):
            with open(memory_file, 'rb') as f:
                self.memory = bytearray(f.read())
        else:
            print(f"Warning: Memory file {memory_file} not found.")

        # State
        self.regs = [0] * 32  # Virtual registers (0x60 -> index 0)
        self.call_stack = []  # For 0xEC CallBlock / 0xEA ChangePC returns
        self.pos_stack = []   # For 0xFC PushPos / 0xFB PopPos
        self.loop_stack = []  # For 0xFE/0xFD loops
        self.pc = 0
        self.h = 0  # Y coordinate
        self.l = 0  # X coordinate
        self.current_depth = 0 # Calculated depth for the current block
        self.prio = 0 # Current priority (block index)

        self.flip_x_mode = False # If true, IncX/DecX are swapped
        
        self.trace_enabled = False
        self.trace_log = []
        self.draw_events = [] # capture chronological draw calls
        self.start_address = 0

        # Safety limits
        self.max_iterations = 50000  # Maximum opcodes per block
        self.max_call_depth = 20     # Maximum nested calls
        self.iteration_count = 0
        self.call_depth = 0
        
    def execute(self, block_def, canvas: AbbeyCanvas, start_x, start_y, param1=1, param2=1, height=0, prio=0, trace=False):
        """
        Execute a block script.
        start_x, start_y: Grid coordinates.
        height: Block height for depth calculation.
        prio: Priority (usually block index) for tracing/ordering.
        trace: Boolean to enable execution tracing.
        """
        self.canvas = canvas
        self.trace_enabled = trace
        self.trace_log = []
        self.draw_events = []
        
        # Start after the tile pointer (2 bytes)
        self.start_address = block_def.address
        self.pc = block_def.address + 2

        self.call_stack = []
        self.pos_stack = []
        self.loop_stack = []
        self.flip_x_mode = False

        # Reset safety counters
        self.iteration_count = 0
        self.call_depth = 0

        # Initialize coordinates
        self.h = start_y
        self.l = start_x
        
        self.prio = prio

        # Calculate depth for the block
        # Formula derived from trace analysis: Depth = X + Y + H - 46
        self.current_depth = start_x + start_y + height - 46

        # Clear regs
        self.regs = [0] * 32
        
        # Initialize Depth registers (DEPTHX=16, DEPTHY=17)
        # H=255 is a special case for floor blocks (Constant Depth -16)
        if height == 255:
            self.regs[16] = 0
            self.regs[17] = 0
        else:
            # Standard initialization for walls and objects
            # Logic derived from ASM routine at 0x1FB8:
            # A = Height >> 1
            # Reg16 (E) = Y + A + X - 15
            # Reg17 (D) = 16 + Y + A - X
            h_eff = height // 2
            self.regs[16] = (start_y + h_eff + start_x - 15) & 0xFF
            self.regs[17] = (16 + start_y + h_eff - start_x) & 0xFF
            
        # Load Tile Data
        # Tile data is accessed via registers 0x61-0x6C (indices 1-12)
        if hasattr(block_def, 'tile_data') and block_def.tile_data:
            for i, val in enumerate(block_def.tile_data):
                if i < 12:
                    self.regs[1 + i] = val  # 0x61 is index 1

        # Set Parameters
        # 0x6D = index 13 = PARAM1
        # 0x6E = index 14 = PARAM2
        self.regs[13] = param1 
        self.regs[14] = param2 
        # 0x6F = index 15 = HEIGHT
        self.regs[15] = height
        
        if self.trace_enabled:
            self.log(f"=== TRACE START: Block Type {block_def.block_id} ===")
            self.log(f"Source: Block Index {prio} (x={start_x}, y={start_y}, h={height}, p1={param1}, p2={param2})")

        # Execute Loop
        while True:
            # Safety check for infinite loops
            self.iteration_count += 1
            if self.iteration_count > self.max_iterations:
                self.log(f"Warning: Block 0x{block_def.block_id:02X} exceeded max iterations ({self.max_iterations})")
                break

            # Safety check for PC bounds
            if self.pc >= len(self.memory):
                self.log(f"PC out of bounds: {self.pc:04X} >= {len(self.memory):04X}")
                break

            opcode = self.memory[self.pc]
            current_pc = self.pc
            self.pc += 1
            
            if self.trace_enabled:
                offset = current_pc - self.start_address
                op_name = OPCODE_NAMES.get(opcode, f"UNK_{opcode:02X}")
                self.log(f"[{offset:4d}] {op_name}")
            
            if opcode == 0xEC: # CallBlock (Standard)
                # Reads address (2 bytes, Little Endian)
                low = self.read_byte()
                high = self.read_byte()
                addr = (high << 8) | low

                # Check call depth
                self.call_depth += 1
                if self.call_depth > self.max_call_depth:
                    self.log(f"Warning: Max call depth ({self.max_call_depth}) exceeded")
                    break

                # Push State: Return Addr, Regs(13-17), Flip, Pos
                # ASM saves: HL (Pos), BC (Flip), 1FDE (Depth), 1FDB (Params), 1FDD (Height)
                state = (
                    self.pc,
                    self.regs[13], self.regs[14], self.regs[15], self.regs[16], self.regs[17],
                    self.flip_x_mode,
                    self.l, self.h
                )
                self.call_stack.append(state)

                # Re-initialize depth registers with current position (matching JS behavior)
                # JS: executeScript always recalculates depth from current (x, y, height)
                height = self.regs[15]
                if height != 255:
                    h_eff = height // 2
                    self.regs[16] = (self.h + h_eff + self.l - 15) & 0xFF  # DEPTHX
                    self.regs[17] = (16 + self.h + h_eff - self.l) & 0xFF  # DEPTHY
                    self.log(f"  -> Re-init Depth: DEPTHX={self.regs[16]}, DEPTHY={self.regs[17]}")

                # All CALL targets have a 2-byte tile header at the start.
                # If first byte < 0xE0, the main loop's header handling will process it.
                # If first byte >= 0xE0, it would be misinterpreted as an opcode,
                # so we must process the header here.
                if addr + 1 < len(self.memory):
                    first_byte = self.memory[addr]
                    if first_byte >= 0xE0:
                        # Process header: read 2-byte tile pointer and load tiles
                        tile_ptr_low = self.memory[addr]
                        tile_ptr_high = self.memory[addr + 1]
                        tile_ptr = (tile_ptr_high << 8) | tile_ptr_low

                        # Load 12 bytes of tile data into T0-T11 (regs 1-12)
                        if tile_ptr + 12 <= len(self.memory):
                            for i in range(12):
                                self.regs[1 + i] = self.memory[tile_ptr + i]
                            self.log(f"  -> Load Tileset from 0x{tile_ptr:04X}")

                        # Skip the 2-byte header
                        self.pc = addr + 2
                    else:
                        # Let main loop handle the header (opcode < 0xE0 case)
                        self.pc = addr
                else:
                    self.pc = addr

            elif opcode == 0xFC: # PUSH POS
                self.pos_stack.append((self.l, self.h))
            elif opcode == 0xFB: # POP POS
                if self.pos_stack:
                    (self.l, self.h) = self.pos_stack.pop()
            
            elif opcode == 0xFE: # WHILE PARAM1
                self.op_loop(13)
            elif opcode == 0xFD: # WHILE PARAM2
                self.op_loop(14)
            elif opcode == 0xFA: # ENDWHILE
                self.op_loop_end()
            
            elif opcode == 0xF9: # DRAWTILE DEC_Y
                self.op_paint_tile(dec_y=True)
            elif opcode == 0xF8: # DRAWTILE INC_X
                self.op_paint_tile(inc_x=True)
            
            elif opcode == 0xF7: # LD
                self.op_update_reg()
            
            elif opcode == 0xF6: # INC Y
                self.h = (self.h + 1) & 0xFF
            elif opcode == 0xF5: # INC X
                self.inc_x()
            elif opcode == 0xF4: # DEC Y
                self.h = (self.h - 1) & 0xFF
            elif opcode == 0xF3: # DEC X
                self.dec_x()
            
            elif opcode == 0xF2: # ADD Y
                val = self.read_expr()
                self.h = (self.h + val) & 0xFF
            elif opcode == 0xF1: # ADD X
                val = self.read_expr()
                if self.flip_x_mode:
                    self.l = (self.l - val) & 0xFF
                else:
                    self.l = (self.l + val) & 0xFF

            elif opcode == 0xF0: # INC PARAM1
                self.regs[13] = (self.regs[13] + 1) & 0xFF
            elif opcode == 0xEF: # INC PARAM2
                self.regs[14] = (self.regs[14] + 1) & 0xFF
            elif opcode == 0xEE: # DEC PARAM1
                self.regs[13] = (self.regs[13] - 1) & 0xFF
            elif opcode == 0xED: # DEC PARAM2
                self.regs[14] = (self.regs[14] - 1) & 0xFF
            
            elif opcode == 0xE0: # NOP
                pass

            elif opcode == 0xEB: # PaintTile DecX
                self.op_paint_tile(dec_x=True)
            elif opcode == 0xEA: # ChangePC (jump without return)
                # Reads 2 bytes addr (Little Endian)
                low = self.read_byte()
                high = self.read_byte()
                addr = (high << 8) | low
                # This is a direct jump, not a call, so don't save return address
                self.pc = addr
            elif opcode in [0xE9, 0xE8, 0xE7, 0xE6, 0xE5]: # FlipX
                self.flip_x_mode = not self.flip_x_mode
            elif opcode == 0xE4: # CallBlock Preserve (skip tile header, don't load tiles)
                # Reads address
                low = self.read_byte()
                high = self.read_byte()
                addr = (high << 8) | low

                self.call_stack.append((
                    self.pc,
                    self.regs[13], self.regs[14], self.regs[15], self.regs[16], self.regs[17],
                    self.flip_x_mode,
                    self.l, self.h
                ))
                self.call_depth += 1

                # Re-initialize depth registers with current position (matching JS behavior)
                height = self.regs[15]
                if height != 255:
                    h_eff = height // 2
                    self.regs[16] = (self.h + h_eff + self.l - 15) & 0xFF  # DEPTHX
                    self.regs[17] = (16 + self.h + h_eff - self.l) & 0xFF  # DEPTHY
                    self.log(f"  -> Re-init Depth: DEPTHX={self.regs[16]}, DEPTHY={self.regs[17]}")

                # All CALL targets have a 2-byte tile header.
                # CALL_PRESERVE skips the header WITHOUT loading tiles (preserves current tileset).
                # Always skip 2 bytes regardless of header value.
                self.pc = addr + 2

            elif opcode == 0xFF: # End / Ret
                if len(self.call_stack) > 0:
                    # Restore State
                    state = self.call_stack.pop()
                    (
                        self.pc,
                        self.regs[13], self.regs[14], self.regs[15], self.regs[16], self.regs[17],
                        self.flip_x_mode,
                        self.l, self.h
                    ) = state
                    
                    self.call_depth -= 1
                    if self.trace_enabled:
                        self.log(f"  -> RET (Restore State)")
                else:
                    break
            elif opcode < 0xE0:
                # Implicit "Load Tileset" header (2 bytes = Address)
                # The code jumps to an address that starts with a pointer to tile data.
                # We must load that data into regs 1-12 and continue.
                low = opcode
                high = self.read_byte()
                tile_ptr = (high << 8) | low
                self.log(f"  -> Implicit Load Tileset from 0x{tile_ptr:04X}")
                
                # Load 12 bytes from tile_ptr
                if tile_ptr < len(self.memory) - 12:
                    for i in range(12):
                        val = self.memory[tile_ptr + i]
                        self.regs[1 + i] = val
                        # self.log(f"    T{i} = {val:02X}")
                else:
                    self.log("    Error: Tile pointer out of bounds")
            
            else:
                self.log(f"Unhandled Opcode: {opcode:02X} at PC {self.pc-1:04X}")
                break

    def log(self, msg):
        if self.trace_enabled:
            self.trace_log.append(msg)

    def get_trace_log(self):
        return self.trace_log

    def get_draw_events(self):
        return self.draw_events

    def read_byte(self):
        if self.pc < len(self.memory):
            val = self.memory[self.pc]
            self.pc += 1
            return val
        return 0

    def read_val(self):
        val = self.read_byte()
        
        # 0x82 is a literal escape prefix (from 0x2220)
        if val == 0x82:
            return self.read_byte()
            
        if val >= 0x60:
            reg_idx = val - 0x60
            
            # Handle FlipX swapping for DEPTHX/DEPTHY
            if self.flip_x_mode:
                if reg_idx == 16: reg_idx = 17 # 0x70 -> 0x71
                elif reg_idx == 17: reg_idx = 16 # 0x71 -> 0x70
                
            if reg_idx < len(self.regs):
                return self.regs[reg_idx]
            return 0
        return val

    def read_expr(self):
        # Simplified expression parser
        val = self.read_val()
        while True:
            if self.pc >= len(self.memory): break
            peek = self.memory[self.pc]
            if peek >= 0xC8: break # Opcode

            self.pc += 1
            if peek == 0x84:
                # 0x84 is UNARY NEGATE - negates the accumulated value so far
                # Example: expression "01 6D 84 70" = -(1 + PARAM1) + DEPTHX
                val = (-val) & 0xFF
            elif peek == 0x82:
                # 0x82 is a literal prefix - consume next byte as literal value
                # This is critical: 0xFF after 0x82 is the value -1, not END!
                literal = self.read_byte()
                val = (val + literal) & 0xFF
            else:
                # peek is the value/reg
                op_val = peek
                if op_val >= 0x60:
                    reg_idx = op_val - 0x60

                    # Handle FlipX swapping for DEPTHX/DEPTHY
                    if self.flip_x_mode:
                        if reg_idx == 16: reg_idx = 17
                        elif reg_idx == 17: reg_idx = 16

                    if reg_idx < len(self.regs):
                        op_val = self.regs[reg_idx]
                    else:
                        op_val = 0  # Out of bounds register, use 0
                val = (val + op_val) & 0xFF
        return val

    def inc_x(self):
        if self.flip_x_mode: self.l -= 1
        else: self.l += 1

    def dec_x(self):
        if self.flip_x_mode: self.l += 1
        else: self.l -= 1

    def op_loop(self, reg_idx):
        """
        WHILE loop implementation.

        Key insight from reference: The loop counter VALUE is pushed onto the stack,
        NOT the register index. This preserves the original register value so nested
        loops work correctly across outer loop iterations.
        """
        count = self.regs[reg_idx]
        if count > 0:
            self.loop_stack.append(self.pc)      # Save return address
            self.loop_stack.append(count)        # Push the VALUE, not reg_idx!
        else:
            # Skip to matching loop end
            depth = 1
            while self.pc < len(self.memory) and depth > 0:
                op = self.memory[self.pc]
                self.pc += 1
                if op in [0xFD, 0xFE]: depth += 1
                elif op == 0xFA: depth -= 1

    def op_loop_end(self):
        """
        ENDWHILE loop implementation.

        Decrements the counter on the stack (not the register).
        If counter > 0, loop back; otherwise exit.
        """
        if len(self.loop_stack) >= 2:
            count = self.loop_stack.pop()        # Pop the counter VALUE
            saved_pc = self.loop_stack.pop()

            count = (count - 1) & 0xFF           # Decrement the counter

            if count > 0:
                self.loop_stack.append(saved_pc)
                self.loop_stack.append(count)    # Push decremented value back
                self.pc = saved_pc

    def op_paint_tile(self, inc_x=False, dec_y=False, dec_x=False):
        """
        Handles F9, F8, EB.
        These opcodes enter a mode where they consume a sequence of tiles/modifiers.
        """
        paint_count = 0
        while True:
            # Read Tile ID (val or reg)
            tile_id = self.read_val()
            paint_count += 1
            if paint_count > 1000:  # Safety
                break
            
            # Read Next Byte (Control/Count/Opcode)
            if self.pc >= len(self.memory): break
            ctrl = self.memory[self.pc]
            
            if ctrl >= 0xC8:
                # It's an opcode.
                # Draw ONE tile, update coords, and exit function.
                # Do NOT consume ctrl.
                self.draw(tile_id)
                if inc_x: self.inc_x()
                if dec_y: self.h -= 1
                if dec_x: self.dec_x()
                return

            self.pc += 1 # Consume ctrl
            
            if ctrl == 0x80:
                # Draw and Move
                self.draw(tile_id)
                if inc_x: self.inc_x()
                if dec_y: self.h -= 1
                if dec_x: self.dec_x()
                # Continue loop (expect another tile_id)
            elif ctrl == 0x81:
                # Draw and Stay
                self.draw(tile_id)
                # Continue loop
            else:
                # Count - draw multiple times
                count = ctrl
                if ctrl >= 0x60:
                    reg_idx = ctrl - 0x60
                    if reg_idx < len(self.regs):
                        count = self.regs[reg_idx]
                    else:
                        count = 0
                
                for _ in range(count):
                    self.draw(tile_id)
                    if inc_x: self.inc_x()
                    if dec_y: self.h -= 1
                    if dec_x: self.dec_x()
                
                # Continue loop

    def op_update_reg(self):
        reg_byte = self.read_byte()
        val = 0
        if reg_byte >= 0x60:
            reg_idx = reg_byte - 0x60
            
            # Handle FlipX swapping for DEPTHX/DEPTHY
            if self.flip_x_mode:
                if reg_idx == 16: reg_idx = 17
                elif reg_idx == 17: reg_idx = 16
            
            val = self.read_expr()
            if reg_idx < len(self.regs):
                # SPECIAL CASE: H=255 floor blocks have DEPTH registers locked at 0
                if (reg_idx == 16 or reg_idx == 17) and self.regs[reg_idx] == 0:
                    self.log(f"  -> Skip Set {REG_NAMES.get(reg_byte, f'R{reg_idx}')} (Locked at 0)")
                    return

                self.regs[reg_idx] = val
                reg_name = REG_NAMES.get(reg_byte, f"R{reg_idx}")
                # Log the actual register being set
                if self.flip_x_mode and (reg_byte == 0x70 or reg_byte == 0x71):
                     # If we swapped, log the swapped name
                     actual_reg_byte = 0x71 if reg_byte == 0x70 else 0x70
                     reg_name = REG_NAMES.get(actual_reg_byte, f"R{reg_idx}")
                
                self.log(f"  -> Set {reg_name} = {val}")

    def draw(self, tile_id, tile_depth=None):
        # Capture the raw draw event for logging
        self.draw_events.append({
            'block_prio': self.prio,
            'tile_id': tile_id,
            'x': self.l,
            'y': self.h,
            'raw_dx': self.regs[16],
            'raw_dy': self.regs[17]
        })

        if self.canvas:
            # Prefer buffered drawing if available (for proper depth sorting)
            if hasattr(self.canvas, 'draw_tile_by_id'):
                depth_x = self.regs[16]
                depth_y = self.regs[17]

                # Pass depthX and depthY as tuple for in-cell depth correction
                # (See RENDERING_Z_ORDER.md for the algorithm)
                depth = (depth_x, depth_y)

                self.canvas.draw_tile_by_id(tile_id, self.l, self.h, depth, self.prio)
                self.log(f"  -> DRAWTILE ID {tile_id} @ ({self.l}, {self.h}) Depth({depth_x}, {depth_y})")
            else:
                # Fallback to direct drawing
                tile_img = self.tiles.get(tile_id)
                if tile_img is not None:
                    self.canvas.draw_tile(tile_img, self.l, self.h)