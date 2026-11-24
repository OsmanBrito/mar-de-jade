@tool
extends RefCounted
## The inventory and the world share the same recognizable story objects.
## In the world they are drawn as isometric painted objects resting on the ground,
## with the same contact and cast shadows as the characters.
static var textures: Dictionary = {}
const Shadows = preload("res://scripts/chapter/contact_shadow.gd")
## Painted isometric stand-ins for inventory icons (tools/build_world_props.gd).
const WORLD := {
	"PT-T01":"res://assets/art/props/coil.png",
	"flour":"res://assets/art/props/sack.png",
	"crates":"res://assets/art/props/crates.png",
}

static func _texture(id: String) -> Texture2D:
	if not textures.has(id):
		var path: String = WORLD.get(id,"res://assets/art/items/portugal/"+id+".png")
		textures[id] = load(path) if ResourceLoader.exists(path) else ImageTexture.create_from_image(Image.load_from_file(path))
	return textures[id]

## Inventory icon at a point (held objects, menus).
static func draw_item(canvas: Node2D,id: String,foot: Vector2,width: float) -> void:
	var texture := _texture(id)
	var size := texture.get_size()*width/texture.get_width()
	canvas.draw_texture_rect(texture,Rect2(foot-Vector2(size.x*0.5,size.y),size),false)

## Object resting on the ground: contact shadow, silhouette cast shadow, then the art.
static func draw_world(canvas: Node2D,id: String,foot: Vector2,width: float,tint: Color = Color.WHITE,cast: bool = true) -> void:
	var texture := _texture(id)
	var size := texture.get_size()*width/texture.get_width()
	# Painted objects sit a few pixels into their own base; icons have empty margins.
	var sink := size.y*(0.06 if WORLD.has(id) else 0.0)
	var rect := Rect2(foot-Vector2(size.x*0.5,size.y-sink),size)
	Shadows.draw_contact(canvas,foot+Vector2(0,-1),Vector2(size.x*0.55,size.x*0.18))
	if cast:
		canvas.draw_set_transform_matrix(Shadows.cast_transform(foot,false,0.8))
		canvas.draw_texture_rect(texture,Rect2(rect.position-foot,rect.size),false,Shadows.SHADOW_COLOR)
		canvas.draw_set_transform(Vector2.ZERO)
	canvas.draw_texture_rect(texture,rect,false,tint)
