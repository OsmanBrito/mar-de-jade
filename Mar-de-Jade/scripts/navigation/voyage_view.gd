extends Node2D
const People = preload("res://scripts/npcs/lisbon_npc_library.gd")
const Actor = preload("res://scripts/combat/portugal_actor_art.gd")
const PAPER := Color("ece1bf")
const GOLD := Color("d7b67b")
const JADE := Color("87c5ae")
const RED := Color("ec9a83")
var game
var scenery = preload("res://scripts/combat/portugal_arena.gd").new()
var boat_texture: Texture2D
var font: Font
var chart_rect := Rect2(100,166,900,610)
var contact_rect := Rect2(34,139,395,80)
var insets: Dictionary = {}

func _ready() -> void:
	font = ThemeDB.fallback_font
	scenery.setup(self)
	boat_texture = load("res://assets/art/living-quay/caravela-clean-v2.png")
func text(value: String,at: Vector2,size: int = 16,color: Color = PAPER) -> void:
	draw_string(font,at+Vector2(1,2),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color(0.01,0.04,0.05,0.65))
	draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func center(value: String,at: Vector2,size: int = 16,color: Color = PAPER) -> void:
	text(value,at-Vector2(font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*0.5,0),size,color)
func poly(points: Array,color: Color) -> void:
	var values := PackedVector2Array()
	for p in points: values.append(p if p is Vector2 else Vector2(p[0],p[1]))
	draw_colored_polygon(values,color)
func world_offset() -> Vector2: return game.get_viewport_rect().size*Vector2(0.5,0.52)-game.model.position*game.zoom
func to_world(at: Vector2) -> Vector2:
	if game.perspective!=null and game.perspective.visible: return game.perspective.sea_point(at)
	return (at-world_offset())/game.zoom
func sea_screen(at: Vector2) -> Vector2:
	if game.perspective!=null and game.perspective.visible: return game.perspective.screen_point(at)
	return world_offset()+at*game.zoom
func sea_direction(at: Vector2) -> Vector2:
	if game.perspective!=null and game.perspective.visible: return game.perspective.relative_direction(at)
	return (at-game.model.position).normalized()
func chart_scale() -> float: return minf(chart_rect.size.x/36000.0,chart_rect.size.y/29000.0)
func chart_origin() -> Vector2: return chart_rect.get_center()-Vector2(36000,29000)*chart_scale()*0.5
func chart_world(at: Vector2) -> Vector2: return (at-chart_origin())/chart_scale()

func _draw() -> void:
	if game==null or game.model==null: return
	match game.model.phase:
		"sea","game_over": draw_sea()
		"naval","naval_result": draw_naval()
		"deck","port","island": draw_stage()
	if game.overlay=="chart": draw_chart()

func draw_land(small: bool = false) -> void:
	var model = game.model
	for island in model.chart.land:
		if small and island.name=="Desertas" and not model.discovered.has("desertas"): continue
		var points := PackedVector2Array()
		var middle := Vector2.ZERO
		for p in island.points:
			var at: Vector2 = model.point(p)
			if small: at = at.clamp(Vector2.ZERO,Vector2(36000,29000))
			points.append(at); middle += at
		middle /= points.size()
		var border := points.duplicate(); border.append(points[0])
		draw_polyline(border,Color("285f61") if not small else Color("517a75"),180 if not small else 90,true)
		if not small:
			draw_polyline(border,Color("3e8079"),105,true)
			draw_polyline(border,Color("8db6a1"),49,true)
			draw_polyline(border,Color("d4d3b0"),12,true)
		draw_colored_polygon(points,Color(island.color))
		var inside := PackedVector2Array()
		if small:
			for p in points: inside.append(p.lerp(middle,0.16))
		else:
			if not insets.has(island.name):
				var rings := Geometry2D.offset_polygon(points,-85)
				insets[island.name] = rings[0] if not rings.is_empty() else points
			inside = insets[island.name]
		draw_colored_polygon(inside,Color("647d59") if island.name in ["Portugal","Madeira"] else Color("a29b6d"))
		if small: continue
		# Land texture is anchored in the world, with trees only in the camera area.
		var view := Rect2(model.position-Vector2(1000,700)/game.zoom,Vector2(2000,1400)/game.zoom)
		for x in range(int(view.position.x/120)*120,int(view.end.x)+120,120):
			for y in range(int(view.position.y/100)*100,int(view.end.y)+100,100):
				var p := Vector2(x+sin(y*0.047+x)*39,y+cos(x*0.018)*30)
				if Geometry2D.is_point_in_polygon(p,inside):
					var pattern := sin(x*0.036+y*0.025)
					draw_line(p,p+Vector2(13,-5),Color("8c9b6e"),1.5,true)
					if pattern>0.1 and island.name in ["Portugal","Madeira"]:
						draw_circle(p+Vector2(8,7),18,Color(0.13,0.22,0.15,0.3))
						draw_line(p,p+Vector2(0,-16),Color("69553d"),4,true)
						draw_circle(p+Vector2(0,-19),16,Color("435f49")); draw_circle(p+Vector2(-5,-25),12,Color("7b9563")); draw_circle(p+Vector2(6,-27),8,Color("9ca878"))
					elif pattern< -0.5:
						poly([p+Vector2(-8,5),p+Vector2(-5,-8),p+Vector2(8,-5),p+Vector2(11,4)],Color("a2a184"))
		if island.name=="Portugal":
			for at in [Vector2(30170,3820),Vector2(30280,4050),Vector2(30330,3690)]:
				if at.distance_to(model.position)<1400: scenery.prop("buildings",0 if at.y<3900 else 2,at,110)

func ship(at: Vector2,angle: float,size: float = 1.0,tint: Color = Color.WHITE,time: float = 0,speed: float = 0) -> void:
	draw_set_transform(at+Vector2(0,sin(time*1.7)*0.8),angle,Vector2.ONE*size)
	if speed>1:
		var strength := clampf(speed/52.0,0.15,1.0)
		for i in 7:
			var k := fmod(time*(14+speed*0.12)+i*13,91.0)
			var alpha := (1-k/91.0)*0.35*strength
			draw_polyline(PackedVector2Array([Vector2(-43-k,-13-k*0.14),Vector2(-58-k,-4),Vector2(-43-k,13+k*0.14)]),Color(0.6,0.85,0.79,alpha),1.4,true)
		for side in [-1,1]: draw_arc(Vector2(36,side*4),17,-1.2 if side<0 else 0.2,0.1 if side<0 else 1.5,14,Color(0.7,0.9,0.84,0.4*strength),1.5,true)
	poly([[-49,7],[-45,-10],[-29,-20],[7,-21],[37,-12],[59,4],[37,20],[7,27],[-29,25],[-45,17]],Color(0,0.025,0.035,0.42))
	poly([[-48,0],[-42,-14],[-25,-19],[9,-18],[36,-10],[56,0],[36,10],[9,18],[-25,19],[-42,14]],Color("49372c")*tint)
	poly([[-43,0],[-37,-11],[-23,-15],[8,-14],[33,-8],[48,0],[33,8],[8,14],[-23,15],[-37,11]],Color("bf9b68")*tint)
	for x in range(-36,35,7): draw_line(Vector2(x,-11),Vector2(x,11),Color("967247"),0.8,true)
	poly([[-43,-10],[-29,-13],[-29,13],[-43,10]],Color("8d643e")*tint)
	draw_line(Vector2(-43,-10),Vector2(-29,-13),Color("e3c794"),1.5,true)
	draw_line(Vector2(-47,0),Vector2(65,0),Color("624a30"),2,true)
	for x in [-21,8,31]:
		var length := 26.0 if x!=31 else 18.0
		var billow := 10.0+sin(time*2.0+x)*0.8+clampf(speed/52.0,0,1)*2
		draw_line(Vector2(x,-length-2),Vector2(x,length+2),Color("483b2c"),2,true)
		draw_line(Vector2(x-3,-length),Vector2(x-20,0),Color(0.2,0.17,0.12,0.6),0.7,true)
		draw_line(Vector2(x-3,length),Vector2(x-20,0),Color(0.2,0.17,0.12,0.6),0.7,true)
		poly([Vector2(x+2,-length+2),Vector2(x+billow,-length*0.6),Vector2(x+billow+3,0),Vector2(x+billow,length*0.6),Vector2(x+2,length-2)],Color("c2b28d")*tint)
		poly([Vector2(x,-length),Vector2(x+billow-1,-length*0.6),Vector2(x+billow+1,0),Vector2(x+billow-1,length*0.6),Vector2(x,length)],Color("ece0be")*tint)
		for side in [-0.5,0.0,0.5]:
			draw_line(Vector2(x+1,length*side),Vector2(x+billow+1,length*side*0.83),Color("c7bc99")*tint,0.8,true)
		draw_polyline(PackedVector2Array([Vector2(x,-length),Vector2(x+billow+1,0),Vector2(x,length)]),Color("fff2d0")*tint,1,true)
	for y in [-1,1]:
		for x in [-14,0,14]: draw_line(Vector2(x,y*11),Vector2(x,y*18),Color("303b39"),3,true)
	poly([[-39,-10],[-43,-28],[-31,-23],[-38,-19]],Color("719d9a")*tint)
	draw_set_transform(Vector2.ZERO)

func bird(at: Vector2,index: int,time: float,direction: Vector2 = Vector2.LEFT) -> void:
	var spread := 4+absf(sin(time*4.1+index))*5
	var across := direction.orthogonal()
	var tip := direction*3
	draw_polyline(PackedVector2Array([at+across*spread-tip,at+tip,at-across*spread-tip]),Color(0.8,0.86,0.76,0.78),1.5,true)
func draw_signals() -> void:
	var m = game.model
	for sign_info in m.chart.get("signals",[]):
		if m.resolved.has(sign_info.leads_to): continue
		var at: Vector2 = m.point(sign_info.pos)
		if at.distance_to(m.position)>1700: continue
		var toward: Vector2 = (m.point(m.place(sign_info.leads_to).pos)-at).normalized()
		match sign_info.kind:
			"birds":
				for i in 7:
					var p := at+toward*fmod(game.clock*11+i*44,310)+toward.orthogonal()*(sin(i*2.1)*90+sin(game.clock*0.5+i)*17)
					bird(p,i,game.clock,toward)
			"drift":
				for i in 9:
					var p := at+toward*(i*58-150)+toward.orthogonal()*sin(i*2.7)*50
					draw_line(p,p+toward.rotated(sin(i)*0.7)*(9+i%4*4),Color("a39068"),3,true)
			"current":
				for i in 12:
					var p := at+toward*(fmod(game.clock*9+i*47,500)-250)+toward.orthogonal()*sin(i*1.2)*80
					draw_line(p,p+toward*35,Color(0.44,0.72,0.65,0.22),1.5,true)

func draw_sea() -> void:
	if game.perspective!=null and game.perspective.visible:
		draw_horizon_hud(); return
	var m = game.model
	draw_set_transform(world_offset(),0,Vector2.ONE*game.zoom)
	draw_land()
	draw_signals()
	if game.waypoint!=Vector2.ZERO:
		draw_arc(game.waypoint,35,0,TAU,40,Color(GOLD,0.8),2,true)
		draw_line(game.waypoint-Vector2(0,22),game.waypoint+Vector2(0,22),GOLD,2,true)
	for entry in m.chart.places:
		if m.resolved.has(entry.id) and entry.kind not in ["port","island","landmark"]: continue
		var at: Vector2 = m.place_position(entry)
		if at.distance_to(m.position)>1300/game.zoom: continue
		var color := RED if entry.kind in ["hostile","boss"] else GOLD
		if entry.kind in ["hostile","boss","merchant","fisher"]:
			draw_set_transform(Vector2.ZERO)
			ship(world_offset()+at*game.zoom,2.4+sin(m.elapsed*0.02)*0.3,game.zoom*(1.35 if entry.kind=="boss" else 0.85),Color("cda99a") if entry.kind in ["hostile","boss"] else Color("dbd9bf"),game.clock,15)
			draw_set_transform(world_offset(),0,Vector2.ONE*game.zoom)
		else:
			if entry.kind in ["port","island"]:
				if entry.id=="lisboa":
					poly([at+Vector2(55,35),at+Vector2(520,35),at+Vector2(520,69),at+Vector2(55,69)],Color("9c825c"))
					for x in range(65,520,24): draw_line(at+Vector2(x,35),at+Vector2(x,69),Color("66553e"),1,true)
				poly([at+Vector2(-30,-7),at+Vector2(30,-7),at+Vector2(30,9),at+Vector2(-30,9)],Color("ad8c61"))
				for i in [-1,1]: draw_circle(at+Vector2(i*26,0),3,Color("4e3e2d"))
			elif entry.kind=="landmark":
				for i in 5: draw_arc(at+Vector2(i*17-34,sin(game.clock+i)*9),20,0.2,1.8,12,Color(JADE,0.5),2,true)
				if entry.id=="current_2":
					for i in 5: bird(at+Vector2(sin(game.clock*0.3+i)*85,cos(game.clock*0.3+i)*42-20),i,game.clock)
				if entry.id=="current_3":
					for i in 3: poly([at+Vector2(i*25-35,8),at+Vector2(i*25-28,-8-i*4),at+Vector2(i*25-13,5)],Color("9b9c83"))
			elif entry.kind=="rescue":
				draw_line(at-Vector2(22,0),at+Vector2(22,0),Color("af946a"),7,true); draw_circle(at-Vector2(0,9),5,Color("d4b68a"))
			else:
				for i in 3:
					var off := Vector2(i*14-16,sin(i*3)*12)
					draw_rect(Rect2(at+off,Vector2(16,13)),Color("9e8051")); draw_line(at+off,at+off+Vector2(16,13),Color("d6b882"),1,true)
		if m.discovered.has(entry.id):
			center(entry.name,at+Vector2(0,-55 if entry.kind=="boss" else -39),13,color)
			if entry.kind in ["hostile","boss"] and at.distance_to(m.position)<(1500 if entry.kind=="boss" else 2000):
				center("ENCONTRO HOSTIL",at+Vector2(0,48),10,RED)
	draw_set_transform(Vector2.ZERO)
	ship(world_offset()+m.position*game.zoom,m.heading,game.zoom*1.2,Color.WHITE,game.clock,m.velocity.length())
	if m.danger>0: draw_danger()
	else: draw_contact_guide()
	# Compass points to the destination even when the coastline is outside view.
	var target: Vector2 = m.point(m.place("madeira").pos) if not m.made_landfall else m.point(m.place("lisboa").pos)
	if game.waypoint!=Vector2.ZERO: target = game.waypoint
	var direction: Vector2 = (target-m.position).normalized()
	var marker := Vector2(720,468)+direction*240
	if m.danger<=0:
		poly([marker+direction*13,marker-direction*5+direction.orthogonal()*6,marker-direction*5-direction.orthogonal()*6],GOLD)
		center("APROXIMAÇÃO" if not game.focus_id.is_empty() else ("RUMO MARCADO" if game.waypoint!=Vector2.ZERO else ("MADEIRA" if not m.made_landfall else "LISBOA")),marker+Vector2(0,30),11,GOLD)
	draw_compass()

func draw_horizon_hud() -> void:
	var m = game.model
	for entry in m.chart.places:
		if m.resolved.has(entry.id) and entry.kind not in ["port","island","landmark"]: continue
		if m.discovered.get(entry.id,"") not in ["sighted","explored"]: continue
		var distance: float = m.position.distance_to(m.place_position(entry))
		if distance>2300: continue
		var at := sea_screen(m.place_position(entry))
		if Rect2(70,260,1190,430).has_point(at):
			center(entry.name,at+Vector2(0,-43),14,RED if entry.kind in ["hostile","boss"] else PAPER)
			if distance<190 and tracked_contact().get("id","")!=entry.id: center("E / A · interagir",at+Vector2(0,26),13,JADE)
	if m.danger>0: draw_danger()
	else: draw_contact_guide()
	var destination: Vector2 = game.waypoint if game.waypoint!=Vector2.ZERO else m.point(m.place("madeira" if not m.made_landfall else "lisboa").pos)
	var dir := sea_direction(destination)
	var at := Vector2(720,550)+dir*165
	if m.danger<=0:
		poly([at+dir*12,at-dir*5+dir.orthogonal()*6,at-dir*5-dir.orthogonal()*6],GOLD)
		center("PILOTO · RUMO MARCADO" if game.waypoint!=Vector2.ZERO else ("MADEIRA" if not m.made_landfall else "LISBOA"),at+Vector2(0,28),11,GOLD)
	draw_compass()
	draw_style_box(game.box(Color(0.035,0.12,0.14,0.9),Color(GOLD,0.4)),Rect2(34,630,245,77))
	text("VELAS · "+game.sail_name().to_upper(),Vector2(49,653),15,GOLD)
	for i in 3: draw_rect(Rect2(49+i*29,665,23,9),JADE if i<game.sail_level else Color("34565a"))
	text("W ↑  S ↓    A/D leme",Vector2(49,696),13,PAPER)

func tracked_contact() -> Dictionary:
	var m = game.model
	if not game.focus_id.is_empty():
		var entry: Dictionary = m.place(game.focus_id)
		if not entry.is_empty() and not m.resolved.has(entry.id): return entry
	var entry: Dictionary = m.contact()
	if entry.get("id","")=="lisboa" and m.elapsed<30: return {}
	return entry
func draw_contact_guide() -> void:
	var entry := tracked_contact()
	if entry.is_empty(): return
	var m = game.model
	var at: Vector2 = sea_screen(m.place_position(entry))
	var color := RED if entry.kind in ["hostile","boss"] else JADE
	draw_style_box(game.box(Color(0.035,0.12,0.14,0.93),Color(color,0.65)),contact_rect)
	text("VELA HOSTIL" if entry.kind in ["hostile","boss"] else "AVISTAMENTO",contact_rect.position+Vector2(15,22),11,color)
	var title: String = entry.name
	if title.length()>37: title = title.left(35)+"…"
	text(title,contact_rect.position+Vector2(15,46),17,PAPER)
	text("Clica aqui para aproximar · V retoma o rumo",contact_rect.position+Vector2(15,66),12,Color("a9c3b5"))
	var bounds := Rect2(85,240,1270,420)
	if bounds.has_point(at):
		draw_arc(at,53+sin(game.clock*2)*2,0.2,TAU-0.2,48,Color(color,0.7),1.5,true)
		center("E / A · interagir" if m.position.distance_to(m.place_position(entry))<190 else "Clique para aproximar",at+Vector2(0,78),12,color)
	else:
		var center_ship := Vector2(720,550)
		var dir := sea_direction(m.place_position(entry))
		var arrow: Vector2 = (center_ship+dir*310).clamp(bounds.position,bounds.end)
		poly([arrow+dir*10,arrow-dir*5+dir.orthogonal()*5,arrow-dir*5-dir.orthogonal()*5],color)
		center("À VISTA",arrow+Vector2(0,25),11,color)
func draw_danger() -> void:
	var m = game.model
	var color := GOLD if m.danger<55 else RED
	var panel := Rect2(465,132,510,91)
	draw_style_box(game.box(Color(0.06,0.12,0.14,0.96),color),panel)
	text("MAR PESADO · CAPACIDADE DA BOTAFOGO",panel.position+Vector2(17,24),14,color)
	text("Segue a seta verde ou usa V para marcar a retirada.",panel.position+Vector2(17,48),15,PAPER)
	draw_rect(Rect2(panel.position+Vector2(17,64),Vector2(475,7)),Color("243c40"))
	draw_rect(Rect2(panel.position+Vector2(17,64),Vector2(475*m.danger/100.0,7)),color)
	var target: Vector2 = m.safety_target()
	var dir := sea_direction(target)
	if dir.length()>0.01:
		var arrow: Vector2 = Vector2(720,550)+dir*160
		poly([arrow+dir*18,arrow-dir*8+dir.orthogonal()*10,arrow-dir*8-dir.orthogonal()*10],JADE)
		center("ÁGUAS SEGURAS",arrow+Vector2(0,37),14,JADE)
	else: center("Mantém o rumo seguro até o mar acalmar.",Vector2(720,261),16,JADE)
	var opacity: float = 0.08+0.2*m.danger/100.0
	draw_rect(Rect2(0,115,8,673),Color(color,opacity)); draw_rect(Rect2(1432,115,8,673),Color(color,opacity))

func draw_compass() -> void:
	var at := Vector2(1348,202)
	draw_style_box(game.box(Color(0.025,0.09,0.11,0.9),Color(0.38,0.51,0.44,0.45)),Rect2(1265,131,162,180))
	draw_circle(at,40,Color(0.025,0.09,0.11,0.8)); draw_arc(at,36,0,TAU,60,Color(GOLD,0.65),1,true)
	for i in 4:
		var dir := Vector2.from_angle(i*PI*0.5-PI*0.5)
		draw_line(at+dir*24,at+dir*34,GOLD,1,true)
	if game.perspective==null or not game.perspective.visible: center("N",at+Vector2(0,-44),13,GOLD)
	var wind := Vector2(-0.75,0.65).normalized()
	var rotation := 0.0
	if game.perspective!=null and game.perspective.visible:
		rotation = -game.perspective.camera_heading-PI*0.5
		wind = wind.rotated(rotation)
		# North turns around the ship; up on screen always follows the bow.
		var north := Vector2.UP.rotated(rotation)
		center("N",at+north*49+Vector2(0,4),12,JADE)
	draw_line(at-wind*19,at+wind*19,JADE,2,true)
	poly([at+wind*23,at+wind*9+wind.orthogonal()*5,at+wind*9-wind.orthogonal()*5],JADE)
	var factor: float = game.model.wind_factor(Vector2.from_angle(game.model.heading))
	center("VENTO FAVORÁVEL" if factor>1.02 else ("VENTO CONTRÁRIO" if factor<0.86 else "VENTO LATERAL"),at+Vector2(0,62),10,JADE)
	center(game.sail_name().to_upper(),at+Vector2(0,81),10,GOLD)

func draw_naval() -> void:
	var battle = game.naval
	if battle==null: return
	if battle.retreat:
		draw_circle(Vector2(115,680),85,Color(0.4,0.8,0.7,0.12)); draw_arc(Vector2(115,680),85,0,TAU,50,JADE,2,true)
		center("RETIRADA",Vector2(137,683),13,JADE)
	if battle.warning>0:
		if battle.attack_kind=="charge":
			var dir: Vector2 = (battle.aimed_at-battle.enemy).normalized()
			poly([battle.enemy-dir.orthogonal()*40,battle.enemy+dir.orthogonal()*40,battle.enemy+dir*600+dir.orthogonal()*65,battle.enemy+dir*600-dir.orthogonal()*65],Color(RED,0.2))
			draw_dashed_line(battle.enemy,battle.enemy+dir*600,RED,2,12,true)
		else:
			draw_circle(battle.aimed_at,85,Color(RED,0.12)); draw_arc(battle.aimed_at,85,0,TAU,50,RED,2,true)
			center("IMPACTO",battle.aimed_at+Vector2(0,-90),12,RED)
	for splash in battle.splashes:
		draw_arc(splash.at,25+(1-splash.life)*60,0,TAU,35,Color(PAPER,splash.life*0.6),3,true)
	ship(battle.enemy,battle.enemy_heading,1.45 if battle.boss else 1.15,Color("d6af9e"),game.clock,30)
	ship(battle.player,battle.heading,1.25,Color.WHITE,game.clock,battle.velocity.length())
	for shot in battle.shots: draw_line(shot.from,shot.to,Color(GOLD if shot.friendly else RED,shot.life*2),3,true)
	center(game.current_enemy.name,battle.enemy+Vector2(0,-62),15,RED)
	var bar := Rect2(battle.enemy+Vector2(-70,-53),Vector2(140,5))
	draw_rect(bar,Color("132d35")); bar.size.x *= maxf(0,battle.enemy_hull/battle.enemy_max); draw_rect(bar,RED)
	if battle.vulnerable>0: center("FLANCOS EXPOSTOS",battle.enemy+Vector2(0,66),14,GOLD)
	center("BOTAFOGO",battle.player+Vector2(0,-62),12,JADE)
	for side in 2:
		var dir := Vector2.from_angle(battle.heading).orthogonal()*(1 if side==0 else -1)
		var color := JADE if battle.side_available(side) and battle.reloads[side]<=0 else Color(GOLD,0.25)
		draw_line(battle.player+dir*38,battle.player+dir*95,color,2,true)
		center("E" if side==1 else "Q",battle.player+dir*112+Vector2(0,5),16,color)

func draw_stage() -> void:
	var m = game.model
	var deck: bool = m.phase=="deck"
	draw_rect(Rect2(0,120,1440,670),Color("16444c"))
	if deck:
		poly([[180,450],[270,205],[1100,205],[1280,450],[1100,737],[270,737]],Color("463c30"))
		poly([[210,450],[295,230],[1085,230],[1245,450],[1085,710],[295,710]],Color("b59568"))
		for y in range(245,710,24): draw_line(Vector2(292,y),Vector2(1090,y),Color("866b49"),1,true)
		for x in range(315,1090,92):
			for y in range(260,700,48): draw_line(Vector2(x,y),Vector2(x,y+24),Color("806448"),1,true)
		for at in [Vector2(520,410),Vector2(910,420)]:
			draw_circle(at+Vector2(5,6),27,Color(0.08,0.1,0.07,0.25)); draw_circle(at,17,Color("5f4830")); draw_circle(at-Vector2(3,4),12,Color("997348"))
		for y in [250,690]: draw_line(Vector2(320,y),Vector2(1090,y),Color("dcc6a1"),5,true)
		center("BOTAFOGO · CONVÉS",Vector2(720,185),24,GOLD)
	else:
		poly([[0,220],[1440,220],[1440,670],[1150,745],[0,745]],Color("b8ad89"))
		for x in range(0,1440,42):
			for y in range(320,730,28): draw_line(Vector2(x+(14 if y%56==0 else 0),y),Vector2(x+24,y),Color(0.3,0.3,0.2,0.12),1,true)
		if m.phase=="island":
			poly([[0,220],[160,130],[410,260],[580,145],[820,295],[1030,170],[1440,280],[1440,355],[0,355]],Color("687b71"))
			for i in 12:
				var at := Vector2(130+i*105,315+sin(i*3.5)*18)
				poly([at+Vector2(-30,12),at+Vector2(-15,-28),at+Vector2(20,-17),at+Vector2(34,15)],Color("929a81"))
			for i in 90:
				var at := Vector2(190+fmod(i*139,1050),360+fmod(i*83,340))
				draw_circle(at,2+posmod(i,3),Color("9b9d83"))
			for x in [680,730,780]: draw_line(Vector2(x,420),Vector2(x+9,405),Color("e3d8b6"),3,true)
		else:
			scenery.prop("buildings",0,Vector2(350,325),230)
			scenery.prop("buildings",2,Vector2(735,310),225)
			scenery.prop("buildings",3,Vector2(1090,330),245)
			scenery.prop("details",2,Vector2(390,450),130)
		poly([[1080,600],[1255,600],[1255,660],[1080,660]],Color("957852"))
		for x in range(1090,1255,18): draw_line(Vector2(x,600),Vector2(x,660),Color("6b543d"),1,true)
		var size := Vector2(270,220)
		draw_texture_rect(boat_texture,Rect2(Vector2(1190,555)-size*0.5,size),false)
		center("BOTAFOGO · E para embarcar",Vector2(1135,714),13,GOLD)
	var people: Array = game.stage_people().duplicate(true)
	people.append({"id":"hero","name":m.hero_name,"at":game.walker})
	people.sort_custom(func(a,b): return a.at.y<b.at.y)
	for person in people:
		var at: Vector2 = person.at
		if person.id=="hero": Actor.draw_actor(self,"hero",at,game.walk_facing==1,"walk" if game.walking else "ready",game.walk_clock,"PU",true,0,false,Vector2.RIGHT,1.18)
		else: People.draw_actor(self,person.id,2,false,0,"standing",0.9,at)
		center(person.name,at+Vector2(0,-95),12,GOLD if person.id!="hero" else PAPER)
	var nearby: Dictionary = game.nearby_person()
	if not nearby.is_empty(): center("E / A · "+nearby.name,game.walker+Vector2(0,31),14,JADE)
	if m.phase=="island": center("ENSEADA · procura as marcas junto das pedras",Vector2(720,180),21,GOLD)

func draw_chart() -> void:
	draw_rect(Rect2(0,115,1440,673),Color(0.025,0.07,0.08,0.78))
	draw_rect(Rect2(65,145,1310,650),Color("142f36"))
	draw_rect(chart_rect,Color("345c61"))
	draw_set_transform(chart_origin(),0,Vector2.ONE*chart_scale())
	draw_land(true)
	var m = game.model
	var margin := 1800.0 if m.upgrades.get("hull",false) else 2700.0
	for rect in [Rect2(0,0,margin,29000),Rect2(36000-margin,0,margin,29000),Rect2(margin,0,36000-margin*2,margin),Rect2(margin,29000-margin,36000-margin*2,margin)]:
		draw_rect(rect,Color(0.64,0.4,0.3,0.17))
	var route := PackedVector2Array()
	for p in m.chart.route: route.append(m.point(p))
	for i in range(route.size()-1): draw_dashed_line(route[i],route[i+1],Color(GOLD,0.75),50,250,true)
	if m.route_known:
		var trail := PackedVector2Array([m.point(m.place("current_1").pos),m.point(m.place("current_2").pos),m.point(m.place("current_3").pos)])
		draw_polyline(trail,JADE,90,true)
	draw_set_transform(Vector2.ZERO)
	for entry in m.chart.places:
		if not m.discovered.has(entry.id): continue
		if m.resolved.has(entry.id) and entry.kind not in ["port","island","landmark"]: continue
		var at: Vector2 = chart_origin()+m.point(entry.pos)*chart_scale()
		var rumor: bool = m.discovered[entry.id]=="rumor"
		var color := RED if entry.kind in ["hostile","boss"] else (Color("a9b4a7") if rumor else GOLD)
		if rumor: draw_arc(at,12,0,TAU,24,Color(color,0.6),1,true)
		else: draw_circle(at,4,color)
		text(("? " if rumor else "")+entry.name,at+Vector2(10,-8 if entry.id!="current_3" else 16),12,color)
	var approximate: Vector2 = m.position+Vector2(sin(m.elapsed*0.02),cos(m.elapsed*0.02))*550*(0.4 if m.upgrades.get("cartographer",false) else 1.0)
	var current := chart_origin()+approximate*chart_scale()
	draw_circle(current,19,Color(JADE,0.12)); draw_arc(current,19,0,TAU,36,JADE,1.5,true)
	var dir := Vector2.from_angle(m.heading)
	poly([current+dir*9,current-dir*5+dir.orthogonal()*5,current-dir*5-dir.orthogonal()*5],PAPER)
	if game.waypoint!=Vector2.ZERO:
		var at: Vector2 = chart_origin()+game.waypoint*chart_scale()
		draw_arc(at,9,0,TAU,20,GOLD,2,true)
	text("CARTA DE NAVEGAÇÃO",Vector2(1040,192),23,GOLD)
	text("Lisboa — Madeira",Vector2(1040,225),17)
	var lines := ["Traço dourado: derrota conhecida", "Círculo verde: posição estimada", "?: relato por confirmar", "Faixa ocre: mar além do preparo", "", "Clique no mar: marcar um rumo", "O navio segue enquanto houver", "água livre; mantém a vigilância.", "", "V retoma o rumo após um desvio.", "M / B fecha a carta.", "Marcas das Desertas: %d / 3"%m.route_marks.size()]
	for i in lines.size(): text(lines[i],Vector2(1040,275+i*25),14,JADE if i==11 else PAPER)
	center("N",Vector2(960,197),18,GOLD)
	text("A carta regista o que foi relatado, avistado e explorado. O mar continua por descobrir.",Vector2(105,766),13,PAPER)
