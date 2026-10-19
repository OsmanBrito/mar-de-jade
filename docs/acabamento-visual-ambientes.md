# Acabamento visual de Lisboa, convento e floresta

**Fechamento dos pontos 2 e 3 — 19/10/2026:** planta, acessos, câmera, acabamento e poses consolidados. [Registro atual e 599 verificações aprovadas](fechamento-planta-arte-arco-01.md). As propostas e contagens abaixo são o histórico da etapa anterior.

Revisão concluída em 19/10/2026.

## Resultado

Lisboa, o jardim do convento e os arredores compartilham a mesma base de cor da vegetação. O piso interior e exterior usa uma escala comum de pedra, inclusive nas soleiras, mantendo a compressão vertical que dá perspectiva ao chão. As bordas das ruas receberam uma margem de desgaste mais estreita e irregular, substituindo as faixas largas sobrepostas.

Os objetos colocados pelo sistema de cenário receberam sombras suaves de contato, dimensionadas pela base física ou pela largura da arte. Os batéis conservam o tratamento próprio sobre a água. A revisão de proporções preservou as dimensões aprovadas da arquitetura, dos personagens e das passagens; os testes confirmaram a circulação nesses espaços.

Arcadas, mobiliário e peças menores do convento agora usam filtragem com mipmaps e tratamento das bordas transparentes. Isso reduz o serrilhado quando a câmera afasta, mantendo o mesmo enquadramento e a mesma geometria.

Na floresta, o rio recebeu textura em tons de verde e margens com transição de solo, substituindo as faixas de cor plana. A ponte conserva sua área atravessável e a ordenação da guarda diante dos personagens; as tábuas agora têm veios, variação de tom, juntas e pregos, com sombra suave sob o tabuleiro.

O chão estático de Lisboa deixou de reconstruir seu desenho a cada quadro. A água continua animada pelo material existente, e os elementos móveis conservam seus próprios ciclos.

## Validação

Capturas antes e depois foram geradas no Godot 4.5.1 com OpenGL e conferidas em 1440 × 900 para os três ambientes. Arquivos locais em `.qa-runtime/visual-finish/`: `city-before.png`, `city-after.png`, `convent-before.png`, `convent-after.png`, `forest-before.png` e `forest-after.png`.

| Verificação | Resultado |
| --- | --- |
| Floresta: caminhada, descobertas, ponte e retorno | 67 sem falhas |
| Arquitetura do convento | 27 sem falhas |
| Proporções e acessos do convento | 9 sem falhas |
| Novas ruas e atividades de Lisboa | 57 sem falhas |
| Atividades da casa e interação com mobiliário | 60 sem falhas |
| **Total** | **220 sem falhas** |

`git diff --check` também passou. Esta etapa não altera narrativa, recompensas, regras de combate ou formato de save.

## Próximo ponto

**Atualização:** a revisão técnica de ritmo e balanceamento foi implementada. Ver [resultado e validação](ritmo-balanceamento-arco-01.md).

Ritmo e balanceamento do primeiro arco: duração dos trajetos e diálogos, distribuição dos pedidos opcionais, economia de ouro e suprimentos e dificuldade dos combates. A avaliação de emoção e ritmo percebido continua dependendo de uma passagem humana completa.
