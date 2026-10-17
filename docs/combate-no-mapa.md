# Mapas de combate separados por local

Esta revisão substitui a integração equivocada do combate dentro da cena de exploração. A referência foi conferida executando o projeto atual `jogo` no Godot: batalhas de Bruma, Lisboa, enseada e prólogo. A captura antiga `beta_combat_attack.png` não é a referência visual.

## Estrutura

O fluxo agora é **local de exploração → identificador do cenário de batalha → combate num World2D separado → retorno à exploração intacta**. Só o identificador do local cruza essa fronteira; a luta não recebe os nós do mapa, não troca os atores originais nem altera suas posições, câmera ou navegação.

`data/chapter_01/battle_maps.json` define os cenários de praça infantil, praça adulta, pátio, cais, serviço/armazém, interior do abrigo e convés. Cada perfil contém materiais, ambientação e obstáculos próprios. A campanha escolhe o perfil pelo local corrente; o treino infantil usa `plaza_child`. A abordagem naval conserva seu cenário específico e sua grade maior, sem receber os obstáculos dos treinos terrestres.

O piso é um material repetido em escala constante e continua para além da área jogável. Não há pintura inteira ampliada, preenchimento de textura por casa ou tabuleiro elevado. Edifícios e objetos usam regiões completas de atlas e escala uniforme; não são montados em faixas filtradas que deixam emendas. As margens de diferentes proporções de janela recebem continuação do piso, sem esticar a arte.

A batalha renderiza na resolução efetiva do viewport. 960×540 serve de referência de posicionamento, ajustada por um único fator uniforme. A seleção pelo mouse utiliza a transformação inversa dessa mesma camada.

A [correção de nitidez de 16/10/2026](combate-resolucao.md) também compensa a escala externa da janela e ajusta a resolução das fontes. A validação passou a conferir os pixels físicos de destino, incluindo cliques após redimensionar.

## Arquivos

- `scripts/combat/battle_maps.gd`: catálogo e obstáculos dos mapas separados.
- `scripts/combat/portugal_arena.gd`: materiais, ambientação e objetos proporcionais.
- `scripts/combat/battle_host.gd`: seleção do mapa antes de iniciar as regras.
- `scripts/combat/battle_stage.gd`: renderização nativa, enquadramento e entrada.
- `scripts/combat/combat_study.gd`: revisão sem saves; F1 também escolhe mapa.
- `tests/map_combat.gd`: independência da exploração, seleção, movimento/desfazer, impacto, perfis e proporções em três resoluções.

A implementação anterior `map_battle*`, que inseria a luta no mundo de exploração, foi removida. Também foi retirado o retângulo claro provisório desenhado sobre o herói ferido; o estado narrativo de ferimento continua existindo.

## Conferência

Executar `tests/map_combat.gd` no renderizador OpenGL verifica todos os perfis e janelas de 1600×900, 1024×768 e 1920×1080. As capturas desse teste ficam temporariamente em `.godot/separate-combat-*.png`. Também devem passar `combat_presentation`, `combat_field`, `combat_feel`, `training`, `combat_ending`, `boarding`, `first_playable_ui` e `chapter_full`.

As imagens e vídeos de revisões anteriores não representam necessariamente esta versão.

Resultado desta revisão: **127 verificações renderizadas dos mapas**, apresentação (19), leitura do campo (23), impacto e animação (36), treino infantil (34), encerramento (27), abordagem renderizada (80), interface (39), percurso adulto completo (41) e acabamento do abrigo (41), sem falhas. Os testes headless emitem um aviso ambiental de acesso ao repositório de certificados do Windows; os testes gráficos dos mapas e da abordagem encerraram sem erros de script ou renderização.

Capturas mantidas como referência da versão entregue: [pátio e movimento](combate-patio-atual.png), [praça e duelo](combate-praca-atual.png), [cais](combate-cais-atual.png).
