import math
from PIL import Image, ImageDraw, ImageFilter

OUTLINE = (32, 41, 56, 255)       # Slate navy #202938
CYAN_MAIN = (41, 169, 225, 255)   # #29A9E1
CYAN_LIGHT = (186, 230, 253, 255) # Light blue accent
CYAN_DARK = (14, 116, 144, 255)   # 3D edge
RED_CORAL = (239, 68, 68, 255)    # #EF4444
RED_DARK = (185, 28, 28, 255)
YELLOW_STAR = (251, 191, 36, 255) # #FBBF24
YELLOW_DARK = (217, 119, 6, 255)
GREEN_LIME = (16, 185, 129, 255)  # #10B981
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

def render_artikel_kesehatan():
    img = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    
    # 1. Soft contact shadow at bottom
    shadow = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.ellipse([220, 840, 804, 950], fill=(210, 222, 235, 180))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=32))
    img.alpha_composite(shadow)
    
    draw = ImageDraw.Draw(img)
    stroke_w = 26
    
    # 2. Isometric 2.5D tilted clipboard / medical journal
    # Backing board (Dark Navy Slate #243342) - tilted ~15 degrees
    # We can draw the board with rounded corners using transformed points or smooth polygon
    
    # Let's create an upright high-res sub-canvas for the board/journal, then rotate smoothly!
    # That gives mathematically PERFECT rounded corners, perfect text lines, perfect clip!
    sub_w, sub_h = 600, 780
    sub = Image.new("RGBA", (sub_w, sub_h), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(sub)
    
    # Base board: Slate navy rounded rect
    corner_r = 54
    # 3D Depth back
    sdraw.rounded_rectangle([20, 35, sub_w - 20, sub_h - 10], radius=corner_r, fill=(18, 26, 36, 255))
    # Front board
    sdraw.rounded_rectangle([20, 20, sub_w - 20, sub_h - 25], radius=corner_r, fill=(36, 51, 66, 255), outline=OUTLINE, width=stroke_w)
    
    # Inner White Paper Sheet with rounded corners
    paper_margin_x = 52
    paper_top = 80
    paper_bot = sub_h - 60
    paper_r = 36
    # 3D paper stack edge
    sdraw.rounded_rectangle([paper_margin_x, paper_top + 10, sub_w - paper_margin_x, paper_bot + 10], radius=paper_r, fill=(226, 232, 240, 255))
    sdraw.rounded_rectangle([paper_margin_x, paper_top, sub_w - paper_margin_x, paper_bot], radius=paper_r, fill=WHITE, outline=OUTLINE, width=stroke_w)
    
    # Header clip at the top of the board (Sky Cyan #29A9E1)
    clip_w, clip_h = 220, 75
    clip_x = (sub_w - clip_w) // 2
    clip_y = 12
    # Clip ring
    ring_r = 30
    sdraw.ellipse([sub_w//2 - ring_r, clip_y - 20, sub_w//2 + ring_r, clip_y + 40], fill=WHITE, outline=OUTLINE, width=stroke_w)
    sdraw.ellipse([sub_w//2 - 14, clip_y - 4, sub_w//2 + 14, clip_y + 24], fill=(36, 51, 66, 255))
    # Clip body
    sdraw.rounded_rectangle([clip_x, clip_y + 15, clip_x + clip_w, clip_y + 15 + clip_h], radius=22, fill=CYAN_MAIN, outline=OUTLINE, width=stroke_w)
    # Clip highlight pill
    sdraw.rounded_rectangle([clip_x + 25, clip_y + 26, clip_x + clip_w - 25, clip_y + 42], radius=8, fill=WHITE)
    
    # Paper Content:
    # A) Big Medical Shield with Heart & Cross
    sh_cx = sub_w // 2
    sh_cy = 280
    sh_w = 110
    sh_h = 135
    
    # Shield shape points
    shield_pts = [
        (sh_cx - sh_w, sh_cy - sh_h + 30),
        (sh_cx, sh_cy - sh_h),
        (sh_cx + sh_w, sh_cy - sh_h + 30),
        (sh_cx + sh_w, sh_cy + 25),
        (sh_cx, sh_cy + sh_h),
        (sh_cx - sh_w, sh_cy + 25),
    ]
    # Draw Shield background (Soft Yellow-Orange or Coral Red)
    sdraw.polygon(shield_pts, fill=RED_CORAL)
    sdraw.line(shield_pts + [shield_pts[0]], fill=OUTLINE, width=stroke_w, joint="curve")
    
    # White Medical Cross inside Shield
    cw, ch = 24, 70
    sdraw.rounded_rectangle([sh_cx - cw, sh_cy - ch + 15, sh_cx + cw, sh_cy + ch + 15], radius=10, fill=WHITE)
    sdraw.rounded_rectangle([sh_cx - ch, sh_cy - cw + 15, sh_cx + ch, sh_cy + cw + 15], radius=10, fill=WHITE)
    
    # Little shiny highlight on shield
    sdraw.arc([sh_cx - sh_w + 18, sh_cy - sh_h + 35, sh_cx - sh_w + 50, sh_cy + 10], start=120, end=260, fill=WHITE, width=12)
    
    # B) Article Headline and Lines
    # Headline pill (Sky blue)
    sdraw.rounded_rectangle([95, 460, 310, 488], radius=14, fill=CYAN_MAIN)
    # Tag badge pill (Green)
    sdraw.rounded_rectangle([330, 460, 420, 488], radius=14, fill=GREEN_LIME)
    
    # Text lines (Rounded soft grey-blue bars)
    for ly in [530, 580, 630]:
        sdraw.rounded_rectangle([95, ly, sub_w - 95, ly + 22], radius=11, fill=PAPER_LINE)
    # Short last line
    sdraw.rounded_rectangle([95, 680, sub_w - 230, 680 + 22], radius=11, fill=PAPER_LINE)
    
    # Rotate the whole clipboard with high quality
    angle = -11 # Gentle friendly angle like grafik_pertumbuhan
    sub_rot = sub.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)
    
    # Paste rotated board onto canvas
    rx = (CANVAS_SIZE - sub_rot.width) // 2
    ry = (CANVAS_SIZE - sub_rot.height) // 2 + 10
    img.alpha_composite(sub_rot, (rx, ry))
    
    # Add floating accent: A cute medical stethoscope or sparkling star
    draw = ImageDraw.Draw(img)
    # Floating cheerful golden star near top-right
    stx, sty = 780, 220
    draw_star(draw, stx, sty, r_out=75, r_in=34, fill=YELLOW_STAR, outline=OUTLINE, stroke_w=20)
    # Star smile
    draw.ellipse([stx - 22, sty - 8, stx - 12, sty + 4], fill=OUTLINE)
    draw.ellipse([stx + 12, sty - 8, stx + 22, sty + 4], fill=OUTLINE)
    draw.arc([stx - 15, sty - 2, stx + 15, sty + 16], start=10, end=170, fill=OUTLINE, width=10)
    
    # Crop and square pad
    bbox = img.getbbox()
    cropped = img.crop(bbox)
    max_d = max(cropped.width, cropped.height)
    pad = int(max_d * 0.08)
    total = max_d + (pad * 2)
    res = Image.new("RGBA", (total, total), (0, 0, 0, 0))
    res.paste(cropped, ((total - cropped.width)//2, (total - cropped.height)//2))
    return res.resize((128, 128), Image.Resampling.LANCZOS)


def render_permainan():
    img = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    
    # 1. Soft contact shadow at bottom
    shadow = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.ellipse([160, 830, 864, 950], fill=(210, 222, 235, 180))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=34))
    img.alpha_composite(shadow)
    
    stroke_w = 26
    
    # Render upright cute rounded gamepad with smooth chubby curves
    sub_w, sub_h = 760, 520
    sub = Image.new("RGBA", (sub_w, sub_h), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(sub)
    
    # Chubby gamepad body:
    # Made of two big rounded grip pills on left/right and a center bridge!
    # Left grip: angled pill
    # Right grip: angled pill
    # Center: wide rounded rectangle
    
    # Let's draw the gamepad base 3D shadow (darker blue #18588C)
    depth_y = 35
    
    for dy, col, is_front in [(depth_y, (20, 80, 125, 255), False), (0, CYAN_MAIN, True)]:
        # Draw base geometry
        # Left grip ellipse:
        sdraw.ellipse([30, 110 + dy, 270, 480 + dy], fill=col)
        # Right grip ellipse:
        sdraw.ellipse([sub_w - 270, 110 + dy, sub_w - 30, 480 + dy], fill=col)
        # Top bridge rounded rect:
        sdraw.rounded_rectangle([130, 80 + dy, sub_w - 130, 360 + dy], radius=80, fill=col)
        # Inner bottom notch (to make ergonomic gamepad arch):
        if not is_front:
            # We outline the union
            pass
            
    # Draw crisp outer outline around the front gamepad body
    # We do this by extracting mask or drawing layered shapes
    # Left grip front:
    sdraw.ellipse([30, 110, 270, 480], fill=CYAN_MAIN, outline=OUTLINE, width=stroke_w)
    sdraw.ellipse([sub_w - 270, 110, sub_w - 30, 480], fill=CYAN_MAIN, outline=OUTLINE, width=stroke_w)
    sdraw.rounded_rectangle([130, 80, sub_w - 130, 360], radius=80, fill=CYAN_MAIN, outline=OUTLINE, width=stroke_w)
    
    # Ergonomic bottom arch cut-out in soft shadow color
    sdraw.ellipse([sub_w//2 - 130, 310, sub_w//2 + 130, 450], fill=(20, 80, 125, 255), outline=OUTLINE, width=stroke_w)
    
    # White / Pale Blue Inner Faceplate
    fp_margin_x = 75
    sdraw.rounded_rectangle([fp_margin_x, 115, sub_w - fp_margin_x, 325], radius=60, fill=OFF_WHITE, outline=OUTLINE, width=20)
    
    # White glossy highlight reflection on top left of gamepad
    sdraw.arc([60, 125, 240, 260], start=160, end=270, fill=WHITE, width=20)
    sdraw.rounded_rectangle([180, 100, 360, 118], radius=9, fill=WHITE)
    
    # Left D-Pad Cross (Dark Slate Navy #202938)
    dpx, dpy = 195, 220
    dw, dh = 24, 76
    sdraw.rounded_rectangle([dpx - dw, dpy - dh, dpx + dw, dpy + dh], radius=12, fill=OUTLINE)
    sdraw.rounded_rectangle([dpx - dh, dpy - dw, dpx + dh, dpy + dw], radius=12, fill=OUTLINE)
    sdraw.ellipse([dpx - 12, dpy - 12, dpx + 12, dpy + 12], fill=(55, 70, 90, 255))
    
    # Right 4 Action Buttons (Candy buttons)
    bx, by = sub_w - 195, 220
    dist = 48
    br = 22
    btns = [
        (bx, by - dist, RED_CORAL),    # Top: Coral Red
        (bx + dist, by, YELLOW_STAR),  # Right: Sunny Yellow
        (bx, by + dist, GREEN_LIME),   # Bottom: Emerald Green
        (bx - dist, by, (129, 140, 248, 255)), # Left: Soft Purple
    ]
    for b_x, b_y, b_col in btns:
        sdraw.ellipse([b_x - br, b_y - br, b_x + br, b_y + br], fill=b_col, outline=OUTLINE, width=14)
        # Gloss shine
        sdraw.ellipse([b_x - br + 6, b_y - br + 6, b_x - br + 15, b_y - br + 15], fill=WHITE)
        
    # Dual Thumbsticks in Center
    s1_x, s1_y = sub_w//2 - 70, 240
    s2_x, s2_y = sub_w//2 + 70, 240
    sr = 34
    for sx, sy in [(s1_x, s1_y), (s2_x, s2_y)]:
        sdraw.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=(14, 116, 144, 255), outline=OUTLINE, width=16)
        sdraw.ellipse([sx - sr + 10, sy - sr + 10, sx + sr - 10, sy + sr - 10], fill=CYAN_MAIN)
        sdraw.ellipse([sx - 6, sy - 6, sx + 6, sy + 6], fill=WHITE)
        
    # Rotate gamepad slightly (-8 degrees) for energetic 2.5D presentation
    rot_angle = -8
    sub_rot = sub.rotate(rot_angle, resample=Image.Resampling.BICUBIC, expand=True)
    rx = (CANVAS_SIZE - sub_rot.width) // 2
    ry = (CANVAS_SIZE - sub_rot.height) // 2 + 70
    img.alpha_composite(sub_rot, (rx, ry))
    
    # Big Floating Achievement Star at top center
    draw = ImageDraw.Draw(img)
    stx, sty = 512, 230
    draw_star(draw, stx, sty, r_out=115, r_in=52, fill=YELLOW_STAR, outline=OUTLINE, stroke_w=24)
    # Cute smiling eyes and mouth
    draw.ellipse([stx - 34, sty - 14, stx - 18, sty + 4], fill=OUTLINE)
    draw.ellipse([stx + 18, sty - 14, stx + 34, sty + 4], fill=OUTLINE)
    draw.arc([stx - 22, sty - 4, stx + 22, sty + 24], start=10, end=170, fill=OUTLINE, width=14)
    # Cheeks
    draw.ellipse([stx - 48, sty + 8, stx - 32, sty + 20], fill=(248, 113, 113, 180))
    draw.ellipse([stx + 32, sty + 8, stx + 48, sty + 20], fill=(248, 113, 113, 180))
    
    # Sparkles around star
    draw.line([(stx + 125, sty - 60), (stx + 165, sty - 60)], fill=YELLOW_STAR, width=12)
    draw.line([(stx + 145, sty - 80), (stx + 145, sty - 40)], fill=YELLOW_STAR, width=12)
    
    # Crop and square pad
    bbox = img.getbbox()
    cropped = img.crop(bbox)
    max_d = max(cropped.width, cropped.height)
    pad = int(max_d * 0.08)
    total = max_d + (pad * 2)
    res = Image.new("RGBA", (total, total), (0, 0, 0, 0))
    res.paste(cropped, ((total - cropped.width)//2, (total - cropped.height)//2))
    return res.resize((128, 128), Image.Resampling.LANCZOS)

if __name__ == "__main__":
    out_artikel = r"C:\GIT\Pediagrow\scratch\new_icons\artikel_kesehatan_perfect.png"
    out_permainan = r"C:\GIT\Pediagrow\scratch\new_icons\permainan_perfect.png"
    
    render_artikel_kesehatan().save(out_artikel, "PNG")
    render_permainan().save(out_permainan, "PNG")
    print("Perfect icons rendered successfully!")

