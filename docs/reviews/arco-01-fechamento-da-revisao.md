# Arco 1 — fechamento da implementação da revisão

17/10/2026 · projeto principal: `C:/Users/gamer/Documents/GitHub/mar-de-jade`.

Esta página é o registro atual dos 43 pontos da [revisão](revisao-direcao-arco-01.md), considerando as [correções do usuário](arco-01-diretrizes-revisadas.md). As páginas das entregas anteriores conservam resultados históricos. “Implementado” descreve comportamento disponível e verificado; não equivale a aprovação de ritmo, emoção ou diversão por jogadores.

## O que jogar agora

Abrir **Jogar.cmd**, na raiz. Em **Som, leitura e combate**, antes de começar, ajustar música, ambiente, efeitos, tamanho do texto, timing ampliado, redução de efeitos e velocidade das animações. As preferências seguem para a viagem. O painel bloqueia a entrada de nome enquanto estiver aberto; Esc/B fecha e devolve o foco.

Na abertura adulta, concluir a entrega antes de regressar ao treino. No socorro, assentar o apoio e depois coordenar o levantamento com Duarte. A percepção do ferimento vem depois da retirada da madeira e não cura o trabalhador; Tomé atende por meios comuns. A refeição exige buscar as porções e servi-las.

O cais abre três intervalos seguros: depois do socorro, depois da convivência/refeição e antes do embarque. O objetivo do retorno muda conforme o compromisso seguinte. Conversar com oficina, pescadora, vizinha e trabalhador do pontão; negociar com o comerciante. **J / menu → Pedidos** conserva o objetivo principal e os pedidos locais. **Conversas** permite consultar até 100 falas já vistas na sequência adulta, sem executar novamente seus efeitos.

Há três pedidos originais de Lisboa:

| Pedido | Experiência | Resultado único |
|---|---|---|
| C01-LIS-01 · A roda presa | Inspecionar o carro, identificar a cavilha, obtê-la, coordenar o reparo e retornar | Carro deslocado, passagem livre, reconhecimento; 12 de ouro e uma ração |
| C01-LIS-02 · A conta das entregas | Ouvir o pontão, confirmar a entrega à cozinha e reconciliar sete caixas distribuídas em cinco mais duas | Registro corrigido na banca, novas respostas; 8 de ouro |
| C01-LIS-03 · Uma sacola preparada | Conferir uma ligadura e água da reserva pessoal antes da viagem | Reserva mantida, explicação de uso na abordagem; 3 de ouro |

Os pedidos são opcionais. Escolhas incorretas recebem explicação e permitem nova tentativa; não fecham a campanha. Os três estados podem coexistir e são salvos. Repetir conversa ou recarregar não duplica pagamento. Não foram renumeradas as 23 opcionais Oxx do corpus, nem implementada uma revisita pós-Coroa que os capítulos atuais não oferecem.

No pátio, experimentar os cinco manejos, interromper com **R / Select / botão de saída**, trocar e voltar. A saída funciona durante escolha, deslocamento, timing, animação e encerramento; uma aula incompleta não concede aprovação, arma, passiva ou recompensa. O duelo narrativo conserva seu contrato próprio.

Cada manejo oferece básico, fundamento e dois exercícios extras de comparação. Os extras usam IDs locais `C01-DEMO-*` e nomes **Exercício · …**: são ações de treino originais, não implementações do catálogo narrativo nem desbloqueios permanentes. Foram retiradas as associações indevidas a ES08, LA01, MC09, FO09 e PU09, cujos efeitos canônicos eram diferentes. O fundamento aprendido permanece separado da demonstração. Esta entrega não implementa o catálogo integral v2.

Antes de continuar com a primeira arma, preparar até quatro passivas do protagonista ou consultar separadamente as de Duarte. É possível prosseguir sem equipar. Os avisos de combate mostram custos economizados e dano mitigado, inclusive quando o arredondamento produz zero. Disparo de Medida reduz metade do bônus explícito de aproximação; não reduz arbitrariamente todo ataque que tenha caminhada. O enfraquecimento pertence ao adversário atingido: acertar um boneco não enfraquece um ataque de Tomé.

A Botafogo parte de cena própria. O diário lembra Madeira como escala para a missão de mantimentos/busca na rota de Duas Águas e a condição de aprendiz sob Rodrigo. **180 de ouro de bordo** pertencem ao fundo da tripulação; não substituem a carteira pessoal. Na abordagem, ligadura recupera 25 de vida e água 5 de energia, gastando a ação e o item. Vida, energia, postura e consumíveis restantes do protagonista seguem para o próximo encontro na mesma viagem. O checkpoint de Portugal permanece independente. Não foi acrescentada persistência individual dos ferimentos de Duarte.

## Fidelidade e autoria

- Base editorial deste recorte: [Portugal consolidado em 14/10](../narrativa/C01-portugal-aprovado.md), que incorpora aprovações posteriores ao C01 do corpus integral. A comparação automatizada confirma as **250 falas dos 17 blocos adultos**, incluindo alternativas. Essa comparação não audita sozinha todos os gestos, a infância ou a campanha completa.
- Corpus integral consultado: `C:/Users/gamer/Documents/Codex/2026-10-13/continue-o-roteiro-e-a-entrevista-2/outputs/mar-de-jade-roteiro-completo`, em conjunto com o pacote de leitura de 12/10. Mantêm-se derrota adulta real, recuperação anterior ao treino, Defesa Perfeita ensinada por Tomé e embarque como aprendiz. Não foram antecipadas revelações de Leonor, cura ou a resolução africana.
- Entrega à cozinha, novos diálogos de moradores, pedidos `C01-LIS-*` e exercícios `C01-DEMO-*` são complementos de implementação sob a solicitação de ampliar o arco. Não são apresentados como trechos previamente aprovados da bíblia. Recompensas locais são valores iniciais de teste, não balanceamento definitivo.
- A referência de sistemas é a pesquisa existente de Hero’s Adventure, especialmente `04-npc-system.md`, `05-dialogue-system.md`, `06-quest-and-event-system.md` e `11-mar-de-jade-recommendations.md`. Aplicaram-se disponibilidade por estado, descoberta, execução, retorno, consequência e persistência. Os dossiês documentam capacidades e limites da investigação; não comprovam um playtest integral da referência.
- Os **23 módulos de combate herdados do projeto atual de Mar de Ferro** continuam idênticos à fonte, exceto caminhos de importação. Os ajustes ficam nas adaptações de Portugal e navegação.
- **Olhos:** o usuário esclareceu um azul e outro verde e, em seguida, pediu para não realizar esse trabalho agora. Nenhuma nova alteração dos olhos faz parte deste fechamento. O ponto visual não é declarado corrigido nem validado.
- O mestre visitante permanece apresentado como **Mestre**, conforme a decisão ainda aberta no documento aprovado. Não lhe foi inventada uma identidade.

## Lista completa, ponto a ponto

| Nº | Estado nesta entrega | Evidência / limite |
|---|---|---|
| 1 | Conteúdo e ligações ampliados; ritmo por validar | Entrega, três pausas de exploração, três pedidos, retorno assistido e recuperação. Nenhuma alegação de duração humana. |
| 2 | Implementado | Apoio e coordenação no socorro, decisões no carro, investigação de entregas, buscar/servir refeição e amarra em duas etapas. |
| 3 | Implementado no recorte | Repetição adulta curta conserva as falas aprovadas; saídas de treino evitam prender o jogador à bateria. Não foi removido ensino canônico. |
| 4 | Implementado; interesse por validar | Quatro moradores conversáveis, três pedidos, comércio, consequências e preparação aplicável na abordagem. |
| 5 | Implementado | Mestre enfrenta e desarma o combatente; Leonor responde a tentativas e desarma o mestre. |
| 6 | Implementado | Objetivo do duelo explica observar distância, responder e prosseguir com a derrota. |
| 7 | Competência jogável implementada; arte retirada do escopo atual | Entrega, apoio, coordenação, passagem, pedidos e provisões. Olhos não encerrados como corrigidos. |
| 8 | Encenação ajustada; validação humana pendente | Aproximação, canecas, silêncio e reenquadramento; não se revelou intenção secreta de Leonor. |
| 9 | Implementado | Auxílio na praça, retorno assistido, água ao alcance, gesto de beber e caminhada de ida/volta com Tomé. |
| 10 | Implementado | Cena própria da Botafogo elimina árvores, decoração e colisões da praça herdada. |
| 11 | Implementado | Reenquadramento da mesa, banco, paciente e cabeceira. |
| 12 | Implementado; coerência artística final por avaliar | Convés, mastro, cordame, tripulação, amarra e afastamento real da margem. Não há nova série completa de animações desenhadas. |
| 13 | Implementado | Público disposto na demonstração; avaliação posterior em composição reservada. |
| 14 | Implementado nos gestos revistos | Pano, tigela, canecas, instrumentos, porções e carga possuem posição/transferência visível. |
| 15 | Implementado na encenação | Pulsação no ferimento, perda de foco e atendimento comum; sem cura automática. |
| 16 | Implementado | Retirada do paciente, liberação de passagem, respostas de moradores e carro reparado persistente. |
| 17 | Implementado | Compromisso em Pedidos, preparação e saída; Madeira é escala, Duas Águas é parte da missão. |
| 18 | Implementado | Escolhas exibem a fala aprovada em vez de rótulos vagos como “Admitir”. |
| 19 | Implementado | Histórico de falas vistas no menu adulto; consulta não repete efeitos. Releitura infantil mantida. |
| 20 | Implementado | Cinco manejos, saída em qualquer fase de treino, troca, três ações além do básico e sons de manejo. Dois movimentos são exercícios locais. |
| 21 | Implementado | Descrições e previsão distinguem alcance, área, postura, preparação, linha livre e custo. |
| 22 | Implementado | Feedback das passivas corresponde à alteração aplicada; previsão não consome efeito. |
| 23 | Implementado | Preparação oferecida no contexto da escolha; quatro vagas e propriedade de Duarte explícitas. |
| 24 | Retirado pelo usuário | Não adotado como obrigação de desgaste entre exercícios. |
| 25 | Implementado no recorte | Conferência de suprimentos e consumo real na abordagem; compra opcional. Balanceamento econômico por validar. |
| 26 | Implementado | Ouro; carteira pessoal distinta do fundo inicial da tripulação. Não se alega autenticidade de moeda histórica. |
| 27 | Implementado para protagonista e reserva | Recursos/consumo seguem entre abordagens; derrota usa regra de retomada segura. Ferimentos individuais de Duarte fora desta mudança. |
| 28 | Implementado | Avisos graduais ao içar vela, virar, parar e abrir carta; consulta posterior na pausa. |
| 29 | Interface verificada; usabilidade humana pendente | Painéis e comandos exercitados; texto a 120% inspecionado. Peso visual em combate requer observação de uso. |
| 30 | Implementado | Marcador com fundo próprio, camada acima dos atores e linha até o alvo; instruções por etapa. |
| 31 | Acabamento aplicado; direção artística contínua | Praça/pátio com detalhes localizados, abrigo mobiliado, cais e convés próprios. Não equivale a arte final de todo o jogo. |
| 32 | Implementado tecnicamente; escuta/mixagem pendentes | Passos por distância, madeira/pedra, pano, água, louça, mar e gaivotas. Quatro novos efeitos procedurais originais; não gravações profissionais. |
| 33 | Implementado | Preferências compartilhadas de música, ambiente e efeitos antes da campanha, no Sistema e na viagem. |
| 34 | Implementado | Timing ampliado, redução de efeitos, combate rápido, texto 100–120% e remapeamento das nove ações expostas de teclado. Não é remapeamento integral de controle. |
| 35 | Implementado; percepção por validar | Janelas com contorno, marcador central e rótulos; resultado escrito, além de cor e som. |
| 36 | Implementado no recorte | Dicas seguem dispositivo; Y percorre exercícios, Select sai, LB/RB navegam; foco e retorno exercitados. Controle físico ainda requer teste. |
| 37 | Implementado | Entrada informa etapa e repetição do início; viagem informa último ponto seguro. Validação e backups mantidos. |
| 38 | Implementado | Objetivo principal e pedidos acessíveis por J/menu, incluindo destino e função na viagem. |
| 39 | Pendente de jogadores externos | Protocolo abaixo. Automação não comprova compreensão, diversão ou desempenho em outros computadores. |
| 40 | Documentação consolidada | Esta matriz, instruções atuais de navegação e histórico identificado. Identidade do mestre continua explicitamente aberta. |
| 41 | Implementado | Assuntos condicionais, pedidos, serviço de comércio e reconhecimento posterior com save. |
| 42 | Implementado; continuidade percebida por validar | Entrega anterior ao treino, intervalos seguros, manhã seguinte, auxílio, recuperação e preparação/partida. |
| 43 | Aplicado | Pesquisa de NPCs, diálogos, quests e persistência consultada; implementação original sem copiar conteúdo da referência. |

## Verificação técnica

**851 verificações em 18 ensaios, sem falhas nos resultados finais**, executados ao longo desta revisão. Não é contagem de casos humanos nem de testes todos executados no mesmo processo. Os ensaios diretamente afetados pelos ajustes finais foram repetidos após eles.

| Ensaio em `tests/` | Verificações | Log de aprovação em `tests/` |
|---|---:|---|
| practice_freedom.gd | 127 | complete-practice_freedom.log |
| player_inventory.gd | 57 | closed2-player_inventory.log |
| chapter_music.gd | 74 | closed2-chapter_music.log |
| navigation_atmosphere.gd | 37 | closed2-navigation_atmosphere.log |
| combat_ending.gd | 27 | closed3-combat-ending.log |
| chapter_routes.gd | 15 | accepted-chapter_routes.log |
| navigation.gd | 88 | accepted-navigation.log |
| chapter_passives.gd | 19 | accepted-chapter_passives.log |
| first_playable_ui.gd | 46 | accepted-first_playable_ui.log |
| navigation_campaign_entry.gd | 12 | closed-navigation_campaign_entry.log |
| chapter_full.gd | 58 | complete-chapter_full.log |
| chapter_styles.gd | 9 | complete-chapter_styles.log |
| lisbon_requests.gd | 84 | acceptance-requests.log |
| arc_revision.gd | 57 | complete-arc_revision.log |
| name_entry.gd | 26 | final-name_entry.log |
| opening_presentation.gd | 29 | end-opening_presentation.log |
| chapter_staging.gd | 48 | end-chapter_staging.log |
| chapter_rules.gd | 38 | complete-chapter_rules.log |

O ensaio integrado usa caminhada e colisão reais nos pedidos, entrega e socorro; testa recompensa única, estado simultâneo dos pedidos, save inválido recusado antes de alterar o estado, preferências, tecla remapeada, consulta de conversas, consumo de suprimentos e continuidade entre duas abordagens. Compara os hashes de campanha, perfil, navegação e preferências antes/depois. As execuções de QA não usam o save do jogador como fixture.

O validador de conteúdo confirmou 17 blocos/250 falas sem divergências. O verificador da referência confirmou 23 módulos preservados. `git diff --check` não encontrou erros de whitespace. O ambiente emite aviso do repositório de certificados; uma execução renderizada da entrada também emitiu aviso de recursos remanescentes ao encerrar, sem falha funcional. A investigação headless da entrada não reproduziu esse último aviso. Não se conclui ausência de vazamentos no jogo completo.

Capturas do próprio Godot inspecionadas: [opções iniciais](../../previews/revision-initial-settings.png), [texto a 120% em 1024 × 640](../../previews/revision-settings-120.png), [histórico](../../previews/revision-history.png), [refeição](../../previews/revision-meal.png), [banco](../../previews/revision-same-bench.png), [apoio do socorro](../../previews/revision-rescue-supported.png) e [conta concluída](../../previews/revision-account-settled.png). Não são montagens. Algumas imagens conservam estados de uma passagem anterior ao último pequeno ajuste de posição ou texto; código e ensaios são a referência funcional.

## Aceitação humana que ainda falta

Jogar uma campanha nova com pessoas que não conhecem o roteiro, sem lhes indicar respostas ou rotas. Registrar o tempo até o primeiro controle e a duração efetiva dos trechos, hesitações, pedidos descobertos espontaneamente, erros de preparação e motivos para interromper. Não fixar a antiga meta de 120 minutos como resultado.

Após cada trecho, verificar sem explicar previamente:

1. O jogador sabe a finalidade da entrega e como o socorro começou? Entende o que fez para libertar o trabalhador e que a manifestação não o curou?
2. Distingue demonstração pública, avaliação privada e derrota que continua a história? Como interpretou o prazo e a ameaça de Leonor, sem receber revelações externas?
3. Encontra assuntos e pedidos sem condução? Percebe mudanças no carro, no registro e nas respostas? Algum deslocamento parece trabalho vazio?
4. Consegue sair no meio do treino, trocar manejo, comparar exercícios e explicar o que aprendeu permanentemente? Entende passiva conhecida versus equipada?
5. Entende o uso de ligadura/água, o custo de uma ação e a diferença entre seu ouro e o fundo da tripulação?
6. Ao partir, lembra que é aprendiz, que Madeira é escala e qual é o compromisso da Botafogo? Tem vontade de continuar?

Repetir a passagem de interface com teclado e controle físico, texto a 120%, áudio desligado e imagem pouco saturada. Escutar a mixagem com música/ambiente/efeitos em volumes distintos. Testar desempenho em outro computador. Essas verificações encerram os pontos de percepção da lista; não foram substituídas por automação ou por uma alegação de que o arco já está aprovado.
