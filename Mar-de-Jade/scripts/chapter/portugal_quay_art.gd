extends RefCounted
## Approved reference sample, shared by the composed quay and adult chapter scenes.
const ROOT := "res://reference-study/heros-adventure/"
static var manifest: Dictionary = {}
static var ground_manifest: Dictionary = {}
static var textures: Dictionary = {}

static func record(name: String, width: int = 0) -> Dictionary:
	if manifest.is_empty(): manifest = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"manifest.json"))
	for item in manifest.sprites:
		if item.name==name and (width==0 or item.width==width): return item
	if ground_manifest.is_empty(): ground_manifest = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"ground-review/manifest.json"))
	for item in ground_manifest.sprites:
		if item.name==name and (width==0 or item.width==width):
			var result: Dictionary = item.duplicate(); result.path = "ground-review/"+item.path; return result
	return {}

static func texture(name: String,width: int = 0) -> Texture2D:
	var item := record(name,width)
	if not textures.has(item.path): textures[item.path] = ImageTexture.create_from_image(Image.load_from_file(ROOT+item.path))
	return textures[item.path]

static func sprite(name: String,width: int = 0,scale_factor: float = 2.0) -> Sprite2D:
	var item := record(name,width)
	var visual := Sprite2D.new(); visual.texture = texture(name,width); visual.centered = false
	visual.scale = Vector2.ONE*scale_factor; visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.position = Vector2(-item.pivot.x*item.width,-(1.0-item.pivot.y)*item.height)*scale_factor
	return visual

static func apply(world: Node2D) -> void:
	if world.has_meta("portugal_quay_art") or world.has_meta("living_quay"): return
	world.set_meta("portugal_quay_art",true)
	var terrain: TileMapLayer = world.terrain
	var original_set := terrain.tile_set
	var original_cells := {}
	for cell in terrain.get_used_cells(): original_cells[cell] = terrain.get_cell_atlas_coords(cell)
	var tiles := TileSet.new(); tiles.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tiles.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN; tiles.tile_size = Vector2i(128,64)
	for name in ["dizhuan22.1_zmf_C_0","dizhuan34.1_mjp_C_0","dizhuan22.2_zmf_C_0"]:
		var image := texture(name).get_image(); image.resize(image.get_width()*2,image.get_height()*2,Image.INTERPOLATE_NEAREST)
		var source := TileSetAtlasSource.new(); source.texture = ImageTexture.create_from_image(image)
		source.texture_region_size = image.get_size(); source.create_tile(Vector2i.ZERO); tiles.add_source(source)
	# The pier retains its existing authored wood until its reference modules are assembled.
	tiles.add_source(original_set.get_source(0).duplicate(),10)
	terrain.tile_set = tiles; terrain.material = null; terrain.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for cell in original_cells:
		if original_cells[cell]==Vector2i(1,0): terrain.set_cell(cell,10,Vector2i(1,0))
		else:
			var floor_source := 1 if cell.x>=10 or cell.y>=9 else (2 if posmod(cell.x*31+cell.y*53,7)==0 else 0)
			terrain.set_cell(cell,floor_source,Vector2i.ZERO)
	world._refresh_ground()
	for prop in world.sorted_world.get_children():
		if not str(prop.name).begins_with("crates_"): continue
		var old_visual: Node = prop.get_node_or_null("Visual_01")
		if old_visual != null: old_visual.free()
		# Preserve the authored cargo positions and collision footprints.
		var visual := sprite("xiangzi1_C_0",40,2.0/prop.scale.x)
		visual.name = "ReferenceCargo"; prop.add_child(visual)
	var points := [Vector2(420,610),Vector2(-105,640),Vector2(650,780)]
	for i in points.size():
		var coil := Node2D.new(); coil.name = "RopeCoil%d"%i; coil.position = points[i]; coil.z_index = -1
		coil.add_child(sprite("shengsuo1_C_0",0,1.5)); world.sorted_world.add_child(coil)
