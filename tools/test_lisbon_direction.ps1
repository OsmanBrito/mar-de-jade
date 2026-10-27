param([string[]]$Suites = @('lisbon_urban','lisbon_environment_art','lisbon_composition','lisbon_direction','lisbon_city','lisbon_circulation','map_art_closure','harbor_visit','lisbon_city_campaign','interface_closure','childhood_bond','adult_arc_closure'))
$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path $PSScriptRoot -Parent
$godotExe = $env:GODOT_EXE
if (-not $godotExe) { $godotExe = Join-Path $env:USERPROFILE 'Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe' }
$qaDirectory = Join-Path $projectDirectory '.qa-runtime/lisbon-direction-tests'
New-Item -ItemType Directory -Path $qaDirectory -Force | Out-Null
$previousAppData = $env:APPDATA
$env:APPDATA = Join-Path $qaDirectory 'userdata'
New-Item -ItemType Directory -Path $env:APPDATA -Force | Out-Null
$total = 0
try {
foreach ($suite in $Suites) {
    if ($suite -notmatch '^[a-z_]+$' -or -not (Test-Path -LiteralPath (Join-Path $projectDirectory "tests/$suite.gd"))) { throw "Unknown suite: $suite" }
    $wrapper = @"
extends "res://tests/$suite.gd"
func _initialize():
    ProjectSettings.set_setting("application/config/custom_user_dir_name","Mar-de-Jade-QA-Direction-$suite-"+str(OS.get_process_id()))
    DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
    super._initialize()
"@
    [IO.File]::WriteAllText((Join-Path $qaDirectory "$suite.gd"),$wrapper,[Text.UTF8Encoding]::new($false))
    $logPath = Join-Path $qaDirectory "$suite.log"
    $process = Start-Process -FilePath $godotExe -ArgumentList @('--headless','--path',('"'+$projectDirectory+'"'),'--script',"res://.qa-runtime/lisbon-direction-tests/$suite.gd",'--quit-after','18000','--log-file',('"'+$logPath+'"')) -WindowStyle Hidden -Wait -PassThru
    $lines = Get-Content -LiteralPath $logPath
    $result = $lines | Where-Object { $_ -match '^[A-Z_]+ \{.*"checks".*\}$' } | Select-Object -Last 1
    if ($process.ExitCode -ne 0 -or -not $result -or ($lines | Where-Object { $_ -match 'SCRIPT ERROR:' })) { $lines | Select-Object -Last 35; throw "Failed: $suite" }
    $data = $result.Substring($result.IndexOf('{')) | ConvertFrom-Json
    if ($data.failures.Count) { throw "Assertions failed: $suite" }
    $total += $data.checks
    Write-Output $result
}
Write-Output "LISBON_DIRECTION_SUITES_OK: $total checks in $($Suites.Count) suites"
} finally { $env:APPDATA = $previousAppData }
