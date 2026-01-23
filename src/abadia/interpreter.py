import os
from .graphics import AbbeyCanvas, AbbeyTiles

OPCODE_NAMES = {
    0xFF: "END",
    0xFE: "WHILE PARAM1",
    0xFD: "WHILE PARAM2",
    0xFC: "PUSH POS",
    0xFB: "POP POS",
    0xFA: "ENDWHILE",
    0xF9: "DRAWTILE DEC_Y",
    0xF8: "DRAWTILE INC_X",
    0xF7: "LD",
    0xF6: "INC Y",
    0xF5: "INC X",
    0xF4: "DEC Y",
    0xF3: "DEC X",
    0xF2: "ADD Y",
    0xF1: "ADD X",
    0xF0: "INC PARAM1",
    0xEF: "INC PARAM2",
    0xEE: "DEC PARAM1",
    0xED: "DEC PARAM2",
    0xE0: "NOP",
    0xEC: "CALL",
    0xEB: "DRAWTILE DEC_X",
    0xEA: "JMP",
    0xE9: "FLIP X",
    0xE8: "FLIP X", 0xE7: "FLIP X", 0xE6: "FLIP X", 0xE5: "FLIP X", # Variants
    0xE4: "CALL FLIP",
    0xC2: "SKIP_2", 0xC6: "SKIP_2", 0xB6: "SKIP_2", 0xBA: "SKIP_2"
}

REG_NAMES = {
    0x6D: "PARAM1",
    0x6E: "PARAM2",
    0x70: "DEPTHX",
    0x71: "DEPTHY"
}
# Add T0-T11
for i in range(12):
    REG_NAMES[0x61 + i] = f"T{i}"

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
        # Based on trace analysis, they include position and height.
        # Approximation: val = pos + height + 3 (Matches Block 2 trace)
        self.regs[16] = (start_x + height + 3) & 0xFF
        self.regs[17] = (start_y + height + 3) & 0xFF

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
            
            if opcode == 0xFF: # End
                break
            elif opcode == 0xFE: # Loop Param1 (0x6D / index 13)
                self.op_loop(13)
            elif opcode == 0xFD: # Loop Param2 (0x6E / index 14)
                self.op_loop(14)
            elif opcode == 0xFC: # PushPos
                self.pos_stack.append(self.l)
                self.pos_stack.append(self.h)
            elif opcode == 0xFB: # PopPos
                if len(self.pos_stack) >= 2:
                    self.h = self.pos_stack.pop()
                    self.l = self.pos_stack.pop()
            elif opcode == 0xFA: # LoopEnd
                self.op_loop_end()
            elif opcode == 0xF9: # PaintTile DecY
                self.op_paint_tile(dec_y=True)
            elif opcode == 0xF8: # PaintTile IncX
                self.op_paint_tile(inc_x=True)
            elif opcode == 0xF7: # UpdateReg
                self.op_update_reg()
            elif opcode == 0xF6: # IncY
                self.h += 1
            elif opcode == 0xF5: # IncX
                self.inc_x()
            elif opcode == 0xF4: # DecY
                self.h -= 1
            elif opcode == 0xF3: # DecX
                self.dec_x()
            elif opcode == 0xF2: # UpdateY
                val = self.read_expr()
                self.h += val 
            elif opcode == 0xF1: # UpdateX
                val = self.read_expr()
                self.l += val
            elif opcode == 0xF0: # IncParam1 (0x6D)
                self.regs[13] = (self.regs[13] + 1) & 0xFF
            elif opcode == 0xEF: # IncParam2 (0x6E)
                self.regs[14] = (self.regs[14] + 1) & 0xFF
            elif opcode == 0xEE: # DecParam1 (0x6D)
                self.regs[13] = (self.regs[13] - 1) & 0xFF
            elif opcode == 0xED: # DecParam2 (0x6E)
                self.regs[14] = (self.regs[14] - 1) & 0xFF
            elif opcode == 0xE0: # NOP / Restart Fetch
                continue
            elif opcode == 0xEC: # CallBlock
                # Reads address (2 bytes, Little Endian)
                low = self.read_byte()
                high = self.read_byte()
                addr = (high << 8) | low

                # Check call depth
                self.call_depth += 1
                if self.call_depth > self.max_call_depth:
                    self.log(f"Warning: Max call depth ({self.max_call_depth}) exceeded")
                    break

                # Push return address
                self.call_stack.append(self.pc)
                # Jump
                self.pc = addr
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
            elif opcode == 0xE4: # CallBlock FlipX
                self.flip_x_mode = not self.flip_x_mode
                low = self.read_byte()
                high = self.read_byte()
                addr = (high << 8) | low
                self.call_stack.append(self.pc)
                self.pc = addr
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
                val2 = self.read_val()
                # 0x84 seems to be Reverse Subtract (val2 - val) based on trace analysis
                val = (val2 - val) & 0xFF
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
                self.regs[reg_idx] = val
                reg_name = REG_NAMES.get(reg_byte, f"R{reg_idx}")
                # Log the actual register being set
                if self.flip_x_mode and (reg_byte == 0x70 or reg_byte == 0x71):
                     # If we swapped, log the swapped name
                     actual_reg_byte = 0x71 if reg_byte == 0x70 else 0x70
                     reg_name = REG_NAMES.get(actual_reg_byte, f"R{reg_idx}")
                
                self.log(f"  -> Set {reg_name} = {val}")

    def draw(self, tile_id, tile_depth=None):
        if self.canvas:
            # Prefer buffered drawing if available (for proper depth sorting)
            if hasattr(self.canvas, 'draw_tile_by_id'):
                depth_x = self.regs[16]
                depth_y = self.regs[17]
                
                # Use calculated depth based on registers
                # Formula: depth = depthX + depthY - 16
                depth = depth_x + depth_y - 16
                
                # Allow override if provided (though mostly unused now)
                if tile_depth is not None:
                    depth = tile_depth

                self.canvas.draw_tile_by_id(tile_id, self.l, self.h, depth, self.prio)
                self.log(f"  -> DRAWTILE ID {tile_id} @ ({self.l}, {self.h}) Depth({depth_x}, {depth_y})")
            else:
                # Fallback to direct drawing
                tile_img = self.tiles.get(tile_id)
                if tile_img is not None:
                    self.canvas.draw_tile(tile_img, self.l, self.h)

