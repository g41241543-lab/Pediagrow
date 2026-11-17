import math
from PIL import Image, ImageDraw, ImageFilter

OUTLINE = (32, 41, 56, 255)       # Slate navy #202938
CYAN_MAIN = (41, 169, 225, 255)   # #29A9E1
CYAN_LIGHT = (186, 230, 253, 255) # Light blue accent
CYAN_DARK = (24, 88, 140, 255)    # 3D shadow blue
RED_CORAL = (239, 68, 68, 255)    # #EF4444
RED_DARK = (185, 28, 28, 255)
YELLOW_STAR = (251, 191, 36, 255) # #FBBF24
GREEN_LIME = (16, 185, 129, 255)  # #10B981
PURPLE_BTN = (129, 140, 248, 255) # #818CF8
WHITE = (255, 255, 255, 255)
OFF_WHITE = (248, 250, 252, 255)
PAPER_LINE = (203, 213, 225, 255) # #CBD5E1

CANVAS_SIZE = 1024

def draw_star(draw, cx, cy, r_out, r_in, fill, outline, stroke_w=24):
    pts = []
    for i in range(10):
        angle = -math.pi / 2 + (i * math.pi / 5)
        r = r_out if i % 2 == 0 else r_in
        pts.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
    draw.polygon(pts, fill=fill)
    draw.line(pts + [pts[0]], fill=outline, width=stroke_w, joint="curve")

def add_shadow(img, box):
    shadow = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.ellipse(box, fill=(210, 222, 235, 180))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=32))
    img.alpha_composite(shadow)

def square_pad_and_resize(img):
    bbox = img.getbbox()
    cropped = img.crop(bbox)
    max_d = max(cropped.width, cropped.height)
    pad = int(max_d * 0.08)
    total = max_d + (pad * 2)
    res = Image.new("RGBA", (total, total), (0, 0, 0, 0))
    res.paste(cropped, ((total - cropped.width)//2, (total - cropped.height)//2))
    return res.resize((128, 128), Image.Resampling.LANCZOS)

# ==========================================
# 1. ARTIKEL KESEHATAN - 3D MEDICAL BOOK / MAGAZINE
# ==========================================
def render_artikel_book():
    img = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    add_shadow(img, [210, 840, 814, 950])
    
    stroke_w = 26
    
    # We create an upright open/thick book, then rotate it slightly for 2.5D
    sub_w, sub_h = 620, 780
    sub = Image.new("RGBA", (sub_w, sub_h), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(sub)
    
    # Book spine/thickness at bottom and left
    # Outer Cover: Vibrant Sky Blue with thick rounded corners
    cr = 46
    # 3D page edge (pages stack)
    sdraw.rounded_rectangle([30, 45, sub_w - 30, sub_h - 15], radius=cr, fill=(225, 235, 245, 255), outline=OUTLINE, width=stroke_w)
    
    # Cover front
    sdraw.rounded_rectangle([30, 20, sub_w - 45, sub_h - 40], radius=cr, fill=CYAN_MAIN, outline=OUTLINE, width=stroke_w)
    
    # Left spine line accent
    sdraw.line([(110, 20), (110, sub_h - 40)], fill=OUTLINE, width=20)
    
    # Inner white paper inset on cover
    sdraw.rounded_rectangle([140, 60, sub_w - 75, sub_h - 80], radius=28, fill=WHITE, outline=OUTLINE, width=22)
    
    # Hanging Red Ribbon Bookmark from top
    ribbon_pts = [(240, 20), (310, 20), (310, 190), (275, 155), (240, 190)]
    sdraw.polygon(ribbon_pts, fill=RED_CORAL)
    sdraw.line(ribbon_pts + [ribbon_pts[0]], fill=OUTLINE, width=18, joint="curve")
    
    # Big Heart with Medical Cross on white page
    hcx, hcy = 360, 280
    
    # Smooth heart shape
    # We can draw smooth heart using 2 overlapping circles and a polygon
    hr = 60
    # Left circle, right circle, bottom triangle
    c1 = (hcx - 45, hcy - 30)
    c2 = (hcx + 45, hcy - 30)
    h_poly = [
        (hcx - 95, hcy - 20),
        (hcx, hcy + 105),
        (hcx + 95, hcy - 20),
        (hcx, hcy - 50)
    ]
    # Draw heart fill
    sdraw.ellipse([c1[0]-hr, c1[1]-hr, c1[0]+hr, c1[1]+hr], fill=RED_CORAL)
    sdraw.ellipse([c2[0]-hr, c2[1]-hr, c2[0]+hr, c2[1]+hr], fill=RED_CORAL)
    sdraw.polygon(h_poly, fill=RED_CORAL)
    
    # Outline of heart
    # Combined outline
    h_out_pts = [
        (hcx, hcy + 105),
        (hcx - 90, hcy),
        (hcx - 95, hcy - 45),
        (hcx - 70, hcy - 85),
        (hcx - 20, hcy - 85),
        (hcx, hcy - 50),
        (hcx + 20, hcy - 85),
        (hcx + 70, hcy - 85),
        (hcx + 95, hcy - 45),
        (hcx + 90, hcy),
    ]
    sdraw.line(h_out_pts + [h_out_pts[0]], fill=OUTLINE, width=stroke_w, joint="curve")
    
    # White Medical Cross in center of heart
    cw, ch = 20, 60
    sdraw.rounded_rectangle([hcx - cw, hcy - ch + 8, hcx + cw, hcy + ch + 8], radius=8, fill=WHITE)
    sdraw.rounded_rectangle([hcx - ch, hcy - cw + 8, hcx + ch, hcy + cw + 8], radius=8, fill=WHITE)
    
    # Article headline bar
    sdraw.rounded_rectangle([175, 435, 435, 465], radius=14, fill=CYAN_MAIN)
    sdraw.rounded_rectangle([455, 435, 515, 465], radius=14, fill=GREEN_LIME)
    
    # Article text lines
    for ly in [505, 555, 605]:
        sdraw.rounded_rectangle([175, ly, sub_w - 105, ly + 20], radius=10, fill=PAPER_LINE)
    sdraw.rounded_rectangle([175, 655, sub_w - 220, 655 + 20], radius=10, fill=PAPER_LINE)
    
    # Rotate slightly
    angle = -10
    sub_rot = sub.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)
    rx = (CANVAS_SIZE - sub_rot.width) // 2
    ry = (CANVAS_SIZE - sub_rot.height) // 2 + 10
    img.alpha_composite(sub_rot, (rx, ry))
    
    # Cheerful sparkle on top right
    draw = ImageDraw.Draw(img)
    spx, spy = 780, 230
    draw.ellipse([spx - 16, spy - 16, spx + 16, spy + 16], fill=CYAN_MAIN)
    draw.line([(spx - 45, spy), (spx + 45, spy)], fill=CYAN_MAIN, width=12)
    draw.line([(spx, spy - 45), (spx, spy + 45)], fill=CYAN_MAIN, width=12)
    
    return square_pad_and_resize(img)

# ==========================================
# 2. PERMAINAN - CONSOLE / HANDHELD (LIKE SWITCH/GAMEBOY)
# ==========================================
def render_permainan_console():
    img = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    add_shadow(img, [180, 830, 844, 940])
    
    stroke_w = 26
    
    sub_w, sub_h = 760, 480
    sub = Image.new("RGBA", (sub_w, sub_h), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(sub)
    
    cr = 64
    # 3D shadow bottom base
    sdraw.rounded_rectangle([20, 40, sub_w - 20, sub_h], radius=cr, fill=CYAN_DARK)
    sdraw.line([(20 + cr, sub_h), (sub_w - 20 - cr, sub_h)], fill=OUTLINE, width=stroke_w)
    
    # Front body (Cyan blue #29A9E1)
    sdraw.rounded_rectangle([20, 20, sub_w - 20, sub_h - 20], radius=cr, fill=CYAN_MAIN, outline=OUTLINE, width=stroke_w)
    
    # Left and Right grip colors (optional, keeps clean look)
    # White glossy reflection pill on top edge
    sdraw.rounded_rectangle([80, 38, sub_w - 80, 56], radius=9, fill=WHITE)
    
    # Center Screen: Slate Navy bezel + bright screen
    sc_w, sc_h = 340, 260
    sc_x = (sub_w - sc_w) // 2
    sc_y = (sub_h - sc_h) // 2 - 10
    
    # Bezel
    sdraw.rounded_rectangle([sc_x - 18, sc_y - 18, sc_x + sc_w + 18, sc_y + sc_h + 18], radius=32, fill=OUTLINE)
    
    # Screen glass (Dark navy blue / game screen)
    sdraw.rounded_rectangle([sc_x, sc_y, sc_x + sc_w, sc_y + sc_h], radius=20, fill=(24, 38, 56, 255))
    
    # Game scene on screen:
    # Cheerful game star/sun or heart pixel hero!
    # Let's draw a smiling golden star right inside the game screen!
    draw_star(sdraw, sub_w//2, sc_y + sc_h//2, r_out=70, r_in=32, fill=YELLOW_STAR, outline=WHITE, stroke_w=12)
    # Smile on game hero
    stx, sty = sub_w//2, sc_y + sc_h//2
    sdraw.ellipse([stx - 18, sty - 8, stx - 8, sty + 2], fill=OUTLINE)
    sdraw.ellipse([stx + 8, sty - 8, stx + 18, sty + 2], fill=OUTLINE)
    sdraw.arc([stx - 12, sty - 2, stx + 12, sty + 14], start=10, end=170, fill=OUTLINE, width=8)
    # Little platform block under star
    sdraw.rounded_rectangle([sc_x + 60, sc_y + sc_h - 35, sc_x + sc_w - 60, sc_y + sc_h - 15], radius=8, fill=GREEN_LIME)
    
    # Left Controls: D-PAD Cross
    dpx = 115
    dpy = sub_h // 2 - 10
    dw, dh = 22, 68
    sdraw.rounded_rectangle([dpx - dw, dpy - dh, dpx + dw, dpy + dh], radius=12, fill=OUTLINE)
    sdraw.rounded_rectangle([dpx - dh, dpy - dw, dpx + dh, dpy + dw], radius=12, fill=OUTLINE)
    sdraw.ellipse([dpx - 10, dpy - 10, dpx + 10, dpy + 10], fill=(60, 75, 95, 255))
    # Little thumbstick below D-pad
    sdraw.ellipse([dpx - 28, dpy + 90, dpx + 28, dpy + 146], fill=CYAN_DARK, outline=OUTLINE, width=14)
    sdraw.ellipse([dpx - 18, dpy + 100, dpx + 18, dpy + 136], fill=WHITE)
    
    # Right Controls: 4 Colorful Candy Buttons
    r_cx = sub_w - 115
    r_cy = sub_h // 2 - 10
    b_dist = 44
    br = 18
    btns = [
        (r_cx, r_cy - b_dist, RED_CORAL),
        (r_cx + b_dist, r_cy, YELLOW_STAR),
        (r_cx, r_cy + b_dist, GREEN_LIME),
        (r_cx - b_dist, r_cy, PURPLE_BTN),
    ]
    for bx, by, bcol in btns:
        sdraw.ellipse([bx - br, by - br, bx + br, by + br], fill=bcol, outline=OUTLINE, width=12)
        sdraw.ellipse([bx - br + 5, by - br + 5, bx - br + 12, by - br + 12], fill=WHITE)
    # Right thumbstick below buttons
    sdraw.ellipse([r_cx - 28, r_cy + 90, r_cx + 28, r_cy + 146], fill=CYAN_DARK, outline=OUTLINE, width=14)
    sdraw.ellipse([r_cx - 18, r_cy + 100, r_cx + 18, r_cy + 136], fill=WHITE)
    
    # Rotate console slightly (-7 deg) for dynamic 2.5D presentation
    rot_angle = -7
    sub_rot = sub.rotate(rot_angle, resample=Image.Resampling.BICUBIC, expand=True)
    rx = (CANVAS_SIZE - sub_rot.width) // 2
    ry = (CANVAS_SIZE - sub_rot.height) // 2 + 35
    img.alpha_composite(sub_rot, (rx, ry))
    
    # Big floating achievement star on top
    draw = ImageDraw.Draw(img)
    stx, sty = 620, 200
    draw_star(draw, stx, sty, r_out=90, r_in=40, fill=YELLOW_STAR, outline=OUTLINE, stroke_w=22)
    # Cheerful face on floating star
    draw.ellipse([stx - 26, sty - 10, stx - 14, sty + 2], fill=OUTLINE)
    draw.ellipse([stx + 14, sty - 10, stx + 26, sty + 2], fill=OUTLINE)
    draw.arc([stx - 16, sty - 2, stx + 16, sty + 18], start=10, end=170, fill=OUTLINE, width=12)
    # Sparkle rays
    draw.line([(stx + 95, sty - 45), (stx + 125, sty - 45)], fill=YELLOW_STAR, width=10)
    draw.line([(stx + 110, sty - 60), (stx + 110, sty - 30)], fill=YELLOW_STAR, width=10)
    
    return square_pad_and_resize(img)

# ==========================================
# 3. PERMAINAN - SEAMLESS PRO GAMEPAD
# ==========================================
def render_permainan_gamepad():
    img = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    add_shadow(img, [170, 830, 854, 940])
    
    stroke_w = 26
    
    # High resolution raster mask for a seamless curvy gamepad
    pad_w, pad_h = 740, 500
    pad = Image.new("RGBA", (pad_w, pad_h), (0, 0, 0, 0))
    pdraw = ImageDraw.Draw(pad)
    
    # We construct the gamepad body:
    # Top bar:
    pdraw.rounded_rectangle([100, 70, pad_w - 100, 280], radius=80, fill=CYAN_MAIN)
    # Left chubby grip:
    pdraw.rounded_rectangle([40, 110, 260, 450], radius=100, fill=CYAN_MAIN)
    # Right chubby grip:
    pdraw.rounded_rectangle([pad_w - 260, 110, pad_w - 40, 450], radius=100, fill=CYAN_MAIN)
    
    # 3D shadow bottom layer (darker blue)
    # We create full shape
    # Center cutout for ergonomic thumb grip arch
    pdraw.ellipse([pad_w//2 - 130, 240, pad_w//2 + 130, 430], fill=(0, 0, 0, 0))
    
    # Outline the entire solid alpha of pad
    # We can do this cleanly by creating a mask
    mask = pad.split()[3]
    # Edge detect or dialate
    # Actually, PIL can draw lines smoothly:
    
    # Let's create an upright gamepad image
    sub = Image.new("RGBA", (pad_w, pad_h), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(sub)
    
    # 3D Depth back
    for dy, col in [(35, CYAN_DARK), (0, CYAN_MAIN)]:
        sdraw.rounded_rectangle([100, 70 + dy, pad_w - 100, 280 + dy], radius=80, fill=col)
        sdraw.rounded_rectangle([40, 110 + dy, 260, 450 + dy], radius=100, fill=col)
        sdraw.rounded_rectangle([pad_w - 260, 110 + dy, pad_w - 40, 450 + dy], radius=100, fill=col)
    
    # Cutout arch
    sdraw.ellipse([pad_w//2 - 130, 240, pad_w//2 + 130, 430], fill=(0, 0, 0, 0))
    sdraw.ellipse([pad_w//2 - 130, 240, pad_w//2 + 130, 430], outline=OUTLINE, width=stroke_w)
    
    # Draw crisp outer borders
    sdraw.rounded_rectangle([100, 70, pad_w - 100, 280], radius=80, outline=OUTLINE, width=stroke_w)
    sdraw.rounded_rectangle([40, 110, 260, 450], radius=100, outline=OUTLINE, width=stroke_w)
    sdraw.rounded_rectangle([pad_w - 260, 110, pad_w - 40, 450], radius=100, outline=OUTLINE, width=stroke_w)
    
    # Inner faceplate (Off white)
    sdraw.rounded_rectangle([90, 100, pad_w - 90, 290], radius=50, fill=OFF_WHITE, outline=OUTLINE, width=18)
    
    # White glossy reflection
    sdraw.rounded_rectangle([150, 85, 340, 102], radius=8, fill=WHITE)
    
    # Left D-Pad
    dpx, dpy = 180, 205
    dw, dh = 24, 72
    sdraw.rounded_rectangle([dpx - dw, dpy - dh, dpx + dw, dpy + dh], radius=12, fill=OUTLINE)
    sdraw.rounded_rectangle([dpx - dh, dpy - dw, dpx + dh, dpy + dw], radius=12, fill=OUTLINE)
    sdraw.ellipse([dpx - 10, dpy - 10, dpx + 10, dpy + 10], fill=(60, 75, 95, 255))
    
    # Right Candy Buttons
    bx, by = pad_w - 180, 205
    dist = 46
    br = 20
    btns = [
        (bx, by - dist, RED_CORAL),
        (bx + dist, by, YELLOW_STAR),
        (bx, by + dist, GREEN_LIME),
        (bx - dist, by, PURPLE_BTN),
    ]
    for b_x, b_y, b_col in btns:
        sdraw.ellipse([b_x - br, b_y - br, b_x + br, b_y + br], fill=b_col, outline=OUTLINE, width=14)
        sdraw.ellipse([b_x - br + 5, b_y - br + 5, b_x - br + 13, b_y - br + 13], fill=WHITE)
        
    # Dual Thumbsticks (Center bottom)
    s1_x, s1_y = pad_w//2 - 65, 220
    s2_x, s2_y = pad_w//2 + 65, 220
    sr = 32
    for sx, sy in [(s1_x, s1_y), (s2_x, s2_y)]:
        sdraw.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=CYAN_DARK, outline=OUTLINE, width=14)
        sdraw.ellipse([sx - sr + 9, sy - sr + 9, sx + sr - 9, sy + sr - 9], fill=CYAN_MAIN)
        sdraw.ellipse([sx - 5, sy - 5, sx + 5, sy + 5], fill=WHITE)
        
    rot_angle = -8
    sub_rot = sub.rotate(rot_angle, resample=Image.Resampling.BICUBIC, expand=True)
    rx = (CANVAS_SIZE - sub_rot.width) // 2
    ry = (CANVAS_SIZE - sub_rot.height) // 2 + 50
    img.alpha_composite(sub_rot, (rx, ry))
    
    # Floating Star at top
    draw = ImageDraw.Draw(img)
    stx, sty = 512, 230
    draw_star(draw, stx, sty, r_out=110, r_in=50, fill=YELLOW_STAR, outline=OUTLINE, stroke_w=24)
    draw.ellipse([stx - 32, sty - 12, stx - 16, sty + 4], fill=OUTLINE)
    draw.ellipse([stx + 16, sty - 12, stx + 32, sty + 4], fill=OUTLINE)
    draw.arc([stx - 20, sty - 4, stx + 20, sty + 22], start=10, end=170, fill=OUTLINE, width=14)
    # Cheeks
    draw.ellipse([stx - 46, sty + 8, stx - 30, sty + 20], fill=(248, 113, 113, 180))
    draw.ellipse([stx + 30, sty + 8, stx + 46, sty + 20], fill=(248, 113, 113, 180))
    
    # Sparkle
    draw.line([(stx + 120, sty - 55), (stx + 155, sty - 55)], fill=YELLOW_STAR, width=10)
    draw.line([(stx + 138, sty - 72), (stx + 138, sty - 38)], fill=YELLOW_STAR, width=10)
    
    return square_pad_and_resize(img)

if __name__ == "__main__":
    out_book = r"C:\GIT\Pediagrow\scratch\new_icons\artikel_kesehatan_book.png"
    out_console = r"C:\GIT\Pediagrow\scratch\new_icons\permainan_console.png"
    out_gamepad = r"C:\GIT\Pediagrow\scratch\new_icons\permainan_gamepad.png"
    
    render_artikel_book().save(out_book, "PNG")
    render_permainan_console().save(out_console, "PNG")
    render_permainan_gamepad().save(out_gamepad, "PNG")
    print("All variant icons rendered!")

