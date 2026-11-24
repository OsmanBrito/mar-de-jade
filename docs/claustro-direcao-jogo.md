# Claustro — direção espacial e leitura de jogo

Revisão de 21/10/2026, aplicada ao interior da casa da Ordem usado pela exploração adulta e infantil.

## Composição

O jardim passa a organizar um circuito pelas quatro galerias. As arcadas norte e sul usam o conjunto existente; bases laterais, bancos e faixas do piso completam a leitura do perímetro. As bases laterais usam um corte baixo da própria arte dos pilares, com superfície de corte visível e colisão, para preservar a visibilidade do personagem. A arcada sul foi reposicionada para abrir a chegada e melhorar a vista da cisterna através dos arcos.

A cisterna saiu do interior bloqueado do jardim e passou para a sua aproximação sul. A posição do objeto, seu volume físico e o ponto de interação estão ligados na planta. Os canteiros de ervas, as oliveiras e a borda contínua identificam a área plantada; o caminho público fica ao redor.

O calçamento utiliza a mesma projeção oblíqua em todas as salas e passagens. As galerias, a enfermaria e o refeitório têm variações discretas de tom, mantendo as juntas alinhadas. Foram retiradas as molduras que faziam camas e mesas parecerem imagens sobrepostas ao piso. Os objetos continuam apoiados por suas sombras de contato.

As placas em postes foram substituídas por identificação nas paredes. Capela, enfermaria, dormitório, cozinha, refeitório, secretaria, armaria e Sala do Capítulo mantêm sua função legível sem ocupar os corredores com sinalização. A placa da enfermaria fica ao lado da janela.

A câmera enquadra cada espaço e interpola a passagem pelos corredores da capela, enfermaria, cozinha, armaria e Sala do Capítulo. O objetivo e a ação contextual continuam na interface existente. No claustro, os indicadores de interação ficam acima do rosto, com alturas próprias para o adulto e para a criança.

## Validação

```powershell
./tools/test_convent_direction.ps1
```

O executor usa dados temporários isolados dentro de `.qa-runtime`. O novo teste percorre todo o anel do jardim, confere as bases dos pilares e a cisterna, valida o enquadramento nas transições e caminha até as salas. Os ensaios existentes verificam a exploração adulta e infantil, salvamento, cozinha, serviços e liderança.

Resultado: **318 verificações em sete suítes**, sem falhas de asserção ou script: `convent_direction` (41), `convent_architecture` (27), `order_convent` (62), `convent_rooms` (23), `order_house_hub` (47), `order_first_service` (60) e `order_leadership` (58).

`tools/capture_convent_direction.gd` também caminha com o controlador real antes de produzir as capturas em `.qa-runtime/claustro-direction`. O log confirma `CLOISTER_WALK_COMPLETE` e `CLOISTER_CAPTURE_COMPLETE`. As capturas anteriores estão em `.qa-runtime/claustro-before`.

Arquivos centrais: `scripts/city/convent_plan.gd`, `convent_world.gd`, `convent_scenery.gd` e `convent_finish.gd`. As alterações preservam a organização das alas, as descobertas, os serviços e o progresso da campanha.
