# Revisão arquitetónica do convento — 18/10/2026

Etapa seguinte: [vida cotidiana, novos interiores, exploração e som](vida-cotidiana-convento.md).

Esta etapa corrige planta, perspectiva, escala e construção dos espaços existentes. Não acrescenta salas, moradores ou atividades.

## 1. Planta e circulação

A igreja passa para o lado poente do claustro, correspondendo ao volume alto que se vê no exterior. A enfermaria permanece a nascente e o acolhimento liga-se pelo lado poente. A abertura da capela, as paredes físicas, a abside, os bancos, a passadeira, o ponto de leitura e a câmera mudam em conjunto. A antiga passagem central fica fechada por alvenaria.

A planta interior usa coordenadas locais para a navegação; o exterior é uma projeção ilustrada desses volumes, com transição de mapa. A correspondência é de organização, acessos e hierarquia arquitetónica, não uma reprodução métrica integral de cada compartimento sob cada pixel do telhado. A portaria poente dá acesso ao acolhimento da casa; não funciona como uma entrada direta no altar.

## 2. Perspectiva

A fachada v2 foi refeita usando a própria casa azul de Ferro como referência de elevação da câmera, profundidade dos telhados, materiais e iluminação. O ponto de vista mais alto permite ver o vazio do claustro, a igreja a poente e a ala fechada a nascente. Mantém-se a largura de 1360 unidades da revisão anterior, sem deformação anisotrópica da imagem.

Os pisos de lajes usam agora projeção 2:1 no mapeamento das texturas; paredes e fundações mantêm o mapeamento vertical. Isso reduz a impressão de lajes gigantes vistas de frente no chão.

## 3. Escala e estrutura

Os três portais isolados do interior foram substituídos por uma galeria contínua de três vãos e quatro pilares partilhados, nas duas frentes existentes do claustro. A cornija é contínua e mais baixa, sem os grandes pináculos repetidos. Os pilares têm colisões individuais de 48 × 30 unidades; as aberturas são verificadas com o raio real do personagem e a margem de navegação.

A mesa da regra foi recuada para (-290,390), junto da parede poente: o teste de passagem detectou que a posição anterior invadia a aproximação do vão.

A portaria continua monumental, enquanto as galerias, bancos, camas e corredores mantêm escala de uso humano. Não se ampliou o mobiliário junto com a fachada.

## 4. Encaixe no terreno e detalhes

As colisões exteriores acompanham a base da nova arquitetura, incluindo a projeção da esquina sul. O acesso oriental foi alinhado com a porta da ala: (238,140). A portaria permanece em (-770,65). As soleiras, marcadores, rotas adultas e visita da infância acompanham esses pontos.

Um embasamento estreito e sombras curtas de contato seguem a fachada, em vez de um retângulo de fundo. A iluminação segue a incidência superior esquerda da referência. A cornija e os pilares novos substituem estrutura existente; a etapa não preenche o adro com decoração.

## Continuidade dos saves

O schema passa a 7 e continua a aceitar versões 1–6. Uma posição guardada na antiga capela da versão 6 é transladada 240 unidades para poente antes da validação e sem alterar a economia ou o objetivo. Posições nas outras áreas permanecem iguais; dados inválidos continuam a ser rejeitados antes de modificar o estado ativo.

## Artes

Ferramenta: geração de imagens integrada, em modo de edição/referência, com transparência. Os arquivos v1 foram preservados.

- Fachada: `assets/art/order/convent-gatehouse-v2.png`.
- Galeria contínua: `assets/art/order/cloister-arcade-v2.png`.

## Validação

315 verificações nas suítes de arquitetura (27), proporções exteriores (9), convento e infância (62), interação e interface (32), saves da infância (13), integração e migrações de Ferro (41), campanha completa (65), percurso urbano até ao socorro (24) e sequência original da praça (42). Incluem deslocação real pelos vãos, colisões dos oito pilares, entradas por clique e teclado, migração de saves adultos e infantis da capela, rejeição de posições inválidas e gravação sem translação duplicada.

A campanha completa percorreu as 17 cenas e os sete encontros de combate. Capturas gráficas em 1440×900 foram conferidas na praça, portaria, claustro, capela e enfermaria. A vista exterior de conjunto usa zoom de inspeção 0,8; o jogo mantém o zoom exterior normal 1,0.

### Prompt da fachada

Edit target: first image, existing Portuguese Order of Christ convent game sprite. Style and camera reference: second image, existing Mar de Ferro house sprite. Produce a revised convent sprite for the SAME 2D game on a genuinely transparent background. Preserve the identity, warm limestone, terracotta roofs, polygonal chapel drum and bell tower on the WEST/LEFT, Order of Christ red cross with narrow white interior, long lower cloister arcade on EAST/RIGHT. Correct architectural perspective: use a higher orthographic three-quarter view from the south-southwest, close to the camera elevation of the house reference, showing much more roof surface and believable rearward building depth. Keep the long south frontage nearly horizontal but descending gently to the right, as in existing convent. Architecture must describe an intelligible plan: chapel on west behind the monumental west portaria, cloister courtyard behind the long southern arcade, enclosed infirmary wing at east. Courtyard is only visible from above between roofs, not an extra courtyard in front. No extra rooms, no expanded program. Human scale: grand portal opening approximately 2.5 adult heights, individual arcade openings 1.7 adult heights, normal upper windows and roof tiles appropriately smaller and consistent with reference house. The whole complex is substantially larger than a domestic house. Retain two readable existing entrances: monumental west portaria around 20 percent image width, and unobstructed east-end arcade doorway around 94 percent width. Do not add stairs that block these entrances. Avoid generic cathedral spires, fantasy towers, additional flags, statues, potted plants or ornament clutter. Remove the oversized decorative foreground well from the arcade. Detailed painterly game texture, clear structural masses, contact shading built into masonry, warm light from upper left. Entire silhouette visible with small transparent margins, landscape canvas approximately 2:1. No ground plane, no backdrop, no text, no people, no UI. This is production game architecture, not a presentation painting.

### Prompt da galeria

Generate one production 2D game sprite: a continuous THREE-BAY stone arcade for the cloister interior of the Portuguese Order of Christ convent shown in the reference. Reference image is architectural/style reference only. This is an architectural correction, not extra decoration. One straight low limestone gallery frontage, exactly three pointed arch openings with four shared piers, a continuous modest stone cornice across all three bays. No separate freestanding triumphal gates, no pinnacles, no statues, no roof or walls filling the openings. Light warm worn limestone matching the reference's lower arcade, understated moldings, structurally believable joints. Orthographic elevated three-quarter camera, front nearly horizontal with a very slight descent to the right, visible small top surfaces on plinths and cornice. Human scale: a render width of 720 game units, overall height about 250 units, each clear opening approximately 145 units high and 170 units wide. Four piers centered approximately 30,250,470,690 units across the 720-unit width. Each pier foot roughly 40 units wide. Thin masonry connection over every opening. The three arch openings MUST be truly transparent holes, with no courtyard, no colored interior backdrop. Genuinely transparent background everywhere outside the masonry including inside openings. Soft contact shading on masonry only. Isolated complete sprite with minimal padding, wide landscape aspect approximately 3:1. No ground, no sky, no characters, no vegetation, no props, no text, no UI. Painterly high-detail game asset with warm upper-left lighting, consistent with Mar de Ferro architecture.
