extends Node2D
## A ship-shaped walking surface using the painted timber and fittings of boarding combat.
const Assets = preload("res://scripts/navigation/boarding_assets.gd")
const OUTLINE := [Vector2(-455,240),Vector2(-385,180),Vector2(-260,178),Vector2(240,270),Vector2(430,360),Vector2(290,490),Vector2(-230,382),Vector2(-455,285)]
var departure_progress := 0.0:
	set(value): departure_progress = value; queue_redraw()
var rope_owner: Node2D
var rope_secured := false

func _process(_delta: float) -> void:
	if is_instance_valid(rope_owner): queue_redraw()
static func install(world: Node2D) -> void:
	world.set_meta("departure_deck",true)
	world.terrain.hide()
	var deck := Node2D.new(); deck.set_script(load("res://scripts/chapter/departure_deck.gd"))
	deck.name = "ConvesDaBotafogo"; deck.z_index = 1; world.add_child(deck)
	for spec in [["deckhouse",Vector2(-355,245),Vector2(135,120)], ["mast",Vector2(-235,255),Vector2(150,230)], ["helm",Vector2(-325,290),Vector2(53,64)], ["crate",Vector2(-285,315),Vector2(56,50)], ["barrel",Vector2(260,425),Vector2(42,57)], ["mast",Vector2(305,365),Vector2(88,135)]]:
		var sprite := Sprite2D.new(); sprite.texture = Assets.prop(spec[0])
		var factor: float = minf(spec[2].x/sprite.texture.get_width(),spec[2].y/sprite.texture.get_height())
		sprite.scale = Vector2.ONE*factor
		sprite.position = spec[1]-Vector2(0,sprite.texture.get_height()*factor*0.5)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		world.sorted_world.add_child(sprite)
		var body := StaticBody2D.new(); body.collision_mask = 0
		body.position = spec[1]; world.sorted_world.add_child(body)
		var shape := CollisionPolygon2D.new()
		var width: float = 24 if spec[0]=="deckhouse" else 12
		shape.polygon = PackedVector2Array([Vector2(-width,0),Vector2(0,-width*0.4),Vector2(width,0),Vector2(0,width*0.4)])
		body.add_child(shape)

static func contains(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point,PackedVector2Array(OUTLINE))

func _draw() -> void:
	var deck := PackedVector2Array(OUTLINE)
	if departure_progress>0:
		for side in [-1,1]:
			var wake := PackedVector2Array()
			for i in 8:
				var trail := float(i)/7
				wake.append(Vector2(-455,275)+Vector2(-110*trail,-42*trail+side*(8+trail*15))*departure_progress)
			draw_polyline(wake,Color(0.67,0.83,0.77,departure_progress*0.3),2,true)
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
	if is_instance_valid(rope_owner) or rope_secured:
		var end: Vector2 = to_local(rope_owner.global_position)+Vector2(0,-30) if is_instance_valid(rope_owner) else Vector2(-140,330)
		var curve := PackedVector2Array()
		for i in 17:
			var weight := float(i)/16
			curve.append(Vector2(-60,290).lerp(end,weight)+Vector2(0,sin(weight*PI)*10))
		draw_polyline(curve,Color("436b79"),3.5,true)
		draw_polyline(curve,Color("8eb5bd"),1.1,true)
	# Standing rigging stays behind the cast rather than crossing their faces.
	for endpoint in [Vector2(-385,180),Vector2(240,270)]:
		draw_line(Vector2(-235,65),endpoint,Color("7b7156"),1.5,true)
	draw_line(Vector2(-235,90),Vector2(305,250),Color("928265"),1.5,true)
