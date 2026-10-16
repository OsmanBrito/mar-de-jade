extends RefCounted
## Mar de Ferro's Lisbon framing: architecture on the street, footings and boat on the pier.
## Convert this map's 2:1 coordinates before blending; never move the authored walking plane.
static func offset_at(point: Vector2) -> Vector2:
	var local := point-Vector2(192,352)
	var towards_river := local.x*0.5+local.y
	return Vector2(0,lerpf(-100,80,smoothstep(850,1050,towards_river)))
static func follow(camera: Camera2D,point: Vector2,delta: float) -> void:
	camera.offset = camera.offset.lerp(offset_at(point),1.0-exp(-delta*4.0))
