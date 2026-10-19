extends Node2D
## Daily life belongs to the house, independently of the approved campaign.
const Actor = preload("res://scripts/chapter/actor_proxy.gd")
const City = preload("res://scripts/city/lisbon_scenery.gd")
const Plan = preload("res://scripts/city/convent_plan.gd")
const EXTERIOR := {
	"porter":{"at":Vector2(-855,155),"title":"Irmão da portaria"},
	"steward":{"at":Vector2(-790,345),"title":"Responsável dos mantimentos"},
	"water":{"at":Vector2(-865,255),"title":"Recolher água da cisterna"}
}
const WARD := {"ward":{"at":Vector2(780,535),"title":"Entregar água à enfermaria"},"cook":{"at":Vector2(1310,5),"title":"Ajudante da cozinha"}}
var world
var pupil: Node2D
var care_surface: Node2D
var elapsed := 0.0
var heard: Dictionary = {}
static func install(map: Node2D) -> void:
	if Engine.is_editor_hint(): return
	if map.has_node("HouseLife"): return
	var life := Node2D.new(); life.name = "HouseLife"; life.set_script(load("res://scripts/city/house_life.gd")); life.world = map; map.add_child(life)
	if map.has_meta("continuous_lisbon"):
		life.person("IrmaoDaPortaria","attendant",Vector2(-855,110))
		life.person("ResponsavelDosMantimentos","dock_woman",Vector2(-790,300))
		life.pupil = life.person("AprendizDoAdro","shelter_child",Vector2(-820,350),false)
		City.prop(map,"CisternaDoAdro","roman-well-refined-v1.png",Vector2(-935,245),Vector2(110,145),Rect2(-35,-22,70,30))
		var table := preload("res://scripts/chapter/furniture_art.gd").place(map.sorted_world,"table",Vector2(-865,300),Vector2(85,70))
		life.surface(table,false)
	else:
		life.person("AjudanteDaCozinha","worker",Vector2(1310,-40))
		var table = map.sorted_world.get_node_or_null("Table")
		if table!=null: life.care_surface = life.surface(table,true)
	preload("res://scripts/city/house_ambience.gd").install(map)
func surface(table: Node2D,care: bool) -> Node2D:
	var items := Node2D.new(); items.name = "HouseWorkSurface"; items.set_script(preload("res://scripts/city/house_work_surface.gd")); items.care = care; table.add_child(items); return items
func person(label: String,id: String,at: Vector2,solid: bool = true) -> Node2D:
	var actor := Actor.new(); actor.name = label; actor.npc_id = id; actor.position = at
	world.sorted_world.add_child(actor)
	if solid:
		var badge := Node2D.new(); badge.set_script(preload("res://scripts/city/house_service_badge.gd")); actor.add_child(badge)
	if solid: City.body(actor,PackedVector2Array([Vector2(-9,-5),Vector2(9,-5),Vector2(9,7),Vector2(-9,7)]))
	return actor
static func rows(map) -> Dictionary:
	if not is_instance_valid(map) or not map.has_node("HouseLife"): return {}
	return WARD if map.has_meta("order_convent") else EXTERIOR
static func child(map) -> bool: return bool(map.get("childhood"))
static func prefix(young: bool) -> String: return "house_child_" if young else "house_adult_"
static func stage(progress,young: bool) -> String:
	var key := prefix(young)
	for state in ["done","delivered","carrying","asked"]:
		if progress.flags.get(key+state,false): return state
	return ""
static func review(progress,young: bool) -> bool:
	return not young and progress.flags.get("house_adult_review",false)
static func objective(progress,young: bool) -> String:
	if review(progress,young):
		match stage(progress,young):
			"asked": return "Confere a água de serviço na cisterna do adro; depois verifica as bacias e os panos na enfermaria."
			"carrying": return "Água conferida. Verifica as bacias e os panos na enfermaria; conclui com o ajudante, sem voltar ao adro."
			"done": return "Concluído · Conferiste a água, as bacias e os panos; o ajudante confirmou a preparação."
	match stage(progress,young):
		"asked": return "Recolhe água na cisterna do adro, a poente da portaria."
		"carrying": return "Leva a água ao ajudante da enfermaria, pela entrada das arcadas."
		"delivered": return "Volta à responsável dos mantimentos no adro."
		"done": return "Concluído · A água foi entregue e a responsável confirmou a tarefa."
	return "A responsável dos mantimentos organiza o trabalho no adro."
static func talk(map,progress,id: String) -> Dictionary:
	var choices := rows(map)
	if not choices.has(id): return {}
	var young := child(map); var key := prefix(young); var state := stage(progress,young)
	var text := ""
	match id:
		"porter":
			text = "A portaria poente recebe quem procura acolhimento; Tomé atende lá dentro. As arcadas do lado nascente levam ao claustro. A capela fica a poente do jardim e a enfermaria a nascente. Mantemos estes caminhos livres para quem precisa de ajuda."
			if not young and progress.flags.get("house_child_done",false): text += "\n\nJá conheces o caminho desde a infância. Ainda te recordas de levar água para as bacias?"
		"steward":
			match state:
				"":
					progress.flags[key+"asked"] = true
					if not young and progress.flags.get("house_child_done",false): progress.flags.house_adult_review=true
					text = "Conferimos o pão e os mantimentos aqui antes de os levar para dentro. Se puderes ajudar, falta uma caneca de água para preparar o cuidado na enfermaria. Recolhe uma caneca de serviço na cisterna do adro e entrega-a ao ajudante; depois vem dizer-me que chegou. A tarefa pode esperar pelo que tens para fazer."
				"asked","carrying": text = objective(progress,young)+" Não deixes a caneca no caminho da portaria."
				"delivered":
					progress.flags[key+"done"] = true
					text = "A água chegou e já podemos preparar o cuidado. Obrigada. É assim que a casa funciona: cada pessoa trata de uma parte e confirma que o trabalho terminou."
				"done": text = "A água já foi entregue. Continuamos a conferir as porções antes da refeição; deixamos a passagem livre entre a cisterna e a portaria."
		"water":
			if state=="asked":
				progress.flags[key+"carrying"] = true
				text = "Enches a caneca de serviço e seguras a asa. A água segue agora para as bacias da enfermaria, do lado nascente do claustro."
			else: text = "A cisterna recolhe a água dos telhados. A caneca de serviço fica à guarda de quem distribui os mantimentos; só se retira o necessário para a tarefa."
		"ward":
			if state=="carrying":
				progress.flags[key+"delivered"] = true
				text = "Podes pousar a caneca junto das bacias. Obrigado; vou separar os panos limpos dos usados antes do próximo cuidado. Avisa a responsável de que a água chegou."
			else: text = "As bacias e os panos são preparados antes de receber alguém. O corredor entre as camas fica livre. Se quiseres ajudar com a água, fala com a responsável dos mantimentos no adro."
		"cook": text = "Os mantimentos vêm da mesa do adro; aqui separamos o pão e mantemos o caldo quente. O refeitório fica a poente deste corredor. Depois da refeição, as canecas regressam para lavar. Quem leva água para a enfermaria usa o corredor sul, longe das brasas."
	if review(progress,young):
		match id:
			"steward":
				if state=="": text="Já nos ajudaste com a água quando eras criança. Hoje não precisas levar outra caneca: confere a reserva da cisterna e verifica com o ajudante se as bacias e os panos estão prontos. Ele confirma a preparação ali mesmo; não precisas voltar a procurar-me."
				elif state=="done": text="O ajudante confirmou a água e os panos. A preparação está feita; obrigada por conferir cada parte."
			"water":
				if state=="asked": text="Conferes a reserva de água de serviço e a caneca limpa junto da cisterna. Há água suficiente; falta verificar as bacias e os panos na enfermaria."
			"ward":
				if state=="carrying":
					progress.flags[key+"done"]=true
					text="A água está conferida; as bacias estão limpas e os panos usados ficaram separados. Confirmo a preparação aqui. Vou avisar a responsável; podes seguir o teu caminho."
				elif state=="asked": text="Ainda falta conferir a reserva na cisterna. Depois verificamos aqui as bacias e os panos."
				elif state=="done": text="A preparação continua confirmada. Os panos limpos estão separados dos usados; não precisas repetir a conferência."
	if young and id=="steward" and state=="": text = "Leva só a caneca de serviço; se precisares, segura-a com as duas mãos. "+text
	if id=="porter":
		var met := "house_porter_met_child" if young else "house_porter_met_adult"
		if progress.flags.get(met,false): text = "A portaria continua livre. O acolhimento é pela porta poente; capela e enfermaria, pelas arcadas a nascente."+(" Ainda te lembras do caminho desde a infância." if not young and progress.flags.get("house_child_done",false) else "")
		progress.flags[met]=true
		if young: text += " Leonor espera junto do banco; podes visitar o claustro antes de ires ter com ela."
		else:
			var context := preload("res://scripts/city/city_conversations.gd").event(progress)
			var life = map.get_node("HouseLife")
			if not context.is_empty() and not life.heard.has(context):
				life.heard[context]=true
				var reactions := {"accident":"Ouve-se agitação no cais. Deixamos a portaria livre para o Tomé sair com os panos de cuidado.","rescue":"O Tomé já regressou do socorro. O ferido saiu acompanhado pela família.","demonstration":"As pessoas já voltam da demonstração da Leonor. Mantemos a passagem do claustro desimpedida.","departure":"A Botafogo prepara a partida. Se ainda precisas de alguma coisa da casa, trata disso antes de embarcar.","return":"Bem-vindo de volta à casa. A portaria recebe-te como sempre; o caminho para o claustro continua aberto."}
				text += "\n\n"+str(reactions[context])
	if not review(progress,young) and ((id=="water" and state=="asked") or (id=="ward" and state=="carrying")):
		map.get_node("HouseAmbience").service(id)
	return {"title":choices[id].title,"text":text}
func _process(delta: float) -> void:
	if not is_instance_valid(world.player): return
	if not world.player.enabled: return
	elapsed += delta
	if is_instance_valid(pupil):
		var target := Vector2(-820+sin(elapsed*.22)*40,350)
		var before := pupil.position
		if world.point_clear(target) and world.segment_clear(before,target): pupil.position = pupil.position.move_toward(target,38*delta)
		pupil.walking = before.distance_to(pupil.position)>.05; pupil.facing = 1 if target.x<before.x else 3; pupil.frame_time += delta*6
	# The carried vessel follows the same persistent task state in either age.
	var current := stage(get_node("/root/ChapterProgress"),child(world))
	world.player.presentation.carries_cup = current=="carrying" and not review(get_node("/root/ChapterProgress"),child(world))
	if is_instance_valid(care_surface):
		care_surface.delivered = current in ["delivered","done"]; care_surface.queue_redraw()
