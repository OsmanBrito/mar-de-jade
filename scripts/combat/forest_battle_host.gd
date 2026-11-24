extends "res://scripts/combat/battle_host.gd"
func _ready() -> void:
	combat = preload("res://scripts/combat/forest_rules.gd").new()
	super._ready()
	var info: Dictionary = preload("res://scripts/combat/portugal_actor_art.gd").data().leonor_child
	var portrait := AtlasTexture.new(); portrait.atlas = load(info.source)
	var frame: Array = info.frames[0]; portrait.region = Rect2(frame[0],frame[1],frame[2],frame[3])
	art.hero_frames["leonor"] = [portrait]
func supreme_opening_sound(_actor: String,_technique: String,_fast: bool) -> void:
	combat_effect("opening_enter",-20)
func end_supreme_opening_sound() -> void:
	pass
func combat_effect(event: String,volume: float = -20) -> void:
	play_effect("gesture_cover_windup" if event=="opening_enter" else "fast_swing",volume)
func begin_hunt(kind: String,hero_name: String) -> void:
	ending.reset(self); combat.start_hunt(kind,hero_name)
	select_battle_map("forest"); prepare_battle_map()
	completed = false; active = true; paused = false; note = ""
	tactical.begin()
	note="Controlas "+hero_name+" · Golpe firme ataca; Respirar recupera. Termina o turno com a guarda voltada para o lobo." if kind=="wolf" else "Agora controlas Leonor criança · as técnicas são dela. Seleciona o urso; não são desbloqueios do protagonista."
	queue_redraw()
func check_outcome() -> bool:
	var finished := super.check_outcome()
	if finished and ending.has_result:
		ending.title = ("LOBO ABATIDO" if combat.encounter.ends_with("wolf") else "LEONOR DERROTOU O URSO") if ending.success else "TENTAR NOVAMENTE"
		ending.detail = "O combate terminou. A história continua." if ending.success else "O encontro recomeça antes do ataque; a progressão da campanha não é alterada."
	return finished
