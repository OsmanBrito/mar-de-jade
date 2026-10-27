param(
    [string]$GodotExe = $env:GODOT_EXE,
    [ValidateSet('order_leadership','order_studies','order_house_costumes','order_house_hub','order_convent','house_life','optional_closure','order_first_service','character_development','weapon_choice','player_inventory','firearm','boarding','combat_economy','practice_freedom','integration_closure','campaign_continuity','chapter_rules','chapter_passives','interface_closure','navigation_campaign_entry','combat_feel','chapter_full')]
    [string[]]$Suites = @('character_development','weapon_choice','player_inventory','firearm','boarding','combat_economy','practice_freedom','integration_closure','campaign_continuity','chapter_rules','chapter_passives','interface_closure','navigation_campaign_entry','combat_feel','chapter_full')
)
$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path $PSScriptRoot -Parent
if (-not $GodotExe) { $GodotExe = Join-Path $env:USERPROFILE 'Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe' }
if (-not (Test-Path -LiteralPath $GodotExe -PathType Leaf)) { throw 'Configure GODOT_EXE para o executável do Godot.' }
$qaDirectory = Join-Path $projectDirectory '.qa-runtime/character-development-runs'
New-Item -ItemType Directory -Path $qaDirectory -Force | Out-Null
$totalChecks = 0
foreach ($suite in $Suites) {
    $wrapperPath = Join-Path $qaDirectory ($suite + '.gd')
    $wrapper = @"
extends "res://tests/$suite.gd"
func _initialize():
    var name = "Mar-de-Jade-QA-01a15602-$suite-"+str(OS.get_process_id())+"-"+str(Time.get_ticks_usec())
    ProjectSettings.set_setting("application/config/custom_user_dir_name",name)
    DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
    print("QA_ISOLATED_DATA ",OS.get_user_data_dir())
    super._initialize()
"@
    [System.IO.File]::WriteAllText($wrapperPath,$wrapper,[System.Text.UTF8Encoding]::new($false))
    $logPath = Join-Path $qaDirectory ($suite + '.log')
    Write-Output "Testing $suite"
    $process = Start-Process -FilePath $GodotExe -ArgumentList @('--headless','--path',('"'+$projectDirectory+'"'),'--script',("res://.qa-runtime/character-development-runs/$suite.gd"),'--quit-after','18000','--log-file',('"'+$logPath+'"')) -WindowStyle Hidden -Wait -PassThru
    $lines = Get-Content -LiteralPath $logPath
    $resultLine = $lines | Where-Object { $_ -match '^[A-Z_]+ \{.*"checks".*\}$' } | Select-Object -Last 1
    if ($process.ExitCode -ne 0 -or -not $resultLine -or ($lines | Where-Object { $_ -match 'SCRIPT ERROR:' })) {
        $lines | Select-Object -Last 50 | Write-Output
        throw "Failed: $suite"
    }
    $json = $resultLine.Substring($resultLine.IndexOf('{')) | ConvertFrom-Json
    if ($json.failures.Count -ne 0) { throw "Assertions failed: $suite" }
    $totalChecks += $json.checks
    Write-Output $resultLine
}
Write-Output "DEVELOPMENT_SUITES_OK: $totalChecks checks in $($Suites.Count) suites"
