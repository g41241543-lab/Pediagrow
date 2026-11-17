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

def draw_perfect_resep_mpasi():
    img = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    stroke_w = 26
    
    # Ground shadow
    s_img = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(s_img)
    s_draw.ellipse([140, 840, 884, 940], fill=(210, 222, 235, 190))
    s_img = s_img.filter(ImageFilter.GaussianBlur(radius=32))
    img.alpha_composite(s_img)
    
    draw = ImageDraw.Draw(img)
    
    # Steam swirls
    for sx, sy in [(440, 210), (512, 170), (584, 210)]:
        draw.arc([sx - 24, sy, sx + 24, sy + 70], start=180, end=360, fill=(185, 210, 230, 255), width=16)
        draw.arc([sx - 24, sy + 40, sx + 24, sy + 110], start=0, end=180, fill=(185, 210, 230, 255), width=16)
        
    # Bowl parameters
    cx = 512
    rim_y = 480
    rx = 360 # horizontal radius
    ry = 120 # vertical rim radius
    bot_y = 750
    bot_w = 200 # base width
    
    # Bowl Body Polygon (Smooth ceramic curve from rim to base)
    # Generate points along bottom curve
    pts_body = []
    # Left rim point
    pts_body.append((cx - rx, rim_y))
    # Curve down to bottom base
    steps = 20
    for i in range(steps + 1):
        t = i / steps
        # Bezier from (cx - rx, rim_y) to (cx - bot_w, bot_y) with control point (cx - rx + 20, bot_y)
        x = (1 - t)**2 * (cx - rx) + 2 * (1 - t) * t * (cx - rx + 10) + t**2 * (cx - bot_w)
        y = (1 - t)**2 * rim_y + 2 * (1 - t) * t * (bot_y - 20) + t**2 * bot_y
        pts_body.append((x, y))
        
    # Across bottom base
    pts_body.append((cx + bot_w, bot_y))
    # Curve up to right rim point
    for i in range(steps + 1):
        t = i / steps
        x = (1 - t)**2 * (cx + bot_w) + 2 * (1 - t) * t * (cx + rx - 10) + t**2 * (cx + rx)
        y = (1 - t)**2 * bot_y + 2 * (1 - t) * t * (bot_y - 20) + t**2 * rim_y
        pts_body.append((x, y))
        
    # Front rim bottom half
    for i in range(steps + 1):
        angle = 0 + (i / steps) * math.pi
        pts_body.append((cx + rx * math.cos(angle), rim_y + ry * math.sin(angle)))
        
    # 3D shadow bottom base
    body_shadow = [(x, y + 35) for x, y in pts_body]
    draw.polygon(body_shadow, fill=ORANGE_DARK)
    draw.line(body_shadow + [body_shadow[0]], fill=OUTLINE, width=stroke_w, joint="curve")
    
    # Front bowl body
    draw.polygon(pts_body, fill=ORANGE_MPASI)
    draw.line(pts_body + [pts_body[0]], fill=OUTLINE, width=stroke_w, joint="curve")
    
    # Outer White Ceramic Rim (Ellipse)
    draw.ellipse([cx - rx, rim_y - ry, cx + rx, rim_y + ry], fill=(245, 250, 255, 255), outline=OUTLINE, width=stroke_w)
    
    # Delicious Golden Porridge inside rim
    prx = rx - 35
    pry = ry - 20
    draw.ellipse([cx - prx, rim_y - pry, cx + prx, rim_y + pry], fill=YELLOW_STAR, outline=OUTLINE, width=18)
    # Porridge surface swirl
    draw.arc([cx - prx + 50, rim_y - pry + 15, cx + prx - 50, rim_y + pry - 15], start=20, end=160, fill=(245, 158, 11, 255), width=24)
    # White glossy shine
    draw.arc([cx - prx + 40, rim_y - pry + 10, cx - prx + 140, rim_y + pry - 10], start=160, end=270, fill=WHITE, width=16)
    
    # Smooth Baby Spoon (dipping gracefully from top right into bowl)
    # Spoon handle points: gentle smooth curved neck
    sp_pts = [
        (650, rim_y - 60), (760, 230), (810, 260), (710, rim_y + 30)
    ]
    draw.polygon(sp_pts, fill=WHITE)
    draw.line(sp_pts + [sp_pts[0]], fill=OUTLINE, width=stroke_w, joint="curve")
    # Spoon head (round infant scoop)
    draw.ellipse([580, rim_y - 80, 700, rim_y + 40], fill=WHITE, outline=OUTLINE, width=stroke_w)
    draw.ellipse([605, rim_y - 60, 675, rim_y + 20], fill=CYAN_LIGHT)
    
    # Fresh Carrot (Sitting in front left)
    c_pts = [(200, 770), (410, 670), (440, 730)]
    draw.polygon(c_pts, fill=(249, 115, 22, 255))
    draw.line(c_pts + [c_pts[0]], fill=OUTLINE, width=stroke_w, joint="curve")
    draw.line([(290, 735), (330, 715)], fill=OUTLINE, width=14)
    draw.line([(340, 755), (380, 735)], fill=OUTLINE, width=14)
    # Carrot bushy greens
    draw.ellipse([140, 750, 205, 805], fill=GREEN_LIME, outline=OUTLINE, width=stroke_w)
    draw.ellipse([120, 695, 185, 750], fill=GREEN_LIME, outline=OUTLINE, width=stroke_w)
    draw.ellipse([170, 680, 235, 735], fill=GREEN_LIME, outline=OUTLINE, width=stroke_w)
    
    # Fresh Avocado Slice (Sitting in front right)
    av_x, av_y = 780, 730
    draw.ellipse([av_x - 90, av_y - 70, av_x + 90, av_y + 70], fill=(21, 128, 61, 255), outline=OUTLINE, width=stroke_w)
    draw.ellipse([av_x - 75, av_y - 55, av_x + 75, av_y + 55], fill=(163, 230, 53, 255), outline=OUTLINE, width=16)
    draw.ellipse([av_x - 45, av_y - 35, av_x + 45, av_y + 35], fill=(120, 53, 15, 255), outline=OUTLINE, width=16)
    
    return crop_tight_and_resize(img)

if __name__ == "__main__":
    out_path = r"C:\GIT\Pediagrow\scratch\upright_icons\resep_mpasi_logo.png"
    draw_perfect_resep_mpasi().save(out_path)
    print("Perfect bowl rendered!")

