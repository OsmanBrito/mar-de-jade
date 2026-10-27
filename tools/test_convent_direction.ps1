param([string[]]$Suites = @('convent_direction','convent_architecture','order_convent','convent_rooms','order_house_hub','order_first_service','order_leadership'))
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'test_lisbon_direction.ps1') -Suites $Suites
