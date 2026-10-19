param([string]$SourceRoot = 'C:/Users/gamer/Documents/ChatGPT/jogo', [switch]$ImportCompatibleItems)
$ErrorActionPreference = 'Stop'
$destination = Split-Path $PSScriptRoot -Parent
$source = (Resolve-Path -LiteralPath $SourceRoot).Path
if ($source -eq $destination) { throw 'A origem deve ser o projeto atual de Ferro.' }
$catalogPath = Join-Path $source 'scripts/rpg_catalog.gd'
$catalogText = Get-Content -LiteralPath $catalogPath -Raw
$itemBlock = [regex]::Match($catalogText, '(?ms)^const ITEMS := \{(.*?)^\}').Groups[1].Value
$items = [ordered]@{}
foreach ($line in ($itemBlock -split "`n")) {
    $entry = $line.Trim().TrimStart(',').TrimEnd(',')
    if (-not $entry) { continue }
    $parsed = ConvertFrom-Json ('{' + $entry + '}')
    foreach ($property in $parsed.PSObject.Properties) { $items[$property.Name] = $property.Value }
}
if ($items.Count -lt 10) { throw 'Catálogo de origem não reconhecido.' }
# Only stats already executed by Jade, with no story or proc effects.
$selected = @('dock_knife', 'coat', 'oilskin', 'mail', 'silk', 'charm', 'rope_bracelet', 'shell')
$queue = [System.Collections.Generic.Queue[string]]::new()
$queue.Enqueue('project.godot')
$seen = @{}
$resources = [System.Collections.Generic.List[object]]::new()
while ($queue.Count) {
    $relative = $queue.Dequeue()
    if ($seen.ContainsKey($relative)) { continue }
    $seen[$relative] = $true
    $path = Join-Path $source $relative
    $exists = Test-Path -LiteralPath $path -PathType Leaf
    $resources.Add([ordered]@{path=$relative; exists=$exists; sha256=$(if ($exists) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLower() } else { $null })})
    if (-not $exists -or [IO.Path]::GetExtension($path) -notin @('.godot','.gd','.tscn','.tres','.gdshader','.json')) { continue }
    foreach ($match in [regex]::Matches((Get-Content -LiteralPath $path -Raw), '["''](res://[^"'']+)["'']')) {
        $reference = $match.Groups[1].Value.Substring(6)
        if (Test-Path -LiteralPath (Join-Path $source $reference) -PathType Leaf) { $queue.Enqueue($reference) }
    }
}
$auditItems = foreach ($id in $items.Keys) {
    $row = $items[$id]
    [ordered]@{source_id=$id; destination_id=$(if ($id -in $selected) { 'FERRO:'+$id } else { $null }); disposition=$(if ($id -in $selected) { 'integrated_initial_balance' } elseif ($row.combat_effect) { 'requires_effect_and_story_review' } else { 'requires_family_balance_and_story_review' }); definition=$row}
}
$copied = foreach ($file in Get-ChildItem -LiteralPath (Join-Path $destination 'scripts/combat/mar_de_ferro') -Filter '*.gd') {
    $original = Join-Path $source ('scripts/'+$file.Name)
    $normalizedEqual = $false
    if (Test-Path -LiteralPath $original) {
        $sourceText = (Get-Content -LiteralPath $original -Raw).Replace("`r`n","`n").Trim()
        $localText = (Get-Content -LiteralPath $file.FullName -Raw).Replace('res://scripts/combat/mar_de_ferro/', 'res://scripts/').Replace("`r`n","`n").Trim()
        $normalizedEqual = $sourceText -ceq $localText
    }
    [ordered]@{destination='scripts/combat/mar_de_ferro/'+$file.Name; source_exists=(Test-Path -LiteralPath $original); identical=$(if (Test-Path -LiteralPath $original) { (Get-FileHash -LiteralPath $original).Hash -eq (Get-FileHash -LiteralPath $file.FullName).Hash } else { $false }); same_after_script_path_and_line_end_normalization=$normalizedEqual}
}
$audit = [ordered]@{schema_version=1; source_root=$source; entrypoint='project.godot'; coverage='Literal resource references reachable from project.godot; dynamically constructed paths require manual review. Unreachable files are not evidence of runtime use.'; source_catalog_sha256=(Get-FileHash -LiteralPath $catalogPath).Hash.ToLower(); resources=$resources.ToArray(); items=@($auditItems); existing_combat_copies=@($copied)}
$out = Join-Path $destination 'data/integration'
New-Item -ItemType Directory -Path $out -Force | Out-Null
$audit | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath (Join-Path $out 'ferro-inventory.json') -Encoding utf8
if ($ImportCompatibleItems) {
    $imported = foreach ($id in $selected) {
        $row = $items[$id]
        if ($row.combat_effect) { throw "Efeito não auditado: $id" }
        foreach ($stat in $row.stats.PSObject.Properties.Name) {
            if ($stat -notin @('hp','qi','posture','defense','speed','attack')) { throw "Atributo não integrado: $stat" }
        }
        $iconKey = if ($row.icon) { $row.icon } else { 'gear_'+$id }
        $iconSource = Join-Path $source ('assets/skill_icons/'+$iconKey+'.png')
        $iconDirectory = Join-Path $destination 'assets/art/items/ferro'
        New-Item -ItemType Directory -Path $iconDirectory -Force | Out-Null
        Copy-Item -LiteralPath $iconSource -Destination (Join-Path $iconDirectory ($id+'.png'))
        $entry = [ordered]@{id='FERRO:'+$id; source_id=$id; origin='mare_de_ferro_current'; source_catalog_sha256=$audit.source_catalog_sha256; name=$row.name; category=$row.slot; description=$row.description; icon='res://assets/art/items/ferro/'+$id+'.png'; design_status='playable_initial_balance'; tradeable=$true; discardable=$true; slot=$row.slot; stats=$row.stats; price=$row.price; rarity='common'; rarity_level=1; rarity_name='Comum'; rarity_color='#A7B3BE'; frame='res://assets/ui/skill_frames/common.svg'; stock=1}
        if ($row.slot -eq 'weapon') { $entry.style = 'ES' }
        $entry
    }
    [ordered]@{schema_version=1; scope='Primeiro lote compatível; distribuição e valores iniciais de Jade'; items=@($imported)} | ConvertTo-Json -Depth 15 | Set-Content -LiteralPath (Join-Path $out 'ferro-items.json') -Encoding utf8
}
Write-Output "Inventário: $($resources.Count) recursos literais alcançáveis, $($items.Count) itens classificados, $(@($copied).Count) módulos de combate comparados."
