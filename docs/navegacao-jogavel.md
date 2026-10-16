# Lisboa–Madeira — navegação jogável

Primeira implementação da entrevista de 15/10/2026, em Godot 4.5.1. Abrir o projeto com F5 ou `Jogar.cmd` e escolher **Testar navegação · Lisboa → Madeira**. O botão funciona sem escolher nome e sem repetir a campanha. Para F6, abrir `scenes/navigation/voyage.tscn`.

Revisão atual: [controle pelo leme, três níveis de vela e câmera com horizonte](navegacao-camera-e-leme.md). O [refinamento anterior](navegacao-refinamento.md) acrescentou pistas naturais, aproximação a avistamentos, retorno ao rumo e ambiência original.

Também disponível: [seis músicas, ondas e áudio do casco](navegacao-atmosfera.md), com volumes em **Esc → Som e música**. O [refinamento do mar](navegacao-mar.md) acrescenta reflexos, ondulação em quatro escalas e rastro contínuo com dispersão. [Prévia atual com áudio](navigation-ocean.mp4).

A abordagem [usa a arte ilustrada de Mar de Ferro e as regras de Portugal](abordagem-combate-portugal.md), com técnicas, passivas, atributos, timing e escala do combate em terra. Dois conveses ficam visíveis; a luta acontece apenas no navio inimigo, com a Botafogo ao lado. **Testar abordagem · combate no convés** abre a luta diretamente pelo menu inicial, sem alterar os saves. [Gravação completa com áudio](boarding-mar-de-ferro.mp4).

## Percurso e conteúdo

A Botafogo parte junto do cais de Lisboa. Madeira é o objetivo visível na carta e a primeira escala antes de Duas Águas. É possível navegar, desviar, voltar a Lisboa, visitar Porto Santo e desembarcar na enseada das Desertas. O mapa regional é uma composição comprimida para gameplay; distâncias e posições não são uma carta geográfica de precisão.

No caminho há carga à deriva, um náufrago, um mercante, pescadores, dois navios hostis e o boss opcional **O Quebra-Mar**. Hostis patrulham e perseguem ao detectar; o contato abre um encontro naval próprio. Mercantes e pescadores oferecem interações. O náufrago salvo passa a estar disponível no convés.

Oito sinais naturais distribuem observações pelo percurso: bandos de aves, restos de madeira e faixas de corrente apontam para encontros. Eles não revelam automaticamente o destino na carta. Relatos são apresentados em sequência e ficam suspensos durante diálogos/menus. Um avistamento oferece um cartão de aproximação e uma indicação na direção do objeto. Clicar no cartão ou no próprio objeto reduz a vela ao chegar e para ao alcance da interação; navios em movimento continuam sendo acompanhados durante a aproximação. Após investigar, é possível continuar explorando ou retomar o rumo anterior.

A carta distingue relatos, avistamentos e visitas. Lisboa e o destino já são conhecidos. Cartas e relatos indicam marcas da Passagem das Desertas; observar as três descobre a rota mesmo sem comprar a carta. A passagem conhecida concede uma corrente mais favorável, além do registro e da recompensa. O cartógrafo melhora o alcance de avistamento e a precisão da posição estimada; o piloto aumenta o rendimento da navegação; o casco reforçado amplia a margem em mar pesado e reduz dano naval.

É possível pausar a viagem, caminhar pelo convés e conversar com Duarte, Beatriz, Rodrigo e o sobrevivente resgatado. Em Madeira e nos outros portos há exploração a pé, serviços e retorno à embarcação. A enseada tem apresentação e interação próprias, sem comerciante ou serviços urbanos.

## Controles

| Ação | Teclado / rato | Comando |
|---|---|---|
| Conduzir navio | W sobe vela; S reduz; A/D leme relativo à proa | Impulsos cima/baixo mudam vela; eixo horizontal/direcional comanda leme |
| Caminhar em terra / convés | WASD ou setas | Analógico ou direcional |
| Marcar rumo | Clique no mar ou na carta; WASD cancela o rumo automático | Carta oferece botões para destinos conhecidos |
| Aproximar um avistamento | Clique no objeto ou no cartão Avistamento | Conduzir até o contato indicado e usar A |
| Parar em exploração | Espaço ou botão Parar | RB |
| Selecionar vela em exploração | 1 manobra; 2 viagem; 3 plena | Cima/baixo alternam os níveis |
| Retomar rumo após um desvio | V ou botão Retomar rumo | LB |
| Carta | M / Tab; M, B ou Esc fecha | Y abre; B fecha |
| Interagir / desembarcar | E ou botão Interagir | A |
| Visitar o convés | C ou botão Convés | X |
| Retomar navegação | B ou botão Voltar ao mar | B |
| Guardar / carregar | F5 / F9 ou menu | Menu |
| Pausa | Esc | Start |
| Música e volumes | Esc → Som e música | Start → Som e música |
| Bordada a bombordo / boreste | Q / E ou botões | LB / RB |
| Pausar para ordens navais | Espaço | Y / Start |
| Visar casco / velas / bateria | 1 / 2 / 3 ou painel de ordens | Painel de ordens |
| Reparo naval | R | X |
| Preparar retirada | F, depois conduzir à zona verde | Painel de ordens, depois conduzir à zona verde |

O clique de navegação escolhe um rumo direto em água livre. A embarcação para diante da costa; o jogador escolhe outro rumo ou aproxima-se do ancoradouro para desembarcar. Não é um caminho que atravesse ilhas automaticamente.

O barco ganha velocidade gradualmente, descreve curvas e conserva um curto embalo ao soltar o controle. Uma ordem na direção oposta exige virar a embarcação. O piloto melhora a resposta ao leme. A opção de meia vela facilita observar e aproximar-se; a aproximação marcada reduz a velocidade automaticamente.

## Combate

A batalha naval usa manobra em tempo real, mira assistida pela tripulação e baterias independentes com recarga. O alvo precisa estar ao alcance e do lado correto. Casco, velas e bateria têm consequências diferentes sobre o adversário. Ataques anunciam a área de impacto; a pausa para ordens congela movimento, dano e recarga. Uma ordem de disparo escolhida durante a pausa executa ao retomar.

O Quebra-Mar alterna bordadas e cargas anunciadas. Após a carga, seus flancos ficam expostos. Ignorar os sinais pode afundar a Botafogo; aprender o padrão permite evitá-los. O encontro fica fora da derrota principal e pode ser procurado quando o jogador quiser.

Após incapacitar um navio, é possível recolher salvado e continuar ou abordar. A abordagem usa o combate tático existente: protagonista e Duarte, casas, movimento, ações, orientação e timing ofensivo/defensivo. O grupo começa no convés inimigo de 9×4 casas, mantendo o tamanho de casa do combate em terra; a Botafogo, sua tripulação e as pranchas ficam visíveis ao lado. Adversários, tripulação, materiais e objetos usam os recursos ilustrados de Mar de Ferro. Vitória retorna ao mar e resolve aquele navio; derrota preserva o ponto seguro. Fuga naval conserva dano e deixa a ameaça no mapa.

## Preparação e salvamento

As reservas iniciais permitem o objetivo e vários desvios. Suprimentos caem por distância, sem custo de tempo em conversas, carta ou convés. Reparo emergencial consome provisões, reduz temporariamente a velocidade e tem um limite por batalha. Portos vendem reservas, reparos, carta e melhorias. Um serviço de cais por escala garante recursos essenciais quando necessário.

O mar além da capacidade preparada gera aviso, perigo crescente e dano se o jogador insistir. Recuar a tempo evita a perda. Fome prolongada também compromete o casco. A morte encerra a tentativa e conserva o último checkpoint seguro.

O piloto avisa ao reconhecer mar pesado à frente, antes de entrar na zona de risco. O perigo em curso tem barra e seta de retorno; **V / LB** marca um rumo para águas seguras enquanto houver perigo. A carta assinala a faixa além da preparação atual. Mar e vento tornam-se mais intensos com o risco; o aviso de recuperação confirma quando o perigo terminou.

- Teste rápido: `user://navegacao-teste.json`.
- Viagem após Portugal: `user://navegacao.json`.
- O perfil de nome e `capitulo-01.json` continuam separados.
- Autosave em interações e portos quando a situação for segura; F5 permite salvar manualmente nas mesmas condições. Salvamento inseguro é recusado para preservar uma recuperação viável.
- Checkpoints conservam posição, recursos, visitas, descobertas, melhorias, encontros resolvidos e posições dos navios. Há arquivo anterior `.bak`; dados inválidos são rejeitados antes de alterar o estado.
- O menu inicial oferece continuar cada viagem guardada. **Testar navegação** inicia uma nova tentativa no arquivo do teste.

## Validação

`tests/navigation.gd` exercita 88 verificações em headless e 89 em OpenGL, incluindo carregamento/reprodução da ambiência: caminho marítimo real até Madeira, acesso dos pontos de interesse, leme relativo, três velas, parada, horizonte/projeção/clique no céu, sinais, consumo, descoberta de rota, compras sem perda de conhecimento anterior, saves antigos/atuais e inválidos, perigo e recuo, aproximação e retorno ao rumo, derrota e recuperação, vitória naval comum e boss com o novo leme, derrota por ignorar boss, pausa, atalho real do menu, convés, resgate, enseada e abordagem tática completa com retorno ao mar. O teste desliga autosave antes da entrada pela própria opção do menu, preservando as viagens do usuário.

O trajeto direto em vela de viagem mediu **371 segundos, aproximadamente 6min11s**, em simulação com deslocamento real, sem teleportar. O primeiro sinal natural apareceu em **9,8 segundos** nessa simulação. Interações, visitas e desvios acrescentam tempo à meta inicial próxima de dez minutos. A vela plena aumenta o andamento em 60% sobre viagem. A cadência e a dificuldade ainda precisam do playtest do jogador.

Regressões repetidas neste refinamento: `chapter_full.gd` (31 verificações) e `name_entry.gd` (23), preservando o percurso anterior e a entrada do jogo. A execução headless emitiu o aviso de certificados do ambiente, sem falhas de GDScript nos testes finais.

Capturas de QA: [menu](navigation-menu.png), [mar](navigation-sea.png), [sinais naturais](navigation-signals.png), [aproximação](navigation-approach.png), [descoberta](navigation-discovery.png), [perigo e retorno](navigation-danger.png), [carta](navigation-chart.png), [convés](navigation-deck.png), [Madeira](navigation-madeira.png), [enseada](navigation-island.png), [boss](navigation-boss.png), [ordens](navigation-orders.png), [abordagem](boarding-start.png).

## Arquivos e apresentação

- Conteúdo e geometria: `data/navigation/atlantic.json`.
- Estado, capacidade e persistência: `scripts/navigation/voyage_model.gd`.
- Encontro naval: `scripts/navigation/naval_battle.gd`.
- Cena, interações, menus e transições: `scripts/navigation/voyage.gd`.
- Viagem em perspectiva: `scripts/navigation/voyage_perspective.gd` e `assets/shaders/navigation_perspective_ocean.gdshader`.
- Carta, encontros táticos, convés e porto: `scripts/navigation/voyage_view.gd` e `assets/shaders/navigation_ocean.gdshader`.
- Ambiência e sinais sonoros: `scripts/navigation/voyage_audio.gd`; síntese reproduzível em `tools/build_navigation_audio.py`, com fontes/metadados em `assets/audio/navigation/sources.json`.
- Trilha fornecida pelo jogador: `assets/audio/navigation/music/playlist.json`, com seis MP3, durações e ganhos de reprodução. Ondas e flotação: `scripts/navigation/voyage_sea.gd`.
- Abordagem: `boarding_rules.gd`, `boarding_view.gd`, `boarding_arena.gd`, `boarding_assets.gd`, `boarding_actor_art.gd` e `boarding_ending.gd`, reutilizando o combate existente e os recursos ilustrados de Mar de Ferro, sem modificar os módulos de referência.

A viagem usa geometria 3D procedural simples e shader de mar, com câmera atrás do navio e horizonte. Encontros, carta, convés e caminhada em terra usam as apresentações próprias existentes. Disparos reutilizam os efeitos sonoros do projeto. Mar, vento, aves, madeira e descoberta usam áudio original sintetizado localmente, sem gravações externas. A apresentação continua aberta ao playtest. O Quebra-Mar, interações e falas do trecho são conteúdo novo de implementação; não substituem as falas aprovadas de Portugal nem antecipam cenas da missão africana. Não foram gerados executáveis ou exportações.
