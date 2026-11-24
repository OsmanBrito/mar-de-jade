# A Ordem de Cristo no início de Mar de Jade

Continuação implementada: [claustro, capela e enfermaria exploráveis](convento-exploravel.md), disponíveis na infância e na fase adulta. O registro abaixo descreve a primeira passagem de identidade visual e narrativa.

Ampliação solicitada pelo usuário em 18/10/2026: tornar explícita e grandiosa a presença templária e da Ordem de Cristo, incluindo a instituição que acolhe o protagonista e a identidade de Duarte.

## Identidade adotada

O abrigo passa a ser apresentado como **Casa de Acolhimento da Ordem de Cristo**, uma casa conventual fictícia em Lisboa ligada ao Convento de Cristo, em Tomar. Mantém a campanha em Lisboa e acrescenta pertencimento institucional ao cuidado de Tomé, à formação dos jovens e à escolta de Duarte. O protagonista continua aprendiz; a roupa de Duarte não lhe atribui novo posto.

A herança templária faz parte da memória e da arquitetura; a instituição ativa é a Ordem de Cristo. O Convento de Cristo histórico fica em Tomar, e a Ordem de Cristo sucedeu aos bens e privilégios templários em Portugal. Referência histórica: [Património Cultural, I.P.](https://www.patrimoniocultural.gov.pt/pat_mun/convento-de-cristo-em-tomar/). A casa de acolhimento de Lisboa e sua organização são conteúdo ficcional de Jade, não uma identificação histórica de um orfanato documentado.

## Implementado no jogo

- Nova fachada ilustrada na praça, substituindo o edifício genérico do abrigo e duas construções de fundo: portal de pedra, escudo da Ordem, estandartes, arcadas, corpo de capela e torre sineira. O conjunto é um marco de arquitetura conventual, com entrada humana legível.
- Pegada física da construção integrada às colisões e à navegação, preservando o acesso ao abrigo.
- Estandartes no interior, tanto na infância quanto no presente, e livro de acolhimento sobre a mesa.
- Nomes de lugar identificando a Ordem desde a primeira cena da infância e na abertura adulta.
- Dois pontos opcionais de leitura, acessíveis por caminhada e interação nos percursos adultos: memorial junto à portaria e livro do acolhimento no abrigo. Explicam ligação com Tomar, acolhimento, ensino, alimentação, tratamento e serviço. Fechar devolve o controle no mesmo lugar, sem recompensas ou avanço de missão.
- Traje claro de serviço e insígnia vermelha com centro branco em Duarte, na exploração, poses de conversa e combate, incluindo o renderizador aliado usado nas abordagens. O tratamento visual roda uma vez por atlas na GPU e mantém originais, recortes, pivôs, silhuetas e tempos das animações. Não substitui os sprites por novas animações.
- Contexto institucional incorporado ao documento narrativo aprovado, por autorização do usuário, sem reescrever suas falas.

## Limites desta entrega

A capela e a ala de claustro são representadas na arquitetura exterior; não são interiores novos exploráveis nesta entrega. O interior acessível continua sendo a sala do abrigo. O complexo completo — refeitório, enfermaria, capela e claustro com circulação própria — entra na reconstrução contínua de Lisboa sobre a base de Ferro. Esta implementação dá presença à instituição já nas cenas atuais; não declara concluída a migração do mapa inteiro.

## Validação

Ensaio gráfico no Godot 4.5.1 com OpenGL: 15 verificações, sem falhas. Verifica caminhada real até os dois pontos de leitura, retorno ao mesmo estado, acesso físico à portaria, presença dos elementos no mapa/interior, atlas originais intactos e textura de traje produzida para exploração/combate. A amostragem de alpha confirma dimensões e silhuetas preservadas. Foram inspecionadas capturas do conjunto, do interior e de nove exemplos de poses de Duarte.

Regressões verificadas: abertura (26), encenação do capítulo (49), circulação por Lisboa (62), abordagens (78), rotas do capítulo (15) e percurso completo pelos 17 blocos adultos (80), sem falhas. Junto às 15 verificações específicas, são 325 verificações sem falhas.

Reprodução do ensaio específico:

```powershell
# Usar APPDATA de teste separado dos saves reais.
$env:APPDATA = Join-Path (Get-Location) '.qa-runtime/order-identity'
& $env:GODOT_EXE --path . --script res://tests/order_identity.gd -- --capture
```

Sem `--capture`, não grava imagens. As capturas opcionais ficam em `.qa-runtime/order-preview/`. O ensaio usa `auto_save=false` e não gera executáveis.

## Arte e prompt

Ferramenta: geração de imagens integrada (`image_gen`), com transparência. Asset utilizado: `assets/art/order/convent-gatehouse-v1.png`. Heráldica interior e traje são tratamentos nativos do renderizador, separados das animações originais.

Prompt final utilizado para a arquitetura:

```text
Use case: stylized-concept. Asset type: finished 2D isometric architectural game asset, transparent cutout, standalone monumental Portuguese Order of Christ convent gatehouse and cloister wing. Primary request: an impressive but lived-in monastic orphanage and training house linked to the Convent of Christ in Tomar, designed for a Portuguese illustrated adventure game. Warm limestone, ivory limewash, medieval Gothic pointed arch main entrance at the LOWER LEFT QUARTER of the building's front facade, heavy open dark oak double doors, a clearly visible Order of Christ red cross WITH a smaller white cross cut into its center on a stone shield above that entrance. Two long wine-red and ivory hanging pennants marked with same cross. A rounded polygonal chapel drum and small bell tower rising behind, terracotta roofs, a long shaded cloister arcade extending RIGHT from the entrance, a carved well seen through the arches, herbs and pots at a few pillars. Monumental believable human scale: door approx 1/5 total building height, not tiny. Elevated 3/4 oblique game camera, see front facade and right roof plane; ground-contact line slopes gently down to right. Single coherent building, NOT a complete town or whole map. Wide roughly 2:1 composition with entire building fully visible plus clean transparent margin all around; no ground tile, no base plate, no sky, no landscape, no people, no text, no UI, no border. Detailed high quality hand painted illustrated game art, full color smooth edges, subtle texture, crisp masonry and deep arcade shadows, sunlight upper left, natural muted palette, not pixel art, not low-poly. Leave the open doorway legible as a playable entrance. Preserve real transparency outside building; no opaque white/checkerboard backdrop.
```
