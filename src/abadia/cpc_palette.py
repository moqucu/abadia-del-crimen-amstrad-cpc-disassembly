from PIL import Image, ImageDraw, ImageFont
import os

class CpcPalette:
    """
    Handles Amstrad CPC Gate Array hardware colors and game-specific palettes.
    
    The Amstrad CPC Gate Array uses a palette of 27 unique colors (accessed via 32 indices).
    References: CPCWiki, Grimware, CPC-Power.
    """

    # Official Hardware Color Mapping (Color Name -> RGB)
    # Note: Index 20 (0x14) is Bright Cyan. Index 4 (0x04) is Magenta.
    HARDWARE_COLORS = {
        'Black': (0, 0, 0),              # 0x00
        'Blue': (0, 0, 128),              # 0x01
        'Bright Blue': (0, 0, 255),       # 0x02
        'Red': (128, 0, 0),               # 0x03
        'Magenta': (128, 0, 128),         # 0x04
        'Mauve': (128, 0, 255),           # 0x05
        'Bright Red': (255, 0, 0),        # 0x06
        'Purple': (255, 0, 128),          # 0x07
        'Bright Magenta': (255, 0, 255),  # 0x08
        'Green': (0, 128, 0),             # 0x09
        'Cyan': (0, 128, 128),            # 0x0A
        'Sky Blue': (0, 128, 255),        # 0x0B
        'Yellow': (128, 128, 0),          # 0x0C
        'White': (128, 128, 128),         # 0x0D (Grey)
        'Pastel Blue': (128, 128, 255),   # 0x0E
        'Orange': (255, 128, 0),          # 0x0F
        'Pink': (255, 128, 128),          # 0x10
        'Pastel Magenta': (255, 128, 255),# 0x11
        'Bright Green': (0, 255, 0),      # 0x12
        'Sea Green': (0, 255, 128),       # 0x13
        'Bright Cyan': (0, 255, 255),     # 0x14
        'Lime': (128, 255, 0),            # 0x15
        'Pastel Green': (128, 255, 128),  # 0x16
        'Pastel Cyan': (128, 255, 255),   # 0x17
        'Bright Yellow': (255, 255, 0),   # 0x18
        'Pastel Yellow': (255, 255, 128), # 0x19
        'Bright White': (255, 255, 255),  # 0x1A
    }

    # Hex code to color name mapping for backward compatibility
    HEX_TO_COLOR = {
        0x00: 'Black',
        0x01: 'Blue',
        0x02: 'Bright Blue',
        0x03: 'Red',
        0x04: 'Magenta',
        0x05: 'Mauve',
        0x06: 'Bright Red',
        0x07: 'Purple',
        0x08: 'Bright Magenta',
        0x09: 'Green',
        0x0A: 'Cyan',
        0x0B: 'Sky Blue',
        0x0C: 'Yellow',
        0x0D: 'White',
        0x0E: 'Pastel Blue',
        0x0F: 'Orange',
        0x10: 'Pink',
        0x11: 'Pastel Magenta',
        0x12: 'Bright Green',
        0x13: 'Sea Green',
        0x14: 'Bright Cyan',
        0x15: 'Lime',
        0x16: 'Pastel Green',
        0x17: 'Pastel Cyan',
        0x18: 'Bright Yellow',
        0x19: 'Pastel Yellow',
        0x1A: 'Bright White',
    }


    # Corrected Visual Palettes
    # While the raw hex codes in the binary (at 0x3F26) provide a hint, strictly mapping them
    # to standard hardware tables results in colors that disagree with actual gameplay screenshots.
    # To ensure the assets are usable, we define a "Visual" palette that matches the
    # authentic look of the game running on a CPC 6128.
    VISUAL_PALETTES = {
        'day': {
            3: HARDWARE_COLORS['Black'],   # Pen 3: 0x14
            2: HARDWARE_COLORS['Orange'],        # Pen 2: 0x0F
            1: HARDWARE_COLORS['Pastel Yellow'], # Pen 1: 0x19
            0: HARDWARE_COLORS['Cyan'],          # Pen 0: 0x0A
        },
        'night': {
            3: HARDWARE_COLORS['Black'],   # Pen 3: 0x14
            2: HARDWARE_COLORS['Bright Magenta'],# Pen 2: 0x08
            1: HARDWARE_COLORS['Bright White'],  # Pen 1: 0x1A
            0: HARDWARE_COLORS['Bright Blue'],   # Pen 0: 0x02
        }
    }

    @staticmethod
    def get_rgb(hw_code: int) -> tuple:
        """Returns (R, G, B) for a given CPC hardware code."""
        color_name = CpcPalette.HEX_TO_COLOR.get(hw_code)
        if color_name:
            return CpcPalette.HARDWARE_COLORS.get(color_name, (0, 0, 0))
        return (0, 0, 0)

    @classmethod
    def get_palette_for_rendering(cls, palette_name='day'):
        """
        Get the RGB palette for sprite/tile extraction.
        
        Args:
            palette_name: 'day' or 'night'
        
        Returns:
            List of 4 RGB tuples corresponding to Pen 0, 1, 2, 3
        """
        pal = cls.VISUAL_PALETTES.get(palette_name, cls.VISUAL_PALETTES['day'])
        return [pal[0], pal[1], pal[2], pal[3]]

    @classmethod
    def render_debug_image(cls, output_path="cpc_palette_debug.png"):
        """Generates an image showing all hardware colors and game palettes."""
        
        # Setup
        swatch_size = 40
        padding = 10
        font_size = 12
        
        # Calculate Dimensions
        # Section 1: All 32 Hardware Codes (8x4 grid)
        # Section 2: Visual Game Palettes
        
        width = (swatch_size + padding) * 8 + padding
        height = (swatch_size + padding) * 4 + 200 + (swatch_size + padding) * 2
        
        img = Image.new('RGB', (width, height), (50, 50, 50))
        draw = ImageDraw.Draw(img)
        
        try:
            font = ImageFont.truetype("Arial.ttf", font_size)
        except OSError:
            font = ImageFont.load_default()

        y = padding
        draw.text((padding, y), "CPC Gate Array Hardware Colors (0x00 - 0x1F)", fill=(255,255,255), font=font)
        y += 20

        # Draw Hardware Colors
        for i in range(32):
            row = i // 8
            col = i % 8
            
            x_pos = padding + col * (swatch_size + padding)
            y_pos = y + row * (swatch_size + padding)
            
            color = cls.get_rgb(i)
            draw.rectangle([x_pos, y_pos, x_pos+swatch_size, y_pos+swatch_size], fill=color, outline=(200,200,200))
            draw.text((x_pos+2, y_pos+2), f"{i:02X}", fill=(128,128,128) if sum(color)>300 else (255,255,255), font=font)

        y += (swatch_size + padding) * 4 + 20
        
        # Draw Game Palettes
        draw.text((padding, y), "Game Palettes (Pens 0-3)", fill=(255,255,255), font=font)
        y += 20
        
        for name in ['day', 'night']:
            if name not in cls.VISUAL_PALETTES: continue
            
            draw.text((padding, y), f"Palette: {name.upper()}", fill=(200,200,200), font=font)
            y += 15
            
            x_pos = padding
            draw.text((x_pos, y + 15), "Visual:", fill=(180,180,180), font=font)
            x_pos += 80
            
            vis_colors = cls.VISUAL_PALETTES[name]
            for pen in range(4):
                color = vis_colors[pen]
                draw.rectangle([x_pos, y, x_pos+swatch_size, y+swatch_size], fill=color, outline=(255,255,255))
                draw.text((x_pos, y+swatch_size+2), f"P{pen}", fill=(255,255,255), font=font)
                x_pos += swatch_size + padding
            y += swatch_size + 25
            
            y += 10

        img.save(output_path)
        print(f"Debug image saved to {output_path}")

if __name__ == "__main__":
    import sys
    
    output_path = "docs/amstrad_palette.png"
    if len(sys.argv) > 1:
        output_path = sys.argv[1]
        
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    CpcPalette.render_debug_image(output_path)
