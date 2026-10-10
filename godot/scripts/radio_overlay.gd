extends Control
## RadioOverlay: Tactile Wiretap Radio Intercept & Oscilloscope Cipher Minigame

signal radio_closed
signal radio_intercept_solved(clue_text: String)

var active: bool = false
var min_freq: float = 88.0
var max_freq: float = 108.0
var current_freq: float = 88.0
var target_freq: float = 94.6

var wave_phase: float = 0.0
var is_locked: bool = false
var has_solved: bool = false
var static_timer: float = 0.0

var full_intercept_text: String = ""
var displayed_text: String = ""
var type_timer: float = 0.0

@onready var title_label: Label = $TopBar/TitleLabel
@onready var dial_label: Label = $DialBox/FreqLabel
@onready var teletype_box: RichTextLabel = $TeletypeBox/Text
@onready var hint_bar: Label = $BottomBar/HintBar

func _ready() -> void:
	visible = false

func start_radio_intercept(city_id: String) -> void:
	active = true
	visible = true
	is_locked = false
	has_solved = false
	current_freq = 88.0
	wave_phase = 0.0
	displayed_text = ""
	
	# Choose target frequency with 1 decimal place (e.g. 96.4 MHz)
	var steps = randi_range(15, 85)
	target_freq = 88.0 + (float(steps) * 0.2)
	
	_generate_intercept_text(city_id)
	
	dial_label.text = "TUNING: %4.1f MHz" % current_freq
	teletype_box.text = "[color=#4b5563]Scanning radio bands for V.I.L.E. covert transmissions...\nUse Left/Right D-Pad to tune frequency needle.[/color]"
	hint_bar.text = "LEFT/RIGHT: TUNE DIAL | [B] CLOSE RECEIVER"
	queue_redraw()

func _generate_intercept_text(city_id: String) -> void:
	var suspect = GameManager.current_criminal
	var trail = GameManager.current_trail
	var next_city_id = ""
	var curr_idx = trail.find(city_id)
	if curr_idx != -1 and curr_idx < trail.size() - 1:
		next_city_id = trail[curr_idx + 1]

	var leads = []
	if next_city_id != "" and Database.CITIES.has(next_city_id):
		var n_city = Database.CITIES[next_city_id]
		leads.append("V.I.L.E. HQ DISPATCH: Operative rendezvous scheduled in %s! Flag details: %s." % [n_city["name"], n_city["flag"]])
		leads.append("INTERCEPTED TELEX: Suspect wired funds converted to %s. Boarded outbound red-eye flight!" % n_city["currency"])

	leads.append("SURVEILLANCE WIRE: Suspect was spotted speeding away in a %s. Ring on hand: %s!" % [suspect.get("vehicle", "Convertible"), suspect.get("feature", "Ruby Ring")])
	leads.append("ENCRYPTED AUDIO: Informant confirms suspect has %s hair and practices %s!" % [suspect.get("hair", "Red"), suspect.get("hobby", "Tennis")])

	full_intercept_text = leads[randi() % leads.size()]

func _process(delta: float) -> void:
	if not active:
		return

	wave_phase += delta * 12.0
	var diff = absf(current_freq - target_freq)
	
	# Tune dial with input
	var tune_speed := 0.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		tune_speed -= 4.5
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		tune_speed += 4.5
		
	if tune_speed != 0.0 and not is_locked:
		current_freq = clampf(current_freq + tune_speed * delta, min_freq, max_freq)
		dial_label.text = "TUNING: %4.1f MHz" % current_freq
		
		static_timer -= delta
		if static_timer <= 0.0:
			SoundManager.play_cursor()
			static_timer = 0.09

	# Check lock condition
	if diff <= 0.25 and not is_locked:
		_lock_signal()

	# Typewriter text if locked
	if is_locked and displayed_text.length() < full_intercept_text.length():
		type_timer += delta
		if type_timer >= 0.025:
			type_timer = 0.0
			displayed_text = full_intercept_text.substr(0, displayed_text.length() + 1)
			teletype_box.text = "[color=#34d399][b]★ SIGNAL LOCKED (%4.1f MHz) ★[/b][/color]\n[color=#fbbf24][b]DECRYPTED V.I.L.E. INTERCEPT:[/b][/color]\n%s" % [target_freq, displayed_text]
			if displayed_text.length() % 3 == 0:
				SoundManager.play_text_blip()
			if displayed_text.length() == full_intercept_text.length():
				hint_bar.text = "PRESS [A] OR SPACE TO STORE INTEL DOSSIER"

	queue_redraw()

func _lock_signal() -> void:
	is_locked = true
	has_solved = true
	SoundManager.play_radio_lock()
	dial_label.text = "★ LOCKED: %4.1f MHz ★" % target_freq

func _input(event: InputEvent) -> void:
	if not active:
		return

	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_B or event.keycode == KEY_ESCAPE)):
		_close_radio()
		get_viewport().set_input_as_handled()
		return
		
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_A or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
		if is_locked and displayed_text.length() >= full_intercept_text.length():
			SoundManager.play_confirm()
			radio_intercept_solved.emit(full_intercept_text)
			_close_radio()
		get_viewport().set_input_as_handled()
		return

func _close_radio() -> void:
	active = false
	visible = false
	SoundManager.play_cancel()
	radio_closed.emit()

func _draw() -> void:
	if not active:
		return

	# CRT Oscilloscope Screen Frame (Upper area)
	var crt_rect := Rect2(140, 60, 1000, 290)
	draw_rect(crt_rect, Color(0.02, 0.05, 0.03, 0.95))
	draw_rect(crt_rect, Color(0.12, 0.35, 0.18, 1.0), false, 2.5)
	
	# Oscilloscope Graticule grid lines
	for x in range(180, 1100, 70):
		draw_line(Vector2(x, 65), Vector2(x, 345), Color(0.06, 0.18, 0.08, 0.6), 1.0)
	for y in range(95, 330, 40):
		draw_line(Vector2(145, y), Vector2(1135, y), Color(0.06, 0.18, 0.08, 0.6), 1.0)
	draw_line(Vector2(145, 205), Vector2(1135, 205), Color(0.10, 0.28, 0.14, 0.9), 2.0)

	# Dynamic Oscilloscope Sine Waveform
	var diff = absf(current_freq - target_freq)
	var points := PackedVector2Array()
	var center_y := 205.0
	var wave_color := Color(0.3, 1.0, 0.45) if is_locked else Color(0.2, 0.65, 0.35)
	if diff <= 0.6 and not is_locked:
		wave_color = Color(0.8, 0.9, 0.3)

	var noise_factor = clampf(diff / 6.0, 0.0, 1.0) * (0.0 if is_locked else 1.0)
	var amp = 70.0 * (1.0 - noise_factor * 0.4)
	var freq_scale = 0.04 + (current_freq - 88.0) * 0.003

	for px in range(150, 1130, 4):
		var t = float(px - 150)
		var s = sin(t * freq_scale + wave_phase) * amp
		var n = randf_range(-35.0, 35.0) * noise_factor
		var py = center_y + s + n
		py = clampf(py, 70.0, 340.0)
		points.append(Vector2(px, py))

	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], wave_color, 2.4)

	# Signal Strength LEDs (5 blocks)
	var bars = 5 if is_locked else clampi(int((1.0 - clampf(diff / 4.0, 0.0, 1.0)) * 5.0), 0, 4)
	for b in range(5):
		var led_rect = Rect2(990 + b * 24, 75, 18, 12)
		var led_col = Color(0.2, 0.9, 0.35) if b < bars else Color(0.08, 0.18, 0.1)
		draw_rect(led_rect, led_col)

	# Radio Dial Bar (Middle area)
	var dial_rect := Rect2(140, 360, 1000, 42)
	draw_rect(dial_rect, Color(0.06, 0.08, 0.12, 0.95))
	draw_rect(dial_rect, Color(0.25, 0.35, 0.50, 1.0), false, 2.0)

	# Frequency Tick Marks
	for f in range(88, 109, 2):
		var ratio = float(f - 88) / 20.0
		var tx = 160.0 + ratio * 960.0
		draw_line(Vector2(tx, 364), Vector2(tx, 386), Color(0.5, 0.65, 0.8), 1.5)

	# Orange Tuning Needle
	var needle_ratio = (current_freq - min_freq) / (max_freq - min_freq)
	var needle_x = 160.0 + needle_ratio * 960.0
	draw_line(Vector2(needle_x, 352), Vector2(needle_x, 410), Color(1.0, 0.35, 0.1), 3.5)
	draw_line(Vector2(needle_x - 4, 352), Vector2(needle_x + 4, 352), Color(1.0, 0.7, 0.2), 2.5)
