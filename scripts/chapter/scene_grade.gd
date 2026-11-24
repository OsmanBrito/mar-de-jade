extends CanvasLayer
## Light and colour per place. Sits on layer 0, above the world and below the
## dialogue/HUD layers, so the interface is never tinted.
const SHADER := preload("res://assets/shaders/scene_grade.gdshader")
const PRESETS := {
	# Shelter: indoor warmth, window light from the upper left, deep corners.
	"interior": {"shadow_tint":Vector3(0.86,0.84,0.86),"highlight_tint":Vector3(1.08,1.0,0.86),"contrast":1.08,
		"saturation":1.02,"exposure":1.0,"light_from":Vector2(-0.75,-0.65),"light_strength":0.16,
		"light_color":Vector3(1.0,0.84,0.6),"vignette":0.55,"vignette_color":Vector3(0.06,0.045,0.03)},
	# Square: clear Lisbon morning, cool shade, warm stone.
	"square": {"shadow_tint":Vector3(0.9,0.96,1.03),"highlight_tint":Vector3(1.05,1.01,0.93),"contrast":1.07,
		"saturation":1.06,"exposure":1.0,"light_from":Vector2(-0.6,-0.8),"light_strength":0.11,
		"light_color":Vector3(1.0,0.93,0.78),"vignette":0.32,"vignette_color":Vector3(0.05,0.065,0.07)},
	# Quay: river light, teal in the shadows.
	"harbor": {"shadow_tint":Vector3(0.88,0.97,1.02),"highlight_tint":Vector3(1.04,1.01,0.95),"contrast":1.06,
		"saturation":1.05,"exposure":1.01,"light_from":Vector2(-0.5,-0.85),"light_strength":0.10,
		"light_color":Vector3(1.0,0.95,0.84),"vignette":0.28,"vignette_color":Vector3(0.04,0.07,0.075)},
	# Departure: late golden light from the west, violet shade on the water.
	"departure": {"shadow_tint":Vector3(0.9,0.88,1.0),"highlight_tint":Vector3(1.07,0.99,0.86),"contrast":1.07,
		"saturation":1.0,"exposure":0.99,"light_from":Vector2(-0.95,-0.3),"light_strength":0.14,
		"light_color":Vector3(1.0,0.78,0.5),"vignette":0.4,"vignette_color":Vector3(0.07,0.05,0.07)},
}
var preset := "square"

static func install(world: Node,name: String) -> void:
	var existing := world.get_node_or_null("LuzDaCena")
	if existing != null: existing.free()
	var grade := CanvasLayer.new(); grade.set_script(load("res://scripts/chapter/scene_grade.gd"))
	grade.name = "LuzDaCena"; grade.preset = name
	world.add_child(grade)

func _ready() -> void:
	layer = 0
	var rect := ColorRect.new(); rect.name = "Gradacao"
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new(); material.shader = SHADER
	for key in PRESETS[preset]: material.set_shader_parameter(key,PRESETS[preset][key])
	rect.material = material
	add_child(rect)
