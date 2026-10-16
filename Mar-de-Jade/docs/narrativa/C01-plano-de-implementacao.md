# Portugal — implementação do capítulo 1

O percurso está ligado do nome à partida da Botafogo. O roteiro aprovado permanece em C01-portugal-aprovado.md; a autorização atual cobre terminar o capítulo com apresentação provisória para validação posterior.

## Sequência disponível

| Bloco | Implementação |
|---|---|
| C01-M01/S01–S03 | Abrigo infantil, banco e duas passagens de movimento |
| C01-M01/S04–S05 | Básico e execução defensiva infantil na base de Mar de Ferro; sem ação Defender ou Defesa Perfeita |
| C01-M01/S06–S07 | Promessa, transição adulta e assumir/desculpar |
| C01-M01/S08 | Movimento/básico e timing defensivo com Duarte; nó da sacola e chamado do cais |
| C01-M02/S01–S03 | Alavanca, verde perceptivo sem cura, busca de Tomé, atendimento comum e passagem livre |
| C01-M02/S04–S05 | Água/refeição, pano e conversa sobre a partida; admitir/ironia |
| C01-M03/S01–S03 | Demonstração assistida de manhã, intervalo até à tarde e duelo real com derrota por diferença de poder |
| C01-M03/S04–S07 | Duas canecas, prazo e ameaça, partida sem gesto secreto, assistência de Duarte/Tomé e recuperação no abrigo |
| C01-M04/S01–S02 | Caminhar antes de treinar; cinco manejos, técnicas introdutórias e passivas; Defesa Perfeita com Tomé |
| C01-M04/S03–S04 | Tigela/provisões na sacola, Rodrigo/Beatriz/Duarte, amarra azul e partida como aprendiz |

As escolhas de resposta são estado de capítulo, sem pontos de romance ou vitória narrativa alternativa. Não há morte no treino, game over na derrota de Leonor, fraturas fixadas ou duração nova da recuperação. Não há novo enquadramento de Leonor após a partida.

## Estrutura editável

A infância e S07 mantêm suas cenas próprias. `scenes/chapter_01/chapter_flow.tscn` executa os 17 blocos de S08 até ao fecho, por dados em `data/chapter_01/chapter_flow.json`. Os mapas reutilizados preservam o TileMap e as colisões; atores, tarefas e pontos da encenação provisória usam `staging.json`.

Tipos de evento: fala, escolha, encenação, tarefa, combate e teste de manejos. A tarefa exige proximidade e interação; a caixa exige recolher/pousar e a recuperação exige caminhar. Diálogo não substitui essas ações. O duelo usa HP real; os exercícios são seguros e repetíveis. Erro no treino de Defesa Perfeita repete as falas aprovadas antes de outra tentativa.

O combate herda os módulos de Mar de Ferro, com conteúdo em `campaign_rules.gd`. Mantidos movimento por casas, previsão, uma ação principal, orientação final, timing e impacto. A defesa é timing, sem comando dedicado. No pátio podem ser aprendidas ES07, LA07, MC08, FO07 ou PU07, além de DP01 e das técnicas de Duarte usadas no ensaio. As oito passivas do catálogo de Portugal são ensinadas pelos exercícios; aprendizado e equipamento são separados, com quatro vagas por personagem.

O save `capitulo-01.json` registra checkpoint, escolhas, aprendizado, manejo, passivas e bagagem, com backup anterior. Autosave à entrada das cenas, inclusive infância; o arranque oferece continuar. Dados incompatíveis são rejeitados antes de alterar o estado. Checkpoints repetem a cena/etapa, sem serializar Nodes ou um turno incompleto.

## Validação e limites

`tests/chapter_full.gd` percorre até à Botafogo, verificando tarefas e seus caminhos, sete modalidades de encontro e persistência. `chapter_rules.gd` cobre cinco estilos e derrota real; `chapter_styles.gd` testa os cinco na mesma visita; `chapter_routes.gd` cobre transições, alternativas, pausa e equipamento; `chapter_passives.gd` verifica efeitos, custos, divisão de proteção e rejeição de dados inválidos. A auditoria de conteúdo confirma 250 falas literais nos 17 blocos e o verificador compara 23 módulos com a referência.

O projeto está pronto para validação manual do capítulo. Figuras, encenação e convés são provisórios. Balanceamento, ritmo e a meta de 120 minutos não estão aprovados pelo playtest automático. O repertório amplo e o sistema completo de itens/proficiência continuam como design para aprofundamento; esta entrega implementa o percurso e os exercícios introdutórios, sem antecipar outros capítulos.
