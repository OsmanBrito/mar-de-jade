"""Short deterministic black-powder report for the introductory firearm; no gameplay RNG."""
from pathlib import Path
import wave
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
rate=44100
t=np.arange(round(rate*.44))/rate
rng=np.random.default_rng(1500)
noise=rng.uniform(-1,1,t.size)
air=np.convolve(noise,np.ones(5)/5,mode='same')
crack=(noise-air)*np.exp(-t*110)*.50
body=air*np.exp(-t*20)*.85+np.sin(2*np.pi*74*t)*np.exp(-t*25)*.28
tail=air*np.exp(-t*8)*.12
envelope=np.minimum(1,t/.001)*np.minimum(1,(t[-1]-t)/.020)
samples=np.clip((crack+body+tail)*envelope,-.85,.85)
with wave.open(str(ROOT/'assets/audio/combat/powder-training.wav'),'wb') as out:
    out.setnchannels(1);out.setsampwidth(2);out.setframerate(rate);out.writeframes((samples*26000).astype('<i2').tobytes())
print('powder-training.wav: 0.44 seconds, mono 44.1 kHz, deterministic original cue')
