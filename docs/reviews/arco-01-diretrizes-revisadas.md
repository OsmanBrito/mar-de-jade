# Arco 1 — diretrizes após o retorno do usuário

Data: 16/10/2026. Complementa e corrige [a revisão inicial](revisao-direcao-arco-01.md). Este documento registra decisões e propostas de produção; não afirma que as alterações de gameplay já foram implementadas.

**Estado atual em 17/10:** consultar o [fechamento ponto a ponto](arco-01-fechamento-da-revisao.md). O texto abaixo conserva as decisões e a ordem original de produção, sem substituir a matriz atual.

Primeira implementação entregue: [pedido A roda presa e conversas de Lisboa](../cais-pedidos.md), com exploração após o socorro, quatro moradores conversáveis, reparo, recompensa e consequência persistente.

Segunda implementação entregue: [demonstração pública, recuperação e embarque](../encenacao-praca-recuperacao-embarque.md), com trocas e desarmes visíveis, água e caminhada de ida e volta, amarra em duas etapas e navio em cena própria. A página distingue os pontos atendidos dos que avançaram parcialmente. As demais exigências abaixo continuam orientando as próximas entregas.

## Diagnóstico corrigido

O arco atual é curto, tem muitos pulos e oferece pouca atividade significativa na cidade e no porto. O problema inclui falta de conteúdo e de ligações entre os acontecimentos. A proposta anterior de priorizar medição/corte de duração antes de ampliar o conteúdo não representa o retorno do usuário.

NPCs andando não tornam o local funcional. A experiência precisa permitir conversar, descobrir assuntos e pedidos, resolver problemas, receber consequências e usar serviços. O porto precisa ser um lugar onde o jogador tem o que fazer, além de esperar a próxima cena obrigatória.

## Decisões expressas

- Ampliar conteúdo e continuidade do arco; não usar a meta histórica de 120 minutos como descrição da duração atual.
- Reformular tarefas que hoje parecem interações arbitrárias, sem sentido de jogo.
- Reduzir repetição didática e apresentar oportunidades reais de aplicação do aprendizado.
- Criar conversas e missões secundárias úteis na cidade/porto, fundamentadas também na engenharia reversa da referência escolhida.
- Refazer a demonstração de Leonor com preparação, confronto e consequências legíveis; atualmente é rápida demais e não mostra o necessário.
- Demonstrar as competências do protagonista por ações e corrigir o detalhe dos olhos na arte. Não há autorização para inventar novas cores, poderes ou explicações fora do design canônico.
- Melhorar recuperação, enquadramentos, público, gestos, socorro, consequências e motivação da partida.
- Diferenciar manejos com testes, técnicas e sons próprios. Durante o treino, permitir sair a qualquer momento, trocar arma e voltar.
- Ampliar as técnicas disponíveis para demonstrar as qualidades de cada arma; distinguir repertório emprestado/demonstrado de aprendizado permanente, quando necessário.
- Retirar o item 24 como exigência independente. Recursos entre exercícios serão definidos em função do treino reformulado.
- Substituir “reais”. **Ouro** é a denominação de trabalho autorizada; nenhuma moeda histórica será escolhida sem verificar o período do cenário.
- Os demais pontos da revisão foram aceitos como direção de melhoria, inclusive persistência, navegação gradual, interface e acessibilidade.

## Referência recuperada

Fonte local: `C:/Users/gamer/Documents/Codex/2026-10-14/continue-a-conversa-e-a-entrevista/Mar-de-Jade/Research`.

- `04-npc-system.md`: identidade/presença separadas da instância visual, opções condicionais, primeiro encontro, falas ambientais por contexto e serviços de interação.
- `06-quest-and-event-system.md`: descoberta, início e conclusão de eventos; objetivos, condições e consequências persistidas; diário como apresentação desse estado.
- `11-mar-de-jade-recommendations.md`: articulação de NPCs, missão, estado posterior, estoques e recompensas únicas; preservação dos IDs e opcionais do corpus.

Os dossiês distinguem metadados/documentação de comportamento observado. Não afirmar que todos esses comportamentos foram comprovados por execução da referência. A extração visual em `reference-study/heros-adventure` não substitui a investigação dos sistemas. Mar de Ferro, quando consultado, deve ser o projeto atual, conforme AGENTS.md.

## Ligações de conteúdo a construir

| Trecho | Experiência necessária | Critério de aceitação |
|---|---|---|
| Infância → presente | Transição temporal compreensível e reencontro com lugares/pessoas conhecidos | O jogador identifica a passagem do tempo e o que permanece no vínculo |
| Entrega → chamado do cais | Trabalho com finalidade, circulação e reação ao acidente | O socorro nasce de uma situação percebida, com destino e urgência claros |
| Socorro → convivência | Coordenar ajuda, encontrar Tomé, liberar passagem e ver o resultado | O jogador sabe quem foi ajudado, como e o que mudou |
| Tarde no cais → avaliação no dia seguinte | Intervalo seguro com exploração/conversas e transição temporal clara | O jogador compreende o compromisso seguinte e pode usar a cidade |
| Demonstração → duelo | Mostrar a competência do mestre e a superioridade de Leonor antes da avaliação privada | O confronto público tem começo, ação e encerramento reconhecíveis |
| Derrota → recuperação | Assistência e retorno compreensíveis, poses e progressão de autonomia | A recuperação não parece um salto de estado sem experiência |
| Recuperação → pátio | Experimentação livre e preparação do personagem | É possível encerrar um treino, trocar arma e comparar técnicas/sons |
| Preparação → embarque | Concluir assuntos locais, negociar, despedir-se e assumir tarefa concreta | A partida encerra uma etapa vivida e apresenta a responsabilidade seguinte |

## Carteira inicial de conteúdo local

As entradas abaixo são propostas concretas de produção, não fatos novos já aprovados do enredo. Antes de atribuir IDs ou recompensas, reconciliar com as 23 opcionais e os requisitos de recuperabilidade do corpus; não renumerar nem duplicar missões existentes.

| Núcleo candidato | Ações do jogador | Consequência útil |
|---|---|---|
| Pendência do abrigo | Conversar com quem precisa, descobrir o necessário e organizar a ajuda | Mudança visível no abrigo e retomada posterior da conversa |
| Segurança da carga | Examinar a área, ouvir envolvidos e ajudar a reorganizar o trabalho após o atendimento | Porto fisicamente alterado e reação dos trabalhadores; responsabilidade de Leonor preservada |
| Pedido de uma família do cais | Descobrir o pedido por conversa, localizar pessoa/material e retornar | Relação local reconhecível, informação ou recompensa coerente |
| Serviço de um artesão | Entender a necessidade, executar trabalho com contexto e usar/comparar equipamento | Acesso compreensível a equipamento ou serviço, com escolha econômica |
| Aprendizado no pátio | Pedir demonstração, experimentar técnicas, interromper, trocar manejo e repetir | Comparação real de armas, sons e estilos, sem prender o jogador |
| Preparativos da Botafogo | Ouvir tripulantes, reconhecer equipamento e resolver uma necessidade prática | Familiaridade com a tripulação e introdução gradual das funções de bordo |

Os pedidos não devem convergir todos em carregar um caixote. Alternar conversa/informação, observação, coordenação, escolha econômica, exploração e aplicação de habilidades. Cada núcleo precisa de descoberta, execução, retorno e estado posterior.

## Requisitos do pátio

1. Antes de começar, apresentar o objetivo e o manejo emprestado/equipado.
2. Oferecer saída imediata e compreensível do exercício, inclusive durante o treino; interromper a ação em curso de modo consistente e devolver controle no pátio.
3. Permitir trocar de arma e experimentar outra sem repetir a introdução completa.
4. Oferecer repertório suficiente para revelar qualidades e limitações: alcance/linha, preparação, proteção, impacto ou mobilidade, conforme as regras do manejo.
5. Usar sons próprios de preparação, execução e impacto onde fizerem diferença perceptível; não basta variar a imagem do ícone.
6. Explicar claramente o que foi apenas demonstrado, o que foi aprendido e o que pode ser equipado.
7. Conservar apenas resultados válidos; sair não duplica recompensa nem concede aprovação de aula incompleta.
8. Definir recursos e recuperação depois desse fluxo, sem reintroduzir o item 24 como obrigação de desgaste.

Essa saída livre é requisito dos treinos. Não estendê-la automaticamente à fuga do duelo narrativo ou de toda batalha da campanha.

## Olhos e arte do protagonista

**Atualização de 17/10:** o usuário confirmou um olho azul e outro verde e pediu para não executar esse trabalho agora. O ponto foi retirado do fechamento atual; não está declarado corrigido ou validado. A descrição abaixo é o diagnóstico anterior, não uma autorização para inferir cores.

O código atual usa `eye_glow` e desenha um pequeno círculo temporário durante a manifestação. Isso não garante que o design dos olhos esteja presente e legível nos sprites. Verificar a fonte canônica e aplicar o detalhe correspondente no herói criança/adulto, poses narrativas, retratos que existirem e arte de combate, com posição correta para cada orientação. O personagem deve ser reconhecível sem depender de acender um efeito no socorro. Não presumir heterocromia ou uma segunda cor sem fonte.

## Próxima ordem de produção

1. Reconciliar o corpus e os opcionais; desenhar o percurso com intervalos de exploração e NPCs utilizáveis.
2. Implementar um ciclo completo de conversa → pedido → execução → consequência → save, usando um núcleo local representativo.
3. Expandir esse ciclo para os pontos do arco que hoje estão vazios ou desconectados.
4. Refazer socorro, demonstração, recuperação e arte dos olhos em paralelo ao conteúdo da cena, sem tratar encenação como uma camada opcional.
5. Reformular o pátio com saída livre, troca de armas, repertório e sons.
6. Consolidar ouro, economia pessoal/fundos de bordo, embarque e continuidade dos recursos.
7. Integrar os demais ajustes aceitos de interface, acessibilidade e navegação; validar o arco completo com jogadores.

Não há estimativa de horas ou promessa de quantidade final de missões neste documento. A definição de conteúdo deve atender às lacunas identificadas e ao corpus já existente.
