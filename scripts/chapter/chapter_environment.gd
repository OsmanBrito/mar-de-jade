@tool
extends Node2D
## Surroundings for the city square; authored walking routes stay intact.
const ART := "res://assets/art/living-quay/"

static func install(world: Node2D) -> void:
	if world.has_node("CityGround"): return
	var ground: TileMapLayer = world.get_node("Ground")
	var city := TileMapLayer.new()
	city.name = "CityGround"; city.tile_set = ground.tile_set
	city.z_index = -1; city.texture_filter = ground.texture_filter
	for x in range(-22,32):
		for y in range(-22,32): city.set_cell(Vector2i(x,y),0,Vector2i.ZERO)
	world.add_child(city)
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
varying vec2 world_at;
void vertex(){ world_at=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy; }
void fragment(){
  float wear=sin(world_at.x*0.012+sin(world_at.y*0.019))*sin(world_at.y*0.015);
  float track=exp(-pow((world_at.y-world_at.x*0.5-215.0)/18.0,2.0));
  vec3 patina=mix(vec3(0.96,0.96,0.89),vec3(0.82,0.85,0.76),0.4+wear*0.32);
  COLOR=vec4(COLOR.rgb*patina*(1.0-track*0.075),COLOR.a);
}
"""
	var paving := ShaderMaterial.new(); paving.shader = shader
	ground.material = paving; city.material = paving
	world.set_meta("city_square",true)
	var dressing := Node2D.new()
	dressing.set_script(load("res://scripts/chapter/chapter_environment.gd"))
	dressing.name = "PracaDeLisboa"; dressing.z_index = 1
	world.add_child(dressing)
	var frames: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ART+"frames.json"))
	for spec in [
		["Abrigo",0,Vector2(-365,35),330.0],
		["CasaDaPraca",3,Vector2(285,35),315.0],
		["Oficina",2,Vector2(-730,225),330.0],
		["Armazem",1,Vector2(755,210),370.0],
		["RuaNorte",1,Vector2(-50,-190),390.0],
		["RuaSul",3,Vector2(-805,665),330.0],
		["RuaLeste",0,Vector2(800,680),330.0]]:
		var r: Array = frames.buildings.frames[spec[1]]
		var sprite := Sprite2D.new(); sprite.name = spec[0]
		var atlas := AtlasTexture.new(); atlas.atlas = load(frames.buildings.path)
		atlas.region = Rect2(r[0],r[1],r[2],r[3]); sprite.texture = atlas
		var factor: float = spec[3]/float(r[2])
		sprite.scale = Vector2.ONE*factor
		sprite.position = spec[2]+Vector2(0,-r[3]*factor*0.5)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		dressing.add_child(sprite)
	# Planters use the existing painted foliage and tangible, matching bases.
	for origin in [Vector2(-435,340),Vector2(435,340)]:
		var plant := Node2D.new(); plant.position = origin; world.sorted_world.add_child(plant)
		var body := StaticBody2D.new(); body.collision_mask = 0; plant.add_child(body)
		var shape := CollisionPolygon2D.new()
		shape.polygon = PackedVector2Array([Vector2(-63,0),Vector2(0,-31),Vector2(63,0),Vector2(0,31)])
		body.add_child(shape)
		var r: Array = frames.details.frames[3]
		var foliage := Sprite2D.new(); var texture := AtlasTexture.new()
		texture.atlas = load(frames.details.path); texture.region = Rect2(r[0],r[1],r[2],r[3])
		foliage.texture = texture; foliage.scale = Vector2.ONE*91.0/r[2]
		foliage.position = Vector2(0,-r[3]*foliage.scale.y*0.5+5)
		foliage.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR; plant.add_child(foliage)
	world.queue_redraw()

func _draw() -> void:
	for origin in [Vector2(-435,340),Vector2(435,340)]:
		var bed := PackedVector2Array([origin+Vector2(-65,0),origin+Vector2(0,-32),origin+Vector2(65,0),origin+Vector2(0,32)])
		for side in [[bed[0],bed[3]],[bed[3],bed[2]]]:
			draw_colored_polygon(PackedVector2Array([side[0],side[1],side[1]+Vector2(0,8),side[0]+Vector2(0,8)]),Color("796d55"))
		draw_colored_polygon(bed,Color("4e5239"))
		var outline := bed.duplicate(); outline.append(bed[0])
		draw_polyline(outline,Color("ad9e7e"),7,true)
		for i in 60:
			var at: Vector2 = origin+Vector2(sin(i*2.4)*44,cos(i*3.7)*15)
			draw_circle(at,1.0,Color("8d8b59"))
	for i in range(-9,10):
		var at := Vector2(i*64,608-abs(i)*32)
		draw_line(at,at+Vector2(32,-16 if i<0 else 16),Color("8e8267"),2,true)
	# Stone enclosure makes the finite walking area legible against the city beyond.
	var corners := PackedVector2Array([Vector2(0,-32),Vector2(640,288),Vector2(0,608),Vector2(-640,288)])
	var masonry := CanvasTexture.new()
	masonry.diffuse_texture = preload("res://assets/art/living-quay/mar-de-ferro-bank-masonry-v1.png")
	masonry.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	for i in 4:
		var a := corners[i]; var b := corners[(i+1)%4]
		var face := PackedVector2Array([a,b,b-Vector2(0,22),a-Vector2(0,22)])
		var uv := PackedVector2Array([Vector2(0,0.4),Vector2(a.distance_to(b)/145.0,0.4),Vector2(a.distance_to(b)/145.0,0.1),Vector2(0,0.1)])
		draw_polygon(face,PackedColorArray([Color("c3b08b")]),uv,masonry)
		draw_line(a-Vector2(0,22),b-Vector2(0,22),Color("ccbd98"),4,true)
		var count := ceili(a.distance_to(b)/34)
		for joint in count:
			var at := a.lerp(b,float(joint)/count)
			draw_line(at,at-Vector2(0,21),Color("82775e"),1,true)
