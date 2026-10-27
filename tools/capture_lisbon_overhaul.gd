extends "res://tools/capture_lisbon_direction.gd"
## Same live route and camera as the baseline, plus 4:3 and 16:9 windows.
func _initialize() -> void:
	output = "res://.qa-runtime/lisbon-overhaul/after"
	super._initialize()
func shot(label: String) -> void:
	await super.shot(label)
	if label=="interacao-960":
		for size in [Vector2i(1024,768),Vector2i(1920,1080)]:
			root.size = size
			await super.shot("interacao-"+str(size.x))
		root.size = Vector2i(960,600)
