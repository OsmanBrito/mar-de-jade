# Arma de fogo — arte e técnicas

Entrega de 19/10/2026. Tomé ensina as quatro técnicas ao confirmar a arma de fogo, conforme a escolha do jogador. A aula concluída pelo combate também concede o conjunto. O aprendizado aparece no menu e acompanha a preparação das abordagens.

![Arte e técnicas](arma-de-fogo-arte.png)

## Arte

O herói adulto tem um atlas próprio com nove poses: pronto, dois passos, mira, recuo do disparo, recuperação, guarda, impacto recebido e ajoelhado. O arcabuz está ilustrado nas mãos do personagem; não usa o desenho de linhas da versão anterior. As demais armas continuam com suas artes anteriores.

Fonte transparente preservada em `assets/art/combat/portugal/hero-firearm-v1.png`. Gerada pelo imagegen integrado a partir do herói e do arcabuz existentes. O prompt completo e as referências estão em [firearm-generation.json](../assets/art/combat/portugal/firearm-generation.json). [build_firearm_frames.py](../tools/build_firearm_frames.py) mede os recortes, apoios e bocas do cano sem regravar os pixels da fonte.

O som e o clarão saem na liberação do disparo, antes do impacto. O clarão acompanha a boca ilustrada do cano; fumaça e recuo respeitam a opção de efeitos reduzidos. Os quatro ícones ilustrados anteriores foram reutilizados, cada um associado à técnica correta.

## Técnicas

As fichas seguem `habilidades-passivas-v2/armas-de-fogo.md` do corpus vigente. O básico recupera alento; manejo e recarga fazem parte da ação, sem novo contador de munição.

| Técnica | Alento | Alcance | Efeito |
|---|---:|---|---|
| Disparo de Medida · FO07 | 4 | Primeiro alvo em linha, até 3 | Bom/Perfeito reduz pela metade o próximo bônus comum de aproximação do alvo. |
| Tiro Preparado · FO01 | 6 | Linha livre, até 4 | Mira e dispara na mesma ação; +15% de potência se não houve movimento no turno. Mover continua permitindo disparar, sem esse bônus. |
| Guarda do Cano · FO08 | 7 | Própria | Reduz 30% do primeiro contato frontal até ao próximo turno próprio. Não protege de projéteis, flancos ou costas, nem concede tiro extra. |
| Tiro de Passagem · FO09 | 7 | Linha livre, até 3 | Dispara da posição inicial e só depois dá um passo lateral. O destino é mostrado na previsão; sem casa lateral livre, a técnica fica indisponível. |

Potências básicas deste recorte: 20 no básico, 17 em FO07/FO09 e 21 em FO01 antes do bônus imóvel e do equipamento. Os custos acima são anteriores ao desconto da passiva Treino Paciente, que considera a primeira técnica de arma usada na batalha. Mira de Aprendiz conserva seu efeito específico em FO07.

O passo lateral não permite adquirir linha de tiro através de uma parede. Mover e voltar à posição original não recupera o bônus imóvel; desfazer o movimento planejado recupera a elegibilidade. A Guarda do Cano usa seu estado próprio, sem herdar a redução de 50% da guarda genérica.

Ao carregar saves antigos que já contêm FO07, a aula de arma de fogo é completada com as outras três técnicas, sem mudar inventário, recursos ou recompensas. Quem ainda não aprendeu este manejo continua dependendo de Tomé. A migração de viagem só acontece após a validação do checkpoint e conserva coerentes o capítulo e a preparação a bordo.

## Experimentar

Na campanha, escolher **Arma de fogo** com Tomé. Na prática livre, há básico e as quatro técnicas. No teclado, **1–5** escolhem essas ações, **F** consulta os detalhes e **Espaço** confirma o timing. No controle, **X** seleciona o básico e **Y** percorre as técnicas.

Para uma revisão independente, abrir [firearm_study.tscn](../scenes/art/firearm_study.tscn) no Godot e usar F6. Não grava progresso. F1 permite trocar encontro, manejo e mapa.

[Previsão do passo lateral](arma-de-fogo-previsao-3.png) · [Previsão da proteção frontal](arma-de-fogo-previsao-8.png) · [Disparo no jogo](arma-de-fogo-acao-2.png).

## Validação

610 verificações aprovadas: firearm (119), weapon_choice (43), practice_freedom (127), combat_field (23), combat_economy (65), combat_presentation (19), combat_feel (36), boarding (78), navigation_campaign_entry (12) e navigation (88). Cobrem regras, custo e passivas, alvo e dano previsto, contato frontal, passo posterior ao tiro, controle, aprendizado, continuidade e migração de saves. Onze imagens nativas do Godot foram geradas e a galeria e as previsões foram inspecionadas.

A suíte geral integration_closure não concluiu o retorno a Lisboa porque tenta gravar o checkpoint em `user://`, fora da área gravável desta sessão: o diagnóstico retornou erro 12 na pasta padrão e sucesso ao gravar o mesmo estado em `.qa-runtime`. Essa suíte não está incluída nas 610 aprovações. Não foi alterada a permissão nem o caminho de saves do jogador. Os registros também conservam o aviso do ambiente sobre certificados e o aviso anterior de objetos retidos em combat_economy. A verificação de controle foi automatizada; equilíbrio e sensação ainda podem ser refinados com uma partida humana.
