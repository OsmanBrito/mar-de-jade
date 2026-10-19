# Continuidade terra/viagem e controles da infância

18/10/2026 · projeto principal `C:/Users/gamer/Documents/GitHub/mar-de-jade`.

## Estado pessoal durante a viagem

Ao sair de Portugal, a viagem recebe o estado completo da campanha: identidade da partida, nome, escolhas, pedidos, descobertas, aprendizado, passivas, mochila, equipamento, estoque, pagamentos e carteira pessoal. Vida, alento e postura do protagonista e de Duarte seguem entre abordagens. Os limites de Duarte continuam os usados pelo combate: 120 de vida, 12 de alento e 100 de postura.

Durante a viagem, seu checkpoint seguro é a fonte de retomada desse conjunto. Vitória aplica recursos restantes e consumíveis gastos ao personagem em memória; derrota ou carregamento restaura personagem e navio juntos ao último ponto seguro. O arquivo de Portugal permanece como checkpoint de saída. A entrada identifica a viagem da mesma partida e oferece a continuação marítima, sem uma segunda opção que repita Portugal com uma mochila antiga.

**Pausa → Personagem e bagagem** permite consultar os recursos das duas pessoas, carteira pessoal, fundo de bordo, bagagem, equipamento, técnicas e passivas. Em porto ou águas seguras é possível usar suprimentos em qualquer dos dois, trocar equipamento de manejos já experimentados e preparar passivas respeitando a propriedade e as quatro vagas. As operações usam as regras compartilhadas de itens. Aproximar-se de uma ameaça impede preparação; não permite recuperar recursos pelo menu durante o encontro.

O fundo inicial de 180 de ouro e as recompensas marítimas continuam pertencendo ao navio. Não são somados à carteira pessoal. O teste isolado de navegação e seu personagem preparado continuam independentes da campanha.

## Saves e compatibilidade

- Capítulo v10: identidade de partida e recursos por identidade de companheiro. Aceita capítulos v1–9 e conserva as migrações anteriores.
- Viagem v2: campanha completa junto do estado marítimo e do kit de combate. Aceita viagens v1.
- Uma nova campanha recebe identidade própria, mesmo se usar o mesmo nome. Uma viagem anterior não é associada automaticamente a essa nova partida.
- A viagem antiga recupera o restante da campanha de um capítulo válido com o mesmo protagonista, conservando o kit e os consumíveis que a própria viagem já registrava. Quando só há um kit antigo, conserva-o sem inventar carteira ou escolhas ausentes.
- Recursos individuais de Duarte que não existiam no save antigo começam pelo estado inicial do encontro; não é possível recuperar ferimentos que aquele formato nunca registrou.
- Dados de personagem e kit divergentes, companheiros desconhecidos ou recursos acima dos limites são recusados antes de alterar o estado. Um estado inválido também não pode sobrescrever a viagem válida anterior. Escrita temporária e backup foram mantidos.

## Infância e floresta

Acolhimento, praça, treino, floresta e promessa compartilham o mesmo menu:

| Ação | Teclado padrão | Controle |
| --- | --- | --- |
| Pausa | Esc | Start |
| Caderno | J | Y |
| Interagir | E | A |
| Guardar | F5 ou botão do menu | Pausa → Guardar progresso |
| Retomar | Esc ou botão Retomar | B / Start |
| Percorrer o caderno | Setas / rolagem | Direcional |

Interação, caderno e salvamento podem ser remapeados na pausa infantil. As preferências antigas são conservadas; se uma tecla antiga já ocupava J, o novo caderno recebe uma tecla livre. Os mesmos comandos remapeados seguem para o capítulo adulto. Dicas de interação e salvamento da viagem também consultam as preferências.

O caderno mostra objetivo, pedido da água nas etapas infantis e descobertas já observadas no convento e na floresta. As descobertas da floresta também aparecem em **Pedidos** durante a fase adulta. Ler, abrir opções e fechar o menu devolve a mesma posição e o mesmo cursor de conversa. A pausa congela a encenação; a pausa de combate existente continua responsável pelos encontros de treino, lobo e urso.

Guardar conserva o percurso livre. Conversas e combates continuam retomando o checkpoint da etapa; não se promete retomada no meio de um golpe ou de uma fala.

## Validação

Ensaios executados com `APPDATA` separado dos saves do jogador. Resultados finais desta entrega, sem falhas:

| Ensaio | Verificações |
| --- | ---: |
| campaign_continuity | 34 |
| childhood_controls | 41 |
| navigation | 88 |
| boarding | 78 |
| navigation_campaign_entry | 12 |
| forest_hunt | 67 |
| chapter_full | 62 |
| player_inventory | 57 |
| chapter_routes | 15 |
| opening_presentation | 29 |
| ferro_integration | 41 |
| childhood_city | 13 |
| exploration_polish | 32 |
| name_entry | 26 |
| chapter_rules | 38 |

Total: **633 verificações em 15 ensaios**, sem contar execuções repetidas. Continuidade e controles também foram exercitados em OpenGL. Capturas do caderno com texto a 120% em 960×600, 1440×900 e 1920×1080 e da bagagem marítima foram inspecionadas em `.qa-runtime/continuity-preview/`.

Dois testes antigos ainda esperavam que a chegada à praça começasse imediatamente a conversa do banco; foram ajustados à exploração livre atual, preservando a verificação de identidade e de entrada sem avanço acidental de falas.

O ambiente continua emitindo o aviso de leitura do repositório de certificados do Windows. Não houve erros de script nos resultados finais. Eventos de controle foram simulados pelo Godot; o teste com controle físico e a avaliação humana de ritmo continuam pendentes.

## Fechamento posterior

O [fechamento das integrações do primeiro arco](fechamento-integracoes-arco-01.md) acrescenta o retorno ao exterior de Lisboa, o reembarque na mesma viagem, o diário a bordo e a definição do catálogo executável e das identidades. As limitações históricas desta etapa devem ser lidas junto dessa atualização.
