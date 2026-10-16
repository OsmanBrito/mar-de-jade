@tool
extends Node2D
## Source rectangles and pivots preserve the generated originals and stable foot contact.
@export_enum("hero", "duarte") var identity := "hero"
var walking := false
var facing := 0
var frame_time := 0.0
static var manifest: Dictionary = {}
static var textures: Dictionary = {}

static func metadata() -> Dictionary:
	if manifest.is_empty():
		manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/portugal-v2/frames.json"))
	return manifest

static func artwork(key: String) -> Texture2D:
	if not textures.has(key):
		# Source PNG also works on a fresh editable checkout before editor import.
		var path: String = metadata()[key].path
		textures[key] = load(path) if ResourceLoader.exists(path) else ImageTexture.create_from_image(Image.load_from_file(path))
	return textures[key]

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var info: Dictionary = metadata()[identity]
	var index := clampi(facing,0,3)*4+(1+int(frame_time)%3 if walking else 0)
	var r: Array = info.frames[index]
	var pivot: Array = info.pivots[index]
	var factor := 84.0/295.0
	draw_set_transform(Vector2.ZERO,0,Vector2(1,0.38))
	draw_circle(Vector2.ZERO,15,Color(0.04,0.08,0.07,0.28))
	draw_set_transform(Vector2.ZERO)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	draw_texture_rect_region(artwork(identity),Rect2(Vector2(-pivot[0],-pivot[1])*factor,Vector2(r[2],r[3])*factor),Rect2(r[0],r[1],r[2],r[3]))
