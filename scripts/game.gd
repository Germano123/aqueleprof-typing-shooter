extends Node2D

# Game - Controlador principal com arena dividida, contador de progresso da onda (0 a 100%) e telemetria

@export var projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")
@export var floating_text_scene: PackedScene = preload("res://scenes/floating_text.tscn")
@export var enemy_scene: PackedScene = preload("res://scenes/enemy_word.tscn")
@export var boss_scene: PackedScene = preload("res://scenes/boss_dreadnought.tscn")
@export var missile_scene: PackedScene = preload("res://scenes/homing_missile.tscn")

@onready var player: Node2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var typing_panel: TypingPanel = $TypingPanel
@onready var word_container: Node2D = $WordContainer
@onready var projectile_container: Node2D = $ProjectileContainer
@onready var effect_container: Node2D = $EffectContainer
@onready var spawn_timer: Timer = $SpawnTimer
@onready var camera: Camera2D = $Camera2D

var targeted_enemy: EnemyWord = null
var current_wave: int = 1
var is_game_over: bool = false
var is_wave_transition: bool = false
var base_fall_speed: float = 34.0
var base_spawn_interval: float = 1.25
var shake_intensity: float = 0.0

var typing_metrics: TypingMetrics = null
var wave_queue: Array[Dictionary] = []
var wave_enemies_remaining: int = 0
var total_wave_enemies: int = 0
var defeated_wave_enemies: int = 0
var current_wave_transition_id: int = 0
var current_section_id: int = 1

# Batalha contra Chefes e Mísseis Teleguiados
var current_boss: BossDreadnought = null
var is_boss_wave: bool = false
var active_missiles: Array[HomingMissile] = []
var missile_spawn_timer: float = 0.0

const SPECIAL_DODGE_SYMBOLS: String = "!@#$%¨&*()^"
const MISSILE_SYMBOLS: Array[Dictionary] = [
	{"sym": "!", "key": "1"},
	{"sym": "@", "key": "2"},
	{"sym": "#", "key": "3"},
	{"sym": "$", "key": "4"},
	{"sym": "%", "key": "5"},
	{"sym": "¨", "key": "6"},
	{"sym": "&", "key": "7"},
	{"sym": "*", "key": "8"},
	{"sym": "(", "key": "9"},
	{"sym": ")", "key": "0"}
]

const BOTTOM_LIMIT_Y: float = 630.0
const MIN_ON_SCREEN_ENEMIES: int = 4
const MAX_ON_SCREEN_ENEMIES: int = 12

var computer_tip_timer: float = 0.0
var idle_tip_index: int = 0

const COMPUTER_TIPS: Array[String] = [
	"Alternar entre os canhões ganha mais pontos.",
	"Para disparos mais fortes você precisa manter seu ritmo constante.",
	"Inimigos mais fortes já estão na linha de frente.",
	"Alerta! Próxima horda está a caminho.",
	"Teclas da linha de base (A S D F e J K L Ç) estabilizam sua precisão espacial.",
	"Mantenha cadência regular para ativar o Overdrive de plasma da nave."
]

func _ready() -> void:
	randomize()
	typing_metrics = TypingMetrics.new()
	_setup_column_guides()
	_setup_connections()
	start_game()

func _setup_column_guides() -> void:
	var guides_node := Node2D.new()
	guides_node.name = "ColumnGuides"
	guides_node.z_index = 1
	add_child(guides_node)
	move_child(guides_node, 3)
	
	# Divisores verticais delimitando as 10 colunas fixas dos dedos
	var dividers: Array[float] = [50.0, 122.0, 194.0, 266.0, 338.0, 410.0, 482.0, 554.0, 626.0, 698.0, 770.0]
	for div_x in dividers:
		var line := Line2D.new()
		line.points = PackedVector2Array([Vector2(div_x, 0.0), Vector2(div_x, BOTTOM_LIMIT_Y)])
		if is_equal_approx(div_x, 410.0):
			line.width = 2.0
			line.default_color = Color(0.35, 0.75, 1.0, 0.35) # Divisor Mão Esquerda vs Mão Direita
		else:
			line.width = 1.0
			line.default_color = Color(0.2, 0.45, 0.75, 0.12) # Linha divisória entre dedos
		guides_node.add_child(line)

func _setup_connections() -> void:
	player.health_changed.connect(hud.update_shields)
	player.died.connect(_on_player_died)
	
	hud.restart_requested.connect(start_game)
	hud.menu_requested.connect(_on_menu_requested)
	hud.next_wave_requested.connect(_on_next_wave_requested)
	hud.debug_wave_selected.connect(_on_debug_wave_selected)
	
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	typing_metrics.style_rank_changed.connect(_on_style_rank_changed)
	typing_metrics.metrics_updated.connect(_on_metrics_updated)
	typing_metrics.hand_alternation_bonus.connect(_on_hand_alternation_bonus)
	typing_metrics.difficult_key_bonus.connect(_on_difficult_key_bonus)
	typing_metrics.flow_intensity_changed.connect(_on_flow_intensity_changed)

func start_game() -> void:
	is_game_over = false
	is_wave_transition = false
	current_wave = 1
	targeted_enemy = null
	
	for child in word_container.get_children():
		child.queue_free()
	for child in projectile_container.get_children():
		child.queue_free()
	for child in effect_container.get_children():
		child.queue_free()
		
	player.reset()
	ScoreManager.start_session()
	typing_metrics.start_session()
	
	hud.game_over_panel.visible = false
	hud.kpi_modal.visible = false
	_update_target_panel()
	typing_panel.add_log("💡 MODO DEBUG: PRESSIONE F1 PARA SELETOR DE FASES")
	
	_start_wave_sequence(current_wave)

func _start_wave_sequence(wave_num: int, direct_boss: bool = false) -> void:
	current_wave_transition_id += 1
	current_wave = wave_num
	is_wave_transition = false
	targeted_enemy = null
	current_section_id = 1
	
	# Limpar mísseis e chefes anteriores
	for m in active_missiles:
		if is_instance_valid(m):
			m.queue_free()
	active_missiles.clear()
	missile_spawn_timer = 0.0
	
	if is_instance_valid(current_boss):
		current_boss.queue_free()
		current_boss = null
	is_boss_wave = false
	
	wave_queue = WordManager.generate_wave_queue(current_wave, direct_boss)
	total_wave_enemies = wave_queue.size()
	defeated_wave_enemies = 0
	wave_enemies_remaining = total_wave_enemies
	
	player.update_wave_progress(0, total_wave_enemies)
	typing_panel.update_wave_progress(0, total_wave_enemies, current_wave)
	typing_metrics.start_wave(current_wave)
	
	# Se for Fase 6 ou Fase 3 em modo direto, inicializar a batalha de chefe imediatamente
	if (current_wave == 6 or (current_wave == 3 and direct_boss)) and boss_scene:
		_spawn_boss()
	
	var tree := get_tree()
	if tree and tree.root and tree.root.has_node("DifficultyManager"):
		var dm = tree.root.get_node("DifficultyManager")
		base_fall_speed = dm.get_fall_speed(current_wave)
		base_spawn_interval = dm.get_spawn_interval(current_wave)
	else:
		match current_wave:
			1, 2, 3, 4, 5, 6:
				base_fall_speed = 32.0
				base_spawn_interval = 1.25
			7, 8, 9, 10, 11, 12:
				base_fall_speed = 35.0
				base_spawn_interval = 1.15
			13, 14, 15, 16, 17, 18:
				base_fall_speed = 33.0
				base_spawn_interval = 1.10
			19:
				base_fall_speed = 24.0
				base_spawn_interval = 1.45
			20:
				base_fall_speed = 19.0
				base_spawn_interval = 1.55
			21:
				base_fall_speed = 19.0
				base_spawn_interval = 2.40
			_:
				base_fall_speed = 22.0
				base_spawn_interval = 1.40
			
	spawn_timer.wait_time = maxf(0.5, base_spawn_interval * typing_metrics.get_flow_spawn_multiplier())
	hud.update_wave(current_wave)
	spawn_timer.start()
	
	var banner_text: String = "Fase %d" % current_wave
	match current_wave:
		1: banner_text = "Fase 1: Indicadores Base (F - J)"
		2: banner_text = "Fase 2: Novos Inimigos: Indicadores Centro (G - H)"
		3: banner_text = "Fase 3: Novos Inimigos: Dedos Médios (D - K) [Chefe ao Final]"
		4: banner_text = "Fase 4: Novos Inimigos: Dedos Anelares (S - L)"
		5: banner_text = "Fase 5: Novos Inimigos: Dedos Mínimos (A - Ç)"
		6: banner_text = "Fase 6: Batalha de Chefe - Encouraçado Ômega"
		7: banner_text = "Fase 7: Linha Superior (R - U)"
		8: banner_text = "Fase 8: Novos Inimigos: Linha Superior (T - Y)"
		9: banner_text = "Fase 9: Novos Inimigos: Linha Superior (E - I)"
		10: banner_text = "Fase 10: Novos Inimigos: Linha Superior (W - O)"
		11: banner_text = "Fase 11: Novos Inimigos: Linha Superior (Q - P)"
		12: banner_text = "Fase 12: Desafio Master da Linha Superior"
		13: banner_text = "Fase 13: Linha Inferior (B - N)"
		14: banner_text = "Fase 14: Novos Inimigos: Linha Inferior (V - M)"
		15: banner_text = "Fase 15: Novos Inimigos: Linha Inferior (C - ,)"
		16: banner_text = "Fase 16: Novos Inimigos: Linha Inferior (X - .)"
		17: banner_text = "Fase 17: Novos Inimigos: Linha Inferior (Z - ;)"
		18: banner_text = "Fase 18: Desafio Master da Linha Inferior"
		19: banner_text = "Fase 19: Cruzadores Pesados 2-HP (Blindagem Dupla)"
		20: banner_text = "Fase 20: Cruzadores Pesados 3-HP (Blindagem Tripla)"
		21: banner_text = "Fase 21: Alcance Difícil - Palavras Longas"
		_: banner_text = "Fase %d: Horda Mista Cósmica" % current_wave
		
	hud.show_wave_banner(banner_text)
	typing_panel.add_log("=== %s ===" % banner_text)
	
	match current_wave:
		1:
			typing_panel.set_computer_message("Inicie com os indicadores nas teclas base F e J.")
		2:
			typing_panel.set_computer_message("Novos invasores detectados: estenda os indicadores para G e H!", true)
		3:
			typing_panel.set_computer_message("Invasores nas colunas dos dedos médios (D e K). Alerta: nave capital inimiga detectada ao final do setor!", true)
		4:
			typing_panel.set_computer_message("Alvos nos dedos anelares: posicione S e L!", true)
		5:
			typing_panel.set_computer_message("Alvos nos extremos: use os dedos mínimos em A e Ç!", true)
		6:
			typing_panel.set_computer_message("ALERTA DE CHEFE: Encouraçado Ômega! Complete a artilharia para danificar os canhões e use SHIFT+número para esquivar de mísseis!", true)
		19, 20:
			typing_panel.set_computer_message("Inimigos blindados na linha de frente! Mantenha ritmo para destruí-los.", true)
		_:
			typing_panel.set_computer_message("Para disparos mais fortes você precisa manter seu ritmo constante.")
	
	# Inicia a onda garantindo pelo menos 4 alvos visíveis e ativos na tela com escalonamento vertical
	var initial_staggers: Array[float] = [150.0, 100.0, 50.0, 0.0]
	for stagger in initial_staggers:
		if not wave_queue.is_empty():
			_spawn_enemy(stagger)
	_maintain_enemy_density()

func _process(delta: float) -> void:
	_process_camera_shake(delta)
	if not is_game_over and not is_wave_transition:
		if typing_metrics:
			typing_metrics.process_decay(delta)
		if _get_active_enemy_count() < MIN_ON_SCREEN_ENEMIES and not wave_queue.is_empty():
			_maintain_enemy_density()
			
		# Spawner periódico de mísseis teleguiados na batalha contra o chefe
		if is_boss_wave and is_instance_valid(current_boss) and missile_scene != null:
			missile_spawn_timer += delta
			if missile_spawn_timer >= 8.5 and active_missiles.size() < 2:
				missile_spawn_timer = 0.0
				_spawn_boss_homing_missile()
			
		computer_tip_timer += delta
		if computer_tip_timer >= 12.0:
			computer_tip_timer = 0.0
			_dispatch_computer_tip()

func _dispatch_computer_tip() -> void:
	if COMPUTER_TIPS.is_empty():
		return
	var tip: String = COMPUTER_TIPS[idle_tip_index % COMPUTER_TIPS.size()]
	idle_tip_index += 1
	typing_panel.set_computer_message(tip, false)

func _process_camera_shake(delta: float) -> void:
	if shake_intensity > 0.0:
		shake_intensity = maxf(0.0, shake_intensity - 30.0 * delta)
		camera.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
	else:
		camera.offset = Vector2.ZERO

func apply_shake(amount: float) -> void:
	shake_intensity = maxf(shake_intensity, amount)

# ----------------- SISTEMA DE ENTRADA E DIGITAÇÃO -----------------

func _input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event and key_event.pressed and not key_event.echo:
		if key_event.keycode == KEY_F1:
			get_viewport().set_input_as_handled()
			if hud:
				hud.toggle_debug_panel()
		elif key_event.keycode == KEY_ESCAPE and hud and hud.is_debug_panel_open():
			get_viewport().set_input_as_handled()
			hud.close_debug_panel()

func _on_debug_wave_selected(wave_num: int, direct_boss: bool) -> void:
	_warp_to_wave(wave_num, direct_boss)

func _warp_to_wave(wave_num: int, direct_boss: bool = false) -> void:
	if is_game_over:
		is_game_over = false
		if hud and hud.game_over_panel:
			hud.game_over_panel.visible = false
		
	# Limpar todos os inimigos da arena imediatamente
	for child in word_container.get_children():
		if child is EnemyWord:
			child.queue_free()
			
	for child in projectile_container.get_children():
		child.queue_free()
		
	for m in active_missiles:
		if is_instance_valid(m):
			m.queue_free()
	active_missiles.clear()
	missile_spawn_timer = 0.0
	
	if is_instance_valid(current_boss):
		current_boss.queue_free()
		current_boss = null
	is_boss_wave = false
	
	wave_queue.clear()
	spawn_timer.stop()
	if is_instance_valid(targeted_enemy):
		targeted_enemy.set_targeted(false)
	targeted_enemy = null
	player.set_target(null)
	_update_target_panel()
	
	if hud and is_instance_valid(hud.kpi_modal):
		hud.kpi_modal.visible = false
		
	typing_panel.add_log("⚡ [DEBUG F1] SELEÇÃO: INICIANDO FASE %d%s" % [wave_num, " (CHEFE)" if direct_boss else ""])
	SoundManager.play_laser(1.2)
	_start_wave_sequence(wave_num, direct_boss)

func _debug_advance_next_wave() -> void:
	_warp_to_wave(current_wave + 1, false)

func _unhandled_key_input(event: InputEvent) -> void:
	if is_game_over or is_wave_transition or (hud and hud.is_debug_panel_open()):
		return
		
	var key_event: InputEventKey = event as InputEventKey
	if key_event and key_event.pressed and not key_event.echo:
		var unicode: int = key_event.unicode
		if unicode > 0:
			var raw_char: String = String.chr(unicode)
			var sanitized_char: String = _sanitize_char(raw_char)
			if sanitized_char.length() > 0:
				_handle_typed_character(sanitized_char)

func _sanitize_char(c: String) -> String:
	if SPECIAL_DODGE_SYMBOLS.contains(c):
		return c
	var upper: String = c.to_upper()
	var map: Dictionary = {
		"Á": "A", "À": "A", "Ã": "A", "Â": "A", "Ä": "A",
		"É": "E", "È": "E", "Ê": "E", "Ë": "E",
		"Í": "I", "Ì": "I", "Î": "I", "Ï": "I",
		"Ó": "O", "Ò": "O", "Õ": "O", "Ô": "O", "Ö": "O",
		"Ú": "U", "Ù": "U", "Û": "U", "Ü": "U",
		"Ç": "Ç"
	}
	if map.has(upper):
		return map[upper]
	if (upper >= "A" and upper <= "Z") or (upper >= "0" and upper <= "9") or upper == "-" or upper == "_" or upper == "Ç" or upper == "," or upper == "." or upper == ";":
		return upper
	return ""

func _handle_typed_character(char_typed: String) -> void:
	# Prioridade de interceptação de mísseis teleguiados
	if active_missiles.size() > 0:
		var target_missile: HomingMissile = null
		for m in active_missiles:
			if is_instance_valid(m) and not m.is_intercepted and m.get_symbol() == char_typed:
				target_missile = m
				break
		if target_missile != null:
			_intercept_missile(target_missile)
			return

	if SPECIAL_DODGE_SYMBOLS.contains(char_typed):
		SoundManager.play_error()
		ScoreManager.register_wrong_keystroke()
		typing_panel.on_keystroke_feedback(char_typed, false)
		typing_panel.add_log("⚠️ NENHUM MÍSSEL COM SÍMBOLO [%s]" % char_typed)
		return

	if is_instance_valid(targeted_enemy):
		var expected: String = targeted_enemy.get_next_letter()
		if char_typed == expected:
			_fire_at_target(targeted_enemy)
			ScoreManager.register_correct_keystroke()
			typing_metrics.register_keystroke(char_typed, true)
			typing_panel.on_keystroke_feedback(char_typed, true)
			targeted_enemy.on_correct_letter()
			_update_target_panel()
		else:
			SoundManager.play_error()
			ScoreManager.register_wrong_keystroke()
			typing_metrics.register_keystroke(char_typed, false)
			typing_panel.on_keystroke_feedback(char_typed, false)
			typing_panel.add_log("⚠️ ERRO DE TECLA: [%s]" % char_typed)
			targeted_enemy.on_wrong_letter()
			apply_shake(2.0)
		return

	var matching_enemies: Array[EnemyWord] = []
	for child in word_container.get_children():
		if child is EnemyWord and not child.is_queued_for_deletion():
			var enemy_item: EnemyWord = child as EnemyWord
			if enemy_item.get_first_letter() == char_typed:
				matching_enemies.append(enemy_item)
				
	if matching_enemies.size() > 0:
		var closest: EnemyWord = matching_enemies[0]
		for e in matching_enemies:
			if e.global_position.y > closest.global_position.y:
				closest = e
				
		if is_instance_valid(targeted_enemy) and targeted_enemy != closest:
			targeted_enemy.set_targeted(false)
			
		targeted_enemy = closest
		player.set_target(targeted_enemy)
		targeted_enemy.set_targeted(true)
		
		_fire_at_target(targeted_enemy)
		ScoreManager.register_correct_keystroke()
		typing_metrics.register_keystroke(char_typed, true)
		typing_panel.on_keystroke_feedback(char_typed, true)
		targeted_enemy.on_correct_letter()
		_update_target_panel()
	else:
		SoundManager.play_error()
		ScoreManager.register_wrong_keystroke()
		typing_metrics.register_keystroke(char_typed, false)
		typing_panel.on_keystroke_feedback(char_typed, false)
		typing_panel.add_log("⚠️ NENHUM ALVO COM [%s]" % char_typed)

func _update_target_panel() -> void:
	if is_instance_valid(targeted_enemy):
		typing_panel.update_target_display(targeted_enemy.full_word, targeted_enemy.get_next_letter())
	else:
		typing_panel.update_target_display("", "")

func _fire_at_target(target: EnemyWord) -> void:
	var rank_mult: float = 1.0
	if typing_metrics.current_rank == "SS":
		rank_mult = 1.25
	elif typing_metrics.current_rank == "S":
		rank_mult = 1.15
	elif typing_metrics.current_rank == "A":
		rank_mult = 1.05
		
	SoundManager.play_laser(rank_mult)
	player.shoot_visual_feedback()
	
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		if proj:
			projectile_container.add_child(proj)
			proj.setup(player.get_shoot_origin(), target.global_position + Vector2(0, 10), target)

# ----------------- EVENTOS DE TELEMETRIA E BÔNUS -----------------

func _on_style_rank_changed(rank_name: String, rank_color: Color, style_pts: float) -> void:
	player.update_style_rank(rank_name, rank_color, style_pts)
	typing_panel.add_log("★ RANK DE ESTILO: %s" % rank_name)
	if rank_name == "C" or rank_name == "D" or rank_name == "E" or rank_name == "F":
		typing_panel.set_computer_message("Para disparos mais fortes você precisa manter seu ritmo constante.")
	elif rank_name == "SS":
		typing_panel.set_computer_message("Potência máxima atingida! Overdrive total nos canhões de plasma.", true)

func _on_metrics_updated(data: Dictionary) -> void:
	typing_panel.update_metrics_display(data)

func _on_hand_alternation_bonus(streak: int) -> void:
	var bonus_pts: int = streak * 35
	ScoreManager.score += bonus_pts
	typing_panel.add_log("⚡ ALTERNÂNCIA x%d (+%d pts)" % [streak, bonus_pts])
	typing_panel.set_computer_message("Alternar entre os canhões ganha mais pontos.")
	
	if floating_text_scene and is_instance_valid(targeted_enemy):
		var float_node = floating_text_scene.instantiate()
		float_node.setup("ALTERNÂNCIA! +%d" % bonus_pts, targeted_enemy.global_position + Vector2(0, -30), Color(0.9, 0.4, 1.0))
		effect_container.add_child(float_node)

func _on_difficult_key_bonus(from_key: String, to_key: String, bonus_pts: int) -> void:
	ScoreManager.score += bonus_pts
	typing_panel.add_log("▲ ALCANCE %s -> %s (+%d pts)" % [from_key, to_key, bonus_pts])
	
	if floating_text_scene and is_instance_valid(targeted_enemy):
		var float_node = floating_text_scene.instantiate()
		float_node.setup("ALCANCE! +%d" % bonus_pts, targeted_enemy.global_position + Vector2(0, -50), Color(1.0, 0.8, 0.2))
		effect_container.add_child(float_node)

func _on_flow_intensity_changed(flow_state: String, mult: float, desc: String) -> void:
	spawn_timer.wait_time = maxf(0.5, base_spawn_interval * mult)
	typing_panel.add_log(desc)
	if flow_state == "FRENESI":
		typing_panel.set_computer_message("Ritmo frenético! Invasores aproximam-se com frequência ampliada.", true)
	elif flow_state == "RECUPERAÇÃO":
		typing_panel.set_computer_message("Modo recuperação ativado: cadência reduzida para reorganização.")
	elif flow_state == "ACELERADO":
		typing_panel.set_computer_message("Excelente sequência! O fluxo de combate está acelerando.")


# ----------------- SPAWN E FLUXO DE FASES -----------------

func _spawn_enemy(offset_y: float = 0.0) -> void:
	if is_game_over or is_wave_transition:
		return
		
	if wave_queue.is_empty():
		# Se estivermos na batalha de chefe e o chefe ainda estiver vivo, repor munição de artilharia
		if is_boss_wave and is_instance_valid(current_boss) and not current_boss.is_defeated:
			var side_needed: String = "core"
			if current_boss.is_left_cannon_alive():
				side_needed = "left"
			elif current_boss.is_right_cannon_alive():
				side_needed = "right"
			var fallback_item: Dictionary = WordManager.generate_boss_artillery_item(current_wave, side_needed)
			wave_queue.append(fallback_item)
		else:
			spawn_timer.stop()
			return
		
	var item: Dictionary = wave_queue.pop_front()
	var sec_id: int = item.get("section_id", 1)
	if sec_id != current_section_id:
		current_section_id = sec_id
		_on_section_transition(sec_id)
		
	# Se for Fase 3 e chegou na seção do chefe (ao final do level 3), inicializar o chefe
	if current_wave == 3 and sec_id == 2 and not is_boss_wave and not is_instance_valid(current_boss):
		_spawn_boss()
		
	var word_str: String = item["word"]
	var word_tag: String = item["tag"]
	var spawn_x: float = item["spawn_x"]
	var enemy_color: Color = item.get("color", Color.WHITE)
	var enemy_scale: float = item.get("scale", 1.0)
	
	# Descida estrita em 10 colunas fixas associadas aos dedos das mãos
	# Evitar sobreposição vertical se houver inimigo descendo na mesmíssima coluna
	var spawn_y: float = -55.0 + offset_y
	for child in word_container.get_children():
		if child is EnemyWord and not child.is_queued_for_deletion():
			if absf(child.global_position.x - spawn_x) < 25.0 and child.global_position.y < 50.0:
				spawn_y = minf(spawn_y, child.global_position.y - 75.0)
	var base_spd: float = item.get("speed", base_fall_speed)
	var speed: float = base_spd + randf_range(-0.8, 0.8)
	
	var enemy: EnemyWord = enemy_scene.instantiate() as EnemyWord
	word_container.add_child(enemy)
	var side_str: String = item.get("cannon_side", "")
	enemy.setup(word_str, speed, Vector2(spawn_x, spawn_y), BOTTOM_LIMIT_Y, word_tag, enemy_color, enemy_scale, side_str)
	
	enemy.word_completed.connect(_on_enemy_word_completed)
	enemy.reached_bottom.connect(_on_enemy_reached_bottom)

func _on_section_transition(new_sec_id: int) -> void:
	if typing_metrics:
		typing_metrics.reset_flow_rhythm()
	spawn_timer.wait_time = maxf(0.5, base_spawn_interval * 1.0)
	
	if current_wave == 3 and new_sec_id == 2:
		hud.show_wave_banner("ALERTA DE CHEFE: ENCOURAÇADO ÔMEGA!")
		typing_panel.set_computer_message("ALERTA MÁXIMO! O Encouraçado Ômega aproximou-se ao final do setor! Destrua os canhões e esquive dos mísseis!", true)
		typing_panel.add_log("🚨 SEÇÃO 2: ENCOURAÇADO ÔMEGA DETECTADO AO FINAL DO LEVEL 3!")
		SoundManager.play_boss_alert()
	else:
		hud.show_wave_banner("Novos inimigos foram encontrados!")
		typing_panel.set_computer_message("Alerta! Novos inimigos foram encontrados!", true)
		typing_panel.add_log("🔔 SEÇÃO %d: Novos inimigos foram encontrados!" % new_sec_id)
		SoundManager.play_comms()

func _get_active_enemy_count() -> int:
	var count: int = 0
	for child in word_container.get_children():
		if child is EnemyWord and not child.is_queued_for_deletion():
			count += 1
	return count

func _maintain_enemy_density() -> void:
	if is_game_over or is_wave_transition:
		return
	var stagger_step: float = 0.0
	while _get_active_enemy_count() < MIN_ON_SCREEN_ENEMIES and not wave_queue.is_empty():
		_spawn_enemy(stagger_step)
		stagger_step += 25.0

func _on_enemy_word_completed(enemy: EnemyWord) -> void:
	var pts: int = ScoreManager.register_word_destroyed(enemy.full_word.length(), 1.0 + (current_wave * 0.1))
	wave_enemies_remaining = maxi(0, wave_enemies_remaining - 1)
	defeated_wave_enemies += 1
	player.update_wave_progress(defeated_wave_enemies, total_wave_enemies)
	typing_panel.update_wave_progress(defeated_wave_enemies, total_wave_enemies, current_wave)
	
	if explosion_scene:
		var exp_node: Node2D = explosion_scene.instantiate() as Node2D
		exp_node.global_position = enemy.global_position
		effect_container.add_child(exp_node)
		
	if floating_text_scene:
		var float_node = floating_text_scene.instantiate()
		var mult: float = ScoreManager.get_multiplier()
		var txt: String = "+%d" % pts
		if mult > 1.0:
			txt += " (x%.1f)" % mult
		float_node.setup(txt, enemy.global_position, Color(0.3, 1.0, 0.4) if mult > 1.0 else Color(1.0, 0.9, 0.2))
		effect_container.add_child(float_node)
		
	apply_shake(3.0)
	
	# Disparo de artilharia contra ponto vital do chefe se for fase de chefe
	if is_boss_wave and is_instance_valid(current_boss) and enemy.cannon_side.length() > 0:
		_fire_artillery_barrage_at_boss(enemy.cannon_side)
	
	if targeted_enemy == enemy:
		targeted_enemy = null
		player.set_target(null)
		_update_target_panel()
		
	if wave_enemies_remaining == 5:
		typing_panel.set_computer_message("Alerta! Próxima horda está a caminho.", true)
		
	enemy.queue_free()
	_maintain_enemy_density()
	_check_wave_completion()

func _on_enemy_reached_bottom(enemy: EnemyWord) -> void:
	wave_enemies_remaining = maxi(0, wave_enemies_remaining - 1)
	defeated_wave_enemies += 1
	player.update_wave_progress(defeated_wave_enemies, total_wave_enemies)
	typing_panel.update_wave_progress(defeated_wave_enemies, total_wave_enemies, current_wave)
	
	if explosion_scene:
		var exp_node: Node2D = explosion_scene.instantiate() as Node2D
		exp_node.global_position = enemy.global_position
		effect_container.add_child(exp_node)
		
	apply_shake(14.0)
	player.take_damage(1)
	ScoreManager.register_wrong_keystroke()
	typing_metrics.register_keystroke("", false)
	typing_panel.add_log("💥 BASE ATINGIDA (-1 ESCUDO)")
	typing_panel.set_computer_message("Alerta de dano! Escudos comprometidos. Elimine os alvos mais próximos da base!", true)
	
	if targeted_enemy == enemy:
		targeted_enemy = null
		player.set_target(null)
		_update_target_panel()
		
	enemy.queue_free()
	_maintain_enemy_density()
	_check_wave_completion()

func _check_wave_completion() -> void:
	if is_game_over or is_wave_transition:
		return
		
	if is_boss_wave and is_instance_valid(current_boss) and not current_boss.is_defeated:
		return
		
	if wave_queue.is_empty() and _get_active_enemy_count() == 0:
		_trigger_wave_completed()

func _trigger_wave_completed() -> void:
	is_wave_transition = true
	spawn_timer.stop()
	targeted_enemy = null
	player.set_target(null)
	_update_target_panel()
	
	var kpis: Dictionary = typing_metrics.get_wave_kpis()
	hud.show_wave_kpi_modal(kpis)
	typing_panel.add_log("★ FASE %d CONCLUÍDA! RELATÓRIO DE KPIS ABERTO" % current_wave)
	SoundManager.play_combo()

func _on_next_wave_requested() -> void:
	is_wave_transition = true
	var expected_wave: int = current_wave + 1
	var token: int = current_wave_transition_id
	hud.show_wave_banner("FASE %d EM 2 SEGUNDOS..." % expected_wave)
	typing_panel.add_log("⏱ PREPARANDO FASE %d (2s)..." % expected_wave)
	typing_panel.set_computer_message("Alerta! Próxima horda está a caminho.", true)
	
	await get_tree().create_timer(2.0).timeout
	if not is_game_over and token == current_wave_transition_id:
		_start_wave_sequence(expected_wave)

func _on_spawn_timer_timeout() -> void:
	if not is_game_over and not is_wave_transition:
		# Capacidade base de acordo com a fase
		var base_cap: int = 8 if current_wave >= 6 else (6 if current_wave == 5 else MAX_ON_SCREEN_ENEMIES)
		# Teto dinâmico que se expande com o ritmo do jogador
		var max_allowed: int = typing_metrics.get_flow_max_active_enemies(base_cap) if typing_metrics else base_cap
		
		# A quantidade de inimigos spawnados por pulso aumenta de acordo com o ritmo do jogador (1x, 2x ou 3x)
		var batch_count: int = typing_metrics.get_flow_spawn_batch_count() if typing_metrics else 1
		for i in range(batch_count):
			if not wave_queue.is_empty() and _get_active_enemy_count() < max_allowed:
				_spawn_enemy(i * 20.0) # Leve defasagem vertical para os novos alvos
				
		# Mantém sempre o piso mínimo de 4 alvos na arena
		_maintain_enemy_density()

func _on_player_died() -> void:
	is_game_over = true
	spawn_timer.stop()
	if is_instance_valid(targeted_enemy):
		targeted_enemy.set_targeted(false)
	targeted_enemy = null
	player.set_target(null)
	_update_target_panel()
	
	# Congelar todos os inimigos ativos na arena para encerrar a fase de verdade
	for child in word_container.get_children():
		if child is EnemyWord:
			(child as EnemyWord).stop()
			
	ScoreManager.end_session()
	hud.show_game_over()
	typing_panel.add_log("☠ MISSÃO ENCERRADA")

func _on_menu_requested() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# ----------------- BATALHA CONTRA CHEFES E MÍSSEIS TELEGUIADOS -----------------

func _spawn_boss() -> void:
	if not boss_scene or is_instance_valid(current_boss):
		return
	is_boss_wave = true
	current_boss = boss_scene.instantiate() as BossDreadnought
	current_boss.position = Vector2(410, 100)
	add_child(current_boss)
	current_boss.cannon_destroyed.connect(_on_boss_cannon_destroyed)
	current_boss.shield_collapsed.connect(_on_boss_shield_collapsed)
	current_boss.boss_defeated.connect(_on_boss_defeated)
	SoundManager.play_boss_alert()
	apply_shake(12.0)

func _spawn_boss_homing_missile() -> void:
	if not is_boss_wave or not is_instance_valid(current_boss) or missile_scene == null:
		return
	var missile: HomingMissile = missile_scene.instantiate() as HomingMissile
	if not missile:
		return
	var item: Dictionary = MISSILE_SYMBOLS.pick_random()
	var launch_pos: Vector2 = current_boss.global_position + Vector2(randf_range(-150.0, 150.0), 30.0)
	add_child(missile)
	missile.setup(item["sym"], item["key"], launch_pos, player)
	missile.intercepted.connect(_on_missile_intercepted)
	missile.impacted.connect(_on_missile_impacted)
	active_missiles.append(missile)
	SoundManager.play_missile_warning()
	typing_panel.set_computer_message("⚠️ MÍSSEL DETECTADO! Pressione SHIFT + %s para contra-atacar!" % item["key"], true)
	typing_panel.add_log("⚠️ MÍSSEL EM ROTA DE COLISÃO! Símbolo [%s] (SHIFT + %s)" % [item["sym"], item["key"]])

func _intercept_missile(missile: HomingMissile) -> void:
	if not is_instance_valid(missile):
		return
	missile.intercept()
	ScoreManager.score += 250
	ScoreManager.register_correct_keystroke()
	typing_metrics.register_keystroke(missile.get_symbol(), true)
	typing_panel.on_keystroke_feedback(missile.get_symbol(), true)
	typing_panel.add_log("⚡ MÍSSEL INTERCEPTADO! (+250 pts)")
	SoundManager.play_missile_destroyed()
	
	player.shoot_visual_feedback()
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		if proj:
			projectile_container.add_child(proj)
			proj.setup(player.get_shoot_origin(), missile.global_position, null)
			
	if floating_text_scene:
		var float_node = floating_text_scene.instantiate()
		float_node.setup("ESQUIVA! +250", missile.global_position, Color(0.3, 1.0, 0.4))
		effect_container.add_child(float_node)

func _on_missile_intercepted(missile: HomingMissile) -> void:
	active_missiles.erase(missile)

func _on_missile_impacted(missile: HomingMissile) -> void:
	active_missiles.erase(missile)
	player.take_damage(1)
	apply_shake(16.0)
	typing_panel.add_log("💥 IMPACTO DE MÍSSEL! (-1 ESCUDO)")
	typing_panel.set_computer_message("Dano crítico! Míssil atingiu o casco. Mantenha os dedos alertas para esquiva!", true)

func _fire_artillery_barrage_at_boss(side: String) -> void:
	if not is_instance_valid(current_boss):
		return
	var target_pos: Vector2 = current_boss.get_target_global_position(side)
	var origin_pos: Vector2 = player.get_shoot_origin()
	
	# Rajada sequencial de 4 projéteis velozes contra o chefe
	for i in range(4):
		var timer := get_tree().create_timer(i * 0.08)
		timer.timeout.connect(func():
			if not is_instance_valid(current_boss):
				return
			SoundManager.play_laser(1.4)
			player.shoot_visual_feedback()
			if projectile_scene:
				var proj = projectile_scene.instantiate()
				if proj:
					projectile_container.add_child(proj)
					var spread := Vector2(randf_range(-12.0, 12.0), randf_range(-8.0, 8.0))
					proj.setup(origin_pos, target_pos + spread, null)
		)
		
	# Resolução do impacto da rajada no ponto vital
	var impact_timer := get_tree().create_timer(0.35)
	impact_timer.timeout.connect(func():
		if not is_instance_valid(current_boss):
			return
		var damaged: bool = current_boss.damage_vital_point(side, 1)
		if damaged:
			apply_shake(6.0)
			if floating_text_scene:
				var float_node = floating_text_scene.instantiate()
				var txt := "ARTILHARIA! -1 HP"
				float_node.setup(txt, target_pos + Vector2(0, -20), Color(1.0, 0.4, 0.2))
				effect_container.add_child(float_node)
			typing_panel.add_log("🎯 IMPACTO DE ARTILHARIA: %s danificado!" % side.to_upper())
		else:
			if side == "core" and current_boss.is_shield_active():
				apply_shake(2.0)
				if floating_text_scene:
					var float_node = floating_text_scene.instantiate()
					float_node.setup("ESCUDO BLOQUEOU!", target_pos + Vector2(0, -20), Color(0.4, 0.8, 1.0))
					effect_container.add_child(float_node)
				typing_panel.add_log("🛡️ ESCUDO DO NÚCLEO ABSORVEU O IMPACTO! Destrua os canhões primeiro!")
	)

func _on_boss_cannon_destroyed(side: String) -> void:
	if side == "left":
		typing_panel.add_log("💥 CANHÃO ESQUERDO DO ENCOURAÇADO DESTRUÍDO!")
		typing_panel.set_computer_message("Canhão esquerdo destruído! Concentre fogo no canhão restante!", true)
		apply_shake(12.0)
	elif side == "right":
		typing_panel.add_log("💥 CANHÃO DIREITO DO ENCOURAÇADO DESTRUÍDO!")
		typing_panel.set_computer_message("Canhão direito destruído! Concentre fogo no canhão restante!", true)
		apply_shake(12.0)

func _on_boss_shield_collapsed() -> void:
	typing_panel.add_log("⚡ ESCUDO DO NÚCLEO EM COLAPSO! NÚCLEO VULNERÁVEL!")
	typing_panel.set_computer_message("ATENÇÃO: Escudo desativado! Foco total de artilharia no NÚCLEO CENTRAL!", true)
	apply_shake(18.0)

func _on_boss_defeated() -> void:
	typing_panel.add_log("🏆 ENCOURAÇADO ÔMEGA DESTRUÍDO COM SUCESSO!")
	typing_panel.set_computer_message("Incrível! O Encouraçado Ômega foi completamente obliterado!", true)
	ScoreManager.score += 5000
	apply_shake(25.0)
	for m in active_missiles:
		if is_instance_valid(m):
			m.queue_free()
	active_missiles.clear()
	for child in word_container.get_children():
		if child is EnemyWord and not child.is_queued_for_deletion():
			if explosion_scene:
				var exp_node: Node2D = explosion_scene.instantiate() as Node2D
				exp_node.global_position = child.global_position
				effect_container.add_child(exp_node)
			child.queue_free()
	wave_queue.clear()
	_trigger_wave_completed()
