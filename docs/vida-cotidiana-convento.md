# Vida da casa da Ordem — 18/10/2026

Continuação da revisão arquitetónica, seguindo os pontos restantes da lista de design.

## Adro com função e entradas legíveis — pontos 4 e 6

A portaria poente tem um irmão da casa que explica os acessos de Tomé, claustro, capela e enfermaria. A responsável dos mantimentos trabalha numa mesa com pão e pano de serviço; a cisterna ocupa a faixa poente. Um aprendiz circula num percurso curto, dentro da área utilizável. Os atores de serviço têm um pequeno emblema da Ordem, sem alterar os atlas aprovados. A mesa, a cisterna e os trabalhadores têm implantação física e aproximações livres.

Os pontos de atividade ficam fora do banco de Leonor e do eixo principal entre portaria, arcadas e Ribeira. A câmera ganha um desvio gradual para nascente quando o jogador visita a faixa poente, reduzindo o espaço vazio fora do adro.

## Presença cotidiana e interiores vividos — pontos 7 e 8

A casa passa a mostrar receção, conferência de mantimentos, transporte de água, preparação dos cuidados e trabalho da cozinha. O ajudante da enfermaria recebe a caneca; ela passa a aparecer sobre a mesa depois da entrega.

O interior contínuo inclui agora:
- dormitório a poente, com três camas, armário e passagem para o corredor do acolhimento;
- refeitório na ala de serviço a nascente, com duas mesas, quatro bancos e passagem central;
- cozinha ligada ao refeitório, com lareira, caldeirão, bancada, mesa de trabalho e ajudante.

Cada sala possui um ponto de descoberta que entra no diário, usa a navegação real e é acessível durante a infância. Não há cura, recompensa de combate ou conclusão automática de acontecimentos da campanha ao visitar esses ambientes.

## Integração visual e enquadramento — pontos 9 e 10

A mobília, os recipientes e os personagens reutilizam os conjuntos existentes de Jade; a cisterna vem do conjunto atual de Ferro. A única arte nova é a lareira, feita a partir da referência de materiais e perspectiva da casa de Ferro. Mantêm-se as proporções humanas definidas na revisão anterior.

A câmera enquadra dormitório e ala de serviço separadamente, com transição suave. A parede norte da enfermaria deixa uma abertura visível para o refeitório. Soleiras e placas foram conferidas nas capturas para evitar sobreposições.

## Exploração com continuidade — ponto 11

O pedido opcional “A água da casa” segue quatro etapas: falar com a responsável, recolher a caneca na cisterna, entregar ao ajudante da enfermaria e voltar para confirmar. O estado aparece em Pedidos e é guardado nos saves existentes, sem novo schema.

Infância e vida adulta têm estados distintos (`house_child_*` e `house_adult_*`). O porteiro adulto recorda a ajuda prestada na infância, mas essa lembrança não conclui a tarefa adulta. Repetir as interações não gera moeda, equipamentos ou recompensas duplicadas.

## Som — ponto 12

O conjunto tem vento exterior discreto, água localizada junto das cisternas e um sino espaçado. Dormitório e áreas de serviço usam pequenos sons de pano e recipientes; a capela fica mais recolhida. Passos na pedra usam o sistema existente. Recolher e pousar a caneca também produzem foley.

O sino é uma síntese modal original de quatro segundos, sem dependência de gravações externas. Os ambientes respeitam o bus JadeAmbience; os sons das interações usam JadeEffects. Os sons cessam com a saída do mapa e ficam pausados com o jogo. O material não inclui falas gravadas.

## Validação

393 verificações sem falhas: vida da casa (61 em execução gráfica), novos ambientes (23), convento/infância (62), interação/interface (32), percurso urbano (24), campanha completa (65), inventário/menu (57), arquitetura e migração dos saves (27) e sequência da praça (42). Incluem caminhada real, clique de mouse no porteiro, recolha e entrega nas duas idades, diário, save/load, conclusão repetida, memória da infância, acesso aos novos ambientes e preservação dos objetivos e da economia.

As imagens foram capturadas no Godot em 1440×900. A revisão visual encontrou e corrigiu o aprendiz fora do limite, a responsável escondida pela árvore, a parede cobrindo uma passagem e a soleira sobrepondo a placa da cozinha.

## Arte nova e proveniência

Ferramenta integrada de geração de imagens, em modo de referência, com fundo transparente. Arquivo final: `assets/art/order/kitchen-hearth-v1.png`. Referência: `assets/art/ferro-lisbon/bruma-v2-house_teal.png`.

Prompt:
Production game sprite, one complete modest late medieval Portuguese convent kitchen hearth, genuinely transparent background. Match warm limestone and terracotta, painterly detailed orthographic elevated three-quarter camera of the reference house from Mar de Ferro. A broad built-in pale stone cooking hearth with a hood, dark fire opening, small controlled embers, one hanging iron cauldron, short adjacent stone worktop with a plain wooden bowl and water jug. No people, no text, no backdrop, no ground plane, no extra furniture, no montage. Compact institutional working kitchen, not fantasy tavern. Entire silhouette fully visible, roughly square composition. Warm light from upper left, restrained warm ember glow inside the firebox only, authentic material scale. Transparent outside the masonry and objects. At game scale width 230 units, hood roughly two adult heights, worktop about waist high.
