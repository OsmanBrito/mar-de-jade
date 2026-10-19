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
	var ground_details := Node2D.new()
	ground_details.set_script(preload("res://scripts/chapter/square_ground_details.gd"))
	ground_details.name = "DesgasteLocal"; ground_details.z_index = 1
	world.add_child(ground_details)
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
	preload("res://scripts/chapter/order_house.gd").install_exterior(world,dressing)
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
	for i in 4:
		var a := corners[i]; var b := corners[(i+1)%4]
		var count := ceili(a.distance_to(b)/34)
		for row in 2:
			for joint in count+1:
				var start := clampf((joint-row*0.5)/count,0,1)
				var end := clampf((joint+1-row*0.5)/count,0,1)
				if end <= start: continue
				if get_parent().has_meta("open_lisbon"):
					if i==3 and start>0.33 and end<0.61: continue
					if (i==0 and start>0.80) or (i==1 and end<0.20): continue
				var p := a.lerp(b,start)-Vector2(0,row*11)
				var q := a.lerp(b,end)-Vector2(0,row*11)
				var color := Color("ac9c7c").lightened(fposmod(joint*0.127+row*0.21+i*0.1,0.16))
				draw_colored_polygon(PackedVector2Array([p,q,q-Vector2(0,10),p-Vector2(0,10)]),color)
				draw_line(q,q-Vector2(0,10),Color(0.35,0.32,0.23,0.42),0.8,true)
			draw_line(a-Vector2(0,row*11),b-Vector2(0,row*11),Color(0.35,0.32,0.23,0.26),0.8,true)
		var caps: Array = [[0.0,1.0]]
		if get_parent().has_meta("open_lisbon"):
			if i==3: caps = [[0.0,0.33],[0.61,1.0]]
			elif i==0: caps = [[0.0,0.80]]
			elif i==1: caps = [[0.20,1.0]]
		for segment in caps:
			var p := a.lerp(b,segment[0]); var q := a.lerp(b,segment[1])
			draw_colored_polygon(PackedVector2Array([p-Vector2(0,21),q-Vector2(0,21),q-Vector2(0,25),p-Vector2(0,25)]),Color("d1c09a"))
			draw_line(p-Vector2(0,25),q-Vector2(0,25),Color("e0ceaa"),1,true)
