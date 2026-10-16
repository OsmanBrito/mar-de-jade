extends RefCounted
## Shared icon framing and an illustrative footprint from the combat rules.
const Rules=preload("res://scripts/combat/mar_de_ferro/tactics.gd")
var textures: Dictionary={}
var previews: Dictionary={}

func icon(path: String) -> Texture2D:
	if textures.has(path): return textures[path]
	if not ResourceLoader.exists(path): return null
	var source: Texture2D=load(path)
	var image:=source.get_image()
	var bounds:=image.get_used_rect()
	image.fix_alpha_edges(); image.generate_mipmaps()
	var filtered:=CanvasTexture.new()
	filtered.diffuse_texture=ImageTexture.create_from_image(image)
	filtered.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var framed:=AtlasTexture.new()
	framed.atlas=filtered; framed.region=Rect2(bounds); framed.filter_clip=true
	textures[path]=framed
	return framed

func draw_icon(canvas: Node2D, texture: Texture2D, rect: Rect2, tint:=Color.WHITE) -> void:
	if texture==null: return
	var native:=texture.get_size()
	var shown:=native*minf(rect.size.x/native.x,rect.size.y/native.y)
	canvas.draw_texture_rect(texture,Rect2(rect.get_center()-shown*0.5,shown),false,tint)

func footprint(hero: int, skill: int) -> Dictionary:
	var key:="%d:%d"%[hero,skill]
	if previews.has(key): return previews[key]
	var rules=Rules.new(); rules.start("training",0)
	rules.obstacles.clear()
	for unit in rules.units: unit.cell=Vector2i(6,4)
	var origin:=Vector2i(1,2); rules.units[hero].cell=origin
	var definition: Dictionary=rules.skill_def(hero,skill)
	var aim:=Vector2i(2,2)
	if definition.shape=="self": aim=origin
	elif definition.shape=="leap": aim=origin+Vector2i(mini(3,int(definition.range)),0)
	elif definition.shape in ["ally","friend"]: rules.units[1-hero].cell=aim
	var cells: Array=rules.area(hero,skill,aim)
	previews[key]={"origin":origin,"aim":aim,"cells":cells,"shape":definition.shape,"range":definition.range}
	return previews[key]

func draw_footprint(canvas: Node2D, hero: int, skill: int, at: Vector2) -> void:
	var data:=footprint(hero,skill)
	for y in 5:
		for x in 7:
			var cell:=Vector2i(x,y)
			var rect:=Rect2(at+Vector2(x*21,y*16),Vector2(18,13))
			var distance: int=absi(x-data.origin.x)+absi(y-data.origin.y)
			var color:=Color("304752") if distance<=int(data.range) else Color("1b343e")
			if data.cells.has(cell): color=Color("78c5af")
			canvas.draw_rect(rect,color)
			if cell==data.origin: canvas.draw_rect(rect,Color("e2b66c"),false,2)
			if cell==data.aim: canvas.draw_circle(rect.get_center(),2,Color("eddfbb"))

