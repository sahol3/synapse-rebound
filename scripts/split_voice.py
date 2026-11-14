"""Splits one long voice recording into the game's line files (dev tooling).

Input: the recording and a word-timed transcript of it (JSON with "words": [{"w", "s", "e"}], made locally with
openai-whisper). Each line of docs/VOICE_SCRIPT.md is matched to the stretch of the transcript that reads most like
it. The cut points are then moved to the quietest moment in the pause before the first word and after the last one,
so no word is clipped and no neighbour leaks in. Nothing is generated: every output file is a piece of the recording.

Usage:
  py -I scripts/split_voice.py match <words.json>                 prints the match table, writes cuts.json beside it
  py -I scripts/split_voice.py cut <source audio> <cuts.json> <out folder> [--speaker echo|sara|both]
Then: py -I scripts/import_voice.py <out folder>
"""
import difflib
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(r"D:\CLAUDE-CODE\haven-dhaka")
SHEET = ROOT / "docs" / "VOICE_SCRIPT.md"
JOKES = {"oh_hell_nah": "oh hell nah", "hehe_boi": "hehe boy"}
MIN_SCORE = 0.62


ONES = "zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen".split()
TENS = "x x twenty thirty forty fifty sixty seventy eighty ninety".split()


def number_words(digits: str) -> str:
    """'400' -> 'four hundred', '09' -> 'zero nine': the way the sheet spells what a transcript writes in digits."""
    if digits.startswith("0") or len(digits) > 3:
        return " ".join(ONES[int(d)] for d in digits)
    n = int(digits)
    out = []
    if n >= 100:
        out += [ONES[n // 100], "hundred"]
        n %= 100
    if n >= 20:
        out.append(TENS[n // 10])
        n %= 10
        if n:
            out.append(ONES[n])
    elif n or not out:
        out.append(ONES[n])
    return " ".join(out)


def norm(text: str) -> list[str]:
    text = text.lower().replace("[q]", "q").replace("[e]", "e").replace("%", " percent")
    text = re.sub(r"\d+", lambda m: " " + number_words(m.group(0)) + " ", text)
    text = re.sub(r"[^a-z' ]+", " ", text)
    return [w.strip("'") for w in text.split() if w.strip("'")]


def read_lines() -> list[dict]:
    rows = []
    speaker = ""
    for line in SHEET.read_text(encoding="utf-8").splitlines():
        if line.startswith("## Sara"):
            speaker = "sara"
        elif line.startswith("## The Echo"):
            speaker = "echo"
        elif line.startswith("## "):
            speaker = ""
        m = re.match(r"\| (\d+) \| `([^`]+)` \| (.*?) \|", line)
        if m and speaker:
            rows.append({"speaker": speaker, "n": int(m.group(1)), "key": m.group(2), "text": m.group(3),
                         "words": norm(m.group(3))})
    for key, text in JOKES.items():
        rows.append({"speaker": "meme", "n": 0, "key": key, "text": text, "words": norm(text)})
    return rows


def best_window(line: list[str], words: list[str], lo: int, hi: int) -> tuple[float, int, int]:
    """(score, first word index, last word index) of the stretch of words[lo:hi] most like the line."""
    target = " ".join(line)
    n = len(line)
    best = (0.0, -1, -1)
    ## A take can open with a word the transcript misheard, so a start is tried wherever any of the next
    ## four words is one of the line's first four.
    head = set(line[:4])
    for i in range(lo, hi):
        if not head.intersection(words[i:i + 4]):
            continue
        for length in range(max(1, int(n * 0.6)), int(n * 1.5) + 2):
            j = i + length
            if j > hi:
                break
            score = difflib.SequenceMatcher(None, target, " ".join(words[i:j]), autojunk=False).ratio()
            if score > best[0]:
                best = (score, i, j - 1)
    return best


def said(tokens: list[dict]) -> str:
    """The transcript's own words for a stretch, each once (one token can stand for several sheet words)."""
    out: list[str] = []
    last = None
    for w in tokens:
        if w is not last:
            out.append(w["w"])
        last = w
    return " ".join(out)


def match(words_path: Path) -> None:
    data = json.loads(words_path.read_text(encoding="utf-8"))
    tw = []
    flat = []
    for w in data["words"]:
        for part in norm(w["w"]):
            tw.append(w)
            flat.append(part)
    rows = read_lines()
    found = []
    for r in rows:
        score, i, j = best_window(r["words"], flat, 0, len(flat))
        if i < 0 or score < MIN_SCORE:
            continue
        found.append({"speaker": r["speaker"], "key": r["key"], "n": r["n"], "score": round(score, 2), "i": i, "j": j,
                      "s": tw[i]["s"], "e": tw[j]["e"], "said": said(tw[i:j + 1]), "text": r["text"]})
    ## Two lines must not claim the same words: the better match keeps them.
    found.sort(key=lambda f: -f["score"])
    kept: list[dict] = []
    for f in found:
        if all(f["j"] < k["i"] or f["i"] > k["j"] for k in kept):
            kept.append(f)
    kept.sort(key=lambda f: f["s"])
    used = set()
    for k in kept:
        used.update(range(k["i"], k["j"] + 1))
        print("%6.2f-%6.2f  %.2f  %-5s %-22s %s" % (k["s"], k["e"], k["score"], k["speaker"], k["key"], k["said"][:110]))
    spare = [idx for idx in range(len(tw)) if idx not in used]
    print("\nmatched %d of %d sheet lines; %d of %d transcript words unused" % (len(kept), len(rows), len(spare), len(tw)))
    run: list[int] = []
    for idx in spare + [-1]:
        if run and idx != run[-1] + 1:
            if len(run) >= 3:
                print("  unused %6.2f-%6.2f  %s" % (tw[run[0]]["s"], tw[run[-1]]["e"], " ".join(tw[x]["w"] for x in run)[:120]))
            run = []
        if idx >= 0:
            run.append(idx)
    for k in kept:
        before = [w["e"] for w in tw[:k["i"]] if w["e"] <= k["s"]]
        after = [w["s"] for w in tw[k["j"] + 1:] if w["s"] >= k["e"]]
        k["prev_e"] = before[-1] if before else 0.0
        k["next_s"] = after[0] if after else None
    out = words_path.with_name("cuts.json")
    out.write_text(json.dumps(kept, indent=1), encoding="utf-8")
    print("wrote", out)


def envelope(source: Path) -> tuple[list[float], float]:
    """RMS level in dB for every 10 ms of the recording."""
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(source), "-ac", "1", "-ar", "16000", "-f", "s16le", "-"],
                         capture_output=True, check=True).stdout
    import array
    import math
    pcm = array.array("h")
    pcm.frombytes(raw[:len(raw) // 2 * 2])
    hop = 160
    levels = []
    for a in range(0, len(pcm) - hop, hop):
        chunk = pcm[a:a + hop]
        rms = math.sqrt(sum(v * v for v in chunk) / hop) or 1.0
        levels.append(20.0 * math.log10(rms / 32768.0))
    return levels, 0.01


def quietest(levels: list[float], step: float, a: float, b: float, prefer: float) -> float:
    """The centre of the quietest 60 ms between a and b; ties go to the moment nearest `prefer`."""
    ia, ib = max(0, int(a / step)), min(len(levels) - 6, int(b / step))
    if ib <= ia:
        return prefer
    best, at = 1e9, prefer
    for i in range(ia, ib):
        level = sum(levels[i:i + 6]) / 6.0 + abs((i * step + 0.03) - prefer) * 2.0
        if level < best:
            best, at = level, i * step + 0.03
    return at


def pauses(levels: list[float], step: float, a: float, b: float, quiet: float) -> list[tuple[float, float]]:
    """Stretches of at least 80 ms between a and b where the level stays under `quiet`: real pauses, as
    opposed to the 30 ms dip inside a word."""
    ia, ib = max(1, int(a / step)), min(len(levels) - 2, int(b / step))
    runs = []
    begin = None
    for i in range(ia, ib + 1):
        smooth = (levels[i - 1] + levels[i] + levels[i + 1]) / 3.0
        if smooth < quiet and i < ib:
            if begin is None:
                begin = i
        elif begin is not None:
            if (i - begin) * step >= 0.08:
                runs.append((begin * step, i * step))
            begin = None
    return runs


def cut(source: Path, cuts_path: Path, out_dir: Path, speaker: str) -> None:
    cuts = json.loads(cuts_path.read_text(encoding="utf-8"))
    levels, step = envelope(source)
    total = len(levels) * step
    ## Room noise is the level the recording sits at when nobody speaks; a pause is anything within 7 dB of it.
    floor = sorted(levels)[len(levels) // 10]
    quiet = floor + 7.0
    print("room noise %.1f dB, pause threshold %.1f dB" % (floor, quiet))
    out_dir.mkdir(parents=True, exist_ok=True)
    for old in out_dir.glob("*.wav"):
        old.unlink()
    n = 0
    for c in cuts:
        if speaker != "both" and c["speaker"] not in (speaker, "meme"):
            continue
        ## Whisper's word edges are approximate. Each cut goes into the real pause nearest to the line's
        ## first or last word: 0.10 s before the voice starts and up to 0.18 s after it stops.
        nxt = c["next_s"] if c["next_s"] is not None else total
        tight_start = c["s"] - c["prev_e"] < 0.25
        tight_end = nxt - c["e"] < 0.25
        lead = pauses(levels, step, (c["prev_e"] - 0.25) if tight_start else max(c["prev_e"] - 0.10, c["s"] - 1.2, 0.0),
                      c["s"] + (0.40 if tight_start else 0.10), quiet)
        if lead:
            run = min(lead, key=lambda r: abs(r[1] - c["s"]))
            start = max(run[0], run[1] - 0.10)
        else:
            start = quietest(levels, step, c["prev_e"] - 0.20, c["s"] + 0.20, (c["prev_e"] + c["s"]) / 2.0)
        tail = pauses(levels, step, c["e"] - (0.25 if tight_end else 0.10),
                      (c["e"] + 0.40) if tight_end else min(nxt + 0.10, c["e"] + 1.5, total), quiet)
        if tail:
            run = min(tail, key=lambda r: abs(r[0] - c["e"]))
            end = min(run[0] + 0.18, run[1])
        else:
            end = quietest(levels, step, c["e"] - 0.20, nxt + 0.20, (c["e"] + nxt) / 2.0)
        name = c["key"] + ".wav"
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-ss", "%.3f" % start, "-to", "%.3f" % end, "-i", str(source),
                        "-ac", "1", "-ar", "44100", str(out_dir / name)], check=True)
        print("%-24s %7.2f - %7.2f  (%.2f s)  words %.2f - %.2f  %s%s" % (
            name, start, end, end - start, c["s"], c["e"], "" if lead else "no pause before ", "" if tail else "no pause after"))
        n += 1
    print("%d takes in %s" % (n, out_dir))


def main() -> int:
    if len(sys.argv) >= 3 and sys.argv[1] == "match":
        match(Path(sys.argv[2]))
        return 0
    if len(sys.argv) >= 5 and sys.argv[1] == "cut":
        speaker = "both"
        for a in sys.argv[5:]:
            if a.startswith("--speaker="):
                speaker = a.split("=", 1)[1]
        cut(Path(sys.argv[2]), Path(sys.argv[3]), Path(sys.argv[4]), speaker)
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main())
