# Direção visual inicial

Inspirada nos princípios observados: composição isométrica por camadas, sprites detalhados, contacto claro com o chão, profundidade aparente e leitura de objetos. As imagens são novas e não derivam de exportações da referência.

O recorte português usa pedra clara gasta, cal quente, telhados de barro, madeira de cais e água verde-jade. Roupa do viajante: linho, colete azul-esverdeado, couro e bagagem modesta. É uma proposta de sprite para avaliar escala e locomoção; não fixa a aparência personalizável do protagonista nem substitui a revisão histórica/artística.

Três atlas gerados pelo **imagegen integrado**: `terrain_atlas.png`, `port_props.png`, `traveller_walk.png`. Originais PNG RGBA com transparência preservados. Prompts completos em [art-prompts.json](art-prompts.json). Não houve uso de API/CLI externo ou de chave API.

O atlas de props inclui armazém, guindaste, pinheiro e carga. O viajante possui quatro direções e quatro quadros por direção. Após feedback de que as passadas lateral e traseira não se liam, a segunda revisão enfatizou pernas alternadas, pés separados e balanço dos braços nessas vistas. A animação agora avança com o comando de movimento, inclusive quando uma colisão impede o deslocamento; o ritmo foi desacelerado para tornar os quadros mais legíveis. O movimento diagonal continua a usar a vista cardinal mais próxima; não há poses diagonais próprias no atlas. A textura de chão repetida deve receber variantes e detalhes locais na próxima passagem de arte. A água é um shader original do projeto, com ondas de baixa intensidade; não é um shader recuperado da referência.

Esta fase valida família visual e legibilidade. Não significa aprovação final de todos os assets ou de arquitetura/vestuário históricos para a campanha.
