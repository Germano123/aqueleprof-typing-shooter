extends Control
class_name DebugLevelSelector

# DebugLevelSelector - Painel modal de depuração acionado por F1
# Permite selecionar instantaneamente qualquer fase (1 a 22+) ou testar diretamente o Chefe da Fase 3

signal wave_selected(wave_number: int, direct_boss: bool)
signal panel_closed

@onready var custom_wave_spin: SpinBox = %CustomWaveSpin
@onready var btn_custom_wave: Button = %BtnCustomWave
@onready var btn_close: Button = %BtnClose
@onready var btn_close_header: Button = %BtnCloseHeader
@onready var btn_boss_fase3: Button = %BtnBossFase3
@onready var btn_boss_direct: Button = %BtnBossDirect
@onready var grid_bloco1: GridContainer = %GridBloco1
@onready var grid_bloco2: GridContainer = %GridBloco2
@onready var grid_bloco3: GridContainer = %GridBloco3
@onready var grid_bloco4: GridContainer = %GridBloco4

func _ready() -> void:
	visible = false
	_setup_button_events()

func open() -> void:
	visible = true
	if is_inside_tree():
		var sm = get_node_or_null("/root/SoundManager")
		if sm and sm.has_method("play_laser"):
			sm.play_laser(1.1)

func close() -> void:
	visible = false
	panel_closed.emit()

func is_open() -> bool:
	return visible

func _setup_button_events() -> void:
	if btn_close:
		btn_close.pressed.connect(close)
	if btn_close_header:
		btn_close_header.pressed.connect(close)
		
	if btn_boss_fase3:
		btn_boss_fase3.pressed.connect(func(): _choose_wave(3, false))
	if btn_boss_direct:
		btn_boss_direct.pressed.connect(func(): _choose_wave(3, true))
		
	if btn_custom_wave and custom_wave_spin:
		btn_custom_wave.pressed.connect(func(): _choose_wave(int(custom_wave_spin.value), false))
		
	_connect_grid(grid_bloco1)
	_connect_grid(grid_bloco2)
	_connect_grid(grid_bloco3)
	_connect_grid(grid_bloco4)

func _connect_grid(grid: GridContainer) -> void:
	if not grid:
		return
	for child in grid.get_children():
		if child is Button:
			var btn: Button = child as Button
			var w_num: int = btn.get_meta("wave", 1)
			var is_boss: bool = btn.get_meta("direct_boss", false)
			btn.pressed.connect(func(): _choose_wave(w_num, is_boss))

func _choose_wave(wave_num: int, direct_boss: bool = false) -> void:
	close()
	wave_selected.emit(wave_num, direct_boss)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	var key_event: InputEventKey = event as InputEventKey
	if key_event and key_event.pressed and not key_event.echo:
		if key_event.keycode == KEY_ESCAPE or key_event.keycode == KEY_F1:
			get_viewport().set_input_as_handled()
			close()
