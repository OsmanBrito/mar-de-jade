@tool
extends Node2D
## Fictional Lisbon house linked to Tomar; not the historical convent relocated.
const NAME := "Casa de Acolhimento da Ordem de Cristo"
const EXTERIOR := "res://assets/art/order/convent-gatehouse-v2.png"
const Plan = preload("res://scripts/city/convent_plan.gd")

const NOTICES := {
	"square":{"point":Vector2(-250,190),"title":"A casa da Ordem","text":"Casa de Acolhimento da Ordem de Cristo · Lisboa\n\nLigada ao Convento de Cristo, em Tomar, esta casa recebe crianças sem família e mantém dormitório, refeitório, enfermaria e pátio de ensino. Tomé cuida do abrigo.\n\nA pedra antiga e a memória dos Templários pertencem à história da casa; a cruz vermelha com o centro branco identifica a Ordem de Cristo. O claustro e a capela ficam para lá da portaria."},
	"room":{"point":Vector2(110,300),"title":"O livro do acolhimento","text":"Uma mesa, um lugar, um nome\n\nO livro da casa regista quem chegou e quem precisa de roupa, alimento ou tratamento. As primeiras páginas estão gastas; as mais recentes têm a letra de Tomé.\n\nEntre as contas do refeitório há remendos de roupa e mantimentos para o cais. A casa também apoia as missões da Ordem; o trabalho continua fora destas paredes."}
}
@export var interior := false

static func install_exterior(world: Node2D,dressing: Node2D) -> void:
	if dressing.has_node("ConventoDaOrdem"): return
	for old_name in ["Abrigo","CasaDaPraca","RuaNorte"]:
		var old := dressing.get_node_or_null(old_name)
		if old!=null: old.free()
	var building := Sprite2D.new(); building.name = "ConventoDaOrdem"
	building.texture = load(EXTERIOR); building.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var factor := Plan.EXTERIOR_WIDTH/building.texture.get_width()
	building.scale = Vector2.ONE*factor
	# Keep the eastern arcade at the square; the expanded church extends north/west.
	building.position = Plan.EXTERIOR_ORIGIN+building.texture.get_size()*factor*0.5
	var grounding := Node2D.new(); grounding.name = "ConventFoundation"
	grounding.set_script(preload("res://scripts/city/convent_foundation.gd")); grounding.z_index = -1
	dressing.add_child(grounding)
	dressing.add_child(building)
	var footprint := StaticBody2D.new(); footprint.name = "ConventFootprint"; footprint.collision_mask = 0
	world.get_node("ActorsAndProps").add_child(footprint)
	var shape := CollisionPolygon2D.new()
	shape.polygon = PackedVector2Array(Plan.EXTERIOR_FOOTPRINT)
	footprint.add_child(shape)
	var heraldry := Node2D.new(); heraldry.name = "OrderIdentity"; heraldry.set_script(load("res://scripts/chapter/order_house.gd"))
	dressing.add_child(heraldry)

static func install_interior(room: Node2D) -> void:
	if room.has_node("OrderIdentity"): return
	var heraldry := Node2D.new(); heraldry.name = "OrderIdentity"; heraldry.set_script(load("res://scripts/chapter/order_house.gd")); heraldry.interior = true
	heraldry.z_index = 2; room.add_child(heraldry)

static func symbol(canvas: CanvasItem,center: Vector2,size: float,across: Vector2 = Vector2.RIGHT) -> void:
	var shape := PackedVector2Array()
	for p in [Vector2(-.34,-1),Vector2(.34,-1),Vector2(.19,-.23),Vector2(.73,-.35),Vector2(.73,.35),Vector2(.19,.23),Vector2(.34,1),Vector2(-.34,1),Vector2(-.19,.23),Vector2(-.73,.35),Vector2(-.73,-.35),Vector2(-.19,-.23)]: shape.append(center+across*p.x*size+Vector2.DOWN*p.y*size)
	canvas.draw_colored_polygon(shape,Color("9b3027"))
	canvas.draw_line(center-Vector2(0,size*.78),center+Vector2(0,size*.78),Color("f1e7c8"),maxf(1,size*.16),true)
	canvas.draw_line(center-across*size*.58,center+across*size*.58,Color("f1e7c8"),maxf(1,size*.16),true)

static func banner(canvas: CanvasItem,center: Vector2,across: Vector2) -> void:
	var a := across*17
	canvas.draw_line(center-a-Vector2(0,37),center+a-Vector2(0,37),Color("6f583a"),4,true)
	canvas.draw_colored_polygon(PackedVector2Array([center-a-Vector2(0,34),center+a-Vector2(0,34),center+a+Vector2(0,38),center+Vector2(0,28),center-a+Vector2(0,38)]),Color("e0d0a9"))
	canvas.draw_line(center-a-Vector2(0,32),center-a+Vector2(0,35),Color("a88d5d"),2,true)
	canvas.draw_line(center+a-Vector2(0,32),center+a+Vector2(0,35),Color("a88d5d"),2,true)
	symbol(canvas,center,17,across)

func _draw() -> void:
	if interior:
		var ground := get_parent().get_node("Ground") as TileMapLayer
		var corner := ground.map_to_local(Vector2i.ZERO)+Vector2(0,-32)
		var left := ground.map_to_local(Vector2i(0,6))+Vector2(-64,0)
		var right := ground.map_to_local(Vector2i(7,0))+Vector2(64,0)
		banner(self,corner.lerp(left,.24)+Vector2(0,-77),(left-corner).normalized())
		banner(self,corner.lerp(right,.25)+Vector2(0,-77),(right-corner).normalized())
		# The ledger is a tangible, modest object beside the optional reading point.
		var book := Vector2(160,245)
		draw_colored_polygon(PackedVector2Array([book+Vector2(-21,0),book+Vector2(0,-10),book+Vector2(24,2),book+Vector2(3,12)]),Color("8a3c2c"))
		draw_line(book,book+Vector2(3,10),Color("dbc89d"),2,true)
	else:
		var p: Vector2 = NOTICES.square.point+Vector2(-24,-10)
		draw_colored_polygon(PackedVector2Array([p+Vector2(-20,0),p+Vector2(11,-16),p+Vector2(27,-8),p+Vector2(-5,8)]),Color("b2a082"))
		symbol(self,p+Vector2(2,-5),8,Vector2(.89,.45))
