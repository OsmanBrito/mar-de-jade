extends RefCounted
## A single delayed handoff after recovery; never advances the combat simulation.
const Stage = preload("res://scripts/combat/battle_stage.gd")
const HOLD := 0.65
const FADE := 0.22
var phase := "idle"
var clock := 0.0
var success := false
var has_result := false
var title := ""
var detail := ""
var duel := false
func running() -> bool: return phase!="idle"
func reset(host) -> void:
	has_result = false
	# style_test can start school during the covered handoff. Keep its reveal.
	if phase=="in": return
	phase = "idle"; clock = 0
	Stage.cover(host,0)
func begin(host,ok: bool) -> void:
	success = ok; has_result = true; phase = "hold"; clock = 0
	duel = host.combat.encounter=="portugal_duel"
	var mode: String = host.combat.get("mode") if host.combat.get("mode")!=null else ("child_attack" if host.combat.lesson==0 else "child_defense")
	title = "EXERCÍCIO CONCLUÍDO"; detail = "Ataque básico praticado."
	if duel: title = "LEONOR VENCEU"; detail = "A avaliação terminou. A história continua com o auxílio de Duarte e Tomé; o treino virá depois da recuperação."
	elif not ok: title = "VOLTAR A PRATICAR"; detail = "Observa a orientação e o sinal."
	elif mode in ["child_defense","adult_defense"]: title = "DEFESA PRATICADA"; detail = "Defesa simples praticada."
	elif mode=="school": title = "FUNDAMENTO PRATICADO"; detail = "Básico e técnica executados."
	elif mode=="perfect_defense": title = "DEFESA PERFEITA"; detail = "Golpe aparado."
	elif mode=="duarte_support": title = "PROTEÇÃO EXECUTADA"; detail = "Exercício de Duarte concluído."
func advance(host,delta: float) -> void:
	if not running() or host.paused: return
	clock += maxf(0,delta)
	# Let the final number settle without running AI or resolving another attack.
	for item in host.tactical.floats: item.life -= maxf(0,delta)
	host.tactical.floats = host.tactical.floats.filter(func(item): return item.life>0)
	if phase=="hold" and clock>=HOLD:
		clock -= HOLD; phase = "out"
	if phase=="out":
		Stage.cover(host,smoothstep(0,FADE,clock))
		if clock>=FADE:
			# The incoming scene is prepared while fully covered. Emit exactly once.
			phase = "in"; clock = 0
			Stage.cover(host,1)
			host.lesson_completed.emit(success)
		return
	if phase=="in":
		Stage.cover(host,1.0-smoothstep(0,FADE,clock))
		if clock>=FADE: phase = "idle"; clock = 0; Stage.cover(host,0)
func draw(host) -> void:
	var border := Color("e2b66c") if duel else (Color("78c5af") if success else Color("df8370"))
	host.panel(Rect2(16,408,928,118),Color("102c37"),border)
	host.centered(title,447,22,border)
	host.centered(detail,480,14,Color("eddfbb"))
	host.centered("A regressar à história…" if running() else "Encontro terminado",510,11,Color("9db3af"))
