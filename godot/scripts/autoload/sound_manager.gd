extends Node
## SoundManager: Dual-Channel SFX Synthesizer + Catchy 8-bit Detective Groove BGM

var sfx_player: AudioStreamPlayer
var blip_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var bgm_enabled: bool = true
var current_region: String = "americas"

# Cached Audio Streams & Regional Banks
var regional_bgm: Dictionary = {}
var regional_ambient: Dictionary = {}
var wav_cursor: AudioStreamWAV
var wav_confirm: AudioStreamWAV
var wav_cancel: AudioStreamWAV
var wav_blip: AudioStreamWAV
var wav_shoulder: AudioStreamWAV
var wav_light: AudioStreamWAV
var wav_clue: AudioStreamWAV
var wav_travel: AudioStreamWAV
var wav_warrant: AudioStreamWAV
var wav_victory: AudioStreamWAV
var wav_game_over: AudioStreamWAV
var wav_impact: AudioStreamWAV
var wav_cuffs: AudioStreamWAV
var wav_static: AudioStreamWAV
var wav_radio_lock: AudioStreamWAV
var wav_ping: AudioStreamWAV
var wav_whoosh: AudioStreamWAV
var wav_siren: AudioStreamWAV
var wav_gadget: AudioStreamWAV
var wav_bgm: AudioStreamWAV


func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	blip_player = AudioStreamPlayer.new()
	blip_player.volume_db = -12.0
	bgm_player = AudioStreamPlayer.new()
	bgm_player.volume_db = -16.0
	ambient_player = AudioStreamPlayer.new()
	ambient_player.volume_db = -22.0
	add_child(sfx_player)
	add_child(blip_player)
	add_child(bgm_player)
	add_child(ambient_player)
	_cache_all_sounds()
	if GameManager.has_signal("city_changed"):
		GameManager.city_changed.connect(func(c_data): play_city_theme(c_data.get("id", "london")))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			toggle_bgm()

func _load_override(sound_name: String, fallback: AudioStream) -> AudioStream:
	var path_wav = "res://assets/audio/%s.wav" % sound_name
	var path_ogg = "res://assets/audio/%s.ogg" % sound_name
	if ResourceLoader.exists(path_wav):
		var res = load(path_wav)
		if res is AudioStream:
			return res
	elif ResourceLoader.exists(path_ogg):
		var res = load(path_ogg)
		if res is AudioStream:
			return res
	return fallback

func _cache_all_sounds() -> void:
	wav_cursor = _load_override("cursor", _create_tone_wav(440.0, 0.04, "square"))
	wav_confirm = _load_override("confirm", _create_tone_wav(660.0, 0.07, "square"))
	wav_cancel = _load_override("cancel", _create_tone_wav(260.0, 0.08, "square"))
	wav_blip = _load_override("blip", _create_tone_wav(900.0, 0.02, "triangle"))
	wav_shoulder = _load_override("shoulder", _create_tone_wav(700.0, 0.04, "triangle"))
	wav_light = _load_override("light", _create_tone_wav(1000.0, 0.03, "square"))
	wav_clue = _load_override("clue", _create_tone_wav(587.3, 0.15, "square"))
	wav_travel = _load_override("travel", _create_tone_wav(150.0, 0.35, "noise"))
	wav_warrant = _load_override("warrant", _create_tone_wav(880.0, 0.30, "square"))
	wav_victory = _load_override("victory", _create_tone_wav(1046.5, 0.45, "square"))
	wav_game_over = _load_override("game_over", _create_tone_wav(196.0, 0.45, "triangle"))
	wav_impact = _load_override("impact", _create_impact_wav())
	wav_cuffs = _load_override("cuffs", _create_cuffs_wav())
	wav_static = _load_override("static", _create_static_wav())
	wav_radio_lock = _load_override("radio_lock", _create_radio_lock_wav())
	wav_ping = _load_override("ping", _create_ping_wav())
	wav_whoosh = _load_override("whoosh", _create_whoosh_wav())
	wav_siren = _load_override("siren", _create_siren_wav())
	wav_gadget = _load_override("gadget", _create_gadget_wav())
	
	for reg in ["americas", "europe", "asia", "latin", "africa_mideast"]:
		regional_bgm[reg] = _load_override("bgm_" + reg, _create_regional_bgm(reg))
		regional_ambient[reg] = _load_override("ambient_" + reg, _create_ambient_foley(reg))

	wav_bgm = regional_bgm["americas"]
	bgm_player.stream = wav_bgm
	ambient_player.stream = regional_ambient["americas"]
	start_bgm()

func start_bgm() -> void:
	if bgm_enabled:
		if not bgm_player.playing:
			bgm_player.play()
		if not ambient_player.playing:
			ambient_player.play()

func stop_bgm() -> void:
	bgm_player.stop()
	ambient_player.stop()

func toggle_bgm() -> void:
	bgm_enabled = !bgm_enabled
	if bgm_enabled:
		bgm_player.play()
		ambient_player.play()
	else:
		bgm_player.stop()
		ambient_player.stop()

func get_region_for_city(city_id: String) -> String:
	match city_id.to_lower():
		"london", "paris", "rome", "athens", "moscow", "reykjavik":
			return "europe"
		"tokyo", "beijing", "kathmandu":
			return "asia"
		"rio", "mexicocity":
			return "latin"
		"cairo", "nairobi":
			return "africa_mideast"
		_:
			return "americas"

func play_city_theme(city_id: String) -> void:
	var reg := get_region_for_city(city_id)
	if reg == current_region and bgm_player.playing:
		return
	current_region = reg
	if regional_bgm.has(reg):
		var was_playing = bgm_player.playing
		bgm_player.stream = regional_bgm[reg]
		if bgm_enabled and (was_playing or not bgm_player.playing):
			bgm_player.play()
	if regional_ambient.has(reg):
		ambient_player.stream = regional_ambient[reg]
		if bgm_enabled:
			ambient_player.play()

func _create_tone_wav(freq: float, duration: float, wave_type: String) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	wav.stereo = false

	var sample_count := int(duration * wav.mix_rate)
	var data := PackedByteArray()
	data.resize(sample_count)

	var period := float(wav.mix_rate) / maxf(freq, 1.0)
	for i in range(sample_count):
		var val := 128
		var t := fmod(float(i), period) / period
		var env := 1.0 - (float(i) / float(sample_count))

		if wave_type == "square":
			val = int(128 + (120 if t < 0.5 else -120) * env)
		elif wave_type == "triangle":
			val = int(128 + ((4.0 * absf(t - 0.5) - 1.0) * 120.0 * env))
		elif wave_type == "noise":
			val = int(128 + (randf_range(-120.0, 120.0) * env))

		data[i] = clampi(val, 0, 255)

	wav.data = data
	return wav

func _create_regional_bgm(region: String) -> AudioStreamWAV:
	var rate := 22050
	var bpm := 125.0
	var total_steps := 32
	
	var notes := {
		"C2": 65.4, "Cs2": 69.3, "D2": 73.4, "Ds2": 77.8, "E2": 82.4, "F2": 87.3, "Fs2": 92.5, "G2": 98.0, "Gs2": 103.8, "A2": 110.0, "As2": 116.5, "B2": 123.5,
		"C3": 130.8, "Cs3": 138.6, "D3": 146.8, "Ds3": 155.6, "E3": 164.8, "F3": 174.6, "Fs3": 185.0, "G3": 196.0, "Gs3": 207.6, "A3": 220.0, "As3": 233.1, "B3": 246.9,
		"C4": 261.6, "Cs4": 277.2, "D4": 293.7, "Ds4": 311.1, "E4": 329.6, "F4": 349.2, "Fs4": 370.0, "G4": 392.0, "Gs4": 415.3, "A4": 440.0, "As4": 466.2, "B4": 493.9,
		"C5": 523.3, "D5": 587.3, "E5": 659.3, "G5": 784.0, "A5": 880.0, "REST": 0.0
	}
	
	var bass_pattern: Array = []
	var arp_pattern: Array = []
	var lead_wave_type := "triangle"
	
	match region:
		"europe":
			bpm = 112.0
			lead_wave_type = "square"
			bass_pattern = [
				"A2", "A2", "E2", "E2", "F2", "F2", "D2", "D2",
				"E2", "E2", "E2", "E2", "A2", "A2", "A2", "A2",
				"A2", "A2", "E2", "E2", "F2", "F2", "D2", "D2",
				"E2", "E2", "Gs2", "Gs2", "A2", "A2", "A2", "A2"
			]
			arp_pattern = [
				"A3", "C4", "E4", "C4", "E3", "B3", "E4", "B3",
				"F3", "C4", "F4", "C4", "D3", "A3", "D4", "A3",
				"E3", "B3", "E4", "B3", "E3", "Gs3", "B3", "E4",
				"A3", "C4", "E4", "A4", "A3", "E4", "C4", "A3"
			]
		"asia":
			bpm = 128.0
			lead_wave_type = "square"
			bass_pattern = [
				"A2", "A2", "A2", "A2", "D2", "D2", "D2", "D2",
				"E2", "E2", "E2", "E2", "A2", "A2", "A2", "A2",
				"C2", "C2", "C2", "C2", "D2", "D2", "D2", "D2",
				"E2", "E2", "E2", "E2", "A2", "A2", "A2", "A2"
			]
			arp_pattern = [
				"A3", "C4", "D4", "E4", "G4", "E4", "D4", "C4",
				"D4", "F4", "G4", "A4", "G4", "F4", "D4", "C4",
				"C4", "E4", "G4", "A4", "C5", "A4", "G4", "E4",
				"E4", "G4", "A4", "C5", "A4", "E4", "D4", "A3"
			]
		"latin":
			bpm = 120.0
			lead_wave_type = "triangle"
			bass_pattern = [
				"D2", "D2", "REST", "A2", "G2", "G2", "REST", "D2",
				"C2", "C2", "REST", "G2", "A2", "A2", "REST", "E2",
				"D2", "D2", "REST", "A2", "G2", "G2", "REST", "D2",
				"As2", "As2", "REST", "F2", "A2", "A2", "REST", "A2"
			]
			arp_pattern = [
				"F3", "A3", "C4", "D4", "F4", "D4", "C4", "A3",
				"B3", "D4", "G4", "B4", "G4", "D4", "B3", "G3",
				"E3", "G3", "C4", "E4", "G4", "E4", "C4", "G3",
				"Cs4", "E4", "A4", "Cs5", "A4", "E4", "Cs4", "A3"
			]
		"africa_mideast":
			bpm = 118.0
			lead_wave_type = "saw"
			bass_pattern = [
				"D2", "D2", "Ds2", "Ds2", "D2", "D2", "Ds2", "D2",
				"G2", "G2", "Fs2", "Fs2", "Ds2", "Ds2", "D2", "D2",
				"D2", "D2", "Ds2", "Ds2", "D2", "D2", "Ds2", "D2",
				"A2", "A2", "As2", "As2", "Fs2", "Fs2", "D2", "D2"
			]
			arp_pattern = [
				"D3", "Ds3", "Fs3", "G3", "A3", "As3", "A3", "Fs3",
				"G3", "A3", "As3", "C4", "As3", "A3", "G3", "Fs3",
				"D3", "Ds3", "Fs3", "G3", "A3", "As3", "C4", "D4",
				"C4", "As3", "A3", "G3", "Fs3", "Ds3", "Fs3", "D3"
			]
		_:
			bpm = 125.0
			lead_wave_type = "triangle"
			bass_pattern = [
				"D2", "D2", "D2", "D2", "F2", "F2", "F2", "F2",
				"G2", "G2", "G2", "G2", "A2", "A2", "A2", "A2",
				"D2", "D2", "D2", "D2", "C2", "C2", "C2", "C2",
				"G2", "G2", "G2", "G2", "A2", "A2", "A2", "A2"
			]
			arp_pattern = [
				"D3", "A3", "D4", "A3", "F3", "C4", "F3", "C4",
				"G3", "D4", "G3", "D4", "A3", "E4", "A3", "E4",
				"D3", "A3", "D4", "A3", "C3", "G3", "C4", "G3",
				"G3", "D4", "G3", "D4", "A3", "E4", "A3", "D4"
			]
	
	var step_duration := (60.0 / bpm) / 4.0
	var step_samples := int(step_duration * rate)
	var total_samples := step_samples * total_steps
	var data := PackedByteArray()
	data.resize(total_samples)
	
	var bass_phase := 0.0
	var arp_phase := 0.0
	
	for s in range(total_samples):
		var step_idx := (s / step_samples) % total_steps
		var sample_in_step := s % step_samples
		var env := maxf(0.0, 1.0 - (float(sample_in_step) / float(step_samples)))
		
		# Bass channel
		var b_note = bass_pattern[step_idx]
		var bass_val := 0.0
		if b_note != "REST" and notes.has(b_note):
			var b_freq: float = notes[b_note]
			bass_phase = fmod(bass_phase + (b_freq / rate), 1.0)
			bass_val = 0.28 * (1.0 if bass_phase < 0.5 else -1.0) * (0.6 + 0.4 * env)
			
		# Arp / Lead channel
		var a_note = arp_pattern[step_idx]
		var arp_val := 0.0
		if a_note != "REST" and notes.has(a_note):
			var a_freq: float = notes[a_note]
			arp_phase = fmod(arp_phase + (a_freq / rate), 1.0)
			if lead_wave_type == "square":
				arp_val = 0.18 * (1.0 if arp_phase < 0.5 else -1.0) * env
			elif lead_wave_type == "saw":
				arp_val = 0.19 * (2.0 * arp_phase - 1.0) * env
			else:
				arp_val = 0.22 * (4.0 * absf(arp_phase - 0.5) - 1.0) * env
				
		# Percussion channel
		var noise_val := 0.0
		if region == "latin":
			if step_idx % 4 == 0 or step_idx % 4 == 3:
				var shaker_env := maxf(0.0, 1.0 - (float(sample_in_step) / float(step_samples * 0.5)))
				noise_val = 0.08 * randf_range(-1.0, 1.0) * shaker_env
		elif region == "asia":
			if step_idx % 8 == 4:
				var clack_env := maxf(0.0, 1.0 - (float(sample_in_step) / float(step_samples * 0.3)))
				noise_val = 0.14 * randf_range(-1.0, 1.0) * clack_env
		elif region == "africa_mideast":
			if step_idx % 4 == 0 or step_idx % 8 == 6:
				var drum_env := maxf(0.0, 1.0 - (float(sample_in_step) / float(step_samples * 0.8)))
				noise_val = 0.15 * randf_range(-1.0, 1.0) * drum_env
		else:
			if step_idx % 8 == 4:
				var snare_env := maxf(0.0, 1.0 - (float(sample_in_step) / float(step_samples * 1.5)))
				noise_val = 0.16 * randf_range(-1.0, 1.0) * snare_env
			elif step_idx % 2 == 0:
				var hat_env := maxf(0.0, 1.0 - (float(sample_in_step) / float(step_samples * 0.4)))
				noise_val = 0.05 * randf_range(-1.0, 1.0) * hat_env
				
		var mix := clampf(bass_val + arp_val + noise_val, -1.0, 1.0)
		data[s] = int(clampi(int(128 + mix * 115.0), 0, 255))
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = total_samples
	wav.data = data
	return wav

func _create_ambient_foley(region: String) -> AudioStreamWAV:
	var rate := 22050
	var duration := 3.0
	var sample_count := int(duration * rate)
	var data := PackedByteArray()
	data.resize(sample_count)
	
	for i in range(sample_count):
		var t := float(i) / float(rate)
		var val := 0.0
		
		match region:
			"europe":
				var rain := randf_range(-0.15, 0.15)
				var drop := 0.0
				if randf() < 0.0015:
					drop = randf_range(0.2, 0.5)
				val = rain + drop
			"asia":
				var neon := sin(2.0 * PI * 120.0 * t) * 0.08
				var shimmer := sin(2.0 * PI * 2100.0 * t) * (0.04 + 0.03 * sin(2.0 * PI * 1.5 * t))
				val = neon + shimmer
			"latin":
				var tide_env := 0.5 + 0.5 * sin(2.0 * PI * 0.33 * t)
				var surf := randf_range(-0.25, 0.25) * tide_env
				val = surf
			"africa_mideast":
				var wind_mod := 0.5 + 0.5 * sin(2.0 * PI * 0.5 * t)
				var wind := randf_range(-0.22, 0.22) * wind_mod
				val = wind
			_:
				var hum := sin(2.0 * PI * 60.0 * t) * 0.06
				var air := randf_range(-0.08, 0.08)
				val = hum + air
				
		data[i] = int(clampi(int(128 + clampf(val, -1.0, 1.0) * 110.0), 0, 255))
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = sample_count
	wav.data = data
	return wav

func play_sfx(stream: AudioStreamWAV, pitch: float = 1.0) -> void:
	if stream == null:
		return
	sfx_player.stream = stream
	sfx_player.pitch_scale = pitch
	sfx_player.play()

func play_cursor() -> void: play_sfx(wav_cursor)
func play_confirm() -> void: play_sfx(wav_confirm)
func play_cancel() -> void: play_sfx(wav_cancel)
func play_text_blip() -> void:
	if wav_blip != null:
		blip_player.stream = wav_blip
		blip_player.pitch_scale = randf_range(0.95, 1.05)
		blip_player.play()
func play_shoulder() -> void: play_sfx(wav_shoulder)
func play_light() -> void: play_sfx(wav_light)
func play_clue() -> void: play_sfx(wav_clue)
func play_travel() -> void: play_sfx(wav_travel)
func play_warrant() -> void: play_sfx(wav_warrant)
func play_victory() -> void: play_sfx(wav_victory)
func play_game_over() -> void: play_sfx(wav_game_over)
func play_impact() -> void: play_sfx(wav_impact)
func play_cuffs() -> void: play_sfx(wav_cuffs)
func play_static() -> void: play_sfx(wav_static)
func play_radio_lock() -> void: play_sfx(wav_radio_lock)
func play_ping() -> void: play_sfx(wav_ping)
func play_whoosh() -> void: play_sfx(wav_whoosh)
func play_siren() -> void: play_sfx(wav_siren)
func play_gadget() -> void: play_sfx(wav_gadget)


func _create_impact_wav() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var duration := 0.35
	var sample_count := int(duration * wav.mix_rate)
	var data := PackedByteArray()
	data.resize(sample_count)
	var freq := 120.0
	var phase := 0.0
	for i in range(sample_count):
		var t := float(i) / float(sample_count)
		var env := pow(1.0 - t, 2.0)
		var f := freq * (1.0 - t * 0.6)
		phase = fmod(phase + (f / wav.mix_rate), 1.0)
		var tone := (1.0 if phase < 0.5 else -1.0) * 0.7
		var noise := randf_range(-1.0, 1.0) * (0.8 if t < 0.15 else 0.1)
		var mix := (tone + noise) * env
		data[i] = int(clampi(int(128 + mix * 120.0), 0, 255))
	wav.data = data
	return wav

func _create_cuffs_wav() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var duration := 0.22
	var sample_count := int(duration * wav.mix_rate)
	var data := PackedByteArray()
	data.resize(sample_count)
	for i in range(sample_count):
		var t := float(i) / float(sample_count)
		var click1 := 1.0 if (i < 300 or (i > 800 and i < 1200)) else 0.0
		var env := pow(1.0 - t, 3.0)
		var tone := sin(float(i) * 0.35) * click1 * env
		data[i] = int(clampi(int(128 + tone * 120.0), 0, 255))
	wav.data = data
	return wav

func _create_static_wav() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var duration := 0.12
	var sample_count := int(duration * wav.mix_rate)
	var data := PackedByteArray()
	data.resize(sample_count)
	for i in range(sample_count):
		var t := float(i) / float(sample_count)
		var env := sin(t * PI)
		var noise := randf_range(-1.0, 1.0) * env
		data[i] = int(clampi(int(128 + noise * 100.0), 0, 255))
	wav.data = data
	return wav

func _create_radio_lock_wav() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var duration := 0.32
	var sample_count := int(duration * wav.mix_rate)
	var data := PackedByteArray()
	data.resize(sample_count)
	# 3-tone ascending electronic lock chime (880Hz -> 1320Hz -> 1760Hz)
	var chord_freqs = [880.0, 1320.0, 1760.0]
	var phase := 0.0
	for i in range(sample_count):
		var seg := clampi(int((float(i) / float(sample_count)) * 3.0), 0, 2)
		var f: float = chord_freqs[seg]
		phase = fmod(phase + (f / wav.mix_rate), 1.0)
		var t_in_seg := fmod(float(i), float(sample_count) / 3.0) / (float(sample_count) / 3.0)
		var env := 1.0 - t_in_seg * 0.7
		var val := (1.0 if phase < 0.5 else -1.0) * env * 0.6
		data[i] = int(clampi(int(128 + val * 120.0), 0, 255))
	wav.data = data
	return wav

func _create_ping_wav() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var duration := 0.18
	var sample_count := int(duration * wav.mix_rate)
	var data := PackedByteArray()
	data.resize(sample_count)
	var freq := 1480.0
	var phase := 0.0
	for i in range(sample_count):
		var t := float(i) / float(sample_count)
		var env := exp(-t * 12.0)
		phase = fmod(phase + (freq / wav.mix_rate), 1.0)
		var val := sin(phase * TAU) * env
		data[i] = int(clampi(int(128 + val * 120.0), 0, 255))
	wav.data = data
	return wav

func _create_whoosh_wav() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var duration := 0.20
	var sample_count := int(duration * wav.mix_rate)
	var data := PackedByteArray()
	data.resize(sample_count)
	for i in range(sample_count):
		var t := float(i) / float(sample_count)
		var env := sin(t * PI)
		var noise := randf_range(-1.0, 1.0) * env * (1.0 - t * 0.5)
		data[i] = int(clampi(int(128 + noise * 110.0), 0, 255))
	wav.data = data
	return wav

func _create_siren_wav() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var duration := 0.35
	var sample_count := int(duration * wav.mix_rate)
	var data := PackedByteArray()
	data.resize(sample_count)
	var phase := 0.0
	for i in range(sample_count):
		var t := float(i) / float(sample_count)
		var freq := 650.0 if (t < 0.5) else 820.0
		phase = fmod(phase + (freq / wav.mix_rate), 1.0)
		var env := sin(t * PI)
		var val := (1.0 if phase < 0.5 else -1.0) * env * 0.7
		data[i] = int(clampi(int(128 + val * 120.0), 0, 255))
	wav.data = data
	return wav

func _create_gadget_wav() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var duration := 0.28
	var sample_count := int(duration * wav.mix_rate)
	var data := PackedByteArray()
	data.resize(sample_count)
	var phase := 0.0
	for i in range(sample_count):
		var t := float(i) / float(sample_count)
		var freq := 800.0 + sin(t * TAU * 4.0) * 400.0
		phase = fmod(phase + (freq / wav.mix_rate), 1.0)
		var env := exp(-t * 4.0)
		var val := sin(phase * TAU) * env * 0.8
		data[i] = int(clampi(int(128 + val * 120.0), 0, 255))
	wav.data = data
	return wav


