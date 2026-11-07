"""Draws the AutoFart logo. Outputs:
  AutoFart/icon.tga   64x64, addon list icon (## IconTexture)
  logo.png            512x512, for the zip / addon sites
"""
import math
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent
S = 1024  # draw big, downscale for antialiasing


def radial_bg(size, inner, outer):
    img = Image.new("RGBA", (size, size))
    px = img.load()
    c = size / 2
    maxd = math.hypot(c, c)
    for y in range(size):
        for x in range(size):
            t = min(1.0, math.hypot(x - c, y - c * 0.85) / maxd * 1.25)
            px[x, y] = tuple(int(inner[i] + (outer[i] - inner[i]) * t) for i in range(3)) + (255,)
    return img


def cloud(draw, blobs, fill, outline=None, grow=0):
    if outline:
        for x, y, r in blobs:
            draw.ellipse((x - r - grow, y - r - grow, x + r + grow, y + r + grow), fill=outline)
    for x, y, r in blobs:
        draw.ellipse((x - r, y - r, x + r, y + r), fill=fill)


def make():
    # Background: dark purple-brown, radial
    bg = radial_bg(S, (74, 52, 92), (18, 12, 24))
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, S - 1, S - 1), radius=150, fill=255)

    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    # Big gas cloud
    blobs = [
        (330, 610, 175), (520, 520, 215), (710, 600, 180),
        (430, 720, 160), (620, 730, 165), (800, 700, 120), (230, 720, 115),
    ]
    cloud(d, blobs, (60, 120, 30), outline=(26, 52, 14), grow=26)
    cloud(d, blobs, (120, 196, 58))
    # Highlights on the upper-left of the puffs
    hl = [(x - r * 0.25, y - r * 0.3, r * 0.6) for x, y, r in blobs[:3]]
    cloud(d, hl, (168, 230, 96))

    # Soft shadow along the bottom of the cloud
    shade = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    sd.ellipse((180, 740, 880, 900), fill=(30, 70, 15, 140))
    shade = shade.filter(ImageFilter.GaussianBlur(30))
    cmask = Image.new("L", (S, S), 0)
    cloud(ImageDraw.Draw(cmask), blobs, 255)
    layer.paste(Image.alpha_composite(layer, shade), (0, 0), cmask)
    d = ImageDraw.Draw(layer)

    # Cheeky face: closed happy eyes + grin
    ink = (24, 44, 12)
    d.arc((380, 530, 480, 610), 200, 340, fill=ink, width=26)
    d.arc((570, 530, 670, 610), 200, 340, fill=ink, width=26)
    d.chord((420, 600, 640, 760), 0, 180, fill=ink)
    d.chord((470, 680, 590, 750), 180, 360, fill=(214, 90, 110))  # tongue
    d.ellipse((330, 620, 400, 665), fill=(232, 120, 120, 170))     # blush
    d.ellipse((650, 620, 720, 665), fill=(232, 120, 120, 170))

    # Stink waves rising
    def wave(x0, y0, h, amp, w):
        pts = [(x0 + amp * math.sin(t / h * 2.6 * math.pi), y0 - t) for t in range(0, h)]
        for r, col in (((w + 18) / 2, (26, 52, 14)), (w / 2, (170, 232, 100))):
            for x, y in pts:  # stamp discs along the path = smooth round stroke
                d.ellipse((x - r, y - r, x + r, y + r), fill=col)

    wave(380, 340, 200, 26, 30)
    wave(530, 290, 220, 30, 34)
    wave(680, 340, 200, 26, 30)

    img = Image.alpha_composite(bg, layer)

    # Gold bevel frame, WoW-icon style
    fr = ImageDraw.Draw(img)
    fr.rounded_rectangle((14, 14, S - 15, S - 15), radius=140, outline=(92, 62, 20), width=40)
    fr.rounded_rectangle((26, 26, S - 27, S - 27), radius=130, outline=(222, 176, 74), width=18)
    fr.rounded_rectangle((44, 44, S - 45, S - 45), radius=115, outline=(120, 84, 30), width=6)

    out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def main():
    big = make()
    (ROOT / "logo.png").parent.mkdir(parents=True, exist_ok=True)
    big.resize((512, 512), Image.LANCZOS).save(ROOT / "logo.png")
    icon = big.resize((64, 64), Image.LANCZOS)
    icon.save(ROOT / "AutoFart" / "icon.tga")  # 32-bit uncompressed TGA, WoW-friendly
    icon.resize((256, 256), Image.NEAREST).save(ROOT / "icon_preview.png")
    print("ok")


if __name__ == "__main__":
    main()
