@tool
extends RefCounted
## Shared rendering data; narrative identity and behavior remain in chapter scripts.
static var entries: Dictionary = {}
static var textures: Dictionary = {}
const FRAMES := "res://assets/art/npcs/lisbon/frames.json"

static func data() -> Dictionary:
	if entries.is_empty() and FileAccess.file_exists(FRAMES):
		entries = JSON.parse_string(FileAccess.get_file_as_string(FRAMES)).entries
		var child_path := "res://assets/art/portugal-v2/hero-child-frames.json"
		if FileAccess.file_exists(child_path):
			entries.hero_child = JSON.parse_string(FileAccess.get_file_as_string(child_path))
		var poses_path := "res://assets/art/portugal-v2/hero-story-poses-frames.json"
		if FileAccess.file_exists(poses_path):
			entries.hero_story = JSON.parse_string(FileAccess.get_file_as_string(poses_path))
	return entries

static func resolve(id: String) -> String:
	return {"tome":"tome_adult","leonor":"leonor_child","child":"hero_child"}.get(id,id)

static func draw_actor(canvas: Node2D,id: String,facing: int,walking: bool,time: float,posture: String,scale_multiplier: float = 1.0,origin: Vector2 = Vector2.ZERO,eye_glow: bool = false) -> bool:
	id = resolve(id)
	if not data().has(id): return false
	var entry: Dictionary = data()[id]
	if not textures.has(id):
		if ResourceLoader.exists(entry.source): textures[id] = load(entry.source)
		elif FileAccess.file_exists(entry.source): textures[id] = ImageTexture.create_from_image(Image.load_from_file(entry.source))
		else: return false
	var index := clampi(facing,0,3)*4+(1+int(time)%3 if walking else 0)
	var use_pose: bool = posture!="standing" and entry.has("pose_indices")
	if use_pose:
		index = entry.pose_indices.get(posture,0)
		if facing in [1,3]: index = entry.pose_indices.get(posture+"_west",index)
	var rect: Array = entry.frames[index]; var pivot: Array = entry.pivots[index]
	var factor: float = entry.height/float(entry.reference_height)*scale_multiplier
	var flip: bool = (facing==1 and entry.west_flip) if not use_pose else facing==3
	if not use_pose and facing==3 and entry.get("east_flip",false): flip = true
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	canvas.draw_set_transform(origin,0,Vector2(-1 if flip else 1,1))
	canvas.draw_texture_rect_region(textures[id],Rect2(Vector2(-pivot[0],-pivot[1])*factor,Vector2(rect[2],rect[3])*factor),Rect2(rect[0],rect[1],rect[2],rect[3]))
	if id in ["hero_child","hero_story"]:
		preload("res://scripts/chapter/hero_eyes.gd").draw(canvas,"child" if id=="hero_child" else "story",index,rect,pivot,factor,eye_glow)
	canvas.draw_set_transform(Vector2.ZERO)
	return true
