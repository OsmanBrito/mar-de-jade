# Escolha de arma do herói

Revisão de usabilidade em 19/10/2026, após relato de dificuldade para escolher a arma.

- Em terra: Pausa → Armas. A ficha Personagem também começa com Escolher arma do herói; Equipamento conserva um atalho.
- A tela separa armas de roupas, consumíveis e objetos da história. Mostra a arma em uso e distingue as que estão na sacola das que precisam ser compradas.
- Selecionar uma arma mostra alcance, descrição e comparação. A confirmação Equipar no herói fica no alto e recebe foco para teclado/controle. Apenas consultar não equipa.
- Desarmado é uma opção explícita, sem exigir vender ou apagar a arma anterior.
- Armas ausentes oferecem um caminho para a loja já filtrada em Armas. O requisito de aprender com Tomé é explicado; nenhum item, aprendizado ou recurso é concedido pela tela.
- Na missão com Tomé, uma tela própria apresenta as cinco opções com imagem e descrição curta. Selecionar destaca a escolha sem iniciar combate; Escolher como arma do herói confirma, recebe e equipa a primeira arma e continua a missão diretamente.
- Tomé concede o fundamento e os aprendizados básicos correspondentes somente à opção escolhida. Não há exigência de combate de teste, aula prática ou comparação com outras armas. A prática livre permanece opcional. Confirmar novamente não concede outra arma gratuita.
- A bordo: Pausa → Armas do herói. A troca conserva o perfil levado à abordagem e mantém a restrição de porto/águas seguras.

Verificação: 199 asserções aprovadas em weapon_choice (42), player_inventory (58), interface_closure (34) e combat_economy (65), sem erros de script nos registros finais. A suíte nova cobre escolha direta nos cinco manejos, arma recebida e equipada uma única vez, fundamento escolhido, continuidade da missão sem inserir combates, prévia sem alteração, confirmação por teclado, compra filtrada, desarmado e continuidade a bordo. O teste de economia mantém seu aviso anterior de objetos retidos no encerramento.

Capturas nativas conferidas em .qa-runtime/weapon-choice/, incluindo janela de 960×600 e texto a 120%. O Godot usa área virtual escalada; os limites da interface foram verificados nas coordenadas dessa área. Logs, capturas e backups são temporários.
