extends RefCounted
## Metres in the Blender-authored X/Z floor plan. Navigation and saves share it.
const SCENE := "res://scenes/chapter_01/childhood_home.tscn"
const SPAWN := Vector2(-7.2, 9.0)
const ROOMS := [Rect2(-10.6,5.25,7.8,7.1),Rect2(-7.05,4.2,1.5,1.5),Rect2(-11.1,-10.1,22.2,14.8)]
const SOLIDS := [
	Rect2(-10,5.6,1.45,2.8),Rect2(-10,9.2,1.45,2.8),Rect2(-5.2,8.85,2,1.3),
	Rect2(-4.3,-3.75,3.6,2.5),Rect2(.7,-3.75,3.6,2.5),
	Rect2(-4.3,-.75,3.6,2.5),Rect2(.7,-.75,3.6,2.5),
	Rect2(-1.15,-2.15,2.3,2.3),Rect2(-10.4,-7.3,2.8,1.1),
	Rect2(2.7,-9.3,3.9,1.9),Rect2(-5,-9.5,3.1,1.3),
	Rect2(8.5,-1.5,1,1),Rect2(10.15,-.6,.9,2.9)
]
const PLACES := {
	"tome":{"at":Vector2(-6.3,8.4),"title":"Falar com Tomé"},
	"bowl":{"at":Vector2(-8,8.1),"title":"A tigela junto da cama"},
	"table":{"at":Vector2(-5.9,9.5),"title":"Sentar à mesa"},
	"child":{"at":Vector2(-8.4,3.3),"title":"Falar com a criança"},
	"stone":{"at":Vector2(-9,-7.9),"title":"A cruz na pedra antiga"},
	"voyage":{"at":Vector2(1,-8.2),"title":"Os preparativos da viagem"},
	"practice":{"at":Vector2(7.7,.5),"title":"Experimentar o alvo de treino"},
	"leonor":{"at":Vector2(0,-8.9),"title":"Leonor · ir até à praça"}
}
const NOTES := {
	"home_stone":{"title":"A cruz na pedra","text":"A pedra escura conserva uma cruz mais antiga. A casa da Ordem foi crescendo à sua volta; Tomé conhece algumas das histórias que aqui se contam."},
	"home_voyage":{"title":"Gente que parte","text":"Os mantimentos já estão separados. Há cavaleiros que deixam a casa para acompanhar as viagens; outras pessoas ficam para alimentar, ensinar e cuidar de quem vive aqui."},
	"home_eyes":{"title":"Um de cada cor","text":"Já te habituaste aos teus olhos. Às perguntas dos outros, nem por isso. Às vezes parece-te que reparas em coisas que eles não veem; ainda não sabes explicar porquê."}
}

static func obstacles() -> Array:
	var result: Array = SOLIDS.duplicate()
	for x in [-6.2,6.2]:
		for z in [-3.7,-.6,2.5]:
			for side in [-1,1]: result.append(Rect2(x-.29,z+side*1.49-.29,.58,.58))
	for x in [-7.6,-4.6,4.6,7.6]:
		for side in [-1,1]: result.append(Rect2(x+side*1.435-.29,-5.8,.58,.6))
	# The raised central arch reuses the former outer posts and opens the
	# middle axis. Previously walkable saved positions remain valid.
	for x in [-3.035,3.035]:result.append(Rect2(x-.29,-5.8,.58,.6))
	return result

static func clear(point: Vector2, margin: float = .23) -> bool:
	var inside := false
	for room in ROOMS:
		if room.has_point(point): inside = true; break
	if not inside: return false
	for offset in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		var sample: Vector2 = point+offset*margin
		if not ROOMS.any(func(room):return room.has_point(sample)): return false
	for solid in obstacles():
		if solid.grow(margin).has_point(point): return false
	return true

static func title(point: Vector2) -> String:
	if point.y>4.7:return "A casa de Tomé"
	if point.y< -6:return "A galeria das partidas"
	if point.x>6:return "O pátio de armas"
	if point.x< -6:return "A memória da Ordem"
	return "O claustro"

static func objective(flags: Dictionary) -> String:
	if not flags.get("home_meal",false):return "Senta-te à mesa com Tomé. A Leonor já veio à tua procura."
	return "Encontra a Leonor junto à portaria, do outro lado do claustro. Vão juntos à praça."
