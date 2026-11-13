#!/bin/bash
# render.sh <out-dir>: voices slides/slide-NN.txt, builds an animated HyperFrames composition from
# them (video.mjs), and renders it to <out-dir>/walkthrough.mp4. Nothing is installed globally:
# HyperFrames runs through npx (pinned), ffmpeg through nix, the voice in its own venv or uv.
# Voice: Kokoro-82M "am_michael" on the CPU (tts_kokoro.py, about 20 s for a whole PR). Set
# PR_EXPLAIN_TTS=chatterbox for Chatterbox instead (tts.py, expressive, about 7 min), which copies
# PR_EXPLAIN_VOICE_REF, else scripts/voice.wav, else a clip spoken by a male macOS voice.
set -euo pipefail

OUT="$(cd "${1:?usage: render.sh <out-dir>}" && pwd)"
HERE="$(cd "$(dirname "$0")" && pwd)"
HYPERFRAMES="hyperframes@0.9.38"
VENV="$HOME/.cache/pr-explain/kokoro-venv"
export HYPERFRAMES_NO_TELEMETRY=1 DO_NOT_TRACK=1

shopt -s nullglob
texts=("$OUT"/slides/slide-*.txt)
[ ${#texts[@]} -gt 0 ] || { echo "no narration in $OUT/slides; run build.mjs first" >&2; exit 1; }
rm -rf "$OUT/video"
mkdir -p "$OUT/video/assets"

if [ "${PR_EXPLAIN_TTS:-kokoro}" = chatterbox ]; then
  if [ -z "${PR_EXPLAIN_VOICE_REF:-}" ] && [ ! -f "$HERE/voice.wav" ]; then
    voice=$(say -v '?' | sed -E 's/ +[a-z]{2}_[A-Z]{2} +#.*$//' | grep -Fx -m1 -e "Daniel" -e "Reed (English (US))" -e "Alex" || true)
    [ -n "$voice" ] || { echo "no male macOS voice for the reference; set PR_EXPLAIN_VOICE_REF" >&2; exit 1; }
    say -v "$voice" -r 175 -o "$OUT/video/ref.wav" --data-format=LEI16@24000 \
      "Alright, let me walk you through this one. It's a small change, but it fixes something that bugs a lot of people. So here's the problem, and here's how we solved it."
    export PR_EXPLAIN_VOICE_REF="$OUT/video/ref.wav"
  fi
  # setuptools<81: Chatterbox's watermarker still imports pkg_resources.
  (cd "$HOME/.cache/pr-explain" 2>/dev/null || cd /tmp
   uv run --quiet --python 3.11 --with chatterbox-tts==0.1.7 --with "setuptools<81" \
     python "$HERE/tts.py" "$OUT/video/assets" "${texts[@]}" 2>&1 | grep -E "^  audio-|Error|error" || true)
else
  # Checks the imports, not just the venv, so a half-finished install is retried.
  "$VENV/bin/python" -c 'import kokoro_onnx, soundfile' 2>/dev/null || {
    [ -x "$VENV/bin/python" ] || uv venv --quiet --python 3.11 "$VENV"
    uv pip install --quiet --python "$VENV/bin/python" kokoro-onnx==0.6.1 soundfile==0.14.0
  }
  # HyperFrames downloads the Kokoro model and voices on its first tts run.
  [ -f "$HOME/.cache/hyperframes/tts/models/kokoro-v1.0.onnx" ] ||
    HYPERFRAMES_PYTHON="$VENV/bin/python" npx --yes "$HYPERFRAMES" tts "Hello." -o "$OUT/video/warmup.wav" >/dev/null
  "$VENV/bin/python" -I "$HERE/tts_kokoro.py" "$OUT/video/assets" "${texts[@]}"
fi
[ -f "$OUT/video/assets/durations.json" ] || { echo "voicing failed" >&2; exit 1; }

node "$HERE/video.mjs" "$OUT"
cd "$OUT/video"
nix shell nixpkgs#ffmpeg -c npx --yes "$HYPERFRAMES" render --quality standard --fps 30 --output "$OUT/walkthrough.mp4"
printf 'walkthrough.mp4: %s\n' "$(du -h "$OUT/walkthrough.mp4" | cut -f1)"
