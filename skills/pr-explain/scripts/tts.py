"""tts.py <out-dir> <slide-NN.txt>...: voices each narration with Chatterbox, locally.

Writes <out-dir>/audio-NN.wav for each file and <out-dir>/durations.json. Run through uv
(see render.sh), so nothing is installed globally; the model downloads from Hugging Face
on first use. [[slnc 400]] in the text becomes a 400 ms pause; other [[...]] marks are dropped.
PR_EXPLAIN_VOICE_REF: a 5-15 s WAV of the voice to speak in (default: voice.wav beside this
script if present, else Chatterbox's built-in voice). PR_EXPLAIN_EXAGGERATION: 0.25-1.0 (0.6).
"""
import json, os, re, sys
from pathlib import Path

import torch
import torchaudio
from chatterbox.tts import ChatterboxTTS

out = Path(sys.argv[1])
files = [Path(f) for f in sys.argv[2:]]
out.mkdir(parents=True, exist_ok=True)
device = "mps" if torch.backends.mps.is_available() else "cpu"
model = ChatterboxTTS.from_pretrained(device=device)
ref = os.environ.get("PR_EXPLAIN_VOICE_REF") or str(Path(__file__).with_name("voice.wav"))
ref = ref if Path(ref).exists() else None
exaggeration = float(os.environ.get("PR_EXPLAIN_EXAGGERATION", "0.6"))
sr = model.sr
if ref:
    model.prepare_conditionals(ref, exaggeration=exaggeration)


def pieces(text):
    """Speech and pauses in order: ("say", sentence) or ("pause", seconds)."""
    for part in re.split(r"(\[\[slnc \d+\]\])", text):
        m = re.fullmatch(r"\[\[slnc (\d+)\]\]", part)
        if m:
            yield ("pause", int(m.group(1)) / 1000)
            continue
        part = re.sub(r"\[\[[^\]]*\]\]", "", part).strip()
        # One sentence at a time: Chatterbox stays steadier on short inputs.
        for sentence in re.split(r"(?<=[.?!])\s+", part):
            if sentence.strip():
                yield ("say", sentence.strip())


durations = []
for f in files:
    n = f.stem.replace("slide-", "")
    chunks = []
    for kind, value in pieces(f.read_text()):
        if kind == "pause":
            chunks.append(torch.zeros(1, int(sr * value)))
        else:
            wav = model.generate(value, exaggeration=exaggeration, cfg_weight=0.4, temperature=0.8)
            chunks.append(wav.cpu())
            chunks.append(torch.zeros(1, int(sr * 0.12)))  # a breath between sentences
    audio = torch.cat(chunks, dim=1) if chunks else torch.zeros(1, sr)
    torchaudio.save(str(out / f"audio-{n}.wav"), audio, sr)
    durations.append(round(audio.shape[1] / sr, 3))
    print(f"  audio-{n}.wav {durations[-1]}s", flush=True)
(out / "durations.json").write_text(json.dumps(durations))
