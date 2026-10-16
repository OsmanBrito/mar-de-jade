# Validação do primeiro recorte — 14/10/2026

Atualização após a conversão de autoria: o percurso foi novamente executado em Windows OpenGL com 28 verificações sem falhas, já com zoom 1,25, cápsula dos pés e fachadas aprovadas. Foram acrescentadas 16 verificações de autoria sem falhas e inspecionadas capturas do cais, interior e porta. Ver [map-authorship.md](map-authorship.md). Os parágrafos abaixo registam o histórico anterior e os seus limites à data.

## Resultado

O percurso integrado passou **28 verificações**, tanto em headless como na renderização Windows OpenGL 3.3 de uma RTX 3060. As capturas foram produzidas pelo próprio viewport Godot e inspecionadas: cais, interior e diálogo. O último relatório headless está em `tests/playtest-report.json`; o resultado da execução gráfica, extraído do log real, está em `tests/playtest-rendered-report.json`. O programa de ensaio fecha automaticamente e não faz parte do percurso normal do jogo.

Verificado: spawn em solo, grelha e cais conectados, bloqueio do rio, bindings de teclado/direcional/analógico, movimento físico, paragem no menu, colisão com edifício, percurso por clique, proximidade, opções de conversa, adiamento sem perder disponibilidade, transição exterior/interior, consulta do registo, retorno e conclusão idempotente. Persistência: escrita e substituição com backup, round-trip completo, rejeição de coordenadas inválidas e versão futura, sem mutação do estado após rejeição.

Foram corrigidos durante o teste: sincronização de input no passo de física, seleção de interação no momento do comando, limites dos recortes do atlas, enquadramento e contraste do HUD. A cena final não registou erros de script ou de renderização.

## Limites

Revisão das casas após as capturas junto à porta: footprint traçado pela base do anexo, barris e fachada, em coordenadas proporcionais à célula do atlas. A fachada inclinada passou a ser ordenada em tiras de 8 pixels pela altura local do chão, preservando a imagem original e permitindo que a personagem à frente da porta apareça inteira. Inicialização headless no Godot 4.5.1 concluída com código 0, sem erros de scripts; permaneceu o aviso do repositório de certificados Windows. O resultado visual e o percurso manual junto às paredes ainda precisam de confirmação no jogo.

Depois do percurso inicial, a câmara passou a iniciar em zoom 1,25. Em resposta ao feedback, as passadas laterais/traseiras foram redesenhadas e a animação passou a responder ao comando mesmo contra um obstáculo. Após relato de penetração antes do bloqueio, a cápsula circular do jogador foi centrada no ponto dos pés e ampliada; os footprints dos props foram estendidos nas bordas de contacto e as camadas dos corpos estáticos ficaram explícitas. O relatório de 28 verificações abaixo antecede estas alterações; esta revisão ainda não foi percorrida novamente no Godot.

Comando físico ainda não ensaiado. Não foi medido desempenho em hardware mínimo ou executado um teste de longa duração. Não há áudio nesta fase. Arte, repetição dos pisos e animações permanecem candidatas a revisão; não são direção artística final de toda a campanha. Os testes de persistência não simulam falha de energia ou disco.

Na sandbox, o Godot emitiu aviso de acesso ao repositório de certificados Windows; a execução gráfica fora da sandbox não o apresentou. A tentativa desnecessária de export foi interrompida e os seus ficheiros removidos após correção do utilizador. A entrega é apenas o projeto editável, sem preparação de versões ou executáveis.

## Reprodução

Executar com Godot 4.5.1:

```powershell
& 'C:/Users/gamer/Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe' --headless --path . --script res://tests/playtest.gd
```

O teste grava fixtures/relatórios apenas em `tests/`. Para capturas, executar a mesma cena de teste com renderização Windows em vez de headless. Não exportar versões: o utilizador trabalha diretamente no projeto Godot.
