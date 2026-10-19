# Habitantes e cidade viva — fechamento do ponto 4

Implementado em 19/10/2026, sobre a planta e os acessos consolidados nos pontos 2 e 3.

## Atividades e presença

Os cinco interlocutores da Ribeira continuam nos pontos de serviço dos pedidos: oficial da oficina, trabalhador do pontão, pescadora, vizinha da cozinha e marinheiro do batel. Receberam ciclos leves de postura, orientação e objetos de trabalho: inspeção do eixo e da amarra, separação em recipiente de serviço e manuseio de louça. A pescadora usa o recipiente vazio, sem apresentar uma tigela de caldo como peixe.

Dois moradores percorrem caminhos públicos curtos: recados na Ribeira e circulação na praça. Usam a navegação e a física do mapa, com pausas nos extremos. Não têm camada sólida contra o jogador: a rotina não pode bloquear uma entrada ou uma encenação. A caminhada para quando o jogador perde o controle numa conversa ou cena.

A infância conserva a circulação da praça e a vida da casa; os cinco postos adultos e o recado da Ribeira ficam ausentes. A criança do abrigo e o irmão da portaria têm respostas posteriores ao primeiro encontro. A orientação infantil continua a apontar para Leonor e os acessos reais.

## Conversas e acontecimentos

A opção **Conversar sobre a cidade e o trabalho** aparece junto das opções dos pedidos para os cinco moradores. Há cinco apresentações, dez falas de trabalho e 25 reações específicas distribuídas por acidente, socorro concluído, demonstração de Leonor, partida e retorno a Lisboa.

A conversa social exige aproximação física e não aceita tarefas nem entrega recompensas. As falas dos pedidos continuam a distinguir oferta, andamento e reconhecimento posterior; suas orientações e escolhas permanecem disponíveis.

O primeiro encontro fica no save. Os assuntos sociais alternam durante a sessão por personagem e acontecimento: depois da reação ao evento, vêm duas falas diferentes do trabalho. Uma mudança de acontecimento permite uma reação nova. Recarregar mantém o conhecimento do morador e reabre os assuntos da conversa; não se conserva um histórico completo de assuntos sociais entre sessões.

A demonstração tem um registro explícito ao terminar. Saves anteriores usam também o avanço do capítulo para reconhecer que ela já aconteceu. A visita de retorno ao porto prevalece sobre a antiga preparação da partida, evitando despedidas fora de contexto.

O irmão da portaria comenta o acidente ainda sem resolução, o retorno do socorro, a demonstração, a partida e a volta à casa. Ao repetir a conversa, dá direções mais curtas. A responsável dos mantimentos orienta a criança a levar a caneca com cuidado; mantém-se a lembrança adulta da ajuda prestada na infância.

## Interrupção e retomada

Ao conversar, o morador suspende seus objetos e sua postura de trabalho e volta-se para o jogador. O relógio da rotina e os percursos param durante a cena. Ao devolver o controle, o serviço retoma no mesmo posto; não há reposicionamento periódico por teleporte.

As animações existentes do reparo do carro continuam responsáveis pelo deslocamento e pelo retorno do oficial enquanto a rotina está suspensa. A restauração do mapa cria uma única instância das rotinas, sem duplicar os dois moradores de passagem.

## Verificação

| Suíte | Verificações aprovadas |
|---|---:|
| city_life | 133 |
| lisbon_requests | 85 |
| house_life | 60 |
| chapter_full | 62 |
| childhood_city | 13 |
| integration_closure | 30 |
| opening_presentation | 29 |
| **Total: 7 suítes** | **412** |

A suíte nova verifica caminhada real, conversa por aproximação, resposta ao socorro nos cinco moradores, mudança de assunto, reações novas depois de acontecimentos, pausa e retomada, posições de serviço, ausência de recompensas sociais, save/load, idade e retorno ao porto. As regressões verificam os pedidos, o reparo, a vida da casa, a campanha completa e as integrações da viagem.

Capturas nativas das conversas foram conferidas em 1440×900: `.qa-runtime/city-life-close/captures/workshop.png` e `fisher.png`. Não há erros de script nos registros dessas suítes.

O ponto 4 está implementado e validado tecnicamente. A avaliação de naturalidade, repetição percebida e ritmo com jogadores continua no ponto 10.

**Continuação implementada:** [ponto 5 — pedidos, exploração e consequências](pedidos-exploracao-consequencias-arco-01.md).
