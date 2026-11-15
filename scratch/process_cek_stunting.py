from PIL import Image
from collections import deque
import os

img_path = r"C:\Users\zsptr\.gemini\antigravity\brain\706d435d-389a-4e19-ac7e-575683f0180a\cek_stunting_icon_v1_1794755707985.jpg"
out_path = r"C:\GIT\Pediagrow\scratch\new_icons\cek_stunting_new.png"

img = Image.open(img_path).convert("RGBA")
w, h = img.size
pixels = img.load()

# Floodfill from borders
visited = set()
queue = deque()

for x in range(w):
    queue.append((x, 0))
    queue.append((x, h - 1))
for y in range(h):
    queue.append((0, y))
    queue.append((w - 1, y))

def is_checker(r, g, b):
    # Gray or white square
    diff = max(abs(r - g), abs(g - b), abs(r - b))
    # In JPEG compression, neutral grays can have slight color noise up to 8
    if diff <= 10 and min(r, g, b) >= 195:
        return True
    return False

while queue:
    x, y = queue.popleft()
    if (x, y) in visited:
        continue
    visited.add((x, y))
    
    r, g, b, a = pixels[x, y]
    if is_checker(r, g, b):
        pixels[x, y] = (0, 0, 0, 0)
        for nx, ny in [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]:
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visited:
                queue.append((nx, ny))

bbox = img.getbbox()
if bbox:
    cropped = img.crop(bbox)
    max_dim = max(cropped.width, cropped.height)
    pad = int(max_dim * 0.10)
    total_size = max_dim + (pad * 2)
    new_img = Image.new("RGBA", (total_size, total_size), (0, 0, 0, 0))
    offset_x = (total_size - cropped.width) // 2
    offset_y = (total_size - cropped.height) // 2
    new_img.paste(cropped, (offset_x, offset_y))
    new_img = new_img.resize((128, 128), Image.Resampling.LANCZOS)
    new_img.save(out_path, "PNG")
    print("Saved:", out_path)

