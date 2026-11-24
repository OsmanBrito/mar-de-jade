# Auditoria e acabamento do primeiro mapa · 28/10/2026

## Estado observado antes das alterações

Auditoria da abertura infantil, praça, floresta, promessa, percurso adulto, Casa da Ordem, caderno, equipamento, combate, saves e transição marítima. Foram lidos os diretores, os estados de missão, a narrativa aprovada e os testes existentes. A captura nativa da promessa e abertura adulta confirmou o enquadramento e o diálogo compacto. As novas referências comparativas são produzidas por `tools/capture_first_map_ux.gd -- --before`.

A abertura já entrega controlo depois de três falas, põe a tigela nas mãos da criança e liga a refeição ao encontro com Leonor. A Ordem já comunica a sua função pelo acolhimento, treino, cozinha, enfermaria, secretaria, armaria, documentos e Sala do Capítulo. A sequência adulta encadeia entrega, aprendizagem, cuidado, relato, socorro, avaliação, recuperação e partida. Preservar estes acontecimentos e a voz aprovada é mais útil do que acrescentar exposição ou sistemas.

## Prioridades da auditoria

| Prioridade | Problema demonstrável | Decisão |
|---|---|---|
| P0 | Nenhum bloqueio de progressão demonstrado na auditoria inicial. | Validar o percurso completo e a continuidade antes de concluir. |
| P1 | Acompanhar um pedido substitui o compromisso de história no HUD das rotas; o caderno mostra apenas o nome curto do destino. | Manter história e pedido distinguíveis; usar o subpasso contextual no quest log. |
| P1 | Caderno e opções não têm acesso por rato durante a exploração infantil, apesar de o movimento e as interações o terem. | Ligar os botões existentes ao menu infantil, com a mesma pausa segura. |
| P1 | Duas instruções no mundo usam `E ·`, formato que não acompanha remapeamento nem comando. | Usar o contextual prompt compartilhado `E / A`, já adaptado ao dispositivo. |
| P1 | A barra vertical do menu liga direita/esquerda aos separadores seguintes/anteriores. | Cima/baixo percorrem a coluna; direita entra no conteúdo. |
| P1 | Com capítulo e viagem guardados, a entrada mede 733 px numa janela lógica de 600 px e corta ações. | Limitar a altura e seguir o foco por scroll, preservando título e foco inicial no nome. |
| P2 | Concluídas duplica a carga da Ordem, omite a refeição da vigília e chama ao resultado «Próximo passo»; a roda pode repetir-se ao ser acompanhada. | Corrigir a apresentação dos quest states existentes e o feedback de conclusão. |
| P2 | A exploração infantil dentro do convento pede Leonor no banco sem explicar o regresso à praça. Uma conversa ainda espera a refeição já tomada. | Contextualizar o próximo passo e respeitar a flag da refeição. |
| P2 | O caderno infantil não distingue explicitamente história e serviço opcional. | Reforçar a hierarchy of information sem criar estados ou marcadores. |
| P2 | Os controlos persistentes do menu não acompanham imediatamente a escala de leitura; toggles do Sistema alargam o painel a 120%. | Atualizar fontes sem recriar controlos nem perder foco e quebrar texto dentro das opções. |
| P3 | Duração humana, compreensão espontânea, carga cognitiva da preparação e mistura de áudio. | Partida com iniciantes; testes automatizados não medem emoção nem preferência estética. |

## Critérios de direção

O active objective deve responder ao próximo passo sem retirar player agency. O acompanhamento opcional deve conservar a motivação de história. Os botões do HUD são non-diegetic UI discreta; portas, objetos, moradores e sinalização existente continuam a assegurar soft guidance e exploration affordance. O feedback loop de uma tarefa termina num resultado legível no caderno, sem aparentar uma missão ainda ativa.

Não alterar o formato do save, recompensas, acontecimentos canónicos, regras de combate ou navegação. Não introduzir novos ícones sobre Lisboa nem conteúdo de capítulos posteriores. A referência de qualidade é ritmo, readability e apresentação; não há importação ou reprodução de conteúdo de Sea of Stars.

## Leitura do percurso e das missões

| Momento | Função e resultado da auditoria |
|---|---|
| Casa e primeiro movimento | A criança tem nome, acolhimento e vulnerabilidade; Tomé e a refeição dão contexto íntimo, Leonor motiva a saída. O objetivo continua visível quando surge uma interação próxima. Preservada a primeira conversa de três falas. |
| Claustro e praça | A cruz antiga, preparativos de viagem e treino opcional dão environmental storytelling à Ordem. O regresso pela saída sul passa a aparecer como subpasso, sem acrescentar marcadores. |
| Leonor e treino | Água, banco, movimento e exercício partilhado constroem relação e onboarding pelo fazer. Os controlos não são todos introduzidos numa exposição inicial. |
| Floresta e promessa | Pistas e descobertas conduzem ao pequeno risco; o combate e a diferença de domínio tornam a promessa significativa. As escolhas e o regresso mantêm consequências e releitura. Sem alteração dos acontecimentos. |
| Primeiro serviço adulto | Entrega, enfermaria e relato apresentam a instituição através do trabalho e do cuidado. Escolhas corrigíveis e recompensas únicas já evitam fail states punitivos. Preservado o encadeamento. |
| Serviços e exploração | Água, vigília, roda, contas e amarra têm ações e consequências distintas; audiência, investigação e treino têm categorias próprias. O caderno passa a mostrar o resultado da vigília e cada tarefa apenas uma vez. |
| Avaliação e recuperação | A demonstração pública e o duelo reservado têm papéis diferentes; auxílio e água precedem novo treino. A derrota mantém a função narrativa e a recuperação o ritmo gradual. |
| Preparação e embarque | Armas, técnicas, passivas e reserva já têm preparação e confirmação. Pedidos são opcionais, a partida avisa pendências e a viagem conserva o grupo. O HUD mantém a história mesmo durante um desvio escolhido. |

O arco de ritmo já disponível é curiosidade → descoberta → pequeno risco → domínio → recompensa → novo horizonte. As mudanças removem atrito de orientação e consulta desse arco. Não foram criados encontros, deslocações obrigatórias ou sistemas adicionais.

## Alterações e capturas nativas

- `lisbon_routes` separa o compromisso principal do acompanhamento; `chapter_objectives` e o caderno consultam o mesmo subpasso de história. A indicação de retomar com Duarte permanece no primeiro pedido guiado.
- O caderno distingue tarefas opcionais, acompanhamento e resultado; carga e roda não se repetem e o serviço da vigília permanece em Concluídas.
- Caderno/Menu abrem a pausa infantil por rato, conservando posição, cursor narrativo, estado e foco. Conversas e combates mantêm os seus próprios controlos.
- A exploração infantil indica a saída do convento e a conversa da criança respeita a refeição tomada; saves anteriores conservam a alternativa antiga.
- A entrada e o menu respondem à leitura ampliada. O foco acompanha o scroll e os filtros quebram entre botões, sem partir palavras.
- As duas instruções antigas de tarefas passam pelo remapeamento e pela seleção de dispositivo já existentes.

| Evidência | Antes | Depois |
|---|---|---|
| Primeiro movimento, mesma escala de comparação | [Infância](primeiro-mapa-ux/infancia-antes.png) | [Caderno/Menu desde o início](primeiro-mapa-ux/infancia-depois.png) |
| Hierarquia do caderno infantil | [Objetivo sem categoria](primeiro-mapa-ux/caderno-infancia-antes.png) | [História e serviço opcional separados](primeiro-mapa-ux/caderno-infancia-depois.png) |

As comparações acima usam o mesmo canvas lógico de 1440 × 900 apresentado numa janela de 960 × 600. A validação adicional usa **também canvas lógico de 960 × 600**, para detetar overflow que a simples redução da janela pode ocultar. Texto testado a 100%, 110% e 120%.

Outras capturas: [história e pedido no HUD a 960](primeiro-mapa-ux/historia-pedido-960.png), [resultados e filtros a 120%](primeiro-mapa-ux/concluidas-960.png), [Sistema a 120%](primeiro-mapa-ux/sistema-960.png), [entrada com título e foco](primeiro-mapa-ux/entrada-960.png), [continuação acessível por scroll](primeiro-mapa-ux/continuar-960.png).

Momentos do percurso conferidos por renderização nativa: [primeiro risco na floresta](primeiro-mapa-ux/primeiro-risco.png), [Leonor em combate](primeiro-mapa-ux/leonor-combate.png), [embarque](primeiro-mapa-ux/embarque.png), [navegação após Portugal](primeiro-mapa-ux/navegacao.png).

## Validação

**35 suítes distintas aprovadas, 1.480 verificações funcionais**, usando o resultado aprovado mais recente de cada suíte. A contagem inclui os quatro testes novos, abertura/infância/floresta/promessa, sequência adulta, missões, equipamento, cinco manejos, passivas, interface, continuidade, navegação e capítulo completo. Os 17 blocos adultos chegaram à partida através dos controladores reais de caminhada, colisão, interação e combate.

**Sete execuções nativas OpenGL aprovadas, 296 verificações**, com sobreposição intencional com a regressão funcional: infância 48, caderno 31, entrada 30, comandos 10, floresta 72, capítulo completo 93 e transição marítima 12. As verificações nativas do percurso completo incluem 20 capturas gravadas com sucesso; a floresta inclui cinco. Os ensaios são automatizados no próprio Godot, com input, física e renderização reais; não constituem uma partida humana com iniciantes.

`tools/validate_chapter_content.py` confirmou **249 falas nos 17 blocos**, sem divergências do roteiro aprovado. Não foi alterado o schema dos saves. Roundtrips, versões antigas, rejeição de estados inválidos, recompensas únicas, recursos e embarque passaram. Os dois fixtures que já estavam modificados antes desta tarefa foram conservados byte a byte. [Relatório por suíte e caminhos dos logs](primeiro-mapa-ux/validation.json).

O ambiente emitiu os diagnósticos já conhecidos de acesso ao repositório de certificados do Windows e gravação do cache GLES, além de avisos de objetos na saída de algumas suítes. As execuções finais acima terminaram sem falhas de asserção ou erros de script; as capturas foram inspecionadas. Uma execução gráfica inicial da floresta precisou de `APPDATA` dentro do workspace para poder gravar os fixtures de QA; a repetição isolada passou integralmente.

Reprodução a partir da raiz principal:

```powershell
.\tools\test_first_map_ux.ps1
.\tools\test_first_map_ux.ps1 -Suites @('chapter_rules','chapter_styles','chapter_passives','navigation')
.\tools\test_first_map_ux.ps1 -Suites @('first_map_childhood','first_map_journal','first_map_entry','first_map_prompts') -Rendered -Capture
```

O runner cria diretórios novos em `.qa-runtime/`, isola saves/preferências através de `APPDATA`, conserva fixtures JSON preexistentes e restaura o ambiente no fim. O gerador `tools/capture_first_map_ux.gd` permite capturas do estado atual; `--comparison` repete a escala da comparação infantil. `--before` é apenas uma pasta para recolher uma referência **antes de uma futura edição**, não reconstrói a versão antiga. As imagens históricas desta revisão estão preservadas nesta documentação.

## Ficheiros desta revisão

- Apresentação e orientação: `scripts/chapter/lisbon_routes.gd`, `chapter_objectives.gd`, `player_menu.gd`, `childhood_menu.gd`, `childhood_roam.gd`, `plaza_director.gd`, `chapter_flow.gd`, `name_entry.gd` e `scenes/chapter_01/name_entry.tscn`.
- Regressões: novos `tests/first_map_childhood.gd`, `first_map_journal.gd`, `first_map_entry.gd` e `first_map_prompts.gd`; `tests/player_inventory.gd` passa a testar baixo na coluna vertical dos separadores.
- Ferramentas: `tools/test_first_map_ux.ps1` e `tools/capture_first_map_ux.gd`.
- Documentação: `README.md`, este relatório e `docs/primeiro-mapa-ux/` com capturas e resultados por suíte.

## Pontos que continuam a beneficiar de playtest humano

Compreensão sem ajuda, emoção da promessa, duração natural dos intervalos, preparação adulta e mistura percebida de áudio continuam P3. Convém observar um principiante e um jogador com comando físico, incluindo como regressam à história depois de um pedido. Nas capturas de combate, rever também a separação das silhuetas quando duas unidades ficam adjacentes. Estes pontos não foram tratados como falhas de progressão nem como motivos para acrescentar conteúdo ao mapa.
