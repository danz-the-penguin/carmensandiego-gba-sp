extends Control
## InspectOverlay: Tactile Magnifying Glass Crime Scene Search Minigame

signal inspection_closed
signal evidence_discovered(clue_text: String)

var active: bool = false
var lens_pos: Vector2 = Vector2(640, 360)
var lens_radius: float = 42.0
var move_speed: float = 360.0
var ping_timer: float = 0.0

var hotspots: Array[Dictionary] = []
var current_place_name: String = ""
var clue_dialog_active: bool = false
var active_clue_data: Dictionary = {}

@onready var clue_card: Panel = $ClueCard
@onready var clue_title: Label = $ClueCard/Title
@onready var clue_desc: RichTextLabel = $ClueCard/Desc
@onready var clue_hint: Label = $ClueCard/Hint
@onready var status_label: Label = $TopBar/StatusLabel
@onready var hint_bar: Label = $BottomBar/HintBar

func _ready() -> void:
	visible = false
	if clue_card:
		clue_card.visible = false

func start_inspection(city_id: String, place_name: String) -> void:
	current_place_name = place_name
	active = true
	visible = true
	lens_pos = Vector2(640, 360)
	clue_dialog_active = false
	if clue_card:
		clue_card.visible = false
	
	_generate_hotspots(city_id)
	status_label.text = "CRIME SCENE: %s" % place_name.to_upper()
	hint_bar.text = "D-PAD: MOVE LENS | [A] EXAMINE SPOT | [B] RETURN"
	queue_redraw()

func _generate_hotspots(city_id: String) -> void:
	hotspots.clear()
	var suspect = GameManager.current_criminal
	var next_city_id = ""
	var trail = GameManager.current_trail
	var curr_idx = trail.find(city_id)
	if curr_idx != -1 and curr_idx < trail.size() - 1:
		next_city_id = trail[curr_idx + 1]
	
	# Hotspot 1: Destination Physical Clue
	var dest_clue_text = ""
	if next_city_id != "" and Database.CITIES.has(next_city_id):
		var n_city = Database.CITIES[next_city_id]
		var items = [
			"Torn boarding pass with flight route to %s (%s)!" % [n_city["name"], n_city["country"]],
			"Discarded currency receipt stamped in %s!" % n_city["currency"],
			"Tourist pamphlet marked with landmark: %s!" % n_city["landmark"]
		]
		dest_clue_text = items[randi() % items.size()]
	else:
		dest_clue_text = "Hidden ledger confirms suspect was seen in %s!" % Database.CITIES[city_id]["name"]
	
	hotspots.append({
		"pos": Vector2(randf_range(160, 560), randf_range(120, 580)),
		"name": "DISCARDED TRAVEL DOCUMENT",
		"clue": dest_clue_text,
		"found": false
	})
	
	# Hotspot 2: Suspect Physical Trait Clue
	var trait_clue_text = ""
	var traits = [
		{"key": "vehicle", "name": "VEHICLE REGISTRATION STUB", "text": "Parking slip logged for a %s!" % suspect.get("vehicle", "Convertible")},
		{"key": "feature", "name": "LOST PERSONAL ITEM", "text": "Evidence recovered: %s matching suspect profile!" % suspect.get("feature", "Ruby Ring")},
		{"key": "hobby", "name": "MEMBERSHIP PASS", "text": "Club pass found for %s!" % suspect.get("hobby", "Tennis")}
	]
	var chosen_trait = traits[randi() % traits.size()]
	trait_clue_text = chosen_trait["text"]

	hotspots.append({
		"pos": Vector2(randf_range(720, 1120), randf_range(120, 580)),
		"name": chosen_trait["name"],
		"clue": trait_clue_text,
		"found": false
	})

func _process(delta: float) -> void:
	if not active:
		return
		
	if clue_dialog_active:
		return
		
	# D-Pad / Keyboard lens movement
	var move_dir := Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_dir.x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_dir.x += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move_dir.y -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move_dir.y += 1.0
		
	if move_dir != Vector2.ZERO:
		lens_pos += move_dir.normalized() * move_speed * delta
		lens_pos.x = clampf(lens_pos.x, 60.0, 1220.0)
		lens_pos.y = clampf(lens_pos.y, 70.0, 630.0)
		
	# Proximity audio ping
	var nearest_dist := 999.0
	for h in hotspots:
		if not h["found"]:
			var d = lens_pos.distance_to(h["pos"])
			if d < nearest_dist:
				nearest_dist = d
				
	if nearest_dist < 120.0:
		ping_timer -= delta
		var interval = clampf(nearest_dist / 280.0, 0.08, 0.45)
		if ping_timer <= 0.0:
			SoundManager.play_ping()
			ping_timer = interval
			
	if nearest_dist <= 36.0:
		hint_bar.text = "★ EVIDENCE DETECTED! PRESS [A] OR SPACE TO EXAMINE ★"
	else:
		hint_bar.text = "D-PAD: MOVE LENS | [A] EXAMINE SPOT | [B] RETURN"

	queue_redraw()

func _input(event: InputEvent) -> void:
	if not active:
		return
		
	if event is InputEventMouseMotion:
		if not clue_dialog_active:
			lens_pos = event.position
			lens_pos.x = clampf(lens_pos.x, 60.0, 1220.0)
			lens_pos.y = clampf(lens_pos.y, 70.0, 630.0)
			queue_redraw()
			
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_B or event.keycode == KEY_ESCAPE)):
		if clue_dialog_active:
			_dismiss_clue()
		else:
			_close_inspection()
		get_viewport().set_input_as_handled()
		return
		
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_A or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		if clue_dialog_active:
			_dismiss_clue()
		else:
			_try_examine()
		get_viewport().set_input_as_handled()
		return

func _try_examine() -> void:
	for h in hotspots:
		if not h["found"] and lens_pos.distance_to(h["pos"]) <= 42.0:
			h["found"] = true
			SoundManager.play_confirm()
			_show_clue(h)
			return
			
	# If clicked empty space
	SoundManager.play_cancel()

func _show_clue(h: Dictionary) -> void:
	clue_dialog_active = true
	active_clue_data = h
	clue_card.visible = true
	clue_title.text = "★ EVIDENCE RECOVERED: %s ★" % h["name"]
	clue_desc.text = "%s\n\n[color=#34d399]ACME bonus: +2 hours saved on investigation timeline![/color]" % h["clue"]
	clue_hint.text = "PRESS [A] OR SPACE TO COLLECT EVIDENCE"
	var max_h = GameManager.current_rank.get("deadline_hours", 48)
	GameManager.hours_left = mini(max_h, GameManager.hours_left + 2)
	GameManager.broadcast_time()
	evidence_discovered.emit(h["clue"])

func _dismiss_clue() -> void:
	clue_dialog_active = false
	clue_card.visible = false
	SoundManager.play_confirm()

func _close_inspection() -> void:
	active = false
	visible = false
	SoundManager.play_cancel()
	inspection_closed.emit()

func _draw() -> void:
	if not active:
		return
		
	# Draw Crime Scene Backdrop Props
	# Room floor & tiles
	draw_rect(Rect2(0, 48, 1280, 624), Color(0.06, 0.08, 0.12, 0.96))
	# Perspective grid lines
	for y in range(70, 660, 48):
		draw_line(Vector2(0, y), Vector2(1280, y), Color(0.10, 0.14, 0.20, 0.5), 1.0)
	for x in range(50, 1280, 80):
		draw_line(Vector2(x, 48), Vector2(x, 672), Color(0.10, 0.14, 0.20, 0.3), 1.0)
		
	# Furniture / Props silhouette
	# Desk / Counter
	draw_rect(Rect2(80, 360, 340, 180), Color(0.12, 0.15, 0.24, 0.9))
	draw_rect(Rect2(86, 368, 328, 16), Color(0.18, 0.24, 0.35, 1.0))
	# Safe / Cabinet
	draw_rect(Rect2(880, 160, 240, 340), Color(0.10, 0.12, 0.18, 0.95))
	draw_rect(Rect2(970, 300, 48, 48), Color(0.25, 0.30, 0.40, 1.0))
	# Archive Boxes
	draw_rect(Rect2(520, 460, 140, 90), Color(0.16, 0.13, 0.10, 0.9))
	draw_rect(Rect2(680, 480, 120, 70), Color(0.18, 0.15, 0.12, 0.9))

	# Draw Clue Hotspots (Subtle shimmering glints if not yet found)
	for h in hotspots:
		if not h["found"]:
			var d = lens_pos.distance_to(h["pos"])
			if d <= 60.0:
				# Sparkle glint when lens is nearby!
				draw_circle(h["pos"], 6.0, Color(1.0, 0.9, 0.4, 0.85))
				draw_line(h["pos"] - Vector2(10, 0), h["pos"] + Vector2(10, 0), Color(1.0, 1.0, 0.8), 2.0)
				draw_line(h["pos"] - Vector2(0, 10), h["pos"] + Vector2(0, 10), Color(1.0, 1.0, 0.8), 2.0)
		else:
			# Discovered marker
			draw_circle(h["pos"], 5.0, Color(0.2, 0.8, 0.4, 0.6))

	# Draw Magnifying Glass Reticle
	var is_locked := false
	for h in hotspots:
		if not h["found"] and lens_pos.distance_to(h["pos"]) <= 36.0:
			is_locked = true
			break
			
	var rim_color = Color(1.0, 0.85, 0.25) if is_locked else Color(0.35, 0.65, 0.95)
	var crosshair_color = Color(1.0, 0.95, 0.4, 0.9) if is_locked else Color(0.5, 0.75, 1.0, 0.5)

	# Lens glass fill
	draw_circle(lens_pos, lens_radius, Color(0.1, 0.35, 0.55, 0.25))
	# Rim
	draw_arc(lens_pos, lens_radius, 0.0, TAU, 32, rim_color, 2.5)
	draw_arc(lens_pos, lens_radius - 3.0, 0.0, TAU, 32, Color(0.08, 0.12, 0.2, 0.7), 1.2)
	
	# Crosshairs
	draw_line(lens_pos - Vector2(lens_radius * 0.7, 0), lens_pos - Vector2(6, 0), crosshair_color, 2.0)
	draw_line(lens_pos + Vector2(6, 0), lens_pos + Vector2(lens_radius * 0.7, 0), crosshair_color, 2.0)
	draw_line(lens_pos - Vector2(0, lens_radius * 0.7), lens_pos - Vector2(0, 6), crosshair_color, 2.0)
	draw_line(lens_pos + Vector2(0, 6), lens_pos + Vector2(0, lens_radius * 0.7), crosshair_color, 2.0)
	
	# Magnifier Handle
	var handle_start = lens_pos + Vector2(lens_radius * 0.7, lens_radius * 0.7)
	var handle_end = handle_start + Vector2(30.0, 30.0)
	draw_line(handle_start, handle_end, rim_color, 4.5)
	draw_line(handle_start + Vector2(3, 3), handle_end, Color(0.4, 0.2, 0.1), 2.5)
