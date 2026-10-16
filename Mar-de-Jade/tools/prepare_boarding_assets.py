"""Copy approved Mar de Ferro art without changing its source pixels; measure metadata."""
import argparse
import hashlib
import json
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/art/combat/boarding'
FILES = [
    'sprites/guard-illustrated-strip.png', 'sprites/rogue-illustrated-strip.png',
    'sprites/sailor-illustrated-strip.png', 'sprites/worker-illustrated-strip.png',
    'sprites/npc-saber.svg', 'sprites/ines-sword.svg',
    'scenery/regional-deck.png', 'scenery/regional-water-illustrated-v1.png',
    'scenery/regional-deckhouse.png', 'scenery/final-cannon-refined-v1.png',
    'scenery/bruma-crate.png', 'scenery/bruma-barrel.png',
    'scenery/regional-sail-reefed-illustrated-v1.png', 'scenery/regional-helm-natural-v1.png',
]
# Original measured hand centres, from Mar de Ferro's actor_equipment.gd.
GRIPS = {
    'guard': [(188,132),(165,134),(162,135),(188,114),(61,129),(166,116)],
    'rogue': [(126,130),(173,139),(178,143),(177,128),(116,134),(165,122)],
}
PROPS = {'deckhouse':'regional-deckhouse.png', 'cannon':'final-cannon-refined-v1.png',
         'crate':'bruma-crate.png', 'barrel':'bruma-barrel.png',
         'mast':'regional-sail-reefed-illustrated-v1.png', 'helm':'regional-helm-natural-v1.png'}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=ROOT.parent/'jogo')
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    copies = []
    for relative in FILES:
        source = args.source/'assets'/relative
        target = OUT/source.name
        content = source.read_bytes()
        target.write_bytes(content)
        copies.append({'source':'assets/'+relative, 'local':str(target.relative_to(ROOT)).replace('\\','/'),
                       'sha256':hashlib.sha256(content).hexdigest()})
    actors = {}
    for kind in ['guard','rogue','sailor','worker']:
        name = kind+'-illustrated-strip.png'
        image = Image.open(OUT/name).convert('RGBA')
        alpha = np.array(image.getchannel('A'))
        frames, pivots = [], []
        for frame in range(6):
            yy, xx = np.where(alpha[:,frame*256:(frame+1)*256]>100)
            bottom = int(yy.max())
            feet_y, feet_x = np.where(alpha[max(0,bottom-13):bottom+1,frame*256:(frame+1)*256]>100)
            frames.append([frame*256,0,256,256])
            pivots.append([round(float(feet_x.mean()),2), bottom+1])
        yy, _ = np.where(alpha[:,:256]>100)
        actors[kind] = {'source':'res://assets/art/combat/boarding/'+name, 'size':list(image.size),
                        'height':60, 'reference_height':int(yy.max()-yy.min()+1),
                        'frames':frames, 'pivots':pivots, 'grips':GRIPS.get(kind,[]),
                        'weapon':{'guard':'sword','rogue':'saber'}.get(kind,'')}
    props = {}
    for key, name in PROPS.items():
        image = Image.open(OUT/name).convert('RGBA')
        region = image.getchannel('A').getbbox()
        props[key] = {'source':'res://assets/art/combat/boarding/'+name,
                      'region':[region[0],region[1],region[2]-region[0],region[3]-region[1]]}
    (OUT/'frames.json').write_text(json.dumps({'actors':actors,'props':props},indent=2)+'\n',encoding='utf-8')
    (OUT/'reused-assets.json').write_text(json.dumps({'source_project':str(args.source.resolve()),
        'source_modified':False,'processing':'PNG/SVG files copied byte for byte. Only JSON measurements created.',
        'copies':copies},indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'copied':len(copies),'actors':len(actors),'source_modified':False}))

if __name__ == '__main__': main()
