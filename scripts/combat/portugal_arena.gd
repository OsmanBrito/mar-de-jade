extends RefCounted
## Dedicated battlefield per location, composed like Mar de Ferro's battlefield_art.
## Repeating materials keep their own texel scale; sprites always scale uniformly.
const Board = preload("res://scripts/combat/portugal_board.gd")
const Maps = preload("res://scripts/combat/battle_maps.gd")
var map_id := "courtyard"
var c: Node2D
var paving: CanvasTexture
var floor_wood: CanvasTexture
var water_material: CanvasTexture
var bench: Texture2D
var buildings: Texture2D
var details: Texture2D
var cargo: Texture2D
var rack: Texture2D
var dummy: Texture2D
var dummy_rect := Rect2()
var manifest: Dictionary
var cargo_rect := Rect2()

func setup(canvas: Node2D) -> void:
	c = canvas
	paving = artwork("res://assets/art/combat/portugal/paving-mar-de-ferro.png",true)
	floor_wood = artwork("res://assets/art/combat/boarding/regional-deck.png",true)
	water_material = artwork("res://assets/art/combat/boarding/regional-water-illustrated-v1.png",true)
	bench = artwork("res://assets/art/combat/portugal/bench-mar-de-ferro.png")
	buildings = artwork("res://assets/art/living-quay/buildings-v1.png")
	details = artwork("res://assets/art/living-quay/street-props-v1.png")
	rack = artwork("res://assets/art/combat/portugal/training-rack-mar-de-ferro.png")
	dummy = artwork("res://assets/art/combat/portugal/training-dummy-v1.png")
	var rect: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/combat/portugal/props.json")).dummy
	dummy_rect = Rect2(rect[0],rect[1],rect[2],rect[3])
	manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/living-quay/frames.json"))
	var quay: Dictionary = preload("res://scripts/chapter/quay_sprite.gd").metadata()
	cargo = artwork(quay.props.path)
	var r: Array = quay.props.frames[3]; cargo_rect = Rect2(r[0],r[1],r[2],r[3])

func artwork(path: String,repeat: bool = false) -> CanvasTexture:
	var source: Texture2D = load(path) if ResourceLoader.exists(path) else ImageTexture.create_from_image(Image.load_from_file(path))
	var image := source.get_image(); image.fix_alpha_edges(); image.generate_mipmaps()
	var filtered := CanvasTexture.new(); filtered.diffuse_texture = ImageTexture.create_from_image(image)
	filtered.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	filtered.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED if repeat else CanvasItem.TEXTURE_REPEAT_DISABLED
	return filtered

static func fitted_size(native: Vector2,bounds: Vector2) -> Vector2:
	return native*minf(bounds.x/native.x,bounds.y/native.y)

func sprite(texture: Texture2D,region: Rect2,foot: Vector2,bounds: Vector2,tint: Color = Color.WHITE) -> void:
	var size := fitted_size(region.size,bounds)
	c.draw_set_transform(foot,0,Vector2(1,0.35)); c.draw_circle(Vector2.ZERO,size.x*0.37,Color(0.04,0.08,0.06,0.18)); c.draw_set_transform(Vector2.ZERO)
	# One complete region, not separately filtered strips with seams between them.
	c.draw_texture_rect_region(texture,Rect2(foot-Vector2(size.x*0.5,size.y),size),region,tint)

func prop(key: String,index: int,foot: Vector2,width: float,tint: Color = Color.WHITE) -> void:
	var r: Array = manifest[key].frames[index]
	var region := Rect2(r[0],r[1],r[2],r[3])
	sprite(buildings if key=="buildings" else details,region,foot,Vector2(width,region.size.y*width/region.size.x),tint)

func project(cell: Vector2) -> Vector2:
	return Board.ORIGIN+Vector2((cell.x-cell.y)*Board.STEP.x,(cell.x+cell.y)*Board.STEP.y)
func quad(a: Vector2,b: Vector2) -> PackedVector2Array:
	return PackedVector2Array([project(a),project(Vector2(b.x,a.y)),project(b),project(Vector2(a.x,b.y))])

func draw_surface(points: PackedVector2Array,texture: Texture2D,tint: Color,period: Vector2,projected: bool = false) -> void:
	var uv := PackedVector2Array()
	for p in points:
		var local := p-Board.ORIGIN
		uv.append(Vector2((local.x/Board.STEP.x+local.y/Board.STEP.y)*0.5,(local.y/Board.STEP.y-local.x/Board.STEP.x)*0.5)/4.0 if projected else p/period)
	c.draw_polygon(points,PackedColorArray([tint]),uv,texture)

func draw_ground(_encounter: String,time: float,reduced: bool) -> void:
	var theme := Maps.profile(map_id)
	var tint := Color(theme.tint)
	# Extend the scenery into aspect-ratio margins without stretching the UI or art.
	var inverse := c.get_viewport().canvas_transform.affine_inverse()
	var viewport_size: Vector2 = c.get_viewport_rect().size
	var screen := PackedVector2Array([inverse*Vector2.ZERO,inverse*Vector2(viewport_size.x,0),inverse*viewport_size,inverse*Vector2(0,viewport_size.y)])
	if theme.shore:
		var uv := PackedVector2Array()
		for p in screen: uv.append(p/Vector2(240,180)+Vector2(0 if reduced else time*0.008,0))
		c.draw_polygon(screen,PackedColorArray([Color("89a7a1")]),uv,water_material)
	var land := quad(Vector2(-28,-28),Vector2(10.4,28)) if theme.shore else screen
	# Fixed-size repetitions, never a whole painting stretched to the window.
	if theme.floor=="forest":
		draw_surface(land,preload("res://scripts/city/lisbon_scenery.gd").texture("bruma-grass-refined.png",false),tint,Vector2(220,165))
	else:
		draw_surface(land,floor_wood if theme.floor=="wood" else paving,tint,Vector2(180,135) if theme.floor=="wood" else Vector2(210,157.5),theme.floor=="wood")
	if theme.shore:
		var a := project(Vector2(10.4,-28)); var b := project(Vector2(10.4,28))
		c.draw_line(a+Vector2(0,9),b+Vector2(0,9),Color("405b54"),12,true)
		c.draw_line(a,b,Color("b1aa8b"),6,true)
		c.draw_line(a-Vector2(0,3),b-Vector2(0,3),Color("e0d0aa"),1.5,true)
	# Scenery is placed outside the complete 9x8 playable footprint.
	for i in theme.buildings.size():
		prop("buildings",theme.buildings[i],project(Vector2(2,-4) if i==0 else Vector2(-4,3)),255 if i==0 else 220,Color("ddd8c8"))
	if theme.dressing in ["garden","square"]:
		prop("details",3,project(Vector2(-1,8.7)),99)
		prop("details",3,project(Vector2(10,2.5)),91)
		prop("details",1,project(Vector2(8,-2)),50)
	if theme.dressing=="forest":
		var tree = preload("res://scripts/city/lisbon_scenery.gd").texture("bruma-v2-tree.png")
		for at in [Vector2(-2,2),Vector2(3,-3),Vector2(10,5),Vector2(2,10)]:
			var foot := project(at); var size := tree.get_size()*150/tree.get_width()
			c.draw_texture_rect(tree,Rect2(foot-Vector2(size.x*.5,size.y),size),false,Color("c5cdb4"))
	if theme.dressing=="cargo":
		sprite(cargo,cargo_rect,project(Vector2(8,-2)),Vector2(92,75))
		prop("details",2,project(Vector2(-2,7)),115)
	if theme.training:
		sprite(rack,Rect2(Vector2.ZERO,rack.get_size()),project(Vector2(6,-1.7)),Vector2(115,80))
	if theme.dressing=="interior":
		# Reuse the finished shelter walls, including windows, stone plinth and wear.
		var corner := project(Vector2(-1,-1)); var left := project(Vector2(-1,9)); var right := project(Vector2(10,-1))
		preload("res://scripts/chapter/shelter_details.gd").draw_wall_span(c,corner,left,right,130)
		var furniture = preload("res://scripts/chapter/furniture_art.gd")
		for spec in [["cupboard",Vector2(0,-1.1),Vector2(68,85)],["shelf",Vector2(8,-1.1),Vector2(80,75)]]:
			var texture: Texture2D = furniture.texture(spec[0])
			furniture.draw(c,spec[0],project(spec[1]),fitted_size(texture.get_size(),spec[2]))
	if theme.dressing=="deck":
		for y in range(-2,12,2):
			var foot := project(Vector2(10.1,y))
			c.draw_line(foot,foot-Vector2(0,22),Color("65503b"),4,true)
			c.draw_line(foot-Vector2(0,19),project(Vector2(10.1,y+2))-Vector2(0,19),Color("b39465"),2,true)
	# Quiet peripheral shade; there is no raised board or per-cell floor image.
	var border := quad(Vector2(-0.5,-0.5),Vector2(8.5,7.5))
	var outside := quad(Vector2(-22,-22),Vector2(30,30))
	for i in 4:
		var next := (i+1)%4
		c.draw_polygon(PackedVector2Array([border[i],border[next],outside[next],outside[i]]),PackedColorArray([Color(0.03,0.08,0.07,0.02),Color(0.03,0.08,0.07,0.02),Color(0.03,0.08,0.07,0.47),Color(0.03,0.08,0.07,0.47)]))
	var edge := border.duplicate(); edge.append(edge[0])
	c.draw_polyline(edge,Color(0.87,0.83,0.66,0.23),0.8,true)

func draw_obstacle(_encounter: String,cell: Vector2i,_deck: bool = false) -> void:
	var foot := Board.screen(cell)+Vector2(0,7)
	if Maps.profile(map_id).obstacle=="cargo": sprite(cargo,cargo_rect,foot,Vector2(52,48))
	else: sprite(bench,Rect2(Vector2.ZERO,bench.get_size()),foot,Vector2(63,42),Color("d0c7b0"))

func draw_target(foot: Vector2,reaction: float,time: float) -> void:
	sprite(dummy,dummy_rect,foot+Vector2(sin(time*36)*reaction*2,0),Vector2(60,59))
