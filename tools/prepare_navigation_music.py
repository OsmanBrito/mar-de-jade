"""Copy the user-supplied tracks unchanged and document playback trim.

Input loudness measured with FFmpeg loudnorm; playback aims for -20 LUFS before
the game's music fader. No re-encoding or changes to the files in Downloads.
"""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys

TRACKS = [
    ("Horizon_of_the_Caravel.mp3", "Horizon of the Caravel", -11.52, 0.50),
    ("Sails_Against_The_Horizon.mp3", "Sails Against the Horizon", -11.38, 0.11),
    ("Salt_on_the_Bowsprit.mp3", "Salt on the Bowsprit", -11.28, 0.36),
    ("Where_the_Map_Ends.mp3", "Where the Map Ends", -11.34, 0.69),
    ("Vamos_ao_Mar.mp3", "Vamos ao Mar", -10.93, 0.57),
    ("O_vento_no_peito.mp3", "O vento no peito", -11.44, 0.42),
]
ROOT = Path(__file__).resolve().parents[1]


def main():
    source = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.home() / "Downloads"
    output = ROOT / "assets/audio/navigation/music"
    output.mkdir(parents=True, exist_ok=True)
    tracks = []
    for filename, title, loudness, peak in TRACKS:
        original = source / filename
        destination = output / filename
        shutil.copy2(original, destination)
        info = json.loads(subprocess.check_output([
            "ffprobe", "-v", "error", "-show_entries", "format=duration",
            "-of", "json", str(destination),
        ]))
        tracks.append({
            "title": title, "file": filename,
            "seconds": round(float(info["format"]["duration"]), 3),
            "input_lufs": loudness, "input_true_peak_db": peak,
            "gain_db": round(-20 - loudness, 2),
            "sha256": hashlib.sha256(destination.read_bytes()).hexdigest(),
        })
    manifest = {
        "source": "Six MP3 files supplied by the user on 2026-10-15; originals copied unchanged.",
        "loudness_analysis": "FFmpeg loudnorm input_i and input_tp; constant playback gain only.",
        "crossfade_seconds": 5.0,
        "tracks": tracks,
    }
    (output / "playlist.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(json.dumps({"tracks": len(tracks), "seconds": sum(t["seconds"] for t in tracks)}))


if __name__ == "__main__":
    main()
