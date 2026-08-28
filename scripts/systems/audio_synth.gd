extends Node

static var instance: Node

var _players: Array[AudioStreamPlayer] = []
const MAX_PLAYERS: int = 16

# Volume settings (0.0 to 1.0 linear)
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var ambient_volume: float = 0.65
var is_ambient_enabled: bool = true

# Ambient Audio Stream Players
var _ambient_player: AudioStreamPlayer
var _heartbeat_player: AudioStreamPlayer
var _heartbeat_timer: Timer

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
var _stream_ambient_drone: AudioStreamWAV
var _stream_heartbeat: AudioStreamWAV

func _ready() -> void:
	instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS

	for i in range(MAX_PLAYERS):
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		_players.append(player)

	# Dedicated Ambient & Heartbeat Players
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = &"Master"
	add_child(_ambient_player)

	_heartbeat_player = AudioStreamPlayer.new()
	_heartbeat_player.bus = &"Master"
	add_child(_heartbeat_player)

	_heartbeat_timer = Timer.new()
	_heartbeat_timer.wait_time = 1.6
	_heartbeat_timer.timeout.connect(_on_heartbeat_timeout)
	add_child(_heartbeat_timer)

	_precache_all_sounds()
	_start_ambient_drone()

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
	
	_stream_ambient_drone = _generate_ambient_drone(4.0)
	_stream_heartbeat = _generate_heartbeat()

func _start_ambient_drone() -> void:
	if _stream_ambient_drone and is_ambient_enabled:
		_ambient_player.stream = _stream_ambient_drone
		_ambient_player.volume_db = _calc_db(ambient_volume, -14.0)
		_ambient_player.play()

func _on_heartbeat_timeout() -> void:
	if not is_ambient_enabled or master_volume <= 0.01:
		return
	if _stream_heartbeat:
		_heartbeat_player.stream = _stream_heartbeat
		_heartbeat_player.volume_db = _calc_db(ambient_volume * 1.2, -6.0)
		_heartbeat_player.play()

func set_combat_intensity(is_boss: bool, is_critical: bool) -> void:
	if is_critical:
		_ambient_player.pitch_scale = 1.15
		_heartbeat_timer.wait_time = 0.9
		if not _heartbeat_timer.is_stopped():
			_heartbeat_timer.stop()
		_heartbeat_timer.start()
	elif is_boss:
		_ambient_player.pitch_scale = 1.05
		_heartbeat_timer.wait_time = 1.5
		if not _heartbeat_timer.is_stopped():
			_heartbeat_timer.stop()
		_heartbeat_timer.start()
	else:
		_ambient_player.pitch_scale = 1.0
		_heartbeat_timer.stop()

# --- Volume Controls ---

func set_master_volume(linear: float) -> void:
	master_volume = clampf(linear, 0.0, 1.0)
	_update_ambient_volume()

func set_sfx_volume(linear: float) -> void:
	sfx_volume = clampf(linear, 0.0, 1.0)

func set_ambient_volume(linear: float) -> void:
	ambient_volume = clampf(linear, 0.0, 1.0)
	_update_ambient_volume()

func set_ambient_enabled(enabled: bool) -> void:
	is_ambient_enabled = enabled
	if not enabled:
		_ambient_player.stop()
		_heartbeat_timer.stop()
	else:
		if not _ambient_player.playing:
			_start_ambient_drone()

func _update_ambient_volume() -> void:
	if _ambient_player:
		if master_volume <= 0.001 or ambient_volume <= 0.001 or not is_ambient_enabled:
			_ambient_player.volume_db = -80.0
		else:
			_ambient_player.volume_db = _calc_db(ambient_volume, -14.0)

func _calc_db(channel_linear: float, base_db: float) -> float:
	var final_linear := master_volume * channel_linear
	if final_linear <= 0.001:
		return -80.0
	return base_db + linear_to_db(final_linear)

func _get_available_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	return _players[0]

# --- Sound Synthesis ---

func _generate_tone(freq_start: float, freq_end: float, duration: float, waveform: String = "sine") -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(sample_rate * duration)
	if total_samples <= 0:
		return null

	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)

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

func _generate_ambient_drone(duration: float = 4.0) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(sample_rate * duration)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)

	var root_freq: float = 55.0  # A1 sub-bass
	var fifth_freq: float = 82.4 # E2 fifth
	var octave_freq: float = 110.0 # A2 octave

	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		# Smooth seamless loop modulation
		var lfo: float = 0.7 + 0.3 * sin(t * TAU * 2.0)
		var s1: float = sin((float(i) * root_freq * TAU) / float(sample_rate))
		var s2: float = 0.4 * sin((float(i) * fifth_freq * TAU) / float(sample_rate))
		var s3: float = 0.2 * sin((float(i) * octave_freq * TAU) / float(sample_rate))
		
		var sample_val: float = (s1 + s2 + s3) * lfo * 0.4
		var int_val: int = int(clampi(int(sample_val * 32767.0), -32768, 32767))
		buffer.encode_s16(i * 2, int_val)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = buffer
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total_samples
	return stream

func _generate_heartbeat() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.22
	var total_samples: int = int(sample_rate * duration)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)

	var phase: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var freq: float = lerpf(85.0, 38.0, t)
		phase += (freq * TAU) / float(sample_rate)
		var sample_val: float = sin(phase) * (1.0 - pow(t, 0.7)) * 0.8
		var int_val: int = int(clampi(int(sample_val * 32767.0), -32768, 32767))
		buffer.encode_s16(i * 2, int_val)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = buffer
	return stream

func play_stream(stream: AudioStreamWAV, base_volume_db: float = -6.0, pitch_scale: float = 1.0) -> void:
	if stream == null or master_volume <= 0.001 or sfx_volume <= 0.001:
		return
	var player := _get_available_player()
	player.stream = stream
	player.volume_db = _calc_db(sfx_volume, base_volume_db)
	player.pitch_scale = pitch_scale
	player.play()

func play_tone(freq_start: float, freq_end: float, duration: float, volume_db: float = -6.0, waveform: String = "sine") -> void:
	var st := _generate_tone(freq_start, freq_end, duration, waveform)
	play_stream(st, volume_db)

# --- Play SFX Triggers ---

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
