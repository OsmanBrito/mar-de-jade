"""Validate Portugal inventory art and rebuild its review gallery."""
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]

def build():
    path=ROOT/'data/chapter_01/items.json'
    catalog=json.loads(path.read_text(encoding='utf-8'))
    tiers={t['id']:t for t in json.loads((ROOT/'data/skill_rarities.json').read_text(encoding='utf-8'))['tiers']}
    sources={s['id']:s for s in json.loads((ROOT/'docs/portugal-item-generation.json').read_text(encoding='utf-8'))}
    entries=catalog['items']
    assert len(entries)==18 and len({p['id'] for p in entries})==18
    font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',16)
    small=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',13)
    title=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',24)
    out=Image.new('RGB',(1400,1100),'#17323d')
    d=ImageDraw.Draw(out)
    d.text((20,15),'Portugal · Itens iniciais',font=title,fill='#f5e8cd')
    d.text((20,47),'18 itens · 5 reutilizados de Maré de Ferro · 13 novos · raridades iniciais',font=font,fill='#b9ced5')
    labels={'weapon':'Arma','outfit':'Vestuário','equipment':'Equipamento','accessory':'Acessório','supply':'Suprimento','story':'História · protegido','tool':'Serviço · protegido'}
    for i,p in enumerate(entries):
        tier=tiers[p['rarity']]
        p.update(rarity_level=tier['level'],rarity_name=tier['name'],rarity_color=tier['color'],frame=f"res://assets/ui/skill_frames/{tier['id']}.svg")
        if p['id'] in sources:
            p['source']=sources[p['id']]['source']
            p['origin']='imagegen integrado'
        image_path=ROOT/p['icon'].replace('res://','')
        assert (ROOT/p['frame'].replace('res://','')).exists()
        if p['origin'].startswith('Maré de Ferro'):
            assert hashlib.sha256(image_path.read_bytes()).digest()==hashlib.sha256(Path(p['source']).read_bytes()).digest(),p['id']
        if p['category'] in ('story','tool'):
            assert not p['tradeable'] and not p['discardable']
        im=Image.open(image_path).convert('RGBA')
        assert im.getextrema()[3][0]==0 and im.getbbox(),p['id']
        im=im.crop(im.getbbox())
        im.thumbnail((160,160),Image.Resampling.LANCZOS)
        x,y=(i%5)*280,(i//5)*250+80
        color=tier['color']
        d.rounded_rectangle((x+48,y,x+232,y+185),radius=12,fill='#102a35',outline=color,width=3)
        out.paste(im,(x+(280-im.width)//2,y+7+(160-im.height)//2),im)
        for pip in range(tier['level']):
            px=x+127+pip*13
            d.ellipse((px-3,y+174,px+3,y+180),fill=color)
        d.text((x+10,y+191),p['name'],font=font,fill='#f5e8cd')
        d.text((x+10,y+214),f"Nv. {tier['level']} · {tier['name']}",font=font,fill=color)
        d.text((x+10,y+236),labels[p['category']],font=small,fill='#b9ced5')
    path.write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    out.save(ROOT/'docs/portugal-item-icons.png')
    print('18/18 unique IDs, transparent nonempty PNGs; 5 source hashes match; narrative protection and rarity frames verified.')

if __name__=='__main__':
    build()
