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
# Lisbon render colours (plaster only; stone, roof and shutters stay painted).
const PLASTER := {
	"cal":Color("e6e0cf"), "ocre":Color("e2b866"), "rosa":Color("e3a593"), "amarelo":Color("efd27a"),
	"azul":Color("9dbfcf"), "salmao":Color("e8b48f"), "verde":Color("a9c3a2"),
}
# Colour and mirroring of the frontage houses, by name. Mirroring turns the
# painted side wall to the left, closing a row from that end.
const FRONTAGE_LOOK := {
	"CasaDoEscrivao":["ocre",false], "CasaDaTravessa":["azul",false], "CasaDoAdro":["cal",true],
	"CasaDosMercadores":["rosa",false], "CasaDaRuaDasCordas":["amarelo",false], "CasaDaDescida":["salmao",true],
	"CasaDoArmazem":["cal",false], "CasaDosCalafates":["verde",false], "CasaDaRuaDaRoda":["rosa",false],
	"CasaDoLargo":["amarelo",true],
}
# Row houses: infill joining the frontages into continuous terraces (casario).
# They stand on private or otherwise unused ground and never occupy a street,
# a door approach or a story position. [name, painting, foot, frame, base, plaster, mirror]
const ROW_HOUSES := [
	# Back of the northern block: a second row of roofs rising behind the street.
	["CasarioNorteA","house_teal",Vector2(790,-175),Vector2(240,320),Vector2(170,60),"amarelo",true],
	["CasarioNorteB","house_limestone",Vector2(1200,-125),Vector2(320,330),Vector2(240,60),"rosa",false],
	["CasarioNorteC","house_teal",Vector2(1600,-30),Vector2(240,320),Vector2(170,60),"cal",false],
	# South side of Rua dos Mercadores, between the descent and the warehouse house.
	["CasarioDaRuaA","house_limestone",Vector2(735,498),Vector2(310,330),Vector2(200,56),"azul",false],
	["CasarioDaRuaB","house_teal",Vector2(930,505),Vector2(235,320),Vector2(150,56),"ocre",false],
	# Eastern end of the street, closing the bend toward the harbour.
	["CasarioDoNascente","house_teal",Vector2(1545,285),Vector2(235,315),Vector2(150,56),"rosa",false],
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
	for row in FRONTAGES+ROW_HOUSES:
		if footprint(row).has_point(at): return true
	return false
