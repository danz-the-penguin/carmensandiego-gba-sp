extends Control
## Title Screen: Animated Carmen Silhouette, Mode Selection & Custom Seed Dialog

@onready var btn_career: Button = $MenuBox/BtnCareer
@onready var btn_daily: Button = $MenuBox/BtnDaily
@onready var btn_custom: Button = $MenuBox/BtnCustom
@onready var stats_label: Label = $StatsLabel

@onready var seed_dialog: Panel = $SeedDialog
@onready var seed_input: LineEdit = $SeedDialog/SeedInput
@onready var btn_start_custom: Button = $SeedDialog/BtnStartCustom
@onready var btn_paste_clip: Button = $SeedDialog/BtnPasteClip
@onready var btn_cancel_seed: Button = $SeedDialog/BtnCancelSeed

var menu_buttons: Array[Button] = []
var current_menu_index: int = 0

func _ready() -> void:
	var agency_label = get_node_or_null("TitleBox/AgencyTag")
	if agency_label:
		agency_label.text = "RANK: %s | CASES SOLVED: %d" % [GameManager.current_rank["title"], GameManager.cases_solved]

	menu_buttons = [btn_career, btn_daily, btn_custom]

	btn_career.pressed.connect(func(): _select_mode(0))
	btn_daily.pressed.connect(func(): _select_mode(1))
	btn_custom.pressed.connect(func(): _select_mode(2))

	btn_start_custom.pressed.connect(_on_start_custom_pressed)
	btn_paste_clip.pressed.connect(_on_paste_clip_pressed)
	btn_cancel_seed.pressed.connect(_close_seed_dialog)
	seed_input.text_submitted.connect(func(_t): _on_start_custom_pressed())

	_update_stats_display()
	_update_menu_focus()

func _update_stats_display() -> void:
	var best_str = GameManager.format_speedrun_time(GameManager.best_speedrun_time) if GameManager.best_speedrun_time < 999999.0 else "--:--.-"
	var today_str = Time.get_date_string_from_system()
	var daily_status = "AVAILABLE [READY]"
	if GameManager.is_today_daily_completed():
		var rec = GameManager.get_today_daily_record()
		daily_status = "COMPLETED (%s)" % rec.get("formatted", "DONE")
	stats_label.text = "★ BEST SPEEDRUN: %s   |   📅 DAILY CHALLENGE (%s): %s" % [best_str, today_str, daily_status]

func _update_menu_focus() -> void:
	if current_menu_index >= 0 and current_menu_index < menu_buttons.size():
		menu_buttons[current_menu_index].grab_focus()

func _input(event: InputEvent) -> void:
	if seed_dialog.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_close_seed_dialog()
			get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			_select_mode(0)
			return
		elif event.keycode == KEY_2:
			_select_mode(1)
			return
		elif event.keycode == KEY_3:
			_select_mode(2)
			return

	if event.is_action_pressed("ui_up"):
		current_menu_index = posmod(current_menu_index - 1, menu_buttons.size())
		SoundManager.play_cursor()
		_update_menu_focus()
	elif event.is_action_pressed("ui_down"):
		current_menu_index = posmod(current_menu_index + 1, menu_buttons.size())
		SoundManager.play_cursor()
		_update_menu_focus()
	elif event.is_action_pressed("gba_start"):
		_select_mode(current_menu_index)

func _select_mode(mode_idx: int) -> void:
	current_menu_index = mode_idx
	SoundManager.play_confirm()
	match mode_idx:
		0:
			GameManager.start_new_case()
		1:
			GameManager.start_daily_case()
		2:
			_open_seed_dialog()

func _open_seed_dialog() -> void:
	seed_dialog.visible = true
	var rand_code = "#ACME-%04d" % (randi() % 10000)
	seed_input.text = rand_code
	seed_input.grab_focus()
	seed_input.select_all()

func _close_seed_dialog() -> void:
	seed_dialog.visible = false
	SoundManager.play_cancel()
	_update_menu_focus()

func _on_paste_clip_pressed() -> void:
	var clip = DisplayServer.clipboard_get()
	if not clip.is_empty():
		seed_input.text = clip.strip_edges()
	SoundManager.play_confirm()

func _on_start_custom_pressed() -> void:
	var s = seed_input.text.strip_edges()
	if s.is_empty():
		s = "#ACME-%04d" % (randi() % 10000)
	seed_dialog.visible = false
	SoundManager.play_confirm()
	GameManager.start_new_case(s)
