# Wandering Sword como referência para Mar de Jade

22/10/2026. Proposta de aplicação da referência visual e de funcionamento escolhida na conversa. Este documento registra uma direção e um primeiro recorte avaliável; não declara essa transformação implementada.

Etapa posterior: [engenharia reversa estrutural da instalação local](../reference-study/wandering-sword/README.md), com inventário do PAK, classes de mapas, propriedades de câmera e animação e esquemas de tabelas efetivamente decodificados. Os resultados e limites dessa análise estão separados das propostas abaixo.

Primeiro experimento implementado: [amostra jogável de Lisboa em cenário 3D com sprites](estudo-jogavel-hd2d.md), incluindo controles de comparação, capturas da campanha e 25 verificações. A geometria da amostra é provisória e a campanha não foi migrada.

## Objetivo

Aproximar Mar de Jade da leitura de um RPG em pixel art com profundidade 2.5D: personagens destacados do ambiente, cenários organizados por planos, contato convincente com o chão e efeitos discretos. A identidade continua portuguesa, com calcário, cal, telha de barro, madeira de cais e água verde-jade.

A [descrição oficial de Wandering Sword](https://store.steampowered.com/app/1876890/Wandering_Sword/) informa que o jogo usa Unreal Engine 4, combina pixel art com paisagens 3D e possui combate sobre tabuleiro com modos por turnos e em tempo real. Isso descreve a referência, não a arquitetura atual de Jade nem uma decisão de importar esses dois modos de combate.

## Base existente e diferença técnica

Jade usa Godot 4.5 e composição de ambientes em Node2D. A documentação atual registra circulação contínua em Lisboa, ordenação por profundidade, oclusão localizada do protagonista, sombras de contato e materiais compartilhados. Ver [direção de Lisboa](lisboa-direcao-jogo.md), [direção artística inicial](art-direction.md) e [acabamento dos ambientes](acabamento-visual-ambientes.md).

Essa infraestrutura permite experimentar profundidade aparente antes de investir em cenários tridimensionais. Uma composição 2D em camadas não produz automaticamente a iluminação, a perspectiva ou o movimento de câmera de um ambiente 3D. Uma eventual passagem para 3D precisa de um protótipo separado e de avaliação do custo de reconstrução.

## Tradução da referência

| Aspecto | Aplicação proposta no Jade | Ponto de partida |
| --- | --- | --- |
| Profundidade | Organizar primeiro plano, percurso caminhável e fundo; deixar portas e destinos visíveis durante a aproximação | Composição e quarteirões de Lisboa |
| Coerência da arte | Fixar escala de detalhe, contorno e contraste de um conjunto pequeno de materiais e objetos | Famílias atuais de arquitetura e mobiliário |
| Personagem legível | Ajustar contraste do entorno e sombra dos pés; conservar o recorte localizado atrás de fachadas | Ordenação e oclusão já documentadas |
| Luz e atmosfera | Testar luz quente junto das construções e tons mais frios perto da água, com efeitos contidos | Materiais, sombras e shader de água existentes |
| Cidade habitada | Compor moradores e objetos conforme trabalho e circulação; deixar o caminho principal reconhecível | Moradores, bancas, oficinas e serviços existentes |
| Combate | Melhorar leitura de preparação, alcance, impacto e recuperação dentro das regras atuais | Sistema de combate de Jade/Ferro |
| Interface | Priorizar objetivo, interlocutor e ação contextual, com contraste legível sobre o cenário | Interface contextual atual |

Esses itens são decisões de design propostas para Jade. Não são conclusões de uma auditoria do código interno de Wandering Sword.

## Primeiro recorte: praça → mercado → cais

Usar o percurso existente como amostra da direção, com os mesmos pontos de captura antes e depois. A comparação precisa mostrar o jogo em movimento, além das imagens paradas.

1. Registrar o estado atual da praça, do mercado e da chegada ao pontão, no enquadramento normal de jogo.
2. Definir uma família visual pequena: piso de calcário, fachada de cal, madeira de cais, uma banca e vegetação de apoio. Escolher recursos próprios ou com licença compatível com a distribuição pretendida.
3. Aplicar a família apenas ao recorte, ajustando escala, paleta, contato com o chão e separação entre planos. Conservar as animações atuais dos personagens durante essa primeira comparação.
4. Percorrer a rota com o controlador real, aproximar-se do comerciante, passar atrás de um objeto alto e chegar ao embarque.
5. Comparar legibilidade e coerência visual; registrar se o resultado é suficiente em 2D ou se ainda justifica um experimento com cenário 3D.

Os pontos técnicos a inspecionar são `scripts/city/lisbon_composition.gd`, `lisbon_ground.gd`, `lisbon_scenery.gd`, `lisbon_finish.gd` e a interface de exploração. Os roteiros existentes `tools/capture_lisbon_direction.gd` e `tools/test_lisbon_direction.ps1` são candidatos para captura e regressão; sua execução deve acompanhar as alterações efetivamente feitas.

## Critérios de comparação

- O protagonista e seus pés continuam reconhecíveis no piso, junto da banca e atrás de objetos altos.
- Piso, fachada, mobiliário e personagens têm escala visual compatível no zoom normal. Aplicar filtro nearest a uma pintura não equivale a produzir pixel art coerente.
- O percurso e as entradas continuam claros em 1440 × 900 e 960 × 600, incluindo a ampliação de texto já suportada.
- Comércio, objetivos, oclusão, colisões e embarque continuam funcionando no percurso.
- As capturas usam posições e condições equivalentes; desempenho deve ser medido no mesmo ambiente, sem presumir ganho ou ausência de custo.

A comparação visual ainda precisa de avaliação em execução. A presente proposta não inclui novas capturas, testes executados ou alteração de cenas.

## Origem dos recursos

Wandering Sword será usado como referência de experiência e apresentação. A produção do recorte deve registrar autor, origem e licença de cada recurso incorporado.

Há material anterior de Hero's Adventure em `reference-study/heros-adventure/`, documentado como extração para estudo. A busca textual também encontrou referências a essa pasta em `scripts/chapter/portugal_quay_art.gd` e `scripts/chapter/reference_ground_study.gd`. Isso não comprova sozinho que os arquivos entram no percurso ou na exportação atual. Antes de tratar um pacote como pronto para comercialização, é necessário verificar essa dependência concreta e substituir ou licenciar qualquer conteúdo usado sem autorização de distribuição. Nenhum desses arquivos foi alterado nesta etapa.

## Decisão nesta etapa

Manter a base atual como ponto de partida do experimento. A escolha de Wandering Sword como referência não decide uma migração de engine, uma conversão completa para 3D ou a substituição das regras de combate. O próximo resultado avaliável é o recorte visual jogável descrito acima.
