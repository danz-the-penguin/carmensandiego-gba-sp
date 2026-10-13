extends Control
## InspectOverlay: Tactile Magnifying Glass Crime Scene Search & UV Document Examination Minigame

signal inspection_closed
signal evidence_discovered(clue_text: String)

enum Mode { SCENE_SEARCH, DOCUMENT_EXAMINE }

var active: bool = false
var current_mode: Mode = Mode.SCENE_SEARCH
var lens_pos: Vector2 = Vector2(640, 360)
var lens_radius: float = 42.0
var move_speed: float = 360.0
var ping_timer: float = 0.0
var uv_active: bool = false

var hotspots: Array[Dictionary] = []
var current_place_name: String = ""
var clue_dialog_active: bool = false
var active_clue_data: Dictionary = {}
var active_doc_data: Dictionary = {}

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
	current_mode = Mode.SCENE_SEARCH
	uv_active = false
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

func start_document_inspection(doc_data: Dictionary = {}) -> void:
	current_mode = Mode.DOCUMENT_EXAMINE
	uv_active = false
	active = true
	visible = true
	lens_pos = Vector2(640, 360)
	clue_dialog_active = false
	if clue_card:
		clue_card.visible = false

	var city_id = GameManager.current_city_id
	var trail = GameManager.current_trail
	var curr_idx = trail.find(city_id)
	var next_city_id = ""
	if curr_idx != -1 and curr_idx < trail.size() - 1:
		next_city_id = trail[curr_idx + 1]

	var next_city_name = Database.CITIES[next_city_id]["name"] if (next_city_id != "" and Database.CITIES.has(next_city_id)) else "CONFIDENTIAL HUB"
	var next_country = Database.CITIES[next_city_id]["country"].to_upper() if (next_city_id != "" and Database.CITIES.has(next_city_id)) else "UNKNOWN"
	var suspect = GameManager.current_criminal
	
	var secret_text = "[UV FORENSIC PASS] Flight ticket routing stamped for %s (%s)! Suspect trait: %s %s!" % [next_city_name, next_country, suspect.get("hair", "Unknown"), suspect.get("vehicle", "Vehicle")]
	
	active_doc_data = {
		"title": "TRANS-CONTINENTAL BOARDING PASS & FLIGHT MANIFEST",
		"carrier": "ACME TRANSIT COURIER AIRWAYS",
		"flight_no": "ACME-%03d" % randi_range(200, 999),
		"origin": Database.CITIES[city_id]["name"].to_upper(),
		"dest": next_city_name.to_upper(),
		"passenger": "ALIAS: " + suspect.get("name", "V.I.L.E. OPERATIVE").to_upper(),
		"secret_clue": secret_text,
		"secret_pos": Vector2(740, 360),
		"found": false
	}
	
	hotspots.clear()
	hotspots.append({
		"pos": active_doc_data["secret_pos"],
		"name": "SECRET UV FLUORESCENT ANNOTATION",
		"clue": secret_text,
		"found": false
	})
	
	status_label.text = "TACTILE FORENSIC EXAMINATION: " + active_doc_data["title"]
	hint_bar.text = "D-PAD: MOVE LOUPE | [A] / [U] TOGGLE UV BLACKLIGHT | [SPACE] COLLECT LEAD | [B] BACK"
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
	var traits = [
		{"key": "vehicle", "name": "VEHICLE REGISTRATION STUB", "text": "Parking slip logged for a %s!" % suspect.get("vehicle", "Convertible")},
		{"key": "feature", "name": "LOST PERSONAL ITEM", "text": "Evidence recovered: %s matching suspect profile!" % suspect.get("feature", "Ruby Ring")},
		{"key": "hobby", "name": "MEMBERSHIP PASS", "text": "Club pass found for %s!" % suspect.get("hobby", "Tennis")}
	]
	var chosen_trait = traits[randi() % traits.size()]

	hotspots.append({
		"pos": Vector2(randf_range(720, 1120), randf_range(120, 580)),
		"name": chosen_trait["name"],
		"clue": chosen_trait["text"],
		"found": false
	})

func _process(delta: float) -> void:
	if not active:
		return
		
	if clue_dialog_active:
		return
		
	# D-Pad / Keyboard lens movement
	var move_dir := Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_LEFT):
		move_dir.x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_RIGHT):
		move_dir.x += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_UP):
		move_dir.y -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_DOWN):
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
			
	if current_mode == Mode.DOCUMENT_EXAMINE:
		if uv_active:
			if nearest_dist <= 50.0:
				hint_bar.text = "★ GLOWING ANNOTATION DETECTED! PRESS [SPACE] TO COLLECT ★"
			else:
				hint_bar.text = "UV BLACKLIGHT ON | SWEEP LOUPE OVER DOCUMENT | [A]/[U] TOGGLE | [B] BACK"
		else:
			hint_bar.text = "DOCUMENT EXAM: MICROPRINT SMUDGED | [A]/[U] TOGGLE UV BLACKLIGHT | [B] BACK"
	else:
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

	if current_mode == Mode.DOCUMENT_EXAMINE:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_U or event.keycode == KEY_A:
				if not clue_dialog_active:
					uv_active = not uv_active
					SoundManager.play_uv_toggle()
					queue_redraw()
					get_viewport().set_input_as_handled()
					return
		if event.is_action_pressed("gba_a"):
			if not clue_dialog_active:
				uv_active = not uv_active
				SoundManager.play_uv_toggle()
				queue_redraw()
				get_viewport().set_input_as_handled()
				return

	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		if clue_dialog_active:
			_dismiss_clue()
		else:
			_try_examine()
		get_viewport().set_input_as_handled()
		return

func _try_examine() -> void:
	if current_mode == Mode.DOCUMENT_EXAMINE:
		for h in hotspots:
			if not h["found"] and lens_pos.distance_to(h["pos"]) <= 52.0:
				if uv_active:
					h["found"] = true
					SoundManager.play_hold_it()
					SoundManager.play_breakthrough()
					_show_clue(h)
					return
				else:
					SoundManager.play_cancel()
					hint_bar.text = "Microprint invisible to naked eye! Press [U] / [A] to deploy UV Blacklight!"
					return
		if not uv_active:
			uv_active = true
			SoundManager.play_uv_toggle()
			queue_redraw()
		else:
			SoundManager.play_cancel()
	else:
		for h in hotspots:
			if not h["found"] and lens_pos.distance_to(h["pos"]) <= 42.0:
				h["found"] = true
				SoundManager.play_confirm()
				_show_clue(h)
				return
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
		
	if current_mode == Mode.DOCUMENT_EXAMINE:
		_draw_document_view()
	else:
		_draw_scene_search_view()

	# Draw Magnifying Loupe Reticle
	_draw_magnifying_loupe()

func _draw_document_view() -> void:
	# Inspection desk background
	if uv_active:
		draw_rect(Rect2(0, 48, 1280, 624), Color(0.05, 0.03, 0.16, 0.98))
		# Subtle UV ambient fluorescent speckles
		for i in range(12):
			var sp := Vector2(280 + i * 65, 180 + (i * 37) % 360)
			draw_circle(sp, 2.0, Color(0.3, 0.85, 1.0, 0.35))
	else:
		draw_rect(Rect2(0, 48, 1280, 624), Color(0.08, 0.10, 0.16, 0.98))
		
	# Boarding pass / ticket parchment card
	var doc_rect := Rect2(200, 140, 880, 420)
	if uv_active:
		draw_rect(doc_rect, Color(0.12, 0.08, 0.28, 1.0))
		draw_rect(doc_rect, Color(0.40, 0.25, 0.75, 1.0), false, 3.0)
	else:
		draw_rect(doc_rect, Color(0.94, 0.91, 0.83, 1.0))
		draw_rect(doc_rect, Color(0.72, 0.68, 0.58, 1.0), false, 3.0)

	# Header Banner
	var header_rect := Rect2(200, 140, 880, 52)
	var header_col = Color(0.22, 0.14, 0.48) if uv_active else Color(0.14, 0.22, 0.36)
	draw_rect(header_rect, header_col)

	# Dashed ticket perforation at x = 860
	var perf_x := 860.0
	for y in range(145, 555, 12):
		draw_line(Vector2(perf_x, y), Vector2(perf_x, y + 6), Color(0.5, 0.5, 0.5, 0.6), 1.5)

	if not uv_active:
		# Normal visible stamps & barcode
		# Carrier stamp (Red double circle)
		draw_arc(Vector2(380, 390), 44.0, 0.0, TAU, 32, Color(0.85, 0.2, 0.25, 0.8), 2.5)
		draw_arc(Vector2(380, 390), 38.0, 0.0, TAU, 32, Color(0.85, 0.2, 0.25, 0.6), 1.5)
		# Indigo customs approval stamp
		draw_rect(Rect2(520, 240, 110, 48), Color(0.2, 0.35, 0.7, 0.75), false, 2.0)
		
		# Barcode lines on right stub
		for bx in range(885, 1055, 6):
			var bar_w = 2.5 if bx % 12 == 0 else 1.2
			draw_line(Vector2(bx, 280), Vector2(bx, 360), Color(0.2, 0.2, 0.25, 0.9), bar_w)
			
		# Water-damaged blur over destination field
		draw_rect(Rect2(640, 320, 200, 48), Color(0.82, 0.79, 0.70, 0.95))
		# Blue ink lines
		draw_line(Vector2(240, 260), Vector2(500, 260), Color(0.18, 0.22, 0.32), 2.0)
		draw_line(Vector2(240, 320), Vector2(600, 320), Color(0.18, 0.22, 0.32), 2.0)
	else:
		# UV Blacklight Mode: Vivid Glowing Fluorescent Markings
		# Whorls of latent fingerprint over flight ticket
		var fp_center := Vector2(740, 360)
		for fp in range(4):
			draw_arc(fp_center, 12.0 + float(fp) * 9.0, -PI * 0.85, PI * 0.65, 24, Color(0.25, 0.95, 0.55, 0.85), 2.0)
		
		# Secret V.I.L.E. Covert Transit Stamp (Neon Cyan & Gold)
		draw_arc(fp_center, 44.0, 0.0, TAU, 32, Color(0.3, 0.85, 1.0, 0.9), 2.5)
		draw_circle(fp_center, 6.0, Color(1.0, 0.9, 0.3, 0.95))
		
		# Glowing security watermark ribbon
		for rx in range(240, 840, 36):
			var wy = 460.0 + sin(float(rx) * 0.04) * 16.0
			draw_circle(Vector2(rx, wy), 3.0, Color(0.3, 0.85, 1.0, 0.7))
			
		# Glowing invisible ink lines over destination
		draw_line(Vector2(620, 320), Vector2(850, 320), Color(0.25, 0.95, 0.55, 0.9), 2.5)
		draw_line(Vector2(620, 400), Vector2(850, 400), Color(0.25, 0.95, 0.55, 0.9), 2.5)

func _draw_scene_search_view() -> void:
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
				draw_circle(h["pos"], 6.0, Color(1.0, 0.9, 0.4, 0.85))
				draw_line(h["pos"] - Vector2(10, 0), h["pos"] + Vector2(10, 0), Color(1.0, 1.0, 0.8), 2.0)
				draw_line(h["pos"] - Vector2(0, 10), h["pos"] + Vector2(0, 10), Color(1.0, 1.0, 0.8), 2.0)
		else:
			draw_circle(h["pos"], 5.0, Color(0.2, 0.8, 0.4, 0.6))

func _draw_magnifying_loupe() -> void:
	var is_locked := false
	for h in hotspots:
		if not h["found"]:
			var target_dist = 50.0 if current_mode == Mode.DOCUMENT_EXAMINE else 36.0
			if lens_pos.distance_to(h["pos"]) <= target_dist:
				if current_mode == Mode.DOCUMENT_EXAMINE:
					if uv_active:
						is_locked = true
						break
				else:
					is_locked = true
					break
			
	var rim_color = Color(1.0, 0.85, 0.25) if is_locked else Color(0.35, 0.65, 0.95)
	var crosshair_color = Color(1.0, 0.95, 0.4, 0.9) if is_locked else Color(0.5, 0.75, 1.0, 0.5)

	# Lens glass fill
	var glass_fill = Color(0.2, 0.1, 0.4, 0.25) if (current_mode == Mode.DOCUMENT_EXAMINE and uv_active) else Color(0.1, 0.35, 0.55, 0.25)
	draw_circle(lens_pos, lens_radius, glass_fill)
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
