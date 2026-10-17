# Nitidez e resolução dos combates — 16/10/2026

Os combates da infância, da campanha e da abordagem agora usam um pixel da imagem renderizada por pixel exibido na área do jogo. A escala acompanha a janela, preservando as proporções do cenário, dos personagens e da interface.

## Problema e correção

O projeto trabalha com coordenadas de 1440×900 e ajusta a apresentação à janela. O `SubViewport` do combate usava essas coordenadas como se fossem pixels físicos: numa janela de 1920×1080, uma batalha da campanha era renderizada em 1440×900 e ampliada para a área de 1728×1080 do jogo. Essa segunda filtragem borrava a imagem. Em janelas menores também havia uma redução intermediária desnecessária.

`scripts/combat/battle_stage.gd` agora mede a transformação final da janela, aloca a imagem na resolução física da área disponível e compensa a escala externa no contêiner. A referência de 960×540 continua servindo apenas para organizar os elementos. O desenho é feito diretamente na resolução de destino; a textura final é apresentada na proporção 1:1.

As fontes também recebem a resolução efetiva de desenho: a transformação manual do combate não atualizava automaticamente a sobreamostragem dos glifos. A seleção pelo mouse usa a transformação completa do contêiner, incluindo a compensação da janela.

Foram consultados os scripts atuais de combate do Mar de Ferro. Seus 23 módulos de referência permanecem idênticos à fonte, exceto pelos caminhos de importação. Referência técnica do motor: [Viewport e sobreamostragem das fontes no Godot 4.5](https://docs.godotengine.org/en/4.5/classes/class_viewport.html#class-viewport-property-oversampling-override).

## Capturas do renderizador

[Antes, no estudo de combate](combate-resolucao-antes.png) · [Depois, no combate da campanha](combate-resolucao-atual.png). Ambas foram capturadas em janela de 1920×1080, sem redimensionamento posterior; o estudo inclui sua faixa de atalhos de revisão.

![Combate com resolução corrigida](combate-resolucao-atual.png)

## Validação

408 verificações passaram, sem falhas nos testes:

- `map_combat`: 148 verificações renderizadas, incluindo resolução física, proporções, resolução das fontes e cliques reais em 1280×800, 1600×900, 1024×768, 1920×1080 e 2560×1440.
- `boarding`: 80 verificações renderizadas, incluindo apresentação em pixels físicos e combate naval completo.
- `combat_presentation`: 19; `training`: 34; `combat_ending`: 27; `combat_field`: 23; `combat_feel`: 36; `chapter_full`: 41, em headless.

O teste de resolução anterior comparava apenas o tamanho do contêiner com o do `SubViewport`; isso podia passar mesmo quando a janela ampliava toda a textura depois. A regressão agora confere a transformação final até os pixels da janela e exerce os botões e a seleção de casas após cada redimensionamento.
