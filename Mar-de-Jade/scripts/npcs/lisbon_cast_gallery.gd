extends Node2D
const LIB = preload("res://scripts/npcs/lisbon_npc_library.gd")
var actors: Array[Node2D] = []
var facing := 0
var walking := false
var posture := "standing"
var clock := 0.0
var hint: Label

func _ready() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/lisbon_npcs.json"))
	var title := Label.new(); title.text = "MAR DE JADE · ELENCO DE LISBOA"; title.position = Vector2(28,18); title.add_theme_font_size_override("font_size",26); add_child(title)
	hint = Label.new(); hint.position = Vector2(28,55); add_child(hint)
	for i in catalog.entries.size():
		var entry: Dictionary = catalog.entries[i]
		var actor = load("res://scenes/npcs/lisbon/"+entry.id+".tscn").instantiate()
		actor.position = Vector2(180+(i%4)*360,235+(i/4)*185)
		actor.scale = Vector2.ONE*1.35; add_child(actor); actors.append(actor)
		var label := Label.new(); label.text = entry.name; label.position = actor.position+Vector2(-155,7); label.size.x = 310; label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.add_theme_font_size_override("font_size",18); add_child(label)
		var period := Label.new(); period.text = entry.period; period.position = actor.position+Vector2(-155,32); period.size.x = 310; period.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; period.add_theme_color_override("font_color",Color("b9c9bf")); add_child(period)
	_update_hint()

func _process(delta: float) -> void:
	clock = fposmod(clock+delta*6,3)
	for actor in actors:
		actor.facing = facing; actor.walking = walking; actor.frame_time = clock; actor.posture = posture; actor.queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0,0,1440,900),Color("142e34"))
	for i in 16: draw_style_box(_card(),Rect2(14+(i%4)*360,95+(i/4)*185,332,174))

func _card() -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = Color("294449"); style.set_corner_radius_all(8); return style

func _update_hint() -> void:
	hint.text = "← / → · direção     Espaço · caminhar     S · sentado     C · agachado     I · de pé     |     "+["Frente","Esquerda","Costas","Direita"][facing]

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_LEFT: facing = posmod(facing-1,4)
		KEY_RIGHT: facing = posmod(facing+1,4)
		KEY_SPACE: walking = not walking; posture = "standing"
		KEY_S: posture = "seated"; walking = false
		KEY_C: posture = "crouched"; walking = false
		KEY_I: posture = "standing"
	_update_hint()
