@tool
extends RefCounted
static var entries: Dictionary = {}
static var source: Texture2D
static var cached: Dictionary = {}
static func texture(key: String) -> AtlasTexture:
	if cached.has(key): return cached[key]
	if entries.is_empty(): entries = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/portugal-v2/furniture-frames.json"))
	if source == null:
		var path := "res://assets/art/portugal-v2/furniture-v1.png"
		source = load(path) if ResourceLoader.exists(path) else ImageTexture.create_from_image(Image.load_from_file(path))
	var region: Array = entries[key]
	var atlas := AtlasTexture.new(); atlas.atlas = source
	atlas.region = Rect2(region[0],region[1],region[2],region[3]); atlas.filter_clip = true
	cached[key] = atlas
	return atlas

static func draw(canvas: Node2D,key: String,foot: Vector2,size: Vector2) -> void:
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	canvas.draw_texture_rect(texture(key),Rect2(foot-Vector2(size.x*0.5,size.y),size),false)

static func place(parent: Node2D,key: String,foot: Vector2,size: Vector2) -> Node2D:
	var node := Node2D.new(); node.position = foot; node.name = key.capitalize()
	parent.add_child(node)
	var sprite := Sprite2D.new(); sprite.texture = texture(key)
	sprite.position = -Vector2(0,size.y*0.5)
	sprite.scale = size/sprite.texture.get_size()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	node.add_child(sprite)
	var body := StaticBody2D.new(); body.collision_mask = 0; node.add_child(body)
	var shape := CollisionPolygon2D.new()
	shape.polygon = PackedVector2Array([Vector2(-size.x*0.38,-8),Vector2(0,-size.x*0.25),Vector2(size.x*0.38,-8),Vector2(0,10)])
	body.add_child(shape)
	return node
