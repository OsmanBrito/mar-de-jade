# Portugal — passivas iniciais

Extensão ao catálogo v2 criada por pedido do utilizador: Portugal também terá passivas. O conjunto abaixo acrescenta oito opções, sem antecipar ou substituir os aprendizados das 102 passivas anteriores. São 110 opções no catálogo de design combinado: 77 do protagonista e 33 dos aliados. A quantidade de oito, os nomes, efeitos e raridades são a primeira implementação editorial deste pedido; balanceamento ainda não ensaiado.

[Galeria](../portugal-passive-icons.png) · [Fichas estruturadas](../../data/chapter_01/passives.json) · [Prompts completos](../portugal-passive-generation.json).

## Ensino em Portugal

Integração prevista em **C01-M04/S01**, após a recuperação e antes da Defesa Perfeita. Fundamento é suficiente. Não conceder passivas de combate no tutorial infantil ou na avaliação de Leonor em M03. Esta extensão não reescreve as falas aprovadas: acrescenta contratos de exercícios ao pátio.

1. Tomé orienta apoio e uma sequência de ataque básico seguido de técnica: conclusão ensina GE21 e GE22, respectivamente.
2. Cada manejo tem um exercício curto de recolher a guarda, medir alcance, apoiar cabo, manter mira ou recolher a palma. A passiva correspondente só é aprendida após concluir o exercício daquele manejo e aprender a técnica necessária. Testar arma não concede passiva automaticamente; os cinco exercícios podem ser retomados no pátio antes do embarque.
3. Duarte participa num ensaio de proteção previsto no pátio antes da partida. DU-P09 pertence apenas a Duarte, com DU01 conhecida. O protagonista não a aprende por estar presente.

Ensino concluído registra cada ID uma vez. A raridade não introduz sorte ou custo monetário para estes exercícios. A aprendizagem de um estilo não bloqueia os restantes. Não acrescentar missão obrigatória, lesão para treino, XP infinito ou recompensa repetida.

## Fichas

| ID | Passiva | Utilizador | Raridade | Efeito |
| --- | --- | --- | --- | --- |
| GE21 | Passo Assentado | Protagonista, geral | Nv. 1 · Comum | Após um turno próprio sem movimento voluntário, reduz em 5% o residual do primeiro contacto físico recebido até ao próximo turno próprio. |
| GE22 | Treino Paciente | Protagonista, geral | Nv. 2 · Incomum | Uma vez por batalha, a primeira técnica de arma custa menos 1 energia se o turno próprio anterior usou ataque básico. |
| ES-P11 | Guarda de Aprendiz | Espada | Nv. 1 · Comum | Acertar ES07 em Bom/Perfeito prepara redução pessoal de 5% no próximo contacto físico frontal, até ao próximo turno próprio. |
| LA-P11 | Medida de Haste | Lança | Nv. 1 · Comum | LA07 ganha 5% de potência quando não houve movimento no turno, mantendo alvo a exatamente dois passos. |
| MC-P11 | Cabo Assentado | Machado | Nv. 1 · Comum | Durante MC08, reduz em 5% o residual pessoal do primeiro contacto físico frontal. |
| FO-P11 | Mira de Aprendiz | Arma de fogo | Nv. 1 · Comum | FO07 ganha 5% de potência quando não houve movimento no turno. |
| PU-P11 | Palma Recolhida | Desarmado | Nv. 1 · Comum | Acertar PU07 em Bom/Perfeito prepara redução pessoal de 5% no próximo contacto físico frontal, até ao próximo turno próprio. |
| DU-P09 | Ombro Presente | Duarte | Nv. 2 · Incomum | A primeira utilização de DU01 na batalha custa menos 1 energia. |

## Limites de resolução

- Até **quatro passivas equipadas por personagem**, gerais e de arma partilham o limite. Troca apenas em ponto seguro; aprender não equipa automaticamente.
- Exige personagem presente/consciente, passiva aprendida/equipada e manejo compatível. Reserva não dispara efeitos. Técnica de outra arma não ativa a passiva.
- GE21 exige um turno próprio anterior válido; não protege o primeiro ataque da batalha antes de o personagem ter agido. Movimento involuntário não serve para manter uma posição estacionária fictícia: se o utilizador mudou de casa desde o fim do turno que criou a condição, a proteção perde validade.
- GE22 considera o primeiro uso elegível de técnica de arma na batalha. Se o turno anterior não usou básico, esse primeiro uso não recebe desconto; uma técnica posterior não ganha uma segunda tentativa. Não afeta ultimate, olhos, itens ou Defender. Não renova ao desequipar/reequipar; estado de batalha pertence ao personagem.
- ES-P11/PU-P11 exigem contacto frontal real; não criam contra-ataque, Perfeito automático ou bloqueio integral. Uma proteção não acumula cargas.
- MC-P11 aplica sobre o residual de MC08, sem somar 5 pontos percentuais à redução preparada. Frente/validade de MC08 continuam necessárias.
- Potência passiva total limitada a +20%; mitigação pessoal limitada a 20%; descontos totais limitados a 2 por ação, custo mínimo 1. Raridade não aumenta esses valores.
- Nenhuma passiva cura, aumenta energia/vida ao equipar, muda patamar, cria movimento/ação extra ou altera a derrota narrativa contra Leonor.

## Arte e implementação

Oito ícones individuais gerados com **imagegen integrado**, em `assets/art/passives/portugal/`. PNGs originais com transparência preservada. Fichas usam as molduras comuns de raridade de `assets/ui/skill_frames/` e o badge nativo `assets/ui/passive_badge.svg`; desenhar badge sobre o canto superior esquerdo da moldura, sem o gravar na imagem fonte. Mostrar nome/nível no tooltip para não depender só da cor.

`tools/build_portugal_passive_gallery.py` valida IDs, utilizadores/manejos, oito PNGs com transparência e molduras existentes, atualiza metadados de raridade e reconstrói a galeria. Galeria inspecionada visualmente. Prompts e origem guardados por ID.

**Estado atual:** as oito passivas têm ensino e efeitos introdutórios no pátio de C01-M04. Aprendizado não equipa automaticamente; há até quatro vagas separadas para protagonista e Duarte. O capítulo usa balanceamento provisório, a validar manualmente. Ver ../combat-portugal.md e tests/chapter_passives.gd.

