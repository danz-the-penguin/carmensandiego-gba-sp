extends Control
## Title Screen: Animated Carmen Fedora Silhouette & Press Start

@onready var press_start_label: Label = $PressStartLabel
var blink_timer: float = 0.0

func _ready() -> void:
	var agency_label = get_node_or_null("TitleBox/AgencyTag")
	if agency_label:
		agency_label.text = "RANK: %s | CASES SOLVED: %d" % [GameManager.current_rank["title"], GameManager.cases_solved]

func _process(delta: float) -> void:
	blink_timer += delta
	if press_start_label:
		press_start_label.visible = fmod(blink_timer, 0.8) < 0.5

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("gba_start") or event.is_action_pressed("gba_a") or event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		SoundManager.play_confirm()
		GameManager.start_new_case()
