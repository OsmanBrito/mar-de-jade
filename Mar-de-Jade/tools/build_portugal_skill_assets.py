"""Copy approved sources and write the Portugal icon catalog and review gallery."""
import json
import shutil
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'assets/art/skills/portugal'
SOURCE = Path('C:/Users/gamer/Documents/ChatGPT/jogo/assets/skill_icons')
REUSE = [
    ('ES01', 'Corte de Precisão', 'ines_0'),
    ('ES07', 'Ponta Breve', 'ines_2'),
    ('ES08', 'Corte de Passagem', 'ines_1'),
    ('ES09', 'Guarda Cruzada', 'ines_14'),
    ('DP01', 'Defesa Perfeita', 'ines_3'),
    ('DU01', 'Guarda Companheira', 'ines_14'),
    ('DU02', 'Ponta da Guarda', 'ines_2'),
]

def build():
    DEST.mkdir(parents=True, exist_ok=True)
    manifest = []
    for key, name, source in REUSE:
        target = DEST / f'{key}.png'
        shutil.copy2(SOURCE / f'{source}.png', target)
        manifest.append(dict(id=key, name=name, icon=f'res://assets/art/skills/portugal/{key}.png', origin='Maré de Ferro; reutilização autorizada', source=str(SOURCE / f'{source}.png'), kind='companion' if key.startswith('DU') else 'universal' if key == 'DP01' else 'weapon'))
    generated = ROOT / 'docs/portugal-skill-generation.json'
    if generated.exists():
        for entry in json.loads(generated.read_text(encoding='utf-8')):
            if (DEST / f"{entry['id']}.png").exists():
                manifest.append(dict(id=entry['id'], name=entry['name'], icon=f"res://assets/art/skills/portugal/{entry['id']}.png", origin='imagegen integrado', source=entry['source'], kind='weapon'))
    manifest.sort(key=lambda x: x['id'])
    rarities = json.loads((ROOT / 'data/skill_rarities.json').read_text(encoding='utf-8'))
    tiers = {tier['id']: tier for tier in rarities['tiers']}
    frames = ROOT / 'assets/ui/skill_frames'
    frames.mkdir(parents=True, exist_ok=True)
    for tier in tiers.values():
        level, color = tier['level'], tier['color']
        pips = ''.join(f'<circle cx="{38+i*13}" cy="112" r="3" fill="{color}"/>' for i in range(level))
        svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><rect x="3" y="3" width="122" height="122" rx="12" fill="#102A35" stroke="{color}" stroke-width="3"/><rect x="9" y="9" width="110" height="94" rx="8" fill="#17323D" stroke="{color}" stroke-opacity="0.35"/>{pips}</svg>\n'
        (frames / f"{tier['id']}.svg").write_text(svg, encoding='utf-8')
    for entry in manifest:
        key = entry['id']
        rarity = 'rare' if key == 'DP01' or key.endswith('09') else 'common' if key.endswith('07') or key == 'DU02' else 'uncommon'
        tier = tiers[rarity]
        entry.update(rarity=rarity, rarity_level=tier['level'], rarity_name=tier['name'], rarity_color=tier['color'], frame=f'res://assets/ui/skill_frames/{rarity}.svg')
    (ROOT / 'data/chapter_01/skill_icons.json').write_text(json.dumps(dict(schema_version=2, scope='C01 Portugal; catálogo v2, Fundamento', rarity_definitions='res://data/skill_rarities.json', classification_status='initial', skills=manifest), ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 16)
    out = Image.new('RGB', (1400, ((len(manifest)+4)//5)*240), '#17323d')
    draw = ImageDraw.Draw(out)
    for i, entry in enumerate(manifest):
        im = Image.open(DEST / f"{entry['id']}.png").convert('RGBA')
        assert im.getextrema()[3][0] == 0, f"No transparency: {entry['id']}"
        bounds = im.getbbox()
        assert bounds, f"Empty asset: {entry['id']}"
        im = im.crop(bounds)
        im.thumbnail((160,160), Image.Resampling.LANCZOS)
        x, y = (i%5)*280, (i//5)*240
        color = entry['rarity_color']
        draw.rounded_rectangle((x+48,y+3,x+232,y+188), radius=12, fill='#102A35', outline=color, width=3)
        out.paste(im, (x+(280-im.width)//2, y+8+(160-im.height)//2), im)
        for pip in range(entry['rarity_level']):
            px = x+116+pip*13
            draw.ellipse((px-3,y+175,px+3,y+181),fill=color)
        # Labels sit outside the frame; pips remain visible inside it.
        draw.rectangle((x+5,y+190,x+275,y+239),fill='#17323d')
        draw.text((x+10,y+195), entry['id']+' · '+entry['name'], font=font, fill='#f5e8cd')
        draw.text((x+10,y+218), f"Nv. {entry['rarity_level']} · {entry['rarity_name']}", font=font, fill=color)
    out.save(ROOT / 'docs/portugal-skill-icons.png')
    print(f'{len(manifest)} icons copied, transparent and nonempty; gallery written.')

if __name__ == '__main__':
    build()
