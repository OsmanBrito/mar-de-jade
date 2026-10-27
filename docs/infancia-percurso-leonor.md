# Da praça à primeira aventura com Leonor

Continuação do refinamento da abertura, autorizada depois da revisão do convento e das quatro direções de caminhada. O objetivo é ligar a convivência no banco, os exercícios e a procura do corço numa sequência com motivos claros para acompanhar Leonor.

## Encontro e treino

Leonor começa ocupada com os instrumentos junto do banco. Ao aproximar-se, a criança é notada e ela levanta-se. O encontro conserva as 27 falas aprovadas do banco e dos percursos, mas o início da conversa mantém a posição de chegada do protagonista. Os dois caminham para os lugares no banco; as mudanças para os exercícios também usam passos direcionais, com pausas respeitadas pelos movimentos encenados.

A praça usa o objetivo persistente e o aviso de interação em espaços separados. A fachada em primeiro plano revela também Leonor quando ela está próxima, permitindo enxergar a atividade antes de conversar. No fim do exercício, Leonor manda pegar na vara; a passagem para o treino usa a transição coberta existente.

Os exercícios mantêm as falas, o combate tático, os dois impactos no alvo, a guarda simples, a segurança e a restrição de Defesa Perfeita. Os instrumentos aparecem nas mãos, e Leonor faz um gesto curto ao orientar o aluno. A mão raspada leva a uma breve encenação junto de uma bacia: o herói pousa a vara, caminha até à água e agacha-se. Os elementos da bacia, banco, pano e instrumentos reutilizam os atlas já existentes.

Depois de lavar a mão, a conversa introduz a saída: Leonor quer verificar o relato do corço branco junto à ponte; o protagonista responde que vai com ela. A tela de conclusão genérica foi substituída por essa passagem falada. Os títulos e o objetivo no caderno acompanham o momento atual.

## Caminho partilhado

Quando o convite já foi feito no treino, a chegada à floresta entrega controle diretamente. A conversa inicial do trilho recorda o que combinaram e oferece as escolhas existentes sobre seguir juntos ou deixar sinais. Uma entrada antiga diretamente na floresta conserva uma introdução falada que explica a procura.

Leonor procura uma posição um pouco à frente ou ao lado da criança, próxima o suficiente para acompanhá-la. Cada posição e caminho respeita a navegação, incluindo a ponte. As quatro direções de movimento correspondem ao deslocamento real; trocar de etapa ou terminar uma conversa descarta o caminho anterior. Depois das primeiras pegadas, um comentário breve reconhece a observação do protagonista sem bloquear o movimento.

Os três recantos opcionais têm conversas curtas entre as crianças. Os mesmos identificadores, textos de registro e descobertas permanecem disponíveis no caderno. As conversas da floresta usam um enquadramento próximo dos dois, e a exploração recupera a câmera do jogador. O regresso encerra com uma fala de Leonor sobre devolver as varas e segue para a promessa pela transição coberta.

A vitória do protagonista contra o lobo, o controle de Leonor diante do urso, a diferença de força, o corço, o retorno e as falas aprovadas da promessa permanecem na sequência. Esta etapa não atribui um patamar à Leonor criança nem antecipa desbloqueios adultos.

## Caminhada e retomada

O protagonista usa os ciclos de oito fases já aprovados no convento também nos mapas 2D da praça e da floresta. A escala acompanha o atlas infantil; o ritmo vem da distância percorrida. Posturas de repouso, sentado, agachado e a apresentação dos olhos em brilho continuam no renderizador existente. O controlador infantil consome pontos de navegação próximos antes de escolher o próximo movimento, evitando uma pausa em cada casa da rota.

As flags aditivas `child_attack_practised`, `child_defense_practised` e `child_forest_invited` registram os limites entre as etapas. Retomar depois do primeiro exercício começa na guarda; depois do segundo, na passagem da mão e do convite; depois de ler o convite, na saída. Os saves passam pela validação de campanha existente e mantêm os recursos e as técnicas adultas. Os saves anteriores sem essas flags percorrem a sequência normalmente.

## Verificação

As suítes de percurso, treino, praça, floresta, controles, vínculo infantil, promessa, continuidade e nome cobrem as mudanças. O teste novo verifica a aproximação física, a revelação real da fachada, o passeio até ao banco, a pausa durante a encenação e a lavagem, as retomadas entre os exercícios, o motivo da saída no caderno, a chegada sem repetir a explicação, o acompanhamento de Leonor e os diálogos das descobertas.

Resultado: **355 verificações aprovadas em nove suítes** — percurso 36, treino 35, praça 42, floresta 67, controles 41, vínculo 49, promessa 25, continuidade 34 e nome 26. Foram conferidas as nove vistas nativas em 1440 × 900. A revisão também corrigiu a pose que ficava congelada num quadro de passada quando um ator parava de caminhar; nas conversas da floresta os dois orientam-se um para o outro.

```powershell
& tools/test_lisbon_direction.ps1 -Suites childhood_journey,training,plaza,forest_hunt,childhood_controls,childhood_bond,promise,campaign_continuity,name_entry
```

`tools/capture_childhood_journey.gd` gera nove vistas em `.qa-runtime/childhood-journey/`: espera, banco, dois percursos, treino, mão, convite, arredores e descoberta. O capturador usa avanço controlado dos eventos de conclusão do combate para chegar às encenações; os combates reais são exercitados separadamente pelas suítes de treino e floresta. As imagens não representam uma medição humana de ritmo ou duração.

Os mapas da praça e da floresta continuam sendo os cenários existentes da campanha. O critério principal desta etapa é jogar do convento até à floresta e perceber uma razão para procurar, treinar e continuar com Leonor.
