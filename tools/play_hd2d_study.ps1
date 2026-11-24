param([switch]$Verify, [switch]$Capture, [switch]$Baseline)
$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path $PSScriptRoot -Parent
$godotExe = $env:GODOT_EXE
if (-not $godotExe) { $godotExe = Join-Path $env:USERPROFILE 'Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe' }
if (-not (Test-Path -LiteralPath $godotExe -PathType Leaf)) { throw 'Configure GODOT_EXE com o caminho do Godot.' }
$qaDirectory = Join-Path $projectDirectory '.qa-runtime/hd2d'
$studyData = Join-Path $qaDirectory 'userdata'
New-Item -ItemType Directory -Path $studyData -Force | Out-Null
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = $studyData
    $mode = if ($Baseline) { 'baseline' } elseif ($Capture) { 'capture' } elseif ($Verify) { 'verify' } else { 'play' }
    $logPath = Join-Path $qaDirectory "$mode.log"
    $arguments = @('--path', ('"' + $projectDirectory + '"'), '--log-file', ('"' + $logPath + '"'))
    if ($Baseline) {
        $arguments += @('--fixed-fps', '60', '--script', 'res://tools/capture_hd2d_baseline.gd')
    } elseif ($Verify -or $Capture) {
        if (-not $Capture) { $arguments += '--headless' }
        $arguments += @('--fixed-fps', '60', '--script', 'res://tests/lisbon_hd2d_study.gd')
        if ($Capture) { $arguments += @('--', '--capture') }
    } else { $arguments += 'res://scenes/art/lisbon_hd2d_study.tscn' }
    $launch = @{FilePath=$godotExe; ArgumentList=$arguments; WorkingDirectory=$projectDirectory; PassThru=$true; WindowStyle='Hidden'}
    if (-not ($Verify -or $Capture -or $Baseline)) { $launch.WindowStyle = 'Normal' }
    $process = Start-Process @launch
    if ($Verify -or $Capture -or $Baseline) {
        if (-not $process.WaitForExit(60000)) {
            Stop-Process -Id $process.Id -Force
            throw "A verificação excedeu 60 segundos; consulte $logPath."
        }
    } else { $process.WaitForExit() }
    $lines = @()
    if (Test-Path -LiteralPath $logPath) { $lines = Get-Content -LiteralPath $logPath; $lines | Select-Object -Last 30 }
    if ($lines | Where-Object { $_ -match 'SCRIPT ERROR:' }) { throw "Erro de script: consulte $logPath." }
    if (($Verify -or $Capture) -and -not ($lines | Where-Object { $_ -like 'LISBON_HD2D_STUDY *' })) { throw 'A verificação não produziu um resultado.' }
    if ($Baseline -and -not ($lines | Where-Object { $_ -eq 'HD2D_BASELINE_COMPLETE' })) { throw 'A captura da campanha não terminou.' }
    if ($process.ExitCode -ne 0) { throw "A amostra encerrou com erro: $($process.ExitCode)" }
} finally { $env:APPDATA = $previousAppData }
