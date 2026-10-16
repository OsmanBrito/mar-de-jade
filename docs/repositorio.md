# Estrutura do repositório

Desde a revisão de 16/10/2026, `project.godot` fica diretamente na raiz de `mar-de-jade`. A pasta intermediária `Mar-de-Jade/` foi removida; os caminhos internos `res://` continuam relativos à mesma raiz do projeto Godot.

| Caminho | Conteúdo |
|---|---|
| `project.godot` | Configuração e entrada do jogo |
| `assets/` | Arte, áudio e shaders usados pelo projeto |
| `data/` | Conteúdo, catálogos e parâmetros |
| `scenes/` | Cenas editáveis do Godot |
| `scripts/` | Sistemas e apresentação |
| `tests/` | Scripts de verificação reproduzíveis |
| `tools/` | Preparação de recursos, gravação e atalhos |
| `docs/` | Decisões, procedência, validação e prévias |
| `reference-study/` | Estudos anteriores preservados e documentados |

`Jogar.cmd` abre o jogo; `Abrir-no-Godot.cmd` abre o editor. Ambos usam `tools/start-godot.ps1`, procurando primeiro `GODOT_EXE`, depois `godot.exe`/`godot4.exe` no PATH e por fim o Godot 4.5.1 na pasta padrão de Downloads do usuário. Não exigem um nome de usuário específico.

## Arquivos locais

O Git conserva os metadados `.uid` e `.import` do Godot, necessários para manter referências estáveis. O cache `.godot/`, dependências locais `.tools/`, logs, configurações de editor e saídas geradas dos testes ficam ignorados. Saves de teste e relatórios antigos foram retirados do índice, preservando suas cópias locais. Os scripts criam essas saídas novamente quando executados; os resultados relevantes ficam documentados em `docs/`.

Recursos de arte e as prévias fazem parte da revisão visual do projeto e permanecem versionados. Não há executáveis exportados no repositório. Alguns geradores históricos consultam fontes externas identificadas nos documentos de procedência; jogar e abrir as cenas usa os recursos já incluídos.

## Validar a partir da raiz

No PowerShell, com o executável do Godot configurado em `GODOT_EXE`:

```powershell
& $env:GODOT_EXE --headless --editor --path . --import --quit --log-file ./tests/import.log
& $env:GODOT_EXE --headless --path . --script tests/navigation.gd --log-file ./tests/navigation.log
& $env:GODOT_EXE --path . --script tests/navigation_ocean.gd --log-file ./tests/ocean.log
& $env:GODOT_EXE --path . --script tests/navigation_atmosphere.gd --log-file ./tests/atmosphere.log
```

Os dois últimos precisam de renderização para conferir a apresentação. Rodar a partir da raiz evita apontar para a antiga pasta intermediária. Os scripts de navegação usam saves e configurações de áudio próprios para QA.

Na reorganização, os 1.079 arquivos movidos foram comparados por SHA-256 antes de editar os documentos e atalhos, sem divergências. A estrutura foi importada também numa cópia nova, criada a partir do índice do Git, sem caches ou dependências locais. Passaram novamente 16 verificações do mar e 88 da navegação no repositório reorganizado, além de 23 da entrada/menu nessa cópia nova.
