"""Describe source sprite rectangles and foot pivots without modifying PNG artwork."""
import json
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / 'assets/art/portugal-v2'
result = {}
for key, filename in [('hero', 'hero-walk-v1.png'), ('duarte', 'duarte-walk-v1.png')]:
    alpha = np.array(Image.open(ROOT / filename).getchannel('A'))
    def spans(mask):
        edges = np.diff(np.r_[False, mask, False].astype(int))
        return list(zip(np.where(edges == 1)[0], np.where(edges == -1)[0]))
    frames, pivots = [], []
    for top, bottom in spans((alpha > 100).sum(axis=1) > 10):
        band = alpha[top:bottom]
        for left, right in spans((band > 100).sum(axis=0) > 10):
            if right-left < 30:
                continue
            crop = band[:, left:right] > 100
            ys, xs = np.where(crop)
            head_x = np.where(crop[:max(1, int(crop.shape[0]*0.23))])[1].mean()
            frames.append([int(left), int(top), int(right-left), int(bottom-top)])
            pivots.append([round(float(head_x), 2), int(ys.max()+1)])
    assert len(frames) == 16, (key, len(frames))
    result[key] = {'path': 'res://assets/art/portugal-v2/'+filename, 'frames': frames, 'pivots': pivots}
filename = 'quay-props-clean-v2.png'
im = Image.open(ROOT / filename)
frames = []
for y in range(2):
    for x in range(2):
        x0, y0 = x*im.width//2, y*im.height//2
        box = im.getchannel('A').crop((x0,y0,x0+im.width//2,y0+im.height//2)).point(lambda v: 255 if v > 32 else 0).getbbox()
        frames.append([x0+box[0], y0+box[1], box[2]-box[0], box[3]-box[1]])
result['props'] = {'path':'res://assets/art/portugal-v2/'+filename, 'frames':frames}
(ROOT / 'frames.json').write_text(json.dumps(result, indent=2)+'\n')
print('Described 32 actor frames and 4 props; original PNGs preserved.')
