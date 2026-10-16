extends "res://scripts/combat/battle_ending.gd"
func begin(host,ok: bool) -> void:
	super.begin(host,ok)
	title = "CONVÉS RECUPERADO" if ok else "A ABORDAGEM FALHOU"
	detail = "Tripulação rendida. Regressar à Botafogo." if ok else "A Botafogo perdeu os seus defensores."
