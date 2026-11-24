# Lisboa — revisão integrada de 27/10/2026

O percurso existente foi revisto como um capítulo jogável: a infância no convento, a aventura com Leonor, a promessa, o primeiro serviço adulto, o trabalho na cidade, a avaliação, a recuperação, a aprendizagem e o embarque na Botafogo. A cidade mantém a praça, as duas descidas, o mercado, os pontões e a casa da Ordem ligados aos mesmos destinos de campanha.

Esta revisão fecha problemas encontrados ao percorrer e conferir esses conteúdos. Não muda o desfecho de Leonor, o prazo de dez anos, a idade do protagonista ou a origem desconhecida dos olhos. O Convento de Cristo continua em Tomar; a casa de Lisboa pertence à ficção do jogo.

## Encenação e roteiro

Na promessa, Leonor levanta-se, caminha até aos instrumentos, recolhe-os e reserva o par. Os pequenos intervalos, a água e a saída respeitam a pausa. A câmara termina com a criança e o par reservado; a oclusão acompanha também os instrumentos, para que uma fachada não esconda o gesto final. As catorze falas centrais permanecem iguais ao roteiro aprovado.

No abrigo adulto, o protagonista caminha até à sacola e à porta com animação direcional. A sacola acompanha-o ao alcance da mão. As duas escolhas conservam as suas falas aprovadas; a introdução do primeiro serviço foi encurtada e ligada à farinha, à enfermaria e ao pátio. A passagem infância → adulto → cidade usa a transição coberta existente.

Os cinco moradores têm vozes distintas e respostas ao socorro, à demonstração, à recuperação e à partida. As lembranças de pedidos exigem que o jogador os tenha concluído. Regressar do navio à cidade não pressupõe uma viagem já realizada. As conversas opcionais não revelam o confronto reservado com Leonor nem concedem recompensas de pedidos por conversar.

## Atividades e orientação

Os quatro pedidos locais conservam etapas, regresso ao responsável e recompensa única. A investigação da Ordem distingue-se da contagem da pescadora: é necessário decidir se uma reposição urgente deve ser autorizada, confrontando os documentos e a entrega já recebida. Uma conclusão incorreta pode ser corrigida.

O treino livre é apresentado nos serviços e nas conversas da liderança, com acompanhamento até à armaria. Pode ser usado depois do primeiro manejo, sem exigir audiência. O início exige proximidade física; abandonar a prática devolve o jogador ao serviço sem consumir os seus recursos pessoais ou avançar a história.

## Interface

Durante a exploração, o compromisso principal e o pedido acompanhado ficam separados da ação contextual. Os botões Caderno e Menu abrem as páginas reais do menu, com pausa e sem avançar o diálogo. Conversas e cenas encenadas escondem esses botões.

O caderno distingue pedidos em curso, concluídos e arquivo. O serviço de água da casa deixa de aparecer em curso depois de concluído. A navegação do menu acompanha a ampliação do texto; as conversas da liderança permitem alcançar todas as opções nas janelas menores. O vocabulário visível foi uniformizado para PT-PT.

## Executar e verificar

Usar `Jogar.cmd` na raiz oficial. Uma nova campanha começa na infância; as continuações existentes continuam disponíveis. Para avaliar toda a nova abertura, iniciar uma campanha nova.

```powershell
& tools/test_lisbon_completion.ps1
```

O executor reúne 38 suítes, incluindo o percurso adulto completo, navegação física, combate, interface, pedidos, recompensas e retomadas. Cada suíte usa dados isolados em `.qa-runtime`; os saves e preferências normais do jogador não são utilizados. `-SkipFullCampaign` omite apenas a repetição integral dos 17 blocos adultos.

Resultado da revisão de 27/10: **1.926 verificações aprovadas nas 38 suítes**, sem falhas de asserção ou de script. Os 17 blocos adultos chegaram à partida usando os controladores reais de caminhada, colisão, interação e combate. A revisão nativa adicional conferiu a UI em 960 × 600 e 1440 × 900 com texto a 120%, a caminhada exterior e a encenação da promessa. O ambiente emitiu avisos de certificados do Windows e de gravação do cache gráfico, sem impedir os testes ou as capturas.

Capturas nativas de revisão:

- `tools/capture_lisbon_completion.gd`: oito momentos da promessa, abrigo e entrada adulta, em `.qa-runtime/lisbon-completion/`.
- `tools/capture_lisbon_direction.gd`: caminhada real praça → mercado → pontão, distritos, oclusão e interface, em `.qa-runtime/lisbon-direction/`.
- `tests/lisbon_ui_closure.gd -- --capture`: caderno, exploração, comércio e liderança com texto ampliado, em `.qa-runtime/lisbon-ui/`.

Os testes verificam funcionamento e continuidade; as capturas permitem rever a composição. Ritmo de leitura, emoção e preferência pelo visual continuam a ser avaliados numa partida normal. O arranque utiliza o Godot instalado, sem exigir um executável exportado.
