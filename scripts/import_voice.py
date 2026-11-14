"""Brings recorded voice lines into the game (dev tooling).

Reads a folder of recordings named by sheet number (07.wav, echo_03.m4a) or by file name (s1_intro_3.wav),
matches them against docs/VOICE_SCRIPT.md, and writes game/assets/audio/voice/<speaker>/<file name>.ogg.
Each recording is converted to mono 44.1 kHz, has leading and trailing silence trimmed and its loudness
evened out with ffmpeg. Nothing is generated and no effect is added: the game applies the radio filter.

Usage: py -I scripts/import_voice.py <folder with recordings>
Then:  tools\\bin\\godot.cmd --headless --path game --import
"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(r"D:\CLAUDE-CODE\haven-dhaka")
SHEET = ROOT / "docs" / "VOICE_SCRIPT.md"
OUT = ROOT / "game" / "assets" / "audio" / "voice"
AUDIO = {".wav", ".mp3", ".m4a", ".ogg", ".flac", ".aac", ".opus", ".wma", ".mp4", ".3gp", ".amr"}


JOKES = ("hehe_boi", "oh_hell_nah")


def read_sheet() -> dict[str, tuple[str, str]]:
    """Maps both the number and the file name of every line to (speaker folder, file name)."""
    names: dict[str, tuple[str, str]] = {}
    speaker = ""
    for line in SHEET.read_text(encoding="utf-8").splitlines():
        if line.startswith("## Saif"):
            speaker = "saif"
        elif line.startswith("## The Echo"):
            speaker = "echo"
        m = re.match(r"\| (\d+) \| `([^`]+)` \|", line)
        if not m or not speaker:
            continue
        number, key = m.group(1), m.group(2)
        names[key.lower()] = (speaker, key)
        if speaker == "saif":
            names[number] = (speaker, key)
            names[str(int(number))] = (speaker, key)
            names["saif_" + number] = (speaker, key)
        else:
            names["echo_" + number] = (speaker, key)
            names["echo_" + str(int(number))] = (speaker, key)
    return names


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    src = Path(sys.argv[1])
    if not src.is_dir():
        print("not a folder:", src)
        return 2
    names = read_sheet()
    wanted = {v for v in names.values()}
    for joke in JOKES:
        names[joke] = ("meme", joke)
    done: set[tuple[str, str]] = set()
    skipped: list[str] = []
    for f in sorted(src.iterdir()):
        if f.suffix.lower() not in AUDIO:
            continue
        hit = names.get(f.stem.lower().strip())
        if hit is None:
            skipped.append(f.name)
            continue
        speaker, key = hit
        dest = OUT / speaker / (key + ".ogg")
        dest.parent.mkdir(parents=True, exist_ok=True)
        chain = ("highpass=f=85,afftdn=nr=12:nf=-34:tn=1,"
                 "silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.05,"
                 "areverse,silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.12,"
                 "afade=t=in:d=0.06,areverse,afade=t=in:d=0.03,"
                 "loudnorm=I=-16:TP=-1.5:LRA=11")
        cmd = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(f), "-vn", "-ac", "1",
               "-ar", "44100", "-af", chain, "-c:a", "libvorbis", "-q:a", "5", str(dest)]
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode != 0 or not dest.exists():
            print("FAILED", f.name, r.stderr.strip()[:200])
            continue
        dur = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(dest)],
                             capture_output=True, text=True).stdout.strip()
        print("ok  %-22s -> voice/%s/%s.ogg  %ss" % (f.name, speaker, key, dur[:5]))
        if speaker != "meme":
            done.add(hit)
    saif_total = len([w for w in wanted if w[0] == "saif"])
    saif_done = len([d for d in done if d[0] == "saif"])
    print("\nSaif: %d of %d lines recorded. Echo: %d of %d." % (
        saif_done, saif_total, len(done) - saif_done, len(wanted) - saif_total))
    missing = sorted(k for s, k in wanted - done if s == "saif")
    if missing:
        print("Saif lines still text only:", ", ".join(missing))
    if skipped:
        print("Not matched to any line (check the name):", ", ".join(skipped))
    return 0


if __name__ == "__main__":
    sys.exit(main())
