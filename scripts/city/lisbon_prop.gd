extends Node2D
## Alpha-aware occlusion follows the real artwork, with a gradual transition.
var texture: Texture2D
var size := Vector2.ZERO
var tint := Color.WHITE
var fade := true
var rect := Rect2()
var pixels: Image
var world
var occlusion_alpha := 1.0
func _ready() -> void:
	rect = Rect2(Vector2(-size.x/2,-size.y),size)
	pixels = texture.atlas.get_image() if texture is AtlasTexture else texture.get_image()
func covers(point: Vector2) -> bool:
	if rect.size.x<=0 or rect.size.y<=0: return false
	var local := to_local(point)+Vector2(0,-45)
	if local.y>=-10 or not rect.has_point(local): return false
	var uv := (local-rect.position)/rect.size
	var region: Rect2 = texture.region if texture is AtlasTexture else Rect2(Vector2.ZERO,texture.get_size())
	var at := Vector2i(region.position+uv*region.size)
	at.x=clampi(at.x,0,pixels.get_width()-1);at.y=clampi(at.y,0,pixels.get_height()-1)
	return pixels.get_pixelv(at).a>.3
func _process(delta: float) -> void:
	var target := .38 if fade and is_instance_valid(world) and is_instance_valid(world.player) and covers(world.player.global_position) else 1.0
	if fade and is_instance_valid(world) and is_instance_valid(world.player) and not world.player.enabled:
		for person in world.get_meta("intimate_scene_people",[]):
			if is_instance_valid(person) and person.is_visible_in_tree() and covers(person.global_position):target=0.0;break
	var next := lerpf(occlusion_alpha,target,1-exp(-delta*12))
	if absf(next-occlusion_alpha)>.001:
		occlusion_alpha=next;queue_redraw()
	elif occlusion_alpha!=target:
		occlusion_alpha=target;queue_redraw()
func _draw() -> void:
	var color := tint;color.a*=occlusion_alpha
	draw_texture_rect(texture,rect,false,color)
