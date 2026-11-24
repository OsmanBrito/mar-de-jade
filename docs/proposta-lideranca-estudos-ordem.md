# Liderança, missões e estudos da Ordem — proposta

Continuação aprovada e implementada: [liderança e estudos no jogo](lideranca-e-estudos-ordem.md). O texto abaixo preserva a proposta discutida antes da implementação.

Análise de 20/10/2026. Proposta para discussão; não implementa NPC, missões, vendas ou mudança nos requisitos do catálogo.

## Diagnóstico

A casa possui serviços cotidianos e uma armaria, mas falta uma liderança com autoridade narrativa, uma cadeia de missões institucionais e uma forma de adquirir estudos. O estudo atual abre os menus de conhecimento e repertório; não vende nem ensina novas técnicas. O instrutor abre a prática livre; essa prática não concede aprendizado.

A entrevista aprovada admite aprendizado por mestres, manuais e missões. O anexo vigente `habilidades-passivas-v2/ensino-e-progressao.md` prevê estudos autorizados, estoque finito, manuais comprados e retorno aos registros de Tomé. Técnicas essenciais permanecem gratuitas. Manual não concede patamar de cultivo, nível ou domínio automático.

## Liderança proposta

Incluir o Grão-Mestre como personagem importante, com apresentação formal por Duarte, opinião própria sobre o serviço da Ordem e participação na preparação da viagem. O protagonista é reconhecido como aprendiz ligado à casa; não recebe posto de cavaleiro por realizar tarefas domésticas.

Uma Sala do Capítulo, acessível pelo corredor da secretaria, reúne mesa de conselho, cadeira da liderança, mapa das rotas, cartas seladas e estandarte. A sala tem audiência, relato de serviço e decisões. Um mestre da casa ou comendador mantém os compromissos disponíveis quando o Grão-Mestre se ausenta. Identidade, nome e relação entre esses cargos são propostas novas a definir na escrita.

Há uma decisão de mundo relevante: na história portuguesa o governo da Ordem se ligou à Coroa, e D. Manuel I foi rei e Grão-Mestre ([fonte oficial](https://www.ordens.presidencia.pt/?idc=120&idi=4970)). Jade já estabelece Portugal fantástico, rei próprio e casa fictícia. Recomenda-se um Grão-Mestre ficcional com relação explícita com a Coroa, preservando o conflito político futuro do roteiro. A alternativa mais próxima da referência histórica é ter o rei no topo e um mestre/comendador residente comandando a casa. Essa escolha não deve ser fixada silenciosamente.

## Missões propostas

| Etapa | Ação e diferença em relação às tarefas atuais | Consequência |
| --- | --- | --- |
| O nome no livro | Duarte apresenta o aprendiz; a liderança recebe o relato do primeiro serviço já realizado. Sem repetir a entrega da enfermaria | Reconhecimento e autorização para consultar estudos |
| A carga da Ordem | Investigar uma divergência nos mantimentos da Ribeira: comparar o registro da casa com o manifesto e ouvir quem recebeu a carga | Relato com evidências, remuneração finita e reação da casa |
| A medida do serviço | Exercício orientado de proteção de uma passagem/aliado, com posicionamento, leitura do golpe e manejo escolhido | Uma lição ou vale de estudo, concedido uma vez |

As duas últimas são opcionais e recuperáveis. Falhar no exercício permite tentar de novo sem taxa e sem recompensas repetidas. Não exigir timing Perfeito. O exercício deve oferecer solução para os cinco manejos. A missão da carga precisa ter sua própria investigação e decisão; não reconcluir o carro da oficina ou a tarefa das porções.

Uma audiência antes do embarque liga o que se aprendeu na casa às responsabilidades da viagem. Não criar uma longa cadeia obrigatória antes da partida. Missões domésticas continuam com cozinheira e ajudantes; assuntos de confiança e viagem recebem atenção da liderança.

## Onde adquirir técnicas

**Secretaria/estudo:** catálogo de manuais autorizados e compra por ouro. **Instrutor:** demonstração, prática orientada e confirmação do aprendizado. **Tomé:** fundamentos, orientação de cultivo e lições essenciais. **Grão-Mestre:** autorização e recompensas de missões. O jogador encontra essas funções por conversa e interação física com cada posto.

Fluxo: serviço/autorização → consultar catálogo → ver efeito e requisitos → comprar manual com confirmação → estudar/praticar se necessário → técnica conhecida → preparar numa das seis vagas. Comprar e aprender não substitui automaticamente o repertório equipado.

Cada oferta mostra nome, manejo, custo em alento, alcance, efeito, requisito de cultivo/proficiência, condição de acesso, preço e estado: conhecido, adquirido para estudar, disponível ou bloqueado. Conhecimento já recebido por Tomé nunca é cobrado novamente. Os quatro ensinamentos de arma de fogo já concedidos permanecem gratuitos e preservados em saves antigos.

O primeiro vale de estudo permite escolher um manual do manejo usado. Demais compras usam a carteira existente. Reputação pode ser expressa por marcos nomeados — acolhido, serviço reconhecido, estudo autorizado — sem acrescentar moeda de fichas ou barra de farm. Preços dependem de simular o ouro disponível junto com armas, vestuário e consumíveis; não estão aprovados nesta análise.

## Limite importante do catálogo

Há muitos IDs apenas de catálogo. `ChapterProgress.learn()` só aceita conteúdo executável declarado em `content_scope.json`; vender o nome de uma ficha não a torna utilizável no combate.

Os estudos portugueses também têm requisitos posteriores. Exemplo: FO10, Disparo de Guarda Baixa, é da Tradição da Medida, mas exige Circulação e C03-M02 no catálogo v2. FO11 também exige Circulação; FO12 exige Integração e C05-M02. A loja de Lisboa pode ter esses registros para estudo posterior, mas ouro e serviços não substituem tais marcos. Técnicas de Matondo, Lin Wen, Abaetê e Mori continuam dependentes dos respectivos ensinamentos.

Para oferecer novas compras utilizáveis já no capítulo 1, é preciso aprovar um pequeno recorte de estudos de Fundamento da Tradição da Medida e revisar as fichas escolhidas. Recomenda-se inicialmente uma opção adicional por manejo, com utilidades diferentes e efeitos compatíveis com o início. A seleção deve ser feita sobre o catálogo, com registro explícito de qualquer mudança de requisito. Até isso ser decidido, não anunciar FO10 ou outros estudos posteriores como técnicas iniciais já disponíveis.

## Implementação e verificação previstas

1. Fixar identidade da liderança e relação com o rei; criar arte própria e Sala do Capítulo com acesso real.
2. Integrar apresentação e relato, mais as duas missões opcionais, com objetivos por etapa e encerramento explícito.
3. Selecionar estudos, implementar efeitos, previsão, ícones, sons e animações antes de pô-los à venda.
4. Integrar compras atômicas: validar acesso, ouro, posse e requisitos antes de descontar; salvar compra, estudo e aprendizagem sem duplicação. Separar manual possuído de técnica conhecida, preservando saves anteriores.
5. Testar os cinco manejos, navegação, dinheiro, compra repetida, menu pausado, interrupção do exercício, save/load e retorno da viagem. Confirmar que a história principal continua viável sem comprar estudos e que o cultivo não sobe por compra.

Fontes de projeto: `docs/entrevista-desenvolvimento-personagem.md`, `docs/ordem-cristo-integracao.md`, `docs/ordem-interior-vivo.md`, `docs/narrativa/C01-portugal-aprovado.md`; corpus vigente de 12/10, especialmente `conceito-original.md` e o anexo `habilidades-passivas-v2/ensino-e-progressao.md` com as fichas por manejo. Esta análise não usou a beta de Mar de Ferro.
