import math
from PIL import Image, ImageDraw, ImageFilter, ImageFont

CANVAS_SIZE = 1024
OUTLINE = (32, 41, 56, 255)       # Slate navy #202938
CYAN_MAIN = (41, 169, 225, 255)   # #29A9E1
CYAN_LIGHT = (186, 230, 253, 255) # Light blue
CYAN_DARK = (24, 88, 140, 255)    # 3D shadow blue
RED_CORAL = (239, 68, 68, 255)    # #EF4444
RED_DARK = (185, 28, 28, 255)
YELLOW_STAR = (251, 191, 36, 255) # #FBBF24
GREEN_LIME = (16, 185, 129, 255)  # #10B981
PURPLE_BTN = (129, 140, 248, 255) # #818CF8
ORANGE_MPASI = (249, 115, 22, 255) # #F97316
ORANGE_DARK = (194, 65, 12, 255)
WHITE = (255, 255, 255, 255)
OFF_WHITE = (248, 250, 252, 255)
PAPER_LINE = (203, 213, 225, 255) # #CBD5E1

def draw_star(draw, cx, cy, r_out, r_in, fill, outline, stroke_w=24):
    pts = []
    for i in range(10):
        angle = -math.pi / 2 + (i * math.pi / 5)
        r = r_out if i % 2 == 0 else r_in
        pts.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
    draw.polygon(pts, fill=fill)
    draw.line(pts + [pts[0]], fill=outline, width=stroke_w, joint="curve")

def crop_tight_and_resize(img, target_size=128, pad_px=4):
    # Crop to alpha bounding box tightly
    bbox = img.getbbox()
    if not bbox:
        return img.resize((target_size, target_size))
    cropped = img.crop(bbox)
    
    # Fit into square canvas with minimal margin (pad_px on 128x128 scale)
    w, h = cropped.size
    max_side = max(w, h)
    
    # Target scale
    scale = (target_size - (pad_px * 2)) / max_side
    new_w = max(1, int(round(w * scale)))
    new_h = max(1, int(round(h * scale)))
    
    resized = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    out = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
    x = (target_size - new_w) // 2
    y = (target_size - new_h) // 2
    out.paste(resized, (x, y))
    return out

# ==========================================
# 1. CEK STUNTING - UPRIGHT INFANT SCALE + TAPE + BADGE
# ==========================================
def draw_cek_stunting():
    img = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    stroke_w = 26
    
    # Tight contact shadow
    s_img = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(s_img)
    s_draw.ellipse([140, 840, 884, 930], fill=(210, 222, 235, 190))
    s_img = s_img.filter(ImageFilter.GaussianBlur(radius=28))
    img.alpha_composite(s_img)
    
    draw = ImageDraw.Draw(img)
    
    # Scale Dimensions (Upright / Straight)
    # A) Infant Tray (Top): Wide curved cradle tray
    tray_pts = [
        (130, 280), (190, 400),
        (834, 400), (894, 280),
        (830, 240), (512, 270), (194, 240)
    ]
    # Tray back/depth
    draw.polygon([(x, y + 25) for x, y in tray_pts], fill=(225, 235, 245, 255))
    draw.line([(x, y + 25) for x, y in tray_pts] + [(tray_pts[0][0], tray_pts[0][1] + 25)], fill=OUTLINE, width=stroke_w, joint="curve")
    # Tray front (Clean White)
    draw.polygon(tray_pts, fill=WHITE)
    draw.line(tray_pts + [tray_pts[0]], fill=OUTLINE, width=stroke_w, joint="curve")
    # Tray inner cradle line
    draw.line([(240, 310), (512, 335), (784, 310)], fill=(203, 213, 225, 255), width=18, joint="curve")
    
    # B) Scale Main Body (Bottom): Rounded sturdy base
    base_box = [200, 380, 824, 780]
    # 3D Depth bottom
    draw.rounded_rectangle([base_box[0], base_box[1] + 40, base_box[2], base_box[3] + 40], radius=50, fill=CYAN_DARK)
    draw.line([(base_box[0] + 50, base_box[3] + 40), (base_box[2] - 50, base_box[3] + 40)], fill=OUTLINE, width=stroke_w)
    
    # Front body (Cyan Blue #29A9E1)
    draw.rounded_rectangle(base_box, radius=50, fill=CYAN_MAIN, outline=OUTLINE, width=stroke_w)
    
    # White glossy reflection pill on scale body
    draw.rounded_rectangle([250, 405, 774, 428], radius=11, fill=WHITE)
    
    # C) Digital Display (Center)
    disp_box = [312, 470, 712, 630]
    draw.rounded_rectangle(disp_box, radius=24, fill=(24, 38, 56, 255), outline=OUTLINE, width=20)
    # LCD Digits pill / indicator: Green glow text or pill
    draw.rounded_rectangle([350, 520, 560, 580], radius=12, fill=(16, 185, 129, 255))
    # Digits "8.5" representation in white
    draw.line([(390, 535), (390, 565)], fill=WHITE, width=8)
    draw.line([(450, 535), (450, 565)], fill=WHITE, width=8)
    draw.ellipse([480, 560, 492, 572], fill=WHITE) # dot
    draw.line([(520, 535), (520, 565)], fill=WHITE, width=8)
    # Unit pill "kg"
    draw.rounded_rectangle([580, 530, 670, 570], radius=10, fill=(41, 169, 225, 255))
    
    # D) Measuring Tape (Wrapped across lower base)
    tape_pts = [
        (160, 680), (320, 680), (380, 730), (740, 730), (840, 670), (880, 720), (740, 790), (360, 790), (160, 740)
    ]
    # Simpler horizontal measuring tape wrapped across base
    tape_box = [160, 670, 864, 760]
    draw.rounded_rectangle(tape_box, radius=24, fill=YELLOW_STAR, outline=OUTLINE, width=stroke_w)
    # Ticks on measuring tape
    for tx in range(210, 820, 36):
        th = 28 if (tx % 72 == 0) else 16
        draw.line([(tx, 670), (tx, 670 + th)], fill=OUTLINE, width=10)
    
    # E) Green Checkmark Badge (Bottom Right)
    bcx, bcy, br = 760, 660, 95
    # Badge shadow
    draw.ellipse([bcx - br, bcy - br + 12, bcx + br, bcy + br + 12], fill=(10, 120, 80, 255))
    # Badge body
    draw.ellipse([bcx - br, bcy - br, bcx + br, bcy + br], fill=GREEN_LIME, outline=OUTLINE, width=stroke_w)
    # White checkmark
    chk_pts = [(bcx - 45, bcy - 5), (bcx - 15, bcy + 35), (bcx + 45, bcy - 35)]
    draw.line(chk_pts, fill=WHITE, width=24, joint="curve")
    
    return crop_tight_and_resize(img)

# ==========================================
# 2. GRAFIK PERTUMBUHAN - UPRIGHT CLIPBOARD + RISING CURVE + STAR
# ==========================================
def draw_grafik_pertumbuhan():
    img = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    stroke_w = 26
    
    s_img = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(s_img)
    s_draw.ellipse([210, 860, 814, 950], fill=(210, 222, 235, 190))
    s_img = s_img.filter(ImageFilter.GaussianBlur(radius=30))
    img.alpha_composite(s_img)
    
    draw = ImageDraw.Draw(img)
    
    # Clipboard Dimensions (Upright / Straight)
    board_w, board_h = 580, 740
    bx = (CANVAS_SIZE - board_w) // 2
    by = 140
    cr = 54
    
    # 3D Depth bottom/right
    draw.rounded_rectangle([bx, by + 30, bx + board_w, by + board_h + 30], radius=cr, fill=(18, 26, 36, 255))
    
    # Front board (Slate Navy #243342)
    draw.rounded_rectangle([bx, by, bx + board_w, by + board_h], radius=cr, fill=(36, 51, 66, 255), outline=OUTLINE, width=stroke_w)
    
    # Inner White Paper Sheet
    pw = 480
    px = (CANVAS_SIZE - pw) // 2
    py = by + 65
    ph = board_h - 100
    pr = 34
    draw.rounded_rectangle([px, py + 8, px + pw, py + ph + 8], radius=pr, fill=(226, 232, 240, 255))
    draw.rounded_rectangle([px, py, px + pw, py + ph], radius=pr, fill=WHITE, outline=OUTLINE, width=stroke_w)
    
    # Top Clip (Cyan Blue #29A9E1)
    clip_w, clip_h = 240, 75
    cx = (CANVAS_SIZE - clip_w) // 2
    cy = by - 10
    # Clip ring
    draw.ellipse([CANVAS_SIZE//2 - 32, cy - 25, CANVAS_SIZE//2 + 32, cy + 39], fill=WHITE, outline=OUTLINE, width=stroke_w)
    draw.ellipse([CANVAS_SIZE//2 - 14, cy - 7, CANVAS_SIZE//2 + 14, cy + 21], fill=(36, 51, 66, 255))
    # Clip body
    draw.rounded_rectangle([cx, cy + 15, cx + clip_w, cy + 15 + clip_h], radius=22, fill=CYAN_MAIN, outline=OUTLINE, width=stroke_w)
    draw.rounded_rectangle([cx + 25, cy + 26, cx + clip_w - 25, cy + 42], radius=8, fill=WHITE)
    
    # Graph area inside paper:
    # Grid dotted/dashed lines
    for gy in [py + 180, py + 290, py + 400]:
        draw.line([(px + 40, gy), (px + pw - 40, gy)], fill=(226, 232, 240, 255), width=10)
        
    # Filled area under the curve (Soft pastel rainbow bands)
    curve_pts = [
        (px + 60, py + 470),
        (px + 160, py + 380),
        (px + 270, py + 410),
        (px + 360, py + 260),
        (px + 410, py + 160)
    ]
    
    # Draw pastel polygon fill under curve
    poly_fill = [(px + 60, py + 520)] + curve_pts + [(px + 410, py + 520)]
    draw.polygon(poly_fill, fill=(234, 246, 255, 255))
    
    # Rising curve line (Slate navy bold)
    draw.line(curve_pts, fill=OUTLINE, width=22, joint="curve")
    
    # Arrow head at the end of curve
    arr_x, arr_y = curve_pts[-1]
    draw.polygon([(arr_x - 15, arr_y + 40), (arr_x, arr_y), (arr_x - 40, arr_y + 15)], fill=OUTLINE)
    
    # Colorful node dots along curve
    nodes = [
        (curve_pts[0], CYAN_MAIN),
        (curve_pts[1], GREEN_LIME),
        (curve_pts[2], (59, 130, 246, 255)),
        (curve_pts[3], (249, 115, 22, 255)),
    ]
    for (nx, ny), ncol in nodes:
        draw.ellipse([nx - 24, ny - 24, nx + 24, ny + 24], fill=ncol, outline=OUTLINE, width=14)
        draw.ellipse([nx - 6, ny - 6, nx + 6, ny + 6], fill=WHITE)
        
    # Green Sprout Leaves on second node
    sp_x, sp_y = curve_pts[1][0], curve_pts[1][1] - 40
    draw.ellipse([sp_x - 22, sp_y - 28, sp_x + 5, sp_y + 5], fill=GREEN_LIME, outline=OUTLINE, width=12)
    draw.ellipse([sp_x + 5, sp_y - 32, sp_x + 32, sp_y - 2], fill=GREEN_LIME, outline=OUTLINE, width=12)
    
    # Cheerful Smiling Star at the top of the curve
    stx, sty = curve_pts[-1][0] - 10, curve_pts[-1][1] - 15
    draw_star(draw, stx, sty, r_out=85, r_in=38, fill=YELLOW_STAR, outline=OUTLINE, stroke_w=22)
    # Smiling face on star
    draw.ellipse([stx - 24, sty - 8, stx - 12, sty + 4], fill=OUTLINE)
    draw.ellipse([stx + 12, sty - 8, stx + 24, sty + 4], fill=OUTLINE)
    draw.arc([stx - 16, sty - 2, stx + 16, sty + 18], start=10, end=170, fill=OUTLINE, width=12)
    
    return crop_tight_and_resize(img)

# ==========================================
# 3. RESEP MPASI - UPRIGHT BOWL + SPOON + CARROT & AVOCADO
# ==========================================
def draw_resep_mpasi():
    img = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    stroke_w = 26
    
    s_img = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(s_img)
    s_draw.ellipse([140, 830, 884, 940], fill=(210, 222, 235, 190))
    s_img = s_img.filter(ImageFilter.GaussianBlur(radius=32))
    img.alpha_composite(s_img)
    
    draw = ImageDraw.Draw(img)
    
    # Upright friendly MPASI bowl:
    # Centered horizontally, completely level!
    bx, by = 512, 570
    bw, bh = 340, 190
    
    # Steam swirls above bowl
    for sx in [440, 520, 600]:
        draw.arc([sx - 25, 230, sx + 25, 310], start=180, end=360, fill=(180, 200, 220, 255), width=16)
        draw.arc([sx - 25, 270, sx + 25, 350], start=0, end=180, fill=(180, 200, 220, 255), width=16)
        
    # Bowl Body: Bottom hemisphere
    # 3D shadow bottom
    draw.pieslice([bx - bw, by - bh + 35, bx + bw, by + bh + 35], start=0, end=180, fill=ORANGE_DARK)
    draw.arc([bx - bw, by - bh + 35, bx + bw, by + bh + 35], start=0, end=180, fill=OUTLINE, width=stroke_w)
    
    # Front Bowl Body (Warm Coral/Orange #F97316)
    draw.pieslice([bx - bw, by - bh, bx + bw, by + bh], start=0, end=180, fill=ORANGE_MPASI)
    draw.arc([bx - bw, by - bh, bx + bw, by + bh], start=0, end=180, fill=OUTLINE, width=stroke_w)
    
    # Bowl Rim (Ellipse on top)
    rim_h = 100
    draw.ellipse([bx - bw, by - rim_h, bx + bw, by + rim_h], fill=(240, 248, 255, 255), outline=OUTLINE, width=stroke_w)
    
    # Warm nutritious porridge inside rim
    pw, ph = bw - 35, rim_h - 18
    draw.ellipse([bx - pw, by - ph, bx + pw, by + ph], fill=YELLOW_STAR, outline=OUTLINE, width=18)
    # Porridge surface swirl
    draw.arc([bx - pw + 50, by - ph + 15, bx + pw - 50, by + ph - 15], start=20, end=160, fill=(245, 158, 11, 255), width=24)
    # White glossy reflection on porridge
    draw.arc([bx - pw + 30, by - ph + 10, bx - pw + 130, by + ph - 10], start=160, end=270, fill=WHITE, width=16)
    
    # White Infant Spoon resting in bowl (angled gently into bowl)
    sp_poly = [
        (560, 310), (740, 180), (790, 230), (640, 420), (540, 440)
    ]
    # Spoon handle & head
    draw.polygon(sp_poly, fill=WHITE)
    draw.line(sp_poly + [sp_poly[0]], fill=OUTLINE, width=stroke_w, joint="curve")
    draw.ellipse([510, 390, 630, 480], fill=WHITE, outline=OUTLINE, width=stroke_w)
    # Light cyan inner spoon scoop
    draw.ellipse([535, 405, 605, 465], fill=(224, 242, 254, 255))
    
    # Fresh Avocado Slice (Right front)
    av_cx, av_cy = 740, 680
    draw.ellipse([av_cx - 90, av_cy - 70, av_cx + 90, av_cy + 70], fill=(21, 128, 61, 255), outline=OUTLINE, width=stroke_w)
    draw.ellipse([av_cx - 75, av_cy - 55, av_cx + 75, av_cy + 55], fill=(163, 230, 53, 255), outline=OUTLINE, width=16)
    draw.ellipse([av_cx - 45, av_cy - 35, av_cx + 45, av_cy + 35], fill=(120, 53, 15, 255), outline=OUTLINE, width=16)
    
    # Fresh Carrot (Left front)
    car_poly = [
        (220, 720), (380, 630), (440, 690)
    ]
    draw.polygon(car_poly, fill=(249, 115, 22, 255))
    draw.line(car_poly + [car_poly[0]], fill=OUTLINE, width=stroke_w, joint="curve")
    # Carrot stripes
    draw.line([(310, 680), (350, 660)], fill=OUTLINE, width=12)
    draw.line([(360, 710), (400, 690)], fill=OUTLINE, width=12)
    # Carrot leafy greens
    draw.ellipse([160, 710, 220, 760], fill=GREEN_LIME, outline=OUTLINE, width=stroke_w)
    draw.ellipse([140, 660, 200, 710], fill=GREEN_LIME, outline=OUTLINE, width=stroke_w)
    draw.ellipse([180, 640, 240, 690], fill=GREEN_LIME, outline=OUTLINE, width=stroke_w)
    
    return crop_tight_and_resize(img)

# ==========================================
# 4. ARTIKEL KESEHATAN - UPRIGHT JOURNAL + SHIELD + BOOKMARK
# ==========================================
def draw_artikel_kesehatan():
    img = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    stroke_w = 26
    
    s_img = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(s_img)
    s_draw.ellipse([210, 860, 814, 950], fill=(210, 222, 235, 190))
    s_img = s_img.filter(ImageFilter.GaussianBlur(radius=30))
    img.alpha_composite(s_img)
    
    draw = ImageDraw.Draw(img)
    
    # Upright / Straight Health Journal
    book_w, book_h = 580, 740
    bx = (CANVAS_SIZE - book_w) // 2
    by = 140
    cr = 54
    
    # 3D Depth bottom/left
    draw.rounded_rectangle([bx, by + 30, bx + book_w, by + book_h + 30], radius=cr, fill=(22, 78, 124, 255), outline=OUTLINE, width=stroke_w)
    
    # Front cover: Vibrant Sky Cyan (#29A9E1)
    draw.rounded_rectangle([bx, by, bx + book_w, by + book_h], radius=cr, fill=CYAN_MAIN, outline=OUTLINE, width=stroke_w)
    
    # Spine line on left
    draw.line([(bx + 80, by), (bx + 80, by + book_h)], fill=OUTLINE, width=20)
    # White glossy highlight on spine
    draw.line([(bx + 40, by + 40), (bx + 40, by + book_h - 40)], fill=WHITE, width=14)
    
    # Inner White Article Sheet
    pw = 430
    px = bx + 110
    py = by + 45
    ph = book_h - 90
    pr = 32
    draw.rounded_rectangle([px, py, px + pw, py + ph], radius=pr, fill=WHITE, outline=OUTLINE, width=22)
    
    # Hanging Red Ribbon Bookmark from top
    rb_w = 56
    rb_x = px + 60
    rb_pts = [(rb_x, by), (rb_x + rb_w, by), (rb_x + rb_w, py + 140), (rb_x + rb_w//2, py + 105), (rb_x, py + 140)]
    draw.polygon(rb_pts, fill=RED_CORAL)
    draw.line(rb_pts + [rb_pts[0]], fill=OUTLINE, width=18, joint="curve")
    
    # Smooth Red Medical Shield with Cross (Centered on paper)
    sh_cx = px + pw // 2 + 10
    sh_cy = py + 200
    sh_w, sh_h = 100, 115
    
    # Draw smooth shield
    shield_pts = [
        (sh_cx - sh_w, sh_cy - sh_h),
        (sh_cx, sh_cy - sh_h + 16),
        (sh_cx + sh_w, sh_cy - sh_h),
        (sh_cx + sh_w, sh_cy + 10),
        (sh_cx, sh_cy + sh_h),
        (sh_cx - sh_w, sh_cy + 10),
    ]
    draw.polygon(shield_pts, fill=RED_CORAL)
    draw.line(shield_pts + [shield_pts[0]], fill=OUTLINE, width=stroke_w, joint="curve")
    
    # White Medical Cross in center
    cw, ch = 22, 60
    draw.rounded_rectangle([sh_cx - cw, sh_cy - ch + 12, sh_cx + cw, sh_cy + ch + 12], radius=10, fill=WHITE)
    draw.rounded_rectangle([sh_cx - ch, sh_cy - cw + 12, sh_cx + ch, sh_cy + cw + 12], radius=10, fill=WHITE)
    
    # Shield highlight arc
    draw.arc([sh_cx - sh_w + 16, sh_cy - sh_h + 20, sh_cx - sh_w + 50, sh_cy + 10], start=120, end=250, fill=WHITE, width=12)
    
    # Headline bar (Cyan + Green)
    draw.rounded_rectangle([px + 35, py + 360, px + 260, py + 390], radius=15, fill=CYAN_MAIN)
    draw.rounded_rectangle([px + 280, py + 360, px + 350, py + 390], radius=15, fill=GREEN_LIME)
    
    # Article text lines (Soft Blue-Gray)
    for ly in [py + 425, py + 475, py + 525]:
        draw.rounded_rectangle([px + 35, ly, px + pw - 35, ly + 22], radius=11, fill=PAPER_LINE)
    draw.rounded_rectangle([px + 35, py + 575, px + pw - 140, py + 575 + 22], radius=11, fill=PAPER_LINE)
    
    # Cheerful Smiling Star at the top right of book
    stx, sty = bx + book_w - 15, by + 10
    draw_star(draw, stx, sty, r_out=75, r_in=34, fill=YELLOW_STAR, outline=OUTLINE, stroke_w=20)
    draw.ellipse([stx - 20, sty - 8, stx - 10, sty + 4], fill=OUTLINE)
    draw.ellipse([stx + 10, sty - 8, stx + 20, sty + 4], fill=OUTLINE)
    draw.arc([stx - 14, sty - 2, stx + 14, sty + 14], start=10, end=170, fill=OUTLINE, width=10)
    
    return crop_tight_and_resize(img)

# ==========================================
# 5. PERMAINAN - UPRIGHT HANDHELD CONSOLE + STAR
# ==========================================
def draw_permainan():
    img = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    stroke_w = 26
    
    s_img = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(s_img)
    s_draw.ellipse([140, 820, 884, 930], fill=(210, 222, 235, 190))
    s_img = s_img.filter(ImageFilter.GaussianBlur(radius=32))
    img.alpha_composite(s_img)
    
    draw = ImageDraw.Draw(img)
    
    # Console Dimensions (Upright / Straight Horizontal)
    cw, ch = 780, 480
    cx = (CANVAS_SIZE - cw) // 2
    cy = 340
    cr = 64
    
    # 3D Depth bottom
    draw.rounded_rectangle([cx, cy + 35, cx + cw, cy + ch + 35], radius=cr, fill=CYAN_DARK)
    draw.line([(cx + cr, cy + ch + 35), (cx + cw - cr, cy + ch + 35)], fill=OUTLINE, width=stroke_w)
    
    # Front Body (Cyan Blue #29A9E1)
    draw.rounded_rectangle([cx, cy, cx + cw, cy + ch], radius=cr, fill=CYAN_MAIN, outline=OUTLINE, width=stroke_w)
    
    # White glossy reflection pill on top edge
    draw.rounded_rectangle([cx + 60, cy + 18, cx + cw - 60, cy + 36], radius=9, fill=WHITE)
    
    # Center Screen: Slate Navy bezel + bright screen
    sc_w, sc_h = 350, 270
    sc_x = (CANVAS_SIZE - sc_w) // 2
    sc_y = cy + (ch - sc_h) // 2 - 10
    
    # Bezel
    draw.rounded_rectangle([sc_x - 18, sc_y - 18, sc_x + sc_w + 18, sc_y + sc_h + 18], radius=32, fill=OUTLINE)
    
    # Screen glass (Dark navy blue / game screen)
    draw.rounded_rectangle([sc_x, sc_y, sc_x + sc_w, sc_y + sc_h], radius=20, fill=(24, 38, 56, 255))
    
    # Game star hero on screen
    draw_star(draw, CANVAS_SIZE//2, sc_y + sc_h//2, r_out=72, r_in=34, fill=YELLOW_STAR, outline=WHITE, stroke_w=12)
    # Smile on game star
    gstx, gsty = CANVAS_SIZE//2, sc_y + sc_h//2
    draw.ellipse([gstx - 18, gsty - 8, gstx - 8, gsty + 2], fill=OUTLINE)
    draw.ellipse([gstx + 8, gsty - 8, gstx + 18, gsty + 2], fill=OUTLINE)
    draw.arc([gstx - 12, gsty - 2, gstx + 12, gsty + 14], start=10, end=170, fill=OUTLINE, width=8)
    # Green platform under star
    draw.rounded_rectangle([sc_x + 60, sc_y + sc_h - 35, sc_x + sc_w - 60, sc_y + sc_h - 15], radius=8, fill=GREEN_LIME)
    
    # Left Controls: D-PAD Cross
    dpx = cx + 105
    dpy = cy + ch // 2 - 10
    dw, dh = 22, 68
    draw.rounded_rectangle([dpx - dw, dpy - dh, dpx + dw, dpy + dh], radius=12, fill=OUTLINE)
    draw.rounded_rectangle([dpx - dh, dpy - dw, dpx + dh, dpy + dw], radius=12, fill=OUTLINE)
    draw.ellipse([dpx - 10, dpy - 10, dpx + 10, dpy + 10], fill=(60, 75, 95, 255))
    # Little thumbstick below D-pad
    draw.ellipse([dpx - 28, dpy + 90, dpx + 28, dpy + 146], fill=CYAN_DARK, outline=OUTLINE, width=14)
    draw.ellipse([dpx - 18, dpy + 100, dpx + 18, dpy + 136], fill=WHITE)
    
    # Right Controls: 4 Colorful Candy Buttons
    r_cx = cx + cw - 105
    r_cy = cy + ch // 2 - 10
    b_dist = 44
    br = 18
    btns = [
        (r_cx, r_cy - b_dist, RED_CORAL),
        (r_cx + b_dist, r_cy, YELLOW_STAR),
        (r_cx, r_cy + b_dist, GREEN_LIME),
        (r_cx - b_dist, r_cy, PURPLE_BTN),
    ]
    for bx, by, bcol in btns:
        draw.ellipse([bx - br, by - br, bx + br, by + br], fill=bcol, outline=OUTLINE, width=12)
        draw.ellipse([bx - br + 5, by - br + 5, bx - br + 12, by - br + 12], fill=WHITE)
    # Right thumbstick below buttons
    draw.ellipse([r_cx - 28, r_cy + 90, r_cx + 28, r_cy + 146], fill=CYAN_DARK, outline=OUTLINE, width=14)
    draw.ellipse([r_cx - 18, r_cy + 100, r_cx + 18, r_cy + 136], fill=WHITE)
    
    # Big Floating Achievement Star centered on top of console
    fst_x, fst_y = CANVAS_SIZE // 2, cy - 130
    draw_star(draw, fst_x, fst_y, r_out=110, r_in=50, fill=YELLOW_STAR, outline=OUTLINE, stroke_w=24)
    draw.ellipse([fst_x - 32, fst_y - 12, fst_x - 16, fst_y + 4], fill=OUTLINE)
    draw.ellipse([fst_x + 16, fst_y - 12, fst_x + 32, fst_y + 4], fill=OUTLINE)
    draw.arc([fst_x - 20, fst_y - 4, fst_x + 20, fst_y + 22], start=10, end=170, fill=OUTLINE, width=14)
    # Cheeks
    draw.ellipse([fst_x - 46, fst_y + 8, fst_x - 30, fst_y + 20], fill=(248, 113, 113, 180))
    draw.ellipse([fst_x + 30, fst_y + 8, fst_x + 46, fst_y + 20], fill=(248, 113, 113, 180))
    # Sparkles
    draw.line([(fst_x + 120, fst_y - 55), (fst_x + 155, fst_y - 55)], fill=YELLOW_STAR, width=10)
    draw.line([(fst_x + 138, fst_y - 72), (fst_x + 138, fst_y - 38)], fill=YELLOW_STAR, width=10)
    
    return crop_tight_and_resize(img)

if __name__ == "__main__":
    out_dir = r"C:\GIT\Pediagrow\scratch\upright_icons"
    import os
    os.makedirs(out_dir, exist_ok=True)
    
    draw_cek_stunting().save(os.path.join(out_dir, "cek_stunting_logo.png"))
    draw_grafik_pertumbuhan().save(os.path.join(out_dir, "grafik_pertumbuhan_logo.png"))
    draw_resep_mpasi().save(os.path.join(out_dir, "resep_mpasi_logo.png"))
    draw_artikel_kesehatan().save(os.path.join(out_dir, "artikel_kesehatan_logo.png"))
    draw_permainan().save(os.path.join(out_dir, "permainan_logo.png"))
    print("All 5 upright icons generated successfully!")
