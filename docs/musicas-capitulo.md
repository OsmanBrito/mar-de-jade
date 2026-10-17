# Música do primeiro capítulo

O capítulo agora tem trilha própria desde a entrada do nome. `ChapterMusic`, em autoload, acompanha a cena corrente e mantém duas vozes para transições suaves de 1,4 segundo. A faixa não reinicia a cada fala ou troca de etapa com o mesmo tema. Ao voltar do combate, o tema do local é retomado; diálogos e pausa reduzem o volume.

| Contexto | Faixa |
|---|---|
| Entrada, abrigo e abertura adulta | Casa das Marés |
| Praça e pátio | Echoes of the Templar City |
| Cais, serviço e embarque | Porto Morning Tides |
| Promessa da infância | Tema de Duarte e Inês |
| Depois do duelo e recuperação | Depois da Onda |
| Treinos infantis e adultos | Steel on Saltwind |
| Duelo com Leonor | Duel at the Atlantic Edge |

As sete gravações foram copiadas sem edição do projeto local atual Maré de Ferro. `assets/audio/chapter/music/playlist.json` registra os caminhos originais e os ganhos de reprodução. Os MP3s de cidade e batalha vêm das associações atuais de `music.gd`; os temas narrativos vêm do catálogo musical existente. Nenhuma música foi gerada ou baixada para esta mudança.

O menu adulto **Sistema** contém volume e silêncio para a música do capítulo. A preferência fica em `user://capitulo-audio.cfg`, separada do save narrativo. Não altera o volume dos golpes. A navegação mantém suas seis músicas e seus próprios controles; ao entrar nela, a trilha do capítulo sai gradualmente.

## Validação

`tests/chapter_music.gd`: **75 verificações no renderizador real, zero falhas**. Confere arquivos completos e loop, cache, transições e reversão rápida, silêncio/volume, cenas narrativas, treino, duelo, retorno, roteamento automático do autoload, preferências e isolamento da navegação. A abertura, praça, promessa, abertura adulta e conversa do treino também são exercitadas como cena corrente, passando pelo `_process` real, incluindo pausa e retomada. Uma captura do barramento de áudio, mantida apenas em memória, confirma sinal não silencioso e margem abaixo da saturação na faixa de treino.

Correção posterior: abertura e promessa não possuem `phase`. O ajuste de volume narrativo agora usa o contexto musical já resolvido, sem tentar acessar essa propriedade. O teste anterior conferia a escolha da faixa nessas cenas, mas não exercitava o acompanhamento automático delas.

Também passaram interface (39), inventário (55), apresentação do combate (19) e treino infantil (34), sem falhas.
