class_name TypingMetrics
extends RefCounted

# TypingMetrics - Motor de telemetria, análise de ritmo, precisão, mãos, rank e meta de cadência de 150ms

signal metrics_updated(data: Dictionary)
signal style_rank_changed(rank_name: String, rank_color: Color, style_percent: float)
signal hand_alternation_bonus(streak: int)
signal difficult_key_bonus(from_key: String, to_key: String, bonus_pts: int)
signal flow_intensity_changed(flow_state: String, spawn_mult: float, description: String)

# Mapeamento de Mãos (Padrão Touch Typing QWERTY/ABNT)
const LEFT_HAND_KEYS: Array[String] = [
	"Q", "W", "E", "R", "T",
	"A", "S", "D", "F", "G",
	"Z", "X", "C", "V", "B",
	"1", "2", "3", "4", "5"
]

const RIGHT_HAND_KEYS: Array[String] = [
	"Y", "U", "I", "O", "P",
	"H", "J", "K", "L", "Ç",
	"N", "M",
	"6", "7", "8", "9", "0",
	",", ".", ";"
]

const HOME_ROW_KEYS: Array[String] = [
	"A", "S", "D", "F", "J", "K", "L", "Ç"
]

# Metas de Cadência (ms)
const TARGET_CADENCE_MS_EARLY: float = 220.0
const TARGET_CADENCE_MS_WAVE4: float = 150.0 # Meta principal a partir da 4ª onda (150ms / ~400 CPM)

# Posições aproximadas no teclado para cálculo de distância entre teclas
const KEY_COORDINATES: Dictionary = {
	"1": Vector2(0, 0), "2": Vector2(1, 0), "3": Vector2(2, 0), "4": Vector2(3, 0), "5": Vector2(4, 0),
	"6": Vector2(5, 0), "7": Vector2(6, 0), "8": Vector2(7, 0), "9": Vector2(8, 0), "0": Vector2(9, 0),
	"Q": Vector2(0.5, 1), "W": Vector2(1.5, 1), "E": Vector2(2.5, 1), "R": Vector2(3.5, 1), "T": Vector2(4.5, 1),
	"Y": Vector2(5.5, 1), "U": Vector2(6.5, 1), "I": Vector2(7.5, 1), "O": Vector2(8.5, 1), "P": Vector2(9.5, 1),
	"A": Vector2(0.7, 2), "S": Vector2(1.7, 2), "D": Vector2(2.7, 2), "F": Vector2(3.7, 2), "G": Vector2(4.7, 2),
	"H": Vector2(5.7, 2), "J": Vector2(6.7, 2), "K": Vector2(7.7, 2), "L": Vector2(8.7, 2), "Ç": Vector2(9.7, 2),
	"Z": Vector2(1.0, 3), "X": Vector2(2.0, 3), "C": Vector2(3.0, 3), "V": Vector2(4.0, 3), "B": Vector2(5.0, 3),
	"N": Vector2(6.0, 3), "M": Vector2(7.0, 3), ",": Vector2(8.0, 3), ".": Vector2(9.0, 3), ";": Vector2(10.0, 3)
}

# Estatísticas Gerais da Sessão
var total_keystrokes: int = 0
var correct_keystrokes: int = 0
var error_count: int = 0
var consecutive_errors: int = 0
var current_perfect_streak: int = 0
var max_perfect_streak: int = 0

# Estatísticas de Mãos
var left_hand_count: int = 0
var right_hand_count: int = 0
var last_hand: String = ""
var last_key: String = ""
var hand_alternation_streak: int = 0

# Estatísticas de Tempo e Ritmo
var session_start_time: float = 0.0
var last_keystroke_time: float = 0.0
var recent_intervals_ms: Array[float] = []
const MAX_INTERVAL_HISTORY: int = 12

# Sistema de Rank de Estilo / Ritmo (0.0 a 100.0)
var style_points: float = 50.0
var current_rank: String = "B"

# Sistema de Dificuldade Adaptativa (DDA - Flow State)
var current_flow_state: String = "EQUILIBRADO"
var current_flow_mult: float = 1.0

# Estatísticas Exclusivas da Onda Atual (KPIs)
var current_wave_num: int = 1
var wave_start_time: float = 0.0
var wave_total_keys: int = 0
var wave_correct_keys: int = 0
var wave_errors: int = 0
var wave_streak: int = 0
var wave_max_streak: int = 0
var wave_intervals_ms: Array[float] = []

# Ranks e Cores
const RANK_THRESHOLDS: Array[Dictionary] = [
	{"name": "SS", "min": 90.0, "color": Color(1.0, 0.84, 0.0)},
	{"name": "S",  "min": 75.0, "color": Color(0.95, 0.4, 1.0)},
	{"name": "A",  "min": 60.0, "color": Color(0.2, 0.9, 0.4)},
	{"name": "B",  "min": 45.0, "color": Color(0.2, 0.8, 1.0)},
	{"name": "C",  "min": 30.0, "color": Color(0.4, 0.6, 1.0)},
	{"name": "D",  "min": 15.0, "color": Color(1.0, 0.75, 0.2)},
	{"name": "E",  "min": 5.0,  "color": Color(1.0, 0.4, 0.2)},
	{"name": "F",  "min": 0.0,  "color": Color(0.9, 0.2, 0.2)}
]

func start_session() -> void:
	total_keystrokes = 0
	correct_keystrokes = 0
	error_count = 0
	consecutive_errors = 0
	current_perfect_streak = 0
	max_perfect_streak = 0
	
	left_hand_count = 0
	right_hand_count = 0
	last_hand = ""
	last_key = ""
	hand_alternation_streak = 0
	
	session_start_time = Time.get_ticks_msec() / 1000.0
	last_keystroke_time = session_start_time
	recent_intervals_ms.clear()
	
	style_points = 50.0
	current_flow_state = "EQUILIBRADO"
	current_flow_mult = 1.0
	start_wave(1)
	_update_rank()

func start_wave(wave_num: int) -> void:
	current_wave_num = wave_num
	wave_start_time = Time.get_ticks_msec() / 1000.0
	wave_total_keys = 0
	wave_correct_keys = 0
	wave_errors = 0
	wave_streak = 0
	wave_max_streak = 0
	wave_intervals_ms.clear()

func reset_flow_rhythm() -> void:
	current_perfect_streak = 0
	consecutive_errors = 0
	style_points = 50.0
	current_flow_state = "EQUILIBRADO"
	current_flow_mult = 1.0
	recent_intervals_ms.clear()
	_update_rank()
	_update_flow_state()

func process_decay(delta: float) -> void:
	var time_since_last: float = (Time.get_ticks_msec() / 1000.0) - last_keystroke_time
	if time_since_last > 0.8:
		var decay_rate: float = 6.0 + (time_since_last * 4.0)
		style_points = maxf(0.0, style_points - decay_rate * delta)
		_update_rank()
		_update_flow_state()

func get_target_cadence_ms() -> float:
	if current_wave_num >= 4:
		return TARGET_CADENCE_MS_WAVE4 # 150ms
	return TARGET_CADENCE_MS_EARLY

func get_hand_for_key(key_char: String) -> String:
	var k: String = key_char.to_upper()
	if LEFT_HAND_KEYS.has(k):
		return "E"
	elif RIGHT_HAND_KEYS.has(k):
		return "D"
	return ""

func register_keystroke(key_char: String, is_correct: bool) -> Dictionary:
	var now: float = Time.get_ticks_msec() / 1000.0
	var interval_ms: float = (now - last_keystroke_time) * 1000.0
	last_keystroke_time = now
	
	total_keystrokes += 1
	wave_total_keys += 1
	var hand: String = get_hand_for_key(key_char)
	var is_alternation: bool = false
	var is_difficult_stretch: bool = false
	var stretch_bonus: int = 0
	
	if is_correct:
		correct_keystrokes += 1
		wave_correct_keys += 1
		consecutive_errors = 0
		current_perfect_streak += 1
		wave_streak += 1
		if current_perfect_streak > max_perfect_streak:
			max_perfect_streak = current_perfect_streak
		if wave_streak > wave_max_streak:
			wave_max_streak = wave_streak
			
		if hand == "E":
			left_hand_count += 1
		elif hand == "D":
			right_hand_count += 1
			
		if total_keystrokes > 1 and interval_ms < 2000.0:
			recent_intervals_ms.append(interval_ms)
			wave_intervals_ms.append(interval_ms)
			if recent_intervals_ms.size() > MAX_INTERVAL_HISTORY:
				recent_intervals_ms.pop_front()
				
		if last_hand != "" and hand != "" and hand != last_hand:
			hand_alternation_streak += 1
			is_alternation = true
			if hand_alternation_streak >= 2:
				hand_alternation_bonus.emit(hand_alternation_streak)
		else:
			hand_alternation_streak = 0
			
		if last_key != "" and KEY_COORDINATES.has(last_key) and KEY_COORDINATES.has(key_char):
			var dist: float = KEY_COORDINATES[last_key].distance_to(KEY_COORDINATES[key_char])
			if dist >= 4.5:
				is_difficult_stretch = true
				stretch_bonus = int(dist * 50)
				difficult_key_bonus.emit(last_key, key_char, stretch_bonus)
				
		var rhythm_stability: float = get_rhythm_consistency_percent()
		var gain: float = 3.5 + (rhythm_stability * 0.03)
		if is_alternation:
			gain += 1.5
		if is_difficult_stretch:
			gain += 3.0
		style_points = minf(100.0, style_points + gain)
		
		last_hand = hand
		last_key = key_char
	else:
		error_count += 1
		wave_errors += 1
		consecutive_errors += 1
		current_perfect_streak = 0
		wave_streak = 0
		hand_alternation_streak = 0
		
		var penalty: float = 12.0 + (consecutive_errors * 4.0)
		style_points = maxf(0.0, style_points - penalty)
		
	_update_rank()
	_update_flow_state()
	
	var result: Dictionary = {
		"is_correct": is_correct,
		"key": key_char,
		"hand": hand,
		"interval_ms": interval_ms,
		"target_interval_ms": get_target_cadence_ms(),
		"is_alternation": is_alternation,
		"alternation_streak": hand_alternation_streak,
		"is_difficult_stretch": is_difficult_stretch,
		"stretch_bonus": stretch_bonus,
		"cpm": get_cpm(),
		"wpm": get_wpm(),
		"accuracy": get_accuracy_percent(),
		"rhythm_consistency": get_rhythm_consistency_percent(),
		"left_hand_percent": get_left_hand_percent(),
		"right_hand_percent": get_right_hand_percent(),
		"style_points": style_points,
		"rank": current_rank,
		"flow_state": current_flow_state,
		"flow_multiplier": current_flow_mult,
		"flow_description": get_flow_description()
	}
	
	metrics_updated.emit(result)
	return result

func get_wave_kpis() -> Dictionary:
	var elapsed_min: float = maxf(((Time.get_ticks_msec() / 1000.0) - wave_start_time) / 60.0, 0.005)
	var wave_cpm: float = float(wave_correct_keys) / elapsed_min
	var wave_wpm: float = wave_cpm / 5.0
	var wave_acc: float = 100.0 if wave_total_keys == 0 else clampf((float(wave_correct_keys) / float(wave_total_keys)) * 100.0, 0.0, 100.0)
	
	var avg_interval: float = 150.0
	if wave_intervals_ms.size() > 0:
		var sum_intervals: float = 0.0
		for iv in wave_intervals_ms:
			sum_intervals += iv
		avg_interval = sum_intervals / float(wave_intervals_ms.size())
		
	var target_cadence: float = get_target_cadence_ms()
	var rank_data: Dictionary = RANK_THRESHOLDS[RANK_THRESHOLDS.size() - 1]
	for entry in RANK_THRESHOLDS:
		if style_points >= entry["min"]:
			rank_data = entry
			break
			
	return {
		"wave_num": current_wave_num,
		"accuracy": wave_acc,
		"total_keys": wave_total_keys,
		"correct_keys": wave_correct_keys,
		"errors": wave_errors,
		"max_streak": wave_max_streak,
		"avg_interval_ms": avg_interval,
		"target_interval_ms": target_cadence,
		"cpm": wave_cpm,
		"wpm": wave_wpm,
		"rank": rank_data["name"],
		"rank_color": rank_data["color"],
		"flow_state": current_flow_state,
		"flow_multiplier": current_flow_mult
	}

func get_flow_spawn_multiplier() -> float:
	if consecutive_errors >= 1:
		return 1.30
	elif current_perfect_streak >= 35 and (current_rank == "S" or current_rank == "SS"):
		return 0.60
	elif current_perfect_streak >= 20:
		return 0.75
	elif current_perfect_streak >= 10:
		return 0.85
	return 1.00

func get_flow_state_name() -> String:
	if consecutive_errors >= 1:
		return "RECUPERAÇÃO"
	elif current_perfect_streak >= 35 and (current_rank == "S" or current_rank == "SS"):
		return "FRENESI"
	elif current_perfect_streak >= 20:
		return "ACELERADO"
	elif current_perfect_streak >= 10:
		return "RITMO ELEVADO"
	return "EQUILIBRADO"

func get_flow_description() -> String:
	match get_flow_state_name():
		"RECUPERAÇÃO": return "🛡️ RECUPERAÇÃO (Spawn 1x | Cadência -30%)"
		"FRENESI": return "🔥 FRENESI (Spawn 3x Simultâneo | Cadência +40%)"
		"ACELERADO": return "⚡ ACELERADO (Spawn 2x Simultâneo | Cadência +25%)"
		"RITMO ELEVADO": return "▲ RITMO ELEVADO (Spawn até 2x | Cadência +15%)"
		_: return "✦ EQUILIBRADO (Spawn 1x | Ritmo Base)"

func get_flow_spawn_batch_count() -> int:
	if consecutive_errors >= 1:
		return 1
	elif current_perfect_streak >= 35 and (current_rank == "S" or current_rank == "SS"):
		return 3
	elif current_perfect_streak >= 20:
		return 2
	elif current_perfect_streak >= 10:
		return 2 if (wave_streak % 2 == 0) else 1
	return 1

func get_flow_max_active_enemies(base_cap: int = 8) -> int:
	if consecutive_errors >= 1:
		return maxi(3, base_cap - 2)
	elif current_perfect_streak >= 35 and (current_rank == "S" or current_rank == "SS"):
		return base_cap + 4
	elif current_perfect_streak >= 20:
		return base_cap + 2
	elif current_perfect_streak >= 10:
		return base_cap + 1
	return base_cap

func _update_flow_state() -> void:
	var new_state: String = get_flow_state_name()
	var new_mult: float = get_flow_spawn_multiplier()
	if new_state != current_flow_state or absf(new_mult - current_flow_mult) > 0.01:
		current_flow_state = new_state
		current_flow_mult = new_mult
		flow_intensity_changed.emit(current_flow_state, current_flow_mult, get_flow_description())

func get_accuracy_percent() -> float:
	if total_keystrokes == 0:
		return 100.0
	return clampf((float(correct_keystrokes) / float(total_keystrokes)) * 100.0, 0.0, 100.0)

func get_cpm() -> float:
	var elapsed_min: float = maxf(((Time.get_ticks_msec() / 1000.0) - session_start_time) / 60.0, 0.005)
	return float(correct_keystrokes) / elapsed_min

func get_wpm() -> float:
	return get_cpm() / 5.0

func get_rhythm_consistency_percent() -> float:
	if recent_intervals_ms.size() < 3:
		return 85.0
		
	var sum: float = 0.0
	for val in recent_intervals_ms:
		sum += val
	var mean: float = sum / float(recent_intervals_ms.size())
	
	var variance_sum: float = 0.0
	for val in recent_intervals_ms:
		var diff: float = val - mean
		variance_sum += diff * diff
	var std_dev: float = sqrt(variance_sum / float(recent_intervals_ms.size()))
	
	# Estabilidade intrínseca de intervalos
	var cv: float = (std_dev / maxf(mean, 40.0)) * 100.0
	var stability: float = clampf(100.0 - cv * 1.1, 0.0, 100.0)
	
	# A partir da Onda 4, avalia proximidade da meta de 150ms
	if current_wave_num >= 4:
		var target: float = TARGET_CADENCE_MS_WAVE4
		var cadence_diff: float = absf(mean - target)
		var cadence_accuracy: float = clampf(100.0 - (cadence_diff / target) * 75.0, 0.0, 100.0)
		return (stability * 0.6) + (cadence_accuracy * 0.4)
		
	return stability

func get_left_hand_percent() -> float:
	var total_hands: int = left_hand_count + right_hand_count
	if total_hands == 0:
		return 50.0
	return (float(left_hand_count) / float(total_hands)) * 100.0

func get_right_hand_percent() -> float:
	return 100.0 - get_left_hand_percent()

func _update_rank() -> void:
	var new_rank: String = "F"
	var rank_color: Color = Color.RED
	for entry in RANK_THRESHOLDS:
		if style_points >= entry["min"]:
			new_rank = entry["name"]
			rank_color = entry["color"]
			break
			
	if new_rank != current_rank:
		current_rank = new_rank
		style_rank_changed.emit(current_rank, rank_color, style_points)
