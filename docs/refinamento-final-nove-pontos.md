# Refinamento final dos nove pontos

Passagem de implementação em 19/10/2026, posterior a `correcoes-revisao-nove-pontos.md`. Esta revisão executa os refinamentos de código e recursos que ainda estavam recomendados. Os documentos anteriores conservam o histórico; este é o estado mais recente.

## Mudanças por ponto

| Ponto | Refinamento entregue nesta passagem | Evidência |
| --- | --- | --- |
| 1. Integrações | Consulta do salvamento mostra local, carteira e recursos realmente gravados. Durante a visita, consulta o navio estacionado da mesma campanha. Assuntos dos moradores passam a integrar a persistência. | Cinco ciclos completos de estado: desembarque, compra, gravação, reembarque e leitura do mesmo arquivo, além do teste anterior de caminhada real até o pontão. Recursos pessoais e de bordo permanecem separados. |
| 2. Circulação | Rua poente identificada pela roda de oficina e rua nascente pelos cabos, com nomes de localização no HUD. Marcas de uso junto dos dois caminhos. | Capturas nativas dos dois acessos e auditoria do grafo real de navegação, descrita abaixo. |
| 3. Arte | 16 bustos novos de interlocutores, com proporção comum e recortes nativos; os dois retratos próprios do protagonista permanecem. Transições suaves entre passos dos animais, preservando os quadros de preparação e contato dos ataques. Vizinha passa a usar identidade feminina tanto no mapa quanto no retrato. | Galeria nativa de 18 retratos e teste dos limites dos recortes. Galeria de poses e percurso pelas portas do mapa. |
| 4. Habitantes | Cinco fases de trabalho com durações distintas por morador: preparar, trabalhar, pousar, conferir e descansar. Gestos de martelo, cabo, recibo e louça; interrupção pela conversa e retomada pelo controlador existente. Uma reação por acontecimento, seguida de assuntos alternados; carregar conserva o próximo assunto. | Cinco ciclos de rotina distintos, teste de gravação em disco e 133 verificações de cidade viva. |
| 5. Pedidos | Resultados físicos derivados das quatro conclusões da Ribeira: carga pronta, conta conferida, reserva e amarra. Aplicar novamente não duplica objetos nem concede prêmio. Orientações repetidas ficam mais curtas sem retirar opções. | Estado concluído reaplicado no mapa real, capturas das quatro áreas e 71 verificações do conteúdo opcional. |
| 6. Infância | Leitura contextual junto dos cascos, ramo, ponte e subida final; respeita distância e etapa, sem marcar descoberta automaticamente. O cronômetro opcional também inclui releitura de conversas. | Testes de proximidade/progresso, floresta completa e contagem real de leitura com mundo pausado. A meta de 30–45 minutos continua sem aprovação humana. |
| 7. Encenação | Nas conversas enquadradas de até três participantes, quem escuta orienta-se para quem está falando. Mantêm-se as pausas e os movimentos já encenados do socorro, recuperação e partida. | 49 verificações de encenação e 62 do percurso adulto completo, sem alterar as falas canônicas. |
| 8. Combate | Resumo pessoal antes da abordagem e na ficha: recursos do protagonista e de Duarte, suprimentos, alertas de ferimento, alento e postura. Comparação adicional de posicionamento, técnica, timing falhado, poucos recursos e três roupas. | 35 combates completos, nos cinco manejos; 95 verificações. Preparação usa o dinheiro do serviço obrigatório, sem recompensas opcionais. |
| 9. Interface e áudio | Prévia de carregamento em terra, infância e viagem. Ganhos musicais calculados a partir de medições individuais; músicas originais preservadas. Regressão de foco, fonte ampliada, remapeamento, diário e controle simulado. | Medição FFmpeg, importação Godot e suítes de interface, controles, música e inventário. Controle físico e audição comparativa permanecem necessários. |

Os resultados físicos ficam no cenário, sem novas legendas permanentes sobre o chão. O caderno e as respostas dos moradores continuam explicando as consequências.

## Salvamentos

O capítulo usa agora versão **12**. `city_topics` guarda apenas identidade do morador, contexto e posição na alternância de assuntos; valores são validados antes de qualquer mudança no estado e normalizados para inteiros após JSON. Versões 1–11 continuam aceitas pelos migradores existentes; a versão 11 recebe assuntos vazios, sem inventar conversas. Um novo jogo limpa esses registros.

A prévia descreve o arquivo disponível, não os valores atuais ainda não salvos. Na visita, verifica a identidade da campanha antes de ler o navio. Nenhum desses painéis recupera vida, concede recursos ou substitui o arquivo.

## Circulação medida

Distâncias obtidas do caminho navegável real, com velocidade normal de 140 px/s. Tempos são limites de deslocamento contínuo; excluem leitura, desvios, interação, corrida e decisões.

| Percurso amostrado | Distância | Caminhada sem paradas |
| --- | ---: | ---: |
| Portaria → Ribeira | 2.574 px | 18,4 s |
| Rua poente → amarra do batel | 981 px | 7,0 s |
| Rua nascente → registo do armazém | 1.113 px | 7,9 s |
| Mercado → cozinha | 376 px | 2,7 s |

Os dois desvios continuam associados a atividades existentes: batel/estaleiro a poente e recibos/armazém a nascente. Não foi criado um atalho obrigatório nem removida exploração com base nesses tempos. Cansaço por repetição depende da partida natural.

## Retratos e proveniência

Recursos criados com o **image_gen integrado**, usando os sprites atuais como referência visual e descrições das identidades restantes. O protagonista conserva seus recursos existentes. Os originais dos sprites não foram alterados. Enquadramento e transparência são tratados pelo Godot.

- [Atlas principal](../assets/art/portraits/cast-busts-v2.png): 12 interlocutores.
- [Atlas complementar](../assets/art/portraits/supporting-busts-v2.png): ferido, observador, criança e combatente.
- Prompts completos, ferramenta, referências e hashes: [metadados do atlas principal](../assets/art/portraits/cast-busts-v2.json) e [metadados complementares](../assets/art/portraits/supporting-busts-v2.json).

Foi conferida a galeria renderizada com os 18 retratos. A aprovação artística definitiva continua sendo do usuário.

## Música medida

Análise `loudnorm` do FFmpeg 8.1, medindo os arquivos completos. Ganho constante calculado por faixa para alvo de **−22 LUFS integrados**, limitado a **−2 dBTP**. São valores de arquivo mais ganho, antes das opções de volume e reduções de cena já existentes. Não equivalem a uma normalização dinâmica nem a uma aprovação auditiva.

| Contexto | LUFS de entrada | Ganho |
| --- | ---: | ---: |
| Acolhimento | −14,53 | −7,47 dB |
| Cidade / porto | −14,23 | −7,77 dB |
| Floresta | −12,22 | −9,78 dB |
| Promessa | −13,81 | −8,19 dB |
| Recuperação | −11,47 | −10,53 dB |
| Treino | −14,77 | −7,23 dB |
| Duelo | −11,22 | −10,78 dB |

As medições e ganhos estão no manifesto musical. Volume percebido, transições, efeitos procedurais e relação entre música, ambiente e efeitos precisam de uma sessão de audição.

## Combate ampliado

Cada manejo enfrenta sete condições: preparação comum, timing falhado, alento inicial zero, Duarte ferido, uso de técnica com posicionamento, capa e botas. Os 35 encontros terminaram com vitória no controlador automatizado; todos mantiveram recursos dentro dos limites. O controlador movimenta também Duarte e procura uma posição válida antes de atacar.

Isso evidencia viabilidade com essas decisões, mas não demonstra dificuldade adequada para iniciantes. Não se compara diretamente a contagem de turnos desta estratégia com o controlador mais simples do documento do ponto 8. Preços, dano e recompensas não foram alterados sem evidência de um problema concreto.

## Validação desta passagem

**1.250 verificações aprovadas em 19 suítes**, sem falhas de asserção nem erros de script nos registros finais. Contagem de uma execução final por suíte, sem somar repetições.

| Suíte | Verificações |
| --- | ---: |
| full_polish — nova, com renderização | 135 |
| combat_stress — nova | 95 |
| city_life | 133 |
| player_inventory | 57 |
| map_art_closure — com renderização | 90 |
| chapter_music | 88 |
| chapter_staging | 49 |
| chapter_full | 62 |
| forest_hunt | 67 |
| integration_closure | 30 |
| navigation | 88 |
| interface_closure | 34 |
| boarding | 78 |
| campaign_continuity | 34 |
| review_fixes | 41 |
| optional_closure | 71 |
| childhood_controls | 41 |
| childhood_bond | 49 |
| childhood_timing — com medição ativada | 8 |

Importação pelo editor Godot 4.5.1 concluída sem erros de script. Renderizações conferidas no modo Compatibility, NVIDIA RTX 3060. Capturas e relatórios ficam em `.qa-runtime/full-polish/` e `.qa-runtime/map-art-close/captures/`; são temporários. Fixtures geradas pelas suítes foram restauradas aos bytes anteriores à execução. O aviso de objetos retidos no encerramento de `review_fixes` continua registrado; esta passagem não certifica memória em sessão prolongada.

## Aprovação de experiência ainda necessária

A implementação acima está entregue. Para declarar o arco 100% pronto, permanece o trabalho empírico do ponto 10:

1. Partida nova, sem atalhos e com leitura natural, cobrindo infância até navegação e primeira abordagem; medir os 30–45 minutos da infância com o cronômetro local opcional.
2. Pessoas que desconhecem o roteiro: uma explora e outra segue a história; registrar perdas de direção, entendimento das pistas, repetição, emoção e motivos para parar.
3. Jogadores iniciantes experimentando os cinco manejos, timing, passivas, suprimentos e compra antes da partida.
4. Controle físico, janela pequena e texto ampliado; leitura de objetivos com áudio desligado e imagem pouco saturada.
5. Audição de cidade, interiores, floresta, combate, recuperação e viagem, com aprovação da mixagem e dos efeitos.
6. Outro computador e sessão prolongada, medindo FPS, travamentos e memória.
7. Aprovação final do usuário sobre arte, ritmo, som e experiência.

Esses resultados não podem ser substituídos pelos testes automatizados. Não há uma aprovação humana presumida ou uma promessa de duração já cumprida.
