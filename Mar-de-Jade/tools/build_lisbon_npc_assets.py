"""Describe generated sprite frames and build review galleries; preserve source PNGs."""
import json, html
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[1]
CATALOG=ROOT/'data/chapter_01/lisbon_npcs.json'
OUT=ROOT/'assets/art/npcs/lisbon'

def spans(mask):
    edges=np.diff(np.r_[False,mask,False].astype(int))
    return [(int(a),int(b)) for a,b in zip(np.where(edges==1)[0],np.where(edges==-1)[0])]

def describe(entry):
    source=ROOT/entry['source'].removeprefix('res://')
    im=Image.open(source).convert('RGBA'); alpha=np.array(im.getchannel('A'))
    rows=[(a,b) for a,b in spans((alpha>100).sum(axis=1)>8) if b-a>35]
    if len(rows)!=entry['expected_rows']:
        raise ValueError(f"{entry['id']}: expected {entry['expected_rows']} rows, found {rows}")
    frames=[]; pivots=[]
    for top,bottom in rows:
        band=alpha[top:bottom]
        columns=[(a,b) for a,b in spans((band>100).sum(axis=0)>8) if b-a>18]
        if len(columns)!=4: raise ValueError(f"{entry['id']}: row {top} has {len(columns)} columns: {columns}")
        for left,right in columns:
            # Source rectangles include edge pixels around the robust silhouette bounds.
            x0=max(0,left-3); x1=min(im.width,right+3); y0=max(0,top-3); y1=min(im.height,bottom+3)
            crop=alpha[y0:y1,x0:x1]>100
            ys,xs=np.where(crop)
            head=np.where(crop[:max(1,int(crop.shape[0]*0.22))])[1]
            pivot_x=float(head.mean()) if len(head) else float(xs.mean())
            frames.append([x0,y0,x1-x0,y1-y0]); pivots.append([round(pivot_x,2),int(ys.max()+1)])
    return dict(entry,frames=frames,pivots=pivots,reference_height=frames[0][3],source_size=list(im.size))

def main():
    catalog=json.loads(CATALOG.read_text(encoding='utf-8'))
    entries=[describe(e) for e in catalog['entries']]
    manifest={'schema_version':1,'entries':{e['id']:e for e in entries}}
    (OUT/'frames.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    font_path=Path('C:/Windows/Fonts/segoeui.ttf')
    font=ImageFont.truetype(str(font_path),22) if font_path.exists() else ImageFont.load_default()
    small=ImageFont.truetype(str(font_path),15) if font_path.exists() else font
    sheet=Image.new('RGB',(1600,1480),'#142e34'); draw=ImageDraw.Draw(sheet)
    for i,e in enumerate(entries):
        x=(i%4)*400; y=(i//4)*370
        draw.rounded_rectangle((x+10,y+10,x+390,y+358),radius=8,fill='#294449')
        im=Image.open(ROOT/e['source'].removeprefix('res://')).convert('RGBA')
        r=e['frames'][0]; crop=im.crop((r[0],r[1],r[0]+r[2],r[1]+r[3]))
        height=240 if e['height']>60 else 175
        crop=crop.resize((round(crop.width*height/crop.height),height),Image.Resampling.LANCZOS)
        sheet.paste(crop,(x+200-crop.width//2,y+275-height),crop)
        draw.text((x+22,y+290),e['name'],font=font,fill='#f0e5cc')
        draw.text((x+22,y+326),e['period']+' · '+str(len(e['frames']))+' quadros',font=small,fill='#bdc9bf')
    sheet.save(ROOT/'docs/lisbon-npc-cast.png')
    # Reusable scenes retain identity and a physical footprint in the editor.
    scenes=ROOT/'scenes/npcs/lisbon'; scenes.mkdir(parents=True,exist_ok=True)
    for e in entries:
        identity='child' if e['height']<60 else 'hero'
        scene='''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/chapter/actor_proxy.gd" id="actor"]
[node name="NPC" type="Node2D"]
script = ExtResource("actor")
identity = "IDENTITY"
npc_id = "NPC_ID"
[node name="Body" type="StaticBody2D" parent="."]
collision_mask = 0
[node name="Footprint" type="CollisionPolygon2D" parent="Body"]
polygon = PackedVector2Array(-12, 0, -8, -8, 0, -12, 8, -8, 12, 0, 8, 8, 0, 12, -8, 8)
'''.replace('IDENTITY',identity).replace('NPC_ID',e['id'])
        (scenes/(e['id']+'.tscn')).write_text(scene,encoding='utf-8')
    data=json.dumps(entries,ensure_ascii=False).replace('</','<\\/')
    page='''<!doctype html><html lang="pt"><meta charset="utf-8"><title>Elenco de Lisboa</title>
<style>body{margin:0;background:#142e34;color:#f0e5cc;font:16px system-ui}header{padding:25px 4vw;position:sticky;top:0;background:#142e34ed;z-index:2}h1{margin:0 0 10px;font-size:28px}button,select{padding:10px;margin:4px;background:#304e52;color:#fff;border:1px solid #9aab9a;border-radius:4px}main{padding:20px 4vw;display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:16px}article{padding:18px;background:#294449;border-radius:8px}canvas{width:100%;height:190px}h2{font-size:19px}p{font-size:14px;color:#c8d2c8}</style>
<header><h1>Mar de Jade · elenco de Lisboa</h1><div>Propostas visuais · 14 identidades / 16 versões</div><select id="direction"><option value="0">Frente</option><option value="1">Esquerda</option><option value="2">Costas</option><option value="3">Direita</option></select><button id="walk">Caminhar / parar</button><select id="pose"><option value="standing">De pé</option><option value="seated">Sentado</option><option value="crouched">Agachado</option></select></header><main></main><script>
const entries=DATA;let walking=false;document.querySelector('#walk').onclick=()=>walking=!walking;
for(const e of entries){const c=document.createElement('article');const canvas=document.createElement('canvas');canvas.width=340;canvas.height=220;const name=document.createElement('h2');name.textContent=e.name;const role=document.createElement('p');role.textContent=e.role;c.append(canvas,name,role);document.querySelector('main').append(c);e.canvas=canvas;e.image=new Image();e.image.src='../../../../'+e.source.replace('res://','');}
function paint(t){let direction=+document.querySelector('#direction').value,pose=document.querySelector('#pose').value;for(const e of entries){let ctx=e.canvas.getContext('2d');ctx.clearRect(0,0,340,220);if(!e.image.complete)continue;let i=direction*4+(walking?1+Math.floor(t/170)%3:0);if(pose!=='standing'&&e.pose_indices)i=e.pose_indices[pose];let r=e.frames[i],p=e.pivots[i],s=165/e.reference_height*(e.height/84);ctx.save();ctx.translate(170,200);if(pose==='standing'&&((direction===1&&e.west_flip)||(direction===3&&e.east_flip)))ctx.scale(-1,1);ctx.drawImage(e.image,...r,-p[0]*s,-p[1]*s,r[2]*s,r[3]*s);ctx.restore();}requestAnimationFrame(paint);}requestAnimationFrame(paint);
</script></html>'''.replace('DATA',data)
    (OUT/'gallery.html').write_text(page,encoding='utf-8')
    print(json.dumps({'appearances':len(entries),'identities':len(set(e['person_id'] for e in entries)),'frames':sum(len(e['frames']) for e in entries)}))

if __name__=='__main__': main()
