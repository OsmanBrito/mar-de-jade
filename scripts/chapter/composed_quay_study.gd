extends Node2D
## Playable preview shares the exact quay used in chapter one, without campaign saves.
@export var map_scene: PackedScene = preload("res://scenes/maps/cais_vivo.tscn")
var world
var duarte: Node2D
var overview_camera: Camera2D
var overview := false
var dialogue: PanelContainer
var message: Label
var context: Label
var points := [Vector2(612,752),Vector2(147,534.5),Vector2(1002,1037)]
var descriptions := ["À sombra do armazém, a passagem fica livre para quem carrega e para quem precisa de ajuda.","Roupa a secar, vasos à porta e uma rua que continua para o interior de Lisboa.","Cordas tensas, carga à espera e a caravela atracada junto ao pontão."]
func _ready() -> void:
	var bindings = preload("res://scripts/main.gd").new(); bindings.configure_input(); bindings.free()
	world = map_scene.instantiate(); world.player_scene = preload("res://scenes/chapter_01/child_player.tscn"); add_child(world)
	world.player.presentation.identity = "hero"
	world.player.camera_zoom = 1.05; world.player.camera.offset = Vector2(90,-90)
	duarte = preload("res://scripts/chapter/actor_proxy.gd").new(); duarte.npc_id = "duarte"; duarte.position = Vector2(542,857); world.sorted_world.add_child(duarte)
	overview_camera = Camera2D.new(); overview_camera.position = Vector2(500,745); overview_camera.zoom = Vector2.ONE*0.78; overview_camera.enabled = false; add_child(overview_camera)
	_interface()
func _interface() -> void:
	var canvas := CanvasLayer.new(); add_child(canvas)
	var root := Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE; canvas.add_child(root)
	var panel := PanelContainer.new(); panel.position = Vector2(24,22); panel.size = Vector2(360,92); panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new(); style.bg_color = Color(0.045,0.11,0.11,0.94); style.border_color = Color("9a8860"); style.border_width_left = 3; style.set_content_margin_all(15); panel.add_theme_stylebox_override("panel",style); root.add_child(panel)
	var text := Label.new(); text.text = "LISBOA  ·  O CAIS\nExplora a rua e encontra Duarte."; text.add_theme_font_size_override("font_size",19); text.add_theme_color_override("font_color",Color("e8ddbd")); panel.add_child(text)
	context = Label.new(); context.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM); context.offset_left = -320; context.offset_right = 320; context.offset_top = -99; context.offset_bottom = -64; context.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; context.add_theme_font_size_override("font_size",20); context.add_theme_color_override("font_outline_color",Color("142c2b")); context.add_theme_constant_override("outline_size",8); root.add_child(context)
	var hint := Label.new(); hint.text = "WASD / setas · mover     Clique · caminhar     E · interagir     M · ver o cais     R · início"; hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); hint.offset_top = -38; hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; hint.add_theme_color_override("font_outline_color",Color("142c2b")); hint.add_theme_constant_override("outline_size",6); root.add_child(hint)
	dialogue = PanelContainer.new(); dialogue.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); dialogue.offset_left = 170; dialogue.offset_right = -170; dialogue.offset_top = -230; dialogue.offset_bottom = -68; dialogue.add_theme_stylebox_override("panel",style.duplicate()); root.add_child(dialogue)
	message = Label.new(); message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; message.add_theme_font_size_override("font_size",20); dialogue.add_child(message); dialogue.hide()
func _process(_delta: float) -> void:
	if not is_instance_valid(world): return
	context.text = ""
	if dialogue.visible: return
	if world.player.position.distance_to(duarte.position)<110: context.text = "[E]  Falar com Duarte"
	else:
		for point in points:
			if world.player.position.distance_to(point)<90: context.text = "[E]  Observar"
func set_overview(value: bool) -> void:
	overview = value; world.player.camera.enabled = not value; overview_camera.enabled = value
func _unhandled_input(event: InputEvent) -> void:
	var viewport := get_viewport()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_M: set_overview(not overview); viewport.set_input_as_handled(); return
		if event.keycode==KEY_R:
			world.player.position = world.get_node("Spawn").position; world.player.destination_path.clear(); world.player.camera.reset_smoothing(); set_overview(false)
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		if dialogue.visible: dialogue.hide(); world.player.enabled = true
		else:
			var text := ""
			if world.player.position.distance_to(duarte.position)<110: text = "DUARTE\n\nEu seguro. Conta comigo, não com a tua pressa."
			else:
				for i in points.size():
					if world.player.position.distance_to(points[i])<90: text = descriptions[i]; break
			if not text.is_empty():
				message.text = text+"\n\n[E / Enter para fechar]"; dialogue.show(); world.player.enabled = false; world.player.destination_path.clear()
		viewport.set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not dialogue.visible:
		world.walk_to(world.get_global_mouse_position())
