# Refinamento da floresta e travessia de Lisboa — 18/10/2026

Esta etapa trabalha a composição e a leitura dos espaços já jogáveis. A direção continua baseada nas referências indicadas pelo utilizador: [Hero's Adventure: Road to Passion](https://store.steampowered.com/app/1948980/Heros_AdventureRoad_to_Passion/) e [Sea of Stars](https://seaofstarsgame.co/). Não houve migração completa para pixel art; os personagens e suas animações aprovadas foram preservados.

## Composição e circulação

- A trilha principal passou de 128 para aproximadamente 86 unidades de largura externa, com variação suave. A escala fica mais próxima de uma trilha percorrida por duas crianças.
- Cada descoberta recebe um desvio conectado ao segmento mais próximo do percurso principal. Foram removidos os ramais que partiam arbitrariamente da mesma coordenada vertical.
- A terra usa um material procedural próprio, com repetição de UV em coordenadas globais e bordas transparentes. Deixou de usar a textura de parede caiada.
- Duas clareiras pequenas marcam o encontro com os animais e a descoberta do corço.
- O olival é mantido no trecho próximo de Lisboa. Sobreiros aparecem no bosque; vegetação baixa, sombras e pistas ajudam a dar profundidade e função aos espaços.
- A ribeira tem margens curvas, gradação de cor, vegetação assimétrica e pequenos reflexos móveis. A área de água continua usando a mesma planta de colisão, com margem de segurança do personagem.
- A ponte recebe espessura visível e um corrimão dianteiro ordenado pela profundidade. A colisão da borda deixa livre o centro da travessia.
- Ninho e vestígios dos carvoeiros tornam as descobertas visíveis no cenário.

## Lisboa e apresentação

O piso do adro e da Ribeira passa a usar um contorno unido, retirando a borda interna na descida. O material mantém a mesma escala e origem nos dois lados. As peças do mapa de Ferro continuam preservadas.

A passagem de exploração para diálogo corrigiu o posicionamento horizontal do objetivo, que podia ficar parcialmente fora da janela. Carregar uma posição da floresta também reposiciona a câmera imediatamente.

O terreno estático deixa de ser redesenhado integralmente a cada quadro. Reflexos e aves usam uma camada móvel separada, com atualização limitada; a opção de reduzir efeitos e a pausa do mundo são respeitadas.

## Arte integrada

Geração nova com a ferramenta integrada `image_gen.imagegen`, fundo transparente, sem referência raster e sem edição externa. Alpha preservado; recorte e mipmaps são feitos pelo carregador do jogo. Originais preservados no diretório de imagens geradas da sessão.

- Árvore: `assets/art/forest/cork-oak-v1.png`.
- Vegetação baixa: `assets/art/forest/undergrowth-v1.png`.

### Prompt final — sobreiro

```text
Use case: stylized-concept. Production game asset: one isolated mature Portuguese cork oak tree for a 2D illustrated RPG woodland near Lisbon. Elevated orthographic three-quarter view looking down about 35 degrees, broad asymmetric dark olive green canopy in distinct readable leafy masses, sturdy slightly leaning rough brown cork trunk and visible branching, restrained warm upper-left sunlight. Painterly illustrated game sprite with clean silhouette, cohesive subtle detail readable at 240 pixels high, natural rather than photoreal. Entire tree fully visible, compact composition, no clipped branches, transparent background throughout, no sky, no ground plane, no cast shadow, no grass patch, no text or border, no other objects. Keep base of trunk visible and centered under canopy.
```

### Prompt final — vegetação baixa

```text
Use case: stylized-concept. Production 2D illustrated RPG scenery sprite: ONE cohesive low Portuguese woodland undergrowth cluster, muted sage green bramble leaves, wild grasses, tiny dry ochre stems and two small weathered limestone rocks at the base. About three times wider than tall, organic uneven silhouette, full object visible, elevated orthographic view looking down 35 degrees, warm upper-left daylight, painterly hand illustrated game art matching a natural historical Portuguese RPG, simplified readable at 100 pixels wide. Genuinely transparent background, no ground plane or cast shadow, no scenery, no trees, no people, no border or text.
```

## Limites

Verificação desta etapa: 67 verificações da aventura da floresta, 24 do percurso adulto de Lisboa e 32 de exploração/interface passaram. Os três percursos também foram executados com renderizador OpenGL e capturas inspecionadas. A entrega e o socorro mantiveram o mesmo exterior, sem recargas. A verificação de espaços em branco de Git passou. Não foram medidos FPS ou tempo humano de conclusão.

As verificações automáticas cobrem percurso, colisão, câmera, interface e persistência. Não equivalem à aprovação estética do utilizador. O ritmo humano da infância de 30–45 minutos continua sem cronometragem. A próxima avaliação deve observar variedade dos espaços, proporção entre arquitetura e pessoas e utilidade da exploração.

