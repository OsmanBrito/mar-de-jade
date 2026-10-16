"""Measure pose rectangles, ground pivots and grips; never rewrite the generated atlases."""
import json
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/art/combat/portugal'
IDS = ['hero', 'hero_child', 'leonor', 'leonor_child', 'duarte', 'tome']
POSES = ['ready', 'walk_a', 'walk_b', 'windup', 'strike', 'recover', 'parry', 'hurt', 'kneel']
GRIPS = [(0.82, .50), (.89, .47), (.86, .48), (.22, .17), (.95, .23), (.90, .48), (.65, .23), (.48, .53), (.43, .70)]
ADJUSTED = {
    'hero': {0:(.82,.48),1:(.87,.48),2:(.83,.48),5:(.86,.52),6:(.61,.19)},
    'hero_child': {0:(.78,.49),1:(.89,.55),2:(.84,.55),3:(.22,.25),4:(.94,.32),5:(.74,.47)},
    'leonor': {0:(.82,.47),4:(.92,.23),5:(.80,.44),6:(.75,.20)},
    'leonor_child': {0:(.77,.50),1:(.89,.51),2:(.83,.52),3:(.22,.22),4:(.93,.28),5:(.82,.48)},
    'duarte': {0:(.82,.43),1:(.83,.43),2:(.82,.45),4:(.93,.23),5:(.82,.42),6:(.35,.20)},
    'tome': {0:(.84,.41),1:(.85,.45),2:(.82,.46),4:(.93,.23),5:(.80,.46),6:(.73,.23)}}
def largest_component(mask):
    parents, runs, previous = [], [], []
    def find(i):
        while parents[i] != i:
            parents[i] = parents[parents[i]]; i = parents[i]
        return i
    for y, row in enumerate(mask):
        change = np.diff(np.r_[False,row,False].astype(np.int8)); current = []
        for start,end in zip(np.where(change==1)[0],np.where(change==-1)[0]):
            index=len(parents); parents.append(index); runs.append((y,int(start),int(end)))
            for a,b,old in previous:
                if a<end and b>start: parents[find(old)] = find(index)
            current.append((start,end,index))
        previous=current
    areas={}
    for i,(_,a,b) in enumerate(runs):
        group=find(i); areas[group]=areas.get(group,0)+b-a
    main=max(areas,key=areas.get); result=np.zeros_like(mask)
    for i,(y,a,b) in enumerate(runs):
        if find(i)==main: result[y,a:b]=True
    return result
def main():
    result = {'schema_version': 1, 'poses': POSES, 'entries': {}}
    font = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 17)
    sheet = Image.new('RGB', (1620, 1320), '#172f33'); draw = ImageDraw.Draw(sheet)
    for actor_index, actor in enumerate(IDS):
        image = Image.open(OUT / (actor+'-v1.png')).convert('RGBA')
        alpha = np.array(image.getchannel('A'))
        frames, pivots, grips = [], [], []
        for index in range(9):
            x, y = round(index % 3 * image.width / 3), round(index // 3 * image.height / 3)
            end_x, end_y = round((index % 3 + 1) * image.width / 3), round((index // 3 + 1) * image.height / 3)
            body = largest_component(alpha[y:end_y,x:end_x]>100)
            yy, xx = np.where(body)
            if len(xx) < 100: raise ValueError((actor, index, 'missing pose'))
            left, top = max(x, x+int(xx.min())-2), max(y, y+int(yy.min())-2)
            right, bottom = min(end_x, x+int(xx.max())+3), min(end_y, y+int(yy.max())+3)
            w, h = right-left, bottom-top
            mask = alpha[top:bottom, left:right] > 100
            feet = np.where(mask[max(0, h-round(h*.10)):])[1]
            foot_x = float(feet.mean()) if len(feet) else w/2
            pivot = [round(foot_x, 2), h-2]
            grip = ADJUSTED.get(actor,{}).get(index,GRIPS[index])
            frames.append([left, top, w, h]); pivots.append(pivot); grips.append([round(grip[0]*w, 2), round(grip[1]*h, 2)])
        height = 44 if actor.endswith('_child') else (63 if actor=='duarte' else 60)
        result['entries'][actor] = {'source': 'res://assets/art/combat/portugal/'+actor+'-v1.png', 'size': list(image.size), 'height': height, 'reference_height': frames[0][3], 'frames': frames, 'pivots': pivots, 'grips': grips}
        # Review composition only; original source pixels stay in the unmodified PNGs.
        for index, rect in enumerate(frames):
            x0, y0 = (index % 9)*180, actor_index*220
            draw.text((x0+8, y0+6), actor+' / '+POSES[index], font=font, fill='#e8dcc1')
            crop = image.crop((rect[0],rect[1],rect[0]+rect[2],rect[1]+rect[3]))
            scale = 155 / frames[0][3]
            crop = crop.resize((round(crop.width*scale), round(crop.height*scale)), Image.Resampling.LANCZOS)
            px, py = round(x0+90-pivots[index][0]*scale), round(y0+207-pivots[index][1]*scale)
            sheet.paste(crop, (px,py), crop)
            gx, gy = px+grips[index][0]*scale, py+grips[index][1]*scale
            draw.ellipse((gx-2,gy-2,gx+2,gy+2), fill='#72e9be')
    (OUT/'frames.json').write_text(json.dumps(result,indent=2)+'\n')
    sheet.save(ROOT/'docs/combat-pose-review.png')
    print(json.dumps({'actors':len(IDS),'poses':len(POSES)*len(IDS)}))
if __name__=='__main__': main()
