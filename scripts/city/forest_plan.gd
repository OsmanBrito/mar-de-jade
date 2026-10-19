extends RefCounted
const BOUNDS := Rect2(-300,-300,3500,2200)
const SPAWN := Vector2(180,850)
const LAND := [Vector2(-100,240),Vector2(800,100),Vector2(1200,280),Vector2(1800,0),Vector2(2700,180),Vector2(3000,700),Vector2(2800,1350),Vector2(2100,1550),Vector2(1700,1380),Vector2(1200,1650),Vector2(500,1500),Vector2(-120,950)]
const RIVER := Rect2(1400,-300,120,2200)
const WATER := [Vector2(1400,-300),Vector2(1420,150),Vector2(1380,380),Vector2(1400,640),Vector2(1400,860),Vector2(1440,1140),Vector2(1390,1400),Vector2(1400,1900),Vector2(1520,1900),Vector2(1510,1400),Vector2(1560,1140),Vector2(1520,860),Vector2(1520,640),Vector2(1500,380),Vector2(1540,150),Vector2(1520,-300)]
const BRIDGE := Rect2(1360,640,200,160)
const TRAIL := [Vector2(100,850),Vector2(340,780),Vector2(600,1050),Vector2(820,1050),Vector2(1000,700),Vector2(1460,730),Vector2(1810,750),Vector2(2030,950),Vector2(2280,1100),Vector2(2450,1050),Vector2(2500,650),Vector2(2350,350)]
const GOALS := [Vector2(340,780),Vector2(600,1050),Vector2(1000,700),Vector2(1460,730),Vector2(2030,950),Vector2(2280,1100),Vector2(2280,1100),Vector2(2350,350),Vector2(180,850)]
const LABELS := ["Combinar a procura com Leonor","Examinar as pegadas na lama","Procurar o sinal na árvore","Atravessar a ponte com Leonor","Subir à clareira","Procurar Leonor entre as árvores","O urso fecha a passagem","Encontrar o corço branco","Regressar pelo caminho de Lisboa"]
const DISCOVERIES := {
	"shelter":{"at":Vector2(630,500),"title":"Um abrigo entre raízes","text":"As raízes abrigam um ninho baixo. Leonor afasta um ramo sem tocar nos ovos. Diz que nem tudo o que se encontra numa caçada precisa de ser levado para casa."},
	"charcoal":{"at":Vector2(1090,1290),"title":"A clareira dos carvoeiros","text":"A terra escura guarda o círculo de uma antiga queima. Há marcas de carro na entrada; gente da cidade também passa por esta floresta. Leonor reconhece um atalho, mas prefere manter o caminho da ponte."},
	"tracks":{"at":Vector2(1850,1200),"title":"Duas marcas diferentes","text":"Uma pata larga afundou a margem. Mais perto da água, dois sinais estreitos apontam para norte. Leonor compara as distâncias: o animal que procuram não é o maior que anda por aqui."}
}
static func discovery_path(id: String) -> Array:
	var destination: Vector2 = DISCOVERIES[id].at
	var connection := TRAIL[0]; var distance := INF
	for i in TRAIL.size()-1:
		var candidate := Geometry2D.get_closest_point_to_segment(destination,TRAIL[i],TRAIL[i+1])
		if candidate.distance_squared_to(destination)<distance:
			distance = candidate.distance_squared_to(destination); connection = candidate
	return [connection,connection.lerp(destination,.5)+Vector2(16,-9),destination]
static func distance_to_trails(at: Vector2) -> float:
	var distance := INF
	var paths: Array = [TRAIL]
	for id in DISCOVERIES: paths.append(discovery_path(id))
	for path in paths:
		for i in path.size()-1: distance = minf(distance,at.distance_to(Geometry2D.get_closest_point_to_segment(at,path[i],path[i+1])))
	return distance
static func contains(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point,PackedVector2Array(LAND)) and (not Geometry2D.is_point_in_polygon(point,PackedVector2Array(WATER)) or BRIDGE.has_point(point))
static func title(point: Vector2) -> String:
	return "Arredores de Lisboa · Caminho dos olivais" if point.x<1250 else "Vale da ponte" if point.x<1800 else "Bosque do corço branco"
