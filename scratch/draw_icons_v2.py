import math
from PIL import Image, ImageDraw, ImageFilter

CANVAS = 1024
OUTLINE = (32, 41, 56, 255)  # Dark slate navy #202938
STROKE = 24

def draw_star(draw, cx, cy, r_out, r_in, fill, outline, stroke_w=24):
    pts = []
    for i in range(10):
        angle = -math.pi / 2 + (i * math.pi / 5)
        r = r_out if i % 2 == 0 else r_in
        pts.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
    draw.polygon(pts, fill=fill)
    draw.line(pts + [pts[0]], fill=outline, width=stroke_w, joint="curve")

def draw_artikel_kesehatan():
    img = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    
    # Soft contact shadow
    shadow = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.ellipse([240, 830, 784, 930], fill=(215, 225, 235, 170))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=28))
    img.alpha_composite(shadow)
    
    draw = ImageDraw.Draw(img)
    
    # Tilted medical book
    # Book spine/left bottom 3D base
    back_poly = [(260, 260), (740, 180), (790, 770), (310, 850)]
    thick_bottom = [(310, 850), (790, 770), (790, 805), (310, 885)]
    thick_left = [(260, 260), (310, 850), (280, 880), (230, 290)]
    
    # Draw 3D thickness
    draw.polygon(thick_bottom, fill=(215, 228, 238, 255))
    draw.line(thick_bottom + [thick_bottom[0]], fill=OUTLINE, width=STROKE, joint="curve")
    
    draw.polygon(thick_left, fill=(24, 88, 140, 255))
    draw.line(thick_left + [thick_left[0]], fill=OUTLINE, width=STROKE, joint="curve")
    
    # Main front cover (Sky blue #29A9E1)
    cover_poly = [(265, 250), (745, 170), (795, 760), (315, 840)]
    draw.polygon(cover_poly, fill=(41, 169, 225, 255))
    draw.line(cover_poly + [cover_poly[0]], fill=OUTLINE, width=STROKE, joint="curve")
    
    # Inner white paper sheet
    sheet_poly = [(305, 280), (710, 215), (755, 720), (350, 785)]
    draw.polygon(sheet_poly, fill=(250, 253, 255, 255))
    draw.line(sheet_poly + [sheet_poly[0]], fill=(32, 41, 56, 140), width=16, joint="curve")
    
    # Coral red ribbon bookmark hanging from top
    ribbon = [(480, 185), (555, 173), (540, 360), (517, 320), (495, 360)]
    draw.polygon(ribbon, fill=(232, 77, 61, 255))
    draw.line(ribbon + [ribbon[0]], fill=OUTLINE, width=20, joint="curve")
    
    # Central Medical Emblem: Big Heart with Medical Cross
    # Center: (535, 470)
    cx, cy = 535, 470
    
    # Draw Coral Red Heart Badge
    # Using smooth overlapping circles and triangle for stylized heart
    hr = 80
    h_left = (cx - 55, cy - 35)
    h_right = (cx + 55, cy - 35)
    
    heart_pts = [
        (cx, cy + 130), # Bottom point
        (cx - 130, cy + 15), # Left curve
        (cx - 130, cy - 60),
        (cx - 65, cy - 120),
        (cx, cy - 65),       # Dip
        (cx + 65, cy - 120),
        (cx + 130, cy - 60),
        (cx + 130, cy + 15),
    ]
    draw.polygon(heart_pts, fill=(232, 77, 61, 255))
    draw.line(heart_pts + [heart_pts[0]], fill=OUTLINE, width=STROKE, joint="curve")
    
    # Pure white cross inside heart
    cross_w, cross_h = 24, 75
    draw.rounded_rectangle([cx - cross_w, cy - cross_h + 10, cx + cross_w, cy + cross_h + 10], radius=10, fill=(255, 255, 255, 255))
    draw.rounded_rectangle([cx - cross_h, cy - cross_w + 10, cx + cross_h, cy + cross_w + 10], radius=10, fill=(255, 255, 255, 255))
    
    # Text lines in journal (soft blue-gray rounded pills)
    t_color = (185, 215, 235, 255)
    lw = 22
    for (x1, y1), (x2, y2) in [
        ((390, 635), (680, 585)),
        ((400, 690), (670, 640)),
        ((410, 745), (580, 715))
    ]:
        draw.line([(x1, y1), (x2, y2)], fill=t_color, width=lw)
        draw.ellipse([x1-lw//2, y1-lw//2, x1+lw//2, y1+lw//2], fill=t_color)
        draw.ellipse([x2-lw//2, y2-lw//2, x2+lw//2, y2+lw//2], fill=t_color)
        
    # Cute medical sparkle (top right)
    spx, spy = 810, 240
    draw.ellipse([spx - 18, spy - 18, spx + 18, spy + 18], fill=(41, 169, 225, 255))
    draw.line([(spx - 45, spy), (spx + 45, spy)], fill=(41, 169, 225, 255), width=12)
    draw.line([(spx, spy - 45), (spx, spy + 45)], fill=(41, 169, 225, 255), width=12)

    # Crop to content and square pad
    bbox = img.getbbox()
    cropped = img.crop(bbox)
    max_d = max(cropped.width, cropped.height)
    pad = int(max_d * 0.08)
    total = max_d + (pad * 2)
    res = Image.new("RGBA", (total, total), (0, 0, 0, 0))
    res.paste(cropped, ((total - cropped.width)//2, (total - cropped.height)//2))
    return res.resize((128, 128), Image.Resampling.LANCZOS)

def draw_permainan():
    img = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    
    # Soft contact shadow
    shadow = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.ellipse([180, 830, 844, 940], fill=(215, 225, 235, 170))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=28))
    img.alpha_composite(shadow)
    
    draw = ImageDraw.Draw(img)
    
    # Ergonomic Game Controller (Gamepad)
    # Controller center
    cx, cy = 512, 570
    
    # 3D Depth Base (Darker teal shadow body)
    base_shift = 45
    
    # Left & Right Grips (angled rounded capsules)
    # Body polygon with rounded grips
    body_pts = [
        # Top bridge
        (320, cy - 130), (704, cy - 130),
        # Right shoulder
        (820, cy - 80), (890, cy + 60),
        # Right grip bottom
        (860, cy + 240), (740, cy + 270),
        # Center bottom arch
        (620, cy + 140), (404, cy + 140),
        # Left grip bottom
        (284, cy + 270), (164, cy + 240),
        # Left shoulder
        (134, cy + 60), (204, cy - 80)
    ]
    
    # Draw bottom 3D shadow body
    body_shadow = [(x, y + base_shift) for (x, y) in body_pts]
    draw.polygon(body_shadow, fill=(24, 88, 140, 255))
    draw.line(body_shadow + [body_shadow[0]], fill=OUTLINE, width=STROKE, joint="curve")
    
    # Draw main top plate (Sky blue #29A9E1)
    draw.polygon(body_pts, fill=(41, 169, 225, 255))
    draw.line(body_pts + [body_pts[0]], fill=OUTLINE, width=STROKE, joint="curve")
    
    # Inner faceplate (Soft white #F0F8FF)
    face_pts = [
        (350, cy - 85), (674, cy - 85),
        (760, cy - 40), (810, cy + 60),
        (770, cy + 180), (690, cy + 200),
        (580, cy + 100), (444, cy + 100),
        (334, cy + 200), (254, cy + 180),
        (214, cy + 60), (264, cy - 40)
    ]
    draw.polygon(face_pts, fill=(244, 250, 255, 255))
    draw.line(face_pts + [face_pts[0]], fill=(32, 41, 56, 120), width=16, joint="curve")
    
    # Left D-Pad Cross (Dark slate navy)
    dpx, dpy = 310, cy + 50
    dw, dh = 32, 95
    draw.rounded_rectangle([dpx - dw, dpy - dh, dpx + dw, dpy + dh], radius=14, fill=OUTLINE)
    draw.rounded_rectangle([dpx - dh, dpy - dw, dpx + dh, dpy + dw], radius=14, fill=OUTLINE)
    draw.ellipse([dpx - 14, dpy - 14, dpx + 14, dpy + 14], fill=(50, 65, 85, 255))
    
    # Right Action Buttons (4 colorful candy buttons)
    # Top: Coral Red, Right: Yellow, Bottom: Green, Left: Purple
    bx, by = 714, cy + 50
    dist = 60
    br = 30
    btns = [
        (bx, by - dist, (232, 77, 61, 255)),   # Red
        (bx + dist, by, (251, 191, 36, 255)),  # Yellow
        (bx, by + dist, (16, 185, 129, 255)),  # Green
        (bx - dist, by, (129, 140, 248, 255)), # Purple
    ]
    for b_x, b_y, b_col in btns:
        draw.ellipse([b_x - br, b_y - br, b_x + br, b_y + br], fill=b_col, outline=OUTLINE, width=16)
        # White highlight shine
        draw.ellipse([b_x - br + 8, b_y - br + 8, b_x - br + 20, b_y - br + 20], fill=(255, 255, 255, 200))
        
    # Dual Thumbsticks (Center bottom)
    s1_x, s1_y = 434, cy + 70
    s2_x, s2_y = 590, cy + 70
    sr = 44
    for sx, sy in [(s1_x, s1_y), (s2_x, s2_y)]:
        draw.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=(41, 169, 225, 255), outline=OUTLINE, width=16)
        draw.ellipse([sx - sr + 14, sy - sr + 14, sx + sr - 14, sy + sr - 14], fill=(24, 88, 140, 255))
        
    # Big Cute Floating Star above controller
    stx, sty = 512, cy - 250
    draw_star(draw, stx, sty, r_out=115, r_in=52, fill=(251, 191, 36, 255), outline=OUTLINE, stroke_w=STROKE)
    
    # Cute smiling eyes and mouth on star
    draw.ellipse([stx - 35, sty - 15, stx - 18, sty + 4], fill=OUTLINE)
    draw.ellipse([stx + 18, sty - 15, stx + 35, sty + 4], fill=OUTLINE)
    draw.arc([stx - 25, sty - 8, stx + 25, sty + 25], start=10, end=170, fill=OUTLINE, width=16)
    
    # Sparkle rays
    draw.line([(stx + 120, sty - 60), (stx + 160, sty - 60)], fill=(251, 191, 36, 255), width=10)
    draw.line([(stx + 140, sty - 80), (stx + 140, sty - 40)], fill=(251, 191, 36, 255), width=10)

    # Crop to content and square pad
    bbox = img.getbbox()
    cropped = img.crop(bbox)
    max_d = max(cropped.width, cropped.height)
    pad = int(max_d * 0.08)
    total = max_d + (pad * 2)
    res = Image.new("RGBA", (total, total), (0, 0, 0, 0))
    res.paste(cropped, ((total - cropped.width)//2, (total - cropped.height)//2))
    return res.resize((128, 128), Image.Resampling.LANCZOS)

out_artikel = r"C:\GIT\Pediagrow\scratch\new_icons\artikel_kesehatan_new.png"
out_permainan = r"C:\GIT\Pediagrow\scratch\new_icons\permainan_new.png"

draw_artikel_kesehatan().save(out_artikel, "PNG")
draw_permainan().save(out_permainan, "PNG")
print("Successfully generated v2 icons!")

