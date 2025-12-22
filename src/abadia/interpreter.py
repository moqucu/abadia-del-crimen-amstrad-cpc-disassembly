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
        self.stack = []
        self.pc = 0
        self.h = 0  # Y coordinate
        self.l = 0  # X coordinate
        
        self.flip_x_mode = False # If true, IncX/DecX are swapped
        
    def execute(self, block_def, canvas: AbbeyCanvas, start_x, start_y, param1=1, param2=1):
        """
        Execute a block script.
        start_x, start_y: Grid coordinates.
        """
        self.canvas = canvas
        
        # Start after the tile pointer (2 bytes)
        self.pc = block_def.address + 2
        
        self.stack = []
        self.flip_x_mode = False
        
        # Initialize coordinates
        self.h = start_y
        self.l = start_x
        
        # Clear regs
        self.regs = [0] * 32
        
        # Load Tile Data
        if hasattr(block_def, 'tile_data') and block_def.tile_data:
            for i, val in enumerate(block_def.tile_data):
                if i < 12:
                    self.regs[2 + i] = val # 0x62 is index 2
        
        # Set Parameters
        self.regs[13] = param2 # 0x6D
        self.regs[14] = param1 # 0x6E
        
        # Execute Loop
        while True:
            # Safety check
            if self.pc >= len(self.memory):
                print("PC out of bounds")
                break
                
            opcode = self.memory[self.pc]
            self.pc += 1
            
            if opcode == 0xFF: # End
                break
            elif opcode == 0xFE: # Loop Param1
                self.op_loop(14)
            elif opcode == 0xFD: # Loop Param2
                self.op_loop(13)
            elif opcode == 0xFC: # PushPos
                self.stack.append(self.l)
                self.stack.append(self.h)
            elif opcode == 0xFB: # PopPos
                if len(self.stack) >= 2:
                    self.h = self.stack.pop()
                    self.l = self.stack.pop()
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
            elif opcode == 0xF0: # IncParam1 (0x6E)
                self.regs[14] = (self.regs[14] + 1) & 0xFF
            elif opcode == 0xEF: # IncParam2 (0x6D)
                self.regs[13] = (self.regs[13] + 1) & 0xFF
            elif opcode == 0xEE: # DecParam2
                self.regs[13] = (self.regs[13] - 1) & 0xFF
            elif opcode == 0xED: # DecParam1
                self.regs[14] = (self.regs[14] - 1) & 0xFF
            elif opcode == 0xEC: # CallBlock
                # Reads address (2 bytes, High Low?)
                high = self.read_byte()
                low = self.read_byte()
                addr = (high << 8) | low
                
                # Push return address
                self.stack.append(self.pc)
                # Jump
                self.pc = addr
                
                # Note: CallBlock normally sets up new tile regs?
                # ASM 21B4 calls 1BBC logic.
                # But here we assume it just jumps to code.
                # If tiles change, we might need more logic.
                pass
            elif opcode == 0xEB: # PaintTile DecX
                self.op_paint_tile(dec_x=True)
            elif opcode == 0xEA: # ChangePC
                # Reads 2 bytes addr (High, Low based on extraction analysis)
                high = self.read_byte()
                low = self.read_byte()
                addr = (high << 8) | low
                self.pc = addr
            elif opcode in [0xE9, 0xE8, 0xE7, 0xE6, 0xE5]: # FlipX
                self.flip_x_mode = not self.flip_x_mode
            elif opcode == 0xE4: # CallBlock FlipX
                self.flip_x_mode = not self.flip_x_mode
                high = self.read_byte()
                low = self.read_byte()
                addr = (high << 8) | low
                self.stack.append(self.pc)
                self.pc = addr
            else:
                # Handle return from CallBlock?
                # There is no explicit RET opcode in the table.
                # FF is End.
                # If stack has return address?
                # ASM 2032: FF -> pop ix. (Return).
                # So FF acts as Return if stack has frames.
                
                # Check if this opcode is unexpected
                print(f"Unknown Opcode: {opcode:02X} at PC {self.pc-1:04X}")
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
                if op_val >= 0x60: op_val = self.regs[op_val - 0x60]
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
            self.stack.append(self.pc)
            self.stack.append(reg_idx)
        else:
            depth = 1
            while self.pc < len(self.memory) and depth > 0:
                op = self.memory[self.pc]
                self.pc += 1
                if op in [0xFD, 0xFE]: depth += 1
                elif op == 0xFA: depth -= 1

    def op_loop_end(self):
        if len(self.stack) >= 2:
            reg_idx = self.stack.pop()
            saved_pc = self.stack.pop()
            
            self.regs[reg_idx] = (self.regs[reg_idx] - 1) & 0xFF
            
            if self.regs[reg_idx] > 0:
                self.stack.append(saved_pc)
                self.stack.append(reg_idx)
                self.pc = saved_pc

    def op_paint_tile(self, inc_x=False, dec_y=False, dec_x=False):
        """
        Handles F9, F8, EB.
        These opcodes enter a mode where they consume a sequence of tiles/modifiers.
        """
        while True:
            # Read Tile ID (val or reg)
            tile_id = self.read_val()
            
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
        if self.canvas:
            self.canvas.draw_tile(tile_img, self.l, self.h)