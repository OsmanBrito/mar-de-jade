extends Node3D
## Playable presentation experiment; the campaign and its save state are untouched.
const Blocks = preload("res://scripts/city/lisbon_blocks.gd")
const FRAMES := "res://assets/art/portugal-v2/frames.json"
const FLOOR := "res://assets/art/places/limestone-floor-v1.png"
const WALL := "res://assets/art/places/limewash-wall-v1.png"
const SPEED := 4.2
const CAMERA_OFFSET := Vector3(11, 19, 24)
var player: CharacterBody3D
var actor: Sprite3D
var camera: Camera3D
var merchant: Sprite3D
var frame_data: Array
var atlas: Texture2D
var walking_path: Array[Vector3] = []
var route: Array[Vector3] = []
var frame_time := 0.0
var facing := 0
var last_frame := -1
var stage_label: Label
var hint_label: Label
var dialog: PanelContainer
var pixel_material: ShaderMaterial
var pixel_button: Button
var scale_button: Button
var visited: Array[int] = []
var ready_for_test := false
var tour_active := false
var last_checkpoint := 0
var status_label: Label
var surface_textures: Dictionary = {}
var house_group := ""
var house_meshes: Dictionary = {}
var faded_house := ""
var faded_houses: Array[String] = []

static func map_point(at: Vector2) -> Vector3:
	return Vector3(at.x / 80.0, 0, at.y / 40.0)

func _ready() -> void:
	for at in Blocks.MAIN_WALK: route.append(map_point(at))
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FRAMES))
	frame_data = data.hero.frames
	atlas = load(data.hero.path)
	_build_light()
	_build_ground()
	_build_neighborhood()
	_build_player()
	_build_interface()
	player.position = route[0] + Vector3(0, 0.05, 0)
	camera.position = player.position + CAMERA_OFFSET
	camera.look_at(player.position + Vector3(0, 1.0, 0))
	_set_frame(0)
	ready_for_test = true

func material(color: Color, texture: Texture2D = null, uv := Vector3.ONE) -> StandardMaterial3D:
	var value := StandardMaterial3D.new()
	value.albedo_color = color
	if texture != null:
		var key := texture.resource_path
		if not surface_textures.has(key):
			var image := texture.get_image()
			image.generate_mipmaps()
			surface_textures[key] = ImageTexture.create_from_image(image)
		value.albedo_texture = surface_textures[key]
	value.uv1_scale = uv
	value.roughness = 0.95
	value.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return value

func box(label: String, at: Vector3, size: Vector3, surface: Material, solid := true) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = label
	var geometry := BoxMesh.new()
	geometry.size = size
	mesh.mesh = geometry
	mesh.material_override = surface
	mesh.position = at
	add_child(mesh)
	_register_house_mesh(mesh)
	if solid:
		var body := StaticBody3D.new()
		body.name = "Collision"
		mesh.add_child(body)
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collider.shape = shape
		body.add_child(collider)
	return mesh

func _build_light() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("9bb5ae")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c5d6ce")
	environment.ambient_light_energy = 0.4
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "SolDaRibeira"
	sun.rotation_degrees = Vector3(-48, -38, 0)
	sun.light_color = Color("fff2df")
	sun.light_energy = 0.78
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 95
	add_child(sun)

func _build_ground() -> void:
	var floor_texture: Texture2D = load(FLOOR)
	var paving := material(Color("d3c6a4"), floor_texture, Vector3(13, 16, 1))
	box("CalcarioDaCidade", Vector3(5, -0.3, 12), Vector3(46, 0.6, 32), paving)
	var quay_mat := material(Color("a5987b"), floor_texture, Vector3(14, 1.4, 1))
	box("MargemDaRibeira", Vector3(5, -0.2, 27.3), Vector3(46, 0.4, 2.1), quay_mat)
	# The route's last point is over this actual timber pier.
	var wood := material(Color("80623e"))
	box("Pontao", Vector3(18.7, -0.175, 30), Vector3(3.3, 0.35, 7), wood)
	for i in 23:
		box("Tabua_%d" % i, Vector3(18.7, 0.003, 26.7 + i * 0.3), Vector3(3.23, 0.006, 0.27), material(Color("9a7c50") if i % 3 else Color("89704c")), false)
	for x in [17.15, 20.25]:
		for z in [27.1, 30.2, 33.0]:
			box("Esteio", Vector3(x, -0.2, z), Vector3(0.22, 1.6, 0.22), wood)
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode cull_disabled;
void fragment() {
 vec2 p = floor(UV * vec2(260.0, 150.0));
 float a = sin(p.x * .11 + TIME * .65) * cos(p.y * .24 + TIME * .4);
 float b = step(.81, sin(p.x * .17 + p.y * .31 + TIME * .6));
 ALBEDO = mix(vec3(.075,.27,.25),vec3(.19,.40,.34),a*.5+.5) + b*.035;
 ROUGHNESS = .5;
}
"""
	var water := ShaderMaterial.new()
	water.shader = shader
	box("Tejo", Vector3(5, -0.65, 52), Vector3(120, 0.1, 48), water, false)
	# Deep boundaries keep the character on the playable slice, including the pier.
	var invisible := material(Color(0, 0, 0, 0))
	for row in [[Vector3(-18.4, 1, 12), Vector3(0.4, 4, 33)], [Vector3(28.4, 1, 12), Vector3(0.4, 4, 33)], [Vector3(5, 1, -4.3), Vector3(47, 4, 0.4)]]:
		var boundary := box("Limite", row[0], row[1], invisible)
		boundary.visible = false

func roof(at: Vector3, width: float, depth: float) -> void:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Gable ridgeline is along the house's depth. Vertex winding is made visible on both sides.
	var left := Vector3(-width * 0.56, 0, 0)
	var right := Vector3(width * 0.56, 0, 0)
	var ridge := Vector3(0, width * 0.26, 0)
	for side in [[left, ridge], [ridge, right]]:
		var a: Vector3 = side[0] + Vector3(0, 0, -depth * 0.57)
		var b: Vector3 = side[1] + Vector3(0, 0, -depth * 0.57)
		var c: Vector3 = side[1] + Vector3(0, 0, depth * 0.57)
		var d: Vector3 = side[0] + Vector3(0, 0, depth * 0.57)
		for point in [a, b, c, a, c, d]: builder.add_vertex(point)
	builder.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = builder.commit()
	mesh.position = at
	var surface := material(Color("aa5835"))
	surface.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = surface
	add_child(mesh)
	_register_house_mesh(mesh)
	var roof_body := StaticBody3D.new()
	roof_body.name = "RoofCollision"
	mesh.add_child(roof_body)
	var collider := CollisionShape3D.new()
	var roof_shape := BoxShape3D.new()
	roof_shape.size = Vector3(width * 1.12, width * 0.26, depth * 1.14)
	collider.shape = roof_shape
	collider.position.y = width * 0.13
	roof_body.add_child(collider)
	# Individual rows give the roof a readable rhythm at the normal zoom.
	for i in 13:
		var z := -depth * 0.55 + float(i) * depth * 1.1 / 12.0
		for sign_x in [-1, 1]:
			var tile := box("FiadaDeTelha", at + Vector3(sign_x * width * 0.28, width * 0.13 + 0.018, z), Vector3(width * 0.62, 0.045, 0.065), material(Color("c77b49") if i % 3 else Color("9b4b30")), false)
			tile.rotation.z = -sign_x * atan(0.26 / 0.56)

func house(label: String, at: Vector3, width: float, depth: float, height: float, tint: Color) -> void:
	house_group = label
	var facade := material(tint, load(WALL), Vector3(2.5, 2.5, 1))
	box(label, at + Vector3(0, height * 0.5, 0), Vector3(width, height, depth), facade)
	roof(at + Vector3(0, height, 0), width, depth)
	# Close the roof ends with the same plaster as the facade.
	var gables := SurfaceTool.new()
	gables.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sign_z in [-1, 1]:
		for point in [Vector3(-width * 0.5, height, sign_z * depth * 0.5), Vector3(0, height + width * 0.23, sign_z * depth * 0.5), Vector3(width * 0.5, height, sign_z * depth * 0.5)]:
			gables.add_vertex(point)
	gables.generate_normals()
	var gable_mesh := MeshInstance3D.new()
	gable_mesh.mesh = gables.commit()
	gable_mesh.position = at
	var gable_material := facade.duplicate() as StandardMaterial3D
	gable_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	gable_mesh.material_override = gable_material
	add_child(gable_mesh)
	_register_house_mesh(gable_mesh)
	var stone := material(Color("b5a88b"))
	var teal := material(Color("385951"))
	var dark := material(Color("343f36"))
	box("Soco", at + Vector3(0, 0.22, 0), Vector3(width + 0.12, 0.44, depth + 0.12), stone, false)
	var front := at.z + depth * 0.5 + 0.025
	box("Porta", Vector3(at.x, 0.88, front), Vector3(0.8, 1.75, 0.075), material(Color("67513a")), false)
	for x in [-width * 0.3, width * 0.3]:
		for y in [1.3, height - 1.0]:
			box("Moldura", Vector3(at.x + x, y, front), Vector3(0.92, 1.03, 0.12), stone, false)
			box("Janela", Vector3(at.x + x, y, front + 0.075), Vector3(0.67, 0.78, 0.1), dark, false)
			for offset in [-0.37, 0.37]:
				box("Portada", Vector3(at.x + x + offset, y, front + 0.14), Vector3(0.22, 0.83, 0.1), teal, false)
	box("Degrau", Vector3(at.x, 0.09, front + 0.35), Vector3(1.25, 0.18, 0.7), stone)
	house_group = ""

func _register_house_mesh(mesh: MeshInstance3D) -> void:
	if house_group.is_empty(): return
	mesh.set_meta("study_house", house_group)
	if not house_meshes.has(house_group): house_meshes[house_group] = []
	house_meshes[house_group].append(mesh)

func _update_occlusion() -> void:
	var hidden: Array[String] = []
	for height in [0.6, 1.5]:
		var query := PhysicsRayQueryParameters3D.create(camera.global_position, player.global_position + Vector3(0, height, 0))
		var excluded: Array[RID] = [player.get_rid()]
		for depth in 8:
			query.exclude = excluded
			var hit := get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty(): break
			excluded.append(hit.collider.get_rid())
			var key := str(hit.collider.get_parent().get_meta("study_house", ""))
			if not key.is_empty() and key not in hidden: hidden.append(key)
	hidden.sort()
	if hidden == faded_houses: return
	for key in faded_houses + hidden:
		if key.is_empty(): continue
		for mesh in house_meshes[key]:
			var surface: StandardMaterial3D = mesh.material_override
			surface.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if key in hidden else BaseMaterial3D.TRANSPARENCY_DISABLED
			surface.albedo_color.a = 0.2 if key in hidden else 1.0
	faded_houses = hidden
	faded_house = hidden[0] if not hidden.is_empty() else ""

func _build_neighborhood() -> void:
	house("CasaDaPraca", Vector3(-3.5, 0, 7), 5.8, 4.0, 5.1, Color("e6d8b5"))
	house("CasaDaDescida", Vector3(9.5, 0, 11.1), 4.0, 3.1, 5.0, Color("b5c1ad"))
	house("CasaDoLargo", Vector3(-2.7, 0, 16.5), 5.0, 3.6, 4.4, Color("e4d6b6"))
	house("CasaDosMercadores", Vector3(12.3, 0, 17.7), 4.6, 3.4, 5.3, Color("d6d1b0"))
	house("ArmazemDaRibeira", Vector3(16.0, 0, 23.0), 5.3, 3.4, 3.7, Color("dfd4b5"))
	house("OficinaDoCais", Vector3(24.0, 0, 23.3), 4.0, 3.0, 4.5, Color("aab8a7"))
	var wood := material(Color("80613d"))
	# Market to the west of the route. All roof posts share its collision footprint.
	box("Banca", Vector3(3.2, 0.56, 23), Vector3(3.0, 1.12, 1.3), wood)
	for x in [1.6, 4.8]:
		for z in [22.2, 23.8]: box("PosteDaBanca", Vector3(x, 1.25, z), Vector3(0.12, 2.5, 0.12), wood)
	for i in 8:
		box("Toldo", Vector3(1.8 + i * 0.4, 2.55, 23), Vector3(0.4, 0.065, 1.95), material(Color("d9cca7") if i % 2 else Color("526e5b")), false)
	for i in 5:
		box("Cesto", Vector3(2.15 + i * 0.48, 1.25, 23.1), Vector3(0.4, 0.28, 0.48), material(Color("bc8a49")), false)
		box("Fruta", Vector3(2.15 + i * 0.48, 1.43, 23.1), Vector3(0.29, 0.15, 0.34), material(Color("b39346") if i % 2 else Color("78904b")), false)
	for at in [Vector3(11, 0, 26.6), Vector3(12, 0, 26.7), Vector3(21.3, 0, 26.3)]:
		box("Carga", at + Vector3(0, 0.43, 0), Vector3(0.9, 0.86, 0.8), wood)
		for z in [-0.31, 0.31]: box("AroDaCaixa", at + Vector3(0, 0.43, z), Vector3(0.95, 0.92, 0.05), material(Color("b09260")), false)
	for at in [Vector3(-7.4, 0, 11.7), Vector3(-6.8, 0, 23), Vector3(22, 0, 17.4)]: tree(at)
	# Existing original character art is kept intact, including its animation atlas.
	var duarte: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FRAMES)).duarte
	merchant = sprite_frame(load(duarte.path), duarte.frames[0], 1.7)
	merchant.name = "Comerciante"
	merchant.position = Vector3(3.2, 0.04, 21.8)
	add_child(merchant)
	contact_shadow(merchant.position, 0.28)
	for row in [["Praça", route[0] + Vector3(-1.1, 0, -0.8)], ["Mercado", Vector3(5.4, 0, 23.9)], ["Cais", Vector3(17, 0, 27)]]:
		var sign := Label3D.new()
		sign.text = row[0]
		sign.position = row[1] + Vector3(0, 1.7, 0)
		sign.font_size = 56
		sign.pixel_size = 0.009
		sign.modulate = Color("f5e9cc")
		sign.outline_modulate = Color("243d35")
		sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(sign)
		box("PosteDaPlaca", row[1] + Vector3(0, 0.75, 0), Vector3(0.09, 1.5, 0.09), wood)

func tree(at: Vector3) -> void:
	box("Tronco", at + Vector3(0, 1.1, 0), Vector3(0.32, 2.2, 0.35), material(Color("6c6446")))
	for row in [[Vector3(-0.5, 3.1, 0), Vector3(2.1, 1.6, 1.8)], [Vector3(0.7, 3.4, 0.3), Vector3(2.1, 1.9, 2.0)], [Vector3(0, 3.8, -0.5), Vector3(2.0, 1.9, 1.8)]]:
		var canopy := MeshInstance3D.new()
		var shape := SphereMesh.new()
		shape.radial_segments = 10
		shape.rings = 5
		canopy.mesh = shape
		canopy.position = at + row[0]
		canopy.scale = row[1]
		canopy.material_override = material(Color("657552"))
		add_child(canopy)

func sprite_frame(texture: Texture2D, bounds: Array, height: float) -> Sprite3D:
	var sprite := Sprite3D.new()
	var region := AtlasTexture.new()
	region.atlas = texture
	region.region = Rect2(bounds[0], bounds[1], bounds[2], bounds[3])
	sprite.texture = region
	sprite.pixel_size = height / float(bounds[3])
	sprite.offset.y = float(bounds[3]) * 0.5
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.45
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.shaded = false
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return sprite

func contact_shadow(at: Vector3, radius: float) -> MeshInstance3D:
	var shadow := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = 0.006
	shadow.mesh = shape
	shadow.position = at + Vector3(0, 0.025, 0)
	shadow.scale.z = 0.65
	var surface := material(Color("756f53"))
	shadow.material_override = surface
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)
	return shadow

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Viajante"
	add_child(player)
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.23
	shape.height = 1.45
	collider.shape = shape
	collider.position.y = 0.73
	player.add_child(collider)
	actor = sprite_frame(atlas, frame_data[0], 1.75)
	actor.name = "PersonagemIlustrado"
	player.add_child(actor)
	var shadow := contact_shadow(Vector3.ZERO, 0.28)
	remove_child(shadow)
	player.add_child(shadow)
	camera = Camera3D.new()
	camera.name = "CameraDaRibeira"
	camera.fov = 40
	camera.far = 200
	add_child(camera)
	camera.make_current()

func button(text: String, callback: Callable) -> Button:
	var value := Button.new()
	value.text = text
	value.add_theme_font_size_override("font_size", 17)
	value.pressed.connect(callback)
	value.focus_mode = Control.FOCUS_NONE
	return value

func _build_interface() -> void:
	var pixels := CanvasLayer.new()
	pixels.layer = 2
	add_child(pixels)
	var screen := ColorRect.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform sampler2D image : hint_screen_texture, filter_nearest;
uniform float pixel_size = 2.0;
void fragment(){vec2 size=vec2(textureSize(image,0));vec2 uv=(floor(SCREEN_UV*size/pixel_size)+.5)*pixel_size/size;COLOR=vec4(textureLod(image,uv,0.0).rgb,1.0);}
"""
	pixel_material = ShaderMaterial.new()
	pixel_material.shader = shader
	pixel_material.set_shader_parameter("pixel_size", 2.0)
	screen.material = pixel_material
	pixels.add_child(screen)
	var hud := CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	var panel := PanelContainer.new()
	panel.position = Vector2(22, 20)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.105, 0.09, 0.94)
	style.border_color = Color("82795a")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 13
	style.content_margin_bottom = 13
	panel.add_theme_stylebox_override("panel", style)
	hud.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	panel.add_child(stack)
	stage_label = Label.new()
	stage_label.add_theme_font_size_override("font_size", 22)
	stage_label.modulate = Color("f1e5c7")
	stack.add_child(stage_label)
	var objective := Label.new()
	objective.text = "Desça pelo mercado e descubra o pontão."
	objective.add_theme_font_size_override("font_size", 17)
	stack.add_child(objective)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	stack.add_child(buttons)
	buttons.add_child(button("Percorrer a Ribeira", start_tour))
	pixel_button = button("Pixels: 2×", toggle_pixels)
	buttons.add_child(pixel_button)
	scale_button = button("Perspectiva", toggle_projection)
	buttons.add_child(scale_button)
	status_label = Label.new()
	status_label.text = "Praça → mercado → cais"
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.modulate = Color("b9c9b0")
	stack.add_child(status_label)
	hint_label = Label.new()
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint_label.offset_top = -55
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 18)
	hint_label.add_theme_color_override("font_shadow_color", Color("14231e"))
	hint_label.add_theme_constant_override("shadow_offset_y", 2)
	hud.add_child(hint_label)
	dialog = PanelContainer.new()
	dialog.position = Vector2(26, 235)
	dialog.add_theme_stylebox_override("panel", style)
	var dialog_stack := VBoxContainer.new()
	dialog_stack.add_theme_constant_override("separation", 12)
	dialog.add_child(dialog_stack)
	var words := Label.new()
	words.text = "Comerciante\n\nA água está calma. O pontão fica a nascente,\nseguindo a margem do rio."
	words.add_theme_font_size_override("font_size", 19)
	dialog_stack.add_child(words)
	dialog_stack.add_child(button("Continuar", func(): dialog.hide()))
	hud.add_child(dialog)
	dialog.hide()

func toggle_pixels() -> void:
	var size: float = pixel_material.get_shader_parameter("pixel_size")
	size = 1.0 if size > 1.0 else 2.0
	pixel_material.set_shader_parameter("pixel_size", size)
	pixel_button.text = "Pixels: %d×" % int(size)

func toggle_projection() -> void:
	if camera.projection == Camera3D.PROJECTION_PERSPECTIVE:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 22
		scale_button.text = "Ortográfica"
	else:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		scale_button.text = "Perspectiva"

func start_tour() -> void:
	dialog.hide()
	player.position = route[0] + Vector3(0, 0.05, 0)
	player.velocity = Vector3.ZERO
	walking_path.assign(route.slice(1))
	visited.assign([0])
	tour_active = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_E: interact()
			KEY_R: start_tour()
			KEY_P: toggle_projection()
			KEY_F: toggle_pixels()
			KEY_ESCAPE: dialog.hide()
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A: interact()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var origin := camera.project_ray_origin(event.position)
		var target := origin + camera.project_ray_normal(event.position) * 200
		var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin, target))
		if not hit.is_empty() and hit.position.y < 0.4:
			walking_path.assign([Vector3(hit.position.x, player.position.y, hit.position.z)])
			tour_active = false

func interact() -> void:
	if player.position.distance_to(merchant.position) < 3.5:
		dialog.visible = not dialog.visible
		walking_path.clear()
		tour_active = false

func _set_frame(index: int) -> void:
	if index == last_frame: return
	last_frame = index
	var bounds: Array = frame_data[index]
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = Rect2(bounds[0], bounds[1], bounds[2], bounds[3])
	actor.texture = texture
	actor.pixel_size = 1.75 / float(bounds[3])
	actor.offset.y = float(bounds[3]) * 0.5

func _physics_process(delta: float) -> void:
	if not ready_for_test: return
	var input := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if not Input.get_connected_joypads().is_empty():
		var joy := Vector2(Input.get_joy_axis(Input.get_connected_joypads()[0], JOY_AXIS_LEFT_X), Input.get_joy_axis(Input.get_connected_joypads()[0], JOY_AXIS_LEFT_Y))
		if joy.length() > 0.2: input = joy
	var motion := Vector3.ZERO
	if input.length() > 0.05:
		walking_path.clear()
		tour_active = false
		var right := camera.global_basis.x
		var down := camera.global_basis.z
		right.y = 0
		down.y = 0
		motion = (right.normalized() * input.x + down.normalized() * input.y).normalized()
	elif not walking_path.is_empty():
		var difference := walking_path[0] - player.position
		difference.y = 0
		if difference.length() < 0.22:
			walking_path.pop_front()
		else: motion = difference.normalized()
	if dialog.visible: motion = Vector3.ZERO
	player.velocity.x = motion.x * SPEED
	player.velocity.z = motion.z * SPEED
	player.velocity.y -= 24 * delta
	player.move_and_slide()
	if player.position.y < -3:
		player.position = route[last_checkpoint] + Vector3(0, 0.1, 0)
		player.velocity = Vector3.ZERO
		walking_path.clear()
		tour_active = false
	for index in route.size():
		if player.position.distance_to(route[index]) < 0.6:
			last_checkpoint = index
			if index not in visited: visited.append(index)
	if tour_active and walking_path.is_empty():
		tour_active = false
		status_label.text = "Chegou ao pontão · explore livremente"
	if motion.length() > 0.05:
		frame_time += delta
		var screen_direction := Vector2(motion.dot(camera.global_basis.x), motion.dot(camera.global_basis.z))
		facing = (3 if screen_direction.x > 0 else 1) if absf(screen_direction.x) > absf(screen_direction.y) else (0 if screen_direction.y > 0 else 2)
		_set_frame(facing * 4 + 1 + int(frame_time * 7.0) % 3)
	else:
		frame_time = 0
		_set_frame(facing * 4)
	var desired := player.position + CAMERA_OFFSET
	camera.position = camera.position.lerp(desired, 1.0 - exp(-5.0 * delta))
	camera.look_at(player.position + Vector3(0, 1.0, 0))
	_update_occlusion()
	var stage := "Praça" if player.position.z < 19 else ("Mercado" if player.position.x < 14 else "Cais")
	stage_label.text = "Lisboa · " + stage
	hint_label.text = "E / A · conversar com o comerciante" if player.position.distance_to(merchant.position) < 3.5 else "WASD / setas / controle · mover    Clique · caminhar    R · percurso    P · câmera    F · pixels"
	if tour_active: status_label.text = "A percorrer a Ribeira · mover cancela o percurso"
