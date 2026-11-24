extends Node2D
## Gold outline behind a character in focus: the host's silhouette in a flat colour,
## offset in eight directions. Drawn behind its parent (show_behind_parent).
var host: Node2D
func _ready() -> void:
	show_behind_parent = true
	var flat := ShaderMaterial.new(); flat.shader = preload("res://assets/shaders/flat_rim.gdshader")
	material = flat
func _process(_delta: float) -> void:
	var pulse := 0.75+0.25*sin(Time.get_ticks_msec()*0.005)
	(material as ShaderMaterial).set_shader_parameter("rim",Color(0.96,0.84,0.55,0.95*pulse))
	queue_redraw()
func _draw() -> void:
	if host != null: host.draw_silhouette(self,2.2)
