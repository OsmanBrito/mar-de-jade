# Infância e vínculo com Leonor — melhorias do ponto 6

Implementado em 19/10/2026. A passagem técnica está validada; **a meta de 30–45 minutos e a avaliação emocional ainda dependem de uma partida com leitura e exploração naturais**. Os testes abaixo não substituem essa avaliação.

## História e liberdade

Mantém-se a sequência acolhimento → exploração da praça/convento → treino → procura do corço → retorno → promessa → 19 anos. A ajuda da casa e as descobertas continuam opcionais antes de procurar Leonor; não foi acrescentada uma tarefa obrigatória para alongar a duração.

Na floresta, as pistas ganham leitura mais clara: cascos estreitos entre marcas de carroça, sinais junto da árvore, patas largas perto da água e cascos em direção à clareira alta. O caderno explica o que observar na etapa atual. A decisão de deixar sinais também produz uma pedra e um ramo visíveis nas curvas do caminho.

Ao retomar um save, a fala usa o contexto da etapa; já não repete o convite inicial da aventura depois de a procura ter avançado.

## Separação e responsabilidade

A saída de Leonor retoma o acordo escolhido: seguir juntos ou deixar sinais. O herói lembra o combinado; ela subestima a distância da subida. A separação continua sendo um erro dela, reconhecido na conversa posterior.

Leonor percorre um trecho real pela navegação, entre as raízes, antes de desaparecer. O jogador recupera o controle sozinho depois desse movimento. Não há nova etapa incompatível no save: uma retomada nesse momento volta ao trecho em que o herói está sozinho.

Depois do urso, o diálogo reconhece o erro sem diminuir a vitória do herói sobre o lobo. A fala posterior distingue a falta de comunicação de simplesmente deixar um sinal no chão.

## Lobo, troca de controle e urso

Foi preservado o equilíbrio existente. O lobo tem combate real e pode matar o herói; não usa imortalidade de treino. As simulações usam ataque básico, resolução real dos turnos inimigos e guarda orientada para o adversário:

| Política simulada | Turnos do herói | Vida final | Resultado |
|---|---:|---:|---|
| Timing falhado no ataque e na defesa | 4 | 65 | Vitória |
| Timing simples | 3 | 100 | Vitória |
| Timing de qualidade superior | 3 | 100 | Vitória |
| Dois turnos iniciais sem atacar, depois timings falhados | 6 | 35 | Vitória |

Esses percursos demonstram margem para erros mecânicos. Ainda é necessário observar jogadores iniciantes para avaliar a compreensão das ações.

A apresentação do lobo identifica o protagonista controlado e as funções de **Golpe firme**, **Respirar** e da guarda no fim do turno. A mensagem de nova tentativa explica que um timing falhado não impede um golpe.

Na entrada do urso, a apresentação reforça **Agora controlas Leonor criança** e esclarece que as técnicas são dela. Mantêm-se suas oito ações e o domínio que permite superar o urso com facilidade, inclusive com as técnicas lendárias e supremas. Não há desbloqueio antecipado, recompensa ou alteração dos recursos adultos do herói.

A posição de Leonor ao aparecer é escolhida em terreno livre e acessível, evitando deixá-la dentro de árvores ou inacessível para conversar.

## Retorno e promessa

Depois do encontro com o corço, há duas formas de regressar:

- Continuar a explorar e caminhar por todo o mapa, com acesso às descobertas restantes.
- Falar com Leonor e escolher **Regressar juntos pelo caminho conhecido**.

O regresso acompanhado abrevia o deslocamento repetido, recorda a ponte e os sinais escolhidos e conserva a conversa de encerramento. Não termina a aventura sem essa conversa. A alternativa de exploração continua levando ao mesmo desfecho, sem penalização.

Na caminhada livre, o indicador aponta primeiro para a ponte enquanto o jogador ainda está do lado oposto do rio, em vez de apontar diretamente para Lisboa através da água.

Quando a aventura foi concluída, três falas de transição ligam o retorno à promessa: a vitória sobre o lobo, a dimensão do urso e a responsabilidade de Leonor. As quatorze falas aprovadas da promessa permanecem intactas. Saves sem a aventura não recebem essa lembrança artificialmente.

A conferência visual também corrigiu a fachada em primeiro plano que atravessava o banco. Nas conversas enquadradas da praça, os objetos que cobrem um dos dois interlocutores desaparecem gradualmente; na exploração normal mantém-se a transparência parcial anterior. Os dois personagens e o banco ficam legíveis.

## Medir a duração sem confundir teste e partida

Foi acrescentado um medidor **local e opcional**, desligado na execução normal. Para iniciar pelo lançador oficial com a medição:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\start-godot.ps1 -MeasureChildhood
```

Começa uma campanha nova e joga a infância com leitura natural. Pausa quando interromperes a sessão. O relatório é gravado em:

`%APPDATA%\Mar de Jade\childhood-pacing.json`

O tempo usa o relógio real, conta leitura de falas, exploração, combate e leitura do caderno; exclui a pausa e as opções. Separa acolhimento, praça, treino, floresta e promessa, e para ao chegar à fase adulta.

O relatório informa etapas ausentes. Retomar a partir da floresta, por exemplo, não é registrado como uma medição da infância completa. Mesmo com todas as etapas, o arquivo não declara aprovação humana automática. A amostra curta do teste verifica o funcionamento do medidor e não é apresentada como duração da campanha.

## Validação

| Suíte | Verificações aprovadas |
|---|---:|
| childhood_bond | 49 |
| childhood_timing, com medição habilitada | 7 |
| forest_hunt | 67 |
| childhood_controls | 41 |
| promise | 25 |
| childhood_city | 13 |
| training | 34 |
| opening_presentation | 29 |
| map_art_closure | 90 |
| **Total: 9 suítes** | **355** |

A suíte nova verifica separação visível, acordo selecionado, combate real com margem para falhas, bloqueio de escolhas fora de hora, duas formas de retorno, terreno de chegada, save durante o retorno e ligação real à promessa. O medidor foi testado com a flag de lançamento, pausa real, leitura do caderno e transição para o adulto.

As regressões verificam o percurso integral a pé, os dois combates e as oito ações de Leonor, os controles compartilhados, as falas aprovadas, a liberdade inicial, os acessos e o acabamento. Registros sem erros de script. Capturas nativas conferidas em 1440×900 ficam em `.qa-runtime/childhood-close/captures/`.

**Ainda por validar com jogadores:** duração de 30–45 minutos, compreensão espontânea da troca de controle, dificuldade percebida por iniciantes e força emocional da promessa. Não foi adicionada espera artificial para atingir a meta.

**Continuação implementada:** [ponto 7 — arco adulto e encenação](arco-adulto-encenacao-ponto-07.md).
