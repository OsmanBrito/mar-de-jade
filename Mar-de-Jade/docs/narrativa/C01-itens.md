# Portugal — itens iniciais e ícones

Conjunto inicial de 18 itens preparado por pedido do utilizador. Portugal ainda não tinha uma tabela fechada de inventário pessoal. O catálogo reúne os objetos previstos no capítulo com propostas de equipamento inicial. Não é uma transcrição do inventário de Maré de Ferro: reaproveitar a arte não transfere nomes, preços, atributos ou efeitos daquele jogo.

[Galeria](../portugal-item-icons.png) · [Catálogo estruturado](../../data/chapter_01/items.json) · [Prompts completos das imagens novas](../portugal-item-generation.json).

## Conjunto

| Categoria | Itens | Origem visual |
| --- | --- | --- |
| Armas | Espada de aprendiz; lança de aprendiz; machado de aprendiz; arcabuz de aprendiz | Espada reutilizada; restantes novos |
| Apoio opcional desarmado | Faixas de treino | Novo; não é requisito para lutar desarmado |
| Vestuário/equipamento | Gibão de prática; capa de viagem; botas de viagem | Gibão e capa reutilizados; botas novas |
| Acessórios | Cinto de serviço; pulseira de corda | Reutilizados |
| Suprimentos | Ligaduras de linho; ração de viagem; cantil de água | Novos |
| Objetos de história | Sacola remendada; tigela do abrigo; caneca da praça | Novos |
| Ferramentas de serviço | Corda de serviço; alavanca do cais | Novos |

15 Comuns (Nv. 1) e três Incomuns (Nv. 2): gibão, cinto e arcabuz. Classificação inicial editorial, não probabilidade de obtenção nem multiplicador de atributos. Objetos sentimentais não ganham estatísticas extraordinárias pela importância narrativa.

## Continuidade

A tigela, a caneca, a sacola e o pano estão no roteiro aprovado. Ligaduras representam material comum de tratamento; não são cura mágica, nem removem instantaneamente as lesões de M03. A composição da ração e o formato do cantil são propostas visuais para mantimentos e água, sem nova receita ou consumível mágico. A corda e a alavanca representam o trabalho de cais/embarque; não são loot automaticamente entregue ao jogador. A arma de fogo é um arcabuz como proposta visual para o manejo aprovado; a aparência não é uma especificação histórica já validada.

Vestuário e acessórios são opções iniciais de design. Não são recompensas confirmadas das cenas existentes. Faixas de treino são opcionais; o estilo desarmado exige só o próprio corpo. As quatro armas podem ser testadas no pátio em C01-M04; disponibilidade para teste não entrega gratuitamente todas ao inventário.

Sacola, tigela e caneca têm `tradeable=false` e `discardable=false`; não ocupam a capacidade de mercadorias do navio. Ferramentas de serviço também ficam protegidas enquanto forem necessárias à missão. A proteção é aplicada pelo inventário e pela loja. Objetos de cena podem ter múltiplas instâncias: o ID de caneca/tigela designa o tipo visual, não funde as duas canecas ou as tigelas diferentes da história. Os papéis de cada instância serão guardados pela cena/missão.

## Arte

Assets finais em `assets/art/items/portugal/<ID>.png`: **cinco reutilizados de Maré de Ferro e treze novos criados com imagegen integrado**. Prompts por ID em `docs/portugal-item-generation.json`. Origem de cada imagem guardada no catálogo. Nenhum ficheiro do projeto de origem foi alterado. A imagem chamada `gear_boots` na origem mostra um pingente; foi rejeitada para calçado e substituída por botas novas.

Os PNGs fonte mantêm transparência e resolução. Molduras ficam separadas, com as mesmas cinco raridades usadas nas skills/passivas. A galeria mostra nome, nível e categoria; o tooltip futuro deve conservar essas informações para não depender apenas da cor.

`tools/build_portugal_item_gallery.py` valida 18 IDs únicos, PNGs transparentes e não vazios, referências de moldura, proteção de história/serviço e igualdade dos cinco reutilizados com a origem. Atualiza metadados e reconstrói a galeria. Galeria final inspecionada para correspondência dos objetos.

## Estado

Arte e catálogo integrados no menu do personagem, inventário e loja. `stats`, `price`, estoque, slots e efeitos de recuperação têm um primeiro balanceamento próprio para Portugal. Arma, traje, calçado e acessório aplicam bônus aos treinos após recuperação; faixas são opcionais. Moeda, equipamento, recursos e estoque ficam no save versão 2, com migração da versão 1. Objetos de história/serviço não podem ser vendidos. Não foi acrescentado limite de capacidade pessoal ou carga naval. Ver [funcionamento e validação](../menu-inventario-loja.md).

