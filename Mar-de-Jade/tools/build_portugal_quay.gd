extends SceneTree
## Bake the revised layout into an editable map scene, rather than assembling it in gameplay.
func _initialize() -> void:
	var map = load("res://scenes/maps/cais.tscn").instantiate()
	map.name = "CaisPortugal"
	var ground: TileMapLayer = map.get_node("Ground")
	ground.clear()
	# Land continues behind the street; only the river-facing edges terminate here.
	for x in range(-6,14):
		for y in range(-6,12):
			ground.set_cell(Vector2i(x,y),0,Vector2i.ZERO)
	for x in range(14,19):
		for y in range(5,8): ground.set_cell(Vector2i(x,y),0,Vector2i(1,0))
	var sorted = map.get_node("ActorsAndProps")
	sorted.get_node("house_00").position = Vector2(-190,450)
	sorted.get_node("house_00").scale = Vector2.ONE*0.57
	sorted.get_node("house_01").position = Vector2(-510,290)
	sorted.get_node("house_01").scale = Vector2.ONE*0.52
	for spec in [["warehouse_back",Vector2(190,295),0.60],["warehouse_street",Vector2(-130,135),0.56],["warehouse_far",Vector2(-490,35),0.48],["warehouse_loading",Vector2(510,455),0.50]]:
		var house = load("res://scenes/props/house.tscn").instantiate()
		house.name = spec[0]; house.object_id = StringName("cais_portugal/"+spec[0])
		house.position = spec[1]; house.scale = Vector2.ONE*spec[2]
		if spec[0] in ["warehouse_back","warehouse_street","warehouse_loading"]: house.scale.x *= -1
		sorted.add_child(house); house.owner = map
	sorted.get_node("pine_02").position = Vector2(-650,470)
	sorted.get_node("pine_03").position = Vector2(730,300)
	sorted.get_node("pine_04").free()
	sorted.get_node("crane_05").position = Vector2(560,610)
	sorted.get_node("crates_06").position = Vector2(425,560)
	sorted.get_node("crates_07").position = Vector2(-65,570)
	sorted.get_node("crates_08").position = Vector2(670,740)
	for spec in [["crates_09",Vector2(370,485),0.24],["crates_10",Vector2(-125,595),0.20]]:
		var cargo = load("res://scenes/props/crates.tscn").instantiate()
		cargo.name = spec[0]; cargo.object_id = StringName("cais_portugal/"+spec[0])
		cargo.position = spec[1]; cargo.scale = Vector2.ONE*spec[2]
		sorted.add_child(cargo); cargo.owner = map
	sorted.get_node("warehouse_door").position = Vector2(-144,442)
	map.get_node("Spawn").position = Vector2(64,544)
	var packed := PackedScene.new()
	var error := packed.pack(map)
	if error==OK: error = ResourceSaver.save(packed,"res://scenes/maps/cais_portugal.tscn")
	map.free(); print("PORTUGAL_QUAY_LAYOUT ",error); quit(error)
