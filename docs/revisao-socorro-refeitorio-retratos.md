# Revisão do socorro, refeitório e retratos

**Atualização de 19/10/2026:** [melhorias e validação do ponto 7](arco-adulto-encenacao-ponto-07.md), com objetivos por etapa, encenação do cuidado e da saída acompanhada, clareza dos confrontos e diário de acontecimentos. O texto abaixo registra as etapas anteriores.

## Direção confirmada

A pausa com Leonor adulta acontece no refeitório do convento. O olho esquerdo do herói é verde e o direito azul, considerando o lado do personagem. No retrato frontal, o azul aparece à esquerda da imagem e o verde à direita.

## Alterações

- Retirados os treinos obrigatórios com Duarte no início adulto e após a escolha do manejo. Duarte continua amigo e participante do socorro.
- “Uma mão livre” começa com o aviso de que a corda rompeu e uma viga prendeu o braço do trabalhador. O enquadramento apresenta o acidente antes da interação. Primeiro assenta-se a alavanca, depois a carga é levantada com Duarte.
- Leonor convida para a cozinha e o refeitório da Ordem. O jogador recolhe as porções com a ajudante e leva-as à mesa existente. A conversa usa os bancos permanentes do convento, sem criar uma mesa no cais.
- O herói e Leonor levantam-se antes da exploração. Ao liberar o jogador, a apresentação também limpa o estado sentado e o suporte do assento.
- Loja: botões de compra, venda e filtros recebem espaço horizontal; colunas ajustam-se à janela. Compra real e visibilidade foram verificadas.
- Diálogos exibem retrato do interlocutor à esquerda. O herói tem retratos próprios de criança e adulto; os demais usam recortes dos sprites existentes. Os olhos no sprite também respeitam o lado anatômico ao espelhar.
- Save versão 9 mantém compatibilidade e migra o cursor antigo de buscar Tomé da versão 8.

## Validação

- Capítulo completo: 62 verificações, 17 blocos, quatro modos de combate; nenhum treino obrigatório de Duarte.
- Inventário e comércio: 57 verificações.
- Percurso e interface desta revisão: 39 verificações, incluindo receber/levar a refeição, sentar, conversar, levantar, caminhar, salvar e comprar. Capturas em 960×600, 1440×900 e 1920×1080.
- Rotas alternativas: 15 verificações.
- Percurso físico da entrega e do socorro: 24 verificações, sem combates de treino e sem recarregar o exterior entre acontecimentos.
- Abertura adulta e correspondência com roteiro: 19 verificações.
- Floresta e infância: 67 verificações.
- Validador do roteiro: 249 falas aprovadas em 17 blocos.
- A aparência continua sujeita ao teste do jogador; não foi medida a duração humana da infância.

## Retratos gerados

Modo: ferramenta integrada image_gen, com referência local, saída com transparência. Sem substituição dos sprites aprovados.

Referência adulta: assets/art/portugal-v2/hero-story-poses-v1.png.
Saída: assets/art/portraits/hero-adult-v1.png.

Referência infantil: assets/art/npcs/lisbon/hero_child-v1.png.
Saída: assets/art/portraits/hero-child-v1.png.

### Prompt final adulto

```text
Use case: identity-preserve. Create a NEW SINGLE dialogue portrait for the game Mar de Jade, using the attached sprite sheet ONLY as character identity and art-style reference. Show this same 19-year-old young man, from chest upward, almost frontal, looking toward the viewer with both eyes equally visible. Preserve the soft wavy brown hair, facial proportions, cream shirt, faded teal waistcoat, warm Portuguese illustrated RPG style and quiet determined expression. Critical canonical eye colors: HIS anatomical LEFT EYE is GREEN (on the RIGHT side of the image); HIS anatomical RIGHT EYE is BLUE (on the LEFT side of the image). Make the two iris colors clear, natural and distinct, not glowing. Refined hand-painted production character art, clean lines and softly shaded shapes matching the source, warm daylight, no new jewelry or armor. One bust only, head fully visible with small clear margin, shoulders and upper chest visible, genuine transparent background. Do not reproduce the sheet, poses, grid or multiple characters. No scenery, frame, text, symbols, weapons, labels or watermark.
```

### Prompt final criança

```text
Use case: identity-preserve. Create a NEW SINGLE dialogue portrait for the game Mar de Jade, using the attached sprite sheet ONLY as character identity and art-style reference. Show this same 9-year-old boy, from chest upward, almost frontal, looking toward the viewer with both eyes equally visible. Preserve the soft wavy brown hair, facial proportions, cream shirt, faded teal waistcoat, warm Portuguese illustrated RPG style and quiet determined expression. Critical canonical eye colors: HIS anatomical LEFT EYE is GREEN (on the RIGHT side of the image); HIS anatomical RIGHT EYE is BLUE (on the LEFT side of the image). Make the two iris colors clear, natural and distinct, not glowing. Refined hand-painted production character art, clean lines and softly shaded shapes matching the source, warm daylight, no new jewelry or armor. One bust only, head fully visible with small clear margin, shoulders and upper chest visible, genuine transparent background. Do not reproduce the sheet, poses, grid or multiple characters. No scenery, frame, text, symbols, weapons, labels or watermark.
```

