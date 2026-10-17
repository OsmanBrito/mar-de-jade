extends RefCounted
## Authored paths with the existing directional walk atlas; feet drive the gait.
static func along(actor: Node2D,points: Array[Vector2],owner: Node,speed: float = 70.0,delay: float = 0.0) -> Tween:
	var tween := owner.create_tween()
	if delay>0: tween.tween_interval(delay)
	var start := actor.position
	for destination in points:
		var origin := start
		var finish := destination
		tween.tween_method(func(weight: float):
			var position: Vector2 = origin.lerp(finish,weight)
			var movement: Vector2 = position-actor.position
			actor.position = position
			if movement.length()>0.0001:
				actor.walking = true
				actor.facing = (3 if movement.x>0 else 1) if absf(movement.x)>absf(movement.y)*1.15 else (0 if movement.y>0 else 2)
				actor.frame_time = fposmod(actor.frame_time+movement.length()/13.0,3.0)
				actor.queue_redraw(),0.0,1.0,maxf(0.08,origin.distance_to(finish)/speed))
		start = destination
	tween.tween_callback(func(): actor.walking = false; actor.queue_redraw())
	return tween
