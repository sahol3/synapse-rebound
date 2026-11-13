"""Copies the chosen recorded samples from the downloaded Kenney CC0 packs into the game (dev tooling).

Sources live in assets/raw/sfx/kenney_<pack>/ (gitignored, see LEDGER). Files are copied unchanged into
game/assets/audio/sfx/kenney/. Two long recordings are trimmed with ffmpeg (cut + short fade-out); nothing is
generated. Re-run after changing PICK. Usage: py -I scripts/import_sfx.py
"""
import shutil
import subprocess
from pathlib import Path

ROOT = Path(r"D:\CLAUDE-CODE\haven-dhaka")
RAW = ROOT / "assets" / "raw" / "sfx"
OUT = ROOT / "game" / "assets" / "audio" / "sfx" / "kenney"


def rng(prefix: str, a: int, b: int, width: int = 3) -> list[str]:
    return [f"{prefix}{i:0{width}d}" for i in range(a, b + 1)]


PICK: dict[str, list[str]] = {
    "kenney_sci-fi-sounds": rng("impactMetal_", 0, 4) + rng("laserSmall_", 0, 4) + rng("laserLarge_", 0, 4)
    + rng("laserRetro_", 0, 4) + rng("forceField_", 0, 4) + rng("explosionCrunch_", 0, 4)
    + rng("lowFrequency_explosion_", 0, 1) + ["spaceEngineLow_000"],
    "kenney_impact-sounds": rng("impactBell_heavy_", 0, 4) + rng("impactSoft_heavy_", 0, 4)
    + rng("impactSoft_medium_", 0, 4) + rng("footstep_concrete_", 0, 4) + rng("impactPunch_medium_", 0, 4)
    + rng("impactGeneric_light_", 0, 4),
    "kenney_interface-sounds": rng("scratch_", 1, 5) + rng("glitch_", 1, 4) + ["bong_001"]
    + rng("confirmation_", 1, 4) + rng("error_", 5, 6) + rng("glass_", 1, 3),
    "kenney_digital-audio": rng("phaseJump", 1, 5, 1) + rng("phaserDown", 1, 3, 1) + rng("powerUp", 1, 6, 1)
    + ["zapThreeToneUp"],
    "kenney_ui-audio": rng("rollover", 1, 6, 1),
}
## (pack, source name, output name, start s, length s)
TRIM = [
    ("kenney_sci-fi-sounds", "thrusterFire_000", "thrusterBurst_000", 0.15, 0.30),
    ("kenney_sci-fi-sounds", "thrusterFire_001", "thrusterBurst_001", 0.15, 0.30),
    ("kenney_sci-fi-sounds", "computerNoise_000", "computerNoiseShort_000", 0.40, 0.35),
]


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    n = 0
    for pack, names in PICK.items():
        for name in names:
            src = RAW / pack / "Audio" / f"{name}.ogg"
            if not src.exists():
                raise SystemExit(f"missing {src}")
            shutil.copy2(src, OUT / src.name)
            n += 1
    for pack, name, out, start, length in TRIM:
        src = RAW / pack / "Audio" / f"{name}.ogg"
        dst = OUT / f"{out}.ogg"
        fade_at = max(length - 0.08, 0.0)
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-ss", str(start), "-t", str(length), "-i", str(src),
                        "-af", f"afade=t=out:st={fade_at}:d=0.08", "-c:a", "libvorbis", "-q:a", "5", str(dst)],
                       check=True)
        n += 1
    shutil.copy2(RAW / "kenney_sci-fi-sounds" / "License.txt", OUT / "License.txt")
    print(f"{n} samples in {OUT}")


if __name__ == "__main__":
    main()
