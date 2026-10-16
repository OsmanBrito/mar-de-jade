"""Describe transparent furniture atlas regions without modifying source pixels."""
import json
from pathlib import Path
import numpy as np
from PIL import Image
from build_lisbon_npc_assets import spans

root = Path(__file__).resolve().parents[1]
path = root/'assets/art/portugal-v2/furniture-v1.png'
image = Image.open(path).convert('RGBA')
alpha = np.array(image.getchannel('A'))
rows = [(a,b) for a,b in spans((alpha>100).sum(axis=1)>8) if b-a>50]
assert len(rows) == 2, rows
entries = {}
keys = iter(['bed','table','bench','cupboard','shelf','washstand'])
for top,bottom in rows:
    columns = [(a,b) for a,b in spans((alpha[top:bottom]>100).sum(axis=0)>8) if b-a>50]
    assert len(columns) == 3, columns
    for left,right in columns:
        ys,xs = np.where(alpha[top:bottom,left:right]>100)
        x0,y0 = max(0,left+int(xs.min())-3),max(0,top+int(ys.min())-3)
        x1,y1 = min(image.width,left+int(xs.max())+4),min(image.height,top+int(ys.max())+4)
        entries[next(keys)] = [x0,y0,x1-x0,y1-y0]
(root/'assets/art/portugal-v2/furniture-frames.json').write_text(json.dumps(entries,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'size':image.size,'entries':entries}))
