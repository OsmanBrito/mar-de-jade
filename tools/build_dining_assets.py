"""Describe atlas cells using original alpha; source pixels remain unchanged."""
import json
from pathlib import Path
import numpy as np
from PIL import Image

root = Path(__file__).resolve().parents[1]
image = Image.open(root / 'assets/art/portugal-v2/dining-v1.png').convert('RGBA')
alpha = np.array(image.getchannel('A'))
assert alpha.min() == 0, 'Atlas must have genuine alpha'
entries = {}
for index, key in enumerate(['stool_east','stool_west','bowl','cup','bread','napkin']):
    left, top = (index % 3) * image.width // 3, (index // 3) * image.height // 2
    right, bottom = left + image.width // 3, top + image.height // 2
    ys, xs = np.where(alpha[top:bottom,left:right] > 100)
    assert len(xs) > 100, key
    x0, y0 = max(left,left+int(xs.min())-3), max(top,top+int(ys.min())-3)
    x1, y1 = min(right,left+int(xs.max())+4), min(bottom,top+int(ys.max())+4)
    entries[key] = [x0,y0,x1-x0,y1-y0]
(root / 'assets/art/portugal-v2/dining-frames.json').write_text(json.dumps(entries,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'size':image.size,'alpha_min':int(alpha.min()),'entries':entries}))
