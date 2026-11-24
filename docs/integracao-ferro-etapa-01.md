# Integração de Ferro — etapa 1

**Registro histórico.** As pendências de continuidade e de definição do recorte do primeiro arco foram tratadas no [fechamento das integrações](fechamento-integracoes-arco-01.md). Os limites abaixo descrevem a primeira etapa, não o estado atual.

Implementada em 18/10/2026, conforme `direcao-base-ferro-campanha-jade.md`. Primeiro lote funcional de equipamentos na economia de Jade, acompanhado do levantamento reproduzível da origem atual. A migração dos serviços e da progressão de personagens ainda não está concluída.

## Levantamento da origem

Origem consultada apenas para leitura: `C:/Users/gamer/Documents/ChatGPT/jogo`. O manifesto `data/integration/ferro-inventory.json` contém 355 recursos alcançáveis por referências literais desde `project.godot`, com SHA-256, e as definições e decisões de integração dos 78 itens. Os 23 módulos existentes em `scripts/combat/mar_de_ferro/` correspondem à origem após normalizar caminhos de scripts e finais de linha; não exigiram substituição nesta etapa.

Esse grafo registra dependências estáticas, não comprova execução de cada ramo. Caminhos construídos em tempo de execução, variações visuais e áudio selecionado por identificador exigem inspeção específica. Não se considera todo arquivo do projeto como recurso efetivamente usado.

| Grupo e arquivos da origem | Classificação e destino |
| --- | --- |
| `main.gd`, `campaign_state.gd`, `campaign_catalog.gd`, `mission_catalog.gd`, `dialogue_catalog.gd` | Coordenação e conteúdo vinculados à história de Ferro. Não adotar o diretor, flags, diálogos nem recompensas. Separar serviços de seus gatilhos narrativos antes de portar. |
| `progression.gd`, `rpg_catalog.gd` | Regras reutilizáveis, estrutura incompatível diretamente: dois heróis por índice, equipamento inicial, aprendizado, recompensas e domínio próprios. Adaptar por identidade e família antes de tornar progresso principal de Jade. |
| `tactics.gd`, `enemy_moves.gd`, `enemy_attributes.gd`, `boss_techniques.gd` | Motor e regras já presentes nas cópias locais; efeitos devem ser auditados por habilidade de Jade. Técnicas numéricas de Ferro não se tornam técnicas canônicas de Jade por renomeação. |
| `tactical_view.gd`, `actor_motion.gd`, `skill_motion.gd`, `skill_presentation.gd`, `technique_cutin.gd`, `passive_feedback.gd` | Infraestrutura de apresentação reaproveitável, já parcialmente integrada ao combate. Preservar capacidades e adaptar atores/efeitos por família. |
| `journey_menu.gd` | Inventário, preparação, comércio e consulta úteis, mas dependentes de `host.progress`, índices de heróis e catálogo de Ferro. Nesta etapa o menu existente de Jade recebe os itens pelo catálogo comum. |
| `world_life.gd`, `*_world.gd`, `*_scenery.gd`, `pixel_art.gd`, `actor_art_catalog.gd` | Movimento, composição, câmera e arte aproveitáveis; nomes, mapas, agendas e condições de missão precisam de adaptação. Habitantes decorativos não contam como missões de Jade. |
| `music.gd`, `soundtrack_catalog.gd`, `combat_audio.gd`, `world_ambience.gd` | Serviços e recursos reutilizáveis mediante adaptação dos contextos e caminhos dinâmicos. Não substituir o áudio/navegação já aprovados de Jade nesta etapa. |
| `assets/skill_icons/gear_*.png` | Arte original reutilizada localmente para os oito equipamentos desta etapa. Nenhuma dependência do diretório externo em execução. |

Para atualizar apenas o levantamento, executar na raiz de Jade:

```powershell
./tools/inventory_ferro_base.ps1
```

`-ImportCompatibleItems` regenera explicitamente o lote e copia sua arte da origem; também restaura os valores definidos por esse importador. Mudanças futuras de balanceamento devem ser refletidas no importador antes de regenerar. O script nunca grava na origem.

## Lote integrado

O catálogo de campanha agora reúne `data/chapter_01/items.json` e `data/integration/ferro-items.json` pelo mesmo serviço `player_items.gd`. Não há bolsa ou moeda adicional.

| Identificador preservado | Equipamento | Preço inicial em ouro |
| --- | --- | ---: |
| `FERRO:dock_knife` | Espada curta de cordoeiro | 65 |
| `FERRO:coat` | Traje do cais | 25 |
| `FERRO:oilskin` | Capa de oleado | 70 |
| `FERRO:mail` | Gibão reforçado | 80 |
| `FERRO:silk` | Faixa de viagem | 75 |
| `FERRO:charm` | Nó de marinheiro | 25 |
| `FERRO:rope_bracelet` | Pulseira de cordame | 55 |
| `FERRO:shell` | Concha do cabo | 60 |

Uma unidade de cada na loja de Lisboa. Não são presentes iniciais; compram-se com o mesmo ouro de serviços e pedidos. Os valores e atributos de origem são um balanceamento inicial, ainda sujeito à avaliação de ritmo. A espada usa o manejo ES e exige experimentá-lo com Tomé; equipamentos respeitam a recuperação narrativa. Os itens existentes de Jade conservam seus identificadores e comportamento.

Este lote só contém vida, alento, postura, proteção, velocidade e ataque, já executados pelas regras de Jade. Itens com movimento, quebra adicional, efeitos por evento, nomes vinculados à trama ou famílias ainda não adaptadas permanecem classificados no manifesto, fora do catálogo jogável. Consumíveis percentuais de Ferro também aguardam integração de efeitos, alcance e consumo em combate.

## Persistência e navegação

- O save de capítulo passa a versão 4 com `campaign_id: mar_de_jade`, no mesmo caminho e com o mecanismo existente de cópia de segurança.
- Saves Jade 1–3 continuam aceitos. A migração mantém o tratamento anterior de cada versão e acrescenta somente o estoque dos novos itens que ainda não tenham entrada. Não altera ouro, equipamento ou estoque antigo nas versões que já os armazenavam.
- Ao salvar em v4, compras e estoque esgotado permanecem esgotados nos próximos carregamentos. Saves v4 de outra campanha e versões desconhecidas são rejeitados antes de alterar o estado em memória. Não há importação de saves de Ferro.
- Terra e abordagens consultam o mesmo catálogo para os itens carregados. O transporte existente por `boarding_loadout.gd` aceita os novos identificadores e executa seus bônus.
- A sincronização completa de consequências entre capítulo, viagem e retorno continua pendente. O perfil marítimo ainda é um snapshot; esta etapa não declara uma progressão unificada de toda a campanha. Recursos coletivos do navio permanecem separados.

## Verificação

Godot 4.5.1, execução headless com `APPDATA` isolado por teste: `ferro_integration` (39 verificações), `player_inventory` (57), `lisbon_requests` (85), `boarding` (78), `navigation_campaign_entry` (12) e `chapter_rules` (38). Total: 309 verificações sem falhas. A suíte de abordagens teve suas expectativas atualizadas para incluir a retirada (`-1`) já existente nas regras; o comportamento não mudou.

O teste novo cobre compra pelos botões reais da loja, equipamento e bônus em terra/abordagem, save/load, migração 1–3 sem reposição posterior e rejeição atômica de dados inválidos. Saves e preferências reais não são usados. Headless não avalia acabamento visual, clareza nem sensação de jogo; a sessão jogada do percurso completo continua necessária.

## Próxima etapa

Extrair a progressão pessoal para identidades estáveis (protagonista nomeável e companheiros), com equipamento, aprendizagem e recompensas próprios de Jade, mantendo adaptadores para o capítulo. Em seguida eliminar a divergência entre o estado pessoal de terra e o snapshot da viagem, antes de migrar efeitos adicionais e serviços de exploração. A navegação marítima e o roteiro aprovado continuam como bases a preservar.
