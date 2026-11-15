import os
from PIL import Image, ImageFilter

brain_dir = r"C:\Users\zsptr\.gemini\antigravity\brain\706d435d-389a-4e19-ac7e-575683f0180a"
out_dir = r"C:\GIT\Pediagrow\scratch\new_icons"
os.makedirs(out_dir, exist_ok=True)

def process_white_bg(input_path, output_path, tolerance=15):
    img = Image.open(input_path).convert("RGBA")
    data = img.getdata()
    
    # Check top-left corner color
    corner = img.getpixel((0, 0))
    print(f"{os.path.basename(input_path)} corner color: {corner}")
    
    new_data = []
    for item in data:
        # If pure white / nearly white (item[0] > 240 and item[1] > 240 and item[2] > 240)
        # and low saturation
        diff = max(abs(item[0]-item[1]), abs(item[1]-item[2]), abs(item[0]-item[2]))
        if item[0] >= 245 and item[1] >= 245 and item[2] >= 245 and diff <= 10:
            new_data.append((255, 255, 255, 0))
        elif item[0] >= 235 and item[1] >= 235 and item[2] >= 235 and diff <= 8:
            # Soft edge antialiasing
            alpha = int(255 * (1.0 - (min(item[0], item[1], item[2]) - 235) / 20.0))
            new_data.append((item[0], item[1], item[2], max(0, min(255, alpha))))
        else:
            new_data.append(item)
            
    img.putdata(new_data)
    img.save(output_path, "PNG")
    print(f"Saved: {output_path}")

process_white_bg(
    os.path.join(brain_dir, "grafik_pertumbuhan_new_1794755714940.jpg"),
    os.path.join(out_dir, "grafik_pertumbuhan_new.png")
)

process_white_bg(
    os.path.join(brain_dir, "resep_mpasi_new_1794755725992.jpg"),
    os.path.join(out_dir, "resep_mpasi_new.png")
)

