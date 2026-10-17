extends CanvasLayer
## Covered scene handoff, following Maré de Ferro's departure/reveal rhythm.
const DURATION := 0.30
var destination := ""
var phase := "in"
var clock := 0.0
var cover: ColorRect

static func reveal(scene: Node) -> void:
	if scene.get_tree().root.has_node("ChapterTransition"): return
	var transition = load("res://scripts/chapter/scene_transition.gd").new()
	scene.add_child(transition)

static func travel(tree: SceneTree,path: String) -> void:
	if tree.root.has_node("ChapterTransition"): return
	var transition = load("res://scripts/chapter/scene_transition.gd").new()
	transition.name = "ChapterTransition"; transition.destination = path; transition.phase = "out"
	tree.root.add_child(transition)

func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_PAUSABLE
	cover = ColorRect.new(); cover.color = Color("0d2022")
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(cover)
	cover.color.a = 1.0 if phase=="in" else 0.0

func _input(_event: InputEvent) -> void:
	get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	clock += delta
	if phase=="out":
		cover.color.a = smoothstep(0,DURATION,clock)
		if clock>=DURATION:
			phase = "covered"; clock = 0
			var error := get_tree().change_scene_to_file(destination)
			if error!=OK: push_error("Não foi possível abrir a próxima cena: "+destination); queue_free()
	elif phase=="covered":
		var scene := get_tree().current_scene
		if scene!=null and scene.scene_file_path==destination:
			phase = "in"; clock = 0
	else:
		cover.color.a = 1.0-smoothstep(0,DURATION,clock)
		if clock>=DURATION: queue_free()
