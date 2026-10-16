# Validação do capítulo 1 — 14/10/2026

O capítulo provisório está ligado da entrada do nome ao embarque na Botafogo. O percurso adulto cobre os 17 blocos restantes do roteiro aprovado, com tarefas, escolhas e combate por turnos herdado de Mar de Ferro. Não existe ação Defender: a defesa é executada no timing do ataque inimigo.

Resultados dos ensaios em Godot 4.5.1:

| Ensaio | Verificações | Falhas |
|---|---:|---:|
| Percurso completo, tarefas e sete modos de combate | 31 | 0 |
| Regras de combate e cinco manejos | 34 | 0 |
| Passivas, custos, mitigação e proteção de Duarte | 19 | 0 |
| Rotas, pausa, preparação e checkpoints | 15 | 0 |
| Testes dos cinco manejos na mesma visita | 9 | 0 |
| Regressão do treino infantil | 33 | 0 |
| Abertura adulta e alternativas | 19 | 0 |

O percurso completo passou em headless e OpenGL. Capturas do viewport foram inspecionadas para verificar enquadramento, tarefas, diálogo, recuperação e embarque; os arquivos temporários foram removidos. As 250 falas dos 17 blocos coincidem com o roteiro aprovado, incluindo alternativas. Os 23 módulos de combate de referência coincidem com a fonte após normalizar os caminhos de importação.

Os testes são reproduzíveis em `tests/chapter_full.gd`, `chapter_rules.gd`, `chapter_passives.gd`, `chapter_routes.gd`, `chapter_styles.gd`, `training.gd` e `adult_opening.gd`. Executar com `--headless --path . --script res://tests/chapter_full.gd`; retirar `--headless` para o ensaio gráfico. Os testes criam fixtures e capturas temporárias em `tests/` e desativam a gravação do checkpoint do jogador.

O Windows emitiu um aviso sobre o repositório de certificados nos ensaios headless, sem falhas de GDScript. Arte, ritmo, balanceamento e duração precisam da validação manual do jogador. O catálogo amplo de técnicas e itens continua além deste conjunto introdutório; não foram gerados exports ou executáveis.
