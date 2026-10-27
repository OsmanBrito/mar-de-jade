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
var cutaway: ShaderMaterial
static var cutaway_shader: Shader
func _ready() -> void:
	rect = Rect2(Vector2(-size.x/2,-size.y),size)
	pixels = texture.atlas.get_image() if texture is AtlasTexture else texture.get_image()
	if cutaway_shader==null:
		cutaway_shader = Shader.new()
		cutaway_shader.code = """shader_type canvas_item;
varying vec2 object_point;
uniform vec2 focus_point = vec2(0.0);
uniform float cover_alpha = 1.0;
uniform bool clear_scene = false;
uniform vec2 interest_point = vec2(0.0);
uniform float interest_strength = 0.0;
void vertex() { object_point = VERTEX; }
void fragment() {
    float distance_to_actor = length((object_point-focus_point)*vec2(1.0,0.72));
    float secondary = (1.0-smoothstep(42.0,88.0,length((object_point-interest_point)*vec2(1.0,0.72))))*interest_strength;
    float reveal = clear_scene ? 1.0 : max(1.0-smoothstep(42.0,88.0,distance_to_actor),secondary);
    COLOR.a *= mix(1.0,cover_alpha,reveal);
}"""
	cutaway = ShaderMaterial.new(); cutaway.shader = cutaway_shader; material = cutaway
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
	var clear_scene := false
	var interest_strength:=0.0
	var companion=world.get_meta("exploration_companion") if is_instance_valid(world) and world.has_meta("exploration_companion") else null
	if fade and is_instance_valid(companion) and is_instance_valid(world.player) and companion.is_visible_in_tree() and covers(companion.global_position):
		interest_strength=1.0-smoothstep(240,440,world.player.global_position.distance_to(companion.global_position))
		if interest_strength>0:target=minf(target,.05)
	if fade and is_instance_valid(world) and is_instance_valid(world.player) and not world.player.enabled:
		for person in world.get_meta("intimate_scene_people",[]):
			if is_instance_valid(person) and person.is_visible_in_tree() and covers(person.global_position):target=0.0;clear_scene=true;break
	var next := lerpf(occlusion_alpha,target,1-exp(-delta*12))
	if absf(next-occlusion_alpha)>.001:
		occlusion_alpha=next;queue_redraw()
	elif occlusion_alpha!=target:
		occlusion_alpha=target;queue_redraw()
	if cutaway!=null:
		cutaway.set_shader_parameter("cover_alpha",occlusion_alpha)
		cutaway.set_shader_parameter("clear_scene",clear_scene)
		cutaway.set_shader_parameter("interest_strength",interest_strength)
		if is_instance_valid(companion):cutaway.set_shader_parameter("interest_point",to_local(companion.global_position)+Vector2(0,-35))
		if is_instance_valid(world) and is_instance_valid(world.player):
			cutaway.set_shader_parameter("focus_point",to_local(world.player.global_position)+Vector2(0,-42))
func _draw() -> void:
	# Keep the building's mass visible while revealing the actor behind it.
	# Intimate story shots still clear the whole obstructing facade when required.
	draw_texture_rect(texture,rect,false,tint)
