from PIL import Image, ImageDraw, ImageFilter

im = Image.open(r"C:\GIT\Pediagrow\scratch\new_icons\grafik_pertumbuhan_new.png")
# The board in grafik_pertumbuhan_new was rotated by about -26 degrees
# Let's rotate by +25 degrees
rot = im.rotate(25, resample=Image.Resampling.BICUBIC, expand=True)

# Separate the clipboard body from the skewed ground shadow
# The shadow is at the bottom right/center and is faint grey (alpha < 180, rgb ~ (220, 220, 220))
# Let's remove low-alpha pixels below y = 0.8 * height, then add a fresh horizontal shadow!
w, h = rot.size
pixels = rot.load()
for y in range(int(h * 0.75), h):
    for x in range(w):
        r, g, b, a = pixels[x, y]
        # If it's a soft shadow pixel (grey and semi-transparent)
        if a > 0 and a < 190 and abs(r - g) < 20 and abs(g - b) < 20 and r > 160:
            pixels[x, y] = (0, 0, 0, 0)

# Now crop tightly
bbox = rot.getbbox()
cropped = rot.crop(bbox)
cw, ch = cropped.size
max_side = max(cw, ch)

# Create 128x128 with horizontal soft shadow
target_size = 128
scale = 114 / max_side
nw = max(1, int(round(cw * scale)))
nh = max(1, int(round(ch * scale)))
r_clip = cropped.resize((nw, nh), Image.Resampling.LANCZOS)

out = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))

# Add soft horizontal contact shadow
shadow = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
s_draw = ImageDraw.Draw(shadow)
px = (target_size - nw) // 2
py = (target_size - nh) // 2
s_draw.ellipse([px + 10, py + nh - 8, px + nw - 10, py + nh + 6], fill=(210, 222, 235, 180))
shadow = shadow.filter(ImageFilter.GaussianBlur(radius=3))
out.alpha_composite(shadow)

# Paste clipboard
out.alpha_composite(r_clip, (px, py))
out.save(r"C:\GIT\Pediagrow\scratch\rot_grafik_clean.png")
print("Clean rot grafik saved!")

