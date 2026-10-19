# Ponto 9 — interface, controles e áudio

Fechamento técnico em 19/10/2026, após o commit e push dos pontos 1–8 (`2c2bac4`). O objetivo foi corrigir inconsistências observáveis e verificar os recursos existentes; aprovação humana de leitura, controle físico e som continua separada.

## Implementação

### Conversas entre cenas e salvamentos

- Histórico único com as últimas 200 falas exibidas na campanha, desde a abertura infantil até a navegação.
- Abertura, praça, treino, floresta, promessa, entrada adulta e cenas adultas registram as falas quando apresentadas.
- A troca de cena não apaga o histórico. Repetir a renderização da mesma fala não duplica a última entrada.
- Consulta em Conversas na pausa infantil, no menu adulto e na pausa/ficha de bordo. Ler não avança o roteiro nem concede recompensas.
- Conversas de Duarte, Beatriz, Rodrigo, sobrevivente e pescadores a bordo entram no mesmo registro; mensagens de sistema e abertura dos menus não são registradas como falas.
- Save do capítulo passa à versão 11 com validação estrita do histórico. Versões 1–10 continuam aceitas; saves anteriores sem histórico começam com lista vazia, sem reconstruir falas não vistas.
- Histórico acompanha o estado da campanha no save marítimo. Reiniciar a campanha limpa a lista.
- O histórico é conservado junto do progresso salvo; não existe uma gravação em disco a cada frase. A política de retomar falas/combates no início da etapa permanece.

### Preferências e controle

- Painel compartilhado de som, leitura e combate oferece todos os remapeamentos: movimento, interação, mover/encerrar turno, timing, sair de treino, caderno e salvamento.
- A infância e a navegação têm acesso ao mesmo painel completo. O Sistema adulto mantém seus controles já existentes.
- B/Esc cancela a captura de uma nova tecla; um segundo B/Esc retorna ao menu anterior. O mundo continua pausado enquanto um submenu estiver aberto.
- O painel restaura o foco anterior quando o controle ainda existe. Histórico utiliza entradas focáveis para permitir rolagem por controle.
- Silenciar música está disponível no painel compartilhado; música, ambiente e efeitos continuam com ajustes separados.

### Dicas e leitura

- Dicas marítimas são tratadas pelo contexto de navegação, evitando aplicar o botão A de timing à ação de parar a embarcação.
- No mar: RB para parar, LB para retomar rumo, Y para carta e X para convés. No combate naval: LB/RB para os lados de tiro, Y para ordens, X para reparo e B para retirada.
- A legenda de vela/leme no teclado acompanha o remapeamento do movimento.
- Menus de bordo usam a escala de texto compartilhada, largura limitada pelo viewport e rolagem em mensagens longas.
- Botões do rodapé marítimo ficam em uma linha, com largura distribuída, reticências e tooltip quando necessário. Não invadem a linha das dicas com texto ampliado.
- Janela de 960×600 (com o escalonamento oficial do projeto) e texto a 120% foram conferidos em capturas nativas: histórico de bordo, preferências compartilhadas e timing de combate sem áudio.

## Áudio e avisos visuais

As suítes exercitaram os oito contextos musicais, recursos reproduzíveis e em loop, crossfade, interrupção de transição, saída para navegação, volumes e mute. Os buses reais de efeitos/ambiente e o mute dos mixers de capítulo/viagem foram conferidos.

O ensaio sem áudio manteve instrução visual de timing, barra de precisão e resultado textual/numérico do golpe. Não foi necessário substituir efeitos ou músicas para resolver as inconsistências encontradas; qualidade sonora e mixagem percebida precisam de audição humana.

## Validação

566 verificações aprovadas em 11 suítes, sem erros de script ou falhas de asserção nos registros finais.

| Suíte | Verificações |
| --- | ---: |
| interface_closure (nova, com renderização) | 34 |
| campaign_continuity | 34 |
| chapter_music | 88 |
| player_inventory | 57 |
| integration_closure | 30 |
| navigation | 88 |
| combat_feel | 36 |
| childhood_controls | 41 |
| opening_presentation | 29 |
| chapter_full | 62 |
| forest_hunt | 67 |

A nova suíte verifica registro real de falas, limite do histórico, rejeição atômica de dados inválidos, migração da versão 10, gravação/carregamento em terra e no mar, consulta sem avançar o roteiro, captura/cancelamento de remapeamento por eventos de controle, retorno da pausa, dicas marítimas, mute dos buses e feedback de combate sem som.

Capturas e registros de QA ficam em `.qa-runtime/interface-close/` e `.qa-runtime/integration-close/`; são temporários e não entram no Git. Fixtures geradas pelos testes foram restauradas.

## Avaliação humana restante

- Controle físico: conforto, direcional/analógico, foco ao longo de uma campanha e identificação dos botões no modelo de controle usado.
- Texto longo e escolha narrativa com leitura natural em outras resoluções.
- Quantidade de informação simultânea no combate, compreensão sem som e em imagem pouco saturada.
- Audição da mixagem entre ambientes, interiores, floresta, combate, recuperação e mar; adequação dos efeitos procedurais.
- Aprovação final de ritmo, legibilidade e experiência.

Próximo: ponto 10 — campanha nova completa, jogadores externos, retomadas, desempenho e aprovação final.
