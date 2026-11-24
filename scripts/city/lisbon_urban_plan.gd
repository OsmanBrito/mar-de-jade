extends RefCounted
## Hand-authored frontage, not scatter. All coordinates are in the exterior's
## world plane. Existing story doors, staging and pier coordinates stay fixed.
const NEIGHBORHOOD := [Vector2(430,-260),Vector2(1580,-100),Vector2(1725,95),Vector2(1725,525),Vector2(1700,760),Vector2(1590,850),Vector2(540,700),Vector2(480,480),Vector2(430,290)]
const WEST_COURT := [Vector2(-885,640),Vector2(-530,650),Vector2(-485,825),Vector2(-645,865),Vector2(-880,790)]
const PUBLIC_ADDITIONS := [NEIGHBORHOOD,WEST_COURT]
# The district is laid out in horizontal streets, matching the paintings'
# front-facing oblique view: each terrace faces the street directly below it,
# so the street is always in view and the facades line up as one row. A house
# about 330 units tall hides whatever lies behind it, so rows are spaced far
# enough apart for their street to show, and private yards fill the space
# hidden behind each row. Vertical lanes link the streets with each other.
# Name, existing painting, ground foot, maximum frame, physical base width/depth.
# The first two are the high back row (roofs over the north terrace); every
# other frontage opens a door onto a public street.
const FRONTAGES := [
	["CasaDoEscrivao","house_limestone",Vector2(880,-150),Vector2(335,340),Vector2(270,70)],
	["CasaDaTravessa","house_teal",Vector2(1385,-128),Vector2(245,320),Vector2(180,70)],
	# North terrace on Rua Alta, west (adro) to east lane.
	["CasaDoAdro","house_limestone",Vector2(740,22),Vector2(350,370),Vector2(270,72)],
	["CasaDosMercadores","house_teal",Vector2(1000,26),Vector2(250,365),Vector2(180,72)],
	["CasaDaRuaDasCordas","house_limestone",Vector2(1260,30),Vector2(350,370),Vector2(270,72)],
	# South terrace on Rua da Oficina, above the working waterfront.
	["CasaDaDescida","house_teal",Vector2(515,445),Vector2(250,355),Vector2(180,86)],
	["CasaDoArmazem","house_limestone",Vector2(1130,466),Vector2(335,355),Vector2(270,76)],
	["CasaDosCalafates","house_teal",Vector2(1390,470),Vector2(255,350),Vector2(185,76)],
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
	# North terrace: its east end, whose painted side wall faces the east lane.
	["CasarioDoNascente","house_teal",Vector2(1520,34),Vector2(250,355),Vector2(180,72),"verde",false],
	# Back row: roofs of the next street up, behind the north terrace.
	["CasarioNorteA","house_teal",Vector2(640,-165),Vector2(240,320),Vector2(170,60),"amarelo",true],
	["CasarioNorteB","house_limestone",Vector2(1140,-140),Vector2(320,330),Vector2(240,60),"rosa",false],
	["CasarioNorteC","house_teal",Vector2(1590,-110),Vector2(240,320),Vector2(170,60),"cal",false],
	# South terrace: its west end beside the lane from the adro gate.
	["CasarioDaRuaA","house_teal",Vector2(878,462),Vector2(250,350),Vector2(180,76),"ocre",true],
]
# Private ground: behind the north terrace, and the yards between the two
# terraces (hidden behind the south row in the camera's view).
const NORTH_BLOCK := [Vector2(500,-250),Vector2(1580,-110),Vector2(1612,-50),Vector2(560,-50)]
const MIDDLE_BLOCK := [Vector2(745,150),Vector2(1612,150),Vector2(1612,388),Vector2(745,388)]
const BLOCKS := [NORTH_BLOCK,MIDDLE_BLOCK]
const WALLS := []
# Rua Alta in front of the north terrace, then the east lane down to Rua da
# Oficina. The lane from the adro gate is part of Layout.EAST_STREET.
const NEIGHBORHOOD_WALK := [Vector2(590,95),Vector2(900,95),Vector2(1250,95),Vector2(1560,95),Vector2(1665,135),Vector2(1665,300),Vector2(1665,450),Vector2(1660,525)]
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
