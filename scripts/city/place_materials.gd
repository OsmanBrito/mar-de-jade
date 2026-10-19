extends RefCounted
## Grounded architecture shared by the town and its monastic house.
static var cache: Dictionary = {}
const PAVING_SCALE := 220.0
const EXTERIOR_STONE := Color("d3c8aa")
const INTERIOR_STONE := Color("d0c6a8")
const GRASS_TINT := Color("a2a880")

static func verge(canvas: Node2D,outline: PackedVector2Array) -> void:
	# A narrow soil margin, then broken grass at the stone boundary. World-space
	# coordinates keep the texture aligned where streets join the forecourt.
	for spread in [12.0,8.0,4.0]:
		for apron in Geometry2D.offset_polygon(outline,spread,Geometry2D.JOIN_ROUND):
			polygon(canvas,apron,"limestone-floor",Color(.66,.62,.48,.12),PAVING_SCALE)
	for i in outline.size():
		var a := outline[i]; var b := outline[(i+1)%outline.size()]
		var count := int(a.distance_to(b)/19)
		for step in count:
			var at := a.lerp(b,(step+.5)/maxi(count,1))
			var variation := sin(at.x*.173+at.y*.287)
			if variation<.15: continue
			canvas.draw_line(at+Vector2(-3,2),at+Vector2(2,-2),Color(.36,.39,.25,.30),1.5,true)

static func texture(key: String) -> Texture2D:
	if cache.has(key): return cache[key]
	var source: Texture2D = load("res://assets/art/places/"+key+"-v1.png")
	var image := source.get_image(); image.generate_mipmaps()
	var material := CanvasTexture.new(); material.diffuse_texture = ImageTexture.create_from_image(image)
	material.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS; material.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	cache[key] = material; return material
static func polygon(canvas: CanvasItem,points: PackedVector2Array,key: String,color: Color = Color.WHITE,scale: float = 240) -> void:
	var uv := PackedVector2Array()
	for p in points:
		uv.append(Vector2(p.x,p.y*2.0 if key=="limestone-floor" else p.y)/scale)
	canvas.draw_polygon(points,PackedColorArray([color]),uv,texture(key))
static func paving(canvas: CanvasItem,rect: Rect2,color: Color = Color.WHITE,scale: float = 240) -> void:
	polygon(canvas,PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)]),"limestone-floor",color,scale)
static func wall(canvas: CanvasItem,a: Vector2,b: Vector2,height: float = 138) -> void:
	var points := PackedVector2Array([a,b,b-Vector2(0,height),a-Vector2(0,height)])
	polygon(canvas,points,"limewash-wall",Color("d7cbb0"),230)
	for level in [0,16]:
		canvas.draw_line(a-Vector2(0,level),b-Vector2(0,level),Color("96836a"),5 if level==0 else 3,true)
	canvas.draw_line(a-Vector2(0,height),b-Vector2(0,height),Color("76654d"),10,true)
	canvas.draw_line(a-Vector2(0,height+3),b-Vector2(0,height+3),Color("ddcda9"),3,true)
	canvas.draw_colored_polygon(PackedVector2Array([a,b,b+Vector2(15,30),a+Vector2(15,30)]),Color(.14,.12,.08,.13))
static func window(canvas: CanvasItem,p: Vector2,width: float = 45,height: float = 74) -> void:
	var outline := PackedVector2Array([p+Vector2(-width/2,0),p+Vector2(-width/2,-height*.68),p+Vector2(0,-height),p+Vector2(width/2,-height*.68),p+Vector2(width/2,0)])
	canvas.draw_colored_polygon(outline,Color("4b635d")); var border := outline.duplicate(); border.append(outline[0])
	canvas.draw_polyline(border,Color("9a825e"),7,true); canvas.draw_polyline(border,Color("d7c49c"),3,true)
	canvas.draw_line(p,p-Vector2(0,height-8),Color("c2ae82"),3,true)
	canvas.draw_line(p+Vector2(-width/2,-height*.4),p+Vector2(width/2,-height*.4),Color("c2ae82"),3,true)
	canvas.draw_polygon(PackedVector2Array([p+Vector2(-width/2,8),p+Vector2(width/2,8),p+Vector2(width/2+110,200),p+Vector2(80,200)]),PackedColorArray([Color(1,.9,.65,.16),Color(1,.9,.65,.16),Color(1,.9,.65,0),Color(1,.9,.65,0)]))
static func threshold(canvas: CanvasItem,at: Vector2,width: float = 86) -> void:
	paving(canvas,Rect2(at-Vector2(width/2,13),Vector2(width,26)),Color("d7caac"),PAVING_SCALE)
	canvas.draw_line(at+Vector2(-width/2,-13),at+Vector2(width/2,-13),Color("8b795b"),3,true)
	canvas.draw_line(at+Vector2(-width/2,13),at+Vector2(width/2,13),Color("eee1bc"),2,true)
static func sign(canvas: CanvasItem,at: Vector2,words: String,right: bool = true) -> void:
	canvas.draw_line(at,at-Vector2(0,83),Color("644e35"),6,true)
	var side := 1 if right else -1
	var board := PackedVector2Array([at+Vector2(-46,-85),at+Vector2(46,-85),at+Vector2(46+side*9,-72),at+Vector2(46,-59),at+Vector2(-46,-59),at+Vector2(-46+side*9,-72)])
	canvas.draw_colored_polygon(board,Color("765c3c")); canvas.draw_line(at+Vector2(-43,-83),at+Vector2(43,-83),Color("b89866"),1,true)
	canvas.draw_string(ThemeDB.fallback_font,at+Vector2(-40,-68),words,HORIZONTAL_ALIGNMENT_CENTER,80,12,Color("eadbb8"))
