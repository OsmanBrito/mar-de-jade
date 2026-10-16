extends RefCounted
## Encounter rows retain authored identities, positions and boss durability.
## Role modifiers are applied once at spawn, equally in both difficulties.
const PROFILES := {
	"signaller":{"hp":0.94,"posture":0.90,"damage":0.85,"pressure":0.90,"speed":0,"weakness":"Quebra, atordoa ou desloca para cortar a ordem."},
	"boarder":{"hp":1.0,"posture":1.0,"damage":0.95,"pressure":1.0,"speed":0,"weakness":"Gancho de alcance 3; guarda, cobertura e defesa perfeita impedem o puxão."},
	"guard":{"hp":1.0,"posture":1.0,"damage":1.0,"pressure":1.0,"speed":0,"weakness":"Equilibrado; explora flancos e Abertura."},
	"defender":{"hp":1.30,"posture":1.35,"damage":1.15,"pressure":1.25,"speed":0,"weakness":"Postura forte; lento a perseguir flancos."},
	"duelist":{"hp":0.98,"posture":0.90,"damage":1.02,"pressure":0.95,"speed":1,"weakness":"Rápido; guarda vulnerável à quebra."},
	"rogue":{"hp":0.96,"posture":0.92,"damage":1.0,"pressure":0.90,"speed":1,"weakness":"Móvel; pouca resistência ao confronto."},
	"archer":{"hp":0.94,"posture":0.90,"damage":1.0,"pressure":0.90,"speed":0,"weakness":"Frágil; bloqueia a linha e aproxima-te."},
	"pikeman":{"hp":1.18,"posture":1.25,"damage":1.18,"pressure":1.38,"speed":0,"weakness":"Pressiona a postura; procura os flancos."},
	"bombard":{"hp":1.12,"posture":1.08,"damage":1.30,"pressure":1.22,"speed":0,"weakness":"Frágil; sai da área antes da explosão."},
	"medic":{"hp":1.22,"posture":1.15,"damage":0.85,"pressure":0.85,"speed":0,"weakness":"Ofensiva fraca; isola-o dos feridos."},
	"boss":{"hp":1.0,"posture":1.0,"damage":1.0,"pressure":1.0,"speed":0,"weakness":"Lê o aviso e explora a recuperação."}
}

static func apply(unit: Dictionary, encounter: String, power: float) -> void:
	var profile: Dictionary=PROFILES.get(unit.kind,PROFILES.guard)
	unit.region_power=power
	unit.challenge_power=power
	unit.posture_pressure=power
	# Preserve tutorial values, timing and teaching order.
	if encounter in ["training","prologue_raid"]: return
	unit.hp=maxi(1,roundi(unit.hp*(1.0 if unit.name=="Rui de Avelar" else float(profile.hp)))); unit.max_hp=unit.hp
	unit.posture=maxi(1,roundi(unit.posture*(1.0 if unit.name=="Rui de Avelar" else float(profile.posture)))); unit.max_posture=unit.posture
	unit.speed+=int(profile.speed)
	if unit.kind=="defender": unit.movement=mini(3,int(unit.movement)); unit.moves=unit.movement
	unit.challenge_power=power*float(profile.damage)
	unit.posture_pressure=power*float(profile.pressure)

static func weakness(kind: String) -> String:
	return PROFILES.get(kind,PROFILES.guard).weakness

