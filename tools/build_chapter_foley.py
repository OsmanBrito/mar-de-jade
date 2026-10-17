"""Original, deterministic procedural foley; no external recordings."""
import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "assets/audio/chapter/foley"
ROOT.mkdir(parents=True, exist_ok=True)
RATE = 22050


def render(name, seconds, synth):
    rng = random.Random(613)
    smooth = 0.0
    samples = []
    for i in range(int(seconds * RATE)):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        smooth = smooth * .78 + noise * .22
        value = synth(t, noise, smooth)
        samples.append(struct.pack("<h", int(max(-1, min(1, value)) * 22000)))
    with wave.open(str(ROOT / (name + ".wav")), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(b"".join(samples))


render("stone_step", .24, lambda t, n, s: (.6*s + .12*n)*math.exp(-t*24)*min(1,t*800) + .18*math.sin(2*math.pi*110*t)*math.exp(-t*48))
render("cloth", .42, lambda t, n, s: (n-s)*.23*math.sin(math.pi*t/.42)**2*(.7+.3*math.sin(2*math.pi*19*t)))
render("cup", .32, lambda t, n, s: (.25*math.sin(2*math.pi*1380*t)*math.exp(-t*32)+.12*math.sin(2*math.pi*2270*t)*math.exp(-t*45)+s*.2*math.exp(-t*65))*min(1,t*1800))
render("water", .6, lambda t, n, s: (.32*s+.04*math.sin(2*math.pi*(190*t+15*math.sin(t*31))))*math.sin(math.pi*t/.6)**2)
print("Generated four original chapter foley cues")
