"""Build chapter data from approved dialogue, with explicit gameplay inserts."""
from pathlib import Path
import re, json
ROOT = Path(__file__).resolve().parents[1]
text = (ROOT/'docs/narrativa/C01-portugal-aprovado.md').read_text(encoding='utf-8-sig')
scenes=[]; mission=''; scene=None; current_choice=None; current_branch=None
for raw in text.splitlines():
    m=re.match(r'## C01-(M\d+) — (.*)',raw)
    if m: mission=m[1]; scene=None; continue
    m=re.match(r'### (S\d+) — (.*)',raw)
    if m:
        scene={'id':f'C01-{mission}/{m[1]}','title':m[2],'events':[],'directions':[]}
        scenes.append(scene); current_choice=None; current_branch=None; continue
    if not scene: continue
    m=re.match(r'^(\s*)(- )?\*\*(.+?):\*\* (.*)',raw)
    if m:
        indent, dash, speaker, body=m.groups()
        base=speaker.split(' [')[0]
        ev={'type':'line','speaker':base,'text':body,'tag':speaker}
        if dash:
            if current_choice is None:
                current_choice={'type':'choice','options':[]}; scene['events'].append(current_choice)
            label=re.search(r'\[(.*?)\]',speaker)[1]
            current_branch={'id':label,'label':label.capitalize(),'events':[ev]}; current_choice['options'].append(current_branch)
        elif indent and current_branch is not None:
            current_branch['events'].append(ev)
        else:
            current_choice=None; current_branch=None; scene['events'].append(ev)
    elif raw.startswith('['): scene['directions'].append(raw)
by={s['id']:s for s in scenes}
def task(name,caption,map=None):
    d={'type':'task','id':name,'caption':caption}
    if map: d['map']=map
    return d
def battle(mode,**kw): return {'type':'battle','mode':mode,**kw}
def stage(name,**kw): return {'type':'stage','action':name,**kw}
def setevents(key,events): by[key]['events']=events
for s in scenes:
    mid=s['id'].split('/')[0]; sid=s['id'].split('/')[1]
    s['map']='courtyard'
    if mid=='C01-M02': s['map']='service' if sid in ('S04','S05') else 'cais'
    if mid=='C01-M03': s['map']='room' if sid=='S07' else 'plaza'
    if mid=='C01-M04': s['map']='deck' if sid=='S04' else ('room' if sid=='S03' else 'courtyard')
by['C01-M04/S01']['map']='room'
# Existing S01-S07 remain the authoritative playable childhood/entry scenes.
remaining=[s for s in scenes if s['id']>='C01-M01/S08']
e=by['C01-M01/S08']['events']; setevents('C01-M01/S08',e[:3]+[stage('child_arrives')]+e[3:7]+[task('knot','Aperta a correia da sacola junto da criança.')]+e[7:])
e=by['C01-M02/S01']['events']; setevents('C01-M02/S01',[stage('rescue_arrival')]+e[:5]+[task('lever','Assenta a alavanca junto da viga; depois levanta a madeira com Duarte.'),stage('green_sight')]+e[5:]+[task('fetch_tome','Vai buscar Tomé ao abrigo.','room')])
e=by['C01-M02/S02']['events']; setevents('C01-M02/S02',[stage('treatment')]+e[:5]+[stage('leonor_arrives')]+e[5:])
e=by['C01-M02/S03']['events']; setevents('C01-M02/S03',e[:5]+[task('clear_passage','Retira o caixote e leva-o para o lado seco.')]+e[5:]+[stage('patient_departure')])
e=by['C01-M02/S04']['events']; setevents('C01-M02/S04',[task('meal','Recolhe duas porções e água na cozinha da Ordem; leva-as a Leonor no refeitório.')]+e+[stage('clean_cloth')])
by['C01-M02/S05']['events'][4]['flag']='departure_response'
by['C01-M02/S05']['events'].append(stage('leave_refectory'))
e=by['C01-M03/S01']['events']; setevents('C01-M03/S01',[stage('morning'),stage('master_demonstration')]+e[:4]+[stage('leonor_demonstration')]+e[4:])
setevents('C01-M03/S02',[stage('afternoon'),stage('two_cups')]+by['C01-M03/S02']['events'])
setevents('C01-M03/S03',[battle('duel'),stage('fallen')])
setevents('C01-M03/S04',[stage('fallen'),stage('cup_in_reach')]+by['C01-M03/S04']['events'])
e=by['C01-M03/S05']['events']; e[-2]['flag']='promise_response'; setevents('C01-M03/S05',e[:-1]+[stage('leonor_leaves')]+e[-1:]+[stage('cannot_stand'),stage('silence')])
setevents('C01-M03/S06',[stage('duarte_arrives')]+by['C01-M03/S06']['events']+[stage('tome_assistance')])
e=by['C01-M03/S07']['events']; setevents('C01-M03/S07',[stage('treated_in_bed')]+e[:5]+[task('recovery_water','Toma a água que Tomé deixou ao alcance da cama.'),stage('water_drunk')]+e[5:])
e=by['C01-M04/S01']['events']; options=e[-1]['options']; styles={'espada':'ES','lança':'LA','machado':'MC','arma de fogo':'FO','desarmado':'PU'}
for o in options: o['style']=styles[o['id']]
setevents('C01-M04/S01',[stage('time_passes'),task('recovery_walk','Caminha até à mesa e regressa ao apoio de Tomé, sem pressa.','room'),stage('recovered'),stage('return_courtyard')]+e[:-1]+[{'type':'styles','options':options}])
e=by['C01-M04/S02']['events']; setevents('C01-M04/S02',e[:1]+[battle('perfect_defense',on_failure=e[1:6])]+e[6:])
e=by['C01-M04/S03']['events']; setevents('C01-M04/S03',e[:7]+[stage('give_bowl')]+e[7:]+[task('pack','Guarda a tigela, a água e as provisões na sacola.'),stage('packed')])
e=by['C01-M04/S04']['events']; setevents('C01-M04/S04',e+[task('blue_rope','Trabalha na amarra azul com Duarte. A branca é de Beatriz.'),stage('ship_departs')])
(ROOT/'data/chapter_01/chapter_flow.json').write_text(json.dumps({'schema_version':1,'scenes':remaining},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f'{len(remaining)} scene blocks generated from approved chapter')


