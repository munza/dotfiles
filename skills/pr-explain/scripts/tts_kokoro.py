"""tts_kokoro.py <out-dir> <slide-NN.txt>...: voices each narration with Kokoro-82M, locally, on the CPU.

Writes <out-dir>/audio-NN.wav for each file, <out-dir>/durations.json, and <out-dir>/timings.json:
for each file, its sentences as {text, start, end} in seconds, for captions and for timing animations.
Uses the model HyperFrames downloads to ~/.cache/hyperframes/tts (render.sh fetches it first) and
runs in a venv with kokoro-onnx and soundfile. [[slnc 400]] becomes a 400 ms pause; other [[...]]
marks are dropped. PR_EXPLAIN_KOKORO_VOICE (am_michael), PR_EXPLAIN_SPEED (1.0).
"""
import json, os, re, sys
from pathlib import Path

import numpy as np
import soundfile as sf
from kokoro_onnx import Kokoro

out = Path(sys.argv[1])
files = [Path(f) for f in sys.argv[2:]]
out.mkdir(parents=True, exist_ok=True)
cache = Path.home() / ".cache/hyperframes/tts"
model = Kokoro(str(cache / "models/kokoro-v1.0.onnx"), str(cache / "voices/voices-v1.0.bin"))
voice = os.environ.get("PR_EXPLAIN_KOKORO_VOICE", "am_michael")
speed = float(os.environ.get("PR_EXPLAIN_SPEED", "1.0"))
if voice not in model.get_voices():
    sys.exit(f"unknown voice {voice!r}; choose one of: {', '.join(sorted(model.get_voices()))}")
if not 0.8 <= speed <= 1.3:
    sys.exit(f"speed {speed} is outside 0.8 to 1.3")
lang = "en-gb" if voice.startswith("b") else "en-us"


def pieces(text):
    """Speech and pauses in order: ("say", sentence) or ("pause", seconds)."""
    for part in re.split(r"(\[\[slnc \d+\]\])", text):
        m = re.fullmatch(r"\[\[slnc (\d+)\]\]", part)
        if m:
            yield ("pause", int(m.group(1)) / 1000)
            continue
        part = re.sub(r"\[\[[^\]]*\]\]", "", part).strip()
        for sentence in re.split(r"(?<=[.?!])\s+", part):
            if sentence.strip():
                yield ("say", sentence.strip())


durations, timings = [], []
for f in files:
    n = f.stem.replace("slide-", "")
    chunks, sr, said, at = [], 24000, [], 0.0
    for kind, value in pieces(f.read_text()):
        if kind == "pause":
            chunks.append(np.zeros(int(sr * value), dtype=np.float32))
            at += len(chunks[-1]) / sr
        else:
            samples, sr = model.create(value, voice=voice, speed=speed, lang=lang)
            chunks.append(samples.astype(np.float32))
            said.append({"text": value, "start": round(at, 3), "end": round(at + len(samples) / sr, 3)})
            at += len(samples) / sr
    audio = np.concatenate(chunks) if chunks else np.zeros(sr, dtype=np.float32)
    sf.write(str(out / f"audio-{n}.wav"), audio, sr)
    durations.append(round(len(audio) / sr, 3))
    timings.append(said)
    print(f"  audio-{n}.wav {durations[-1]}s", flush=True)
(out / "durations.json").write_text(json.dumps(durations))
(out / "timings.json").write_text(json.dumps(timings))
