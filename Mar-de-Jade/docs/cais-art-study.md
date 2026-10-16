# Primeiro estudo de arte do cais

Abrir `scenes/art/cais_study.tscn` no Godot e executar com **F6**. É uma cena interativa de direção visual, sem leitura ou gravação do progresso da campanha. F5 continua a abrir o capítulo.

WASD/setas movem o protagonista, clique escolhe caminho, E perto de Duarte abre uma fala já aprovada do cais, E/Enter fecha e R repõe a posição inicial. A exploração usa o controlador e a navegação existentes, com os mesmos footprints das fachadas. Os novos objetos e Duarte têm colisão e entram no cálculo do caminho.

## Proposta para rever

Pedra clara e cal quente, telha de barro, água verde-jade e madeira usada continuam a base. O protagonista de 19 anos usa linho, colete jade e sacola; Duarte, de 20, tem silhueta mais larga e roupa castanha. São propostas de aparência, ainda não modelos definitivos. Os adultos têm cerca de 84 unidades de altura, pivô nos pés e sombra de contacto. O pátio, as crianças e o combate conservam a apresentação anterior nesta etapa.

O recorte acrescenta cabeço de amarração, carro de sacos, redes e carga coberta com linho. O piso recebe variação suave de desgaste por shader, mantendo a textura original. A distribuição deixa o centro livre e mantém a porta acessível. As figuras têm quatro vistas cardinais e três quadros de marcha por vista; diagonais usam a vista cardinal mais próxima. Poses de combate, transporte de objetos e ferimentos ainda precisam de arte própria antes de aplicar este conjunto ao capítulo completo.

## Arquivos e produção

Os três atlas selecionados estão em `assets/art/portugal-v2/`: `hero-walk-v1.png`, `duarte-walk-v1.png` e `quay-props-clean-v2.png`. Foram criados pelo **imagegen integrado**, com transparência, sem API/CLI externo. Os prompts completos e o pedido de limpeza estão em `prompts.json`. O atlas de objetos recebeu uma segunda passagem para retirar a névoa castanha que prejudicava a composição sobre o piso.

Os originais foram preservados. `tools/build_art_frame_manifest.py` descreve os recortes e os pivôs em `frames.json`, sem reescrever os PNG. Isso corrige a distribuição irregular dos quadros gerados e evita capturar pedaços de outro personagem. A apresentação lê esses metadados em `scripts/chapter/quay_sprite.gd`; a composição está em `scripts/chapter/quay_art_study.gd`.

## Validação

`tests/art_study.gd` passou 45 verificações em Godot 4.5.1/OpenGL: fontes dos 32 quadros completos, spawn livre, movimento, orientação da arte, pausa no diálogo, retorno ao controle e navegação em torno dos novos footprints. As capturas reais `cais-art-study.png` e `cais-art-study-dialogue.png` foram inspecionadas e ficam aqui para revisão. O ambiente emitiu avisos de certificados e de escrita do cache de shaders, sem falhas de GDScript ou dos testes.

Validar agora as proporções em relação à fachada, a distinção entre os dois personagens e a família visual dos novos objetos. A aparência histórica detalhada e a animação final continuam abertas à revisão.
