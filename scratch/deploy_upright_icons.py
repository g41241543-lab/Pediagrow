import shutil
import os

source_map = {
    "cek_stunting_logo.png": r"C:\GIT\Pediagrow\scratch\upright_icons\cek_stunting_logo.png",
    "grafik_pertumbuhan_logo.png": r"C:\GIT\Pediagrow\scratch\upright_icons\grafik_pertumbuhan_logo.png",
    "resep_mpasi_logo.png": r"C:\GIT\Pediagrow\scratch\rot_mpasi.png",
    "artikel_kesehatan_logo.png": r"C:\GIT\Pediagrow\scratch\upright_icons\artikel_kesehatan_logo.png",
    "permainan_logo.png": r"C:\GIT\Pediagrow\scratch\upright_icons\permainan_logo.png",
}

space_map = {
    "cek_stunting_logo.png": "cek stunting logo.png",
    "grafik_pertumbuhan_logo.png": "grafik pertumbuhan logo.png",
    "resep_mpasi_logo.png": "resep MPASI logo.png",
    "artikel_kesehatan_logo.png": "artikel kesehatan logo.png",
    "permainan_logo.png": "permainan logo.png",
}

brain_dir = r"C:\Users\zsptr\.gemini\antigravity\brain\706d435d-389a-4e19-ac7e-575683f0180a"
assets_dir = r"C:\GIT\Pediagrow\assets\images"

for file_name, src in source_map.items():
    # 1. Copy to assets/images with underscore
    dst1 = os.path.join(assets_dir, file_name)
    shutil.copyfile(src, dst1)
    
    # 2. Copy to assets/images with space
    space_name = space_map[file_name]
    dst2 = os.path.join(assets_dir, space_name)
    shutil.copyfile(src, dst2)
    
    # 3. Copy to brain artifact dir with _new.png naming
    prefix = file_name.replace("_logo.png", "")
    dst3 = os.path.join(brain_dir, f"{prefix}_new.png")
    shutil.copyfile(src, dst3)
    
    # Also copy as standard name to brain
    dst4 = os.path.join(brain_dir, file_name)
    shutil.copyfile(src, dst4)

print("All 5 icons deployed successfully to assets and brain!")

