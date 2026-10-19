# Correções da revisão dos nove pontos

Implementado em 19/10/2026 após a segunda revisão dos pontos 1–9. Esta passagem corrige os defeitos reproduzidos e uniformiza a preparação do grupo; a avaliação de ritmo, arte, mixagem e equilíbrio com jogadores permanece separada.

## Controles e leitura

- M, C, B, V, R e Espaço ficam reservados à navegação para comandos compartilhados com a exploração: movimento, interação, caderno e salvamento. Os atalhos próprios do combate mantêm seu contexto.
- Remapear um comando para uma dessas teclas é recusado com explicação, sem modificar as configurações.
- Configurações antigas com conflito são migradas para uma tecla livre, preservando as demais. Um aviso no painel de opções/Sistema informa o ajuste.
- O painel compartilhado conserva o foco em Texto, Restaurar ou no comando que estava sendo remapeado. Cancelar com B/Esc mantém o foco no comando correspondente.
- A escala de texto atualiza imediatamente os elementos existentes do HUD marítimo e dos menus, sem precisar reabrir a cena.
- Dicas escritas como “J · pedidos” acompanham o remapeamento do caderno.
- O atalho de teclado do caderno abre Diário e pedidos a bordo; o controle Y conserva sua função de carta/ordens na navegação.
- Viagens sem uma campanha associada mostram uma mensagem de diário indisponível, em vez de tentar ler campos ausentes do estado.

## Histórico

- Conversas e inspeções opcionais da exploração infantil registram o texto quando ele é apresentado.
- Avisos do pontão entram no histórico tanto pelo fluxo de visita ao cais quanto pela prancha do mapa contínuo.
- Inspeções locais da cidade também utilizam o histórico compartilhado.
- Mantém-se a gravação junto dos checkpoints e salvamentos existentes, sem escrita em disco a cada frase.

## Suprimentos e Duarte

- Inventário de Lisboa oferece Usar no protagonista e Usar em Duarte, com os mesmos limites de recuperação do uso a bordo.
- A ação em Duarte consome uma unidade da bolsa comum e altera apenas os recursos dele.
- As telas de item em Lisboa e a bordo mostram a recuperação efetiva e o excedente para cada pessoa.
- Rações calculam vida e alento separadamente. Recursos completos continuam impedindo consumo desnecessário.
- As ações e previsões aparecem antes da descrição longa no inventário de Lisboa.

## Validação

440 verificações aprovadas em dez suítes, sem falhas de asserção nem erros de script nos registros finais:

| Suíte | Verificações |
| --- | ---: |
| review_fixes (nova, com renderização) | 41 |
| childhood_controls | 41 |
| interface_closure | 34 |
| player_inventory | 57 |
| campaign_continuity | 34 |
| optional_closure | 71 |
| arc_revision | 5 |
| harbor_visit | 39 |
| navigation | 88 |
| integration_closure | 30 |

A suíte nova reproduz as correções de tecla reservada, migração de configuração antiga, dica remapeada, fala infantil, foco, recuperação de Duarte, previsão de excesso, fonte do HUD, atalho da carta e caderno. O teste de pedidos percorre a prancha real e confirma a presença da fala do pontão no histórico.

Os testes anteriores de interação que usavam V passam a usar U, uma tecla livre. A rejeição de V e dos demais atalhos reservados recebe verificações específicas.

Captura nativa conferida: `.qa-runtime/review-fixes/recovery.png`. Logs e backups em `.qa-runtime/` são temporários. Fixtures de testes foram restauradas. A suíte nova ainda emite aviso de objetos retidos ao encerrar, sem erro de script; análise de memória prolongada permanece pendente.

## Continuação

Os refinamentos recomendados de rotinas mais longas, variedade visual, duração dos percursos, leitura das pistas, ritmo emocional e comparação entre estratégias de combate requerem a passagem jogada prevista no ponto 10. Não foram declarados aprovados por estes testes técnicos.
