# Lisbon — structural environment correction, 21 October 2026

## Audit and design decision

The starting point was the existing working checkout, including its earlier local environment changes. No screenshot attachment was available in this turn. The project's existing `lisboa-ambiente-depois.png` and fresh live OpenGL captures supplied the visual baseline.

The underlying problem was land use: four waterfront buildings beneath a large civic apron, two oversized closed plots, and unused lawn to the northeast. Previous improvements to sprite proportions did not create street frontage or a neighborhood. The religious landmark is intentionally monumental; its identity and scale were retained. At gameplay zoom the adult is approximately 84 pixels tall, with a 12-pixel physical radius and 14-pixel navigation clearance. Enlarging characters or changing the camera would conceal the spacing problem.

Implementation inspected: `praca_infancia.tscn`, `lisbon_world.gd`, the inherited plaza/world navigation, `convent_plan.gd`, `order_house.gd`, `ferro_lisbon.gd`, ground/composition/prop scripts, city residents, service approaches, and the existing capture/test workflows. The exterior uses an oblique illustrated ground plane with Cartesian movement, rather than a strict isometric movement grid. `FerroRibeira` owns ground and water; `ActorsAndProps` shares Y sorting for people, houses and props.

The plan was to enclose the civic square, replace the northeastern lawn with a compact residential block, connect its street to the existing eastern return, extend the western frontage toward the shipyard, and organize the market and cargo around the preserved waterfront destinations.

## Implemented changes

- **Buildings:** ten additional instances of the two existing Lisbon house paintings; no new art files. Eight face public approaches; two rear houses complete the skyline inside the private northern block. Together with the original four buildings these form a neighborhood, rather than a single waterfront row. Heights and setbacks are authored individually; the convent retains the highest skyline.
- **Civic enclosure:** a house on the southern edge of the square and one at the eastern descent give the public space architectural edges. Existing narrative staging, bench, portaria and arcade entrances retain their coordinates.
- **Northern block:** a continuous private parcel, short connecting walls and matching physical collision close the spaces between houses. Its frontage borders the bent Rua dos Mercadores, with a 106-unit worn central strip. Two civilian passers use checked routes along this street. They have no blocking collision and remain hidden during childhood.
- **Western connection:** a new paved court connects the western house to Rua da Roda and the shipyard. The kitchen garden is retained and narrowed to fit the frontage. It remains an intentional enclosed garden.
- **Working courts:** the formerly extensive eastern grass parcel becomes a smaller paved service yard. Its northern strip is now a public doorstep lane. The high wall behind the original warehouse/workshop grouping is shortened and lowered, and the obsolete eastern civic boundary wall is removed so it no longer cuts across the neighborhood connection.
- **Market:** the isolated second stall moves to the foot of the descent near the existing fish/merchant stall. Pots, shade tree and bench form its resting edge. The waterfront through-route and merchant approach remain clear.
- **Cargo:** the five loose crate columns formerly beneath the western houses move into the warehouse loading bay; associated logical cargo footprints move with them. The accident cargo, repairable cart, workers, embarkation pier and western boat activity retain their existing coordinates and behavior.
- **Scale:** existing framing logic fits every added painting uniformly to its authored box. Aspect ratios, foot pivots, Y sorting and gradual protagonist reveal remain intact. Player size, gameplay zoom, camera offset behavior, viewport settings and source PNGs were not changed.

`scripts/city/lisbon_urban_plan.gd` is the shared source for the added public surfaces, frontage positions, physical bases, northern block, connecting walls, street route and market anchors. Rendering and navigation consume the same plan. Existing save validation remains compatible; the original clear-position restoration still resolves saves that land in newly occupied plots.

## Visual verification

Captured with `tools/capture_lisbon_urban.gd` in the actual chapter scene using OpenGL, an isolated unsaved campaign and the existing exploration camera. Both runs use a 1440×900 viewport, identical camera/player stations and the same configuration. The overview uses the existing audit framing at position (250,400), zoom 0.43; gameplay views use zoom 1.0.

- [Before overview](lisbon-urban-before.png)
- [After overview](lisbon-urban-after.png)
- [Street at gameplay scale](lisbon-urban-street.png)
- [Market at gameplay scale](lisbon-urban-market.png)

All six before/after stations, including civic square, neighborhood, market, eastern harbor, shipyard and overview, are retained in `.qa-runtime/lisbon-urban/{before,after}/`. The neighborhood baseline station intentionally shows the former lawn from the same camera station; that position was outside the previous public routes.

Visual inspection confirmed the new southern square edge, compact northern frontage, a visible street between housing and commercial buildings, a connected western court, market grouping, and cargo next to the warehouse. Adult characters remain readable at normal zoom. No source painting was stretched. Navigation was assessed through physical walking tests in addition to image inspection.

## Verification results

Latest passing results across the twelve suites total **712 checks**, including targeted retests after route/yard corrections:

| Suite | Checks |
| --- | ---: |
| lisbon_urban | 61 |
| lisbon_environment_art | 220 |
| lisbon_composition | 36 |
| lisbon_direction | 44 |
| lisbon_city | 20 |
| lisbon_circulation | 57 |
| map_art_closure | 90 |
| harbor_visit | 40 |
| lisbon_city_campaign | 24 |
| interface_closure | 34 |
| childhood_bond | 49 |
| adult_arc_closure | 37 |

The new urban test physically walks the residential street, eight public door approaches, original doors/services, both piers and the return route. It checks actual physics under each new house, native image proportions, and preservation of both childhood entrances and the childhood waterfront boundary. The existing tests cover errands, boat release, cart work, saves, campaign continuity, occlusion and HUD behavior. Two former test samples were updated because they intentionally changed from verge/private yard into residential frontage/public doorstep lane; the tests still exercise the remaining verge and reduced private yard.

Run all suites with `./tools/test_lisbon_direction.ps1`. Render with Godot `--path . --script res://tools/capture_lisbon_urban.gd --fixed-fps 60 -- after`; use a workspace-local APPDATA directory for isolated QA.

Godot reports certificate-store and shader-cache access errors in this environment, also present in the baseline; rendering completed without script errors. Some existing campaign suites still report ObjectDB shutdown warnings. Test logs and the aggregate result are in `.qa-runtime/lisbon-direction-tests/` and `.qa-runtime/lisbon-urban/verification.json`.

## Remaining art constraint

The kit supplies two residential paintings, so repeated facades remain visible. Their painted perspective and lighting also differ from the convent illustration. This intervention changes urban structure, circulation and land use; it does not turn those paintings into a varied modular architecture library. The waterfront retains its broad working access and both existing piers for the current campaign.

Pre-existing unrelated checkout changes were preserved. No commit was created.
