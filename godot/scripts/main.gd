extends Control
## Main Coordinator Scene: Handles Scene Switches & Optional GBA SP Post-Processing

@onready var scene_container: Control = $SceneContainer
var current_subscene: Node = null

func _ready() -> void:
	_apply_window_scale()
	GameManager.case_started.connect(_on_case_started)
	GameManager.case_resolved.connect(_on_case_resolved)
	GameManager.title_requested.connect(load_title_screen)
	load_title_screen()

func _apply_window_scale() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		var screen_rect = DisplayServer.screen_get_usable_rect()
		# Standard 1280x720 HD 16:9 window scale
		var target_size = Vector2i(1280, 720)
		if screen_rect.size.y >= 1200 and screen_rect.size.x >= 2000:
			target_size = Vector2i(1920, 1080)
		
		DisplayServer.window_set_size(target_size)
		DisplayServer.window_set_position(screen_rect.position + (screen_rect.size - target_size) / 2)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_F and (event.ctrl_pressed or event.meta_pressed)):
			var mode = DisplayServer.window_get_mode()
			if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				_apply_window_scale()
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F1:
			_set_window_size(Vector2i(1280, 720))
		elif event.keycode == KEY_F2:
			_set_window_size(Vector2i(1920, 1080))
		elif event.keycode == KEY_F3:
			_set_window_size(Vector2i(2560, 1440))

func _set_window_size(target_size: Vector2i) -> void:
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var screen_rect = DisplayServer.screen_get_usable_rect()
	DisplayServer.window_set_size(target_size)
	DisplayServer.window_set_position(screen_rect.position + (screen_rect.size - target_size) / 2)

func load_title_screen() -> void:
	GameManager.current_state = GameManager.State.TITLE
	_switch_scene(preload("res://scenes/title_screen.tscn").instantiate())

func _on_case_started() -> void:
	_switch_scene(preload("res://scenes/city_hub.tscn").instantiate())

func _on_case_resolved(is_victory: bool, message: String) -> void:
	await get_tree().create_timer(8.0).timeout
	if GameManager.current_state in [GameManager.State.ARREST, GameManager.State.GAMEOVER]:
		load_title_screen()

func _switch_scene(new_scene: Node) -> void:
	if current_subscene:
		current_subscene.queue_free()
	current_subscene = new_scene
	scene_container.add_child(new_scene)
