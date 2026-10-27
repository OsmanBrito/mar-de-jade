"""Assemble Blender frames, existing project audio and approved dialogue.

Requires ffmpeg on PATH. No user data or campaign state is accessed.
"""
import json
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
QA = ROOT / ".qa-runtime/leonor-blender"
FRAMES = QA / "frames"
SOURCE = ROOT / "art-source/blender/leonor-praca"
PREVIEW = ROOT / "previews"
ASSET = ROOT / "assets/cinematics"
PREVIEW.mkdir(exist_ok=True)
ASSET.mkdir(exist_ok=True)
FFMPEG = shutil.which("ffmpeg")
if not FFMPEG:
    raise SystemExit("ffmpeg não encontrado no PATH.")
if len(list(FRAMES.glob("praca_*.png"))) != 384:
    raise SystemExit("São necessários os 384 quadros renderizados pelo Blender.")

subtitles = SOURCE / "leonor-praca.ass"
subtitles.write_text("""[Script Info]
ScriptType: v4.00+
PlayResX: 1280
PlayResY: 720
WrapStyle: 0

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Dialogue,Georgia,27,&H00F1F2EE,&H00FFFFFF,&H001B221D,&H751B221D,0,0,0,0,100,100,0,0,1,2,1,2,50,50,42,1
Style: Title,Georgia,29,&H00F1F2EE,&H00FFFFFF,&H001B221D,&H751B221D,0,0,0,0,100,100,3,0,1,1,1,8,50,50,38,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:00.25,0:00:02.10,Title,,0,0,0,,{\\fad(200,350)}MAR DE JADE · A PRAÇA DO TEJO
Dialogue: 0,0:00:12.25,0:00:13.35,Dialogue,,0,0,0,,{\\fad(100,100)}Mestre: Outra vez.
Dialogue: 0,0:00:13.55,0:00:14.65,Dialogue,,0,0,0,,{\\fad(100,100)}Leonor: A tua mão.
""", encoding="utf8")

# A restrained score and foley already authored for this project.
music = ROOT / "assets/audio/chapter/music/Echoes_of_the_Templar_City.mp3"
effects = [
    ("assets/audio/chapter/foley/stone_step.wav", 1.82, .30),
    ("assets/audio/chapter/foley/stone_step.wav", 2.14, .28),
    ("assets/audio/chapter/foley/stone_step.wav", 2.48, .26),
    ("assets/audio/chapter/foley/stone_step.wav", 4.20, .32),
    ("assets/audio/combat/swing.wav", 4.37, .30),
    ("assets/audio/combat/guard.wav", 4.76, .35),
    ("assets/audio/chapter/foley/stone_step.wav", 5.65, .28),
    ("assets/audio/chapter/foley/stone_step.wav", 6.25, .25),
    ("assets/audio/chapter/foley/cloth.wav", 8.18, .18),
    ("assets/audio/combat/fast_swing.wav", 9.20, .27),
    ("assets/audio/combat/guard.wav", 9.76, .38),
    ("assets/audio/combat/posture_break.wav", 10.00, .14),
    ("assets/audio/combat/footstep_wood.wav", 10.91, .40),
    ("assets/audio/combat/footstep_wood.wav", 11.18, .18),
]
command = [FFMPEG, "-hide_banner", "-loglevel", "warning", "-y", "-framerate", "24", "-start_number", "1", "-i", str(FRAMES / "praca_%04d.png"), "-i", str(music)]
for path, _, _ in effects:
    command += ["-i", str(ROOT / path)]
filters = ["[1:a]atrim=0:16,asetpts=PTS-STARTPTS,volume=0.13,afade=t=in:d=0.8,afade=t=out:st=14.7:d=1.3[a0]"]
for index, (_, time, volume) in enumerate(effects, 2):
    delay = round(time * 1000)
    filters.append(f"[{index}:a]volume={volume},adelay={delay}|{delay}[a{index-1}]")
labels = "".join(f"[a{i}]" for i in range(len(effects) + 1))
filters.append(labels + f"amix=inputs={len(effects)+1}:normalize=0,alimiter=limit=0.9,atrim=0:16[audio]")
# Relative filter paths avoid colon escaping on Windows.
filters.append("[0:v]subtitles=art-source/blender/leonor-praca/leonor-praca.ass,fade=t=in:d=0.35,fade=t=out:st=15.6:d=0.4[video]")
movie = PREVIEW / "leonor-praca.mp4"
command += ["-filter_complex", ";".join(filters), "-map", "[video]", "-map", "[audio]", "-c:v", "libx264", "-crf", "18", "-preset", "medium", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k", "-t", "16", "-movflags", "+faststart", str(movie)]
subprocess.run(command, cwd=ROOT, check=True)
subprocess.run([FFMPEG, "-hide_banner", "-loglevel", "warning", "-y", "-i", str(movie), "-c:v", "libtheora", "-q:v", "8", "-c:a", "libvorbis", "-q:a", "5", str(ASSET / "leonor-praca.ogv")], check=True)
subprocess.run([FFMPEG, "-hide_banner", "-loglevel", "error", "-y", "-ss", "11.4", "-i", str(movie), "-frames:v", "1", str(PREVIEW / "leonor-praca.jpg")], check=True)
print(json.dumps({"movie": str(movie), "godot": str(ASSET / "leonor-praca.ogv"), "frames": 384, "fps": 24, "duration": 16}, ensure_ascii=False))
