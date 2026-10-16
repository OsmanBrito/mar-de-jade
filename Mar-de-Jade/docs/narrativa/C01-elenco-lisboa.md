# Elenco de Lisboa — capítulo 1

Criadas **14 identidades de NPC, com 16 versões visuais e 280 quadros**. O âmbito é Lisboa no capítulo 1, incluindo prólogo e embarque da Botafogo. Os papéis, as entradas em cena e as idades confirmadas seguem `C01-portugal-aprovado.md`; as aparências são propostas originais para revisão. Não foram criados nomes para o mestre visitante, parentescos para os figurantes ou novos diálogos.

## Rever no jogo

Abrir `scenes/art/lisbon_cast_gallery.tscn` e usar **F6**. Setas esquerda/direita mudam a orientação; espaço alterna caminhada; S mostra sentado, C agachado e I de pé. As poses extras estão disponíveis para Leonor criança/adulta, Tomé jovem/atual, Duarte e o trabalhador ferido. Os demais permanecem de pé quando uma pose não disponível é escolhida.

Galeria ampliada: `docs/lisbon-npc-cast.png`. Galeria HTML com direções e locomoção: `assets/art/npcs/lisbon/gallery.html`. Capturas do Godot: `docs/lisbon-cast-in-game.png` e `docs/lisbon-cast-poses.png`.

## Identidades e versões

| Identidade | Versão / função em Lisboa |
|---|---|
| Leonor | Criança no prólogo; 19 anos no presente. Instrutora e princesa. Sem fixar idade ou Plenitude na infância |
| Frei Tomé | Mais jovem no prólogo, sem nova idade numérica; 60 no presente. Mesmo rosto, hábito e identidade |
| Duarte | 20 anos; companheiro de treino, socorro e embarque |
| Rodrigo | Capitão da Botafogo; Rodrigo Falcão no corpus de identidades anterior |
| Beatriz | Tripulante que orienta a primeira amarra |
| Mestre visitante | Adulto; nome e identidade narrativa continuam em aberto |
| Combatente experiente | Participante sem fala na demonstração pública |
| Criança do abrigo | Menina que tenta apertar a correia; sem nome ou idade novos |
| Trabalhador do cais | Chama por ajuda e participa do atendimento |
| Trabalhador ferido | Modelo distinto, com suporte de linho no braço e poses de apoio, sem sangue |
| Mulher do cais | Auxilia com pano e passagem do paciente |
| Observador | Reage ao olho verde; recebe a tarefa de trazer água |
| Acompanhante de Leonor | Arquétipo de figurante discreto no prólogo, à distância |
| Familiar do trabalhador | Arquétipo da família presente na retirada; parentesco específico não fixado |

Pai do protagonista e encarregado são mencionados, mas não têm uma entrada visual individual explícita no recorte aprovado. O escrivão do estudo antigo do cais não foi promovido a personagem deste capítulo. O protagonista não integra o catálogo de NPCs.

## Produção visual

Os **16 atlas selecionados são originais**, criados com **imagegen integrado**, sem imagens de Hero’s Adventure. Duarte reaproveita sua proposta anterior como referência de identidade e recebeu uma nova versão com poses extras; o PNG anterior foi preservado. Leonor criança e Tomé mais jovem foram derivados de seus respectivos modelos adultos para conservar a identidade. Prompts completos em `assets/art/npcs/lisbon/prompts.json`.

Cada versão tem quatro vistas e 16 quadros de locomoção; seis versões acrescentam quatro poses sentadas/agachadas. `tools/build_lisbon_npc_assets.py` descreve os recortes e pivôs em `frames.json`, gera as galerias e as cenas reutilizáveis em `scenes/npcs/lisbon/`. Os PNGs fonte são preservados. Algumas vistas laterais geradas vieram na orientação repetida: os campos `west_flip`/`east_flip`, conferidos visualmente, corrigem a orientação na renderização sem reescrever a fonte.

O conjunto é uma primeira base de sprites de exploração e encenação. Poses sentadas/agachadas têm vistas frontal e lateral; não são animações completas em todas as direções. Golpes, reações e retratos de diálogo não foram tratados como pranchas finais. O combate mostra os novos sprites de Leonor, Duarte e Tomé em sua escala, conservando o pipeline de movimento, timing e impacto existente.

## Integração e verificação

`data/chapter_01/lisbon_npcs.json` separa pessoa, versão cronológica, função e aparência. `scripts/npcs/lisbon_npc_library.gd` partilha os metadados e texturas. `actor_proxy.gd` usa os sprites e conserva os overlays de tigela, caneca e instrumento de treino. As colisões permanecem nos pontos dos pés.

O capítulo identifica os trabalhadores e figurantes por papel, em vez de os desenhar todos como o protagonista. Tomé jovem aparece no abrigo do prólogo e o atual na abertura adulta; o familiar aparece na retirada do paciente; o acompanhante fica no prólogo. O mestre continua identificado apenas como Mestre nas falas.

Ensaios em Godot 4.5.1: **27 verificações do elenco**, **31 do capítulo completo em OpenGL**, **38 da praça**, **33 do treino**, **25 da promessa** e **20 da abertura**, sem falhas. Foram inspecionadas as galerias, as poses e capturas reais de socorro e embarque. Os 23 módulos de referência de combate continuam idênticos, exceto os caminhos de importação. O aviso de certificados Windows permanece; não houve erros de GDScript nesses ensaios.
