extends RefCounted
## Continuous illustrated ground and scenery; never owns collision or combat state.
const ORIGIN:=Vector2(590,108)
const TILE:=Vector2(37,18)
const Motifs=preload("res://scripts/combat/mar_de_ferro/maritime_motifs.gd")
const THEMES:={
	"bruma":{"floor":"paving","tint":Color("aebfc0"),"props":["crate","barrel"],"edge":"house_teal"},
	"cove":{"floor":"grass","tint":Color("b6b6a3"),"props":["rocks","crate"],"edge":"tree"},
	"lisbon":{"floor":"paving","tint":Color("d1cbb8"),"props":["crate","barrel"],"edge":"house_limestone"},
	"douro":{"floor":"grass","tint":Color("a4b6a0"),"props":["rocks","barrel"],"edge":"tree"},
	"monastery":{"floor":"masonry","tint":Color("bcc2bc"),"props":["pillar","crate"],"edge":"chapel"},
	"ceuta":{"floor":"paving","tint":Color("dfc5a0"),"props":["crate","barrel"],"edge":"ceuta-house"},
	"coast":{"floor":"grass","tint":Color("c3b390"),"props":["rocks","crate"],"edge":"rocks"},
	"refuge":{"floor":"masonry","tint":Color("a9bcb5"),"props":["pillar","rocks"],"edge":"chapel"},
	"deck":{"floor":"deck","tint":Color("adb9bb"),"props":["barrel","crate"],"edge":"deckhouse"},
	"prologue":{"floor":"deck","tint":Color("72818d"),"props":["barrel","crate"],"edge":"deckhouse"}
}
var c: Node2D
var materials: Dictionary={}
var props: Dictionary={}
const BRUMA_PERIOD:=Vector2(180,135)
var shadow: Texture2D

static func theme_for(encounter: String) -> String:
	if encounter=="prologue_raid": return "prologue"
	if encounter in ["refuge_trial","refuge_threat"]: return "refuge"
	if encounter in ["cargo_boarding","cargo_return"]: return "deck"
	if encounter=="cargo_signals": return "coast"
	if encounter.begins_with("storm_") or encounter.begins_with("final_"): return "deck"
	if encounter.begins_with("cove_"): return "cove"
	if encounter.begins_with("lisbon_"): return "lisbon"
	if encounter.begins_with("douro_"): return "douro"
	if encounter.begins_with("ceuta_"): return "ceuta"
	if encounter.begins_with("coast_"): return "coast"
	if encounter in ["saint_roman","stronghold","vigia_sentinel","vigia_guard"]: return "monastery"
	return "bruma"

func setup(canvas: Node2D) -> void:
	c=canvas; shadow=c.art.contact_shadow
	var source: Dictionary=c.art.regional.assets
	for key in ["paving","grass","masonry","deck"]: materials[key]=source[key]
	materials.bruma_paving=c.art.bruma.terrain.textures.paving
	materials.bruma_bank=c.art.bruma.terrain.textures.bank
	props.bruma_house=c.art.bruma.world_assets.house_teal
	props.bruma_workshop=c.art.bruma.world_assets.workshop
	props.bruma_warehouse=c.art.bruma.world_assets.warehouse
	for key in ["crate","barrel","pillar","rocks","tree","house_teal","house_limestone","chapel","ceuta-house","deckhouse","boat"]:
		var texture: Texture2D=source[key]
		if texture is CanvasTexture:
			var cropped:=AtlasTexture.new()
			cropped.atlas=texture; cropped.region=Rect2(texture.diffuse_texture.get_image().get_used_rect()); cropped.filter_clip=true
			props[key]=cropped
		else: props[key]=texture

static func project(cell: Vector2) -> Vector2:
	return ORIGIN+Vector2((cell.x-cell.y)*TILE.x,(cell.x+cell.y)*TILE.y)

static func ground_uv(point: Vector2, scale:=4.0) -> Vector2:
	var p:=point-ORIGIN
	return Vector2((p.x/TILE.x+p.y/TILE.y)*0.5,(p.y/TILE.y-p.x/TILE.x)*0.5)/scale

func surface(points: PackedVector2Array, material: String, tint: Color, scale:=4.0) -> void:
	var uv:=PackedVector2Array()
	for point in points: uv.append(point/BRUMA_PERIOD if material=="bruma_paving" else ground_uv(point,scale))
	c.draw_polygon(points,PackedColorArray([tint]),uv,materials[material])

func ground_quad(a: Vector2, b: Vector2) -> PackedVector2Array:
	return PackedVector2Array([project(a),project(Vector2(b.x,a.y)),project(b),project(Vector2(a.x,b.y))])

func draw_ground(encounter: String, time_s:=0.0, reduced_fx:=false) -> void:
	var theme_id:=theme_for(encounter)
	var theme: Dictionary=THEMES[theme_id].duplicate()
	if theme_id=="bruma":
		theme.floor="bruma_paving"; theme.tint=Color("d9dfd4")
		theme.edge="bruma_workshop" if encounter=="training" else ("bruma_warehouse" if encounter=="boss" else "bruma_house")
	var shore: bool=theme_id in ["bruma","cove","douro","coast","deck","prologue"]
	# One UV plane continues beneath every playable cell and beyond the grid.
	# There is no raised slab, checkerboard or independent per-cell texture.
	var land:=ground_quad(Vector2(-24,-24),Vector2(10.7 if shore else 28.0,28))
	if shore:
		c.art.regional.water(0.0 if reduced_fx else time_s,Rect2(0,0,960,540),theme_id in ["deck","prologue"])
	surface(land,theme.floor,theme.tint,3.0 if theme.floor in ["paving","masonry"] else 4.0)
	if theme_id=="refuge":
		Motifs.rose(c,project(Vector2(4,3.5)),143,Color(0.84,0.83,0.65,0.23),0.49)
	if shore:
		var a:=project(Vector2(10.7,-24)); var b:=project(Vector2(10.7,28))
		if theme_id=="bruma": draw_bruma_bank(a,b)
		else:
			c.draw_polyline(PackedVector2Array([a+Vector2(0,4),b+Vector2(0,4)]),Color("26313a") if theme_id=="prologue" else Color("364c4a"),8,true)
			c.draw_line(a,b,Color("717c82") if theme_id=="prologue" else (Color("aaa181") if theme_id=="deck" else Color("939982")),3,true)
	if theme.floor=="grass":
		# An irregular stone track joins the surrounding terrain without changing costs.
		var top:=PackedVector2Array(); var bottom:=PackedVector2Array()
		for x in range(-12,12 if shore else 22):
			var edge_x: float=minf(x,10.7) if shore else float(x)
			top.append(project(Vector2(edge_x,1.6+sin(x*1.7)*0.18)))
			bottom.append(project(Vector2(edge_x,5.8+cos(x*1.3)*0.18)))
		var road:=top.duplicate()
		for i in range(bottom.size()-1,-1,-1): road.append(bottom[i])
		surface(road,"paving",Color(theme.tint,0.73),4.0)
		for line in [top,bottom]:
			for i in range(line.size()-1):
				var outward:=Vector2(7,-4) if line==top else Vector2(-7,4)
				var quad:=PackedVector2Array([line[i],line[i+1],line[i+1]+outward,line[i]+outward])
				var uv:=PackedVector2Array()
				for p in quad: uv.append(ground_uv(p))
				c.draw_polygon(quad,PackedColorArray([Color(theme.tint,0.73),Color(theme.tint,0.73),Color(theme.tint,0),Color(theme.tint,0)]),uv,materials.paving)
	# Peripheral shade shares the ground plane; the play boundary is only an inlay.
	var border:=ground_quad(Vector2(-0.5,-0.5),Vector2(8.5,7.5))
	var outside:=ground_quad(Vector2(-14,-14),Vector2(23,22))
	for i in 4:
		var next: int=(i+1)%4
		c.draw_polygon(PackedVector2Array([border[i],border[next],outside[next],outside[i]]),PackedColorArray([Color(0.03,0.09,0.10,0.14),Color(0.03,0.09,0.10,0.14),Color(0.03,0.09,0.10,0.58),Color(0.03,0.09,0.10,0.58)]))
	var edge:=border.duplicate(); edge.append(edge[0])
	c.draw_polyline(edge,Color(0.08,0.13,0.13,0.38),2,true)
	c.draw_polyline(edge,Color(0.83,0.84,0.72,0.26),1,true)
	for corner in border: c.draw_circle(corner,2,Color("a49e7e"))
	# Dressing remains entirely outside the walkable footprint.
	var key: String=theme.edge
	sprite(key,project(Vector2(3,-3)),Vector2(180,146),Color("9ea7a3"))
	sprite(key,project(Vector2(9.8,-1.5)),Vector2(166,139),Color("a5afa8"))
	sprite("barrel" if theme.floor=="deck" else "rocks",project(Vector2(-2,4)),Vector2(72,51),Color("a7b3ad"))
	sprite("crate" if theme.floor=="deck" else "rocks",project(Vector2(7,10)),Vector2(94,56),Color("9aa8a3"))
	if theme.floor=="deck":
		# Gunwale outside the arena, running on the same axes as the deck planks.
		for y in range(-2,12,2):
			var foot:=project(Vector2(10.5,y))
			c.draw_line(foot,foot+Vector2(0,-24),Color("514a3c"),5,true)
			if y<10: c.draw_line(foot+Vector2(0,-19),project(Vector2(10.5,y+2))+Vector2(0,-19),Color("a48e65"),2,true)
		if theme_id=="prologue": draw_prologue_details(time_s,reduced_fx)

func draw_bruma_bank(a: Vector2,b: Vector2) -> void:
	# Same dry stone, damp strip and submerged footing as Bruma exploration.
	var depth:=PackedFloat32Array([0,30,38,50])
	var colors:=PackedColorArray([Color("b8b69c"),Color("818c74"),Color(.27,.48,.43,.88),Color(.20,.47,.48,0)])
	var length:=a.distance_to(b)/132.0
	for stage in 3:
		var upper:=Vector2(stage,depth[stage]); var lower:=Vector2(stage+1,depth[stage+1])
		var points:=PackedVector2Array([a+upper,b+upper,b+lower,a+lower])
		var uv:=PackedVector2Array([Vector2(0,depth[stage]/38),Vector2(length,depth[stage]/38),Vector2(length,depth[stage+1]/38),Vector2(0,depth[stage+1]/38)])
		c.draw_polygon(points,PackedColorArray([colors[stage],colors[stage],colors[stage+1],colors[stage+1]]),uv,materials.bruma_bank)
	c.draw_line(a,b,Color("d6d0b9"),3,true)

func draw_prologue_details(time_s: float, reduced_fx: bool) -> void:
	# Night sea remains visible around the ship; the playfield itself stays one continuous deck.
	var motion:=0.0 if reduced_fx else time_s
	for i in 17:
		var x:=posmod(i*83+int(motion*18.0),960)
		var y:=12+(i*29)%66
		c.draw_line(Vector2(x,y),Vector2(x+18+(i%4)*5,y+1),Color(0.49,0.68,0.78,0.22),1.5,true)
	# Rigging and a clipped, damaged sail sit beyond the rear edge of the playable deck.
	var mast_x:=861.0
	var mast_y:=project(Vector2(5.7,-4.4)).y+10
	c.draw_line(Vector2(mast_x,mast_y),Vector2(mast_x+5,16),Color("282f36"),9,true)
	c.draw_line(Vector2(mast_x-2,mast_y-34),Vector2(mast_x+5,21),Color("9a896c"),3,true)
	var sail:=PackedVector2Array([Vector2(mast_x+8,28),Vector2(mast_x+112,91),Vector2(mast_x+14,99)])
	c.draw_colored_polygon(sail,Color("817665",0.84))
	c.draw_line(Vector2(mast_x+13,39),Vector2(mast_x+106,88),Color("b4a78d",0.62),2,true)
	c.draw_line(Vector2(mast_x+18,50),Vector2(mast_x+31,90),Color("554f48",0.72),2,true)
	# Rain catches the light only around the perimeter, leaving cell markers crisp.
	for i in 24:
		var x:=posmod(i*127+int(motion*34.0),960)
		var y:=76+(i*47)%370
		if x<265 or x>945:
			c.draw_line(Vector2(x,y),Vector2(x-3,y+10),Color(0.71,0.81,0.87,0.26),1,true)

func sprite(key: String, foot: Vector2, bounds: Vector2, tint:=Color.WHITE) -> void:
	var texture: Texture2D=props[key]
	var native:=texture.get_size()
	var shown:=native*minf(bounds.x/native.x,bounds.y/native.y)
	c.draw_texture_rect(shadow,Rect2(foot-Vector2(shown.x*0.58,8),Vector2(shown.x*1.16,15)),false)
	c.draw_texture_rect(texture,Rect2(foot-Vector2(shown.x*0.5,shown.y),shown),false,tint)

func obstacle_key(encounter: String, cell: Vector2i) -> String:
	if encounter=="boss": return "pillar"
	var variants: Array=THEMES[theme_for(encounter)].props
	return variants[posmod(cell.x*13+cell.y*7+int(cell.y/2),variants.size())]

func draw_obstacle(encounter: String, cell: Vector2i, broken_deck:=false) -> void:
	var p:=project(cell)
	if broken_deck:
		for i in 3:
			var start:=p+Vector2(-23+i*5,-9+i*7)
			var points:=PackedVector2Array([start,start+Vector2(37,-6+i*3),start+Vector2(41,1+i*3),start+Vector2(2,7)])
			c.draw_polyline(PackedVector2Array([points[3]+Vector2(0,2),points[2]+Vector2(0,2)]),Color("342b26"),3,true)
			surface(points,"deck",Color("b8b2a0"),2.0)
		return
	var key:=obstacle_key(encounter,cell)
	var size: Vector2={"crate":Vector2(46,46),"barrel":Vector2(36,47),"pillar":Vector2(40,65),"rocks":Vector2(59,39)}[key]
	sprite(key,p+Vector2(0,9),size)

