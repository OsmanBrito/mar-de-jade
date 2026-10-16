extends RefCounted
## A courtyard continues outside the tactical cells; actors, cells and scenery stay separate.
const Board = preload("res://scripts/combat/portugal_board.gd")
var c: Node2D
var paving: CanvasTexture
var bench: Texture2D
var buildings: Texture2D
var details: Texture2D
var rack: Texture2D
var dummy: Texture2D
var dummy_rect := Rect2()
var manifest: Dictionary
func setup(canvas: Node2D) -> void:
	c = canvas
	paving = artwork("res://assets/art/combat/portugal/paving-mar-de-ferro.png") as CanvasTexture
	paving.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	bench = artwork("res://assets/art/combat/portugal/bench-mar-de-ferro.png")
	buildings = artwork("res://assets/art/living-quay/buildings-v1.png")
	details = artwork("res://assets/art/living-quay/street-props-v1.png")
	rack = artwork("res://assets/art/combat/portugal/training-rack-mar-de-ferro.png")
	dummy = artwork("res://assets/art/combat/portugal/training-dummy-v1.png")
	var rect: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/combat/portugal/props.json")).dummy
	dummy_rect = Rect2(rect[0],rect[1],rect[2],rect[3])
	manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/living-quay/frames.json"))
func artwork(path: String) -> Texture2D:
	var source: Texture2D = load(path) if ResourceLoader.exists(path) else ImageTexture.create_from_image(Image.load_from_file(path))
	var image := source.get_image(); image.fix_alpha_edges(); image.generate_mipmaps()
	var filtered := CanvasTexture.new(); filtered.diffuse_texture = ImageTexture.create_from_image(image); filtered.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return filtered
func prop(key: String,index: int,foot: Vector2,width: float,tint: Color = Color.WHITE) -> void:
	var info: Dictionary = manifest[key]; var r: Array = info.frames[index]
	var factor: float = width/float(r[2])
	var atlas: Texture2D = buildings if key=="buildings" else details
	for region in info.strips[index]:
		c.draw_texture_rect_region(atlas,Rect2(foot+Vector2(-width*0.5+region[0]*factor,(-r[3]+region[1])*factor),Vector2(region[2],region[3])*factor),Rect2(r[0]+region[0],r[1]+region[1],region[2],region[3]),tint)
func draw_ground(encounter: String,_time: float,_reduced: bool) -> void:
	var points := PackedVector2Array([Vector2.ZERO,Vector2(960,0),Vector2(960,540),Vector2(0,540)])
	var uv := PackedVector2Array()
	for p in points: uv.append(p/Vector2(210,157.5))
	c.draw_polygon(points,PackedColorArray([Color("c8c7b3")]),uv,paving)
	# Subtle cool shade and a street seam keep the playable stone plane grounded.
	c.draw_polygon(points,PackedColorArray([Color(0.05,0.14,0.13,0.20),Color(0.05,0.14,0.13,0.12),Color(0.05,0.14,0.13,0.03),Color(0.05,0.14,0.13,0.03)]))
	for x in range(-4,16):
		var a := Board.screen(Vector2i(x,-2)); var b := Board.screen(Vector2i(x+1,-2))
		c.draw_line(a,b,Color("9e9c82"),3,true)
		c.draw_line(a+Vector2(0,3),b+Vector2(0,3),Color("d7c7a4"),1,true)
	var duel := encounter=="portugal_duel"
	prop("buildings",3 if duel else 0,Board.screen(Vector2i(7,-3))+Vector2(10,9),222)
	prop("buildings",0 if duel else 2,Board.screen(Vector2i(-3,5))+Vector2(-14,0),205,Color("d4cfba"))
	prop("details",3,Board.screen(Vector2i(1,10))+Vector2(-14,0),129)
	prop("details",3,Board.screen(Vector2i(11,3))+Vector2(12,0),125,Color("b5c3a9"))
	prop("details",1,Board.screen(Vector2i(10,-1)),46)
	prop("details",2,Board.screen(Vector2i(-3,0)),128)
	if not duel: c.draw_texture_rect(rack,Rect2(Vector2(631,73),Vector2(112,55)),false,Color("d4c9aa"))
	# Broad contact shadow follows the complete courtyard bench, not isolated square props.
	for cell in [Vector2i(3,2),Vector2i(3,3),Vector2i(3,4)]:
		c.draw_colored_polygon(Board.polygon(cell,3),Color(0.05,0.08,0.06,0.15))
func draw_obstacle(_encounter: String,cell: Vector2i,_deck: bool = false) -> void:
	# Exact same blocked houses, drawn as grounded seats aligned to the isometric row.
	var foot := Board.screen(cell)
	var size := Vector2(63,42)
	c.draw_texture_rect(bench,Rect2(foot-Vector2(size.x*0.5,size.y-7),size),false,Color("d0c7b0"))
func draw_target(foot: Vector2,reaction: float,time: float) -> void:
	c.draw_set_transform(foot,0,Vector2(1,0.36)); c.draw_circle(Vector2.ZERO,16,Color(0.04,0.07,0.05,0.25)); c.draw_set_transform(Vector2.ZERO)
	var height := 59.0
	var size := dummy_rect.size*(height/dummy_rect.size.y)
	var offset := Vector2(sin(time*36)*reaction*2,0)
	c.draw_texture_rect_region(dummy,Rect2(foot+offset-Vector2(size.x*0.5,height),size),dummy_rect)
