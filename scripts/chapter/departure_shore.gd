extends Node2D
## Fixed Lisbon backdrop: the vessel moves away while the quay stays behind.
func _ready() -> void:
	z_index = -5
	var ground := TileMapLayer.new(); ground.name = "QuayPaving"; ground.z_index = -1
	ground.tile_set = preload("res://data/terrain/ground.tres"); ground.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	for x in range(-24,17):
		for y in range(-24,17): ground.set_cell(Vector2i(x,y),0,Vector2i.ZERO)
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; varying vec2 at; void vertex(){at=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;} void fragment(){if(at.y>45.0+(at.x+700.0)*210.0/1240.0)discard; COLOR*=vec4(0.84,0.84,0.75,1.0);}"
	var material := ShaderMaterial.new(); material.shader = shader; ground.material = material; add_child(ground)
	var frames: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/living-quay/frames.json"))
	for spec in [[0,Vector2(-360,85),220.0],[1,Vector2(-60,140),250.0]]:
		var r: Array = frames.buildings.frames[spec[0]]
		var atlas := AtlasTexture.new(); atlas.atlas = load(frames.buildings.path)
		atlas.region = Rect2(r[0],r[1],r[2],r[3])
		var sprite := Sprite2D.new(); sprite.texture = atlas; sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.scale = Vector2.ONE*spec[2]/float(r[2]); sprite.position = spec[1]-Vector2(0,r[3]*sprite.scale.y*0.5)
		add_child(sprite)

func _draw() -> void:
	var a := Vector2(-1800,-141.3); var b := Vector2(1800,468.4)
	preload("res://scripts/chapter/quay_bank.gd").draw(self,a,b)
	for i in 24:
		var at := a.lerp(b,float(i)/23)
		draw_line(at-Vector2(0,8),at+Vector2(0,13),Color("5a6555"),1,true)
