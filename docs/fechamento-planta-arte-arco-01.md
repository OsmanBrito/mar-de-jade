# Fechamento dos pontos 2 e 3 — planta e arte do Arco 1

Implementação consolidada em 19/10/2026. Este registro substitui as pendências de planta e acabamento da lista anterior. O fechamento técnico não substitui a aprovação final de arte, ritmo e experiência com jogadores prevista no ponto 10.

## Planta e circulação

A planta definitiva conserva o eixo adro–praça–Ribeira e as descidas alternativas a poente e nascente. Não foram acrescentadas vielas sem função. O percurso poente liga estaleiro e pontão ao restante cais; o nascente liga oficina, recibos e armazém. A leitura dos recibos oferece uma alternativa à repetição de entregas. O pontão poente recebe **A maré e a amarra**; o pontão de embarque conserva a função de partida e retorno da Botafogo.

As arcadas levam ao claustro e aos interiores existentes. A portaria infantil agora também entra no acolhimento pelo dormitório e devolve a criança à mesma porta ao sair, inclusive depois de salvar e retomar. Não é necessário atravessar o claustro para usar essa entrada.

Cinco pontos de acesso exteriores têm inspeção por aproximação física: igreja, duas moradias, armazém e oficina. As casas são identificadas como privadas; a igreja orienta para a capela pelo claustro; armazém e oficina indicam o atendimento exterior. Não prometem interiores inexistentes. As três cancelas infantis explicam a restrição pela circulação de trabalho e pela necessidade de acompanhamento.

Estaleiro, cordoaria, mercado, armazém e oficina têm placas posicionadas fora dos objetos que antes as ocultavam. As leituras conservam o progresso da história e ficam observadas no save. Conversas e inspeções locais mantêm a câmera de exploração: bloquear movimento já não desloca o enquadramento para a encenação principal.

Os limites da câmera usam uma margem composta do cenário, com vegetação periférica. Os dois extremos das ruas e os dois pontões foram conferidos em 1024×768, 1280×800 e 1920×1080.

## Acabamento visual

O piso recebeu variações localizadas pelo uso: terra e desgaste, resíduos de madeira, fibras, marcas de rodas e áreas úmidas de trabalho. Essa camada complementa o pavimento existente sem acrescentar outra grade de ladrilhos. Bases e soleiras receberam sombras de contato; placas e pequenos avisos identificam a função dos edifícios.

As proporções originais dos recursos são preservadas. Fachadas usam a transparência real da imagem para detectar cobertura do personagem e transitam suavemente para a opacidade reduzida; os cantos transparentes não escondem o edifício. Mantêm-se os materiais compartilhados, a filtragem, a ponte e as transições de água e margem da floresta já implementadas na passagem anterior.

O padrão dos retratos é busto em proporção **5:6**, com enquadramento e filtragem comuns. O protagonista conserva sua arte dedicada; os interlocutores usam recortes consistentes das artes existentes, incluindo os papéis antes sem correspondência. Objetos e narração não recebem um rosto de personagem.

Lobo, urso e corço receberam três folhas transparentes com **18 poses**. O lobo e o urso distinguem caminhada, preparação, contato e queda; o corço distingue observação, caminhada e corrida. Escala por espécie e apoio inferior central são compartilhados entre poses, evitando mudanças de tamanho no movimento. O impacto do combate continua sincronizado com a regra existente. A opção de efeitos reduzidos é respeitada.

As imagens originais permanecem preservadas. As folhas foram geradas com a ferramenta de imagem integrada, usando os animais existentes como referência. O validador de atlas confere recortes e margens sem redimensionar os arquivos.

- [Assets finais, referências e prompts completos](../assets/art/forest/animal-poses-provenance.json)
- [Validador e construção dos recortes](../tools/build_animal_atlas.py)
- [Passagem anterior de materiais, água e ponte](acabamento-visual-ambientes.md)

## Validação

| Suíte | Verificações |
|---|---:|
| map_art_closure | 90 |
| chapter_full | 62 |
| forest_hunt | 67 |
| lisbon_circulation | 57 |
| childhood_controls | 41 |
| convent_architecture | 27 |
| convent_proportions | 9 |
| opening_presentation | 29 |
| combat_presentation | 19 |
| exploration_polish | 32 |
| childhood_city | 13 |
| chapter_rules | 38 |
| lisbon_requests | 85 |
| integration_closure | 30 |
| **Total: 14 suítes** | **599** |

Todas aprovadas. A suíte nova verifica aproximação real às portas, câmera ativa, limites em três resoluções, opacidade por alpha, portaria infantil com retomada de save, proporção e cobertura do elenco nos retratos, recortes e estados dos animais. As regressões cobrem campanha, infância, floresta, pedidos e continuidade da viagem.

Capturas nativas usadas na inspeção ficam em `.qa-runtime/map-art-close/captures/`: cinco acessos, extremos em três resoluções, contato de retratos e poses dos animais. O julgamento final do estilo e da experiência continua sendo uma aprovação humana; estes testes não medem satisfação, emoção ou duração natural da campanha.

**Continuação implementada:** [ponto 4 — habitantes e cidade viva](habitantes-cidade-viva-arco-01.md), com atividades, conversas por acontecimento e retomada após cenas.
