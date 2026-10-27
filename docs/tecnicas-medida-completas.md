# Técnicas da Tradição da Medida

Implementação do conjunto de 65 técnicas comuns (13 por manejo) do catálogo v2 de 14/10/2026. Fonte vigente copiada em `data/order_techniques.json`; não usa a beta de Mar de Ferro.

## Progressão e acesso

- Fundamento, Circulação, Integração, Manifestação e Plenitude preservam os marcos C01-M04, C03-M02, C05-M02, C07-M04 e C10-M04. Proficiência: 0 / 100 / 250 / 400 / 500.
- Pós-jogo: Plenitude 3, nível 52, proficiência 650 e conclusão de C10-M04.
- Os marcos posteriores são consultados no registro de recompensas únicas de desenvolvimento; seus capítulos ainda precisam existir na campanha para disponibilizar acesso normal. Testes não os liberam em saves do jogador.
- FO10 conserva a adaptação de Fundamento de Lisboa. Os cinco estudos introdutórios e os ensinamentos de fogo já conhecidos permanecem compatíveis.
- Principais são gratuitas. Estudos: 30 / 60 / 100 / 160 / 240 ouro conforme patamar; pós-jogo 360. Preços são parâmetros iniciais de implementação, sujeitos a balanceamento da economia futura. Um vale pode substituir uma compra paga.
- Cada ID ocupa uma vaga, independentemente do grau. Conhecimento e preparação continuam separados.

## Graus

I ao aprender; II a 8 usos válidos; III a 20. Ofensivas ganham +5% / +10% de potência. Guardas puras ganham +3 / +5 pontos percentuais, sem desconto adicional. Apoios sem potência reduzem custo em 1 / 2, com teto total de desconto 2. Nenhum grau aumenta alcance, duração ou número de ocorrências.

## Combate

Repertório com seis vagas; compatibilidade do manejo; uma ação principal; movimento especial usa o orçamento existente. Guardas não concedem recuperação de Defender. Vigias só respondem a movimento voluntário, uma vez por inimigo; posição e orientação são mostradas no campo. Escolta exige aliado consciente e dois destinos livres. Punho de Três Medidas oferece escolha de foco por botões, C ou R3.

O sistema de cobertura baixa está representado por `campaign_rules.low_cover` e pelos atributos de cobertura parcial das unidades, separado de paredes/obstáculos. As fichas que dependem desse contexto mantêm seu efeito condicional quando o mapa não oferece cobertura elegível.

Os 65 IDs têm ícones próprios: 44 ilustrações novas geradas com imagegen integrado e 21 artes próprias anteriores preservadas. PNGs originais e alpha foram mantidos; a importação para a UI limita a textura a 256 px com mipmaps. As animações usam perfis por função e poses compatíveis da arte existente; não são 65 novas folhas de sprites. Ultimates e passivas não foram adicionadas a esta contagem de técnicas comuns.

## Catálogo

| ID | Técnica | Cultivo | Alento | Via |
| --- | --- | --- | ---: | --- |
| ES01 | Corte de Precisão | Fundamento | 6 | Principal |
| ES06 | Fio Ininterrupto | Plenitude | 18 | Principal |
| ES07 | Ponta Breve | Fundamento | 4 | Principal |
| ES08 | Corte de Passagem | Fundamento | 7 | Principal |
| ES09 | Guarda Cruzada | Fundamento | 7 | Estudo |
| ES10 | Finta de Ponta | Circulação | 8 | Estudo |
| ES11 | Fio de Retirada | Circulação | 9 | Estudo |
| ES12 | Corte da Dobradiça | Integração | 11 | Estudo |
| ES13 | Medida Guardada | Integração | 10 | Estudo |
| ES14 | Linha de Regresso | Manifestação | 16 | Estudo |
| ES15 | Promessa de Aço | Plenitude | 22 | Estudo |
| ES56 | Fio da Última Medida | Plenitude 3 / pós-jogo | 24 | Pós-jogo |
| ES57 | Guarda de Três Faces | Plenitude 3 / pós-jogo | 23 | Pós-jogo |
| LA01 | Ponta Sentinela | Fundamento | 6 | Principal |
| LA06 | Círculo de Haste | Plenitude | 18 | Principal |
| LA07 | Ponta de Medida | Fundamento | 4 | Principal |
| LA08 | Haste de Abrigo | Fundamento | 7 | Principal |
| LA09 | Ponta e Calcanhar | Fundamento | 7 | Estudo |
| LA10 | Travessa de Haste | Circulação | 8 | Estudo |
| LA11 | Linha de Passagem | Circulação | 9 | Estudo |
| LA12 | Ponta entre Guardas | Integração | 11 | Estudo |
| LA13 | Haste de Escolta | Integração | 12 | Estudo |
| LA14 | Linha sobre o Ombro | Manifestação | 16 | Estudo |
| LA15 | Ponta do Porto Seguro | Plenitude | 21 | Estudo |
| LA56 | Ponta de Três Medidas | Plenitude 3 / pós-jogo | 24 | Pós-jogo |
| LA57 | Haste de Passagem Inteira | Plenitude 3 / pós-jogo | 24 | Pós-jogo |
| MC01 | Golpe de Cunha | Fundamento | 6 | Principal |
| MC06 | Queda da Bigorna | Plenitude | 20 | Principal |
| MC07 | Talho de Medida | Fundamento | 5 | Principal |
| MC08 | Guarda de Cabo | Fundamento | 7 | Principal |
| MC09 | Talho de Passagem | Fundamento | 8 | Estudo |
| MC10 | Cunha de Guarda | Circulação | 9 | Estudo |
| MC11 | Talho de Contrapeso | Circulação | 10 | Estudo |
| MC12 | Corte da Trave | Integração | 13 | Estudo |
| MC13 | Peso Reservado | Integração | 12 | Estudo |
| MC14 | Talho de Amurada | Manifestação | 17 | Estudo |
| MC15 | Cunha do Compromisso | Plenitude | 22 | Estudo |
| MC56 | Talho de Compromisso Inteiro | Plenitude 3 / pós-jogo | 26 | Pós-jogo |
| MC57 | Cabo de Quatro Apoios | Plenitude 3 / pós-jogo | 24 | Pós-jogo |
| PU01 | Palma de Interrupção | Fundamento | 6 | Principal |
| PU06 | Impacto de Centro | Plenitude | 18 | Principal |
| PU07 | Punho de Medida | Fundamento | 4 | Principal |
| PU08 | Palma de Guarda | Fundamento | 6 | Principal |
| PU09 | Passo de Lado | Fundamento | 7 | Estudo |
| PU10 | Ombro de Passagem | Circulação | 8 | Estudo |
| PU11 | Nó de Punho | Circulação | 9 | Estudo |
| PU12 | Palma entre Guardas | Integração | 11 | Estudo |
| PU13 | Corpo de Escolta | Integração | 11 | Estudo |
| PU14 | Punho de Duas Margens | Manifestação | 16 | Estudo |
| PU15 | Passo do Compromisso | Plenitude | 20 | Estudo |
| PU56 | Punho de Três Medidas | Plenitude 3 / pós-jogo | 24 | Pós-jogo |
| PU57 | Passo de Compromisso Inteiro | Plenitude 3 / pós-jogo | 24 | Pós-jogo |
| FO01 | Tiro Preparado | Fundamento | 6 | Principal |
| FO06 | Foco de Caçada | Plenitude | 12 | Principal |
| FO07 | Disparo de Medida | Fundamento | 4 | Principal |
| FO08 | Guarda do Cano | Fundamento | 7 | Principal |
| FO09 | Tiro de Passagem | Fundamento | 7 | Estudo |
| FO10 | Disparo de Guarda Baixa | Circulação | 9 | Estudo |
| FO11 | Tiro de Fim de Avanço | Circulação | 9 | Estudo |
| FO12 | Disparo de Duas Margens | Integração | 12 | Estudo |
| FO13 | Tiro de Escolta | Integração | 11 | Estudo |
| FO14 | Disparo de Amurada | Manifestação | 16 | Estudo |
| FO15 | Tiro da Medida Final | Plenitude | 20 | Estudo |
| FO56 | Tiro de Três Medidas | Plenitude 3 / pós-jogo | 24 | Pós-jogo |
| FO57 | Mira de Duas Passagens | Plenitude 3 / pós-jogo | 24 | Pós-jogo |

## Verificação

`tests/medida_catalogue.gd` exercita os novos comandos nos três graus: custo, geometrias legais, previsão/impacto, uma ação por turno e recusas sem consumir recursos. `tests/medida_effects.gd` verifica guardas, vigias, controle, escolta, foco, movimento e save/load das 65 técnicas. Suítes antigas cobrem os comandos introdutórios preservados. `tools/capture_medida.gd -- --all-medida` renderiza previsão e impacto de cada novo comando usando a interface real.

## Ícones e animações por função

Prompts, arquivos e procedência da geração: `assets/art/skills/portugal/medida-icon-generation.json`. Os ajustes de enquadramento de ES11 e LA12 estão nas versões v2, com originais v1 preservados. `data/medida_presentation.json` liga os 65 IDs ao ícone e ao perfil de gesto; menu e combate consultam as mesmas referências.

As famílias distinguem precisão, finalização, finta, desarme, corte amplo, projeção, guarda, vigia, passo lateral, recuo, aproximação, escolta, foco e disparo em dois alvos. Guardas e vigias sustentam postura preparada. Saída lateral/recuo iniciam depois do impacto; aproximação chega ao contato antes dele; escolta conduz os dois corpos juntos. Os pés seguem o trajeto legal, incluindo suas esquinas. O impacto permanece em 0,45 s e a apresentação não muda dano, custo, alcance, cultivo ou número de ações. Graus I–III conservam a identidade do mesmo ID.

`tests/medida_assets.gd` valida texturas, alpha, caminhos exclusivos e tamanho de importação. `tests/medida_visuals.gd` valida 65 perfis e a sincronização da apresentação com a execução real. `tools/capture_medida_icons.gd` gera a galeria de 65 ícones; `tools/capture_medida_motion.gd` captura saída lateral, aproximação e escolta pela interface real.

Prévia do conjunto: [65 ícones](medida-icones.png). Captura dos movimentos no jogo: [saída lateral, aproximação e escolta](medida-animacoes.gif).
