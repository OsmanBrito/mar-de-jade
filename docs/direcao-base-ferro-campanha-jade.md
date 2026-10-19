# Direção: base de Maré de Ferro, campanha de Mar de Jade

Última etapa implementada: [fechamento das integrações do primeiro arco](fechamento-integracoes-arco-01.md), incluindo retorno ao exterior de Lisboa, diário a bordo, identidades e catálogo executável do arco. Os registros de etapas abaixo conservam seus limites históricos.

Decisão do usuário em 18/10/2026: aproveitar os sistemas de jogo, itens, habilidades e demais recursos do projeto atual de Maré de Ferro para construir Mar de Jade, sem importar sua história ou roteiro. Preservar a navegação marítima, o roteiro e a amplitude de habilidades de Mar de Jade.

## Esclarecimento: reconstrução do jogo

Na entrevista de 18/10/2026, o usuário esclareceu que pretende **refazer Mar de Jade usando Maré de Ferro como base**, incluindo seus mapas. A integração não se limita a acrescentar itens e módulos ao fluxo atual de Jade.

- Começar por **Lisboa**, para receber o início da campanha de Jade.
- Aproveitar geografia, conexões, aparência e construções dos mapas atuais de Ferro, reorganizando-os quando necessário para o roteiro de Jade.
- Ampliar e melhorar esses mapas com o tratamento aplicado em Jade; a ampliação de mapa de Jade foi aprovada como direção.
- Preservar as animações e os habitantes de Jade, considerados satisfatórios. Aproveitar habitantes de Ferro seletivamente, conforme sua utilidade na nova campanha.
- A direção da experiência é exploração livre, com acontecimentos do roteiro acionados nos lugares correspondentes. O usuário quer rever o início em entrevista antes de fechar sua reorganização.

Na continuação da entrevista, o usuário escolheu exploração desde a infância numa área menor da mesma Lisboa, com pedidos de moradores, lojas e descobertas, e combates onde fizerem sentido. A organização entre exterior contínuo e bairros será decidida após avaliar uma [proposta de mapa](lisboa-reconstrucao-proposta.md). Escala e ritmo ainda serão fechados nessa revisão. O lote de equipamentos já integrado é uma preparação técnica, não a realização dessa reconstrução.

## Fontes e limites

Continuação aprovada em 18/10/2026: exterior contínuo em Lisboa e [presença explícita da Ordem de Cristo](ordem-cristo-integracao.md), com conjunto conventual de acolhimento ligado a Tomar, memória templária e vestuário de Duarte. As animações de Jade permanecem preservadas.

- Base de referência: `C:/Users/gamer/Documents/ChatGPT/jogo`, projeto atual, consultado sem alterações. Não usar material da beta.
- Destino: este repositório. A junction em Documents/ChatGPT aponta para ele; não criar outro projeto independente ali.
- História de Portugal: `docs/narrativa/C01-portugal-aprovado.md`. A adoção técnica não autoriza reescrever identidades, relações, cronologia ou revelações.
- A navegação em `scripts/navigation/` é um sistema a preservar e integrar, incluindo exploração marítima, estado do navio e abordagens. Não substituí-la pelas travessias mais restritas de Ferro.
- Catálogo narrativo, habilidade executável e apresentação final são estados diferentes. Não apresentar habilidades documentadas ou exercícios locais como implementação completa do catálogo.

## O que aproveitar

| Origem | Aproveitamento | Adaptação necessária |
| --- | --- | --- |
| Ferro: exploração, interação, câmera, moradores e ambientes | Base da experiência em terra e recursos de apresentação | Mapas e habitantes devem servir às missões de Jade; passeantes não substituem conteúdo interativo |
| Ferro: combate, IA, previsão, orientação, timing, efeitos e áudio | Preservar as capacidades existentes | Ampliar armas, personagens e condições de aprendizagem de Jade |
| Ferro: progressão, técnicas, passivas e domínio | Reutilizar regras e infraestrutura compatíveis | Remover a dependência fixa de Duarte/Inês e de suas famílias de armas |
| Ferro: itens, equipamento, bolsa, lojas e recuperação | Aproveitar funcionalidades, conteúdo compatível e apresentação | Rever requisitos, nomes, valores e distribuição; itens vinculados à trama precisam de adaptação |
| Ferro: diário, preparação, opções e salvamento | Reutilizar serviços de campanha | Campanha e saves próprios de Jade, sem flags ou desbloqueios da história de Ferro |
| Jade: roteiro, elenco e missões | Conteúdo narrativo da nova campanha | Converter acontecimentos em objetivos e consequências no mundo explorável |
| Jade: navegação marítima | Preservar a experiência aprovada | Ligar porto, embarque, tripulação, combate e retorno ao mesmo progresso |
| Jade: famílias de armas e catálogo amplo de habilidades | Preservar variedade e identidade | Implementar efeitos canônicos, balancear e produzir apresentação por família |

Reutilizar tudo que for compatível não significa liberar todos os itens e habilidades no início, nem conservar recompensas associadas a acontecimentos de outra história.

## Integrações verificadas e problemas a resolver

O `scripts/main.gd` do Ferro integra Progression, JourneyMenu, Missions, CampaignState, WorldLife, combate e navegação regional. Entretanto, ainda contém lógica específica da sua campanha. Não deve ser copiado como diretor de Jade sem separar essas responsabilidades.

O `scripts/progression.gd` do Ferro inicializa dois heróis, técnicas e armas próprias. É necessário tornar essa estrutura adequada ao protagonista nomeável e aos companheiros de Jade antes de adotá-la como progresso principal.

Jade já possui módulos de combate copiados de Ferro, mas seu inventário em `scripts/chapter/player_items.gd` e progresso de capítulo são próprios. A migração deve evitar duas economias pessoais ou duas fontes de equipamento. Recursos coletivos do navio continuam uma responsabilidade distinta, com transferências explícitas quando aplicáveis.

`scripts/combat/campaign_rules.gd` implementa um recorte introdutório de cinco manejos. Os exercícios `C01-DEMO-*` não são habilidades canônicas. O catálogo amplo precisa de auditoria individual de efeitos, requisitos e apresentação antes de ser declarado jogável.

## Ordem de execução

1. Inventariar dependências e recursos efetivamente usados pelo projeto atual de Ferro; classificar sistemas, conteúdo reutilizável e conteúdo vinculado à sua história.
2. Extrair/adaptar a base no destino, preservando o projeto original e o funcionamento atual de Jade durante a transição.
3. Definir uma única progressão pessoal, inventário, equipamento, aprendizagem e recompensas, com formato de save próprio e política explícita para saves antigos.
4. Adaptar personagens e famílias de armas; reunir os itens e técnicas compatíveis de Ferro com o catálogo de Jade, preservando a origem dos identificadores.
5. Integrar exploração, serviços, preparação e diário à campanha de Jade.
6. Converter o primeiro arco em missões no mundo, mantendo os acontecimentos aprovados e desenvolvendo as ligações jogáveis entre eles.
7. Integrar a navegação preservada a esse progresso, incluindo embarque, abordagens, consequências e retorno a terra.
8. Lapidar habilidades por família: comportamento, alcance, custos, animações, impacto, som e leitura dos efeitos. Compartilhar recursos quando apropriado, mantendo diferenças mecânicas perceptíveis.
9. Validar um percurso completo antes de migrar o restante: abrigo → exploração e missão → preparação → combate → recompensa e consequência → porto → navegação → salvar/carregar.

## Critérios de aceitação

- O jogador entende objetivo, motivo, destino e consequência sem depender de saltos entre cenas.
- Exploração e serviços têm utilidade; a missão principal não exige concluir todo conteúdo opcional.
- Equipamento, recursos e habilidades mantêm o mesmo estado em terra e nas abordagens.
- A navegação conserva o comportamento aprovado pelo usuário.
- A campanha não herda falas, parentescos, eventos ou desbloqueios narrativos de Ferro.
- Os testes verificam integridade e persistência; uma sessão jogada avalia clareza, ritmo e sensação de jogo.

Este documento registra a direção e os pontos de integração. Não declara a migração implementada nem o catálogo completo jogável.

## Execução iniciada

18/10/2026: [primeira etapa implementada](integracao-ferro-etapa-01.md), com levantamento da origem atual, oito equipamentos adaptados à economia de Jade e migração de saves. A progressão por personagem, os demais serviços e a sincronização completa com a viagem continuam pendentes.

Continuação: [primeiro percurso de Lisboa sobre Ferro implementado](lisboa-ferro-integracao.md). Convento, praça e Ribeira compartilham o mesmo exterior; a infância explora uma área menor e o percurso adulto mantém entrega, treino, socorro e continuação do arco. O documento registra origem, limites, migração de saves e verificações.

Etapa seguinte: [convento explorável](convento-exploravel.md), com claustro, capela, enfermaria, cinco descobertas e acesso nas duas idades. As visitas preservam o compromisso da campanha e a localização salva.

Refinamento solicitado: [remodelação de Lisboa e do convento](remodelacao-lisboa-convento.md), com acabamento arquitetônico, materiais próprios, câmera, orientação e controle por clique. A campanha e suas recompensas continuam preservadas.
