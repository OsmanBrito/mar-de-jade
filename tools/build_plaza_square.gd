extends SceneTree
## One-off authoring step: writes the square's buildings and planters into
## scenes/maps/praca_infancia.tscn so they can be edited in the Godot 2D view.
## Re-running replaces "PracaDeLisboa" and the planters with this layout.
## Usage: Godot --headless --path . --script res://tools/build_plaza_square.gd
const MAP := "res://scenes/maps/praca_infancia.tscn"
const FACADE := preload("res://scripts/chapter/square_facade.gd")
const PLANTER := preload("res://scenes/props/planter.tscn")
# Front ground corner in frame pixels and façade widths (frame pixels).
const FRAMES := {
	0: {"corner":Vector2(282,522), "left":215.0, "right":215.0}, # house with balcony
	1: {"corner":Vector2(390,505), "left":290.0, "right":410.0}, # warehouse
	2: {"corner":Vector2(232,432), "left":175.0, "right":460.0}, # workshop
	3: {"corner":Vector2(338,585), "left":310.0, "right":165.0}, # house with awning
}
# [name, frame, edge, corner x, scale, flip, recess behind the edge]
const LAYOUT := [
	["RuaNorte",0,"ne",-30.0,0.6,true,170.0],
	["Oficina",2,"nw",-640.0,0.52,false,0.0],
	["Abrigo",0,"nw",-436.0,0.66,false,76.0],
	["CasaDoCanto",3,"nw",-280.0,0.6,true,0.0],
	["Armazem",1,"ne",178.0,0.55,false,0.0],
	["CasaDaPraca",3,"ne",380.0,0.6,false,0.0],
]
const PLANTERS := [["CanteiroOeste",Vector2(-435,340)],["CanteiroLeste",Vector2(435,340)]]

func _initialize() -> void:
	var root: Node = load(MAP).instantiate()
	for old in ["PracaDeLisboa"]:
		if root.has_node(old): root.get_node(old).free()
	var sorted: Node = root.get_node("ActorsAndProps")
	for planter in PLANTERS:
		if sorted.has_node(planter[0]): sorted.get_node(planter[0]).free()
	var frames: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/living-quay/frames.json"))
	var sheet: Texture2D = load(frames.buildings.path)
	var dressing := Node2D.new(); dressing.name = "PracaDeLisboa"
	dressing.z_index = 1; dressing.y_sort_enabled = true
	root.add_child(dressing); dressing.owner = root
	root.move_child(dressing,root.get_node("ActorsAndProps").get_index())
	for spec in LAYOUT:
		var r: Array = frames.buildings.frames[spec[1]]
		var info: Dictionary = FRAMES[spec[1]]
		var factor: float = spec[4]; var flip: bool = spec[5]
		var corner: Vector2 = info.corner
		if flip: corner.x = r[2]-corner.x
		var x: float = spec[3]
		var y: float = (-32.0-x*0.5) if spec[2]=="nw" else (-32.0+x*0.5)
		var facade := Node2D.new(); facade.set_script(FACADE); facade.name = spec[0]
		facade.position = Vector2(x,y-10.0-spec[6])
		facade.edge = spec[2]
		var right_side: float = info.left if flip else info.right
		var left_side: float = info.right if flip else info.left
		facade.along = (right_side if spec[2]=="nw" else left_side)*factor
		facade.depth = (left_side if spec[2]=="nw" else right_side)*factor
		dressing.add_child(facade); facade.owner = root
		var sprite := Sprite2D.new(); sprite.name = "Pintura"
		var atlas := AtlasTexture.new(); atlas.atlas = sheet
		atlas.region = Rect2(r[0],r[1],r[2],r[3])
		sprite.texture = atlas; sprite.centered = false; sprite.flip_h = flip
		sprite.scale = Vector2.ONE*factor
		sprite.position = -corner*factor
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		facade.add_child(sprite); sprite.owner = root
	for planter in PLANTERS:
		var node: Node2D = PLANTER.instantiate(); node.name = planter[0]
		node.position = planter[1]; node.object_id = StringName("praca_infancia/"+planter[0].to_lower())
		sorted.add_child(node); node.owner = root
	var packed := PackedScene.new()
	var error := packed.pack(root)
	if error == OK: error = ResourceSaver.save(packed,MAP)
	print("PLAZA_SQUARE_BUILT " if error == OK else "PLAZA_SQUARE_FAILED ",error)
	root.free()
	quit()
