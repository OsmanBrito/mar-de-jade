# Lisboa de Ferro na campanha de Jade

18/10/2026 — primeiro percurso integrado e jogável.

## O que mudou

Lisboa passa a ter um exterior contínuo: a praça e o pátio da casa da Ordem de Cristo ligam-se à Ribeira por uma descida central. Atravessar entre eles conserva o jogador, a câmera e a mesma instância do cenário. As entradas do acolhimento e do convés continuam a abrir espaços próprios.

A Ribeira vem do projeto **atual** de Maré de Ferro, em `C:/Users/gamer/Documents/ChatGPT/jogo`. Foram importados 21 recursos de cenário e a planta de `scripts/lisbon_world.gd`, com hashes em [provenance.json](../assets/art/ferro-lisbon/provenance.json). A origem permaneceu intacta. O importador reproduzível é [import_ferro_lisbon.ps1](../tools/import_ferro_lisbon.ps1).

Mantêm-se a sequência oeste–leste das casas, estaleiro, cordoaria, mercado, armazém e oficina, além dos dois pontões. A planta recebe escala 1,6 e uma parte alta para o convento. Edifícios e objetos são peças separadas, ordenadas pelos pés, com colisões e transparência quando encobrem o protagonista. O piso superior é repetido em resolução própria. A abertura na mureta e a substituição de uma área de cargas permitem a ligação ao convento e o socorro de Jade.

## Percurso da campanha

- **Infância:** depois do acolhimento, o jogador explora a praça menor da mesma Lisboa. Pode observar a casa da Ordem e as arcadas ou falar com uma criança. Aproximar-se de Leonor e interagir inicia a conversa aprovada no banco. A descida para a Ribeira fica limitada; não há dinheiro, equipamento adulto nem habilidades oferecidas pelas descobertas.
- **Aos 19 anos:** sair do acolhimento, descer até a cozinha, entregar os sacos e voltar ao pátio para o treino. A tarefa do nó com a criança permanece.
- **Socorro:** Duarte dirige-se ao acidente; o jogador caminha até a carga, liberta o trabalhador, procura Tomé no acolhimento e regressa com ele. O atendimento e o pagamento continuam ligados aos mesmos acontecimentos.
- **Depois do socorro:** moradores, pedidos e comércio funcionam na Ribeira. Oficina, carro reparável, pescadora e trabalhador do pontão foram reposicionados para os locais de trabalho da planta importada, conservando o conteúdo de Jade.
- **Resto do arco:** refeição, descanso, demonstração, avaliação com Leonor, recuperação, aprendizagem e preparativos usam o mesmo exterior. A Botafogo recebe o jogador pelo pontão leste; ainda é possível descer antes de falar com Rodrigo.

As animações originais e o roteiro aprovado permanecem. A identidade da [Ordem de Cristo](ordem-cristo-integracao.md), inclusive o vestuário de Duarte, faz parte deste percurso.

A música e o ambiente acompanham a posição na cidade: chegar à Ribeira seleciona seu tema sem depender da próxima conversa; voltar à praça restaura o tema urbano. Os temas de combate e recuperação conservam prioridade narrativa.

## Salvamento

O formato de Jade passa à versão 5 para registrar exploração infantil. Aceita saves das versões 1–4. A localização infantil só é válida na cena da infância e dentro de seu limite. A versão 4 conserva dinheiro e estoque esgotado dos itens de Ferro; a atualização não reabastece a loja. As migrações anteriores continuam adicionando somente a disponibilidade prevista dos itens importados.

O percurso adulto registra compromisso, área e posição. Posições antigas que colidem com a nova composição são ajustadas para um ponto livre próximo. Falas e combates continuam retomando seus checkpoints.

## Validação

Os ensaios percorrem navegação e colisões reais, usando os mesmos objetivos e interações do jogador. Resultados desta integração:

| Ensaio | Verificações |
| --- | ---: |
| `lisbon_city.gd`: planta, destinos, colisões e limite infantil | 20 |
| `childhood_city.gd`: exploração, descoberta e save infantil | 13 |
| `lisbon_city_campaign.gd`: entrega → treino → socorro, sem recargas do exterior | 24 |
| `chapter_full.gd`: 17 blocos adultos e sete tipos de encontro | 65 |
| `lisbon_walk.gd`: deslocamentos, entradas, ida/volta e retomada | 57 |
| `lisbon_requests.gd`: moradores, pedidos e reparação | 85 |
| `plaza.gd`: exploração e sequência infantil aprovada | 42 |
| `chapter_staging.gd`: encenações do arco | 49 |
| `ferro_integration.gd`: itens, economia e migrações | 40 |
| `player_inventory.gd`: inventário e equipamentos | 57 |
| `navigation.gd`: navegação marítima | 88 |
| `boarding.gd`: abordagens e estado transportado | 78 |
| `chapter_music.gd`: trilha, transições e localização no exterior contínuo | 75 |

O teste do primeiro percurso também foi executado com renderização e capturas para inspeção do convento e da Ribeira. Capturas opcionais ficam em `.qa-runtime/city-preview/` com `--capture`. Os saves de teste usam perfis isolados.

## Limite desta etapa

Está implementada a ligação principal entre convento e Ribeira. Na etapa seguinte foram acrescentados [claustro, capela e enfermaria exploráveis](convento-exploravel.md), com retomada em saves v6 e dois recursos adicionais de cenário de Ferro. As vielas alternativas da proposta, a função narrativa do pontão oeste e novas missões continuam pendentes. A migração dos demais mapas e sistemas de Ferro também prossegue em outras etapas. O interesse e o ritmo dos deslocamentos precisam de avaliação jogada pelo usuário; os testes confirmam funcionamento e persistência.

Para jogar: `Jogar.cmd`, na raiz do repositório. Uma nova campanha apresenta a exploração infantil; saves adultos retomam o estágio correspondente na nova composição.
