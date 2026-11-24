# Ponto 8 — combate, preparação e economia do primeiro arco

## Resultado

Fechamento técnico em 19/10/2026. Os cinco manejos são viáveis na primeira abordagem no cenário automatizado descrito abaixo. Os valores atuais foram mantidos: não houve evidência nesse cenário para alterar dano, preços ou recompensas. Isso não certifica equilíbrio entre estratégias nem compreensão por jogadores iniciantes.

## Mudanças

- Comparação de equipamentos calcula atributos finais antes/depois, incluindo a potência base do manejo. Espada de aprendiz → machado mostra +7 de potência do básico, em vez de apenas +1 de bônus da peça. Machado → faixas mostra −13, preservando a opção desarmada. Mostra também o alcance do básico; dano final continua dependendo de defesa, posição e timing.
- Passivas mostram dono, condição conhecida/equipada e quatro vagas próprias por pessoa. Aprender continua sem equipar automaticamente.
- Prática livre apresenta explicitamente básico, fundamento e dois exercícios temporários. Os exercícios não são aprendidos nem seguem para a abordagem.
- Textos de água e ligaduras explicam o uso na Bolsa durante abordagem, alvo próprio/aliado adjacente e custo de uma ação principal. Ração continua sendo uma recuperação fora de combate.
- Previsão de suprimentos mantém os campos de vida/alento coerentes com a dose fixa de Jade e mostra recuperação efetiva e excedente. Água com um ponto faltando mostra 1 recuperado e 4 excedentes; ligadura com 22 faltando mostra 22 e 3.
- Teste dos cinco manejos distingue as sete passivas do protagonista da passiva própria de Duarte, que também pode estar aprendida ao concluir o percurso.

## Verificação por requisito

| Requisito do ponto 8 | Evidência |
| --- | --- |
| Cinco escolhas iniciais viáveis | Todos venceram a abordagem com timing Bom, básicos, movimento legal, orientação automática para o adversário e Duarte; sem passivas equipadas, técnicas especiais ou consumíveis usados pelo agente de combate. |
| Identidade mecânica e audiovisual | Alcances e definições partilhados entre terra e bordo; lança exige duas casas no fundamento, fogo exige alinhamento e linha livre, machado prepara proteção sem dano. Animação, disparo, contato, recuperação e pausas distintas foram verificados pela suíte combat_feel. |
| Técnicas versus demonstrações | Apenas fundamento aprendido disponível na abordagem; exercícios C01-DEMO ficam na prática livre, agora descrita explicitamente. |
| Passivas e Duarte | Interface diferencia dono, conhecimento e equipamento; suíte de passivas executa benefícios e compara previsão com impacto. |
| Custos, alcance, postura, previsão | Novo teste executa básicos dos cinco manejos e confere vida/postura contra a previsão; fundamentos cobram o custo exibido, qi zero impede técnica e permite básico; obstáculos e diagonais bloqueiam o fundamento de fogo. |
| Aprender timing | Regras e apresentação verificadas; entendimento espontâneo de iniciantes ainda depende de playtest humano. |
| Recompensas, preços e estoque | Serviço obrigatório paga 40 uma vez; gibão 24 + ligadura 6 + água 3 = 33, sobrando 7. Primeira arma é oferecida por Tomé. Compra/venda não gera lucro. Estoque limitado e persistente. |
| Compra útil antes do embarque | Gibão comprado aparece na abordagem com vida máxima 112 e proteção 2. Equipar preserva os recursos atuais; não cura. Capa, botas e acessórios oferecem alternativas ao gibão. |
| Suprimentos | Ligadura recupera até 25 de vida; água até 5 de alento; ração até 15 de vida e 3 de alento fora de combate. Consumo unitário, limites e recusa de desperdício em alvo cheio verificados. |
| Equipamentos de Ferro | Oito itens do lote atual mantêm IDs, origem e bônus suportados por Jade; compra, estoque, restrições, combate em terra/bordo e save/load verificados. |
| Preparação em Lisboa | Arma, traje, técnica, passivas, recursos e suprimentos usam o mesmo estado na abordagem. |
| Carteira e fundo de bordo | Carteira pessoal permanece separada dos 180 iniciais de bordo; prêmio da abordagem vai ao fundo da tripulação. Continuidade e ficha de bordo verificadas. |

## Cenário automatizado de viabilidade

Campanha reiniciada por manejo; primeira arma local correspondente oferecida, gibão comprado e equipado, uma ligadura e uma água compradas. Vida inicial 100 (equipar não cura), alento 20, postura 100. Nenhum pedido opcional é necessário.

O condutor procura o inimigo vivo mais próximo, move pelas casas alcançáveis, usa básico com qualidade Bom e termina orientado para o inimigo. A IA inimiga real resolve os turnos; defesa Bom para os aliados. Não há garantia de vitória para outra estratégia, timing ou estado inicial.

| Manejo | Turnos de unidades processados | Vida final protagonista | Vida final Duarte |
| --- | ---: | ---: | ---: |
| Espada | 10 | 70 | 98 |
| Lança | 10 | 70 | 98 |
| Machado | 8 | 80 | 109 |
| Fogo | 10 | 70 | 98 |
| Desarmado | 12 | 65 | 98 |

Machado é mais eficiente nesta estratégia de aproximação e básicos; lança/fogo têm vantagens de distância que o condutor simples não explora plenamente. Não se buscou igualar os resultados por alteração artificial de valores.

## Validação

481 verificações aprovadas em 11 suítes, sem falhas de asserção ou erros de script:

| Suíte | Verificações |
| --- | ---: |
| combat_economy (nova, com renderização e inspeção da comparação no menu) | 65 |
| arc_balance | 38 |
| chapter_rules | 38 |
| player_inventory | 57 |
| chapter_styles | 13 |
| campaign_continuity | 34 |
| boarding | 78 |
| chapter_full | 62 |
| chapter_passives | 19 |
| combat_feel | 36 |
| ferro_integration | 41 |

A campanha completa percorreu os 17 blocos, com duelo, escolha de manejo, escola e defesa perfeita. Dois processos de QA emitiram aviso de objetos retidos ao encerrar (arc_balance e combat_economy), sem falha funcional nos resultados; esse aviso não equivale a uma medição de memória em sessão prolongada.

Captura local de revisão: .qa-runtime/balance-close/equipment.png. Fixtures modificadas pelos testes foram restauradas.

## Validação humana restante

- Iniciante aprender timing e orientação sem orientação externa.
- Comparar cinco manejos com uso real dos fundamentos, distância, consumíveis e passivas.
- Avaliar satisfação das compras, quantidade de informação e utilidade de cada suprimento.
- Sessão prolongada para medir memória e estabilidade.

Próximo ponto: 9 — interface, controles e áudio.
