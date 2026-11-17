import math
from PIL import Image, ImageDraw, ImageFilter

SCALE = 4
SIZE = 256 * SCALE  # 1024x1024 canvas
STROKE_COLOR = (32, 41, 56, 255)  # #202938
STROKE_W = 7 * SCALE  # ~28px

def create_shadow_layer(width, height, cx, cy, rx, ry, color=(220, 229, 238, 180)):
    shadow = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=color)
    return shadow.filter(ImageFilter.GaussianBlur(radius=8 * SCALE))

# ─────────────────────────────────────────────────────────────────────────────
# 1. ARTIKEL KESEHATAN ICON
# ─────────────────────────────────────────────────────────────────────────────
def draw_artikel_kesehatan():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    
    # Contact shadow
    shadow = create_shadow_layer(SIZE, SIZE, 512, 850, 320, 55)
    img.alpha_composite(shadow)
    
    draw = ImageDraw.Draw(img)
    
    # Book / Journal tilted geometry (approx 20 deg tilt)
    # Book dimensions
    bw, bh = 420, 560
    bx, by = 490, 480
    
    # Base polygon with 3D pages thickness
    # Bottom page stack (gray/white layers)
    pages_poly = [
        (310, 250), (690, 190), (740, 720), (360, 785)
    ]
    # Thickness sides
    thickness_bottom = [
        (360, 785), (740, 720), (745, 755), (365, 820)
    ]
    thickness_left = [
        (310, 250), (360, 785), (345, 805), (295, 270)
    ]
    
    # Draw page thickness
    draw.polygon(thickness_bottom, fill=(215, 226, 236, 255))
    draw.line(thickness_bottom + [thickness_bottom[0]], fill=STROKE_COLOR, width=STROKE_W, joint="curve")
    
    draw.polygon(thickness_left, fill=(26, 92, 142, 255))
    draw.line(thickness_left + [thickness_left[0]], fill=STROKE_COLOR, width=STROKE_W, joint="curve")
    
    # Cover polygon (Sky blue / cyan with curved corners)
    cover_poly = [
        (315, 240), (695, 180), (745, 715), (365, 780)
    ]
    draw.polygon(cover_poly, fill=(41, 169, 225, 255))
    
    # Cover inner white page sheet
    sheet_poly = [
        (345, 270), (665, 220), (710, 680), (390, 735)
    ]
    draw.polygon(sheet_poly, fill=(248, 252, 255, 255))
    
    # Cover dark outline
    draw.line(cover_poly + [cover_poly[0]], fill=STROKE_COLOR, width=STROKE_W, joint="curve")
    draw.line(sheet_poly + [sheet_poly[0]], fill=(32, 41, 56, 120), width=int(STROKE_W * 0.6), joint="curve")
    
    # Ribbon bookmark hanging from top (coral red #E84D3D)
    ribbon = [
        (480, 190), (540, 180), (530, 340), (505, 305), (480, 340)
    ]
    draw.polygon(ribbon, fill=(232, 77, 61, 255))
    draw.line(ribbon + [ribbon[0]], fill=STROKE_COLOR, width=int(STROKE_W * 0.8), joint="curve")
    
    # Medical Heart / Shield in center of page
    # Heart center ~ (530, 420)
    hcx, hcy = 530, 420
    # Draw coral red circle badge with cross
    badge_r = 85
    draw.ellipse([hcx - badge_r, hcy - badge_r, hcx + badge_r, hcy + badge_r], fill=(232, 77, 61, 255), outline=STROKE_COLOR, width=STROKE_W)
    
    # White medical cross inside badge
    cw, ch = 22, 60
    # vertical bar
    draw.rounded_rectangle([hcx - cw, hcy - ch, hcx + cw, hcy + ch], radius=8, fill=(255, 255, 255, 255))
    # horizontal bar
    draw.rounded_rectangle([hcx - ch, hcy - cw, hcx + ch, hcy + cw], radius=8, fill=(255, 255, 255, 255))
    
    # Article text lines below badge
    line_color = (180, 210, 230, 255)
    line_w = 16
    lines = [
        [(415, 545), (665, 505)],
        [(425, 595), (655, 555)],
        [(435, 645), (585, 620)],
    ]
    for p1, p2 in lines:
        draw.line([p1, p2], fill=line_color, width=line_w)
        # Endcaps
        draw.ellipse([p1[0]-line_w//2, p1[1]-line_w//2, p1[0]+line_w//2, p1[1]+line_w//2], fill=line_color)
        draw.ellipse([p2[0]-line_w//2, p2[1]-line_w//2, p2[0]+line_w//2, p2[1]+line_w//2], fill=line_color)
        
    # Floating spark / plus decoration on top right
    sp_cx, sp_cy = 760, 260
    draw.ellipse([sp_cx - 16, sp_cy - 16, sp_cx + 16, sp_cy + 16], fill=(41, 169, 225, 255))
    draw.line([(sp_cx - 36, sp_cy), (sp_cx + 36, sp_cy)], fill=(41, 169, 225, 255), width=10)
    draw.line([(sp_cx, sp_cy - 36), (sp_cx, sp_cy + 36)], fill=(41, 169, 225, 255), width=10)
    
    # Resize down with Lanczos
    return img.resize((128, 128), Image.Resampling.LANCZOS)

# ─────────────────────────────────────────────────────────────────────────────
# 2. PERMAINAN ICON
# ─────────────────────────────────────────────────────────────────────────────
def draw_permainan():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    
    # Contact shadow
    shadow = create_shadow_layer(SIZE, SIZE, 512, 850, 360, 60)
    img.alpha_composite(shadow)
    
    draw = ImageDraw.Draw(img)
    
    # Gamepad body (tilted slightly, semi-isometric)
    # Main rounded controller body
    gx, gy = 512, 540
    gw, gh = 700, 360
    
    # Controller 3D bottom base (dark blue shadow band)
    bottom_base = [gx - 320, gy + 30, gx + 320, gy + gh - 40]
    draw.rounded_rectangle(bottom_base, radius=130, fill=(26, 92, 142, 255), outline=STROKE_COLOR, width=STROKE_W)
    
    # Main top controller plate (Sky blue #29A9E1)
    top_base = [gx - 320, gy - 70, gx + 320, gy + gh - 140]
    draw.rounded_rectangle(top_base, radius=130, fill=(41, 169, 225, 255), outline=STROKE_COLOR, width=STROKE_W)
    
    # White accent faceplate
    faceplate = [gx - 230, gy - 20, gx + 230, gy + gh - 190]
    draw.rounded_rectangle(faceplate, radius=80, fill=(240, 248, 255, 255), outline=STROKE_COLOR, width=int(STROKE_W * 0.7))
    
    # Left D-Pad (Directional Cross #202938)
    dpad_cx, dpad_cy = gx - 170, gy + 80
    dw, dh = 26, 75
    draw.rounded_rectangle([dpad_cx - dw, dpad_cy - dh, dpad_cx + dw, dpad_cy + dh], radius=10, fill=STROKE_COLOR)
    draw.rounded_rectangle([dpad_cx - dh, dpad_cy - dw, dpad_cx + dh, dpad_cy + dw], radius=10, fill=STROKE_COLOR)
    # Center circle indent
    draw.ellipse([dpad_cx - 12, dpad_cy - 12, dpad_cx + 12, dpad_cy + 12], fill=(45, 58, 75, 255))
    
    # Right Action Buttons (4 colored candy buttons)
    btn_cx, btn_cy = gx + 170, gy + 80
    br = 26
    dist = 48
    # Top: Coral Red
    draw.ellipse([btn_cx - br, btn_cy - dist - br, btn_cx + br, btn_cy - dist + br], fill=(232, 77, 61, 255), outline=STROKE_COLOR, width=int(STROKE_W * 0.7))
    # Right: Yellow
    draw.ellipse([btn_cx + dist - br, btn_cy - br, btn_cx + dist + br, btn_cy + br], fill=(251, 191, 36, 255), outline=STROKE_COLOR, width=int(STROKE_W * 0.7))
    # Bottom: Green
    draw.ellipse([btn_cx - br, btn_cy + dist - br, btn_cx + br, btn_cy + dist + br], fill=(16, 185, 129, 255), outline=STROKE_COLOR, width=int(STROKE_W * 0.7))
    # Left: Purple-Blue
    draw.ellipse([btn_cx - dist - br, btn_cy - br, btn_cx - dist + br, btn_cy + br], fill=(99, 102, 241, 255), outline=STROKE_COLOR, width=int(STROKE_W * 0.7))
    
    # Center thumbsticks (two small circles)
    stick1_x, stick1_y = gx - 65, gy + 140
    stick2_x, stick2_y = gx + 65, gy + 140
    sr = 36
    for sx, sy in [(stick1_x, stick1_y), (stick2_x, stick2_y)]:
        draw.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=(41, 169, 225, 255), outline=STROKE_COLOR, width=int(STROKE_W * 0.7))
        draw.ellipse([sx - sr + 10, sy - sr + 10, sx + sr - 10, sy + sr - 10], fill=(26, 92, 142, 255))
        
    # Floating Achievement Star above controller
    star_cx, star_cy = gx, gy - 210
    star_r_out = 95
    star_r_in = 42
    star_pts = []
    for i in range(10):
        angle = -math.pi / 2 + (i * math.pi / 5)
        r = star_r_out if i % 2 == 0 else star_r_in
        star_pts.append((star_cx + r * math.cos(angle), star_cy + r * math.sin(angle)))
        
    draw.polygon(star_pts, fill=(251, 191, 36, 255))
    draw.line(star_pts + [star_pts[0]], fill=STROKE_COLOR, width=STROKE_W, joint="curve")
    
    # Cute smiling star face
    # Eyes
    draw.ellipse([star_cx - 28, star_cy - 12, star_cx - 16, star_cy], fill=STROKE_COLOR)
    draw.ellipse([star_cx + 16, star_cy - 12, star_cx + 28, star_cy], fill=STROKE_COLOR)
    # Smile arc
    draw.arc([star_cx - 20, star_cy - 6, star_cx + 20, star_cy + 22], start=10, end=170, fill=STROKE_COLOR, width=int(STROKE_W * 0.7))
    
    # Star gleam sparkle
    draw.line([(star_cx + 100, star_cy - 60), (star_cx + 130, star_cy - 60)], fill=(251, 191, 36, 255), width=8)
    draw.line([(star_cx + 115, star_cy - 75), (star_cx + 115, star_cy - 45)], fill=(251, 191, 36, 255), width=8)

    return img.resize((128, 128), Image.Resampling.LANCZOS)

# Generate and save
out_artikel = r"C:\GIT\Pediagrow\scratch\new_icons\artikel_kesehatan_new.png"
out_permainan = r"C:\GIT\Pediagrow\scratch\new_icons\permainan_new.png"

draw_artikel_kesehatan().save(out_artikel, "PNG")
draw_permainan().save(out_permainan, "PNG")
print("Saved custom vector icons!")

