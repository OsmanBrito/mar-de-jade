extends RefCounted
## Reuse the actual navigation, footprints and interaction; no position injection.
func reach(game,destination_area: String = "") -> bool:
	for leg in 8:
		if not game.routes.active or game.phase!="roaming": return false
		var at_goal: bool = game.routes.goal_reachable_here()
		if not destination_area.is_empty() and game.routes.area()==destination_area: return true
		var destination: Vector2 = game.routes.goal
		var desired: String = game.routes.goal_area if destination_area.is_empty() else destination_area
		if game.routes.continuous():
			if desired=="room": destination = preload("res://scripts/city/lisbon_layout.gd").ROOM_ENTRY
			elif desired=="convent": destination = preload("res://scripts/city/lisbon_layout.gd").CONVENT_ENTRY
			elif desired=="deck": destination = preload("res://scripts/city/lisbon_layout.gd").BOAT_ENTRY
			elif not destination_area.is_empty(): destination = Vector2(-130,350) if desired=="square" else Vector2(350,1030)
		elif game.routes.area()!=desired:
			var next := "square" if game.routes.area() in ["room","cais","convent"] else "cais"
			if game.routes.area()=="convent" and desired=="room": next = "room"
			if game.routes.area()=="room" and desired=="convent": next = "convent"
			if game.routes.area()=="square" and desired=="room": next = "room"
			if game.routes.area()=="cais" and desired=="deck": next = "deck"
			var found := false
			for exit in game.routes.exits:
				if exit.to==next: destination = exit.point; found = true; break
			if not found: return false
		game.world.walk_to(destination)
		for step in 1800:
			if game.world.player.position.distance_to(destination)<30 and game.world.segment_clear(game.world.player.position,destination): break
			await game.get_tree().physics_frame
			if game.world.player.destination_path.is_empty(): break
		if game.world.player.position.distance_to(destination)>45: return false
		if not destination_area.is_empty() and game.routes.area()==destination_area: return true
		game.routes.interact()
		if game.phase=="boarding": game.routes.board()
		await game.get_tree().process_frame
		if destination_area.is_empty() and at_goal: return true
	return false
