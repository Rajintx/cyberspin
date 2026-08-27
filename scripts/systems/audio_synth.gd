extends Node

static var instance: Node

var _players: Array[AudioStreamPlayer] = []
const MAX_PLAYERS: int = 16

# Pre-cached synthesized audio streams
var _stream_click: AudioStreamWAV
var _stream_spin_tick: AudioStreamWAV
var _stream_lever: AudioStreamWAV
var _stream_laser: AudioStreamWAV
var _stream_shield: AudioStreamWAV
var _stream_payline: AudioStreamWAV
var _stream_jackpot: AudioStreamWAV
var _stream_boss_hit: AudioStreamWAV
var _stream_emp: AudioStreamWAV
var _stream_virus: AudioStreamWAV

func _ready() -> void:
	instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(MAX_PLAYERS):
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		_players.append(player)

	_precache_all_sounds()

func _precache_all_sounds() -> void:
	_stream_click = _generate_tone(800, 300, 0.04, "square")
	_stream_spin_tick = _generate_tone(600, 250, 0.04, "sine")
	_stream_lever = _generate_tone(150, 650, 0.18, "saw")
	_stream_laser = _generate_tone(1200, 150, 0.16, "saw")
	_stream_shield = _generate_tone(350, 800, 0.2, "sine")
	_stream_payline = _generate_tone(523.25, 1046.5, 0.3, "square")
	_stream_jackpot = _generate_tone(440.0, 880.0, 0.15, "square")
	_stream_boss_hit = _generate_tone(180, 50, 0.22, "noise")
	_stream_emp = _generate_tone(900, 200, 0.25, "saw")
	_stream_virus = _generate_tone(300, 150, 0.18, "saw")

func _get_available_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	return _players[0]

func _generate_tone(freq_start: float, freq_end: float, duration: float, waveform: String = "sine") -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(sample_rate * duration)
	if total_samples <= 0:
		return null

	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2) # 16-bit mono

	var phase: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var cur_freq: float = lerpf(freq_start, freq_end, t)
		phase += (cur_freq * TAU) / float(sample_rate)

		var sample_val: float = 0.0
		if waveform == "sine":
			sample_val = sin(phase)
		elif waveform == "square":
			sample_val = 1.0 if sin(phase) > 0.0 else -1.0
		elif waveform == "saw":
			sample_val = (fmod(phase, TAU) / PI) - 1.0
		elif waveform == "noise":
			sample_val = randf_range(-1.0, 1.0)

		# Decay envelope
		var envelope: float = 1.0 - t
		sample_val *= envelope

		var int_val: int = int(clampi(int(sample_val * 32767.0), -32768, 32767))
		buffer.encode_s16(i * 2, int_val)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = buffer
	return stream

func play_stream(stream: AudioStreamWAV, volume_db: float = -6.0, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return
	var player := _get_available_player()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()

func play_tone(freq_start: float, freq_end: float, duration: float, volume_db: float = -6.0, waveform: String = "sine") -> void:
	var st := _generate_tone(freq_start, freq_end, duration, waveform)
	play_stream(st, volume_db)

# Fast cached play methods
func play_click() -> void:
	play_stream(_stream_click, -10.0)

func play_spin_tick() -> void:
	play_stream(_stream_spin_tick, -12.0, randf_range(0.9, 1.1))

func play_lever_pull() -> void:
	play_stream(_stream_lever, -6.0)

func play_laser() -> void:
	play_stream(_stream_laser, -4.0)

func play_shield() -> void:
	play_stream(_stream_shield, -6.0)

func play_payline() -> void:
	play_stream(_stream_payline, -4.0)

func play_jackpot() -> void:
	play_stream(_stream_jackpot, -3.0)
	var t := create_tween()
	t.tween_callback(func(): play_stream(_stream_jackpot, -3.0, 1.25)).set_delay(0.12)
	t.tween_callback(func(): play_stream(_stream_jackpot, -2.0, 1.5)).set_delay(0.24)

func play_boss_hit() -> void:
	play_stream(_stream_boss_hit, -3.0)

func play_emp() -> void:
	play_stream(_stream_emp, -5.0)

func play_virus() -> void:
	play_stream(_stream_virus, -6.0)
