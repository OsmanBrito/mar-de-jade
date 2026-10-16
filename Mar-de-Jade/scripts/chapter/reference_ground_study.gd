extends "res://scripts/chapter/quay_art_study.gd"
## Same exploration controller, with sampled terrain/props from the installed reference.
const SAMPLE_ROOT := "res://reference-study/heros-adventure/"
var reference_manifest: Dictionary = {}
var reference_textures: Dictionary = {}
var ground_sources: Array[String] = ["dizhuan1.1_tj_C_0","dizhuan1.3_tj_C_0","tudi1_C_0","caodi1_C_0"]
var selected_ground := 0
var ground_names := ["Pedra lisa","Lajes","Terra","Relva"]
var ground_label: Label
var reference_tiles: TileSet

func _ready() -> void:
	reference_manifest = JSON.parse_string(FileAccess.get_file_as_string(SAMPLE_ROOT+"manifest.json"))
	super._ready()

func source_record(source_name: String) -> Dictionary:
	var chosen := {}
	for record in reference_manifest.sprites:
		if source_name=="xiangzi1_C_0" and record.name==source_name and record.width==40: return record
		if record.name == source_name and (chosen.is_empty() or record.width>chosen.width): chosen = record
	return chosen

func source_texture(source_name: String) -> Texture2D:
	if not reference_textures.has(source_name):
		var record := source_record(source_name)
		reference_textures[source_name] = ImageTexture.create_from_image(Image.load_from_file(SAMPLE_ROOT+record.path))
	return reference_textures[source_name]

func _ground_variation() -> void:
	var tiles := TileSet.new(); tiles.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tiles.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN; tiles.tile_size = Vector2i(128,64)
	var all_sources: Array[String] = ground_sources.duplicate(); all_sources.append("dizhuan1.2_tj_C_0"); all_sources.append("dizhuan1.4_tj_C_0")
	for name in all_sources:
		var image := source_texture(name).get_image()
		image.resize(image.get_width()*2,image.get_height()*2,Image.INTERPOLATE_NEAREST)
		var atlas := TileSetAtlasSource.new(); atlas.texture = ImageTexture.create_from_image(image)
		atlas.texture_region_size = image.get_size(); atlas.create_tile(Vector2i.ZERO)
		tiles.add_source(atlas)
	reference_tiles = tiles
	world.terrain.tile_set = reference_tiles
	apply_ground(0)
	# Reference props belong to this study, with individual sorting and footprints.
	for child in world.sorted_world.get_children():
		if str(child.name).begins_with("crates_"):
			child.free()

func apply_ground(index: int) -> void:
	selected_ground = index
	world.terrain.tile_set = reference_tiles
	for cell in world.terrain.get_used_cells():
		var source := index
		if index==0: source = [0,4,0,5][posmod(cell.x*7+cell.y*11,4)]
		world.terrain.set_cell(cell,source,Vector2i.ZERO)
	world.terrain.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world.terrain.material = null
	world._refresh_ground()
	if ground_label != null: ground_label.text = "1–4 · piso: "+ground_names[index]+"  |  5 · comparar piso anterior"

func _add_prop(label: String,index: int,point: Vector2,_width: float,radius: Vector2) -> void:
	var names := ["shitou1_C_0","xiangzi1_C_0","shengsuo2_C_0","xiangzi1_C_0"]
	var source_name: String = names[index]
	var record := source_record(source_name)
	var prop := Node2D.new(); prop.name = label; prop.position = point
	var sprite := Sprite2D.new(); sprite.texture = source_texture(source_name)
	sprite.centered = false; sprite.scale = Vector2.ONE*2
	# Unity pivot is measured from bottom-left; Godot images from top-left.
	sprite.position = Vector2(-record.pivot.x*record.width,-(1.0-record.pivot.y)*record.height)*2
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; prop.add_child(sprite)
	world.sorted_world.add_child(prop)
	if index==2: return # Rope lies on the floor and can be walked over.
	var body := StaticBody2D.new(); body.collision_mask = 0; prop.add_child(body)
	var shape := CollisionPolygon2D.new()
	var footprint := Vector2(minf(radius.x,record.width*0.65),minf(radius.y,record.height*0.35))
	shape.polygon = PackedVector2Array([Vector2(-footprint.x,0),Vector2(0,-footprint.y),Vector2(footprint.x,0),Vector2(0,footprint.y)])
	body.add_child(shape)

func _interface() -> void:
	super._interface()
	var canvas := CanvasLayer.new(); add_child(canvas)
	ground_label = Label.new(); ground_label.position = Vector2(24,100)
	ground_label.add_theme_font_size_override("font_size",18)
	ground_label.add_theme_color_override("font_shadow_color",Color.BLACK); ground_label.add_theme_constant_override("shadow_offset_x",2); ground_label.add_theme_constant_override("shadow_offset_y",2)
	canvas.add_child(ground_label)
	var label := Label.new(); label.text = "HERO’S ADVENTURE · amostra extraída"; label.position = Vector2(24,128); label.add_theme_color_override("font_color",Color("e8d7b5")); canvas.add_child(label)
	ground_label.text = "1–4 · piso: "+ground_names[0]+"  |  5 · comparar piso anterior"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode>=KEY_1 and event.keycode<=KEY_4:
			apply_ground(event.keycode-KEY_1); return
		if event.keycode==KEY_5:
			world.terrain.tile_set = preload("res://data/terrain/ground.tres")
			for cell in world.terrain.get_used_cells(): world.terrain.set_cell(cell,0,Vector2i.ZERO)
			ground_label.text = "Comparação · piso anterior gerado"; return
	super._unhandled_input(event)
