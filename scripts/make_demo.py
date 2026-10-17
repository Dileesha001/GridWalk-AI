"""Build an annotated silent video from actual product browser captures.

Verification tooling only: pip install Pillow imageio-ffmpeg in the helper env.
Run verify_recovery_console.py against the product first. This is a sequence of
recorded console states, not a continuous recording or a live model claim.
"""
import json
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps
import imageio_ffmpeg

root = Path(__file__).resolve().parents[1]
captures = root / ".jac" / "console-verification"
report = json.loads((captures / "recovery-product.json").read_text(encoding="utf-8"))
output = root / ".jac" / "demo"
output.mkdir(parents=True, exist_ok=True)
font = root / "assets" / "fonts" / "FiraSans-Regular.ttf"
title_font = ImageFont.truetype(str(font), 34)
body_font = ImageFont.truetype(str(font), 24)
runs = report["scenarios"]
scenes = [
    ("recovery-baseline.png", "GridWalk AI | Fictional microgrid", "Twelve buses modeled in Jac. AI proposes; deterministic code validates; the simulator applies."),
    ("recovery-0-fault.png", "1. Inject a source-capacity fault", "The dashboard reads a fresh server snapshot. Faults remain active after recovery."),
    ("recovery-0-result.png", "2. Inspect the source recovery", f"Observed mode: {runs[0]['mode']} | Outcome: {runs[0]['outcome']} | Served: {runs[0]['served_kw']:g} kW."),
    ("recovery-1-fault.png", "3. Inject a physical line fault", "The hospital branch loses service. Recovery does not repair the physical line."),
    ("recovery-1-result.png", "4. Verify the line recovery", f"Observed mode: {runs[1]['mode']} | Outcome: {runs[1]['outcome']} | Served: {runs[1]['served_kw']:g} kW."),
    ("recovery-2-result.png", "5. Inspect limited backup capacity", f"Observed mode: {runs[2]['mode']} | Outcome: {runs[2]['outcome']} | Served: {runs[2]['served_kw']:g} kW."),
]
frames = []
for index, (filename, title, caption) in enumerate(scenes):
    canvas = Image.new("RGB", (1600, 1400), "#f5f7fa")
    draw = ImageDraw.Draw(canvas)
    draw.rectangle((0, 0, 1600, 105), fill="#102b30")
    draw.text((32, 27), title, font=title_font, fill="white")
    screenshot = ImageOps.contain(Image.open(captures / filename).convert("RGB"), (1560, 1160))
    canvas.paste(screenshot, ((1600 - screenshot.width) // 2, 120))
    draw.text((32, 1300), caption, font=body_font, fill="#142c35")
    draw.text((32, 1345), "Recorded product states | Silent walkthrough | Simplified connectivity and kW constraints", font=body_font, fill="#536574")
    frame = output / f"scene-{index:02}.png"
    canvas.save(frame)
    frames.append(frame)
playlist = output / "frames.txt"
playlist.write_text("\n".join(f"file '{p.name}'\nduration 8" for p in frames) + f"\nfile '{frames[-1].name}'\n", encoding="utf-8")
video = output / "GridWalk-demo.mp4"
ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
subprocess.run([ffmpeg, "-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", str(playlist),
                "-vf", "fps=24", "-c:v", "libx264", "-preset", "fast", "-crf", "20", "-pix_fmt", "yuv420p",
                "-movflags", "+faststart", str(video)], check=True)
# Decode the complete result, rather than trusting file creation alone.
subprocess.run([ffmpeg, "-v", "error", "-i", str(video), "-f", "null", "-"], check=True)
print(json.dumps({"video":str(video), "bytes":video.stat().st_size, "scenes":len(scenes),
                  "duration_seconds":48, "audio":"silent", "full_decode":"passed"}, indent=2))
