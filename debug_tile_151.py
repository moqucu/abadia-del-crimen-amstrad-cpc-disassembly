from PIL import Image
import os

tile_path = 'src/abadia/resources/tiles/palette_day/tile_151_0x97.png'

if not os.path.exists(tile_path):
    print(f"File not found: {tile_path}")
else:
    img = Image.open(tile_path)
    print(f"Format: {img.format}")
    print(f"Mode: {img.mode}")
    print(f"Size: {img.size}")
    if img.mode == 'P':
        print(f"Palette: {img.getpalette()[:12] if img.getpalette() else 'None'}")
        print(f"Transparency: {img.info.get('transparency')}")
    
    print("Extrema:", img.getextrema())
    
    # Sample pixels
    pixels = list(img.getdata())
    print(f"Pixel count: {len(pixels)}")
    unique_pixels = set(pixels)
    print(f"Unique pixel values: {unique_pixels}")
    
    # Convert to RGBA to see what it looks like
    img_rgba = img.convert('RGBA')
    r, g, b, a = img_rgba.split()
    print("Alpha extrema:", a.getextrema())
