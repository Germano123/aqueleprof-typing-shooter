extends Control
class_name TypingPanel

# TypingPanel - Painel lateral de telemetria, teclado virtual e métricas de touch typing

@onready var cpm_label: Label = $MarginContainer/VBoxContainer/MetricsGrid/CPMCard/VBox/ValueLabel
@onready var wpm_label: Label = $MarginContainer/VBoxContainer/MetricsGrid/WPMCard/VBox/ValueLabel
@onready var accuracy_label: Label = $MarginContainer/VBoxContainer/MetricsGrid/AccuracyCard/VBox/ValueLabel
@onready var rhythm_label: Label = $MarginContainer/VBoxContainer/MetricsGrid/RhythmCard/VBox/ValueLabel

@onready var left_hand_bar: ProgressBar = $MarginContainer/VBoxContainer/HandBalanceCard/VBox/HBoxContainer/LeftBar
@onready var left_hand_label: Label = $MarginContainer/VBoxContainer/HandBalanceCard/VBox/HBoxContainer/LeftLabel
@onready var right_hand_label: Label = $MarginContainer/VBoxContainer/HandBalanceCard/VBox/HBoxContainer/RightLabel

@onready var target_word_label: Label = $MarginContainer/VBoxContainer/TargetCard/VBox/TargetWordLabel
@onready var target_hand_label: Label = $MarginContainer/VBoxContainer/TargetCard/VBox/TargetHandLabel
@onready var log_label: Label = $MarginContainer/VBoxContainer/LogCard/VBox/LogLabel

# Dicionário de nós dos botões das teclas do teclado virtual
var key_nodes: Dictionary = {}
var target_key: String = ""
var recent_logs: Array[String] = []

const LEFT_KEYS: Array[String] = ["Q", "W", "E", "R", "T", "A", "S", "D", "F", "G", "Z", "X", "C", "V", "B"]
const RIGHT_KEYS: Array[String] = ["Y", "U", "I", "O", "P", "H", "J", "K", "L", "Ç", "N", "M"]
const HOME_KEYS: Array[String] = ["A", "S", "D", "F", "J", "K", "L", "Ç"]

func _ready() -> void:
	_map_keyboard_keys()
	_apply_initial_keyboard_styles()
	update_target_display("", "")
	add_log("SISTEMA DE TELEMETRIA PRONTO")

func _map_keyboard_keys() -> void:
	var rows: Array[Node] = [
		$MarginContainer/VBoxContainer/KeyboardCard/KeyboardContainer/Row1,
		$MarginContainer/VBoxContainer/KeyboardCard/KeyboardContainer/Row2,
		$MarginContainer/VBoxContainer/KeyboardCard/KeyboardContainer/Row3
	]
	
	for row in rows:
		if row:
			for child in row.get_children():
				if child is Button or child is PanelContainer or child is Control:
					var kname: String = child.name.to_upper().replace("KEY_", "")
					key_nodes[kname] = child

func _apply_initial_keyboard_styles() -> void:
	for kname in key_nodes.keys():
		var node: Control = key_nodes[kname]
		var col: Color = Color(0.12, 0.45, 0.75, 0.7) if LEFT_KEYS.has(kname) else Color(0.55, 0.2, 0.75, 0.7)
		if HOME_KEYS.has(kname):
			col = col.lightened(0.25)
		node.modulate = Color.WHITE

func on_keystroke_feedback(key_char: String, is_correct: bool) -> void:
	var k: String = key_char.to_upper()
	if key_nodes.has(k):
		var node: Control = key_nodes[k]
		var flash_col: Color = Color(0.2, 1.0, 0.4, 1.5) if is_correct else Color(2.0, 0.2, 0.2, 1.5)
		
		var tween: Tween = create_tween()
		tween.tween_property(node, "modulate", flash_col, 0.04)
		tween.tween_property(node, "modulate", Color.WHITE, 0.15)
		
		# Efeito de escala na tecla
		var scale_tween: Tween = create_tween()
		scale_tween.tween_property(node, "scale", Vector2(1.15, 1.15), 0.04).set_trans(Tween.TRANS_QUAD)
		scale_tween.tween_property(node, "scale", Vector2.ONE, 0.1)

func update_target_display(word: String, next_letter: String) -> void:
	target_key = next_letter.to_upper()
	
	if word.length() == 0:
		if target_word_label:
			target_word_label.text = "SEM ALVO TRAVADO"
		if target_hand_label:
			target_hand_label.text = "DIGITE A PRIMEIRA LETRA"
	else:
		if target_word_label:
			target_word_label.text = "ALVO: " + word
		if target_hand_label:
			var hand_str: String = "MÃO ESQUERDA" if LEFT_KEYS.has(target_key) else ("MÃO DIREITA" if RIGHT_KEYS.has(target_key) else "")
			target_hand_label.text = "PRÓXIMA: [%s] (%s)" % [target_key, hand_str]

func update_metrics_display(data: Dictionary) -> void:
	if cpm_label:
		cpm_label.text = "%.0f" % data.get("cpm", 0.0)
	if wpm_label:
		wpm_label.text = "%.0f" % data.get("wpm", 0.0)
	if accuracy_label:
		accuracy_label.text = "%.1f%%" % data.get("accuracy", 100.0)
	if rhythm_label:
		rhythm_label.text = "%.0f%%" % data.get("rhythm_consistency", 80.0)
		
	var left_p: float = data.get("left_hand_percent", 50.0)
	var right_p: float = data.get("right_hand_percent", 50.0)
	if left_hand_bar:
		left_hand_bar.value = left_p
	if left_hand_label:
		left_hand_label.text = "E: %.0f%%" % left_p
	if right_hand_label:
		right_hand_label.text = "D: %.0f%%" % right_p

func add_log(msg: String) -> void:
	recent_logs.push_front(msg)
	if recent_logs.size() > 4:
		recent_logs.pop_back()
		
	if log_label:
		log_label.text = "\n".join(recent_logs)

func update_wave_progress(_current_count: int, _total_count: int, _wave_num: int = 1) -> void:
	pass

func set_computer_message(msg: String, is_alert: bool = false) -> void:
	var prefix: String = "⚠️ " if is_alert else "📡 "
	add_log(prefix + msg)
