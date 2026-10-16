extends "res://scripts/combat/portugal_arena.gd"
## Mar de Ferro's modular painted deck, water, fittings and illustrated actors.
const Layout = preload("res://scripts/navigation/boarding_layout.gd")
const Assets = preload("res://scripts/navigation/boarding_assets.gd")
const CrewArt = preload("res://scripts/navigation/boarding_actor_art.gd")
var focus: Array[Vector2] = []
var wood: CanvasTexture
var sea: CanvasTexture
func setup(canvas: Node2D) -> void:
	c = canvas
	wood = Assets.texture("regional-deck.png",true)
	sea = Assets.texture("regional-water-illustrated-v1.png",true)
func deck_point(x: float,y: float) -> Vector2: return Layout.point(x,y)
func deck_outline() -> PackedVector2Array: return Layout.outline()
func surface(points: PackedVector2Array,tint: Color = Color.WHITE,period: float = 4) -> void:
	var uv := PackedVector2Array()
	for p in points:
		var local := p-Board.ORIGIN
		uv.append(Vector2((local.x/Board.STEP.x+local.y/Board.STEP.y)*0.5,(local.y/Board.STEP.y-local.x/Board.STEP.x)*0.5)/period)
	c.draw_polygon(points,PackedColorArray([tint]),uv,wood)
func patch(x: float,y: float,width: float,height: float,tint: Color = Color.WHITE,offset := Vector2.ZERO) -> void:
	surface(PackedVector2Array([Layout.point(x,y)+offset,Layout.point(x+width,y)+offset,Layout.point(x+width,y+height)+offset,Layout.point(x,y+height)+offset]),tint)
func rail(a: Vector2,b: Vector2,tint: Color) -> void:
	# A textured solid gunwale with a dark iron fastener at each timber upright.
	var face := PackedVector2Array([a,b,b-Vector2(0,8),a-Vector2(0,8)])
	surface(face,tint.darkened(0.3),2)
	c.draw_line(a,b,Color("372e25"),1.5,true)
	c.draw_line(a-Vector2(0,8),b-Vector2(0,8),Color("c4a371"),2,true)
	var posts := maxi(1,ceili(a.distance_to(b)/29))
	for i in range(posts+1):
		var p := a.lerp(b,float(i)/posts)
		c.draw_line(p+Vector2(0,2),p-Vector2(0,10),Color("302e27"),3.3,true)
		c.draw_line(p,p-Vector2(0,10),Color("9f8258"),1.4,true)
		c.draw_circle(p-Vector2(0,5),0.8,Color("d1b17c"))
func draw_ground(_encounter: String,time: float,reduced: bool) -> void:
	var motion := 0.0 if reduced else time
	c.draw_rect(Rect2(0,0,960,540),Color("285763"))
	var points := PackedVector2Array([Vector2.ZERO,Vector2(960,0),Vector2(960,540),Vector2(0,540)])
	var uv := PackedVector2Array()
	for p in points: uv.append(p/520.0+Vector2(motion*0.004,motion*0.002))
	c.draw_polygon(points,PackedColorArray([Color(0.82,0.89,0.89,0.83)]),uv,sea)
	draw_ship(Layout.FRIENDLY_OFFSET,true,motion)
	draw_ship(Vector2.ZERO,false,motion)
	# Two real openings, laid planks, rope lashes and contact shadows.
	for x in [0.8,2.15]:
		patch(x,3.82,0.62,1.95,Color("524736"),Vector2(0,4))
		patch(x,3.82,0.62,1.95,Color("d6c7a6"))
		for seam in [0.2,0.4]: c.draw_line(Layout.point(x+seam,3.82),Layout.point(x+seam,5.77),Color("755b3b"),0.6,true)
		for end in [4.05,5.5]:
			c.draw_line(Layout.point(x-0.06,end),Layout.point(x+0.68,end),Color("604c33"),2.5,true)
			c.draw_line(Layout.point(x-0.06,end),Layout.point(x+0.68,end),Color("c1aa7d"),0.85,true)
	# Foreground crew are anonymous sailors, keeping story identities untouched.
	draw_prop("deckhouse",Layout.point(-0.55,7.35),Vector2(86,77),Color("c3c6b7"),false)
	draw_prop("mast",Layout.point(3.8,6.9),Vector2(74,117),Color.WHITE,true)
	draw_prop("barrel",Layout.point(1.65,8.6),Vector2(23,29),Color.WHITE,false)
	draw_prop("crate",Layout.point(7.7,8.8),Vector2(34,30),Color.WHITE,false)
	draw_prop("helm",Layout.point(0.3,8.5),Vector2(29,34),Color.WHITE,false)
	CrewArt.draw_actor(c,"sailor",Layout.point(0.7,6.75),false,"ready",time,0,reduced,false)
	CrewArt.draw_actor(c,"worker",Layout.point(5.8,7.1),true,"ready",time,0,reduced,false)
	c.centered("BOTAFOGO",379,9,Color("eddfbb"),455)
func draw_ship(offset: Vector2,friendly: bool,time: float) -> void:
	var deck := Layout.outline(offset)
	var shadow := PackedVector2Array()
	for p in deck: shadow.append(p+Vector2(4,19))
	c.draw_colored_polygon(shadow,Color(0.02,0.10,0.12,0.35))
	# Individual hull faces have the same painted timber, natural shading and depth.
	for i in deck.size():
		var a := deck[i]; var b := deck[(i+1)%deck.size()]
		if b.x>a.x: continue
		var face := PackedVector2Array([a,b,b+Vector2(0,12),a+Vector2(0,12)])
		var uv := PackedVector2Array([Vector2.ZERO,Vector2(a.distance_to(b)/160,0),Vector2(a.distance_to(b)/160,0.38),Vector2(0,0.38)])
		c.draw_polygon(face,PackedColorArray([Color("57432e")]),uv,wood)
		c.draw_line(a+Vector2(0,12),b+Vector2(0,12),Color("253532"),2,true)
	var tint := Color("aeb9aa") if friendly else Color("d2c3a8")
	surface(deck,tint)
	var edge := deck.duplicate(); edge.append(deck[0])
	c.draw_polyline(edge,Color("403325"),4,true); c.draw_polyline(edge,Color("c4a371"),1.6,true)
	# Raised strips remain outside all walkable cells.
	patch(-1.05,offset.y,0.35,3.0,tint.darkened(0.2),Vector2(0,-3))
	var back := offset.y-0.85
	if friendly:
		for ends in [Vector2(-0.65,0.65),Vector2(1.55,2.0),Vector2(2.85,8.8)]: rail(Layout.point(ends.x,back),Layout.point(ends.y,back),tint)
	else: rail(Layout.point(-0.65,back),Layout.point(8.8,back),tint)
	rail(deck[0],deck[1],tint); rail(deck[0],deck[6],tint)
	var front := offset.y+3.85
	if friendly: rail(Layout.point(-0.65,front),Layout.point(8.8,front),tint)
	else:
		for ends in [Vector2(-0.65,0.65),Vector2(1.55,2.0),Vector2(2.85,8.8)]: rail(Layout.point(ends.x,front),Layout.point(ends.y,front),tint)
	for x in [2.0,7.1]: draw_prop("cannon",Layout.point(x,offset.y-0.62),Vector2(38,34),Color("e2e0ce"),false)
	# Faint foam tracks sit beneath the keel and never cover the tactical field.
	for i in 12:
		var p := Layout.point(i*0.78-0.5,offset.y+4.12)+Vector2(0,14)
		c.draw_line(p,p+Vector2(13,3),Color(0.75,0.86,0.81,0.15+sin(time*1.5+i)*0.04),1,true)
func prop_bounds(key: String,foot: Vector2,bounds: Vector2) -> Rect2:
	var texture := Assets.prop(key)
	var shown := texture.get_size()*minf(bounds.x/texture.get_width(),bounds.y/texture.get_height())
	return Rect2(foot-Vector2(shown.x*0.5,shown.y),shown)
func prop_alpha(key: String,rect: Rect2) -> float:
	var texture := Assets.prop(key)
	var pixels: Image = Assets.images[Assets.data().props[key].source.get_file()]
	for foot in focus:
		if foot.y>=rect.end.y-8: continue
		var head := foot-Vector2(0,37)
		if not rect.has_point(head): continue
		var pixel := Vector2i(texture.region.position+(head-rect.position)/rect.size*texture.region.size)
		if pixels.get_pixelv(pixel).a>0.45: return 0.38
	return 1.0
func draw_prop(key: String,foot: Vector2,bounds: Vector2,tint: Color = Color.WHITE,fade: bool = true) -> void:
	var rect := prop_bounds(key,foot,bounds)
	var alpha := prop_alpha(key,rect) if fade else 1.0
	c.draw_texture_rect(Assets.contact_shadow(),Rect2(foot-Vector2(rect.size.x*0.52,4),Vector2(rect.size.x*1.04,12)),false,Color(1,1,1,alpha))
	c.draw_texture_rect(Assets.prop(key),rect,false,Color(tint,alpha))
func draw_obstacle(_encounter: String,cell: Vector2i,_deck: bool = false) -> void:
	if cell==Vector2i(4,0): draw_prop("mast",Board.screen(cell),Vector2(77,122))
	else: draw_prop("crate",Board.screen(cell)+Vector2(0,7),Vector2(39,36))
