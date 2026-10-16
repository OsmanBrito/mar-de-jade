extends "res://scripts/combat/battle_ending.gd"
func begin(host,ok: bool) -> void:
	super.begin(host,ok)
	title = "CONVÉS RECUPERADO" if ok else "A ABORDAGEM FALHOU"
	detail = "Tripulação rendida. Regressar à Botafogo." if ok else "A Botafogo perdeu os seus defensores."
func draw(host) -> void:
	var border := Color("78c5af") if success else Color("df8370")
	host.panel(Rect2(16,408,928,118),Color("102c37"),border)
	host.centered(title,447,22,border)
	host.centered(detail,480,14,Color("eddfbb"))
	host.centered("A regressar à Botafogo…" if success else "A regressar ao ponto seguro…",510,11,Color("9db3af"))
