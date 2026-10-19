# Circulação e atividades de Lisboa

**Fechamento dos pontos 2 e 3 — 19/10/2026:** planta, acessos, câmera, acabamento e poses consolidados. [Registro atual e 599 verificações aprovadas](fechamento-planta-arte-arco-01.md). As propostas e contagens abaixo são o histórico da etapa anterior.

Implementado em 18/10/2026 no projeto principal de Mar de Jade.

## Caminhos úteis

O exterior adulto tem duas ligações adicionais entre a parte alta e a Ribeira. A rua poente passa pelo estaleiro e chega ao pontão oeste; a rua nascente contorna a oficina e o armazém, aproximando o jogador da Botafogo. Ambas se ligam ao percurso central e permitem fazer uma volta pela cidade sem troca de cena.

Os caminhos têm piso contínuo, aberturas no limite da praça e placas de orientação. A infância conserva o recorte anterior, com cancelas nas novas saídas. O objetivo principal permanece ativo durante a exploração opcional.

## A maré e a amarra

O marinheiro do pontão poente oferece um quarto pedido local, `C01-LIS-04`. O jogador compara a marca de água no poste e a tensão da amarra. As duas observações podem ser feitas em qualquer ordem, inclusive antes de aceitar o pedido.

A decisão acontece na própria amarra. Dar folga e prender novamente conclui a atividade; encurtar ou cortar explica o problema e permite tentar outra vez. Não há ferramenta a buscar nem retorno obrigatório ao solicitante. A conclusão concede **6 de ouro uma única vez**, altera o cabo, afasta o batel e fica registrada no save e no diário.

## Conferência das entregas

O armazém tem um registro físico com os recibos de cinco caixas para a banca e duas para a cozinha. Conferi-lo oferece uma alternativa à sequência de consultas ao trabalhador e à vizinha em **A conta das entregas**. A explicação final à pescadora e a recompensa original de 8 de ouro permanecem.

Ler os recibos antes de aceitar o pedido também é reconhecido. As três observações novas podem ser relidas em **Pedidos → Lugares conhecidos · Ribeira de Lisboa**. Os objetivos indicam a alternativa do armazém.

## Continuidade

Os quatro pedidos podem coexistir. O carregamento valida seus estados e conserva observações, recompensas e consequências visuais. A retomada de uma exploração no cais deixou de encaminhar indevidamente o jogador ao refeitório por causa de um alias antigo de mapa.

As interações continuam exigindo aproximação física; objetos usam a indicação de examinar e o marinheiro usa a de conversar. As atividades são opcionais e não concluem a refeição ou antecipam o embarque.

## Validação

- `lisbon_circulation.gd`: 57 verificações, incluindo caminhada física pelas duas ruas, observação antes da aceitação, erro e acerto, recompensa única, recibos, diário, save/reload e limites infantis; executado também com renderização OpenGL.
- `lisbon_requests.gd`: 85 verificações dos pedidos anteriores. A asserção de moradores agora verifica os quatro originais sem proibir novos interlocutores; a entrada no refeitório verifica a persistência do pedido, sem exigir que o carro da rua exista dentro do convento.
- `lisbon_city_campaign.gd`: 24 verificações; nenhum recarregamento do exterior.
- `lisbon_city.gd`: 20 verificações.
- `childhood_city.gd`: 13 verificações.
- `campaign_continuity.gd`: 34 verificações.
- `chapter_full.gd`: 62 verificações, com os 17 blocos restantes até a partida.

Total: **295 verificações**, sem falhas. Capturas locais de revisão em `.qa-runtime/circulation-preview/` e visão geral em `.qa-runtime/circulation-after.png`.

## Próximo ponto

**Atualização de 19/10/2026:** o acabamento dos ambientes foi implementado e validado. Ver [resultado e próximo ponto: ritmo e balanceamento](acabamento-visual-ambientes.md).

Acabamento visual e coesão entre Lisboa, convento e floresta: pavimentos, proporções, perspectiva, bordas dos caminhos e integração dos objetos. Depois, avaliar ritmo e balanceamento com uma passagem jogada completa.
