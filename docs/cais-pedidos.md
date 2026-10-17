# Lisboa — primeiro ciclo de pedido local

**Atualização de 17/10:** esta página conserva a primeira entrega. Agora também há **A conta das entregas**, **Uma sacola preparada** e exploração após a refeição. O fundo de bordo está identificado separadamente da carteira pessoal. Ver [estado atual e validação consolidada](reviews/arco-01-fechamento-da-revisao.md).

Implementado no projeto editável. Depois de desimpedir a passagem e concluir o socorro, o jogo abre uma pausa de exploração do cais. Duarte espera no pontão para continuar a sequência da refeição. A visita antes do embarque conserva o mesmo pedido e permite retomá-lo.

## O que jogar

- Conversar com o **oficial da oficina**, a **vizinha**, a **pescadora** e o **trabalhador do pontão**, com E / A junto deles.
- Descobrir **A roda presa** na oficina e aceitar ou adiar a ajuda.
- Examinar o carro, observar as pistas e identificar a falta da cavilha; puxar a corda não resolve o problema e recebe uma resposta específica.
- Encontrar o trabalhador do pontão e receber uma **cavilha de eixo**, objeto protegido na sacola.
- Voltar ao carro e combinar o apoio da carga com o oficial antes de encaixar a peça. Tentar fazer tudo sozinho recebe uma explicação e permite rever a ação.
- Ver a encenação do reparo, o deslocamento do carro e a liberação da posição anterior para caminhada.
- Falar novamente com o oficial e receber **12 de ouro e uma ração**, uma única vez.
- Voltar à vizinha e ao oficial para ouvir respostas que reconhecem a conclusão.

**J** abre **Pedidos**; a mesma página está no menu do personagem, acessível por controle. O registro conserva objetivo atual e acontecimentos já vividos. Esc / B fecha conversas locais sem avançar a história principal. No pontão, a primeira visita oferece **Levar a refeição**; a segunda oferece **Embarcar com Duarte**, com aviso se o pedido ainda estiver em curso.

## Conteúdo e persistência

O conteúdo original usa o ID local `C01-LIS-01`, separado da numeração Oxx do corpus. Não substitui nem renumera as opcionais existentes. É o primeiro ciclo implementado para fundamentar a ampliação da cidade; não constitui a entrega dos demais pontos da revisão do arco.

O save do capítulo passa à versão 3 e continua aceitando versões 1 e 2. Etapa, peça de missão, recompensa e consequência do cenário são conservadas juntas. A etapa é validada antes de alterar o estado atual; saves incompatíveis com a presença da cavilha são recusados. Concluir, conversar de novo, reiniciar a etapa ou recarregar não repete o pagamento. O pedido não é marcado como fracassado ao embarcar; seu estado fica preservado, sem prometer revisitas de capítulos ainda não implementados.

As 250 falas aprovadas do fluxo principal permanecem intactas. As conversas novas estão em dados separados. A pausa liga o socorro à refeição e não interrompe o atendimento urgente.

**Ouro** substitui “reais” na interface de Portugal e navegação, nas mensagens de transação e no catálogo. Os valores numéricos foram conservados. A distinção entre carteira pessoal e fundo naval de 180 unidades ainda pertence à revisão mais ampla da economia; esta entrega altera a denominação, sem afirmar que as carteiras já foram unificadas.

## Arquivos

- [Falas, objetivos e recompensa](../data/chapter_01/local_requests.json).
- [Estados e validação](../scripts/chapter/local_request_state.gd).
- [Interações, encenação e consequência visual](../scripts/chapter/lisbon_requests.gd).
- [Integração com o percurso e o embarque](../scripts/chapter/harbor_visit.gd).
- [Teste do ciclo completo](../tests/lisbon_requests.gd).
- [Captura isolada para revisão visual](../tools/capture_lisbon_request.gd).

## Verificação

O teste do pedido usa caminhada e colisões reais, teclado e controle. Verifica recusa/aceitação, pistas, decisão incorreta recuperável, obtenção e proteção da peça, reparo, mudança da navegação, retorno, recompensa única, salvamento em etapas intermediárias, migração de save antigo, dados inválidos, respostas posteriores, diário, retorno à refeição e retomada na visita final. Compara os hashes dos saves do jogador antes/depois e grava somente fixtures próprias.

Também foram exercitados percurso adulto, rotas/retomada, inventário/loja, visita ao cais, interface e navegação. As capturas são geradas no OpenGL pelo próprio jogo, não montagens.

Resultados finais: pedido local **82** verificações no OpenGL, percurso adulto **42**, visita ao cais **34**, inventário/loja **56**, rotas **15**, interface **39** e navegação **88**, todos sem falhas. A comparação do conteúdo principal confirmou **250 falas em 17 blocos**, sem diferenças. O teste do pedido confirmou que os arquivos de campanha, perfil e navegação do jogador permaneceram intactos.

- [Escolhas da inspeção](../previews/lisbon-request-choices.png).
- [Conversa na oficina](../previews/lisbon-request-offer.png).
- [Carro após o reparo](../previews/lisbon-request-repaired.png).
- [Registro de pedidos em janela 1024 × 768](../previews/lisbon-request-journal-1024.png).

Ainda requer avaliação humana da descoberta, interesse da tarefa, deslocamento e clareza das decisões. Os testes automatizados confirmam funcionamento e composição, não diversão.
