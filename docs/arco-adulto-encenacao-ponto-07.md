# Arco adulto e encenação — melhorias do ponto 7

Implementado em 19/10/2026. A validação técnica foi concluída; a compreensão espontânea, a duração percebida e o efeito emocional das cenas ainda requerem jogadores que desconheçam o roteiro.

## Entrega, acidente e socorro

A sequência conserva a entrega da farinha seca à cozinha, o regresso ao compromisso com Duarte e o aviso da amarra rompida. A chegada ao acidente apresenta o trabalhador preso pela madeira antes da ação do jogador.

O socorro continua com duas ações físicas: assentar a alavanca e aproximar-se de Duarte para confirmar a elevação conjunta. O caderno agora acompanha o subpasso real; depois de assentar o apoio já não manda repetir essa etapa. O mesmo tratamento foi aplicado às duas etapas da refeição, da caminhada de recuperação e da amarra azul.

A manifestação no ferimento permanece uma percepção, sem fechar a ferida ou conceder tratamento. O registro desse acontecimento explica a necessidade de Tomé, pano e água limpa. Tomé agora aplica visualmente um pano com a arte existente, mantendo o ferido marcado como lesionado.

A saída do ferido passou a mostrar o familiar caminhando ao lado dele, com enquadramento do grupo e aviso da saída acompanhada. Os dois saem de cena antes das consequências sociais; o trabalhador não reaparece como se o atendimento ainda estivesse pendente.

## Refeitório e conversa

A refeição continua na cozinha e no refeitório existentes do convento. Foram novamente verificados o recebimento e transporte das porções, o ato de sentar depois da entrega, os retratos adultos, a conversa, o gesto do pano e a saída da mesa antes da exploração.

As capturas foram conferidas no enquadramento atual. O teste também cobre a continuidade do mesmo mapa, a retomada por save e a interface em 960×600, 1440×900 e 1920×1080. O julgamento sobre a duração ideal das pausas e a naturalidade dos gestos permanece humano.

## Demonstração pública e avaliação reservada

Os cabeçalhos distinguem **Demonstração pública**, na manhã seguinte, e **Avaliação reservada**, no fim da tarde. Durante a demonstração, os avisos identificam o primeiro ataque do combatente, a tentativa do mestre, a recomposição da guarda e o desarme por Leonor.

Mantêm-se os seis espectadores, as duas tentativas do mestre e os dois instrumentos no chão. A avaliação junto do banco não herda a plateia. O objetivo no caderno diferencia assistir à demonstração de participar da avaliação.

**Mestre** permanece a identificação definitiva por função neste arco. O caderno o contextualiza como o mestre da praça; não foi acrescentado um nome próprio sem fundamento no roteiro.

O enquadramento adulto usa a ocultação dos objetos que cobrem os interlocutores, preservando a leitura dos dois personagens. Também foi corrigida uma reposição genérica que, ao abrir diretamente a cena do banco, sobrescrevia a posição sentada e deixava o herói fora do assento. O posicionamento da demonstração também conserva sua composição própria.

## Derrota, auxílio, recuperação e aprendizagem

A entrada no duelo identifica a avaliação reservada e o protagonista controlado. O resultado **LEONOR VENCEU** informa que a história continua com o auxílio de Duarte e Tomé e que a aprendizagem vem depois da recuperação.

O encerramento mantém a reação final e a transição para a próxima cena, em vez de oferecer a derrota como um reinício. Foi testado tanto o resultado por dano efetivo quanto o retorno do combate ao bloco seguinte.

No regresso assistido, os três personagens apresentam o deslocamento e encerram a caminhada ao terminar a ação. Água, cuidado, repouso, caminhada e aulas continuam separados: beber não remove a lesão, e a recuperação não concede técnicas automaticamente.

A validação da aprendizagem percorre o retorno ao pátio antes do teste de manejo e da aula. Permanecem os quatro modos do percurso atual: duelo, teste de manejo, escola e Defesa Perfeita. Não foram reintroduzidos os treinos obrigatórios iniciais de Duarte.

## Partida e releitura dos acontecimentos

O caderno passa a oferecer registros dos acontecimentos conhecidos, também consultáveis a bordo:

- entrega da farinha;
- apoio da carga e percepção no ferimento;
- conclusão do socorro;
- demonstração pública;
- resultado da avaliação;
- compromisso de dez anos, após a partida de Leonor;
- regresso acompanhado e recuperação;
- missão da Ordem e condição de aprendiz.

Cada registro depende de um marco já visto. Perder o duelo, por exemplo, não registra antecipadamente o compromisso de dez anos nem o auxílio ainda não ocorrido. As entradas são derivadas das flags existentes e continuam disponíveis após salvar e carregar.

A missão explicita o papel de Duarte, a apresentação ao capitão Rodrigo, a condição de aprendiz, Madeira como primeira escala para mantimentos e Duas Águas na busca da caravela. Antes de concluir o embarque, o registro conserva a condição de aceitação pelo capitão; depois da partida, descreve a condição efetivamente assumida.

## Validação

| Suíte | Verificações aprovadas |
|---|---:|
| adult_arc_closure | 37 |
| chapter_full | 62 |
| chapter_staging | 49 |
| integration_closure | 30 |
| adult_opening | 19 |
| arc_revision | 5 |
| player_feedback | 39 |
| combat_ending | 28 |
| **Total: 8 suítes** | **269** |

O validador de conteúdo confirmou **17 blocos e 249 falas aprovadas, sem divergências**. As melhorias usam instruções, encenação e registros para releitura; as falas canônicas permanecem preservadas.

O teste novo verifica subpassos, apoio e elevação por aproximação real, percepção sem cura, pano aplicado, familiar em movimento, distinção dos confrontos, posição no banco, identidade adulta de Leonor, encerramento da derrota, ausência de registros futuros, save/load e motivação da partida.

Capturas nativas conferidas ficam em `.qa-runtime/adult-arc-close/captures/`, `.qa-runtime/feedback-preview/` e `previews/staging-*.png`. Os registros das oito suítes não apresentam erros de script.

**Próximo ponto: 8 — combate, preparação e economia.** A aprovação de ritmo, emoção e compreensão por jogadores continua pendente no playtest.
