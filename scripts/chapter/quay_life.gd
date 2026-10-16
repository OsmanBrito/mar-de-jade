@tool
extends Node2D
## Small native effects: shoreline wash, moorings, gulls and smoke above the roofs.
var clock := 0.0
var boat: Sprite2D
var boat_origin := Vector2.ZERO
func p(u: float,v: float) -> Vector2: return Vector2(u-v,(u+v)*0.5)+Vector2(192,352)
func _ready() -> void:
	z_index = -2
	if Engine.is_editor_hint(): return
	boat = get_parent().get_node_or_null("ActorsAndProps/Caravela")
	if boat: boat_origin = boat.position
	var ground: TileMapLayer = get_parent().get_node("Ground")
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
varying vec2 world_position;
void vertex(){ world_position=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy; }
void fragment(){
  float wear=sin(world_position.x*0.011+sin(world_position.y*0.017))*sin(world_position.y*0.014);
  float damp=smoothstep(-0.2,0.8,wear);
  COLOR=vec4(COLOR.rgb*mix(vec3(0.96,0.96,0.90),vec3(0.76,0.81,0.75),damp*0.65),COLOR.a);
}
"""
	var material := ShaderMaterial.new(); material.shader = shader; ground.material = material
	var city_ground := get_parent().get_node_or_null("CityGround") as TileMapLayer
	if city_ground: city_ground.material = material
func _process(delta: float) -> void:
	clock += delta
	if boat: boat.position.y = boat_origin.y+sin(clock*0.7)*1.3
	queue_redraw()
func _draw() -> void:
	# Continuous retaining wall belongs to the river, including beyond the playable district.
	var ground := get_parent().get_node_or_null("Ground") as TileMapLayer
	if ground != null and get_parent().has_node("CityGround"):
		for v in range(-48,49):
			if v>=-5 and v<14: continue # World draws the active shore and pier edges.
			var center := ground.map_to_local(Vector2i(20,v+4))
			var a := center+Vector2(64,0); var b := center+Vector2(0,32)
			preload("res://scripts/chapter/quay_bank.gd").draw(self,a,b)
	# Worn cart tracks run along the street; drains and edging follow the same axes.
	for v in [245,315]:
		for u in range(-140,880,30):
			draw_line(p(u,v),p(u+18,v),Color(0.25,0.22,0.16,0.12),2)
	for u in range(-160,900,24):
		draw_line(p(u,348),p(u+18,348),Color("897d60"),2)
		draw_line(p(u,351),p(u+18,351),Color(0.88,0.82,0.65,0.6),1)
	for v in range(-180,650,38):
		var a := p(895,v); var b := p(895,v+32)
		draw_line(a,b,Color("c9b895"),5)
		draw_line(a+Vector2(5,8),b+Vector2(5,8),Color(0.69,0.81,0.69,0.22+sin(clock*1.4+v)*0.08),2)
	# Mooring lines run down to the vessel without crossing the walking corridor.
	draw_polyline(PackedVector2Array([p(1145,350),p(1190,450)+Vector2(0,10+sin(clock)*1.5),p(1190,490)]),Color("887455"),2,true)
	# Distant roof smoke stays subtle and follows a slow wind.
	for source in [p(180,130)+Vector2(0,-250),p(420,455)+Vector2(0,-250)]:
		for i in 5:
			var age := fposmod(clock*0.14+i*0.2,1.0)
			draw_circle(source+Vector2(age*28,-age*55),4+age*11,Color(0.86,0.84,0.73,(1-age)*0.16))
	for i in 4:
		var center := p(980,300)+Vector2(sin(clock*0.13+i*1.7)*180,-200+cos(clock*0.18+i)*80)
		var flap := sin(clock*4+i)*3
		draw_polyline(PackedVector2Array([center+Vector2(-7,-2-flap),center,center+Vector2(7,-2-flap)]),Color("d9dcc8"),1.5,true)
