# Revisão dos mapas e ampliação da infância — entrevista de 18/10/2026

**Atualização de 19/10/2026:** [melhorias do ponto 6](infancia-vinculo-leonor-arco-01.md), com separação encenada, retorno opcional abreviado, continuidade da promessa e medidor local. A duração de 30–45 minutos continua pendente de validação com leitura natural. O texto abaixo conserva o histórico da direção aprovada.

## Correções pedidas

O utilizador considerou insuficiente o resultado jogável, especialmente conexões entre mapas, junções dos pisos, proporções e sensação de vida. Os resultados dos testes automáticos anteriores não constituem aprovação estética ou de experiência.

Referências indicadas: Hero's Adventure: Road to Passion e Sea of Stars. A referência deve orientar composição, circulação, exploração e apresentação; a adoção de pixel art ou mudança de perspectiva depende da resposta à entrevista.

## Música — executado

O catálogo do projeto atual de Ferro identifica Casa das Marés, Tema de Duarte e Inês e Depois da Onda como produzidas por Stable Audio local. Os três OGG e seus arquivos de importação foram removidos de Jade. Os contextos usam somente arquivos da pasta raiz `Mar de Ferro/assets/audio`: abrigo usa Echoes of the Templar City, cidade usa Porto Morning Tides, promessa usa Celestial Pages, recuperação usa Maré do Destino, treino usa Steel on Saltwind e duelo usa Duel at the Atlantic Edge. A floresta usa a faixa fornecida pelo utilizador `Under_the_Ancient_Canopy.mp3`. Nenhum arquivo de `assets/audio/music` é usado.

Também foram adicionadas à biblioteca disponível, sem atribuição de cena nesta etapa, `Tides_of_the_Gilded_Horizon.mp3` e `Steel_Against_the_Tide.mp3`.

Validação: 82 verificações de áudio passaram, incluindo carregamento, loop, cache, crossfade, contexto de floresta e transições das sete faixas. O projeto de Ferro foi apenas consultado como origem dos arquivos.

## Infância — direção confirmada pelo utilizador

- Duração desejada de 30–45 minutos, formando uma pequena história completa antes do salto para os 19 anos.
- Missão de caça com Leonor, incluindo exploração em uma floresta.
- Leonor separa-se rapidamente do herói; ele enfrenta e mata um lobo por conta própria.
- Surge um urso muito mais forte. Leonor regressa e passa a ser a personagem controlada pelo jogador.
- A luta continua por turnos, com as habilidades mais fortes disponíveis para Leonor. Ela derrota o urso com facilidade.
- Esse contraste de poder deve integrar a construção do vínculo entre os dois.

O lobo deve permitir uma vitória real do herói; o urso não deve virar uma luta artificialmente difícil para Leonor. As habilidades da demonstração pertencem a ela e não devem desbloquear prematuramente a progressão adulta do herói.

## Segunda rodada da entrevista — respostas recebidas

1. Leonor procura um animal raro nos arredores. Implementado como corço branco.
2. O herói já sabia que ela era forte, mas nunca tinha visto a dimensão desse poder. A conversa após o urso reconhece também a vitória dele sobre o lobo e o erro de Leonor ao afastar-se.
3. Preferência pelo caminho mais fácil, aceitando pixel art como Hero's Adventure. Nesta etapa foram preservados os personagens e animações aprovados: a mudança trabalha composição, circulação e materiais. Não houve conversão completa do jogo para pixel art.

## Diagnóstico técnico para a revisão dos pisos

O renderer atual desenha cada retângulo de sala e corredor com bordas próprias. Nas junções, essas bordas e os embasamentos sobrepostos fazem os espaços parecerem peças separadas. A revisão deve trabalhar com superfícies contínuas, paredes somente onde há separação física e soleiras apenas em mudanças justificadas. A planta e a escala devem ser avaliadas em conjunto com os personagens e com as referências escolhidas.

Não ampliar a quantidade de salas ou decoração para compensar esses problemas de composição.

## Implementação desta etapa

- Piso do convento calculado pela união geométrica das salas e corredores; um único contorno externo e UV globais. Removidas molduras sobrepostas nas ligações internas.
- Lisboa usa a mesma escala e origem do material de pedra entre os patamares e a descida. A grama passa a repetir em escala fixa, sem esticamento na arena.
- Nova aventura após o treino e antes da promessa: olivais, ribeira, ponte, rastros, três descobertas opcionais, decisões compartilhadas e retorno pelo caminho percorrido. Leonor acompanha pela navegação do mapa.
- Dois encontros reais por turnos: lobo vencível pelo herói; urso com 1.800 de vida contra Leonor, com oito ações e técnicas lendárias/supremas. A apresentação da suprema usa a própria Leonor criança. A demonstração não altera as habilidades adultas, moedas ou inventário.
- Save versão 8 conserva estágio, posição, descobertas e decisões; aceita versões anteriores. Recarregar após o lobo retoma a chegada de Leonor antes do urso. Coordenadas na água e estados incompatíveis são rejeitados sem alterar o progresso vivo.
- Vento e água são efeitos ambientes existentes; nenhuma música substituta foi gerada.

A meta de 30–45 minutos refere-se à infância completa, incluindo convento, exploração, treino, aventura e promessa. Não foi cronometrada com um jogador lendo e explorando em ritmo normal. O cenário novo é uma primeira composição jogável; ainda requer avaliação estética e de ritmo, não equivale ao acabamento final das referências.

Referências consultadas: [Hero's Adventure, página oficial na Steam](https://store.steampowered.com/app/1948980/Heros_AdventureRoad_to_Passion/) e [Sea of Stars, site oficial](https://seaofstarsgame.co/). São referências de direção; não foram copiados seus mapas ou recursos.

## Verificação reproduzível

`tests/forest_hunt.gd`: 64 verificações, incluindo deslocamento pela navegação até todas as descobertas e objetivos, os dois combates pela apresentação tática, técnica suprema com Leonor criança, recarga entre encontros, rejeição atômica de coordenadas na água, compatibilidade com save 7, ausência de desbloqueios adultos e transições reais treino → floresta → promessa. Executado com renderizador OpenGL e capturas para inspeção.

Regressões: treino 34; campanha adulta 65; arquitetura do convento 27; salas conectadas 23; exploração e interface 32; exploração infantil 13; música 72. Os 23 módulos de combate copiados de Ferro continuam idênticos à fonte atual, exceto os caminhos de importação. A nova aventura usa subclasses locais.
