# Comerciante e última visita ao cais

Depois de guardar a tigela, a água e os mantimentos em C01-M04/S03, o capítulo abre uma pausa de exploração no cais vivo. O jogador pode andar por WASD/setas/direcional ou clique, visitar o comerciante, abrir a sacola e preparar equipamento. A pausa termina ao procurar Duarte no pontão e confirmar o embarque. As 250 falas aprovadas permanecem intactas; a sequência seguinte começa com a primeira fala original de Rodrigo.

## Interação

- O comerciante é um civil junto da banca ilustrada já existente, com identificação, marcador, pegada física e pequenas mercadorias das artes do inventário. A apresentação reutiliza a arte civil `observer`; não há nova personagem narrativa com nome próprio ou nova arte gerada.
- Aproximar e pressionar E / A abre a mesma loja de Lisboa, com moedas, estoque, compra e venda do perfil. O cabeçalho mostra a interação disponível e o saldo. A rota de um clique é interrompida ao negociar; fechar com Esc / B retoma o cais exatamente na mesma posição.
- Duarte tem identificação no pontão. E / A abre a confirmação; o foco inicial permanece em **Continuar a explorar**. Esc / B cancela. **Embarcar com Duarte** inicia C01-M04/S04 e fecha a visita. A loja continua indisponível no convés.
- O mercador permanece visível nas cenas do cais e de serviço, mas a interação física só é habilitada nesta pausa segura. Socorro, tarefas urgentes, tratamento e combate não são interrompidos para negociar. O acesso pelo menu nas pausas anteriores continua disponível.

## Continuidade e navegação

Só Duarte permanece entre os atores narrativos desta pausa: Leonor e os demais atores específicos das cenas anteriores são removidos antes do primeiro frame. A ambientação do cais continua funcionando, com os percursos dos moradores. O trajeto da pescadora é reposicionado nesta visita para deixar livre a posição de atendimento do jogador.

A banca, o comerciante e a margem usam a geometria de navegação e colisão do mapa real. O clique é convertido da posição do evento para o mapa através da transformação da câmera, funcionando também com entrada remota/reproduzida. Os testes percorrem realmente os caminhos até o balcão e até Duarte. A água continua inacessível.

O checkpoint 15 registra a flag booleana `harbor_pause` junto dos dados já existentes no save versão 2. Guardar e carregar nesta pausa regressa diretamente ao cais, conservando compras, equipamentos, estoque e saldo. Não repete o diálogo da bagagem nem entrega novamente provisões, armas ou pagamentos. Ao confirmar o embarque, a flag é removida. Reiniciar durante a visita regressa ao ponto seguro de chegada ao cais; fechar a loja conserva a posição exata de atendimento.

## Implementação e reprodução

`scripts/chapter/harbor_visit.gd` coordena a visita, o contexto do comerciante e a confirmação de partida. `quay_merchant.gd` apresenta o civil e sua pegada; `chapter_flow.gd` integra a pausa ao fim da preparação; `player_menu.gd` permite negociar nessa fase. Os PNGs originais e a cena base do cais não foram modificados.

`tests/harbor_visit.gd`: **34 verificações**, incluindo clique e caminhada reais, E / A, compra e equipamento, posição ao fechar, alcance, bloqueios, confirmação/cancelamento, save e primeira fala do capitão. Aprovadas em headless e OpenGL. Regressões exercitadas: inventário 55, capítulo completo 31 e rotas/retomada 15 — **135 verificações distintas** nesta entrega. `validate_chapter_content.py` conserva 250 falas / 17 blocos e `verify_combat_reference.ps1` conserva os 23 módulos de referência.

`tools/capture_harbor_visit.gd` reproduz a visita através do mapa, entradas de rato e teclado e botões reais. Usa um perfil de demonstração em memória, sem escrever saves do jogador; `--record-visit` acrescenta pausas de leitura para Movie Maker.

[Ver o percurso real — 13 segundos](comerciante-lisboa.mp4) · [Comerciante no cais](comerciante-lisboa.png) · [Loja](comerciante-loja.png) · [Retorno](comerciante-retorno.png) · [Confirmação de embarque](lisboa-embarque.png).
