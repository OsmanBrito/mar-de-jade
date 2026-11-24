# Lisboa — percurso a pé entre os acontecimentos

**Atualização:** a [integração da Lisboa atual de Ferro](lisboa-ferro-integracao.md) substitui as antigas passagens entre praça e cais por um exterior contínuo e acrescenta exploração infantil. Abaixo permanece o registro da etapa anterior; sua contagem de verificações e sua organização em áreas descrevem aquela implementação.

18/10/2026. O percurso adulto de Lisboa passou a ligar o abrigo, a praça/pátio, o cais/mercado e o convés por passagens no cenário. O jogador aproxima-se e usa **E / A** para atravessar a entrada ou iniciar o encontro. Encerrar uma conversa que exige mudança de lugar devolve o controle, com o destino indicado em vez de carregar automaticamente a cena seguinte.

## Percurso

| Momento | O que passa a ser jogável |
|---|---|
| Entrega adulta | Receber controle ainda no abrigo; sair para a praça, descer ao cais e entregar os sacos à cozinha. A sacola acompanha o personagem. |
| Volta ao treino | Regressar pela praça e falar com Duarte no pátio. É possível entrar novamente no abrigo sem iniciar o treino por engano. |
| Acidente | Depois do exercício e da correia, caminhar ao cais e aproximar-se do trabalhador para iniciar o socorro. |
| Buscar Tomé | Sair do cais, passar pela praça e procurá-lo no abrigo. Conversar com ele inicia a volta com sua presença no percurso; o atendimento não começa à distância. |
| Refeição | Após concluir o socorro, explorar os moradores e pedidos, ir à cozinha e buscar as porções. O objetivo continua sendo a refeição, sem antecipar o embarque. |
| Manhã seguinte | Regressar ao abrigo e escolher descansar. Chegar ao local permite adiar o descanso e continuar explorando. A manhã começa no abrigo; o jogador vai à demonstração na praça. |
| Avaliação reservada | Após a demonstração, ir até o banco de Leonor. Ela desloca-se ao banco e o protagonista aproxima-se para sentar quando o jogador inicia o encontro. |
| Recuperação e prática | O retorno assistido após a derrota conserva a encenação de cuidado. Depois de recuperar, sair do abrigo e procurar Tomé no pátio para escolher o manejo. |
| Preparativos | Depois da Defesa Perfeita, voltar ao abrigo para a conversa e a sacola. Em seguida, percorrer a cidade até o pontão da Botafogo. |
| Embarque | Conferir os assuntos pendentes com Duarte, subir pela prancha e caminhar até Rodrigo. Antes de falar com o capitão, ainda é possível descer ao mesmo pontão. |

Conversas consecutivas de um mesmo encontro continuam juntas. A derrota e a primeira fala posterior permanecem ligadas, assim como as ações em que o protagonista precisa de auxílio. A passagem da infância para a idade adulta e as passagens de tempo continuam sendo marcos narrativos; esta mudança reorganiza a circulação adulta em Lisboa.

## Exploração e orientação

Os mapas existentes formam áreas conectadas por entradas físicas: abrigo ↔ praça/pátio ↔ cais/mercado ↔ convés. As aberturas da praça receberam piso caminhável e interrupções visíveis na mureta. As posições de chegada correspondem à passagem utilizada; sair do convés devolve o jogador a uma posição livre junto à prancha.

O cabeçalho informa o lugar e o compromisso atual. A indicação de interação muda conforme a entrada, pessoa ou serviço mais próximo. **J / menu → Pedidos** consulta o destino e conserva os pedidos locais. Conversas com os moradores e comércio permanecem disponíveis nos intervalos seguros do cais. Durante a busca urgente por tratamento, o objetivo é procurar Tomé e regressar ao paciente.

Sair de uma loja ou conversa local devolve o controle no mesmo lugar. Visitar outra área não inicia uma etapa futura. As cenas são iniciadas ao chegar ao encontro correspondente e interagir; apenas abrir o menu ou avançar o texto não substitui o deslocamento.

## Salvamento

O capítulo conserva um campo opcional `journey`, com tipo do percurso, compromisso, área, posição e ponto de retomada. A validação verifica também sua coerência com a etapa da história antes de alterar o estado atual. Saves anteriores sem esse campo continuam aceitos, incluindo a pausa antiga do cais, que agora oferece o percurso a pé.

Guardar durante um percurso ou entrar no menu registra a localização e o compromisso. A entrada e o Sistema explicam essa retomada. Falas e combates em andamento continuam usando o checkpoint de início da etapa. Um destino forjado ou um ponto de retomada incompatível é recusado; o arquivo não pode ser usado para saltar diretamente ao final do capítulo.

## Validação

Os ensaios usam caminhada, navegação e colisões reais. O percurso completo percorreu os 17 blocos adultos e os sete tipos de encontro até a partida. Foram verificados entrega e retorno, desvio pelo abrigo, busca de Tomé com ida e volta, descanso adiado/confirmado, salvamento no caminho, compatibilidade com saves antigos, compra por teclado/controle e retorno do navio ao pontão. As 250 falas aprovadas dos blocos adultos continuam iguais ao documento de Portugal.

Resultados confirmados nesta passagem: `chapter_full.gd` — 80 verificações; `lisbon_walk.gd` — 62; `harbor_visit.gd` — 39; `chapter_staging.gd` — 49; `arc_revision.gd` — 59; `chapter_routes.gd` — 15; `lisbon_requests.gd` — 85. São **389 verificações em sete ensaios**, todos terminados sem falhas. A quantidade maior de deslocamentos ainda requer avaliação humana de ritmo; a automação comprova funcionamento, não interesse ou duração percebida.

As capturas temporárias foram usadas para inspecionar o abrigo, as aberturas da praça e a chegada ao cais. Não são novos assets do jogo e não precisam permanecer no projeto. Capturas do teste de percurso só são produzidas com `--capture` e ficam em `.qa-runtime/`.

Arquivos principais: [rotas e encontros](../scripts/chapter/lisbon_routes.gd), [entradas dos lugares](../data/chapter_01/lisbon_routes.json), [fluxo do capítulo](../scripts/chapter/chapter_flow.gd), [validação do percurso salvo](../scripts/chapter/lisbon_journey_state.gd) e [teste de caminhada](../tests/lisbon_walk.gd).
