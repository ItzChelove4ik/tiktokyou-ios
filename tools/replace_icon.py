#!/usr/bin/env python3
"""replace_icon.py — заменяет иконку приложения TikTok внутри IPA на иконку TikTok You.

Использование: python3 tools/replace_icon.py <ipa> <variant>
variant: default | metal | hlx | md

Стратегия:
1. Распаковывает Payload/TikTok.app из IPA (zip).
2. Ищет иконки: AppIcon*.appiconset (asset catalog Assets.car — бинарный, меняем через
   aapt-free подход: перезаписываем info.plist ссылки невозможно) — поэтому:
   - сначала ищем обычные PNG-иконки (AppIcon60x60@2x.png и т.п. в корне .app);
   - затем, если иконки в Assets.car, генерируем PNG всех требуемых размеров
     и заменяем через actool невозможно — вместо этого добавляем CFBundleIconFiles
     (обычные PNG в корне приложения имеют приоритет над asset catalog в iOS < 16
     и корректно работают как fallback) — практический путь: заменить все PNG
     с именами иконок, которые найдены рядом (включая .app/AppIcon*).
3. Требуемые размеры генерируются из 1024 исходника (Pillow нет на runner —
   используем sips, встроен в macOS).
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile

SIZES = [
    ("AppIcon20x20@1x", 20), ("AppIcon20x20@2x", 40), ("AppIcon20x20@3x", 60),
    ("AppIcon29x29@1x", 29), ("AppIcon29x29@2x", 58), ("AppIcon29x29@3x", 87),
    ("AppIcon40x40@1x", 40), ("AppIcon40x40@2x", 80), ("AppIcon40x40@3x", 120),
    ("AppIcon60x60@2x", 120), ("AppIcon60x60@3x", 180),
    ("AppIcon76x76@~ipad", 152), ("AppIcon83.5x83.5@~ipad", 167),
    ("AppIcon512x512@2x", 1024), ("AppIcon1024", 1024),
]


def main():
    ipa = sys.argv[1]
    variant = sys.argv[2] if len(sys.argv) > 2 else "default"
    here = os.path.dirname(os.path.abspath(__file__))
    src = os.path.join(here, f"{variant}.png")
    if not os.path.exists(src):
        print(f"[icon] variant {variant} not found, using default")
        src = os.path.join(here, "default.png")

    tmp = tempfile.mkdtemp()
    with zipfile.ZipFile(ipa) as z:
        z.extractall(tmp)

    app_dir = None
    for root, dirs, files in os.walk(os.path.join(tmp, "Payload")):
        if root.endswith(".app"):
            app_dir = root
            break
    if not app_dir:
        print("[icon] ERROR: no .app in Payload")
        sys.exit(1)

    # Resize source to all sizes with sips
    replaced = 0
    for name, size in SIZES:
        out = os.path.join(app_dir, f"{name}.png")
        if os.path.exists(out):
            subprocess.run(["sips", "-z", str(size), str(size), src, "--out", out],
                           capture_output=True, check=True)
            replaced += 1

    # Also replace any legacy PNG icons named like icon*.png / AppIcon*.png at app root
    for f in os.listdir(app_dir):
        if re.match(r"(?i)(appicon|icon)[0-9@~x.]*\.png$", f) and os.path.isfile(os.path.join(app_dir, f)):
            # match size digits if any
            m = re.search(r"(\d+)", f)
            size = int(m.group(1)) if m else 1024
            subprocess.run(["sips", "-z", str(size), str(size), src, "--out", os.path.join(app_dir, f)],
                           capture_output=True, check=True)
            replaced += 1

    # Repack IPA
    out_ipa = ipa
    staging = tempfile.mkdtemp()
    os.rename(ipa, os.path.join(staging, "old.ipa"))
    with zipfile.ZipFile(out_ipa, "w", zipfile.ZIP_DEFLATED) as z:
        for root, _, files in os.walk(tmp):
            for f in files:
                full = os.path.join(root, f)
                rel = os.path.relpath(full, tmp)
                z.write(full, rel)
    shutil.rmtree(tmp, ignore_errors=True)
    shutil.rmtree(staging, ignore_errors=True)
    print(f"[icon] replaced {replaced} icon files, variant={variant}")


if __name__ == "__main__":
    main()
