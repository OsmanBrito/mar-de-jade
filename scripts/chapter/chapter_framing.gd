extends Node
## Intimate conversations use their own camera; exploration keeps the original controller.
var camera: Camera2D
var subjects: Array = []
var zoom := 1.6
var bias := Vector2(0,-5)
static func install(director: Node,people: Array,scale_value: float = 1.6) -> Node:
	var framing := Node.new(); framing.set_script(load("res://scripts/chapter/chapter_framing.gd"))
	framing.name = "ConversationFraming"; framing.subjects = people; framing.zoom = scale_value
	director.add_child(framing)
	framing.camera = Camera2D.new(); framing.camera.name = "ConversationCamera"
	framing.camera.zoom = Vector2.ONE*scale_value
	director.add_child(framing.camera)
	framing.camera.global_position = framing.target()
	framing.camera.make_current()
	return framing

func target() -> Vector2:
	var center := Vector2.ZERO; var count := 0
	for person in subjects:
		if is_instance_valid(person) and person.is_visible_in_tree():
			center += person.global_position; count += 1
	return center/maxi(1,count)+bias

func _process(delta: float) -> void:
	if camera == null or not camera.enabled or get_tree().paused: return
	camera.global_position = camera.global_position.lerp(target(),1.0-exp(-delta*4.0))

func activate(value: bool) -> void:
	camera.enabled = value
	if value: camera.make_current()
