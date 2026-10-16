"""Draw the original quay plan as an editable vector document, from game layout data."""
import json, html
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
plan=json.loads((ROOT/'data/chapter_01/quay_layout_plan.json').read_text(encoding='utf-8'))
parts=['<svg xmlns="http://www.w3.org/2000/svg" width="1440" height="1000" viewBox="0 0 1440 1000">',
'<rect width="1440" height="1000" fill="#142e34"/>',
'<g font-family="Segoe UI, sans-serif" fill="#f0e7ce"><text x="70" y="65" font-size="30">MAR DE JADE · PLANTA DO CAIS</text><text x="70" y="105" font-size="18">Rua de chegada → área de serviço → embarcadouro. Volumes e caminhos antes da arte.</text></g>',
'<g transform="translate(90 190)">',
'<rect x="-25" y="-20" width="925" height="660" fill="#7d8780"/>']
def rect(values,color,stroke='none'):
    x,y,w,h=values
    parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="3" fill="{color}" stroke="{stroke}" stroke-width="2"/>')
for key,color in [('street','#d4c6a5'),('service','#a4ac91'),('quay','#a7a58e'),('pier','#a38a66'),('gangway','#a38a66'),('boat','#65818a')]: rect(plan[key],color)
for b in plan['buildings']:
    rect(b['rect'],'#526969','#b5c4b6')
    x,y,w,h=b['rect']
    parts.append(f'<text x="{x+w/2}" y="{y+h/2}" text-anchor="middle" fill="#f6edda" font-family="Segoe UI" font-size="17">{html.escape(b["name"])}</text>')
for cargo in plan['cargo']: rect(cargo,'#9d8057','#e0c996')
parts.append('<path d="M20 280 H1090" fill="none" stroke="#654e26" stroke-width="4" stroke-dasharray="12 9"/>')
for i,marker in enumerate(plan['markers'],1):
    x,y=marker['point']
    parts.append(f'<circle cx="{x}" cy="{y}" r="15" fill="#f0d99e" stroke="#31454b" stroke-width="2"/><text x="{x}" y="{y+6}" text-anchor="middle" font-family="Segoe UI" font-size="16" fill="#243e43">{i}</text>')
parts.append('<text x="1160" y="170" transform="rotate(90 1160 170)" font-family="Segoe UI" font-size="30" fill="#aac2c4">TEJO</text></g>')
for i,marker in enumerate(plan['markers']):
    x=90+(i%3)*430; y=900+(i//3)*38
    parts.append(f'<text x="{x}" y="{y}" font-family="Segoe UI" font-size="18" fill="#e8dfc5">{i+1}. {html.escape(marker["name"])}</text>')
parts.append('</svg>')
(ROOT/'docs/quay-layout-plan.svg').write_text('\n'.join(parts),encoding='utf-8')
print('Original quay layout SVG saved.')
