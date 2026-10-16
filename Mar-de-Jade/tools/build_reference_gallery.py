"""Build a local browsing gallery from the extracted sample manifest."""
from pathlib import Path
import json, html

OUT = Path(__file__).resolve().parents[1] / 'reference-study/heros-adventure'
manifest = json.loads((OUT/'manifest.json').read_text(encoding='utf-8'))
cards=[]
for row in sorted(manifest['sprites'],key=lambda r:r['name']):
    name=html.escape(row['name']); path=html.escape(row['path'])
    cards.append(f'<article data-name="{name}"><div class="art"><img src="{path}" alt="{name}"></div><h2>{name}</h2><p>{row["width"]} × {row["height"]} px · {row["pixels_per_unit"]:g} px/unidade</p><small>{row["id"]}</small></article>')
page='''<!doctype html><html lang="pt"><meta charset="utf-8"><title>Hero’s Adventure — amostra local</title>
<style>body{margin:0;background:#14292b;color:#e9dfc8;font:16px system-ui}header{padding:30px 4vw;position:sticky;top:0;background:#14292bf5;border-bottom:1px solid #637572}h1{font-size:25px;margin:0 0 8px}p{color:#bfccbf}input{padding:12px;width:min(450px,80vw);background:#243d3f;color:#fff;border:1px solid #8c9679;font:inherit}main{padding:25px 4vw;display:grid;grid-template-columns:repeat(auto-fit,minmax(270px,1fr));gap:18px}article{background:#243d3f;padding:16px;border:1px solid #435b58;border-radius:6px}article[hidden]{display:none}.art{height:230px;display:flex;align-items:center;justify-content:center;background:#34484a}img{image-rendering:pixelated;max-width:95%;max-height:95%;width:auto;min-width:128px}h2{font-size:16px;overflow-wrap:anywhere}small{color:#a6b6ab}article p{font-size:14px}</style>
<header><h1>Hero’s Adventure · amostra extraída</h1><p>37 sprites reais · PNGs na resolução original · identificação e escala preservadas</p><input type="search" placeholder="Filtrar pelo nome…" aria-label="Filtrar sprites"></header><main>'''+''.join(cards)+'''</main><script>document.querySelector('input').addEventListener('input',e=>document.querySelectorAll('article').forEach(c=>c.hidden=!c.dataset.name.toLowerCase().includes(e.target.value.toLowerCase())))</script></html>'''
(OUT/'index.html').write_text(page,encoding='utf-8')
print('Local gallery generated: 37 indexed sprites.')
