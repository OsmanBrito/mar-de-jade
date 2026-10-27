extends RefCounted
## Hand-authored frontage, not scatter. All coordinates are in the exterior's
## world plane. Existing story doors, staging and pier coordinates stay fixed.
const NEIGHBORHOOD := [Vector2(430,-260),Vector2(1580,-100),Vector2(1720,385),Vector2(1700,760),Vector2(1590,850),Vector2(540,700),Vector2(480,480),Vector2(430,290)]
const WEST_COURT := [Vector2(-885,640),Vector2(-530,650),Vector2(-485,825),Vector2(-645,865),Vector2(-880,790)]
const PUBLIC_ADDITIONS := [NEIGHBORHOOD,WEST_COURT]
# Name, existing painting, ground foot, maximum frame, physical base width/depth.
# The back row steps down toward the river; the convent keeps the high skyline.
const FRONTAGES := [
	["CasaDoEscrivao","house_limestone",Vector2(990,-125),Vector2(335,340),Vector2(270,86)],
	["CasaDaTravessa","house_teal",Vector2(1420,-65),Vector2(245,320),Vector2(180,78)],
	["CasaDoAdro","house_limestone",Vector2(655,105),Vector2(350,370),Vector2(280,90)],
	["CasaDosMercadores","house_teal",Vector2(955,150),Vector2(250,365),Vector2(185,86)],
	["CasaDaRuaDasCordas","house_limestone",Vector2(1245,205),Vector2(350,370),Vector2(280,90)],
	["CasaDaDescida","house_teal",Vector2(550,445),Vector2(250,355),Vector2(180,86)],
	["CasaDoArmazem","house_limestone",Vector2(1145,465),Vector2(335,355),Vector2(270,86)],
	["CasaDosCalafates","house_teal",Vector2(1490,515),Vector2(255,350),Vector2(185,82)],
	["CasaDaRuaDaRoda","house_limestone",Vector2(-675,650),Vector2(330,350),Vector2(265,84)],
	["CasaDoLargo","house_limestone",Vector2(-425,480),Vector2(300,320),Vector2(220,70)]
]
# A continuous private block closes the spaces between houses. Its south edge
# is the street frontage; doors open onto public ground, not grass islands.
const NORTH_BLOCK := [Vector2(500,-250),Vector2(1580,-100),Vector2(1615,170),Vector2(1410,235),Vector2(1105,210),Vector2(1045,170),Vector2(795,125),Vector2(500,65)]
const BLOCKS := [NORTH_BLOCK]
const WALLS := [[Vector2(795,125),Vector2(862,150),42.0],[Vector2(1045,170),Vector2(1105,210),42.0]]
# Continuous public street; its bend opens a small junction at the civic gate.
const NEIGHBORHOOD_WALK := [Vector2(520,260),Vector2(720,275),Vector2(950,305),Vector2(1230,335),Vector2(1535,370),Vector2(1645,450)]
const SERVICE_YARD := [Vector2(625,505),Vector2(1005,505),Vector2(1005,566),Vector2(625,566)]
const MARKET_STALL := Vector2(315,880)
const MARKET_GOODS := Vector2(388,899)
const MARKET_TREE := Vector2(200,790)
const MARKET_BENCH := Vector2(260,795)
static func footprint(row: Array) -> Rect2:
	return Rect2(row[2]-Vector2(row[4].x*.5,row[4].y),row[4])
static func private_ground(at: Vector2) -> bool:
	for polygon in BLOCKS:
		if Geometry2D.is_point_in_polygon(at,PackedVector2Array(polygon)): return true
	for row in FRONTAGES:
		if footprint(row).has_point(at): return true
	return false
