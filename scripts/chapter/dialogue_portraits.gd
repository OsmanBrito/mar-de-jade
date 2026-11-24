extends RefCounted
## One bust framing rule for the whole cast; approved faces remain unchanged.
const NPC = preload("res://scripts/npcs/lisbon_npc_library.gd")
const ASPECT := 5.0/6.0
static var cache: Dictionary = {}
static var sources: Dictionary = {}
static var busts: Dictionary = {}
static func identity(who: String,young: bool,hero_name: String) -> String:
	who = who.split(" · ")[0]
	if who==hero_name or who in ["Herói","Herói adulto","Herói criança"]: return "hero_child" if young or who=="Herói criança" else "hero_adult"
	if who in ["Leonor","Leonor criança"]: return "leonor_child" if young or who=="Leonor criança" else "leonor_adult"
	if who=="Tomé": return "tome_young" if young else "tome_adult"
	return {"Duarte":"duarte","Vizinha":"dock_woman","Vizinha da cozinha":"dock_woman","Pescadora":"dock_woman","Trabalhador":"worker","Trabalhador ferido":"injured_worker","Mulher do cais":"dock_woman","Observador":"observer","Criança":"shelter_child","Mestre":"master","Combatente":"combatant","Rodrigo":"rodrigo","Beatriz":"beatriz","Familiar":"family","Ajudante da cozinha":"attendant","Ajudante da enfermaria":"attendant","Irmão da portaria":"attendant","Responsável dos mantimentos":"dock_woman","Comerciante":"observer","Marinheiro do batel":"worker","Oficial da oficina":"worker","Trabalhador do pontão":"worker"}.get(who,"")
static func filtered(path: String) -> Texture2D:
	if sources.has(path): return sources[path]
	var image: Image = load(path).get_image() if ResourceLoader.exists(path) else Image.load_from_file(path)
	image.fix_alpha_edges();image.generate_mipmaps()
	var texture:=CanvasTexture.new();texture.diffuse_texture=ImageTexture.create_from_image(image);texture.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sources[path]=texture;return texture
static func portrait(id: String) -> Texture2D:
	if cache.has(id): return cache[id]
	if id=="duarte":
		var info: Dictionary = NPC.data().duarte; var f: Array = info.frames[0]
		var portrait_height: float = float(f[3])*0.66
		var atlas := AtlasTexture.new(); atlas.atlas = filtered(info.source)
		atlas.region = Rect2(f[0]+(f[2]-portrait_height*ASPECT)*0.5,f[1],portrait_height*ASPECT,portrait_height)
		atlas.filter_clip = true; cache[id] = atlas; return atlas
	var source: Texture2D
	var region: Rect2
	if id in ["hero_adult","hero_child"]:
		source=filtered("res://assets/art/portraits/hero-"+("adult" if id=="hero_adult" else "child")+"-v1.png")
		var height:=source.get_height()
		region=Rect2(Vector2((source.get_width()-height*ASPECT)*.5,0),Vector2(height*ASPECT,height))
	else:
		if busts.is_empty():busts=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/portraits/cast-busts-v2.json"))
		if busts.entries.has(id):
			var frame: Array=busts.entries[id]
			var bust:=AtlasTexture.new();bust.atlas=filtered(busts.get("source_overrides",{}).get(id,busts.source));bust.region=Rect2(frame[0],frame[1],frame[2],frame[3]);bust.filter_clip=true;cache[id]=bust;return bust
		if not NPC.data().has(id): return null
		var info: Dictionary=NPC.data()[id];var frame: Array=info.frames[0]
		source=filtered(info.source)
		var height: float=frame[3]*.45
		region=Rect2(Vector2(frame[0]+(frame[2]-height*ASPECT)*.5,frame[1]),Vector2(height*ASPECT,height))
	var atlas:=AtlasTexture.new();atlas.atlas=source;atlas.region=region;atlas.filter_clip=true
	cache[id]=atlas;return atlas
