"""Validate Portugal passive assets and rebuild the final review gallery."""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]

def build():
    path = ROOT / 'data/chapter_01/passives.json'
    catalog = json.loads(path.read_text(encoding='utf-8'))
    tiers = {t['id']: t for t in json.loads((ROOT / 'data/skill_rarities.json').read_text(encoding='utf-8'))['tiers']}
    sources = {s['id']:s for s in json.loads((ROOT / 'docs/portugal-passive-generation.json').read_text(encoding='utf-8'))}
    entries = catalog['passives']
    assert len(entries) == 8 and len({p['id'] for p in entries}) == 8
    assert catalog['equip_limit'] == 4
    assert sum(p['owner']=='hero' and p['weapon'] is None for p in entries)==2
    assert {p['weapon'] for p in entries if p['weapon']} == {'ES','LA','MC','FO','PU'}
    font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf',16)
    small = ImageFont.truetype('C:/Windows/Fonts/arial.ttf',13)
    title = ImageFont.truetype('C:/Windows/Fonts/arial.ttf',24)
    out = Image.new('RGB',(1200,600),'#17323d')
    d = ImageDraw.Draw(out)
    d.text((20,15),'Portugal · Passivas iniciais',font=title,fill='#f5e8cd')
    d.text((20,46),'Até 4 equipadas por personagem · efeitos condicionais · classificação inicial',font=font,fill='#b9ced5')
    for i,p in enumerate(entries):
        tier = tiers[p['rarity']]
        p.update(rarity_level=tier['level'],rarity_name=tier['name'],rarity_color=tier['color'],frame=f"res://assets/ui/skill_frames/{tier['id']}.svg",origin='imagegen integrado',source=sources[p['id']]['source'])
        assert (ROOT / p['frame'].replace('res://','')).exists()
        image_path = ROOT / p['icon'].replace('res://','')
        im = Image.open(image_path).convert('RGBA')
        assert im.getextrema()[3][0]==0 and im.getbbox(),p['id']
        im = im.crop(im.getbbox())
        im.thumbnail((170,160),Image.Resampling.LANCZOS)
        x,y = (i%4)*300,(i//4)*260+80
        color=tier['color']
        d.rounded_rectangle((x+58,y,x+242,y+185),radius=12,fill='#102a35',outline=color,width=3)
        out.paste(im,(x+(300-im.width)//2,y+7+(160-im.height)//2),im)
        d.ellipse((x+47,y-5,x+79,y+27),fill='#102a35',outline='#f5e8cd',width=2)
        d.text((x+57,y+1),'P',font=font,fill='#f5e8cd')
        for pip in range(tier['level']):
            px=x+137+pip*13
            d.ellipse((px-3,y+174,px+3,y+180),fill=color)
        d.text((x+12,y+191),p['id']+' · '+p['name'],font=font,fill='#f5e8cd')
        d.text((x+12,y+214),f"Nv. {tier['level']} · {tier['name']}",font=font,fill=color)
        owner='Duarte' if p['owner']=='duarte' else {'ES':'Espada','LA':'Lança','MC':'Machado','FO':'Arma de fogo','PU':'Desarmado'}.get(p['weapon'],'Geral do protagonista')
        d.text((x+12,y+237),owner,font=small,fill='#b9ced5')
    path.write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    out.save(ROOT / 'docs/portugal-passive-icons.png')
    print('8/8 unique IDs, expected owners/weapons, transparent nonempty PNGs and rarity frames verified.')

if __name__=='__main__':
    build()
