extends RefCounted
## Exterior materials share one oblique ground plane and the navigation boundary.
const Layout = preload("res://scripts/city/lisbon_layout.gd")
const Materials = preload("res://scripts/city/place_materials.gd")
const STONE := Color("c3bcaa")
static var cobbles: Texture2D
# One district boundary for every surface, apron and worn strip. It crosses the
# narrow descent, not the middle of the civic square. No overlapping floor paint.
const CIVIC := [Vector2(-3000,-3000),Vector2(4000,-3000),Vector2(4000,504),Vector2(-3000,728)]
const WORKING := [Vector2(-3000,728),Vector2(4000,504),Vector2(4000,3000),Vector2(-3000,3000)]
static func surface(canvas: CanvasItem,outline: PackedVector2Array,tint: Color = STONE) -> void:
	if cobbles==null:
		var image: Image = load("res://assets/art/ferro-lisbon/bruma-paving-refined.png").get_image()
		image.generate_mipmaps()
		var filtered := CanvasTexture.new(); filtered.diffuse_texture = ImageTexture.create_from_image(image)
		filtered.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		filtered.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED; cobbles = filtered
	for polygon in Geometry2D.intersect_polygons(outline,PackedVector2Array(CIVIC)):
		paving(canvas,polygon,tint,Materials.texture("limestone-floor"),118)
	for polygon in Geometry2D.intersect_polygons(outline,PackedVector2Array(WORKING)):
		cobbled_surface(canvas,polygon,tint)
static func cobbled_surface(canvas: CanvasItem,outline: PackedVector2Array,tint: Color) -> void:
	# The source cobbles are not seamless. Reflect adjacent tiles at their shared
	# edge, using the same world-space phase for every street and apron. This
	# removes the dark repeated tile borders without editing or resampling art.
	var projected := PackedVector2Array()
	for p in outline: projected.append(Vector2(.5*p.x+p.y,-.22*p.x+p.y)/96.0)
	var bounds := Rect2(projected[0],Vector2.ZERO)
	for p in projected: bounds = bounds.expand(p)
	for x in range(floori(bounds.position.x),ceili(bounds.end.x)):
		for y in range(floori(bounds.position.y),ceili(bounds.end.y)):
			var tile := PackedVector2Array([Vector2(x,y),Vector2(x+1,y),Vector2(x+1,y+1),Vector2(x,y+1)])
			for section in Geometry2D.intersect_polygons(projected,tile):
				var points := PackedVector2Array(); var uv := PackedVector2Array()
				for p in section:
					# Inverse of the common oblique projection above.
					points.append(Vector2((p.x-p.y)/.72,(.22*p.x+.5*p.y)/.72)*96.0)
					var sample := p-Vector2(x,y)
					if posmod(x,2)==1: sample.x = 1-sample.x
					if posmod(y,2)==1: sample.y = 1-sample.y
					uv.append(sample.clamp(Vector2(.001,.001),Vector2(.999,.999)))
				canvas.draw_polygon(points,PackedColorArray([tint]),uv,cobbles)
static func paving(canvas: CanvasItem,outline: PackedVector2Array,tint: Color,texture: Texture2D,unit: float) -> void:
	var uv := PackedVector2Array()
	# Parallel axes, matching the low front and receding side of the architecture.
	# Small masonry units retain human scale; no screen-aligned brick wallpaper.
	for p in outline: uv.append(Vector2(.5*p.x+p.y,-.22*p.x+p.y)/unit)
	canvas.draw_polygon(outline,PackedColorArray([tint]),uv,texture)
static func inside(at: Vector2,surfaces: Array[PackedVector2Array]) -> bool:
	for polygon in surfaces:
		if Geometry2D.is_point_in_polygon(at,polygon): return true
	return false
static func edging(canvas: CanvasItem,surfaces: Array[PackedVector2Array]) -> void:
	# Interrupt the curb at every street junction. These edges describe the same
	# walkable area as Layout.contains, including the two alternative descents.
	for polygon in surfaces:
		for i in polygon.size():
			var a := polygon[i]; var b := polygon[(i+1)%polygon.size()]
			var count := maxi(1,ceili(a.distance_to(b)/18.0))
			var normal := (b-a).normalized().orthogonal()*7
			for step in count:
				var from := a.lerp(b,float(step)/count); var to := a.lerp(b,float(step+1)/count)
				var middle := (from+to)*.5
				if middle.y>1098: continue # The quay's retaining wall owns the water edge.
				if inside(middle+normal,surfaces) and inside(middle-normal,surfaces): continue
				canvas.draw_line(from+Vector2(2,3),to+Vector2(2,3),Color(.17,.20,.16,.30),9,true)
				canvas.draw_line(from,to,Color("8c8874"),6,true)
				canvas.draw_line(from-Vector2(0,2),to-Vector2(0,2),Color("b1aa92"),2,true)
				canvas.draw_line(from,from+(to-from).normalized()*1.5,Color("777462"),5,true)
