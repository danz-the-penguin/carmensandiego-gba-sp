extends Control
## Main Coordinator Scene: Handles Scene Switches & Optional GBA SP Post-Processing

@onready var scene_container: Control = $SceneContainer
var current_subscene: Node = null

func _ready() -> void:
	GameManager.case_started.connect(_on_case_started)
	GameManager.case_resolved.connect(_on_case_resolved)
	load_title_screen()

func load_title_screen() -> void:
	GameManager.current_state = GameManager.State.TITLE
	_switch_scene(preload("res://scenes/title_screen.tscn").instantiate())

func _on_case_started() -> void:
	_switch_scene(preload("res://scenes/city_hub.tscn").instantiate())

func _on_case_resolved(is_victory: bool, message: String) -> void:
	await get_tree().create_timer(3.5).timeout
	load_title_screen()

func _switch_scene(new_scene: Node) -> void:
	if current_subscene:
		current_subscene.queue_free()
	current_subscene = new_scene
	scene_container.add_child(new_scene)
