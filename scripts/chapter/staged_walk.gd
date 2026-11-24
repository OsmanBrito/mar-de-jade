extends RefCounted
## Authored paths with the existing directional walk atlas; feet drive the gait.
static func along(actor: Node2D,points: Array[Vector2],owner: Node,speed: float = 70.0,delay: float = 0.0) -> Tween:
	var tween := owner.create_tween().bind_node(actor)
	var actor_ref: WeakRef = weakref(actor)
	if delay>0: tween.tween_interval(delay)
	var start := actor.position
	for destination in points:
		var origin := start
		var finish := destination
		tween.tween_method(func(weight: float):
			var subject = actor_ref.get_ref()
			if subject==null: return
			var position: Vector2 = origin.lerp(finish,weight)
			var movement: Vector2 = position-subject.position
			subject.position = position
			if movement.length()>0.0001:
				subject.walking = true
				subject.facing = (3 if movement.x>0 else 1) if absf(movement.x)>absf(movement.y)*1.15 else (0 if movement.y>0 else 2)
				var visual=subject.get("presentation")
				var child:bool=is_instance_valid(visual) and visual.get("identity")=="hero_child"
				subject.frame_time = fposmod(subject.frame_time+movement.length()/(21.0 if child else 13.0),3.0)
				if is_instance_valid(visual):
					visual.walking=true;visual.facing=subject.facing;visual.frame_time=subject.frame_time;visual.queue_redraw()
				subject.queue_redraw(),0.0,1.0,maxf(0.08,origin.distance_to(finish)/speed))
		start = destination
	tween.tween_callback(func():
		var subject = actor_ref.get_ref()
		if subject!=null:
			subject.walking = false; subject.queue_redraw()
			var visual=subject.get("presentation")
			if is_instance_valid(visual):visual.walking=false;visual.queue_redraw())
	return tween
