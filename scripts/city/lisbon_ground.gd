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

## A Lisbon street, as opposed to a square: darker cobbles (calçada de cubos),
## a central gutter of larger setts and soft shade along both edges. The
## square and doorsteps keep the pale limestone slabs, so the two read apart.
const STREET_COBBLE := Color("a2998a")
static func street(canvas: CanvasItem,path: PackedVector2Array,width: float) -> void:
	for polygon in Geometry2D.offset_polyline(path,width*.5,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND):
		cobbled_surface(canvas,polygon,STREET_COBBLE)
	# Shade where the street meets walls and doorsteps.
	for side in [-1.0,1.0]:
		for band in 3:
			var inset := width*.5-4.0-band*5.0
			canvas.draw_polyline(_offset(path,side*inset),Color(.22,.20,.15,.07),7.0,true)
	gutter(canvas,path)

## Central gutter: a shallow channel of larger, darker setts.
static func gutter(canvas: CanvasItem,path: PackedVector2Array) -> void:
	canvas.draw_polyline(path,Color(.26,.24,.19,.22),16.0,true)
	canvas.draw_polyline(path,Color(.20,.19,.15,.20),7.0,true)
	var travelled := 0.0
	for i in path.size()-1:
		var a := path[i]; var b := path[i+1]
		var length := a.distance_to(b); var along := (b-a)/maxf(length,.001)
		var across := along.orthogonal()
		var d := fposmod(-travelled,15.0)
		while d < length:
			var at := a+along*d
			for k in [-1.0,1.0]:
				var stone: Vector2 = at+across*k*4.2
				var s := 3.0+fposmod(stone.x*.37+stone.y*.11,1.2)
				canvas.draw_set_transform(stone,along.angle(),Vector2(1.25,.7))
				canvas.draw_circle(Vector2.ZERO,s,Color(.35,.32,.26,.55))
				canvas.draw_circle(Vector2(-.6,-.8),s*.5,Color(.55,.51,.43,.35))
			d += 15.0
		travelled += length
	canvas.draw_set_transform(Vector2.ZERO)

static func _offset(path: PackedVector2Array,distance: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in path.size():
		var tangent := (path[mini(i+1,path.size()-1)]-path[maxi(i-1,0)]).normalized()
		result.append(path[i]+tangent.orthogonal()*distance)
	return result

## Pale limestone threshold in front of a door: private ground meeting the street.
static func doorstep(canvas: CanvasItem,foot: Vector2,width: float) -> void:
	var outline := PackedVector2Array([foot+Vector2(-width*.5,-2),foot+Vector2(width*.5,-2),foot+Vector2(width*.5-6,24),foot+Vector2(-width*.5+6,24)])
	paving(canvas,outline,Color("d6cfbd"),Materials.texture("limestone-floor"),70)
	canvas.draw_line(outline[3],outline[2],Color(.25,.22,.17,.30),3,true)
	canvas.draw_line(outline[3]+Vector2(0,-1.5),outline[2]+Vector2(0,-1.5),Color(1,.97,.88,.35),1,true)
