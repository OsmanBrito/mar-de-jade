extends RefCounted
## Presentation only: battle time and resources do not advance during the introduction.
const PORTRAITS={"Duarte":"duarte","Inês":"ines","Mestre de Ferro":"mestre","Rui de Avelar":"avelar","Catarina":"catarina","Afonso do Lastro":"afonso","Guardião da Rosa":"guardiao","Yusuf ibn Rami":"yusuf","Esteban de Alarcón":"esteban","Eco da Primeira Maré":"guardiao"}
var active:=false
var elapsed:=0.0
var duration:=2.5
var actor_name:=""
var technique:=""
var enemy:=false
var reduced:=false
var textures: Dictionary={}
var portrait: Texture2D
var body_portrait:=false
func clear() -> void:
	active=false; elapsed=0.0; portrait=null
func begin(actor: Dictionary, name: String, reduced_fx: bool, fast: bool, combat_image: Texture2D=null) -> void:
	active=true; elapsed=0.0; actor_name=actor.name; technique=name; enemy=actor.team==1; reduced=reduced_fx
	duration=2.0 if reduced or fast else 2.5
	body_portrait=not PORTRAITS.has(actor_name) and combat_image!=null
	if body_portrait:
		var key: String="combat:"+actor.get("kind",actor_name)
		if not textures.has(key):
			var source: Texture2D=combat_image.atlas if combat_image is AtlasTexture else combat_image
			if source is CanvasTexture: source=source.diffuse_texture
			var image: Image=source.get_image()
			if combat_image is AtlasTexture: image=image.get_region(combat_image.region)
			textures[key]=ImageTexture.create_from_image(image.get_region(image.get_used_rect()))
		portrait=textures[key]
		return
	var art: String=PORTRAITS.get(actor_name,actor.get("kind","mestre"))
	var path: String="res://assets/portraits/"+art+".png"
	if not ResourceLoader.exists(path): path="res://assets/portraits/mestre.png"
	if not textures.has(path): textures[path]=load(path)
	portrait=textures[path]
func update(delta: float) -> bool:
	if not active: return false
	elapsed+=maxf(0,delta)
	if elapsed<duration: return false
	active=false
	return true
func draw(c: Node2D) -> void:
	if not active: return
	var progress: float=clampf(elapsed/duration,0,1)
	var enter: float=1.0 if reduced else ease(clampf(progress/0.22,0,1),0.35)
	var fade: float=1.0 if reduced else minf(1,(1-progress)/0.15)
	var gold:=Color("e2b66c")
	var ink:=Color("07171f")
	var paper:=Color("f3e4c6")
	c.draw_rect(Rect2(0,0,960,540),Color(ink,0.82*minf(1,enter*1.8)*fade))
	var slide: float=(1-enter)*110
	var frame:=Rect2(688+slide,42,256,456)
	c.draw_rect(frame.grow(3),Color(gold,0.6*fade))
	c.draw_rect(frame,Color(ink,fade))
	if portrait!=null:
		var size: Vector2=portrait.get_size()
		if body_portrait:
			var shown: Vector2=size*minf(232.0/size.x,374.0/size.y)
			c.draw_texture_rect(portrait,Rect2(frame.position+Vector2((256-shown.x)/2,374-shown.y),shown),false,Color(1,1,1,fade))
		else:
			var crop_width: float=size.y*frame.size.x/frame.size.y
			var crop:=Rect2((size.x-crop_width)/2,0,crop_width,size.y)
			c.draw_texture_rect_region(portrait,frame,crop,Color(1,1,1,fade))
	c.draw_rect(Rect2(frame.position+Vector2(0,361),Vector2(frame.size.x,95)),Color(ink,0.88*fade))
	c.text_at(c.fit_text(actor_name,224,18),frame.position+Vector2(16,402),18,Color(paper,fade))
	c.text_at("TÉCNICA ESPECIAL" if enemy else "TÉCNICA SUPREMA",Vector2(48-slide*0.25,218),14,Color(gold,fade))
	c.draw_line(Vector2(48,235),Vector2(635,235),Color(gold,0.65*fade),2,true)
	var lines: Array[String]=c.tactical.wrap_hint(technique,568,34,3)
	for i in lines.size(): c.text_at(lines[i],Vector2(48-slide*0.25,288+i*42),34,Color(paper,fade))
	c.text_at("Lê a técnica. O ritmo começa a seguir." if enemy else "A dupla muda o rumo da batalha.",Vector2(48,405),15,Color(paper,0.85*fade))
	c.text_at("ENTER · avançar",Vector2(48,481),11,Color(gold,0.7*fade))

