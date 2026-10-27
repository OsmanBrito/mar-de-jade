"""Index generated atlases without altering their illustrated pixels or alpha."""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / 'assets/art/npcs/lisbon/order-house'
ROLES = {
    'brother': ('Irmão da Ordem', 78),
    'instructor': ('Instrutor da Ordem', 82),
    'server': ('Servidor da casa', 76),
    'cook': ('Cozinheira da casa', 76),
    'grandmaster': ('Grão-Mestre da Ordem', 86),
}
ROW_CUTS = {
    'brother': [0, 320, 626, 945, 1233],
    'instructor': [0, 320, 635, 965, 1280],
    'server': [0, 325, 646, 970, 1288],
    'cook': [0, 319, 626, 948, 1250],
    'grandmaster': [0, 322, 638, 972, 1285],
}

def build():
    entries = {}
    for role, (name, height) in ROLES.items():
        path = FOLDER / f'order-{role}-v1.png'
        with Image.open(path) as raw:
            image = raw.convert('RGBA')
        alpha = image.getchannel('A')
        assert alpha.getextrema() == (0, 255), f'{role}: missing transparency'
        width, tall = image.size
        frames, pivots = [], []
        for index in range(16):
            col, row = index % 4, index // 4
            cuts = ROW_CUTS.get(role, [round(r*tall/4) for r in range(5)])
            left, top = round(col * width / 4), cuts[row]
            right, bottom = round((col + 1) * width / 4), cuts[row+1]
            slot = alpha.crop((left, top, right, bottom))
            box = slot.point(lambda a: 255 if a > 90 else 0).getbbox()
            assert box, f'{role}: empty frame {index}'
            x, y, r, b = box
            band = max(3, round((b-y)*.06))
            feet = [px for py in range(b-band,b) for px in range(x,r) if slot.getpixel((px,py)) > 100]
            frames.append([left+x, top+y, r-x, b-y])
            pivots.append([round(sum(feet)/len(feet)-x, 2), b-y-2])
        heights = [frame[3] for frame in frames]
        assert max(heights)/min(heights) < 1.23, f'{role}: inconsistent figure scale'
        entries['order_'+role] = {
            'id': 'order_'+role, 'name': name, 'height': height,
            'source': 'res://'+path.relative_to(ROOT).as_posix(),
            'reference_height': sorted(heights)[len(heights)//2],
            'frames': frames, 'pivots': pivots, 'west_flip': False,
            'source_size': [width, tall], 'expected_rows': 4,
            'appearance_status': 'Original illustrated Order-house costume; 4 facings and idle plus 3 walking poses',
        }
        print(role, len(frames), 'frames', image.size, 'alpha verified')
    (FOLDER/'frames.json').write_text(json.dumps({'entries':entries},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

if __name__ == '__main__':
    build()
