extends Node
## GameManager: Core Procedural Case Generation, Time Management & GBA Controls

signal case_started
signal city_changed(city_data: Dictionary)
signal time_updated(hours_left: int, day_str: String, time_str: String)
signal clue_found(clue_text: String)
signal warrant_issued(suspect_name: String)
signal case_resolved(is_victory: bool, message: String)
signal light_mode_changed(mode_name: String)
signal shell_changed(shell_id: String, shell_data: Dictionary)
signal title_requested

enum State { TITLE, BRIEFING, CITY_HUB, DOSSIER, CRIME_COMPUTER, ARREST, GAMEOVER }

var current_state: State = State.TITLE

# Player Profile & Career Meta-Progression
var cases_solved: int = 0
var current_rank: Dictionary
var recovered_treasures: Array = []
var current_case_seed: String = "#ACME-1000"

# Phase 4: Speedrun Stopwatch & Daily Challenge State
var speedrun_active: bool = false
var speedrun_elapsed: float = 0.0
var speedrun_splits: Array[Dictionary] = []
var best_speedrun_time: float = 999999.0
var daily_records: Dictionary = {}
var is_daily_case: bool = false

# Unlockable GBA SP Console Shell Customizations
const SHELLS: Array[Dictionary] = [
	{"id": "platinum", "name": "PLATINUM SILVER", "cases": 0, "color": Color("#c4cad8")},
	{"id": "cobalt", "name": "COBALT BLUE", "cases": 1, "color": Color("#2563eb")},
	{"id": "flame", "name": "FLAME RED", "cases": 3, "color": Color("#dc2626")},
	{"id": "onyx", "name": "ONYX BLACK", "cases": 6, "color": Color("#1e293b")},
	{"id": "gold", "name": "TRIBAL GOLD", "cases": 10, "color": Color("#f59e0b")},
	{"id": "famicom", "name": "FAMICOM 20TH", "cases": 15, "color": Color("#831843")}
]
var current_shell_index: int = 0

# Tactical ACME Gadgets Inventory (Replenished each case)
var gadget_charges: Dictionary = {
	"uv_light": 2,
	"gps_tracer": 1,
	"lockpick": 2,
	"polygraph": 2
}


# Active Case
var current_treasure: String = ""
var current_criminal: Dictionary = {}
var current_trail: Array[String] = []
var current_clues: Dictionary = {}
var current_city_id: String = "london"
var hours_left: int = 40
var day_index: int = 0 # 0=MON
var hour_of_day: int = 9 # 9:00 AM

# Warrant & Notes
var warrant_suspect: Dictionary = {}
var clues_gathered: Array[String] = []
var computer_filters: Dictionary = {
	"sex": "", "hair": "", "vehicle": "", "hobby": "", "feature": ""
}

# GBA SP Light Modes: "ags101_bright", "ags101_normal", "ags001_frontlit"
var light_modes: Array[String] = ["ags101_bright", "ags101_normal", "ags001_frontlit"]
var light_mode_index: int = 0

const DAYS: Array[String] = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]

func _ready() -> void:
	load_profile()

func load_profile() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://detective_profile.cfg") == OK:
		cases_solved = cfg.get_value("player", "cases_solved", 0)
		recovered_treasures = cfg.get_value("player", "recovered_treasures", [])
		current_shell_index = cfg.get_value("player", "current_shell_index", 0)
		best_speedrun_time = cfg.get_value("player", "best_speedrun_time", 999999.0)
		daily_records = cfg.get_value("player", "daily_records", {})
	update_rank()

func save_profile() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "cases_solved", cases_solved)
	cfg.set_value("player", "recovered_treasures", recovered_treasures)
	cfg.set_value("player", "current_shell_index", current_shell_index)
	cfg.set_value("player", "best_speedrun_time", best_speedrun_time)
	cfg.set_value("player", "daily_records", daily_records)
	cfg.save("user://detective_profile.cfg")

func _process(delta: float) -> void:
	if speedrun_active and current_state in [State.BRIEFING, State.CITY_HUB, State.DOSSIER, State.CRIME_COMPUTER]:
		speedrun_elapsed += delta

func format_speedrun_time(t: float) -> String:
	if t >= 999990.0:
		return "--:--.-"
	var total_msec: int = int(t * 1000.0)
	var minutes: int = total_msec / 60000
	var seconds: int = (total_msec % 60000) / 1000
	var tenths: int = (total_msec % 1000) / 100
	return "%02d:%02d.%d" % [minutes, seconds, tenths]

func record_speedrun_split(split_name: String) -> void:
	var prev_time := 0.0
	if not speedrun_splits.is_empty():
		prev_time = speedrun_splits[-1]["time"]
	var delta := speedrun_elapsed - prev_time
	speedrun_splits.append({
		"name": split_name,
		"time": speedrun_elapsed,
		"delta": delta,
		"formatted": format_speedrun_time(speedrun_elapsed)
	})

func copy_seed_to_clipboard() -> String:
	DisplayServer.clipboard_set(current_case_seed)
	SoundManager.play_confirm()
	return current_case_seed

func start_daily_case() -> void:
	var today_str = Time.get_date_string_from_system()
	start_new_case("DAILY-%s" % today_str)

func is_today_daily_completed() -> bool:
	var today_str = Time.get_date_string_from_system()
	return daily_records.has(today_str)

func get_today_daily_record() -> Dictionary:
	var today_str = Time.get_date_string_from_system()
	return daily_records.get(today_str, {})


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("gba_light"):
		cycle_light_mode()

func update_rank() -> void:
	current_rank = Database.RANKS[0]
	for r in Database.RANKS:
		if cases_solved >= r["required_cases"]:
			current_rank = r

func cycle_shell() -> Dictionary:
	var unlocked: Array[int] = []
	for i in range(SHELLS.size()):
		if cases_solved >= SHELLS[i]["cases"]:
			unlocked.append(i)
	if unlocked.is_empty():
		unlocked = [0]
	var cur_pos = unlocked.find(current_shell_index)
	if cur_pos == -1:
		current_shell_index = unlocked[0]
	else:
		current_shell_index = unlocked[(cur_pos + 1) % unlocked.size()]
	save_profile()
	SoundManager.play_shoulder()
	shell_changed.emit(SHELLS[current_shell_index]["id"], SHELLS[current_shell_index])
	return SHELLS[current_shell_index]

func cycle_light_mode() -> void:
	light_mode_index = (light_mode_index + 1) % light_modes.size()
	SoundManager.play_light()
	light_mode_changed.emit(light_modes[light_mode_index])

# --- Procedural Case Generator ---
func start_new_case(seed_string: String = "", custom_params: Dictionary = {}) -> void:
	update_rank()
	if seed_string != "":
		current_case_seed = seed_string
	else:
		current_case_seed = "#ACME-%04d" % randi_range(1000, 9999)
	
	is_daily_case = current_case_seed.begins_with("DAILY-")
	
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(current_case_seed)
	
	var hops: int = current_rank["hops"]
	hours_left = current_rank["deadline_hours"]
	day_index = 0
	hour_of_day = 9
	warrant_suspect = {}
	clues_gathered.clear()
	computer_filters = {"sex": "", "hair": "", "vehicle": "", "hobby": "", "feature": ""}
	
	# Start speedrun stopwatch
	speedrun_active = true
	speedrun_elapsed = 0.0
	speedrun_splits.clear()
	record_speedrun_split("HQ Assignment")
	
	# Tactical Gadget Capacity Scales With Detective Rank
	var base_uv = 2 + (1 if cases_solved >= 2 else 0) + (1 if cases_solved >= 8 else 0) + (1 if cases_solved >= 12 else 0)
	var base_gps = 1 + (1 if cases_solved >= 5 else 0) + (1 if cases_solved >= 12 else 0)
	var base_lock = 2 + (1 if cases_solved >= 2 else 0) + (1 if cases_solved >= 8 else 0) + (1 if cases_solved >= 12 else 0)
	var base_poly = 2 + (1 if cases_solved >= 5 else 0) + (1 if cases_solved >= 12 else 0)
	gadget_charges = {
		"uv_light": base_uv,
		"gps_tracer": base_gps,
		"lockpick": base_lock,
		"polygraph": base_poly
	}

	# 1. Stolen treasure & start city
	var treasure_data: Dictionary = {}
	if custom_params.has("treasure"):
		for t in Database.TREASURES:
			if t["name"] == custom_params["treasure"]:
				treasure_data = t
				break
	if treasure_data.is_empty():
		treasure_data = Database.TREASURES[rng.randi_range(0, Database.TREASURES.size() - 1)]

	current_treasure = treasure_data["name"]
	var start_city: String = treasure_data["city"]
	current_city_id = start_city

	# 2. Culprit
	current_criminal = {}
	if custom_params.has("criminal"):
		for s in Database.SUSPECTS:
			if s["id"] == custom_params["criminal"] or s["name"] == custom_params["criminal"]:
				current_criminal = s
				break
	if current_criminal.is_empty():
		current_criminal = Database.SUSPECTS[rng.randi_range(0, Database.SUSPECTS.size() - 1)]
		if current_rank["title"] == "ACE DETECTIVE" and rng.randf() < 0.6:
			for s in Database.SUSPECTS:
				if s["id"] == "carmen":
					current_criminal = s
					break

	# 3. Flight trail
	current_trail = [start_city]
	var curr: String = start_city
	for i in range(hops):
		var city_dict: Dictionary = Database.CITIES[curr]
		var connections: Array = city_dict["connections"]
		var candidates: Array = []
		for c in connections:
			if not current_trail.has(c):
				candidates.append(c)
		var next_city: String = candidates[rng.randi_range(0, candidates.size() - 1)] if candidates.size() > 0 else connections[rng.randi_range(0, connections.size() - 1)]
		current_trail.append(next_city)
		curr = next_city

	# 4. Generate city clues
	current_clues.clear()
	var pronoun_subj = "She" if current_criminal["sex"] == "Female" else "He"
	var pronoun_poss = "her" if current_criminal["sex"] == "Female" else "his"
	var pronoun_obj = "her" if current_criminal["sex"] == "Female" else "him"

	for i in range(current_trail.size() - 1):
		var this_city: String = current_trail[i]
		var next_city: String = current_trail[i + 1]
		var next_data: Dictionary = Database.CITIES[next_city]

		var geo_clues: Array[String] = [
			"Exchanged money for " + next_data["currency"] + "!",
			"Flew to a country flying " + next_data["flag"] + ".",
			"Heard speaking " + next_data["language"] + ".",
			"Mentioned sight-seeing at " + next_data["landmark"] + "!"
		]
		# Seeded Fisher-Yates shuffle
		for idx in range(geo_clues.size() - 1, 0, -1):
			var swap_idx = rng.randi_range(0, idx)
			var temp = geo_clues[idx]
			geo_clues[idx] = geo_clues[swap_idx]
			geo_clues[swap_idx] = temp

		var trait_clues: Array[String] = [
			"%s had striking %s hair." % [pronoun_subj, current_criminal["hair"].to_upper()],
			"%s was seen driving off in a %s." % [pronoun_subj, current_criminal["vehicle"].to_upper()],
			"Heard %s talking about playing %s." % [pronoun_obj, current_criminal["hobby"].to_upper()],
			"%s was spotted wearing a %s!" % [pronoun_subj, current_criminal["feature"].to_upper()]
		]

		current_clues[this_city] = [
			geo_clues[0],
			geo_clues[1],
			trait_clues[i % trait_clues.size()]
		]

	var final_city: String = current_trail[-1]
	current_clues[final_city] = [
		"Suspect is cornered at the hideout! Ensure your warrant is issued!",
		"Witness confirms the fugitive is trapped inside!",
		"ACME backup is arriving! Close in for the arrest!"
	]

	current_state = State.BRIEFING
	case_started.emit()
	broadcast_time()

# --- Time & Navigation ---
func spend_hours(h: int) -> bool:
	hours_left = maxi(0, hours_left - h)
	hour_of_day += h

	while hour_of_day >= 24:
		hour_of_day -= 24
		day_index = (day_index + 1) % DAYS.size()

	# Bedtime penalty between 10 PM and 6 AM
	if hour_of_day >= 22 or hour_of_day < 6:
		hours_left = maxi(0, hours_left - 8)
		if hour_of_day >= 22:
			day_index = (day_index + 1) % DAYS.size()
		hour_of_day = 6
		SoundManager.play_cancel()

	broadcast_time()

	if hours_left <= 0:
		trigger_game_over()
		return false
	return true

func broadcast_time() -> void:
	var ampm: String = "PM" if hour_of_day >= 12 else "AM"
	var disp_hour: int = 12 if (hour_of_day % 12 == 0) else (hour_of_day % 12)
	var time_str: String = "%d%s" % [disp_hour, ampm]
	time_updated.emit(hours_left, DAYS[day_index], time_str)

func travel_to(destination_id: String) -> void:
	if not spend_hours(4):
		return
	current_city_id = destination_id
	var c_name: String = Database.CITIES[current_city_id]["name"]
	record_speedrun_split("Hop to %s" % c_name)
	city_changed.emit(Database.CITIES[current_city_id])

func investigate_place(place_index: int) -> void:
	if not spend_hours(2):
		return

	var clue_text := ""
	if current_clues.has(current_city_id):
		var city_clues: Array = current_clues[current_city_id]
		clue_text = city_clues[place_index % city_clues.size()]
	else:
		clue_text = "Nobody matching that description was seen here! You've lost the trail!"

	SoundManager.play_clue()
	var full_clue := "[%s] %s" % [Database.CITIES[current_city_id]["name"], clue_text]
	if not clues_gathered.has(full_clue):
		clues_gathered.append(full_clue)
	clue_found.emit(full_clue)

	# If final hideout reached
	if current_city_id == current_trail[-1] and not warrant_suspect.is_empty():
		attempt_arrest()

func return_to_title() -> void:
	speedrun_active = false
	title_requested.emit()

func attempt_arrest() -> void:
	current_state = State.ARREST
	if not warrant_suspect.is_empty() and warrant_suspect["id"] == current_criminal["id"]:
		SoundManager.play_victory()
		cases_solved += 1
		speedrun_active = false
		record_speedrun_split("Arrest %s" % current_criminal.get("name", "SUSPECT"))
		
		var speed_msg := "⏱ TIME: %s" % format_speedrun_time(speedrun_elapsed)
		if speedrun_elapsed < best_speedrun_time:
			best_speedrun_time = speedrun_elapsed
			speed_msg += " (NEW PERSONAL BEST!)"
		
		if is_daily_case:
			var today_str = Time.get_date_string_from_system()
			daily_records[today_str] = {
				"time": speedrun_elapsed,
				"formatted": format_speedrun_time(speedrun_elapsed),
				"treasure": current_treasure,
				"criminal": current_criminal.get("name", "SUSPECT")
			}
			speed_msg += " [DAILY CHALLENGE COMPLETE!]"
		
		var found_already = false
		for rec in recovered_treasures:
			if rec is Dictionary and rec.get("name") == current_treasure:
				found_already = true
				break
		if not found_already:
			var t_lore = ""
			var t_val = "$10,000,000"
			for t in Database.TREASURES:
				if t["name"] == current_treasure:
					t_lore = t.get("lore", "")
					t_val = t.get("value", "$10,000,000")
					break
			recovered_treasures.append({
				"name": current_treasure,
				"thief": current_criminal.get("name", "SUSPECT"),
				"city": current_city_id,
				"lore": t_lore,
				"value": t_val
			})

		save_profile()
		update_rank()
		var quote = current_criminal.get("quote", "Curses! Foiled again!")
		case_resolved.emit(true, "%s: \"%s\"\n\nCASE SOLVED! %s apprehended! %s recovered!\n%s\nPromotion: %s" % [current_criminal["name"], quote, current_criminal["name"], current_treasure, speed_msg, current_rank["title"]])
	else:
		speedrun_active = false
		SoundManager.play_game_over()
		var msg := "ALERT: You cornered %s without a valid warrant! The criminal escaped!" % current_criminal["name"] if warrant_suspect.is_empty() else "BLUNDER: Warrant was for %s, but thief was %s! Escaped!" % [warrant_suspect["name"], current_criminal["name"]]
		case_resolved.emit(false, msg)

func trigger_game_over() -> void:
	speedrun_active = false
	current_state = State.GAMEOVER
	SoundManager.play_game_over()
	case_resolved.emit(false, "TIME EXPIRED! The deadline passed and the thief escaped!")
