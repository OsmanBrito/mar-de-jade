extends RefCounted
## Parcels and public spaces share the same plan as walls and collision.
const WEST_GARDEN := [Vector2(-495,530),Vector2(-6,530),Vector2(-6,635),Vector2(-59,680),Vector2(-460,680),Vector2(-495,610)]
const SERVICE_COURT := [Vector2(1070,590),Vector2(1580,590),Vector2(1580,672),Vector2(1070,672)]
const PARCELS := [WEST_GARDEN,SERVICE_COURT]
const WALLS := [
	[Vector2(-495,530),Vector2(-6,530),62.0],
	[Vector2(-495,530),Vector2(-495,610),54.0],
	[Vector2(-495,610),Vector2(-460,680),54.0],
	[Vector2(-6,530),Vector2(-6,635),54.0],
	[Vector2(1070,590),Vector2(1580,590),45.0],
	[Vector2(1580,590),Vector2(1580,672),45.0],
	[Vector2(1070,590),Vector2(1070,672),45.0]
]
const MAIN_WALK := [Vector2(180,420),Vector2(420,530),Vector2(452,660),Vector2(440,770),Vector2(510,865),Vector2(610,1038),Vector2(930,1045),Vector2(1160,1065),Vector2(1470,1082),Vector2(1496,1165)]
const MARKET_APRON := [Vector2(490,866),Vector2(720,884),Vector2(835,1014),Vector2(740,1077),Vector2(505,1057),Vector2(455,970)]
const PIER_APRON := [Vector2(1390,1018),Vector2(1575,1038),Vector2(1575,1099),Vector2(1400,1099)]
static func private_ground(at: Vector2) -> bool:
	for polygon in PARCELS:
		if Geometry2D.is_point_in_polygon(at,PackedVector2Array(polygon)): return true
	return false
