extends Node2D
class_name HomingMissile

# HomingMissile - Míssil teleguiado de ataque do chefe
# Exige o conceito de esquiva/interceptação com SHIFT + número: ! @ # $ % ¨ & * ( )

signal intercepted(missile: HomingMissile)
signal impacted(missile: HomingMissile)

@export var speed: float = 85.0
@export var acceleration: float = 15.0

var symbol: String = "!"
var hint_key: String = "1"
var target_pos: Vector2 = Vector2(410, 650)
var is_active: bool = true
var is_intercepted: bool = false

@onready var sprite: Sprite2D = $Sprite if has_node("Sprite") else null
@onready var symbol_label: Label = $Badge/Margin/VBox/SymbolLabel if has_node("Badge/Margin/VBox/SymbolLabel") else null
@onready var hint_label: Label = $Badge/Margin/VBox/HintLabel if has_node("Badge/Margin/VBox/HintLabel") else null
@onready var badge: PanelContainer = $Badge if has_node("Badge") else null
@onready var thrusters: CPUParticles2D = $ThrusterParticles if has_node("ThrusterParticles") else null

func _ready() -> void:
	_update_display()
	_play_sfx("warning")
	
	# Efeito de pulso no badge de alerta do míssil
	if badge:
		var tween := create_tween().set_loops()
		tween.tween_property(badge, "scale", Vector2(1.1, 1.1), 0.3).set_trans(Tween.TRANS_SINE)
		tween.tween_property(badge, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_SINE)

func setup(sym: String, hint: String, origin_pos: Vector2, target_node_or_pos = null, base_spd: float = 85.0) -> void:
	global_position = origin_pos
	if target_node_or_pos is Node2D:
		target_pos = (target_node_or_pos as Node2D).global_position
	elif target_node_or_pos is Vector2:
		target_pos = target_node_or_pos
	else:
		target_pos = Vector2(410.0, 650.0)
	symbol = sym
	hint_key = hint
	speed = base_spd
	is_active = true
	is_intercepted = false
	_update_display()
	look_at(target_pos)
	rotation += PI / 2.0

func _update_display() -> void:
	if symbol_label:
		symbol_label.text = symbol
	if hint_label:
		if hint_key.length() > 0:
			hint_label.text = "SHIFT + %s" % hint_key
		else:
			hint_label.text = "SHIFT"

func _process(delta: float) -> void:
	if not is_active:
		return
		
	speed += acceleration * delta
	var dir := (target_pos - global_position).normalized()
	global_position += dir * speed * delta
	
	# Suave rotação na direção da nave
	var target_rot: float = dir.angle() + PI / 2.0
	rotation = lerp_angle(rotation, target_rot, 8.0 * delta)
	
	# Verificar se atingiu a linha defensiva da nave
	if global_position.y >= 635.0 or global_position.distance_to(target_pos) < 30.0:
		_on_impact()

func intercept() -> void:
	if not is_active:
		return
	is_active = false
	is_intercepted = true
	_play_sfx("destroyed")
	intercepted.emit(self)
	queue_free()

func _play_sfx(sfx_name: String) -> void:
	if not is_inside_tree():
		return
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		match sfx_name:
			"warning": sm.play_missile_warning()
			"destroyed": sm.play_missile_destroyed()

func _on_impact() -> void:
	if not is_active:
		return
	is_active = false
	impacted.emit(self)
	queue_free()

func get_symbol() -> String:
	return symbol

func get_hint_text() -> String:
	if hint_key.length() > 0:
		return "SHIFT + %s" % hint_key
	return "SHIFT"
