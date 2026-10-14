extends Control
## City Hub: 480x320 World City Exploration, Witness Questioning & Flight Routing

@onready var city_title_label: Label = $SkylineView/CityBanner/CityTitle
@onready var city_landmark_label: Label = $SkylineView/CityBanner/CityLandmark
@onready var skyline_sprite: TextureRect = $SkylineView/SkylineSprite
@onready var city_status_label: Label = $StatusBar/HBox/CityLabel
@onready var trail_label: Label = $StatusBar/HBox/TrailLabel
@onready var clock_label: Label = $StatusBar/HBox/ClockLabel
@onready var hours_label: Label = $StatusBar/HBox/HoursLabel
@onready var speedrun_label: Label = $StatusBar/HBox/SpeedrunLabel

@onready var portrait_rect: TextureRect = $DialogBox/PortraitFrame/Portrait
@onready var speaker_label: Label = $DialogBox/SpeakerLabel
@onready var dialog_label: RichTextLabel = $DialogBox/DialogLabel

@onready var btn_investigate: Button = $ActionMenu/BtnInvestigate
@onready var btn_depart: Button = $ActionMenu/BtnDepart
@onready var btn_computer: Button = $ActionMenu/BtnComputer
@onready var btn_dossier: Button = $ActionMenu/BtnDossier
@onready var btn_radio: Button = $ActionMenu/BtnRadio
@onready var btn_inspect: Button = $ActionMenu/BtnInspect

@onready var inspect_overlay: Control = $InspectOverlay
@onready var radio_overlay: Control = $RadioOverlay
@onready var chase_overlay: Control = $ChaseOverlay
@onready var trap_overlay: Control = $TrapOverlay
@onready var museum_overlay: Control = $MuseumOverlay



@onready var subscreen_panel: Panel = $SubscreenOverlay
@onready var subscreen_title: Label = $SubscreenOverlay/Header/TitleLabel
@onready var subscreen_list: VBoxContainer = $SubscreenOverlay/Scroll/ItemList

@onready var flight_overlay: Panel = $FlightOverlay
@onready var flight_route: Label = $FlightOverlay/RadarBox/FlightRoute
@onready var flight_status: Label = $FlightOverlay/RadarBox/FlightStatus

@onready var weather_overlay: Control = $SkylineView/WeatherOverlay
@onready var flash_overlay: ColorRect = $FlashOverlay
@onready var arrest_overlay: Panel = $ArrestOverlay
@onready var arrest_portrait: TextureRect = $ArrestOverlay/Card/PortraitBox/Portrait
@onready var arrest_details: RichTextLabel = $ArrestOverlay/Card/DetailsLabel
@onready var arrest_stamp: Label = $ArrestOverlay/Card/StampLabel
@onready var arrest_hint: Label = $ArrestOverlay/Card/ContinueHint

var action_buttons: Array[Button] = []
var current_menu_index: int = 0
var subscreen_mode: String = ""
var subscreen_index: int = 0
var subscreen_data: Array = []

var is_typing: bool = false
var typewriter_timer: float = 0.0
var current_speaker_id: String = "chief"
var portrait_material: ShaderMaterial
var blink_timer: float = 0.0
var blink_next: float = 3.5
var is_blinking: bool = false
var mouth_timer: float = 0.0
var is_mouth_open: bool = false
var is_case_ended: bool = false
var _alert_regexes: Array[RegEx] = []
var _trait_regexes: Array[RegEx] = []

var shake_timer: float = 0.0
var shake_intensity: float = 0.0
var original_pos: Vector2 = Vector2.ZERO

const FILTER_SEX = ["ANY", "Female", "Male"]
const FILTER_HAIR = ["ANY", "Red", "Black", "Blonde", "Brown"]
const FILTER_VEHICLE = ["ANY", "Convertible", "Motorcycle", "Limousine"]
const FILTER_HOBBY = ["ANY", "Tennis", "Mountain Climbing", "Croquet", "Bowling", "Skydiving", "Sailing", "Scuba Diving"]
const FILTER_FEATURE = ["ANY", "Ruby Ring", "Tattoo", "Monocle", "Gold Watch", "Gold Locket", "Eyepatch", "Scar", "Cane"]

const CITY_PALETTES = {
	"london": Color(0.09, 0.12, 0.18),
	"paris": Color(0.16, 0.10, 0.22),
	"rome": Color(0.18, 0.13, 0.10),
	"athens": Color(0.08, 0.14, 0.24),
	"cairo": Color(0.24, 0.16, 0.08),
	"nairobi": Color(0.14, 0.18, 0.10),
	"tokyo": Color(0.12, 0.07, 0.22),
	"beijing": Color(0.18, 0.09, 0.10),
	"kathmandu": Color(0.10, 0.15, 0.22),
	"sydney": Color(0.07, 0.14, 0.22),
	"newyork": Color(0.08, 0.10, 0.18),
	"sanfrancisco": Color(0.10, 0.15, 0.20),
	"mexicocity": Color(0.18, 0.12, 0.09),
	"rio": Color(0.06, 0.16, 0.20),
	"moscow": Color(0.12, 0.11, 0.20),
	"reykjavik": Color(0.05, 0.18, 0.16)
}

func _ready() -> void:
	action_buttons = [btn_investigate, btn_depart, btn_computer, btn_dossier, btn_radio, btn_inspect]

	btn_investigate.pressed.connect(func(): _activate_menu_slot(0))
	btn_depart.pressed.connect(func(): _activate_menu_slot(1))
	btn_computer.pressed.connect(func(): _activate_menu_slot(2))
	btn_dossier.pressed.connect(func(): _activate_menu_slot(3))
	btn_radio.pressed.connect(func(): _activate_menu_slot(4))
	btn_inspect.pressed.connect(func(): _activate_menu_slot(5))

	inspect_overlay.evidence_discovered.connect(_on_evidence_discovered)
	inspect_overlay.inspection_closed.connect(_on_overlay_closed)
	radio_overlay.radio_intercept_solved.connect(_on_radio_solved)
	radio_overlay.radio_closed.connect(_on_overlay_closed)
	chase_overlay.chase_completed.connect(_on_chase_completed)
	trap_overlay.trap_resolved.connect(_on_trap_resolved)
	museum_overlay.museum_closed.connect(_on_overlay_closed)

	GameManager.city_changed.connect(_on_city_changed)
	GameManager.time_updated.connect(_on_time_updated)
	GameManager.clue_found.connect(_on_clue_found)
	GameManager.case_resolved.connect(_on_case_resolved)

	original_pos = position

	# Initialize procedural animated portrait shader material
	var anim_shader = load("res://shaders/portrait_anim.gdshader")
	if anim_shader:
		portrait_material = ShaderMaterial.new()
		portrait_material.shader = anim_shader
		portrait_material.set_shader_parameter("idle_breath", 1.0)
		portrait_material.set_shader_parameter("mouth_open", 0.0)
		portrait_material.set_shader_parameter("eye_blink", 0.0)
		portrait_rect.material = portrait_material

	if Database.CITIES.has(GameManager.current_city_id):
		_update_city_view(Database.CITIES[GameManager.current_city_id])
	GameManager.broadcast_time()
	_update_trail_heat()
	_update_menu_highlight()

	# Display opening ACME briefing
	var start_city = Database.CITIES.get(GameManager.current_city_id, {})
	var city_name = start_city.get("name", "the city")
	show_dialog("[ACME CHIEF]", "URGENT BRIEFING: %s was stolen from %s! You have %d hours to track down the suspect and secure a warrant!" % [GameManager.current_treasure, city_name, GameManager.hours_left], "chief")

func _process(delta: float) -> void:
	if speedrun_label and GameManager.speedrun_active:
		speedrun_label.text = "⏱ " + GameManager.format_speedrun_time(GameManager.speedrun_elapsed)

	if shake_timer > 0.0:
		shake_timer -= delta
		position = original_pos + Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		if shake_timer <= 0.0:
			position = original_pos

	# Dynamic eye-blink loop (every 2.8 - 4.8s for 120ms)
	blink_timer += delta
	if not is_blinking:
		if blink_timer >= blink_next:
			is_blinking = true
			blink_timer = 0.0
			if portrait_material:
				portrait_material.set_shader_parameter("eye_blink", 1.0)
	else:
		if blink_timer >= 0.12:
			is_blinking = false
			blink_timer = 0.0
			blink_next = randf_range(2.8, 4.8)
			if portrait_material:
				portrait_material.set_shader_parameter("eye_blink", 0.0)

	if is_typing:
		typewriter_timer += delta
		mouth_timer += delta
		# Rhythmic talking mouth flap (every 85ms)
		if mouth_timer >= 0.085:
			mouth_timer = 0.0
			is_mouth_open = not is_mouth_open
			if portrait_material:
				portrait_material.set_shader_parameter("mouth_open", 1.0 if is_mouth_open else 0.0)

		if typewriter_timer >= 0.02:
			typewriter_timer = 0.0
			var total = dialog_label.get_total_character_count()
			if total > 0:
				if dialog_label.visible_characters < total:
					dialog_label.visible_characters += 1
					if dialog_label.visible_characters % 2 == 0:
						SoundManager.play_text_blip(current_speaker_id)
					# 2010s Handheld Talking Bob / Flap
					portrait_rect.position.y = 3.0 if (dialog_label.visible_characters % 4 in [1, 2]) else 4.0
				else:
					is_typing = false
					portrait_rect.position.y = 4.0
					if portrait_material:
						portrait_material.set_shader_parameter("mouth_open", 0.0)
	else:
		portrait_rect.position.y = 4.0
		if portrait_material and portrait_material.get_shader_parameter("mouth_open") > 0.0:
			portrait_material.set_shader_parameter("mouth_open", 0.0)

func _input(event: InputEvent) -> void:
	if flight_overlay.visible or inspect_overlay.visible or radio_overlay.visible or chase_overlay.visible or trap_overlay.visible or museum_overlay.visible:
		return

	if is_case_ended:
		if is_typing:
			if event.is_action_pressed("gba_a") or event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
				dialog_label.visible_characters = -1
				is_typing = false
				if portrait_material:
					portrait_material.set_shader_parameter("mouth_open", 0.0)
		else:
			if event.is_action_pressed("gba_a") or event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
				GameManager.return_to_title()
		return

	# Fast-forward typewriter if still animating
	if is_typing:
		if event.is_action_pressed("gba_a") or event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
			dialog_label.visible_characters = -1
			is_typing = false
			if portrait_material:
				portrait_material.set_shader_parameter("mouth_open", 0.0)
			return

	if event.is_action_pressed("gba_l"):
		SoundManager.play_shoulder()
		if subscreen_panel.visible and subscreen_mode == "dossier":
			close_subscreen()
		else:
			open_dossier()
		return
	if event.is_action_pressed("gba_r"):
		SoundManager.play_shoulder()
		if subscreen_panel.visible and subscreen_mode == "computer":
			close_subscreen()
		else:
			open_crime_computer()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_G:
			if subscreen_panel.visible and subscreen_mode == "gadgets":
				close_subscreen()
			else:
				open_gadgets()
			return
		elif event.keycode == KEY_V:
			if museum_overlay.visible:
				museum_overlay.close_museum()
			else:
				open_museum()
			return
		elif event.keycode == KEY_C:
			var sh = GameManager.cycle_shell()
			show_dialog("[GBA SP CHASSIS]", "Custom GBA SP Shell switched to %s! Saved to detective profile." % sh["name"], "chief")
			return
		elif event.keycode == KEY_P:
			if subscreen_panel.visible and subscreen_mode == "present_evidence":
				close_subscreen()
			else:
				open_present_evidence()
			return
		elif event.keycode == KEY_U:
			open_document_inspection()
			return
		elif event.keycode == KEY_N:
			if subscreen_panel.visible and subscreen_mode == "informant":
				close_subscreen()
			else:
				open_informant_negotiation()
			return
		elif event.keycode == KEY_T:
			if inspect_overlay.visible and inspect_overlay.current_mode == inspect_overlay.Mode.LOCKPICK:
				inspect_overlay.visible = false
				inspect_overlay.active = false
			else:
				open_lockpick_simulator()
			return
		elif event.keycode == KEY_O:
			if subscreen_panel.visible and subscreen_mode == "speedrun":
				close_subscreen()
			else:
				open_speedrun_splits()
			return
		elif event.keycode == KEY_K:
			GameManager.copy_seed_to_clipboard()
			SoundManager.play_confirm()
			show_dialog("[ACME SEED DISPATCH]", "Case Seed Code '%s' copied to system clipboard! Share with fellow detectives." % GameManager.current_case_seed, "chief")
			return

	if subscreen_panel.visible:
		if event.is_action_pressed("ui_up"):
			subscreen_index = posmod(subscreen_index - 1, subscreen_data.size())
			SoundManager.play_cursor()
			_update_subscreen_selection()
		elif event.is_action_pressed("ui_down"):
			subscreen_index = posmod(subscreen_index + 1, subscreen_data.size())
			SoundManager.play_cursor()
			_update_subscreen_selection()
		elif (event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right")) and subscreen_mode == "computer" and subscreen_index < 5:
			var dir = -1 if event.is_action_pressed("ui_left") else 1
			_cycle_filter(subscreen_index, dir)
			_refresh_computer_labels()
			SoundManager.play_cursor()
		elif event.is_action_pressed("gba_a") or event.is_action_pressed("ui_accept"):
			_confirm_subscreen(subscreen_index)
		elif event.is_action_pressed("gba_b") or event.is_action_pressed("ui_cancel"):
			close_subscreen()
	else:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_1:
				_activate_menu_slot(0)
				return
			elif event.keycode == KEY_2:
				_activate_menu_slot(1)
				return
			elif event.keycode == KEY_3:
				_activate_menu_slot(2)
				return
			elif event.keycode == KEY_4:
				_activate_menu_slot(3)
				return
			elif event.keycode in [KEY_5, KEY_X, KEY_W]:
				_activate_menu_slot(4)
				return
			elif event.keycode in [KEY_6, KEY_Y, KEY_I]:
				_activate_menu_slot(5)
				return


		if event.is_action_pressed("ui_left"):
			current_menu_index = (current_menu_index - 1) if (current_menu_index % 3 > 0) else (current_menu_index + 2)
			SoundManager.play_cursor()
			_update_menu_highlight()
		elif event.is_action_pressed("ui_right"):
			current_menu_index = (current_menu_index + 1) if (current_menu_index % 3 < 2) else (current_menu_index - 2)
			SoundManager.play_cursor()
			_update_menu_highlight()
		elif event.is_action_pressed("ui_up"):
			current_menu_index = (current_menu_index - 3) if current_menu_index >= 3 else (current_menu_index + 3)
			SoundManager.play_cursor()
			_update_menu_highlight()
		elif event.is_action_pressed("ui_down"):
			current_menu_index = (current_menu_index + 3) if current_menu_index < 3 else (current_menu_index - 3)
			SoundManager.play_cursor()
			_update_menu_highlight()
		elif event.is_action_pressed("gba_a") or event.is_action_pressed("ui_accept"):
			_activate_menu_slot(current_menu_index)


func show_dialog(speaker: String, text: String, portrait_id: String = "chief") -> void:
	speaker_label.text = speaker
	current_speaker_id = portrait_id
	var portrait_tex = PortraitManager.get_portrait(portrait_id)
	portrait_rect.texture = portrait_tex
	dialog_label.text = _highlight_bbcode(text)
	dialog_label.visible_characters = 0
	var vscroll = dialog_label.get_v_scroll_bar()
	if vscroll:
		vscroll.value = 0
	is_typing = true
	typewriter_timer = 0.0
	mouth_timer = 0.0
	is_mouth_open = false
	if portrait_material:
		portrait_material.set_shader_parameter("mouth_open", 0.0)
		portrait_material.set_shader_parameter("eye_blink", 0.0)

func _init_highlight_regexes() -> void:
	if not _alert_regexes.is_empty():
		return
	var alert_words = ["ARREST", "WARRANT", "MATCH CONFIRMED", "ALERT", "TIME EXPIRED", "CASE SOLVED", "CORNERED", "WARNING"]
	for w in alert_words:
		_alert_regexes.append(RegEx.create_from_string("(?i)\\b" + w + "\\b"))

	var traits = [
		"Ruby Ring", "Tattoo", "Monocle", "Gold Watch", "Gold Locket", "Eyepatch", "Scar", "Cane",
		"Convertible", "Motorcycle", "Limousine",
		"Tennis", "Mountain Climbing", "Croquet", "Bowling", "Skydiving", "Sailing", "Scuba Diving",
		"Red", "Black", "Blonde", "Brown"
	]
	for t in traits:
		_trait_regexes.append(RegEx.create_from_string("(?i)\\b" + t + "\\b"))

func _highlight_bbcode(text: String) -> String:
	_init_highlight_regexes()
	var result = text
	for r in _alert_regexes:
		result = r.sub(result, "[color=#f87171][b]$0[/b][/color]", true)
	for r in _trait_regexes:
		result = r.sub(result, "[color=#fbbf24][b]$0[/b][/color]", true)
	return result

func _on_city_changed(city_data: Dictionary) -> void:
	_update_city_view(city_data)
	SoundManager.play_city_theme(city_data["id"])
	var trail = GameManager.current_trail
	var city_id = city_data["id"]
	if not trail.has(city_id):
		SoundManager.play_cancel()
		show_dialog("[ACME ALERT: COLD TRAIL]", "WARNING: Local Interpol branches in %s report ZERO suspect activity! You are off the trail! Use the ACME Casebook [L] or deploy GPS Tracer [G] to reacquire the target!" % city_data["name"], "chief")
	elif city_id == trail[-1]:
		SoundManager.play_impact()
		show_dialog("[ACME DISPATCH: CORNERED!]", "ATTENTION GUMSHOE: Visual confirmation! Suspect is hiding in THIS city right now! Obtain an arrest warrant [R] and investigate the hideout!", "chief")
	else:
		show_dialog("[ACME DISPATCH]", "Arrived in %s. Check transit connections or question local witnesses." % city_data["name"], "chief")

func _update_city_view(city_data: Dictionary) -> void:
	city_title_label.text = "%s, %s" % [city_data["name"], city_data["country"].to_upper()]
	city_landmark_label.text = "LANDMARK: %s" % city_data["landmark"]
	city_status_label.text = "%s" % city_data["name"]

	# Load rasterized pixel-art city skyline if available
	var city_id = city_data["id"]
	var city_asset_path = "res://assets/cities/%s.png" % city_id
	if not ResourceLoader.exists(city_asset_path):
		city_asset_path = "res://assets/cities/default.png"
	if ResourceLoader.exists(city_asset_path):
		var tex = load(city_asset_path)
		if tex is Texture2D:
			skyline_sprite.texture = tex

	_apply_time_of_day_lighting(city_id)
	_update_trail_heat()

func _apply_time_of_day_lighting(city_id: String) -> void:
	var h = GameManager.hour_of_day
	var base_palette: Color = CITY_PALETTES.get(city_id, Color(0.10, 0.14, 0.22))
	var sky_rect = get_node_or_null("SkylineView/SkyBg")
	
	var sky_color: Color
	var sprite_tint: Color
	
	if h >= 6 and h < 11:
		# Morning sunrise: golden-blue warmth
		sky_color = base_palette.lerp(Color(0.24, 0.42, 0.68), 0.5)
		sprite_tint = Color(1.0, 0.96, 0.88)
	elif h >= 11 and h < 17:
		# Crisp daylight: vibrant
		sky_color = base_palette.lerp(Color(0.14, 0.35, 0.62), 0.4)
		sprite_tint = Color(1.0, 1.0, 1.0)
	elif h >= 17 and h < 20:
		# Sunset / Twilight: deep amber/crimson dusk
		sky_color = base_palette.lerp(Color(0.48, 0.18, 0.18), 0.6)
		sprite_tint = Color(1.0, 0.78, 0.65)
	else:
		# Midnight / Night: deep midnight navy
		sky_color = base_palette.lerp(Color(0.04, 0.06, 0.14), 0.7)
		sprite_tint = Color(0.45, 0.52, 0.75)
		
	if sky_rect is ColorRect:
		sky_rect.color = sky_color
	if skyline_sprite:
		skyline_sprite.modulate = sprite_tint
		
	if weather_overlay and weather_overlay.has_method("set_city_weather"):
		weather_overlay.set_city_weather(city_id, h)

func shake_screen(intensity: float = 3.0, duration: float = 0.25) -> void:
	shake_intensity = intensity
	shake_timer = duration

func flash_screen(color: Color = Color.WHITE, duration: float = 0.15) -> void:
	if not flash_overlay:
		return
	flash_overlay.color = color
	flash_overlay.visible = true
	var tw = create_tween()
	tw.tween_property(flash_overlay, "modulate:a", 0.0, duration).from(1.0)
	tw.tween_callback(func(): flash_overlay.visible = false)

func _update_trail_heat() -> void:
	if GameManager.current_trail.is_empty():
		return
	if GameManager.current_city_id == GameManager.current_trail[-1]:
		trail_label.text = "★ CORNERED!"
		trail_label.modulate = Color(1.0, 0.25, 0.35)
	elif GameManager.current_trail.has(GameManager.current_city_id):
		trail_label.text = "● HOT TRAIL"
		trail_label.modulate = Color(0.25, 0.95, 0.6)
	else:
		trail_label.text = "▲ COLD TRAIL"
		trail_label.modulate = Color(0.95, 0.45, 0.45)

func _on_time_updated(hours: int, day_str: String, time_str: String) -> void:
	clock_label.text = "%s %s" % [day_str, time_str]
	hours_label.text = "%dH LEFT" % hours
	_apply_time_of_day_lighting(GameManager.current_city_id)

func _on_clue_found(clue: String) -> void:
	pass

func _on_case_resolved(is_victory: bool, message: String) -> void:
	is_case_ended = true
	subscreen_panel.visible = false
	var criminal_id = GameManager.current_criminal.get("id", "carmen")
	var speaker = "[SUSPECT: %s]" % GameManager.current_criminal.get("name", "SUSPECT") if is_victory else "[ACME DISPATCH]"
	var portrait_id = criminal_id if is_victory else "chief"
	show_dialog(speaker, message + "\n\n[color=#38bdf8][b][PRESS A / SPACE TO CONTINUE][/b][/color]", portrait_id)

func _update_menu_highlight() -> void:
	for i in range(action_buttons.size()):
		if i == current_menu_index:
			action_buttons[i].grab_focus()

func _activate_menu_slot(idx: int) -> void:
	if GameManager.current_state in [GameManager.State.ARREST, GameManager.State.GAMEOVER]:
		return
	current_menu_index = idx
	SoundManager.play_confirm()
	match idx:
		0: open_investigate()
		1: open_depart()
		2: open_crime_computer()
		3: open_dossier()
		4: open_radio_intercept()
		5: open_crime_scene_inspection()

# --- Subscreens ---
func open_investigate() -> void:
	subscreen_mode = "investigate"
	var city = Database.CITIES[GameManager.current_city_id]
	subscreen_title.text = "INVESTIGATE WITNESSES (%s)" % city["name"]
	subscreen_data = []
	for p in city["places"]:
		subscreen_data.append({"type": "witness", "name": p["name"], "witness": p["witness"]})
	subscreen_data.append({"type": "inspect", "name": "🔍 SWEEP SCENE FOR PHYSICAL EVIDENCE", "witness": "Magnifying Glass"})
	subscreen_data.append({"type": "doc_inspect", "name": "📑 EXAMINE RECOVERED TRAVEL DOCUMENTS [U]", "witness": "365nm UV Blacklight Loupe"})
	subscreen_data.append({"type": "present", "name": "⚡ PRESENT EVIDENCE TO WITNESS [P]", "witness": "Contradiction Matrix"})
	subscreen_data.append({"type": "informant", "name": "🤝 CONSULT UNDERCOVER INFORMANT [N]", "witness": "Tactical Negotiation & Lead Intel"})
	subscreen_data.append({"type": "lockpick", "name": "🔓 TACTICAL LOCKPICK TUMBLER SIMULATOR [T]", "witness": "Electronic Lockpick"})
	
	var labels: Array[String] = []
	for p in subscreen_data:
		if p["type"] == "witness":
			labels.append("%s\nWitness: %s" % [p["name"], p["witness"]])
		elif p["type"] == "inspect":
			labels.append("%s\nExamine crime scene with tactile magnifying lens" % p["name"])
		elif p["type"] == "doc_inspect":
			labels.append("%s\nInspect flight tickets under 365nm UV blacklight" % p["name"])
		elif p["type"] == "present":
			labels.append("%s\nConfront witnesses with gathered proof & break alibis" % p["name"])
		elif p["type"] == "informant":
			labels.append("%s\nNegotiate with local underworld fixer for leads & time" % p["name"])
		elif p["type"] == "lockpick":
			labels.append("%s\nPick electronic tumbler pins to bypass security gates (+4H bonus)" % p["name"])
	_populate_subscreen(labels)


func open_depart() -> void:
	subscreen_mode = "depart"
	subscreen_title.text = "DEPART FLIGHTS [AIRPORT BOARDING]"
	var city = Database.CITIES[GameManager.current_city_id]
	subscreen_data = city["connections"]
	var labels: Array[String] = []
	for c_id in subscreen_data:
		var c = Database.CITIES[c_id]
		labels.append("✈ FLY TO %s\n   (%s)" % [c["name"], c["country"].to_upper()])
	_populate_subscreen(labels)

func open_crime_computer() -> void:
	subscreen_mode = "computer"
	subscreen_title.text = "CRIME COMPUTER [INTERPOL V.I.L.E. DATABASE]"
	_refresh_computer_labels()

func _refresh_computer_labels() -> void:
	var f = GameManager.computer_filters
	subscreen_data = [
		"SEX:     [%s]" % (f["sex"].to_upper() if f["sex"] != "" else "ANY"),
		"HAIR:    [%s]" % (f["hair"].to_upper() if f["hair"] != "" else "ANY"),
		"VEHICLE: [%s]" % (f["vehicle"].to_upper() if f["vehicle"] != "" else "ANY"),
		"HOBBY:   [%s]" % (f["hobby"].to_upper() if f["hobby"] != "" else "ANY"),
		"FEATURE: [%s]" % (f["feature"].to_upper() if f["feature"] != "" else "ANY"),
		"▶ COMPUTE & ISSUE ARREST WARRANT"
	]
	_populate_subscreen(subscreen_data, false)

func open_dossier() -> void:
	subscreen_mode = "dossier"
	subscreen_title.text = "ACME CASEBOOK & DEDUCTION MATRIX [L]"
	var items: Array[Dictionary] = []
	var warrant_txt = "WARRANT: %s" % (GameManager.warrant_suspect["name"] if not GameManager.warrant_suspect.is_empty() else "NONE ISSUED")
	var shell_data = GameManager.SHELLS[GameManager.current_shell_index]
	var reg = SoundManager.get_region_for_city(GameManager.current_city_id).to_upper()
	items.append({"action": "none", "text": "★ CASE SEED: %s | JURISDICTION: %s" % [GameManager.current_case_seed, reg]})
	items.append({"action": "none", "text": "★ STATUS: %s | STOLEN: %s" % [warrant_txt, GameManager.current_treasure]})
	items.append({"action": "cycle_shell", "text": "🎨 [C] GBA SP SHELL: %s (Click to Cycle)" % shell_data["name"]})
	items.append({"action": "gadgets", "text": "⚡ [G] ACME GADGET BELT (Deploy GPS, UV, Polygraph, Lockpick)"})
	items.append({"action": "present", "text": "⚡ [P] PRESENT EVIDENCE TO WITNESS (Break Alibis & Decoys)"})
	items.append({"action": "doc_inspect", "text": "📑 [U] TACTILE UV TRAVEL DOCUMENT INSPECTION"})
	items.append({"action": "museum", "text": "🏛 [M] EVIDENCE HALL & MUSEUM (Recovered Relics)"})
	items.append({"action": "speedrun", "text": "⏱ [O] SPEEDRUN SPLITS & STOPWATCH"})
	items.append({"action": "copy_seed", "text": "📋 [K] COPY / EXPORT CASE SEED CODE"})
	items.append({"action": "informant", "text": "🤝 [N] NEGOTIATE WITH LOCAL INFORMANT / FIXER (Time & Intel)"})
	items.append({"action": "lockpick", "text": "🔓 [T] TACTILE LOCKPICK TUMBLER SIMULATOR (Bypass Locks)"})
	
	# SECTION 1: SUSPECT DEDUCTION PROBABILITY MATRIX
	items.append({"action": "none", "text": "--- 🎯 DEDUCTION MATRIX: SUSPECT PROBABILITY ---"})
	
	var gathered_lower = ""
	for c in GameManager.clues_gathered:
		gathered_lower += " " + c.to_lower()
		
	var suspect_scores = []
	for s in Database.SUSPECTS:
		var matched_traits = []
		var conflict_traits = []
		
		# Check sex
		if gathered_lower.contains("she ") or gathered_lower.contains("her "):
			if s["sex"].to_lower() == "female":
				matched_traits.append("Sex: Female")
			else:
				conflict_traits.append("Sex (Male)")
		elif gathered_lower.contains("he ") or gathered_lower.contains("him ") or gathered_lower.contains("his "):
			if s["sex"].to_lower() == "male":
				matched_traits.append("Sex: Male")
			else:
				conflict_traits.append("Sex (Female)")
				
		# Check hair
		if gathered_lower.contains(s["hair"].to_lower() + " hair") or gathered_lower.contains("dyed " + s["hair"].to_lower()):
			matched_traits.append("Hair: " + s["hair"])
		elif (gathered_lower.contains("red hair") or gathered_lower.contains("black hair") or gathered_lower.contains("blonde hair") or gathered_lower.contains("brown hair")):
			conflict_traits.append("Hair")
			
		# Check vehicle
		if gathered_lower.contains(s["vehicle"].to_lower()):
			matched_traits.append("Vehicle: " + s["vehicle"])
		elif (gathered_lower.contains("convertible") or gathered_lower.contains("motorcycle") or gathered_lower.contains("limousine")):
			conflict_traits.append("Vehicle")
			
		# Check hobby
		if gathered_lower.contains(s["hobby"].to_lower()):
			matched_traits.append("Hobby: " + s["hobby"])
			
		# Check feature
		if gathered_lower.contains(s["feature"].to_lower()):
			matched_traits.append("Feature: " + s["feature"])
			
		var score = matched_traits.size() * 25
		if not conflict_traits.is_empty():
			score = 0
			
		suspect_scores.append({
			"suspect": s,
			"score": score,
			"matched": matched_traits,
			"conflict": conflict_traits
		})
		
	suspect_scores.sort_custom(func(a, b): return a["score"] > b["score"])
	
	for entry in suspect_scores:
		var s = entry["suspect"]
		var score = entry["score"]
		var prefix = "★" if score >= 50 else ("●" if score > 0 else "✖")
		var note = ""
		if score > 0:
			note = "[%d%% MATCH] %s (Click to load in Crime Comp)" % [score, ", ".join(entry["matched"])]
		elif not entry["conflict"].is_empty():
			note = "[ELIMINATED] Conflicts: %s" % ", ".join(entry["conflict"])
		else:
			note = "[POSSIBLE] No direct clues yet"
		items.append({
			"action": "load_suspect",
			"suspect": s,
			"text": "%s %s - %s" % [prefix, s["name"].to_upper(), note]
		})
		
	# SECTION 2: GATHERED WITNESS CLUES ARCHIVE
	items.append({"action": "none", "text": "--- 📑 ACTIVE CLUE & INTERCEPT LOG ---"})
	if GameManager.clues_gathered.is_empty():
		items.append({"action": "none", "text": "No clues logged yet. Question witnesses or scan crime scenes!"})
	else:
		for c in GameManager.clues_gathered:
			items.append({"action": "none", "text": c})
			
	subscreen_data = items
	var labels: Array[String] = []
	for it in items:
		labels.append(it["text"])
	_populate_subscreen(labels)

func open_museum() -> void:
	subscreen_panel.visible = false
	museum_overlay.open_museum()

func open_speedrun_splits() -> void:
	subscreen_mode = "speedrun"
	subscreen_title.text = "SPEEDRUN SPLIT TRACKER & STOPWATCH [O]"
	var items: Array[Dictionary] = []
	var best_str = GameManager.format_speedrun_time(GameManager.best_speedrun_time) if GameManager.best_speedrun_time < 999999.0 else "--:--.-"
	var cur_str = GameManager.format_speedrun_time(GameManager.speedrun_elapsed)
	var is_daily_str = "YES (DAILY CHALLENGE)" if GameManager.is_daily_case else "NO (CAREER/CUSTOM)"
	
	items.append({"action": "none", "text": "⏱ ELAPSED: %s   ★ PERSONAL BEST: %s" % [cur_str, best_str]})
	items.append({"action": "none", "text": "📋 CASE SEED: %s   DAILY: %s" % [GameManager.current_case_seed, is_daily_str]})
	items.append({"action": "copy_seed", "text": "📋 [K] COPY CASE SEED CODE TO CLIPBOARD"})
	items.append({"action": "none", "text": "--- 🏁 RECORDED MILESTONE SPLITS ---"})
	
	if GameManager.speedrun_splits.is_empty():
		items.append({"action": "none", "text": "No splits logged yet. Hop between cities or secure warrants to log splits!"})
	else:
		var prev_t = 0.0
		for i in range(GameManager.speedrun_splits.size()):
			var sp = GameManager.speedrun_splits[i]
			var t: float = sp.get("time", 0.0)
			var delta_t = t - prev_t
			prev_t = t
			var delta_str = "+%.1fs" % delta_t if i > 0 else "START"
			items.append({"action": "none", "text": "%d. [%s] %s (%s)" % [i + 1, GameManager.format_speedrun_time(t), sp.get("name", "Split"), delta_str]})
			
	items.append({"action": "back", "text": "◀ CLOSE SPEEDRUN SPLITS [B / O]"})
	
	subscreen_data = items
	var labels: Array[String] = []
	for it in items:
		labels.append(it["text"])
	_populate_subscreen(labels)

func open_gadgets() -> void:
	subscreen_mode = "gadgets"
	subscreen_title.text = "ACME TACTICAL GADGET INVENTORY"
	var g = GameManager.gadget_charges
	subscreen_data = [
		{"id": "gps_tracer", "name": "GPS MICRO-TRACER", "charges": g.get("gps_tracer", 0), "desc": "Satellite beacon ping reveals suspect flight destination."},
		{"id": "uv_light", "name": "UV BLACKLIGHT SCANNER", "charges": g.get("uv_light", 0), "desc": "Fluorescent beam uncovers hidden physical evidence."},
		{"id": "lockpick", "name": "ELECTRONIC LOCKPICK", "charges": g.get("lockpick", 0), "desc": "Bypasses transit security locks (+3 Hours recovered)."},
		{"id": "polygraph", "name": "POCKET POLYGRAPH", "charges": g.get("polygraph", 0), "desc": "Voice stress test extracts confirmed suspect trait."},
		{"id": "back", "name": "◀ CLOSE GADGET BELT", "charges": -1, "desc": "Return to active case operations."}
	]
	var labels: Array[String] = []
	for item in subscreen_data:
		if item["id"] == "back":
			labels.append(item["name"])
		else:
			labels.append("⚡ %s [%d BATTERY]\n   %s" % [item["name"], item["charges"], item["desc"]])
	_populate_subscreen(labels)

func _use_gadget(gadget_id: String) -> void:
	if gadget_id == "back":
		close_subscreen()
		return

	var charges: int = GameManager.gadget_charges.get(gadget_id, 0)
	if charges <= 0:
		SoundManager.play_cancel()
		show_dialog("[ACME GEAR]", "BATTERY DEPLETED! No charges remaining. Gadgets recharge automatically on your next case assignment.", "chief")
		close_subscreen()
		return

	GameManager.gadget_charges[gadget_id] = charges - 1
	SoundManager.play_gadget()
	flash_screen(Color(0.2, 0.8, 1.0, 0.7), 0.25)
	shake_screen(2.5, 0.2)
	close_subscreen()

	match gadget_id:
		"gps_tracer":
			var trail = GameManager.current_trail
			var curr_id = GameManager.current_city_id
			var idx = trail.find(curr_id)
			if idx != -1 and idx < trail.size() - 1:
				var next_id = trail[idx + 1]
				var next_name = Database.CITIES[next_id]["name"]
				var next_country = Database.CITIES[next_id]["country"].to_upper()
				var intel = "[GPS SATELLITE FIX] Micro-tracer transponder tracked to %s, %s!" % [next_name, next_country]
				if not GameManager.clues_gathered.has(intel):
					GameManager.clues_gathered.append(intel)
				GameManager.clue_found.emit(intel)
				show_dialog("[GPS TRACER]", "Satellite link confirmed! Transponder signals indicate suspect boarded a flight bound for %s (%s)!" % [next_name, next_country], "chief")
			elif idx == trail.size() - 1:
				show_dialog("[GPS TRACER]", "SIGNAL MAXIMUM! Suspect is hiding in THIS city right now! Obtain a warrant and corner them!", "chief")
			else:
				show_dialog("[GPS TRACER]", "Signal out of range! The suspect did not transit through this city. You are off the trail!", "chief")

		"uv_light":
			var suspect = GameManager.current_criminal
			var traits = [
				"suspect left hair strands dyed %s" % suspect.get("hair", "Unknown"),
				"tire tread residue matches a %s" % suspect.get("vehicle", "Unknown"),
				"metallic scrape matches a %s" % suspect.get("feature", "Unknown")
			]
			var picked: String = traits.pick_random()
			var intel = "[UV SCAN] Blacklight revealed fluorescent residue: %s!" % picked
			if not GameManager.clues_gathered.has(intel):
				GameManager.clues_gathered.append(intel)
			GameManager.clue_found.emit(intel)
			var reg = SoundManager.get_region_for_city(GameManager.current_city_id)
			if reg == "africa_mideast":
				reg = "africa"
			show_dialog("[UV BLACKLIGHT]", "High-intensity ultraviolet sweep detected trace forensic residue: %s!" % picked, "curator_%s" % reg)

		"lockpick":
			open_lockpick_simulator()

		"polygraph":
			var suspect = GameManager.current_criminal
			var traits = [
				"witness confirms suspect has a %s" % suspect.get("feature", "Ruby Ring"),
				"polygraph analysis confirms suspect is into %s" % suspect.get("hobby", "Tennis"),
				"voice stress pattern confirms suspect is %s" % suspect.get("sex", "Female")
			]
			var picked: String = traits.pick_random()
			var intel = "[POLYGRAPH INTEL] Lie detector cross-examination: %s!" % picked
			if not GameManager.clues_gathered.has(intel):
				GameManager.clues_gathered.append(intel)
			GameManager.clue_found.emit(intel)
			show_dialog("[POCKET POLYGRAPH]", "Biometric sensors detected elevated perspiration and voice tremor: %s!" % picked, "chief")

func _on_trap_resolved(success: bool, bonus_clue: String) -> void:
	if success and bonus_clue != "":
		var city_name = Database.CITIES[GameManager.current_city_id]["name"]
		var full = "[%s INTEL] %s" % [city_name, bonus_clue]
		if not GameManager.clues_gathered.has(full):
			GameManager.clues_gathered.append(full)
		GameManager.clue_found.emit(full)

func _populate_subscreen(labels: Array, reset_idx: bool = true) -> void:
	if reset_idx:
		subscreen_index = 0
	subscreen_panel.visible = true
	for child in subscreen_list.get_children():
		subscreen_list.remove_child(child)
		child.queue_free()

	for i in range(labels.size()):
		var btn = Button.new()
		var txt_str = str(labels[i])
		btn.text = txt_str
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.add_theme_font_size_override("font_size", 11)
		
		# Bulletproof multiline calculation: count lines across linebreaks and wrapping
		var lines = txt_str.split("\n")
		var visual_lines = 0
		for l in lines:
			visual_lines += maxi(1, ceili(float(l.length()) / 85.0))
		var btn_height = maxi(48, visual_lines * 22 + 20)
		btn.custom_minimum_size = Vector2(0, btn_height)

		var click_idx = i
		btn.pressed.connect(func(): _confirm_subscreen(click_idx))
		subscreen_list.add_child(btn)

	_update_subscreen_selection()

func _update_subscreen_selection() -> void:
	var children = subscreen_list.get_children()
	for i in range(children.size()):
		if children[i] is Button:
			if i == subscreen_index:
				children[i].grab_focus()

func close_subscreen() -> void:
	subscreen_panel.visible = false
	subscreen_mode = ""
	SoundManager.play_cancel()
	_update_menu_highlight()

func _confirm_subscreen(idx: int) -> void:
	if GameManager.current_state in [GameManager.State.ARREST, GameManager.State.GAMEOVER]:
		return
	subscreen_index = idx
	SoundManager.play_confirm()
	match subscreen_mode:
		"investigate":
			close_subscreen()
			if idx < subscreen_data.size() and subscreen_data[idx] is Dictionary:
				var t = subscreen_data[idx].get("type", "")
				if t == "inspect":
					open_crime_scene_inspection()
				elif t == "doc_inspect":
					open_document_inspection()
				elif t == "present":
					open_present_evidence()
				elif t == "informant":
					open_informant_negotiation()
				elif t == "lockpick":
					open_lockpick_simulator()
				else:
					_handle_investigation(idx)
			else:
				_handle_investigation(idx)
		"depart":
			var dest_id = subscreen_data[idx]
			close_subscreen()
			_handle_departure(dest_id)
		"computer":
			if idx == 5:
				_compute_warrant()
			else:
				_cycle_filter(idx)
				_refresh_computer_labels()
		"dossier":
			if idx < subscreen_data.size() and subscreen_data[idx] is Dictionary:
				var act = subscreen_data[idx].get("action", "none")
				if act == "gadgets":
					open_gadgets()
					return
				elif act == "present":
					open_present_evidence()
					return
				elif act == "doc_inspect":
					open_document_inspection()
					return
				elif act == "museum":
					open_museum()
					return
				elif act == "speedrun":
					open_speedrun_splits()
					return
				elif act == "copy_seed":
					GameManager.copy_seed_to_clipboard()
					SoundManager.play_confirm()
					show_dialog("[ACME SEED DISPATCH]", "Case Seed Code '%s' copied to system clipboard! Share with fellow detectives." % GameManager.current_case_seed, "chief")
					return
				elif act == "informant":
					open_informant_negotiation()
					return
				elif act == "lockpick":
					open_lockpick_simulator()
					return
				elif act == "cycle_shell":
					GameManager.cycle_shell()
					open_dossier()
					return
				elif act == "load_suspect":
					var s = subscreen_data[idx].get("suspect", {})
					if not s.is_empty():
						GameManager.computer_filters["sex"] = s.get("sex", "")
						GameManager.computer_filters["hair"] = s.get("hair", "")
						GameManager.computer_filters["vehicle"] = s.get("vehicle", "")
						GameManager.computer_filters["hobby"] = s.get("hobby", "")
						GameManager.computer_filters["feature"] = s.get("feature", "")
						open_crime_computer()
						return
			close_subscreen()
		"speedrun":
			if idx < subscreen_data.size() and subscreen_data[idx] is Dictionary:
				var act = subscreen_data[idx].get("action", "none")
				if act == "copy_seed":
					GameManager.copy_seed_to_clipboard()
					SoundManager.play_confirm()
					show_dialog("[ACME SEED DISPATCH]", "Case Seed Code '%s' copied to system clipboard!" % GameManager.current_case_seed, "chief")
					return
			close_subscreen()
		"gadgets":
			if idx < subscreen_data.size() and subscreen_data[idx] is Dictionary:
				_use_gadget(subscreen_data[idx].get("id", "back"))
		"present_evidence":
			_present_evidence_item(idx)
		"informant":
			_handle_informant_negotiation(idx)

func _handle_investigation(place_index: int) -> void:
	var city = Database.CITIES[GameManager.current_city_id]
	var place = city["places"][place_index % city["places"].size()]
	var witness_role = place["witness"]
	
	# Select regional witness portrait based on city location and archetype
	var reg = SoundManager.get_region_for_city(GameManager.current_city_id)
	if reg == "africa_mideast":
		reg = "africa"
	var base_role = "banker"
	if place_index == 1:
		base_role = "pilot"
	elif place_index == 2:
		base_role = "curator"
	var portrait_id = "%s_%s" % [base_role, reg]
	
	# Spend 2 hours
	if not GameManager.spend_hours(2):
		return

	# 22% chance of V.I.L.E. Ambush / Trap hazard on non-final cities
	if randf() < 0.22 and GameManager.current_city_id != GameManager.current_trail[-1]:
		trap_overlay.trigger_random_trap()
		await trap_overlay.trap_resolved
		if is_case_ended:
			return

	var is_cold = not GameManager.current_trail.has(GameManager.current_city_id)
	var clue_text := ""
	if is_cold:
		clue_text = "COLD TRAIL! Local authorities confirm no suspicious international travel matching V.I.L.E. here. Backtrack to the previous city!"
	elif GameManager.current_clues.has(GameManager.current_city_id):
		var city_clues: Array = GameManager.current_clues[GameManager.current_city_id]
		clue_text = city_clues[place_index % city_clues.size()]
	else:
		clue_text = "Nobody matching that description was seen here! You've lost the trail!"

	# Cross-examination & double agent breakdown mechanic (28% chance on valid clues)
	if not is_cold and randf() < 0.28:
		var s = GameManager.current_criminal
		var traits_list = [
			"Confessed: 'They drove off in a flashy %s!'" % s.get("vehicle", "limousine"),
			"Broke down during cross-examination: 'I saw %s hair under their disguise!'" % s.get("hair", "brown"),
			"Admitted under pressure: 'They wouldn't stop talking about %s!'" % s.get("hobby", "tennis"),
			"Slipped up: 'They definitely wore a %s!'" % s.get("feature", "ruby ring")
		]
		var bonus_trait: String = traits_list.pick_random()
		clue_text += "\n\n[color=#38bdf8][b]⚡ CROSS-EXAMINATION SUCCESS:[/b] Witness cracked under intense questioning: \"%s\"[/color]" % bonus_trait
	elif not is_cold and GameManager.cases_solved >= 2 and randf() < 0.35 and place_index == 2:
		# Decoy Contradiction Matrix for higher detective ranks
		clue_text += "\n\n[color=#f59e0b][b]⚠ CONTRADICTION ALERT:[/b] Witness appears bribed or coached by V.I.L.E.! Press [P] to PRESENT EVIDENCE and break their alibi![/color]"

	SoundManager.play_clue()
	var full_clue := "[%s] %s" % [city["name"], clue_text]
	if not GameManager.clues_gathered.has(full_clue):
		GameManager.clues_gathered.append(full_clue)
	GameManager.clue_found.emit(full_clue)

	# Check if final hideout reached
	if GameManager.current_city_id == GameManager.current_trail[-1]:
		if GameManager.warrant_suspect.is_empty():
			SoundManager.play_cancel()
			shake_screen(2.0, 0.2)
			var warn_text = "%s\n\n[color=#f87171][b]WARNING: Suspect spotted nearby! You do NOT have an arrest warrant yet! Open Crime Computer [R] and secure a warrant before arresting![/b][/color]" % clue_text
			show_dialog("[WITNESS: %s]" % witness_role.to_upper(), warn_text, portrait_id)
		else:
			show_dialog("[ACME DISPATCH]", "WARRANT CONFIRMED FOR %s! Suspect bolting into the back-alleys — AFTER THEM!" % GameManager.warrant_suspect["name"], "chief")
			await get_tree().create_timer(1.2).timeout
			_start_alley_chase()
	else:
		show_dialog("[WITNESS: %s]" % witness_role.to_upper(), clue_text, portrait_id)

func open_radio_intercept() -> void:
	subscreen_panel.visible = false
	radio_overlay.start_radio_intercept(GameManager.current_city_id)

func open_crime_scene_inspection() -> void:
	subscreen_panel.visible = false
	var city = Database.CITIES[GameManager.current_city_id]
	var place = city["places"][0]["name"]
	inspect_overlay.start_inspection(GameManager.current_city_id, place)

func open_document_inspection() -> void:
	subscreen_panel.visible = false
	inspect_overlay.start_document_inspection()

func open_lockpick_simulator() -> void:
	subscreen_panel.visible = false
	inspect_overlay.start_lockpick()

func open_present_evidence() -> void:
	subscreen_mode = "present_evidence"
	subscreen_title.text = "PRESENT FORENSIC EVIDENCE [HOLD IT! / OBJECTION!]"
	if GameManager.clues_gathered.is_empty():
		subscreen_data = [{"empty": true}]
		_populate_subscreen(["NO EVIDENCE GATHERED YET\nSearch crime scenes or question witnesses first."])
		return

	var items: Array[Dictionary] = []
	var labels: Array[String] = []
	for c in GameManager.clues_gathered:
		items.append({"clue": c})
		labels.append("📁 %s" % c)
	subscreen_data = items
	_populate_subscreen(labels)

func _present_evidence_item(idx: int) -> void:
	if idx >= subscreen_data.size() or subscreen_data[idx].get("empty", false):
		close_subscreen()
		return

	var chosen_clue: String = subscreen_data[idx].get("clue", "")
	close_subscreen()

	var suspect = GameManager.current_criminal
	var trail = GameManager.current_trail
	var curr_id = GameManager.current_city_id
	var curr_idx = trail.find(curr_id)
	var next_city_id = ""
	if curr_idx != -1 and curr_idx < trail.size() - 1:
		next_city_id = trail[curr_idx + 1]
	var next_city = Database.CITIES.get(next_city_id, {})
	var next_name = next_city.get("name", "")
	var next_currency = next_city.get("currency", "")
	var next_flag = next_city.get("flag", "")

	var clue_lower = chosen_clue.to_lower()
	var is_relevant = false

	# Check if clue matches suspect trait
	var traits = ["hair", "vehicle", "hobby", "feature", "sex"]
	for t in traits:
		var val = str(suspect.get(t, "")).to_lower()
		if val != "" and clue_lower.contains(val):
			is_relevant = true
			break

	# Check if clue matches destination
	if not is_relevant and next_name != "":
		if clue_lower.contains(next_name.to_lower()) or (next_currency != "" and clue_lower.contains(next_currency.to_lower())) or (next_flag != "" and clue_lower.contains(next_flag.to_lower())):
			is_relevant = true

	# Also check if it's a UV document, flight manifest, or forensic stamp
	if not is_relevant and (clue_lower.contains("uv") or clue_lower.contains("evidence") or clue_lower.contains("manifest") or clue_lower.contains("ticket")):
		is_relevant = true

	var reg = SoundManager.get_region_for_city(curr_id)
	if reg == "africa_mideast":
		reg = "africa"
	var portrait_id = "curator_%s" % reg

	if is_relevant:
		SoundManager.play_hold_it()
		flash_screen(Color(0.2, 0.9, 1.0, 0.9), 0.35)
		shake_screen(4.0, 0.35)
		await get_tree().create_timer(0.35).timeout

		SoundManager.play_breakthrough()
		flash_screen(Color(1.0, 0.85, 0.2, 0.6), 0.25)

		# Award +2 bonus hours
		GameManager.hours_left = mini(GameManager.hours_left + 2, 168)
		GameManager.broadcast_time()

		var confession = ""
		if next_name != "":
			confession = "HOLD IT! ... You caught me red-handed with that evidence! I was paid off by V.I.L.E. to misdirect you, but I can't deny this proof: the suspect definitely boarded transport for %s (%s) and drove a %s! (+2 Hours Bonus)" % [next_name, next_city.get("country", "").to_upper(), suspect.get("vehicle", "vehicle")]
		else:
			confession = "HOLD IT! ... Alright, detective, you win! The suspect is holed up right here in this city planning their getaway! Secure your warrant and check the hideouts! (+2 Hours Bonus)"

		var logged_entry = "[CONTRADICTION BREAKTHROUGH] Witness cracked: %s" % confession
		if not GameManager.clues_gathered.has(logged_entry):
			GameManager.clues_gathered.append(logged_entry)
		GameManager.clue_found.emit(logged_entry)

		show_dialog("[WITNESS BREAKTHROUGH!]", confession, portrait_id)
	else:
		SoundManager.play_cancel()
		shake_screen(1.5, 0.15)
		var unhelpful = [
			"What does that prove? That has nothing to do with what I saw, detective!",
			"Are you bluffing? That piece of evidence doesn't contradict my testimony at all.",
			"Nice try, gumshoe! You'll need real forensic proof to rattle me."
		].pick_random()
		show_dialog("[WITNESS CONFRONTATION]", unhelpful, portrait_id)

func open_informant_negotiation() -> void:
	subscreen_mode = "informant"
	
	var city_id = GameManager.current_city_id
	var hash_val = abs((GameManager.current_case_seed.hash() + city_id.hash()))
	var archetypes = ["greedy", "lawful", "nervous"]
	var arch = archetypes[hash_val % 3]
	
	var fixer_names = {
		"greedy": "Vito 'Cashflow' (Black Market Broker)",
		"lawful": "Kenji Sato (Precinct Veteran)",
		"nervous": "Rico 'Twitch' (Stashhouse Courier)"
	}
	
	subscreen_title.text = "INFORMANT: %s [%s]" % [fixer_names[arch].to_upper(), arch.to_upper()]
	
	subscreen_data = [
		{"tactic": "bounty", "arch": arch, "title": "💵 OFFER FINANCIAL BOUNTY (5,000 ACME Credits)", "desc": "Grease palms with cash bounty to buy underworld loyalty."},
		{"tactic": "justice", "arch": arch, "title": "⚖ APPEAL TO CIVIC JUSTICE & DUTY", "desc": "Appeal to community protection and moral duty against crime syndicates."},
		{"tactic": "intimidation", "arch": arch, "title": "🚨 INTERPOL LEGAL INTIMIDATION", "desc": "Brandish ACME badge and threaten harboring / obstruction charges."},
		{"tactic": "back", "arch": arch, "title": "◀ WITHDRAW FROM NEGOTIATION", "desc": "Return to active case operations."}
	]
	
	var labels: Array[String] = []
	for item in subscreen_data:
		if item["tactic"] == "back":
			labels.append(item["title"])
		else:
			labels.append("%s\n   %s" % [item["title"], item["desc"]])
	_populate_subscreen(labels)

func _handle_informant_negotiation(idx: int) -> void:
	if idx >= subscreen_data.size():
		close_subscreen()
		return
	var item = subscreen_data[idx]
	var tactic: String = item.get("tactic", "back")
	if tactic == "back":
		close_subscreen()
		return
	
	var arch: String = item.get("arch", "greedy")
	close_subscreen()
	
	# Spend 1 hour for the tactical negotiation
	if not GameManager.spend_hours(1):
		return

	var reg = SoundManager.get_region_for_city(GameManager.current_city_id)
	if reg == "africa_mideast":
		reg = "africa"
	var portrait_id = "curator_%s" % reg

	var is_success = (tactic == "bounty" and arch == "greedy") or (tactic == "justice" and arch == "lawful") or (tactic == "intimidation" and arch == "nervous")
	
	if is_success:
		SoundManager.play_breakthrough()
		SoundManager.play_clue()
		flash_screen(Color(0.2, 0.9, 0.5, 0.8), 0.3)
		shake_screen(3.5, 0.25)
		
		# Award +3 bonus hours
		GameManager.hours_left = mini(GameManager.hours_left + 3, 168)
		GameManager.broadcast_time()
		
		var suspect = GameManager.current_criminal
		var trail = GameManager.current_trail
		var curr_id = GameManager.current_city_id
		var curr_idx = trail.find(curr_id)
		var lead_msg = ""
		
		if curr_idx != -1 and curr_idx < trail.size() - 1:
			var next_city = Database.CITIES[trail[curr_idx + 1]]
			lead_msg = "INFORMANT LEAD: 'The operative slipped into the VIP terminal heading for %s (%s). Kept bragging about driving a %s!' (+3 Hours Bonus)" % [next_city["name"], next_city["country"].to_upper(), suspect.get("vehicle", "vehicle")]
		elif curr_idx == trail.size() - 1:
			lead_msg = "INFORMANT LEAD: 'They're hiding right here in this city! Saw them near the back-alleys with %s hair and a %s! Get your warrant ready!' (+3 Hours Bonus)" % [suspect.get("hair", "dark"), suspect.get("feature", "disguise")]
		else:
			lead_msg = "INFORMANT LEAD: 'You're off track, detective! V.I.L.E. bypassed this territory completely. Check your casebook and backtrack!' (+3 Hours Bonus)"
		
		var entry = "[INFORMANT INTEL] %s" % lead_msg
		if not GameManager.clues_gathered.has(entry):
			GameManager.clues_gathered.append(entry)
		GameManager.clue_found.emit(entry)
		
		show_dialog("[INFORMANT COOPERATION]", lead_msg, portrait_id)
	else:
		SoundManager.play_cancel()
		shake_screen(2.0, 0.2)
		var refusal_text = ""
		if arch == "greedy":
			refusal_text = "'Nice speech, agent, but speeches don't pay my debts. Money talks, morality walks. Bring real cash next time!'"
		elif arch == "lawful":
			refusal_text = "'You think I'm a common crook you can bribe or threaten? I cooperate for justice and the safety of our citizens, nothing else!'"
		else: # nervous
			refusal_text = "'Your soft words don't scare V.I.L.E. and they don't comfort me! I'm not risking my neck unless you can guarantee Interpol muscle!'"
			
		show_dialog("[NEGOTIATION STALEMATE]", refusal_text, portrait_id)

func _start_alley_chase() -> void:
	subscreen_panel.visible = false
	chase_overlay.start_chase(GameManager.current_criminal)

func _on_chase_completed(_success: bool) -> void:
	_trigger_dramatic_arrest()

func _on_evidence_discovered(clue_text: String) -> void:
	var city_name = Database.CITIES[GameManager.current_city_id]["name"]
	var full = "[%s EVIDENCE] %s" % [city_name, clue_text]
	if not GameManager.clues_gathered.has(full):
		GameManager.clues_gathered.append(full)
	GameManager.clue_found.emit(full)
	var reg = SoundManager.get_region_for_city(GameManager.current_city_id)
	if reg == "africa_mideast":
		reg = "africa"
	show_dialog("[PHYSICAL EVIDENCE]", clue_text, "curator_%s" % reg)

func _on_radio_solved(clue_text: String) -> void:
	var city_name = Database.CITIES[GameManager.current_city_id]["name"]
	var full = "[%s INTERCEPT] %s" % [city_name, clue_text]
	if not GameManager.clues_gathered.has(full):
		GameManager.clues_gathered.append(full)
	GameManager.clue_found.emit(full)
	show_dialog("[RADIO SURVEILLANCE]", clue_text, "chief")

func _on_overlay_closed() -> void:
	_update_menu_highlight()


func _trigger_dramatic_arrest() -> void:
	var criminal = GameManager.current_criminal
	var warrant = GameManager.warrant_suspect
	var is_correct = (warrant.get("id") == criminal.get("id"))

	# 1. Dramatic Impact Sting & Screen Flash + Shake
	SoundManager.play_impact()
	shake_screen(6.0, 0.45)
	flash_screen(Color(1.0, 0.2, 0.2, 0.85), 0.25)

	# 2. Show Arrest Overlay
	subscreen_panel.visible = false
	arrest_overlay.visible = true
	arrest_stamp.visible = false
	arrest_hint.visible = false

	var portrait_id = criminal.get("id", "carmen")
	arrest_portrait.texture = PortraitManager.get_portrait(portrait_id)
	
	if is_correct:
		var quote = criminal.get("quote", "Curses! Foiled again!")
		arrest_details.text = "[b]%s CORNERED![/b]\n\n\"%s\"\n\n[color=#fbbf24]Warrant verified. ACME tactical backup has surrounded the hideout![/color]" % [criminal.get("name", "SUSPECT"), quote]
		
		# 3. Metallic handcuffs snap after 1.1s
		await get_tree().create_timer(1.1).timeout
		SoundManager.play_cuffs()
		shake_screen(3.5, 0.25)
		arrest_stamp.text = "★ APPREHENDED & CUFFED ★"
		arrest_stamp.visible = true

		# 4. Fanfare & promotion resolution after 0.8s
		await get_tree().create_timer(0.8).timeout
		GameManager.cases_solved += 1
		var found_rec = false
		for rec in GameManager.recovered_treasures:
			if rec is Dictionary and rec.get("name") == GameManager.current_treasure:
				found_rec = true
				break
		if not found_rec:
			var t_lore = "Historic treasure safely restored to ACME vault."
			var t_val = "$10,000,000"
			for t in Database.TREASURES:
				if t["name"] == GameManager.current_treasure:
					t_lore = t.get("lore", t_lore)
					t_val = t.get("value", t_val)
					break
			GameManager.recovered_treasures.append({
				"name": GameManager.current_treasure,
				"thief": criminal.get("name", "V.I.L.E. Operative"),
				"city": GameManager.current_city_id,
				"value": t_val,
				"lore": t_lore
			})
		GameManager.save_profile()
		GameManager.update_rank()
		SoundManager.play_victory()
		arrest_details.text += "\n\n[color=#34d399][b]CASE SOLVED![/b][/color] %s recovered!\n[color=#38bdf8]Rank: %s (%d solved)[/color]" % [GameManager.current_treasure, GameManager.current_rank["title"], GameManager.cases_solved]
		arrest_hint.visible = true
		is_case_ended = true
		GameManager.current_state = GameManager.State.ARREST
	else:
		# Blunder! Warrant was for wrong suspect!
		var quote = criminal.get("quote", "You'll never catch me!")
		arrest_details.text = "[b]BLUNDER AT THE HIDEOUT![/b]\n\n\"%s\"\n\n[color=#f87171]Your warrant was for %s, but the thief was %s!\nWithout a valid warrant, the criminal slipped away into the shadows![/color]" % [quote, warrant.get("name", "UNKNOWN"), criminal.get("name", "SUSPECT")]
		
		await get_tree().create_timer(1.0).timeout
		SoundManager.play_game_over()
		shake_screen(3.0, 0.3)
		arrest_stamp.text = "✖ CASE FAILED — SUSPECT ESCAPED ✖"
		arrest_stamp.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		arrest_stamp.visible = true
		arrest_hint.visible = true
		is_case_ended = true
		GameManager.current_state = GameManager.State.GAMEOVER

func _handle_departure(dest_id: String) -> void:
	var orig_name = Database.CITIES[GameManager.current_city_id]["name"]
	var dest_name = Database.CITIES[dest_id]["name"]
	var dest_reg = SoundManager.get_region_for_city(dest_id).to_upper()
	flight_route.text = "%s ➔ %s" % [orig_name, dest_name]
	flight_status.text = "TRACKING TRANSIT... [REGIONAL VISA STAMP: %s DIVISION]" % dest_reg
	flight_overlay.visible = true

	SoundManager.play_travel()
	await get_tree().create_timer(0.6).timeout
	SoundManager.play_impact()
	shake_screen(2.5, 0.2)
	await get_tree().create_timer(0.4).timeout
	flight_overlay.visible = false

	GameManager.travel_to(dest_id)

func _cycle_filter(filter_slot: int, dir: int = 1) -> void:
	var f = GameManager.computer_filters
	match filter_slot:
		0: f["sex"] = _get_next_filter(FILTER_SEX, f["sex"], dir)
		1: f["hair"] = _get_next_filter(FILTER_HAIR, f["hair"], dir)
		2: f["vehicle"] = _get_next_filter(FILTER_VEHICLE, f["vehicle"], dir)
		3: f["hobby"] = _get_next_filter(FILTER_HOBBY, f["hobby"], dir)
		4: f["feature"] = _get_next_filter(FILTER_FEATURE, f["feature"], dir)

func _get_next_filter(options: Array, current_val: String, dir: int = 1) -> String:
	var idx = 0
	for i in range(options.size()):
		if options[i].to_lower() == current_val.to_lower():
			idx = i
			break
	var next_idx = posmod(idx + dir, options.size())
	return "" if options[next_idx] == "ANY" else options[next_idx]

func _compute_warrant() -> void:
	close_subscreen()
	var f = GameManager.computer_filters
	var matches := []
	for s in Database.SUSPECTS:
		var ok = true
		if f["sex"] != "" and s["sex"].to_lower() != f["sex"].to_lower():
			ok = false
		if f["hair"] != "" and s["hair"].to_lower() != f["hair"].to_lower():
			ok = false
		if f["vehicle"] != "" and s["vehicle"].to_lower() != f["vehicle"].to_lower():
			ok = false
		if f["hobby"] != "" and s["hobby"].to_lower() != f["hobby"].to_lower():
			ok = false
		if f["feature"] != "" and s["feature"].to_lower() != f["feature"].to_lower():
			ok = false
		if ok:
			matches.append(s)

	if matches.size() == 1:
		GameManager.warrant_suspect = matches[0]
		SoundManager.play_warrant()
		GameManager.warrant_issued.emit(GameManager.warrant_suspect["name"])
		if GameManager.current_city_id == GameManager.current_trail[-1]:
			show_dialog("[CRIME COMPUTER]", "MATCH CONFIRMED! ARREST WARRANT ISSUED FOR %s!\nSuspect is cornered here! Investigate the hideout to arrest them!" % GameManager.warrant_suspect["name"], GameManager.warrant_suspect["id"])
		else:
			show_dialog("[CRIME COMPUTER]", "MATCH CONFIRMED! ARREST WARRANT ISSUED FOR %s!" % GameManager.warrant_suspect["name"], GameManager.warrant_suspect["id"])
	elif matches.size() == 0:
		SoundManager.play_cancel()
		show_dialog("[CRIME COMPUTER]", "No suspects match those traits! Check witness clues and reset filters.", "chief")
	else:
		SoundManager.play_cancel()
		show_dialog("[CRIME COMPUTER]", "%d suspects match. Enter more specific clues to narrow the search!" % matches.size(), "chief")
