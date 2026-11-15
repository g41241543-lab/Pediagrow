from PIL import Image

def test_rotations():
    # 1. Resep MPASI
    im_mpasi = Image.open(r"C:\GIT\Pediagrow\scratch\new_icons\resep_mpasi_new.png")
    # In resep_mpasi_new, the bowl rim was tilted down to the left by about 12-14 degrees
    # Rotating clockwise (negative angle in PIL rotate)
    rot_mpasi = im_mpasi.rotate(14, resample=Image.Resampling.BICUBIC, expand=True)
    
    # 2. Grafik Pertumbuhan
    im_grafik = Image.open(r"C:\GIT\Pediagrow\scratch\new_icons\grafik_pertumbuhan_new.png")
    # Leaning left by ~25 degrees
    rot_grafik = im_grafik.rotate(24, resample=Image.Resampling.BICUBIC, expand=True)
    
    # 3. Cek Stunting
    im_stunting = Image.open(r"C:\GIT\Pediagrow\scratch\new_icons\cek_stunting_new.png")
    # Tilted by ~12 degrees
    rot_stunting = im_stunting.rotate(12, resample=Image.Resampling.BICUBIC, expand=True)
    
    def crop_tight(im):
        bbox = im.getbbox()
        cropped = im.crop(bbox)
        w, h = cropped.size
        m = max(w, h)
        scale = 120 / m
        nw, nh = max(1, int(round(w * scale))), max(1, int(round(h * scale)))
        r = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
        out = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        out.paste(r, ((128 - nw)//2, (128 - nh)//2))
        return out
        
    crop_tight(rot_mpasi).save(r"C:\GIT\Pediagrow\scratch\rot_mpasi.png")
    crop_tight(rot_grafik).save(r"C:\GIT\Pediagrow\scratch\rot_grafik.png")
    crop_tight(rot_stunting).save(r"C:\GIT\Pediagrow\scratch\rot_stunting.png")
    print("Rotated test complete!")

test_rotations()

