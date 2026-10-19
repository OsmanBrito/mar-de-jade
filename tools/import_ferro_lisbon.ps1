param([string]$SourceRoot = 'C:/Users/gamer/Documents/ChatGPT/jogo')
$ErrorActionPreference = 'Stop'
$destination = Split-Path $PSScriptRoot -Parent
$target = Join-Path $destination 'assets/art/ferro-lisbon'
New-Item -ItemType Directory -Path $target -Force | Out-Null
$files = @('lisbon-ground-refined-v3.png','lisbon-shipyard-refined-v1.png','lisbon-timber-refined-v1.png','lisbon-courtyard-wall-refined-v1.png','bruma-v2-house_limestone.png','bruma-v2-house_teal.png','bruma-v2-workshop.png','bruma-v2-warehouse.png','bruma-v2-pots.png','bruma-v2-cart.png','bruma-v2-tree.png','bruma-barrel.png','bruma-crate.png','bruma-nets.png','bruma-market.png','bruma-boat.png','regional-bench-illustrated-v1.png','bruma-net-rack-illustrated-v1.png','bruma-market-goods-illustrated-v1.png','bruma-pier-directed-v1.png','bruma-paving-refined.png')
$files += @('bruma-grass-refined.png','roman-well-refined-v1.png')
$copies = foreach ($name in $files) {
    $original = Join-Path $SourceRoot ('assets/scenery/'+$name)
    Copy-Item -LiteralPath $original -Destination (Join-Path $target $name)
    [ordered]@{source='assets/scenery/'+$name; local='assets/art/ferro-lisbon/'+$name; sha256=(Get-FileHash -LiteralPath $original).Hash.ToLower()}
}
$worldSource = Join-Path $SourceRoot 'scripts/lisbon_world.gd'
$worldText = [IO.File]::ReadAllText($worldSource).Replace('res://assets/scenery/lisbon-ground-refined-v3.png','res://assets/art/ferro-lisbon/lisbon-ground-refined-v3.png')
New-Item -ItemType Directory -Path (Join-Path $destination 'scripts/city') -Force | Out-Null
[IO.File]::WriteAllText((Join-Path $destination 'scripts/city/ferro_lisbon.gd'),$worldText)
[ordered]@{schema_version=1; source_root=$SourceRoot; source_layout_sha256=(Get-FileHash -LiteralPath $worldSource).Hash.ToLower(); layout='scripts/city/ferro_lisbon.gd'; adaptation='Original layout and navigation, with local ground asset path. Jade opens a northern gate in the courtyard wall, replaces two cargo footprints with the rescue scene, and adds a connected convent district.'; copies=@($copies)} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $target 'provenance.json') -Encoding utf8
Write-Output "Lisboa atual de Ferro: $($copies.Count) recursos copiados; origem preservada."
