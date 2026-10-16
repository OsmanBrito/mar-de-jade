# Reaproveitamento do Mar de Ferro

Autorização do usuário: usar também o trabalho do Mar de Ferro quando ajudar o Mar de Jade. A fonte consultada é `C:/Users/gamer/Documents/ChatGPT/jogo`, lida sem alterações.

## Aplicado ao cais

**Margem integrada à água.** `scripts/chapter/quay_bank.gd` adapta o método de `scripts/bruma_terrain.gd` do Mar de Ferro: face seca de alvenaria, faixa úmida e fundação com transparência gradual sob a água, mais sombra de contato. As profundidades de 30/38/50 da fonte foram ajustadas para 36/46/60 na escala dos personagens deste mapa. As coordenadas de textura seguem a posição no mundo. O piso caminhável mantém a altura e a navegação existentes. O mesmo helper desenha a margem próxima e sua continuação exterior, sem emendas de escala.

A textura `assets/scenery/bruma-bank-masonry-v1.png` da fonte foi copiada, sem redesenho, para `assets/art/living-quay/mar-de-ferro-bank-masonry-v1.png`. SHA-256 de ambas: `C3C88D890CBAB68EEAE5922E798F18161FBA0C4D44A2B7E02AE82F28E7C61C42`. A criação original e os critérios visuais estão documentados no Mar de Ferro em `docs/BRUMA_TERRENO_MODULAR.md` e `docs/BRUMA_MARGEM_E_PROPORCOES.md`.

**Câmera de rua e embarque.** `scripts/chapter/quay_camera.gd` adapta o enquadramento de `scripts/lisbon_world.gd` e `coast_world.gd`: na rua, mantém arquitetura à vista; ao chegar ao pontão, acompanha a água e o barco. Os pontos são convertidos da projeção 2:1 do Mar de Jade antes da interpolação. A câmera de diálogo conserva o enquadramento do diretor enquanto o movimento estiver travado.

## Critérios recuperados

Os documentos e preferências do Mar de Ferro registram acabamento ilustrado aprovado, filtragem suave, escala humana medida pelas portas e corpos, materiais de chão em escala fixa, sombras e margens apoiadas na água. Essa base permite trabalhar composição e legibilidade próximas da referência sem impor uma redução artificial de resolução ou de paleta.

Também foram consultados `world_life.gd`, `world_ambience.gd` e os cenários de Lisboa e costa para orientar futuras decisões. Nesta revisão, foram adaptadas a margem e a câmera; o elenco, as rotinas e o roteiro continuam os do Mar de Jade.

## Validação

`tests/living_quay.gd`: 49 verificações passaram, incluindo caminhada real, sete moradores em movimento, continuidade da cidade, bloqueio do rio, enquadramento ao chegar ao pontão e preservação da câmera durante diálogo. Captura geral inspecionada em Godot/OpenGL. `tools/verify_combat_reference.ps1` confirmou que os 23 módulos de combate continuam iguais à fonte, exceto os caminhos de importação.
