extends Node2D
## Authored pose atlases share one world scale and a bottom-centre anchor.
@export var animal := "wolf"
@export var size := 70.0
var fallen := false
var clock := 0.0
static var textures: Dictionary = {}
static var manifest: Dictionary = {}
static var sheets: Dictionary = {}
static func data() -> Dictionary:
	if manifest.is_empty(): manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/forest/animal-poses-v2.json")).entries
	return manifest
static func frame_for(id: String,pose: String,time: float) -> int:
	if id=="deer":
		if pose=="walk": return 3+posmod(int(time/.18),2)
		if pose=="run": return 5
		if pose=="inspect": return 2
		return 1 if posmod(int(time/2.5),4)==2 else 0
	if pose in ["kneel","fallen","dead"]: return 5
	if pose=="walk": return 1+posmod(int(time/.16),2)
	if pose in ["attack","thrust","crush","shoot","sweep","punch"]:
		return 3 if time<.34 else 4 if time<.68 else 0
	return 0
static func art(id: String,index: int=0) -> Texture2D:
	var key:=id+":"+str(index)
	if textures.has(key): return textures[key]
	var row: Dictionary=data()[id]
	if not sheets.has(id):
		var image: Image=load(row.source).get_image() if ResourceLoader.exists(row.source) else Image.load_from_file(row.source)
		image.fix_alpha_edges();image.generate_mipmaps()
		var source:=CanvasTexture.new();source.diffuse_texture=ImageTexture.create_from_image(image);source.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sheets[id]=source
	var frame: Array=row.frames[index]
	var atlas:=AtlasTexture.new();atlas.atlas=sheets[id];atlas.region=Rect2(frame[0],frame[1],frame[2],frame[3]);atlas.filter_clip=true
	textures[key]=atlas;return atlas
static func walk_blend(id: String,pose: String,time: float) -> Dictionary:
	if pose!="walk":return {"next":frame_for(id,pose,time),"weight":0.0}
	var duration:=.18 if id=="deer" else .16
	return {"next":frame_for(id,pose,time+duration),"weight":smoothstep(duration-.04,duration,fposmod(time,duration))}

static func paint(canvas: CanvasItem,id: String,point: Vector2,height: float,left: bool,pose: String,time: float,flash: float=0) -> Vector2:
	canvas.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var texture:=art(id,frame_for(id,pose,time))
	var factor: float=height/float(data()[id].reference_height)
	var drawn:=texture.get_size()*factor
	var base_width:=art(id).get_width()*factor
	var extension:=smoothstep(.30,.45,time)*(1-smoothstep(.68,.95,time)) if pose in ["attack","thrust","crush","sweep","punch"] else 0.0
	var offset:=Vector2(-1 if left else 1,0)*extension*height*.1
	canvas.draw_set_transform(point,0,Vector2(1,.35))
	for ring in range(4,0,-1): canvas.draw_circle(Vector2.ZERO,base_width*(.20+ring*.025),Color(0,0,0,.035))
	canvas.draw_set_transform(point+offset,0,Vector2(1 if left else -1,1))
	var blend:=walk_blend(id,pose,time)
	var tint:=Color.WHITE.lerp(Color("dfaaa0"),flash*.5)
	if blend.weight>0:
		canvas.draw_texture_rect(texture,Rect2(Vector2(-drawn.x*.5,-drawn.y),drawn),false,Color(tint,1.0-blend.weight))
		var next_texture:=art(id,blend.next)
		var next_size:=next_texture.get_size()*factor
		canvas.draw_texture_rect(next_texture,Rect2(Vector2(-next_size.x*.5,-next_size.y),next_size),false,Color(tint,blend.weight))
	else:canvas.draw_texture_rect(texture,Rect2(Vector2(-drawn.x*.5,-drawn.y),drawn),false,tint)
	canvas.draw_set_transform(Vector2.ZERO);return point+offset
func _process(delta: float) -> void:
	if not visible: return
	var prefs=get_node_or_null("/root/GamePreferences")
	if prefs!=null and prefs.options.get("reduced_fx",false): return
	clock+=delta
	if animal=="deer": queue_redraw()
func _draw() -> void: paint(self,animal,Vector2.ZERO,size,true,"kneel" if fallen else "ready",clock)
