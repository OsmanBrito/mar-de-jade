extends Control
## Bust portrait for the dialogue panel, cropped from each character's front frame.
## No separate portrait art exists yet: the illustrated walk sheets already have faces.
const NPC_ART = preload("res://scripts/npcs/lisbon_npc_library.gd")
const QUAY_ART = preload("res://scripts/chapter/quay_sprite.gd")
const NAMES := {
	"Duarte":"duarte", "Rodrigo":"rodrigo", "Beatriz":"beatriz", "Mestre":"master",
	"Combatente":"combatant", "Trabalhador ferido":"injured_worker", "Trabalhador":"worker",
	"Mulher do cais":"dock_woman", "Observador":"observer", "Familiar":"family",
	"Vizinha":"attendant", "Vizinha da cozinha":"attendant", "Ajudante da cozinha":"attendant",
	"Acompanhante":"attendant", "Criança":"shelter_child", "Leonor criança":"leonor_child",
	"Leonor":"leonor_adult", "Tomé":"tome_adult",
}
const JADE := Color("3f8f78")
const GOLD := Color("d9bc80")
var art_id := ""
var childhood := false
var texture: Texture2D
var region := Rect2()

## Picks the portrait for a speaker line; returns false when nobody is speaking.
func show_speaker(speaker: String,hero_name: String,in_childhood: bool) -> bool:
	childhood = in_childhood
	var id: String = NAMES.get(speaker,"")
	if speaker == hero_name or speaker.begins_with("Herói"): id = "hero_child" if childhood else "hero"
	if id == "tome_adult" and childhood: id = "tome_young"
	if id == "leonor_adult" and childhood: id = "leonor_child"
	if id != art_id:
		art_id = id
		_resolve()
		queue_redraw()
	return texture != null

func _resolve() -> void:
	texture = null
	if art_id.is_empty(): return
	var frame: Array
	if art_id == "hero":
		var info: Dictionary = QUAY_ART.metadata().hero
		texture = QUAY_ART.artwork("hero"); frame = info.frames[0]
	else:
		var entries := NPC_ART.data()
		if not entries.has(art_id): return
		var entry: Dictionary = entries[art_id]
		texture = load(entry.source) if ResourceLoader.exists(entry.source) else null
		if texture == null: return
		frame = entry.frames[0]
	# Head and shoulders: a square from the top of the front-facing frame.
	var side: float = minf(frame[2]*1.05,frame[3]*0.36)
	region = Rect2(frame[0]+frame[2]*0.5-side*0.5,frame[1]+frame[3]*0.015,side,side)

func _draw() -> void:
	var r := Rect2(Vector2.ZERO,size)
	var center := r.get_center()
	var radius := minf(size.x,size.y)*0.5
	# Medallion: dark jade field, soft inner light, gold rims.
	draw_circle(center,radius,Color("0b1d1c"))
	for ring in range(8,0,-1):
		draw_circle(center+Vector2(0,-radius*0.18),radius*float(ring)/9.0,Color(JADE,0.045))
	if texture != null:
		var inner := radius-6.0
		var points := PackedVector2Array(); var uvs := PackedVector2Array()
		for i in 48:
			var direction := Vector2.from_angle(TAU*i/48.0)
			points.append(center+direction*inner)
			var uv := region.position+region.size*(direction*0.5+Vector2(0.5,0.5))
			uvs.append(uv/texture.get_size())
		draw_colored_polygon(points,Color.WHITE,uvs,texture)
		# Bottom of the bust fades into the medallion instead of ending on a hard cut.
		for i in 10:
			var t := float(i)/10.0
			draw_arc(center,inner*(0.55+t*0.45),PI*0.2,PI*0.8,24,Color(0.043,0.114,0.11,t*0.11),inner*0.06,true)
	draw_arc(center,radius-2,0,TAU,64,Color("3b2c1a"),4,true)
	draw_arc(center,radius-2,0,TAU,64,GOLD,1.6,true)
	draw_arc(center,radius-7,0,TAU,64,Color(GOLD,0.35),1,true)
	# Jade cabochon at the base of the frame.
	var gem := center+Vector2(0,radius-2)
	draw_colored_polygon(PackedVector2Array([gem+Vector2(0,-7),gem+Vector2(6,0),gem+Vector2(0,7),gem+Vector2(-6,0)]),JADE)
	draw_polyline(PackedVector2Array([gem+Vector2(0,-7),gem+Vector2(6,0),gem+Vector2(0,7),gem+Vector2(-6,0),gem+Vector2(0,-7)]),GOLD,1.2,true)
	draw_circle(gem+Vector2(-1.5,-2),1.6,Color(1,1,1,0.45))
