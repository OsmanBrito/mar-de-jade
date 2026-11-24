extends Control
## Standalone review of the Blender-authored public duel, without campaign writes.
const MOVIE := "res://assets/cinematics/leonor-praca.ogv"
var player: VideoStreamPlayer
var toggle: Button
var progress: ProgressBar
var clock: Label

func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("101b19")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var fit := AspectRatioContainer.new()
	fit.ratio = 16.0 / 9.0
	fit.stretch_mode = AspectRatioContainer.STRETCH_FIT
	fit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fit.offset_bottom = -62
	add_child(fit)
	player = VideoStreamPlayer.new()
	player.expand = true
	player.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var preferences = get_node_or_null("/root/GamePreferences")
	if preferences != null: player.bus = preferences.effects_bus
	player.volume_db = -3
	fit.add_child(player)
	var bar := HBoxContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_left = 18
	bar.offset_right = -18
	bar.offset_top = -52
	bar.offset_bottom = -12
	bar.add_theme_constant_override("separation", 16)
	add_child(bar)
	toggle = Button.new()
	toggle.text = "Pausar · Espaço"
	toggle.custom_minimum_size.x = 175
	toggle.pressed.connect(pause_movie)
	bar.add_child(toggle)
	var replay := Button.new()
	replay.text = "Rever · R"
	replay.pressed.connect(restart)
	bar.add_child(replay)
	progress = ProgressBar.new()
	progress.max_value = 16.0
	progress.show_percentage = false
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	progress.custom_minimum_size.y = 8
	var track := StyleBoxFlat.new()
	track.bg_color = Color("283a34")
	progress.add_theme_stylebox_override("background", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("95b7a6")
	progress.add_theme_stylebox_override("fill", fill)
	bar.add_child(progress)
	clock = Label.new()
	clock.custom_minimum_size.x = 95
	bar.add_child(clock)
	var leave := Button.new()
	leave.text = "Fechar · Esc"
	leave.pressed.connect(func(): get_tree().quit())
	bar.add_child(leave)
	if not ResourceLoader.exists(MOVIE):
		clock.text = "Vídeo ausente"
		toggle.disabled = true
		replay.disabled = true
		return
	player.stream = load(MOVIE)
	player.finished.connect(func(): toggle.text = "Rever · Espaço")
	player.play()

func _process(_delta: float) -> void:
	if not is_instance_valid(player): return
	progress.value = player.stream_position
	clock.text = "%04.1f / 16 s" % minf(player.stream_position, 16.0)

func pause_movie() -> void:
	if player.paused:
		player.paused = false
	elif player.is_playing():
		player.paused = true
	else:
		restart()
		return
	toggle.text = "Continuar · Espaço" if player.paused else "Pausar · Espaço"

func restart() -> void:
	player.stop()
	player.paused = false
	player.play()
	toggle.text = "Pausar · Espaço"

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo(): return
	if event.is_action("ui_cancel"):
		get_tree().quit()
	elif event is InputEventKey and event.keycode == KEY_SPACE:
		pause_movie()
	elif event is InputEventKey and event.keycode == KEY_R:
		restart()
