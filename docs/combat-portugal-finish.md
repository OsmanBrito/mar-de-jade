# Combates de Portugal — acabamento para validação

Entrega de 15/10/2026. Os quatro pontos autorizados foram integrados aos combates do capítulo: cenário, personagens em ação, interface e som. As regras continuam herdadas de Mar de Ferro. A comparação verificou 23 módulos idênticos à origem, salvo os caminhos de importação.

## Ver e jogar

- [Encerramento e retorno à história — 11,07 s](combate-encerramento-v4.mp4): duelo com vida real, último impacto, postura de derrota, indicação breve de resultado e a primeira fala aprovada da cena seguinte. [Resultado](combate-encerramento-v4.png) e [retorno à narrativa](combate-retorno-v4.png).
- [Leitura do campo — 13,17 s](combate-campo-v3.mp4): obstáculo, movimento insuficiente, percurso numerado, confirmação, desfazer e linha de tiro bloqueada/aberta, através dos controles reais. [Percurso](combate-caminho-v3.png) e [alcance](combate-alcance-v3.png) em capturas estáticas.
- [Gravação dos manejos com som — 28,37 s](combate-manejos-v2.mp4): os cinco manejos e uma Defesa Perfeita com Tomé, com eventos reais de teclado e mouse. Cada manejo usa o básico disponível no capítulo; não representa o catálogo futuro de skills.
- [Primeira gravação — 10,77 s](combate-portugal.mp4): movimento e primeira troca contra Leonor, antes do refino das cadências. Preservada como referência da entrega anterior.
- [Treino infantil](combate-infancia.png), [impacto no duelo](combate-golpe.png), [Defesa Perfeita](combate-aparo.png) e [proteção de Duarte](combate-duarte.png): capturas do renderizador do jogo.
- Cena editável: `scenes/art/combat_study.tscn`. F6 executa; F1 escolhe encontro e manejo; R repete. O estudo não grava o capítulo. O nome e o equipamento passivo vêm do perfil carregado; a disponibilidade de Defesa Perfeita segue a etapa escolhida.
- A campanha usa o mesmo `battle_host.gd` e a mesma apresentação. F5 mantém o percurso narrativo completo e os checkpoints existentes.

## O que mudou

O campo de 9×8 casas agora fica num pátio contínuo, com edifícios de Lisboa, oliveiras, roupa estendida e objetos de treino nas bordas. Os bancos ilustrados ocupam as mesmas casas bloqueadas. A área de movimento, a seleção de alvos e o percurso continuam calculados pelas regras. A arena preserva as proporções em janelas diferentes.

Protagonista e Leonor têm versões infantis e adultas; Duarte e Tomé completam seis folhas, com nove poses cada: pronto, dois passos, antecipação, golpe, recuperação, aparo, reação ao dano e ajoelhado. Os pés e as mãos têm âncoras medidas; armas são desenhadas por manejo e espelhadas com o personagem. O golpe e a reação encontram o impacto herdado em 0,45 s. O boneco de treino recebeu um sprite próprio.

Os botões mostram ícone, nome e custo. Os nomes sobre o campo aparecem para o personagem atual ou para a seleção, reduzindo sobreposição. As instruções distinguem defesa simples no verde e Defesa Perfeita no dourado. Não existe comando Defender. Os exercícios usam o timing guiado; o duelo com Leonor usa as janelas e os sinais dinâmicos da base de Mar de Ferro. A perda continua decorrendo de HP e atributos reais e regressa à narrativa.

Sons de antecipação, impacto, aparo, guarda, proteção e quebra de postura respondem ao resultado efetivo da ação. A arma de fogo tem um estampido próprio. O áudio pausa junto com o combate.

## Refino do peso e dos manejos

Cada manejo ganhou uma cadência própria de antecipação, extensão e recuperação sobre os atlas existentes. As inclinações e deslocamentos são visuais; as casas lógicas e o alcance permanecem iguais.

| Manejo | Movimento e contato |
|---|---|
| Espada | Corte com preparação curta, avanço moderado e retorno à guarda. |
| Lança | Extensão mais reta e tardia, maior alcance visual e retorno rápido. |
| Machado | Preparação mais pesada, corpo assentando no golpe e recuperação prolongada. A pausa de contato dura mais que nos demais manejos. |
| Arma de fogo | Postura apoiada, cano orientado ao alvo, recuo na saída do tiro e fumaça discreta. Som e clarão partem do cano aos 0,28 s; o dano continua no impacto aos 0,45 s. |
| Desarmado | Soco curto, extensão rápida e recuperação antecipada. O básico não desenha estrelas de atordoamento quando não aplica esse estado. |

O alvo cede ligeiramente após receber dano, sem mudar de casa. O aparo usa um arco curto e faíscas de contato, preservando a pose defensiva quando o dano é zero. Os efeitos de ataque deixaram de desenhar rachaduras ou ondas grandes no chão. A opção herdada de efeitos reduzidos diminui os deslocamentos, elimina inclinações e fumaça e encurta a pausa.

As novas cadências estão em `scripts/combat/portugal_motion.gd`; os 23 módulos herdados continuam intactos. Os PNGs, os pivôs e as âncoras da arte aprovada também foram preservados. A seleção de skills e as regras não receberam alterações.

## Leitura do campo

As marcações agora acompanham a decisão. Ao mover, o contorno verde mostra os destinos acessíveis e o percurso traz números legíveis por casa. O painel lateral mostra custo e movimento restante. Se o destino exigir mais movimento, o trecho excedente fica tracejado em vermelho, com a quantidade em falta; a confirmação continua desabilitada. Bancos bloqueados têm uma marca na base e não recebem percursos através deles.

Ao mirar, o contorno tracejado indica o alcance máximo; cantos dourados identificam alvos realmente válidos. A seleção válida ganha uma área dourada discreta, sem escurecer o restante cenário. Linha bloqueada destaca o banco responsável e explica a restrição no painel. As consultas usam as regras reais, incluindo a distância exata da técnica de lança, a preparação no próprio personagem e a proteção de Duarte.

O personagem atual tem um losango completo; os alvos usam cantos, diferenciando-os também pela forma. A orientação final tem uma indicação curta no chão. O golpe anunciado mantém hachura vermelha nas casas realmente ameaçadas. Fora dessas decisões, os pisos ficam livres da grade completa. Arte e personagens continuam ordenados pelos pés.

A apresentação está em `scripts/combat/portugal_field.gd`, integrada à view de Portugal. O custo, o alcance, os bloqueios, as entradas e as regras de confirmação continuam herdados. A correção de previsão impede anunciar dano para um alvo recusado por uma restrição do manejo.

## Encerramento e retorno à história

O resultado já não corta diretamente da recuperação para o diálogo. A última reação termina, o resultado fica visível por 0,65 s e a passagem usa uma cobertura de 0,22 s para sair e outra para revelar a cena seguinte. Os rótulos distinguem prática concluída, fundamento, proteção, Defesa Perfeita e tentativa a repetir. O resultado não concede recompensas novas.

No duelo, o protagonista chega a zero de vida pelas regras reais. A indicação “Leonor venceu” apresenta a perda como continuação da história. Ele permanece ajoelhado, com a cabeça baixa; Leonor termina a recuperação e não volta a atacar. Na cena narrativa, a postura `fallen` reutiliza essa silhueta de derrota, corrigindo o antigo fallback que reduzia uma figura ainda em pé. Não foram criadas lesões permanentes nem alteradas as falas.

O bloco jogável `C01-M03/S03` agora chega diretamente à primeira fala de `C01-M03/S04`, com a encenação pronta sob a cobertura. A tela genérica de etapa concluída já não interrompe esse momento. O bloco continua emitindo a conclusão uma única vez, e os flags e checkpoints seguem o fluxo existente.

Durante a troca, a cobertura vive no viewport externo e cobre também as faixas da janela. Ela intercepta teclado, controle e mouse antes dos botões do diálogo, impedindo que um comando da luta avance a primeira fala. A indicação de resultado pode ser pausada. Reiniciar um estudo cancela a saída pendente; o encadeamento de teste de manejo para fundamento preserva a cobertura até a nova batalha estar pronta.

O controle está em `scripts/combat/battle_ending.gd`, com a cobertura em `battle_curtain.gd` e `battle_stage.gd`. O combate para de atualizar turnos ao concluir a recuperação; o sinal de retorno só é emitido quando a troca está totalmente coberta.

## Origem e reprodução

- [Arte original e prompts](../assets/art/combat/portugal/prompts.json): sete PNGs gerados a partir das identidades já aprovadas, preservados sem reescrever os arquivos de origem.
- [Frames e âncoras](../assets/art/combat/portugal/frames.json): medidos por `tools/build_combat_pose_frames.py`; o processamento cria metadados e uma prancha de conferência, sem alterar os PNGs.
- [Reuso de Mar de Ferro](../assets/art/combat/portugal/reused-assets.json): piso, banco, suporte de treino, ícone básico e 15 WAVs copiados, com SHA-256 verificado. `tools/verify_combat_assets.py` compara as 19 cópias. O projeto de origem permanece intacto.
- Edifícios e vegetação vêm da arte própria de Lisboa em `assets/art/living-quay`. Esta revisão não acrescenta assets de Hero’s Adventure.
- `tools/build_combat_audio.py` reproduz o estampido original. `tools/capture_combat.gd` reproduz as imagens; `tools/record_combat.gd` reproduz a demonstração com o Movie Maker do Godot (`--write-movie ./tests/combat-review.avi --fixed-fps 30`).
- `tools/record_combat_styles.gd` reproduz o vídeo dos manejos: executar com `--write-movie ./tests/combat-styles.avi --fixed-fps 30`, no renderizador OpenGL. O vídeo mostra entradas reais e seis execuções, sem gravar o progresso da campanha.
- `tools/capture_combat_field.gd` reproduz os estados de leitura do campo. `tools/record_combat_field.gd`, com `--write-movie ./tests/combat-field.avi --fixed-fps 30`, reproduz o vídeo de percurso e linha de tiro; as posições dele são alcançadas por movimento real, sem alterar as regras ou gravar o capítulo.
- `tools/record_combat_ending.gd`, com `--write-movie ./tests/combat-ending.avi --fixed-fps 30`, grava o duelo canônico a partir de 90/90 de vida, usando teclado e mouse. Também captura o resultado e a primeira fala após o retorno. Na demonstração, o aprendiz termina com 0/90 e Leonor com 3970/4000; não há alteração de HP para encenar o vídeo. O progresso da campanha não é gravado.

## Verificação

230 verificações automatizadas, sem falhas: infância (33), percurso completo dos 17 blocos adultos (31), regras (34), passivas (19), cinco manejos (9), apresentação/entradas/áudio (19), sincronização dos manejos (36), leitura do campo (22) e encerramento (27). Infância, percurso, manejos, apresentação, sincronização, leitura e encerramento também foram executados no renderizador OpenGL real. O teste de apresentação seleciona o botão e o alvo com mouse, confirma com teclado e executa o timing com evento de controle; verifica que o dano espera pelo impacto.

`tests/combat_feel.gd` executa os cinco manejos antes e depois dos instantes de saída e impacto. Confere ausência de dano antecipado, disparo único, dano igual à previsão, conservação das casas, pausa de contato, retorno à posição, aparo sem reação de ferimento e efeitos reduzidos. O vídeo dos manejos contém áudio não silencioso e sem saturação (pico de −17,4 dBFS).

`tests/combat_field.gd` usa mouse, teclado e controle para verificar percurso versus custo consumido, bloqueios, excesso de orçamento, desfazer, linha de tiro, alcance, restrições da lança, preparação no próprio personagem, aliado elegível e orientação antes de confirmar. O percurso completo dos 17 blocos adultos também passou novamente após a revisão das marcações.

`tests/combat_ending.gd` verifica derrota por dano real, recuperação antes da saída, resultado pausável, sinal único sob cobertura total, primeira fala intacta, bloqueio de comandos durante a troca, postura caída, tentativa malsucedida, reinício e encadeamento entre exercícios. O percurso completo voltou a passar após a nova postura. `tools/validate_chapter_content.py` confirmou as 250 falas dos 17 blocos; os 23 módulos herdados também continuam iguais à origem.

Na primeira gravação, o aprendiz termina a troca com 59/90 de vida e Leonor com 3965/4000. A comparação dos módulos confirma a integridade da base de Mar de Ferro.

O acabamento está pronto para revisão do usuário. A aprovação estética, a sensação dos timings e o balanceamento continuam dependendo dessa validação. Não há afirmação de que a qualidade já supera Mar de Ferro, nem aprovação automática do ritmo pela passagem dos testes.
