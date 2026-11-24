extends CanvasLayer
## A brief visual handoff for real doorways; input and campaign state stay with the director.
var elapsed := 0.0
var cover: ColorRect
static func show_place(scene: Node) -> void:
	if DisplayServer.get_name()=="headless": return
	var old := scene.get_node_or_null("PlaceReveal")
	if old!=null: old.free()
	var reveal = load("res://scripts/city/place_reveal.gd").new(); reveal.name = "PlaceReveal"; scene.add_child(reveal)
func _ready() -> void:
	layer = 4
	cover = ColorRect.new(); cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE; cover.color = Color(.055,.085,.075,.8); add_child(cover)
func _process(delta: float) -> void:
	elapsed += delta; cover.color.a = .8*(1-smoothstep(0,.22,elapsed))
	if elapsed>=.22: queue_free()
