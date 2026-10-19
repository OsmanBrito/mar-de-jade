# Convento da Ordem — espaços exploráveis

Atualização: [remodelação dos ambientes e controles](remodelacao-lisboa-convento.md), com materiais próprios, orientação mais discreta, clique com aproximação e descobertas persistentes.

18/10/2026. Continuação da reconstrução de Lisboa sobre o projeto atual de Ferro.

## Acesso e circulação

As arcadas à direita da fachada, na praça, recebem uma entrada para o **claustro, a capela e a enfermaria**. A fase adulta também permite passar do acolhimento ao claustro pela porta lateral. As portas são acionadas por aproximação e **E / A**, com as mesmas entradas do teclado e do controle usadas em Lisboa.

Os três espaços compartilham um mapa caminhável. O jardim com cisterna ocupa o centro do claustro; o corredor norte leva à capela, e a passagem leste à enfermaria. A portaria sul retorna à praça; a porta poente retorna ao acolhimento de Tomé na fase adulta. As colunas, os canteiros e o mobiliário têm colisões. As arcadas são peças separadas e ficam transparentes quando encobrem o protagonista.

Na infância, a visita conserva o personagem infantil e a praça original. Voltar permite conversar com Leonor e iniciar a sequência aprovada no banco. A Ribeira continua fora do limite infantil. Na fase adulta, entrar ou sair conserva o compromisso em andamento, incluindo a entrega e a busca urgente por Tomé. Tomé acompanha o retorno pelo claustro quando o jogador escolhe esse caminho; o atendimento só acontece junto do trabalhador.

## Conteúdo e identidade

Há cinco descobertas opcionais: a cisterna, as tarefas da casa, a capela, a separação da roupa limpa na enfermaria e a conversa com o ajudante. Elas tornam visíveis o acolhimento, o trabalho cotidiano e a ligação da casa com a Ordem de Cristo e sua memória templária. A ligação a Tomar continua explícita; esta é a casa fictícia de Lisboa estabelecida na direção do jogo.

As descobertas não concedem habilidades, equipamento, dinheiro ou recuperação de recursos. As falas principais, a formação com Leonor e o socorro mantêm seus acontecimentos. O tema musical da casa acompanha os interiores; ao voltar à praça ou à Ribeira, a trilha retoma o contexto correspondente.

## Arte e origem

Foram criadas duas peças raster com transparência usando a ferramenta integrada de imagens: o arco do claustro e a abside da capela. [Arquivos e prompts finais](convento-artes.md). Os personagens e as animações de Jade permanecem, assim como o mobiliário ilustrado existente.

O jardim e a cisterna aproveitam `bruma-grass-refined.png` e `roman-well-refined-v1.png` do projeto atual de Ferro. Os nomes da origem são conservados para rastreabilidade; o poço entra como objeto de cenário da casa, sem eventos da campanha original. O importador e o [manifesto com hashes](../assets/art/ferro-lisbon/provenance.json) agora registram 23 recursos de cenário copiados. Nenhum arquivo da origem foi alterado.

## Persistência

O save de Jade passa à **versão 6**, aceitando versões 1–5. O percurso usa `area: convent`, com a posição indicando claustro, capela ou enfermaria. A validação recusa posições fora do mapa ou dentro do canteiro. Saves anteriores não podem declarar esse novo espaço; continuam carregando suas áreas originais, dinheiro e estoque esgotado.

Guardar e retomar durante a exploração infantil ou adulta restaura o interior, a posição e o compromisso. A visita não cria um checkpoint posterior da história.

## Verificação

`tests/order_convent.gd` percorre as portas e as cinco descobertas com caminhada e colisões reais, verifica retorno a Tomé, acompanhamento durante o socorro, visita infantil, retomada nas duas idades, compatibilidade v5 e rejeição de localização inválida. O modo `--capture` produz imagens em `.qa-runtime/convent-preview/`.

Também foram repetidos os ensaios do arco adulto completo, praça infantil, percurso de Lisboa, trilha e integração de itens/saves. O ensaio com renderização verifica os três espaços no jogo. As novas visitas são opcionais; o interesse e o ritmo de exploração continuam sujeitos à avaliação jogada.

| Ensaio | Verificações sem falhas |
| --- | ---: |
| `order_convent.gd`, com renderização e capturas | 62 |
| `childhood_city.gd` | 13 |
| `chapter_full.gd`, 17 blocos e sete encontros | 65 |
| `lisbon_walk.gd` | 57 |
| `plaza.gd` | 42 |
| `chapter_music.gd` | 75 |
| `ferro_integration.gd` | 41 |

Total desta etapa: 355 verificações. A cena do convento também pode ser executada diretamente com F6 para inspeção do cenário.

Novos pedidos ligados à Ordem, refeitório e dormitórios adicionais, atividades da capela e as ruas alternativas de Lisboa ficam para etapas seguintes.
