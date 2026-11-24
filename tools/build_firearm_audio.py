"""Prepare four Freesound CC0 firearm cues; originals cached beside the credits."""
from pathlib import Path
import hashlib,json,shutil,subprocess,wave
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/audio/combat'
RATE=44100
PROFILES=[('firearm-basic',234869,'mlsulli',1.0,1.15),('firearm-measured',347647,'fennelliott',1.0,.9),('firearm-prepared',244345,'Willlewis',.92,1.4),('firearm-passage',234869,'mlsulli',1.12,.65)]
credits=[]; clips=[]
for event,sound,author,speed,duration in PROFILES:
    source=OUT/'sources'/f'{sound}.mp3'
    raw=subprocess.check_output([shutil.which('ffmpeg'),'-v','error','-i',str(source),'-f','f32le','-ac','1','-ar',str(RATE),'-'])
    data=np.frombuffer(raw,dtype='<f4').copy()
    # Drop silence before the report so the sample starts at the animated release.
    window=np.convolve(np.abs(data),np.ones(220)/220,mode='same')
    onset=max(0,int(np.flatnonzero(window>window.max()*.15)[0])-132)
    data=data[onset:]
    data=np.interp(np.arange(0,len(data),speed),np.arange(len(data)),data)[:int(RATE*duration)]
    data*=.82/max(.001,float(np.abs(data).max()))
    fade=min(1764,len(data)//4)
    data[-fade:]*=np.linspace(1,0,fade)
    data[:44]*=np.linspace(0,1,44)
    with wave.open(str(OUT/(event+'.wav')),'wb') as out:
        out.setnchannels(1);out.setsampwidth(2);out.setframerate(RATE);out.writeframes((data*32767).astype('<i2').tobytes())
    clips.extend([data,np.zeros(RATE//2)])
    urls=(source.with_suffix('.url')).read_text().splitlines()
    credits.append({'event':event,'title':{234869:'Musket Shot.wav',347647:'musket.wav',244345:'Musket Explosion'}[sound],'author':author,'url':urls[0],'download_url':urls[1],'license':'CC0 1.0','license_url':'https://creativecommons.org/publicdomain/zero/1.0/','source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'edits':{'trim_leading_silence':True,'speed':speed,'max_duration':duration,'peak':.82,'fade_out_ms':40}})
(OUT/'firearm-credits.json').write_text(json.dumps({'title':'Firearm technique effects — Freesound','sources':credits},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
with wave.open(str(ROOT/'docs/firearm-audio-comparison.wav'),'wb') as out:
    out.setnchannels(1);out.setsampwidth(2);out.setframerate(RATE);out.writeframes((np.concatenate(clips)*32767).astype('<i2').tobytes())
print('Prepared four distinct cues and comparison: basic, measured, prepared, passage')
