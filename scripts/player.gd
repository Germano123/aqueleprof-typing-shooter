extends Node2D

# Player - Nave espacial com mira suave, barra de rank/estilo (SS a F), overdrive e barra de progresso da onda

signal health_changed(current_health: int, max_health: int)
signal died

@export var max_health: int = 3
var health: int = 3
var default_aim_dir: Vector2 = Vector2.UP
var current_target: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var left_cannon: Marker2D = $LeftCannon
@onready var right_cannon: Marker2D = $RightCannon
@onready var thrusters: CPUParticles2D = $Thrusters
@onready var overdrive_particles: CPUParticles2D = $OverdriveParticles if has_node("OverdriveParticles") else null

# Componentes da Barra de Rank de Estilo e Progresso da Onda
@onready var style_bar: ProgressBar = $StyleHUD/StyleBar if has_node("StyleHUD/StyleBar") else null
@onready var rank_label: Label = $StyleHUD/RankLabel if has_node("StyleHUD/RankLabel") else null
@onready var wave_progress_bar: ProgressBar = $StyleHUD/WaveProgressBar if has_node("StyleHUD/WaveProgressBar") else null
@onready var wave_progress_label: Label = $StyleHUD/WaveProgressLabel if has_node("StyleHUD/WaveProgressLabel") else null

var use_left_cannon: bool = true
var base_position: Vector2 = Vector2.ZERO
var current_rank: String = "C"

func _ready() -> void:
	health = max_health
	base_position = position
	health_changed.emit(health, max_health)
	update_style_rank("C", Color(0.4, 0.6, 1.0), 50.0)
	update_wave_progress(0, 100)

func reset() -> void:
	health = max_health
	current_target = null
	position = base_position
	rotation = 0.0
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
