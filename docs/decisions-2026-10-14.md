# Arranque do desenvolvimento — decisões aceites

O utilizador confirmou a localização junto de Maré de Ferro, teclado/rato e comando, arte original inspirada na apresentação investigada e Windows como plataforma inicial. A localização encontrada de Maré de Ferro é `C:/Users/gamer/Documents/ChatGPT/jogo`, identificada somente pelo nome em project.godot. Mar de Jade fica num projeto irmão: `C:/Users/gamer/Documents/ChatGPT/Mar-de-Jade`.

Foi usado Godot 4.5.1 já instalado, sem atualização ou instalação global. O primeiro recorte é um estudo não canónico de cais/interior, com arte original. Não se antecipou a campanha adulta como substituição do prólogo infantil. Os nomes e acontecimentos do corpus narrativo aprovado continuam intactos.

**Preferência expressa do utilizador:** trabalhar apenas no projeto editável. Não preparar executáveis, exportações ou versões de distribuição sem um pedido explícito. A preparação de export iniciada por engano foi cancelada e retirada da entrega.

A apresentação usa chão TileMapLayer isométrico 2:1, sprites com contacto no chão, ordenação Y de objetos/atores e câmara ortográfica 2D. Texturas fonte foram preservadas. O motor normaliza o atlas de chão em memória e usa regiões de atlas para separar props; estes são passos normais de amostragem/consumo, sem alteração artística dos PNGs gerados.

Mapas são apresentações descartáveis. O estado da sessão contém IDs, posição e factos, sem referências a Nodes. A demonstração tem um único fluxo curto; não foi criado um framework geral de quests ou um editor visual. O pathfinding por clique usa a grelha isométrica local e evita os footprints; movimento direto usa CharacterBody2D e colisões. Agentes remotos e rotinas complexas ficam para a etapa de NPCs.

Foram consultadas as APIs oficiais da versão 4.5: [TileMapLayer](https://docs.godotengine.org/en/4.5/classes/class_tilemaplayer.html), [TileSetAtlasSource](https://docs.godotengine.org/en/4.5/classes/class_tilesetatlassource.html), [Input](https://docs.godotengine.org/en/4.5/classes/class_input.html) e [CharacterBody2D](https://docs.godotengine.org/en/4.5/classes/class_characterbody2d.html).

A investigação anterior está em `C:/Users/gamer/Documents/Codex/2026-10-14/continue-a-conversa-e-a-entrevista/Mar-de-Jade/Research`. O corpus vigente está em `C:/Users/gamer/Documents/Codex/2026-10-12/c-users-gamer-documents-chatgpt-jogo-2/outputs/mar-de-jade`. Nenhum dos documentos anteriores foi alterado no arranque.
