extends Control
## ChaseOverlay: Interactive Alleyway Foot Chase & QTE Takedown Minigame

signal chase_completed(success: bool)

var active: bool = false
var stage: int = 0 # 0 = Vault, 1 = Corner/Turn, 2 = Tackle Mash
var stage_timer: float = 0.0
var max_stage_time: float = 2.2

var expected_key: String = "" # "B", "LEFT", "RIGHT", "A"
var mash_count: int = 0
var target_mash: int = 4

var scroll_pos: float = 0.0
var suspect_name: String = ""
var status_message: String = ""
var stage_success: bool = false

@onready var title_label: Label = $TopBar/TitleLabel
@onready var prompt_label: Label = $PromptBox/PromptLabel
@onready var subtext_label: Label = $PromptBox/SubtextLabel
@onready var timer_bar: ColorRect = $PromptBox/TimerBar
@onready var timer_bg: ColorRect = $PromptBox/TimerBg

func _ready() -> void:
	visible = false

func start_chase(criminal: Dictionary) -> void:
	active = true
	visible = true
	stage = 0
	suspect_name = criminal.get("name", "SUSPECT")
	title_label.text = "★ FOOT CHASE: PURSUING %s ★" % suspect_name
	_setup_stage(0)
	queue_redraw()

func _setup_stage(s: int) -> void:
	stage = s
	mash_count = 0
	stage_success = false
	
	if stage == 0:
		expected_key = "B"
		max_stage_time = 2.4
		stage_timer = max_stage_time
		prompt_label.text = "⚡ OBSTACLE: CRATES TOPPLED! ⚡"
		subtext_label.text = "PRESS [B] OR ESC TO VAULT!"
	elif stage == 1:
		expected_key = "LEFT" if (randi() % 2 == 0) else "RIGHT"
		max_stage_time = 2.0
		stage_timer = max_stage_time
		prompt_label.text = "⚡ FORK IN ALLEY: SUSPECT BREAKS %s! ⚡" % expected_key
		subtext_label.text = "PRESS [%s] D-PAD TO CUT OFF ESCAPE!" % expected_key
	elif stage == 2:
		expected_key = "A"
		max_stage_time = 2.5
		stage_timer = max_stage_time
		prompt_label.text = "⚡ DEAD END! SUSPECT SCALING FENCE! ⚡"
		subtext_label.text = "MASH [A] OR SPACE TO TACKLE! (%d/%d)" % [mash_count, target_mash]

func _process(delta: float) -> void:
	if not active:
		return

	scroll_pos += delta * 180.0
	stage_timer -= delta
	
	# Update Timer Bar
	if timer_bar and timer_bg:
		var ratio = clampf(stage_timer / max_stage_time, 0.0, 1.0)
		timer_bar.size.x = timer_bg.size.x * ratio
		timer_bar.color = Color(0.2, 0.9, 0.4) if ratio > 0.4 else Color(1.0, 0.3, 0.3)

	# Timer expired
	if stage_timer <= 0.0:
		_handle_stage_miss()

	queue_redraw()

func _input(event: InputEvent) -> void:
	if not active:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if stage == 0:
			if event.keycode == KEY_B or event.keycode == KEY_ESCAPE:
				_handle_stage_hit()
				get_viewport().set_input_as_handled()
		elif stage == 1:
			if (expected_key == "LEFT" and (event.keycode == KEY_LEFT or event.keycode == KEY_A)) or \
			   (expected_key == "RIGHT" and (event.keycode == KEY_RIGHT or event.keycode == KEY_D)):
				_handle_stage_hit()
				get_viewport().set_input_as_handled()
		elif stage == 2:
			if event.keycode == KEY_A or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
				mash_count += 1
				SoundManager.play_cursor()
				subtext_label.text = "MASH [A] OR SPACE TO TACKLE! (%d/%d)" % [mash_count, target_mash]
				if mash_count >= target_mash:
					_handle_stage_hit()
				get_viewport().set_input_as_handled()

func _handle_stage_hit() -> void:
	SoundManager.play_whoosh()
	stage += 1
	if stage < 3:
		_setup_stage(stage)
	else:
		_finish_chase(true)

func _handle_stage_miss() -> void:
	SoundManager.play_cancel()
	# Stumbled! Deduct 1 hour as penalty
	GameManager.hours_left = maxi(1, GameManager.hours_left - 1)
	GameManager.broadcast_time()
	stage += 1
	if stage < 3:
		_setup_stage(stage)
	else:
		_finish_chase(true)

func _finish_chase(success: bool) -> void:
	active = false
	visible = false
	chase_completed.emit(success)

func _draw() -> void:
	if not active:
		return

	# Alleyway Silhouette & Parallax Brick Walls
	draw_rect(Rect2(0, 32, 480, 256), Color(0.04, 0.05, 0.08, 0.95))
	
	# Streetlamps and brick mortar lines
	for y in range(40, 220, 28):
		draw_line(Vector2(0, y), Vector2(480, y), Color(0.12, 0.14, 0.20, 0.4), 1.0)
	
	# Cobblestones
	draw_rect(Rect2(0, 220, 480, 68), Color(0.08, 0.10, 0.15))
	for cx in range(0, 480, 32):
		var stone_x = fmod(float(cx) - scroll_pos * 0.5, 480.0)
		if stone_x < 0: stone_x += 480.0
		draw_rect(Rect2(stone_x, 230, 28, 12), Color(0.12, 0.15, 0.22, 0.6))

	# Fleeing Suspect Silhouette (Ahead in the distance)
	var suspect_x := 320.0 + sin(scroll_pos * 0.05) * 20.0
	var suspect_y := 170.0
	draw_circle(Vector2(suspect_x, suspect_y - 20), 10.0, Color(0.75, 0.15, 0.2)) # Red coat silhouette
	draw_rect(Rect2(suspect_x - 8, suspect_y - 12, 16, 24), Color(0.1, 0.1, 0.15))
	
	# Pursuing ACME Detective Shadow (Foreground)
	var det_x := 120.0
	var det_y := 185.0
	draw_circle(Vector2(det_x, det_y - 24), 12.0, Color(0.2, 0.4, 0.7))
	draw_rect(Rect2(det_x - 10, det_y - 14, 20, 28), Color(0.15, 0.2, 0.3))
