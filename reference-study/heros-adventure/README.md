# Hero’s Adventure — amostra local de arte

**Estado atual:** este material conserva a amostra extraída e os ensaios de comparação. A integração da pedra, carga e cordas ficou registada em `docs/cais-reference-integration.md`. O mapa ativo passou para a composição original `scenes/maps/cais_vivo.tscn`; `docs/cais-vivo.md` descreve a revisão e a diferença de estilo ainda por resolver. Para comparar os pisos reais, usar `scenes/art/reference_ground_study.tscn`. A descrição abaixo registra a extração e a cena inicial de comparação.

Extração autorizada para estudo visual em 15/10/2026. São **37 sprites reais** do pacote de mapas da instalação Steam, sem geração de arte ou redesenho. Os PNGs preservam as dimensões originais. Abrir `index.html` no navegador para filtrar a galeria; `gallery-01.png` a `gallery-03.png` mostram a mesma seleção ampliada sem suavização.

## Testar no Godot

Abrir `scenes/art/reference_ground_study.tscn` na raiz do projeto e executar com **F6**.

- 1: pedra, com variantes da mesma família.
- 2: lajes.
- 3: terra.
- 4: relva.
- 5: comparação com o piso anterior gerado.
- WASD/setas e clique: caminhar. E: falar com Duarte. R: repor posição.

A cena usa os pisos e alguns objetos extraídos. Fachadas, árvores, guindaste e os dois personagens continuam os do estudo anterior, para comparar no mesmo enquadramento. É uma prova de integração, sem mudança na campanha ou nos saves. A água é o shader existente do projeto.

## Origem e conversão

Fonte: `C:/Program Files (x86)/Steam/steamapps/common/WulinSH/Wulin_Data/StreamingAssets/aa/StandaloneWindows64/map_assets_all.bundle`.

O pacote tem um invólucro gzip e foi lido com UnityPy 1.25.4 instalado somente em `.tools/unitypy`. A extração inventariou 12.065 sprites e selecionou pisos `dizhuan`, terra `tudi`, vegetação `caodi`, cais `matou`, caixas `xiangzi`, cordas `shengsuo` e pedras `shitou`. Os nomes são identificadores da fonte; não se presume a função só pelo nome. Existem nomes repetidos: o path ID e o arquivo serializado identificam cada sprite.

`sprite-index.json` é o índice completo; `manifest.json` registra os 37 arquivos selecionados, origem, path IDs, dimensões, pivôs, pixels por unidade e eventuais erros. O hash SHA-256 do pacote foi comparado antes e depois da extração: **sem alterações**, zero erros de extração. Nenhum arquivo foi escrito na instalação do jogo.

No Godot, os pisos são ampliados em memória por fator inteiro 2, com amostragem nearest, para a grelha existente de 128 × 64. Os PNGs fonte não são modificados. O pivô Unity, medido a partir da base esquerda, é convertido para coordenadas da imagem no Godot. As colisões dos objetos são footprints provisórios do estudo, não colisões recuperadas do jogo.

As peças de cais `matou` incluem recortes complementares; não são todas objetos completos. Montá-las como o mapa original exige recuperar também os posicionamentos e as peças vizinhas. A amostra não reconstrói um mapa inteiro nem extrai personagens ou combate.

## Reproduzir e validar

Ferramenta: `tools/extract_reference_sample.py`. A opção `--match` seleciona nomes por regex e `--ids` seleciona path IDs explícitos; `--limit` limita a amostra. Sem seleção, grava somente o índice. `tools/build_reference_gallery.py` reconstrói a galeria HTML a partir do manifest.

`tests/reference_ground_study.gd` passou **15 verificações** em Godot 4.5.1/OpenGL: integridade da extração, quantidade de sprites, troca entre pisos preservando a geometria, comparação/restauro e movimento. As quatro capturas `godot-floor-1.png` a `godot-floor-4.png` foram produzidas pelo viewport e inspecionadas. Apenas o aviso de certificados do ambiente apareceu nessa execução; não houve erros de GDScript.

A pesquisa que permitiu localizar os pacotes permanece em `C:/Users/gamer/Documents/Codex/2026-10-14/continue-a-conversa-e-a-entrevista/Mar-de-Jade/Research`. Ela identificou as estruturas; este estudo acrescenta a extração visual e a prova no Godot.
