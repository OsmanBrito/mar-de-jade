extends RefCounted
## C01 firearm techniques from habilidades-passivas-v2/armas-de-fogo.md.
const IDS := {1:"FO07",2:"FO01",3:"FO09",8:"FO08"}
const LEARNED := ["FO07","FO01","FO08","FO09"]
const COSTS := {1:4,2:6,3:7,8:7}
static func upgrade_lesson(skills: Array) -> void:
	# A loaded FO07 records Tomé's completed firearm lesson, including old saves.
	if not skills.has("FO07"): return
	for id in LEARNED:
		if not skills.has(id): skills.append(id)
static func definition(skill: int,base: Dictionary,stationary: bool) -> Dictionary:
	var d := base.duplicate(true)
	d.effect = "ranged"; d.shape = "single"; d.uses_opening = false
	d.name = "Disparo básico"; d.description = "Disparo a até quatro casas com linha livre. Recupera 1 alento. A recarga faz parte da ação."
	d.range = 4; d.power = 20
	if IDS.has(skill): d.content_id = IDS[skill]
	match skill:
		1:
			d.name = "Disparo de Medida"; d.cost = 4; d.range = 3; d.power = 17
			d.description = "Primeiro alvo em linha, até três casas. Bom ou Perfeito reduz pela metade o próximo bónus comum de aproximação desse alvo; não impede movimento."
		2:
			d.name = "Tiro Preparado"; d.cost = 6; d.power = roundi(21*1.15) if stationary else 21
			d.description = "Mira e dispara na mesma ação, até quatro casas. +15% de potência se não mudou de posição neste turno. Linha livre; não atravessa cobertura."
		3:
			d.name = "Tiro de Passagem"; d.cost = 7; d.range = 3; d.power = 17
			d.description = "Dispara da posição inicial a até três casas e dá um passo lateral depois. Exige destino livre, mostrado no campo; não permite disparar através de cobertura."
		8:
			d.name = "Guarda do Cano"; d.cost = 7; d.range = 0; d.power = 0; d.shape = "self"; d.effect = "brace"
			d.description = "Prepara proteção de 30% ao primeiro golpe de contacto frontal, até ao próximo turno próprio. Sem dano ou tiro extra; não protege de projéteis, flancos ou costas."
	return d
static func side_step(model,actor: int,aim: Vector2i) -> Vector2i:
	var origin: Vector2i = model.units[actor].cell
	var forward: Vector2i = model.DIRECTIONS[model.direction_index(aim-origin)]
	var side := Vector2i(-forward.y,forward.x)
	for destination in [origin+side,origin-side]:
		if model.passable(destination,actor): return destination
	return Vector2i(-1,-1)
