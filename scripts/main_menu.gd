extends Control

# MainMenu - Menu inicial com instruções interativas, high score e efeitos estelares

@onready var play_button: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var how_to_play_button: Button = $CenterContainer/VBoxContainer/HowToPlayButton
@onready var audio_toggle_button: Button = $CenterContainer/VBoxContainer/AudioButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton
@onready var how_to_play_modal: PanelContainer = $HowToPlayModal
@onready var close_modal_button: Button = $HowToPlayModal/MarginContainer/VBoxContainer/CloseButton
@onready var high_score_label: Label = $CenterContainer/VBoxContainer/HighScoreLabel
@onready var ship_preview: Sprite2D = $ShipPreview

func _ready() -> void:
	how_to_play_modal.visible = false
	
	play_button.pressed.connect(_on_play_pressed)
	how_to_play_button.pressed.connect(_on_how_to_play_pressed)
	audio_toggle_button.pressed.connect(_on_audio_toggle_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	close_modal_button.pressed.connect(_on_close_modal_pressed)
	
	high_score_label.text = "★ RECORDE ATUAL: %d PONTOS ★" % ScoreManager.high_score
	_update_audio_button_text()
	
	# Animação suave de flutuação da nave na tela de título
	if ship_preview:
		var tween := create_tween().set_loops()
		tween.tween_property(ship_preview, "position:y", ship_preview.position.y - 12.0, 1.6).set_trans(Tween.TRANS_SINE)
		tween.tween_property(ship_preview, "position:y", ship_preview.position.y + 12.0, 1.6).set_trans(Tween.TRANS_SINE)

func _on_play_pressed() -> void:
	SoundManager.play_laser(1.2)
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_how_to_play_pressed() -> void:
	SoundManager.play_type()
	how_to_play_modal.visible = true

func _on_close_modal_pressed() -> void:
	SoundManager.play_type()
	how_to_play_modal.visible = false

func _on_audio_toggle_pressed() -> void:
	SoundManager.sound_enabled = not SoundManager.sound_enabled
	_update_audio_button_text()
	if SoundManager.sound_enabled:
		SoundManager.play_combo()

func _update_audio_button_text() -> void:
	audio_toggle_button.text = "SOM: LIGADO" if SoundManager.sound_enabled else "SOM: MUTADO"

func _on_quit_pressed() -> void:
	get_tree().quit()
