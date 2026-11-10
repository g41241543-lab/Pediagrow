from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np
import os

pego_sources = {
    'Cek Stunting': r'C:\Users\zsptr\.gemini\antigravity\brain\d482e3d9-33b7-45ed-a771-f684ed63d57f\pego_cek_stunting_1794162673596.jpg',
    'Grafik Pertumbuhan': r'C:\Users\zsptr\.gemini\antigravity\brain\d482e3d9-33b7-45ed-a771-f684ed63d57f\pego_grafik_pertumbuhan_1794162859971.jpg',
    'Resep MPASI': r'C:\Users\zsptr\.gemini\antigravity\brain\d482e3d9-33b7-45ed-a771-f684ed63d57f\pego_resep_mpasi_1794162703072.jpg',
    'Artikel Kesehatan': r'C:\Users\zsptr\.gemini\antigravity\brain\d482e3d9-33b7-45ed-a771-f684ed63d57f\pego_artikel_kesehatan_1794162849061.jpg',
    'Lokasi Fasyankes': r'C:\Users\zsptr\.gemini\antigravity\brain\d482e3d9-33b7-45ed-a771-f684ed63d57f\pego_lokasi_fasyankes_clean_1794162733439.jpg',
    'Permainan': r'C:\Users\zsptr\.gemini\antigravity\brain\d482e3d9-33b7-45ed-a771-f684ed63d57f\pego_permainan_1794162838848.jpg',
}

transparent_dir = r'C:\Users\zsptr\.gemini\antigravity\brain\d482e3d9-33b7-45ed-a771-f684ed63d57f\pego_transparent_icons'
os.makedirs(transparent_dir, exist_ok=True)

transparent_images = {}

def make_transparent(img_path):
    im = Image.open(img_path).convert('RGBA')
    arr = np.array(im).astype(np.float32)
    
    # White background detection (flood fill or threshold from corners)
    # The background is solid pure white #FFFFFF
    r, g, b, a = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2], arr[:, :, 3]
    
    # Distance to pure white
    dist_to_white = np.sqrt((255.0 - r)**2 + (255.0 - g)**2 + (255.0 - b)**2)
    
    # Smooth alpha mask
    # dist < 12 => alpha 0
    # dist > 35 => alpha 255
    new_alpha = np.clip((dist_to_white - 10.0) / 25.0 * 255.0, 0, 255)
    
    # Only remove white connected to the outside (from border in)
    from scipy.ndimage import binary_fill_holes
    # background mask
    is_bg = (dist_to_white < 18.0)
    
    # Keep white inside the character (like robot face) intact!
    # Floodfill background starting from (0,0)
    from scipy.ndimage import label
    labeled, num_features = label(is_bg)
    # Background label is the one at corner (0,0)
    bg_label = labeled[0, 0]
    is_outer_bg = (labeled == bg_label)
    
    # Apply soft edge on outer background
    from scipy.ndimage import gaussian_filter
    outer_bg_soft = gaussian_filter(is_outer_bg.astype(np.float32), sigma=1.0)
    
    final_alpha = np.clip((1.0 - outer_bg_soft) * 255.0, 0, 255).astype(np.uint8)
    
    res_arr = arr.copy().astype(np.uint8)
    res_arr[:, :, 3] = final_alpha
    return Image.fromarray(res_arr)

# 1. Process all 6 images
for name, path in pego_sources.items():
    trans = make_transparent(path)
    file_key = name.lower().replace(' ', '_')
    out_path = os.path.join(transparent_dir, f'{file_key}.png')
    trans.save(out_path)
    transparent_images[name] = trans
    print(f'Processed {name} -> {out_path}')

# 2. Build Showcase Grid (Raw icons & App Card Simulation)
card_s = 200
cols = 3
rows = 2
pad = 20

show_w = cols * card_s + (cols + 1) * pad
show_h = rows * (card_s + 40) + (rows + 1) * pad

showcase = Image.new('RGB', (show_w, show_h), (255, 255, 255))
draw_s = ImageDraw.Draw(showcase)

try:
    font_title = ImageFont.truetype('arialbd.ttf', 16)
except:
    font_title = ImageFont.load_default()

items_list = list(transparent_images.items())
for idx, (title, img) in enumerate(items_list):
    r = idx // cols
    c = idx % cols
    x = pad + c * (card_s + pad)
    y = pad + r * (card_s + 40 + pad)
    
    # Paste resized icon
    s_img = img.resize((card_s, card_s), Image.Resampling.LANCZOS)
    showcase.paste(s_img, (x, y), s_img)
    
    # Title
    draw_s.text((x + 15, y + card_s + 10), title, fill=(30, 41, 59), font=font_title)

showcase.save(r'C:\Users\zsptr\.gemini\antigravity\brain\d482e3d9-33b7-45ed-a771-f684ed63d57f\pego_6_menu_icons_showcase.png')
print('Showcase saved to pego_6_menu_icons_showcase.png')

# 3. Simulate App Cards (Light Mode & Dark Mode)
def simulate_app_cards(mode='light'):
    is_dark = (mode == 'dark')
    app_card_s = 110
    grid_w = cols * app_card_s + (cols - 1) * 16 + 2 * 16
    grid_h = rows * (app_card_s + 42) + 20 + 2 * 16
    
    bg_color = (11, 16, 20) if is_dark else (255, 255, 255)
    canvas = Image.new('RGB', (grid_w, grid_h), bg_color)
    draw = ImageDraw.Draw(canvas)
    
    card_colors = {
        'Cek Stunting': (37, 99, 235) if not is_dark else (56, 189, 248),
        'Grafik Pertumbuhan': (13, 148, 136) if not is_dark else (45, 212, 191),
        'Resep MPASI': (234, 88, 12) if not is_dark else (251, 146, 60),
        'Artikel Kesehatan': (79, 70, 229) if not is_dark else (129, 140, 248),
        'Lokasi Fasyankes': (2, 132, 199) if not is_dark else (56, 189, 248),
        'Permainan': (217, 119, 6) if not is_dark else (251, 191, 36),
    }
    
    for idx, (title, img) in enumerate(items_list):
        r = idx // cols
        c = idx % cols
        x = 16 + c * (app_card_s + 16)
        y = 16 + r * (app_card_s + 42 + 20)
        
        card_fill = (21, 29, 35) if is_dark else (244, 248, 254)
        card_border = (44, 57, 67) if is_dark else (221, 233, 246)
        
        # Card rounded rect
        draw.rounded_rectangle([x, y, x + app_card_s, y + app_card_s], radius=14, fill=card_fill, outline=card_border, width=1)
        
        # Soft subtle colored podium behind icon
        accent = card_colors[title]
        cx = x + app_card_s // 2
        cy = y + app_card_s // 2
        pod_r = 30
        draw.ellipse([cx - pod_r, cy - pod_r, cx + pod_r, cy + pod_r], 
                     fill=(*accent, int(255 * (0.14 if is_dark else 0.08))),
                     outline=(*accent, int(255 * (0.30 if is_dark else 0.20))),
                     width=1)
        
        # Paste Robot Pego icon in center
        icon_size = 56 # Large, beautiful mascot presence
        resized_icon = img.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
        canvas.paste(resized_icon, (cx - icon_size // 2, cy - icon_size // 2), resized_icon)
        
        # Text title below
        text_color = (233, 237, 239) if is_dark else (0, 0, 0)
        lines = title.split(' ')
        ty = y + app_card_s + 8
        for line in lines:
            draw.text((x + 8, ty), line, fill=text_color)
            ty += 16
            
    return canvas

sim_l = simulate_app_cards('light')
sim_d = simulate_app_cards('dark')

w_combo = sim_l.width * 2 + 30
h_combo = sim_l.height + 60
combo_sim = Image.new('RGB', (w_combo, h_combo), (241, 245, 249))
d_combo = ImageDraw.Draw(combo_sim)
combo_sim.paste(sim_l, (10, 45))
combo_sim.paste(sim_d, (sim_l.width + 20, 45))

d_combo.text((20, 16), 'Pratinjau Kartu Menu Pego: Light Mode (SAMA & Desainable)', fill=(15, 23, 42), font=font_title)
d_combo.text((sim_l.width + 30, 16), 'Pratinjau Kartu Menu Pego: Dark Mode (SAMA & Desainable)', fill=(15, 23, 42), font=font_title)

combo_sim.save(r'C:\Users\zsptr\.gemini\antigravity\brain\d482e3d9-33b7-45ed-a771-f684ed63d57f\pego_app_cards_preview_combo.png')
print('App cards simulation saved to pego_app_cards_preview_combo.png!')

