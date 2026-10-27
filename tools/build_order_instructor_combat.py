"""Index instructor art; retain PNG bytes and source hand anchors from the edited atlas."""
from pathlib import Path
import json
from PIL import Image

folder=Path(__file__).resolve().parents[1]/'assets/art/combat/portugal'
old=json.loads((folder/'duarte-order-frames.json').read_text(encoding='utf-8-sig'))
image=Image.open(folder/'order-instructor-v1.png').convert('RGBA')
assert image.size==(1122,1402)
data=dict(old)
data.update(id='order_instructor',name='Instrutor da Ordem',height=70,source='res://assets/art/combat/portugal/order-instructor-v1.png')
data['frames']=[];data['pivots']=[];data['grips']=[]
cols=[0,374,748,1122];rows=[0,465,935,1402]
for i in range(9):
    left,top=cols[i%3],rows[i//3]
    alpha=image.crop((left,top,cols[i%3+1],rows[i//3+1])).getchannel('A')
    x,y,r,b=alpha.point(lambda v:255 if v>90 else 0).getbbox()
    band=max(3,round((b-y)*.07))
    feet=[px for py in range(b-band,b) for px in range(x,r) if alpha.getpixel((px,py))>100]
    frame=[left+x,top+y,r-x,b-y]
    data['frames'].append(frame);data['pivots'].append([round(sum(feet)/len(feet)-x,2),b-y-2])
    prior=old['frames'][i];grip=old['grips'][i]
    data['grips'].append([round(prior[0]+grip[0]-frame[0],2),round(prior[1]+grip[1]-frame[1],2)])
data['reference_height']=data['frames'][0][3]
(folder/'order-instructor-frames.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Order instructor:',len(data['frames']),'combat poses; source image preserved')
