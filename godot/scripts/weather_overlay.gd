extends Control
## WeatherOverlay: Dynamic Multi-Layer Cinematic Skyline Animator & Landmark Kinetics

var current_city_id: String = "london"
var current_hour: int = 12
var active_weather: String = "clear"
var is_night_time: bool = false
var is_sunset: bool = false

var particles: Array = []
var max_particles: int = 72
var clouds: Array = []
var anim_time: float = 0.0

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_init_clouds()
	_init_particles()

func _init_clouds() -> void:
	clouds.clear()
	for i in range(4):
		clouds.append({
			"pos": Vector2(float(i * 360 + randf_range(0, 100)), randf_range(16.0, 72.0)),
			"speed": randf_range(12.0, 22.0),
			"width": randf_range(90.0, 160.0),
			"height": randf_range(24.0, 38.0)
		})

func _init_particles() -> void:
	particles.clear()
	for i in range(max_particles):
		particles.append({
			"pos": Vector2(randf_range(0, 1280), randf_range(0, 320)),
			"vel": Vector2.ZERO,
			"phase": randf_range(0, TAU),
			"speed": randf_range(0.8, 1.4)
		})

func set_city_weather(city_id: String, hour_of_day: int) -> void:
	current_city_id = city_id
	current_hour = hour_of_day
	is_night_time = (hour_of_day >= 20 or hour_of_day < 6)
	is_sunset = (hour_of_day >= 17 and hour_of_day < 20)
	
	match city_id:
		"london": active_weather = "rain"
		"tokyo": active_weather = "petals" if not is_night_time else "drizzle"
		"moscow", "reykjavik": active_weather = "snow"
		"cairo": active_weather = "sand"
		"nairobi": active_weather = "dust"
		"sanfrancisco": active_weather = "fog"
		_: active_weather = "stars" if is_night_time else "clear"

	_init_particles()
	queue_redraw()

func _process(delta: float) -> void:
	anim_time += delta
	var w_size = size
	if w_size.x <= 0:
		w_size = Vector2(1280, 320)

	# 1. Update drifting clouds
	for c in clouds:
		c["pos"].x += c["speed"] * delta
		if c["pos"].x > w_size.x + 120.0:
			c["pos"].x = -160.0
			c["pos"].y = randf_range(16.0, 72.0)

	# 2. Update weather particles
	for p in particles:
		p["phase"] += delta * 2.5
		match active_weather:
			"rain":
				p["pos"].y += 240.0 * p["speed"] * delta
				p["pos"].x -= 50.0 * delta
			"drizzle":
				p["pos"].y += 140.0 * p["speed"] * delta
				p["pos"].x -= 25.0 * delta
			"snow":
				p["pos"].y += 48.0 * p["speed"] * delta
				p["pos"].x += sin(p["phase"]) * 22.0 * delta
			"sand":
				p["pos"].x += 180.0 * p["speed"] * delta
				p["pos"].y += sin(p["phase"] * 1.5) * 16.0 * delta
			"dust":
				p["pos"].x += 70.0 * p["speed"] * delta
				p["pos"].y += sin(p["phase"]) * 12.0 * delta
			"fog":
				p["pos"].x += 28.0 * p["speed"] * delta
			"petals":
				p["pos"].y += 35.0 * p["speed"] * delta
				p["pos"].x += sin(p["phase"] * 0.8) * 32.0 * delta + 20.0 * delta
			"stars":
				pass

		# Wrap boundaries
		if p["pos"].y > w_size.y:
			p["pos"].y = 0.0
			p["pos"].x = randf_range(0, w_size.x)
		elif p["pos"].y < 0.0:
			p["pos"].y = w_size.y
		if p["pos"].x > w_size.x:
			p["pos"].x = 0.0
		elif p["pos"].x < 0.0:
			p["pos"].x = w_size.x

	queue_redraw()

func _draw() -> void:
	# LAYER 1: Celestial Orb & Drifting Clouds (Far Sky)
	_draw_celestial_bodies()
	_draw_clouds()

	# LAYER 2: City-Specific Kinetic Landmark Animations
	_draw_kinetic_landmarks()

	# LAYER 3: Atmospheric Weather & Ambient Particles
	_draw_weather_particles()

	# LAYER 4: Scenic Water Reflection Waves (For coastal & river cities)
	_draw_water_reflections()

func _draw_celestial_bodies() -> void:
	if is_night_time:
		# Luminous Crescent Moon
		var moon_pos = Vector2(1120, 75)
		draw_circle(moon_pos, 22.0, Color(0.96, 0.94, 0.82, 0.95))
		draw_circle(moon_pos + Vector2(7, -4), 18.0, Color(0.08, 0.11, 0.19, 0.98))
		# Moon corona glow
		draw_arc(moon_pos, 26.0, 0, TAU, 32, Color(1.0, 0.95, 0.7, 0.25), 2.0)
	elif is_sunset:
		# Deep Crimson/Amber Sunset Sun
		var sun_pos = Vector2(980, 110)
		draw_circle(sun_pos, 28.0, Color(1.0, 0.45, 0.2, 0.85))
		draw_circle(sun_pos, 38.0, Color(1.0, 0.6, 0.2, 0.3))
	else:
		# Morning / Midday Sun
		var sun_pos = Vector2(1040, 68)
		draw_circle(sun_pos, 24.0, Color(1.0, 0.92, 0.45, 0.9))
		draw_arc(sun_pos, 32.0, 0, TAU, 32, Color(1.0, 0.85, 0.3, 0.3), 3.0)

	# Undulating Aurora Borealis for Reykjavik & Moscow at night
	if is_night_time and (current_city_id == "reykjavik" or current_city_id == "moscow"):
		for ribbon in range(3):
			var pts = PackedVector2Array()
			var y_base = 45.0 + float(ribbon) * 18.0
			for px in range(0, 1281, 40):
				var wave = sin(float(px) * 0.006 + anim_time * 1.2 + float(ribbon) * 1.5) * 14.0
				pts.append(Vector2(px, y_base + wave))
			var col = Color(0.2, 0.95, 0.6, 0.22) if ribbon % 2 == 0 else Color(0.65, 0.35, 0.95, 0.18)
			for i in range(pts.size() - 1):
				draw_line(pts[i], pts[i + 1], col, 12.0)

func _draw_clouds() -> void:
	if active_weather == "rain" or active_weather == "drizzle":
		# Heavy overcast rainclouds
		for c in clouds:
			draw_rect(Rect2(c["pos"], Vector2(c["width"] * 1.3, c["height"] * 1.2)), Color(0.18, 0.22, 0.32, 0.45))
	else:
		# Soft drifting cumulus puffs
		var cloud_col = Color(0.9, 0.92, 0.98, 0.22) if not is_night_time else Color(0.2, 0.25, 0.38, 0.25)
		for c in clouds:
			var p = c["pos"]
			var w = c["width"]
			var h = c["height"]
			draw_circle(p + Vector2(w * 0.3, h * 0.5), h * 0.5, cloud_col)
			draw_circle(p + Vector2(w * 0.5, h * 0.4), h * 0.65, cloud_col)
			draw_circle(p + Vector2(w * 0.7, h * 0.5), h * 0.5, cloud_col)
			draw_rect(Rect2(p + Vector2(w * 0.2, h * 0.5), Vector2(w * 0.6, h * 0.45)), cloud_col)

func _draw_kinetic_landmarks() -> void:
	match current_city_id:
		"london":
			# Big Ben Illuminated Clock Face (Clock Tower)
			var clock_pos = Vector2(412, 136)
			var clock_glow = 0.75 + 0.25 * sin(anim_time * 3.0)
			draw_circle(clock_pos, 11.0, Color(1.0, 0.92, 0.55, 0.95 * clock_glow))
			draw_circle(clock_pos, 8.5, Color(0.12, 0.16, 0.25, 1.0))
			# Moving clock hands
			var hour_angle = (float(current_hour % 12) / 12.0) * TAU - PI * 0.5
			var min_angle = (anim_time * 0.4) * TAU - PI * 0.5
			draw_line(clock_pos, clock_pos + Vector2(cos(hour_angle), sin(hour_angle)) * 4.5, Color(1.0, 0.88, 0.4), 1.8)
			draw_line(clock_pos, clock_pos + Vector2(cos(min_angle), sin(min_angle)) * 6.5, Color(1.0, 0.88, 0.4), 1.2)
			# Tower Bridge Red Marine Strobe
			var strobe = 1.0 if (int(anim_time * 2.0) % 2 == 0) else 0.2
			draw_circle(Vector2(850, 158), 4.0, Color(1.0, 0.2, 0.25, strobe))

		"paris":
			# Eiffel Tower Sweeping Night Searchlight Beacon
			var tower_apex = Vector2(640, 88)
			draw_circle(tower_apex, 3.5, Color(1.0, 0.95, 0.6, 0.9))
			var sweep_angle = sin(anim_time * 1.1) * 0.75 - PI * 0.5
			var beam_len = 160.0
			var beam_end1 = tower_apex + Vector2(cos(sweep_angle - 0.12), sin(sweep_angle - 0.12)) * beam_len
			var beam_end2 = tower_apex + Vector2(cos(sweep_angle + 0.12), sin(sweep_angle + 0.12)) * beam_len
			var beam_col = Color(1.0, 0.95, 0.7, 0.16 if is_night_time else 0.08)
			draw_polygon(PackedVector2Array([tower_apex, beam_end1, beam_end2]), PackedColorArray([beam_col, Color(1.0, 1.0, 1.0, 0.0), Color(1.0, 1.0, 1.0, 0.0)]))

		"tokyo":
			# Pulsing Neon Arcade Billboards (Cyan & Magenta)
			var pulse1 = 0.5 + 0.5 * sin(anim_time * 4.0)
			var pulse2 = 0.5 + 0.5 * cos(anim_time * 3.5)
			draw_rect(Rect2(720, 160, 26, 12), Color(0.2, 0.85, 1.0, 0.75 * pulse1))
			draw_rect(Rect2(724, 163, 18, 6), Color(1.0, 1.0, 1.0, 0.9 * pulse1))
			draw_rect(Rect2(910, 148, 30, 14), Color(0.96, 0.25, 0.45, 0.75 * pulse2))
			draw_rect(Rect2(914, 151, 22, 8), Color(1.0, 1.0, 1.0, 0.9 * pulse2))
			# Tokyo Tower Red Obstruction Beacon
			var beacon = 1.0 if (int(anim_time * 2.5) % 2 == 0) else 0.2
			draw_circle(Vector2(835, 112), 4.0, Color(1.0, 0.2, 0.2, beacon))

		"newyork":
			# Empire State Building Top Spire Aviation Strobe
			var esb_apex = Vector2(620, 92)
			var blink = 1.0 if (fmod(anim_time, 1.4) < 0.25) else 0.2
			draw_circle(esb_apex, 4.5, Color(1.0, 0.25, 0.25, blink))
			draw_circle(esb_apex, 8.0, Color(1.0, 0.25, 0.25, 0.3 * blink))

		"cairo":
			# Golden Desert Heat Shimmer above Giza Plateau
			for i in range(6):
				var hx = 350.0 + float(i) * 110.0
				var hy = 180.0 + sin(anim_time * 3.0 + float(i)) * 6.0
				draw_line(Vector2(hx, hy), Vector2(hx + 40, hy - 3), Color(1.0, 0.8, 0.3, 0.25), 2.0)

		"sanfrancisco":
			# Rolling Pacific Ocean Fog Bank through Golden Gate Cables
			var fog_offset = fmod(anim_time * 20.0, 600.0)
			for f in range(3):
				var fx = 300.0 + float(f * 260) - fog_offset * 0.4
				draw_rect(Rect2(fx, 190 + f * 18, 220, 24), Color(0.85, 0.90, 0.96, 0.22))

		"sydney":
			# Harbor Bridge Navigational Beacon
			var beacon_syd = 1.0 if (int(anim_time * 1.8) % 2 == 0) else 0.3
			draw_circle(Vector2(780, 165), 3.5, Color(0.2, 0.9, 0.4, beacon_syd))

func _draw_weather_particles() -> void:
	match active_weather:
		"rain":
			var col = Color(0.65, 0.82, 0.98, 0.65)
			for p in particles:
				var start = p["pos"]
				var end = start + Vector2(-4, 11)
				draw_line(start, end, col, 1.2)
		"drizzle":
			var col = Color(0.70, 0.85, 1.0, 0.45)
			for p in particles:
				var start = p["pos"]
				var end = start + Vector2(-2, 6)
				draw_line(start, end, col, 1.0)
		"snow":
			for p in particles:
				var alpha = 0.5 + 0.5 * sin(p["phase"])
				var col = Color(0.95, 0.98, 1.0, alpha * 0.85)
				draw_rect(Rect2(p["pos"], Vector2(2.5, 2.5)), col)
		"petals":
			for p in particles:
				var alpha = 0.6 + 0.4 * sin(p["phase"])
				var col = Color(1.0, 0.72, 0.82, alpha * 0.8)
				draw_rect(Rect2(p["pos"], Vector2(3.0, 2.0)), col)
		"sand":
			var col = Color(0.95, 0.80, 0.45, 0.55)
			for p in particles:
				draw_rect(Rect2(p["pos"], Vector2(3.0, 1.5)), col)
		"dust":
			var col = Color(0.85, 0.75, 0.55, 0.40)
			for p in particles:
				draw_rect(Rect2(p["pos"], Vector2(1.5, 1.5)), col)
		"fog":
			var col = Color(0.80, 0.88, 0.95, 0.28)
			for p in particles:
				draw_rect(Rect2(p["pos"], Vector2(40.0, 6.0)), col)
		"stars":
			for p in particles:
				var alpha = 0.3 + 0.7 * absf(sin(p["phase"]))
				var col = Color(1.0, 0.95, 0.7, alpha)
				draw_rect(Rect2(p["pos"], Vector2(1.5, 1.5)), col)
				if alpha > 0.85:
					draw_rect(Rect2(p["pos"] + Vector2(1.5, 0), Vector2(1.5, 1.5)), Color(1.0, 1.0, 1.0, alpha * 0.5))
					draw_rect(Rect2(p["pos"] + Vector2(-1.5, 0), Vector2(1.5, 1.5)), Color(1.0, 1.0, 1.0, alpha * 0.5))

func _draw_water_reflections() -> void:
	# Check if destination is a river or coastal city
	var water_cities = ["london", "paris", "sydney", "rio", "sanfrancisco", "newyork"]
	if not water_cities.has(current_city_id):
		return

	# Lower waterfront band (y = 296 to 320)
	var water_rect = Rect2(0, 296, 1280, 24)
	draw_rect(water_rect, Color(0.04, 0.08, 0.15, 0.75))

	# Shimmering water ripple reflection lines
	for wy in range(298, 318, 4):
		var row_ratio = float(wy - 298) / 20.0
		var line_col = Color(0.3, 0.65, 0.95, 0.25 + 0.2 * row_ratio)
		for x in range(0, 1280, 48):
			var wave = sin(float(x) * 0.04 + anim_time * 2.5 + float(wy)) * 12.0
			var start_x = float(x) + wave
			draw_line(Vector2(start_x, wy), Vector2(start_x + 28.0, wy), line_col, 1.2)
