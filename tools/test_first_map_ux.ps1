param([string[]]$Suites = @(
    'first_map_childhood','first_map_journal','first_map_prompts','first_map_entry',
    'name_entry','childhood_home','childhood_home_presentation','childhood_journey',
    'childhood_controls','childhood_bond','plaza','training','forest_hunt','promise',
    'adult_opening','order_first_service','order_house_hub','order_leadership',
    'lisbon_dialogue_finish','lisbon_requests','lisbon_ui_closure','lisbon_direction',
    'player_inventory','menu_learning','interface_closure','optional_closure',
    'adult_arc_closure','campaign_continuity','integration_closure',
    'navigation_campaign_entry','chapter_full'
), [switch]$Rendered, [switch]$Capture)
# Fresh output directories avoid stale captures/logs and preserve earlier QA evidence.
$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path $PSScriptRoot -Parent
$godotExe = $env:GODOT_EXE
if (-not $godotExe) { $godotExe = Join-Path $env:USERPROFILE 'Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe' }
$runDirectory = Join-Path $projectDirectory ('.qa-runtime/first-map-tests-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Path $runDirectory -Force | Out-Null
$previousAppData = $env:APPDATA
$env:APPDATA = Join-Path $runDirectory 'userdata'
New-Item -ItemType Directory -Path $env:APPDATA -Force | Out-Null
$total = 0
$fixtureBytes = @{}
foreach ($fixture in Get-ChildItem -LiteralPath (Join-Path $projectDirectory 'tests') -Filter '*.json') {
    $fixtureBytes[$fixture.FullName] = [IO.File]::ReadAllBytes($fixture.FullName)
}
try {
    foreach ($suite in $Suites) {
        if ($suite -notmatch '^[a-z_]+$' -or -not (Test-Path -LiteralPath (Join-Path $projectDirectory "tests/$suite.gd"))) { throw "Unknown suite: $suite" }
        $wrapper = @"
extends "res://tests/$suite.gd"
func _initialize():
    ProjectSettings.set_setting("application/config/custom_user_dir_name","Mar-de-Jade-QA-FirstMap-$suite-"+str(OS.get_process_id()))
    DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
    super._initialize()
"@
        $wrapperPath = Join-Path $runDirectory "$suite.gd"
        [IO.File]::WriteAllText($wrapperPath,$wrapper,[Text.UTF8Encoding]::new($false))
        $logPath = Join-Path $runDirectory "$suite.log"
        $scriptPath = 'res://.qa-runtime/' + (Split-Path -Path $runDirectory -Leaf) + "/$suite.gd"
        $runArguments = @('--path',('"'+$projectDirectory+'"'),'--script',$scriptPath,'--quit-after','18000','--log-file',('"'+$logPath+'"'))
        if (-not $Rendered) { $runArguments = @('--headless') + $runArguments }
        if ($Capture) { $runArguments += @('--','--capture') }
        $process = Start-Process -FilePath $godotExe -ArgumentList $runArguments -WindowStyle Hidden -Wait -PassThru
        $lines = Get-Content -LiteralPath $logPath
        $result = $lines | Where-Object { $_ -match '^[A-Z_]+ \{.*"checks".*\}$' } | Select-Object -Last 1
        if ($process.ExitCode -ne 0 -or -not $result -or ($lines | Where-Object { $_ -match 'SCRIPT ERROR:' })) { $lines | Select-Object -Last 35; throw "Failed: $suite" }
        $data = $result.Substring($result.IndexOf('{')) | ConvertFrom-Json
        if ($data.failures.Count) { throw "Assertions failed: $suite" }
        $total += $data.checks
        Write-Output $result
    }
    Write-Output "FIRST_MAP_UX_SUITES_OK: $total checks in $($Suites.Count) suites"
    Write-Output "Logs: $runDirectory"
} finally {
    $env:APPDATA = $previousAppData
    foreach ($fixture in $fixtureBytes.Keys) {
        if ([Convert]::ToBase64String([IO.File]::ReadAllBytes($fixture)) -ne [Convert]::ToBase64String($fixtureBytes[$fixture])) {
            [IO.File]::WriteAllBytes($fixture,$fixtureBytes[$fixture])
        }
    }
}
