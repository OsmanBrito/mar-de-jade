# Cais — composição da amostra aprovada

## Revisão do mapa — 15/10/2026

O cais adulto passou para `scenes/maps/cais_portugal.tscn`, uma cena editável própria. O estudo antigo em `cais.tscn` permanece como referência anterior. A nova composição substitui a praça isolada por uma rua que chega a uma faixa de trabalho junto ao rio: seis edifícios organizam as frentes da rua, cinco grupos de carga ficam junto aos armazéns e ao guindaste, e o embarcadouro continua ligado à margem.

O terreno prolonga-se para trás dos edifícios, evitando o recorte de ilha no enquadramento. As fachadas dos lados opostos estão voltadas para a passagem. A pedra bege da rua e o pavimento escuro da zona de carga distinguem os espaços. Foram escolhidos `dizhuan22.1_zmf`, `dizhuan22.2_zmf` e `dizhuan34.1_mjp` de uma seleção adicional de 32 sprites em `reference-study/heros-adventure/ground-review`, com manifest e hash da fonte preservados. As fachadas ainda reutilizam o modelo existente; esta revisão trata da disposição e da circulação, não de novos edifícios exclusivos.

O roteiro, os pontos das tarefas e as 15 células de madeira do embarcadouro permanecem ligados. Colisões e navegação usam os footprints dos edifícios e da carga nas novas posições. O mapa foi inicialmente montado por `tools/build_portugal_quay.gd` e guardado como cena; o script reconstrói a disposição inicial e não deve ser executado sobre futuras edições manuais sem as preservar.

Validação desta revisão: **16 verificações** de composição e conexão entre rua, socorro, lado seco e embarcadouro, mais **31 verificações** do capítulo completo com renderização OpenGL. Sem falhas dos testes ou erros de GDScript. Inspecionadas a vista livre e a cena real de socorro do capítulo. A captura atual é `docs/cais-composed-reference.png`.

## Histórico da primeira integração

Após aprovação da amostra de Hero’s Adventure em 15/10/2026, o cais usa a família de pedra `dizhuan1`, as caixas de carga de madeira `xiangzi1` de 40 px e a corda enrolada `shengsuo1`. A variação das três peças de pedra mantém a mesma paleta; a carga e as cordas concentram-se junto ao guindaste, ao embarcadouro e ao limite da área de serviço.

O helper `scripts/chapter/portugal_quay_art.gd` aplica a mesma composição às cenas adultas dos mapas `cais` e `service` em `chapter_flow.gd`. As posições, os footprints de carga, o piso de madeira do embarcadouro e os marcadores das tarefas foram preservados. As cordas são detalhes de chão transitáveis e ficam abaixo dos personagens na ordenação. Os PNGs extraídos permanecem intactos; ampliação e conversão de pivô acontecem em memória.

Para rever diretamente, abrir **`scenes/art/composed_quay_study.tscn` e usar F6**. Esta cena mostra os dois sprites adultos propostos anteriormente. No capítulo, os personagens conservam a apresentação provisória que também suporta ferimentos, postura e transporte de objetos. Fachadas, árvores, guindaste e madeira continuam da etapa anterior; a integração atual abrange piso de pedra, carga e cordas.

Validação: `tests/composed_quay.gd` passou 9 verificações de spawn, carga/colisões, cordas, preservação das 15 células de madeira, integridade do TileSet partilhado e aplicação sem duplicações. `tests/chapter_full.gd` passou as 31 verificações do percurso completo, incluindo acessibilidade das tarefas, sete modalidades de encontro e save/load, sem erros de GDScript. O ensaio gráfico foi inspecionado em `docs/cais-composed-reference.png`.

Origem dos sprites e galeria: `reference-study/heros-adventure/README.md`. A cena de comparação `reference_ground_study.tscn` continua disponível para alternar os quatro tipos de piso.
