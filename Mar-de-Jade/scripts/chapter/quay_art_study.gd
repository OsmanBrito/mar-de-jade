extends Node2D
## Interactive visual study; does not read or write campaign progress.
const ART = preload("res://scripts/chapter/quay_sprite.gd")
@export var map_scene: PackedScene = preload("res://scenes/maps/cais.tscn")
var world
var hero
var duarte
var dialogue: PanelContainer

func _ready() -> void:
	var bindings = preload("res://scripts/main.gd").new()
	bindings.configure_input(); bindings.free()
	world = map_scene.instantiate()
	world.set_script(preload("res://scripts/chapter/plaza_world.gd"))
	world.player_scene = preload("res://scenes/chapter_01/child_player.tscn")
	var sorted = world.get_node("ActorsAndProps")
	for child in sorted.get_children():
		if child.get_script() == preload("res://scripts/interaction.gd"):
			child.free()
	world.get_node("Spawn").position = Vector2(50,480)
	add_child(world)
	hero = ART.new(); hero.identity = "hero"
	world.player.presentation.hide(); world.player.add_child(hero)
	world.player.camera.offset = Vector2(80,-90)
	world.player.camera_zoom = 1.15
	duarte = ART.new(); duarte.identity = "duarte"; duarte.position = Vector2(160,485)
	sorted.add_child(duarte)
	var body := StaticBody2D.new(); body.collision_mask = 0; duarte.add_child(body)
	var shape := CollisionPolygon2D.new(); shape.polygon = PackedVector2Array([Vector2(-12,-6),Vector2(12,-6),Vector2(14,5),Vector2(-14,5)]); body.add_child(shape)
	_add_prop("Amarra",0,Vector2(-155,570),70,Vector2(24,12))
	_add_prop("Carro",1,Vector2(300,422),145,Vector2(44,23))
	_add_prop("Redes",2,Vector2(-180,440),105,Vector2(37,14))
	_add_prop("Carga",3,Vector2(375,560),105,Vector2(34,20))
	_ground_variation()
	world.rebuild_navigation()
	_interface()

func _process(_delta: float) -> void:
	if hero == null: return
	hero.walking = world.player.walking; hero.facing = world.player.facing; hero.frame_time = world.player.frame_time

func _add_prop(label: String,index: int,point: Vector2,width: float,radius: Vector2) -> void:
	var r: Array = ART.metadata().props.frames[index]
	var texture := AtlasTexture.new(); texture.atlas = ART.artwork("props"); texture.region = Rect2(r[0],r[1],r[2],r[3])
	var prop := Node2D.new(); prop.name = label; prop.position = point
	var sprite := Sprite2D.new(); sprite.texture = texture; sprite.scale = Vector2.ONE*width/r[2]
	sprite.position.y = -r[3]*sprite.scale.y*0.5+radius.y; prop.add_child(sprite)
	var body := StaticBody2D.new(); body.collision_mask = 0; prop.add_child(body)
	var shape := CollisionPolygon2D.new()
	shape.polygon = PackedVector2Array([Vector2(-radius.x,0),Vector2(0,-radius.y),Vector2(radius.x,0),Vector2(0,radius.y)])
	body.add_child(shape); world.sorted_world.add_child(prop)

func _ground_variation() -> void:
	# Broad low-contrast variations break repeated paving; base stone artwork remains intact.
	var material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
varying vec2 ground_position;
void vertex(){ ground_position=VERTEX; }
void fragment(){
	 vec4 tex=COLOR;
 float wear=sin(ground_position.x*0.009+sin(ground_position.y*0.018))*sin(ground_position.y*0.011);
 float dirt=smoothstep(0.25,0.85,wear);
 tex.rgb=mix(tex.rgb,tex.rgb*vec3(0.78,0.81,0.73),dirt*0.45);
 COLOR=tex;
}
"""
	material.shader = shader; world.terrain.material = material

func _interface() -> void:
	var canvas := CanvasLayer.new(); add_child(canvas)
	var root := Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE; canvas.add_child(root)
	var backing := Panel.new(); backing.position = Vector2(20,16); backing.size = Vector2(470,74); backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var header_style := StyleBoxFlat.new(); header_style.bg_color = Color(0.05,0.12,0.12,0.9); header_style.border_color = Color("8c805f"); header_style.border_width_bottom = 1; backing.add_theme_stylebox_override("panel",header_style); root.add_child(backing)
	var title := Label.new(); title.text = "MAR DE JADE  /  CAIS DE PORTUGAL"; title.position = Vector2(32,24); title.add_theme_font_size_override("font_size",23); title.add_theme_color_override("font_color",Color("eadfc5")); root.add_child(title)
	var subtitle := Label.new(); subtitle.text = "Estudo de arte · protagonista e Duarte"; subtitle.position = Vector2(34,57); subtitle.add_theme_color_override("font_color",Color("c7b993")); root.add_child(subtitle)
	var hint := Label.new(); hint.text = "WASD / setas · mover     Clique · caminhar     E · falar com Duarte     R · voltar ao início"; hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); hint.offset_top = -45; hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; root.add_child(hint)
	dialogue = PanelContainer.new(); dialogue.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); dialogue.offset_left = 140; dialogue.offset_right = -140; dialogue.offset_top = -200; dialogue.offset_bottom = -65
	var style := StyleBoxFlat.new(); style.bg_color = Color("142c2c"); style.border_color = Color("a29268"); style.set_border_width_all(1); style.set_content_margin_all(22); dialogue.add_theme_stylebox_override("panel",style)
	var text := Label.new(); text.text = "DUARTE\n\nEu seguro. Conta comigo, não com a tua pressa.\n\n[E / Enter para fechar]"; text.add_theme_font_size_override("font_size",19); dialogue.add_child(text); root.add_child(dialogue); dialogue.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		world.player.position = Vector2(50,480); world.player.facing = 0; world.player.destination_path.clear(); world.player.camera.reset_smoothing()
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		if dialogue.visible:
			dialogue.hide(); world.player.enabled = true
		elif world.player.position.distance_to(duarte.position)<130:
			dialogue.show(); world.player.enabled = false; world.player.destination_path.clear()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not dialogue.visible:
		world.walk_to(world.get_global_mouse_position())
