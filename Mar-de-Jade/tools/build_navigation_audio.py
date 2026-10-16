"""Generate original, deterministic maritime ambience. Standard library only."""
from pathlib import Path
import math
import random
import struct
import wave
import json

RATE = 22050
OUTPUT = Path(__file__).resolve().parents[1] / "assets/audio/navigation"


def filtered_periodic(values, alpha):
    state = 0.0
    result = []
    for turn in range(2):
        result = []
        for value in values:
            state += (value - state) * alpha
            result.append(state)
    return result


def write(name, samples, loop=False):
    peak = max(abs(v) for v in samples)
    samples = [v * 0.55 / max(0.55, peak) for v in samples]
    # Zero-slope short seam, avoiding a click when the ambience wraps.
    fade = round(RATE * (0.025 if loop else 0.008))
    for i in range(min(fade, len(samples)//2)):
        gain = math.sin(i / fade * math.pi * 0.5) ** 2
        samples[i] *= gain
        samples[-1-i] *= gain
    OUTPUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT / (name + ".wav")), "wb") as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(RATE)
        audio.writeframes(b"".join(struct.pack("<h", round(v * 32767)) for v in samples))
    return {"seconds": round(len(samples) / RATE, 3), "peak": round(max(abs(v) for v in samples), 4), "seam": round(abs(samples[-1]-samples[0]), 5), "loop": loop}


def main():
    rng = random.Random(15102026)
    count = RATE * 12
    raw = [rng.uniform(-1, 1) for _ in range(count)]
    low = filtered_periodic(raw, 0.045)
    mid = filtered_periodic(raw, 0.22)
    sea, wind = [], []
    for i in range(count):
        phase = 2 * math.pi * i / count
        swell = 0.6 + 0.21 * math.sin(phase * 3) + 0.1 * math.sin(phase * 5 + 1)
        sea.append((mid[i] * 0.48 + low[i] * 0.85) * swell)
        wind.append((low[i] * 0.75 + (mid[i]-low[i]) * 0.2) * (0.8 + 0.16 * math.sin(phase * 2)))
    report = {"sea": write("sea", sea, True), "wind": write("wind", wind, True)}
    # Continuous bow wash and loose cordage. Separate layers keep music/SFX
    # mixable without masking the swell with a permanently loud noise bed.
    wash, rigging = [], []
    for i in range(count):
        t = i / RATE
        cycle = 2 * math.pi * i / count
        wash.append((mid[i]-low[i])*0.55*(0.65+0.22*math.sin(cycle*5)+0.1*math.sin(cycle*11)))
        rigging.append((math.sin(t*2*math.pi*214+0.9*math.sin(cycle*7))*0.032+
                        math.sin(t*2*math.pi*329+0.5*math.sin(cycle*9))*0.019)*
                       (0.3+0.7*max(0,math.sin(cycle*3+0.6))**5))
    report["bow_wash"] = write("bow_wash", wash, True)
    report["rigging"] = write("rigging", rigging, True)
    for name, duration in [("hull_wave_l",2.25),("hull_wave_r",2.65),("sail_flap",1.4)]:
        samples = []; low_state = 0.0; mid_state = 0.0
        for i in range(round(duration * RATE)):
            t = i / RATE
            white = rng.uniform(-1,1)
            low_state += (white-low_state)*0.025
            mid_state += (white-mid_state)*0.32
            attack = min(1,t*32)
            if name.startswith("hull_wave"):
                surge = attack * math.exp(-t*2.2)
                foam = min(1,t*7) * math.exp(-t*1.7)
                thump = math.sin(t*2*math.pi*(63-8*min(t,1))) * math.exp(-t*11) * attack
                value = low_state*1.1*surge+(mid_state-low_state)*0.65*foam+thump*0.15
            else:
                flaps = max(0,math.sin(t*24+math.sin(t*6)))**3
                value = (low_state*0.75+(mid_state-low_state)*0.2)*flaps*math.sin(math.pi*t/duration)**2
            samples.append(value)
        report[name] = write(name, samples)
    for name, duration in [("gull", 0.85), ("creak", 0.65), ("discovery", 1.1)]:
        data = []
        phase = 0.0
        for i in range(round(duration * RATE)):
            t = i / RATE
            u = t / duration
            envelope = math.sin(math.pi * u) ** 2
            if name == "gull":
                frequency = 780 + 550 * math.sin(math.pi * u) + 80 * math.sin(t * 65)
                phase += 2 * math.pi * frequency / RATE
                value = (math.sin(phase) + 0.25 * math.sin(phase * 2)) * envelope * 0.19
            elif name == "creak":
                phase += 2 * math.pi * (160 + 210 * (1-u)**2) / RATE
                value = math.sin(phase + 0.5*math.sin(t*120)) * envelope * 0.14
            else:
                value = (math.sin(t*2*math.pi*622) + 0.4*math.sin(t*2*math.pi*933)) * math.exp(-t*4) * min(1,t*80) * 0.23
            data.append(value)
        report[name] = write(name, data)
    (OUTPUT / "sources.json").write_text(json.dumps({"source":"Original procedural synthesis; tools/build_navigation_audio.py", "sample_rate": RATE, "assets":report}, indent=2), encoding="utf-8")
    print(json.dumps(report))


if __name__ == "__main__":
    main()
