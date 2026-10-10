extends Control
## TrapOverlay: V.I.L.E. Ambush Traps, Sabotage & Reaction Counter Minigame

signal trap_resolved(success: bool, bonus_clue: String)

var active: bool = false
var trap_type: String = "smoke" # "smoke", "blackout", "decoy"
var timer: float = 0.0
var max_timer: float = 2.4
var resolved: bool = false
var bonus_clue: String = ""

var smoke_particles: Array[Vector2] = []
var flicker_val: float = 1.0

@onready var alert_label: Label = $AlertBox/AlertLabel
@onready var desc_label: Label = $AlertBox/DescLabel
@onready var action_hint: Label = $AlertBox/ActionHint
@onready var timer_bar: ColorRect = $AlertBox/TimerBar
@onready var timer_bg: ColorRect = $AlertBox/TimerBg

func _ready() -> void:
	visible = false

func trigger_random_trap() -> void:
	var types = ["smoke", "blackout", "decoy"]
	trigger_trap(types.pick_random())

func trigger_trap(type: String) -> void:
	active = true
	visible = true
	resolved = false
	trap_type = type
	max_timer = 2.5
	timer = max_timer
	bonus_clue = ""
	
	SoundManager.play_siren()
	
	# Initialize smoke particles if smoke trap
	smoke_particles.clear()
	if trap_type == "smoke":
		for i in range(40):
			smoke_particles.append(Vector2(randf_range(0, 480), randf_range(40, 280)))
			
	_setup_trap_ui()
	queue_redraw()

func _setup_trap_ui() -> void:
	if trap_type == "smoke":
		alert_label.text = "⚡ V.I.L.E. SMOKE AMBUSH! ⚡"
		desc_label.text = "Henchman popped a blinding toxic smoke canister! You're losing visibility!"
		action_hint.text = "PRESS [B] OR ESC TO DIVE & VAULT CLEAR!"
	elif trap_type == "blackout":
		alert_label.text = "⚡ CIRCUIT SABOTAGE! BLACKOUT! ⚡"
		desc_label.text = "Power grid cut! Pitch black room! Footsteps are fading into the shadows!"
		action_hint.text = "PRESS [A] OR SPACE TO DEPLOY ACME UV BLACKLIGHT!"
	elif trap_type == "decoy":
		alert_label.text = "⚡ SUSPICIOUS WITNESS DETECTED! ⚡"
		desc_label.text = "Informant is stammering nervously and whispering into a hidden earpiece!"
		action_hint.text = "PRESS [A] OR SPACE TO DEPLOY POCKET LIE DETECTOR!"

func _process(delta: float) -> void:
	if not active:
		return
		
	if resolved:
		return

	timer -= delta
	
	# Animate smoke / blackout
	if trap_type == "smoke":
		for i in range(smoke_particles.size()):
			smoke_particles[i].x += randf_range(-15, 15) * delta
			smoke_particles[i].y -= 25.0 * delta
			if smoke_particles[i].y < 30:
				smoke_particles[i].y = 280.0
	elif trap_type == "blackout":
		flicker_val = 0.2 + 0.3 * sin(timer * 20.0)

	# Update Timer Bar
	if timer_bar and timer_bg:
		var ratio = clampf(timer / max_timer, 0.0, 1.0)
		timer_bar.size.x = timer_bg.size.x * ratio
		timer_bar.color = Color(0.2, 0.9, 0.4) if ratio > 0.35 else Color(1.0, 0.25, 0.25)

	if timer <= 0.0:
		_handle_trap_failure()

	queue_redraw()

func _input(event: InputEvent) -> void:
	if not active or resolved:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if trap_type == "smoke":
			if event.keycode == KEY_B or event.keycode == KEY_ESCAPE:
				_handle_trap_success()
				get_viewport().set_input_as_handled()
		elif trap_type == "blackout":
			if event.keycode == KEY_A or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
				_handle_trap_success()
				get_viewport().set_input_as_handled()
		elif trap_type == "decoy":
			if event.keycode == KEY_A or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
				_handle_trap_success()
				get_viewport().set_input_as_handled()

func _handle_trap_success() -> void:
	resolved = true
	SoundManager.play_gadget()
	var suspect = GameManager.current_criminal
	
	if trap_type == "smoke":
		alert_label.text = "★ NARROW ESCAPE! ★"
		desc_label.text = "Clean dive! You rolled under the toxic smoke cloud and cornered the witness!"
		action_hint.text = "PRESS [A] OR SPACE TO CONTINUE"
	elif trap_type == "blackout":
		alert_label.text = "★ UV BLACKLIGHT ACTIVATED! ★"
		bonus_clue = "Glowing phosphorescent footprints reveal suspect vehicle: %s!" % suspect.get("vehicle", "Convertible")
		desc_label.text = "UV beam illuminates the darkness! %s" % bonus_clue
		action_hint.text = "PRESS [A] OR SPACE TO CONTINUE"
	elif trap_type == "decoy":
		alert_label.text = "★ V.I.L.E. DECOY EXPOSED! ★"
		bonus_clue = "Polygraph needle spikes! Informant confesses: 'Thief has %s hair!' " % suspect.get("hair", "Red")
		desc_label.text = "Voice stress analyzer exposed the plant! %s" % bonus_clue
		action_hint.text = "PRESS [A] OR SPACE TO CONTINUE"
		
	await get_tree().create_timer(1.2).timeout
	_finish(true)

func _handle_trap_failure() -> void:
	resolved = true
	SoundManager.play_cancel()
	
	var penalty := 2
	if trap_type == "smoke":
		penalty = 3
		alert_label.text = "✖ AMBUSH HIT! DISORIENTED! ✖"
		desc_label.text = "Blinded and coughing in toxic fumes! Lost 3 hours recovering your bearings!"
	elif trap_type == "blackout":
		penalty = 2
		alert_label.text = "✖ STUMBLED IN THE DARK! ✖"
		desc_label.text = "Tripped over obstacles in the blacked-out room! Lost 2 hours!"
	elif trap_type == "decoy":
		penalty = 2
		alert_label.text = "✖ MISLED BY DECOY! ✖"
		desc_label.text = "The fake informant misled your search across town! Lost 2 hours!"

	action_hint.text = "PRESS [A] OR SPACE TO CONTINUE"
	GameManager.hours_left = maxi(1, GameManager.hours_left - penalty)
	GameManager.broadcast_time()

	await get_tree().create_timer(1.2).timeout
	_finish(false)

func _finish(success: bool) -> void:
	active = false
	visible = false
	trap_resolved.emit(success, bonus_clue)

func _draw() -> void:
	if not active:
		return

	if trap_type == "smoke":
		# Render thick smoke cloud circles
		for pt in smoke_particles:
			draw_circle(pt, randf_range(16.0, 32.0), Color(0.25, 0.22, 0.32, 0.45))
	elif trap_type == "blackout":
		# Render blackout darkness with red emergency strobe
		draw_rect(Rect2(0, 32, 480, 256), Color(0.01, 0.01, 0.02, 0.94))
		draw_rect(Rect2(20, 40, 440, 240), Color(0.8, 0.1, 0.1, 0.15 * flicker_val))
	elif trap_type == "decoy":
		# Shady vignette overlay
		draw_rect(Rect2(0, 32, 480, 256), Color(0.12, 0.08, 0.04, 0.7))
