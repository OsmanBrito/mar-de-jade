param([switch]$SkipFullCampaign)
# All saves/preferences stay in the isolated runtime used by the shared runner.
$ErrorActionPreference = 'Stop'
$suites = @(
    'name_entry','childhood_home','childhood_home_motion','childhood_home_side_walk',
    'childhood_home_presentation','childhood_journey','plaza','training','forest_hunt',
    'childhood_controls','childhood_bond','promise','adult_opening',
    'order_first_service','order_house_hub','order_leadership','menu_learning',
    'lisbon_dialogue_finish','city_life','lisbon_requests','lisbon_circulation',
    'lisbon_urban','lisbon_environment_art','lisbon_composition','lisbon_direction',
    'map_art_closure','lisbon_city','lisbon_city_campaign','harbor_visit',
    'lisbon_ui_closure','first_playable_ui','interface_closure','optional_closure',
    'adult_arc_closure','campaign_continuity','integration_closure','navigation_campaign_entry'
)
if (-not $SkipFullCampaign) { $suites += 'chapter_full' }
& (Join-Path $PSScriptRoot 'test_lisbon_direction.ps1') -Suites $suites
