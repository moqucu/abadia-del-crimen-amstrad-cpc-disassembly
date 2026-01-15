import os
from .graphics import AbbeyCanvas, AbbeyTiles

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

        self.flip_x_mode = False # If true, IncX/DecX are swapped

        # Safety limits
        self.max_iterations = 50000  # Maximum opcodes per block
        self.max_call_depth = 20     # Maximum nested calls
        self.iteration_count = 0
        self.call_depth = 0
        
    def execute(self, block_def, canvas: AbbeyCanvas, start_x, start_y, param1=1, param2=1):
        """
        Execute a block script.
        start_x, start_y: Grid coordinates.
        """
        self.canvas = canvas

        # Start after the tile pointer (2 bytes)
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

        # Clear regs
        self.regs = [0] * 32

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

        # Execute Loop
        while True:
...
            if opcode == 0xFF: # End
                break
            elif opcode == 0xFE: # Loop Param1
                self.op_loop(13)
            elif opcode == 0xFD: # Loop Param2
                self.op_loop(14)
...
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
                    print(f"Warning: Max call depth ({self.max_call_depth}) exceeded")
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
            elif opcode < 0xE4:
                # Opcodes below 0xE4 are not valid block interpreter opcodes
                # This means we've jumped into Z80 assembly code
                # Try to return from the call if we have a return address
                if len(self.call_stack) > 0:
                    # Return from call
                    self.pc = self.call_stack.pop()
                    self.call_depth = max(0, self.call_depth - 1)
                else:
                    # No return address - this might be end of block or data
                    # Don't print warning for common Z80 opcodes
                    if opcode not in [0x00, 0x16, 0x1C, 0x1B, 0x1F, 0x61, 0x71, 0x49, 0x80, 0xDB, 0xE0, 0xE1, 0xE2, 0xE3]:
                        print(f"Unknown Opcode: {opcode:02X} at PC {self.pc-1:04X}")
                    # Continue to next byte
                    pass
            else:
                # This shouldn't happen - opcodes E4-FE are all handled above
                print(f"Unhandled Opcode: {opcode:02X} at PC {self.pc-1:04X}")
                break
                
            # Handle implicit return on FF
            if opcode == 0xFF:
                # But we break on FF above.
                # If we were called, we should return.
                # Check stack?
                # The stack mixes Pos and PC?
                # No, we must be careful.
                # We used stack for loops and calls.
                # If stack top looks like PC (large number?), return?
                # This is tricky.
                # Let's handle Calls with a separate call stack?
                # Or assume FF is always Stop for now.
                pass

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
                val = (val - val2) & 0xFF
            else:
                # peek is the value/reg
                op_val = peek
                if op_val >= 0x60:
                    reg_idx = op_val - 0x60
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
        count = self.regs[reg_idx]
        if count > 0:
            self.loop_stack.append(self.pc)
            self.loop_stack.append(reg_idx)
        else:
            # Skip to matching loop end
            depth = 1
            while self.pc < len(self.memory) and depth > 0:
                op = self.memory[self.pc]
                self.pc += 1
                if op in [0xFD, 0xFE]: depth += 1
                elif op == 0xFA: depth -= 1

    def op_loop_end(self):
        if len(self.loop_stack) >= 2:
            reg_idx = self.loop_stack.pop()
            saved_pc = self.loop_stack.pop()

            self.regs[reg_idx] = (self.regs[reg_idx] - 1) & 0xFF

            if self.regs[reg_idx] > 0:
                self.loop_stack.append(saved_pc)
                self.loop_stack.append(reg_idx)
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
            if paint_count > 100:  # Safety
                break
            
            # Read Next Byte (Control/Count/Opcode)
            # We need to peek or read and unread?
            # ASM 2106 reads byte at IX.
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
                # Count
                count = ctrl
                if ctrl >= 0x60:
                    reg_idx = ctrl - 0x60
                    if reg_idx < len(self.regs):
                        count = self.regs[reg_idx]
                    else:
                        print(f"Error: Register {reg_idx} out of bounds")
                        count = 0
                
                for _ in range(count):
                    self.draw(tile_id)
                    if inc_x: self.inc_x()
                    if dec_y: self.h -= 1
                    if dec_x: self.dec_x()
                
                # Continue loop
                # ASM 2138: jr 2103 (Loop)

    def op_update_reg(self):
        reg_byte = self.read_byte()
        if reg_byte >= 0x60:
            reg_idx = reg_byte - 0x60
            val = self.read_expr()
            if reg_idx < len(self.regs):
                self.regs[reg_idx] = val

    def draw(self, tile_id):
        # tile_id is 0-255.
        # But if it comes from regs, it's already resolved.
        # Wait, self.read_val() returns the value in the register (which IS the tile ID).
        # So we just use it.
        tile_img = self.tiles.get(tile_id)
        if self.canvas and tile_img is not None:
            self.canvas.draw_tile(tile_img, self.l, self.h)