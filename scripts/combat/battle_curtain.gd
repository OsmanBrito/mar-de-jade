extends ColorRect
## Lives in the outer viewport, above the arena and the incoming dialogue.
func _input(_event: InputEvent) -> void:
	if visible: get_viewport().set_input_as_handled()
