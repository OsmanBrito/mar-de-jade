# A casa onde cresceste — primeira versão jogável

24/10/2026. Primeiro trecho implementado a partir da [entrevista sobre a abertura](direcao-abertura-entrevista-2026-10-24.md). Uma campanha nova começa pela descoberta do convento como criança. A aprovação da primeira impressão depende de jogar esta versão.

## Como jogar

Usar `Jogar.cmd` na raiz oficial `C:/Users/gamer/Documents/GitHub/mar-de-jade` e confirmar o nome para começar uma campanha nova. O botão de continuar conserva o percurso de saves anteriores.

No editor, a cena do novo início é `scenes/chapter_01/childhood_home.tscn`. F6 pede o nome se necessário e regressa à cena. A campanha continua depois pela praça, pelo treino com Leonor, pela floresta e pela promessa existentes.

Controles: WASD ou setas para caminhar; clique para aproximar e interagir; E ou A para interagir; J ou Y para o caderno; Esc ou Start para o menu. O painel compartilhado conserva as opções de leitura, áudio e remapeamento.

## O que existe neste trecho

- Três falas curtas de Tomé, seguidas do controle da criança.
- Tigela visível junto da cama, recolha e transporte até à mesa. A refeição retoma a ausência do pai e o acolhimento de Tomé.
- Dormitório compacto, passagem aberta, claustro com jardim e fonte, galeria de preparativos e pátio de armas.
- Conversas sobre os olhos, uma cruz antiga e as pessoas que partem em viagem; descobertas relidas no caderno e posteriormente no diário da campanha.
- Cavaleiro com animação articulada produzida no Blender, visível em atividade no pátio.
- Alvo de treino opcional, usando o combate tático existente. Pode-se observar, experimentar ou abandonar a prática. O exercício é seguro, não ensina Defesa Perfeita nem concede técnicas ou XP adultos.
- Leonor chama para a praça depois da refeição, ligando o novo trecho à infância já implementada.

As falas novas usam português de Portugal. O antigo acolhimento continua disponível para os saves que já apontavam para ele. O roteiro e as falas da praça, da floresta e da promessa permanecem como estavam.

## Apresentação e Blender

O cenário deste trecho é uma cena 3D ortográfica dentro do Godot, exibida em metade da resolução com ampliação por vizinho mais próximo. A interface permanece na resolução normal. É uma primeira amostra de apresentação pixelada; resolução, materiais e direção visual ainda devem ser avaliados jogando.

O cenário e o cavaleiro são autoria local no Blender, com fontes editáveis:

- `art-source/blender/childhood-convent/convento-infancia.blend`
- `art-source/blender/childhood-convent/cavaleiro-treino.blend`

`tools/blender/build_childhood_convent.py` recria ambos e exporta os GLB consumidos pelo Godot em `assets/models/childhood-convent/`. Os personagens principais reutilizam os atlas ilustrados existentes. Esta etapa não substitui suas animações por modelos articulados completos.

A câmera aproxima o dormitório e abre o enquadramento ao sair. Um recorte localizado na arquitetura permite ver a criança quando uma coluna ou parede está diante dela. A navegação e os pontos de interação compartilham a planta e os obstáculos do cenário.

Para regenerar os modelos, na raiz oficial:

```powershell
& '.tools/blender/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python tools/blender/build_childhood_convent.py
```

## Salvamento e continuidade

O capítulo guarda posição com precisão de centímetros, a refeição, as descobertas e a prática. Conversas interrompidas podem ser repetidas; um treino opcional interrompido regressa à exploração. Posições dentro de obstáculos e tentativas de carregar esse percurso em outra cena são rejeitadas antes de alterar o estado.

Saves anteriores continuam aceitos. A nova cena utiliza o estado de campanha existente; seu percurso próprio é validado como `childhood_home`. Ao seguir para a praça, esse percurso é encerrado.

Durante as regressões foi encontrado um problema já presente na cena da promessa: os instrumentos e os marcadores usados pelo diretor tinham desaparecido da cena. Foram repostos, preservando seus metadados atuais, para permitir o restante da infância e sua repetição.

## Verificação

As verificações cobrem entrada pelo nome, aproximação por clique, movimento por teclado, caminhada física por todos os pontos do convento, bloqueio de interação remota, escolhas opcionais, animação do Blender em execução, prática segura, diário, pausa, salvamento, retomada e continuidade até à praça. As regressões cobrem a promessa, a floresta, os controles e a continuidade da campanha.

Resultado desta etapa: **270 verificações aprovadas em sete suítes** — nova abertura 69, nome 26, promessa 25, floresta 67, continuidade 34, controles 41 e medição opcional 8. Foram conferidas seis capturas nativas em 1440 × 900. Esses resultados verificam funcionamento; a avaliação da primeira impressão continua sendo humana.

```powershell
& tools/test_lisbon_direction.ps1 -Suites childhood_home,name_entry,promise,forest_hunt,campaign_continuity,childhood_controls
```

A medição opcional da infância reconhece a nova cena como a etapa de abertura. Seu teste exige o argumento `--measure-childhood`; a medição continua desligada numa partida normal.

`tools/capture_childhood_home.gd` produz capturas nativas do acolhimento, dormitório, claustro, galeria, pátio e treino, com dados de usuário separados para QA. As capturas ficam em `.qa-runtime/childhood-home/`.

O critério humano desta entrega é sentir vontade de caminhar, descobrir o convento e conhecer as pessoas. Este trecho ainda não representa uma reconstrução visual de toda Lisboa ou a revisão de todos os diálogos da campanha.

## Refinamento do piso e da caminhada — 24/10/2026

Após o usuário relatar que o chão piscava e o andar parecia estranho, foram reproduzidos dois defeitos: a face superior da fundação estava praticamente no mesmo plano das lajes (diferença inferior a 0,00004 m no GLB importado), e a caminhada por clique ficava parada durante um tick em cada ponto intermediário, reiniciando o ciclo de passos.

A fundação foi rebaixada 12 cm no arquivo Blender e no GLB. O percurso passa a unir trechos livres e a consumir pontos já atingidos no mesmo tick, com aproximação final sem ultrapassar o destino. A animação acompanha a distância realmente percorrida, conserva a direção ao parar e alterna as poses de passada sem regressar ao repouso entre as casas da navegação. Os pés e a sombra também acompanham a altura do soalho.

A apresentação do personagem e o acompanhamento da câmera usam interpolação local entre os ticks de física. As retomadas e mudanças de posição reinicializam essa interpolação; o restante da campanha mantém sua configuração de física.

`tests/childhood_home_motion.gd` verifica a geometria realmente importada, a continuidade do movimento, o ciclo de passos, a chegada ao destino e o repouso. O mesmo trajeto que antes apresentava nove ticks parados e só uma pose de caminhada passou a apresentar zero ticks parados e as três poses da passada. Os testes de movimento, abertura e entrada pelo nome passaram: **106 verificações em três suítes**.

```powershell
& tools/test_lisbon_direction.ps1 -Suites childhood_home_motion,childhood_home,name_entry
```

`tools/capture_childhood_home_walk.gd` registra uma caminhada real pelo dormitório e pelas galerias; a conferência desta revisão produziu 258 quadros de execução, com capturas em `.qa-runtime/childhood-home/walk-review/`.

## Passadas de frente e de costas — revisão visual

O ajuste anterior não resolvia a semelhança das pernas nos desenhos originais. A abertura agora usa um atlas próprio para a caminhada vertical da criança, com elevação da bota, joelho dobrado e alternância real das pernas. A montagem usa oito fases por sentido, escala compartilhada e âncora no chão. A caminhada lateral e as poses de repouso conservam o atlas anterior.

O preparo, as fontes preservadas e o prompt da ferramenta integrada image_gen estão documentados em [hero-child-vertical-walk-art.md](hero-child-vertical-walk-art.md). A sequência de costas tem ordenação própria; as metades complementares são espelhadas para evitar repetir a mesma perna de avanço.

Foram aprovadas **112 verificações em três suítes** (movimento 17, abertura 69 e entrada pelo nome 26). O teste de movimento agora inspeciona os pixels das botas e exige elevação alternada visível nos dois sentidos, além de confirmar as oito fases durante percursos reais para cima e para baixo. `tools/capture_childhood_vertical_walk.gd` produziu 44 quadros de execução; 22 capturas renderizadas foram conferidas no tamanho do jogo e em recortes ampliados. A prévia animada fica em `.qa-runtime/childhood-home/vertical-walk/native/native-walk.gif`.

## Apresentação do convento e primeiro percurso — 24/10/2026

O primeiro objetivo passou a ser sentar à mesa com Tomé, sabendo que Leonor veio à procura da criança. O menino já segura a tigela, como na encenação da história; procurar o objeto deixou de ser a primeira tarefa. Saves da versão anterior continuam permitindo recolhê-la, mas também permitem sentar diretamente: Tomé oferece uma tigela e o fim da refeição reconcilia os estados visuais. A conversa sobre o pai e a segurança da refeição continua presente.

Depois da refeição, o objetivo indica Leonor junto à portaria e explica que vão à praça. A primeira passagem pelo claustro apresenta uma breve fala ambiente do treino, sem interromper o movimento. O treino continua opcional. Objetivo e interação próxima agora têm espaços separados na interface, para que aproximar-se de uma pessoa não esconda a orientação principal.

O cenário Blender recebeu pedra com variação mais contida, juntas menores, soalho com cavilhas e emendas, roupa dobrada, capas, jarro e pão na mesa. A oliveira ocupa um canteiro já bloqueado. Ciprestes e volumes de casas prolongam o cenário além dos muros. Janelas elevadas, frisos, memorial, rosácea, campanário e um arco central maior dão identidade à casa da Ordem. Trata-se da casa fictícia de Lisboa; o Convento de Cristo de Tomar não foi deslocado para este mapa.

O arco central reutiliza os pilares exteriores e retira os dois apoios que fechavam o eixo da portaria. A mudança abre circulação sem bloquear posições de saves anteriormente válidas. A câmera enquadra o dormitório mais para dentro do cenário e abre o campo gradualmente ao chegar à galeria norte. O recorte da arquitetura acompanha também a pessoa próxima da criança, evitando esconder o rosto de Leonor atrás de um arco.

Dois estandartes têm deformação de tecido animada no Blender, com cruz vermelha em superfície separada. A fonte recebeu ondulações e som localizado. O cavaleiro ganhou arestas suavizadas, antebraços e cotovelos articulados. A exportação agora produz um clipe coordenado por cena: o padrão do exportador separava os objetos e deixava parte das animações parada ao tocar apenas o primeiro clipe. Fontes `.blend` e GLB foram regeneradas com o mesmo construtor documentado acima.

Validação: **306 verificações em oito suítes**, incluindo a apresentação (29), o movimento (17), a abertura (67), nome (26), controles (41), continuidade (34), promessa (25) e floresta (67). A nova suíte verifica os pesos dos dois tecidos e as rotações dos dois cotovelos realmente mudando no Godot, materiais separados, UVs dos tecidos, entrada direta na refeição, objetivo persistente, passagem central, momento ambiente e retomada dos saves anteriores.

```powershell
& tools/test_lisbon_direction.ps1 -Suites childhood_home_presentation,childhood_home_motion,childhood_home,name_entry,childhood_controls,campaign_continuity,promise,forest_hunt
```

`tools/capture_childhood_home.gd` agora guarda sete vistas em `.qa-runtime/childhood-home/presentation/` e 32 amostras renderizadas dos ciclos do cavaleiro e dos estandartes em `presentation/motion/`. As amostras de animação usam avanço controlado dos clipes para inspeção; não são uma medição de desempenho. A revisão da apresentação é uma etapa jogável para avaliar a primeira impressão, não uma declaração de que toda a infância ou Lisboa já atingiu o acabamento final.

## Caminhada lateral

O protagonista agora usa também um ciclo de oito desenhos para os lados, com apoio, joelho dobrado, passagem e alternância entre perna próxima e distante. A cabeça mantém a mesma âncora horizontal e a escala acompanha a caminhada vertical. Para a esquerda, o ciclo completo é espelhado. Os quadros avançam pela distância percorrida em todas as direções; as poses de repouso são preservadas.

O [registro de arte e prompt](hero-child-side-walk-art.md) descreve o atlas, suas referências e o preparo reproduzível. A captura `tools/capture_childhood_side_walk.gd` percorre o claustro nos dois sentidos. Foram conferidos 61 recortes de uma execução de 183 quadros. Passaram **147 verificações em quatro suítes**: lateral 34, movimento 17, apresentação 29 e abertura 67.

```powershell
& tools/test_lisbon_direction.ps1 -Suites childhood_home_side_walk,childhood_home_motion,childhood_home_presentation,childhood_home
```

## Continuação com Leonor

A ligação da praça ao treino e à floresta foi refinada na etapa seguinte. O encontro ganhou deslocamentos encenados, o fim do treino conduz ao cuidado da mão e ao convite de Leonor, e o caminho permite conversar sobre as descobertas. As animações de oito fases também acompanham o protagonista nesses mapas. Ver [Da praça à primeira aventura com Leonor](infancia-percurso-leonor.md) para encenação, retomadas e verificações.
