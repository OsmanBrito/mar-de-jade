extends RefCounted
const Cart = preload("res://scripts/chapter/local_request_state.gd")
const Errands = preload("res://scripts/chapter/lisbon_errands.gd")
static func target_id(p,id: String) -> String:
	if id==Cart.ID: return {"inspect":"cart","parts":"dock","fit":"cart","return":"workshop"}.get(Cart.stage(p),"")
	var stage: String = Errands.stage(p,id)
	if id==Errands.ACCOUNT: return {"dock":"dock","kitchen":"neighbor","reconcile":"fisher"}.get(stage,"")
	if id==Errands.KIT and stage=="prepare": return "dock" if Errands.ready(p) else "shop"
	if id==Errands.BATEL:
		if stage=="observe": return "tide" if not p.flags.get("lisbon_tide_read",false) else "mooring"
		if stage=="solve": return "mooring"
	return ""
static func objective(p,id: String) -> String:
	if id=="ORDER-PRACTICE":return "Treino livre · procura o instrutor na armaria, no pátio sul da casa da Ordem. Usa o manejo que aprendeste com Tomé; podes sair do combate e retomar o serviço."
	if id=="ORDER-AUDIENCE":return "Apresenta o primeiro relato à liderança na Sala do Capítulo, pelo corredor norte da secretaria."
	if id=="ORDER-CARGO":return preload("res://scripts/chapter/order_campaign.gd").objective(p)
	if id=="ORDER-MEAL": return preload("res://scripts/city/order_house_hub.gd").meal_objective(p)
	if id==Cart.ID: return Cart.objective(p)
	if Errands.DEFINITIONS.has(id): return Errands.DEFINITIONS[id].objectives.get(Errands.stage(p,id),"")
	return ""
static func target(p,city) -> Vector2:
	var id := target_id(p,p.choices.get("tracked_request",""))
	if id=="shop" and is_instance_valid(city.harbor.merchant): return city.harbor.merchant.approach
	if id.is_empty() or not city.markers.has(id): return Vector2.INF
	return city.approach(id)
static func track(p,id: String) -> bool:
	if target_id(p,id).is_empty(): return false
	p.choices.tracked_request = id
	return true
