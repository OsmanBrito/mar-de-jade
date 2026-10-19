# Fechamento das integrações do primeiro arco

Concluído em 19/10/2026 para Portugal e a primeira viagem. Este fechamento trata do grupo 1 da avaliação; não declara concluídos os demais grupos de arte, habitantes ou validação com jogadores.

## Continuidade terra → viagem → abordagem → terra → viagem

O porto de Lisboa na navegação oferece **Entrar em Lisboa**, na conversa com o comerciante. O desembarque abre o mesmo exterior contínuo do capítulo: Ribeira, ruas, acolhimento e convento. O roteiro já concluído não é repetido.

O objetivo da visita é **Regressar à Botafogo**. O pontão oferece continuar a explorar ou reembarcar. Ao reembarcar, a viagem é retomada no mesmo porto, com casco, reservas, fundo de bordo, descobertas, serviços e encontros resolvidos preservados. Madeira continua funcionando como escala da viagem; este fechamento não cria um novo capítulo terrestre na Madeira.

O save da viagem estacionada é a referência durante a visita. Compras, equipamento, suprimentos, passivas, pedidos e descobertas atualizam essa mesma campanha. Guardar em Lisboa também conserva sua área e posição. Carregar durante a visita usa o ponto seguro da viagem, evitando restaurar um capítulo antigo. Ao continuar pela entrada do jogo, uma viagem salva com visita em andamento abre novamente a cidade.

Um retorno de outra campanha não pode sobrescrever o navio: a ligação usa o `run_id`, e não apenas o nome do protagonista. A operação exige uma viagem da campanha, capítulo concluído e porto de Lisboa. Falha ao guardar impede a troca de cenário e mantém o ponto seguro anterior.

## Identidades e propriedade da progressão

O adaptador `party_progress.gd` oferece identidades estáveis sem criar uma segunda bolsa, carteira ou fonte de aprendizado.

| Identidade | Equipamento e aprendizado | Recursos e recompensas |
| --- | --- | --- |
| `hero` | Equipamento pessoal editável, cinco manejos, técnicas e passivas do protagonista | Vida, alento e postura persistentes; carteira pessoal e inventário compartilhado do grupo |
| `duarte` | Kit próprio fixo no primeiro arco; Guarda Companheira e passiva de Duarte, com vagas separadas | Vida, alento e postura próprios; usa suprimentos da mesma bolsa e mantém seus recursos entre encontros |
| Leonor | Participações e equipamentos definidos pelos encontros do roteiro | Não é um membro persistente e equipável do grupo neste arco |

Duarte chega à partida conhecendo Guarda Companheira e sua passiva. Aprender a passiva não a equipa automaticamente. Isso não reintroduz os treinos obrigatórios removidos de Duarte. O fechamento não acrescenta compras de armas ou armaduras para ele: sua política de equipamento no primeiro arco é fixa e aparece nas telas de personagem.

Recompensas pessoais continuam na carteira e bolsa da campanha, com os registros existentes que impedem pagamentos repetidos. Recompensas navais entram no fundo de bordo. Os dois fundos não são somados no desembarque ou reembarque.

## Catálogo do arco fechado

A fonte do recorte é `data/chapter_01/content_scope.json`:

- **27 itens:** os 19 itens de Portugal e os oito equipamentos compatíveis já integrados de Ferro.
- **7 habilidades executáveis:** `DP01`, `DU01`, `ES07`, `LA07`, `MC08`, `FO07` e `PU07`.
- **8 passivas:** `GE21`, `GE22`, as cinco `*-P11` e `DU-P09`, com proprietário explícito.
- **10 exercícios `C01-DEMO-*`:** somente prática local, sem desbloqueio como habilidade canônica.
- **16 outras entradas de habilidades:** catálogo para etapas posteriores, incluindo `DU02`; não são anunciadas como executáveis neste arco.

O serviço de aprendizado rejeita IDs desconhecidos, demonstrações temporárias e técnicas fora desse recorte. Registros antigos de habilidades conhecidas do catálogo continuam aceitos no save, mas as telas os identificam como não executáveis neste arco. Não se apagam aprendizados legados nem se declara implementado o catálogo de toda a campanha.

## Diário, infância e floresta

A etapa anterior já unificou pausa, salvamento, caderno, dicas remapeadas e comandos de controle na infância e na floresta. Sua regressão foi executada novamente.

A viagem agora oferece **Pausa → Personagem e bagagem → Diário e pedidos**. Ali podem ser relidas as descobertas observadas no convento, na floresta e na Ribeira, além dos pedidos registrados, incluindo as duas idades de **A água da casa**. Nada é revelado antes de ser descoberto. Os textos usam quebra de linha e rolagem.

## Compatibilidade e validação

O estado pessoal continua usando o formato de capítulo existente e a viagem conserva seu formato com campanha incorporada. A visita acrescenta o tipo de percurso `port_visit`; saves anteriores sem esse percurso seguem funcionando. O modelo de recursos e o tratamento dos saves legados da etapa anterior permanecem.

| Suíte | Verificações aprovadas |
| --- | ---: |
| Integração completa de retorno, catálogo e diário | 30 |
| Continuidade da campanha | 34 |
| Abordagem | 78 |
| Entrada na navegação da campanha | 12 |
| Equipamentos integrados de Ferro | 41 |
| Inventário | 57 |
| Controles infantis e floresta | 41 |
| Capítulo até a partida | 62 |
| Cidade infantil | 13 |
| Floresta | 67 |
| Circulação e atividades de Lisboa | 57 |
| Balanceamento do arco | 38 |
| **Total** | **530** |

A comparação antiga de abordagem foi atualizada: os limites do equipamento devem coincidir com Portugal, mas a energia carregada pela abordagem é a energia pessoal real, enquanto a aula usa seu orçamento separado.

O teste de integração também foi executado com renderização OpenGL. Capturas em `.qa-runtime/integration-close/captures/`: retorno a Lisboa e diário a bordo. A revisão visual detectou e corrigiu uma linha longa que alargava o diário para fora da janela. As execuções usam perfis de QA separados dos saves reais.

As verificações cobrem funcionamento e persistência. A aprovação de clareza e experiência com jogadores permanece no grupo de validação humana, não neste fechamento técnico.
