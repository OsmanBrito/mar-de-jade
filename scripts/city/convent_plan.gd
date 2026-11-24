extends RefCounted
## The Lisbon house is fictional; the historical Convento de Cristo remains in Tomar.
const EXTERIOR_WIDTH := 1360.0
const EXTERIOR_ORIGIN := Vector2(-1042,-512)
const PORTARIA := Vector2(-770,65)
const ARCADE := Vector2(238,140)
const FRONTAGE := [Vector2(-1030,-60),Vector2(-850,20),Vector2(-770,20),Vector2(-700,35),Vector2(-550,70),Vector2(25,145),Vector2(310,75)]
const EXTERIOR_FOOTPRINT := [Vector2(-1030,-510),Vector2(310,-510),Vector2(310,75),Vector2(25,145),Vector2(-550,70),Vector2(-700,35),Vector2(-770,20),Vector2(-850,20),Vector2(-1030,-60)]
const BOUNDS := Rect2(-1100,-960,2620,1990)
const CHAPTER_ROOM := Rect2(80,-920,620,510)
const CHAPEL_OFFSET := Vector2(-240,0)
const CHAPEL_ENTRY := Vector2(-240,190)
const CHAPEL := Rect2(-550,-420,620,660)
const CLOISTER := Rect2(-360,180,720,730)
const INFIRMARY := Rect2(360,230,610,570)
const DORMITORY := Rect2(-1000,270,500,480)
const REFECTORY := Rect2(430,-360,500,510)
const KITCHEN := Rect2(1050,-360,400,510)
const SCRIPTORIUM := Rect2(80,-350,310,500)
const ARMORY := Rect2(-1000,790,500,220)
const FLOORS := [CHAPTER_ROOM,Rect2(210,-440,110,110),SCRIPTORIUM,ARMORY,Rect2(210,140,110,80),Rect2(-820,720,160,100),CLOISTER,CHAPEL,Rect2(290,420,180,160),INFIRMARY,DORMITORY,Rect2(-520,620,180,120),REFECTORY,Rect2(600,140,150,130),KITCHEN,Rect2(900,-60,180,120)]
static var continuous_floor: Array[PackedVector2Array] = []
static func surfaces() -> Array[PackedVector2Array]:
	if not continuous_floor.is_empty(): return continuous_floor
	for room in FLOORS:
		var polygon := PackedVector2Array([room.position,room.position+Vector2(room.size.x,0),room.end,room.position+Vector2(0,room.size.y)])
		var index := 0
		while index<continuous_floor.size():
			var joined := Geometry2D.merge_polygons(polygon,continuous_floor[index])
			if joined.size()==1:
				polygon = joined[0]; continuous_floor.remove_at(index); index = 0
			else: index += 1
		continuous_floor.append(polygon)
	return continuous_floor
# A 140-unit opening on the west side connects the church to the cloister.
const NORTH_WALLS := [Rect2(-360,173,50,14),Rect2(-170,173,350,14),Rect2(285,173,75,14)]
const ARCADE_ROWS := [300,780]
const PIER_CENTERS := [-320,-108,108,320]
const PIER_SIZE := Vector2(48,30)
const SIDE_PIERS := [Vector2(-320,460),Vector2(-320,600),Vector2(320,460),Vector2(320,600)]
const CISTERN := Vector2(-5,685)
const CISTERN_FOOTPRINT := Rect2(-40,667,70,30)
const GARDEN := Rect2(-165,385,330,235)
const SPAWN := Vector2(0,805)
const NOTES := {
	"dormitory":{"point":Vector2(-700,600),"title":"O dormitório do acolhimento","text":"As camas ficam afastadas da passagem entre o armário e o claustro. Cada criança guarda a roupa de uso diário junto do seu lugar; os panos de reserva ficam no armário comum. O corredor poente liga o dormitório ao acolhimento de Tomé."},
	"refectory":{"point":Vector2(680,70),"title":"A mesa comum","text":"O pão e as porções chegam da cozinha pelo corredor nascente. A mesa reúne crianças, irmãos e ajudantes. Os bancos deixam livre a passagem central para quem leva os recipientes; depois da refeição, cada pessoa recolhe o que usou."},
	"kitchen":{"point":Vector2(1340,55),"title":"O trabalho da cozinha","text":"A lareira mantém o caldo quente, enquanto a mesa de trabalho recebe o pão e os recipientes. Os mantimentos conferidos no adro são separados aqui antes de seguirem para o refeitório. A água e os panos de serviço ficam fora do alcance das brasas."},
	"water":{"point":Vector2(0,735),"title":"O jardim e a cisterna","text":"A água recolhida nos telhados chega à cisterna do claustro. Daqui seguem os cântaros para a cozinha e para as bacias da enfermaria. Nos canteiros crescem plantas de uso doméstico; cada vaso traz uma pequena marca, para evitar trocas."},
	"rule":{"point":Vector2(-265,350),"title":"A regra da casa","text":"Na mesa do corredor ficam as tarefas do dia: limpar os bancos, levar água, cuidar da roupa e repartir o pão. As crianças aprendem a ler e a contar com os irmãos da casa. A cruz no estandarte pertence à Ordem de Cristo; a memória dos Templários é guardada aqui como parte de uma história mais antiga."},
	"chapel":{"point":Vector2(-240,-125),"title":"A capela da Ordem","text":"A capela ocupa o lado poente da casa e abre-se para o corredor norte do claustro. A cruz vermelha com o centro branco repete o emblema da portaria e das roupas de serviço de Duarte. Esta casa de Lisboa mantém ligação ao Convento de Cristo, em Tomar. Nos bancos há lugar para os irmãos, para as crianças e para quem procura abrigo."},
	"linen":{"point":Vector2(570,600),"title":"Roupa limpa e água","text":"Os panos limpos estão separados dos usados. Junto das camas há bacias, água e espaço para quem ajuda. O cuidado aqui é feito com trabalho, repouso e observação; os instrumentos são preparados antes de receber alguém."},
	"attendant":{"point":Vector2(810,485),"title":"Ajudante da enfermaria","text":"As passagens entre as camas ficam livres. Quem chega precisa de ar e de sossego. O Tomé costuma atender no acolhimento; se precisas dele, a porta fica no lado poente do claustro."}
}
static func observed(progress,id: String) -> bool:
	return progress.flags.get("convent_read_"+id,false)
static func observe(progress,id: String) -> void:
	if NOTES.has(id): progress.flags["convent_read_"+id] = true
static func title(p: Vector2) -> String:
	if CHAPTER_ROOM.has_point(p):return "Ordem de Cristo · Sala do Capítulo"
	if ARMORY.has_point(p): return "Ordem de Cristo · Armaria e prática"
	if SCRIPTORIUM.has_point(p): return "Ordem de Cristo · Secretaria e estudo"
	if DORMITORY.has_point(p) or (p.x< -360 and p.y>240): return "Ordem de Cristo · Dormitório"
	if p.y<230 and p.x>1000: return "Ordem de Cristo · Cozinha"
	if p.y<230 and p.x>400: return "Ordem de Cristo · Refeitório"
	if p.y<180: return "Ordem de Cristo · Capela"
	if p.x>360: return "Ordem de Cristo · Enfermaria"
	return "Ordem de Cristo · Claustro do acolhimento"
static func camera_focus(at: Vector2) -> Vector2:
	var cloister := Vector2(clampf(at.x*.25,-70,70),clampf(at.y-75,400,560))
	if at.x>80 and at.x<700 and at.y< -330:
		return Vector2(390,-605).lerp(Vector2(235,-60),smoothstep(-440,-330,at.y))
	if ARMORY.has_point(at): return Vector2(-750,885)
	if at.x< -400 and at.y>240:
		return Vector2(-750,lerpf(500,885,smoothstep(720,820,at.y)))
	if SCRIPTORIUM.has_point(at): return Vector2(235,-60)
	if at.x>900 and at.y<170:
		return Vector2(lerpf(680,1240,smoothstep(900,1090,at.x)),-70)
	if REFECTORY.has_point(at): return Vector2(680,-70)
	if at.x>430 and at.y>=140 and at.y<270:
		return Vector2(680,lerpf(-70,420,smoothstep(140,270,at.y)))
	if CHAPEL.has_point(at) or (at.x> -500 and at.x< -100 and at.y<320):
		var chapel := Vector2(CHAPEL_OFFSET.x,clampf(at.y-110,-230,-100))
		return chapel.lerp(cloister,smoothstep(180,320,at.y))
	if at.x>280 and at.y>230:
		return cloister.lerp(Vector2(665,clampf(at.y-60,395,535)),smoothstep(300,490,at.x))
	return cloister
static func contains(p: Vector2) -> bool:
	var inside := false
	for floor in FLOORS:
		if floor.has_point(p): inside = true; break
	return inside and not GARDEN.grow(10).has_point(p)

static func migrate_v6_journey(value: Variant) -> Variant:
	if not value is Dictionary: return value
	var result: Dictionary = value.duplicate(true)
	if result.get("area","")!="convent": return result
	var position: Variant = result.get("position")
	if not position is Array or position.size()!=2: return result
	for number in position:
		if not (number is int or number is float) or not is_finite(float(number)): return result
	var point := Vector2(position[0],position[1])
	# Translate only the former church; all other saved rooms retain their coordinates.
	if point.y<180 and Rect2(-310,-420,620,600).has_point(point):
		point += CHAPEL_OFFSET
		result.position = [point.x,point.y]
	return result
