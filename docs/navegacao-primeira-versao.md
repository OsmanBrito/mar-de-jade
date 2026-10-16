# Navegação — primeira versão jogável

Direção definida na entrevista de 15/10/2026. Histórico e distinção entre respostas e propostas: `navegacao-entrevista.md`.

Primeira implementação disponível: [acesso, controles, conteúdo e validação](navegacao-jogavel.md). Os parâmetros abaixo deram origem ao trecho jogável; a descrição do comportamento entregue está nesse documento.

## Experiência pretendida

Sair de Lisboa na Botafogo, conduzir livremente em direção à Madeira, descobrir lugares e acontecimentos no mar e chegar a um porto explorável. Conhecer rotas e preparar a embarcação amplia o alcance, enquanto a manutenção leve permite investigar desvios.

O protagonista permanece aprendiz sob Rodrigo. O controle da embarcação pelo jogador não concede imediatamente o comando narrativo ao protagonista.

## Direção aprovada

| Parte | Comportamento |
|---|---|
| Apresentação | Navio inteiro em vista elevada levemente inclinada; escala de mapa regional, com inspiração na simplicidade de Sea of Stars. |
| Movimento | Controle direto, curvas suaves e leve peso; tripulação opera velas; vento influencia velocidade e caminhos. |
| Liberdade | Destino principal claro e possibilidade de desviar, investigar e retornar. |
| Primeiro percurso | Lisboa–Madeira, cerca de dez minutos com atividades pelo caminho; desvios maiores podem prolongar a viagem. |
| Descobertas | Ilhas, portos, náufragos e outros encontros; lugares maiores têm exploração pelo grupo, menores podem ser resolvidos a bordo. |
| Conhecimento | Cartas, relatos, pilotos e exploração própria ajudam a descobrir ou facilitar rotas. Descobrir sozinho deve ser difícil. |
| Capacidade | Navio, tripulação e provisões limitam travessias; alertas e oportunidade de recuar antes de condições fatais. |
| Falha | Navio e tripulação podem morrer; game over e retorno ao último salvamento seguro anterior à situação fatal. |
| Navios no mapa | Aliados/mercantes seguem rotas; hostis patrulham e perseguem ao detectar; manobra permite evitar alguns encontros. |
| Contato | Amigável abre interação; hostil inicia encontro naval em área própria. |
| Batalha naval | Tempo real moderado, manobra e ordens de disparo, mira assistida pela tripulação e pausa para escolher ordens. Ataques inimigos sinalizados. |
| Abordagem | Após incapacitar o adversário, combate tático por turnos no convés quando escolhido ou exigido pelo encontro. |
| Bosses | Encontros opcionais com padrões próprios aprendíveis. Exemplos e quantidade ainda ajustáveis. |
| Convés | Parar a navegação, caminhar, conversar com Duarte/tripulação, consultar informações e preparar; retomar retorna ao mapa. |
| Recursos | Suprimentos e condição do navio com abastecimento/reparo em portos, sem retornos constantes ou bloqueio da exploração. |
| Madeira | Porto pequeno para desembarcar, explorar, negociar e obter informações; primeira escala antes de Duas Águas. |

## Regras iniciais propostas para playtest

Estas são escolhas de implementação ajustáveis, não novas aprovações individuais do usuário.

1. Separar informação de capacidade: descobrir uma passagem melhora a carta, mas a travessia ainda exige preparo adequado.
2. Usar a direção cartográfica anterior compatível: carta parcial com rumo, marcos e posição aproximada; registros relatado/avistado/explorado. Lisboa já é conhecida.
3. Permitir descoberta própria por indícios observáveis e preparação. Evitar depender apenas de uma tentativa aleatória sem informação.
4. Dar reservas suficientes para a viagem principal e alguns desvios. Consumir por deslocamento, sem cobrar pelo tempo gasto em menus, carta e conversas.
5. Oferecer reposição em portos e oportunidades de comércio/descobertas. Manter reparos leves compatíveis com continuar a exploração.
6. Mostrar deterioração do risco com margem para recuar, inclusive antes de perder capacidade de retorno. O desconhecimento de um trecho, sozinho, não equivale automaticamente a morte.
7. Conservar checkpoint seguro anterior ao perigo. Definir salvamento de modo que carregar não repita uma situação fatal inevitável.
8. Evitar que retomar após convés, contato amigável ou batalha provoque imediatamente o mesmo encontro por sobreposição no mapa.
9. Usar um boss com padrão próprio para validar o sistema antes de definir um catálogo. Seus poderes, nome, localização e recompensas serão propostas de conteúdo identificadas.

## Sequência de implementação

1. Mapa marítimo Lisboa–Madeira: controle do barco, câmera, vento legível, carta parcial e pontos de descoberta.
2. Liberdade e limites: conhecimento de rotas, preparo, suprimentos leves, alertas, retorno e salvamento seguro.
3. Encontros: tráfego amigável/hostil, perseguição e contato, resgate e transição para batalha naval com pausa.
4. Combate: manobras, bordadas assistidas, sinalização, condição do adversário, abordagem no combate existente e boss opcional.
5. Continuidade: visita ao convés e retorno ao mapa, saída de Lisboa, chegada/porto explorável na Madeira e indicação de Duas Águas como continuação.
6. Playtest do percurso completo, com revisão da duração, intensidade da manutenção, liberdade de desvio e leitura dos perigos.

## Critérios de validação

- A saída da campanha leva a uma viagem controlável, com Madeira como objetivo e desvios reais disponíveis.
- A viagem oferece atividades durante o deslocamento e mantém ritmo próximo da meta, sem um trecho longo de oceano vazio obrigatório.
- O jogador descobre algo, decide investigar e ainda consegue cumprir a rota com os recursos iniciais de referência.
- Carta, pilotos e capacidade do navio têm efeitos distinguíveis sobre informação e alcance.
- Um perigo além da capacidade é reconhecível e permite recuo antes da falha; insistência pode levar a game over e retorno seguro.
- Navios amigáveis e hostis produzem respostas distintas; é possível evitar alguns hostis antes do contato.
- O combate naval permite pausa para ordens e comunica ataques; abordagem usa o combate por turnos e retorna ao estado marítimo correto.
- O boss exige reconhecer um padrão, além de possuir atributos maiores.
- Visitar o convés e voltar conserva a viagem; atracar na Madeira permite exploração e serviços.
- Salvamento/carregamento conserva os estados previstos sem prender a partida em falha inevitável ou contato repetido.

## Limites da definição

Ainda serão ajustados controles físicos, escala geográfica, custos, taxas de consumo, dano, recarga, tempo de perseguição, condições de fuga, conteúdos/recompensas e interface. Esses valores serão propostos e testados durante a implementação. A meta de dez minutos é referência inicial, não resultado medido.

O roteiro aprovado de Portugal e a abertura de Duas Águas continuam como referências de continuidade. A escala na Madeira foi aceita nesta entrevista; novas falas e cenas devem ser identificadas como conteúdo novo. Este documento não afirma que o sistema já está implementado.
