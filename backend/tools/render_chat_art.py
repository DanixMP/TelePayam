"""Render the original Campus Notes sticker pack and two looping GIFs."""

import math
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / "app/modules/stickers/assets"
INK = "#153b61"


def sticker(name):
    im = Image.new("RGBA", (256, 256))
    d = ImageDraw.Draw(im)
    if name == "plane":
        d.polygon(
            [(19, 110), (235, 28), (179, 226), (117, 171), (80, 207), (72, 137)],
            fill="#87d9ff",
            outline=INK,
            width=8,
        )
        d.polygon([(74, 136), (213, 49), (110, 159), (81, 193)], fill="#2476b1")
        d.line([(113, 163), (168, 207)], fill="white", width=6)
    elif name == "book":
        for points, fill in [
            ([(17, 54), (73, 43), (127, 66), (127, 212), (73, 191), (17, 200)], "#ffe5a4"),
            ([(127, 66), (181, 43), (239, 54), (239, 200), (181, 191), (127, 212)], "#fff4d7"),
        ]:
            d.polygon(points, fill=fill, outline=INK, width=8)
        for y in (85, 111, 137):
            d.line([(38, y), (71, y - 5), (105, y + 6)], fill="#b5773c", width=5)
            d.line([(151, y + 6), (182, y - 5), (219, y)], fill="#b5773c", width=5)
        d.polygon([(184, 50), (204, 52), (204, 103), (194, 95), (184, 106)], fill="#d45e53")
    elif name == "done":
        d.rounded_rectangle((27, 27, 230, 229), radius=59, fill="#8ce0ac", outline=INK, width=8)
        d.line([(68, 132), (107, 166), (189, 86)], fill=INK, width=23, joint="curve")
    else:
        points = [
            (
                128 + (109 if i % 2 == 0 else 57) * math.sin(i * math.pi / 5),
                128 - (109 if i % 2 == 0 else 57) * math.cos(i * math.pi / 5),
            )
            for i in range(10)
        ]
        d.polygon(points, fill="#ffce61", outline=INK, width=8)
        for x in (100, 149):
            d.ellipse((x, 114, x + 10, 128), fill=INK)
        d.arc((111, 119, 146, 147), 15, 165, fill=INK, width=5)
    return im


if __name__ == "__main__":
    for name in ("plane", "book", "done", "star"):
        sticker(name).save(OUT / f"{name}.png", optimize=True)
    for name, shape in [("flight", "plane"), ("sparkle", "star")]:
        frames = []
        for i in range(20):
            angle = 2 * math.pi * i / 20
            frame = Image.new("RGB", (200, 150), "#d9edff" if name == "flight" else "#ffe9bb")
            size = 82 if name == "flight" else round(88 + 14 * math.cos(angle))
            art = sticker(shape).resize((size, size), Image.Resampling.LANCZOS)
            x = round(54 + 42 * math.sin(angle)) if name == "flight" else (200 - size) // 2
            y = round(34 + 15 * math.cos(angle)) if name == "flight" else (150 - size) // 2
            frame.paste(art, (x, y), art)
            frames.append(frame)
        frames[0].save(
            OUT / f"{name}.gif", save_all=True, append_images=frames[1:], duration=70, loop=0
        )
