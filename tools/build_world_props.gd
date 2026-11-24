extends SceneTree
## Cuts isometric story objects out of existing painted sheets (no new art):
## a rope coil from the quay props sheet and a flour sack from the buildings sheet.
## Masks are feathered polygons so neighbouring paint (net, wall) is excluded.
## Usage: Godot --headless --path . --script res://tools/build_world_props.gd
const OUT := "res://assets/art/props/"
const CUTS := {
	"coil": {"source":"res://assets/art/portugal-v2/quay-props-clean-v2.png", "rect":Rect2i(505,770,190,128),
		"ellipse":[Vector2(597,834),Vector2(87,56)]},
	"crates": {"source":"res://assets/art/portugal-v2/quay-props-clean-v2.png", "rect":Rect2i(862,545,606,414)},
	"sack": {"source":"res://assets/art/living-quay/buildings-v1.png", "rect":Rect2i(998,438,48,78),
		"polygon":[Vector2(1006,446),Vector2(1020,441),Vector2(1034,444),Vector2(1043,472),Vector2(1040,506),Vector2(1022,513),Vector2(1003,508),Vector2(1001,472)]},
}

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for id in CUTS:
		var cut: Dictionary = CUTS[id]
		var source := Image.load_from_file(ProjectSettings.globalize_path(cut.source))
		source.convert(Image.FORMAT_RGBA8)
		var rect: Rect2i = cut.rect
		var result := Image.create(rect.size.x,rect.size.y,false,Image.FORMAT_RGBA8)
		for y in rect.size.y:
			for x in rect.size.x:
				var at := Vector2(rect.position.x+x+0.5,rect.position.y+y+0.5)
				var inside := _coverage(cut,at)
				if inside <= 0.0: continue
				var color := source.get_pixelv(Vector2i(at))
				color.a *= inside
				result.set_pixel(x,y,color)
		result.save_png(ProjectSettings.globalize_path(OUT+id+".png"))
		print("PROP ",id," ",rect.size)
	quit()

## 1 inside, fading to 0 over ~2 px at the edge.
func _coverage(cut: Dictionary,at: Vector2) -> float:
	if not cut.has("ellipse") and not cut.has("polygon"): return 1.0 # the sheet's own alpha
	if cut.has("ellipse"):
		var c: Vector2 = cut.ellipse[0]; var r: Vector2 = cut.ellipse[1]
		var d := ((at-c)/r).length()
		return clampf((1.0-d)*r.y/2.0,0.0,1.0)
	var polygon := PackedVector2Array(cut.polygon)
	var distance := INF
	for i in polygon.size():
		var p := Geometry2D.get_closest_point_to_segment(at,polygon[i],polygon[(i+1)%polygon.size()])
		distance = minf(distance,at.distance_to(p))
	var sign := 1.0 if Geometry2D.is_point_in_polygon(at,polygon) else -1.0
	return clampf(0.5+sign*distance/2.0,0.0,1.0)
