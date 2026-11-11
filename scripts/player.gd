extends Node2D

# Player - Nave espacial com mira suave, barra de rank/estilo (SS a F), overdrive e barra de progresso da onda

signal health_changed(current_health: int, max_health: int)
signal died

@export var max_health: int = 3
var health: int = 3
var default_aim_dir: Vector2 = Vector2.UP
var current_target: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var left_cannon: Marker2D = $LeftCannon if has_node("LeftCannon") else null
@onready var right_cannon: Marker2D = $RightCannon if has_node("RightCannon") else null
@onready var thrusters: CPUParticles2D = $Thrusters if has_node("Thrusters") else null
@onready var overdrive_particles: CPUParticles2D = $OverdriveParticles if has_node("OverdriveParticles") else null

# Componentes da Barra de Rank de Estilo e Progresso da Onda
@onready var style_bar: ProgressBar = $StyleHUD/StyleBar if has_node("StyleHUD/StyleBar") else null
@onready var rank_label: Label = $StyleHUD/RankLabel if has_node("StyleHUD/RankLabel") else null
@onready var wave_progress_bar: ProgressBar = $StyleHUD/WaveProgressBar if has_node("StyleHUD/WaveProgressBar") else null
@onready var wave_progress_label: Label = $StyleHUD/WaveProgressLabel if has_node("StyleHUD/WaveProgressLabel") else null

var use_left_cannon: bool = true
var base_position: Vector2 = Vector2.ZERO
var current_rank: String = "C"
var is_dodging: bool = false
var dodge_tween: Tween = null

func _ensure_nodes() -> void:
	if sprite == null and has_node("Sprite2D"):
		sprite = $Sprite2D
	if left_cannon == null and has_node("LeftCannon"):
		left_cannon = $LeftCannon
	if right_cannon == null and has_node("RightCannon"):
		right_cannon = $RightCannon
	if thrusters == null and has_node("Thrusters"):
		thrusters = $Thrusters

func _ready() -> void:
	_ensure_nodes()
	health = max_health
	base_position = position
	health_changed.emit(health, max_health)
	update_style_rank("C", Color(0.4, 0.6, 1.0), 50.0)
	update_wave_progress(0, 100)

func reset() -> void:
	if dodge_tween and dodge_tween.is_valid():
		dodge_tween.kill()
	is_dodging = false
	health = max_health
	current_target = null
	position = base_position
	rotation = 0.0
	if sprite:
		sprite.rotation = 0.0
		sprite.position = Vector2.ZERO
	if thrusters:
		thrusters.speed_scale = 1.0
	modulate = Color.WHITE
	health_changed.emit(health, max_health)
	update_style_rank("C", Color(0.4, 0.6, 1.0), 50.0)
	update_wave_progress(0, 100)

func set_target(target: Node2D) -> void:
	current_target = target

func _process(delta: float) -> void:
	var target_angle: float = 0.0
	if is_instance_valid(current_target):
		var aim_vec: Vector2 = current_target.global_position - global_position
		target_angle = aim_vec.angle() + PI / 2.0
	else:
		target_angle = 0.0
		
	rotation = lerp_angle(rotation, target_angle, 14.0 * delta)

func update_style_rank(rank_str: String, rank_col: Color, style_pts: float) -> void:
	current_rank = rank_str
	if rank_label:
		rank_label.text = rank_str
		rank_label.add_theme_color_override("font_color", rank_col)
	if style_bar:
		style_bar.value = style_pts
		
	if overdrive_particles:
		var is_overdrive: bool = (rank_str == "S" or rank_str == "SS")
		overdrive_particles.emitting = is_overdrive

func update_wave_progress(current_count: int, total_count: int) -> void:
	var total_safe: int = maxi(1, total_count)
	if wave_progress_bar:
		wave_progress_bar.max_value = float(total_safe)
		wave_progress_bar.value = float(current_count)
	if wave_progress_label:
		var pct: float = (float(current_count) / float(total_safe)) * 100.0
		wave_progress_label.text = "%.0f%%" % pct

func get_shoot_origin() -> Vector2:
	use_left_cannon = not use_left_cannon
	if use_left_cannon and left_cannon:
		return left_cannon.global_position
	elif right_cannon:
		return right_cannon.global_position
	return global_position

func shoot_visual_feedback() -> void:
	var recoil_offset: Vector2 = Vector2.DOWN.rotated(rotation) * 4.0
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "position", recoil_offset, 0.04)
	tween.tween_property(sprite, "position", Vector2.ZERO, 0.06)

func perform_dodge(threat_x: float = -1.0) -> void:
	_ensure_nodes()
	if dodge_tween and dodge_tween.is_valid():
		dodge_tween.kill()
		
	is_dodging = true
	var dodge_distance: float = 125.0
	var dodge_dir: float = -1.0
	
	if threat_x >= 0.0:
		# Se a ameaça estiver vindo da direita (>= base X), esquivar para a esquerda
		# Se vier da esquerda (< base X), esquivar para a direita
		dodge_dir = -1.0 if threat_x >= base_position.x else 1.0
	else:
		dodge_dir = -1.0 if randf() < 0.5 else 1.0
		
	var target_dodge_x: float = clampf(base_position.x + (dodge_dir * dodge_distance), 160.0, 660.0)
	var bank_angle: float = deg_to_rad(20.0 * dodge_dir)
	
	dodge_tween = create_tween()
	
	# 1. Rápido deslocamento lateral com rolamento/inclinação da nave (0.12s)
	dodge_tween.set_parallel(true)
	dodge_tween.tween_property(self, "position:x", target_dodge_x, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if sprite:
		dodge_tween.tween_property(sprite, "rotation", bank_angle, 0.12)
	if thrusters:
		thrusters.speed_scale = 2.5
		
	# 2. Ponto de transição na lateral (0.06s)
	dodge_tween.chain().tween_interval(0.06)
	
	# 3. Retorno suave e veloz ao centro da arena (base_position.x)
	dodge_tween.chain().set_parallel(true)
	dodge_tween.tween_property(self, "position:x", base_position.x, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if sprite:
		dodge_tween.tween_property(sprite, "rotation", 0.0, 0.22)
	
	dodge_tween.chain().tween_callback(func():
		is_dodging = false
		position.x = base_position.x
		if sprite:
			sprite.rotation = 0.0
		if thrusters:
			thrusters.speed_scale = 1.0
	)

func take_damage(amount: int = 1) -> void:
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	var snd = get_node_or_null("/root/SoundManager")
	if snd and snd.has_method("play_player_hit"):
		snd.play_player_hit()
	
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1.5, 0.2, 0.2, 1.0), 0.08)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)
	
	if health <= 0:
		died.emit()
