extends RefCounted
## Read the same discoveries on land and aboard; never grant unseen notes.
static func notes(p) -> Array:
	var entries: Array = []
	for id in preload("res://scripts/chapter/childhood_home_plan.gd").NOTES:
		if p.flags.get(id,false):
			var row: Dictionary=preload("res://scripts/chapter/childhood_home_plan.gd").NOTES[id]
			entries.append({"id":"home:"+id,"title":row.title,"text":row.text})
	var convent = preload("res://scripts/city/convent_plan.gd")
	for id in convent.NOTES:
		if convent.observed(p,id): entries.append({"id":"convent:"+id,"title":convent.NOTES[id].title,"text":convent.NOTES[id].text})
	var forest = preload("res://scripts/city/forest_plan.gd")
	for id in p.childhood_hunt.get("notes",[]):
		var row: Dictionary = forest.DISCOVERIES[id]
		entries.append({"id":"forest:"+str(id),"title":row.title,"text":row.text})
	var district = preload("res://scripts/chapter/lisbon_district.gd")
	for id in district.NOTES:
		if p.flags.get(id,false): entries.append({"id":"lisbon:"+id,"title":district.NOTES[id].title,"text":district.NOTES[id].text})
	var access = preload("res://scripts/city/lisbon_access.gd")
	for id in access.ROWS:
		if access.observed(p,id): entries.append({"id":"access:"+id,"title":access.ROWS[id].title,"text":access.ROWS[id].text})
	entries.append_array(preload("res://scripts/chapter/optional_arc.gd").memories(p))
	entries.append_array(preload("res://scripts/chapter/adult_arc.gd").notes(p))
	entries.append_array(preload("res://scripts/chapter/first_order_service.gd").notes(p))
	entries.append_array(preload("res://scripts/city/order_house_hub.gd").journal(p))
	entries.append_array(preload("res://scripts/chapter/order_campaign.gd").notes(p))
	return entries
static func request_text(p,text:String,finished:bool) -> String:
	if not finished and p.completed and p.journey.get("kind","")!="port_visit": return text+"\n\nRetoma este pedido em terra, quando estiveres atracado em Lisboa."
	return text
static func requests(p) -> Array:
	var entries: Array = []
	for row in preload("res://scripts/chapter/order_campaign.gd").notes(p):entries.append({"title":row.title,"text":request_text(p,row.text,row.id!="order:cargo" or p.flags.get("order_cargo_done",false))})
	if preload("res://scripts/city/order_house_hub.gd").meal_stage(p)!="": entries.append({"title":"Ordem · A mesa de quem fica","text":request_text(p,preload("res://scripts/city/order_house_hub.gd").meal_objective(p),preload("res://scripts/city/order_house_hub.gd").meal_stage(p)=="done")})
	var house = preload("res://scripts/city/house_life.gd")
	for young in [true,false]:
		if not house.stage(p,young).is_empty():
			var text:String=house.objective(p,young)
			if young and house.stage(p,true)!="done" and (p.flags.get("hunt_completed",false) or p.checkpoint>0 or p.completed or p.entry_scene in ["res://scenes/chapter_01/adult_opening.tscn","res://scenes/chapter_01/chapter_flow.tscn"]): text="Ficou por concluir na infância. Esta lembrança não bloqueia os pedidos da fase adulta."
			entries.append({"title":"A água da casa · "+("Infância" if young else "Fase adulta"),"text":request_text(p,text,young or house.stage(p,false)=="done")})
	var cart = preload("res://scripts/chapter/local_request_state.gd")
	if not cart.stage(p).is_empty(): entries.append({"title":cart.definition().title,"text":request_text(p,cart.objective(p),cart.stage(p)=="completed")})
	var errands = preload("res://scripts/chapter/lisbon_errands.gd")
	for id in errands.DEFINITIONS:
		var stage: String = errands.stage(p,id)
		if not stage.is_empty(): entries.append({"title":errands.DEFINITIONS[id].title,"text":request_text(p,errands.DEFINITIONS[id].objectives[stage],stage=="completed")})
	return entries
