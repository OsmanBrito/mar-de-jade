# Menu e aprendizado

A referência é o Mar de Ferro atual (`jogo/scripts/journey_menu.gd`): seleção de personagem, lista de práticas e ação no próprio detalhe.

- Navegação lateral agrupada: personagem, pertences, jornada e jogo. Preserva entradas de páginas já usadas pela campanha.
- Itens mantêm ícones, comparação e ação destacada; ilustração menor deixa espaço para os efeitos.
- Abaixo de 1150 px o resumo lateral é recolhido para proteger lista e detalhes. Personagem continua acessível pela navegação.
- Técnicas e passivas têm seleção de pessoa e contador de vagas. A lista assinala as práticas preparadas.
- Manuais adquiridos aparecem em Técnicas. Aprender e preparar acontecem no próprio detalhe, sem deslocamento adicional à armaria ou troca para Evolução.
- Avaliação, autorização, fundamentos, recuperação e pausa segura continuam necessários. Comprar e aprender é uma transação única; estudar um manual antigo não cobra uma segunda vez. Aprender preserva o repertório preparado.
- Preparação persiste pelo mesmo inventário/desenvolvimento da campanha. Seis técnicas e quatro passivas por pessoa; defesa por reação não ocupa vaga.

Verificação: `tests/menu_learning.gd`, suites existentes de inventário, desenvolvimento, liderança, estudos e interface. `tools/capture_menu_revision.gd` verifica o caminho de aprender/preparar pela UI real e captura 1280×800 e 960×600 em `.qa-runtime/menu-review`.

O catálogo de Técnicas mostra as 65 técnicas da Medida, com filtros Todas / Preparadas / Aprendidas / Disponíveis, manejo e cultivo. Disponíveis reúne técnicas autorizadas ainda não aprendidas; preço e saldo continuam validados na compra. A compra direta por ouro ou vale aprende no mesmo passo, preserva vagas e recursos e valida autorização, avaliação e fundamento antes de cobrar. Manuais antigos adquiridos conservam a ação Aprender.

## Diário e liderança

Missões abre cartões de compromissos em curso, concluídos e arquivo. O detalhe apresenta objetivo e acompanhamento; a carga mostra a contagem dos três registros. Arquivo preserva a consulta completa anterior. Técnicas inclui filtro Preparadas e ícone no detalhe.

Grão-Mestre tem três perguntas opcionais (dever, força e carga), audiência expandida e reconhecimento após investigação. Os diálogos são registrados pelo histórico normal de inspeção; perguntas não alteram missão nem concedem recursos. O comendador conserva a função quando o Grão-Mestre está ausente. Teste order_leadership percorre os três diálogos na cena real e verifica ausência de alterações de progressão.

Catálogo completo da Medida implementado em 22/10/2026: ver [técnicas, requisitos e graus](tecnicas-medida-completas.md). Os filtros de manejo e cultivo substituem a lista restrita aos cinco estudos introdutórios.


## Clareza da Ordem · 22/10/2026

Secretaria e instrutor abrem o mesmo catálogo visual; o posto de estudo tem atalhos para Técnicas, Passivas e Evolução. O catálogo não produz uma conversa de 65 botões. As APIs antigas de compra continuam validadas para compatibilidade.

Cada linha informa preparada/equipada, conhecida na reserva, manual adquirido, disponível ou bloqueada. Defesa por reação informa que não ocupa vaga. A seleção permanece realçada e o detalhe abre automaticamente; a raridade não usa mais o rótulo ambíguo de nível. Passivas têm filtros Todas / Equipadas / Conhecidas e mostram como desbloquear as iniciais ainda não conhecidas, sem permitir equipá-las nem comprá-las. Filtros reiniciam ao abrir o caderno.

Captura de revisão também verifica que consultar uma passiva bloqueada não altera o progresso nem oferece ação, que o filtro Equipadas corresponde às vagas reais e que Preparadas exclui a defesa por reação. Capturas em 1280×800 e 960×600.
