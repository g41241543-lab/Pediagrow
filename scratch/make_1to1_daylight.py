from PIL import Image, ImageEnhance, ImageFilter
import numpy as np

def convert_dark_to_light():
    dark_im = Image.open(r'C:\Users\zsptr\.gemini\antigravity\brain\d482e3d9-33b7-45ed-a771-f684ed63d57f\footer_dark_hd_v3_png_1794153738700.jpg')
    arr = np.array(dark_im).astype(np.float32)
    h, w, _ = arr.shape

    # 1. Detect sky region
    # In dark image: y < 450, B > G, R is low, or high brightness stars/clouds
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    
    # Sky detection
    sky_score = (b - g) + (b - r)
    is_sky = (sky_score > -5) & (arr.mean(axis=2) < 95) & (np.arange(h)[:, None] < 420)
    # Include stars and night clouds in the sky
    is_sky = is_sky | ((arr.mean(axis=2) > 120) & (b > 110) & (np.arange(h)[:, None] < 350))

    # Smooth the sky mask
    from scipy.ndimage import gaussian_filter
    sky_mask = gaussian_filter(is_sky.astype(np.float32), sigma=1.5)

    # 2. Daytime sky gradient
    # Top is near white #F4FAFD, transitioning to cheerful sky cyan #C2EAFB
    y_coords = np.arange(h)[:, None] / float(h)
    sky_r = 244.0 - y_coords * 60.0
    sky_g = 250.0 - y_coords * 25.0
    sky_b = 255.0 - y_coords * 10.0
    daytime_sky = np.stack([sky_r * np.ones((h, w)), sky_g * np.ones((h, w)), sky_b * np.ones((h, w))], axis=2)

    # 3. Ground / nature conversion:
    # Boost brightness and shift emerald/night tones to lush sunny daytime green
    # Convert RGB to HSV
    nature_arr = arr.copy()
    
    # Luminance of original
    lum = 0.299 * r + 0.587 * g + 0.114 * b
    
    # Target daytime palette for ground/foliage:
    # Deep greens become fresh leaf green: R: 70..140, G: 160..215, B: 50..100
    # Warm highlights (tent, campfire, birch) retain their character
    
    # Nature recolor
    recolored = np.zeros_like(arr)
    
    # Tent detection (cyan/teal fabric): g > 80, b > 70, |g-b| < 30, r < 90
    is_tent = (g > 70) & (b > 65) & (np.abs(g - b) < 35) & (r < 110) & (np.arange(h)[:, None] > 350)
    
    # Birch tree / white highlights: r > 140, g > 140, b > 130
    is_bright = (r > 130) & (g > 130) & (b > 120)
    
    # Campfire warm glow: r > 120, g > 80, b < 70
    is_fire = (r > 120) & (r > b * 1.4)
    
    # General grass & trees
    norm_lum = np.clip(lum / 120.0, 0.1, 1.8)
    
    green_r = np.clip(60 + norm_lum * 65, 0, 255)
    green_g = np.clip(135 + norm_lum * 75, 0, 255)
    green_b = np.clip(45 + norm_lum * 60, 0, 255)
    
    recolored[:, :, 0] = green_r
    recolored[:, :, 1] = green_g
    recolored[:, :, 2] = green_b
    
    # Keep tent vibrant cyan
    recolored[is_tent, 0] = np.clip(r[is_tent] * 0.9, 0, 80)
    recolored[is_tent, 1] = np.clip(g[is_tent] * 1.6 + 30, 140, 220)
    recolored[is_tent, 2] = np.clip(b[is_tent] * 1.5 + 40, 160, 235)
    
    # Keep birch trunks crisp white with bark marks
    recolored[is_bright, 0] = np.clip(r[is_bright] * 1.3, 0, 255)
    recolored[is_bright, 1] = np.clip(g[is_bright] * 1.3, 0, 255)
    recolored[is_bright, 2] = np.clip(b[is_bright] * 1.25, 0, 255)
    
    # Keep campfire
    recolored[is_fire, 0] = np.clip(r[is_fire] * 1.3, 0, 255)
    recolored[is_fire, 1] = np.clip(g[is_fire] * 1.2, 0, 255)
    recolored[is_fire, 2] = np.clip(b[is_fire], 0, 255)

    # Blend sky and nature
    mask_3d = np.clip(sky_mask[:, :, None], 0.0, 1.0)
    result = daytime_sky * mask_3d + recolored * (1.0 - mask_3d)
    result = np.clip(result, 0, 255).astype(np.uint8)
    
    res_im = Image.fromarray(result)
    res_im.save(r'C:\Users\zsptr\.gemini\antigravity\brain\d482e3d9-33b7-45ed-a771-f684ed63d57f\footer_1to1_recolored_daylight.png')
    print('1-to-1 recolored daylight saved successfully!')

if __name__ == '__main__':
    convert_dark_to_light()

