extends Node2D
var contacts: Array = []

func contact(point: Vector2,disarm: bool = false) -> void:
	contacts.append({"point":point,"age":0.0,"disarm":disarm})
	queue_redraw()

func _process(delta: float) -> void:
	for item in contacts: item.age += delta
	contacts = contacts.filter(func(item): return item.age<0.3)
	if not contacts.is_empty(): queue_redraw()
	elif is_visible_in_tree(): queue_redraw()

func _draw() -> void:
	for item in contacts:
		var alpha: float = 1.0-item.age/0.3
		var p: Vector2 = item.point
		for i in 4:
			var direction := Vector2.from_angle(i*TAU/4+0.45)
			draw_line(p+direction*3,p+direction*(8+item.age*17),Color(0.9,0.81,0.58,alpha),1.4,true)
