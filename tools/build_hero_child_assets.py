"""Describe the new childhood protagonist without rewriting the approved NPC cast."""
import json
import numpy as np
from PIL import Image
from build_lisbon_npc_assets import describe, spans, ROOT

entry = describe({
    'id': 'hero_child', 'height': 58,
    'source': 'res://assets/art/npcs/lisbon/hero_child-v1.png',
    'expected_rows': 5, 'west_flip': False,
    'pose_indices': {'seated': 16, 'crouched': 17, 'seated_west': 18, 'crouched_west': 19},
})
destination = ROOT / 'assets/art/portugal-v2/hero-child-frames.json'
destination.write_text(json.dumps(entry, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
print(f"Child protagonist: {len(entry['frames'])} frames; {entry['source_size']}")

source = ROOT / 'assets/art/portugal-v2/hero-story-poses-v1.png'
image = Image.open(source).convert('RGBA')
alpha = np.array(image.getchannel('A'))
rows = [(a,b) for a,b in spans((alpha>100).sum(axis=1)>8) if b-a>35]
assert len(rows) == 2, rows
frames, pivots = [], []
for top,bottom in rows:
    columns = [(a,b) for a,b in spans((alpha[top:bottom]>100).sum(axis=0)>8) if b-a>18]
    assert len(columns) == 2, columns
    for left,right in columns:
        x0,y0 = max(0,left-3),max(0,top-3)
        x1,y1 = min(image.width,right+3),min(image.height,bottom+3)
        crop = alpha[y0:y1,x0:x1]>100
        ys,xs = np.where(crop)
        head = np.where(crop[:max(1,int(crop.shape[0]*0.22))])[1]
        frames.append([x0,y0,x1-x0,y1-y0])
        pivots.append([round(float(head.mean()),2),int(ys.max()+1)])
poses = dict(id='hero_story',height=84,source='res://assets/art/portugal-v2/hero-story-poses-v1.png',
    west_flip=False,frames=frames,pivots=pivots,reference_height=frames[0][3]/0.75,
    pose_indices=dict(seated=0,crouched=1,seated_west=2,crouched_west=3))
(ROOT/'assets/art/portugal-v2/hero-story-poses-frames.json').write_text(json.dumps(poses,indent=2)+'\n',encoding='utf-8')
print('Adult protagonist: 4 story poses')
