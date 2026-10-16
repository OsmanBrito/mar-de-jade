extends "res://scripts/combat/portugal_field.gd"
func snapshot(view) -> Dictionary:
	var state: Dictionary = super.snapshot(view)
	if state.reason=="Um banco bloqueia esta casa.": state.reason = "O mastro ou a carga bloqueiam esta casa."
	for cell in state.range.keys():
		if not view.model.inside(cell): state.range.erase(cell)
	return state
