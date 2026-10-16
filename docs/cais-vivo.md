# Cais vivo de Lisboa

O mapa ativo das cenas adultas de cais e serviço é `scenes/maps/cais_vivo.tscn`. A cena `scenes/art/composed_quay_study.tscn` permite explorá-lo sem ler ou gravar a campanha: WASD/setas ou clique, E para observar/falar com Duarte, M para vista geral e R para regressar à entrada.

Doze edifícios compõem a rua e os quarteirões da área explorável: abrigo, armazéns abertos, oficinas e casas com varandas. A carga fica junto das portas e da margem; a banca de peixe, redes, amarras, carrinhos, barris, roupa e oliveiras dão funções aos espaços. A caravela fica ao lado do pontão, sobre a água.

A revisão de continuidade acrescenta 39 edifícios de cenário nas ruas vizinhas e chão urbano para além dos limites de exploração. A margem do rio é contínua; a fronteira interna da área jogável deixa de desenhar paredes de cais ou água. A cidade atravessa o enquadramento em escala normal. Essa continuação exterior é cenográfica e não acrescenta novas zonas exploráveis ou missões. A proximidade com Hero’s Adventure ainda precisa de revisão de escala, composição e leitura. A pesquisa do Mar de Ferro também recuperou um acabamento ilustrado aprovado: reduzir resolução ou paleta à força não é requisito desta direção.

Sete moradores percorrem rotas curtas, param nos seus pontos de trabalho e evitam obstáculos por navegação e colisão física. Os passos usam as animações do elenco de Lisboa. Água, aves, fumo discreto e balanço do barco acrescentam movimento. As figuras de fundo não criam novas missões nem alteram as falas aprovadas. A exploração de demonstração contém apenas observações do cenário e uma fala já existente de Duarte.

O controlador mantém raio de 12 e a navegação reserva 14. Os edifícios usam polígonos de chão e tiras visuais para ordenação isométrica. O espaço entre a oficina e a casa da frente foi alargado para permitir a circulação real. As tarefas de socorro, carga e refeição usam posições revistas no mesmo mapa.

## Arte e reprodução

Arte original criada com o **image_gen integrado**, sem nova extração do jogo de referência. Ficheiros finais em `assets/art/living-quay/`: `buildings-v1.png`, `caravela-clean-v2.png` e `street-props-v1.png`. Os objetos de trabalho anteriores continuam em `assets/art/portugal-v2/quay-props-clean-v2.png`, e o elenco em `assets/art/npcs/lisbon/`. O piso usa o tileset original do projeto. A aplicação da amostra extraída é ignorada neste mapa.

Os prompts e nomes dos resultados originais ficam em `assets/art/living-quay/prompts.json`. Os PNGs gerados são preservados; `tools/measure_living_quay.py` mede regiões e limites das tiras no atlas sem redesenhar pixels. `frames.json` guarda esses metadados. Executar esse script antes de `tools/build_living_quay.gd` quando houver alterações intencionais aos assets ou à disposição. O segundo script grava uma cena editável com os elementos e footprints já posicionados.

## Verificação

A adaptação de margem e câmera do Mar de Ferro passou 49 verificações de mapa em Godot/OpenGL. A captura da encenação do capítulo pode ser atualizada com `tools/capture_quay_chapter.gd`, sem gravar o checkpoint do jogador.

`tests/living_quay.gd` verifica circulação física por clique entre entrada, socorro, carga, refeição e pontão; rotas e movimento dos sete moradores; bloqueio da água e continuidade visual da cidade. Grava `docs/cais-vivo-overview.png` e `docs/cais-vivo-rua.png` em OpenGL. `tests/chapter_full.gd` passou 31 verificações dos 17 blocos adultos, tarefas, sete tipos de encontro, escolhas e persistência. A simulação integral usa teleporte após comprovar as rotas; a caminhada física é exercitada separadamente no teste do mapa. Elenco: 27 verificações; pontes e retomada do capítulo: 15. As 250 falas aprovadas e os 23 módulos de combate de referência mantêm-se intactos. O ritmo e a sensação de vida ainda dependem da validação do jogador.
