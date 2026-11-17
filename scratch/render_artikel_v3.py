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
WHITE = (255, 255, 255, 255)
OFF_WHITE = (248, 250, 252, 255)
PAPER_LINE = (203, 213, 225, 255) # #CBD5E1

CANVAS_SIZE = 1024

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

def draw_smooth_shield(draw, cx, cy, w, h, fill, outline, stroke_w):
    # Generates a smooth classic medical shield
    pts = []
    # Top edge: slight dip in center or arched
    # Left top corner
    pts.append((cx - w, cy - h))
    # Top arch
    pts.append((cx, cy - h + 18))
    # Right top corner
    pts.append((cx + w, cy - h))
    # Right side going down straight
    pts.append((cx + w, cy))
    # Curve to bottom point using bezier-like arc
    steps = 16
    for i in range(steps + 1):
        t = i / steps
        # from (cx + w, cy) to (cx, cy + h)
        x = (1 - t)**2 * (cx + w) + 2 * (1 - t) * t * (cx + w * 0.8) + t**2 * cx
        y = (1 - t)**2 * cy + 2 * (1 - t) * t * (cy + h * 0.8) + t**2 * (cy + h)
        pts.append((x, y))
    for i in range(steps + 1):
        t = i / steps
        # from (cx, cy + h) to (cx - w, cy)
        x = (1 - t)**2 * cx + 2 * (1 - t) * t * (cx - w * 0.8) + t**2 * (cx - w)
        y = (1 - t)**2 * (cy + h) + 2 * (1 - t) * t * (cy + h * 0.8) + t**2 * cy
        pts.append((x, y))
    pts.append((cx - w, cy - h))
    
    draw.polygon(pts, fill=fill)
    draw.line(pts, fill=outline, width=stroke_w, joint="curve")

def render_artikel_journal():
    img = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    add_shadow(img, [200, 840, 824, 950])
    
    stroke_w = 26
    
    # 2.5D Health Article / Journal
    sub_w, sub_h = 620, 780
    sub = Image.new("RGBA", (sub_w, sub_h), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(sub)
    
    cr = 46
    # 3D Depth back cover (Warm teal/navy edge)
    sdraw.rounded_rectangle([25, 45, sub_w - 25, sub_h - 15], radius=cr, fill=(22, 78, 124, 255), outline=OUTLINE, width=stroke_w)
    
    # Front cover: Vibrant Sky Cyan (#29A9E1)
    sdraw.rounded_rectangle([25, 20, sub_w - 40, sub_h - 40], radius=cr, fill=CYAN_MAIN, outline=OUTLINE, width=stroke_w)
    
    # Left spine line accent
    sdraw.line([(95, 20), (95, sub_h - 40)], fill=OUTLINE, width=18)
    # White glossy highlight on spine
    sdraw.line([(55, 45), (55, sub_h - 65)], fill=WHITE, width=12)
    
    # White inner article sheet
    sdraw.rounded_rectangle([125, 55, sub_w - 65, sub_h - 75], radius=28, fill=WHITE, outline=OUTLINE, width=22)
    
    # Top bookmark ribbon (Coral Red)
    rb_w = 56
    rb_x = 205
    rb_pts = [(rb_x, 20), (rb_x + rb_w, 20), (rb_x + rb_w, 180), (rb_x + rb_w//2, 145), (rb_x, 180)]
    sdraw.polygon(rb_pts, fill=RED_CORAL)
    sdraw.line(rb_pts + [rb_pts[0]], fill=OUTLINE, width=18, joint="curve")
    
    # Smooth Medical Shield Emblem
    sh_cx = 360
    sh_cy = 285
    sh_w = 105
    sh_h = 120
    draw_smooth_shield(sdraw, sh_cx, sh_cy, sh_w, sh_h, fill=RED_CORAL, outline=OUTLINE, stroke_w=24)
    
    # Bold pure white medical cross in center
    cw, ch = 22, 62
    sdraw.rounded_rectangle([sh_cx - cw, sh_cy - ch + 10, sh_cx + cw, sh_cy + ch + 10], radius=10, fill=WHITE)
    sdraw.rounded_rectangle([sh_cx - ch, sh_cy - cw + 10, sh_cx + ch, sh_cy + cw + 10], radius=10, fill=WHITE)
    
    # Shield highlight arc
    sdraw.arc([sh_cx - sh_w + 16, sh_cy - sh_h + 20, sh_cx - sh_w + 48, sh_cy], start=120, end=250, fill=WHITE, width=10)
    
    # Article headline bar (Sky Blue + Green Tag)
    sdraw.rounded_rectangle([160, 440, 400, 470], radius=15, fill=CYAN_MAIN)
    sdraw.rounded_rectangle([420, 440, 490, 470], radius=15, fill=GREEN_LIME)
    
    # Article body text lines (Soft Blue-Gray)
    for ly in [510, 560, 610]:
        sdraw.rounded_rectangle([160, ly, sub_w - 95, ly + 22], radius=11, fill=PAPER_LINE)
    sdraw.rounded_rectangle([160, 660, sub_w - 200, 660 + 22], radius=11, fill=PAPER_LINE)
    
    # Rotate slightly
    angle = -10
    sub_rot = sub.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)
    rx = (CANVAS_SIZE - sub_rot.width) // 2
    ry = (CANVAS_SIZE - sub_rot.height) // 2 + 10
    img.alpha_composite(sub_rot, (rx, ry))
    
    # Cheerful golden star / sparkle accent on top right
    draw = ImageDraw.Draw(img)
    stx, sty = 790, 220
    # Floating star
    pts = []
    for i in range(10):
        a = -math.pi / 2 + (i * math.pi / 5)
        r = 65 if i % 2 == 0 else 28
        pts.append((stx + r * math.cos(a), sty + r * math.sin(a)))
    draw.polygon(pts, fill=YELLOW_STAR)
    draw.line(pts + [pts[0]], fill=OUTLINE, width=18, joint="curve")
    # Star smile
    draw.ellipse([stx - 16, sty - 6, stx - 8, sty + 2], fill=OUTLINE)
    draw.ellipse([stx + 8, sty - 6, stx + 16, sty + 2], fill=OUTLINE)
    draw.arc([stx - 12, sty - 2, stx + 12, sty + 12], start=10, end=170, fill=OUTLINE, width=8)
    
    return square_pad_and_resize(img)

if __name__ == "__main__":
    out_path = r"C:\GIT\Pediagrow\scratch\new_icons\artikel_kesehatan_v3.png"
    render_artikel_journal().save(out_path, "PNG")
    print("Artikel kesehatan v3 rendered!")

