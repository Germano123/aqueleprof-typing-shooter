extends Node

# ScoreManager - Gerenciamento global de pontuação, combos, estatísticas e recordes salvos

signal score_changed(new_score: int, added_points: int)
signal combo_changed(current_combo: int, multiplier: float)
signal stats_updated(wpm: float, accuracy: float)
signal high_score_updated(new_high_score: int)

const SAVE_PATH := "user://high_score.dat"

var score: int = 0
var high_score: int = 0
var combo: int = 0
var max_combo: int = 0
var words_destroyed: int = 0

var total_keystrokes: int = 0
var correct_keystrokes: int = 0
var game_start_time: float = 0.0
var is_game_active: bool = false

func _ready() -> void:
	load_high_score()

func start_session() -> void:
	score = 0
	combo = 0
	max_combo = 0
	words_destroyed = 0
	total_keystrokes = 0
	correct_keystrokes = 0
	game_start_time = Time.get_ticks_msec() / 1000.0
	is_game_active = true
	score_changed.emit(score, 0)
	combo_changed.emit(combo, get_multiplier())

func end_session() -> void:
	is_game_active = false
	if score > high_score:
		high_score = score
		save_high_score()
		high_score_updated.emit(high_score)

func get_multiplier() -> float:
	if combo < 5:
		return 1.0
	elif combo < 15:
		return 1.5
	elif combo < 30:
		return 2.0
	elif combo < 50:
		return 2.5
	else:
		return 3.0

func register_correct_keystroke() -> void:
	total_keystrokes += 1
	correct_keystrokes += 1
	combo += 1
	if combo > max_combo:
		max_combo = combo
	
	combo_changed.emit(combo, get_multiplier())
	_emit_stats()

func register_wrong_keystroke() -> void:
	total_keystrokes += 1
	if combo > 0:
		combo = 0
		combo_changed.emit(combo, 1.0)
	_emit_stats()

func register_word_destroyed(word_len: int, speed_factor: float = 1.0) -> int:
	words_destroyed += 1
	var mult := get_multiplier()
	# Pontuação base proporcional ao comprimento da palavra
	var base_pts := word_len * 100
	var final_pts := int(base_pts * mult * speed_factor)
	score += final_pts
	
	if score > high_score:
		high_score = score
		high_score_updated.emit(high_score)
		
	score_changed.emit(score, final_pts)
	_emit_stats()
	return final_pts

func _emit_stats() -> void:
	stats_updated.emit(get_wpm(), get_accuracy())

func get_accuracy() -> float:
	if total_keystrokes == 0:
		return 100.0
	return clamp((float(correct_keystrokes) / float(total_keystrokes)) * 100.0, 0.0, 100.0)

func get_wpm() -> float:
	if not is_game_active:
		return 0.0
	var elapsed_min := maxf(((Time.get_ticks_msec() / 1000.0) - game_start_time) / 60.0, 0.01)
	# Padrão WPM: 5 caracteres = 1 palavra
	var words_typed := float(correct_keystrokes) / 5.0
	return words_typed / elapsed_min

func save_high_score() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_32(high_score)
		file.close()

func load_high_score() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			high_score = file.get_32()
			file.close()
			high_score_updated.emit(high_score)
