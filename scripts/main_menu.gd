extends Control

# MainMenu - Menu inicial com instruções interativas, tela de configurações de balanceamento e recordes

@onready var play_button: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var how_to_play_button: Button = $CenterContainer/VBoxContainer/HowToPlayButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var audio_toggle_button: Button = $CenterContainer/VBoxContainer/AudioButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton
@onready var high_score_label: Label = $CenterContainer/VBoxContainer/HighScoreLabel
@onready var ship_preview: Sprite2D = $ShipPreview

# Modal Como Jogar
@onready var how_to_play_modal: PanelContainer = $HowToPlayModal
@onready var close_modal_button: Button = $HowToPlayModal/MarginContainer/VBoxContainer/CloseButton

# Modal Configurações & Dificuldade
@onready var settings_modal: PanelContainer = $SettingsModal
@onready var platform_label: Label = $SettingsModal/MarginContainer/VBoxContainer/PlatformInfoLabel
@onready var wave_option_button: OptionButton = $SettingsModal/MarginContainer/VBoxContainer/ScopeHBox/WaveOptionButton
@onready var preset_facil_btn: Button = $SettingsModal/MarginContainer/VBoxContainer/PresetsHBox/PresetFacilBtn
@onready var preset_normal_btn: Button = $SettingsModal/MarginContainer/VBoxContainer/PresetsHBox/PresetNormalBtn
@onready var preset_dificil_btn: Button = $SettingsModal/MarginContainer/VBoxContainer/PresetsHBox/PresetDificilBtn
@onready var speed_slider: HSlider = $SettingsModal/MarginContainer/VBoxContainer/GridContainer/SpeedSlider
@onready var speed_value_label: Label = $SettingsModal/MarginContainer/VBoxContainer/GridContainer/SpeedValueLabel
@onready var count_slider: HSlider = $SettingsModal/MarginContainer/VBoxContainer/GridContainer/CountSlider
@onready var count_value_label: Label = $SettingsModal/MarginContainer/VBoxContainer/GridContainer/CountValueLabel
@onready var spawn_slider: HSlider = $SettingsModal/MarginContainer/VBoxContainer/GridContainer/SpawnSlider
@onready var spawn_value_label: Label = $SettingsModal/MarginContainer/VBoxContainer/GridContainer/SpawnValueLabel
@onready var feedback_label: Label = $SettingsModal/MarginContainer/VBoxContainer/FeedbackLabel
@onready var save_button: Button = $SettingsModal/MarginContainer/VBoxContainer/ActionButtonsHBox/SaveButton
@onready var reset_button: Button = $SettingsModal/MarginContainer/VBoxContainer/ActionButtonsHBox/ResetButton
@onready var close_settings_button: Button = $SettingsModal/MarginContainer/VBoxContainer/ActionButtonsHBox/CloseSettingsButton

var is_updating_ui: bool = false

func _ready() -> void:
	how_to_play_modal.visible = false
	settings_modal.visible = false
	
	play_button.pressed.connect(_on_play_pressed)
	how_to_play_button.pressed.connect(_on_how_to_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	audio_toggle_button.pressed.connect(_on_audio_toggle_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	close_modal_button.pressed.connect(_on_close_modal_pressed)
	
	# Conexões do modal de configurações
	close_settings_button.pressed.connect(_on_close_settings_pressed)
	save_button.pressed.connect(_on_save_settings_pressed)
	reset_button.pressed.connect(_on_reset_settings_pressed)
	
	preset_facil_btn.pressed.connect(func(): _on_preset_pressed("facil"))
	preset_normal_btn.pressed.connect(func(): _on_preset_pressed("normal"))
	preset_dificil_btn.pressed.connect(func(): _on_preset_pressed("dificil"))
	
	speed_slider.value_changed.connect(_on_speed_slider_changed)
	count_slider.value_changed.connect(_on_count_slider_changed)
	spawn_slider.value_changed.connect(_on_spawn_slider_changed)
	wave_option_button.item_selected.connect(_on_wave_selected)
	
	high_score_label.text = "★ RECORDE ATUAL: %d PONTOS ★" % ScoreManager.high_score
	_update_audio_button_text()
	_populate_waves_dropdown()
	_setup_platform_label()
	
	# Animação suave de flutuação da nave na tela de título
	if ship_preview:
		var tween := create_tween().set_loops()
		tween.tween_property(ship_preview, "position:y", ship_preview.position.y - 12.0, 1.6).set_trans(Tween.TRANS_SINE)
		tween.tween_property(ship_preview, "position:y", ship_preview.position.y + 12.0, 1.6).set_trans(Tween.TRANS_SINE)

func _setup_platform_label() -> void:
	var is_web: bool = OS.has_feature("web")
	if is_web:
		platform_label.text = "🌐 MODO WEB: Alterações ativas na sessão (reseta ao recarregar a página)"
		platform_label.modulate = Color(0.4, 0.9, 1.0)
	else:
		platform_label.text = "🖥️ MODO DESKTOP: Alterações salvas no arquivo JSON local"
		platform_label.modulate = Color(0.7, 1.0, 0.7)

func _populate_waves_dropdown() -> void:
	wave_option_button.clear()
	wave_option_button.add_item("Todas as Fases (Ajuste Global)", 0)
	
	var dm = _get_difficulty_manager()
	for w in range(1, 23):
		var w_name: String = "Fase %d" % w
		if dm:
			w_name = dm.get_wave_name(w)
		wave_option_button.add_item("%d: %s" % [w, w_name], w)
	
	wave_option_button.selected = 0

func _on_play_pressed() -> void:
	SoundManager.play_laser(1.2)
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_how_to_play_pressed() -> void:
	SoundManager.play_type()
	how_to_play_modal.visible = true

func _on_close_modal_pressed() -> void:
	SoundManager.play_type()
	how_to_play_modal.visible = false

func _on_settings_pressed() -> void:
	SoundManager.play_type()
	feedback_label.text = ""
	_refresh_settings_ui()
	settings_modal.visible = true

func _on_close_settings_pressed() -> void:
	SoundManager.play_type()
	settings_modal.visible = false

func _on_preset_pressed(preset_name: String) -> void:
	SoundManager.play_combo()
	var dm = _get_difficulty_manager()
	if dm:
		dm.apply_preset(preset_name)
		feedback_label.text = "✓ Preset '%s' aplicado aos modificadores globais!" % preset_name.to_upper()
		feedback_label.modulate = Color(0.3, 1.0, 0.5)
		_refresh_settings_ui()

func _on_wave_selected(_idx: int) -> void:
	SoundManager.play_type()
	feedback_label.text = ""
	_refresh_settings_ui()

func _refresh_settings_ui() -> void:
	var dm = _get_difficulty_manager()
	if not dm:
		return
		
	is_updating_ui = true
	var selected_wave: int = wave_option_button.get_selected_id()
	
	if selected_wave == 0:
		# Modo Global: mostra multiplicadores baseados em 32.0 px/s, 40 tropas e 1.25s
		var mods: Dictionary = dm.config_data.get("modificadores_globais", {})
		var spd_mult: float = float(mods.get("multiplicador_velocidade", 1.0))
		var cnt_mult: float = float(mods.get("multiplicador_quantidade", 1.0))
		var spw_mult: float = float(mods.get("multiplicador_spawn_intervalo", 1.0))
		
		speed_slider.min_value = 10.0
		speed_slider.max_value = 80.0
		speed_slider.value = 32.0 * spd_mult
		speed_value_label.text = "%.1f px/s (%.2fx)" % [speed_slider.value, spd_mult]
		
		count_slider.min_value = 6.0
		count_slider.max_value = 100.0
		count_slider.value = round(40.0 * cnt_mult)
		count_value_label.text = "%d tropas (%.2fx)" % [int(count_slider.value), cnt_mult]
		
		spawn_slider.min_value = 0.4
		spawn_slider.max_value = 3.0
		spawn_slider.value = 1.25 * spw_mult
		spawn_value_label.text = "%.2f s (%.2fx)" % [spawn_slider.value, spw_mult]
	else:
		# Modo Específico da Fase
		var spd: float = dm.get_fall_speed(selected_wave)
		var cnt: int = dm.get_enemy_count(selected_wave)
		var spw: float = dm.get_spawn_interval(selected_wave)
		
		speed_slider.min_value = 10.0
		speed_slider.max_value = 80.0
		speed_slider.value = spd
		speed_value_label.text = "%.1f px/s" % spd
		
		count_slider.min_value = 6.0
		count_slider.max_value = 100.0
		count_slider.value = float(cnt)
		count_value_label.text = "%d tropas" % cnt
		
		spawn_slider.min_value = 0.4
		spawn_slider.max_value = 3.0
		spawn_slider.value = spw
		spawn_value_label.text = "%.2f s" % spw
		
	is_updating_ui = false

func _on_speed_slider_changed(val: float) -> void:
	if is_updating_ui:
		return
	var selected_wave: int = wave_option_button.get_selected_id()
	if selected_wave == 0:
		var mult: float = val / 32.0
		speed_value_label.text = "%.1f px/s (%.2fx)" % [val, mult]
	else:
		speed_value_label.text = "%.1f px/s" % val

func _on_count_slider_changed(val: float) -> void:
	if is_updating_ui:
		return
	var selected_wave: int = wave_option_button.get_selected_id()
	if selected_wave == 0:
		var mult: float = val / 40.0
		count_value_label.text = "%d tropas (%.2fx)" % [int(val), mult]
	else:
		count_value_label.text = "%d tropas" % int(val)

func _on_spawn_slider_changed(val: float) -> void:
	if is_updating_ui:
		return
	var selected_wave: int = wave_option_button.get_selected_id()
	if selected_wave == 0:
		var mult: float = val / 1.25
		spawn_value_label.text = "%.2f s (%.2fx)" % [val, mult]
	else:
		spawn_value_label.text = "%.2f s" % val

func _on_save_settings_pressed() -> void:
	SoundManager.play_laser(1.1)
	var dm = _get_difficulty_manager()
	if not dm:
		return
		
	var selected_wave: int = wave_option_button.get_selected_id()
	if selected_wave == 0:
		var spd_mult: float = speed_slider.value / 32.0
		var cnt_mult: float = count_slider.value / 40.0
		var spw_mult: float = spawn_slider.value / 1.25
		dm.set_global_multipliers(spd_mult, cnt_mult, spw_mult)
	else:
		dm.set_wave_balance(selected_wave, int(count_slider.value), speed_slider.value, spawn_slider.value)
		
	var success: bool = dm.save_config()
	if success:
		if OS.has_feature("web"):
			feedback_label.text = "✓ Alterações ativas na memória da sessão atual!"
			feedback_label.modulate = Color(0.3, 1.0, 0.4)
		else:
			feedback_label.text = "✓ Alterações salvas com sucesso em JSON local!"
			feedback_label.modulate = Color(0.3, 1.0, 0.4)
	else:
		feedback_label.text = "⚠️ Erro ao gravar arquivo de balanceamento."
		feedback_label.modulate = Color(1.0, 0.4, 0.4)

func _on_reset_settings_pressed() -> void:
	SoundManager.play_type()
	var dm = _get_difficulty_manager()
	if dm:
		dm.reset_to_defaults()
		feedback_label.text = "✓ Padrões originais restaurados!"
		feedback_label.modulate = Color(1.0, 0.9, 0.3)
		_refresh_settings_ui()

func _get_difficulty_manager():
	if has_node("/root/DifficultyManager"):
		return get_node("/root/DifficultyManager")
	return null

func _on_audio_toggle_pressed() -> void:
	SoundManager.sound_enabled = not SoundManager.sound_enabled
	_update_audio_button_text()
	if SoundManager.sound_enabled:
		SoundManager.play_combo()

func _update_audio_button_text() -> void:
	audio_toggle_button.text = "SOM: LIGADO" if SoundManager.sound_enabled else "SOM: MUTADO"

func _on_quit_pressed() -> void:
	get_tree().quit()
