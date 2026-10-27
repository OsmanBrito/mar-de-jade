"""Normalize the generated side walk, keeping a shared scale and head anchor.

This is sprite preparation only: no repainting, limb warping or per-pose scale.
The raw generation remains available beside the game atlas.
"""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'assets/art/portugal-v2'
SIZE = 96


def build():
    raw = Image.open(ART / 'hero-child-side-walk-raw-v1.png').convert('RGBA')
    crops = []
    anchors = []
    for row in range(2):
        for column in range(4):
            cell = raw.crop((round(column*raw.width/4), round(row*raw.height/2),
                             round((column+1)*raw.width/4), round((row+1)*raw.height/2)))
            bbox = cell.getchannel('A').point(lambda a: 255 if a > 32 else 0).getbbox()
            assert bbox is not None
            crop = cell.crop(bbox)
            alpha = crop.getchannel('A')
            head = [(x, y) for y in range(round(crop.height*.25))
                    for x in range(crop.width) if alpha.getpixel((x, y)) > 128]
            assert head
            anchors.append(sum(x for x, _ in head)/len(head))
            crops.append(crop)
    scale = min(SIZE/max(c.height for c in crops),
                (SIZE/2-2)/max(anchors),
                (SIZE/2-2)/max(c.width-a for c, a in zip(crops, anchors)))
    atlas = Image.new('RGBA', (SIZE*8, SIZE))
    for index, (crop, anchor) in enumerate(zip(crops, anchors)):
        width, height = round(crop.width*scale), round(crop.height*scale)
        resized = crop.resize((width, height), Image.Resampling.NEAREST)
        x, y = round(SIZE/2-anchor*scale), SIZE-height
        assert x >= 0 and x+width <= SIZE and y >= 0
        atlas.alpha_composite(resized, (index*SIZE+x, y))
    # The same metres-per-pixel convention as the vertical walk, including
    # any transparent margin required for a wide stride.
    reference_height = max(c.height for c in crops)*scale
    atlas.save(ART / 'hero-child-side-walk-v1.png')
    manifest = dict(source='res://assets/art/portugal-v2/hero-child-side-walk-v1.png',
                    frame_size=SIZE, reference_height=round(reference_height, 6),
                    anchor=[SIZE/2, SIZE], facing='east', west_flip=True,
                    frames=8, layout=[8, 1], source_layout=[4, 2])
    (ART / 'hero-child-side-walk-frames.json').write_text(
        json.dumps(manifest, indent=2)+'\n', encoding='utf-8')
    print('Built eight grounded side-walk phases:', manifest['reference_height'])


if __name__ == '__main__':
    build()
