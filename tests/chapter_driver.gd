extends RefCounted
func drive(host) -> void:
	var b = host.combat
	var v = host.tactical
	if v.phase in ["choose","move","aim"] and v.is_player():
		if v.phase != "choose": v.cancel()
		if b.current().acted:
			v.start_facing(); v.facing = b.suggested_facing(b.current_id); v.confirm(); return
		if b.mode == "adult_basic" and not b.moved_in_battle:
			var destination: Vector2i = b.current().cell
			var nearest := 999
			for cell in b.reachable(b.current_id).costs:
				if cell==b.current().cell or b.path_to(b.current_id,cell).is_empty(): continue
				if b.distance(cell,b.units[2].cell)<nearest: destination = cell; nearest = b.distance(cell,b.units[2].cell)
			v.select_move(); v.select_cell(destination); v.confirm(); return
		if b.mode in ["adult_defense","perfect_defense"] or (b.mode == "duarte_support" and b.current_id == 0):
			v.start_facing(); v.facing = b.suggested_facing(b.current_id); v.confirm(); return
		var skill := 0
		if b.mode == "duarte_support" and b.current_id == 1: skill = 4
		elif b.mode == "school" and b.previous_action == 0 and b.previous_action_turn == b.current().turns-1: skill = 1
		var aim: Vector2i = b.units[2].cell
		if skill == 4: aim = b.units[0].cell
		if skill == 1 and b.style == "MC": aim = b.current().cell
		if not b.valid_attack(skill,aim):
			var best := Vector2i(-1,-1)
			for cell in b.reachable(b.current_id).costs:
				if b.distance(cell,aim) <= int(b.skill_def(b.current_id,skill).range) and b.distance(cell,aim) > 0:
					best = cell; break
			if best != Vector2i(-1,-1): v.select_move(); v.select_cell(best); v.confirm()
			else: v.start_facing(); v.confirm()
			return
		v.select_skill(skill); v.select_cell(aim); v.confirm()
	elif v.phase.begins_with("timing"):
		v.commit_timing(2 if b.mode == "perfect_defense" or v.phase == "timing_attack" else 1)
	else:
		v.update(2.1)


