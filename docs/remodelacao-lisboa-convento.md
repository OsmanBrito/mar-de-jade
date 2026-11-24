# Remodelação de Lisboa e do conjunto conventual

Revisão posterior: [proporções do convento e ampliação do adro](proporcoes-convento.md).

Revisão seguinte: [planta, perspectiva, escala e construção](arquitetura-convento-revisao.md).

18/10/2026. Passagem de design de ambientes, circulação e interação sobre a Lisboa atual de Ferro integrada à campanha de Jade.

## Direção aplicada

A praça passa a ter limites visíveis, vegetação coerente, portarias e uma descida marcada para a Ribeira. O convento ganha piso de lajes, paredes rebocadas, luz nas janelas, soleiras e corredores próprios. A escala dos materiais é independente da escala dos edifícios. A planta de Ferro, os acontecimentos da campanha, os moradores e as animações de Jade permanecem como base.

O acabamento atende problemas identificados nas capturas anteriores: piso de rua repetido dentro da capela e da enfermaria, bordas terminando em vazio, árvores de estilos distintos, arcadas muito dominantes e vários marcadores competindo com o cenário.

## Ambientes e percurso

- **Praça:** lajes do adro, jardins externos, muretas nos limites da parte alta, entradas com soleiras e placas para claustro e Ribeira. As árvores antigas que destoavam do conjunto foram substituídas pelo tratamento vegetal já usado na cidade.
- **Descida e Ribeira:** a faixa de piso conduz à abertura real da mureta de Ferro. As construções e os locais de trabalho mantêm sua organização; a água recebeu movimento visual discreto.
- **Claustro:** jardim e cisterna ancoram o centro; a arcada tem escala revista e sombras nos pilares. A passagem norte tem uma abertura física central, coerente com a parede desenhada.
- **Capela:** lajes próprias, reboco e corredor central com passadeira. A abside e os bancos continuam como marcos do espaço.
- **Enfermaria:** camas em áreas legíveis, luz vinda das janelas e uma circulação separada dos lugares de cuidado.
- **Câmera:** enquadramento próprio das alas internas e leitura da fachada durante a aproximação. As portas têm uma transição visual curta.

## Uso e orientação

Clicar numa entrada, descoberta, morador ou comerciante inicia a aproximação pelo caminho real. A interação só ocorre ao chegar a uma posição livre e próxima, com linha desimpedida. Movimento manual cancela a intenção do clique. E/A permanece disponível.

Os marcadores ficam discretos à distância e a interação mais próxima recebe o destaque. O indicador na borda aponta para o objetivo alcançável no lugar atual, incluindo a próxima porta quando o compromisso está noutra área. O cabeçalho da exploração informa lugar e compromisso/interação sem repetir a marca do jogo sobre o cenário. As dicas respeitam controle, remapeamento de teclas e largura da janela.

As descobertas observadas na casa da Ordem são conservadas no save. O menu **Pedidos → Lugares conhecidos · Casa da Ordem** permite reler seus textos. Isso não concede dinheiro, cura, equipamento ou técnicas, nem substitui acontecimentos da campanha. O formato continua na versão 6, usando flags adicionais compatíveis com o estado existente.

## Verificação

| Ensaio | Verificações sem falhas |
| --- | ---: |
| `childhood_city.gd` | 13 |
| `exploration_polish.gd`, incluindo mouse real, controle, remapeamento e três resoluções | 32 |
| `order_convent.gd`, com renderização | 62 |
| `lisbon_city_campaign.gd`, com renderização | 24 |
| `chapter_full.gd`, 17 blocos adultos e sete encontros | 65 |
| `plaza.gd` | 42 |
| `lisbon_requests.gd` | 85 |
| `player_inventory.gd` | 57 |

Total: **380 verificações**. O HUD foi conferido em 960×600, 1440×900 e 1920×1080. As capturas mostram o cenário em execução, o diário e a infância. Os testes usam dados isolados e não alteram o progresso do usuário. A avaliação de ritmo e sensação pelo jogador continua sendo útil; esta passagem não declara concluída a migração de todos os mapas de Ferro.

## Materiais novos e prompts finais

Geração pela ferramenta integrada `image_gen`, sem CLI. Os materiais foram salvos no projeto e são consumidos por `scripts/city/place_materials.gd`:

- [Lajes de calcário](../assets/art/places/limestone-floor-v1.png).
- [Reboco de cal](../assets/art/places/limewash-wall-v1.png).

### Lajes

```text
Use case: stylized-concept. Asset type: production seamless square 2D game ground texture, 1024x1024. Warm pale limestone flagstone floor for a Portuguese Order of Christ convent interior. Orthographic straight top-down texture, NO perspective. Long modest irregular rectangular stone slabs in staggered rows, each with fine pores, gently worn edges, faint ochre variation, narrow warm grey mortar joints. Slab width about 180 pixels, height about 105 pixels. Sophisticated detailed hand-painted realistic RPG material consistent with warm cream Gothic stone. Even neutral diffuse lighting; restrained low contrast so human sprites remain legible. Perfectly tileable on all four edges. Texture must fill entire image edge to edge. No border, no room, no walls, no grass, no furniture, no objects, no text, no cast shadows or gradients.
```

### Reboco

```text
Use case: stylized-concept. Asset type: production seamless square 2D game wall material texture, 1024x1024. Warm ivory limewash plaster on the interior of a Portuguese late-medieval convent. Straight-on orthographic flat material, absolutely no perspective. Subtle hand-trowelled uneven plaster, small warm cream grain, delicate age wear and sparse faint hairline cracks. Restrained painterly realistic texture in warm off-white and muted sand, low contrast, uniform material across image. Soft neutral diffuse lighting. Perfectly tileable on all four edges. Entire image filled with only plaster texture. No stone blocks, no wall edges, no trim, no doors, no windows, no sky, no frame, no objects, no text, no directional cast shadows, no dark vignette.
```
