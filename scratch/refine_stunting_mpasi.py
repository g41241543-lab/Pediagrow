import math
from PIL import Image, ImageDraw, ImageFilter

CANVAS_SIZE = 1024
OUTLINE = (32, 41, 56, 255)       # Slate navy #202938
CYAN_MAIN = (41, 169, 225, 255)   # #29A9E1
CYAN_LIGHT = (224, 242, 254, 255) # Light blue accent
CYAN_DARK = (24, 88, 140, 255)    # 3D shadow blue
RED_CORAL = (239, 68, 68, 255)    # #EF4444
YELLOW_STAR = (251, 191, 36, 255) # #FBBF24
GREEN_LIME = (16, 185, 129, 255)  # #10B981
ORANGE_MPASI = (249, 115, 22, 255) # #F97316
ORANGE_DARK = (194, 65, 12, 255)
WHITE = (255, 255, 255, 255)
PAPER_LINE = (203, 213, 225, 255)

def crop_tight_and_resize(img, target_size=128, pad_px=4):
    bbox = img.getbbox()
    if not bbox:
        return img.resize((target_size, target_size))
    cropped = img.crop(bbox)
    w, h = cropped.size
    max_side = max(w, h)
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
# REFINED CEK STUNTING: SMOOTH BABY SCALE
# ==========================================
def draw_refined_cek_stunting():
    img = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    stroke_w = 26
    
    # Ground shadow
    s_img = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(s_img)
    s_draw.ellipse([140, 840, 884, 940], fill=(210, 222, 235, 190))
    s_img = s_img.filter(ImageFilter.GaussianBlur(radius=30))
    img.alpha_composite(s_img)
    
    draw = ImageDraw.Draw(img)
    
    # A) Infant Scale Tray (Curved cradle tray with smooth rounded lip)
    # Tray width: 780, height: 180
    tcx = CANVAS_SIZE // 2
    tcy = 300
    
    # Tray 3D edge
    draw.ellipse([tcx - 390, tcy - 80 + 35, tcx + 390, tcy + 130 + 35], fill=(215, 228, 240, 255))
    draw.arc([tcx - 390, tcy - 80 + 35, tcx + 390, tcy + 130 + 35], start=0, end=180, fill=OUTLINE, width=stroke_w)
    
    # Tray front body (Clean white curved basin)
    draw.ellipse([tcx - 390, tcy - 80, tcx + 390, tcy + 130], fill=WHITE, outline=OUTLINE, width=stroke_w)
    # Inner basin scoop line
    draw.arc([tcx - 320, tcy - 60, tcx + 320, tcy + 80], start=20, end=160, fill=(210, 225, 238, 255), width=18)
    
    # B) Scale Base Body (Solid rounded rectangular console)
    bx = 200
    by = 400
    bw = 624
    bh = 380
    br = 54
    
    # 3D Depth bottom
    draw.rounded_rectangle([bx, by + 40, bx + bw, by + bh + 40], radius=br, fill=CYAN_DARK)
    draw.line([(bx + br, by + bh + 40), (bx + bw - br, by + bh + 40)], fill=OUTLINE, width=stroke_w)
    
    # Front Body (Vibrant Sky Blue #29A9E1)
    draw.rounded_rectangle([bx, by, bx + bw, by + bh], radius=br, fill=CYAN_MAIN, outline=OUTLINE, width=stroke_w)
    # Glossy reflection line on top
    draw.rounded_rectangle([bx + 40, by + 22, bx + bw - 40, by + 40], radius=9, fill=WHITE)
    
    # C) Digital LCD Screen (Center)
    sx = bx + 90
    sy = by + 70
    sw = bw - 180
    sh = 150
    draw.rounded_rectangle([sx, sy, sx + sw, sy + sh], radius=24, fill=(24, 38, 56, 255), outline=OUTLINE, width=20)
    
    # Screen display: Bright glowing green pill with "8.5 kg" baby weight
    draw.rounded_rectangle([sx + 35, sy + 35, sx + sw - 120, sy + sh - 35], radius=16, fill=GREEN_LIME)
    # Digits line representation in white
    draw.line([(sx + 70, sy + 55), (sx + 70, sy + 95)], fill=WHITE, width=12)
    draw.line([(sx + 130, sy + 55), (sx + 130, sy + 95)], fill=WHITE, width=12)
    draw.ellipse([sx + 165, sy + 85, sx + 177, sy + 97], fill=WHITE)
    draw.line([(sx + 210, sy + 55), (sx + 210, sy + 95)], fill=WHITE, width=12)
    
    # Unit badge "kg"
    draw.rounded_rectangle([sx + sw - 95, sy + 45, sx + sw - 25, sy + sh - 45], radius=12, fill=CYAN_MAIN)
    
    # D) Yellow Measuring Tape along bottom of scale
    tape_box = [170, 670, 854, 765]
    draw.rounded_rectangle(tape_box, radius=24, fill=YELLOW_STAR, outline=OUTLINE, width=stroke_w)
    # Tape measure ticks
    for tx in range(210, 820, 36):
        th = 30 if (tx % 72 == 0) else 16
        draw.line([(tx, 670), (tx, 670 + th)], fill=OUTLINE, width=10)
        
    # E) Green Health Checkmark Badge (Bottom Right)
    bcx, bcy, br = 760, 670, 95
    # Badge shadow
    draw.ellipse([bcx - br, bcy - br + 12, bcx + br, bcy + br + 12], fill=(10, 120, 80, 255))
    draw.ellipse([bcx - br, bcy - br, bcx + br, bcy + br], fill=GREEN_LIME, outline=OUTLINE, width=stroke_w)
    # White checkmark
    chk_pts = [(bcx - 45, bcy - 5), (bcx - 15, bcy + 35), (bcx + 45, bcy - 35)]
    draw.line(chk_pts, fill=WHITE, width=24, joint="curve")
    
    return crop_tight_and_resize(img)

# ==========================================
# REFINED RESEP MPASI: DELICIOUS UPRIGHT BOWL
# ==========================================
def draw_refined_resep_mpasi():
    img = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    stroke_w = 26
    
    s_img = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(s_img)
    s_draw.ellipse([140, 840, 884, 940], fill=(210, 222, 235, 190))
    s_img = s_img.filter(ImageFilter.GaussianBlur(radius=32))
    img.alpha_composite(s_img)
    
    draw = ImageDraw.Draw(img)
    
    # A) Steam swirls above bowl (Centered)
    for sx, sy in [(440, 210), (512, 170), (584, 210)]:
        draw.arc([sx - 24, sy, sx + 24, sy + 70], start=180, end=360, fill=(185, 210, 230, 255), width=16)
        draw.arc([sx - 24, sy + 40, sx + 24, sy + 110], start=0, end=180, fill=(185, 210, 230, 255), width=16)
        
    # B) Main Bowl
    # Deep ceramic baby bowl (Upright, level)
    cx, cy = 512, 480
    rx = 360 # Bowl rim semi-major axis
    ry = 110 # Bowl rim semi-minor axis
    depth = 260 # Height of bowl basin
    
    # Bowl basin bottom hemisphere
    # 3D shadow bottom rim
    draw.pieslice([cx - rx, cy - ry + 40, cx + rx, cy + depth + 40], start=0, end=180, fill=ORANGE_DARK)
    draw.arc([cx - rx, cy - ry + 40, cx + rx, cy + depth + 40], start=0, end=180, fill=OUTLINE, width=stroke_w)
    
    # Bowl front basin (Warm Coral Orange #F97316)
    draw.pieslice([cx - rx, cy - ry, cx + rx, cy + depth], start=0, end=180, fill=ORANGE_MPASI)
    draw.arc([cx - rx, cy - ry, cx + rx, cy + depth], start=0, end=180, fill=OUTLINE, width=stroke_w)
    
    # Bowl outer white rim
    draw.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=(245, 250, 255, 255), outline=OUTLINE, width=stroke_w)
    
    # Porridge surface (Warm golden puree)
    prx, pry = rx - 35, ry - 18
    draw.ellipse([cx - prx, cy - pry, cx + prx, cy + pry], fill=YELLOW_STAR, outline=OUTLINE, width=18)
    # Porridge swirl texture
    draw.arc([cx - prx + 60, cy - pry + 12, cx + prx - 60, cy + pry - 12], start=20, end=160, fill=(245, 158, 11, 255), width=24)
    # White glossy shine
    draw.arc([cx - prx + 40, cy - pry + 8, cx - prx + 140, cy + pry - 8], start=160, end=270, fill=WHITE, width=16)
    
    # C) Smooth Baby Spoon (Resting in the bowl with rounded handle)
    # Dipping from upper right into porridge
    sp_h_pts = [
        (660, 240), (790, 140), (840, 190), (710, 310)
    ]
    draw.polygon(sp_h_pts, fill=WHITE)
    draw.line(sp_h_pts + [sp_h_pts[0]], fill=OUTLINE, width=stroke_w, joint="curve")
    # Spoon scoop head (dipping in porridge)
    draw.ellipse([580, 260, 710, 370], fill=WHITE, outline=OUTLINE, width=stroke_w)
    draw.ellipse([605, 280, 685, 350], fill=CYAN_LIGHT)
    
    # D) Fresh Carrot (Sitting in front left)
    c_pts = [(240, 720), (430, 620), (460, 680)]
    draw.polygon(c_pts, fill=(249, 115, 22, 255))
    draw.line(c_pts + [c_pts[0]], fill=OUTLINE, width=stroke_w, joint="curve")
    draw.line([(330, 680), (370, 655)], fill=OUTLINE, width=14)
    draw.line([(380, 700), (420, 675)], fill=OUTLINE, width=14)
    # Carrot bushy greens
    draw.ellipse([180, 700, 245, 755], fill=GREEN_LIME, outline=OUTLINE, width=stroke_w)
    draw.ellipse([160, 645, 225, 700], fill=GREEN_LIME, outline=OUTLINE, width=stroke_w)
    draw.ellipse([210, 630, 275, 685], fill=GREEN_LIME, outline=OUTLINE, width=stroke_w)
    
    # E) Fresh Avocado Slice (Sitting in front right)
    av_x, av_y = 750, 680
    draw.ellipse([av_x - 90, av_y - 70, av_x + 90, av_y + 70], fill=(21, 128, 61, 255), outline=OUTLINE, width=stroke_w)
    draw.ellipse([av_x - 75, av_y - 55, av_x + 75, av_y + 55], fill=(163, 230, 53, 255), outline=OUTLINE, width=16)
    draw.ellipse([av_x - 45, av_y - 35, av_x + 45, av_y + 35], fill=(120, 53, 15, 255), outline=OUTLINE, width=16)
    
    return crop_tight_and_resize(img)

if __name__ == "__main__":
    out_dir = r"C:\GIT\Pediagrow\scratch\upright_icons"
    import os
    draw_refined_cek_stunting().save(os.path.join(out_dir, "cek_stunting_logo.png"))
    draw_refined_resep_mpasi().save(os.path.join(out_dir, "resep_mpasi_logo.png"))
    print("Refined Cek Stunting & Resep MPASI rendered successfully!")

