extends RefCounted
## Full Medida catalogue. Requirements describe campaign access, never purchasable cultivation.
static var cache: Dictionary={}
const LEGACY=["ES07","LA07","MC08","PU07","FO01","FO07","FO08","FO09","ES09","LA09","MC09","PU09","FO10"]
const INTRO=["ES09","LA09","MC09","PU09","FO10"]
const FIRST={"ES":"ES07","LA":"LA07","MC":"MC08","FO":"FO07","PU":"PU07"}
const RANKS=["Fundamento","Circulação","Integração","Manifestação","Plenitude"]
static func rows() -> Dictionary:
	if cache.is_empty():
		for row in JSON.parse_string(FileAccess.get_file_as_string("res://data/order_techniques.json")).techniques: cache[row.id]=row
	return cache
static func action(id: String) -> int:
	return 200+rows().keys().find(id)
static func id_for(command: int) -> String:
	var ids: Array=rows().keys()
	return ids[command-200] if command>=200 and command<200+ids.size() else ""
static func rank_of(p) -> int:
	return int(p.development.members.hero.cultivation.rank)
static func reason(p,id: String) -> String:
	if not rows().has(id): return "Técnica desconhecida."
	var row: Dictionary=rows()[id]
	if p.skills.has(id): return "Técnica já aprendida."
	if p.flags.get("injured",false): return "Recupera antes de estudar."
	if not p.flags.get("order_audience_done",false): return "Apresenta o relato ao Grão-Mestre."
	if not p.skills.has(FIRST[row.style]): return "Conclui o fundamento deste manejo com Tomé."
	if not p.flags.get("order_trial_done",false): return "Conclui a avaliação com o instrutor."
	if INTRO.has(id): return ""
	if rank_of(p)<int(row.rank): return "Cultivo necessário: "+RANKS[int(row.rank)]+"."
	var proficiency: int=p.development.members.hero.proficiency.get(row.style,0)
	if proficiency<int(row.proficiency): return "Proficiência de %s: %d / %d."%[row.style,proficiency,row.proficiency]
	# C01 teaching is recorded by FIRST; later milestones must be real campaign awards.
	if int(row.rank)>0 and not p.development.claimed.any(func(mark): return str(mark).begins_with(row.milestone)):
		return "Ensino da campanha necessário: "+row.milestone+"."
	if row.postgame:
		if p.development.members.hero.cultivation.step<3: return "Pós-jogo: Plenitude 3 necessária."
		if preload("res://scripts/chapter/character_development.gd").level_of(p.development.members.hero.xp)<52: return "Pós-jogo: nível 52 necessário."
	return ""
static func price(id: String) -> int: return int(rows()[id].price)
static func requirements(id: String) -> String:
	if id=="FO10": return "Fundamento · estudo introdutório autorizado em Lisboa (adaptação preservada)."
	var row: Dictionary=rows()[id]
	return "%s · proficiência %d · %s%s"%[RANKS[int(row.rank)],row.proficiency,"ensino de Tomé" if int(row.rank)==0 else "ensino da campanha no capítulo %d"%[3,5,7,10][int(row.rank)-1]," · pós-jogo, nível 52, Plenitude 3" if row.postgame else ""]
