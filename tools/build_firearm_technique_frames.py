"""Measure the new transparent source without modifying its pixels."""
import json
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'assets/art/combat/portugal'
image=Image.open(ART/'hero-firearm-techniques-v2.png').convert('RGBA')
assert image.size==(1086,1448),image.size
columns=[0,390,775,1086]; rows=[0,425,737,1042,1448]
muzzles=[(337,26),(730,78),(1068,253),(372,482),(756,520),(1070,691),(346,928),(758,868),(1063,954),(306,1056),(630,1050),(1067,1063)]
frames=[];pivots=[];tips=[]
for i in range(12):
    col=i%3; row=i//3
    left=columns[col]; top=rows[row]; right=columns[col+1]; bottom=rows[row+1]
    if col==2 and row==2: bottom=1053
    if col==2 and row==3: top=1053
    crop=image.crop((left,top,right,bottom))
    bbox=crop.getchannel('A').point(lambda a:255 if a>90 else 0).getbbox()
    assert bbox,i
    x,y,r,b=bbox; frame=[left+x,top+y,r-x,b-y]
    alpha=crop.getchannel('A')
    band=max(3,round(frame[3]*.06))
    points=[px for py in range(b-band,b) for px in range(x,r) if alpha.getpixel((px,py))>100]
    assert points,i
    frames.append(frame);pivots.append([round(sum(points)/len(points)-x,2),frame[3]-2])
    tips.append([muzzles[i][0]-frame[0],muzzles[i][1]-frame[1]])
data={'source':'res://assets/art/combat/portugal/hero-firearm-techniques-v2.png','height':60,'reference_height':frames[1][3],'frames':frames,'pivots':pivots,'muzzles':tips,'rows':{'FO07':[0,1,2],'FO01':[3,4,5],'FO09':[6,7,8],'FO08':[9,10,11]}}
(ART/'firearm-technique-frames.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
print('Distinct technique frame sizes:',[f[2:] for f in frames])
