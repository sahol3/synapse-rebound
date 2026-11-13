"""Side-by-side review sheet: the same frames from two capture tags (dev tooling, output in tools/_frames).

Usage: py -I scripts/compare_sheet.py <tag_a> <tag_b>
Writes tools/_frames/compare_<tag_a>_<tag_b>.jpg with one row per moment, tag_a on the left.
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(r"D:\CLAUDE-CODE\haven-dhaka\tools\_frames")
MOMENTS = [("menu", 70), ("stage1", 40), ("stage2", 60), ("mech", 160), ("mech", 560), ("mech", 1060), ("mech", 1260)]


def pick(tag: str, shot: str, i: int) -> Path:
    files = sorted((ROOT / tag / shot).glob("f*.png"))
    return files[min(i, len(files) - 1)]


def main() -> None:
    a, b = sys.argv[1], sys.argv[2]
    w, h = 576, 324
    head = 20
    img = Image.new("RGB", (w * 2 + 8, len(MOMENTS) * (h + head)), (14, 14, 14))
    d = ImageDraw.Draw(img)
    for r, (shot, i) in enumerate(MOMENTS):
        y = r * (h + head)
        for c, tag in enumerate((a, b)):
            x = c * (w + 8)
            img.paste(Image.open(pick(tag, shot, i)).convert("RGB").resize((w, h), Image.LANCZOS), (x, y + head))
            d.text((x + 4, y + 4), f"{tag}  {shot} #{i}", fill=(230, 230, 230))
    out = ROOT / f"compare_{a}_{b}.jpg"
    img.save(out, quality=90)
    print(out)


if __name__ == "__main__":
    main()
