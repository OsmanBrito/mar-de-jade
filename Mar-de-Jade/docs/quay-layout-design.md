# Cais de Mar de Jade — planta original

A revisão começou pela função e pela circulação, antes de selecionar imagens. A planta está em `docs/quay-layout-plan.svg`; a disposição inicial é usada pela cena interativa `scenes/art/quay_layout_blockout.tscn` (**F6**). WASD/setas e clique movem a figura de escala; Tab oculta ou mostra o eixo principal. Esta planta é um estudo anterior: a campanha agora utiliza o [cais vivo com arte e moradores](cais-vivo.md), com ajustes de largura entre edifícios e quarteirões de enquadramento.

## Disposição

Uma rua liga a saída para a cidade à cabeça do embarcadouro. Abrigo e armazém A ficam de um lado; oficina e armazém B do outro. Os acessos estão voltados para a rua. Antes do rio, a passagem abre numa área de serviço para conversa, refeição e socorro; a carga fica num espaço lateral seco. Uma faixa ao longo da margem permite circular entre o serviço, a carga e o embarque sem atravessar as pilhas de caixas.

O embarcadouro é um prolongamento da rua, com acesso estreito ao volume que representa a Botafogo. O rio ocupa o lado de fora da margem; a massa urbana continua para lá da entrada, evitando o aspeto de ilha. A oficina é uma função proposta para um dos volumes; não acrescenta missão ou diálogo ao roteiro aprovado.

## Escala de trabalho

As medidas são unidades de desenho, não metros. A rua tem 120 unidades de largura; a faixa da margem, 60; o embarcadouro, 100; a prancha de acesso, 45. O desenho é projetado em 2:1. A navegação e as colisões deixam margem para o raio de 12 unidades do controlador existente. Os pontos de serviço e de pousar carga ficam fora dos footprints.

Os volumes, polígonos e planta vetorial são originais. Não utilizam os sprites extraídos de Hero’s Adventure. A figura simples do protagonista é a apresentação provisória existente. Nesta vista de planeamento ela permanece visível sobre os volumes para facilitar a leitura; a oclusão artística final não é o objeto desta etapa.

## Fonte e verificação

`data/chapter_01/quay_layout_plan.json` contém edifícios, áreas, carga e pontos de atividade. `scripts/chapter/quay_layout_blockout.gd` usa os mesmos polígonos para desenho, navegação e colisão física. `tools/build_quay_layout_plan.py` gera a planta SVG sem redesenhar imagens.

`tests/quay_layout_blockout.gd` passou 19 verificações: chegada livre, seis atividades acessíveis com margem, trajetos conectados, edifícios sólidos, rio intransitável e caminhada real por clique até à área de serviço. A captura `docs/quay-layout-blockout.png` foi inspecionada em Godot/OpenGL. O aviso de certificados do ambiente continua; não houve erros de GDScript.

A etapa de arte deve vestir esta estrutura: fachadas orientadas para os acessos, pisos que distingam rua e trabalho, carga contida nos seus footprints e elementos portuários concentrados na margem. O desenho dos volumes não representa a arte final.
