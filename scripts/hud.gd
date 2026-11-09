extends CanvasLayer

# HUD - Interface de usuário com placar, escudos, modais de Game Over e Relatório de KPIs por Fase

signal restart_requested
signal menu_requested
signal next_wave_requested

@onready var score_label: Label = $TopBar/MarginContainer/HBoxContainer/ScoreContainer/ScoreLabel
@onready var high_score_label: Label = $TopBar/MarginContainer/HBoxContainer/ScoreContainer/HighScoreLabel
@onready var combo_label: Label = $TopBar/MarginContainer/HBoxContainer/CenterContainer/ComboLabel
@onready var wave_label: Label = $TopBar/MarginContainer/HBoxContainer/CenterContainer/WaveLabel
@onready var stats_label: Label = $TopBar/MarginContainer/HBoxContainer/StatsContainer/StatsLabel
@onready var shields_container: HBoxContainer = $TopBar/MarginContainer/HBoxContainer/StatsContainer/ShieldsContainer

@onready var wave_banner: Label = $WaveBanner
@onready var game_over_panel: PanelContainer = $GameOverOverlay
@onready var final_score_label: Label = $GameOverOverlay/MarginContainer/VBoxContainer/FinalScoreLabel
@onready var high_score_alert_label: Label = $GameOverOverlay/MarginContainer/VBoxContainer/HighScoreAlert
@onready var final_stats_label: Label = $GameOverOverlay/MarginContainer/VBoxContainer/FinalStatsLabel

@onready var restart_btn: Button = $GameOverOverlay/MarginContainer/VBoxContainer/HBoxContainer/RestartButton
@onready var menu_btn: Button = $GameOverOverlay/MarginContainer/VBoxContainer/HBoxContainer/MenuButton

# Modal de Relatório de KPIs por Fase
@onready var kpi_modal: PanelContainer = $WaveKPIModal
@onready var kpi_title_label: Label = $WaveKPIModal/MarginContainer/VBoxContainer/Title
@onready var kpi_rank_label: Label = $WaveKPIModal/MarginContainer/VBoxContainer/RankContainer/RankBadge
@onready var kpi_acc_label: Label = $WaveKPIModal/MarginContainer/VBoxContainer/GridContainer/AccCard/Margin/VBox/ValueLabel
@onready var kpi_streak_label: Label = $WaveKPIModal/MarginContainer/VBoxContainer/GridContainer/StreakCard/Margin/VBox/ValueLabel
@onready var kpi_interval_label: Label = $WaveKPIModal/MarginContainer/VBoxContainer/GridContainer/IntervalCard/Margin/VBox/ValueLabel
@onready var kpi_speed_label: Label = $WaveKPIModal/MarginContainer/VBoxContainer/GridContainer/SpeedCard/Margin/VBox/ValueLabel
@onready var kpi_next_btn: Button = $WaveKPIModal/MarginContainer/VBoxContainer/NextWaveButton

func _ready() -> void:
	game_over_panel.visible = false
	kpi_modal.visible = false
	wave_banner.modulate.a = 0.0
	
	restart_btn.pressed.connect(func(): restart_requested.emit())
	menu_btn.pressed.connect(func(): menu_requested.emit())
	kpi_next_btn.pressed.connect(_on_next_wave_pressed)
	
	ScoreManager.score_changed.connect(_on_score_changed)
	ScoreManager.combo_changed.connect(_on_combo_changed)
	ScoreManager.stats_updated.connect(_on_stats_updated)
	ScoreManager.high_score_updated.connect(_on_high_score_updated)
	
	_on_high_score_updated(ScoreManager.high_score)
	_on_score_changed(0, 0)
	_on_combo_changed(0, 1.0)
	_on_stats_updated(0.0, 100.0)

func _unhandled_input(event: InputEvent) -> void:
	if kpi_modal.visible and event is InputEventKey and event.pressed and not event.echo:
		var key: InputEventKey = event as InputEventKey
		if key.keycode == KEY_SPACE or key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
			_on_next_wave_pressed()

func update_shields(current: int, _max_val: int) -> void:
	var shields := shields_container.get_children()
	for i in range(shields.size()):
		shields[i].modulate = Color.WHITE if i < current else Color(0.3, 0.3, 0.3, 0.4)

func update_wave(wave: int) -> void:
	wave_label.text = "FASE " + str(wave)

func show_wave_banner(text: String) -> void:
	wave_banner.text = text
	var tween: Tween = create_tween()
	tween.tween_property(wave_banner, "modulate:a", 1.0, 0.3)
	tween.tween_interval(1.2)
	tween.tween_property(wave_banner, "modulate:a", 0.0, 0.4)

func show_wave_kpi_modal(data: Dictionary) -> void:
	kpi_modal.visible = true
	kpi_modal.modulate.a = 0.0
	
	var wave_num: int = data.get("wave_num", 1)
	kpi_title_label.text = "★ RELATÓRIO DE DESEMPENHO - FASE %d ★" % wave_num
	
	var r_name: String = data.get("rank", "A")
	var r_color: Color = data.get("rank_color", Color(0.2, 0.9, 0.4))
	kpi_rank_label.text = "RANK %s" % r_name
	kpi_rank_label.add_theme_color_override("font_color", r_color)
	
	kpi_acc_label.text = "%.1f%%\n(%d acertos | %d erros)" % [
		data.get("accuracy", 100.0),
		data.get("correct_keys", 0),
		data.get("errors", 0)
	]
	
	kpi_streak_label.text = "%d teclas\n(Sequência Perfeita)" % data.get("max_streak", 0)
	
	var target_ms: float = data.get("target_interval_ms", 150.0)
	var avg_ms: float = data.get("avg_interval_ms", 150.0)
	kpi_interval_label.text = "%.0f ms\n(Meta: %.0f ms)" % [avg_ms, target_ms]
	
	kpi_speed_label.text = "%.0f CPM | %.0f PPM\n(Velocidade)" % [
		data.get("cpm", 0.0),
		data.get("wpm", 0.0)
	]
	
	var tween: Tween = create_tween()
	tween.tween_property(kpi_modal, "modulate:a", 1.0, 0.3)

func _on_next_wave_pressed() -> void:
	SoundManager.play_laser(1.1)
	kpi_modal.visible = false
	next_wave_requested.emit()

func show_game_over() -> void:
	SoundManager.play_game_over()
	game_over_panel.visible = true
	game_over_panel.modulate.a = 0.0
	
	final_score_label.text = "PONTOS: " + str(ScoreManager.score)
	if ScoreManager.score >= ScoreManager.high_score and ScoreManager.score > 0:
		high_score_alert_label.text = "★ NOVO RECORDE REGISTRADO! ★"
		high_score_alert_label.visible = true
	else:
		high_score_alert_label.visible = false
		
	var wpm: float = ScoreManager.get_wpm()
	var acc: float = ScoreManager.get_accuracy()
	final_stats_label.text = "Palavras Destruídas: %d\nMaior Combo: %dx\nVelocidade: %.1f WPM\nPrecisão: %.1f%%" % [
		ScoreManager.words_destroyed,
		ScoreManager.max_combo,
		wpm,
		acc
	]
	
	var tween: Tween = create_tween()
	tween.tween_property(game_over_panel, "modulate:a", 1.0, 0.4)

func _on_score_changed(new_score: int, _added: int) -> void:
	score_label.text = "PONTOS: " + str(new_score)

func _on_high_score_updated(new_high: int) -> void:
	high_score_label.text = "RECORDE: " + str(new_high)

func _on_combo_changed(combo: int, multiplier: float) -> void:
	if combo > 1:
		combo_label.text = "COMBO %dx (x%.1f)" % [combo, multiplier]
		combo_label.visible = true
		if combo % 10 == 0 and combo > 0:
			SoundManager.play_combo()
	else:
		combo_label.visible = false

func _on_stats_updated(wpm: float, accuracy: float) -> void:
	stats_label.text = "%.0f WPM | %.0f%%" % [wpm, accuracy]
