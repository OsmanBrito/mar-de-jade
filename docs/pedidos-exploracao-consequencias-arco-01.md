# Pedidos, exploração e consequências — fechamento do ponto 5

Implementado em 19/10/2026. O primeiro arco fica com **cinco linhas opcionais**: quatro pedidos da Ribeira e a ajuda da casa da Ordem, com estados por idade. Este fechamento não aumenta tarefas de transporte; consolida a variedade existente e acrescenta uma variante de observação para o adulto que já ajudou na infância.

## Conjunto de conteúdo do arco

| Pedido | Atividade e descoberta | Consequência |
|---|---|---|
| A roda presa | Conversa com o oficial, diagnóstico do eixo e reparo coordenado | Carro alinhado e deslocado, passagem livre, agradecimento, 12 de ouro e uma ração uma única vez |
| A conta das entregas | Conferir destinos por moradores ou pelos dois recibos no armazém | Cinco caixas na banca e duas na cozinha reconhecidas, registo visível e 8 de ouro uma única vez |
| Uma sacola preparada | Conferir água e ligadura com o trabalhador, depois da recuperação | Reserva permanece na sacola para uso real, orientação posterior e 3 de ouro uma única vez |
| A maré e a amarra | Observar água e cabo e escolher o ajuste no próprio pontão poente | Cabo com folga, batel afastado em segurança, reconhecimento e 6 de ouro uma única vez |
| A água da casa | Serviço infantil ou primeira ajuda adulta; conferência adulta se a ajuda infantil foi concluída | Água e preparação visíveis na enfermaria; confirmação dos responsáveis e memória entre idades, sem recompensa econômica |

Oficina, pescadora, trabalhador e marinheiro têm marcadores e conversas no próprio local de trabalho. A casa é descoberta junto da portaria e dos mantimentos. A alternativa dos recibos permite investigar por observação do ambiente sem refazer toda a sequência de entregas entre moradores.

Conclusões dos quatro pedidos da Ribeira agora mostram **✓** no interlocutor. Um pedido concluído não apaga o **!** de outra etapa ativa no mesmo trabalhador. Os efeitos anteriores no carro, no registo, no cabo, no batel e nos suprimentos foram preservados e novamente verificados.

## Variante adulta da casa

Se a ajuda infantil foi concluída e o pedido adulto ainda não começou, a responsável reconhece a experiência e propõe conferir a reserva da cisterna, as bacias e os panos da enfermaria. A criança continua com a entrega da caneca; o adulto experiente não repete esse transporte.

A conferência da cisterna fica salva. Na enfermaria, o ajudante confirma o serviço e assume o aviso à responsável: **não é preciso voltar ao adro para concluir**. O caderno explica a sequência e não mostra o adulto carregando uma caneca que apenas conferiu. A inspeção não toca o som de encher ou entregar água.

Pedidos adultos já iniciados em saves anteriores mantêm a entrega original. Não são convertidos silenciosamente a meio do caminho. A variante usa flags compatíveis com o salvamento existente.

## Escolhas da floresta retomadas

As seis alternativas das três escolhas ganham lembranças no diário compartilhado, em terra e a bordo. Só aparece a alternativa que foi efetivamente escolhida:

- seguir juntos ou deixar sinais;
- testar a ponte primeiro ou confiar nos passos de Leonor;
- observar o corço ou tentar aproximar-se.

A opção **Recordar a floresta com Leonor** aparece em conversas relacionadas: oficial da oficina, marinheiro do batel e pescadora. O protagonista conta a própria lembrança; o morador responde ligando-a à coordenação da carga, à comunicação na amarra ou à observação antes de cobrar uma entrega.

As lembranças não concedem bônus nem resolvem pedidos automaticamente. Não se inventam escolhas ausentes em saves antigos. São consequências narrativas e práticas das decisões, sem transformar uma alternativa em punição ou prêmio oculto.

## Disponibilidade e partida

A ajuda da infância pertence àquela idade. Se ficou incompleta, o diário compartilhado a identifica como lembrança por concluir, sem apresentá-la como tarefa do adulto nem bloquear o embarque.

A Ribeira abre depois do socorro; a reserva da sacola pode ser conferida depois da recuperação. O caderno indica os quatro postos onde procurar conversas. Os pedidos podem esperar durante a recuperação e não têm prazo enquanto se explora Lisboa.

A revisão de embarque lista por nome todos os pedidos adultos iniciados e incompletos, incluindo a casa. Explica que são opcionais e que, depois da partida, só podem ser continuados quando o jogador estiver de novo em Lisboa. Conserva **Continuar a explorar** como primeira escolha e não falha nem conclui tarefas automaticamente.

O diário a bordo preserva as lembranças e marca pedidos pendentes como atividades a retomar em terra, atracado em Lisboa. O progresso continua no estado da campanha usado no retorno ao porto.

Durante esta validação foi corrigida uma sobreposição no desembarque do convés: Duarte podia ser instalado sobre a posição de chegada do jogador. A folga do ponto de chegada agora é resolvida depois da instalação dos personagens e das colisões. O jogador consegue descer ao pontão e voltar a bordo antes de falar com Rodrigo.

## Validação

| Suíte | Verificações aprovadas |
|---|---:|
| optional_closure | 70 |
| lisbon_requests | 85 |
| house_life | 60 |
| integration_closure | 30 |
| lisbon_circulation | 57 |
| city_life | 133 |
| forest_hunt | 67 |
| chapter_full | 62 |
| harbor_visit | 39 |
| **Total: 9 suítes** | **603** |

A suíte nova cobre as seis lembranças, três conversas por aproximação real, variante adulta com save/load intermediário, conclusão sem retorno, preservação da entrega antiga, lista dos cinco pedidos no pontão, diário a bordo, memória infantil incompleta e prioridade dos marcadores. As regressões verificam recompensas únicas, consequências no cenário, infância, floresta, campanha, viagem e subida/descida do convés.

O teste antigo da visita ao cais foi atualizado para aceitar a ausência dos personagens que já saíram da história e usar a posição atual do pontão. Continua exigindo chão livre e uma caminhada completa de volta ao capitão.

Capturas nativas conferidas em 1440×900: `.qa-runtime/optional-close/captures/`, com as três retomadas da floresta, o diário e o embarque com cinco pendências. Registros sem erros de script.

**Continuação implementada:** [ponto 6 — infância e vínculo com Leonor](infancia-vinculo-leonor-arco-01.md). A percepção de variedade e repetição ainda será avaliada com jogadores no ponto 10.
