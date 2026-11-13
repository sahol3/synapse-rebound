"""Checks a movie-writer recording of tests/SfxProbe.tscn: every cue slot must be audible and the
silent control slot must not be. Usage: py -I scripts/sfx_probe_check.py <f.wav> <slots comma list>
Prints one PASS/FAIL line per slot and a final verdict; exit 1 on any failure.
"""
import math
import struct
import sys
import wave

START = 0.5
SLOT = 0.8
LOUD_DBFS = -45.0


def main() -> None:
    path, slots = sys.argv[1], sys.argv[2].split(",")
    with wave.open(path, "rb") as w:
        rate, ch, width, n = w.getframerate(), w.getnchannels(), w.getsampwidth(), w.getnframes()
        raw = w.readframes(n)
    if width == 2:
        data = struct.unpack("<%dh" % (len(raw) // 2), raw)
        full = 32768.0
    elif width == 4:
        data = struct.unpack("<%di" % (len(raw) // 4), raw)
        full = 2147483648.0
    else:
        raise SystemExit(f"unsupported sample width {width}")
    fails = 0
    for i, key in enumerate(slots):
        a = int((START + i * SLOT) * rate) * ch
        b = int((START + (i + 1) * SLOT - 0.05) * rate) * ch
        seg = data[a:b]
        peak = max((abs(x) for x in seg), default=0) / full
        db = 20 * math.log10(peak) if peak > 0 else -120.0
        loud = db > LOUD_DBFS
        ok = (not loud) if key.startswith("__silent") else loud
        fails += 0 if ok else 1
        print(f"{'PASS' if ok else 'FAIL'}  {key:<20} peak {db:6.1f} dBFS")
    print(f"VERDICT: {len(slots) - fails} of {len(slots)} slots as expected")
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
