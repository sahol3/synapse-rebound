"""Copies the enemy character sheets the game uses out of the downloaded Sideview Sci-Fi pack.

Pack: "Sideview Sci-Fi - Patreon Collection" by Luis Zuno (Ansimuz), CC0 / public domain.
Source: https://opengameart.org/content/sideview-sci-fi-patreon-collection
Unzip it to assets/raw/sideview_scifi/x/ first (assets/raw is gitignored).

Files are copied byte for byte (no re-encoding, nothing generated) into game/assets/sideview_scifi/
together with the pack's licence file.

Usage: py -I scripts/import_sprites.py
"""
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "raw", "sideview_scifi", "x", "Sideview Sci-Fi - Patreon Collection")
DST = os.path.join(ROOT, "game", "assets", "sideview_scifi")

FILES = [
    "Sprites/space-marine/PNG/space-marine-idle.png",
    "Sprites/space-marine/PNG/space-marine-run.png",
    "Sprites/space-marine/PNG/space-marine-shoot.png",
    "Sprites/mech-unit/spritesheet/mech-unit.png",
    "Sprites/bipedal-Unit/PNG/bipedal-unit.png",
    "Sprites/tank-unit/PNG/tank-unit.png",
] + ["Sprites/alien-flying-enemy/sprites/alien-enemy-flying%d.png" % i for i in range(1, 9)] + [
    "public-license.txt",
]


def main():
    os.makedirs(DST, exist_ok=True)
    missing = 0
    for rel in FILES:
        src = os.path.join(SRC, *rel.split("/"))
        if not os.path.exists(src):
            print("MISSING " + rel)
            missing += 1
            continue
        shutil.copyfile(src, os.path.join(DST, os.path.basename(rel)))
    print("IMPORT_SPRITES copied=%d missing=%d -> %s" % (len(FILES) - missing, missing, DST))
    sys.exit(1 if missing else 0)


if __name__ == "__main__":
    main()
