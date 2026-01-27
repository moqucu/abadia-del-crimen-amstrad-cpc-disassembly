#!/usr/bin/env python3
"""
Extract room/screen definitions from abadia8.bin

Room data format (sequential in file):
- Byte 0: Length of screen data in bytes
- Followed by block entries:
  - Byte 0: Block ID (bits 7-1) + size flag (bit 0: 0=3 bytes, 1=4 bytes)
  - Byte 1: X position (bits 4-0) + X length (bits 7-5)
  - Byte 2: Y position (bits 4-0) + Y length (bits 7-5)
  - Byte 3 (optional): Extra parameter (if bit 0 of Byte 0 is set)
- Terminated with 0xFF
"""

from dataclasses import dataclass
from typing import List, Optional
import struct


@dataclass
class BlockEntry:
    """A single block placement in a room"""
    block_id: int       # Which block from Material Table (0x00-0x5F)
    x_pos: int          # X position in tile buffer coordinates
    y_pos: int          # Y position in tile buffer coordinates
    x_length: int       # X extent
    y_length: int       # Y extent
    extra_param: Optional[int]  # Optional 4th byte parameter

    def __str__(self):
        extra = f", extra=0x{self.extra_param:02X}" if self.extra_param is not None else ""
        return f"Block 0x{self.block_id:02X} at ({self.x_pos},{self.y_pos}) size ({self.x_length},{self.y_length}){extra}"


@dataclass
class RoomDefinition:
    """A complete room/screen definition"""
    room_id: int
    file_offset: int    # Offset in abadia8.bin
    length: int         # Length byte value
    blocks: List[BlockEntry]

    def __str__(self):
        return f"Room {self.room_id} @ 0x{self.file_offset:04X}, {len(self.blocks)} blocks"


class RoomExtractor:
    """Extracts room definitions from abadia8.bin"""

    def __init__(self, abadia8_path: str):
        with open(abadia8_path, 'rb') as f:
            raw_data = f.read()
        # Skip AMSDOS header (128 bytes / 0x80)
        self.data = raw_data[0x80:]
        self.rooms: List[RoomDefinition] = []

    def parse_room(self, offset: int, room_id: int) -> tuple[RoomDefinition, int]:
        """
        Parse a single room starting at the given offset.
        Returns the room definition and the offset of the next room.
        """

        # Read length byte
        length = self.data[offset]
        start_offset = offset
        offset += 1

        blocks = []

        # Parse block entries until we hit 0xFF
        while offset < len(self.data):
            byte0 = self.data[offset]

            # Check for end marker
            if byte0 == 0xFF:
                # End of room found
                # Consume the 0xFF byte
                offset += 1
                break

            # Extract block ID (bits 7-1) and size flag (bit 0)
            block_id = (byte0 & 0xFE) >> 1
            has_extra = (byte0 & 0x01) != 0

            # Read byte 1 and 2
            if offset + 2 >= len(self.data):
                break

            byte1 = self.data[offset + 1]
            byte2 = self.data[offset + 2]

            # Extract position and length
            x_pos = byte1 & 0x1F
            x_length = (byte1 >> 5) & 0x07
            y_pos = byte2 & 0x1F
            y_length = (byte2 >> 5) & 0x07

            # Read optional 4th byte
            extra_param = None
            if has_extra:
                if offset + 3 < len(self.data):
                    extra_param = self.data[offset + 3]
                    offset += 4
                else:
                    offset += 3
            else:
                offset += 3

            blocks.append(BlockEntry(
                block_id=block_id,
                x_pos=x_pos,
                y_pos=y_pos,
                x_length=x_length,
                y_length=y_length,
                extra_param=extra_param
            ))

        return RoomDefinition(
            room_id=room_id,
            file_offset=start_offset,
            length=length,
            blocks=blocks
        ), offset

    def extract_all_rooms(self) -> List[RoomDefinition]:
        """Extract all rooms from abadia8.bin"""

        offset = 0
        room_id = 0

        # Room data goes from 0x0000 to 0x2329 (116 rooms total, ending with room 115)
        # Note: Original MEMORY_BANK_ANALYSIS.md said 0x2237 which excludes the last room
        # Data after 0x2329 is 0xFF padding
        max_offset = 0x2329

        while offset < max_offset and offset < len(self.data):
            # Parse this room
            room, next_offset = self.parse_room(offset, room_id)
            self.rooms.append(room)

            # Move to next room based on actual parsed data
            offset = next_offset
            room_id += 1

        return self.rooms

    def print_room_summary(self):
        """Print a summary of all extracted rooms"""
        print(f"\nExtracted {len(self.rooms)} rooms from abadia8.bin\n")
        print("=" * 80)

        for room in self.rooms[:10]:  # First 10 rooms
            print(f"\n{room}")
            for block in room.blocks[:5]:  # First 5 blocks per room
                print(f"  {block}")
            if len(room.blocks) > 5:
                print(f"  ... and {len(room.blocks) - 5} more blocks")

        if len(self.rooms) > 10:
            print(f"\n... and {len(self.rooms) - 10} more rooms")

        print("\n" + "=" * 80)

    def get_room_by_id(self, room_id: int) -> Optional[RoomDefinition]:
        """Get a specific room by ID"""
        if 0 <= room_id < len(self.rooms):
            return self.rooms[room_id]
        return None


def main():
    import os

    # Path to abadia8.bin
    base_dir = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
    abadia8_path = os.path.join(base_dir, "pirated_spanish_CPC_game_files", "ABADIA8.BIN")

    if not os.path.exists(abadia8_path):
        print(f"Error: {abadia8_path} not found!")
        return

    # Extract rooms
    extractor = RoomExtractor(abadia8_path)
    rooms = extractor.extract_all_rooms()

    # Print summary
    extractor.print_room_summary()

    # Export to Python module
    output_path = os.path.join(base_dir, "src", "abadia", "abbey_rooms_library.py")
    with open(output_path, 'w') as f:
        f.write('"""\n')
        f.write('Room definitions extracted from abadia8.bin\n')
        f.write(f'Total rooms: {len(rooms)}\n')
        f.write('"""\n\n')
        f.write('from typing import List, Optional\n')
        f.write('from dataclasses import dataclass\n\n\n')

        # Write the dataclass definitions
        f.write('@dataclass\n')
        f.write('class BlockEntry:\n')
        f.write('    """A single block placement in a room"""\n')
        f.write('    block_id: int\n')
        f.write('    x_pos: int\n')
        f.write('    y_pos: int\n')
        f.write('    x_length: int\n')
        f.write('    y_length: int\n')
        f.write('    extra_param: Optional[int]\n\n\n')

        f.write('@dataclass\n')
        f.write('class RoomDefinition:\n')
        f.write('    """A complete room/screen definition"""\n')
        f.write('    room_id: int\n')
        f.write('    file_offset: int\n')
        f.write('    length: int\n')
        f.write('    blocks: List[BlockEntry]\n\n\n')

        # Write the rooms
        f.write('ROOM_DEFINITIONS = {\n')
        for room in rooms:
            f.write(f'    {room.room_id}: RoomDefinition(\n')
            f.write(f'        room_id={room.room_id},\n')
            f.write(f'        file_offset=0x{room.file_offset:04X},\n')
            f.write(f'        length={room.length},\n')
            f.write(f'        blocks=[\n')
            for block in room.blocks:
                extra = f', {block.extra_param}' if block.extra_param is not None else ', None'
                f.write(f'            BlockEntry(0x{block.block_id:02X}, {block.x_pos}, {block.y_pos}, '
                       f'{block.x_length}, {block.y_length}{extra}),\n')
            f.write(f'        ]\n')
            f.write(f'    ),\n')
        f.write('}\n')

    print(f"\nExported room definitions to: {output_path}")


if __name__ == "__main__":
    main()
