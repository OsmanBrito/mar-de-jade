# Portugal, fase 1 — Um lugar à mesa

Revisão de 16/10/2026, no repositório principal `Documents/GitHub/mar-de-jade`. Esta passagem cobre o abrigo e a saída para a praça. A conversa e os exercícios da praça serão a próxima fase da revisão com o jogador.

[Prévia real de 30,5 segundos com áudio](../previews/abrigo-revisao-sem-escada.mp4). Mostra falas, releitura, Tomé no banco, a caminhada, a tigela na mesa e a chegada à primeira fala de Leonor. Foi gravada pelo Godot em 1280×800, 30 fps, com áudio estéreo de 48 kHz, sem saves reais.

## O que mudou

Um Enter podia avançar duas falas: o diretor recebia o toque e o botão focado também podia ativar ao soltar a tecla. A continuação por teclado agora é tratada uma vez, antes do botão. O abrigo também instala as configurações de controle já na primeira cena; o botão A só estava sendo configurado ao chegar à praça.

As onze falas aprovadas continuam iguais e na mesma ordem. O nome do protagonista aparece na sua fala; uma identificação discreta sobre o ator indica quem fala. A contagem e o botão **Reler**, adaptados do Maré de Ferro atual, permitem voltar ao texto sem desfazer ou repetir gestos. A última resposta de Tomé oferece **Acompanhar Tomé**.

Tomé senta-se num banquinho de madeira junto à cama antes de responder sobre o pai. A escada solta foi retirada: a referência visual precisa fazer sentido no ambiente. Depois da última fala, ele se levanta e espera antes de o menino acompanhá-lo. As duas rotas são definidas por marcadores editáveis e passam por fora dos footprints da cama e da mesa. A caminhada usa os quadros direcionais existentes, com a cadência derivada da distância percorrida. Pausar congela deslocamento, quadros e passos.

A tigela agora está vazia desde a conversa. O mesmo recurso acompanha a passagem da mão para a mesa; um objeto temporário faz o deslocamento visível, e a louça final só aparece ao concluir o gesto. Os dois se sentam antes de voltar a oferecer a continuação.

A câmera está mais próxima dos interlocutores e acompanha a ida à mesa. Na saída, a tela fecha e revela a praça em duas passagens de 0,30 s. A troca de mapa ocorre sob cobertura total; toques acumulados não saltam a primeira fala de Leonor.

![Tomé no banco, antes da resposta sobre o pai](../previews/abrigo-banco.png)

![A tigela na mesa, antes da saída](../previews/abrigo-mesa.png)

## Reaproveitamento das referências

- **Maré de Ferro atual:** paginação por interlocutor e releitura sem efeitos sobre a história, de `scripts/main.gd` (`show_dialog`, `previous_dialog`, `draw_dialog`); passos disparados por distância, de `update_footsteps`; ritmo de fechamento e revelação nas viagens de `update_travel`. Os controladores foram adaptados ao Godot do Mar de Jade, sem importar as falas, o elenco ou o progresso da outra campanha.
- **Áudio do Maré de Ferro:** o `assets/audio/combat/footstep_wood.wav` já presente no projeto tem o mesmo SHA-256 da fonte atual: `77D9DC214E208ACDE1AA6DBE4C8F34EDA35EA44A00AA949C558DEC99C3F70CCA`. É usado com volume baixo e somente durante deslocamento real.
- **Hero’s Adventure:** a seleção de degraus continua apenas no estudo de referência. A escada que havia sido inserida no abrigo foi retirada por não ter ligação com a arquitetura da sala. A campanha usa agora o banquinho de madeira do próprio conjunto de mobiliário.
- **Recursos existentes do Mar de Jade:** elenco e quadros direcionais, mobiliário, louça, tigela de história `PT-Q02`, música do abrigo e materiais de interface. As outras cenas mantêm a variante habitual da louça; o estado de tigela vazia é ativado apenas nesta abertura.

Não foi consultado material da beta do Maré de Ferro.

## Conferência

232 verificações passaram:

- `opening_presentation`: 29 em OpenGL. Teclado, botão A, repetição ao segurar Enter, clique em **Reler**, gestos, caminhos fora dos móveis, pausa, transferência da tigela, saída real e proteção da primeira fala da praça. Os hashes dos saves reais permanecem iguais.
- `opening`: 26, incluindo comparação literal das onze falas com o roteiro aprovado e repetição da cena.
- `name_entry`: 23; `shelter_finish`: 41; `chapter_music`: 74; `first_playable_ui`: 39, em headless.

`tools/record_shelter_review.gd` reproduz a prévia com a entrada real do jogador. A gravação chega a `plaza.tscn` com **“Sai desse lado.”** ainda intacta. O ritmo e a preferência visual ficam para a avaliação do jogador antes de revisar o banco da praça.
