param([string]$GodotExe = $env:GODOT_EXE)
$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path $PSScriptRoot -Parent
if (-not $GodotExe) {
    $GodotExe = Join-Path $env:USERPROFILE 'Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe'
}
if (-not (Test-Path -LiteralPath $GodotExe -PathType Leaf)) { throw 'Configure GODOT_EXE para abrir a animação.' }
$logDirectory = Join-Path $projectDirectory '.qa-runtime/leonor-blender'
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
$arguments = @('--path', ('"' + $projectDirectory + '"'), 'res://scenes/art/leonor_blender_study.tscn', '--log-file', ('"' + $logDirectory + '/player.log"'))
Start-Process -FilePath $GodotExe -ArgumentList $arguments
