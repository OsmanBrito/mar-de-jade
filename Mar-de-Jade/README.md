# Mar de Jade — capítulo 1 jogável

Projeto editável em Godot 4.5.1 para Windows. O capítulo **A promessa impossível**, em Portugal, está ligado do nome do protagonista até ao embarque na Botafogo. Figuras, encenação e convés mantêm a apresentação provisória para validação; não foram criados executáveis ou exportações.

**Navegação Lisboa → Madeira:** no arranque, escolher **Testar navegação · Lisboa → Madeira**, sem precisar de escrever um nome ou repetir Portugal. O teste tem salvamento próprio; **Continuar teste de navegação** aparece quando houver uma viagem guardada. Também é possível abrir `scenes/navigation/voyage.tscn` com F6. No fim de Portugal, **Navegar para a Madeira** inicia a viagem da campanha. [Controles, conteúdo e validação](docs/navegacao-jogavel.md).

**Abordagem no convés:** escolher **Testar abordagem · combate no convés** no menu. A luta acontece no navio inimigo, com a Botafogo ao lado. NPCs, materiais e objetos usam a arte ilustrada de **Mar de Ferro**; técnicas, passivas, timing, controles e escala seguem Portugal. [Batalha completa com áudio — 26 segundos](docs/boarding-mar-de-ferro.mp4) · [Arte, regras e validação](docs/abordagem-combate-portugal.md).

A navegação agora tem [câmera com horizonte e controle pelo leme](docs/navegacao-camera-e-leme.md). **W aumenta a vela; S reduz**: parado, manobra, viagem e plena. Soltar W mantém o andamento; **A/D** viram em relação à proa. **Espaço / RB** recolhe as velas para parar. Aves e correntes indicam descobertas, a aproximação abranda ao chegar e **V / LB** retoma o rumo após o desvio.

As **seis músicas fornecidas pelo jogador**, ondas em relevo, balanço, espuma e sons do casco estão integrados. **Esc → Som e música** ajusta trilha, ambiente e efeitos separadamente. [Prévia de 18 segundos com áudio](docs/navigation-atmosphere.mp4) · [Funcionamento e validação](docs/navegacao-atmosfera.md).

## Jogar

**Combates de Portugal:** abrir `scenes/art/combat_study.tscn` e usar **F6**. **F1** escolhe encontro e manejo; **R** repete. Usa o mesmo combate da campanha, com arena ilustrada, 54 poses de personagens, ícones e sons. Não grava progresso. Vídeos: [encerramento e retorno à história, 11 segundos](docs/combate-encerramento-v4.mp4), [leitura do campo, 13 segundos](docs/combate-campo-v3.mp4), [cinco manejos e aparo, 28 segundos](docs/combate-manejos-v2.mp4). [Acabamento, origem e validação](docs/combat-portugal-finish.md).

**Elenco de Lisboa:** abrir `scenes/art/lisbon_cast_gallery.tscn` e usar **F6**. São 14 identidades, 16 versões e 280 quadros, já ligados ao capítulo. Ver [personagens, poses e origem da arte](docs/narrativa/C01-elenco-lisboa.md).

**Cais vivo:** abrir `scenes/art/composed_quay_study.tscn` e usar **F6**. A campanha usa o mesmo `scenes/maps/cais_vivo.tscn`: edifícios variados, banca de peixe, oficina, carga, oliveiras, caravela e sete moradores com rotinas. **M** alterna a vista geral; WASD/clique movem; **E** interage. [Capturas e validação](docs/cais-vivo.md).

**Estudos anteriores:** `scenes/art/quay_layout_blockout.tscn` conserva a planta em volumes. `scenes/maps/cais_portugal.tscn` e a [integração da amostra](docs/cais-reference-integration.md) ficam como histórico da comparação visual.

**Amostra real de Hero’s Adventure:** abrir `scenes/art/reference_ground_study.tscn` e usar **F6**. Teclas 1–4 trocam pisos extraídos; 5 compara com o anterior. A [galeria e a origem dos 37 sprites](reference-study/heros-adventure/README.md) ficam separadas da campanha.

**Primeiro estudo de arte do cais:** abrir `scenes/art/cais_study.tscn` e executar com **F6**. Propostas do protagonista adulto e Duarte, objetos de trabalho, movimento e diálogo. Ver [o estudo e os controles](docs/cais-art-study.md). Esta cena não grava o progresso da campanha.

Abrir `project.godot` no Godot e usar **F5**, ou executar `Jogar.cmd`. O arranque pede o nome e começa a infância. Se houver um checkpoint, aparece **Continuar capítulo guardado**.

| Momento | Controlos |
|---|---|
| Falas | Enter / espaço / botão Continuar / A |
| Exploração e tarefas | WASD / setas / clique para mover; E / A junto da marca para interagir |
| Combate: mover | G / botão Mover; selecionar casa e confirmar com Enter / A; Z desfaz |
| Combate: ações | 1 para básico; 2 para a técnica disponível; escolher alvo e confirmar |
| Combate: execução | Espaço / A no sinal ofensivo ou defensivo |
| Combate: fim do turno | T / Fim do turno; Q/E orientam; Enter confirma |
| Comando no combate | Direcional seleciona casas; X/Y escolhem ações; LB move; RB encerra; A confirma; B volta |
| Menu do personagem | Esc / Start; personagem, inventário, equipamento, técnicas, passivas, loja e sistema |
| Atalhos do menu adulto | C personagem; I inventário; K técnicas; P passivas; Enter / A confirma; Esc / B retoma |
| Guardar | Automático à entrada das cenas; F5 e menu na sequência adulta |

**Não existe ação Defender.** A defesa acontece no timing do ataque inimigo. Defesa Perfeita só é ensinada por Tomé após a derrota adulta e a recuperação.

## Percurso

Nome → abrigo/infância → praça/movimento → treino infantil → promessa → abertura adulta com assumir/desculpar → repetição com Duarte → socorro no cais → trabalho e conversa com Leonor → demonstração pública → duelo reservado jogável → prazo de dez anos → auxílio e recuperação → teste de cinco manejos → Defesa Perfeita → provisões → amarra azul e embarque.

A derrota contra Leonor resulta do combate e da diferença de atributos, sem game over ou golpes impostos por uma sequência fixa. Ela não ataca o protagonista caído. O treino só regressa depois da recuperação. O capítulo termina como aprendiz sob Rodrigo, sem antecipar África ou novo encontro com Leonor.

No pátio é possível experimentar espada, lança, machado, arma de fogo e desarmado antes da escolha inicial. Há uma técnica introdutória por manejo, oito passivas aprendíveis, preparação de até quatro passivas por personagem e um exercício de proteção com Duarte. Aprender não equipa automaticamente; as passivas de Duarte permanecem dele. A escolha inicial conserva a possibilidade de aprender outros manejos posteriormente.

## Guardar e rever

O checkpoint `user://capitulo-01.json` conserva nome, cena/etapa, escolhas, manejo, aprendizado, passivas, bagagem e conclusão, além de moedas, equipamentos, recursos e estoque. O save versão 2 carrega saves da versão 1. Guarda ao início da cena e após alterações à mochila; carregar repete essa cena, não um turno incompleto. Há backup anterior `.bak`. O perfil de nome continua separado em `campanha-perfil.json`, assim como `viagem.json` do estudo antigo do cais.

[Menu, inventário e loja: funcionamento e validação](docs/menu-inventario-loja.md) · [Prévia real de 10 segundos](docs/menu-loja-portugal.mp4). A loja abre pelo menu nas pausas seguras em Lisboa. O serviço no cais dá 40 reais uma única vez; equipamentos e suprimentos têm preços iniciais para validação.

Depois de preparar a sacola, há exploração livre do cais antes do embarque. Aproxima do comerciante e usa E / A para negociar; fechar a loja mantém a posição. Procura Duarte no pontão e confirma a partida quando estiveres pronto. Guardar/carregar nessa pausa retoma o cais com as compras conservadas. [Integração e testes](docs/comerciante-lisboa.md) · [Percurso real em vídeo](docs/comerciante-lisboa.mp4).

Para rever o restante capítulo diretamente: abrir `scenes/chapter_01/chapter_flow.tscn` e usar F6. O campo `start_block` no Inspector escolhe 0–16 para validação das etapas adultas. Sem nome, a entrada pede-o e regressa à cena. A abertura adulta e a promessa também continuam disponíveis como cenas próprias. O estudo não canónico do cais permanece em `scenes/main.tscn` com F6.

## Autoria e validação

- Roteiro: `docs/narrativa/C01-portugal-aprovado.md`.
- Falas e eventos do restante capítulo: `data/chapter_01/chapter_flow.json`; gerados por `tools/build_chapter_content.py` e comparados ao aprovado por `tools/validate_chapter_content.py`.
- Direção e tarefas: `scripts/chapter/chapter_flow.gd`; posições provisórias em `data/chapter_01/staging.json`.
- Regras do recorte: `scripts/combat/campaign_rules.gd`, herdando o combate de Mar de Ferro. Os 23 módulos de referência continuam iguais à fonte, exceto os caminhos de importação; `tools/verify_combat_reference.ps1` verifica isso.
- Persistência: `scripts/chapter/chapter_progress.gd`.
- Testes reproduzíveis: `tests/chapter_full.gd`, `chapter_rules.gd`, `chapter_routes.gd`, `chapter_styles.gd`, `chapter_passives.gd` e os ensaios anteriores da infância.

O percurso completo foi exercitado em headless e OpenGL, com verificação de cenas, tarefas, combate, estilos, escolhas, passivas e saves inválidos. As 250 falas dos 17 blocos restantes coincidem com o roteiro aprovado, incluindo alternativas. Capturas temporárias foram usadas para conferir a apresentação e removidas após a validação.

O ritmo, o balanceamento e a meta histórica de 120 minutos ainda precisam de validação manual. Este recorte não transforma todo o catálogo amplo de técnicas/itens em sistemas definitivos: o pátio usa o conjunto introdutório indicado acima. Elenco de Lisboa e personagens de combate já têm arte ilustrada; a exploração, a encenação e o convés continuam sujeitos à revisão visual. O nome do mestre visitante continua em aberto, apresentado apenas como Mestre.
