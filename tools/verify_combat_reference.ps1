param([string]$SourceDirectory = 'C:\Users\gamer\Documents\ChatGPT\jogo\scripts')
$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path $PSScriptRoot -Parent
$referenceDirectory = Join-Path $projectDirectory 'scripts\combat\mar_de_ferro'
$verified = 0
foreach ($module in Get-ChildItem -LiteralPath $referenceDirectory -Filter '*.gd') {
    $original = (Get-Content -LiteralPath (Join-Path $SourceDirectory $module.Name) -Raw).Replace('res://scripts/', 'res://scripts/combat/mar_de_ferro/').Trim()
    $copied = (Get-Content -LiteralPath $module.FullName -Raw).Trim()
    if ($original -cne $copied) { throw "O módulo diverge da referência: $($module.Name)" }
    $verified++
}
Write-Output "Referência verificada: $verified módulos idênticos, exceto caminhos de importação."
