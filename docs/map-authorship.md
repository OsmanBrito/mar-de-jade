# Autoria dos mapas — primeira etapa, 14/10/2026

A composição aprovada do cais e do armazém está agora guardada nas próprias cenas. O jogo não reconstrói chão, props ou interações a partir dos JSON. Os JSON conservam título, região, exterior/interior e dimensões das paredes do interior. O estado da viagem continua separado da apresentação.

## Editar no Godot 4.5.1

1. Abrir `scenes/maps/cais.tscn` ou `scenes/maps/armazem.tscn` na vista 2D.
2. Selecionar `Ground` para pintar ou apagar células do TileMapLayer. O TileSet partilhado é `data/terrain/ground.tres`, com a mesma normalização de textura do protótipo. Não alterar os PNG originais.
3. Mover ou duplicar instâncias dentro de `ActorsAndProps`. Manter `Y Sort Enabled` no grupo e o seu Z em 2. Usar escala uniforme e não rodar casas: a profundidade assume a projeção aprovada.
4. Para criar objetos, arrastar cenas de `scenes/props/`: `house`, `pine`, `crane`, `crates`. Atribuir `object_id` único por mapa ao duplicar uma instância; este ID prepara a persistência futura, ainda não a implementa.
5. Abrir a cena do prop para editar `Body/Footprint`, um CollisionPolygon2D visível e editável. Para alterar só uma instância, usar filhos editáveis e tornar recursos únicos quando aplicável. Editar a cena base altera todas as suas instâncias.
6. Nas casas, manter `sloped_depth` ativo e os sprites em tiras como filhos diretos. O script `map_prop.gd` atualiza a origem de ordenação de cada tira quando o polígono é editado, conservando a posição da imagem. O pivô da raiz representa contacto no chão; não recentrar os sprites.
7. Instanciar `scenes/interactions/door.tscn`, `npc.tscn`, `ledger.tscn` ou `observe.tscn`. A posição do nó é o ponto de interação. No Inspector, editar `definition` (`id`, `kind`, `title`; portas também usam `destination`) e `interact_radius`. O círculo de alcance aparece apenas no editor. O NPC já tem sprite e colisão como filhos da cena.
8. Mover o Marker2D `Spawn` para editar a chegada inicial. As portas ainda usam o retorno específico do protótipo em `main.gd`; entradas nomeadas serão a etapa 2.
9. Guardar o mapa. Para testar o estudo do cais, abrir `scenes/main.tscn` e executar com F6; F5 passou a iniciar a campanha pela escolha do nome. A navegação lê os polígonos editados, incluindo posição e escala, ao montar o mapa. Alterações durante uma partida não recalculam a grelha; reiniciar ou voltar a montar o mapa.

Os campos antigos `cell`/`offset` nas definições de interação são metadados do protótipo. Não controlam a posição: mover o nó na cena é a fonte de verdade.

## Validação desta etapa

- Percurso integrado gráfico: 28 verificações sem falhas; inclui movimento, colisão da casa, caminho por clique em área aberta, diálogo, transições, diário por estado e save/load.
- Autoria: 16 verificações sem falhas; incluem zoom inicial 1,25, chão serializado, cenas reutilizáveis, spawn editado, célula removida e prop deslocado alterando os obstáculos de navegação em ambos os mapas.
- Comparação do recorte estático da casa: 23 de 131.750 pixels diferem, no máximo uma unidade de cor em 255. A composição e o enquadramento foram mantidos; a diferença residual é compatível com arredondamento da transformação em escala.
- Capturas reais inspecionadas: cais, armazém e personagem à frente da porta. A personagem aparece inteira à frente da fachada.
- Importação pelo editor sem erros de GDScript. A sandbox impediu guardar as preferências globais do editor e o motor repetiu o aviso de certificados Windows; não são falhas das cenas.

Relatórios: `tests/playtest-report.json`, `tests/authorship-report.json`. Baseline anterior: `tests/authorship-before-*.png`. Captura da porta: `tests/authorship-door-preview.png`.

Reproduzir na pasta do projeto (o log local evita o acesso aos logs globais):

```powershell
& 'C:/Users/gamer/Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe' --path . --log-file ./tests/authorship.log --script res://tests/playtest.gd
& 'C:/Users/gamer/Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe' --headless --path . --log-file ./tests/authorship-checks.log --script res://tests/authorship.gd
```

## Continuidade

Esta etapa não altera `player.gd`, a arte original, a arquitetura de domínio ou o formato de save. Água, paredes, mesa do registo e indicadores conservam a apresentação por shader/desenho original, com pré-visualização por scripts `@tool`. Não houve ensaio físico de comando nem revisão manual prolongada de todas as paredes.

A seguir: padronizar portas e entradas nomeadas, retirar a chegada específica do armazém de `main.gd` e rever caminhos em torno de obstáculos considerando o raio do jogador e os NPCs. O algoritmo atual foi preservado; a conversão não resolve ainda esses limites. Depois avançar para identidade/estado dos NPCs e diálogos por dados, na ordem aprovada.
