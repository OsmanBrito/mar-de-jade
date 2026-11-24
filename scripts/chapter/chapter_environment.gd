@tool
extends Node2D
## Lisbon square ground: painted paving replaces the tile look at runtime.
## Buildings ("PracaDeLisboa") and planters are authored in
## scenes/maps/praca_infancia.tscn; tools/build_plaza_square.gd made the first layout.
const GROUND_SHADER := preload("res://assets/shaders/lisbon_square_ground.gdshader")
const GROUND_ATLAS := preload("res://assets/art/terrain_atlas.png")
static func install(world: Node2D) -> void:
	if world.has_node("CityGround"): return
	var ground: TileMapLayer = world.get_node("Ground")
	# The city tiles keep defining navigation and edges; the painted surface replaces their look.
	var city := TileMapLayer.new()
	city.name = "CityGround"; city.tile_set = ground.tile_set
	city.z_index = -1; city.visible = false
	for x in range(-22,32):
		for y in range(-22,32): city.set_cell(Vector2i(x,y),0,Vector2i.ZERO)
	world.add_child(city)
	ground.self_modulate = Color(1,1,1,0)
	var surface := Polygon2D.new(); surface.name = "Calcada"; surface.z_index = -1
	surface.polygon = PackedVector2Array([Vector2(-2600,-1700),Vector2(2600,-1700),Vector2(2600,2300),Vector2(-2600,2300)])
	var paving := ShaderMaterial.new(); paving.shader = GROUND_SHADER
	paving.set_shader_parameter("atlas",GROUND_ATLAS)
	surface.material = paving
	surface.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	world.add_child(surface); world.move_child(surface,0)
	world.set_meta("city_square",true)
	var ground_details := Node2D.new()
	ground_details.set_script(preload("res://scripts/chapter/square_ground_details.gd"))
	ground_details.name = "DesgasteLocal"; ground_details.z_index = 1
	world.add_child(ground_details)
	world.queue_redraw()
