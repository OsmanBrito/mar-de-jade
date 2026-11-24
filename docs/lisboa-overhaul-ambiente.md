# Lisboa — auditoria e intervenção de ambiente

## Diagnóstico anterior à intervenção (21/10/2026)

Estado de partida: checkout de trabalho existente, incluindo alterações locais anteriores. Capturas reais em `.qa-runtime/lisbon-overhaul/before/`; percurso completo capturado pelo workflow `tools/capture_lisbon_direction.gd`.

| Prioridade | Causa observada | Local | Correção |
| --- | --- | --- | --- |
| Alta | Pontões dimensionados por divisão vetorial, deformando a imagem | `lisbon_scenery.gd`, `DOCK_DRAW` | Escala uniforme, centrada no mesmo acesso, preservando altura e tabuleiro |
| Alta | Cada fatia de muro recebe uma altura arbitrária e um pivô no fundo de toda a imagem, incluindo transparência | `lisbon_scenery.gd`, `COURTYARD_WALLS` | Uma escala para a pintura inteira; recorte vertical e contacto próprios por fatia, sem alterar o PNG |
| Alta | Moradias dominam a descida; portas e telhados maiores que a linguagem do adro | `ferro_lisbon.gd`, `BUILDING_SIZES` | Ajuste individual das caixas de enquadramento; mesma proporção original, base e destinos de interação |
| Média | Adro e cais usam a mesma pedra regular; grandes vazios parecem uma única superfície plana | `lisbon_ground.gd` | Calçada irregular existente na Ribeira, transição contínua no colo da descida; UV em coordenadas de mundo |
| Média | Árvores em anel exterior; quintais fechados vazios; sinalização compete com personagens | `lisbon_scenery.gd`, `lisbon_composition.gd` | Redistribuir parte das oliveiras para quintais existentes; escala humana das placas |
| Média | Sombras de casas calculadas pela caixa máxima, não pelo tamanho efetivamente desenhado | `lisbon_finish.gd` | Usar dimensões reais do prop para o contacto |

## Arquitetura e escala verificadas

- Cena ativa: `scenes/maps/praca_infancia.tscn`, usada também por `chapter_flow.tscn`; raiz sem escala herdada. Script `lisbon_world.gd` → `plaza_world.gd` → `world.gd`. Sem cena herdada intermediária.
- `Ground` é o TileMapLayer lógico, oculto no exterior. `FerroRibeira` (-4) desenha chão/água/pontões, `WorkingGround` (-3) desgaste/sombras, `ActorsAndProps` (2, Y-sort) personagens, edifícios, mobiliário e muros. A casa da Ordem é uma pintura fixa com footprint próprio.
- Movimento em X/Y com CharacterBody2D; projeção oblíqua ilustrada, sem grelha isométrica de movimento. Pivôs nos pés; raio físico 12 px e clearance de navegação 14 px. Adulto 84 px, criança 52 px; não alterar personagens para compensar arquitetura.
- Viewport 1440×900, janela inicial 1280×800, `canvas_items`. Câmara de exploração 1×, limites e enviesamento já existentes. Não alterar zoom ou configuração global para resolver proporções.
- Props usam caixas de enquadramento com `min(width/native_width,height/native_height)` e mantêm proporções. Texturas ilustradas recebem filtragem linear com mipmaps em memória; não são pixel art. Assets fonte e importações preservados.
- Plano da Ribeira usa escala uniforme 1.6, offset (-680,120); ruas laterais 124 px. Footprints de serviços, gatilhos, missões e portas permanecem nas coordenadas existentes.

## Validação

Intervenção aplicada diretamente nos scripts que montam o exterior, sem alterar a cena base, o zoom, a movimentação, os PNGs fonte ou as importações:

- Moradia de pedra aproximadamente 9,5% menor; casa azul 14,7%; armazém 6,7%; oficina 6%. Não se aplicou uma redução global. Mantêm-se os centros, bases e footprints existentes; as portas continuam acessíveis. Placas a 78% da dimensão anterior.
- Pontões e pintura da margem passam a escala uniforme. Os pontões conservam altura e centro do acesso, ganhando a largura natural da imagem.
- Muros ilustrados conservam uma única escala por pintura. Fatias em coordenadas inteiras, recorte vertical do conteúdo opaco e pivôs próprios eliminam esticamento e transparência vazia no contacto. Desvio medido entre base visível e plano lógico: máximo 5,71 px, dentro dos 9 px de meia espessura da colisão.
- Adro mantém lajeado; a Ribeira usa a calçada irregular já existente. A transição cruza a descida e as duas ruas na mesma linha oblíqua. Textura aplicada com reflexão alternada dos tiles e fase mundial comum para reduzir as bordas repetidas do asset não seamless. Nenhuma imagem foi redesenhada.
- Oliveiras menores dentro dos quintais fechados criam planos intermédios e separam os telhados dos muros. Uma oliveira do agrupamento do adro passa para o vazio não transitável da rua poente. Dois exemplares do anel exterior foram retirados para reduzir repetição.
- Sombras arquitetónicas usam a largura efetivamente desenhada, em vez da caixa máxima de enquadramento.

### Testes e inspeção

Workflow existente: `./tools/test_lisbon_direction.ps1`. O novo teste também é executado por este runner, passando `-Suites lisbon_environment_art`.

| Suite | Verificações | Resultado |
| --- | ---: | --- |
| lisbon_environment_art | 200 | Passou |
| lisbon_composition | 35 | Passou |
| lisbon_direction | 44 | Passou |
| lisbon_city | 20 | Passou |
| lisbon_circulation | 57 | Passou |
| map_art_closure | 90 | Passou |
| harbor_visit | 40 | Passou |
| lisbon_city_campaign | 24 | Passou |

Total: 510 verificações distintas, oito suites. Depois dos ajustes finais de textura/árvore, repetiram-se as suites de arte, composição e direção. Os testes exercitam caminhada física, não apenas consultas de pathfinding: percurso adro → descida → mercado → oficina → embarque, acessos aos serviços/portas, ruas alternativas, limites da infância, transições e conservação da campanha.

Captura final: `godot --path . --script res://tools/capture_lisbon_overhaul.gd --fixed-fps 60`. Herda o percurso real do workflow anterior e acrescenta janelas 1024×768 e 1920×1080 às de 1440×900 e 960×600. O teste de interface verifica texto 100%/120% em 1440×900 e 960×600. Capturas incluem adro, portaria, Ribeira, estaleiro, oficina, rua poente, oclusão, interação e planta geral. Inspeção visual realizada sobre imagens reais do viewport OpenGL; não inferida do resultado headless.

- [Planta antes](lisboa-ambiente-antes.png) · [Planta depois](lisboa-ambiente-depois.png)
- Capturas completas antes/depois e logs: `.qa-runtime/lisbon-overhaul/` (artefactos locais de QA).
- Os logs gráficos apresentam erros de acesso ao cache de shaders e ao certificado raiz do ambiente, também presentes na captura anterior à intervenção. Não houve erro de script ou falha de percurso nas capturas concluídas.

### Limitações artísticas

A arquitetura continua a ser composta por ilustrações planas com perspetiva, luz e sombras já pintadas. A casa da Ordem tem detalhe e construção de perspetiva diferentes do kit da Ribeira; mudanças de escala e composição aproximam os conjuntos, mas não tornam os assets uma biblioteca modular única. A relva e a água também conservam repetição e detalhe dos originais. Atrás de fachadas, a revelação localizada do protagonista continua a ser necessária; preservou-se a oclusão gradual e o comportamento das cenas narrativas. A planta geral é uma vista de auditoria a 0,43×, não a câmara de exploração a 1×.

### Ficheiros desta intervenção

`scripts/city/ferro_lisbon.gd`, `scripts/city/lisbon_scenery.gd`, `scripts/city/lisbon_finish.gd`, `scripts/city/lisbon_composition.gd`, `scripts/city/lisbon_ground.gd`, `tests/lisbon_environment_art.gd`, `tools/capture_lisbon_overhaul.gd`, este relatório e as duas capturas comparativas. Alterações locais anteriores noutros ficheiros foram preservadas.
