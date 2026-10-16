extends "res://scripts/combat/portugal_arena.gd"
const Layout = preload("res://scripts/navigation/boarding_layout.gd")
const People = preload("res://scripts/npcs/lisbon_npc_library.gd")
const WOOD := Color("a48560")
func deck_point(x: float,y: float) -> Vector2: return Layout.point(x,y)
func deck_outline() -> PackedVector2Array: return Layout.outline()
func patch(x: float,y: float,width: float,height: float,colour: Color,offset := Vector2.ZERO) -> void:
	c.draw_colored_polygon(PackedVector2Array([Layout.point(x,y)+offset,Layout.point(x+width,y)+offset,Layout.point(x+width,y+height)+offset,Layout.point(x,y+height)+offset]),colour)
func rail(a: Vector2,b: Vector2,colour: Color) -> void:
	c.draw_line(a,b,Color("4c392b"),4,true)
	var length := a.distance_to(b)
	for i in range(ceili(length/21)+1):
		var p := a.lerp(b,float(i)/maxi(1,ceili(length/21)))
		c.draw_line(p,p-Vector2(0,10),colour.darkened(0.2),2,true)
	c.draw_line(a-Vector2(0,10),b-Vector2(0,10),colour,2.5,true)
	c.draw_line(a-Vector2(0,5),b-Vector2(0,5),colour.darkened(0.28),1,true)
func draw_ground(_encounter: String,time: float,reduced: bool) -> void:
	c.draw_rect(Rect2(0,0,960,540),Color("194650"))
	for i in 110:
		var p := Vector2(fposmod(i*157.1+time*(1 if reduced else 5),1000)-20,fposmod(i*73.7,540))
		c.draw_line(p,p+Vector2(13+sin(i)*9,-2),Color(0.55,0.77,0.76,0.09),1,true)
	draw_ship(Layout.FRIENDLY_OFFSET,true,time)
	draw_ship(Vector2.ZERO,false,time)
	# Both decks are visible. The party has already crossed before turn one.
	for x in [0.8,2.15]:
		patch(x,3.82,0.62,1.95,Color("493b2d"),Vector2(0,3))
		patch(x,3.82,0.62,1.95,Color("b59b74"))
		for seam in [0.19,0.4]:
			c.draw_line(Layout.point(x+seam,3.82),Layout.point(x+seam,5.77),Color("776044"),0.8,true)
		for end in [4.05,5.55]:
			c.draw_line(Layout.point(x+0.05,end),Layout.point(x+0.57,end),Color("584635"),1.8,true)
	# The foreground mast must stand in front of the neighbouring ship's hull.
	draw_mast(Layout.point(3.8,Layout.FRIENDLY_OFFSET.y+1.35),true,time)
	# The Botafogo's crew holds the other deck, outside the combat simulation.
	for crew in [{"id":"rodrigo","cell":Vector2(0.6,6.9)},{"id":"beatriz","cell":Vector2(5.8,7.1)}]:
		var p := Layout.point(crew.cell.x,crew.cell.y)
		c.draw_set_transform(p,0,Vector2(1,0.36)); c.draw_circle(Vector2.ZERO,12,Color(0.04,0.08,0.08,0.25)); c.draw_set_transform(Vector2.ZERO)
		var entry: Dictionary = People.data()[crew.id]
		People.draw_actor(c,crew.id,3,false,0,"standing",60.0/float(entry.height),p)
	c.centered("BOTAFOGO",379,9,Color("d9c6a0"),455)
func draw_ship(offset: Vector2,friendly: bool,time: float) -> void:
	var deck := Layout.outline(offset)
	# A deep hull, waterline and contact shadow give the deck volume.
	var shadow := PackedVector2Array(); var bottom := PackedVector2Array()
	for p in deck: shadow.append(p+Vector2(5,20)); bottom.append(p+Vector2(0,12))
	c.draw_colored_polygon(shadow,Color(0.03,0.12,0.15,0.38))
	c.draw_colored_polygon(bottom,Color("352d27"))
	var wood := Color("8d795b") if friendly else WOOD
	c.draw_colored_polygon(deck,wood)
	# Planks, staggered joints and grain follow the unchanged tactical projection.
	for row in 27:
		var y: float = -0.8+row*0.17+offset.y
		var shade: float = sin(row*7.71)*0.035
		patch(-0.6,y,9.38,0.17,wood.lightened(shade) if shade>0 else wood.darkened(-shade))
		c.draw_line(Layout.point(-0.6,y),Layout.point(8.78,y),Color(0.25,0.18,0.12,0.52),0.65,true)
		for joint in 5:
			var x: float = -0.5+joint*2.0+(0.8 if row%2 else 0.0)
			if x>8.7: continue
			c.draw_line(Layout.point(x,y),Layout.point(x,y+0.17),Color(0.28,0.21,0.15,0.45),0.6,true)
			var grain: float = 0.6+fposmod(row*0.31+joint*0.72,0.9)
			c.draw_line(Layout.point(x+0.08,y+0.08),Layout.point(minf(8.7,x+grain),y+0.08),Color(0.9,0.8,0.62,0.13),0.5,true)
	# Forecastle and stern sit outside the walkable cells, like courtyard scenery.
	patch(-1.0,offset.y,0.35,3.0,wood.darkened(0.19),Vector2(0,-4))
	var bow := PackedVector2Array([Layout.point(8.8,offset.y-0.82),Layout.point(10.05,offset.y+1.5),Layout.point(8.8,offset.y+3.82)])
	c.draw_colored_polygon(bow,wood.darkened(0.08))
	for y in range(0,4): c.draw_line(Layout.point(8.85,offset.y+y),Layout.point(9.4 if y in [1,2] else 8.9,offset.y+y),Color("715a40"),0.7,true)
	var edge := deck.duplicate(); edge.append(deck[0])
	c.draw_polyline(edge,Color("49382b"),5,true); c.draw_polyline(edge,Color("cfb993"),2.4,true)
	rail(Layout.point(-0.65,offset.y-0.85),Layout.point(8.8,offset.y-0.85),Color("b49a71"))
	rail(deck[0],deck[1],Color("b49a71")); rail(deck[0],deck[6],Color("b49a71"))
	# Rail openings line up with the two boarding planks.
	if not friendly:
		for ends in [Vector2(-0.65,0.65),Vector2(1.55,2.0),Vector2(2.85,8.8)]:
			rail(Layout.point(ends.x,3.85),Layout.point(ends.y,3.85),Color("c3aa80"))
	for x in [3.1,6.7]: draw_cannon(Layout.point(x,offset.y-0.55),true)
	if friendly:
		rail(Layout.point(-0.65,offset.y+3.85),Layout.point(8.8,offset.y+3.85),Color("ac946f"))
	else:
		var flag := Layout.point(-0.8,1.7)-Vector2(0,48)
		c.draw_line(flag,flag+Vector2(0,48),Color("58432d"),2,true)
		c.draw_colored_polygon(PackedVector2Array([flag,flag+Vector2(24,3),flag+Vector2(21,16),flag+Vector2(0,12)]),Color("873d3a"))
	for i in 12:
		var p := Layout.point(i*0.78-0.5,offset.y+4.12)+Vector2(0,12)
		c.draw_line(p,p+Vector2(10,3),Color(0.74,0.85,0.78,0.15+sin(time*1.5+i)*0.05),1,true)
func draw_cannon(p: Vector2,port: bool) -> void:
	var direction := Vector2(0.85,-0.43) if port else Vector2(-0.85,0.43)
	c.draw_circle(p+Vector2(0,2),7,Color(0.1,0.1,0.07,0.3))
	c.draw_line(p-direction*7,p+direction*13,Color("293937"),6,true)
	c.draw_line(p-direction*7+Vector2(0,3),p+direction*4+Vector2(0,3),Color("6b4c30"),4,true)
	c.draw_circle(p+Vector2(-4,4),3,Color("473d2c")); c.draw_circle(p+Vector2(6,4),3,Color("473d2c"))
func draw_mast(p: Vector2,friendly: bool,time: float) -> void:
	c.draw_circle(p,12,Color(0.12,0.12,0.07,0.3))
	c.draw_circle(p,8,Color("695034")); c.draw_line(p,p-Vector2(0,89),Color("59452f"),6,true)
	c.draw_line(p-Vector2(25,74),p+Vector2(29,-48),Color("71563a"),4,true)
	c.draw_line(p-Vector2(23,70),p+Vector2(26,-50),Color("c9bea0"),7,true)
	for i in 7:
		var q := (p-Vector2(23,70)).lerp(p+Vector2(26,-50),i/6.0)
		c.draw_line(q-Vector2(0,3),q+Vector2(0,4),Color("746b51"),1,true)
	if friendly:
		var top := p-Vector2(0,89)
		c.draw_colored_polygon(PackedVector2Array([top,top+Vector2(24,2+sin(time)*1.5),top+Vector2(22,13),top+Vector2(0,11)]),Color("d7ccab"))
		c.draw_line(top+Vector2(10,2),top+Vector2(10,11),Color("984339"),2,true)
		c.draw_line(top+Vector2(5,6),top+Vector2(16,6),Color("984339"),2,true)
func draw_obstacle(_encounter: String,cell: Vector2i,_deck: bool = false) -> void:
	var p := Board.screen(cell)
	if cell==Vector2i(4,0): draw_mast(p,false,0); return
	c.draw_colored_polygon(PackedVector2Array([p+Vector2(-20,-16),p+Vector2(0,-27),p+Vector2(20,-16),p+Vector2(0,-5)]),Color("b99d73"))
	c.draw_colored_polygon(PackedVector2Array([p+Vector2(-20,-16),p+Vector2(0,-5),p+Vector2(0,12),p+Vector2(-20,1)]),Color("705637"))
	c.draw_colored_polygon(PackedVector2Array([p+Vector2(0,-5),p+Vector2(20,-16),p+Vector2(20,1),p+Vector2(0,12)]),Color("8a6b46"))
	c.draw_line(p+Vector2(-16,-12),p+Vector2(-4,7),Color("b3976c"),2,true)
	c.draw_line(p+Vector2(5,6),p+Vector2(16,-12),Color("b3976c"),2,true)
