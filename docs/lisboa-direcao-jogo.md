# Lisboa — direção espacial e leitura de jogo

Revisão de 21/10/2026, aplicada ao exterior contínuo usado pela campanha.

## Diagnóstico e decisões

O problema principal era a combinação de pistas espaciais contraditórias. O calçamento tinha uma orientação diferente das fachadas e continuava para fora da área caminhável. Objetos, nomes e placas disputavam atenção com o protagonista. Alguns detalhes eram desenhados diretamente sobre o chão, sem participar da profundidade dos personagens.

| Problema observado no jogo | Alteração aplicada |
| --- | --- |
| Piso parecido com uma parede de tijolos vista de frente; pedras grandes em relação ao personagem | Material externo com eixos oblíquos compartilhados, unidades menores e cor menos dominante. As coordenadas são contínuas entre praça, ruas e cais. |
| Calçamento aparentemente aberto além dos limites de navegação | A superfície da Ribeira termina na sua extensão real. Bordas marcam os caminhos laterais, com interrupções nos cruzamentos. |
| Construções com pouco contato com o chão | Sombras seguem a frente baixa e a lateral recuada das fachadas; a vegetação periférica usa grupos menos regulares. |
| Casas inteiras ficavam transparentes durante a caminhada | Recorte suave localizado ao redor do protagonista. Nas conversas que exigem desobstrução completa, a fachada ainda se afasta para manter os participantes visíveis. |
| Caixas superiores podiam ser ordenadas como se estivessem no chão | Cada pilha usa uma única base para ordenar a profundidade; a altura fica dentro desse conjunto. |
| Placas e barras flutuantes espalhadas pelo piso | Cinco placas nos pontos de decisão, ancoradas e ordenadas com os personagens. Removidas as placas soltas no chão, os traços destacados nas entradas e a carga provisória de outro estilo no adro. |
| Miniaturas de inventário coladas sobre a banca | A banca usa seus próprios produtos ilustrados. O nome do comerciante aparece quando ele está em foco; o indicador desaparece à distância. |
| Interagir apagava o objetivo; texto disputava contraste com a arquitetura | Painel compacto para local e objetivo, ação contextual separada na parte inferior. Respeita os comandos configurados e a ampliação de texto. |
| O cabeçalho conservava o nome de uma rua depois do retorno à praça | Atualização do local também dentro do mesmo distrito. A seta de orientação respeita o espaço ocupado pelo painel. |
| O elenco do socorro continuava alinhado atrás do mercado | Ao seguir para a refeição no convento, a cena anterior libera o espaço. Moradores, serviços e seus pedidos continuam disponíveis. |

## Critérios mantidos na implementação

- A praça, as duas descidas, o mercado e os pontões continuam no mesmo mundo e na mesma navegação.
- Entradas, pedidos, comércio e progresso da campanha usam os pontos existentes.
- O piso público indica circulação; as fachadas, as cargas e a água mantêm seus impedimentos.
- O protagonista continua legível quando passa atrás de objetos altos.
- A interface apresenta o compromisso atual e a ação possível como informações distintas.

## Validação reproduzível

Executar na raiz oficial do repositório:

```powershell
./tools/test_lisbon_direction.ps1
```

O executor direciona os dados temporários para `.qa-runtime/lisbon-direction-tests/userdata`, dentro do projeto, e restaura a variável de ambiente ao terminar. As verificações não leem nem escrevem os saves normais do jogador.

As suítes cobrem o circuito pelas duas ruas, pedidos e consequências, acesso ao comerciante e compra, progressão do socorro, persistência, interface e enquadramento das conversas. A verificação específica de direção também confere objetivo e interação em 1440×900 e 960×600, com texto em 100% e 120%, saída do menu e atualização do nome do lugar.

Resultado: **395 verificações aprovadas em nove suítes**, sem falhas de asserção ou de script: `lisbon_direction` (44), `lisbon_city` (20), `lisbon_circulation` (57), `map_art_closure` (90), `harbor_visit` (40), `lisbon_city_campaign` (24), `interface_closure` (34), `childhood_bond` (49) e `adult_arc_closure` (37). A inspeção visual também confirmou a oclusão localizada e a leitura do mercado com a interface contextual. O ambiente de execução emitiu avisos de certificados do Windows e, nas capturas, de gravação do cache gráfico; as imagens foram produzidas e os testes terminaram normalmente.

`tools/capture_lisbon_direction.gd` produz capturas do jogo em `.qa-runtime/lisbon-direction/`: praça, portaria, Ribeira, estaleiro, oficina, rua poente, oclusão, interação e visão geral. As capturas servem à inspeção visual e não são imagens usadas como cenário.

Foi necessário atualizar o substituto do diretor em `tests/adult_arc_closure.gd`: o código atual de objetivos consulta o autoload `ChapterProgress`, portanto o teste precisa de um Node na árvore, em vez de um Dictionary. As verificações do teste foram preservadas.

## Composição do percurso praça → mercado → pontão

Segunda passagem de direção, em 21/10/2026. O trecho ganhou uma estrutura de quarteirões: o quintal residencial une a moradia poente à casa recuada; o pátio de serviço une os fundos do armazém e da oficina. Seus muros são divididos em pequenos segmentos ordenados pela profundidade e as áreas privadas usam a mesma geometria no desenho, na navegação e na colisão.

A saída da praça é enquadrada por dois vasos. O desgaste discreto do calçamento acompanha as curvas da passagem central, abre para o largo do mercado e continua pela faixa pública junto da água. A banca complementar fica junto à fachada, com banco e oliveira no limite do largo. Os acessos à banca principal, ao socorro e à oficina continuam livres. A entrada do pontão ganha uma flâmula da Ordem visível acima dos personagens; o calçamento termina na margem, preservando o tablado de madeira e as pedras de contenção.

O roteiro de captura agora também percorre o mapa com o controlador real, passando por dez pontos entre a praça e o embarque. As imagens `percurso-0.png`, `percurso-3.png`, `percurso-5.png` e `percurso-9.png`, em `.qa-runtime/lisbon-direction/`, mostram a sequência durante essa caminhada. O resultado `LISBON_COMPOSITION_WALK_COMPLETE` confirma a chegada ao pontão antes das demais capturas.

Posições antigas dentro dos novos quintais continuam aceitas pela validação histórica do terreno. Na retomada, a rotina existente `routes.clear_point` coloca o protagonista num ponto público livre antes de devolver o controle. O novo teste verifica tanto a aceitação do save quanto a saída segura do quintal.

Nesta passagem foram aprovadas **371 verificações em nove suítes**: `lisbon_composition` (35), `lisbon_direction` (44), `lisbon_city` (20), `lisbon_circulation` (57), `map_art_closure` (90), `harbor_visit` (40), `lisbon_city_campaign` (24), `childhood_bond` (49) e `navigation_campaign_entry` (12). Os controles da campanha, os pedidos e as duas ruas laterais foram exercitados, além do caminho principal. A captura com renderização verifica separadamente a composição visual do percurso.

Os arquivos centrais desta etapa são `scripts/city/lisbon_blocks.gd` (planta), `lisbon_composition.gd` (composição dos espaços), `lisbon_block_wall.gd` (muros) e `lisbon_waterfront_marker.gd` (marco do embarque). O executor `tools/test_lisbon_direction.ps1` inclui o novo ensaio na execução padrão.
