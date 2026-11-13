"""Builds review contact sheets from movie-writer frames (dev tooling; output stays in tools/_frames, never in game/).

Usage: py -I scripts/contact_sheet.py <tag> [--scale 0.5]
Writes tools/_frames/<tag>/sheet_shots.jpg (chosen frames per shot) and sheet_mech.jpg (every 100th MechTest frame).
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(r"D:\CLAUDE-CODE\haven-dhaka\tools\_frames")
PICKS = {"menu": [20, 70], "stage1": [40, 145], "stage2": [60, 145], "stage3": [100], "stage4": [80, 205]}


def frame(tag: str, shot: str, i: int) -> Path | None:
    files = sorted((ROOT / tag / shot).glob("f*.png"))
    if not files:
        return None
    return files[min(i, len(files) - 1)]


def sheet(paths: list[tuple[str, Path]], out: Path, scale: float, cols: int) -> None:
    w, h = int(1152 * scale), int(648 * scale)
    rows = (len(paths) + cols - 1) // cols
    img = Image.new("RGB", (cols * w, rows * (h + 18)), (16, 16, 16))
    d = ImageDraw.Draw(img)
    for k, (label, p) in enumerate(paths):
        x, y = (k % cols) * w, (k // cols) * (h + 18)
        img.paste(Image.open(p).convert("RGB").resize((w, h), Image.NEAREST), (x, y + 18))
        d.text((x + 4, y + 3), label, fill=(230, 230, 230))
    img.save(out, quality=88)
    print(out, len(paths))


def main() -> None:
    tag = sys.argv[1]
    scale = float(sys.argv[sys.argv.index("--scale") + 1]) if "--scale" in sys.argv else 0.5
    shots = []
    for shot, idx in PICKS.items():
        for i in idx:
            p = frame(tag, shot, i)
            if p:
                shots.append((f"{shot} #{i}", p))
    sheet(shots, ROOT / tag / "sheet_shots.jpg", scale, 3)
    mech = sorted((ROOT / tag / "mech").glob("f*.png"))
    picks = [(f"mech #{i}", mech[i]) for i in range(60, len(mech), 100)]
    if picks:
        sheet(picks, ROOT / tag / "sheet_mech.jpg", scale * 0.8, 4)


if __name__ == "__main__":
    main()
