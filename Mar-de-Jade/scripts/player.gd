extends CharacterBody2D
signal moved
var enabled: bool = true
var world: Node2D
var destination_path: PackedVector2Array = PackedVector2Array()
var frame_time: float = 0.0
var facing: int = 0
var walking: bool = false
var sprite: Sprite2D
var camera: Camera2D
var stuck_time: float = 0.0
var camera_zoom: float = 1.25

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 2
	collision_mask = 1
	safe_margin = 1.5
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 12.0
	shape.shape = circle
	shape.position = Vector2.ZERO
	add_child(shape)
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/art/traveller_walk.png")
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.scale = Vector2.ONE * 0.245
	sprite.position.y = -34.0
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.offset = Vector2(0,-100)
	camera.zoom = Vector2.ONE * camera_zoom
	add_child(camera)
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2(0,-1),0,Vector2(1,0.42))
	draw_circle(Vector2.ZERO,16,Color(0.035,0.08,0.065,0.28))
	draw_set_transform(Vector2.ZERO)

func _physics_process(delta: float) -> void:
	var direction = Vector2.ZERO
	if enabled:
		direction = Input.get_vector("move_left","move_right","move_up","move_down")
		if direction.length() > 0.08:
			destination_path.clear()
		elif not destination_path.is_empty():
			var target = destination_path[0]
			if position.distance_to(target) < 8.0:
				destination_path.remove_at(0)
			else:
				direction = (target-position).normalized()
	var speed = 205.0 if Input.is_action_pressed("run") else 140.0
	var has_move_input = direction.length() > 0.08
	velocity = direction * speed
	var old_position = position
	if world != null and not world.is_walkable_point(position + velocity * delta):
		# Permit sliding along the shore; never allow a click target into the river.
		var x_step = position + Vector2(velocity.x,0) * delta
		var y_step = position + Vector2(0,velocity.y) * delta
		if world.is_walkable_point(x_step):
			velocity.y = 0
		elif world.is_walkable_point(y_step):
			velocity.x = 0
		else:
			velocity = Vector2.ZERO
	move_and_slide()
	walking = position.distance_to(old_position) > 0.05
	if has_move_input:
		# Face and animate from the requested direction, even when a collider
		# prevents displacement; this keeps the walk cycle visible on contact.
		if absf(direction.x) > absf(direction.y) * 1.15:
			facing = 3 if direction.x > 0 else 1
		else:
			facing = 0 if direction.y >= 0 else 2
		frame_time = fposmod(frame_time + delta * (7.5 if speed < 200 else 9.5), 3.0)
	else:
		frame_time = 0
	if walking:
		moved.emit()
		stuck_time = 0
	elif not destination_path.is_empty():
		stuck_time += delta
		if stuck_time > 1.2:
			destination_path.clear()
	var column = 1 + int(frame_time) % 3 if has_move_input else 0
	sprite.frame = facing * 4 + column
	camera.zoom = camera.zoom.lerp(Vector2.ONE*camera_zoom,delta*7.0)
	if enabled and world != null and world.has_meta("living_quay"):
		preload("res://scripts/chapter/quay_camera.gd").follow(camera,position,delta)

func follow_path(points: PackedVector2Array) -> void:
	destination_path = points
	stuck_time = 0

func set_zoom(amount: float) -> void:
	camera_zoom = clampf(camera_zoom+amount,0.75,1.3)
