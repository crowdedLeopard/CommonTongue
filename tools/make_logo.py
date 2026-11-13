#!/usr/bin/env python3
"""
Draw the CommonTongue project logo (square PNG) for CurseForge.

    python tools/make_logo.py [output.png] [size]

Default output: dist/CommonTongue-logo.png at 1024x1024. Needs Pillow
(pip install pillow). Two overlapping chat bubbles in the addon's own colours
(blue = built-in engine, green = live translation) with "A" and "文".
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "dist", "CommonTongue-logo.png")
size = int(sys.argv[2]) if len(sys.argv) > 2 else 1024
S = 2048  # drawn at this size, then scaled down for smooth edges

BG = (18, 26, 44, 255)
BLUE = (127, 212, 255, 255)    # |cff7fd4ff, the addon's inline tag colour
GREEN = (143, 227, 143, 255)   # |cff8fe38f, the live-translation colour
INK = (16, 22, 38, 255)
TEXT = (232, 238, 248, 255)

FONTS = os.path.join(os.environ.get("WINDIR", r"C:\Windows"), "Fonts")


def font(names, px):
    for name in names:
        p = os.path.join(FONTS, name)
        if os.path.isfile(p):
            try:
                return ImageFont.truetype(p, px)
            except OSError:
                pass
    return ImageFont.load_default()


img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.rounded_rectangle((0, 0, S - 1, S - 1), radius=S // 7, fill=BG)


def bubble(box, color, tail, outline=None):
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    r = h // 3
    if tail == "left":
        pts = [(x0 + w * 0.20, y1 - r * 0.4), (x0 + w * 0.08, y1 + h * 0.24), (x0 + w * 0.40, y1 - 4)]
    else:
        pts = [(x1 - w * 0.20, y1 - r * 0.4), (x1 - w * 0.08, y1 + h * 0.24), (x1 - w * 0.40, y1 - 4)]
    if outline:
        ow = outline[1]
        d.rounded_rectangle((x0 - ow, y0 - ow, x1 + ow, y1 + ow), radius=r + ow, fill=outline[0])
        d.polygon([(px + (ow if px > (x0 + x1) / 2 else -ow), py + ow * 0.9) for px, py in pts], fill=outline[0])
    d.polygon(pts, fill=color)
    d.rounded_rectangle(box, radius=r, fill=color)


def centered(text, fnt, cx, cy, fill):
    l, t, r, b = d.textbbox((0, 0), text, font=fnt)
    d.text((cx - (r - l) / 2 - l, cy - (b - t) / 2 - t), text, font=fnt, fill=fill)


blue_box = (230, 300, 1180, 1010)
green_box = (870, 760, 1820, 1470)
bubble(blue_box, BLUE, "left")
bubble(green_box, GREEN, "right", outline=(BG, 44))

f_latin = font(["segoeuib.ttf", "arialbd.ttf", "arial.ttf"], 540)
f_cjk = font(["msyhbd.ttc", "msyh.ttc", "simhei.ttf", "simsun.ttc", "malgunbd.ttf", "meiryob.ttc"], 470)
centered("A", f_latin, (blue_box[0] + blue_box[2]) / 2, (blue_box[1] + blue_box[3]) / 2 + 10, INK)
centered("\u6587", f_cjk, (green_box[0] + green_box[2]) / 2, (green_box[1] + green_box[3]) / 2, INK)

f_name = font(["segoeuib.ttf", "arialbd.ttf", "arial.ttf"], 150)
centered("CommonTongue", f_name, S / 2, 1800, TEXT)

os.makedirs(os.path.dirname(out), exist_ok=True)
img = img.resize((size, size), Image.LANCZOS)
img.save(out, "PNG", optimize=True)
print("written %s (%dx%d, %.0f KB)" % (out, size, size, os.path.getsize(out) / 1024))
