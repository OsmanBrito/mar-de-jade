# Ritmo e balanceamento do primeiro arco

Revisão de 19/10/2026.

## Ajustes implementados

As aulas concluídas de Tomé copiavam o desgaste de vida, alento e postura para a campanha, enquanto abandonar a aula preservava os recursos pessoais. Experimentar vários manejos penalizava justamente quem concluía os exercícios.

Agora as aulas de fundamento, Defesa Perfeita e apoio usam um orçamento separado: vida e postura completas nos limites do equipamento, com 8 de alento. Acertar, errar, repetir ou abandonar conserva os recursos pessoais anteriores. O aprendizado continua sendo concedido pelas mesmas condições, e as aulas não oferecem cura para a campanha. O duelo narrativo conserva sua derrota real, e a abordagem continua usando os recursos restantes do protagonista e de Duarte.

Ao voltar à seleção depois de concluir um manejo, o foco do controle vai para **Continuar**, evitando reiniciar o primeiro exercício por engano. Os outros manejos e a prática livre permanecem disponíveis.

A loja informa o custo da reserva básica e explica que a primeira arma é oferecida por Tomé ao confirmar o manejo. A página Personagem esclarece a separação entre recursos dos exercícios e recursos da viagem.

## Economia conferida

| Referência | Ouro |
| --- | ---: |
| Pagamento obrigatório do serviço, uma única vez | 40 |
| Gibão de prática | 24 |
| Ligadura de linho | 6 |
| Cantil de água | 3 |
| Sobra ao comprar os três | 7 |
| Recompensas dos quatro pedidos opcionais, somadas antes de despesas | 29 |

A primeira arma é concedida pela escolha com Tomé, sem compra obrigatória. A preparação básica acima cabe na renda obrigatória, sem exigir pedidos opcionais. Não foi necessário alterar preços, estoque ou recompensas. Compra e revenda continuam dando prejuízo, e confirmar novamente a escolha não duplica a arma.

## Ritmo e dificuldade

A auditoria estática encontrou 226 falas diretas nos 17 blocos de `chapter_flow.json`, somando 1.295 palavras. O maior bloco direto tem 26 falas curtas e 146 palavras. A contagem com ramificações é maior; ela não corresponde a uma única sessão. Esses números descrevem texto, não tempo real de jogo: excluem caminhada, escolhas, encenação e combate.

Os percursos atuais e a progressão dos 17 blocos até a partida passaram no teste completo. O jogador pode concluir uma aula para prosseguir ou experimentar os cinco manejos na mesma visita. As condições de aprendizado, o confronto com Leonor e a dificuldade da abordagem foram mantidos; a mudança elimina o desgaste desigual causado por repetir tutoriais.

A duração e o efeito emocional das cenas não foram certificados por automação. O próximo passo é uma passagem humana completa para medir tempo parado, tentativas de combate, clareza dos destinos e vontade de explorar, antes de novos cortes ou ajustes de dificuldade.

## Validação

| Suíte | Verificações sem falhas |
| --- | ---: |
| `arc_balance.gd`: cinco manejos com recursos baixos, conclusão, falha, interrupção, economia e arma inicial | 38 |
| `chapter_rules.gd`: regras e derrota jogável | 38 |
| `player_inventory.gd`: equipamento, consumo e economia | 57 |
| `chapter_styles.gd`: cinco manejos na mesma visita | 12 |
| `campaign_continuity.gd`: recursos reais entre terra e viagem | 34 |
| `chapter_full.gd`: percurso até a partida | 62 |
| **Total** | **241** |

O teste de inventário foi atualizado para exigir vida local completa na aula e vida pessoal preservada. O teste dos manejos passou a percorrer a recuperação atual e verificar as sete passivas das cinco aulas, sem contar o antigo treinamento removido de Duarte. Os arquivos de campanha usados pelos testes ficam em perfis de QA separados.


Atualização: [fechamento técnico do ponto 8](combate-preparacao-economia-ponto-08.md), com comparação entre manejos, clareza da preparação e 481 verificações. Os valores permanecem sujeitos à avaliação com jogadores.
