param([switch]$Editor, [switch]$MeasureChildhood)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$godotBinary = $env:GODOT_EXE
if (-not $godotBinary) {
    foreach ($commandName in @('godot.exe', 'godot4.exe')) {
        $godotCommand = Get-Command $commandName -CommandType Application -ErrorAction SilentlyContinue
        if ($godotCommand) { $godotBinary = $godotCommand.Source; break }
    }
}
if (-not $godotBinary) {
    $godotBinary = Join-Path $env:USERPROFILE 'Downloads\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64.exe'
}
if (-not (Test-Path -LiteralPath $godotBinary -PathType Leaf)) {
    Write-Host 'Godot 4.5.1 não encontrado. Configure GODOT_EXE com o caminho do executável ou adicione godot.exe ao PATH.'
    exit 1
}
$launchArguments = @('--path', ('"' + $projectRoot + '"'))
if ($Editor) { $launchArguments += '--editor' }
if ($MeasureChildhood -and -not $Editor) { $launchArguments += @('--', '--measure-childhood') }
Start-Process -FilePath $godotBinary -ArgumentList $launchArguments
