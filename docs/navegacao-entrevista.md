# Navegação marítima — entrevista de implementação

Data: 15/10/2026. Direção da primeira versão definida após a entrevista. Este registro distingue respostas, propostas e detalhes de implementação ainda ajustáveis. Resumo consolidado em `navegacao-primeira-versao.md`.

## Objetivo e decisões atuais

- O usuário quer navegar pelo mar como parte do trabalho atual de fechamento de Portugal, além do embarque já implementado.
- Exploração livre, com um destino normal da missão para orientar a progressão.
- Referências iniciais: Assassin's Creed IV: Black Flag para a experiência de navegar; Europa Universalis V para revelação e conhecimento que facilitam ou abrem rotas. Sea of Stars foi acrescentado como referência de simplicidade.
- Aprovada a combinação proposta: navio visto de cima, levemente inclinado, controle simples e dificuldade concentrada na escolha dos caminhos e preparação da viagem.
- A proposta aceita inclui direção direta, curvas suaves e leve sensação de peso, tripulação cuidando das velas e vento influenciando velocidade/caminhos. Valores e controles exatos não foram definidos.
- O jogador controla a embarcação; o protagonista continua aprendiz na história. A resposta inicial sobre esse papel foi apenas "sim"; o enquadramento de condução supervisionada foi explicitado na proposta seguinte e não recebeu objeção. Cenas específicas ainda não foram aprovadas.
- Há limites reais de capacidade de navegação. Insistir em travessia além da capacidade pode destruir o navio e matar a tripulação. A proposta aprovada apresenta sinais e alertas antes da consequência fatal, com oportunidade de recuo.
- A morte resulta em game over e retorno ao último salvamento seguro anterior à situação fatal. Não foi aprovada perda permanente de personagens na campanha.
- Cartas e informações, pilotos e melhorias do navio devem contribuir em conjunto para ampliar o alcance.
- O jogador também pode descobrir rotas por conta própria, mas o usuário quer que seja bem difícil. Fórmula, exigências e critérios de descoberta continuam abertos.
- Descobertas desejadas: ilhas, portos e náufragos, com interesse amplo por encontrar coisas no mar. Não há lista de locais, quantidade ou conteúdos aprovada.
- Navios aparecem durante a navegação, aproximam-se e o contato inicia o encontro. Modelo de batalha, identificação de hostis e perseguição foram definidos nas rodadas seguintes; fuga após início do combate ainda exige regra de implementação.
- Aprovada a proposta de mercantes/aliados seguindo rotas, hostis patrulhando e perseguindo ao detectar o jogador e possibilidade de evitar alguns encontros por observação/manobra. Contato com amigável abre interação. Fuga após a batalha começar ainda não foi definida.
- O usuário pediu bosses no mar, com Black Flag como referência. Quantidade, tipos, posição, recompensas e regras de encontro continuam abertos.
- Aprovada a mistura de lugares maiores com desembarque/exploração pelo grupo e descobertas menores resolvidas a bordo, como náufragos, destroços e pescadores.
- O usuário sugeriu navegar saindo de Lisboa em direção à Madeira para o primeiro trecho e depois aprovou Madeira como escala explorável antes de Duas Águas. Localização dos opcionais e cenas específicas ainda não foram escritas.
- Sobre o tipo de batalha, o usuário primeiro pediu recomendação; a escolha da rodada posterior está registrada abaixo.

## Rodada seguinte — decisões de combate, ritmo e preparação

- Após a comparação de opções, o usuário aceitou a recomendação de navegação simples no mapa, batalha naval curta em tempo real e abordagem tática por turnos quando fizer sentido.
- A proposta aceita usa contato no mapa para iniciar um encontro em uma área de batalha com os navios posicionados para lutar. O jogador conduz e ordena disparos; a tripulação mira. Escolher o momento e posicionar o lado dos canhões são as decisões centrais.
- Abordagem é escolha ou exigência de encontros específicos após incapacitar o adversário; nem todo navio exige duas batalhas.
- Bosses opcionais com comportamentos próprios foram propostos, incluindo abalroamento, resistência com posição vulnerável e dupla de navios. O usuário aceitou o modelo geral; esses exemplos ainda não constituem catálogo aprovado nem quantidade exigida para o primeiro trecho.
- Lisboa–Madeira tem meta inicial de aproximadamente dez minutos, com coisas para fazer no caminho. O usuário enfatizou atividades durante a viagem; não interpretar como dez minutos de deslocamento vazio antes de conteúdo. Duração de desvios e encontros será avaliada em jogo.
- O usuário aceitou acompanhar suprimentos e estado do navio e usar portos para abastecimento/reparos, com intensidade leve: "sim mas n muito, n quero travar a exploração".
- Custos e manutenção devem permitir desvios e descobertas, sem exigir retornos constantes ao porto. Regras numéricas, avisos e consequências de esgotamento não estão aprovados.

## Rodada final — convés, chegada e acessibilidade do combate

- Aprovado poder parar a navegação e caminhar pelo convés: conversar com Duarte/tripulação, consultar informações e cuidar da preparação; retomar devolve o controle do barco no mapa.
- Aprovado desembarcar em um porto pequeno na Madeira, explorar, negociar e obter informações para seguir rumo a Duas Águas. Madeira funciona como primeira escala e oportunidade de descobrir rotas.
- Aprovado combate naval em tempo real de ritmo moderado, ataques inimigos sinalizados e pausa para escolher ordens. Manobras e oportunidades continuam importantes; bosses têm padrões aprendíveis.
- Propostas para conciliar preparação leve com exploração: reservas para objetivo e alguns desvios, consumo por deslocamento, ausência de consumo ao consultar carta/conversar/organizar grupo, reposição em portos/comércio/descobertas e avisos de retorno. Foram apresentadas, mas a última resposta do usuário aprovou explicitamente as três perguntas sobre convés, Madeira e combate; não registrar cada regra de recursos como aprovação separada.

## Propostas ainda abertas

- Separar conhecimento de uma rota da capacidade física de enfrentá-la: cartas melhoram informação; navio/tripulação/provisões determinam viabilidade.
- Três situações de navegação sugeridas: águas conhecidas, fronteira explorável e travessia além da capacidade. A combinação geral foi aceita; fronteiras e apresentação não foram detalhadas.
- Descoberta própria pode resultar de observação, pistas e boa preparação, em vez de sorte sem informação. Critério proposto para a primeira implementação, a validar em jogo.
- Precisão do marcador do navio, apresentação da carta e interface não foram escolhidas nesta entrevista.
- Além da meta de cerca de dez minutos com atividades para Lisboa–Madeira, não há aprovação de durações, distâncias, custos, consumo de recursos, balanceamento ou quantidade de encontros.

## Continuidade consultada

- Roteiro local aprovado: `docs/narrativa/C01-portugal-aprovado.md`. Portugal termina na partida da Botafogo como aprendiz sob Rodrigo. O destino anunciado é Duas Águas, na missão de busca de uma caravela desaparecida.
- Primeiro espaço marítimo: Lisboa–Madeira. A escala antes de Duas Águas foi aprovada nesta entrevista; cenas, diálogos e ligação técnica com C01/C02 ainda serão implementados.
- Corpus anterior, consultado apenas para leitura: `C:/Users/gamer/Documents/Codex/2026-10-12/c-users-gamer-documents-chatgpt-jogo-2/outputs/mar-de-jade/docs`.
- `design/navegacao-e-combate-naval.md`: direção anterior previa manobras/bordadas em tempo real e abordagem por turnos no convés. A entrevista conciliou esse modelo com contato no mapa iniciando área de batalha separada e acrescentou pausa para ordens.
- `design/exploracao-e-cartografia.md`: carta parcial com posição aproximada, rumo e marcos; estados relatado/avistado/explorado; grandes regiões e transições intercontinentais. Não exigir reaprovacão de decisões compatíveis; resolver somente o que a conversa atual reabriu ou alterou.
- `design/tripulacao-e-manutencao.md`: postos de piloto/artilheiro/cartógrafo/manutenção, suprimentos agregados, sem salários diários individuais; reparo emergencial com materiais e restauração completa em porto. Não tratar esses detalhes como novos requisitos aprovados nesta entrevista.
- `roteiro/roteiro-completo/C02.md`: abertura em Porto das Duas Águas/costa ocidental africana, treino naval e busca com destroços, sobreviventes e embarcação hostil. Não importar ou reescrever essas cenas automaticamente.

## Detalhes para implementar e validar

1. Controles e apresentação do encontro naval; modelo geral de batalha naval em tempo real seguida de abordagem contextual por turnos aceito.
2. Fuga após início de batalha e regras dos bosses; comportamento básico de hostis/neutros e desvio de encontros aceitos.
3. Conteúdo e recompensas das descobertas; mistura de desembarques e interações a bordo aceita.
4. Primeiro trecho Lisboa–Madeira: escala explorável aprovada; definir cenas e ligação com a continuação para Duas Águas.
5. Meta de cerca de dez minutos com atividades para Lisboa–Madeira aceita; detalhar consumo leve, reparos e sinais de limite fatal sem travar exploração.
6. Carta, progressão do conhecimento e critérios de descoberta própria difícil.
7. Salvamentos seguros e comportamento após vitória, derrota, fuga, resgate e retorno ao porto.

Esses detalhes podem receber parâmetros iniciais ajustáveis e ser avaliados no playtest. A entrevista não exige outra rodada de confirmação genérica antes de desenvolver a direção aceita; novas mudanças de escopo ou de narrativa devem permanecer identificáveis.

## Revisão após playtest: condução e câmera

O jogador relatou deriva excessiva, andamento lento e falta de clareza porque W conduzia para norte. Escolheu o leme relativo à proa (A/D), com W aumentando e S reduzindo a vela em níveis: parado, manobra, viagem e plena. O navio mantém o andamento quando W é solto. Pediu experimentar uma câmera atrás e acima, com horizonte visível; ainda não escolheu uma prioridade entre ilhas, navios, tempestades e costa à distância. [Implementação para o novo teste](navegacao-camera-e-leme.md).

## Referências pesquisadas

- Black Flag: https://www.ubisoft.com/en-us/game/assassins-creed/iv-black-flag
- Europa Universalis V, vídeo oficial Discovery: https://www.youtube.com/watch?v=eedDh0uiFx0
- Sailwind: https://store.steampowered.com/app/1764530/Sailwind/
- Horizon's Gate: https://store.steampowered.com/app/1224290/Horizons_Gate/
- Sea of Stars, navegação no mapa: https://www.arrpeegeez.com/2023/08/sea-of-stars-walkthrough-part-18-town.html
