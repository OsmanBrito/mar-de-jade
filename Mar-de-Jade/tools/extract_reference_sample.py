"""Read-only Unity bundle sample extraction for the local visual study.

Source files are never written. PNGs and evidence stay in the project study folder.
"""
from pathlib import Path
import argparse, gzip, hashlib, json, re, sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.tools/unitypy'))
import UnityPy
from PIL import Image, ImageDraw, ImageFont

SOURCE = Path('C:/Program Files (x86)/Steam/steamapps/common/WulinSH/Wulin_Data/StreamingAssets/aa/StandaloneWindows64/map_assets_all.bundle')
OUT = ROOT / 'reference-study/heros-adventure'

def main():
    global OUT
    parser = argparse.ArgumentParser()
    parser.add_argument('--match', default='')
    parser.add_argument('--ids', default='')
    parser.add_argument('--limit', type=int, default=48)
    parser.add_argument('--output', default='reference-study/heros-adventure')
    args = parser.parse_args()
    OUT = (ROOT / args.output).resolve()
    if not OUT.is_relative_to(ROOT): raise ValueError('Output must stay inside the project')
    OUT.mkdir(parents=True, exist_ok=True)
    raw = SOURCE.read_bytes()
    digest = hashlib.sha256(raw).hexdigest()
    env = UnityPy.load(gzip.decompress(raw) if raw[:2] == b'\x1f\x8b' else raw)
    print('Bundle loaded', flush=True)
    index = []
    sprites = {}
    for obj in env.objects:
        if obj.type.name == 'Sprite':
            name = obj.peek_name() or ''
            index.append({'id':obj.path_id, 'file':obj.assets_file.name, 'name':name})
            sprites[obj.path_id] = obj
    (OUT / 'sprite-index.json').write_text(json.dumps(index,ensure_ascii=False,indent=2),encoding='utf-8')
    print(f'Indexed {len(index)} sprites',flush=True)
    if not args.match and not args.ids:
        return
    ids = {int(x) for x in args.ids.split(',') if x}
    selected = [row for row in index if row['id'] in ids or (args.match and re.search(args.match,row['name'],re.I))][:args.limit]
    records, thumbs, errors = [], [], []
    (OUT / 'sprites').mkdir(exist_ok=True)
    for row in selected:
        try:
            obj = sprites[row['id']].read()
            im = obj.image.convert('RGBA')
            filename = f"{row['id']}.png"
            im.save(OUT / 'sprites' / filename)
            record = dict(row, path='sprites/'+filename,width=im.width,height=im.height,
                          pivot={'x':obj.m_Pivot.x,'y':obj.m_Pivot.y},pixels_per_unit=obj.m_PixelsToUnits)
            records.append(record)
            thumbs.append((record,im.copy()))
            print(f"Exported {row['name']} {im.size}",flush=True)
        except Exception as exc:
            errors.append(dict(row,error=str(exc)))
            print(f"Failed {row['name']}: {exc}",flush=True)
    manifest = {'source':str(SOURCE),'source_sha256':digest,'tool':'UnityPy 1.25.4','scope':'local visual study',
                'source_unchanged':hashlib.sha256(SOURCE.read_bytes()).hexdigest()==digest,
                'sprites':records,'errors':errors}
    (OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
    for page in range((len(thumbs)+15)//16):
        sheet = Image.new('RGB',(1200,1000),'#152a2c'); draw=ImageDraw.Draw(sheet)
        for slot,(record,im) in enumerate(thumbs[page*16:page*16+16]):
            x=(slot%4)*300; y=(slot//4)*250
            draw.rectangle((x+8,y+8,x+291,y+200),fill='#34484a')
            factor = max(1,min(270//im.width,180//im.height))
            im = im.resize((im.width*factor,im.height*factor),Image.Resampling.NEAREST)
            im.thumbnail((270,180),Image.Resampling.NEAREST)
            sheet.paste(im,(x+150-im.width//2,y+105-im.height//2),im)
            draw.text((x+12,y+207),str(record['id']),fill='#e9dabc')
            draw.text((x+12,y+225),record['name'][:36],fill='#e9dabc')
        sheet.save(OUT/f'gallery-{page+1:02}.png')
    print(json.dumps({'exported':len(records),'errors':len(errors),'source_unchanged':manifest['source_unchanged']}),flush=True)

if __name__=='__main__': main()
