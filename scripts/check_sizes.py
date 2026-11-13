"""Checks the frames from capture_sizes.ps1.

For every window size and shot it reads the last frame and reports:
  - whether the frame is the size that was asked for,
  - whether any screen edge is an empty bar (a strip of one flat colour, 12 px deep),
  - script errors in the run's log.
It also writes one contact sheet per size to tools/_frames/<tag>/sheet_<WxH>.jpg.

Usage: py scripts/check_sizes.py <tag>
Exit code 1 if any frame has the wrong size, a bar, or a script error.
"""
import glob
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STRIP = 12


def flat(img, box):
    """True if the strip is one flat colour (an empty bar)."""
    colours = img.crop(box).getcolors(maxcolors=4)
    return colours is not None and len(colours) == 1


def main():
    tag = sys.argv[1] if len(sys.argv) > 1 else "sizes"
    base = os.path.join(ROOT, "tools", "_frames", tag)
    bad = 0
    rows = 0
    for size_dir in sorted(glob.glob(os.path.join(base, "*x*"))):
        if not os.path.isdir(size_dir):
            continue
        want = tuple(int(v) for v in os.path.basename(size_dir).split("x"))
        thumbs = []
        for shot in ("menu", "stage1", "stage3"):
            frames = sorted(glob.glob(os.path.join(size_dir, shot, "*.png")))
            log = ""
            for name in ("out.txt", "err.txt"):
                path = os.path.join(size_dir, shot, name)
                if os.path.exists(path):
                    with open(path, encoding="utf-8", errors="replace") as f:
                        log += f.read()
            errors = [ln for ln in log.splitlines() if "SCRIPT ERROR" in ln or "Parse Error" in ln or "shader" in ln.lower() and "error" in ln.lower()]
            rows += 1
            if not frames:
                print("%-10s %-7s NO FRAMES" % (os.path.basename(size_dir), shot))
                bad += 1
                continue
            img = Image.open(frames[-1]).convert("RGB")
            w, h = img.size
            bars = []
            if flat(img, (0, 0, STRIP, h)):
                bars.append("left")
            if flat(img, (w - STRIP, 0, w, h)):
                bars.append("right")
            if flat(img, (0, 0, w, STRIP)):
                bars.append("top")
            if flat(img, (0, h - STRIP, w, h)):
                bars.append("bottom")
            ok = (w, h) == want and not bars and not errors
            bad += 0 if ok else 1
            print("%-10s %-7s frame=%dx%d %s bars=%s errors=%d  %s" % (
                os.path.basename(size_dir), shot, w, h, "size-ok" if (w, h) == want else "SIZE-WRONG",
                ",".join(bars) or "none", len(errors), "PASS" if ok else "FAIL"))
            for e in errors[:3]:
                print("    " + e.strip())
            t = img.copy()
            t.thumbnail((640, 640))
            thumbs.append(t)
        if thumbs:
            sheet = Image.new("RGB", (sum(t.width for t in thumbs) + 8 * (len(thumbs) - 1), max(t.height for t in thumbs)), (20, 20, 20))
            x = 0
            for t in thumbs:
                sheet.paste(t, (x, 0))
                x += t.width + 8
            sheet.save(os.path.join(base, "sheet_%s.jpg" % os.path.basename(size_dir)), quality=88)
    print("CHECK_SIZES frames=%d failed=%d" % (rows, bad))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
