from PIL import Image, ImageDraw, ImageFont

def create_palette_image():
    # Amstrad CPC 6128 Palette
    # Format: "Name": (R, G, B)
    palette = {
        "Black": (4, 4, 4),
        "Grey": (128, 128, 128),
        "White": (255, 255, 255),
        "Dark Red": (128, 0, 0),
        "Red": (255, 0, 0),
        "Bright Red": (255, 128, 128),
        "Orange": (255, 127, 0),
        "Yellow": (255, 255, 128),
        "Bright Yellow": (255, 255, 0),
        "Dark Yellow": (128, 128, 0),
        "Dark Green": (0, 128, 0),
        "Green": (1, 255, 0),
        "Bright Green": (128, 255, 0),
        "Sea Green": (128, 255, 128),
        "Cyan": (1, 255, 128),
        "Dark Cyan": (0, 128, 128),
        "Bright Cyan": (1, 255, 255),
        "Sky Blue": (128, 255, 255),
        "Dark Blue": (0, 128, 255),
        "Blue": (0, 0, 255),
        "Darker Blue": (0, 0, 127),
        "Purple": (127, 0, 255),
        "Bright Purple": (128, 128, 255),
        "Magenta": (255, 128, 255),
        "Bright Magenta": (255, 0, 255),
        "Dark Magenta": (255, 0, 128),
        "Dark Purple": (128, 0, 128)
    }

    # Image settings
    swatch_width = 100
    swatch_height = 50
    padding = 10
    text_width = 150
    row_height = swatch_height + padding
    img_width = swatch_width + text_width + (padding * 3)
    img_height = (row_height * len(palette)) + padding

    # Create image
    img = Image.new('RGB', (img_width, img_height), color=(240, 240, 240))
    draw = ImageDraw.Draw(img)

    # Load a font (try default, if fails, use default bitmap font)
    try:
        # Try to load a generic TTF if available, otherwise default
        font = ImageFont.truetype("Arial.ttf", 16)
    except IOError:
        font = ImageFont.load_default()

    y = padding
    for name, color in palette.items():
        # Draw Swatch
        draw.rectangle(
            [(padding, y), (padding + swatch_width, y + swatch_height)],
            fill=color,
            outline=(0, 0, 0)
        )
        
        # Draw Text
        # Calculate text position to be vertically centered relative to swatch
        text_x = padding + swatch_width + padding
        text_y = y + (swatch_height // 2) - 8 # Approx adjustment for default font
        
        draw.text((text_x, text_y), f"{name} {color}", fill=(0, 0, 0), font=font)
        
        y += row_height

    output_filename = "amstrad_palette.png"
    img.save(output_filename)
    print(f"Palette image saved to {output_filename}")
    
    # Try to open the image automatically (works on macOS 'open', Linux 'xdg-open', Windows 'start')
    import subprocess
    import platform
    
    current_os = platform.system()
    try:
        if current_os == 'Darwin':  # macOS
            subprocess.run(['open', output_filename])
        elif current_os == 'Windows':
            subprocess.run(['start', output_filename], shell=True)
        elif current_os == 'Linux':
            subprocess.run(['xdg-open', output_filename])
    except Exception as e:
        print(f"Could not automatically open image: {e}")

if __name__ == "__main__":
    create_palette_image()
