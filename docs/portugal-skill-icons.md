# Ícones de skills — Portugal / C01

Atualização de 19/10/2026: os quatro ícones de arma de fogo agora estão ligados às técnicas executáveis ensinadas por Tomé. [Arte de combate, regras e validação](arma-de-fogo.md). O restante deste documento registra a entrega original dos ícones.

23 ícones PNG com transparência: 20 técnicas do protagonista (quatro por manejo), Defesa Perfeita e duas técnicas de Duarte. IDs/nome das técnicas seguem o catálogo `habilidades-passivas-v2` do corpus narrativo anterior. DP01 é um ID editorial local para Defesa Perfeita, ensinada por Tomé em C01-M04.

[Galeria completa](portugal-skill-icons.png) · [Catálogo de consumo](../data/chapter_01/skill_icons.json) · [Prompts das 16 imagens novas](portugal-skill-generation.json).

Os sete ícones reutilizados de Maré de Ferro foram copiados após autorização do utilizador. A origem está registada por ficheiro no catálogo. DU01 partilha o símbolo de proteção com ES09; DU02 partilha o símbolo de estocada com ES07. A identidade continua distinta nos IDs e nomes. Nenhum ficheiro do projeto de origem foi alterado.

Os restantes 16 ícones foram criados com imagegen integrado, sem CLI/API externo. Preservados os PNG originais e o canal alfa. Os quatro ícones de machado e o passo desarmado receberam imagens próprias para evitar confusão com alabarda/espada. A primeira geração alternativa de ES01 permanece em `assets/art/skills/sources/ES01-generated-v1.png`, com prompt em [portugal-skill-alternative.json](portugal-skill-alternative.json); não integra o catálogo principal.

O catálogo v2 anterior não previa passivas aprendidas em C01. A extensão posterior [Passivas iniciais de Portugal](narrativa/C01-passivas.md), criada por pedido do utilizador, acrescenta oito opções ao ensino de C01-M04, com catálogo e galeria próprios. Não há técnicas próprias dos olhos desbloqueadas em C01. A manifestação contextual verde do cais não é uma skill de cura. A ultimate UPT01 só se qualifica em Integração após C05-M02; o registo de Tomé em Portugal não a torna executável. Ataque básico, movimento e defesa simples continuam ações universais; não foram contados como novas técnicas de arma.

## Consumo

Assets finais em `res://assets/art/skills/portugal/<ID>.png`. O catálogo versão 2 contém `id`, `name`, `icon`, `origin`, `source`, `kind`, `rarity`, `rarity_level`, `rarity_name`, `rarity_color` e `frame`. A interface de skills/combate ainda não existe neste projeto: esta entrega prepara a arte e o mapeamento, sem implementar combate ou conceder técnicas à campanha.

## Raridade

Classificação inicial adicionada após autorização do utilizador. Não havia escala anterior de raridade das técnicas no corpus consultado. Definições em `data/skill_rarities.json`: Nv. 1 Comum (cinza), Nv. 2 Incomum (verde), Nv. 3 Rara (azul), Nv. 4 Épica (roxo), Nv. 5 Lendária (dourado).

Portugal: seis Comuns (técnicas 07 dos cinco manejos e DU02), onze Incomuns (técnicas 01 e 08 dos cinco manejos e DU01), seis Raras (técnicas de estudo 09 dos cinco manejos e DP01). A Defesa Perfeita recebe Rara pela execução especializada; continua ensino essencial de Tomé, sem probabilidade de obtenção. A raridade não altera potência, custos, slots, patamar de cultivo ou graus de domínio I/II/III. Disponibilidade em Portugal não torna uma técnica rara aleatória ou dispensável.

Molduras reutilizáveis em `assets/ui/skill_frames/`: cinco SVGs nativos, com cor e um a cinco pontos de nível. Desenhar a moldura atrás do PNG, reservando o painel interior superior para a arte e a faixa inferior para os pontos. Mostrar também o nome/nível no tooltip, como na galeria, para não depender só de cor. As imagens originais permanecem sem moldura embutida.

Para enquadrar no HUD, usar os limites alfa, manter proporção e filtragem linear; preservar as fontes de resolução maior. A galeria mostra os símbolos sobre fundo escuro, apropriado para os realces claros.

## Validação

23 ficheiros presentes, IDs únicos, imagens não vazias e transparência confirmada. Galeria final inspecionada visualmente para arma, gesto e correspondência com técnica. Não foi ensaiado um HUD de combate, que ainda não está implementado.

`tools/build_portugal_skill_assets.py` reproduz catálogo/galeria, conserva os assets gerados e copia os sete reutilizados do caminho de origem documentado. Requer Pillow e a fonte Arial do Windows; a reconstrução dos reutilizados requer acesso ao projeto de origem.
