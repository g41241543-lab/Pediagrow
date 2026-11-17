import os
from PIL import Image
from collections import deque

brain_dir = r"C:\Users\zsptr\.gemini\antigravity\brain\706d435d-389a-4e19-ac7e-575683f0180a"
out_dir = r"C:\GIT\Pediagrow\scratch\new_icons"
os.makedirs(out_dir, exist_ok=True)

def flood_fill_transparent(input_path, output_path, bg_threshold=240):
    img = Image.open(input_path).convert("RGBA")
    w, h = img.size
    pixels = img.load()
    
    # Visited set
    visited = set()
    queue = deque()
    
    # Seed queue with borders
    for x in range(w):
        queue.append((x, 0))
        queue.append((x, h - 1))
    for y in range(h):
        queue.append((0, y))
        queue.append((w - 1, y))
        
    def is_bg(x, y):
        r, g, b, a = pixels[x, y]
        # Light gray/white shadow or pure white
        # If very bright and neutral
        diff = max(abs(r - g), abs(g - b), abs(r - b))
        if r >= bg_threshold and g >= bg_threshold and b >= bg_threshold and diff <= 12:
            return True
        # Also remove soft contact shadow if desired, or keep it
        # The subtle oval shadow at the bottom is around (215, 222, 230)
        # If it's pure background, let's treat r > 235 as bg
        return False

    while queue:
        x, y = queue.popleft()
        if (x, y) in visited:
            continue
        visited.add((x, y))
        
        if is_bg(x, y):
            pixels[x, y] = (0, 0, 0, 0)
            for nx, ny in [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]:
                if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visited:
                    queue.append((nx, ny))

    # Also crop transparent bounding box and pad to square
    bbox = img.getbbox()
    if bbox:
        cropped = img.crop(bbox)
        # Pad to square with 10% margin
        max_dim = max(cropped.width, cropped.height)
        pad = int(max_dim * 0.12)
        total_size = max_dim + (pad * 2)
        new_img = Image.new("RGBA", (total_size, total_size), (0, 0, 0, 0))
        offset_x = (total_size - cropped.width) // 2
        offset_y = (total_size - cropped.height) // 2
        new_img.paste(cropped, (offset_x, offset_y))
        new_img = new_img.resize((128, 128), Image.Resampling.LANCZOS)
        new_img.save(output_path, "PNG")
    else:
        img.save(output_path, "PNG")
        
    print(f"Saved: {output_path}")

flood_fill_transparent(
    os.path.join(brain_dir, "grafik_pertumbuhan_new_1794755714940.jpg"),
    os.path.join(out_dir, "grafik_pertumbuhan_new.png")
)

flood_fill_transparent(
    os.path.join(brain_dir, "resep_mpasi_new_1794755725992.jpg"),
    os.path.join(out_dir, "resep_mpasi_new.png")
)

