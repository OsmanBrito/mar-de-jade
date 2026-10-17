# Primeiro teste jogável — 16 de outubro de 2026

Executa `Jogar.cmd` na pasta do projeto, ou abre `project.godot` no Godot 4.5.1 e usa F5. Escolhe o nome para uma nova campanha ou uma continuação guardada. A campanha segue da infância até à partida e à navegação para a Madeira. Os saves existentes foram conservados.

Revisão posterior: [mapas de combate separados por local](combate-no-mapa.md), conforme a versão atual do Mar de Ferro. A exploração permanece independente e a arte conserva suas proporções.

## Revisão aplicada

- Combate: cabeçalho único, ordem dos turnos, estado do personagem e barra de ações recompostos, sem painéis herdados cobertos por remendos. Botões de mover, desfazer, confirmar e terminar usam áreas distintas.
- Ataque e defesa: barra de timing redesenhada; a defesa simples usa o verde, a perfeita usa o dourado. O botão de execução também responde ao mouse. Os nomes longos ajustam o tamanho da letra e os ícones acompanham o manejo equipado.
- Conversas: caixa dimensionada pelo conteúdo, escolhas com quebra de linha e rolagem quando necessário. O foco acompanha a navegação e novas falas voltam ao início do texto. Cabeçalho com degradê para preservar a cena.
- Campanha: removidos os botões internos de teste e de repetição das cenas. Os blocos adultos passam diretamente para a cena seguinte, preservando a preparação de técnicas e a pausa no cais antes de embarcar.
- Apresentação: materiais comuns para conversas, entrada de nome, inventário e navegação. O suporte de instrumentos usa a arte ilustrada do pátio.

## Validação executada

Os 17 blocos adultos foram percorridos com caminhada, colisões e interações reais, incluindo os sete tipos de encontro, escolhas, pagamento do serviço, preparação da sacola e embarque. O mesmo percurso passou em headless e no renderizador OpenGL. A comparação com o roteiro confirmou as 250 falas aprovadas sem diferenças.

A revisão também executou os testes de nome, abertura, praça, treino infantil, promessa, abertura adulta, transições de entrada, regras, estilos, passivas, rotas, apresentação/impacto/campo/encerramento do combate, inventário, loja, visita ao cais, abordagem, navegação, atmosfera e acabamento do abrigo. Todas as verificações terminaram sem falhas.

Verificações visuais adicionais:

| Ensaio | Resultado |
|---|---|
| Caixas, escolhas, botões e conversa longa | 39 verificações, sem falhas |
| Abordagem, incluindo janelas 1600×900 e 1024×768 | 80 verificações, sem falhas |
| Percurso adulto completo no OpenGL | 41 verificações, sem falhas |
| Inventário e loja no OpenGL | 55 verificações, sem falhas |

Capturas geradas pelo jogo: [combate](../previews/first-test-battle.png), [timing](../previews/first-test-timing.png), [escolha de manejo](../previews/first-test-styles.png), [passivas](../previews/first-test-passives.png), [abordagem](boarding-start.png).

O teste automatizado verifica o funcionamento e a composição da interface. O primeiro teste humano deve observar o ritmo das conversas, a dificuldade dos timings e o equilíbrio das recompensas. Não foi produzido um executável exportado; o arranque usa o Godot já instalado.
