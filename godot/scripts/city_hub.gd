extends Control
## City Hub: 480x320 World City Exploration, Witness Questioning & Flight Routing

@onready var city_title_label: Label = $SkylineView/CityBanner/CityTitle
@onready var city_landmark_label: Label = $SkylineView/CityBanner/CityLandmark
@onready var city_status_label: Label = $StatusBar/HBox/CityLabel
@onready var clock_label: Label = $StatusBar/HBox/ClockLabel
@onready var hours_label: Label = $StatusBar/HBox/HoursLabel
@onready var dialog_label: Label = $DialogBox/TextLabel

@onready var btn_investigate: Button = $ActionMenu/BtnInvestigate
@onready var btn_depart: Button = $ActionMenu/BtnDepart
@onready var btn_computer: Button = $ActionMenu/BtnComputer
@onready var btn_dossier: Button = $ActionMenu/BtnDossier

@onready var subscreen_panel: Panel = $SubscreenOverlay
@onready var subscreen_title: Label = $SubscreenOverlay/Header/TitleLabel
@onready var subscreen_list: VBoxContainer = $SubscreenOverlay/Scroll/ItemList

var action_buttons: Array[Button] = []
var current_menu_index: int = 0
var subscreen_mode: String = ""
var subscreen_index: int = 0
var subscreen_data: Array = []

var target_dialog_text: String = ""
var displayed_text_length: int = 0
var typewriter_timer: float = 0.0

const FILTER_SEX = ["ANY", "Female", "Male"]
const FILTER_HAIR = ["ANY", "Red", "Black", "Blonde", "Brown"]
const FILTER_VEHICLE = ["ANY", "Convertible", "Motorcycle", "Limousine"]
const FILTER_HOBBY = ["ANY", "Tennis", "Mountain Climbing", "Croquet", "Bowling", "Skydiving", "Sailing", "Scuba Diving"]
const FILTER_FEATURE = ["ANY", "Ruby Ring", "Tattoo", "Monocle", "Gold Watch", "Gold Locket", "Eyepatch", "Scar", "Cane"]

func _ready() -> void:
	action_buttons = [btn_investigate, btn_depart, btn_computer, btn_dossier]

	btn_investigate.pressed.connect(func(): _activate_menu_slot(0))
	btn_depart.pressed.connect(func(): _activate_menu_slot(1))
	btn_computer.pressed.connect(func(): _activate_menu_slot(2))
	btn_dossier.pressed.connect(func(): _activate_menu_slot(3))

	GameManager.city_changed.connect(_on_city_changed)
	GameManager.time_updated.connect(_on_time_updated)
	GameManager.clue_found.connect(_on_clue_found)
	GameManager.case_resolved.connect(_on_case_resolved)

	if Database.CITIES.has(GameManager.current_city_id):
		_on_city_changed(Database.CITIES[GameManager.current_city_id])
	GameManager.broadcast_time()
	_update_menu_highlight()

func _process(delta: float) -> void:
	if displayed_text_length < target_dialog_text.length():
		typewriter_timer += delta
		if typewriter_timer >= 0.02:
			typewriter_timer = 0.0
			displayed_text_length += 1
			dialog_label.text = target_dialog_text.substr(0, displayed_text_length)
			if displayed_text_length % 2 == 0:
				SoundManager.play_text_blip()

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

func _input(event: InputEvent) -> void:
	if GameManager.current_state in [GameManager.State.ARREST, GameManager.State.GAMEOVER]:
		return

	# Fast-forward typewriter on A/Space/Click if still typing
	if displayed_text_length < target_dialog_text.length():
		if event.is_action_pressed("gba_a") or event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
			displayed_text_length = target_dialog_text.length()
			dialog_label.text = target_dialog_text
			return

	if event.is_action_pressed("gba_l"):
		open_dossier()
		return
	if event.is_action_pressed("gba_r"):
		open_crime_computer()
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
		elif event.is_action_pressed("gba_a") or event.is_action_pressed("ui_accept"):
			_confirm_subscreen(subscreen_index)
		elif event.is_action_pressed("gba_b") or event.is_action_pressed("ui_cancel"):
			close_subscreen()
	else:
		if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			current_menu_index ^= 1
			SoundManager.play_cursor()
			_update_menu_highlight()
		elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
			current_menu_index ^= 2
			SoundManager.play_cursor()
			_update_menu_highlight()
		elif event.is_action_pressed("gba_a") or event.is_action_pressed("ui_accept"):
			_activate_menu_slot(current_menu_index)

func show_dialog(text: String) -> void:
	target_dialog_text = text
	displayed_text_length = 0
	typewriter_timer = 0.0

func _on_city_changed(city_data: Dictionary) -> void:
	city_title_label.text = "%s, %s" % [city_data["name"], city_data["country"].to_upper()]
	city_landmark_label.text = "LANDMARK: %s" % city_data["landmark"]
	city_status_label.text = "LOC: %s" % city_data["name"]
	var sky_rect = get_node_or_null("SkylineView/SkyBg")
	if sky_rect is ColorRect:
		sky_rect.color = CITY_PALETTES.get(city_data["id"], Color(0.08, 0.11, 0.19))
	show_dialog("Arrived in %s. Check transit connections or question witnesses." % city_data["name"])

func _on_time_updated(hours: int, day_str: String, time_str: String) -> void:
	clock_label.text = "%s %s" % [day_str, time_str]
	hours_label.text = "%dH LEFT" % hours

func _on_clue_found(clue: String) -> void:
	show_dialog(clue)

func _on_case_resolved(is_victory: bool, message: String) -> void:
	subscreen_panel.visible = false
	show_dialog(message)

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

# --- Subscreens ---
func open_investigate() -> void:
	subscreen_mode = "investigate"
	var city = Database.CITIES[GameManager.current_city_id]
	subscreen_title.text = "INVESTIGATE (%s)" % city["name"]
	subscreen_data = city["places"]
	var labels: Array[String] = []
	for p in subscreen_data:
		labels.append("%s (Witness: %s)" % [p["name"], p["witness"]])
	_populate_subscreen(labels)

func open_depart() -> void:
	subscreen_mode = "depart"
	subscreen_title.text = "DEPART FLIGHTS"
	var city = Database.CITIES[GameManager.current_city_id]
	subscreen_data = city["connections"]
	var labels: Array[String] = []
	for c_id in subscreen_data:
		labels.append("✈ FLY TO %s (%s)" % [Database.CITIES[c_id]["name"], Database.CITIES[c_id]["country"].to_upper()])
	_populate_subscreen(labels)

func open_crime_computer() -> void:
	subscreen_mode = "computer"
	subscreen_title.text = "CRIME COMPUTER [INTERPOL V.I.L.E. DB]"
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
	subscreen_title.text = "DETECTIVE DOSSIER & CASE NOTES"
	var items: Array[String] = []
	var warrant_txt = "WARRANT: %s" % (GameManager.warrant_suspect["name"] if not GameManager.warrant_suspect.is_empty() else "NONE ISSUED")
	items.append("★ " + warrant_txt)
	items.append("★ STOLEN TREASURE: %s" % GameManager.current_treasure)
	items.append("--- GATHERED WITNESS CLUES ---")
	if GameManager.clues_gathered.is_empty():
		items.append("No clues gathered yet. Question local witnesses!")
	else:
		for c in GameManager.clues_gathered:
			items.append(c)
	subscreen_data = items
	_populate_subscreen(items)

func _populate_subscreen(labels: Array, reset_idx: bool = true) -> void:
	if reset_idx:
		subscreen_index = 0
	subscreen_panel.visible = true
	for child in subscreen_list.get_children():
		subscreen_list.remove_child(child)
		child.queue_free()

	for i in range(labels.size()):
		var btn = Button.new()
		btn.text = str(labels[i])
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 26)
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
			GameManager.investigate_place(idx)
		"depart":
			var dest_id = subscreen_data[idx]
			close_subscreen()
			GameManager.travel_to(dest_id)
		"computer":
			if idx == 5:
				_compute_warrant()
			else:
				_cycle_filter(idx)
				_refresh_computer_labels()
		"dossier":
			close_subscreen()

func _cycle_filter(filter_slot: int) -> void:
	var f = GameManager.computer_filters
	match filter_slot:
		0: f["sex"] = _get_next_filter(FILTER_SEX, f["sex"])
		1: f["hair"] = _get_next_filter(FILTER_HAIR, f["hair"])
		2: f["vehicle"] = _get_next_filter(FILTER_VEHICLE, f["vehicle"])
		3: f["hobby"] = _get_next_filter(FILTER_HOBBY, f["hobby"])
		4: f["feature"] = _get_next_filter(FILTER_FEATURE, f["feature"])

func _get_next_filter(options: Array, current_val: String) -> String:
	var idx = 0
	for i in range(options.size()):
		if options[i].to_lower() == current_val.to_lower():
			idx = i
			break
	var next_idx = (idx + 1) % options.size()
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
		show_dialog("MATCH! ARREST WARRANT ISSUED FOR %s!" % GameManager.warrant_suspect["name"])
	elif matches.size() == 0:
		SoundManager.play_cancel()
		show_dialog("CRIME COMPUTER: No suspects match! Check witness clues.")
	else:
		SoundManager.play_cancel()
		show_dialog("CRIME COMPUTER: %d suspects match. Enter more clues!" % matches.size())
