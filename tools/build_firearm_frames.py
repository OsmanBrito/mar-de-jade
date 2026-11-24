"""Measure the generated firearm atlas without changing its source pixels."""
import json
from pathlib import Path
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'assets/art/combat/portugal'
image = Image.open(ART / 'hero-firearm-v1.png').convert('RGBA')
assert image.size == (1254, 1254)
# Aim poses extend past a nominal third: preserve the whole barrel.
columns, rows = [0, 455, 870, 1254], [0, 435, 846, 1254]
muzzles = [(402,94),(809,136),(1203,146),(444,522),(844,522),(1218,560),(394,894),(785,1124),(1218,1046)]
frames, pivots, tips = [], [], []
for i in range(9):
    left, top = columns[i % 3], rows[i // 3]
    crop = image.crop((left,top,columns[i % 3+1],rows[i // 3+1]))
    bbox = crop.getchannel('A').point(lambda a: 255 if a > 90 else 0).getbbox()
    assert bbox, i
    x,y,right,bottom = bbox
    frame = [left+x,top+y,right-x,bottom-y]
    feet = crop.getchannel('A').crop((x,bottom-round(frame[3]*0.1),right,bottom))
    samples = [px for py in range(feet.height) for px in range(feet.width) if feet.getpixel((px,py)) > 100]
    frames.append(frame); pivots.append([round(sum(samples)/len(samples),2),frame[3]-2])
    tips.append([muzzles[i][0]-frame[0],muzzles[i][1]-frame[1]])
data = dict(source='res://assets/art/combat/portugal/hero-firearm-v1.png',height=60,reference_height=frames[0][3],frames=frames,pivots=pivots,muzzles=tips)
(ART/'firearm-frames.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
print('FIREARM_ATLAS: 9 full poses, transparent source preserved')
