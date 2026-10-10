extends Control
## WeatherOverlay: Lightweight Retro Pixel Weather & Atmospheric Night Stars

var active_weather: String = "clear"
var is_night_time: bool = false
var particles: Array = []
var max_particles: int = 36

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_init_particles()

func _init_particles() -> void:
	particles.clear()
	for i in range(max_particles):
		particles.append({
			"pos": Vector2(randf_range(0, 480), randf_range(0, 144)),
			"vel": Vector2.ZERO,
			"phase": randf_range(0, TAU),
			"speed": randf_range(0.8, 1.4)
		})

func set_city_weather(city_id: String, hour_of_day: int) -> void:
	is_night_time = (hour_of_day >= 20 or hour_of_day < 6)
	
	match city_id:
		"london": active_weather = "rain"
		"tokyo": active_weather = "drizzle"
		"moscow", "reykjavik": active_weather = "snow"
		"cairo": active_weather = "sand"
		"nairobi": active_weather = "dust"
		"sanfrancisco": active_weather = "fog"
		_: active_weather = "stars" if is_night_time else "clear"

	_init_particles()
	queue_redraw()

func _process(delta: float) -> void:
	if active_weather == "clear" and not is_night_time:
		return

	var w_size = size
	if w_size.x <= 0:
		w_size = Vector2(480, 144)

	for p in particles:
		p["phase"] += delta * 2.5
		match active_weather:
			"rain":
				p["pos"].y += 180.0 * p["speed"] * delta
				p["pos"].x -= 40.0 * delta
			"drizzle":
				p["pos"].y += 120.0 * p["speed"] * delta
				p["pos"].x -= 20.0 * delta
			"snow":
				p["pos"].y += 45.0 * p["speed"] * delta
				p["pos"].x += sin(p["phase"]) * 20.0 * delta
			"sand":
				p["pos"].x += 160.0 * p["speed"] * delta
				p["pos"].y += sin(p["phase"] * 1.5) * 15.0 * delta
			"dust":
				p["pos"].x += 60.0 * p["speed"] * delta
				p["pos"].y += sin(p["phase"]) * 10.0 * delta
			"fog":
				p["pos"].x += 25.0 * p["speed"] * delta
			"stars":
				pass # Twinkle in place

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
	match active_weather:
		"rain":
			var col = Color(0.65, 0.82, 0.98, 0.65)
			for p in particles:
				var start = p["pos"]
				var end = start + Vector2(-3, 8)
				draw_line(start, end, col, 1.0)
		"drizzle":
			var col = Color(0.70, 0.85, 1.0, 0.45)
			for p in particles:
				var start = p["pos"]
				var end = start + Vector2(-2, 5)
				draw_line(start, end, col, 1.0)
		"snow":
			for p in particles:
				var alpha = 0.5 + 0.5 * sin(p["phase"])
				var col = Color(0.95, 0.98, 1.0, alpha * 0.8)
				draw_rect(Rect2(p["pos"], Vector2(2, 2)), col)
		"sand":
			var col = Color(0.95, 0.80, 0.45, 0.55)
			for p in particles:
				draw_rect(Rect2(p["pos"], Vector2(2, 1)), col)
		"dust":
			var col = Color(0.85, 0.75, 0.55, 0.40)
			for p in particles:
				draw_rect(Rect2(p["pos"], Vector2(1, 1)), col)
		"fog":
			var col = Color(0.80, 0.88, 0.95, 0.25)
			for p in particles:
				draw_rect(Rect2(p["pos"], Vector2(24, 4)), col)
		"stars":
			for p in particles:
				var alpha = 0.3 + 0.7 * absf(sin(p["phase"]))
				var col = Color(1.0, 0.95, 0.7, alpha)
				draw_rect(Rect2(p["pos"], Vector2(1, 1)), col)
				if alpha > 0.85:
					draw_rect(Rect2(p["pos"] + Vector2(1, 0), Vector2(1, 1)), Color(1.0, 1.0, 1.0, alpha * 0.5))
					draw_rect(Rect2(p["pos"] + Vector2(-1, 0), Vector2(1, 1)), Color(1.0, 1.0, 1.0, alpha * 0.5))
