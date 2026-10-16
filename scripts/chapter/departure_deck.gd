extends Node2D
## A ship-shaped walking surface using the painted timber and fittings of boarding combat.
const Assets = preload("res://scripts/navigation/boarding_assets.gd")
const OUTLINE := [Vector2(-440,260),Vector2(-310,167),Vector2(220,167),Vector2(455,305),Vector2(325,485),Vector2(-280,485),Vector2(-440,395)]
static func install(world: Node2D) -> void:
	world.set_meta("departure_deck",true)
	world.terrain.hide()
	var deck := Node2D.new(); deck.set_script(load("res://scripts/chapter/departure_deck.gd"))
	deck.name = "ConvesDaBotafogo"; deck.z_index = 1; world.add_child(deck)
	for spec in [["mast",Vector2(-270,260),Vector2(160,240)], ["helm",Vector2(255,235),Vector2(66,78)], ["crate",Vector2(-305,403),Vector2(64,58)], ["barrel",Vector2(260,425),Vector2(42,57)]]:
		var sprite := Sprite2D.new(); sprite.texture = Assets.prop(spec[0])
		var factor: float = minf(spec[2].x/sprite.texture.get_width(),spec[2].y/sprite.texture.get_height())
		sprite.scale = Vector2.ONE*factor
		sprite.position = spec[1]-Vector2(0,sprite.texture.get_height()*factor*0.5)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		world.sorted_world.add_child(sprite)

static func contains(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point,PackedVector2Array(OUTLINE))

func _draw() -> void:
	var deck := PackedVector2Array(OUTLINE)
	var shadow := PackedVector2Array()
	for point in deck: shadow.append(point+Vector2(8,33))
	draw_colored_polygon(shadow,Color(0.02,0.1,0.12,0.35))
	for i in deck.size():
		var a := deck[i]; var b := deck[(i+1)%deck.size()]
		draw_colored_polygon(PackedVector2Array([a,b,b+Vector2(0,24),a+Vector2(0,24)]),Color("4f3e2b"))
	var uv := PackedVector2Array()
	for point in deck: uv.append(Vector2(point.x/290.0+point.y/145.0,point.y/145.0-point.x/290.0))
	draw_polygon(deck,PackedColorArray([Color("d1c4a8")]),uv,Assets.texture("regional-deck.png",true))
	var edge := deck.duplicate(); edge.append(deck[0])
	draw_polyline(edge,Color("42352a"),10,true)
	draw_polyline(edge,Color("bda078"),4,true)
	for i in deck.size():
		var a := deck[i]; var b := deck[(i+1)%deck.size()]
		var posts := maxi(1,ceili(a.distance_to(b)/48))
		for step in posts:
			var foot := a.lerp(b,float(step)/posts)
			draw_line(foot,foot-Vector2(0,16),Color("5a4632"),5,true)
		draw_line(a-Vector2(0,16),b-Vector2(0,16),Color("cfb48a"),3,true)
	for origin in [Vector2(-60,290),Vector2(50,290)]:
		preload("res://scripts/chapter/story_prop_art.gd").draw_item(self,"PT-T01",origin+Vector2(0,7),48)
		if origin.x<0: draw_line(origin+Vector2(-13,0),origin+Vector2(12,0),Color("68a3bc"),4,true)
