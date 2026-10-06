extends Node
## SoundManager: GBA DirectSound & PSG Audio Synthesizer (Cached for Zero Latency)

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

func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	blip_player = AudioStreamPlayer.new()
	blip_player.volume_db = -12.0
	bgm_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	add_child(blip_player)
	add_child(bgm_player)
	_cache_all_sounds()

func _cache_all_sounds() -> void:
	wav_cursor = _create_tone_wav(440.0, 0.04, "square")
	wav_confirm = _create_tone_wav(660.0, 0.07, "square")
	wav_cancel = _create_tone_wav(260.0, 0.08, "square")
	wav_blip = _create_tone_wav(900.0, 0.02, "triangle")
	wav_shoulder = _create_tone_wav(700.0, 0.04, "triangle")
	wav_light = _create_tone_wav(1000.0, 0.03, "square")
	wav_clue = _create_tone_wav(587.3, 0.15, "square")
	wav_travel = _create_tone_wav(150.0, 0.35, "noise")
	wav_warrant = _create_tone_wav(880.0, 0.25, "square")
	wav_victory = _create_tone_wav(1046.5, 0.4, "square")
	wav_game_over = _create_tone_wav(196.0, 0.4, "triangle")

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
