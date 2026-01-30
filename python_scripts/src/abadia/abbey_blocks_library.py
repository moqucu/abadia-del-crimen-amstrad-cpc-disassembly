"""
Abbey Blocks Library

Auto-generated from binary memory dump.
Contains building block scripts and shared subroutines used by the game engine.
Each entry includes raw bytecode and human-readable DSL representation.

BLOCK_DEFINITIONS: Building blocks (0x01-0x5F) referenced by room definitions.
SUBROUTINE_DEFINITIONS: Shared code (SCRIPT96+) that blocks JMP/CALL into.
"""


class BlockDef:
    """A building block script with tile data."""
    def __init__(self, block_id, description, address, tile_ptr, tile_data, bytecode, dsl=""):
        self.block_id = block_id
        self.description = description
        self.address = address
        self.tile_ptr = tile_ptr
        self.tile_data = tile_data
        self.bytecode = bytecode
        self.dsl = dsl


class SubroutineDef:
    """A shared subroutine that blocks can JMP/CALL into."""
    def __init__(self, script_id, description, address, bytecode, dsl=""):
        self.script_id = script_id
        self.description = description
        self.address = address
        self.bytecode = bytecode
        self.dsl = dsl


BLOCK_DEFINITIONS = {
    0x01: BlockDef(
        block_id=0x01,
        description="thin black brick parallel to y",
        address=0x1973,
        tile_ptr=0x16A2,
        tile_data=[0x28, 0x09, 0x29, 0x00, 0x2B, 0x0A, 0x2D, 0x00, 0x23, 0x22, 0x61, 0x29],
        bytecode=[0xF7, 0x71, 0x01, 0x6E, 0x6E, 0x84, 0x71, 0xEF, 0xFD, 0xFC, 0xF9, 0x61, 0xFE, 0xF9, 0x62, 0xFA, 0xF9, 0x63, 0xFB, 0xF5, 0xF4, 0xFA, 0xFF],
        dsl="""
          [SCRIPT1]
          TILES 40,9,41,0,43,10,45,0,35,34,97,41
          LD DEPTHY, 1 + PARAM2 + PARAM2 - DEPTHY
          INC PARAM2
          WHILE PARAM2
            PUSH X
            PUSH Y
            DRAWTILE T0
            DEC Y
            WHILE PARAM1
              DRAWTILE T1
              DEC Y
            ENDWHILE
            DRAWTILE T2
            DEC Y
            POP Y
            POP X
            INC X
            DEC Y
          ENDWHILE
          END
          """
    ),
    0x02: BlockDef(
        block_id=0x02,
        description="thin red brick parallel to x",
        address=0x196E,
        tile_ptr=0x16A6,
        tile_data=[0x2B, 0x0A, 0x2D, 0x00, 0x23, 0x22, 0x61, 0x29, 0x26, 0x25, 0x27, 0x2D],
        bytecode=[0xEA, 0x8C, 0x19],
        dsl="""
          [SCRIPT2]
          TILES 43,10,45,0,35,34,97,41,38,37,39,45
          JMP SCRIPT106, 0
          """
    ),
    0x03: BlockDef(
        block_id=0x03,
        description="thick black brick parallel to y",
        address=0x193C,
        tile_ptr=0x16B2,
        tile_data=[0x62, 0x02, 0x63, 0x03, 0x6A, 0x06, 0x74, 0x07, 0x23, 0x22, 0x21, 0x29],
        bytecode=[0xEA, 0xAD, 0x19],
        dsl="""
          [SCRIPT3]
          TILES 98,2,99,3,106,6,116,7,35,34,33,41
          JMP SCRIPT107, 0
          """
    ),
    0x04: BlockDef(
        block_id=0x04,
        description="thick red brick parallel to x",
        address=0x1941,
        tile_ptr=0x16B6,
        tile_data=[0x6A, 0x06, 0x74, 0x07, 0x23, 0x22, 0x21, 0x29, 0x26, 0x25, 0x24, 0x2D],
        bytecode=[0xEA, 0xC6, 0x19],
        dsl="""
          [SCRIPT4]
          TILES 106,6,116,7,35,34,33,41,38,37,36,45
          JMP SCRIPT108, 0
          """
    ),
    0x05: BlockDef(
        block_id=0x05,
        description="small windows block, slightly rounded and black parallel to the y axis",
        address=0x1946,
        tile_ptr=0x16BA,
        tile_data=[0x23, 0x22, 0x21, 0x29, 0x26, 0x25, 0x24, 0x2D, 0x37, 0x36, 0x35, 0x00],
        bytecode=[0xEA, 0x90, 0x19],
        dsl="""
          [SCRIPT5]
          TILES 35,34,33,41,38,37,36,45,55,54,53
          JMP SCRIPT109, 0
          """
    ),
    0x06: BlockDef(
        block_id=0x06,
        description="small windows block, slightly rounded and red parallel to the x axis",
        address=0x194B,
        tile_ptr=0x16BE,
        tile_data=[0x26, 0x25, 0x24, 0x2D, 0x37, 0x36, 0x35, 0x00, 0x34, 0x33, 0x32, 0x00],
        bytecode=[0xEA, 0xA9, 0x19],
        dsl="""
          [SCRIPT6]
          TILES 38,37,36,45,55,54,53,0,52,51,50
          JMP SCRIPT110, 0
          """
    ),
    0x07: BlockDef(
        block_id=0x07,
        description="red railing parallel to the y axis",
        address=0x1950,
        tile_ptr=0x16C2,
        tile_data=[0x37, 0x36, 0x35, 0x00, 0x34, 0x33, 0x32, 0x00, 0x99, 0x9A, 0x97, 0x98],
        bytecode=[0xEA, 0xCA, 0x19],
        dsl="""
          [SCRIPT7]
          TILES 55,54,53,0,52,51,50,0,153,154,151,152
          JMP SCRIPT111, 0
          """
    ),
    0x08: BlockDef(
        block_id=0x08,
        description="red railing parallel to the x axis",
        address=0x1955,
        tile_ptr=0x16C6,
        tile_data=[0x34, 0x33, 0x32, 0x00, 0x99, 0x9A, 0x97, 0x98, 0x23, 0x21, 0x1B, 0x3A],
        bytecode=[0xEA, 0xD4, 0x19],
        dsl="""
          [SCRIPT8]
          TILES 52,51,50,0,153,154,151,152,35,33,27,58
          JMP SCRIPT112, 0
          """
    ),
    0x09: BlockDef(
        block_id=0x09,
        description="white column parallel to the y axis",
        address=0x195A,
        tile_ptr=0x16CA,
        tile_data=[0x99, 0x9A, 0x97, 0x98, 0x23, 0x21, 0x1B, 0x3A, 0x26, 0x24, 0x69, 0x39],
        bytecode=[0xEA, 0x90, 0x19],
        dsl="""
          [SCRIPT9]
          TILES 153,154,151,152,35,33,27,58,38,36,105,57
          JMP SCRIPT109, 0
          """
    ),
    0x0A: BlockDef(
        block_id=0x0A,
        description="white column parallel to the x axis",
        address=0x1969,
        tile_ptr=0x16CA,
        tile_data=[0x99, 0x9A, 0x97, 0x98, 0x23, 0x21, 0x1B, 0x3A, 0x26, 0x24, 0x69, 0x39],
        bytecode=[0xEA, 0xA9, 0x19],
        dsl="""
          [SCRIPT10]
          TILES 153,154,151,152,35,33,27,58,38,36,105,57
          JMP SCRIPT110, 0
          """
    ),
    0x0B: BlockDef(
        block_id=0x0B,
        description="stairs with black brick on the edge parallel to the y axis",
        address=0x1AEF,
        tile_ptr=0x16EA,
        tile_data=[0x12, 0xB2, 0xB2, 0x45, 0x13, 0xB4, 0xB5, 0xB3, 0xB1, 0x10, 0x81, 0x81],
        bytecode=[0xF7, 0x70, 0x02, 0x6D, 0x6D, 0x84, 0x70, 0xF7, 0x71, 0x01, 0x6E, 0x6E, 0x84, 0x71, 0xEF, 0xFD, 0xFC, 0xFC, 0xF9, 0x61, 0x80, 0x65, 0xFB, 0xF3, 0xFE, 0xFC, 0xF9, 0x62, 0x80, 0x66, 0x80, 0x67, 0xFB, 0xF4, 0xF3, 0xFA, 0xF9, 0x63, 0x80, 0x68, 0x80, 0x69, 0xFB, 0xF4, 0xF4, 0xF5, 0xFA, 0xF3, 0xF0, 0xFE, 0xF9, 0x64, 0xF3, 0xFA, 0xFF],
        dsl="""
          [SCRIPT11]
          TILES 18,178,178,69,19,180,181,179,177,16,129,129
          LD DEPTHX, 2 + PARAM1 + PARAM1 - DEPTHX
          LD DEPTHY, 1 + PARAM2 + PARAM2 - DEPTHY
          INC PARAM2
          WHILE PARAM2
            PUSH X
            PUSH Y
            PUSH X
            PUSH Y
            DRAWTILE T0
            DEC Y
            DRAWTILE T4
            DEC Y
            POP Y
            POP X
            DEC X
            WHILE PARAM1
              PUSH X
              PUSH Y
              DRAWTILE T1
              DEC Y
              DRAWTILE T5
              DEC Y
              DRAWTILE T6
              DEC Y
              POP Y
              POP X
              DEC Y
              DEC X
            ENDWHILE
            DRAWTILE T2
            DEC Y
            DRAWTILE T7
            DEC Y
            DRAWTILE T8
            DEC Y
            POP Y
            POP X
            DEC Y
            DEC Y
            INC X
          ENDWHILE
          DEC X
          INC PARAM1
          WHILE PARAM1
            DRAWTILE T3
            DEC Y
            DEC X
          ENDWHILE
          END
          """
    ),
    0x0C: BlockDef(
        block_id=0x0C,
        description="stairs with red brick on the edge parallel to the x axis",
        address=0x1B28,
        tile_ptr=0x16F3,
        tile_data=[0x10, 0x81, 0x81, 0x44, 0x11, 0x83, 0x84, 0x82, 0x80, 0x1C, 0x1B, 0xB8],
        bytecode=[0xE9, 0xEA, 0xF1, 0x1A],
        dsl="""
          [SCRIPT12]
          TILES 16,129,129,68,17,131,132,130,128,28,27,184
          FLIP X
          JMP SCRIPT11, 0
          """
    ),
    0x0D: BlockDef(
        block_id=0x0D,
        description="floor of thick blue tiles",
        address=0x1BA0,
        tile_ptr=0x1B43,
        tile_data=[0x04, 0x04, 0x04, 0x01, 0x4E, 0x4D, 0x05, 0x4F, 0x59, 0x28, 0x29, 0x2B],
        bytecode=[0xEA, 0xCF, 0x1B],
        dsl="""
          [SCRIPT13]
          TILES 4,4,4,1,78,77,5,79,89,40,41,43
          JMP SCRIPT113, 0
          """
    ),
    0x0E: BlockDef(
        block_id=0x0E,
        description="floor of red and blue tiles forming a checkerboard effect",
        address=0x1BA5,
        tile_ptr=0x1B46,
        tile_data=[0x01, 0x4E, 0x4D, 0x05, 0x4F, 0x59, 0x28, 0x29, 0x2B, 0x2D, 0x0A, 0x09],
        bytecode=[0xEA, 0xCF, 0x1B],
        dsl="""
          [SCRIPT14]
          TILES 1,78,77,5,79,89,40,41,43,45,10,9
          JMP SCRIPT113, 0
          """
    ),
    0x0F: BlockDef(
        block_id=0x0F,
        description="floor of blue tiles",
        address=0x1BAA,
        tile_ptr=0x1B49,
        tile_data=[0x05, 0x4F, 0x59, 0x28, 0x29, 0x2B, 0x2D, 0x0A, 0x09, 0x05, 0x59, 0x4F],
        bytecode=[0xEA, 0xCF, 0x1B],
        dsl="""
          [SCRIPT15]
          TILES 5,79,89,40,41,43,45,10,9,5,89,79
          JMP SCRIPT113, 0
          """
    ),
    0x10: BlockDef(
        block_id=0x10,
        description="floor of yellow tiles",
        address=0x1BAF,
        tile_ptr=0x1B5B,
        tile_data=[0x87, 0x88, 0xCF, 0x28, 0x29, 0x2B, 0x2D, 0x0A, 0x09, 0x87, 0xCF, 0x88],
        bytecode=[0xEA, 0xCF, 0x1B],
        dsl="""
          [SCRIPT16]
          TILES 135,136,207,40,41,43,45,10,9,135,207,136
          JMP SCRIPT113, 0
          """
    ),
    0x11: BlockDef(
        block_id=0x11,
        description="block of arches passing through pairs of columns parallel to the y axis",
        address=0x1CB8,
        tile_ptr=0x1C48,
        tile_data=[0xC4, 0xC3, 0xC2, 0xC0, 0xC1, 0xBF, 0x9B, 0xBC, 0xBD, 0xBE, 0xF6, 0xF5],
        bytecode=[0xF7, 0x70, 0x01, 0x70, 0xF7, 0x71, 0x01, 0x71, 0xF0, 0xFE, 0xF7, 0x71, 0x08, 0x84, 0x71, 0xF9, 0x67, 0x80, 0x82, 0xFB, 0x80, 0x82, 0xC8, 0x80, 0x82, 0xC5, 0x80, 0x82, 0xC6, 0x80, 0x82, 0xC7, 0xF5, 0xF6, 0xF6, 0xF6, 0xF9, 0x61, 0x80, 0x62, 0x80, 0x63, 0x80, 0x64, 0xF5, 0xF6, 0xF6, 0xF9, 0x65, 0x80, 0x66, 0xF5, 0xF2, 0x04, 0xF9, 0x67, 0x80, 0x68, 0x80, 0x69, 0x80, 0x6A, 0xF5, 0xF2, 0x03, 0xFA, 0xFF],
        dsl="""
          [SCRIPT17]
          TILES 196,195,194,192,193,191,155,188,189,190,246,245
          LD DEPTHX, 1 + DEPTHX
          LD DEPTHY, 1 + DEPTHY
          INC PARAM1
          WHILE PARAM1
            LD DEPTHY, -( DEPTHY ) + 8
            DRAWTILE T6
            DEC Y
            DRAWTILE 251
            DEC Y
            DRAWTILE 200
            DEC Y
            DRAWTILE 197
            DEC Y
            DRAWTILE 198
            DEC Y
            DRAWTILE 199
            DEC Y
            INC X
            INC Y
            INC Y
            INC Y
            DRAWTILE T0
            DEC Y
            DRAWTILE T1
            DEC Y
            DRAWTILE T2
            DEC Y
            DRAWTILE T3
            DEC Y
            INC X
            INC Y
            INC Y
            DRAWTILE T4
            DEC Y
            DRAWTILE T5
            DEC Y
            INC X
            ADD Y, 4
            DRAWTILE T6
            DEC Y
            DRAWTILE T7
            DEC Y
            DRAWTILE T8
            DEC Y
            DRAWTILE T9
            DEC Y
            INC X
            ADD Y, 3
          ENDWHILE
          END
          """
    ),
    0x12: BlockDef(
        block_id=0x12,
        description="block of arches passing through pairs of columns parallel to the x axis",
        address=0x1CFD,
        tile_ptr=0x1C52,
        tile_data=[0xF6, 0xF5, 0xF4, 0xF2, 0xF3, 0xF1, 0x9B, 0xEE, 0xEF, 0xF0, 0xE3, 0x9C],
        bytecode=[0xE9, 0xF7, 0x70, 0x01, 0x70, 0xF7, 0x71, 0x01, 0x71, 0xF0, 0xFE, 0xF7, 0x71, 0x08, 0x84, 0x71, 0xF9, 0x67, 0x80, 0x82, 0xFB, 0x80, 0x82, 0xF7, 0x80, 0x82, 0xF8, 0x80, 0x82, 0xF9, 0x80, 0x82, 0xFA, 0xEA, 0xDA, 0x1C],
        dsl="""
          [SCRIPT18]
          TILES 246,245,244,242,243,241,155,238,239,240,227,156
          FLIP X
          LD DEPTHX, 1 + DEPTHX
          LD DEPTHY, 1 + DEPTHY
          INC PARAM1
          WHILE PARAM1
            LD DEPTHY, -( DEPTHY ) + 8
            DRAWTILE T6
            DEC Y
            DRAWTILE 251
            DEC Y
            DRAWTILE 247
            DEC Y
            DRAWTILE 248
            DEC Y
            DRAWTILE 249
            DEC Y
            DRAWTILE 250
            DEC Y
            JMP SCRIPT17, 32
          """
    ),
    0x13: BlockDef(
        block_id=0x13,
        description="block of arches with columns parallel to the y axis",
        address=0x1D23,
        tile_ptr=0x1C48,
        tile_data=[0xC4, 0xC3, 0xC2, 0xC0, 0xC1, 0xBF, 0x9B, 0xBC, 0xBD, 0xBE, 0xF6, 0xF5],
        bytecode=[0xFC, 0xF2, 0x05, 0x84, 0xF7, 0x6F, 0x0A, 0x6F, 0xEC, 0xB8, 0x1C, 0xF7, 0x6F, 0x0A, 0x84, 0x6F, 0xFB, 0xF0, 0xFE, 0xEC, 0x59, 0x1D, 0xF4, 0xF4, 0xF4, 0xF5, 0xF5, 0xF5, 0xEC, 0x59, 0x1D, 0xF4, 0xF5, 0xFA, 0xFF],
        dsl="""
          [SCRIPT19]
          TILES 196,195,194,192,193,191,155,188,189,190,246,245
          PUSH X
          PUSH Y
          ADD Y, -( 5 )
          LD HEIGHT, 10 + HEIGHT
          CALL SCRIPT17
          LD HEIGHT, -( HEIGHT ) + 10
          POP Y
          POP X
          INC PARAM1
          WHILE PARAM1
            CALL SCRIPT96
            DEC Y
            DEC Y
            DEC Y
            INC X
            INC X
            INC X
            CALL SCRIPT96
            DEC Y
            INC X
          ENDWHILE
          END
          """
    ),
    0x14: BlockDef(
        block_id=0x14,
        description="block of arches with columns parallel to the x axis",
        address=0x1D48,
        tile_ptr=0x1C52,
        tile_data=[0xF6, 0xF5, 0xF4, 0xF2, 0xF3, 0xF1, 0x9B, 0xEE, 0xEF, 0xF0, 0xE3, 0x9C],
        bytecode=[0xFC, 0xF2, 0x05, 0x84, 0xF7, 0x6F, 0x0A, 0x6F, 0xEC, 0xFD, 0x1C, 0xE9, 0xEA, 0x30, 0x1D],
        dsl="""
          [SCRIPT20]
          TILES 246,245,244,242,243,241,155,238,239,240,227,156
          PUSH X
          PUSH Y
          ADD Y, -( 5 )
          LD HEIGHT, 10 + HEIGHT
          CALL SCRIPT18
          FLIP X
          JMP SCRIPT19, 11
          """
    ),
    0x15: BlockDef(
        block_id=0x15,
        description="double yellow rivet on the brick parallel to the y axis",
        address=0x1F5F,
        tile_ptr=0x1C78,
        tile_data=[0xAA, 0xAB, 0xAB, 0xAA, 0xA9, 0xA8, 0xA8, 0xA9, 0x3F, 0x3E, 0x3D, 0x3C],
        bytecode=[0xEA, 0xAD, 0x19],
        dsl="""
          [SCRIPT21]
          TILES 170,171,171,170,169,168,168,169,63,62,61,60
          JMP SCRIPT107, 0
          """
    ),
    0x16: BlockDef(
        block_id=0x16,
        description="double yellow rivet on the brick parallel to the x axis",
        address=0x1F64,
        tile_ptr=0x1C7C,
        tile_data=[0xA9, 0xA8, 0xA8, 0xA9, 0x3F, 0x3E, 0x3D, 0x3C, 0x3A, 0x39, 0x30, 0x1C],
        bytecode=[0xEA, 0xC6, 0x19],
        dsl="""
          [SCRIPT22]
          TILES 169,168,168,169,63,62,61,60,58,57,48,28
          JMP SCRIPT108, 0
          """
    ),
    0x17: BlockDef(
        block_id=0x17,
        description="solid block of thin brick parallel to the x axis",
        address=0x17FE,
        tile_ptr=0x1B31,
        tile_data=[0x08, 0x76, 0x75, 0x28, 0x29, 0x2B, 0x2D, 0x0A, 0x09, 0x08, 0x75, 0x76],
        bytecode=[0xEA, 0x05, 0x18],
        dsl="""
          [SCRIPT23]
          TILES 8,118,117,40,41,43,45,10,9,8,117,118
          JMP SCRIPT57, 0
          """
    ),
    0x18: BlockDef(
        block_id=0x18,
        description="solid block of thin brick parallel to the y axis",
        address=0x18A6,
        tile_ptr=0x1B3A,
        tile_data=[0x08, 0x75, 0x76, 0x2B, 0x2D, 0x28, 0x29, 0x09, 0x0A, 0x04, 0x04, 0x04],
        bytecode=[0xEA, 0xAD, 0x18],
        dsl="""
          [SCRIPT24]
          TILES 8,117,118,43,45,40,41,9,10,4,4,4
          JMP SCRIPT56, 0
          """
    ),
    0x19: BlockDef(
        block_id=0x19,
        description="white table parallel to the x axis",
        address=0x17F9,
        tile_ptr=0x1B88,
        tile_data=[0xDB, 0xD4, 0xDA, 0xD8, 0xDC, 0xD7, 0xDD, 0xE2, 0xD9, 0x2E, 0x1B, 0xEA],
        bytecode=[0xEA, 0x05, 0x18],
        dsl="""
          [SCRIPT25]
          TILES 219,212,218,216,220,215,221,226,217,46,27,234
          JMP SCRIPT57, 0
          """
    ),
    0x1A: BlockDef(
        block_id=0x1A,
        description="white table parallel to the y axis",
        address=0x18A1,
        tile_ptr=0x1B7F,
        tile_data=[0xDB, 0xDA, 0xD4, 0xD7, 0xDD, 0xD8, 0xDC, 0xD9, 0xE2, 0xDB, 0xD4, 0xDA],
        bytecode=[0xEA, 0xAD, 0x18],
        dsl="""
          [SCRIPT26]
          TILES 219,218,212,215,221,216,220,217,226,219,212,218
          JMP SCRIPT56, 0
          """
    ),
    0x1B: BlockDef(
        block_id=0x1B,
        description="small discharge pillar placed next to a wall on the x axis",
        address=0x1932,
        tile_ptr=0x16D6,
        tile_data=[0x7F, 0x7E, 0x7D, 0x00, 0x58, 0x57, 0x56, 0x00, 0x41, 0x17, 0x16, 0x1A],
        bytecode=[0xEA, 0x8C, 0x19],
        dsl="""
          [SCRIPT27]
          TILES 127,126,125,0,88,87,86,0,65,23,22,26
          JMP SCRIPT106, 0
          """
    ),
    0x1C: BlockDef(
        block_id=0x1C,
        description="red and black terrain area",
        address=0x1B9B,
        tile_ptr=0x1B31,
        tile_data=[0x08, 0x76, 0x75, 0x28, 0x29, 0x2B, 0x2D, 0x0A, 0x09, 0x08, 0x75, 0x76],
        bytecode=[0xEA, 0xCF, 0x1B],
        dsl="""
          [SCRIPT28]
          TILES 8,118,117,40,41,43,45,10,9,8,117,118
          JMP SCRIPT113, 0
          """
    ),
    0x1D: BlockDef(
        block_id=0x1D,
        description="bookshelves parallel to the y axis",
        address=0x1E0F,
        tile_ptr=0x1C80,
        tile_data=[0x3F, 0x3E, 0x3D, 0x3C, 0x3A, 0x39, 0x30, 0x1C, 0xEC, 0xA6, 0x1C, 0xF7],
        bytecode=[0xE9, 0xF0, 0xEF, 0xFC, 0xF9, 0x61, 0xFE, 0xF9, 0x62, 0x80, 0x63, 0x80, 0x61, 0xFA, 0xFB, 0xF6, 0xF5, 0xFD, 0xFC, 0xF9, 0x64, 0xFE, 0xF9, 0x65, 0x80, 0x66, 0x80, 0x64, 0xFA, 0xFB, 0xF6, 0xF5, 0xFA, 0xFF],
        dsl="""
          [SCRIPT29]
          TILES 63,62,61,60,58,57,48,28,236,166,28,247
          FLIP X
          INC PARAM1
          INC PARAM2
          PUSH X
          PUSH Y
          DRAWTILE T0
          DEC Y
          WHILE PARAM1
            DRAWTILE T1
            DEC Y
            DRAWTILE T2
            DEC Y
            DRAWTILE T0
            DEC Y
          ENDWHILE
          POP Y
          POP X
          INC Y
          INC X
          WHILE PARAM2
            PUSH X
            PUSH Y
            DRAWTILE T3
            DEC Y
            WHILE PARAM1
              DRAWTILE T4
              DEC Y
              DRAWTILE T5
              DEC Y
              DRAWTILE T3
              DEC Y
            ENDWHILE
            POP Y
            POP X
            INC Y
            INC X
          ENDWHILE
          END
          """
    ),
    0x1E: BlockDef(
        block_id=0x1E,
        description="bed",
        address=0x1E33,
        tile_ptr=0x1BF9,
        tile_data=[0xD8, 0x95, 0x94, 0xEA, 0xD0, 0xDC, 0xDB, 0x96, 0xD7, 0xDD, 0xDA, 0xA7],
        bytecode=[0xF7, 0x71, 0x04, 0x84, 0x71, 0xF7, 0x70, 0x01, 0x84, 0x70, 0xFC, 0xF9, 0x69, 0x80, 0x6A, 0x80, 0x6B, 0xFB, 0xF5, 0xFC, 0xF9, 0x61, 0x80, 0x66, 0x80, 0x67, 0x80, 0x68, 0xFB, 0xF5, 0xF4, 0xF9, 0x61, 0x80, 0x62, 0x80, 0x63, 0x80, 0x64, 0x80, 0x65, 0xFF],
        dsl="""
          [SCRIPT30]
          TILES 216,149,148,234,208,220,219,150,215,221,218,167
          LD DEPTHY, -( DEPTHY ) + 4
          LD DEPTHX, -( DEPTHX ) + 1
          PUSH X
          PUSH Y
          DRAWTILE T8
          DEC Y
          DRAWTILE T9
          DEC Y
          DRAWTILE T10
          DEC Y
          POP Y
          POP X
          INC X
          PUSH X
          PUSH Y
          DRAWTILE T0
          DEC Y
          DRAWTILE T5
          DEC Y
          DRAWTILE T6
          DEC Y
          DRAWTILE T7
          DEC Y
          POP Y
          POP X
          INC X
          DEC Y
          DRAWTILE T0
          DEC Y
          DRAWTILE T1
          DEC Y
          DRAWTILE T2
          DEC Y
          DRAWTILE T3
          DEC Y
          DRAWTILE T4
          DEC Y
          END
          """
    ),
    0x1F: BlockDef(
        block_id=0x1F,
        description="large blue and yellow windows parallel to the y axis",
        address=0x1E5F,
        tile_ptr=0x1C04,
        tile_data=[0xA7, 0xA5, 0xA3, 0xA1, 0x9F, 0x9D, 0xA6, 0xA4, 0xA2, 0xA0, 0x9E, 0x00],
        bytecode=[0xF7, 0x70, 0x01, 0x84, 0x70, 0xF7, 0x71, 0x03, 0x6D, 0x6D, 0x6D, 0x6D, 0x84, 0x71, 0xF0, 0xEF, 0xFD, 0xFC, 0xFE, 0xFC, 0xF9, 0x61, 0x80, 0x62, 0x80, 0x62, 0x80, 0x63, 0x80, 0x64, 0x80, 0x65, 0x80, 0x66, 0xFB, 0xF5, 0xF4, 0xFC, 0xF9, 0x67, 0x80, 0x68, 0x80, 0x68, 0x80, 0x69, 0x80, 0x6A, 0x80, 0x6B, 0xFB, 0xF5, 0xF4, 0xFA, 0xFB, 0xF2, 0x07, 0x84, 0xFA, 0xFF],
        dsl="""
          [SCRIPT31]
          TILES 167,165,163,161,159,157,166,164,162,160,158
          LD DEPTHX, -( DEPTHX ) + 1
          LD DEPTHY, 3 + PARAM1 + PARAM1 + PARAM1 + PARAM1 - DEPTHY
          INC PARAM1
          INC PARAM2
          WHILE PARAM2
            PUSH X
            PUSH Y
            WHILE PARAM1
              PUSH X
              PUSH Y
              DRAWTILE T0
              DEC Y
              DRAWTILE T1
              DEC Y
              DRAWTILE T1
              DEC Y
              DRAWTILE T2
              DEC Y
              DRAWTILE T3
              DEC Y
              DRAWTILE T4
              DEC Y
              DRAWTILE T5
              DEC Y
              POP Y
              POP X
              INC X
              DEC Y
              PUSH X
              PUSH Y
              DRAWTILE T6
              DEC Y
              DRAWTILE T7
              DEC Y
              DRAWTILE T7
              DEC Y
              DRAWTILE T8
              DEC Y
              DRAWTILE T9
              DEC Y
              DRAWTILE T10
              DEC Y
              POP Y
              POP X
              INC X
              DEC Y
            ENDWHILE
            POP Y
            POP X
            ADD Y, -( 7 )
          ENDWHILE
          END
          """
    ),
    0x20: BlockDef(
        block_id=0x20,
        description="large blue and yellow windows parallel to the x axis",
        address=0x1E9D,
        tile_ptr=0x1C10,
        tile_data=[0x93, 0x91, 0x8F, 0x8D, 0x8B, 0x89, 0x92, 0x90, 0x8E, 0x8C, 0x8A, 0x00],
        bytecode=[0xE9, 0xEA, 0x61, 0x1E],
        dsl="""
          [SCRIPT32]
          TILES 147,145,143,141,139,137,146,144,142,140,138
          FLIP X
          JMP SCRIPT31, 0
          """
    ),
    0x21: BlockDef(
        block_id=0x21,
        description="candelabras with 2 candles parallel to the x axis",
        address=0x1ECC,
        tile_ptr=0x1C1C,
        tile_data=[0x5F, 0xCB, 0xCD, 0xCA, 0x46, 0x5F, 0xCB, 0xCD, 0xCA, 0x46, 0x5F, 0xCE],
        bytecode=[0xEA, 0xC8, 0x1E],
        dsl="""
          [SCRIPT33]
          TILES 95,203,205,202,70,95,203,205,202,70,95,206
          JMP SCRIPT59, 0
          """
    ),
    0x22: BlockDef(
        block_id=0x22,
        description="does nothing",
        address=0x1ED6,
        tile_ptr=0x1C2B,
        tile_data=[0x6D, 0xCE, 0xCD, 0xCC, 0x60, 0xD6, 0xD5, 0xAB, 0xD2, 0xD1, 0xA8, 0x28],
        bytecode=[0xFF],
        dsl="""
          [SCRIPT34]
          TILES 109,206,205,204,96,214,213,171,210,209,168,40
          END
          """
    ),
    0x23: BlockDef(
        block_id=0x23,
        description="yellow rivet with support parallel to the y axis",
        address=0x1EDE,
        tile_ptr=0x1C30,
        tile_data=[0xD6, 0xD5, 0xAB, 0xD2, 0xD1, 0xA8, 0x28, 0x09, 0x6E, 0x6F, 0x72, 0x71],
        bytecode=[0xEA, 0x75, 0x19],
        dsl="""
          [SCRIPT35]
          TILES 214,213,171,210,209,168,40,9,110,111,114,113
          JMP SCRIPT1, 0
          """
    ),
    0x24: BlockDef(
        block_id=0x24,
        description="red railing corner",
        address=0x18DA,
        tile_ptr=0x16C2,
        tile_data=[0x37, 0x36, 0x35, 0x00, 0x34, 0x33, 0x32, 0x00, 0x99, 0x9A, 0x97, 0x98],
        bytecode=[0xEC, 0xE7, 0x18, 0xF7, 0x6E, 0x00, 0xF3, 0xEC, 0x55, 0x19, 0xFF],
        dsl="""
          [SCRIPT36]
          TILES 55,54,53,0,52,51,50,0,153,154,151,152
          CALL SCRIPT97
          LD PARAM2, 0
          DEC X
          CALL SCRIPT8
          END
          """
    ),
    0x25: BlockDef(
        block_id=0x25,
        description="yellow rivet with support parallel to the x axis",
        address=0x1EE3,
        tile_ptr=0x1C33,
        tile_data=[0xD2, 0xD1, 0xA8, 0x28, 0x09, 0x6E, 0x6F, 0x72, 0x71, 0x70, 0x2B, 0x0A],
        bytecode=[0xEA, 0x8C, 0x19],
        dsl="""
          [SCRIPT37]
          TILES 210,209,168,40,9,110,111,114,113,112,43,10
          JMP SCRIPT106, 0
          """
    ),
    0x26: BlockDef(
        block_id=0x26,
        description="red railing corner (2)",
        address=0x18EF,
        tile_ptr=0x16C2,
        tile_data=[0x37, 0x36, 0x35, 0x00, 0x34, 0x33, 0x32, 0x00, 0x99, 0x9A, 0x97, 0x98],
        bytecode=[0xEC, 0xE7, 0x18, 0xF2, 0x6E, 0x84, 0x6D, 0xF1, 0x01, 0x6E, 0x6D, 0xF7, 0x6E, 0x00, 0xEC, 0x55, 0x19, 0xFF],
        dsl="""
          [SCRIPT38]
          TILES 55,54,53,0,52,51,50,0,153,154,151,152
          CALL SCRIPT97
          ADD Y, -( PARAM1 ) + PARAM2
          ADD X, 1 + PARAM2 + PARAM1
          LD PARAM2, 0
          CALL SCRIPT8
          END
          """
    ),
    0x27: BlockDef(
        block_id=0x27,
        description="rounded passage hole with thin red and black bricks parallel to the x axis",
        address=0x1F1A,
        tile_ptr=0x1C36,
        tile_data=[0x28, 0x09, 0x6E, 0x6F, 0x72, 0x71, 0x70, 0x2B, 0x0A, 0x2B, 0x0A, 0x5A],
        bytecode=[0xE9, 0xEA, 0xEA, 0x1E],
        dsl="""
          [SCRIPT39]
          TILES 40,9,110,111,114,113,112,43,10,43,10,90
          FLIP X
          JMP SCRIPT50, 0
          """
    ),
    0x28: BlockDef(
        block_id=0x28,
        description="small windows block, rectangular and black parallel to the y axis",
        address=0x192D,
        tile_ptr=0x16AA,
        tile_data=[0x23, 0x22, 0x61, 0x29, 0x26, 0x25, 0x27, 0x2D, 0x62, 0x02, 0x63, 0x03],
        bytecode=[0xEA, 0x90, 0x19],
        dsl="""
          [SCRIPT40]
          TILES 35,34,97,41,38,37,39,45,98,2,99,3
          JMP SCRIPT109, 0
          """
    ),
    0x29: BlockDef(
        block_id=0x29,
        description="small windows block, rectangular and red parallel to the x axis",
        address=0x1928,
        tile_ptr=0x16AE,
        tile_data=[0x26, 0x25, 0x27, 0x2D, 0x62, 0x02, 0x63, 0x03, 0x6A, 0x06, 0x74, 0x07],
        bytecode=[0xEA, 0xA9, 0x19],
        dsl="""
          [SCRIPT41]
          TILES 38,37,39,45,98,2,99,3,106,6,116,7
          JMP SCRIPT110, 0
          """
    ),
    0x2A: BlockDef(
        block_id=0x2A,
        description="1 bottle and a jar",
        address=0x191E,
        tile_ptr=0x1693,
        tile_data=[0x2A, 0x2C, 0xE0, 0xDF, 0xDE, 0xFD, 0xFC, 0x5F, 0xFE, 0x1B, 0x3A, 0x3A],
        bytecode=[0xF9, 0x61, 0x80, 0x62, 0xFF],
        dsl="""
          [SCRIPT42]
          TILES 42,44,224,223,222,253,252,95,254,27,58,58
          DRAWTILE T0
          DEC Y
          DRAWTILE T1
          DEC Y
          END
          """
    ),
    0x2B: BlockDef(
        block_id=0x2B,
        description="does nothing",
        address=0x1925,
        tile_ptr=0x16AE,
        tile_data=[0x26, 0x25, 0x27, 0x2D, 0x62, 0x02, 0x63, 0x03, 0x6A, 0x06, 0x74, 0x07],
        bytecode=[0xFF],
        dsl="""
          [SCRIPT43]
          TILES 38,37,39,45,98,2,99,3,106,6,116,7
          END
          """
    ),
    0x2C: BlockDef(
        block_id=0x2C,
        description="stairs with black brick on the edge parallel to the y axis (2)",
        address=0x1AE9,
        tile_ptr=0x16FC,
        tile_data=[0x1C, 0x1B, 0xB8, 0xB7, 0xBA, 0xB9, 0xB6, 0xBB, 0x28, 0x09, 0x6B, 0x69],
        bytecode=[0xE9, 0xEA, 0x9B, 0x1A],
        dsl="""
          [SCRIPT44]
          TILES 28,27,184,183,186,185,182,187,40,9,107,105
          FLIP X
          JMP SCRIPT45, 0
          """
    ),
    0x2D: BlockDef(
        block_id=0x2D,
        description="stairs with red brick on the edge parallel to the x axis (2)",
        address=0x1A99,
        tile_ptr=0x1706,
        tile_data=[0x6B, 0x69, 0x6C, 0xB0, 0xAD, 0xAC, 0xAF, 0xAE, 0x2B, 0x0A, 0x58, 0x28],
        bytecode=[0xF7, 0x71, 0x02, 0x6E, 0x6E, 0x84, 0x71, 0xF7, 0x70, 0x01, 0x84, 0x70, 0xFC, 0xFC, 0xF8, 0x69, 0xFE, 0xF8, 0x6A, 0xFA, 0xFB, 0xF4, 0xFC, 0xF8, 0x61, 0xFE, 0xF8, 0x62, 0xFA, 0xF8, 0x63, 0xFB, 0xF4, 0xFD, 0xFC, 0xF8, 0x66, 0xFE, 0xF8, 0x64, 0xFA, 0xF8, 0x65, 0x80, 0x63, 0xFB, 0xF4, 0xF5, 0xFA, 0xF8, 0x66, 0xFE, 0xF8, 0x67, 0xFA, 0xF8, 0x68, 0xFB, 0xF7, 0x6E, 0x00, 0xFE, 0xF5, 0xF6, 0xFC, 0xF9, 0x69, 0xFD, 0xF9, 0x6A, 0xFA, 0xF7, 0x6E, 0x01, 0x6E, 0xFB, 0xFA, 0xFF],
        dsl="""
          [SCRIPT45]
          TILES 107,105,108,176,173,172,175,174,43,10,88,40
          LD DEPTHY, 2 + PARAM2 + PARAM2 - DEPTHY
          LD DEPTHX, -( DEPTHX ) + 1
          PUSH X
          PUSH Y
          PUSH X
          PUSH Y
          DRAWTILE T8
          INC X
          WHILE PARAM1
            DRAWTILE T9
            INC X
          ENDWHILE
          POP Y
          POP X
          DEC Y
          PUSH X
          PUSH Y
          DRAWTILE T0
          INC X
          WHILE PARAM1
            DRAWTILE T1
            INC X
          ENDWHILE
          DRAWTILE T2
          INC X
          POP Y
          POP X
          DEC Y
          WHILE PARAM2
            PUSH X
            PUSH Y
            DRAWTILE T5
            INC X
            WHILE PARAM1
              DRAWTILE T3
              INC X
            ENDWHILE
            DRAWTILE T4
            INC X
            DRAWTILE T2
            INC X
            POP Y
            POP X
            DEC Y
            INC X
          ENDWHILE
          DRAWTILE T5
          INC X
          WHILE PARAM1
            DRAWTILE T6
            INC X
          ENDWHILE
          DRAWTILE T7
          INC X
          POP Y
          POP X
          LD PARAM2, 0
          WHILE PARAM1
            INC X
            INC Y
            PUSH X
            PUSH Y
            DRAWTILE T8
            DEC Y
            WHILE PARAM2
              DRAWTILE T9
              DEC Y
            ENDWHILE
            LD PARAM2, 1 + PARAM2
            POP Y
            POP X
          ENDWHILE
          END
          """
    ),
    0x2E: BlockDef(
        block_id=0x2E,
        description="rectangular passage hole with thin black bricks parallel to the y axis",
        address=0x1726,
        tile_ptr=0x1710,
        tile_data=[0x58, 0x28, 0x51, 0x53, 0x57, 0x55, 0x54, 0x50, 0x52, 0x2B, 0x0A, 0x7F],
        bytecode=[0xFC, 0xF2, 0x01, 0x6D, 0x84, 0xF1, 0x6D, 0xF7, 0x70, 0x02, 0x84, 0x70, 0xF7, 0x71, 0x03, 0x6D, 0x6D, 0x84, 0x71, 0xFC, 0xF9, 0x6A, 0xFD, 0xF9, 0x6B, 0xFA, 0xFB, 0xF5, 0xF9, 0x61, 0xFD, 0xF9, 0x65, 0xFA, 0xF9, 0x68, 0x80, 0x63, 0x80, 0x69, 0xFB, 0xEF, 0xF7, 0x71, 0x02, 0x6D, 0x6D, 0x71, 0xF9, 0x61, 0xFD, 0xF9, 0x65, 0xFA, 0xF9, 0x66, 0x80, 0x67, 0xF7, 0x70, 0x02, 0x70, 0xF7, 0x71, 0x6D, 0x6D, 0x84, 0x71, 0xF6, 0xF6, 0xF5, 0xFE, 0xFC, 0xF9, 0x62, 0x80, 0x63, 0x80, 0x64, 0xFB, 0xF5, 0xF4, 0xFA, 0xFF],
        dsl="""
          [SCRIPT46]
          TILES 88,40,81,83,87,85,84,80,82,43,10,127
          PUSH X
          PUSH Y
          ADD Y, -( 1 + PARAM1 )
          ADD X, PARAM1
          LD DEPTHX, -( DEPTHX ) + 2
          LD DEPTHY, 3 + PARAM1 + PARAM1 - DEPTHY
          PUSH X
          PUSH Y
          DRAWTILE T9
          DEC Y
          WHILE PARAM2
            DRAWTILE T10
            DEC Y
          ENDWHILE
          POP Y
          POP X
          INC X
          DRAWTILE T0
          DEC Y
          WHILE PARAM2
            DRAWTILE T4
            DEC Y
          ENDWHILE
          DRAWTILE T7
          DEC Y
          DRAWTILE T2
          DEC Y
          DRAWTILE T8
          DEC Y
          POP Y
          POP X
          INC PARAM2
          LD DEPTHY, 2 + PARAM1 + PARAM1 + DEPTHY
          DRAWTILE T0
          DEC Y
          WHILE PARAM2
            DRAWTILE T4
            DEC Y
          ENDWHILE
          DRAWTILE T5
          DEC Y
          DRAWTILE T6
          DEC Y
          LD DEPTHX, 2 + DEPTHX
          LD DEPTHY, PARAM1 + PARAM1 - DEPTHY
          INC Y
          INC Y
          INC X
          WHILE PARAM1
            PUSH X
            PUSH Y
            DRAWTILE T1
            DEC Y
            DRAWTILE T2
            DEC Y
            DRAWTILE T3
            DEC Y
            POP Y
            POP X
            INC X
            DEC Y
          ENDWHILE
          END
          """
    ),
    0x2F: BlockDef(
        block_id=0x2F,
        description="rectangular passage hole with thin red bricks parallel to the x axis",
        address=0x177C,
        tile_ptr=0x171B,
        tile_data=[0x7F, 0x2B, 0x78, 0x7A, 0x7E, 0x7C, 0x7B, 0x77, 0x79, 0x28, 0x09, 0x10],
        bytecode=[0xFC, 0xF2, 0x01, 0x6D, 0x84, 0xF1, 0x6D, 0x84, 0xE9, 0xEA, 0x2F, 0x17],
        dsl="""
          [SCRIPT47]
          TILES 127,43,120,122,126,124,123,119,121,40,9,16
          PUSH X
          PUSH Y
          ADD Y, -( 1 + PARAM1 )
          ADD X, -( PARAM1 )
          FLIP X
          JMP SCRIPT46, 7
          """
    ),
    0x30: BlockDef(
        block_id=0x30,
        description="thin black and red brick corner",
        address=0x17A4,
        tile_ptr=0x16A6,
        tile_data=[0x2B, 0x0A, 0x2D, 0x00, 0x23, 0x22, 0x61, 0x29, 0x26, 0x25, 0x27, 0x2D],
        bytecode=[0xEC, 0x6E, 0x19, 0xF5, 0xEC, 0x73, 0x19, 0xFF],
        dsl="""
          [SCRIPT48]
          TILES 43,10,45,0,35,34,97,41,38,37,39,45
          CALL SCRIPT2
          INC X
          CALL SCRIPT1
          END
          """
    ),
    0x31: BlockDef(
        block_id=0x31,
        description="thick black and red brick corner",
        address=0x17AE,
        tile_ptr=0x16B6,
        tile_data=[0x6A, 0x06, 0x74, 0x07, 0x23, 0x22, 0x21, 0x29, 0x26, 0x25, 0x24, 0x2D],
        bytecode=[0xEC, 0x41, 0x19, 0xF5, 0xEC, 0x3C, 0x19, 0xFF],
        dsl="""
          [SCRIPT49]
          TILES 106,6,116,7,35,34,33,41,38,37,36,45
          CALL SCRIPT4
          INC X
          CALL SCRIPT3
          END
          """
    ),
    0x32: BlockDef(
        block_id=0x32,
        description="rounded passage hole with thin black and red bricks parallel to the y axis",
        address=0x1EE8,
        tile_ptr=0x1C3F,
        tile_data=[0x2B, 0x0A, 0x5A, 0x5B, 0x5E, 0x5D, 0x5C, 0x28, 0x09, 0xC4, 0xC3, 0xC2],
        bytecode=[0xF7, 0x71, 0x01, 0x71, 0xF0, 0xF7, 0x70, 0x01, 0x70, 0xFE, 0xFC, 0xF5, 0xF4, 0xF4, 0xE4, 0x20, 0x1F, 0xFB, 0xF7, 0x71, 0x04, 0x84, 0x71, 0xF9, 0x65, 0x80, 0x66, 0x80, 0x66, 0x80, 0x66, 0x80, 0x66, 0x80, 0x67, 0x80, 0x64, 0xF5, 0xF6, 0xF9, 0x63, 0x80, 0x69, 0xF5, 0xF2, 0x06, 0xFA, 0xFF],
        dsl="""
          [SCRIPT50]
          TILES 43,10,90,91,94,93,92,40,9,196,195,194
          LD DEPTHY, 1 + DEPTHY
          INC PARAM1
          LD DEPTHX, 1 + DEPTHX
          WHILE PARAM1
            PUSH X
            PUSH Y
            INC X
            DEC Y
            DEC Y
            FLIP X
            CALL SCRIPT39, 4
            POP Y
            POP X
            LD DEPTHY, -( DEPTHY ) + 4
            DRAWTILE T4
            DEC Y
            DRAWTILE T5
            DEC Y
            DRAWTILE T5
            DEC Y
            DRAWTILE T5
            DEC Y
            DRAWTILE T5
            DEC Y
            DRAWTILE T6
            DEC Y
            DRAWTILE T3
            DEC Y
            INC X
            INC Y
            DRAWTILE T2
            DEC Y
            DRAWTILE T8
            DEC Y
            INC X
            ADD Y, 6
          ENDWHILE
          END
          """
    ),
    0x33: BlockDef(
        block_id=0x33,
        description="yellow rivet corner with support",
        address=0x1C86,
        tile_ptr=0x1C30,
        tile_data=[0xD6, 0xD5, 0xAB, 0xD2, 0xD1, 0xA8, 0x28, 0x09, 0x6E, 0x6F, 0x72, 0x71],
        bytecode=[0xEC, 0xA6, 0x1C, 0xF7, 0x6E, 0x6D, 0xF7, 0x6D, 0x01, 0xF3, 0xEC, 0xE3, 0x1E, 0xFF],
        dsl="""
          [SCRIPT51]
          TILES 214,213,171,210,209,168,40,9,110,111,114,113
          CALL SCRIPT99
          LD PARAM2, PARAM1
          LD PARAM1, 1
          DEC X
          CALL SCRIPT37
          END
          """
    ),
    0x34: BlockDef(
        block_id=0x34,
        description="yellow rivet corner",
        address=0x1C96,
        tile_ptr=0x1C78,
        tile_data=[0xAA, 0xAB, 0xAB, 0xAA, 0xA9, 0xA8, 0xA8, 0xA9, 0x3F, 0x3E, 0x3D, 0x3C],
        bytecode=[0xEC, 0xAF, 0x1C, 0xF7, 0x6E, 0x6D, 0xF7, 0x6D, 0x00, 0xF3, 0xEC, 0x64, 0x1F, 0xFF],
        dsl="""
          [SCRIPT52]
          TILES 170,171,171,170,169,168,168,169,63,62,61,60
          CALL SCRIPT100
          LD PARAM2, PARAM1
          LD PARAM1, 0
          DEC X
          CALL SCRIPT22
          END
          """
    ),
    0x35: BlockDef(
        block_id=0x35,
        description="does nothing",
        address=0x17B8,
        tile_ptr=0x1B31,
        tile_data=[0x08, 0x76, 0x75, 0x28, 0x29, 0x2B, 0x2D, 0x0A, 0x09, 0x08, 0x75, 0x76],
        bytecode=[0xFF],
        dsl="""
          [SCRIPT53]
          TILES 8,118,117,40,41,43,45,10,9,8,117,118
          END
          """
    ),
    0x36: BlockDef(
        block_id=0x36,
        description="red railing corner (3)",
        address=0x1903,
        tile_ptr=0x16C2,
        tile_data=[0x37, 0x36, 0x35, 0x00, 0x34, 0x33, 0x32, 0x00, 0x99, 0x9A, 0x97, 0x98],
        bytecode=[0xEC, 0xE7, 0x18, 0xF2, 0x6D, 0x01, 0xF1, 0x6D, 0xF7, 0x6E, 0x00, 0xEC, 0x55, 0x19, 0xFF],
        dsl="""
          [SCRIPT54]
          TILES 55,54,53,0,52,51,50,0,153,154,151,152
          CALL SCRIPT97
          ADD Y, PARAM1 + 1
          ADD X, PARAM1
          LD PARAM2, 0
          CALL SCRIPT8
          END
          """
    ),
    0x37: BlockDef(
        block_id=0x37,
        description="thin red and black brick pyramid",
        address=0x1F76,
        tile_ptr=0x1F72,
        tile_data=[0x28, 0x09, 0x4C, 0x4B, 0x72, 0x1F, 0xEC, 0x86, 0x1F, 0xF3, 0xEC, 0x80],
        bytecode=[0xEC, 0x86, 0x1F, 0xF3, 0xEC, 0x80, 0x1F, 0xFF],
        dsl="""
          [SCRIPT55]
          TILES 40,9,76,75,114,31,236,134,31,243,236,128
          CALL SCRIPT66
          DEC X
          CALL SCRIPT65
          END
          """
    ),
    0x38: BlockDef(
        block_id=0x38,
        description="solid block of thin red and black brick, with yellow and black tiles on top, parallel to the y axis",
        address=0x18AB,
        tile_ptr=0x1B64,
        tile_data=[0x87, 0xCF, 0x88, 0x2B, 0x2D, 0x28, 0x29, 0x09, 0x0A, 0xFF, 0x45, 0x44],
        bytecode=[0xE9, 0xEA, 0x05, 0x18],
        dsl="""
          [SCRIPT56]
          TILES 135,207,136,43,45,40,41,9,10,255,69,68
          FLIP X
          JMP SCRIPT57, 0
          """
    ),
    0x39: BlockDef(
        block_id=0x39,
        description="solid block of thin red and black brick, with yellow and black tiles on top, parallel to the x axis",
        address=0x1803,
        tile_ptr=0x1B5B,
        tile_data=[0x87, 0x88, 0xCF, 0x28, 0x29, 0x2B, 0x2D, 0x0A, 0x09, 0x87, 0xCF, 0x88],
        bytecode=[0xF7, 0x71, 0x71, 0x82, 0xFF, 0xF7, 0x70, 0x6E, 0x6E, 0x02, 0x84, 0x70, 0xFC, 0xF9, 0x64, 0xFE, 0xF9, 0x69, 0xFA, 0xF9, 0x61, 0x81, 0x65, 0x80, 0x62, 0xFB, 0xF3, 0xFD, 0xFC, 0xF9, 0x66, 0xFE, 0xF9, 0x68, 0xFA, 0xF9, 0x61, 0x81, 0x67, 0x80, 0x61, 0x80, 0x62, 0xFB, 0xF3, 0xF4, 0xFA, 0xF9, 0x66, 0xFE, 0xF9, 0x68, 0xFA, 0xF9, 0x61, 0x81, 0x67, 0x80, 0x63, 0xFF],
        dsl="""
          [SCRIPT57]
          TILES 135,136,207,40,41,43,45,10,9,135,207,136
          LD DEPTHY, DEPTHY + 255
          LD DEPTHX, PARAM2 + PARAM2 + 2 - DEPTHX
          PUSH X
          PUSH Y
          DRAWTILE T3
          DEC Y
          WHILE PARAM1
            DRAWTILE T8
            DEC Y
          ENDWHILE
          DRAWTILE T0
          DRAWTILE T4
          DEC Y
          DRAWTILE T1
          DEC Y
          POP Y
          POP X
          DEC X
          WHILE PARAM2
            PUSH X
            PUSH Y
            DRAWTILE T5
            DEC Y
            WHILE PARAM1
              DRAWTILE T7
              DEC Y
            ENDWHILE
            DRAWTILE T0
            DRAWTILE T6
            DEC Y
            DRAWTILE T0
            DEC Y
            DRAWTILE T1
            DEC Y
            POP Y
            POP X
            DEC X
            DEC Y
          ENDWHILE
          DRAWTILE T5
          DEC Y
          WHILE PARAM1
            DRAWTILE T7
            DEC Y
          ENDWHILE
          DRAWTILE T0
          DRAWTILE T6
          DEC Y
          DRAWTILE T2
          DEC Y
          END
          """
    ),
    0x3A: BlockDef(
        block_id=0x3A,
        description="solid block of thin red and black brick, with yellow and black tiles on top, that grows upwards",
        address=0x18CD,
        tile_ptr=0x1B5B,
        tile_data=[0x87, 0x88, 0xCF, 0x28, 0x29, 0x2B, 0x2D, 0x0A, 0x09, 0x87, 0xCF, 0x88],
        bytecode=[0xF7, 0x6D, 0x6D, 0x6E, 0xF7, 0x6E, 0x00, 0xEC, 0xAB, 0x18, 0xFF],
        dsl="""
          [SCRIPT58]
          TILES 135,136,207,40,41,43,45,10,9,135,207,136
          LD PARAM1, PARAM1 + PARAM2
          LD PARAM2, 0
          CALL SCRIPT56
          END
          """
    ),
    0x3B: BlockDef(
        block_id=0x3B,
        description="candelabras with 2 candles parallel to the x axis (2)",
        address=0x1EC6,
        tile_ptr=0x1C21,
        tile_data=[0x5F, 0xCB, 0xCD, 0xCA, 0x46, 0x5F, 0xCE, 0xCD, 0xCC, 0x60, 0x6D, 0xCE],
        bytecode=[0xE9, 0xEA, 0xA5, 0x1E],
        dsl="""
          [SCRIPT59]
          TILES 95,203,205,202,70,95,206,205,204,96,109,206
          FLIP X
          JMP SCRIPT60, 0
          """
    ),
    0x3C: BlockDef(
        block_id=0x3C,
        description="candelabras with 2 candles parallel to the y axis",
        address=0x1EA3,
        tile_ptr=0x1C26,
        tile_data=[0x5F, 0xCE, 0xCD, 0xCC, 0x60, 0x6D, 0xCE, 0xCD, 0xCC, 0x60, 0xD6, 0xD5],
        bytecode=[0xF7, 0x71, 0x01, 0x6D, 0x6D, 0x84, 0x71, 0xF0, 0xEF, 0xFD, 0xFC, 0xFE, 0xFC, 0xF9, 0x61, 0x80, 0x62, 0x80, 0x63, 0x80, 0x64, 0x80, 0x65, 0xFB, 0xF5, 0xF4, 0xFA, 0xFB, 0xF2, 0x05, 0x84, 0xFA, 0xFF],
        dsl="""
          [SCRIPT60]
          TILES 95,206,205,204,96,109,206,205,204,96,214,213
          LD DEPTHY, 1 + PARAM1 + PARAM1 - DEPTHY
          INC PARAM1
          INC PARAM2
          WHILE PARAM2
            PUSH X
            PUSH Y
            WHILE PARAM1
              PUSH X
              PUSH Y
              DRAWTILE T0
              DEC Y
              DRAWTILE T1
              DEC Y
              DRAWTILE T2
              DEC Y
              DRAWTILE T3
              DEC Y
              DRAWTILE T4
              DEC Y
              POP Y
              POP X
              INC X
              DEC Y
            ENDWHILE
            POP Y
            POP X
            ADD Y, -( 5 )
          ENDWHILE
          END
          """
    ),
    0x3D: BlockDef(
        block_id=0x3D,
        description="candelabras with wall support and 2 candles parallel to the y axis",
        address=0x1ED1,
        tile_ptr=0x1C2B,
        tile_data=[0x6D, 0xCE, 0xCD, 0xCC, 0x60, 0xD6, 0xD5, 0xAB, 0xD2, 0xD1, 0xA8, 0x28],
        bytecode=[0xEA, 0xA5, 0x1E],
        dsl="""
          [SCRIPT61]
          TILES 109,206,205,204,96,214,213,171,210,209,168,40
          JMP SCRIPT60, 0
          """
    ),
    0x3E: BlockDef(
        block_id=0x3E,
        description="small discharge pillar placed next to a wall on the y axis",
        address=0x1937,
        tile_ptr=0x16DA,
        tile_data=[0x58, 0x57, 0x56, 0x00, 0x41, 0x17, 0x16, 0x1A, 0x14, 0x1D, 0x1E, 0x40],
        bytecode=[0xEA, 0x75, 0x19],
        dsl="""
          [SCRIPT62]
          TILES 88,87,86,0,65,23,22,26,20,29,30,64
          JMP SCRIPT1, 0
          """
    ),
    0x3F: BlockDef(
        block_id=0x3F,
        description="thin black and red brick corner (2)",
        address=0x18B1,
        tile_ptr=0x16A6,
        tile_data=[0x2B, 0x0A, 0x2D, 0x00, 0x23, 0x22, 0x61, 0x29, 0x26, 0x25, 0x27, 0x2D],
        bytecode=[0xF5, 0xEC, 0x73, 0x19, 0xF3, 0xF7, 0x6E, 0x00, 0xEC, 0x6E, 0x19, 0xFF],
        dsl="""
          [SCRIPT63]
          TILES 43,10,45,0,35,34,97,41,38,37,39,45
          INC X
          CALL SCRIPT1
          DEC X
          LD PARAM2, 0
          CALL SCRIPT2
          END
          """
    ),
    0x40: BlockDef(
        block_id=0x40,
        description="thin black and red brick corner (3)",
        address=0x18BF,
        tile_ptr=0x16A2,
        tile_data=[0x28, 0x09, 0x29, 0x00, 0x2B, 0x0A, 0x2D, 0x00, 0x23, 0x22, 0x61, 0x29],
        bytecode=[0xF3, 0xEC, 0x6E, 0x19, 0xF5, 0xF7, 0x6E, 0x00, 0xEC, 0x73, 0x19, 0xFF],
        dsl="""
          [SCRIPT64]
          TILES 40,9,41,0,43,10,45,0,35,34,97,41
          DEC X
          CALL SCRIPT2
          INC X
          LD PARAM2, 0
          CALL SCRIPT1
          END
          """
    ),
    0x41: BlockDef(
        block_id=0x41,
        description="thin red brick forming a right triangle parallel to the x axis",
        address=0x1F80,
        tile_ptr=0x1F6E,
        tile_data=[0x2B, 0x0A, 0x49, 0x4A, 0x28, 0x09, 0x4C, 0x4B, 0x72, 0x1F, 0xEC, 0x86],
        bytecode=[0xE9, 0xEA, 0x88, 0x1F],
        dsl="""
          [SCRIPT65]
          TILES 43,10,73,74,40,9,76,75,114,31,236,134
          FLIP X
          JMP SCRIPT66, 0
          """
    ),
    0x42: BlockDef(
        block_id=0x42,
        description="thin black brick forming a right triangle parallel to the y axis",
        address=0x1F86,
        tile_ptr=0x1F72,
        tile_data=[0x28, 0x09, 0x4C, 0x4B, 0x72, 0x1F, 0xEC, 0x86, 0x1F, 0xF3, 0xEC, 0x80],
        bytecode=[0xF7, 0x6D, 0x6E, 0x6D, 0xF7, 0x6E, 0x6D, 0x01, 0xF7, 0x71, 0x01, 0x6D, 0x6D, 0x84, 0x71, 0xF7, 0x70, 0x02, 0x6D, 0x6D, 0x84, 0x70, 0xFD, 0xFC, 0xF9, 0x61, 0xFE, 0xF9, 0x62, 0x80, 0x62, 0x80, 0x62, 0xFA, 0xF9, 0x63, 0x80, 0x64, 0xF7, 0x6D, 0x01, 0x84, 0x6D, 0xFB, 0xF5, 0xF4, 0xFA, 0xFF],
        dsl="""
          [SCRIPT66]
          TILES 40,9,76,75,114,31,236,134,31,243,236,128
          LD PARAM1, PARAM2 + PARAM1
          LD PARAM2, PARAM1 + 1
          LD DEPTHY, 1 + PARAM1 + PARAM1 - DEPTHY
          LD DEPTHX, 2 + PARAM1 + PARAM1 - DEPTHX
          WHILE PARAM2
            PUSH X
            PUSH Y
            DRAWTILE T0
            DEC Y
            WHILE PARAM1
              DRAWTILE T1
              DEC Y
              DRAWTILE T1
              DEC Y
              DRAWTILE T1
              DEC Y
            ENDWHILE
            DRAWTILE T2
            DEC Y
            DRAWTILE T3
            DEC Y
            LD PARAM1, -( PARAM1 ) + 1
            POP Y
            POP X
            INC X
            DEC Y
          ENDWHILE
          END
          """
    ),
    0x43: BlockDef(
        block_id=0x43,
        description="rounded passage hole with thin red and black bricks parallel to the y axis, with thick pillars between the holes",
        address=0x1F2B,
        tile_ptr=0x1C3F,
        tile_data=[0x2B, 0x0A, 0x5A, 0x5B, 0x5E, 0x5D, 0x5C, 0x28, 0x09, 0xC4, 0xC3, 0xC2],
        bytecode=[0xF7, 0x6E, 0x6D, 0x01, 0xF7, 0x71, 0x01, 0x71, 0xF7, 0x70, 0x02, 0x84, 0x70, 0xFD, 0xF7, 0x6D, 0x00, 0xE4, 0xE8, 0x1E, 0xF5, 0xF5, 0xF4, 0xF4, 0xFC, 0xF7, 0x71, 0x06, 0x84, 0x71, 0xF7, 0x6D, 0x06, 0xF9, 0x68, 0xFE, 0xF9, 0x69, 0xFA, 0xFB, 0xF5, 0xF4, 0xFA, 0xFF],
        dsl="""
          [SCRIPT67]
          TILES 43,10,90,91,94,93,92,40,9,196,195,194
          LD PARAM2, PARAM1 + 1
          LD DEPTHY, 1 + DEPTHY
          LD DEPTHX, -( DEPTHX ) + 2
          WHILE PARAM2
            LD PARAM1, 0
            FLIP X
            CALL SCRIPT50
            INC X
            INC X
            DEC Y
            DEC Y
            PUSH X
            PUSH Y
            LD DEPTHY, -( DEPTHY ) + 6
            LD PARAM1, 6
            DRAWTILE T7
            DEC Y
            WHILE PARAM1
              DRAWTILE T8
              DEC Y
            ENDWHILE
            POP Y
            POP X
            INC X
            DEC Y
          ENDWHILE
          END
          """
    ),
    0x44: BlockDef(
        block_id=0x44,
        description="rounded passage hole with thin red and black bricks parallel to the x axis, with thick pillars between the holes",
        address=0x1F59,
        tile_ptr=0x1C36,
        tile_data=[0x28, 0x09, 0x6E, 0x6F, 0x72, 0x71, 0x70, 0x2B, 0x0A, 0x2B, 0x0A, 0x5A],
        bytecode=[0xE9, 0xEA, 0x2D, 0x1F],
        dsl="""
          [SCRIPT68]
          TILES 40,9,110,111,114,113,112,43,10,43,10,90
          FLIP X
          JMP SCRIPT67, 0
          """
    ),
    0x45: BlockDef(
        block_id=0x45,
        description="bench to sit on parallel to the x axis",
        address=0x1D99,
        tile_ptr=0x1C6E,
        tile_data=[0x41, 0x47, 0x75, 0x08, 0x76, 0x40, 0x38, 0x20, 0x42, 0x1F, 0xAA, 0xAB],
        bytecode=[0xE9, 0xEA, 0x6D, 0x1D],
        dsl="""
          [SCRIPT69]
          TILES 65,71,117,8,118,64,56,32,66,31,170,171
          FLIP X
          JMP SCRIPT70, 0
          """
    ),
    0x46: BlockDef(
        block_id=0x46,
        description="bench to sit on parallel to the y axis",
        address=0x1D6B,
        tile_ptr=0x1C64,
        tile_data=[0x67, 0x48, 0x76, 0x08, 0x75, 0x66, 0x68, 0x65, 0x3B, 0x64, 0x41, 0x47],
        bytecode=[0xF6, 0xF5, 0xFC, 0xF9, 0x61, 0x80, 0x62, 0x80, 0x63, 0xFB, 0xF3, 0xF6, 0xFE, 0xFC, 0xF9, 0x61, 0x80, 0x62, 0x80, 0x64, 0x80, 0x65, 0xFB, 0xF3, 0xF6, 0xFA, 0xFC, 0xF9, 0x66, 0x80, 0x67, 0x80, 0x64, 0x80, 0x65, 0xFB, 0xF3, 0xF9, 0x6A, 0x80, 0x68, 0x80, 0x69, 0xFF],
        dsl="""
          [SCRIPT70]
          TILES 103,72,118,8,117,102,104,101,59,100,65,71
          INC Y
          INC X
          PUSH X
          PUSH Y
          DRAWTILE T0
          DEC Y
          DRAWTILE T1
          DEC Y
          DRAWTILE T2
          DEC Y
          POP Y
          POP X
          DEC X
          INC Y
          WHILE PARAM1
            PUSH X
            PUSH Y
            DRAWTILE T0
            DEC Y
            DRAWTILE T1
            DEC Y
            DRAWTILE T3
            DEC Y
            DRAWTILE T4
            DEC Y
            POP Y
            POP X
            DEC X
            INC Y
          ENDWHILE
          PUSH X
          PUSH Y
          DRAWTILE T5
          DEC Y
          DRAWTILE T6
          DEC Y
          DRAWTILE T3
          DEC Y
          DRAWTILE T4
          DEC Y
          POP Y
          POP X
          DEC X
          DRAWTILE T9
          DEC Y
          DRAWTILE T7
          DEC Y
          DRAWTILE T8
          DEC Y
          END
          """
    ),
    0x47: BlockDef(
        block_id=0x47,
        description="very low thin black and red brick corner",
        address=0x1797,
        tile_ptr=0x16A2,
        tile_data=[0x28, 0x09, 0x29, 0x00, 0x2B, 0x0A, 0x2D, 0x00, 0x23, 0x22, 0x61, 0x29],
        bytecode=[0xEC, 0x73, 0x19, 0xF1, 0x6E, 0x6E, 0x01, 0xEC, 0x6E, 0x19, 0xFF],
        dsl="""
          [SCRIPT71]
          TILES 40,9,41,0,43,10,45,0,35,34,97,41
          CALL SCRIPT1
          ADD X, PARAM2 + PARAM2 + 1
          CALL SCRIPT2
          END
          """
    ),
    0x48: BlockDef(
        block_id=0x48,
        description="very low thick black and red brick corner",
        address=0x178A,
        tile_ptr=0x16B2,
        tile_data=[0x62, 0x02, 0x63, 0x03, 0x6A, 0x06, 0x74, 0x07, 0x23, 0x22, 0x21, 0x29],
        bytecode=[0xEC, 0x3C, 0x19, 0xF1, 0x6E, 0x6E, 0x01, 0xEC, 0x41, 0x19, 0xFF],
        dsl="""
          [SCRIPT72]
          TILES 98,2,99,3,106,6,116,7,35,34,33,41
          CALL SCRIPT3
          ADD X, PARAM2 + PARAM2 + 1
          CALL SCRIPT4
          END
          """
    ),
    0x49: BlockDef(
        block_id=0x49,
        description="flat corner delimited with black line and blue floor",
        address=0x1B96,
        tile_ptr=0x1B6D,
        tile_data=[0xFF, 0x45, 0x44, 0x28, 0x29, 0x2B, 0x2D, 0x0A, 0x09, 0xFF, 0x44, 0x45],
        bytecode=[0xEA, 0xCF, 0x1B],
        dsl="""
          [SCRIPT73]
          TILES 255,69,68,40,41,43,45,10,9,255,68,69
          JMP SCRIPT113, 0
          """
    ),
    0x4A: BlockDef(
        block_id=0x4A,
        description="work table",
        address=0x1D9F,
        tile_ptr=0x16DE,
        tile_data=[0x41, 0x17, 0x16, 0x1A, 0x14, 0x1D, 0x1E, 0x40, 0x15, 0x1F, 0x20, 0x19],
        bytecode=[0xE9, 0xF6, 0xF5, 0xFC, 0xF9, 0x61, 0x80, 0x62, 0x80, 0x63, 0x80, 0x64, 0xFB, 0xF3, 0xF6, 0xFE, 0xFC, 0xF9, 0x61, 0x80, 0x62, 0x80, 0x82, 0x43, 0x80, 0x66, 0x80, 0x67, 0xFB, 0xF3, 0xF6, 0xFA, 0xFC, 0xF9, 0x68, 0x80, 0x69, 0x80, 0x82, 0x18, 0x80, 0x66, 0x80, 0x67, 0xFB, 0xF3, 0xF9, 0x6A, 0x80, 0x6B, 0x80, 0x6C, 0x80, 0x65, 0xFF],
        dsl="""
          [SCRIPT74]
          TILES 65,23,22,26,20,29,30,64,21,31,32,25
          FLIP X
          INC Y
          INC X
          PUSH X
          PUSH Y
          DRAWTILE T0
          DEC Y
          DRAWTILE T1
          DEC Y
          DRAWTILE T2
          DEC Y
          DRAWTILE T3
          DEC Y
          POP Y
          POP X
          DEC X
          INC Y
          WHILE PARAM1
            PUSH X
            PUSH Y
            DRAWTILE T0
            DEC Y
            DRAWTILE T1
            DEC Y
            DRAWTILE 67
            DEC Y
            DRAWTILE T5
            DEC Y
            DRAWTILE T6
            DEC Y
            POP Y
            POP X
            DEC X
            INC Y
          ENDWHILE
          PUSH X
          PUSH Y
          DRAWTILE T7
          DEC Y
          DRAWTILE T8
          DEC Y
          DRAWTILE 24
          DEC Y
          DRAWTILE T5
          DEC Y
          DRAWTILE T6
          DEC Y
          POP Y
          POP X
          DEC X
          DRAWTILE T9
          DEC Y
          DRAWTILE T10
          DEC Y
          DRAWTILE T11
          DEC Y
          DRAWTILE T4
          DEC Y
          END
          """
    ),
    0x4B: BlockDef(
        block_id=0x4B,
        description="plates",
        address=0x1DD8,
        tile_ptr=0x1C5C,
        tile_data=[0xE3, 0x9C, 0x0D, 0x0C, 0x0B, 0x31, 0x0F, 0x0E, 0x67, 0x48, 0x76, 0x08],
        bytecode=[0xEA, 0xDF, 0x1D],
        dsl="""
          [SCRIPT75]
          TILES 227,156,13,12,11,49,15,14,103,72,118,8
          JMP SCRIPT87, 0
          """
    ),
    0x4C: BlockDef(
        block_id=0x4C,
        description="bottles with handles",
        address=0x1DFC,
        tile_ptr=0x1C61,
        tile_data=[0x31, 0x0F, 0x0E, 0x67, 0x48, 0x76, 0x08, 0x75, 0x66, 0x68, 0x65, 0x3B],
        bytecode=[0xEA, 0x75, 0x19],
        dsl="""
          [SCRIPT76]
          TILES 49,15,14,103,72,118,8,117,102,104,101,59
          JMP SCRIPT1, 0
          """
    ),
    0x4D: BlockDef(
        block_id=0x4D,
        description="cauldron",
        address=0x1E06,
        tile_ptr=0x1C5E,
        tile_data=[0x0D, 0x0C, 0x0B, 0x31, 0x0F, 0x0E, 0x67, 0x48, 0x76, 0x08, 0x75, 0x66],
        bytecode=[0xF9, 0x61, 0x80, 0x62, 0x80, 0x63, 0xFF],
        dsl="""
          [SCRIPT77]
          TILES 13,12,11,49,15,14,103,72,118,8,117,102
          DRAWTILE T0
          DEC Y
          DRAWTILE T1
          DEC Y
          DRAWTILE T2
          DEC Y
          END
          """
    ),
    0x4E: BlockDef(
        block_id=0x4E,
        description="flat corner delimited with black line and yellow floor",
        address=0x1BB4,
        tile_ptr=0x1B88,
        tile_data=[0xDB, 0xD4, 0xDA, 0xD8, 0xDC, 0xD7, 0xDD, 0xE2, 0xD9, 0x2E, 0x1B, 0xEA],
        bytecode=[0xEA, 0xCF, 0x1B],
        dsl="""
          [SCRIPT78]
          TILES 219,212,218,216,220,215,221,226,217,46,27,234
          JMP SCRIPT113, 0
          """
    ),
    0x4F: BlockDef(
        block_id=0x4F,
        description="solid block of thin red and black brick, with blue tiles on top, parallel to the y axis",
        address=0x17EF,
        tile_ptr=0x1B49,
        tile_data=[0x05, 0x4F, 0x59, 0x28, 0x29, 0x2B, 0x2D, 0x0A, 0x09, 0x05, 0x59, 0x4F],
        bytecode=[0xEA, 0x05, 0x18],
        dsl="""
          [SCRIPT79]
          TILES 5,79,89,40,41,43,45,10,9,5,89,79
          JMP SCRIPT57, 0
          """
    ),
    0x50: BlockDef(
        block_id=0x50,
        description="solid block of thin red and black brick, with blue top, parallel to the y axis",
        address=0x17F4,
        tile_ptr=0x1B6D,
        tile_data=[0xFF, 0x45, 0x44, 0x28, 0x29, 0x2B, 0x2D, 0x0A, 0x09, 0xFF, 0x44, 0x45],
        bytecode=[0xEA, 0x05, 0x18],
        dsl="""
          [SCRIPT80]
          TILES 255,69,68,40,41,43,45,10,9,255,68,69
          JMP SCRIPT57, 0
          """
    ),
    0x51: BlockDef(
        block_id=0x51,
        description="solid block of thin red and black brick, with blue tiles on top, parallel to the x axis",
        address=0x1897,
        tile_ptr=0x1B52,
        tile_data=[0x05, 0x59, 0x4F, 0x2B, 0x2D, 0x28, 0x29, 0x09, 0x0A, 0x87, 0x88, 0xCF],
        bytecode=[0xEA, 0xAD, 0x18],
        dsl="""
          [SCRIPT81]
          TILES 5,89,79,43,45,40,41,9,10,135,136,207
          JMP SCRIPT56, 0
          """
    ),
    0x52: BlockDef(
        block_id=0x52,
        description="solid block of thin red and black brick, with blue top, parallel to the x axis",
        address=0x189C,
        tile_ptr=0x1B76,
        tile_data=[0xFF, 0x44, 0x45, 0x2B, 0x2D, 0x28, 0x29, 0x09, 0x0A, 0xDB, 0xDA, 0xD4],
        bytecode=[0xEA, 0xAD, 0x18],
        dsl="""
          [SCRIPT82]
          TILES 255,68,69,43,45,40,41,9,10,219,218,212
          JMP SCRIPT56, 0
          """
    ),
    0x53: BlockDef(
        block_id=0x53,
        description="solid block of thin red and black brick, with blue tiles on top and stair-stepped, parallel to the x axis",
        address=0x17BB,
        tile_ptr=0x1B49,
        tile_data=[0x05, 0x4F, 0x59, 0x28, 0x29, 0x2B, 0x2D, 0x0A, 0x09, 0x05, 0x59, 0x4F],
        bytecode=[0xEC, 0xEF, 0x17, 0xF7, 0x70, 0x02, 0x84, 0x70, 0xF7, 0x71, 0x01, 0x84, 0x71, 0xF2, 0x6D, 0x01, 0x84, 0xF9, 0x61, 0xF1, 0x01, 0x84, 0x6D, 0xF2, 0x6D, 0x6D, 0x02, 0xEC, 0x91, 0x18, 0xF5, 0xF6, 0xF7, 0x6E, 0x6D, 0xF7, 0x6D, 0x00, 0xEC, 0x28, 0x1B, 0xFF],
        dsl="""
          [SCRIPT83]
          TILES 5,79,89,40,41,43,45,10,9,5,89,79
          CALL SCRIPT79
          LD DEPTHX, -( DEPTHX ) + 2
          LD DEPTHY, -( DEPTHY ) + 1
          ADD Y, -( PARAM1 + 1 )
          DRAWTILE T0
          DEC Y
          ADD X, -( PARAM1 ) + 1
          ADD Y, PARAM1 + PARAM1 + 2
          CALL SCRIPT86, 34
          INC X
          INC Y
          LD PARAM2, PARAM1
          LD PARAM1, 0
          CALL SCRIPT12
          END
          """
    ),
    0x54: BlockDef(
        block_id=0x54,
        description="solid block of thin red and black brick, with blue top and stair-stepped, parallel to the x axis",
        address=0x17E7,
        tile_ptr=0x1B6D,
        tile_data=[0xFF, 0x45, 0x44, 0x28, 0x29, 0x2B, 0x2D, 0x0A, 0x09, 0xFF, 0x44, 0x45],
        bytecode=[0xEC, 0xF4, 0x17, 0xEA, 0xC0, 0x17],
        dsl="""
          [SCRIPT84]
          TILES 255,69,68,40,41,43,45,10,9,255,68,69
          CALL SCRIPT80
          JMP SCRIPT83, 3
          """
    ),
    0x55: BlockDef(
        block_id=0x55,
        description="solid block of thin red and black brick, with blue tiles on top and stair-stepped, parallel to the y axis",
        address=0x1841,
        tile_ptr=0x1B52,
        tile_data=[0x05, 0x59, 0x4F, 0x2B, 0x2D, 0x28, 0x29, 0x09, 0x0A, 0x87, 0x88, 0xCF],
        bytecode=[0xEC, 0x97, 0x18, 0xF7, 0x71, 0x02, 0x84, 0x71, 0xF7, 0x70, 0x01, 0x84, 0x70, 0xF2, 0x01, 0x6D, 0x84, 0xF9, 0x61, 0xF1, 0x6D, 0x84, 0x01, 0xF2, 0x6D, 0x6D, 0x02, 0xEC, 0x75, 0x18, 0xF3, 0xF6, 0xF7, 0x6E, 0x6D, 0xF7, 0x6D, 0x00, 0xEC, 0xEF, 0x1A, 0xFF],
        dsl="""
          [SCRIPT85]
          TILES 5,89,79,43,45,40,41,9,10,135,136,207
          CALL SCRIPT81
          LD DEPTHY, -( DEPTHY ) + 2
          LD DEPTHX, -( DEPTHX ) + 1
          ADD Y, -( 1 + PARAM1 )
          DRAWTILE T0
          DEC Y
          ADD X, -( 1 ) + PARAM1
          ADD Y, PARAM1 + PARAM1 + 2
          CALL SCRIPT86, 6
          DEC X
          INC Y
          LD PARAM2, PARAM1
          LD PARAM1, 0
          CALL SCRIPT11
          END
          """
    ),
    0x56: BlockDef(
        block_id=0x56,
        description="solid block of thin red and black brick, with blue top and stair-stepped, parallel to the y axis",
        address=0x186D,
        tile_ptr=0x1B76,
        tile_data=[0xFF, 0x44, 0x45, 0x2B, 0x2D, 0x28, 0x29, 0x09, 0x0A, 0xDB, 0xDA, 0xD4],
        bytecode=[0xEC, 0x9C, 0x18, 0xEA, 0x46, 0x18],
        dsl="""
          [SCRIPT86]
          TILES 255,68,69,43,45,40,41,9,10,219,218,212
          CALL SCRIPT82
          JMP SCRIPT85, 3
          """
    ),
    0x57: BlockDef(
        block_id=0x57,
        description="human skulls",
        address=0x1DDD,
        tile_ptr=0x1C5D,
        tile_data=[0x9C, 0x0D, 0x0C, 0x0B, 0x31, 0x0F, 0x0E, 0x67, 0x48, 0x76, 0x08, 0x75],
        bytecode=[0xFC, 0xF5, 0xF4, 0xE4, 0xEF, 0x1D, 0xFB, 0xE9, 0xF7, 0x6D, 0x6E, 0x01, 0xE4, 0xEF, 0x1D, 0xFF],
        dsl="""
          [SCRIPT87]
          TILES 156,13,12,11,49,15,14,103,72,118,8,117
          PUSH X
          PUSH Y
          INC X
          DEC Y
          FLIP X
          CALL SCRIPT87, 16
          POP Y
          POP X
          FLIP X
          LD PARAM1, PARAM2 + 1
          FLIP X
          CALL SCRIPT87, 16
          END
          """
    ),
    0x58: BlockDef(
        block_id=0x58,
        description="skeleton remains???",
        address=0x1B91,
        tile_ptr=0x1B2E,
        tile_data=[0xEB, 0xEB, 0xEB, 0x08, 0x76, 0x75, 0x28, 0x29, 0x2B, 0x2D, 0x0A, 0x09],
        bytecode=[0xEA, 0xCF, 0x1B],
        dsl="""
          [SCRIPT88]
          TILES 235,235,235,8,118,117,40,41,43,45,10,9
          JMP SCRIPT113, 0
          """
    ),
    0x59: BlockDef(
        block_id=0x59,
        description="monster face with horns",
        address=0x1914,
        tile_ptr=0x1698,
        tile_data=[0xFD, 0xFC, 0x5F, 0xFE, 0x1B, 0x3A, 0x3A, 0x69, 0x39, 0x39, 0x28, 0x09],
        bytecode=[0xEA, 0x20, 0x19],
        dsl="""
          [SCRIPT89]
          TILES 253,252,95,254,27,58,58,105,57,57,40,9
          JMP SCRIPT42, 0
          """
    ),
    0x5A: BlockDef(
        block_id=0x5A,
        description="support with cross",
        address=0x1919,
        tile_ptr=0x169A,
        tile_data=[0x5F, 0xFE, 0x1B, 0x3A, 0x3A, 0x69, 0x39, 0x39, 0x28, 0x09, 0x29, 0x00],
        bytecode=[0xEA, 0x20, 0x19],
        dsl="""
          [SCRIPT90]
          TILES 95,254,27,58,58,105,57,57,40,9,41
          JMP SCRIPT42, 0
          """
    ),
    0x5B: BlockDef(
        block_id=0x5B,
        description="large cross",
        address=0x1E01,
        tile_ptr=0x1695,
        tile_data=[0xE0, 0xDF, 0xDE, 0xFD, 0xFC, 0x5F, 0xFE, 0x1B, 0x3A, 0x3A, 0x69, 0x39],
        bytecode=[0xEA, 0x08, 0x1E],
        dsl="""
          [SCRIPT91]
          TILES 224,223,222,253,252,95,254,27,58,58,105,57
          JMP SCRIPT77, 0
          """
    ),
    0x5C: BlockDef(
        block_id=0x5C,
        description="library books parallel to the x axis",
        address=0x1F69,
        tile_ptr=0x169F,
        tile_data=[0x69, 0x39, 0x39, 0x28, 0x09, 0x29, 0x00, 0x2B, 0x0A, 0x2D, 0x00, 0x23],
        bytecode=[0xEA, 0xC6, 0x19],
        dsl="""
          [SCRIPT92]
          TILES 105,57,57,40,9,41,0,43,10,45,0,35
          JMP SCRIPT108, 0
          """
    ),
    0x5D: BlockDef(
        block_id=0x5D,
        description="library books parallel to the y axis",
        address=0x1ED9,
        tile_ptr=0x169C,
        tile_data=[0x1B, 0x3A, 0x3A, 0x69, 0x39, 0x39, 0x28, 0x09, 0x29, 0x00, 0x2B, 0x0A],
        bytecode=[0xEA, 0x75, 0x19],
        dsl="""
          [SCRIPT93]
          TILES 27,58,58,105,57,57,40,9,41,0,43,10
          JMP SCRIPT1, 0
          """
    ),
    0x5E: BlockDef(
        block_id=0x5E,
        description="top of a wall with small slightly rounded and black window parallel to the y axis???",
        address=0x195F,
        tile_ptr=0x16CE,
        tile_data=[0x23, 0x21, 0x1B, 0x3A, 0x26, 0x24, 0x69, 0x39, 0x7F, 0x7E, 0x7D, 0x00],
        bytecode=[0xEA, 0x90, 0x19],
        dsl="""
          [SCRIPT94]
          TILES 35,33,27,58,38,36,105,57,127,126,125
          JMP SCRIPT109, 0
          """
    ),
    0x5F: BlockDef(
        block_id=0x5F,
        description="top of a wall with small slightly rounded and red window parallel to the x axis???",
        address=0x1964,
        tile_ptr=0x16D2,
        tile_data=[0x26, 0x24, 0x69, 0x39, 0x7F, 0x7E, 0x7D, 0x00, 0x58, 0x57, 0x56, 0x00],
        bytecode=[0xEA, 0xA9, 0x19],
        dsl="""
          [SCRIPT95]
          TILES 38,36,105,57,127,126,125,0,88,87,86
          JMP SCRIPT110, 0
          """
    ),
}


SUBROUTINE_DEFINITIONS = {
    96: SubroutineDef(
        script_id=96,
        description="Common floor rendering setup",
        address=0x18E3,
        bytecode=[0xEC, 0x55, 0x19, 0xFF],
        dsl="""
          [SCRIPT96]
          CALL SCRIPT8
          END
          """
    ),
    97: SubroutineDef(
        script_id=97,
        description="Common floor rendering loop",
        address=0x18E7,
        bytecode=[0xC2, 0x16, 0xF7, 0x6D, 0x00, 0xEA, 0xCA, 0x19],
        dsl="""
          [SCRIPT97]
          ; Unknown opcode $C2 at $18E7
          """
    ),
    99: SubroutineDef(
        script_id=99,
        description="Arch column base rendering",
        address=0x1CA6,
        bytecode=[0x30, 0x1C, 0xF7, 0x6D, 0x01, 0xEC, 0xDE, 0x1E, 0xFF],
        dsl="""
          [SCRIPT99]
          ; Unknown opcode $30 at $1CA6
          """
    ),
    100: SubroutineDef(
        script_id=100,
        description="Arch column middle rendering",
        address=0x1CAF,
        bytecode=[0x78, 0x1C, 0xF7, 0x6D, 0x00, 0xEC, 0x5F, 0x1F, 0xFF],
        dsl="""
          [SCRIPT100]
          ; Unknown opcode $78 at $1CAF
          """
    ),
    101: SubroutineDef(
        script_id=101,
        description="Arch column top rendering",
        address=0x1CB4,
        bytecode=[0xEC, 0x5F, 0x1F, 0xFF],
        dsl="""
          [SCRIPT101]
          CALL SCRIPT21
          END
          """
    ),
    102: SubroutineDef(
        script_id=102,
        description="Arch column finish",
        address=0x1CBD,
        bytecode=[0x70, 0xF7, 0x71, 0x01, 0x71, 0xF0, 0xFE, 0xF7, 0x71, 0x08, 0x84, 0x71, 0xF9, 0x67, 0x80, 0x82, 0xFB, 0x80, 0x82, 0xC8, 0x80, 0x82, 0xC5, 0x80, 0x82, 0xC6, 0x80, 0x82, 0xC7, 0xF5, 0xF6, 0xF6, 0xF6, 0xF9, 0x61, 0x80, 0x62, 0x80, 0x63, 0x80, 0x64, 0xF5, 0xF6, 0xF6, 0xF9, 0x65, 0x80, 0x66, 0xF5, 0xF2, 0x04, 0xF9, 0x67, 0x80, 0x68, 0x80, 0x69, 0x80, 0x6A, 0xF5, 0xF2, 0x03, 0xFA, 0xFF],
        dsl="""
          [SCRIPT102]
          ; Unknown opcode $70 at $1CBD
          """
    ),
    106: SubroutineDef(
        script_id=106,
        description="FLIP X then JMP SCRIPT1",
        address=0x198C,
        bytecode=[0xE9, 0xEA, 0x75, 0x19],
        dsl="""
          [SCRIPT106]
          FLIP X
          JMP SCRIPT1, 0
          """
    ),
    107: SubroutineDef(
        script_id=107,
        description="Common column/window code",
        address=0x19AD,
        bytecode=[0xF7, 0x71, 0x01, 0x6E, 0x6E, 0x84, 0x71, 0xEF, 0xFD, 0xFC, 0xF9, 0x61, 0xFE, 0xF9, 0x62, 0x80, 0x64, 0xFA, 0xF9, 0x63, 0xFB, 0xF5, 0xF4, 0xFA, 0xFF],
        dsl="""
          [SCRIPT107]
          LD DEPTHY, 1 + PARAM2 + PARAM2 - DEPTHY
          INC PARAM2
          WHILE PARAM2
            PUSH X
            PUSH Y
            DRAWTILE T0
            DEC Y
            WHILE PARAM1
              DRAWTILE T1
              DEC Y
              DRAWTILE T3
              DEC Y
            ENDWHILE
            DRAWTILE T2
            DEC Y
            POP Y
            POP X
            INC X
            DEC Y
          ENDWHILE
          END
          """
    ),
    108: SubroutineDef(
        script_id=108,
        description="FLIP X then JMP SCRIPT107",
        address=0x19C6,
        bytecode=[0xE9, 0xEA, 0xAD, 0x19],
        dsl="""
          [SCRIPT108]
          FLIP X
          JMP SCRIPT107, 0
          """
    ),
    109: SubroutineDef(
        script_id=109,
        description="Column generation code",
        address=0x1990,
        bytecode=[0xF7, 0x71, 0x01, 0x6E, 0x6E, 0x84, 0x71, 0xEF, 0xFD, 0xFC, 0xF9, 0x61, 0xFE, 0xF9, 0x62, 0xFA, 0xF9, 0x63, 0x80, 0x64, 0xFB, 0xF5, 0xF4, 0xFA, 0xFF],
        dsl="""
          [SCRIPT109]
          LD DEPTHY, 1 + PARAM2 + PARAM2 - DEPTHY
          INC PARAM2
          WHILE PARAM2
            PUSH X
            PUSH Y
            DRAWTILE T0
            DEC Y
            WHILE PARAM1
              DRAWTILE T1
              DEC Y
            ENDWHILE
            DRAWTILE T2
            DEC Y
            DRAWTILE T3
            DEC Y
            POP Y
            POP X
            INC X
            DEC Y
          ENDWHILE
          END
          """
    ),
    110: SubroutineDef(
        script_id=110,
        description="FLIP X then JMP SCRIPT109",
        address=0x19A9,
        bytecode=[0xE9, 0xEA, 0x90, 0x19],
        dsl="""
          [SCRIPT110]
          FLIP X
          JMP SCRIPT109, 0
          """
    ),
    111: SubroutineDef(
        script_id=111,
        description="LD PARAM2 manipulation",
        address=0x19CA,
        bytecode=[0xF7, 0x6E, 0x6E, 0x6D, 0xF7, 0x6D, 0x01, 0xEA, 0x75, 0x19],
        dsl="""
          [SCRIPT111]
          LD PARAM2, PARAM2 + PARAM1
          LD PARAM1, 1
          JMP SCRIPT1, 0
          """
    ),
    112: SubroutineDef(
        script_id=112,
        description="FLIP X then JMP SCRIPT111",
        address=0x19D4,
        bytecode=[0xE9, 0xEA, 0xCA, 0x19],
        dsl="""
          [SCRIPT112]
          FLIP X
          JMP SCRIPT111, 0
          """
    ),
    113: SubroutineDef(
        script_id=113,
        description="Floor tile rendering code",
        address=0x1BCF,
        bytecode=[0xF7, 0x70, 0x02, 0x6E, 0x6E, 0x84, 0x70, 0xF7, 0x71, 0x03, 0x6D, 0x6D, 0x84, 0x71, 0xF0, 0xEF, 0xFD, 0xFC, 0xFE, 0xF9, 0x61, 0x80, 0x61, 0xF5, 0xF6, 0xFA, 0xF9, 0x61, 0x80, 0x62, 0xFB, 0xF4, 0xF3, 0xFA, 0xF5, 0xF4, 0xFE, 0xF9, 0x63, 0xF5, 0xFA, 0xFF],
        dsl="""
          [SCRIPT113]
          LD DEPTHX, 2 + PARAM2 + PARAM2 - DEPTHX
          LD DEPTHY, 3 + PARAM1 + PARAM1 - DEPTHY
          INC PARAM1
          INC PARAM2
          WHILE PARAM2
            PUSH X
            PUSH Y
            WHILE PARAM1
              DRAWTILE T0
              DEC Y
              DRAWTILE T0
              DEC Y
              INC X
              INC Y
            ENDWHILE
            DRAWTILE T0
            DEC Y
            DRAWTILE T1
            DEC Y
            POP Y
            POP X
            DEC Y
            DEC X
          ENDWHILE
          INC X
          DEC Y
          WHILE PARAM1
            DRAWTILE T2
            DEC Y
            INC X
          ENDWHILE
          END
          """
    ),
}