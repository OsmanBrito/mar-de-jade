"""Measure source alpha; preserve the generated costume images byte-for-byte."""
from pathlib import Path
import json
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
for battle in [False,True]:
    folder=ROOT/('assets/art/combat/portugal' if battle else 'assets/art/npcs/lisbon')
    old=json.loads((folder/'frames.json').read_text(encoding='utf-8-sig'))['entries']['duarte']
    data=dict(old);image=Image.open(folder/'duarte-order-v2.png').convert('RGBA')
    assert image.size==(1122,1402)
    cols=[0,374,748,1122] if battle else [0,280,561,842,1122]
    rows=[0,465,935,1402] if battle else [0,315,610,910,1205,1402]
    data['frames']=[];data['pivots']=[]
    if battle:data['grips']=[]
    for i in range(9 if battle else 20):
        left=cols[i%(len(cols)-1)];top=rows[i//(len(cols)-1)]
        crop=image.crop((left,top,cols[i%(len(cols)-1)+1],rows[i//(len(cols)-1)+1]))
        alpha=crop.getchannel('A');box=alpha.point(lambda a:255 if a>90 else 0).getbbox();assert box,i
        x,y,r,b=box;frame=[left+x,top+y,r-x,b-y]
        band=max(3,round((b-y)*.07))
        feet=[px for py in range(b-band,b) for px in range(x,r) if alpha.getpixel((px,py))>100]
        data['frames'].append(frame);data['pivots'].append([round(sum(feet)/len(feet)-x,2),b-y-2])
        if battle:
            g=old['grips'][i];orig=old['frames'][i]
            data['grips'].append([round(orig[0]+g[0]-frame[0],2),round(orig[1]+g[1]-frame[1],2)])
    data['source']='res://'+str(folder.relative_to(ROOT)).replace('\\','/')+'/duarte-order-v2.png'
    data['reference_height']=data['frames'][0][3]
    if not battle: data['appearance_status']='Order of Christ costume: new illustrated tabard, mantle and chainmail'
    (folder/'duarte-order-frames.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('Duarte order costume:',len(data['frames']),'frames',data['source'])
