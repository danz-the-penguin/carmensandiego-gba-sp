extends Node
## SoundManager: Dual-Channel SFX Synthesizer + Catchy 8-bit Detective Groove BGM

var sfx_player: AudioStreamPlayer
var blip_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer
var bgm_enabled: bool = true

# Cached Audio Streams
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
var wav_bgm: AudioStreamWAV

func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	blip_player = AudioStreamPlayer.new()
	blip_player.volume_db = -12.0
	bgm_player = AudioStreamPlayer.new()
	bgm_player.volume_db = -16.0
	add_child(sfx_player)
	add_child(blip_player)
	add_child(bgm_player)
	_cache_all_sounds()

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
	
	wav_bgm = _load_override("bgm", _create_detective_bgm())
	bgm_player.stream = wav_bgm
	start_bgm()

func start_bgm() -> void:
	if bgm_enabled and not bgm_player.playing:
		bgm_player.play()

func stop_bgm() -> void:
	bgm_player.stop()

func toggle_bgm() -> void:
	bgm_enabled = !bgm_enabled
	if bgm_enabled:
		bgm_player.play()
	else:
		bgm_player.stop()

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

func _create_detective_bgm() -> AudioStreamWAV:
	var rate := 22050
	var bpm := 125.0
	var step_duration := (60.0 / bpm) / 4.0 # 16th note
	var step_samples := int(step_duration * rate)
	var total_steps := 32 # 2 bars
	var total_samples := step_samples * total_steps

	var data := PackedByteArray()
	data.resize(total_samples)

	var notes := {
		"C2": 65.4, "D2": 73.4, "F2": 87.3, "G2": 98.0, "A2": 110.0,
		"C3": 130.8, "D3": 146.8, "E3": 164.8, "F3": 174.6, "G3": 196.0, "A3": 220.0,
		"C4": 261.6, "D4": 293.7, "E4": 329.6, "F4": 349.2, "A4": 440.0
	}

	var bass_pattern := [
		"D2", "D2", "D2", "D2", "F2", "F2", "F2", "F2",
		"G2", "G2", "G2", "G2", "A2", "A2", "A2", "A2",
		"D2", "D2", "D2", "D2", "C2", "C2", "C2", "C2",
		"G2", "G2", "G2", "G2", "A2", "A2", "A2", "A2"
	]

	var arp_pattern := [
		"D3", "A3", "D4", "A3", "F3", "C4", "F3", "C4",
		"G3", "D4", "G3", "D4", "A3", "E4", "A3", "E4",
		"D3", "A3", "D4", "A3", "C3", "G3", "C4", "G3",
		"G3", "D4", "G3", "D4", "A3", "E4", "A3", "D4"
	]

	var bass_phase := 0.0
	var arp_phase := 0.0

	for s in range(total_samples):
		var step_idx := (s / step_samples) % total_steps
		var sample_in_step := s % step_samples
		var env := maxf(0.0, 1.0 - (float(sample_in_step) / float(step_samples)))

		var bass_freq: float = notes[bass_pattern[step_idx]]
		bass_phase = fmod(bass_phase + (bass_freq / rate), 1.0)
		var bass_val := 0.28 * (1.0 if bass_phase < 0.5 else -1.0) * (0.6 + 0.4 * env)

		var arp_freq: float = notes[arp_pattern[step_idx]]
		arp_phase = fmod(arp_phase + (arp_freq / rate), 1.0)
		var arp_val := 0.20 * (4.0 * absf(arp_phase - 0.5) - 1.0) * env

		var noise_val := 0.0
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
