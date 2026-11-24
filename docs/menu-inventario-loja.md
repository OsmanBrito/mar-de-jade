# Personagem, inventário e loja de Lisboa

Implementação inicial jogável em `scripts/chapter/player_menu.gd` e `player_items.gd`, integrada na sequência adulta `chapter_flow.tscn`.

## Acesso e interface

Esc / Start abre o menu sem substituir a fala atual. C abre Personagem, I Inventário, K Técnicas e P Passivas. Setas, rato e direcional navegam; Enter / A confirma; Esc / B retoma. O menu pausa o mundo e devolve o foco anterior ao fechar. Não abre durante animações ou combate, que conserva a própria pausa.

Abas: Personagem, Inventário, Equipamento, Técnicas, Passivas, Loja de Lisboa e Sistema. Há arte existente, filtros, raridade em texto, listas e detalhes com scroll, comparação com ganhos/perdas e revisão antes de vender, carregar ou reiniciar. Técnicas mostra apenas práticas aprendidas; os detalhes das cinco técnicas iniciais vêm das regras reais. Passivas mantém quatro vagas por personagem e a propriedade de Duarte.

A loja é opcional pelo menu nas pausas entre etapas do cais, serviço, praça e pátio; também na escolha do manejo. Depois de preparar a sacola, há uma pausa de exploração no cais com comerciante físico: aproxima e usa E / A para negociar, depois procura Duarte no pontão para embarcar. Não funciona durante uma tarefa urgente, a recuperação ou no convés. Ver [comerciante e embarque](comerciante-lisboa.md); as falas aprovadas permanecem intactas.

## Economia inicial

O protagonista começa sem reais. Desimpedir a passagem no cais dá **40 reais uma única vez**, com aviso ao concluir a etapa. Preços iniciais: armas 26–38; faixas 8; trajes 18/24; botas 16; acessórios 6/20; ligaduras 6; ração 5; água 3. Estoque inicial: duas unidades por equipamento e seis por suprimento. Vender rende metade do preço arredondada para baixo, mínimo um real, e repõe a unidade no estoque. A última cópia equipada não pode ser vendida.

Sacola, tigela, caneca e ferramentas de serviço ficam protegidas. Comprar não ensina um manejo. Repetir etapas não duplica pagamentos, a primeira arma ou mantimentos da bagagem. Só a primeira escolha com Tomé oferece uma peça; empréstimos para experimentar estilos não entram na sacola. Peças compradas não são apagadas ao confirmar a escolha. Em repetições, escolher outro manejo exige possuir a arma; desarmado continua disponível sem faixas depois de o testar.

## Equipamento, suprimentos e combate

Vagas: arma, traje, calçado e acessório. As faixas ocupam a vaga de arma como apoio opcional ao desarmado. Equipar exige recuperação concluída, e armas exigem manejo testado. Retirar a arma exige conhecer desarmado. Equipar uma arma muda o manejo ativo.

Base após recuperação: vida máxima 100, alento máximo 20, postura 100, proteção 0, velocidade 18 e movimento 5. A potência base continua a do manejo. Armas dão +2 potência, machado +3; faixas +4 postura. Gibão: +12 vida/+2 proteção; capa: +8 vida/+6 postura; botas: +8 postura/+1 velocidade; cinto: +2 alento/+6 postura; pulseira: +4 postura.

Os bônus entram nas aulas de manejo, Defesa Perfeita e apoio de Duarte, depois da recuperação. Vida/alento/postura remanescentes persistem entre esses exercícios. Trocar equipamento limita os valores ao novo máximo, sem recuperar recursos. Uma arma de outro manejo não beneficia o instrumento emprestado. Tomé garante pelo menos 8 de alento no início de cada aula de manejo para manter os cinco testes acessíveis. A derrota anterior contra Leonor conserva a diferença de poder e os atributos aprovados, por HP real.

Ligaduras recuperam 25 vida; ração 15 vida e 3 alento; água 5 alento. Uso fora do combate, após tratamento de Tomé; nunca removem a lesão narrativa. Não são gastos se todos os recursos afetados estiverem cheios. Objetos da história mantêm os papéis das cenas, sem bônus artificiais.

## Save e validação

Save versão 2 acrescenta moedas, vagas, estoque, pagamentos e recursos atuais. Versão 1 continua carregável, migra a arma inicial e reconhece o serviço do cais já concluído. O arquivo antigo só é substituído na próxima gravação, com backup. Quantidades, valores, vagas, propriedade e limites inválidos são rejeitados antes de alterar o estado atual.

`tests/player_inventory.gd`: 55 verificações de transações, proteção, atributos reais, HP/mitigação, migração, rejeição atómica, teclado/controle, fala preservada, acesso contextual e repetição sem recompensas duplicadas, também aprovadas em OpenGL. Com capítulo completo (31), regras (34), estilos (9), passivas (19), encerramento (27), treino infantil (33) e rotas/retomada (15), são **223 verificações distintas aprovadas**. As 250 falas aprovadas e os 23 módulos de referência foram preservados.

Capturas reais: [personagem](menu-personagem.png), [loja](loja-lisboa.png), [inventário](inventario-portugal.png), [equipamento](equipamento-portugal.png) e [passivas](passivas-menu.png). O vídeo de validação de 10 segundos foi removido na limpeza de temporários. `tools/capture_player_menu.gd` monta um estado de revisão na cena real sem gravar saves do utilizador; `--record-menu` acrescenta pausas de leitura para Movie Maker.

Arte, nomes e referências existentes foram conservados. Preços e atributos são o primeiro balanceamento jogável, sujeito à validação manual.
