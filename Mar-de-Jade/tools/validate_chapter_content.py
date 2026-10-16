from pathlib import Path
import re,json,sys
root=Path(__file__).resolve().parents[1]
source=(root/'docs/narrativa/C01-portugal-aprovado.md').read_text(encoding='utf-8-sig')
expected={}; mission=''; current=None
for line in source.splitlines():
    m=re.match(r'## C01-(M\d+) —',line)
    if m: mission=m[1]; current=None
    m=re.match(r'### (S\d+) —',line)
    if m: current=f'C01-{mission}/{m[1]}'; expected[current]=[]
    m=re.match(r'\s*(?:- )?\*\*(.+?):\*\* (.*)',line)
    if m and current: expected[current].append((m[1].split(' [')[0],m[2]))
def dialogue(events):
    result=[]
    for event in events:
        if event['type']=='line': result.append((event['speaker'],event['text']))
        if event['type'] in ('choice','styles'):
            for option in event['options']: result.extend(dialogue(option['events']))
        if 'on_failure' in event: result.extend(dialogue(event['on_failure']))
    return result
content=json.loads((root/'data/chapter_01/chapter_flow.json').read_text(encoding='utf-8-sig'))
failures=[]; total=0
for scene in content['scenes']:
    actual=dialogue(scene['events']); total+=len(actual)
    if actual!=expected[scene['id']]: failures.append(scene['id'])
print(json.dumps({'scene_blocks':len(content['scenes']),'approved_lines':total,'failures':failures},ensure_ascii=False))
sys.exit(bool(failures))

