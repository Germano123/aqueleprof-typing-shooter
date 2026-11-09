extends Node

# SoundManager - Gerador procedural de efeitos sonoros arcade (100% autônomo sem arquivos externos)

var sfx_laser: AudioStreamWAV
var sfx_hit: AudioStreamWAV
var sfx_explosion: AudioStreamWAV
var sfx_type: AudioStreamWAV
var sfx_error: AudioStreamWAV
var sfx_combo: AudioStreamWAV
var sfx_player_hit: AudioStreamWAV
var sfx_game_over: AudioStreamWAV
var sfx_comms: AudioStreamWAV

var audio_players: Array[AudioStreamPlayer] = []
var num_players: int = 12
var current_player_idx: int = 0

var sound_enabled: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_players()
	_generate_all_sounds()

func _setup_audio_players() -> void:
	for i in range(num_players):
		var asp := AudioStreamPlayer.new()
		asp.bus = &"Master"
		add_child(asp)
		audio_players.append(asp)

func _play_stream(stream: AudioStreamWAV, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if not sound_enabled or stream == null:
		return
	var asp: AudioStreamPlayer = audio_players[current_player_idx]
	current_player_idx = (current_player_idx + 1) % num_players
	asp.stream = stream
	asp.volume_db = volume_db
	asp.pitch_scale = pitch_scale
	asp.play()

func play_laser(pitch: float = 1.0) -> void:
	_play_stream(sfx_laser, -6.0, pitch)

func play_hit() -> void:
	_play_stream(sfx_hit, -8.0, randf_range(0.95, 1.1))

func play_explosion() -> void:
	_play_stream(sfx_explosion, -3.0, randf_range(0.9, 1.1))

func play_type() -> void:
	_play_stream(sfx_type, -10.0, randf_range(0.95, 1.05))

func play_error() -> void:
	_play_stream(sfx_error, -4.0, 1.0)

func play_combo() -> void:
	_play_stream(sfx_combo, -4.0, 1.0)

func play_player_hit() -> void:
	_play_stream(sfx_player_hit, -2.0, 1.0)

func play_game_over() -> void:
	_play_stream(sfx_game_over, -2.0, 1.0)

func play_comms() -> void:
	_play_stream(sfx_comms, -8.0, randf_range(0.98, 1.02))

# ----------------- GERADORES DE ÁUDIO PROCEDURAL (PCM 16-BIT) -----------------

func _generate_all_sounds() -> void:
	sfx_laser = _gen_laser()
	sfx_hit = _gen_hit()
	sfx_explosion = _gen_explosion()
	sfx_type = _gen_type()
	sfx_error = _gen_error()
	sfx_combo = _gen_combo()
	sfx_player_hit = _gen_player_hit()
	sfx_game_over = _gen_game_over()
	sfx_comms = _gen_comms()

func _create_wav(byte_array: PackedByteArray, sample_rate: int = 22050) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_array
	return wav

func _gen_laser() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.09
	var total_samples: int = int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)
	
	var phase: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var freq: float = lerpf(900.0, 180.0, t * t)
		phase += (freq * TAU) / float(sample_rate)
		var sample: float = sin(phase) * (1.0 - t)
		var s16: int = int(clampf(sample * 30000.0, -32767.0, 32767.0))
		bytes.encode_s16(i * 2, s16)
		
	return _create_wav(bytes, sample_rate)

func _gen_hit() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.05
	var total_samples: int = int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)
	
	var phase: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var freq: float = lerpf(1200.0, 400.0, t)
		phase += (freq * TAU) / float(sample_rate)
		var sample: float = (sin(phase) + (randf() * 2.0 - 1.0) * 0.3) * (1.0 - t)
		var s16: int = int(clampf(sample * 28000.0, -32767.0, 32767.0))
		bytes.encode_s16(i * 2, s16)
		
	return _create_wav(bytes, sample_rate)

func _gen_explosion() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.35
	var total_samples: int = int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)
	
	var low_pass: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var noise: float = randf() * 2.0 - 1.0
		low_pass += (noise - low_pass) * 0.2
		var env: float = exp(-4.0 * t)
		var sample: float = (low_pass * 0.7 + sin(t * 120.0) * 0.3) * env
		var s16: int = int(clampf(sample * 32000.0, -32767.0, 32767.0))
		bytes.encode_s16(i * 2, s16)
		
	return _create_wav(bytes, sample_rate)

func _gen_type() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.025
	var total_samples: int = int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)
	
	var phase: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		phase += (1400.0 * TAU) / float(sample_rate)
		var sample: float = sin(phase) * (1.0 - t)
		var s16: int = int(clampf(sample * 18000.0, -32767.0, 32767.0))
		bytes.encode_s16(i * 2, s16)
		
	return _create_wav(bytes, sample_rate)

func _gen_error() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.12
	var total_samples: int = int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)
	
	var phase: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		phase += (150.0 * TAU) / float(sample_rate)
		var square: float = 1.0 if sin(phase) >= 0.0 else -1.0
		var sample: float = square * (1.0 - t * 0.5)
		var s16: int = int(clampf(sample * 24000.0, -32767.0, 32767.0))
		bytes.encode_s16(i * 2, s16)
		
	return _create_wav(bytes, sample_rate)

func _gen_combo() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.24
	var total_samples: int = int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)
	
	var freqs: Array[float] = [523.25, 659.25, 783.99, 1046.50]
	var phase: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var note_idx: int = int(t * 4.0)
		note_idx = mini(note_idx, 3)
		var freq: float = freqs[note_idx]
		phase += (freq * TAU) / float(sample_rate)
		var note_t: float = fmod(t * 4.0, 1.0)
		var sample: float = sin(phase) * (1.0 - note_t * 0.8)
		var s16: int = int(clampf(sample * 26000.0, -32767.0, 32767.0))
		bytes.encode_s16(i * 2, s16)
		
	return _create_wav(bytes, sample_rate)

func _gen_player_hit() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.28
	var total_samples: int = int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var noise: float = randf() * 2.0 - 1.0
		var s_sin: float = sin(t * 80.0)
		var sample: float = (noise * 0.6 + s_sin * 0.4) * (1.0 - t)
		var s16: int = int(clampf(sample * 32000.0, -32767.0, 32767.0))
		bytes.encode_s16(i * 2, s16)
		
	return _create_wav(bytes, sample_rate)

func _gen_game_over() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.6
	var total_samples: int = int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)
	
	var freqs: Array[float] = [392.0, 349.23, 311.13, 261.63]
	var phase: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var note_idx: int = int(t * 4.0)
		note_idx = mini(note_idx, 3)
		var freq: float = freqs[note_idx]
		phase += (freq * TAU) / float(sample_rate)
		var sample: float = sin(phase) * exp(-2.0 * t)
		var s16: int = int(clampf(sample * 28000.0, -32767.0, 32767.0))
		bytes.encode_s16(i * 2, s16)
		
	return _create_wav(bytes, sample_rate)

func _gen_comms() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.12
	var total_samples: int = int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)
	
	var phase: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var freq: float = 880.0 if t < 0.5 else 1320.0
		phase += (freq * TAU) / float(sample_rate)
		var sample: float = sin(phase) * (1.0 - fmod(t * 2.0, 1.0) * 0.5)
		var s16: int = int(clampf(sample * 24000.0, -32767.0, 32767.0))
		bytes.encode_s16(i * 2, s16)
		
	return _create_wav(bytes, sample_rate)
