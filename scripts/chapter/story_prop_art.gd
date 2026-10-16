@tool
extends RefCounted
## The inventory and the world share the same recognizable story objects.
static var textures: Dictionary = {}
static func draw_item(canvas: Node2D,id: String,foot: Vector2,width: float) -> void:
	if not textures.has(id):
		textures[id] = load("res://assets/art/items/portugal/"+id+".png")
	var texture: Texture2D = textures[id]
	var size := texture.get_size()*width/texture.get_width()
	canvas.draw_texture_rect(texture,Rect2(foot-Vector2(size.x*0.5,size.y),size),false)
