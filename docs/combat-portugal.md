# Combate de Portugal — integração de Mar de Ferro

A base de `C:/Users/gamer/Documents/ChatGPT/jogo/scripts` foi reaproveitada por autorização do utilizador. O projeto de origem não foi editado. Os 23 módulos em scripts/combat/mar_de_ferro continuam iguais à fonte, salvo o prefixo dos caminhos; tools/verify_combat_reference.ps1 compara-os.

portugal_rules/portugal_view integram a infância; campaign_rules e battle_host acrescentam os encontros adultos, mantendo o campo 9×8, percurso/custo, movimento antes/depois da ação, previsão/confirmação, desfazer, alcance/linha, iniciativa, uma ação principal, orientação final e timing com efeitos no impacto.

Não existe comando Defender. Na infância e antes de Tomé, a defesa é simples: não há janela Perfeito nem contra-ataque. O duelo com Leonor é jogável e termina por HP real do protagonista; ela tem diferença efetiva de poder, sem imunidade ou derrota por contador de turnos. A derrota regressa à narrativa. Depois da assistência e da recuperação, Tomé ensina Defesa Perfeita, que bloqueia integralmente o golpe defendido.

O pátio testa cinco manejos e uma técnica introdutória própria de cada um. A sequência básico no turno anterior → técnica ensina os fundamentos de preparação/custo. O machado exige contato real na preparação. O exercício de Duarte preserva divisão 60/40 do residual e uma interceptação, sem uma segunda execução defensiva. Raridades não concedem multiplicadores automáticos.

Passivas são aprendidas sem equipar ou recuperar recursos. Protagonista e Duarte têm quatro vagas separadas. Estão implementados os gatilhos introdutórios de posição, técnica no turno anterior, guarda/preparação, potência estacionária e primeiro custo de proteção. Previsão e dano residual executado coincidem; movimento involuntário invalida o apoio estacionário.

Números dos exercícios e do duelo são provisórios para validação. Não há níveis/XP de personagem por repetir treino. O repertório ampliado do catálogo, proficiência completa, todos os refinamentos e itens estatísticos não são a entrega deste recorte.

Ensaios: tests/training.gd, chapter_full.gd, chapter_rules.gd, chapter_styles.gd, chapter_passives.gd e chapter_routes.gd. Capturas reais em OpenGL verificaram o cenário e os painéis; os arquivos temporários são removidos após a conferência.

## Apresentação integrada — 15/10/2026

Os quatro pontos da revisão foram implementados: arena de pátio/praça, seis identidades de combate com nove poses cada, ícones e instruções corretas, sons ligados à antecipação e ao impacto. A infância tem versões infantis próprias. O duelo usa o timing dinâmico herdado; os exercícios mantêm janelas guiadas. A proporção do campo é preservada ao redimensionar a janela.

O mesmo host serve a campanha e `scenes/art/combat_study.tscn`, com seleção de encontros e dos cinco manejos. Os refinamentos acrescentaram cadências próprias por manejo, pausas e reações conforme o contato, sincronização do disparo com o cano, marcações contextuais e encerramento após a recuperação. A derrota contra Leonor chega diretamente ao diálogo aprovado, com postura caída e proteção contra comandos durante a troca. Entradas reais de mouse, teclado e controle foram exercitadas; 230 verificações automatizadas passaram. O aceite estético, o ritmo e o balanceamento permanecem sujeitos à revisão do usuário.

Ver [acabamento, fontes, testes e gravação real](combat-portugal-finish.md). O catálogo futuro de técnicas, inimigos e animações de civis continua fora deste recorte.

