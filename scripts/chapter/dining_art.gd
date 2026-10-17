@tool
extends RefCounted
## A single transparent atlas supplies seats and crockery in every story scene.
static var frames: Dictionary = {}
static var source: Texture2D
static var cache: Dictionary = {}

static func texture(id: String) -> AtlasTexture:
	if cache.has(id): return cache[id]
	if frames.is_empty(): frames = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/portugal-v2/dining-frames.json"))
	if source == null:
		var path := "res://assets/art/portugal-v2/dining-v1.png"
		source = load(path) if ResourceLoader.exists(path) else ImageTexture.create_from_image(Image.load_from_file(path))
	var region: Array = frames[id]
	var atlas := AtlasTexture.new(); atlas.atlas = source
	atlas.region = Rect2(region[0],region[1],region[2],region[3]); atlas.filter_clip = true
	cache[id] = atlas
	return atlas

static func draw(canvas: Node2D,id: String,foot: Vector2,width: float,extra_height: float = 0.0) -> void:
	var art := texture(id)
	var size := Vector2(width,width*art.get_height()/art.get_width()+extra_height)
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	canvas.draw_texture_rect(art,Rect2(foot-Vector2(size.x*0.5,size.y),size),false)
